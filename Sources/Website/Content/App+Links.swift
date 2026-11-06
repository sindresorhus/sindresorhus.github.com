import Foundation
import SiteKit

extension App {
	/**
	Links to the sections of the page (level 2 headings).
	*/
	private var sectionLinks: [LabeledLink] {
		markdown.headings
			.filter { $0.level == .h2 }
			.map { heading in
				let link = LabeledLink(heading.id == Section.faq.id ? "FAQ" : heading.text, destination: .fragment(heading.id))
				// The footer has a page about all the apps with the title of these two sections.
				return [Section.faq.id, Section.olderVersions.id].contains(heading.id) ? namingApp(link) : link
			}
	}

	/**
	The link with the app in its name for screen readers, like “Privacy Policy of Dato”, for a link whose title is also the title of a page about all the apps in the footer, like “Privacy Policy”, so the two are different in a list of the links of the page.
	*/
	private func namingApp(_ link: LabeledLink) -> LabeledLink {
		var link = link
		link.accessibilityLabel = "\(link.title) of \(self.title)"
		return link
	}

	/**
	The own download options: the site of the app as “Learn More”, the download on GitHub, or the purchase on Gumroad, and then the repo as “Source Code”.
	*/
	var ownOptions: [DownloadOption] {
		[
			frontmatter.redirectURL.map { .link(LabeledLink("Learn More", url: $0)) },
			frontmatter.gitHubDownload.map { .link(LabeledLink("Download", url: $0.url)) },
			gumroadURL.map { .link(LabeledLink("Buy", url: $0)) },
			frontmatter.redirectURL == nil ? frontmatter.repositoryURL.map(DownloadOption.sourceCode) : nil,
		]
		.compactMap(\.self)
	}

	/**
	The links in the app header: page sections, custom links, the beta on TestFlight, and support.
	*/
	var links: [LabeledLink] {
		// Apps with `olderVersions` have the “Older Versions” section, which the section links already have.
		var extraLinks = [LabeledLink]()

		if let invitation = frontmatter.testFlight {
			extraLinks.append(LabeledLink("TestFlight", url: invitation.url))
		}

		if !frontmatter.isArchived {
			extraLinks.append(LabeledLink("Support", destination: feedbackURL))
		}

		// The “Non-App Store Version” section is in the “…” menu instead.
		return sectionLinks
			.filter { $0.destination != .section(.nonAppStoreVersion) }
			.merging(frontmatter.links.labeledLinks)
			.merging(extraLinks)
	}

	/**
	The custom overflow links and the “Non-App Store Version” section.
	*/
	var overflowLinks: [LabeledLink] {
		frontmatter.overflowLinks.labeledLinks
			.merging(sectionLinks.filter { $0.destination == .section(.nonAppStoreVersion) })
	}

	/**
	The overflow links plus the standard pages about the app.
	*/
	var pageOverflowLinks: [LabeledLink] {
		var links = overflowLinks

		if !frontmatter.isArchived {
			if let appStoreURL = appStoreURL(placement: .whatsNew) {
				links.append(LabeledLink("What’s New", url: appStoreURL))
			}

			if let reviewURL {
				links.append(LabeledLink("Rate or Review", url: reviewURL))
			}

			if let releaseNotes {
				links.append(LabeledLink("Release Notes", path: releaseNotes.path))
			}

			links.append(namingApp(LabeledLink("Privacy Policy", path: privacyPolicyPath)))
			links.append(.termsOfUse)

			if frontmatter.isPaid {
				links.append(.discounts)
			}
		}

		return links
	}

	/**
	Whether the page asks visitors to get the app, like with the “Get” button: the app is not archived, and it has a place to get it.
	*/
	var isDownloadable: Bool {
		!frontmatter.isArchived && !placesToGet.isEmpty
	}

	/**
	The download options without the source code and the trial: the stores and the own links, like “Buy”.
	*/
	var placesToGet: [DownloadOption] {
		downloadOptions.filter(\.isPlaceToGet)
	}

	/**
	The places to get the app, and its trial, in the order they are shown. The stores come first when the app is on the App Store, as most visitors get it there. Otherwise, the own links, like “Buy”, and the trial come before Setapp, so the page offers its own purchase before the subscription of another company. Archived apps can only be downloaded from their own links, and have no trial.
	*/
	var downloadOptions: [DownloadOption] {
		downloadOptions(appStorePlacement: .downloadButton)
	}

	/**
	The download options (``downloadOptions``) with the App Store link of another place on the site, like the box to get the app in a guide, which has the campaign of the guide.
	*/
	func downloadOptions(appStorePlacement: AppStorePlacement) -> [DownloadOption] {
		guard !frontmatter.isArchived else {
			return ownOptions
		}

		let ownOptionsWithTrial = ownOptions + (hasTrial ? [.trial(appPath: path)] : [])

		let appStoreOption = appStoreID.map { DownloadOption.appStore($0, placement: appStorePlacement) }
		let storeOptions = [appStoreOption, frontmatter.setappID.map(DownloadOption.setapp)].compactMap(\.self)

		return appStoreOption == nil ? ownOptionsWithTrial + storeOptions : storeOptions + ownOptionsWithTrial
	}

	/**
	The link to get the app from another site, for apps that are not only on the App Store: the download on GitHub, the purchase on Gumroad, or else the site or the repo of the app.
	*/
	var ownDownloadURL: URL? {
		frontmatter.gitHubDownload?.url ?? gumroadURL ?? frontmatter.redirectURL?.value ?? frontmatter.repositoryURL?.value
	}

	var hasFAQSection: Bool {
		markdown.headings.hasFAQSection
	}

	/**
	The link to the FAQ section of the app page, or `nil` when the app has none.
	*/
	var faqDestination: LinkDestination? {
		hasFAQSection ? .path(path, fragment: App.Section.faq.id) : nil
	}

	/**
	The questions of the FAQ section: its level 3 headings, except the injected feedback question and the added menu bar question, which only links to the general question.
	*/
	var faqHeadings: [Heading] {
		markdown.headings.faqSection.filter { heading in
			heading.level == .h3
				&& heading.id != App.Section.feedbackQuestion.id
				&& heading.id != App.Section.menuBarQuestion.id
		}
	}

	/**
	The tips that the feedback form suggests: the level 3 headings of the “Tips” section that have a custom ID (`{#id}`), like “Batch transcribe” (`#batch`). The owner gives a custom ID to the tips that he links to, so the generic headings, like “Keyboard Shortcuts”, stay out.
	*/
	var tipHeadings: [Heading] {
		markdown.headings.tips
	}

	/**
	The Markdown of the answer of a question of the FAQ section, as it is in the file: the lines up to the next question or section, not to a heading in the answer, without the directives below the question, like `<!-- @faq.keywords … -->`. `nil` for a question that the build adds, which is not in the file.
	*/
	func faqAnswerMarkdown(of question: Heading) -> String? {
		faqAnswerLines(of: question)?
			.map(\.text)
			.joined(separator: "\n")
			.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	/**
	The lines of ``faqAnswerMarkdown(of:)`` with their lines in the file, like for a warning about a line of an answer.
	*/
	func faqAnswerLines(of question: Heading) -> [(line: SiteKit.SourceLocation.Line, text: Substring)]? {
		guard let sourceLine = question.line else {
			return nil
		}

		let bodyLines = file.bodyLines
		let line = sourceLine.rawValue
		let end = markdown.headings.first { $0.level <= .h3 && $0.line.map { $0 > sourceLine } == true }?.line?.rawValue ?? file.bodyStartLine.rawValue + bodyLines.count

		return ((line + 1)..<end)
			.map { (line: SiteKit.SourceLocation.Line($0), text: bodyLines[$0 - file.bodyStartLine.rawValue]) }
			.filter { !$0.text.trimmingPrefix(while: \.isWhitespace).hasPrefix("<!--") }
	}
}

extension [Heading] {
	/**
	Whether the headings have the FAQ section of an app.
	*/
	var hasFAQSection: Bool {
		contains(where: \.isFAQSection)
	}

	/**
	The tips of an app that the feedback form suggests (``App/tipHeadings``). Empty without a “Tips” section, which is found by its ID (``App/Section/tips``), like `## Tips` or `## Tips and Tricks {#tips}`.
	*/
	var tips: [Heading] {
		guard let start = firstIndex(where: { App.Section.tips.isHeading(level: $0.level, id: $0.id) }) else {
			return []
		}

		return contentOfSection(afterHeadingAt: start, level: App.Section.tips.level) { $0.level }
			.filter { $0.level == .h3 && $0.hasCustomID }
	}

	/**
	The headings in the FAQ section of an app, after its level 2 heading and before the next heading of level 2 or less. Empty without a FAQ section.
	*/
	var faqSection: ArraySlice<Heading> {
		guard let start = firstIndex(where: \.isFAQSection) else {
			return []
		}

		return contentOfSection(afterHeadingAt: start, level: App.Section.faq.level) { $0.level }
	}
}

extension Heading {
	/**
	Whether the heading starts the FAQ section of an app.
	*/
	fileprivate var isFAQSection: Bool {
		App.Section.faq.isHeading(level: level, id: id)
	}
}

/**
A place to get an app, or its trial.
*/
enum DownloadOption: Hashable {
	case appStore(AppStoreID, placement: App.AppStorePlacement)
	case setapp(SetappID)

	/**
	A custom download button, like “Download” or “Buy”.
	*/
	case link(LabeledLink)

	/**
	The “Source Code” button, which links to the repo of an open-source app.
	*/
	case sourceCode(AbsoluteURL)

	/**
	The “Free Trial” button, which links to the trial section of the app page at its path, so it also works on another page, like a guide.
	*/
	case trial(appPath: RoutePath)

	/**
	The badge image of a store, like “Download on the App Store”. Custom links are buttons instead.
	*/
	struct Badge {
		static let appStore = Self(imagePath: #path("/assets/download-on-app-store-badge.svg"), label: "Download on the App Store", width: 180)
		static let setapp = Self(imagePath: #path("/assets/download-on-setapp-badge.svg"), label: "Download on Setapp", width: 150)

		let imagePath: RoutePath
		let label: String

		/**
		The width of the image at the height it is shown at, 60px.
		*/
		let width: Int
	}

	/**
	Whether it is a place to get the app, not the “Source Code” or “Free Trial” button.
	*/
	var isPlaceToGet: Bool {
		switch self {
		case .appStore, .setapp, .link:
			true
		case .sourceCode, .trial:
			false
		}
	}

	var url: LinkDestination {
		switch self {
		case .appStore(let id, let placement):
			.url(id.url(placement: placement))
		case .setapp(let id):
			.url(id.referralURL)
		case .sourceCode(let url):
			.url(url)
		case .link(let link):
			link.destination
		case .trial(let appPath):
			.path(appPath, fragment: App.Section.trial.id)
		}
	}
}

extension OrderedMapping<AbsoluteURL> {
	fileprivate var labeledLinks: [LabeledLink] {
		map { title, url in LabeledLink(title, url: url) }
	}
}
