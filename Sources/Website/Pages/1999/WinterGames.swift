import Elementary
import Foundation
import SiteKit

/**
Sindre’s Winter Games ’99, a game of winter sports in many events, like Winter Games by Epyx (1985), Track & Field by Konami (1983), and Nagano Winter Olympics ’98, with the sports of Norway after the Olympics of Lillehammer in 1994. The visitor signs up with a name, initials, a country with a pixel flag, and a mascot, carries the torch in the opening ceremony, and competes in eight events against five rivals: the ski jump of Holmenkollen, biathlon, speed skating against a ghost, slalom, bobsleigh, curling, an ice hockey shootout, and figure skating to Grieg. Each event has a screen of how to play, the weather of the day, a commentator who talks in Norwegian and English, a scoreboard, a podium with the anthem of the winner, an interview, and world records with three initials. A medal table counts the medals of all the countries, and a closing ceremony ends the Games. Its script, `WinterGames.js`, runs it on one canvas, only while it is on the screen and the tab is visible, and keeps the athlete, the records, the medals, the ghost, and the replay in the browser.
*/
struct GeoCitiesWinterGames: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the Games, which the site map links to.
	*/
	static let rootID = "geocities-winter"

	let project: Project

	/**
	An event of the Games, with the ID that `WinterGames.js` knows it by.
	*/
	struct Event {
		let id: String
		let title: String
		let venue: String

		/**
		How to play, in a few sentences.
		*/
		let howTo: String

		/**
		The keys and what they do, each with the touch button that does the same.
		*/
		let controls: [(keys: String, action: String)]

		/**
		An animated GIF next to how to play, if the event has one.
		*/
		var gif: GeoCitiesPage.GIF?

		/**
		How the GIF sits next to the text: floating where there is room, or centered above it for a wide one.
		*/
		var gifStyle: GeoCitiesPage.Styles = .floating
	}

	/**
	The events, in the order of the Games.
	*/
	static let events = [
		Event(
			id: "skijump",
			title: "Ski Jump",
			venue: "Holmenkollen, Oslo, K110",
			howTo: "Two jumps from the big hill in Oslo. Hold ▼ on the inrun to crouch and go faster. Press Jump right at the end of the table: too early or too late, and you fly short. In the air, keep the needle of the balance meter in the green with ▲ and ▼, as the wind pushes you around. When the ground comes close, press Jump again to land in a telemark, with one ski in front of the other. A jump to the K-point of 110 meters gives 60 points, and each meter more or less gives 1.8 points more or less. Five judges give up to 20 points each for the style, and the highest and the lowest marks do not count. A head wind lifts you, and a tail wind pushes you down.",
			controls: [("▼ (hold)", "Crouch on the inrun"), ("Space or the Jump button", "Take off, and land in a telemark"), ("▲ and ▼", "Lean forward and back in the air")]
		),
		Event(
			id: "biathlon",
			title: "Biathlon",
			venue: "Birkebeineren, Lillehammer",
			howTo: "Ski to the shooting range, shoot five targets, and ski to the finish. Press ◀ and ▶ one after the other to ski: the faster, the faster you go, but your heart rate goes up too. At the range, the higher your heart rate, the more the rifle sight shakes, so slow down before you get there, or wait a moment at the range. Move the sight with the arrow keys, and press Fire. The wind flag shows where the wind blows your bullets, so aim a little against it. Each miss sends you around the penalty loop, which is 150 meters in real biathlon and shorter here.",
			controls: [("◀ ▶ ◀ ▶", "Ski"), ("The arrow keys", "Move the sight at the range"), ("Space or the Fire button", "Shoot")]
		),
		Event(
			id: "skating",
			title: "Speed Skating 500 m",
			venue: "Vikingskipet, Hamar",
			howTo: "Race 500 meters against the ghost of the best race: the record at first, then your own best. Wait for the gun, and press Go when it fires. Two false starts, and you are out. Then skate with ◀ and ▶ in the rhythm of the stride meter: press ◀ when the marker swings to the left end, and ▶ when it swings to the right end. The faster you go, the faster it swings. In the curves, the ends are smaller, so be careful.",
			controls: [("Space or the Go button", "Start at the gun"), ("◀ and ▶", "Skate, in the rhythm of the stride meter")]
		),
		Event(
			id: "slalom",
			title: "Slalom",
			venue: "Hafjell, Øyer",
			howTo: "Ski down through 20 gates, red and blue, as fast as you can. Steer with ◀ and ▶. Hold ▼ to crouch, which is faster, but you turn slower. Hold ▲ to brake. Go between the two poles of each gate: a missed gate costs 5 seconds (in real slalom, you would be out). Fog and new snow make it harder, so check the weather.",
			controls: [("◀ and ▶", "Steer"), ("▼ (hold)", "Crouch for speed"), ("▲ (hold)", "Brake")]
		),
		Event(
			id: "bobsleigh",
			title: "Bobsleigh",
			venue: "Hunderfossen, Lillehammer",
			howTo: "Push the sled with ◀ ▶ ◀ ▶ as fast as you can, and press Jump In when the light is green, before the line. Then steer down the ice: in the curves, the sled climbs the wall, more the faster you go. Keep it on the green line with ◀ and ▶. Too low, and it scrapes and slows down; too high, and it tips over. The sign at the top tells which way the next curve goes. Cold ice is fast ice.",
			controls: [("◀ ▶ ◀ ▶", "Push at the start"), ("Space or the Jump In button", "Jump into the sled"), ("◀ and ▶", "Steer on the wall of the curves")]
		),
		Event(
			id: "curling",
			title: "Curling",
			venue: "Hamar Curling Hall",
			howTo: "Four stones, and red stones in the house. Aim with ◀ and ▶, and pick the turn of the stone with ▲ and ▼, which makes it curl to the left or the right as it slows down. Press Throw to start the weight meter, and press it again to let go: too hard, and the stone slides through the house. While the stone slides, press ◀ and ▶ one after the other to sweep: it goes further and straighter. Hurry hard! A stone on the button gives 4 points, in the next rings 3, 2, and 1. Each red stone you knock out of the house gives 2 points, and the stone closest to the middle gives 2 more.",
			controls: [("◀ and ▶", "Aim, and sweep while the stone slides"), ("▲ and ▼", "Turn the stone to curl left or right"), ("Space or the Throw button", "Start the weight meter, and let go")]
		),
		Event(
			id: "hockey",
			title: "Ice Hockey Shootout",
			venue: "Håkons Hall, Lillehammer",
			howTo: "Five shots, and five saves. When you shoot, the crosshair moves over the goal by itself: press Shoot when it is where the goalie is not. Press ◀ or ▶ first to fake a shot to that side, and the goalie moves there. When you are the goalie, watch the shooter: move with ◀ and ▶, hold ▲ for a high save with the glove, and hold ▼ to go down and cover the ice. Each goal and each save is a point.",
			controls: [("Space or the Shoot button", "Shoot"), ("◀ and ▶", "Fake a shot, or move the goalie"), ("▲ and ▼ (hold)", "High glove save, and down on the ice")],
			gif: .slapshot,
			gifStyle: .centered
		),
		Event(
			id: "figure",
			title: "Figure Skating",
			venue: "Nordlyshallen, Hamar",
			howTo: "Skate to In the Hall of the Mountain King by Edvard Grieg, which gets faster and faster. Arrows slide to the line on the left: press the arrow key when an arrow is on the line. A star is a jump: press Jump for it, or you fall on the ice. Five judges give two marks of up to 6.0 each, as in 1999: one for the technical merit, mostly the jumps, and one for the artistic impression, which likes long runs without a miss. With the sound on, you hear the music.",
			controls: [("◀ ▼ ▲ ▶", "Skate the steps of the arrows"), ("Space or the Jump button", "Jump at a star")],
			gif: .iceDancer
		),
	]

	/**
	A country of the Games, with the code that `WinterGames.js` knows it by and draws its flag for.
	*/
	static let countries: [(code: String, name: String)] = [
		("NOR", "Norway"),
		("SWE", "Sweden"),
		("FIN", "Finland"),
		("GER", "Germany"),
		("USA", "USA"),
		("CAN", "Canada"),
		("JPN", "Japan"),
		("GBR", "Great Britain"),
	]

	/**
	The mascots, by the name that `WinterGames.js` draws them by. Lillehammer had two children from the sagas, Håkon and Kristin. My Games have these.
	*/
	static let mascots: [(id: String, name: String)] = [
		("unicorn", "🦄 Glitter the Unicorn"),
		("troll", "👹 Tufsen the Troll"),
		("moose", "🫎 Elgar the Moose"),
		("lemming", "🐹 Lemmy the Lemming"),
	]

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id(Self.rootID)]
	}

	var content: some HTML {
		h2 {
			GeoCitiesPage.GIFImage(gif: .skiSlope, alt: "", style: .gif, project: project)
			" Sindre’s Winter Games ’99 "
			GeoCitiesPage.GIFImage(gif: .skiSlope, alt: "", style: .gif, project: project)
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"The Olympics in Lillehammer in 1994 were the best two weeks of my life, so I made my own Winter Games! Pick a country, carry the torch, and go for gold in eight events, from the ski jump of Holmenkollen to figure skating. Your world records stay on this computer forever (or until Mom clears the cache)."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			div {
				"WINTER99.EXE"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				console
				panels
			}
			.style(Styles.body)
		}
		.style(GeoCitiesPage.Styles.window, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The Winter Games need JavaScript, like all real computer games of 1999. Go outside and ski instead."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The screen, like a TV in a dark frame, with the line of the commentator below it, and the controls for touch screens.
	*/
	private var console: some HTML {
		div {
			div {
				// The screen is 320 × 200 pixels, like the VGA games of the 1990s, made bigger with sharp pixels.
				canvas(.part(Parts.screen), .width(320), .height(200), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The screen of the Winter Games. Use the arrow keys, and Space for the button of the event. Escape leaves an event.")
					.style(Styles.screen)
			}
			.style(Styles.bezel)

			p(.part(Parts.commentary), .role("status")) {
				"Velkommen! Welcome to the Winter Games. Sign up below to start."
			}
			.style(Styles.commentary)

			div {
				// The arrows, as four buttons around a plus sign. The keyboard uses the arrow keys on the screen instead, so the buttons are not in the order of the Tab key.
				div {
					for row in [[("up", "Up", "▲")], [("left", "Left", "◀"), ("right", "Right", "▶")], [("down", "Down", "▼")]] {
						div {
							for (control, label, symbol) in row {
								button(.type(.button), .tabindex(-1), .hook(Hooks.control, value: control)) {
									symbol
								}
								.accessibilityLabel(label)
								.style(Styles.padButton)
							}
						}
						.style(Styles.padRow)
					}
				}
				.style(Styles.pad)

				button(.type(.button), .tabindex(-1), .hook(Hooks.control, value: "action")) {
					"GO"
				}
				.style(Styles.actionButton)
			}
			.style(Styles.controls)

			div {
				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔇 Sound Off"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.quit), .type(.button), .hidden) {
					"Leave the Event"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.wear)) {
				"KEYBOARD WEAR: 0 MASHES. ALL KEYS OK."
			}
			.style(GeoCitiesPage.Styles.lcd, Styles.wear)
		}
		.style(Styles.console)
	}

	/**
	The parts below the screen, one at a time: signing up, the opening ceremony, the events, how to play, the results, the world records, and the medal table.
	*/
	private var panels: some HTML {
		div {
			register
			ceremony
			menu
			howTo
			playing
			results
			records
			medals
		}
		.style(Styles.panels)
	}

	private var register: some HTML {
		form(.part(Parts.register)) {
			h3 {
				"Sign Up for the Games"
			}
			.style(GeoCitiesPage.Styles.subheading)

			div {
				label(.for("geocities-winter-name")) {
					"Your name"
				}
				.style(Styles.fieldLabel)

				input(.id("geocities-winter-name"), .part(Parts.name), .type(.text), .autocomplete("off"), .maxlength(14), .value("Sindre"))
					.style(GeoCitiesPage.Styles.field)

				label(.for("geocities-winter-initials")) {
					"Initials for the records"
				}
				.style(Styles.fieldLabel)

				input(.id("geocities-winter-initials"), .part(Parts.initials), .type(.text), .autocomplete("off"), .maxlength(3), .value("SSO"))
					.style(GeoCitiesPage.Styles.field, Styles.initials)
			}
			.style(Styles.fields)

			fieldset {
				legend {
					"Your country"
				}
				.style(Styles.legend)

				for (index, country) in Self.countries.enumerated() {
					label {
						input(.type(.radio), .name(Hooks.country.rawValue), .value(country.code))
							.attributes(.checked, when: index == 0)
						canvas(.hook(Hooks.flag, value: country.code), .width(22), .height(16)) {}
							.accessibilityHidden()
							.style(Styles.flag)
						" \(country.name)"
					}
					.style(Styles.option)
				}
			}
			.style(Styles.choices)

			fieldset {
				legend {
					"Your mascot"
				}
				.style(Styles.legend)

				for (index, mascot) in Self.mascots.enumerated() {
					label {
						input(.type(.radio), .name(Hooks.mascot.rawValue), .value(mascot.id))
							.attributes(.checked, when: index == 0)
						" \(mascot.name)"
					}
					.style(Styles.option)
				}
			}
			.style(Styles.choices)

			div {
				button(.type(.submit)) {
					"🔥 Open the Games!"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.panel)
	}

	private var ceremony: some HTML {
		div(.part(Parts.ceremony), .hidden) {
			h3(.tabindex(-1)) {
				"The Opening Ceremony"
			}
			.style(GeoCitiesPage.Styles.subheading)

			p {
				"In Lillehammer, a ski jumper flew down the hill with the torch. In my Games, your mascot runs it up the stairs of the stadium. Press ◀ ▶ ◀ ▶ (or the buttons) as fast as you can, and then the button to light the flame!"
			}

			div {
				button(.part(Parts.skip), .type(.button)) {
					"Skip the Ceremony"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.panel)
	}

	private var menu: some HTML {
		div(.part(Parts.menu), .hidden) {
			h3(.tabindex(-1)) {
				"The Events"
			}
			.style(GeoCitiesPage.Styles.subheading)

			p(.part(Parts.athlete)) {}
				.style(GeoCitiesPage.Styles.caption)

			ol {
				for event in Self.events {
					li {
						button(.type(.button), .hook(Hooks.event, value: event.id)) {
							strong {
								event.title
							}

							span {
								event.venue
							}
							.style(Styles.venue)

							span(.hook(Hooks.medal, value: event.id)) {}
								.style(Styles.medal)
						}
						.style(Styles.eventButton)
					}
				}
			}
			.style(Styles.eventList)

			div {
				button(.part(Parts.all), .type(.button)) {
					"🏅 Compete in All Events"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			div {
				button(.part(Parts.showRecords), .type(.button)) {
					"World Records"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.showMedals), .type(.button)) {
					"Medal Table"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.newAthlete), .type(.button)) {
					"New Athlete"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.panel)
	}

	private var howTo: some HTML {
		div(.part(Parts.howTo), .hidden) {
			h3(.part(Parts.howToTitle), .tabindex(-1)) {}
				.style(GeoCitiesPage.Styles.subheading)

			for event in Self.events {
				div(.hook(Hooks.howToText, value: event.id), .hidden) {
					if let gif = event.gif {
						GeoCitiesPage.GIFImage(gif: gif, alt: "", style: event.gifStyle, project: project)
					}

					p {
						event.howTo
					}

					dl {
						for control in event.controls {
							dt {
								control.keys
							}
							.style(Styles.key)

							dd {
								control.action
							}
							.style(Styles.keyAction)
						}
					}
					.style(Styles.keys)
				}
			}

			p(.part(Parts.weather)) {}
				.style(GeoCitiesPage.Styles.lcd)

			div {
				button(.part(Parts.start), .type(.button)) {
					"Start!"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.type(.button), .part(Parts.back)) {
					"Back to the Events"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.panel)
	}

	private var playing: some HTML {
		div(.part(Parts.playing), .hidden) {
			p(.part(Parts.tip)) {}
				.style(Styles.tip)
		}
		.style(Styles.panel)
	}

	private var results: some HTML {
		div(.part(Parts.results), .hidden) {
			h3(.part(Parts.resultsTitle), .tabindex(-1)) {}
				.style(GeoCitiesPage.Styles.subheading)

			table {
				caption {
					"The results"
				}
				.style(VisuallyHidden.Styles.root)

				thead {
					tr {
						th {
							"#"
						}

						th {
							"Athlete"
						}

						th {
							"Result"
						}
					}
				}

				tbody(.part(Parts.resultsBody)) {}
			}
			.style(Styles.table)

			p(.part(Parts.resultsNote)) {}

			form(.part(Parts.recordForm), .hidden) {
				label(.for("geocities-winter-record-initials")) {
					"🏆 A new world record! Enter your initials: "
				}

				input(.id("geocities-winter-record-initials"), .part(Parts.recordInitials), .type(.text), .autocomplete("off"), .maxlength(3))
					.style(GeoCitiesPage.Styles.field, Styles.initials)

				button(.type(.submit)) {
					"Save"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(Styles.recordForm)

			div(.part(Parts.interview)) {
				p(.part(Parts.question)) {}
					.style(Styles.question)

				div {
					for index in 0..<3 {
						button(.type(.button), .hook(Hooks.answer, value: "\(index)")) {}
							.style(GeoCitiesPage.Styles.smallButton)
					}
				}
				.accessibilityLabel("Your answer")
				.attributes(.role("group"))
				.style(Styles.answers)

				p(.part(Parts.reply), .role("status")) {}
					.style(GeoCitiesPage.Styles.caption)
			}
			.style(Styles.interview)

			div {
				button(.part(Parts.next), .type(.button)) {
					"Next Event"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.anthem), .type(.button)) {
					"🔊 Play the Anthem"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.replay), .type(.button), .hidden) {
					"📼 Replay of My Best Jump"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.type(.button), .part(Parts.back)) {
					"Back to the Events"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.panel)
	}

	private var records: some HTML {
		div(.part(Parts.records), .hidden) {
			h3(.tabindex(-1)) {
				"World Records"
			}
			.style(GeoCitiesPage.Styles.subheading)

			p {
				"The best result of each event ever, on this computer. The first records are by my rivals. Beat them!"
			}
			.style(GeoCitiesPage.Styles.caption)

			table {
				caption {
					"World records"
				}
				.style(VisuallyHidden.Styles.root)

				thead {
					tr {
						th {
							"Event"
						}

						th {
							"Record"
						}

						th {
							"By"
						}
					}
				}

				tbody(.part(Parts.recordsBody)) {}
			}
			.style(Styles.table)

			div {
				button(.part(Parts.recordsReplay), .type(.button)) {
					"📼 Replay of My Best Jump"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.clear), .type(.button)) {
					"Clear My Records"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.type(.button), .part(Parts.back)) {
					"Back to the Events"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.panel)
	}

	private var medals: some HTML {
		div(.part(Parts.medals), .hidden) {
			h3(.tabindex(-1)) {
				"Medal Table"
			}
			.style(GeoCitiesPage.Styles.subheading)

			p(.part(Parts.medalsNote)) {}
				.style(GeoCitiesPage.Styles.caption)

			table {
				caption {
					"Medals by country"
				}
				.style(VisuallyHidden.Styles.root)

				thead {
					tr {
						th {
							"Country"
						}

						th {
							"🥇"
						}
						.accessibilityLabel("Gold")

						th {
							"🥈"
						}
						.accessibilityLabel("Silver")

						th {
							"🥉"
						}
						.accessibilityLabel("Bronze")

						th {
							"Total"
						}
					}
				}

				tbody(.part(Parts.medalsBody)) {}
			}
			.style(Styles.table)

			div {
				button(.part(Parts.closing), .type(.button)) {
					"🎆 Closing Ceremony"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.newGames), .type(.button)) {
					"New Games"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.type(.button), .part(Parts.back)) {
					"Back to the Events"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
		.style(Styles.panel)
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The control of a touch button, like `left` or `action`.
		*/
		case control = "data-winter-control"

		/**
		The name of the radio buttons of the country, which is also how the script finds them.
		*/
		case country = "geocities-winter-country"

		/**
		The name of the radio buttons of the mascot.
		*/
		case mascot = "geocities-winter-mascot"

		/**
		The country of a small canvas that shows its flag, like `NOR`.
		*/
		case flag = "data-winter-flag"

		/**
		The event of a button of the menu, like `skijump`.
		*/
		case event = "data-winter-event"

		/**
		The event whose best medal a part of a button of the menu shows.
		*/
		case medal = "data-winter-medal"

		/**
		The event that a text of how to play is for.
		*/
		case howToText = "data-winter-howto"

		/**
		The answer of a button of the interview, as its index.
		*/
		case answer = "data-winter-answer"
	}

	enum Parts: String, ElementPartSet {
		case screen
		case commentary
		case sound
		case quit
		case wear

		case register
		case name
		case initials

		case ceremony
		case skip

		case menu
		case athlete
		case all
		case showRecords
		case showMedals
		case newAthlete

		case howTo
		case howToTitle
		case weather
		case start

		/**
		The buttons that go back to the events.
		*/
		case back

		case playing
		case tip

		case results
		case resultsTitle
		case resultsBody
		case resultsNote
		case recordForm
		case recordInitials
		case interview
		case question
		case reply
		case next
		case anthem
		case replay

		case records
		case recordsBody
		case recordsReplay
		case clear

		case medals
		case medalsNote
		case medalsBody
		case closing
		case newGames
	}

	enum Styles: ElementStyleSet {
		case root
		case body
		case console
		case bezel
		case screen
		case commentary
		case controls
		case pad
		case padRow
		case padButton
		case actionButton
		case wear
		case panels
		case panel
		case fields
		case fieldLabel
		case initials
		case choices
		case legend
		case option
		case flag
		case eventList
		case eventButton
		case venue
		case medal
		case keys
		case key
		case keyAction
		case tip
		case table
		case recordForm
		case interview
		case question
		case answers

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .body:
				Style()
					.vstack(spacing: .rootEm(0.75))
					.padding(.rootEm(0.75))
					.below(.smallTablet) {
						$0.padding(.rootEm(0.375))
					}
			case .console:
				// A dark console, like a TV with a game console under it.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.below(.smallTablet) {
						$0.padding(.rootEm(0.375))
					}
					.background(Color("#2a2a3a"))
					.border(Color("#555566"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(0.5))
			case .bezel:
				Style()
					.frame(width: .percent(100), maxWidth: .pixels(660))
					.padding(.rootEm(0.5))
					.below(.smallTablet) {
						$0.padding(.rootEm(0.25))
					}
					.background(.black)
					.border(Color("#444444"), width: .pixels(3), style: .inset)
					.cornerRadius(.rootEm(0.75))
			case .screen:
				// While an event is on, a finger on the screen does not scroll the page, as the events are played with the buttons below it.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(320.0 / 200.0)
					.imageRendering(.pixelated)
					.background(.black)
					.touchAction(.manipulation)
					.focusVisible {
						$0.focusRing(Color("#ffee55"), width: .pixels(2), offset: .pixels(2))
					}
			case .commentary:
				// Two lines high, so the console does not grow when a line of the commentator is longer.
				Style()
					.frame(width: .percent(100), minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.lineHeight(1.2)
					.textAlign(.center)
					.color(Color("#ffee55"))
			case .controls:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(2))
					.textSelection(.disabled)
			case .pad:
				Style().vstack(alignment: .center, spacing: .rootEm(0.25))
			case .padRow:
				// Left and right have the width of a button between them.
				Style().hstack(alignment: .center, justification: .center, spacing: .rootEm(3))
			case .padButton:
				Style()
					.frame(width: .rootEm(3), height: .rootEm(3))
					.background(Color("#3a5a9a"))
					.border(Color("#7a9ada"), width: .pixels(3), style: .outset)
					.cornerRadius(.rootEm(0.5))
					.fontFamily(.system)
					.font(.large, weight: .bold)
					.color(.white)
					.touchAction(.none)
					.handCursor()
					.active {
						$0.border(Color("#7a9ada"), width: .pixels(3), style: .inset)
					}
			case .actionButton:
				// The big round button, which says what it does in the event, like JUMP.
				Style()
					.frame(width: .rootEm(5), height: .rootEm(5))
					.background(Color("#cc1a2a"))
					.border(Color("#ff7a7a"), width: .pixels(4), style: .outset)
					.cornerRadius(.percent(50))
					.fontFamily(GeoCitiesPage.impact)
					.textStyle(.body)
					.color(.white)
					.touchAction(.none)
					.handCursor()
					.active {
						$0.border(Color("#ff7a7a"), width: .pixels(4), style: .inset)
					}
			case .wear:
				Style()
					.frame(width: .percent(100))
					.margin(0)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .panels:
				Style().frame(width: .percent(100))
			case .panel:
				Style().flowSpacing(.rootEm(0.75))
			case .fields:
				// A label and its field on each row where there is room.
				Style()
					.grid(minimumColumnWidth: .rootEm(9))
					.gap(row: .rootEm(0.25), column: .rootEm(0.5))
					.alignItems(.center)
			case .fieldLabel:
				Style().fontWeight(.bold)
			case .initials:
				Style()
					.frame(width: .rootEm(4))
					.fontFamily(GeoCitiesPage.courier)
					.textCase(.uppercase)
			case .choices:
				Style()
					.grid(minimumColumnWidth: .rootEm(10))
					.gap(row: .rootEm(0.25), column: .rootEm(0.75))
					.margin(0)
					.padding(.rootEm(0.5))
					.border(Color("#808080"), width: .pixels(2), style: .groove)
			case .legend:
				Style()
					.padding(.horizontal, .rootEm(0.25))
					.fontWeight(.bold)
			case .option:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.handCursor()
			case .flag:
				Style()
					.frame(width: .pixels(22), height: .pixels(16))
					.imageRendering(.pixelated)
					.border(Color("#404040"), width: .pixels(1))
			case .eventList:
				Style()
					.grid(minimumColumnWidth: .rootEm(13))
					.gap(.rootEm(0.375))
					.margin(0)
					.padding(0)
					// Without the numbers of the list, as each button says what it is.
					.children("li") {
						$0.display(.block)
					}
			case .eventButton:
				Style()
					.vstack(alignment: .start, spacing: 0)
					.frame(width: .percent(100), height: .percent(100))
					.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.625))
					.background(Color("#ffffff"))
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption)
					.textAlign(.leading)
					.color(.black)
					.handCursor()
					.hover {
						$0.background(Color("#ffffcc"))
					}
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
			case .venue:
				Style().color(Color("#555555"))
			case .medal:
				Style().fontWeight(.bold)
			case .keys:
				Style()
					.grid(columns: "auto 1fr")
					.gap(row: .rootEm(0.25), column: .rootEm(0.75))
					.margin(0)
			case .key:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.fontWeight(.bold)
			case .keyAction:
				Style().margin(0)
			case .tip:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .table:
				Style()
					.frame(width: .percent(100))
					.background(Color("#ffffff"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.textStyle(.caption)
					.children("* > tr > *") {
						$0
							.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
							.border(.bottom, Color("#dddddd"), width: .pixels(1))
							.textAlign(.leading)
					}
					.children("thead > tr > th") {
						$0
							.background(Color("#000080"))
							.color(.white)
					}
			case .recordForm:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.flexWrap()
					.padding(.rootEm(0.5))
					.background(Color("#ffffcc"))
					.border(Color("#cc9900"), width: .pixels(2), style: .dashed)
					.fontWeight(.bold)
			case .interview:
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(.rootEm(0.5))
					.border(Color("#808080"), width: .pixels(2), style: .groove)
			case .question:
				Style()
					.margin(0)
					.fontWeight(.bold)
			case .answers:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			}
		}
	}
}
