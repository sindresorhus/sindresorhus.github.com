import Elementary
import Foundation
import SiteKit

/**
Order Now!: the ads on the back pages of my comic books, like Donald Duck & Co. and the American comics that Trond’s cousin sent from Minnesota, and what really came in the mail. Each ad is drawn in the halftone dots of the comics, with a bold headline, a price, and a coupon with a dashed line. The visitor cuts out a coupon with scissors along the dashed line on the kitchen table, Sindre’s piggy bank pays (unless Mamma says no first, and then Pappa or a promise to clean my room may help), and the letter goes in the mail. Then the weeks go by (“Allow 6 to 8 weeks for delivery”, sped up), and the visitor checks the mailbox in the Bergen rain, which mostly has bills for Pappa, until a package comes. The package is torn open on the kitchen table, with bubble wrap to pop one bubble at a time (or all at once, which ruins it), and the thing inside is shown next to its ad. Then it is mine to play with: Sea-Monkeys that hatch in a tank and follow a flashlight, and look nothing like the royal family of the ad under a magnifying glass; X-Ray Specs that show the bones (the HTML) of the whole page under the pointer; a Chia Pet to seed, water, and give a haircut; a whoopee cushion for the chair of Mormor; a joy buzzer for Pappa’s hand; onion gum for the family; crystals that grow in a jar; the art school test, where the visitor draws Tippy and mails it in; and the real hovercraft for 99 kroner, which is a sheet of plans. Its script, `MailOrder.js`, runs it, and keeps the orders in the browser.
*/
struct GeoCitiesMailOrder: ScriptedElement {
	static let script = ElementScript()

	/**
	An ad on the back page of the comic book.
	*/
	private struct Ad {
		let id: String
		let headline: String
		let pitch: String
		let price: Int
		let finePrint: String
		let picture: String
	}

	/**
	The ads, in the order of the page. The script knows them by the ID, and has what really comes in the mail.
	*/
	private static let ads = [
		Ad(id: "sea-monkeys", headline: "Amazing Live Sea-Monkeys!", pitch: "Own a bowlful of happiness! A whole royal family that lives, plays, and obeys your commands. Instant life: just add water!", price: 49, finePrint: "With Water Purifier, Instant Life Eggs, and Growth Food. Guaranteed to hatch!", picture: "A happy family of Sea-Monkeys with crowns, in a fish bowl."),
		Ad(id: "x-ray-specs", headline: "X-Ray Specs", pitch: "See the bones in your hand! See through walls, and see the HTML of any web page! Amaze your friends!", price: 29, finePrint: "Scientific optical principle really works. Not for driving.", picture: "A boy with X-Ray Specs, who sees the bones of his hand."),
		Ad(id: "chia", headline: "Ch-ch-ch-Chia Pet!", pitch: "The pottery that grows! Spread the seeds, add water, and in days your ram has a coat of lush green hair.", price: 79, finePrint: "Handmade clay planter. Seeds included.", picture: "A clay ram with a thick coat of green hair."),
		Ad(id: "whoopee", headline: "Whoopee Cushion", pitch: "Hide it on a chair and wait! The rudest noise in the world, when anyone sits down. Hours of fun at family dinners!", price: 15, finePrint: "Real rubber. Blow it up yourself.", picture: "A man who jumps up from a chair, with “PFFFRRT!” in big letters."),
		Ad(id: "buzzer", headline: "Joy Buzzer", pitch: "Shake hands and SHOCK your friends! Wind it up, hide it in your palm, and BZZZT! Totally harmless!", price: 19, finePrint: "Spring power. No batteries.", picture: "Two hands that shake, with lightning bolts."),
		Ad(id: "onion-gum", headline: "Onion Gum", pitch: "Looks like real spearmint gum. Tastes like a raw ONION! Offer a stick and watch their faces!", price: 10, finePrint: "5 sticks per pack.", picture: "A pack of gum, and a girl with a green face."),
		Ad(id: "crystals", headline: "Grow Your Own Crystals", pitch: "A glittering crystal castle in only 24 hours! Real science on your windowsill!", price: 39, finePrint: "Magic crystal powder and growing rock included.", picture: "A tall, glittering castle of crystals."),
		Ad(id: "draw", headline: "Draw Me!", pitch: "Do you have talent? Draw Tippy the turtle and mail it in for a FREE professional art test. You may win a scholarship!", price: 0, finePrint: "No fee. No obligation. Just a stamp.", picture: "Tippy, a turtle in a cap, with a pencil."),
		Ad(id: "hovercraft", headline: "Real Hovercraft: Only 99 Kroner!", pitch: "Ride on a cushion of air over land, snow, and water! Faster than a moped! Complete and ready for adventure!", price: 99, finePrint: "*Plans only. Motor, plywood, skirt, and fan not included.", picture: "A boy on a hovercraft that flies over a lake, with spray."),
	]

	/**
	The tabindex of the section that the toy was, so a click on the toy outside its controls focuses the toy, and not the page.
	*/
	var rootAttributes: [HTMLAttribute<ElementTag<Self>>] {
		[.tabindex(-1)]
	}

	var content: some HTML {
		h2 {
			"Order Now!"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"The best pages of a comic book are the last ones: the ads! Cut out a coupon, pay with my piggy bank, and wait for the mailman. Then we see if it looks like the ad."
		}

		div {
			bank
			comicBook

			div(.part(Parts.mamma), .role("alertdialog"), .custom(name: "aria-describedby", value: "geocities-mail-order-mamma-text"), .hidden) {
				p(.id("geocities-mail-order-mamma-text"), .part(Parts.mammaText)) {}
					.style(Styles.mammaText)

				div {
					button(.part(Parts.mammaPappa), .type(.button)) {
						"Ask Pappa Instead"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.part(Parts.mammaPromise), .type(.button)) {
						"Promise to Clean My Room"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.part(Parts.mammaCancel), .type(.button)) {
						"Never Mind"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.accessibilityLabel("Mamma")
			.style(Styles.mamma)

			div {
				window("The Kitchen Table", part: .table) {
					kitchenTable
				}

				window("The Mailbox", part: .mailbox) {
					mailbox
				}
			}
			.style(Styles.desk)

			window("My Stuff from the Mail", part: .stuff) {
				stuff
			}

			div {
				button(.part(Parts.reset), .type(.button)) {
					"Start Over with a New Comic"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			// The lens of the X-Ray Specs, over the whole page. The script moves it to the end of the page, so nothing around it can cut it off.
			canvas(.part(Parts.lens), .hidden) {}
				.accessibilityHidden()
				.style(Styles.lens)
		}
		.style(Styles.toy, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"The coupons need JavaScript to be cut out. And 6 to 8 weeks."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	private var bank: some HTML {
		div {
			span(.part(Parts.piggy)) {
				"🐷"
			}
			.accessibilityHidden()
			.style(Styles.piggy)

			p {
				"My piggy bank: "
				span(.part(Parts.balance)) {
					"120 kr"
				}
				.style(GeoCitiesPage.Styles.lcd)
			}
			.style(Styles.bankLabel)

			div {
				button(.part(Parts.pant), .type(.button)) {
					"Return a Bottle (Pant)"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.mormor), .type(.button)) {
					"Visit Mormor"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.sound), .type(.button), .custom(name: "aria-pressed", value: "false")) {
					"🔊 Sound"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.bankStatus), .role("status")) {}
				.style(Styles.bankStatus)
		}
		.style(Styles.bank)
	}

	private var comicBook: some HTML {
		div {
			div {
				span {
					"Donald Duck & Co."
				}
				span {
					"Nr. 37 · 1999"
				}
				span {
					"Kr 14,50"
				}
			}
			.style(Styles.masthead)

			div {
				for ad in Self.ads {
					article(.hook(Hooks.ad, value: ad.id), .hook(Hooks.price, value: "\(ad.price)")) {
						canvas(.part(Parts.art), .width(480), .height(300), .role("img")) {}
							.accessibilityLabel(ad.picture)
							.style(Styles.art)

						h3 {
							ad.headline
						}
						.style(Styles.headline)

						p {
							ad.pitch
						}
						.style(Styles.pitch)

						p {
							ad.price == 0 ? "FREE!" : "Only \(ad.price) kr!"
						}
						.style(Styles.price)

						div(.part(Parts.coupon)) {
							p {
								"✂ Order Now!"
							}
							.style(Styles.couponTitle)

							p {
								"Name: ________ Address: ________"
							}
							.style(Styles.finePrint)

							p {
								ad.finePrint
							}
							.style(Styles.finePrint)

							button(.part(Parts.cut), .type(.button)) {
								"Cut Out the Coupon"
							}
							.style(GeoCitiesPage.Styles.smallButton, Styles.dimmedWhenDisabled)
						}
						.style(Styles.coupon)

						p(.part(Parts.note)) {
							"Allow 6 to 8 weeks for delivery."
						}
						.style(Styles.note)
					}
					.style(Styles.ad)
				}
			}
			.style(Styles.ads)
		}
		.style(Styles.comic)
	}

	private var kitchenTable: some HTML {
		div {
			canvas(.part(Parts.tableCanvas), .width(360), .height(240), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The kitchen table. With a coupon, drag the scissors along the dashed line, or press Space to cut. With a package, press Space to tear the paper, and then the arrow keys and Space to pop the bubble wrap.")
				.style(Styles.canvas, Styles.tableCanvas)

			div {
				button(.part(Parts.tableAction), .type(.button), .disabled) {
					"Lick the Stamp and Mail It"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.dimmedWhenDisabled)

				button(.part(Parts.tablePopAll), .type(.button), .hidden) {
					"Pop All"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.tableStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.panel)
	}

	private var mailbox: some HTML {
		div {
			canvas(.part(Parts.mailboxCanvas), .width(360), .height(240), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The mailbox outside the house, in the rain. Press Enter to check the mailbox.")
				.style(Styles.canvas, Styles.mailboxCanvas)

			div {
				button(.part(Parts.mailboxCheck), .type(.button)) {
					"Check the Mailbox"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.mailboxWait), .type(.button)) {
					"Wait a Week"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			p(.part(Parts.mailboxStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.panel)
	}

	private var stuff: some HTML {
		div {
			div(.part(Parts.stuffTabs), .role("group")) {}
				.accessibilityLabel("My stuff")
				.style(Styles.tabs)

			// The script adds a copy for each thing that came in the mail, and for each tool of the thing.
			template(.part(Parts.stuffTab)) {
				button(.type(.button)) {}
					.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
			}

			canvas(.part(Parts.stuffCanvas), .width(640), .height(360), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The thing from the mail. Use the buttons under it, drag on it, or move with the arrow keys and press Space. Hold Shift with the arrow keys to drag. To draw, press Space first.")
				.style(Styles.canvas, Styles.stuffCanvas)

			div(.part(Parts.stuffTools)) {}
				.style(GeoCitiesPage.Styles.buttonRow)

			template(.part(Parts.stuffTool)) {
				button(.type(.button)) {}
					.style(GeoCitiesPage.Styles.smallButton, Styles.toggle, Styles.dimmedWhenDisabled)
			}

			p(.part(Parts.stuffStatus), .role("status")) {}
				.style(Styles.status)
		}
		.style(Styles.panel)
	}

	private func window(_ title: String, part: Parts, @HTMLBuilder content: () -> some HTML) -> some HTML {
		section(.part(part), .tabindex(-1)) {
			h3 {
				title
			}
			.style(GeoCitiesPage.Styles.titleBar)

			div {
				content()
			}
			.style(GeoCitiesPage.Styles.windowBody)
		}
		.style(GeoCitiesPage.Styles.window, Styles.window)
	}

	enum Parts: String, ElementPartSet {
		case piggy
		case balance
		case pant
		case mormor
		case sound
		case bankStatus

		case mamma
		case mammaText
		case mammaPappa
		case mammaPromise
		case mammaCancel

		case table
		case tableCanvas
		case tableAction
		case tablePopAll
		case tableStatus

		case mailbox
		case mailboxCanvas
		case mailboxCheck
		case mailboxWait
		case mailboxStatus

		case stuff
		case stuffTabs
		case stuffTab
		case stuffCanvas
		case stuffTools
		case stuffTool
		case stuffStatus

		case reset
		case lens

		/**
		The picture of an ad, which the script draws.
		*/
		case art

		/**
		The coupon of an ad, which leaves a hole in the page when it is cut out.
		*/
		case coupon

		/**
		The button that takes the coupon of an ad to the kitchen table.
		*/
		case cut

		/**
		The line under an ad that tells where the order is.
		*/
		case note
	}

	enum Hooks: String, ScriptHookSet {
		/**
		An ad, with the ID of what it sells.
		*/
		case ad = "data-mail-order-ad"

		/**
		The price of an ad, in kroner.
		*/
		case price = "data-mail-order-price"
	}

	enum Styles: ElementStyleSet {
		case root
		case toy
		case bank
		case piggy
		case bankLabel
		case toggle
		case comic
		case masthead
		case ads
		case ad
		case art
		case headline
		case pitch
		case price
		case coupon
		case couponTitle
		case finePrint
		case note
		case mamma
		case mammaText
		case desk
		case window
		case panel
		case canvas
		case tableCanvas
		case mailboxCanvas
		case stuffCanvas
		case tabs
		case status
		case bankStatus
		case dimmedWhenDisabled
		case lens

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .toy:
				Style().vstack(spacing: .rootEm(1))
			case .bank:
				// The piggy bank on my desk, with the ways to fill it.
				Style()
					.hstack(alignment: .center, justification: .center, spacing: .rootEm(0.75))
					.flexWrap()
					.padding(.rootEm(0.5))
					.background(Color("#ffe4ec"))
					.border(Color("#cc6688"), width: .pixels(2), style: .ridge)
			case .piggy:
				// The piggy bank shakes while it pays, or while a coin goes in.
				Style()
					.display(.inlineBlock)
					.font(size: .rootEm(2.25), lineHeight: 1)
					.media(.allowsMotion) {
						$0.when(.state, is: "shaking") {
							$0.animation(Animations.shake, .linear(duration: .seconds(0.1)).repeatForever())
						}
					}
			case .bankLabel:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
			case .toggle:
				// Pressed in while it is on.
				Style().when(.state, is: "on") {
					$0
						.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
						.background(Color("#e8e8e8"))
				}
			case .comic:
				// The yellowed newsprint of the last pages of a comic book.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.625))
					.background(Color("#f6ecc8"))
					.border(.black, width: .pixels(3))
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000055")))
					.color(.black)
			case .masthead:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
					.flexWrap()
					.padding(.bottom, .rootEm(0.25))
					.border(.bottom, .black, width: .pixels(2))
					.fontFamily(GeoCitiesPage.impact)
					.textStyle(.caption)
					.textCase(.uppercase)
					.letterSpacing(.em(0.05))
			case .ads:
				Style()
					.grid(minimumColumnWidth: .rootEm(12))
					.gap(.rootEm(0.625))
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .ad:
				// A box of the ad page, with a black frame like the panels of a comic.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(.rootEm(0.5))
					.background(Color("#fffbe8"))
					.border(.black, width: .pixels(2))
			case .art:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(240.0 / 150.0)
					.border(.black, width: .pixels(1))
			case .headline:
				// The loud headline of an ad.
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge)
					.lineHeight(1)
					.fontWeight(.regular)
					.textCase(.uppercase)
					.color(Color("#d40000"))
					.textShadow(Shadow(x: .pixels(1), y: .pixels(1), color: Color("#ffcc00")))
			case .pitch:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.times)
					.textStyle(.caption)
			case .price:
				// A yellow price sticker, a little crooked.
				Style()
					.alignSelf(.start)
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.background(Color("#ffe100"))
					.border(Color("#d40000"), width: .pixels(2))
					.cornerRadius(.rootEm(0.5))
					.fontFamily(GeoCitiesPage.impact)
					.textStyle(.body)
					.color(Color("#d40000"))
					.rotationEffect(.degrees(-4))
			case .coupon:
				// A coupon with a dashed line to cut along. When it is cut out, a hole in the page is left, and the next page shows through.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.margin(.top, .auto)
					.padding(.rootEm(0.5))
					.background(.white)
					.border(.black, width: .pixels(2), style: .dashed)
					.textAlign(.center)
					.when(.state, is: "cut") {
						$0
							.background(Color("#c9bfa0"))
							.border(Color("#8a7f60"), width: .pixels(2), style: .dashed)
							.shadow(Shadow(x: .pixels(2), y: .pixels(2), blur: .pixels(4), color: Color("#00000066"), isInset: true))
							.children("*") {
								$0.visibility(false)
							}
					}
			case .couponTitle:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.impact)
					.textStyle(.body)
					.textCase(.uppercase)
					.color(Color("#d40000"))
			case .finePrint:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.times)
					.font(size: .rootEm(0.6875), lineHeight: 1.2)
			case .note:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.font(size: .rootEm(0.75), lineHeight: 1.3)
					.fontWeight(.bold)
					.color(Color("#000080"))
			case .mamma:
				// Mamma, in a speech bubble.
				Style()
					.vstack(spacing: .rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#fff0f5"))
					.border(Color("#aa3366"), width: .pixels(3), style: .double)
					.cornerRadius(.rootEm(1))
			case .mammaText:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
			case .desk:
				Style()
					.grid(minimumColumnWidth: .rootEm(16))
					.gap(.rootEm(1))
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .window:
				Style().frame(minWidth: 0)
			case .panel:
				Style().vstack(spacing: .rootEm(0.5))
			case .canvas:
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.background(.black)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .tableCanvas:
				// A finger cuts, tears, and pops instead of scrolling the page.
				Style()
					.aspectRatio(360.0 / 240.0)
					.cursor(.crosshair)
					.touchAction(.none)
			case .mailboxCanvas:
				// The mailbox only takes taps, so the page still scrolls over it.
				Style()
					.aspectRatio(360.0 / 240.0)
					.handCursor()
					.touchAction(.manipulation)
			case .stuffCanvas:
				// A finger draws, shines the flashlight, and cuts the hair instead of scrolling the page.
				Style()
					.aspectRatio(640.0 / 360.0)
					.cursor(.crosshair)
					.touchAction(.none)
			case .tabs:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .status:
				// No room before the first message, so no empty gray waits under the buttons, and then room for two lines, so the window does not jump between messages.
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.when(.state, is: "said") {
						$0.frame(minHeight: .lineHeight(2))
					}
			case .bankStatus:
				// Empty until there is news of the money, so it takes no room until then.
				Style()
					.frame(width: .percent(100))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
			case .dimmedWhenDisabled:
				// The small buttons of the page have no look of their own when they do nothing.
				Style().disabled {
					$0.opacity(0.5)
				}
			case .lens:
				// Over everything, and never in the way of the pointer.
				Style()
					.position(.fixed)
					.inset(0)
					.frame(width: .percent(100), height: .percent(100))
					.zIndex(2000)
					.allowsHitTesting(false)
			}
		}
	}

	enum Animations: KeyframeSet {
		case shake

		var keyframes: [Keyframe] {
			switch self {
			case .shake:
				[
					.from(Style().rotationEffect(.degrees(-12))),
					.to(Style().rotationEffect(.degrees(12))),
				]
			}
		}
	}
}
