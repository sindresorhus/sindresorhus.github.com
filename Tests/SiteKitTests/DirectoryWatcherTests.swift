import Foundation
import TestSupport
import Testing
import SiteKit

/**
The tests wait for a change of the file system, so a slow CI runner, where the whole suite runs at once, can take longer than a minute to report one, though it never hangs.
*/
@Suite(.timeLimit(.minutes(3)))
struct DirectoryWatcherTests {
	@Test(.temporaryDirectory)
	func `a changed size is reported even when the modification date stays the same`() async throws {
		let root = try URL.temporaryDirectory(files: ["file.txt": "old"])
		var file = root.appending(path: "file.txt")
		let originalDate = try #require(file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
		var changes = DirectoryWatcher(directories: [root], latency: .milliseconds(20)).makeAsyncIterator()
		try Data("a longer replacement".utf8).write(to: file)
		var values = URLResourceValues()
		values.contentModificationDate = originalDate
		try file.setResourceValues(values)
		#expect(try file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate == originalDate)
		let changed = await changes.next()
		// File enumeration resolves the /var alias of the temporary directory to /private/var on macOS.
		#expect(changed?.map(\.standardizedFileURL) == [file.standardizedFileURL])
	}

	@Test(.temporaryDirectory)
	func `reports the changed files`() async throws {
		let root = try URL.temporaryDirectory(files: ["first/.keep": "", "second/.keep": ""])
		let first = root.appending(path: "first")
		let second = root.appending(path: "second")

		var changes = DirectoryWatcher(directories: [first, second], latency: .milliseconds(20)).makeAsyncIterator()
		let file = second.appending(path: "file.txt")
		try Data("New".utf8).write(to: file)

		#expect(await changes.next()?.map(\.lastPathComponent) == [file.lastPathComponent])
	}

	/**
	Editors save atomically: they write a temporary file, like `Clock.js.sb-1a2b3c4d-X7yZ`, and move it over the file.
	*/
	@Test(.temporaryDirectory)
	func `reports only the file of an atomic save, not its temporary file or directory`() async throws {
		let root = try URL.temporaryDirectory(files: ["sources/Scripts/Clock.js": "old"])
		let file = root.appending(path: "sources/Scripts/Clock.js")

		// A longer latency, so the save is done when the event arrives, also on a busy machine, and its temporary file is gone.
		var changes = DirectoryWatcher(directories: [root.appending(path: "sources")], latency: .milliseconds(250)).makeAsyncIterator()
		try Data("new".utf8).write(to: file, options: .atomic)

		#expect(await changes.next()?.map(\.lastPathComponent) == [file.lastPathComponent])
	}

	/**
	The system keeps the “created” flag of a new file for its later events, so a new file that is moved away, like to the trash, has the flags of the temporary file of an atomic save.
	*/
	@Test(.temporaryDirectory)
	func `reports a new file that is moved away`() async throws {
		let root = try URL.temporaryDirectory(files: ["content/.keep": ""])
		let file = root.appending(path: "content/draft.md")

		var changes = DirectoryWatcher(directories: [root.appending(path: "content")], latency: .milliseconds(20)).makeAsyncIterator()
		try Data("Draft".utf8).write(to: file)
		#expect(await changes.next()?.map(\.lastPathComponent) == [file.lastPathComponent])

		try FileManager.default.moveItem(at: file, to: root.appending(path: "draft.md"))
		#expect(await changes.next()?.map(\.lastPathComponent) == [file.lastPathComponent])
	}

	/**
	A file that the build loaded can be removed while it runs, which is a change of the content too.
	*/
	@Test(.temporaryDirectory)
	func `reports a removed file`() async throws {
		let root = try URL.temporaryDirectory(files: ["notes.md": "Notes"])
		let file = root.appending(path: "notes.md")

		var changes = DirectoryWatcher(directories: [root], latency: .milliseconds(20)).makeAsyncIterator()
		try FileManager.default.removeItem(at: file)

		#expect(await changes.next()?.map(\.lastPathComponent) == [file.lastPathComponent])
	}

	/**
	The hidden files that macOS writes, like `.DS_Store`, are no change of the content, so they are left out.
	*/
	@Test(.temporaryDirectory)
	func `leaves out hidden files`() async throws {
		let root = try URL.temporaryDirectory(files: [".keep": ""])
		let file = root.appending(path: "visible.md")

		var changes = DirectoryWatcher(directories: [root], latency: .milliseconds(20)).makeAsyncIterator()
		try Data("Hidden".utf8).write(to: root.appending(path: ".DS_Store"))
		try Data("Visible".utf8).write(to: file)

		#expect(await changes.next()?.map(\.lastPathComponent) == [file.lastPathComponent])
	}

	/**
	`website serve` stops watching when the task stops, instead of waiting for a change that never comes.
	*/
	@Test(.temporaryDirectory)
	func `a cancelled task ends the changes`() async throws {
		// No file, as the system can report a file that was made just before the watcher started, which would end the wait before the cancel.
		let root = try URL.temporaryDirectory()
		let watcher = DirectoryWatcher(directories: [root], latency: .milliseconds(20))

		let changes = watcher.makeAsyncIterator()
		let task = Task {
			var changes = changes
			return await changes.next()
		}

		task.cancel()

		#expect(await task.value == nil)
	}

	@Test(.temporaryDirectory)
	func `cancellation permanently ends an iterator`() async throws {
		let root = try URL.temporaryDirectory()
		let changes = DirectoryWatcher(directories: [root], latency: .milliseconds(20)).makeAsyncIterator()

		var finished = await Task {
			var changes = changes
			withUnsafeCurrentTask { task in
				task?.cancel()
			}
			#expect(await changes.next() == nil)
			return changes
		}.value

		// Iteration stays finished in a task that is not cancelled, even after a new file arrives.
		try Data("New".utf8).write(to: root.appending(path: "file.txt"))
		#expect(await finished.next() == nil)
	}

	/**
	The system reports a moved directory without the files in it.
	*/
	@Test(.temporaryDirectory)
	func `reports a renamed directory`() async throws {
		let root = try URL.temporaryDirectory(files: ["content/dato/index.md": "Dato"])
		let directory = root.appending(path: "content/dato")

		var changes = DirectoryWatcher(directories: [root.appending(path: "content")], latency: .milliseconds(20)).makeAsyncIterator()
		try FileManager.default.moveItem(at: directory, to: root.appending(path: "content/dato-2"))

		// The system can also report the file at its old path, as it was made just before the watcher started, which is right, as it is gone from there, and it can report it on its own first.
		var changed = Set<String>()

		while
			!changed.isSuperset(of: ["dato", "dato-2"]),
			let files = await changes.next()
		{
			changed.formUnion(files.map(\.lastPathComponent))
		}

		#expect(changed.isSubset(of: ["dato", "dato-2", "index.md"]))
	}
}
