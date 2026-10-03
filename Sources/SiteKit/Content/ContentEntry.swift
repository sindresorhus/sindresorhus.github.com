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
	The order of the loaded entries.
	*/
	static var sortOrder: [KeyPathComparator<Self>] { get }

	init(file: MarkdownFile, frontmatter: Frontmatter, project: Project) throws

	/**
	Drafts are not loaded.
	*/
	var isDraft: Bool { get }
}

extension ContentEntry {
	public var isDraft: Bool {
		false
	}

	/**
	Loads the entries from the Markdown files in ``directory`` and its subdirectories.

	```swift
	let posts = try BlogPost.load(from: project)
	```

	Each file is decoded and validated. The mistakes of all files are thrown together as ``ContentErrors``, with file paths and lines. Drafts are left out, and the entries are sorted by ``sortOrder``.
	*/
	public static func load(from project: Project) async throws(ContentErrors) -> [Self] {
		let directoryURL = project.root.appending(path: directory)

		guard
			directoryURL.isDirectory,
			let files = try? directoryURL.filesRecursively()
		else {
			throw ContentErrors([ContentError(file: directoryURL, reason: "The content directory does not exist.")])
		}

		let lastCommitDates = project.lastCommitDates(in: directory)

		let markdownFiles = files
			.filter { $0.pathExtension == "md" }
			.sorted(using: KeyPathComparator(\.path, comparator: String.StandardComparator.lexical))

		// The files are loaded in parallel, and every file is loaded, so all mistakes are reported at once. The results are put back in path order, so entries with the same sort key always come out in the same order.
		var entriesByIndex = [Self?](repeating: nil, count: markdownFiles.count)
		var errors = [ContentError]()

		await withTaskGroup(of: (index: Int, entry: Self?, errors: [ContentError]).self) { group in
			for (index, url) in markdownFiles.enumerated() {
				group.addTask {
					do {
						var file = try MarkdownFile(url: url, relativeTo: directoryURL)
						file.lastCommitDate = lastCommitDates[url.path(relativeTo: project.root)]
						let frontmatter = try file.decodeFrontmatter(as: Frontmatter.self)
						return (index, try Self(file: file, frontmatter: frontmatter, project: project), [])
					} catch {
						return (index, nil, ContentErrors(converting: error, file: url).errors)
					}
				}
			}

			for await result in group {
				entriesByIndex[result.index] = result.entry
				errors += result.errors
			}
		}

		let entries = entriesByIndex.compactMap(\.self)
		errors.sort(using: [KeyPathComparator(\.file.path, comparator: String.StandardComparator.lexical), KeyPathComparator(\.line)])

		guard errors.isEmpty else {
			throw ContentErrors(errors)
		}

		// The sort is stable, so ties keep the path order.
		return entries
			.filter { !$0.isDraft }
			.sorted(using: sortOrder)
	}
}
