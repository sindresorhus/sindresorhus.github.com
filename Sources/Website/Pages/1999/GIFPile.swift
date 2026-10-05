import Elementary
import Foundation
import SiteKit

/**
The GIF-O-Matic: a button that adds more GIFs, because a home page can never have enough. Each press drops a random GIF of the page onto a pile, which grows from the bottom up, and says how much bigger the page is and how much longer it takes to load over a modem. At 50 GIFs a siren warns that it is too many, and at 100 the page wins Solitaire. An earthquake shakes the page and scatters the pile. Its script, `GIFPile.js`, takes the GIFs from the page, so the pile has every GIF there is, and the still frames for visitors who prefer reduced motion, who get no earthquake.
*/
struct GeoCitiesGIFPile: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	var content: some HTML {
		h2 {
			"GIF-O-Matic 2000"
		}
		.style(GeoCitiesPage.Styles.titleBar)

		div {
			div {
				GeoCitiesPage.GIFImage(gif: .copyingFiles, alt: "A window of Windows that copies a GIF", style: .gif, project: project)
			}
			.style(Styles.dialog)

			p {
				"Is my page not loud enough for you? Press the button for "
				strong {
					"more GIFs"
				}
				.style(GeoCitiesPage.Styles.rainbowText)
				"!!! Every GIF makes my page better. That is just science."
			}

			div {
				button(.part(Parts.more), .type(.button)) {
					"MORE GIFs!!!"
				}
				.style(GeoCitiesPage.Styles.retroButton, Styles.moreButton)

				button(.part(Parts.moreTen), .type(.button)) {
					"×10"
				}
				.accessibilityLabel("Ten more GIFs")
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.earthquake), .type(.button)) {
					GeoCitiesPage.GIFImage(gif: .siren, alt: "", style: .gif, project: project)
					" Earthquake!"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.clean), .type(.button)) {
					"Clean up"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow, GeoCitiesPage.Styles.scriptingOnly)

			div {
				div(.part(Parts.pile)) {}
					.style(Styles.pile)

				// It shows when the pile has too many GIFs. It is outside the pile, so it stays at the top of the box while the pile shows its top.
				div(.part(Parts.warning), .hidden) {
					GeoCitiesPage.GIFImage(gif: .siren, alt: "", style: .gif, project: project)
					span {
						"WARNING: TOO MANY GIFs"
					}
					GeoCitiesPage.GIFImage(gif: .siren, alt: "", style: .gif, project: project)
				}
				.style(Styles.warning)
			}
			.accessibilityHidden()
			.style(Styles.pileFrame, GeoCitiesPage.Styles.scriptingOnly)

			p(.part(Parts.status), .role("status")) {
				"The pile is empty. That is sad."
			}
			.style(GeoCitiesPage.Styles.centeredText, GeoCitiesPage.Styles.scriptingOnly)

			GeoCitiesPage.GIFImage(gif: .dividerHelix, alt: "", style: .centered, project: project)

			p {
				"The GIF-O-Matic needs JavaScript, so you have to make do with the 200 GIFs that are already here."
			}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
		}
		.style(GeoCitiesPage.Styles.windowBody)

		// The script adds a copy for each GIF of the pile, with the still frame of the GIF for visitors who prefer reduced motion, like ``GeoCitiesPage/GIFImage``.
		template(.part(Parts.template)) {
			picture {
				source(.media(.reducedMotion))

				img(.alt(""))
					.style(Styles.pileGIF)
			}
			.style(GeoCitiesPage.Styles.picture)
		}
	}

	enum Parts: String, ElementPartSet {
		case more
		case moreTen
		case earthquake
		case clean
		case pile
		case warning
		case status
		case template
	}

	enum Styles: ElementStyleSet {
		case root
		case dialog
		case moreButton
		case pileFrame
		case pile
		case pileGIF
		case warning

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.window.style.display(.block)
			case .dialog:
				// The window that copies GIFs, smaller than its picture.
				Style()
					.textAlign(.center)
					.lineHeight(0)
					.children("picture > img") {
						$0.frame(width: .percent(100), height: .auto, maxWidth: .rootEm(16))
					}
			case .moreButton:
				Style()
					.color(Color("#cc0000"))
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: Color("#ffff00")))
			case .pileFrame:
				// The warning is over the pile.
				Style().position(.relative)
			case .pile:
				// The GIFs pile up from the bottom, row on row. When the pile is higher than the box, the script scrolls it to its top, where the newest GIFs land, and the bottom rows go out of the box.
				Style()
					.hstack(alignment: .end, justification: .center, spacing: .pixels(2))
					.flexWrap(isReversed: true)
					.alignContent(.start)
					.frame(height: .rootEm(14))
					.overflow(.hidden)
					.padding(.rootEm(0.25))
					.backgroundImage(.linearGradient("to bottom", Color("#000033"), Color("#330066")))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
			case .pileGIF:
				// Each GIF lands on the pile from above, a little tilted. The script tilts it. Lynx shows no images.
				Style()
					.display(.block)
					.when(ancestorHas: GeoCitiesBestViewed.Hooks.view, is: "lynx") {
						$0.hidden()
					}
					.frame(width: .auto, height: .auto, maxWidth: .rootEm(6), maxHeight: .rootEm(3))
					.media(.allowsMotion) {
						$0.animation(Animations.drop, .easeIn(duration: .milliseconds(450)))
					}
			case .warning:
				// Over the pile, at the top, blinking.
				Style()
					.position(.absolute)
					.top(.rootEm(0.25))
					.leading(0)
					.trailing(0)
					.zIndex(1)
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.fontFamily(GeoCitiesPage.impact)
					.color(Color("#ff3333"))
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: .black))
					.children("span") {
						$0
							.padding(.horizontal, .rootEm(0.25))
							.background(.black)
							.media(.allowsMotion) {
								$0.animation(GeoCitiesPage.Animations.blink, .timingCurve("steps(1, end)", duration: .seconds(1)).repeatForever(autoreverses: false))
							}
					}
					.children("picture img") {
						$0.frame(width: .rootEm(2), height: .auto)
					}
			}
		}
	}

	enum Animations: KeyframeSet {
		case drop

		var keyframes: [Keyframe] {
			switch self {
			case .drop:
				[.from(Style().offset(y: .rootEm(-14)))]
			}
		}
	}
}
