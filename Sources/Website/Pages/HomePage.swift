import Elementary
import Foundation
import SiteKit

struct HomePage: Page {
	let content: SiteContent

	var path: RoutePath {
		.root
	}

	/**
	The description says what Sindre makes, with the number of apps and their platforms, as the tagline of the page (``Site/description``) says little in search results. It counts the apps that a visitor can get, like the apps page lists them, not the archived ones.
	*/
	var metadata: PageMetadata {
		PageMetadata(
			title: Site.name,
			description: "Full-time open-source developer and app maker: \(content.activeApps.count.formatted(counting: "app")) for \(AppCategory.platformList(in: content)), and Node.js packages and CLI tools.",
			isTitleStandalone: true
		)
	}

	var body: some HTML {
		section {
			// `home.js` loads `nebula.js` in dark mode, which draws a galaxy on it.
			canvas(.id(IDs.nebula)) {}
				.accessibilityHidden()
				.style(Styles.nebula)

			div {
				div {
					div {
						// The small photo is sharp up to two pixels for each CSS pixel, so screens with three, like most phones, get the large one.
						img(
							.src(Site.author.smallPhotoPath),
							.srcset(.density([
								(.path(Site.author.smallPhotoPath), 2),
								(.path(Site.author.photoPath), 3),
							])),
							.alt("\(Site.author.name) profile photo"),
							.width(144),
							.height(144)
						)
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
							Site.description.replacing("-", with: "\u{2011}")
						}
						.style(Styles.tagline)

						div {
							a(.href(.apps)) {
								Label("Apps", icon: .appStore)
							}
							.style(Styles.button, Styles.glass, Styles.glassPrimary)

							a(.href(.openSource)) {
								Label("Code", icon: .github)
							}
							.style(Styles.button, Styles.glass, Styles.glassDark)
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

		ModuleScript(#path("/scripts/home.js"))

		JSONScript(schema: Schema.Person.authorProfile)

		// The name of the site in search results.
		JSONScript(schema: Schema.WebSite(name: Site.name, url: path.absoluteURL))
	}
}

extension HomePage {
	/**
	The IDs that the scripts of the page find elements by.
	*/
	enum IDs: String, ScriptIDSet {
		case nebula
	}

	enum Styles: String, StyleSet {
		case root
		case nebula
		case container
		case content
		case profileRing
		case profilePhoto
		case name
		case text
		case tagline
		case actions
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
					.inset(.zero)
					.hidden()
					.frame(size: .percent(100))
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
					.contentColumn(.page)
					// On phones, the margins are smaller with large text, so the name has more space.
					.below(.smallTablet) {
						$0.padding(.horizontal, .min(.pageGutter, .viewportWidth(6)))
					}
					.from(.tablet) {
						$0
							.frame(height: .smallViewportHeight(100))
							.margin(.top, .rootEm(-5))
					}
			case .content:
				// It can be narrower than its content, so with large text, the content wraps instead of going past the screen.
				Style()
					.frame(minWidth: .zero)
					.margin(.auto)
					.padding(top: .rootEm(3), horizontal: .zero, bottom: .rootEm(5.5))
					.textAlign(.center)
					.from(.tablet) {
						$0
							.padding(top: .rootEm(5), horizontal: .zero, bottom: .rootEm(9))
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
							.filter(.dropShadow(Shadow(y: .zero, blur: .pixels(14), color: .primary(500).opacity(0.5))), .dropShadow(Shadow(y: .zero, blur: .pixels(40), color: .violet(500).opacity(0.28))))
							.before {
								$0
									.content("")
									.position(.absolute)
									.inset(.pixels(-3))
									.cornerRadius(.circle)
									.backgroundImage(
										.conicGradient(
											.primary(500),
											.violet(500),
											.secondary(500),
											.violet(500),
											.primary(500)
										)
									)
									.animation(Animations.ringRotate, .linear(duration: .seconds(10)).repeatForever(autoreverses: false))
							}
					}
			case .profilePhoto:
				Style()
					.position(.relative)
					.zIndex(1)
					.cornerRadius(.circle)
					.transition(.scaleEffect, timing: .default(duration: .milliseconds(350)))
					.maskImage(.radialGradient(.circle, Color.black.at(.percent(80)), Color.transparent.at(.percent(100))))
					.hover {
						$0.scaleEffect(1.03)
					}
			case .name:
				// The expanded width of SF Pro on Apple platforms.
				Style()
					.margin(.bottom, .rootEm(1))
					.expandedFont()
					.fluidFontSize(
						fromRem: 3,
						toRem: 3.5,
						between: .smallTablet,
						and: .tablet
					)
					.lineHeight(1)
					.bold()
					.letterSpacing(.em(-0.05))
					.color(.transparent)
					.setting(HomePage.gradientStart, to: .primary(500))
					.setting(HomePage.gradientEnd, to: Self.gradientColor(at: 25))
					.backgroundImage(
						.linearGradient(
							.toRight,
							HomePage.gradientStart.value,
							HomePage.gradientEnd.value,
							in: .oklch
						)
					)
					.backgroundClip(.text)
					.animation(Animations.gradientShift, .default(duration: .seconds(4)).repeatForever(autoreverses: false))
					.from(.smallTablet) {
						$0.textWrap(.nowrap)
					}
					// On phones, as large as fits, so with large text, the longest word, “Sorhus” (3.64 em), stays on the screen.
					.below(.smallTablet) {
						$0.font(size: .min(.rootEm(3), .viewportWidth(24)))
					}
					.dark {
						$0.filter(.dropShadow(Shadow(y: .zero, blur: .pixels(12), color: .primary(500).opacity(0.55))), .dropShadow(Shadow(y: .zero, blur: .pixels(32), color: .violet(500).opacity(0.3))), .dropShadow(Shadow(y: .zero, blur: .pixels(60), color: .secondary(500).opacity(0.15))))
					}
			case .text:
				Style()
					.centeredColumn(.standard)
			case .tagline:
				// Centered lines of similar lengths, like a heading.
				Style()
					.margin(.bottom, .rootEm(2.5))
					.expandedFont()
					.font(.extraLarge2, weight: 350)
					// With large text, the longest word, “Open‑Sourcerer” (9.22 em), stays on the screen.
					.font(size: .min(TextSize.extraLarge2.size, .viewportWidth(9.5)))
					.letterSpacing(.em(0.06))
					.textWrap(.balance)
					.color(.gray(600), dark: .gray(200).opacity(0.82))
					.dark {
						$0.textShadow(Shadow(y: .zero, blur: .pixels(28), color: Color.violet(500).opacity(0.28)))
					}
			case .actions:
				Style()
					.vstack(spacing: .rootEm(1.5))
					.margin(vertical: .rootEm(0.5), horizontal: .zero)
					.padding(.horizontal, .rootEm(1.5))
					.from(.smallTablet) {
						$0
							.flexDirection(.row)
							.justifyContent(.center)
					}
			case .button:
				Style()
					.hstack(alignment: .center, justification: .center, isInline: true)
					// As wide as the column on phones.
					.frame(width: .percent(100))
					.from(.smallTablet) {
						$0.frame(width: .auto)
					}
					.padding(vertical: .rootEm(1), horizontal: .rootEm(2))
					.cornerRadius(.rootEm(1.5))
					.fontWeight(.medium)
					.lineHeight(1.375)
					.textAlign(.center)
					.shadow(.large)
					.nested(Icon.selector) {
						$0
							.margin(.trailing, .rootEm(0.25))
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
					.transition(
						.background,
						.shadow,
						.borderColor,
						timing: .default(duration: .milliseconds(250))
					)
					.transition(.offset, timing: .default(duration: .milliseconds(200)))
					.dark {
						$0
							.backdropFilter(.blur(radius: .pixels(20)), .saturation(1.8))
							// The solid backgrounds for reduced transparency are in the fills, as their backgrounds come later.
							.reducedTransparency {
								$0.backdropFilter()
							}
							.before {
								$0
									.content("")
									.position(.absolute)
									.inset(.zero)
									.inherits(.borderRadius)
									.backgroundImage(
										.linearGradient(
											.angle(.degrees(175)),
											Color.white.opacity(0.28).at(.percent(0)),
											Color.white.opacity(0.06).at(.percent(40)),
											Color.transparent.at(.percent(70))
										)
									)
									.allowsHitTesting(false)
							}
							.hoverOrFocusVisible {
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
					.hoverOrFocusVisible {
						$0
							.background(.primary(700), dark: .primary(500).opacity(0.32))
							.borderColor(.primary(700), dark: .primary(400).opacity(0.6))
					}
					.dark {
						$0
							.shadow(
								BoxShadow(y: .pixels(1.5), color: .white.opacity(0.4), isInset: true),
								BoxShadow(y: .pixels(-1), color: .black.opacity(0.1), isInset: true),
								BoxShadow(y: .pixels(4), blur: .pixels(24), color: .primary(500).opacity(0.25)),
								BoxShadow(y: .pixels(1), blur: .pixels(4), color: .black.opacity(0.15))
							)
							.hoverOrFocusVisible {
								$0.shadow(
									BoxShadow(y: .pixels(1.5), color: .white.opacity(0.5), isInset: true),
									BoxShadow(y: .pixels(-1), color: .black.opacity(0.1), isInset: true),
									BoxShadow(y: .pixels(8), blur: .pixels(32), color: .primary(500).opacity(0.35)),
									BoxShadow(y: .pixels(2), blur: .pixels(6), color: .black.opacity(0.15))
								)
							}
					}
			case .glassDark:
				Style()
					.background(.gray(900), dark: .gray(950).opacity(0.4))
					.border(.lightDark(.transparent, .white.opacity(0.16)))
					.media(.dark && .reducedTransparency) {
						$0.background(.gray(800))
					}
					.hoverOrFocusVisible {
						$0
							.background(.gray(700), dark: .gray(950).opacity(0.55))
							.borderColor(.transparent, dark: .white.opacity(0.26))
					}
					.dark {
						$0
							.shadow(
								BoxShadow(y: .pixels(1.5), color: .white.opacity(0.25), isInset: true),
								BoxShadow(y: .pixels(-1), color: .black.opacity(0.15), isInset: true),
								BoxShadow(y: .pixels(4), blur: .pixels(20), color: .black.opacity(0.3)),
								BoxShadow(y: .pixels(1), blur: .pixels(4), color: .black.opacity(0.2))
							)
							.hoverOrFocusVisible {
								$0.shadow(
									BoxShadow(y: .pixels(1.5), color: .white.opacity(0.35), isInset: true),
									BoxShadow(y: .pixels(-1), color: .black.opacity(0.15), isInset: true),
									BoxShadow(y: .pixels(8), blur: .pixels(28), color: .black.opacity(0.4)),
									BoxShadow(y: .pixels(2), blur: .pixels(6), color: .black.opacity(0.2))
								)
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
	fileprivate static let gradientStart = RegisteredProperty<Color>(
		"gradient-start",
		initialValue: .black,
		inherits: false
	)
	fileprivate static let gradientEnd = RegisteredProperty<Color>(
		"gradient-end",
		initialValue: .black,
		inherits: false
	)

	enum Animations: String, KeyframeSet {
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
					.at(
						50,
						Style()
						.setting(HomePage.gradientStart, to: HomePage.Styles.gradientColor(at: 75))
						.setting(HomePage.gradientEnd, to: .secondary(500))
					),
				]
			}
		}
	}
}
