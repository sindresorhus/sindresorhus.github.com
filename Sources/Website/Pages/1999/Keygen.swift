import Elementary
import Foundation
import SiteKit

/**
The warez corner of the page, as a joke: the page is shareware, with a nag window that wants a serial number, and next to it the keygen of TEAM WAFFLE, which makes the serial for any name, with a sine scroller, a rainbow border, and keygen music. The serial from the keygen registers the page, which its script, `Keygen.js`, keeps in the browser, and the scroller of the cracktro thanks the visitor for it. Below them is the NFO file of the release, which types itself at the speed of a modem, and which the visitor can open in Notepad, where the ANSI art turns to garbage like on Windows 98.
*/
struct GeoCitiesKeygen: ScriptedElement {
	static let script = ElementScript()

	/**
	The NFO file of the release, in the characters of code page 437, like in a DOS window.
	*/
	static let nfo = """
	 ████████ ██     ██ ████████
	 ▀▀▀██▀▀▀ ██     ██ ██▀▀▀▀▀▀
	    ██    ██  ▄  ██ ██████
	    ██    ██ ███ ██ ██▀▀▀▀
	    ██     ███▀███  ██
	 ░▒▓█  T E A M   W A F F L E  █▓▒░

	╔════════════════════════════════════╗
	║ Sindre’s Home Page v1999 *CRACKED* ║
	╚════════════════════════════════════╝

	 Release date ..: 12/31/1999
	 Protection ....: None (a home page)
	 Cracked by ....: Sindre
	 Supplier ......: Mamma
	 Size ..........: 1 floppy (1.44 MB)
	 Format ........: HTML, GIF, MIDI

	──────────────────────────────────────
	 RELEASE NOTES

	 This is the full version of Sindre’s
	 Home Page. The trial stops working on
	 01/01/2000 because of the Y2K bug.
	 Run the keygen, type your name, and
	 enjoy unlimited waffles.

	──────────────────────────────────────
	 TEAM WAFFLE IS

	 Sindre ......: code, graphics, music
	 Trond .......: moral support, snacks
	 Glitter .....: mascot (a unicorn)

	──────────────────────────────────────
	 GREETINGS TO

	 Mamma · Mormor · Glitter · Trond
	 Spaceballs · Future Crew · Razor 1911
	 and all elite web masters

	──────────────────────────────────────
	 WE ARE LOOKING FOR

	 A 28.8k modem that does not hang up
	 when Mamma picks up the phone.

	──────────────────────────────────────
	    ░▒▓█ TWF · 1999 · NORWAY █▓▒░
	"""

	var content: some HTML {
		h2 {
			"Register My Home Page!"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"My home page is shareware now. Registering is free, but you need a serial number. Luckily, TEAM WAFFLE made a keygen."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			nagWindow
			keygen
		}
		.style(Styles.layout, GeoCitiesPage.Styles.scriptingOnly)

		nfoWindow

		p {
			"The keygen needs JavaScript. So does the registration. This copy stays unregistered."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The nag window of the shareware, which counts the days of the trial and takes the name and the serial.
	*/
	private var nagWindow: some HTML {
		div(.part(Parts.nag)) {
			p(.part(Parts.nagTitle)) {
				"Sindre’s Home Page 1999: UNREGISTERED"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				div(.part(Parts.unregistered)) {
					p(.part(Parts.trial)) {
						"This is day 1 of your 30-day free trial."
					}
					.style(Styles.nagTitle)

					p(.part(Parts.nagMessage)) {
						"Please register to remove this message and support a kid in Norway."
					}

					form(.part(Parts.nagForm)) {
						label(.for("geocities-nag-name")) {
							"Name:"
						}
						.style(GeoCitiesPage.Styles.label)

						input(.id("geocities-nag-name"), .part(Parts.nagName), .type(.text), .autocomplete("off"), .maxlength(24), .required)
							.style(GeoCitiesPage.Styles.field)

						label(.for("geocities-nag-serial")) {
							"Serial number:"
						}
						.style(GeoCitiesPage.Styles.label)

						input(.id("geocities-nag-serial"), .part(Parts.nagSerial), .type(.text), .autocomplete("off"), .maxlength(24), .required, .custom(name: "spellcheck", value: "false"), .placeholder("TWF-0000-0000-0000"))
							.style(GeoCitiesPage.Styles.field, Styles.serial)

						div {
							button(.type(.submit)) {
								"Register"
							}
							.style(GeoCitiesPage.Styles.retroButton)

							button(.part(Parts.later), .type(.button)) {
								"Remind Me Later"
							}
							.style(GeoCitiesPage.Styles.retroButton)
						}
						.style(Styles.buttons)
					}
					.style(Styles.form)
				}

				div(.part(Parts.registered), .hidden) {
					p {
						"★ REGISTERED ★"
					}
					.style(Styles.nagTitle)

					p {
						"This copy is registered to "
						strong(.part(Parts.registeredName)) {}
						". Thank you for your support! Your free waffle is in the mail."
					}

					button(.part(Parts.unregister), .type(.button)) {
						"Unregister"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}

				p(.part(Parts.nagStatus), .role("status")) {}
					.style(Styles.status)
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window, Styles.nag)
	}

	/**
	The keygen: a black window with a rainbow border, a logo, a scroller, the name, and the serial.
	*/
	private var keygen: some HTML {
		div {
			// The border is behind the keygen, so turning its colors does not turn the colors of the keygen.
			div {}
				.accessibilityHidden()
				.style(Styles.rainbowBorder)

			div {
				p {
					span {
						"SINDRE.EXE keygen by TEAM WAFFLE"
					}

					span {
						"[TWF]"
					}
					.accessibilityHidden()
				}
				.style(Styles.keygenTitle)

				pre {
					"░▒▓██ TEAM WAFFLE ██▓▒░"
				}
				.accessibilityHidden()
				.style(Styles.keygenLogo)

				canvas(.part(Parts.scroller), .width(240), .height(24)) {}
					.accessibilityHidden()
					.style(Styles.scroller)

				form(.part(Parts.form)) {
					label(.for("geocities-keygen-name")) {
						"Name:"
					}
					.style(Styles.keygenLabel)

					input(.id("geocities-keygen-name"), .part(Parts.name), .type(.text), .autocomplete("off"), .maxlength(24), .required, .value("Sindre"))
						.style(Styles.keygenField)

					label(.for("geocities-keygen-serial")) {
						"Serial:"
					}
					.style(Styles.keygenLabel)

					input(.id("geocities-keygen-serial"), .part(Parts.serial), .type(.text), .readonly, .value("Press Generate"))
						.style(Styles.keygenField, Styles.serial)

					div {
						button(.type(.submit)) {
							"Generate"
						}
						.style(Styles.keygenButton)

						button(.part(Parts.copy), .type(.button)) {
							"Copy"
						}
						.style(Styles.keygenButton)

						button(.part(Parts.music), .type(.button)) {
							"♪ Music"
						}
						.style(Styles.keygenButton)
					}
					.style(Styles.buttons)
				}
				.style(Styles.form)

				p(.part(Parts.status), .role("status")) {}
					.style(Styles.status)
			}
			.style(Styles.keygen)
		}
		.style(Styles.rainbow)
	}

	/**
	The NFO file in a window, with the speed of the modem and the program that opens it.
	*/
	private var nfoWindow: some HTML {
		div {
			p(.part(Parts.nfoTitle)) {
				"TWF-SINDRE.NFO: DOS Prompt"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				div {
					span {
						"Download it at:"
					}

					for (speed, title) in [("300", "300 baud"), ("2400", "2400 baud"), ("14400", "14.4k"), ("57600", "56k")] {
						button(.type(.button), .hook(Hooks.speed, value: speed)) {
							title
						}
						.style(GeoCitiesPage.Styles.retroButton, Styles.small)
					}

					button(.part(Parts.notepad), .type(.button)) {
						"Open in Notepad"
					}
					.style(GeoCitiesPage.Styles.retroButton, Styles.small)
				}
				.style(Styles.buttons, GeoCitiesPage.Styles.scriptingOnly)

				pre(.part(Parts.nfo), .tabindex(0)) {
					Self.nfo
				}
				.accessibilityLabel("The NFO file of TEAM WAFFLE")
				.style(Styles.nfo)
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window, Styles.nfoWindow)
	}

	enum Parts: String, ElementPartSet {
		case nag
		case nagTitle
		case unregistered
		case trial
		case nagMessage
		case nagForm
		case nagName
		case nagSerial
		case later
		case registered
		case registeredName
		case unregister
		case nagStatus
		case scroller
		case form
		case name
		case serial
		case copy
		case music
		case status
		case nfoTitle
		case nfo
		case notepad
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The speed of the modem that types the NFO file, in bits a second.
		*/
		case speed = "data-nfo-speed"
	}

	enum Styles: ElementStyleSet {
		case root
		case layout
		case nag
		case nagTitle
		case form
		case serial
		case buttons
		case status
		case rainbow
		case rainbowBorder
		case keygen
		case keygenTitle
		case keygenLogo
		case scroller
		case keygenLabel
		case keygenField
		case keygenButton
		case nfoWindow
		case nfo
		case small

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .layout:
				Style()
					.grid(minimumColumnWidth: .rootEm(17))
					.gap(.rootEm(1.25))
					.alignItems(.start)
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .nag:
				// It shakes when the serial is wrong.
				Style()
					.frame(minWidth: 0)
					.media(.allowsMotion) {
						$0.when(.state, is: "wrong") {
							$0.animation(Animations.shake, .linear(duration: .milliseconds(400)))
						}
					}
			case .nagTitle:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.fontWeight(.bold)
					.color(Color("#800000"))
			case .form:
				Style().vstack(spacing: .rootEm(0.375))
			case .serial:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.letterSpacing(.em(0.05))
			case .buttons:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .status:
				Style()
					.frame(minHeight: .lineHeight(1))
					.fontWeight(.bold)
			case .rainbow:
				Style()
					.display(.grid)
					.frame(minWidth: 0)
			case .rainbowBorder:
				// The border of the keygen goes around the colors of the rainbow.
				Style()
					.stackedInGrid()
					.backgroundImage(.linearGradient("135deg", Color("#ff0000"), Color("#ffcc00"), Color("#33ff00"), Color("#00ccff"), Color("#6600ff"), Color("#ff00cc")))
					.cornerRadius(.rootEm(0.5))
					.media(.allowsMotion) {
						$0.animation(Animations.rainbow, .linear(duration: .seconds(3)).repeatForever(autoreverses: false))
					}
			case .keygen:
				// Positioned, so it is drawn over the border, which its filter puts in a layer of its own.
				Style()
					.stackedInGrid()
					.position(.relative)
					.margin(.pixels(5))
					.frame(minWidth: 0)
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#0b0b1a"))
					.cornerRadius(.rootEm(0.25))
					.fontFamily(GeoCitiesPage.courier)
					.color(Color("#c8c8ff"))
			case .keygenTitle:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.flexWrap()
					.fontWeight(.bold)
					.color(Color("#ffcc00"))
			case .keygenLogo:
				Style()
					.margin(0)
					.overflow(horizontal: .auto)
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.textAlign(.center)
					.color(Color("#ff66cc"))
			case .scroller:
				Style()
					.display(.block)
					.frame(width: .percent(100))
					.imageRendering(.pixelated)
					.background(.black)
			case .keygenLabel:
				Style()
					.fontWeight(.bold)
					.color(Color("#33ff66"))
			case .keygenField:
				Style()
					.frame(width: .percent(100))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.375))
					.background(.black)
					.border(Color("#6666cc"), width: .pixels(2))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body)
					.color(Color("#33ff66"))
			case .keygenButton:
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.75))
					.background(Color("#1a1a4a"))
					.border(Color("#6666cc"), width: .pixels(2), style: .outset)
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(Color("#ffcc00"))
					.handCursor()
					.active {
						$0.border(Color("#6666cc"), width: .pixels(2), style: .inset)
					}
			case .nfoWindow:
				Style().margin(.top, .rootEm(1.25))
			case .nfo:
				// Light gray on black, like a DOS window. The lines are at most 40 characters, so they fit on a phone.
				Style()
					.margin(0)
					.frame(minHeight: .rootEm(12))
					.padding(.rootEm(0.75))
					.overflow(horizontal: .auto)
					.background(.black)
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .clamp(.pixels(10), .viewportWidth(2.6), .pixels(15)), lineHeight: 1.15)
					.color(Color("#c0c0c0"))
					// Black on white in Notepad.
					.when(.state, is: "notepad") {
						$0
							.background(.white)
							.color(.black)
					}
			case .small:
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.textStyle(.caption, weight: .bold)
			}
		}
	}

	enum Animations: KeyframeSet {
		case rainbow
		case shake

		var keyframes: [Keyframe] {
			switch self {
			case .rainbow:
				[.from(Style().filter(.hueRotation(.degrees(0)))), .to(Style().filter(.hueRotation(.degrees(360))))]
			case .shake:
				// Four shakes from side to side.
				[12.5, 37.5, 62.5, 87.5].enumerated().map { index, percentage in
					.at(percentage, Style().offset(x: .pixels(index.isMultiple(of: 2) ? -6 : 6)))
				}
			}
		}
	}
}
