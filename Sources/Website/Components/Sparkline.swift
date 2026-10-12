import Elementary
import Foundation
import SiteKit

/**
A small line chart of numbers without axes, like the contributions of each week, to show a trend at a glance. The last number has a dot, as it is the newest. It is in the accent of the page, and fills the width of its container.

Limitation: It needs at least two numbers to draw a line.
*/
struct Sparkline: HTML {
	let values: [Int]

	/**
	What the chart shows, for screen readers, like the lowest, the highest, and the last number.
	*/
	let label: String

	var body: some HTML<HTMLTag.div> {
		let points = points
		// The line through the points.
		let line = "M" + points.map { "\($0.x) \($0.y)" }.joined(separator: "L")

		return div {
			// The scale of the drawing is not uniform, so it fills any width, and the lines keep their width (`vector-effect`).
			SVG.svg(
				.xmlns(),
				.viewBox(0, 0, .init(Swift.max(values.count - 1, 1)), 100),
				SVGAttribute(name: "preserveAspectRatio", value: "none"),
				SVGAttribute(name: "role", value: "img"),
				SVGAttribute(name: "aria-label", value: label)
			) {
				SVG.path(.fill("currentColor"), .fillOpacity(0.12), .d("\(line)L\(values.count - 1) 100L0 100Z"))
				SVG.path(.fill("none"), .stroke("currentColor"), .strokeWidth(2), .strokeLinejoin(.round), SVGAttribute(name: "vector-effect", value: "non-scaling-stroke"), .d(line))

				// A round cap on a line without length is a dot.
				if let last = points.last {
					SVG.path(.stroke("currentColor"), .strokeWidth(7), .strokeLinecap(.round), SVGAttribute(name: "vector-effect", value: "non-scaling-stroke"), .d("M\(last.x) \(last.y)h0"))
				}
			}
		}
		.style(Styles.root)
	}

	/**
	The points of the numbers, one unit apart, from the bottom (100) for zero to the top (0) for the highest number, rounded to whole units, which is less than a pixel.
	*/
	private var points: [(x: Int, y: Int)] {
		let highest = Swift.max(values.max() ?? 0, 1)

		return values.enumerated().map { index, value in
			(index, 100 - ((value * 100) + (highest / 2)) / highest)
		}
	}

	enum Styles: StyleSet {
		case root

		var style: Style {
			Style()
				.color(.accentMark)
				.children("svg") {
					$0
						.display(.block)
						.frame(width: .percent(100), height: .rootEm(3))
						// The lines and the dot can go a little outside the drawing, so it does not cut them.
						.overflow(.visible)
				}
		}
	}
}
