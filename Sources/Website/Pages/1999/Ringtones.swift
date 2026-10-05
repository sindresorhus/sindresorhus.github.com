import Elementary
import SiteKit

/**
The Composer of a Nokia 3210 (1999), with its real notation, like `8e2 8d2 4#f1`: the keys 1 to 7 are the notes C to B, 8 and 9 make the last note shorter and longer, 0 is a rest, * changes the octave, and # makes the note sharp. The visitor can also type the code. Next to it is an ad for ringtones from a magazine for teenagers, with tones that cost 15 kroner each on the phone bill, until Mamma notices. “Ring Me!” makes someone call with the tune, and “Save as MIDI” saves a real MIDI file. Its script plays the beeps through the sound card of the Music Room, and keeps the tune and the phone bill in the browser.
*/
struct GeoCitiesRingtones: ScriptedElement {
	static let script = ElementScript()

	/**
	The keys of the phone, with what each does, as the key that the script reads.
	*/
	static let keys: [(key: String, label: String)] = [
		("1", "C"), ("2", "D"), ("3", "E"),
		("4", "F"), ("5", "G"), ("6", "A"),
		("7", "B"), ("8", "short"), ("9", "long"),
		("*", "octave"), ("0", "rest"), ("#", "sharp"),
	]

	/**
	The ringtones of the ad, by their ID in the script, with their order codes.
	*/
	static let tones: [(id: String, title: String, code: String)] = [
		("nokia", "Nokia Tune", "4471"),
		("elise", "Für Elise", "4472"),
		("morning", "Morning Mood (Grieg, from Norway!)", "4473"),
		("mozart", "Eine kleine Nachtmusik", "4474"),
		("joy", "Ode to Joy", "4475"),
		("boogie", "Brunost Boogie", "4476"),
		("alarm", "Waffle Alarm", "4477"),
	]

	var content: some HTML {
		h2 {
			"Ringtone Composer"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"My dad got a Nokia 3210 for work, and I borrow it to compose ringtones. Press the keys of the phone, or type the code. Then press Ring Me! and someone calls with your tune."
		}

		div {
			div {
				div(.part(Parts.phone)) {
					p {
						"NOKIA"
					}
					.style(Styles.brand)

					div {
						p {
							"Composer"
						}
						.style(Styles.screenTitle)

						p(.part(Parts.code)) {}
							.style(Styles.screenCode)

						div(.part(Parts.call), .hidden) {
							p {
								"📞"
							}
							.style(Styles.callIcon)

							p(.part(Parts.caller)) {}
						}
						.style(Styles.call)
					}
					.accessibilityHidden()
					.style(Styles.screen)

					div {
						button(.part(Parts.answer), .type(.button), .hidden) {
							"Answer"
						}
						.style(Styles.softKey)

						button(.part(Parts.reject), .type(.button), .hidden) {
							"Reject"
						}
						.style(Styles.softKey)
					}
					.style(Styles.softKeys)

					div {
						for key in Self.keys {
							button(.type(.button), .hook(Hooks.key, value: key.key)) {
								strong {
									key.key
								}

								span {
									key.label
								}
								.style(Styles.keyLabel)
							}
							.accessibilityLabel("\(key.key), \(key.label)")
							.style(Styles.key)
						}

						button(.type(.button), .hook(Hooks.key, value: "c")) {
							strong {
								"C"
							}

							span {
								"delete"
							}
							.style(Styles.keyLabel)
						}
						.accessibilityLabel("C, delete")
						.style(Styles.key, Styles.wideKey)
					}
					.accessibilityLabel("Keypad. Works with the number keys of the computer too.")
					.style(Styles.keypad)
				}
				.style(Styles.phone)

				div {
					label(.for("geocities-nokia-text")) {
						"Ringtone code:"
					}
					.style(GeoCitiesPage.Styles.label)

					textarea(.id("geocities-nokia-text"), .part(Parts.text), .rows(3), .autocomplete("off"), .custom(name: "spellcheck", value: "false")) {}
						.style(GeoCitiesPage.Styles.field, Styles.text)

					div {
						label(.for("geocities-nokia-tempo")) {
							"Tempo:"
						}

						select(.id("geocities-nokia-tempo"), .part(Parts.tempo)) {
							for tempo in [63, 100, 125, 160, 200, 250] {
								option(.value("\(tempo)")) {
									"\(tempo) bpm"
								}
								.attributes(.selected, when: tempo == 125)
							}
						}
						.style(GeoCitiesPage.Styles.field, GeoCitiesPage.Styles.select)
					}
					.style(GeoCitiesPage.Styles.formRow)

					div {
						button(.part(Parts.play), .type(.button)) {
							"▶ Play"
						}
						.style(GeoCitiesPage.Styles.retroButton)

						button(.part(Parts.ring), .type(.button)) {
							"📳 Ring Me!"
						}
						.style(GeoCitiesPage.Styles.retroButton)

						button(.part(Parts.midi), .type(.button)) {
							"💾 Save as MIDI"
						}
						.style(GeoCitiesPage.Styles.retroButton)

						button(.part(Parts.clear), .type(.button)) {
							"Clear"
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
					.style(GeoCitiesPage.Styles.formRow)

					GeoCitiesMusicVolume()

					p(.part(Parts.status), .role("status")) {}
						.style(Styles.status)
				}
				.style(Styles.editor)
			}
			.style(Styles.composer)

			aside {
				p {
					"RINGETONER!!!"
				}
				.style(Styles.adTitle)

				p {
					"The coolest tones for your mobile! Send TONE + code to 1999. Only kr 15,- each!*"
				}

				ul {
					for tone in Self.tones {
						li {
							span {
								tone.title
							}

							button(.type(.button), .hook(Hooks.tone, value: tone.id)) {
								"TONE \(tone.code)"
							}
							.accessibilityLabel("Order \(tone.title) for 15 kroner")
							.style(Styles.order)
						}
						.style(Styles.adItem)
					}
				}
				.style(Styles.adList)

				p {
					"* Ask your parents first. Works with Nokia 3210, 5110, and 6110."
				}
				.style(Styles.smallPrint)

				p(.part(Parts.bill)) {}
					.style(Styles.bill)

				button(.part(Parts.pay), .type(.button), .hidden) {
					"💸 Pay with my allowance"
				}
				.style(Styles.order)
			}
			.style(Styles.ad)
		}
		.style(Styles.layout, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The phone needs JavaScript. Without it, it is just a very small brick."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case phone
		case code
		case call
		case caller
		case answer
		case reject
		case text
		case tempo
		case play
		case ring
		case midi
		case clear
		case status
		case bill
		case pay
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A key of the phone, like `1` or `#`, or `c` for the clear key.
		*/
		case key = "data-nokia-key"

		/**
		A ringtone of the ad, by its ID.
		*/
		case tone = "data-nokia-tone"
	}

	enum Styles: ElementStyleSet {
		case root
		case layout
		case composer
		case phone
		case brand
		case screen
		case screenTitle
		case screenCode
		case call
		case callIcon
		case softKeys
		case softKey
		case keypad
		case key
		case wideKey
		case keyLabel
		case editor
		case text
		case status
		case ad
		case adTitle
		case adList
		case adItem
		case order
		case smallPrint
		case bill

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .layout:
				Style()
					.grid(minimumColumnWidth: .rootEm(18))
					.gap(.rootEm(1))
					.alignItems(.start)
			case .composer:
				Style()
					.hstack(alignment: .start, spacing: .rootEm(1))
					.flexWrap()
			case .phone:
				// The dark blue Nokia 3210, round at the top and the bottom, with the screen at the top and the keys below.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(width: .rootEm(11))
					.padding(vertical: .rootEm(1), horizontal: .rootEm(0.75))
					.backgroundImage(.linearGradient("to right", Color("#1b2a4a"), Color("#2e4677"), Color("#1b2a4a")))
					.cornerRadius(.rootEm(3))
					.shadow(Shadow(x: .pixels(3), y: .pixels(5), color: Color("#00000080")))
					.when(.state, is: "ringing") {
						$0.media(.allowsMotion) {
							$0.animation(Animations.buzz, .linear(duration: .milliseconds(90)).repeatForever())
						}
					}
			case .brand:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.letterSpacing(.em(0.2))
					.color(Color("#c8d0e0"))
			case .screen:
				// The green screen with its light on, and black pixels.
				Style()
					.position(.relative)
					.frame(width: .percent(100), height: .rootEm(6.5))
					.padding(.rootEm(0.375))
					.background(Color("#9bbc4f"))
					.border(Color("#0e1a30"), width: .pixels(4))
					.cornerRadius(.rootEm(0.5))
					.fontFamily(GeoCitiesPage.courier)
					.color(Color("#102000"))
					.overflow(.hidden)
			case .screenTitle:
				Style()
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
					.border(.bottom, Color("#102000"), width: .pixels(1))
			case .screenCode:
				// The newest notes are at the bottom, like on the phone, where the text scrolls up.
				Style()
					.vstack(justification: .end)
					.frame(height: .rootEm(4.25))
					.font(size: .rootEm(0.75), lineHeight: 1.4)
					.fontWeight(.bold)
					.overflowWrap(.anywhere)
					.overflow(.hidden)
			case .call:
				Style()
					.position(.absolute)
					.inset(0)
					.vstack(alignment: .center, justification: .center)
					.background(Color("#9bbc4f"))
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .callIcon:
				Style()
					.font(.extraLarge)
					.media(.allowsMotion) {
						$0.animation(Animations.buzz, .linear(duration: .milliseconds(120)).repeatForever())
					}
			case .softKeys:
				Style()
					.hstack(justification: .spaceBetween, spacing: .rootEm(0.5))
					.frame(width: .percent(100), minHeight: .rootEm(1.75))
			case .softKey:
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Color("#c8d0e0"))
					.border(Color("#0e1a30"), width: .pixels(1))
					.cornerRadius(.rootEm(1))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.handCursor()
			case .keypad:
				Style()
					.grid(columns: 3)
					.gap(.rootEm(0.375))
					.frame(width: .percent(100))
			case .key:
				// A rubbery gray key, with its number and, below, what it does in the Composer.
				Style()
					.vstack(alignment: .center)
					.padding(vertical: .rootEm(0.125), horizontal: 0)
					.background(Color("#d6dae3"))
					.border(Color("#0e1a30"), width: .pixels(1))
					.cornerRadius(.rootEm(0.75))
					.fontFamily(.system)
					.color(.black)
					.lineHeight(1.1)
					.handCursor()
					.active {
						$0.background(Color("#9bbc4f"))
					}
					.when(.state, is: "pressed") {
						$0.background(Color("#9bbc4f"))
					}
			case .wideKey:
				Style().gridColumnSpan(3)
			case .keyLabel:
				Style()
					.font(size: .rootEm(0.625))
					.color(Color("#334"))
			case .editor:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.flex(1)
					.frame(minWidth: .rootEm(14))
			case .text:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
			case .status:
				Style()
					.frame(minHeight: .lineHeight(1))
					.fontWeight(.bold)
					.color(Color("#000080"))
			case .ad:
				// An ad from the back pages of a magazine for teenagers: loud colors and small print.
				Style()
					.flowSpacing(.rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#ffff66"))
					.border(Color("#ff0099"), width: .pixels(4), style: .dashed)
					.fontFamily(GeoCitiesPage.comicSans)
					.color(.black)
					.rotationEffect(.degrees(1))
			case .adTitle:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge2)
					.textAlign(.center)
					.color(Color("#ff0099"))
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#0066ff")))
			case .adList:
				Style()
					.margin(0)
					.padding(0)
					.flowSpacing(.rootEm(0.25))
			case .adItem:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.textStyle(.caption, weight: .bold)
			case .order:
				Style()
					.flexShrink(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.background(Color("#0066ff"))
					.border(.black, width: .pixels(1))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(.white)
					.handCursor()
			case .smallPrint:
				Style()
					.font(size: .rootEm(0.625))
			case .bill:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#cc0000"))
			}
		}
	}

	enum Animations: KeyframeSet {
		case buzz

		var keyframes: [Keyframe] {
			switch self {
			case .buzz:
				// The phone shakes from side to side, like a phone that vibrates on a table.
				[.from(Style().offset(x: .pixels(-2))), .to(Style().offset(x: .pixels(2)))]
			}
		}
	}
}
