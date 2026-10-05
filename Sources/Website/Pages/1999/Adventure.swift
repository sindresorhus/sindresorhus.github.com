import Elementary
import Foundation
import SiteKit

/**
My own adventure game, Sindre's Quest for the Golden Waffle, a point-and-click adventure like the LucasArts games of the 1990s (The Secret of Monkey Island, Day of the Tentacle): pixel-art scenes of Bergen on a canvas, a verb bar, an inventory with things that go together, conversations with funny answers, a score, deaths that are jokes like in the Sierra games, three save slots, a hint line that costs kr 9.90 a minute, and an ending. It comes in a box with feelies and four floppy disks, and with a manual that the copy protection asks about, like the games of the time. Its script, `Adventure.js`, runs it, only while it is on the screen and the tab is visible, and its sound button turns on the sound of the other adventure games of the page too: ``GeoCitiesWaffleQuest``, ``GeoCitiesInsultFight``, and ``GeoCitiesLinkingBook``.
*/
struct GeoCitiesAdventure: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the adventure, which the site map links to.
	*/
	static let rootID = "geocities-adventure"

	let project: Project

	/**
	The pages of the manual, with the paragraph whose words the copy protection asks for, and more text below it.
	*/
	static let manualPages: [(title: String, words: String, more: [String])] = [
		("Sindre’s Quest for the Golden Waffle", "Instruction manual for the adventure game by Sindresoft of Bergen. Keep this manual in a safe place, because the game asks about it.", ["© 1999 Sindresoft. All rights reserved. Some rights left out in the rain."]),
		("The Story So Far", "Mormor has a golden waffle iron called the Golden Waffle, and it makes the best waffles in Western Norway.", ["Last night, the troll of Fløyen took it. Today is Mormor’s birthday, and a birthday without waffles is not a birthday. Only one brave kid can get it back. That kid is you."]),
		("How to Play", "Click a verb, then click a thing in the picture, and Sindre does it.", ["The verbs are Walk to, Look at, Pick up, Use, Talk to, Give, and Open. The line under the picture says what you are about to do. With the keyboard, Tab to the picture, pick a thing with the arrow keys, and press Enter. The first letter of a verb picks it, and the period key skips a line of talk."]),
		("The Inventory", "The things you carry are in your inventory, next to the verbs.", ["Use a thing with another thing to put them together: click Use, then the first thing, then the second. Some things only make sense together, like waffles and brown cheese."]),
		("Talking", "Talk to people, and pick what to say from the list.", ["Be polite to Mormor. Do not insult the troll. Seagulls do not listen to anyone, so do not bother."]),
		("The People of Bergen", "Mamma, Mormor, Kevin from school, a seagull, a troll, and Glitter.", ["Mamma: worries about rain. Mormor: makes waffles, knows everything. Kevin: collects things. The seagull: steals things. The troll: lives on Fløyen, has one tooth. Glitter: my unicorn."]),
		("A Map of Bergen", "Bergen has seven mountains, one fish market, and rain on most days of the year.", ["From home you can walk to the school, to Bryggen, and to the fish market. Fløibanen, the funicular, goes from the fish market up to Fløyen. Bring a ticket."]),
		("Saving Your Game", "Save often, because Bergen is a dangerous place for a kid.", ["You have three save slots. They are kept in your browser, so they are still there tomorrow, unless your big brother needs the space."]),
		("Dying", "Yes, you can die in this game, like in the games from Sierra.", ["Do not worry. Try Again puts you back where you were, only a little wetter."]),
		("Hints", "Stuck? Call the Sindresoft Hint Line at 820 WAFFLE.", ["It costs kr 9.90 a minute. Ask the person who pays the phone bill first. Or look in the WaffleClues book, which is cheaper, and has invisible ink."]),
		("Brown Cheese Facts", "The cheese slicer was invented in Norway in 1925, by Thor Bjørklund of Lillehammer.", ["Before that, people bit the cheese. Brown cheese is not really cheese, it is whey that was boiled for a long time. Trolls love it."]),
		("Credits", "Story, art, and programming by Sindre, in his room, after homework.", ["Testing by Kevin, who found 47 bugs and one waffle. Thanks to Mamma, Mormor, and Glitter. No trolls were harmed in the making of this game."]),
	]

	/**
	The verbs of the verb bar, by the name that `Adventure.js` knows them by, with their names.
	*/
	static let verbs: [(id: String, name: String)] = [
		("walk", "Walk to"),
		("look", "Look at"),
		("pickup", "Pick up"),
		("use", "Use"),
		("talk", "Talk to"),
		("give", "Give"),
		("open", "Open"),
	]

	/**
	The things that Sindre can carry, by the name that `Adventure.js` knows them by, with their names.
	*/
	static let items: [(id: String, name: String)] = [
		("jacket", "rain jacket"),
		("piggy", "piggy bank"),
		("coins", "kr 20"),
		("cd", "AOL CD"),
		("slicer", "cheese slicer"),
		("cheese", "brown cheese"),
		("slices", "brown cheese slices"),
		("fishhead", "fish head"),
		("ticket", "Fløibanen ticket"),
		("waffle", "Golden Waffle"),
	]

	/**
	The things in the box of the game, which say something when they are clicked.
	*/
	static let feelies: [(id: String, name: String)] = [
		("ticket", "🎫 A Fløibanen ticket"),
		("sticker", "🧀 A scratch-and-sniff sticker"),
		("map", "🗺️ A cloth map of Bergen"),
		("card", "📮 A registration card"),
	]

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id(Self.rootID)]
	}

	var content: some HTML {
		h2 {
			GeoCitiesPage.GIFImage(gif: .turnBook, alt: "", style: .gif, project: project)
			" Sindre’s Adventure Games "
			GeoCitiesPage.GIFImage(gif: .turnBook, alt: "", style: .gif, project: project)
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"I played The Secret of Monkey Island on Kevin’s PC until his dad needed it for taxes, so I made my own adventure game. It came in a box, with a manual, like a real one. Open the box, read the manual (you need it!), and get Mormor’s Golden Waffle back from the troll."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			boxView
			manualView
		}
		.style(Styles.shelf)

		gameView

		p {
			"My adventure game needs JavaScript. Without it, you can still read the manual, which is the best part anyway."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The box of the game, with art on the front, and the feelies and the floppy disks inside.
	*/
	@HTMLBuilder
	var boxView: some HTML {
		div {
			div {
				p {
					"SINDRESOFT PRESENTS"
				}
				.style(Styles.boxPresents)

				p {
					"Sindre’s Quest"
				}
				.style(Styles.boxTitle)

				p {
					"for the Golden Waffle"
				}
				.style(Styles.boxSubtitle)

				canvas(.part(Parts.cover), .width(160), .height(100)) {}
					.accessibilityLabel("The art on the box: Sindre in a yellow rain jacket on Fløyen, and a big troll with a golden waffle iron.")
					.style(Styles.cover)

				p {
					"256 COLORS! • SOUND BLASTER • 4 DISKS"
				}
				.style(Styles.boxBadges)
			}
			.style(Styles.box)

			button(.part(Parts.openBox), .type(.button), .ariaExpanded(false), .ariaControls("geocities-adventure-contents")) {
				"📦 Open the Box"
			}
			.style(GeoCitiesPage.Styles.retroButton, GeoCitiesPage.Styles.scriptingOnly)

			div(.id("geocities-adventure-contents"), .part(Parts.contents), .hidden) {
				p {
					"Inside: the manual (next to the box), four floppy disks, and some feelies."
				}
				.style(Styles.contentsText)

				div {
					for feelie in Self.feelies {
						button(.type(.button), .hook(Hooks.feelie, value: feelie.id)) {
							feelie.name
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.feelie)
					}
				}
				.style(Styles.feelies)

				div {
					button(.part(Parts.install), .type(.button)) {
						"C:\\> INSTALL"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					div {
						for disk in 1...4 {
							button(.type(.button), .hook(Hooks.disk, value: String(disk))) {
								"💾"
								span {
									"Disk \(disk)"
								}
								.style(Styles.diskLabel)
							}
							.style(Styles.disk)
						}
					}
					.accessibilityLabel("Floppy disks")
					.attributes(.role("group"))
					.style(Styles.disks)

					p(.part(Parts.installStatus), .role("status")) {
						"Type INSTALL to install. Or do not, the game runs anyway."
					}
					.style(GeoCitiesPage.Styles.lcd, Styles.installStatus)
				}
				.style(Styles.install)
			}
			.style(Styles.contents)
		}
		.style(Styles.boxColumn)
	}

	/**
	The manual, a page at a time with the script, or all pages without it.
	*/
	@HTMLBuilder
	var manualView: some HTML {
		div {
			h3 {
				"MANUAL.DOC"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				for (index, page) in Self.manualPages.enumerated() {
					article(.hook(Hooks.page, value: String(index + 1))) {
						h4 {
							page.title
						}
						.style(Styles.manualTitle)

						p(.part(Parts.words)) {
							page.words
						}
						.style(Styles.manualText)

						for paragraph in page.more {
							p {
								paragraph
							}
							.style(Styles.manualText)
						}

						p {
							"– \(index + 1) –"
						}
						.style(Styles.pageNumber)
					}
					.style(Styles.manualPage)
				}

				div {
					button(.part(Parts.previousPage), .type(.button)) {
						"◀ Page"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					span(.part(Parts.pageLabel)) {
						"Page 1 of \(Self.manualPages.count)"
					}

					button(.part(Parts.nextPage), .type(.button)) {
						"Page ▶"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow, Styles.manualNavigation, GeoCitiesPage.Styles.scriptingOnly)
			}
			.style(Styles.manualBody)
		}
		.style(GeoCitiesPage.Styles.window, Styles.manual)
	}

	/**
	The game: the scene with its panels on top, the sentence line, the verbs, the inventory, and the buttons below.
	*/
	@HTMLBuilder
	var gameView: some HTML {
		div(.part(Parts.game)) {
			h3 {
				span {
					"Sindre’s Quest for the Golden Waffle"
				}
				span(.part(Parts.score)) {
					"Score: 0 of 100"
				}
			}
			.style(GeoCitiesPage.Styles.titleBar, Styles.gameTitle)

			div {
				div {
					// The scene is drawn at 320 × 160 pixels, about the size of a scene of a game with 256 colors in 1990.
					canvas(.part(Parts.scene), .width(320), .height(160), .tabindex(0), .role("application")) {}
						.accessibilityLabel("The scene of the game. Pick a verb, then use the left and right arrow keys to pick a thing and press Enter.")
						.style(Styles.scene)

					p(.part(Parts.speech), .role("status")) {}
						.style(Styles.speech)

					div(.part(Parts.titleScreen)) {
						button(.part(Parts.start), .type(.button)) {
							"▶ New Game"
						}
						.style(GeoCitiesPage.Styles.retroButton)

						button(.type(.button), .hook(Hooks.action, value: "load")) {
							"📂 Load Game"
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
					.style(Styles.titleScreen)

					form(.part(Parts.copyProtection), .hidden) {
						h4 {
							"COPY PROTECTION"
						}
						.style(Styles.panelTitle)

						label(.for("geocities-adventure-copy-answer"), .part(Parts.copyQuestion)) {
							"Type the third word on page 12 of the manual."
						}

						div {
							input(.id("geocities-adventure-copy-answer"), .part(Parts.copyAnswer), .type(.text), .autocomplete("off"), .maxlength(24), .required, .custom(name: "spellcheck", value: "false"))
								.style(GeoCitiesPage.Styles.field, Styles.copyField)

							button(.type(.submit)) {
								"OK"
							}
							.style(GeoCitiesPage.Styles.smallButton)
						}
						.style(GeoCitiesPage.Styles.formRow)

						p(.part(Parts.copyStatus), .role("status")) {}
							.style(Styles.panelNote)
					}
					.style(Styles.panel)

					div(.part(Parts.death), .hidden, .role("alertdialog"), .custom(name: "aria-label", value: "You have died"), .ariaDescribedBy("geocities-adventure-death-text")) {
						h4 {
							"☠ You have died!"
						}
						.style(Styles.panelTitle, Styles.deathTitle)

						p(.id("geocities-adventure-death-text"), .part(Parts.deathText)) {}

						div {
							button(.type(.button), .hook(Hooks.action, value: "retry")) {
								"Try Again"
							}
							.style(GeoCitiesPage.Styles.smallButton)

							button(.type(.button), .hook(Hooks.action, value: "load")) {
								"Restore"
							}
							.style(GeoCitiesPage.Styles.smallButton)

							button(.type(.button), .hook(Hooks.action, value: "restart")) {
								"Restart"
							}
							.style(GeoCitiesPage.Styles.smallButton)
						}
						.style(GeoCitiesPage.Styles.buttonRow)
					}
					.style(Styles.panel, Styles.deathPanel)

					div(.part(Parts.saves), .hidden, .role("dialog"), .ariaLabelledBy("geocities-adventure-saves-title")) {
						h4(.id("geocities-adventure-saves-title"), .part(Parts.savesTitle)) {
							"Save Game"
						}
						.style(Styles.panelTitle)

						div {
							for slot in 1...3 {
								button(.type(.button), .part(Parts.slot)) {
									"\(slot). Empty"
								}
								.style(Styles.slot)
							}
						}
						.style(Styles.slots)

						button(.type(.button), .hook(Hooks.action, value: "close")) {
							"Cancel"
						}
						.style(GeoCitiesPage.Styles.smallButton)
					}
					.style(Styles.panel)

					div(.part(Parts.hintLine), .hidden, .role("dialog"), .custom(name: "aria-label", value: "Sindresoft Hint Line")) {
						h4 {
							"☎ Sindresoft Hint Line"
						}
						.style(Styles.panelTitle)

						p(.part(Parts.hintText), .role("status")) {}

						p(.part(Parts.hintBill)) {}
							.style(Styles.panelNote)

						div {
							button(.type(.button), .hook(Hooks.action, value: "hint")) {
								"Another Hint (kr 9.90)"
							}
							.style(GeoCitiesPage.Styles.smallButton)

							button(.type(.button), .hook(Hooks.action, value: "close")) {
								"Hang Up"
							}
							.style(GeoCitiesPage.Styles.smallButton)
						}
						.style(GeoCitiesPage.Styles.buttonRow)
					}
					.style(Styles.panel)
				}
				.style(Styles.stage)

				p(.part(Parts.sentence)) {
					"Walk to"
				}
				.style(Styles.sentence)

				div {
					div(.part(Parts.verbs)) {
						for (index, verb) in Self.verbs.enumerated() {
							button(.type(.button), .hook(Hooks.verb, value: verb.id), .ariaPressed(index == 0)) {
								verb.name
							}
							.style(Styles.verb)
						}
					}
					.accessibilityLabel("Verbs")
					.attributes(.role("group"))
					.style(Styles.verbs)

					div(.part(Parts.inventory)) {
						for item in Self.items {
							button(.type(.button), .hook(Hooks.item, value: item.id), .hidden) {
								canvas(.width(16), .height(16)) {}
									.accessibilityHidden()
									.style(Styles.itemIcon)
								span {
									item.name
								}
							}
							.style(Styles.item)
						}

						p(.part(Parts.emptyInventory)) {
							"Your pockets are empty."
						}
						.style(Styles.empty)
					}
					.accessibilityLabel("Inventory")
					.attributes(.role("group"))
					.style(Styles.inventory)

					div(.part(Parts.choices), .hidden) {
						for _ in 1...6 {
							button(.type(.button), .part(Parts.choice)) {}
								.style(Styles.choice)
						}
					}
					.accessibilityLabel("What to say")
					.attributes(.role("group"))
					.style(Styles.choices)
				}
				.style(Styles.controls)

				div {
					button(.type(.button), .hook(Hooks.action, value: "save")) {
						"💾 Save"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.type(.button), .hook(Hooks.action, value: "load")) {
						"📂 Load"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.type(.button), .hook(Hooks.action, value: "call")) {
						"☎ Hint Line (kr 9.90 a minute)"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.type(.button), .hook(Hooks.action, value: "restart")) {
						"↺ Restart"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.type(.button), .hook(Hooks.action, value: "sound"), .ariaPressed(false)) {
						"🔈 Sound: Off"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.style(Styles.gameBody)
		}
		.style(GeoCitiesPage.Styles.window, Styles.gameWindow, GeoCitiesPage.Styles.scriptingOnly)
	}

	enum Parts: String, ElementPartSet {
		case cover
		case game
		case openBox
		case contents
		case install
		case installStatus
		case previousPage
		case nextPage
		case pageLabel
		case score
		case scene
		case speech
		case titleScreen
		case start
		case copyProtection
		case copyQuestion
		case copyAnswer
		case copyStatus
		case death
		case deathText
		case saves
		case savesTitle
		case hintLine
		case hintText
		case hintBill
		case sentence
		case verbs
		case inventory
		case emptyInventory
		case choices

		/**
		The paragraph of a page of the manual that the copy protection asks about.
		*/
		case words

		/**
		A line to say in a conversation.
		*/
		case choice

		/**
		A save slot.
		*/
		case slot
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A thing in the box, like `sticker`.
		*/
		case feelie = "data-adventure-feelie"

		/**
		The number of a floppy disk in the box.
		*/
		case disk = "data-adventure-disk"

		/**
		The number of a page of the manual.
		*/
		case page = "data-adventure-page"

		/**
		A verb of the verb bar, like `look`.
		*/
		case verb = "data-adventure-verb"

		/**
		A thing in the inventory, like `slicer`.
		*/
		case item = "data-adventure-item"

		/**
		What a button of the game does, like `save`.
		*/
		case action = "data-adventure-action"
	}

	enum Styles: ElementStyleSet {
		case root
		case shelf
		case boxColumn
		case box
		case boxPresents
		case boxTitle
		case boxSubtitle
		case cover
		case boxBadges
		case contents
		case contentsText
		case feelies
		case feelie
		case install
		case disks
		case disk
		case diskLabel
		case installStatus
		case manual
		case manualBody
		case manualPage
		case manualTitle
		case manualText
		case pageNumber
		case manualNavigation
		case gameWindow
		case gameTitle
		case gameBody
		case stage
		case scene
		case speech
		case titleScreen
		case panel
		case panelTitle
		case panelNote
		case copyField
		case deathPanel
		case deathTitle
		case slots
		case slot
		case sentence
		case controls
		case verbs
		case verb
		case inventory
		case item
		case itemIcon
		case empty
		case choices
		case choice

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .shelf:
				// The box and the manual side by side on a wide screen, and the manual below the box on a phone.
				Style()
					.grid(columns: 1)
					.gap(.rootEm(1))
					.alignItems(.start)
					.from(.tablet) {
						$0.gridColumns(2)
					}
			case .boxColumn:
				Style().vstack(alignment: .center, spacing: .rootEm(0.75))
			case .box:
				// The front of a big box of a PC game, with the side and the back as a hard shadow, so it looks deep.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.frame(width: .rootEm(17), maxWidth: .percent(100))
					.padding(.rootEm(0.75))
					.backgroundImage(.linearGradient("160deg", Color("#1a1040"), Color("#5a1a6a"), Color("#d0602a")))
					.border(Color("#ffd700"), width: .pixels(3), style: .ridge)
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#3a0a3a")), Shadow(x: .pixels(8), y: .pixels(8), color: Color("#2a062a")), Shadow(x: .pixels(12), y: .pixels(12), color: Color("#00000055")))
					.color(.white)
					.textAlign(.center)
			case .boxPresents:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.letterSpacing(.em(0.2))
					.color(Color("#ffd700"))
			case .boxTitle:
				// The title in gold letters with a hard shadow, like the logo of a LucasArts game.
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.times)
					.font(.extraLarge2, weight: .heavy)
					.italic()
					.lineHeight(1)
					.color(Color("#ffd700"))
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#8a2000")), Shadow(x: .pixels(4), y: .pixels(4), color: .black))
			case .boxSubtitle:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.times)
					.font(.large, weight: .bold)
					.italic()
					.color(Color("#ffeeaa"))
			case .cover:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(160.0 / 100.0)
					.border(Color("#ffd700"), width: .pixels(2))
					.background(Color("#304070"))
					.imageRendering(.pixelated)
			case .boxBadges:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.impact)
					.textStyle(.caption)
					.letterSpacing(.em(0.05))
					.color(Color("#ffffff"))
			case .contents:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(width: .percent(100))
			case .contentsText:
				Style()
					.margin(0)
					.textAlign(.center)
					.textStyle(.caption)
			case .feelies:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .feelie:
				Style().padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
			case .install:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.375))
					.frame(width: .percent(100))
			case .disks:
				Style().hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
			case .disk:
				// A floppy disk with its number on the label, large enough for a finger.
				Style()
					.vstack(alignment: .center, spacing: 0)
					.frame(minWidth: .rootEm(3), minHeight: .rootEm(3))
					.padding(.rootEm(0.25))
					.background(Color("#222233"))
					.border(Color("#555566"), width: .pixels(2), style: .outset)
					.font(.large)
					.color(.white)
					.handCursor()
					.when(.state, is: "done") {
						$0.opacity(0.4)
					}
			case .diskLabel:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .installStatus:
				Style()
					.frame(width: .percent(100), minHeight: .lineHeight(2))
					.margin(0)
					.textStyle(.caption)
					.preservesLineBreaks()
			case .manual:
				Style().frame(width: .percent(100))
			case .manualBody:
				// The paper of the manual.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#fffbe8"))
			case .manualPage:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(minHeight: .rootEm(13))
					.padding(.rootEm(0.75))
					.border(Color("#c8b890"), width: .pixels(1))
					.background(Color("#fffef6"))
					.fontFamily(GeoCitiesPage.times)
					.color(Color("#222222"))
			case .manualTitle:
				Style()
					.margin(0)
					.font(.large, weight: .bold)
					.color(Color("#5a1a6a"))
			case .manualText:
				Style().margin(0)
			case .pageNumber:
				Style()
					.margin(top: .auto)
					.textAlign(.center)
					.textStyle(.caption)
					.color(Color("#666666"))
			case .manualNavigation:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .gameWindow:
				Style()
					.frame(maxWidth: .pixels(720))
					.margin(.horizontal, .auto)
			case .gameTitle:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.flexWrap()
			case .gameBody:
				// The black screen of the game, around the scene and the verbs.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.5))
					.background(.black)
			case .stage:
				Style().position(.relative)
			case .scene:
				// A tap does the verb, and a finger can still scroll the page over the scene.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(320.0 / 160.0)
					.background(Color("#000000"))
					.imageRendering(.pixelated)
					.touchAction(.manipulation)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(-2))
					}
			case .speech:
				// The words of whoever talks, at the top of the scene in their color, with a black edge so they can be read on any picture, like in the LucasArts games.
				Style()
					.position(.absolute)
					.top(.rootEm(0.25))
					.leading(.rootEm(0.5))
					.trailing(.rootEm(0.5))
					.margin(0)
					.fontFamily(GeoCitiesPage.courier)
					.fluidFontSize(fromRem: 0.875, toRem: 1.125, between: .phone, and: .tablet)
					.fontWeight(.bold)
					.lineHeight(1.25)
					.textAlign(.center)
					.color(.white)
					.textShadow(Shadow(x: .pixels(-2), y: 0, color: .black), Shadow(x: .pixels(2), y: 0, color: .black), Shadow(x: 0, y: .pixels(-2), color: .black), Shadow(x: 0, y: .pixels(2), color: .black), Shadow(x: .pixels(2), y: .pixels(2), color: .black))
					.allowsHitTesting(false)
					.when(.state, is: "sindre") {
						$0.color(Color("#ffffff"))
					}
					.when(.state, is: "mamma") {
						$0.color(Color("#ff9ad5"))
					}
					.when(.state, is: "mormor") {
						$0.color(Color("#ffd27a"))
					}
					.when(.state, is: "kevin") {
						$0.color(Color("#7ad7ff"))
					}
					.when(.state, is: "troll") {
						$0.color(Color("#9cff7a"))
					}
					.when(.state, is: "seagull") {
						$0.color(Color("#d0d0d0"))
					}
					.when(.state, is: "fishmonger") {
						$0.color(Color("#ffa060"))
					}
					.when(.state, is: "glitter") {
						$0.color(Color("#e6a0ff"))
					}
					.when(.state, is: "conductor") {
						$0.color(Color("#ff7070"))
					}
					.when(.state, is: "narrator") {
						$0.color(Color("#ffff66"))
					}
			case .titleScreen:
				Style()
					.position(.absolute)
					.leading(0)
					.trailing(0)
					.bottom(.rootEm(0.5))
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .panel:
				// A window of a Sierra game on top of the scene: white, with a double edge. It covers at least the scene, and on a phone, where its text is taller than the scene, it grows down over the verbs, which wait anyway.
				Style()
					.position(.absolute)
					.top(0)
					.leading(0)
					.trailing(0)
					.zIndex(1)
					.frame(minHeight: .percent(100))
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.padding(.rootEm(0.5))
					.background(Color("#f4f4f4"))
					.border(Color("#a00000"), width: .pixels(4), style: .double)
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
					.textAlign(.center)
			case .panelTitle:
				Style()
					.margin(0)
					.font(.regular, weight: .heavy)
					.color(Color("#a00000"))
			case .panelNote:
				Style()
					.margin(0)
					.frame(minHeight: .lineHeight(1))
					.italic()
			case .copyField:
				Style().frame(width: .rootEm(9))
			case .deathPanel:
				Style()
					.background(Color("#d8d8d8"))
					.border(Color("#000080"), width: .pixels(4), style: .double)
			case .deathTitle:
				Style().color(Color("#000080"))
			case .slots:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.frame(width: .percent(100), maxWidth: .rootEm(20))
			case .slot:
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.hover {
						$0.background(Color("#ffffcc"))
					}
			case .sentence:
				// The sentence line, in the light blue of The Secret of Monkey Island.
				Style()
					.frame(minHeight: .lineHeight(1))
					.margin(0)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.textAlign(.center)
					.color(Color("#7fd4ff"))
			case .controls:
				// The verbs on the left and the inventory on the right on a wide screen, and the inventory below the verbs on a phone.
				Style()
					.grid(columns: 1)
					.gap(.rootEm(0.5))
					.from(.smallTablet) {
						$0.gridColumns(2)
					}
			case .verbs:
				Style()
					.grid(columns: 4)
					.gap(.rootEm(0.25))
					.from(.smallTablet) {
						$0.gridColumns(3)
					}
			case .verb:
				// A verb in green, brighter while it is chosen, like the verbs of the LucasArts games.
				Style()
					.frame(minHeight: .rootEm(2.75))
					.padding(.rootEm(0.25))
					.background(Color("#101010"))
					.border(Color("#2a5a2a"), width: .pixels(1))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.color(Color("#3cb043"))
					.handCursor()
					.hover {
						$0.color(Color("#9cff9c"))
					}
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(-2))
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#1f3f1f"))
							.color(Color("#b6ffb6"))
							.border(Color("#9cff9c"), width: .pixels(1))
					}
			case .inventory:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.25))
					.alignContent(.start)
			case .item:
				// A thing in the inventory: its picture and its name, in the purple of the inventory of the LucasArts games.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.frame(minHeight: .rootEm(2.75))
					.padding(.rootEm(0.25))
					.background(Color("#14002a"))
					.border(Color("#4a2a7a"), width: .pixels(1))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.textAlign(.leading)
					.color(Color("#d0a0ff"))
					.handCursor()
					.hover {
						$0.color(Color("#ffffff"))
					}
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(-2))
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#3a1a6a"))
							.color(Color("#ffffff"))
							.border(Color("#d0a0ff"), width: .pixels(1))
					}
			case .itemIcon:
				Style()
					.frame(width: .rootEm(2), height: .rootEm(2))
					.flexShrink(0)
					.imageRendering(.pixelated)
			case .empty:
				Style()
					.margin(0)
					.gridColumnSpan(2)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
					.color(Color("#8a6aaa"))
			case .choices:
				Style()
					.vstack(spacing: .rootEm(0.125))
					.gridColumnSpan(2)
			case .choice:
				// A line to say, in purple, and yellow under the pointer, like the conversations of Monkey Island.
				Style()
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.5))
					.background(Color("#000000"))
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
			}
		}
	}
}
