import Elementary
import SiteKit

/**
Long-form text with typographic styles, like rendered Markdown.

Components inside it keep their own styles, because the prose styles are in an earlier cascade layer.
*/
struct Prose<Content: HTML>: HTML {
	enum Variant {
		case standard

		/**
		A blog post, with colored links and typographic refinements.
		*/
		case article
	}

	let variant: Variant
	let content: Content

	init(variant: Variant = .standard, @ContentBuilder content: () -> Content) {
		self.variant = variant
		self.content = content()
	}

	var body: some HTML {
		div {
			content
		}
		.style(ProseStyles.root)
		.style(ProseStyles.article, when: variant == .article)
	}
}

extension Prose where Content == MarkdownContent {
	/**
	Rendered Markdown, which adds the styles of its block directives to the page.
	*/
	init(markdown: MarkdownContent, variant: Variant = .standard) {
		self.init(variant: variant) {
			markdown
		}
	}
}

/**
The styles of prose and of the markup that the Markdown renderer creates, like alerts and collapsible sections. ``SiteKit/MarkdownTheme/site`` gives the markup these classes.

The styles of each topic are in their own file.
*/
enum ProseStyles: StyleSet {
	case root
	case article

	case footnotes
	case footnoteReference
	case footnotePopover
	case keySeparator
	case tableContainer
	case alert
	case alertNote
	case alertTip
	case alertImportant
	case alertWarning
	case alertCaution
	case alertTitle
	case alertIcon
	case collapsibleSections
	case collapsibleSection
	case collapsibleSummary
	case collapsibleTitle
	case collapsibleChevron
	case collapsibleContent
	case collapsibleMoreLink
	case anchoredHeading
	case anchoredSection
	case headingAnchor
	case headingAnchorLinkIcon
	case headingAnchorCheckIcon
	case listSubtitle
	case listDescription

	/**
	Every style is scoped, so the closest one wins over the prose root, like an alert inside prose, as the nearest scope wins when specificity is equal.
	*/
	var style: Style {
		definition.scoped()
	}

	private var definition: Style {
		switch self {
		case .root:
			Self.typography
				.combined(with: Self.tables)
				.combined(with: Self.spacing)
				.combined(with: Self.keyboardKeys)
		case .article:
			Self.articleStyle
		case .footnotes:
			Self.footnotesStyle
		case .footnoteReference:
			Self.footnoteReferenceStyle
		case .footnotePopover:
			Self.footnotePopoverStyle
		case .keySeparator:
			Self.keySeparatorStyle
		case .tableContainer:
			Self.tableContainerStyle
		case .alert:
			Self.alertStyle
		case .alertNote:
			Self.alertStyle(.note)
		case .alertTip:
			Self.alertStyle(.tip)
		case .alertImportant:
			Self.alertStyle(.important)
		case .alertWarning:
			Self.alertStyle(.warning)
		case .alertCaution:
			Self.alertStyle(.caution)
		case .alertTitle:
			Self.alertTitleStyle
		case .alertIcon:
			Self.alertIconStyle
		case .collapsibleSections:
			Self.collapsibleSectionsStyle
		case .collapsibleSection:
			Self.collapsibleSectionStyle
		case .collapsibleSummary:
			Self.collapsibleSummaryStyle
		case .collapsibleTitle:
			Self.collapsibleTitleStyle
		case .collapsibleChevron:
			Self.collapsibleChevronStyle
		case .collapsibleContent:
			Self.collapsibleContentStyle
		case .collapsibleMoreLink:
			Self.collapsibleMoreLinkStyle
		case .anchoredHeading:
			Self.anchoredHeadingStyle
		case .anchoredSection:
			Self.anchoredSectionStyle
		case .headingAnchor:
			Self.headingAnchorStyle
		case .headingAnchorLinkIcon:
			Style()
		case .headingAnchorCheckIcon:
			Self.headingAnchorCheckIconStyle
		case .listSubtitle:
			Self.listSubtitleStyle
		case .listDescription:
			Self.listDescriptionStyle
		}
	}
}

extension MarkdownTheme {
	/**
	The classes of the site's styles for the markup that the Markdown renderer creates.
	*/
	static let site = Self { element in
		let styles: [any StyleSet] = switch element {
		case .alert(let kind):
			[ProseStyles.alert, kind.style]
		case .alertTitle:
			[ProseStyles.alertTitle]
		case .alertIcon:
			[ProseStyles.alertIcon]
		case .footnotes:
			[ProseStyles.footnotes]
		case .footnoteBackReference:
			[]
		case .footnoteReference:
			[ProseStyles.footnoteReference]
		case .footnotePopover:
			[ProseStyles.footnotePopover]
		case .visuallyHidden:
			[VisuallyHidden.Styles.root]
		case .keySeparator:
			[ProseStyles.keySeparator]
		case .tableContainer:
			[ProseStyles.tableContainer]
		case .collapsibleSections:
			[ProseStyles.collapsibleSections]
		case .collapsibleSection:
			[ProseStyles.collapsibleSection]
		case .collapsibleSummary:
			[ProseStyles.collapsibleSummary]
		case .collapsibleTitle:
			[ProseStyles.collapsibleTitle]
		case .collapsibleChevron:
			[ProseStyles.collapsibleChevron]
		case .collapsibleContent:
			[ProseStyles.collapsibleContent]
		case .collapsibleMoreLink:
			[ProseStyles.collapsibleMoreLink]
		case .anchoredHeading:
			[ProseStyles.anchoredHeading]
		case .anchoredSection:
			[ProseStyles.anchoredSection]
		case .headingAnchor:
			[ProseStyles.headingAnchor]
		case .headingAnchorLinkIcon:
			[ProseStyles.headingAnchorLinkIcon]
		case .headingAnchorCheckIcon:
			[ProseStyles.headingAnchorCheckIcon]
		case .listSubtitle:
			[ProseStyles.listSubtitle]
		case .listDescription:
			[ProseStyles.listDescription]
		}

		return styles.map(\.className).joined(separator: " ")
	}
}
