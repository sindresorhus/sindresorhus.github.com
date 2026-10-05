import Elementary
import SiteKit

/**
Sindre’s Music Room: the music toys of 1999, made live with the sound card. It starts with the mixer of a Sound Blaster, with a speaker test that asks if the visitor heard it, and then has WaffleJay (a sequencer like Dance eJay), a Winamp visualizer, a Casio keyboard, a ringtone composer of a Nokia 3210, a tracker like FastTracker 2, a stamp composer like the one of a painting game from 1992, a hamster band, a karaoke machine, and a DJ booth with a turntable, an air horn, and a theremin. Each toy is a custom element with its own script, and they all play through one audio context, the sound card of `geocities-sound-card.js`. Nothing plays until the visitor presses something that plays sound, the volume starts low, one tune plays at a time, and the music stops when the visitor leaves the tab.
*/
struct GeoCitiesMusicRoom: HTML {
	let project: Project

	var body: some HTML {
		Mixer(project: project)

		GeoCitiesPage.Deferred(GeoCitiesWaffleJay())

		GeoCitiesPage.Deferred(GeoCitiesVisualizer())

		GeoCitiesPage.Deferred(GeoCitiesCasio(project: project))

		GeoCitiesPage.Deferred(GeoCitiesRingtones())

		GeoCitiesPage.Deferred(GeoCitiesTracker())

		GeoCitiesPage.Deferred(GeoCitiesStampComposer(project: project))

		GeoCitiesPage.Deferred(GeoCitiesHamsterBand(project: project))

		GeoCitiesPage.Deferred(GeoCitiesKaraoke(project: project))

		GeoCitiesPage.Deferred(GeoCitiesDJBooth(project: project))
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The ID of the mixer, which the “Music Room” button of the site map jumps to.
		*/
		case root = "geocities-music"
	}

	/**
	The mixer of a Sound Blaster at the start of the Music Room, with a speaker test that asks if the visitor heard it, and a button that stops all the music of the room.
	*/
	struct Mixer: ScriptedElement {
		static let script = ElementScript()

		let project: Project

		var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
			[.id(GeoCitiesMusicRoom.Hooks.root)]
		}

		var content: some HTML {
			h2 {
				GeoCitiesPage.GIFImage(gif: .speakerNotes, alt: "", style: .gif, project: project)
				" Sindre’s Music Room "
				GeoCitiesPage.GIFImage(gif: .speakerNotes, alt: "", style: .gif, project: project)
			}
			.style(Styles.title)

			p {
				"I make music on my computer! Every sound here is made live by my sound card. Press a button that plays sound, and turn up the speakers (not too much, Mamma is sleeping)."
			}
			.style(GeoCitiesPage.Styles.centeredText)

			div {
				p {
					"Sound Blaster Live! Mixer"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					GeoCitiesMusicVolume()

					p {
						"Speaker test: "
						button(.type(.button), .hook(Hooks.speaker, value: "left")) {
							"◀ Left"
						}
						.accessibilityLabel("Test the left speaker")
						.style(GeoCitiesPage.Styles.retroButton)
						" "
						button(.type(.button), .hook(Hooks.speaker, value: "right")) {
							"Right ▶"
						}
						.accessibilityLabel("Test the right speaker")
						.style(GeoCitiesPage.Styles.retroButton)
					}
					.style(GeoCitiesPage.Styles.formRow)

					p(.part(Parts.status), .role("status")) {}
						.style(Styles.status)

					div(.part(Parts.question), .hidden) {
						"Did you hear it? "
						button(.type(.button), .hook(Hooks.answer, value: "yes")) {
							"Yes"
						}
						.style(GeoCitiesPage.Styles.retroButton)
						" "
						button(.type(.button), .hook(Hooks.answer, value: "no")) {
							"No"
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
					.style(GeoCitiesPage.Styles.formRow)

					p {
						button(.part(Parts.stopAll), .type(.button)) {
							"■ Stop all music"
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
				}
				.style(GeoCitiesPage.Styles.windowBody)
			}
			.style(GeoCitiesPage.Styles.window, Styles.mixer, GeoCitiesPage.Styles.scriptingOnly)

			p {
				"The Music Room needs JavaScript and a sound card. Without them, it is the Silence Room."
			}
			.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
		}

		enum Parts: String, ElementPartSet {
			case status
			case question
			case stopAll
		}

		enum Hooks: String, ScriptHookSet {
			/**
			A button that plays the test sound in one speaker, `left` or `right`.
			*/
			case speaker = "data-music-speaker"

			/**
			An answer to “Did you hear it?”, `yes` or `no`.
			*/
			case answer = "data-music-answer"
		}

		enum Styles: ElementStyleSet {
			case root
			case title
			case mixer
			case status

			var style: Style {
				switch self {
				case .root:
					GeoCitiesPage.Styles.section.style
				case .title:
					// Big and purple with a yellow shadow, like the title of a page about a band.
					Style()
						.textAlign(.center)
						.fontFamily(GeoCitiesPage.impact)
						.font(.extraLarge3)
						.color(Color("#6600cc"))
						.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#ffcc00")))
				case .mixer:
					Style()
						.frame(maxWidth: .rootEm(30))
						.margin(.horizontal, .auto)
				case .status:
					Style()
						.frame(minHeight: .lineHeight(1))
						.fontWeight(.bold)
						.color(Color("#000080"))
				}
			}
		}
	}
}

/**
The volume slider of the Music Room. Each toy has one, and they all move together, as they set the same volume.
*/
struct GeoCitiesMusicVolume: HTML {
	var body: some HTML {
		label {
			span {
				"🔊 Volume"
			}

			input(.type(.range), .min(0), .max(100), .step(1), .value("30"), .hook(Hooks.volume))
				.style(Styles.slider)
		}
		.style(Styles.volume)
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A volume slider, from 0 to 100.
		*/
		case volume = "data-music-volume"
	}

	enum Styles: StyleSet {
		case volume
		case slider

		var style: Style {
			switch self {
			case .volume:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .slider:
				Style()
					.frame(width: .rootEm(8), minWidth: 0)
					.flexShrink(1)
					.handCursor()
			}
		}
	}
}
