import Elementary
import Foundation
import SiteKit

/**
My camera cartridge (1998), the blue cartridge with the eye on top, plugged into my handheld game console, with the little printer on a link cable next to it. The screen is a canvas of 160 × 144 pixels in 4 shades, and the photos are 128 × 112 pixels, made with the ordered (Bayer) dithering of the real camera, with its brightness and contrast on the D-pad. After the power switch (or a tap on the dark screen or any button of the game console), the eye of the camera comes down, and the menu has Shoot, View, Edit, Music, and Race. The camera photographs drawn scenes that pan like a hand that holds the camera (my room with the rain in the window, Rocky on my desk, Glitter on the monitor with the black stripe of a filmed screen, and the rain at Bryggen), or, only after the visitor clicks “Use My Webcam”, the real webcam, which stops again when the game console leaves the screen (also while the wardrobe door below it is still on the screen) or the page closes, with a clear message when there is no camera or the visitor says no. The eye turns around for photos of me (or the visitor, mirrored). The A button takes a photo with the shutter sound into the album of 30 photos, like the real one, with the trick lenses (two kinds of mirrors and a panorama of four shots) and the hot-air balloon of the self-timer. In the album, the visitor flips through the photos, picks one of 9 frames, puts stamps on them (a hat, a mustache, sunglasses, a heart, a star, a crown, and “HEI!”) with undo, erases them, and saves them as a PNG. Music is a small step sequencer of 16 steps for a melody, a bass, and 3 drums, with a demo song and a random one, and Race is a race of 100 meters against Trond, where A and B, one after the other, make the runner with the visitor’s last photo as the head run. The little printer prints a photo with its buzz on thermal paper (white, yellow, or blue sticker paper) that slides out of the top, band by band (the printer comes into view when it starts, as on a phone it is below the buttons of the camera, so the screen and the buttons fit on the screen together), until the roll runs out and Mamma has to buy a new one. A printed sticker is torn off and stuck inside my wardrobe door, where the visitor drags it to a place (or moves it with the arrow keys). The colors of the screen can be the green of the first handhelds or the palettes that a color handheld picks with the buttons at the start. Its script, `HandheldCamera.js`, runs it, only while it is on the screen and the tab is visible, and keeps the album, the stickers, the song, and the best time in the browser. Nothing makes a sound until the visitor turns on the sound or plays the song, and with reduced motion, the scenes do not pan or rain by themselves (the webcam still updates), the balloon and the paper move in steps, and the race only moves when the visitor presses a button.
*/
struct GeoCitiesHandheldCamera: ScriptedElement {
	static let script = ElementScript()

	var content: some HTML {
		h2 {
			"My Camera Cartridge"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"I got the camera cartridge for my birthday, and the little printer for Christmas (Mormor paid half). The camera goes in the top of my handheld game console, and the eye on it turns around, so I can take photos of myself. The photos are 128 × 112 pixels in 4 shades of green, and the printer prints them on stickers! Pappa says they look like the newspaper photos of 1950. Turn it on!"
		}

		div {
			// The window of the game console and its buttons, without the wardrobe door below it. The toy runs only while it is on the screen.
			section(.part(Parts.handheld)) {
				h3 {
					"CAMERA + PRINTER"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					div {
						Console()

						span {}
							.accessibilityHidden()
							.style(Styles.cable)

						Printer()
					}
					.style(Styles.rig)

					Modes()

					// The status is above the buttons of the mode, so it is close to the screen and to the button that was pressed, also on a phone.
					p(.part(Parts.status), .role("status")) {
						"It is off. Slide the power switch at the top of the game console, or press START!"
					}
					.style(Styles.status)

					ShootPanel()

					AlbumPanel()

					StampPanel()

					MusicPanel()

					RunPanel()

					Keys()
				}
				.style(GeoCitiesPage.Styles.windowBody, Styles.body)
			}
			.style(GeoCitiesPage.Styles.window, Styles.toy)

			Wardrobe()
		}
		.style(Styles.stack, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My camera cartridge needs JavaScript. And four AA batteries, and six more for the printer."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The game console in see-through purple, like ``GeoCitiesHandheld``, with the camera cartridge and its eye on top.
	*/
	private struct Console: HTML {
		var body: some HTML {
			div {
				Cartridge()

				div {
					div {
						button(.part(Parts.power), .type(.button), .ariaPressed(false)) {
							"OFF ◂ ▸ ON"
						}
						.accessibilityLabel("Power")
						.style(GeoCitiesHandheld.Styles.power)

						span(.part(Parts.led)) {}
							.accessibilityHidden()
							.style(GeoCitiesHandheld.Styles.led)
					}
					.style(GeoCitiesHandheld.Styles.top)

					div {
						// The screen is drawn at 160 × 144 pixels, the size of the real screen, and a photo is the 128 × 112 pixels in the middle of it.
						canvas(.part(Parts.screen), .width(160), .height(144), .tabindex(0), .role("application")) {}
							.accessibilityLabel("The screen of the camera. The arrow keys are the D-pad, X or Space is A, Z is B, Enter is Start, and Backspace is Select. In Shoot, A takes a photo, up and down change the brightness, and left and right the contrast.")
							.style(Styles.screen)

						p {
							span {
								"C"
							}
							.style(GeoCitiesHandheld.Styles.red)
							span {
								"O"
							}
							.style(GeoCitiesHandheld.Styles.purple)
							span {
								"L"
							}
							.style(GeoCitiesHandheld.Styles.green)
							span {
								"O"
							}
							.style(GeoCitiesHandheld.Styles.yellow)
							span {
								"R"
							}
							.style(GeoCitiesHandheld.Styles.blue)
						}
						.accessibilityHidden()
						.style(GeoCitiesHandheld.Styles.brand)
					}
					.style(GeoCitiesHandheld.Styles.bezel)

					Pad()
				}
				.style(GeoCitiesHandheld.Styles.body)
			}
			.style(Styles.console)
		}
	}

	private struct Cartridge: HTML {
		var body: some HTML {
			div {
				// The eye turns around for photos of myself. The script turns it with the state `turned`.
				div {
					span(.part(Parts.eye)) {}
						.style(Styles.lens)
				}
				.accessibilityHidden()
				.style(Styles.eyeBall)

				p {
					"CAMERA"
				}
				.accessibilityHidden()
				.style(Styles.cartridgeLabel)
			}
			.style(Styles.cartridge)
		}
	}

	/**
	The D-pad and the buttons, like on ``GeoCitiesHandheld``. The keyboard uses the keys on the screen instead, so they are not in the order of the Tab key.
	*/
	private struct Pad: HTML {
		var body: some HTML {
			div {
				div {
					for row in [[("up", "Up", "▲")], [("left", "Left", "◀"), ("right", "Right", "▶")], [("down", "Down", "▼")]] {
						div {
							for (control, label, symbol) in row {
								button(.type(.button), .tabindex(-1), .hook(Hooks.button, value: control)) {
									symbol
								}
								.accessibilityLabel(label)
								.style(GeoCitiesHandheld.Styles.padButton)
							}
						}
						.style(GeoCitiesHandheld.Styles.padRow)
					}
				}
				.style(GeoCitiesHandheld.Styles.pad)

				div {
					button(.type(.button), .tabindex(-1), .hook(Hooks.button, value: "b")) {
						"B"
					}
					.accessibilityLabel("B")
					.style(GeoCitiesHandheld.Styles.roundButton, GeoCitiesHandheld.Styles.buttonB)

					button(.type(.button), .tabindex(-1), .hook(Hooks.button, value: "a")) {
						"A"
					}
					.accessibilityLabel("A")
					.style(GeoCitiesHandheld.Styles.roundButton, GeoCitiesHandheld.Styles.buttonA)
				}
				.style(GeoCitiesHandheld.Styles.ab)
			}
			.style(GeoCitiesHandheld.Styles.controls)

			div {
				button(.type(.button), .tabindex(-1), .hook(Hooks.button, value: "select")) {
					"SELECT"
				}
				.style(GeoCitiesHandheld.Styles.pill)

				button(.type(.button), .tabindex(-1), .hook(Hooks.button, value: "start")) {
					"START"
				}
				.style(GeoCitiesHandheld.Styles.pill)
			}
			.style(GeoCitiesHandheld.Styles.pills)
		}
	}

	/**
	The little printer, light gray, with the paper that comes out of the slot on its top.
	*/
	private struct Printer: HTML {
		var body: some HTML {
			div(.part(Parts.printer)) {
				// The paper rises out of the slot as it prints: the script makes the visible part taller.
				div(.part(Parts.paperHolder)) {
					div(.part(Parts.paperClip)) {
						div {
							canvas(.part(Parts.print), .width(176), .height(176), .role("img")) {}
								.accessibilityLabel("The paper of the printer")
								.style(Styles.printCanvas)
						}
						.style(Styles.paper)
					}
					.style(Styles.paperClip)
				}
				.style(Styles.paperHolder)

				div {
					span {}
						.accessibilityHidden()
						.style(Styles.slot)

					div {
						p {
							"POWER"
						}
						.accessibilityHidden()
						.style(Styles.printerPower)

						span(.part(Parts.printerLight)) {}
							.accessibilityHidden()
							.style(Styles.printerLight)
					}
					.style(Styles.printerTop)

					p {
						"PRINTER"
					}
					.accessibilityHidden()
					.style(Styles.printerBrand)

					p(.part(Parts.paperLeft)) {
						"PAPER ▮▮▮▮▮▮▮▮▮▮"
					}
					.style(GeoCitiesPage.Styles.lcd, Styles.paperLeft)

					PrinterButtons()
				}
				.style(Styles.printer)
			}
			.style(Styles.printerColumn)
		}
	}

	private struct PrinterButtons: HTML {
		private static let papers: [(id: String, name: String)] = [
			("white", "⬜ White"),
			("yellow", "🟨 Yellow Sticker"),
			("blue", "🟦 Blue Sticker"),
		]

		var body: some HTML {
			div {
				for paper in Self.papers {
					button(.type(.button), .hook(Hooks.paperColor, value: paper.id), .ariaPressed(paper.id == "white")) {
						paper.name
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
				}
			}
			.accessibilityLabel("The paper")
			.attributes(.role("group"))
			.style(Styles.printerButtons)

			div {
				button(.part(Parts.tear), .type(.button), .disabled) {
					"✂️ Tear Off"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton, Styles.dimmedWhenDisabled)

				button(.part(Parts.roll), .type(.button)) {
					"🧻 New Roll"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)
			}
			.style(Styles.printerButtons)
		}
	}

	private struct Modes: HTML {
		private static let modes: [(id: String, name: String)] = [
			("shoot", "📷 Shoot"),
			("album", "🖼️ Album"),
			("stamps", "⭐ Stamps"),
			("music", "🎵 Music"),
			("run", "🏃 Race"),
		]

		var body: some HTML {
			div {
				for mode in Self.modes {
					button(.type(.button), .hook(Hooks.mode, value: mode.id), .ariaPressed(false)) {
						mode.name
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
				}
			}
			.accessibilityLabel("The menu of the camera")
			.attributes(.role("group"))
			.style(GeoCitiesPage.Styles.buttonRow)

			div {
				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔈 Sound Off"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

				button(.part(Parts.colors), .type(.button)) {
					"🎨 Colors: Classic Green"
				}
				.help("On the real console, you pick the colors with the D-pad and a button while the logo comes down")
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow, Styles.settings)
		}
	}

	private struct ShootPanel: HTML {
		private static let scenes: [(id: String, name: String)] = [
			("room", "🛏️ My Room"),
			("rocky", "🪨 Rocky"),
			("glitter", "🦄 Glitter"),
			("bryggen", "🌧️ Bryggen"),
		]

		var body: some HTML {
			div(.hook(Hooks.panel, value: "shoot")) {
				// The shutter row is first, as taking a photo is what a visitor wants to do first, also on a phone, where the panel is far below the screen.
				div {
					button(.part(Parts.shutter), .type(.button)) {
						"📸 Shoot (A)"
					}
					.style(GeoCitiesPage.Styles.retroButton, Styles.bigButton)

					button(.part(Parts.turnEye), .type(.button), .ariaPressed(false)) {
						"🔄 Turn the Eye"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

					button(.part(Parts.trick), .type(.button)) {
						"🪞 Trick Lens: Normal"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.timer), .type(.button)) {
						"🎈 Self-Timer"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)

				div {
					button(.part(Parts.webcam), .type(.button), .ariaPressed(false)) {
						"🎥 Use My Webcam"
					}
					.help("Asks for your camera. Nothing leaves your computer.")
					.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)

					for scene in Self.scenes {
						button(.type(.button), .hook(Hooks.scene, value: scene.id), .ariaPressed(scene.id == "room")) {
							scene.name
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
					}
				}
				.accessibilityLabel("What the camera looks at")
				.attributes(.role("group"))
				.style(GeoCitiesPage.Styles.buttonRow)

				div {
					button(.part(Parts.darker), .type(.button)) {
						"🌑 Darker"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.brighter), .type(.button)) {
						"☀️ Brighter"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.lessContrast), .type(.button)) {
						"◐ Less Contrast"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.moreContrast), .type(.button)) {
						"◑ More Contrast"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.panLeft), .type(.button)) {
						"◀ Point Left"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.panRight), .type(.button)) {
						"Point Right ▶"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.hidden(when: true)
			.style(Styles.panel)
		}
	}

	private struct AlbumPanel: HTML {
		var body: some HTML {
			div(.hook(Hooks.panel, value: "album")) {
				p {
					"The album has room for 30 photos, like the real one. Pick a photo to look at it on the game console."
				}
				.style(GeoCitiesPage.Styles.caption, Styles.belowButtons)

				div {
					for index in 0..<30 {
						button(.type(.button), .hook(Hooks.slot, value: "\(index)"), .disabled) {
							canvas(.width(128), .height(112)) {}
								.style(Styles.slotCanvas)
						}
						.accessibilityLabel("Photo \(index + 1), empty")
					}
				}
				.accessibilityLabel("The album")
				.attributes(.role("group"))
				.style(Styles.album, Styles.belowButtons)

				div {
					button(.part(Parts.framePrevious), .type(.button)) {
						"◀ Frame"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.frameNext), .type(.button)) {
						"Frame ▶"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.printButton), .type(.button)) {
						"🖨️ Print"
					}
					.style(GeoCitiesPage.Styles.retroButton, Styles.bigButton)

					button(.part(Parts.toStamps), .type(.button)) {
						"⭐ Stamps"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.png), .type(.button)) {
						"💾 Save as PNG"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.erase), .type(.button)) {
						"🗑️ Erase"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.hidden(when: true)
			.style(Styles.panel)
		}
	}

	private struct StampPanel: HTML {
		private static let stamps: [(id: String, name: String)] = [
			("hat", "🎩 Hat"),
			("mustache", "👨 Mustache"),
			("glasses", "🕶️ Sunglasses"),
			("heart", "❤️ Heart"),
			("star", "⭐ Star"),
			("crown", "👑 Crown"),
			("hei", "💬 “HEI!”"),
		]

		var body: some HTML {
			div(.hook(Hooks.panel, value: "stamps")) {
				p {
					"Tap the photo on the screen to put a stamp on it, or move the stamp with the D-pad and press A. B takes the last one away."
				}
				.style(GeoCitiesPage.Styles.caption, Styles.belowButtons)

				div {
					for stamp in Self.stamps {
						button(.type(.button), .hook(Hooks.stamp, value: stamp.id), .ariaPressed(stamp.id == "hat")) {
							stamp.name
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
					}
				}
				.accessibilityLabel("The stamps")
				.attributes(.role("group"))
				.style(GeoCitiesPage.Styles.buttonRow)

				div {
					button(.part(Parts.undo), .type(.button)) {
						"↩️ Undo"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.stampsDone), .type(.button)) {
						"✅ Done"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.hidden(when: true)
			.style(Styles.panel)
		}
	}

	private struct MusicPanel: HTML {
		var body: some HTML {
			div(.hook(Hooks.panel, value: "music")) {
				p {
					"The music maker of the camera: 16 steps, a melody, a bass, and 3 drums. Tap the grid on the screen, or move with the D-pad and press A."
				}
				.style(GeoCitiesPage.Styles.caption, Styles.belowButtons)

				div {
					button(.part(Parts.musicPlay), .type(.button), .ariaPressed(false)) {
						"▶ Play (Sound!)"
					}
					.style(GeoCitiesPage.Styles.retroButton, Styles.bigButton)

					button(.part(Parts.slower), .type(.button)) {
						"🐢 Slower"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.faster), .type(.button)) {
						"🐇 Faster"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.demo), .type(.button)) {
						"🎵 Demo Song"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.random), .type(.button)) {
						"🌀 Random Song"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)

					button(.part(Parts.clear), .type(.button)) {
						"🧹 Clear"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.hidden(when: true)
			.style(Styles.panel)
		}
	}

	private struct RunPanel: HTML {
		var body: some HTML {
			div(.hook(Hooks.panel, value: "run")) {
				p {
					"A race of 100 meters against Trond. Press A and B, one after the other, as fast as you can! The same button twice makes you stumble. Your last photo is the head of your runner."
				}
				.style(GeoCitiesPage.Styles.caption, Styles.belowButtons)

				div {
					button(.part(Parts.runStart), .type(.button)) {
						"🏁 Start the Race"
					}
					.style(GeoCitiesPage.Styles.retroButton, Styles.bigButton)

					p(.part(Parts.runBest)) {
						"BEST --.-- ★ WINS 0"
					}
					.style(GeoCitiesPage.Styles.lcd, Styles.runBest)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.hidden(when: true)
			.style(Styles.panel)
		}
	}

	private struct Keys: HTML {
		var body: some HTML {
			ul {
				li {
					"🎮 The arrow keys are the D-pad, X or Space is A, Z is B, Enter is Start, and Backspace is Select (click the screen first)."
				}
				li {
					"📷 In Shoot: A takes a photo, ▲ ▼ change the brightness, ◀ ▶ the contrast, Select the trick lens, and Start the self-timer. Drag the screen to point the camera."
				}
				li {
					"🖼️ In View: ◀ ▶ flip the photos, ▲ ▼ pick the frame, A prints, and Select puts on stamps."
				}
			}
			.style(Styles.help)
		}
	}

	/**
	The inside of my wardrobe door, where the printed stickers go.
	*/
	private struct Wardrobe: HTML {
		var body: some HTML {
			section {
				h3 {
					"Inside my wardrobe door (Mamma does not look here)"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					div(.part(Parts.wall)) {
						p(.part(Parts.wallEmpty)) {
							"No stickers yet. Print a photo, and tear it off!"
						}
						.style(Styles.wallEmpty)
					}
					.accessibilityLabel("The stickers inside my wardrobe door")
					.attributes(.role("group"))
					.style(Styles.wall)

					div {
						button(.part(Parts.peel), .type(.button), .disabled) {
							"🩹 Peel Off the Last One I Touched"
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.bigSmallButton, Styles.dimmedWhenDisabled)
					}
					.style(GeoCitiesPage.Styles.buttonRow)

					// The script adds a copy for each sticker that is torn off the printer.
					template(.part(Parts.stickerTemplate)) {
						button(.type(.button), .hook(Hooks.sticker)) {
							canvas(.width(176), .height(176)) {}
								.style(Styles.stickerCanvas)
						}
						.style(Styles.sticker)
					}
				}
				.style(GeoCitiesPage.Styles.windowBody)
			}
			.style(GeoCitiesPage.Styles.window, Styles.toy)
		}
	}

	/**
	How much of the paper is out of the printer, from `0%` to `100%`, which the script sets while it prints.
	*/
	static let paperOut = StyleVariable<Length>("--gb-camera-paper")

	/**
	Where a sticker is inside the wardrobe door, in percent of its width and height, which the script sets while the visitor drags it.
	*/
	static let stickerX = StyleVariable<Length>("--gb-camera-sticker-x")

	static let stickerY = StyleVariable<Length>("--gb-camera-sticker-y")

	enum Parts: String, ElementPartSet {
		case handheld
		case power
		case led
		case eye
		case screen
		case status
		case sound
		case colors
		case webcam
		case shutter
		case turnEye
		case trick
		case timer
		case darker
		case brighter
		case lessContrast
		case moreContrast
		case panLeft
		case panRight
		case framePrevious
		case frameNext
		case printButton
		case toStamps
		case png
		case erase
		case undo
		case stampsDone
		case musicPlay
		case slower
		case faster
		case demo
		case random
		case clear
		case runStart
		case runBest
		case paperHolder
		case paperClip
		case print
		case printer
		case printerLight
		case paperLeft
		case tear
		case roll
		case wall
		case wallEmpty
		case peel
		case stickerTemplate
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button of the game console, like `a` or `left`.
		*/
		case button = "data-gb-camera-button"

		/**
		A mode of the camera, like `shoot` or `music`.
		*/
		case mode = "data-gb-camera-mode"

		/**
		The panel of buttons of a mode, which is shown while the camera is in that mode.
		*/
		case panel = "data-gb-camera-panel"

		/**
		A drawn scene for the camera, like `rocky`.
		*/
		case scene = "data-gb-camera-scene"

		/**
		A stamp, like `mustache`.
		*/
		case stamp = "data-gb-camera-stamp"

		/**
		A paper of the printer, like `yellow`.
		*/
		case paperColor = "data-gb-camera-paper-color"

		/**
		A place in the album, from `0` to `29`.
		*/
		case slot = "data-gb-camera-slot"

		/**
		A sticker inside the wardrobe door, with its number.
		*/
		case sticker = "data-gb-camera-sticker"
	}

	enum Styles: ElementStyleSet {
		case root
		case toy
		case stack
		case body
		case rig
		case console
		case cartridge
		case eyeBall
		case lens
		case cartridgeLabel
		case screen
		case cable
		case printerColumn
		case paperHolder
		case paperClip
		case paper
		case printCanvas
		case printer
		case slot
		case printerTop
		case printerPower
		case printerLight
		case printerBrand
		case paperLeft
		case printerButtons
		case settings
		case toggle
		case bigSmallButton
		case bigButton
		case dimmedWhenDisabled
		case panel
		case belowButtons
		case album
		case slotCanvas
		case runBest
		case status
		case help
		case wall
		case wallEmpty
		case sticker
		case stickerCanvas

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .toy:
				Style()
					.frame(width: .percent(100), maxWidth: .rootEm(46))
					.margin(.horizontal, .auto)
			case .stack:
				Style().vstack(spacing: .rootEm(1))
			case .body:
				// On a phone, the parts of the window are a column that can show them in another order (with `order`), so the buttons of the camera are right under the game console, and the sound and the printer are below them.
				Style().below(.smallTablet) {
					$0.vstack()
				}
			case .rig:
				// The game console and the printer side by side. On a phone, they are parts of the column of the window, so the printer can go below the buttons of the camera.
				Style()
					.hstack(alignment: .end, justification: .center, spacing: .rootEm(0.75))
					.flexWrap()
					.margin(.top, .rootEm(1.5))
					.below(.smallTablet) {
						$0.display(.contents)
					}
			case .console:
				// On a phone, the room above it is for the eye, which sticks out of the top of the cartridge.
				Style()
					.vstack(alignment: .center, spacing: 0)
					.frame(maxWidth: .percent(100))
					.below(.smallTablet) {
						$0.margin(.top, .rootEm(1.5))
					}
			case .cartridge:
				// The blue cartridge of the camera, which sticks out of the top of the game console, with the eye on it.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.125))
					.frame(width: .rootEm(9))
					.margin(.bottom, .rootEm(-0.5))
					.padding(top: .rootEm(0.25), horizontal: .rootEm(0.5), bottom: .rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#4a6fd8"), Color("#2c4aa8")))
					.border(Color("#1c2f70"), width: .pixels(2))
					.cornerRadius(.rootEm(0.5))
			case .eyeBall:
				// The round eye, which turns around on the cartridge.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(3.25), height: .rootEm(3.25))
					.margin(.top, .rootEm(-1.75))
					.backgroundImage(.radialGradient("circle at 35% 30%", Color("#9fb4f0"), Color("#3e5cc0"), Color("#1c2f70")))
					.border(Color("#1c2f70"), width: .pixels(2))
					.cornerRadius(.circle)
					.shadow(Shadow(y: .pixels(3), color: Color("#00000055")))
			case .lens:
				// The lens, black with a glint. When the eye is turned toward me, the lens goes around to the back.
				Style()
					.frame(width: .rootEm(1.5), height: .rootEm(1.5))
					.backgroundImage(.radialGradient("circle at 35% 30%", Color("#8899aa"), Color("#111122"), Color("#000000")))
					.border(Color("#cc2222"), width: .pixels(3))
					.cornerRadius(.circle)
					.media(.allowsMotion) {
						$0.transition(.offset, .opacity, animation: .easeInOut(duration: .milliseconds(400)))
					}
					.when(.state, is: "turned") {
						$0
							.offset(x: .rootEm(1.25))
							.opacity(0)
					}
			case .cartridgeLabel:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.italic()
					.letterSpacing(.em(0.05))
					.color(Color("#e8eeff"))
			case .screen:
				// The screen, in big pixels. A drag to the side points the camera, and a finger that moves up or down still scrolls the page, as the screen is most of the width of a phone.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(160.0 / 144.0)
					.background(Color("#2a2f22"))
					.imageRendering(.pixelated)
					.touchAction(.panY)
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(2), offset: .pixels(2))
					}
			case .cable:
				// The gray link cable between the game console and the printer, only where they are side by side.
				Style()
					.frame(width: .rootEm(1.5), height: .rootEm(0.375))
					.margin(.bottom, .rootEm(6))
					.background(Color("#555555"))
					.cornerRadius(.capsule)
					.hidden(below: .smallTablet)
			case .printerColumn:
				// On a phone, the printer is below the buttons of the camera and the sound (the script scrolls it into view when it prints), so the screen and the buttons of the camera fit on the screen together. It is wider there, so its buttons need fewer rows.
				Style()
					.vstack(alignment: .center, spacing: 0)
					.frame(width: .rootEm(14), maxWidth: .percent(100))
					.below(.smallTablet) {
						$0
							.frame(width: .rootEm(19))
							.alignSelf(.center)
							.margin(.top, .rootEm(0.75))
							.order(2)
					}
			case .paperHolder:
				// The room above the printer for a whole sheet, so the page does not move while the paper comes out. On a phone, where the printer is below the buttons, the room opens only when a print starts (the script scrolls the printer into view then), so no empty gray waits under the buttons before anything is printed.
				Style()
					.vstack(alignment: .center, justification: .end)
					.frame(width: .rootEm(11), maxWidth: .percent(80))
					.aspectRatio(1)
					.below(.smallTablet) {
						$0
							.frame(height: 0)
							.when(.state, is: "open") {
								$0.frame(height: .auto)
							}
					}
			case .paperClip:
				// The part of the paper that is out of the printer. The rest is still inside.
				Style()
					.frame(width: .percent(100), height: GeoCitiesHandheldCamera.paperOut.value(default: .percent(0)))
					.overflow(.hidden)
			case .paper:
				// Thermal paper, or a sticker of the colors of the sticker paper.
				Style()
					.frame(width: .percent(100))
					.aspectRatio(1)
					.shadow(Shadow(x: .pixels(1), y: .pixels(1), color: Color("#00000033")))
			case .printCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(1)
			case .printer:
				// The light gray printer, with the slot for the paper on the top.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.375))
					.frame(width: .percent(100))
					.padding(top: 0, horizontal: .rootEm(0.75), bottom: .rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#d8d8d2"), Color("#b8b8b0")))
					.border(Color("#77776f"), width: .pixels(2))
					.cornerRadius(.rootEm(0.625))
					.shadow(Shadow(x: .pixels(3), y: .pixels(5), color: Color("#00000055")))
			case .slot:
				Style()
					.display(.block)
					.frame(width: .percent(85), height: .rootEm(0.375))
					.background(Color("#33332f"))
					.cornerRadius(.rootEm(0.1875))
			case .printerTop:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.frame(width: .percent(100))
			case .printerPower:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#5a5a55"))
			case .printerLight:
				// The power light, red while the printer is on, and blinking while it prints.
				Style()
					.frame(width: .rootEm(0.625), height: .rootEm(0.625))
					.background(Color("#441111"))
					.cornerRadius(.circle)
					.when(.state, is: "on") {
						$0
							.background(Color("#ff2222"))
							.shadow(Shadow(y: 0, blur: .pixels(6), color: Color("#ff3333")))
					}
					.when(.state, is: "busy") {
						$0
							.background(Color("#ff2222"))
							.shadow(Shadow(y: 0, blur: .pixels(6), color: Color("#ff3333")))
							.media(.allowsMotion) {
								$0.animation(GeoCitiesPage.Animations.blink, .timingCurve("steps(1, end)", duration: .milliseconds(400)).repeatForever(autoreverses: false))
							}
					}
			case .printerBrand:
				Style()
					.margin(0)
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.italic()
					.letterSpacing(.em(0.05))
					.color(Color("#2b2f8a"))
			case .paperLeft:
				Style()
					.margin(0)
					.textStyle(.caption)
			case .printerButtons:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .settings:
				// On a phone, the sound and the colors are below the buttons of the mode, as the visitor changes them less often.
				Style().below(.smallTablet) {
					$0.order(1)
				}
			case .toggle:
				// Big enough for a thumb, and pressed in while it is on.
				Style()
					.frame(minHeight: .rootEm(2.5))
					.when(.state, is: "on") {
						$0
							.background(Color("#ffff99"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .bigSmallButton:
				Style().frame(minHeight: .rootEm(2.5))
			case .bigButton:
				Style().frame(minHeight: .rootEm(2.75))
			case .dimmedWhenDisabled:
				Style().disabled {
					$0.opacity(0.5)
				}
			case .panel:
				Style().vstack(spacing: .rootEm(0.5))
			case .belowButtons:
				// On a phone, the text and the grid of the album are below the buttons of their panel, so the buttons are close to the screen, which shows what they do. The status above says the same as the text.
				Style().below(.smallTablet) {
					$0.order(1)
				}
			case .album:
				// The 30 places of the album, like the grid of small photos on the real camera.
				Style()
					.grid(minimumColumnWidth: .rootEm(3.5))
					.gap(.rootEm(0.25))
					.children("button") {
						$0
							.padding(.pixels(2))
							.background(GeoCitiesPage.windowGray)
							.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
							.handCursor()
							.disabled {
								$0
									.opacity(0.4)
									.cursor(.default)
							}
							.when(.state, is: "selected") {
								$0
									.background(Color("#ffff66"))
									.border(Color("#cc0000"), width: .pixels(2), style: .solid)
							}
					}
			case .slotCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(128.0 / 112.0)
					.imageRendering(.pixelated)
			case .runBest:
				Style()
					.margin(0)
					.textStyle(.caption)
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .help:
				// On a phone, the keys are last, below the printer.
				Style()
					.margin(0)
					.padding(.leading, .rootEm(1))
					.textStyle(.caption)
					.below(.smallTablet) {
						$0.order(3)
					}
			case .wall:
				// The inside of a wooden wardrobe door, with room for the stickers anywhere on it.
				Style()
					.position(.relative)
					.frame(minHeight: .rootEm(18))
					.overflow(.hidden)
					.backgroundImage(.linearGradient("100deg", Color("#c89a63"), Color("#b5844f"), Color("#d2a873"), Color("#b07d48"), Color("#c99c66")))
					.border(Color("#6b4423"), width: .pixels(4), style: .ridge)
			case .wallEmpty:
				Style()
					.margin(0)
					.padding(.rootEm(1))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
					.color(Color("#4a2e14"))
			case .sticker:
				// A sticker, a little crooked, which the visitor drags to a place on the door.
				Style()
					.position(.absolute)
					.leading(GeoCitiesHandheldCamera.stickerX.value(default: .percent(50)))
					.top(GeoCitiesHandheldCamera.stickerY.value(default: .percent(50)))
					.frame(width: .rootEm(6.5))
					.padding(0)
					.background(.white)
					.border(Color("#00000022"), width: .pixels(1))
					.shadow(Shadow(x: .pixels(2), y: .pixels(3), blur: .pixels(2), color: Color("#00000066")))
					.offset(x: .percent(-50), y: .percent(-50))
					.touchAction(.none)
					.cursor(.move)
					.when(.state, is: "left") {
						$0.rotationEffect(.degrees(-6))
					}
					.when(.state, is: "right") {
						$0.rotationEffect(.degrees(5))
					}
					.active {
						$0
							.scaleEffect(1.08)
							.shadow(Shadow(x: .pixels(5), y: .pixels(8), blur: .pixels(4), color: Color("#00000066")))
					}
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(3), offset: .pixels(2))
					}
			case .stickerCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(1)
					.allowsHitTesting(false)
			}
		}
	}
}
