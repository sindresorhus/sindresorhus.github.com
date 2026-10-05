import Elementary
import Foundation
import SiteKit

/**
The sponsors on the supporters page, by tier: logos, or a list of names for a tier without logos.

The Markdown of the page places it with `@Sponsors`, so it is rendered with the Markdown, and its styles are in the shared stylesheet.
*/
struct SponsorList: HTML {
	let tiers: [MarkdownPage.SponsorTier]

	var body: some HTML {
		for tier in tiers {
			h2 {
				"\(tier.title) "

				span {
					tier.price
				}
				.style(Styles.price)
			}

			if tier.sponsors.contains(where: { $0.logo != nil }) {
				div {
					for sponsor in tier.sponsors {
						a(.href(sponsor.url?.absoluteString ?? ""), .rel("nofollow")) {
							if let logo = sponsor.logo {
								// When the name is shown next to it, the logo is decorative, so screen readers read the name once.
								img(.src(logo.description), .alt(sponsor.showsName ? "" : sponsor.name), .width(sponsor.logoWidth ?? 0))
							}

							if sponsor.logo == nil || sponsor.showsName {
								span {
									sponsor.name
								}
								.style(Styles.name)
							}
						}
						.style(Styles.sponsor)
					}
				}
				.style(Styles.logos)
			} else {
				ul {
					for sponsor in tier.sponsors {
						li {
							if let url = sponsor.url {
								a(.href(.url(url))) {
									sponsor.name
								}
							} else {
								sponsor.name
							}
						}
					}
				}
			}
		}
	}

	enum Styles: StyleSet {
		case logos
		case sponsor
		case name
		case price

		var style: Style {
			switch self {
			case .logos:
				// Two columns, so the logos, which are mostly wide, have room to be large.
				Style()
					.grid(columns: 2)
					.gap(.rootEm(1))
			case .sponsor:
				// Every logo is in a box of the same size, on a light plate in both modes, as the logos are made for a light background. In dark mode, the plate is a little dimmer, so it does not glare. The logo fits inside, so wide and square logos look about as large.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.frame(height: .rootEm(6))
					.padding(vertical: .rootEm(1.25), horizontal: .rootEm(1.5))
					.from(.smallTablet) {
						$0.frame(height: .rootEm(8))
					}
					.cornerRadius(.boxRadius)
					.color(.gray(900))
					.background(.gray(50), dark: .gray(200))
					.shadow(Shadow(y: 0, spread: .pixels(1), color: .lightDark(.black.opacity(0.06), .white.opacity(0.1)), isInset: true))
					.underline(false)
					.nested("img") {
						$0
							.plainImage()
							.frame(width: .auto, height: .percent(100), minWidth: 0, maxWidth: .percent(100))
							.objectFit(.contain)
							// The plate shows through the white or light background that some logos have.
							.blendMode(.darken)
					}
			case .name:
				// A name in place of a logo, or next to a small logo, is about as large as the logos around it. On phones, the boxes are narrow, so it is smaller.
				Style()
					.textStyle(.headline)
					.textAlign(.center)
					.from(.smallTablet) {
						$0.font(size: .rootEm(2.25))
					}
			case .price:
				Style()
					.font(size: .rootEm(0.875))
					.letterSpacing(0)
			}
		}
	}
}
