import Elementary
import Foundation
import SiteKit

/**
A panel of big red arcade buttons, each with a label like on a control desk, that do something silly to the whole page: the Hampster Dance, waffles that rain down, every GIF spinning, the page in every color of the rainbow, a red wallpaper for Norway, and a sparkling Glitter. `geocities.js` runs them. Without scripts, the panel is hidden, as the buttons need them.
*/
struct GeoCitiesBigButtons: HTML {
	/**
	The buttons, by what they do in `geocities.js`, with their labels.
	*/
	private static let buttons: [(effect: String, title: String)] = [
		("hamster", "Hampster Dance"),
		("waffles", "Make It Rain Waffles"),
		("spin", "Spin All GIFs"),
		("rainbow", "Taste the Rainbow"),
		("norway", "Hipp Hipp Hurra!"),
		("glitter", "Sparkle Glitter"),
	]

	var body: some HTML {
		section(.id("geocities-big-buttons")) {
			h2 {
				"The Big Red Buttons"
			}
			.style(Styles.title)

			p {
				"Do NOT press them all at once. (Go on, press them all at once.)"
			}
			.style(GeoCitiesPage.Styles.caption)

			ul {
				for item in Self.buttons {
					li {
						button(.type(.button), .hook(Hooks.effect, value: item.effect)) {}
							.accessibilityLabel(item.title)
							.style(Styles.button)

						span {
							item.title
						}
						.accessibilityHidden()
						.style(Styles.label)
					}
					.style(Styles.item)
				}
			}
			.style(Styles.desk)
		}
		.style(Styles.panel, GeoCitiesPage.Styles.scriptingOnly)
	}

	enum Hooks: String, ScriptHookSet {
		/**
		What a big button does to the page, like `hamster`.
		*/
		case effect = "data-big-button"
	}

	enum Styles: StyleSet {
		case panel
		case title
		case desk
		case item
		case button
		case label

		var style: Style {
			switch self {
			case .panel:
				// A gray metal control desk with yellow and black hazard stripes, like a machine with buttons that should not be pressed.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.rootEm(1))
					.background(Color("#4a4a4a"))
					.border(Color("#ffcc00"), width: .pixels(6), style: .dashed)
					.color(.white)
					.textAlign(.center)
			case .title:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge2)
					.color(Color("#ff3333"))
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: .black))
			case .desk:
				// Two rows of three, also on phones, where three buttons fit side by side.
				Style()
					.grid(columns: 3)
					.gap(.rootEm(1))
					.frame(width: .percent(100))
			case .item:
				Style().vstack(alignment: .center, spacing: .rootEm(0.5))
			case .button:
				// A big round red arcade button that sinks in when pressed.
				Style()
					.frame(width: .rootEm(4.5), height: .rootEm(4.5))
					.backgroundImage(.radialGradient("circle at 35% 30%", Color("#ff8888"), Color("#dd0000"), Color("#880000")))
					.border(Color("#333333"), width: .pixels(5))
					.cornerRadius(.percent(50))
					.shadow(Shadow(y: .pixels(6), color: Color("#550000")))
					.handCursor()
					.transition(.offset, animation: .easeOut(duration: .milliseconds(80)))
					.active {
						$0
							.offset(y: .pixels(4))
							.shadow(Shadow(y: .pixels(2), color: Color("#550000")))
					}
					.reducedMotion {
						$0.noTransition()
					}
			case .label:
				// A label of tape under the button, like on a control desk.
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Color("#ffffcc"))
					.border(.black, width: .pixels(1))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(.black)
			}
		}
	}
}
