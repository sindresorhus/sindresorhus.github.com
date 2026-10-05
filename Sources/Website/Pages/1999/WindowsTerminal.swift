import Elementary
import Foundation
import SiteKit

/**
HyperTerminal of Windows 98 (by Hilgraeve) on the desktop of my computer (``GeoCitiesPage/desktop``): the Connection Description with its icons, a list of the BBSes of Bergen to dial, and the black screen of a terminal with the colors of ANSI. Fjordnet BBS answers, with a unicorn in ANSI art, a log on for new users, the message base with the posts of the kids of Bergen, the file area with a download at 2400 baud that never finishes, who is online, a chat with the SysOp while he eats dinner, and the doors, where Legend of the Red Troll is, a game like Legend of the Red Dragon. The other numbers are busy, do not answer, or are a fax machine. It is the content of its window of the desktop, and its script, `WindowsTerminal.js`, runs the BBS, keeps the hero of the door game in the browser, and makes the sounds of the modem when the visitor turns them on.
*/
struct GeoCitiesWindowsTerminal: ScriptedElement {
	static let script = ElementScript()

	/**
	The BBSes of Bergen in the phone book of HyperTerminal, by the value that the script knows them by.
	*/
	private static let numbers: [(value: String, title: String)] = [
		("fjordnet", "Fjordnet BBS, 55 31 19 99"),
		("bryggen", "Bryggen Bulletin Board, 55 23 10 00"),
		("ulriken", "Ulriken Underground, 55 99 66 66"),
		("office", "Pappa’s office, 55 20 40 80"),
		("mormor", "Mormor, 55 18 12 34"),
	]

	/**
	The icons of the Connection Description, like the ones of HyperTerminal: a phone, a globe, and some more.
	*/
	private static let icons = ["📞", "🌐", "🏰", "🦄", "🧇", "💾"]

	var content: some HTML {
		div {
			button(.part(Parts.call), .type(.button)) {
				"📞 Call"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.hangUp), .type(.button), .disabled) {
				"🔌 Hang Up"
			}
			.style(GeoCitiesPage.Styles.smallButton)

			button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
				"🔊 Modem sounds"
			}
			.help("Plays the sounds of the modem")
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(GeoCitiesWindows.Styles.toolbar, GeoCitiesPage.Styles.scriptingOnly)

		form(.part(Parts.setup)) {
			p {
				strong {
					"Connection Description"
				}
			}

			p {
				"Enter a name and choose an icon for the connection:"
			}

			div {
				label(.for("geocities-term-name")) {
					"Name:"
				}

				input(.id("geocities-term-name"), .part(Parts.name), .type(.text), .value("Fjordnet"), .autocomplete("off"), .maxlength(20), .custom(name: "spellcheck", value: "false"))
					.style(GeoCitiesPage.Styles.field)
			}
			.style(GeoCitiesWindows.Styles.nowrapRow)

			fieldset {
				legend {
					"Icon:"
				}
				.style(Styles.legend)

				for (index, icon) in Self.icons.enumerated() {
					label {
						input(.type(.radio), .name("geocities-term-icon"), .value(icon))
							.attributes(.checked, when: index == 0)

						span {
							icon
						}
						.style(Styles.iconPicture)
					}
					.style(Styles.iconChoice)
				}
			}
			.style(Styles.icons)

			div {
				label(.for("geocities-term-number")) {
					"Phone number:"
				}

				select(.id("geocities-term-number"), .part(Parts.number)) {
					for (value, title) in Self.numbers {
						option(.value(value)) {
							title
						}
					}
				}
				.style(GeoCitiesPage.Styles.field)
			}
			.style(GeoCitiesWindows.Styles.stack)

			p {
				"Connect using: Sportster 14,400 Fax"
			}
			.style(GeoCitiesPage.Styles.caption)

			button(.type(.submit)) {
				"Dial"
			}
			.style(GeoCitiesPage.Styles.retroButton)
		}
		.style(GeoCitiesWindows.Styles.stack, Styles.setup, GeoCitiesPage.Styles.scriptingOnly)

		div(.part(Parts.monitor)) {
			div(.part(Parts.screen), .role("log"), .tabindex(0)) {}
				.accessibilityLabel("The screen of the terminal")
				.style(Styles.screen)

			span {
				"_"
			}
			.accessibilityHidden()
			.style(GeoCitiesPage.Styles.blinkingCursor, Styles.cursor)
		}
		.style(Styles.monitor, GeoCitiesPage.Styles.scriptingOnly)

		form(.part(Parts.form)) {
			label(.for("geocities-term-input")) {
				"Type to the BBS"
			}
			.style(VisuallyHidden.Styles.root)

			input(.id("geocities-term-input"), .part(Parts.input), .type(.text), .autocomplete("off"), .maxlength(60), .disabled, .custom(name: "autocapitalize", value: "off"), .custom(name: "autocorrect", value: "off"), .custom(name: "spellcheck", value: "false"))
				.style(Styles.input)

			button(.type(.submit)) {
				"Send"
			}
			.style(GeoCitiesPage.Styles.smallButton)
		}
		.style(GeoCitiesWindows.Styles.nowrapRow, GeoCitiesPage.Styles.scriptingOnly)

		div(.part(Parts.keys), .role("group")) {}
			.accessibilityLabel("Keys")
			.style(GeoCitiesWindows.Styles.wrapRow, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.statusBar)) {
			"Disconnected | Auto detect | 14400 8-N-1"
		}
		.style(GeoCitiesPage.Styles.statusBar, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"HyperTerminal needs JavaScript. And a phone line that nobody else uses."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)

		template(.part(Parts.textTemplate)) {
			span {}
				.style(Styles.text)
		}

		template(.part(Parts.artTemplate)) {
			canvas {}
				.accessibilityHidden()
				.style(Styles.art)
		}

		template(.part(Parts.keyTemplate)) {
			button(.type(.button)) {}
				.style(GeoCitiesPage.Styles.smallButton, Styles.key)
		}
	}

	enum Parts: String, ElementPartSet {
		case call
		case hangUp
		case sound
		case setup
		case name
		case number
		case monitor
		case screen
		case form
		case input
		case keys
		case statusBar
		case textTemplate
		case artTemplate
		case keyTemplate
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The color of a piece of text on the screen, as a number of the 16 colors of ANSI, like `14` for yellow.
		*/
		case color = "data-term-color"
	}

	enum Styles: ElementStyleSet {
		case root
		case setup
		case icons
		case legend
		case iconChoice
		case iconPicture
		case monitor
		case screen
		case text
		case art
		case cursor
		case input
		case key

		/**
		The 16 colors of a VGA screen in text mode, which ANSI art used, by their numbers.
		*/
		private static let palette = ["#000000", "#0000aa", "#00aa00", "#00aaaa", "#aa0000", "#aa00aa", "#aa5500", "#aaaaaa", "#555555", "#5555ff", "#55ff55", "#55ffff", "#ff5555", "#ff55ff", "#ffff55", "#ffffff"]

		/**
		A color for each number of the palette, which the script sets on each piece of text.
		*/
		private static var colors: Style {
			var style = Style()

			for (number, color) in palette.enumerated() {
				style = style.when(Hooks.color, is: "\(number)") {
					$0.color(Color(color))
				}
			}

			return style
		}

		var style: Style {
			switch self {
			case .root:
				GeoCitiesWindows.Styles.stack.style
			case .setup:
				// The dialog of a new connection, gray and raised, like a dialog of Windows over the empty terminal.
				Style()
					.padding(.rootEm(0.5))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
			case .icons:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
					.padding(.rootEm(0.25))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .iconChoice:
				Style()
					.hstack(alignment: .center, spacing: 0)
					.handCursor()
			case .legend:
				Style().padding(horizontal: .rootEm(0.25))
			case .iconPicture:
				Style().font(.large)
			case .monitor:
				// The black screen of the terminal, with the cursor after the last text. The lines touch, so the frames of the menus join, like on a screen in text mode.
				Style()
					.frame(minHeight: .rootEm(14), maxHeight: .rootEm(20))
					.overflow(.auto)
					.padding(.rootEm(0.5))
					.background(.black)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .rootEm(0.8125), lineHeight: 1)
					.fontWeight(.bold)
					.color(Color("#aaaaaa"))
			case .screen:
				// The script turns the spaces that line up the art into no-break spaces, and the single spaces between words still wrap.
				Style()
					.display(.inline)
					.preservesLineBreaks()
					.overflowWrap(.anywhere)
					.focusVisible {
						$0.focusRing(Color("#55ffff"), width: .pixels(1), offset: .pixels(2), style: .dotted)
					}
			case .text:
				Self.colors
			case .art:
				// The ANSI art, in big square pixels of the 16 colors, which the script sizes to the columns of the text.
				Style()
					.display(.block)
					.imageRendering(.pixelated)
			case .cursor:
				Style().color(Color("#aaaaaa"))
			case .input:
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.25))
					.background(.black)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.color(Color("#55ff55"))
			case .key:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
			}
		}
	}
}
