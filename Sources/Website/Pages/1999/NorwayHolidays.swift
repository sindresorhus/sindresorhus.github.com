import Elementary
import Foundation
import SiteKit

/**
The best week of the year in Norway, as a game: the Easter ski trip (påsketur), where the visitor waxes the skis for the snow of the day, kicks and glides to the cabin before Dad, and eats a Kvikk Lunsj with the mountain code on the wrapper. Its script, `NorwayHolidays.js`, runs it, only while it is on the screen and the tab is visible. With reduced motion, the ski race only goes on for a moment after each kick.
*/
struct GeoCitiesNorwayHolidays: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the window of the ski trip, which the skis in my room lead to.
	*/
	static let skiID = "geocities-ski"

	/**
	The grip waxes of the ski trip, from the hardest, for the coldest snow, by the name that the script knows them by, with the temperatures of new snow that each is for.
	*/
	static let waxes: [(id: String, name: String, range: String, style: Styles)] = [
		("green", "Green", "−15 to −8 °C", .waxGreen),
		("blue", "Blue", "−10 to −2 °C", .waxBlue),
		("violet", "Violet", "−3 to 0 °C", .waxViolet),
		("red", "Red", "0 to +3 °C", .waxRed),
		("klister", "Klister", "wet snow, above 0 °C", .waxKlister),
	]

	var content: some HTML {
		h2 {
			GeoCitiesPage.GIFImage(gif: .norwayFlag, alt: "", style: .gif, project: project)
			" Easter in the Mountains "
			GeoCitiesPage.GIFImage(gif: .norwayFlag, alt: "", style: .gif, project: project)
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"The best week of the year: Easter, when the whole of Norway goes skiing to a cabin in the mountains, with oranges and Kvikk Lunsj in the backpack."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			window("Påsketur: The Easter Ski Trip", id: Self.skiID) {
				skiTrip
			}
		}
		.style(GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The ski trip needs JavaScript. God påske anyway!"
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	let project: Project

	private var skiTrip: some HTML {
		div {
			p(.part(Parts.skiWeather)) {}
				.style(GeoCitiesPage.Styles.lcd)

			div {
				p {
					"1. Wax the skis for the snow of the day:"
				}
				.style(Styles.stepTitle)

				div {
					for wax in Self.waxes {
						button(.type(.button), .hook(Hooks.wax, value: wax.id), .ariaPressed(false)) {
							strong {
								wax.name
							}
							" "
							span {
								wax.range
							}
							.style(Styles.waxRange)
						}
						.style(Styles.wax, wax.style)
					}
				}
				.style(Styles.waxBox)
			}

			GeoCitiesPage.GIFImage(gif: .skier, alt: "A skier on the way down", style: .floating, project: project)

			p {
				"2. Kick and glide to the cabin before Dad: kick with the left and the right ski, one after the other, in a steady rhythm. Too fast, and you fall. Eat a Kvikk Lunsj when you run out of energy."
			}
			.style(Styles.stepTitle)

			canvas(.part(Parts.skiCanvas), .width(400), .height(160), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The ski track to the cabin. Press the left and right arrow keys one after the other to kick, and K to eat a Kvikk Lunsj.")
				.style(Styles.canvas)

			div {
				button(.type(.button), .hook(Hooks.skiControl, value: "left")) {
					"⬅ Left Ski"
				}
				.style(Styles.kick)

				button(.type(.button), .hook(Hooks.skiControl, value: "right")) {
					"Right Ski ➡"
				}
				.style(Styles.kick)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			div {
				button(.part(Parts.skiStart), .type(.button)) {
					"Go!"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.type(.button), .hook(Hooks.skiControl, value: "kvikk")) {
					"🍫 Eat a Kvikk Lunsj"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.skiStatus), .role("status")) {}
				.style(Styles.status)

			// The wrapper of the Kvikk Lunsj has the mountain code on the back, so the script shows a rule of it for each bar.
			p(.part(Parts.skiWrapper), .hidden) {}
				.style(Styles.wrapper)
		}
		.style(Styles.toy)
	}

	/**
	A window of a game, with an ID, which a thing in my room leads to. It can have the focus, so the keyboard goes on from there.
	*/
	private func window(_ title: String, id: String, @HTMLBuilder content: () -> some HTML) -> some HTML {
		section {
			h3 {
				title
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				content()
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.attributes(.id(id), .tabindex(-1))
		.style(GeoCitiesPage.Styles.window)
	}

	enum Parts: String, ElementPartSet {
		case skiWeather
		case skiCanvas
		case skiStart
		case skiStatus
		case skiWrapper
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The grip wax of a button of the wax box, like `blue`.
		*/
		case wax = "data-ski-wax"

		/**
		What a button of the ski trip does: `left`, `right`, or `kvikk`.
		*/
		case skiControl = "data-ski-control"
	}

	enum Styles: ElementStyleSet {
		case root
		case toy
		case canvas
		case status
		case stepTitle
		case waxBox
		case wax
		case waxRange
		case waxGreen
		case waxBlue
		case waxViolet
		case waxRed
		case waxKlister
		case kick
		case wrapper

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .toy:
				Style().vstack(spacing: .rootEm(0.5))
			case .canvas:
				// Big pixels. The game is played with the buttons, so a finger still scrolls the page over the canvas.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.imageRendering(.pixelated)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .stepTitle:
				Style()
					.margin(0)
					.textStyle(.caption, weight: .bold)
			case .waxBox:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
					.margin(top: .rootEm(0.25))
			case .wax:
				// A tube of grip wax, in the color of its tube, with a thick edge while it is on the skis.
				Style()
					.vstack(alignment: .center, spacing: 0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.border(Color("#333333"), width: .pixels(2), style: .outset)
					.cornerRadius(.rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.white)
					.handCursor()
					.when(.state, is: "on") {
						$0
							.border(Color("#ffcc00"), width: .pixels(4), style: .solid)
							.shadow(Shadow(y: 0, blur: .pixels(6), color: Color("#ffcc00")))
					}
			case .waxRange:
				Style().font(size: .rootEm(0.7))
			case .waxGreen:
				Style().background(Color("#1f7a3a"))
			case .waxBlue:
				Style().background(Color("#1f4fa0"))
			case .waxViolet:
				Style().background(Color("#6a2c91"))
			case .waxRed:
				Style().background(Color("#b3122a"))
			case .waxKlister:
				Style()
					.background(Color("#c0c0c0"))
					.color(.black)
			case .kick:
				// Big buttons for the thumbs, for the left and the right ski.
				Style()
					.frame(minWidth: .rootEm(8), minHeight: .rootEm(3))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(.black)
					.touchAction(.manipulation)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
			case .wrapper:
				// The red wrapper of a Kvikk Lunsj, with the mountain code on the back.
				Style()
					.margin(0)
					.padding(.rootEm(0.5))
					.background(Color("#d0021b"))
					.border(Color("#ffffff"), width: .pixels(3), style: .double)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.white)
			}
		}
	}
}
