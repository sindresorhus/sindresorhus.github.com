import Foundation
import Synchronization

/**
A possible problem that does not fail the build, like a request for extra data that failed, or a spelling mistake that `website check` finds.

It is printed after where it is, like `content/apps/dato/index.md:12: Unknown word: “shorcut”.`, or alone when it is not in a file, like a failed request.
*/
public struct Warning: Hashable, Sendable, CustomStringConvertible {
	/**
	What kind of problem it is, like a vague link text, so `website check` can count the warnings of each kind. The code that finds a kind of problem declares it as a static member, like ``failedRequest``, and the warnings use the member, so the kinds are not misspelled.
	*/
	public struct Kind: Hashable, Sendable, CustomStringConvertible {
		/**
		What the problem is, in the singular, like “Vague link text”, for the summary of `website check`.
		*/
		public let description: String

		public init(_ description: String) {
			self.description = description
		}
	}

	public let kind: Kind

	/**
	`nil` when it is not in a file or page, like a failed request.
	*/
	public let location: SourceLocation?

	public let message: String

	public init(_ kind: Kind, at location: SourceLocation? = nil, _ message: String) {
		self.kind = kind
		self.location = location
		self.message = message
	}

	public var description: String {
		location.map { "\($0): \(message)" } ?? message
	}
}

extension Warning.Kind {
	/**
	A request for extra data that failed, so the pages leave the data out.
	*/
	public static let failedRequest = Self("Failed request")

	/**
	A cached response that was used because its request failed, so the data may be old.
	*/
	public static let staleResponse = Self("Cached response of a failed request")
}

/**
Collects the warnings of work that runs at the same time, like the requests of a build. It is a class, so the work can share it.
*/
public final class WarningCollector: Sendable {
	private let warnings = Mutex<[Warning]>([])

	public init() {}

	/**
	Adds a warning. It is safe to call from work that runs at the same time.
	*/
	public func add(_ warning: Warning) {
		warnings.withLock {
			$0.append(warning)
		}
	}

	/**
	The warnings in the order of their text, as work that runs at the same time adds them in any order.
	*/
	public var all: [Warning] {
		warnings.withLock(\.self).sorted(using: KeyPathComparator(\.description, comparator: .localizedStandard))
	}

	/**
	The value of the request, or `nil` with a warning when it fails, so the page leaves the value out. A failure after task cancellation leaves out the value without a warning. The warning is the message followed by the error, like “Could not get the popular GitHub repos, so the about page leaves them out: …”.
	*/
	public func value<Value: Sendable>(warning message: String, _ request: @Sendable () async throws -> Value) async -> Value? {
		do {
			return try await request()
		} catch {
			guard !Task.isCancelled else {
				return nil
			}

			add(Warning(.failedRequest, "\(message): \(error)"))
			return nil
		}
	}

	/**
	The values of the keys, like the ratings of apps by their IDs, each from one request, and the requests run at the same time. A request that fails is a warning, like in ``value(warning:_:)``, and its key is left out, so the others still have their values.

	```swift
	let ratings = await warnings.values(of: ids) { id in
		"Could not get the rating of \(id), so its page leaves it out"
	} request: { id in
		try await cache.decoded(Rating.self, from: URLRequest(url: url(of: id)))
	}
	```
	*/
	public func values<Key: Hashable & Sendable, Value: Sendable>(
		of keys: some Sequence<Key>,
		warning message: @escaping @Sendable (Key) -> String,
		request: @escaping @Sendable (Key) async throws -> Value
	) async -> [Key: Value] {
		await withTaskGroup(of: (Key, Value?).self) { group in
			for key in Set(keys) {
				group.addTask {
					await (key, self.value(warning: message(key)) { try await request(key) })
				}
			}

			// The keys whose request failed are left out.
			var values = [Key: Value]()

			for await case (let key, let value?) in group {
				values[key] = value
			}

			return values
		}
	}
}
