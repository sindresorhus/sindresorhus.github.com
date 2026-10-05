import Elementary
import Foundation
import SiteKit

/**
The two treasures in my jacket pocket in 1999: a Kinderegg from the Narvesen kiosk and my light-up yo-yo. Its script, `KinderEgg.js`, draws both on canvases. Mamma’s rule is one egg a week, so the visitor buys the egg of the week at Narvesen, begs Mamma for one more (she says no in many ways, sends me to Pappa, who sends me back to Mamma, and only sometimes gives in), and waits for Saturday for the next one. The egg is tactile: the foil is peeled by dragging over it and tears off in strips that crinkle and fall, the chocolate egg cracks and breaks in two halves with crumbs, the halves are eaten in bites, and the yellow plastic capsule inside opens by twisting it around. Out come the parts and the tiny folded paper, which unfolds one fold at a time to the pictograms of the steps and the warning for children under 3. The parts are dragged together in the order of the paper (a race car with stickers, a spinning top, a propeller plane, a puzzle of 4 pieces, or a figure of the Happy Hippos or of the crocodiles with its own little thing to hold), and then the toy plays: the pull-back car drives across the table, the top spins until it falls over, the plane flies, and the figure hops. Lillesøster sometimes wants the new toy, and if I give it to her, Mamma gives me an extra egg (once a week). The toys go on my shelf, with slots for the whole series of the hippos and the crocodiles, the rare golden hippo that everybody wants, the doubles, and the same puzzle over and over, and Trond trades for my doubles with offers that are often bad. The yo-yo hangs from my finger on a real string: a throw down (a drag down, or a key) spins it up, a tug at the bottom brings it back, and a tug that is too late finds it dead on the string. It sleeps at the bottom and slows down, its LEDs flash while it spins, and it walks the dog on the floor, goes around the world, and rocks the baby in a cradle of string, while a trick list unlocks the next tricks. A trick with too little spin tangles the string in knots to pick open, the string wears out and snaps after many throws, and Trond’s Yomega Brain, which comes back by itself, can be borrowed. Nothing makes a sound until the visitor turns on the sound, nothing moves by itself for visitors who prefer reduced motion (each step shows as a still picture), and the shelf and the tricks are kept in the browser.
*/
struct GeoCitiesKinderEgg: ScriptedElement {
	static let script = ElementScript()

	var content: some HTML {
		h2 {
			"What’s in My Pocket? A Kinderegg and a Yo-Yo!"
		}
		.style(GeoCitiesPage.Styles.heading)

		p {
			"Every Saturday I run to the Narvesen kiosk at the bus stop with 9 kroner for a Kinderegg: chocolate outside, a SURPRISE inside. Mamma’s rule is one egg a week (“Du får hull i tennene!”), so make it last. And everybody at school has a yo-yo now. Mine lights up when it spins!"
		}

		div {
			button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
				"🔊 Sound (Crinkle! Whirr!)"
			}
			.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
		}
		.style(GeoCitiesPage.Styles.buttonRow, GeoCitiesPage.Styles.scriptingOnly)

		div {
			// The shelf is under the egg, as its toys come from the eggs, and the tall yo-yo has a column of its own next to them.
			div {
				EggWindow()
				ShelfWindow()
			}
			.style(Styles.eggColumn)

			YoyoWindow()
		}
		.style(Styles.toys, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"My Kinderegg and my yo-yo need JavaScript. And chocolate."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The kitchen table with the egg of the week, and what I do with it.
	*/
	private struct EggWindow: HTML {
		var body: some HTML {
			section(.tabindex(-1)) {
				h3 {
					"My Kinderegg"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					p(.part(Parts.week)) {
						"UKE 14 · 1999 · 1 EGG LEFT THIS WEEK"
					}
					.style(GeoCitiesPage.Styles.lcd, Styles.lcdLine)

					canvas(.part(Parts.egg), .width(320), .height(260), .tabindex(0), .role("application")) {}
						.accessibilityLabel("The kitchen table with my Kinderegg. Drag over the foil to peel it, click to break and to bite, drag around the capsule to twist it open, and drag the parts together. Or use the keys: Enter or Space does the next step, B takes a bite, the number keys add a part, Escape folds away the paper, and P plays with the new toy.")
						.style(Styles.canvas, Styles.eggCanvas)

					EggButtons()
					SisterPrompt()

					p(.part(Parts.eggStatus), .role("status")) {
						"Mamma gave me 9 kroner. Off to Narvesen!"
					}
					.style(Styles.status)
				}
				.style(GeoCitiesPage.Styles.windowBody, Styles.stack)
			}
			.style(GeoCitiesPage.Styles.window, Styles.window)
		}
	}

	/**
	The next step of the egg, a bite of the chocolate or a play with the new toy, and the trips to Narvesen and to Mamma.
	*/
	private struct EggButtons: HTML {
		var body: some HTML {
			div {
				button(.part(Parts.eggAction), .type(.button)) {
					"🏪 Buy a Kinderegg at Narvesen"
				}
				.style(GeoCitiesPage.Styles.retroButton, Styles.wide)

				button(.part(Parts.extra), .type(.button), .hidden) {
					"🍫 Take a Bite"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.beg), .type(.button)) {
					"🥺 Ask Mamma for One More"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.saturday), .type(.button)) {
					"📅 Wait for Saturday"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
	}

	/**
	Lillesøster at the door, who wants my new toy.
	*/
	private struct SisterPrompt: HTML {
		var body: some HTML {
			div(.part(Parts.sister), .hidden) {
				p(.part(Parts.sisterText), .role("status")) {}
					.style(Styles.speech)

				div {
					button(.part(Parts.sisterGive), .type(.button)) {
						"🎁 Give It to Her"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.part(Parts.sisterKeep), .type(.button)) {
						"🙅 “Nei! Den er MIN!”"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.style(Styles.prompt)
		}
	}

	/**
	The yo-yo on my finger, its buttons, and the trick list.
	*/
	private struct YoyoWindow: HTML {
		var body: some HTML {
			section(.tabindex(-1)) {
				h3 {
					"My Light-Up Yo-Yo"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					p(.part(Parts.string)) {
						"STRING: NEW · THROWS: 0"
					}
					.style(GeoCitiesPage.Styles.lcd, Styles.lcdLine)

					canvas(.part(Parts.yoyo), .width(320), .height(320), .tabindex(0), .role("application")) {}
						.accessibilityLabel("My yo-yo on my finger. Drag down to throw it (further is harder), and click or tap to tug it back. Or use the keys: Down Arrow or S throws, Up Arrow or Enter tugs, Space throws or tugs, D walks the dog, W goes around the world, B rocks the baby, and U untangles.")
						.style(Styles.canvas, Styles.yoyoCanvas)

					YoyoButtons()

					p(.part(Parts.yoyoStatus), .role("status")) {
						"Drag down on the yo-yo to throw it. Tug to get it back!"
					}
					.style(Styles.status)

					TrickList()
				}
				.style(GeoCitiesPage.Styles.windowBody, Styles.stack)
			}
			.style(GeoCitiesPage.Styles.window, Styles.window)
		}
	}

	/**
	The throw, the tug, the three tricks, and the care of the string.
	*/
	private struct YoyoButtons: HTML {
		var body: some HTML {
			div {
				button(.part(Parts.throwDown), .type(.button)) {
					"⬇️ Throw"
				}
				.style(GeoCitiesPage.Styles.retroButton, Styles.bigButton)

				button(.part(Parts.tug), .type(.button)) {
					"⬆️ Tug!"
				}
				.style(GeoCitiesPage.Styles.retroButton, Styles.bigButton)
			}
			.style(Styles.pair)

			div {
				button(.part(Parts.walkDog), .type(.button)) {
					"🐕 Walk the Dog"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.aroundWorld), .type(.button)) {
					"🌍 Around the World"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.rockBaby), .type(.button)) {
					"👶 Rock the Baby"
				}
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(GeoCitiesPage.Styles.buttonRow)

			div {
				button(.part(Parts.untangle), .type(.button), .hidden) {
					"🪢 Pick at the Knot"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.urgent)

				button(.part(Parts.newString), .type(.button)) {
					"🧵 New String"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				button(.part(Parts.swap), .type(.button), .ariaPressed(false)) {
					"🧠 Borrow Trond’s Yomega Brain"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.toggle)
			}
			.style(GeoCitiesPage.Styles.buttonRow)
		}
	}

	/**
	The tricks I can do, and the ones that I still have to learn.
	*/
	private struct TrickList: HTML {
		private static let tricks = [
			("throw", "Throw Down", "Throw it and tug it back"),
			("sleeper", "The Sleeper", "Let it spin at the bottom for 3 seconds"),
			("long", "Long Sleeper", "8 seconds! Trond can do 6"),
			("dog", "Walk the Dog", "Let it roll on the floor, then tug"),
			("world", "Around the World", "A big loop around my finger"),
			("baby", "Rock the Baby", "Swing it in a cradle of string"),
			("ten", "Ten in a Row", "10 tricks without a knot or a dead yo-yo"),
		]

		var body: some HTML {
			div {
				h4 {
					"My Trick List"
				}
				.style(Styles.subheading)

				ul {
					for trick in Self.tricks {
						li(.hook(Hooks.trick, value: trick.0)) {
							strong {
								trick.1
							}
							" "
							span {
								trick.2
							}
						}
						.style(Styles.trick)
					}
				}
				.accessibilityLabel("My trick list")
				.style(Styles.trickList)
			}
		}
	}

	/**
	The shelf over my bed, with the toys of the eggs, the doubles, and Trond’s offers.
	*/
	private struct ShelfWindow: HTML {
		var body: some HTML {
			section(.tabindex(-1)) {
				h3 {
					"My Shelf"
				}
				.style(GeoCitiesPage.Styles.titleBar)

				div {
					canvas(.part(Parts.shelf), .width(320), .height(250), .role("img")) {}
						.accessibilityLabel("The shelf over my bed with my Kinderegg toys: a row for the Happy Hippos, a row for the crocodiles, and a row for the other toys.")
						.style(Styles.canvas, Styles.shelfCanvas)

					p(.part(Parts.shelfCount)) {}
						.style(GeoCitiesPage.Styles.lcd, Styles.lcdLine)

					h4 {
						"Doubles to Trade with Trond"
					}
					.style(Styles.subheading)

					ul(.part(Parts.doubles)) {}
						.accessibilityLabel("My doubles")
						.style(Styles.doubles)

					OfferPrompt()

					p(.part(Parts.shelfStatus), .role("status")) {}
						.style(Styles.status)
				}
				.style(GeoCitiesPage.Styles.windowBody, Styles.stack)
			}
			.style(GeoCitiesPage.Styles.window, Styles.window)
		}
	}

	/**
	Trond’s offer for one of my doubles.
	*/
	private struct OfferPrompt: HTML {
		var body: some HTML {
			div(.part(Parts.offer), .hidden) {
				p(.part(Parts.offerText), .role("status")) {}
					.style(Styles.speech)

				div {
					button(.part(Parts.accept), .type(.button)) {
						"🤝 Byttes! (Deal!)"
					}
					.style(GeoCitiesPage.Styles.smallButton)

					button(.part(Parts.decline), .type(.button)) {
						"🙄 No Way"
					}
					.style(GeoCitiesPage.Styles.smallButton)
				}
				.style(GeoCitiesPage.Styles.buttonRow)
			}
			.style(Styles.prompt)
		}
	}

	enum Parts: String, ElementPartSet {
		case sound

		case week
		case egg
		case eggAction
		case extra
		case beg
		case saturday
		case sister
		case sisterText
		case sisterGive
		case sisterKeep
		case eggStatus

		case string
		case yoyo
		case throwDown
		case tug
		case walkDog
		case aroundWorld
		case rockBaby
		case untangle
		case newString
		case swap
		case yoyoStatus

		case shelf
		case shelfCount
		case doubles
		case offer
		case offerText
		case accept
		case decline
		case shelfStatus
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A trick of the trick list, with its ID in the script, which the script marks as learned or locked.
		*/
		case trick = "data-kinder-egg-trick"

		/**
		The trade button of a double, which the script makes, with the ID of the toy.
		*/
		case trade = "data-kinder-egg-trade"
	}

	enum Styles: ElementStyleSet {
		case root
		case toys
		case eggColumn
		case window
		case stack
		case canvas
		case eggCanvas
		case yoyoCanvas
		case shelfCanvas
		case lcdLine
		case toggle
		case urgent
		case wide
		case pair
		case bigButton
		case status
		case prompt
		case speech
		case subheading
		case trickList
		case trick
		case doubles

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .toys:
				Style()
					.grid(minimumColumnWidth: .rootEm(18))
					.gap(.rootEm(1.25))
					.alignItems(.start)
					.children("*") {
						$0.frame(minWidth: 0)
					}
			case .eggColumn:
				Style().vstack(spacing: .rootEm(1.25))
			case .window:
				Style().frame(minWidth: 0)
			case .stack:
				Style().vstack(spacing: .rootEm(0.625))
			case .canvas:
				// A finger on the yo-yo throws it, instead of scrolling the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.border(Color("#808080"), width: .pixels(2), style: .inset)
					.background(Color("#f3e3c3"))
					.touchAction(.none)
					.cursor(.pointer)
					.focusVisible {
						$0.focusRing(Color("#000080"), width: .pixels(2), offset: .pixels(2))
					}
			case .eggCanvas:
				// The kiosk, the cracking, and the bites only take taps, so a finger can scroll the page over the table then. The foil, the capsule, and the parts take drags.
				Style()
					.aspectRatio(320.0 / 260.0)
					.touchAction(.manipulation)
					.when(.state, is: "drag") {
						$0.touchAction(.none)
					}
			case .yoyoCanvas:
				Style().aspectRatio(1)
			case .shelfCanvas:
				// The shelf only shows the toys, so the page scrolls over it.
				Style()
					.aspectRatio(320.0 / 250.0)
					.touchAction(.auto)
					.cursor(.default)
			case .lcdLine:
				Style()
					.margin(0)
					.textStyle(.caption, weight: .bold)
					.textAlign(.center)
					.overflowWrap(.anywhere)
			case .toggle:
				Style()
					.frame(minHeight: .rootEm(2.25))
					.when(.state, is: "on") {
						$0
							.background(Color("#ffff99"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .urgent:
				Style()
					.frame(minHeight: .rootEm(2.25))
					.background(Color("#ffcc66"))
			case .wide:
				Style().frame(width: .percent(100), minHeight: .rootEm(2.5))
			case .pair:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.5))
			case .bigButton:
				Style().frame(minHeight: .rootEm(2.75))
			case .status:
				Style()
					.frame(minHeight: .lineHeight(3))
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .prompt:
				// A yellow note, like the speech of a comic, for Lillesøster and for Trond.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(.rootEm(0.5))
					.background(Color("#ffffcc"))
					.border(Color("#000000"), width: .pixels(2), style: .dashed)
					.color(.black)
			case .speech:
				Style()
					.margin(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
			case .subheading:
				Style()
					.margin(top: .rootEm(0.25), bottom: .rootEm(0.25))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
			case .trickList:
				// Lined paper from my school planner, where I keep my tricks.
				Style()
					.vstack(spacing: 0)
					.margin(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.75))
					.backgroundImage(.linearGradient("to bottom", Color("#fffef6"), Color("#fdf8e2")))
					.border(.leading, Color("#e05555"), width: .pixels(3))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption)
					.color(Color("#333344"))
			case .trick:
				Style()
					.padding(vertical: .rootEm(0.125), horizontal: 0)
					.border(.bottom, Color("#9ec3e6"), width: .pixels(1))
					.overflowWrap(.anywhere)
					.opacity(0.85)
					.children("strong") {
						$0.display(.block)
					}
					.when(.state, is: "learned") {
						$0
							.color(Color("#006600"))
							.opacity(1)
					}
					.when(.state, is: "locked") {
						$0
							.color(Color("#888888"))
							.opacity(0.7)
					}
			case .doubles:
				Style()
					.vstack(spacing: .rootEm(0.375))
					.margin(0)
					.padding(0)
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.children("li") {
						$0
							.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.5))
							.flexWrap()
							.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
							.background(Color("#ffffff"))
							.border(Color("#808080"), width: .pixels(1), style: .solid)
					}
					.children("li button") {
						$0
							.frame(minHeight: .rootEm(2.25))
							.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
							.background(GeoCitiesPage.windowGray)
							.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
							.fontFamily(GeoCitiesPage.comicSans)
							.textStyle(.caption, weight: .bold)
							.color(.black)
							.handCursor()
					}
			}
		}
	}
}
