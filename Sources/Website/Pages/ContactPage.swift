import Elementary
import Foundation
import SiteKit

struct ContactPage: Page {
	var path: RoutePath {
		.contact
	}

	var metadata: PageMetadata {
		PageMetadata(title: PageMetadata.titled("Contact"), description: "How to contact Sindre Sorhus.")
	}

	var body: some HTML {
		section {
			div {}
				.style(Styles.orb, Styles.blueOrb)

			div {}
				.style(Styles.orb, Styles.pinkOrb)

			div {
				// The design has no visible title.
				h1 {
					"Contact"
				}
				.style(VisuallyHidden.Styles.root)

				p {
					"say hello"
				}
				.style(Styles.reveal, Styles.eyebrow)

				div {
					div {
						a(.id(.contactEmail), .href("mailto:\(Site.author.email)"), .ariaLabel(Site.author.email)) {
							// Each letter animates on its own (`contact.js`). The parts do not break across lines.
							for part in Self.emailParts {
								span {
									for character in part {
										span {
											String(character)
										}
										.style(Styles.letter)
									}
								}
								.style(Styles.emailPart)
							}
						}
						.style(Styles.email)
					}
					.style(Styles.tilt)
				}
				.style(Styles.reveal, Styles.emailContainer)

				ul {
					li {
						"Keep it succinct"
					}

					li {
						"No calls or job offers"
					}

					li {
						"App queries → use in-app feedback"
					}
				}
				.style(Styles.reveal, Styles.notes)
			}
			.style(Styles.center)
		}
		.style(Styles.root)

		// The sparkles of a click on the email address.
		template(.id(.sparkleTemplate)) {
			span {}
				.style(Styles.sparkle)
		}

		ModuleScript("/scripts/contact.js")
	}

	/**
	The email address split before the `@`, like `sindresorhus` and `@gmail.com`.
	*/
	fileprivate static var emailParts: [Substring] {
		let email = Site.author.email
		let at = email.firstIndex(of: "@") ?? email.endIndex
		return [email[..<at], email[at...]]
	}
}

extension ContactPage {
	/**
	The hue of the rainbow, which turns while the pointer is on the page. Each letter adds its place in the address, so the colors go around once across it.
	*/
	fileprivate static let hue = RegisteredProperty("--hue", syntax: "<number>", initialValue: 0)

	enum Styles: StyleSet {
		case root
		case orb
		case blueOrb
		case pinkOrb
		case center
		case reveal
		case eyebrow
		case emailContainer
		case tilt
		case email
		case emailPart
		case letter
		case notes
		case sparkle

		var style: Style {
			switch self {
			case .root:
				// `contact.js` sets `--header-height`, so the content is centered in the visible area.
				Style()
					.position(.relative)
					.hstack(alignment: .center, justification: .center)
					.frame(minHeight: Length("calc(100dvh - var(--header-height, 0px))"))
					.padding(top: 0, horizontal: .rem(1.5), bottom: .variable("--header-height", fallback: 0))
					.overflow(.hidden)
			case .orb:
				// Colored light in the background.
				Style()
					.position(.fixed)
					.zIndex(0)
					.cornerRadius(.circle)
					.opacity(0.055)
					.blur(radius: .px(140))
					.allowsHitTesting(false)
					.dark {
						$0.opacity(0.14)
					}
			case .blueOrb:
				// Each orb stops for reduced motion in its own case, as a later case with an animation wins over the shared one.
				Style()
					.top(.percent(-20))
					.trailing(.percent(-20))
					.frame(width: .px(700), height: .px(700))
					.background(.primary(500))
					.animation(Animations.driftA, duration: .seconds(18), curve: .easeInOut, repeats: true, autoreverses: true)
					.reducedMotion {
						$0.noAnimation()
					}
			case .pinkOrb:
				Style()
					.bottom(.percent(-20))
					.leading(.percent(-20))
					.frame(width: .px(600), height: .px(600))
					.background(.secondary(500))
					.animation(Animations.driftB, duration: .seconds(13), curve: .easeInOut, repeats: true, autoreverses: true)
					.reducedMotion {
						$0.noAnimation()
					}
			case .center:
				Style()
					.position(.relative)
					.zIndex(10)
					.frame(width: .percent(100))
					.margin(.top, .rem(-4))
					.textAlign(.center)
			case .reveal:
				// The parts fade in one after the other. The first part is the second child, after the hidden title. Browsers without `sibling-index()` fade them in together.
				Style()
					.animation(Animations.reveal, duration: .milliseconds(800), curve: .cubicBezier(0.22, 1, 0.36, 1), fillMode: .both)
					.supports("(order: sibling-index())") {
						$0.declaration("animation-delay", "calc((sibling-index() - 2) * 100ms)")
					}
					.reducedMotion {
						$0.noAnimation()
					}
			case .eyebrow:
				Style()
					.margin(.bottom, .rem(2))
					.fontFamily(.monospace)
					.font(.xs)
					.letterSpacing(.em(0.1))
					.textCase(.uppercase)
					.opacity(0.35)
			case .emailContainer:
				Style().margin(.bottom, .rem(2.5))
			case .tilt:
				Style()
					.display(.block)
					.declaration(.perspective, .px(800))
			case .email:
				// The outline helps the rainbow colors stand out on a light background. `contact.js` tilts it toward the pointer with `--tilt-x` and `--tilt-y`, and sets `data-rainbow` while the pointer is on the page. On touch screens, the rainbow always turns.
				Style()
					.display(.block)
					.font(size: Length("clamp(2rem, 10vw, 100rem)"), lineHeight: 1)
					.fontWidth(.expanded)
					.bold()
					.letterSpacing(.em(-0.025))
					.color(.inherit)
					.declaration("-webkit-text-stroke", "1px rgb(0 0 0 / 18%)")
					.declaration(.transformStyle, "preserve-3d")
					.transform("rotateX(calc(var(--tilt-x, 0) * 1deg)) rotateY(calc(var(--tilt-y, 0) * 1deg))")
					.setting(ContactPage.hue, to: 0)
					.media(Self.rainbowMotion) {
						$0
							.nested("&[data-rainbow]") {
								$0.animation(Animations.turnHue, duration: .seconds(6), curve: .linear, repeats: true)
							}
							.media(.cannotHover) {
								$0.animation(Animations.turnHue, duration: .seconds(6), curve: .linear, repeats: true)
							}
					}
					.breakpoint(.sm) {
						$0.font(size: Length("clamp(2rem, 5.8vw, 100rem)"))
					}
					.dark {
						$0.declaration("-webkit-text-stroke", 0)
					}
			case .emailPart:
				// The letters after the `@` continue the count of the letters before it.
				Style()
					.display(.inlineBlock)
					.noWrap()
					.nested("&:last-child") {
						$0.declaration("--offset", CSSValue(integerLiteral: ContactPage.emailParts.first?.count ?? 0))
					}
			case .letter:
				// `contact.js` sets `--strength` (0 to 1) by how close the pointer is, which lifts and grows the letter, and `data-leaving` when the pointer moves away, which springs it back.
				Style()
					.display(.inlineBlock)
					.declaration(.transformOrigin, [.percent(50), .percent(85)])
					.transform("translateY(calc(var(--strength, 0) * -22px)) scale(calc(1 + var(--strength, 0) * 0.8)) translateZ(calc(var(--strength, 0) * 55px))")
					.transition(.transform, duration: .milliseconds(80), curve: .cubicBezier(0.34, 1.56, 0.64, 1)).transition(.color, .textShadow, duration: .milliseconds(80))
					.declaration(.willChange, "transform")
					.declaration("--letter-hue", ContactPage.hue.value)
					.supports("(order: sibling-index())") {
						$0.declaration("--letter-hue", CSSValue("calc(\(ContactPage.hue.value) + (sibling-index() - 1 + var(--offset, 0)) * \(CSSValue(floatLiteral: 360 / Double(max(Self.letterCount, 1)))))"))
					}
					.nested("&[data-leaving]") {
						$0.transition(.transform, duration: .milliseconds(600), curve: AnimationCurve("linear(0, .5 7.7%, .9 14.4%, 1.04 19.4%, 1.06 23.7%, 1.02 30%, 1 35%, .99 45%, 1)")).transition(.color, .textShadow, duration: .milliseconds(500), curve: .ease)
					}
					.media(Self.rainbowMotion) {
						$0
							.nested("[data-rainbow] &") {
								$0.combined(with: Self.rainbowLetter)
							}
							.media(.cannotHover) {
								$0.combined(with: Self.rainbowLetter)
							}
					}
					.reducedMotion {
						$0.nested("&, &[data-leaving]") {
							$0.noTransition()
						}
					}
			case .notes:
				Style()
					.vstack(alignment: .center)
					.gap(row: .rem(0.25))
					.font(.xs)
					.opacity(0.4)
					.breakpoint(.sm) {
						$0
							.flexDirection(.row)
							.flexWrap()
							.justifyContent(.center)
							.gap(column: .rem(2))
					}
			case .sparkle:
				// `contact.js` sets where the click was (`--start-x`, `--start-y`), where the sparkle flies (`--x`, `--y`), its size, and how far between blue and pink its color is (`--mix`). It flies out from the click as it appears.
				Style()
					.position(.fixed)
					.leading(.variable("--start-x"))
					.top(.variable("--start-y"))
					.zIndex(50)
					.frame(width: .variable("--size"), height: .variable("--size"))
					.cornerRadius(.circle)
					.declaration(.backgroundColor, CSSValue(Self.sparkleColor))
					.declaration(.boxShadow, CSSValue("0 0 calc(var(--size) * 2) \(Self.sparkleColor)"))
					.allowsHitTesting(false)
					.declaration(.translate, "calc(-50% + var(--x)) calc(-50% + var(--y))")
					.opacity(0)
					.transition(.transform, duration: .milliseconds(750), curve: .cubicBezier(0.22, 1, 0.36, 1)).transition(.opacity, duration: .milliseconds(750), curve: .ease)
					.startingStyle {
						$0
							.declaration(.translate, "-50% -50%")
							.opacity(1)
					}
			}
		}

		/**
		The rainbow only turns when the visitor allows motion.
		*/
		private static let rainbowMotion: MediaQuery = "(prefers-reduced-motion: no-preference)"

		private static let sparkleColor = "color-mix(in oklch, \(Color.primary(500)), \(Color.secondary(500)) var(--mix, 50%))"

		private static var letterCount: Int {
			ContactPage.emailParts.map(\.count).reduce(0, +)
		}

		/**
		The color of a letter in the rainbow, with a glow.
		*/
		private static var rainbowLetter: Style {
			let color = "hsl(var(--letter-hue) 100% 65%"

			return Style()
				.color(Color("\(color))"))
				.declaration(.textShadow, CSSValue("0 0 20px \(color) / 0.65), 0 0 44px \(color) / 0.3)"))
		}
	}

	enum Animations: KeyframeSet {
		case driftA
		case driftB
		case reveal
		case turnHue

		var keyframes: [Keyframe] {
			switch self {
			case .driftA:
				[.to(Style().offset(x: .px(60), y: .px(50)).scaleEffect(1.1))]
			case .driftB:
				[.to(Style().offset(x: .px(-50), y: .px(-40)).scaleEffect(1.08))]
			case .reveal:
				[
					.from(Style()
						.opacity(0)
						.offset(y: .px(20))
						.blur(radius: .px(8))
					),
				]
			case .turnHue:
				[.to(Style().setting(ContactPage.hue, to: 360))]
			}
		}
	}
}
