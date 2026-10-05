import Elementary
import Foundation
import SiteKit

/**
Comic Chat ’99, a chat room drawn as a comic strip, like Microsoft Comic Chat of 1996, with the art of Jim Woodring. The visitor types a line, and the characters act it out in a new panel, with the rules of Comic Chat: “hi” and “bye” wave, “I” points to yourself, “you” points to the other, LOL laughs, capitals and “!!!” shout with a jagged balloon, and smileys set the face. The emotion wheel picks the face by hand, like in Comic Chat. Sindre answers and acts out his answer too, Rocky the pet rock sits in the room and says nothing, and Mom needs the phone line after a while. Its script, `ComicChat.js`, draws the panels.
*/
struct GeoCitiesComicChat: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the menu of the characters, for its label.
	*/
	private static let characterID = "geocities-comic-character"

	/**
	The ID of the field of the line, for its label.
	*/
	private static let inputID = "geocities-comic-input"

	/**
	The emotions of the wheel, in the order of the 3 × 3 grid: around the circle as in Comic Chat, with neutral in the middle. Each shows as a smiley of 1999.
	*/
	private static let emotions: [(id: String, name: String, smiley: String)] = [
		("coy", "Coy", ";-)"),
		("happy", "Happy", ":-)"),
		("laughing", "Laughing", ":-D"),
		("bored", "Bored", ":-|"),
		("auto", "Automatic", "Auto"),
		("shouting", "Shouting", ":-O"),
		("scared", "Scared", ":-S"),
		("sad", "Sad", ":-("),
		("angry", "Angry", ">:-("),
	]

	/**
	The characters that the visitor can be.
	*/
	private static let characters: [(id: String, name: String)] = [
		("kid", "Propeller Kid"),
		("dude", "Cool Dude"),
		("mormor", "Mormor"),
		("alien", "Alien from Area 51"),
	]

	var content: some HTML {
		h2 {
			"Comic Chat ’99: #sindres-room"
		}
		.style(GeoCitiesPage.Styles.titleBar)

		div {
			p {
				"Chat with me in a real comic book! Type something and we act it out. Say "
				strong {
					"hi"
				}
				" and I wave. Start with "
				strong {
					"I"
				}
				" and you point at yourself. SHOUT IN CAPITALS. LOL works too. Smileys like :-) change your face."
			}

			div(.part(Parts.strip), .role("log")) {}
				.accessibilityLabel("The comic strip of the chat")
				.style(Styles.strip, GeoCitiesPage.Styles.scriptingOnly)

			form(.part(Parts.form)) {
				div {
					div {
						label(.for(Self.characterID)) {
							"You are:"
						}
						.style(GeoCitiesPage.Styles.label)

						select(.id(Self.characterID), .part(Parts.character)) {
							ForEach(Self.characters) { character in
								Elementary.option(.value(character.id)) {
									character.name
								}
							}
						}
					}

					fieldset {
						legend {
							"Emotion wheel"
						}
						.style(Styles.legend)

						div {
							ForEach(Self.emotions) { emotion in
								label {
									input(.type(.radio), .name("geocities-comic-emotion"), .value(emotion.id))
										.attributes(.checked, when: emotion.id == "auto")
										.style(VisuallyHidden.Styles.root)

									span {
										emotion.smiley
									}
									.accessibilityHidden()

									span {
										emotion.name
									}
									.style(VisuallyHidden.Styles.root)
								}
								.style(Styles.emotion)
							}
						}
						.style(Styles.wheel)
					}
					.style(Styles.fieldset)
				}
				.style(Styles.options)

				div {
					label(.for(Self.inputID)) {
						"Say something:"
					}
					.style(GeoCitiesPage.Styles.label)

					div {
						input(.id(Self.inputID), .part(Parts.input), .type(.text), .autocomplete("off"), .maxlength(80), .placeholder("Hi Sindre! I LOVE your page!!!"))
							.style(Styles.input)

						button(.type(.submit), .hook(Hooks.mode, value: "say")) {
							"Say"
						}
						.style(GeoCitiesPage.Styles.retroButton)

						button(.type(.submit), .hook(Hooks.mode, value: "think")) {
							"Think"
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
					.style(Styles.inputRow)
				}

				div {
					button(.part(Parts.clear), .type(.button)) {
						"New page"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					button(.part(Parts.reconnect), .type(.button), .hidden) {
						"Reconnect"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.style(GeoCitiesPage.Styles.form, GeoCitiesPage.Styles.scriptingOnly)

			p {
				"Comic Chat needs JavaScript. Imagine me waving at you in a comic. *wave*"
			}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
		}
		.style(GeoCitiesPage.Styles.windowBody)

		// The parts of a panel, which the script copies: the panel with its background, a balloon, and a character.
		template(.part(Parts.panelTemplate)) {
			figure {
				div {}
					.style(Styles.balloons)

				div {}
					.style(Styles.cast)

				figcaption {}
					.style(VisuallyHidden.Styles.root)
			}
			.style(Styles.panel)
		}

		template(.part(Parts.balloonTemplate)) {
			p {}
				.style(Styles.balloon)
		}

		template(.part(Parts.characterTemplate)) {
			div {}
				.accessibilityHidden()
				.style(Styles.character)
		}
	}

	enum Parts: String, ElementPartSet {
		case strip
		case form
		case character
		case input
		case clear
		case reconnect
		case panelTemplate
		case balloonTemplate
		case characterTemplate
	}

	enum Hooks: String, ScriptHookSet {
		/**
		Whether a button says or thinks the line: `say` or `think`.
		*/
		case mode = "data-comic-mode"

		/**
		The side of the panel of the speaker of a balloon, `right` for the one on the right, so its tail points there.
		*/
		case side = "data-comic-side"
	}

	enum Styles: ElementStyleSet {
		case root
		case strip
		case panel
		case balloons
		case balloon
		case cast
		case character
		case options
		case fieldset
		case legend
		case wheel
		case emotion
		case inputRow
		case input

		var style: Style {
			switch self {
			case .root:
				// The window that was a section. A custom element is inline by default, so it is a block.
				GeoCitiesPage.Styles.window.style.display(.block)
			case .strip:
				// The panels of the comic, side by side like a page of a comic book, and one under the other on phones, so the balloons have room.
				Style()
					.grid(columns: 1)
					.gap(.rootEm(0.5))
					.padding(.rootEm(0.5))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.from(.smallTablet) {
						$0.grid(columns: 2)
					}
					.from(.tablet) {
						$0.grid(columns: 3)
					}
			case .panel:
				// A panel of the comic, with a black border and a room behind the characters: a wall, a window with the rain of Bergen, and a floor.
				Style()
					.position(.relative)
					.vstack(justification: .spaceBetween)
					.aspectRatio(1)
					.margin(0)
					.backgroundImage(.linearGradient("to bottom", Color("#fff7d6"), Color("#fff7d6"), Color("#ffe6a8"), Color("#d9a066"), Color("#c08040")))
					.border(.black, width: .pixels(3))
					.when(.state, is: "mom") {
						$0.backgroundImage(.linearGradient("to bottom", Color("#ffd6d6"), Color("#ffb0b0"), Color("#d96666")))
					}
			case .balloons:
				Style()
					.vstack(alignment: .start, spacing: .rootEm(0.25))
					.padding(.rootEm(0.25))
					.zIndex(1)
			case .balloon:
				// A balloon of speech, round with a tail toward its speaker, in the capitals of comic lettering. A shout is jagged and yellow, and a thought is a cloud with a bubble for its tail.
				Style()
					.position(.relative)
					.frame(maxWidth: .percent(92))
					.margin(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(.white)
					.border(.black, width: .pixels(2))
					.cornerRadius(.rootEm(1))
					.fontFamily(GeoCitiesPage.comicSans)
					.font(size: .rootEm(0.7), lineHeight: 1.2)
					.textCase(.uppercase)
					.overflowWrap(.anywhere)
					.color(.black)
					.after {
						$0
							.content("")
							.position(.absolute)
							.bottom(.rootEm(-0.4))
							.leading(.rootEm(1))
							.frame(width: .rootEm(0.6), height: .rootEm(0.6))
							.background(.white)
							.border([.bottom, .trailing], .black, width: .pixels(2))
							.rotationEffect(.degrees(45))
					}
					.when(Hooks.side, is: "right") {
						$0
							.alignSelf(.end)
							.after {
								$0
									.leading(.auto)
									.trailing(.rootEm(1))
							}
					}
					.when(.state, is: "shout") {
						$0
							.background(Color("#ffff99"))
							.border(.black, width: .pixels(3))
							.cornerRadius(0)
							.fontWeight(.bold)
							.font(size: .rootEm(0.8), lineHeight: 1.2)
							.rotationEffect(.degrees(-2))
							.after {
								$0
									.background(Color("#ffff99"))
									.border([.bottom, .trailing], .black, width: .pixels(3))
							}
					}
					.when(.state, is: "think") {
						$0
							.border(.black, width: .pixels(2), style: .dashed)
							.cornerRadius(.rootEm(2))
							.italic()
							.after {
								$0
									.bottom(.rootEm(-0.6))
									.frame(width: .rootEm(0.45), height: .rootEm(0.45))
									.border(.black, width: .pixels(2))
									.cornerRadius(.percent(50))
							}
					}
			case .cast:
				// The characters stand on the floor, facing each other.
				Style()
					.hstack(alignment: .end, justification: .spaceBetween)
					.frame(height: .percent(52))
					.padding(.horizontal, .percent(4))
			case .character:
				Style()
					.frame(width: .percent(30), height: .percent(100))
					.children("svg") {
						$0.frame(width: .percent(100), height: .percent(100))
					}
			case .options:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(1))
					.flexWrap()
					.frame(width: .percent(100))
			case .fieldset:
				Style()
					.margin(0)
					.padding(0)
					.border(.transparent, width: 0)
			case .legend:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .wheel:
				// The emotion wheel of Comic Chat: a circle with the emotions around its edge and neutral in the middle.
				Style()
					.grid(columns: 3)
					.frame(width: .rootEm(11), height: .rootEm(11))
					.padding(.rootEm(1.25))
					.backgroundImage(.radialGradient("circle", Color("#ffffff"), Color("#ffffcc"), Color("#ffcc66")))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.cornerRadius(.percent(50))
			case .emotion:
				// A smiley of the wheel, which is pressed in while it is picked.
				Style()
					.hstack(alignment: .center, justification: .center)
					.cornerRadius(.percent(50))
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .rootEm(0.75), lineHeight: 1)
					.fontWeight(.bold)
					.textWrap(.nowrap)
					.color(.black)
					.handCursor()
					.hover {
						$0.background(Color("#ffffff"))
					}
					.focusWithin {
						$0.focusRing(.black, width: .pixels(1), offset: .pixels(-2), style: .dotted)
					}
					// The script marks the smiley that is picked, as the radio button is hidden.
					.when(.state, is: "picked") {
						$0
							.background(Color("#000080"))
							.color(.white)
					}
			case .inputRow:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .input:
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(10))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.375))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(.system)
			}
		}
	}
}
