import Elementary
import Foundation
import SiteKit

/**
Lillesøster’s Dollz corner, on my page because she is six and has no page of her own. Dollz were the little pixel dress-up dolls of GeoCities and Angelfire from 1998 to 2002, drawn pixel by pixel in MS Paint at 800% zoom, and every girl with a home page had a “Dollz Maker” and a sign that said “DoN’T StEaL mY dOlLz!!!”. Here the doll is real pixel art on a canvas at 1x, scaled up with crisp pixels, in the true style of dollz: tall and thin, a big head, black outlines on every piece, highlights and shadows, and the 3/4 pose with one hand on the hip. The visitor builds a doll in the Dollz Maker 2.0 with tabs, like the real makers: a girl or a guy base in a polka-dot swimsuit, in six skin tones; eyes with lashes and an eye color; a mouth, blush, freckles, or face gems; eight hair styles, among them pigtails, space buns, the curls of Scary Spice, the ponytail of Sporty Spice, curtains like a boy band, and spiky guy hair with frosted tips; tops like a baby tee, a tube top, a Norwegian lusekofte sweater, and a Backstreet Boys jersey; flared jeans, the plaid skirt of Britney, cargo pants, track pants, and overalls with one strap down; the Union Jack dress of Ginger Spice, a bunad for the 17th of May, a slip dress, a yellow raincoat for Bergen, and a shiny puffer jacket; Spice Girls platforms, rain boots, skate shoes, and Mary Janes; and extras to stack, like tiny sunglasses, butterfly clips, a tattoo choker, angel wings, a glitter halo, a Furby, a Tamagotchi, a Discman with headphones, a skateboard, a Norwegian flag, and Rocky the pet rock. Seven backgrounds go behind her: none (see-through), a rainbow, stars, Bryggen, a tiled GeoCities background, hearts, and rain in Bergen. The recolor tool swaps the palette of the last piece with a color of the 28 colors of MS Paint, so the hair can be green and the skin can be alien. A glitter filter makes the clothes sparkle, the doll blinks, and the stamp “DoN’T StEaL!!!” and the name of the maker are written on the picture in alternating caps, like the doll’s own name. Undo, Random, and Start Over help, Lillesøster says what she thinks of each choice, and a right click on the doll is “disabled”, like on the real pages. The Dollz House keeps the saved dolls in the browser, next to three dolls that Lillesøster made herself (one of them is me, and ugly), and a doll is saved as a PNG at the real size or big. Adopt a Doll makes a random doll for the visitor, once the visitor agrees to Lillesøster’s rules in sparkly text, with a funny adoption certificate to save and the HTML code to link back. Its script, `Dollz.js`, draws and runs it. For visitors who prefer reduced motion, the glitter is a still frame that changes with each change, and the doll does not blink. Without scripts, the corner is left out, as the dolls are drawn by the script.
*/
struct GeoCitiesDollz: ScriptedElement {
	static let script = ElementScript()

	/**
	A choice in the maker, like a hair style.
	*/
	fileprivate struct Item {
		let id: String
		let name: String
	}

	/**
	The choices for one piece of the doll, like the hair, in a box of a tab.
	*/
	fileprivate struct Group {
		let slot: String
		let title: String
		let items: [Item]
	}

	/**
	A tab of the maker, with its boxes of choices.
	*/
	fileprivate struct Tab {
		let id: String
		let name: String
		let groups: [Group]
	}

	fileprivate static let tabs: [Tab] = [
		Tab(id: "base", name: "👤 Base", groups: [
			Group(slot: "body", title: "Dollz base:", items: [
				Item(id: "girl", name: "👧 Girl Dollz"),
				Item(id: "guy", name: "👦 Guy Dollz"),
			]),
			Group(slot: "skin", title: "Skin:", items: [
				Item(id: "porcelain", name: "Porcelain"),
				Item(id: "peach", name: "Peach"),
				Item(id: "tan", name: "Tan"),
				Item(id: "golden", name: "Golden"),
				Item(id: "brown", name: "Brown"),
				Item(id: "deep", name: "Deep Brown"),
			]),
		]),
		Tab(id: "face", name: "👀 Face", groups: [
			Group(slot: "eyes", title: "Eyes:", items: [
				Item(id: "sparkly", name: "✨ Sparkly"),
				Item(id: "lashes", name: "Long Lashes"),
				Item(id: "anime", name: "🌸 Anime"),
				Item(id: "sleepy", name: "😴 Sleepy"),
				Item(id: "wink", name: "😉 Wink"),
				Item(id: "cool", name: "😎 Cool (Guy)"),
			]),
			Group(slot: "mouth", title: "Mouth:", items: [
				Item(id: "smile", name: "🙂 Smile"),
				Item(id: "gloss", name: "💋 Lip Gloss"),
				Item(id: "grin", name: "😁 Grin"),
				Item(id: "tongue", name: "😛 :P"),
				Item(id: "surprised", name: "😮 Oh!"),
			]),
			Group(slot: "cheeks", title: "Cheeks:", items: [
				Item(id: "none", name: "Nothing"),
				Item(id: "blush", name: "🌸 Blush"),
				Item(id: "freckles", name: "Freckles"),
				Item(id: "gems", name: "💎 Face Gems"),
			]),
		]),
		Tab(id: "hair", name: "💇 Hair", groups: [
			Group(slot: "hair", title: "Hair:", items: [
				Item(id: "long", name: "Long & Straight"),
				Item(id: "pigtails", name: "Pigtails"),
				Item(id: "buns", name: "Space Buns"),
				Item(id: "bob", name: "Bob"),
				Item(id: "curly", name: "Big Curls (Scary Spice)"),
				Item(id: "ponytail", name: "High Ponytail (Sporty Spice)"),
				Item(id: "spiky", name: "Spiky + Frosted Tips (Guy)"),
				Item(id: "curtains", name: "Curtains (Boy Band)"),
				Item(id: "none", name: "No Hair"),
			]),
		]),
		Tab(id: "top", name: "👚 Tops", groups: [
			Group(slot: "top", title: "Tops:", items: [
				Item(id: "none", name: "None"),
				Item(id: "tank", name: "Tank Top"),
				Item(id: "babytee", name: "Baby Tee ★"),
				Item(id: "tube", name: "Tube Top"),
				Item(id: "girlpower", name: "“Girl Power” Tee"),
				Item(id: "lusekofte", name: "Lusekofte Sweater"),
				Item(id: "jersey", name: "Backstreet Boys Jersey"),
			]),
		]),
		Tab(id: "bottom", name: "👖 Bottoms", groups: [
			Group(slot: "bottom", title: "Bottoms:", items: [
				Item(id: "none", name: "None"),
				Item(id: "flares", name: "Flared Jeans"),
				Item(id: "plaid", name: "Plaid Skirt (like Britney)"),
				Item(id: "shorts", name: "Jean Shorts"),
				Item(id: "cargo", name: "Cargo Pants"),
				Item(id: "trackpants", name: "Track Pants (Sporty)"),
				Item(id: "overalls", name: "Overalls, One Strap Down"),
			]),
		]),
		Tab(id: "dress", name: "👗 Dresses & Coats", groups: [
			Group(slot: "dress", title: "Dresses:", items: [
				Item(id: "none", name: "No Dress"),
				Item(id: "unionjack", name: "Union Jack Dress (Ginger Spice)"),
				Item(id: "bunad", name: "🇳🇴 Bunad for the 17th of May"),
				Item(id: "slip", name: "Slip Dress"),
			]),
			Group(slot: "coat", title: "Over it:", items: [
				Item(id: "none", name: "No Coat"),
				Item(id: "raincoat", name: "☔ Raincoat for Bergen"),
				Item(id: "puffer", name: "Shiny Puffer Jacket"),
			]),
		]),
		Tab(id: "shoes", name: "👟 Shoes", groups: [
			Group(slot: "shoes", title: "Shoes:", items: [
				Item(id: "none", name: "Barefoot"),
				Item(id: "platforms", name: "Spice Girls Platforms"),
				Item(id: "boots", name: "Rain Boots (Gummistøvler)"),
				Item(id: "skate", name: "Skate Shoes"),
				Item(id: "maryjanes", name: "Mary Janes + Socks"),
			]),
		]),
		Tab(id: "extras", name: "🦋 Extras", groups: [
			Group(slot: "extras", title: "Extras (take as many as you want):", items: [
				Item(id: "sunglasses", name: "🕶 Tiny Sunglasses"),
				Item(id: "clips", name: "🦋 Butterfly Clips"),
				Item(id: "choker", name: "Tattoo Choker"),
				Item(id: "wings", name: "👼 Angel Wings"),
				Item(id: "halo", name: "😇 Glitter Halo"),
				Item(id: "furby", name: "Furby"),
				Item(id: "tamagotchi", name: "🥚 Tamagotchi"),
				Item(id: "discman", name: "💿 Discman"),
				Item(id: "skateboard", name: "🛹 Skateboard"),
				Item(id: "flag", name: "🇳🇴 Flag"),
				Item(id: "rocky", name: "🪨 Rocky the Pet Rock"),
			]),
		]),
		Tab(id: "background", name: "🌈 Backgrounds", groups: [
			Group(slot: "background", title: "Background:", items: [
				Item(id: "none", name: "None (See-Through)"),
				Item(id: "rainbow", name: "🌈 Rainbow"),
				Item(id: "stars", name: "⭐ Stars"),
				Item(id: "bryggen", name: "🏠 Bryggen"),
				Item(id: "tiles", name: "GeoCities Tiles"),
				Item(id: "hearts", name: "💕 Hearts"),
				Item(id: "rain", name: "☔ Rain in Bergen"),
			]),
		]),
	]

	/**
	The 28 colors of the palette of MS Paint, in its order, top row first.
	*/
	fileprivate static let paintColors: [(hex: String, name: String)] = [
		("#000000", "Black"),
		("#808080", "Gray"),
		("#800000", "Dark red"),
		("#808000", "Olive"),
		("#008000", "Green"),
		("#008080", "Teal"),
		("#000080", "Navy"),
		("#800080", "Purple"),
		("#808040", "Khaki"),
		("#004040", "Dark teal"),
		("#0080ff", "Sky blue"),
		("#004080", "Dark blue"),
		("#8000ff", "Violet"),
		("#804000", "Brown"),
		("#ffffff", "White"),
		("#c0c0c0", "Silver"),
		("#ff0000", "Red"),
		("#ffff00", "Yellow"),
		("#00ff00", "Lime"),
		("#00ffff", "Cyan"),
		("#0000ff", "Blue"),
		("#ff00ff", "Magenta"),
		("#ffff80", "Light yellow"),
		("#00ff80", "Mint"),
		("#80ffff", "Light cyan"),
		("#8080ff", "Periwinkle"),
		("#ff0080", "Hot pink"),
		("#ff8040", "Orange"),
	]

	fileprivate static let rules = [
		"LiNk BaCk To My PaGe!!!",
		"No StEaLiNg!!! I wIlL kNoW.",
		"Do NoT sAy YoU mAdE hEr.",
		"GiVe HeR a GoOd HoMe (aNd WaFfLeS).",
		"No BoYs. ExCePt GuY dOlLz.",
		"If YoU bReAk ThE rUlEs, I tElL mAmMa.",
	]

	/**
	The color of a swatch of the recolor tool, which the script sets from its `data-dollz-color`.
	*/
	static let swatchColor = StyleVariable<Color>("--dollz-swatch")

	var content: some HTML {
		h2 {
			"~*~ LiLlEsØsTeR’s DoLlZ ~*~"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText, Styles.title)

		p {
			"My little sister (Lillesøster) is six, and Mamma says she is too small for her own home page, so she has this corner of mine. She makes dollz in MS Paint, pixel by pixel, at 800% zoom, and she gets very angry when I say they all look the same. Make one, but DoN’T StEaL!!!"
		}

		div {
			Maker()

			Gallery()

			Adoption()
		}
		.style(GeoCitiesPage.Styles.scriptingOnly, Styles.corner)

		p {
			"The dollz need JavaScript. And MS Paint."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The window of the Dollz Maker: the doll on the left and the tabs on the right.
	*/
	private struct Maker: HTML {
		var body: some HTML {
			section {
				h3 {
					"Dollz Maker 2.0 by LiLlEsØsTeR (bEsT vIeWeD aT 800%)"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					Stage()

					Controls()
				}
				.style(GeoCitiesPage.Styles.windowBody, Styles.maker)
			}
			.style(GeoCitiesPage.Styles.window)
		}
	}

	/**
	The doll with what Lillesøster says, and the buttons under it.
	*/
	private struct Stage: HTML {
		var body: some HTML {
			div {
				div {
					canvas(.part(Parts.canvas), .width(128), .height(200), .tabindex(0), .role("application")) {}
						.accessibilityLabel("The doll. The left and right arrow keys change the tab, the up and down arrow keys change the piece of the tab, R makes a random doll, G turns the glitter on or off, and Z undoes.")
						.style(Styles.canvas)

					p(.part(Parts.status), .role("status")) {
						"Click a tab, then click the clothes to dress her up! Or try 🎲 Random."
					}
					.style(Styles.status)
				}
				.style(Styles.figure)

				div {
					button(.part(Parts.random), .type(.button)) {
						"🎲 Random"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigButton, Styles.belowDoll)

					button(.part(Parts.undo), .type(.button), .disabled) {
						"↶ Undo"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigButton, Styles.dimmedWhenDisabled, Styles.belowDoll)

					button(.part(Parts.reset), .type(.button)) {
						"🧹 Start Over"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigButton, Styles.belowDoll)
				}
				.style(GeoCitiesPage.Styles.buttonRow)

				div {
					button(.part(Parts.house), .type(.button)) {
						"🏠 Put in the Dollz House"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigButton, Styles.belowDoll)

					button(.part(Parts.png), .type(.button)) {
						"💾 Save PNG (Real Size)"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigButton, Styles.belowDoll)

					button(.part(Parts.bigPNG), .type(.button)) {
						"💾 Save PNG (Big)"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigButton, Styles.belowDoll)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.style(Styles.stage)
		}
	}

	/**
	The tabs, the recolor tool, the names, and the filters.
	*/
	private struct Controls: HTML {
		var body: some HTML {
			div {
				div {
					for tab in GeoCitiesDollz.tabs {
						button(.type(.button), .hook(Hooks.tab, value: tab.id), .ariaPressed(tab.id == "base")) {
							tab.name
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.tab, Styles.belowDoll)
					}
				}
				.style(Styles.tabs)

				for tab in GeoCitiesDollz.tabs {
					Panel(tab: tab)
				}

				Recolor()

				Options()
			}
			.style(Styles.controls)
		}
	}

	private struct Panel: HTML {
		let tab: Tab

		var body: some HTML {
			div(.hook(Hooks.panel, value: tab.id)) {
				for group in tab.groups {
					GroupBox(group: group)
				}
			}
			.hidden(when: tab.id != "base")
			.style(Styles.panel)
		}
	}

	private struct GroupBox: HTML {
		let group: Group

		var body: some HTML {
			fieldset {
				legend {
					group.title
				}
				.style(Styles.legend)

				div {
					for item in group.items {
						button(.type(.button), .hook(Hooks.slot, value: group.slot), .hook(Hooks.item, value: item.id), .ariaPressed(false)) {
							item.name
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.choice, Styles.belowDoll)
					}
				}
				.style(Styles.choices)
			}
			.style(Styles.fieldset)
		}
	}

	/**
	The paint bucket of MS Paint, for the last piece the visitor picked.
	*/
	private struct Recolor: HTML {
		var body: some HTML {
			fieldset {
				legend {
					"🪣 Recolor the "
					span(.part(Parts.recolorTarget)) {
						"skin"
					}
					":"
				}
				.style(Styles.legend)

				div {
					for color in GeoCitiesDollz.paintColors {
						button(.type(.button), .hook(Hooks.color, value: color.hex)) {}
							.accessibilityLabel(color.name)
							.help(color.name)
							.style(Styles.swatch, Styles.belowDoll)
					}
				}
				.style(Styles.palette)

				button(.part(Parts.originalColor), .type(.button)) {
					"↺ Original Color"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.choice, Styles.belowDoll)
			}
			.style(Styles.fieldset)
		}
	}

	/**
	The name of the doll, the name of the maker, the stamp, and the filters.
	*/
	private struct Options: HTML {
		var body: some HTML {
			div {
				div {
					label {
						// The script makes it “His name:” for a guy dollz.
						span(.part(Parts.nameLabel)) {
							"Her name:"
						}

						input(.part(Parts.name), .type(.text), .maxlength(14), .autocomplete("off"), .placeholder("Sparkle"))
							.style(GeoCitiesPage.Styles.field, Styles.belowDoll)
					}
					.style(Styles.fieldLabel)

					label {
						"Made by (you):"
						input(.part(Parts.maker), .type(.text), .maxlength(14), .autocomplete("off"), .placeholder("Your name"))
							.style(GeoCitiesPage.Styles.field, Styles.belowDoll)
					}
					.style(Styles.fieldLabel)
				}
				.style(Styles.fields)

				div {
					button(.part(Parts.glitter), .type(.button), .ariaPressed(false)) {
						"✨ Glitter Filter"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.choice, Styles.belowDoll)

					button(.part(Parts.stamp), .type(.button), .ariaPressed(true)) {
						"🔖 “DoN’T StEaL!!!” Stamp"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.choice, Styles.belowDoll)

					button(.part(Parts.blink), .type(.button), .ariaPressed(true)) {
						"😉 Blinking"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.choice, Styles.belowDoll)
				}
				.style(Styles.choices)
			}
			.style(Styles.options)
		}
	}

	/**
	The saved dolls, which the script draws.
	*/
	private struct Gallery: HTML {
		var body: some HTML {
			section {
				h3 {
					"🏠 ThE dOlLz HoUsE"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					p {
						"The dolls live here (in your browser). Click one to dress her again. The first three are Lillesøster’s own, so they cannot move out."
					}
					.style(GeoCitiesPage.Styles.caption)

					ul(.part(Parts.gallery)) {}
						.accessibilityLabel("The dolls in the Dollz House")
						.style(Styles.gallery)
				}
				.style(GeoCitiesPage.Styles.windowBody)
			}
			.style(GeoCitiesPage.Styles.window)
		}
	}

	/**
	Adopt a Doll, with the rules, the certificate, and the code to link back.
	*/
	private struct Adoption: HTML {
		var body: some HTML {
			section {
				h3 {
					"💕 AdOpT a DoLl 💕"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					p {
						"Lillesøster has many dolls who need a home. Read her rules first!!!"
					}

					ol {
						for rule in GeoCitiesDollz.rules {
							li {
								"✨ \(rule) ✨"
							}
						}
					}
					.style(Styles.rules)

					label {
						input(.part(Parts.agree), .type(.checkbox))
						" I promise to follow ALL the rules!!! (pinky promise)"
					}
					.style(Styles.agree)

					div {
						button(.part(Parts.adopt), .type(.button)) {
							"💕 Adopt a Doll!"
						}
						.style(GeoCitiesPage.Styles.retroButton, Styles.bigButton)
					}
					.style(GeoCitiesPage.Styles.buttonRow)

					Certificate()
				}
				.style(GeoCitiesPage.Styles.windowBody)
			}
			.style(GeoCitiesPage.Styles.window)
		}
	}

	private struct Certificate: HTML {
		var body: some HTML {
			div(.part(Parts.certificateBox)) {
				canvas(.part(Parts.certificate), .width(288), .height(208)) {}
					.accessibilityLabel("The adoption certificate")
					.style(Styles.certificate)

				div {
					button(.part(Parts.saveCertificate), .type(.button)) {
						"💾 Save the Certificate"
					}
					.style(GeoCitiesPage.Styles.smallButton, Styles.bigButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)

				label(.for("geocities-dollz-link-code")) {
					"Put this on your page to link back (rule number 1!!!):"
				}
				.style(GeoCitiesPage.Styles.label)

				textarea(.id("geocities-dollz-link-code"), .part(Parts.linkCode), .rows(3), .readonly) {}
					.style(GeoCitiesPage.Styles.field, GeoCitiesPage.Styles.code)
			}
			.hidden(when: true)
			.style(Styles.certificateBox)
		}
	}

	enum Parts: String, ElementPartSet {
		case canvas
		case status
		case random
		case undo
		case reset
		case house
		case png
		case bigPNG
		case recolorTarget
		case originalColor
		case name
		case nameLabel
		case maker
		case glitter
		case stamp
		case blink
		case gallery
		case agree
		case adopt
		case certificateBox
		case certificate
		case saveCertificate
		case linkCode
	}

	enum Hooks: String, ScriptHookSet {
		case tab = "data-dollz-tab"
		case panel = "data-dollz-panel"
		case slot = "data-dollz-slot"
		case item = "data-dollz-item"
		case color = "data-dollz-color"
	}

	enum Styles: ElementStyleSet {
		case root
		case title
		case corner
		case maker
		case stage
		case figure
		case canvas
		case status
		case bigButton
		case dimmedWhenDisabled
		case belowDoll
		case controls
		case tabs
		case tab
		case panel
		case fieldset
		case legend
		case choices
		case choice
		case palette
		case swatch
		case options
		case fields
		case fieldLabel
		case gallery
		case rules
		case agree
		case certificateBox
		case certificate

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .title:
				Style().color(Color("#cc0099"))
			case .corner:
				Style().vstack(spacing: .rootEm(1))
			case .maker:
				// The doll and the controls side by side, and one above the other on a phone.
				Style()
					.grid(minimumColumnWidth: .rootEm(17))
					.gap(.rootEm(1))
					.alignItems(.start)
					.children("*") {
						$0.frame(minWidth: 0)
					}
					.below(.smallTablet) {
						$0.gridColumns(1)
					}
			case .stage:
				// On a phone, the parts of the stage are rows of the maker, so the doll can stick to the top while the visitor scrolls through the clothes.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.below(.smallTablet) {
						$0.display(.contents)
					}
			case .figure:
				// On a phone, the clothes are below the doll, so the doll and what Lillesøster says stick under the header of the site, smaller, and the visitor sees each change.
				Style()
					.vstack(spacing: .rootEm(0.25))
					.below(.smallTablet) {
						$0
							.position(.sticky)
							.top(SiteHeader.height)
							.zIndex(1)
							.padding(.vertical, .rootEm(0.25))
							.background(GeoCitiesPage.windowGray)
					}
			case .canvas:
				// The doll at 1x, scaled up with crisp pixels, on white like a page of 1999.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto, maxWidth: .pixels(384))
					.margin(.horizontal, .auto)
					.aspectRatio(128.0 / 200.0)
					.imageRendering(.pixelated)
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
					// On a phone, the height is capped, so the sticky doll and what Lillesøster says leave most of the screen for the clothes.
					.below(.smallTablet) {
						$0.frame(width: .auto, height: .smallViewportHeight(22))
					}
			case .status:
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(Color("#cc0099"))
			case .bigButton:
				Style().frame(minHeight: .rootEm(2.75))
			case .dimmedWhenDisabled:
				Style().disabled {
					$0.opacity(0.5)
				}
			case .belowDoll:
				// On a phone, the doll and what Lillesøster says stick to the top of the screen (the canvas, 2 lines of the status, and the gaps), so a control of the maker that gets focus scrolls into view below them. The site header is already in the scroll padding of the page.
				Style().below(.smallTablet) {
					$0.scrollMargin(top: .smallViewportHeight(22) + .rootEm(3.75))
				}
			case .controls:
				Style().vstack(spacing: .rootEm(0.75))
			case .tabs:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .tab:
				// The open tab is pink and pressed in.
				Style()
					.frame(minHeight: .rootEm(2.5))
					.when(.state, is: "on") {
						$0
							.background(Color("#ffccee"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .panel:
				Style().vstack(spacing: .rootEm(0.5))
			case .fieldset:
				Style()
					.margin(0)
					.padding(.rootEm(0.5))
					.background(Color("#fff0fa"))
					.border(Color("#ff99cc"), width: .pixels(2), style: .groove)
			case .legend:
				Style()
					.padding(.horizontal, .rootEm(0.25))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(Color("#cc0099"))
			case .choices:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .choice:
				// Big enough for a thumb, and pink and pressed in while it is on.
				Style()
					.frame(minHeight: .rootEm(2.5))
					.when(.state, is: "on") {
						$0
							.background(Color("#ff99dd"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .palette:
				// Two rows of 14, like the palette of MS Paint.
				Style()
					.grid(columns: 14)
					.gap(.pixels(2))
					.margin(.bottom, .rootEm(0.5))
			case .swatch:
				Style()
					.frame(minHeight: .rootEm(1.75))
					.padding(0)
					.background(GeoCitiesDollz.swatchColor.value(default: .white))
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.handCursor()
					.when(.state, is: "on") {
						$0.border(.black, width: .pixels(2), style: .solid)
					}
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(1))
					}
			case .options:
				Style().vstack(spacing: .rootEm(0.5))
			case .fields:
				Style()
					.grid(minimumColumnWidth: .rootEm(9))
					.gap(.rootEm(0.5))
			case .fieldLabel:
				Style()
					.vstack(spacing: .rootEm(0.125))
					.textStyle(.caption, weight: .bold)
			case .gallery:
				// The dolls at their real size, in a row of little rooms. The script makes the rooms.
				Style()
					.grid(minimumColumnWidth: .pixels(136))
					.gap(.rootEm(0.5))
					.margin(0)
					.padding(0)
					.children("li") {
						$0
							.vstack(alignment: .center, spacing: .rootEm(0.25))
							.padding(.rootEm(0.25))
							.background(Color("#fff0fa"))
							.border(Color("#ff99cc"), width: .pixels(2), style: .outset)
							.textStyle(.caption, weight: .bold)
							.fontFamily(GeoCitiesPage.comicSans)
							.textAlign(.center)
							.when(.state, is: "sister") {
								$0.background(Color("#ffffcc"))
							}
					}
			case .rules:
				// The rules sparkle in the colors of the rainbow, but hold still for reduced motion.
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.large, weight: .bold)
					.color(Color("#ff0099"))
					.media(.allowsMotion) {
						$0.animation(GeoCitiesPage.Animations.rainbow, .linear(duration: .seconds(2)).repeatForever(autoreverses: false))
					}
			case .agree:
				Style()
					.display(.block)
					.fontFamily(GeoCitiesPage.comicSans)
					.fontWeight(.bold)
			case .certificateBox:
				Style().vstack(spacing: .rootEm(0.5))
			case .certificate:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto, maxWidth: .pixels(576))
					.margin(.horizontal, .auto)
					.aspectRatio(288.0 / 208.0)
					.imageRendering(.pixelated)
					.background(.white)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			}
		}
	}
}
