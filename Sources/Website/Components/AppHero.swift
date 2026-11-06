import Elementary
import Foundation
import SiteKit

/**
The top of an app page: the icon, the name, the subtitle, the introduction, the download buttons, the price, the platforms, a link to the privacy policy, and the links. The rating is in the app information (``AppFacts``), so the hero is not crowded.
*/
struct AppHero: HTML {
	/**
	The app with its fetched data, for the price and the requirement.
	*/
	let listing: AppListing

	/**
	The HTML of the first paragraph of the page, so visitors see what the app does before the screenshots.
	*/
	var introduction: MarkdownContent?

	/**
	When the site is built, for how long the app has been available.
	*/
	let buildDate: Date

	/**
	Whether the page has guides about the app, which the “…” menu links to.
	*/
	let hasGuides: Bool

	private var app: App {
		listing.app
	}

	var body: some HTML {
		header(.id(IDs.hero)) {
			AppIcon(
				app,
				size: 256,
				isAboveFold: true,
				imageID: IDs.icon.id
			)
				.style(Styles.icon)

			// The name of the app is not translated, so visitors find it on the App Store.
			h1(.notTranslated) {
				app.title
			}
			.style(Styles.title)

			p {
				app.subtitle
			}
			.style(Styles.subtitle)

			if let introduction {
				p {
					introduction
				}
				.style(Styles.introduction)
			}

			// Shown when coming from the random app page, which links to `#another-random-app`.
			div {
				Link(destination: .path(.randomApp)) {
					Label("Another Random App", icon: .shuffle)
				}
				.buttonStyle(.gradient)
				.style(Styles.anotherRandomAppButton)
			}
			.style(Styles.anotherRandomApp)

			if app.isArchived {
				div {
					Badge("Archived", kind: .archived)
				}
				.style(Styles.archivedBadge)
			}

			if !app.downloadOptions.isEmpty {
				DownloadOptions(app: app)
					.style {
						$0.margin(.top, .rootEm(2))
					}
			}

			if let downloadCount = app.downloadCount {
				p {
					span {
						downloadCount.value.approximateCount
					}
					.style(Styles.downloadCount)

					span {
						" downloads"
					}
					.style(Styles.downloadLabel)
				}
				.style(Styles.downloads)
			}

			// An archived app is no longer available, so it has no price, platforms, or privacy.
			if !app.isArchived {
				// The price on a line of its own, and the other facts on one line below it, so neither line is long. The facts are a list, so copied text, screen readers, and reader views get them apart, not run together.
				div {
					if let price = listing.priceText {
						p {
							price
						}
					}

					// Keep the list semantics in Safari, as the styles remove its bullets.
					ul(.role(.list)) {
						for fact in details {
							li {
								fact
							}
							.style(Styles.fact)
						}

						// It looks like the text around it, so the line stays quiet, and shows that it is a link under the pointer or with the focus of the keyboard.
						li {
							a(.href(app.privacyPolicyPath)) {
								app.privacySummary
							}
							.style {
								$0.quietLink()
							}
						}
						.style(Styles.fact)
					}
					.style(Styles.facts)
				}
				.style(Styles.details)
			}

			// An archived app is no longer available, so the menu has no QR code or sharing.
			if let sharedPage = app.sharedPage {
				// The “Show QR Code” option of the “…” menu shows it, like on a computer, to open the App Store page on an iPhone. An app that is not on iPhone, Apple Watch, or Vision Pro gets the page of the app instead, to open it on a phone, like to send it to someone.
				let target = if let appStoreURL = app.qrCodeURL {
					(url: appStoreURL, label: "QR code that opens \(app.title) on the App Store", caption: "Scan with your iPhone to open \(app.title) on the App Store")
				} else {
					(url: app.path.absoluteURL, label: "QR code that opens this page", caption: "Scan with your phone to open this page")
				}
				// A dialog named by its caption, which the “…” menu focuses, so screen readers announce it. Not a `figure`, which cannot be a dialog when it has a caption.
				div {
					QRCode(url: target.url, label: target.label)
						.style(Styles.qrCodeImage)

					p(.id(Self.qrCodeCaptionID)) {
						target.caption
					}
				}
				.dialogPopover(id: Self.qrCodeID, labelledBy: Self.qrCodeCaptionID)
				.style(Styles.dialog)

				// The “Share…” option of the “…” menu shows it when it cannot share, like in Safari on the Mac, which does not count a choice in a menu as an action of the visitor. Its buttons count.
				div {
					p(.id(Self.shareTitleID)) {
						"Share \(app.title)"
					}
					.style(Styles.shareTitle)

					div {
						ShareButton(page: sharedPage)

						CopyButton(title: "Copy Link", text: sharedPage.url.absoluteString)
					}
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
				}
				.dialogPopover(id: Self.sharePopoverID, labelledBy: Self.shareTitleID)
				.style(Styles.dialog)
			}

			// The menu is there also without links, as it has a random app, and the QR code and sharing for apps that are not archived.
			ChipNavigation(label: "App links", links: sectionLinks, menu: .appPage(app, hasGuides: hasGuides, variant: .chip))
				.style {
					$0.margin(.top, .rootEm(2))
				}
		}
		.style(Styles.root)
	}

	/**
	The platforms with the requirement, and how long the app has been available, before the link to the privacy policy.
	*/
	private var details: [String] {
		[listing.availabilityFact, app.availableSinceText(at: buildDate)].compactMap(\.self)
	}

	/**
	The section links of the app, without the trial section, as the “Free Trial” button right above links to it.
	*/
	private var sectionLinks: [LabeledLink] {
		app.links.filter { $0.destination != .section(.trial) }
	}

	/**
	The fragment that the random app page adds, which shows the “Another Random App” button. The app page has the ID at its top, so the page does not scroll.
	*/
	static let anotherRandomAppID = ElementID("another-random-app")

	/**
	The ID of the QR code popover, which the “…” menu shows.
	*/
	static let qrCodeID = ElementID("qr-code")

	private static let qrCodeCaptionID = ElementID("qr-code-caption")

	/**
	The ID of the share popover, which the “Share…” option of the “…” menu shows when the browser refuses to share from the menu.
	*/
	static let sharePopoverID = ElementID("share-popover")

	private static let shareTitleID = ElementID("share-title")

	/**
	The IDs that scripts find elements of the hero by: the hero, which the navigation of the app observes and links to, and the icon, which the script of an app page can change, like the googly eyes of the Googly Eyes page.
	*/
	enum IDs: String, ScriptIDSet {
		case hero = "app-hero"
		case icon = "app-icon"
	}

	enum Styles: String, StyleSet {
		case root
		case icon
		case title
		case subtitle
		case introduction
		case anotherRandomApp
		case anotherRandomAppButton
		case dialog
		case shareTitle
		case qrCodeImage
		case archivedBadge
		case downloads
		case downloadCount
		case downloadLabel
		case details
		case facts
		case fact

		var style: Style {
			switch self {
			case .root:
				Style()
					.vstack(alignment: .center)
					.padding(.horizontal, .rootEm(1))
					.textAlign(.center)
					.from(.smallTablet) {
						$0.padding(.horizontal, .rootEm(1.5))
					}
			case .icon:
				// A large icon above the title, with a soft shadow in layers.
				Style()
					.frame(size: .rootEm(8))
					.margin(.bottom, .rootEm(1.25))
					.filter(
						.dropShadow(Shadow(y: .pixels(1), blur: .pixels(2), color: .black.opacity(0.15))),
						.dropShadow(Shadow(y: .pixels(4), blur: .pixels(10), color: .black.opacity(0.1))),
						.dropShadow(Shadow(y: .pixels(12), blur: .pixels(28), color: .black.opacity(0.07))),
						// A soft glow in the color of the icon. Without an accent, it is transparent, as the alpha of `transparent` is 0.
						.dropShadow(Shadow(y: .pixels(10), blur: .pixels(24), color: Color.accent.value(default: .transparent).opacity(0.5)))
					)
					.from(.smallTablet) {
						$0.frame(size: .rootEm(11))
					}
			case .title:
				// At most the width of the hero, so a long name, like “Supercharge”, breaks when it is wider than the screen, like on a phone with large text.
				Style()
					.margin(.bottom, .rootEm(0.75))
					.textStyle(.largeTitle)
					.color(.primaryText)
					.frame(maxWidth: .percent(100))
					.breaksLongWords()
			case .subtitle:
				// It grows a little on large screens, and its width is in `em`, so it grows with it, and most subtitles fit on one line there.
				Style()
					.frame(maxWidth: .em(26))
					.font(size: .clamp(.rootEm(1.25), .viewportWidth(3), .rootEm(1.5)), lineHeight: 1.3)
					.from(.desktop) {
						$0
							.frame(maxWidth: .em(32))
							.font(size: .rootEm(1.625), lineHeight: 1.3)
					}
					.fontWeight(.medium)
					.letterSpacing(.em(-0.01))
					.color(.primaryText)
					.textWrap(.balance)
					.hangingPunctuation([.first, .last])
			case .introduction:
				// As wide as about 75 characters, so most introductions are two balanced lines. On large screens, the text is larger, and so wider, with the same line length.
				Style()
					.frame(maxWidth: .em(35.5))
					.margin(top: .rootEm(1), horizontal: .zero, bottom: .zero)
					.secondaryText(.lead)
					.from(.desktop) {
						$0.font(size: .rootEm(1.3125))
					}
					.textLinks()
					// The text is centered, so lines of similar lengths look better than a short last line.
					.textWrap(.balance)
			case .anotherRandomApp:
				Style()
					.hidden()
					.justifyContent(.center)
					// Only the target of the random app page (``AppHero/anotherRandomAppID``), not another target around it, like the content that the skip link goes to.
					.nested("#\(raw: AppHero.anotherRandomAppID.rawValue):target &") {
						$0.display(.flex)
					}
			case .anotherRandomAppButton:
				Style().margin(.top, .rootEm(1.5))
			case .shareTitle:
				Style()
					.fontWeight(.semibold)
					.color(.primaryText)
			case .dialog:
				// The browser centers a popover with the auto margins, which the reset removes. It closes with the Escape key or a click outside.
				Style()
					.popoverOpen {
						$0.vstack(alignment: .center, spacing: .rootEm(1))
					}
					.margin(.auto)
					.frame(maxWidth: .rootEm(18))
					.padding(.rootEm(1.5))
					.popoverSurface()
					.secondaryText()
					.textAlign(.center)
					.backdrop {
						$0.background(.black.opacity(0.3))
					}
			case .qrCodeImage:
				Style()
					.frame(size: .pixels(176))
					.padding(.pixels(8))
					.cornerRadius(.rootEm(0.5))
					.color(.gray(900))
					.background(.white)
			case .archivedBadge:
				// Below the introduction, which says why the app is archived.
				Style()
					.margin(.top, .rootEm(1))
					.setting(Badge.fontSize, to: .rootEm(1))
			case .downloads:
				Style()
					.margin(.top, .rootEm(1))
					.textStyle(.caption)
					.monospacedDigit()
			case .downloadCount:
				Style()
					.fontWeight(.semibold)
					.color(.bodyText)
			case .downloadLabel:
				Style()
					.color(.secondaryText)
			case .details:
				Style()
					.margin(.top, .rootEm(1))
					.secondaryText()
					.monospacedDigit()
			case .facts:
				// One fact on each line on phones. From tablets, one line with dots between the facts, which wraps between the facts with large text. The dot is at the end of the fact before it, so no line starts with a dot.
				Style()
					.vstack(alignment: .center)
					.from(.tablet) {
						$0
							.flexDirection(.row)
							.flexWrap()
							.justifyContent(.center)
					}
			case .fact:
				// Screen readers skip the dot, as its alternative text is empty.
				Style()
					.from(.tablet) {
						$0.nested("&:not(:last-child)::after") {
							$0.content("\u{2002}·\u{2002}", alternativeText: "")
						}
					}
			}
		}
	}
}

/**
The end of an app page, for visitors who read the whole page: the icon, the name, the download options, the price, and the facts of the app (``AppFacts``), so the end of the page is one block. The page shows it only for an app that can be downloaded (``App/isDownloadable``).

The panel has a soft light in the accent of the page, like the color of the icon, and an edge in the accent, so the last call to action stands out from the gray cards above it and ties the end of the page to the top.
*/
struct AppCallToAction: HTML {
	/**
	The app with its fetched data, for the price and the facts.
	*/
	let listing: AppListing
	let buildDate: Date

	/**
	Where the box is, for the campaign of its App Store link: the app page, or a guide.
	*/
	var appStorePlacement = App.AppStorePlacement.downloadButton

	private var app: App {
		listing.app
	}

	var body: some HTML<HTMLTag.section> {
		// The box shows the app, so its links show no preview of it in a guide.
		section(.hook(LinkPreview.Hooks.noLinkPreview)) {
			AppIcon(decorative: app, size: 128)
				.style(Styles.icon)

			h2 {
				"Get "

				span(.notTranslated) {
					app.title
				}
			}
			.style(Styles.title)

			p {
				app.subtitle
			}
			.style(Styles.subtitle)

			DownloadOptions(app: app, appStorePlacement: appStorePlacement)
				.style {
					$0.margin(.top, .rootEm(0.5))
				}

			if let price = listing.priceText {
				p {
					price
				}
				.style(Styles.price)
			}

			AppFacts(listing: listing, buildDate: buildDate)
				.style {
					$0.margin(.top, .rootEm(3))
				}
		}
		.style(Styles.root)
	}

	enum Styles: String, StyleSet {
		case root
		case icon
		case title
		case subtitle
		case price

		var style: Style {
			switch self {
			case .root:
				// A panel, so the end of the page stands out from the text above it. The light comes from the top, where the icon is.
				// Wider on large screens, with the edge of the press quotes and the reviews, so the panel is not a narrow column there.
				Style()
					.from(.proseWithGutters) {
						$0.centeredColumn(.standard)
					}
					.wideAppPartColumn()
					.vstack(alignment: .center)
					.padding(vertical: .rootEm(3), horizontal: .rootEm(1.5))
					.backgroundImage(.radialGradient(.ellipse(radiusX: .percent(120), radiusY: .percent(90), at: .init(x: .percent(50), y: .percent(0))), .lightDark(Color.pageAccent.opacity(0.16), Color.pageAccent.opacity(0.2)), .lightDark(Color.pageAccent.opacity(0.04), Color.pageAccent.opacity(0.05))))
					.border(.lightDark(Color.pageAccent.opacity(0.25), Color.pageAccent.opacity(0.3)))
					// The gray of secondary text has too little contrast on the light of the accent in light mode, so the subtitle, the price, and the labels of the facts are darker.
					.replacing(.secondaryText, with: .lightDark(.gray(600), .gray(400)))
					.cornerRadius(.panelRadius)
					.textAlign(.center)
					.from(.smallTablet) {
						$0.padding(vertical: .rootEm(4), horizontal: .panelPadding)
					}
					// Below tablets, the panel is as wide as the screen, so it has no corners and no edges at its sides. The app page also makes it as wide as the screen until there is space at its sides.
					.below(.tablet) {
						$0
							.cornerRadius(.zero)
							.border(.horizontal, width: .zero)
					}
			case .icon:
				Style()
					.frame(size: .rootEm(5.25))
					.filter(.dropShadow(Shadow(y: .pixels(4), blur: .pixels(10), color: .black.opacity(0.12))))
			case .title:
				Style()
					.margin(.top, .rootEm(1))
					.textStyle(.title)
					.color(.primaryText)
			case .subtitle:
				Style()
					.margin(top: .rootEm(0.5), horizontal: .zero, bottom: .rootEm(1.5))
					.secondaryText(.lead)
			case .price:
				Style()
					.margin(.top, .rootEm(1))
					.secondaryText()
			}
		}
	}
}

/**
The facts of an app at the end of its page, like the “Information” of the App Store: the platforms, the requirement, the category, when it was released, the privacy, Family Sharing for an app with a price on the App Store, when it was last updated, the version, the size of the download, and the rating, so visitors who scan find them in one place. They are in the box to get the app (``AppCallToAction``), below its button, as three columns with thin lines between them, and on phones as rows with the label at the start and the value at the end. The price is in the box too, so it is not repeated. An app that cannot be downloaded yet shows them alone. An archived app is no longer available, so it has none.
*/
struct AppFacts: HTML {
	/**
	The app with its fetched data, for the requirement and the category.
	*/
	let listing: AppListing
	let buildDate: Date

	private var app: App {
		listing.app
	}

	private struct Fact {
		let label: String
		let value: String
		var destination: LinkDestination?
	}

	private var facts: [Fact] {
		[
			Fact(label: "Platform".pluralized(for: app.platforms.count), value: app.operatingSystems),
			listing.requirement.map { Fact(label: "Requires", value: $0) },
			listing.appStoreInfo?.primaryGenreName.map { Fact(label: "Category", value: $0) },
			Fact(label: "Released", value: app.publicationDate.foundationDate.formatted(.siteMonth)),
			// The summary of an app that sends some data says that the policy has the details, which the label already says.
			Fact(label: "Privacy", value: app.privacyNote == nil ? app.privacySummary : "Read the policy", destination: .path(app.privacyPolicyPath)),
			listing.hasFamilySharing ? Fact(label: "Family Sharing", value: "Yes", destination: .familySharingQuestion) : nil,
			updatedFact,
			listing.version.map { Fact(label: "Version", value: $0) },
			// A visitor with little free space sees a large download, like an app with a large model, before the download.
			listing.fileSize.map { size in
				let value = if size < 1_000_000_000 {
					"\((Double(size) / 1_000_000).formatted(.number.grouping(.never).locale(.site).precision(.fractionLength(0)))) MB"
				} else {
					size.formatted(.siteFileSize)
				}

				return Fact(label: "Size", value: value)
			},
			ratingFact,
		]
		.compactMap(\.self)
	}

	/**
	The eligible rating as a compact fact, with its source and sample size together.
	*/
	private var ratingFact: Fact? {
		guard let rating = listing.rating(at: buildDate) else {
			return nil
		}

		switch rating {
		case .store(let rating):
			let value = "\(rating.formattedAverage)/5 (\(rating.count.formatted(counting: "rating")))"

			switch rating.store {
			case .appStore:
				return Fact(label: "US App Store rating", value: value, destination: app.appStoreID.map { .url(#URL("https://apps.apple.com/us/app").appending(path: "id\($0)")) })
			case .gumroad:
				return Fact(label: "Gumroad rating", value: value, destination: app.frontmatter.gumroad.map { .url($0.id.url) })
			}
		case .setapp(let rating):
			return Fact(label: "Setapp rating", value: "\(rating.formattedPercentage) positive (\(rating.count.formatted(counting: "rating")))", destination: app.setappID.map { .url($0.pageURL) })
		}
	}

	/**
	When the current version was released, like the date in the structured data, which tells a buyer that the app is maintained. Without the date, like for an app that the build could not fetch, the developer, so the facts keep their rows.
	*/
	private var updatedFact: Fact {
		guard let date = listing.currentVersionDate else {
			return Fact(label: "Developer", value: Site.author.name, destination: .path(.about))
		}

		return Fact(
			label: "Updated",
			value: date.foundationDate.formatted(.siteMonth)
		)
	}

	/**
	Four columns from laptops when they leave no more empty places in the last row than three, like 4 + 3 for seven facts instead of 3 + 3 + 1, and 4 + 4 + 2 for ten instead of 3 + 3 + 3 + 1, and three columns otherwise, like 3 + 3 for six facts.
	*/
	private var columnsStyle: Styles {
		let count = facts.count

		func emptyPlaces(columns: Int) -> Int {
			(columns - count % columns) % columns
		}

		return emptyPlaces(columns: 4) <= emptyPlaces(columns: 3) ? .fourColumns : .threeColumns
	}

	var body: some HTML<HTMLTag.dl> {
		dl {
			for fact in facts {
				div {
					dt {
						fact.label
					}
					.style(Styles.label)

					dd {
						if let destination = fact.destination {
							a(.href(destination)) {
								fact.value
							}
							.style(Styles.link)
						} else {
							fact.value
						}
					}
					.style(Styles.value)
				}
				.style(Styles.fact)
			}
		}
		.style(Styles.root, columnsStyle)
	}

	enum Styles: String, StyleSet {
		case root
		case threeColumns
		case fourColumns
		case fact
		case label
		case value
		case link

		var style: Style {
			switch self {
			case .root:
				// On phones, rows with a thin line between them, like the information of the App Store, so every value fits on its line. From small tablets, columns (``threeColumns`` or ``fourColumns``), with a thin line between the columns, so most values fit on one line, like the short values of the information of the App Store, and the facts of a last row that is not full centered below the others, like the last two of five facts.
				Style()
					.centeredColumn(.standard)
					.frame(width: .percent(100))
					.margin(.bottom, .zero)
					.below(.smallTablet) {
						$0.children(":not(:first-child)") {
							$0.border(.top, .separator, width: .pixels(1))
						}
					}
					.from(.smallTablet) {
						$0
							.frame(maxWidth: .rootEm(40))
							.display(.grid)
							.textAlign(.center)
							.gap(row: .rootEm(1.5), column: .zero)
					}
			case .threeColumns:
				Style()
					.from(.smallTablet) {
						$0.factColumns(3)
					}
			case .fourColumns:
				// Three columns on tablets, where four would wrap the longer values, like “No personal data collected”.
				Style()
					.media(.from(.smallTablet) && .below(.laptop)) {
						$0.factColumns(3)
					}
					.from(.laptop) {
						$0
							.frame(maxWidth: .rootEm(54))
							.factColumns(4)
					}
			case .fact:
				// A long value, like the requirement of an app on several platforms, wraps, at the end of its row on phones.
				Style()
					.hstack(alignment: .baseline, justification: .spaceBetween, spacing: .rootEm(1))
					.padding(.vertical, .rootEm(0.75))
					.from(.smallTablet) {
						$0
							.display(.block)
							.padding(vertical: .zero, horizontal: .rootEm(0.75))
					}
			case .label:
				Style()
					.flexShrink(0)
					.secondaryText()
			case .value:
				// A value that wraps has lines of about the same length, so its last line is not one word, like “later”.
				Style()
					.margin(.zero)
					.textAlign(.trailing)
					.textStyle(.caption)
					.textWrap(.balance)
					.color(.bodyText)
					.from(.smallTablet) {
						$0
							.margin(.top, .rootEm(0.25))
							.textAlign(.center)
					}
			case .link:
				// A faint underline makes linked facts recognizable before hover.
				Style()
					.quietLink()
					.underline(color: Color.currentColor.opacity(0.35), thickness: .pixels(1), offset: .pixels(3))
					.hoverOrFocusVisible {
						$0.underlineColor(.currentColor)
					}
			}
		}
	}
}

extension Style {
	/**
	The columns of the facts of an app, with a thin line between the columns.
	*/
	fileprivate func factColumns(_ count: Int) -> Self {
		balancedColumns(count)
			.children(":not(:nth-child(\(raw: String(count))n + 1))") {
				$0.border(.leading, .separator, width: .pixels(1))
			}
	}
}

/**
Applies the shared nonmodal dialog-popover relationship to a div root.
*/
extension HTML where Tag == HTMLTag.div {
	/**
	Creates a focusable dialog popover named by its caption, preserving the explicit ID references.
	*/
	func dialogPopover(id: ElementID, labelledBy label: ElementID) -> _AttributedContent<Self> {
		attributes(.id(id), .popover, .role(.dialog), .ariaLabelledBy(label), .tabindex(-1))
	}
}
