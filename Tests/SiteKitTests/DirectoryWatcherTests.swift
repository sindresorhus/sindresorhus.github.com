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
}
