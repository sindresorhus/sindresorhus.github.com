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
			canvas(.id(.nebula)) {}
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
							span {
								Site.description
							}
							.style(Styles.taglineText)
						}
						.style(Styles.tagline)

						div(.data("nosnippet", value: "")) {
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
	}
}

extension HomePage {
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
					.display(.none)
					.frame(width: .percent(100), height: .percent(100))
					.allowsHitTesting(false)
					.dark {
						$0
							.display(.block)
							.animation(Animations.nebulaFadeIn, duration: .seconds(3), curve: .easeOut, fillMode: .forwards)
					}
					.reducedMotion {
						$0
							.important {
								$0.display(.none)
							}
					}
			case .container:
				Style()
					.display(.flex)
					.pageWidth()
					.padding(.horizontal, .rem(1))
					.breakpoint(.sm) {
						$0.padding(.horizontal, .rem(1.5))
					}
					.breakpoint(.md) {
						$0
							.frame(height: .svh(100))
							.margin(.top, .rem(-5))
					}
			case .content:
				Style()
					.margin(.auto)
					.padding(top: .rem(3), horizontal: 0, bottom: .rem(5.5))
					.textAlign(.center)
					.breakpoint(.md) {
						$0
							.padding(top: .rem(5), horizontal: 0, bottom: .rem(9))
					}
			case .profileRing:
				Style()
					.position(.relative)
					.display(.inlineFlex)
					.margin(.rem(2))
					.cornerRadius(.circle)
					// A rotating ring in the galaxy colors.
					.dark {
						$0
							.dropShadow(Shadow(y: 0, blur: .px(14), color: "rgb(59 130 246 / 50%)")).dropShadow(Shadow(y: 0, blur: .px(40), color: "rgb(139 92 246 / 28%)"))
							.before {
								$0
									.content("")
									.position(.absolute)
									.inset(.px(-3))
									.cornerRadius(.circle)
									.declaration(.background, CSSValue("conic-gradient(\(Color.primary(500)), \(Color.violet(500)), \(Color.secondary(500)), \(Color.violet(500)), \(Color.primary(500)))"))
									.animation(Animations.ringRotate, duration: .seconds(10), curve: .linear, repeats: true)
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
					.transition(.transform, duration: .milliseconds(350))
					.declaration(.maskImage, "radial-gradient(circle, #000 80%, transparent 100%)")
					.hover {
						$0.scaleEffect(1.03)
					}
			case .name:
				// The expanded width of SF Pro on Apple platforms.
				Style()
					.margin(.bottom, .rem(1))
					.fontFamily(.expandable)
					.fontWidth(.expanded)
					.font(.xl5, weight: .bold)
					.fluidFontSize(fromRem: 3, toRem: 3.5, between: .sm, and: .md)
					.letterSpacing(.em(-0.05))
					.color(.transparent)
					.setting(HomePage.gradientStart, to: CSSValue(Color.primary(500)))
					.setting(HomePage.gradientEnd, to: CSSValue(Self.gradientColor(at: 25)))
					.backgroundImage(CSSValue("linear-gradient(to right in oklch, \(HomePage.gradientStart.value), \(HomePage.gradientEnd.value))"))
					.declaration(.backgroundClip, "text")
					.animation(Animations.gradientShift, duration: .seconds(4), repeats: true)
					.reducedMotion {
						$0.noAnimation()
					}
					.breakpoint(.sm) {
						$0.noWrap()
					}
					.dark {
						$0.dropShadow(Shadow(y: 0, blur: .px(12), color: "rgb(59 130 246 / 55%)")).dropShadow(Shadow(y: 0, blur: .px(32), color: "rgb(139 92 246 / 30%)")).dropShadow(Shadow(y: 0, blur: .px(60), color: "rgb(236 72 153 / 15%)"))
					}
			case .text:
				Style()
					.frame(maxWidth: .rem(48))
					.margin(vertical: 0, horizontal: .auto)
			case .tagline:
				Style()
					.margin(.bottom, .rem(2.5))
					.font(.xl)
					.color(.gray(600), dark: .slate(400))
			case .taglineText:
				Style()
					.fontFamily(.expandable)
					.fontWidth(.expanded)
					.font(.xl2, weight: 350)
					.letterSpacing(.em(0.06))
					.dark {
						$0
							.color(.slate(200).opacity(0.82))
							.declaration(.textShadow, "0 0 28px rgb(139 92 246 / 28%)")
					}
			case .actions:
				Style()
					.vstack(spacing: .rem(1.5))
					.margin(vertical: .rem(0.5), horizontal: 0)
					.padding(.horizontal, .rem(1.5))
					.breakpoint(.sm) {
						$0
							.flexDirection(.row)
							.justifyContent(.center)
					}
			case .action:
				Style()
					.display(.flex)
					.frame(width: .percent(100))
					.breakpoint(.sm) {
						$0.frame(width: .auto)
					}
			case .button:
				Style()
					.display(.inlineFlex)
					.alignItems(.center)
					.justifyContent(.center)
					.frame(width: .percent(100))
					.padding(vertical: .rem(1), horizontal: .rem(2))
					.cornerRadius(.rem(1.5))
					.fontWeight(.medium)
					.lineHeight(1.375)
					.textAlign(.center)
					.shadow(.large)
					.nested(Icon.selector) {
						$0
							.margin(.top, 0)
							.margin(.trailing, .rem(0.25))
							.margin(.bottom, 0)
							.margin(.leading, .rem(-0.375))
					}
					.breakpoint(.sm) {
						$0.padding(vertical: .rem(0.75), horizontal: .rem(2))
					}
			case .glass:
				// Liquid glass buttons in dark mode.
				Style()
					.position(.relative)
					.overflow(.hidden)
					.color(.white)
					.transition(.background, .shadow, duration: .milliseconds(250)).transition(.transform, duration: .milliseconds(200)).transition(.borderColor, duration: .milliseconds(250))
					.dark {
						$0
							.backdropFilter("blur(20px) saturate(180%)")
							// The solid backgrounds for reduced transparency are in the fills, as their backgrounds come later.
							.reducedTransparency {
								$0.declaration(.backdropFilter, .none)
							}
							.before {
								$0
									.content("")
									.position(.absolute)
									.inset(0)
									.declaration(.borderRadius, .inherit)
									.declaration(.background, "linear-gradient(175deg, rgb(255 255 255 / 28%) 0%, rgb(255 255 255 / 6%) 40%, transparent 70%)")
									.allowsHitTesting(false)
							}
					}
					.dark {
						$0
							.hover {
								$0.offset(y: .px(-1))
							}
					}
			case .glassPrimary:
				Style()
					.background(.primary(600).opacity(0.9), dark: .primary(500).opacity(0.22))
					.border(.primary(600).opacity(0.3))
					.media(.dark && .reducedTransparency) {
						$0.background(.primary(700))
					}
					.hover {
						$0
							.background(.primary(700))
							.borderColor(.primary(700))
					}
					.dark {
						$0
							.border("rgb(99 160 255 / 45%)")
							.shadow(Shadow(y: .px(1.5), color: "rgb(255 255 255 / 40%)", isInset: true), Shadow(y: .px(-1), color: "rgb(0 0 0 / 10%)", isInset: true), Shadow(y: .px(4), blur: .px(24), color: "rgb(59 130 246 / 25%)"), Shadow(y: .px(1), blur: .px(4), color: "rgb(0 0 0 / 15%)"))
					}
					.dark {
						$0
							.hover {
								$0
									.background(.primary(500).opacity(0.32))
									.borderColor("rgb(120 180 255 / 60%)")
									.shadow(Shadow(y: .px(1.5), color: "rgb(255 255 255 / 50%)", isInset: true), Shadow(y: .px(-1), color: "rgb(0 0 0 / 10%)", isInset: true), Shadow(y: .px(8), blur: .px(32), color: "rgb(59 130 246 / 35%)"), Shadow(y: .px(2), blur: .px(6), color: "rgb(0 0 0 / 15%)"))
							}
					}
			case .glassDark:
				Style()
					.background(.gray(900), dark: "rgb(10 15 30 / 40%)")
					.border(.transparent)
					.media(.dark && .reducedTransparency) {
						$0.background(.slate(800))
					}
					.hover {
						$0.background(.gray(700))
					}
					.dark {
						$0
							.border(.white.opacity(0.16))
							.shadow(Shadow(y: .px(1.5), color: "rgb(255 255 255 / 25%)", isInset: true), Shadow(y: .px(-1), color: "rgb(0 0 0 / 15%)", isInset: true), Shadow(y: .px(4), blur: .px(20), color: "rgb(0 0 0 / 30%)"), Shadow(y: .px(1), blur: .px(4), color: "rgb(0 0 0 / 20%)"))
					}
					.dark {
						$0
							.hover {
								$0
									.background("rgb(10 15 30 / 55%)")
									.borderColor(.white.opacity(0.26))
									.shadow(Shadow(y: .px(1.5), color: "rgb(255 255 255 / 35%)", isInset: true), Shadow(y: .px(-1), color: "rgb(0 0 0 / 15%)", isInset: true), Shadow(y: .px(8), blur: .px(28), color: "rgb(0 0 0 / 40%)"), Shadow(y: .px(2), blur: .px(6), color: "rgb(0 0 0 / 20%)"))
							}
					}
			}
		}

		/**
		A color of the brand gradient, from blue (0) to pink (100).
		*/
		fileprivate static func gradientColor(at percent: Int) -> Color {
			Color("color-mix(in oklch, \(Color.primary(500)), \(Color.secondary(500)) \(percent)%)")
		}
	}

	/**
	The colors at the ends of the gradient of the name. They are registered properties, so they can animate: the gradient moves from the blue end of the brand gradient to the pink end and back.
	*/
	fileprivate static let gradientStart = RegisteredProperty("--gradient-start", syntax: "<color>", initialValue: CSSValue(Color.black), inherits: false)
	fileprivate static let gradientEnd = RegisteredProperty("--gradient-end", syntax: "<color>", initialValue: CSSValue(Color.black), inherits: false)

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
						.setting(HomePage.gradientStart, to: CSSValue(HomePage.Styles.gradientColor(at: 75)))
						.setting(HomePage.gradientEnd, to: CSSValue(Color.secondary(500)))
					),
				]
			}
		}
	}
}
