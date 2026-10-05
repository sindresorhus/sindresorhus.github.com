import Elementary
import Foundation
import SiteKit

/**
Christmas in Bergen in 1999, as three toys in windows, with the Norwegian traditions of Christmas. Pepperkakebyen, the gingerbread town of Bergen, the biggest in the world, where kids bring their own gingerbread houses every year: the visitor builds a gingerbread house on the cake board from walls, gable roofs, and chimneys that stack like the houses of Bryggen (or starts from Pappa’s Bryggen kit), glues the seams with icing from a piping bag that the visitor draws with, where red dashes show the seams that still need icing, decorates it with Smarties, gummy bears, licorice, and peppermint candy that only stick where there is icing, dusts it with powdered sugar (melis) for snow, names it, and lets Lillesøster taste it (she bites, and a wall with three bites breaks). When the icing dries, or on the way to the town, the pieces whose seams have no icing fall off, with everything that only stands on them. A house that stands goes to the town, where it stands among the gingerbread Bryggen, the church, and the houses of other kids, in the snow, with a little train that goes around and toots. Nisse Bowling, like Elf Bowling, the Christmas game of 1998 that everyone mailed around: Julenissen bowls at ten nisser at the end of the lane, who taunt him in speech bubbles, with an aim, a spin, and steering while the ball rolls, nisser who dodge the ball, and nisser who turn around and wiggle their behinds in their red trousers. The nisser fly when they are hit, a strike gets a celebration with sleigh bells, and the score sheet has ten frames with strikes, spares, and the bonus balls of the tenth frame, and keeps the best score. The barn nisse’s porridge (fjøsnissen): on Christmas Eve, the visitor cooks the rice porridge (risengrynsgrøt) and stirs it so it does not burn, hides the almond, and eats with the family until someone finds the almond and wins the marzipan pig (mandelgave), and Mormor hides it in her cheek until all the bowls are empty. Then a bowl must go out to the barn for the nisse, with a pat of butter, sugar, and cinnamon. If the visitor forgets the butter, or eats the porridge, the nisse plays pranks on the 1999 page, one every 20 seconds: he knocks the title bar of the bowling window crooked, tilts a GIF, smears porridge on the visitor counter, swaps two letters of the title, and turns a GIF upside down, and a list tells what he did, with a button that shows each one. He never hides a button or turns a canvas that the visitor plays on. He puts it all back when the visitor brings a new bowl with butter, and the angry nisse stays angry in the browser until then. The pranks reach outside the element on purpose, as they are on the rest of the page (the GIFs, the visitor counter, and the title of the page), and the nisse plays them while the toy is off screen too, as long as the tab is visible, and he also puts them back when the toy is removed. A sound button turns on the sleigh bells, the crunch of gingerbread, and the bowling, and two buttons play “Bjelleklang” (“Jingle Bells”) and “Glade jul” (“Silent Night”) with bells. Its script, `Christmas.js`, runs it, each canvas only while it is on the screen and the tab is visible. With reduced motion, nothing moves by itself: the train moves when it toots, the snow and the falling pieces stand still, and the ball of the bowling shows its whole path at once. Without scripts, it is left out, as it has nothing to show.
*/
struct GeoCitiesChristmas: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	The pieces and candies of the gingerbread house, by the name that `Christmas.js` knows them by, with their names.
	*/
	private static let houseTools: [(id: String, name: String)] = [
		("wall", "🧱 Wall"),
		("roof", "🔺 Roof"),
		("chimney", "🏭 Chimney"),
		("icing", "🧁 Piping Bag"),
		("smarties", "🔴 Smarties"),
		("bear", "🐻 Gummy Bear"),
		("licorice", "➰ Licorice"),
		("peppermint", "🍬 Peppermint"),
	]

	var content: some HTML {
		h2 {
			GeoCitiesPage.GIFImage(gif: .candle, alt: "", style: .gif, project: project)
			" God Jul fra Bergen!!! "
			GeoCitiesPage.GIFImage(gif: .candle, alt: "", style: .gif, project: project)
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Christmas in Bergen! It rains instead of snowing (as always), but we have the biggest gingerbread town in the world, Julenissen on the bowling lane, and a nisse in the barn at Mormor’s farm who wants his porridge. Do NOT forget the butter."
		}
		.style(GeoCitiesPage.Styles.centeredText)

		div {
			Toolbar()
			GingerbreadWindow()

			div {
				BowlingWindow()
				PorridgeWindow()
			}
			.style(GeoCitiesPage.Styles.columns)
		}
		.style(Styles.windows, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Christmas needs JavaScript. God jul anyway!"
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The sound, and the Christmas songs.
	*/
	private struct Toolbar: HTML {
		var body: some HTML {
			div {
				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔔 Sound"
				}
				.help("Sleigh bells, the crunch of gingerbread, and the bowling")
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle, Styles.bigTarget)

				button(.type(.button), .hook(Hooks.music, value: "bjelleklang"), .ariaPressed(false)) {
					"🎵 Play “Bjelleklang”"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle, Styles.bigTarget)

				button(.type(.button), .hook(Hooks.music, value: "glade-jul"), .ariaPressed(false)) {
					"🎵 Play “Glade jul”"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle, Styles.bigTarget)
			}
			.style(Styles.row, Styles.centeredRow)
		}
	}

	/**
	A window of Windows 95, with a title bar, which the angry barn nisse can knock crooked.
	*/
	private struct ToyWindow<Content: HTML>: HTML {
		let title: String
		let name: String
		@HTMLBuilder let content: Content

		var body: some HTML {
			section {
				h3(.hook(Hooks.titleBar, value: name)) {
					title
				}
				.style(GeoCitiesPage.Styles.titleBar, Styles.crooked)

				div {
					content
				}
				.style(GeoCitiesPage.Styles.windowBody)
			}
			.style(GeoCitiesPage.Styles.window)
		}
	}

	/**
	Pepperkakebyen: the gingerbread house and the town.
	*/
	private struct GingerbreadWindow: HTML {
		var body: some HTML {
			ToyWindow(title: "🍪 Pepperkakebyen: Build a Gingerbread House", name: "gingerbread") {
				p {
					"Every Christmas, the kids of Bergen bring their own gingerbread houses to Pepperkakebyen, the biggest gingerbread town in the world. Pick a piece and tap a spot on the cake board to put it there. Glue EVERY seam with the piping bag, or it falls apart on the way! Candy only sticks on icing."
				}
				.style(GeoCitiesPage.Styles.caption)

				div {
					HouseBoard()

					div {
						HouseActions()
						Town()
					}
					.style(Styles.stack)
				}
				.style(Styles.workshop)
			}
		}
	}

	/**
	The cake board, with what happens right under it and the pieces and candies, so a phone shows them together while the visitor builds.
	*/
	private struct HouseBoard: HTML {
		var body: some HTML {
			div {
				canvas(.part(Parts.house), .width(360), .height(270), .tabindex(0), .role("application")) {}
					.accessibilityLabel("My gingerbread house on the cake board. Pick a piece or a candy, and click or tap the board to put it there. With the piping bag, drag to pipe icing on the seams. With the keys, the arrow keys move the piping bag, and Space or Enter puts the piece or the candy there. Hold Space while you move to pipe icing.")
					.style(Styles.house)

				p(.part(Parts.houseStatus), .role("status")) {
					"Pick a wall, and tap the cake board."
				}
				.style(Styles.status)

				HouseTools()
			}
			.style(Styles.stack)
		}
	}

	/**
	The pieces, the piping bag, and the candies.
	*/
	private struct HouseTools: HTML {
		var body: some HTML {
			div {
				for (index, tool) in GeoCitiesChristmas.houseTools.enumerated() {
					button(.type(.button), .hook(Hooks.tool, value: tool.id), .ariaPressed(index == 0)) {
						tool.name
					}
					.attributes(.hook(.state, value: "on"), when: index == 0)
					.style(GeoCitiesPage.Styles.smallButton, Styles.toggle, Styles.bigTarget)
				}
			}
			.accessibilityLabel("Pieces and candy")
			.attributes(.role("group"))
			.style(Styles.row)
		}
	}

	/**
	What the visitor does with the whole house.
	*/
	private struct HouseActions: HTML {
		var body: some HTML {
			div {
				label(.for("geocities-christmas-name")) {
					"Name on the sign:"
				}
				.style(Styles.inlineLabel)

				input(.id("geocities-christmas-name"), .part(Parts.houseName), .type(.text), .maxlength(18), .autocomplete("off"), .placeholder("Sindre, 11 år"))
					.style(GeoCitiesPage.Styles.field, Styles.nameField)
			}
			.style(Styles.row)

			div {
				button(.type(.button), .hook(Hooks.houseAction, value: "snow")) {
					"❄️ Dust with Melis"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				button(.type(.button), .hook(Hooks.houseAction, value: "bite")) {
					"😋 Lillesøster Wants a Taste"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				button(.type(.button), .hook(Hooks.houseAction, value: "bryggen")) {
					"🏘 Bryggen Kit"
				}
				.help("Builds four Bryggen houses for you, without icing")
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				button(.type(.button), .hook(Hooks.houseAction, value: "undo")) {
					"↩ Undo"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				button(.type(.button), .hook(Hooks.houseAction, value: "clear")) {
					"🗑 Start Over"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.style(Styles.row)

			div {
				button(.type(.button), .hook(Hooks.houseAction, value: "dry")) {
					"⏳ Let the Icing Dry"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				button(.type(.button), .hook(Hooks.houseAction, value: "bring")) {
					"🚗 Bring It to the Town"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(Styles.row)
		}
	}

	/**
	The gingerbread town, with the little train.
	*/
	private struct Town: HTML {
		var body: some HTML {
			canvas(.part(Parts.town), .width(360), .height(180), .role("img")) {}
				.accessibilityLabel("Pepperkakebyen, the gingerbread town of Bergen, with Bryggen, the church, the houses of other kids, my houses with their signs, and a little train that goes around.")
				.style(Styles.town)

			div {
				button(.part(Parts.toot), .type(.button)) {
					"🚂 Tut-tut!"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				button(.type(.button), .hook(Hooks.houseAction, value: "empty-town")) {
					"🧹 Take My Houses Home"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.style(Styles.row)
		}
	}

	/**
	Nisse Bowling, like Elf Bowling.
	*/
	private struct BowlingWindow: HTML {
		var body: some HTML {
			ToyWindow(title: "🎳 NISSE BOWLING.EXE", name: "bowling") {
				p {
					"Trond mailed me this! Julenissen bowls at the nisser, and they are NOT nice about it. Move him, set the spin, and bowl. Steer the ball while it rolls."
				}
				.style(GeoCitiesPage.Styles.caption)

				canvas(.part(Parts.lane), .width(320), .height(400), .tabindex(0), .role("application")) {}
					.accessibilityLabel("The bowling lane, with Julenissen at the front and ten nisser at the end. The left and right arrow keys move Julenissen, and steer the ball while it rolls. A and D set the spin, and Space or Enter bowls.")
					.style(Styles.lane)

				// Right under the lane, so a phone shows the lane, what happened, the buttons, and the score sheet together.
				p(.part(Parts.bowlingStatus), .role("status")) {
					"Frame 1. The nisser are waiting."
				}
				.style(Styles.status)

				BowlingControls()
				ScoreSheet()
			}
		}
	}

	/**
	The buttons of the bowling.
	*/
	private struct BowlingControls: HTML {
		var body: some HTML {
			div {
				button(.type(.button), .hook(Hooks.bowl, value: "left")) {
					"◀ Move"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.thumb)

				button(.type(.button), .hook(Hooks.bowl, value: "bowl")) {
					"🎳 Bowl!"
				}
				.style(GeoCitiesPage.Styles.retroButton, Styles.thumb)

				button(.type(.button), .hook(Hooks.bowl, value: "right")) {
					"Move ▶"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.thumb)
			}
			.style(Styles.row, Styles.centeredRow)

			div {
				button(.type(.button), .hook(Hooks.bowl, value: "spin-left")) {
					"↶ Spin"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				p(.part(Parts.spin)) {
					"Spin: none"
				}
				.style(GeoCitiesPage.Styles.lcd, Styles.spin)

				button(.type(.button), .hook(Hooks.bowl, value: "spin-right")) {
					"Spin ↷"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				button(.type(.button), .hook(Hooks.bowl, value: "new")) {
					"New Game"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.style(Styles.row, Styles.centeredRow)
		}
	}

	/**
	The score sheet, with ten frames, filled by `Christmas.js`.
	*/
	private struct ScoreSheet: HTML {
		var body: some HTML {
			ol(.part(Parts.sheet)) {
				for frame in 1...10 {
					li {
						span {
							"\(frame)"
						}

						span {}

						strong {}
					}
				}
			}
			.accessibilityLabel("The score sheet")
			.style(Styles.sheet)

			p(.part(Parts.best)) {
				"Best: 0"
			}
			.style(Styles.best)
		}
	}

	/**
	The barn nisse’s porridge on Christmas Eve.
	*/
	private struct PorridgeWindow: HTML {
		var body: some HTML {
			ToyWindow(title: "🥣 Julaften: Grøt for Fjøsnissen", name: "porridge") {
				p {
					"Christmas Eve at Mormor’s farm. First the rice porridge for us, with the almond in it (whoever finds it wins the marzipan pig). Then a bowl for the nisse in the barn, WITH butter, or he plays pranks on you all year."
				}
				.style(GeoCitiesPage.Styles.caption)

				canvas(.part(Parts.barn), .width(320), .height(200), .role("img")) {}
					.accessibilityLabel("The kitchen at Mormor’s farm on Christmas Eve, the table, and the barn in the snow, where the nisse lives.")
					.style(Styles.barn)

				PorridgeControls()

				p(.part(Parts.pigs)) {
					"Marzipan pigs: none yet"
				}
				.style(GeoCitiesPage.Styles.lcd, Styles.pigs)

				p(.part(Parts.porridgeStatus), .role("status")) {
					"The rice and the milk are in the pot. Stir, so it does not burn!"
				}
				.style(Styles.status)

				div(.part(Parts.pranks), .hidden) {
					h4 {
						"😠 What the nisse did to my page:"
					}
					.style(Styles.pranksTitle)

					ul(.part(Parts.prankList)) {}
						.style(Styles.prankList)
				}
				.style(Styles.pranks)
			}
		}
	}

	/**
	The buttons of the porridge, which `Christmas.js` shows when they can be used.
	*/
	private struct PorridgeControls: HTML {
		var body: some HTML {
			div {
				PorridgeButton(action: "stir", title: "🥄 Stir the Pot")
				PorridgeButton(action: "almond", title: "🌰 Hide the Almond")
				PorridgeButton(action: "serve", title: "🍚 Serve the Family")
				PorridgeButton(action: "eat", title: "🥄 Eat a Spoonful")
				PorridgeButton(action: "more", title: "🍚 Take Seconds")
				PorridgeButton(action: "fill", title: "🥣 Fill the Nisse’s Bowl")
				PorridgeButton(action: "butter", title: "🧈 Pat of Butter", isToggle: true)
				PorridgeButton(action: "sugar", title: "✨ Sugar", isToggle: true)
				PorridgeButton(action: "cinnamon", title: "🟤 Cinnamon", isToggle: true)
				PorridgeButton(action: "carry", title: "🌙 Carry It to the Barn")
				PorridgeButton(action: "steal", title: "😋 Eat It Myself")
				PorridgeButton(action: "morning", title: "☀️ Next Morning")
				PorridgeButton(action: "again", title: "🔁 Christmas Eve Again")
			}
			.style(Styles.row, Styles.centeredRow)
		}
	}

	/**
	A button of the porridge, hidden until `Christmas.js` shows it.
	*/
	private struct PorridgeButton: HTML {
		let action: String
		let title: String
		var isToggle = false

		var body: some HTML {
			button(.type(.button), .hook(Hooks.porridgeAction, value: action), .hidden) {
				title
			}
			.attributes(.ariaPressed(false), when: isToggle)
			.style(GeoCitiesPage.Styles.smallButton, Styles.toggle, Styles.bigTarget)
		}
	}

	enum Parts: String, ElementPartSet {
		case sound
		case house
		case houseName
		case houseStatus
		case town
		case toot
		case lane
		case spin
		case sheet
		case best
		case bowlingStatus
		case barn
		case pigs
		case porridgeStatus
		case pranks
		case prankList
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button that plays a Christmas song: `bjelleklang` or `glade-jul`.
		*/
		case music = "data-christmas-music"

		/**
		A button that picks a piece, the piping bag, or a candy, like `roof` or `smarties`.
		*/
		case tool = "data-christmas-tool"

		/**
		A button that does something with the whole house: `snow`, `bite`, `bryggen`, `undo`, `clear`, `dry`, `bring`, or `empty-town`.
		*/
		case houseAction = "data-christmas-house-action"

		/**
		A button of the bowling: `left`, `right`, `spin-left`, `spin-right`, `bowl`, or `new`.
		*/
		case bowl = "data-christmas-bowl"

		/**
		A button of the porridge, like `stir`, `butter`, or `carry`.
		*/
		case porridgeAction = "data-christmas-porridge"

		/**
		The title bar of a window, by its toy: `gingerbread`, `bowling`, or `porridge`.
		*/
		case titleBar = "data-christmas-title-bar"
	}

	enum Styles: ElementStyleSet {
		case root
		case windows
		case crooked
		case row
		case centeredRow
		case stack
		case toggle
		case bigTarget
		case thumb
		case workshop
		case house
		case inlineLabel
		case nameField
		case town
		case lane
		case spin
		case sheet
		case best
		case barn
		case pigs
		case status
		case pranks
		case pranksTitle
		case prankList

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .windows:
				Style().vstack(spacing: .rootEm(1.25))
			case .crooked:
				// Knocked crooked by the angry barn nisse.
				Style().when(.state, is: "tilted") {
					$0.rotationEffect(.degrees(-3))
				}
			case .row:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .centeredRow:
				Style().hstack(alignment: .center, justification: .center, spacing: .rootEm(0.375))
			case .stack:
				Style().vstack(spacing: .rootEm(0.5))
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
			case .thumb:
				// Big buttons for the thumbs, which can be held down.
				Style()
					.frame(minWidth: .rootEm(5), minHeight: .rootEm(2.75))
					.touchAction(.manipulation)
					.textSelection(.disabled)
			case .workshop:
				Style()
					.grid(minimumColumnWidth: .rootEm(18))
					.gap(.rootEm(0.75))
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .house:
				// The kitchen table under the cake board. With the piping bag, a finger pipes icing on it instead of scrolling the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(360.0 / 270.0)
					.border(Color("#6b3a1a"), width: .pixels(4), style: .ridge)
					.touchAction(.manipulation)
					.when(.state, is: "piping") {
						$0.touchAction(.none)
					}
					.cursor(.crosshair)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .inlineLabel:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .nameField:
				Style()
					.flex(1)
					.frame(width: .auto, minWidth: .rootEm(8))
			case .town:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(360.0 / 180.0)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .lane:
				// A tap on the lane bowls, so a finger on it does not zoom the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto, maxWidth: .rootEm(22))
					.margin(.horizontal, .auto)
					.aspectRatio(320.0 / 400.0)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.touchAction(.manipulation)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .spin:
				Style()
					.frame(minWidth: .rootEm(7))
					.margin(0)
					.textStyle(.caption)
					.textAlign(.center)
			case .sheet:
				// The score sheet of the bowling alley: the number of the frame, the balls, and the total.
				Style()
					.grid(columns: 10)
					.margin(0)
					.padding(0)
					.background(.white)
					.border(.black, width: .pixels(2))
					.fontFamily(GeoCitiesPage.courier)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.textAlign(.center)
					.children("li") {
						$0
							.vstack(spacing: 0)
							.frame(minWidth: 0)
							.border(.black, width: .pixels(1))
					}
					.children("li span:first-child") {
						$0
							.background(Color("#cc0000"))
							.color(.white)
					}
					.children("li span + span") {
						$0
							.frame(minHeight: .lineHeight(1))
							.color(Color("#000080"))
					}
					.children("li strong") {
						$0.frame(minHeight: .lineHeight(1))
					}
			case .best:
				Style()
					.margin(0)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .barn:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(320.0 / 200.0)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
			case .pigs:
				Style()
					.margin(0)
					.textStyle(.caption)
					.textAlign(.center)
			case .status:
				// A yellow note from Mamma on the fridge, where the toys say what happens.
				Style()
					.frame(minHeight: .lineHeight(2))
					.margin(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.background(Color("#fff68f"))
					.shadow(Shadow(x: .pixels(2), y: .pixels(2), color: Color("#00000040")))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(.black)
			case .pranks:
				// A note from the angry nisse, on red paper.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(.rootEm(0.5))
					.background(Color("#ffdddd"))
					.border(Color("#cc0000"), width: .pixels(3), style: .dashed)
					.color(.black)
			case .pranksTitle:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .prankList:
				Style()
					.vstack(spacing: .rootEm(0.25))
					.margin(0)
					.padding(.leading, .rootEm(1))
					.textStyle(.caption)
					// The buttons that scroll to each prank, made by `Christmas.js`, raised and gray like the other buttons.
					.children("li button") {
						$0
							.margin(.leading, .rootEm(0.375))
							.frame(minHeight: .rootEm(2))
							.padding(vertical: 0, horizontal: .rootEm(0.5))
							.background(GeoCitiesPage.windowGray)
							.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
							.fontFamily(.system)
							.textStyle(.caption, weight: .bold)
							.color(.black)
							.touchAction(.manipulation)
							.handCursor()
					}
			}
		}
	}
}
