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
				div(.role("group"), .ariaRoleDescription("slide")) {
					// The width and height attributes give the natural size and the aspect ratio, so the media reserves its space before it loads, and is never shown larger than its natural size. On wider screens, it is at most 640px tall.
					switch asset.kind {
					case .video:
						// The script plays it while it is visible, unless the visitor prefers reduced motion. It can be paused with a click or the keyboard. The time in the URL makes iOS draw the first frame, which it otherwise does not with `preload="metadata"`.
						video(
							.src("\(asset.path)#t=0.001"),
							.width(asset.size.width),
							.height(asset.size.height),
							.loop,
							.muted,
							.playsInline,
							.preload(.metadata),
							.tabindex(0)
						) {}
						.accessibilityLabel("\(app.title) demo video. Press to pause or play.")
						.style(Styles.media)
					case .image:
						// Numbered without the videos, which have their own label. The first item is in view when the page loads on a computer, so it loads at once instead of lazily. Not with a high priority, as on phones it is below the first screen, and the icon of the app is the largest image there.
						let image = img(.src(asset.path), .width(asset.size.width), .height(asset.size.height), .alt("\(app.title) screenshot \(app.media[..<index].count { $0.kind == .image } + 1)"))
							.attributes(.lazyLoading, when: index > 0)
							.attributes(.asyncDecoding)
							.style(Styles.media)

						// The smaller JPEG XL copy, for browsers that show it.
						JPEGXLPicture(copy: asset.jpegXL) {
							image
						}
					}
				}
				.accessibilityLabel("\(index + 1) of \(app.media.count)")
				.style(Styles.item)
				.style {
					asset.settingSizes(on: $0, phoneMaximumHeight: phoneMaximumHeight)
				}
			}
		}
		.accessibilityLabel("App media")
		.style(Styles.scroller)

		// One item has nothing to scroll to, so it gets no buttons, as screen readers also read the disabled buttons that the styles hide.
		if app.media.count > 1 {
			button(.part(Parts.previous)) {
				Icon.chevronLeft.size(.rootEm(1.5))
			}
			.accessibilityLabel("Previous item")
			.style(Styles.control, Styles.previous)

			button(.part(Parts.next)) {
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
	The width of an item at a height of at most 640 pixels, which each item sets for wider screens.
	*/
	fileprivate static let maximumWidth = StyleVariable<Length>("--max-width")

	/**
	The width of an item on phones, which each item sets.
	*/
	fileprivate static let phoneWidth = StyleVariable<Length>("--phone-width")

	/**
	The maximum width of an item on phones, in percent of the width of the screen, so the next item shows at the side.
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

	enum Styles: ElementStyleSet {
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
				// Keyboard users see the buttons too.
				Style()
					.display(.block)
					.position(.relative)
					.centeredColumn(.wide)
					.hover(Self.showingControls)
					.focusWithin(Self.showingControls)
			case .scroller:
				// From tablets, the gap is wider than the padding, so the next item and its shadow do not show beside the current one, which can have another aspect ratio.
				// The items are at the top, so a landscape screenshot next to a portrait one starts below the content above, and the empty space is below it.
				// The padding above and below makes room for the shadows of the items, which the scrolling would cut off. The negative margins keep the space around the carousel.
				Style()
					.hstack(alignment: .start, spacing: .rootEm(1))
					.padding(top: .rootEm(1.5), horizontal: .rootEm(1.5), bottom: .rootEm(4))
					.margin(top: .rootEm(-1.5), horizontal: 0, bottom: .rootEm(-4))
					.overflow(horizontal: .auto)
					.scrollSnapType(.horizontal, isMandatory: true)
					.scrollIndicators(.hidden)
					// A horizontal swipe on a trackpad at the end does not go back in the history.
					.overscrollBehavior(horizontal: .contain)
					.from(.tablet) {
						$0.gap(.rootEm(3))
					}
			case .item:
				// A play icon over a paused video, like when the visitor prefers reduced motion. The video gets the click.
				Style()
					.position(.relative)
					.nested("&:has(> video:paused)::after") {
						$0
							.content("")
							.position(.absolute)
							.top(.percent(50))
							.leading(.percent(50))
							.frame(size: .rootEm(4))
							.offset(x: .percent(-50), y: .percent(-50))
							.declaration(.backgroundImage, #"url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Ccircle cx='32' cy='32' r='32' fill='rgb(0 0 0 / 50%25)'/%3E%3Cpath d='M26 20v24l19-12z' fill='white'/%3E%3C/svg%3E")"#)
							.allowsHitTesting(false)
					}
					// On phones, the width of its media, so the next item shows at the side, also after a narrower item.
					.flexShrink(0)
					.frame(width: AppMedia.phoneWidth.value)
					.scrollSnapAlign(.center)
					.from(.tablet) {
						$0
							.hstack(alignment: .center, justification: .center)
							.frame(width: .percent(100))
					}
			case .media:
				Style()
					.margin(vertical: 0, horizontal: .auto)
					.cornerRadius(.windowRadius)
					.shadow(.window)
					.from(.tablet) {
						$0.frame(maxWidth: .min(.percent(100), AppMedia.maximumWidth.value))
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
					.transition(.opacity, .backgroundColor, animation: .stateChange)
					// A stronger fill under the pointer, also when the visitor prefers reduced transparency.
					.hoverOrFocusVisible {
						$0.frostedBackground(.lightDark(.white.opacity(0.6), .gray(900).opacity(0.6)), opaque: .lightDark(.gray(100), .gray(800)), blur: .pixels(8))
					}
					.disabled {
						$0.allowsHitTesting(false)
					}
					.hidden(below: .tablet)
			case .previous:
				Style().leading(.rootEm(2))
			case .next:
				Style().trailing(.rootEm(2))
			case .dots:
				// Above the padding of the scroller, which makes room for the shadows of the items and would otherwise take the clicks in Safari.
				Style()
					.hstack(alignment: .center, justification: .center)
					.position(.relative)
					.zIndex(1)
					.margin(.top, .rootEm(0.75))
			case .dot:
				// The button is larger than the dot, which is drawn inside it, so it is easy to tap, and at least 24px wide, the smallest target of WCAG 2.2. The buttons touch, so their tap areas do not overlap. The script marks the dot of the item in view with `aria-current`.
				// The focus of the keyboard shows as a round fill around the dot, like on the icon buttons of the site, as the dot of the item in view already has the accent.
				Style()
					.frame(width: .rootEm(1.5), height: .rootEm(1.75))
					.media(.coarsePointer) {
						$0.frame(width: .rootEm(1.75), height: .rootEm(2.75))
					}
					.focusFill()
					.before {
						$0
							.content("")
							.display(.block)
							.frame(size: .rootEm(0.5))
							.margin(.auto)
							.cornerRadius(.circle)
							.background(.gray(300), dark: .gray(600))
							.transition(.backgroundColor, animation: .stateChange)
					}
					.current {
						$0.before {
							$0.background(.accentMark)
						}
					}
			}
		}
	}
}

extension MediaAsset {
	/**
	The width at a height of at most 640 pixels, for wider screens, and the width on phones: at most 85% of the screen, and at most as tall as 70% of the screen and the maximum height of the carousel, so a tall item is not taller than most of the screen, nor much taller than the other items.

	- Parameter phoneMaximumHeight: The maximum height on phones, in percent of the width of the screen.
	*/
	fileprivate func settingSizes(on style: Style, phoneMaximumHeight: Double) -> Style {
		let maximumWidth = Length.pixels(min(Double(size.width), 640 * size.aspectRatio))
		let phoneWidth = Length.min(.viewportWidth(AppMedia.phoneItemWidth), .viewportWidth(phoneMaximumHeight * size.aspectRatio), .smallViewportHeight(70 * size.aspectRatio), maximumWidth)

		return style
			.setting(AppMedia.maximumWidth, to: maximumWidth)
			.setting(AppMedia.phoneWidth, to: phoneWidth)
	}
}
