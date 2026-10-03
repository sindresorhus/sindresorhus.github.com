import Testing
import SiteKit

@Suite
struct StylesheetTests {
	@Test
	func `renders typed and raw declarations in order`() {
		let css = Stylesheet {
			Rule(".card", Style()
				.display(.flex)
				.padding(vertical: .rem(0.5), horizontal: .rem(1.5))
				.color(Color("red").opacity(0.06))
				.declaration("-webkit-backdrop-filter", "blur(14px)")
				.declaration("--accent", "#2563eb")
				.zIndex(40)
			)
		}.css

		#expect(css == """
		.card {
			display: flex;
			padding: .5rem 1.5rem;
			color: color-mix(in oklab, red 6%, transparent);
			-webkit-backdrop-filter: blur(14px);
			--accent: #2563eb;
			z-index: 40;
		}

		""")
	}

	@Test
	func `nests rules and media queries`() {
		let css = Stylesheet {
			Rule(".a, .b", Style()
				.color("red")
				.hover {
					$0.color("blue")
				}
				.nested("span") {
					$0.margin(0)
				}
				.media(.dark && .hover) {
					$0.color("white")
				}
			)

			Media(.minWidth(.px(640))) {
				Rule(".c", Style().gap(.rem(1)))
			}

			Keyframes("spin") {
				Rule("to", Style().transform("rotate(360deg)"))
			}
		}.css

		#expect(css == """
		.a, .b {
			color: red;
			@media (hover: hover) {
				&:hover {
					color: blue;
				}
			}
			span {
				margin: 0;
			}
			@media (prefers-color-scheme: dark) and (hover: hover) {
				color: white;
			}
		}
		@media (min-width: 640px) {
			.c {
				gap: 1rem;
			}
		}
		@keyframes spin {
			to {
				transform: rotate(360deg);
			}
		}

		""")
	}

	@Test
	func `keeps selectors with parentheses intact`() {
		let css = Stylesheet {
			Rule("table:not(:has(> thead, > tfoot))", Style()
				.nested("> tbody") {
					$0.display(.block)
				}
			)
		}.css

		#expect(css.hasPrefix("table:not(:has(> thead, > tfoot)) {\n\t> tbody {"))
	}
}
