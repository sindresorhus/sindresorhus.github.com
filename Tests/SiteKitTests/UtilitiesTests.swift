import Foundation
import Synchronization
import TestSupport
import Testing
@testable import SiteKit

struct UtilitiesTests {
	@Test(.temporaryDirectory, arguments: [false, true])
	func `recursive listings preserve hidden file and directory filtering`(includesHiddenFiles: Bool) throws {
		let directory = try URL.temporaryDirectory(files: [
			"visible.txt": "Visible",
			"nested/inside.txt": "Inside",
			".hidden.txt": "Hidden",
			".secret/inside-secret.txt": "Hidden directory",
			"nested/.inside-hidden.txt": "Hidden file",
		])
		let allNames: Set<String> = ["visible.txt", "nested", "inside.txt", ".hidden.txt", ".secret", "inside-secret.txt", ".inside-hidden.txt"]
		let expected: Set<String> = includesHiddenFiles ? allNames : ["visible.txt", "nested", "inside.txt"]

		#expect(Set(try directory.checkedContentsRecursively(includesHiddenFiles: includesHiddenFiles).map(\.lastPathComponent)) == expected)
		#expect(Set(directory.contentsRecursively(includesHiddenFiles: includesHiddenFiles).map(\.lastPathComponent)) == expected)

		if includesHiddenFiles {
			#expect(Set(try directory.checkedContentsRecursively().map(\.lastPathComponent)) == allNames)
			#expect(Set(directory.contentsRecursively().map(\.lastPathComponent)) == allNames)
		}
	}

	@Test(.temporaryDirectory)
	func `checked recursive listings report an unreadable child directory`() throws {
		let directory = try URL.temporaryDirectory(files: ["blocked/notes.md": "Notes"])
		let blocked = directory.appending(path: "blocked")
		let manager = FileManager()
		try manager.setAttributes([.posixPermissions: 0], ofItemAtPath: blocked.path(percentEncoded: false))
		defer {
			try? manager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: blocked.path(percentEncoded: false))
		}

		let error = try #require(throws: (any Error).self) {
			try directory.filesRecursively()
		}
		#expect((error as? CocoaError)?.code == .fileReadNoPermission)
	}

	@Test(.temporaryDirectory)
	func `checked recursive listings preserve errors for missing and non-directory roots`() throws {
		let directory = try URL.temporaryDirectory(files: ["notes.md": "Notes"])
		let missingError = try #require(throws: (any Error).self) {
			try directory.appending(path: "missing").filesRecursively()
		}
		#expect((missingError as? CocoaError)?.code == .fileReadNoSuchFile)

		let fileError = try #require(throws: (any Error).self) {
			try directory.appending(path: "notes.md").checkedContentsRecursively()
		}
		let underlyingError = (fileError as NSError).userInfo[NSUnderlyingErrorKey] as? POSIXError
		#expect(underlyingError?.code == .ENOTDIR)
	}

	@Test(.temporaryDirectory)
	func `cached file values of different types keep separate entries`() async throws {
		let file = try URL.temporaryDirectory(files: ["value.txt": "42"]).appending(path: "value.txt")
		let numberReads = Mutex(0)
		let textReads = Mutex(0)
		let numberRead = FileRead("value") { url in
			numberReads.withLock { $0 += 1 }
			return Int(try String(contentsOf: url, encoding: .utf8))
		}
		let textRead = FileRead("value") { url in
			textReads.withLock { $0 += 1 }
			return try String(contentsOf: url, encoding: .utf8)
		}

		for _ in 0..<2 {
			let number = try await file.cachedValue(using: numberRead)
			let text = try await file.cachedValue(using: textRead)
			#expect(number == 42)
			#expect(text == "42")
		}

		#expect(numberReads.withLock { $0 } == 1)
		#expect(textReads.withLock { $0 } == 1)
	}

	@Test(.temporaryDirectory)
	func `file read operations with the same result type keep separate identities`() async throws {
		let file = try URL.temporaryDirectory(files: ["value.txt": "42"]).appending(path: "value.txt")
		let first = FileRead("first") { _ in 1 }
		let second = FileRead("second") { _ in 2 }

		#expect(await file.cachedValue(using: first) == 1)
		#expect(await file.cachedValue(using: second) == 2)
		#expect(await file.cachedValue(using: first) == 1)
	}

	@Test(.temporaryDirectory)
	func `file reads preserve typed errors and do not cache failures`() async throws {
		enum Failure: Error {
			case unreadable
		}

		let file = try URL.temporaryDirectory(files: ["value.txt": "42"]).appending(path: "value.txt")
		let reads = Mutex(0)
		let operation = FileRead<Int, Failure>("retry") { _ throws(Failure) in
			let count = reads.withLock { count in
				count += 1
				return count
			}

			guard count > 1 else {
				throw Failure.unreadable
			}

			return 42
		}

		await #expect(throws: Failure.unreadable) {
			try await file.cachedValue(using: operation)
		}
		#expect(try await file.cachedValue(using: operation) == 42)
		#expect(try await file.cachedValue(using: operation) == 42)
		#expect(reads.withLock { $0 } == 2)
	}

	@Test
	func `the closest string is the misspelling within a third of its characters`() {
		#expect("notes".closest(in: ["note", "platform"]) == "note")
		#expect("titel".closest(in: ["title"]) == "title")
		#expect("platfrom".closest(in: ["platform"]) == "platform")
		// Two changes are too many for a string of four characters.
		#expect("abcd".closest(in: ["abzz"]) == nil)
		#expect("dato".closest(in: ["something-else-entirely"]) == nil)
	}

	@Test
	func `the closest string ignores case`() {
		#expect("Titel".closest(in: ["title"]) == "title")
	}

	/**
	The suggestion must be the same on each run, as the candidates can come from a set, whose order changes.
	*/
	@Test
	func `the closest string is the first alphabetically at the same distance`() {
		#expect("cato".closest(in: ["dato", "bato"]) == "bato")
	}
}
