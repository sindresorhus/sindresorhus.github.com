import Elementary
import SiteKit

/**
A line with a fact of this moment, which only the browser of the visitor knows, like “It is ISO week 46 today · November 9 to November 15” on the page of Week Number, or “It is 14:32 UTC now · 15:32 for you (UTC+1)” on the page of UTC Time. Content places it with `@LiveFact(kind: "week-number")`.

The script finds the value from the clock of the visitor, as the site is only built once a night, and updates it each minute. The week is the ISO 8601 week (it starts on Monday, and week 1 has the first Thursday of the year) of the day of the visitor, and the line says so, as the Week Number app follows the calendar settings of the Mac, which a page cannot read. The times are in the 24-hour format.

The line is invisible until the script sets the value, but it keeps its space, so the page does not move when it shows. Without JavaScript, it is not shown, so the page never shows a wrong value.
*/
struct LiveFact: ScriptedElement {
	static let script = ElementScript()

	let kind: Kind

	/**
	What the line shows. The raw value is the value in the content, like `kind: "week-number"`, and the `kind` attribute of the element, which the script reads.
	*/
	enum Kind: String, ContentEnum {
		case weekNumber = "week-number"
		case utcTime = "utc-time"
	}

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.custom(name: "kind", value: kind.rawValue)]
	}

	var content: some HTML {
		// The script changes the value and the detail. Until then, they are texts of about the same length, so the invisible line already has its size.
		p {
			FactLine {
				span {
					"It is "

					strong(.part(Parts.value)) {
						placeholder.value
					}

					placeholder.ending
				}

				span(.part(Parts.detail)) {
					placeholder.detail
				}
			}
			// The detail is on its own line where the two do not fit on one line, like on a phone, so the line does not end with a dot.
			.style {
				$0.below(.smallTablet) {
					$0.stackedFacts()
				}
			}
			// The texts in the HTML are placeholders, so a search engine does not show them. On the `span`, as search engines read the attribute only on a `span`, a `div`, or a `section`.
			.hiddenFromSearchSnippets()
		}
		.style {
			$0
				.monospacedDigit()
				.hiddenWithoutScripting()
		}
	}

	/**
	The texts before the script runs, and the end of the sentence, which the script does not change.
	*/
	private var placeholder: (value: String, ending: String, detail: String) {
		switch kind {
		case .weekNumber:
			("ISO week 00", " today", "September 00 to September 00")
		case .utcTime:
			("00:00 UTC", " now", "00:00 for you (UTC+0)")
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

	static func render(arguments: Self, contentHTML: String, context: MarkdownDocument.Options.BlockDirectiveRenderer.Context) -> String {
		LiveFact(kind: arguments.kind).render()
	}
}
