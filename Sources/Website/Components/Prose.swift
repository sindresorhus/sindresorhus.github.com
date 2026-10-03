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

	init(variant: Variant = .standard, @HTMLBuilder content: () -> Content) {
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

extension Prose where Content == HTMLRaw {
	/**
	Rendered Markdown.
	*/
	init(html: String, variant: Variant = .standard) {
		self.init(variant: variant) {
			HTMLRaw(html)
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

	/**
	Opts the element and its content out of the prose styles, like components that are not text.
	*/
	case excluded

	case footnotes
	case footnoteReference
	case footnotePopover
	case codeBlock
	case codeBlockBar
	case codeBlockLanguage
	case copyButton
	case keySeparator
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
	case headingAnchor
	case headingAnchorLinkIcon
	case headingAnchorCheckIcon

	/**
	Every style is scoped up to the excluded elements. Scoping them all also makes the closest one win over the prose root, like an alert inside prose, as the nearest scope wins when specificity is equal.
	*/
	var style: Style {
		// `not-prose` is used in the raw HTML of the content.
		definition.scope(excluding: ":is(\(Self.excluded.selector), .not-prose)")
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
		case .excluded:
			Style()
		case .footnotes:
			Self.footnotesStyle
		case .footnoteReference:
			Self.footnoteReferenceStyle
		case .footnotePopover:
			Self.footnotePopoverStyle
		case .codeBlock:
			Self.codeBlockStyle
		case .codeBlockBar:
			Self.codeBlockBarStyle
		case .codeBlockLanguage:
			Self.codeBlockLanguageStyle
		case .copyButton:
			Self.copyButtonStyle
		case .keySeparator:
			Self.keySeparatorStyle
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
		case .headingAnchor:
			Self.headingAnchorStyle
		case .headingAnchorLinkIcon:
			Style()
		case .headingAnchorCheckIcon:
			Self.headingAnchorCheckIconStyle
		}
	}
}

extension MarkdownTheme {
	/**
	The classes of the site's styles for the markup that the Markdown renderer creates.
	*/
	static let site = Self { element in
		// The same class names as in the raw HTML of the content, so both forms look the same.
		switch element {
		case .listSubtitle:
			return "list-subtitle"
		case .listDescription:
			return "list-description"
		default:
			break
		}

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
		case .codeBlock:
			[ProseStyles.codeBlock]
		case .codeBlockBar:
			[ProseStyles.codeBlockBar]
		case .codeBlockLanguage:
			[ProseStyles.codeBlockLanguage]
		case .copyButton:
			[ProseStyles.copyButton]
		case .visuallyHidden:
			[VisuallyHidden.Styles.root]
		case .keySeparator:
			[ProseStyles.keySeparator]
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
		case .headingAnchor:
			[ProseStyles.headingAnchor]
		case .headingAnchorLinkIcon:
			[ProseStyles.headingAnchorLinkIcon]
		case .headingAnchorCheckIcon:
			[ProseStyles.headingAnchorCheckIcon]
		case .listSubtitle, .listDescription:
			[]
		}

		return styles.map(\.className).joined(separator: " ")
	}
}
