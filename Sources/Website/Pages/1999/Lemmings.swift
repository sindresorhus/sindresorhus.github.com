import Elementary
import Foundation
import SiteKit

/**
Lemmingz ’99, a game like Lemmings (DMA Design, 1991): little green-haired creatures fall out of a trapdoor and walk on, whatever is in front of them, and the visitor gives them jobs to get them to the exit: digging down, building stairs, bashing through walls, blocking the others, floating down with an umbrella, or exploding with an “Oh no!”. Four levels, each with a number to save, and a big red button that blows them all up. Its script, `Lemmings.js`, runs the game on the canvas and keeps the levels the visitor has reached in the browser. For visitors who prefer reduced motion, the game moves one second for each press of the Step button.
*/
struct GeoCitiesLemmings: ScriptedElement {
	static let script = ElementScript()

	/**
	The jobs of the lemmings, by the ID that the script knows them by, with their names and keys.
	*/
	private static let skills: [(id: String, name: String)] = [
		("dig", "Dig"),
		("build", "Build"),
		("bash", "Bash"),
		("block", "Block"),
		("float", "Float"),
		("bomb", "Bomb"),
	]

	var content: some HTML {
		h2(.part(Parts.title)) {
			"LEMMINGZ.EXE"
		}
		.style(GeoCitiesPage.Styles.titleBar)

		div {
			p {
				"Oh no! The lemmings walk off every cliff on my page. Pick a job, then click a lemming to give it the job. Get enough of them to the exit! With the keyboard: the arrow keys pick a lemming, the keys 1 to 6 pick a job, and Space gives it."
			}

			// On phones, the screen scrolls sideways, like the levels of Lemmings, so a finger can pick a lemming.
			div {
				canvas(.part(Parts.screen), .width(512), .height(288), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The lemmings. The arrow keys pick a lemming, the keys 1 to 6 pick a job, Space gives the job, and P pauses.")
					.style(Styles.screen)
			}
			.style(Styles.scroller, GeoCitiesPage.Styles.scriptingOnly)

			div {
				ForEach(Array(Self.skills.enumerated())) { index, skill in
					button(.type(.button), .hook(Hooks.skill, value: skill.id), .ariaPressed(index == 0)) {
						span(.hook(Hooks.skillCount, value: skill.id)) {
							"0"
						}
						.style(Styles.skillCount)

						span {
							"\(index + 1) \(skill.name)"
						}
					}
					.style(Styles.skill)
				}

				button(.part(Parts.nuke), .type(.button)) {
					span {
						"☢"
					}
					.accessibilityHidden()
					.style(Styles.skillCount)

					span {
						"Nuke"
					}
				}
				.style(Styles.skill, Styles.nuke)
			}
			.style(Styles.skills, GeoCitiesPage.Styles.scriptingOnly)

			div {
				button(.part(Parts.pause), .type(.button), .ariaPressed(false)) {
					"Pause"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.step), .type(.button)) {
					"Step"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.restart), .type(.button)) {
					"Restart level"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.next), .type(.button), .hidden) {
					"Next level"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				label {
					"Level: "
					select(.part(Parts.level)) {}
				}
			}
			.style(GeoCitiesPage.Styles.buttonRow, GeoCitiesPage.Styles.scriptingOnly)

			p(.part(Parts.status), .role("status")) {}
				.style(Styles.status, GeoCitiesPage.Styles.scriptingOnly)

			p {
				"The lemmings need JavaScript. Without it, they all walked off a cliff. Oh no!"
			}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
		}
		.style(GeoCitiesPage.Styles.windowBody)
	}

	enum Parts: String, ElementPartSet {
		case title
		case screen
		case nuke
		case pause
		case step
		case restart
		case next
		case level
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The button of a job, with its ID, like `dig`.
		*/
		case skill = "data-lemmings-skill"

		/**
		How many of a job are left, with its ID.
		*/
		case skillCount = "data-lemmings-count"
	}

	enum Styles: ElementStyleSet {
		case root
		case scroller
		case screen
		case skills
		case skill
		case skillCount
		case nuke
		case status

		var style: Style {
			switch self {
			case .root:
				// The window that was a section. A custom element is inline by default, so it is a block.
				GeoCitiesPage.Styles.window.style.display(.block)
			case .scroller:
				Style()
					.overflow(horizontal: .auto)
					.lineHeight(0)
			case .screen:
				// A black screen of big pixels.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto, minWidth: .pixels(512))
					.aspectRatio(16.0 / 9.0)
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.imageRendering(.pixelated)
					.touchAction(.manipulation)
					.cursor(.crosshair)
			case .skills:
				// The panel of jobs at the bottom of the screen, like in Lemmings.
				Style()
					.grid(columns: 4)
					.gap(.pixels(2))
					.padding(.pixels(2))
					.background(Color("#202060"))
					.from(.smallTablet) {
						$0.grid(columns: 7)
					}
			case .skill:
				// A job, with how many are left above its name. It is pressed in while it is picked.
				Style()
					.vstack(alignment: .center, spacing: 0)
					.padding(.rootEm(0.25))
					.background(Color("#4040a0"))
					.border(Color("#8080ff"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.white)
					.handCursor()
					.active {
						$0.border(Color("#8080ff"), width: .pixels(2), style: .inset)
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#8080ff"))
							.border(Color("#c0c0ff"), width: .pixels(2), style: .inset)
					}
			case .skillCount:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.font(.large, weight: .heavy)
					.color(Color("#66ff66"))
			case .nuke:
				Style().background(Color("#a02020"))
			case .status:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			}
		}
	}
}
