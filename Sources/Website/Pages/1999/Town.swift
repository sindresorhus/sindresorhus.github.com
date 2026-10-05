import Elementary
import Foundation
import SiteKit

/**
SimSindreville 2000, a little town on a strip of land between the mountains of Bergen and the road, like SimCity and SimTower of Maxis. The visitor is the mayor: builds houses, a waffle café, an Internet café, a stave church, a park, and a GeoCities tower that grows a floor for each click, with an elevator. The taxes of the people pay for it, also while the visitor is away. Day and night follow the clock of the visitor, it rains like in Bergen (a button stops it for a moment), cars drive by and honk when clicked, people walk with umbrellas, and the disaster is a troll, which turns to stone in daylight. A newspaper tells what happens. Its script, `Town.js`, draws the town on the canvas and keeps it in the browser. For visitors who prefer reduced motion, the town is a still picture that changes with each thing the visitor does.
*/
struct GeoCitiesTown: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	The tools of the mayor, by the ID that the script knows them by, with their names and prices in kroner.
	*/
	static let tools: [(id: String, name: String, price: Int)] = [
		("house", "House", 100),
		("waffle", "Waffle café", 250),
		("cafe", "Internet café", 300),
		("church", "Stave church", 400),
		("park", "Park", 50),
		("tower", "GeoCities tower", 500),
		("bulldozer", "Bulldozer", 0),
	]

	/**
	The number of lots on the strip of land.
	*/
	static let lotCount = 8

	var content: some HTML {
		h2 {
			"SimSindreville 2000"
		}
		.style(GeoCitiesPage.Styles.titleBar)

		div {
			p {
				GeoCitiesPage.GIFImage(gif: .underConstructionCrane, alt: "", style: .floating, project: project)
				"I am the mayor of my own town! Pick something to build, then click an empty lot. Click the GeoCities tower again for one more floor. The taxes pay for everything, even while you are away. It rains a lot. It is near Bergen."
			}

			fieldset {
				legend {
					"Build:"
				}
				.style(GeoCitiesPage.Styles.label)

				div {
					ForEach(Self.tools) { tool in
						label {
							input(.type(.radio), .name("geocities-town-tool"), .value(tool.id))
								.attributes(.checked, when: tool.id == "house")

							" \(tool.name)"

							if tool.price > 0 {
								span {
									" kr \(tool.price)"
								}
								.style(Styles.price)
							}
						}
						.style(Styles.tool)
					}
				}
				.style(Styles.tools)
			}
			.style(Styles.fieldset, GeoCitiesPage.Styles.scriptingOnly)

			// On phones, the town scrolls sideways, like the map of SimCity, so the lots are large enough for a finger.
			div {
				div {
					canvas(.part(Parts.city), .width(960), .height(320)) {}
						.accessibilityHidden()
						.style(Styles.city)

					// A button for each lot, over the picture of the town, so the keyboard and screen readers can build too. The script names each by what stands on it.
					div {
						ForEach(Array(0..<Self.lotCount)) { lot in
							button(.type(.button), .hook(Hooks.lot, value: "\(lot)")) {
								"Lot \(lot + 1)"
							}
							.style(Styles.lot)
						}
					}
					.style(Styles.lots)
				}
				.style(Styles.land)
			}
			.style(Styles.frame, GeoCitiesPage.Styles.scriptingOnly)

			p {
				span(.part(Parts.funds)) {}
				" ★ "
				span(.part(Parts.population)) {}
				" ★ "
				span(.part(Parts.date)) {}
			}
			.style(Styles.stats, GeoCitiesPage.Styles.scriptingOnly)

			div {
				button(.part(Parts.sun), .type(.button)) {
					"Make it stop raining"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.troll), .type(.button)) {
					"Disaster: troll!"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.honk), .type(.button)) {
					"Honk at a car"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow, GeoCitiesPage.Styles.scriptingOnly)

			div {
				p {
					"The Sindreville Times"
				}
				.style(Styles.masthead)

				p(.part(Parts.news), .role("status")) {}
					.style(Styles.headline)
			}
			.style(Styles.newspaper, GeoCitiesPage.Styles.scriptingOnly)

			p {
				"SimSindreville needs JavaScript. Without it, the town is just a field with a sheep in it."
			}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
		}
		.style(GeoCitiesPage.Styles.windowBody)
	}

	enum Parts: String, ElementPartSet {
		case city
		case funds
		case population
		case date
		case sun
		case troll
		case honk
		case news
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A lot of the town, with its number from 0 on the left.
		*/
		case lot = "data-town-lot"
	}

	enum Styles: ElementStyleSet {
		case root
		case fieldset
		case tools
		case tool
		case price
		case frame
		case land
		case city
		case lots
		case lot
		case stats
		case newspaper
		case masthead
		case headline

		var style: Style {
			switch self {
			case .root:
				// The window that was a section. A custom element is inline by default, so it is a block.
				GeoCitiesPage.Styles.window.style.display(.block)
			case .fieldset:
				Style()
					.margin(0)
					.padding(0)
					.border(.transparent, width: 0)
			case .tools:
				Style()
					.grid(minimumColumnWidth: .rootEm(10.5))
					.gap(.rootEm(0.25))
			case .tool:
				// Like a button of the toolbar of SimCity.
				Style()
					.display(.block)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.handCursor()
					.focusWithin {
						$0.focusRing(.black, width: .pixels(1), offset: .pixels(-4), style: .dotted)
					}
					// The script marks the tool that is picked, which is pressed in.
					.when(.state, is: "on") {
						$0
							.background(Color("#ffffff"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .price:
				Style().color(Color("#006600"))
			case .frame:
				Style()
					.overflow(horizontal: .auto)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.lineHeight(0)
			case .land:
				Style()
					.position(.relative)
					.frame(minWidth: .pixels(480))
			case .city:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(3)
					.imageRendering(.pixelated)
			case .lots:
				// The lots cover the land in the lower part of the picture, above the road.
				Style()
					.position(.absolute)
					.leading(0)
					.trailing(0)
					.top(.percent(25))
					.bottom(.percent(22))
					.grid(columns: GeoCitiesTown.lotCount)
			case .lot:
				// Only an outline under the pointer or with the focus, so the town shows through. The name is for screen readers.
				Style()
					.background(.transparent)
					.border(.transparent, width: .pixels(2), style: .dashed)
					.font(size: 0)
					.color(.transparent)
					.handCursor()
					.hover {
						$0.border(Color("#ffff00"), width: .pixels(2), style: .dashed)
					}
					.focusVisible {
						$0.border(Color("#ffff00"), width: .pixels(2), style: .dashed)
					}
			case .stats:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .newspaper:
				// A newspaper with a black masthead.
				Style()
					.padding(.rootEm(0.5))
					.background(Color("#f4f0e0"))
					.border(Color("#808080"), width: .pixels(1))
					.textAlign(.center)
			case .masthead:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.times)
					.font(.large, weight: .heavy)
					.italic()
					.border(.bottom, .black, width: .pixels(2))
			case .headline:
				Style()
					.margin(.top, .rootEm(0.25))
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.body, weight: .bold)
					.frame(minHeight: .lineHeight(2))
			}
		}
	}
}
