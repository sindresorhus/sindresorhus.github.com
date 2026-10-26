import Foundation
import SiteKit

extension App {
	static let nonAppStoreVersionTitle = "Non-App Store Version"

	/**
	The ID of the “Non-App Store Version” heading, which is in the “…” menu instead of the links of the app.
	*/
	private static let nonAppStoreVersionID = "non-app-store-version"

	/**
	Links to the sections of the page (level 2 headings).
	*/
	private var sectionLinks: [LabeledLink] {
		markdown.headings
			.filter { $0.level == 2 }
			.map { heading in
				LabeledLink(heading.id == Self.faqSectionID ? "FAQ" : heading.text, destination: .fragment(heading.id))
			}
	}

	/**
	Download buttons: the repo or redirect page as “Learn More”, then the download on GitHub, or the purchase on Gumroad.
	*/
	var mainLinks: [LabeledLink] {
		[
			(frontmatter.redirectURL ?? frontmatter.repositoryURL).map { LabeledLink("Learn More", url: $0) },
			frontmatter.gitHubDownload.map { LabeledLink("Download", url: $0.url) },
			gumroadURL.map { LabeledLink("Buy", url: $0) },
		]
		.compactMap(\.self)
	}

	/**
	The links in the app header: page sections, custom links, the older versions in the readme of the repo, the beta on TestFlight, and support.
	*/
	var links: [LabeledLink] {
		var extraLinks = [LabeledLink]()

		// Apps with `olderVersions` have the “Older Versions” section, which the section links already have.
		if
			!frontmatter.olderMacOSVersions.isEmpty,
			let olderVersionsURL
		{
			extraLinks.append(LabeledLink("Older Versions", url: olderVersionsURL))
		}

		if let testFlightURL = frontmatter.testFlightURL {
			extraLinks.append(LabeledLink("TestFlight", url: testFlightURL))
		}

		if
			frontmatter.showsSupportLink,
			!frontmatter.isArchived
		{
			extraLinks.append(LabeledLink("Support", destination: feedbackURL))
		}

		return sectionLinks
			.filter { $0.destination != .fragment(Self.nonAppStoreVersionID) }
			.merging(frontmatter.links.labeledLinks)
			.merging(extraLinks)
	}

	/**
	The custom overflow links and the “Non-App Store Version” section.
	*/
	var overflowLinks: [LabeledLink] {
		frontmatter.overflowLinks.labeledLinks
			.merging(sectionLinks.filter { $0.destination == .fragment(Self.nonAppStoreVersionID) })
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
		!frontmatter.isArchived && !downloadOptions.isEmpty
	}

	/**
	The places to get the app, in the order they are shown. Archived apps can only be downloaded from their own links.
	*/
	var downloadOptions: [DownloadOption] {
		var options = [DownloadOption]()

		if !frontmatter.isArchived {
			if let appStoreURL = appStoreURL(placement: .downloadButton) {
				options.append(.appStore(appStoreURL))
			}

			if let setappURL {
				options.append(.setapp(setappURL))
			}
		}

		return options + mainLinks.map(DownloadOption.link)
	}

	/**
	The first download link to another site, like GitHub or a store, for apps that are not only on the App Store.
	*/
	var ownDownloadURL: URL? {
		downloadOptions.lazy.compactMap { option in
			guard
				case .link(let link) = option,
				case .url(let url) = link.destination
			else {
				return nil
			}

			return url
		}
		.first
	}

	var hasFAQSection: Bool {
		markdown.headings.hasFAQSection
	}

	/**
	The questions of the FAQ section: its level 3 headings, except the injected feedback question and the added menu bar question, which only links to the general question.
	*/
	var faqHeadings: [Heading] {
		markdown.headings.faqSection.filter { heading in
			heading.level == 3
				&& heading.id != App.feedbackHeadingID
				&& heading.id != App.addedMenuBarQuestionID
		}
	}

	/**
	The Markdown of the answer of a question of the FAQ section, as it is in the file: the lines up to the next question or section, not to a heading in the answer, without the directives below the question, like `<!-- @faq.keywords … -->`. `nil` for a question that the build adds, which is not in the file.
	*/
	func faqAnswerMarkdown(of question: Heading) -> String? {
		guard let line = question.line else {
			return nil
		}

		let bodyLines = file.bodyLines
		let end = markdown.headings.first { $0.level <= 3 && ($0.line ?? 0) > line }?.line ?? file.bodyStartLine + bodyLines.count

		return bodyLines[(line + 1 - file.bodyStartLine)..<(end - file.bodyStartLine)]
			.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("<!--") }
			.joined(separator: "\n")
			.trimmingCharacters(in: .whitespacesAndNewlines)
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

		return self[(start + 1)...].prefix { $0.level > 2 }
	}
}

extension Heading {
	/**
	Whether the heading starts the FAQ section of an app.
	*/
	fileprivate var isFAQSection: Bool {
		level == 2 && id == App.faqSectionID
	}
}

/**
A place to get an app.
*/
enum DownloadOption {
	case appStore(URL)
	case setapp(URL)

	/**
	A custom download button, like “Learn More” for an open-source app.
	*/
	case link(LabeledLink)

	/**
	The badge image of a store, like “Download on the App Store”.
	*/
	struct Badge {
		let imagePath: RoutePath
		let label: String

		/**
		The width of the image at the height it is shown at, 60px.
		*/
		let width: Int
	}

	var url: LinkDestination {
		switch self {
		case .appStore(let url), .setapp(let url):
			.url(url)
		case .link(let link):
			link.destination
		}
	}

	/**
	The badge of a store. Custom links are buttons instead.
	*/
	var badge: Badge? {
		switch self {
		case .appStore:
			Badge(imagePath: "/assets/download-on-app-store-badge.svg", label: "Download on the App Store", width: 180)
		case .setapp:
			Badge(imagePath: "/assets/download-on-setapp-badge.svg", label: "Download on Setapp", width: 150)
		case .link:
			nil
		}
	}
}

extension OrderedMapping<AbsoluteURL> {
	fileprivate var labeledLinks: [LabeledLink] {
		map { title, url in LabeledLink(title, url: url.value) }
	}
}
