import Elementary
import SiteKit

/**
A block of code, with its language and a copy button in a bar at the top right, like a fenced code block in Markdown (``SiteKit/MarkdownDocument/Options/codeBlock``).

Swift code is highlighted when the site builds, by the parser of Swift itself (``String/swiftCodeParts``), in the colors of Xcode. SOML code is highlighted by the lexer of SOML (``String/somlCodeParts``), in the same colors. The code of other languages is plain. Each line of a `console` block is a command, after a `$ ` prompt that is not copied. The removed and added lines of a `diff` block are red and green, and the copy button copies the new code, without the removed lines and the markers.

```swift
CodeBlock(source: "let greeting = \"Hello\"", language: .swift)
```
*/
struct CodeBlock: HTML {
	/**
	A language of a code block, which the bar shows. The bar shows the name as it is written, so another language is a content error, like a typo of `swfit`, which would show as the label. Add a language here when the content needs it.
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
	}

	let source: String

	/**
	The language, like `swift`, which the bar shows.
	*/
	let language: Language?

	/**
	The HTML of a code block, for ``SiteKit/MarkdownDocument/Options/codeBlock``. An unknown language is an error.
	*/
	@Sendable
	static func render(source: String, language: String?) throws(ContentError) -> String {
		Self(source: source, language: try language.map(Language.init(validating:))).render()
	}

	var body: some HTML {
		div {
			div {
				if let language {
					span {
						language.rawValue
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
					case .console:
						for (index, line) in lines.enumerated() {
							if index > 0 {
								"\n"
							}

							if !line.isEmpty {
								span {
									String(line)
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
					default:
						source
					}
				}
				.style(Styles.code)
				.style(Styles.console, when: language == .console)
			}
			.style(Styles.pre)
		}
		.style(Styles.root)
	}

	private var lines: [Substring] {
		source.split(separator: "\n", omittingEmptySubsequences: false)
	}

	/**
	The code that the copy button copies, without the newline at its end, which would run a pasted command in a shell without bracketed paste, and add an empty line in an editor. For a diff, the new code: without the removed lines, and without the first character of the other lines, which is the marker of an added line or the space of an unchanged line, so the copy is code that works. Limitation: a diff is only the lines of its changes, without the headers of `git diff`, like `+++ b/file` and `@@`.
	*/
	private var copiedText: String {
		let code = language == .diff
			? lines
				.filter { !$0.hasPrefix("-") }
				.map { $0.dropFirst() }
				.joined(separator: "\n")
			: source

		return code.hasSuffix("\n") ? String(code.dropLast()) : code
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
		Each line is a command, after a faded `$ ` prompt. The prompt is generated content, so it is not selected or copied, and screen readers skip it.
		*/
		case console

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
		The corners of the bar and its copy button (``CopyButton/Look/icon``), parallel to the corner of the code around them.
		*/
		static let barRadius = LengthPercentage.windowRadius - barInset

		var style: Style {
			switch self {
			case .root:
				// The bar is positioned in the corner of the code.
				// On phones, a code block in the text goes to the edges of the screen, so a line shows more characters. Only a block directly in the prose, as the prose is one gutter from the edges, but a list, a collapsible section, or a box is not.
				Style()
					.position(.relative)
					.below(.smallTablet) {
						$0.directlyInside(ProseStyles.root.selector) {
							$0
								.margin(.horizontal, .length(-.pageGutter))
								.children(Self.pre.selector) {
									$0.cornerRadius(.zero)
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
					.frostedBackground(.lightDark(.gray(800).opacity(0.8), .black.opacity(0.7)), opaque: .lightDark(.gray(800), .black), blur: .pixels(6))
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
			case .pre:
				Style()
					.margin(.zero)
					.codeSurface()
					// The bar always shows on touch screens, so the code starts below it, instead of under it.
					.media(.cannotHover) {
						$0.padding(.top, .rootEm(2.75))
					}
					// On phones, smaller code with less space at the sides, so a line shows more characters.
					.below(.smallTablet) {
						$0
							.font(size: .rootEm(0.875))
							.padding(.horizontal, .rootEm(1))
					}
			case .code:
				// The font of the block, not of inline code.
				Style()
					.inheritsFont()
					.inherits(.color)
			case .console:
				// A long command wraps, so it can be read on a phone before it is pasted. The copy button copies it as one line. A wrapped line continues after the prompt, which hangs in the space at the start of the line. A line is an inline block, so it can have that space, and the line breaks between the lines stay the only breaks.
				Style()
					.textWrap(.wrap)
					.overflowWrap(.anywhere)
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
					}
			// The red of the strings, and a soft green, which both have enough contrast on the dark code.
			case .removed:
				Style().color("#ff8170")
			case .added:
				Style().color("#acf2a0")
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
