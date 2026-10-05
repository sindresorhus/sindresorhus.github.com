import Foundation
import Testing
import SiteKit

@Suite
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
		let (data, response) = try await URLSession.shared.data(from: url)
		return ((response as? HTTPURLResponse)?.statusCode ?? 0, String(decoding: data, as: UTF8.self))
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
