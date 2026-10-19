import Foundation
import Testing

/**
Gives the test a temporary directory that is deleted when the test ends. ``Foundation/URL/temporaryDirectory(files:)`` creates directories in it.

```swift
@Test(.temporaryDirectory)
func `publishes the files`() throws {
	let project = try URL.temporaryDirectory(files: ["public/robots.txt": ""])
}
```
*/
public struct TemporaryDirectoryTrait: TestTrait, TestScoping {
	@TaskLocal public static var current: URL?

	public func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable @concurrent () async throws -> Void) async throws {
		let directory = FileManager.default.temporaryDirectory.appending(path: "\(test.sourceLocation.moduleName)-\(UUID().uuidString)")
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

		defer {
			try? FileManager.default.removeItem(at: directory)
		}

		try await Self.$current.withValue(directory) {
			try await function()
		}
	}
}

extension Trait where Self == TemporaryDirectoryTrait {
	/**
	A temporary directory for the test, deleted when the test ends.
	*/
	public static var temporaryDirectory: Self {
		Self()
	}
}

extension URL {
	/**
	A new, empty directory for a test, with files from a dictionary of relative paths and contents. It is in the directory of the `.temporaryDirectory` trait, so it is deleted when the test ends.
	*/
	public static func temporaryDirectory(files: [String: String] = [:]) throws -> URL {
		let parent = try #require(TemporaryDirectoryTrait.current, "Add the `.temporaryDirectory` trait to the test.")
		let directory = parent.appending(path: UUID().uuidString)
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

		for (path, contents) in files {
			let file = directory.appending(path: path)
			try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
			try Data(contents.utf8).write(to: file)
		}

		return directory
	}
}
