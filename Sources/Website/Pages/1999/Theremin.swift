import Elementary
import SiteKit

/**
The theremin of the DJ booth, the instrument of the flying saucers of old films, which plays while the visitor holds the pointer or a finger on it: left and right is the pitch, and up is louder. It has Auto-Tune, the effect that Cher made famous with “Believe” in 1998, which snaps the pitch to the nearest note. Its script plays it through the sound card of the Music Room.
*/
struct GeoCitiesTheremin: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	var content: some HTML {
		h2 {
			"Theremin"
		}
		.style(GeoCitiesDJBooth.Styles.title)

		div {
			GeoCitiesPage.GIFImage(gif: .ufo, alt: "", style: .gif, project: project)
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div(.part(Parts.pad), .tabindex(0), .role("application")) {
			span(.part(Parts.hand)) {}
				.accessibilityHidden()
				.style(Styles.hand)

			span {
				"Hold here and move ← low · high →"
			}
			.accessibilityHidden()
			.style(Styles.padText)
		}
		.accessibilityLabel("The theremin. Hold the pointer or a finger on it and move. With the keyboard, Space plays, and the arrow keys change the pitch and the volume.")
		.style(Styles.pad)

		p(.part(Parts.readout)) {
			"-- Hz"
		}
		.accessibilityHidden()
		.style(GeoCitiesPage.Styles.lcd)

		div {
			label {
				input(.part(Parts.autoTune), .type(.checkbox))
				" Auto-Tune (like Cher!)"
			}
			.style(Styles.option)

			label {
				input(.part(Parts.vibrato), .type(.checkbox), .checked)
				" Spooky wobble"
			}
			.style(Styles.option)
		}
		.style(GeoCitiesPage.Styles.formRow)

		GeoCitiesMusicVolume()

		p(.part(Parts.status), .role("status")) {
			"Hold the box above and move around. Beware of flying saucers."
		}
		.style(GeoCitiesPage.Styles.caption)
	}

	enum Parts: String, ElementPartSet {
		case pad
		case hand
		case readout
		case autoTune
		case vibrato
		case status
	}

	enum Styles: ElementStyleSet {
		case root
		case pad
		case hand
		case padText
		case option

		var style: Style {
			switch self {
			case .root:
				// A section before, so it is a block.
				GeoCitiesDJBooth.Styles.booth.style.display(.block)
			case .pad:
				// A dark night sky with a glow where the hand is.
				Style()
					.position(.relative)
					.hstack(alignment: .end, justification: .center)
					.frame(height: .rootEm(10))
					.padding(.rootEm(0.5))
					.backgroundImage(.linearGradient("to bottom", Color("#0a0030"), Color("#3a0060")))
					.border(Color("#39ff14"), width: .pixels(2), style: .dashed)
					.overflow(.hidden)
					.cursor(.crosshair)
					.touchAction(.none)
					.focusVisible {
						$0.focusRing(Color("#39ff14"), width: .pixels(3), offset: .pixels(3))
					}
			case .hand:
				// A glowing dot where the pointer is, which the script moves, and which glows brighter while the theremin plays.
				Style()
					.position(.absolute)
					.top(.percent(50))
					.leading(.percent(50))
					.frame(width: .rootEm(1.5), height: .rootEm(1.5))
					.offset(x: .percent(-50), y: .percent(-50))
					.backgroundImage(.radialGradient("circle", Color("#ffffff"), Color("#39ff14"), Color("#39ff1400")))
					.cornerRadius(.percent(50))
					.opacity(0.4)
					.allowsHitTesting(false)
					.when(.state, is: "on") {
						$0
							.opacity(1)
							.scaleEffect(1.6)
					}
			case .padText:
				Style()
					.fontFamily(.system)
					.textStyle(.caption)
					.color(Color("#9999cc"))
					.allowsHitTesting(false)
			case .option:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			}
		}
	}
}
