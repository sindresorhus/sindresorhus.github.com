import Foundation
import SiteKit

extension App {
	static let nonAppStoreVersionTitle = "Non-App Store Version"

	/**
	The ID of the “Non-App Store Version” heading, which is in the “…” menu instead of the links of the app.
	*/
	static let nonAppStoreVersionID = "non-app-store-version"

	/**
	Links to the sections of the page (level 2 headings).
	*/
	private var sectionLinks: [LabeledLink] {
		markdown.headings
			.filter { $0.level == 2 && $0.id != Heading.footnotesID }
			.map { heading in
				LabeledLink(heading.id == Self.faqSectionID ? "FAQ" : heading.text, destination: .fragment(heading.id))
			}
	}

	/**
	Download buttons: the repo or redirect page as “Learn More”, then the custom links.
	*/
	var mainLinks: [LabeledLink] {
		let learnMore = [frontmatter.repositoryURL, frontmatter.redirectURL]
			.compactMap(\.self)
			.map { LabeledLink("Learn More", url: $0) }

		return [].merging(learnMore).merging(frontmatter.mainLinks.labeledLinks)
	}

	/**
	The links in the app header: page sections, custom links, and support.
	*/
	var links: [LabeledLink] {
		var support = [LabeledLink]()
		if frontmatter.showsSupportLink, !frontmatter.isArchived {
			support.append(LabeledLink("Support", destination: feedbackURL))
		}

		return sectionLinks
			.filter { $0.destination != .fragment(Self.nonAppStoreVersionID) }
			.merging(frontmatter.links.labeledLinks)
			.merging(support)
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
		}

		links.append(.termsOfUse)

		if frontmatter.isPaid {
			links.append(.discounts)
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
		markdown.headings.contains(where: \.isFAQSection)
	}

	/**
	The questions of the FAQ section: its level 3 headings, except the injected feedback question.
	*/
	var faqHeadings: [Heading] {
		guard let start = markdown.headings.firstIndex(where: \.isFAQSection) else {
			return []
		}

		var questions = [Heading]()

		for heading in markdown.headings[(start + 1)...] {
			if heading.level <= 2 {
				break
			}

			if
				heading.level == 3,
				heading.id != App.feedbackHeadingID
			{
				questions.append(heading)
			}
		}

		return questions
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
