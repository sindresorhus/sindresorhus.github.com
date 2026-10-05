import Elementary
import Foundation
import SiteKit

/**
The Effect Toy Box: the effects of the demos of the 1990s as toys, each in a window: a lava lamp with metaballs, a kaleidoscope to draw in, a fire to draw flames and burn words in, a plasma to stir, a bump map with a flashlight, Fractint to zoom into the Mandelbrot set, a voxel landscape to fly over, shadebobs, a disco floor, a moiré, a cube with the GIFs of the page on its faces, and a bouncing logo that sometimes hits the corner. Its script, `EffectToys.js`, runs each only while it is on the screen and the tab is visible. For visitors who prefer reduced motion, each shows a still picture, which changes only when the visitor does something.
*/
struct GeoCitiesEffectToys: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	A toy of the box, with the part of its canvas, which the script knows it by.
	*/
	struct Toy {
		let id: Parts
		let title: String
		let caption: String

		/**
		What a screen reader says for the canvas.
		*/
		let label: String

		let width: Int
		let height: Int

		/**
		How the toy takes a finger: `.none` for a toy to draw on, and `.panY` for a toy that a finger taps or drags sideways, so the page still scrolls over it.
		*/
		let touch: TouchAction

		/**
		Whether the canvas takes the arrow keys, which the label then explains.
		*/
		var takesKeys = false

		/**
		Whether the toy is drawn in big square pixels.
		*/
		var isPixelArt = true

		/**
		The buttons of the toy, by what they do in the script.
		*/
		let actions: [(id: String, title: String)]
	}

	/**
	The toys, in the order of the box.
	*/
	static let toys: [Toy] = [
		Toy(id: .lava, title: "Lava Lamp", caption: "The hot wax rises, cools at the top, and sinks. Tap a blob to heat it, or tap the lamp to add one.", label: "A lava lamp with blobs of wax that rise and sink", width: 80, height: 120, touch: .panY, actions: [("color", "Color")]),
		Toy(id: .kaleidoscope, title: "Kaleidoscope", caption: "Draw with the pointer or a finger. It draws by itself when you stop.", label: "A kaleidoscope that mirrors what you draw", width: 240, height: 240, touch: .none, isPixelArt: false, actions: [("mirrors", "More Mirrors"), ("clear", "Shake It")]),
		Toy(id: .fire, title: "Fire!", caption: "Draw flames with the pointer, or burn a word.", label: "A fire that you can draw flames in", width: 160, height: 100, touch: .none, actions: [("gasoline", "Gasoline"), ("water", "Put It Out")]),
		Toy(id: .plasma, title: "Plasma", caption: "Stir it with the pointer or a finger.", label: "A plasma of colors that moves like a lava of light", width: 160, height: 100, touch: .panY, actions: [("colors", "Colors")]),
		Toy(id: .bump, title: "Flashlight", caption: "A bump map, like in the demos of 1996. Shine the light on it with the pointer.", label: "A waffle and my name in metal, lit by a flashlight", width: 160, height: 100, touch: .panY, actions: [("color", "Light Color")]),
		Toy(id: .fractal, title: "Fractint", caption: "Click to zoom into the Mandelbrot set. My 486 needed all night for this.", label: "The Mandelbrot set. Use the arrow keys to move the cross, and Enter to zoom in.", width: 160, height: 120, touch: .panY, takesKeys: true, actions: [("in", "Zoom In"), ("out", "Zoom Out"), ("cycle", "Color Cycling")]),
		Toy(id: .voxel, title: "Fly Over the Fjord", caption: "Fly a helicopter over a fjord, like in Comanche (1992). Steer with the pointer or the arrow keys.", label: "A landscape of mountains and a fjord, seen from a helicopter. Use the arrow keys to steer and to fly higher or lower.", width: 160, height: 100, touch: .panY, takesKeys: true, actions: [("time", "Time of Day")]),
		Toy(id: .shadebobs, title: "Shadebobs", caption: "Draw with the pointer. The colors go around and around.", label: "Shadebobs that leave trails of colors", width: 160, height: 120, touch: .none, actions: [("bobs", "More Bobs"), ("clear", "Clear")]),
		Toy(id: .disco, title: "Disco Floor", caption: "Dance on it with the pointer or a finger, like in Saturday Night Fever.", label: "A disco floor with tiles that light up", width: 160, height: 160, touch: .panY, actions: [("dance", "Next Dance")]),
		Toy(id: .moire, title: "Moiré", caption: "Move the rings with the pointer. Do not stare at it for too long.", label: "Two sets of rings that make a moiré pattern", width: 160, height: 160, touch: .panY, actions: [("rings", "More Rings")]),
		Toy(id: .cube, title: "Cube of GIFs", caption: "Six GIFs of my page on a cube. Drag it to spin it.", label: "A spinning cube with a GIF of the page on each face", width: 240, height: 240, touch: .panY, isPixelArt: false, actions: [("spin", "Spin!")]),
		Toy(id: .bounce, title: "Bouncing Logo", caption: "It changes color at every wall. Wait for it to hit the corner.", label: "A logo that bounces around the screen", width: 256, height: 192, touch: .panY, actions: [("nudge", "Nudge")]),
	]

	/**
	The GIFs on the faces of the cube.
	*/
	static let cubeGIFs: [GeoCitiesPage.GIF] = [.unicorn, .flyingPig, .dancingBaby, .coolCow, .dancingBanana, .skull]

	var content: some HTML {
		h2 {
			"The Effect Toy Box"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"All the effects from the demos, as toys. Every one of them is real math, done with real pixels, by real me."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			for toy in Self.toys {
				ToyWindow(toy: toy)
			}
		}
		.style(Styles.box, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.status), .role("status")) {}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.centeredText)

		p {
			"The toys need JavaScript. Without it, they are just boxes."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)

		div {
			gif(.buttonModulez, alt: "Modulez")
			gif(.buttonAmigaPower, alt: "Amiga power")
		}
		.style(GeoCitiesPage.Styles.row)

		// The GIFs of the cube, which the script draws on its faces, or their still frames for visitors who prefer reduced motion.
		template(.part(Parts.cubeFaces)) {
			for gif in Self.cubeGIFs {
				img(.src(gif.path), .alt(""), .hook(Hooks.still, value: gif.stillPath.description))
			}
		}

	}

	private func gif(_ gif: GeoCitiesPage.GIF, alt: String = "") -> GeoCitiesPage.GIFImage {
		GeoCitiesPage.GIFImage(gif: gif, alt: alt, style: .gif, project: project)
	}

	/**
	The window of a toy: its canvas, what it does, and its buttons.
	*/
	struct ToyWindow: HTML {
		let toy: Toy

		var body: some HTML {
			div {
				h3 {
					toy.title
				}
				.style(GeoCitiesPage.Styles.titleBar, Styles.windowTitle)

				div {
					canvas(.part(toy.id), .width(toy.width), .height(toy.height), .role(toy.takesKeys ? "application" : "img")) {}
						.attributes(.tabindex(0), when: toy.takesKeys)
						.accessibilityLabel(toy.label)
						.style(Styles.canvas, toy.isPixelArt ? Styles.pixelArt : Styles.smooth, toy.touch == .none ? Styles.drawing : Styles.steering)

					p {
						toy.caption
					}
					.style(GeoCitiesPage.Styles.caption)

					if toy.id == .fractal {
						p(.part(Parts.fractalInfo)) {
							"Zoom 1× ★ Iterations 64"
						}
						.style(GeoCitiesPage.Styles.lcd, Styles.info)
					}

					if toy.id == .bounce {
						p {
							"Corner hits: "
							span(.part(Parts.bounceCount)) {
								"0"
							}
						}
						.style(GeoCitiesPage.Styles.lcd, Styles.info)
					}

					if toy.id == .fire {
						form(.part(Parts.fireForm)) {
							label(.for("geocities-toys-fire-word")) {
								VisuallyHidden("A word to burn")
							}

							input(.id("geocities-toys-fire-word"), .part(Parts.fireWord), .type(.text), .autocomplete("off"), .maxlength(10), .required, .value("WAFFLE"), .custom(name: "spellcheck", value: "false"))
								.style(GeoCitiesPage.Styles.field, Styles.word)

							button(.type(.submit)) {
								"Burn It"
							}
							.style(GeoCitiesPage.Styles.retroButton, Styles.button)
						}
						.style(Styles.buttons)
					}

					div {
						for action in toy.actions {
							button(.type(.button), .hook(Hooks.action, value: "\(toy.id.rawValue):\(action.id)")) {
								action.title
							}
							.style(GeoCitiesPage.Styles.retroButton, Styles.button)
						}
					}
					.style(Styles.buttons)
				}
				.style(GeoCitiesPage.Styles.windowBody, Styles.body)
			}
			.style(GeoCitiesPage.Styles.window, Styles.window)
		}
	}

	enum Parts: String, ElementPartSet {
		case lava
		case kaleidoscope
		case fire
		case plasma
		case bump
		case fractal
		case voxel
		case shadebobs
		case disco
		case moire
		case cube
		case bounce
		case status
		case cubeFaces
		case fractalInfo
		case bounceCount
		case fireForm
		case fireWord
	}

	enum Hooks: String, ScriptHookSet {
		/**
		What a button of a toy does, as the part of the toy and the action, like `fire:gasoline`.
		*/
		case action = "data-demo-action"

		/**
		The still frame of a GIF of the cube.
		*/
		case still = "data-demo-still"
	}

	enum Styles: ElementStyleSet {
		case root
		case box
		case window
		case windowTitle
		case body
		case canvas
		case pixelArt
		case smooth
		case drawing
		case steering
		case info
		case buttons
		case button
		case word

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .box:
				// Two or three windows side by side where there is room.
				Style()
					.grid(minimumColumnWidth: .rootEm(16))
					.gap(.rootEm(1.25))
					.alignItems(.start)
			case .window:
				Style().frame(minWidth: 0)
			case .windowTitle:
				Style()
					.margin(0)
					.font(.regular, weight: .bold)
			case .body:
				Style().textAlign(.center)
			case .canvas:
				Style()
					.display(.block)
					.frame(width: .percent(100))
					.background(.black)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.cursor(.crosshair)
			case .pixelArt:
				Style().imageRendering(.pixelated)
			case .smooth:
				Style().imageRendering(.auto)
			case .drawing:
				Style().touchAction(.none)
			case .steering:
				Style().touchAction(.panY)
			case .info:
				Style().textStyle(.caption, weight: .bold)
			case .buttons:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .button:
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.625))
					.textStyle(.caption, weight: .bold)
			case .word:
				Style()
					.frame(width: .rootEm(8))
					.fontFamily(GeoCitiesPage.impact)
					.textCase(.uppercase)
			}
		}
	}
}
