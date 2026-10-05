import Elementary
import SiteKit

/**
A unicorn that gallops across the page after the Konami code (↑ ↑ ↓ ↓ ← → ← → B A). `site.js` listens for the keys and adds a copy of the template. Not for visitors who prefer reduced motion.
*/
struct UnicornEasterEgg: HTML {
	var body: some HTML {
		template(.id(Hooks.unicornTemplate)) {
			span {
				span {
					"🦄"
				}
				.style(Styles.hop)
			}
			.accessibilityHidden()
			.style(Styles.unicorn)
		}
	}

	/**
	The IDs and data attributes that the scripts of the component find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case unicornTemplate = "unicorn-template"
	}

	enum Styles: StyleSet {
		case unicorn
		case hop

		var style: Style {
			switch self {
			case .unicorn:
				// Runs across the screen. `site.js` removes it when the run ends.
				Style()
					.position(.fixed)
					.bottom(.percent(12))
					.leading(0)
					.zIndex(50)
					.font(size: .rootEm(6), lineHeight: 1)
					.allowsHitTesting(false)
					.animation(Animations.run, .linear(duration: .milliseconds(2800)), fillMode: .forwards)
					.reducedMotion {
						$0.hidden()
					}
			case .hop:
				// A hop at each stride, six in the run. The emoji faces left, so it is mirrored to run to the right.
				Style()
					.display(.inlineBlock)
					.declaration(.scale, "-1 1")
					.animation(Animations.hop, .easeInOut(duration: .milliseconds(233)).repeatForever())
			}
		}
	}

	enum Animations: KeyframeSet {
		case run
		case hop

		var keyframes: [Keyframe] {
			switch self {
			case .run:
				[
					.from(Style().offset(x: .rootEm(-8))),
					.to(Style().offset(x: .viewportWidth(100))),
				]
			case .hop:
				[
					.from(Style().rotationEffect(.degrees(4))),
					.to(Style().offset(y: .rootEm(-2)).rotationEffect(.degrees(-6))),
				]
			}
		}
	}
}
