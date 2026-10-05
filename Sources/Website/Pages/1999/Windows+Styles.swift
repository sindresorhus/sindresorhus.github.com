import Elementary
import Foundation
import SiteKit

extension GeoCitiesWindows {
	enum Styles: StyleSet {
		case normalWindow
		case wideWindow
		case stack
		case wrapRow
		case nowrapRow
		case grow
		case desktopState
		case fileList
		case fileButton
		case submenuItem
		case submenu
		case submenuArrow
		case menuSeparator
		case menuIcon
		case tasks
		case taskButton
		case tray
		case trayButton
		case volumePopup
		case volumeSlider
		case calcScreen
		case calcDisplay
		case calcMemory
		case calcTopRow
		case calcKeys
		case calcRedKey
		case calcBlueKey
		case dos
		case dosOutput
		case dosLine
		case dosInput
		case toolbar
		case toolbarSelect
		case toolbarButton
		case toolbarLabel
		case wordpadPage
		case wordpadText
		case wingdings
		case assistant
		case assistantClip
		case assistantEyes
		case assistantBalloon
		case assistantChoice
		case ieThrobber
		case ieAddressBar
		case iePage
		case iePageContent
		case ieHeadline
		case ieLinks
		case ieLink
		case ieErrorTitle
		case ieDroste
		case ieStatusBar
		case progressTrack
		case progressFill
		case addressField
		case mediaScreen
		case mediaVideo
		case mediaBuffering
		case lcdSmall
		case soundTop
		case soundLabel
		case soundWave
		case soundControls
		case soundButton
		case recordButton
		case freecellTable
		case freecellTop
		case cardSlots
		case cardSlot
		case slotSuit
		case freecellKing
		case freecellColumns
		case freecellColumn
		case card
		case numberField
		case paneTitle
		case calendar
		case calendarHead
		case calendarDay
		case jackBox
		case programRow
		case fixerBody
		case fixerLogo
		case findAnimation
		case findGlass
		case taskList
		case welcomeTitle
		case welcomeLogo
		case welcomeColumns
		case welcomeTopic
		case welcomePane
		case messageRow
		case messageIcon
		case messageText
		case messageDetails
		case messageButtons
		case layer
		case webPage
		case webBanner
		case recoveryPage
		case recoveryTitle
		case channels
		case channelTitle
		case channelButton
		case ticker
		case tickerText
		case contextMenu
		case boot
		case bootText
		case bootLogo
		case bootMicrosoft
		case bootWindows
		case bootBar
		case bsod
		case bsodQuote
		case maze
		case mazeCanvas
		case mazeText
		case plainFieldset
		case quickLaunch
		case beginHint
		case beginArrow
		case cat
		case paper
		case paperPile

		/**
		The gray edge of a sunken part, like the screen of Calculator.
		*/
		private static let sunken = Color("#808080")

		/**
		The height of a card of FreeCell, and how much of each card shows in a column, where the cards overlap.
		*/
		private static let cardHeight = Length.rootEm(3.5)
		private static let cardOverlap = Length.rootEm(-2.4)

		var style: Style {
			switch self {
			case .normalWindow:
				GeoCitiesPage.Styles.desktopWindow.style
			case .wideWindow:
				// For the programs with toolbars or cards, like Internet Explorer and FreeCell. A phone still gets a window as wide as its desktop.
				GeoCitiesPage.Styles.desktopWindow.style
					.frame(width: .rootEm(32))
					.when(ancestorHas: Hooks.dosMode) {
						// In MS-DOS mode, the MS-DOS Prompt is the whole screen, as Windows is gone.
						$0.frame(width: .percent(100), height: .percent(100), maxWidth: .percent(100), maxHeight: .percent(100))
					}
			case .stack:
				Style().vstack(spacing: .rootEm(0.5))
			case .wrapRow:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .nowrapRow:
				// The field takes the rest of the row, next to its label.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.children("input") {
						$0
							.flex(1)
							.frame(minWidth: 0)
					}
			case .grow:
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(2))
			case .desktopState:
				// The hourglass while Windows is busy, like while a page loads.
				Style().when(Hooks.busy) {
					$0
						.cursor(GeoCitiesPage.GIF.hourglass.stillPath, x: 14, y: 16, fallback: .wait)
						.children("*") {
							$0.cursor(GeoCitiesPage.GIF.hourglass.stillPath, x: 14, y: 16, fallback: .wait)
						}
				}
			case .fileList:
				// The large icons of a folder, in rows.
				Style()
					.grid(minimumColumnWidth: .rootEm(5.5))
					.gap(.rootEm(0.25))
					.frame(minHeight: .rootEm(6))
					.padding(.rootEm(0.25))
					.background(.white)
					.border(Self.sunken, width: .pixels(2), style: .inset)
			case .fileButton:
				// A file of a folder, with its name under its picture, which is blue while it has the focus.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.125))
					.frame(width: .percent(100))
					.padding(.rootEm(0.25))
					.background(.transparent)
					.border(.transparent, width: 0)
					.fontFamily(.system)
					.textStyle(.caption)
					.overflowWrap(.anywhere)
					.textAlign(.center)
					.color(.black)
					.handCursor()
					.focusVisible {
						$0
							.background(Color("#000080"))
							.color(.white)
					}
			case .submenuItem:
				Style().position(.relative)
			case .submenu:
				// Under its item on a narrow desktop, like on a phone, and to the side of it on a wide one, like the menus of Windows.
				Style()
					.vstack()
					.padding(.leading, .rootEm(0.75))
					.border(.leading, Self.sunken, width: .pixels(2), style: .groove)
					.from(.laptop) {
						$0
							.position(.absolute)
							.top(.rootEm(-0.25))
							.leading(.percent(100))
							.zIndex(1)
							.frame(minWidth: .rootEm(12))
							.padding(.rootEm(0.25))
							.background(GeoCitiesPage.windowGray)
							.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
							.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000066")))
							.textWrap(.nowrap)
					}
			case .submenuArrow:
				Style()
					.margin(.leading, .auto)
					.font(.extraSmall)
			case .menuSeparator:
				Style()
					.margin(.vertical, .rootEm(0.25))
					.border(.top, Self.sunken, width: .pixels(2), style: .groove)
			case .menuIcon:
				Style()
					.fontFamily(.system)
					.font(size: .rootEm(1.25), lineHeight: 1)
			case .tasks:
				// The buttons of the open windows share the taskbar, and each gets narrower when there are many.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flex(1)
					.frame(minWidth: 0)
					.overflow(.hidden)
			case .taskButton:
				// Pressed in while its window is in front, like on the taskbar of Windows.
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(2), maxWidth: .rootEm(9))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.overflow(.hidden)
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption)
					.textWrap(.nowrap)
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.buttonFocusRing()
					.when(Hooks.selected) {
						$0
							.background(Color("#e0e0e0"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
							.fontWeight(.bold)
					}
			case .tray:
				Style()
					.position(.relative)
					.hstack(alignment: .center, spacing: .rootEm(0.125))
					.padding(.horizontal, .rootEm(0.25))
					.border(Self.sunken, width: .pixels(1), style: .inset)
			case .trayButton:
				Style()
					.padding(.pixels(2))
					.background(.transparent)
					.border(.transparent, width: 0)
					.fontFamily(.system)
					.font(size: .rootEm(1), lineHeight: 1)
					.handCursor()
					.buttonFocusRing()
			case .volumePopup:
				// Above the tray, like the volume of Windows.
				Style()
					.position(.absolute)
					.bottom(.percent(100))
					.trailing(0)
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.margin(.bottom, .rootEm(0.5))
					.padding(.rootEm(0.5))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.textStyle(.caption)
					.textWrap(.nowrap)
			case .volumeSlider:
				Style().frame(width: .rootEm(8), maxWidth: .percent(100))
			case .calcScreen:
				Style()
					.padding(.rootEm(0.25))
					.background(.white)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.overflow(.hidden)
			case .calcDisplay:
				// Upside down, like a calculator turned over at school.
				Style()
					.display(.block)
					.fontFamily(GeoCitiesPage.courier)
					.font(.extraLarge, weight: .bold)
					.textAlign(.trailing)
					.overflowWrap(.anywhere)
					.transition(.rotationEffect, animation: .easeInOut(duration: .milliseconds(600)))
					.when(Hooks.flipped) {
						$0.rotationEffect(.degrees(180))
					}
					.reducedMotion {
						$0.noTransition()
					}
			case .calcMemory:
				Style()
					.frame(width: .rootEm(2), height: .rootEm(1.75))
					.flexShrink(0)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.textAlign(.center)
					.fontWeight(.bold)
			case .calcTopRow:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.children("button") {
						$0.flex(1)
					}
			case .calcKeys:
				Style()
					.grid(columns: 6)
					.gap(.rootEm(0.25))
			case .calcRedKey:
				// The keys are small, so six fit in a row on a phone.
				GeoCitiesPage.Styles.retroButton.style
					.padding(vertical: .rootEm(0.25), horizontal: 0)
					.textStyle(.caption, weight: .bold)
					.textWrap(.nowrap)
					.color(Color("#cc0000"))
			case .calcBlueKey:
				GeoCitiesPage.Styles.retroButton.style
					.padding(vertical: .rootEm(0.25), horizontal: 0)
					.textStyle(.caption, weight: .bold)
					.textWrap(.nowrap)
					.color(Color("#0000cc"))
			case .dos:
				Style()
					.vstack(spacing: 0)
					.padding(.rootEm(0.5))
					.background(.black)
					.when(ancestorHas: Hooks.dosMode) {
						$0.frame(minHeight: .rootEm(29))
					}
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#c0c0c0"))
			case .dosOutput:
				// The last lines of the screen of DOS, which scrolls.
				Style()
					.frame(maxHeight: .rootEm(16))
					.when(ancestorHas: Hooks.dosMode) {
						$0.frame(maxHeight: .rootEm(26))
					}
					.overflow(.auto)
					.preservesLineBreaks()
					.overflowWrap(.anywhere)
			case .dosLine:
				// A long prompt, like “Abort, Retry, Fail?” on a phone, puts the field on the next line, so it always has room to type.
				Style()
					.hstack(alignment: .baseline)
					.flexWrap()
			case .dosInput:
				// No field, only the text after the prompt, like in DOS.
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(6))
					.padding(0)
					.background(.transparent)
					.border(.transparent, width: 0)
					.inheritsFont()
					.color(Color("#c0c0c0"))
					.focusVisible {
						$0.focusRing(Color("#c0c0c0"), width: .pixels(1), offset: .pixels(1), style: .dotted)
					}
			case .toolbar:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .toolbarSelect:
				// Tall enough for a finger on a phone, like the drop-down menus of the rest of the page.
				Style()
					.fontFamily(.system)
					.textStyle(.caption)
					.below(.smallTablet) {
						$0.frame(minHeight: .rootEm(1.75))
					}
			case .toolbarButton:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.25))
					.frame(minWidth: .rootEm(1.75))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.handCursor()
					.buttonFocusRing()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#e0e0e0"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .toolbarLabel:
				// Only the icons on a phone, where the toolbar is narrow.
				Style()
					.hidden()
					.from(.smallTablet) {
						$0.display(.inline)
					}
			case .wordpadPage:
				Style()
					.position(.relative)
					.padding(.rootEm(0.5))
					.background(Self.sunken)
			case .wordpadText:
				// A white page on the gray of WordPad. `geocities-windows.js` sets the font that the visitor picks.
				Style()
					.display(.block)
					.frame(width: .percent(100), minHeight: .rootEm(16))
					.padding(.rootEm(0.75))
					.background(.white)
					.border(.black, width: .pixels(1))
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.body)
					.color(.black)
					.preservesLineBreaks()
					.overflowWrap(.breakWord)
			case .wingdings:
				Style()
					.frame(maxHeight: .rootEm(20))
					.overflow(.auto)
					.lineHeight(1.6)
			case .assistant:
				// The Office Assistant, in the corner of the page, with a yellow balloon above it.
				Style()
					.position(.absolute)
					.trailing(.rootEm(0.75))
					.bottom(.rootEm(0.75))
					.vstack(alignment: .end, spacing: .rootEm(0.25))
					.frame(maxWidth: .percent(90))
			case .assistantClip:
				Style()
					.position(.relative)
					.fontFamily(.system)
					.font(size: .rootEm(3), lineHeight: 1)
					.media(.allowsMotion) {
						$0.animation(Animations.bob, .easeInOut(duration: .seconds(1)).repeatForever())
					}
			case .assistantEyes:
				// Googly eyes on the paper clip.
				Style()
					.position(.absolute)
					.top(.rootEm(0.25))
					.leading(.rootEm(0.75))
					.font(size: .rootEm(1), lineHeight: 1)
			case .assistantBalloon:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.5))
					.background(Color("#ffffcc"))
					.border(.black, width: .pixels(1))
					.cornerRadius(.rootEm(0.5))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption)
					.color(.black)
					.shadow(Shadow(x: .pixels(3), y: .pixels(3), color: Color("#00000066")))
			case .assistantChoice:
				// The links of the balloon of the Office Assistant, with blue bullets.
				Style()
					.padding(0)
					.background(.transparent)
					.border(.transparent, width: 0)
					.fontFamily(.system)
					.textStyle(.caption)
					.textAlign(.leading)
					.color(Color("#0000ff"))
					.underline()
					.handCursor()
					.before {
						$0.content("● ")
					}
			case .ieThrobber:
				// The blue “e” of Internet Explorer, which turns while a page loads.
				Style()
					.margin(.leading, .auto)
					.padding(.horizontal, .rootEm(0.5))
					.fontFamily(GeoCitiesPage.times)
					.font(.extraLarge, weight: .bold)
					.italic()
					.lineHeight(1)
					.color(Color("#1e5bd6"))
					.when(ancestorHas: Hooks.loading) {
						$0.media(.allowsMotion) {
							$0.animation(GeoCitiesPage.Animations.spin, .linear(duration: .seconds(1)).repeatForever(autoreverses: false))
						}
					}
			case .ieAddressBar:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.textStyle(.caption)
					.children("input") {
						$0
							.flex(1)
							.frame(minWidth: 0)
					}
			case .iePage:
				Style()
					.frame(minHeight: .rootEm(14), maxHeight: .rootEm(20))
					.overflow(.auto)
					.background(.white)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.times)
					.color(.black)
			case .iePageContent:
				Style()
					.padding(.rootEm(0.75))
					.flowSpacing(.rootEm(0.5))
			case .ieHeadline:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.large, weight: .bold)
					.color(Color("#000080"))
			case .ieLinks:
				Style().vstack(spacing: .rootEm(0.25))
			case .ieLink:
				// A blue, underlined link, like the links of 1999.
				Style()
					.padding(0)
					.background(.transparent)
					.border(.transparent, width: 0)
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.body)
					.textAlign(.leading)
					.color(Color("#0000ee"))
					.underline()
					.handCursor()
			case .ieErrorTitle:
				Style()
					.fontFamily(.system)
					.font(.large, weight: .bold)
			case .ieDroste:
				// A desktop in a desktop in a desktop, like the page in the page.
				Style()
					.hstack(alignment: .center, justification: .center)
					.padding(.rootEm(0.5))
					.background(Color("#008080"))
					.border(GeoCitiesPage.windowGray, width: .pixels(4), style: .outset)
					.font(.large)
			case .ieStatusBar:
				Style().hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
			case .progressTrack:
				Style()
					.display(.block)
					.frame(width: .rootEm(6), height: .rootEm(0.75))
					.flexShrink(0)
					.background(.white)
					.border(Self.sunken, width: .pixels(1), style: .inset)
			case .progressFill:
				// The blue bar of a progress bar of Windows. `geocities-windows.js` sets how far it is.
				Style()
					.display(.block)
					.frame(width: 0, height: .percent(100))
					.background(Color("#000080"))
			case .addressField:
				GeoCitiesPage.Styles.field.style
					.flex(1)
					.frame(minWidth: 0)
					.textStyle(.caption)
			case .mediaScreen:
				Style()
					.position(.relative)
					.hstack(alignment: .center, justification: .center)
					.padding(.rootEm(0.5))
					.background(.black)
			case .mediaVideo:
				Style()
					.frame(width: .percent(100), height: .auto, maxWidth: .pixels(240))
					.imageRendering(.pixelated)
			case .mediaBuffering:
				Style()
					.position(.absolute)
					.inset(0)
					.hstack(alignment: .center, justification: .center)
					.background(.black)
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(Color("#33ff66"))
			case .lcdSmall:
				Style()
					.padding(.horizontal, .rootEm(0.25))
					.background(.black)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#33ff66"))
					.textWrap(.nowrap)
			case .soundTop:
				Style().hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
			case .soundLabel:
				Style()
					.textStyle(.caption)
					.monospacedDigit()
			case .soundWave:
				// The black screen with the green line of the sound.
				Style()
					.frame(width: .rootEm(10), maxWidth: .percent(50))
					.background(.black)
					.border(Self.sunken, width: .pixels(2), style: .inset)
			case .soundControls:
				Style()
					.grid(columns: 5)
					.gap(.rootEm(0.25))
			case .soundButton:
				GeoCitiesPage.Styles.retroButton.style.padding(vertical: .rootEm(0.25), horizontal: 0)
			case .recordButton:
				GeoCitiesPage.Styles.retroButton.style
					.padding(vertical: .rootEm(0.25), horizontal: 0)
					.color(Color("#cc0000"))
			case .freecellTable:
				// The green of FreeCell, under the cells and the columns.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.375))
					.background(Color("#008000"))
					.border(Self.sunken, width: .pixels(2), style: .inset)
			case .freecellTop:
				// The free cells on the left and the home cells on the right, with the king between them, on the green of FreeCell.
				Style()
					.grid(columns: "1fr auto 1fr")
					.alignItems(.center)
					.gap(.rootEm(0.25))
			case .cardSlots:
				Style()
					.grid(columns: 4)
					.gap(.rootEm(0.125))
			case .cardSlot:
				// An empty place for a card, with a dark edge on the green. A card in it fills it.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .percent(100), height: Self.cardHeight)
					.padding(0)
					.background(.transparent)
					.border(Color("#004000"), width: .pixels(1))
					.fontFamily(.system)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffff00"), width: .pixels(2), offset: .pixels(1))
					}
			case .slotSuit:
				Style()
					.font(.large)
					.color(Color("#004000"))
			case .freecellKing:
				// The king between the free cells and the home cells, who looks to the side of the pointer, like in FreeCell.
				Style()
					.fontFamily(.system)
					.font(.extraLarge)
					.when(Hooks.lookRight) {
						$0.scaleEffect(-1)
					}
			case .freecellColumns:
				Style()
					.grid(columns: 8)
					.gap(.rootEm(0.125))
			case .freecellColumn:
				// A column of cards, which overlap, so each shows its corner.
				Style()
					.vstack(alignment: .center)
					.frame(minHeight: .rootEm(12))
					.padding(0)
					.background(.transparent)
					.border(.transparent, width: 0)
					.handCursor()
					.children("* + *") {
						$0.margin(.top, Self.cardOverlap)
					}
					.focusVisible {
						$0.focusRing(Color("#ffff00"), width: .pixels(2), offset: .pixels(1))
					}
			case .card:
				// A card of FreeCell, with its rank and suit in the corner. Red for hearts and diamonds, and dark while it is picked up, like in FreeCell.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: Self.cardHeight)
					.flexShrink(0)
					.padding(.pixels(2))
					.background(.white)
					.border(.black, width: .pixels(1))
					.cornerRadius(.pixels(3))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.lineHeight(1)
					.textAlign(.leading)
					.color(.black)
					.textWrap(.nowrap)
					.overflow(.hidden)
					.when(Hooks.cardRed) {
						$0.color(Color("#cc0000"))
					}
					.when(Hooks.selected) {
						$0.filter(.invert(1))
					}
			case .numberField:
				GeoCitiesPage.Styles.field.style.frame(width: .rootEm(5))
			case .paneTitle:
				Style().textStyle(.body, weight: .bold)
			case .calendar:
				Style()
					.grid(columns: 7)
					.gap(.pixels(2))
					.padding(.rootEm(0.25))
					.background(.white)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.textStyle(.caption)
					.textAlign(.center)
			case .calendarHead:
				Style()
					.background(Self.sunken)
					.color(.white)
			case .calendarDay:
				Style()
					.frame(minHeight: .lineHeight(1))
					.monospacedDigit()
					.when(Hooks.today) {
						$0
							.background(Color("#000080"))
							.color(.white)
					}
			case .jackBox:
				// The test area of the mouse, a box that a jack-in-the-box jumps out of.
				Style()
					.alignSelf(.center)
					.padding(.rootEm(0.25))
					.background(.white)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.font(size: .rootEm(3), lineHeight: 1)
					.handCursor()
			case .programRow:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.padding(.rootEm(0.25))
					.background(.white)
			case .fixerBody:
				// Pale and still while the program does not respond, like a window that Windows cannot draw.
				Style().when(ancestorHas: Hooks.frozen) {
					$0
						.opacity(0.35)
						.filter(.grayscale(1))
				}
			case .fixerLogo:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge)
					.lineHeight(1)
					.textAlign(.center)
					.color(Color("#cc0000"))
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#ffcc00")))
			case .findAnimation:
				Style()
					.position(.relative)
					.font(size: .rootEm(2), lineHeight: 1)
			case .findGlass:
				// The magnifying glass goes around the folder while Find searches, like in Windows 98.
				Style()
					.position(.absolute)
					.leading(.rootEm(0.5))
					.top(.rootEm(0.5))
					.font(size: .rootEm(1.25), lineHeight: 1)
					.media(.allowsMotion) {
						$0.animation(Animations.circle, .linear(duration: .seconds(1)).repeatForever(autoreverses: false))
					}
			case .taskList:
				Style().frame(minHeight: .rootEm(8))
			case .welcomeTitle:
				Style()
					.fontFamily(.system)
					.font(.large, weight: .bold)
			case .welcomeLogo:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.color(Color("#000080"))
			case .welcomeColumns:
				Style()
					.grid(minimumColumnWidth: .rootEm(10))
					.gap(.rootEm(0.5))
			case .welcomeTopic:
				Style()
					.frame(width: .percent(100))
					.padding(.rootEm(0.375))
					.background(Color("#000080"))
					.border(Color("#4040c0"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.textAlign(.leading)
					.color(.white)
					.handCursor()
			case .welcomePane:
				Style()
					.padding(.rootEm(0.5))
					.background(.white)
					.border(Self.sunken, width: .pixels(2), style: .inset)
			case .messageRow:
				Style().hstack(alignment: .start, spacing: .rootEm(0.75))
			case .messageIcon:
				Style()
					.fontFamily(.system)
					.font(size: .rootEm(2), lineHeight: 1)
			case .messageText:
				Style()
					.preservesLineBreaks()
					.overflowWrap(.breakWord)
			case .messageDetails:
				Style()
					.frame(maxHeight: .rootEm(8))
					.overflow(.auto)
					.padding(.rootEm(0.25))
					.background(.white)
					.border(Self.sunken, width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.font(.extraSmall)
					.preservesLineBreaks()
					.overflowWrap(.anywhere)
			case .messageButtons:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .layer:
				// The wallpaper and the web page of the Active Desktop, behind the icons and the windows. `geocities-windows.js` draws the wallpaper. It turns gray behind Shut Down Windows.
				Style()
					.position(.absolute)
					.inset(0)
					.zIndex(-1)
					.overflow(.hidden)
					.when(ancestorHas: Hooks.dimmed) {
						$0.filter(.grayscale(1), .brightness(0.6))
					}
			case .webPage:
				Style()
					.position(.absolute)
					.inset(0)
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.padding(.rootEm(1))
					.background(.white)
					.fontFamily(GeoCitiesPage.times)
					.textAlign(.center)
					.color(Self.sunken)
			case .webBanner:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge3)
					.color(Color("#c0c0ff"))
			case .recoveryPage:
				// The white page that Windows showed when the Active Desktop crashed, which happened a lot.
				Style()
					.position(.absolute)
					.inset(0)
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.padding(.rootEm(1))
					.background(.white)
					.fontFamily(.system)
					.textAlign(.center)
					.color(Color("#999999"))
			case .recoveryTitle:
				Style()
					.font(.extraLarge2, weight: .bold)
					.color(Color("#000080"))
			case .channels:
				// The Channel Bar of Internet Explorer 4, on the right of the desktop, over the icons.
				Style()
					.position(.absolute)
					.top(.rootEm(0.5))
					.trailing(.rootEm(0.5))
					.zIndex(0)
					.vstack(spacing: .rootEm(0.25))
					.frame(width: .rootEm(7.5))
					.padding(.rootEm(0.25))
					.background(Color("#000033"))
					.border(GeoCitiesPage.windowGray, width: .pixels(2), style: .outset)
			case .channelTitle:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
					.color(.white)
			case .channelButton:
				Style()
					.padding(.rootEm(0.25))
					.background(Color("#3366cc"))
					.border(Color("#99ccff"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.white)
					.handCursor()
			case .ticker:
				// The news ticker of the Active Desktop, above the taskbar.
				Style()
					.position(.absolute)
					.leading(.rootEm(0.5))
					.trailing(.rootEm(0.5))
					.bottom(.rootEm(3))
					.zIndex(0)
					.overflow(.hidden)
					.padding(.rootEm(0.25))
					.background(.black)
					.border(GeoCitiesPage.windowGray, width: .pixels(2), style: .outset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#ffff00"))
			case .tickerText:
				Style()
					.textWrap(.nowrap)
					.media(.allowsMotion) {
						$0.animation(GeoCitiesPage.Animations.marquee, .linear(duration: .seconds(14)).repeatForever(autoreverses: false))
					}
			case .contextMenu:
				// The menu of the right mouse button, where the pointer is. `geocities-windows.js` places it.
				Style()
					.position(.absolute)
					.zIndex(1001)
					.vstack()
					.frame(minWidth: .rootEm(11))
					.padding(.rootEm(0.25))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000066")))
			case .boot:
				// The screen of the computer while Windows starts, over the desktop.
				Style()
					.position(.absolute)
					.inset(0)
					.zIndex(2000)
					.hstack(alignment: .center, justification: .center)
					.overflow(.hidden)
					.background(.black)
					.color(Color("#c0c0c0"))
					.focusVisible {
						$0.focusRing(.white, width: .pixels(2), offset: .pixels(-4))
					}
					.when(.state, is: "scandisk") {
						// ScanDisk after Windows was not shut down properly, on the blue screen of DOS.
						$0.background(Color("#0000aa"))
					}
			case .bootText:
				Style()
					.position(.absolute)
					.top(.rootEm(0.5))
					.leading(.rootEm(0.5))
					.trailing(.rootEm(0.5))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.preservesLineBreaks()
			case .bootLogo:
				// The clouds of the startup screen of Windows 98, with the logo, and the moving bar at the bottom.
				Style()
					.position(.absolute)
					.inset(0)
					.vstack(alignment: .center, justification: .center, spacing: 0)
					.backgroundImage(
						.radialGradient("ellipse 30% 12% at 20% 30%", Color("#ffffffcc"), Color("#ffffff00")),
						.radialGradient("ellipse 35% 14% at 75% 22%", Color("#ffffffb3"), Color("#ffffff00")),
						.radialGradient("ellipse 40% 15% at 60% 75%", Color("#ffffffb3"), Color("#ffffff00")),
						.linearGradient("to bottom", Color("#3a6fd8"), Color("#9cc3f5"))
					)
					.color(.white)
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#00000066")))
			case .bootMicrosoft:
				Style()
					.fontFamily(.system)
					.font(.regular, weight: .bold)
			case .bootWindows:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge4)
			case .bootBar:
				// The bar of colors that moves along the bottom while Windows starts. It is twice as wide as the screen, with its colors twice, so it seems to never end.
				Style()
					.position(.absolute)
					.leading(0)
					.bottom(0)
					.frame(width: .percent(200), height: .rootEm(0.75))
					.backgroundImage(.linearGradient("to right", Color("#000080"), Color("#00ffff"), Color("#ff00ff"), Color("#000080"), Color("#00ffff"), Color("#ff00ff"), Color("#000080")))
					.media(.allowsMotion) {
						$0.animation(Animations.bootBar, .linear(duration: .seconds(2)).repeatForever(autoreverses: false))
					}
			case .bsod:
				// The blue screen of the launch of Windows 98, over the desktop only.
				Style()
					.position(.absolute)
					.inset(0)
					.zIndex(2000)
					.vstack(justification: .center, spacing: .rootEm(1))
					.overflow(.auto)
					.padding(.rootEm(1))
					.background(Color("#0000aa"))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.color(.white)
					.cursor(.default)
					.focusVisible {
						$0.focusRing(.white, width: .pixels(2), offset: .pixels(-4))
					}
			case .bsodQuote:
				Style()
					.padding(.rootEm(0.75))
					.background(.white)
					.fontFamily(GeoCitiesPage.times)
					.italic()
					.color(Color("#0000aa"))
			case .maze:
				Style()
					.position(.absolute)
					.inset(0)
					.zIndex(2000)
					.vstack(alignment: .center, justification: .center)
					.background(.black)
					.focusVisible {
						$0.focusRing(.white, width: .pixels(2), offset: .pixels(-4))
					}
			case .mazeCanvas:
				Style()
					.frame(width: .percent(100), height: .percent(100))
					.objectFit(.contain)
					.imageRendering(.pixelated)
			case .mazeText:
				Style()
					.position(.absolute)
					.bottom(.rootEm(0.5))
					.fontFamily(.system)
					.textStyle(.caption)
					.color(Self.sunken)
			case .plainFieldset:
				Style()
					.padding(0)
					.border(.transparent, width: 0)
			case .quickLaunch:
				// The small buttons next to the Start button, behind a groove, like the Quick Launch bar of Windows 98.
				Style()
					.hstack(alignment: .center, spacing: 0)
					.padding(.leading, .rootEm(0.25))
					.border(.leading, Self.sunken, width: .pixels(2), style: .groove)
			case .beginHint:
				// The arrow of Windows 95 that slides toward the Start button, until the first click on it. It leaves room for the buttons of the windows, and only shows where the taskbar has room for all of it.
				Style()
					.frame(minWidth: 0)
					.flex(1)
					.overflow(.hidden)
					.textWrap(.nowrap)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.visibility(false)
					.from(.smallTablet) {
						$0.visibility(true)
					}
			case .beginArrow:
				Style()
					.display(.inlineBlock)
					.media(.allowsMotion) {
						$0.animation(Animations.nudge, .easeInOut(duration: .seconds(0.5)).repeatForever())
					}
			case .cat:
				// The Kit-Cat Klock of the wallpaper, on the right of the desktop, behind the icons.
				Style()
					.position(.absolute)
					.trailing(.percent(6))
					.top(.percent(8))
					.frame(height: .percent(55))
					.imageRendering(.pixelated)
			case .paper:
				// A sheet of paper that spilled out of the full Recycle Bin, where `geocities-windows.js` drops it.
				Style()
					.position(.absolute)
					.font(size: .rootEm(1.25), lineHeight: 1)
					.allowsHitTesting(false)
			case .paperPile:
				// A point under the icon of the Recycle Bin, which the paper is placed from, so it moves with the icon.
				Style()
					.position(.relative)
					.frame(height: 0)
			}
		}
	}

	enum Animations: KeyframeSet {
		case bob
		case circle
		case bootBar
		case nudge

		var keyframes: [Keyframe] {
			switch self {
			case .bob:
				[.from(Style().offset(y: 0)), .to(Style().offset(y: .pixels(-4)))]
			case .circle:
				[.from(Style().rotationEffect(.degrees(0))), .to(Style().rotationEffect(.degrees(360)))]
			case .bootBar:
				[.from(Style().offset(x: .percent(-50))), .to(Style().offset(x: 0))]
			case .nudge:
				[.from(Style().offset(x: 0)), .to(Style().offset(x: .rootEm(-0.5)))]
			}
		}
	}
}
