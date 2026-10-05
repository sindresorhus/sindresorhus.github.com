import Elementary
import Foundation
import SiteKit

/**
WaffleClues, an extra of my adventure games: a hint book with invisible ink that shows when it is rubbed, like the InvisiClues of Infocom, with a chapter for each game. Rubbing a box with the pointer or a finger, or pressing it, makes the ink show in two steps, and Enter or Space shows it at once. Its script, `WaffleClues.js`, runs it.
*/
struct GeoCitiesWaffleClues: ScriptedElement {
	static let script = ElementScript()

	/**
	The questions of the hint book, by game, each with its hints from a nudge to the answer. Some questions are fakes, like in the real books, so a reader cannot guess the puzzles from the questions.
	*/
	static let clues: [(game: String, questions: [(question: String, hints: [String])])] = [
		("Sindre’s Quest for the Golden Waffle", [
			("How do I get out of my room?", ["Mamma says something about the weather. It is Bergen.", "Open the wardrobe.", "Pick up the rain jacket, then Use it in your inventory."]),
			("Where do I get money?", ["What rattles in your room?", "Pick up the piggy bank, then Open it in your inventory."]),
			("Where do I find brown cheese?", ["Talk to Mormor at Bryggen.", "Kevin collects something that comes in the mail every day.", "Give Kevin the AOL CD from the floor of your room."]),
			("The seagull stole my brown cheese!", ["It is a Bergen seagull. What do seagulls love, after brown cheese?", "Ask the fishmonger for something for the seagull.", "Give the fish head to the seagull."]),
			("The troll will not eat the brown cheese.", ["How many teeth does the troll have?", "Mormor has a tool for that.", "Use the cheese slicer with the brown cheese, and give the slices to the troll."]),
			("How do I kill the troll?", ["You don’t. He is nice once he has eaten.", "Shame on you."]),
		]),
		("WAFFLE QUEST", [
			("How do I get into the house?", ["Walk around it.", "The window behind the house is slightly ajar.", "OPEN WINDOW, then W."]),
			("It is dark, and something keeps eating me.", ["There is a light in the living room.", "TAKE LAMP, then TURN ON LAMP."]),
			("How do I get past the troll?", ["Trolls are always hungry.", "What is in the brown paper bag in the kitchen?", "GIVE SANDWICH TO TROLL."]),
			("How do I get through the maze?", ["Drop things to mark the rooms, like the adventurers of 1980 did.", "From the Troll Room: E, N, N, S."]),
			("How do I get the milk out of the ice?", ["You need something sharp. Not the spatula.", "There is a cheese slicer in the attic.", "CHIP ICE WITH SLICER."]),
			("What is the word that Mormor says?", ["Read the brass plaque in the living room.", "Close the iron with the three things in it, and SAY KOS."]),
			("What is the elvish spatula for?", ["Nothing. Every game has one thing that is for nothing.", "This space intentionally left blank."]),
		]),
		("Insult Seagull Fighting", [
			("How do I beat the Sea Gull Master?", ["Fight the ordinary seagulls first. When you insult them, they answer, and you learn their comebacks.", "The insults of the Master are new, but the comebacks are the same old ones. Think about what each insult means.", "“I will soak you like a week of Bergen rain!” Answer: “I’m from Bergen. I was born wet.”"]),
		]),
		("The Brunost Age", [
			("How do I open the cheese tower?", ["The door of the tower has three marks. Something else on the island has three of something.", "Turn on all three marker switches: on the dock, by the path, and in the forest."]),
			("Where are the pages?", ["One is red, and one is blue.", "The red page is in the forest. The blue page is in the cheese tower. Put them in the books in the library."]),
		]),
	]

	var content: some HTML {
		h2 {
			"WaffleClues"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Stuck? Kevin’s big brother had the InvisiClues books for Zork, where the answers were printed in invisible ink, and you rubbed them with a special marker to see them. So I made my own. Rub a box with the pointer or a finger (or press it) to make the ink show. The first box is only a nudge. Some questions are fake, so you can’t guess the puzzles."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			p {
				"WaffleClues™ • The hint book for all Sindresoft games • kr 99"
			}
			.style(Styles.bookCover)

			// Each game is a chapter that opens and closes, so the book is not as long as all its questions.
			for game in Self.clues {
				ClueChapter(title: game.game, questions: game.questions)
			}
		}
		.style(Styles.book)

		p(.part(Parts.status), .role("status")) {}
			.style(GeoCitiesPage.Styles.centeredText, Styles.cluesStatus)
	}

	/**
	A game in the hint book, as a chapter that opens and closes, with its questions and their boxes of invisible ink.
	*/
	struct ClueChapter: HTML {
		let title: String
		let questions: [(question: String, hints: [String])]

		var body: some HTML {
			details {
				summary {
					title
				}
				.style(Styles.bookGame)

				div {
					for question in questions {
						div {
							h4 {
								question.question
							}
							.style(Styles.bookQuestion)

							div {
								for (hintIndex, hint) in question.hints.enumerated() {
									button(.type(.button), .part(Parts.ink)) {
										hint
									}
									.accessibilityLabel("Invisible ink, hint \(hintIndex + 1) of \(question.hints.count). Press to reveal.")
									.style(Styles.ink)
								}
							}
							.style(Styles.inks)
						}
						.style(Styles.bookEntry)
					}
				}
				.style(Styles.bookChapter)
			}
		}
	}

	enum Parts: String, ElementPartSet {
		case status

		/**
		A box of invisible ink in the hint book.
		*/
		case ink
	}

	enum Styles: ElementStyleSet {
		case root
		case book
		case bookCover
		case bookGame
		case bookChapter
		case bookEntry
		case bookQuestion
		case inks
		case ink
		case cluesStatus

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .book:
				// The yellow paper of a hint book, in two columns on a wide screen.
				Style()
					.frame(maxWidth: .pixels(820))
					.margin(.horizontal, .auto)
					.padding(.rootEm(1))
					.background(Color("#fff4b8"))
					.border(Color("#8a6a1a"), width: .pixels(3), style: .double)
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000055")))
					.fontFamily(GeoCitiesPage.times)
					.color(Color("#222222"))
					.flowSpacing(.rootEm(0.75))
			case .bookCover:
				Style()
					.margin(0)
					.padding(.rootEm(0.5))
					.background(Color("#2a2a6a"))
					.fontFamily(GeoCitiesPage.impact)
					.textStyle(.body)
					.textAlign(.center)
					.letterSpacing(.em(0.05))
					.color(Color("#ffd700"))
			case .bookGame:
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: 0)
					.border(.bottom, Color("#8a6a1a"), width: .pixels(2))
					.font(.large, weight: .bold)
					.color(Color("#5a1a6a"))
					.handCursor()
			case .bookChapter:
				Style()
					.padding(.top, .rootEm(0.75))
					.flowSpacing(.rootEm(0.75))
			case .bookEntry:
				Style().vstack(spacing: .rootEm(0.375))
			case .bookQuestion:
				Style()
					.margin(0)
					.font(.regular, weight: .bold)
			case .inks:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.padding(.leading, .rootEm(1))
			case .ink:
				// A box of invisible ink, in the color of the paper until it is rubbed. Then the ink shows in green, the color of the InvisiClues marker. A finger that rubs sideways does not scroll the page, and one that moves up and down still does.
				Style()
					.frame(minHeight: .rootEm(2.25))
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(Color("#fff8d0"))
					.border(Color("#c8b060"), width: .pixels(1), style: .dashed)
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.body)
					.textAlign(.leading)
					.color(Color("#fff8d0"))
					.touchAction(.panY)
					.textSelection(.disabled)
					.handCursor()
					.transition(.colors, animation: .easeOut(duration: .milliseconds(300)))
					.when(.state, is: "faint") {
						$0
							.background(Color("#f2f0c8"))
							.color(Color("#b8d0a8"))
					}
					.when(.state, is: "shown") {
						$0
							.background(Color("#e8f0c0"))
							.color(Color("#1a5a2a"))
							.textSelection(.enabled)
					}
			case .cluesStatus:
				Style()
					.frame(minHeight: .lineHeight(1))
					.margin(0)
					.textStyle(.caption)
			}
		}
	}
}
