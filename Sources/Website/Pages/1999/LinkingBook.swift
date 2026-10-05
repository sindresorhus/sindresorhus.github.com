import Elementary
import Foundation
import SiteKit

/**
My linking book, an extra of my adventure games: a book with a picture of the Brunost Age that moves like the flyby in the linking books of Myst (1993), and touching it links to the Age, a few still views to click through. The edges of a view turn, the middle walks on, and the things in it can be clicked. Three marker switches open the cheese tower, and a red page and a blue page wake up who is trapped in the two books of the library. Its script, `LinkingBook.js`, runs it, and makes the sounds of the Age when the sound button of my adventure game (``GeoCitiesAdventure``) is on.
*/
struct GeoCitiesLinkingBook: ScriptedElement {
	static let script = ElementScript()
	let project: Project

	var content: some HTML {
		h2 {
			GeoCitiesPage.GIFImage(gif: .bookCandle, alt: "", style: .gif, project: project)
			" My Linking Book "
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"In Myst, you travel to other worlds, called Ages, by touching the picture in a linking book. I wrote one to the Brunost Age, a small island that smells of brown cheese. Click the picture to link. Click the edges of the view to turn, and the middle to walk."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			div(.part(Parts.pages)) {
				div {
					p {
						"The Brunost Age"
					}
					.style(Styles.journalTitle)

					p {
						"I have written an Age of calm brown water and tall pines. On the hill stands a tower of cheese, and its door only opens for those who notice things. Somebody else is here too. I can hear them arguing in the library."
					}
					.style(Styles.journalText)
				}
				.style(Styles.journalPage)

				div {
					button(.part(Parts.panel), .type(.button)) {
						canvas(.part(Parts.panelCanvas), .width(160), .height(110)) {}
							.accessibilityHidden()
							.style(Styles.panelCanvas)
					}
					.accessibilityLabel("Link to the Brunost Age")
					.style(Styles.linkPanel)
				}
				.style(Styles.journalPage)
			}
			.style(Styles.openBook)

			div(.part(Parts.view), .hidden) {
				canvas(.part(Parts.canvas), .width(480), .height(300), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The view in the Brunost Age. Use the buttons below to look around.")
					.style(Styles.ageCanvas)

				p(.part(Parts.status), .role("status")) {}
					.style(Styles.ageStatus)

				div {
					for (direction, label) in [("left", "↶ Turn Left"), ("forward", "↑ Forward"), ("back", "↓ Back"), ("right", "Turn Right ↷")] {
						button(.type(.button), .hook(Hooks.move, value: direction)) {
							label
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.moveButton)
					}
				}
				.accessibilityLabel("Directions")
				.attributes(.role("group"))
				.style(GeoCitiesPage.Styles.buttonRow)

				div {
					for _ in 1...3 {
						button(.type(.button), .part(Parts.spot), .hidden) {}
							.style(GeoCitiesPage.Styles.smallButton, Styles.moveButton)
					}
				}
				.accessibilityLabel("Things here")
				.attributes(.role("group"))
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.style(Styles.ageView)

			div(.part(Parts.flash)) {}
				.style(Styles.flash)
		}
		.style(Styles.ageFrame, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My linking book needs JavaScript. Without it, it is just a book. A very nice book."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case pages
		case panel
		case panelCanvas
		case view
		case canvas
		case status
		case flash

		/**
		A thing to click in the view of the Brunost Age.
		*/
		case spot
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A direction to go in the Brunost Age, like `forward`.
		*/
		case move = "data-age-move"
	}

	enum Styles: ElementStyleSet {
		case root
		case ageFrame
		case openBook
		case journalPage
		case journalTitle
		case journalText
		case linkPanel
		case panelCanvas
		case ageView
		case ageCanvas
		case ageStatus
		case moveButton
		case flash

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .ageFrame:
				Style()
					.position(.relative)
					.frame(maxWidth: .pixels(640))
					.margin(.horizontal, .auto)
			case .openBook:
				// An open leather book: the journal on the left page and the linking panel on the right, or the panel below the journal on a phone.
				Style()
					.grid(columns: 1)
					.from(.smallTablet) {
						$0.gridColumns(2)
					}
					.gap(.rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#5a2a14"))
					.border(Color("#3a1a0a"), width: .pixels(4), style: .ridge)
					.cornerRadius(.rootEm(0.375))
					.shadow(Shadow(x: .pixels(4), y: .pixels(6), color: Color("#00000077")))
			case .journalPage:
				Style()
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#efe2c0"))
					.fontFamily(GeoCitiesPage.times)
					.color(Color("#3a2a1a"))
			case .journalTitle:
				Style()
					.margin(0)
					.font(.large, weight: .bold)
					.italic()
			case .journalText:
				Style()
					.margin(0)
					.textStyle(.caption)
					.italic()
			case .linkPanel:
				// The picture of the Age in the book, which links when it is touched.
				Style()
					.display(.block)
					.frame(width: .percent(100))
					.padding(0)
					.border(Color("#2a1a0a"), width: .pixels(3), style: .solid)
					.background(.black)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(3), offset: .pixels(2))
					}
			case .panelCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(160.0 / 110.0)
			case .ageView:
				Style().vstack(spacing: .rootEm(0.5))
			case .ageCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(480.0 / 300.0)
					.background(.black)
					.border(Color("#2a1a0a"), width: .pixels(4), style: .ridge)
					.touchAction(.manipulation)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(2))
					}
			case .ageStatus:
				Style()
					.frame(minHeight: .lineHeight(3))
					.margin(0)
					.padding(.rootEm(0.5))
					.background(Color("#1a1410"))
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.body)
					.italic()
					.color(Color("#efe2c0"))
			case .moveButton:
				Style().frame(minHeight: .rootEm(2.25))
			case .flash:
				// The white light of a link, which fades in and out over the book.
				Style()
					.position(.absolute)
					.inset(0)
					.background(.white)
					.opacity(0)
					.allowsHitTesting(false)
					.media(.allowsMotion) {
						$0.transition(.opacity, animation: .easeInOut(duration: .milliseconds(600)))
					}
					.when(.state, is: "on") {
						$0.opacity(1)
					}
			}
		}
	}
}
