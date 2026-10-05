import Elementary
import Foundation
import SiteKit

/**
My music to go in 1999: a Discman with a CD I burned, which skips when the visitor shakes it, unless the electronic skip protection (ESP) has music in its buffer, and a Walkman with a mixtape I taped off the radio, whose tape comes out as tape salad, so the visitor winds it back in with a pencil, and whose batteries slow the tape down as they run out. The music is made in the browser, and only plays after the visitor puts on the headphones; until then, the headphones only leak a faint “tsk tsk”. Its script, `Music.js`, runs them. With reduced motion, the CD and the reels do not turn, and the Discman does not shake, but it still skips.
*/
struct GeoCitiesMusic: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the element, which the Discman and the Walkman on the desk in my room lead to.
	*/
	static let rootID = "geocities-discman"

	let project: Project

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id(Self.rootID), .tabindex(-1)]
	}

	var content: some HTML {
		h2 {
			GeoCitiesPage.GIFImage(gif: .compactDisc, alt: "", style: .gif, project: project)
			" My Discman and My Walkman"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Music to go! Do not run with the Discman. Do not ask what happened to the tape."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		p {
			button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
				"🎧 Headphones On (plays sound)"
			}
			.style(GeoCitiesPage.Styles.retroButton, Styles.toggle)
		}
		.style(GeoCitiesPage.Styles.centeredText, GeoCitiesPage.Styles.scriptingOnly)

		div {
			div {
				h3 {
					"Discman"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					canvas(.part(Parts.discmanCanvas), .width(240), .height(240), .tabindex(0), .role("application")) {}
						.accessibilityLabel("My Discman. Drag it around to shake it, or press the arrow keys to bump it.")
						.style(Styles.discman)

					div {
						for (action, label, symbol) in [("previous", "Previous track", "⏮"), ("play", "Play or pause", "⏯"), ("stop", "Stop", "⏹"), ("next", "Next track", "⏭")] {
							button(.type(.button), .hook(Hooks.discmanAction, value: action)) {
								symbol
							}
							.accessibilityLabel(label)
							.style(Styles.playerButton)
						}
					}
					.style(Styles.playerButtons)

					div {
						button(.type(.button), .hook(Hooks.discmanAction, value: "esp"), .ariaPressed(false)) {
							"ESP Anti-Skip"
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

						button(.type(.button), .hook(Hooks.discmanAction, value: "run"), .ariaPressed(false)) {
							"🏃 Go for a Run"
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
					}
					.style(GeoCitiesPage.Styles.buttonRow)

					p(.part(Parts.discmanStatus), .role("status")) {}
						.style(Styles.status)
				}
				.style(GeoCitiesPage.Styles.windowBody, Styles.player)
			}
			.style(GeoCitiesPage.Styles.window)

			div {
				h3 {
					"Walkman"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					canvas(.part(Parts.walkmanCanvas), .width(280), .height(200), .tabindex(0), .role("application")) {}
						.accessibilityLabel("My Walkman. With the pencil in, drag around the pencil in circles to wind the tape in, or press the arrow keys.")
						.style(Styles.walkman)

					div {
						for (action, label, symbol) in [("rewind", "Rewind", "⏪"), ("play", "Play", "▶"), ("stop", "Stop", "⏹")] {
							button(.type(.button), .hook(Hooks.walkmanAction, value: action)) {
								symbol
							}
							.accessibilityLabel(label)
							.style(Styles.playerButton)
						}
					}
					.style(Styles.playerButtons)

					div {
						button(.type(.button), .hook(Hooks.walkmanAction, value: "pencil"), .ariaPressed(false)) {
							"✏️ Stick a Pencil In"
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

						button(.type(.button), .hook(Hooks.walkmanAction, value: "batteries")) {
							"🔋 Take the Batteries from the TV Remote"
						}
						.style(GeoCitiesPage.Styles.smallButton)
					}
					.style(GeoCitiesPage.Styles.buttonRow)

					p(.part(Parts.walkmanStatus), .role("status")) {}
						.style(Styles.status)
				}
				.style(GeoCitiesPage.Styles.windowBody, Styles.player)
			}
			.style(GeoCitiesPage.Styles.window)
		}
		.style(GeoCitiesPage.Styles.columns, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My Discman and my Walkman need JavaScript, and the batteries are dead anyway."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case sound
		case discmanCanvas
		case discmanStatus
		case walkmanCanvas
		case walkmanStatus
	}

	enum Hooks: String, ScriptHookSet {
		/**
		What a button of the Discman does, like `play` or `esp`.
		*/
		case discmanAction = "data-discman-action"

		/**
		What a button of the Walkman does, like `pencil`.
		*/
		case walkmanAction = "data-walkman-action"
	}

	enum Styles: ElementStyleSet {
		case root
		case player
		case discman
		case walkman
		case playerButtons
		case playerButton
		case toggle
		case status

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .player:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.textAlign(.center)
			case .discman:
				// The Discman can be dragged around, so a finger shakes it instead of scrolling the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto, maxWidth: .rootEm(15))
					.aspectRatio(1)
					.touchAction(.none)
					.cursor(.move)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .walkman:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto, maxWidth: .rootEm(17.5))
					.aspectRatio(280.0 / 200.0)
					.touchAction(.none)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .playerButtons:
				Style().hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
			case .playerButton:
				// A silver button of a player of the 1990s.
				Style()
					.frame(minWidth: .rootEm(2.75), minHeight: .rootEm(2.25))
					.backgroundImage(.linearGradient("to bottom", Color("#f4f4f4"), Color("#b8b8c0")))
					.border(Color("#77777f"), width: .pixels(1))
					.cornerRadius(.rootEm(0.375))
					.textStyle(.body)
					.color(Color("#222222"))
					.handCursor()
					.active {
						$0.backgroundImage(.linearGradient("to bottom", Color("#b8b8c0"), Color("#e4e4e4")))
					}
			case .toggle:
				Style().when(.state, is: "on") {
					$0
						.background(Color("#99ff99"))
						.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
				}
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			}
		}
	}
}
