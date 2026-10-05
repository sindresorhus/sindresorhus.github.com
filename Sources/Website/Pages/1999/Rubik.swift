import Elementary
import Foundation
import SiteKit

/**
Pappa’s Rubik’s Cube from 1981, which nobody in the family has ever solved, as a real cube in 3D on a canvas, with the black plastic, the worn stickers, and the logo on the white center. The visitor turns the whole cube in the hand by dragging beside it (or with the arrow keys), and turns a layer by dragging on a face, where the direction of the drag picks the layer and the way it turns, and the layer follows the finger until it snaps to a quarter turn. The keys of the notation turn it too (R, L, U, D, F, B, the middle slices M, E, and S, and the whole cube with X, Y, and Z, with Shift for the other way), always as the cube is held, and a field plays algorithms like “(R U R’ U’)6”. Scramble makes 25 random turns and shows them in the notation, and then the timer starts at the first turn, like the timer of a speedcuber, with a move counter, Undo, and the best times on a score card. A solved cube is celebrated. Pattern buttons make the checkerboard, the cube in a cube, the six spots, and the superflip. Then the cheats of every kid: peel a sticker off and put it on another place (or make the whole cube look solved at once), and the cube tells that it is a fake, and why it can no longer be solved; or take it apart with a screwdriver, so the pieces fall on the table, and put it back together solved, or let Lillesøster put it back, which can only be solved 1 time of 12. Pappa can try too: he turns it for 3 minutes on his own clock, says things in Norwegian, makes it worse, and gives up. The instruction booklet from 1981 has the steps of the layer-by-layer method, with buttons that show the pieces of a step on the cube and play its algorithms, and a solver finds a real solution with the same steps and plays it. Its script, `Rubik.js`, runs it, only while it is on the screen and the tab is visible, and keeps the cube and the best times in the browser. Nothing makes a sound until the visitor turns on the sound, and with reduced motion, every turn happens at once. Without scripts, it is left out, as it has nothing to show.
*/
struct GeoCitiesRubik: ScriptedElement {
	static let script = ElementScript()

	/**
	A page of the instruction booklet, with an algorithm to try and the pieces to show on the cube.
	*/
	private struct Page {
		let title: String
		let text: String
		var algorithms = [String]()

		/**
		The pieces that the script shows on the cube, like `cross`.
		*/
		var highlight: String?

		/**
		What Pappa wrote on the page with a pencil, in 1981.
		*/
		let note: String
	}

	private static let pages = [
		Page(
			title: "Solution for Rubik’s Cube",
			text: "The cube can be scrambled in 43 252 003 274 489 856 000 ways, and only one of them is solved. Follow the seven steps of this booklet, one layer at a time, and do not give up!",
			note: "Kjøpt i Bergen, 1981. 79 kr. (Bought in Bergen.)"
		),
		Page(
			title: "Step 1: Solve the first layer cross",
			text: "Hold the cube with the white center on top. Find the four edges with white on them, and put them around the white center, so that the other color of each edge matches the center on the side.",
			highlight: "cross",
			note: "Hvordan?! (How?!)"
		),
		Page(
			title: "Step 2: The white corners",
			text: "Find a white corner, and turn the bottom until the corner is under its place, in front on the right. Then repeat R’ D’ R D until it goes up in its place, with white on top. Do not worry about the rest, it comes back.",
			algorithms: ["R’ D’ R D"],
			highlight: "corners",
			note: "Fikk 1 hjørne. (Got 1 corner.)"
		),
		Page(
			title: "Step 3: The middle layer",
			text: "Turn the cube over, so yellow is on top. Find an edge on top without yellow, and turn the top until it matches the center in front. Then move it down to the right or to the left.",
			algorithms: ["U R U’ R’ U’ F’ U F", "U’ L’ U L U F U’ F’"],
			highlight: "middle",
			note: "Her ble det rot. (Here it got messy.)"
		),
		Page(
			title: "Step 4: The yellow cross",
			text: "Do F R U R’ U’ F’ until there is a yellow cross on top. Hold a yellow line from left to right, or a yellow L in the back on the left.",
			algorithms: ["F R U R’ U’ F’"],
			highlight: "yellowCross",
			note: ""
		),
		Page(
			title: "Step 5: The yellow edges",
			text: "Turn the top until two edges match their centers. This algorithm swaps the edge in front and the edge on the left.",
			algorithms: ["R U R’ U R U2 R’ U"],
			highlight: "yellowCross",
			note: ""
		),
		Page(
			title: "Step 6: The yellow corners in their places",
			text: "This algorithm moves three corners around, and keeps the one in front on the right. Repeat until every corner is in its place, even if it is twisted.",
			algorithms: ["U R U’ L’ U R’ U’ L"],
			highlight: "yellowCorners",
			note: ""
		),
		Page(
			title: "Step 7: Twist the yellow corners",
			text: "Do R’ D’ R D two or four times, until the corner in front on the right is yellow on top. Then turn only the top, with U, to bring the next corner there. The cube looks broken in the middle of this step. Do not stop!",
			algorithms: ["R’ D’ R D R’ D’ R D", "U"],
			highlight: "yellowCorners",
			note: "Her ga jeg opp. 1981. (Here I gave up.)"
		),
	]

	private static let patterns: [(name: String, algorithm: String)] = [
		("🏁 Checkerboard", "M2 E2 S2"),
		("📦 Cube in a Cube", "F L F U’ R U F2 L2 U’ L’ B D’ B’ L2 U"),
		("🎲 Six Spots", "U D’ R L’ F B’ U D’"),
		("🌀 Superflip", "U R2 F B R B2 R U2 L B2 R U’ D’ R2 F R’ L B2 U2 F2"),
	]

	var content: some HTML {
		h2 {
			"Pappa’s Rubik’s Cube"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Pappa bought it in 1981, the year it came to Norway, and nobody in our family has ever solved it. It has been on the shelf in the living room with the same scramble since. Drag a face to turn it, drag beside it to turn the whole cube, or use the letters of the notation. Or cheat, like every kid in the world: peel the stickers, or take it apart with a screwdriver."
		}

		div {
			canvas(.part(Parts.canvas), .width(1080), .height(810), .tabindex(0), .role("application")) {}
				.accessibilityLabel("Pappa’s Rubik’s Cube. Drag a face to turn that layer, or drag beside the cube to turn the whole cube. The keys R, L, U, D, F, B, M, E, and S turn the layers, and X, Y, and Z turn the whole cube, with Shift for the other way. The arrow keys turn the cube in the hand, Home shows the front, and Backspace undoes a turn.")
				.style(Styles.canvas)

			Display()

			p(.part(Parts.notation)) {
				"Pappa’s scramble from 1981. Nobody remembers the moves."
			}
			.style(Styles.notation)

			// The status is right under the cube, so a visitor on a phone can read what Pappa says while watching him turn it.
			p(.part(Parts.status), .role("status")) {
				"The cube is on the table, just like Pappa left it in 1981."
			}
			.style(Styles.status)

			Controls()

			Solution()

			div {
				Booklet()

				ScoreCard()
			}
			.style(Styles.papers)
		}
		.style(Styles.toy, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The cube needs JavaScript. Pappa says it needs a hammer."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The timer of a speedcuber, the move counter, and the best time, on a green screen.
	*/
	private struct Display: HTML {
		var body: some HTML {
			div {
				span {
					"⏱ "
					span(.part(Parts.time)) {
						"0:00.00"
					}
					.style(Styles.time)
				}

				span(.part(Parts.moves)) {
					"0 moves"
				}

				span(.part(Parts.best)) {
					"Best: none"
				}
			}
			.style(GeoCitiesPage.Styles.lcd, Styles.display)
		}
	}

	private struct Controls: HTML {
		var body: some HTML {
			div {
				div {
					button(.part(Parts.scramble), .type(.button)) {
						"🔀 Scramble"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					button(.part(Parts.undo), .type(.button), .disabled) {
						"↩️ Undo"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					button(.part(Parts.view), .type(.button)) {
						"👀 Front View"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
						"🔈 Sound"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)

				form(.part(Parts.form)) {
					label(.for("geocities-rubik-algorithm")) {
						"Algorithm:"
					}
					.style(Styles.formLabel)

					input(.id("geocities-rubik-algorithm"), .part(Parts.algorithm), .type(.text), .autocomplete("off"), .maxlength(200), .placeholder("(R U R’ U’)6"), .value("(R U R’ U’)6"))
						.style(GeoCitiesPage.Styles.field, Styles.algorithmField)

					button(.type(.submit)) {
						"▶ Play"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(Styles.form)

				div {
					for pattern in GeoCitiesRubik.patterns {
						button(.type(.button), .hook(Hooks.pattern, value: pattern.algorithm)) {
							pattern.name
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.smallButton)
					}
				}
				.accessibilityLabel("Patterns")
				.style(GeoCitiesPage.Styles.buttonRow)

				Cheats()
			}
			.style(Styles.controls)
		}
	}

	/**
	The cheats of every kid, and the help of Pappa and the solver.
	*/
	private struct Cheats: HTML {
		var body: some HTML {
			div {
				button(.part(Parts.peel), .type(.button), .ariaPressed(false)) {
					"🩹 Peel the Stickers"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.lookSolved), .type(.button), .hidden) {
					"✨ Make It Look Solved"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.restick), .type(.button), .hidden) {
					"🩹 Put the Stickers Back"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.apart), .type(.button)) {
					"🪛 Take It Apart"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.together), .type(.button), .hidden) {
					"🧩 Put It Back Together"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.sister), .type(.button), .hidden) {
					"👧 Let Lillesøster Put It Back"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.pappa), .type(.button)) {
					"👨 Let Pappa Try"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.part(Parts.solve), .type(.button)) {
					"🤓 Show the Solution"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
	}

	/**
	The solution of the solver, step by step, with the steps of the booklet. The script fills in the steps.
	*/
	private struct Solution: HTML {
		var body: some HTML {
			div(.part(Parts.solution), .hidden) {
				p {
					"The solution, with the steps of the booklet"
				}
				.style(Styles.paperTitle)

				ol {
					for index in 0..<9 {
						li(.hook(Hooks.step, value: "\(index)"), .hidden) {
							span {}
								.style(Styles.stepTitle)
							" "
							code {}
								.style(Styles.stepMoves)
						}
						.style(Styles.step)
					}
				}
				.style(Styles.steps)

				div {
					button(.part(Parts.nextStep), .type(.button)) {
						"⏭ Next Step"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					button(.part(Parts.playSolution), .type(.button)) {
						"▶ Play It All"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.style(Styles.solution)
		}
	}

	/**
	The small instruction booklet that came with the cube in 1981, with a pencil note from Pappa on some pages.
	*/
	private struct Booklet: HTML {
		var body: some HTML {
			aside {
				for index in GeoCitiesRubik.pages.indices {
					BookletPage(page: GeoCitiesRubik.pages[index], index: index)
				}

				div {
					button(.part(Parts.previousPage), .type(.button), .disabled) {
						"◀"
					}
					.accessibilityLabel("Previous page")
					.style(GeoCitiesPage.Styles.smallButton, Styles.smallButton)

					span(.part(Parts.pageNumber)) {
						"1 / \(GeoCitiesRubik.pages.count)"
					}
					.style(Styles.pageNumber)

					button(.part(Parts.nextPage), .type(.button)) {
						"▶"
					}
					.accessibilityLabel("Next page")
					.style(GeoCitiesPage.Styles.smallButton, Styles.smallButton)
				}
				.style(Styles.pageButtons)
			}
			.accessibilityLabel("The instruction booklet of the cube, from 1981")
			.style(Styles.booklet)
		}
	}

	/**
	A page of the booklet. Only the first page is shown at first, and the script turns the pages.
	*/
	private struct BookletPage: HTML {
		let page: Page
		let index: Int

		var body: some HTML {
			div(.hook(Hooks.page, value: "\(index)")) {
				p {
					page.title
				}
				.style(Styles.pageTitle)

				p {
					page.text
				}
				.style(Styles.pageText)

				if !page.algorithms.isEmpty || page.highlight != nil {
					div {
						if let highlight = page.highlight {
							button(.type(.button), .hook(Hooks.highlight, value: highlight)) {
								"👆 Show Me"
							}
							.style(GeoCitiesPage.Styles.smallButton, Styles.smallButton)
						}

						for algorithm in page.algorithms {
							button(.type(.button), .hook(Hooks.algorithmButton, value: algorithm)) {
								"▶ \(algorithm)"
							}
							.style(GeoCitiesPage.Styles.smallButton, Styles.smallButton)
						}
					}
					.style(Styles.pageActions)
				}

				if !page.note.isEmpty {
					p {
						page.note
					}
					.style(Styles.pencil)
				}
			}
			.attributes(.hidden, when: index > 0)
			.style(Styles.page)
		}
	}

	/**
	The best times, on a card from the drawer.
	*/
	private struct ScoreCard: HTML {
		var body: some HTML {
			aside {
				p {
					"Best times"
				}
				.style(Styles.cardTitle)

				ol {
					for index in 0..<5 {
						li(.hook(Hooks.bestTime, value: "\(index)"), .hidden) {}
					}
				}
				.style(Styles.times)

				p {
					"Scramble, and the clock starts at your first turn. Times with help from the solver, Pappa, or the stickers do not count."
				}
				.style(Styles.cardText)

				p {
					"Pappa’s best time: never (since 1981)"
				}
				.style(Styles.pencil)
			}
			.accessibilityLabel("Best times")
			.style(Styles.card)
		}
	}

	enum Parts: String, ElementPartSet {
		case canvas
		case time
		case moves
		case best
		case notation
		case form
		case algorithm
		case scramble
		case undo
		case view
		case sound
		case peel
		case lookSolved
		case restick
		case apart
		case together
		case sister
		case pappa
		case solve
		case solution
		case nextStep
		case playSolution
		case previousPage
		case nextPage
		case pageNumber
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A step of the solution, with its number.
		*/
		case step = "data-rubik-step"

		/**
		A best time on the score card, with its place.
		*/
		case bestTime = "data-rubik-time"

		/**
		A page of the booklet, with its number.
		*/
		case page = "data-rubik-page"

		/**
		A button that plays an algorithm of the booklet, with the algorithm.
		*/
		case algorithmButton = "data-rubik-algorithm"

		/**
		A button that shows the pieces of a step on the cube, like `cross`.
		*/
		case highlight = "data-rubik-highlight"

		/**
		A button that makes a pattern, with its algorithm.
		*/
		case pattern = "data-rubik-pattern"
	}

	enum Styles: ElementStyleSet {
		case root
		case toy
		case canvas
		case display
		case time
		case notation
		case controls
		case form
		case formLabel
		case algorithmField
		case smallButton
		case status
		case solution
		case paperTitle
		case steps
		case step
		case stepTitle
		case stepMoves
		case papers
		case booklet
		case page
		case pageTitle
		case pageText
		case pageActions
		case pencil
		case pageButtons
		case pageNumber
		case card
		case cardTitle
		case times
		case cardText

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .toy:
				Style().vstack(alignment: .center, spacing: .rootEm(0.75))
			case .canvas:
				// The cube in the hand, over the table in the living room. A drag on it turns the cube, not the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto, maxWidth: .rootEm(40))
					.aspectRatio(4.0 / 3.0)
					.background(Color("#2b3756"))
					.border(Color("#5a3a1a"), width: .pixels(4), style: .ridge)
					.touchAction(.none)
					.textSelection(.disabled)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffcc00"), width: .pixels(3), offset: .pixels(2))
					}
			case .display:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(1))
					.flexWrap()
					.frame(width: .percent(100), maxWidth: .rootEm(40))
					.monospacedDigit()
			case .time:
				Style()
					.font(.large, weight: .bold)
					.when(.state, is: "running") {
						$0.color(Color("#ffee55"))
					}
					.when(.state, is: "solved") {
						$0
							.color(Color("#66ffff"))
							.textShadow(Shadow(y: 0, blur: .pixels(6), color: Color("#33ffff")))
					}
			case .notation:
				// The notation of the last turns, typed on the typewriter of Mormor.
				Style()
					.frame(width: .percent(100), maxWidth: .rootEm(40), minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .controls:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.5))
					.frame(width: .percent(100), maxWidth: .rootEm(40))
			case .form:
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.5))
					.frame(width: .percent(100))
			case .formLabel:
				Style()
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
			case .algorithmField:
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(6), minHeight: .rootEm(2.5))
					.fontFamily(GeoCitiesPage.courier)
			case .smallButton:
				// Big enough for a finger.
				Style()
					.frame(minHeight: .rootEm(2.25))
					.touchAction(.manipulation)
			case .status:
				Style()
					.frame(maxWidth: .rootEm(40), minHeight: .lineHeight(3))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
					.textAlign(.center)
			case .solution:
				// A sheet of squared paper from my math book, with the solution written on it.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(width: .percent(100), maxWidth: .rootEm(40))
					.padding(.rootEm(0.75))
					.background(Color("#fbfbf4"))
					.border(Color("#9db4d6"), width: .pixels(2))
					.shadow(Shadow(x: .pixels(3), y: .pixels(4), color: Color("#00000040")))
					.fontFamily(GeoCitiesPage.comicSans)
					.color(Color("#1a1a6a"))
			case .paperTitle:
				Style()
					.margin(0)
					.font(.large, weight: .bold)
					.textAlign(.center)
			case .steps:
				Style()
					.vstack(spacing: .rootEm(0.375))
					.margin(0)
					.padding(.leading, .rootEm(1.5))
			case .step:
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.25))
					.border(Color("#00000000"), width: .pixels(2))
					.when(.state, is: "current") {
						$0
							.background(Color("#fff6a8"))
							.border(Color("#d0a000"), width: .pixels(2), style: .dashed)
					}
					.when(.state, is: "done") {
						$0.opacity(0.55)
					}
			case .stepTitle:
				Style().fontWeight(.bold)
			case .stepMoves:
				Style()
					.display(.block)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#222222"))
			case .papers:
				Style()
					.grid(minimumColumnWidth: .rootEm(15))
					.gap(.rootEm(1))
					.frame(width: .percent(100), maxWidth: .rootEm(40))
			case .booklet:
				// The small booklet of thin paper, folded in the middle, a bit yellow after 18 years.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#f6edd2"))
					.border(Color("#b9a77a"), width: .pixels(1))
					.border(.leading, Color("#c8102e"), width: .rootEm(0.5))
					.shadow(Shadow(x: .pixels(3), y: .pixels(4), color: Color("#00000040")))
					.rotationEffect(.degrees(-0.8))
					.fontFamily(GeoCitiesPage.times)
					.color(Color("#1a1a1a"))
			case .page:
				Style()
					.vstack(spacing: .rootEm(0.375))
					.frame(minHeight: .rootEm(12))
			case .pageTitle:
				Style()
					.margin(0)
					.padding(.bottom, .rootEm(0.25))
					.border(.bottom, Color("#1a1a1a"), width: .pixels(2))
					.font(.large, weight: .heavy)
			case .pageText:
				Style()
					.margin(0)
					.textStyle(.body)
			case .pageActions:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .pencil:
				// Pappa’s pencil, gray and a bit crooked.
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption)
					.italic()
					.color(Color("#666666"))
					.rotationEffect(.degrees(-2))
			case .pageButtons:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.margin(.top, .auto)
			case .pageNumber:
				Style()
					.textStyle(.caption)
					.monospacedDigit()
			case .card:
				// A white index card with blue lines, from the drawer of Mamma’s desk.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#ffffff"))
					.border(.top, Color("#d0102a"), width: .pixels(3))
					.shadow(Shadow(x: .pixels(3), y: .pixels(4), color: Color("#00000040")))
					.rotationEffect(.degrees(0.8))
					.fontFamily(GeoCitiesPage.comicSans)
					.color(Color("#1a1a6a"))
			case .cardTitle:
				Style()
					.margin(0)
					.font(.large, weight: .bold)
			case .times:
				Style()
					.margin(0)
					.padding(.leading, .rootEm(1.5))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.body, weight: .bold)
					.monospacedDigit()
			case .cardText:
				Style()
					.margin(0)
					.textStyle(.caption)
			}
		}
	}
}
