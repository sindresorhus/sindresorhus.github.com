import Elementary
import Foundation
import SiteKit

/**
Sindre’s Arcade, a cabinet of six games in one, like the arcade machines of the 1980s and the Shockwave and Java games of 1999: Unicorn Invaders, Paperclip Pong, Waffle Stacker, the Information Superhighway, 88×31 Breakout, and SkiFri. It takes coins, which the visitor puts in one at a time, and gets from Mom, or from kicking the machine. It has an attract mode with a blinking “INSERT COIN”, a “CONTINUE?” countdown, a table of high scores with three initials for each game, and tickets for the Prize Counter. Its script, `Arcade.js`, draws the games on the screen, and keeps the coins, the scores, the tickets, and the prizes in the browser. The coin games of the Game Room (``GeoCitiesGameRoom``) take the same coins and give tickets for the same Prize Counter, through the arcade.
*/
struct GeoCitiesArcade: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	A game of the cabinet, with the ID that the script knows it by.
	*/
	struct Game {
		let id: String
		let title: String
		let tagline: String
	}

	/**
	The games of the cabinet, in the order of the menu.
	*/
	static let games = [
		Game(id: "invaders", title: "Unicorn Invaders", tagline: "Y2K bugs from outer space! Shoot them with waffles."),
		Game(id: "pong", title: "Paperclip Pong", tagline: "Beat the paperclip. It only wants to help."),
		Game(id: "stacker", title: "Waffle Stacker", tagline: "Stack the waffles. A full row gets eaten."),
		Game(id: "highway", title: "Information Superhighway", tagline: "Get the e-mail across the traffic of the Web."),
		Game(id: "breakout", title: "88×31 Breakout", tagline: "Break all the buttons of the Web."),
		Game(id: "ski", title: "SkiFri", tagline: "Ski down the mountain. Do not look back."),
	]

	/**
	A prize of the Prize Counter, with its price in tickets.
	*/
	struct Prize: Encodable {
		let emoji: String
		let name: String
		let price: Int

		/**
		What the lady at the counter says when the visitor gets it.
		*/
		let line: String
	}

	/**
	The prizes, from the cheapest to the giant unicorn on the top shelf, which nobody ever gets.
	*/
	static let prizes = [
		Prize(emoji: "💿", name: "An AOL CD with 500 free hours", price: 5, line: "Take two. We have boxes of them."),
		Prize(emoji: "🕷️", name: "A plastic spider ring", price: 15, line: "Scare your sister with it!"),
		Prize(emoji: "🦄", name: "A Pog with a unicorn", price: 30, line: "A rare one. Do not play for keeps."),
		Prize(emoji: "🌈", name: "A slap bracelet", price: 50, line: "Slap it on! They are banned at school, so wear it at home."),
		Prize(emoji: "🟢", name: "A glow stick", price: 80, line: "It glows for 6 hours. Then it is a stick."),
		Prize(emoji: "🔋", name: "A battery for a Tamagotchi", price: 120, line: "Glitter would like that too."),
		Prize(emoji: "🪶", name: "A Furby feather (probably)", price: 200, line: "We think it is from a Furby. We do not ask."),
		Prize(emoji: "💾", name: "A floppy disk that says “GAMES”", price: 300, line: "Nobody knows what is on it. Do not put it in your dad’s computer."),
		Prize(emoji: "🧸", name: "The giant stuffed unicorn from the top shelf", price: 2000, line: "Nobody has ever won it. You did it! I need a ladder."),
	]

	/**
	The titles of the games, by their ID, and the prizes, for the script.
	*/
	struct Config: Encodable {
		let games: [String: String]
		let prizes: [Prize]
	}

	var config: Config {
		Config(games: Dictionary(uniqueKeysWithValues: Self.games.map { ($0.id, $0.title) }), prizes: Self.prizes)
	}

	/**
	The ID of the section that the toy was, which a button of the site map of the page jumps to.
	*/
	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id("geocities-arcade")]
	}

	var content: some HTML {
		h2 {
			gif(.pacman)
			" Sindre’s Arcade "
			gif(.pacman)
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Six real arcade games in one machine, just like at the mall! One coin a game. Mom gave me 10 coins, and she says that is the last time."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			cabinet

			div {
				gameMenu
				highScores
			}
			.style(Styles.side)
		}
		.style(Styles.layout, GeoCitiesPage.Styles.scriptingOnly)

		// The buttons of the plugins that the games of 1999 needed, which are also bricks of 88×31 Breakout.
		p {
			"This arcade requires Shockwave 7, Java 1.1, and a 56k modem. Get them here:"
		}
		.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.centeredText)

		div {
			gif(.buttonGetShockwave, alt: "Get Shockwave")
			gif(.buttonShockRave, alt: "Join ShockRave")
			gif(.buttonGetJava, alt: "Get Java")
			gif(.buttonGames, alt: "Games")
			gif(.buttonSpaceInvaders, alt: "Space Invaders")
		}
		.style(GeoCitiesPage.Styles.row)

		prizeCounter

		p {
			"The arcade needs JavaScript. Insert coin to continue."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)

		// The 88×31 buttons that are the bricks of 88×31 Breakout, which the script draws on the screen.
		template(.part(Parts.bricks)) {
			for gif in Self.brickGIFs {
				img(.src(gif.path), .alt(""))
			}
		}
	}

	/**
	The 88×31 buttons of the page, which 88×31 Breakout breaks.
	*/
	static let brickGIFs: [GeoCitiesPage.GIF] = GeoCitiesPage.GIF.allCases.filter { $0.rawValue.hasPrefix("button-") }

	/**
	The cabinet: a marquee, the screen, the control panel with the joystick and the buttons, and the coin door.
	*/
	private var cabinet: some HTML {
		div(.part(Parts.cabinet)) {
			p {
				"★ SINDRE’S ARCADE ★"
			}
			.accessibilityHidden()
			.style(Styles.marquee)

			div {
				// The screen is twice the size of the games, which are 224 × 288 pixels, like the screens of the arcade machines of 1981, so the text is sharp.
				canvas(.part(Parts.screen), .width(448), .height(576), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The screen of the arcade. Use the arrow keys to move, Space to fire, and Enter to start.")
					.style(Styles.screen)
			}
			.style(Styles.bezel)

			p(.part(Parts.status), .role("status")) {
				"Choose a game, and press Start! It puts in a coin for you."
			}
			.style(Styles.status)

			div {
				// The joystick, as four buttons around a plus sign. The keyboard moves with the arrow keys on the screen instead, so the buttons are not in the order of the Tab key.
				div {
					for row in [[("up", "Up", "▲")], [("left", "Left", "◀"), ("right", "Right", "▶")], [("down", "Down", "▼")]] {
						div {
							for (control, label, symbol) in row {
								button(.type(.button), .tabindex(-1), .hook(Hooks.control, value: control)) {
									symbol
								}
								.accessibilityLabel(label)
								.style(Styles.stickButton)
							}
						}
						.style(Styles.stickRow)
					}
				}
				.style(Styles.stick)

				div {
					button(.part(Parts.start), .type(.button)) {
						"START"
					}
					.style(Styles.startButton)

					button(.type(.button), .tabindex(-1), .hook(Hooks.control, value: "a")) {
						"A"
					}
					.accessibilityLabel("Fire")
					.style(Styles.fireButton)
				}
				.style(Styles.buttons)
			}
			.style(Styles.controlPanel)

			div {
				p {
					"Coins: "
					span(.hook(Hooks.coins)) {
						"10"
					}
					" ★ Credits: "
					span(.part(Parts.credits)) {
						"0"
					}
				}
				.style(GeoCitiesPage.Styles.lcd, Styles.coinDisplay)

				div {
					button(.part(Parts.insert), .type(.button)) {
						"Insert Coin"
					}
					.style(Styles.coinSlot)

					button(.part(Parts.mom), .type(.button)) {
						"Ask Mom for Coins"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.part(Parts.kick), .type(.button)) {
						"Kick the Machine"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.type(.button), .hook(Hooks.sound), .ariaPressed(false)) {
						"🔇 Sound"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.style(Styles.coinDoor)
		}
		.style(Styles.cabinet)
	}

	/**
	The menu of the games, like the select screen of a cabinet with many games in one.
	*/
	private var gameMenu: some HTML {
		div {
			h3 {
				"Choose a Game"
			}
			.style(Styles.sideTitle)

			ol {
				for (index, game) in Self.games.enumerated() {
					li {
						button(.type(.button), .hook(Hooks.game, value: game.id), .ariaPressed(index == 0)) {
							strong {
								game.title
							}

							span {
								game.tagline
							}
							.style(Styles.tagline)
						}
						.style(Styles.gameButton)
					}
				}
			}
			.style(Styles.menu)
		}
		.style(GeoCitiesPage.Styles.window, Styles.panel)
	}

	/**
	The high scores of the chosen game, with three initials each, like on the screens of the arcade machines.
	*/
	private var highScores: some HTML {
		div {
			h3(.part(Parts.scoresTitle)) {
				"High Scores"
			}
			.style(Styles.sideTitle)

			ol(.part(Parts.scores)) {}
				.style(Styles.scores)
		}
		.style(GeoCitiesPage.Styles.window, Styles.panel)
	}

	/**
	The counter where the visitor trades the tickets of the games for prizes, and the shelf with the prizes that the visitor has.
	*/
	private var prizeCounter: some HTML {
		div {
			div {
				"Prize Counter"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				p {
					"Every game in the arcade and the Game Room gives tickets. You have "
					strong {
						span(.part(Parts.tickets)) {
							"0"
						}
						" tickets"
					}
					"."
				}

				ul {
					for (index, prize) in Self.prizes.enumerated() {
						li {
							button(.type(.button), .hook(Hooks.prize, value: "\(index)")) {
								span {
									prize.emoji
								}
								.accessibilityHidden()
								.style(Styles.prizeEmoji)

								span {
									prize.name
								}

								span {
									"\(prize.price) tickets"
								}
								.style(Styles.price)
							}
							.style(Styles.prizeButton)
						}
					}
				}
				.style(Styles.prizes)

				p(.part(Parts.prizeStatus), .role("status")) {}

				h3 {
					"My Prize Shelf"
				}
				.style(Styles.sideTitle)

				ul(.part(Parts.shelf)) {}
					.style(Styles.shelf)
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window, GeoCitiesPage.Styles.scriptingOnly)
	}

	private func gif(_ gif: GeoCitiesPage.GIF, alt: String = "") -> GeoCitiesPage.GIFImage {
		GeoCitiesPage.GIFImage(gif: gif, alt: alt, style: .gif, project: project)
	}

	/**
	The data attributes with a value that the script finds elements by, and the coins and the sound buttons, which the Game Room has too.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		A button of the joystick, or the fire button: `up`, `down`, `left`, `right`, or `a`.
		*/
		case control = "data-arcade-control"

		/**
		The coins of the visitor, which the arcade and the coin games of the Game Room show.
		*/
		case coins = "data-arcade-coins"

		/**
		A button that turns the sound of the arcade on and off, in the arcade and in the games of the Game Room that make sounds.
		*/
		case sound = "data-arcade-sound"

		/**
		The ID of a game of the menu.
		*/
		case game = "data-arcade-game"

		/**
		The index of a prize of the Prize Counter.
		*/
		case prize = "data-arcade-prize"
	}

	enum Parts: String, ElementPartSet {
		case cabinet
		case screen
		case status
		case start
		case credits
		case insert
		case mom
		case kick
		case scoresTitle
		case scores

		/**
		The tickets of the visitor, which the Prize Counter shows.
		*/
		case tickets

		case prizeStatus
		case shelf

		/**
		The 88×31 buttons that are the bricks of 88×31 Breakout.
		*/
		case bricks
	}

	enum Styles: ElementStyleSet {
		case root
		case layout
		case side
		case cabinet
		case marquee
		case bezel
		case screen
		case status
		case controlPanel
		case stick
		case stickRow
		case stickButton
		case buttons
		case startButton
		case fireButton
		case coinDoor
		case coinDisplay
		case coinSlot
		case panel
		case sideTitle
		case menu
		case gameButton
		case tagline
		case scores
		case prizes
		case prizeButton
		case prizeEmoji
		case price
		case shelf

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .layout:
				// The menu and the high scores are next to the cabinet where there is room, and the cabinet gets the most of the width, so the games are large. On a phone, they go below it.
				Style()
					.hstack(alignment: .start, spacing: .rootEm(1.25))
					.flexWrap()
			case .side:
				Style()
					.vstack(spacing: .rootEm(1))
					.flex(2)
					.frame(minWidth: .rootEm(15))
			case .cabinet:
				// A tall black cabinet with purple side art, like the arcade machines at the mall. It shakes when the visitor kicks it.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.flex(3)
					.frame(minWidth: .rootEm(14), maxWidth: .rootEm(26))
					.margin(.horizontal, .auto)
					.padding(.rootEm(0.375))
					.backgroundImage(.linearGradient("to right", Color("#3a0a5e"), Color("#111111"), Color("#111111"), Color("#3a0a5e")))
					.border(Color("#000000"), width: .pixels(3))
					.cornerRadius(.rootEm(0.5))
					.shadow(Shadow(x: .pixels(4), y: .pixels(6), blur: .pixels(6), color: Color("#00000066")))
					.color(.white)
					.media(.allowsMotion) {
						$0.when(.state, is: "kicked") {
							$0.animation(GeoCitiesPage.Animations.y2kShake, .linear(duration: .milliseconds(400)))
						}
					}
			case .marquee:
				// The lit sign at the top of the cabinet.
				Style()
					.frame(width: .percent(100))
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.5))
					.backgroundImage(.linearGradient("to bottom", Color("#ffee55"), Color("#ff9900")))
					.border(Color("#ffcc00"), width: .pixels(3), style: .ridge)
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge)
					.letterSpacing(.em(0.05))
					.textAlign(.center)
					.color(Color("#cc0000"))
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), blur: 0, color: Color("#660000")))
			case .bezel:
				Style()
					.frame(width: .percent(100))
					.padding(.rootEm(0.5))
					.background(.black)
					.border(Color("#444444"), width: .pixels(3), style: .inset)
					.cornerRadius(.rootEm(0.75))
			case .screen:
				// While a game is on, a finger on the screen moves the paddle instead of scrolling the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(224.0 / 288.0)
					.background(.black)
					.cornerRadius(.rootEm(0.375))
					.when(.state, is: "playing") {
						$0.touchAction(.none)
					}
			case .status:
				// Two lines high, so the cabinet does not grow when a message is longer.
				Style()
					.frame(width: .percent(100), minHeight: .lineHeight(2))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.lineHeight(1.2)
					.textAlign(.center)
					.color(Color("#ffee55"))
			case .controlPanel:
				// The buttons go below the joystick when the cabinet is too narrow for both.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.75))
					.flexWrap()
					.frame(width: .percent(100))
					.padding(.rootEm(0.75))
					.background(Color("#222222"))
					.border(Color("#555555"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(0.5))
					.textSelection(.disabled)
			case .stick:
				Style().vstack(alignment: .center, spacing: .rootEm(0.25))
			case .stickRow:
				// Left and right have the width of a button between them, where the stick is.
				Style().hstack(alignment: .center, justification: .center, spacing: .rootEm(2.5))
			case .stickButton:
				Style()
					.frame(width: .rootEm(2.5), height: .rootEm(2.5))
					.background(Color("#cc0000"))
					.border(Color("#ff6666"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(0.5))
					.fontFamily(.system)
					.font(.large, weight: .bold)
					.color(.white)
					.touchAction(.none)
					.handCursor()
					.active {
						$0.border(Color("#ff6666"), width: .pixels(3), style: .inset)
					}
			case .buttons:
				Style().hstack(alignment: .center, spacing: .rootEm(0.75))
			case .startButton:
				Style()
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.625))
					.background(Color("#ffffff"))
					.border(Color("#cccccc"), width: .pixels(3), style: .outset)
					.cornerRadius(.capsule)
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.color(.black)
					.handCursor()
					.active {
						$0.border(Color("#cccccc"), width: .pixels(3), style: .inset)
					}
			case .fireButton:
				// The big round button.
				Style()
					.frame(width: .rootEm(3.5), height: .rootEm(3.5))
					.background(Color("#ffcc00"))
					.border(Color("#ffee88"), width: .pixels(4), style: .outset)
					.cornerRadius(.percent(50))
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge)
					.color(Color("#663300"))
					.touchAction(.none)
					.handCursor()
					.active {
						$0.border(Color("#ffee88"), width: .pixels(4), style: .inset)
					}
			case .coinDoor:
				// The metal door at the bottom, with the coin slot.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(width: .percent(100))
					.padding(.rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#8a8a8a"), Color("#5a5a5a")))
					.border(Color("#b0b0b0"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(0.375))
			case .coinDisplay:
				Style()
					.margin(0)
					.textAlign(.center)
			case .coinSlot:
				// A coin slot that lights up red, like on the coin doors of the arcade machines.
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.75))
					.background(Color("#220000"))
					.border(Color("#ff3333"), width: .pixels(3), style: .inset)
					.cornerRadius(.rootEm(0.25))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#ff5555"))
					.textShadow(Shadow(x: 0, y: 0, blur: .pixels(4), color: Color("#ff0000")))
					.handCursor()
			case .panel:
				Style().padding(.rootEm(0.75))
			case .sideTitle:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.large, weight: .bold)
					.color(Color("#000080"))
			case .menu:
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(.leading, 0)
					.margin(top: .rootEm(0.5), bottom: 0)
					.children("li") {
						$0.display(.block)
					}
			case .gameButton:
				// The chosen game is pressed in, with a black background, like a selection of a menu on a screen.
				Style()
					.vstack(alignment: .start, spacing: 0)
					.frame(width: .percent(100))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption)
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.when(.state, is: "on") {
						$0
							.background(.black)
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
							.color(Color("#ffee55"))
					}
			case .tagline:
				Style().font(.extraSmall)
			case .scores:
				Style()
					.margin(top: .rootEm(0.5), bottom: 0)
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.5))
					.padding(.leading, .rootEm(2))
					.background(.black)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(Color("#33ffff"))
					.children("li") {
						$0.hstack(justification: .spaceBetween, spacing: .rootEm(1))
					}
					.children("li:first-child") {
						$0.color(Color("#ffee55"))
					}
			case .prizes:
				Style()
					.grid(minimumColumnWidth: .rootEm(16))
					.gap(.rootEm(0.5))
					.padding(.leading, 0)
					.children("li") {
						$0.display(.flex)
					}
			case .prizeButton:
				// The prize on the left, and the price on the right.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(width: .percent(100))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.textAlign(.leading)
					.children("span:nth-child(2)") {
						$0.flex(1)
					}
					.background(.white)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
					.handCursor()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .prizeEmoji:
				Style().font(.extraLarge2)
			case .price:
				Style()
					.textWrap(.nowrap)
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(Color("#cc0000"))
			case .shelf:
				// A wooden shelf.
				Style()
					.hstack(alignment: .end, spacing: .rootEm(0.5))
					.flexWrap()
					.frame(minHeight: .rootEm(3))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.75))
					.background(Color("#fff8e8"))
					.border(.bottom, Color("#8b5a2b"), width: .pixels(8))
					.font(.extraLarge2)
					.children("li") {
						$0.display(.block)
					}
					.when(.state, is: "empty") {
						$0
							.fontFamily(GeoCitiesPage.comicSans)
							.textStyle(.caption)
					}
			}
		}
	}
}
