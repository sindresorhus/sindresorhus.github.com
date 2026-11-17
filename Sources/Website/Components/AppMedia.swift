import Elementary
import Foundation
import SiteKit

/**
A horizontally scrolling carousel of videos and screenshots, with buttons at its sides and dots below it when there is more than one item, as the next item is not visible on wider screens. Its script wires up the buttons and the dots, and plays the videos.
*/
struct AppMedia: ScriptedElement {
	static let script = ElementScript()

	let app: App

	var content: some HTML {
		// Not a Tab stop, which browsers make a scroller without controls, as it has no focus look: the buttons and the dots move through the items, and one item has nothing to scroll to.
		// Screen readers announce it as a carousel of slides, like in the carousel pattern of ARIA.
		section(.part(Parts.scroller), .tabindex(-1), .ariaRoleDescription("carousel")) {
			for (index, asset) in app.media.enumerated() {
				// The item has the sizes of its media (`--max-width` and `--phone-width`), so it has its width before the media loads.
				div(.ariaRoleDescription("slide")) {
					// The width and height attributes give the natural size and the aspect ratio, so the media reserves its space before it loads, and is never shown larger than its natural size. On wider screens, it is at most 640px tall.
					switch asset {
					case .video(let videoAsset):
						// The script plays it while it is visible, unless the visitor prefers reduced motion. It can be paused with a click or the keyboard. The poster is its first frame, which shows while the video loads, and is the still frame with reduced motion. It also replaces the time in the URL (`#t=0.001`) that made iOS draw the first frame, which it otherwise does not with `preload="metadata"`.
						video(
							.src(asset.path),
							.loop,
							.muted,
							.playsInline,
							.preload(.metadata),
							.poster(videoAsset.poster),
							.tabindex(0)
						) {}
						.intrinsicSize(asset.size)
						.accessibilityLabel("\(app.title) demo video. Press to pause or play.")
						.style(Styles.media)
					case .image(let screenshot):
						// Numbered without the videos, which have their own label. The first item is in view when the page loads on a computer, so it loads at once instead of lazily. Not with a high priority, as on phones it is below the first screen, and the icon of the app is the largest image there.
						// The smaller JPEG XL copy, for browsers that show it.
						ScreenshotImage(
							asset: screenshot,
							alternativeText: "\(app.title) screenshot \(app.media[..<index].count(where: \.isImage) + 1)",
							loadsImmediately: index == 0
						) {
							$0.style(Styles.media)
						}
					}
				}
				.accessibilityLabel("\(index + 1) of \(app.media.count)", role: .group)
				// A video starts paused, so the play icon also shows without the script and with reduced motion, where it does not play. The script updates it when the video plays or pauses.
				.attributes(.state(States.paused), when: asset.isVideo)
				.style(Styles.item)
				.style {
					asset.settingSizes(
						on: $0,
						isOnlyItem: app.media.count == 1,
						phoneMaximumHeight: phoneMaximumHeight,
						firstSize: app.media[0].size
					)
				}
			}
		}
		.accessibilityLabel("App media")
		.style(Styles.scroller)

		// One item has nothing to scroll to, so it gets no buttons, as screen readers also read the disabled buttons that the styles hide.
		// Disabled until the script runs, as they need the script, so from desktops, where they always show, “Previous item” does not show at the first item before the script disables it.
		if app.media.count > 1 {
			button(.part(Parts.previous), .disabled) {
				Icon.chevronLeft.size(.rootEm(1.5))
			}
			.accessibilityLabel("Previous item")
			.style(Styles.control, Styles.previous)

			button(.part(Parts.next), .disabled) {
				Icon.chevronRight.size(.rootEm(1.5))
			}
			.accessibilityLabel("Next item")
			.style(Styles.control, Styles.next)

			// Hidden until the script shows them, as they need the script.
			div(.part(Parts.dots), .hidden) {
				for index in app.media.indices {
					button(.type(.button)) {}
						.accessibilityLabel("Show item \(index + 1) of \(app.media.count)")
						.style(Styles.dot)
				}
			}
			.style(Styles.dots)
		}
	}

	/**
	The largest width of an item on wider screens, which each item sets: its width at a height of at most 640 pixels, and not more than the width at the height of the first item.
	*/
	fileprivate static let maximumWidth = StyleVariable<LengthPercentage>("max-width")

	/**
	The width of an item on phones, which each item sets.
	*/
	fileprivate static let phoneWidth = StyleVariable<LengthPercentage>("phone-width")

	/**
	The maximum width of an item on phones, in percent of the width of the screen, so the next item shows at the side. The only item of a carousel has nothing to show at its side, so it is as wide as the text.
	*/
	fileprivate static let phoneItemWidth = 85.0

	/**
	The maximum height of an item on phones, in percent of the width of the screen: a quarter more than the height of the shortest item, the one with the widest shape, so a tall item, like a portrait screenshot next to landscape ones, is not much taller than the others, and the shorter items do not leave a large empty space below them. When the items have the same shape, it does not limit them. It is at least 60% of the width of the screen, so a very wide item does not make the others tiny.
	*/
	private var phoneMaximumHeight: Double {
		let widestAspectRatio = app.media.map(\.size.aspectRatio).max() ?? 1
		return max(Self.phoneItemWidth / widestAspectRatio * 1.25, 60)
	}

	enum Parts: String, ElementPartSet {
		case scroller
		case previous
		case next
		case dots
	}

	/**
	The states of an item. Not `:paused`, which Chrome 156 does not support (`CSS.supports("selector(:paused)")` is false), and the state also shows the play icon before the script runs.
	*/
	enum States: String, ElementStateSet {
		case paused
	}

	enum Styles: String, ElementStyleSet {
		case root
		case scroller
		case item
		case media
		case control
		case previous
		case next
		case dots
		case dot

		/**
		An icon in a dark circle in the middle of a video, like the play icon over a paused video. The video gets the click.

		- Parameter shapes: The white shapes of the icon, as SVG in a 64×64 box.
		*/
		private static func videoIcon(_ style: Style, shapes: String) -> Style {
			style
				.content("")
				.position(.absolute)
				.top(.percent(50))
				.leading(.percent(50))
				.frame(size: .rootEm(4))
				.offset(x: .percent(-50), y: .percent(-50))
				.backgroundImage(CSSImage.url(svg: "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'><circle cx='32' cy='32' r='32' fill='rgb(0 0 0 / 50%)'/>\(shapes)</svg>"))
				.allowsHitTesting(false)
		}

		/**
		Shows the buttons that are not disabled. The script disables the button at each end, which stays hidden.
		*/
		private static func showingControls(_ style: Style) -> Style {
			style.nested("\(control.selector):not(:disabled)") {
				$0.opacity(1)
			}
		}

		var style: Style {
			switch self {
			case .root:
				// Keyboard users see the buttons too. From desktops, the buttons are beside the item (``previous``, ``next``), where they cover nothing, so they always show, and a visitor sees that more items come.
				Style()
					.display(.block)
					.position(.relative)
					.centeredColumn(.wide)
					.hover(Self.showingControls)
					.focusWithin(Self.showingControls)
					.from(.desktop, Self.showingControls)
			case .scroller:
				// From tablets, the gap is wider than the padding, so the next item and its shadow do not show beside the current one, which can have another aspect ratio.
				// On phones, the items are at the top, so a row of items of other shapes starts at one line. From tablets, one item shows at a time, so a shorter item is in the middle of the row, which is as tall as the first item.
				// The padding above and below makes room for the shadows of the items, which the scrolling would cut off. The negative margins keep the space around the carousel.
				Style()
					.hstack(alignment: .start, spacing: .rootEm(1))
					.padding(top: .rootEm(1.5), horizontal: .rootEm(1.5), bottom: .rootEm(4))
					.margin(top: .rootEm(-1.5), horizontal: .zero, bottom: .rootEm(-4))
					.overflow(horizontal: .auto)
					.scrollSnapType(.horizontal, isMandatory: true)
					.scrollIndicators(.hidden)
					// A horizontal swipe on a trackpad at the end does not go back in the history.
					.overscrollBehavior(horizontal: .contain)
					.from(.tablet) {
						$0
							.gap(.rootEm(3))
							.alignItems(.center)
					}
			case .item:
				// A play icon over a paused video, like when the visitor prefers reduced motion, and a pause icon over a playing video under the pointer, with the pointer cursor, so the visitor knows that a click pauses it.
				Style()
					.position(.relative)
					.when(States.paused) {
						$0.after {
							Self.videoIcon($0, shapes: "<path d='M26 20v24l19-12z' fill='white'/>")
						}
					}
					.children("video") {
						$0.cursor(.pointer)
					}
					.media(.hover) {
						$0.nested("&:not(\(States.paused.selector)):has(video:hover)") {
							$0.after {
								Self.videoIcon($0, shapes: "<rect x='22' y='20' width='7' height='24' rx='1.5' fill='white'/><rect x='35' y='20' width='7' height='24' rx='1.5' fill='white'/>")
							}
						}
					}
					// On phones, the width of its media, so the next item shows at the side, also after a narrower item.
					.flexShrink(0)
					.frame(width: .length(AppMedia.phoneWidth.value))
					.scrollSnapAlign(.center)
					.from(.tablet) {
						$0
							.hstack(alignment: .center, justification: .center)
							.frame(width: .percent(100))
					}
			case .media:
				// A quiet fill while the image loads, so a slow screenshot is a gray tile, not an empty frame. The screenshots are JPEG, and the videos have posters, so the fill does not show through.
				Style()
					.margin(vertical: .zero, horizontal: .auto)
					.windowSurface()
					.background(.card)
					.from(.tablet) {
						$0.frame(maxWidth: .length(AppMedia.maximumWidth.value))
					}
			case .control:
				Style()
					.position(.absolute)
					.top(.percent(50))
					.zIndex(10)
					.hstack(alignment: .center, justification: .center)
					.frame(size: .rootEm(3))
					.cornerRadius(.capsule)
					.color(.bodyText)
					.frostedBackground(.lightDark(.white.opacity(0.4), .gray(900).opacity(0.4)), opaque: .lightDark(.white, .gray(900)), blur: .pixels(8))
					.shadow(.medium)
					.opacity(0)
					.offset(y: .percent(-50))
					.transition(.opacity, .backgroundColor, timing: .stateChange)
					// A stronger fill under the pointer, also when the visitor prefers reduced transparency.
					.hoverOrFocusVisible {
						$0.frostedBackground(.lightDark(.white.opacity(0.6), .gray(900).opacity(0.6)), opaque: .lightDark(.gray(100), .gray(800)), blur: .pixels(8))
					}
					.disabled {
						$0.allowsHitTesting(false)
					}
					// From desktops, the buttons are beside the item, on the page, where the dark see-through fill and the shadow do not show, so in dark mode they get the fill of a card and a faint light edge. Not over the item, where a light screenshot would show through the fill.
					.from(.desktop) {
						$0
							.frostedBackground(.lightDark(.white.opacity(0.4), .white.opacity(0.06)), opaque: .lightDark(.white, .gray(900)), blur: .pixels(8))
							.shadow(.medium + [.edge(.lightDark(.transparent, .white.opacity(0.1)))])
							.hoverOrFocusVisible {
								$0.frostedBackground(.lightDark(.white.opacity(0.6), .white.opacity(0.1)), opaque: .lightDark(.gray(100), .gray(800)), blur: .pixels(8))
							}
					}
					.hidden(below: .tablet)
			// From desktops, the page has space at the sides of the carousel, so the arrows are beside the item and do not cover it.
			case .previous:
				Style()
					.leading(.rootEm(2))
					.from(.desktop) {
						$0.leading(.rootEm(-3))
					}
			case .next:
				Style()
					.trailing(.rootEm(2))
					.from(.desktop) {
						$0.trailing(.rootEm(-3))
					}
			case .dots:
				// Above the padding of the scroller, which makes room for the shadows of the items and would otherwise take the clicks in Safari.
				Style()
					.hstack(alignment: .center, justification: .center)
					.position(.relative)
					.zIndex(1)
					.margin(.top, .rootEm(0.75))
			case .dot:
				// The button is larger than the dot, which is drawn inside it, so it is easy to tap, and at least 24px wide, the smallest target of WCAG 2.2. The buttons touch, so their tap areas do not overlap. The script marks the dot of the item in view with `aria-current`, which is a short pill in the accent, like the page controls of iOS, so the item in view is clear by its shape, not only by its color. Its button is 12px wider, so the space between the dots stays the same.
				// In whole pixels, so the dots are evenly spaced also where the root font size is larger, like on large screens.
				// The focus of the keyboard shows as a round fill around the dot, like on the icon buttons of the site, as the dot of the item in view already has the accent.
				Style()
					.frame(width: .pixels(24), height: .pixels(28))
					.media(.coarsePointer) {
						$0.frame(width: .pixels(28), height: .pixels(44))
					}
					.focusFill()
					.before {
						$0
							.content("")
							.display(.block)
							// In whole pixels, as a fractional size can snap to an oval. Capsule corners, so the pill has round ends while it grows.
							.frame(size: .pixels(8))
							.margin(.auto)
							.cornerRadius(.capsule)
							.background(.gray(300), dark: .gray(600))
							.transition(.backgroundColor, timing: .stateChange)
							// The pill grows from the dot, and the dots next to it move aside, but not when the visitor prefers reduced motion.
							.media(.allowsMotion) {
								$0.transition(.backgroundColor, .width, timing: .stateChange)
							}
					}
					.media(.allowsMotion) {
						$0.transition(.width, timing: .stateChange)
					}
					// Darker under the pointer, like the arrows next to the dots. The dot of the item in view keeps the accent, as its rule comes after.
					.hover {
						$0.before {
							$0.background(.gray(400), dark: .gray(500))
						}
					}
					.current {
						$0
							.frame(width: .pixels(36))
							.media(.coarsePointer) {
								$0.frame(width: .pixels(40))
							}
							.before {
								$0
									.frame(width: .pixels(20))
									.background(.accentMark)
							}
					}
			}
		}
	}
}

extension MediaAsset {
	/**
	The width at the largest height (``MediaAsset/maximumDisplayHeight``), for wider screens, and the width on phones: at most 85% of the screen, so the next item shows at the side, or as wide as the carousel for the only item, which then lines up with the text, and at most as tall as 70% of the screen and the maximum height of the carousel, so a tall item is not taller than most of the screen, nor much taller than the other items.

	On wider screens, an item that is narrower than the first item, like a portrait screenshot after a landscape one, is also at most as tall as the first item, so the first item, which shows when the page loads, has no empty space below it, as the row is as tall as its tallest item. An item that is wider than the first item does not change.

	- Parameters:
		- isOnlyItem: Whether the item is the only item of the carousel.
		- phoneMaximumHeight: The maximum height on phones, in percent of the width of the screen.
		- firstSize: The pixel size of the first item, which also limits the height when it is naturally smaller than the carousel.
	*/
	fileprivate func settingSizes(
		on style: Style,
		isOnlyItem: Bool,
		phoneMaximumHeight: Double,
		firstSize: PixelSize
	) -> Style {
		let largestWidth = LengthPercentage.pixels(maximumDisplayWidth)
		let phoneItemWidth: LengthPercentage = isOnlyItem ? .percent(100) : .viewportWidth(AppMedia.phoneItemWidth)
		let phoneWidth = LengthPercentage.min(
			phoneItemWidth,
			.viewportWidth(phoneMaximumHeight * size.aspectRatio),
			.smallViewportHeight(70 * size.aspectRatio),
			largestWidth
		)

		let heightLimitedWidth = if size.aspectRatio < firstSize.aspectRatio {
			min(maximumDisplayWidth, Double(firstSize.height) * size.aspectRatio)
		} else {
			maximumDisplayWidth
		}

		// In percent of the width of the item, which is the width of the carousel.
		let maximumWidth = LengthPercentage.min(
			.percent(100 * min(1, size.aspectRatio / firstSize.aspectRatio)),
			.pixels(heightLimitedWidth)
		)

		return style
			.setting(AppMedia.maximumWidth, to: maximumWidth)
			.setting(AppMedia.phoneWidth, to: phoneWidth)
	}
}
