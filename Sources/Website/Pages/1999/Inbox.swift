import Elementary
import SiteKit

/**
WaffleMail, a free web mail like Hotmail in 1999, with an inbox full of what everyone got then: chain letters, hoaxes, and spam. The visitor reads each one, and some have buttons: forward the e-mail of Bill Gates and see what he owes, claim the free Palm Pilot, warn everyone about the Good Times virus, or break the chain. The visitor can also write a chain letter of their own, which comes back to them after a while, like they always did. Its script, `Inbox.js`, runs it, and keeps the money of Bill Gates in the browser.
*/
struct GeoCitiesInbox: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of WaffleMail, which the site map links to.
	*/
	static let rootID = "geocities-wafflemail"

	let project: Project

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id(Self.rootID)]
	}

	var content: some HTML {
		h2 {
			GeoCitiesPage.GIFImage(gif: .mailbox, alt: "", style: .gif, project: project)
			" WaffleMail "
			GeoCitiesPage.GIFImage(gif: .emailSpin, alt: "", style: .gif, project: project)
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"I have free e-mail now! 2 MB of space, so I can keep almost 40 e-mails. Here is my inbox. My friends send me the most important things."
		}

		div {
			p(.part(Parts.title)) {
				"WaffleMail: Inbox"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				ul(.part(Parts.list)) {}
					.accessibilityLabel("Messages")
					.style(Styles.list)

				// The script adds a copy for each message.
				template(.part(Parts.rowTemplate)) {
					li {
						button(.type(.button)) {
							span {}
								.style(Styles.from)
							span {}
						}
						.style(Styles.row)
					}
				}

				// The script fills it with the message that the visitor opens, and focuses it.
				article(.part(Parts.reader), .tabindex(-1)) {
					div {
						p(.part(Parts.readerFrom)) {}
						p(.part(Parts.readerSubject)) {}
					}
					.style(Styles.readerHeader)

					div(.part(Parts.readerBody)) {
						"Pick a message to read it."
					}
					.style(Styles.body)

					div(.part(Parts.actions)) {}
						.style(GeoCitiesPage.Styles.row)
				}
				.accessibilityLabel("Message")
				.style(Styles.reader)

				// The script adds a copy for each button of a message.
				template(.part(Parts.actionTemplate)) {
					button(.type(.button)) {}
						.style(GeoCitiesPage.Styles.retroButton)
				}

				p(.part(Parts.status), .role("status")) {}
					.style(Styles.status)

				div {
					button(.part(Parts.compose), .type(.button)) {
						"✎ Write a Chain Letter"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(GeoCitiesPage.Styles.centeredText)

				form(.part(Parts.composer), .hidden) {
					h3 {
						"Write a Chain Letter"
					}

					for (part, title, options) in Self.chainParts {
						div {
							label(.for("geocities-chain-\(part.rawValue)")) {
								title
							}
							.style(GeoCitiesPage.Styles.label)

							select(.id("geocities-chain-\(part.rawValue)"), .part(part)) {
								for option in options {
									Elementary.option(.value(option)) {
										option
									}
								}
							}
							.style(GeoCitiesPage.Styles.field)
						}
					}

					div {
						button(.type(.submit)) {
							"Send to 10 Friends"
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
					.style(GeoCitiesPage.Styles.row)
				}
				.style(Styles.composer)
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"WaffleMail needs JavaScript. My e-mails are safe from you."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The parts of a chain letter that the visitor picks, with the part of their field.
	*/
	private static let chainParts: [(part: Parts, title: String, options: [String])] = [
		(.who, "Who says it is true:", ["Bill Gates", "NASA", "My cousin who works at AOL", "A real lawyer", "The Pope", "Glitter"]),
		(.luck, "Good luck if they forward it:", ["They will find $50", "Their crush will call them", "Their modem will connect on the first try", "They will get a pony", "They will win at Solitaire"]),
		(.curse, "Bad luck if they do not:", ["Their hard drive will be erased", "Their Tamagotchi will die", "They will step on a LEGO", "Their mom will pick up the phone", "Their waffles will burn"]),
		(.count, "Send it to:", ["10 people", "15 people", "Everyone you know", "Everyone you do not know"]),
	]

	enum Parts: String, ElementPartSet {
		case title
		case list
		case rowTemplate
		case reader
		case readerFrom
		case readerSubject
		case readerBody
		case actions
		case actionTemplate
		case status
		case compose
		case composer
		case who
		case luck
		case curse
		case count
	}

	enum Styles: ElementStyleSet {
		case root
		case list
		case row
		case from
		case reader
		case readerHeader
		case body
		case status
		case composer

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .list:
				// A white list of messages, which scrolls when the inbox is full.
				Style()
					.margin(0)
					.padding(0)
					.frame(maxHeight: .rootEm(14))
					.overflow(.auto)
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .row:
				// A message in the list, bold while it is unread, and blue while it is open.
				Style()
					.vstack(alignment: .start)
					.frame(width: .percent(100))
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.5))
					.border(.bottom, Color("#dddddd"))
					.background(.white)
					.fontFamily(.system)
					.textStyle(.caption)
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.when(.state, is: "unread") {
						$0.fontWeight(.bold)
					}
					.when(.state, is: "open") {
						$0
							.background(Color("#000080"))
							.color(.white)
					}
			case .from:
				// Gray, and light on the blue of an open message.
				Style()
					.color(Color("#555555"))
					.when(ancestorHas: .state, is: "open") {
						$0.color(Color("#ccccff"))
					}
			case .reader:
				// The open message, like a letter on white paper.
				Style()
					.flowSpacing(.rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(.system)
					.textStyle(.body)
					.overflowWrap(.breakWord)
			case .readerHeader:
				Style()
					.padding(.bottom, .rootEm(0.5))
					.border(.bottom, Color("#cccccc"))
					.textStyle(.caption)
			case .body:
				// The text of an e-mail of 1999, in a font like the plain text of Outlook Express, with its line breaks.
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
					.preservesLineBreaks()
			case .status:
				Style()
					.textStyle(.caption)
					.fontWeight(.bold)
					.color(Color("#800000"))
			case .composer:
				Style()
					.flowSpacing(.rootEm(0.5))
					.padding(.rootEm(0.75))
					.border(Color("#808080"), width: .pixels(2), style: .groove)
			}
		}
	}
}
