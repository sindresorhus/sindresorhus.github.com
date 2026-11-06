import Foundation
import SiteKit
import SOML

/**
A content file with a page, like an app, a blog post, or a Markdown page.

The type owns the rule for the path of its pages, so links to content files, like `[Dato](dato.md)`, always go to the real page. Frontmatter values are available directly on the document, like `app.title`.
*/
@dynamicMemberLookup
protocol ContentDocument: ContentEntry where Frontmatter: DocumentFrontmatter {
	/**
	The path that the pages of the type are at, like `.blog` for `/blog/post`. The default is the root, like `/dato`.
	*/
	static var pageRoute: RoutePath { get }

	/**
	The root keys the formatter orders. Empty preserves authored order.
	*/
	static var formattingKeys: [any CodingKey] { get }

	/**
	The path of the page of a file, by its slug, like `/dato` for `dato`.
	*/
	static func path(slug: ContentSlug) -> RoutePath

	/**
	The content file, for reporting mistakes at their line.
	*/
	var file: MarkdownFile { get }

	/**
	The source and its validated frontmatter, kept together from decoding through rendering and keyed diagnostics.
	*/
	var decodedFile: DecodedMarkdownFile<Frontmatter> { get }

	var frontmatter: Frontmatter { get }
	var markdown: MarkdownDocument { get }
}

/**
The frontmatter of a ``ContentDocument``, so the document has its values without forwarding them.
*/
protocol DocumentFrontmatter: SiteKit.Frontmatter {
	var title: String { get }
	/**
	Old paths of the page, like `/old-name`. They redirect to the page.
	*/
	var redirectFrom: [RoutePath] { get }

	/**
	The key of ``redirectFrom``, for the line of a mistake in it.
	*/
	static var redirectFromKey: CodingKeys { get }

	/**
	Makes the document link to a page elsewhere, like a GitHub repo, instead of having a page. The default is `nil`, for the types without the key.
	*/
	var redirectURL: AbsoluteURL? { get }
}

extension DocumentFrontmatter {
	var redirectURL: AbsoluteURL? {
		nil
	}
}

/**
The frontmatter of a document that is published on a day, like an app or a post, which can be a draft until then.
*/
protocol PublishedFrontmatter: DocumentFrontmatter {
	/**
	A draft is not published, and neither are the files of its page bundle.
	*/
	var isDraft: Bool { get }

	/**
	An unlisted document has its page, but it is not in the lists, the feeds, or the sitemap. The default is `false`, for the types without the key.
	*/
	var isUnlisted: Bool { get }

	var publicationDate: SOML.Date { get }

	/**
	The key of ``publicationDate``, for the line of a mistake in it.
	*/
	static var publicationDateKey: CodingKeys { get }
}

extension PublishedFrontmatter {
	var isUnlisted: Bool {
		false
	}

	/**
	Adds a mistake when a document that is published has a date in the future, like a wrong year, as the lists, the feeds, and the sitemap would show the date. A draft can have the day it will be published.

	Limitation: A day is in the future from the day after today (UTC), so a document written just after midnight in a time zone ahead of UTC, with the date of that day, passes the build that runs in UTC.
	*/
	func validatePublicationDate(into problems: inout FrontmatterProblems<Self>) {
		guard
			!isDraft,
			publicationDate > SOML.Date(Date.now.addingTimeInterval(86_400))
		else {
			return
		}

		problems.add("The date is in the future. Use `isDraft: true` until the day it is published.", at: Self.publicationDateKey)
	}
}

/**
The content types that have pages, in the order the build loads them, so the paths of their files and the files of their page bundles have one owner.
*/
let contentDocumentTypes: [any ContentDocument.Type] = [App.self, BlogPost.self, Guide.self, MarkdownPage.self]

extension ContentDocument {
	var file: MarkdownFile {
		decodedFile.source
	}

	var frontmatter: Frontmatter {
		decodedFile.frontmatter
	}

	static var formattingKeys: [any CodingKey] {
		[]
	}

	/**
	An error at one of this document’s frontmatter keys.
	*/
	func error(at key: Frontmatter.CodingKeys, index: Int? = nil, _ reason: String) -> ContentError {
		decodedFile.error(at: key, index: index, reason)
	}

	/**
	A warning at one of this document’s frontmatter keys.
	*/
	func warning(_ kind: Warning.Kind, at key: Frontmatter.CodingKeys, index: Int? = nil, _ message: String) -> Warning {
		decodedFile.warning(kind, at: key, index: index, message)
	}

	static var pageRoute: RoutePath {
		.root
	}

	static func path(slug: ContentSlug) -> RoutePath {
		pageRoute.appending(path: slug.value)
	}

	subscript<Value>(dynamicMember keyPath: KeyPath<Frontmatter, Value>) -> Value {
		frontmatter[keyPath: keyPath]
	}

	/**
	The path of the file relative to the content directory, without the extension, like `dato`.
	*/
	var slug: ContentSlug {
		file.slug
	}

	var path: RoutePath {
		Self.path(slug: slug)
	}

	/**
	When a commit last changed the content file.
	*/
	var lastCommitDate: Date? {
		file.lastCommitDate
	}

	var redirectFrom: [RoutePath] {
		frontmatter.redirectFrom
	}

	/**
	Where the old paths of the document are written, like for a redirect that writes the file of another route.
	*/
	var redirectSource: Route.Source {
		.redirect(key: Frontmatter.redirectFromKey.stringValue, file: file.url, line: file.line(of: Frontmatter.redirectFromKey))
	}

	var redirectURL: AbsoluteURL? {
		frontmatter.redirectURL
	}

	/**
	Where links to the document go: its page, or the page elsewhere.
	*/
	var url: LinkDestination {
		redirectURL.map { .url($0) } ?? .path(path)
	}

	var isRedirect: Bool {
		redirectURL != nil
	}

	/**
	The absolute URL of the page, or of the page elsewhere.
	*/
	var absoluteURL: URL {
		redirectURL?.value ?? path.absoluteURL
	}
}

extension ContentDocument where Frontmatter: PublishedFrontmatter {
	/**
	Published documents are newest first unless their type supplies another ordering.
	*/
	static var sortOrder: [KeyPathComparator<Self>] {
		[KeyPathComparator(\Self.frontmatter.publicationDate, order: .reverse)]
	}

	var isDraft: Bool {
		frontmatter.isDraft
	}

	/**
	Whether the document is shown in the lists, the feeds, and the sitemap. An unlisted document still has its page.
	*/
	var isListed: Bool {
		!frontmatter.isUnlisted
	}

	/**
	The calendar day of the last change, shared by article metadata, structured data, and the sitemap.

	The last commit of the content file, but never before the document was published.
	*/
	var lastModified: SOML.Date {
		max(lastCommitDate.map(SOML.Date.init) ?? frontmatter.publicationDate, frontmatter.publicationDate)
	}
}

extension Sequence where Element: ContentDocument, Element.Frontmatter: PublishedFrontmatter {
	/**
	The entry in the sitemap of a page that lists the documents, like the apps page: it changes when one of them changes, like a new app, so it has the newest date of the documents (``ContentDocument/lastModified``). No date for an empty list.
	*/
	var listSitemapEntry: SitemapEntry {
		SitemapEntry(lastModified: map(\.lastModified).max())
	}
}

extension Project {
	/**
	Formats the frontmatter of every Markdown content file, using the app and blog models' preferred root property order. Expands collections without changing values or page bodies, and returns only the files that changed.
	*/
	@discardableResult
	public func formatFrontmatter() throws(ContentErrors) -> [URL] {
		let files: [URL]

		do {
			files = try contentDirectory.filesRecursively().filter { $0.pathExtension == "md" }
		} catch {
			throw ContentErrors(converting: error, file: contentDirectory)
		}

		var changedFiles = [URL]()
		var errors = [ContentError]()

		for file in files {
			do {
				// Routing and formatting recognize the same content directories.
				let orderedKeys = contentDocumentTypes.first { file.isInside($0.directory.fileURL(in: root)) }?.formattingKeys ?? []

				let contents = try String(contentsOf: file, encoding: .utf8)
				let formatted = try MarkdownFile.formattingFrontmatter(in: contents, orderedKeys: orderedKeys)
				guard formatted != contents else {
					continue
				}

				try Data(formatted.utf8).write(to: file, options: .atomic)
				changedFiles.append(file)
			} catch {
				errors += ContentErrors(converting: error, file: file).errors
			}
		}

		guard errors.isEmpty else {
			throw ContentErrors(errors)
		}

		return changedFiles
	}

	/**
	The project of the site at the root, with the path of the pages of each content type, so the files of a page bundle are published next to its page, like `/dato/icon.png` for `content/apps/dato/icon.png` and `/blog/post/image.png` for `content/blog/post/image.png`.
	*/
	public static func site(root: URL) -> Self {
		Self(root: root, pageRoutes: Dictionary(uniqueKeysWithValues: contentDocumentTypes.map { ($0.directory, $0.pageRoute) }))
	}
}

extension RoutePath {
	/**
	The path of the page of a content file, like `/dato` for `content/apps/dato/index.md`, by the path rule of its content type. `nil` when the file is not in the directory of a content type with pages.

	Limitation: Apps, posts, and guides are flat, so a file in a subdirectory of `content/apps`, `content/blog`, or `content/guides` has no page, except for the `index.md` of a page bundle, like `content/apps/dato/index.md`.
	*/
	init?(contentFile file: URL, project: Project) {
		for type in contentDocumentTypes {
			let directory = type.directory.fileURL(in: project.root)

			guard file.isInside(directory) else {
				continue
			}

			let slug = MarkdownFile.slug(of: file, relativeTo: directory)

			guard
				type.allows(slug: slug),
				let slug = try? ContentSlug(validating: slug)
			else {
				return nil
			}

			self = type.path(slug: slug)
			return
		}

		return nil
	}
}

extension MarkdownFile {
	/**
	A link in the file, with a link to another content file, like `dato.md` or `../pages/about.md`, as the path of its page, and a link to a file of its page bundle, like `screenshot.png`, as the path of the published file. Other links stay as they are, and every link is checked as a ``LinkDestination``, except a relative link without an extension, like `donate`, which the browser resolves, as ``LinkDestination`` has no relative case. So a malformed URL or a path with `.` or `..` is an error, and so is a relative link with a file extension to a file that does not exist, like a typo in a file name.
	*/
	func resolvingLink(_ destination: String, project: Project) throws(ContentError) -> String {
		let path = String(destination.prefix { $0 != "#" })
		let fragment = destination.dropFirst(path.count)

		guard
			!path.isEmpty,
			!path.contains(":"),
			!path.hasPrefix("/")
		else {
			return try destination.checkedAsLink
		}

		let target = url.deletingLastPathComponent().appending(path: path).standardizedFileURL

		// A file of the page bundle, like `screenshot.png` next to `index.md`.
		guard path.hasSuffix(".md") else {
			if let publicPath = project.publicPath(ofContentFile: target) {
				return try "\(publicPath.description)\(fragment)".checkedAsLink
			}

			// A link with a file extension goes to a file, so a missing one is a mistake, like a typo. A link without one, like `donate`, goes to a page, so it stays relative, and the browser resolves it against the page's own path.
			guard target.pathExtension.isEmpty else {
				guard target.isFile else {
					throw ContentError(reason: "The link `\(destination)` goes to a file that does not exist next to the page.")
				}

				// Like a file next to a page that is a single Markdown file.
				throw ContentError(reason: "The link `\(destination)` goes to a file that is not published. Only the files directly next to the `index.md` of a page bundle are published.")
			}

			return destination
		}

		guard
			target.isFile,
			let route = RoutePath(contentFile: target, project: project)
		else {
			throw ContentError(reason: "The link `\(destination)` goes to a content file that does not exist.")
		}

		return try "\(route.description)\(fragment)".checkedAsLink
	}
}

extension MarkdownDocument {
	/**
	The Markdown of a frontmatter value of the file, like the feedback note of an app, with its links resolved and checked like the text of the file. Its problems are thrown at the key, as the lines of the SOML value are not the lines of the file.
	*/
	init<Value: Frontmatter>(parsing markdown: String, at key: Value.CodingKeys, of file: DecodedMarkdownFile<Value>, project: Project) throws(ContentErrors) {
		self.init(parsing: markdown, options: .content(file.source, project: project))

		guard problems.isEmpty else {
			throw ContentErrors(problems.map { file.error(at: key, "`\(key.stringValue)`: \($0.reason)") })
		}
	}

	/**
	The error of a level 1 heading in the text of a document whose page shows its title as the `h1`, like an app, a post, or a guide, as the heading would be a second `h1`. A Markdown page has no other title, so it can start with one.
	*/
	func titleHeadingError(in file: MarkdownFile) -> ContentError? {
		guard let heading = headings.first(where: { $0.level == .h1 }) else {
			return nil
		}

		return file.error(line: heading.line, "The page shows the title as its level 1 heading, so the text cannot have one. Make “\(heading.text)” a level 2 heading: `## \(heading.text)`.")
	}
}

extension String {
	/**
	The link, checked as a ``LinkDestination``, which rejects a relative link and a malformed URL. The value stays the same, so the `href` is the text of the content, not a URL that Foundation rewrote.
	*/
	fileprivate var checkedAsLink: String {
		get throws(ContentError) {
			_ = try LinkDestination(validating: self)
			return self
		}
	}
}

extension Collection {
	/**
	The content after a heading, including its subsections, until the next heading of the same or a higher level. Each representation supplies only its own heading projection.
	*/
	func contentOfSection(afterHeadingAt headingIndex: Index, level: HeadingLevel, headingLevel: (Element) -> HeadingLevel?) -> SubSequence {
		self[index(after: headingIndex)...].prefix { element in
			headingLevel(element).map { $0 > level } ?? true
		}
	}
}
