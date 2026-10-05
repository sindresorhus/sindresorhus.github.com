import Elementary
import Foundation
import SiteKit

/**
Microsoft Encarta Encyclopedia Deluxe 99 on the desktop of my computer (``GeoCitiesPage/desktop``), the encyclopedia on two CD-ROMs that every family computer had in 1999. It starts by reading drive D: with a spinning disc, and asks for the other disc, like the real one, when the visitor goes to something that is on it. The home screen has the Pinpointer, which finds the articles while the visitor types, with a category menu, a random article, and a “Did you know?” fact. The articles are about Norway, Bergen, the waffle, the unicorn, the year 2000 problem, the Internet, the dial-up modem, and Furby, each with a pronunciation that the browser speaks, a media picture drawn on a canvas with buttons that change it, like a national anthem and Grieg to play, a waffle to bake, a modem that connects until Mamma picks up the phone, and a Furby that speaks Furbish, a fact box, and “See also” links. The timeline goes from the big bang to 1999, one event at a time, with jumps to the eras, and links to the articles. MindMaze, the trivia game of Encarta, is a castle of 16 rooms seen in first person, where each door asks a question about 1999 and Norway, with funny wrong answers: a right answer opens the door, a wrong one locks it for a while, and the jester can take away two wrong answers. The jester, a knight with riddles, a ghost with the map, Mormor in the kitchen, and the King in the throne room pop up and talk, the points raise the visitor from peasant to squire, and the King knights the visitor who answers his question. It is the content of its window of the desktop, and its script, `WindowsEncarta.js`, runs it all and keeps the knights in the browser.
*/
struct GeoCitiesWindowsEncarta: ScriptedElement {
	static let script = ElementScript()

	/**
	The categories of the Pinpointer, which the script also gives each article.
	*/
	private static let categories = ["All categories", "Geography", "History", "Science & Technology", "Life Science", "Food & Hobbies", "Myths & Legends"]

	/**
	The eras of the timeline, by the index of their first event in the script.
	*/
	private static let eras: [(index: Int, title: String)] = [
		(0, "The universe"),
		(6, "The Vikings"),
		(14, "The 1800s"),
		(19, "The 1900s"),
		(27, "1999"),
	]

	// The labels of the Pinpointer and the group of the question of MindMaze refer to these IDs.
	private static let searchID = "geocities-encarta-search"
	private static let categoryID = "geocities-encarta-category"
	private static let questionTextID = "geocities-encarta-maze-question-text"

	var content: some HTML {
		MenuBar()
		Splash()
		Home()
		ArticlePage()
		Timeline()
		MindMaze()

		p(.part(Parts.status), .role("status")) {
			"Please wait while Encarta reads drive D:."
		}
		.style(GeoCitiesPage.Styles.statusBar, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Encarta needs JavaScript. Please insert Disc 1 into drive D: and try again."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The dark bar at the top of Encarta, with the places to go, Back, and the sound.
	*/
	private struct MenuBar: HTML {
		var body: some HTML {
			div(.role("toolbar")) {
				goButton("home", "🏠 Home")
				goButton("timeline", "⏳ Timeline")
				goButton("maze", "🏰 MindMaze")

				button(.part(Parts.back), .type(.button), .disabled) {
					"◀ Back"
				}
				.style(Styles.menuButton)

				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔈 Sound"
				}
				.help("Plays sounds")
				.style(Styles.menuButton)
			}
			.accessibilityLabel("Encarta")
			.style(Styles.menuBar, GeoCitiesPage.Styles.scriptingOnly)
		}

		private func goButton(_ place: String, _ title: String) -> some HTML {
			button(.type(.button), .hook(Hooks.go, value: place)) {
				title
			}
			.style(Styles.menuButton)
		}
	}

	/**
	The screen while Encarta reads the disc, with the logo, a spinning disc, and a progress bar.
	*/
	private struct Splash: HTML {
		var body: some HTML {
			div(.part(Parts.splash)) {
				p {
					"Microsoft®"
				}
				.style(Styles.splashMaker)

				p {
					"Encarta"
				}
				.style(Styles.splashBrand)

				p {
					"Encyclopedia Deluxe 99"
				}
				.style(Styles.splashEdition)

				p(.part(Parts.disc)) {
					"💿"
				}
				.accessibilityHidden()
				.style(Styles.disc)

				span {
					span(.part(Parts.progress)) {}
						.style(GeoCitiesWindows.Styles.progressFill)
				}
				.accessibilityHidden()
				.style(GeoCitiesWindows.Styles.progressTrack, Styles.splashProgress)

				p(.part(Parts.splashText)) {
					"Reading drive D:…"
				}
				.style(GeoCitiesPage.Styles.caption)
			}
			.style(Styles.view, Styles.splash, GeoCitiesPage.Styles.scriptingOnly)
		}
	}

	/**
	The home screen, with the Pinpointer and a fact.
	*/
	private struct Home: HTML {
		var body: some HTML {
			div(.part(Parts.home), .hidden) {
				div {
					label(.for(GeoCitiesWindowsEncarta.searchID)) {
						"Type a word or phrase"
					}
					.style(VisuallyHidden.Styles.root)

					input(.id(GeoCitiesWindowsEncarta.searchID), .part(Parts.search), .type(.search), .placeholder("🔍 Pinpointer: type a word"), .autocomplete("off"), .custom(name: "spellcheck", value: "false"))
						.style(GeoCitiesPage.Styles.field)

					div {
						label(.for(GeoCitiesWindowsEncarta.categoryID)) {
							"Category"
						}
						.style(VisuallyHidden.Styles.root)

						select(.id(GeoCitiesWindowsEncarta.categoryID), .part(Parts.category)) {
							for category in GeoCitiesWindowsEncarta.categories {
								option(.value(category)) {
									category
								}
							}
						}
						.style(Styles.grow)

						button(.part(Parts.random), .type(.button)) {
							"🎲 Random"
						}
						.style(GeoCitiesPage.Styles.smallButton)
					}
					.style(GeoCitiesWindows.Styles.wrapRow)

					div {
						ul(.part(Parts.results)) {}
							.accessibilityLabel("Articles")
							.style(Styles.results)
					}
					.style(Styles.resultsFrame)

					p(.part(Parts.resultsCount)) {}
						.style(Styles.smallText)

					template(.part(Parts.resultTemplate)) {
						li {
							button(.type(.button)) {
								span {}
								span {}
								span {}
									.style(Styles.resultCategory)
							}
							.style(Styles.result)
						}
					}
				}
				.style(Styles.pinpointer)

				div {
					p {
						strong {
							"💡 Did you know? "
						}

						span(.part(Parts.homeFact)) {}
					}

					div {
						button(.part(Parts.homeFactRead), .type(.button)) {
							"Read the article"
						}
						.style(GeoCitiesPage.Styles.smallButton)

						button(.part(Parts.homeFactNext), .type(.button)) {
							"Another fact"
						}
						.style(GeoCitiesPage.Styles.smallButton)
					}
					.style(GeoCitiesWindows.Styles.wrapRow)
				}
				.style(Styles.factBox)
			}
			.style(Styles.view, Styles.home)
		}
	}

	/**
	An article, which the script fills: the category, the title, the pronunciation, the media picture with its buttons and caption, the text, a fact, and the links.
	*/
	private struct ArticlePage: HTML {
		var body: some HTML {
			article(.part(Parts.article), .hidden, .tabindex(-1)) {
				p(.part(Parts.articleCategory)) {}
					.style(Styles.articleCategory)

				h4(.part(Parts.articleTitle)) {}
					.style(Styles.articleTitle)

				div {
					span(.part(Parts.pronunciation)) {}
						.style(Styles.smallText)

					button(.part(Parts.say), .type(.button)) {
						"🗣️ Say it"
					}
					.help("Speaks the word")
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(GeoCitiesWindows.Styles.wrapRow)

				figure {
					canvas(.part(Parts.media), .width(240), .height(150), .role("img")) {}
						.style(Styles.mediaCanvas)

					div(.part(Parts.mediaActions)) {}
						.style(GeoCitiesWindows.Styles.wrapRow)

					figcaption(.part(Parts.mediaCaption)) {}
						.style(GeoCitiesPage.Styles.caption)

					template(.part(Parts.actionTemplate)) {
						button(.type(.button)) {}
							.style(GeoCitiesPage.Styles.smallButton, Styles.mediaButton)
					}
				}
				.style(Styles.media)

				div(.part(Parts.articleBody)) {}
					.style(Styles.articleBody)

				aside {
					p {
						strong {
							"💡 Did you know?"
						}
					}

					p(.part(Parts.articleFact)) {}

					button(.part(Parts.articleFactNext), .type(.button)) {
						"Next fact"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(Styles.factBox)

				div {
					strong {
						"See also:"
					}

					div(.part(Parts.seeAlso)) {}
						.style(GeoCitiesWindows.Styles.wrapRow)
				}
				.style(GeoCitiesWindows.Styles.wrapRow)

				template(.part(Parts.linkTemplate)) {
					button(.type(.button)) {}
						.style(Styles.link)
				}
			}
			.style(Styles.view, Styles.article)
		}
	}

	/**
	The timeline, a strip of events from the big bang to 1999, with the buttons to step and the eras to jump to.
	*/
	private struct Timeline: HTML {
		var body: some HTML {
			div(.part(Parts.timeline), .hidden) {
				div {
					button(.part(Parts.timelineEarlier), .type(.button)) {
						"◀ Earlier"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

					p(.part(Parts.timelineYear)) {}
						.style(GeoCitiesPage.Styles.lcd, Styles.timelineYear)

					button(.part(Parts.timelineLater), .type(.button)) {
						"Later ▶"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

					button(.part(Parts.timelinePlay), .type(.button), .ariaPressed(false)) {
						"🚀 Travel to 1999"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
				}
				.style(GeoCitiesWindows.Styles.wrapRow)

				ol(.part(Parts.timelineStrip), .tabindex(0)) {}
					.accessibilityLabel("Timeline. The Left and Right arrow keys go to the earlier and later events.")
					.style(Styles.timelineStrip)

				// The eras are under the strip, so the buttons to step and the events fit in the view together, also on a phone.
				div {
					for era in GeoCitiesWindowsEncarta.eras {
						button(.type(.button), .hook(Hooks.era, value: "\(era.index)")) {
							era.title
						}
						.style(GeoCitiesPage.Styles.smallButton)
					}
				}
				.style(GeoCitiesWindows.Styles.wrapRow)

				template(.part(Parts.eventTemplate)) {
					li {
						span {}
							.accessibilityHidden()
							.style(Styles.eventIcon)

						strong {}
							.style(Styles.eventDate)

						span {}
					}
					.style(Styles.event)
				}
			}
			.style(Styles.view, Styles.timeline)
		}
	}

	/**
	MindMaze: the room of the castle on a canvas, the map over its corner, the balloon of the character, the question over the room, and the buttons for the doors, the map, and a new game.
	*/
	private struct MindMaze: HTML {
		var body: some HTML {
			div(.part(Parts.maze), .hidden) {
				div {
					p(.part(Parts.mazeScore)) {
						"0 points ★ Peasant"
					}
					.style(GeoCitiesPage.Styles.lcd, Styles.mazeScore)

					button(.part(Parts.mazeMapToggle), .type(.button), .ariaPressed(true)) {
						"🗺️ Map"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

					button(.part(Parts.mazeNew), .type(.button)) {
						"New Game"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
				}
				.style(GeoCitiesWindows.Styles.wrapRow)

				div {
					canvas(.part(Parts.mazeScreen), .width(480), .height(236), .tabindex(0), .role("application")) {}
						.accessibilityLabel("MindMaze castle. The Left, Up, and Right arrow keys pick the door on that wall, Down turns around, 1 to 4 answer a question, H asks the jester, T talks, M shows the map, and Escape steps back.")
						.style(Styles.mazeScreen)

					canvas(.part(Parts.mazeMap), .width(120), .height(120), .role("img")) {}
						.accessibilityLabel("Map of the castle")
						.style(Styles.mazeMap)

					p(.part(Parts.mazeBalloon), .hidden) {}
						.style(Styles.balloon)

					div(.part(Parts.mazeQuestion), .hidden, .role("group"), .ariaLabelledBy(GeoCitiesWindowsEncarta.questionTextID)) {
						p(.part(Parts.mazeAsker)) {}
							.style(Styles.asker)

						p(.id(GeoCitiesWindowsEncarta.questionTextID), .part(Parts.mazeQuestionText)) {}
							.style(Styles.questionText)

						div {
							for index in 0..<4 {
								button(.type(.button), .hook(Hooks.answer, value: "\(index)")) {}
									.style(GeoCitiesPage.Styles.smallButton, Styles.answer)
							}
						}
						.style(Styles.answers)

						div {
							button(.part(Parts.mazeHint), .type(.button)) {
								"🃏 Ask the jester"
							}
							.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

							button(.part(Parts.mazeLookup), .type(.button)) {
								"📖 Look it up"
							}
							.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

							button(.part(Parts.mazeStepBack), .type(.button)) {
								"Step back"
							}
							.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
						}
						.style(GeoCitiesWindows.Styles.wrapRow)
					}
					.style(Styles.question)
				}
				.style(Styles.mazeStage)

				div {
					doorButton("left", "◀", label: "Door on the left")
					doorButton("front", "▲", label: "Door ahead")
					doorButton("right", "▶", label: "Door on the right")
					doorButton("back", "↻", label: "Turn around")

					button(.part(Parts.mazeTalk), .type(.button), .hidden) {
						"💬 Talk"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
				}
				.style(GeoCitiesWindows.Styles.wrapRow)
			}
			.style(Styles.app)
		}

		private func doorButton(_ side: String, _ symbol: String, label: String) -> some HTML {
			button(.type(.button), .hook(Hooks.door, value: side)) {
				symbol
			}
			.accessibilityLabel(label)
			.style(GeoCitiesPage.Styles.smallButton, Styles.doorButton)
		}
	}

	enum Parts: String, ElementPartSet {
		case back
		case sound
		case status
		case splash
		case disc
		case progress
		case splashText
		case home
		case search
		case category
		case random
		case results
		case resultsCount
		case resultTemplate
		case homeFact
		case homeFactRead
		case homeFactNext
		case article
		case articleCategory
		case articleTitle
		case pronunciation
		case say
		case media
		case mediaActions
		case mediaCaption
		case actionTemplate
		case articleBody
		case articleFact
		case articleFactNext
		case seeAlso
		case linkTemplate
		case timeline
		case timelineStrip
		case eventTemplate
		case timelineEarlier
		case timelineLater
		case timelineYear
		case timelinePlay
		case maze
		case mazeScore
		case mazeMapToggle
		case mazeTalk
		case mazeNew
		case mazeScreen
		case mazeMap
		case mazeBalloon
		case mazeQuestion
		case mazeAsker
		case mazeQuestionText
		case mazeHint
		case mazeLookup
		case mazeStepBack
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button of the bar that goes to a place: `home`, `timeline`, or `maze`.
		*/
		case go = "data-encarta-go"

		/**
		A button that jumps the timeline to an era, by the index of its first event.
		*/
		case era = "data-encarta-era"

		/**
		A button for a door of the room in MindMaze, by its wall: `left`, `front`, `right`, or `back`.
		*/
		case door = "data-encarta-door"

		/**
		An answer to the question of a door, by its index.
		*/
		case answer = "data-encarta-answer"
	}

	enum Styles: ElementStyleSet {
		case root
		case app
		case menuBar
		case menuButton
		case view
		case splash
		case splashMaker
		case splashBrand
		case splashEdition
		case disc
		case splashProgress
		case home
		case pinpointer
		case grow
		case resultsFrame
		case results
		case result
		case resultCategory
		case smallText
		case factBox
		case article
		case articleCategory
		case articleTitle
		case media
		case mediaCanvas
		case mediaButton
		case articleBody
		case link
		case timeline
		case timelineStrip
		case event
		case eventIcon
		case eventDate
		case timelineYear
		case bigTarget
		case doorButton
		case mazeScore
		case mazeStage
		case mazeScreen
		case mazeMap
		case balloon
		case question
		case asker
		case questionText
		case answers
		case answer

		/**
		The deep blue and the gold of Encarta 99.
		*/
		private static let navy = Color("#0b1a4a")
		private static let gold = Color("#e8c36a")
		private static let paper = Color("#fffdf3")

		var style: Style {
			switch self {
			case .root, .app:
				Style().vstack(spacing: .rootEm(0.375))
			case .menuBar:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
					.padding(.rootEm(0.25))
					.backgroundImage(.linearGradient("to bottom", Color("#2a2a78"), Self.navy))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .menuButton:
				// The places of Encarta are gold words on the dark bar, outlined when the pointer is on them, and lit while the visitor is there.
				Style()
					.frame(minHeight: .rootEm(2))
					.padding(vertical: 0, horizontal: .rootEm(0.5))
					.background(.transparent)
					.border(.transparent, width: .pixels(1))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Self.gold)
					.handCursor()
					.hover {
						$0.border(Self.gold, width: .pixels(1))
					}
					.focusVisible {
						$0.focusRing(Color("#ffff00"), width: .pixels(2), offset: .pixels(1))
					}
					.disabled {
						$0
							.opacity(0.45)
							.cursor(.default)
					}
					.when(.state, is: "current") {
						$0
							.background(Color("#3b3b9a"))
							.border(Self.gold, width: .pixels(1))
							.color(.white)
					}
			case .view:
				// Every place of Encarta is as tall, so the window does not jump, and a long article scrolls in it.
				Style()
					.frame(height: .rootEm(20))
					.overflow(.auto)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .splash:
				Style()
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.padding(.rootEm(0.75))
					.backgroundImage(.radialGradient("circle at 50% 35%", Color("#4b3c9a"), Color("#1b1458"), Color("#070722")))
					.color(.white)
					.textAlign(.center)
			case .splashMaker:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.letterSpacing(.em(0.1))
			case .splashBrand:
				// The big gold serif word of the box of Encarta.
				Style()
					.fontFamily(GeoCitiesPage.times)
					.font(.extraLarge5, weight: .bold)
					.italic()
					.color(Self.gold)
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: .black))
			case .splashEdition:
				Style()
					.fontFamily(GeoCitiesPage.times)
					.font(.extraLarge, weight: .bold)
					.letterSpacing(.em(0.05))
			case .disc:
				// The disc spins while the drive reads it.
				Style()
					.font(size: .rootEm(2.5), lineHeight: 1)
					.when(.state, is: "spinning") {
						$0.media(.allowsMotion) {
							$0.animation(Animations.spin, .linear(duration: .seconds(0.6)).repeatForever(autoreverses: false))
						}
					}
			case .splashProgress:
				Style().frame(width: .rootEm(12))
			case .home:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.5))
					.backgroundImage(.linearGradient("160deg", Color("#1b1458"), Color("#0b1a4a"), Color("#2a1040")))
					.color(.white)
			case .pinpointer:
				// The Pinpointer is a gray panel of Windows over the blue of Encarta.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.flex(1)
					.padding(.rootEm(0.375))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.color(.black)
			case .grow:
				Style()
					.flex(1)
					.frame(minWidth: 0, minHeight: .rootEm(2))
			case .resultsFrame:
				// The list of articles takes the room that the fact under it leaves, so the fact fits on a computer, and its text fits on a phone. The list is out of the flow in it, so its rows do not make the Pinpointer taller.
				Style()
					.flex(1)
					.frame(minHeight: .rootEm(3.25))
					.position(.relative)
			case .results:
				// The list of articles scrolls by itself.
				Style()
					.position(.absolute)
					.top(0)
					.bottom(0)
					.leading(0)
					.trailing(0)
					.overflow(.auto)
					.margin(0)
					.padding(0)
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .result:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.frame(width: .percent(100), minHeight: .rootEm(2))
					.padding(vertical: 0, horizontal: .rootEm(0.375))
					.background(.white)
					.border(.transparent, width: .pixels(1))
					.fontFamily(.system)
					.textStyle(.caption)
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.hover {
						$0
							.background(Color("#000080"))
							.color(.white)
					}
					.focusVisible {
						$0
							.background(Color("#000080"))
							.color(.white)
							.border(Color("#ffff00"), width: .pixels(1), style: .dotted)
					}
			case .resultCategory:
				Style()
					.margin(.leading, .auto)
					.opacity(0.7)
					.italic()
			case .smallText:
				Style()
					.fontFamily(.system)
					.textStyle(.caption)
			case .factBox:
				// The yellow note of “Did you know?”.
				Style()
					.vstack(alignment: .start, spacing: .rootEm(0.25))
					.padding(.rootEm(0.5))
					.background(Color("#fff4b0"))
					.border(Color("#b08a20"), width: .pixels(1))
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
			case .article:
				// The white page of an article, with the title in serif like a printed encyclopedia.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.625))
					.background(Self.paper)
					.color(.black)
			case .articleCategory:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.textCase(.uppercase)
					.letterSpacing(.em(0.08))
					.color(Color("#8a6a10"))
			case .articleTitle:
				Style()
					.fontFamily(GeoCitiesPage.times)
					.font(.extraLarge3, weight: .bold)
					.color(Self.navy)
					.border(.bottom, Self.gold, width: .pixels(2))
			case .media:
				// The media picture, as wide as a phone allows, with its buttons and caption.
				Style()
					.vstack(spacing: .rootEm(0.25))
					.frame(width: .percent(100), maxWidth: .rootEm(18))
					.margin(vertical: 0, horizontal: .auto)
					.padding(.rootEm(0.375))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
			case .mediaCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(240.0 / 150.0)
					.background(.black)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .mediaButton:
				Style().frame(minHeight: .rootEm(2.25))
			case .articleBody:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.body)
			case .link:
				// The links of Encarta are blue, underlined words, as big as a finger.
				Style()
					.frame(minHeight: .rootEm(2))
					.padding(vertical: 0, horizontal: .rootEm(0.25))
					.background(.transparent)
					.border(.transparent, width: .pixels(1))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#0000cc"))
					.underline()
					.handCursor()
					.hover {
						$0.color(Color("#cc0000"))
					}
			case .timeline:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.5))
					.backgroundImage(.linearGradient("to bottom", Color("#1b1458"), Self.navy))
					.color(.white)
			case .timelineStrip:
				// The events are in a row that scrolls sideways, like the timeline of Encarta.
				Style()
					.hstack(spacing: .rootEm(0.5))
					.flexShrink(0)
					.overflow(horizontal: .auto)
					.margin(0)
					.padding(.rootEm(0.5))
					.background(Color("#0a0a30"))
					.border(Self.gold, width: .pixels(1))
					.focusVisible {
						$0.focusRing(Color("#ffff00"), width: .pixels(2), offset: .pixels(1))
					}
			case .event:
				// An event is a card on the strip, and the event the visitor is at is gold.
				Style()
					.vstack(alignment: .start, spacing: .rootEm(0.25))
					.frame(width: .rootEm(11))
					.flexShrink(0)
					.padding(.rootEm(0.375))
					.background(Self.paper)
					.border(Color("#808080"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
					.when(.state, is: "current") {
						$0
							.background(Color("#fff4b0"))
							.border(Self.gold, width: .pixels(3), style: .solid)
					}
			case .eventIcon:
				Style().font(size: .rootEm(1.5), lineHeight: 1)
			case .eventDate:
				Style()
					.fontFamily(GeoCitiesPage.times)
					.color(Self.navy)
			case .timelineYear:
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(6))
					.textStyle(.caption)
					.textAlign(.center)
			case .bigTarget:
				// Big enough for a thumb.
				Style().frame(minHeight: .rootEm(2.25))
			case .doorButton:
				Style().frame(minWidth: .rootEm(2.25), minHeight: .rootEm(2.25))
			case .mazeScore:
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(8))
					.textStyle(.caption)
			case .mazeStage:
				Style().position(.relative)
			case .mazeScreen:
				// The room of the castle. A tap picks a door, so a finger on it does not zoom the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(480.0 / 236.0)
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.touchAction(.manipulation)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffff00"), width: .pixels(2), offset: .pixels(1))
					}
			case .mazeMap:
				// The map is in the corner of the room, small enough to leave the doors free.
				Style()
					.position(.absolute)
					.top(.rootEm(0.375))
					.trailing(.rootEm(0.375))
					.frame(width: .percent(18), height: .auto)
					.aspectRatio(1)
					.border(Self.gold, width: .pixels(1))
					.allowsHitTesting(false)
			case .balloon:
				// What the characters of the castle say, in a balloon over the top of the room.
				Style()
					.position(.absolute)
					.top(.rootEm(0.375))
					.leading(.rootEm(0.375))
					.frame(maxWidth: .percent(70))
					.margin(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(.white)
					.border(.black, width: .pixels(2))
					.cornerRadius(.rootEm(0.75))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption)
					.color(.black)
					.allowsHitTesting(false)
			case .question:
				// The question is a scroll of parchment over the lower part of the room, and over all of it on a phone, where it scrolls.
				Style()
					.position(.absolute)
					.leading(.rootEm(0.375))
					.trailing(.rootEm(0.375))
					.bottom(.rootEm(0.375))
					.vstack(spacing: .rootEm(0.25))
					.frame(maxHeight: .percent(100) - .rootEm(0.75))
					.overflow(.auto)
					.padding(.rootEm(0.375))
					.background(Color("#f3e3b5"))
					.border(Color("#7a5520"), width: .pixels(3), style: .double)
					.color(.black)
					.below(.smallTablet) {
						// A phone has too small a room to cover, so the question goes below it.
						$0
							.position(.static)
							.margin(.top, .rootEm(0.375))
					}
			case .asker:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#7a3a10"))
			case .questionText:
				Style()
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.body, weight: .bold)
			case .answers:
				Style()
					.grid(minimumColumnWidth: .rootEm(10))
					.gap(.rootEm(0.25))
			case .answer:
				// An answer that the jester took away is faded, a wrong one is red, and the right one is green.
				Style()
					.frame(minHeight: .rootEm(2.25))
					.textAlign(.leading)
					.when(.state, is: "cut") {
						$0
							.opacity(0.35)
							.underline(false)
					}
					.when(.state, is: "wrong") {
						$0
							.background(Color("#ff9999"))
							.opacity(0.8)
					}
					.when(.state, is: "right") {
						$0.background(Color("#99ff99"))
					}
			}
		}
	}

	enum Animations: KeyframeSet {
		case spin

		var keyframes: [Keyframe] {
			switch self {
			case .spin:
				[.from(Style().rotationEffect(.degrees(0))), .to(Style().rotationEffect(.degrees(360)))]
			}
		}
	}
}
