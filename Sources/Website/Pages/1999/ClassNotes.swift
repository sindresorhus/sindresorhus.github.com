import Elementary
import Foundation
import SiteKit

/**
Passing Notes in Class, in my classroom in 6B at school in Bergen in 1999, as a game of red light, green light. The visitor writes a note on lined paper from a school notebook, in handwriting, with the classic “Liker du meg? ☐ Ja ☐ Nei ☐ Kanskje” (“Do you like me? Yes, No, Maybe”) as a template, with doodle stamps (a heart, a smiley, a star, Glitter the unicorn, Rocky the pet rock, and Fru Hansen with horns) and freehand pencil doodles, and folds it into a paper football, a square with a pull tab, or a paper airplane, with a little animation of the folds. Then, in the classroom from above, the visitor passes it from desk to desk to Ingrid (my crush, two rows away) or Trond (my best friend), while the teacher writes on the blackboard, and freezes when she turns around. She gives tells before she turns: the chalk stops squeaking, and she clears her throat. A note that moves while she looks is caught. Each kid has a personality: the nice ones hold it, the snitches tell, Kevin opens it, reads it, and writes on it, the sleepers snort when they wake up, the gigglers giggle, and Stian throws it straight to the target like Solskjær, but not always well. A risk meter shows how suspicious the teacher is, and when it is full, she turns at once. When the note is caught, the teacher reads it out loud to the whole class, the text of the visitor, in a big speech bubble and with the voice of the computer once the sound is on, the class laughs, and Sindre goes red. When it arrives, the answer comes back with a box checked, sometimes sweet, sometimes “Nei”, and sometimes a doodle. The paper airplane goes over the whole class at once, but where it lands is up to the wind. There are four lessons: Norwegian and math with Fru Hansen, the substitute who reads the newspaper and never turns around, and the strict principal, who fakes his tells. The bell ends each lesson, and the notes are kept in a pencil case in the browser, to read again. Its script, `ClassNotes.js`, runs it, only while it is on the screen and the tab is visible. Nothing makes a sound until the visitor turns on the sound, and with reduced motion, the teacher turns at once, the notes fold at once, and nothing moves by itself. Without scripts, it is left out, as it has nothing to show.
*/
struct GeoCitiesClassNotes: ScriptedElement {
	static let script = ElementScript()

	/**
	The lessons of the day, by the name that the script knows them by, with their names.
	*/
	private static let lessons: [(id: String, name: String)] = [
		("norsk", "📖 Norsk"),
		("matte", "➗ Matte"),
		("vikar", "📰 Vikar"),
		("rektor", "👔 Rektor"),
	]

	/**
	The doodles that can go on the note, by the name that the script knows them by, with their names.
	*/
	private static let doodles: [(id: String, name: String)] = [
		("heart", "♥ Heart"),
		("smiley", "☺ Smiley"),
		("star", "★ Star"),
		("unicorn", "🦄 Glitter"),
		("rock", "🪨 Rocky"),
		("teacher", "😈 Fru Hansen"),
	]

	/**
	The ways to fold the note, by the name that the script knows them by, with their names.
	*/
	private static let folds: [(id: String, name: String)] = [
		("football", "🏈 Fold a Football"),
		("square", "✉️ Fold a Square with a Tab"),
		("airplane", "✈️ Fold an Airplane"),
	]

	var content: some HTML {
		h2 {
			"Passing Notes in Class"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"6B, the third lesson, and it is raining on the windows. Ingrid sits two rows in front of me, and I have to ask her something. Write a note, fold it, and pass it from desk to desk while the teacher writes on the blackboard. When she turns around, freeze! If she catches it, she reads it OUT LOUD to the whole class."
		}

		// In the order of play: write and fold the note, start the lesson, and pass the note in the classroom right below the Start button.
		div {
			Notebook()
			Toolbar()
			Classroom()
			PencilCase()
		}
		.style(Styles.game, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Passing notes needs JavaScript. Fru Hansen has her eye on you anyway."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The lessons to pick, the sound, and the button that starts the lesson.
	*/
	private struct Toolbar: HTML {
		var body: some HTML {
			div {
				div {
					for (index, lesson) in GeoCitiesClassNotes.lessons.enumerated() {
						button(.type(.button), .hook(Hooks.lesson, value: lesson.id), .ariaPressed(index == 0)) {
							lesson.name
						}
						.attributes(.hook(.state, value: "on"), when: index == 0)
						.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
					}
				}
				.accessibilityLabel("Lesson")
				.attributes(.role("group"))
				.style(Styles.row)

				div {
					button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
						"🔈 Sound"
					}
					.help("Plays sound, and the teacher reads caught notes out loud")
					.style(GeoCitiesPage.Styles.smallButton, Styles.toggle, Styles.bigTarget)

					button(.part(Parts.start), .type(.button)) {
						"🔔 Start the Lesson"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(Styles.row)
			}
			.style(Styles.toolbar)
		}
	}

	/**
	The page of the notebook where the note is written, with its doodles and folds.
	*/
	private struct Notebook: HTML {
		var body: some HTML {
			div {
				canvas(.part(Parts.paper), .width(320), .height(240), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The note, on a page torn out of my school notebook. Drag on it, or press the arrow keys, to doodle with the pencil. The text, the doodles, and the folds are next to it.")
					.style(Styles.paper)

				div {
					NoteFields()
					Doodles()
					Folds()
				}
				.style(Styles.controls)
			}
			.style(Styles.notebook)
		}
	}

	/**
	The text of the note, who it is for, and the classic boxes.
	*/
	private struct NoteFields: HTML {
		var body: some HTML {
			div {
				label(.for("geocities-class-notes-to")) {
					"To:"
				}
				.style(Styles.inlineLabel)

				select(.id("geocities-class-notes-to"), .part(Parts.recipient)) {
					option(.value("ingrid")) {
						"Ingrid ♥ (my crush)"
					}

					option(.value("trond")) {
						"Trond (my best friend)"
					}
				}
				.style(Styles.select)
			}
			.style(Styles.row)

			label(.for("geocities-class-notes-text")) {
				"My note:"
			}
			.style(Styles.inlineLabel)

			textarea(.id("geocities-class-notes-text"), .part(Parts.text), .rows(3), .maxlength(120), .autocomplete("off"), .placeholder("Hei! Kjedelig time, eller hva?")) {}
				.style(GeoCitiesPage.Styles.field, Styles.text)

			div {
				button(.part(Parts.classic), .type(.button)) {
					"☐ Use the Classic"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				label {
					input(.part(Parts.boxes), .type(.checkbox))
					" Add “☐ Ja ☐ Nei ☐ Kanskje”"
				}
				.style(Styles.check)
			}
			.style(Styles.row)
		}
	}

	/**
	The buttons that draw a doodle on the note, and the eraser.
	*/
	private struct Doodles: HTML {
		var body: some HTML {
			div {
				for doodle in GeoCitiesClassNotes.doodles {
					button(.type(.button), .hook(Hooks.doodle, value: doodle.id)) {
						doodle.name
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
				}

				button(.type(.button), .hook(Hooks.doodle, value: "erase")) {
					"🧽 Erase"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.accessibilityLabel("Doodle on the note")
			.attributes(.role("group"))
			.style(Styles.row)
		}
	}

	/**
	The buttons that fold the note.
	*/
	private struct Folds: HTML {
		var body: some HTML {
			div {
				for fold in GeoCitiesClassNotes.folds {
					button(.type(.button), .hook(Hooks.fold, value: fold.id)) {
						fold.name
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
				}
			}
			.accessibilityLabel("Fold the note")
			.attributes(.role("group"))
			.style(Styles.row)
		}
	}

	/**
	The classroom from above, with the teacher, the risk meter, and what she reads out loud.
	*/
	private struct Classroom: HTML {
		var body: some HTML {
			div {
				p(.part(Parts.bubble)) {}
					.style(Styles.bubble)

				canvas(.part(Parts.room), .width(480), .height(400), .tabindex(0), .role("application")) {}
					.accessibilityLabel("My classroom from above, with the teacher at the blackboard. Click a desk next to the note to pass it there, or press an arrow key to pass it that way. With the paper airplane, click a desk to throw it there, or press Enter to throw it to the one the note is for.")
					.style(Styles.room)

				p {
					"✋ tells the teacher · 👀 reads it · 💤 asleep · 😆 giggles · ⚽ throws it · ♥ Ingrid · ★ Trond"
				}
				.style(Styles.legend)

				p(.part(Parts.stats)) {
					"Clock 08:15 ★ Risk 0% ★ Answered 0 ★ Caught 0"
				}
				.style(GeoCitiesPage.Styles.lcd, Styles.stats)

				p(.part(Parts.status), .role("status")) {
					"Write a note to Ingrid, fold it, and start the lesson."
				}
				.style(Styles.status)
			}
			.style(Styles.classroom)
		}
	}

	/**
	The pencil case, where the notes are kept.
	*/
	private struct PencilCase: HTML {
		var body: some HTML {
			div {
				h3 {
					"✏️ My Pencil Case"
				}
				.style(Styles.caseTitle)

				ul(.part(Parts.pencilCase)) {}
					.accessibilityLabel("Notes in my pencil case")
					.style(Styles.caseList)

				button(.part(Parts.empty), .type(.button)) {
					"Empty the Pencil Case"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.style(Styles.pencilCase)
		}
	}

	enum Parts: String, ElementPartSet {
		case sound
		case start
		case paper
		case recipient
		case text
		case classic
		case boxes
		case room
		case bubble
		case stats
		case status
		case pencilCase
		case empty
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button that picks a lesson, like `matte`.
		*/
		case lesson = "data-class-notes-lesson"

		/**
		A button that draws a doodle on the note, like `heart`, or `erase` to erase them.
		*/
		case doodle = "data-class-notes-doodle"

		/**
		A button that folds the note, like `football`.
		*/
		case fold = "data-class-notes-fold"
	}

	enum Styles: ElementStyleSet {
		case root
		case game
		case toolbar
		case row
		case toggle
		case bigTarget
		case notebook
		case paper
		case controls
		case inlineLabel
		case select
		case text
		case check
		case classroom
		case bubble
		case room
		case legend
		case stats
		case status
		case pencilCase
		case caseTitle
		case caseList

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .game:
				// The gray linoleum floor of the classroom.
				Style()
					.vstack(spacing: .rootEm(1))
					.padding(.rootEm(0.75))
					.background(Color("#cfc9b8"))
					.border(Color("#8a8370"), width: .pixels(4), style: .ridge)
					.color(.black)
			case .toolbar:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.flexWrap()
			case .row:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .toggle:
				// Pressed in while it is on.
				Style().when(.state, is: "on") {
					$0
						.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
						.background(Color("#e8e8e8"))
				}
			case .bigTarget:
				// Big enough for a finger.
				Style()
					.frame(minHeight: .rootEm(2.25))
					.touchAction(.manipulation)
			case .notebook:
				Style()
					.grid(minimumColumnWidth: .rootEm(16))
					.gap(.rootEm(0.75))
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .paper:
				// A page torn out of a school notebook. A finger doodles on it instead of scrolling the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(320.0 / 240.0)
					.shadow(Shadow(x: .pixels(3), y: .pixels(3), color: Color("#00000040")))
					.touchAction(.none)
					.cursor(.crosshair)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .controls:
				Style().vstack(spacing: .rootEm(0.5))
			case .inlineLabel:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .select:
				Style()
					.flex(1)
					.frame(minWidth: 0, minHeight: .rootEm(2.25))
			case .text:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
			case .check:
				// The whole label checks the box, and on a touch screen, the checkbox is big enough for a finger.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.frame(minHeight: .rootEm(2.25))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.handCursor()
					.children("input") {
						$0
							.flexShrink(0)
							.margin(0)
							.media(.coarsePointer) {
								$0.frame(width: .rootEm(1.5), height: .rootEm(1.5))
							}
					}
			case .classroom:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.position(.relative)
			case .bubble:
				// What the teacher reads out loud to the whole class, big, over the top of the classroom.
				Style()
					.hidden()
					.position(.absolute)
					.top(.rootEm(0.5))
					.leading(.rootEm(0.5))
					.trailing(.rootEm(0.5))
					.zIndex(1)
					.margin(0)
					.padding(.rootEm(0.75))
					.background(.white)
					.border(.black, width: .pixels(3))
					.cornerRadius(.rootEm(1.25))
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000066")))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.headline, weight: .bold)
					.overflowWrap(.anywhere)
					.textAlign(.center)
					.color(Color("#990000"))
					.children("strong") {
						$0
							.display(.block)
							.textStyle(.caption, weight: .bold)
							.color(.black)
					}
					.when(.state, is: "shown") {
						$0.display(.block)
					}
			case .room:
				// A tap passes the note, so a finger on it does not zoom the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto, maxWidth: .rootEm(36))
					.aspectRatio(480.0 / 400.0)
					.border(Color("#5a4630"), width: .pixels(4), style: .ridge)
					.touchAction(.manipulation)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .legend:
				Style()
					.margin(0)
					.textStyle(.caption)
					.textAlign(.center)
			case .stats:
				Style()
					.frame(width: .percent(100), maxWidth: .rootEm(36))
					.margin(0)
					.textStyle(.caption)
					.textAlign(.center)
			case .status:
				// A yellow sticky note, where the classroom says what happens.
				Style()
					.frame(width: .percent(100), maxWidth: .rootEm(36), minHeight: .lineHeight(2))
					.margin(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(Color("#fff68f"))
					.shadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#00000040")))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .pencilCase:
				// A pencil case of blue cloth, with a zipper all around.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#4466bb"), Color("#3355aa"), Color("#22397a")))
					.border(Color("#c0c0c0"), width: .pixels(4), style: .dashed)
					.cornerRadius(.rootEm(1))
					.color(.white)
			case .caseTitle:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
			case .caseList:
				// The notes lie in the case, folded.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
					.margin(0)
					.padding(0)
					.frame(minHeight: .rootEm(2))
					.children("li") {
						$0.display(.block)
					}
					.children("li button") {
						$0
							.frame(minHeight: .rootEm(2.25))
							.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
							.background(Color("#fffef2"))
							.border(Color("#9db4d8"), width: .pixels(1))
							.fontFamily(GeoCitiesPage.comicSans)
							.textStyle(.caption)
							.color(.black)
							.handCursor()
					}
			}
		}
	}
}
