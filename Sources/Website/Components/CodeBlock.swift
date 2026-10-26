import Elementary
import SiteKit

/**
A block of code, with its language and a copy button in a bar at the top right, like a fenced code block in Markdown (``SiteKit/MarkdownDocument/Options/codeBlock``).

Swift code is highlighted when the site builds, by the parser of Swift itself (``String/swiftCodeParts``), in the colors of Xcode. SOML code is highlighted by the lexer of SOML (``String/somlCodeParts``), in the same colors. The code of other languages is plain. Each line of a `console` block is a command, after a `$ ` prompt that is not copied.

```swift
CodeBlock(source: "let greeting = \"Hello\"", language: "swift")
```
*/
struct CodeBlock: ScriptedElement {
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		// The pending timer that removes the copied state, so a second click restarts it.
		#copiedStateTimer;

		connectedCallback() {
			// The same function, so connecting the element again does not add a second listener.
			this.querySelector('[data-part="copyButton"]').addEventListener('click', this.#copy);
		}

		// Without clipboard access, it does nothing, as the visitor can still select the code.
		#copy = async event => {
			const button = event.currentTarget;

			try {
				await navigator.clipboard.writeText(this.querySelector('[data-part="code"]').textContent);
			} catch {
				return;
			}

			button.dataset.state = 'copied';
			// Older browsers, like Safari 26, have no `ariaNotify`. They say nothing, but the copied state still goes away.
			button.ariaNotify?.('Copied');

			clearTimeout(this.#copiedStateTimer);
			this.#copiedStateTimer = setTimeout(() => {
				delete button.dataset.state;
			}, 1500);
		};
	}
	"""#)

	let source: String

	/**
	The language, like `swift`, which the bar shows.
	*/
	let language: String?

	/**
	The HTML of a code block, for ``SiteKit/MarkdownDocument/Options/codeBlock``.
	*/
	@Sendable
	static func render(source: String, language: String?) -> String {
		Self(source: source, language: language).render()
	}

	var content: some HTML {
		div {
			if let language {
				span {
					language
				}
				.style(Styles.language)
			}

			// A copy icon, and a checkmark that the styles show after copying.
			button(.type(.button), .part(Parts.copyButton)) {
				span {
					Icon.copy.size(.rootEm(0.875))
				}
				.style(Styles.copyIcon)

				span {
					Icon.check.size(.rootEm(0.875), strokeWidth: 2.75)
				}
				.style(Styles.checkmark)
			}
			.accessibilityLabel("Copy code")
			.style(Styles.copyButton)
		}
		.style(Styles.bar)

		// Focusable, so keyboard users can scroll wide code.
		// Code is not translated, as a translation would change the command that the copy button copies.
		pre(.tabindex(0), .notTranslated) {
			code(.part(Parts.code)) {
				switch language {
				case "swift":
					Self.highlighted(source.swiftCodeParts)
				case "soml":
					Self.highlighted(source.somlCodeParts)
				case "console":
					for (index, line) in source.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
						if index > 0 {
							"\n"
						}

						if !line.isEmpty {
							span {
								String(line)
							}
						}
					}
				default:
					source
				}
			}
			.style(Styles.code)
			.style(Styles.console, when: language == "console")
		}
		.style(Styles.pre)
	}

	/**
	The parts of highlighted code, with each colored part in a span with the style of its kind.
	*/
	@HTMLBuilder
	private static func highlighted(_ parts: [(text: String, token: CodeToken?)]) -> some HTML {
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

	enum Parts: String, ElementPartSet {
		case copyButton
		case code
	}

	enum States: String, ElementStateSet {
		case copied
	}

	enum Styles: ElementStyleSet {
		case root
		case bar
		case language
		case copyButton
		case copyIcon
		case checkmark
		case pre
		case code

		/**
		Each line is a command, after a faded `$ ` prompt. The prompt is generated content, so it is not selected or copied, and screen readers skip it.
		*/
		case console

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
		private static let barInset = Length.rootEm(0.5)

		/**
		The corners of the bar and its button, parallel to the corner of the code around them.
		*/
		private static let barRadius = Length.windowRadius - barInset

		var style: Style {
			switch self {
			case .root:
				// The bar is positioned in the corner of the code.
				Style()
					.display(.block)
					.position(.relative)
			case .bar:
				// The bar shows while the pointer is over the code or it has focus, while the button shows its checkmark, and always on touch screens.
				Style()
					.position(.absolute)
					.top(Self.barInset)
					.trailing(Self.barInset)
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.font(.extraSmall)
					.padding(.leading, .rootEm(0.5))
					.cornerRadius(Self.barRadius)
					// A frosted backdrop in the color of the code, so the language and the button are easy to read over a long line of code.
					.frostedBackground(.lightDark(.gray(800).opacity(0.8), .black.opacity(0.7)), opaque: .lightDark(.gray(800), .black), blur: .pixels(6))
					.opacity(0)
					.transition(.opacity, animation: .stateChange)
					.nested("\(Self.root.selector):hover &, \(Self.root.selector):focus-within &, &:has(> \(States.copied.selector))") {
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
			case .copyButton:
				// A square button with a copy icon. After copying, the icon fades out, and a green checkmark grows in. Without JavaScript, there is no copy button.
				Style()
					.display(.grid)
					.frame(size: .rootEm(1.75))
					.cornerRadius(Self.barRadius)
					.color(.gray(300))
					.background(.white.opacity(0.08))
					.shadow(.edge(.white.opacity(0.1)))
					.hoverFill(.white.opacity(0.16), color: .white)
					.hiddenWithoutScripting()
					.minimumTapArea()
			case .copyIcon:
				Style()
					.hstack(alignment: .center, justification: .center)
					.copyLabel(hiddenWhen: States.copied)
			case .checkmark:
				Style()
					.color(.emerald(400))
					.copiedCheckmark(when: States.copied)
			case .pre:
				Style()
					.margin(0)
					.codeSurface()
					// The bar always shows on touch screens, so the code starts below it, instead of under it.
					.media(.cannotHover) {
						$0.padding(.top, .rootEm(2.75))
					}
			case .code:
				// The font of the block, not of inline code.
				Style()
					.inheritsFont()
					.color(.inherit)
			case .console:
				Style().children("span") {
					$0.before {
						$0
							.content("$ ", alternativeText: "")
							.opacity(0.5)
					}
				}
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
