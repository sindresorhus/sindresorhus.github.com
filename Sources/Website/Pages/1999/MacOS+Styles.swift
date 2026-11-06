import Elementary
import Foundation
import SiteKit

extension GeoCitiesMacOS {
	/**
	The colors of the theme of the Appearance, which the screen sets for its theme, and the windows, the menus, and the title bars read, so a Kaleidoscope scheme recolors all of the desktop.
	*/
	static let face = StyleVariable<Color>("mac-face")
	static let titleColor = StyleVariable<Color>("mac-title")
	static let titleText = StyleVariable<Color>("mac-title-text")
	static let highlight = StyleVariable<Color>("mac-highlight")

	/**
	The font of Mac OS 8 was Charcoal, which only Macs of that time have, so the bold system font stands in.
	*/
	static let charcoal = FontFamily.stack(.named("Charcoal"), .named("Chicago"), .named("Geneva"), .init(raw: "-apple-system"), .init(raw: "BlinkMacSystemFont"), .named("Segoe UI"), .named("Roboto"), .named("Arial"), .genericSansSerif)

	/**
	The Platinum gray of Mac OS 8.
	*/
	static let platinum = Color(raw: "#dddddd")

	/**
	The lines of a Platinum title bar, a light and a dark line that repeat over the color of the title bar.
	*/
	static let stripes = #path("/1999/mac-stripes.png")

	enum States: String, ElementStateSet {
		case on
		case `default`
	}

	enum Styles: String, StyleSet {
		case desk
		case imac
		case bezel
		case chin
		case badge
		case tray
		case trayCD
		case power
		case led
		case printer
		case printout
		case printerBody
		case below
		case keyRow
		case keyCap
		case status
		case screen
		case off
		case boot
		case bootIcon
		case welcome
		case face
		case welcomeText
		case progressTrack
		case progressBar
		case bootNote
		case bootMessage
		case extensionRow
		case desktop
		case picture
		case icons
		case icon
		case iconImage
		case iconLabel
		case menuBar
		case menus
		case menuSlot
		case menuTitle
		case menuIcon
		case menu
		case menuAtRight
		case menuItem
		case menuSeparator
		case submenuSlot
		case submenu
		case submenuArrow
		case menuRight
		case strip
		case stripModules
		case stripModule
		case stripTab
		case balloon
		case saver
		case alert
		case alertMessage
		case alertIcon
		case alertText
		case alertDetail
		case alertButtons
		case window
		case smallWindow
		case mediumWindow
		case largeWindow
		case titleBar
		case titleBox
		case zoomBox
		case collapseBox
		case windowTitle
		case windowBody
		case windowStatus
		case button
		case smallButton
		case buttons
		case toolbar
		case fine
		case field
		case fieldset
		case choice
		case numberField
		case textField
		case tabs
		case tab
		case panel
		case grid
		case row
		case listButton
		case meter
		case meterFill
		case aboutHeader
		case aboutFace
		case aboutVersion
		case memoryList
		case memoryRow
		case memoryName
		case memorySize
		case memoryBar
		case memoryFill
		case infoHeader
		case infoName
		case extensionList
		case clipCanvas
		case clipText
		case scroll
		case switcherApps
		case puzzleBoard
		case notePage
		case notePadFooter
		case pageNumber
		case stickyText
		case keyCapsDisplay
		case keyboard
		case keyCapsKey
		case chooserColumns
		case chooserList
		case searchForm
		case sites
		case results
		case result
		case resultTitle
		case relevance
		case equation
		case plot
		case game
		case gamePad
		case pad
		case padButton
		case rollButton
		case browserToolbar
		case browserButton
		case throbber
		case location
		case browserPage
		case document

		var style: Style {
			switch self {
			case .desk:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.margin(.horizontal, .auto)
			case .imac:
				// The iMac G3 in Bondi Blue: see-through blue plastic, with the light coming through it.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(width: .rootEm(44), maxWidth: .percent(100))
					.padding(top: .rootEm(1), horizontal: .rootEm(0.75), bottom: .rootEm(0.75))
					.backgroundImage(
						.radialGradient(
							.ellipse(at: .init(x: .percent(30), y: .percent(15))),
							Color(raw: "#9fe4ef"),
							Color(raw: "#2bb3cc"),
							Color(raw: "#0095b6"),
							Color(raw: "#00667d")
						)
					)
					.border(Color(raw: "#005466"), width: .pixels(2))
					.cornerRadius(.rootEm(2))
					.shadow(
						BoxShadow(
							x: .pixels(0),
							y: .pixels(8),
							blur: .pixels(16),
							color: Color(raw: "#00000055")
						),
						BoxShadow(
							x: .pixels(4),
							y: .pixels(4),
							blur: .pixels(12),
							color: Color(raw: "#ffffff66"),
							isInset: true
						)
					)
			case .bezel:
				// The dark glass around the screen.
				Style()
					.frame(width: .percent(100))
					.padding(.rootEm(0.75))
					.background(Color(raw: "#20282c"))
					.cornerRadius(.rootEm(1))
					.shadow(
						BoxShadow(
							x: .pixels(0),
							y: .pixels(0),
							blur: .pixels(0),
							spread: .pixels(3),
							color: Color(raw: "#d8f4f8aa")
						)
					)
			case .chin:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.flexWrap()
					.frame(width: .percent(100))
					.padding(.horizontal, .rootEm(0.5))
			case .badge:
				Style()
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(Color(raw: "#e8fbff"))
					.textShadow(Shadow(x: .pixels(0), y: .pixels(1), color: Color(raw: "#004a5a")))
			case .tray:
				// The CD tray, out of the iMac.
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(Color(raw: "#e9f6f8"))
					.border(Color(raw: "#7fb6c2"), width: .pixels(2))
					.cornerRadius(.rootEm(0.25))
			case .trayCD:
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(.white)
					.border(Color(raw: "#9ab"), width: .pixels(1))
					.cornerRadius(.capsule)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.handCursor()
			case .power:
				// The round power button at the right, with its light.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.75))
					.background(Color(raw: "#e9f6f8"))
					.border(Color(raw: "#4d8f9e"), width: .pixels(2))
					.cornerRadius(.capsule)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color(raw: "#003b46"))
					.handCursor()
					.active {
						$0.background(Color(raw: "#c5e6ec"))
					}
			case .led:
				// The light of the power button: green while it is on, and amber, breathing slowly, while it sleeps.
				Style()
					.frame(size: .rootEm(0.625))
					.background(Color(raw: "#335544"))
					.cornerRadius(.circle)
					.when(States.on) {
						$0
							.background(Color(raw: "#33ff66"))
							.shadow(
								BoxShadow(
									x: .pixels(0),
									y: .pixels(0),
									blur: .pixels(6),
									color: Color(raw: "#33ff66")
								)
							)
					}
					.when(Hooks.sleeping) {
						$0
							.background(Color(raw: "#ffaa22"))
							.animation(GeoCitiesPage.Animations.blink, .easeInOut(duration: .seconds(3)).repeatForever(autoreverses: true))
					}
			case .printer:
				Style()
					.vstack(alignment: .center, spacing: .zero)
					.frame(width: .rootEm(16), maxWidth: .percent(100))
			case .printout:
				Style()
					.display(.block)
					.frame(width: .percent(80), height: .auto)
					.background(.white)
					.border(Color(raw: "#bbbbbb"), width: .pixels(1))
					.shadow(BoxShadow(x: .pixels(2), y: .pixels(2), color: Color(raw: "#00000033")))
			case .printerBody:
				// The StyleWriter II, a small gray printer.
				Style()
					.frame(width: .percent(100))
					.margin(.zero)
					.padding(.rootEm(0.5))
					.background(Color(raw: "#cfcfc8"))
					.border(Color(raw: "#77776f"), width: .pixels(2))
					.cornerRadius(.rootEm(0.375))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
					.color(Color(raw: "#444444"))
			case .below:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.margin(top: .rootEm(1))
					.textAlign(.center)
			case .keyRow:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .keyCap:
				// A key of the keyboard of the iMac, pressed down while it is held for the next startup.
				Style()
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.625))
					.background(Color(raw: "#f4f8f9"))
					.border(Color(raw: "#7fa9b3"), width: .pixels(1))
					.cornerRadius(.rootEm(0.375))
					.shadow(BoxShadow(x: .pixels(0), y: .pixels(3), color: Color(raw: "#5d8c97")))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.handCursor()
					.pressed {
						$0
							.offset(y: .pixels(3))
							.background(Color(raw: "#bfe6ee"))
							.shadow(BoxShadow(x: .pixels(0), y: .pixels(0), color: Color(raw: "#5d8c97")))
					}
			case .status:
				Style().toyStatus(lines: 1)
			case .screen:
				// The screen of 4:3, taller on a phone, so the windows fit. The colors of the monitor and the theme of the Appearance are on it.
				Style()
					.position(.relative)
					.frame(width: .percent(100), minHeight: .rootEm(30))
					.aspectRatio(4.0 / 3.0)
					.overflow(.hidden)
					.background(.black)
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.8125), lineHeight: 1.3)
					.color(.black)
					.textAlign(.leading)
					.setting(GeoCitiesMacOS.face, to: GeoCitiesMacOS.platinum)
					.setting(GeoCitiesMacOS.titleColor, to: Color(raw: "#cccccc"))
					.setting(GeoCitiesMacOS.titleText, to: .black)
					.setting(GeoCitiesMacOS.highlight, to: Color(raw: "#3c3cb4"))
					.when(Hooks.theme, is: "bondi") {
						$0
							.setting(GeoCitiesMacOS.face, to: Color(raw: "#d4eef2"))
							.setting(GeoCitiesMacOS.titleColor, to: Color(raw: "#4fc3d8"))
							.setting(GeoCitiesMacOS.titleText, to: Color(raw: "#003b46"))
							.setting(GeoCitiesMacOS.highlight, to: Color(raw: "#0095b6"))
					}
					.when(Hooks.theme, is: "waffle") {
						$0
							.setting(GeoCitiesMacOS.face, to: Color(raw: "#f6e2b3"))
							.setting(GeoCitiesMacOS.titleColor, to: Color(raw: "#d9a441"))
							.setting(GeoCitiesMacOS.titleText, to: Color(raw: "#4a2a00"))
							.setting(GeoCitiesMacOS.highlight, to: Color(raw: "#8b4513"))
					}
					.when(Hooks.theme, is: "copland") {
						$0
							.setting(GeoCitiesMacOS.face, to: Color(raw: "#cdc6e3"))
							.setting(GeoCitiesMacOS.titleColor, to: Color(raw: "#8f86c0"))
							.setting(GeoCitiesMacOS.titleText, to: Color(raw: "#1b1440"))
							.setting(GeoCitiesMacOS.highlight, to: Color(raw: "#5a2d91"))
					}
					.when(Hooks.theme, is: "windows") {
						$0
							.setting(GeoCitiesMacOS.face, to: GeoCitiesPage.windowGray)
							.setting(GeoCitiesMacOS.titleColor, to: Color(raw: "#000080"))
							.setting(GeoCitiesMacOS.titleText, to: .white)
							.setting(GeoCitiesMacOS.highlight, to: Color(raw: "#000080"))
					}
					.when(Hooks.theme, is: "system7") {
						$0
							.setting(GeoCitiesMacOS.face, to: .white)
							.setting(GeoCitiesMacOS.titleColor, to: .white)
							.setting(GeoCitiesMacOS.titleText, to: .black)
							.setting(GeoCitiesMacOS.highlight, to: .black)
					}
					.when(Hooks.depth, is: "256") {
						$0.filter(.saturation(1.8), .contrast(1.15))
					}
					.when(Hooks.depth, is: "gray") {
						$0.filter(.grayscale(1), .contrast(1.3))
					}
					.when(Hooks.depth, is: "bw") {
						$0.filter(.grayscale(1), .contrast(30))
					}
			case .off:
				Style()
					.position(.absolute)
					.inset(.zero)
					.display(.flex)
					.alignItems(.center)
					.justifyContent(.center)
					.padding(.rootEm(1))
					.background(Color(raw: "#050607"))
					.fontFamily(.system)
					.textStyle(.caption)
					.textAlign(.center)
					.color(Color(raw: "#556066"))
			case .boot:
				// The gray screen of the startup.
				Style()
					.position(.absolute)
					.inset(.zero)
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(1))
					.background(Color(raw: "#999999"))
			case .bootIcon:
				Style()
					.frame(width: .rootEm(4.5), height: .auto)
					.imageRendering(.pixelated)
			case .welcome:
				// The box of “Welcome to Mac OS”, with the face of the Mac OS logo and the progress bar.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(width: .rootEm(16), maxWidth: .percent(90))
					.padding(.rootEm(1))
					.background(GeoCitiesMacOS.platinum)
					.border(.black, width: .pixels(1))
					.shadow(
						BoxShadow(x: .pixels(2), y: .pixels(2), color: Color(raw: "#00000066")),
						BoxShadow(
							x: .pixels(1),
							y: .pixels(1),
							color: .white,
							isInset: true
						)
					)
			case .face:
				Style().frame(size: .rootEm(4))
			case .welcomeText:
				Style()
					.margin(.zero)
					.font(size: .rootEm(1.25))
					.fontWeight(.bold)
			case .progressTrack:
				Style()
					.frame(width: .percent(90), height: .rootEm(0.75))
					.background(Color(raw: "#eeeeee"))
					.border(Color(raw: "#555555"), width: .pixels(1))
			case .progressBar:
				Style()
					.frame(width: .zero, height: .percent(100))
					.backgroundImage(.linearGradient(.toBottom, Color(raw: "#9c9cff"), Color(raw: "#4040c0")))
			case .bootNote:
				Style()
					.frame(minHeight: .lineHeight(1))
					.margin(.zero)
					.font(size: .rootEm(0.75))
			case .bootMessage:
				Style()
					.frame(maxWidth: .rootEm(20))
					.margin(.zero)
					.padding(.horizontal, .rootEm(1))
					.textAlign(.center)
			case .extensionRow:
				// The icons of the extensions, which march along the bottom of the screen while they load.
				Style()
					.position(.absolute)
					.leading(.rootEm(0.5))
					.trailing(.rootEm(0.5))
					.bottom(.rootEm(0.5))
					.hstack(alignment: .end, spacing: .pixels(2))
					.flexWrap()
					.children("img") {
						$0
							.frame(size: .pixels(32))
							.imageRendering(.pixelated)
					}
			case .desktop:
				Style()
					.position(.absolute)
					.inset(.zero)
					.background(Color(raw: "#6666aa"))
			case .picture:
				Style()
					.position(.absolute)
					.inset(.zero)
					.frame(size: .percent(100))
					.imageRendering(.pixelated)
			case .icons:
				Style()
					.position(.absolute)
					.top(.rootEm(1.375))
					.leading(.zero)
					.trailing(.zero)
					.bottom(.zero)
			case .icon:
				// An icon of the desktop or of a Finder window: the picture, with the name below it on white, black while it is selected.
				Style()
					.vstack(alignment: .center, spacing: .pixels(2))
					.frame(width: .rootEm(5))
					.padding(.pixels(2))
					.background(.transparent)
					.border(.transparent, width: .pixels(1))
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.6875), lineHeight: 1.15)
					.color(.black)
					.touchAction(.none)
					.textSelection(.disabled)
					.handCursor()
					.focusVisible {
						$0.focusRing(GeoCitiesMacOS.highlight.value, width: .pixels(2), offset: .pixels(1))
					}
					.when(Hooks.selected) {
						$0.children("img") {
							$0.filter(.brightness(0.55))
						}
					}
			case .iconImage:
				Style()
					.display(.block)
					.frame(size: .pixels(32))
					.imageRendering(.pixelated)
			case .iconLabel:
				Style()
					.padding(.horizontal, .pixels(3))
					.background(.white)
					.textAlign(.center)
					.overflowWrap(.breakWord)
					.when(ancestorHas: Hooks.selected) {
						$0
							.background(.black)
							.color(.white)
					}
					.when(ancestorHas: Hooks.generic) {
						$0.italic()
					}
			case .menuBar:
				// The menu bar of Mac OS 8, light gray with a black line under it, always over the windows.
				Style()
					.position(.absolute)
					.top(.zero)
					.leading(.zero)
					.trailing(.zero)
					.zIndex(900)
					.hstack(alignment: .center, justification: .spaceBetween)
					.frame(height: .rootEm(1.375))
					.background(GeoCitiesMacOS.face.value)
					.border(.bottom, .black, width: .pixels(1))
					.shadow(
						BoxShadow(
							x: .pixels(0),
							y: .pixels(1),
							color: Color(raw: "#ffffff"),
							isInset: true
						)
					)
			case .menus:
				Style()
					.hstack(alignment: .center)
					.margin(.zero)
					.padding(.horizontal, .rootEm(0.25))
			case .menuSlot:
				Style().position(.relative)
			case .menuTitle:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.frame(height: .rootEm(1.3125))
					.padding(.horizontal, .rootEm(0.5))
					.background(.transparent)
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.8125))
					.fontWeight(.bold)
					.color(.black)
					.textSelection(.disabled)
					.handCursor()
					.focusVisible {
						$0.focusRing(GeoCitiesMacOS.highlight.value, width: .pixels(2), offset: .pixels(-2))
					}
					.flexShrink(0)
					.textWrap(.nowrap)
					// On a phone, the menu bar has less room, so the titles are smaller, and the Application menu shows only the icon of the program.
					.below(.smallTablet) {
						$0
							.padding(.horizontal, .rootEm(0.1875))
							.font(size: .rootEm(0.6875))
							.children("span") {
								$0.visuallyHidden()
							}
					}
					.expanded {
						$0
							.background(GeoCitiesMacOS.highlight.value)
							.color(.white)
					}
			case .menuIcon:
				// A fixed size, as the site makes images as wide as their container at most, and a menu title is as wide as its image.
				Style()
					.display(.inlineBlock)
					.flexShrink(0)
					.frame(
						width: .pixels(16),
						height: .pixels(16),
						minWidth: .pixels(16),
						maxWidth: .pixels(16)
					)
					.imageRendering(.pixelated)
					.verticalAlign(.middle)
			case .menu:
				// A menu that drops down from its title, with a hard shadow.
				Style()
					.position(.absolute)
					.top(.percent(100))
					.leading(.zero)
					.zIndex(901)
					.frame(minWidth: .rootEm(12), maxWidth: .rootEm(18))
					.margin(.zero)
					.padding(vertical: .pixels(3), horizontal: .zero)
					.background(GeoCitiesMacOS.face.value)
					.border(.black, width: .pixels(1))
					.shadow(BoxShadow(x: .pixels(2), y: .pixels(2), color: Color(raw: "#00000066")))
			case .menuAtRight:
				Style()
					.leading(.auto)
					.trailing(.zero)
			case .menuItem:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.frame(width: .percent(100))
					.padding(vertical: .pixels(3), horizontal: .rootEm(0.75))
					.background(.transparent)
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.8125))
					.fontWeight(.bold)
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.hover {
						$0
							.background(GeoCitiesMacOS.highlight.value)
							.color(.white)
					}
					.focusVisible {
						$0
							.background(GeoCitiesMacOS.highlight.value)
							.color(.white)
					}
					.disabled {
						$0
							.background(.transparent)
							.color(Color(raw: "#999999"))
							.cursor(.default)
					}
			case .menuSeparator:
				Style()
					.margin(vertical: .pixels(3), horizontal: .zero)
					.border(.top, Color(raw: "#999999"), width: .pixels(1))
			case .submenuSlot:
				Style().position(.relative)
			case .submenu:
				// A submenu opens to the side of its item, and under it on a narrow screen.
				Style()
					.position(.absolute)
					.top(.zero)
					.leading(.percent(100))
					.zIndex(902)
					.frame(minWidth: .rootEm(11))
					.margin(.zero)
					.padding(vertical: .pixels(3), horizontal: .zero)
					.background(GeoCitiesMacOS.face.value)
					.border(.black, width: .pixels(1))
					.shadow(BoxShadow(x: .pixels(2), y: .pixels(2), color: Color(raw: "#00000066")))
					.below(.smallTablet) {
						$0
							.position(.static)
							.margin(.leading, .rootEm(1))
							.shadow(BoxShadow(x: .zero, y: .zero, color: .transparent))
					}
			case .submenuArrow:
				Style()
					.margin(.leading, .auto)
					.font(size: .rootEm(0.625))
			case .menuRight:
				Style()
					.hstack(alignment: .center)
					.padding(.trailing, .rootEm(0.25))
			case .strip:
				// The Control Strip at the bottom left, which collapses to its tab.
				Style()
					.position(.absolute)
					.leading(.zero)
					.bottom(.rootEm(0.375))
					.zIndex(800)
					.hstack()
					.background(GeoCitiesMacOS.face.value)
					.border(.black, width: .pixels(1))
					.cornerRadius(.rootEm(0.25))
			case .stripModules:
				Style().hstack(alignment: .center)
			case .stripModule:
				Style()
					.frame(width: .rootEm(1.75), height: .rootEm(1.5))
					.background(.transparent)
					.border(.trailing, Color(raw: "#999999"), width: .pixels(1))
					.font(size: .rootEm(0.75))
					.handCursor()
					.active {
						$0.background(Color(raw: "#aaaaaa"))
					}
					.pressed {
						$0.background(Color(raw: "#bbbbee"))
					}
			case .stripTab:
				Style()
					.frame(width: .rootEm(1.25))
					.background(Color(raw: "#bbbbbb"))
					.font(size: .rootEm(0.625))
					.handCursor()
			case .balloon:
				// A balloon of Balloon Help, a round white bubble with a black edge.
				Style()
					.position(.absolute)
					.zIndex(1900)
					.frame(maxWidth: .rootEm(14))
					.margin(.zero)
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.75))
					.background(.white)
					.border(.black, width: .pixels(1))
					.cornerRadius(.rootEm(1))
					.shadow(BoxShadow(x: .pixels(2), y: .pixels(2), color: Color(raw: "#00000055")))
					.font(size: .rootEm(0.75), lineHeight: 1.3)
					.fontWeight(.regular)
					.allowsHitTesting(false)
			case .saver:
				Style()
					.position(.absolute)
					.inset(.zero)
					.zIndex(1950)
					.frame(size: .percent(100))
					.background(.black)
			case .alert:
				// An alert of Mac OS 8, in the middle near the top, over everything, with the thick edge of a dialog.
				Style()
					.position(.absolute)
					.top(.percent(14))
					.leading(.zero)
					.trailing(.zero)
					.zIndex(2000)
					.vstack(spacing: .rootEm(0.75))
					.frame(width: .rootEm(24), maxWidth: .percent(94))
					.margin(.horizontal, .auto)
					.padding(.rootEm(1))
					.background(GeoCitiesMacOS.face.value)
					.border(.black, width: .pixels(1))
					.shadow(
						BoxShadow(
							x: .pixels(0),
							y: .pixels(0),
							spread: .pixels(3),
							color: Color(raw: "#bbbbbb"),
							isInset: true
						),
						BoxShadow(
							x: .pixels(0),
							y: .pixels(0),
							spread: .pixels(4),
							color: .black,
							isInset: true
						),
						BoxShadow(x: .pixels(3), y: .pixels(3), color: Color(raw: "#00000077"))
					)
					.when(Hooks.low) {
						$0
							.top(.auto)
							.bottom(.percent(4))
					}
			case .alertMessage:
				Style().hstack(alignment: .start, spacing: .rootEm(0.75))
			case .alertIcon:
				Style()
					.flexShrink(0)
					.frame(size: .pixels(32))
					.imageRendering(.pixelated)
			case .alertText:
				Style()
					.margin(.zero)
					.fontWeight(.bold)
			case .alertDetail:
				Style()
					.margin(top: .rootEm(0.375))
					.font(size: .rootEm(0.75))
					.fontWeight(.regular)
			case .alertButtons:
				Style()
					.hstack(alignment: .center, justification: .end, spacing: .rootEm(0.5))
					.flexWrap()
			case .window:
				// A Platinum window: gray, with a black edge, a light inner edge, and a hard shadow.
				Style()
					.position(.absolute)
					.vstack()
					.frame(maxWidth: .percent(98), maxHeight: .length(.percent(100) - .rootEm(1.75)))
					.background(GeoCitiesMacOS.face.value)
					.border(.black, width: .pixels(1))
					.shadow(
						BoxShadow(
							x: .pixels(1),
							y: .pixels(1),
							color: .white,
							isInset: true
						),
						BoxShadow(x: .pixels(2), y: .pixels(2), color: Color(raw: "#00000066"))
					)
					.when(Hooks.zoomed) {
						$0.frame(
							width: .percent(100),
							height: .length(.percent(100) - .rootEm(1.375)),
							maxWidth: .percent(100),
							maxHeight: .percent(100)
						)
					}
					// A rolled-up window keeps only its title bar, also while it is zoomed.
					.when(Hooks.collapsed) {
						$0.frame(height: .auto)
					}
			case .smallWindow:
				Style().frame(width: .rootEm(15))
			case .mediumWindow:
				Style().frame(width: .rootEm(19))
			case .largeWindow:
				Style().frame(width: .rootEm(25))
			case .titleBar:
				// The title bar of Platinum, striped in the window in front, plain in the windows behind it. Windoze 95 has the blue bar of Windows 95 instead.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexShrink(0)
					.frame(height: .rootEm(1.25))
					// Taller for a finger, so the larger boxes fit.
					.media(.coarsePointer) {
						$0.frame(height: .rootEm(1.5))
					}
					.padding(.horizontal, .rootEm(0.375))
					.background(GeoCitiesMacOS.face.value)
					.border(.bottom, Color(raw: "#888888"), width: .pixels(1))
					.touchAction(.none)
					.textSelection(.disabled)
					.cursor(.move)
					.when(ancestorHas: Hooks.front) {
						$0
							.background(GeoCitiesMacOS.titleColor.value)
							.backgroundImage(.url(GeoCitiesMacOS.stripes))
					}
					.when(ancestorHas: Hooks.theme, is: "windows") {
						$0.backgroundImage(.none)
					}
			case .titleBox:
				// The square boxes of the title bar, with a bevel.
				Style()
					.flexShrink(0)
					.frame(size: .rootEm(0.8125))
					// Larger for a finger.
					.media(.coarsePointer) {
						$0.frame(size: .rootEm(1.25))
					}
					.background(GeoCitiesMacOS.face.value)
					.border(Color(raw: "#333333"), width: .pixels(1))
					.shadow(
						BoxShadow(
							x: .pixels(1),
							y: .pixels(1),
							color: .white,
							isInset: true
						),
						BoxShadow(
							x: .pixels(-1),
							y: .pixels(-1),
							color: Color(raw: "#999999"),
							isInset: true
						)
					)
					.handCursor()
					.active {
						$0.background(Color(raw: "#888888"))
					}
			case .zoomBox:
				Style()
					.margin(.leading, .auto)
					.backgroundImage(
						.linearGradient(
							.toBottomRight,
							Color(raw: "#ffffff00"),
							Color(raw: "#ffffff00"),
							Color(raw: "#33333366")
						)
					)
			case .collapseBox:
				Style().backgroundImage(
					.linearGradient(
						.toBottom,
						Color(raw: "#ffffff00"),
						Color(raw: "#ffffff00"),
						Color(raw: "#333333"),
						Color(raw: "#ffffff00"),
						Color(raw: "#ffffff00")
					)
				)
			case .windowTitle:
				// The title sits on a plain patch in the middle of the stripes.
				Style()
					.margin(.horizontal, .auto)
					.padding(.horizontal, .rootEm(0.5))
					.background(GeoCitiesMacOS.face.value)
					.font(size: .rootEm(0.8125))
					.fontWeight(.bold)
					.color(.black)
					.textWrap(.nowrap)
					.overflow(.hidden)
					.allowsHitTesting(false)
					.when(ancestorHas: Hooks.theme, is: "windows") {
						$0
							.margin(.leading, .zero)
							.background(.transparent)
							.color(GeoCitiesMacOS.titleText.value)
					}
			case .windowBody:
				Style()
					.flex(1)
					.frame(minHeight: .zero)
					.overflow(.auto)
					.padding(.rootEm(0.625))
					.flowSpacing(.rootEm(0.5))
					.overflowWrap(.breakWord)
					.when(ancestorHas: Hooks.collapsed) {
						$0.hidden()
					}
			case .windowStatus:
				Style()
					.frame(minHeight: .lineHeight(1))
					.margin(.zero)
					.font(size: .rootEm(0.75))
					.fontWeight(.regular)
			case .button:
				// A Platinum push button: rounded, light at the top, darker at the bottom.
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.875))
					.backgroundImage(
						.linearGradient(
							.toBottom,
							Color(raw: "#ffffff"),
							Color(raw: "#dddddd"),
							Color(raw: "#bbbbbb")
						)
					)
					.border(.black, width: .pixels(1))
					.cornerRadius(.rootEm(0.3125))
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.8125))
					.fontWeight(.bold)
					.color(.black)
					.handCursor()
					.active {
						$0
							.backgroundImage(.linearGradient(.toBottom, Color(raw: "#555555"), Color(raw: "#777777")))
							.color(.white)
					}
					.disabled {
						$0
							.color(Color(raw: "#999999"))
							.cursor(.default)
					}
					.focusVisible {
						$0.focusRing(GeoCitiesMacOS.highlight.value, width: .pixels(2), offset: .pixels(2))
					}
					.when(States.default) {
						$0.shadow(
							BoxShadow(
								x: .zero,
								y: .zero,
								spread: .pixels(2),
								color: GeoCitiesMacOS.face.value
							),
							BoxShadow(
								x: .zero,
								y: .zero,
								spread: .pixels(3),
								color: .black
							)
						)
					}
					// The front program in the Application Switcher, which is a state, and the Shift and Option keys of Key Caps, which are toggle buttons.
					.when(States.on) {
						$0
							.backgroundImage(.linearGradient(.toBottom, Color(raw: "#9999cc"), Color(raw: "#7777bb")))
							.color(.white)
					}
					.pressed {
						$0
							.backgroundImage(.linearGradient(.toBottom, Color(raw: "#9999cc"), Color(raw: "#7777bb")))
							.color(.white)
					}
			case .smallButton:
				Style()
					.padding(vertical: .pixels(2), horizontal: .rootEm(0.5))
					.backgroundImage(.linearGradient(.toBottom, Color(raw: "#ffffff"), Color(raw: "#cccccc")))
					.border(Color(raw: "#333333"), width: .pixels(1))
					.cornerRadius(.rootEm(0.25))
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.6875))
					.fontWeight(.bold)
					.color(.black)
					.handCursor()
					.focusVisible {
						$0.focusRing(GeoCitiesMacOS.highlight.value, width: .pixels(2), offset: .pixels(2))
					}
			case .buttons:
				Style()
					.hstack(alignment: .center, justification: .end, spacing: .rootEm(0.5))
					.flexWrap()
			case .toolbar:
				Style().hstack(alignment: .center, spacing: .rootEm(0.375))
			case .fine:
				Style()
					.font(size: .rootEm(0.6875))
					.fontWeight(.regular)
					.color(Color(raw: "#333333"))
			case .field:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .fieldset:
				Style()
					.margin(.zero)
					.padding(.rootEm(0.5))
					.border(Color(raw: "#888888"), width: .pixels(1))
					.flowSpacing(.rootEm(0.25))
			case .choice:
				Style()
					.display(.block)
					.handCursor()
			case .numberField:
				Style()
					.frame(width: .rootEm(5.5))
					.padding(.pixels(2))
					.background(.white)
					.border(.black, width: .pixels(1))
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.8125))
			case .textField:
				Style()
					.frame(width: .rootEm(10), maxWidth: .percent(100))
					.padding(.pixels(2))
					.background(.white)
					.border(.black, width: .pixels(1))
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.8125))
			case .tabs:
				Style()
					.hstack(alignment: .end, spacing: .pixels(2))
					.flexWrap()
					.border(.bottom, Color(raw: "#555555"), width: .pixels(1))
			case .tab:
				Style()
					.padding(vertical: .pixels(3), horizontal: .rootEm(0.625))
					.background(Color(raw: "#c4c4c4"))
					.border([.top, .leading, .trailing], Color(raw: "#555555"), width: .pixels(1))
					.cornerRadius(.rootEm(0.25))
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.75))
					.fontWeight(.bold)
					.color(.black)
					.handCursor()
					.pressed {
						$0.background(GeoCitiesMacOS.face.value)
					}
			case .panel:
				Style().flowSpacing(.rootEm(0.5))
			case .grid:
				Style()
					.hstack(alignment: .start, spacing: .rootEm(0.25))
					.flexWrap()
					.frame(minHeight: .rootEm(5))
					.padding(.rootEm(0.375))
					.background(.white)
					.border(Color(raw: "#777777"), width: .pixels(1))
			case .row:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.padding(vertical: .pixels(1), horizontal: .rootEm(0.25))
					.handCursor()
			case .listButton:
				Style()
					.frame(width: .percent(100))
					.padding(vertical: .pixels(3), horizontal: .rootEm(0.375))
					.background(.white)
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.75))
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.pressed {
						$0
							.background(GeoCitiesMacOS.highlight.value)
							.color(.white)
					}
			case .meter:
				Style()
					.frame(height: .rootEm(0.75))
					.background(Color(raw: "#eeeeee"))
					.border(Color(raw: "#555555"), width: .pixels(1))
			case .meterFill:
				Style()
					.frame(width: .zero, height: .percent(100))
					.backgroundImage(.linearGradient(.toBottom, Color(raw: "#9c9cff"), Color(raw: "#4040c0")))
			case .aboutHeader:
				Style().hstack(alignment: .center, spacing: .rootEm(0.75))
			case .aboutFace:
				Style()
					.flexShrink(0)
					.frame(size: .rootEm(3))
			case .aboutVersion:
				Style()
					.margin(.zero)
					.font(size: .rootEm(1.375))
					.fontWeight(.heavy)
			case .memoryList:
				Style()
					.margin(.zero)
					.padding(.rootEm(0.25))
					.background(.white)
					.border(Color(raw: "#777777"), width: .pixels(1))
			case .memoryRow:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.padding(.vertical, .pixels(1))
			case .memoryName:
				Style()
					.flex(1)
					.font(size: .rootEm(0.75))
			case .memorySize:
				Style()
					.frame(width: .rootEm(4))
					.font(size: .rootEm(0.6875))
					.fontWeight(.regular)
					.textAlign(.trailing)
			case .memoryBar:
				Style()
					.display(.block)
					.frame(width: .rootEm(5), height: .rootEm(0.625))
					.background(Color(raw: "#eeeeee"))
					.border(Color(raw: "#555555"), width: .pixels(1))
			case .memoryFill:
				Style()
					.display(.block)
					.frame(height: .percent(100))
					.background(Color(raw: "#6666cc"))
			case .infoHeader:
				Style().hstack(alignment: .center, spacing: .rootEm(0.5))
			case .infoName:
				Style()
					.margin(.zero)
					.fontWeight(.heavy)
			case .extensionList:
				Style()
					.frame(maxHeight: .rootEm(12))
					.overflow(.auto)
					.margin(.zero)
					.padding(.rootEm(0.25))
					.background(.white)
					.border(Color(raw: "#777777"), width: .pixels(1))
					.font(size: .rootEm(0.75))
			case .clipCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.margin(.horizontal, .auto)
					.background(.white)
					.border(Color(raw: "#777777"), width: .pixels(1))
					.imageRendering(.pixelated)
			case .clipText:
				Style()
					.margin(.zero)
					.padding(.rootEm(0.5))
					.background(.white)
					.border(Color(raw: "#777777"), width: .pixels(1))
					.fontFamily(GeoCitiesPage.times)
					.font(size: .rootEm(1))
					.fontWeight(.regular)
					.preservesLineBreaks()
			case .scroll:
				Style().frame(width: .percent(100))
			case .switcherApps:
				Style()
					.vstack(spacing: .pixels(2))
					.children("button") {
						$0
							.hstack(alignment: .center, spacing: .rootEm(0.375))
							.textAlign(.leading)
					}
			case .puzzleBoard:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.margin(.horizontal, .auto)
					.background(.white)
					.border(.black, width: .pixels(1))
					.imageRendering(.pixelated)
					.touchAction(.manipulation)
					.handCursor()
					.focusVisible {
						$0.focusRing(GeoCitiesMacOS.highlight.value, width: .pixels(2), offset: .pixels(2))
					}
			case .notePage:
				// A page of the Note Pad: yellow paper with a folded corner at the bottom.
				Style()
					.display(.block)
					.frame(width: .percent(100))
					.padding(.rootEm(0.5))
					.background(Color(raw: "#fffbd0"))
					.border(Color(raw: "#888888"), width: .pixels(1))
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .rootEm(0.8125))
					.color(.black)
			case .notePadFooter:
				Style().hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
			case .pageNumber:
				Style().font(size: .rootEm(0.75))
			case .stickyText:
				Style()
					.display(.block)
					.frame(width: .percent(100))
					.padding(.rootEm(0.375))
					.background(.transparent)
					.border(.transparent, width: .zero)
					.fontFamily(GeoCitiesPage.comicSans)
					.font(size: .rootEm(0.8125))
					.color(.black)
			case .keyCapsDisplay:
				Style()
					.frame(minHeight: .lineHeight(1.5))
					.margin(.zero)
					.padding(.rootEm(0.375))
					.background(.white)
					.border(.black, width: .pixels(1))
					.fontFamily(GeoCitiesPage.times)
					.font(size: .rootEm(1.125))
					.fontWeight(.regular)
					.overflowWrap(.anywhere)
			case .keyboard:
				Style()
					.vstack(spacing: .pixels(2))
					.padding(.rootEm(0.375))
					.background(Color(raw: "#bbbbbb"))
					.border(Color(raw: "#555555"), width: .pixels(1))
					.children("div") {
						$0.hstack(spacing: .pixels(2))
					}
			case .keyCapsKey:
				Style()
					.flex(1)
					.frame(height: .rootEm(1.75), minWidth: .zero)
					.padding(.zero)
					.background(.white)
					.border(Color(raw: "#555555"), width: .pixels(1))
					.cornerRadius(.pixels(3))
					.fontFamily(GeoCitiesPage.times)
					.font(size: .rootEm(0.9375))
					.color(.black)
					.handCursor()
					.when(States.on) {
						$0
							.background(.black)
							.color(.white)
					}
			case .chooserColumns:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.5))
			case .chooserList:
				Style()
					.frame(minHeight: .rootEm(5))
					.margin(.zero)
					.padding(.pixels(2))
					.background(.white)
					.border(Color(raw: "#777777"), width: .pixels(1))
			case .searchForm:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .sites:
				Style()
					.grid(columns: 2)
					.gap(row: .zero, column: .rootEm(0.5))
					.font(size: .rootEm(0.6875))
			case .results:
				Style()
					.frame(minHeight: .rootEm(4), maxHeight: .rootEm(10))
					.overflow(.auto)
					.margin(.zero)
					.padding(.pixels(2))
					.background(.white)
					.border(Color(raw: "#777777"), width: .pixels(1))
			case .result:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.frame(width: .percent(100))
					.padding(vertical: .pixels(2), horizontal: .rootEm(0.25))
					.background(.transparent)
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.6875))
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.focusVisible {
						$0
							.background(GeoCitiesMacOS.highlight.value)
							.color(.white)
					}
					.when(States.on) {
						$0
							.background(GeoCitiesMacOS.highlight.value)
							.color(.white)
					}
			case .resultTitle:
				Style().flex(1)
			case .relevance:
				// The relevance of a result of Sherlock, as a bar.
				Style()
					.flexShrink(0)
					.frame(width: .rootEm(3), height: .rootEm(0.5))
					.background(Color(raw: "#eeeeee"))
					.border(Color(raw: "#555555"), width: .pixels(1))
			case .equation:
				Style()
					.frame(width: .rootEm(12), maxWidth: .percent(100))
					.padding(.pixels(3))
					.background(.white)
					.border(.black, width: .pixels(1))
					.fontFamily(GeoCitiesPage.times)
					.font(size: .rootEm(1))
					.italic()
			case .plot:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.background(.white)
					.border(Color(raw: "#777777"), width: .pixels(1))
			case .game:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.background(Color(raw: "#2f6b2f"))
					.border(.black, width: .pixels(1))
					.imageRendering(.pixelated)
					.focusVisible {
						$0.focusRing(GeoCitiesMacOS.highlight.value, width: .pixels(2), offset: .pixels(2))
					}
			case .gamePad:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
			case .pad:
				Style().hstack(alignment: .center, spacing: .pixels(4))
			case .padButton:
				// Big enough for a thumb.
				Style()
					.frame(height: .rootEm(2.5), minWidth: .rootEm(2.5))
					.backgroundImage(.linearGradient(.toBottom, Color(raw: "#ffffff"), Color(raw: "#bbbbbb")))
					.border(.black, width: .pixels(1))
					.cornerRadius(.rootEm(0.375))
					.font(size: .rootEm(1))
					.color(.black)
					.touchAction(.none)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0.backgroundImage(.linearGradient(.toBottom, Color(raw: "#888888"), Color(raw: "#aaaaaa")))
					}
			case .rollButton:
				Style()
					.padding(.horizontal, .rootEm(0.75))
					.fontFamily(GeoCitiesMacOS.charcoal)
					.font(size: .rootEm(0.8125))
					.fontWeight(.bold)
			case .browserToolbar:
				Style()
					.hstack(alignment: .center, spacing: .pixels(3))
					.flexWrap()
			case .browserButton:
				Style()
					.padding(vertical: .pixels(1), horizontal: .pixels(4))
					.background(Color(raw: "#cccccc"))
					.border(Color(raw: "#666666"), width: .pixels(1))
					.font(size: .rootEm(0.625))
			case .throbber:
				// The N of Netscape, with a meteor while it loads.
				Style()
					.margin(.leading, .auto)
					.frame(size: .rootEm(1.75))
					.display(.flex)
					.alignItems(.center)
					.justifyContent(.center)
					.background(Color(raw: "#000066"))
					.fontFamily(GeoCitiesPage.times)
					.font(size: .rootEm(1.25))
					.fontWeight(.heavy)
					.color(Color(raw: "#66ccff"))
					.when(States.on) {
						$0.animation(GeoCitiesPage.Animations.blink, .linear(duration: .seconds(0.4)).repeatForever(autoreverses: true))
					}
			case .location:
				Style()
					.margin(.zero)
					.padding(.pixels(2))
					.background(.white)
					.border(Color(raw: "#777777"), width: .pixels(1))
					.font(size: .rootEm(0.6875))
					.overflowWrap(.anywhere)
			case .browserPage:
				Style()
					.frame(minHeight: .rootEm(8))
					.padding(.rootEm(0.5))
					.background(Color(raw: "#c0c0c0"))
					.border(Color(raw: "#777777"), width: .pixels(1))
					.fontFamily(GeoCitiesPage.times)
					.font(size: .rootEm(0.875))
					.fontWeight(.regular)
					.flowSpacing(.rootEm(0.375))
			case .document:
				Style()
					.frame(maxHeight: .rootEm(14))
					.overflow(.auto)
					.padding(.rootEm(0.5))
					.background(.white)
					.border(Color(raw: "#777777"), width: .pixels(1))
					.fontFamily(GeoCitiesPage.times)
					.font(size: .rootEm(0.9375))
					.fontWeight(.regular)
					.flowSpacing(.rootEm(0.5))
			}
		}
	}
}
