import Elementary
import Foundation
import SiteKit

/**
My Furby, the one Mamma queued for in the rain outside a toy store in Bergen in December 1998, drawn and alive on a canvas: it blinks with real eyelids, wiggles its ears, moves its beak when it talks, and looks around when nobody plays with it. It talks Furbish, with real Furbish words like “u-nye loo-lay doo?” and “kah a-tay”, in speech bubbles and in a squeaky voice once the sound is on, and the more the visitor plays with it, the more English it mixes in, like the real one, while a Furbish–English dictionary fills in with each word it says. It has the sensors of the real one: a stroke of its back pets it, a poke in the tummy tickles it, a press on the tongue feeds it a waffle (too many make it burp, then sick), it can be turned upside down and shaken, a clap wakes it, and the light sensor makes it scared and sleepy in the dark, where it asks for a hug. It gets hungry, sleepy, and sick, which a spoon of tran cures, and it complains at the worst times. It dances and sings to its own song and to any music of the page. Lillesøster’s Furby can come over, and the two chatter by infrared, sing together, and sneeze at each other. At bedtime, the clock runs to 3 in the morning, when it wakes the whole house, and nothing stops it but taking out the batteries with Pappa’s tiny screwdriver. It has a name and an age in days, and an NSA mode for the myth of 1999 that it could record secrets. Its script, `Furby.js`, runs it, and keeps it in the browser. For visitors who prefer reduced motion, it holds still and changes its face only when the visitor does something.
*/
struct GeoCitiesFurby: ScriptedElement {
	static let script = ElementScript()

	/**
	The buttons of the Furby, by what they do in the script, with their labels, in groups.
	*/
	private static let sensorButtons: [(Parts, String)] = [
		(.feed, "Feed It a Waffle"),
		(.tickle, "Tickle Its Tummy"),
		(.pet, "Pet Its Back"),
		(.flip, "Turn It Upside Down"),
		(.shake, "Shake It"),
		(.clap, "Clap!"),
	]

	private static let houseButtons: [(Parts, String)] = [
		(.light, "Turn Off the Light"),
		(.medicine, "Give It a Spoon of Tran"),
		(.music, "Play Music"),
		(.sister, "Borrow Lillesøster’s Furby"),
		(.chat, "Make Them Chat"),
	]

	private static let nightButtons: [(Parts, String)] = [
		(.bed, "Go to Bed"),
		(.batteries, "Take Out the Batteries"),
		(.nsa, "NSA Mode"),
		(.sound, "Sound: Off"),
	]

	/**
	The fur colors of the Furby, by their IDs in the script.
	*/
	private static let furs = [
		("owl", "Brown and white, like an owl"),
		("snow", "Snow white"),
		("leopard", "Leopard spots"),
		("bat", "Black as a bat"),
		("wolf", "Gray, like a wolf"),
	]

	var content: some HTML {
		h2 {
			"My Furby"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"I got a Furby for Christmas 1998! Mamma stood in the rain outside the toy store in Bergen for two hours to get the very last one. It only speaks Furbish, but the more you play with it, the more English it learns. Stroke its back, tickle its tummy, and press its tongue to feed it. Do "
			strong {
				"not"
			}
			" take it to bed."
		}

		div {
			div {
				div {
					canvas(.part(Parts.canvas), .width(480), .height(360), .tabindex(0), .role("application")) {}
						.accessibilityLabel("My Furby. Stroke its back to pet it, press its tummy to tickle it, and its tongue to feed it. Or use the keys: F feeds, T tickles, P pets, U turns it upside down, S shakes, C claps, L turns the light off or on, and M plays music.")
						.style(Styles.canvas)

					p(.part(Parts.status), .role("status")) {}
						.style(Styles.status)

					div {
						buttonGroup("Its sensors", buttons: Self.sensorButtons)
						buttonGroup("My room", buttons: Self.houseButtons)
						buttonGroup("At night", buttons: Self.nightButtons)
					}
					.style(Styles.controls)
				}
				.style(Styles.stage)

				div {
					p(.part(Parts.lcd)) {}
						.style(GeoCitiesPage.Styles.lcd, Styles.lcd)

					div {
						label {
							"Its name: "
							input(.part(Parts.name), .type(.text), .maxlength(16), .autocomplete("off"), .placeholder("Tee-Loo"))
								.style(GeoCitiesPage.Styles.field, Styles.nameField)
						}
						.style(Styles.label)

						label {
							"Its fur: "
							select(.part(Parts.fur)) {
								for (value, title) in Self.furs {
									Elementary.option(.value(value)) {
										title
									}
								}
							}
							.style(GeoCitiesPage.Styles.select)
						}
						.style(Styles.label)
					}
					.style(Styles.fields)

					details {
						summary {
							"Furbish–English dictionary ("
							span(.part(Parts.dictionaryCount)) {
								"0"
							}
							" words heard)"
						}
						.style(Styles.summary)

						dl(.part(Parts.dictionaryList)) {}
							.style(Styles.dictionary)
					}
					.style(Styles.dictionaryCard)

					div(.part(Parts.nsaBox), .hidden) {
						p {
							"TOP SECRET: what my Furby has recorded for the NSA"
						}
						.style(Styles.nsaTitle)

						ol(.part(Parts.nsaLog)) {}
							.style(Styles.nsaLog)
					}
					.style(Styles.nsa)
				}
				.style(Styles.panel)
			}
			.style(Styles.layout)
		}
		.style(GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My Furby needs JavaScript. And four AA batteries."
		}
		.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	A small heading and its row of buttons, each with what it does in the script.
	*/
	private func buttonGroup(_ title: String, buttons: [(Parts, String)]) -> some HTML {
		div {
			p {
				title
			}
			.style(Styles.groupTitle)

			div {
				for (part, label) in buttons {
					button(.type(.button), .part(part)) {
						label
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.button)
				}
			}
			.style(Styles.buttons)
		}
		.style(Styles.group)
	}

	/**
	The elements that the script uses. Each button is the part with the name of what it does, like `feed`.
	*/
	enum Parts: String, ElementPartSet {
		case canvas
		case status
		case lcd
		case name
		case fur
		case dictionaryList
		case dictionaryCount
		case nsaBox
		case nsaLog
		case feed
		case tickle
		case pet
		case flip
		case shake
		case clap
		case light
		case medicine
		case music
		case sister
		case chat
		case bed
		case batteries
		case nsa
		case sound
	}

	enum Styles: ElementStyleSet {
		case root
		case layout
		case controls
		case stage
		case canvas
		case status
		case panel
		case group
		case groupTitle
		case buttons
		case button
		case lcd
		case fields
		case label
		case nameField
		case dictionaryCard
		case summary
		case dictionary
		case nsa
		case nsaTitle
		case nsaLog

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .layout:
				// The Furby and its buttons get most of the width, and its screen and dictionary sit next to it, or below the buttons on a phone, so the buttons stay close to the Furby.
				Style()
					.hstack(alignment: .start, spacing: .rootEm(1))
					.flexWrap()
			case .controls:
				Style().vstack(spacing: .rootEm(0.5))
			case .stage:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.flex(3)
					.frame(minWidth: .rootEm(20))
			case .canvas:
				// A finger on the wall or the floor scrolls the page. A finger on the Furby strokes and tickles it, as the script stops the scroll there.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(480.0 / 360.0)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.background(Color("#9fd3e6"))
					.touchAction(.manipulation)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .status:
				Style()
					.frame(minHeight: .lineHeight(3))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .panel:
				Style()
					.vstack(spacing: .rootEm(0.625))
					.flex(1)
					.frame(minWidth: .rootEm(13))
			case .group:
				Style().vstack(spacing: .rootEm(0.25))
			case .groupTitle:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(Color("#800080"))
			case .buttons:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .button:
				// Big enough for a finger. The batteries button is yellow while the Furby wakes the house, as nothing else helps.
				Style()
					.frame(minHeight: .rootEm(2))
					.disabled {
						$0.opacity(0.5)
					}
					.when(.state, is: "on") {
						$0
							.background(.white)
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
					.when(.state, is: "urgent") {
						$0
							.background(Color("#ffff00"))
							.color(Color("#cc0000"))
					}
			case .lcd:
				// The lines of the screen, like “TUMMY ███░░”.
				Style()
					.margin(0)
					.preservesLineBreaks()
					.textStyle(.caption, weight: .bold)
			case .fields:
				Style().vstack(spacing: .rootEm(0.375))
			case .label:
				Style()
					.display(.block)
					.textStyle(.caption, weight: .bold)
			case .nameField:
				Style().frame(width: .rootEm(9))
			case .dictionaryCard:
				// A card from the box of the Furby, where the words fill in as it says them.
				Style()
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.625))
					.background(Color("#fffbe0"))
					.border(Color("#c0a000"), width: .pixels(2), style: .dashed)
			case .summary:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.handCursor()
			case .dictionary:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.125))
					.margin(.top, .rootEm(0.375))
					.textStyle(.caption)
					.children("dt") {
						$0.fontFamily(GeoCitiesPage.courier).fontWeight(.bold)
					}
					.children("dd") {
						$0.margin(0)
					}
			case .nsa:
				// A page from a typewriter, stamped secret.
				Style()
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.625))
					.background(.white)
					.border(Color("#cc0000"), width: .pixels(3), style: .double)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
			case .nsaTitle:
				Style()
					.margin(0)
					.fontWeight(.bold)
					.color(Color("#cc0000"))
			case .nsaLog:
				Style()
					.margin(0)
					.padding(.leading, .rootEm(1.25))
			}
		}
	}
}
