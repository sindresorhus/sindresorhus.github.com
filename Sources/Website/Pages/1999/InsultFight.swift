import Elementary
import Foundation
import SiteKit

/**
Insult Seagull Fighting, an extra of my adventure games, like the insult sword fighting of The Secret of Monkey Island (1990), with the seagulls of the fish market and their Sea Gull Master. Whoever is insulted must answer with the comeback that fits, or lose the round, and a fight is first to three rounds. Sindre learns each insult that a seagull uses on him, and each comeback that a seagull answers him with, and when he knows enough comebacks, the Sea Gull Master fights him with insults of her own that fit the same comebacks. Its script, `InsultFight.js`, runs it, keeps what Sindre learned in the browser, and makes the sounds of the fight when the sound button of my adventure game (``GeoCitiesAdventure``) is on.
*/
struct GeoCitiesInsultFight: ScriptedElement {
	static let script = ElementScript()

	var content: some HTML {
		h2 {
			"Insult Seagull Fighting"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"In Monkey Island, pirates fight with insults. At the fish market in Bergen, the seagulls do. When a seagull insults you, pick the comeback that fits. When it is your turn, insult back. You learn new insults and comebacks from every seagull, and when you know enough, the Sea Gull Master of Fisketorget will fight you."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			h3 {
				"⚔ Insult Seagull Fighting"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				canvas(.part(Parts.canvas), .width(200), .height(80), .role("img")) {}
					.accessibilityLabel("Sindre with an umbrella and a seagull with a mackerel, fighting on the quay of the fish market.")
					.style(Styles.fightCanvas)

				p(.part(Parts.tally)) {
					"Sindre 0 – 0 Seagull"
				}
				.style(Styles.tally)

				p(.part(Parts.line), .role("status")) {
					"A seagull lands on the quay and looks at your waffle."
				}
				.style(Styles.fightLine)

				div {
					for _ in 1...10 {
						button(.type(.button), .part(Parts.choice), .hidden) {}
							.style(Styles.fightChoice)
					}
				}
				.accessibilityLabel("What to say")
				.attributes(.role("group"))
				.style(Styles.fightChoices)

				div {
					button(.part(Parts.start), .type(.button)) {
						"⚔ Fight a Seagull"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					button(.part(Parts.master), .type(.button)) {
						"👑 Fight the Sea Gull Master"
					}
					.style(GeoCitiesPage.Styles.retroButton, Styles.masterButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)

				p(.part(Parts.known)) {
					"You know 2 insults and 2 comebacks."
				}
				.style(Styles.known)
			}
			.style(GeoCitiesPage.Styles.windowBody, Styles.fightBody)
		}
		.style(GeoCitiesPage.Styles.window, Styles.fightWindow, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Insult Seagull Fighting needs JavaScript. Without it, the seagulls just steal your waffle."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case canvas
		case tally
		case line
		case start
		case master
		case known

		/**
		A line to say in a fight.
		*/
		case choice
	}

	enum Styles: ElementStyleSet {
		case root
		case fightWindow
		case fightBody
		case fightCanvas
		case tally
		case fightLine
		case fightChoices
		case fightChoice
		case masterButton
		case known

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .fightWindow:
				Style()
					.frame(maxWidth: .pixels(560))
					.margin(.horizontal, .auto)
			case .fightBody:
				Style().background(Color("#101828"))
			case .fightCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(200.0 / 80.0)
					.imageRendering(.pixelated)
					.border(Color("#5a6a8a"), width: .pixels(2), style: .inset)
			case .tally:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.textAlign(.center)
					.color(Color("#ffd27a"))
			case .fightLine:
				// The words of the fight, in the colors of Monkey Island: white for Sindre and the seagulls, on black.
				Style()
					.frame(minHeight: .lineHeight(3))
					.margin(0)
					.padding(.rootEm(0.5))
					.background(.black)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.textAlign(.center)
					.color(.white)
			case .fightChoices:
				Style().vstack(spacing: .rootEm(0.125))
			case .fightChoice:
				Style()
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.5))
					.background(.black)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.textAlign(.leading)
					.color(Color("#c070ff"))
					.handCursor()
					.hover {
						$0.color(Color("#ffff66"))
					}
					.focusVisible {
						$0
							.color(Color("#ffff66"))
							.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(-2))
					}
			case .masterButton:
				// Locked until the visitor knows enough comebacks, but still there to see, so the visitor knows what to aim for.
				Style().when(.state, is: "locked") {
					$0.opacity(0.6)
				}
			case .known:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
					.textAlign(.center)
					.color(Color("#b0c0e0"))
			}
		}
	}
}
