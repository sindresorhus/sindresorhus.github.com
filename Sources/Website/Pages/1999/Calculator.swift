import Elementary
import Foundation
import SiteKit

/**
My TI-83, the graphing calculator of Texas Instruments (1996) that every kid in my class had for math, and used for games. It is drawn with its dark gray plastic, the gray-green screen of 96 × 64 pixels, and all 50 keys, with the yellow 2nd functions and the green letters of ALPHA printed above them. Its script, `Calculator.js`, draws the screen pixel by pixel on a canvas, with the real pixel fonts (the big one of the home screen and the small one of the graph screen), the blinking cursor that shows 2nd and ALPHA, and the slow LCD that leaves a shadow when things move. The keys work with the mouse, a finger, and the keys of the computer, and the arrows and DEL repeat while they are held down. The home screen calculates for real, with the order of operations of a TI (where −2² is −4 and implied multiplication counts as ×), Ans, the (−) key that is not the minus key, x², x⁻¹, √(, sin(, π, ▸Frac, STO▶ to letters, 2nd ENTRY, and the real error screens like “ERR:SYNTAX 1:Quit 2:Goto” and “ERR:DIVIDE BY 0”. MODE switches between Radian and Degree, Float and Fix, and Normal and Sci. The Y= editor takes up to seven functions, WINDOW and ZOOM set the window, GRAPH draws the functions one column of pixels at a time, slowly, like the real one, with the busy indicator in the corner (and at once with reduced motion), TRACE moves a blinking cursor along the graph, and 2nd TABLE shows the values. PRGM runs my games: PHOENIX, the shooter with birds and a shield, WAFFLRUN, where I jump over Rocky the pet rock and catch waffles in the rain, SNAKE, and QUIZ, Trond’s program that answers the math homework badly. EDIT shows their code. The sticky note has the numbers that make words when you turn the calculator over, like 0.7734 (“hELLO”), and Turn It Over turns it. The Teacher Is Coming! switches to a boring graph of the homework at once. The link cable connects Trond’s TI-83, where he sends me his games, with “Transmitting…” on his screen, and “ERR:MEMORY” when mine is full. 2nd MEM resets the memory and erases all the games. 2nd and the up and down arrows set the contrast, and the four AAA batteries run down, so the screen fades, until the visitor changes them in the battery door (but never the round backup battery). With reduced motion, the cursor does not blink, the graph draws at once, and the games only go on while the visitor presses keys.
*/
struct GeoCitiesCalculator: ScriptedElement {
	static let script = ElementScript()

	/**
	The kind of a key, which sets its color, like the light gray number keys and the yellow 2nd key.
	*/
	enum KeyKind {
		case top
		case dark
		case light
		case second
		case alpha
	}

	/**
	A key: its ID for the script, what is printed on it, the 2nd function in yellow and the ALPHA letter in green above it, and its name for screen readers.
	*/
	struct Key {
		let id: String
		let label: String
		var second = ""
		var alpha = ""
		var kind = KeyKind.dark
		var name: String?
	}

	static let topKeys = [
		Key(id: "y=", label: "Y=", second: "STAT PLOT", kind: .top),
		Key(id: "window", label: "WINDOW", second: "TBLSET", kind: .top),
		Key(id: "zoom", label: "ZOOM", second: "FORMAT", kind: .top),
		Key(id: "trace", label: "TRACE", second: "CALC", kind: .top),
		Key(id: "graph", label: "GRAPH", second: "TABLE", kind: .top),
	]

	static let upperKeys = [
		Key(id: "2nd", label: "2nd", kind: .second),
		Key(id: "mode", label: "MODE", second: "QUIT"),
		Key(id: "del", label: "DEL", second: "INS"),
		Key(id: "alpha", label: "ALPHA", second: "A-LOCK", kind: .alpha),
		Key(id: "xt", label: "X,T,θ", second: "LINK", name: "X, T, theta"),
		Key(id: "stat", label: "STAT", second: "LIST"),
	]

	static let lowerKeys = [
		Key(id: "math", label: "MATH", second: "TEST", alpha: "A"),
		Key(id: "matrx", label: "MATRX", second: "ANGLE", alpha: "B"),
		Key(id: "prgm", label: "PRGM", second: "DRAW", alpha: "C"),
		Key(id: "vars", label: "VARS", second: "DISTR", alpha: "D"),
		Key(id: "clear", label: "CLEAR"),
		Key(id: "inverse", label: "x⁻¹", second: "", alpha: "E", name: "x inverse"),
		Key(id: "sin", label: "SIN", second: "SIN⁻¹", alpha: "F"),
		Key(id: "cos", label: "COS", second: "COS⁻¹", alpha: "G"),
		Key(id: "tan", label: "TAN", second: "TAN⁻¹", alpha: "H"),
		Key(id: "power", label: "^", second: "π", alpha: "I", name: "power"),
		Key(id: "square", label: "x²", second: "√", alpha: "J", name: "x squared"),
		Key(id: "comma", label: ",", second: "EE", alpha: "K", name: "comma"),
		Key(id: "open", label: "(", second: "{", alpha: "L", name: "open parenthesis"),
		Key(id: "close", label: ")", second: "}", alpha: "M", name: "close parenthesis"),
		Key(id: "divide", label: "÷", second: "e", alpha: "N", name: "divide"),
		Key(id: "log", label: "LOG", second: "10ˣ", alpha: "O"),
		Key(id: "7", label: "7", second: "u", alpha: "P", kind: .light),
		Key(id: "8", label: "8", second: "v", alpha: "Q", kind: .light),
		Key(id: "9", label: "9", second: "w", alpha: "R", kind: .light),
		Key(id: "multiply", label: "×", second: "[", alpha: "S", name: "multiply"),
		Key(id: "ln", label: "LN", second: "eˣ", alpha: "T"),
		Key(id: "4", label: "4", second: "L4", alpha: "U", kind: .light),
		Key(id: "5", label: "5", second: "L5", alpha: "V", kind: .light),
		Key(id: "6", label: "6", second: "L6", alpha: "W", kind: .light),
		Key(id: "subtract", label: "−", second: "]", alpha: "X", name: "minus"),
		Key(id: "store", label: "STO▶", second: "RCL", alpha: "Y", name: "store"),
		Key(id: "1", label: "1", second: "L1", alpha: "Z", kind: .light),
		Key(id: "2", label: "2", second: "L2", alpha: "θ", kind: .light),
		Key(id: "3", label: "3", second: "L3", kind: .light),
		Key(id: "add", label: "+", second: "MEM", alpha: "“", name: "plus"),
		Key(id: "on", label: "ON", second: "OFF"),
		Key(id: "0", label: "0", second: "CATALOG", alpha: "␣", kind: .light),
		Key(id: ".", label: ".", second: "i", alpha: ":", kind: .light, name: "decimal point"),
		Key(id: "negate", label: "(−)", second: "ANS", alpha: "?", kind: .light, name: "negative"),
		Key(id: "enter", label: "ENTER", second: "ENTRY", alpha: "SOLVE"),
	]

	/**
	The numbers on the sticky note, which make words when the calculator is upside down, with the word.
	*/
	static let upsideDownWords: [(number: String, word: String)] = [
		("0.7734", "hELLO"),
		("7718", "BILL"),
		("3045", "ShOE"),
		("4614", "hIgh"),
		("5508", "BOSS"),
		("618", "BIg"),
		("35007", "LOOSE"),
		("0.637", "LEgO"),
	]

	/**
	The programs on Trond’s calculator, which he sends over the link cable, with their size in bytes.
	*/
	static let trondPrograms: [(name: String, size: Int)] = [
		("FALLDOWN", 2348),
		("CATPIC", 4116),
		("RPGQUEST", 18400),
		("PHOENIX", 8977),
		("WAFFLRUN", 3312),
		("SNAKE", 1560),
		("QUIZ", 921),
	]

	var content: some HTML {
		h2 {
			"My TI-83"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"Everybody in 8B has a TI-83 for math, and nobody uses it for math. Mine has PHOENIX, WAFFLRUN (I made it), SNAKE, and QUIZ, and Trond sends me more over the link cable. It calculates too, and it draws graphs, slowly. Click the keys, or click the screen and type: Enter, Backspace for DEL, Esc for CLEAR, Shift for 2nd, ~ for (−), F1 to F8 for the top keys, MODE, PRGM, and MATH, and Home for ON."
		}

		div {
			// The status is right under the calculator, so on a phone the screen, the keys, and the tips fit on the screen together.
			div {
				Calculator()

				p(.part(Parts.upsideDown)) {}
					.hidden(when: true)
					.style(Styles.upsideDown)

				p(.part(Parts.status), .role("status")) {
					"It is on. Try 2+2 ENTER, or PRGM ENTER ENTER to play PHOENIX."
				}
				.style(Styles.status)
			}
			.style(Styles.column)

			div {
				StickyNote()

				TrondCalculator()

				BatteryDoor()
			}
			.style(Styles.side)
		}
		.style(Styles.desk, GeoCitiesPage.Styles.scriptingOnly)

		div {
			button(.part(Parts.flip), .type(.button), .ariaPressed(false)) {
				"🙃 Turn It Over"
			}
			.style(GeoCitiesPage.Styles.retroButton, Styles.toggle)

			button(.part(Parts.teacher), .type(.button)) {
				"👨‍🏫 The Teacher Is Coming!"
			}
			.style(GeoCitiesPage.Styles.retroButton, Styles.toggle, Styles.teacher)

			button(.part(Parts.link), .type(.button), .ariaPressed(false)) {
				"🔌 Link Cable to Trond"
			}
			.style(GeoCitiesPage.Styles.retroButton, Styles.toggle)

			button(.part(Parts.batteries), .type(.button), .ariaPressed(false)) {
				"🔋 Change the Batteries"
			}
			.style(GeoCitiesPage.Styles.retroButton, Styles.toggle, Styles.batteries)
		}
		.style(GeoCitiesPage.Styles.buttonRow, Styles.buttons, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My TI-83 needs JavaScript. And four AAA batteries."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case calculator
		case screen
		case status
		case flip
		case teacher
		case link
		case batteries
		case upsideDown
		case trond
		case trondScreen
		case receive
		case batteryDoor
		case backup
		case closeDoor
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A key of the calculator, by its ID, like `enter` or `7`.
		*/
		case key = "data-ti83-key"

		/**
		A number on the sticky note, which the button types on the calculator.
		*/
		case number = "data-ti83-number"

		/**
		A program on Trond’s calculator, by its name, which the button sends over the link cable.
		*/
		case send = "data-ti83-send"

		/**
		A slot of an AAA battery in the battery door, by its index.
		*/
		case battery = "data-ti83-battery"
	}

	enum Styles: ElementStyleSet {
		case root
		case desk
		case column
		case side
		case body
		case brand
		case brandName
		case brandMaker
		case bezel
		case screen
		case keypad
		case upperRows
		case upperGrid
		case keyGrid
		case keyCell
		case keyLabels
		case secondLabel
		case alphaLabel
		case key
		case darkKey
		case topKey
		case lightKey
		case secondKey
		case alphaKey
		case arrowPad
		case arrowKey
		case note
		case noteTitle
		case noteButtons
		case noteButton
		case trond
		case cable
		case trondScreen
		case trondButtons
		case door
		case cells
		case cell
		case backup
		case buttons
		case toggle
		case teacher
		case batteries
		case upsideDown
		case status

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .desk:
				// The calculator is wider than it is tall halfway through Turn It Over, so the sides are clipped, or a phone would get a horizontal scroll for a moment.
				Style()
					.hstack(alignment: .start, justification: .center, spacing: .rootEm(1.25))
					.flexWrap()
					.overflow(horizontal: .clip)
			case .column:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.frame(width: .rootEm(19.5), maxWidth: .percent(100))
			case .side:
				Style()
					.vstack(spacing: .rootEm(1))
					.frame(width: .rootEm(17), maxWidth: .percent(100))
			case .body:
				// The dark gray plastic of the TI-83, a long calculator with rounded corners, which turns over slowly.
				Style()
					.vstack(spacing: .rootEm(0.625))
					.frame(width: .rootEm(19.5), maxWidth: .percent(100))
					.padding(top: .rootEm(0.75), horizontal: .rootEm(0.75), bottom: .rootEm(1.25))
					.backgroundImage(.linearGradient("to right", Color("#3c3d42"), Color("#4b4c52"), Color("#3c3d42")))
					.border(Color("#1f2023"), width: .pixels(2))
					.cornerRadius(.rootEm(1.25))
					.shadow(Shadow(x: .pixels(4), y: .pixels(6), color: Color("#00000066")), Shadow(x: .pixels(-2), y: .pixels(-2), blur: .pixels(4), color: Color("#00000055"), isInset: true))
					.color(.white)
					.when(.state, is: "flipped") {
						$0.rotationEffect(.degrees(180))
					}
					.media(.allowsMotion) {
						$0.transition(.rotationEffect, animation: .easeInOut(duration: .milliseconds(800)))
					}
			case .brand:
				Style().hstack(alignment: .baseline, justification: .spaceBetween, spacing: .rootEm(0.5))
			case .brandName:
				Style()
					.margin(0)
					.fontFamily(.system)
					.font(.large, weight: .heavy)
					.italic()
					.color(Color("#f0f0f0"))
			case .brandMaker:
				Style()
					.margin(0)
					.fontFamily(.system)
					.font(size: .rootEm(0.625))
					.letterSpacing(.em(0.1))
					.fontWeight(.bold)
					.color(Color("#c8c8cc"))
			case .bezel:
				// The black frame around the screen.
				Style()
					.padding(.rootEm(0.625))
					.background(Color("#1b1c1f"))
					.border(Color("#0e0e10"), width: .pixels(2), style: .inset)
					.cornerRadius(.rootEm(0.5))
			case .screen:
				// The screen of 96 × 64 pixels, drawn four times as big, in the gray-green of the LCD. The glass has a margin around the pixels, like on the real one, so the top line and the left column are not cut by the frame. The canvas keeps its own aspect ratio, so the padding does not stretch the pixels.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.padding(.rootEm(0.25))
					.background(Color("#a9b597"))
					.imageRendering(.pixelated)
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ffd23f"), width: .pixels(2), offset: .pixels(2))
					}
			case .keypad:
				Style().vstack(spacing: .rootEm(0.25))
			case .upperRows:
				Style().hstack(alignment: .center, spacing: .rootEm(0.375))
			case .upperGrid:
				Style()
					.grid(columns: 3)
					.gap(row: .rootEm(0.25), column: .rootEm(0.375))
					.flex(3)
			case .keyGrid:
				Style()
					.grid(columns: 5)
					.gap(row: .rootEm(0.25), column: .rootEm(0.375))
			case .keyCell:
				Style()
					.vstack(spacing: .pixels(1))
					.frame(minWidth: 0)
			case .keyLabels:
				// The 2nd function in yellow on the left, and the letter of ALPHA in green on the right, printed above the key.
				Style()
					.hstack(justification: .spaceBetween, spacing: .pixels(2))
					.frame(minHeight: .lineHeight(1))
					.fontFamily(.system)
					.font(size: .rootEm(0.5), lineHeight: 1.2)
					.fontWeight(.bold)
					.textWrap(.nowrap)
					.textSelection(.disabled)
			case .secondLabel:
				Style().color(Color("#f2c94c"))
			case .alphaLabel:
				Style().color(Color("#5fd38a"))
			case .key:
				// A dark rubber key, which moves down while it is pressed.
				Style()
					.frame(width: .percent(100), minHeight: .rootEm(2.125))
					.padding(vertical: 0, horizontal: .pixels(1))
					.background(Color("#232427"))
					.border(Color("#0c0c0d"), width: .pixels(1))
					.cornerRadius(.rootEm(0.375))
					.shadow(Shadow(y: .pixels(2), color: Color("#101012")))
					.fontFamily(.system)
					.font(size: .rootEm(0.6875))
					.fontWeight(.bold)
					.color(Color("#f4f4f4"))
					.textWrap(.nowrap)
					.touchAction(.manipulation)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0
							.offset(y: .pixels(2))
							.shadow(Shadow(y: 0, color: Color("#101012")))
					}
					.when(.state, is: "down") {
						$0
							.offset(y: .pixels(2))
							.shadow(Shadow(y: 0, color: Color("#101012")))
					}
					.when(.state, is: "on") {
						$0.focusRing(Color("#ffffff"), width: .pixels(2), offset: .pixels(1))
					}
					// The dotted ring of the page is dark on the light keys, so it would not show on the dark plastic.
					.focusVisible {
						$0.focusRing(Color("#ffd23f"), width: .pixels(2), offset: .pixels(2))
					}
			case .darkKey:
				// Most keys are black, with white text.
				Style()
					.background(Color("#1d1e21"))
					.color(Color("#f4f4f4"))
			case .topKey:
				// The slim light keys under the screen.
				Style()
					.frame(minHeight: .rootEm(1.625))
					.background(Color("#c9cacd"))
					.font(size: .rootEm(0.5625))
					.color(Color("#1b1b1d"))
			case .lightKey:
				Style()
					.background(Color("#b9babe"))
					.font(size: .rootEm(0.9375))
					.color(Color("#111"))
			case .secondKey:
				Style()
					.background(Color("#f2c94c"))
					.color(Color("#1b1b1d"))
			case .alphaKey:
				Style()
					.background(Color("#4fbf78"))
					.color(Color("#0b1f12"))
			case .arrowPad:
				// The four arrow keys in a round cluster, like on the real one.
				Style()
					.grid(columns: 3)
					.flex(2)
					.frame(height: .rootEm(6))
					.padding(.pixels(2))
					.background(Color("#2c2d31"))
					.cornerRadius(.circle)
			case .arrowKey:
				Style()
					.background(Color("#9fa0a5"))
					.border(Color("#555"), width: .pixels(1))
					.cornerRadius(.rootEm(0.375))
					.fontFamily(.system)
					.font(size: .rootEm(0.75))
					.color(Color("#1b1b1d"))
					.touchAction(.manipulation)
					.textSelection(.disabled)
					.handCursor()
					.active {
						$0.background(Color("#7d7e83"))
					}
					.when(.state, is: "down") {
						$0.background(Color("#7d7e83"))
					}
					.focusVisible {
						$0.focusRing(Color("#ffd23f"), width: .pixels(2), offset: .pixels(2))
					}
			case .note:
				// A yellow sticky note, a little crooked, with the numbers that make words upside down.
				Style()
					.padding(.rootEm(0.75))
					.background(Color("#fff27a"))
					.shadow(Shadow(x: .pixels(2), y: .pixels(3), color: Color("#00000040")))
					.rotationEffect(.degrees(-1.5))
					.fontFamily(GeoCitiesPage.comicSans)
					.color(Color("#222"))
			case .noteTitle:
				Style()
					.margin(top: 0, bottom: .rootEm(0.5))
					.textStyle(.caption, weight: .bold)
			case .noteButtons:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.375))
			case .noteButton:
				Style()
					.frame(minHeight: .rootEm(2.25))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.25))
					.background(Color("#fffbd0"))
					.border(Color("#c9b400"), width: .pixels(1), style: .dashed)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(Color("#222"))
					.handCursor()
					.active {
						$0.background(Color("#ffe94a"))
					}
			case .trond:
				// Trond’s TI-83, smaller, at the other end of the link cable.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#3c3d42"))
					.border(Color("#1f2023"), width: .pixels(2))
					.cornerRadius(.rootEm(0.75))
					.color(.white)
					.fontFamily(.system)
					.textStyle(.caption)
			case .cable:
				// The black link cable, with its gray plug.
				Style()
					.margin(0)
					.padding(.leading, .rootEm(0.5))
					.border(.leading, Color("#111"), width: .pixels(6))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(Color("#ddd"))
			case .trondScreen:
				// The same margin of the glass as on my screen.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.padding(.rootEm(0.25))
					.background(Color("#a9b597"))
					.border(Color("#1b1c1f"), width: .pixels(4))
					.cornerRadius(.rootEm(0.25))
					.imageRendering(.pixelated)
			case .trondButtons:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.375))
					.children("button") {
						$0
							.frame(minHeight: .rootEm(2.25))
							.textAlign(.leading)
					}
			case .door:
				// The battery door on the back, open, with the four AAA batteries and the round backup battery.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#2c2d31"))
					.border(Color("#111"), width: .pixels(2), style: .dashed)
					.cornerRadius(.rootEm(0.5))
					.color(.white)
					.fontFamily(.system)
					.textStyle(.caption)
			case .cells:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.375))
			case .cell:
				// An AAA battery: old and tired, gone, or new from Pappa’s drawer.
				Style()
					.frame(minHeight: .rootEm(2.5))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.background(Color("#8a6d3b"))
					.border(Color("#000"), width: .pixels(2))
					.cornerRadius(.rootEm(0.5))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.white)
					.handCursor()
					.when(.state, is: "old") {
						$0.background(Color("#7a5a2a"))
					}
					.when(.state, is: "out") {
						$0
							.background(Color("#1b1b1d"))
							.border(Color("#777"), width: .pixels(2), style: .dashed)
							.color(Color("#bbb"))
					}
					.when(.state, is: "new") {
						$0
							.background(Color("#d4a017"))
							.color(.black)
					}
			case .backup:
				Style()
					.frame(minHeight: .rootEm(2.5))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Color("#c0c0c8"))
					.border(Color("#555"), width: .pixels(2))
					.cornerRadius(.capsule)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.handCursor()
					.when(.state, is: "out") {
						$0
							.background(Color("#1b1b1d"))
							.border(Color("#777"), width: .pixels(2), style: .dashed)
							.color(Color("#ff8080"))
					}
			case .buttons:
				Style().margin(top: .rootEm(0.75))
			case .toggle:
				// Pressed in while it is on.
				Style()
					.frame(minHeight: .rootEm(2.75))
					.when(.state, is: "on") {
						$0
							.background(Color("#ffff99"))
							.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
			case .teacher:
				Style().when(.state, is: "on") {
					$0.background(Color("#ccffcc"))
				}
			case .batteries:
				// Orange while the batteries are low, and red when they are dead.
				Style()
					.when(.state, is: "low") {
						$0.background(Color("#ffcc66"))
					}
					.when(.state, is: "dead") {
						$0
							.background(Color("#ff6666"))
							.color(.white)
					}
			case .upsideDown:
				// What the number says upside down, big, like Trond reads it out loud.
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.extraLarge2, weight: .bold)
					.textAlign(.center)
					.color(Color("#000080"))
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			}
		}
	}
}

extension GeoCitiesCalculator {
	/**
	The calculator itself: the brand, the screen, and the keys.
	*/
	private struct Calculator: HTML {
		var body: some HTML {
			div(.part(Parts.calculator)) {
				div {
					p {
						"TI-83"
					}
					.style(Styles.brandName)

					p {
						"TEXAS INSTRUMENTS"
					}
					.style(Styles.brandMaker)
				}
				.accessibilityHidden()
				.style(Styles.brand)

				div {
					// The screen is drawn at four times 96 × 64 pixels, so each pixel of the LCD can have a gap and a shadow.
					canvas(.part(Parts.screen), .width(384), .height(256), .tabindex(0), .role("application")) {}
						.accessibilityLabel("The screen of the TI-83. Type numbers and + − * / ^ ( ), Enter to calculate, Backspace for DEL, Escape for CLEAR, the arrow keys to move, F1 to F5 for Y=, WINDOW, ZOOM, TRACE, and GRAPH, F6 for MODE, F7 for PRGM, F8 for MATH, Home for ON, letters for ALPHA, and Shift for 2nd. In the games, the arrow keys move, and Space or Enter shoots or jumps.")
						.style(Styles.screen)
				}
				.style(Styles.bezel)

				Keypad()
			}
			.style(Styles.body)
		}
	}

	/**
	The 50 keys, in the rows of the real one, with the arrow keys next to 2nd and ALPHA.
	*/
	private struct Keypad: HTML {
		var body: some HTML {
			div {
				div {
					for key in GeoCitiesCalculator.topKeys {
						KeyCell(key: key)
					}
				}
				.style(Styles.keyGrid)

				div {
					div {
						for key in GeoCitiesCalculator.upperKeys {
							KeyCell(key: key)
						}
					}
					.style(Styles.upperGrid)

					ArrowPad()
				}
				.style(Styles.upperRows)

				div {
					for key in GeoCitiesCalculator.lowerKeys {
						KeyCell(key: key)
					}
				}
				.style(Styles.keyGrid)
			}
			.style(Styles.keypad)
		}
	}

	/**
	A key, with its 2nd function and ALPHA letter above it.
	*/
	private struct KeyCell: HTML {
		let key: Key

		var body: some HTML {
			div {
				div {
					span {
						key.second
					}
					.style(Styles.secondLabel)

					span {
						key.alpha
					}
					.style(Styles.alphaLabel)
				}
				.accessibilityHidden()
				.style(Styles.keyLabels)

				button(.type(.button), .hook(Hooks.key, value: key.id)) {
					key.label
				}
				.accessibilityLabel(key.name ?? key.label)
				.style(Styles.key, kindStyle)
			}
			.style(Styles.keyCell)
		}

		private var kindStyle: Styles {
			switch key.kind {
			case .top:
				.topKey
			case .dark:
				.darkKey
			case .light:
				.lightKey
			case .second:
				.secondKey
			case .alpha:
				.alphaKey
			}
		}
	}

	/**
	The arrow keys, in a cross, with empty cells in the corners and the middle of the grid.
	*/
	private struct ArrowPad: HTML {
		private static let cells: [(id: String, symbol: String, name: String)?] = [
			nil,
			("up", "▲", "Up"),
			nil,
			("left", "◀", "Left"),
			nil,
			("right", "▶", "Right"),
			nil,
			("down", "▼", "Down"),
			nil,
		]

		var body: some HTML {
			div {
				for cell in Self.cells {
					if let cell {
						button(.type(.button), .hook(Hooks.key, value: cell.id)) {
							cell.symbol
						}
						.accessibilityLabel(cell.name)
						.style(Styles.arrowKey)
					} else {
						span {}
					}
				}
			}
			.style(Styles.arrowPad)
		}
	}

	/**
	The sticky note on the desk, with the numbers that make words upside down. A button types its number on the calculator.
	*/
	private struct StickyNote: HTML {
		var body: some HTML {
			div {
				p {
					"Type it, then Turn It Over! (from Trond)"
				}
				.style(Styles.noteTitle)

				div {
					for word in GeoCitiesCalculator.upsideDownWords {
						button(.type(.button), .hook(Hooks.number, value: word.number)) {
							"\(word.number) = \(word.word)"
						}
						.style(Styles.noteButton)
					}
				}
				.style(Styles.noteButtons)
			}
			.style(Styles.note)
		}
	}

	/**
	Trond’s TI-83 at the other end of the link cable, with its own screen and the programs he can send.
	*/
	private struct TrondCalculator: HTML {
		var body: some HTML {
			div(.part(Parts.trond)) {
				p {
					"🔌 Trond’s TI-83 (his has a crack in the screen)"
				}
				.style(Styles.cable)

				canvas(.part(Parts.trondScreen), .width(384), .height(256)) {}
					.accessibilityHidden()
					.style(Styles.trondScreen)

				button(.part(Parts.receive), .type(.button)) {
					"📥 Get My TI-83 Ready to Receive"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.noteButton)

				div {
					for program in GeoCitiesCalculator.trondPrograms {
						button(.type(.button), .hook(Hooks.send, value: program.name)) {
							"Send \(program.name)"
						}
						.help("\(program.size) bytes")
						.style(GeoCitiesPage.Styles.smallButton)
					}
				}
				.style(Styles.trondButtons)
			}
			.hidden(when: true)
			.style(Styles.trond)
		}
	}

	/**
	The open battery door, with the four AAA batteries and the round backup battery that keeps the memory.
	*/
	private struct BatteryDoor: HTML {
		var body: some HTML {
			div(.part(Parts.batteryDoor)) {
				p {
					"The battery door is open, so it is off. Pappa’s drawer has new AAA batteries. Trond’s sticker: “NEVER take out the round one!”"
				}

				div {
					for index in 0..<4 {
						button(.type(.button), .hook(Hooks.battery, value: "\(index)")) {
							"AAA"
						}
						.style(Styles.cell)
					}
				}
				.style(Styles.cells)

				button(.part(Parts.backup), .type(.button)) {
					"🪙 Backup Battery (CR1616)"
				}
				.style(Styles.backup)

				button(.part(Parts.closeDoor), .type(.button)) {
					"Close the Battery Door"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.hidden(when: true)
			.style(Styles.door)
		}
	}
}
