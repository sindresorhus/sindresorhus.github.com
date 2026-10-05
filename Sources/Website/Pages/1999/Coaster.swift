import Elementary
import Foundation
import SiteKit

/**
Sindre’s RollerCoaster Tycoon: Fløyen Park, a game like RollerCoaster Tycoon (Chris Sawyer, March 1999), where the visitor builds a steel roller coaster piece by piece and lets the guests ride it, in a side view of a little park below Fløyen in Bergen. The construction window works like the one of the game: the slope buttons (steep down, down, level, up, steep up) only allow the next steepness, a chain lift can go on the slopes up and clacks as it pulls the train, and the special pieces are a vertical loop, a corkscrew, a helix that can be banked or not, a banked turn around to the front of the park and back, and brakes. A flashing ghost shows the next piece before it is built, and the real errors of the game stop a bad piece, like “Can’t build this here… Ground in the way!” and “Too high!”. Each piece costs kroner from the park money, the bulldozer gives some of it back, and the track is drawn with steel supports down to the ground, with the way back to the station built along the back of the park. A test run sends the empty train around with real physics (gravity, rolling friction, and air drag, with the chain, brakes, and drive tires), and shows the speed, the G-forces, and at the end the Excitement, Intensity, and Nausea ratings of the game, computed from the real ride (speed, drops, G-forces, airtime, and inversions), with the graphs of speed, height, and G-forces of the ride window. A train that is too slow for a hill rolls back and gets stuck, and one that takes an unbanked helix too fast flies off the track. When the ride is open, little pixel guests walk into the park, think about the ride (it can look too intense, or too dull, or too expensive for the ticket price the visitor sets), queue, pay, ride, scream on the drops and loops, and come off with the thoughts of the game, from “Wow! What a great ride!” to “I feel sick”, after which some of them throw up on the path, and a hired handyman sweeps it up. Some guests cannot find the exit. The visitor can name the ride, pick its colors, ride along in an on-ride camera, read the thoughts of any guest by clicking them, borrow money from Pappa, and, like the famous trick of the game, demolish the track in front of a running train, which then flies off, crashes, and lets its balloons go, while the riders float down under their Bergen umbrellas. Its script, `Coaster.js`, runs it on the canvas and keeps the park in the browser. Nothing makes a sound until the visitor turns on the sound. For visitors who prefer reduced motion, the ride is a still diagram with the speeds written along the track, and the train and the guests move one step for each press of the Step button.
*/
struct GeoCitiesCoaster: ScriptedElement {
	static let script = ElementScript()

	/**
	The slope buttons of the construction window, by the ID that the script knows them by, with their arrows and names.
	*/
	private static let slopes: [(id: String, symbol: String, name: String)] = [
		("steepDown", "⇘", "Steep down"),
		("down", "↘", "Down"),
		("level", "→", "Level"),
		("up", "↗", "Up"),
		("steepUp", "⇗", "Steep up"),
	]

	/**
	The special pieces of the construction window, by their IDs in the script, with their names.
	*/
	private static let specials: [(id: String, name: String)] = [
		("loop", "➰ Loop"),
		("corkscrew", "🌀 Corkscrew"),
		("helix", "🐌 Helix"),
		("turn", "↩ Turn around"),
		("brakes", "🛑 Brakes"),
	]

	/**
	The three lights of the ride status, like in the game: closed, testing, and open.
	*/
	private static let statuses: [(id: String, name: String)] = [
		("closed", "Closed"),
		("test", "Test"),
		("open", "Open"),
	]

	/**
	The color schemes of the track, by their IDs in the script.
	*/
	private static let colorSchemes = [
		("red", "Red track, white supports"),
		("blue", "Blue track, yellow supports"),
		("green", "Green track, gray supports"),
		("glitter", "Pink and purple, like Glitter"),
		("black", "Black and orange"),
	]

	/**
	The graphs of the ride window, by their IDs in the script.
	*/
	private static let graphs = [
		("speed", "Speed"),
		("height", "Height"),
		("vertical", "Vertical G"),
		("lateral", "Lateral G"),
	]

	var content: some HTML {
		h2 {
			"Sindre’s RollerCoaster Tycoon: Fløyen Park"
		}
		.style(GeoCitiesPage.Styles.titleBar)

		div {
			p {
				"RollerCoaster Tycoon came out in March, and it is the best game ever made. Pappa says I can be the boss of my own park below Fløyen, as long as I do not spend all the money. Build a roller coaster piece by piece, test it, set the ticket price, and open it! The guests tell you what they think. Watch out for the vomit."
			}

			Game()

			p {
				"My park needs JavaScript. Without it, the guests just stand at the gate in the rain and think “I want to go on something more thrilling than the merry-go-round”."
			}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
		}
		.style(GeoCitiesPage.Styles.windowBody)
	}

	/**
	The screen of the park with its toolbar and news ticker, and the windows of the game below it.
	*/
	private struct Game: HTML {
		var body: some HTML {
			div {
				div {
					Toolbar()

					canvas(.part(Parts.canvas), .width(640), .height(360), .tabindex(0), .role("application")) {}
						.accessibilityLabel("Fløyen Park, with my roller coaster. Click a guest to read what they think. Keys: B builds the selected piece, Backspace demolishes the last piece, T tests the ride, O opens it, X closes it, C turns on the ride camera, G reads the thoughts of the next guest, and Space moves one step while paused.")
						.style(Styles.canvas)

					p(.part(Parts.status), .role("status")) {
						"Welcome to Fløyen Park! Pappa built a coaster and tested it. Click Open to let the guests in, or build your own."
					}
					.style(GeoCitiesPage.Styles.statusBar, Styles.ticker)
				}
				.style(Styles.stage)

				div {
					Construction()
					RideWindow()
					ParkWindow()
				}
				.style(Styles.windows)
			}
			.style(Styles.layout, GeoCitiesPage.Styles.scriptingOnly)
		}
	}

	/**
	The lights of the ride status, and the toggles of the view and the sound.
	*/
	private struct Toolbar: HTML {
		var body: some HTML {
			div {
				div {
					for status in GeoCitiesCoaster.statuses {
						button(.type(.button), .hook(Hooks.rideStatus, value: status.id), .ariaPressed(status.id == "closed")) {
							span {}
								.accessibilityHidden()
								.style(Styles.light, Styles.lightColor(status.id))
							status.name
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.toolButton)
					}
				}
				.style(Styles.lights)

				button(.part(Parts.camera), .type(.button), .ariaPressed(false)) {
					"🎥 Ride camera"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toolButton)

				button(.part(Parts.speeds), .type(.button), .ariaPressed(false)) {
					"Speeds"
				}
				.help("Writes the speeds of the last test run along the track")
				.style(GeoCitiesPage.Styles.smallButton, Styles.toolButton)

				button(.part(Parts.pause), .type(.button), .ariaPressed(false)) {
					"Pause"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toolButton)

				button(.part(Parts.step), .type(.button)) {
					"Step ▶"
				}
				.help("Moves the park on by one second")
				.style(GeoCitiesPage.Styles.smallButton, Styles.toolButton)

				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔈 Sound"
				}
				.help("Plays sound")
				.style(GeoCitiesPage.Styles.smallButton, Styles.toolButton)
			}
			.style(Styles.toolbar)
		}
	}

	/**
	The construction window of the game: the slopes, the special pieces, the chain lift, the banking, and the bulldozer.
	*/
	private struct Construction: HTML {
		var body: some HTML {
			div {
				p {
					"Construction"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					Pieces()

					button(.part(Parts.build), .type(.button)) {
						"Build this"
					}
					.style(GeoCitiesPage.Styles.retroButton, Styles.build)

					p(.part(Parts.message)) {}
						.style(Styles.message)

					div {
						button(.part(Parts.demolish), .type(.button)) {
							"🚜 Demolish last piece"
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.toolButton)

						button(.part(Parts.clear), .type(.button)) {
							"Demolish all"
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.toolButton)

						button(.part(Parts.preset), .type(.button)) {
							"Pappa’s design"
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.toolButton)
					}
					.style(Styles.row)
				}
				.style(Styles.windowContent)
			}
			.style(Styles.gameWindow)
		}
	}

	/**
	The buttons of the pieces of track.
	*/
	private struct Pieces: HTML {
		var body: some HTML {
			p {
				"Slope"
			}
			.style(Styles.groupTitle)

			div {
				for slope in GeoCitiesCoaster.slopes {
					button(.type(.button), .hook(Hooks.piece, value: slope.id), .ariaPressed(slope.id == "level")) {
						span {
							slope.symbol
						}
						.accessibilityHidden()
						.style(Styles.arrow)
						span {
							slope.name
						}
						.style(Styles.pieceName)
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.pieceButton)
				}
			}
			.style(Styles.slopes)

			p {
				"Special"
			}
			.style(Styles.groupTitle)

			div {
				for special in GeoCitiesCoaster.specials {
					button(.type(.button), .hook(Hooks.piece, value: special.id), .ariaPressed(false)) {
						special.name
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.pieceButton)
				}

				button(.part(Parts.chain), .type(.button), .ariaPressed(false)) {
					"⛓ Chain lift"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.pieceButton)

				button(.part(Parts.banked), .type(.button), .ariaPressed(true)) {
					"↺ Banked"
				}
				.help("Tilts the helix toward its middle, so the train cannot fly off")
				.style(GeoCitiesPage.Styles.smallButton, Styles.pieceButton)
			}
			.style(Styles.specials)
		}
	}

	/**
	The ride window of the game: the name, the ticket price, the ratings, the numbers of the test run, its graph, and the colors.
	*/
	private struct RideWindow: HTML {
		var body: some HTML {
			div {
				p {
					"Ride"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					label {
						"Name: "
						input(.part(Parts.name), .type(.text), .maxlength(24), .autocomplete("off"), .value("Roller Coaster 1"))
							.style(GeoCitiesPage.Styles.field)
					}
					.style(Styles.label)

					Price()

					dl(.part(Parts.ratings)) {}
						.style(Styles.ratings)

					dl(.part(Parts.stats)) {}
						.style(Styles.stats)

					Graph()
				}
				.style(Styles.windowContent)
			}
			.style(Styles.gameWindow)
		}
	}

	/**
	The ticket price, with buttons to lower and raise it.
	*/
	private struct Price: HTML {
		var body: some HTML {
			div {
				span {
					"Ticket price: "
				}
				.style(Styles.label)

				button(.part(Parts.priceDown), .type(.button)) {
					"−"
				}
				.accessibilityLabel("Lower the price")
				.style(GeoCitiesPage.Styles.smallButton, Styles.priceButton)

				output(.part(Parts.price)) {
					"30 kr"
				}
				.style(GeoCitiesPage.Styles.lcd, Styles.price)

				button(.part(Parts.priceUp), .type(.button)) {
					"+"
				}
				.accessibilityLabel("Raise the price")
				.style(GeoCitiesPage.Styles.smallButton, Styles.priceButton)
			}
			.style(Styles.row)
		}
	}

	/**
	The graph of the last test run, and the colors of the ride.
	*/
	private struct Graph: HTML {
		var body: some HTML {
			label {
				"Graph: "
				select(.part(Parts.graphKind)) {
					for (value, title) in GeoCitiesCoaster.graphs {
						Elementary.option(.value(value)) {
							title
						}
					}
				}
				.style(GeoCitiesPage.Styles.select)
			}
			.style(Styles.label, Styles.row)

			canvas(.part(Parts.graph), .width(320), .height(110)) {}
				.accessibilityLabel("A graph of the last test run.")
				.style(Styles.graph)

			label {
				"Colors: "
				select(.part(Parts.colors)) {
					for (value, title) in GeoCitiesCoaster.colorSchemes {
						Elementary.option(.value(value)) {
							title
						}
					}
				}
				.style(GeoCitiesPage.Styles.select)
			}
			.style(Styles.label, Styles.row)
		}
	}

	/**
	The park window: the money, the handymen, the loan from Pappa, and the thoughts of the guests.
	*/
	private struct ParkWindow: HTML {
		var body: some HTML {
			div {
				p {
					"Park"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					p(.part(Parts.money)) {}
						.style(GeoCitiesPage.Styles.lcd, Styles.money)

					div {
						button(.part(Parts.handyman), .type(.button)) {
							"🧹 Hire a handyman (500 kr)"
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.toolButton)

						button(.part(Parts.loan), .type(.button)) {
							"💰 Borrow 5 000 kr from Pappa"
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.toolButton)
					}
					.style(Styles.row)

					p {
						"What the guests think:"
					}
					.style(Styles.groupTitle)

					ul(.part(Parts.thoughts)) {}
						.style(Styles.thoughts)
				}
				.style(Styles.windowContent)
			}
			.style(Styles.gameWindow, Styles.parkWindow)
		}
	}

	enum Parts: String, ElementPartSet {
		case canvas
		case status
		case camera
		case speeds
		case pause
		case step
		case sound
		case chain
		case banked
		case build
		case message
		case demolish
		case clear
		case preset
		case name
		case priceDown
		case priceUp
		case price
		case ratings
		case stats
		case graphKind
		case graph
		case colors
		case money
		case handyman
		case loan
		case thoughts
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A light of the ride status, with its ID, like `open`.
		*/
		case rideStatus = "data-coaster-status"

		/**
		A button of a track piece in the construction window, with its ID, like `steepUp`.
		*/
		case piece = "data-coaster-piece"
	}

	enum Styles: ElementStyleSet {
		case root
		case layout
		case stage
		case toolbar
		case lights
		case toolButton
		case light
		case lightClosed
		case lightTest
		case lightOpen
		case canvas
		case ticker
		case windows
		case gameWindow
		case parkWindow
		case windowContent
		case groupTitle
		case slopes
		case specials
		case pieceButton
		case arrow
		case pieceName
		case build
		case message
		case row
		case label
		case priceButton
		case price
		case ratings
		case stats
		case graph
		case money
		case thoughts

		/**
		The color of a light of the ride status, by its ID.
		*/
		static func lightColor(_ id: String) -> Self {
			switch id {
			case "test":
				.lightTest
			case "open":
				.lightOpen
			default:
				.lightClosed
			}
		}

		var style: Style {
			switch self {
			case .root:
				// The window that was a section. A custom element is inline by default, so it is a block.
				GeoCitiesPage.Styles.window.style.display(.block)
			case .layout:
				Style().vstack(spacing: .rootEm(0.75))
			case .stage:
				Style().vstack(spacing: .rootEm(0.375))
			case .toolbar:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .lights:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .toolButton:
				// Big enough for a finger. A pressed toggle is sunken in, like a toggle of Windows 95.
				Style()
					.frame(minHeight: .rootEm(2.25))
					.disabled {
						$0.opacity(0.5)
					}
					.when(.state, is: "on") {
						$0
							.background(.white)
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .light:
				// A round lamp, dark until its status is on, like the lights of the ride window of the game.
				Style()
					.display(.inlineBlock)
					.frame(width: .rootEm(0.75), height: .rootEm(0.75))
					.margin(.trailing, .rootEm(0.25))
					.border(Color("#404040"), width: .pixels(1), style: .solid)
					.cornerRadius(.capsule)
					.opacity(0.35)
					.when(.state, is: "on") {
						$0
							.opacity(1)
							.shadow(Shadow(x: 0, y: 0, blur: .pixels(4), color: Color("#ffff99")))
					}
			case .lightClosed:
				Style().background(Color("#ff2020"))
			case .lightTest:
				Style().background(Color("#ffd800"))
			case .lightOpen:
				Style().background(Color("#20e020"))
			case .canvas:
				// A tap on a guest reads their thoughts, so a finger on the park does not zoom the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(640.0 / 360.0)
					.background(Color("#8fb8d8"))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.imageRendering(.pixelated)
					.touchAction(.manipulation)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .ticker:
				// The news ticker at the bottom of the screen of the game, two lines high so the page does not jump.
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.background(Color("#ffffcc"))
					.textStyle(.caption, weight: .bold)
			case .windows:
				// The windows of the game sit side by side, or below each other on a phone. Three columns would squeeze the slope buttons and the ticket price on the narrow page.
				Style()
					.grid(columns: 1)
					.gap(.rootEm(0.75))
					.from(.smallTablet) {
						$0.grid(columns: 2)
					}
			case .parkWindow:
				// The park window, which is short, goes across below the two others.
				Style().from(.smallTablet) {
					$0.gridColumnSpan(2)
				}
			case .gameWindow:
				Style()
					.background(Color("#c8b89a"))
					.border(Color("#efe4cf"), width: .pixels(3), style: .outset)
			case .windowContent:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.5))
			case .groupTitle:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#402000"))
			case .slopes:
				Style()
					.grid(columns: 5)
					.gap(.pixels(3))
			case .specials:
				Style()
					.grid(columns: 2)
					.gap(.pixels(3))
			case .pieceButton:
				// A piece is pressed in while it is picked, and grayed out where the track cannot take it.
				Style()
					.frame(minHeight: .rootEm(2.5))
					.padding(.pixels(2))
					.disabled {
						$0.opacity(0.4)
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#fff8d0"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .arrow:
				Style()
					.display(.block)
					.font(.large, weight: .heavy)
					.lineHeight(1)
			case .pieceName:
				Style()
					.display(.block)
					.font(.extraSmall)
			case .build:
				Style().frame(minHeight: .rootEm(2.75))
			case .message:
				// The cost of the next piece, or the error of the game, like “Too high!”.
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#800000"))
			case .row:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .label:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .priceButton:
				Style().frame(minWidth: .rootEm(2.5), minHeight: .rootEm(2.25))
			case .price:
				Style()
					.frame(minWidth: .rootEm(4.5))
					.textAlign(.center)
			case .ratings:
				// The three ratings of the game, big, as they decide everything.
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.125))
					.margin(0)
					.padding(.rootEm(0.375))
					.background(Color("#fffbe0"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.children("dd") {
						$0.margin(0)
					}
			case .stats:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.0625))
					.margin(0)
					.fontFamily(.system)
					.font(.extraSmall)
					.children("dd") {
						$0.margin(0).fontWeight(.bold)
					}
			case .graph:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(320.0 / 110.0)
					.background(.black)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .money:
				Style()
					.margin(0)
					.preservesLineBreaks()
					.textStyle(.caption)
			case .thoughts:
				// The thoughts of the guests, newest first, like the thoughts tab of the park window of the game.
				Style()
					.frame(minHeight: .rootEm(6))
					.margin(0)
					.padding(.rootEm(0.375))
					.padding(.leading, .rootEm(1.25))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(.system)
					.font(.extraSmall)
			}
		}
	}
}
