import Foundation
import Testing
import SiteKit

@Suite
struct PreviewServerTests {
	@Test(.timeLimit(.minutes(1)))
	func `serves pages like GitHub Pages and stops when cancelled`() async throws {
		// The secret is next to the served directory, so a path that leaves the directory would find it.
		let root = try URL.temporaryDirectory(files: ["site/about.html": "About", "site/blog/index.html": "Blog", "site/404.html": "Missing", "secret": "Secret"])
		let directory = root.appending(path: "site")

		let port = UInt16.random(in: 49_152...65_000)
		let (ready, readyContinuation) = AsyncStream<Void>.makeStream()

		// The stream ends when the server stops, so a port that is taken fails the test instead of hanging it.
		let server = Task {
			defer {
				readyContinuation.finish()
			}

			try await PreviewServer(directory: directory, port: port).run {
				readyContinuation.yield()
			}
		}

		for await _ in ready {
			break
		}

		func get(_ path: String) async throws -> (status: Int, body: String) {
			let (data, response) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)\(path)")!)
			return ((response as? HTTPURLResponse)?.statusCode ?? 0, String(decoding: data, as: UTF8.self))
		}

		#expect(try await get("/about") == (200, "About"))
		#expect(try await get("/blog") == (200, "Blog"))
		#expect(try await get("/nope") == (404, "Missing"))
		#expect(try await get("/%2e%2e/secret") == (404, "Missing"))

		server.cancel()
		try await server.value
	}

	@Test(.timeLimit(.minutes(1)))
	func `reloads pages after a reload`() async throws {
		let directory = try URL.temporaryDirectory(files: ["index.html": "<p>Page</p>"])

		let port = UInt16.random(in: 49_152...65_000)
		let previewServer = PreviewServer(directory: directory, port: port, reloadsPages: true)
		let (ready, readyContinuation) = AsyncStream<Void>.makeStream()

		let server = Task {
			defer {
				readyContinuation.finish()
			}

			try await previewServer.run {
				readyContinuation.yield()
			}
		}

		for await _ in ready {
			break
		}

		func get(_ path: String) async throws -> String {
			let (data, _) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(port)\(path)")!)
			return String(decoding: data, as: UTF8.self)
		}

		let page = try await get("/")
		#expect(page.hasPrefix("<p>Page</p><script>"))

		// The page starts with the current version, so a reload right after it loads is not missed.
		let version = try await get("/_preview-server/version")
		#expect(page.contains("let version=\"\(version)\""))
		previewServer.reload()
		#expect(try await get("/_preview-server/version") != version)

		server.cancel()
		try await server.value
	}
}

@Suite
struct DirectoryWatcherTests {
	@Test(.timeLimit(.minutes(1)))
	func `reports the changed directories`() async throws {
		let root = try URL.temporaryDirectory(files: ["first/.keep": "", "second/.keep": ""])
		let first = root.appending(path: "first")
		let second = root.appending(path: "second")

		var changes = DirectoryWatcher(directories: [first, second], interval: .milliseconds(20)).makeAsyncIterator()
		try Data("New".utf8).write(to: second.appending(path: "file.txt"))

		#expect(await changes.next() == [second])
	}
}
