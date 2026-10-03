import Foundation
import SiteKit
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
Fetches JSON from the App Store and GitHub, with a cache on disk.

A cached response is used while it is younger than `maximumAge`. After that, it is revalidated with its ETag, so an unchanged response costs no download and, for GitHub, no rate limit.

Local builds use a maximum age of an hour, and a cached response when the network fails, so rebuilds are fast and work offline. Deploy builds use a maximum age of zero and never use a stale response, so the data is always fresh.
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
	Whether a cached response is used when the request fails.
	*/
	let usesStaleResponseOnFailure: Bool

	public init(directory: URL?, maximumAge: Duration, usesStaleResponseOnFailure: Bool) {
		self.directory = directory
		self.maximumAge = maximumAge
		self.usesStaleResponseOnFailure = usesStaleResponseOnFailure
	}

	/**
	The cache for builds of the project: in `.cache/responses`, and fresh on CI.
	*/
	public static func forBuilds(of project: Project, environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
		let isContinuousIntegration = environment["CI"] != nil

		return Self(
			directory: project.root.appending(path: ".cache/responses"),
			maximumAge: isContinuousIntegration ? .zero : .seconds(60 * 60),
			usesStaleResponseOnFailure: !isContinuousIntegration
		)
	}

	/**
	No cache. Every request goes to the network.
	*/
	public static let disabled = Self(directory: nil, maximumAge: .zero, usesStaleResponseOnFailure: false)

	/**
	Fetches and decodes JSON. Dates are ISO 8601. Throws for responses other than 2xx and 304.
	*/
	func decoded<Value: Decodable>(_ type: Value.Type = Value.self, from request: URLRequest) async throws -> Value {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return try await decoder.decode(Value.self, from: data(for: request))
	}

	private func data(for request: URLRequest) async throws -> Data {
		let file = request.url.flatMap { url in
			directory?.appending(path: "\(String(url.absoluteString.stableHash, radix: 16)).json")
		}

		let cached = file.flatMap { try? JSONDecoder().decode(Entry.self, from: Data(contentsOf: $0)) }

		if
			let cached,
			Date.now.timeIntervalSince(cached.date) < maximumAge.timeInterval
		{
			return cached.body
		}

		var request = request

		if let etag = cached?.etag {
			request.setValue(etag, forHTTPHeaderField: "If-None-Match")
		}

		let data: Data
		let response: URLResponse

		// A failed request, or an error status like a rate limit, uses the cached response when allowed.
		func cachedResponse(after error: any Error) throws -> Data {
			guard
				usesStaleResponseOnFailure,
				let cached
			else {
				throw error
			}

			print("Warning: Using a cached response for \(request.url?.absoluteString ?? ""), because the request failed: \(error.localizedDescription)")
			return cached.body
		}

		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			return try cachedResponse(after: error)
		}

		let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

		if
			statusCode == 304,
			let cached
		{
			try save(Entry(etag: cached.etag, date: .now, body: cached.body), to: file)
			return cached.body
		}

		guard (200..<300).contains(statusCode) else {
			return try cachedResponse(after: URLError(.badServerResponse, userInfo: [NSURLErrorFailingURLErrorKey: request.url as Any, NSLocalizedDescriptionKey: "The server responded with status \(statusCode)."]))
		}

		try save(Entry(etag: (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "ETag"), date: .now, body: data), to: file)
		return data
	}

	private func save(_ entry: Entry, to file: URL?) throws {
		guard let file else {
			return
		}

		try file.deletingLastPathComponent().createDirectory()
		try JSONEncoder().encode(entry).write(to: file, options: .atomic)
	}
}

extension Duration {
	fileprivate var timeInterval: TimeInterval {
		let (seconds, attoseconds) = components
		return Double(seconds) + Double(attoseconds) / 1e18
	}
}
