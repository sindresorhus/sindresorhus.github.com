import Elementary
import Foundation
import SiteKit

/**
The 1999 page, Sindre’s personal home page as it was in 1999: a “Click here to enter” splash that dials up, a tiled background, Comic Sans, flames, spinning globes, a marquee, a banner ad, a MIDI jukebox, under construction signs, a pop-up ad, a webring of the apps, a Y2K countdown, a game, a virtual unicorn like a Tamagotchi, a quiz show, a top 10 of links, a butler who answers questions, fun facts, a browser poll, a report about the computer of the visitor, the Matrix, awards, a guestbook with a visitor counter, a dance party, free downloads, the Display Properties of Windows 95, ASCII art, a link exchange, a wall of 88×31 buttons, and more: a site map like a navigation frame, a welcome like Zombo.com, a news ticker, the Lake applet in a Java box, SindreCam, the weather in Bergen, an ICQ status, a shrine to waffles, a pet rock, a fortune cookie, the Cool Site of the Week, a Hall of Fame, a wall of GIFs, and Floppy, a helper for the guestbook, and the toys of the computers of 1999: Snake on a mobile phone, a desktop of Windows 98 with Unicorn Paint, Y2K Bugsweeper, a secret diary, Solitaire, a defragmenter, and the Recycle Bin, a midnight party for the year 2000 with fireworks, and a skull that crashes the computer, with the animated GIFs of that time (``GIF``). The page has the arrow and hand pointers and the scroll bar of Windows 95, and `geocities.js` adds a mouse trail (rainbow sparkles, elastic balls, or a clock), snow, a title that scrolls, screen savers (Flying Unicorns, 3D Pipes, Starfield, and Mystify), the win of Solitaire for the big wins of the page, and a parade of unicorns for the Konami code.

Everything moves, unless the visitor prefers reduced motion: then the GIFs show a still frame, the marquee and the signs stand still, the photo does not load line by line, the counter does not roll, and the trails, the snow, the scrolling title, the screen savers, the falling code of the Matrix, the parade, the static of SindreCam, the cards of the Solitaire win, the fireworks, and the shaking of the Y2K bug are left out, and the water of the Lake applet, the news ticker, the dolphin, the bars of the jukebox, and the preview of the screen saver stand still. The games still work, as the aliens appear and disappear without moving, and the snake moves one step for each key. Nothing makes a sound until the visitor clicks: the splash plays the sound of a modem quietly when the visitor enters, and the jukebox plays when the visitor presses Play. The toys keep what the visitor does in the browser, as the page has no server. The page keeps the 1999 colors in dark mode, with dark text on a light gray panel, so it stays readable.
*/
struct GeoCitiesPage: Page {
	let content: SiteContent

	var path: RoutePath {
		.geoCities
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Sindre’s Home Page, 1999 Edition", description: "Sindre Sorhus as a personal home page from 1999, with a guestbook, an alien game, a virtual unicorn, and a MIDI jukebox.")
	}

	var head: some HTML {
		style {
			HTMLRaw(Self.rootStylesheet.css)
		}
	}

	var body: some HTML {
		HTMLComment(" Hi! You found my source! Steal my GIFs, not my HTML. Greetings from Norway, Sindre ")

		div(.id(Hooks.root)) {
			Deferred(GeoCitiesNavigator(project: content.project))

			// `geocities.js` shakes it when the Y2K bug strikes at the midnight party.
			div(.id(Hooks.panel)) {
				// The panel is in four parts, so rendering the page does not nest too deep for the stack of a thread.
				Deferred(topParts)

				Deferred(middleParts)

				Deferred(lowerParts)

				Deferred(bottomParts)
			}
			.style(Styles.panel)

			Deferred(GeoCitiesStatusBar())

			// It only shows in a print, like of the iMac of the banner ad.
			Deferred(certificate)

			// `geocities.js` adds a copy for each sparkle and star of the rainbow trail behind the mouse pointer, and one copy of the letter for each letter that follows the pointer.
			template(.id(Hooks.sparkleTemplate)) {
				img(.src(GIF.sparkle.path), .alt(""), .width(60), .height(56))
					.style(Styles.sparkle)
			}

			template(.id(Hooks.starTemplate)) {
				span {
					"★"
				}
				.style(Styles.sparkle, Styles.trailStar)
			}

			template(.id(Hooks.letterTemplate)) {
				span {}
					.style(Styles.trailLetter)
			}

			// `geocities.js` adds a copy that runs across the bottom of the window when the visitor types the Konami code, unless the visitor prefers reduced motion.
			template(.id(Hooks.paradeTemplate)) {
				div {
					div {
						for _ in 0..<5 {
							gif(.unicornGallop)
						}
					}
					.style(Styles.paradeUnicorns)
				}
				.accessibilityHidden()
				.style(Styles.parade)
			}

			// `geocities.js` shows a copy when the visitor leaves the page alone, or presses Preview, unless the visitor prefers reduced motion.
			template(.id(Hooks.saverTemplate)) {
				div {
					for _ in 0..<8 {
						gif(.unicornGallop, style: .saverUnicorn)
					}

					p {
						"Sindre’s Flying Unicorns ★ Move the mouse or tap to come back"
					}
					.style(Styles.saverText)
				}
				.accessibilityHidden()
				.style(Styles.saver)
			}

			Deferred(effectTemplates)

			// `geocities.js` adds a copy for each snowflake.
			template(.id(Hooks.snowTemplate)) {
				// The variation selector shows the snowflake as text, not as the blue emoji, so it is white.
				span {
					"❄\u{FE0E}"
				}
				.accessibilityHidden()
				.style(Styles.snowflake)
			}

			// `geocities.js` shows a copy for the falling green code of the Matrix.
			template(.id(Hooks.matrixTemplate)) {
				canvas {}
					.accessibilityHidden()
					.style(Styles.matrixRain)
			}

			// A message at the bottom of the window, like when the visitor right-clicks a GIF.
			p(.id(Hooks.toast), .role("status"), .hidden) {}
				.style(Styles.toast)

			JSONScript(id: Hooks.data, ScriptData(facts: Self.funFacts, tunes: Self.tunes, quiz: quizQuestions))
		}
		.style(Styles.root)

		ModuleScript("/scripts/geocities.js")
	}

	/**
	Part 1 of the 4 parts of the panel, in the order of the page.
	*/
	@HTMLBuilder
	var topParts: some HTML {
		Deferred(splash)

		gif(.flamesBar, style: .centered)

		div {
			gif(.globe, style: .globe)

			// `geocities.js` focuses it when the visitor enters from the splash.
			h1(.id(Hooks.welcome), .tabindex(-1)) {
				"Welcome to Sindre’s Home Page!!!"
			}
			.style(Styles.title)

			gif(.globe, style: .globe)
		}
		.style(Styles.header)

		div {
			p {
				"★ \(Site.description) ★ \(content.activeApps.count) apps and counting ★ Thanks for stopping by! ★"
			}
			.style(Styles.marqueeText)
		}
		.style(Styles.marquee)

		gif(.dividerSparkle, style: .centered)

		// About me and my computer come first, as they are what a visitor comes for.
		section {
			// The photo loads line by line, like over a modem in 1999, as a gray cover moves down from the top of it.
			div {
				img(.src(Site.author.photoPath), .alt("\(Site.author.name) profile photo"), .width(96), .height(96))
					.style(Styles.photo)

				div {}
					.style(Styles.photoLoading)
			}
			.style(Styles.photoFrame)

			h2 {
				"About Me"
			}
			.style(Styles.heading)

			p {
				"Hi, I’m Sindre. I make apps and open-source software full time. This is my corner of the World Wide Web!"
			}

			p {
				gif(.norwayFlag, alt: "The flag of Norway")
				" "
				strong {
					"Hilsen fra Norge!"
				}
				" That is Norwegian for “Greetings from Norway!” We have the Internet here too."
			}

			Deferred(aboutMe)

			figure {
				div {
					gif(.kidComputer, alt: "A kid at a computer")
					gif(.propellerHat, alt: "A propeller hat")
				}

				figcaption {
					"Me in 1999, coding with my thinking cap on (artist’s impression)"
				}
				.style(Styles.caption)
			}
			.style(Styles.figure)

			p {
				"Want more? Read the rest of my "
				a(.href(.about)) {
					"about page"
				}
				", or go back to "
				a(.href(.root)) {
					"my web site from the future"
				}
				"."
			}

			gif(.dividerBirds, style: .centered)
		}
		.style(Styles.section)

		gif(.dividerStars, style: .centered)

		Deferred(desktop)

		gif(.dividerSparkle, style: .centered)

		Deferred(newMail)

		Deferred(banner)

		div {
			Deferred(siteMap)
			Deferred(zombo)
		}
		.style(Styles.columns)

		Deferred(newsTicker)

		Deferred(GeoCitiesBigButtons())

		gif(.dividerLaser, style: .centered)

		Deferred(GeoCitiesCracktro(project: content.project))

		Deferred(GeoCitiesKeygen())

		gif(.dividerHelix, style: .centered)

		Deferred(GeoCitiesEffectToys(project: content.project))

		gif(.dividerLaser, style: .centered)

		Deferred(midiPlayer)

		Deferred(construction)

		gif(.dividerRainbow, style: .centered)

		Deferred(popUp)

		gif(.dividerDolphin, style: .centered)

		Deferred(lakeApplet)

		Deferred(GeoCitiesPets(project: content.project))

		gif(.dividerBirds, style: .centered)

		Deferred(GeoCitiesComicChat())

		Deferred(GeoCitiesFishTank(project: content.project))

		gif(.dividerFlowers, style: .centered)

		Deferred(GeoCitiesTown(project: content.project))

		Deferred(GeoCitiesLemmings())

		Deferred(GeoCitiesCoaster())

		gif(.dividerLights, style: .centered)

		section {
			h2 {
				"My Apps"
			}
			.style(Styles.heading)

			if let newestApp = content.newestApp {
				p {
					gif(.whatsNew, alt: "What’s new?")
				}
				.style(Styles.centeredText)

				p {
					gif(.newFlames, alt: "New!")
					" "
					span {
						"NEW!"
					}
					.style(Styles.new)

					" Check out my newest app, "
					a(.href(newestApp.url)) {
						newestApp.title
					}
					"!"
				}
			}

			Deferred(webring)

			gif(.dividerStarburst, style: .centered)
		}
		.style(Styles.section)

		Deferred(y2k)

		Deferred(sindreCam)

		Deferred(GeoCitiesAdventure(project: content.project))

		Deferred(GeoCitiesWaffleQuest())

		Deferred(GeoCitiesInsultFight())

		Deferred(GeoCitiesWaffleClues())

		Deferred(GeoCitiesLinkingBook(project: content.project))

		Deferred(GeoCitiesBergenTrail())

		gif(.dividerFuse, style: .centered)
	}

	/**
	Part 2 of the 4 parts of the panel, in the order of the page.
	*/
	@HTMLBuilder
	var middleParts: some HTML {
		Deferred(GeoCitiesBestViewed(project: content.project))

		gif(.dividerRainbowDashes, style: .centered)

		Deferred(GeoCitiesCoolText(project: content.project))

		gif(.dividerComet, style: .centered)

		div {
			Deferred(GeoCitiesNeonSign(project: content.project))
			Deferred(GeoCitiesComputer(project: content.project))
		}
		.style(Styles.columns)

		gif(.dividerHazard, style: .centered)

		gif(.constructionBlinkers, alt: "Under construction", style: .centered)

		Deferred(GeoCitiesGIFPile(project: content.project))

		Deferred(GeoCitiesDeskToys())

		gif(.flamesWide, style: .centered)

		gif(.dividerPacman, style: .centered)

		gif(.dividerDots, style: .centered)

		Deferred(game)

		Deferred(snake)

		Deferred(GeoCitiesBopIt())

		Deferred(GeoCitiesRubik())

		gif(.dividerRainbow, style: .centered)

		Deferred(pet)

		gif(.dividerDog, style: .centered)

		div {
			Deferred(petRock)
			Deferred(fortune)
		}
		.style(Styles.columns)

		gif(.dividerLights, style: .centered)

		Deferred(quiz)

		Deferred(GeoCitiesMacOS(project: content.project))

		gif(.dividerPacman, style: .centered)

		Deferred(GeoCitiesArcade(project: content.project))

		Deferred(GeoCitiesCommodore())
	}

	/**
	Part 3 of the 4 parts of the panel, in the order of the page.
	*/
	@HTMLBuilder
	var lowerParts: some HTML {
		Deferred(GeoCitiesGameRoom(project: content.project))

		Deferred(GeoCitiesWorms())

		gif(.dividerStars, style: .centered)

		Deferred(GeoCitiesRoom(project: content.project))

		Deferred(GeoCitiesRoomToys())

		Deferred(GeoCitiesFurby())

		Deferred(GeoCitiesKinderEgg())

		gif(.dividerRainbow, style: .centered)

		Deferred(GeoCitiesLego())

		Deferred(GeoCitiesCrafts())

		Deferred(GeoCitiesHandheld())

		Deferred(GeoCitiesHandheldCamera())

		Deferred(GeoCitiesMusic(project: content.project))

		gif(.dividerStars, style: .centered)

		Deferred(GeoCitiesNorwayHolidays(project: content.project))

		Deferred(GeoCitiesChristmas(project: content.project))

		Deferred(GeoCitiesNorwayDays())

		Deferred(GeoCitiesMarbles())

		Deferred(GeoCitiesClassNotes())

		Deferred(GeoCitiesCalculator())

		gif(.dividerHot, style: .centered)

		section(.id("geocities-links")) {
			gif(.hot, alt: "Hot!", style: .floating)

			h2 {
				gif(.fire, style: .flame)
				" Cool Links "
				gif(.fire, style: .flame)
			}
			.style(Styles.heading)

			ul {
				li {
					gif(.starSpin, style: .bullet)
					a(.href(.blog)) {
						"My blog (it has an RSS feed!)"
					}
					" "
					gif(.newYellow, alt: "New!")
					" "
					gif(.hotFlames, alt: "Hot!")
				}

				li {
					gif(.starSpin, style: .bullet)
					a(.href(.now)) {
						"What I’m doing now"
					}
					" "
					gif(.newSmall, alt: "New!")
					" "
					gif(.newRainbow, alt: "New!")
				}

				// Every other link has a bouncing ball as its bullet, for variety.
				for (index, link) in Site.author.socialLinks.enumerated() {
					li {
						gif(index.isMultiple(of: 2) ? .bulletBall : .starSpin, style: .bullet)
						a(.href(.url(link.url))) {
							"Me on \(link.name)"
						}

						if index == 0 {
							" "
							gif(.hotBurst, alt: "Hot!")
						}
					}
				}
			}
			.style(Styles.links)

			p {
				gif(.constructionPage, alt: "Page under construction", style: .centered)
				"More cool links coming soon!"
			}
			.style(Styles.centeredText)

			p {
				gif(.cautionSlowWebmaster, alt: "Caution: slow webmaster")
			}
			.style(Styles.centeredText)

			gif(.dividerAnts, style: .centered)
		}
		.style(Styles.section)

		Deferred(topLinks)

		Deferred(coolSite)

		gif(.dividerLights, style: .centered)

		div {
			Deferred(butler)
			Deferred(funFact)
		}
		.style(Styles.columns)

		gif(.dividerStars, style: .centered)

		div {
			Deferred(weather)
			Deferred(icq)
		}
		.style(Styles.columns)

		gif(.dividerDots, style: .centered)

		Deferred(poll)

		Deferred(GeoCitiesWinterGames(project: content.project))

		Deferred(GeoCitiesSkater(project: content.project))

		Deferred(GeoCitiesWorldCup())

		Deferred(computerReport)

		Deferred(matrix)

		Deferred(awards)

		Deferred(hallOfFame)

		gif(.dividerRainbow, style: .centered)

		Deferred(GeoCitiesVCR())

		Deferred(GeoCitiesTekstTV())

		Deferred(GeoCitiesInbox(project: content.project))

		Deferred(GeoCitiesBuddyList())

		Deferred(GeoCitiesBeeper())

		gif(.dividerLights, style: .centered)
	}

	/**
	Part 4 of the 4 parts of the panel, in the order of the page.
	*/
	@HTMLBuilder
	var bottomParts: some HTML {
		Deferred(GeoCitiesNapster(project: content.project))

		Deferred(GeoCitiesTradingCards(project: content.project))

		Deferred(GeoCitiesDollz())

		gif(.dividerStars, style: .centered)

		Deferred(GeoCitiesPageMaker(project: content.project))

		Deferred(GeoCitiesPrintShop())

		Deferred(GeoCitiesFortuneToys())

		Deferred(GeoCitiesY2KKit())

		Deferred(GeoCitiesMailOrder())

		gif(.dividerBalls, style: .centered)

		Deferred(guestbook)

		gif(.dividerHearts, style: .centered)

		Deferred(shrine)

		Deferred(GeoCitiesMusicRoom(project: content.project))

		Deferred(GeoCitiesDanceRevolution())

		gif(.underConstructionTape, style: .centered)

		div {
			Deferred(downloads)
			Deferred(displayProperties)
		}
		.style(Styles.columns)

		section {
			h2 {
				"Dance Party!"
			}
			.style(Styles.heading)

			p {
				"Everybody is invited. Bring your floppy disks."
			}

			gif(.discoLights, style: .centered)

			gif(.dividerDiscoDots, style: .centered)

			div {
				gif(.dancingBaby, alt: "The dancing baby")
				gif(.dancingBanana, alt: "A dancing banana")
				gif(.dancingFrog, alt: "A frog in a top hat, dancing")
				gif(.dancingMoonwalk, alt: "A man doing the moonwalk")
				gif(.dancingBallet, alt: "A man in a tutu, dancing ballet")
				gif(.skeleton, alt: "A dancing skeleton")
				gif(.stickDance, alt: "A dancing stick figure")
				gif(.sparkles)
				gif(.jumpRope, alt: "A girl jumping rope")
				gif(.walkingComputer, alt: "A walking computer")
				gif(.hamster, alt: "A hamster, dancing like on the Hampster Dance")
				gif(.smileyComputer, alt: "A computer blowing smoke")
			}
			.style(Styles.row)
		}
		.style(Styles.section)

		gif(.dividerFlowers, style: .centered)

		Deferred(gifWall)

		gif(.dividerEyes, style: .centered)

		gif(.dividerRainbow, style: .centered)

		div {
			Deferred(asciiArt)
			Deferred(linkToMe)
		}
		.style(Styles.columns)

		gif(.flamesBar, style: .centered)

		ul {
			li {
				gif(.buttonSindre, alt: "Sindre’s Home Page")
			}

			for button in Self.buttons {
				li {
					gif(button.gif, alt: button.text)
				}
			}

			for badge in ["Best viewed with any browser", "Made on a Mac", "Tabs, not spaces"] {
				li {
					badge
				}
				.style(Styles.badge)
			}
		}
		.accessibilityLabel("Badges")
		.style(Styles.badges)

		footer {
			p {
				gif(.comeBack, alt: "Come back soon!")
			}

			gif(.dividerEmail, style: .centered)

			p {
				gif(.sendEmail, alt: "Questions? Comments? Send email")
			}

			p(.id("geocities-mail")) {
				a(.href(.contact)) {
					gif(.emailAtRed)
					gif(.mailRocket)
					" E-mail me! "
					gif(.fishMail, alt: "Hey! Drop me a line!")
					gif(.atGold)
				}
			}

			p {
				gif(.envelopeFlying)
				" "
				gif(.mailMeRainbow, alt: "Mail me!")
				" "
				gif(.envelopeFlying)
			}

			p {
				gif(.smiley)
				" Thanks for visiting! Come back soon! "
				gif(.sparkle)
				gif(.coolSun)
			}

			p {
				a(.href("#\(Hooks.welcome.rawValue)")) {
					gif(.topArrow)
					" Back to the top"
				}
			}

			p {
				a(.href(.root)) {
					gif(.home)
					gif(.homeHouse)
					"Back to my web site from the future"
					gif(.homeNeon)
				}
			}

			p {
				"AOL Keyword: "
				strong {
					"Sindre"
				}
				" ★ This page is Y2K compliant (probably) ★ No frames were harmed in the making of this page"
			}
			.style(Styles.caption)

			p {
				gif(.globeSmall)
				" Last updated: December 31, 1999"
			}
			.style(Styles.caption)

			// `geocities.js` fills it with the size of the page and how long it would take to load over a modem.
			p(.id(Hooks.loadTime)) {}
				.style(Styles.caption, Styles.scriptingOnly)

			p {
				a(.href("mailto:?subject=\("Check out this cool home page!".addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")&body=\("\(Site.url.absoluteString)\(RoutePath.geoCities)".addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")")) {
					"Tell a friend about my page!"
				}
				" ★ "
				button(.id(Hooks.bookmark), .type(.button)) {
					"Bookmark me!"
				}
				.style(Styles.retroButton, Styles.scriptingOnly)
			}

			// `geocities.js` shows it when the visitor types the Konami code.
			p(.id(Hooks.secret), .hidden, .tabindex(-1)) {
				gif(.unicorn, style: .centered)
				"Cheat code accepted! You have unlocked 30 extra unicorns."
			}
			.style(Styles.secret)
		}
		.style(Styles.centeredText)
	}

	/**
	An animated GIF of the page.

	- Parameter alt: The text of the image, or nothing when it is only decoration.
	*/
	func gif(_ gif: GIF, alt: String = "", style: Styles = .gif) -> GIFImage {
		GIFImage(gif: gif, alt: alt, style: style, project: content.project)
	}
}

extension GeoCitiesPage {
	/**
	A part of the 1999 page that is made only when it renders. The page has so many parts that its body, with all of them in it, is too large for the stack of a thread, so each part is only a closure in the body.
	*/
	struct Deferred<Content: HTML>: HTML {
		private let content: () -> Content

		init(_ content: @autoclosure @escaping () -> Content) {
			self.content = content
		}

		var body: Content {
			content()
		}
	}

	/**
	An animated GIF of the 1999 page, with its size from the file. A GIF that moves shows its still frame to visitors who prefer reduced motion.

	A missing file, like in a test without the public files, has no size. The link check of the build finds it.
	*/
	struct GIFImage: HTML {
		let gif: GeoCitiesPage.GIF
		let alt: String
		let style: GeoCitiesPage.Styles
		let project: Project

		var body: some HTML {
			let size = project.publicFile(gif.path).mediaSize
			let stillPath = project.publicFile(gif.stillPath).isFile ? gif.stillPath : nil

			return picture {
				if let stillPath {
					source(.media(.reducedMotion), .srcset(stillPath))
				}

				// The page has hundreds of GIFs, so each loads when it comes near the window. They all have a size, so nothing moves when they load.
				img(.src(gif.path), .alt(alt), .lazyLoading)
					.attributes(.width(size?.width ?? 0), .height(size?.height ?? 0), when: size != nil)
					.style(GeoCitiesPage.Styles.gif, style)
			}
			.style(GeoCitiesPage.Styles.picture)
		}
	}
}
