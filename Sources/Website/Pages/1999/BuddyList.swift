import Elementary
import SiteKit

/**
My buddy list, like the instant messenger of AOL in 1999, the program every kid had open after school: buddies sign on and off with the creak and slam of a door, send instant messages, and answer the ones of the visitor in their own way. The visitor can warn a buddy, which raises their warning level until they are kicked off, and buddies warn back. The visitor can also write an away message, which answers the buddies by itself. Its script, `BuddyList.js`, runs it while it is on screen, and it only makes sounds after the visitor turns them on.
*/
struct GeoCitiesBuddyList: ScriptedElement {
	static let script = ElementScript()

	/**
	The away messages that the visitor can pick, from the classics of the time.
	*/
	private static let awayMessages = [
		"brb, my mom needs the phone",
		"~*~ eating waffles ~*~ leave a msg!!!",
		"at school. or sleeping. or both.",
		"If you are reading this, you are reading my away message. :-P",
		"♪ I’m blue da ba dee da ba daa ♪",
		"zzzZZZzzz",
	]

	/**
	The ID of the list of away messages, which the field of the away message suggests.
	*/
	private static let awayPresetsID = "geocities-buddies-away-presets"

	/**
	The ID of the field of the away message, for its label.
	*/
	private static let awayTextID = "geocities-buddies-away-text"

	var content: some HTML {
		h2 {
			"My Buddy List"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"All my friends are online after school. Click a buddy to send an instant message. Be nice, or they will warn you!"
		}

		div {
			div {
				p {
					"Buddy List"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					p {
						"Screen name: "
						strong {
							"SindreTheUnicorn"
						}
						br()
						span(.part(Parts.myWarning)) {
							"My warning level: 0%"
						}
					}
					.style(GeoCitiesPage.Styles.caption)

					label {
						input(.part(Parts.sound), .type(.checkbox))
						" Play sounds (doors and bloops)"
					}
					.style(Styles.option)

					ul(.part(Parts.list)) {}
						.accessibilityLabel("Buddies")
						.style(Styles.list)

					// The script adds a copy for each group of buddies, like “Family”.
					template(.part(Parts.groupTemplate)) {
						li {
							strong {}
								.style(Styles.group)
							ul {}
								.style(Styles.members)
						}
					}

					// The script adds a copy for each buddy.
					template(.part(Parts.buddyTemplate)) {
						li {
							button(.type(.button)) {
								span {}
									.accessibilityHidden()
									.style(Styles.icon)
								span {}
								span {}
									.style(Styles.note)
							}
							.style(Styles.buddy)
						}
					}

					button(.part(Parts.away), .type(.button), .ariaExpanded(false)) {
						"I’m Away"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					form(.part(Parts.awayForm), .hidden) {
						label(.for(Self.awayTextID)) {
							"My away message:"
						}
						.style(GeoCitiesPage.Styles.label)

						input(.id(Self.awayTextID), .part(Parts.awayText), .type(.text), .autocomplete("off"), .maxlength(80), .custom(name: "list", value: Self.awayPresetsID))
							.style(GeoCitiesPage.Styles.field)

						datalist(.id(Self.awayPresetsID)) {
							for message in Self.awayMessages {
								option(.value(message)) {}
							}
						}

						button(.type(.submit)) {
							"Set Away"
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
					.style(GeoCitiesPage.Styles.form)

					p(.part(Parts.status), .role("status")) {}
						.style(GeoCitiesPage.Styles.caption)
				}
				.style(GeoCitiesPage.Styles.windowBody)
			}
			.style(GeoCitiesPage.Styles.window)

			div {
				p(.part(Parts.chatTitle)) {
					"Instant Message"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					p(.part(Parts.buddyWarning)) {
						"Click a buddy to start a chat."
					}
					.style(GeoCitiesPage.Styles.caption)

					div(.part(Parts.log), .role("log")) {}
						.accessibilityLabel("Conversation")
						.style(Styles.log)

					// The script adds a copy for each message of the chat.
					template(.part(Parts.lineTemplate)) {
						p {
							strong {}
								.style(Styles.name)
							span {}
						}
						.style(Styles.line)
					}

					form(.part(Parts.form)) {
						input(.part(Parts.input), .type(.text), .autocomplete("off"), .maxlength(120), .disabled)
							.accessibilityLabel("Message")
							.style(GeoCitiesPage.Styles.field)

						div {
							button(.part(Parts.send), .type(.submit), .disabled) {
								"Send"
							}
							.style(GeoCitiesPage.Styles.retroButton)

							button(.part(Parts.warn), .type(.button), .disabled) {
								"⚠ Warn"
							}
							.style(GeoCitiesPage.Styles.retroButton)
						}
						.style(GeoCitiesPage.Styles.row)
					}
					.style(GeoCitiesPage.Styles.form)
				}
				.style(GeoCitiesPage.Styles.windowBody)
			}
			.style(GeoCitiesPage.Styles.window)
		}
		.style(GeoCitiesPage.Styles.columns, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My buddies only come online with JavaScript."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case myWarning
		case sound
		case list
		case groupTemplate
		case buddyTemplate
		case away
		case awayForm
		case awayText
		case status
		case chatTitle
		case buddyWarning
		case log
		case lineTemplate
		case form
		case input
		case send
		case warn
	}

	enum Styles: ElementStyleSet {
		case root
		case option
		case list
		case group
		case members
		case buddy
		case icon
		case note
		case log
		case line
		case name

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .option:
				Style()
					.display(.block)
					.fontFamily(.system)
					.textStyle(.caption)
			case .list:
				Style()
					.margin(0)
					.padding(.rootEm(0.25))
					.frame(minHeight: .rootEm(12))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .group:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .members:
				Style()
					.margin(0)
					.padding(.leading, .rootEm(0.5))
			case .buddy:
				// A buddy in the list: gray and italic while away or idle, and highlighted for a moment while signing on or off, like the open and closed doors of the real list. A buddy with a new message blinks.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.frame(width: .percent(100), minHeight: .rootEm(2))
					.padding(.horizontal, .rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption)
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.hover {
						$0.background(Color("#e0e0ff"))
					}
					.when(.state, is: "away") {
						$0
							.italic()
							.color(Color("#666666"))
					}
					.when(.state, is: "signing-on") {
						$0
							.background(Color("#ffff99"))
							.fontWeight(.bold)
					}
					.when(.state, is: "signing-off") {
						$0
							.background(Color("#dddddd"))
							.color(Color("#808080"))
					}
					.when(.state, is: "message") {
						$0
							.background(Color("#000080"))
							.color(.white)
							.fontWeight(.bold)
					}
					.disabled {
						$0
							.color(Color("#999999"))
							.cursor(GeoCitiesPage.arrowCursor, fallback: .default)
					}
			case .icon:
				Style()
					.frame(width: .rootEm(1.25))
					.flexShrink(0)
					.textAlign(.center)
			case .note:
				// Gray, and light on the blue of a buddy with a new message.
				Style()
					.margin(.leading, .auto)
					.color(Color("#808080"))
					.when(ancestorHas: .state, is: "message") {
						$0.color(Color("#ccccff"))
					}
			case .log:
				// The chat, which scrolls, with the newest message at the bottom.
				Style()
					.frame(height: .rootEm(14))
					.overflow(.auto)
					.padding(.rootEm(0.5))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.body)
					.overflowWrap(.breakWord)
			case .line:
				Style()
					.margin(.bottom, .rootEm(0.25))
					.when(.state, is: "auto") {
						$0.italic()
					}
					.when(.state, is: "system") {
						$0
							.color(Color("#808080"))
							.fontFamily(.system)
							.textStyle(.caption)
					}
			case .name:
				// The screen name before each message: red for the buddy and blue for the visitor, like in the real chat window.
				Style()
					.margin(.trailing, .rootEm(0.25))
					.color(Color("#cc0000"))
					.when(.state, is: "mine") {
						$0.color(Color("#0000cc"))
					}
			}
		}
	}
}
