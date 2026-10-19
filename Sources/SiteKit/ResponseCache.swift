import CryptoKit
import Foundation

/**
Fetches a response, like JSON from the App Store and GitHub, or a JavaScript file, with a cache on disk.

A cached response is used while it is younger than `maximumAge`. After that, it is revalidated with its ETag, so an unchanged response costs no download and, for GitHub, no rate limit.

Local builds use a maximum age of an hour, so rebuilds are fast and work offline once the cache has the responses. Deploy builds use a maximum age of zero, so the data is fresh. When a request fails, every build uses the cached response with a warning, so one failed request does not fail a deploy or leave data out of the pages. A build without a cache needs the network.
*/
public struct ResponseCache: Sendable {
	private struct Entry: Codable {
		let etag: String?
		let date: Date
		let body: Data
	}

	/**
	The directory with the cached responses. `nil` turns the cache off.
	*/
	let directory: URL?

	let maximumAge: Duration

	/**
	The warnings about stale responses. It is shared by the copies of the cache.
	*/
	private let staleResponses = WarningCollector()

	/**
	The session for the requests. It has no `URLCache`, as the cache of Foundation would keep each response a second time, and hide `304 Not Modified` responses: it answers a request itself while the response is fresh by its `Cache-Control` header, like for 60 seconds on GitHub, and turns a 304 into a 200 with its own copy of the body. So the ETag check below would never get a 304.
	*/
	private static let session: URLSession = {
		let configuration = URLSessionConfiguration.ephemeral
		configuration.urlCache = nil
		configuration.httpCookieStorage = nil
		configuration.urlCredentialStorage = nil
		configuration.httpShouldSetCookies = false
		// The timeout of a request only counts the time without data, so a slow response that keeps sending could run until the build is stopped. This is the most time a whole request can take.
		configuration.timeoutIntervalForResource = 60
		return URLSession(configuration: configuration)
	}()

	public init(directory: URL?, maximumAge: Duration) {
		self.directory = directory
		self.maximumAge = maximumAge
	}

	/**
	The cache for builds of the project: in `.cache/responses`, and fresh on CI.
	*/
	public static func forBuilds(of project: Project) -> Self {
		let isContinuousIntegration = ProcessInfo.processInfo.environment["CI"] != nil

		return Self(
			directory: project.root.appending(path: ".cache/responses"),
			maximumAge: isContinuousIntegration ? .zero : .seconds(60 * 60)
		)
	}

	/**
	Fetches and decodes JSON. Dates are ISO 8601. Throws for responses other than 2xx and 304.

	A response is decoded before it is saved. A response that cannot be decoded, like a GraphQL error with status 200, is not saved, and is handled like a failed request, so the cached response stays and the next build asks again. A cached response that cannot be decoded, like after the type changed, is removed, so the next build asks again.

	- Parameter maximumAge: How long the response is used without asking again, like a long time for data that never changes, such as the contributions of a past year. Defaults to the maximum age of the cache.
	*/
	public func decoded<Value: Decodable>(_ type: Value.Type = Value.self, from request: URLRequest, maximumAge: Duration? = nil) async throws -> Value {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601

		return try await decoded(from: request, maximumAge: maximumAge) {
			try decoder.decode(Value.self, from: $0)
		}
	}

	/**
	Fetches the body and reads it with the function, like the names in a JavaScript file, with the caching of ``decoded(_:from:maximumAge:)``. The function throws for a body that it cannot read, so the body is not saved, and the cached response is used.
	*/
	public func decoded<Value>(from request: URLRequest, maximumAge: Duration? = nil, decode: (Data) throws -> Value) async throws -> Value {
		try Task.checkCancellation()
		let maximumAge = maximumAge ?? self.maximumAge
		let file = file(for: request)
		let entry = file.flatMap { try? JSONDecoder().decode(Entry.self, from: Data(contentsOf: $0)) }

		if
			let entry,
			Date.now.timeIntervalSince(entry.date) < maximumAge / .seconds(1)
		{
			do {
				return try decode(entry.body)
			} catch {
				try? file?.removeIfExists()
				throw error
			}
		}

		// An outdated cached response that cannot be decoded is neither revalidated nor used when the request fails.
		let cached = entry.flatMap { entry in
			(try? decode(entry.body)).map { (entry: entry, value: $0) }
		}

		var request = request

		if let etag = cached?.entry.etag {
			request.setValue(etag, forHTTPHeaderField: "If-None-Match")
		}

		// A failed request, an error status like a rate limit, or a response that cannot be decoded, uses the cached response. The reason is a sentence, like “the request failed: Could not connect to the server.”
		func cachedValue(because reason: String) throws -> Value {
			guard let cached else {
				throw RequestError(url: request.url, reason: reason)
			}

			staleResponses.add(Warning(message: "Using a cached response for \(request.url, default: ""), because \(reason)"))
			return cached.value
		}

		let data: Data
		let response: URLResponse

		do {
			(data, response) = try await Self.session.data(for: request)
		} catch {
			try Task.checkCancellation()
			return try cachedValue(because: "the request failed: \(error.descriptiveMessage)")
		}

		let httpResponse = response as? HTTPURLResponse
		let statusCode = httpResponse?.statusCode ?? 0

		if
			statusCode == 304,
			let cached
		{
			try save(Entry(etag: cached.entry.etag, date: .now, body: cached.entry.body), to: file)
			return cached.value
		}

		guard (200..<300).contains(statusCode) else {
			return try cachedValue(because: "the request failed: The server responded with status \(statusCode).")
		}

		let value: Value

		do {
			value = try decode(data)
		} catch {
			// The localized description of a decoding error does not say what is wrong, like which key is missing.
			return try cachedValue(because: "the response could not be read: \((error as? DecodingError)?.readableDescription(root: "response") ?? error.descriptiveMessage)")
		}

		try save(Entry(etag: httpResponse?.value(forHTTPHeaderField: "ETag"), date: .now, body: data), to: file)
		return value
	}

	/**
	The file of the cached response, by the method, the URL, and the body, as GraphQL requests have the same URL. The headers are not part of it, as the GitHub token of CI changes on each run, which would make each run miss the cache.
	*/
	private func file(for request: URLRequest) -> URL? {
		guard request.url != nil else {
			return nil
		}

		return directory?.appending(path: "\(request.responseCacheKey).json")
	}

	/**
	A warning for each cached response that was used because its request failed, so a build can say that some data may be old.
	*/
	public var warnings: [Warning] {
		staleResponses.all
	}

	private func save(_ entry: Entry, to file: URL?) throws {
		guard let file else {
			return
		}

		try file.deletingLastPathComponent().createDirectory()
		try JSONEncoder().encode(entry).write(to: file, options: .atomic)
	}
}

extension ResponseCache {
	/**
	A request that failed without a cached response to use. It says the URL, as the error of the request often does not, like when the network is off.
	*/
	private struct RequestError: Error, CustomStringConvertible {
		let url: URL?

		/**
		Why there is no response, like “the request failed: Could not connect to the server.”
		*/
		let reason: String

		var description: String {
			"Could not get \(url, default: "an unknown URL"), because \(reason)"
		}
	}
}

extension URLRequest {
	/**
	A stable digest of the method, the URL, and the exact bytes of the body, for the name of a cache file.
	*/
	var responseCacheKey: String {
		struct Identity: Encodable {
			let url: String?
			let method: String
			let body: Data?
		}

		let identity = Identity(
			url: url?.absoluteString,
			method: httpMethod ?? "GET",
			body: httpBody
		)

		let data = Data(JSONEncoder.pageJSON(identity).utf8)
		return SHA256.hash(data: data).map { ($0 < 16 ? "0" : "") + String($0, radix: 16) }.joined()
	}
}
