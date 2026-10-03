import Elementary
import Foundation
import SiteKit

/**
A horizontally scrolling carousel of videos and screenshots. `app.js` wires up the buttons.
*/
struct AppMedia: HTML {
	let app: App

	var body: some HTML {
		div {
			section(.id(.appMedia), .ariaLabel("App media")) {
				for (index, asset) in app.media.enumerated() {
					div {
						// The width and height attributes give the natural size and the aspect ratio, so the media reserves its space before it loads, and is never shown larger than its natural size. On wider screens, it is at most 640px tall.
						switch asset.kind {
						case .video:
							// `app.js` plays it while it is visible, unless the visitor prefers reduced motion. It can be paused with a click or the keyboard.
							video(
								.src(asset.path),
								.width(asset.width),
								.height(asset.height),
								.loop,
								.muted,
								.playsInline,
								.preload(.metadata),
								.tabindex(0),
								.ariaLabel("\(app.title) demo video. Press to pause or play."),
								.style(asset.sizeStyle)
							) {}
							.style(Styles.media)
						case .image:
							img(.src(asset.path), .width(asset.width), .height(asset.height), .alt("\(app.title) screenshot \(index + 1)"), .lazyLoading, .asyncDecoding, .style(asset.sizeStyle))
								.style(Styles.media)
						}
					}
					.style(Styles.item)
				}
			}
			.style(Styles.scroller)

			button(.id(.mediaPrevious), .ariaLabel("Previous screenshot")) {
				Icon.chevronLeft.size(.rem(1.5))
			}
			.style(Styles.control, Styles.previous)

			button(.id(.mediaNext), .ariaLabel("Next screenshot")) {
				Icon.chevronRight.size(.rem(1.5))
			}
			.style(Styles.control, Styles.next)
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case scroller
		case item
		case media
		case control
		case previous
		case next

		var style: Style {
			switch self {
			case .root:
				Style()
					.position(.relative)
					.frame(maxWidth: .rem(64))
					.margin(top: 0, horizontal: .auto, bottom: .rem(5))
					// Keyboard users see the buttons too. `app.js` disables the button at each end, which stays hidden.
					.hover {
						$0.nested("\(Self.control.selector):not(:disabled)") {
							$0.opacity(1)
						}
					}
					.nested("&:focus-within \(Self.control.selector):not(:disabled)") {
						$0.opacity(1)
					}
			case .scroller:
				Style()
					.hstack(spacing: .rem(1))
					.padding(.horizontal, .rem(1.5))
					.overflow(horizontal: .auto)
					.declaration(.scrollSnapType, "x mandatory")
					.declaration(.scrollbarWidth, .none)
					// A horizontal swipe on a trackpad at the end does not go back in the history.
					.declaration("overscroll-behavior-x", "contain")
			case .item:
				Style()
					.flexShrink(0)
					.frame(width: .vw(85))
					.declaration(.scrollSnapAlign, .center)
					.breakpoint(.md) {
						$0
							.hstack(alignment: .center, justification: .center)
							.frame(width: .percent(100))
					}
			case .media:
				Style()
					.margin(vertical: 0, horizontal: .auto)
					.cornerRadius(.rem(0.375))
					.shadow(.large)
					.breakpoint(.md) {
						$0.frame(maxWidth: Length("min(100%, var(--max-width))"))
					}
					.focusVisible {
						$0.focusRing(.primary(500))
					}
			case .control:
				Style()
					.position(.absolute)
					.top(.percent(50))
					.zIndex(10)
					.display(.flex)
					.alignItems(.center)
					.justifyContent(.center)
					.frame(width: .rem(3), height: .rem(3))
					.cornerRadius(.capsule)
					.color(.gray(700), dark: .gray(200))
					.background(.white.opacity(0.4), dark: .gray(900).opacity(0.4))
					.backdropFilter("blur(8px)")
					.reducedTransparency {
						$0
							.background(.white, dark: .gray(900))
							.declaration(.backdropFilter, .none)
					}
					.shadow(.medium)
					.opacity(0)
					.offset(y: .percent(-50))
					.transition(.opacity, duration: .milliseconds(150))
					.cursor(.default)
					.disabled {
						$0.allowsHitTesting(false)
					}
					.hidden(below: .md)
			case .previous:
				Style().leading(.rem(2))
			case .next:
				Style().trailing(.rem(2))
			}
		}
	}
}

extension MediaAsset {
	/**
	The width at a height of at most 640 pixels, for wider screens.
	*/
	fileprivate var sizeStyle: String {
		let maximumWidth = min(Double(width), 640 * Double(width) / Double(height))
		let maximumWidthText = maximumWidth.rounded() == maximumWidth ? String(Int(maximumWidth)) : String(maximumWidth)
		return "--max-width: \(maximumWidthText)px"
	}
}
