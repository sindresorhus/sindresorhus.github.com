import Elementary
import Foundation
import SiteKit

/**
Sindre’s Desktop Pets, the little animals that live on the whole page, like the desktop pets of the 1990s: Neko, the kitten of 1989 that chases the pointer, sleeps when it rests, scratches, can be picked up, plays with yarn, and turns the pointer into prey, like NekoDA; Dolly, a sheep like the Stray Sheep of Windows 95 that walks on top of the windows and can be cloned, like the real Dolly of 1996; sparrows that sit on the windows and fly away from the pointer, and a seagull of Bergen that steals their bread; a mouse that runs along the bottom of the window for brown cheese, and that Neko chases; a UFO that beams up a GIF of the page, unless the visitor zaps it; and a bookworm that eats a hole in a window, which a construction worker then fixes. The window here is their control panel, like the menu of a desktop pet, where the visitor feeds them, calls them, and shoos them away, so they never sit on what the visitor reads. `geocities-life.js` brings them to life. For visitors who prefer reduced motion, they stand still where they are, and still answer when they are poked. Without scripts, the controls are hidden.
*/
struct GeoCitiesPets: HTML {
	let project: Project

	/**
	A pet of the control panel, with the ID that the script knows it by.
	*/
	private struct Pet {
		let id: String
		let name: String
		let text: String

		/**
		The buttons of the pet, by what they do in the script, with their labels.
		*/
		let actions: [(action: String, title: String)]
	}

	private static let pets = [
		Pet(id: "neko", name: "Neko the kitten", text: "Neko chases your mouse pointer (or your finger) all over my page. Let the pointer rest and Neko falls asleep. Pick Neko up and drop it, if you dare.", actions: [("neko-pet", "Pet Neko"), ("neko-yarn", "Throw yarn"), ("neko-home", "Send Neko to the basket")]),
		Pet(id: "sheep", name: "Dolly the sheep", text: "Dolly walks on top of my windows and falls off the edges. Drag her somewhere nicer. Scientists cloned a sheep in 1996, so I can too.", actions: [("sheep-clone", "Clone Dolly"), ("sheep-baa", "Say mæ")]),
		Pet(id: "birds", name: "The sparrows", text: "They sit on my windows. Move the pointer close and they fly away. Bread brings them back. Watch out for the seagulls of Bergen.", actions: [("birds-crumbs", "Throw bread crumbs")]),
		Pet(id: "mouse", name: "The mouse (not that kind)", text: "A real mouse lives at the bottom of the window. It loves brown cheese. Neko loves the mouse. The mouse does not love Neko.", actions: [("mouse-cheese", "Put out brown cheese")]),
		Pet(id: "ufo", name: "The UFO", text: "Now and then it flies over my page and beams up a GIF. Click the UFO before it gets away!", actions: [("ufo-call", "Call the UFO"), ("ufo-zap", "Zap the UFO"), ("ufo-return", "Ask Area 51 for the GIFs")]),
		Pet(id: "worm", name: "The bookworm", text: "It eats holes in my windows. Luckily my page is always under construction, so a worker fixes them.", actions: [("worm-call", "Call the bookworm")]),
	]

	var body: some HTML {
		section(.id(Hooks.root)) {
			h2 {
				"Sindre’s Desktop Pets 1.0"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				p {
					GeoCitiesPage.GIFImage(gif: .cat, alt: "", style: .floating, project: project)
					"My page is "
					strong {
						"ALIVE"
					}
					.style(GeoCitiesPage.Styles.rainbowText)
					"! These little guys live all over it. Feed them, pet them, or shoo them away if they sit on what you want to read. They do not need a floppy disk or a reboot."
				}

				div {
					ForEach(Self.pets) { pet in
						card(for: pet)
					}
				}
				.style(Styles.grid, GeoCitiesPage.Styles.scriptingOnly)

				GeoCitiesPage.GIFImage(gif: .worm, alt: "", style: .centered, project: project)

				div {
					button(.type(.button), .hook(Hooks.action, value: "shoo")) {
						"Shoo, all of you!"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					button(.type(.button), .hook(Hooks.action, value: "welcome")) {
						"Everybody back!"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow, GeoCitiesPage.Styles.scriptingOnly)

				p(.id(Hooks.status), .role("status")) {}
					.style(GeoCitiesPage.Styles.centeredText, GeoCitiesPage.Styles.scriptingOnly)

				p {
					"My pets need JavaScript to come out. Right now they are all asleep under the desk."
				}
				.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
			}
			.style(GeoCitiesPage.Styles.windowBody)

			templates
		}
		.style(GeoCitiesPage.Styles.window)

		ModuleScript("/scripts/geocities-life.js")
	}

	/**
	The card of a pet: its picture, what it does, whether it lives on the page, and its buttons.
	*/
	private func card(for pet: Pet) -> some HTML {
		div {
			div {
				petPicture(for: pet)
			}
			.accessibilityHidden()
			.style(Styles.picture)

			div {
				h3 {
					pet.name
				}
				.style(Styles.name)

				p {
					pet.text
				}
				.style(Styles.text)

				// The live counts of the pet, like how many sheep there are, which the script fills.
				p(.hook(Hooks.count, value: pet.id)) {}
					.style(Styles.count)

				if pet.id == "neko" {
					label {
						"Your pointer: "
						select(.id(Hooks.prey)) {
							for (value, title) in [("arrow", "Arrow"), ("mouse", "Mouse"), ("fish", "Fish"), ("bird", "Bird")] {
								Elementary.option(.value(value)) {
									title
								}
							}
						}
						.style(Styles.select)
					}
					.style(Styles.text)
				}

				label {
					input(.type(.checkbox), .hook(Hooks.toggle, value: pet.id))
						.attributes(.checked)
					" Lives on my page"
				}
				.style(Styles.text)

				div {
					for (action, title) in pet.actions {
						button(.type(.button), .hook(Hooks.action, value: action)) {
							title
						}
						.style(GeoCitiesPage.Styles.retroButton, Styles.button)
					}
				}
				.style(Styles.buttons)
			}
			.style(Styles.body)
		}
		.style(Styles.card)
	}

	/**
	The picture of a pet. Neko sleeps in its basket, the UFO is a GIF, and the sprites of the others, which the script draws, are on a small canvas.
	*/
	@HTMLBuilder
	private func petPicture(for pet: Pet) -> some HTML {
		if pet.id == "neko" {
			// The basket, where Neko sleeps while it is home. The script shows Neko awake in it when it is poked, and an empty basket while Neko is out.
			div(.id(Hooks.basket), .hook(ScriptAttribute.state, value: "home")) {
				div {
					img(.src(GeoCitiesPage.GIF.neko.path), .alt(""), .width(256), .height(128))
						.style(Styles.nekoSheet)
				}
				.style(Styles.nekoFrame)
			}
			.style(Styles.basket)
		} else if pet.id == "ufo" {
			GeoCitiesPage.GIFImage(gif: .ufo, alt: "", style: .gif, project: project)
		} else {
			canvas(.hook(Hooks.picture, value: pet.id), .width(48), .height(48)) {}
				.style(Styles.pixels)
		}
	}

	/**
	The parts that the script copies for the pets. The two layers go at the end of the page, outside of the panel, which can be turned upside down or filtered by the “Best viewed with…” buttons: one scrolls with the page, for the pets that live on the windows, and one stays on the screen, for the pets that live on the glass.
	*/
	private var templates: some HTML {
		div {
			template(.id(Hooks.pageLayerTemplate)) {
				div {}
					.accessibilityHidden()
					.style(Styles.pageLayer)
			}

			template(.id(Hooks.screenLayerTemplate)) {
				div {}
					.accessibilityHidden()
					.style(Styles.screenLayer)
			}

			template(.id(Hooks.critterTemplate)) {
				div {}
					.style(Styles.critter)
			}

			template(.id(Hooks.bubbleTemplate)) {
				span {}
					.style(Styles.bubble)
			}

			template(.id(Hooks.nekoTemplate)) {
				div {
					img(.src(GeoCitiesPage.GIF.neko.path), .alt(""), .width(256), .height(128))
						.style(Styles.nekoSheet)
				}
				.style(Styles.critter, Styles.nekoFrame)
			}
		}
	}

	enum Hooks: String, ScriptHookSet {
		case root = "geocities-pets"
		case status = "geocities-pets-status"
		case prey = "geocities-pets-prey"
		case basket = "geocities-pets-basket"
		case pageLayerTemplate = "geocities-pets-page-layer"
		case screenLayerTemplate = "geocities-pets-screen-layer"
		case critterTemplate = "geocities-pets-critter"
		case bubbleTemplate = "geocities-pets-bubble"
		case nekoTemplate = "geocities-pets-neko"

		/**
		What a button of the panel does, like `neko-yarn`.
		*/
		case action = "data-critter-action"

		/**
		The checkbox of a pet that lives on the page, with the ID of the pet.
		*/
		case toggle = "data-critter-toggle"

		/**
		The counts of a pet, with the ID of the pet.
		*/
		case count = "data-critter-count"

		/**
		The canvas where the script draws a pet for its card, with the ID of the pet.
		*/
		case picture = "data-critter-picture"
	}

	enum Styles: StyleSet {
		case grid
		case card
		case picture
		case pixels
		case body
		case name
		case text
		case count
		case select
		case buttons
		case button
		case basket
		case nekoFrame
		case nekoSheet
		case pageLayer
		case screenLayer
		case critter
		case bubble

		var style: Style {
			switch self {
			case .grid:
				Style()
					.grid(minimumColumnWidth: .rootEm(17))
					.gap(.rootEm(0.75))
			case .card:
				// A white box with a sunken edge, like a list in a window of Windows 95, with the picture of the pet next to what it does.
				Style()
					.hstack(alignment: .start, spacing: .rootEm(0.75))
					.padding(.rootEm(0.625))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .picture:
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(4), height: .rootEm(4))
					.flexShrink(0)
					.background(Color("#000033"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.children("picture img") {
						$0.frame(width: .rootEm(3.5), height: .auto, maxHeight: .rootEm(3.5))
							.objectFit(.contain)
					}
			case .pixels:
				Style()
					.display(.block)
					.frame(width: .rootEm(3), height: .rootEm(3))
					.imageRendering(.pixelated)
			case .body:
				Style()
					.vstack(alignment: .start, spacing: .rootEm(0.375))
					.frame(minWidth: 0)
					.flex(1)
			case .name:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
					.color(Color("#800000"))
			case .text:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption)
			case .count:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#006600"))
			case .select:
				Style()
					.fontFamily(.system)
					.textStyle(.caption)
			case .buttons:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .button:
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.textStyle(.caption, weight: .bold)
			case .basket:
				// A wicker basket at the bottom of the picture, where Neko sleeps while it is home.
				Style()
					.position(.relative)
					.hstack(alignment: .end, justification: .center)
					.frame(width: .percent(100), height: .percent(100))
					.after {
						$0
							.content("")
							.position(.absolute)
							.leading(.percent(8))
							.trailing(.percent(8))
							.bottom(.pixels(2))
							.frame(height: .rootEm(1))
							.background(Color("#b5651d"))
							.border(Color("#8b4513"), width: .pixels(3), style: .ridge)
							.cornerRadius(.rootEm(0.25))
					}
					.when(.state, is: "home") {
						$0.children("*") {
							$0.visibility(true)
						}
					}
					.when(.state, is: "awake") {
						$0.children("*") {
							$0.visibility(true)
						}
					}
					.when(.state, is: "out") {
						$0.children("*") {
							$0.visibility(false)
						}
					}
			case .nekoFrame:
				// One sprite of the sheet of Neko, of 32 × 32 pixels. The script moves the sheet behind it to show the other sprites. In the basket, Neko sleeps.
				Style()
					.overflow(.hidden)
					.frame(width: .pixels(32), height: .pixels(32))
					.flexShrink(0)
					.margin(.bottom, .pixels(4))
			case .nekoSheet:
				Style()
					.display(.block)
					.frame(width: .pixels(256), height: .pixels(128), maxWidth: .pixels(256))
					.offset(x: .pixels(-64), y: 0)
					.imageRendering(.pixelated)
					.allowsHitTesting(false)
			case .pageLayer:
				// It covers the page from the top, as high as the page, so the pets on the windows scroll with it, under the header of the site and the toolbar of the browser. It cuts off what goes past the sides, so nothing makes the page wider.
				Style()
					.position(.absolute)
					.top(0)
					.leading(0)
					.frame(width: .percent(100), height: 0)
					.overflow(horizontal: .clip)
					.zIndex(39)
					.allowsHitTesting(false)
			case .screenLayer:
				// The pets on the glass are over everything, like the desktop pets of 1990s, but under the toasts.
				Style()
					.position(.fixed)
					.inset(0)
					.overflow(.clip)
					.zIndex(58)
					.allowsHitTesting(false)
			case .critter:
				// A pet, which the script moves. A finger drags it instead of scrolling the page.
				Style()
					.position(.absolute)
					.top(0)
					.leading(0)
					.allowsHitTesting(true)
					.touchAction(.none)
					.imageRendering(.pixelated)
					.textSelection(.disabled)
					.handCursor()
					.children("canvas") {
						$0.display(.block)
					}
			case .bubble:
				// A small speech bubble of a pet, like “Mæ!”, which the script puts above it.
				Style()
					.position(.absolute)
					.top(0)
					.leading(0)
					.padding(vertical: .pixels(1), horizontal: .pixels(6))
					.background(.white)
					.border(.black, width: .pixels(2))
					.cornerRadius(.rootEm(0.75))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.textWrap(.nowrap)
					.color(.black)
					.allowsHitTesting(false)
			}
		}
	}
}
