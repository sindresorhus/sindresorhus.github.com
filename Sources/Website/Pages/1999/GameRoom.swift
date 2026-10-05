import Elementary
import Foundation
import SiteKit

/**
The Game Room next to the arcade, with the small games of the web of 1999, each in a window: the Brown Cheese Bandit (a slot machine), the Unicorn Derby (a race to bet on), Glitter Says (Simon), a memory game with the GIFs of the page, Hangman with the words of 1999, Yatzy (the Norwegian way, with pairs), Rock Paper Scissors against Rocky the pet rock, a reaction test for the modem finger, and a typing tutor. The coin games take the coins of the arcade, and every game gives tickets for the Prize Counter of the arcade (``GeoCitiesArcade``). Its script, `GameRoom.js`, runs them, with the coins, the tickets, and the sound of the arcade.
*/
struct GeoCitiesGameRoom: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	The GIFs of the memory game, each on two cards, with the name that a screen reader says when the card is face up.
	*/
	static let memoryGIFs: [(gif: GeoCitiesPage.GIF, name: String)] = [
		(.unicorn, "A unicorn"),
		(.hamster, "A dancing hamster"),
		(.coolCow, "A cool cow"),
		(.flyingPig, "A flying pig"),
		(.toaster, "A toaster"),
		(.dolphin, "A dolphin"),
		(.pacman, "Pac-Man"),
		(.skull, "A spinning skull"),
	]

	/**
	The unicorns of the Unicorn Derby, with the odds of each. Dial-Up Dan takes a while to connect.
	*/
	static let runners: [(name: String, odds: Int)] = [
		("Sparkle Pony", 2),
		("Brunost Express", 3),
		("Glitter Jr.", 4),
		("Y2K Bug", 6),
		("Dial-Up Dan", 15),
	]

	/**
	The categories of Yatzy, with the key that the script scores them by. The first six are the upper section.
	*/
	static let yatzyCategories: [(key: String, name: String)] = [
		("1", "Ones"),
		("2", "Twos"),
		("3", "Threes"),
		("4", "Fours"),
		("5", "Fives"),
		("6", "Sixes"),
		("pair", "One Pair"),
		("twoPairs", "Two Pairs"),
		("three", "Three of a Kind"),
		("four", "Four of a Kind"),
		("small", "Small Straight (1–5)"),
		("large", "Large Straight (2–6)"),
		("house", "Full House"),
		("chance", "Chance"),
		("yatzy", "Yatzy!"),
	]

	var content: some HTML {
		h2 {
			gif(.gamesCube)
			" The Game Room"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"More games! The coin games take the coins of the arcade, and every game gives tickets for the Prize Counter."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			window("Brown Cheese Bandit") {
				slotMachine
			}

			window("Unicorn Derby") {
				derby
			}

			window("Glitter Says") {
				simon
			}

			window("Memory") {
				memory
			}

			window("Hangman ’99") {
				hangman
			}

			window("Rock Paper Scissors") {
				rockPaperScissors
			}

			window("Yatzy") {
				yatzy
			}

			window("How Fast Is Your Modem Finger?") {
				reaction
			}

			window("Mormor Teaches Typing") {
				typing
			}
		}
		.style(Styles.room, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The Game Room needs JavaScript. All the games are out of order."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	A slot machine with three reels of waffles, brown cheese, unicorns, and Y2K bugs. Three slices of brown cheese is the jackpot.
	*/
	private var slotMachine: some HTML {
		div {
			p {
				"Coins: "
				span(.hook(GeoCitiesArcade.Hooks.coins)) {
					"10"
				}
			}
			.style(GeoCitiesPage.Styles.lcd)

			div {
				for _ in 0..<3 {
					span(.part(Parts.reel)) {
						"🟫"
					}
					.style(Styles.reel)
				}
			}
			.accessibilityHidden()
			.style(Styles.reels)

			button(.part(Parts.slotPull), .type(.button)) {
				"Pull the Lever! (1 coin)"
			}
			.style(GeoCitiesPage.Styles.retroButton)

			p(.part(Parts.slotStatus), .role("status")) {}
				.style(Styles.status)

			ul {
				for (symbols, prize) in [("🟫🟫🟫", "50 (jackpot!)"), ("🧇🧇🧇", "10 coins"), ("🦄🦄🦄", "15 coins"), ("🐛🐛🐛", "19 (Y2K bug!)"), ("🍒🍒🍒", "5 coins"), ("🟫🟫", "2 coins"), ("🍒🍒", "1 coin")] {
					li {
						span {
							symbols
						}
						.accessibilityHidden()
						" "
						prize
					}
				}
			}
			.accessibilityLabel("What the machine pays")
			.style(Styles.payTable)

			p {
				"🟫 is a slice of brunost, the brown cheese of Norway."
			}
			.style(GeoCitiesPage.Styles.caption)
		}
		.style(Styles.game)
	}

	/**
	A race of five unicorns. The visitor bets coins on one, and wins the bet times the odds.
	*/
	private var derby: some HTML {
		div {
			ol {
				for (index, runner) in Self.runners.enumerated() {
					li {
						span {
							"\(index + 1). \(runner.name)"
						}
						.style(Styles.laneName)

						span(.part(Parts.runner)) {
							gif(.unicornGallop)
						}
						.style(Styles.runner)
					}
					.style(Styles.lane)
				}
			}
			.accessibilityLabel("The race track")
			.style(Styles.track)

			div {
				label {
					"Unicorn: "
					select(.part(Parts.derbyPick)) {
						for (index, runner) in Self.runners.enumerated() {
							option(.value("\(index)")) {
								"\(runner.name) (\(runner.odds) to 1)"
							}
						}
					}
					.style(GeoCitiesPage.Styles.select)
				}

				label {
					"Bet: "
					select(.part(Parts.derbyBet)) {
						for coins in [1, 3, 5] {
							option(.value("\(coins)")) {
								coins == 1 ? "1 coin" : "\(coins) coins"
							}
						}
					}
					.style(GeoCitiesPage.Styles.select)
				}
			}
			.style(GeoCitiesPage.Styles.formRow)

			button(.part(Parts.derbyStart), .type(.button)) {
				"And They’re Off!"
			}
			.style(GeoCitiesPage.Styles.retroButton)

			p(.part(Parts.derbyStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.game)
	}

	/**
	Simon, with four colored buttons that play the tones of the Simon of 1978, and a longer tune each round.
	*/
	private var simon: some HTML {
		div {
			div(.part(Parts.simonBoard)) {
				for (index, color) in ["Green", "Red", "Yellow", "Blue"].enumerated() {
					button(.type(.button), .part(Parts.simonPad)) {
						"\(index + 1)"
					}
					.accessibilityLabel("\(color) (\(index + 1))")
					.style(Styles.simonPad, Styles.simonColors[index])
				}
			}
			.style(Styles.simonBoard)

			div {
				button(.part(Parts.simonStart), .type(.button)) {
					"Start"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.type(.button), .hook(GeoCitiesArcade.Hooks.sound), .ariaPressed(false)) {
					"🔇 Sound"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.simonStatus), .role("status")) {
				"Watch Glitter, then press the same colors. The keys 1 to 4 work too."
			}
			.style(Styles.status)
		}
		.style(Styles.game)
	}

	/**
	A memory game with 16 cards, two of each GIF.
	*/
	private var memory: some HTML {
		div {
			div(.part(Parts.memoryBoard)) {
				for (index, item) in (Self.memoryGIFs + Self.memoryGIFs).enumerated() {
					button(.type(.button), .hook(Hooks.memoryCard, value: "\(index % Self.memoryGIFs.count)"), .hook(Hooks.memoryName, value: item.name)) {
						gif(item.gif)
					}
					.accessibilityLabel("Card \(index + 1), face down")
					.style(Styles.card)
				}
			}
			.style(Styles.memoryBoard)

			p(.part(Parts.memoryStatus), .role("status")) {
				"Find the pairs!"
			}
			.style(Styles.status)

			button(.part(Parts.memoryRestart), .type(.button)) {
				"Shuffle"
			}
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(Styles.game)
	}

	/**
	Hangman with the words of 1999, each with a hint. A wrong letter adds a part to the stick figure, the propeller hat last.
	*/
	private var hangman: some HTML {
		div {
			pre(.part(Parts.hangmanDrawing)) {}
				.accessibilityHidden()
				.style(Styles.hangmanDrawing)

			// The script names it with the letters and the blanks, as a screen reader would say “underscore” for each blank.
			p(.part(Parts.hangmanWord), .role("img")) {}
				.style(Styles.hangmanWord)

			p(.part(Parts.hangmanHint)) {}
				.style(GeoCitiesPage.Styles.caption)

			div(.part(Parts.hangmanKeys)) {
				for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
					button(.type(.button), .hook(Hooks.hangmanLetter, value: String(letter))) {
						String(letter)
					}
					.style(Styles.letterKey)
				}
			}
			.accessibilityLabel("Letters")
			.style(Styles.letterKeys)

			p(.part(Parts.hangmanStatus), .role("status")) {}
				.style(Styles.status)

			button(.part(Parts.hangmanNew), .type(.button)) {
				"New Word"
			}
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(Styles.game)
	}

	/**
	Rock Paper Scissors against Rocky, who is a rock.
	*/
	private var rockPaperScissors: some HTML {
		div {
			p {
				gif(.googlyEyes, alt: "Rocky")
			}
			.style(Styles.rocky)

			p {
				"Rocky challenges you! He has never lost his cool. He has never lost anything, really."
			}

			div {
				for (move, title) in [("rock", "✊ Rock"), ("paper", "✋ Paper"), ("scissors", "✌️ Scissors")] {
					button(.type(.button), .hook(Hooks.rpsMove, value: move)) {
						title
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.rpsScore)) {
				"You: 0 ★ Rocky: 0 ★ Ties: 0"
			}
			.style(GeoCitiesPage.Styles.lcd)

			p(.part(Parts.rpsStatus), .role("status")) {}
				.style(Styles.status)

			button(.part(Parts.rpsVisit), .type(.button)) {
				"Visit Rocky’s Home"
			}
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(Styles.game)
	}

	/**
	Yatzy with five dice, three rolls a round, and the 15 categories of the Scandinavian Yatzy.
	*/
	private var yatzy: some HTML {
		div {
			p {
				gif(.dice)
				" Roll up to three times a round, keep the dice you like, and pick a row. 63 in the upper rows gives 50 extra."
			}

			div {
				for index in 0..<5 {
					button(.type(.button), .part(Parts.yatzyDie), .ariaPressed(false), .disabled) {
						"⚀"
					}
					.accessibilityLabel("Die \(index + 1)")
					.style(Styles.die)
				}
			}
			.style(Styles.dice)

			button(.part(Parts.yatzyRoll), .type(.button)) {
				"Roll the Dice!"
			}
			.style(GeoCitiesPage.Styles.retroButton)

			p(.part(Parts.yatzyStatus), .role("status")) {
				"Press Roll to start. Click a die to keep it."
			}
			.style(Styles.status)

			table {
				caption {
					"Score card"
				}
				.style(VisuallyHidden.Styles.root)

				tbody {
					for (index, category) in Self.yatzyCategories.enumerated() {
						tr {
							th {
								category.name
							}

							td {
								button(.type(.button), .hook(Hooks.yatzyCategory, value: category.key), .disabled) {
									"–"
								}
								.style(Styles.scoreButton)
							}
						}

						if index == 5 {
							tr {
								th {
									"Bonus (63 or more)"
								}

								td(.part(Parts.yatzyBonus)) {
									"0 / 63"
								}
							}
							.style(Styles.sumRow)
						}
					}

					tr {
						th {
							"Total"
						}

						td(.part(Parts.yatzyTotal)) {
							"0"
						}
					}
					.style(Styles.sumRow)
				}
			}
			.style(Styles.scoreCard)
		}
		.style(Styles.game)
	}

	/**
	A reaction test: the button turns green after a while, and the visitor clicks it as fast as possible.
	*/
	private var reaction: some HTML {
		div {
			button(.part(Parts.reactionButton), .type(.button)) {
				"Click to Start"
			}
			.style(Styles.reactionButton)

			p(.part(Parts.reactionStatus), .role("status")) {
				"Click when it turns green. Not before!"
			}
			.style(Styles.status)

			p(.part(Parts.reactionBest)) {}
				.style(GeoCitiesPage.Styles.caption)
		}
		.style(Styles.game)
	}

	/**
	A typing tutor, like Mavis Beacon, but taught by my grandmother: type the sentence, and get the speed in words a minute and as the speed of a modem.
	*/
	private var typing: some HTML {
		div {
			p {
				"Mormor (my grandma) types 90 words a minute. Type the sentence below!"
			}

			p(.part(Parts.typingText)) {}
				.accessibilityHidden()
				.style(Styles.typingText)

			label {
				span(.part(Parts.typingLabel)) {
					"Type here"
				}
				.style(VisuallyHidden.Styles.root)

				input(.part(Parts.typingInput), .type(.text), .autocomplete("off"), .custom(name: "autocapitalize", value: "off"), .custom(name: "autocorrect", value: "off"), .custom(name: "spellcheck", value: "false"))
					.style(GeoCitiesPage.Styles.field)
			}
			.style(Styles.typingField)

			p(.part(Parts.typingStatus), .role("status")) {}
				.style(Styles.status)

			button(.part(Parts.typingNew), .type(.button)) {
				"New Sentence"
			}
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(Styles.game)
	}

	/**
	A window of Windows 95 for a game, with its title.
	*/
	private func window(_ title: String, @HTMLBuilder content: () -> some HTML) -> some HTML {
		div {
			h3 {
				title
			}
			.style(GeoCitiesPage.Styles.titleBar, Styles.windowTitle)

			div {
				content()
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window, Styles.window)
	}

	private func gif(_ gif: GeoCitiesPage.GIF, alt: String = "", style: GeoCitiesPage.Styles = .gif) -> GeoCitiesPage.GIFImage {
		GeoCitiesPage.GIFImage(gif: gif, alt: alt, style: style, project: project)
	}

	/**
	The data attributes with a value that the script reads.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		The pair of a card of the memory game.
		*/
		case memoryCard = "data-memory-card"

		/**
		The name of the GIF of a card, which its label says when it is face up.
		*/
		case memoryName = "data-memory-name"

		/**
		The letter of a key of Hangman.
		*/
		case hangmanLetter = "data-hangman-letter"

		/**
		What the visitor plays against Rocky: `rock`, `paper`, or `scissors`.
		*/
		case rpsMove = "data-rps-move"

		/**
		The key of a row of the score card of Yatzy.
		*/
		case yatzyCategory = "data-yatzy-category"
	}

	enum Parts: String, ElementPartSet {
		/**
		A reel of the slot machine. There are three.
		*/
		case reel

		case slotPull
		case slotStatus

		/**
		A unicorn of the Unicorn Derby. There are five.
		*/
		case runner

		case derbyPick
		case derbyBet
		case derbyStart
		case derbyStatus
		case simonBoard

		/**
		A colored button of Glitter Says. There are four.
		*/
		case simonPad

		case simonStart
		case simonStatus
		case memoryBoard
		case memoryStatus
		case memoryRestart
		case hangmanDrawing
		case hangmanWord
		case hangmanHint
		case hangmanKeys
		case hangmanStatus
		case hangmanNew
		case rpsScore
		case rpsStatus
		case rpsVisit

		/**
		A die of Yatzy. There are five.
		*/
		case yatzyDie

		case yatzyRoll
		case yatzyStatus
		case yatzyBonus
		case yatzyTotal
		case reactionButton
		case reactionStatus
		case reactionBest
		case typingText
		case typingLabel
		case typingInput
		case typingStatus
		case typingNew
	}

	enum Styles: ElementStyleSet {
		case root
		case room
		case window
		case windowTitle
		case game
		case status
		case reels
		case reel
		case payTable
		case track
		case lane
		case laneName
		case runner
		case simonBoard
		case simonPad
		case simonGreen
		case simonRed
		case simonYellow
		case simonBlue
		case memoryBoard
		case card
		case hangmanDrawing
		case hangmanWord
		case letterKeys
		case letterKey
		case rocky
		case dice
		case die
		case scoreCard
		case scoreButton
		case sumRow
		case reactionButton
		case typingText
		case typingField

		/**
		The colors of the buttons of Glitter Says, in the order of the buttons.
		*/
		static let simonColors: [Self] = [.simonGreen, .simonRed, .simonYellow, .simonBlue]

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .room:
				// Two windows side by side where there is room.
				Style()
					.grid(minimumColumnWidth: .rootEm(17))
					.gap(.rootEm(1.25))
					.alignItems(.start)
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .window:
				Style().frame(minWidth: 0)
			case .windowTitle:
				Style().margin(0)
			case .game:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.625))
					.textAlign(.center)
					.children("p") {
						$0.margin(0)
					}
			case .status:
				// Two lines high, so the window does not grow when a message is longer.
				Style()
					.frame(minHeight: .lineHeight(2))
					.fontWeight(.bold)
					.color(Color("#000080"))
			case .reels:
				// The window of the slot machine, with three reels side by side.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.padding(.rootEm(0.5))
					.background(Color("#cc0000"))
					.border(Color("#ffcc00"), width: .pixels(4), style: .ridge)
					.cornerRadius(.rootEm(0.5))
			case .reel:
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(3.5), height: .rootEm(3.5))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.font(size: .rootEm(2.25), lineHeight: 1)
					.when(.state, is: "win") {
						$0.background(Color("#ffff66"))
					}
			case .payTable:
				Style()
					.grid(minimumColumnWidth: .rootEm(7.5))
					.gap(.rootEm(0.125))
					.padding(.leading, 0)
					.textStyle(.caption)
					.textAlign(.leading)
					.children("li") {
						$0.display(.block)
					}
			case .track:
				// A green track with a white line between the lanes, and the finish line on the right.
				Style()
					.vstack(spacing: 0)
					.frame(width: .percent(100))
					.padding(.leading, 0)
					.background(Color("#2d8a2d"))
					.border(.trailing, .white, width: .pixels(6), style: .dashed)
			case .lane:
				Style()
					.position(.relative)
					.display(.block)
					.frame(height: .rootEm(2.75))
					.border(.bottom, Color("#ffffff66"), width: .pixels(1))
			case .laneName:
				Style()
					.position(.absolute)
					.leading(.rootEm(0.25))
					.top(0)
					.fontFamily(.system)
					.font(.extraSmall, weight: .bold)
					.color(.white)
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: .black))
			case .runner:
				// The script moves it from the start to the finish, as a part of the width of the lane.
				Style()
					.position(.absolute)
					.bottom(0)
					.leading(0)
					.frame(width: .rootEm(3))
					.leading(GeoCitiesGameRoom.progress.value(default: 0))
					.children("picture > img") {
						$0
							.display(.block)
							.frame(width: .percent(100), height: .auto)
					}
			case .simonBoard:
				// A black circle, which cuts the outer corners of the buttons round, like the Simon of 1978.
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(.black)
					.cornerRadius(.percent(50))
					.overflow(.hidden)
			case .simonPad:
				// Dim until it lights up, when Glitter shows it or the visitor presses it.
				Style()
					.frame(width: .rootEm(5), height: .rootEm(5))
					.border(.black, width: .pixels(3))
					.fontFamily(.system)
					.font(.large, weight: .bold)
					.color(Color("#00000066"))
					.opacity(0.55)
					.handCursor()
					.when(.state, is: "lit") {
						$0
							.opacity(1)
							.shadow(Shadow(x: 0, y: 0, blur: .pixels(16), color: .white))
					}
			case .simonGreen:
				Style().background(Color("#00cc44"))
			case .simonRed:
				Style().background(Color("#ee2222"))
			case .simonYellow:
				Style().background(Color("#ffdd00"))
			case .simonBlue:
				Style().background(Color("#2266ff"))
			case .memoryBoard:
				Style()
					.grid(columns: 4)
					.gap(.rootEm(0.375))
					.frame(width: .percent(100), maxWidth: .rootEm(18))
			case .card:
				// The back of a card is blue with a question mark, and the GIF only shows while the card is face up.
				Style()
					.position(.relative)
					.hstack(alignment: .center, justification: .center)
					.aspectRatio(1)
					.padding(.rootEm(0.25))
					.background(Color("#000080"))
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.handCursor()
					// The GIFs have different sizes, so each fits in its card.
					.children("picture > img") {
						$0
							.frame(maxWidth: .percent(100), maxHeight: .percent(100))
							.objectFit(.contain)
					}
					.children("*") {
						$0.visibility(false)
					}
					.before {
						$0
							.content("?")
							.position(.absolute)
							.fontFamily(GeoCitiesPage.comicSans)
							.font(.extraLarge2, weight: .bold)
							.color(Color("#ffee55"))
					}
					.when(.state, is: "open") {
						$0
							.background(.white)
							.children("*") {
								$0.visibility(true)
							}
							.before {
								$0.content("")
							}
					}
					.when(.state, is: "matched") {
						$0
							.background(Color("#ccffcc"))
							.border(Color("#00aa00"), width: .pixels(3), style: .inset)
							.children("*") {
								$0.visibility(true)
							}
							.before {
								$0.content("")
							}
					}
			case .hangmanDrawing:
				// A drawing in a notebook, in pencil.
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(1))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.lineHeight(1.1)
					.textAlign(.leading)
			case .hangmanWord:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.font(.extraLarge, weight: .bold)
					.letterSpacing(.em(0.2))
					.overflowWrap(.anywhere)
			case .letterKeys:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .letterKey:
				Style()
					.frame(minWidth: .rootEm(2), minHeight: .rootEm(2))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(.black)
					.handCursor()
					.when(.state, is: "hit") {
						$0
							.background(Color("#99ee99"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
					.when(.state, is: "miss") {
						$0
							.background(Color("#ee9999"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
					.disabled {
						$0.cursor(GeoCitiesPage.arrowCursor, fallback: .default)
					}
			case .rocky:
				// A gray rock, with the googly eyes of Rocky on it.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(6), height: .rootEm(4))
					.background(Color("#8a8a8a"))
					.border(Color("#5a5a5a"), width: .pixels(3))
					.cornerRadius(.percent(50))
			case .dice:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .die:
				// A kept die is pressed in and yellow.
				Style()
					.frame(width: .rootEm(3.25), height: .rootEm(3.25))
					.background(.white)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(0.5))
					.font(size: .rootEm(2.5), lineHeight: 1)
					.color(.black)
					.handCursor()
					.when(.state, is: "kept") {
						$0
							.background(Color("#ffee55"))
							.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
					.disabled {
						$0
							.color(Color("#00000088"))
							.cursor(GeoCitiesPage.arrowCursor, fallback: .default)
					}
			case .scoreCard:
				Style()
					.frame(width: .percent(100), maxWidth: .rootEm(22))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(.system)
					.textStyle(.caption)
					.textAlign(.leading)
					.children("tbody > tr > *") {
						$0
							.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
							.border(.bottom, Color("#dddddd"), width: .pixels(1))
					}
			case .scoreButton:
				// An open row shows what it would score, and a scored row keeps its score, without the look of a button.
				Style()
					.frame(width: .percent(100), minWidth: .rootEm(3))
					.background(Color("#ffffcc"))
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(Color("#000080"))
					.handCursor()
					.when(.state, is: "scored") {
						$0
							.background(.transparent)
							.border(.transparent, width: .pixels(2))
							.color(.black)
					}
					.disabled {
						$0.cursor(GeoCitiesPage.arrowCursor, fallback: .default)
					}
			case .sumRow:
				Style()
					.background(Color("#eeeeee"))
					.fontWeight(.bold)
			case .reactionButton:
				// A big button that is red while the visitor waits, and green when it is time to click.
				Style()
					.frame(width: .percent(100), minHeight: .rootEm(7))
					.background(Color("#000080"))
					.border(Color("#dfdfdf"), width: .pixels(4), style: .outset)
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge2)
					.color(.white)
					.handCursor()
					.when(.state, is: "wait") {
						$0.background(Color("#cc0000"))
					}
					.when(.state, is: "go") {
						$0
							.background(Color("#00cc44"))
							.color(.black)
					}
			case .typingField:
				Style()
					.display(.block)
					.frame(width: .percent(100))
			case .typingText:
				// The script puts each letter in a span, green when it is typed right and red when it is typed wrong.
				Style()
					.padding(.rootEm(0.5))
					.background(Color("#ffffee"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.textAlign(.leading)
					.children("span") {
						$0
							.when(.state, is: "typed") {
								$0.color(Color("#008800"))
							}
							.when(.state, is: "mistyped") {
								$0
									.background(Color("#ffaaaa"))
									.color(Color("#cc0000"))
							}
					}
			}
		}
	}

	/**
	How far a unicorn of the Unicorn Derby has run, which the script sets.
	*/
	static let progress = StyleVariable<Length>("--derby-progress")
}
