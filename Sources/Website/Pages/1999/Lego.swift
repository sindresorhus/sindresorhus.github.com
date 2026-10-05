import Elementary
import Foundation
import SiteKit

/**
My LEGO, as a builder like LEGO Creator (1998): the visitor clicks bricks onto a green baseplate in an isometric view, with the classic colors and studs, stacks them, turns them, and takes them off again. The building is kept in the browser. A set with instructions, the 6999 Brunost Cruiser of LEGO Space, shows each brick to place, step by step, and the Swoosh button flies whatever is on the plate around the room, like every kid did with a spaceship. Its script, `Lego.js`, draws and runs it.
*/
struct GeoCitiesLego: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the element, which the LEGO shelf in my room leads to.
	*/
	static let rootID = "geocities-lego"

	/**
	The bricks, by the size that the script knows them by, with their names.
	*/
	static let pieces: [(id: String, name: String)] = [
		("2x4", "2×4"),
		("2x2", "2×2"),
		("1x4", "1×4"),
		("1x2", "1×2"),
		("1x1", "1×1"),
		("figure", "Minifigure"),
	]

	/**
	The classic colors of LEGO, by the name that the script knows them by, with their names and colors.
	*/
	static let colors: [(id: String, name: String, style: Styles)] = [
		("red", "Red", .red),
		("blue", "Blue", .blue),
		("yellow", "Yellow", .yellow),
		("green", "Green", .green),
		("white", "White", .white),
		("gray", "Gray", .gray),
		("black", "Black", .black),
		("clear", "Transparent", .clear),
	]

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id(Self.rootID), .tabindex(-1)]
	}

	var content: some HTML {
		h2 {
			"My LEGO"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"I started with LEGO before computers. Build something! Click the plate to put a brick on it, and click a brick to put one on top. Mamma says it has to be tidied up before dinner."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			h3 {
				"LEGO Builder ’99"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				div {
					div {
						for (index, piece) in Self.pieces.enumerated() {
							button(.type(.button), .hook(Hooks.piece, value: piece.id), .ariaPressed(index == 0)) {
								piece.name
							}
							.style(Styles.toolButton)
						}
					}
					.accessibilityLabel("Brick")
					.attributes(.role("group"))
					.style(Styles.toolRow)

					div {
						for (index, color) in Self.colors.enumerated() {
							button(.type(.button), .hook(Hooks.color, value: color.id), .ariaPressed(index == 0)) {
								span {
									color.name
								}
								.style(Styles.swatchName)
							}
							.style(Styles.swatch, color.style)
						}
					}
					.accessibilityLabel("Color")
					.attributes(.role("group"))
					.style(Styles.toolRow)
				}
				.style(Styles.toolbar)

				// The plate is drawn at twice the size of the canvas on the page, so the studs are round and sharp.
				canvas(.part(Parts.canvas), .width(640), .height(480), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The LEGO baseplate. Move with the arrow keys, press Enter to put the brick on, R to turn it, and Delete to take the top brick off.")
					.style(Styles.canvas)

				p(.part(Parts.step), .hidden) {}
					.style(Styles.step)

				div {
					button(.type(.button), .hook(Hooks.action, value: "rotate")) {
						"↻ Turn"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.type(.button), .hook(Hooks.action, value: "remove"), .ariaPressed(false)) {
						"✋ Take Off"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

					button(.type(.button), .hook(Hooks.action, value: "undo")) {
						"↶ Undo"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.type(.button), .hook(Hooks.action, value: "swoosh")) {
						"🚀 Swoosh!"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.type(.button), .hook(Hooks.action, value: "set")) {
						"📘 Build Set 6999"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.type(.button), .hook(Hooks.action, value: "tidy")) {
						"🧹 Tidy Up"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)

				p(.part(Parts.status), .role("status")) {}
					.style(Styles.status)
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window, Styles.window, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My LEGO needs JavaScript. Without it, it is just a box of bricks."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case canvas
		case step
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The size of a brick button, like `2x4`.
		*/
		case piece = "data-lego-piece"

		/**
		The color of a color button, like `red`.
		*/
		case color = "data-lego-color"

		/**
		What a button of the builder does, like `swoosh`.
		*/
		case action = "data-lego-action"
	}

	enum Styles: ElementStyleSet {
		case root
		case window
		case toolbar
		case toolRow
		case toolButton
		case swatch
		case red
		case blue
		case yellow
		case green
		case white
		case gray
		case black
		case clear
		case swatchName
		case toggle
		case canvas
		case step
		case status

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .window:
				Style()
					.frame(maxWidth: .pixels(720))
					.margin(.horizontal, .auto)
			case .toolbar:
				Style().vstack(spacing: .rootEm(0.375))
			case .toolRow:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .toolButton:
				// A raised button, pressed in while its brick is chosen.
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.handCursor()
					.when(.state, is: "on") {
						$0
							.background(Color("#ffffff"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .swatch:
				// A square of the color, with a thick black edge while it is chosen.
				Style()
					.frame(width: .rootEm(2), height: .rootEm(2))
					.border(Color("#555555"), width: .pixels(2), style: .outset)
					.handCursor()
					.when(.state, is: "on") {
						$0.border(.black, width: .pixels(4), style: .solid)
					}
			case .red:
				Style().background(Color("#c91a09"))
			case .blue:
				Style().background(Color("#0055bf"))
			case .yellow:
				Style().background(Color("#f2cd37"))
			case .green:
				Style().background(Color("#237841"))
			case .white:
				Style().background(Color("#f4f4f4"))
			case .gray:
				Style().background(Color("#a0a5a9"))
			case .black:
				Style().background(Color("#2a2a2a"))
			case .clear:
				// Transparent, like the windows of the spaceships.
				Style().backgroundImage(.linearGradient("135deg", Color("#e8f8ff"), Color("#9fd4e8"), Color("#e8f8ff")))
			case .swatchName:
				Style().visuallyHidden()
			case .toggle:
				Style().when(.state, is: "on") {
					$0
						.background(Color("#ffcc66"))
						.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
				}
			case .canvas:
				// A tap puts a brick on, and a finger can still scroll the page over the plate, as the bricks go on with a click.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(640.0 / 480.0)
					.background(Color("#9cc3e6"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.touchAction(.manipulation)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .step:
				// A page of the instructions, in the blue of the LEGO books of the 1990s.
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(Color("#0055bf"))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.white)
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			}
		}
	}
}
