import Foundation
import Markdown
import SiteKit
import SOML

/**
A sale that runs on the day of the build: a `@Scheduled` block with a `sale` name that its page shows now, like the Black Friday block of the discounts page. The page of each paid and active app that the block links to shows a note about it (``AppPage``), so the dates and the apps of a sale are only written in the block. The block links to an app with a site path, like `/dato`, a link to its content file, or its product on Gumroad. A relative link to the page, like `../dato`, does not count. A free or archived app gets no note, also when the block links to it, like in “also see the free [Week Number](/week-number)”.
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
	The products on Gumroad that the block links to, like the link of an app with the code of the sale (``GumroadProductID/init(productURL:)``).
	*/
	let gumroadProducts: Set<GumroadProductID>

	/**
	Whether the app is paid and active, and the block links to its page, or to its product on Gumroad, like `https://sindresorhus.gumroad.com/l/supercharge/BLACKFRIDAY`.
	*/
	func includes(_ app: App) -> Bool {
		guard
			app.isPaid,
			app.isActive
		else {
			return false
		}

		return linkedPaths.contains(app.path) || app.purchase.gumroad.map { gumroadProducts.contains($0.id) } == true
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
				let arguments = directive.scheduled,
				let name = arguments.sale
			else {
				return nil
			}

			let destinations = directive.descendants(of: Markdown.Link.self).compactMap(\.destination)

			// A link to another content file, like `../../apps/dato/index.md`, is the path of its page.
			let linkedPaths = destinations.compactMap { file.linkedPagePath($0, project: project) }

			return Sale(
				name: name,
				lastDay: arguments.until.date,
				page: path,
				linkedPaths: Set(linkedPaths),
				gumroadProducts: Set(destinations.compactMap { URL(string: $0).flatMap(GumroadProductID.init(productURL:)) })
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
			let arguments = directive.scheduled,
			!arguments.contains(today)
		{
			return nil
		}

		return defaultVisit(directive)
	}
}
