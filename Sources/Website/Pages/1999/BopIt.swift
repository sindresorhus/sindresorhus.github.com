import Elementary
import Foundation
import SiteKit

/**
Bop It!, the toy of Hasbro (1996) that yells commands, and Bop It Extreme (1998), which I borrowed from Trond for “one week” in March. The toy is drawn big on a canvas: the yellow body with the purple bop button, the blue twist crank, and the green pull handle, and for Extreme, the orange flick stick, the red spin wheel, and the speaker of the “Shout it!” of the later ones. When the visitor turns it on, a peppy voice of `speechSynthesis` yells “Bop it!”, “Twist it!”, or “Pull it!” over a drum loop that its script, `BopIt.js`, makes with the Web Audio API, and the visitor does it the right way: a click, a tap, or Space on the button to bop it, a drag in a circle around the crank or an arrow key to twist it, a drag down on the handle or Enter to pull it, a quick flick of the stick to flick it, a swipe across the wheel to spin it, and a click on the speaker (or a real shout into the microphone, if the visitor allows it) to shout it. Each part makes its own sound, and the toy wiggles. The beat speeds up, and a wrong move or a late one ends the round with the fail sound, an “Ohhh!”, and the score said out loud. The best score of each toy is kept in the browser. In Pass It, two to four players with names take turns, the toy says “Pass it!” for the next one, a mistake puts a player out, and the last one left wins. The voice can also speak Norwegian (“Dunk den! Vri den! Dra den!”). Lillesøster wants a turn and plays badly, but loudly. The batteries run down as the visitor plays: the voice gets slow and deep, then the toy dies, until the visitor puts in new batteries one by one. With reduced motion, the toy does not wiggle, but the game works the same. Without scripts, the toy has no batteries.
*/
struct GeoCitiesBopIt: ScriptedElement {
	static let script = ElementScript()

	private static let toys: [(part: Parts, name: String)] = [
		(.classic, "Bop It! (1996)"),
		(.extreme, "Bop It Extreme (1998)"),
	]

	private static let games: [(part: Parts, name: String)] = [
		(.solo, "👤 Solo"),
		(.pass, "👥 Pass It"),
	]

	private static let players: [(name: String, placeholder: String)] = [
		("Sindre", "Sindre"),
		("Trond", "Trond"),
		("", "Mamma"),
		("", "Mormor"),
	]

	var content: some HTML {
		h2 {
			"Bop It! Twist It! Pull It!"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Trond got a Bop It Extreme for his birthday, and I borrowed it for one week (it was in March). It yells at you, and you have to do what it says, faster and faster. Mamma says it is the loudest toy in the house, and she has heard the Furby."
		}

		div {
			section {
				h3 {
					"BOP IT! (Trond’s, do not lose the batteries)"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					choices

					players

					p(.part(Parts.command)) {
						"Press Start!"
					}
					.accessibilityHidden()
					.style(GeoCitiesPage.Styles.lcd, Styles.command)

					canvas(.part(Parts.canvas), .width(480), .height(360), .tabindex(0), .role("application")) {}
						.accessibilityLabel("The Bop It. Space bops it, the left and right arrow keys twist it, Enter or the down arrow key pulls it, the up arrow key flicks it, S spins it, and Y shouts it.")
						.style(Styles.canvas)

					p(.part(Parts.stats)) {
						"Score 0 ★ Best 0 ★ 🔋 100%"
					}
					.style(GeoCitiesPage.Styles.lcd, Styles.stats)

					// The status is right under the toy, so a phone shows it with the toy, and not below the buttons.
					p(.part(Parts.status), .role("status")) {
						"Press Start, and do what the toy says. With sound!"
					}
					.style(Styles.status)

					buttons

					ol(.part(Parts.scoreboard)) {}
						.accessibilityLabel("The players")
						.hidden(when: true)
						.style(Styles.scoreboard)

					help
				}
				.style(GeoCitiesPage.Styles.windowBody)
			}
			.style(GeoCitiesPage.Styles.window, Styles.toy)
		}
		.style(GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Bop It! needs JavaScript. And batteries."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)

	}

	private var choices: some HTML {
		div {
			div {
				for toy in Self.toys {
					button(.part(toy.part), .type(.button), .ariaPressed(toy.part == .classic)) {
						toy.name
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
				}
			}
			.style(Styles.choiceGroup)

			div {
				for game in Self.games {
					button(.part(game.part), .type(.button), .ariaPressed(game.part == .solo)) {
						game.name
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
				}
			}
			.style(Styles.choiceGroup)

			div {
				button(.part(Parts.norwegian), .type(.button), .ariaPressed(false)) {
					"🇳🇴 Norsk Voice"
				}
				.help("The toy yells in Norwegian")
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

				button(.part(Parts.shout), .type(.button), .ariaPressed(false), .disabled) {
					"📢 Add “Shout It!”"
				}
				.help("Only on Bop It Extreme")
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle, Styles.dimmedWhenDisabled)

				button(.part(Parts.microphone), .type(.button), .ariaPressed(false), .disabled) {
					"🎤 Really Shout"
				}
				.help("Uses the microphone, so you shout for real")
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle, Styles.dimmedWhenDisabled)

				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔈 Sound Off"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
			}
			.style(Styles.choiceGroup)
		}
		.style(Styles.choices)
	}

	private var players: some HTML {
		fieldset(.part(Parts.players)) {
			legend {
				"Pass It: two to four players. An empty name sits out."
			}
			.style(GeoCitiesPage.Styles.label)

			div {
				for (index, player) in Self.players.enumerated() {
					label {
						"Player \(index + 1)"
						input(.type(.text), .maxlength(12), .autocomplete("off"), .value(player.name), .placeholder(player.placeholder))
							.style(GeoCitiesPage.Styles.field)
					}
					.style(Styles.playerLabel)
				}
			}
			.style(Styles.playerFields)
		}
		.hidden(when: true)
		.style(Styles.fieldset)
	}

	private var buttons: some HTML {
		div {
			button(.part(Parts.start), .type(.button)) {
				"▶ Start (Sound!)"
			}
			.style(GeoCitiesPage.Styles.retroButton, Styles.start, Styles.dimmedWhenDisabled)

			button(.part(Parts.sister), .type(.button)) {
				"👧 Lillesøster Wants a Turn (Sound!)"
			}
			.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton, Styles.sister, Styles.dimmedWhenDisabled)

			button(.part(Parts.batteries), .type(.button)) {
				"🔋 New Batteries"
			}
			.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton, Styles.batteries, Styles.dimmedWhenDisabled)
		}
		.style(GeoCitiesPage.Styles.buttonRow)
	}

	private var help: some HTML {
		ul {
			li {
				"🟣 Bop it: click or tap the purple button, or press Space."
			}
			li {
				"🔵 Twist it: drag around the blue crank in a circle, or press ← or →."
			}
			li {
				"🟢 Pull it: drag the green handle down, or press Enter or ↓."
			}
			li {
				"🟠 Flick it (Extreme): flick the orange stick to the side, or press ↑."
			}
			li {
				"🔴 Spin it (Extreme): swipe across the red wheel, or press S."
			}
			li {
				"📢 Shout it (Extreme): click the speaker, press Y, or shout into the microphone."
			}
		}
		.style(Styles.help)
	}

	enum Parts: String, ElementPartSet {
		case classic
		case extreme
		case solo
		case pass
		case norwegian
		case shout
		case microphone
		case sound
		case players
		case command
		case canvas
		case stats
		case status
		case start
		case sister
		case batteries
		case scoreboard
	}

	enum Styles: ElementStyleSet {
		case root
		case toy
		case choices
		case choiceGroup
		case toggle
		case fieldset
		case playerFields
		case playerLabel
		case command
		case canvas
		case stats
		case start
		case bigSmallButton
		case sister
		case batteries
		case dimmedWhenDisabled
		case scoreboard
		case status
		case help

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .toy:
				Style()
					.frame(maxWidth: .rootEm(36))
					.margin(.horizontal, .auto)
			case .choices:
				Style().vstack(spacing: .rootEm(0.375))
			case .choiceGroup:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .toggle:
				// Big enough for a thumb, and pressed in while it is on.
				Style()
					.frame(minHeight: .rootEm(2.5))
					.when(.state, is: "on") {
						$0
							.background(Color("#ffff99"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .fieldset:
				Style()
					.margin(0)
					.padding(.rootEm(0.5))
					.border(Color("#808080"), width: .pixels(2), style: .groove)
			case .playerFields:
				Style()
					.grid(minimumColumnWidth: .rootEm(7))
					.gap(.rootEm(0.5))
			case .playerLabel:
				Style()
					.vstack(spacing: .rootEm(0.125))
					.textStyle(.caption, weight: .bold)
			case .command:
				// The big yell of the toy, in the color of the part it wants. It keeps the space of the window above it, so it does not touch the buttons.
				Style()
					.frame(minHeight: .lineHeight(1.25))
					.margin(.bottom, 0)
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge2)
					.textAlign(.center)
					.letterSpacing(.em(0.05))
					.when(.state, is: "bop") {
						$0.color(Color("#d58cff"))
					}
					.when(.state, is: "twist") {
						$0.color(Color("#66b3ff"))
					}
					.when(.state, is: "pull") {
						$0.color(Color("#66ff66"))
					}
					.when(.state, is: "flick") {
						$0.color(Color("#ffaa33"))
					}
					.when(.state, is: "spin") {
						$0.color(Color("#ff5555"))
					}
					.when(.state, is: "shout") {
						$0.color(Color("#ffffff"))
					}
					.when(.state, is: "pass") {
						$0.color(Color("#ffff66"))
					}
					.when(.state, is: "fail") {
						$0
							.background(Color("#550000"))
							.color(Color("#ff6666"))
					}
					.when(.state, is: "dead") {
						$0
							.background(Color("#111111"))
							.color(Color("#335533"))
					}
			case .canvas:
				// The toy, big. A finger on a part twists and pulls it, as the script stops the scroll there, and a finger beside the parts scrolls the page. When the toy comes into view, the yell above it and the status below it come too.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(480.0 / 360.0)
					.background(Color("#2a0a4a"))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.touchAction(.manipulation)
					.scrollMargin(top: .rootEm(3.75), bottom: .rootEm(6.5))
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .stats:
				Style()
					.margin(0)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .start:
				Style().frame(minHeight: .rootEm(2.75))
			case .bigSmallButton:
				Style().frame(minHeight: .rootEm(2.75))
			case .sister:
				// She asks again and again, and the button blinks while she does.
				Style().when(.state, is: "nag") {
					$0
						.background(Color("#ffccee"))
						.media(.allowsMotion) {
							$0.animation(GeoCitiesPage.Animations.blink, .timingCurve("steps(1, end)", duration: .seconds(1)).repeatForever(autoreverses: false))
						}
				}
			case .batteries:
				// Red while the batteries are low or dead.
				Style()
					.when(.state, is: "low") {
						$0.background(Color("#ffcc66"))
					}
					.when(.state, is: "dead") {
						$0
							.background(Color("#ff6666"))
							.color(.white)
					}
			case .dimmedWhenDisabled:
				Style().disabled {
					$0.opacity(0.5)
				}
			case .scoreboard:
				// The players of Pass It, like name tags. The one with the toy is lit, and the ones who are out are gray.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.flexWrap()
					.margin(0)
					.padding(0)
					.children("li") {
						$0
							.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
							.background(.white)
							.border(Color("#808080"), width: .pixels(2), style: .outset)
							.fontFamily(GeoCitiesPage.comicSans)
							.textStyle(.caption, weight: .bold)
							.when(.state, is: "current") {
								$0
									.background(Color("#ffff66"))
									.border(Color("#cc9900"), width: .pixels(2), style: .solid)
							}
							.when(.state, is: "out") {
								$0
									.background(Color("#c0c0c0"))
									.color(Color("#808080"))
									.italic()
							}
							.when(.state, is: "winner") {
								$0
									.background(Color("#ffcc00"))
									.border(Color("#cc0000"), width: .pixels(2), style: .solid)
							}
					}
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .help:
				Style()
					.margin(0)
					.padding(.leading, .rootEm(1))
					.textStyle(.caption)
			}
		}
	}
}
