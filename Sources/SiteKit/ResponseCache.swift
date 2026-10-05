import Foundation

/**
Fetches JSON, like from the App Store and GitHub, with a cache on disk.

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
	public static func forBuilds(of project: Project, environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
		let isContinuousIntegration = environment["CI"] != nil

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
		let maximumAge = maximumAge ?? self.maximumAge
		let file = file(for: request)
		let entry = file.flatMap { try? JSONDecoder().decode(Entry.self, from: Data(contentsOf: $0)) }

		if
			let entry,
			Date.now.timeIntervalSince(entry.date) < maximumAge / .seconds(1)
		{
			do {
				return try decoder.decode(Value.self, from: entry.body)
			} catch {
				try? file?.removeIfExists()
				throw error
			}
		}

		// An outdated cached response that cannot be decoded is neither revalidated nor used when the request fails.
		let cached = entry.flatMap { entry in
			(try? decoder.decode(Value.self, from: entry.body)).map { (entry: entry, value: $0) }
		}

		var request = request

		if let etag = cached?.entry.etag {
			request.setValue(etag, forHTTPHeaderField: "If-None-Match")
		}

		// A failed request, an error status like a rate limit, or a response that cannot be decoded, uses the cached response.
		func cachedValue(after error: any Error, reason: String = "the request failed") throws -> Value {
			guard let cached else {
				throw RequestError(url: request.url, underlyingError: error)
			}

			staleResponses.add(Warning(message: "Using a cached response for \(request.url, default: ""), because \(reason): \(error.localizedDescription)"))
			return cached.value
		}

		let data: Data
		let response: URLResponse

		do {
			(data, response) = try await Self.session.data(for: request)
		} catch {
			return try cachedValue(after: error)
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
			return try cachedValue(after: URLError(.badServerResponse, userInfo: [NSURLErrorFailingURLErrorKey: request.url as Any, NSLocalizedDescriptionKey: "The server responded with status \(statusCode)."]))
		}

		let value: Value

		do {
			value = try decoder.decode(Value.self, from: data)
		} catch {
			return try cachedValue(after: error, reason: "the response could not be read")
		}

		try save(Entry(etag: httpResponse?.value(forHTTPHeaderField: "ETag"), date: .now, body: data), to: file)
		return value
	}

	/**
	The file of the cached response. The body is part of the key, as GraphQL requests have the same URL. Requests without a body keep the key of the URL alone.
	*/
	private func file(for request: URLRequest) -> URL? {
		request.url.flatMap { url in
			let key = url.absoluteString + (request.httpBody.map { String(decoding: $0, as: UTF8.self) } ?? "")
			return directory?.appending(path: "\(String(key.stableHash, radix: 16)).json")
		}
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
	struct RequestError: Error, CustomStringConvertible {
		let url: URL?
		let underlyingError: any Error

		var description: String {
			"The request for \(url, default: "an unknown URL") failed: \(underlyingError)"
		}
	}
}
