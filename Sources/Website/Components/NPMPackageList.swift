import Elementary
import Foundation
import SiteKit

/**
All the npm packages, most downloaded first, each as a row with its name, which links to the package on npm, its description, and its weekly downloads, with a field above them that filters the rows by name and description. JavaScript shows batches of 20, with a button to show more, and filtering searches the whole list. When no package matches, the package with the closest name shows, so a small typo still finds the package, and Enter opens the first package that shows. All the rows are in the HTML, so search engines and visitors without JavaScript see the whole list. Without JavaScript, there is no filter.
*/
struct NPMPackageList: ScriptedElement {
	static let script = ElementScript()

	/**
	The number of packages in a batch. The script has the same number (`#pageSize`).
	*/
	static let pageSize = 20

	/**
	The packages, in the order of the list.
	*/
	let packages: [NPMStatistics.Package]

	init(packages: [NPMStatistics.Package]) {
		// A package without the downloads goes last, as its number is not known.
		self.packages = packages.sorted(using: [KeyPathComparator(\.weeklyDownloads, order: .reverse), KeyPathComparator(\.name, comparator: .localizedStandard)])
	}

	var content: some HTML {
		input(
			.part(Parts.filter),
			.type(.search),
			.placeholder("Filter packages"),
			.autocomplete("off"),
			.spellcheck(false),
			.enterKeyHint(.go)
		)
		.accessibilityLabel("Filter packages")
		.style(FormFieldStyles.control)
		// On the element, so it wins over the display of the field.
		.style {
			$0
				.margin(.bottom, .rootEm(1))
				.hiddenWithoutScripting()
		}

		// The script says how many packages match the filter, or that none does. Between the field and the list, where the eyes are while typing. A polite live region that is always on the page, so screen readers announce the text without interrupting the typing.
		p(.part(Parts.status), .role(.status)) {}
			.style {
				$0
					.margin(top: .zero, horizontal: .zero, bottom: .rootEm(0.5))
					.color(.secondaryText)
			}

		// Keep the list semantics in Safari, as the styles remove its bullets.
		ul(.role(.list)) {
			for package in packages {
				li(.part(Parts.row)) {
					// The name and the description are the text that the filter reads.
					div(.part(Parts.text)) {
						a(.part(Parts.link), .href(.url(package.url)), .notTranslated) {
							package.name
						}
						.style(Styles.name)

						if let description = package.description {
							span {
								description
							}
							.style(Styles.description)
						}
					}

					if let downloads = package.weeklyDownloadsLabel {
						span {
							downloads
						}
						.style(Styles.downloads)
					}
				}
				.style(Styles.row)
			}
		}
		.style(Styles.list)

		button(.part(Parts.showMore), .type(.button), .hidden) {
			"Show more"
		}
		.buttonStyle(.secondary)
		.style {
			$0.margin(.top, .rootEm(1))
		}
	}

	enum Parts: String, ElementPartSet {
		case filter
		case row
		case text
		case link
		case status
		case showMore
	}

	enum Styles: String, ElementStyleSet {
		case root
		case list
		case row
		case name
		case description
		case downloads

		var style: Style {
			switch self {
			case .root:
				// The width of prose, like the introduction of the page, so the eye does not travel far from the name to the downloads on wide screens.
				Style()
					.display(.block)
					.frame(maxWidth: .length(Style.ColumnWidth.prose.maximum))
			case .list:
				// Not `plainList()`, which makes the rows blocks.
				Style()
					.margin(.zero)
					.padding(.zero)
					// Between the shown rows, so the first shown row has no line above it when the filter hides the rows before it.
					.children(":not([hidden]) ~ :not([hidden])") {
						$0.border(.top, .separator)
					}
			case .row:
				// The downloads next to the text from small tablets, and below it on phones. The link of the name covers the row.
				Style()
					.position(.relative)
					.vstack(spacing: .rootEm(0.25))
					.padding(.vertical, .rootEm(0.75))
					.from(.smallTablet) {
						$0
							.flexDirection(.row)
							.alignItems(.baseline)
							.justifyContent(.spaceBetween)
							.gap(.rootEm(1.5))
					}
					// Before the script runs, only the first batch shows, like after it, so the page does not start with all the rows and then jump when the script hides them. The script defines the element, so the element is not defined until then. Without JavaScript, all the rows show. A known limit: when the browser has JavaScript but the script fails to load, only the first batch shows.
					.media(!MediaCondition.scriptingDisabled) {
						$0.nested("\(Self.root.selector):not(:defined) &:nth-child(n + \(raw: String(NPMPackageList.pageSize + 1)))") {
							$0.hidden()
						}
					}
			case .name:
				// Long names, like `@sindresorhus/is`, break anywhere, so they fit a phone. The link covers the row, so the whole row is the link, like the rows of the projects above the list, but its name is only the name of the package.
				Style()
					.fontWeight(.semibold)
					.color(.primaryText)
					.overflowWrap(.anywhere)
					.noUnderline()
					.hoverColor(.link)
					.after {
						$0
							.content("")
							.position(.absolute)
							.inset(.zero)
					}
			case .description:
				// A long list without spaces, like the one of `into-stream` (“string/promise/array/…”), breaks anywhere too.
				Style()
					.display(.block)
					.secondaryText(.body)
					.overflowWrap(.anywhere)
			case .downloads:
				Style()
					.flexShrink(0)
					.secondaryText()
					.monospacedDigit()
			}
		}
	}
}
