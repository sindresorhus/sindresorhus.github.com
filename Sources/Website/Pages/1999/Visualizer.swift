import Elementary
import SiteKit

/**
A visualizer plugin for Winamp, like the Geiss plugin (1998) and the Advanced Visualization Studio that came after it: a black screen that dances to every sound of the Music Room, with presets, effects to turn on and off (trails, a mirror, a flash on the beat, rainbow colors), a random preset, and full screen. Its script draws it from the sound of the room, only while it is on the screen and the tab is visible. For visitors who prefer reduced motion, it shows a still picture of the preset.
*/
struct GeoCitiesVisualizer: ScriptedElement {
	static let script = ElementScript()

	/**
	The presets, by their ID in the script, with their titles.
	*/
	static let presets: [(id: String, title: String)] = [
		("scope", "Superscope Spiral"),
		("fire", "Spectrum Fire"),
		("tunnel", "Unicorn Tunnel"),
		("stars", "Starfield Beat"),
		("waves", "Oscilloscope"),
	]

	/**
	The effects that can be turned on, by their ID in the script.
	*/
	static let effects: [(id: String, title: String, isOn: Bool)] = [
		("trails", "Trails", true),
		("mirror", "Mirror", false),
		("flash", "Flash on beat", false),
		("rainbow", "Rainbow", true),
	]

	var content: some HTML {
		h2 {
			"vis_waffle.dll"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"My own visualizer plugin for Winamp. It dances to everything in the Music Room. Play something, then come back here and stare at it for an hour."
		}

		div {
			p {
				"Winamp Visualization - vis_waffle.dll v0.99"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				canvas(.part(Parts.canvas), .width(320), .height(200), .role("img")) {}
					.accessibilityLabel("The visualizer")
					.style(Styles.screen)

				div {
					for (index, preset) in Self.presets.enumerated() {
						button(.type(.button), .hook(Hooks.preset, value: preset.id), .ariaPressed(index == 0)) {
							preset.title
						}
						.style(Styles.preset)
					}
				}
				.attributes(.role("group"))
				.accessibilityLabel("Presets")
				.style(GeoCitiesPage.Styles.formRow)

				div {
					for effect in Self.effects {
						label {
							input(.type(.checkbox), .hook(Hooks.effect, value: effect.id))
								.attributes(.checked, when: effect.isOn)
							" \(effect.title)"
						}
						.style(Styles.effect)
					}
				}
				.style(GeoCitiesPage.Styles.formRow)

				div {
					button(.part(Parts.random), .type(.button)) {
						"🎲 Random"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					button(.part(Parts.fullScreen), .type(.button)) {
						"⛶ Full screen"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(GeoCitiesPage.Styles.formRow)

				p(.part(Parts.status), .role("status")) {}
					.style(GeoCitiesPage.Styles.caption)
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window, Styles.window, GeoCitiesPage.Styles.scriptingOnly)
	}

	enum Parts: String, ElementPartSet {
		case canvas
		case random
		case fullScreen
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button of a preset, by its ID.
		*/
		case preset = "data-visualizer-preset"

		/**
		A checkbox of an effect, by its ID.
		*/
		case effect = "data-visualizer-effect"
	}

	enum Styles: ElementStyleSet {
		case root
		case window
		case screen
		case preset
		case effect

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .window:
				Style()
					.frame(maxWidth: .rootEm(36))
					.margin(.horizontal, .auto)
			case .screen:
				// Big blocky pixels, like a visualizer of 1999 at 320 × 200.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(16.0 / 10.0)
					.background(.black)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.imageRendering(.pixelated)
			case .preset:
				// A small dark button with green text, like the buttons of Winamp, lit while it is the preset.
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Color("#29293d"))
					.border(Color("#5a5a7a"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#00e000"))
					.handCursor()
					.when(.state, is: "on") {
						$0
							.border(Color("#5a5a7a"), width: .pixels(2), style: .inset)
							.color(Color("#ffff66"))
					}
			case .effect:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption)
			}
		}
	}
}
