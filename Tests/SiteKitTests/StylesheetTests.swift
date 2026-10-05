import Testing
import SiteKit

@Suite
struct StylesheetTests {
	@Test
	func `renders typed and raw declarations in order`() {
		let css = Stylesheet {
			Rule(".card", Style()
				.display(.flex)
				.padding(vertical: .rootEm(0.5), horizontal: .rootEm(1.5))
				.color(Color("red").opacity(0.06))
				.declaration(.webkitBackdropFilter, "blur(14px)")
				.declaration(Property("--accent"), "#2563eb")
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

			Media(.from(Breakpoint(minimumWidthInRem: 40))) {
				Rule(".c", Style().gap(.rootEm(1)))
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
		@media (width >= 40rem) {
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

	@Test
	func `merges sibling conditions with the same query`() {
		let css = Stylesheet {
			Rule(".a", Style()
				.dark {
					$0.color("white")
				}
				.dark {
					$0.hover {
						$0.color("gray")
					}
				}
			)
		}.css

		#expect(css == """
		.a {
			@media (prefers-color-scheme: dark) {
				color: white;
				@media (hover: hover) {
					&:hover {
						color: gray;
					}
				}
			}
		}

		""")
	}

	@Test
	func `keeps sibling conditions apart when merging would reorder declarations`() {
		let css = Stylesheet {
			Rule(".a", Style()
				.dark {
					$0.hover {
						$0.color("gray")
					}
				}
				.dark {
					$0.color("white")
				}
			)
		}.css

		#expect(css.ranges(of: "@media (prefers-color-scheme: dark)").count == 2)
	}

	@Test
	func `black and white with opacity are plain rgb`() {
		#expect(Color.black.opacity(0.5).description == "rgb(0 0 0 / 50%)")
		#expect(Color.white.opacity(0.035).description == "rgb(255 255 255 / 3.5%)")
		#expect(Color("red").opacity(0.5).description == "color-mix(in oklab, red 50%, transparent)")
	}
}
