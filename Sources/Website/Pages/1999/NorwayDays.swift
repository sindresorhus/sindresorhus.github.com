import Elementary
import Foundation
import SiteKit

/**
The everyday life of a kid in Norway in 1999, as toys: the matpakke, the packed lunch of slices of bread with brown cheese and the paper between them, which the visitor makes for the day and which Mom and the class judge at lunch; crab fishing off the dock in the summer, where a crab lets go of the line if it is pulled up too fast; dressing for the weather of Bergen, as there is no bad weather, only bad clothes; slicing brown cheese with the cheese slicer, without making a ski slope; and the Saturday candy, picked by weight for the money of the week. Its script, `NorwayDays.js`, runs them, only while they are on the screen and the tab is visible. With reduced motion, the crabs do not walk around, and a crab is at the mussel at once.
*/
struct GeoCitiesNorwayDays: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the window of the matpakke, which the school bag in my room leads to.
	*/
	static let lunchID = "geocities-lunch"

	/**
	The ID of the window of the weather, which the rain gear in my room leads to.
	*/
	static let weatherID = "geocities-dress"

	/**
	The ID of the window of the crab fishing, which the crab bucket in my room leads to.
	*/
	static let crabsID = "geocities-crabs"

	/**
	What can go on a slice of bread, by the name that the script knows it by, with its name.
	*/
	static let toppings: [(id: String, name: String)] = [
		("brunost", "🟫 Brunost"),
		("gulost", "🧀 Gulost"),
		("leverpostei", "🐷 Leverpostei"),
		("makrell", "🐟 Makrell i tomat"),
		("kaviar", "🥫 Kaviar"),
		("syltetøy", "🍓 Syltetøy"),
		("nugatti", "🍫 Nugatti"),
		("banan", "🍌 Banana"),
	]

	/**
	The clothes for the weather, by the name that the script knows them by, with their names.
	*/
	static let clothes: [(id: String, name: String)] = [
		("sydvest", "Sou’wester"),
		("lue", "Wool hat"),
		("caps", "Cap"),
		("regnjakke", "Rain jacket"),
		("ullgenser", "Wool sweater"),
		("tskjorte", "T-shirt"),
		("regnbukse", "Rain pants"),
		("shorts", "Shorts"),
		("støvler", "Rubber boots"),
		("joggesko", "Sneakers"),
		("votter", "Mittens"),
		("solbriller", "Sunglasses"),
	]

	var content: some HTML {
		h2 {
			"A Day in My Life"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		div {
			window("My Matpakke", id: Self.lunchID) {
				lunch
			}

			window("Det finnes ikke dårlig vær…", id: Self.weatherID) {
				weather
			}
		}
		.style(GeoCitiesPage.Styles.columns, GeoCitiesPage.Styles.scriptingOnly)

		div {
			window("Summer 1999: Crab Fishing off the Dock", id: Self.crabsID) {
				crabs
			}
		}
		.style(Styles.wide, GeoCitiesPage.Styles.scriptingOnly)

		div {
			window("Brunost and the Ostehøvel") {
				cheese
			}

			window("Lørdagsgodt: Saturday Candy") {
				candy
			}
		}
		.style(GeoCitiesPage.Styles.columns, Styles.wide, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My lunch, the weather, the crabs, the cheese, and the candy need JavaScript. The lunch is brown cheese on bread anyway."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	private var lunch: some HTML {
		div {
			p {
				"In Norway, we bring a matpakke to school: slices of bread with something on them, with a sheet of paper between the slices. Make mine! Mom wants it healthy. My class wants it cool."
			}
			.style(GeoCitiesPage.Styles.caption)

			canvas(.part(Parts.lunchCanvas), .width(240), .height(150)) {}
				.accessibilityHidden()
				.style(Styles.canvas)

			p(.part(Parts.lunchSlices)) {
				"The lunch box is empty."
			}
			.style(Styles.list)

			div {
				for topping in Self.toppings {
					button(.type(.button), .hook(Hooks.topping, value: topping.id)) {
						topping.name
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
			}
			.accessibilityLabel("Put a slice in the box with")
			.attributes(.role("group"))
			.style(Styles.choices)

			div {
				button(.part(Parts.lunchUndo), .type(.button)) {
					"Take Out a Slice"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.lunchGo), .type(.button)) {
					"🎒 Go to School"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.lunchStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.toy)
	}

	private var weather: some HTML {
		div {
			p {
				"…bare dårlige klær: there is no bad weather, only bad clothes. Dress me for the weather of Bergen today, and send me out to play. It changes fast."
			}
			.style(GeoCitiesPage.Styles.caption)

			p(.part(Parts.forecast)) {}
				.style(GeoCitiesPage.Styles.lcd)

			div {
				canvas(.part(Parts.weatherCanvas), .width(120), .height(160)) {}
					.accessibilityHidden()
					.style(Styles.canvas, Styles.kid)

				fieldset {
					legend {
						"My clothes"
					}
					.style(Styles.legend)

					for item in Self.clothes {
						label {
							input(.type(.checkbox), .hook(Hooks.clothing, value: item.id))
							" \(item.name)"
						}
						.style(Styles.clothing)
					}
				}
				.style(Styles.wardrobe)
			}
			.style(Styles.dressRow)

			div {
				button(.part(Parts.weatherGo), .type(.button)) {
					"Go Out and Play"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.weatherNew), .type(.button)) {
					"Next Day"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.weatherStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.toy)
	}

	private var crabs: some HTML {
		div {
			p {
				"Lower the line with a mussel on the hook, and wait for a crab to grab it. Then hold the reel button to pull it up. Pull too fast, and it lets go! We always let them go at the end of the day."
			}
			.style(GeoCitiesPage.Styles.caption)

			canvas(.part(Parts.crabCanvas), .width(400), .height(200), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The dock and the sea. Press Enter to lower the line, and hold Space or the up arrow to reel it in.")
				.style(Styles.canvas)

			div {
				button(.part(Parts.crabLower), .type(.button)) {
					"Lower the Line"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.crabReel), .type(.button), .disabled) {
					"Hold to Reel In"
				}
				.style(Styles.reel)

				button(.part(Parts.crabRelease), .type(.button), .disabled) {
					"Let Them Go"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.dimmedWhenDisabled)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.crabStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.toy)
	}

	private var cheese: some HTML {
		div {
			p {
				"The cheese slicer is a Norwegian invention (1925). Drag it across the brown cheese from left to right, and keep it level for a thin, even slice. Dig in, and you make a ski slope, and Dad will notice."
			}
			.style(GeoCitiesPage.Styles.caption)

			canvas(.part(Parts.cheeseCanvas), .width(320), .height(180), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The brown cheese and the cheese slicer. Press the up and down arrow keys to tilt the slicer, and Enter to cut a slice.")
				.style(Styles.canvas, Styles.cheeseCanvas)

			div {
				button(.part(Parts.cheeseNew), .type(.button)) {
					"New Cheese"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.cheeseStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.toy)
	}

	private var candy: some HTML {
		div {
			p {
				"Candy only on Saturdays! Pick it by weight, at 8.90 kroner a hectogram, for my 20 kroner. Get as close as you can, but not over."
			}
			.style(GeoCitiesPage.Styles.caption)

			canvas(.part(Parts.candyCanvas), .width(320), .height(180)) {}
				.accessibilityHidden()
				.style(Styles.canvas)

			div {
				for (kind, name) in Self.candies {
					button(.type(.button), .hook(Hooks.candyKind, value: kind)) {
						name
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
			}
			.accessibilityLabel("Put in the bag")
			.attributes(.role("group"))
			.style(Styles.choices)

			div {
				button(.part(Parts.candyBack), .type(.button)) {
					"Put One Back"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.candyPay), .type(.button)) {
					"Pay"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.candyStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.toy)
	}

	/**
	The candy of the pick-and-mix, by the name that the script knows it by, with its name.
	*/
	static let candies: [(id: String, name: String)] = [
		("seigmenn", "Jelly men"),
		("skumbananer", "Foam bananas"),
		("lakris", "Licorice"),
		("sure", "Sour tongues"),
		("sjokolade", "Chocolate buttons"),
	]

	/**
	A window of a toy. A window with an ID, which a thing in my room leads to, can have the focus, so the keyboard goes on from there.
	*/
	private func window(_ title: String, id: String? = nil, @HTMLBuilder content: () -> some HTML) -> some HTML {
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
		.attributes(.id(id ?? ""), .tabindex(-1), when: id != nil)
		.style(GeoCitiesPage.Styles.window)
	}

	enum Parts: String, ElementPartSet {
		case lunchCanvas
		case lunchSlices
		case lunchUndo
		case lunchGo
		case lunchStatus

		case forecast
		case weatherCanvas
		case weatherGo
		case weatherNew
		case weatherStatus

		case crabCanvas
		case crabLower
		case crabReel
		case crabRelease
		case crabStatus

		case cheeseCanvas
		case cheeseNew
		case cheeseStatus

		case candyCanvas
		case candyBack
		case candyPay
		case candyStatus
	}

	enum Hooks: String, ScriptHookSet {
		/**
		What a button puts on a slice of bread, like `brunost`.
		*/
		case topping = "data-lunch-topping"

		/**
		The clothing of a checkbox of the wardrobe, like `sydvest`.
		*/
		case clothing = "data-dress-clothing"

		/**
		The candy that a button puts in the bag, like `seigmenn`.
		*/
		case candyKind = "data-candy-kind"
	}

	enum Styles: ElementStyleSet {
		case root
		case wide
		case toy
		case canvas
		case list
		case choices
		case status
		case dressRow
		case kid
		case wardrobe
		case legend
		case clothing
		case reel
		case cheeseCanvas
		case dimmedWhenDisabled

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .wide:
				Style().margin(top: .rootEm(1.25))
			case .toy:
				Style().vstack(spacing: .rootEm(0.5))
			case .canvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.imageRendering(.pixelated)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .list:
				Style()
					.margin(0)
					.textStyle(.caption)
			case .choices:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .dressRow:
				Style()
					.hstack(alignment: .start, justification: .center, spacing: .rootEm(0.75))
					.flexWrap()
			case .kid:
				Style()
					.frame(width: .rootEm(7.5))
					.flexShrink(0)
					.background(Color("#9ab"))
			case .wardrobe:
				// Two columns of clothes, like a wardrobe with two doors.
				Style()
					.grid(minimumColumnWidth: .rootEm(7.5))
					.gap(row: .rootEm(0.125), column: .rootEm(0.5))
					.flex(1)
					.frame(minWidth: .rootEm(10))
					.margin(0)
					.padding(.rootEm(0.375))
					.border(Color("#808080"), width: .pixels(2), style: .groove)
			case .legend:
				Style()
					.padding(.horizontal, .rootEm(0.25))
					.textStyle(.caption, weight: .bold)
			case .clothing:
				Style()
					.textStyle(.caption)
					.handCursor()
			case .dimmedWhenDisabled:
				// The small buttons of the page have no look of their own when they do nothing.
				Style().disabled {
					$0.opacity(0.5)
				}
			case .cheeseCanvas:
				// A finger slices instead of scrolling the page.
				Style()
					.touchAction(.none)
					.cursor(.crosshair)
			case .reel:
				// Held down to reel in, so a long press on a phone does not select the text.
				Style()
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(1))
					.background(Color("#ffcc33"))
					.border(Color("#cc9900"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(0.375))
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(.black)
					.touchAction(.none)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0.border(Color("#cc9900"), width: .pixels(3), style: .inset)
					}
					.disabled {
						$0.opacity(0.5)
					}
			}
		}
	}
}
