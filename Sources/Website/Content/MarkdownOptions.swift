import Foundation
import Markdown
import SiteKit

extension MarkdownDocument.Options {
	/**
	The site's classes, and no other options. For short texts, like frontmatter fields.
	*/
	static let site = Self(theme: .site)

	/**
	The options for a content file: the site's classes, the known heading directives, links to other content files (`[Dato](dato.md)`), the sizes of local images, platform badges, the block directives, footnotes in popovers, and copy buttons on code blocks.
	*/
	static func content(_ file: MarkdownFile, project: Project) -> Self {
		Self(
			theme: .site,
			headingDirectives: ["faq.keywords", "faq.platforms"],
			inlineAttributes: renderInlineAttributes,
			blockDirectives: [
				"Details": renderDetails,
				"Tips": renderTips,
			],
			resolveLink: { destination in
				try resolveContentLink(destination, from: file, project: project)
			},
			imageSize: { source in
				source.hasPrefix("/") ? project.publicFile(source).mediaSize : nil
			},
			showsFootnotesInPopovers: true,
			addsCopyButtons: true
		)
	}

	/**
	The questions below the “Frequently Asked Questions” heading of an app page are collapsible, followed by a link to the general FAQ. Each section has a link that copies its URL. The feedback question is added to the questions.
	*/
	static func appPage(_ file: MarkdownFile, project: Project, appTitle: String) -> Self {
		var options = content(file, project: project)
		options.collapsibleSections = MarkdownDocument.CollapsibleSections(level: 4, startHeadingID: "faq", name: "faq", moreLink: .init(title: "More FAQs", url: MarkdownPage.faqPath.description))
		options.addsHeadingAnchors = true
		options.rewrite = { $0.addingFeedbackQuestion(appTitle: appTitle) }
		return options
	}

	/**
	Every question of the general FAQ is collapsible, and each has a link that copies its URL.
	*/
	static func faqPage(_ file: MarkdownFile, project: Project) -> Self {
		var options = content(file, project: project)
		options.collapsibleSections = MarkdownDocument.CollapsibleSections(level: 3, name: "faq")
		options.addsHeadingAnchors = true
		return options
	}
}

/**
A mistake in the Markdown of a content file.
*/
private struct MarkdownContentError: Error, CustomStringConvertible {
	let description: String

	init(_ description: String) {
		self.description = description
	}
}

/**
Links to other content files, like `dato.md` or `../pages/about.md`, become the paths of their pages. Other links stay as they are.
*/
private func resolveContentLink(_ destination: String, from file: MarkdownFile, project: Project) throws -> String {
	let path = String(destination.prefix { $0 != "#" })
	let fragment = destination.dropFirst(path.count)

	guard
		path.hasSuffix(".md"),
		!path.contains(":"),
		!path.hasPrefix("/")
	else {
		return destination
	}

	let target = file.url.deletingLastPathComponent().appending(path: path).standardizedFileURL

	guard
		target.isFile,
		let route = Site.routePath(ofContentFile: target.path(relativeTo: project.root.appending(path: "content")))
	else {
		throw MarkdownContentError("The link `\(destination)` goes to a content file that does not exist.")
	}

	return route.description + fragment
}

/**
Platform badges, like `^[macOS only](platform: "macOS")`.
*/
@Sendable
private func renderInlineAttributes(_ attributes: String, contentHTML: String) throws -> String {
	guard
		let values = try? JSONDecoder.json5.decode([String: String].self, from: Data("{\(attributes)}".utf8)),
		values.count == 1,
		let name = values["platform"]
	else {
		throw MarkdownContentError("The inline attributes `\(attributes)` are not supported. Use `platform: \"macOS\"`.")
	}

	guard let platform = Platform(rawValue: name) else {
		throw MarkdownContentError("Unknown platform “\(name)”. Known platforms: \(Platform.allCases.map(\.rawValue).joined(separator: ", ")).")
	}

	return #"<span class="\#(Badge.Styles.root.className) \#(Badge.Kind.platform.className)" data-platform="\#(platform.rawValue)">\#(contentHTML)</span>"#
}

/**
A collapsible section, like `@Details(summary: "Why?") { … }`, with the look of the FAQ questions.
*/
@Sendable
private func renderDetails(arguments: [String: String], contentHTML: String) throws -> String {
	guard
		let summary = arguments["summary"],
		arguments.count == 1
	else {
		throw MarkdownContentError("`@Details` needs one argument: `summary`, like `@Details(summary: \"Why?\")`.")
	}

	return #"<details class="\#(ProseStyles.collapsibleSection.className)"><summary class="\#(ProseStyles.collapsibleSummary.className)"><span class="\#(ProseStyles.collapsibleTitle.className)">\#(MarkdownDocument.inlineHTML(summary, options: .site))</span><span class="\#(ProseStyles.collapsibleChevron.className)" aria-hidden="true"></span></summary><div class="\#(ProseStyles.collapsibleContent.className)">\#(contentHTML)</div></details>"#
}

/**
A box of tips, like `@Tips { - Tip }`, with the look of a tip alert.
*/
@Sendable
private func renderTips(arguments: [String: String], contentHTML: String) throws -> String {
	guard arguments.isEmpty else {
		throw MarkdownContentError("`@Tips` has no arguments.")
	}

	let icon = #"<svg class="\#(ProseStyles.alertIcon.className)" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true"><path d="\#(MarkdownAlert.tip.iconPath)"></path></svg>"#
	return #"<aside class="\#(MarkdownTheme.site.classes(for: .alert(.tip)))"><p class="\#(ProseStyles.alertTitle.className)">\#(icon)Tips</p>\#(contentHTML)</aside>"#
}

extension JSONDecoder {
	/**
	A decoder that accepts JSON5, like unquoted keys.
	*/
	fileprivate static var json5: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.allowsJSON5 = true
		return decoder
	}
}

extension Document {
	/**
	Adds the feedback question to the FAQ section, or adds the answer to an existing “feature request” question.
	*/
	fileprivate func addingFeedbackQuestion(appTitle: String) -> Document {
		var blocks = Array(blockChildren)

		guard let faqIndex = blocks.firstIndex(where: { block in
			guard let heading = block as? Markdown.Heading else {
				return false
			}

			return heading.level == 2 && heading.plainText.contains(App.faqHeadingTitle)
		}) else {
			return self
		}

		let sectionEnd = blocks[(faqIndex + 1)...].firstIndex { (($0 as? Markdown.Heading)?.level ?? 3) <= 2 } ?? blocks.endIndex
		let answerMarkdown = "Click the feedback button in the app or [send it here.](\(Site.url.absoluteString)\(App.feedbackPath(appTitle: appTitle))&referrer=Website-FAQ)"

		guard let answer = Document(parsing: answerMarkdown).child(at: 0) as? Paragraph else {
			return self
		}

		let customID = Markdown.Text(" {#\(App.feedbackHeadingID)}")

		if let questionIndex = blocks[(faqIndex + 1)..<sectionEnd].firstIndex(where: { block in
			guard let heading = block as? Markdown.Heading else {
				return false
			}

			return heading.level == 4 && heading.plainText.lowercased().contains("feature request")
		}), let question = blocks[questionIndex] as? Markdown.Heading {
			// The question gets the feedback ID instead of its own.
			let content = question.inlineChildren.map { child -> InlineMarkup in
				guard let text = child as? Markdown.Text else {
					return child
				}

				return Markdown.Text(text.string.replacing(/\s*\{#[\w-]+\}\s*$/, with: ""))
			}

			blocks[questionIndex] = Markdown.Heading(level: question.level, content + [customID])
			blocks.insert(answer, at: questionIndex + 1)
		} else {
			let question = Markdown.Heading(level: 4, [Markdown.Text("I have a feature request, bug report, or some feedback"), customID])
			blocks.insert(contentsOf: [question, answer] as [any BlockMarkup], at: faqIndex + 1)
		}

		return Document(blocks)
	}
}
