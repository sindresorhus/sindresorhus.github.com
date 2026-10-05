import Foundation

/**
Reports which files in the directories changed: they were added, removed, or modified.

It compares the modification dates of the files every half second. That is simple and fast enough for the few thousand files of a site project.

```swift
for await changed in DirectoryWatcher(directories: [content, sources]) {
	print(changed) // The files that changed.
}
```
*/
public struct DirectoryWatcher: AsyncSequence, Sendable {
	public let directories: [URL]
	public let interval: Duration

	public init(directories: [URL], interval: Duration = .milliseconds(500)) {
		self.directories = directories
		self.interval = interval
	}

	public func makeAsyncIterator() -> Iterator {
		Iterator(directories: directories, interval: interval)
	}

	/**
	Returns the files that changed since the previous element, and `nil` when the task is cancelled.
	*/
	public struct Iterator: AsyncIteratorProtocol, Sendable {
		let directories: [URL]
		let interval: Duration
		private var snapshot: [URL: Date]

		init(directories: [URL], interval: Duration) {
			self.directories = directories
			self.interval = interval
			self.snapshot = Self.snapshot(of: directories)
		}

		public mutating func next() async -> Set<URL>? {
			while true {
				do {
					try await Task.sleep(for: interval)
				} catch {
					return nil
				}

				let latest = Self.snapshot(of: directories)
				let changed = Set(latest.keys).union(snapshot.keys).filter { latest[$0] != snapshot[$0] }
				snapshot = latest

				if !changed.isEmpty {
					return changed
				}
			}
		}

		/**
		The modification date of each file in the directories. Hidden files, like `.DS_Store`, are left out.
		*/
		private static func snapshot(of directories: [URL]) -> [URL: Date] {
			Dictionary(directories.flatMap { $0.contentsRecursively(includesHiddenFiles: false) }.map { file in
				(file, (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
			}) { first, _ in first }
		}
	}
}
