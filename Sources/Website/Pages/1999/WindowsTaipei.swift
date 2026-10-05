import Elementary
import Foundation
import SiteKit

/**
Taipei on the desktop of my computer (``GeoCitiesPage/desktop``), the mahjong solitaire of the Microsoft Entertainment Pack (Dave Norris, 1990): 144 tiles of a mahjong set, stacked in layers, and the visitor takes them off in matching pairs. A tile can be taken when no tile lies on it and its left or right side is open. Any flower matches any flower, and any season any season. The layouts are those of the Layout menu of Taipei: Standard (the turtle), Bridge, Castle, Pyramid, and Cube. Each deal is built backwards from an empty table, so it always has a solution, and its game number deals it again. The game has Undo, Hint, a shuffle when no moves are left, the Peek option that lifts a tile to see what is under it, the Watch Builds option that shows how the layout is built, a clock, and the best time of each layout. The Boss Key hides the game behind the budget of my father in Excel, in case Pappa (or Mamma) walks by. It is the content of its window of the desktop, and its script, `WindowsTaipei.js`, deals, draws the tiles on the canvas, and keeps the best times and the options in the browser.
*/
struct GeoCitiesWindowsTaipei: ScriptedElement {
	static let script = ElementScript()

	/**
	The layouts of the Layout menu, by the ID that the script knows them by.
	*/
	private static let layouts: [(id: String, name: String)] = [
		("standard", "Turtle"),
		("bridge", "Bridge"),
		("castle", "Castle"),
		("pyramid", "Pyramid"),
		("cube", "Cube"),
	]

	/**
	A row of the budget of my father for the first quarter of 1999, in kroner, with the formula of a cell where he wrote one, and his note.
	*/
	private struct BudgetRow {
		let name: String
		let values: [Int]
		var formulas: [String?] = [nil, nil, nil]
		var note = ""
	}

	private static let budget: [BudgetRow] = [
		BudgetRow(name: "Husleie", values: [6500, 6500, 6500]),
		BudgetRow(name: "Strøm", values: [1240, 1385, 1110], note: "Regn. Mye regn."),
		BudgetRow(name: "Telefon (Telenor)", values: [450, 2870, 610], formulas: [nil, "=450+2420", nil], note: "SINDRE!!! INTERNETT!!!"),
		BudgetRow(name: "Mat", values: [4200, 4050, 4300]),
		BudgetRow(name: "Brunost", values: [189, 189, 378], formulas: [nil, nil, "=189*2"], note: "Mormor på besøk"),
		BudgetRow(name: "Bensin (Volvo 240)", values: [900, 850, 980]),
		BudgetRow(name: "NRK-lisens", values: [0, 0, 1015]),
		BudgetRow(name: "Pianotimer, Lillesøster", values: [480, 480, 480]),
		BudgetRow(name: "Tamagotchi-batterier", values: [0, 45, 45], note: "Igjen?!"),
		BudgetRow(name: "Lommepenger, Sindre", values: [100, 100, 50], formulas: [nil, nil, "=100-50"], note: "Minus telefonen"),
	]

	private static let months = ["Januar", "Februar", "Mars"]
	private static let columnLetters = ["A", "B", "C", "D", "E", "F"]

	var content: some HTML {
		// The game and the spreadsheet of the Boss Key take turns in one place, so the window does not add space between them.
		div {
			div(.part(Parts.game)) {
				div {
					toolButton(.newGame, "New")
					toolButton(.undo, "Undo")
					toolButton(.hint, "Hint")
					toolButton(.shuffle, "Shuffle")

					button(.part(Parts.peek), .type(.button), .ariaPressed(false)) {
						"Peek"
					}
					.help("Press and hold a tile to see what is under it")
					.style(GeoCitiesPage.Styles.smallButton, Styles.tool)

					button(.part(Parts.watch), .type(.button), .ariaPressed(false)) {
						"Watch Builds"
					}
					.help("Shows how the layout is built at the start of a game")
					.style(GeoCitiesPage.Styles.smallButton, Styles.tool)

					button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
						"🔈 Sound"
					}
					.help("Plays sound")
					.style(GeoCitiesPage.Styles.smallButton, Styles.tool)

					label(.for("geocities-taipei-layout")) {
						"Layout"
					}
					.style(VisuallyHidden.Styles.root)

					select(.id("geocities-taipei-layout"), .part(Parts.layout)) {
						for layout in Self.layouts {
							option(.value(layout.id)) {
								layout.name
							}
						}
					}
					.style(Styles.layout)

					span {
						label(.for("geocities-taipei-number")) {
							"Game #"
						}

						input(.id("geocities-taipei-number"), .part(Parts.number), .type(.number), .min("1"), .max("99999"), .value("1"), .autocomplete("off"))
							.style(Styles.number)

						toolButton(.play, "Go")
					}
					.style(GeoCitiesWindows.Styles.wrapRow)

					button(.part(Parts.boss), .type(.button)) {
						"💼 Boss Key"
					}
					.help("Hides the game, fast, when somebody walks by")
					.style(GeoCitiesPage.Styles.smallButton, Styles.tool, Styles.bossButton)
				}
				.style(Styles.options)

				canvas(.part(Parts.screen), .width(1200), .height(780), .tabindex(0), .role("application")) {}
					.accessibilityLabel("Taipei. Pick two free tiles that match to take them off. The arrow keys move the cursor, Space or Enter picks the tile, H shows a hint, U undoes, P peeks under the tile while Peek is on, Escape lets go of the tile, and B is the boss key.")
					.style(Styles.screen)

				div {
					p(.part(Parts.status), .role("status")) {
						"Pick two free tiles that match. A tile is free when nothing lies on it, and its left or right side is open."
					}
					.style(GeoCitiesPage.Styles.statusBar, Styles.status)

					p(.part(Parts.stats)) {
						"Tiles 144 ★ Moves 0\nTime 0:00 ★ Best –"
					}
					.style(Styles.stats)
				}
				.style(Styles.bottomRow)
			}
			.style(Styles.game)

			spreadsheet
		}
		.style(GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Taipei needs JavaScript. The tiles are still in their box."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	private func toolButton(_ part: Parts, _ title: String) -> some HTML {
		button(.part(part), .type(.button)) {
			title
		}
		.style(GeoCitiesPage.Styles.smallButton, Styles.tool)
	}

	/**
	The budget of my father in Excel 97, in Norwegian, which the Boss Key shows instead of the game. A click on a cell shows its formula, like in Excel, and the tab of the sheet called Taipei brings the game back.
	*/
	private var spreadsheet: some HTML {
		div(.part(Parts.sheet), .hidden) {
			p {
				"Fil  Rediger  Vis  Sett inn  Format  Verktøy  Data  Vindu  Hjelp"
			}
			.accessibilityHidden()
			.style(Styles.excelMenu)

			p {
				"📄 📂 💾 🖨️ 🔍 ✂️ 📋 ↶ Σ 𝑓x 📊 100%"
			}
			.accessibilityHidden()
			.style(Styles.excelMenu, Styles.excelToolbar)

			div {
				span(.part(Parts.nameBox)) {
					"A1"
				}
				.style(Styles.nameBox)

				span(.part(Parts.formula)) {
					"Post"
				}
				.style(Styles.formula)
			}
			.style(Styles.formulaBar)

			div {
				table {
					caption {
						"Pappa’s budget for 1999, in kroner"
					}
					.style(VisuallyHidden.Styles.root)

					thead {
						tr {
							th {}
								.style(Styles.header)

							for letter in Self.columnLetters {
								th(.scope(.col)) {
									letter
								}
								.style(Styles.header)
							}
						}
					}

					tbody {
						for (index, row) in Self.sheetRows.enumerated() {
							tr {
								th(.scope(.row)) {
									"\(index + 1)"
								}
								.style(Styles.header)

								// Only the selected cell is in the order of the Tab key, and the arrow keys move between the cells, so Tab gets past the sheet to its tabs in one press.
								for cell in row {
									td(.tabindex(cell.name == "A1" ? 0 : -1), .hook(Hooks.cell, value: cell.name)) {
										cell.value
									}
									.attributes(.hook(Hooks.formulaText, value: cell.formula ?? ""), when: cell.formula != nil)
									.style(Styles.cell)
									.style(Styles.numberCell, when: cell.isNumber)
									.style(Styles.boldCell, when: cell.isBold)
									.style(Styles.noteCell, when: cell.isNote)
								}
							}
						}
					}
				}
				.style(Styles.grid)
			}
			.style(Styles.gridScroll)

			div(.role("group")) {
				for (tab, title) in [("ark1", "Budsjett 1999"), ("ark2", "Ark2"), ("taipei", "Taipei")] {
					button(.type(.button), .hook(Hooks.tab, value: tab)) {
						title
					}
					.attributes(.hook(.state, value: "active"), when: tab == "ark1")
					.style(Styles.tab)
				}
			}
			.accessibilityLabel("Sheets")
			.style(Styles.tabs)

			p(.part(Parts.sheetStatus), .role("status")) {
				"Klar"
			}
			.style(GeoCitiesPage.Styles.statusBar)
		}
		.style(Styles.sheet)
	}

	/**
	A cell of the spreadsheet, by its name, like B4. A cell takes the focus, like the cells of Excel, and shows its formula, or its value, in the formula bar. The arrow keys move between the cells.
	*/
	private struct SheetCell {
		let name: String
		let value: String
		var formula: String?
		var isNumber = false
		var isBold = false
		var isNote = false
	}

	/**
	The rows of the spreadsheet: the titles, a row for each post of the budget with its sum and note, and the totals.
	*/
	private static var sheetRows: [[SheetCell]] {
		let totalRow = budget.count + 2
		let titles = ["Post"] + months + ["Sum", "Merknad"]
		var rows = [titles.enumerated().map { SheetCell(name: "\(columnLetters[$0.offset])1", value: $0.element, isBold: true) }]

		for (index, post) in budget.enumerated() {
			let number = index + 2
			var row = [SheetCell(name: "A\(number)", value: post.name)]

			for (month, value) in post.values.enumerated() {
				row.append(SheetCell(name: "\(columnLetters[month + 1])\(number)", value: kroner(value), formula: post.formulas[month], isNumber: true))
			}

			row.append(SheetCell(name: "E\(number)", value: kroner(post.values.reduce(0, +)), formula: "=SUM(B\(number):D\(number))", isNumber: true))
			row.append(SheetCell(name: "F\(number)", value: post.note, isNote: true))
			rows.append(row)
		}

		var totals = [SheetCell(name: "A\(totalRow)", value: "Totalt", isBold: true)]

		for column in 1...4 {
			let letter = columnLetters[column]
			let total = column == 4 ? budget.flatMap(\.values).reduce(0, +) : budget.map { $0.values[column - 1] }.reduce(0, +)
			totals.append(SheetCell(name: "\(letter)\(totalRow)", value: kroner(total), formula: "=SUM(\(letter)2:\(letter)\(totalRow - 1))", isNumber: true, isBold: true))
		}

		totals.append(SheetCell(name: "F\(totalRow)", value: ""))
		rows.append(totals)
		return rows
	}

	/**
	An amount in kroner with a space between the thousands, like in Norway.
	*/
	private static func kroner(_ value: Int) -> String {
		let digits = String(value)
		var result = ""

		for (index, digit) in digits.enumerated() {
			if index > 0, (digits.count - index).isMultiple(of: 3) {
				result += " "
			}

			result.append(digit)
		}

		return result
	}

	enum Parts: String, ElementPartSet {
		case game
		case newGame
		case undo
		case hint
		case shuffle
		case peek
		case watch
		case sound
		case boss
		case layout
		case number
		case play
		case screen
		case stats
		case status
		case sheet
		case nameBox
		case formula
		case sheetStatus
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A cell of the spreadsheet, by its name, like B4.
		*/
		case cell = "data-taipei-cell"

		/**
		The formula of a cell of the spreadsheet, where it has one.
		*/
		case formulaText = "data-taipei-formula"

		/**
		The tab of a sheet of the spreadsheet, by its ID.
		*/
		case tab = "data-taipei-tab"
	}

	enum Styles: ElementStyleSet {
		case root
		case game
		case tool
		case bossButton
		case options
		case layout
		case number
		case screen
		case bottomRow
		case status
		case stats
		case sheet
		case excelToolbar
		case excelMenu
		case formulaBar
		case nameBox
		case formula
		case gridScroll
		case grid
		case header
		case cell
		case numberCell
		case boldCell
		case noteCell
		case tabs
		case tab

		var style: Style {
			switch self {
			case .root:
				Style().display(.block)
			case .game:
				// Close together, so the whole game fits on the desktop without a scroll bar in the window.
				Style().vstack(spacing: .rootEm(0.25))
			case .tool:
				// Big enough for a thumb on a touch screen.
				Style().media(.coarsePointer) {
					$0.frame(minHeight: .rootEm(2.5))
				}
			case .bossButton:
				Style().margin(.leading, .auto)
			case .options:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
					.fontFamily(.system)
					.textStyle(.caption)
			case .layout:
				// A drop-down list of Windows, like the Layout menu of Taipei.
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.25))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
					.media(.coarsePointer) {
						$0.frame(minHeight: .rootEm(2.5))
					}
			case .number:
				// The text field of Windows, narrow enough for a game number.
				GeoCitiesPage.Styles.field.style
					.frame(width: .rootEm(4.75))
					.padding(vertical: 0, horizontal: .rootEm(0.25))
			case .screen:
				// The table of the tiles. A tap picks a tile and a long press peeks, so a finger on it does not zoom the page or select text.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(1200.0 / 780.0)
					.background(Color("#0f4a2c"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.touchAction(.manipulation)
					.textSelection(.disabled)
					.handCursor()
			case .bottomRow:
				// The status line and the stats side by side, so the window fits on the desktop. On a phone, the stats go below.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .status:
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(12))
					.margin(0)
			case .stats:
				// The green screen of the page, small, with two short lines.
				GeoCitiesPage.Styles.lcd.style
					.margin(0)
					.padding(vertical: 0, horizontal: .rootEm(0.5))
					.textStyle(.caption)
					.monospacedDigit()
					.preservesLineBreaks()
					.textWrap(.nowrap)
			case .sheet:
				Style()
					.vstack(spacing: 0)
					.background(GeoCitiesPage.windowGray)
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
			case .excelToolbar:
				// The standard toolbar of Excel 97, under its menus.
				Style()
					.border(.top, Color("#ffffff"))
					.letterSpacing(.em(0.2))
			case .excelMenu:
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.375))
					.preservesLineBreaks()
					.overflow(.hidden)
					.textWrap(.nowrap)
			case .formulaBar:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.padding(.rootEm(0.125))
			case .nameBox:
				Style()
					.frame(minWidth: .rootEm(3))
					.padding(.horizontal, .rootEm(0.25))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .formula:
				Style()
					.flex(1)
					.frame(minWidth: 0)
					.padding(.horizontal, .rootEm(0.25))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.overflow(.hidden)
					.textWrap(.nowrap)
			case .gridScroll:
				// The sheet scrolls sideways on a phone, like a real one that is too wide for the screen, and down, so the window fits on the desktop.
				Style()
					.overflow(.auto)
					.frame(maxHeight: .rootEm(16.5))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.background(.white)
			case .grid:
				Style()
					.frame(minWidth: .percent(100))
					.background(Color("#c8c8c8"))
					.textAlign(.leading)
			case .header:
				Style()
					.padding(.horizontal, .rootEm(0.25))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(1), style: .outset)
					.fontWeight(.regular)
					.textAlign(.center)
			case .cell:
				// The cell with the focus has the thick black frame of Excel.
				Style()
					.padding(.horizontal, .rootEm(0.25))
					.background(.white)
					.border(.white, width: .pixels(2))
					.textWrap(.nowrap)
					.when(.state, is: "selected") {
						$0.border(.black, width: .pixels(2))
					}
			case .numberCell:
				Style()
					.textAlign(.trailing)
					.monospacedDigit()
			case .boldCell:
				Style().fontWeight(.bold)
			case .noteCell:
				Style()
					.color(Color("#cc0000"))
					.fontWeight(.bold)
			case .tabs:
				Style()
					.hstack(alignment: .start, spacing: 0)
					.padding(.horizontal, .rootEm(0.375))
			case .tab:
				// The tabs of the sheets hang below the sheet, and the open one is white.
				Style()
					.frame(minHeight: .rootEm(2))
					.padding(.horizontal, .rootEm(0.625))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#808080"), width: .pixels(1))
					.fontFamily(.system)
					.textStyle(.caption)
					.color(.black)
					.handCursor()
					.when(.state, is: "active") {
						$0
							.background(.white)
							.fontWeight(.bold)
					}
			}
		}
	}
}
