import Foundation
import Testing
import SiteKit

@Suite
struct DirectoryWatcherTests {
	@Test(.timeLimit(.minutes(1)), .temporaryDirectory)
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
	@Test(.timeLimit(.minutes(1)), .temporaryDirectory)
	func `reports only the file of an atomic save, not its directory`() async throws {
		let root = try URL.temporaryDirectory(files: ["sources/Scripts/Clock.js": "old"])
		let file = root.appending(path: "sources/Scripts/Clock.js")

		var changes = DirectoryWatcher(directories: [root.appending(path: "sources")], interval: .milliseconds(20)).makeAsyncIterator()
		try Data("new".utf8).write(to: file, options: .atomic)

		#expect(await changes.next()?.map(\.lastPathComponent) == [file.lastPathComponent])
	}
}
