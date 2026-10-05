import Elementary
import SiteKit

/**
The Hampster Band: five hamsters, each with a part of the song (drums, bass, banjo, whistle, and “dee dee” vocals), that the visitor turns on and off, and a hamster dances only while its part plays. The record player has three speeds, and like the Hampster Dance of 1998, which was a country song sped up, the song only becomes the Hampster Dance at 78 RPM. Its script plays the parts together through the sound card of the Music Room, and swaps each GIF for its still frame while its part is off.
*/
struct GeoCitiesHamsterBand: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	The hamsters, by the part they play in the script, with their names and GIFs.
	*/
	static let members: [(part: String, name: String, instrument: String, gif: GeoCitiesPage.GIF)] = [
		("drums", "Hammy", "Drums", .hamsterDrummer),
		("bass", "Nibbles", "Bass", .hamsterBassist),
		("banjo", "Banjo Bob", "Banjo", .hamsterBanjo),
		("whistle", "Whiskers", "Whistle", .hamsterWhistler),
		("vocals", "Fluffy", "Dee dee!", .hamsterSinger),
	]

	/**
	The speeds of the record player.
	*/
	static let speeds: [(rpm: String, title: String)] = [
		("33", "33 RPM"),
		("45", "45 RPM"),
		("78", "78 RPM"),
	]

	var content: some HTML {
		h2 {
			"The Hampster Band"
		}
		.style(Styles.title)

		p {
			"Everybody knows the Hampster Dance. But did you know it is really a slow country song, played much too fast? Turn on the hamsters one by one, then turn up the speed."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			ul {
				for member in Self.members {
					li(.hook(Hooks.member, value: member.part)) {
						GeoCitiesPage.GIFImage(gif: member.gif, alt: "", style: .gif, project: project)

						button(.type(.button), .hook(Hooks.part, value: member.part), .ariaPressed(false)) {
							strong {
								member.name
							}
							span {
								member.instrument
							}
						}
						.style(Styles.toggle)
					}
					.style(Styles.member)
				}
			}
			.accessibilityLabel("The band")
			.style(Styles.stage)

			div {
				button(.part(Parts.everybody), .type(.button)) {
					"🐹 Everybody!"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.stop), .type(.button)) {
					"■ Stop"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				fieldset {
					legend {
						"Record speed"
					}
					.style(Styles.legend)

					for speed in Self.speeds {
						label {
							input(.type(.radio), .name("geocities-hamster-speed"), .value(speed.rpm), .hook(Hooks.speed))
								.attributes(.checked, when: speed.rpm == "33")
							" \(speed.title)"
						}
						.style(Styles.speed)
					}
				}
				.style(Styles.speeds)

				GeoCitiesMusicVolume()
			}
			.style(GeoCitiesPage.Styles.formRow, Styles.controls)

			p(.part(Parts.status), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.box, GeoCitiesPage.Styles.scriptingOnly)
	}

	enum Parts: String, ElementPartSet {
		case everybody
		case stop
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The button that turns a part on and off, by the part.
		*/
		case part = "data-hamster-part"

		/**
		A hamster of the band, by its part, which dances while its part plays.
		*/
		case member = "data-hamster-member"

		/**
		A radio button of a speed of the record player.
		*/
		case speed = "data-hamster-speed"
	}

	enum Styles: ElementStyleSet {
		case root
		case title
		case box
		case stage
		case member
		case toggle
		case controls
		case speeds
		case legend
		case speed
		case status

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .title:
				Style()
					.textAlign(.center)
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.extraLarge2, weight: .bold)
					.color(Color("#ff6600"))
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#ffff00")))
			case .box:
				// A stage with a red curtain at the top and a wooden floor.
				Style()
					.flowSpacing(.rootEm(0.75))
					.padding(.rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#aa1111"), Color("#aa1111"), Color("#ffe9b0"), Color("#d9a35f")))
					.border(Color("#661100"), width: .pixels(4), style: .ridge)
			case .stage:
				Style()
					.grid(minimumColumnWidth: .rootEm(6.5))
					.gap(.rootEm(0.5))
					.margin(0)
					.padding(0)
			case .member:
				// A hamster is gray and small while it does not play, and grows when it joins the band.
				Style()
					.vstack(alignment: .center, justification: .end, spacing: .rootEm(0.375))
					.padding(.rootEm(0.375))
					.background(Color("#fff8e1"))
					.border(Color("#d9a35f"), width: .pixels(2))
					.cornerRadius(.rootEm(0.5))
					.children("picture img") {
						$0
							.filter(.grayscale(1))
							.opacity(0.6)
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#ffff99"))
							.border(Color("#ff6600"), width: .pixels(2))
							.children("picture img") {
								$0
									.filter(.grayscale(0))
									.opacity(1)
							}
					}
			case .toggle:
				Style()
					.vstack(alignment: .center)
					.frame(width: .percent(100))
					.padding(.rootEm(0.25))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
					.handCursor()
					.when(.state, is: "on") {
						$0
							.background(Color("#ffcc00"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .controls:
				Style()
					.padding(.rootEm(0.5))
					.background(Color("#fff8e1"))
					.border(Color("#d9a35f"), width: .pixels(2))
			case .speeds:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.flexWrap()
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.border(Color("#d9a35f"), width: .pixels(1))
			case .legend:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .speed:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption)
			case .status:
				Style()
					.frame(minHeight: .lineHeight(1))
					.padding(.rootEm(0.25))
					.background(Color("#fff8e1"))
					.fontFamily(GeoCitiesPage.comicSans)
					.fontWeight(.bold)
					.textAlign(.center)
					.color(Color("#aa1111"))
			}
		}
	}
}
