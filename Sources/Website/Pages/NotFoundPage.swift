import Elementary
import Foundation
import SiteKit

/**
The page for missing files. It suggests the closest page, like for a mistyped app name, and a random app.
*/
struct NotFoundPage: Page {
	/**
	The pages a visitor may have meant. A script picks the closest one to the requested path.
	*/
	let suggestedPaths: [RoutePath]

	let randomApp: App?

	var path: RoutePath {
		.notFound
	}

	var metadata: PageMetadata {
		PageMetadata(title: PageMetadata.titled("Error 404"))
	}

	var isInSitemap: Bool {
		false
	}

	var body: some HTML {
		section {
			div {
				div {
					h1 {
						VisuallyHidden("Error")
						" "
						GradientText("404")
					}
					.style(Styles.code)

					p {
						"The worker unicorns failed to find this page."
					}
					.style(Styles.title)

					p {
						"It was probably a bad idea anyway, so maybe for the better?"
					}
					.style(Styles.message)

					// `not-found.js` shows it when a page is close to the requested path.
					p(.id(.closestPage), .hidden) {
						"Did you mean "
						a(.id(.closestPageLink), .href("/")) {}
							.style(Styles.closestPageLink)
						"?"
					}
					.style(Styles.closestPage)

					Button("Back to homepage", destination: "/", fill: .dark)

					if let randomApp {
						p {
							"While you’re here, check out "
							a(.href(randomApp.path)) {
								randomApp.title
							}
							.style(Styles.randomAppLink)
							": \(randomApp.subtitle)."
						}
						.style(Styles.randomApp)
					}
				}
				.style(Styles.content)
			}
			.style(Styles.container)
		}
		.style(Styles.root)

		JSONScript(id: ScriptHook.notFoundData.rawValue, ["paths": suggestedPaths.map(\.description)])
		ModuleScript("/scripts/not-found.js")
	}
}

extension NotFoundPage {
	enum Styles: StyleSet {
		case root
		case container
		case content
		case code
		case title
		case message
		case closestPage
		case closestPageLink
		case randomApp
		case randomAppLink

		var style: Style {
			switch self {
			case .root:
				Style()
					.hstack(alignment: .center)
					.frame(minHeight: .svh(75))
			case .container:
				Style()
					.vstack(alignment: .center)
					.frame(width: .percent(100))
					.margin(.top, .rem(-5))
					.padding(.horizontal, .rem(1.25))
			case .content:
				Style()
					.frame(maxWidth: .rem(28))
					.textAlign(.center)
			case .code:
				Style()
					.margin(.bottom, .rem(1.5))
					.font(.xl8, weight: .bold)
					.fluidFontSize(fromRem: 6, toRem: 8, between: .phone, and: .sm)
			case .title:
				Style().font(.xl3, weight: .semibold)
			case .message:
				Style()
					.margin(top: .rem(1), horizontal: 0, bottom: .rem(2))
					.font(.lg)
					.color(.gray(600), dark: .slate(400))
			case .closestPage:
				Style()
					.margin(.bottom, .rem(2))
					.font(.lg, weight: .medium)
			case .closestPageLink:
				Style().underline(offset: .em(0.15))
			case .randomApp:
				Style()
					.margin(.top, .rem(3))
					.font(.sm)
					.color(.gray(500), dark: .slate(400))
			case .randomAppLink:
				Style()
					.fontWeight(.semibold)
					.color(.primaryText)
			}
		}
	}
}
