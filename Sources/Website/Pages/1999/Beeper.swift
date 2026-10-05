import Elementary
import Foundation
import SiteKit

/**
My Beeper, the personsøker that I got from Telenor in 1999: a numeric pager in see-through purple plastic, so you can see the circuit board, the AAA battery, and the little motor that makes it vibrate. Its script, `Beeper.js`, draws it on a canvas, lying on the kitchen table, with its small green LCD, its four rubber buttons, and the belt clip and the sticker with my number on the back. The beeper has its own clock, which runs fast through a Friday in November 1999 while it is on the screen, and it gets pages with numeric codes at believable times of that day: Trond after school, Mamma with 0000 when dinner is ready, Mormor with her own phone number because she does not understand codes, and Lillesøster with every button of the phone. A page beeps, or in the vibrate mode, buzzes the beeper across the table until it falls off, and with reduced motion, it only beeps. The memory keeps the last 10 pages with their times, the light makes the LCD glow, the beeper can be turned upside down so 07734 says hELLO, and the one AAA battery runs low, beeps “LO BATT” at 3 in the morning, and is changed with one from Pappa’s drawer or from the TV remote. In “Decode It!”, the visitor guesses what each page means, for points, and the codes go into my code book. The red Telenor phone booth on the corner, drawn in the rain, has the phone with a display, a keypad with DTMF tones, the slot for a telekort with units that count down, the coin slot for coins of 1, 5, and 10 kroner, the coin return that sometimes has the coin of someone else, and the phone book on a chain with a torn page. The visitor pages me or my friends from there: dial the number of the beeper, wait for the voice and the tone, type the code, and press the pound key. The friends page back (Trond answers 143 with 404), Trond calls the booth back, and the home number is busy because Pappa is on the Internet. Nothing makes a sound until the visitor turns on the sound, and the state is kept in the browser.
*/
struct GeoCitiesBeeper: ScriptedElement {
	static let script = ElementScript()

	var content: some HTML {
		h2 {
			"My Beeper"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"I got a beeper! A real personsøker from Telenor, in see-through purple plastic, so you can see the inside. You cannot talk on it: you call its number, type some numbers, and they show up on it. Everybody in my class has one, and we have codes for everything. My number is 960 10 143. Page me from the phone booth on the corner!"
		}

		div {
			PagerWindow()
			BoothWindow()
			DecoderWindow()
		}
		.style(Styles.toys, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My beeper needs JavaScript. And one AAA battery."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The beeper on the kitchen table, with its buttons, and the battery.
	*/
	private struct PagerWindow: HTML {
		var body: some HTML {
			section(.tabindex(-1)) {
				h3 {
					"My Beeper: 960 10 143"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					canvas(.part(Parts.table), .width(320), .height(220), .tabindex(0), .role("application")) {}
						.accessibilityLabel("My beeper on the kitchen table. Press R to read the pages, M to change between beep, vibrate, and silent, L for the light, C to clear a page, and U to turn it upside down.")
						.style(Styles.canvas, Styles.tableCanvas)

					PagerButtons()

					// The status is right under the buttons of the beeper, so it can be seen on a phone too.
					p(.part(Parts.status), .role("status")) {
						"The beeper is on. Waiting for pages…"
					}
					.style(Styles.status)

					PagerTools()
				}
				.style(GeoCitiesPage.Styles.windowBody, Styles.stack)
			}
			.style(GeoCitiesPage.Styles.window, Styles.window)
		}
	}

	/**
	The four rubber buttons of the beeper.
	*/
	private struct PagerButtons: HTML {
		var body: some HTML {
			div(.role("group")) {
				button(.part(Parts.read), .type(.button)) {
					"Read"
				}
				.style(Styles.pagerButton)

				button(.part(Parts.mode), .type(.button)) {
					"Mode"
				}
				.style(Styles.pagerButton)

				button(.part(Parts.light), .type(.button)) {
					"Light"
				}
				.style(Styles.pagerButton)

				button(.part(Parts.clear), .type(.button)) {
					"Clear"
				}
				.style(Styles.pagerButton)
			}
			.accessibilityLabel("The buttons of the beeper")
			.style(Styles.pagerButtons)
		}
	}

	/**
	What I do with the beeper, and the batteries in the house.
	*/
	private struct PagerTools: HTML {
		var body: some HTML {
			div {
				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔊 Sound (Beeps!)"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.tool, Styles.toggle)

				button(.part(Parts.flip), .type(.button), .ariaPressed(false)) {
					"🙃 Upside Down"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.tool, Styles.toggle)

				button(.part(Parts.over), .type(.button), .ariaPressed(false)) {
					"🔄 Turn It Over"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.tool, Styles.toggle)

				button(.part(Parts.bed), .type(.button)) {
					"🛏 Go to Bed"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.tool)

				button(.part(Parts.pickUp), .type(.button), .hidden) {
					"🫳 Pick It Up"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.tool, Styles.urgent)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			div {
				button(.part(Parts.drawer), .type(.button)) {
					"🔋 Battery from Pappa’s Drawer"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.tool)

				button(.part(Parts.remote), .type(.button)) {
					"📺 Battery from the TV Remote"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.tool)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
	}

	/**
	The phone booth on the corner, with the phone, my pocket, and the phone book.
	*/
	private struct BoothWindow: HTML {
		var body: some HTML {
			section(.tabindex(-1)) {
				h3 {
					"The Phone Booth on the Corner"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					canvas(.part(Parts.booth), .width(320), .height(240), .tabindex(0), .role("application")) {}
						.accessibilityLabel("The red Telenor phone booth on the corner, in the rain. Press H to lift or hang up the handset, type digits, star, and pound to dial, and press B for the phone book.")
						.style(Styles.canvas, Styles.boothCanvas)

					Phone()

					// The status is right under the keypad, so it can be seen on a phone while dialing.
					p(.part(Parts.phoneStatus), .role("status")) {
						"Lift the handset, and pay with the telekort or with coins."
					}
					.style(Styles.status)

					Pocket()
					PhoneBook()
				}
				.style(GeoCitiesPage.Styles.windowBody, Styles.stack)
			}
			.style(GeoCitiesPage.Styles.window, Styles.window)
		}
	}

	/**
	The gray metal phone of the booth: the display, the keypad, and the slots.
	*/
	private struct Phone: HTML {
		private static let keys: [(key: String, name: String)] = [
			("1", "1"), ("2", "2"), ("3", "3"),
			("4", "4"), ("5", "5"), ("6", "6"),
			("7", "7"), ("8", "8"), ("9", "9"),
			("*", "Star"), ("0", "0"), ("#", "Pound"),
		]

		var body: some HTML {
			div {
				p {
					"TELENOR"
				}
				.accessibilityHidden()
				.style(Styles.brand)

				output(.part(Parts.display)) {
					"LØFT RØRET"
				}
				.accessibilityLabel("The display of the phone")
				.style(Styles.phoneDisplay)

				div(.role("group")) {
					for key in Self.keys {
						button(.type(.button), .hook(Hooks.key, value: key.key)) {
							key.key
						}
						.accessibilityLabel(key.name)
						.style(Styles.key)
					}
				}
				.accessibilityLabel("The keypad")
				.style(Styles.keypad)

				div {
					button(.part(Parts.handset), .type(.button)) {
						"📞 Lift the Handset"
					}
					.style(GeoCitiesPage.Styles.retroButton, Styles.wide)

					button(.part(Parts.card), .type(.button)) {
						span {
							span {}
								.style(Styles.chip)
						}
						.accessibilityHidden()
						.style(Styles.telekort)

						span(.part(Parts.cardLabel)) {
							"Insert Telekort"
						}
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.slotButton)

					button(.part(Parts.coinReturn), .type(.button)) {
						"⏏ Coin Return"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.slotButton)
				}
				.style(Styles.slots)
			}
			.style(Styles.phone)
		}
	}

	/**
	My pocket: the coins to put in the phone, and the money for a new telekort.
	*/
	private struct Pocket: HTML {
		var body: some HTML {
			div {
				p {
					"My pocket. Click a coin to put it in the phone:"
				}
				.style(GeoCitiesPage.Styles.caption)

				div(.role("group")) {
					coin(1, style: Styles.oneKrone, hasHole: true)
					coin(5, style: Styles.fiveKroner, hasHole: true)
					coin(10, style: Styles.tenKroner, hasHole: false)
				}
				.accessibilityLabel("Coins")
				.style(Styles.coins)

				p(.part(Parts.pocket)) {}
					.style(GeoCitiesPage.Styles.lcd, Styles.pocketLine)

				div {
					button(.part(Parts.take), .type(.button), .hidden) {
						"🪙 Take the Coins from the Cup"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.tool, Styles.urgent)

					button(.part(Parts.narvesen), .type(.button)) {
						"🏪 Buy a Telekort at Narvesen (40 kr)"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.tool)

					button(.part(Parts.allowance), .type(.button)) {
						"👩 Ask Mamma for Lommepenger"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.tool)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.style(Styles.pocket)
		}

		private func coin(_ value: Int, style: Styles, hasHole: Bool) -> some HTML {
			button(.type(.button), .hook(Hooks.coin, value: "\(value)")) {
				span {
					if hasHole {
						span {}
							.style(Styles.coinHole)
					} else {
						"\(value)"
					}
				}
				.accessibilityHidden()
				.style(Styles.coin, style)

				span(.hook(Hooks.coinCount, value: "\(value)")) {
					"\(value) kr"
				}
			}
			.style(Styles.coinButton)
		}
	}

	/**
	The phone book on a chain under the phone, with a page torn out.
	*/
	private struct PhoneBook: HTML {
		var body: some HTML {
			button(.part(Parts.phoneBookToggle), .type(.button), .ariaExpanded(false), .ariaControls("geocities-beeper-phone-book")) {
				"📖 The Phone Book on the Chain"
			}
			.style(GeoCitiesPage.Styles.smallButton, Styles.wide)

			div(.id("geocities-beeper-phone-book"), .part(Parts.phoneBook), .hidden) {
				p(.part(Parts.phoneBookTitle)) {}
					.style(Styles.phoneBookTitle)

				ul(.part(Parts.phoneBookEntries)) {}
					.style(Styles.phoneBookEntries)

				p(.part(Parts.phoneBookNote)) {}
					.style(GeoCitiesPage.Styles.caption)

				div {
					button(.part(Parts.phoneBookPrevious), .type(.button)) {
						"◀ Page"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.part(Parts.phoneBookNext), .type(.button)) {
						"Page ▶"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.style(Styles.phoneBook)
		}
	}

	/**
	The guessing game of the codes, my code book, and the memory of the beeper.
	*/
	private struct DecoderWindow: HTML {
		var body: some HTML {
			section(.part(Parts.decoderWindow), .tabindex(-1)) {
				h3 {
					"Decode It!"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					p {
						"What does the newest page mean? Guess right for points. Right or wrong, the code goes in my code book."
					}
					.style(GeoCitiesPage.Styles.caption)

					p(.part(Parts.decodeCode)) {
						"No new pages."
					}
					.style(GeoCitiesPage.Styles.lcd, Styles.decodeCode)

					div(.role("group")) {
						for index in 0..<3 {
							button(.type(.button), .hook(Hooks.choice, value: "\(index)"), .hidden) {}
								.style(Styles.choice)
						}
					}
					.accessibilityLabel("What it means")
					.style(Styles.choices)

					// What the guess was is right under the guesses, as the status of the beeper is far up on a phone.
					p(.part(Parts.decodeStatus), .role("status")) {
						"Which one is it?"
					}
					.style(Styles.status)

					p(.part(Parts.score)) {
						"Points: 0"
					}
					.style(GeoCitiesPage.Styles.lcd, Styles.pocketLine)

					CodeBook()
				}
				.style(GeoCitiesPage.Styles.windowBody, Styles.stack)
			}
			.style(GeoCitiesPage.Styles.window, Styles.window, Styles.decoderWindow)
		}
	}

	/**
	My code book, in the back of my school planner, and the memory of the beeper.
	*/
	private struct CodeBook: HTML {
		var body: some HTML {
			div {
				div {
					h4 {
						"My Code Book"
					}
					.style(Styles.subheading)

					p(.part(Parts.bookCount)) {}
						.style(GeoCitiesPage.Styles.caption)

					ul(.part(Parts.book)) {}
						.accessibilityLabel("My code book")
						.style(Styles.notebook)
				}

				div {
					h4 {
						"Memory: the Last 10 Pages"
					}
					.style(Styles.subheading)

					ol(.part(Parts.memory)) {}
						.accessibilityLabel("The pages in the memory of the beeper")
						.style(Styles.memory)
				}
			}
			.style(Styles.bookColumns)
		}
	}

	enum Parts: String, ElementPartSet {
		case table
		case read
		case mode
		case light
		case clear
		case sound
		case flip
		case over
		case bed
		case pickUp
		case drawer
		case remote
		case status

		case booth
		case display
		case handset
		case card
		case cardLabel
		case coinReturn
		case pocket
		case take
		case narvesen
		case allowance
		case phoneBookToggle
		case phoneBook
		case phoneBookTitle
		case phoneBookEntries
		case phoneBookNote
		case phoneBookPrevious
		case phoneBookNext
		case phoneStatus

		case decoderWindow
		case decodeCode
		case decodeStatus
		case score
		case bookCount
		case book
		case memory
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A key of the keypad of the phone, with what it types: a digit, `*`, or `#`.
		*/
		case key = "data-beeper-key"

		/**
		A coin in my pocket, with its value in kroner: `1`, `5`, or `10`.
		*/
		case coin = "data-beeper-coin"

		/**
		How many coins of a value are in my pocket, which the script writes, with the value.
		*/
		case coinCount = "data-beeper-coin-count"

		/**
		A guess of what a page means, with its place among the guesses.
		*/
		case choice = "data-beeper-choice"
	}

	enum Styles: ElementStyleSet {
		case root
		case toys
		case window
		case decoderWindow
		case stack
		case canvas
		case tableCanvas
		case boothCanvas
		case pagerButtons
		case pagerButton
		case tool
		case toggle
		case urgent
		case wide
		case status
		case phone
		case brand
		case phoneDisplay
		case keypad
		case key
		case slots
		case slotButton
		case telekort
		case chip
		case pocket
		case coins
		case coinButton
		case coin
		case coinHole
		case oneKrone
		case fiveKroner
		case tenKroner
		case pocketLine
		case phoneBook
		case phoneBookTitle
		case phoneBookEntries
		case decodeCode
		case choices
		case choice
		case subheading
		case bookColumns
		case notebook
		case memory

		/**
		The see-through purple plastic of the beeper.
		*/
		private static let purple = Color("#8a3fd1")

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .toys:
				Style()
					.grid(minimumColumnWidth: .rootEm(18))
					.gap(.rootEm(1.25))
					.alignItems(.start)
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .window:
				Style().frame(minWidth: 0)
			case .decoderWindow:
				// The decoder and the code book are wide, under the beeper and the booth.
				Style().from(.tablet) {
					$0.gridColumnSpan(2)
				}
			case .stack:
				Style().vstack(spacing: .rootEm(0.625))
			case .canvas:
				// Big pixels.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.imageRendering(.pixelated)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.background(.black)
					.touchAction(.manipulation)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .tableCanvas:
				Style().aspectRatio(320.0 / 220.0)
			case .boothCanvas:
				Style().aspectRatio(320.0 / 240.0)
			case .pagerButtons:
				Style()
					.grid(columns: 4)
					.gap(.rootEm(0.375))
			case .pagerButton:
				// The rubber buttons of the beeper, in the same see-through purple as the plastic.
				Style()
					.frame(minHeight: .rootEm(2.75))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.25))
					.backgroundImage(.linearGradient("to bottom", Color("#c99cf0"), Styles.purple))
					.border(Color("#5a1f8f"), width: .pixels(2), style: .outset)
					.cornerRadius(.capsule)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.textCase(.uppercase)
					.color(.white)
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: Color("#3a0066")))
					.handCursor()
					.active {
						$0.border(Color("#5a1f8f"), width: .pixels(2), style: .inset)
					}
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .tool:
				Style().frame(minHeight: .rootEm(2.25))
			case .toggle:
				Style()
					.when(.state, is: "on") {
						$0
							.background(Color("#ffff99"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .urgent:
				Style().background(Color("#ffcc66"))
			case .wide:
				Style().frame(width: .percent(100), minHeight: .rootEm(2.5))
			case .status:
				Style()
					.frame(minHeight: .lineHeight(3))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .phone:
				// The gray metal card phone of Telenor, bolted to the wall of the booth.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.625))
					.backgroundImage(.linearGradient("to bottom", Color("#d4d7dc"), Color("#8e939b")))
					.border(Color("#b0b4ba"), width: .pixels(4), style: .ridge)
					.cornerRadius(.pixels(6))
			case .brand:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.impact)
					.textStyle(.headline)
					.letterSpacing(.pixels(3))
					.textAlign(.center)
					.color(Color("#0033a0"))
			case .phoneDisplay:
				// The gray green display of the phone, with black letters and two lines.
				Style()
					.display(.block)
					.frame(minHeight: .lineHeight(2.6))
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.5))
					.background(Color("#b7c49a"))
					.border(Color("#4a4f55"), width: .pixels(3), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.color(Color("#1b2410"))
					.preservesLineBreaks()
					.overflowWrap(.anywhere)
			case .keypad:
				// A finger on the keypad dials instead of zooming the page.
				Style()
					.grid(columns: 3)
					.gap(.rootEm(0.375))
					.frame(width: .percent(100), maxWidth: .rootEm(14))
					.margin(.horizontal, .auto)
					.touchAction(.manipulation)
			case .key:
				// A square steel key, which is pressed in while it is held.
				Style()
					.frame(minHeight: .rootEm(2.75))
					.padding(0)
					.backgroundImage(.linearGradient("to bottom", Color("#f2f3f5"), Color("#a6abb3")))
					.border(Color("#e8e9ec"), width: .pixels(3), style: .outset)
					.cornerRadius(.pixels(4))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.title, weight: .bold)
					.color(Color("#1a1a1a"))
					.handCursor()
					.active {
						$0
							.border(Color("#e8e9ec"), width: .pixels(3), style: .inset)
							.background(Color("#9aa0a8"))
					}
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(1))
					}
			case .slots:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.375))
					.children("*:first-child") {
						$0.gridColumnSpan(2)
					}
			case .slotButton:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.frame(minHeight: .rootEm(2.5))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.375))
			case .telekort:
				// A small telekort with a picture of a fjord, and the gold chip.
				Style()
					.display(.inlineBlock)
					.position(.relative)
					.frame(width: .rootEm(2), height: .rootEm(1.3))
					.flexShrink(0)
					.backgroundImage(.linearGradient("to bottom", Color("#5aa0e0"), Color("#2f6a3a")))
					.border(Color("#ffffff"), width: .pixels(1))
					.cornerRadius(.pixels(3))
			case .chip:
				Style()
					.position(.absolute)
					.top(.pixels(3))
					.leading(.pixels(3))
					.frame(width: .pixels(8), height: .pixels(7))
					.backgroundImage(.linearGradient("to bottom right", Color("#ffe58a"), Color("#b08a1a")))
					.cornerRadius(.pixels(1))
			case .pocket:
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(.rootEm(0.5))
					.background(Color("#2c3e6b"))
					.border(Color("#1a2747"), width: .pixels(2), style: .inset)
					.color(.white)
			case .coins:
				Style()
					.hstack(alignment: .end, justification: .center, spacing: .rootEm(0.75))
					.flexWrap()
			case .coinButton:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.frame(minWidth: .rootEm(3.5), minHeight: .rootEm(2.75))
					.padding(.rootEm(0.25))
					.background(.transparent)
					.border(.transparent, width: .pixels(2))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.white)
					.handCursor()
					.active {
						$0.scaleEffect(0.92)
					}
					.disabled {
						$0.opacity(0.4)
					}
					.focusVisible {
						$0.focusRing(Color("#ffff66"), width: .pixels(2), offset: .pixels(1))
					}
			case .coin:
				Style()
					.hstack(alignment: .center, justification: .center)
					.cornerRadius(.circle)
					.border(Color("#ffffff99"), width: .pixels(2), style: .outset)
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.caption, weight: .bold)
					.color(Color("#5a4300"))
			case .coinHole:
				// The hole in the middle of the coins of 1 and 5 kroner, where the blue of my jacket pocket shows through.
				Style()
					.display(.block)
					.frame(width: .percent(28), height: .percent(28))
					.cornerRadius(.circle)
					.background(Color("#2c3e6b"))
					.border(Color("#00000066"), width: .pixels(1), style: .inset)
			case .oneKrone:
				Style()
					.frame(width: .rootEm(2.1), height: .rootEm(2.1))
					.backgroundImage(.radialGradient("circle at 35% 30%", Color("#ffffff"), Color("#c4c8cc"), Color("#7d838a")))
			case .fiveKroner:
				Style()
					.frame(width: .rootEm(2.6), height: .rootEm(2.6))
					.backgroundImage(.radialGradient("circle at 35% 30%", Color("#ffffff"), Color("#bcc1c6"), Color("#70767d")))
			case .tenKroner:
				Style()
					.frame(width: .rootEm(2.4), height: .rootEm(2.4))
					.backgroundImage(.radialGradient("circle at 35% 30%", Color("#fff3b0"), Color("#d9b440"), Color("#8a6a10")))
			case .pocketLine:
				Style()
					.margin(0)
					.textStyle(.caption, weight: .bold)
					.preservesLineBreaks()
			case .phoneBook:
				// The thin white pages of Telefonkatalogen, gray from all the fingers.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(.rootEm(0.625))
					.background(Color("#f4f1e4"))
					.border(Color("#9a8f6a"), width: .pixels(2), style: .solid)
					.color(.black)
			case .phoneBookTitle:
				Style()
					.margin(0)
					.padding(.bottom, .rootEm(0.25))
					.border(.bottom, Color("#000000"), width: .pixels(2))
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.headline, weight: .bold)
			case .phoneBookEntries:
				Style()
					.vstack(spacing: .rootEm(0.125))
					.margin(0)
					.padding(0)
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.caption)
					.children("li") {
						$0
							.hstack(alignment: .start, justification: .spaceBetween, spacing: .rootEm(0.5))
							.flexWrap()
					}
					.children("li strong") {
						$0.fontFamily(GeoCitiesPage.courier)
					}
			case .decodeCode:
				Style()
					.margin(0)
					.textStyle(.title)
					.textAlign(.center)
					.overflowWrap(.anywhere)
			case .choices:
				Style()
					.grid(minimumColumnWidth: .rootEm(10))
					.gap(.rootEm(0.375))
			case .choice:
				Style()
					.frame(minHeight: .rootEm(2.75))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.handCursor()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
					.when(.state, is: "right") {
						$0
							.background(Color("#99ff99"))
							.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
					.when(.state, is: "wrong") {
						$0
							.background(Color("#ff9999"))
							.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
			case .subheading:
				Style()
					.margin(top: .rootEm(0.25), bottom: .rootEm(0.25))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
			case .bookColumns:
				Style()
					.grid(minimumColumnWidth: .rootEm(15))
					.gap(.rootEm(1))
					.alignItems(.start)
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .notebook:
				// Lined paper of the school planner, written in pencil.
				Style()
					.vstack(spacing: 0)
					.margin(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#fffef6"), Color("#fdf8e2")))
					.border(.leading, Color("#e05555"), width: .pixels(3))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption)
					.color(Color("#333344"))
					.children("li") {
						$0
							.padding(vertical: .rootEm(0.125), horizontal: 0)
							.border(.bottom, Color("#9ec3e6"), width: .pixels(1))
							.overflowWrap(.anywhere)
					}
			case .memory:
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.5))
					.padding(.leading, .rootEm(2))
					.background(Color("#0a2a0a"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#33ff66"))
					.children("li") {
						$0.overflowWrap(.anywhere)
					}
			}
		}
	}
}
