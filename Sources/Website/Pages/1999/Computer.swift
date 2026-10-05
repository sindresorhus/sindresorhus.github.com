import Elementary
import Foundation
import SiteKit

/**
The front of my beige PC: the CD-ROM drive, which opens into a cup holder, the lights for the power and the hard drive, which flickers whenever the visitor clicks or types, the display of the speed in MHz, the Turbo button, and the Reset button, which restarts the page with the screen of the BIOS. On real PCs of the time, the Turbo button made the computer slower, for old games. Mine makes everything that moves on the page faster: its script, `Computer.js`, speeds up the animations of the page, but not the GIFs, which play at their own speed.
*/
struct GeoCitiesComputer: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	var content: some HTML {
		h2 {
			"My Computer: the Sindre 2000 Turbo"
		}
		.style(GeoCitiesPage.Styles.titleBar)

		div {
			div {
				// The CD-ROM drive, with its tray, which slides out with a cup on it.
				div(.part(Parts.drive)) {
					span {
						"CD-ROM 32×"
					}
					.style(Styles.label)

					button(.part(Parts.eject), .type(.button), .ariaPressed(false)) {
						"⏏"
					}
					.accessibilityLabel("Open the CD-ROM tray")
					.style(Styles.smallButton, GeoCitiesPage.Styles.scriptingOnly)

					div {
						GeoCitiesPage.GIFImage(gif: .javaCup, alt: "A cup of coffee on the tray", style: .gif, project: project)
					}
					.style(Styles.tray)
				}
				.style(Styles.drive)

				div {
					span {
						"3½″ floppy"
					}
					.style(Styles.label)
				}
				.style(Styles.drive)

				div {
					p {
						"SINDRE 2000"
					}
					.style(Styles.badge)

					div {
						span {
							span {}
								.style(Styles.light, Styles.powerLight)
							"Power"
						}
						.style(Styles.lightLabel)

						span {
							span(.part(Parts.hardDriveLight)) {}
								.style(Styles.light, Styles.hardDriveLight)
							"HDD"
						}
						.style(Styles.lightLabel)

						span {
							span(.part(Parts.turboLight)) {}
								.style(Styles.light, Styles.turboLight)
							"Turbo"
						}
						.style(Styles.lightLabel)
					}
					.style(Styles.lights)

					p {
						span(.part(Parts.speed)) {
							"66"
						}
						" MHz"
					}
					.style(Styles.display)

					div {
						button(.part(Parts.turbo), .type(.button), .ariaPressed(false)) {
							"TURBO"
						}
						.style(Styles.caseButton)

						button(.part(Parts.reset), .type(.button)) {
							"RESET"
						}
						.style(Styles.caseButton)
					}
					.style(Styles.caseButtons, GeoCitiesPage.Styles.scriptingOnly)
				}
				.style(Styles.front)
			}
			.style(Styles.computerCase)

			p(.part(Parts.status), .role("status")) {}
				.style(GeoCitiesPage.Styles.centeredText)

			p {
				span {
					GeoCitiesPage.GIFImage(gif: .computerSmash, alt: "A man fixing his computer with a hammer", style: .gif, project: project)
				}
				.style(GeoCitiesPage.Styles.floating, Styles.smash)
				"Fun fact: on real PCs, the Turbo button made the computer "
				em {
					"slower"
				}
				", so old games did not run too fast. Mine is fixed: it makes everything on this page faster. When it still crashes, I fix it like the man in the picture."
			}
			.style(GeoCitiesPage.Styles.caption)

			p {
				"The buttons need JavaScript, so the computer is off."
			}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
		}
		.style(GeoCitiesPage.Styles.windowBody)

		// The screen of the BIOS while the computer restarts. The script moves it to the end of the page, as it covers the whole window, writes the lines one after the other, and any key or click skips to the end.
		div(.part(Parts.bios), .role("dialog"), .ariaModal, .tabindex(-1), .hidden) {
			p(.part(Parts.biosText)) {}
		}
		.accessibilityLabel("The computer restarts")
		.style(Styles.bios)
	}

	enum Parts: String, ElementPartSet {
		case drive
		case eject
		case hardDriveLight
		case turboLight
		case speed
		case turbo
		case reset
		case status
		case bios
		case biosText
	}

	enum Styles: ElementStyleSet {
		case root
		case computerCase
		case drive
		case label
		case smallButton
		case tray
		case front
		case badge
		case lights
		case lightLabel
		case light
		case powerLight
		case hardDriveLight
		case turboLight
		case display
		case caseButtons
		case caseButton
		case smash
		case bios

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.window.style.display(.block)
			case .computerCase:
				// The beige plastic of the PCs of the 1990s, yellowed a little by the sun.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#f0e9d2"), Color("#d9cfb0")))
					.border(Color("#f6f0dc"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(0.375))
					.fontFamily(.system)
					.color(Color("#333333"))
			case .drive:
				// A bay of the case, with the slot of the drive.
				Style()
					.position(.relative)
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.frame(minHeight: .rootEm(2.25))
					.backgroundImage(.linearGradient("to bottom", Color("#e2d9bc"), Color("#cbc09e")))
					.border(Color("#a89c78"), width: .pixels(2), style: .inset)
					// The tray is out while the drive is open.
					.when(.state, is: "open") {
						$0.children("div") {
							$0
								.visibility(true)
								.opacity(1)
								.offset(y: 0)
						}
					}
			case .label:
				Style()
					.textStyle(.caption, weight: .bold)
					.letterSpacing(.em(0.05))
			case .smallButton:
				Style()
					.padding(vertical: 0, horizontal: .rootEm(0.5))
					.background(Color("#d6cba8"))
					.border(Color("#efe6c8"), width: .pixels(2), style: .outset)
					.textStyle(.body, weight: .bold)
					.color(Color("#333333"))
					.handCursor()
					.active {
						$0.border(Color("#efe6c8"), width: .pixels(2), style: .inset)
					}
			case .tray:
				// The tray, which is inside the drive until it opens and slides down out of it.
				Style()
					.position(.absolute)
					.top(.percent(100))
					.leading(.rootEm(2))
					.zIndex(1)
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(7), height: .rootEm(3.5))
					.background(Color("#2a2a2a"))
					.border(Color("#555555"), width: .pixels(2), style: .outset)
					.cornerRadius(.rootEm(0.25))
					.visibility(false)
					.opacity(0)
					.offset(y: .rootEm(-1.5))
					.children("picture > img") {
						$0.frame(width: .auto, height: .rootEm(3))
					}
					.media(.allowsMotion) {
						$0.transition(.offset, .opacity, .visibility, animation: .easeOut(duration: .milliseconds(400)))
					}
			case .front:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.5))
					.alignItems(.center)
					.padding(.top, .rootEm(0.25))
			case .badge:
				// A silver badge with the name of the model.
				Style()
					.justifySelf(.start)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.backgroundImage(.linearGradient("to bottom", Color("#ffffff"), Color("#9aa0aa"), Color("#e4e6ea")))
					.border(Color("#777777"), width: .pixels(1))
					.fontFamily(GeoCitiesPage.impact)
					.letterSpacing(.em(0.1))
					.color(Color("#203060"))
			case .lights:
				Style()
					.hstack(alignment: .center, justification: .end, spacing: .rootEm(0.75))
					.flexWrap()
			case .lightLabel:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.textStyle(.caption)
			case .light:
				// A small round light, dark while it is off.
				Style()
					.display(.inlineBlock)
					.frame(width: .rootEm(0.625), height: .rootEm(0.625))
					.cornerRadius(.percent(50))
					.background(Color("#4a4a3a"))
					.border(Color("#777766"), width: .pixels(1))
			case .powerLight:
				Style()
					.background(Color("#33ff33"))
					.shadow(Shadow(y: 0, blur: .pixels(6), color: Color("#33ff33")))
			case .hardDriveLight:
				Style().when(.state, is: "on") {
					$0
						.background(Color("#ffaa00"))
						.shadow(Shadow(y: 0, blur: .pixels(6), color: Color("#ffaa00")))
				}
			case .turboLight:
				Style().when(.state, is: "on") {
					$0
						.background(Color("#ffff33"))
						.shadow(Shadow(y: 0, blur: .pixels(6), color: Color("#ffff33")))
				}
			case .display:
				// The red seven-segment display of the speed.
				Style()
					.justifySelf(.start)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Color("#1a0000"))
					.border(Color("#777766"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.font(.large, weight: .bold)
					.monospacedDigit()
					.color(Color("#ff2a1a"))
					.textShadow(Shadow(y: 0, blur: .pixels(4), color: Color("#ff2a1a")))
			case .caseButtons:
				Style()
					.hstack(alignment: .center, justification: .end, spacing: .rootEm(0.5))
					.flexWrap()
			case .caseButton:
				// A chunky beige button of the case, which stays in while it is on.
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.75))
					.background(Color("#d6cba8"))
					.border(Color("#efe6c8"), width: .pixels(3), style: .outset)
					.textStyle(.caption, weight: .heavy)
					.letterSpacing(.em(0.08))
					.color(Color("#333333"))
					.handCursor()
					.active {
						$0.border(Color("#efe6c8"), width: .pixels(3), style: .inset)
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#c4b890"))
							.border(Color("#efe6c8"), width: .pixels(3), style: .inset)
					}
			case .smash:
				// Smaller than the picture, next to the text.
				Style()
					.frame(width: .rootEm(6))
					.children("picture > img") {
						$0.frame(width: .percent(100), height: .auto)
					}
			case .bios:
				// The screen of the BIOS: gray text on black over the whole window, above everything else.
				Style()
					.position(.fixed)
					.inset(0)
					.zIndex(85)
					.overflow(.hidden)
					.padding(.rootEm(1.5))
					.background(.black)
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .clamp(.rootEm(0.75), .viewportWidth(2.6), .rootEm(1.125)), lineHeight: 1.35)
					.color(Color("#c0c0c0"))
					.preservesLineBreaks()
					.overflowWrap(.anywhere)
			}
		}
	}
}
