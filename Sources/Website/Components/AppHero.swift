import Elementary
import Foundation
import SiteKit

/**
The top of an app page: the icon, the name, the subtitle, the introduction, the download buttons, the price, the platforms, a link to the privacy policy, a link to the App Store story that features the app, and the links. It also has the popovers of the page: the QR code, sharing, and the trial card. The rating is in the app information (``AppFacts``), so the hero is not crowded.
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
				imageID: IDs.icon.id,
				shadow: .large
			)
				.style(Styles.icon)

			// The name of the app is not translated, so visitors find it on the App Store.
			h1(.notTranslated) {
				app.title
			}
			.style(Styles.title)

			p {
				app.displaySubtitle
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
				// The light tint of an action next to the main one, as it is a way to browse on, so the App Store badge below stays the strongest button of the hero.
				.buttonStyle(.secondary, size: .small)
				.style(Styles.anotherRandomAppButton)
			}
			.style(Styles.anotherRandomApp)

			if app.isArchived {
				div {
					Badge("Archived", kind: .archived)
				}
				.style(Styles.archivedBadge)
			}

			// Above the buttons, as the end of the introduction, so the price and the facts come right after the buttons that they are about.
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

			if !app.downloadOptions.isEmpty {
				DownloadOptions(app: app, trialDialogID: Self.trialDialogID, isAboveFold: true)
					.style {
						$0.margin(.top, .rootEm(2))
					}
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
						// The editors of the App Store chose the app for a story, which a buyer trusts more than the words of the developer. It is first, so on phones, where each fact is on its line, the requirement is between the two links, and their tap areas do not cover the other link.
						if let story = app.frontmatter.appStoreStory {
							li {
								a(.href(.url(story.url))) {
									"Featured by Apple"
								}
								.style(Styles.factLink)
							}
							.style(Styles.fact)
						}

						// The year that the app was released is in the facts at the end of the page (``AppFacts``), so this line stays short.
						li {
							listing.availabilityFact
						}
						.style(Styles.fact)

						// It looks like the text around it, so the line stays quiet, and shows that it is a link under the pointer or with the focus of the keyboard.
						li {
							a(.href(app.privacyPolicyPath)) {
								app.privacySummary
							}
							.style(Styles.factLink)
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
					QRCode(url: target.url, label: target.label, centerIcon: app)
						.style(Styles.qrCodeImage)

					// Balanced, so “this page” is not alone on the second line. On the paragraph, as the `pretty` of the base styles would win over an inherited value.
					p(.id(Self.qrCodeCaptionID)) {
						target.caption
					}
					.style {
						$0.textWrap(.balance)
					}

					closeButton(for: Self.qrCodeID)
				}
				.dialogPopover(id: Self.qrCodeID, labelledBy: Self.qrCodeCaptionID)
				.style(Styles.dialog)

				// The “Share…” option of the “…” menu shows it when it cannot share, like in Safari on the Mac, which does not count a choice in a menu as an action of the visitor. Its buttons count.
				div {
					p(.id(Self.shareTitleID)) {
						"Share \(app.title)"
					}
					.style(Styles.shareTitle)

					// The card that link previews show, like in Messages, so the visitor sees what the shared link looks like, like in the share sheet of the system. In dark mode, the dark card, as apps show a preview in their own look, and a light card would be the brightest thing on the dark page. No alternative text, as the title already names the page. It loads when the dialog opens, as the dialog is hidden until then.
					picture {
						source(.media(.dark), .srcset(OpenGraphCard.path(ofPage: app.path, appearance: .dark)))

						img(
							.src(OpenGraphCard.path(ofPage: app.path)),
							.width(OpenGraphCard.width),
							.height(OpenGraphCard.height),
							.alt(""),
							.lazyLoading
						)
							.style(Styles.shareCard)
					}
					// Only a wrapper of the sources, so the card is an item of the dialog, like an image alone.
					.style {
						$0.pictureWrapper()
					}

					div {
						ShareButton(page: sharedPage)

						CopyButton(title: "Copy Link", text: sharedPage.url.absoluteString)
					}
					// Columns of the same width, so the two buttons are a balanced pair below the centered card.
					.style {
						$0
							.display(.grid)
							.gridAutoFlow(.column)
							.gridAutoColumns(.fraction(1))
							.gap(.rootEm(0.5))
					}

					closeButton(for: Self.sharePopoverID)
				}
				.dialogPopover(id: Self.sharePopoverID, labelledBy: Self.shareTitleID)
				.style(Styles.dialog)
			}

			// The “Free Trial” buttons of the hero and of the box to get the app open the trial card over the page, so the visitor reads the terms of the trial without a jump to the trial section, which can be far down the page. The section stays, for the links to it and the Markdown copy of the page. The dialog covers the requirement of the hero, so its card shows it (``AppListing/trialCard``).
			if let trialCard = listing.trialCard {
				div {
					p(.id(Self.trialTitleID)) {
						"Free Trial"
					}
					.style(Styles.trialTitle)

					// One surface with the dialog, without the box of the card.
					trialCard
						.style {
							$0
								.margin(.zero)
								.padding(.zero)
								.cornerRadius(.zero)
								.background(.transparent)
								.backgroundImage(.none)
								.shadow([])
						}

					closeButton(for: Self.trialDialogID)
				}
				.dialogPopover(id: Self.trialDialogID, labelledBy: Self.trialTitleID)
				.style(Styles.trialDialog)
			}

			// The menu is there also without links, as it has a random app, and the QR code and sharing for apps that are not archived.
			ChipNavigation(label: "App links", links: sectionLinks, lastChip: .menu(.appPage(app, hasGuides: hasGuides, variant: .chip)))
				.style {
					$0.margin(.top, .rootEm(2))
				}
		}
		.style(Styles.root)
	}

	/**
	The button in the top corner of a dialog that closes it, as on a phone, where the trial dialog can fill the screen, a tap outside it is not easy to find. It is last, so the Tab key goes to the content of the dialog first. The dialog is open while the button shows, so the button hides it without a script.
	*/
	private func closeButton(for dialogID: ElementID) -> some HTML {
		button(.type(.button), .popoverTarget(dialogID)) {
			Icon.close.size(.rootEm(1), strokeWidth: 1.5)
		}
		.accessibilityLabel("Close")
		.style(Styles.closeButton)
	}

	/**
	The section links of the app, without the trial section, as the “Free Trial” button right above shows the trial.
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
	The ID of the trial popover, which the “Free Trial” buttons of the hero and of the box to get the app show (``DownloadOptions/trialDialogID``).
	*/
	static let trialDialogID = ElementID("trial-dialog")

	private static let trialTitleID = ElementID("trial-dialog-title")

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
		case trialDialog
		case trialTitle
		case closeButton
		case shareTitle
		case qrCodeImage
		case shareCard
		case archivedBadge
		case downloads
		case downloadCount
		case downloadLabel
		case details
		case facts
		case fact
		case factLink

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
				// A large icon above the title, with a soft shadow in layers (``AppIcon/ShadowSize/large``).
				Style()
					.frame(size: .rootEm(8))
					.margin(.bottom, .rootEm(1.25))
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
				// It grows a little on large screens, and its width is in `em`, so it grows with it. From laptops, its width is 32 em, so most subtitles fit on one line.
				Style()
					.frame(maxWidth: .em(26))
					.font(size: .clamp(.rootEm(1.25), .viewportWidth(3), .rootEm(1.5)), lineHeight: 1.3)
					.from(.laptop) {
						$0.frame(maxWidth: .em(32))
					}
					.from(.desktop) {
						$0.font(size: .rootEm(1.625), lineHeight: 1.3)
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
					// Keys and code look like in the text below, as the introduction is the first paragraph of the Markdown, outside the prose.
					.combined(with: ProseStyles.keyboardKeys)
					.combined(with: ProseStyles.inlineCode)
					// The text is centered, so lines of similar lengths look better than a short last line.
					.textWrap(.balance)
			case .anotherRandomApp:
				Style()
					.hidden()
					.justifyContent(.center)
					// Only the target of the random app page (``AppHero/anotherRandomAppID``), not another target around it, like the content that the skip link goes to.
					.inside("#\(raw: AppHero.anotherRandomAppID.rawValue):target") {
						$0.display(.flex)
					}
			case .anotherRandomAppButton:
				Style().margin(.top, .rootEm(1.5))
			case .shareTitle:
				// Space for the close button at the end, and the same at the start, so the title stays centered, and a long name, like “Share System Color Picker”, does not run under the button.
				Style()
					.padding(.horizontal, .rootEm(1.75))
					.fontWeight(.semibold)
					.color(.primaryText)
			case .dialog:
				Self.dialogSurface
					.popoverOpen {
						$0.vstack(alignment: .center, spacing: .rootEm(1))
					}
					.frame(maxWidth: .rootEm(18))
					.secondaryText()
					.textAlign(.center)
			case .trialDialog:
				// Wider, with the text at the start, like the trial section, not centered like the hero around it, and the space of the page at the sides on phones. The links and the code look like in the text of the page, as the card is not in prose here.
				Self.dialogSurface
					.popoverOpen {
						$0.vstack(spacing: .rootEm(1))
					}
					.frame(maxWidth: .length(.min(.rootEm(34), .viewportWidth(100) - .pageGutter * 2)))
					.textAlign(.leading)
					.color(.bodyText)
					// Only the links in the text, not the download button.
					.descendants("p") {
						$0.textLinks()
					}
					.combined(with: ProseStyles.inlineCode)
			case .trialTitle:
				Style()
					.margin(.zero)
					.textStyle(.headline)
					.color(.primaryText)
			case .closeButton:
				// Round, with the quiet fill of a chip, in the top trailing corner, where it does not cover the content, which starts 1.5rem in. Its center is on the center of the first line of the title: the padding of the dialog (1.5rem) plus half of the line (0.75rem) less half of the button (0.875rem). The same distance from the side as from the top, so the round button is concentric with the 1.5rem corner of the dialog.
				Style()
					.position(.absolute)
					.top(.rootEm(1.375))
					.trailing(.rootEm(1.375))
					.hstack(alignment: .center, justification: .center)
					.padding(.rootEm(0.375))
					.cornerRadius(.capsule)
					.color(.secondaryText)
					.background(.card)
					.hoverFill(.cardHover, color: .primaryText)
			case .qrCodeImage:
				Style()
					.frame(size: .pixels(176))
					.padding(.pixels(8))
					.cornerRadius(.rootEm(0.5))
					.color(.gray(900))
					.background(.white)
			case .shareCard:
				// As wide as the dialog, with the corners of a small card and an edge, as the card can be as light or as dark as the dialog.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.cornerRadius(.rootEm(0.75))
					.border(.separator)
			case .archivedBadge:
				// Below the introduction, which says why the app is archived.
				Style()
					.margin(.top, .rootEm(1))
					.setting(Badge.fontSize, to: .rootEm(1))
			case .downloads:
				Style()
					.margin(.top, .rootEm(0.75))
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
				// One fact on each line on phones. From small tablets, like a window that fills half of a laptop screen, one line with dots between the facts, which wraps between the facts with large text. The dot is at the end of the fact before it, so no line starts with a dot.
				Style()
					.vstack(alignment: .center)
					.from(.smallTablet) {
						$0
							.flexDirection(.row)
							.flexWrap()
							.justifyContent(.center)
					}
			case .fact:
				// Screen readers skip the dot, as its alternative text is empty (``Style/factSeparator()``).
				Style()
					.from(.smallTablet) {
						$0.notLastChild {
							$0.after {
								$0.factSeparator()
							}
						}
					}
			case .factLink:
				// On touch screens, a tap area for the short link. On phones, where each fact is on its line, the links are not next to each other, so their tap areas do not cover the other link.
				Style()
					.quietLink()
					.minimumTapArea()
			}
		}

		/**
		The surface of the dialogs of the hero, and of the search of the site (``SiteSearch``). The browser centers a popover with the auto margins, which the reset removes. It closes with the Escape key, a click outside, or its close button. The corners are the ones of a card, not of a window, as the padding is the one of a card.
		*/
		static let dialogSurface = Style()
			.margin(.auto)
			.padding(.rootEm(1.5))
			.popoverSurface()
			.cornerRadius(.cardRadius)
			// Darker in dark mode, as a light dim hardly shows on the near-black page. A small blur, so the text of the page around the dialog does not compete with the text of the dialog.
			.backdrop {
				$0
					.background(.black.opacity(0.3), dark: .black.opacity(0.6))
					.backdropFilter(.blur(radius: .pixels(6)))
			}
			.reducedTransparency {
				$0.backdrop {
					$0.backdropFilter()
				}
			}
			// The page does not scroll while a dialog is open, as the dim makes the dialog look modal, and the page would move under it. The root keeps the space of a classic scroll bar, so the page does not move to the side.
			.popoverOpen {
				$0.onPageRoot {
					$0.overflow(.hidden)
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

	/**
	Whether the facts are only the ones that decide a purchase (``AppFacts/isCompact``), like in a guide, where the box is not the main content.
	*/
	var hasCompactFacts = false

	/**
	The dialog of the page with the trial card, which the “Free Trial” button opens (``DownloadOptions/trialDialogID``). A guide has none, so the button links to the trial section of the app page.
	*/
	var trialDialogID: ElementID?

	/**
	Whether the “Free Trial” button is shown (``DownloadOptions/showsTrial``).
	*/
	var showsTrial = true

	/**
	The platforms that the requirement names (``AppFacts/platforms``), like only iOS in a guide about the iPhone. `nil` for all the platforms of the app.
	*/
	var platforms: [Platform]?

	private var app: App {
		listing.app
	}

	var body: some HTML<HTMLTag.section> {
		// The box shows the app, so its links show no preview of it in a guide.
		section(.id(IDs.panel), .hook(LinkPreview.Hooks.noLinkPreview)) {
			AppIcon(decorative: app, size: 128, shadow: .medium)
				.style(Styles.icon)

			h2 {
				"Get "

				span(.notTranslated) {
					app.title
				}
			}
			.style(Styles.title)

			p {
				app.displaySubtitle
			}
			.style(Styles.subtitle)

			DownloadOptions(
				app: app,
				appStorePlacement: appStorePlacement,
				trialDialogID: trialDialogID,
				showsTrial: showsTrial
			)
				.style {
					$0.margin(.top, .rootEm(0.5))
				}

			if let price = listing.priceText {
				p {
					price
				}
				.style(Styles.price)
			}

			// A guide shows only the facts that decide a purchase, as the link to the app page below the box leads to the others.
			AppFacts(
				listing: listing,
				buildDate: buildDate,
				isCompact: hasCompactFacts,
				platforms: platforms
			)
				.style {
					$0.margin(.top, .rootEm(3))
				}
		}
		.style(Styles.root)
	}

	/**
	The ID of the box, which the navigation of the app finds, so it marks no section while the visitor reads the box.
	*/
	enum IDs: String, ScriptIDSet {
		case panel = "get-app"
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
				// Where there is space at its sides, it has the edge of the press quotes, the reviews, and the app cards below it, so the panel is not a narrow column there.
				Style()
					.wideAppPartColumn()
					.vstack(alignment: .center)
					.padding(vertical: .rootEm(3), horizontal: .rootEm(1.5))
					// In dark mode, a dark accent gets the lightness of the selection (``Color/darkModeHighlightAccent``) and a light accent is not as strong, so the tint is about the same for all apps, and a light accent, like yellow, is not a strong colored panel.
					.backgroundImage(.radialGradient(.ellipse(radiusX: .percent(120), radiusY: .percent(90), at: .init(x: .percent(50), y: .percent(0))), .lightDark(Color.pageAccent.opacity(0.16), Color.darkModeHighlightAccent.opacity(0.12)), .lightDark(Color.pageAccent.opacity(0.04), Color.darkModeHighlightAccent.opacity(0.03))))
					.border(.lightDark(Color.pageAccent.opacity(0.25), Color.darkModeHighlightAccent.opacity(0.2)))
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
			case .title:
				Style()
					.margin(.top, .rootEm(1))
					.textStyle(.title)
					.color(.primaryText)
			case .subtitle:
				Style()
					.margin(top: .rootEm(0.5), horizontal: .zero, bottom: .rootEm(1.5))
					.secondaryText(.lead)
					// Like the subtitle of the hero, so a subtitle that wraps on a phone does not leave a word alone on its last line.
					.textWrap(.balance)
			case .price:
				Style()
					.margin(.top, .rootEm(1))
					.secondaryText()
			}
		}
	}
}

/**
The facts of an app at the end of its page, like the “Information” of the App Store: the requirement (or the platforms, for an app without a requirement), the category, when it was released (not in the hero, so the hero stays short), the privacy, Family Sharing for an app with a price on the App Store, the license of an app sold on Gumroad, which is for all the Macs of the buyer, when it was last updated, the number of free updates of a paid app with release notes, the version, the size of the download (of the Mac and the iPhone version of a universal app), and the rating, so visitors who scan find them in one place. The box of a guide shows only the facts that decide a purchase (``isCompact``). They are in the box to get the app (``AppCallToAction``), below its button, as three columns with thin lines between them, and on phones as rows with the label at the start and the value at the end. The price is in the box too, so it is not repeated. An app that cannot be downloaded yet shows them alone. An archived app is no longer available, so it has none.
*/
struct AppFacts: HTML {
	/**
	The app with its fetched data, for the requirement and the category.
	*/
	let listing: AppListing
	let buildDate: Date

	/**
	Whether only the facts that decide a purchase are shown: the requirement, the privacy, Family Sharing or the license, the update date, and the rating, like in the box to get the app of a guide, where the link to the app page leads to the others.
	*/
	var isCompact = false

	/**
	The platforms that the requirement names, like only iOS in a guide about the iPhone, where the other platforms of the app are not what the guide is about. `nil` for all the platforms of the app.
	*/
	var platforms: [Platform]?

	private var app: App {
		listing.app
	}

	private struct Fact {
		let label: String

		/**
		The value on one line, or on more lines, like the size of each version of a universal app.
		*/
		let lines: [String]

		var destination: LinkDestination?

		init(label: String, lines: [String], destination: LinkDestination? = nil) {
			self.label = label
			self.lines = lines
			self.destination = destination
		}

		init(label: String, value: String, destination: LinkDestination? = nil) {
			self.init(label: label, lines: [value], destination: destination)
		}
	}

	private var facts: [Fact] {
		let supportedPlatforms = platforms ?? app.platforms
		let facts: [Fact?] = [
			// The requirement names each platform, like the one “Compatibility” fact of the App Store, so the platforms are a fact only without it.
			listing.requirement.map { Fact(label: "Requires", value: OSRequirement(platforms: supportedPlatforms, version: $0.version).description) } ?? Fact(label: "Platform".pluralized(for: supportedPlatforms.count), value: supportedPlatforms.map(\.rawValue).joined(separator: ", ")),
			isCompact ? nil : listing.appStoreInfo?.primaryGenreName.map { Fact(label: "Category", value: $0) },
			isCompact ? nil : Fact(label: "Released", value: app.publicationDate.foundationDate.formatted(.siteMonth)),
			// The summary of an app that sends some data says that the policy has the details, which the label already says.
			Fact(label: "Privacy", value: app.privacyNote == nil ? app.privacySummary : "Read the policy", destination: .path(app.privacyPolicyPath)),
			listing.hasFamilySharing ? Fact(label: "Family Sharing", value: "Yes", destination: .familySharingQuestion) : nil,
			// A purchase on Gumroad is for all the Macs of the buyer, which the App Store limits to 5.
			app.purchase.gumroad == nil ? nil : Fact(label: "License", value: "All your Macs", destination: .deviceLimitQuestion),
			updatedFact,
			isCompact ? nil : freeUpdatesFact,
			isCompact ? nil : listing.version.map { Fact(label: "Version", value: $0) },
			// A visitor with little free space sees a large download, like an app with a large model, before the download.
			isCompact || listing.sizeLines.isEmpty ? nil : Fact(label: "Size", lines: listing.sizeLines),
			ratingFact,
		]

		return facts.compactMap(\.self)
	}

	/**
	The eligible rating as a compact fact, with its source and sample size together.
	*/
	private var ratingFact: Fact? {
		guard let rating = listing.rating(at: buildDate) else {
			return nil
		}

		let destination: LinkDestination? = switch rating {
		case .store(let rating):
			switch rating.store {
			case .appStore:
				app.appStoreID.map { .url(#URL("https://apps.apple.com/us/app").appending(path: "id\($0)")) }
			case .gumroad:
				app.purchase.gumroad.map { .url($0.id.url) }
			}
		case .setapp:
			app.setappID.map { .url($0.pageURL) }
		}

		return Fact(label: rating.label, value: rating.value, destination: destination)
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
	The number of free updates (``AppListing/freeUpdateCount``), like “52” for Supercharge, with a link to the release notes.
	*/
	private var freeUpdatesFact: Fact? {
		guard
			let count = listing.freeUpdateCount,
			let releaseNotes = app.releaseNotes
		else {
			return nil
		}

		return Fact(label: "Free updates", value: count.formatted(.siteNumber), destination: .path(releaseNotes.path))
	}

	/**
	Four columns from laptops when they leave no more empty places in the last row than three, like 4 + 3 for seven facts instead of 3 + 3 + 1, and 4 + 4 + 2 for ten instead of 3 + 3 + 3 + 1, and three columns otherwise, like 3 + 3 for six facts. The compact facts of a guide have four columns only for four facts, as one row (``Styles/compactFourColumns``).
	*/
	private var columnsStyle: Styles {
		let count = facts.count

		func emptyPlaces(columns: Int) -> Int {
			(columns - count % columns) % columns
		}

		guard emptyPlaces(columns: 4) <= emptyPlaces(columns: 3) else {
			return .threeColumns
		}

		return isCompact && count == 4 ? .compactFourColumns : .fourColumns
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
						for (index, line) in fact.lines.enumerated() {
							if index > 0 {
								br()
							}

							if let destination = fact.destination {
								a(.href(destination)) {
									line
								}
								.style(Styles.link)
							} else {
								line
							}
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
		case compactFourColumns
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
			case .compactFourColumns:
				// In the box of a guide, which is narrower than the box of an app page, the four facts are one row, so each column is as wide as its value and the space left is shared equally, like “No personal data collected” on one line next to “Yes”. The facts of an app page keep equal columns, as the centered last row of a grid with more rows needs them (``Style/balancedColumns(_:)``).
				Self.fourColumns.style
					.from(.laptop) {
						$0.gridColumns(GridTrackList.repeating(.auto, count: 8))
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
					// A short value, like “Yes”, is a small target on a touch screen.
					.minimumTapArea()
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
