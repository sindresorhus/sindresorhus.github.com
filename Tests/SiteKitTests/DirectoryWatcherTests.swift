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
		var changes = DirectoryWatcher(directories: [root], interval: .milliseconds(20)).makeAsyncIterator()
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

		var changes = DirectoryWatcher(directories: [first, second], interval: .milliseconds(20)).makeAsyncIterator()
		let file = second.appending(path: "file.txt")
		try Data("New".utf8).write(to: file)

		#expect(await changes.next()?.map(\.lastPathComponent) == [file.lastPathComponent])
	}

	/**
	Editors save atomically: they write a temporary file and move it over the file, which changes the modification date of the directory too.
	*/
	@Test(.temporaryDirectory)
	func `reports only the file of an atomic save, not its directory`() async throws {
		let root = try URL.temporaryDirectory(files: ["sources/Scripts/Clock.js": "old"])
		let file = root.appending(path: "sources/Scripts/Clock.js")

		var changes = DirectoryWatcher(directories: [root.appending(path: "sources")], interval: .milliseconds(20)).makeAsyncIterator()
		try Data("new".utf8).write(to: file, options: .atomic)

		#expect(await changes.next()?.map(\.lastPathComponent) == [file.lastPathComponent])
	}
}
