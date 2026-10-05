import Elementary
import SiteKit

/**
The DJ booth, with two instruments side by side. A turntable with a breakbeat on a record that the visitor scratches by dragging it (or with the arrow keys), an air horn, and a rewind, like the DJs of jungle and garage in 1999 did when the crowd wanted the tune again. And a theremin, the instrument of the flying saucers of old films, which plays while the visitor holds the pointer or a finger on it: left and right is the pitch, and up is louder. It has Auto-Tune, the effect that Cher made famous with “Believe” in 1998, which snaps the pitch to the nearest note. Each instrument is a custom element with its own script, which plays through the sound card of the Music Room. The record only spins by itself for visitors who do not prefer reduced motion.
*/
struct GeoCitiesDJBooth: HTML {
	let project: Project

	var body: some HTML {
		div {
			Turntable(project: project)
			GeoCitiesTheremin(project: project)
		}
		.style(GeoCitiesPage.Styles.columns, GeoCitiesPage.Styles.scriptingOnly)
	}

	/**
	The turntable of the DJ booth, with a breakbeat on a record that the visitor scratches by dragging it (or with the arrow keys), an air horn, and a rewind. Its script makes the sounds, and the record only spins by itself for visitors who do not prefer reduced motion.
	*/
	struct Turntable: ScriptedElement {
		static let script = ElementScript()

		let project: Project

		var content: some HTML {
			h2 {
				GeoCitiesPage.GIFImage(gif: .turntableScratch, alt: "", style: .gif, project: project)
				" DJ Sindre"
			}
			.style(GeoCitiesDJBooth.Styles.title)

			div {
				GeoCitiesPage.GIFImage(gif: .alienDJ, alt: "An alien DJ", style: .gif, project: project)
			}
			.style(GeoCitiesPage.Styles.centeredText)

			div {
				div(.part(Parts.record), .tabindex(0), .role("application")) {
					div {
						"SINDRE RECORDS ★ WAFFLE BREAKS VOL. 1"
					}
					.style(Styles.label)
				}
				.accessibilityLabel("The record. Drag it back and forth to scratch, or use the left and right arrow keys.")
				.style(Styles.record)
			}
			.style(Styles.deck)

			div {
				button(.part(Parts.play), .type(.button), .ariaPressed(false)) {
					"▶ Play the beat"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.airHorn), .type(.button)) {
					"📯 Air horn"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.rewind), .type(.button)) {
					"⏪ Rewind!"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.formRow)

			GeoCitiesMusicVolume()

			p(.part(Parts.status), .role("status")) {
				"Drag the record to scratch. Wikka wikka!"
			}
			.style(GeoCitiesPage.Styles.caption)
		}

		enum Parts: String, ElementPartSet {
			case record
			case play
			case airHorn
			case rewind
			case status
		}

		enum Styles: ElementStyleSet {
			case root
			case deck
			case record
			case label

			var style: Style {
				switch self {
				case .root:
					// A section before, so it is a block.
					GeoCitiesDJBooth.Styles.booth.style.display(.block)
				case .deck:
					// The silver deck of a Technics turntable.
					Style()
						.hstack(alignment: .center, justification: .center)
						.padding(.rootEm(0.75))
						.backgroundImage(.linearGradient("to bottom right", Color("#d8d8d8"), Color("#9a9a9a")))
						.border(Color("#555"), width: .pixels(2))
						.cornerRadius(.rootEm(0.5))
				case .record:
					// A black record with grooves. The script turns it.
					Style()
						.hstack(alignment: .center, justification: .center)
						.frame(width: .rootEm(12), height: .rootEm(12))
						.backgroundImage(.radialGradient("circle", Color("#cc0000"), Color("#111111"), Color("#2a2a2a"), Color("#111111"), Color("#2a2a2a"), Color("#111111"), Color("#2a2a2a"), Color("#111111")))
						.border(Color("#000"), width: .pixels(3))
						.cornerRadius(.percent(50))
						.shadow(Shadow(y: .pixels(3), blur: .pixels(6), color: Color("#00000099")))
						.handCursor()
						.touchAction(.none)
						.focusVisible {
							$0.focusRing(Color("#39ff14"), width: .pixels(3), offset: .pixels(3))
						}
				case .label:
					// The red label in the middle, with the text of the record.
					Style()
						.hstack(alignment: .center, justification: .center)
						.frame(width: .rootEm(4.5), height: .rootEm(4.5))
						.padding(.rootEm(0.5))
						.background(Color("#cc0000"))
						.cornerRadius(.percent(50))
						.fontFamily(.system)
						.font(size: .rootEm(0.4375))
						.fontWeight(.bold)
						.textAlign(.center)
						.color(.white)
						.lineHeight(1.1)
						.allowsHitTesting(false)
				}
			}
		}
	}

	/**
	The styles of both instruments of the booth.
	*/
	enum Styles: StyleSet {
		case booth
		case title

		var style: Style {
			switch self {
			case .booth:
				// Black, with neon green, like a booth in a club.
				Style()
					.flowSpacing(.rootEm(0.75))
					.padding(.rootEm(0.75))
					.background(Color("#111111"))
					.border(Color("#39ff14"), width: .pixels(3))
					.color(.white)
					.children("label, p") {
						$0.color(.white)
					}
			case .title:
				Style()
					.textAlign(.center)
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge2)
					.color(Color("#39ff14"))
					.textShadow(Shadow(y: 0, blur: .pixels(8), color: Color("#39ff14")))
			}
		}
	}
}
