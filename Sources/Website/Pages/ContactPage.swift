import Elementary
import Foundation
import SiteKit

struct ContactPage: Page {
	var path: RoutePath {
		.contact
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Contact", description: "How to contact Sindre Sorhus.")
	}

	var headerBackground: SiteHeader.Background {
		.transparentAtTop
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
						a(.id(Hooks.email), .href("mailto:\(Site.author.email)")) {
							// Each letter animates on its own (`contact.js`). The parts do not break across lines.
							for part in Self.emailParts {
								span {
									for character in part {
										span(.hook(Hooks.letter)) {
											String(character)
										}
										.style(Styles.letter)
									}
								}
								.style(Styles.emailPart)
							}
						}
						.accessibilityLabel(Site.author.email)
						.style(Styles.email)
					}
					.style(Styles.tilt)

					CopyButton(title: "Copy", text: Site.author.email)
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
						"App queries → use "
						Link("in-app feedback", destination: .path(.feedback))
							.style(Styles.notesLink)
					}
				}
				.style(Styles.reveal, Styles.notes)
			}
			.style(Styles.center)
		}
		.style(Styles.root)

		// The sparkles of a click on the email address.
		template(.id(Hooks.sparkleTemplate)) {
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
	fileprivate static let hue = RegisteredProperty<CSSValue>("--hue", syntax: "<number>", initialValue: 0)

	/**
	The hue of a letter: the hue of the rainbow, plus the place of the letter in the address.
	*/
	fileprivate static let letterHue = StyleVariable<CSSValue>("--letter-hue")

	/**
	The number of letters before the part of the address, so the letters after the `@` continue the count.
	*/
	fileprivate static let letterOffset = StyleVariable<CSSValue>("--offset")

	/**
	Where the click of a sparkle was, and its size. `contact.js` sets them.
	*/
	fileprivate static let sparkleStartX = StyleVariable<Length>("--start-x")
	fileprivate static let sparkleStartY = StyleVariable<Length>("--start-y")
	fileprivate static let sparkleSize = StyleVariable<Length>("--size")

	/**
	Where a sparkle flies, from the click. `contact.js` sets them.
	*/
	fileprivate static let sparkleX = StyleVariable<Length>("--x")
	fileprivate static let sparkleY = StyleVariable<Length>("--y")

	/**
	How far between blue and pink the color of a sparkle is, like `30%`. `contact.js` sets it.
	*/
	fileprivate static let sparkleColorMix = StyleVariable<CSSValue>("--mix")

	/**
	How much the address tilts toward the pointer, from -0.5 to 0.5 on each axis. `contact.js` sets them.
	*/
	fileprivate static let tiltX = StyleVariable<CSSValue>("--tilt-x")
	fileprivate static let tiltY = StyleVariable<CSSValue>("--tilt-y")

	/**
	How close the pointer is to a letter, from 0 to 1. `contact.js` sets it.
	*/
	fileprivate static let letterStrength = StyleVariable<CSSValue>("--strength")

	/**
	The IDs and data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case email = "contact-email"
		case leaving = "data-leaving"
		case letter = "data-letter"
		case rainbow = "data-rainbow"
		case sparkleTemplate = "sparkle-template"
	}

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
		case notesLink
		case sparkle

		var style: Style {
			switch self {
			case .root:
				// The content is centered in the visible area below the header, which is see-through at the top of this page, so the colored light continues behind it without an edge.
				Style()
					.position(.relative)
					.hstack(alignment: .center, justification: .center)
					.frame(minHeight: Length.dynamicViewportHeight(100) - SiteHeader.height)
					.padding(top: 0, horizontal: .pageGutter, bottom: SiteHeader.height)
					.overflow(.hidden)
			case .orb:
				// Colored light in the background.
				Style()
					.position(.fixed)
					.zIndex(0)
					.cornerRadius(.circle)
					.opacity(0.055)
					.filter(.blur(radius: .pixels(140)))
					.allowsHitTesting(false)
					.dark {
						$0.opacity(0.14)
					}
			case .blueOrb:
				// Each orb stops for reduced motion in its own case, as a later case with an animation wins over the shared one.
				Style()
					.top(.percent(-20))
					.trailing(.percent(-20))
					.frame(width: .pixels(700), height: .pixels(700))
					.background(.primary(500))
					.animation(Animations.driftA, .easeInOut(duration: .seconds(18)).repeatForever())
					.reducedMotion {
						$0.noAnimation()
					}
			case .pinkOrb:
				Style()
					.bottom(.percent(-20))
					.leading(.percent(-20))
					.frame(width: .pixels(600), height: .pixels(600))
					.background(.secondary(500))
					.animation(Animations.driftB, .easeInOut(duration: .seconds(13)).repeatForever())
					.reducedMotion {
						$0.noAnimation()
					}
			case .center:
				Style()
					.position(.relative)
					.zIndex(10)
					.frame(width: .percent(100))
					.margin(.top, .rootEm(-4))
					.textAlign(.center)
			case .reveal:
				// The parts fade in one after the other. The first part is the second child, after the hidden title.
				Style()
					.animation(Animations.reveal, .timingCurve(0.22, 1, 0.36, 1, duration: .milliseconds(800)), fillMode: .both)
					.declaration(.animationDelay, "calc((sibling-index() - 2) * 100ms)")
					.reducedMotion {
						$0.noAnimation()
					}
			case .eyebrow:
				Style()
					.margin(.bottom, .rootEm(2))
					.fontFamily(.monospace)
					.font(.extraSmall)
					.letterSpacing(.em(0.1))
					.textCase(.uppercase)
					// Like the notes, darker than the secondary text in light mode, as the tinted background is darker than white.
					.color(.lightDark(.gray(600), .secondaryText))
			case .emailContainer:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(1.25))
					.margin(.bottom, .rootEm(2.5))
			case .tilt:
				Style()
					.display(.block)
					.declaration(.perspective, .pixels(800))
			case .email:
				// The outline helps the rainbow colors stand out on a light background. `contact.js` tilts it toward the pointer with `--tilt-x` and `--tilt-y`, and sets `data-rainbow` while the pointer is on the page. On touch screens, the rainbow always turns.
				Style()
					.display(.block)
					.font(size: .clamp(.rootEm(2), .viewportWidth(10), .rootEm(100)), lineHeight: 1)
					.fontWidth(.expanded)
					.bold()
					.letterSpacing(.em(-0.025))
					.color(.inherit)
					// Only the outer half of the stroke shows, so it is twice as wide.
					.textStroke(.black.opacity(0.18), width: .pixels(2))
					.declaration(.transformStyle, "preserve-3d")
					.transform(CSSValue("rotateX(calc(\(ContactPage.tiltX.value(default: 0)) * 1deg)) rotateY(calc(\(ContactPage.tiltY.value(default: 0)) * 1deg))"))
					.setting(ContactPage.hue, to: 0)
					// The rainbow only turns when the visitor allows motion.
					.media(.allowsMotion) {
						$0
							.when(Hooks.rainbow) {
								$0.animation(Animations.turnHue, .linear(duration: .seconds(6)).repeatForever(autoreverses: false))
							}
							.media(.cannotHover) {
								$0.animation(Animations.turnHue, .linear(duration: .seconds(6)).repeatForever(autoreverses: false))
							}
					}
					.from(.smallTablet) {
						$0.font(size: .clamp(.rootEm(2), .viewportWidth(5.8), .rootEm(100)))
					}
					.dark {
						$0.declaration(.webkitTextStroke, 0)
					}
			case .emailPart:
				// The letters after the `@` continue the count of the letters before it.
				Style()
					.display(.inlineBlock)
					.textWrap(.nowrap)
					.lastChild {
						$0.setting(ContactPage.letterOffset, to: CSSValue(integerLiteral: ContactPage.emailParts.first?.count ?? 0))
					}
			case .letter:
				// `contact.js` sets `--strength` (0 to 1) by how close the pointer is, which lifts and grows the letter, and `data-leaving` when the pointer moves away, which springs it back.
				Style()
					.display(.inlineBlock)
					.declaration(.transformOrigin, [.percent(50), .percent(85)])
					.transform(CSSValue("translateY(calc(\(ContactPage.letterStrength.value(default: 0)) * -22px)) scale(calc(1 + \(ContactPage.letterStrength.value(default: 0)) * 0.8)) translateZ(calc(\(ContactPage.letterStrength.value(default: 0)) * 55px))"))
					.transition(.transform, animation: .timingCurve(0.34, 1.56, 0.64, 1, duration: .milliseconds(80))).transition(.color, .textShadow, animation: .default(duration: .milliseconds(80)))
					.declaration(.willChange, "transform")
					.setting(ContactPage.letterHue, to: CSSValue("calc(\(ContactPage.hue.value) + (sibling-index() - 1 + \(ContactPage.letterOffset.value(default: 0))) * \(CSSValue(floatLiteral: 360 / Double(max(Self.letterCount, 1)))))"))
					.when(Hooks.leaving) {
						$0.transition(.transform, animation: .timingCurve("linear(0, .5 7.7%, .9 14.4%, 1.04 19.4%, 1.06 23.7%, 1.02 30%, 1 35%, .99 45%, 1)", duration: .milliseconds(600))).transition(.color, .textShadow, animation: .default(duration: .milliseconds(500)))
					}
					// The rainbow only turns when the visitor allows motion.
					.media(.allowsMotion) {
						$0
							.nested("\(Hooks.rainbow.selector()) &") {
								$0.combined(with: Self.rainbowLetter)
							}
							.media(.cannotHover) {
								$0.combined(with: Self.rainbowLetter)
							}
					}
					.reducedMotion {
						$0.nested("&, &\(Hooks.leaving.selector())") {
							$0.noTransition()
						}
					}
			case .notes:
				Style()
					.vstack(alignment: .center)
					.gap(row: .rootEm(0.25))
					.font(.extraSmall)
					// Darker than the secondary text in light mode, as the tinted background behind the small text is darker than white.
					.color(.lightDark(.gray(600), .secondaryText))
					.from(.smallTablet) {
						$0
							.flexDirection(.row)
							.flexWrap()
							.justifyContent(.center)
							.gap(column: .rootEm(2))
					}
			case .notesLink:
				Style().textLink()
			case .sparkle:
				// `contact.js` sets where the click was (`--start-x`, `--start-y`), where the sparkle flies (`--x`, `--y`), its size, and how far between blue and pink its color is (`--mix`). It flies out from the click as it appears.
				Style()
					.position(.fixed)
					.leading(ContactPage.sparkleStartX.value)
					.top(ContactPage.sparkleStartY.value)
					.zIndex(50)
					.frame(width: ContactPage.sparkleSize.value, height: ContactPage.sparkleSize.value)
					.cornerRadius(.circle)
					.background(Self.sparkleColor)
					.shadow(Shadow(y: 0, blur: ContactPage.sparkleSize.value * 2, color: Self.sparkleColor))
					.allowsHitTesting(false)
					.offset(x: .percent(-50) + ContactPage.sparkleX.value, y: .percent(-50) + ContactPage.sparkleY.value)
					.opacity(0)
					.transition(.offset, animation: .timingCurve(0.22, 1, 0.36, 1, duration: .milliseconds(750))).transition(.opacity, animation: .default(duration: .milliseconds(750)))
					.startingStyle {
						$0
							.offset(x: .percent(-50), y: .percent(-50))
							.opacity(1)
					}
			}
		}

		private static let sparkleColor = Color.primary(500).mix(with: .secondary(500), amount: ContactPage.sparkleColorMix.value(default: .percent(50)))

		private static var letterCount: Int {
			ContactPage.emailParts.map(\.count).reduce(0, +)
		}

		/**
		The color of a letter in the rainbow, with a glow.
		*/
		private static var rainbowLetter: Style {
			let color = Color.hsl(hue: ContactPage.letterHue.value, saturation: 1, lightness: 0.65)

			return Style()
				.color(color)
				.textShadow(Shadow(y: 0, blur: .pixels(20), color: color.opacity(0.65)), Shadow(y: 0, blur: .pixels(44), color: color.opacity(0.3)))
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
				[.to(Style().offset(x: .pixels(60), y: .pixels(50)).scaleEffect(1.1))]
			case .driftB:
				[.to(Style().offset(x: .pixels(-50), y: .pixels(-40)).scaleEffect(1.08))]
			case .reveal:
				[
					.from(Style()
						.opacity(0)
						.offset(y: .pixels(20))
						.filter(.blur(radius: .pixels(8)))
					),
				]
			case .turnHue:
				[.to(Style().setting(ContactPage.hue, to: 360))]
			}
		}
	}
}
