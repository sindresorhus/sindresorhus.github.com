import Elementary
import SiteKit

/**
A checklist for the Y2K survival kit, like the ones in the newspapers of late 1999, which grades the visitor on a report card when they hand it in. Some things on the list help, and some do not. Its script, `Y2KKit.js`, adds up the points.
*/
struct GeoCitiesY2KKit: ScriptedElement {
	static let script = ElementScript()

	/**
	The things on the checklist, with their points.
	*/
	private static let items: [(text: String, points: Int)] = [
		("20 gallons of bottled water", 15),
		("Canned beans. A lot of canned beans.", 15),
		("Cash under the mattress, as the banks will forget my money", 15),
		("A flashlight, and batteries for it", 10),
		("Printed out the whole Internet, just in case", 10),
		("Wrote down the ICQ numbers of my friends on paper", 10),
		("Backed up my Tamagotchi on a floppy disk", 5),
		("Unplugged the toaster (it has a chip in it)", 5),
		("Told Glitter to stay away from computers on New Year’s Eve", 5),
		("Set the clock of the VCR to 1900, so it is ready", -10),
		("Sold my computer to buy more canned beans", -15),
		("Plan to be in an elevator at midnight", -25),
	]

	var content: some HTML {
		h2 {
			"Y2K Survival Kit"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"The year 2000 is almost here! The computers may think it is 1900. Are you ready? Check what you have, and hand it in for your grade."
		}

		form(.part(Parts.form)) {
			fieldset {
				legend {
					"My Y2K kit:"
				}
				.style(GeoCitiesPage.Styles.label)

				for item in Self.items {
					label {
						input(.type(.checkbox), .hook(Hooks.points, value: "\(item.points)"))
						span {
							item.text
						}
					}
					.style(Styles.item)
				}
			}
			.style(Styles.list)

			button(.type(.submit)) {
				"Hand It In"
			}
			.style(GeoCitiesPage.Styles.retroButton, GeoCitiesPage.Styles.scriptingOnly)

			div(.part(Parts.card), .role("status"), .hidden) {
				p(.part(Parts.grade)) {}
					.style(Styles.grade)

				div {
					p {
						"Report card"
					}
					.style(Styles.cardTitle)

					p(.part(Parts.comment)) {}
						.style(Styles.comment)
				}
			}
			.style(Styles.card)
		}
		.style(GeoCitiesPage.Styles.form)

		p {
			"Grading needs JavaScript. Grade yourself: if you have canned beans, you pass."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case form
		case card
		case grade
		case comment
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The points of a thing on the checklist.
		*/
		case points = "data-y2k-points"
	}

	enum Styles: ElementStyleSet {
		case root
		case list
		case item
		case card
		case cardTitle
		case grade
		case comment

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .list:
				// A checklist on lined paper.
				Style()
					.vstack(spacing: .rootEm(0.25))
					.frame(width: .percent(100))
					.margin(0)
					.padding(.rootEm(0.75))
					.background(Color("#fffff0"))
					.border(Color("#808080"), width: .pixels(2), style: .groove)
			case .item:
				Style()
					.hstack(alignment: .start, spacing: .rootEm(0.5))
					.padding(.bottom, .rootEm(0.25))
					.border(.bottom, Color("#aaccee"))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body)
					.children("input") {
						$0
							.flexShrink(0)
							.margin(.top, .rootEm(0.3))
					}
			case .card:
				// A report card, with the grade in red pen.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(1))
					.frame(width: .percent(100))
					.padding(.rootEm(1))
					.background(Color("#fdf5e6"))
					.border(Color("#996633"), width: .pixels(3), style: .double)
					.rotationEffect(.degrees(-1))
			case .cardTitle:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.caption, weight: .bold)
					.textCase(.uppercase)
					.letterSpacing(.em(0.2))
			case .grade:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.flexShrink(0)
					.font(size: .rootEm(4), lineHeight: 1)
					.fontWeight(.bold)
					.color(Color("#dd0000"))
					.rotationEffect(.degrees(-8))
			case .comment:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.color(Color("#dd0000"))
			}
		}
	}
}
