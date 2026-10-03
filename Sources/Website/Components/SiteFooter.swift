import Elementary
import SiteKit

/**
Social links and a quote.
*/
struct SiteFooter: HTML {
	var body: some HTML {
		footer(.data("nosnippet", value: "")) {
			div {
				ul {
					for link in Site.author.socialLinks {
						li {
							IconLink(url: link.url.absoluteString, label: link.name, icon: link.icon, relationship: .rel("me"))
						}
					}
				}
				.style(Styles.socialLinks)

				div {
					q {
						"The people who are crazy enough to think they can change the world are the ones who do"
					}
					.style(Styles.quote)

					a(.href(Site.sourceURL.absoluteString)) {
						"Built with Swift"
					}
					.style(Styles.source)
				}
				.style(Styles.details)
			}
			.style(Styles.content)
		}
		.style(Styles.root)
	}

	enum Styles: StyleSet {
		case root
		case content
		case socialLinks
		case details
		case quote
		case source

		var style: Style {
			switch self {
			case .root:
				Style()
					.border(.top)
					.borderColor(.gray(200), dark: .slate(800))
			case .content:
				Style()
					.pageWidth()
					.padding(vertical: .rem(1.5), horizontal: .rem(1))
					.breakpoint(.sm) {
						$0.padding(.rem(1.5))
					}
					.breakpoint(.md) {
						$0
							.hstack(alignment: .center, justification: .spaceBetween)
							.padding(vertical: .rem(2), horizontal: .rem(1.5))
					}
			case .socialLinks:
				Style()
					.hstack(justification: .center)
					.margin(.bottom, .rem(1))
					.margin(.leading, .rem(-0.5))
					.breakpoint(.md) {
						$0
							.declaration(.order, 1)
							.margin(.bottom, 0)
							.margin(.leading, .rem(1))
					}
			case .details:
				Style()
					.hstack(alignment: .baseline, justification: .center, spacing: .rem(1))
					.font(.xs)
					.color(.gray(700), dark: .slate(400))
			case .quote:
				Style()
					.hidden(below: .md)
			case .source:
				Style()
					.noWrap()
					.opacity(0.7)
					.hover {
						$0
							.opacity(1)
							.underline()
					}
			}
		}
	}
}
