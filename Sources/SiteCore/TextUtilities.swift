import Foundation

public enum TextUtilities {
	public static func shortenForSnippet(_ text: String) -> String {
		let maximumLength = 160
		guard text.count > maximumLength else { return text }
		let end = text.index(text.startIndex, offsetBy: maximumLength - 1)
		let shortened = String(text[..<end])
		let boundary = shortened.lastIndex(of: " ") ?? shortened.endIndex
		return String(shortened[..<boundary]).trimmingCharacters(in: CharacterSet(charactersIn: ",.:;")) + "…"
	}

	public static func slugify(_ value: String) -> String {
		let strippedHTML = value.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
		let folded = strippedHTML.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX")).lowercased()
		let scalars = folded.unicodeScalars.filter { scalar in
			CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "_" || CharacterSet.whitespacesAndNewlines.contains(scalar)
		}
		return String(String.UnicodeScalarView(scalars))
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.replacingOccurrences(of: #"\s+"#, with: "-", options: .regularExpression)
			.replacingOccurrences(of: #"-+"#, with: "-", options: .regularExpression)
	}

	public static func escapeHTML(_ value: String) -> String {
		value
			.replacingOccurrences(of: "&", with: "&amp;")
			.replacingOccurrences(of: "<", with: "&lt;")
			.replacingOccurrences(of: ">", with: "&gt;")
			.replacingOccurrences(of: "\"", with: "&quot;")
	}

	public static func escapeXML(_ value: String) -> String { escapeHTML(value) }

	public static func formattedMonth(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US")
		formatter.dateFormat = "MMMM yyyy"
		return formatter.string(from: date)
	}

	public static func formattedDate(_ value: String) -> String {
		let input = ISO8601DateFormatter()
		guard let date = input.date(from: value) else { return value }
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US")
		formatter.dateStyle = .long
		formatter.timeStyle = .none
		return formatter.string(from: date)
	}

	public static func isoDate(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.calendar = Calendar(identifier: .gregorian)
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		formatter.dateFormat = "yyyy-MM-dd"
		return formatter.string(from: date)
	}
}
