import Elementary
import Foundation
import SiteKit

extension GeoCitiesPage {
	/**
	A note at the top for visitors who come back, like “You have new mail!”, from my mom or Glitter. `geocities.js` shows it from the second visit, and the close button hides it.
	*/
	var newMail: some HTML {
		div(.id(Hooks.newMail), .hidden) {
			gif(.envelope)

			p(.id(Hooks.newMailText), .role("status")) {}

			button(.id(Hooks.newMailClose), .type(.button)) {
				"×"
			}
			.accessibilityLabel("Close the message")
			.style(Styles.closeButton)
		}
		.style(Styles.newMail)
	}

	/**
	A site map like the navigation frame of a home page from 1999, with an animated button for each big part of the page. The page is long, so it helps too.
	*/
	var siteMap: some HTML {
		nav {
			h2 {
				"Site Map"
			}
			.style(Styles.titleBar)

			ul {
				for item in Self.siteMapItems {
					li {
						a(.href("#\(item.anchor)")) {
							gif(item.gif)
							span {
								item.title
							}
						}
						.style(Styles.siteMapLink)
					}
				}
			}
			.style(Styles.siteMapList)

			p {
				"This would be a frame, but my mom says frames are bad for you."
			}
			.style(Styles.caption, Styles.centeredText)
		}
		.accessibilityLabel("Site map")
		.style(Styles.window, Styles.siteMap)
	}

	/**
	A welcome like the one of Zombo.com, a page of 1999 that only had a spinning circle and a voice that said that you can do anything there.
	*/
	var zombo: some HTML {
		section {
			gif(.welcomeTo, alt: "Welcome to")

			p {
				"Sindre’s Page"
			}
			.style(Styles.zomboTitle)

			gif(.spinningWheel, style: .zomboWheel)

			p {
				"You can do "
				strong {
					"anything"
				}
				.style(Styles.rainbowText)
				" at Sindre’s page."
			}

			p {
				"Anything at all. The only limit is yourself."
			}

			p {
				"Welcome… to Sindre’s page."
			}
			.style(Styles.caption)
		}
		.style(Styles.zombo)
	}

	/**
	A news ticker that scrolls up, like a `<marquee direction="up">`, and a dolphin that swims back and forth, like a `<marquee behavior="alternate">`. Both stand still for visitors who prefer reduced motion, and the ticker then shows all the news.
	*/
	var newsTicker: some HTML {
		div {
			div {
				p {
					gif(.newAndUpdated, alt: "New and updated")
					" "
					gif(.newSpin, alt: "New!")
				}
				.style(Styles.centeredText)

				div {
					ul {
						for item in Self.news {
							li {
								strong {
									"\(item.date): "
								}
								item.text
							}
						}
					}
					.style(Styles.tickerList)
				}
				.style(Styles.ticker)
			}
			.style(Styles.window, Styles.windowBody)

			div {
				gif(.dolphin, style: .bouncer)

				p {
					"~ Dolphins are the unicorns of the sea ~"
				}
				.style(Styles.bounceText)
			}
			.style(Styles.bounceStrip)
		}
		.style(Styles.section)
	}

	/**
	A Java applet, like the ones that took a minute to start in 1999: a gray box with the coffee cup of Java that loads, and then the Lake applet, which shows a picture with its reflection in rippling water. `geocities.js` loads it when it comes into view and draws the water on a canvas, like the real applet: each row of the reflection is the picture upside down, moved sideways by a wave. The water stands still for visitors who prefer reduced motion.
	*/
	var lakeApplet: some HTML {
		section(.id("geocities-java")) {
			h2 {
				gif(.hotJava, alt: "Hot Java")
				" "
				gif(.hotBadge, alt: "Hot!")
			}
			.style(Styles.centeredText)

			p {
				"My page has a Java applet now! It is called Lake. Please be patient while it loads. It is worth it."
			}
			.style(Styles.centeredText)

			div(.id(Hooks.lake)) {
				div(.id(Hooks.lakeLoading)) {
					gif(.javaCup, alt: "A hot cup of Java")

					p {
						"Loading Java applet…"
					}

					div {
						div(.id(Hooks.lakeBar)) {}
							.style(Styles.progressFill)
					}
					.accessibilityHidden()
					.style(Styles.progressTrack, Styles.appletProgress)
				}
				.style(Styles.appletLoading)

				canvas(.id(Hooks.lakeCanvas), .width(320), .height(240), .hidden, .role("img")) {}
					.accessibilityLabel("A fjord in Norway at sunset, with Glitter on the shore, and its reflection in rippling water")
					.style(Styles.lakeCanvas)

				p(.id(Hooks.lakeStatus), .role("status")) {
					"Applet Lake: waiting…"
				}
				.style(Styles.appletStatus)
			}
			.style(Styles.applet, Styles.scriptingOnly)

			p {
				"Java needs JavaScript. Do not ask me why."
			}
			.style(Styles.scriptingDisabledOnly)
		}
		.style(Styles.section)
	}

	/**
	SindreCam, a webcam like the ones of 1999, which showed a new picture every 30 seconds. `geocities.js` shows the pictures one after the other, with TV static in between, and the time on each. The static is left out for visitors who prefer reduced motion. Without scripts, the first picture stays.
	*/
	var sindreCam: some HTML {
		section {
			h2 {
				gif(.cameraman)
				" SindreCam: LIVE! "
				gif(.hotBadge, alt: "Hot!")
			}
			.style(Styles.heading, Styles.centeredText)

			p {
				"See what I am doing right now! A new picture every 30 seconds. (The first webcam watched a coffee pot. Mine is much better.)"
			}
			.style(Styles.centeredText)

			div {
				div {
					for (index, scene) in Self.camScenes.enumerated() {
						figure(.hook(Hooks.camScene, value: "\(index)")) {
							gif(scene.gif, style: .webcamPicture)

							figcaption {
								scene.caption
							}
							.style(Styles.webcamCaption)
						}
						.attributes(.hidden, when: index > 0)
						.style(Styles.webcamScene)
					}

					canvas(.id(Hooks.camStatic), .width(160), .height(120), .hidden) {}
						.accessibilityHidden()
						.style(Styles.webcamStatic)

					p(.id(Hooks.camTime)) {
						"12/31/1999 11:59 PM"
					}
					.style(Styles.webcamTime)
				}
				.style(Styles.webcamScreen)

				div {
					p(.id(Hooks.camCountdown)) {
						"Next picture in 30 seconds"
					}
					.style(Styles.caption)

					button(.id(Hooks.camRefresh), .type(.button)) {
						"Refresh Now"
					}
					.style(Styles.smallButton)
				}
				.style(Styles.formRow, Styles.scriptingOnly)
			}
			.style(Styles.webcam)
		}
		.style(Styles.section)
	}

	/**
	The weather in Bergen, the rainiest city of Norway, where it always rains. `geocities.js` checks again, and it still rains.
	*/
	var weather: some HTML {
		section {
			h2 {
				gif(.lightning)
				" Weather in Bergen"
			}
			.style(Styles.heading)

			p {
				gif(.storm, alt: "A rain cloud")
			}
			.style(Styles.centeredText)

			dl {
				for item in Self.forecast {
					div {
						dt {
							"\(item.day):"
						}
						.style(Styles.factLabel)

						dd {
							item.weather
						}
						.style(Styles.factValue)
					}
				}
			}
			.style(Styles.facts)

			button(.id(Hooks.weatherCheck), .type(.button)) {
				"Check Again"
			}
			.style(Styles.retroButton, Styles.scriptingOnly)

			p(.id(Hooks.weatherStatus), .role("status")) {
				"Now: 7 °C and rain."
			}
			.style(Styles.lcd)
		}
		.style(Styles.section)
	}

	/**
	My status on ICQ, the chat program of 1999, from the time of day of the visitor: in school, eating, sleeping, or online. Also my mood. `geocities.js` sets both, and the button pretends to send a message.
	*/
	var icq: some HTML {
		section {
			h2 {
				gif(.phone)
				" Chat With Me!"
			}
			.style(Styles.heading)

			dl {
				div {
					dt {
						"ICQ number:"
					}
					.style(Styles.factLabel)

					dd {
						"19991231"
					}
					.style(Styles.factValue)
				}

				div {
					dt {
						"Status:"
					}
					.style(Styles.factLabel)

					dd {
						span(.id(Hooks.icqLight)) {
							gif(.flower, style: .icqFlower)
						}
						.style(Styles.icqLight)

						" "
						span(.id(Hooks.icqStatus)) {
							"Online"
						}
					}
					.style(Styles.factValue)
				}

				div {
					dt {
						"Mood:"
					}
					.style(Styles.factLabel)

					dd {
						gif(.happy)
						" "
						span(.id(Hooks.mood)) {
							"Hyper (I had three waffles)"
						}
					}
					.style(Styles.factValue)
				}
			}
			.style(Styles.facts)

			button(.id(Hooks.icqMessage), .type(.button)) {
				"Send Me a Message"
			}
			.style(Styles.retroButton, Styles.scriptingOnly)

			p(.id(Hooks.icqReply), .role("status")) {}
		}
		.style(Styles.section)
	}

	/**
	A shrine to waffles, like the shrines that home pages of 1999 had to a band or a TV show, with candles. The visitor lights a candle, and `geocities.js` counts the candles in the browser.
	*/
	var shrine: some HTML {
		section(.id("geocities-shrine")) {
			h2 {
				"My Shrine to Waffles"
			}
			.style(Styles.wordArt, Styles.centeredText)

			div {
				gif(.candleTall)
				gif(.candle)

				pre(.role("img")) {
					Self.asciiWaffle
				}
				.accessibilityLabel("A waffle in the shape of a heart, drawn with letters and symbols")
				.style(Styles.waffle)

				gif(.candle)
				gif(.candleTall)
			}
			.style(Styles.row)

			p {
				"Waffles with brown cheese are the best food in the world. This shrine is for them."
			}
			.style(Styles.centeredText)

			ul {
				for reason in Self.waffleReasons {
					li {
						gif(.candleSmall, style: .bullet)
						reason
					}
				}
			}
			.style(Styles.links)

			figure {
				gif(.toaster, alt: "A toaster with toast")

				figcaption {
					"My waffle iron (artist’s impression). It is a toaster. Do not tell my mom."
				}
				.style(Styles.caption)
			}
			.style(Styles.figure)

			p {
				button(.id(Hooks.candleLight), .type(.button)) {
					"Light a Candle for the Waffles"
				}
				.style(Styles.retroButton, Styles.scriptingOnly)
			}
			.style(Styles.centeredText)

			p(.id(Hooks.candleStatus), .role("status")) {}
				.style(Styles.centeredText)
		}
		.style(Styles.shrine)
	}

	/**
	Rocky, a pet rock, which needs nothing, unlike Glitter. Each button gets an answer from `geocities.js`, and it is always the same, as Rocky is a rock.
	*/
	var petRock: some HTML {
		section {
			h2 {
				"Adopt Rocky, My Pet Rock"
			}
			.style(Styles.heading)

			p {
				"Glitter too much work? Rocky needs no food, no walks, and no love. But he appreciates it."
			}

			div(.role("img")) {
				gif(.googlyEyes, style: .rockEyes)
			}
			.accessibilityLabel("Rocky, a gray rock with googly eyes")
			.style(Styles.rock)

			dl {
				for (label, value) in [("Age", "4.5 billion years"), ("Food", "Not needed"), ("Mood", "Rock solid")] {
					div {
						dt {
							"\(label):"
						}
						.style(Styles.factLabel)

						dd {
							value
						}
						.style(Styles.factValue)
					}
				}
			}
			.style(Styles.facts)

			div {
				for (action, title) in [("feed", "Feed"), ("pet", "Pet"), ("walk", "Walk"), ("trick", "Trick")] {
					button(.type(.button), .hook(Hooks.rockAction, value: action)) {
						title
					}
					.style(Styles.smallButton)
				}
			}
			.style(Styles.buttonRow, Styles.scriptingOnly)

			p(.id(Hooks.rockStatus), .role("status")) {}
		}
		.style(Styles.section)
	}

	/**
	A fortune cookie with the future of the visitor in the year 2000. `geocities.js` picks a fortune.
	*/
	var fortune: some HTML {
		section {
			h2 {
				"The Fortune Wizard"
			}
			.style(Styles.heading)

			p {
				gif(.wizard, alt: "A wizard with a magic staff")
			}
			.style(Styles.centeredText)

			p(.id(Hooks.fortuneText), .role("status")) {
				"The wizard sees your future in a fortune cookie. Crack one!"
			}
			.style(Styles.speech)

			button(.id(Hooks.fortuneCrack), .type(.button)) {
				"Crack a Fortune Cookie"
			}
			.style(Styles.retroButton, Styles.scriptingOnly)

			p {
				"The wizard needs JavaScript to see your future."
			}
			.style(Styles.scriptingDisabledOnly)
		}
		.style(Styles.section)
	}

	/**
	The Cool Site of the Week, which is mine, of course.
	*/
	var coolSite: some HTML {
		section {
			h2 {
				gif(.cool, alt: "Cool")
				" Cool Site of the Week"
			}
			.style(Styles.heading)

			p {
				gif(.goldStar, style: .floating)
				"This week’s winner is… "
				strong {
					"Sindre’s Home Page!"
				}
				" Congratulations to me. The judges (me) said: “Wow, so many GIFs.”"
			}
			.style(Styles.alertBox)
		}
		.style(Styles.section)
	}

	/**
	The Hall of Fame, with the best visitors: the visitor for the toys of the page, from what `geocities.js` finds in the browser, and others from 1999. Also a graph of the visits of 1999, as bars of text.
	*/
	var hallOfFame: some HTML {
		let mostHits = Self.hits.map(\.count).max() ?? 1

		return section {
			h2 {
				gif(.goldStar)
				" Hall\u{00A0}of\u{00A0}Fame "
				gif(.goldStar)
			}
			.style(Styles.heading, Styles.centeredText)

			dl {
				for (label, hook) in [("Best alien zapper", Hooks.fameScore), ("Most loyal visitor", Hooks.fameVisits), ("Best unicorn parent", Hooks.fameCare)] {
					div {
						dt {
							"\(label):"
						}
						.style(Styles.factLabel)

						dd(.id(hook)) {
							"Nobody yet. It could be you!"
						}
						.style(Styles.factValue)
					}
				}

				for (label, value) in [("Fastest guestbook signer", "Trond, in 4 seconds"), ("Longest visit", "mamma, 9 hours (she forgot to log off)")] {
					div {
						dt {
							"\(label):"
						}
						.style(Styles.factLabel)

						dd {
							value
						}
						.style(Styles.factValue)
					}
				}
			}
			.style(Styles.facts)

			h3 {
				gif(.counterDigits)
				" My Hits in 1999"
			}
			.style(Styles.subheading)

			ol {
				for item in Self.hits {
					li {
						"\(item.month) "
						span {
							String(repeating: "█", count: item.count * 20 / mostHits).padding(toLength: 20, withPad: "░", startingAt: 0)
						}
						.accessibilityHidden()
						" \(item.count) visits"
					}
				}
			}
			.accessibilityLabel("Visits in each month of 1999")
			.style(Styles.pollResults)

			p {
				"December was the Y2K panic. Everybody wanted to see my page one last time."
			}
			.style(Styles.caption)
		}
		.style(Styles.section)
	}

	/**
	A wall of animated GIFs, like the GIF collections of 1999, and a skull that the visitor should not click. `geocities.js` crashes the computer when the visitor clicks it anyway: the blue screen of Windows, and the next time, the bomb of the Mac.
	*/
	var gifWall: some HTML {
		section {
			h2 {
				"My GIF Collection"
			}
			.style(Styles.heading, Styles.centeredText)

			p {
				"I collected these from all over the World Wide Web. Please do not steal them. (Just kidding, I stole them too.)"
			}
			.style(Styles.centeredText)

			div {
				gif(.purpleUnicorn, alt: "A purple unicorn, galloping")
				gif(.pegasus, alt: "A flying horse")
				gif(.flyingPig, alt: "A pig with wings")
				gif(.dolphin, alt: "A dolphin")
				gif(.fishbowl, alt: "A fish in a bowl")
				gif(.rainbow, alt: "A rainbow")
				gif(.butterflies, alt: "Butterflies")
				gif(.monkey, alt: "A monkey that swings")
				gif(.coolCow, alt: "A cow with a propeller hat")
				gif(.waggingDog, alt: "A dog that wags its tail")
				gif(.cat, alt: "A cat that runs")
				gif(.dj, alt: "A record that spins")
				gif(.flames, alt: "Flames")

				button(.id(Hooks.skull), .type(.button)) {
					gif(.skull)
				}
				.accessibilityLabel("Do not click the skull")
				.style(Styles.skullButton, Styles.scriptingOnly)
			}
			.style(Styles.gifWall)

			p {
				"Do NOT click the skull!"
			}
			.style(Styles.caption, Styles.centeredText, Styles.scriptingOnly)
		}
		.style(Styles.section)
	}

	/**
	A helper like the paper clip of Office 97, but a floppy disk, who offers help when the visitor starts to write a guestbook entry. `geocities.js` shows it, unless the visitor asked it to never come back, which it keeps in the browser.
	*/
	var guestbookHelper: some HTML {
		div(.id(Hooks.helper), .hidden) {
			gif(.floppy, alt: "Floppy, the helper")

			div {
				p(.id(Hooks.helperText), .role("status")) {}
					.style(Styles.speech)

				div {
					for (answer, title) in [("yes", "Yes, please"), ("no", "No"), ("never", "Don’t show this again")] {
						button(.type(.button), .hook(Hooks.helperAnswer, value: answer)) {
							title
						}
						.style(Styles.smallButton)
					}
				}
				.style(Styles.buttonRow)
			}
			.style(Styles.helperBody)
		}
		.style(Styles.helper)
	}

	/**
	The certificate for the iMac of the banner ad, which only shows in a print. The button below the banner prints it after a catch, and a print of the page without a catch gets it too, with a note that there is no iMac.
	*/
	var certificate: some HTML {
		div(.id(Hooks.certificate)) {
			p {
				"Certificate of Winning"
			}
			.style(Styles.wordArt)

			gif(.iMac, alt: "An iMac")

			p(.id(Hooks.certificateText)) {
				"This certifies that you printed my page instead of catching the star. No iMac for you, but here is a picture of one."
			}

			p {
				"This picture is your iMac. Plug it in to start."
			}
			.style(Styles.caption)

			p {
				"Signed: Sindre, Webmaster, December 31, 1999"
			}
		}
		.style(Styles.certificate)
	}
}
