import Foundation
import TestSupport
import Testing
@testable import SiteKit

struct ContentLoadingTests {
	struct Frontmatter: SiteKit.Frontmatter {
		let links: OrderedMapping<String>
	}

	@Test
	func `ordered mappings keep the order of the keys`() throws {
		let file = try MarkdownFile(contents: "---\nlinks: {\n\tZebra: 'z',\n\tApple: 'a',\n\tMango: 'm',\n}\n---\nBody", url: URL(filePath: "/content/test.md"))
		let frontmatter = try file.decodeFrontmatter(as: Frontmatter.self)

		#expect(frontmatter.links.map(\.key) == ["Zebra", "Apple", "Mango"])
		#expect(frontmatter.links["Apple"] == "a")
		#expect(file.body == "Body")
		#expect(file.slug == "test")
	}

	struct Note: ContentEntry {
		@Frontmatter
		struct Frontmatter {
			var title: String

			var isDraft = false
		}

		static let directory = "content/notes"
		static let sortOrder = [KeyPathComparator(\Note.title)]

		let title: String
		let slug: String
		let isDraft: Bool

		init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) {
			self.title = frontmatter.title
			self.slug = file.slug
			self.isDraft = frontmatter.isDraft
		}
	}

	@Test(.temporaryDirectory)
	func `entries with the same sort key load in file path order`() async throws {
		let names = (10..<40).map { "note-\($0)" }
		let root = try URL.temporaryDirectory(files: Dictionary(uniqueKeysWithValues: names.map { ("\(Note.directory)/\($0).md", "---\ntitle: 'Same'\n---\nBody") }))

		for _ in 0..<5 {
			#expect(try await Note.load(from: Project(root: root)).map(\.slug) == names)
		}
	}

	@Test(.temporaryDirectory)
	func `a page bundle has the slug of its directory`() async throws {
		let root = try URL.temporaryDirectory(files: [
			"\(Note.directory)/a/index.md": "---\ntitle: 'A'\n---\nBody",
			"\(Note.directory)/a/image.png": "",
			"\(Note.directory)/b.md": "---\ntitle: 'B'\n---\nBody",
		])

		#expect(try await Note.load(from: Project(root: root)).map(\.slug) == ["a", "b"])
	}

	/**
	Both files are the same page, so the build names them instead of stopping on the duplicate path later.
	*/
	@Test(.temporaryDirectory)
	func `two files for the same page are an error that names them`() async throws {
		let root = try URL.temporaryDirectory(files: [
			"\(Note.directory)/a.md": "---\ntitle: 'A'\n---\nBody",
			"\(Note.directory)/a/index.md": "---\ntitle: 'A'\n---\nBody",
		])

		let error = try await #require(throws: ContentErrors.self) {
			try await Note.load(from: Project(root: root))
		}

		try #require(error.errors.count == 1)
		#expect(error.errors[0].reason.contains("a.md"))
	}

	@Test(.temporaryDirectory)
	func `loading leaves out drafts, sorts, and names all broken files`() async throws {
		let root = try URL.temporaryDirectory(files: [
			"\(Note.directory)/b.md": "---\ntitle: 'B'\n---\nBody",
			"\(Note.directory)/a.md": "---\ntitle: 'A'\n---\nBody",
			"\(Note.directory)/c.md": "---\ntitle: 'C'\nisDraft: true\n---\nBody",
		])
		let directory = root.appending(path: Note.directory)

		#expect(try await Note.load(from: Project(root: root)).map(\.title) == ["A", "B"])

		try Data("---\ntitle: 'D'\nunknown: true\n---\n".utf8).write(to: directory.appending(path: "d.md"))
		try Data("---\ntitle: 'E'\nunknown: true\n---\n".utf8).write(to: directory.appending(path: "e.md"))

		let error = try await #require(throws: ContentErrors.self) {
			try await Note.load(from: Project(root: root))
		}

		// Every broken file is reported, not only the first.
		#expect(error.errors.map(\.file?.lastPathComponent) == ["d.md", "e.md"])
	}

	/**
	Editors on Windows can add a byte order mark, which reading the file as UTF-8 removes.
	*/
	@Test(.temporaryDirectory)
	func `frontmatter fences allow a byte order mark and trailing spaces`() throws {
		let url = try URL.temporaryDirectory().appending(path: "test.md")
		try Data([0xEF, 0xBB, 0xBF] + Array("--- \nlinks: {A: 'a'}\n---\t\nBody".utf8)).write(to: url)

		let file = try MarkdownFile(url: url)
		#expect(file.frontmatter == "links: {A: 'a'}")
		#expect(file.body == "Body")
	}

	@Test
	func `frontmatter errors name the line`() throws {
		let file = try MarkdownFile(contents: "---\ntitle: 'A'\nlinks: ['a']\nunknown: true\n---\nBody", url: URL(filePath: "/content/test.md"))

		let error = try #require(throws: ContentError.self) {
			try file.decodeFrontmatter(as: Frontmatter.self)
		}

		#expect(error.line == 3)
		#expect(error.description.hasPrefix("/content/test.md:3: Invalid `links`"))

		let strict = try #require(throws: ContentError.self) {
			try file.decodeFrontmatter(as: Note.Frontmatter.self)
		}

		// The first unknown key in the file.
		#expect(strict.line == 3)
		#expect(strict.reason == "Unknown key links, which Frontmatter does not read.")
	}

	@Frontmatter
	struct CheckedFrontmatter {
		@NonEmpty var title: String
		@NonEmpty var subtitle: String?
		@Absolute var url: URL?
		@JavaScriptSafe var downloads = 1

		@Key("date")
		@CalendarDay var publicationDate: Date
	}

	@Test
	func `property wrappers decode checked values`() throws {
		let file = try MarkdownFile(contents: "---\ntitle: 'Title'\nurl: 'https://example.com'\ndate: '2026-02-23'\n---\nBody", url: URL(filePath: "/content/test.md"))
		let frontmatter = try file.decodeFrontmatter(as: CheckedFrontmatter.self)

		#expect(frontmatter.title == "Title")
		#expect(frontmatter.subtitle == nil)
		#expect(frontmatter.url == URL(string: "https://example.com"))
		#expect(frontmatter.downloads == 1)
		#expect(frontmatter.publicationDate == Date(timeIntervalSince1970: 1_771_804_800))
	}

	@Test(arguments: [
		("title: ' '\ndate: '2026-02-23'", 2, "Invalid `title`: Must not be empty."),
		("title: 'Title'\nsubtitle: ''\ndate: '2026-02-23'", 3, "Invalid `subtitle`: Must not be empty."),
		("title: 'Title'\nurl: 'example.com'\ndate: '2026-02-23'", 3, "Invalid `url`: Must be an absolute URL, got “example.com”."),
		("title: 'Title'\ndownloads: 0\ndate: '2026-02-23'", 3, "Invalid `downloads`: Must be a positive integer of at most 2⁵³ − 1, got 0."),
		("title: 'Title'\ndate: '2026-02-30'", 3, "Invalid `date`: “2026-02-30” is not a real day."),
		// A missing key is at the line of its parent, here the start of the frontmatter.
		("date: '2026-02-23'", 2, "Missing required key `title`."),
	])
	func `property wrappers report invalid values at their line`(frontmatter: String, line: Int, reason: String) throws {
		let file = try MarkdownFile(contents: "---\n\(frontmatter)\n---\nBody", url: URL(filePath: "/content/test.md"))

		let error = try #require(throws: ContentError.self) {
			try file.decodeFrontmatter(as: CheckedFrontmatter.self)
		}

		#expect(error.reason == reason)
		#expect(error.line == line)
	}

	@Test
	func `the line of a frontmatter key uses its SOML name`() throws {
		let file = try MarkdownFile(contents: "---\ntitle: 'Title'\ndate: '2026-02-23'\n---\nBody", url: URL(filePath: "/content/test.md"))
		#expect(file.line(of: CheckedFrontmatter.CodingKeys.publicationDate) == 3)
	}

	@Test
	func `a body without frontmatter has the line endings of a body with frontmatter`() throws {
		let file = try MarkdownFile(contents: "First\r\nSecond", url: URL(filePath: "/content/test.md"))
		#expect(file.body == "First\nSecond")
	}

	@Test
	func `frontmatter with only blank lines is empty`() throws {
		let file = try MarkdownFile(contents: "---\n\n  \n---\nBody", url: URL(filePath: "/content/test.md"))

		// Not a SOML error about a document without a value.
		let error = try #require(throws: ContentError.self) {
			try file.decodeFrontmatter(as: Frontmatter.self)
		}

		#expect(error.reason == "Missing required key `links`.")
	}

	@Test
	func `content errors name a file in the current directory by its relative path`() {
		let error = ContentError(file: URL.currentDirectory().appending(path: "content/test.md"), line: 3, reason: "Wrong.")
		#expect(error.description == "content/test.md:3: Wrong.")
	}

	@Test
	func `converting other errors keeps their description`() {
		struct Failure: Error, CustomStringConvertible {
			let description = "The image dimensions could not be read."
		}
		struct LocalizedFailure: LocalizedError {
			var errorDescription: String? {
				"The image format is not supported."
			}
		}

		let file = URL(filePath: "/content/test.md")
		let errors = ContentErrors(converting: Failure(), file: file)
		#expect(errors.description == "/content/test.md: The image dimensions could not be read.")
		#expect(ContentErrors(converting: LocalizedFailure(), file: file).description == "/content/test.md: The image format is not supported.")
		let foundationError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "The file could not be read."])
		#expect(ContentErrors(converting: foundationError, file: file).description == "/content/test.md: The file could not be read.")
		// A Foundation error struct, not boxed as `any Error`.
		let cocoaError = CocoaError(.fileReadNoSuchFile)
		#expect(cocoaError.descriptiveMessage == cocoaError.localizedDescription)
	}

	@Test(.temporaryDirectory)
	func `a missing content directory is an error`() async {
		await #expect(throws: ContentErrors.self) {
			try await Note.load(from: Project(root: try URL.temporaryDirectory()))
		}
	}

	@Test(.temporaryDirectory)
	func `last commit dates ignore moves without changes`() async throws {
		let root = try URL.temporaryDirectory(files: ["old/a.md": "A", "old/b.md": "B"])

		func git(_ arguments: String..., date: String = "2026-01-01T00:00:00Z") async throws {
			let process = Process()
			process.executableURL = URL(filePath: "/usr/bin/env")
			process.arguments = ["git", "-C", root.path(percentEncoded: false), "-c", "user.name=Test", "-c", "user.email=test@example.com"] + arguments
			// The `PATH` of the tests, so it runs the same git as `lastCommitDates()`. A `PATH` with `/usr/bin` first runs `/usr/bin/git`, which asks `xcodebuild` where the git of Xcode is when its cache does not know it yet, like on CI, where git is the one of Homebrew. The test took 24 to 31 s on CI.
			process.environment = ["GIT_COMMITTER_DATE": date, "GIT_AUTHOR_DATE": date, "PATH": ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin"]
			process.standardOutput = FileHandle.nullDevice
			try #require(await process.runUntilExit() == 0, "git \(arguments.joined(separator: " ")) failed.")
		}

		try await git("init", "--quiet")
		try await git("add", ".")
		try await git("commit", "--quiet", "-m", "Add")
		try Data("A, changed".utf8).write(to: root.appending(path: "old/a.md"))
		try await git("commit", "--quiet", "-am", "Change", date: "2026-02-01T00:00:00Z")
		try await git("mv", "old", "content")
		try await git("commit", "--quiet", "-m", "Move", date: "2026-03-01T00:00:00Z")

		let dates = await Project(root: root).lastCommitDates()
		#expect(dates["content/a.md"] == Date(timeIntervalSince1970: 1_769_904_000))
		#expect(dates["content/b.md"] == Date(timeIntervalSince1970: 1_767_225_600))
	}

	@Test(.temporaryDirectory)
	func `last commit dates leave out the ignored commits`() async throws {
		let root = try URL.temporaryDirectory(files: ["content/a.md": "A", "content/b.md": "B"])

		func git(_ arguments: String..., date: String = "2026-01-01T00:00:00Z") async throws -> String {
			let process = Process()
			process.executableURL = URL(filePath: "/usr/bin/env")
			process.arguments = ["git", "-C", root.path(percentEncoded: false), "-c", "user.name=Test", "-c", "user.email=test@example.com"] + arguments
			// The `PATH` of the tests, like in the test above.
			process.environment = ["GIT_COMMITTER_DATE": date, "GIT_AUTHOR_DATE": date, "PATH": ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin"]
			let pipe = Pipe()
			process.standardOutput = pipe
			var output = ""

			try #require(await process.runUntilExit {
				for try await line in pipe.fileHandleForReading.bytes.lines {
					output += line
				}
			} == 0, "git \(arguments.joined(separator: " ")) failed.")

			return output
		}

		_ = try await git("init", "--quiet")
		_ = try await git("add", ".")
		_ = try await git("commit", "--quiet", "-m", "Add")
		try Data("A, changed".utf8).write(to: root.appending(path: "content/a.md"))
		try Data("B, changed".utf8).write(to: root.appending(path: "content/b.md"))
		_ = try await git("commit", "--quiet", "-am", "Change the syntax of all files", date: "2026-02-01T00:00:00Z")
		let hash = try await git("rev-parse", "HEAD")
		try Data("A, changed again".utf8).write(to: root.appending(path: "content/a.md"))
		_ = try await git("commit", "--quiet", "-am", "Change", date: "2026-03-01T00:00:00Z")

		let project = Project(root: root)
		try Data("# A change of syntax\n\n\(hash.prefix(8)) # The frontmatter\n".utf8).write(to: project.ignoredCommitsFile)
		let dates = await project.lastCommitDates()

		// The ignored commit changed both, so `b.md` keeps the date of the commit before it.
		#expect(dates["content/a.md"] == Date(timeIntervalSince1970: 1_772_323_200))
		#expect(dates["content/b.md"] == Date(timeIntervalSince1970: 1_767_225_600))
	}

	@Test
	func `a process returns its exit status, and its output can be read while it runs`() async throws {
		let succeeding = Process()
		succeeding.executableURL = URL(filePath: "/usr/bin/true")
		#expect(try await succeeding.runUntilExit() == 0)

		let failing = Process()
		failing.executableURL = URL(filePath: "/usr/bin/false")
		#expect(try await failing.runUntilExit() == 1)

		let echo = Process()
		echo.executableURL = URL(filePath: "/bin/echo")
		echo.arguments = ["Hello"]
		let pipe = Pipe()
		echo.standardOutput = pipe
		var lines = [String]()

		let status = try await echo.runUntilExit {
			for try await line in pipe.fileHandleForReading.bytes.lines {
				lines.append(line)
			}
		}

		#expect(status == 0)
		#expect(lines == ["Hello"])

		let missing = Process()
		missing.executableURL = URL(filePath: "/nonexistent")

		await #expect(throws: (any Error).self) {
			try await missing.runUntilExit()
		}
	}

	@Test
	func `slugs are relative to the content directory`() throws {
		let file = try MarkdownFile(contents: "Body", url: URL(filePath: "/content/apps/faq.md"), relativeTo: URL(filePath: "/content"))
		#expect(file.slug == "apps/faq")
	}
}
