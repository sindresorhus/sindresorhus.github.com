import Elementary
import SiteKit

/**
A card with a fact of this moment, which only the browser of the visitor knows, like “This week”, “ISO week 46”, and “November 9 to November 15” on the page of Week Number, or “Right now”, “14:32 UTC”, and “Nov 13 in UTC · 15:32 for you (UTC+1)” on the page of UTC Time. Content places it with `@LiveFact(kind: "week-number")`.

The script finds the value from the clock of the visitor, as the site is only built once a night, and updates it each minute. The week is the ISO 8601 week (it starts on Monday, and week 1 has the first Thursday of the year) of the day of the visitor, and the card says so, as the Week Number app follows the calendar settings of the Mac, which a page cannot read. The times are in the 24-hour format.

The card is invisible until the script sets the value, but it keeps its space, so the page does not move when it shows. Without JavaScript, it is not shown, so the page never shows a wrong value.
*/
struct LiveFact: ScriptedElement {
	static let script = ElementScript()

	let kind: Kind

	/**
	What the card shows. The raw value is the value in the content, like `kind: "week-number"`, and the `kind` attribute of the element, which the script reads.
	*/
	enum Kind: String, ContentEnum {
		case weekNumber = "week-number"
		case utcTime = "utc-time"
	}

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.custom(name: "kind", value: kind.rawValue)]
	}

	var content: some HTML {
		// A card like the numbers of the now page (``StatCard``): a label, the value, and the detail, each on its own line. The script changes the value and the detail. Until then, they are texts of about the same length, so the invisible card already has its size.
		// The spaces are for copied text and screen readers. The stack does not show them.
		p {
			span {
				label
			}
			.style {
				$0
					.textStyle(.caption)
					.secondaryText()
			}

			" "

			// The texts in the HTML are placeholders, so a search engine does not show them. On a `span`, as search engines read the attribute only on a `span`, a `div`, or a `section`.
			span(.part(Parts.value)) {
				placeholder.value
			}
			.hiddenFromSearchSnippets()
			.style(StatCard.Styles.value)
			// The colon of a time is centered on the digits, like on a clock (stylistic set 3 of SF Pro and SF Pro Rounded). The other values have no colon.
			.style {
				$0.fontFeatures(.stylisticSet(3))
			}

			" "

			span(.part(Parts.detail)) {
				placeholder.detail
			}
			.hiddenFromSearchSnippets()
			.style {
				$0
					.textStyle(.caption)
					.secondaryText()
			}
		}
		.style {
			$0
				.vstack(spacing: .rootEm(0.125))
				.plainCard()
				.monospacedDigit()
				.hiddenWithoutScripting()
				// From tablets, only as wide as its text, with more space at the end, so it reads as one fact, not as a wide box around a short line. On phones, it is as wide as the text.
				.from(.smallTablet) {
					$0
						.frame(width: .fitContent)
						.padding(.trailing, .rootEm(4))
				}
		}
	}

	/**
	What the card is about, above the value.
	*/
	private var label: String {
		switch kind {
		case .weekNumber:
			"This week"
		case .utcTime:
			"Right now"
		}
	}

	/**
	The texts before the script runs.
	*/
	private var placeholder: (value: String, detail: String) {
		switch kind {
		case .weekNumber:
			("ISO week 00", "September 00 to September 00")
		case .utcTime:
			("00:00 UTC", "Sep 00 in UTC · 00:00 for you (UTC+00:00)")
		}
	}

	enum Parts: String, ElementPartSet {
		case value
		case detail
	}

	enum States: String, ElementStateSet {
		case shown
	}

	enum Styles: String, ElementStyleSet {
		case root

		var style: Style {
			switch self {
			case .root:
				// The paragraph is laid out as if the element were not there. It is invisible until the script sets the value, and the paragraph inherits it.
				Style()
					.display(.contents)
					.visibility(false)
					.when(States.shown) {
						$0.visibility(true)
					}
			}
		}
	}
}

/**
The arguments of `@LiveFact(kind: "week-number")`.
*/
@Frontmatter
struct LiveFactArguments {
	var kind: LiveFact.Kind
}

/**
A fact of this moment from the browser of the visitor (``LiveFact``), like `@LiveFact(kind: "utc-time")`. It has no content, and the Markdown copy of the page leaves it out, as a text file cannot show the value.
*/
extension LiveFactArguments: BlockDirectiveDefinition {
	typealias Arguments = Self
	static let name = BlockDirectiveName.liveFact.rawValue
	static let content = MarkdownDocument.Options.BlockDirectiveRenderer.Content.empty

	static func render(arguments: Self, content: HTMLFragment, context: MarkdownDocument.Options.BlockDirectiveRenderer.Context) -> HTMLFragment {
		LiveFact(kind: arguments.kind).renderFragment()
	}
}
