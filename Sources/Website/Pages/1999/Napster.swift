import Elementary
import SiteKit

/**
Napster, which came out in June 1999, and a CD burner. The visitor searches for the hits of 1999, finds files with the wrong names on modems of other kids, and downloads them over the modem, which takes all night, unless mom picks up the phone. Then the visitor burns a mix CD of the songs, and must not touch the computer while it burns, or the buffer runs empty and the CD becomes a coaster, like with the CD burners of 1999. Its script, `Napster.js`, runs both, with a clock of the night that runs much faster than a real one, and keeps the coasters in the browser.
*/
struct GeoCitiesNapster: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	Searches that the visitor can try with one click.
	*/
	private static let suggestions = ["Blue", "Barbie Girl", "a-ha", "Sandstorm", "Mambo", "Britney"]

	var content: some HTML {
		h2 {
			GeoCitiesPage.GIFImage(gif: .spinningCD, alt: "", style: .gif, project: project)
			" Free Music!!! "
			GeoCitiesPage.GIFImage(gif: .musicNotes, alt: "", style: .gif, project: project)
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"My cousin showed me Napster. You can get any song in the world for free! It only takes all night. Then I burn my own mix CD. Please do not pick up the phone while I download."
		}

		div {
			p {
				"Napster v2.0 BETA 3"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				form(.part(Parts.search)) {
					label(.for("geocities-napster-query")) {
						"Artist or title:"
					}
					.style(GeoCitiesPage.Styles.label)

					div {
						input(.id("geocities-napster-query"), .part(Parts.query), .type(.search), .autocomplete("off"), .maxlength(40), .required)
							.style(GeoCitiesPage.Styles.field, GeoCitiesPage.Styles.select)

						button(.type(.submit)) {
							"Find It!"
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
					.style(GeoCitiesPage.Styles.formRow)

					p {
						"Try: "
						for suggestion in Self.suggestions {
							button(.type(.button), .hook(Hooks.suggestion, value: suggestion)) {
								suggestion
							}
							.style(Styles.chip)
							" "
						}
					}
					.style(GeoCitiesPage.Styles.caption)
				}
				.style(GeoCitiesPage.Styles.form)

				ul(.part(Parts.results)) {}
					.accessibilityLabel("Search results")
					.style(Styles.list)

				// The script adds a copy for each file that it finds.
				template(.part(Parts.resultTemplate)) {
					li {
						div {
							strong {}
								.style(Styles.fileName)
							span {}
								.style(GeoCitiesPage.Styles.caption)
						}

						button(.type(.button)) {
							"Get"
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
					.style(Styles.result)
				}

				h3 {
					"Transfers"
				}
				.style(Styles.subheading)

				p(.part(Parts.clock)) {}
					.style(GeoCitiesPage.Styles.lcd)

				ul(.part(Parts.transfers)) {
					li {
						"Nothing yet. Find a song and press Get."
					}
					.style(GeoCitiesPage.Styles.caption)
				}
				.accessibilityLabel("Transfers")
				.style(Styles.list)

				// The script adds a copy for each download.
				template(.part(Parts.transferTemplate)) {
					li {
						strong {}
							.style(Styles.fileName)

						div {
							div {}
								.style(GeoCitiesPage.Styles.progressFill)
						}
						.accessibilityHidden()
						.style(GeoCitiesPage.Styles.progressTrack)

						span {}
							.style(GeoCitiesPage.Styles.caption)

						// Shown when the download fails, so the visitor does not have to search for the song again.
						button(.type(.button), .hidden) {
							"Try Again"
						}
						.style(GeoCitiesPage.Styles.smallButton)
					}
					.style(Styles.transfer)
				}

				p(.part(Parts.status), .role("status")) {}
					.style(Styles.status)
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window, GeoCitiesPage.Styles.scriptingOnly)

		div {
			p {
				"Easy CD Burner 3.5"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				p {
					"Pick the songs for the CD. A CD-R holds 74 minutes. My MP3s:"
				}

				ul(.part(Parts.library)) {}
					.accessibilityLabel("My MP3s")
					.style(Styles.list)

				// The script adds a copy for each song that the visitor has.
				template(.part(Parts.songTemplate)) {
					li {
						label {
							input(.type(.checkbox))
							span {}
						}
						.style(Styles.song)
					}
				}

				div {
					div(.part(Parts.capacityFill)) {}
						.style(GeoCitiesPage.Styles.progressFill)
				}
				.accessibilityHidden()
				.style(GeoCitiesPage.Styles.progressTrack)

				p(.part(Parts.capacity)) {
					"0:00 of 74:00"
				}
				.style(GeoCitiesPage.Styles.caption)

				div {
					label(.for("geocities-burner-label")) {
						"Label (I write it with a marker):"
					}
					.style(GeoCitiesPage.Styles.label)

					input(.id("geocities-burner-label"), .part(Parts.label), .type(.text), .autocomplete("off"), .maxlength(24), .value("Sindre’s Mix ’99"))
						.style(GeoCitiesPage.Styles.field)
				}

				p {
					button(.part(Parts.burn), .type(.button), .disabled) {
						"🔥 Burn CD"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(GeoCitiesPage.Styles.centeredText)

				div(.part(Parts.burner), .hidden, .tabindex(-1)) {
					p {
						strong {
							"DO NOT TOUCH THE COMPUTER WHILE IT BURNS! "
						}
						"Do not move the mouse, scroll, or type, or the buffer runs empty."
					}
					.style(Styles.warning)

					p {
						"Buffer:"
					}
					.style(GeoCitiesPage.Styles.caption)

					div {
						div(.part(Parts.buffer)) {}
							.style(Styles.bufferFill)
					}
					.accessibilityHidden()
					.style(GeoCitiesPage.Styles.progressTrack)

					p {
						"Writing at 2×:"
					}
					.style(GeoCitiesPage.Styles.caption)

					div {
						div(.part(Parts.written)) {}
							.style(GeoCitiesPage.Styles.progressFill)
					}
					.accessibilityHidden()
					.style(GeoCitiesPage.Styles.progressTrack)
				}
				.style(Styles.burner)

				p(.part(Parts.burnStatus), .role("status")) {}
					.style(Styles.status)

				div(.part(Parts.disc), .hidden, .role("img")) {
					span(.part(Parts.discLabel)) {}
				}
				.style(Styles.disc)

				p(.part(Parts.coasters)) {}
					.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.centeredText)
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Napster and the CD burner need JavaScript, and a lot of patience."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	enum Parts: String, ElementPartSet {
		case search
		case query
		case results
		case resultTemplate
		case clock
		case transfers
		case transferTemplate
		case status
		case library
		case songTemplate
		case capacity
		case capacityFill
		case label
		case burn
		case burner
		case buffer
		case written
		case burnStatus
		case disc
		case discLabel
		case coasters
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button that searches for its text.
		*/
		case suggestion = "data-napster-suggestion"
	}

	enum Styles: ElementStyleSet {
		case root
		case chip
		case list
		case result
		case fileName
		case subheading
		case transfer
		case status
		case song
		case warning
		case burner
		case bufferFill
		case disc

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .chip:
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(.white)
					.border(Color("#808080"), width: .pixels(1))
					.fontFamily(.system)
					.textStyle(.caption)
					.color(Color("#0000ee"))
					.handCursor()
			case .list:
				Style()
					.margin(0)
					.padding(0)
					.flowSpacing(.rootEm(0.375))
			case .result:
				// A file that the search found, with its button to the right.
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.padding(.rootEm(0.375))
					.background(.white)
					.border(Color("#808080"), width: .pixels(1))
					.fontFamily(.system)
					.textStyle(.caption)
					.children("div") {
						$0
							.vstack(alignment: .start)
							.frame(minWidth: 0)
					}
			case .fileName:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.overflowWrap(.anywhere)
			case .subheading:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
			case .transfer:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.padding(.rootEm(0.375))
					.background(.white)
					.border(Color("#808080"), width: .pixels(1))
					.fontFamily(.system)
					.textStyle(.caption)
					.children("button") {
						$0.alignSelf(.start)
					}
					.when(.state, is: "failed") {
						$0.background(Color("#ffdddd"))
					}
					.when(.state, is: "done") {
						$0.background(Color("#ddffdd"))
					}
			case .status:
				Style()
					.fontWeight(.bold)
					.color(Color("#800000"))
			case .song:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.fontFamily(.system)
					.textStyle(.caption)
			case .warning:
				Style()
					.padding(.rootEm(0.5))
					.background(Color("#ffff00"))
					.border(Color("#cc0000"), width: .pixels(2), style: .dashed)
					.fontFamily(.system)
					.textStyle(.caption)
			case .burner:
				Style().flowSpacing(.rootEm(0.375))
			case .bufferFill:
				// The buffer of the burner, green while it is full and red when it runs low.
				Style()
					.frame(width: .percent(100), height: .percent(100))
					.background(Color("#00aa00"))
					.when(.state, is: "low") {
						$0.background(Color("#cc0000"))
					}
			case .disc:
				// A CD-R, gold with a silver middle, and the label written on its lower half with a marker. A coaster is dull.
				Style()
					.position(.relative)
					.hstack(alignment: .end, justification: .center)
					.frame(width: .rootEm(12), height: .rootEm(12))
					.margin(.horizontal, .auto)
					.padding(.rootEm(1.5))
					.backgroundImage(.radialGradient("circle", Color("#c0c0c0"), Color("#f7efc4"), Color("#d8c060"), Color("#f4e7a1"), Color("#c9a83e"), Color("#efe0a0")))
					.border(Color("#9c8a3a"), width: .pixels(2))
					.cornerRadius(.percent(50))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
					.textAlign(.center)
					.color(Color("#1a1aa0"))
					.rotationEffect(.degrees(-8))
					.when(.state, is: "coaster") {
						$0.filter(.grayscale(0.8), .brightness(0.8))
					}
			}
		}
	}
}
