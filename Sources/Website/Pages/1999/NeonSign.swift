import Elementary
import Foundation
import SiteKit

/**
A neon sign on a brick wall, like in front of a diner: “Sindre’s Home Page”, in pink and blue tubes. Now and then a letter flickers, like an old tube, and the visitor can kick the sign, which fixes it, breaks it more, or knocks a letter off. Its script, `NeonSign.js`, flickers the letters only while the sign is in view, and not for visitors who prefer reduced motion. A kick still does what it does, without the sputter.
*/
struct GeoCitiesNeonSign: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	The lines of the sign, each in the color of its tube.
	*/
	private static let lines: [(text: String, style: Styles)] = [
		("Sindre’s", .pinkTube),
		("HOME PAGE", .blueTube),
	]

	var content: some HTML {
		GeoCitiesPage.GIFImage(gif: .skullSmoking, alt: "A cool skull with sunglasses, hanging out by the sign", style: .gif, project: project)

		p(.part(Parts.sign)) {
			VisuallyHidden("A neon sign: Sindre’s Home Page")

			for line in Self.lines {
				span {
					// A space is a letter box too, so it does not collapse between the boxes.
					for character in line.text {
						span {
							character == " " ? "\u{00A0}" : String(character)
						}
					}
				}
				.accessibilityHidden()
				.style(Styles.line, line.style)
			}
		}
		.style(Styles.sign)

		GeoCitiesPage.GIFImage(gif: .neonOpen, alt: "Open 24 hours", style: .gif, project: project)

		button(.part(Parts.kick), .type(.button)) {
			"Kick the sign"
		}
		.style(GeoCitiesPage.Styles.retroButton, GeoCitiesPage.Styles.scriptingOnly)

		p(.part(Parts.status), .role("status")) {}
			.style(Styles.status)
	}

	enum Parts: String, ElementPartSet {
		case sign
		case kick
		case status
	}

	enum Styles: ElementStyleSet {
		case root
		case sign
		case line
		case pinkTube
		case blueTube
		case status

		var style: Style {
			switch self {
			case .root:
				// A dark wall at night, lit by the sign in the middle.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.rootEm(1))
					.backgroundImage(.radialGradient("ellipse at 50% 35%", Color("#5a2a3a"), Color("#2a1418"), Color("#140a0c")))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.textAlign(.center)
					.color(.white)
			case .sign:
				// Tilted when a kick knocks it crooked.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.padding(vertical: .rootEm(0.75), horizontal: .rootEm(1.25))
					.border(Color("#552222"), width: .pixels(3))
					.cornerRadius(.rootEm(0.75))
					.background(Color("#1a0a0a"))
					.media(.allowsMotion) {
						$0.transition(.rotationEffect, animation: .timingCurve(0.3, 1.6, 0.5, 1, duration: .milliseconds(600)))
					}
					.when(.state, is: "crooked") {
						$0.rotationEffect(.degrees(-9))
					}
			case .line:
				// Each letter is a tube of its own, which is dark while it flickers off, and falls when a kick knocks it off.
				Style()
					.display(.block)
					.lineHeight(1.1)
					.children("span") {
						$0
							.display(.inlineBlock)
							.media(.allowsMotion) {
								$0.transition(.offset, .rotationEffect, animation: .easeIn(duration: .milliseconds(500)))
							}
							.when(.state, is: "off") {
								$0
									.color(Color("#4a2a3a"))
									.textShadow()
							}
							.when(.state, is: "fallen") {
								$0
									.color(Color("#4a2a3a"))
									.textShadow()
									.offset(y: .em(1.2))
									.rotationEffect(.degrees(70))
							}
					}
			case .pinkTube:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.fluidFontSize(fromRem: 2, toRem: 3, between: .phone, and: .tablet)
					.italic()
					.color(Color("#ffe6f6"))
					.textShadow(Shadow(y: 0, blur: .pixels(4), color: Color("#ff4fc4")), Shadow(y: 0, blur: .pixels(12), color: Color("#ff1aa8")), Shadow(y: 0, blur: .pixels(24), color: Color("#ff1aa8")))
			case .blueTube:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.fluidFontSize(fromRem: 1.5, toRem: 2.25, between: .phone, and: .tablet)
					.letterSpacing(.em(0.12))
					.color(Color("#e6fbff"))
					.textShadow(Shadow(y: 0, blur: .pixels(4), color: Color("#33ccff")), Shadow(y: 0, blur: .pixels(12), color: Color("#0099ff")), Shadow(y: 0, blur: .pixels(24), color: Color("#0066ff")))
			case .status:
				Style()
					.frame(minHeight: .lineHeight(1))
					.fontFamily(GeoCitiesPage.comicSans)
			}
		}
	}
}
