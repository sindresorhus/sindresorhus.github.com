import Elementary
import Foundation
import SiteKit

/**
The Print Shop by Brøderbund, from 1984 and still on every school computer in 1999, with the dot matrix printer of the computer room next to it. The program has the blocky menus of the DOS version in the colors of CGA: the visitor picks a Greeting Card, a Sign, Letterhead, or a Banner, and then a border, a graphic from the clip art library (Glitter the unicorn, a waffle, a heart, the flag of Norway, a computer, a birthday cake, Rocky the pet rock, and an umbrella for Bergen, all pixel art that the script draws), a layout, and one of five chunky fonts, types the words, and sees a preview, with the number of copies (the teacher says one). The printer, an Epson LX-800 that the script draws on a canvas, then prints it line by line, with the head that goes left and right under the smoked lid, the screech of the needles, the paper that rolls out of the top and piles up on the floor in folds, and banners with the letters sideways over many pages. The ribbon fades with each print, so the lines get lighter until the visitor changes it, the box of paper runs out with the “Paper Out” light and a beep, and sometimes the paper jams and crumples, so the visitor opens the lid, pulls it out, and presses On Line. The panel of the printer has On Line, Form Feed, and Line Feed, which only work while it is off line, like on the real one. The visitor tears the printout off along the perforation with a drag (ragged without a Form Feed first) and peels off the strips with the holes. A greeting card is folded and stands up on the desk (the inside is printed upside down on purpose), and a banner can be hung across the top of the 1999 page, where the browser keeps it. Its script, `PrintShop.js`, runs it, only while it is on the screen and the tab is visible, and keeps the design, the ribbon, the paper, and the hanging banner in the browser. Nothing makes a sound until the visitor turns on the sound, and with reduced motion, the printout appears a page at a time, without the moving head. Without scripts, it is left out, as nothing in it works without them.
*/
struct GeoCitiesPrintShop: ScriptedElement {
	static let script = ElementScript()

	private static let modes: [(id: String, name: String)] = [
		("card", "Greeting Card"),
		("sign", "Sign"),
		("letterhead", "Letterhead"),
		("banner", "Banner"),
	]

	private static let borders: [(id: String, name: String)] = [
		("hearts", "Hearts"),
		("stars", "Stars"),
		("flags", "17. Mai"),
		("zigzag", "Zigzag"),
		("checkers", "Checkers"),
		("lines", "Thin Lines"),
		("none", "No Border"),
	]

	private static let graphics: [(id: String, name: String)] = [
		("unicorn", "Unicorn"),
		("waffle", "Waffle"),
		("heart", "Heart"),
		("flag", "Norway"),
		("computer", "Computer"),
		("cake", "Cake"),
		("rocky", "Rocky"),
		("umbrella", "Umbrella"),
		("none", "No Graphic"),
	]

	private static let layouts: [(id: String, name: String)] = [
		("large", "One Large Graphic"),
		("tiled", "Small Tiled Graphics"),
		("corners", "Four Corners"),
	]

	private static let fonts: [(id: String, name: String)] = [
		("block", "Block"),
		("outline", "Outline"),
		("party", "Party"),
		("stencil", "Stencil"),
		("bubble", "Bubble"),
	]

	/**
	The focus goes to the toy when the visitor takes down the banner over the page, as its button goes away with it.
	*/
	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.tabindex(-1)]
	}

	var content: some HTML {
		h2 {
			"The Print Shop"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Every school in Bergen had The Print Shop on the computers of the computer room, and every classroom had a banner from it. Make a card, a sign, letterhead, or a banner as long as the hallway, and print it on the dot matrix printer. The whole school can hear it."
		}

		div {
			computer

			printer

			printout

			card
		}
		.style(Styles.lab, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The Print Shop needs JavaScript. And the key to the computer room."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)

		hanging
	}

	/**
	The beige school computer, with the program on the screen.
	*/
	private var computer: some HTML {
		div {
			div(.part(Parts.screen), .role("group")) {
				p(.part(Parts.title)) {
					"The Print Shop"
				}
				.style(Styles.screenBar)

				menuStep

				choiceStep("border", prompt: "Choose a border", options: Self.borders, hook: .border)

				choiceStep("graphic", prompt: "Choose a graphic", options: Self.graphics, hook: .graphic)

				layoutStep

				choiceStep("font", prompt: "Choose a font", options: Self.fonts, hook: .font)

				textStep

				previewStep

				printingStep

				div {
					button(.part(Parts.back), .type(.button)) {
						"◄ Esc: Back"
					}
					.style(Styles.screenKey)

					span {
						"↑ ↓ to choose · Return to select"
					}
					.accessibilityHidden()
				}
				.style(Styles.screenFooter)
			}
			.accessibilityLabel("The screen of the school computer, with The Print Shop. The arrow keys move between the choices, Return picks one, and Escape goes back.")
			.style(Styles.screen)

			div {
				p {
					"SKOLE-PC 3"
				}
				.style(Styles.monitorBrand)

				p {
					"IKKE SPIS VED PC-EN!"
				}
				.style(Styles.sticker)
			}
			.style(Styles.monitorChin)
		}
		.style(Styles.monitor)
	}

	private var menuStep: some HTML {
		div(.hook(Hooks.step, value: "menu")) {
			p {
				"The Print Shop"
			}
			.accessibilityHidden()
			.style(Styles.logo)

			p {
				"© 1984 Brøderbund · Skolelisens"
			}
			.style(Styles.screenSmall)

			p {
				"What would you like to do?"
			}
			.style(Styles.prompt)

			div {
				for mode in Self.modes {
					button(.type(.button), .hook(Hooks.mode, value: mode.id), .ariaPressed(false)) {
						mode.name
					}
					.style(Styles.menuItem)
				}
			}
			.style(Styles.menuList)
		}
		.style(Styles.step)
	}

	/**
	A step where the visitor picks one of the options, each with a sample that the script draws in the button.
	*/
	private func choiceStep(_ id: String, prompt: String, options: [(id: String, name: String)], hook: Hooks) -> some HTML {
		div(.hook(Hooks.step, value: id), .hidden) {
			p {
				prompt
			}
			.style(Styles.prompt)

			div {
				for option in options {
					button(.type(.button), .hook(hook, value: option.id), .ariaPressed(false)) {
						canvas(.width(64), .height(48)) {}
							.accessibilityHidden()
							.style(Styles.sample)
						span {
							option.name
						}
					}
					.style(Styles.tile)
				}
			}
			.style(Styles.tiles)
		}
		.style(Styles.step)
	}

	private var layoutStep: some HTML {
		div(.hook(Hooks.step, value: "layout"), .hidden) {
			p {
				"Choose a layout for the graphic"
			}
			.style(Styles.prompt)

			div {
				for layout in Self.layouts {
					button(.type(.button), .hook(Hooks.layout, value: layout.id), .ariaPressed(false)) {
						layout.name
					}
					.style(Styles.menuItem)
				}
			}
			.style(Styles.menuList)
		}
		.style(Styles.step)
	}

	private var textStep: some HTML {
		form(.part(Parts.form), .hook(Hooks.step, value: "text"), .hidden) {
			p(.part(Parts.textPrompt)) {
				"Type your message"
			}
			.style(Styles.prompt)

			label {
				span(.part(Parts.firstLabel)) {
					"Message:"
				}
				input(.part(Parts.firstLine), .type(.text), .autocomplete("off"), .maxlength(40))
					.style(Styles.screenField)
			}
			.style(Styles.screenLabel)

			label(.part(Parts.secondRow)) {
				span(.part(Parts.secondLabel)) {
					"Small line:"
				}
				input(.part(Parts.secondLine), .type(.text), .autocomplete("off"), .maxlength(26))
					.style(Styles.screenField)
			}
			.style(Styles.screenLabel)

			button(.type(.submit)) {
				"Continue ►"
			}
			.style(Styles.screenKey)
		}
		.style(Styles.step)
	}

	private var previewStep: some HTML {
		div(.hook(Hooks.step, value: "preview"), .hidden) {
			p {
				"Preview"
			}
			.style(Styles.prompt)

			canvas(.part(Parts.preview), .width(320), .height(200), .role("img")) {}
				.accessibilityLabel("The preview of what will be printed")
				.style(Styles.preview)

			p(.part(Parts.previewNote)) {}
				.style(Styles.screenSmall)

			div {
				span {
					"Copies:"
				}
				button(.part(Parts.fewerCopies), .type(.button)) {
					"−"
				}
				.accessibilityLabel("Fewer copies")
				.style(Styles.screenKey)
				span(.part(Parts.copies)) {
					"1"
				}
				.style(Styles.copies)
				button(.part(Parts.moreCopies), .type(.button)) {
					"+"
				}
				.accessibilityLabel("More copies")
				.style(Styles.screenKey)
			}
			.style(Styles.copiesRow)

			button(.part(Parts.print), .type(.button)) {
				"Print It!"
			}
			.style(Styles.menuItem)
		}
		.style(Styles.step)
	}

	private var printingStep: some HTML {
		div(.hook(Hooks.step, value: "printing"), .hidden) {
			p {
				"Now printing…"
			}
			.style(Styles.prompt)

			p(.part(Parts.printingNote)) {}
				.style(Styles.screenSmall)

			button(.part(Parts.mainMenu), .type(.button)) {
				"Main Menu"
			}
			.style(Styles.menuItem)
		}
		.style(Styles.step)
	}

	/**
	The dot matrix printer of the computer room, on a desk, with its panel, its supplies, and its status.
	*/
	private var printer: some HTML {
		div {
			canvas(.part(Parts.printerCanvas), .width(600), .height(560), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The dot matrix printer on the desk, with the paper coming out of the top and piling up on the floor. To tear off the printout, drag sideways along the top of the printer, or press T.")
				.style(Styles.printerCanvas)

			div(.role("group")) {
				div {
					light("Power", part: nil)
					light("On Line", part: .onlineLight)
					light("Paper Out", part: .paperLight)
				}
				.style(Styles.lights)

				div {
					button(.part(Parts.online), .type(.button), .ariaPressed(true)) {
						"On Line"
					}
					.style(Styles.panelButton)

					button(.part(Parts.formFeed), .type(.button)) {
						"Form Feed"
					}
					.style(Styles.panelButton)

					button(.part(Parts.lineFeed), .type(.button)) {
						"Line Feed"
					}
					.style(Styles.panelButton)
				}
				.style(Styles.panelButtons)

				p {
					"EPSON LX-800"
				}
				.accessibilityHidden()
				.style(Styles.printerBrand)
			}
			.accessibilityLabel("The panel of the printer")
			.style(Styles.panel)

			p(.part(Parts.status), .role("status")) {
				"The printer hums and waits. The teacher says one copy each."
			}
			.style(Styles.status)

			p(.part(Parts.supplies)) {}
				.style(GeoCitiesPage.Styles.lcd, Styles.supplies)

			div {
				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔈 Sound"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.lid), .type(.button), .ariaPressed(false)) {
					"Open the Lid"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.unjam), .type(.button), .hidden) {
					"Pull Out the Crumpled Paper"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.ribbon), .type(.button)) {
					"Change the Ribbon"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.paper), .type(.button)) {
					"New Box of Paper"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.tear), .type(.button), .disabled) {
					"Tear It Off"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.printerArea)
	}

	/**
	A light of the panel with its name. The power light is not a part, as it is always on.
	*/
	@HTMLBuilder
	private func light(_ name: String, part: Parts?) -> some HTML {
		span {
			if let part {
				span(.part(part)) {}
					.accessibilityHidden()
					.style(Styles.light)
			} else {
				span {}
					.accessibilityHidden()
					.style(Styles.light, Styles.lightOn)
			}
			name
		}
		.style(Styles.lightLabel)
	}

	/**
	The printout after it is torn off, where the visitor peels off the strips with the holes, and then folds a card or hangs a banner.
	*/
	private var printout: some HTML {
		div(.part(Parts.printoutBox), .hidden) {
			p(.part(Parts.printoutNote)) {}
				.style(GeoCitiesPage.Styles.caption)

			div {
				canvas(.part(Parts.printoutCanvas), .width(400), .height(300), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The printout. Drag a strip with the holes sideways to peel it off, or press P.")
					.style(Styles.printoutCanvas)
			}
			.style(Styles.printoutScroller)

			div {
				button(.part(Parts.peel), .type(.button)) {
					"Peel Off a Strip"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.fold), .type(.button), .hidden) {
					"Fold It and Stand It Up"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.hang), .type(.button), .hidden) {
					"Hang It Over the Page"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.throwAway), .type(.button)) {
					"Throw It Away"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.printout)
	}

	/**
	The greeting card, folded, standing on the desk.
	*/
	private var card: some HTML {
		div(.part(Parts.card), .hidden) {
			div {
				canvas(.part(Parts.cardFront), .width(320), .height(208), .role("img")) {}
					.accessibilityLabel("The front of the card")
					.style(Styles.cardFace, Styles.cardFront)

				canvas(.part(Parts.cardInside), .width(320), .height(208), .role("img")) {}
					.accessibilityLabel("The other half of the card, with the message")
					.style(Styles.cardFace, Styles.cardInside)
			}
			.style(Styles.cardStage)

			div {
				button(.part(Parts.turn), .type(.button)) {
					"Turn It Around"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.card)
	}

	/**
	The banner that hangs across the top of the 1999 page. The script moves it there.
	*/
	private var hanging: some HTML {
		div(.part(Parts.hanging), .hidden) {
			canvas(.part(Parts.hangingCanvas), .width(680), .height(120), .role("img")) {}
				.accessibilityLabel("A banner that I printed on The Print Shop, hanging across the top of the page")
				.style(Styles.hangingCanvas)

			button(.part(Parts.takeDown), .type(.button)) {
				"Take Down the Banner"
			}
			.style(GeoCitiesPage.Styles.smallButton, Styles.takeDown)
		}
		.style(Styles.hanging)
	}

	enum Parts: String, ElementPartSet {
		case screen
		case title
		case back
		case form
		case textPrompt
		case firstLabel
		case firstLine
		case secondRow
		case secondLabel
		case secondLine
		case preview
		case previewNote
		case fewerCopies
		case moreCopies
		case copies
		case print
		case printingNote
		case mainMenu
		case printerCanvas
		case onlineLight
		case paperLight
		case online
		case formFeed
		case lineFeed
		case supplies
		case sound
		case lid
		case unjam
		case ribbon
		case paper
		case tear
		case status
		case printoutBox
		case printoutNote
		case printoutCanvas
		case peel
		case fold
		case hang
		case throwAway
		case card
		case cardFront
		case cardInside
		case turn
		case hanging
		case hangingCanvas
		case takeDown
	}

	/**
	The steps and the choices of the program, which carry a value, like `font` or `banner`, that a part cannot have, so they stay data attributes.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		A step of the program on the screen, like `font`. The script shows one at a time.
		*/
		case step = "data-print-shop-step"

		/**
		A choice of the main menu, like `banner`.
		*/
		case mode = "data-print-shop-mode"

		case border = "data-print-shop-border"
		case graphic = "data-print-shop-graphic"
		case layout = "data-print-shop-layout"
		case font = "data-print-shop-font"
	}

	enum Styles: ElementStyleSet {
		case root
		case lab
		case monitor
		case screen
		case screenBar
		case step
		case logo
		case screenSmall
		case prompt
		case menuList
		case menuItem
		case tiles
		case tile
		case sample
		case screenLabel
		case screenField
		case screenKey
		case screenFooter
		case preview
		case copiesRow
		case copies
		case monitorChin
		case monitorBrand
		case sticker
		case printerArea
		case printerCanvas
		case panel
		case lights
		case lightLabel
		case light
		case lightOn
		case panelButtons
		case panelButton
		case printerBrand
		case supplies
		case status
		case printout
		case printoutScroller
		case printoutCanvas
		case card
		case cardStage
		case cardFace
		case cardFront
		case cardInside
		case hanging
		case hangingCanvas
		case takeDown

		/**
		The colors of CGA, which the DOS version of The Print Shop used: black, cyan, magenta, and white.
		*/
		private static let cyan = Color("#55ffff")
		private static let magenta = Color("#ff55ff")
		private static let beige = Color("#d8d0b8")

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .lab:
				Style().vstack(alignment: .center, spacing: .rootEm(1.25))
			case .monitor:
				// A beige monitor of the 1990s, with a thick frame around the screen.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(width: .rootEm(32), maxWidth: .percent(100))
					.padding(top: .rootEm(1), horizontal: .rootEm(1), bottom: .rootEm(0.5))
					.backgroundImage(.linearGradient("to bottom", Color("#e6dfca"), Self.beige, Color("#c2b99e")))
					.border(Color("#a39a80"), width: .pixels(2))
					.cornerRadius(.rootEm(0.75))
					.shadow(Shadow(x: .pixels(4), y: .pixels(6), color: Color("#00000059")))
					.color(.black)
			case .screen:
				// The screen in the colors of CGA, with a blocky font in capital letters, like the DOS version.
				Style()
					.vstack(spacing: .rootEm(0.625))
					.frame(minHeight: .rootEm(22))
					.padding(.rootEm(0.75))
					.background(.black)
					.border(Color("#4a4636"), width: .pixels(6), style: .inset)
					.cornerRadius(.rootEm(0.75))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.textCase(.uppercase)
					.color(.white)
					.shadow(Shadow(y: 0, blur: .pixels(14), color: Color("#55ffff33"), isInset: true))
			case .screenBar:
				// The bar at the top of each screen of The Print Shop, in inverse.
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Self.magenta)
					.color(.black)
					.textAlign(.center)
					.letterSpacing(.em(0.1))
			case .step:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.flex(1)
			case .logo:
				// The logo of the title screen, big and blocky.
				Style()
					.margin(top: .rootEm(0.5), bottom: 0)
					.font(.extraLarge2, weight: .heavy)
					.lineHeight(1)
					.letterSpacing(.em(0.05))
					.textAlign(.center)
					.color(Self.cyan)
					.textShadow(Shadow(x: .pixels(3), y: .pixels(3), color: Self.magenta))
			case .screenSmall:
				Style()
					.margin(0)
					.textAlign(.center)
					.color(Self.cyan)
			case .prompt:
				Style()
					.margin(0)
					.textAlign(.center)
					.color(.white)
			case .menuList:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.frame(width: .rootEm(16), maxWidth: .percent(100))
			case .menuItem:
				// A choice of a menu, which shows in inverse while it has the focus, like the bar of the real menu.
				Style()
					.frame(minHeight: .rootEm(2.25))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.75))
					.background(.black)
					.border(Self.cyan, width: .pixels(2))
					.inheritsFont()
					.textStyle(.body, weight: .bold)
					.textCase(.uppercase)
					.color(Self.cyan)
					.handCursor()
					.hover {
						$0
							.background(Self.cyan)
							.color(.black)
					}
					.focusVisible {
						$0
							.background(Self.cyan)
							.color(.black)
							.focusRing(Self.magenta, width: .pixels(2), offset: .pixels(2))
					}
					.when(.state, is: "selected") {
						$0.border(Self.magenta, width: .pixels(2))
					}
			case .tiles:
				Style()
					.grid(minimumColumnWidth: .rootEm(6))
					.gap(.rootEm(0.375))
					.frame(width: .percent(100))
			case .tile:
				// A choice with a sample, like a page of the clip art library.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.padding(.rootEm(0.25))
					.background(.black)
					.border(Color("#555555"), width: .pixels(2))
					.inheritsFont()
					.textStyle(.caption, weight: .bold)
					.textCase(.uppercase)
					.color(.white)
					.handCursor()
					.hover {
						$0.border(Self.cyan, width: .pixels(2))
					}
					.focusVisible {
						$0
							.background(Color("#003a3a"))
							.border(Self.cyan, width: .pixels(2))
							.focusRing(Self.magenta, width: .pixels(2), offset: .pixels(1))
					}
					.when(.state, is: "selected") {
						$0
							.border(Self.magenta, width: .pixels(2))
							.color(Self.magenta)
					}
			case .sample:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(64.0 / 48.0)
					.imageRendering(.pixelated)
			case .screenLabel:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.frame(width: .percent(100))
					.color(Self.cyan)
			case .screenField:
				// A field in the program, white on black with a blocky cursor.
				Style()
					.frame(width: .percent(100), minHeight: .rootEm(2.25))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.375))
					.background(.black)
					.border(.white, width: .pixels(2))
					.inheritsFont()
					.textStyle(.body, weight: .bold)
					.textCase(.uppercase)
					.color(.white)
					.focusVisible {
						$0
							.borderColor(Self.magenta)
							.focusRing(Self.magenta, width: .pixels(1), offset: .pixels(1))
					}
			case .screenKey:
				Style()
					.frame(minWidth: .rootEm(2.25), minHeight: .rootEm(2.25))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Self.cyan)
					.border(Self.cyan, width: .pixels(2))
					.inheritsFont()
					.textStyle(.caption, weight: .bold)
					.textCase(.uppercase)
					.color(.black)
					.handCursor()
					.hover {
						$0.background(.white)
					}
					.focusVisible {
						$0.focusRing(Self.magenta, width: .pixels(2), offset: .pixels(2))
					}
			case .screenFooter:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.flexWrap()
					.padding(.top, .rootEm(0.375))
					.border(.top, Color("#555555"), width: .pixels(2), style: .dashed)
					.color(Color("#aaaaaa"))
			case .preview:
				// The page on the screen, in big pixels.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto, maxWidth: .rootEm(24))
					.aspectRatio(320.0 / 200.0)
					.imageRendering(.pixelated)
					.border(Self.cyan, width: .pixels(2))
			case .copiesRow:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.color(Self.cyan)
			case .copies:
				Style()
					.frame(minWidth: .rootEm(1.5))
					.textStyle(.body, weight: .bold)
					.textAlign(.center)
					.color(.white)
			case .monitorChin:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.flexWrap()
			case .monitorBrand:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.letterSpacing(.em(0.2))
					.color(Color("#6e6650"))
			case .sticker:
				// The note that the teacher taped on every computer.
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Color("#fff27a"))
					.border(Color("#c9b400"), width: .pixels(1))
					.rotationEffect(.degrees(-3))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(Color("#cc0000"))
			case .printerArea:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.frame(width: .rootEm(36), maxWidth: .percent(100))
			case .printerCanvas:
				// A sideways drag tears the paper off, and the page still scrolls up and down over it.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(600.0 / 560.0)
					.touchAction(.panY)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .panel:
				// The front panel of the printer, beige like the printer, with the lights and the three buttons.
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.flexWrap()
					.frame(width: .percent(100))
					.margin(.top, .rootEm(-0.75))
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.75))
					.background(Self.beige)
					.border(Color("#a39a80"), width: .pixels(2))
					.cornerRadius(.rootEm(0.375))
					.color(Color("#333333"))
			case .lights:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.flexWrap()
			case .lightLabel:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.fontFamily(.system)
					.font(.extraSmall, weight: .bold)
					.textCase(.uppercase)
			case .light:
				// A small light, dark while it is off.
				Style()
					.frame(width: .rootEm(0.625), height: .rootEm(0.625))
					.background(Color("#3a3a2a"))
					.border(Color("#222222"), width: .pixels(1))
					.cornerRadius(.circle)
					.when(.state, is: "on") {
						$0
							.background(Color("#44ff44"))
							.shadow(Shadow(y: 0, blur: .pixels(5), color: Color("#44ff44")))
					}
					.when(.state, is: "warning") {
						$0
							.background(Color("#ffaa00"))
							.shadow(Shadow(y: 0, blur: .pixels(6), color: Color("#ff8800")))
					}
					.when(.state, is: "blink") {
						$0
							.background(Color("#ffaa00"))
							.media(.allowsMotion) {
								$0.animation(GeoCitiesPage.Animations.blink, .timingCurve("steps(1, end)", duration: .seconds(0.6)).repeatForever(autoreverses: false))
							}
					}
			case .lightOn:
				Style()
					.background(Color("#44ff44"))
					.shadow(Shadow(y: 0, blur: .pixels(5), color: Color("#44ff44")))
			case .panelButtons:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .panelButton:
				// The square buttons of the printer, big enough for a finger.
				Style()
					.frame(minWidth: .rootEm(4.5), minHeight: .rootEm(2.5))
					.padding(.horizontal, .rootEm(0.375))
					.background(Color("#8c8672"))
					.border(Color("#bdb59a"), width: .pixels(2), style: .outset)
					.cornerRadius(.rootEm(0.25))
					.fontFamily(.system)
					.font(.extraSmall, weight: .heavy)
					.textCase(.uppercase)
					.color(.white)
					.handCursor()
					.active {
						$0.border(Color("#bdb59a"), width: .pixels(2), style: .inset)
					}
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .printerBrand:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.italic()
					.letterSpacing(.em(0.1))
					.color(Color("#1a3a8a"))
			case .supplies:
				Style()
					.margin(0)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .status:
				Style()
					.frame(maxWidth: .rootEm(34), minHeight: .lineHeight(3))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .printout:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.frame(width: .percent(100))
			case .printoutScroller:
				// A banner is long, so it scrolls sideways in its own box instead of making the page wider.
				Style()
					.frame(maxWidth: .percent(100))
					.overflow(horizontal: .auto)
					.padding(.rootEm(0.5))
					.background(Color("#7a6a55"))
					.border(Color("#5a4a35"), width: .pixels(3), style: .ridge)
			case .printoutCanvas:
				// A sideways drag peels a strip, and the page still scrolls up and down over it. A page fits the width, and a banner keeps its height and scrolls sideways in its box, where the script drags it, as a finger cannot scroll it sideways over the canvas.
				Style()
					.display(.block)
					.touchAction(.panY)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
					.when(.state, is: "page") {
						$0.frame(width: .percent(100), height: .auto, maxWidth: .rootEm(24))
					}
					.when(.state, is: "banner") {
						$0.frame(width: .auto, height: .rootEm(12), maxWidth: .none)
					}
			case .card:
				Style().vstack(alignment: .center, spacing: .rootEm(0.75))
			case .cardStage:
				// The desk that the card stands on.
				Style()
					.vstack(alignment: .center, spacing: 0)
					.frame(width: .rootEm(22), maxWidth: .percent(100))
					.padding(top: .rootEm(1.5), horizontal: .rootEm(1), bottom: .rootEm(1))
					.backgroundImage(.linearGradient("to bottom", Color("#cfe3f0"), Color("#cfe3f0"), Color("#a07850"), Color("#7a5a3a")))
					.border(Color("#5a4028"), width: .pixels(2))
			case .cardFace:
				// A half of the printed page, which folds at the line between them.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(320.0 / 208.0)
					.background(.white)
					.transition(.transform, .opacity, .shadow, animation: .easeInOut(duration: .seconds(0.7)))
					.reducedMotion {
						$0.noTransition()
					}
			case .cardFront:
				Style()
					.when(ancestorHas: ScriptAttribute.state, is: "standing") {
						$0
							.transform("perspective(700px) translateY(50%) rotateX(22deg) translateY(-50%)")
							.shadow(Shadow(x: .pixels(10), y: .pixels(14), blur: .pixels(10), color: Color("#00000066")))
					}
					.when(ancestorHas: ScriptAttribute.state, is: "turning") {
						$0.transform("perspective(700px) translateY(50%) rotateX(22deg) translateY(-50%) rotateY(90deg)")
					}
					.when(ancestorHas: ScriptAttribute.state, is: "back") {
						$0.hidden()
					}
			case .cardInside:
				// The inside is printed upside down, so it is turned the right way up on the back of the standing card.
				Style()
					.when(ancestorHas: ScriptAttribute.state, is: "folding") {
						$0
							.transform("perspective(700px) translateY(-50%) rotateX(-90deg) translateY(50%)")
							.opacity(0.4)
					}
					.when(ancestorHas: ScriptAttribute.state, is: "standing") {
						$0.hidden()
					}
					.when(ancestorHas: ScriptAttribute.state, is: "turning") {
						$0.hidden()
					}
					.when(ancestorHas: ScriptAttribute.state, is: "back") {
						$0
							.transform("perspective(700px) translateY(50%) rotateX(22deg) translateY(-50%) rotate(180deg)")
							.shadow(Shadow(x: .pixels(10), y: .pixels(14), blur: .pixels(10), color: Color("#00000066")))
					}
			case .hanging:
				// The banner, taped up across the top of the page.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.margin(.bottom, .rootEm(1))
			case .hangingCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
			case .takeDown:
				Style()
					.alignSelf(.end)
			}
		}
	}
}
