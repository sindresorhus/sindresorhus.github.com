import Elementary
import SiteKit

/**
A karaoke machine with a bouncing ball, like the sing-along cartoons of Max Fleischer (1924) and the karaoke machines of the 1990s: it plays one of two silly songs of my own, and a ball bounces from word to word of the lyrics. It has the button every karaoke machine needs, Key Change, which moves the song up like the last chorus of a boy band, an Echo knob, a melody to follow that can be turned off, and three judges who give points at the end. Its script plays the songs through the sound card of the Music Room and moves the ball. For visitors who prefer reduced motion, the ball does not bounce, and the words light up instead.
*/
struct GeoCitiesKaraoke: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	The songs, by their ID in the script.
	*/
	static let songs: [(id: String, title: String)] = [
		("modem", "My Modem Loves Me"),
		("waffles", "Waffles on a Sunday"),
	]

	var content: some HTML {
		h2 {
			"Sing-Along-O-Matic 2000"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"Karaoke night at my house! Pick a song, press Sing, and follow the bouncing ball. Press Key Change for the big finish. My little sister always turns the echo all the way up."
		}

		div {
			div {
				div {
					GeoCitiesPage.GIFImage(gif: .singingMicrophone, alt: "", style: .gif, project: project)
				}
				.style(Styles.decoration)

				div {
					p(.part(Parts.songTitle)) {
						"♪ Pick a song and press Sing! ♪"
					}
					.style(Styles.songTitle)

					div {
						span(.part(Parts.ball)) {}
							.accessibilityHidden()
							.style(Styles.ball)

						p(.hook(Hooks.line, value: "0")) {}
							.style(Styles.line)

						p(.hook(Hooks.line, value: "1")) {}
							.style(Styles.line)
					}
					.style(Styles.lyrics)

					p(.part(Parts.banner), .hidden) {
						"KEY CHANGE!"
					}
					.accessibilityHidden()
					.style(Styles.banner)
				}
				.style(Styles.screen)

				div {
					GeoCitiesPage.GIFImage(gif: .boombox, alt: "", style: .gif, project: project)
				}
				.style(Styles.decoration)
			}
			.style(Styles.machine)

			div {
				for song in Self.songs {
					button(.type(.button), .hook(Hooks.song, value: song.id)) {
						"🎤 Sing “\(song.title)”"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}

				button(.part(Parts.keyChange), .type(.button), .disabled) {
					"⬆ Key Change!"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.stop), .type(.button), .disabled) {
					"■ Stop"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.formRow)

			div {
				label {
					"🔁 Echo "
					input(.part(Parts.echo), .type(.range), .min(0), .max(100), .step(1), .value("25"))
				}
				.style(Styles.knob)

				label {
					input(.part(Parts.guide), .type(.checkbox), .checked)
					" Play the melody"
				}
				.style(Styles.knob)

				GeoCitiesMusicVolume()
			}
			.style(GeoCitiesPage.Styles.formRow)

			div(.part(Parts.judges), .hidden, .role("status")) {}
				.style(Styles.judges)
		}
		.style(Styles.box, GeoCitiesPage.Styles.scriptingOnly)
	}

	enum Parts: String, ElementPartSet {
		case songTitle
		case ball
		case banner
		case keyChange
		case stop
		case echo
		case guide
		case judges
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A line of the lyrics on the screen, the first or the second.
		*/
		case line = "data-karaoke-line"

		/**
		A button that sings a song, by its ID.
		*/
		case song = "data-karaoke-song"
	}

	enum Styles: ElementStyleSet {
		case root
		case box
		case machine
		case decoration
		case screen
		case songTitle
		case lyrics
		case line
		case ball
		case banner
		case knob
		case judges

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .box:
				Style()
					.flowSpacing(.rootEm(0.75))
					.padding(.rootEm(0.75))
					.background(Color("#1a0033"))
					.border(Color("#ff33cc"), width: .pixels(4), style: .double)
					.color(.white)
					.children("p, label") {
						$0.color(.white)
					}
			case .machine:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
			case .decoration:
				// The microphone and the boombox only fit next to the screen on larger screens.
				Style()
					.flexShrink(0)
					.hidden(below: .tablet)
			case .screen:
				// The blue screen of a karaoke video, with the words in big white letters.
				Style()
					.position(.relative)
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flex(1)
					.frame(minWidth: 0, minHeight: .rootEm(11))
					.padding(.rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#000066"), Color("#3333cc"), Color("#000066")))
					.border(Color("#888"), width: .pixels(6), style: .ridge)
					.cornerRadius(.rootEm(0.75))
					.textAlign(.center)
			case .songTitle:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(Color("#ffff66"))
			case .lyrics:
				Style()
					.position(.relative)
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.top, .rootEm(1.5))
			case .line:
				// Each word is white, and turns yellow once it is sung.
				Style()
					.frame(minHeight: .lineHeight(1))
					.fontFamily(GeoCitiesPage.impact)
					.font(.large)
					.from(.tablet) {
						$0.font(.extraLarge)
					}
					.letterSpacing(.em(0.03))
					.color(.white)
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: .black))
					.children("span") {
						$0.when(.state, is: "sung") {
							$0.color(Color("#ffee00"))
						}
					}
			case .ball:
				// The bouncing ball, red and shiny, which the script moves over the words.
				Style()
					.position(.absolute)
					.top(0)
					.leading(0)
					.frame(width: .rootEm(1), height: .rootEm(1))
					.backgroundImage(.radialGradient("circle at 35% 35%", Color("#ffaaaa"), Color("#ee0000"), Color("#880000")))
					.cornerRadius(.percent(50))
					.opacity(0)
					.when(.state, is: "on") {
						$0.opacity(1)
					}
					.reducedMotion {
						$0.hidden()
					}
			case .banner:
				Style()
					.position(.absolute)
					.top(.percent(40))
					.leading(0)
					.frame(width: .percent(100))
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge3)
					.color(Color("#ff33cc"))
					.textShadow(Shadow(x: .pixels(3), y: .pixels(3), color: Color("#ffff00")))
					.rotationEffect(.degrees(-6))
			case .knob:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .judges:
				Style()
					.padding(.rootEm(0.75))
					.background(Color("#ffff99"))
					.border(Color("#ff33cc"), width: .pixels(3))
					.fontFamily(GeoCitiesPage.comicSans)
					.color(.black)
					.flowSpacing(.rootEm(0.375))
					.children("p") {
						$0.color(.black)
					}
			}
		}
	}
}
