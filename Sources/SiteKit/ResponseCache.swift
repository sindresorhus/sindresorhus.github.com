import CryptoKit
import Foundation
import Synchronization

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
	The cached responses that were used because their request failed. It is shared by the copies of the cache, except a copy for another build (``forAnotherBuild``).
	*/
	private var staleResponses = StaleResponses()

	/**
	The decoded values of the responses, so a process that builds several times, like `website serve` after each edit, does not read and decode the files again while the responses are fresh. It is shared by the copies of the cache.
	*/
	private let decodedValues = DecodedValues()

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
	A copy for another build of the same process, like each build of `website serve`, which shares the decoded values, but not the warnings of the earlier builds, as each build prints its own.
	*/
	public var forAnotherBuild: Self {
		var copy = self
		copy.staleResponses = StaleResponses()
		return copy
	}

	/**
	Fetches and decodes JSON. Dates are ISO 8601. Throws for responses other than 2xx and 304.

	A response is decoded before it is saved. A response that cannot be decoded, like a GraphQL error with status 200, is not saved, and is handled like a failed request, so the cached response stays and the next build asks again. A cached response that cannot be decoded, like after the type changed, is removed, so the next build asks again.

	- Parameter maximumAge: How long the response is used without asking again, like a long time for data that never changes, such as the contributions of a past year. Defaults to the maximum age of the cache.
	*/
	public func decoded<Value: Decodable & Sendable>(_ type: Value.Type = Value.self, from request: URLRequest, maximumAge: Duration? = nil) async throws -> Value {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601

		return try await decoded(from: request, maximumAge: maximumAge) {
			try decoder.decode(Value.self, from: $0)
		}
	}

	/**
	Fetches and decodes JSON with the common 15-second data-request timeout. Use the request-taking overload for custom headers, methods, or timeouts.
	*/
	public func decoded<Value: Decodable & Sendable>(_ type: Value.Type = Value.self, from url: URL, maximumAge: Duration? = nil) async throws -> Value {
		try await decoded(type, from: URLRequest(url: url, timeoutInterval: 15), maximumAge: maximumAge)
	}

	/**
	Fetches a body with the common 15-second data-request timeout and reads it with the function, retaining the cache behavior of the request-taking overload.
	*/
	public func decoded<Value: Sendable>(from url: URL, maximumAge: Duration? = nil, decode: (Data) throws -> Value) async throws -> Value {
		try await decoded(from: URLRequest(url: url, timeoutInterval: 15), maximumAge: maximumAge, decode: decode)
	}

	/**
	Fetches the body and reads it with the function, like the names in a JavaScript file, with the caching of ``decoded(_:from:maximumAge:)``. The function throws for a body that it cannot read, so the body is not saved, and the cached response is used.

	A cached response that is used because its request failed is kept in memory with the time of the failure, so the later builds of the process, like each rebuild of `website serve`, use it without asking again until it is outdated, like a fresh response. Each of them still warns about it, as its data is still old.
	*/
	public func decoded<Value: Sendable>(from request: URLRequest, maximumAge: Duration? = nil, decode: (Data) throws -> Value) async throws -> Value {
		try Task.checkCancellation()
		let maximumAge = maximumAge ?? self.maximumAge

		func isFresh(_ date: Date) -> Bool {
			Date.now.timeIntervalSince(date) < maximumAge / .seconds(1)
		}

		let file = file(for: request)
		// By the type too, as the same response could be read as another type.
		let requestKey = request.responseCacheKey

		if
			let decodedValue = decodedValues.value(for: requestKey, as: Value.self),
			isFresh(decodedValue.date)
		{
			// The data is still old, so each build says it.
			if let failure = decodedValue.failure {
				staleResponses.add(url: request.url, failure: failure)
			}

			return decodedValue.value
		}

		let entry = file.flatMap { try? JSONDecoder().decode(Entry.self, from: Data(contentsOf: $0)) }

		if
			let entry,
			isFresh(entry.date)
		{
			do {
				let value = try decode(entry.body)
				return decodedValues.remember(value, date: entry.date, for: requestKey)
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
		func cachedValue(because failure: FailureCause) throws -> Value {
			guard let cached else {
				throw RequestError(url: request.url, failure: failure)
			}

			staleResponses.add(url: request.url, failure: failure)
			return decodedValues.remember(cached.value, date: .now, failure: failure, for: requestKey)
		}

		let data: Data
		let response: URLResponse

		do {
			(data, response) = try await Self.session.data(for: request)
		} catch {
			try Task.checkCancellation()
			return try cachedValue(because: .requestFailed(error.descriptiveMessage))
		}

		let httpResponse = response as? HTTPURLResponse
		let statusCode = httpResponse?.statusCode ?? 0

		if
			statusCode == 304,
			let cached
		{
			let refreshed = Entry(etag: cached.entry.etag, date: .now, body: cached.entry.body)
			return try save(refreshed, value: cached.value, for: requestKey, to: file)
		}

		guard (200..<300).contains(statusCode) else {
			return try cachedValue(because: .httpStatus(statusCode, hint: httpResponse?.usedUpRateLimitHint))
		}

		let value: Value

		do {
			value = try decode(data)
		} catch {
			// The localized description of a decoding error does not say what is wrong, like which key is missing.
			return try cachedValue(because: .unreadableBody((error as? DecodingError)?.readableDescription(root: "response") ?? error.descriptiveMessage))
		}

		let fetched = Entry(etag: httpResponse?.value(forHTTPHeaderField: "ETag"), date: .now, body: data)
		return try save(fetched, value: value, for: requestKey, to: file)
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
	A warning for the cached responses that were used because their request failed, so a build can say that some data may be old. It is one warning for each host and reason, with the number of responses and one of their URLs, as a server that refuses all requests, like the review feeds of the App Store, would otherwise give one warning for each of many URLs.
	*/
	public var warnings: [Warning] {
		Dictionary(grouping: staleResponses.all) { StaleResponses.Group(host: $0.url?.host(), failure: $0.failure) }
			.values
			.map { responses in
				let reason = responses[0].failure.description
				// Each URL once, as a response can be read twice in a build, like as two types.
				let urls = Set(responses.map { $0.url?.absoluteString ?? "" })
				let example = urls.min() ?? ""

				guard urls.count > 1 else {
					return Warning(.staleResponse, "Using a cached response for \(example), because \(reason)")
				}

				return Warning(.staleResponse, "Using cached responses for \(urls.count) URLs of \(responses[0].url?.host() ?? "an unknown host"), like \(example), because \(reason)")
			}
			.sorted(using: KeyPathComparator(\.description, comparator: .localizedStandard))
	}

	/**
	Persists a usable response before remembering its decoded value, so a failed disk write never leaves a success visible only in memory.
	*/
	private func save<Value: Sendable>(_ entry: Entry, value: Value, for request: String, to file: URL?) throws -> Value {
		if let file {
			try file.deletingLastPathComponent().createDirectory()
			try JSONEncoder().encode(entry).write(to: file, options: .atomic)
		}

		return decodedValues.remember(value, date: entry.date, for: request)
	}
}

extension ResponseCache {
	/**
	Why a response could not be used. Only an HTTP failure carries a status code; descriptions remain the same for errors and stale-cache warnings.
	*/
	fileprivate enum FailureCause: Hashable, Sendable, CustomStringConvertible {
		case httpStatus(Int, hint: String?)
		case requestFailed(String)
		case unreadableBody(String)

		var statusCode: Int? {
			guard case .httpStatus(let code, _) = self else {
				return nil
			}

			return code
		}

		var description: String {
			switch self {
			case .httpStatus(let code, let hint):
				"the request failed: The server responded with status \(code).\(hint ?? "")"
			case .requestFailed(let message):
				"the request failed: \(message)"
			case .unreadableBody(let message):
				"the response could not be read: \(message)"
			}
		}
	}

	/**
	The decoded values by the key of their request and their type, with the dates of their responses, so the cache uses a value while its response is fresh, like the file of the response. A value of a cached response that was used because its request failed has the reason of the failure (`failure`), and the date of the failure.

	Limitation: A response file that another process changes, like `website check` while `website serve` runs, or that is removed, is not seen until the value is outdated.
	*/
	private final class DecodedValues: Sendable {
		/**
		The request and exact result type, as unrelated types can have the same displayed name.
		*/
		private struct Key: Hashable {
			let request: String
			let type: ObjectIdentifier
		}

		/**
		The type belongs to the entire entry, so its value and identity cannot be assembled independently by a caller.
		*/
		struct CachedValue<Value: Sendable>: Sendable {
			let date: Date
			let value: Value
			let failure: FailureCause?
		}

		private let values = Mutex<[Key: any Sendable]>([:])

		/**
		Reads an entry using the same exact Swift type that defines its key. Erasure stays behind this boundary.
		*/
		func value<Value: Sendable>(for request: String, as type: Value.Type) -> CachedValue<Value>? {
			values.withLock { $0[Key(request: request, type: ObjectIdentifier(type))] as? CachedValue<Value> }
		}

		/**
		Remembers the value with its freshness and optional stale reason, returning it for the request's success path.
		*/
		func remember<Value: Sendable>(_ value: Value, date: Date, failure: FailureCause? = nil, for request: String) -> Value {
			values.withLock {
				$0[Key(request: request, type: ObjectIdentifier(Value.self))] = CachedValue(date: date, value: value, failure: failure)
			}
			return value
		}
	}

	/**
	The cached responses that were used because their request failed, with why, like “the request failed: The server responded with status 403.”
	*/
	private final class StaleResponses: Sendable {
		/**
		The server and failure are identity; their rendered diagnostic text is only presentation.
		*/
		struct Group: Hashable {
			let host: String?
			let failure: FailureCause
		}

		private let responses = Mutex<[(url: URL?, failure: FailureCause)]>([])

		func add(url: URL?, failure: FailureCause) {
			responses.withLock {
				$0.append((url, failure))
			}
		}

		var all: [(url: URL?, failure: FailureCause)] {
			responses.withLock(\.self)
		}
	}

	/**
	A body that the function of ``decoded(from:maximumAge:decode:)`` cannot read, like a page without the expected data. The description says what is wrong, like “The page has no `aggregateRating`.”
	*/
	public struct ReadError: Error, CustomStringConvertible {
		public let description: String

		public init(_ description: String) {
			self.description = description
		}
	}

	/**
	A request that failed without a cached response to use. It says the URL, as the error of the request often does not, like when the network is off.
	*/
	public struct RequestError: Error, CustomStringConvertible {
		let url: URL?

		/**
		The status of the response, like `404`, or `nil` when there was no response, like when the network is off.
		*/
		public var statusCode: Int? {
			failure.statusCode
		}

		/**
		Why there is no response, like “the request failed: Could not connect to the server.”
		*/
		fileprivate let failure: FailureCause

		public var description: String {
			"Could not get \(url, default: "an unknown URL"), because \(failure)"
		}
	}
}

extension HTTPURLResponse {
	/**
	Why a request was refused, when it is because the rate limit is used up, like “ The rate limit is used up until 14:20.”, with a space before it, or `nil` for another reason. A refused request of GitHub looks like a permission problem, as it has status 403 when the limit is used up. GitHub gives a token a much higher limit.
	*/
	fileprivate var usedUpRateLimitHint: String? {
		guard
			[403, 429].contains(statusCode),
			value(forHTTPHeaderField: "x-ratelimit-remaining") == "0"
		else {
			return nil
		}

		let reset = value(forHTTPHeaderField: "x-ratelimit-reset").flatMap(TimeInterval.init).map { " until \(Date(timeIntervalSince1970: $0).formatted(date: .omitted, time: .shortened))" } ?? ""
		let tokenHint = url?.host() == "api.github.com" ? " Set `GITHUB_TOKEN`, or log in with `gh auth login`, for the higher limit of a token." : ""
		return " The rate limit is used up\(reset).\(tokenHint)"
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
		return SHA256.hash(data: data).hexString
	}
}
