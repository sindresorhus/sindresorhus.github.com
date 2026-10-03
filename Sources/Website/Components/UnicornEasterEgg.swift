import Elementary
import SiteKit

/**
A unicorn that gallops across the page after the Konami code (↑ ↑ ↓ ↓ ← → ← → B A). `site.js` listens for the keys and adds a copy of the template. Not for visitors who prefer reduced motion.
*/
struct UnicornEasterEgg: HTML {
	var body: some HTML {
		template(.id(.unicornTemplate)) {
			span {
				"🦄"
			}
			.accessibilityHidden()
			.style(Styles.unicorn)
		}
	}

	enum Styles: StyleSet {
		case unicorn

		var style: Style {
			// The emoji faces left, so it is mirrored to run to the right.
			Style()
				.position(.fixed)
				.bottom(.percent(12))
				.leading(0)
				.zIndex(50)
				.font(size: .rem(6), lineHeight: 1)
				.allowsHitTesting(false)
				.declaration(.scale, "-1 1")
				.animation(Animations.run, duration: .milliseconds(2800), curve: .linear, fillMode: .forwards)
				.reducedMotion {
					$0.hidden()
				}
		}
	}

	enum Animations: KeyframeSet {
		case run

		var keyframes: [Keyframe] {
			// Across the screen, with a hop at each stride.
			let strides = 6

			return (0...(strides * 2)).map { step in
				let progress = Double(step) / Double(strides * 2)
				let isUp = !step.isMultiple(of: 2)

				return .at(progress * 100, Style()
					.offset(x: Length("calc(\(CSSValue(floatLiteral: progress)) * (100vw + 8rem) - 8rem)"), y: isUp ? .rem(-2) : 0)
					.rotationEffect(.degrees(isUp ? -6 : 4))
				)
			}
		}
	}
}
