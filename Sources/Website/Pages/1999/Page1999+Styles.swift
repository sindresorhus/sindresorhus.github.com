import Elementary
import Foundation
import SiteKit

extension GeoCitiesPage {
	/**
	The styles of the root element of the page: the scroll bar of Windows 95, the room for the sticky bars when a link or the focus scrolls the page, and nothing but the certificate when the visitor prints. They are plain `:root` rules in the head of the page, not `:root:has()` rules of the page's styles, as the browser checks `:has()` again on every change of the page, and this page changes all the time, which made every change lay out the whole page.
	*/
	static let rootStylesheet = Stylesheet {
		Rule(":root", Style()
			.scrollbar(.bar) {
				$0.frame(width: .pixels(16), height: .pixels(16))
			}
			.scrollbar(.track) {
				// The dithered gray of the track.
				$0.backgroundImage(.url("/1999/scrollbar-track.png"))
			}
			.scrollbar(.thumb) {
				$0
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
			}
			.scrollbar(.button) {
				$0.hidden()
			}
			.scrollbar(.upButton) {
				$0
					.display(.block)
					.frame(height: .pixels(16))
					.backgroundImage(.url("/1999/scrollbar-up.png"))
			}
			.scrollbar(.downButton) {
				$0
					.display(.block)
					.frame(height: .pixels(16))
					.backgroundImage(.url("/1999/scrollbar-down.png"))
			}
			.scrollbar(.corner) {
				$0.background(GeoCitiesPage.windowGray)
			}
			.supports(!.webKitScrollbar) {
				$0.scrollbarColor(thumb: GeoCitiesPage.windowGray, track: Color("#dfdfdf"))
			}
			// The status bar of the Netscape window is stuck to the bottom, and its toolbar to the top from tablets.
			.scrollPadding(bottom: .rootEm(2.5))
			.from(.smallTablet) {
				$0.scrollPadding(top: SiteHeader.height + .rootEm(6.5))
			}
			.media(.print) {
				$0.visibility(false)
			}
		)
	}

	static let comicSans: FontFamily = #""Comic Sans MS", "Comic Sans", "Chalkboard SE", "Comic Neue", cursive"#
	static let times: FontFamily = #""Times New Roman", Times, serif"#
	static let courier: FontFamily = #""Courier New", Courier, monospace"#
	static let impact: FontFamily = #""Impact", "Arial Black", "Haettenschweiler", sans-serif"#

	/**
	The arrow pointer of Windows 95, in pixel art.
	*/
	static let arrowCursor: RoutePath = "/1999/cursor-arrow.png"

	/**
	The hand pointer of old browsers over links, which points with the tip of the finger.
	*/
	static let handCursor: RoutePath = "/1999/cursor-hand.png"

	/**
	The gray of the windows and buttons of Windows 95.
	*/
	static let windowGray = Color("#c0c0c0")

	enum Styles: StyleSet {
		// First, so the styles of the images that are not inline, like the dividers, win.
		case gif
		case picture
		case root
		case panel
		case header
		case globe
		case title
		case marquee
		case marqueeText
		case construction
		case constructionText
		case constructionTitle
		case row
		case section
		case photo
		case figure
		case caption
		case heading
		case new
		case webring
		case links
		case bullet
		case counter
		case centeredText
		case centered
		case floating
		case flame
		case game
		case gameBar
		case retroButton
		case clock
		case score
		case holes
		case hole
		case alien
		case scriptingDisabledOnly
		case badges
		case badge
		case sparkle
		case trailStar
		case trailLetter
		case photoFrame
		case photoLoading
		case splash
		case wordArt
		case enter
		case dialUp
		case window
		case titleBar
		case titleBarWithButton
		case windowBody
		case closeButton
		case popUp
		case lcd
		case formRow
		case form
		case label
		case field
		case select
		case code
		case facts
		case factLabel
		case factValue
		case alertBox
		case countdown
		case egg
		case petScreen
		case petSprite
		case petSpriteButton
		case petScene
		case petStats
		case petBubble
		case petHat
		case petZzz
		case petMess
		case petHeart
		case petGame
		case petMeters
		case buttonRow
		case petButton
		case topLinks
		case columns
		case speech
		case choices
		case choice
		case pollResults
		case awards
		case award
		case medal
		case counterDigit
		case entries
		case entry
		case ascii
		case secret
		case parade
		case paradeUnicorns
		case banner
		case bannerText
		case bannerStar
		case quiz
		case quizTitle
		case quizPrize
		case quizQuestion
		case quizAnswers
		case quizAnswer
		case quizButton
		case quizStatus
		case matrixBox
		case matrixTitle
		case pill
		case redPill
		case bluePill
		case matrixRain
		case smallButton
		case downloadList
		case progressTrack
		case progressFill
		case saver
		case saverUnicorn
		case saverText
		case snowflake
		case toast
		case newMail
		case siteMap
		case siteMapList
		case siteMapLink
		case zombo
		case zomboTitle
		case zomboWheel
		case rainbowText
		case ticker
		case tickerList
		case bounceStrip
		case bouncer
		case bounceText
		case applet
		case appletLoading
		case appletProgress
		case appletStatus
		case lakeCanvas
		case webcam
		case webcamScreen
		case webcamScene
		case webcamPicture
		case webcamCaption
		case webcamStatic
		case webcamTime
		case icqLight
		case icqFlower
		case shrine
		case waffle
		case rock
		case rockEyes
		case subheading
		case gifWall
		case skullButton
		case helper
		case helperBody
		case certificate
		case spectrum
		case spectrumBar
		case phone
		case phoneBrand
		case phoneScreen
		case phoneScore
		case phoneCanvas
		case phoneStatus
		case phoneKeys
		case phoneKey
		case phoneKeySymbol
		case desktop
		case desktopIcons
		case desktopIcon
		case desktopIconTitle
		case desktopIconPicture
		case desktopWindow
		case desktopTitleBar
		case desktopWindowTitle
		case startMenu
		case startMenuBanner
		case startMenuList
		case startMenuItem
		case startMenuSeparator
		case startButton
		case taskbar
		case taskbarClock
		case statusBar
		case paint
		case paintTools
		case paintButton
		case paintStampPicture
		case paintCanvasFrame
		case paintCanvas
		case paintCursor
		case paintPalette
		case paintSwatch
		case sweeper
		case sweeperBar
		case sweeperLED
		case sweeperFace
		case sweeperGrid
		case sweeperCell
		case notepad
		case felt
		case card
		case redCard
		case defrag
		case defragBlock
		case saverCanvas
		case effectCanvas
		case trailDot
		case blueScreen
		case blueScreenTitle
		case blueScreenText
		case blueScreenList
		case blinkingCursor
		case bombScreen
		case bombDialog
		case macButton
		case shutDown
		case shutDownText
		case partyGIF
		case partyCount
		case monitor
		case monitorScreen
		case mouseGIF
		// Last, so it hides the elements that have a display of their own.
		case scriptingOnly

		var style: Style {
			switch self {
			case .root:
				// A tiled night sky with stars, with the pointers of Windows 95. The scroll bar is in `rootStylesheet`.
				// Narrow on phones, where every pixel of the panel counts for the games and the toys.
				Style()
					.padding(vertical: .rootEm(2), horizontal: .rootEm(1))
					.below(.smallTablet) {
						$0.padding(vertical: .rootEm(1), horizontal: .rootEm(0.375))
					}
					.background(Color("#000033"))
					.declaration(.backgroundImage, "radial-gradient(1px 1px at 12px 18px, #fff, transparent), radial-gradient(1px 1px at 52px 74px, #ffd, transparent), radial-gradient(2px 2px at 92px 30px, #fff, transparent), radial-gradient(1px 1px at 118px 104px, #aaf, transparent), radial-gradient(1px 1px at 30px 112px, #fff, transparent)")
					.declaration(.backgroundSize, "128px 128px")
					.cursor(GeoCitiesPage.arrowCursor, fallback: .default)
			case .panel:
				// A light gray window with a raised edge, and the default link colors of old browsers. The controls are light in dark mode too, like the window. The focus is a dotted line, like the focus rectangle of Windows 95, in the color of the text, so it shows on the dark boxes too. The rest of the site has no focus rings.
				Style()
					.vstack(spacing: .rootEm(1.25))
					.frame(maxWidth: .rootEm(46))
					.margin(.horizontal, .auto)
					.padding(.rootEm(1.5))
					.below(.smallTablet) {
						$0.padding(.rootEm(0.5))
					}
					.background(GeoCitiesPage.windowGray)
					.border(Color("#e0e0e0"), width: .pixels(4), style: .outset)
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.lead)
					.lineHeight(1.4)
					.letterSpacing(0)
					.color(.black)
					.declaration(.colorScheme, "light")
					.focusVisibleInside {
						$0.focusRing(.currentColor, width: .pixels(1), offset: .pixels(2), style: .dotted)
					}
					// The big button Taste the Rainbow turns the colors of the whole page.
					.media(.allowsMotion) {
						$0.when(Hooks.effect, is: "rainbow") {
							$0.animation(Animations.rainbow, .linear(duration: .seconds(2)).repeatForever(autoreverses: false))
						}
					}
					// Links light up under the pointer, like the hover scripts of 1999.
					.nested("& a") {
						$0
							.color(Color("#0000ee"))
							.underline()
							.handCursor()
							.hover {
								$0
									.color(Color("#ff0000"))
									.textShadow(Shadow(y: 0, blur: .pixels(6), color: Color("#ffff00")))
							}
					}
					.nested("& a:visited") {
						$0.color(Color("#551a8b"))
					}
					// The Y2K bug of the midnight party shakes the page in strange colors for a moment.
					.media(.allowsMotion) {
						$0.when(.state, is: "y2k") {
							$0
								.filter(.hueRotation(.degrees(180)), .saturation(3))
								.animation(Animations.y2kShake, .linear(duration: .milliseconds(160)).repeatForever())
						}
					}
					// The views of the “Best viewed with…” buttons: Lynx, the green old monitor, 16-bit color, red and cyan for 3D glasses, dark for the cool shades, and upside down for Australia. The page turns around its middle, so all of it stays where the page can scroll, and the script of the buttons, `BestViewed.js`, then brings them back into view.
					.when(GeoCitiesBestViewed.Hooks.view, is: "lynx") {
						$0
							.filter(.invert(1), .grayscale(1))
							.fontFamily(GeoCitiesPage.courier)
					}
					.when(GeoCitiesBestViewed.Hooks.view, is: "monitor") {
						$0
							.filter(.invert(1), .grayscale(1), .sepia(1), .hueRotation(.degrees(50)), .saturation(6))
							.textShadow(Shadow(y: 0, blur: .pixels(3), color: Color("#33ff33")))
					}
					.when(GeoCitiesBestViewed.Hooks.view, is: "16-bit") {
						$0.filter(.saturation(4), .contrast(1.4))
					}
					.when(GeoCitiesBestViewed.Hooks.view, is: "3d") {
						$0.textShadow(Shadow(x: .pixels(-2), y: 0, color: Color("#ff0000aa")), Shadow(x: .pixels(2), y: 0, color: Color("#00ccffaa")))
					}
					.when(GeoCitiesBestViewed.Hooks.view, is: "shades") {
						$0.filter(.invert(1), .hueRotation(.degrees(180)))
					}
					.when(GeoCitiesBestViewed.Hooks.view, is: "australia") {
						$0.rotationEffect(.degrees(180))
					}
					.media(.allowsMotion) {
						$0.transition(.rotationEffect, animation: .easeInOut(duration: .milliseconds(900)))
					}
					// Only the certificate of the iMac is printed.
					.media(.print) {
						$0.hidden()
					}
			case .header:
				Style().hstack(alignment: .center, justification: .center, spacing: .rootEm(0.75))
			case .globe:
				// Smaller on phones, so the title has room between the globes.
				Style()
					.frame(width: .clamp(.rootEm(3), .viewportWidth(14), .rootEm(6.25)))
					.flexShrink(0)
			case .title:
				// The sparkles of `geocities-effects.js` twinkle over it.
				Style()
					.position(.relative)
					.frame(minWidth: 0)
					.fontFamily(GeoCitiesPage.comicSans)
					.fluidFontSize(fromRem: 1.5, toRem: 2.5, between: .phone, and: .tablet)
					.lineHeight(1.2)
					.bold()
					.textAlign(.center)
					.color(Color("#000080"))
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), blur: 0, color: Color("#ffff00")))
			case .marquee:
				Style()
					.overflow(.hidden)
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.75))
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
			case .marqueeText:
				// Like a `<marquee>`.
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.textAlign(.center)
					.color(Color("#00ff00"))
					.media(.allowsMotion) {
						$0
							.display(.inlineBlock)
							.textWrap(.nowrap)
							.padding(.leading, .percent(100))
							.animation(Animations.marquee, .linear(duration: .seconds(16)).repeatForever(autoreverses: false))
					}
			case .construction:
				// Yellow and black stripes around a yellow sign, with a worker on each side. The stripes move.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.75))
					.flexWrap()
					.padding(.rootEm(0.75))
					.declaration(.backgroundImage, "repeating-linear-gradient(45deg, #000 0 12px, #ffd700 12px 24px)")
					.declaration(.backgroundSize, "34px 34px")
					.media(.allowsMotion) {
						$0.animation(Animations.stripes, .linear(duration: .seconds(1)).repeatForever(autoreverses: false))
					}
			case .constructionText:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.flex(1)
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.75))
					.background(Color("#ffd700"))
					.textAlign(.center)
					.fontFamily(.system)
					.color(.black)
			case .constructionTitle:
				Style()
					.font(.extraLarge, weight: .heavy)
					.textCase(.uppercase)
			case .row:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.75))
					.flexWrap()
			case .section:
				Style()
					.flowSpacing(.rootEm(0.75))
					.display(.flowRoot)
					// Long words, like a name in the guestbook, break instead of making the page wider.
					.overflowWrap(.breakWord)
			case .photo:
				Style().border(Color("#808080"), width: .pixels(4), style: .ridge)
			case .figure:
				Style()
					.margin(0)
					.textAlign(.center)
			case .caption:
				Style()
					.textStyle(.caption)
					.italic()
			case .heading:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.extraLarge2, weight: .bold)
					.color(Color("#800000"))
			case .new:
				Style()
					.padding(.horizontal, .rootEm(0.25))
					.background(Color("#cc0000"))
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.color(.white)
					.media(.allowsMotion) {
						$0.animation(Animations.blink, .timingCurve("steps(1, end)", duration: .seconds(1)).repeatForever(autoreverses: false))
					}
			case .webring:
				Style()
					.padding(.rootEm(1))
					.background(.white)
					.border(Color("#808080"), width: .pixels(3), style: .ridge)
					.textAlign(.center)
					.flowSpacing(.rootEm(0.5))
			case .links:
				// The spinning stars are the bullets.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(.leading, 0)
			case .bullet:
				Style().margin(.trailing, .rootEm(0.375))
			case .counter:
				// The digits of an odometer, each on its own wheel.
				Style()
					.hstack(spacing: .pixels(2), isInline: true)
					.verticalAlign(.middle)
			case .centeredText:
				Style().textAlign(.center)
			case .centered:
				Style()
					.display(.block)
					.margin(.horizontal, .auto)
			case .floating:
				// Only where there is room next to the text.
				Style()
					.declaration(.float, "right")
					.margin(.leading, .rootEm(0.75))
					.hidden(below: .smallTablet)
			case .flame:
				// On the line of the text, as the flame is at the bottom of the image.
				Style().verticalAlign(.baseline)
			case .gif:
				// In the line, like the images of old pages. Like all images, they are narrower than their size on phones, like the wide dividers. They wiggle under the pointer, and spin with the big button Spin All GIFs. Lynx shows no images, and the 3D view gives them red and cyan edges.
				Style()
					.display(.inline)
					.media(.allowsMotion) {
						$0
							.hover {
								$0.animation(Animations.wiggle, .easeInOut(duration: .milliseconds(120)).repeatForever())
							}
							.when(ancestorHas: Hooks.effect, is: "spin") {
								$0.animation(Animations.spin, .linear(duration: .seconds(1)).repeatForever(autoreverses: false))
							}
					}
					.when(ancestorHas: GeoCitiesBestViewed.Hooks.view, is: "lynx") {
						$0.hidden()
					}
					.when(ancestorHas: GeoCitiesBestViewed.Hooks.view, is: "3d") {
						$0.filter(.dropShadow(Shadow(x: .pixels(-3), y: 0, color: Color("#ff000099"))), .dropShadow(Shadow(x: .pixels(3), y: 0, color: Color("#00ccff99"))))
					}
			case .picture:
				// Without a box, so the image is laid out like an image without a `<picture>`, like in a flex row.
				Style().display(.contents)
			case .game:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.rootEm(1))
					.background(Color("#000033"))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.color(.white)
			case .gameBar:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(1))
					.flexWrap()
			case .retroButton:
				// A raised gray button that is pressed in while it is held down.
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(1.25))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(.black)
					.handCursor()
					.buttonFocusRing()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
					// Grayed out with an engraved look, like a disabled button of Windows 95.
					.disabled {
						$0
							.color(Color("#808080"))
							.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: .white))
							.cursor(GeoCitiesPage.arrowCursor, fallback: .default)
					}
			case .clock:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(Color("#ffff00"))
			case .score:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.fontWeight(.bold)
					.textAlign(.center)
					.color(Color("#00ff00"))
			case .holes:
				Style()
					.grid(columns: 3)
					.gap(.rootEm(0.5))
					.frame(width: .percent(100), maxWidth: .rootEm(18))
			case .hole:
				// A crater on the moon. The alien only shows while it is in the hole, Glitter peeks out as a unicorn that must not be zapped, and the hole flashes when the visitor zaps it, zaps Glitter, or misses.
				Style()
					.position(.relative)
					.hstack(alignment: .center, justification: .center)
					.aspectRatio(1)
					.padding(.rootEm(0.25))
					.background(Color("#404060"))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.cornerRadius(.percent(50))
					.handCursor()
					.children("*") {
						$0.visibility(false)
					}
					.when(.state, is: "alien") {
						$0.children("*") {
							$0.visibility(true)
						}
					}
					.when(.state, is: "zapped") {
						$0
							.background(Color("#ffff00"))
							.after {
								$0
									.content("ZAP!")
									.position(.absolute)
									.inset(0)
									.hstack(alignment: .center, justification: .center)
									.fontFamily(GeoCitiesPage.comicSans)
									.fontWeight(.bold)
									.color(Color("#cc0000"))
							}
					}
					.when(.state, is: "friend") {
						$0
							.background(Color("#ffccee"))
							.after {
								$0
									.content("🦄")
									.position(.absolute)
									.inset(0)
									.hstack(alignment: .center, justification: .center)
									.font(size: .rootEm(3), lineHeight: 1)
							}
					}
					.when(.state, is: "ouch") {
						$0
							.background(Color("#ff66cc"))
							.after {
								$0
									.content("OUCH!")
									.position(.absolute)
									.inset(0)
									.hstack(alignment: .center, justification: .center)
									.fontFamily(GeoCitiesPage.comicSans)
									.fontWeight(.bold)
									.color(.white)
							}
					}
					.when(.state, is: "missed") {
						$0.after {
							$0
								.content("MISS")
								.position(.absolute)
								.inset(0)
								.hstack(alignment: .center, justification: .center)
								.fontFamily(GeoCitiesPage.comicSans)
								.textStyle(.caption, weight: .bold)
								.color(Color("#ccccee"))
						}
					}
					.disabled {
						$0.cursor(GeoCitiesPage.arrowCursor, fallback: .default)
					}
			case .alien:
				Style().frame(width: .percent(85))
			case .scriptingDisabledOnly:
				Style().shownOnlyWithoutScripting()
			case .badges:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .badge:
				// Like an 88×31 button.
				Style()
					.display(.flex)
					.alignItems(.center)
					.justifyContent(.center)
					.frame(width: .pixels(88), minHeight: .pixels(31))
					.padding(.pixels(2))
					.background(.white)
					.border(.black)
					.fontFamily(.system)
					.font(.extraSmall, weight: .bold)
					.lineHeight(1.1)
					.textAlign(.center)
			case .sparkle:
				// A sparkle or a star of the rainbow trail behind the mouse pointer, which spins, shrinks, fades, and falls. `geocities.js` puts it at the pointer, gives it its color of the rainbow, and removes it when the animation ends.
				Style()
					.position(.fixed)
					.zIndex(60)
					.allowsHitTesting(false)
					.offset(x: .percent(-50), y: .percent(-50))
					.animation(Animations.sparkle, .easeIn(duration: .milliseconds(1200)), fillMode: .forwards)
					.reducedMotion {
						$0.hidden()
					}
			case .trailStar:
				Style()
					.fontFamily(.system)
					.font(size: .rootEm(2.75), lineHeight: 1)
			case .trailLetter:
				// A letter of the word that follows the mouse pointer, like the DHTML scripts of 1999. `geocities.js` moves it and colors it.
				Style()
					.position(.fixed)
					.leading(0)
					.top(0)
					.zIndex(61)
					.allowsHitTesting(false)
					.fontFamily(GeoCitiesPage.impact)
					.font(size: .rootEm(1.75), lineHeight: 1)
					.color(.white)
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: .black))
					.reducedMotion {
						$0.hidden()
					}
			case .photoFrame:
				// On the right of the text, like the photo of a home page.
				Style()
					.position(.relative)
					.declaration(.float, "right")
					.margin(.leading, .rootEm(1))
			case .photoLoading:
				// A gray cover that moves down the photo in steps, once, like a photo that loads over a modem. Without motion, the photo shows right away.
				Style()
					.position(.absolute)
					.leading(0)
					.trailing(0)
					.bottom(0)
					.frame(height: 0)
					.background(GeoCitiesPage.windowGray)
					.media(.allowsMotion) {
						$0.animation(Animations.load, .timingCurve("steps(12, end)", duration: .seconds(6)), fillMode: .both)
					}
			case .splash:
				// A black box with a big button, like the splash pages before the home pages of 1999.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.rootEm(1.25))
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.textAlign(.center)
					.color(.white)
			case .wordArt:
				// Like WordArt: rainbow letters with a deep shadow, a little tilted.
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.fluidFontSize(fromRem: 1.75, toRem: 3, between: .phone, and: .tablet)
					.lineHeight(1.1)
					.backgroundImage(.linearGradient("to right", Color("#ff3333"), Color("#ff9900"), Color("#ffee00"), Color("#33cc33"), Color("#3399ff"), Color("#cc66ff")))
					.backgroundClip(.text)
					.color(.transparent)
					.filter(.dropShadow(Shadow(x: .pixels(3), y: .pixels(3), color: Color("#666666"))))
					.rotationEffect(.degrees(-3))
			case .enter:
				// A big raised yellow button, like the “Enter” of a splash page. The link is blue, like all links of the page.
				Style()
					.display(.inlineBlock)
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(1.25))
					.background(Color("#ffff00"))
					.border(Color("#ffff99"), width: .pixels(4), style: .outset)
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.extraLarge, weight: .bold)
					.active {
						$0.border(Color("#ffff99"), width: .pixels(4), style: .inset)
					}
			case .dialUp:
				// A line high before the first step, so the splash does not grow when the dialing starts.
				Style()
					.frame(minHeight: .lineHeight(1))
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(Color("#00ff00"))
			case .window:
				// A window of Windows 95: gray, with a raised edge and a hard shadow. The color scheme of the desktop, like Hot Dog Stand, changes the colors of its windows.
				Style()
					.background(GeoCitiesWindows.windowFace.value(default: GeoCitiesPage.windowGray))
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000066")))
					.color(GeoCitiesWindows.windowText.value(default: .black))
			case .titleBar:
				// The blue title bar of a window of Windows 95.
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.backgroundImage(.linearGradient("to right", GeoCitiesWindows.titleStart.value(default: Color("#000080")), GeoCitiesWindows.titleEnd.value(default: Color("#1084d0"))))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.white)
			case .titleBarWithButton:
				Style().hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
			case .windowBody:
				Style()
					.padding(.rootEm(0.75))
					.flowSpacing(.rootEm(0.75))
			case .closeButton:
				// Like the close button of a window of Windows 95, but large enough for a finger.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(1.5), height: .rootEm(1.5))
					.flexShrink(0)
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.lineHeight(1)
					.color(.black)
					.handCursor()
					.buttonFocusRing()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .popUp:
				Style()
					.frame(maxWidth: .rootEm(26))
					.margin(.horizontal, .auto)
			case .lcd:
				// A green screen, like the display of a stereo.
				Style()
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.75))
					.background(Color("#0a2a0a"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(Color("#33ff66"))
			case .formRow:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .form:
				Style().vstack(alignment: .start, spacing: .rootEm(0.5))
			case .label:
				Style()
					.display(.block)
					.fontWeight(.bold)
			case .field:
				// A white field with a sunken edge, like the text fields of Windows 95.
				Style()
					.frame(width: .percent(100))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.375))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(.system)
					.textStyle(.body)
					.color(.black)
					// The focus is a blue edge, like the text fields of the rest of the site.
					.focusVisible {
						$0
							.borderColor(Color("#000080"))
							.focusRing(Color("#000080"), width: .pixels(1), offset: .pixels(-1))
					}
			case .select:
				// Next to its label, and narrower than its longest option on phones, where it is also tall enough for a finger.
				Style()
					.frame(width: .auto, minWidth: 0)
					.flex(1)
					.below(.smallTablet) {
						$0.frame(minHeight: .rootEm(1.75))
					}
			case .code:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
			case .facts:
				Style()
					.padding(.rootEm(0.75))
					.background(.white)
					.border(Color("#808080"), width: .pixels(3), style: .ridge)
					.flowSpacing(.rootEm(0.25))
			case .factLabel:
				Style()
					.display(.inline)
					.margin(.trailing, .em(0.3))
					.fontWeight(.bold)
			case .factValue:
				Style().display(.inline)
			case .alertBox:
				// A yellow box with a dashed red edge, for important news.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.rootEm(1))
					.background(Color("#ffffcc"))
					.border(Color("#cc0000"), width: .pixels(4), style: .dashed)
					.textAlign(.center)
			case .countdown:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.extraLarge, weight: .bold)
					.color(Color("#cc0000"))
			case .egg:
				// A pink egg with a screen and three buttons, like a Tamagotchi.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(1))
					.frame(width: .percent(100), maxWidth: .rootEm(21))
					.margin(.horizontal, .auto)
					.padding(vertical: .rootEm(2.5), horizontal: .rootEm(1.5))
					.backgroundImage(.radialGradient("circle at 35% 25%", Color("#ffe6f2"), Color("#ff77bb")))
					.border(Color("#cc3388"), width: .pixels(3))
					.cornerRadius(.rootEm(8))
			case .petScreen:
				// The screen of the egg, in the green of old LCD screens. It is dark while Glitter sleeps.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.frame(width: .percent(100))
					.padding(.rootEm(0.75))
					.background(Color("#9bbc0f"))
					.border(Color("#555555"), width: .pixels(4), style: .inset)
					.cornerRadius(.rootEm(0.5))
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(Color("#0f380f"))
					.transition(.colors, animation: .easeInOut(duration: .milliseconds(600)))
					.when(.state, is: "asleep") {
						$0
							.background(Color("#1b2a12"))
							.color(Color("#9bbc0f"))
					}
			case .petSprite:
				// A Rainbow Legend shines in every color.
				Style()
					.display(.block)
					.media(.allowsMotion) {
						$0.when(ancestorHas: Hooks.petStage, is: "legend") {
							$0.animation(Animations.rainbow, .linear(duration: .seconds(3)).repeatForever(autoreverses: false))
						}
					}
			case .petSpriteButton:
				// Glitter herself, a button that pets her. She grows with her stage, and moves for what she does, which `geocities.js` sets as her state.
				Style()
					.position(.relative)
					.display(.block)
					.margin(.horizontal, .auto)
					.padding(0)
					.background(.transparent)
					.border(.transparent, width: 0)
					.handCursor()
					.transition(.scaleEffect, .offset, animation: .easeOut(duration: .milliseconds(400)))
					.scaleEffect(0.75)
					.when(ancestorHas: Hooks.petStage, is: "teen") {
						$0.scaleEffect(0.88)
					}
					.when(ancestorHas: Hooks.petStage, is: "grown-up") {
						$0.scaleEffect(1)
					}
					.when(ancestorHas: Hooks.petStage, is: "legend") {
						$0.scaleEffect(1.12)
					}
					.when(.state, is: "left") {
						$0.offset(x: .percent(-30))
					}
					.when(.state, is: "right") {
						$0.offset(x: .percent(30))
					}
					.when(.state, is: "sparkly") {
						$0.filter(.brightness(1.4), .saturation(2))
					}
					.media(.allowsMotion) {
						$0
							.when(.state, is: "eating") {
								$0.animation(Animations.petBounce, .easeInOut(duration: .milliseconds(250)).repeatForever())
							}
							.when(.state, is: "petted") {
								$0.animation(Animations.petWiggle, .easeInOut(duration: .milliseconds(150)).repeatForever())
							}
							.when(.state, is: "jump") {
								$0.animation(Animations.petJump, .easeOut(duration: .milliseconds(500)).repeatForever())
							}
							.when(.state, is: "backflip") {
								$0.animation(Animations.petBackflip, .easeInOut(duration: .milliseconds(900)))
							}
							.when(.state, is: "moonwalk") {
								$0.animation(Animations.petMoonwalk, .linear(duration: .milliseconds(1200)))
							}
							.when(.state, is: "rainbow") {
								$0.animation(Animations.rainbow, .linear(duration: .milliseconds(600)).repeatForever(autoreverses: false))
							}
							.when(.state, is: "dancing") {
								$0.animation(Animations.petDance, .easeInOut(duration: .milliseconds(450)).repeatForever())
							}
					}
					.focusVisible {
						$0.focusRing(Color("#0f380f"), width: .pixels(3), offset: .pixels(2))
					}
					.reducedMotion {
						$0.noTransition()
					}
			case .petScene:
				// The place on the screen where Glitter stands, with room for her hat, her bubble, and the hearts.
				Style()
					.position(.relative)
					.frame(width: .percent(100), minHeight: .rootEm(9))
					.padding(top: .rootEm(2.5), bottom: .rootEm(0.5))
			case .petStats:
				Style()
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .petBubble:
				// A speech bubble, like in a comic, for what Glitter says now and then.
				Style()
					.position(.absolute)
					.top(0)
					.trailing(0)
					.frame(maxWidth: .percent(70))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(.white)
					.border(Color("#0f380f"), width: .pixels(2))
					.cornerRadius(.rootEm(0.75))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.transition(.opacity, animation: .easeOut(duration: .milliseconds(300)))
					.when(.state, is: "hidden") {
						$0.opacity(0)
					}
			case .petHat:
				// On her head, which is on the right of the GIF. It is inside her button, so it grows and does tricks with her.
				Style()
					.position(.absolute)
					.top(.percent(-12))
					.leading(.percent(52))
					.fontFamily(.system)
					.font(size: .rootEm(2), lineHeight: 1)
					.allowsHitTesting(false)
			case .petZzz:
				Style()
					.position(.absolute)
					.top(.rootEm(1))
					.leading(.rootEm(0.5))
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.large, weight: .bold)
					.media(.allowsMotion) {
						$0.animation(Animations.petFloat, .easeInOut(duration: .seconds(2)).repeatForever())
					}
			case .petMess:
				// The messes she makes, which the Clean button cleans up.
				Style()
					.position(.absolute)
					.bottom(0)
					.trailing(.rootEm(0.25))
					.font(.large, weight: .bold)
					.letterSpacing(.em(0.2))
			case .petHeart:
				// A heart that floats up from Glitter and fades. `geocities.js` removes it when the animation ends.
				Style()
					.position(.absolute)
					.bottom(.percent(40))
					.fontFamily(.system)
					.font(size: .rootEm(1.75), lineHeight: 1)
					.color(Color("#ff3399"))
					.allowsHitTesting(false)
					.animation(Animations.petHeart, .easeOut(duration: .milliseconds(1100)), fillMode: .forwards)
					.reducedMotion {
						$0.hidden()
					}
			case .petGame:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.fontFamily(GeoCitiesPage.comicSans)
					.fontWeight(.bold)
					.textAlign(.center)
			case .petMeters:
				Style().letterSpacing(.em(0.1))
			case .buttonRow:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .petButton:
				// A round yellow button of the egg.
				Style()
					.frame(minWidth: .rootEm(4))
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.625))
					.background(Color("#ffee55"))
					.border(Color("#cc9900"), width: .pixels(3), style: .outset)
					.cornerRadius(.capsule)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.handCursor()
					.active {
						$0.border(Color("#cc9900"), width: .pixels(3), style: .inset)
					}
			case .topLinks:
				// The numbers are in black boxes, like a chart.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.counterReset("top-links")
					.children("li") {
						$0
							.counterIncrement("top-links")
							.before {
								$0
									.content(counter: "top-links")
									.display(.inlineBlock)
									.frame(minWidth: .rootEm(1.75))
									.margin(.trailing, .rootEm(0.5))
									.background(.black)
									.fontFamily(GeoCitiesPage.courier)
									.fontWeight(.bold)
									.textAlign(.center)
									.color(Color("#ffff00"))
							}
					}
			case .columns:
				// Side by side where there is room. The columns can be narrower than their content, like the ASCII art, which scrolls instead.
				Style()
					.grid(minimumColumnWidth: .rootEm(16))
					.gap(.rootEm(1.25))
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .speech:
				// A speech bubble.
				Style()
					.padding(.rootEm(0.75))
					.background(.white)
					.border(.black, width: .pixels(2))
					.cornerRadius(.rootEm(1))
					.fontFamily(GeoCitiesPage.comicSans)
			case .choices:
				Style().vstack(spacing: .rootEm(0.25))
			case .choice:
				Style().hstack(alignment: .center, spacing: .rootEm(0.5))
			case .pollResults:
				// Bars of text, like the results of a poll on a page without images.
				Style()
					.vstack(spacing: .rootEm(0.25))
					.padding(.rootEm(0.75))
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#00ff00"))
					.overflowWrap(.anywhere)
			case .awards:
				Style()
					.hstack(justification: .center, spacing: .rootEm(0.75))
					.flexWrap()
			case .award:
				// A gold plaque.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.frame(width: .rootEm(8.5))
					.padding(.rootEm(0.75))
					.background(Color("#fff8dc"))
					.border(Color("#b8860b"), width: .pixels(4), style: .ridge)
					.textAlign(.center)
					.lineHeight(1.2)
			case .medal:
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(2.5), height: .rootEm(2.5))
					.backgroundImage(.radialGradient("circle at 35% 35%", Color("#fff6a0"), Color("#d4a017")))
					.border(Color("#8b6508"), width: .pixels(2))
					.cornerRadius(.circle)
					.font(.extraLarge)
					.color(Color("#8b0000"))
			case .counterDigit:
				// A wheel of the odometer, darker at the top and the bottom, as it is round.
				Style()
					.padding(.horizontal, .rootEm(0.25))
					.backgroundImage(.linearGradient("to bottom", Color("#000000"), Color("#555555"), Color("#000000")))
					.border(Color("#808080"))
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.color(.white)
			case .entries:
				Style().vstack(spacing: .rootEm(0.75))
			case .entry:
				Style()
					.padding(.rootEm(0.75))
					.background(.white)
					.border(Color("#808080"), width: .pixels(3), style: .ridge)
					.overflowWrap(.anywhere)
			case .ascii:
				// It scrolls on narrow screens, as the lines of ASCII art cannot wrap.
				Style()
					.overflow(horizontal: .auto)
					.padding(.rootEm(0.75))
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .rootEm(0.8125), lineHeight: 1.15)
					.color(Color("#ff99ff"))
			case .secret:
				Style()
					.padding(.rootEm(0.75))
					.background(Color("#ffff00"))
					.border(Color("#cc0000"), width: .pixels(3), style: .dashed)
					.fontFamily(GeoCitiesPage.comicSans)
					.fontWeight(.bold)
			case .parade:
				// Unicorns that run across the bottom of the window once, without catching the pointer. `geocities.js` removes them at the end.
				Style()
					.position(.fixed)
					.leading(0)
					.trailing(0)
					.bottom(0)
					.zIndex(60)
					.overflow(.hidden)
					.allowsHitTesting(false)
					.reducedMotion {
						$0.hidden()
					}
			case .paradeUnicorns:
				Style()
					.hstack(alignment: .end, spacing: .rootEm(1), isInline: true)
					.animation(Animations.parade, .linear(duration: .seconds(8)), fillMode: .forwards)
			case .banner:
				// A banner ad of 468×60, taller when the text is larger. A container, for the track of the star.
				Style()
					.position(.relative)
					.frame(width: .percent(100), maxWidth: .pixels(468), minHeight: .pixels(60))
					.margin(.horizontal, .auto)
					.overflow(.hidden)
					.containerType(.inlineSize)
					.backgroundImage(.linearGradient("to right", Color("#ffff00"), Color("#ff9900"), Color("#ff00cc")))
					.border(Color("#0000ff"), width: .pixels(3), style: .outset)
			case .bannerText:
				Style()
					.padding(.rootEm(0.25))
					.fontFamily(GeoCitiesPage.impact)
					.font(.large)
					.color(Color("#0000cc"))
					.media(.allowsMotion) {
						$0.animation(Animations.blink, .timingCurve("steps(1, end)", duration: .milliseconds(800)).repeatForever(autoreverses: false))
					}
			case .bannerStar:
				// The star that moves back and forth along the bottom of the banner. It moves with `translate`, not `left`, so the browser does not lay out the page in every frame, and in percentages of the banner (`cqi`), as a percentage of `translate` is of the star.
				Style()
					.position(.absolute)
					.bottom(0)
					.leading(.percent(45))
					.padding(.horizontal, .rootEm(0.25))
					.background(.transparent)
					.border(.transparent, width: 0)
					.fontFamily(.system)
					.font(size: .rootEm(1.75), lineHeight: 1)
					.color(Color("#ff0000"))
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: .white))
					.handCursor()
					.media(.allowsMotion) {
						$0
							.leading(0)
							.animation(Animations.bannerStar, .easeInOut(duration: .milliseconds(650)).repeatForever())
					}
			case .quiz:
				// The dark blue stage of the quiz show, with gold lights.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.rootEm(1))
					.backgroundImage(.radialGradient("circle at 50% 0%", Color("#2b2bb5"), Color("#000033")))
					.border(Color("#ffcc00"), width: .pixels(3))
					.cornerRadius(.rootEm(0.75))
					.color(.white)
			case .quizTitle:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge2)
					.color(Color("#ffcc00"))
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#000066")))
					.textAlign(.center)
			case .quizPrize:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.font(.large)
					.color(Color("#ffcc00"))
			case .quizQuestion:
				Style()
					.frame(width: .percent(100))
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(1))
					.background(Color("#000066"))
					.border(Color("#ffcc00"), width: .pixels(2))
					// Not a capsule, which would cut the corners of a question that wraps on a phone.
					.cornerRadius(.rootEm(1.5))
					.fontWeight(.bold)
					.textAlign(.center)
			case .quizAnswers:
				Style()
					.grid(minimumColumnWidth: .rootEm(15))
					.gap(.rootEm(0.5))
					.frame(width: .percent(100))
			case .quizAnswer:
				// An answer, which turns orange when picked, green when right, and disappears after 50:50.
				Style()
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(1))
					.background(Color("#000066"))
					.border(Color("#ffcc00"), width: .pixels(2))
					.cornerRadius(.capsule)
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(.white)
					.textAlign(.leading)
					.handCursor()
					.hover {
						$0.background(Color("#3333aa"))
					}
					.when(.state, is: "picked") {
						$0
							.background(Color("#ff9900"))
							.color(.black)
					}
					.when(.state, is: "correct") {
						$0
							.background(Color("#00aa00"))
							.color(.white)
					}
					.when(.state, is: "removed") {
						$0.visibility(false)
					}
			case .quizButton:
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.875))
					.background(Color("#000066"))
					.border(Color("#ffcc00"), width: .pixels(2))
					.cornerRadius(.capsule)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(Color("#ffcc00"))
					.handCursor()
					.disabled {
						$0.opacity(0.4)
					}
			case .quizStatus:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
					.textAlign(.center)
			case .matrixBox:
				// Green code on black, like the screens of the Matrix.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(.rootEm(1))
					.background(.black)
					.border(Color("#00ff41"), width: .pixels(2))
					.fontFamily(GeoCitiesPage.courier)
					.color(Color("#00ff41"))
					.textAlign(.center)
			case .matrixTitle:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.font(.extraLarge2, weight: .bold)
					.textShadow(Shadow(y: 0, blur: .pixels(8), color: Color("#00ff41")))
			case .pill:
				Style()
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(1.25))
					.border(.white, width: .pixels(2))
					.cornerRadius(.capsule)
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(.white)
					.handCursor()
			case .redPill:
				Style().backgroundImage(.linearGradient("to bottom", Color("#ff6666"), Color("#aa0000")))
			case .bluePill:
				Style().backgroundImage(.linearGradient("to bottom", Color("#6699ff"), Color("#0000aa")))
			case .matrixRain:
				// Over the whole window, until it ends, or the visitor clicks or presses a key.
				Style()
					.position(.fixed)
					.inset(0)
					.zIndex(70)
					.frame(width: .percent(100), height: .percent(100))
					.background(.black)
			case .smallButton:
				Style()
					.padding(vertical: 0, horizontal: .rootEm(0.5))
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
			case .downloadList:
				Style().flowSpacing(.rootEm(0.5))
			case .progressTrack:
				// The sunken progress bar of Windows 95.
				Style()
					.frame(height: .rootEm(1.25))
					.padding(.pixels(2))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .progressFill:
				// Blue blocks, which `geocities.js` widens.
				Style()
					.frame(width: 0, height: .percent(100))
					.background(Color("#000080"))
			case .saver:
				// A black screen over the whole window, until the visitor moves. It catches the click or tap that wakes it, so that one does not act on the page under it.
				Style()
					.position(.fixed)
					.inset(0)
					.zIndex(70)
					.overflow(.hidden)
					.background(.black)
					.reducedMotion {
						$0.hidden()
					}
			case .saverUnicorn:
				// A unicorn that flies across the screen saver, again and again. `geocities.js` gives each its height, speed, and delay.
				Style()
					.position(.absolute)
					.leading(0)
					.frame(width: .pixels(96))
					.animation(Animations.saverFly, .linear(duration: .seconds(6)).repeatForever(autoreverses: false), fillMode: .both)
			case .saverText:
				Style()
					.position(.absolute)
					.bottom(.rootEm(1))
					.leading(0)
					.trailing(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.fontWeight(.bold)
					.color(Color("#ff99ff"))
					.textAlign(.center)
			case .snowflake:
				// A snowflake that falls from the top of the window and sways. `geocities.js` gives each its place, size, speed, and delay.
				Style()
					.position(.fixed)
					.top(.rootEm(-2))
					.zIndex(59)
					.allowsHitTesting(false)
					.fontFamily(.system)
					.lineHeight(1)
					.color(.white)
					.textShadow(Shadow(y: 0, blur: .pixels(3), color: Color("#6699ff")))
					.animation(Animations.snowFall, .linear(duration: .seconds(10)).repeatForever(autoreverses: false), fillMode: .both)
					.reducedMotion {
						$0.hidden()
					}
			case .toast:
				// A message at the bottom of the window, like a dialog of Windows 95, that `geocities.js` shows for a few seconds, above the status bar of the browser.
				Style()
					.position(.fixed)
					.bottom(.rootEm(2.5))
					.leading(.rootEm(1))
					.trailing(.rootEm(1))
					.zIndex(65)
					.frame(maxWidth: .rootEm(24))
					.margin(.horizontal, .auto)
					.allowsHitTesting(false)
					.padding(.rootEm(0.75))
					.background(Color("#ffffcc"))
					.border(.black, width: .pixels(2))
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000066")))
					.fontFamily(GeoCitiesPage.comicSans)
					.fontWeight(.bold)
					.color(.black)
					.textAlign(.center)
			case .newMail:
				// A yellow note with an envelope, for visitors who come back.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.75))
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.75))
					.background(Color("#ffffcc"))
					.border(Color("#ffcc00"), width: .pixels(3), style: .outset)
					.fontFamily(GeoCitiesPage.comicSans)
					.fontWeight(.bold)
					.children("p") {
						$0.flex(1)
					}
			case .siteMap:
				Style().frame(minWidth: 0)
			case .siteMapList:
				// A white frame with a sunken edge, like the navigation frame of a frameset.
				Style()
					.grid(minimumColumnWidth: .rootEm(6.5))
					.gap(.rootEm(0.5))
					.margin(.rootEm(0.5))
					.padding(.rootEm(0.5))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .siteMapLink:
				Style()
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.25))
					.frame(height: .percent(100))
					.padding(.rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .zombo:
				// Black, with a spinning circle, like Zombo.com.
				Style()
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.padding(.rootEm(1))
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.textAlign(.center)
					.color(.white)
			case .zomboTitle:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge2)
					.color(Color("#00ccff"))
			case .zomboWheel:
				Style().frame(width: .rootEm(4))
			case .rainbowText:
				// A word in every color of the rainbow, one after the other.
				Style()
					.color(Color("#ff0000"))
					.media(.allowsMotion) {
						$0.animation(Animations.rainbow, .linear(duration: .seconds(2)).repeatForever(autoreverses: false))
					}
			case .ticker:
				// The news scrolls up in a box, like a `<marquee direction="up">`. With reduced motion, the box shows all the news.
				Style()
					.padding(.rootEm(0.5))
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
					.color(Color("#ffff00"))
					.media(.allowsMotion) {
						$0
							.frame(height: .rootEm(7))
							.overflow(.hidden)
					}
			case .tickerList:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.leading, 0)
					.media(.allowsMotion) {
						$0.animation(Animations.ticker, .linear(duration: .seconds(18)).repeatForever(autoreverses: false))
					}
			case .bounceStrip:
				// The sea, where the dolphin swims back and forth above the caption. A container, for the track of the dolphin.
				Style()
					.position(.relative)
					.padding(top: .pixels(74), horizontal: .rootEm(0.5), bottom: .rootEm(0.25))
					.overflow(.hidden)
					.containerType(.inlineSize)
					.backgroundImage(.linearGradient("to bottom", Color("#66ccff"), Color("#003399")))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
			case .bouncer:
				// Like a `<marquee behavior="alternate">`. It moves with `translate`, like the star of the banner.
				Style()
					.position(.absolute)
					.top(.pixels(4))
					.leading(0)
					.media(.allowsMotion) {
						$0.animation(Animations.bounce, .easeInOut(duration: .seconds(4)).repeatForever())
					}
			case .bounceText:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.fontWeight(.bold)
					.textAlign(.center)
					.color(.white)
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: .black))
			case .applet:
				// The gray box of a Java applet, with the status bar of the browser below it.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(maxWidth: .rootEm(22))
					.margin(.horizontal, .auto)
					.padding(.rootEm(0.5))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .appletLoading:
				Style()
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.frame(width: .percent(100), minHeight: .rootEm(12))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .appletProgress:
				Style().frame(width: .percent(80))
			case .appletStatus:
				Style()
					.frame(width: .percent(100))
					.padding(.horizontal, .rootEm(0.375))
					.border(Color("#808080"), width: .pixels(1), style: .inset)
					.fontFamily(.system)
					.textStyle(.caption)
			case .lakeCanvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(4.0 / 3.0)
			case .webcam:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
			case .webcamScreen:
				// A black screen of 4:3, like the picture of a webcam.
				Style()
					.position(.relative)
					.frame(width: .percent(100), maxWidth: .rootEm(20))
					.aspectRatio(4.0 / 3.0)
					.overflow(.hidden)
					.background(.black)
					.border(Color("#808080"), width: .pixels(4), style: .ridge)
			case .webcamScene:
				Style()
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.25))
					.frame(height: .percent(100))
					.margin(0)
					.padding(top: .rootEm(1.5), horizontal: .rootEm(0.5), bottom: .rootEm(0.5))
			case .webcamPicture:
				// In black and white, like the cheap webcams of 1999.
				Style()
					.frame(maxWidth: .percent(60))
					.filter(.grayscale(1), .contrast(1.4), .brightness(1.1))
			case .webcamCaption:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.lineHeight(1.2)
					.textAlign(.center)
					.color(.white)
			case .webcamStatic:
				// The TV static between two pictures, over the picture.
				Style()
					.position(.absolute)
					.inset(0)
					.frame(width: .percent(100), height: .percent(100))
			case .webcamTime:
				Style()
					.position(.absolute)
					.top(.rootEm(0.25))
					.leading(.rootEm(0.5))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#ffff00"))
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: .black))
			case .icqLight:
				// The flower of ICQ is green when I am online, yellow when I am away, red when I am busy, and gray when I sleep. `geocities.js` sets the state.
				Style()
					.when(.state, is: "online") {
						$0.filter(.hueRotation(.degrees(80)))
					}
					.when(.state, is: "away") {
						$0.filter(.hueRotation(.degrees(25)))
					}
					.when(.state, is: "busy") {
						$0.filter(.hueRotation(.degrees(-35)), .saturation(2))
					}
					.when(.state, is: "asleep") {
						$0.filter(.grayscale(1))
					}
			case .icqFlower:
				Style()
					.frame(width: .rootEm(1.5))
					.verticalAlign(.middle)
			case .shrine:
				// A dark purple altar with a gold edge, like the shrines of home pages.
				Style()
					.flowSpacing(.rootEm(0.75))
					.display(.flowRoot)
					.padding(.rootEm(1))
					.background(Color("#2a0033"))
					.border(Color("#ffd700"), width: .pixels(6), style: .ridge)
					.color(Color("#ffe6f7"))
					.overflowWrap(.breakWord)
			case .waffle:
				Style()
					.margin(0)
					.overflow(horizontal: .auto)
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .rootEm(0.8125), lineHeight: 1.15)
					.fontWeight(.bold)
					.color(Color("#e8b04b"))
			case .rock:
				// A gray rock, a little flat, with googly eyes.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(9), height: .rootEm(5.5))
					.margin(.horizontal, .auto)
					.backgroundImage(.radialGradient("circle at 35% 30%", Color("#cfcfcf"), Color("#555555")))
					.cornerRadius(.percent(50))
					.shadow(Shadow(x: .pixels(3), y: .pixels(6), blur: .pixels(4), color: Color("#00000066")))
			case .rockEyes:
				Style().frame(width: .rootEm(3))
			case .subheading:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.large, weight: .bold)
					.color(Color("#000080"))
			case .gifWall:
				// On the teal of Windows 95, where the GIFs with a black or a white background both show.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
					.padding(.rootEm(0.75))
					.background(Color("#008080"))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
			case .skullButton:
				Style()
					.padding(0)
					.background(.transparent)
					.border(.transparent, width: 0)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffff00"), width: .pixels(3), offset: .pixels(2))
					}
			case .helper:
				// A helper with a speech bubble, like the assistant of Office 97.
				Style()
					.hstack(alignment: .start, spacing: .rootEm(0.75))
					.padding(.rootEm(0.75))
					.background(Color("#ffffcc"))
					.border(.black, width: .pixels(2))
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000066")))
			case .helperBody:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.flex(1)
					.frame(minWidth: 0)
			case .certificate:
				// Only in a print, where the rest of the page is left out.
				Style()
					.hidden()
					.media(.print) {
						$0
							.vstack(alignment: .center, spacing: .rootEm(1))
							.visibility(true)
							.padding(.rootEm(2))
							.background(.white)
							.border(Color("#b8860b"), width: .pixels(8), style: .double)
							.fontFamily(GeoCitiesPage.comicSans)
							.font(.large)
							.textAlign(.center)
							.color(.black)
					}
			case .spectrum:
				// The spectrum of Winamp, in green, yellow, and red.
				Style()
					.hstack(alignment: .end, spacing: .pixels(2))
					.frame(height: .rootEm(2.5))
					.padding(.rootEm(0.25))
					.background(.black)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .spectrumBar:
				// A bar that bounces while the jukebox plays. `geocities.js` gives each its own speed.
				Style()
					.flex(1)
					.frame(height: .percent(10))
					.backgroundImage(.linearGradient("to top", Color("#00cc00"), Color("#ffff00"), Color("#ff0000")))
					.media(.allowsMotion) {
						$0.when(.state, is: "playing") {
							$0.animation(Animations.spectrum, .easeInOut(duration: .milliseconds(400)).repeatForever())
						}
					}
			case .phone:
				// A mobile phone of 1997, dark gray, with a green screen and a keypad.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.75))
					.frame(width: .percent(100), maxWidth: .rootEm(17))
					.margin(.horizontal, .auto)
					.padding(top: .rootEm(1), horizontal: .rootEm(1), bottom: .rootEm(1.5))
					.backgroundImage(.linearGradient("to right", Color("#2b2f3a"), Color("#59606f"), Color("#2b2f3a")))
					.border(Color("#15171c"), width: .pixels(3))
					.cornerRadius(.rootEm(2.5))
					.shadow(Shadow(x: .pixels(4), y: .pixels(6), blur: .pixels(6), color: Color("#00000066")))
			case .phoneBrand:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .heavy)
					.letterSpacing(.em(0.3))
					.color(Color("#c8ccd6"))
			case .phoneScreen:
				// The green screen, with dark pixels, like the screens of the phones of 1999.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.frame(width: .percent(100))
					.padding(.rootEm(0.5))
					.background(Color("#9fbf5a"))
					.border(Color("#1d2310"), width: .pixels(3), style: .inset)
					.cornerRadius(.rootEm(0.375))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#1f2a10"))
			case .phoneScore:
				Style().textAlign(.center)
			case .phoneCanvas:
				// Big square pixels, and a swipe steers instead of scrolling.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(84.0 / 48.0)
					.imageRendering(.pixelated)
					.touchAction(.none)
			case .phoneStatus:
				// Two lines high, so the screen does not grow when a message is longer.
				Style()
					.frame(minHeight: .lineHeight(2))
					.textAlign(.center)
					.lineHeight(1.2)
			case .phoneKeys:
				Style()
					.grid(columns: 3)
					.gap(.rootEm(0.5))
					.frame(width: .percent(100))
			case .phoneKey:
				// A round gray key, which goes down while it is pressed.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.25))
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.25))
					.backgroundImage(.radialGradient("circle at 50% 30%", Color("#f4f4f4"), Color("#a9adb6")))
					.border(Color("#15171c"), width: .pixels(2))
					.cornerRadius(.capsule)
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(Color("#111111"))
					.handCursor()
					.active {
						$0.scaleEffect(0.94)
					}
			case .phoneKeySymbol:
				Style()
					.textStyle(.caption, weight: .bold)
					.color(Color("#cc0000"))
			case .desktop:
				// The teal desktop of Windows, with the icons at the top and the taskbar at the bottom. The windows open over it. Its own layer keeps the windows and the taskbar under the screens that cover the window, like Shut Down.
				Style()
					.position(.relative)
					.zIndex(0)
					.frame(minHeight: .rootEm(34))
					.overflow(.hidden)
					.padding(bottom: .rootEm(3))
					.background(Color("#008080"))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.fontFamily(.system)
					.textStyle(.body)
					.color(.black)
			case .desktopIcons:
				Style()
					.grid(minimumColumnWidth: .rootEm(5.5))
					.gap(.rootEm(0.25))
					.padding(.rootEm(0.25))
					.when(ancestorHas: GeoCitiesWindows.Hooks.dimmed) {
						$0.filter(.grayscale(1), .brightness(0.6))
					}
			case .desktopIcon:
				// White text under the picture, like the icons of Windows.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.frame(width: .percent(100))
					.padding(.rootEm(0.25))
					.background(.transparent)
					.border(.transparent, width: 0)
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.white)
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: .black))
					.handCursor()
					.focusVisible {
						$0.focusRing(.white, width: .pixels(1), offset: .pixels(-2), style: .dotted)
					}
					.when(ancestorHas: GeoCitiesWindows.Hooks.dancing) {
						// CLEAN.AVI of the Windows 98 CD makes the icons dance.
						$0.media(.allowsMotion) {
							$0.animation(Animations.petDance, .easeInOut(duration: .seconds(0.24)).repeatForever())
						}
					}
			case .desktopIconTitle:
				// Underlined like a link while the Active Desktop shows the desktop as a web page.
				Style()
					.overflowWrap(.breakWord)
					.textAlign(.center)
					.when(ancestorHas: GeoCitiesWindows.Hooks.web) {
						$0.underline()
					}
			case .desktopIconPicture:
				Style()
					.fontFamily(.system)
					.font(size: .rootEm(2), lineHeight: 1)
					.textShadow(Shadow(x: 0, y: 0, color: .transparent))
					.when(ancestorHas: GeoCitiesWindows.Hooks.largeIcons) {
						$0.font(size: .rootEm(3.5), lineHeight: 1)
					}
			case .desktopWindow:
				// A window on the desktop, which `geocities.js` moves with its title bar, and brings to the front when the visitor uses it. It scrolls when it is taller than the desktop, like on a phone.
				Style()
					.position(.absolute)
					.top(.rootEm(0.5))
					.leading(.rootEm(0.5))
					.zIndex(1)
					.frame(width: .rootEm(24), maxWidth: .percent(100) - .rootEm(1), maxHeight: .percent(100) - .rootEm(3.25))
					.overflow(.auto)
					.when(ancestorHas: GeoCitiesWindows.Hooks.desktopShown) {
						// Show Desktop of the Quick Launch bar hides the windows until it is pressed again.
						$0.visibility(false)
					}
			case .desktopTitleBar:
				// A drag moves the window, so a finger on it does not scroll the page. It stays at the top of a window that scrolls, so Close and the drag are always in view, and over the positioned parts of the window, like a canvas.
				Style()
					.position(.sticky)
					.top(0)
					.zIndex(1)
					.cursor(.move)
					.touchAction(.none)
					.textSelection(.disabled)
			case .desktopWindowTitle:
				Style()
					.frame(minWidth: 0)
					.overflowWrap(.anywhere)
			case .startMenu:
				// Above the taskbar and the windows, with “Windows98” down the side.
				Style()
					.position(.absolute)
					.leading(.rootEm(0.25))
					.bottom(.rootEm(2.5))
					.zIndex(1000)
					.hstack()
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000066")))
			case .startMenuBanner:
				Style()
					.padding(vertical: .rootEm(0.5), horizontal: .rootEm(0.25))
					.backgroundImage(.linearGradient("to top", Color("#000080"), Color("#1084d0")))
					.fontFamily(GeoCitiesPage.impact)
					.font(.large)
					.color(GeoCitiesPage.windowGray)
					.writingMode(.verticalRightToLeft)
					.rotationEffect(.degrees(180))
			case .startMenuList:
				// The submenus open inside the list on a narrow desktop, so it scrolls when they make it taller than the desktop. On a wide one, they open to the side, and a scrolling list would cut them off.
				Style()
					.vstack()
					.frame(minWidth: .rootEm(12))
					.padding(.rootEm(0.25))
					.below(.laptop) {
						$0
							.frame(maxHeight: .rootEm(29))
							.overflow(.auto)
					}
			case .startMenuItem:
				// Blue while the pointer or the focus is on it, like the menus of Windows.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(width: .percent(100))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(.transparent)
					.border(.transparent, width: 0)
					.fontFamily(.system)
					.textStyle(.body)
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.hover {
						$0
							.background(Color("#000080"))
							.color(.white)
					}
					.focusVisible {
						$0
							.background(Color("#000080"))
							.color(.white)
					}
			case .startMenuSeparator:
				Style()
					.margin(.top, .rootEm(0.25))
					.padding(.top, .rootEm(0.25))
					.border(.top, Color("#808080"), width: .pixels(2), style: .groove)
			case .startButton:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(.black)
					.handCursor()
					.buttonFocusRing()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .taskbar:
				Style()
					.position(.absolute)
					.leading(0)
					.trailing(0)
					.bottom(0)
					.zIndex(1000)
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.padding(.rootEm(0.25))
					.background(GeoCitiesPage.windowGray)
					.border(.top, Color("#ffffff"), width: .pixels(2))
					.when(ancestorHas: GeoCitiesWindows.Hooks.dancing) {
						$0.media(.allowsMotion) {
							$0.animation(Animations.petBounce, .easeInOut(duration: .seconds(0.24)).repeatForever())
						}
					}
					.when(ancestorHas: GeoCitiesWindows.Hooks.dimmed) {
						$0.filter(.grayscale(1), .brightness(0.6))
					}
			case .taskbarClock:
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.border(Color("#808080"), width: .pixels(1), style: .inset)
					.textStyle(.caption)
			case .statusBar:
				// The status bar at the bottom of a window, a line high before the first message.
				Style()
					.frame(minHeight: .lineHeight(1))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.border(Color("#808080"), width: .pixels(1), style: .inset)
					.fontFamily(.system)
					.textStyle(.caption)
			case .paint:
				Style().vstack(spacing: .rootEm(0.5))
			case .paintTools:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .paintButton:
				// A tool, which stays pressed in while it is picked.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(minWidth: .rootEm(2.25), minHeight: .rootEm(2.25))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.25))
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
							.background(Color("#ffffff"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .paintStampPicture:
				Style().frame(width: .auto, height: .rootEm(1.75))
			case .paintCanvasFrame:
				Style()
					.position(.relative)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .paintCanvas:
				// The picture in big pixels, like a picture of 320 × 200 on a monitor of 1999. A finger draws on it instead of scrolling.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(320.0 / 200.0)
					.background(.white)
					.imageRendering(.pixelated)
					.touchAction(.none)
					.cursor(.crosshair)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .paintCursor:
				// The brush, for the keyboard, which `geocities.js` moves with the arrow keys.
				Style()
					.position(.absolute)
					.frame(width: .rootEm(1), height: .rootEm(1))
					.offset(x: .percent(-50), y: .percent(-50))
					.border(Color("#ff00ff"), width: .pixels(2), style: .dashed)
					.cornerRadius(.circle)
					.allowsHitTesting(false)
			case .paintPalette:
				Style()
					.grid(columns: 8)
					.gap(.pixels(2))
					.frame(maxWidth: .rootEm(18))
			case .paintSwatch:
				// `geocities.js` gives each its color.
				Style()
					.frame(minHeight: .rootEm(1.5))
					.padding(0)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.handCursor()
					.when(.state, is: "on") {
						$0.border(.black, width: .pixels(3))
					}
			case .sweeper:
				// The gray box of Minesweeper, with the counters and the face above the squares. Fast clicks and long presses on the squares do not select the text of the counters.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.padding(.rootEm(0.5))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.textSelection(.disabled)
			case .sweeperBar:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.frame(width: .percent(100), maxWidth: .rootEm(18))
					.padding(.rootEm(0.25))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .sweeperLED:
				// Red numbers on black, like the counters of Minesweeper.
				Style()
					.padding(.horizontal, .rootEm(0.25))
					.background(.black)
					.fontFamily(GeoCitiesPage.courier)
					.font(.large, weight: .bold)
					.letterSpacing(.em(0.1))
					.color(Color("#ff0000"))
			case .sweeperFace:
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(2.25), height: .rootEm(2.25))
					.padding(0)
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.fontFamily(.system)
					.font(size: .rootEm(1.25), lineHeight: 1)
					.handCursor()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
			case .sweeperGrid:
				Style()
					.grid(columns: GeoCitiesPage.sweeperSize)
					.frame(width: .percent(100), maxWidth: .rootEm(18))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
			case .sweeperCell:
				// A raised square, which is flat when it is open, with a number in the color of Minesweeper for the bugs next to it.
				[("1", "#0000ff"), ("2", "#008000"), ("3", "#ff0000"), ("4", "#000080"), ("5", "#800000"), ("6", "#008080"), ("7", "#000000"), ("8", "#808080")].reduce(
					Style()
						.hstack(alignment: .center, justification: .center)
						.aspectRatio(1)
						.padding(0)
						.background(GeoCitiesPage.windowGray)
						.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
						.fontFamily(.system)
						.font(size: .rootEm(1), lineHeight: 1)
						.fontWeight(.heavy)
						.handCursor()
						.focusVisible {
							$0.focusRing(.black, width: .pixels(2), offset: .pixels(-3), style: .dotted)
						}
						.when(.state, is: "open") {
							$0
								.background(Color("#bdbdbd"))
								.border(Color("#808080"), width: .pixels(1))
						}
						.when(.state, is: "exploded") {
							$0
								.background(Color("#ff0000"))
								.border(Color("#808080"), width: .pixels(1))
						}
				) { style, item in
					style.when(Hooks.sweeperCount, is: item.0) {
						$0.color(Color(item.1))
					}
				}
			case .notepad:
				// The white page of Notepad, in the font of the system of 1999.
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
					.lineHeight(1.4)
			case .felt:
				// The green felt of Solitaire, with the four piles.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#008000"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .card:
				Style()
					.frame(width: .rootEm(2.75), height: .rootEm(3.75))
					.margin(0)
					.padding(.rootEm(0.25))
					.background(.white)
					.border(.black)
					.cornerRadius(.rootEm(0.25))
					.fontFamily(.system)
					.font(.large, weight: .bold)
					.lineHeight(1)
					.color(.black)
			case .redCard:
				Styles.card.style.color(Color("#cc0000"))
			case .defrag:
				// The hard drive as rows of blocks, like the details of the defragmenter of Windows 98.
				Style()
					.grid(columns: 20)
					.gap(.pixels(1))
					.padding(.pixels(2))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .defragBlock:
				// Light blue for a part of a file, dark blue for a file that is done, green while it is read, and red while it is written. White is free space.
				Style()
					.aspectRatio(0.7)
					.background(.white)
					.border(Color("#c0c0c0"), width: .pixels(1))
					.when(.state, is: "fragment") {
						$0.background(Color("#00ffff"))
					}
					.when(.state, is: "done") {
						$0.background(Color("#0000aa"))
					}
					.when(.state, is: "read") {
						$0.background(Color("#00cc00"))
					}
					.when(.state, is: "write") {
						$0.background(Color("#ff0000"))
					}
			case .saverCanvas:
				Style()
					.position(.absolute)
					.inset(0)
					.display(.block)
					.frame(width: .percent(100), height: .percent(100))
			case .effectCanvas:
				// Over the whole window, without catching the pointer, so the page still works under the cards and the fireworks.
				Style()
					.position(.fixed)
					.inset(0)
					.zIndex(69)
					.frame(width: .percent(100), height: .percent(100))
					.allowsHitTesting(false)
					.reducedMotion {
						$0.hidden()
					}
			case .trailDot:
				// A ball of the elastic trail, or a number or a dot of the clock that follows the mouse pointer. `geocities.js` moves it, and gives it its look.
				Style()
					.position(.fixed)
					.leading(0)
					.top(0)
					.zIndex(61)
					.allowsHitTesting(false)
					.fontFamily(GeoCitiesPage.comicSans)
					.font(size: .rootEm(0.875), lineHeight: 1)
					.fontWeight(.bold)
					.reducedMotion {
						$0.hidden()
					}
			case .blueScreen:
				// The blue screen of Windows 98, over the whole window.
				Style()
					.position(.fixed)
					.inset(0)
					.zIndex(80)
					.hstack(alignment: .center, justification: .center)
					.overflow(.auto)
					.padding(.rootEm(1))
					.background(Color("#0000aa"))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.lineHeight(1.4)
					.color(.white)
					.cursor(.default)
			case .blueScreenTitle:
				Style()
					.frame(width: .rootEm(7))
					.margin(.horizontal, .auto)
					.background(GeoCitiesPage.windowGray)
					.color(Color("#0000aa"))
					.textAlign(.center)
			case .blueScreenText:
				Style()
					.frame(maxWidth: .rootEm(40))
					.flowSpacing(.rootEm(1))
			case .blueScreenList:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.leading, 0)
					.children("li") {
						$0.before {
							$0.content("*  ")
						}
					}
			case .blinkingCursor:
				Style().media(.allowsMotion) {
					$0.animation(Animations.blink, .timingCurve("steps(1, end)", duration: .seconds(1)).repeatForever(autoreverses: false))
				}
			case .bombScreen:
				// The gray screen of a crashed Mac, with the dialog of the bomb in the middle.
				Style()
					.position(.fixed)
					.inset(0)
					.zIndex(80)
					.hstack(alignment: .center, justification: .center)
					.padding(.rootEm(1))
					.backgroundImage(.radialGradient("circle at 50% 50%", Color("#9a9a9a"), Color("#5a5a5a")))
					.cursor(.default)
			case .bombDialog:
				Style()
					.hstack(alignment: .start, spacing: .rootEm(1))
					.flexWrap()
					.frame(maxWidth: .rootEm(28))
					.padding(.rootEm(1))
					.background(.white)
					.border(.black, width: .pixels(4), style: .double)
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: .black))
					.fontFamily(.system)
					.textStyle(.body)
					.color(.black)
					.children("div") {
						$0
							.flex(1)
							.frame(minWidth: .rootEm(12))
							.flowSpacing(.rootEm(0.5))
					}
			case .macButton:
				// The round button of the Mac, with the thick edge of the default button.
				Style()
					.margin(.leading, .auto)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(1.5))
					.background(.white)
					.border(.black, width: .pixels(3))
					.cornerRadius(.rootEm(0.5))
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.color(.black)
					.handCursor()
			case .shutDown:
				// The black screen with orange text, when Windows had shut down.
				Style()
					.position(.fixed)
					.inset(0)
					.zIndex(80)
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(1))
					.padding(.rootEm(1))
					.background(.black)
					.textAlign(.center)
					.color(Color("#ff8c00"))
					.cursor(.default)
			case .shutDownText:
				Style()
					.fontFamily(.system)
					.fluidFontSize(fromRem: 1.5, toRem: 2.5, between: .phone, and: .tablet)
					.fontWeight(.bold)
			case .partyGIF:
				Style().frame(width: .auto, height: .rootEm(5))
			case .partyCount:
				// The big numbers of the countdown to midnight.
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.fluidFontSize(fromRem: 3, toRem: 5, between: .phone, and: .tablet)
					.lineHeight(1)
					.color(Color("#cc0000"))
					.textShadow(Shadow(x: .pixels(3), y: .pixels(3), color: Color("#ffcc00")))
			case .monitor:
				// A beige monitor, with the screen saver on its screen, like the preview of the Display Properties.
				Style()
					.frame(width: .percent(100), maxWidth: .rootEm(11))
					.margin(.horizontal, .auto)
					.padding(top: .rootEm(0.75), horizontal: .rootEm(0.75), bottom: .rootEm(1.5))
					.backgroundImage(.linearGradient("to bottom", Color("#efe9d6"), Color("#cfc8b0")))
					.border(Color("#e8e2cc"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(0.5))
			case .monitorScreen:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(4.0 / 3.0)
					.background(.black)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .mouseGIF:
				Style().frame(width: .auto, height: .rootEm(2))
			case .scriptingOnly:
				Style().media(.scriptingDisabled) {
					$0.hidden()
				}
			}
		}
	}

	enum Animations: KeyframeSet {
		case spin
		case marquee
		case stripes
		case blink
		case sparkle
		case load
		case parade
		case rainbow
		case petBounce
		case petWiggle
		case petJump
		case petBackflip
		case petMoonwalk
		case petDance
		case petFloat
		case petHeart
		case bannerStar
		case saverFly
		case snowFall
		case ticker
		case bounce
		case spectrum
		case y2kShake
		case wiggle

		var keyframes: [Keyframe] {
			switch self {
			case .spin:
				[.to(Style().rotationEffect(.degrees(360)))]
			case .marquee:
				[.to(Style().offset(x: .percent(-100)))]
			case .stripes:
				[.to(Style().declaration(.backgroundPosition, "34px 0"))]
			case .blink:
				[.at(50, Style().opacity(0))]
			case .sparkle:
				[
					.to(
						Style()
							.opacity(0)
							.offset(x: .percent(-50), y: .percent(150))
							.rotationEffect(.degrees(270))
							.scaleEffect(0.2)
					),
				]
			case .load:
				[.from(Style().frame(height: .percent(100))), .to(Style().frame(height: 0))]
			case .parade:
				[.from(Style().offset(x: .viewportWidth(100))), .to(Style().offset(x: .percent(-100)))]
			case .rainbow:
				[.to(Style().filter(.hueRotation(.degrees(360)), .saturation(2)))]
			case .petBounce:
				[.to(Style().offset(y: .percent(-8)))]
			case .petWiggle:
				[.from(Style().rotationEffect(.degrees(-8))), .to(Style().rotationEffect(.degrees(8)))]
			case .petJump:
				[.to(Style().offset(y: .percent(-35)))]
			case .petBackflip:
				[
					.at(50, Style().offset(y: .percent(-40))),
					.to(Style().rotationEffect(.degrees(-360))),
				]
			case .petMoonwalk:
				[
					.at(25, Style().offset(x: .percent(-35))),
					.at(75, Style().offset(x: .percent(35))),
				]
			case .petDance:
				[
					.from(Style().rotationEffect(.degrees(-12)).offset(y: 0)),
					.to(Style().rotationEffect(.degrees(12)).offset(y: .percent(-12))),
				]
			case .petFloat:
				[.to(Style().offset(y: .rootEm(-0.5)).opacity(0.4))]
			case .petHeart:
				[.to(Style().offset(y: .rootEm(-5)).opacity(0).scaleEffect(1.6))]
			case .bannerStar:
				[.from(Style().offset(x: .containerInlineSize(2))), .to(Style().offset(x: .containerInlineSize(90)))]
			case .saverFly:
				[.from(Style().offset(x: .pixels(-120))), .to(Style().offset(x: .viewportWidth(105)))]
			case .snowFall:
				[
					.at(50, Style().offset(x: .rootEm(2), y: .viewportHeight(55)).rotationEffect(.degrees(180))),
					.to(Style().offset(x: 0, y: .viewportHeight(110)).rotationEffect(.degrees(360))),
				]
			case .ticker:
				[.from(Style().offset(y: .rootEm(7))), .to(Style().offset(y: .percent(-100)))]
			case .bounce:
				// 75% of the padding box of the sea, as `left: 75%` was: `cqi` is of its content box, which is narrower by the padding.
				[.to(Style().offset(x: .containerInlineSize(75) + .rootEm(0.75)))]
			case .spectrum:
				[.from(Style().frame(height: .percent(10))), .to(Style().frame(height: .percent(100)))]
			case .y2kShake:
				// Only sideways and up and down, as a rotation of the long page would swing its far ends out of the window.
				[
					.from(Style().offset(x: .pixels(-6), y: .pixels(2))),
					.to(Style().offset(x: .pixels(6), y: .pixels(-2))),
				]
			case .wiggle:
				// A small turn, as the wide dividers swing far at their ends.
				[.from(Style().rotationEffect(.degrees(-4))), .to(Style().rotationEffect(.degrees(4)))]
			}
		}
	}
}

extension Style {
	/**
	The hand pointer of old browsers, on a control of the 1999 page, like on its links.
	*/
	func handCursor() -> Self {
		cursor(GeoCitiesPage.handCursor, x: 5, fallback: .pointer)
	}

	/**
	The focus of a button of the 1999 page for the keyboard: a solid frame just inside its raised edge, in navy, the blue of the selection of Windows 98, instead of the faint dotted line of the panel. It is on the button and not around it, so it shows on the gray windows and on the dark boxes alike, and a window that scrolls does not cut it off.
	*/
	func buttonFocusRing(_ color: Color = Color("#000080")) -> Self {
		focusVisible {
			$0.focusRing(color, width: .pixels(2), offset: .pixels(-4))
		}
	}
}
