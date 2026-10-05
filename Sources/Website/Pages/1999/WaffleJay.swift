import Elementary
import SiteKit

/**
WaffleJay ’99, a music program like Dance eJay (1997): the visitor picks colored sample blocks (beats, bass, synths, voices, and effects) and puts them on six tracks of eight bars, by clicking or dragging, and plays the loop. Every sample follows the same four chords, so they always fit together. “Make Me a Hit!” fills the tracks by itself, and “Release Single!” sends the song to the Norwegian chart, where it lands on a place from how good the mix is, with a review. Its script plays through the sound card of the Music Room and keeps the mix and the best place in the browser.
*/
struct GeoCitiesWaffleJay: ScriptedElement {
	static let script = ElementScript()

	/**
	The number of tracks and bars of the arrangement.
	*/
	static let trackCount = 6
	static let barCount = 8

	/**
	The groups of samples, each with its color in the styles, and the samples, by their ID in the script, with their title and the short name in a block on a track.
	*/
	static let groups: [(id: String, title: String, samples: [(id: String, title: String, short: String)])] = [
		("beats", "Beats", [("kick", "Four on the Floor", "KICK"), ("break", "Breakbeat", "BREAK"), ("hats", "Hi-Hats", "HATS"), ("roll", "Snare Roll", "ROLL")]),
		("bass", "Bass", [("bounce", "Bouncy Bass", "BASS"), ("acid", "Acid Squelch", "ACID"), ("sub", "Sub Wobble", "WOB")]),
		("synth", "Synth", [("hoover", "Hoover", "HOOV"), ("piano", "Rave Piano", "PIANO"), ("arp", "Trance Arp", "ARP")]),
		("voice", "Voice", [("hey", "Hey!", "HEY!"), ("ooh", "Diva Ooh", "OOH"), ("robot", "Robot Waffle", "ROBOT")]),
		("fx", "FX", [("siren", "Siren", "SIREN"), ("laser", "Laser", "ZAP"), ("riser", "Riser", "RISE")]),
	]

	var content: some HTML {
		h2 {
			"WaffleJay ’99 "
			span {
				"Dance Edition"
			}
			.style(Styles.edition)
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"My cousin has Dance eJay, so I made my own. Pick a sample (you hear it), then click a spot on the tracks, or drag the sample there. Press Play. Every sample fits with every other one, so it always sounds like a hit. Almost."
		}

		div {
			p {
				"WaffleJay ’99 - untitled.mix"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				div {
					for group in Self.groups {
						div {
							h3 {
								group.title
							}
							.style(Styles.groupTitle)

							for sample in group.samples {
								button(.type(.button), .hook(Hooks.sample, value: sample.id), .hook(Hooks.group, value: group.id), .hook(Hooks.short, value: sample.short), .ariaPressed(false)) {
									sample.title
								}
								.style(Styles.sample)
							}
						}
						.style(Styles.group)
					}
				}
				.attributes(.role("group"))
				.accessibilityLabel("Samples")
				.style(Styles.palette)

				div {
					span {}
					for bar in 1...Self.barCount {
						span(.hook(Hooks.bar, value: "\(bar - 1)")) {
							"\(bar)"
						}
						.style(Styles.barNumber)
					}

					for track in 1...Self.trackCount {
						span {
							"\(track)"
						}
						.style(Styles.trackNumber)

						for bar in 1...Self.barCount {
							button(.type(.button), .hook(Hooks.cell, value: "\(track - 1)-\(bar - 1)")) {}
								.accessibilityLabel("Track \(track), bar \(bar): empty")
								.style(Styles.cell)
						}
					}
				}
				.attributes(.role("group"))
				.accessibilityLabel("Tracks")
				.style(Styles.tracks)

				div {
					button(.part(Parts.play), .type(.button)) {
						"▶ Play"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					button(.part(Parts.hit), .type(.button)) {
						"🎲 Make Me a Hit!"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					button(.part(Parts.clear), .type(.button)) {
						"Clear"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					GeoCitiesMusicVolume()
				}
				.style(GeoCitiesPage.Styles.formRow)

				p(.part(Parts.status), .role("status")) {
					"Pick a sample to start."
				}
				.style(GeoCitiesPage.Styles.caption)

				form(.part(Parts.release)) {
					label(.for("geocities-jay-title")) {
						"Song title:"
					}
					.style(GeoCitiesPage.Styles.label)

					div {
						input(.id("geocities-jay-title"), .part(Parts.songTitle), .type(.text), .autocomplete("off"), .maxlength(40), .value("Waffle Dance (Radio Edit)"), .required)
							.style(GeoCitiesPage.Styles.field, Styles.songTitle)

						button(.type(.submit)) {
							"💿 Release Single!"
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
					.style(GeoCitiesPage.Styles.formRow)
				}
				.style(GeoCitiesPage.Styles.form)

				div(.part(Parts.chart), .hidden, .role("status")) {
					p(.part(Parts.place)) {}
						.style(Styles.place)

					p(.part(Parts.review)) {}
				}
				.style(Styles.chart)

				p(.part(Parts.best)) {}
					.style(GeoCitiesPage.Styles.caption)
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window, GeoCitiesPage.Styles.scriptingOnly)

		// The script moves a copy with the pointer while the visitor drags a sample.
		template(.part(Parts.ghostTemplate)) {
			span {}
				.accessibilityHidden()
				.style(Styles.cell, Styles.ghost)
		}
	}

	enum Parts: String, ElementPartSet {
		case play
		case hit
		case clear
		case status
		case release
		case songTitle
		case chart
		case place
		case review
		case best
		case ghostTemplate
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A sample of the palette, by its ID.
		*/
		case sample = "data-jay-sample"

		/**
		The group of a sample, or of the sample on a track, for its color.
		*/
		case group = "data-jay-group"

		/**
		The short name of a sample, for its block on a track.
		*/
		case short = "data-jay-short"

		/**
		A spot on the tracks, as the track and the bar, like `0-3`.
		*/
		case cell = "data-jay-cell"

		/**
		The number above a bar, which lights up while the bar plays.
		*/
		case bar = "data-jay-bar"
	}

	enum Styles: ElementStyleSet {
		case root
		case edition
		case palette
		case group
		case groupTitle
		case sample
		case tracks
		case barNumber
		case trackNumber
		case cell
		case ghost
		case songTitle
		case chart
		case place

		/**
		The colors of the groups, like the colored blocks of Dance eJay.
		*/
		private static let colors: [(group: String, color: Color)] = [
			("beats", Color("#ff6666")),
			("bass", Color("#6699ff")),
			("synth", Color("#66dd66")),
			("voice", Color("#ffdd44")),
			("fx", Color("#cc77ff")),
		]

		private func colored(_ style: Style) -> Style {
			Self.colors.reduce(style) { style, item in
				style.when(Hooks.group, is: item.group) {
					$0.background(item.color)
				}
			}
		}

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .edition:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.textStyle(.body)
					.color(Color("#ff00cc"))
			case .palette:
				// The groups side by side, and in two columns on phones.
				Style()
					.grid(minimumColumnWidth: .rootEm(7))
					.gap(.rootEm(0.5))
			case .group:
				Style().vstack(spacing: .rootEm(0.25))
			case .groupTitle:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .sample:
				// A colored block with a raised edge, pressed in while it is the sample to put on the tracks.
				colored(
					Style()
						.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.375))
						.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
						.fontFamily(.system)
						.textStyle(.caption, weight: .bold)
						.textAlign(.leading)
						.color(.black)
						.handCursor()
						.when(.state, is: "selected") {
							$0
								.border(.black, width: .pixels(2), style: .inset)
								.underline()
						}
				)
			case .tracks:
				// The tracks as a grid: a narrow column for the numbers of the tracks, and one column for each bar.
				Style()
					.grid(columns: "1.25rem repeat(8, 1fr)")
					.gap(.pixels(2))
					.padding(.pixels(4))
					.background(Color("#202040"))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .barNumber:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
					.color(Color("#8888cc"))
					.when(.state, is: "now") {
						$0
							.background(Color("#ffff00"))
							.color(.black)
					}
			case .trackNumber:
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(minWidth: .rootEm(1))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(Color("#8888cc"))
			case .cell:
				// An empty spot is dark, and a spot with a sample has the color of its group and its short name.
				colored(
					Style()
						.frame(minWidth: 0, minHeight: .rootEm(2))
						.padding(0)
						.background(Color("#303060"))
						.border(Color("#505090"), width: .pixels(1))
						.fontFamily(GeoCitiesPage.courier)
						.font(size: .rootEm(0.625))
						.fontWeight(.bold)
						.color(.black)
						.overflow(.hidden)
						.handCursor()
						.when(.state, is: "now") {
							$0.filter(.brightness(1.4))
						}
						.when(.state, is: "target") {
							$0.border(Color("#ffff00"), width: .pixels(2))
						}
				)
			case .ghost:
				// The block that follows the pointer while the visitor drags a sample.
				Style()
					.position(.fixed)
					.top(0)
					.leading(0)
					.zIndex(1000)
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(3))
					.opacity(0.85)
					.allowsHitTesting(false)
			case .songTitle:
				// Wide enough for a title on phones, where the button goes below it.
				Style()
					.frame(width: .auto, minWidth: .rootEm(10))
					.flex(1)
			case .chart:
				// Like the chart page of a newspaper.
				Style()
					.padding(.rootEm(0.75))
					.background(Color("#fffbe6"))
					.border(.black, width: .pixels(2))
					.fontFamily(GeoCitiesPage.times)
					.flowSpacing(.rootEm(0.5))
			case .place:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge)
					.color(Color("#cc0000"))
			}
		}
	}
}
