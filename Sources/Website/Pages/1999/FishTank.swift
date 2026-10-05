import Elementary
import Foundation
import SiteKit

/**
My aquarium, a fish tank like El-Fish (1993) and the aquarium screen savers of the 1990s: fish that swim around and follow the pointer or a finger, food that sinks and makes the fish grow, too much food that makes the water green until the visitor cleans the tank, a glass to tap on, which scares the fish and puffs up the pufferfish, a pet shop with more fish, and a light switch. Its script, `FishTank.js`, draws the tank on the canvas and keeps the fish in the browser. For visitors who prefer reduced motion, the tank shows a still picture, which changes with each thing the visitor does.
*/
struct GeoCitiesFishTank: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the menu of the pet shop, for its label.
	*/
	private static let speciesID = "geocities-fish-species"

	let project: Project

	/**
	The fish of the pet shop, by the ID that the script draws them by.
	*/
	private static let species: [(id: String, name: String)] = [
		("goldfish", "Goldfish"),
		("neon", "Neon tetra"),
		("angel", "Angelfish"),
		("puffer", "Pufferfish"),
		("cod", "Cod from Bergen"),
	]

	var content: some HTML {
		h2 {
			"Aquarium.exe"
		}
		.style(GeoCitiesPage.Styles.titleBar)

		div {
			p {
				GeoCitiesPage.GIFImage(gif: .fishbowl, alt: "", style: .floating, project: project)
				"My fish tank! Move your mouse (or your finger) in the water and the fish follow it. Click to drop food. Do NOT tap on the glass. Mom says it scares them. Dad says it is a screen."
			}

			canvas(.part(Parts.tank), .width(640), .height(360), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The fish tank. The fish follow your pointer or finger. Click or press Space to drop food, and move your finger with the arrow keys.")
				.style(Styles.tank, GeoCitiesPage.Styles.scriptingOnly)

			p(.part(Parts.stats)) {}
				.style(Styles.stats, GeoCitiesPage.Styles.scriptingOnly)

			div {
				button(.part(Parts.food), .type(.button)) {
					"Feed the fish"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.tap), .type(.button)) {
					"Tap on the glass"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.lights), .type(.button), .ariaPressed(true)) {
					"Lights"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.clean), .type(.button)) {
					"Clean the tank"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow, GeoCitiesPage.Styles.scriptingOnly)

			div {
				label(.for(Self.speciesID)) {
					"Pet shop:"
				}

				select(.id(Self.speciesID), .part(Parts.species)) {
					ForEach(Self.species) { fish in
						Elementary.option(.value(fish.id)) {
							fish.name
						}
					}
				}

				button(.part(Parts.buy), .type(.button)) {
					"Buy (free!)"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow, GeoCitiesPage.Styles.scriptingOnly)

			p(.part(Parts.status), .role("status")) {}
				.style(GeoCitiesPage.Styles.centeredText, GeoCitiesPage.Styles.scriptingOnly)

			p {
				"The fish need JavaScript to swim. Right now they are hiding behind the castle."
			}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
		}
		.style(GeoCitiesPage.Styles.windowBody)
	}

	enum Parts: String, ElementPartSet {
		case tank
		case stats
		case food
		case tap
		case lights
		case clean
		case species
		case buy
		case status
	}

	enum Styles: ElementStyleSet {
		case root
		case tank
		case stats

		var style: Style {
			switch self {
			case .root:
				// The window that was a section. A custom element is inline by default, so it is a block.
				GeoCitiesPage.Styles.window.style.display(.block)
			case .tank:
				// The glass of the tank, in a black frame, like a tank on a cabinet. A finger scrolls the page as usual, so the tank is no trap on a phone, and the fish swim to where it touches.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(16.0 / 9.0)
					.border(Color("#222222"), width: .pixels(6), style: .ridge)
					.imageRendering(.pixelated)
					.touchAction(.manipulation)
					.cursor(.crosshair)
			case .stats:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			}
		}
	}
}
