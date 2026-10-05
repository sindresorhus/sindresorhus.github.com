import Elementary
import Foundation
import SiteKit

/**
WAFFLE QUEST: The Great Underground Kitchen, a text adventure like Zork (1980), on a DOS screen with a status line and a blinking cursor. A parser understands verbs, nouns, and the abbreviations of the time, like N, I, X, and L, and TAKE ALL, SCORE, SAVE, and RESTORE. There is a lamp, a grue, a maze of twisty little passages, a troll, and a score of 100. Its script, `WaffleQuest.js`, runs it, keeps a saved game in the browser, and beeps when the sound button of my adventure game (``GeoCitiesAdventure``) is on.
*/
struct GeoCitiesWaffleQuest: ScriptedElement {
	static let script = ElementScript()

	/**
	The buttons below the screen for the commands that are typed most, for a phone, where typing is slow.
	*/
	static let quickCommands: [(command: String, label: String)] = [
		("n", "N"),
		("s", "S"),
		("e", "E"),
		("w", "W"),
		("u", "Up"),
		("d", "Down"),
		("look", "Look"),
		("inventory", "Inventory"),
	]

	var content: some HTML {
		h2 {
			"WAFFLE QUEST"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Before computers had pictures, games had words. Kevin’s big brother showed me Zork, so I made my own. Type what you want to do, like OPEN MAILBOX, TAKE LAMP, or GO NORTH, and press Enter. Type HELP if you are lost. You will be lost."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			p {
				span(.part(Parts.room)) {
					"West of Mormor’s House"
				}
				span(.part(Parts.score)) {
					"Score: 0/100   Moves: 0"
				}
			}
			.style(Styles.statusLine)

			div(.part(Parts.screen), .role("log")) {}
				.style(Styles.screen)

			form(.part(Parts.form)) {
				label(.for("geocities-waffle-quest-input")) {
					">"
				}
				.style(Styles.prompt)

				span {
					span(.part(Parts.typed)) {}
					span {
						"_"
					}
					.style(Styles.cursor, GeoCitiesPage.Styles.blinkingCursor)
					span(.part(Parts.after)) {}
				}
				.accessibilityHidden()
				.style(Styles.mirror)

				input(.id("geocities-waffle-quest-input"), .part(Parts.input), .type(.text), .autocomplete("off"), .maxlength(80), .custom(name: "spellcheck", value: "false"), .custom(name: "autocapitalize", value: "off"), .custom(name: "enterkeyhint", value: "send"))
					.accessibilityLabel("Command")
					.style(Styles.input)
			}
			.style(Styles.form)
		}
		.style(Styles.monitor, GeoCitiesPage.Styles.scriptingOnly)

		div {
			for quick in Self.quickCommands {
				button(.type(.button), .hook(Hooks.command, value: quick.command)) {
					quick.label
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.quickButton)
			}
		}
		.accessibilityLabel("Quick commands")
		.attributes(.role("group"))
		.style(GeoCitiesPage.Styles.buttonRow, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"WAFFLE QUEST needs JavaScript. It is pitch black. You are likely to be eaten by a grue."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case room
		case score
		case screen
		case form
		case input
		case typed
		case after
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The command of a quick button, like `n`.
		*/
		case command = "data-waffle-quest-command"
	}

	enum Styles: ElementStyleSet {
		case root
		case monitor
		case statusLine
		case screen
		case form
		case prompt
		case mirror
		case cursor
		case input
		case quickButton

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .monitor:
				// A DOS screen: gray letters on black, in the font of a PC of the time.
				Style()
					.position(.relative)
					.frame(maxWidth: .pixels(720))
					.margin(.horizontal, .auto)
					.background(.black)
					.border(Color("#555555"), width: .pixels(10), style: .ridge)
					.fontFamily(#""Perfect DOS VGA 437", "Lucida Console", "Courier New", monospace"#)
					.textStyle(.body)
					.lineHeight(1.35)
					.color(Color("#c0c0c0"))
					.focusWithin {
						$0.border(Color("#777777"), width: .pixels(10), style: .ridge)
					}
			case .statusLine:
				// The status line of the Infocom games: the room on the left and the score on the right, in reverse.
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(1))
					.flexWrap()
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Color("#c0c0c0"))
					.color(.black)
			case .screen:
				Style()
					.frame(height: .rootEm(20))
					.padding(top: .rootEm(0.5), horizontal: .rootEm(0.5))
					.overflow(.auto)
					.preservesLineBreaks()
					.overflowWrap(.breakWord)
					.scrollbarColor(thumb: Color("#808080"), track: .black)
			case .form:
				// The input is on top of a copy of what is typed, with a blinking cursor like DOS, so a click or a tap anywhere on the line types.
				Style()
					.position(.relative)
					.hstack(alignment: .center, spacing: .em(0.6))
					.padding(top: .rootEm(0.25), horizontal: .rootEm(0.5), bottom: .rootEm(0.5))
			case .prompt:
				Style()
					.color(Color("#ffffff"))
			case .mirror:
				Style()
					.flex(1)
					.preservesLineBreaks()
					.overflowWrap(.breakWord)
					.color(Color("#ffffff"))
			case .cursor:
				Style().color(Color("#ffffff"))
			case .input:
				Style()
					.position(.absolute)
					.inset(0)
					.frame(width: .percent(100))
					.opacity(0)
					.inheritsFont()
					// At least 16 pixels, so a phone does not zoom in on the screen when the field gets the focus.
					.font(size: .rootEm(1))
			case .quickButton:
				Style().frame(minWidth: .rootEm(2.75), minHeight: .rootEm(2.25))
			}
		}
	}
}
