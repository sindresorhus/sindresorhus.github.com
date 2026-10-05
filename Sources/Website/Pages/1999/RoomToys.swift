import Elementary
import Foundation
import SiteKit

/**
Three toys of my room, each in a window: under the bed, where a flashlight with dying batteries looks for the things I lost before Mom turns off the light; the ceiling over the bunk bed, with glow-in-the-dark stars that the visitor sticks on, which glow when the light goes off and fade as they lose their charge, and can be joined into a constellation; and a Magic Screen, which draws one line with two knobs and is erased by shaking it. Its script, `RoomToys.js`, runs them.
*/
struct GeoCitiesRoomToys: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the window under the bed, which the bed in my room leads to.
	*/
	static let underBedID = "geocities-under-bed"

	/**
	The ID of the window of the glow stars, which the stars over the bed in my room lead to.
	*/
	static let ceilingID = "geocities-ceiling"

	var content: some HTML {
		div {
			window("Under My Bed", id: Self.underBedID) {
				underBed
			}

			window("Glow-in-the-Dark Stars", id: Self.ceilingID) {
				ceiling
			}

			window("Magic Screen") {
				sketch
			}
		}
		.style(Styles.toys, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The toys of my room need JavaScript. And batteries."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	private var underBed: some HTML {
		div {
			p {
				"Mom turns off the light in one minute, and the batteries of the flashlight are almost dead. Find my things! Bang the flashlight when it gets dim."
			}
			.style(GeoCitiesPage.Styles.caption)

			canvas(.part(Parts.bedCanvas), .width(320), .height(180), .tabindex(0), .role("application")) {}
				.accessibilityLabel("Under my bed, in the dark. Move the flashlight with the arrow keys, and press Enter to pick up what it shines on.")
				.style(Styles.canvas, Styles.bedCanvas)

			ul(.part(Parts.bedList)) {}
				.accessibilityLabel("Things to find")
				.style(Styles.checklist)

			div {
				button(.part(Parts.bedStart), .type(.button)) {
					"Turn On the Flashlight"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.bedBang), .type(.button), .disabled) {
					"Bang the Flashlight"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.dimmedWhenDisabled)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.bedStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.toy)
	}

	private var ceiling: some HTML {
		div {
			p {
				"Click the ceiling over my bunk bed to stick on a star. Then turn off the light, and join the stars into a constellation while they glow."
			}
			.style(GeoCitiesPage.Styles.caption)

			canvas(.part(Parts.ceilingCanvas), .width(320), .height(200), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The ceiling over my bed. Move with the arrow keys, and press Enter to stick on a star, or in the dark, to join it to the last one.")
				.style(Styles.canvas, Styles.ceilingCanvas)

			div {
				button(.part(Parts.ceilingLight), .type(.button)) {
					"Turn Off the Light"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.ceilingClear), .type(.button)) {
					"Peel Them All Off"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			label {
				"My constellation is called: "
				input(.part(Parts.ceilingName), .type(.text), .maxlength(30), .autocomplete("off"), .placeholder("The Great Waffle"))
					.style(GeoCitiesPage.Styles.field)
			}
			.style(Styles.nameLabel)

			p(.part(Parts.ceilingStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.toy)
	}

	private var sketch: some HTML {
		div {
			p {
				"Turn the left knob to draw sideways, and the right knob to draw up and down: drag around a knob in circles, or use the arrow keys. Shake it to erase."
			}
			.style(GeoCitiesPage.Styles.caption)

			canvas(.part(Parts.sketchCanvas), .width(280), .height(220), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The Magic Screen. The left and right arrow keys turn the left knob, and the up and down arrow keys turn the right knob.")
				.style(Styles.sketchCanvas)

			div {
				button(.part(Parts.sketchShake), .type(.button)) {
					"Shake It to Erase"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.sketchStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.toy)
	}

	/**
	A window of a toy. A window with an ID, which a thing in my room leads to, can have the focus, so the keyboard goes on from there.
	*/
	private func window(_ title: String, id: String? = nil, @HTMLBuilder content: () -> some HTML) -> some HTML {
		section {
			h3 {
				title
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				content()
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.attributes(.id(id ?? ""), .tabindex(-1), when: id != nil)
		.style(GeoCitiesPage.Styles.window)
	}

	enum Parts: String, ElementPartSet {
		case bedCanvas
		case bedList
		case bedStart
		case bedBang
		case bedStatus

		case ceilingCanvas
		case ceilingLight
		case ceilingClear
		case ceilingName
		case ceilingStatus

		case sketchCanvas
		case sketchShake
		case sketchStatus
	}

	enum Styles: ElementStyleSet {
		case root
		case toys
		case toy
		case canvas
		case bedCanvas
		case ceilingCanvas
		case checklist
		case status
		case nameLabel
		case sketchCanvas
		case dimmedWhenDisabled

		var style: Style {
			switch self {
			case .root:
				// The three windows stay sections of the page, so the pets stand on each of them, as if the element was not there.
				Style().display(.contents)
			case .toys:
				Style()
					.grid(minimumColumnWidth: .rootEm(17))
					.gap(.rootEm(1.25))
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .toy:
				Style().vstack(spacing: .rootEm(0.5))
			case .canvas:
				// Big pixels.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.imageRendering(.pixelated)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.background(.black)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .bedCanvas:
				// A finger moves the flashlight instead of scrolling the page.
				Style()
					.aspectRatio(320.0 / 180.0)
					.touchAction(.none)
			case .ceilingCanvas:
				// A tap sticks on a star, and a finger can still scroll the page, as the stars go on with a click.
				Style()
					.aspectRatio(320.0 / 200.0)
					.touchAction(.manipulation)
					.cursor(.crosshair)
			case .checklist:
				// The things to find, ticked off as they are found.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
					.margin(0)
					.padding(0)
					.textStyle(.caption)
					.children("li") {
						$0
							.padding(vertical: 0, horizontal: .rootEm(0.375))
							.background(.white)
							.border(Color("#808080"), width: .pixels(1))
					}
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .nameLabel:
				Style()
					.display(.block)
					.textStyle(.caption, weight: .bold)
			case .dimmedWhenDisabled:
				// The small buttons of the page have no look of their own when they do nothing.
				Style().disabled {
					$0.opacity(0.5)
				}
			case .sketchCanvas:
				// The red frame and the knobs are part of the drawing, and a finger turns the knobs instead of scrolling the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(280.0 / 220.0)
					.touchAction(.none)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			}
		}
	}
}
