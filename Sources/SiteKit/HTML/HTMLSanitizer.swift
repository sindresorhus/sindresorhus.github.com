import Foundation

extension String {
	/**
	The HTML without unsafe parts, like scripts and event handlers, for embedding untrusted HTML in a feed.

	It keeps text and structure tags (no images or forms) and only the `href`, `name`, and `target` attributes of links, with safe URL schemes. Text outside the kept tags is escaped, so a `<` can never start a new tag. Characters that XML does not allow, like `&#0;`, are removed, so a feed with the HTML is always valid.
	*/
	public var sanitizedHTML: String {
		let html = replacing(/(?s)<!--.*?-->/, with: "")
			// These tags are removed with their content, not just the tags.
			.replacing(/(?is)<\s*(script|style|textarea|option)\b[^>]*>.*?<\s*\/\s*\1\s*>/, with: "")

		var result = ""
		var textStart = html.startIndex

		for match in html.matches(of: Self.tag) {
			result += html[textStart..<match.range.lowerBound].escapingAngleBrackets
			result += Self.sanitizedTag(name: match.2.lowercased(), attributes: String(match.3), isClosing: !match.1.isEmpty)
			textStart = match.range.upperBound
		}

		return result + html[textStart...].escapingAngleBrackets
	}
}

extension String {
	nonisolated(unsafe) fileprivate static let tag = /(?is)<(\/?)([a-z][a-z0-9]*)([^<>]*)>/
	nonisolated(unsafe) fileprivate static let attribute = /(?i)([a-z_:][-a-z0-9_:.]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>]+))/
	nonisolated(unsafe) fileprivate static let numericCharacterReference = /&#([xX][0-9a-fA-F]+|[0-9]+);?/

	/**
	The text with numeric character references and the basic named entities decoded, or `nil` when it has another named entity, which a sanitizer cannot safely interpret.
	*/
	fileprivate var decodingHTMLEntities: String? {
		let named = ["amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'"]
		var isValid = true

		let decoded = replacing(/&(#[xX][0-9a-fA-F]+|#[0-9]+|[a-zA-Z][a-zA-Z0-9]*);?/) { match in
			let entity = String(match.1)

			if entity.hasPrefix("#") {
				let isHexadecimal = entity.dropFirst().first.map { $0 == "x" || $0 == "X" } ?? false
				let digits = entity.dropFirst(isHexadecimal ? 2 : 1)

				guard
					let code = UInt32(digits, radix: isHexadecimal ? 16 : 10),
					let scalar = Unicode.Scalar(code)
				else {
					isValid = false
					return ""
				}

				return scalar.isAllowedInXML ? String(Character(scalar)) : ""
			}

			guard let character = named[entity.lowercased()] else {
				isValid = false
				return ""
			}

			return character
		}

		return isValid ? decoded : nil
	}
}

extension StringProtocol {
	/**
	Escapes `<` and `>`, but keeps entities like `&amp;` as they are, because the text is already HTML. Character references to characters that XML does not allow are removed.
	*/
	fileprivate var escapingAngleBrackets: String {
		// Unicode scalars, as a combining mark after `<` makes them one character, which would not equal `<`.
		var text = ""

		for scalar in unicodeScalars {
			switch scalar {
			case "<":
				text += "&lt;"
			case ">":
				text += "&gt;"
			default:
				text.unicodeScalars.append(scalar)
			}
		}

		if text.contains("&#") {
			text = text.replacing(String.numericCharacterReference) { match in
				let digits = match.1
				let isHexadecimal = digits.first == "x" || digits.first == "X"

				guard
					let code = UInt32(digits.dropFirst(isHexadecimal ? 1 : 0), radix: isHexadecimal ? 16 : 10),
					Unicode.Scalar(code)?.isAllowedInXML == true
				else {
					return ""
				}

				return String(match.0)
			}
		}

		return text
	}
}

extension String {
	fileprivate static let allowedTags: Set<String> = [
		"address", "article", "aside", "footer", "header", "h1", "h2", "h3", "h4", "h5", "h6", "hgroup", "main", "nav", "section",
		"blockquote", "dd", "div", "dl", "dt", "figcaption", "figure", "hr", "li", "menu", "ol", "p", "pre", "ul",
		"a", "abbr", "b", "bdi", "bdo", "br", "cite", "code", "data", "dfn", "em", "i", "kbd", "mark", "q", "rb", "rp", "rt", "rtc", "ruby",
		"s", "samp", "small", "span", "strong", "sub", "sup", "time", "u", "var", "wbr",
		"caption", "col", "colgroup", "table", "tbody", "td", "tfoot", "th", "thead", "tr",
	]

	fileprivate static let voidTags: Set<String> = ["br", "hr", "wbr"]
	fileprivate static let allowedLinkAttributes: Set<String> = ["href", "name", "target"]
	fileprivate static let allowedSchemes: Set<String> = ["http", "https", "ftp", "mailto", "tel"]

	fileprivate static func sanitizedTag(name: String, attributes: String, isClosing: Bool) -> String {
		guard allowedTags.contains(name) else {
			return ""
		}

		if voidTags.contains(name) {
			return isClosing ? "" : "<\(name) />"
		}

		if isClosing {
			return "</\(name)>"
		}

		guard name == "a" else {
			return "<\(name)>"
		}

		let keptAttributes = attributes.matches(of: attribute).compactMap { match -> String? in
			let attribute = match.1.lowercased()

			// The value is HTML, so it is decoded before the URL check (`&#58;` is a colon) and escaped once on output.
			guard
				allowedLinkAttributes.contains(attribute),
				let value = (match.2 ?? match.3 ?? match.4).flatMap({ String($0).decodingHTMLEntities }),
				attribute != "href" || isSafeURL(value)
			else {
				return nil
			}

			return #"\#(attribute)="\#(value.escapedForHTML)""#
		}

		return keptAttributes.isEmpty ? "<a>" : "<a \(keptAttributes.joined(separator: " "))>"
	}

	/**
	Relative URLs and URLs with an allowed scheme are safe. This rejects `javascript:` and `data:` URLs.
	*/
	fileprivate static func isSafeURL(_ value: String) -> Bool {
		let url = value.trimmingCharacters(in: .whitespacesAndNewlines)

		guard let colon = url.firstIndex(of: ":") else {
			return true
		}

		if let slash = url.firstIndex(of: "/"), slash < colon {
			return true
		}

		return allowedSchemes.contains(url[..<colon].lowercased())
	}
}

extension Unicode.Scalar {
	/**
	Whether XML 1.0 allows the character. Most control characters are not allowed, even as character references.
	*/
	fileprivate var isAllowedInXML: Bool {
		switch value {
		case 0x9, 0xA, 0xD, 0x20...0xD7FF, 0xE000...0xFFFD, 0x10000...0x10FFFF:
			true
		default:
			false
		}
	}
}
