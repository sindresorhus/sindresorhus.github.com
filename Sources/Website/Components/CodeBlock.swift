import Elementary
import SiteKit

/**
A block of code, with its language and a copy button in a bar at the top right, like a fenced code block in Markdown (``SiteKit/MarkdownDocument/Options/codeBlock``).

Swift code is highlighted when the site builds, by the parser of Swift itself (``String/swiftCodeParts``), in the colors of Xcode. The code of other languages is plain. Each line of a `console` block is a command, after a `$ ` prompt that is not copied.

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
			this.querySelector('button').addEventListener('click', this.#copy);
		}

		// Without clipboard access, it does nothing, as the visitor can still select the code.
		#copy = async event => {
			const button = event.currentTarget;

			try {
				await navigator.clipboard.writeText(this.querySelector('code').textContent);
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
	var language: String?

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
			button(.type(.button)) {
				span {
					Icon.copy.size(.rootEm(0.875))
				}
				span {
					Icon.check.size(.rootEm(0.875))
				}
			}
			.accessibilityLabel("Copy code")
			.style(Styles.copyButton)
		}
		.style(Styles.bar)

		// Focusable, so keyboard users can scroll wide code.
		pre(.tabindex(0)) {
			code {
				switch language {
				case "swift":
					for part in source.swiftCodeParts {
						if let token = part.token {
							span {
								part.text
							}
							.style(Styles(token))
						} else {
							part.text
						}
					}
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

	enum Styles: ElementStyleSet {
		case root
		case bar
		case language
		case copyButton
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
			switch token {
			case .keyword:
				self = .keyword
			case .type:
				self = .type
			case .attribute:
				self = .attribute
			case .string:
				self = .string
			case .number:
				self = .number
			case .comment:
				self = .comment
			case .declaration:
				self = .declaration
			case .member:
				self = .member
			}
		}

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
					.top(.rootEm(0.5))
					.trailing(.rootEm(0.5))
					.hstack(alignment: .center, spacing: .rootEm(0.5))
					.font(size: .rootEm(0.75), lineHeight: 1.5)
					// A frosted backdrop in the color of the code, so the language and the button are easy to read over a long line of code.
					.padding(.leading, .rootEm(0.5))
					.cornerRadius(.rootEm(0.5))
					.background(.gray(800).opacity(0.8), dark: .black.opacity(0.7))
					.backdropFilter(.blur(radius: .pixels(6)))
					.reducedTransparency {
						$0
							.background(.gray(800), dark: .black)
							.backdropFilter(.none)
					}
					.opacity(0)
					.transition(.opacity, animation: .stateChange)
					.nested("\(Self.root.selector):hover &, \(Self.root.selector):focus-within &, &:has(> \(ScriptAttribute.state.selector()))") {
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
					.frame(width: .rootEm(1.75), height: .rootEm(1.75))
					.cornerRadius(.rootEm(0.5))
					.color(.gray(300))
					.background(.white.opacity(0.08))
					.shadow(Shadow(y: 0, spread: .pixels(1), color: .white.opacity(0.1), isInset: true))
					.transition(.color, .backgroundColor, animation: .stateChange)
					.children("span") {
						$0
							.stackedInGrid()
							.hstack(alignment: .center, justification: .center)
							.transition(.opacity, .scaleEffect, animation: .pop)
					}
					.children("span:last-child") {
						$0
							.color(.emerald(400))
							.opacity(0)
							.scaleEffect(0.5)
					}
					.when(.state, is: "copied") {
						$0
							.children("span:first-child") {
								$0
									.opacity(0)
									.scaleEffect(0.5)
							}
							.children("span:last-child") {
								$0
									.opacity(1)
									.scaleEffect(1)
							}
					}
					.hover {
						$0
							.color(.white)
							.background(.white.opacity(0.16))
					}
					.media(.scriptingDisabled) {
						$0.hidden()
					}
					.minimumTapArea()
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
