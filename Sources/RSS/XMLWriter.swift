/**
Writes indented XML with correct escaping.
*/
struct XMLWriter {
	private(set) var output = ""
	private var depth = 0

	mutating func declaration() {
		output += #"<?xml version="1.0" encoding="UTF-8"?>"# + "\n"
	}

	mutating func element(_ name: String, attributes: [(String, String)] = [], content: (inout Self) -> Void) {
		line("<\(name)\(Self.render(attributes))>")
		depth += 1
		content(&self)
		depth -= 1
		line("</\(name)>")
	}

	mutating func element(_ name: String, attributes: [(String, String)] = [], text: String) {
		line("<\(name)\(Self.render(attributes))>\(text.escapedForXML)</\(name)>")
	}

	mutating func element(_ name: String, attributes: [(String, String)]) {
		line("<\(name)\(Self.render(attributes))/>")
	}

	/**
	Writes the text as CDATA, which keeps HTML readable. A `]]>` sequence in the text is split across two sections.
	*/
	mutating func element(_ name: String, characterData: String) {
		let text = characterData.removingCharactersNotAllowedInXML
			.replacing("]]>", with: "]]]]><![CDATA[>")
		line("<\(name)><![CDATA[\(text)]]></\(name)>")
	}

	private mutating func line(_ string: String) {
		output += String(repeating: "\t", count: depth) + string + "\n"
	}

	private static func render(_ attributes: [(String, String)]) -> String {
		attributes
			.map { name, value in
				#" \#(name)="\#(value.escapedForXML)""#
			}
			.joined()
	}
}

extension String {
	/**
	The text with `&`, `<`, `>`, `"`, and `'` escaped, and without the characters that XML 1.0 does not allow.
	*/
	fileprivate var escapedForXML: String {
		var result = ""
		result.reserveCapacity(utf8.count)

		// Unicode scalars, as a combining mark after `&` makes them one character, which would not equal `&`.
		for scalar in unicodeScalars where scalar.isAllowedInXML {
			switch scalar {
			case "&":
				result += "&amp;"
			case "<":
				result += "&lt;"
			case ">":
				result += "&gt;"
			case "\"":
				result += "&quot;"
			case "'":
				result += "&apos;"
			default:
				result.unicodeScalars.append(scalar)
			}
		}

		return result
	}

	/**
	The string without the characters that XML 1.0 does not allow, like most control characters.
	*/
	fileprivate var removingCharactersNotAllowedInXML: String {
		String(String.UnicodeScalarView(unicodeScalars.filter(\.isAllowedInXML)))
	}
}

extension Unicode.Scalar {
	fileprivate var isAllowedInXML: Bool {
		switch value {
		case 0x9, 0xA, 0xD, 0x20...0xD7FF, 0xE000...0xFFFD, 0x10000...0x10FFFF:
			true
		default:
			false
		}
	}
}
