import Elementary
import Foundation
import SiteKit

/**
The Craft Table: the kitchen table on a rainy Saturday in Bergen, covered in Bergens Tidende, with four crafts, each in its own window and drawn on a canvas. Hama beads, from the tub of every Norwegian home: a clear pegboard (square, heart, or star) on which the visitor places glossy beads in the colors of the tub with the fingers (drag to place many, and sometimes one bounces off) or the tweezers (one at a time, and they pick beads off again), with a pattern sheet under the board to follow (a heart, the Norwegian flag, a waffle with brown cheese, and Glitter the unicorn) that counts the beads that are right, a bowl that gets knocked over and scatters beads on the table to pick up, and Mamma’s iron: the visitor holds it and moves it over the baking paper, each bead melts from round to flat by how long the iron was over it, and too long burns it brown and smelly. A finished piece goes on the fridge. Paper snowflakes: the visitor folds a paper into 6, 4, or 8, cuts shapes out of the folded wedge with the scissors by clicking or dragging around them, sees the scraps fall, and unfolds the symmetric snowflake, which hangs in the rainy kitchen window and turns on its thread with the others. A Spirograph: a ring and a wheel with a hole for the pen, turned by dragging around the ring or by holding a button, with ballpoint colors and the four-color pen, a wheel that slips a tooth now and then, a ballpoint that skips and blobs, a wheel that flies out when it is turned too fast, a count of the turns until the pattern closes, and a new sheet and a save as PNG. Shrinky Dinks (krympeplast): markers on the frosted sheet, which can be laid over a drawing of Glitter to trace, the scissors to cut it out, the hole punch for the keyring, and the oven with the window, the timer, and the light, where the piece curls up, flattens, and shrinks to a small thick charm, which must come out before it burns, and goes on the keyring of my school bag. Nothing makes a sound until the visitor turns on the sound: the beads click, the scissors snip, the iron hisses, and the oven timer rings. Its script, `Crafts.js`, runs it, only while it is on the screen and the tab is visible, and keeps the fridge, the window, and the keyring in the browser. With reduced motion, nothing moves by itself: the scraps and the beads land at once, the snowflakes hang still, and the oven shows its steps when the visitor looks in.
*/
struct GeoCitiesCrafts: ScriptedElement {
	static let script = ElementScript()

	/**
	The colors of the Hama tub, with the numbers that Hama gives them.
	*/
	static let beadColors: [(id: String, name: String, color: String)] = [
		("01", "White", "#f4f3ee"),
		("03", "Yellow", "#f6cf1d"),
		("04", "Orange", "#ee7a1d"),
		("05", "Red", "#c81f2b"),
		("06", "Pink", "#f39cbf"),
		("07", "Purple", "#7b4a9f"),
		("08", "Blue", "#1f3f96"),
		("09", "Light Blue", "#5aa7e2"),
		("10", "Green", "#1f8a3d"),
		("27", "Beige", "#e2bf88"),
		("12", "Brown", "#7a4a26"),
		("17", "Gray", "#9b9b9b"),
		("18", "Black", "#232323"),
	]

	/**
	The ballpoint pens of the Spirograph box.
	*/
	static let penColors: [(name: String, color: String)] = [
		("Blue", "#1d3fbf"),
		("Red", "#d0202b"),
		("Green", "#178a3a"),
		("Black", "#1a1a1a"),
		("Purple", "#7a2a9c"),
	]

	/**
	The permanent markers for the shrink plastic.
	*/
	static let markerColors: [(name: String, color: String)] = [
		("Black", "#151515"),
		("Red", "#e0182b"),
		("Orange", "#f57a10"),
		("Yellow", "#f4d60f"),
		("Green", "#1c9a3c"),
		("Blue", "#1c4fd0"),
		("Purple", "#8a2fb0"),
		("Pink", "#f05aa8"),
		("Brown", "#7a4520"),
	]

	/**
	The teeth of the wheels of the Spirograph set.
	*/
	static let wheels = [24, 30, 36, 40, 45, 52, 56, 60, 63, 72, 75, 80, 84]

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.tabindex(-1)]
	}

	var content: some HTML {
		h2 {
			"The Craft Table"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Saturday in Bergen, and it has rained since Tuesday. Mamma covered the kitchen table with Bergens Tidende and got out the craft box (formingsboksen), so now we craft. Lillesøster eats the Hama beads, so watch her."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
				"🔇 Sound Off"
			}
			.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
		}
		.style(GeoCitiesPage.Styles.buttonRow, GeoCitiesPage.Styles.scriptingOnly)

		div {
			window("Hama Beads") {
				hama
			}

			window("Paper Snowflakes") {
				snowflakes
			}

			window("Spirograph") {
				spirograph
			}

			window("Shrinky Dinks (Krympeplast)") {
				shrinky
			}
		}
		.style(Styles.toys, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The craft table needs JavaScript. And Mamma to say yes to the glitter."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	// MARK: Hama beads

	private var hama: some HTML {
		div {
			p {
				"Click or drag on the pegboard to put on beads. Put a pattern under the board to follow it. When it is done, Mamma irons it: hold the iron and move it over the paper, but not too long!"
			}
			.style(GeoCitiesPage.Styles.caption)

			div {
				label {
					"Board: "
					select(.part(Parts.hamaBoard)) {
						option(.value("square")) {
							"Square"
						}
						option(.value("heart")) {
							"Heart"
						}
						option(.value("star")) {
							"Star"
						}
					}
					.style(GeoCitiesPage.Styles.select)
				}

				label {
					"Pattern: "
					select(.part(Parts.hamaPattern)) {
						option(.value("")) {
							"None"
						}
						option(.value("heart")) {
							"A heart"
						}
						option(.value("flag")) {
							"The Norwegian flag"
						}
						option(.value("waffle")) {
							"A waffle with brunost"
						}
						option(.value("unicorn")) {
							"Glitter the unicorn"
						}
					}
					.style(GeoCitiesPage.Styles.select)
				}
			}
			.style(GeoCitiesPage.Styles.formRow)

			hamaTub

			canvas(.part(Parts.hamaCanvas), .width(640), .height(640), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The Hama pegboard on the kitchen table. Move with the arrow keys and press Enter to put on a bead or, with the tweezers, to take one off. While ironing, the arrow keys move the iron.")
				.style(Styles.canvas, Styles.drawingCanvas)

			hamaButtons

			p(.part(Parts.hamaStatus), .role("status")) {}
				.style(Styles.status)

			canvas(.part(Parts.fridge), .width(640), .height(220), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The fridge door, with the finished Hama pieces. Press Delete to take down the newest one.")
				.style(Styles.canvas, Styles.displayCanvas)
		}
		.style(Styles.toy)
	}

	private var hamaTub: some HTML {
		div {
			div {
				for (index, bead) in Self.beadColors.enumerated() {
					button(.type(.button), .hook(Hooks.color, value: bead.color), .ariaPressed(index == 3)) {
						span {
							"\(bead.id) \(bead.name)"
						}
						.style(Styles.swatchName)
					}
					.style(Styles.swatch, Styles.bead)
				}

				button(.type(.button), .hook(Hooks.color, value: "mixed"), .ariaPressed(false)) {
					span {
						"Mixed, a handful from the tub"
					}
					.style(Styles.swatchName)
				}
				.style(Styles.swatch, Styles.bead, Styles.mixed)
			}
			.attributes(.part(Parts.hamaColors), .role("group"))
			.accessibilityLabel("Bead color")
			.style(Styles.swatches)

			div {
				button(.type(.button), .hook(Hooks.tool, value: "fingers"), .ariaPressed(true)) {
					"🤏 Fingers"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

				button(.type(.button), .hook(Hooks.tool, value: "tweezers"), .ariaPressed(false)) {
					"🪡 Tweezers"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
			}
			.attributes(.part(Parts.hamaTools), .role("group"))
			.accessibilityLabel("Tool")
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.toolbar)
	}

	private var hamaButtons: some HTML {
		div {
			action("hama-spill", "🥣 Knock Over the Bowl")
			action("hama-empty", "♻️ Tip Back in the Tub")
			action("hama-iron", "♨️ Mamma, Iron It!")
			action("hama-lift", "📄 Lift the Paper", isDisabled: true)
			action("hama-fridge", "🧲 Put It on the Fridge", isDisabled: true)
		}
		.style(GeoCitiesPage.Styles.buttonRow)
	}

	// MARK: Paper snowflakes

	private var snowflakes: some HTML {
		div {
			p {
				"Fold the paper, then cut pieces out of the folded wedge: click around a shape, or drag the scissors around it. Then unfold it and see the snowflake!"
			}
			.style(GeoCitiesPage.Styles.caption)

			div {
				label {
					"Fold in: "
					select(.part(Parts.snowFolds)) {
						option(.value("6")) {
							"6, like real snow"
						}
						option(.value("4")) {
							"4"
						}
						option(.value("8")) {
							"8"
						}
					}
					.style(GeoCitiesPage.Styles.select)
				}

				label {
					"Paper: "
					select(.part(Parts.snowPaper)) {
						option(.value("white")) {
							"White paper"
						}
						option(.value("blue")) {
							"Blue glanspapir"
						}
						option(.value("red")) {
							"Red glanspapir"
						}
						option(.value("gold")) {
							"Gold paper"
						}
						option(.value("news")) {
							"Bergens Tidende"
						}
					}
					.style(GeoCitiesPage.Styles.select)
				}
			}
			.style(GeoCitiesPage.Styles.formRow)

			canvas(.part(Parts.snowCanvas), .width(640), .height(640), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The folded paper. Move the scissors with the arrow keys, and press Enter to add a corner of the cut. Press Enter on the first corner again to finish the cut, Escape to stop cutting, and Backspace to undo.")
				.style(Styles.canvas, Styles.drawingCanvas)

			div {
				action("snow-fold", "📄 Fold a New Paper")
				action("snow-undo", "↶ Undo the Cut", isDisabled: true)
				action("snow-unfold", "❄️ Unfold It!")
				action("snow-hang", "🪟 Hang It in the Window", isDisabled: true)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.snowStatus), .role("status")) {}
				.style(Styles.status)

			canvas(.part(Parts.kitchenWindow), .width(640), .height(300), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The kitchen window, with the snowflakes hanging in it, and the rain outside. Press Delete to take down the newest one.")
				.style(Styles.canvas, Styles.displayCanvas)
		}
		.style(Styles.toy)
	}

	// MARK: Spirograph

	private var spirograph: some HTML {
		div {
			p {
				"Pick a ring, a wheel, and a hole for the pen. Then drag around the ring to turn the wheel, or hold the button. Not too fast, or the wheel flies out!"
			}
			.style(GeoCitiesPage.Styles.caption)

			div {
				label {
					"Ring: "
					select(.part(Parts.spiroRing)) {
						option(.value("96")) {
							"96 teeth, inside"
						}
						option(.value("105")) {
							"105 teeth, inside"
						}
						option(.value("-144")) {
							"144 teeth, around the outside"
						}
					}
					.style(GeoCitiesPage.Styles.select)
				}

				label {
					"Wheel: "
					select(.part(Parts.spiroWheel)) {
						for teeth in Self.wheels {
							option(.value("\(teeth)")) {
								"\(teeth) teeth"
							}
							.attributes(.selected, when: teeth == 40)
						}
					}
					.style(GeoCitiesPage.Styles.select)
				}

				label {
					"Hole: "
					select(.part(Parts.spiroHole)) {
						for hole in 1...6 {
							option(.value("\(hole)")) {
								hole == 1 ? "1, at the edge" : (hole == 6 ? "6, near the middle" : "\(hole)")
							}
							.attributes(.selected, when: hole == 2)
						}
					}
					.style(GeoCitiesPage.Styles.select)
				}
			}
			.style(GeoCitiesPage.Styles.formRow)

			div {
				for (index, pen) in Self.penColors.enumerated() {
					button(.type(.button), .hook(Hooks.color, value: pen.color), .ariaPressed(index == 0)) {
						span {
							"\(pen.name) pen"
						}
						.style(Styles.swatchName)
					}
					.style(Styles.swatch, Styles.pen)
				}

				button(.type(.button), .hook(Hooks.color, value: "four"), .ariaPressed(false)) {
					span {
						"The four-color pen, which changes color each time around"
					}
					.style(Styles.swatchName)
				}
				.style(Styles.swatch, Styles.pen, Styles.mixed)
			}
			.attributes(.part(Parts.spiroColors), .role("group"))
			.accessibilityLabel("Pen color")
			.style(Styles.swatches)

			canvas(.part(Parts.spiroCanvas), .width(640), .height(640), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The Spirograph, pinned to the table. Hold the right arrow key to turn the wheel one way, and the left arrow key to turn it back. If the wheel flies out, an arrow key puts it back.")
				.style(Styles.canvas, Styles.drawingCanvas)

			div {
				button(.type(.button), .hook(Hooks.action, value: "spiro-turn"), .ariaPressed(false)) {
					"🔄 Hold to Turn"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle, Styles.holdButton)
				action("spiro-shift", "↪️ Start a Bit Further")
				action("spiro-clear", "📄 New Paper")
				action("spiro-save", "💾 Save as PNG")
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.spiroStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.toy)
	}

	// MARK: Shrinky Dinks

	private var shrinky: some HTML {
		div {
			p {
				"Draw on the frosted plastic with the markers, cut it out with the scissors, and punch a hole for the keyring. Then bake it, and watch through the oven window. It gets small and thick!"
			}
			.style(GeoCitiesPage.Styles.caption)

			div {
				for (index, marker) in Self.markerColors.enumerated() {
					button(.type(.button), .hook(Hooks.color, value: marker.color), .ariaPressed(index == 0)) {
						span {
							"\(marker.name) marker"
						}
						.style(Styles.swatchName)
					}
					.style(Styles.swatch, Styles.marker)
				}
			}
			.attributes(.part(Parts.shrinkColors), .role("group"))
			.accessibilityLabel("Marker color")
			.style(Styles.swatches)

			div {
				button(.type(.button), .hook(Hooks.tool, value: "draw"), .ariaPressed(true)) {
					"🖊️ Markers"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

				button(.type(.button), .hook(Hooks.tool, value: "cut"), .ariaPressed(false)) {
					"✂️ Scissors"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

				button(.type(.button), .hook(Hooks.tool, value: "punch"), .ariaPressed(false)) {
					"🕳️ Hole Punch"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

				action("shrink-trace", "🦄 Trace Glitter")
			}
			.attributes(.part(Parts.shrinkTools), .role("group"))
			.accessibilityLabel("Tool")
			.style(GeoCitiesPage.Styles.buttonRow)

			canvas(.part(Parts.shrinkCanvas), .width(640), .height(560), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The sheet of shrink plastic, or the oven. Move with the arrow keys, and hold Space to draw or cut. Press Enter to punch the hole, or to look in the oven.")
				.style(Styles.canvas, Styles.drawingCanvas)

			div {
				action("shrink-bake", "🔥 Into the Oven")
				action("shrink-out", "🧤 Take It Out!", isDisabled: true)
				action("shrink-new", "📄 New Sheet")
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.shrinkStatus), .role("status")) {}
				.style(Styles.status)

			canvas(.part(Parts.keyring), .width(640), .height(220), .tabindex(0), .role("application")) {}
				.accessibilityLabel("My school bag, with the shrink plastic charms on the keyring. Press Delete to take off the newest one.")
				.style(Styles.canvas, Styles.displayCanvas)
		}
		.style(Styles.toy)
	}

	// MARK: Parts

	private func action(_ id: String, _ title: String, isDisabled: Bool = false) -> some HTML {
		button(.type(.button), .hook(Hooks.action, value: id)) {
			title
		}
		.attributes(.disabled, when: isDisabled)
		.style(GeoCitiesPage.Styles.smallButton, Styles.dimmedWhenDisabled)
	}

	private func window(_ title: String, @HTMLBuilder content: () -> some HTML) -> some HTML {
		section(.tabindex(-1)) {
			h3 {
				title
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				content()
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window)
	}

	/**
	The color of a swatch, which the script sets from its `data-crafts-color`.
	*/
	static let swatchColor = StyleVariable<Color>("--crafts-swatch")

	enum Parts: String, ElementPartSet {
		case sound

		case hamaBoard
		case hamaPattern
		case hamaColors
		case hamaTools
		case hamaCanvas
		case hamaStatus
		case fridge

		case snowFolds
		case snowPaper
		case snowCanvas
		case snowStatus
		case kitchenWindow

		case spiroRing
		case spiroWheel
		case spiroHole
		case spiroColors
		case spiroCanvas
		case spiroStatus

		case shrinkColors
		case shrinkTools
		case shrinkCanvas
		case shrinkStatus
		case keyring
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The color of a swatch, like `#c81f2b`, or `mixed` for a handful of beads from the tub, or `four` for the four-color pen.
		*/
		case color = "data-crafts-color"

		/**
		A tool of a craft, like `tweezers` or `punch`.
		*/
		case tool = "data-crafts-tool"

		/**
		What a button of a craft does, like `hama-iron`.
		*/
		case action = "data-crafts-action"
	}

	enum Styles: ElementStyleSet {
		case root
		case toys
		case toy
		case toolbar
		case swatches
		case swatch
		case bead
		case pen
		case marker
		case mixed
		case swatchName
		case toggle
		case holdButton
		case canvas
		case drawingCanvas
		case displayCanvas
		case status
		case dimmedWhenDisabled

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .toys:
				Style()
					.grid(minimumColumnWidth: .rootEm(20))
					.gap(.rootEm(1.25))
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .toy:
				Style().vstack(spacing: .rootEm(0.5))
			case .toolbar:
				Style().vstack(spacing: .rootEm(0.375))
			case .swatches:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .swatch:
				// Big enough for a finger, with a thick black ring while it is chosen.
				Style()
					.position(.relative)
					.frame(width: .rootEm(2), height: .rootEm(2))
					.background(GeoCitiesCrafts.swatchColor.value(default: .white))
					.border(Color("#00000066"), width: .pixels(1))
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
					.when(.state, is: "on") {
						$0
							.border(.black, width: .pixels(3))
							.scaleEffect(1.12)
					}
			case .bead:
				// A glossy bead seen from above, with the hole in the middle and a shine at the top.
				Style()
					.cornerRadius(.circle)
					.backgroundImage(
						.radialGradient("circle at 35% 30%", Color("#ffffffcc"), .transparent, .transparent, .transparent),
						.radialGradient("circle", Color("#00000080"), Color("#00000080"), .transparent, .transparent, .transparent, .transparent, .transparent)
					)
			case .pen:
				// A ballpoint pen seen from the end.
				Style()
					.cornerRadius(.circle)
					.border(Color("#555555"), width: .pixels(3), style: .double)
			case .marker:
				// The cap of a marker.
				Style()
					.cornerRadius(.rootEm(0.5))
					.backgroundImage(.linearGradient("to right", Color("#ffffff55"), .transparent, Color("#00000033")))
			case .mixed:
				Style().backgroundImage(.linearGradient("135deg", Color("#c81f2b"), Color("#f6cf1d"), Color("#1f8a3d"), Color("#1f3f96"), Color("#f39cbf")))
			case .swatchName:
				Style().visuallyHidden()
			case .toggle:
				Style().when(.state, is: "on") {
					$0
						.background(Color("#ffcc66"))
						.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
				}
			case .holdButton:
				// A finger that moves a little while it holds the button keeps turning the wheel, instead of scrolling the page and letting go.
				Style()
					.touchAction(.none)
					.textSelection(.disabled)
			case .canvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.background(Color("#e9e6dc"))
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .drawingCanvas:
				// A finger draws, cuts, and irons on the canvas instead of scrolling the page.
				Style()
					.touchAction(.none)
					.cursor(.crosshair)
			case .displayCanvas:
				// Only a tap takes something down, so a finger can still scroll the page.
				Style().touchAction(.manipulation)
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .dimmedWhenDisabled:
				// The small buttons of the page have no look of their own when they do nothing.
				Style().disabled {
					$0.opacity(0.5)
				}
			}
		}
	}
}
