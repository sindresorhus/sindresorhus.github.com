import Foundation
import Network
import SiteKit
import Synchronization
import Testing

@Suite
struct ResponseCacheTests {
	private struct Value: Decodable, Equatable {
		let value: Int
	}

	private struct Entry: Decodable {
		let date: Date
	}

	/**
	The server allows the response to be cached for a minute, like GitHub. So with the cache of Foundation, the second request would be answered from that cache, and the server would never get it.
	*/
	@Test(.timeLimit(.minutes(1)), .temporaryDirectory)
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
	}

	@Test(.timeLimit(.minutes(1)), .temporaryDirectory)
	func `a response that cannot be decoded keeps the cached response, and uses it`() async throws {
		let server = try ETagServer(bodies: [#"{"value": 1}"#, #"{"errors": []}"#])
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
		#expect(cache.warnings.count == 1)
		// The request worked, so the warning says that the response could not be read.
		#expect(cache.warnings.first?.message.contains("could not be read") == true)
		#expect(cache.warnings.first?.message.contains("request failed") == false)

		// The file still has the response that can be decoded, so a cache that uses it without asking gets the value.
		let freshCache = ResponseCache(directory: directory, maximumAge: .seconds(60))
		#expect(try await freshCache.decoded(Value.self, from: request) == Value(value: 1))
		#expect(server.answers.count == 2)
	}

	@Test(.timeLimit(.minutes(1)), .temporaryDirectory)
	func `a failed request without a cached response says its URL`() async throws {
		let server = try ETagServer()
		let port = try await server.start()
		server.stop()

		let cache = ResponseCache(directory: try URL.temporaryDirectory(), maximumAge: .zero)
		let url = try #require(URL(string: "http://127.0.0.1:\(port)/value"))

		let error = await #expect(throws: (any Error).self) {
			try await cache.decoded(Value.self, from: URLRequest(url: url))
		}

		#expect(String(describing: try #require(error)).contains(url.absoluteString))
	}
}

/**
A local HTTP server that answers with a JSON body and an ETag, and with `304 Not Modified` and no body when the request has the ETag in `If-None-Match`.

Each `200` answer has the next of the bodies, and the last body after that. The ETag of a body is its number, like `"1"` for the first.
*/
private final class ETagServer: Sendable {
	private let bodies: [String]
	private let listener: NWListener
	private let statuses = Mutex<[String]>([])

	/**
	The status of each answer, in order, like `200`.
	*/
	var answers: [String] {
		statuses.withLock(\.self)
	}

	init(bodies: [String] = [#"{"value": 1}"#]) throws {
		self.bodies = bodies
		let parameters = NWParameters.tcp
		parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
		listener = try NWListener(using: parameters)
	}

	/**
	Starts the server, and returns the port that the system picked.
	*/
	func start() async throws -> UInt16 {
		listener.newConnectionHandler = { [self] connection in
			connection.start(queue: .global())
			connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, _, _ in
				let request = String(decoding: data ?? Data(), as: UTF8.self)

				let (status, body, etag) = self.statuses.withLock { statuses in
					let index = min(statuses.count { $0 == "200" }, self.bodies.count - 1)
					let etag = "\"\(index + 1)\""
					let isRevalidation = request.split(separator: "\r\n").contains { $0.lowercased() == "if-none-match: \(etag)" }
					let status = isRevalidation ? "304" : "200"
					statuses.append(status)
					return (status, isRevalidation ? "" : self.bodies[index], etag)
				}

				let response = "HTTP/1.1 \(status) \(status == "304" ? "Not Modified" : "OK")\r\nETag: \(etag)\r\nCache-Control: private, max-age=60\r\nContent-Type: application/json\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"

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
