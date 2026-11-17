import Elementary
import SiteKit

/**
A block of code, with its language and a copy button in a bar at the top right, like a fenced code block in Markdown (``SiteKit/MarkdownDocument/Options/codeBlock``).

Swift code is highlighted when the site builds, by the parser of Swift itself (``String/swiftCodeParts``), in the colors of Xcode. SOML code is highlighted by the lexer of SOML (``String/somlCodeParts``), JavaScript code by a small lexer (``String/javaScriptCodeParts``), and the comments and strings of shell code (`sh`, and the commands of a `console` block) by another (``String/shellCodeParts``), in the same colors. The code of other languages is plain. Each line of a `console` block is a command, after a `$ ` prompt that is not copied. When some lines start with `$ `, only those lines are commands, and the other lines are what the commands print, in a lighter color, and the copy button copies only the commands, so a command that continues on the next line, after a `\`, is not supported there. The removed and added lines of a `diff` block are red and green, with a faint fill of the same color from edge to edge, and the copy button copies the new code, without the removed lines and the markers. A fence can name the file of the code after the language, like ```` ```swift Badge.swift ````, which shows at the top left of the block.

```swift
CodeBlock(source: "let greeting = \"Hello\"", language: .swift)
```
*/
struct CodeBlock: HTML {
	/**
	A language of a code block, which the bar shows by its name (``title``). Another language is a content error, like a typo of `swfit`, as the bar has no name for it. Add a language here when the content needs it.
	*/
	enum Language: String, ContentEnum {
		case applescript
		case console
		case css
		case diff
		case js
		case python
		case sh
		case soml
		case swift
		case xml
		case yaml

		/**
		The name that the bar shows, like “Terminal” for `console`, as most readers of a guide do not know the names of the fences, and the guides say to run a command in the Terminal app.
		*/
		var title: String {
			switch self {
			case .applescript:
				"AppleScript"
			case .console:
				"Terminal"
			case .css:
				"CSS"
			case .diff:
				"Diff"
			case .js:
				"JavaScript"
			case .python:
				"Python"
			case .sh:
				"Shell"
			case .soml:
				"SOML"
			case .swift:
				"Swift"
			case .xml:
				"XML"
			case .yaml:
				"YAML"
			}
		}
	}

	let source: String

	/**
	The language, like `swift`, which the bar shows.
	*/
	let language: Language?

	/**
	The name of the file that the code is from, like `Badge.swift`, which shows at the top left of the block, so a reader knows where the code is.
	*/
	var fileName: String?

	/**
	The HTML of a code block, for ``SiteKit/MarkdownDocument/Options/codeBlock``. An unknown language is an error.
	*/
	@Sendable
	static func render(source: String, language: String?, fileName: String?) throws(ContentError) -> HTMLFragment {
		Self(source: source, language: try language.map(Language.init(validating:)), fileName: fileName).renderFragment()
	}

	var body: some HTML {
		div {
			if let fileName {
				div {
					fileName
				}
				.style(Styles.fileName)
			}

			div {
				if let language {
					span {
						language.title
					}
					.style(Styles.language)
				}

				CopyButton(title: "Copy code", text: copiedText, look: .icon)
			}
			.style(Styles.bar)

			// Focusable, so keyboard users can scroll wide code.
			// Code is not translated, as a translation would change the command that the copy button copies.
			pre(.tabindex(0), .notTranslated) {
				code {
					switch language {
					case .swift:
						Self.highlighted(source.swiftCodeParts)
					case .soml:
						Self.highlighted(source.somlCodeParts)
					case .js:
						Self.highlighted(source.javaScriptCodeParts)
					case .sh:
						Self.highlighted(source.shellCodeParts)
					case .console:
						for (index, line) in lines.enumerated() {
							if index > 0 {
								"\n"
							}

							if !line.isEmpty {
								if
									hasPrompts,
									!line.hasPrefix(Self.prompt)
								{
									samp {
										String(line)
									}
									.style(Styles.output)
								} else {
									Command(text: String(line.trimmingPrefix(Self.prompt)))
								}
							}
						}
					case .diff:
						for (index, line) in lines.enumerated() {
							if index > 0 {
								"\n"
							}

							switch line.first {
							case "-":
								span {
									String(line)
								}
								.style(Styles.removed)
							case "+":
								span {
									String(line)
								}
								.style(Styles.added)
							default:
								String(line)
							}
						}
					// A long line, like a URL, wraps (``Styles/wrapped``) where a line of code reads well, like before the `&` of a parameter, not inside a word.
					case nil:
						BreakableCode(text: source)
					default:
						source
					}
				}
				.style(Styles.code)
				.style(Styles.wrapped, when: language == nil || language == .console)
				.style(Styles.console, when: language == .console)
				.style(Styles.diff, when: language == .diff)
			}
			.style(Styles.pre)
		}
		.style(Styles.root)
		.style(Styles.titled, when: fileName != nil)
	}

	private var lines: [Substring] {
		source.split(separator: "\n", omittingEmptySubsequences: false)
	}

	/**
	The prompt before a command in a `console` block that also shows what the commands print.
	*/
	private static let prompt = "$ "

	/**
	Whether the commands of a `console` block start with a `$ ` prompt, so the other lines are what the commands print. Without a prompt, each line is a command.
	*/
	private var hasPrompts: Bool {
		lines.contains { $0.hasPrefix(Self.prompt) }
	}

	/**
	The code that the copy button copies, without the newline at its end, which would run a pasted command in a shell without bracketed paste, and add an empty line in an editor. For a diff, the new code: without the removed lines, and without the first character of the other lines, which is the marker of an added line or the space of an unchanged line, so the copy is code that works. Limitation: a diff is only the lines of its changes, without the headers of `git diff`, like `+++ b/file` and `@@`. For a `console` block with prompts, only the commands, without their prompts, and not what they print. Limitation: a command that continues on the next line after a `\\` is not supported with prompts, as the next line is output.
	*/
	private var copiedText: String {
		let code = switch language {
		case .diff:
			lines
				.filter { !$0.hasPrefix("-") }
				.map { $0.dropFirst() }
				.joined(separator: "\n")
		case .console where hasPrompts:
			lines
				.filter { $0.hasPrefix(Self.prompt) }
				.map { $0.dropFirst(Self.prompt.count) }
				.joined(separator: "\n")
		default:
			source
		}

		return code.hasSuffix("\n") ? String(code.dropLast()) : code
	}

	/**
	The names of the commands of a `console` or `sh` block, like `sips` and `killall`, also after `sudo`, and after `&&`, `;`, and `|` in a line, for the site search. A line that is a comment is not a command.
	*/
	var commandNames: [String] {
		guard
			let language,
			[.console, .sh].contains(language)
		else {
			return []
		}

		let commandParts: [Substring] = copiedText
			.split(separator: "\n")
			.filter { !$0.hasPrefix("#") }
			.flatMap { $0.split(separator: /&&|;|\|/) }

		return commandParts.compactMap { command in
			command.split(separator: " ").first { $0 != "sudo" }.map(String.init)
		}
	}

	/**
	The words of a command, split at its spaces, each with the highlighted parts of the shell code (``String/shellCodeParts``), like `'lungo:toggle'` as a string. A string or a comment with spaces, like `'id of app "Safari"'`, is in more than one word. A word is empty where the command has two spaces in a row.
	*/
	fileprivate static func commandWords(_ command: String) -> [[CodePart]] {
		var words: [[CodePart]] = [[]]

		for part in command.shellCodeParts {
			for (index, text) in part.text.split(separator: " ", omittingEmptySubsequences: false).enumerated() {
				if index > 0 {
					words.append([])
				}

				if !text.isEmpty {
					words[words.count - 1].append(CodePart(text: String(text), token: part.token))
				}
			}
		}

		return words
	}

	/**
	The parts of highlighted code, with each colored part in a span with the style of its kind.
	*/
	@HTMLBuilder
	private static func highlighted(_ parts: [CodePart]) -> some HTML {
		for part in parts {
			if let token = part.token {
				span {
					part.text
				}
				.style(Styles(token))
			} else {
				part.text
			}
		}
	}

	enum Styles: String, StyleSet {
		case root
		case bar
		case language
		case pre
		case code

		/**
		The name of the file of the code, in the row of the bar, at the other side.
		*/
		case fileName

		/**
		A block with the name of its file, whose code starts below the row of the bar, also on a screen with a pointer, where the bar only shows under the pointer, so the name does not cover the code.
		*/
		case titled

		/**
		The long lines of a `console` block and of a block without a language wrap, so a reader on a phone sees all of a command or a URL, like the two `VIDEO_ID` of a long URL, without scrolling. A word that is wider than the code breaks inside. Code with a language keeps its lines and scrolls, as its indentation shows its structure.
		*/
		case wrapped

		/**
		Each line is a command, after a faded `$ ` prompt. The prompt is generated content, so it is not selected or copied, and screen readers skip it.
		*/
		case console

		/**
		A line of a `console` block that a command prints, without a prompt.
		*/
		case output

		/**
		The code of a diff, which is as wide as its longest line, so the fill of a changed line (``removed``, ``added``) goes to the end of the code when it scrolls sideways.
		*/
		case diff

		/**
		A removed line of a diff, with its `-` marker.
		*/
		case removed

		/**
		An added line of a diff, with its `+` marker.
		*/
		case added

		case keyword
		case type
		case attribute
		case string
		case number
		case comment
		case declaration
		case member

		init(_ token: CodeToken) {
			self = switch token {
			case .keyword:
				.keyword
			case .type:
				.type
			case .attribute:
				.attribute
			case .string:
				.string
			case .number:
				.number
			case .comment:
				.comment
			case .declaration:
				.declaration
			case .member:
				.member
			}
		}

		/**
		The space between the bar and the corner of the code.
		*/
		private static let barInset = LengthPercentage.rootEm(0.5)

		/**
		The height of the row of the bar, with its space above and below the copy button (``CopyButton/Look/icon``). On touch screens, where the bar always shows, and in a block with the name of its file, the code starts below it.
		*/
		private static let barRowHeight = barInset * 2 + .rootEm(1.75)

		/**
		The space at the sides of the code, which the root sets, so the name of the file starts where the code starts, and the fill of a changed line of a diff goes to the edges of the block.
		*/
		private static let codeInset = StyleVariable<LengthPercentage>("code-inset")

		/**
		The corners of the bar and its copy button (``CopyButton/Look/icon``), parallel to the corner of the code around them.
		*/
		static let barRadius = LengthPercentage.windowRadius - barInset

		/**
		The fill of the code, which is dark in both modes.
		*/
		private static let codeBackground = Color.lightDark(.gray(800), .darkCodeBackground)

		/**
		The sideways scrolling of the code, which the fade at its end follows.
		*/
		private static let codeScroll = ScrollTimeline("code-scroll", axis: .inline)

		/**
		A changed line of a diff in its color, with a faint fill of the color from edge to edge of the block, like GitHub, so a reader sees the changed lines as rows. The line is an inline block that is as wide as the code (``diff``), and goes into the space at the sides of the code.
		*/
		private static func changedLine(_ color: Color, fillOpacity: Double) -> Style {
			Style()
				.color(color)
				.display(.inlineBlock)
				.frame(minWidth: .length(.percent(100) + Self.codeInset.value * 2))
				.margin(.horizontal, .length(-Self.codeInset.value))
				.padding(.horizontal, Self.codeInset.value)
				.background(color.opacity(fillOpacity))
		}

		enum Animations: String, KeyframeSet {
			case hideFade

			var keyframes: [Keyframe] {
				[
					.from(Style().opacity(1)),
					.to(Style().opacity(0)),
				]
			}
		}

		var style: Style {
			switch self {
			case .root:
				// The bar is positioned in the corner of the code.
				// On phones, a code block in the text goes to the edges of the screen, so a line shows more characters. Only a block directly in the prose, as the prose is one gutter from the edges, but a list, a collapsible section, or a box is not. In dark mode, the edge of the code is only a line above and below it, like a full-width table, as a line at the sides would be on the edge of the screen.
				Style()
					.position(.relative)
					.setting(Self.codeInset, to: .boxInset)
					.timelineScope(Self.codeScroll)
					// The end of code that scrolls sideways fades, so a reader on a phone sees that the lines go on and are not cut off. The fade goes away in the last 2.5rem of the scrolling, at the end of the lines. Code that does not scroll has no active timeline, so the animation does nothing, and the fade stays hidden. It is before the bar, so it does not cover the bar, and 1 px inside the code, so it does not cover the faint edge of the code in dark mode.
					.before {
						$0
							.content("")
							.position(.absolute)
							.top(.pixels(1))
							.bottom(.pixels(1))
							.trailing(.pixels(1))
							.frame(width: .rootEm(2.5))
							.cornerRadius(.windowRadius - .pixels(1))
							.backgroundImage(.linearGradient(.toRight, Color.transparent, Self.codeBackground))
							.allowsHitTesting(false)
							.opacity(0)
							.animation(Animations.hideFade, timeline: .scrolling(Self.codeScroll), from: .percent(100) - .rootEm(2.5), to: .percent(100))
					}
					// On phones, less space at the sides, so a line shows more characters.
					.below(.smallTablet) {
						$0
							.setting(Self.codeInset, to: .rootEm(1))
							.directlyInside(ProseStyles.root.selector) {
								$0
									.margin(.horizontal, .length(-.pageGutter))
									// The code starts at the gutter of the page, in line with the text above it.
									.setting(Self.codeInset, to: .pageGutter)
									.before {
										$0.cornerRadius(.zero)
									}
									.children(Self.pre.selector) {
										$0
											.cornerRadius(.zero)
											.dark {
												$0.shadow(.horizontalEdges(.white.opacity(0.06)))
											}
									}
							}
					}
			case .bar:
				// The bar shows while the pointer is over the code or it has focus, while the button shows its checkmark, and always on touch screens.
				Style()
					.position(.absolute)
					.top(.length(Self.barInset))
					.trailing(.length(Self.barInset))
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.font(.extraSmall)
					.padding(.leading, .rootEm(0.5))
					.cornerRadius(Self.barRadius)
					// A frosted backdrop in the color of the code, so the language and the button are easy to read over a long line of code.
					.frostedBackground(.lightDark(.gray(800).opacity(0.8), Color.darkCodeBackground.opacity(0.8)), opaque: Self.codeBackground, blur: .pixels(6))
					.opacity(0)
					.transition(.opacity, timing: .stateChange)
					.nested("\(Self.root.selector):hover &, \(Self.root.selector):focus-within &, &:has(\(CopyButton.States.copied.selector))") {
						$0.opacity(1)
					}
					.media(.cannotHover) {
						$0.opacity(1)
					}
			case .language:
				Style()
					.fontFamily(.monospace)
					.color(.gray(400))
					.textSelection(.disabled)
			case .fileName:
				// In the font and the gray of the language in the bar, in the middle of the row of the bar. It always shows, unlike the bar on a screen with a pointer.
				Style()
					.position(.absolute)
					.top(.zero)
					.leading(.length(Self.codeInset.value))
					.hstack(alignment: .center)
					.frame(height: .length(Self.barRowHeight))
					.font(.extraSmall)
					.fontFamily(.monospace)
					.color(.gray(400))
			case .titled:
				Style()
					.children(Self.pre.selector) {
						$0.padding(.top, Self.barRowHeight)
					}
			case .pre:
				// The space at the sides is the space of the root (``codeInset``): less on phones, and the gutter of the page for a block that goes to the edges of the screen.
				Style()
					.margin(.zero)
					.codeSurface()
					.padding(.horizontal, Self.codeInset.value)
					.scrollTimeline(Self.codeScroll)
					// The bar always shows on touch screens, so the code starts below it, instead of under it.
					.media(.cannotHover) {
						$0.padding(.top, Self.barRowHeight)
					}
					// On phones, smaller code, so a line shows more characters.
					.below(.smallTablet) {
						$0.font(size: .rootEm(0.875))
					}
			case .code:
				// The font of the block, not of inline code.
				Style()
					.inheritsFont()
					.inherits(.color)
			case .wrapped:
				Style()
					.textWrap(.wrap)
					.overflowWrap(.anywhere)
			case .console:
				// A long command wraps (``wrapped``), so it can be read on a phone before it is pasted. The copy button copies it as one line. A wrapped line continues after the prompt, which hangs in the space at the start of the line. A line is an inline block, so it can have that space, and the line breaks between the lines stay the only breaks. Each word of a command is an inline block too, like the items of a menu path (``ProseStyles/menuPathItemStyle``), so a command breaks only at a space, and a word wider than the code still breaks inside.
				Style()
					.children("span") {
						$0
							.display(.inlineBlock)
							.padding(.leading, .characterWidth(2))
							.before {
								$0
									.content("$ ", alternativeText: "")
									.margin(.leading, .characterWidth(-2))
									.opacity(0.5)
							}
							.children("span") {
								$0
									.display(.inlineBlock)
									.frame(maxWidth: .percent(100))
							}
					}
					// On a screen with a pointer, the bar shows over the code while the pointer is over it, so the first command wraps before the bar, and the bar does not hide its end. On touch screens, the code starts below the bar.
					.media(.hover) {
						$0.children("span:first-child") {
							$0.frame(maxWidth: .length(.percent(100) - .rootEm(6.5)))
						}
					}
			case .output:
				// The font of the code, not the smaller monospace font of `samp` in browsers. The gray of the language in the bar, which is lighter than the code in both modes, as the code is light on dark.
				Style()
					.inheritsFont()
					.color(.gray(400))
			case .diff:
				Style()
					.display(.inlineBlock)
					.frame(minWidth: .percent(100))
			// The red of the strings, and a soft green, which both have enough contrast on the dark code.
			case .removed:
				Self.changedLine("#ff8170", fillOpacity: 0.15)
			case .added:
				Self.changedLine("#acf2a0", fillOpacity: 0.12)
			// The colors of the default dark theme of Xcode, as code blocks are dark in both modes, and Swift developers know them.
			case .keyword:
				Style()
					.color("#ff7ab2")
					.fontWeight(.semibold)
			case .type:
				Style().color("#dabaff")
			case .attribute:
				Style().color("#cc9768")
			case .string:
				Style().color("#ff8170")
			case .number:
				Style().color("#d9c97c")
			case .comment:
				// Lighter than in Xcode, for enough contrast on the lighter code blocks of light mode.
				Style().color("#8b97a3")
			case .declaration:
				Style().color("#41a1c0")
			case .member:
				Style().color("#67b7a4")
			}
		}
	}
}

/**
A highlighted command of a `console` block. Each word is an element, so a command that wraps breaks only at a space, not after the hyphen of an option, like `-globalDomain`. A word that is wider than the code breaks where a line of code reads well (``BreakableCode``), like between the words of `NSShowAppCentricOpenPanelInsteadOfUntitledFile`, not at any letter. The spaces stay text, so a selection copies the command as it is.
*/
private struct Command: HTML {
	let text: String

	var body: some HTML<HTMLTag.span> {
		span {
			for (index, word) in CodeBlock.commandWords(text).enumerated() {
				if index > 0 {
					" "
				}

				span {
					for part in word {
						if let token = part.token {
							span {
								BreakableCode(text: part.text)
							}
							.style(CodeBlock.Styles(token))
						} else {
							BreakableCode(text: part.text)
						}
					}
				}
			}
		}
	}
}

/**
Code with a `<wbr>` at each place where a line of code can break (``Swift/String/codeLineBreakParts``), for code that wraps. `<wbr>` adds no text, so copying is the same.
*/
private struct BreakableCode: HTML {
	let text: String

	var body: some HTML {
		for (index, part) in text.codeLineBreakParts.enumerated() {
			if index > 0 {
				wbr()
			}

			String(part)
		}
	}
}
