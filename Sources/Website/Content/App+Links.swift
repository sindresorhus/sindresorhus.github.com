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
				LabeledLink(heading.id == Section.faq.id ? "FAQ" : heading.text, destination: .fragment(heading.id))
			}
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

			if let releaseNotes {
				links.append(LabeledLink("Release Notes", path: releaseNotes.path))
			}

			links.append(LabeledLink("Privacy Policy", path: privacyPolicyPath))
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
		guard !frontmatter.isArchived else {
			return ownOptions
		}

		let ownOptionsWithTrial = ownOptions + (hasTrial ? [.trial(appPath: path)] : [])

		let appStoreOption = appStoreID.map { DownloadOption.appStore($0, placement: .downloadButton) }
		let storeOptions = [appStoreOption, frontmatter.setappID.map(DownloadOption.setapp)].compactMap(\.self)

		return appStoreOption == nil ? ownOptionsWithTrial + storeOptions : storeOptions + ownOptionsWithTrial
	}

	/**
	The link to get the app from another site, for apps that are not only on the App Store: the download on GitHub, the purchase on Gumroad, or else the site or the repo of the app.
	*/
	var ownDownloadURL: URL? {
		frontmatter.gitHubDownload?.url ?? gumroadURL ?? frontmatter.redirectURL ?? frontmatter.repositoryURL?.value
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
	func faqAnswerLines(of question: Heading) -> [(line: Int, text: Substring)]? {
		guard let line = question.line else {
			return nil
		}

		let bodyLines = file.bodyLines
		let end = markdown.headings.first { $0.level <= .h3 && ($0.line ?? 0) > line }?.line ?? file.bodyStartLine + bodyLines.count

		return ((line + 1)..<end)
			.map { (line: $0, text: bodyLines[$0 - file.bodyStartLine]) }
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
