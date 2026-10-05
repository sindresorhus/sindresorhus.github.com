import Elementary
import Foundation
import SiteKit

/**
Sindre’s Wurms ’99, a game like Worms Armageddon (Team17, 1999), the turn-based artillery game that everyone played on one PC with friends: Team Sindre against Team Trond on a random island in the rain of Bergen, with a giant waffle, blocks of brown cheese with a cheese slicer, the wooden houses of Bryggen, and Rocky the pet rock as land, drawn pixel by pixel, under the seven mountains and the TV mast of Ulriken. Explosions cut round holes in the land, and the worms fly, fall, take falling damage, and drown in the sea. The worms take turns: each walks, jumps, does backflips, aims with an angle, and holds Fire to charge the power, against a wind that blows the rockets and the rain. The weapons are the bazooka, the grenade with a fuse of 1 to 5 seconds that bounces, the shotgun with two shots, the banana bomb that splits into five, the sheep that walks and explodes on command, the air strike, the Holy Hand Grenade with a choir that sings “Hallelujah!”, the girder, and the teleport. A turn has a clock, and a worm that fired has a few seconds to run away. Team Trond is the computer, who aims well but sometimes badly on purpose, or a friend on the same keyboard (hot seat). Worms say funny things in speech bubbles, in English and in Norwegian, dead worms leave gravestones, the team health bars shrink, after five rounds comes sudden death (Mamma opened the bath tap, so the sea rises every turn), and the winners do a victory dance. The camera follows the shots, and a drag on the island looks around. Its script, `Worms.js`, runs the game on the canvas, with keys on a computer and big buttons for a phone, keeps the names of the worms and the wins in the browser, and makes the sounds with the Web Audio API once the visitor turns on the sound. For visitors who prefer reduced motion, the rain and the sea stand still, and every shot and every turn of the computer happens at once, with its path drawn as dots.
*/
struct GeoCitiesWorms: ScriptedElement {
	static let script = ElementScript()

	/**
	The weapons and tools, by the ID that the script knows them by, with their pictures and names.
	*/
	private static let weapons: [(id: String, icon: String, name: String)] = [
		("bazooka", "🚀", "Bazooka"),
		("grenade", "💣", "Grenade"),
		("shotgun", "🔫", "Shotgun"),
		("banana", "🍌", "Banana Bomb"),
		("sheep", "🐑", "Sheep"),
		("airstrike", "✈️", "Air Strike"),
		("holy", "✨", "Holy Hand Grenade"),
		("girder", "🏗️", "Girder"),
		("teleport", "🌀", "Teleport"),
	]

	/**
	The buttons for walking, jumping, aiming, and firing, for a finger or a mouse, by the ID that the script knows them by.
	*/
	private static let controls: [(id: String, icon: String, name: String)] = [
		("left", "◀", "Walk left"),
		("right", "▶", "Walk right"),
		("up", "▲", "Aim up"),
		("down", "▼", "Aim down"),
		("jump", "⤴", "Jump"),
		("backflip", "↩", "Backflip"),
	]

	/**
	The default names of the worms of Team Sindre, which the visitor can change.
	*/
	private static let defaultNames = ["Sindre", "Rocky", "Glitter", "Lillesøster"]

	var content: some HTML {
		h2 {
			"WURMS99.EXE: Sindre’s Wurms ’99"
		}
		.style(GeoCitiesPage.Styles.titleBar)

		div {
			p {
				"Trond and I played Worms Armageddon on Pappa’s PC every Friday. Here is my own version! Team Sindre against Team Trond, on an island of waffle and brown cheese in the rain. Blow up all the worms of Trond before he blows up yours."
			}

			div {
				button(.part(Parts.newGame), .type(.button)) {
					"New Game"
				}
				.style(GeoCitiesPage.Styles.smallButton)

				label {
					"Team Trond: "
					select(.part(Parts.opponent)) {
						Elementary.option(.value("computer")) {
							"The computer"
						}

						Elementary.option(.value("friend")) {
							"A friend (hot seat)"
						}
					}
					.style(GeoCitiesPage.Styles.select)
				}
				.style(Styles.setting)

				label {
					"Worms: "
					select(.part(Parts.count)) {
						for count in 2...4 {
							Elementary.option(.value("\(count)")) {
								"\(count) each"
							}
							.attributes(.selected, when: count == 3)
						}
					}
					.style(GeoCitiesPage.Styles.select)
				}
				.style(Styles.setting)

				button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
					"🔈 Sound"
				}
				.help("Plays sound")
				.style(GeoCitiesPage.Styles.smallButton)
			}
			.style(Styles.toolbar, GeoCitiesPage.Styles.scriptingOnly)

			canvas(.part(Parts.screen), .width(320), .height(200), .tabindex(0), .role("application")) {}
				.accessibilityLabel("The island of Wurms ’99. The left and right arrow keys walk, the up and down arrow keys aim, hold Space to charge and let go to fire, Enter jumps, Backspace does a backflip, the keys 1 to 5 set the fuse, and W picks the next weapon. Drag to look around.")
				.style(Styles.screen, GeoCitiesPage.Styles.scriptingOnly)

			p(.part(Parts.status), .role("status")) {
				"Click or tap the island to aim, then hold Space or 🔥 Hold to Fire. Team Sindre goes first!"
			}
			.style(GeoCitiesPage.Styles.statusBar, GeoCitiesPage.Styles.scriptingOnly)

			div {
				for control in Self.controls {
					button(.type(.button), .hook(Hooks.control, value: control.id)) {
						span {
							control.icon
						}
						.accessibilityHidden()

						span {
							control.name
						}
						.style(Styles.controlName)
					}
					.style(Styles.control)
				}

				button(.part(Parts.fire), .type(.button)) {
					"🔥 Hold to Fire"
				}
				.style(Styles.control, Styles.fire)
			}
			.attributes(.role("group"))
			.accessibilityLabel("Controls")
			.style(Styles.pad, GeoCitiesPage.Styles.scriptingOnly)

			div {
				for weapon in Self.weapons {
					button(.type(.button), .hook(Hooks.weapon, value: weapon.id), .ariaPressed(weapon.id == "bazooka")) {
						span {
							weapon.icon
						}
						.accessibilityHidden()
						.style(Styles.weaponIcon)

						span {
							weapon.name
						}

						span(.hook(Hooks.ammo, value: weapon.id)) {
							"∞"
						}
						.style(Styles.ammo)
					}
					.style(Styles.weapon)
				}

				button(.part(Parts.skip), .type(.button)) {
					span {
						"🏳️"
					}
					.accessibilityHidden()
					.style(Styles.weaponIcon)

					span {
						"Skip Go"
					}
				}
				.style(Styles.weapon)
			}
			.attributes(.role("group"))
			.accessibilityLabel("Weapons")
			.style(Styles.weapons, GeoCitiesPage.Styles.scriptingOnly)

			div {
				span {
					"Fuse of the grenade and the banana:"
				}
				.style(Styles.setting)

				div {
					for seconds in 1...5 {
						button(.type(.button), .hook(Hooks.fuse, value: "\(seconds)"), .ariaPressed(seconds == 3)) {
							"\(seconds) s"
						}
						.style(GeoCitiesPage.Styles.smallButton, Styles.fuse)
					}
				}
				.style(Styles.fuses)
			}
			.style(Styles.toolbar, GeoCitiesPage.Styles.scriptingOnly)

			details {
				summary {
					"✏️ Name my worms"
				}
				.style(Styles.summary)

				div {
					for (index, name) in Self.defaultNames.enumerated() {
						label {
							"Worm \(index + 1): "
							input(.type(.text), .hook(Hooks.name, value: "\(index)"), .maxlength(12), .autocomplete("off"), .placeholder(name))
								.style(GeoCitiesPage.Styles.field)
						}
						.style(Styles.nameLabel)
					}
				}
				.style(Styles.names)
			}
			.style(GeoCitiesPage.Styles.scriptingOnly)

			p {
				"Wurms ’99 needs JavaScript. Without it, all the worms are hiding in the brown cheese."
			}
			.style(GeoCitiesPage.Styles.caption, GeoCitiesPage.Styles.scriptingDisabledOnly)
		}
		.style(GeoCitiesPage.Styles.windowBody)
	}

	enum Parts: String, ElementPartSet {
		case screen
		case newGame
		case opponent
		case count
		case sound
		case skip
		case fire
		case status
	}

	enum Hooks: String, ScriptHookSet {
		/**
		The button of a weapon, with its ID, like `bazooka`.
		*/
		case weapon = "data-worms-weapon"

		/**
		How many of a weapon the team in turn has left, with its ID.
		*/
		case ammo = "data-worms-ammo"

		/**
		A button for walking, jumping, or aiming, with its ID, like `left`.
		*/
		case control = "data-worms-control"

		/**
		A button that sets the fuse, with its seconds.
		*/
		case fuse = "data-worms-fuse"

		/**
		The field of the name of a worm of Team Sindre, with its index.
		*/
		case name = "data-worms-name"
	}

	enum Styles: ElementStyleSet {
		case root
		case toolbar
		case setting
		case screen
		case weapons
		case weapon
		case weaponIcon
		case ammo
		case pad
		case control
		case controlName
		case fire
		case fuse
		case fuses
		case summary
		case names
		case nameLabel

		var style: Style {
			switch self {
			case .root:
				GeoCitiesPage.Styles.window.style.combined(with: GeoCitiesPage.Styles.section.style)
			case .toolbar:
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.flexWrap()
			case .setting:
				Style()
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			case .screen:
				// The island, in big pixels. Its size in pixels follows the width of the page, and a drag on it looks around, so a finger on it does not scroll the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.background(Color("#4a5a6a"))
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.imageRendering(.pixelated)
					.touchAction(.none)
					.cursor(.crosshair)
			case .weapons:
				// The weapon panel, like the one of Worms Armageddon that opens with the right mouse button.
				Style()
					.grid(columns: 5)
					.gap(.pixels(2))
					.padding(.pixels(2))
					.background(Color("#101030"))
			case .weapon:
				// A weapon, with its picture, its name, and how many are left. It is pressed in while it is picked, and gray when the team has none left.
				Style()
					.vstack(alignment: .center, spacing: 0)
					.padding(.rootEm(0.25))
					.background(Color("#303070"))
					.border(Color("#7070d0"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.lineHeight(1.1)
					.color(.white)
					.handCursor()
					.active {
						$0.border(Color("#7070d0"), width: .pixels(2), style: .inset)
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#c08020"))
							.border(Color("#ffd060"), width: .pixels(2), style: .inset)
					}
					.when(.state, is: "empty") {
						$0.opacity(0.45)
					}
			case .weaponIcon:
				Style().font(.large)
			case .ammo:
				Style()
					.fontFamily(GeoCitiesPage.courier)
					.color(Color("#66ff66"))
			case .pad:
				// Big buttons for a thumb, as a phone has no arrow keys.
				Style()
					.grid(columns: 4)
					.gap(.pixels(4))
			case .control:
				Style()
					.vstack(alignment: .center, justification: .center, spacing: 0)
					.frame(minHeight: .rootEm(2.75))
					// No padding at the sides, so the longest names, like “Walk right”, stay on one line in the narrow buttons of a phone.
					.padding(vertical: .rootEm(0.25), horizontal: 0)
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(3), style: .outset)
					.fontFamily(.system)
					.textStyle(.body, weight: .bold)
					.lineHeight(1.1)
					.color(.black)
					.handCursor()
					.textSelection(.disabled)
					.touchAction(.none)
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(3), style: .inset)
					}
			case .controlName:
				Style()
					.textStyle(.caption)
					.below(.smallTablet) {
						$0.font(size: .rootEm(0.8125), lineHeight: 1.1)
					}
			case .fire:
				// The big red button, two buttons wide.
				Style()
					.gridColumnSpan(2)
					.background(Color("#c02020"))
					.border(Color("#ff8080"), width: .pixels(3), style: .outset)
					.color(.white)
					.active {
						$0.border(Color("#ff8080"), width: .pixels(3), style: .inset)
					}
			case .fuse:
				Style()
					.frame(minWidth: .rootEm(2.75), minHeight: .rootEm(2.75))
					.when(.state, is: "on") {
						$0
							.background(Color("#ffd060"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .fuses:
				// The five fuse buttons stay together on one line, also when the label above them wraps on a phone.
				Style().hstack(alignment: .center, spacing: .rootEm(0.5))
			case .summary:
				// Tall enough for a finger.
				Style()
					.padding(.vertical, .rootEm(0.25))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.handCursor()
			case .names:
				Style()
					.grid(columns: 2)
					.gap(.rootEm(0.5))
					.padding(top: .rootEm(0.5))
			case .nameLabel:
				Style()
					.vstack(alignment: .start, spacing: .rootEm(0.125))
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
			}
		}
	}
}
