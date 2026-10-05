import Elementary
import Foundation
import SiteKit

/**
The window of Netscape Navigator 4 around the 1999 page: the title bar, the menus, and the toolbar at the top, with the location of the page on GeoCities and the N with the meteors, which animates while the page scrolls or loads. From tablets, the toolbar sticks to the top of the window while the page scrolls, like the frame of a browser. On phones it scrolls away, so the page has room.

`geocities-effects.js` makes the buttons do silly things: Back and Forward cannot leave 1999, Reload loads the page again over a modem, Home goes to the top, Search jumps to a random part of the page, Print prints a certificate on a dot matrix printer, Security shows how safe the page is, and Stop stops every GIF, like the Stop button of old browsers did, until Reload.
*/
struct GeoCitiesNavigator: HTML {
	let project: Project

	/**
	The buttons of the toolbar of Netscape Navigator 4, with their icons.
	*/
	private static let buttons: [(id: String, title: String, icon: String)] = [
		("back", "Back", "◀"),
		("forward", "Forward", "▶"),
		("reload", "Reload", "↻"),
		("home", "Home", "🏠"),
		("search", "Search", "🔍"),
		("print", "Print", "🖨️"),
		("security", "Security", "🔒"),
		("stop", "Stop", "✖"),
	]

	var body: some HTML {
		div {
			p {
				"Welcome to Sindre’s Home Page!!! - Netscape"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			p {
				for menu in ["File", "Edit", "View", "Go", "Communicator", "Help"] {
					span {
						menu
					}
				}
			}
			.style(Styles.menuBar)
		}
		.accessibilityHidden()
		.style(Styles.frameTop)

		div(.id(Hooks.toolbar)) {
			div {
				div(.role("group")) {
					for item in Self.buttons {
						button(.type(.button), .hook(Hooks.button, value: item.id)) {
							span {
								item.icon
							}
							.accessibilityHidden()
							.style(Styles.icon, Styles.icon(item.id))

							span {
								item.title
							}
							.style(Styles.buttonLabel)
						}
						.style(Styles.button)
					}
				}
				.accessibilityLabel("Navigator toolbar")
				.style(Styles.buttons)

				// The N of Netscape on a planet, where meteors rain down while the page loads.
				div(.id(Hooks.throbber)) {
					span {}
					span {}
					span {}
					"N"
				}
				.accessibilityHidden()
				.style(Styles.throbber)
			}
			.style(Styles.toolbarRow)

			p {
				span {
					"Location:"
				}
				.style(Styles.locationLabel)

				span {
					"http://www.geocities.com/SiliconValley/Bay/1999/"
				}
				.style(Styles.location)

				span {
					GeoCitiesPage.GIFImage(gif: .buttonNetscapeNow4, alt: "Netscape Now! 4.0", style: .gif, project: project)
				}
				.style(Styles.netscapeNow)
			}
			.style(Styles.locationBar)

			// The certificate of the dot matrix printer, on paper with green bars and the holes of the tractor feed. `geocities-effects.js` prints it line by line.
			div(.id(Hooks.printout), .hidden) {
				div(.id(Hooks.printoutPaper), .tabindex(-1)) {}
					.accessibilityLabel("Printout")
					.style(Styles.paper)

				button(.id(Hooks.tearOff), .type(.button), .hidden) {
					"✂ Tear off"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(Styles.printout)
		}
		.style(Styles.toolbar, GeoCitiesPage.Styles.scriptingOnly)

		ModuleScript("/scripts/geocities-effects.js")
	}

	enum Hooks: String, ScriptHookSet {
		case toolbar = "geocities-navigator"
		case throbber = "geocities-navigator-throbber"
		case printout = "geocities-navigator-printout"
		case printoutPaper = "geocities-navigator-paper"
		case tearOff = "geocities-navigator-tear-off"

		/**
		What a button of the toolbar does: `back`, `forward`, `reload`, `home`, `search`, `print`, `security`, or `stop`.
		*/
		case button = "data-navigator-button"
	}

	enum Styles: StyleSet {
		case frameTop
		case menuBar
		case toolbar
		case toolbarRow
		case buttons
		case button
		case icon
		case iconBack
		case iconStop
		case iconReload
		case buttonLabel
		case throbber
		case locationBar
		case locationLabel
		case location
		case netscapeNow
		case printout
		case paper

		/**
		The color of the icon of a button, as the arrows and the stop sign are text.
		*/
		static func icon(_ id: String) -> Self {
			switch id {
			case "back", "forward":
				.iconBack
			case "stop":
				.iconStop
			case "reload":
				.iconReload
			default:
				.icon
			}
		}

		var style: Style {
			switch self {
			case .frameTop:
				// The title bar and the menus of the window, as wide as the page.
				Style()
					.frame(maxWidth: .rootEm(46))
					.margin(.horizontal, .auto)
					.background(GeoCitiesPage.windowGray)
					.border(Color("#e0e0e0"), width: .pixels(4), style: .outset)
					.border(.bottom, Color("#e0e0e0"), width: 0)
			case .menuBar:
				Style()
					.hstack(spacing: .rootEm(1))
					.flexWrap()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
			case .toolbar:
				// Under the menus, and from tablets stuck to the top of the window under the header of the site, above the page but below the toasts and the screens that cover the window. Links to a part of the page then scroll it below the toolbar.
				Style()
					.position(.relative)
					.frame(maxWidth: .rootEm(46))
					.margin(.horizontal, .auto)
					.padding(.rootEm(0.25))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#e0e0e0"), width: .pixels(4), style: .outset)
					.border(.vertical, Color("#808080"), width: .pixels(1))
					.fontFamily(.system)
					.color(.black)
					.from(.smallTablet) {
						$0
							.position(.sticky)
							.top(SiteHeader.height + .pixels(1))
							.zIndex(50)
					}
					.media(.print) {
						$0.hidden()
					}
			case .toolbarRow:
				Style().hstack(alignment: .center, spacing: .rootEm(0.25))
			case .buttons:
				Style()
					.hstack()
					.flex(1)
					.frame(minWidth: 0)
			case .button:
				// Flat until the pointer is over it, like the buttons of Netscape 4, and pressed in while it is held down. On phones only the icon shows.
				Style()
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.125))
					.flex(1)
					.frame(minWidth: 0, minHeight: .rootEm(2.75))
					.padding(.pixels(2))
					.background(.transparent)
					.border(.transparent, width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption)
					.lineHeight(1)
					.color(.black)
					.handCursor()
					.hover {
						$0.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					}
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#dfdfdf"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .icon:
				Style()
					.fontFamily(.system)
					.font(size: .rootEm(1.25), lineHeight: 1)
			case .iconBack:
				Style()
					.fontFamily(.system)
					.font(size: .rootEm(1.25), lineHeight: 1)
					.color(Color("#008000"))
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: .white))
			case .iconStop:
				Style()
					.fontFamily(.system)
					.font(size: .rootEm(1.25), lineHeight: 1)
					.bold()
					.color(Color("#cc0000"))
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: .white))
			case .iconReload:
				Style()
					.fontFamily(.system)
					.font(size: .rootEm(1.25), lineHeight: 1)
					.bold()
					.color(Color("#000080"))
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: .white))
			case .buttonLabel:
				Style().below(.smallTablet) {
					$0.visuallyHidden()
				}
			case .throbber:
				// A night sky with a planet at the bottom and the N standing on it. While it loads, three meteors fall across it again and again, unless the visitor prefers reduced motion.
				Style()
					.position(.relative)
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(2.75), height: .rootEm(2.75))
					.flexShrink(0)
					.overflow(.hidden)
					.backgroundImage(.radialGradient("ellipse 120% 45% at 50% 115%", Color("#3a6ad8"), Color("#14306e"), .transparent), .linearGradient("to bottom", Color("#000010"), Color("#101850")))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.times)
					.font(size: .rootEm(2), lineHeight: 1)
					.bold()
					.color(.white)
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#000040")), Shadow(y: 0, blur: .pixels(4), color: Color("#6699ff")))
					.children("span") {
						$0
							.position(.absolute)
							.top(.percent(-30))
							.leading(.percent(25))
							.frame(width: .pixels(2), height: .rootEm(1))
							.backgroundImage(.linearGradient("to bottom", .transparent, .white))
							.rotationEffect(.degrees(35))
							.opacity(0)
					}
					.children("span:nth-child(2)") {
						$0.leading(.percent(55))
					}
					.children("span:nth-child(3)") {
						$0.leading(.percent(85))
					}
					// Each meteor at its own speed, so they do not fall together.
					.media(.allowsMotion) {
						$0.when(.state, is: "loading") {
							$0
								.children("span") {
									$0.animation(Animations.meteor, .linear(duration: .milliseconds(700)).repeatForever(autoreverses: false))
								}
								.children("span:nth-child(2)") {
									$0.animation(Animations.meteor, .linear(duration: .milliseconds(950)).repeatForever(autoreverses: false))
								}
								.children("span:nth-child(3)") {
									$0.animation(Animations.meteor, .linear(duration: .milliseconds(1200)).repeatForever(autoreverses: false))
								}
						}
					}
			case .locationBar:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.margin(.top, .rootEm(0.25))
					.textStyle(.caption)
			case .locationLabel:
				Style()
					.fontWeight(.bold)
					.hidden(below: .phone)
			case .location:
				// Like a text field, on one line.
				Style()
					.flex(1)
					.frame(minWidth: 0)
					.overflow(.hidden)
					.padding(vertical: .pixels(2), horizontal: .rootEm(0.25))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.textWrap(.nowrap)
			case .netscapeNow:
				// Only where there is room, so the location has room on phones.
				Style()
					.lineHeight(0)
					.hidden(below: .smallTablet)
			case .printout:
				// The paper comes out under the toolbar, on the right, over the page.
				Style()
					.position(.absolute)
					.top(.percent(100))
					.trailing(.rootEm(0.5))
					.zIndex(1)
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(maxWidth: .percent(100) - .rootEm(1))
			case .paper:
				// The paper of a dot matrix printer: green bars every two lines, and the holes of the tractor feed down both sides.
				Style()
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(1.25))
					.background(.white)
					.border(.horizontal, Color("#bbbbbb"), width: .pixels(10), style: .dotted)
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000066")))
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .rootEm(0.75), lineHeight: 1.5)
					.color(Color("#333366"))
					.preservesLineBreaks()
					.children("span") {
						$0
							.display(.block)
							.textWrap(.nowrap)
					}
					.children("span:nth-child(4n + 1), span:nth-child(4n + 2)") {
						$0.background(Color("#d8f0d8"))
					}
			}
		}
	}

	enum Animations: KeyframeSet {
		case meteor

		var keyframes: [Keyframe] {
			switch self {
			case .meteor:
				[
					.from(Style().offset(x: .rootEm(1.5), y: 0).opacity(1)),
					.to(Style().offset(x: .rootEm(-1.5), y: .rootEm(3.5)).opacity(0)),
				]
			}
		}
	}
}

/**
The status bar at the bottom of the window of Netscape Navigator 4: the padlock, the progress of the loading, a message that scrolls, like the scripts of 1999 that scrolled a message in the status bar, the address of the link under the pointer, and a clock, like the DHTML clocks of 1999. It sticks to the bottom of the window while the page is in view. It only repeats what the page says in other places, so screen readers skip it.
*/
struct GeoCitiesStatusBar: HTML {
	var body: some HTML {
		div {
			span(.id(Hooks.lock)) {
				"🔓"
			}
			.style(Styles.lock)

			span {
				span(.id(Hooks.progress)) {}
					.style(Styles.progressFill)
			}
			.style(Styles.progress)

			span(.id(Hooks.text)) {
				"Document: Done"
			}
			.style(Styles.text)

			span(.id(Hooks.clock)) {}
				.style(Styles.clock)
		}
		.accessibilityHidden()
		.style(Styles.root, GeoCitiesPage.Styles.scriptingOnly)
	}

	enum Hooks: String, ScriptHookSet {
		case lock = "geocities-status-lock"
		case progress = "geocities-status-progress"
		case text = "geocities-status-text"
		case clock = "geocities-status-clock"
	}

	enum Styles: StyleSet {
		case root
		case lock
		case progress
		case progressFill
		case text
		case clock

		var style: Style {
			switch self {
			case .root:
				// Stuck to the bottom of the window, under the toasts.
				Style()
					.position(.sticky)
					.bottom(0)
					.zIndex(50)
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.frame(maxWidth: .rootEm(46))
					.margin(.horizontal, .auto)
					.padding(.pixels(2))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#e0e0e0"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption)
					.lineHeight(1.4)
					.color(.black)
					.media(.print) {
						$0.hidden()
					}
			case .lock:
				Style()
					.padding(.horizontal, .rootEm(0.25))
					.border(Color("#808080"), width: .pixels(1), style: .inset)
			case .progress:
				Style()
					.display(.block)
					.frame(width: .rootEm(4), height: .rootEm(0.75))
					.flexShrink(0)
					.border(Color("#808080"), width: .pixels(1), style: .inset)
					.hidden(below: .smallTablet)
			case .progressFill:
				// `geocities-effects.js` sets its width while the page loads.
				Style()
					.display(.block)
					.frame(width: 0, height: .percent(100))
					.background(Color("#000080"))
			case .text:
				Style()
					.flex(1)
					.frame(minWidth: 0)
					.overflow(.hidden)
					.padding(.horizontal, .rootEm(0.25))
					.border(Color("#808080"), width: .pixels(1), style: .inset)
					.textWrap(.nowrap)
			case .clock:
				Style()
					.flexShrink(0)
					.padding(.horizontal, .rootEm(0.25))
					.border(Color("#808080"), width: .pixels(1), style: .inset)
					.monospacedDigit()
					.textWrap(.nowrap)
			}
		}
	}
}
