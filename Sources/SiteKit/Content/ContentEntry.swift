import Foundation

/**
A type loaded from a Markdown file with typed frontmatter, like a blog post.
*/
public protocol ContentEntry: Sendable {
	associatedtype Frontmatter: SiteKit.Frontmatter

	/**
	The directory with the Markdown files, relative to the project root, like `content/blog`.
	*/
	static var directory: Project.ContentDirectory { get }

	/**
	Whether the Markdown files can be in subdirectories of ``directory``. When `false`, a file in a subdirectory is a content error, for example when the slug is one component of a path, but a page bundle, like `dato/index.md`, is allowed. The default is `true`.
	*/
	static var allowsSubdirectories: Bool { get }

	/**
	The order of the loaded entries.
	*/
	static var sortOrder: [KeyPathComparator<Self>] { get }

	init(file: DecodedMarkdownFile<Frontmatter>, project: Project) async throws

	/**
	Drafts are loaded apart from the other entries (``ContentLoad/drafts``), so they are not published.
	*/
	var isDraft: Bool { get }
}

/**
The result of loading a content directory. An unavailable directory has no entries to check; a loaded directory can retain valid entries alongside mistakes in other files.
*/
public enum ContentLoad<Entry: ContentEntry>: Sendable {
	case unavailable(ContentErrors)
	case loaded(Loaded)

	/**
	The result of a directory that could be read. The values have names, not positions, as ``entries`` and ``drafts`` have the same type.
	*/
	public struct Loaded: Sendable {
		/**
		The entries without the drafts, which are apart, so only the preview of `website serve` shows them.
		*/
		public let entries: [Entry]

		/**
		The drafts that loaded successfully (`isDraft: true`).
		*/
		public let drafts: [Entry]

		/**
		The slugs of the files with mistakes, so the caller can leave out the checks that need an entry that did not load.
		*/
		public let failedSlugs: Set<String>

		public let errors: [ContentError]
	}

	/**
	The entries that loaded successfully, for checks between available documents. An unavailable directory has none; use the `.loaded` case when its availability matters.
	*/
	public var validEntries: [Entry] {
		switch self {
		case .loaded(let loaded):
			loaded.entries
		case .unavailable:
			[]
		}
	}

	/**
	The drafts that loaded successfully (`isDraft: true`), for the preview of `website serve`. An unavailable directory has none.
	*/
	public var drafts: [Entry] {
		switch self {
		case .loaded(let loaded):
			loaded.drafts
		case .unavailable:
			[]
		}
	}

	/**
	All mistakes found while loading the directory.
	*/
	public var errors: [ContentError] {
		switch self {
		case .unavailable(let failure):
			failure.errors
		case .loaded(let loaded):
			loaded.errors
		}
	}
}

extension ContentEntry {
	public static var allowsSubdirectories: Bool {
		true
	}

	/**
	Whether a file with the slug can be an entry: any file when ``allowsSubdirectories``, else only a file directly in ``directory``, or the `index.md` of a page bundle, like `dato` for `dato/index.md`.
	*/
	public static func allows(slug: String) -> Bool {
		allowsSubdirectories || !slug.contains("/")
	}

	/**
	Loads the entries from the Markdown files in ``directory`` and, when ``allowsSubdirectories``, its subdirectories.

	```swift
	let posts = try await BlogPost.load(from: project, lastCommitDates: project.lastCommitDates())
	```

	Each file is decoded and validated. The mistakes of all files are thrown together as ``ContentErrors``, with file paths and lines. Drafts are left out (``ContentLoad/drafts`` has them), and the entries are sorted by ``sortOrder``.

	- Parameter lastCommitDates: The dates from ``Project/lastCommitDates()``, which the files get as ``MarkdownFile/lastCommitDate``.
	*/
	public static func load(from project: Project, lastCommitDates: [URL: Date] = [:]) async throws(ContentErrors) -> [Self] {
		let loaded = await load(from: project, lastCommitDates: lastCommitDates) { file in
			try await Self(file: file, project: project)
		}

		guard
			case .loaded(let result) = loaded,
			result.errors.isEmpty
		else {
			throw ContentErrors(loaded.errors)
		}

		return result.entries
	}

	/**
	Loads the entries like ``load(from:lastCommitDates:)``, but makes each entry with the closure, like with a value that all the entries share, which the caller loads once, and returns the mistakes instead of throwing them. A `.loaded` result contains the entries of files without mistakes; `.unavailable` means the directory could not be read, so the caller leaves out checks against it. `failedSlugs` are the slugs of the files with mistakes, so the caller can check the entries against each other in the same run, and leave out the checks that need an entry that did not load.

	```swift
	let loadedApps = await App.load(from: project) { file in
		try await App(file: file, sharedQuestions: library, project: project)
	}
	```
	*/
	public static func load(
		from project: Project,
		lastCommitDates: [URL: Date] = [:],
		making makeEntry: @escaping @Sendable (DecodedMarkdownFile<Frontmatter>) async throws -> Self
	) async -> ContentLoad<Self> {
		let directoryURL = directory.fileURL(in: project.root)

		// It throws when the directory does not exist or cannot be read.
		let files: [URL]
		do {
			files = try directoryURL.filesRecursively()
		} catch {
			return .unavailable(ContentErrors(converting: error, file: directoryURL))
		}

		let markdownFiles = files.filter { $0.pathExtension == "md" }.map { (url: $0, slug: MarkdownFile.slug(of: $0, relativeTo: directoryURL)) }

		// The files are loaded in parallel, and every file is loaded, so all mistakes are reported at once. The results are put back in path order (``Foundation/URL/filesRecursively()`` sorts by path), so entries with the same sort key always come out in the same order.
		var entriesByIndex = [Self?](repeating: nil, count: markdownFiles.count)
		var failedSlugs = Set<String>()
		var errors = [ContentError]()

		let outcomes = await markdownFiles.concurrentMap { url, slug -> ContentEntryOutcome<Self> in
			do {
				guard allows(slug: slug) else {
					let name = url.lastPathComponent
					let folder = slug.split(separator: "/").dropLast().joined(separator: "/")

					// A file below the folder of a page.
					guard !folder.contains("/") else {
						throw ContentError(file: url, reason: "The file must be directly in `\(directory)`.")
					}

					// By the list of the files, not the disk, which can ignore case, so `Index.md` is not the `index.md` of the folder.
					guard markdownFiles.contains(where: { $0.slug == folder && $0.url.lastPathComponent == "index.md" }) else {
						throw ContentError(file: url, reason: "The page of a folder is its `index.md`. Rename `\(name)` to `index.md`, or move it out of the folder.")
					}

					throw ContentError(file: url, reason: "The folder already has its page, `index.md`, and only that Markdown file is read. Move `\(name)` out of `content`, or remove it.")
				}

				// The slug is the path of the page, and the paths of GitHub Pages are case-sensitive, so a link with another case would not find it.
				guard slug.wholeMatch(of: ContentSlug.pattern) != nil else {
					throw ContentError(file: url, reason: "The path of the file is the URL of its page, so its names can only have lowercase letters, digits, and hyphens. \(renameInstruction(of: url, slug: slug))")
				}

				var file = try MarkdownFile(url: url, relativeTo: directoryURL)
				file.lastCommitDate = lastCommitDates[url.standardizedFileURL]
				return .loaded(try await makeEntry(file.decoded()))
			} catch {
				return .failed(ContentErrors(converting: error, file: url))
			}
		}

		for (index, outcome) in outcomes.enumerated() {
			switch outcome {
			case .loaded(let entry):
				entriesByIndex[index] = entry
			case .failed(let failure):
				errors += failure.errors
				failedSlugs.insert(markdownFiles[index].slug)
			}
		}

		// Two files can be the same page, like `a.md` and `a/index.md`. Neither is an entry, so the page is not reported again as two documents with one path.
		for (slug, indexes) in Dictionary(grouping: markdownFiles.indices, by: { markdownFiles[$0].slug }) where indexes.count > 1 {
			for index in indexes.dropFirst() {
				errors.append(ContentError(file: markdownFiles[index].url, reason: "It is the same page as `\(markdownFiles[indexes[0]].url.path(relativeTo: project.root))`. Rename or remove one of them."))
			}

			for index in indexes {
				entriesByIndex[index] = nil
			}

			failedSlugs.insert(slug)
		}

		errors.sort(using: ContentError.locationOrder)

		// The sort is stable, so ties keep the path order.
		let entries = entriesByIndex
			.compactMap(\.self)
			.sorted(using: sortOrder)

		return .loaded(ContentLoad.Loaded(
			entries: entries.filter { !$0.isDraft },
			drafts: entries.filter(\.isDraft),
			failedSlugs: failedSlugs,
			errors: errors
		))
	}

	/**
	What to rename for a slug that is not valid: the first name in it with other characters, which is the folder of a page bundle, like `Empathy-In-Open-Source`, or the file, with its fixed name, like `empathy-in-open-source`.
	*/
	private static func renameInstruction(of url: URL, slug: String) -> String {
		let names = slug.split(separator: "/")

		guard let index = names.firstIndex(where: { $0.wholeMatch(of: ContentSlug.pattern) == nil }) else {
			return ""
		}

		let name = String(names[index])
		// Each run of other characters, like `_` or a space, becomes a hyphen.
		let fixedName = name.lowercased().split { !($0.isASCII && ($0.isLetter || $0.isNumber)) }.joined(separator: "-")

		// The last name is the file, except for the `index.md` of a page bundle, whose slug ends with its folder.
		guard
			index == names.indices.last,
			url.lastPathComponent != "index.md"
		else {
			return "Rename the folder `\(name)` to `\(fixedName)`."
		}

		return "Rename the file `\(name).md` to `\(fixedName).md`."
	}
}

/**
The outcome of loading one file, before the loader combines successful entries and errors from all files.
*/
private enum ContentEntryOutcome<Entry: ContentEntry>: Sendable {
	case loaded(Entry)
	case failed(ContentErrors)
}
