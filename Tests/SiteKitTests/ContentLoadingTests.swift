import Foundation
import SOML
import TestSupport
import Testing
@testable import SiteKit

struct ContentLoadingTests {
	@Test
	func `diagnostics sort by optional location while keeping ties in input order`() {
		let first = URL(filePath: "/a.md")
		let last = URL(filePath: "/z.md")
		let errors = [
			ContentError(file: last, line: 1, reason: "last file"),
			ContentError(file: first, line: 2, reason: "first tie"),
			ContentError(line: 3, reason: "unlocated line"),
			ContentError(file: first, reason: "whole file"),
			ContentError(file: first, line: 2, reason: "second tie"),
			ContentError(reason: "unlocated"),
		]

		#expect(errors.sorted(using: ContentError.locationOrder).map(\.reason) == ["unlocated", "unlocated line", "whole file", "first tie", "second tie", "last file"])
	}

	struct Frontmatter: SiteKit.Frontmatter {
		let links: OrderedMapping<String>

		enum CodingKeys: String, CodingKey {
			case links
		}
	}

	@Frontmatter
	struct EscapedKeyFrontmatter {
		@Key("n\u{61}me") var title: String
	}

	@Test
	func `escaped macro literals retain their represented values at runtime`() throws {
		let metadata = try JSONDecoder().decode(EscapedKeyFrontmatter.self, from: Data(#"{"name":"Title"}"#.utf8))

		#expect(metadata.title == "Title")
		#expect(#URL("https\u{3a}//example.com").absoluteString == "https://example.com")
		#expect(#path("\u{2f}apps") == #path("/apps"))
	}

	@Test
	func `code-owned ordered mappings retain unique keys in their given order`() {
		let mapping = OrderedMapping([("Zebra", "z"), ("Apple", "a")])

		#expect(mapping.map(\.key) == ["Zebra", "Apple"])
		#expect(mapping["Apple"] == "a")
		#expect(OrderedMapping<String>().isEmpty)
	}

	@Test
	func `code-owned ordered mappings reject duplicate keys`() async {
		await #expect(processExitsWith: .failure) {
			_ = OrderedMapping([("Apple", "a"), ("Apple", "b")])
		}
	}

	@Test
	func `page routes allow disjoint directories before they exist`() {
		let routes: [String: RoutePath] = [
			"content/apps": .root,
			"content/apps-extra": #path("/extra"),
			"content/blog": #path("/blog"),
		]
		let project = Project(root: URL(filePath: "/nonexistent/site"), pageRoutes: routes)

		#expect(project.pageRoutes == routes)
	}

	@Test
	func `page routes reject nested source directories`() async {
		await #expect(processExitsWith: .failure) {
			_ = Project(root: URL(filePath: "/site"), pageRoutes: ["content/apps": .root, "content/apps/tools": #path("/tools")])
		}
	}

	@Test(arguments: ["", "/content/apps", "content/apps/", "content//apps", "content/./apps", "content/../apps", "content/\0apps"])
	func `page routes reject source directories that are not canonical relative paths`(directory: String) async {
		await #expect(processExitsWith: .failure) { [directory] in
			_ = Project(root: URL(filePath: "/site"), pageRoutes: [directory: .root])
		}
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

	@Test
	func `model-owned diagnostic keys retain renamed paths through nested optional values and arrays`() throws {
		let model = try JSONDecoder().decode(DiagnosticFrontmatter.self, from: Data(#"{"name":"","children":[{"caption":"","children":[{"caption":"","children":[]}]},{"caption":"Valid","children":[]}],"optional":{"caption":"","children":[]}}"#.utf8))
		var problems = FrontmatterProblems<DiagnosticFrontmatter>()
		model.validate(into: &problems)

		#expect(problems.all.map { $0.codingPath.map(\.stringValue) } == [
			["name"],
			["children", "0", "caption"],
			["children", "0", "children", "0", "caption"],
			["optional", "caption"],
		])
		#expect(problems.all.map(\.reason) == ["Title is required.", "Caption is required.", "Caption is required.", "Caption is required."])
		#expect(problems.all[1].codingPath[1].intValue == 0)
		#expect(DiagnosticFrontmatter.CodingKeys.title.stringValue == "name")
	}

	enum Fruit: String, ContentEnum {
		case apple
		case mango
	}

	/**
	The error of Swift names the type, not the values, so a value outside the frontmatter, like the language of a code block, lists the valid values, in English on any build machine.
	*/
	@Test
	func `an invalid value of a content enum lists the valid values`() throws {
		#expect(try Fruit(validating: "mango") == .mango)

		let error = try #require(throws: ContentError.self) {
			try Fruit(validating: "Apple")
		}

		#expect(error.reason == "Must be one of `apple` or `mango`, not “Apple”.")
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
	func `partial loading keeps valid entries and records every failed slug`() async throws {
		let root = try URL.temporaryDirectory(files: [
			"\(Note.directory)/a.md": "---\ntitle: 'A'\n---\nBody",
			"\(Note.directory)/b.md": "---\ntitle: 'B'\n---\nBody",
			"\(Note.directory)/broken.md": "---\nunknown: true\n---\nBody",
			"\(Note.directory)/draft.md": "---\ntitle: 'Draft'\nisDraft: true\n---\nBody",
			"\(Note.directory)/rejected.md": "---\ntitle: 'Rejected'\n---\nBody",
		])
		let project = Project(root: root)
		let loaded = await Note.load(from: project) { file, frontmatter in
			guard file.slug != "rejected" else {
				throw ContentError(reason: "Rejected by the entry initializer.")
			}

			return Note(file: file, frontmatter: frontmatter, project: project)
		}

		guard case .loaded(let entries, let failedSlugs, let errors) = loaded else {
			Issue.record("The existing directory must load.")
			return
		}

		#expect(entries.map(\.slug) == ["a", "b"])
		#expect(loaded.validEntries.map(\.slug) == ["a", "b"])
		#expect(failedSlugs == ["broken", "rejected"])
		#expect(errors.map(\.file?.lastPathComponent) == ["broken.md", "rejected.md"])
		#expect(errors.last?.reason == "Rejected by the entry initializer.")
	}

	@Test(.temporaryDirectory)
	func `an empty content directory is loaded while a missing directory is unavailable`() async throws {
		let root = try URL.temporaryDirectory(files: ["content/notes/placeholder.txt": ""])
		let project = Project(root: root)
		let loaded = await Note.load(from: project) { file, frontmatter in
			Note(file: file, frontmatter: frontmatter, project: project)
		}

		guard case .loaded(let entries, let failedSlugs, let errors) = loaded else {
			Issue.record("An empty directory is available.")
			return
		}

		#expect(entries.isEmpty)
		#expect(failedSlugs.isEmpty)
		#expect(errors.isEmpty)
		#expect(try await Note.load(from: project).isEmpty)

		let missingProject = Project(root: root.appending(path: "missing"))
		let unavailable = await Note.load(from: missingProject) { file, frontmatter in
			Note(file: file, frontmatter: frontmatter, project: missingProject)
		}

		guard case .unavailable(let failure) = unavailable else {
			Issue.record("A missing directory is unavailable.")
			return
		}

		#expect(unavailable.validEntries.isEmpty)
		#expect(failure.errors.count == 1)
		#expect(failure.errors.first?.file == missingProject.root.appending(path: Note.directory))
		await #expect(throws: ContentErrors.self) {
			try await Note.load(from: missingProject)
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
		let root = try URL.temporaryDirectory(
			files: [
				"\(Note.directory)/a/index.md": "---\ntitle: 'A'\n---\nBody",
				"\(Note.directory)/a/image.png": "",
				"\(Note.directory)/b.md": "---\ntitle: 'B'\n---\nBody",
			]
		)

		#expect(try await Note.load(from: Project(root: root)).map(\.slug) == ["a", "b"])
	}

	/**
	The name of a file is the URL of its page, and the paths of GitHub Pages are case-sensitive.
	*/
	@Test(.temporaryDirectory)
	func `a file name that is not a lowercase slug is an error`() async throws {
		let root = try URL.temporaryDirectory(
			files: [
				"\(Note.directory)/Keep-Mac-Awake.md": "---\ntitle: 'A'\n---\nBody",
				"\(Note.directory)/My_Bundle/index.md": "---\ntitle: 'B'\n---\nBody",
				"\(Note.directory)/keep-mac-awake-2.md": "---\ntitle: 'C'\n---\nBody",
			]
		)

		let error = try await #require(throws: ContentErrors.self) {
			try await Note.load(from: Project(root: root))
		}

		#expect(error.errors.map { $0.file?.lastPathComponent } == ["Keep-Mac-Awake.md", "index.md"])
		#expect(error.errors.allSatisfy { $0.reason.hasPrefix("The path of the file is the URL of its page") })
		#expect(error.errors.map { $0.reason.split(separator: ". ").last } == ["Rename the file `Keep-Mac-Awake.md` to `keep-mac-awake.md`.", "Rename the folder `My_Bundle` to `my-bundle`."])
	}

	/**
	Both files are the same page, so the build names them instead of stopping on the duplicate path later.
	*/
	@Test(.temporaryDirectory)
	func `two files for the same page are an error that names them`() async throws {
		let root = try URL.temporaryDirectory(
			files: [
				"\(Note.directory)/a.md": "---\ntitle: 'A'\n---\nBody",
				"\(Note.directory)/a/index.md": "---\ntitle: 'A'\n---\nBody",
			]
		)

		let error = try await #require(throws: ContentErrors.self) {
			try await Note.load(from: Project(root: root))
		}

		try #require(error.errors.count == 1)
		#expect(error.errors[0].reason.contains("a.md"))
	}

	@Test(.temporaryDirectory)
	func `loading leaves out drafts, sorts, and names all broken files`() async throws {
		let root = try URL.temporaryDirectory(
			files: [
				"\(Note.directory)/b.md": "---\ntitle: 'B'\n---\nBody",
				"\(Note.directory)/a.md": "---\ntitle: 'A'\n---\nBody",
				"\(Note.directory)/c.md": "---\ntitle: 'C'\nisDraft: true\n---\nBody",
			]
		)
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

	private enum FormattingKeys: String, CodingKey {
		case isDraft
		case title
		case publicationDate
		case details
		case missing
	}

	@Test
	func `formatting frontmatter orders only root keys and preserves comments and scalar spelling`() throws {
		let source = """
		---
		# Document 🦄

		details: {zebra: ['é', {last: 0x1F90, first: true}], apple: []} # Details
		# The title
		title: 'É 🦄'
		publicationDate: 2026-02-23
		isDraft: true # Draft
		unknownSecond: 1_000
		unknownFirst: 'keep'
		# Footer
		---
		"""
		let expected = """
		---
		# Document 🦄

		isDraft: true # Draft
		# The title
		title: 'É 🦄'
		publicationDate: 2026-02-23
		details: {
			zebra: [
				'é'
				{
					last: 0x1F90
					first: true
				}
			]
			apple: []
		} # Details
		unknownSecond: 1_000
		unknownFirst: 'keep'
		# Footer
		---
		"""
		let keys: [any CodingKey] = [FormattingKeys.isDraft, FormattingKeys.title, FormattingKeys.publicationDate, FormattingKeys.details, FormattingKeys.missing]
		let formatted = try MarkdownFile.formattingFrontmatter(in: source, orderedKeys: keys)

		#expect(formatted == expected)
		#expect(try MarkdownFile.formattingFrontmatter(in: formatted, orderedKeys: keys) == formatted)
	}

	@Test
	func `formatting frontmatter preserves block strings and the raw body and fences`() throws {
		let opening = "--- \t\n"
		let suffix = "---\t\n\n\n# Body 🦄\n\n---\n\nText.  \n\n"
		let source = opening + """
		notes:
			'''
			A 🦄 and 'quotes'.
			---
			Second line.
			'''
		title: 'Title'
		""" + "\n" + suffix
		let expected = opening + """
		title: 'Title'
		notes:
			'''
			A 🦄 and 'quotes'.
			---
			Second line.
			'''
		""" + "\n" + suffix
		let formatted = try MarkdownFile.formattingFrontmatter(in: source, orderedKeys: [FormattingKeys.title])

		#expect(formatted == expected)
		#expect(try MarkdownFile.formattingFrontmatter(in: formatted, orderedKeys: [FormattingKeys.title]) == formatted)
	}

	@Test
	func `formatting frontmatter keeps multiline trailing comments with their key`() throws {
		let source = "---\nother: 1 /* First\nSecond */\ntitle: 'Title'\n---\nBody"
		let formatted = try MarkdownFile.formattingFrontmatter(in: source, orderedKeys: [FormattingKeys.title])

		#expect(formatted == "---\ntitle: 'Title'\nother: 1 /* First\nSecond */\n---\nBody")
		#expect(try MarkdownFile.formattingFrontmatter(in: formatted, orderedKeys: [FormattingKeys.title]) == formatted)
	}

	@Test
	func `formatting frontmatter normalizes only frontmatter line endings`() throws {
		let source = "--- \r\nitems: ['one', 'two']\r\n---\t\r\n\r\nBody\r\n---\r\n"
		let formatted = try MarkdownFile.formattingFrontmatter(in: source)

		#expect(formatted == "--- \r\nitems: [\n\t'one'\n\t'two'\n]\n---\t\r\n\r\nBody\r\n---\r\n")
	}

	@Test
	func `formatting preserves distinct Unicode scalar spellings of unknown keys`() throws {
		let frontmatter = "'é': 1\n'e\u{301}': 2\ntitle: 'Title'\n"
		let source = "---\n" + frontmatter + "---\nBody"
		let formatted = try MarkdownFile.formattingFrontmatter(in: source, orderedKeys: [FormattingKeys.title])
		let file = try MarkdownFile(contents: formatted, url: URL(filePath: "/content/test.md"))
		let originalValue = try SOML.Document(parsing: frontmatter).value
		let formattedValue = try SOML.Document(parsing: file.frontmatter).value

		#expect(formattedValue == originalValue)
		#expect(formattedValue.objectValue?.count == 3)
		#expect(formatted == "---\ntitle: 'Title'\n'é': 1\n'e\u{301}': 2\n---\nBody")
	}

	@Test
	func `formatting reorders braced roots with their attached comments`() throws {
		let source = "---\n{other: 1, /* The title */ title: 'Title'}\n---\nBody"
		let formatted = try MarkdownFile.formattingFrontmatter(in: source, orderedKeys: [FormattingKeys.title])

		#expect(formatted == "---\n{\n\t/* The title */ title: 'Title'\n\tother: 1\n}\n---\nBody")
		#expect(try MarkdownFile.formattingFrontmatter(in: formatted, orderedKeys: [FormattingKeys.title]) == formatted)
	}

	@Test(arguments: ["# Body\n---\nText.\n", "---\n---\n\nBody\n", "---\n \t\n---\nBody", ""])
	func `formatting leaves absent or blank frontmatter unchanged`(source: String) throws {
		#expect(try MarkdownFile.formattingFrontmatter(in: source) == source)
	}

	@Test
	func `formatting reports invalid frontmatter at its Markdown line`() throws {
		let error = try #require(throws: ContentError.self) {
			try MarkdownFile.formattingFrontmatter(in: "---\ntitle: 'Title'\npublicationDate: 2026-02-30\n---\nBody")
		}
		#expect(error.line == 3)
		#expect(throws: ContentError.self) {
			try MarkdownFile.formattingFrontmatter(in: "---\ntitle: 'Title'")
		}
	}

	@Test
	func `frontmatter errors name the line`() throws {
		let file = try MarkdownFile(contents: "---\ntitle: 'A'\nlinks: ['a']\nunknown: true\n---\nBody", url: URL(filePath: "/content/test.md"))

		let error = try #require(throws: ContentErrors.self) {
			try file.decodeFrontmatter(as: Frontmatter.self)
		}.errors[0]

		#expect(error.line == 3)
		#expect(error.description.hasPrefix("/content/test.md:3: Invalid `links`"))

		let strict = try #require(throws: ContentErrors.self) {
			try file.decodeFrontmatter(as: Note.Frontmatter.self)
		}.errors[0]

		// The first unknown key in the file.
		#expect(strict.line == 3)
		#expect(strict.reason == "Unknown key links, which Frontmatter does not read.")
	}

	@Frontmatter
	struct CheckedFrontmatter {
		@NonEmpty var title: String
		@NonEmpty var subtitle: String?
		@Absolute var url: URL?
		@JavaScriptSafe var downloadCount = 1

		@Key("date")
		var publicationDate: SOML.Date
	}

	@Test
	func `property wrappers decode checked values`() throws {
		let file = try MarkdownFile(contents: "---\ntitle: 'Title'\nurl: 'https://example.com'\ndate: 2026-02-23\n---\nBody", url: URL(filePath: "/content/test.md"))
		let frontmatter = try file.decodeFrontmatter(as: CheckedFrontmatter.self)

		#expect(frontmatter.title == "Title")
		#expect(frontmatter.subtitle == nil)
		#expect(frontmatter.url == URL(string: "https://example.com"))
		#expect(frontmatter.downloadCount == 1)
		#expect(frontmatter.publicationDate.description == "2026-02-23")
	}

	@Test(arguments: [
		("2026-03-01T00:30:00+02:00", "2026-02-28"),
		("2026-02-28T23:30:00-08:00", "2026-03-01"),
	])
	func `calendar days normalize dates to UTC midnight and encode as a single date string`(date: String, expected: String) throws {
		let day = SOML.Date(try Date(date, strategy: .iso8601))
		#expect(day.description == expected)
		#expect(SOML.Date(day.foundationDate) == day)

		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .secondsSince1970
		let encoded = try encoder.encode(day)
		#expect(try JSONDecoder().decode(String.self, from: encoded) == expected)
		#expect(try JSONDecoder().decode(SOML.Date.self, from: encoded) == day)
	}

	@Test(arguments: ["0001-01-01", "1582-10-10", "1900-03-01", "2000-02-29", "9999-12-31"])
	func `native dates bridge through UTC without a Gregorian cutover`(text: String) throws {
		let day = try #require(SOML.Date(text))
		#expect(SOML.Date(day.foundationDate) == day)
		#expect(try SOML.Encoder().encodeToValue(day) == .date(day))
	}

	@Test
	func `a subnanosecond before midnight stays in the preceding day`() {
		let date = Date(timeIntervalSinceReferenceDate: -Double.leastNonzeroMagnitude)
		#expect(SOML.Date(date).description == "2000-12-31")
	}

	@Test(arguments: ["2026-02-30", "1900-02-29", "0000-01-01", "'2026-02-23'", "2026-02-23T00:00:00Z"])
	func `invalid native dates and other value types report the frontmatter line`(value: String) throws {
		let file = try MarkdownFile(contents: "---\ntitle: 'Title'\ndate: \(value)\n---\nBody", url: URL(filePath: "/content/test.md"))
		let error = try #require(throws: ContentErrors.self) {
			try file.decodeFrontmatter(as: CheckedFrontmatter.self)
		}.errors[0]
		#expect(error.line == 3)
	}

	@Test(arguments: [
		("title: 'Title'\nsubtitle: 'Sindre's app'", "Unexpected “s” after a value. A straight apostrophe ends a single-quoted string, so write it as ’, like 'Sindre’s app'."),
		// Only an apostrophe between letters is explained.
		("title: 'Version 2'1", "Unexpected “1” after a value"),
	])
	func `a straight apostrophe that ends a single-quoted string is explained`(frontmatter: String, reason: String) throws {
		let file = try MarkdownFile(contents: "---\n\(frontmatter)\n---\nBody", url: URL(filePath: "/content/test.md"))

		let error = try #require(throws: ContentErrors.self) {
			try file.decodeFrontmatter(as: CheckedFrontmatter.self)
		}.errors[0]

		#expect(error.reason == reason)
	}

	@Test(arguments: [
		("title: ' '\ndate: 2026-02-23", 2, "Invalid `title`: Must not be empty."),
		("title: 'Title'\nsubtitle: ''\ndate: 2026-02-23", 3, "Invalid `subtitle`: Must not be empty."),
		("title: 'Title'\nurl: 'example.com'\ndate: 2026-02-23", 3, "Invalid `url`: Must be an absolute URL, got “example.com”."),
		("title: 'Title'\ndownloadCount: 0\ndate: 2026-02-23", 3, "Invalid `downloadCount`: Must be a positive integer of at most 2⁵³ − 1, got 0."),
		// A missing key is at the line of its parent, here the start of the frontmatter.
		("date: 2026-02-23", 2, "Missing required key `title`."),
	])
	func `property wrappers report invalid values at their line`(frontmatter: String, line: Int, reason: String) throws {
		let file = try MarkdownFile(contents: "---\n\(frontmatter)\n---\nBody", url: URL(filePath: "/content/test.md"))

		let error = try #require(throws: ContentErrors.self) {
			try file.decodeFrontmatter(as: CheckedFrontmatter.self)
		}.errors[0]

		#expect(error.reason == reason)
		#expect(error.line == line)
	}

	@Test
	func `the line of a frontmatter key uses its SOML name`() throws {
		let file = try MarkdownFile(contents: "---\ntitle: 'Title'\ndate: 2026-02-23\n---\nBody", url: URL(filePath: "/content/test.md"))
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
		let error = try #require(throws: ContentErrors.self) {
			try file.decodeFrontmatter(as: Frontmatter.self)
		}.errors[0]

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

		try await git(in: root, "init", "--quiet")
		try await git(in: root, "add", ".")
		try await git(
			in: root,
			"commit",
			"--quiet",
			"-m",
			"Add"
		)
		try Data("A, changed".utf8).write(to: root.appending(path: "old/a.md"))
		try await git(
			in: root,
			"commit",
			"--quiet",
			"-am",
			"Change",
			date: "2026-02-01T00:00:00Z"
		)
		try await git(
			in: root,
			"mv",
			"old",
			"content"
		)
		try await git(
			in: root,
			"commit",
			"--quiet",
			"-m",
			"Move",
			date: "2026-03-01T00:00:00Z"
		)

		let dates = await Project(root: root).lastCommitDates()
		#expect(dates["content/a.md"] == Date(timeIntervalSince1970: 1_769_904_000))
		#expect(dates["content/b.md"] == Date(timeIntervalSince1970: 1_767_225_600))
	}

	@Test(.temporaryDirectory)
	func `last commit dates leave out the ignored commits`() async throws {
		let root = try URL.temporaryDirectory(files: ["content/a.md": "A", "content/b.md": "B"])

		try await git(in: root, "init", "--quiet")
		try await git(in: root, "add", ".")
		try await git(
			in: root,
			"commit",
			"--quiet",
			"-m",
			"Add"
		)
		try Data("A, changed".utf8).write(to: root.appending(path: "content/a.md"))
		try Data("B, changed".utf8).write(to: root.appending(path: "content/b.md"))
		try await git(
			in: root,
			"commit",
			"--quiet",
			"-am",
			"Change the syntax of all files",
			date: "2026-02-01T00:00:00Z"
		)
		let hash = try await git(in: root, "rev-parse", "HEAD")
		try Data("A, changed again".utf8).write(to: root.appending(path: "content/a.md"))
		try await git(
			in: root,
			"commit",
			"--quiet",
			"-am",
			"Change",
			date: "2026-03-01T00:00:00Z"
		)

		let project = Project(root: root)
		try Data("# A change of syntax\n\n\(hash.prefix(8)) # The frontmatter\n".utf8).write(to: project.ignoredCommitsFile)
		let dates = await project.lastCommitDates()

		// The ignored commit changed both, so `b.md` keeps the date of the commit before it.
		#expect(dates["content/a.md"] == Date(timeIntervalSince1970: 1_772_323_200))
		#expect(dates["content/b.md"] == Date(timeIntervalSince1970: 1_767_225_600))
	}

	@Test(.temporaryDirectory)
	func `changed files have each modified and new file, both paths of a rename, and non-ASCII names`() async throws {
		let root = try URL.temporaryDirectory(files: ["a.md": "A", "README.md": "Readme", "c.md": "C"])

		try await git(in: root, "init", "--quiet")
		try await git(in: root, "add", ".")
		try await git(
			in: root,
			"commit",
			"--quiet",
			"-m",
			"Add"
		)

		// A modified file, the most common change.
		try Data("A, changed".utf8).write(to: root.appending(path: "a.md"))

		// A staged rename, with an old path that starts with `R`.
		try await git(
			in: root,
			"mv",
			"README.md",
			"readme-new.md"
		)

		// A rename in the worktree column: a file that was moved without git, and whose new path was added with `--intent-to-add`.
		try FileManager.default.moveItem(at: root.appending(path: "c.md"), to: root.appending(path: "e.md"))
		try await git(
			in: root,
			"add",
			"--intent-to-add",
			"e.md"
		)

		// A new directory with two files, and a non-ASCII name.
		try root.appending(path: "new").createDirectory()
		try Data("F".utf8).write(to: root.appending(path: "new/f.md"))
		try Data("Ø".utf8).write(to: root.appending(path: "new/ø.md"))

		let project = Project(root: root)
		let paths = Set(try await project.changedFiles().map { $0.path(percentEncoded: false) })
		let expected = Set(["a.md", "readme-new.md", "README.md", "e.md", "c.md", "new/f.md", "new/ø.md"].map { root.appending(path: $0).path(percentEncoded: false) })
		#expect(paths == expected)
	}

	@Test
	func `a process returns its exit status, and its output can be read while it runs`() async throws {
		let succeeding = Process()
		succeeding.executableURL = URL(filePath: "/usr/bin/true")
		#expect(try await succeeding.runUntilExit() == .exit(0))

		let failing = Process()
		failing.executableURL = URL(filePath: "/usr/bin/false")
		#expect(try await failing.runUntilExit() == .exit(1))

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

		#expect(status == .exit(0))
		#expect(lines == ["Hello"])

		let missing = Process()
		missing.executableURL = URL(filePath: "/nonexistent")

		await #expect(throws: (any Error).self) {
			try await missing.runUntilExit()
		}
	}

	@Test
	func `a process distinguishes an exit code from a signal with the same number`() async throws {
		let exiting = Process()
		exiting.executableURL = URL(filePath: "/bin/sh")
		exiting.arguments = ["-c", "exit 15"]
		#expect(try await exiting.runUntilExit() == .exit(15))

		let signalled = Process()
		signalled.executableURL = URL(filePath: "/bin/sh")
		signalled.arguments = ["-c", "kill -TERM $$"]
		#expect(try await signalled.runUntilExit() == .signal(15))
	}

	@Test
	func `slugs are relative to the content directory`() throws {
		let file = try MarkdownFile(contents: "Body", url: URL(filePath: "/content/apps/faq.md"), relativeTo: URL(filePath: "/content"))
		#expect(file.slug == "apps/faq")
	}
}

/**
Runs git in the repository as a test user, with the date of the commits, and returns its output.
*/
@discardableResult
private func git(in root: URL, _ arguments: String..., date: String = "2026-01-01T00:00:00Z") async throws -> String {
	let process = Process()
	process.executableURL = URL(filePath: "/usr/bin/env")
	process.arguments = ["git", "-C", root.path(percentEncoded: false), "-c", "user.name=Test", "-c", "user.email=test@example.com"] + arguments
	// The `PATH` of the tests, so it runs the same git as `lastCommitDates()`. A `PATH` with `/usr/bin` first runs `/usr/bin/git`, which asks `xcodebuild` where the git of Xcode is when its cache does not know it yet, like on CI, where git is the one of Homebrew. The test took 24 to 31 s on CI.
	process.environment = ["GIT_COMMITTER_DATE": date, "GIT_AUTHOR_DATE": date, "PATH": ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin"]
	let pipe = Pipe()
	process.standardOutput = pipe
	var output = ""

	try #require(await process.runUntilExit {
		for try await line in pipe.fileHandleForReading.bytes.lines {
			output += line
		}
	} == .exit(0), "git \(arguments.joined(separator: " ")) failed.")

	return output
}

@Frontmatter
public struct DiagnosticFrontmatter {
	@Key("name")
	public var title: String
	public var children: [Child]
	public var optional: Child?

	public func validate(into problems: inout FrontmatterProblems<Self>) {
		if title.isEmpty {
			problems.add("Title is required.", at: .title)
		}

		problems.validate(children, at: .children)
		problems.validate(optional, at: .optional)
	}

	@Frontmatter
	public struct Child {
		@Key("caption")
		public var title: String
		public var children: [Self]

		public func validate(into problems: inout FrontmatterProblems<Self>) {
			if title.isEmpty {
				problems.add("Caption is required.", at: .title)
			}

			problems.validate(children, at: .children)
		}
	}
}
