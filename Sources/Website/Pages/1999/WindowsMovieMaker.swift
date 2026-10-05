import Elementary
import Foundation
import SiteKit

/**
3D Movie Maker, the movie studio for kids of Microsoft Kids (1995), on the desktop of my computer (``GeoCitiesPage/desktop``), like the real one: a set in fake 3D (the haunted house, the diner, the space station, and a rainy street of Bergen), each with three or four camera angles, actors that walk on the floor and get smaller further back (me, Glitter the unicorn, Rocky the pet rock, a seagull, and a robot), and a clock that runs while the visitor drags an actor, which records its path frame by frame. Each actor gets actions (walk, run, jump, dance, wave, fall over), speech balloons that it says out loud with the sound on, and sound effects (boing, crash, a laugh track, applause). Titles of 3D letters spin in, a camera angle can cut in the middle of a scene, and the scenes play one after the other from the start with a film counter, until “The End”. McZee, the lanky alien guide of 3D Movie Maker, and his talking hand give tips and jokes in the status balloon. With reduced motion, the movie only goes frame by frame with the Step button. It is the content of its window of the desktop, and its script, `WindowsMovieMaker.js`, draws the sets and the actors on the canvas, keeps the movie in the browser, and has one premade movie, “The Waffle Heist”.
*/
struct GeoCitiesWindowsMovieMaker: ScriptedElement {
	static let script = ElementScript()

	/**
	The sets, by the ID the script knows them by.
	*/
	private static let sets: [(id: String, name: String)] = [
		("haunted", "Haunted House"),
		("diner", "Diner"),
		("space", "Space Station"),
		("bergen", "Rainy Bergen Street"),
	]

	/**
	The tools of the studio, like the toolbar of the real one, each with a panel of its own, by the ID the script knows them by.
	*/
	private static let tools: [(id: String, name: String, icon: String)] = [
		("scenes", "Scenes", "🎬"),
		("actors", "Actors", "🎭"),
		("words", "Words", "🔤"),
		("sounds", "Sounds", "🔔"),
		("portfolio", "Portfolio", "📁"),
	]

	/**
	The actors of the cast list, by the ID the script knows them by.
	*/
	private static let cast: [(id: String, name: String)] = [
		("sindre", "Sindre"),
		("glitter", "Glitter the unicorn"),
		("rocky", "Rocky the pet rock"),
		("seagull", "Seagull"),
		("robot", "Robot"),
	]

	/**
	The actions of an actor, by the ID the script knows them by.
	*/
	private static let actions: [(id: String, name: String)] = [
		("stand", "Stand"),
		("walk", "Walk"),
		("run", "Run"),
		("jump", "Jump"),
		("dance", "Dance"),
		("wave", "Wave"),
		("fall", "Fall over"),
	]

	/**
	The sound effects, by the ID the script knows them by.
	*/
	private static let soundEffects: [(id: String, name: String)] = [
		("boing", "Boing"),
		("crash", "Crash"),
		("laugh", "Laugh track"),
		("applause", "Applause"),
	]

	var content: some HTML {
		div {
			GeoCitiesPage.Deferred(stage)
			GeoCitiesPage.Deferred(playbackControls)
			GeoCitiesPage.Deferred(toolbar)
			GeoCitiesPage.Deferred(scenesPanel)
			GeoCitiesPage.Deferred(actorsPanel)
			GeoCitiesPage.Deferred(wordsPanel)
			GeoCitiesPage.Deferred(soundsPanel)
			GeoCitiesPage.Deferred(portfolioPanel)
			GeoCitiesPage.Deferred(guide)
		}
		.style(GeoCitiesWindows.Styles.stack, GeoCitiesPage.Styles.scriptingOnly)

		p {
			"3D Movie Maker needs JavaScript. McZee is out getting popcorn."
		}
		.style(GeoCitiesPage.Styles.scriptingDisabledOnly)
	}

	/**
	The stage, with the frame slider and the film counter under it.
	*/
	@HTMLBuilder
	private var stage: some HTML {
		canvas(.part(Parts.screen), .width(480), .height(300), .tabindex(0), .role("application")) {}
			.accessibilityLabel("The movie. Click an actor to pick it, and drag it on the floor to record its path while the clock runs. The arrow keys move the picked actor and record one frame, N picks the next actor, Delete removes it, comma and period go back and forward a frame, and Space plays the movie.")
			.style(Styles.screen)

		div {
			input(.part(Parts.frame), .type(.range), .min(0), .max(0), .value("0"))
				.accessibilityLabel("Frame")
				.style(Styles.slider)

			p(.part(Parts.counter)) {
				"Scene 1/1 ★ Frame 000/001"
			}
			.style(GeoCitiesPage.Styles.lcd, Styles.counter)
		}
		.style(Styles.timeline)
	}

	/**
	Play, Stop, Step, Undo, and the sound.
	*/
	@HTMLBuilder
	private var playbackControls: some HTML {
		div {
			button(.part(Parts.play), .type(.button)) {
				"▶ Play"
			}
			.help("Plays the movie from the start")
			.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

			button(.part(Parts.stop), .type(.button)) {
				"■ Stop"
			}
			.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

			button(.part(Parts.step), .type(.button)) {
				"⏭ Step"
			}
			.help("Goes one frame forward")
			.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

			button(.part(Parts.undo), .type(.button), .disabled) {
				"↶ Undo"
			}
			.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

			button(.part(Parts.sound), .type(.button), .ariaPressed(false)) {
				"🔈 Sound"
			}
			.help("Plays the sounds and the voices")
			.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
		}
		.style(GeoCitiesWindows.Styles.wrapRow)
	}

	/**
	The tools, which open their drawers.
	*/
	@HTMLBuilder
	private var toolbar: some HTML {
		div(.role("group")) {
			for tool in Self.tools {
				button(.type(.button), .hook(Hooks.tool, value: tool.id), .ariaPressed(tool.id == "scenes")) {
					span {
						tool.icon
					}
					.accessibilityHidden()
					.style(Styles.toolIcon)

					tool.name
				}
				.attributes(.hook(ScriptAttribute.state, value: "on"), when: tool.id == "scenes")
				.style(Styles.toolButton)
			}
		}
		.accessibilityLabel("Tools")
		.style(Styles.tools)
	}

	/**
	The drawer of the scenes: the set, the camera angles, and the scenes of the movie.
	*/
	@HTMLBuilder
	private var scenesPanel: some HTML {
		div(.hook(Hooks.panel, value: "scenes")) {
			div {
				label {
					"Set: "

					select(.part(Parts.set)) {
						for set in Self.sets {
							option(.value(set.id)) {
								set.name
							}
						}
					}
					.style(GeoCitiesWindows.Styles.toolbarSelect)
				}

				div(.role("group")) {
					for camera in 0..<4 {
						button(.type(.button), .hook(Hooks.camera, value: "\(camera)"), .ariaPressed(camera == 0)) {
							"📷 \(camera + 1)"
						}
						.accessibilityLabel("Camera \(camera + 1)")
						.attributes(.hook(ScriptAttribute.state, value: "on"), when: camera == 0)
						.style(Styles.toolButton)
					}
				}
				.accessibilityLabel("Camera angle")
				.style(GeoCitiesWindows.Styles.wrapRow)
			}
			.style(GeoCitiesWindows.Styles.wrapRow)

			div {
				div(.part(Parts.scenes), .role("group")) {}
					.accessibilityLabel("Scenes")
					.style(Styles.sceneStrip)

				template(.part(Parts.sceneTemplate)) {
					button(.type(.button)) {}
						.style(Styles.sceneButton)
				}

				button(.part(Parts.addScene), .type(.button)) {
					"➕ New Scene"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				button(.part(Parts.deleteScene), .type(.button)) {
					"✂️ Cut Scene"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.style(GeoCitiesWindows.Styles.wrapRow)
		}
		.style(Styles.panel)
	}

	/**
	The drawer of the actors: the cast list and the actions.
	*/
	@HTMLBuilder
	private var actorsPanel: some HTML {
		div(.hook(Hooks.panel, value: "actors"), .hidden) {
			div {
				label {
					"Cast: "

					select(.part(Parts.cast)) {
						for actor in Self.cast {
							option(.value(actor.id)) {
								actor.name
							}
						}
					}
					.style(GeoCitiesWindows.Styles.toolbarSelect)
				}

				button(.part(Parts.addActor), .type(.button)) {
					"➕ Add Actor"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.style(GeoCitiesWindows.Styles.wrapRow)

			div {
				label {
					"Action: "

					select(.part(Parts.action)) {
						for action in Self.actions {
							option(.value(action.id)) {
								action.name
							}
						}
					}
					.style(GeoCitiesWindows.Styles.toolbarSelect)
				}

				button(.part(Parts.nextActor), .type(.button)) {
					"👉 Next Actor"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				button(.part(Parts.removeActor), .type(.button)) {
					"🗑️ Remove"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.style(GeoCitiesWindows.Styles.wrapRow)
		}
		.style(Styles.panel)
	}

	/**
	The drawer of the words: speech balloons and titles.
	*/
	@HTMLBuilder
	private var wordsPanel: some HTML {
		div(.hook(Hooks.panel, value: "words"), .hidden) {
			form(.part(Parts.sayForm)) {
				label(.for("geocities-moviemaker-say-text")) {
					"💬 Say:"
				}

				input(.id("geocities-moviemaker-say-text"), .part(Parts.sayText), .type(.text), .maxlength(50), .autocomplete("off"), .placeholder("Uff da!"))
					.style(GeoCitiesPage.Styles.field)

				button(.type(.submit)) {
					"Add"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.style(GeoCitiesWindows.Styles.nowrapRow)

			form(.part(Parts.titleForm)) {
				label(.for("geocities-moviemaker-title-text")) {
					"🔠 Title:"
				}

				input(.id("geocities-moviemaker-title-text"), .part(Parts.titleText), .type(.text), .maxlength(24), .autocomplete("off"), .placeholder("THE END?"))
					.style(GeoCitiesPage.Styles.field)

				button(.type(.submit)) {
					"Add"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.style(GeoCitiesWindows.Styles.nowrapRow)
		}
		.style(Styles.panel)
	}

	/**
	The drawer of the sound effects.
	*/
	@HTMLBuilder
	private var soundsPanel: some HTML {
		div(.hook(Hooks.panel, value: "sounds"), .hidden) {
			div {
				label {
					"Sound effect: "

					select(.part(Parts.effect)) {
						for effect in Self.soundEffects {
							option(.value(effect.id)) {
								effect.name
							}
						}
					}
					.style(GeoCitiesWindows.Styles.toolbarSelect)
				}

				button(.part(Parts.addEffect), .type(.button)) {
					"🔔 Add Sound"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.style(GeoCitiesWindows.Styles.wrapRow)
		}
		.style(Styles.panel)
	}

	/**
	The drawer of the portfolio: save, open, a new movie, and the premade movie.
	*/
	@HTMLBuilder
	private var portfolioPanel: some HTML {
		div(.hook(Hooks.panel, value: "portfolio"), .hidden) {
			div {
				button(.part(Parts.save), .type(.button)) {
					"💾 Save"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				button(.part(Parts.open), .type(.button)) {
					"📂 Open"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				button(.part(Parts.newMovie), .type(.button)) {
					"📄 New Movie"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)

				button(.part(Parts.premiere), .type(.button)) {
					"🍿 Watch “The Waffle Heist”"
				}
				.style(GeoCitiesPage.Styles.smallButton, Styles.bigTarget)
			}
			.style(GeoCitiesWindows.Styles.wrapRow)
		}
		.style(Styles.panel)
	}

	/**
	McZee, who gives a tip when he is clicked, and what he says in a balloon, which is the status of the studio.
	*/
	@HTMLBuilder
	private var guide: some HTML {
		div {
			button(.part(Parts.ask), .type(.button)) {
				canvas(.part(Parts.guide), .width(64), .height(96)) {}
					.accessibilityHidden()
					.style(Styles.guide)

				"Ask McZee"
			}
			.help("Gives a tip")
			.style(Styles.guideButton)

			p(.part(Parts.status), .role("status")) {
				"McZee: Welcome to the studio! Drag Sindre across the floor to make a movie."
			}
			.style(Styles.balloon)
		}
		.style(Styles.guideRow)
	}

	enum Parts: String, ElementPartSet {
		case screen
		case frame
		case counter
		case play
		case stop
		case step
		case undo
		case sound
		case set
		case scenes
		case sceneTemplate
		case addScene
		case deleteScene
		case cast
		case addActor
		case action
		case nextActor
		case removeActor
		case sayForm
		case sayText
		case titleForm
		case titleText
		case effect
		case addEffect
		case save
		case open
		case newMovie
		case premiere
		case guide
		case status
		case ask
	}

	/**
	The lists of the same kind of button, with a value for the script.
	*/
	enum Hooks: String, ScriptHookSet {
		/**
		A tool of the toolbar, by the ID of its panel.
		*/
		case tool = "data-moviemaker-tool"

		/**
		The panel of a tool, by its ID.
		*/
		case panel = "data-moviemaker-panel"

		/**
		A camera angle of the set, by its number from 0.
		*/
		case camera = "data-moviemaker-camera"
	}

	enum Styles: ElementStyleSet {
		case root
		case screen
		case timeline
		case slider
		case counter
		case bigTarget
		case tools
		case toolButton
		case toolIcon
		case panel
		case sceneStrip
		case sceneButton
		case guideRow
		case guideButton
		case guide
		case balloon

		var style: Style {
			switch self {
			case .root:
				// The studio, or the text for a browser without JavaScript, in the body of its window.
				Style().display(.block)
			case .screen:
				// The stage, as wide as the window. A drag on it moves an actor, so a finger on it does not scroll the page.
				Style()
					.display(.block)
					.frame(width: .percent(100), height: .auto)
					.aspectRatio(480.0 / 300.0)
					.background(.black)
					.border(Color("#808080"), width: .pixels(3), style: .inset)
					.touchAction(.none)
					.cursor(.pointer)
					.focusVisible {
						$0.focusRing(Color("#ffd23f"), width: .pixels(2), offset: .pixels(2))
					}
			case .timeline:
				// The frame slider, with the film counter beside it, like the counter of a VCR.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.375))
					.flexWrap()
			case .slider:
				// Tall enough for a finger on a phone.
				Style()
					.flex(1)
					.frame(minWidth: .rootEm(8))
					.margin(0)
					.below(.smallTablet) {
						$0.frame(minHeight: .rootEm(1.75))
					}
			case .counter:
				Style()
					.flexShrink(0)
					.margin(0)
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.5))
					.textStyle(.caption)
					.monospacedDigit()
			case .bigTarget:
				// Big enough for a thumb on a phone.
				Style().frame(minHeight: .rootEm(2))
			case .tools:
				// The tools share the row, but a long name like “Portfolio” keeps its width, so each name fits inside its button. On a phone, the names are as small as the 8 point text of the toolbars of Windows 98, and the tools are closer together, so they fit in one row down to a phone of 360 points. A narrower phone wraps the last tool to a second row instead of making the window scroll sideways.
				Style()
					.hstack(spacing: .rootEm(0.25))
					.flexWrap()
					.below(.smallTablet) {
						$0.gap(.rootEm(0.125))
					}
					.children("button") {
						$0
							.flex(1)
							.frame(minWidth: .auto)
							.below(.smallTablet) {
								$0.font(size: .rootEm(0.6875))
							}
					}
			case .toolButton:
				// A tool of the studio, which stays pressed in while its panel is open.
				Style()
					.vstack(alignment: .center, justification: .center, spacing: 0)
					.frame(minWidth: .rootEm(2.25), minHeight: .rootEm(2.5))
					.padding(vertical: .rootEm(0.125), horizontal: .rootEm(0.25))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.handCursor()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
					.when(.state, is: "on") {
						$0
							.background(Color("#ffffcc"))
							.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .toolIcon:
				Style().font(.large)
			case .panel:
				// The open drawer of a tool, under the toolbar.
				Style()
					.vstack(spacing: .rootEm(0.375))
					.padding(.rootEm(0.375))
					.border(Color("#808080"), width: .pixels(2), style: .groove)
			case .sceneStrip:
				// The scenes of the movie, one after the other, like the scene sorter of the real one.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.25))
					.flexWrap()
			case .sceneButton:
				// A scene, like a frame of film. The scene on the stage is yellow.
				Style()
					.frame(minWidth: .rootEm(2.5), minHeight: .rootEm(2))
					.padding(vertical: 0, horizontal: .rootEm(0.25))
					.background(Color("#202020"))
					.border(Color("#808080"), width: .pixels(2), style: .dashed)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.white)
					.handCursor()
					.when(.state, is: "on") {
						$0
							.background(Color("#ffff99"))
							.color(.black)
					}
			case .guideRow:
				// McZee, with what he says in a balloon beside him.
				Style()
					.grid(columns: "auto 1fr")
					.alignItems(.center)
					.gap(.rootEm(0.375))
			case .guideButton:
				// McZee himself, who gives a tip when he is clicked.
				Style()
					.vstack(alignment: .center, spacing: 0)
					.padding(.rootEm(0.125))
					.background(GeoCitiesPage.windowGray)
					.border(Color("#dfdfdf"), width: .pixels(2), style: .outset)
					.fontFamily(.system)
					.textStyle(.caption, weight: .bold)
					.color(.black)
					.handCursor()
					.active {
						$0.border(Color("#dfdfdf"), width: .pixels(2), style: .inset)
					}
			case .guide:
				Style()
					.display(.block)
					.frame(width: .rootEm(3), height: .rootEm(4.5))
			case .balloon:
				// A speech balloon of a comic, for McZee.
				Style()
					.margin(0)
					.padding(vertical: .rootEm(0.25), horizontal: .rootEm(0.5))
					.frame(minHeight: .rootEm(3))
					.background(.white)
					.border(.black, width: .pixels(2))
					.cornerRadius(.rootEm(0.75))
					.fontFamily(GeoCitiesPage.comicSans)
					.textStyle(.caption)
					.color(.black)
					.overflowWrap(.anywhere)
			}
		}
	}
}
