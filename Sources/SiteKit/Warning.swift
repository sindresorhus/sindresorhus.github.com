import Foundation
import Synchronization

/**
A possible problem that does not fail the build, like a request for extra data that failed, or a spelling mistake that `website check` finds.

It is printed after where it is, like `content/apps/dato/index.md:12: Unknown word: “shorcut”.`, or alone when it is not in a file, like a failed request.
*/
public struct Warning: Hashable, Sendable, CustomStringConvertible {
	/**
	Where the problem is, like `content/apps/dato/index.md:12`, `content/apps/dato/icon.png`, or a page path. `nil` when it is not in a file or page, like a failed request.
	*/
	public let location: String?

	public let message: String

	public init(location: String? = nil, message: String) {
		self.location = location
		self.message = message
	}

	public var description: String {
		location.map { "\($0): \(message)" } ?? message
	}
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
}
