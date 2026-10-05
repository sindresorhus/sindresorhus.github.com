import Elementary
import Foundation
import SiteKit

/**
The page for missing files. It suggests the closest page, like for a mistyped app name, and a few apps that change every day.
*/
struct NotFoundPage: Page {
	/**
	The pages a visitor may have meant. A script picks the closest one to the requested path.
	*/
	let suggestedPaths: [RoutePath]

	let content: SiteContent

	var path: RoutePath {
		.notFound
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Error 404", isIndexed: false)
	}

	var body: some HTML {
		section {
			div {
				div {
					// The unicorn is the zero. Screen readers read “Error 404”.
					h1 {
						VisuallyHidden("Error 404")

						span {
							GradientText("4")

							span {
								"🦄"
							}
							.style(Styles.unicorn)

							GradientText("4")
						}
						.accessibilityHidden()
					}
					.style(Styles.code)

					p {
						"This page wandered off."
					}
					.style(Styles.title)

					p {
						"The unicorns looked everywhere, but it is not here. It may have moved, or it never existed."
					}
					.style(Styles.message)

					// `not-found.js` shows it when a page is close to the requested path.
					p(.id(Hooks.closestPage), .hidden) {
						"Did you mean "
						a(.id(Hooks.closestPageLink), .href(.root)) {}
							.style(Styles.closestPageLink)
						"?"
					}
					.style(Styles.closestPage)

					div {
						Link("Back to Homepage", destination: .path(.root))
							.buttonStyle(.primary)

						Link("Browse Apps", destination: .path(.apps))
							.buttonStyle(.secondary)
					}
					.style(Styles.buttons)
				}
				.style(Styles.content)

				let apps = content.randomApps(count: 4)

				if !apps.isEmpty {
					section {
						h2 {
							"While You’re Here"
						}
						.style(SectionStyles.label)

						AppGrid(apps: apps, content: content)
					}
					.style(Styles.apps)
				}
			}
			.style(Styles.container)
		}
		.style(Styles.root)

		// Not the home page, which is close to every short path, and already has a button.
		JSONScript(id: Hooks.data, ["paths": suggestedPaths.filter { $0 != .root }])
		ModuleScript("/scripts/not-found.js")
	}
}

extension NotFoundPage {
	/**
	The IDs and data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case closestPage = "closest-page"
		case closestPageLink = "closest-page-link"
		case data = "not-found-data"
	}

	enum Styles: StyleSet {
		case root
		case container
		case content
		case code
		case unicorn
		case title
		case message
		case closestPage
		case closestPageLink
		case buttons
		case apps

		var style: Style {
			switch self {
			case .root:
				Style()
					.hstack(alignment: .center)
					.frame(minHeight: .smallViewportHeight(75))
					.padding(vertical: .rootEm(4), horizontal: 0)
			case .container:
				// As wide as the content of the header, so the app cards line up with it, like on the other pages with app cards.
				Style()
					.vstack(alignment: .center)
					.frame(width: .percent(100))
					.contentColumn(.page)
			case .content:
				Style()
					.vstack(alignment: .center)
					.frame(maxWidth: .rootEm(30))
					.textAlign(.center)
			case .code:
				// Large, in the rounded font, like a sign.
				Style()
					.margin(.bottom, .rootEm(1.5))
					.fluidFontSize(fromRem: 6, toRem: 9, between: .phone, and: .smallTablet)
					.lineHeight(1)
					.fontFamily(.rounded)
					.bold()
					.letterSpacing(.em(-0.04))
			case .unicorn:
				// A little smaller than the digits, and tilted, as if it is looking around.
				Style()
					.display(.inlineBlock)
					.margin(.horizontal, .em(0.02))
					.font(size: .em(0.82))
					.rotationEffect(.degrees(-8))
			case .title:
				Style()
					.margin(0)
					.textStyle(.title)
					.color(.primaryText)
			case .message:
				Style()
					.margin(top: .rootEm(0.75), horizontal: 0, bottom: .rootEm(2))
					.secondaryText(.lead)
			case .closestPage:
				Style()
					.margin(.bottom, .rootEm(2))
					.textStyle(.lead, weight: .medium)
			case .closestPageLink:
				Style().textLink()
			case .buttons:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.75))
					.flexWrap()
			case .apps:
				// More space below than other sections, as the footer follows.
				Style()
					.frame(width: .percent(100))
					.margin(top: .rootEm(6), horizontal: 0, bottom: .rootEm(4))
			}
		}
	}
}
