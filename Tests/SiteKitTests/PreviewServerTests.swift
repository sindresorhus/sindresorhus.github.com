import Foundation
import TestSupport
import Testing
import SiteKit

struct PreviewServerTests {
	private struct State: Decodable {
		let version: String
		let revision: String
		let error: String?
	}

	/**
	Runs the server on a port that the system picks while the body runs, and stops it afterwards.
	*/
	private func running(_ server: PreviewServer, body: (_ port: UInt16) async throws -> Void) async throws {
		let (ports, portContinuation) = AsyncStream.makeStream(of: UInt16.self)

		// The stream ends when the server stops, so a server that cannot start fails the test instead of hanging it.
		let task = Task {
			defer {
				portContinuation.finish()
			}

			try await server.run { port in
				portContinuation.yield(port)
			}
		}

		var iterator = ports.makeAsyncIterator()

		guard let port = await iterator.next() else {
			try await task.value
			Issue.record("The server stopped before it was ready.")
			return
		}

		#expect(port != 0)

		do {
			try await body(port)
		} catch {
			task.cancel()
			throw error
		}

		task.cancel()
		try await task.value
	}

	private func get(_ path: String, port: UInt16) async throws -> (status: Int, body: String) {
		let url = try #require(URL(string: "http://127.0.0.1:\(port)\(path)"))
		let (data, response) = try await URLSession.shared.httpData(for: URLRequest(url: url))
		return (response.statusCode, String(decoding: data, as: UTF8.self))
	}

	private func state(since revision: String, port: UInt16) async throws -> State {
		let response = try await get("/_preview-server/state?since=\(revision)", port: port)
		return try JSONDecoder().decode(State.self, from: Data(response.body.utf8))
	}

	@Test(.timeLimit(.minutes(1)), .temporaryDirectory)
	func `serves pages like GitHub Pages and stops when cancelled`() async throws {
		// The secret is next to the served directory, so a path that leaves the directory would find it.
		let root = try URL.temporaryDirectory(files: ["site/about.html": "About", "site/blog/index.html": "Blog", "site/404.html": "Missing", "secret": "Secret"])

		try await running(PreviewServer(directory: root.appending(path: "site"), port: 0)) { port in
			for (path, status, body) in [("/about", 200, "About"), ("/blog", 200, "Blog"), ("/nope", 404, "Missing"), ("/%2e%2e/secret", 404, "Missing")] {
				let response = try await get(path, port: port)
				#expect(response.status == status, "\(path)")
				#expect(response.body == body, "\(path)")
			}
		}
	}

	@Test(.timeLimit(.minutes(1)), .temporaryDirectory)
	func `answers a request for a range of bytes, like Safari for a video`() async throws {
		let directory = try URL.temporaryDirectory(files: ["video.mp4": "0123456789"])

		try await running(PreviewServer(directory: directory, port: 0)) { port in
			// An invalid range, or several ranges, get the whole file.
			for (range, status, body, contentRange) in [
				(nil, 200, "0123456789", nil),
				("bytes=2-4", 206, "234", "bytes 2-4/10"),
				("bytes=7-", 206, "789", "bytes 7-9/10"),
				("bytes=-3", 206, "789", "bytes 7-9/10"),
				("bytes=-30", 206, "0123456789", "bytes 0-9/10"),
				("bytes=8-100", 206, "89", "bytes 8-9/10"),
				("bytes=0-0", 206, "0", "bytes 0-0/10"),
				("bytes=9-9", 206, "9", "bytes 9-9/10"),
				("bytes=10-", 416, "", "bytes */10"),
				("bytes=-0", 416, "", "bytes */10"),
				("bytes=4-2", 200, "0123456789", nil),
				("bytes=0-1,4-5", 200, "0123456789", nil)
			] as [(String?, Int, String, String?)] {
				var request = URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(port)/video.mp4")))
				request.setValue(range, forHTTPHeaderField: "Range")
				let (data, httpResponse) = try await URLSession.shared.httpData(for: request)
				let label = range ?? "no range"
				#expect(httpResponse.statusCode == status, "\(label)")
				#expect(String(decoding: data, as: UTF8.self) == body, "\(label)")
				#expect(httpResponse.value(forHTTPHeaderField: "Content-Length") == String(data.count), "\(label)")
				#expect(httpResponse.value(forHTTPHeaderField: "Content-Range") == contentRange, "\(label)")
				#expect(httpResponse.value(forHTTPHeaderField: "Accept-Ranges") == (status == 416 ? nil : "bytes"), "\(label)")
			}
		}
	}

	@Test(.timeLimit(.minutes(1)), .temporaryDirectory)
	func `a byte range of an empty file is unsatisfied`() async throws {
		let directory = try URL.temporaryDirectory(files: ["empty.mp4": ""])

		try await running(PreviewServer(directory: directory, port: 0)) { port in
			var request = URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(port)/empty.mp4")))
			request.setValue("bytes=0-", forHTTPHeaderField: "Range")
			let (data, httpResponse) = try await URLSession.shared.httpData(for: request)
			#expect(httpResponse.statusCode == 416)
			#expect(data.isEmpty)
			#expect(httpResponse.value(forHTTPHeaderField: "Content-Range") == "bytes */0")
			#expect(httpResponse.value(forHTTPHeaderField: "Content-Length") == "0")
		}
	}

	@Test(.timeLimit(.minutes(1)), .temporaryDirectory)
	func `reloads pages and shows errors`() async throws {
		let directory = try URL.temporaryDirectory(files: ["index.html": "<p>Page</p>"])
		let server = PreviewServer(directory: directory, port: 0, reloadsPages: true)

		try await running(server) { port in
			let page = try await get("/", port: port).body
			#expect(page.hasPrefix("<p>Page</p><script>"))

			// The page starts with the current version, so a reload right after it loads is not missed.
			let initial = try await state(since: "", port: port)
			#expect(page.contains("const version=\"\(initial.version)\""))
			#expect(initial.error == nil)

			// A request for the next change waits for it.
			let change = Task {
				try await state(since: initial.revision, port: port)
			}

			try await Task.sleep(for: .milliseconds(200))
			server.show(error: "Broken")
			let errorState = try await change.value
			#expect(errorState.error == "Broken")
			#expect(errorState.version == initial.version)

			server.reload()
			let reloaded = try await state(since: errorState.revision, port: port)
			#expect(reloaded.version != initial.version)
		}
	}
}

extension URLSession {
	/**
	The data and checked HTTP response of a request to the local preview server.
	*/
	fileprivate func httpData(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
		let (data, response) = try await data(for: request)
		return (data, try #require(response as? HTTPURLResponse))
	}
}
