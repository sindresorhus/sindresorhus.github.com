import Elementary
import SiteKit

/**
Make Your Own Home Page, in an editor like FrontPage Express, which came free with Internet Explorer 4: the visitor picks a background, a WordArt title, a marquee, GIFs, a MIDI, and a hit counter, and sees their own page of 1999 in a frame as they go. They can view its source, save it as an HTML file, and “publish” it to GeoCities, which uploads it over FTP, line by line, and gives it an address in a neighborhood. Its script, `PageMaker.js`, writes the page.
*/
struct GeoCitiesPageMaker: ScriptedElement {
	static let script = ElementScript()

	/**
	The ID of the page maker, which the site map links to.
	*/
	static let rootID = "geocities-page-maker"

	let project: Project

	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.id(Self.rootID)]
	}

	/**
	The GIFs that the visitor can put on their page.
	*/
	private static let gifs: [(gif: GeoCitiesPage.GIF, name: String)] = [
		(.flames, "Flames"),
		(.globe, "Globe"),
		(.underConstructionCone, "Construction"),
		(.unicornGallop, "Unicorn"),
		(.hamster, "Hamster"),
		(.dolphin, "Dolphin"),
		(.emailSpin, "E-mail"),
		(.newSpin, "New!"),
	]

	private static let backgrounds = ["Starry Night", "Clouds", "Hot Pink", "Flames", "Matrix", "Bricks"]
	private static let wordArtStyles = ["Rainbow", "Fire", "Chrome", "Slime"]
	private static let tunes = ["None", "canyon.mid", "macarena.mid", "my_heart_will_go_on.mid", "x-files.mid"]

	var content: some HTML {
		h2 {
			"Make Your Own Home Page!"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Everybody needs a home page. Make yours here, in FrontPage Express, and it is ready in 5 minutes. No HTML needed! (But you can look at it.)"
		}

		div {
			p {
				"FrontPage Express: [My Home Page]"
			}
			.style(GeoCitiesPage.Styles.titleBar)

			p {
				"File  Edit  View  Insert  Format  Tools  Table  Help"
			}
			.accessibilityHidden()
			.style(Styles.menuBar)

			div {
				form(.part(Parts.form)) {
					field("Title (in WordArt):", id: "geocities-page-maker-title") {
						input(.id("geocities-page-maker-title"), .part(Parts.title), .type(.text), .autocomplete("off"), .maxlength(40), .value("Welcome 2 My Page!!!"))
							.style(GeoCitiesPage.Styles.field)
					}

					field("WordArt style:", id: "geocities-page-maker-word-art") {
						select(.id("geocities-page-maker-word-art"), .part(Parts.wordArt)) {
							for style in Self.wordArtStyles {
								option(.value(style)) {
									style
								}
							}
						}
						.style(GeoCitiesPage.Styles.field)
					}

					field("Background:", id: "geocities-page-maker-background") {
						select(.id("geocities-page-maker-background"), .part(Parts.background)) {
							for background in Self.backgrounds {
								option(.value(background)) {
									background
								}
							}
						}
						.style(GeoCitiesPage.Styles.field)
					}

					field("About me:", id: "geocities-page-maker-about") {
						textarea(.id("geocities-page-maker-about"), .part(Parts.about), .rows(3), .maxlength(300)) {
							"Hi! I am new on the Internet. I like my cat, the Spice Girls, and my computer. Sign my guestbook!!!"
						}
						.style(GeoCitiesPage.Styles.field)
					}

					field("Marquee text:", id: "geocities-page-maker-marquee") {
						input(.id("geocities-page-maker-marquee"), .part(Parts.marquee), .type(.text), .autocomplete("off"), .maxlength(80), .value("Thanks for visiting!!! Come back soon!!!"))
							.style(GeoCitiesPage.Styles.field)
					}

					fieldset(.part(Parts.gifs)) {
						legend {
							"GIFs:"
						}
						.style(GeoCitiesPage.Styles.label)

						div {
							for (index, item) in Self.gifs.enumerated() {
								label {
									input(.type(.checkbox), .hook(Hooks.gif, value: item.gif.path.description), .hook(Hooks.still, value: stillPath(of: item.gif).description), .value(item.name))
										.attributes(.checked, when: index < 3)
									GeoCitiesPage.GIFImage(gif: item.gif, alt: "", style: .gif, project: project)
									span {
										item.name
									}
								}
								.style(Styles.gifChoice)
							}
						}
						.style(Styles.gifChoices)
					}
					.style(Styles.fieldset)

					field("Background music:", id: "geocities-page-maker-tune") {
						select(.id("geocities-page-maker-tune"), .part(Parts.tune)) {
							for tune in Self.tunes {
								option(.value(tune)) {
									tune
								}
							}
						}
						.style(GeoCitiesPage.Styles.field)
					}

					label {
						input(.part(Parts.counter), .type(.checkbox), .checked)
						" Hit counter"
					}
					.style(Styles.check)

					label {
						input(.part(Parts.construction), .type(.checkbox), .checked, .hook(Hooks.gif, value: GeoCitiesPage.GIF.underConstructionSign.path.description), .hook(Hooks.still, value: stillPath(of: .underConstructionSign).description))
						" “Under construction” sign"
					}
					.style(Styles.check)
				}
				.style(GeoCitiesPage.Styles.form)

				div {
					iframe(.part(Parts.preview), .custom(name: "sandbox", value: ""), .title("Preview of your home page")) {}
						.style(Styles.preview)

					div {
						button(.part(Parts.viewSource), .type(.button), .ariaExpanded(false)) {
							"View Source"
						}
						.style(GeoCitiesPage.Styles.retroButton)

						button(.part(Parts.save), .type(.button)) {
							"Save As…"
						}
						.style(GeoCitiesPage.Styles.retroButton)

						button(.part(Parts.publish), .type(.button)) {
							"Publish!"
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
					.style(GeoCitiesPage.Styles.row)

					textarea(.part(Parts.source), .rows(12), .readonly, .hidden) {}
						.accessibilityLabel("HTML source of your page")
						.style(GeoCitiesPage.Styles.field, Styles.source)

					pre(.part(Parts.log), .hidden) {}
						.style(Styles.log)

					p(.part(Parts.status), .role("status")) {}
						.style(GeoCitiesPage.Styles.caption)
				}
				.style(Styles.previewColumn)
			}
			.style(GeoCitiesPage.Styles.windowBody, GeoCitiesPage.Styles.columns)
		}
		.style(GeoCitiesPage.Styles.window, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"FrontPage Express needs JavaScript. Or you can write the HTML by hand in Notepad, like me."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The still frame of a GIF for visitors who prefer reduced motion, or the GIF itself when it does not move.
	*/
	private func stillPath(of gif: GeoCitiesPage.GIF) -> RoutePath {
		project.publicFile(gif.stillPath).isFile ? gif.stillPath : gif.path
	}

	private func field(_ title: String, id: String, @HTMLBuilder content: () -> some HTML) -> some HTML {
		div {
			label(.for(id)) {
				title
			}
			.style(GeoCitiesPage.Styles.label)

			content()
		}
		.style(Styles.field)
	}

	enum Parts: String, ElementPartSet {
		case form
		case title
		case wordArt
		case background
		case about
		case marquee
		case tune
		case counter
		case construction
		case gifs
		case preview
		case viewSource
		case save
		case publish
		case source
		case log
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The path of a GIF that the visitor can put on their page.
		*/
		case gif = "data-page-maker-gif"

		/**
		The path of the still frame of a GIF that the visitor can put on their page, for the preview when the visitor prefers reduced motion.
		*/
		case still = "data-page-maker-still"
	}

	enum Styles: ElementStyleSet {
		case root
		case menuBar
		case field
		case fieldset
		case gifChoices
		case gifChoice
		case check
		case previewColumn
		case preview
		case source
		case log

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .menuBar:
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.border(.bottom, Color("#808080"))
					.fontFamily(.system)
					.textStyle(.caption)
					.preservesLineBreaks()
					.overflow(.hidden)
			case .field:
				Style().frame(width: .percent(100))
			case .fieldset:
				Style()
					.frame(width: .percent(100))
					.margin(0)
					.padding(.rootEm(0.5))
					.border(Color("#808080"), width: .pixels(2), style: .groove)
			case .gifChoices:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.25))
			case .gifChoice:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption)
					.children("picture > img") {
						$0
							.frame(width: .rootEm(1.75), height: .rootEm(1.75))
							.objectFit(.contain)
					}
			case .check:
				Style()
					.fontFamily(.system)
					.textStyle(.caption)
			case .previewColumn:
				Style()
					.vstack(spacing: .rootEm(0.5))
			case .preview:
				// The frame of the preview, like the Normal view of the editor.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .rootEm(24))
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .source:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
			case .log:
				// The log of the FTP program, green on black.
				Style()
					.margin(0)
					.padding(.rootEm(0.5))
					.background(.black)
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption)
					.color(Color("#33ff66"))
					.preservesLineBreaks()
					.overflowWrap(.anywhere)
			}
		}
	}
}
