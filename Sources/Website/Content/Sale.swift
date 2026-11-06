import Foundation
import Markdown
import SiteKit
import SOML

/**
A sale that runs on the day of the build: a `@Scheduled` block with a `sale` name that its page shows now, like the Black Friday block of the discounts page. The page of each app that the block links to shows a note about it (``AppPage``), so the dates and the apps of a sale are only written in the block. The block links to an app with a site path, like `/dato`, a link to its content file, or its product on Gumroad. A relative link to the page, like `../dato`, does not count.
*/
struct Sale {
	/**
	The name of the sale, like “Black Friday”.
	*/
	let name: String

	let lastDay: SOML.Date

	/**
	The page with the block, which the note links to.
	*/
	let page: RoutePath

	/**
	The pages of the site that the block links to, like `/dato`.
	*/
	let linkedPaths: Set<RoutePath>

	/**
	The other links of the block, like the Gumroad link of an app with the code of the sale.
	*/
	let externalLinks: [String]

	/**
	Whether the block links to the page of the app, or to its product on Gumroad, like `https://sindresorhus.gumroad.com/l/supercharge/BLACKFRIDAY`.
	*/
	func includes(_ app: App) -> Bool {
		if linkedPaths.contains(app.path) {
			return true
		}

		guard let product = app.purchase.gumroad?.id.url.absoluteString else {
			return false
		}

		// The product link can have a code or a query after it.
		return externalLinks.contains { $0 == product || $0.hasPrefix("\(product)/") || $0.hasPrefix("\(product)?") }
	}
}

extension MarkdownPage {
	/**
	The sales of the page that run on the day: its `@Scheduled` blocks with a `sale` name that the page shows on that day.

	- Parameter today: The day of the build.
	*/
	func sales(on today: SOML.Date, project: Project) -> [Sale] {
		let document = Document(parsing: file.body, options: .parseBlockDirectives)
		var rewriter = ScheduledContentRewriter(today: today)
		let visibleDocument = rewriter.visit(document) as? Document ?? document

		return visibleDocument.blockDirectives.compactMap { directive -> Sale? in
			// The build already reported invalid arguments.
			guard
				directive.siteName == .scheduled,
				let arguments = try? directive.arguments(as: ScheduledArguments.self),
				let name = arguments.sale
			else {
				return nil
			}

			let destinations = directive.descendants(of: Markdown.Link.self).compactMap(\.destination)

			// A link to another content file, like `../../apps/dato/index.md`, is the path of its page.
			let linkedPaths = destinations.compactMap { destination -> RoutePath? in
				guard
					let resolved = try? file.resolvingLink(destination, project: project),
					case .path(let path, _, _)? = try? LinkDestination(validating: resolved)
				else {
					return nil
				}

				return path
			}

			return Sale(
				name: name,
				lastDay: arguments.until.date,
				page: path,
				linkedPaths: Set(linkedPaths),
				externalLinks: destinations.filter { $0.hasPrefix("https://") }
			)
		}
	}
}

/**
Removes inactive scheduled blocks before collecting sales and their links, so a hidden ancestor or descendant contributes neither.
*/
private struct ScheduledContentRewriter: MarkupRewriter {
	let today: SOML.Date

	mutating func visitBlockDirective(_ directive: BlockDirective) -> (any Markup)? {
		if
			directive.siteName == .scheduled,
			(try? directive.arguments(as: ScheduledArguments.self))?.contains(today) != true
		{
			return nil
		}

		return defaultVisit(directive)
	}
}
