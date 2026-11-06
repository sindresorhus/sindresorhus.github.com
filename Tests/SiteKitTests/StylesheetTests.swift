import Testing
import SiteKit

struct StylesheetTests {
	@Test
	func `media condition trees preserve mixed grouping and media types`() {
		#expect(((!MediaCondition.hover || .coarsePointer) && .dark).description == "((not (hover: hover)) or (pointer: coarse)) and (prefers-color-scheme: dark)")
		#expect((!(MediaCondition.dark && .hover)).description == "not ((prefers-color-scheme: dark) and (hover: hover))")
		#expect((MediaQuery.print(matching: .dark || .moreContrast)).description == "print and ((prefers-color-scheme: dark) or (prefers-contrast: more))")
		#expect((MediaCondition.dark && .hover && .allowsMotion).description == "(prefers-color-scheme: dark) and (hover: hover) and (prefers-reduced-motion: no-preference)")
		#expect(MediaQuery(raw: "screen, print").description == "screen, print")
	}

	@Test
	func `complete media queries and conditions render at their distinct entry points`() {
		let condition = MediaCondition.hover || .dark
		let css = Stylesheet {
			Media(.print(matching: condition)) {
				Rule(".print", Style().opacity(0.5))
			}
			Media(condition) {
				Rule(".screen", Style().opacity(1))
			}
			Media(MediaQuery(raw: "screen, print")) {
				Rule(".both", Style().opacity(1))
			}
		}.css
		#expect(css.contains("@media print and ((hover: hover) or (prefers-color-scheme: dark)) {"))
		#expect(css.contains("@media (hover: hover) or (prefers-color-scheme: dark) {"))
		#expect(css.contains("@media screen, print {"))
		#expect(MediaQuery(condition).description == condition.description)
		#expect(MediaQuery.print(matching: !.hover).description == "print and (not (hover: hover))")
	}

	@Test
	func `renders typed and raw declarations in order`() {
		let css = Stylesheet {
			Rule(
				".card",
				Style()
				.display(.flex)
				.padding(vertical: .rootEm(0.5), horizontal: .rootEm(1.5))
				.color(Color(raw: "red").opacity(0.06))
				.declaration(raw: .webkitBackdropFilter, "blur(14px)")
				.declaration(raw: Property("--accent"), "#2563eb")
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
			Rule(
				".a, .b",
				Style()
				.color("red")
				.hover {
					$0.color("blue")
				}
				.nested("span") {
					$0.margin(.zero)
				}
				.media(.dark && .hover) {
					$0.color("white")
				}
			)

			Media(.from(Breakpoint(minimumWidthInRem: 40))) {
				Rule(".c", Style().gap(.rootEm(1)))
			}

			Keyframes("spin", .to(Style().transform(.rotate(.degrees(360)))))
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
	func `keyframes in a condition are written once in it, and again outside it`() {
		let animated = Style().animation(FadeAnimations.fade, .default(duration: .seconds(1)))
		let css = Stylesheet {
			Media(.dark) {
				Rule(".a", animated)
				Rule(".b", animated)
			}

			Rule(".c", animated)
		}.css

		#expect(css.ranges(of: "@keyframes fade-fade").count == 2)
	}

	@Test
	func `keeps selectors with parentheses intact`() {
		let css = Stylesheet {
			Rule(
				"table:not(:has(> thead, > tfoot))",
				Style()
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
			Rule(
				".a",
				Style()
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
			Rule(
				".a",
				Style()
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
		#expect(Color(raw: "red").opacity(0.5).description == "color-mix(in oklab, red 50%, transparent)")
	}
}
