import SiteKit

extension Stylesheet {
	static let sitePath: RoutePath = "/assets/site.css"

	/**
	The stylesheet that every page links to, so browsers cache it: the element defaults and the Markdown typography.

	Each page has the styles of its components in a `<style>` element, collected while it renders, so no list of components has to be kept in sync. Markdown renders before the page, so a document collects the styles of its block directives, and the page adds them when it shows the document (``MarkdownContent``). The components here are the ones that most pages use, so they are cached with the stylesheet.
	*/
	static let site = Stylesheet {
		// Element defaults, then Markdown typography, then components, then the styles of single elements. A later layer wins whatever the specificity, so components always win over the typography around them, and a style on an element wins over its component.
		Layer(.base) {
			base
		}

		Layer(.prose) {
			ProseStyles.self
		}

		// Most pages use these, so they are cached with the stylesheet.
		Layer(.components) {
			VisuallyHidden.Styles.self
			ButtonStyles.self
		}

		// The styles that only one element has, which pages add (``ElementStyle``). Empty here, so the order of the layers has it.
		Layer(.elements) {}
	}
}

extension CascadeLayer {
	/**
	The element defaults.
	*/
	static let base = Self("base")

	/**
	The typography of Markdown output.
	*/
	static let prose = Self("prose")

	/**
	The styles of components, which win over the typography around them.
	*/
	static let components = Self("components")

	/**
	The styles that only one element has, written on the element (`.style { … }`), which win over the styles of its component.
	*/
	static let elements = Self("elements")
}

extension Stylesheet {
	/**
	The element defaults and utilities that every page uses.
	*/

	static let base = Stylesheet {
		Rule(":root", Palette.customProperties
			.combined(with: SemanticColor.customProperties)
			.colorScheme(.lightDark)
			// Animate details open/close via ::details-content (requires interpolate-size support)
			.declaration(.interpolateSize, "allow-keywords")
		)

		// A small reset: elements have no spacing or borders until a component styles them.
		Rule("*, ::before, ::after", Style()
			.declaration(.boxSizing, "border-box")
			.margin(0)
			.padding(0)
			.declaration(.border, "0 solid")
		)

		document

		Rule("h1, h2, h3, h4, h5, h6", Style()
			.declaration(.fontSize, .inherit)
			.declaration(.fontWeight, .inherit)
			// Lines of a heading get similar lengths, instead of a last line with one word.
			.textWrap(.balance)
		)

		// Avoids a last line with one word, and short lines in the middle of paragraphs.
		Rule("p, li, dd, blockquote", Style().textWrap(.pretty))

		// In the accent of the page, like the color of the app on an app page. See-through, so the text keeps its color, also the colors of highlighted code on the dark code blocks.
		Rule("::selection", Style()
			.background(Color.accent.value(default: .primary(500)).opacity(0.22), dark: Color.accent.value(default: .primary(400)).opacity(0.35))
		)

		Rule("a", Style()
			.color(.inherit)
			.declaration(.textDecoration, .inherit)
		)

		Rule("hr", Style()
			.frame(height: 0)
			.color(.inherit)
			.border(.top, width: .pixels(1))
		)

		Rule("b, strong", Style().declaration(.fontWeight, "bolder"))

		Rule("code, kbd, samp, pre", Style().fontFamily(.monospace))

		Rule("ol, ul, menu", Style().declaration(.listStyle, .none))

		Rule("img, svg, video, canvas", Style()
			.display(.block)
			.verticalAlign(.middle)
		)

		Rule("img, video", Style().frame(height: .auto, maxWidth: .percent(100)))

		Rule("button, input, select, optgroup, textarea", Style()
			.inheritsFont()
			.color(.inherit)
			.declaration(.letterSpacing, .inherit)
			.background(.transparent)
		)

		Rule("button, label[for]", Style().cursor(.pointer))

		Rule("[hidden]", Style()
			.important {
				$0.hidden()
			}
		)
	}
}
