import Elementary
import Foundation
import SiteKit

/**
Klinkekuler, the marbles that every school yard in Norway played in the spring, when the snow melted and the gravel came out, here in the recess (friminutt) of my school in Bergen. The gravel of the school yard is drawn from above on a canvas, with real marble physics: the marbles roll, slow down on the gravel (more in the rain, when it is mud and puddles), bounce off each other in elastic collisions where the heavy ones hit harder, and their swirls turn as they roll, in 3D. The visitor aims like a real flick: drag back from the marble, and the thumb of the drawn hand pulls back with the power, with a dotted hint of the path, and a spin button curves the shot to the left or the right. The marble bag (kuleposen) is kept in the browser, with glass marbles with colored swirls, cat’s eyes, clay marbles, the big ones (kinakuler), the steel ball bearing (stålkule) that every kid wanted, and the rare king (kongen), each drawn with highlights, shadows, and the light that glass throws on the ground. There are three games of the Norwegian school yard: Hull, where everybody throws their marbles at a little hole dug in the gravel (gropa), and the closest one starts to flick them in, and who flicks in the last one wins them all; Ring, where the visitor knocks the marbles out of a circle drawn in the gravel and wins what goes out; and Tårn, where a kid builds a tower of marbles and the others pay a marble for each shot at it from a line, and whoever hits it wins the tower, or the visitor builds his own tower and earns the fees of the kids who miss. The opponents have their own skill and their own tricks: Trond is fair and good, Kevin from the Unimon cards cheats (he nudges his marbles, shoots from inside the ring, and glues his tower with chewing gum, until the visitor shouts “Juks!”), Store-Geir from 7B is the best and takes all the marbles at the end, unless the visitor calls the teacher, and Lillesøster cannot aim and cries to Mamma when she loses. The visitor plays for real (på ordentlig), where the marbles are won and lost, or for fun (på lek). Every shot takes a minute of the recess, and the school bell ends it. The teacher on yard duty confiscates the steel ball, which waits in her drawer until after the bell. The trade stand (byttebua) has the trades of the kids, fair and not so fair. Once the sound is on, the glass clicks, the steel clanks, the marbles drop in the hole, the bell rings, and the teacher blows her whistle, all made in the browser. Its script, `Marbles.js`, runs it. For visitors who prefer reduced motion, a shot goes to its final spot at once with a dotted path behind each marble that moved, and the other kids shoot only when the visitor says so.
*/
struct GeoCitiesMarbles: ScriptedElement {
	static let script = ElementScript()

	/**
	The games, by their IDs in the script.
	*/
	private static let games = [
		("hull", "Hull (the Hole)"),
		("ring", "Ring"),
		("tower", "Tårn (Shoot the Tower)"),
		("my-tower", "Build My Own Tower"),
	]

	private static let opponents = [
		("trond", "Trond"),
		("kevin", "Kevin"),
		("geir", "Store-Geir (7B)"),
		("sister", "Lillesøster"),
	]

	private static let spins = [
		("none", "Straight"),
		("left", "Curve Left"),
		("right", "Curve Right"),
	]

	private static let yardButtons: [(part: Parts, label: String)] = [
		(.stakes, "På lek (for Fun)"),
		(.rain, "Rain"),
		(.cheat, "Juks! (Cheater!)"),
		(.teacher, "Call the Teacher"),
		(.goOn, "Go On"),
		(.newGame, "New Game"),
		(.sound, "Sound: Off"),
	]

	var content: some HTML {
		h2 {
			"Klinkekuler"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"When the snow melts in April and the gravel comes out, everybody brings their marble bag to school. In the recess, we play Hull, Ring, and Tårn by the bike shed. Play “på ordentlig” (for real) and you can win Store-Geir’s king. Or lose all your marbles to him. Do "
			strong {
				"not"
			}
			" bring the steel ball. The teacher takes it."
		}

		div {
			div {
				stage
				panel
			}
			.style(Styles.layout)
		}
		.style(GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The marbles need JavaScript. And dry gravel."
		}
		.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	private var stage: some HTML {
		div {
			canvas(.part(Parts.canvas), .width(640), .height(440), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The gravel of the school yard, seen from above. Drag back from your marble and let go to flick it. Or use the keys: Left and Right aim, Up and Down set the power, A and D move along the line, N picks the next marble, and Space or Enter flicks. After a game, a click or Space starts the next one.")
				.style(Styles.canvas)

			p(.part(Parts.status), .role("status")) {}
				.style(Styles.status)

			div {
				buttonGroup("The game", buttons: Self.games.map { (.hook(Hooks.game, value: $0), $1) })
				buttonGroup("Play against", buttons: Self.opponents.map { (.hook(Hooks.opponent, value: $0), $1) })
				buttonGroup("The flick", buttons: Self.spins.map { (.hook(Hooks.spin, value: $0), $1) })
				buttonGroup("The school yard", buttons: Self.yardButtons.map { (.part($0.part), $0.label) })
			}
			.style(Styles.controls)
		}
		.style(Styles.stage)
	}

	private var panel: some HTML {
		div {
			p(.part(Parts.lcd)) {}
				.style(GeoCitiesPage.Styles.lcd, Styles.lcd)

			div {
				p {
					"My marble bag (pick the shooter)"
				}
				.style(Styles.cardTitle)

				div(.part(Parts.bagList)) {}
					.style(Styles.bag)
			}
			.style(Styles.bagCard)

			div {
				p {
					"The teacher’s drawer"
				}
				.style(Styles.cardTitle)

				p(.part(Parts.drawerText)) {}
					.style(Styles.drawerText)

				button(.type(.button), .part(Parts.drawer)) {
					"Ask for It Back"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.button)
			}
			.style(Styles.drawerCard)

			div {
				p {
					"Byttebua (the trade stand)"
				}
				.style(Styles.cardTitle)

				ul(.part(Parts.tradeList)) {}
					.style(Styles.trades)
			}
			.style(Styles.tradeCard)
		}
		.style(Styles.panel)
	}

	/**
	A small heading and its row of buttons, each with the attribute that the script finds it by.
	*/
	private func buttonGroup(_ title: String, buttons: [(attribute: HTMLAttribute<HTMLTag.button>, label: String)]) -> some HTML {
		div {
			p {
				title
			}
			.style(Styles.groupTitle)

			div {
				for (attribute, label) in buttons {
					button(.type(.button), attribute) {
						label
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.button)
				}
			}
			.style(Styles.buttons)
		}
		.style(Styles.group)
	}

	enum Parts: String, ElementPartSet {
		case canvas
		case status
		case stakes
		case rain
		case cheat
		case teacher
		case goOn
		case newGame
		case sound
		case lcd
		case bagList
		case drawerText
		case drawer
		case tradeList
	}

	/**
	The buttons that carry a value, which the script reads in one listener for clicks. The script makes the buttons of the bag and of the trade stand.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		The game that a button picks, like `ring`.
		*/
		case game = "data-marbles-game"

		/**
		The kid that a button picks to play against, like `trond`.
		*/
		case opponent = "data-marbles-opponent"

		/**
		The spin of the flick that a button picks, like `left`.
		*/
		case spin = "data-marbles-spin"

		/**
		The kind of marble of a button of the bag, which the script makes, like `steel`.
		*/
		case kind = "data-marbles-kind"

		/**
		The trade of a button of the trade stand, which the script makes, by its place in the list.
		*/
		case trade = "data-marbles-trade"
	}

	enum Styles: ElementStyleSet {
		case root
		case layout
		case stage
		case canvas
		case status
		case controls
		case group
		case groupTitle
		case buttons
		case button
		case panel
		case lcd
		case cardTitle
		case bagCard
		case bag
		case drawerCard
		case drawerText
		case tradeCard
		case trades

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .layout:
				// The school yard gets the whole width, so the marbles are big enough to see their swirls, and the bag and the trade stand sit below it.
				Style().vstack(spacing: .rootEm(1))
			case .stage:
				Style().vstack(spacing: .rootEm(0.5))
			case .canvas:
				// A finger aims a flick instead of scrolling the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(640.0 / 440.0)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.background(Color("#a89a80"))
					.touchAction(.none)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .status:
				Style()
					.frame(minHeight: .lineHeight(3))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .controls:
				Style().vstack(spacing: .rootEm(0.5))
			case .group:
				Style().vstack(spacing: .rootEm(0.25))
			case .groupTitle:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(Color("#006600"))
			case .buttons:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .button:
				// Big enough for a finger. The picked game, kid, and spin look pressed in, and a button that wants a click now is yellow, like “Juks!” when Kevin just cheated.
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
					.when(.state, is: "urgent") {
						$0
							.background(Color("#ffff00"))
							.color(Color("#cc0000"))
					}
			case .panel:
				Style()
					.hstack(alignment: .start, spacing: .rootEm(0.625))
					.flexWrap()
					.children("*") {
						$0
							.flex(1)
							.frame(minWidth: .rootEm(12))
					}
			case .lcd:
				// The lines of the screen, like “RING  MEG 2  TROND 1”.
				Style()
					.margin(0)
					.preservesLineBreaks()
					.textStyle(.caption, weight: .bold)
			case .cardTitle:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(Color("#800080"))
			case .bagCard:
				// A bag of blue cloth with a drawstring, like the one Mormor sewed.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.625))
					.background(Color("#dde8ff"))
					.border(Color("#3355aa"), width: .pixels(2), style: .dashed)
			case .bag:
				// The script fills in a button for each kind of marble, with a drawing of it and how many there are.
				Style()
					.vstack(spacing: .rootEm(0.25))
					.children("button") {
						$0
							.hstack(alignment: .center, spacing: .rootEm(0.375))
							.frame(minHeight: .rootEm(2.25))
							.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
							.background(Color("#ffffff"))
							.border(Color("#8899cc"), width: .pixels(2), style: .outset)
							.fontFamily(.system)
							.textStyle(.caption)
							.textAlign(.leading)
							.color(.black)
							.handCursor()
							.disabled {
								$0.opacity(0.45)
							}
							.focusVisible {
								$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(1))
							}
					}
					.children("button[aria-pressed=\"true\"]") {
						$0
							.background(Color("#ffff99"))
							.border(Color("#cc9900"), width: .pixels(2), style: .inset)
							.fontWeight(.bold)
					}
					.children("button canvas") {
						$0
							.flexShrink(0)
							.frame(width: .pixels(22), height: .pixels(22))
					}
			case .drawerCard:
				// The drawer of the teacher’s desk, of brown wood.
				Style()
					.vstack(alignment: .start, spacing: .rootEm(0.375))
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.625))
					.background(Color("#f3e3c3"))
					.border(Color("#8a5a2b"), width: .pixels(3), style: .ridge)
			case .drawerText:
				Style()
					.margin(0)
					.textStyle(.caption)
			case .tradeCard:
				// A cardboard box turned upside down, with the trades on it.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.625))
					.background(Color("#e8cfa0"))
					.border(Color("#a07840"), width: .pixels(2), style: .solid)
			case .trades:
				Style()
					.vstack(spacing: .rootEm(0.375))
					.margin(0)
					.padding(0)
					.textStyle(.caption)
					.children("li") {
						$0.vstack(alignment: .start, spacing: .rootEm(0.25))
					}
					.children("li button") {
						$0.frame(minHeight: .rootEm(2))
					}
			}
		}
	}
}
