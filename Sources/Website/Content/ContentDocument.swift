import Foundation
import SiteKit

/**
A content file with a page, like an app, a blog post, or a Markdown page.

The type owns the rule for the path of its pages, so links to content files, like `[Dato](dato.md)`, always go to the real page.
*/
protocol ContentDocument: ContentEntry {
	/**
	The path of the page of a file, by its slug, like `/dato` for `dato`.
	*/
	static func path(slug: String) -> RoutePath

	/**
	The content file, for reporting mistakes at their line.
	*/
	var file: MarkdownFile { get }

	var markdown: MarkdownDocument { get }

	/**
	Old paths of the page, like `/old-name`. They redirect to the page.
	*/
	var redirectFrom: [RoutePath] { get }

	/**
	Makes the document link to a page elsewhere, like a GitHub repo, instead of having a page.
	*/
	var redirectURL: URL? { get }
}

extension ContentDocument {
	/**
	The path of the file relative to the content directory, without the extension, like `dato`.
	*/
	var slug: String {
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

	var redirectURL: URL? {
		nil
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
		redirectURL ?? path.absoluteURL
	}
}

extension Project {
	/**
	The project of the site at the root, with the path of the pages of each content type, so the files of a page bundle are published next to its page, like `/dato/icon.png` for `content/apps/dato/icon.png` and `/blog/post/image.png` for `content/blog/post/image.png`.
	*/
	public static func site(root: URL) -> Self {
		Self(root: root, pageRoutes: [App.directory: .root, BlogPost.directory: .blog, MarkdownPage.directory: .root])
	}
}

extension RoutePath {
	/**
	The path of the page of a content file, like `/dato` for `content/apps/dato/index.md`, by the path rule of its content type. `nil` when the file is not in the directory of a content type with pages.

	Limitation: Apps and posts are flat, so a file in a subdirectory of `content/apps` or `content/blog` has no page, except for the `index.md` of a page bundle, like `content/apps/dato/index.md`.
	*/
	init?(contentFile file: URL, project: Project) {
		let types: [any ContentDocument.Type] = [App.self, BlogPost.self, MarkdownPage.self]

		for type in types {
			let directory = project.root.appending(path: type.directory)

			guard file.isInside(directory) else {
				continue
			}

			let slug = MarkdownFile.slug(of: file, relativeTo: directory)

			guard type.allowsSubdirectories || !slug.contains("/") else {
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
	A link in the file, with a link to another content file, like `dato.md` or `../pages/about.md`, as the path of its page, and a link to a file of its page bundle, like `screenshot.png`, as the path of the published file. Other links stay as they are. A relative link with a file extension to a file that does not exist is an error, like a typo in a file name.
	*/
	func resolvingLink(_ destination: String, project: Project) throws(ContentError) -> String {
		let path = String(destination.prefix { $0 != "#" })
		let fragment = destination.dropFirst(path.count)

		guard
			!path.isEmpty,
			!path.contains(":"),
			!path.hasPrefix("/")
		else {
			return destination
		}

		let target = url.deletingLastPathComponent().appending(path: path).standardizedFileURL

		// A file of the page bundle, like `screenshot.png` next to `index.md`.
		guard path.hasSuffix(".md") else {
			if let publicPath = project.publicPath(ofContentFile: target) {
				return publicPath.description + fragment
			}

			// A link with a file extension goes to a file, so a missing one is a mistake, like a typo. A link without one, like `donate`, goes to a page.
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

		return route.description + fragment
	}
}
