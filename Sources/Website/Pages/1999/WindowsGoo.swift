import Elementary
import Foundation
import SiteKit

/**
Kai’s Power Goo (MetaTools, 1995) on the desktop of my computer (``GeoCitiesPage/desktop``): a face that melts like liquid under the brush, with the tools of Power Goo on glowing balls on a dark panel, like the interfaces of Kai Krause. The faces are my school photo of 1999 with a laser background, Pappa, a cat, and the Mona Lisa as I copied it in Paint, all drawn by its script, `WindowsGoo.js`. It warps the face, plays the Goo Movie back and forth, undoes, and saves the face as a PNG. It is the content of its window of the desktop.
*/
struct GeoCitiesWindowsGoo: ScriptedElement {
	static let script = ElementScript()

	/**
	The tools of Power Goo, by the ID that the script knows them by, with their names and pictures.
	*/
	private static let tools: [(id: String, name: String, icon: String)] = [
		("smear", "Smear", "✋"),
		("grow", "Grow", "🎈"),
		("shrink", "Shrink", "🤏"),
		("twirl", "Twirl", "🌀"),
		("noodle", "Noodle", "〰️"),
		("smudge", "Smudge", "🫠"),
		("ungoo", "Ungoo", "🧽"),
	]

	/**
	The faces to goo, by the ID that the script draws them by.
	*/
	private static let faces: [(id: String, name: String)] = [
		("sindre", "Me, school photo 1999"),
		("pappa", "Pappa"),
		("cat", "Pus the cat"),
		("mona", "Mona Lisa (copied in Paint)"),
	]

	var content: some HTML {
		div {
			div {
				div {
					label(.for("geocities-goo-face")) {
						"Face:"
					}

					select(.id("geocities-goo-face"), .part(Parts.face)) {
						for face in Self.faces {
							option(.value(face.id)) {
								face.name
							}
						}
					}
					.style(Styles.select)
				}
				.style(GeoCitiesWindows.Styles.wrapRow)

				div {
					label(.for("geocities-goo-size")) {
						"Brush:"
					}

					select(.id("geocities-goo-size"), .part(Parts.size)) {
						for (value, title) in [("24", "Small"), ("40", "Medium"), ("64", "Big")] {
							option(.value(value)) {
								title
							}
							.attributes(.selected, when: value == "40")
						}
					}
					.style(Styles.select)
				}
				.style(GeoCitiesWindows.Styles.wrapRow)
			}
			.style(Styles.options)

			div(.role("group")) {
				for tool in Self.tools {
					button(.type(.button), .hook(Hooks.tool, value: tool.id), .ariaPressed(tool.id == "smear")) {
						span {
							tool.icon
						}
						.accessibilityHidden()
						.style(Styles.toolBall)

						span {
							tool.name
						}
					}
					.style(Styles.tool)
				}
			}
			.accessibilityLabel("Tools")
			.style(Styles.tools)

			canvas(.part(Parts.canvas), .width(256), .height(256), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The face. Drag on it to goo it with the tool. With the keyboard, the arrow keys move the brush, and holding Space down goos.")
				.style(Styles.canvas)

			div {
				for (part, title) in [(Parts.undo, "Undo"), (Parts.reset, "Reset")] {
					button(.part(part), .type(.button)) {
						title
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}

				button(.part(Parts.movie), .type(.button), .ariaPressed(false)) {
					"🎬 Goo Movie"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.save), .type(.button)) {
					"💾 Save as PNG"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesWindows.Styles.wrapRow)

			p(.part(Parts.status), .role("status")) {
				"Pick a tool, and drag on the face. It is like liquid!"
			}
			.style(Styles.status)
		}
		.style(GeoCitiesWindows.Styles.stack, Styles.panel, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Kai’s Power Goo needs JavaScript. Without it, the face stays the same."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case canvas
		case face
		case size
		case undo
		case reset
		case movie
		case save
		case status
	}

	/**
	The tool buttons, with the tool that each one picks.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		A tool of Power Goo, with its ID, like `twirl`.
		*/
		case tool = "data-goo-tool"
	}

	enum Styles: ElementStyleSet {
		case root
		case panel
		case options
		case select
		case tools
		case tool
		case toolBall
		case canvas
		case status

		var style: Style {
			switch self {
			case .root:
				// The panel, or the text for a browser without JavaScript, in the body of its window.
				Style().display(.block)
			case .panel:
				// The dark, stony panel of Power Goo, with light text, like the interfaces of Kai Krause.
				Style()
					.padding(.rootEm(0.5))
					.backgroundImage(.radialGradient("circle at 30% 20%", Color("#5a5048"), Color("#2a2420"), Color("#141010")))
					.border(Color("#000000"), width: .pixels(2), style: .solid)
					.cornerRadius(.rootEm(0.75))
					.color(Color("#f0e6d8"))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .options:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.flexWrap()
			case .select:
				// A white field with black text on the dark panel, so its menu reads well too.
				Style()
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
			case .tools:
				Style()
					.hstack(alignment: .start, justification: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .tool:
				// A tool is a ball that glows while it is picked.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.125))
					.frame(minWidth: .rootEm(3))
					.padding(.rootEm(0.125))
					.background(.transparent)
					.border(.transparent, width: 0)
					.fontFamily(.system)
					.textStyle(.caption)
					.color(Color("#c8bcae"))
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffd27a"), width: .pixels(2), offset: .pixels(1))
					}
					.when(.state, is: "on") {
						$0.color(Color("#ffd27a"))
					}
			case .toolBall:
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(2.25), height: .rootEm(2.25))
					.backgroundImage(.radialGradient("circle at 35% 30%", Color("#a89a8a"), Color("#4a4038"), Color("#1a1410")))
					.cornerRadius(.circle)
					.shadow(Shadow(x: 0, y: .pixels(2), blur: .pixels(3), color: .black))
					.font(.large)
					.when(ancestorHas: ScriptAttribute.state, is: "on") {
						$0
							.backgroundImage(.radialGradient("circle at 35% 30%", Color("#fff2b0"), Color("#e8a020"), Color("#7a3a00")))
							.shadow(Shadow(x: 0, y: 0, blur: .pixels(10), color: Color("#ffb040")))
					}
			case .canvas:
				// The face, square, which a finger goos instead of scrolling the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto, maxWidth: .rootEm(18))
					.aspectRatio(1)
					.margin(horizontal: .auto)
					.background(.black)
					.border(Color("#000000"), width: .pixels(3), style: .solid)
					.cornerRadius(.rootEm(0.5))
					.touchAction(.none)
					.cursor(.crosshair)
					.focusVisible {
						$0.focusRing(Color("#ffd27a"), width: .pixels(2), offset: .pixels(2))
					}
			case .status:
				Style()
					.frame(minHeight: .lineHeight(1))
					.textAlign(.center)
			}
		}
	}
}
