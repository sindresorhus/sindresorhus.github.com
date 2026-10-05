import Elementary
import Foundation
import SiteKit

extension GeoCitiesPage {
	/**
	A splash at the top, like the ones that came before so many home pages: “Click here to enter”. The link goes to the title below it, so the page works without scripts, and `geocities.js` first dials up to the Internet, with the steps in a status and the sound of a modem, and then hides the splash and focuses the title. It never covers the page, as the page is right below it.
	*/
	var splash: some HTML {
		div(.id(Hooks.splash)) {
			p {
				"You have reached"
			}
			.style(Styles.caption)

			p {
				"Sindre’s World Wide Web Site"
			}
			.style(Styles.wordArt)

			a(.id(Hooks.enter), .href("#\(Hooks.welcome.rawValue)")) {
				"Click here to enter"
			}
			.style(Styles.enter)

			gif(.modem, alt: "A modem with blinking lights")

			p(.id(Hooks.dialUp), .role("status")) {}
				.style(Styles.dialUp)

			p {
				"Best viewed at 800 × 600 with Netscape Navigator 4.0 or Opera 3.6 (it is made in Norway!). Please wait for all the GIFs to load. Turn up your speakers for the modem!"
			}
			.style(Styles.caption)
		}
		.style(Styles.splash)
	}

	/**
	A banner ad of 468×60, like the ones that free hosts put at the top of home pages, where the visitor catches a star that moves back and forth to “win” an iMac. `geocities.js` counts the catches. With reduced motion, the star stands still.
	*/
	var banner: some HTML {
		div {
			div {
				p {
					"★ CATCH THE STAR AND WIN A FREE iMac!!! ★"
				}
				.style(Styles.bannerText)

				button(.id(Hooks.bannerStar), .type(.button)) {
					"★"
				}
				.accessibilityLabel("Catch the star")
				.style(Styles.bannerStar, Styles.scriptingOnly)
			}
			.style(Styles.banner)

			p(.id(Hooks.bannerStatus), .role("status")) {
				"Advertisement"
			}
			.style(Styles.caption)

			// `geocities.js` shows it when the visitor catches the star.
			button(.id(Hooks.bannerPrint), .type(.button), .hidden) {
				"Print My iMac!"
			}
			.style(Styles.retroButton)
		}
		.style(Styles.centeredText)
	}

	/**
	The questions of Who Wants to Be a Unicornaire?, from $100 to $1,000,000. The last one is about my apps, so its answer follows the content.
	*/
	var quizQuestions: [QuizQuestion] {
		let appCount = content.activeApps.count

		return [
			QuizQuestion(prize: "$100", question: "What does “WWW” stand for?", answers: ["Wild Wild West", "World Wide Web", "Wonderful Waffle World", "Windows Will Work"], correct: 1),
			QuizQuestion(prize: "$500", question: "What is the national animal of Scotland?", answers: ["The haggis", "The sheep", "The unicorn", "The Loch Ness Monster"], correct: 2),
			QuizQuestion(prize: "$1,000", question: "Which web browser is made in Norway?", answers: ["Opera", "Netscape Navigator", "Mosaic", "Lynx"], correct: 0),
			QuizQuestion(prize: "$8,000", question: "What sound does a 56k modem make when it connects?", answers: ["Beep", "Screech", "Bong", "All of them, at the same time"], correct: 3),
			QuizQuestion(prize: "$32,000", question: "What do Norwegians call brown cheese?", answers: ["Lefse", "Brunost", "Pølse", "Smørbrød"], correct: 1),
			QuizQuestion(prize: "$125,000", question: "In what year did the Tamagotchi come out in Japan?", answers: ["1989", "1993", "1996", "1999"], correct: 2),
			QuizQuestion(prize: "$500,000", question: "After 99 comes 00. Which year do some old computers think that is?", answers: ["2000", "1900", "3000", "1066"], correct: 1),
			QuizQuestion(prize: "$1,000,000", question: "How many apps has Sindre made?", answers: ["3", "\(appCount)", "\(appCount + 11)", "Infinity"], correct: 1),
		]
	}

	/**
	Who Wants to Be a Unicornaire?, like the quiz show of 1999, with eight questions, two safe levels, and three lifelines: 50:50, Phone a Friend (my mom, who answers in Norwegian), and Ask the Audience. `geocities.js` runs it.
	*/
	var quiz: some HTML {
		section(.id("geocities-quiz")) {
			h2 {
				"Who Wants to Be a Unicornaire?"
			}
			.style(Styles.quizTitle)

			p {
				"Answer 8 questions and win $1,000,000 unicorn dollars! Is that your final answer?"
			}
			.style(Styles.centeredText)

			div {
				p(.id(Hooks.quizPrize)) {
					"Press Play to start!"
				}
				.style(Styles.quizPrize)

				p(.id(Hooks.quizQuestion), .hidden) {}
					.style(Styles.quizQuestion)

				div(.id(Hooks.quizAnswers), .hidden, .role("group"), .ariaLabelledBy(Hooks.quizQuestion.rawValue)) {
					for (index, letter) in ["A", "B", "C", "D"].enumerated() {
						button(.type(.button), .hook(Hooks.quizAnswer, value: "\(index)")) {
							"\(letter): "
						}
						.style(Styles.quizAnswer)
					}
				}
				.style(Styles.quizAnswers)

				div(.id(Hooks.quizLifelines), .hidden) {
					for (lifeline, title) in [("fifty", "50:50"), ("phone", "Phone a Friend"), ("audience", "Ask the Audience")] {
						button(.type(.button), .hook(Hooks.quizLifeline, value: lifeline)) {
							title
						}
						.style(Styles.quizButton)
					}
				}
				.style(Styles.buttonRow)

				p(.id(Hooks.quizStatus), .role("status")) {}
					.style(Styles.quizStatus)

				button(.id(Hooks.quizStart), .type(.button)) {
					"Play!"
				}
				.style(Styles.quizButton)
			}
			.style(Styles.quiz, Styles.scriptingOnly)

			p {
				"The quiz needs JavaScript. Final answer."
			}
			.style(Styles.scriptingDisabledOnly)
		}
		.style(Styles.section)
	}

	/**
	A report about the computer of the visitor, like the browser sniffers of 1999: the browser, the system, the screen, the colors, and how long the visitor has been online, with the phone bill. `geocities.js` fills it in the browser. Nothing leaves the browser.
	*/
	var computerReport: some HTML {
		section {
			h2 {
				gif(.walkingComputer)
				" Your Computer Report"
			}
			.style(Styles.heading)

			p {
				"My page can see your computer! (It stays between us.)"
			}

			dl {
				for (label, hook) in [("Browser", Hooks.reportBrowser), ("Computer", Hooks.reportSystem), ("Screen", Hooks.reportScreen), ("Colors", Hooks.reportColors), ("Online for", Hooks.reportOnline), ("Phone bill", Hooks.reportBill)] {
					div {
						dt {
							"\(label):"
						}
						.style(Styles.factLabel)

						dd(.id(hook)) {
							"Checking…"
						}
						.style(Styles.factValue)
					}
				}
			}
			.style(Styles.facts, Styles.scriptingOnly)

			p {
				"Turn on JavaScript, so I can see your computer."
			}
			.style(Styles.scriptingDisabledOnly)
		}
		.style(Styles.section)
	}

	/**
	The Matrix came out in 1999. The red pill shows its falling green code over the window for a few seconds, and the blue pill does nothing. `geocities.js` runs it. With reduced motion, the code does not fall, and a message says what the visitor would have seen.
	*/
	var matrix: some HTML {
		section {
			h2 {
				"Wake up, Neo…"
			}
			.style(Styles.matrixTitle)

			p {
				"The Matrix came out this year, and it is the best movie ever made. This is your last chance. Which pill do you take?"
			}

			div {
				button(.type(.button), .hook(Hooks.pill, value: "red")) {
					"Red Pill"
				}
				.style(Styles.pill, Styles.redPill)

				button(.type(.button), .hook(Hooks.pill, value: "blue")) {
					"Blue Pill"
				}
				.style(Styles.pill, Styles.bluePill)
			}
			.style(Styles.buttonRow, Styles.scriptingOnly)

			p(.id(Hooks.matrixStatus), .role("status")) {}

			p {
				"The pills need JavaScript. You are stuck in the Matrix."
			}
			.style(Styles.scriptingDisabledOnly)
		}
		.style(Styles.matrixBox)
	}

	/**
	Free downloads, like the downloads pages of 1999, with a progress window that takes forever and usually fails, as somebody picks up the phone. Only the recipe arrives. `geocities.js` runs it.
	*/
	var downloads: some HTML {
		section(.id("geocities-downloads")) {
			h2 {
				"Free Downloads!"
			}
			.style(Styles.heading)

			p {
				"All files are virus-free. I checked with Norton AntiVirus 2000."
			}

			ul {
				for (file, description) in [("sindre.scr", "My Flying Unicorns screen saver (1.4 MB)"), ("glitter.exe", "Glitter for your desktop (3.2 MB)"), ("waffles.txt", "My secret waffle recipe (1 KB)")] {
					li {
						strong {
							file
						}
						": \(description) "
						button(.type(.button), .hook(Hooks.download, value: file)) {
							"Download"
						}
						.style(Styles.smallButton, Styles.scriptingOnly)
					}
				}
			}
			.style(Styles.downloadList)

			p {
				"Downloading needs JavaScript. And a lot of patience."
			}
			.style(Styles.scriptingDisabledOnly)

			div(.id(Hooks.downloadWindow), .hidden) {
				h3(.id(Hooks.downloadTitle)) {
					"Downloading…"
				}
				.style(Styles.titleBar)

				div {
					p(.id(Hooks.downloadText), .role("status")) {}

					div {
						div(.id(Hooks.downloadBar)) {}
							.style(Styles.progressFill)
					}
					.accessibilityHidden()
					.style(Styles.progressTrack)

					p(.id(Hooks.downloadTime)) {}
						.style(Styles.caption)

					button(.id(Hooks.downloadCancel), .type(.button)) {
						"Cancel"
					}
					.style(Styles.retroButton)
				}
				.style(Styles.windowBody)
			}
			.style(Styles.window)
		}
		.style(Styles.section)
	}

	/**
	The Display Properties of Windows 95, which change the page: the wallpaper, the screen saver, with a preview on a small monitor, and its wait, the mouse trail, the snow, and the title that scrolls in the tab. `geocities.js` runs it and keeps the settings in the browser. The screen saver, the trail, the snow, and the title stand still for visitors who prefer reduced motion.
	*/
	var displayProperties: some HTML {
		section {
			h2 {
				"Display Properties"
			}
			.style(Styles.titleBar)

			div {
				div {
					label(.for(Hooks.wallpaper.rawValue)) {
						"Wallpaper:"
					}

					select(.id(Hooks.wallpaper)) {
						for (color, name) in [("#000033", "Starry Night"), ("#008080", "Teal (like Windows 95)"), ("#ff1493", "Hot Pink"), ("#4b0082", "Purple Haze"), ("#003300", "The Matrix")] {
							option(.value(color)) {
								name
							}
						}
					}
					.style(Styles.field, Styles.select)
				}
				.style(Styles.formRow)

				// A monitor that shows the screen saver, like the preview of Windows.
				div {
					canvas(.id(Hooks.saverMonitor), .width(160), .height(120)) {}
						.style(Styles.monitorScreen)
				}
				.accessibilityHidden()
				.style(Styles.monitor)

				div {
					label(.for(Hooks.saverKind.rawValue)) {
						"Screen saver:"
					}

					select(.id(Hooks.saverKind)) {
						for (kind, name) in [("unicorns", "Flying Unicorns"), ("pipes", "3D Pipes"), ("starfield", "Starfield"), ("mystify", "Mystify"), ("none", "(None)")] {
							option(.value(kind)) {
								name
							}
						}
					}
					.style(Styles.field, Styles.select)
				}
				.style(Styles.formRow)

				div {
					label(.for(Hooks.saverWait.rawValue)) {
						"Wait:"
					}

					select(.id(Hooks.saverWait)) {
						for (seconds, name) in [("60", "1 minute"), ("120", "2 minutes"), ("300", "5 minutes")] {
							option(.value(seconds)) {
								name
							}
							.attributes(.selected, when: seconds == "120")
						}
					}
					.style(Styles.field, Styles.select)
				}
				.style(Styles.formRow)

				button(.id(Hooks.saverPreview), .type(.button)) {
					"Preview Screen Saver"
				}
				.style(Styles.retroButton)

				div {
					gif(.mouse, style: .mouseGIF)

					label(.for(Hooks.trailKind.rawValue)) {
						"Mouse trail:"
					}

					select(.id(Hooks.trailKind)) {
						for (kind, name) in [("sparkles", "Sparkles"), ("elastic", "Elastic balls"), ("clock", "Clock"), ("none", "(None)")] {
							option(.value(kind)) {
								name
							}
						}
					}
					.style(Styles.field, Styles.select)
				}
				.style(Styles.formRow)

				div {
					input(.id(Hooks.snow), .type(.checkbox), .checked)

					label(.for(Hooks.snow.rawValue)) {
						"Let it snow (it is always December 1999 here!)"
					}
				}
				.style(Styles.choice)

				div {
					input(.id(Hooks.titleScroll), .type(.checkbox), .checked)

					label(.for(Hooks.titleScroll.rawValue)) {
						"Scroll the title in the tab"
					}
				}
				.style(Styles.choice)

				p {
					"Your settings stay in your browser."
				}
				.style(Styles.caption)
			}
			.style(Styles.windowBody)
		}
		.style(Styles.window, Styles.scriptingOnly)
	}

	/**
	A MIDI jukebox, like the background music of old home pages, but it only plays after a click on Play, and it stops when the tab is hidden. `geocities.js` plays the tune with Web Audio, as a square wave, quietly. The tunes are old enough to be in the public domain.
	*/
	var midiPlayer: some HTML {
		div(.id("geocities-jukebox")) {
			h2 {
				span {
					"♫"
				}
				.accessibilityHidden()
				" MIDI Jukebox"
			}
			.style(Styles.titleBar)

			div {
				gif(.sound, alt: "Sound!", style: .centered)

				p(.id(Hooks.midiStatus), .role("status")) {
					"Ready to rock! Turn your speakers down first."
				}
				.style(Styles.lcd)

				// Bars like the spectrum of Winamp, which `geocities.js` makes bounce while a tune plays.
				div(.id(Hooks.spectrum)) {
					for _ in 0..<16 {
						span {}
							.style(Styles.spectrumBar)
					}
				}
				.accessibilityHidden()
				.style(Styles.spectrum, Styles.scriptingOnly)

				div {
					label(.for(Hooks.midiTune.rawValue)) {
						"Song:"
					}

					select(.id(Hooks.midiTune)) {
						for tune in Self.tunes {
							option(.value(tune.file)) {
								tune.file
							}
						}
					}
					.style(Styles.field, Styles.select)
				}
				.style(Styles.formRow, Styles.scriptingOnly)

				div {
					button(.id(Hooks.midiPlay), .type(.button)) {
						span {
							"▶"
						}
						.accessibilityHidden()
						" Play"
					}
					.style(Styles.retroButton)

					button(.id(Hooks.midiStop), .type(.button), .disabled) {
						span {
							"■"
						}
						.accessibilityHidden()
						" Stop"
					}
					.style(Styles.retroButton)
				}
				.style(Styles.row, Styles.scriptingOnly)

				p {
					"My web space only has room for 2 MB, so canyon.mid did not fit. Here is Edvard Grieg instead (he is from Norway, like me!), and a bit of Beethoven."
				}
				.style(Styles.caption)

				p {
					"The jukebox needs JavaScript."
				}
				.style(Styles.scriptingDisabledOnly)
			}
			.style(Styles.windowBody)
		}
		.style(Styles.window)
	}

	/**
	The facts about me, like the profile of a home page from 1999.
	*/
	var aboutMe: some HTML {
		dl {
			for fact in Self.aboutMeFacts {
				div {
					dt {
						"\(fact.label):"
					}
					.style(Styles.factLabel)

					dd {
						fact.value
					}
					.style(Styles.factValue)
				}
			}
		}
		.style(Styles.facts)
	}

	/**
	A pop-up ad, like the ones of free home page hosts, but inside the page, so it does not cover anything. The close button hides it, and the prize button leads to Glitter, the virtual unicorn. `geocities.js` runs both. Without scripts, the buttons are hidden, as they do nothing.
	*/
	var popUp: some HTML {
		div {
			div(.id(Hooks.popUp)) {
				div {
					h2 {
						"Congratulations!!!"
					}

					button(.id(Hooks.popUpClose), .type(.button)) {
						"×"
					}
					.accessibilityLabel("Close pop-up")
					.style(Styles.closeButton, Styles.scriptingOnly)
				}
				.style(Styles.titleBar, Styles.titleBarWithButton)

				div {
					p {
						gif(.newStarburst, alt: "New!")
						" You are the "
						strong {
							"1,000,000th"
						}
						" visitor to my home page! You have won a "
						strong {
							"FREE UNICORN"
						}
						"!"
					}

					button(.id(Hooks.popUpClaim), .type(.button)) {
						"Claim My Unicorn!"
					}
					.style(Styles.retroButton, Styles.scriptingOnly)

					p {
						"(This is not a real ad. It is the only pop-up on my page, I promise.)"
					}
					.style(Styles.caption)
				}
				.style(Styles.windowBody, Styles.centeredText)
			}
			.style(Styles.window, Styles.popUp)

			// `geocities.js` shows it instead of the pop-up when the visitor closes it, and focuses it.
			p(.id(Hooks.popUpClosed), .hidden, .tabindex(-1)) {
				"Pop-up closed. Phew!"
			}
			.style(Styles.centeredText)
		}
	}

	/**
	The countdown to the year 2000, which is always in the past, a check for the Y2K bug, and a midnight party, with a countdown from 10, fireworks, and the Y2K bug, which `geocities.js` runs. The number of days and the date with the Y2K bug, like the year 19126 that `getYear()` of old scripts showed, are from the build date, and `geocities.js` updates them to today.
	*/
	var y2k: some HTML {
		let year2000 = Calendar.site.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? .distantPast
		let days = Calendar.site.dateComponents([.day], from: Calendar.site.startOfDay(for: content.buildDate), to: year2000).day ?? 0
		let buildDate = Calendar.site.dateComponents([.year, .month, .day], from: content.buildDate)
		let month = content.buildDate.formatted(.site.month(.wide))

		return section {
			h2 {
				gif(.newYear)
				" Y2K\u{00A0}Countdown "
				gif(.newYear)
			}
			.style(Styles.heading, Styles.centeredText)

			div {
				p {
					"Only "
					strong(.id(Hooks.y2kDays)) {
						days.formatted(.number.locale(.site)).replacing("-", with: "−")
					}
					" days left until the year 2000!"
				}
				.style(Styles.countdown)

				p {
					"Is your computer ready? Mine says today is "
					strong(.id(Hooks.y2kToday)) {
						"\(month) \(buildDate.day ?? 1), 19\((buildDate.year ?? 2000) - 1900)"
					}
					". I think it already has the bug."
				}

				button(.id(Hooks.y2kCheck), .type(.button)) {
					"Check My Computer for the Y2K Bug"
				}
				.style(Styles.retroButton, Styles.scriptingOnly)

				p {
					"The check needs JavaScript. Which is not Y2K compliant either."
				}
				.style(Styles.scriptingDisabledOnly)

				p(.id(Hooks.y2kStatus), .role("status")) {
					"Ready."
				}
				.style(Styles.lcd)

				div {
					gif(.champagne, style: .partyGIF)

					button(.id(Hooks.partyStart), .type(.button)) {
						"Party Like It’s 1999! Count Down to 2000"
					}
					.style(Styles.retroButton, Styles.scriptingOnly)

					gif(.fireworks, style: .partyGIF)
				}
				.style(Styles.row)

				// The big numbers of the countdown, which the status also says, but only at the start and the end.
				p(.id(Hooks.partyCount), .hidden) {}
					.accessibilityHidden()
					.style(Styles.partyCount)

				p(.id(Hooks.partyStatus), .role("status")) {}
			}
			.style(Styles.alertBox)
		}
		.style(Styles.section)
	}

	/**
	Glitter, a virtual unicorn like a Tamagotchi, in an egg with a screen and buttons. `geocities.js` keeps her in the browser, so she remembers the visitor:
	- The visitor pets her by clicking her, which floats hearts up, and feeds, brushes, cleans up after, and plays with her. Play is the left or right game of the Tamagotchi: she turns five times, and the visitor guesses which way.
	- She does tricks, wears hats, sleeps with the light off and at night, dances while the jukebox plays, and talks in a speech bubble.
	- She gets hungry, bored, and messy over time, and grows up with the care she gets, from Baby to Rainbow Legend. She never dies, as unicorns do not.

	Without scripts, the buttons are hidden.
	*/
	var pet: some HTML {
		section(.id("geocities-glitter")) {
			h2 {
				gif(.heart)
				" Adopt Glitter, My Virtual Unicorn! "
				gif(.heart)
			}
			.style(Styles.heading, Styles.centeredText)

			p {
				"She lives in your browser. Pet her, feed her, play with her, and watch her grow up! Unicorns cannot die, but they do get grumpy."
			}
			.style(Styles.centeredText)

			div {
				div(.id(Hooks.petScreen)) {
					p(.id(Hooks.petStats)) {
						"Baby Glitter ★ Age: 0 days"
					}
					.style(Styles.petStats)

					div {
						p(.id(Hooks.petBubble)) {
							"Neigh!"
						}
						.accessibilityHidden()
						.style(Styles.petBubble)

						// Disabled until `geocities.js` runs, as petting needs it.
						button(.id(Hooks.petSprite), .type(.button), .disabled) {
							gif(.unicorn, alt: "", style: .petSprite)

							span(.id(Hooks.petHat)) {}
								.accessibilityHidden()
								.style(Styles.petHat)
						}
						.accessibilityLabel("Pet Glitter")
						.style(Styles.petSpriteButton)

						span(.id(Hooks.petZzz), .hidden) {
							"Z z z"
						}
						.accessibilityHidden()
						.style(Styles.petZzz)

						p(.id(Hooks.petMess), .role("img"), .hidden) {}
							.style(Styles.petMess)
					}
					.style(Styles.petScene)

					p(.id(Hooks.petFace)) {
						"(-_-)"
					}
					.accessibilityHidden()

					dl {
						div {
							dt {
								"Food:"
							}
							.style(Styles.factLabel)

							dd {
								span(.id(Hooks.petFood), .role("img")) {
									"♥♥♡♡"
								}
								.accessibilityLabel("2 of 4 hearts")
							}
							.style(Styles.factValue)
						}

						div {
							dt {
								"Fun:"
							}
							.style(Styles.factLabel)

							dd {
								span(.id(Hooks.petFun), .role("img")) {
									"♥♥♡♡"
								}
								.accessibilityLabel("2 of 4 hearts")
							}
							.style(Styles.factValue)
						}
					}
					.style(Styles.petMeters)
				}
				.style(Styles.petScreen)

				div(.id(Hooks.petGame), .hidden) {
					p(.id(Hooks.petGameStatus), .role("status")) {
						"Which way will Glitter turn?"
					}

					div {
						button(.type(.button), .hook(Hooks.petGuess, value: "left")) {
							"◀ Left"
						}
						.style(Styles.petButton)

						button(.type(.button), .hook(Hooks.petGuess, value: "right")) {
							"Right ▶"
						}
						.style(Styles.petButton)
					}
					.style(Styles.buttonRow)
				}
				.style(Styles.petGame)

				div(.id(Hooks.petButtons)) {
					for (action, title) in [("feed", "Feed"), ("play", "Play"), ("brush", "Brush"), ("clean", "Clean"), ("trick", "Trick"), ("hat", "Hat"), ("light", "Light")] {
						button(.type(.button), .hook(Hooks.petAction, value: action)) {
							title
						}
						.style(Styles.petButton)
					}
				}
				.style(Styles.buttonRow, Styles.scriptingOnly)
			}
			.style(Styles.egg)

			p(.id(Hooks.petStatus), .role("status"), .tabindex(-1)) {}
				.style(Styles.centeredText)

			p {
				"Glitter needs JavaScript to eat."
			}
			.style(Styles.scriptingDisabledOnly, Styles.centeredText)

			// `geocities.js` adds a copy that floats up from Glitter when the visitor pets her.
			template(.id(Hooks.petHeartTemplate)) {
				span {
					"♥"
				}
				.accessibilityHidden()
				.style(Styles.petHeart)
			}
		}
		.style(Styles.section)
	}

	/**
	The favorite links of a home page from 1999. Most of those pages are gone, so most links go to Wikipedia.
	*/
	var topLinks: some HTML {
		section {
			h2 {
				"My Top 10 Links on the Information Superhighway"
			}
			.style(Styles.heading)

			ol {
				for link in Self.topLinks {
					li {
						a(.href(.url(link.url))) {
							link.title
						}
						" "
						span {
							"(\(link.note))"
						}
						.style(Styles.caption)
					}
				}
			}
			.style(Styles.topLinks)

			p {
				"Updated weekly! (Not really.) Most of these pages are gone now, so the links go to an encyclopedia from the future."
			}
			.style(Styles.caption)
		}
		.style(Styles.section)
	}

	/**
	A butler who answers questions, like Ask Jeeves. `geocities.js` picks an answer by the words of the question.
	*/
	var butler: some HTML {
		section {
			h2 {
				gif(.question)
				" Ask Sindre’s Butler"
			}
			.style(Styles.heading)

			p {
				"He knows almost everything. Ask him a question!"
			}

			form(.id(Hooks.butlerForm)) {
				label(.for(Hooks.butlerQuestion.rawValue)) {
					"Your question:"
				}
				.style(Styles.label)

				input(.id(Hooks.butlerQuestion), .type(.text), .autocomplete("off"), .required, .maxlength(100), .placeholder("Are unicorns real?"))
					.style(Styles.field)

				button(.type(.submit)) {
					"Ask!"
				}
				.style(Styles.retroButton)
			}
			.style(Styles.form, Styles.scriptingOnly)

			p(.id(Hooks.butlerAnswer), .role("status")) {
				"Good day! How may I help you surf the web?"
			}
			.style(Styles.speech)

			p {
				"The butler needs JavaScript to think."
			}
			.style(Styles.scriptingDisabledOnly)
		}
		.style(Styles.section)
	}

	/**
	A fun fact, and a button for another one. `geocities.js` picks one of ``funFacts``.
	*/
	var funFact: some HTML {
		section {
			h2 {
				gif(.lightbulb)
				" Fun Fact!"
			}
			.style(Styles.heading)

			p(.id(Hooks.fact), .role("status")) {
				Self.funFacts[0]
			}
			.style(Styles.speech)

			button(.id(Hooks.nextFact), .type(.button)) {
				"Another Fun Fact!"
			}
			.style(Styles.retroButton, Styles.scriptingOnly)
		}
		.style(Styles.section)
	}

	/**
	A poll about browsers with made-up results. `geocities.js` adds the vote of the visitor and shows the results with bars of text, and remembers the vote in the browser.
	*/
	var poll: some HTML {
		section {
			h2 {
				"Poll: What Is Your Favorite Browser?"
			}
			.style(Styles.heading)

			form(.id(Hooks.pollForm)) {
				fieldset {
					legend {
						"Pick one:"
					}
					.style(VisuallyHidden.Styles.root)

					for (index, option) in Self.pollOptions.enumerated() {
						div {
							input(.id("geocities-poll-\(index)"), .type(.radio), .name("browser"), .value(option.name), .required, .hook(Hooks.votes, value: "\(option.votes)"))

							label(.for("geocities-poll-\(index)")) {
								option.name
							}
						}
						.style(Styles.choice)
					}
				}
				.style(Styles.choices)

				div {
					gif(.voteHere, alt: "Vote here!")

					button(.type(.submit)) {
						"Vote!"
					}
					.style(Styles.retroButton)
				}
				.style(Styles.formRow)
			}
			.style(Styles.form, Styles.scriptingOnly)

			p(.id(Hooks.pollStatus), .role("status"), .tabindex(-1)) {}

			ol(.id(Hooks.pollResults), .hidden) {}
				.style(Styles.pollResults)

			p {
				"The poll needs JavaScript."
			}
			.style(Styles.scriptingDisabledOnly)
		}
		.style(Styles.section)
	}

	/**
	The awards of the page, like the trophy rooms of old home pages, which mostly gave awards to themselves.
	*/
	var awards: some HTML {
		section {
			h2 {
				gif(.trophy)
				" My Awards "
				gif(.trophy)
			}
			.style(Styles.heading, Styles.centeredText)

			ul {
				for award in Self.awards {
					li {
						span {
							"★"
						}
						.accessibilityHidden()
						.style(Styles.medal)

						strong {
							award.title
						}

						span {
							award.note
						}
						.style(Styles.caption)
					}
					.style(Styles.award)
				}
			}
			.style(Styles.awards)
		}
		.style(Styles.section)
	}

	/**
	The guestbook, with entries from 1999, a visitor counter, and a form that adds an entry. The entries of the visitor stay in the browser, as the page has no server. `geocities.js` adds them, and counts the visits of the visitor on the counter.
	*/
	var guestbook: some HTML {
		section(.id("geocities-guestbook")) {
			h2 {
				"Guestbook"
			}
			.style(Styles.heading, Styles.centeredText)

			p {
				"You are visitor number "
				span(.id(Hooks.counter), .role("img")) {
					for digit in "001999" {
						span {
							String(digit)
						}
						.style(Styles.counterDigit)
					}
				}
				.accessibilityLabel("1999")
				.style(Styles.counter)
				"! I counted most of them myself, to make sure the counter works."
			}
			.style(Styles.centeredText)

			p {
				gif(.signGuestbook, alt: "Sign my guestbook!")
			}
			.style(Styles.centeredText)

			guestbookForm

			p {
				"Signing my guestbook needs JavaScript. You can still read it!"
			}
			.style(Styles.scriptingDisabledOnly)

			guestbookHelper

			p(.id(Hooks.guestbookStatus), .role("status")) {}

			ol(.id(Hooks.guestbookEntries)) {
				for entry in Self.guestbookEntries {
					entry
				}
			}
			.accessibilityLabel("Guestbook entries")
			.style(Styles.entries)

			// `geocities.js` fills a copy for each entry of the visitor.
			template(.id(Hooks.entryTemplate)) {
				GuestbookEntry(name: "", place: "", date: "", via: "", message: "")
			}

			p {
				gif(.mailbox)
				" Want to send me a real message? Use my "
				a(.href(.feedback)) {
					"feedback form"
				}
				", or "
				a(.href(.reviews)) {
					"read what others wrote about my apps"
				}
				"!"
			}

			p {
				gif(.emailSpin)
				a(.href(.contact)) {
					gif(.mailMe, alt: "Mail me!")
				}
			}
			.style(Styles.centeredText)
		}
		.style(Styles.section)
	}

	/**
	The form that adds an entry to the guestbook, in the browser. `geocities.js` runs it.
	*/
	var guestbookForm: some HTML {
		form(.id(Hooks.guestbookForm)) {
			div {
				label(.for("geocities-name")) {
					"Your name:"
				}
				.style(Styles.label)

				input(.id("geocities-name"), .type(.text), .name("name"), .autocomplete("off"), .required, .maxlength(40))
					.style(Styles.field)
			}

			div {
				label(.for("geocities-place")) {
					"Where are you from?"
				}
				.style(Styles.label)

				input(.id("geocities-place"), .type(.text), .name("place"), .autocomplete("off"), .maxlength(40))
					.style(Styles.field)
			}

			div {
				label(.for("geocities-via")) {
					"How did you find my page?"
				}
				.style(Styles.label)

				select(.id("geocities-via"), .name("via")) {
					for place in ["Yahoo!", "AltaVista", "Ask Jeeves", "A webring", "My mom told me", "I got lost"] {
						option(.value(place)) {
							place
						}
					}
				}
				.style(Styles.field, Styles.select)
			}

			div {
				label(.for("geocities-message")) {
					"Comments:"
				}
				.style(Styles.label)

				textarea(.id("geocities-message"), .name("message"), .rows(3), .required, .maxlength(300)) {}
					.style(Styles.field)
			}

			div {
				button(.type(.submit)) {
					"Sign It!"
				}
				.style(Styles.retroButton)

				button(.type(.reset)) {
					"Clear"
				}
				.style(Styles.retroButton)
			}
			.style(Styles.row)

			p {
				"Your entry stays in your browser, so only you can see it. My web space has no room for a server."
			}
			.style(Styles.caption)
		}
		.style(Styles.window, Styles.windowBody, Styles.scriptingOnly)
	}

	/**
	A unicorn in ASCII art, with a hint about the Konami code.
	*/
	var asciiArt: some HTML {
		section {
			h2 {
				"ASCII Art Corner"
			}
			.style(Styles.heading)

			pre(.role("img")) {
				Self.asciiUnicorn
			}
			.accessibilityLabel("A unicorn, drawn with letters and symbols")
			.style(Styles.ascii)

			p {
				"Psst! Secret code: ↑ ↑ ↓ ↓ ← → ← → B A. On a phone? Tap the visitor counter 7 times."
			}
			.style(Styles.caption)
		}
		.style(Styles.section)
	}

	/**
	The code for a link to this page with its 88×31 button, for the home pages of others, like the link exchanges of 1999.
	*/
	var linkToMe: some HTML {
		let code = #"<a href="\#(Site.url.absoluteString)\#(RoutePath.geoCities)"><img src="\#(Site.url.absoluteString)\#(GIF.buttonSindre.path)" width="88" height="31" alt="Sindre’s Home Page"></a>"#

		return section {
			h2 {
				"Link to Me!"
			}
			.style(Styles.heading)

			p {
				"Put my button on your home page, and I will put yours on mine! Copy this HTML:"
			}

			p {
				gif(.buttonSindre, alt: "Sindre’s Home Page")
			}

			label(.for("geocities-link-code")) {
				"HTML code for my button"
			}
			.style(VisuallyHidden.Styles.root)

			textarea(.id("geocities-link-code"), .rows(4), .readonly) {
				code
			}
			.style(Styles.field, Styles.code)

			CopyButton(title: "Copy Code", text: code, look: .retro)
		}
		.style(Styles.section)
	}

	/**
	The under construction sign, with workers, and a construction site below it.
	*/
	var construction: some HTML {
		div {
			div {
				gif(.constructionWorker, alt: "A construction worker with a sign and a shovel")

				div {
					p {
						gif(.underConstructionSign)
						" Under Construction "
						gif(.underConstructionSign)
					}
					.style(Styles.constructionTitle)

					p {
						"This page will never be finished, like all good home pages."
					}

					gif(.comingSoon, alt: "Coming soon!")
				}
				.style(Styles.constructionText)

				gif(.constructionJackhammer, alt: "A construction worker with a jackhammer")
			}
			.style(Styles.construction)

			div {
				gif(.underConstructionCone, alt: "A traffic cone")
				gif(.constructionBarrier, alt: "A barrier with blinking lights")
				gif(.underConstructionDigger, alt: "A construction worker playing with a toy digger")
				gif(.underConstructionStripes, alt: "Under construction")
				gif(.underConstructionCrane, alt: "A crane")
				gif(.underConstructionBulldozer, alt: "A bulldozer")
				gif(.underConstructionStill, alt: "This page is still under construction")
			}
			.style(Styles.row)
		}
		.style(Styles.section)
	}

	/**
	The webring of the apps: two apps that change daily, a random app, and the list.
	*/
	var webring: some HTML {
		let neighbors = content.randomApps(count: 2)

		return div {
			p {
				gif(.spinningCD)
				" This site is a proud member of the "
				strong {
					"Sindre Sorhus App Ring"
				}
				" "
				gif(.spinningCD)
			}

			p {
				if let previous = neighbors.first {
					a(.href(previous.url)) {
						"« \(previous.title)"
					}
					" | "
				}

				a(.href(.randomApp)) {
					"Random"
				}
				" | "
				a(.href(.apps)) {
					"List All"
				}

				if neighbors.count > 1 {
					" | "
					a(.href(neighbors[1].url)) {
						"\(neighbors[1].title) »"
					}
				}
			}

			p {
				gif(.geoCitiesBanner, alt: "GeoCities: Your home on the web")
			}
		}
		.style(Styles.webring)
	}

	/**
	Zap the Aliens: aliens appear in the holes for 30 seconds, the last 30 seconds of 1999, and each one the visitor zaps before it leaves is a point. Now and then Glitter peeks out instead, and zapping her costs 3 points, and a click on an empty hole costs one, so clicking everything does not win. `geocities.js` runs it. The holes are buttons, so a mouse, a finger, and the keyboard play it, and the number keys 1 to 9 zap the holes while the focus is in the game, like the keys of a phone. The score is a status, so screen readers announce it politely. Limitation: Screen readers do not announce where an alien appears, as the game is about seeing it.
	*/
	var game: some HTML {
		section(.id("geocities-games")) {
			h2 {
				gif(.ufo)
				" Zap\u{00A0}the\u{00A0}Aliens! "
				gif(.newStarburst, alt: "New!")
			}
			.style(Styles.heading, Styles.centeredText)

			p {
				"Aliens from Area 51 have landed on my home page! Zap as many as you can before the year 2000. Click or tap them, or press the number keys 1 to 9. A miss costs a point, and do NOT zap Glitter (🦄), or you lose 3!"
			}

			div(.id(Hooks.game)) {
				div {
					button(.id(Hooks.start), .type(.button)) {
						"Start"
					}
					.style(Styles.retroButton)

					p {
						gif(.hourglass)
						" "
						span(.id(Hooks.clock)) {
							"11:59:30 PM"
						}
					}
					.style(Styles.clock)
				}
				.style(Styles.gameBar)

				p(.id(Hooks.score), .role("status")) {
					"Press Start to play."
				}
				.style(Styles.score)

				div {
					for index in 1...Self.holeCount {
						button(.type(.button), .hook(Hooks.hole, value: "\(index)"), .disabled) {
							gif(.alien, style: .alien)
						}
						.accessibilityLabel("Hole \(index)")
						.style(Styles.hole)
					}
				}
				.style(Styles.holes)
			}
			.style(Styles.game, Styles.scriptingOnly)

			p {
				"The game needs JavaScript, like all cool things in 1999."
			}
			.style(Styles.scriptingDisabledOnly)
		}
		.style(Styles.section)
	}
}
