import Foundation

/**
Reports which directories changed: a file was added, removed, or modified.

It compares the modification dates of the files every half second. That is simple and fast enough for the few thousand files of a site project.

```swift
for await changed in DirectoryWatcher(directories: [content, sources]) {
	print(changed) // The directories with changes.
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
	Returns the directories that changed since the previous element, and `nil` when the task is cancelled.
	*/
	public struct Iterator: AsyncIteratorProtocol, Sendable {
		let directories: [URL]
		let interval: Duration
		private var snapshots: [[String: Date]]

		init(directories: [URL], interval: Duration) {
			self.directories = directories
			self.interval = interval
			self.snapshots = directories.map(Self.snapshot)
		}

		public mutating func next() async -> Set<URL>? {
			while true {
				do {
					try await Task.sleep(for: interval)
				} catch {
					return nil
				}

				let latest = directories.map(Self.snapshot)
				let changed = Set(zip(directories, zip(snapshots, latest)).filter { $1.0 != $1.1 }.map(\.0))
				snapshots = latest

				if !changed.isEmpty {
					return changed
				}
			}
		}

		/**
		The modification date of each file in the directory. Hidden files, like `.DS_Store`, are left out.
		*/
		private static func snapshot(of directory: URL) -> [String: Date] {
			let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)?.compactMap { $0 as? URL } ?? []

			return Dictionary(files.map { file in
				(file.path, (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
			}) { first, _ in first }
		}
	}
}
