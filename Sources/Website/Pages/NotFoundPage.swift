import Elementary
import Foundation
import SiteKit

/**
The page for missing files. It suggests the closest page, like for a mistyped app name, and a few apps that change every day.
*/
struct NotFoundPage: Page {
	/**
	The pages a visitor may have meant, with their names (``Route/title``). A script picks the closest one to the requested path.
	*/
	let suggestedPages: [Route]

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

					div {
						// `not-found.js` shows it in place of the link to the home page when a page is close to the requested path, as that page is the most likely target.
						a(.id(IDs.closestPageLink), .href(.root), .hidden) {}
							.buttonStyle(.primary)
							// A long name, like the title of a guide, breaks into lines of about the same length.
							.style {
								$0.textWrap(.balance)
							}

						a(.id(IDs.homeLink), .href(.root)) {
							"Back to Homepage"
						}
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

						AppGrid(apps: apps, buildDate: content.buildDate)
					}
					.style(Styles.apps)
				}
			}
			.style(Styles.container)
		}
		.style(Styles.root)

		JSONScript(id: IDs.data, ScriptData(suggestedPages: suggestedPages, apps: content.activeAppsWithPages))
		ModuleScript(#path("/scripts/not-found.js"))
	}
}

extension NotFoundPage {
	/**
	The data of `not-found.js`.
	*/
	struct ScriptData: Encodable {
		/**
		The help of an app, for a path like `/dato/support` or `/dato/faq`.
		*/
		struct AppHelp: Encodable {
			let feedback: LinkDestination
			let faq: LinkDestination
		}

		/**
		A page that the visitor may have meant, with the text of the button that goes to it.
		*/
		struct SuggestedPage: Encodable {
			let path: RoutePath

			/**
			“Go to” and the name of the page, like “Go to Dato”, or for a guide or a post only its title, which is already long, like “How to Flush the DNS Cache on Mac”.
			*/
			let label: String

			init(route: Route) {
				let title = route.title ?? route.path.description
				// A guide or a post, like `/guides/flush-dns-cache-mac`, not the list of them.
				let isArticle = [RoutePath.guides, .blog].contains { route.path != $0 && route.path.starts(with: $0) }
				self.path = route.path
				self.label = isArticle ? title : "Go to \(title)"
			}
		}

		/**
		The pages that the visitor may have meant. Not the home page, which is close to every short path, and already has a button.
		*/
		let pages: [SuggestedPage]

		/**
		The feedback form, for a path like `/support`.
		*/
		let feedback: RoutePath

		/**
		The help of each app, by its slug.
		*/
		let apps: [String: AppHelp]

		/**
		The page of each platform by its other names, with and without `apps/`, like `/apps/ios` for `ipad` and `apps/ipad`.
		*/
		let platformPaths: [String: RoutePath]

		init(suggestedPages: [Route], apps: [App]) {
			self.pages = suggestedPages.filter { $0.path != .root }.map(SuggestedPage.init(route:))
			self.feedback = .feedback
			self.apps = Dictionary(uniqueKeysWithValues: apps.map { app in
				(
					app.slug.value,
					AppHelp(
						feedback: App.feedbackURL(appTitle: app.title),
						faq: app.faqDestination ?? .path(app.path)
					)
				)
			})
			self.platformPaths = Dictionary(uniqueKeysWithValues: AppCategory.allCases.flatMap { category in
				category.otherNames.flatMap { name in
					[(name, category.path), ("apps/\(name)", category.path)]
				}
			})
		}
	}

	/**
	The IDs that the scripts of the page find elements by.
	*/
	enum IDs: String, ScriptIDSet {
		case closestPageLink = "closest-page-link"
		case homeLink = "home-link"
		case data = "not-found-data"
	}

	enum Styles: String, StyleSet {
		case root
		case container
		case content
		case code
		case unicorn
		case title
		case message
		case buttons
		case apps

		var style: Style {
			switch self {
			case .root:
				Style()
					.hstack(alignment: .center)
					.frame(minHeight: .smallViewportHeight(75))
					.padding(vertical: .rootEm(4), horizontal: .zero)
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
					.fluidFontSize(
						fromRem: 6,
						toRem: 9,
						between: .phone,
						and: .smallTablet
					)
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
					.textStyle(.title)
					.color(.primaryText)
			case .message:
				Style()
					.margin(top: .rootEm(0.75), horizontal: .zero, bottom: .rootEm(2))
					.secondaryText(.lead)
					// The message is short and centered, so its lines have about the same length, and the last line is not only “never existed.”.
					.textWrap(.balance)
			case .buttons:
				// On phones, the buttons fill their line, so a long suggestion and “Browse Apps” below it have one width, and two short buttons share the line.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.75))
					.flexWrap()
					.below(.smallTablet) {
						$0
							.alignSelf(.stretch)
							.children("*") {
								$0.flexGrow(1)
							}
					}
			case .apps:
				// More space below than other sections, as the footer follows.
				Style()
					.frame(width: .percent(100))
					.margin(top: .rootEm(6), horizontal: .zero, bottom: .rootEm(4))
			}
		}
	}
}
