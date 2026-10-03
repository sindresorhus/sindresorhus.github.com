import SiteKit

extension Stylesheet {
	static let sitePath: RoutePath = "/assets/site.css"

	/**
	The stylesheet that every page links to, so browsers cache it: the element defaults, the Markdown typography, and the classes in the raw HTML of the content.

	Each page has the styles of its components in a `<style>` element, collected while it renders, so no list of components has to be kept in sync. The components here are the ones that Markdown output refers to by class name, like platform badges, which rendering cannot find.
	*/
	static let site = Stylesheet {
		// Element defaults, then Markdown typography, then the classes in the raw HTML of the content, then components. A later layer wins whatever the specificity, so components always win over the typography around them.
		Layers("base", "prose", "content", "components")

		Layer("base") {
			base
		}

		Layer("prose") {
			ProseStyles.self
		}

		Layer("content") {
			content
		}

		Layer("components") {
			VisuallyHidden.Styles.self
			Badge.Styles.self
			Badge.Kind.self
		}
	}

	/**
	The component styles in the shared stylesheet, which pages do not repeat.
	*/
	static let sharedStyleSets: [any StyleSet.Type] = [ProseStyles.self, VisuallyHidden.Styles.self, Badge.Styles.self, Badge.Kind.self]
}

extension Stylesheet {
	/**
	The element defaults and utilities that every page uses.
	*/

	static let base = Stylesheet {
		Rule(":root", Palette.customProperties
			.combined(with: SemanticColor.customProperties)
			.declaration(.colorScheme, "light dark")
			// Animate details open/close via ::details-content (requires interpolate-size support)
			.supports("(interpolate-size: allow-keywords)") {
				$0.declaration(.interpolateSize, "allow-keywords")
			}
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

		Rule("::selection", Style()
			.color(.primaryText)
			.background(.secondary(200), dark: .secondary(800))
		)

		Rule("a", Style()
			.color(.inherit)
			.declaration(.textDecoration, .inherit)
		)

		Rule("hr", Style()
			.frame(height: 0)
			.color(.inherit)
			.declaration(.borderTopWidth, .px(1))
		)

		Rule("b, strong", Style().declaration(.fontWeight, "bolder"))

		Rule("code, kbd, samp, pre", Style().fontFamily(.monospace))

		Rule("ol, ul, menu", Style().declaration(.listStyle, .none))

		Rule("img, svg, video, canvas", Style()
			.display(.block)
			.declaration(.verticalAlign, "middle")
		)

		Rule("img, video", Style().frame(height: .auto, maxWidth: .percent(100)))

		Rule("button, input, select, optgroup, textarea", Style()
			.declaration(.font, .inherit)
			.color(.inherit)
			.declaration(.letterSpacing, .inherit)
			.background(.transparent)
		)

		Rule("button, label[for]", Style().cursor(.pointer))

		Rule("table", Style().declaration(.borderCollapse, "collapse"))

		// Pages cross-fade when the visitor follows a link, and app icons morph into the icon of the next page. Not for visitors who prefer reduced motion.
		Media("(prefers-reduced-motion: no-preference)") {
			Rule("@view-transition", Style().declaration("navigation", "auto"))
		}

		Rule("::view-transition-group(*.app-icon)", Style().declaration("animation-duration", ".4s"))

		Rule("[hidden]", Style()
			.important {
				$0.display(.none)
			}
		)
	}
}
