import Elementary
import Foundation
import SiteKit

/**
A wall of the “Best viewed with…” buttons of 1999 that really change how the page looks: Lynx shows it as text, with the text of each image in brackets, the old monitor in green, 16-bit color with way too much color, 3DNow! in red and cyan for 3D glasses, the cool shades dark, like a dark mode 20 years early, and Auzzie upside down, for visitors in Australia. Eyes are back to normal. Its script, `BestViewed.js`, sets the view on the panel of the page, and the styles of the panel show it. The view is not kept, so the page is normal again when it opens.
*/
struct GeoCitiesBestViewed: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	The views, with the 88×31 button of each and what it says.
	*/
	private static let views: [(id: String, gif: GeoCitiesPage.GIF, text: String)] = [
		("eyes", .buttonBestViewedEyes, "Best viewed with eyes"),
		("lynx", .buttonLynx, "Lynx friendly"),
		("monitor", .buttonOldMonitor, "Old monitor approved"),
		("16-bit", .button16Bit, "Best viewed in 16-bit color"),
		("3d", .button3DNow, "Get 3DNow!"),
		("shades", .buttonCoolShades, "Cool shades"),
		("australia", .buttonAuzzie, "Auzzie"),
	]

	var content: some HTML {
		h2 {
			"This Page Is Best Viewed With…"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"…all of these! Press a button to see my page the way it was meant to be seen."
		}

		GeoCitiesPage.GIFImage(gif: .dividerArrows, alt: "", style: .centered, project: project)

		ul {
			for (index, view) in Self.views.enumerated() {
				li {
					button(.type(.button), .hook(Hooks.button, value: view.id), .ariaPressed(index == 0)) {
						GeoCitiesPage.GIFImage(gif: view.gif, alt: view.text, style: .gif, project: project)
					}
					.style(Styles.button)
				}
			}
		}
		.style(Styles.buttons, GeoCitiesPage.Styles.scriptingOnly)

		p {
			GeoCitiesPage.GIFImage(gif: .constructionLightning, alt: "", style: .gif, project: project)
			" More views coming soon: Mosaic, WebTV, and a fridge. "
			GeoCitiesPage.GIFImage(gif: .constructionLightning, alt: "", style: .gif, project: project)
		}
		.style(GeoCitiesPage.Styles.caption)

		p {
			"The buttons need JavaScript, so this page is best viewed with JavaScript."
		}
		.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)

		// The script puts a copy after each image of the page in the view of Lynx, with the text of the image, like Lynx did. Screen readers read it instead of the image, which is hidden then.
		template(.part(Parts.lynxTemplate)) {
			span {}
				.style(Styles.lynxImage)
		}
	}

	enum Parts: String, ElementPartSet {
		case lynxTemplate
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The view of a button: `eyes`, `lynx`, `monitor`, `16-bit`, `3d`, `shades`, or `australia`.
		*/
		case button = "data-best-viewed"

		/**
		The view on the panel of the page, like `lynx`. Normal without it.
		*/
		case view = "data-best-viewed-view"
	}

	enum Styles: ElementStyleSet {
		case root
		case buttons
		case button
		case lynxImage

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style.combined(with: GeoCitiesPage.Styles.centeredText.style)
			case .buttons:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
					.padding(.leading, 0)
			case .button:
				// Only the button image, which is pressed in while its view is on.
				Style()
					.display(.block)
					.padding(.pixels(2))
					.background(.transparent)
					.border(.transparent, width: .pixels(2), style: .solid)
					.lineHeight(0)
					.handCursor()
					.hover {
						$0.border(Color("#000080"), width: .pixels(2), style: .dotted)
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#ffff00"))
							.border(Color("#808080"), width: .pixels(2), style: .inset)
					}
			case .lynxImage:
				// The text of an image in brackets, like `[INLINE]` in Lynx.
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
			}
		}
	}
}
