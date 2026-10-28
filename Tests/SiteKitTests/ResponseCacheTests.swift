import Foundation
import Network
@testable import SiteKit
import Synchronization
import TestSupport
import Testing

/**
The requests wait for a local server, so a slow CI runner, where the whole suite runs at once, can take longer than a minute to answer one, though it never hangs.
*/
@Suite(.timeLimit(.minutes(3)))
struct ResponseCacheTests {
	private struct Value: Decodable, Equatable {
		let value: Int
	}

	private struct Entry: Decodable {
		let date: Date
	}

	@Test(.temporaryDirectory)
	func `a failed cache save does not leave a successful value in memory`() async throws {
		let server = try ETagServer(.etag(bodies: [#"{"value": 1}"#, #"{"value": 2}"#]))
		let port = try await server.start()
		defer {
			server.stop()
		}

		let directory = try URL.temporaryDirectory().appending(path: "cache")
		try Data().write(to: directory)
		let cache = ResponseCache(directory: directory, maximumAge: .seconds(60))
		let request = URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(port)/value")))
		await #expect(throws: (any Error).self) {
			try await cache.decoded(Value.self, from: request)
		}

		try directory.removeIfExists()
		#expect(try await cache.decoded(Value.self, from: request) == Value(value: 2))
		#expect(server.answers == ["200", "200"])
	}

	@Test
	func `an ETag fixture requires a response body`() async {
		await #expect(processExitsWith: .failure) {
			_ = try ETagServer(.etag(bodies: []))
		}
	}

	/**
	The server allows the response to be cached for a minute, like GitHub. So with the cache of Foundation, the second request would be answered from that cache, and the server would never get it.
	*/
	@Test(.temporaryDirectory)
	func `an outdated response is revalidated with its ETag, and a 304 keeps its body and makes it fresh`() async throws {
		let server = try ETagServer()
		let port = try await server.start()

		defer {
			server.stop()
		}

		let directory = try URL.temporaryDirectory()
		let cache = ResponseCache(directory: directory, maximumAge: .zero)
		let request = URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(port)/value")))

		func cachedDate() throws -> Date {
			let file = try #require(try directory.filesRecursively().first)
			return try JSONDecoder().decode(Entry.self, from: Data(contentsOf: file)).date
		}

		#expect(try await cache.decoded(Value.self, from: request) == Value(value: 1))
		let firstDate = try cachedDate()

		// The 304 has no body, so the value can only come from the cached response.
		#expect(try await cache.decoded(Value.self, from: request) == Value(value: 1))
		#expect(server.answers == ["200", "304"])
		#expect(try cachedDate() > firstDate)
		#expect(cache.warnings.isEmpty)

		#expect(try await cache.decoded(Value.self, from: request) == Value(value: 1))
		#expect(server.answers == ["200", "304", "304"])
	}

	/**
	Like each build of `website serve`, a copy for another build uses the decoded value while the response is fresh, without reading the file again.
	*/
	@Test(.temporaryDirectory)
	func `a fresh value is reused from memory by a copy for another build`() async throws {
		let server = try ETagServer()
		let port = try await server.start()

		defer {
			server.stop()
		}

		let directory = try URL.temporaryDirectory()
		let cache = ResponseCache(directory: directory, maximumAge: .seconds(60 * 60))
		let request = URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(port)/value")))

		#expect(try await cache.decoded(Value.self, from: request) == Value(value: 1))

		for file in try directory.filesRecursively() {
			try file.removeIfExists()
		}

		#expect(try await cache.forAnotherBuild.decoded(Value.self, from: request) == Value(value: 1))
		#expect(server.answers == ["200"])
	}

	@Test(.temporaryDirectory)
	func `decoded values with the same type name keep separate memory entries`() async throws {
		struct Value: Sendable {
			let value: Int
		}

		#expect(String(describing: Value.self) == String(describing: ResponseCacheTests.Value.self))
		let directory = try URL.temporaryDirectory()
		let cache = ResponseCache(directory: directory, maximumAge: .seconds(60 * 60))
		let request = URLRequest(url: #URL("https://example.com/value"))
		let entry: [String: Any] = ["date": Date.now.timeIntervalSinceReferenceDate, "body": Data(#"{"value": 1}"#.utf8).base64EncodedString()]
		try JSONSerialization.data(withJSONObject: entry).write(to: directory.appending(path: "\(request.responseCacheKey).json"))
		var firstDecodes = 0
		var secondDecodes = 0

		for _ in 0..<2 {
			let first = try await cache.decoded(from: request) { data in
				firstDecodes += 1
				return try JSONDecoder().decode(ResponseCacheTests.Value.self, from: data)
			}
			let second = try await cache.decoded(from: request) { data in
				secondDecodes += 1
				return Value(value: try JSONDecoder().decode(ResponseCacheTests.Value.self, from: data).value)
			}
			#expect(first.value == 1)
			#expect(second.value == 1)
		}

		#expect(firstDecodes == 1)
		#expect(secondDecodes == 1)
	}

	@Test(.temporaryDirectory)
	func `a response that cannot be decoded keeps the cached response, and uses it`() async throws {
		let server = try ETagServer(.etag(bodies: [#"{"value": 1}"#, #"{"errors": []}"#]))
		let port = try await server.start()

		defer {
			server.stop()
		}

		let directory = try URL.temporaryDirectory()
		let cache = ResponseCache(directory: directory, maximumAge: .zero)
		let request = URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(port)/value")))

		#expect(try await cache.decoded(Value.self, from: request) == Value(value: 1))
		#expect(try await cache.decoded(Value.self, from: request) == Value(value: 1))
		#expect(server.answers == ["200", "200"])
		try #require(cache.warnings.count == 1)
		// The request worked, so the warning says that the response could not be read.
		let message = cache.warnings[0].message
		#expect(message.hasSuffix("could not be read: Missing required key `value`."))
		#expect(!message.contains("request failed"))

		// The file still has the response that can be decoded, so a cache that uses it without asking gets the value.
		let freshCache = ResponseCache(directory: directory, maximumAge: .seconds(60))
		#expect(try await freshCache.decoded(Value.self, from: request) == Value(value: 1))
		#expect(server.answers.count == 2)
	}

	/**
	Like the review feeds of the App Store when Apple refuses the requests of a Mac: one warning for the host, not one for each URL, and the later builds of `website serve` do not ask again while the cached value is fresh, but still warn, as the data is still old.
	*/
	@Test(.temporaryDirectory)
	func `failed requests of one host give one warning, and are not asked again by a later build`() async throws {
		let reset = Date(timeIntervalSince1970: 1_800_000_000)
		let server = try ETagServer(.rateLimited(until: reset))
		let port = try await server.start()

		defer {
			server.stop()
		}

		let directory = try URL.temporaryDirectory()
		let requests = try ["a", "b"].map { URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(port)/\($0)"))) }

		// Outdated cached responses.
		for request in requests {
			let entry: [String: Any] = ["date": 0, "body": Data(#"{"value": 1}"#.utf8).base64EncodedString()]
			try JSONSerialization.data(withJSONObject: entry).write(to: directory.appending(path: "\(request.responseCacheKey).json"))
		}

		let cache = ResponseCache(directory: directory, maximumAge: .seconds(60))

		for request in requests {
			#expect(try await cache.decoded(Value.self, from: request) == Value(value: 1))
		}

		#expect(server.answers.count == 2)
		#expect(cache.warnings.map(\.message) == ["Using cached responses for 2 URLs of 127.0.0.1, like http://127.0.0.1:\(port)/a, because the request failed: The server responded with status 403. The rate limit is used up until \(reset.formatted(date: .omitted, time: .shortened))."])

		let laterBuild = cache.forAnotherBuild
		#expect(laterBuild.warnings.isEmpty)
		#expect(try await laterBuild.decoded(Value.self, from: requests[0]) == Value(value: 1))
		#expect(server.answers.count == 2)
		#expect(laterBuild.warnings.map(\.message) == [cache.warnings[0].message.replacing("cached responses for 2 URLs of 127.0.0.1, like ", with: "a cached response for ")])

		// An explicit freshness requirement still retries the request, despite the cached failure in memory.
		#expect(try await laterBuild.decoded(Value.self, from: requests[0], maximumAge: .zero) == Value(value: 1))
		#expect(server.answers.count == 3)
		#expect(laterBuild.warnings.count == 1)
	}

	@Test(.temporaryDirectory)
	func `a failed request without a cached response says its URL`() async throws {
		let server = try ETagServer()
		let port = try await server.start()
		server.stop()

		let cache = ResponseCache(directory: try URL.temporaryDirectory(), maximumAge: .zero)
		let url = try #require(URL(string: "http://127.0.0.1:\(port)/value"))

		let error = try await #require(throws: ResponseCache.RequestError.self) {
			try await cache.decoded(Value.self, from: URLRequest(url: url))
		}

		#expect(error.statusCode == nil)
		let description = String(describing: error)
		#expect(description.hasPrefix("Could not get \(url), because the request failed: "))
		// The message of the error, not all its details.
		#expect(!description.contains("Error Domain"))
	}

	@Test(.temporaryDirectory)
	func `a custom decoding failure keeps its description in the warning`() async throws {
		let server = try ETagServer(.etag(bodies: ["valid", "invalid"]))
		let port = try await server.start()
		defer {
			server.stop()
		}

		let cache = ResponseCache(directory: try URL.temporaryDirectory(), maximumAge: .zero)
		let request = URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(port)/value")))

		for _ in 0..<2 {
			let value = try await cache.decoded(from: request) { data in
				guard String(decoding: data, as: UTF8.self) == "valid" else {
					throw ContentError(reason: "The response has no usable values.")
				}

				return "valid"
			}
			#expect(value == "valid")
		}

		#expect(server.answers == ["200", "200"])
		let message = try #require(cache.warnings.first).message
		#expect(message.hasSuffix("could not be read: The response has no usable values."))
	}

	@Test(.temporaryDirectory)
	func `an unreadable response without cached data has no HTTP failure status`() async throws {
		let server = try ETagServer(.etag(bodies: ["invalid"]))
		let port = try await server.start()
		defer {
			server.stop()
		}

		let cache = ResponseCache(directory: try URL.temporaryDirectory(), maximumAge: .zero)
		let url = try #require(URL(string: "http://127.0.0.1:\(port)/value"))
		let request = URLRequest(url: url)
		let error = try await #require(throws: ResponseCache.RequestError.self) {
			try await cache.decoded(from: request) { _ -> String in
				throw ResponseCache.ReadError("Missing required values.")
			}
		}

		#expect(error.statusCode == nil)
		#expect(error.description == "Could not get \(url), because the response could not be read: Missing required values.")
		#expect(cache.warnings.isEmpty)
	}

	/**
	GitHub refuses a request with status 403 when the rate limit is used up, which looks like a permission problem.
	*/
	@Test(.temporaryDirectory)
	func `a refused request says when the rate limit is used up, and has the status`() async throws {
		let reset = Date(timeIntervalSince1970: 1_800_000_000)
		let server = try ETagServer(.rateLimited(until: reset))
		let port = try await server.start()

		defer {
			server.stop()
		}

		let cache = ResponseCache(directory: try URL.temporaryDirectory(), maximumAge: .zero)
		let request = URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(port)/value")))

		let error = try await #require(throws: ResponseCache.RequestError.self) {
			try await cache.decoded(Value.self, from: request)
		}

		#expect(error.statusCode == 403)
		#expect(server.answers == ["403"])
		#expect(error.description.hasSuffix("The server responded with status 403. The rate limit is used up until \(reset.formatted(date: .omitted, time: .shortened))."))
	}

	@Test
	func `cache identities distinguish methods and binary body bytes`() {
		let original = URLRequest(url: #URL("https://example.com/api"))
		var variants = [original]
		var post = original
		post.httpMethod = "POST"
		variants.append(post)
		for byte: UInt8 in [0x80, 0x81] {
			var binary = post
			binary.httpBody = Data([byte])
			variants.append(binary)
		}
		#expect(Set(variants.map(\.responseCacheKey)).count == variants.count)
		#expect(variants.allSatisfy { $0.responseCacheKey.count == 64 })
	}

	/**
	The GitHub token of CI changes on each run, so a key with it would miss the cache on each run.
	*/
	@Test(.temporaryDirectory)
	func `a request with another token uses the same cached response`() async throws {
		let server = try ETagServer(.etag(bodies: [#"{"value": 1}"#, #"{"value": 2}"#]))
		let port = try await server.start()
		defer {
			server.stop()
		}
		let cache = ResponseCache(directory: try URL.temporaryDirectory(), maximumAge: .seconds(60))
		var request = URLRequest(url: try #require(URL(string: "http://127.0.0.1:\(port)/value")))
		request.setValue("Bearer first", forHTTPHeaderField: "Authorization")
		#expect(try await cache.decoded(Value.self, from: request) == Value(value: 1))
		request.setValue("Bearer second", forHTTPHeaderField: "Authorization")
		#expect(try await cache.decoded(Value.self, from: request) == Value(value: 1))
		#expect(server.answers == ["200"])
	}
}

/**
A local HTTP server that answers with a JSON body and an ETag, and with `304 Not Modified` and no body when the request has the ETag in `If-None-Match`.

Each `200` answer has the next of the bodies, and the last body after that. The ETag of a body is its number, like `"1"` for the first.
*/
private final class ETagServer: Sendable {
	enum Mode: Sendable {
		case etag(bodies: [String])

		/**
		Every answer is `403 Forbidden`, with the headers of a rate limit that is used up until this time, like GitHub.
		*/
		case rateLimited(until: Date)
	}

	private let mode: Mode
	private let listener: NWListener
	private let statuses = Mutex<[String]>([])

	/**
	The status of each answer, in order, like `200`.
	*/
	var answers: [String] {
		statuses.withLock(\.self)
	}

	init(_ mode: Mode = .etag(bodies: [#"{"value": 1}"#])) throws {
		if case .etag(let bodies) = mode {
			precondition(!bodies.isEmpty, "An ETag server needs at least one response body.")
		}

		self.mode = mode
		let parameters = NWParameters.tcp
		parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
		self.listener = try NWListener(using: parameters)
	}

	/**
	Starts the server, and returns the port that the system picked.
	*/
	func start() async throws -> UInt16 {
		listener.newConnectionHandler = { [self] connection in
			connection.start(queue: .global())
			connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, _, _ in
				let request = String(decoding: data ?? Data(), as: UTF8.self)

				let response = self.statuses.withLock { statuses in
					let status: String
					let response: String

					switch self.mode {
					case .etag(let bodies):
						let index = min(statuses.count { $0 == "200" }, bodies.count - 1)
						let etag = "\"\(index + 1)\""
						let isRevalidation = request.split(separator: "\r\n").contains { $0.lowercased() == "if-none-match: \(etag)" }
						status = isRevalidation ? "304" : "200"
						let body = isRevalidation ? "" : bodies[index]
						response = "HTTP/1.1 \(status) \(status == "304" ? "Not Modified" : "OK")\r\nETag: \(etag)\r\nCache-Control: private, max-age=60\r\nContent-Type: application/json\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
					case .rateLimited(let reset):
						status = "403"
						response = "HTTP/1.1 \(status) Forbidden\r\nx-ratelimit-remaining: 0\r\nx-ratelimit-reset: \(Int(reset.timeIntervalSince1970))\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
					}

					statuses.append(status)
					return response
				}

				connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
					connection.cancel()
				})
			}
		}

		return try await withCheckedThrowingContinuation { continuation in
			listener.stateUpdateHandler = { [listener] state in
				switch state {
				case .ready:
					listener.stateUpdateHandler = nil
					continuation.resume(returning: listener.port?.rawValue ?? 0)
				case .failed(let error):
					listener.stateUpdateHandler = nil
					continuation.resume(throwing: error)
				default:
					break
				}
			}

			listener.start(queue: .global())
		}
	}

	func stop() {
		listener.cancel()
	}
}
