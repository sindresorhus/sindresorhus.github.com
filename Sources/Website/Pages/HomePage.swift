import Elementary
import Foundation
import SiteKit

struct HomePage: Page {
	var path: RoutePath {
		.root
	}

	var metadata: PageMetadata {
		PageMetadata(title: Site.name, description: Site.description)
	}

	var body: some HTML {
		section {
			// `home.js` loads `nebula.js` in dark mode, which draws a galaxy on it.
			canvas(.id(Hooks.nebula)) {}
				.accessibilityHidden()
				.style(Styles.nebula)

			div {
				div {
					div {
						img(.src(Site.author.photoPath), .alt("\(Site.author.name) profile photo"), .width(144), .height(144))
							.style(Styles.profilePhoto)
					}
					.style(Styles.profileRing)

					h1 {
						Site.name
					}
					.style(Styles.name)

					div {
						p {
							// Non-breaking hyphens, so “Open-Sourcerer” does not break at the hyphen on phones.
							span {
								Site.description.replacing("-", with: "\u{2011}")
							}
							.style(Styles.taglineText)
						}
						.style(Styles.tagline)

						div {
							div {
								a(.href(.apps)) {
									Label("Apps", icon: .appStore)
								}
								.style(Styles.button, Styles.glass, Styles.glassPrimary)
							}
							.style(Styles.action)

							div {
								a(.href("https://github.com/sindresorhus")) {
									Label("Code", icon: .github)
								}
								.style(Styles.button, Styles.glass, Styles.glassDark)
							}
							.style(Styles.action)
						}
						.hiddenFromSearchSnippets()
						.style(Styles.actions)
					}
					.style(Styles.text)
				}
				.style(Styles.content)
			}
			.style(Styles.container)
		}
		.style(Styles.root)

		ModuleScript("/scripts/home.js")

		JSONScript(schema: Schema.Person.authorProfile)

		// The name of the site in search results.
		JSONScript(schema: Schema.WebSite(name: Site.name, url: path.absoluteURL))
	}
}

extension HomePage {
	/**
	The IDs and data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case nebula = "nebula"
	}

	enum Styles: StyleSet {
		case root
		case nebula
		case container
		case content
		case profileRing
		case profilePhoto
		case name
		case text
		case tagline
		case taglineText
		case actions
		case action
		case button
		case glass
		case glassPrimary
		case glassDark

		var style: Style {
			switch self {
			case .root:
				Style()
					.position(.relative)
					.overflow(.hidden)
			case .nebula:
				Style()
					.position(.absolute)
					.inset(0)
					.hidden()
					.frame(width: .percent(100), height: .percent(100))
					.allowsHitTesting(false)
					.dark {
						$0
							.display(.block)
							.animation(Animations.nebulaFadeIn, .easeOut(duration: .seconds(3)), fillMode: .forwards)
					}
					.reducedMotion {
						$0.hidden()
					}
			case .container:
				Style()
					.display(.flex)
					.pageWidth()
					.padding(.horizontal, .pageGutter)
					.from(.tablet) {
						$0
							.frame(height: .smallViewportHeight(100))
							.margin(.top, .rootEm(-5))
					}
			case .content:
				Style()
					.margin(.auto)
					.padding(top: .rootEm(3), horizontal: 0, bottom: .rootEm(5.5))
					.textAlign(.center)
					.from(.tablet) {
						$0
							.padding(top: .rootEm(5), horizontal: 0, bottom: .rootEm(9))
					}
			case .profileRing:
				Style()
					.position(.relative)
					.display(.inlineFlex)
					.margin(.rootEm(2))
					.cornerRadius(.circle)
					// A rotating ring in the galaxy colors.
					.dark {
						$0
							.filter(.dropShadow(Shadow(y: 0, blur: .pixels(14), color: .primary(500).opacity(0.5))), .dropShadow(Shadow(y: 0, blur: .pixels(40), color: .violet(500).opacity(0.28))))
							.before {
								$0
									.content("")
									.position(.absolute)
									.inset(.pixels(-3))
									.cornerRadius(.circle)
									.backgroundImage(.conicGradient(.primary(500), .violet(500), .secondary(500), .violet(500), .primary(500)))
									.animation(Animations.ringRotate, .linear(duration: .seconds(10)).repeatForever(autoreverses: false))
							}
					}
					.media(.dark && .reducedMotion) {
						$0
							.before {
								$0.noAnimation()
							}
					}
			case .profilePhoto:
				Style()
					.position(.relative)
					.zIndex(1)
					.display(.block)
					.cornerRadius(.circle)
					.transition(.scaleEffect, animation: .default(duration: .milliseconds(350)))
					.maskImage(.radialGradient("circle", Color.black.at(.percent(80)), Color.transparent.at(.percent(100))))
					.hover {
						$0.scaleEffect(1.03)
					}
			case .name:
				// The expanded width of SF Pro on Apple platforms.
				Style()
					.margin(.bottom, .rootEm(1))
					.fontFamily(.expandable)
					.fontWidth(.expanded)
					.fluidFontSize(fromRem: 3, toRem: 3.5, between: .smallTablet, and: .tablet)
					.lineHeight(1)
					.bold()
					.letterSpacing(.em(-0.05))
					.color(.transparent)
					.setting(HomePage.gradientStart, to: .primary(500))
					.setting(HomePage.gradientEnd, to: Self.gradientColor(at: 25))
					.backgroundImage(.linearGradient("to right", HomePage.gradientStart.value, HomePage.gradientEnd.value, in: "oklch"))
					.backgroundClip(.text)
					.animation(Animations.gradientShift, .default(duration: .seconds(4)).repeatForever(autoreverses: false))
					.reducedMotion {
						$0.noAnimation()
					}
					.from(.smallTablet) {
						$0.textWrap(.nowrap)
					}
					.dark {
						$0.filter(.dropShadow(Shadow(y: 0, blur: .pixels(12), color: .primary(500).opacity(0.55))), .dropShadow(Shadow(y: 0, blur: .pixels(32), color: .violet(500).opacity(0.3))), .dropShadow(Shadow(y: 0, blur: .pixels(60), color: .secondary(500).opacity(0.15))))
					}
			case .text:
				Style()
					.frame(maxWidth: .rootEm(48))
					.margin(vertical: 0, horizontal: .auto)
			case .tagline:
				Style()
					.margin(.bottom, .rootEm(2.5))
					.font(.extraLarge)
					.color(.gray(600), dark: .gray(400))
			case .taglineText:
				Style()
					.fontFamily(.expandable)
					.fontWidth(.expanded)
					.font(.extraLarge2, weight: 350)
					.letterSpacing(.em(0.06))
					.dark {
						$0
							.color(.gray(200).opacity(0.82))
							.textShadow(Shadow(y: 0, blur: .pixels(28), color: Color.violet(500).opacity(0.28)))
					}
			case .actions:
				Style()
					.vstack(spacing: .rootEm(1.5))
					.margin(vertical: .rootEm(0.5), horizontal: 0)
					.padding(.horizontal, .rootEm(1.5))
					.from(.smallTablet) {
						$0
							.flexDirection(.row)
							.justifyContent(.center)
					}
			case .action:
				Style()
					.display(.flex)
					.frame(width: .percent(100))
					.from(.smallTablet) {
						$0.frame(width: .auto)
					}
			case .button:
				Style()
					.display(.inlineFlex)
					.alignItems(.center)
					.justifyContent(.center)
					.frame(width: .percent(100))
					.padding(vertical: .rootEm(1), horizontal: .rootEm(2))
					.cornerRadius(.rootEm(1.5))
					.fontWeight(.medium)
					.lineHeight(1.375)
					.textAlign(.center)
					.shadow(.large)
					.nested(Icon.selector) {
						$0
							.margin(.top, 0)
							.margin(.trailing, .rootEm(0.25))
							.margin(.bottom, 0)
							.margin(.leading, .rootEm(-0.375))
					}
					.from(.smallTablet) {
						$0.padding(vertical: .rootEm(0.75), horizontal: .rootEm(2))
					}
			case .glass:
				// Liquid glass buttons in dark mode.
				Style()
					.position(.relative)
					.overflow(.hidden)
					.color(.white)
					.transition(.background, .shadow, animation: .default(duration: .milliseconds(250))).transition(.offset, animation: .default(duration: .milliseconds(200))).transition(.borderColor, animation: .default(duration: .milliseconds(250)))
					.dark {
						$0
							.backdropFilter(.blur(radius: .pixels(20)), .saturation(1.8))
							// The solid backgrounds for reduced transparency are in the fills, as their backgrounds come later.
							.reducedTransparency {
								$0.backdropFilter(.none)
							}
							.before {
								$0
									.content("")
									.position(.absolute)
									.inset(0)
									.declaration(.borderRadius, .inherit)
									.backgroundImage(.linearGradient("175deg", Color.white.opacity(0.28).at(.percent(0)), Color.white.opacity(0.06).at(.percent(40)), Color.transparent.at(.percent(70))))
									.allowsHitTesting(false)
							}
					}
					.dark {
						$0
							.hover {
								$0.offset(y: .pixels(-1))
							}
					}
			case .glassPrimary:
				Style()
					.background(.primary(600), dark: .primary(500).opacity(0.22))
					.border(.lightDark(.primary(600).opacity(0.3), .primary(400).opacity(0.45)))
					.media(.dark && .reducedTransparency) {
						$0.background(.primary(700))
					}
					.hover {
						$0
							.background(.primary(700), dark: .primary(500).opacity(0.32))
							.borderColor(.primary(700), dark: .primary(400).opacity(0.6))
					}
					.dark {
						$0
							.shadow(Shadow(y: .pixels(1.5), color: .white.opacity(0.4), isInset: true), Shadow(y: .pixels(-1), color: .black.opacity(0.1), isInset: true), Shadow(y: .pixels(4), blur: .pixels(24), color: .primary(500).opacity(0.25)), Shadow(y: .pixels(1), blur: .pixels(4), color: .black.opacity(0.15)))
							.hover {
								$0.shadow(Shadow(y: .pixels(1.5), color: .white.opacity(0.5), isInset: true), Shadow(y: .pixels(-1), color: .black.opacity(0.1), isInset: true), Shadow(y: .pixels(8), blur: .pixels(32), color: .primary(500).opacity(0.35)), Shadow(y: .pixels(2), blur: .pixels(6), color: .black.opacity(0.15)))
							}
					}
			case .glassDark:
				Style()
					.background(.gray(900), dark: .gray(950).opacity(0.4))
					.border(.lightDark(.transparent, .white.opacity(0.16)))
					.media(.dark && .reducedTransparency) {
						$0.background(.gray(800))
					}
					.hover {
						$0
							.background(.gray(700), dark: .gray(950).opacity(0.55))
							.borderColor(.transparent, dark: .white.opacity(0.26))
					}
					.dark {
						$0
							.shadow(Shadow(y: .pixels(1.5), color: .white.opacity(0.25), isInset: true), Shadow(y: .pixels(-1), color: .black.opacity(0.15), isInset: true), Shadow(y: .pixels(4), blur: .pixels(20), color: .black.opacity(0.3)), Shadow(y: .pixels(1), blur: .pixels(4), color: .black.opacity(0.2)))
							.hover {
								$0.shadow(Shadow(y: .pixels(1.5), color: .white.opacity(0.35), isInset: true), Shadow(y: .pixels(-1), color: .black.opacity(0.15), isInset: true), Shadow(y: .pixels(8), blur: .pixels(28), color: .black.opacity(0.4)), Shadow(y: .pixels(2), blur: .pixels(6), color: .black.opacity(0.2)))
							}
					}
			}
		}

		/**
		A color of the brand gradient, from blue (0) to pink (100).
		*/
		fileprivate static func gradientColor(at percent: Int) -> Color {
			Color.primary(500).mix(with: .secondary(500), amount: .percent(Double(percent)))
		}
	}

	/**
	The colors at the ends of the gradient of the name. They are registered properties, so they can animate: the gradient moves from the blue end of the brand gradient to the pink end and back.
	*/
	fileprivate static let gradientStart = RegisteredProperty<Color>("--gradient-start", syntax: "<color>", initialValue: .black, inherits: false)
	fileprivate static let gradientEnd = RegisteredProperty<Color>("--gradient-end", syntax: "<color>", initialValue: .black, inherits: false)

	enum Animations: KeyframeSet {
		case nebulaFadeIn
		case ringRotate
		case gradientShift

		var keyframes: [Keyframe] {
			switch self {
			case .nebulaFadeIn:
				[
					.from(Style().opacity(0)),
					.to(Style().opacity(1)),
				]
			case .ringRotate:
				[.to(Style().rotationEffect(.degrees(360)))]
			case .gradientShift:
				[
					.at(50, Style()
						.setting(HomePage.gradientStart, to: HomePage.Styles.gradientColor(at: 75))
						.setting(HomePage.gradientEnd, to: .secondary(500))
					),
				]
			}
		}
	}
}
