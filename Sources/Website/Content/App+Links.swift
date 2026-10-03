import Foundation
import SiteKit

extension App {
	private static let nonAppStoreVersionTitle = "Non-App Store Version"

	/**
	Computes the links and the FAQ questions once, when the app loads, as pages use them many times.
	*/
	mutating func computeDerivedData() {
		mainLinks = computedMainLinks
		links = computedLinks
		overflowLinks = computedOverflowLinks
		pageOverflowLinks = computedPageOverflowLinks
		downloadOptions = computedDownloadOptions
		faqHeadings = computedFAQHeadings
	}

	/**
	Links to the sections of the page (level 2 headings).
	*/
	private var sectionLinks: [LabeledLink] {
		markdown.headings
			.filter { $0.level == 2 && $0.text != "Footnotes" }
			.map { heading in
				LabeledLink(heading.text == Self.faqHeadingTitle ? "FAQ" : heading.text, destination: .fragment(heading.id))
			}
	}

	/**
	Download buttons: the repo or redirect page as “Learn More”, then the custom links.
	*/
	private var computedMainLinks: [LabeledLink] {
		let learnMore = [frontmatter.repositoryURL, frontmatter.redirectURL]
			.compactMap(\.self)
			.map { LabeledLink("Learn More", url: $0.url) }

		return [].merging(learnMore).merging(frontmatter.mainLinks.labeledLinks)
	}

	/**
	The links in the app header: page sections, custom links, and support.
	*/
	private var computedLinks: [LabeledLink] {
		var support = [LabeledLink]()
		if frontmatter.showsSupportLink, !frontmatter.isArchived {
			support.append(LabeledLink("Support", path: RoutePath(feedbackPath)))
		}

		return sectionLinks
			.filter { $0.title != Self.nonAppStoreVersionTitle }
			.merging(frontmatter.links.labeledLinks)
			.merging(support)
	}

	/**
	The custom overflow links and the “Non-App Store Version” section.
	*/
	private var computedOverflowLinks: [LabeledLink] {
		frontmatter.overflowLinks.labeledLinks
			.merging(sectionLinks.filter { $0.title == Self.nonAppStoreVersionTitle })
	}

	/**
	The overflow links plus the standard pages about the app.
	*/
	private var computedPageOverflowLinks: [LabeledLink] {
		var links = computedOverflowLinks

		if !frontmatter.isArchived {
			if let appStoreURL = appStoreURL(placement: "whats-new") {
				links.append(LabeledLink("What's New", url: appStoreURL))
			}

			if let releaseNotes {
				links.append(LabeledLink("Release Notes", path: releaseNotes.path))
			}

			links.append(LabeledLink("Privacy Policy", path: privacyPolicyPath))
		}

		links.append(LabeledLink("Terms of Use", path: "/apps/terms"))

		if frontmatter.isPaid {
			links.append(LabeledLink("Discounts", path: "/apps/discounts"))
		}

		return links
	}

	/**
	The places to get the app, in the order they are shown. Archived apps can only be downloaded from their own links.
	*/
	private var computedDownloadOptions: [DownloadOption] {
		var options = [DownloadOption]()

		if !frontmatter.isArchived {
			if let appStoreURL = appStoreURL(placement: "download-button") {
				options.append(.appStore(appStoreURL))
			}

			if let setappURL {
				options.append(.setapp(setappURL))
			}
		}

		return options + computedMainLinks.map(DownloadOption.link)
	}

	public var hasFAQSection: Bool {
		markdown.headings.contains { $0.level == 2 && $0.text == Self.faqHeadingTitle }
	}

	/**
	The questions of the FAQ section: level 4 headings that are not in a level 3 subsection, except the injected feedback question.
	*/
	private var computedFAQHeadings: [Heading] {
		guard let start = markdown.headings.firstIndex(where: { $0.level == 2 && $0.text == Self.faqHeadingTitle }) else {
			return []
		}

		var questions = [Heading]()

		for heading in markdown.headings[(start + 1)...] {
			if heading.level == 2 {
				break
			}

			if heading.level == 3 {
				return questions
			}

			if heading.level == 4, heading.id != App.feedbackHeadingID {
				questions.append(heading)
			}
		}

		return questions
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

	var url: String {
		switch self {
		case .appStore(let url), .setapp(let url):
			url.absoluteString
		case .link(let link):
			link.href
		}
	}
}

extension OrderedMapping<AbsoluteURL> {
	fileprivate var labeledLinks: [LabeledLink] {
		map { LabeledLink($0.key, url: $0.value.url) }
	}
}
