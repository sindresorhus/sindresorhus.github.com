import Elementary
import SiteKit

/**
A music composer like the one of a painting game for game consoles from 1992: the visitor picks a stamp, like a unicorn, a waffle, or a cat, and stamps it on a staff, where each stamp is an instrument and its height is the note. When the song plays, Glitter runs along the staff. It has an eraser, a tempo, and two songs to start from. Its script draws the staff on a canvas, plays it through the sound card of the Music Room, and keeps the song in the browser. For visitors who prefer reduced motion, Glitter stays home, and the column that plays lights up instead.
*/
struct GeoCitiesStampComposer: ScriptedElement {
	static let script = ElementScript()

	let project: Project

	/**
	The stamps, by their ID in the script, with their picture and the instrument they play.
	*/
	static let stamps: [(id: String, emoji: String, title: String)] = [
		("unicorn", "🦄", "Unicorn (piano)"),
		("waffle", "🧇", "Waffle (marimba)"),
		("cat", "🐱", "Cat (meow)"),
		("hamster", "🐹", "Hamster (squeak)"),
		("dog", "🐶", "Dog (woof)"),
		("star", "⭐", "Star (bell)"),
		("floppy", "💾", "Floppy drive (buzz)"),
		("drum", "🥁", "Drum"),
	]

	/**
	The songs to start from, by their ID in the script.
	*/
	static let songs: [(id: String, title: String)] = [
		("twinkle", "Twinkle Twinkle"),
		("hop", "Hamster Hop"),
	]

	var content: some HTML {
		h2 {
			GeoCitiesPage.GIFImage(gif: .musicStaff, alt: "", style: .gif, project: project)
			" Stamp Composer "
			GeoCitiesPage.GIFImage(gif: .musicStaff, alt: "", style: .gif, project: project)
		}
		.style(GeoCitiesPage.Styles.heading, GeoCitiesPage.Styles.centeredText)

		p {
			"Like the music maker of the old painting game, but with my animals! Pick a stamp, then click the staff to put it on a note. Higher is higher. Press Play and Glitter runs along and plays them. Use the keyboard too: arrow keys move, Enter stamps, and Delete erases."
		}

		div {
			div {
				for (index, stamp) in Self.stamps.enumerated() {
					button(.type(.button), .hook(Hooks.stamp, value: stamp.id), .ariaPressed(index == 0)) {
						stamp.emoji
					}
					.attributes(.hook(.state, value: "on"), when: index == 0)
					.accessibilityLabel(stamp.title)
					.help(stamp.title)
					.style(Styles.stamp)
				}

				button(.type(.button), .hook(Hooks.stamp, value: "eraser"), .ariaPressed(false)) {
					"🧽"
				}
				.accessibilityLabel("Eraser")
				.help("Eraser")
				.style(Styles.stamp)
			}
			.attributes(.role("group"))
			.accessibilityLabel("Stamps")
			.style(Styles.stamps)

			div {
				div(.part(Parts.runner)) {
					"🦄"
				}
				.accessibilityHidden()
				.style(Styles.runner)

				canvas(.part(Parts.staff), .width(1872), .height(340), .tabindex(0), .role("application")) {}
					.accessibilityLabel("Staff. Arrow keys move, Enter stamps, Delete erases.")
					.style(Styles.staff)
			}
			.style(Styles.scroller)

			div {
				button(.part(Parts.play), .type(.button)) {
					"▶ Play"
				}
				.style(GeoCitiesPage.Styles.retroButton)

				for song in Self.songs {
					button(.type(.button), .hook(Hooks.song, value: song.id)) {
						song.title
					}
					.style(GeoCitiesPage.Styles.retroButton)
				}

				button(.part(Parts.clear), .type(.button)) {
					"Clear"
				}
				.style(GeoCitiesPage.Styles.retroButton)
			}
			.style(GeoCitiesPage.Styles.formRow)

			div {
				label {
					"🐢 Tempo "
					input(.part(Parts.tempo), .type(.range), .min(60), .max(300), .step(10), .value("150"))
					" 🐇"
				}
				.style(Styles.tempo)

				GeoCitiesMusicVolume()
			}
			.style(GeoCitiesPage.Styles.formRow)

			p(.part(Parts.status), .role("status")) {}
				.style(GeoCitiesPage.Styles.caption)
		}
		.style(Styles.box, GeoCitiesPage.Styles.scriptingOnly)
	}

	enum Parts: String, ElementPartSet {
		case runner
		case staff
		case play
		case clear
		case tempo
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		A button of a stamp, by its ID, or `eraser`.
		*/
		case stamp = "data-stamps-stamp"

		/**
		A button that loads a song, by its ID.
		*/
		case song = "data-stamps-song"
	}

	enum Styles: ElementStyleSet {
		case root
		case box
		case stamps
		case stamp
		case scroller
		case runner
		case staff
		case tempo

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.section.style
			case .box:
				// A light blue box with a thick edge, like the screens of that painting game.
				Style()
					.flowSpacing(.rootEm(0.75))
					.padding(.rootEm(0.75))
					.background(Color("#cfe8ff"))
					.border(Color("#ff6f3c"), width: .pixels(4))
					.cornerRadius(.rootEm(0.75))
			case .stamps:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .stamp:
				Style()
					.hstack(alignment: .center, justification: .center)
					.frame(width: .rootEm(2.5), height: .rootEm(2.5))
					.background(.white)
					.border(Color("#888"), width: .pixels(2), style: .outset)
					.cornerRadius(.rootEm(0.5))
					.font(.large)
					.handCursor()
					.when(.state, is: "on") {
						$0
							.background(Color("#ffeb3b"))
							.border(Color("#ff6f3c"), width: .pixels(3))
					}
			case .scroller:
				// The staff is wider than a phone, so it scrolls sideways inside its box, like in that painting game.
				Style()
					.position(.relative)
					.padding(.top, .rootEm(1.75))
					.background(.white)
					.border(Color("#888"), width: .pixels(2), style: .inset)
					.overflow(horizontal: .auto)
			case .runner:
				// Glitter, who runs along the top of the staff while the song plays, as the script moves it.
				Style()
					.position(.absolute)
					.top(0)
					.leading(0)
					.font(.large)
					.lineHeight(1)
					.allowsHitTesting(false)
					.reducedMotion {
						$0.hidden()
					}
			case .staff:
				Style()
					.display(.block)
					.frame(width: .pixels(936), height: .pixels(170))
					.handCursor()
					.focusVisible {
						$0.focusRing(Color("#ff6f3c"), width: .pixels(3), offset: .pixels(-3))
					}
			case .tempo:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			}
		}
	}
}
