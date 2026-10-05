import Elementary
import Foundation
import SiteKit

/**
My room in 1999, as a QuickTime VR panorama: the visitor holds the mouse down and moves it to turn around in the room, like in the QuickTime VR movies of the time, and clicks the things in it. The iMac in Bondi Blue, the bunk bed with the unicorn, the window with the rain of Bergen, the LEGO shelf, the light switch, and the rest each do something, or lead to the toys of my room further down the page. Next to it is a Polaroid camera that takes a picture of what the panorama shows, and a cork board with the pictures, which develop slowly. Its script, `Room.js`, draws the room and runs it.
*/
struct GeoCitiesRoom: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the element, which the links to my room on the page lead to.
	*/
	static let rootID = "geocities-room"

	/**
	The ID of the Polaroid camera, which the camera on the desk in the room leads to.
	*/
	static let cameraID = "geocities-polaroid"

	let project: Project

	/**
	The things in the room that the visitor can click, by the name that the script knows them by, with the section further down that they lead to, if any.
	*/
	static let hotspots: [(id: String, name: String, target: String?)] = [
		("imac", "My iMac", nil),
		("poster", "Unicorn poster", nil),
		("lava", "Lava lamp", nil),
		("music", "Discman and Walkman", GeoCitiesMusic.rootID),
		("polaroid", "Polaroid camera", cameraID),
		("raincoat", "Rain gear", GeoCitiesNorwayDays.weatherID),
		("window", "Window", nil),
		("plush", "Unicorn plush", nil),
		("handheld", "Handheld game console", GeoCitiesHandheld.rootID),
		("bed", "Under the bed", GeoCitiesRoomToys.underBedID),
		("stars", "Glow stars", GeoCitiesRoomToys.ceilingID),
		("door", "Door", nil),
		("lights", "Light switch", nil),
		("lego", "LEGO shelf", GeoCitiesLego.rootID),
		("skis", "Skis", GeoCitiesNorwayHolidays.skiID),
		("calendar", "Calendar", nil),
		("backpack", "School bag", GeoCitiesNorwayDays.lunchID),
		("bucket", "Crab bucket", GeoCitiesNorwayDays.crabsID),
	]

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id(Self.rootID)]
	}

	var content: some HTML {
		h2(.tabindex(-1)) {
			GeoCitiesPage.GIFImage(gif: .computerSmall, alt: "", style: .gif, project: project)
			" My Room in QuickTime VR "
			GeoCitiesPage.GIFImage(gif: .buttonQuickTime, alt: "Made with QuickTime", style: .gif, project: project)
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Welcome to my room! Hold the mouse down and move it to look around, like in a real QuickTime VR movie. Click on things. Do not touch my LEGO."
		}
		.style(GeoCitiesPage.Styles.centeredText, GeoCitiesPage.Styles.scriptingOnly)

		div {
			p {
				"Sindre’s Room.mov"
			}
			.accessibilityHidden()
			.style(Styles.playerTitle)

			div {
				// The room is drawn at 480 × 270 pixels, in big pixels, like a QuickTime VR movie of 1999 that was made for a 14-inch monitor.
				canvas(.part(Parts.view), .width(480), .height(270), .tabindex(0), .role("application")) {}
					.accessibilityLabel("My room. Use the arrow keys to look around, plus and minus to zoom, and the buttons below to look at things.")
					.style(Styles.view)

				// The flash of the Polaroid camera.
				div(.part(Parts.flash)) {}
					.style(Styles.flash)
			}
			.style(Styles.viewFrame)

			div {
				button(.type(.button), .hook(Hooks.action, value: "zoom-out")) {
					"−"
				}
				.accessibilityLabel("Zoom out")
				.style(Styles.controllerButton)

				button(.type(.button), .hook(Hooks.action, value: "zoom-in")) {
					"+"
				}
				.accessibilityLabel("Zoom in")
				.style(Styles.controllerButton)

				button(.type(.button), .hook(Hooks.action, value: "hotspots"), .ariaPressed(false)) {
					"?"
				}
				.accessibilityLabel("Show the hot spots")
				.style(Styles.controllerButton)

				p(.part(Parts.status), .role("status")) {
					"Drag to look around."
				}
				.style(Styles.label)
			}
			.style(Styles.controller)
		}
		.style(Styles.player, GeoCitiesPage.Styles.scriptingOnly)

		div {
			h3 {
				"Look at:"
			}
			.style(Styles.lookTitle)

			ul {
				for hotspot in Self.hotspots {
					li {
						button(.type(.button), .hook(Hooks.hotspot, value: hotspot.id)) {
							hotspot.name
						}
						.attributes(.hook(Hooks.target, value: hotspot.target ?? ""), when: hotspot.target != nil)
						.style(GeoCitiesPage.Styles.smallButton)
					}
				}
			}
			.accessibilityLabel("Things in my room")
			.style(Styles.lookList)
		}
		.style(GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My room needs JavaScript and QuickTime 3. It is a mess anyway, so do not come in."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)

		camera
	}

	/**
	The Polaroid camera, which takes a picture of what the panorama shows, and the cork board with the pictures.
	*/
	private var camera: some HTML {
		div(.id(Self.cameraID), .tabindex(-1)) {
			div {
				div {
					div {}
						.style(Styles.cameraLens)

					div {
						span {
							"Film: "
						}
						span(.part(Parts.film)) {
							"10"
						}
					}
					.style(Styles.cameraCounter)
				}
				.style(Styles.cameraFront)

				div {}
					.accessibilityHidden()
					.style(Styles.cameraStripe)

				div {
					button(.part(Parts.shutter), .type(.button)) {}
						.accessibilityLabel("Take a picture of my room")
						.style(Styles.shutter)

					button(.part(Parts.newFilm), .type(.button), .hidden) {
						"Buy a New Film Pack"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(Styles.cameraButtons)
			}
			.style(Styles.camera)

			div {
				p {
					"Point the panorama at something and press the red button. Polaroid 600 film takes a while to develop. Shaking it does not help."
				}
				.style(GeoCitiesPage.Styles.caption)

				p(.part(Parts.cameraStatus), .role("status")) {}
					.style(Styles.label)
			}

			ul(.part(Parts.photos)) {}
				.accessibilityLabel("My cork board")
				.style(Styles.cork)

			// The script adds a copy for each picture on the cork board.
			template(.part(Parts.photoTemplate)) {
				li {
					div {
						canvas(.width(160), .height(160)) {}
							.style(Styles.photoPicture)

						input(.type(.text), .maxlength(30), .autocomplete("off"), .placeholder("Write on it"))
							.accessibilityLabel("Write on the picture")
							.style(Styles.photoCaption)
					}
					.style(Styles.photo)

					button(.type(.button)) {
						"Take Down"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(Styles.photoItem)
			}
		}
		.style(Styles.cameraArea, GeoCitiesPage.Styles.scriptingOnly)
	}

	enum Parts: String, ElementPartSet {
		case view
		case flash
		case status
		case film
		case shutter
		case newFilm
		case cameraStatus
		case photos
		case photoTemplate
	}

	enum Hooks: String, ScriptHookSet {
		/**
		What a button of the QuickTime controller does, like `zoom-in`.
		*/
		case action = "data-room-action"

		/**
		The thing in the room that a button looks at.
		*/
		case hotspot = "data-room-hotspot"

		/**
		The ID of the section further down that a thing in the room leads to.
		*/
		case target = "data-room-target"
	}

	enum Styles: ElementStyleSet {
		case root
		case player
		case playerTitle
		case viewFrame
		case view
		case flash
		case controller
		case controllerButton
		case label
		case lookTitle
		case lookList
		case cameraArea
		case camera
		case cameraFront
		case cameraLens
		case cameraCounter
		case cameraStripe
		case cameraButtons
		case shutter
		case cork
		case photoItem
		case photo
		case photoPicture
		case photoCaption

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .player:
				// A window of Mac OS 8, in the gray of the Platinum look, with the controller of QuickTime VR at the bottom.
				Style()
					.frame(maxWidth: .pixels(720))
					.margin(.horizontal, .auto)
					.background(Color("#dddddd"))
					.border(Color("#666666"), width: .pixels(1))
					.shadow(Shadow(x: .pixels(3), y: .pixels(3), color: Color("#00000080")))
					.color(.black)
			case .playerTitle:
				// The title bar of Mac OS 8, with its fine lines.
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.backgroundImage(.linearGradient("to bottom", Color("#eeeeee"), Color("#bbbbbb"), Color("#eeeeee"), Color("#bbbbbb"), Color("#eeeeee"), Color("#bbbbbb"), Color("#eeeeee")))
					.border(.bottom, Color("#888888"), width: .pixels(1))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .viewFrame:
				Style()
					.position(.relative)
					.background(.black)
			case .view:
				// Big pixels, and a finger turns the room instead of scrolling the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(480.0 / 270.0)
					.imageRendering(.pixelated)
					.touchAction(.none)
					.cursor(.move)
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(3), offset: .pixels(-3))
					}
					.when(.state, is: "hotspot") {
						$0.cursor(.pointer)
					}
			case .flash:
				// It shows for a moment when the Polaroid camera takes a picture, and never for visitors who prefer reduced motion.
				Style()
					.position(.absolute)
					.inset(0)
					.background(.white)
					.opacity(0)
					.allowsHitTesting(false)
					.when(.state, is: "flash") {
						$0
							.opacity(1)
							.media(.allowsMotion) {
								$0.animation(Animations.flash, .easeOut(duration: .milliseconds(600)), fillMode: .forwards)
							}
							.reducedMotion {
								$0.opacity(0)
							}
					}
			case .controller:
				// The controller of QuickTime VR: the buttons on the left, and the name of the hot spot under the pointer.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.padding(.rootEm(0.25))
					.backgroundImage(.linearGradient("to bottom", Color("#eeeeee"), Color("#bbbbbb")))
					.border(.top, Color("#888888"), width: .pixels(1))
			case .controllerButton:
				Style()
					.frame(minWidth: .rootEm(2), minHeight: .rootEm(1.75))
					.background(Color("#dddddd"))
					.border(Color("#777777"), width: .pixels(1))
					.cornerRadius(.pixels(3))
					.shadow(Shadow(x: .pixels(1), y: .pixels(1), color: .white, isInset: true))
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(.black)
					.handCursor()
					.active {
						$0.background(Color("#999999"))
					}
					.when(.state, is: "on") {
						$0.background(Color("#9999ff"))
					}
			case .label:
				Style()
					.flex(1)
					.margin(0)
					.padding(.horizontal, .rootEm(0.375))
					.fontFamily(.system)
					.textStyle(.caption)
			case .lookTitle:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
					.textAlign(.center)
			case .lookList:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
					.flexWrap()
					.margin(top: .rootEm(0.375))
					.padding(0)
			case .cameraArea:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.margin(top: .rootEm(1.5))
					.textAlign(.center)
			case .camera:
				// A Polaroid 600 camera: a black box with the rainbow stripe, the lens, and the red button.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(width: .rootEm(14), maxWidth: .percent(100))
					.padding(.rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#3a3a3a"), Color("#111111")))
					.cornerRadius(.rootEm(0.75))
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000080")))
					.color(.white)
			case .cameraFront:
				Style().hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
			case .cameraLens:
				Style()
					.frame(width: .rootEm(4), height: .rootEm(4))
					.backgroundImage(.radialGradient("circle at 40% 35%", Color("#8899cc"), Color("#223355"), Color("#000000")))
					.border(Color("#777777"), width: .pixels(5))
					.cornerRadius(.circle)
			case .cameraCounter:
				// The film counter, which counts down from 10, like the counter of a Polaroid 600.
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.background(Color("#330000"))
					.border(Color("#555555"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#ff5533"))
			case .cameraStripe:
				// The rainbow stripe of Polaroid.
				Style()
					.frame(height: .rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#e8313a"), Color("#f7941d"), Color("#ffde17"), Color("#3ab54a"), Color("#1b75bc")))
			case .cameraButtons:
				Style().hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
			case .shutter:
				Style()
					.frame(width: .rootEm(2.75), height: .rootEm(2.75))
					.backgroundImage(.radialGradient("circle at 35% 30%", Color("#ff8877"), Color("#dd1100"), Color("#881100")))
					.border(Color("#222222"), width: .pixels(3))
					.cornerRadius(.circle)
					.handCursor()
					.active {
						$0.offset(y: .pixels(2))
					}
					.disabled {
						$0.opacity(0.5)
					}
			case .cork:
				// A cork board with the pictures pinned on it, side by side where there is room.
				Style()
					.hstack(alignment: .start, justification: .center, spacing: .rootEm(1))
					.flexWrap()
					.frame(width: .percent(100), minHeight: .rootEm(6))
					.margin(0)
					.padding(.rootEm(1))
					.background(Color("#c49a6c"))
					.backgroundImage(.radialGradient("circle at 30% 40%", Color("#d8b48a"), Color("#b5895a"), Color("#a07447")))
					.border(Color("#7a4f24"), width: .pixels(8), style: .ridge)
			case .photoItem:
				Style().vstack(alignment: .center, spacing: .rootEm(0.25))
			case .photo:
				// A Polaroid picture, with the wide white edge at the bottom to write on, a little crooked on the board.
				Style()
					.vstack(spacing: .rootEm(0.25))
					.frame(width: .rootEm(8.5))
					.padding(top: .rootEm(0.5), horizontal: .rootEm(0.5), bottom: .rootEm(0.25))
					.background(Color("#fbfbf5"))
					.shadow(Shadow(x: .pixels(2), y: .pixels(3), color: Color("#00000066")))
					.rotationEffect(.degrees(-2))
					.when(.state, is: "right") {
						$0.rotationEffect(.degrees(3))
					}
			case .photoPicture:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(1)
					.background(Color("#1d2b2e"))
			case .photoCaption:
				// Handwriting with a black marker on the white edge.
				Style()
					.frame(width: .percent(100))
					.padding(.pixels(2))
					.background(.transparent)
					.border(.transparent, width: 0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
					.textAlign(.center)
					.color(Color("#1a1a66"))
			}
		}
	}

	enum Animations: KeyframeSet {
		case flash

		var keyframes: [Keyframe] {
			switch self {
			case .flash:
				[
					.from(Style().opacity(1)),
					.to(Style().opacity(0)),
				]
			}
		}
	}
}
