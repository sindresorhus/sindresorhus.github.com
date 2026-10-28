import Foundation

/**
A type loaded from a Markdown file with typed frontmatter, like a blog post.
*/
public protocol ContentEntry: Sendable {
	associatedtype Frontmatter: SiteKit.Frontmatter

	/**
	The directory with the Markdown files, relative to the project root, like `content/blog`.
	*/
	static var directory: String { get }

	/**
	Whether the Markdown files can be in subdirectories of ``directory``. When `false`, a file in a subdirectory is a content error, for example when the slug is one component of a path, but a page bundle, like `dato/index.md`, is allowed. The default is `true`.
	*/
	static var allowsSubdirectories: Bool { get }

	/**
	The order of the loaded entries.
	*/
	static var sortOrder: [KeyPathComparator<Self>] { get }

	init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) async throws

	/**
	Drafts are not loaded.
	*/
	var isDraft: Bool { get }
}

/**
The result of loading a content directory. An unavailable directory has no entries to check; a loaded directory can retain valid entries alongside mistakes in other files.
*/
public enum ContentLoad<Entry: ContentEntry>: Sendable {
	case unavailable(ContentErrors)
	case loaded(entries: [Entry], failedSlugs: Set<String>, errors: [ContentError])

	/**
	The entries that loaded successfully, for checks between available documents. An unavailable directory has none; use the `.loaded` case when its availability matters.
	*/
	public var validEntries: [Entry] {
		switch self {
		case .loaded(let entries, _, _):
			entries
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
		case .loaded(_, _, let errors):
			errors
		}
	}
}

extension ContentEntry {
	public static var allowsSubdirectories: Bool {
		true
	}

	public var isDraft: Bool {
		false
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

	Each file is decoded and validated. The mistakes of all files are thrown together as ``ContentErrors``, with file paths and lines. Drafts are left out, and the entries are sorted by ``sortOrder``.

	- Parameter lastCommitDates: The dates from ``Project/lastCommitDates()``, which the files get as ``MarkdownFile/lastCommitDate``.
	*/
	public static func load(from project: Project, lastCommitDates: [String: Date] = [:]) async throws(ContentErrors) -> [Self] {
		let loaded = await load(from: project, lastCommitDates: lastCommitDates) { file, frontmatter in
			try await Self(file: file, frontmatter: frontmatter, project: project)
		}

		guard
			case .loaded(let entries, _, let errors) = loaded,
			errors.isEmpty
		else {
			throw ContentErrors(loaded.errors)
		}

		return entries
	}

	/**
	Loads the entries like ``load(from:lastCommitDates:)``, but makes each entry with the closure, like with a value that all the entries share, which the caller loads once, and returns the mistakes instead of throwing them. A `.loaded` result contains the entries of files without mistakes; `.unavailable` means the directory could not be read, so the caller leaves out checks against it. `failedSlugs` are the slugs of the files with mistakes, so the caller can check the entries against each other in the same run, and leave out the checks that need an entry that did not load.

	```swift
	let loadedApps = await App.load(from: project) { file, frontmatter in
		try await App(file: file, frontmatter: frontmatter, sharedQuestions: library, project: project)
	}
	```
	*/
	public static func load(
		from project: Project,
		lastCommitDates: [String: Date] = [:],
		making makeEntry: @escaping @Sendable (MarkdownFile, Frontmatter) async throws -> Self
	) async -> ContentLoad<Self> {
		let directoryURL = project.root.appending(path: directory)

		// It throws when the directory does not exist.
		guard let files = try? directoryURL.filesRecursively() else {
			return .unavailable(ContentErrors([ContentError(file: directoryURL, reason: "The content directory does not exist.")]))
		}

		let markdownFiles = files.filter { $0.pathExtension == "md" }.map { (url: $0, slug: MarkdownFile.slug(of: $0, relativeTo: directoryURL)) }

		// The files are loaded in parallel, and every file is loaded, so all mistakes are reported at once. The results are put back in path order (``Foundation/URL/filesRecursively()`` sorts by path), so entries with the same sort key always come out in the same order.
		var entriesByIndex = [Self?](repeating: nil, count: markdownFiles.count)
		var failedSlugs = Set<String>()
		var errors = [ContentError]()

		await withTaskGroup(of: (index: Int, outcome: ContentEntryOutcome<Self>).self) { group in
			for (index, item) in markdownFiles.enumerated() {
				let (url, slug) = item
				group.addTask {
					do {
						guard allows(slug: slug) else {
							throw ContentError(file: url, reason: "The file must be directly in `\(directory)`.")
						}

						// The slug is the path of the page, and the paths of GitHub Pages are case-sensitive, so a link with another case would not find it.
						guard slug.wholeMatch(of: MarkdownFile.slugPattern) != nil else {
							throw ContentError(file: url, reason: "The path of the file is the URL of its page, so its names can only have lowercase letters, digits, and hyphens. \(renameInstruction(of: url, slug: slug))")
						}

						var file = try MarkdownFile(url: url, relativeTo: directoryURL)
						file.lastCommitDate = lastCommitDates[url.path(relativeTo: project.root)]
						let frontmatter = try file.decodeFrontmatter(as: Frontmatter.self)
						return (index, .loaded(try await makeEntry(file, frontmatter)))
					} catch {
						return (index, .failed(ContentErrors(converting: error, file: url)))
					}
				}
			}

			for await result in group {
				switch result.outcome {
				case .loaded(let entry):
					entriesByIndex[result.index] = entry
				case .failed(let failure):
					errors += failure.errors
					failedSlugs.insert(markdownFiles[result.index].slug)
				}
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
			.filter { !$0.isDraft }
			.sorted(using: sortOrder)

		return .loaded(entries: entries, failedSlugs: failedSlugs, errors: errors)
	}

	/**
	What to rename for a slug that is not valid: the first name in it with other characters, which is the folder of a page bundle, like `Empathy-In-Open-Source`, or the file, with its fixed name, like `empathy-in-open-source`.
	*/
	private static func renameInstruction(of url: URL, slug: String) -> String {
		let names = slug.split(separator: "/")

		guard let index = names.firstIndex(where: { $0.wholeMatch(of: MarkdownFile.slugPattern) == nil }) else {
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
