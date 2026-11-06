import CoreServices
import Foundation
import Synchronization

/**
Reports which files in the directories changed: they were added, removed, modified, or renamed.

It uses the file events of FSEvents, so the system reports a save after the latency, and an idle watcher does no work. A directory that is removed or renamed is reported too, as the system reports a moved directory without the files in it. Hidden files, like `.DS_Store`, and the temporary files of an atomic save are left out.

The changes that happen before the next element are reported together, like the changes during a rebuild.

```swift
for await changed in DirectoryWatcher(directories: [content, sources]) {
	print(changed) // The files that changed.
}
```
*/
public struct DirectoryWatcher: AsyncSequence, Sendable {
	public let directories: [URL]

	/**
	How long the system collects the events before it reports them, so a save that writes several files is one change.
	*/
	public let latency: Duration

	public init(directories: [URL], latency: Duration = .milliseconds(100)) {
		self.directories = directories
		self.latency = latency
	}

	/**
	Starts to watch the directories, so the changes from now on are reported, also the ones before the first call of `next()`.
	*/
	public func makeAsyncIterator() -> Iterator {
		Iterator(events: EventStream(directories: directories, latency: latency))
	}

	/**
	Returns the files that changed since the previous element, and `nil` when the task is cancelled.
	*/
	public struct Iterator: AsyncIteratorProtocol, Sendable {
		/**
		The iterator owns the stream until iteration ends or the iterator is gone, so a finished iterator no longer keeps file events running.
		*/
		var events: EventStream?

		public mutating func next() async -> Set<URL>? {
			guard
				!Task.isCancelled,
				let changed = await events?.next()
			else {
				events = nil
				return nil
			}

			return changed
		}
	}
}

extension DirectoryWatcher {
	/**
	An FSEvents stream of the directories, which collects the changed files until the watcher asks for them.
	*/
	final class EventStream: Sendable {
		/**
		The event flags read by the watcher, separate from the flags used to create a stream.
		*/
		private struct Flags: OptionSet, Sendable {
			let rawValue: FSEventStreamEventFlags

			static let isDirectory = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir))
			static let renamed = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed))
			static let removed = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved))
		}

		/**
		The stream has its own reference to the changes, which it releases when it is gone, so a callback that is still running after `deinit` has its changes.
		*/
		private let changes = Changes()

		/**
		Set once in `init`, and only released in `deinit`.
		*/
		nonisolated(unsafe) private var stream: FSEventStreamRef?

		init(directories: [URL], latency: Duration) {
			var context = FSEventStreamContext(
				version: 0,
				info: Unmanaged.passRetained(changes).toOpaque(),
				retain: nil,
				release: { info in
					if let info {
						Unmanaged<Changes>.fromOpaque(info).release()
					}
				},
				copyDescription: nil
			)

			let callback: FSEventStreamCallback = { _, info, count, paths, flags, _ in
				guard
					let info,
					let paths = Unmanaged<NSArray>.fromOpaque(paths).takeUnretainedValue() as? [String]
				else {
					return
				}

				let changed = zip(paths, UnsafeBufferPointer(start: flags, count: count)).compactMap { path, flags -> URL? in
					let url = URL(filePath: path)
					let flags = Flags(rawValue: flags)

					// A new directory is no change, as its files are reported when they are written. The temporary file of an atomic save is gone after the save, and it is named after the file, like `dato.md.sb-1a2b3c4d-X7yZ` for `dato.md`, so a file that is gone and starts with the name of a file next to it did not change anything either. Another file that is gone was removed, also when the system says that it was made, as the system keeps that flag of a new file for its later events, like when it is moved to the trash.
					let isChange = if flags.contains(.isDirectory) {
						!flags.isDisjoint(with: [.renamed, .removed])
					} else {
						url.exists || !url.deletingLastPathComponent().files.contains { url.lastPathComponent.hasPrefix($0.lastPathComponent + ".") }
					}

					guard
						isChange,
						!url.lastPathComponent.hasPrefix(".")
					else {
						return nil
					}

					return url
				}

				Unmanaged<Changes>.fromOpaque(info).takeUnretainedValue().add(changed)
			}

			// A directory that does not exist yet is watched too, so its files are reported when it is made.
			guard let stream = FSEventStreamCreate(
				nil,
				callback,
				&context,
				directories.map { $0.path(percentEncoded: false) } as CFArray,
				FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
				latency / .seconds(1),
				FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
			) else {
				Unmanaged.passUnretained(changes).release()
				return
			}

			FSEventStreamSetDispatchQueue(stream, DispatchQueue(label: "DirectoryWatcher", qos: .utility))

			// It does not fail in practice, so a stream that does not start only reports no changes.
			guard FSEventStreamStart(stream) else {
				FSEventStreamInvalidate(stream)
				FSEventStreamRelease(stream)
				return
			}

			self.stream = stream

			// The system can report the changes of the last moment before the stream started, like the files of a directory that was just made, so they are delivered now and left out.
			FSEventStreamFlushSync(stream)
			changes.removeAll()
		}

		deinit {
			guard let stream else {
				return
			}

			FSEventStreamStop(stream)
			FSEventStreamInvalidate(stream)
			FSEventStreamRelease(stream)
		}

		/**
		The files that changed since the previous call, after waiting for a change when there is none yet. `nil` when the task is cancelled.
		*/
		func next() async -> Set<URL>? {
			await changes.next()
		}
	}

	/**
	The changed files that the stream collects until the watcher asks for them.
	*/
	private final class Changes: Sendable {
		private struct State {
			var changed = Set<URL>()

			/**
			The `next()` call that waits for a change.
			*/
			var waiter: CheckedContinuation<Set<URL>?, Never>?
		}

		private let state = Mutex(State())

		func add(_ files: [URL]) {
			guard !files.isEmpty else {
				return
			}

			state.withLock { state in
				state.changed.formUnion(files)

				if let waiter = state.waiter {
					state.waiter = nil
					waiter.resume(returning: state.changed)
					state.changed = []
				}
			}
		}

		func removeAll() {
			state.withLock { $0.changed = [] }
		}

		func next() async -> Set<URL>? {
			await withTaskCancellationHandler {
				await withCheckedContinuation { continuation in
					state.withLock { state in
						if !state.changed.isEmpty {
							continuation.resume(returning: state.changed)
							state.changed = []
						} else if Task.isCancelled {
							continuation.resume(returning: nil)
						} else {
							state.waiter = continuation
						}
					}
				}
			} onCancel: {
				state.withLock { state in
					state.waiter?.resume(returning: nil)
					state.waiter = nil
				}
			}
		}
	}
}
