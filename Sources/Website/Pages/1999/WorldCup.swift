import Elementary
import Foundation
import SiteKit

/**
France 98, the night of 23 June 1998, when Norway beat Brazil 2–1 in Marseille, replayed on the old TV in our living room in Bergen, drawn on a canvas, with the whole family in the sofa in front of it, seen from behind. The broadcast has the match clock and the score bug, and a ticker with the other match of the group, where Morocco beats Scotland, so Norway must win. The visitor watches Bebeto head in the 1–0 for Brazil in the 78th minute, then plays the big moments: Tore André Flo’s 1–1 in the 83rd minute as a mini-game in three steps (take down Bjørnebye’s long ball, turn past the defender, and shoot past Taffarel), and Kjetil Rekdal’s penalty in the 89th minute after the referee’s whistle, as a real penalty with a moving reticle to aim, a power meter, and a keeper who dives. A miss makes Pappa rewind the VHS tape, and the visitor tries again. Between the big moments, Kick fast-forwards the tape to what happens next. A made-up commentator goes wild in Norwegian, with English subtitles, and talks with the computer voice once the sound is on, over a synthesized crowd that roars at the goals and a button that starts the “Olé, olé, olé” chant. The family reacts: Pappa jumps and spills his coffee on the carpet, Mormor asks what is happening (and if “BRA” on the score bug means it is good), Lillesøster sleeps through all of it, and the neighbors bang on the wall. Sindre can put on the red Norway shirt with his name on the back, a scarf, face paint, and a horned helmet. After the match, there is an instant replay of the visitor’s goals in slow motion, the Panini stickers the visitor earns in an album, the newspaper of the next morning with a photo of the visitor’s own goal from the TV and what the family said, a penalty shootout against Taffarel with five shots each and sudden death, where the visitor also keeps goal, and the sad truth: four days later, Norway lost 1–0 to Italy in the round of 16, with Vieri’s goal in the 18th minute, which no shot can change. Its script, `WorldCup.js`, runs it, and keeps the stickers and the shirt in the browser. For visitors who prefer reduced motion, nothing moves by itself: the match steps forward on each press, the reticle moves only with the arrow keys or a tap on the goal, and the meters fill step by step while the visitor holds the kick button, or move with the up and down arrows, so a single click on Kick can also kick hard.
*/
struct GeoCitiesWorldCup: ScriptedElement {
	static let script = ElementScript()

	/**
	The buttons of the TV, by what they do in the script, with their labels, in groups.
	*/
	private static let matchButtons: [(Parts, String)] = [
		(.kickoff, "Kick Off at 78’"),
		(.flo, "Skip to Flo, 83’"),
		(.penalty, "Skip to the Penalty, 89’"),
	]

	private static let roomButtons: [(Parts, String)] = [
		(.sound, "Sound: Off"),
		(.chant, "Start the “Olé, Olé, Olé”"),
		(.replay, "Instant Replay"),
	]

	private static let outfitButtons: [(Parts, String)] = [
		(.shirt, "Put On the Norway Shirt"),
		(.scarf, "Scarf"),
		(.paint, "Face Paint"),
		(.helmet, "Viking Helmet"),
	]

	private static let afterButtons: [(Parts, String)] = [
		(.shootout, "Penalty Shootout vs Taffarel"),
		(.paper, "Read Tomorrow’s Paper"),
		(.italy, "Then Came Italy…"),
	]

	/**
	The arrows that aim a shot, or pick where the keeper dives, with what they do and their labels for screen readers.
	*/
	private static let padButtons: [(Parts, String, String)] = [
		(.left, "◀", "Aim left, or dive left"),
		(.up, "▲", "Aim higher, or fill the meter more"),
		(.down, "▼", "Aim lower, stay in the middle, or fill the meter less"),
		(.right, "▶", "Aim right, or dive right"),
	]

	/**
	The stickers of the album, by their IDs in the script, with their names and how to earn them.
	*/
	private static let stickers = [
		("flo", "Tore André Flo", "Score the 1–1"),
		("rekdal", "Kjetil Rekdal", "Score the penalty"),
		("keeper", "Sindre in goal", "Save a penalty in the shootout"),
		("hero", "Sindre, the hero", "Win the shootout"),
	]

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.tabindex(-1)]
	}

	var content: some HTML {
		h2 {
			"France 98: The Night We Beat Brazil"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"On 23 June 1998, the whole family sat in the sofa for Norway against Brazil in the World Cup. Brazil was the world champion. Norway won 2–1! Pappa taped the match on the VCR, and now you can play the big moments yourself: Flo’s goal in the 83rd minute and Rekdal’s penalty in the 89th. Press "
			strong {
				"Kick"
			}
			" (or Space) when the time is right."
		}

		div {
			tv
			controls
			GeoCitiesPage.Deferred(album)
			GeoCitiesPage.Deferred(paper)
		}
		.style(GeoCitiesPage.Styles.scriptingOnly, Styles.layout)

		p {
			"The TV needs JavaScript. Pappa says the match is on the tape anyway."
		}
		.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	private var tv: some HTML {
		div {
			canvas(.part(Parts.canvas), .width(640), .height(480), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The TV in the living room, with the match and the family in the sofa. Press Space or Enter, or tap the TV, to kick, and hold it to fill a meter. The arrow keys aim a shot, set a meter, or pick where the keeper dives.")
				.style(Styles.canvas)

			div {
				div {
					for (part, symbol, label) in Self.padButtons {
						button(.type(.button), .part(part)) {
							symbol
						}
						.accessibilityLabel(label)
						.style(GeoCitiesPage.Styles.smallButton, Styles.padButton)
					}
				}
				.style(Styles.pad)

				button(.type(.button), .part(Parts.kick)) {
					"Kick!"
				}
				.style(GeoCitiesPage.Styles.retroButton, Styles.kickButton)
			}
			.style(Styles.pad)

			p(.part(Parts.status), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.stage)
	}

	private var controls: some HTML {
		div {
			buttonGroup("The match", buttons: Self.matchButtons)
			buttonGroup("The living room", buttons: Self.roomButtons)
			buttonGroup("Dress up Sindre", buttons: Self.outfitButtons)
			buttonGroup("After the match", buttons: Self.afterButtons)
		}
		.style(Styles.controls)
	}

	private var album: some HTML {
		div {
			p {
				"My Panini album, France 98 ("
				span(.part(Parts.albumCount)) {
					"0"
				}
				" of 4 stickers)"
			}
			.style(Styles.groupTitle)

			div {
				for (identifier, name, how) in Self.stickers {
					figure {
						canvas(.width(120), .height(160), .hook(Hooks.sticker, value: identifier)) {}
							.accessibilityLabel("The sticker of \(name)")
							.style(Styles.stickerCanvas)

						figcaption {
							how
						}
						.style(Styles.stickerCaption)
					}
					.style(Styles.sticker)
				}
			}
			.style(Styles.stickers)
		}
		.style(Styles.album)
	}

	private var paper: some HTML {
		article(.part(Parts.newspaper), .hidden) {
			p {
				"Bergens Regnblad"
			}
			.style(Styles.masthead)

			p {
				"Onsdag 24. juni 1998 · Nr. 171 · Kr 8,00 · Sankthans i regnet"
			}
			.style(Styles.dateline)

			h3(.part(Parts.headline)) {}
				.style(Styles.headline)

			p(.part(Parts.subhead)) {}
				.style(Styles.subhead)

			figure {
				canvas(.part(Parts.photo), .width(320), .height(192)) {}
					.accessibilityLabel("The photo on the front page: the goal on the TV in the living room")
					.style(Styles.photo)

				figcaption(.part(Parts.photoCaption)) {}
					.style(Styles.photoCaption)
			}
			.style(Styles.photoFigure)

			div {
				p(.part(Parts.story)) {}
				ul(.part(Parts.quotes)) {}
					.style(Styles.quotes)
			}
			.style(Styles.paperColumns)

			p(.part(Parts.translation)) {}
				.style(Styles.translation)
		}
		.style(Styles.paper)
	}

	/**
	A small heading and its row of buttons, each with what it does in the script.
	*/
	private func buttonGroup(_ title: String, buttons: [(Parts, String)]) -> some HTML {
		div {
			p {
				title
			}
			.style(Styles.groupTitle)

			div {
				for (part, label) in buttons {
					button(.type(.button), .part(part)) {
						label
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.button)
				}
			}
			.style(Styles.buttons)
		}
		.style(Styles.group)
	}

	/**
	The elements that the script uses. Each button is the part with the name of what it does, like `kick`.
	*/
	enum Parts: String, ElementPartSet {
		case canvas
		case status
		case albumCount
		case newspaper
		case headline
		case subhead
		case photo
		case photoCaption
		case story
		case quotes
		case translation
		case left
		case up
		case down
		case right
		case kick
		case kickoff
		case flo
		case penalty
		case sound
		case chant
		case replay
		case shirt
		case scarf
		case paint
		case helmet
		case shootout
		case paper
		case italy
	}

	enum Hooks: String, ScriptHookSet {
		/**
		Which sticker a canvas of the album draws, like `flo`.
		*/
		case sticker = "data-world-cup-sticker"
	}

	enum Styles: ElementStyleSet {
		case root
		case layout
		case stage
		case canvas
		case status
		case pad
		case padButton
		case kickButton
		case controls
		case group
		case groupTitle
		case buttons
		case button
		case album
		case stickers
		case sticker
		case stickerCanvas
		case stickerCaption
		case paper
		case masthead
		case dateline
		case headline
		case subhead
		case photoFigure
		case photo
		case photoCaption
		case paperColumns
		case quotes
		case translation

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .layout:
				Style().vstack(spacing: .rootEm(0.75))
			case .stage:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(maxWidth: .pixels(640))
					.margin(.horizontal, .auto)
			case .canvas:
				// A finger on the TV scrolls the page between the big moments, and only holds a kick or aims while one plays.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(640.0 / 480.0)
					.border(Color("#5a3a1a"), width: .pixels(3), style: .inset)
					.background(Color("#3a2a1a"))
					.touchAction(.manipulation)
					.handCursor()
					.when(.state, is: "play") {
						$0.touchAction(.none)
					}
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .status:
				Style()
					.frame(minHeight: .lineHeight(3))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .pad:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .padButton:
				// Big enough for a thumb.
				Style()
					.frame(minWidth: .rootEm(2.75), minHeight: .rootEm(2.75))
					.textStyle(.body, weight: .bold)
					.disabled {
						$0.opacity(0.5)
					}
			case .kickButton:
				// The big red button, held down to fill a meter.
				Style()
					.frame(minWidth: .rootEm(8), minHeight: .rootEm(2.75))
					.background(Color("#cc0000"))
					.color(.white)
					.fontFamily(GeoCitiesPage.impact)
					.letterSpacing(.em(0.05))
					.touchAction(.none)
					// White, as the navy ring of the other buttons does not show on the red.
					.buttonFocusRing(.white)
					.when(.state, is: "on") {
						$0
							.background(Color("#800000"))
							.border(Color("#400000"), width: .pixels(2), style: .inset)
					}
			case .controls:
				Style().vstack(spacing: .rootEm(0.5))
			case .group:
				Style().vstack(spacing: .rootEm(0.25))
			case .groupTitle:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(Color("#cc0000"))
			case .buttons:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .button:
				Style()
					.frame(minHeight: .rootEm(2))
					.disabled {
						$0.opacity(0.5)
					}
					.when(.state, is: "on") {
						$0
							.background(.white)
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .album:
				// The album of stickers, on the blue of the Panini albums of the time.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(.rootEm(0.625))
					.background(Color("#dde8ff"))
					.border(Color("#000080"), width: .pixels(2), style: .solid)
			case .stickers:
				Style()
					.grid(minimumColumnWidth: .rootEm(4.5))
					.gap(.rootEm(0.5))
			case .sticker:
				// An empty place has a dashed outline, like in the album. An earned sticker sits in it, and a shiny one glows.
				Style()
					.vstack(spacing: .rootEm(0.25))
					.margin(0)
					.padding(.rootEm(0.25))
					.background(.white)
					.border(Color("#8080a0"), width: .pixels(2), style: .dashed)
					.when(.state, is: "earned") {
						$0.border(Color("#cc0000"), width: .pixels(2), style: .solid)
					}
					.when(.state, is: "shiny") {
						$0
							.border(Color("#c0a000"), width: .pixels(2), style: .solid)
							.backgroundImage(.linearGradient("135deg", Color("#fff8c0"), Color("#ffffff"), Color("#ffe080")))
							.shadow(Shadow(y: .pixels(0), blur: .pixels(8), color: Color("#ffd700")))
					}
			case .stickerCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(120.0 / 160.0)
			case .stickerCaption:
				Style()
					.textAlign(.center)
					.textStyle(.caption)
			case .paper:
				// Newsprint of a Norwegian tabloid of 1998, with the big red headline.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.875))
					.background(Color("#f3eedf"))
					.color(Color("#111111"))
					.border(Color("#999080"), width: .pixels(1), style: .solid)
					.shadow(Shadow(x: .pixels(3), y: .pixels(3), color: Color("#00000040")))
					.fontFamily(GeoCitiesPage.times)
			case .masthead:
				Style()
					.margin(0)
					.textAlign(.center)
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.title, weight: .bold)
					.letterSpacing(.em(0.04))
			case .dateline:
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: 0)
					.border([.top, .bottom], Color("#111111"), width: .pixels(1), style: .solid)
					.textAlign(.center)
					.textStyle(.caption)
			case .headline:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.impact)
					.textStyle(.largeTitle)
					.color(Color("#c00000"))
					.textCase(.uppercase)
					.lineHeight(1.05)
			case .subhead:
				Style()
					.margin(0)
					.textStyle(.lead, weight: .bold)
			case .photoFigure:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.margin(0)
			case .photo:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(320.0 / 192.0)
					.border(Color("#111111"), width: .pixels(1), style: .solid)
			case .photoCaption:
				Style()
					.textStyle(.caption, weight: .bold)
			case .paperColumns:
				Style()
					.columns(2, minimumWidth: .rootEm(14))
					.textStyle(.body)
			case .quotes:
				Style()
					.margin(.top, .rootEm(0.5))
					.padding(.leading, .rootEm(1.25))
			case .translation:
				Style()
					.margin(0)
					.italic()
					.textStyle(.caption)
					.color(Color("#555555"))
			}
		}
	}
}
