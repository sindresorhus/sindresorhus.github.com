import Elementary
import SiteKit

/**
WaffleTracker 2, a music tracker like FastTracker 2 (1994) and ModPlug Tracker, which the demo scene and kids with a PC used to make music in 1999: a pattern of 32 rows and four channels, where each row of a channel can have a note and an instrument. The visitor types notes with the keys of the computer like in FastTracker (Z to M and Q to U are two octaves), or taps the notes below, moves with the arrow keys, mutes channels, loads two modules, and saves the song as a MIDI file. Its script plays it through the sound card of the Music Room, with a bar that runs down the pattern, and keeps the pattern in the browser.
*/
struct GeoCitiesTracker: ScriptedElement {
	static let script = ElementScript()

	/**
	The number of rows and channels of the pattern.
	*/
	static let rowCount = 32
	static let channelCount = 4

	/**
	The instruments, by their number, which the script plays.
	*/
	static let instruments = ["Kick", "Snare", "HiHat", "Bass", "Lead", "Pad"]

	/**
	The modules that the visitor can load, by their ID in the script.
	*/
	static let modules: [(id: String, file: String)] = [
		("brunost", "brunost.xm"),
		("hamster", "hampster.mod"),
	]

	var content: some HTML {
		h2 {
			"WaffleTracker 2"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"Real musicians use a tracker, like FastTracker 2. The notes go down, not across! Click the pattern, then type notes with the keys of your computer: Z to M is one octave, Q to U the next. Arrow keys move, Delete erases, and Space plays. Or tap a spot and the notes below. Load a module to see how the pros do it."
		}

		div {
			p(.part(Parts.title)) {
				"WaffleTracker 2.08 - untitled.xm"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				div {
					button(.part(Parts.play), .type(.button)) {
						"▶ Play"
					}
					.style(Styles.button)

					for module in Self.modules {
						button(.type(.button), .hook(Hooks.module, value: module.id)) {
							"Load \(module.file)"
						}
						.style(Styles.button)
					}

					button(.part(Parts.clear), .type(.button)) {
						"New"
					}
					.style(Styles.button)

					button(.part(Parts.midi), .type(.button)) {
						"Save as MIDI"
					}
					.style(Styles.button)
				}
				.style(Styles.toolbar)

				div {
					p {
						"BPM 125 · Spd 6 · Octave "
						span(.part(Parts.octave)) {
							"4"
						}
					}
					.style(Styles.info)

					div {
						for (index, instrument) in Self.instruments.enumerated() {
							button(.type(.button), .hook(Hooks.instrument, value: "\(index + 1)"), .ariaPressed(index == 0)) {
								"0\(index + 1) \(instrument)"
							}
							.attributes(.hook(.state, value: "on"), when: index == 0)
							.style(Styles.instrument)
						}
					}
					.attributes(.role("group"))
					.accessibilityLabel("Instruments")
					.style(Styles.instruments)
				}
				.style(Styles.panel)

				div {
					span {}

					for channel in 1...Self.channelCount {
						button(.type(.button), .hook(Hooks.mute, value: "\(channel - 1)"), .ariaPressed(false)) {
							"Ch \(channel)"
							span(.hook(Hooks.meter, value: "\(channel - 1)")) {}
								.accessibilityHidden()
								.style(Styles.meter)
						}
						.accessibilityLabel("Mute channel \(channel)")
						.style(Styles.channel)
					}
				}
				.style(Styles.row, Styles.header)

				div(.part(Parts.pattern), .tabindex(0), .role("application")) {
					for row in 0..<Self.rowCount {
						div(.hook(Hooks.row, value: "\(row)")) {
							span {
								hex(row)
							}
							.style(Styles.rowNumber)

							for channel in 0..<Self.channelCount {
								span(.hook(Hooks.cell, value: "\(row)-\(channel)")) {
									"--- --"
								}
								.style(Styles.cell)
							}
						}
						.style(Styles.row, row.isMultiple(of: 4) ? Styles.beatRow : Styles.plainRow)
					}
				}
				.accessibilityLabel("Pattern. Type notes with Z to M and Q to U, move with the arrow keys, Delete erases, Space plays.")
				.style(Styles.pattern)

				div {
					for (index, name) in ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"].enumerated() {
						button(.type(.button), .hook(Hooks.note, value: "\(index)")) {
							name
						}
						.style(Styles.noteButton)
					}

					button(.type(.button), .hook(Hooks.note, value: "delete")) {
						"Del"
					}
					.style(Styles.noteButton)

					button(.type(.button), .hook(Hooks.note, value: "down")) {
						"Oct −"
					}
					.style(Styles.noteButton)

					button(.type(.button), .hook(Hooks.note, value: "up")) {
						"Oct +"
					}
					.style(Styles.noteButton)
				}
				.attributes(.role("group"))
				.accessibilityLabel("Notes")
				.style(Styles.notes)

				div {
					GeoCitiesMusicVolume()
				}
				.style(Styles.volume)

				p(.part(Parts.status), .role("status")) {}
					.style(Styles.status)
			}
			.style(Styles.body)
		}
		.style(GeoCitiesPage.Styles.window, GeoCitiesPage.Styles.scriptingOnly)
	}

	private func hex(_ number: Int) -> String {
		let digits = String(number, radix: 16, uppercase: true)
		return digits.count < 2 ? "0\(digits)" : digits
	}

	enum Parts: String, ElementPartSet {
		case title
		case play
		case clear
		case midi
		case octave
		case pattern
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button that loads a module, by its ID.
		*/
		case module = "data-tracker-module"

		/**
		A button of an instrument, by its number.
		*/
		case instrument = "data-tracker-instrument"

		/**
		A button that mutes a channel, by its index.
		*/
		case mute = "data-tracker-mute"

		/**
		The meter of a channel, by its index, which lights up when the channel plays a note.
		*/
		case meter = "data-tracker-meter"

		/**
		A row of the pattern, by its index.
		*/
		case row = "data-tracker-row"

		/**
		A spot of the pattern, as the row and the channel, like `4-2`.
		*/
		case cell = "data-tracker-cell"

		/**
		A button that enters a note (by its index from C) at the cursor, or `delete`, `up`, or `down` for the octave.
		*/
		case note = "data-tracker-note"
	}

	enum Styles: ElementStyleSet {
		case root
		case body
		case toolbar
		case button
		case panel
		case info
		case instruments
		case instrument
		case header
		case row
		case beatRow
		case plainRow
		case channel
		case meter
		case pattern
		case rowNumber
		case cell
		case notes
		case noteButton
		case volume
		case status

		/**
		The colors of FastTracker 2: a blue-gray panel with light edges, and the pattern in black.
		*/
		private static let panelColor = Color("#49577a")
		private static let lightColor = Color("#9aaacd")
		private static let darkColor = Color("#262f44")

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .body:
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.5))
					.background(Self.panelColor)
					.color(.white)
			case .toolbar:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .button:
				// The flat buttons of FastTracker 2, with light and dark edges.
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Self.panelColor)
					.border(Self.lightColor, width: .pixels(2), style: .outset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(.white)
					.handCursor()
					.active {
						$0.border(Self.lightColor, width: .pixels(2), style: .inset)
					}
			case .panel:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .info:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
			case .instruments:
				Style()
					.hstack(spacing: .rootEm(0.25))
					.flexWrap()
			case .instrument:
				Style()
					.padding(vertical: 0, horizontal: .rootEm(0.375))
					.background(Self.darkColor)
					.border(Self.lightColor, width: .pixels(1))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
					.color(Color("#ffff88"))
					.handCursor()
					.when(.state, is: "on") {
						$0
							.background(Color("#ffff88"))
							.color(.black)
					}
			case .row:
				// The number of the row, and one column for each channel.
				Style()
					.grid(columns: "2.5ch repeat(4, 1fr)")
					.gap(.rootEm(0.25))
					.padding(.horizontal, .rootEm(0.25))
					.when(.state, is: "now") {
						$0.background(Color("#3a4f8f"))
					}
			case .beatRow:
				Style().color(Color("#ffffaa"))
			case .plainRow:
				Style().color(Color("#d0d8f0"))
			case .header:
				Style().padding(.bottom, .rootEm(0.125))
			case .channel:
				// A channel that is muted is crossed out.
				Style()
					.vstack(spacing: .pixels(2))
					.padding(.pixels(2))
					.background(Self.panelColor)
					.border(Self.lightColor, width: .pixels(1), style: .outset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(.white)
					.handCursor()
					.when(.state, is: "muted") {
						$0
							.color(Color("#ff8888"))
							.underline()
					}
			case .meter:
				// A meter that lights up for a moment with each note.
				Style()
					.frame(height: .pixels(4))
					.background(Self.darkColor)
					.transition(.background, animation: .easeOut(duration: .milliseconds(200)))
					.when(.state, is: "hit") {
						$0
							.background(Color("#33ff66"))
							.noTransition()
					}
			case .pattern:
				// Black, with about 16 rows on the screen at a time. It scrolls inside, so the page does not move while a song plays. The rows are placed from it, so the script can scroll to them.
				Style()
					.position(.relative)
					.frame(height: .rootEm(19))
					.padding(.vertical, .rootEm(0.25))
					.background(.black)
					.border(Self.darkColor, width: .pixels(2), style: .inset)
					.fontFamily(GeoCitiesPage.courier)
					.font(size: .rootEm(0.8125), lineHeight: 1.4)
					.fontWeight(.bold)
					.overflow(.auto)
					.focusVisible {
						$0.focusRing(Color("#ffff88"), width: .pixels(2), offset: .pixels(2))
					}
			case .rowNumber:
				Style().color(Color("#8899cc"))
			case .cell:
				// The cursor is a box around the spot, which shows while the pattern has the focus, or after a tap.
				Style()
					.padding(.horizontal, .pixels(2))
					.textWrap(.nowrap)
					.handCursor()
					.when(.state, is: "cursor") {
						$0
							.background(Color("#cccccc"))
							.color(.black)
					}
			case .notes:
				Style()
					.grid(minimumColumnWidth: .rootEm(2.75))
					.gap(.rootEm(0.25))
			case .noteButton:
				Style()
					.padding(vertical: .rootEm(0.25), horizontal: 0)
					.background(Self.darkColor)
					.border(Self.lightColor, width: .pixels(1), style: .outset)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(.white)
					.handCursor()
					.active {
						$0.border(Self.lightColor, width: .pixels(1), style: .inset)
					}
			case .volume:
				Style().hstack(alignment: .center, justification: .end)
			case .status:
				Style()
					.frame(minHeight: .lineHeight(1))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
					.color(Color("#ffff88"))
			}
		}
	}
}
