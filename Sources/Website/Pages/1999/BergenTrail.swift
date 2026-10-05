import Elementary
import Foundation
import SiteKit

/**
The Bergen Trail, a game like The Oregon Trail of MECC, which every school had on the Apple II: the summer car trip of my family in Pappa’s old Volvo 240, from Bergen to Nordkapp, the long way, on a black Apple II screen with chunky white and green letters and little pixel pictures in the six colors of the Apple II. The visitor picks the job of Pappa (a banker from Bergen with much money, a fisherman from Askøy who fishes better, or a teacher from Fana who keeps the kids from boredom, for two or three times the points), edits the names of the family, and picks the month to start in: June has the midnight sun, July has the common holiday when all of Norway is in the ferry queue, and September has rain. At Rimi in Bergen, the visitor buys brown cheese, matpakke bread, Kvikk Lunsj, petrol money, spare tires, a road map, and mosquito spray, where Kjell at the counter has already put his advice in the basket, so the visitor can change it or just pay. On the trail, the Volvo drives across mountains, fjords, and the tundra of Finnmark (one picture for each day with reduced motion), with the date, the weather, the health, the food, the next landmark, and how many times Lillesøster has asked “Er vi fremme snart?” The visitor sizes up the situation to change the pace and the food rations, rest, look at a map of Norway with the route, check the supplies, go fishing, talk to people, and buy food on the way, at higher prices the farther north. The landmarks are real places, each with a pixel picture and a short text: Voss, Geiranger, Trondheim, the Arctic Circle Centre, Lofoten, Tromsø, Alta, and Nordkapp. The rivers of the original are ferry crossings: wait in the queue for hours, drive up the ramp as it lifts, drive around the fjord for days, or ask the ferry man; and the new Nordkapp tunnel opens on 15 June 1999. Random events of a Norwegian car trip happen on the way: sheep, a moose, reindeer, a flat tire, a tunnel with no lights, a lost shoe, Mormor’s churches, the cassette player that eats the tape, the mosquitoes of Finnmark, the midnight sun, a Swedish caravan, and the police. Fishing replaces hunting, with a float that goes under and a quick hand, and the classic note that only 10 kg fits in the car. Nobody dies: they get carsickness or a sunburn, and at worst die of boredom, get a small gravestone, and come back. When a trip fails, the visitor writes the epitaph on its gravestone, which the browser keeps and the next trip passes on the road. At Nordkapp, the score counts the health of the family, the supplies, and the money, times the job of Pappa, with the ranks of the original (Trail Guide, Adventurer, Greenhorn) and a Top Ten in the browser. The trip is saved in the browser, so it goes on after a reload. Its script, `BergenTrail.js`, runs it. Without scripts, the trail is left out.
*/
struct GeoCitiesBergenTrail: ScriptedElement {
	static let script = ElementScript()

	var content: some HTML {
		h2 {
			"The Bergen Trail"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Every summer, Pappa says we will drive to Nordkapp “the long way”. We play The Oregon Trail on the Apple II at school, so I made it about us. In the real one, you die of dysentery. In mine, you can only die of boredom."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		monitor

		div {
			button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
				"🔇 Sound Off"
			}
			.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

			button(.part(Parts.restart), .type(.button)) {
				"Start a New Trip"
			}
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(GeoCitiesPage.Styles.buttonRow, Styles.controls, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.status), .role("status")) {}
			.style(Styles.status, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The Bergen Trail needs JavaScript. You have died of no JavaScript."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.tabindex(-1)]
	}

	private var monitor: some HTML {
		div {
			div(.part(Parts.monitor)) {
				canvas(.part(Parts.canvas), .width(280), .height(160), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The picture of the trip. Press Enter or Space for the main choice of the screen: to continue, to stop the car and size up the situation (or with reduced motion, to drive on for a day), and while fishing, to pull the line when the float goes under. The number keys pick a choice, and Escape keeps the trip when “Start a New Trip” asks.")
					.style(Styles.canvas)

				div(.part(Parts.screen)) {}
					.style(Styles.screen)

				p {
					span(.part(Parts.prompt)) {}
					span {
						"_"
					}
					.style(GeoCitiesPage.Styles.blinkingCursor)
				}
				.accessibilityHidden()
				.style(Styles.prompt)
			}
			.style(Styles.glass)

			p {
				"Monitor ]["
			}
			.accessibilityHidden()
			.style(Styles.badge)
		}
		.style(Styles.bezel, GeoCitiesPage.Styles.scriptingOnly)
	}

	enum Parts: String, ElementPartSet {
		case monitor
		case canvas
		case screen
		case prompt
		case sound
		case restart
		case status
	}

	/**
	The white, green, and black of the Apple II.
	*/
	private static let green = Color("#14f53c")

	enum Styles: ElementStyleSet {
		case root
		case bezel
		case glass
		case canvas
		case screen
		case prompt
		case badge
		case controls
		case toggle
		case status

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .bezel:
				// The beige plastic of a monitor of the time, around the black glass.
				Style()
					.frame(maxWidth: .rootEm(38))
					.margin(.horizontal, .auto)
					.padding(top: .rootEm(1), horizontal: .rootEm(1), bottom: .rootEm(0.25))
					.background(Color("#d6ccb0"))
					.border(Color("#ece4cc"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(1))
					.below(.smallTablet) {
						$0.padding(top: .rootEm(0.5), horizontal: .rootEm(0.5), bottom: .rootEm(0.125))
					}
			case .glass:
				// The black screen, with letters that glow a little, like on a tube.
				Style()
					.padding(.rootEm(0.75))
					.background(.black)
					.cornerRadius(.rootEm(0.75))
					.shadow(Shadow(y: 0, blur: .pixels(14), spread: .pixels(2), color: Color("#000000aa"), isInset: true))
					.fontFamily(#""Monaco", "Lucida Console", "Courier New", monospace"#)
					.font(size: .rootEm(1), lineHeight: 1.35)
					.color(.white)
					.textShadow(Shadow(y: 0, blur: .pixels(3), color: Color("#ffffff66")))
					.below(.smallTablet) {
						$0
							.padding(.rootEm(0.5))
							.font(size: .rootEm(0.9375), lineHeight: 1.35)
					}
			case .canvas:
				// Big pixels, and a tap pulls the fishing line at once, without the wait for a double tap.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(280.0 / 160.0)
					.imageRendering(.pixelated)
					.background(.black)
					.touchAction(.manipulation)
					.focusVisible {
						$0.focusRing(GeoCitiesBergenTrail.green, width: .pixels(2), offset: .pixels(2))
					}
			case .screen:
				// The script writes the text of each screen with these elements: headings in green, bold words in green, inverse words like the Apple II, numbered menus, tables, and fields.
				Style()
					.frame(minHeight: .rootEm(14))
					.margin(.top, .rootEm(0.5))
					.overflowWrap(.breakWord)
					.children("h3") {
						$0
							.margin(vertical: .rootEm(0.25), horizontal: 0)
							.textAlign(.center)
							.font(size: .rootEm(1), lineHeight: 1.35)
							.fontWeight(.bold)
							.color(GeoCitiesBergenTrail.green)
					}
					.children("p") {
						$0.margin(vertical: .rootEm(0.25), horizontal: 0)
					}
					.children("p b") {
						$0.color(GeoCitiesBergenTrail.green)
					}
					.children("p strong") {
						$0
							.padding(vertical: 0, horizontal: .rootEm(0.25))
							.background(.white)
							.color(.black)
							.textShadow()
					}
					.children("ol") {
						$0
							.vstack(spacing: .rootEm(0.125))
							.margin(vertical: .rootEm(0.5), horizontal: 0)
							.padding(0)
					}
					.children("ol > li > button") {
						$0
							.display(.block)
							.frame(width: .percent(100), minHeight: .rootEm(2.25))
							.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
							.background(.black)
							.border(.black, width: 0)
							.textAlign(.leading)
							.inheritsFont()
							.color(.white)
							.handCursor()
							.hover {
								$0
									.background(.white)
									.color(.black)
									.textShadow()
							}
							.focusVisible {
								$0
									.background(.white)
									.color(.black)
									.textShadow()
									.focusRing(GeoCitiesBergenTrail.green, width: .pixels(2), offset: .pixels(1))
							}
					}
					.children("table") {
						// Smaller letters on a phone, so the prices of the store fit next to the buttons without breaking into many lines.
						$0
							.frame(width: .percent(100))
							.margin(vertical: .rootEm(0.25), horizontal: 0)
							.below(.smallTablet) {
								$0.font(size: .rootEm(0.8125), lineHeight: 1.3)
							}
					}
					.children("table th") {
						$0
							.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.25))
							.textAlign(.leading)
							.fontWeight(.regular)
							.color(GeoCitiesBergenTrail.green)
					}
					.children("table td") {
						$0.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.25))
					}
					.children("table td > div") {
						$0
							.hstack(alignment: .center, spacing: .rootEm(0.25))
							.textWrap(.nowrap)
					}
					// Room for four digits, so the + buttons stay in one column.
					.children("table td > div > span") {
						$0
							.frame(minWidth: .em(2.5))
							.textAlign(.center)
					}
					.children("table button") {
						$0
							.frame(minWidth: .rootEm(2.25), minHeight: .rootEm(2.25))
							.background(.black)
							.border(GeoCitiesBergenTrail.green, width: .pixels(2))
							.inheritsFont()
							.color(GeoCitiesBergenTrail.green)
							.handCursor()
							.hover {
								$0
									.background(GeoCitiesBergenTrail.green)
									.color(.black)
							}
							.focusVisible {
								$0
									.background(GeoCitiesBergenTrail.green)
									.color(.black)
							}
					}
					.children("form") {
						$0.vstack(alignment: .start, spacing: .rootEm(0.375))
					}
					.children("form label") {
						$0.display(.block)
					}
					.children("form input") {
						$0
							.frame(width: .percent(100), maxWidth: .rootEm(20))
							.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
							.background(.black)
							.border(GeoCitiesBergenTrail.green, width: .pixels(2))
							.inheritsFont()
							// At least 16 pixels, so a phone does not zoom in when the field gets the focus.
							.font(size: .rootEm(1))
							.color(.white)
							.focusVisible {
								$0.focusRing(.white, width: .pixels(2), offset: .pixels(1))
							}
					}
			case .prompt:
				Style()
					.frame(minHeight: .lineHeight(1))
					.margin(top: .rootEm(0.25), horizontal: 0, bottom: 0)
					.color(GeoCitiesBergenTrail.green)
			case .badge:
				// The name plate on the beige plastic below the glass.
				Style()
					.margin(vertical: .rootEm(0.25), horizontal: 0)
					.textAlign(.trailing)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#7a705a"))
			case .controls:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.margin(.top, .rootEm(0.5))
			case .toggle:
				Style().when(.state, is: "on") {
					$0.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
				}
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.textAlign(.center)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			}
		}
	}
}
