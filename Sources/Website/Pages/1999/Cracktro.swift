import Elementary
import Foundation
import SiteKit

/**
The intro of TEAM WAFFLE, the demo group of Sindre and Trond, for The Gathering 1999 in Hamar: a cracktro on a screen of 320 × 200 pixels, like mode 13h of a PC, in seven parts: copper bars with a 3D starfield and a wobbling logo, a glenz vector over a plasma, a tunnel of waffle, a rotozoomer of a unicorn, vector balls that change shape, Kefrens bars with a twister, and the credits over a fire. A sine scroller with greetings runs along the bottom, and the visitor can write their own. The remote control changes the part, the speed, and the colors, plays a chiptune, and runs it full screen, and too much speed crashes it with a Guru Meditation of the Amiga. Its script, `Cracktro.js`, draws it only while it is on the screen and the tab is visible, and shows a still frame of each part to visitors who prefer reduced motion.
*/
struct GeoCitiesCracktro: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	The buttons of the remote control, by the part that the script knows them by.
	*/
	private static let controls: [(control: Parts, title: String)] = [
		(.previous, "◀ Previous Part"),
		(.next, "Next Part ▶"),
		(.faster, "Faster!"),
		(.colors, "More Colors"),
		(.pause, "Pause"),
		(.music, "♪ Play Music"),
		(.fullscreen, "Full Screen"),
	]

	/**
	The ID that the “Demos” button of the site map jumps to.
	*/
	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id("geocities-cracktro")]
	}

	var content: some HTML {
		h2 {
			"★ TEAM WAFFLE Presents ★"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Me and Trond started a demo group! This is our first intro, for the demo competition at The Gathering 1999 in Vikingskipet, Hamar. It runs in 320 × 200 with 256 colors, like a real one, and it has music. We did not win. Spaceballs won. Spaceballs always wins."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			div {
				canvas(.part(Parts.screen), .width(320), .height(200), .role("img")) {}
					.accessibilityLabel("The intro of TEAM WAFFLE, with copper bars, plasma, a tunnel, a spinning unicorn, and a scroller with greetings")
					.style(Styles.screen)

				// The script shows it when the visitor makes the intro too fast, like the crash screen of the Amiga.
				button(.part(Parts.guru), .type(.button), .hidden) {
					span {
						"Software Failure. Press left mouse button to continue."
					}

					span {
						"Guru Meditation #00000004.0000AAC0"
					}
				}
				.style(Styles.guru)
			}
			.style(Styles.stack)

			p(.part(Parts.part)) {
				"PART 1/7: COPPER BARS"
			}
			.accessibilityHidden()
			.style(GeoCitiesPage.Styles.lcd, Styles.part)
		}
		.style(Styles.monitor, GeoCitiesPage.Styles.scriptingOnly)

		div {
			for item in Self.controls {
				button(.part(item.control), .type(.button)) {
					item.title
				}
				.style(GeoCitiesPage.Styles.retroButton, Styles.control)
			}
		}
		.style(Styles.remote, GeoCitiesPage.Styles.scriptingOnly)

		form(.part(Parts.form)) {
			label(.for("geocities-cracktro-text")) {
				"Write your own scroller (greetings are mandatory):"
			}
			.style(GeoCitiesPage.Styles.label)

			div {
				input(.id("geocities-cracktro-text"), .part(Parts.text), .type(.text), .autocomplete("off"), .maxlength(140), .custom(name: "spellcheck", value: "false"), .placeholder("Greetings to my cat and all elite web masters"))
					.style(GeoCitiesPage.Styles.field)

				button(.type(.submit)) {
					"Scroll It!"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(Styles.formRow)
		}
		.style(Styles.form, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.status), .role("status")) {}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.centeredText)

		p {
			"The intro needs JavaScript. Imagine copper bars. Now imagine them moving."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)

		div {
			gif(.buttonAmigaDemo, alt: "Amiga demoscene archive")
			gif(.buttonAmigaPower, alt: "Amiga power")
			gif(.buttonSceneOrg, alt: "scene.org")
			gif(.buttonDOS, alt: "DOS page")
			gif(.buttonModPlug, alt: "This site uses MODplug")
		}
		.style(GeoCitiesPage.Styles.row)

		// The unicorn of the rotozoomer, which the script draws into a texture.
		template(.part(Parts.texture)) {
			img(.src(GeoCitiesPage.GIF.unicorn.stillPath), .alt(""))
		}
	}

	private func gif(_ gif: GeoCitiesPage.GIF, alt: String = "") -> GeoCitiesPage.GIFImage {
		GeoCitiesPage.GIFImage(gif: gif, alt: alt, style: .gif, project: project)
	}

	enum Parts: String, ElementPartSet {
		case screen
		case guru
		case part
		case previous
		case next
		case faster
		case colors
		case pause
		case music
		case fullscreen
		case form
		case text
		case status
		case texture
	}

	enum Styles: ElementStyleSet {
		case root
		case monitor
		case stack
		case screen
		case guru
		case part
		case remote
		case control
		case form
		case formRow

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .monitor:
				// A big CRT monitor in dark plastic, like at a demo party.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(maxWidth: .pixels(680))
					.margin(.horizontal, .auto)
					.padding(.rootEm(0.75))
					.background(Color("#2b2b2b"))
					.border(Color("#555555"), width: .pixels(4), style: .outset)
					.cornerRadius(.rootEm(1))
			case .stack:
				Style()
					.display(.grid)
					.frame(width: .percent(100))
					.border(.black, width: .pixels(4))
					.cornerRadius(.rootEm(0.5))
					.overflow(.hidden)
					.background(.black)
			case .screen:
				// The intro is drawn at 320 × 200 and shown larger with square pixels, like a PC in mode 13h on a big monitor.
				Style()
					.stackedInGrid()
					.display(.block)
					.frame(width: .percent(100))
					.imageRendering(.pixelated)
			case .guru:
				// The red box of the crash screen of the Amiga, which blinks once a second.
				Style()
					.stackedInGrid()
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(.black)
					.border(Color("#ff2200"), width: .pixels(6))
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .clamp(.pixels(12), .viewportWidth(2.6), .pixels(20)))
					.fontWeight(.bold)
					.color(Color("#ff2200"))
					.textAlign(.center)
					.handCursor()
					.media(.allowsMotion) {
						$0.animation(Animations.blink, .timingCurve("steps(1, end)", duration: .seconds(1)).repeatForever(autoreverses: false))
					}
			case .part:
				Style()
					.frame(width: .percent(100))
					.textAlign(.center)
					.textStyle(.caption, weight: .bold)
			case .remote:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .control:
				Style().padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.75))
			case .form:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.frame(maxWidth: .pixels(680))
					.margin(.horizontal, .auto)
			case .formRow:
				// The field gets narrower on a phone, not the button.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.children("button") {
						$0.flexShrink(0)
					}
			}
		}
	}

	enum Animations: KeyframeSet {
		case blink

		var keyframes: [Keyframe] {
			switch self {
			case .blink:
				[.at(50, Style().borderColor(.black))]
			}
		}
	}
}
