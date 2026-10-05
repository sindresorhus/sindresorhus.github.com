import Elementary
import SiteKit

/**
Unimon, trading cards like the monster cards that every kid collected in 1999, with the GIFs of the page as the pictures. The visitor opens booster packs of five cards, with a rare holo card in some of them that shines where the pointer is, and collects them in a binder. Kevin from school offers trades for the extra cards, and mostly tries to rip the visitor off. Its script, `TradingCards.js`, opens the packs and keeps the binder in the browser.
*/
struct GeoCitiesTradingCards: ScriptedElement {
	static let script = ElementScript()

	/**
	A card of the game.
	*/
	struct Card {
		/**
		The kind of a card, which sets its color, like the energy types of the monster cards of 1999.
		*/
		enum Kind: String {
			case rainbow
			case water
			case electric
			case space
			case normal

			/**
			The color of the card.
			*/
			var style: Styles {
				switch self {
				case .rainbow:
					.rainbow
				case .water:
					.water
				case .electric:
					.electric
				case .space:
					.space
				case .normal:
					.normal
				}
			}
		}

		/**
		How often the card is in a pack. Every pack has one rare card or one more uncommon card, and a rare card is a holo card, which shines.
		*/
		enum Rarity: String {
			case common
			case uncommon
			case rare

			var symbol: String {
				switch self {
				case .common:
					"● Common"
				case .uncommon:
					"◆ Uncommon"
				case .rare:
					"★ Holo Rare"
				}
			}
		}

		let id: String
		let name: String
		let gif: GeoCitiesPage.GIF
		let kind: Kind
		let hitPoints: Int
		let attack: String
		let damage: String
		let text: String
		let rarity: Rarity
	}

	static let cards: [Card] = [
		Card(id: "glitter", name: "Glitter", gif: .unicorn, kind: .rainbow, hitPoints: 120, attack: "Glitter Blast", damage: "80", text: "Loves waffles. Afraid of the Y2K bug.", rarity: .rare),
		Card(id: "pegasus", name: "Pegasus", gif: .pegasus, kind: .rainbow, hitPoints: 100, attack: "Sky Gallop", damage: "60", text: "A unicorn that traded its horn for wings. Bad trade.", rarity: .rare),
		Card(id: "imac", name: "iMac", gif: .iMac, kind: .electric, hitPoints: 99, attack: "Bondi Blue Beam", damage: "60", text: "Comes in five fruity flavors. Has no floppy drive.", rarity: .rare),
		Card(id: "y2k", name: "Y2K Bug", gif: .bomb, kind: .electric, hitPoints: 2000, attack: "Millennium Crash", damage: "∞", text: "Ticks until midnight on December 31, 1999.", rarity: .rare),
		Card(id: "purple", name: "Purple Unicorn", gif: .purpleUnicorn, kind: .rainbow, hitPoints: 70, attack: "Sparkle", damage: "30", text: "Nobody has seen one. Except me.", rarity: .uncommon),
		Card(id: "gallop", name: "Galloping Unicorn", gif: .unicornGallop, kind: .rainbow, hitPoints: 80, attack: "Stampede", damage: "50", text: "Has never stopped running since 1996.", rarity: .uncommon),
		Card(id: "pig", name: "Flying Pig", gif: .flyingPig, kind: .normal, hitPoints: 40, attack: "When Pigs Fly", damage: "0", text: "This card does nothing. When pigs fly, it does.", rarity: .uncommon),
		Card(id: "wizard", name: "Wizard", gif: .wizard, kind: .space, hitPoints: 70, attack: "Abracadabra", damage: "30", text: "Knows HTML. Some say even JavaScript.", rarity: .uncommon),
		Card(id: "ufo", name: "UFO", gif: .ufo, kind: .space, hitPoints: 60, attack: "Beam Me Up", damage: "40", text: "Lives in the Area51 neighborhood of GeoCities.", rarity: .uncommon),
		Card(id: "alien", name: "Alien", gif: .alien, kind: .space, hitPoints: 50, attack: "Zap", damage: "30", text: "Came for the aliens game. Stayed for the waffles.", rarity: .common),
		Card(id: "dolphin", name: "Dolphin", gif: .dolphin, kind: .water, hitPoints: 60, attack: "Splash", damage: "20", text: "The unicorn of the sea.", rarity: .common),
		Card(id: "fish", name: "Fishbowl", gif: .fishbowl, kind: .water, hitPoints: 20, attack: "Bubble", damage: "10", text: "Remembers nothing for longer than a modem stays online.", rarity: .common),
		Card(id: "hamster", name: "Hamster", gif: .hamster, kind: .normal, hitPoints: 30, attack: "Hampster Dance", damage: "10×", text: "Dee doo dee doo. Dee doo dee doo.", rarity: .common),
		Card(id: "cow", name: "Cool Cow", gif: .coolCow, kind: .normal, hitPoints: 50, attack: "Moo", damage: "10", text: "Wears sunglasses indoors.", rarity: .common),
		Card(id: "monkey", name: "Monkey", gif: .monkey, kind: .normal, hitPoints: 50, attack: "Banana Toss", damage: "20", text: "Typed the first draft of my home page.", rarity: .common),
		Card(id: "toaster", name: "Toaster", gif: .toaster, kind: .electric, hitPoints: 40, attack: "Flying Toast", damage: "20", text: "Escaped from a screen saver.", rarity: .common),
		Card(id: "floppy", name: "Floppy", gif: .floppy, kind: .electric, hitPoints: 14, attack: "Save", damage: "1.44", text: "Holds 1.44 MB. Wow.", rarity: .common),
		Card(id: "skeleton", name: "Skeleton", gif: .skeleton, kind: .space, hitPoints: 30, attack: "Bone Dance", damage: "20", text: "Danced so long that nothing is left.", rarity: .common),
	]

	let project: Project

	var content: some HTML {
		h2 {
			"Unimon Trading Cards"
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Everybody at school collects Unimon cards! Open a pack, and maybe you get a rare holo card. Gotta collect ’em all: there are \(Self.cards.count) cards."
		}

		// In a block of its own, so it hides without scripts, as the pack and the binder set their own display.
		div {
			div {
				button(.part(Parts.pack), .type(.button)) {
					span {
						"UNIMON"
					}
					.style(Styles.packTitle)

					GeoCitiesPage.GIFImage(gif: .unicorn, alt: "", style: .gif, project: project)

					span {
						"Booster Pack ★ 5 Cards"
					}
					.style(Styles.packText)

					span {
						"Click to open!"
					}
					.style(Styles.packText)
				}
				.style(Styles.pack)

				div(.part(Parts.pull)) {}
					.accessibilityLabel("Cards from the pack")
					.style(Styles.pull)
			}
			.style(Styles.table)

			p(.part(Parts.status), .role("status")) {}
				.style(GeoCitiesPage.Styles.centeredText)

			div(.part(Parts.trade), .hidden) {
				p(.part(Parts.tradeText)) {}

				div {
					button(.part(Parts.tradeAccept), .type(.button)) {
						"Deal!"
					}
					.style(GeoCitiesPage.Styles.retroButton)

					button(.part(Parts.tradeDecline), .type(.button)) {
						"No way, Kevin"
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}
				.style(GeoCitiesPage.Styles.row)
			}
			.style(Styles.trade)

			h3(.part(Parts.binderTitle)) {
				"My Binder"
			}
			.style(Styles.binderTitle)

			ol(.part(Parts.binder)) {
				for card in Self.cards {
					li(.hook(Hooks.slot, value: card.id)) {
						"?"
					}
					.style(Styles.slot)
				}
			}
			.accessibilityLabel("Binder")
			.style(Styles.binder)
		}
		.style(Styles.game, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"Opening packs needs JavaScript. Kevin says that is cheating anyway."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)

		// The script copies the card that the pack gives, into the pack and the binder.
		for index in Self.cards.indices {
			template(.hook(Hooks.card, value: Self.cards[index].id)) {
				CardView(card: Self.cards[index], number: index + 1, project: project)
			}
		}
	}

	/**
	A card, as it is in a pack and in the binder.
	*/
	struct CardView: HTML {
		let card: Card
		let number: Int
		let project: Project

		var body: some HTML {
			div(.hook(Hooks.rarity, value: card.rarity.rawValue)) {
				p {
					strong {
						card.name
					}
					span {
						"\(card.hitPoints) HP"
					}
					.style(Styles.hitPoints)
				}
				.style(Styles.cardTop)

				div {
					GeoCitiesPage.GIFImage(gif: card.gif, alt: card.name, style: .gif, project: project)
				}
				.style(Styles.art)

				p {
					strong {
						card.attack
					}
					span {
						card.damage
					}
				}
				.style(Styles.cardTop)

				p {
					card.text
				}
				.style(Styles.flavor)

				p {
					"\(card.rarity.symbol) · \(number)/\(GeoCitiesTradingCards.cards.count)"
				}
				.style(Styles.rarity)

				if card.rarity == .rare {
					div {}
						.accessibilityHidden()
						.style(Styles.shine)
				}
			}
			.style(Styles.card, card.kind.style)
		}
	}

	/**
	Where the shine of a holo card is, from `-50%` to `50%`, which the script sets from the pointer over the card.
	*/
	static let shinePosition = StyleVariable<Length>("--unimon-shine")

	enum Parts: String, ElementPartSet {
		case pack
		case pull
		case status
		case trade
		case tradeText
		case tradeAccept
		case tradeDecline
		case binderTitle
		case binder
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A place in the binder, with the ID of its card.
		*/
		case slot = "data-unimon-slot"

		/**
		The template of a card, with its ID.
		*/
		case card = "data-unimon-card"

		/**
		How rare a card is.
		*/
		case rarity = "data-unimon-rarity"
	}

	enum Styles: ElementStyleSet {
		case root
		case game
		case table
		case pack
		case packTitle
		case packText
		case pull
		case card
		case rainbow
		case water
		case electric
		case space
		case normal
		case cardTop
		case hitPoints
		case art
		case flavor
		case rarity
		case shine
		case trade
		case binderTitle
		case binder
		case slot

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .game:
				Style().flowSpacing(.rootEm(0.75))
			case .table:
				Style()
					.vstack(alignment: .center, spacing: .rootEm(1))
			case .pack:
				// A shiny foil pack, which shakes when it opens.
				Style()
					.vstack(alignment: .center, spacing: .rootEm(0.25))
					.frame(width: .rootEm(10))
					.padding(.rootEm(0.75))
					.backgroundImage(.linearGradient("135deg", Color("#ff66cc"), Color("#9966ff"), Color("#33ccff"), Color("#66ffcc"), Color("#ffcc33")))
					.border(Color("#ffffff"), width: .pixels(3), style: .ridge)
					.cornerRadius(.rootEm(0.5))
					.shadow(Shadow(x: .pixels(4), y: .pixels(4), color: Color("#00000066")))
					.color(.white)
					.textShadow(Shadow(x: .pixels(2), y: .pixels(2), color: .black))
					.handCursor()
					.active {
						$0.scaleEffect(0.96)
					}
					.media(.allowsMotion) {
						$0.when(.state, is: "opening") {
							$0.animation(Animations.shake, .linear(duration: .seconds(0.1)).repeatForever())
						}
					}
					.disabled {
						$0
							.opacity(0.6)
							.cursor(GeoCitiesPage.arrowCursor, fallback: .default)
					}
			case .packTitle:
				Style()
					.fontFamily(GeoCitiesPage.impact)
					.font(.extraLarge2)
					.letterSpacing(.em(0.05))
			case .packText:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption, weight: .bold)
			case .pull:
				// The cards of the last pack, side by side where there is room.
				Style()
					.hstack(justification: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .card:
				// A card with a yellow edge, like the cards of 1999. Its kind gives it its color. A new card flips in.
				Style()
					.position(.relative)
					.overflow(.hidden)
					.vstack(spacing: .rootEm(0.25))
					.frame(width: .rootEm(7.5))
					.padding(.rootEm(0.3125))
					.border(Color("#f5d000"), width: .pixels(5))
					.cornerRadius(.rootEm(0.5))
					.shadow(Shadow(x: .pixels(2), y: .pixels(3), color: Color("#00000055")))
					.fontFamily(.system)
					.font(size: .rootEm(0.6875))
					.lineHeight(1.2)
					.color(.black)
					.media(.allowsMotion) {
						$0.when(.state, is: "new") {
							$0.animation(Animations.flip, .easeOut(duration: .seconds(0.5)))
						}
					}
			case .rainbow:
				Style().background(Color("#ffd6f0"))
			case .water:
				Style().background(Color("#cfe8ff"))
			case .electric:
				Style().background(Color("#fff3a8"))
			case .space:
				Style().background(Color("#e3d4ff"))
			case .normal:
				Style().background(Color("#f2f2e8"))
			case .cardTop:
				Style()
					.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(0.25))
					.margin(0)
			case .hitPoints:
				Style()
					.flexShrink(0)
					.fontWeight(.bold)
					.color(Color("#cc0000"))
			case .art:
				// The picture of the card, in a frame.
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(height: .rootEm(4.5))
					.overflow(.hidden)
					.background(.white)
					.border(Color("#b0b0b0"), width: .pixels(3), style: .ridge)
					.children("picture") {
						$0.frame(maxWidth: .percent(100), maxHeight: .percent(100))
					}
					.children("picture > img") {
						$0
							.frame(maxWidth: .percent(100), maxHeight: .rootEm(4))
							.objectFit(.contain)
					}
			case .flavor:
				Style()
					.margin(0)
					.italic()
					.color(Color("#444444"))
			case .rarity:
				Style()
					.margin(.top, .auto)
					.font(size: .rootEm(0.5625))
					.color(Color("#666666"))
			case .shine:
				// The rainbow foil of a holo card, which the script moves with the pointer.
				Style()
					.position(.absolute)
					.top(0)
					.bottom(0)
					.leading(.percent(-100))
					.frame(width: .percent(300))
					.allowsHitTesting(false)
					.backgroundImage(.linearGradient("110deg", .transparent, Color("#ff000055"), Color("#ffff0066"), Color("#00ff0055"), Color("#00ffff66"), Color("#0000ff55"), Color("#ff00ff66"), .transparent))
					.blendMode(.overlay)
					.offset(x: GeoCitiesTradingCards.shinePosition.value(default: .percent(0)))
			case .trade:
				// Kevin from school, in a speech bubble.
				Style()
					.flowSpacing(.rootEm(0.5))
					.padding(.rootEm(0.75))
					.background(Color("#ffffcc"))
					.border(.black, width: .pixels(2))
					.cornerRadius(.rootEm(1))
					.fontFamily(GeoCitiesPage.comicSans)
			case .binderTitle:
				Style()
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.body, weight: .bold)
					.textAlign(.center)
			case .binder:
				// The pages of a binder, with a pocket for each card.
				Style()
					.grid(columns: 6)
					.below(.tablet) {
						$0.gridColumns(3)
					}
					.gap(.rootEm(0.375))
					.margin(0)
					.padding(.rootEm(0.5))
					.background(Color("#202060"))
					.border(Color("#808080"), width: .pixels(3), style: .ridge)
					.textAlign(.center)
			case .slot:
				// An empty pocket shows a question mark. A pocket with a card shows its picture, its name, and how many the visitor has, with a gold edge for a holo card.
				Style()
					.vstack(alignment: .center, justification: .center, spacing: .rootEm(0.125))
					.frame(minHeight: .rootEm(6.5))
					.padding(.rootEm(0.25))
					.border(Color("#6060a0"), width: .pixels(2), style: .dashed)
					.fontFamily(GeoCitiesPage.comicSans)
					.font(.extraLarge2, weight: .bold)
					.color(Color("#6060a0"))
					.overflow(.hidden)
					.children("picture > img") {
						$0
							.frame(maxWidth: .percent(100), maxHeight: .rootEm(3.5))
							.objectFit(.contain)
					}
					.when(.state, is: "filled") {
						$0
							.background(Color("#f2f2e8"))
							.border(Color("#f5d000"), width: .pixels(3))
							.fontFamily(.system)
							.textStyle(.caption, weight: .bold)
							.lineHeight(1.1)
							.color(.black)
					}
					.when(Hooks.rarity, is: "rare") {
						$0.backgroundImage(.linearGradient("135deg", Color("#fff6c0"), Color("#ffd6f0"), Color("#cfe8ff")))
					}
			}
		}
	}

	enum Animations: KeyframeSet {
		case shake
		case flip

		var keyframes: [Keyframe] {
			switch self {
			case .shake:
				[
					.from(Style().rotationEffect(.degrees(-4))),
					.to(Style().rotationEffect(.degrees(4))),
				]
			case .flip:
				[
					.from(Style().transform("perspective(600px) rotateY(90deg)").opacity(0)),
					.to(Style().transform("perspective(600px) rotateY(0deg)").opacity(1)),
				]
			}
		}
	}
}
