import Elementary
import SiteKit

/**
Three toys that told the future in 1999, side by side: a Magic 8-Ball that shakes before it answers, a paper fortune teller (a cootie catcher) that opens and closes for each letter of a color and each number, like the ones folded in every school yard, and a mood ring that changes color with how calmly the pointer moves over it. Its script, `FortuneToys.js`, runs them. The 8-Ball does not shake for visitors who prefer reduced motion, and the paper opens without moving.
*/
struct GeoCitiesFortuneToys: ScriptedElement {
	static let script = ElementScript()

	/**
	The four colors on the outside of the paper fortune teller, from the top left, with the numbers inside each, the first shown when it opens one way, and the second when it opens the other way.
	*/
	static let flaps: [(color: String, numbers: (Int, Int), style: Styles)] = [
		("Red", (1, 2), .topLeft),
		("Blue", (3, 4), .topRight),
		("Green", (8, 7), .bottomLeft),
		("Yellow", (6, 5), .bottomRight),
	]

	var content: some HTML {
		div {
			eightBall
			fortuneTeller
			moodRing
		}
		.style(GeoCitiesPage.Styles.columns)

		p {
			"My Magic 8-Ball, paper fortune teller, and mood ring need JavaScript to see your future."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	private var eightBall: some HTML {
		section {
			h2 {
				"Magic 8-Ball"
			}
			.style(Styles.title)

			form(.part(Parts.eightBallForm)) {
				label(.for("geocities-eight-ball-question")) {
					"Ask a yes-or-no question:"
				}
				.style(GeoCitiesPage.Styles.label)

				input(.id("geocities-eight-ball-question"), .part(Parts.question), .type(.text), .autocomplete("off"), .maxlength(80), .placeholder("Will I get an iMac for Christmas?"))
					.style(GeoCitiesPage.Styles.field)

				div(.part(Parts.ball)) {
					div {
						p(.part(Parts.answer), .role("status"), .hook(.state, value: "eight")) {
							"8"
						}
						.style(Styles.answer)
					}
					.style(Styles.ballWindow)
				}
				.style(Styles.ball)

				button(.type(.submit)) {
					"Shake It!"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(Styles.toy)
		}
		.style(Styles.card, GeoCitiesPage.Styles.scriptingOnly)
	}

	private var fortuneTeller: some HTML {
		section {
			h2 {
				"Paper Fortune Teller"
			}
			.style(Styles.title)

			div {
				div {
					for flap in Self.flaps {
						div(.hook(Hooks.flap, value: flap.color)) {
							span {
								flap.color
							}
							.style(Styles.flapColor)

							span {
								"\(flap.numbers.0)"
							}
							.style(Styles.flapNumber, Styles.numberA)

							span {
								"\(flap.numbers.1)"
							}
							.style(Styles.flapNumber, Styles.numberB)
						}
						.style(Styles.flap, flap.style)
					}
				}
				.accessibilityHidden()
				.style(Styles.paper)

				p(.part(Parts.catcherStatus), .role("status")) {
					"Pick a color!"
				}
				.style(GeoCitiesPage.Styles.centeredText)

				div(.part(Parts.choices)) {
					for flap in Self.flaps {
						button(.type(.button), .custom(name: "value", value: flap.color)) {
							flap.color
						}
						.style(GeoCitiesPage.Styles.retroButton)
					}
				}
				.style(GeoCitiesPage.Styles.row)

				// The script adds a copy for each choice after the colors.
				template(.part(Parts.choiceTemplate)) {
					button(.type(.button)) {}
						.style(GeoCitiesPage.Styles.retroButton)
				}
			}
			.style(Styles.toy)
		}
		.style(Styles.card, GeoCitiesPage.Styles.scriptingOnly)
	}

	private var moodRing: some HTML {
		section {
			h2 {
				"Mood Ring"
			}
			.style(Styles.title)

			div {
				p {
					"Move your mouse or finger slowly over the ring. It knows how you feel."
				}
				.style(GeoCitiesPage.Styles.caption)

				div(.part(Parts.ring)) {
					div {}
						.style(Styles.stone)
				}
				.accessibilityHidden()
				.style(Styles.ring)

				p(.part(Parts.mood), .role("status")) {
					"Mood: Unknown (black)"
				}
				.style(GeoCitiesPage.Styles.centeredText)

				button(.part(Parts.warm), .type(.button)) {
					"Hold It in Your Hand"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(Styles.toy)
		}
		.style(Styles.card, GeoCitiesPage.Styles.scriptingOnly)
	}

	/**
	The color of the stone of the mood ring, which the script sets.
	*/
	static let moodColor = StyleVariable<Color>("--mood-ring-color")

	enum Parts: String, ElementPartSet {
		case eightBallForm
		case question
		case ball
		case answer
		case catcherStatus
		case choices
		case choiceTemplate
		case ring
		case mood
		case warm
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A flap of the paper fortune teller, with its color.
		*/
		case flap = "data-catcher-flap"
	}

	enum Styles: ElementStyleSet {
		case root
		case card
		case title
		case toy
		case ball
		case ballWindow
		case answer
		case paper
		case flap
		case topLeft
		case topRight
		case bottomLeft
		case bottomRight
		case flapColor
		case flapNumber
		case numberA
		case numberB
		case ring
		case stone

		var style: Style {
			switch self {
			case .root:
				// The three cards stay sections of the page, so the pets stand on each of them, as if the element was not there.
				Style().display(.contents)
			case .card:
				// A box with a dashed edge, like a cut-out coupon.
				Style()
					.padding(.rootEm(0.75))
					.background(Color("#ffffee"))
					.border(Color("#800080"), width: .pixels(2), style: .dashed)
			case .title:
				Style()
					.margin(.bottom, .rootEm(0.5))
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.extraLarge, weight: .bold)
					.textAlign(.center)
					.color(Color("#800080"))
			case .toy:
				Style().vstack(alignment: .center, spacing: .rootEm(0.5))
			case .ball:
				// A black ball with a shine, and a dark blue window in the middle. It shakes while it thinks.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(10), height: .rootEm(10))
					.backgroundImage(.radialGradient("circle at 35% 30%", Color("#666666"), Color("#111111"), Color("#000000")))
					.cornerRadius(.percent(50))
					.shadow(Shadow(x: .pixels(3), y: .pixels(5), color: Color("#00000066")))
					.media(.allowsMotion) {
						$0.when(.state, is: "shaking") {
							$0.animation(Animations.shake, .linear(duration: .seconds(0.12)).repeatForever())
						}
					}
			case .ballWindow:
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(5), height: .rootEm(5))
					.padding(.rootEm(0.375))
					.background(Color("#0a0a40"))
					.border(Color("#333333"), width: .pixels(3))
					.cornerRadius(.percent(50))
			case .answer:
				// The answer on the blue triangle that floats up in the window, or the 8 before the first question.
				Style()
					.margin(0)
					.fontFamily(.system)
					.font(size: .rootEm(0.625))
					.fontWeight(.bold)
					.lineHeight(1.1)
					.textAlign(.center)
					.textCase(.uppercase)
					.color(Color("#88bbff"))
					.media(.allowsMotion) {
						$0.transition(.opacity, animation: .easeIn(duration: .seconds(0.8)))
					}
					.when(.state, is: "hidden") {
						$0.opacity(0)
					}
					.when(.state, is: "eight") {
						$0
							.fontFamily(GeoCitiesPage.times)
							.font(size: .rootEm(2.5))
							.color(.white)
					}
			case .paper:
				// The paper fortune teller from above: four flaps, which move apart to one side or the other as it opens.
				Style()
					.grid(columns: 2)
					.gap(.pixels(2))
					.frame(width: .rootEm(10), height: .rootEm(10))
					.margin(.rootEm(0.75))
			case .flap:
				Style()
					.position(.relative)
					.hstack(alignment: .center, justification: .center)
					.border(Color("#999999"))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.media(.allowsMotion) {
						$0.transition(.offset, animation: .easeInOut(duration: .seconds(0.25)))
					}
			case .topLeft:
				Style()
					.background(Color("#ee3333"))
					.cornerRadius(.rootEm(0.25))
					.when(.state, is: "a") {
						$0.offset(x: .rootEm(-0.75))
					}
					.when(.state, is: "b") {
						$0.offset(y: .rootEm(-0.75))
					}
			case .topRight:
				Style()
					.background(Color("#3366ff"))
					.cornerRadius(.rootEm(0.25))
					.when(.state, is: "a") {
						$0.offset(x: .rootEm(0.75))
					}
					.when(.state, is: "b") {
						$0.offset(y: .rootEm(-0.75))
					}
			case .bottomLeft:
				Style()
					.background(Color("#33bb33"))
					.cornerRadius(.rootEm(0.25))
					.when(.state, is: "a") {
						$0.offset(x: .rootEm(-0.75))
					}
					.when(.state, is: "b") {
						$0.offset(y: .rootEm(0.75))
					}
			case .bottomRight:
				Style()
					.background(Color("#ffdd00"))
					.cornerRadius(.rootEm(0.25))
					.when(.state, is: "a") {
						$0.offset(x: .rootEm(0.75))
					}
					.when(.state, is: "b") {
						$0.offset(y: .rootEm(0.75))
					}
			case .flapColor:
				// The color shows while the paper is closed, and the numbers inside while it is open.
				Style()
					.when(ancestorHas: .state) {
						$0.hidden()
					}
			case .flapNumber:
				// Hidden after the stack, so it wins, until the paper opens the way of the number.
				Style()
					.hstack(alignment: .center, justification: .center)
					.hidden()
					.frame(width: .rootEm(2.5), height: .rootEm(2.5))
					.background(.white)
					.cornerRadius(.percent(50))
					.font(.extraLarge, weight: .bold)
			case .numberA:
				Style().when(ancestorHas: .state, is: "a") {
					$0.display(.flex)
				}
			case .numberB:
				Style().when(ancestorHas: .state, is: "b") {
					$0.display(.flex)
				}
			case .ring:
				// A silver ring, and the stone on it, which the script colors.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(9), height: .rootEm(9))
					.border(Color("#c0c0c0"), width: .rootEm(0.75), style: .ridge)
					.cornerRadius(.percent(50))
					.touchAction(.none)
			case .stone:
				Style()
					.frame(width: .rootEm(5), height: .rootEm(3.75))
					.background(GeoCitiesFortuneToys.moodColor.value(default: Color("#111111")))
					.border(Color("#c0c0c0"), width: .pixels(4), style: .outset)
					.cornerRadius(.percent(50))
					.shadow(Shadow(y: 0, blur: .rootEm(1), color: GeoCitiesFortuneToys.moodColor.value(default: Color("#111111"))))
					.media(.allowsMotion) {
						$0.transition(.backgroundColor, .shadow, animation: .easeInOut(duration: .seconds(0.6)))
					}
			}
		}
	}

	enum Animations: KeyframeSet {
		case shake

		var keyframes: [Keyframe] {
			switch self {
			case .shake:
				[
					.from(Style().offset(x: .pixels(-6), y: .pixels(3)).rotationEffect(.degrees(-6))),
					.to(Style().offset(x: .pixels(6), y: .pixels(-3)).rotationEffect(.degrees(6))),
				]
			}
		}
	}
}
