import Elementary
import SiteKit

/**
NRK Tekst-TV, the teletext of the Norwegian TV in 1999, on a TV with a remote: blocky colored text pages, which the visitor browses by page number, like 100 for the front page and 150 for the weather, or with the four colored buttons. Its script, `TekstTV.js`, draws the pages from its data, and searches for a page like a real decoder, which counts through the pages on the air until the one it waits for comes by. A button turns the pages into English. Without scripts, the TV is left out, as it has nothing to show.
*/
struct GeoCitiesTekstTV: ScriptedElement {
	static let script = ElementScript()

	/**
	The colored buttons of the remote, which jump to the main parts, like on a real remote.
	*/
	private static let fastext: [(page: Int, label: String, style: Styles)] = [
		(101, "News", .fastextRed),
		(200, "Sport", .fastextGreen),
		(150, "Weather", .fastextYellow),
		(300, "TV", .fastextBlue),
	]

	var content: some HTML {
		h2 {
			"NRK Tekst-TV"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"The teletext of the Norwegian TV. My dad reads the ski results here every morning, before the newspaper comes. Type a page number on the remote, like 150 for the weather, or try to find the secret page."
		}

		// In a block of its own, so it hides without scripts, as the TV and the remote set their own display.
		div {
			div {
				div {
					// The header line, with the page number that the TV searches through and the clock. It changes all the time, so screen readers hear the status below instead.
					p(.part(Parts.header)) {}
						.accessibilityHidden()
						.style(Styles.line)

					div(.part(Parts.page), .role("region")) {}
						.accessibilityLabel("Teletext page")
						.style(Styles.page)
				}
				.style(Styles.screen)

				p {
					"NRK"
				}
				.accessibilityHidden()
				.style(Styles.brand)
			}
			.style(Styles.television)

			p(.part(Parts.status), .role("status")) {}
				.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.centeredText)

			div {
				div {
					for digit in [1, 2, 3, 4, 5, 6, 7, 8, 9, 0] {
						button(.type(.button), .hook(Hooks.digit, value: "\(digit)")) {
							"\(digit)"
						}
						.style(Styles.key)
					}
				}
				.accessibilityLabel("Page number")
				.style(Styles.keypad)

				div {
					button(.type(.button), .hook(Hooks.step, value: "-1")) {
						"◀ Page"
					}
					.accessibilityLabel("Previous page")
					.style(Styles.key)

					button(.type(.button), .hook(Hooks.step, value: "1")) {
						"Page ▶"
					}
					.accessibilityLabel("Next page")
					.style(Styles.key)

					button(.part(Parts.translate), .type(.button), .ariaPressed(false)) {
						"Translate"
					}
					.style(Styles.key)
				}
				.style(Styles.keyRow)

				div {
					for button in Self.fastext {
						Elementary.button(.type(.button), .hook(Hooks.jump, value: "\(button.page)")) {
							button.label
						}
						.style(Styles.key, button.style)
					}
				}
				.accessibilityLabel("Colored buttons")
				.style(Styles.keyRow)
			}
			.accessibilityLabel("Remote control")
			.style(Styles.remote)
		}
		.style(Styles.player, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Tekst-TV needs JavaScript (and a TV)."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case header
		case page
		case status
		case translate
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A number key of the remote, with its digit.
		*/
		case digit = "data-tekst-tv-digit"

		/**
		A button that goes to the page before or after, with `-1` or `1`.
		*/
		case step = "data-tekst-tv-step"

		/**
		A colored button of the remote, with the page that it jumps to.
		*/
		case jump = "data-tekst-tv-jump"
	}

	enum Styles: ElementStyleSet {
		case root
		case player
		case television
		case screen
		case line
		case page
		case brand
		case remote
		case keypad
		case keyRow
		case key
		case fastextRed
		case fastextGreen
		case fastextYellow
		case fastextBlue

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .player:
				Style().flowSpacing(.rootEm(0.75))
			case .television:
				// A gray TV of the 1990s, with a thick frame around the black screen. Its font size sets the size of the screen, and so of the TV, which is as wide as the screen in it.
				Style()
					.vstack(alignment: .center, spacing: .em(0.25))
					.frame(width: .em(26.5) + .pixels(14), maxWidth: .percent(100))
					.margin(.horizontal, .auto)
					.padding(.em(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#5a5a5a"), Color("#2e2e2e")))
					.border(Color("#1a1a1a"), width: .pixels(3))
					.cornerRadius(.rootEm(1))
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000066")))
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .clamp(.pixels(8), .viewportWidth(2.5), .pixels(16)))
			case .screen:
				// 40 letters wide, like teletext. The letters touch from line to line, so the block graphics join.
				Style()
					.padding(.em(0.5))
					.background(.black)
					.border(Color("#111111"), width: .pixels(4), style: .inset)
					.cornerRadius(.rootEm(0.5))
					.fontWeight(.bold)
					.lineHeight(1.15)
					.color(.white)
			case .line:
				// Each line of teletext is 40 letters, which never wrap. The colored parts fill the whole height of the line, so the bands and the block graphics have no gaps between the lines.
				Style()
					.margin(0)
					.frame(width: .em(24))
					.textWrap(.nowrap)
					.overflow(.hidden)
					.children("span") {
						$0.display(.inlineBlock)
					}
			case .page:
				Style()
					.frame(width: .em(24), minHeight: .lineHeight(20))
					.textWrap(.nowrap)
					.overflow(.hidden)
					.children("div > span") {
						$0.display(.inlineBlock)
					}
			case .brand:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.letterSpacing(.em(0.3))
					.color(Color("#bbbbbb"))
			case .remote:
				// A black remote, held sideways.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(maxWidth: .rootEm(24))
					.margin(.horizontal, .auto)
					.padding(.rootEm(0.75))
					.background(Color("#222222"))
					.border(Color("#555555"), width: .pixels(2), style: .outset)
					.cornerRadius(.rootEm(1.5))
			case .keypad:
				Style()
					.grid(columns: 5)
					.gap(.rootEm(0.375))
					.frame(width: .percent(100))
			case .keyRow:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .key:
				// A rubber key, which goes down while it is pressed. Large enough for a finger.
				Style()
					.frame(minWidth: .rootEm(2.75), minHeight: .rootEm(2.75))
					.padding(.horizontal, .rootEm(0.5))
					.background(Color("#4a4a4a"))
					.border(Color("#111111"), width: .pixels(2))
					.cornerRadius(.rootEm(0.75))
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(.white)
					.handCursor()
					.active {
						$0.scaleEffect(0.94)
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#ffff00"))
							.color(.black)
					}
			case .fastextRed:
				Style()
					.background(Color("#cc0000"))
			case .fastextGreen:
				Style()
					.background(Color("#008800"))
			case .fastextYellow:
				Style()
					.background(Color("#bbaa00"))
					.color(.black)
			case .fastextBlue:
				Style()
					.background(Color("#0033cc"))
			}
		}
	}
}
