import Elementary
import Foundation
import SiteKit

/**
Appdle, a daily game: guess the app from a pixelated part of its icon. Each wrong guess shows more of the icon, sharper.

The build only lists the puzzles. `appdle.js` picks the puzzle of the day from the local date of the visitor, so it changes at midnight without a new build, and everybody gets the same app on the same day. The puzzles are in a shuffled order, so a new app in the list changes the order, and the puzzle of that day can change once.
*/
struct AppdlePage: Page {
	let content: SiteContent

	/**
	The day of the first puzzle, 2026-10-07, as days since 1970, like the daily seed. The script numbers the puzzles from it.
	*/
	static let firstDay = 20_733

	static let maximumGuesses = 6

	/**
	The ID of the list of app names that the guess input suggests.
	*/
	private static let namesID = "appdle-names"

	var path: RoutePath {
		.appdle
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Appdle: Guess the App", description: "A daily game: guess the app by Sindre Sorhus from a pixelated part of its icon. A new app every day.")
	}

	/**
	The listed apps with a page here and an icon, in a shuffled order that is the same for each build. The puzzle of a day is the one at the day number modulo the count.
	*/
	var puzzles: [Puzzle] {
		var generator = SeededRandomNumberGenerator(seed: "appdle".stableHash)

		return content.activeAppsWithPages
			.filter { !$0.hasPlaceholderIcon }
			.shuffled(using: &generator)
			.map(Puzzle.init)
	}

	var body: some HTML {
		let puzzles = puzzles

		section {
			// Centered, like the game below it.
			PageHeader(title: "Appdle", intro: "Guess the app from a pixelated part of its icon. Each wrong guess shows more of it. A new app every day.", isCentered: true)

			div(.id(Hooks.game)) {
				p {
					"Puzzle "
					span(.id(Hooks.number)) {}
				}
				.style(Styles.meta)

				// `appdle.js` draws the part of the icon, and the whole icon when the game ends, with the `revealed` state.
				canvas(.custom(name: "width", value: "480"), .custom(name: "height", value: "480"), .role("img")) {}
					.accessibilityLabel("A pixelated part of the icon of today’s app")
					.style(Styles.canvas)

				// One slot for each guess, which `appdle.js` marks as `correct` or `wrong`, like the squares of the shared result.
				div {
					for _ in 0..<Self.maximumGuesses {
						span {}
							.style(Styles.slot)
					}
				}
				.accessibilityHidden()
				.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))

				// How many guesses are left, or why a guess did not count. When the game ends, it is the headline of the result, like “You got it in 2 guesses!”.
				p(.id(Hooks.status), .role("status")) {}
					.style(Styles.status)

				form {
					label(.for("appdle-guess")) {
						"App name"
					}
					.style(VisuallyHidden.Styles.root)

					input(.id("appdle-guess"), .type(.text), .name("guess"), .custom(name: "list", value: Self.namesID), .autocomplete("off"), .custom(name: "enterkeyhint", value: "send"), .placeholder("Type an app name"))
						.style(Styles.input)

					button(.type(.submit)) {
						"Guess"
					}
					.buttonStyle()
				}
				.style(Styles.form)

				// Replaces the form when the game ends. `appdle.js` focuses it, so it can have focus, but not from the keyboard.
				div(.id(Hooks.result), .hidden, .tabindex(-1)) {
					// `appdle.js` sets the start, like “The app is ”, and the link to the app.
					p {
						span {}
						a {}
						"."
					}
					.style(Styles.answer)

					div {
						// `appdle.js` sets the result to copy.
						CopyButton(title: "Copy Result", text: "")
							.attributes(.id(Hooks.copyResult))

						// Clears the guesses of today, to play the puzzle again.
						button(.id(Hooks.restart), .type(.button)) {
							"Start Over"
						}
						.buttonStyle(.secondary, size: .small)
					}
					.style(Styles.resultButtons)

					p {
						"A new app tomorrow."
					}
					.style(Styles.meta)
				}
				.style(Styles.result)

				ol {}
					.accessibilityLabel("Guesses")
					.style(Styles.attempts)
			}
			.style(Styles.game)

			datalist(.id(Self.namesID)) {
				for title in puzzles.map(\.title).sorted(using: .localizedStandard) {
					option(.value(title)) {}
				}
			}

			p {
				"Appdle needs JavaScript. You can still "
				a(.href(.apps)) {
					"browse all the apps"
				}
				"."
			}
			.style(Styles.scriptingDisabledOnly)
		}
		.style(Styles.root)

		JSONScript(id: Hooks.data, ScriptData(firstDay: Self.firstDay, maximumGuesses: Self.maximumGuesses, puzzles: puzzles))
		ModuleScript("/scripts/appdle.js")
	}
}

extension AppdlePage {
	/**
	An app to guess.
	*/
	struct Puzzle: Encodable {
		let title: String
		let url: String
		let icon: String

		init(app: App) {
			self.title = app.title
			self.url = app.url.description
			self.icon = app.iconPath.description
		}
	}

	private struct ScriptData: Encodable {
		let firstDay: Int
		let maximumGuesses: Int
		let puzzles: [Puzzle]
	}
}

extension AppdlePage {
	/**
	The IDs and data attributes that the scripts of the page find elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case game = "appdle"
		case data = "appdle-data"
		case number = "appdle-number"
		case copyResult = "appdle-copy-result"
		case restart = "appdle-restart"
		case result = "appdle-result"
		case status = "appdle-status"
	}

	enum Styles: StyleSet {
		case root
		case game
		case meta
		case canvas
		case slot
		case form
		case input
		case status
		case attempts
		case result
		case answer
		case resultButtons
		case scriptingDisabledOnly

		var style: Style {
			switch self {
			case .root:
				Style()
					.pageColumn()
			case .game:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(1.25))
					.frame(maxWidth: .rootEm(26))
					.margin(.horizontal, .auto)
					.media(.scriptingDisabled) {
						$0.hidden()
					}
			case .meta:
				Style()
					.secondaryText()
					.monospacedDigit()
			case .canvas:
				// The part of the icon is a tile with the corners of an app icon. The whole icon has its own shape, with space around it, so it has no corners or shadow. Both are the same size, so the page does not move when the game ends.
				Style()
					.display(.block)
					.frame(width: .percent(100), maxWidth: .rootEm(15))
					.aspectRatio(1)
					.cornerRadius(.percent(22.5))
					.shadow(.window)
					.when(.state, is: "revealed") {
						$0
							.cornerRadius(0)
							.shadow([])
					}
			case .slot:
				// A neutral gray for the guesses left, a little stronger than a card, so they show on a white page.
				Style()
					.frame(width: .rootEm(1.75), height: .rootEm(0.5))
					.cornerRadius(.capsule)
					.background(.gray(200), dark: .gray(800))
					.when(.state, is: "wrong") {
						$0.background(.red(500))
					}
					.when(.state, is: "correct") {
						$0.background(.emerald(400))
					}
			case .form:
				// The button is as high as the field, as the items of a flex row stretch.
				Style()
					.hstack(spacing: .rootEm(0.5))
					.frame(width: .percent(100))
			case .input:
				// A form field, but round like the button next to it, so the two look like one set, like a search field. Without the arrow that Chrome shows for the list of names on focus, as the list opens while typing. Chrome shows the arrow with `!important`.
				FormFieldStyles.control.style
					.flex(1)
					.frame(minWidth: 0)
					.cornerRadius(.capsule)
					.padding(.horizontal, .rootEm(1.125))
					.nested("&::-webkit-calendar-picker-indicator") {
						$0.declaration(.display, .important(.none))
					}
			case .status:
				// The height of one line while it is empty, so the form below does not move when a message shows. When the game ends, it is the headline of the result.
				Style()
					.frame(minHeight: .lineHeight(1))
					.textAlign(.center)
					.textWrap(.balance)
					.color(.bodyText)
					.when(.state, is: "done") {
						$0
							.font(.extraLarge2, weight: .bold)
							.letterSpacing(.em(-0.02))
							.color(.primaryText)
					}
			case .attempts:
				// The guesses as quiet chips, like the categories on the apps page, but without a hover, as they are not links. The right guess is green, like its slot.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
					.children("li") {
						$0
							.padding(vertical: .rootEm(0.375), horizontal: .rootEm(0.875))
							.cornerRadius(.capsule)
							.textStyle(.caption, weight: .medium)
							.textWrap(.nowrap)
							.color(.bodyText)
							.background(.card)
							.when(.state, is: "correct") {
								$0
									.color(.emerald(700), dark: .emerald(400))
									.background(.emerald(50), dark: .emerald(950))
							}
					}
			case .result:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(1))
					.textAlign(.center)
			case .answer:
				Style()
					.textStyle(.lead)
					.color(.bodyText)
					.children("a") {
						$0.textLink()
					}
			case .resultButtons:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .scriptingDisabledOnly:
				Style().shownOnlyWithoutScripting()
			}
		}
	}
}
