import Foundation

public enum OGImageGenerator {
	public static func generate(apps: [App], root: URL, output: URL) throws {
		let outputDirectory = output.appending(path: "og")
		try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

		let cards = [
			Card(
				slug: "sindre-sorhus",
				title: SiteConfiguration.name,
				subtitle: SiteConfiguration.description,
				imagePath: root.appending(path: "public/assets/sindre-sorhus.jpg")
			)
		] + apps.map {
			Card(
				slug: $0.slug,
				title: $0.title,
				subtitle: $0.subtitle,
				imagePath: root.appending(path: "public" + $0.iconURL)
			)
		}

		for card in cards {
			try generate(card: card, outputDirectory: outputDirectory)
		}
	}

	private static func generate(card: Card, outputDirectory: URL) throws {
		let svgURL = outputDirectory.appending(path: ".\(card.slug).svg")
		let pngURL = outputDirectory.appending(path: "\(card.slug).png")
		let svg = try renderSVG(card)
		try svg.write(to: svgURL, atomically: true, encoding: .utf8)

		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/usr/bin/rsvg-convert")
		process.arguments = [
			"--width", "1200",
			"--height", "630",
			"--output", pngURL.path,
			svgURL.path,
		]
		let errorPipe = Pipe()
		process.standardError = errorPipe
		try process.run()
		process.waitUntilExit()

		guard process.terminationStatus == 0 else {
			let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
			let message = String(data: data, encoding: .utf8) ?? "Unknown rsvg-convert error"
			throw OGError.renderFailed(card.slug, message)
		}

		try? FileManager.default.removeItem(at: svgURL)
	}

	private static func renderSVG(_ card: Card) throws -> String {
		let image = try imageDataURL(card.imagePath)
		let titleLines = wrap(card.title, maximumWeightedCharacters: 20)
		let subtitleLines = wrap(card.subtitle, maximumWeightedCharacters: 40)
		let titleStartY = titleLines.count > 1 ? 218 : 250
		let title = tspans(titleLines, x: 344, startY: titleStartY, lineHeight: 76)
		let subtitleStartY = titleStartY + titleLines.count * 76 + 18
		let subtitle = tspans(subtitleLines, x: 344, startY: subtitleStartY, lineHeight: 45)
		let domainY = min(570, subtitleStartY + subtitleLines.count * 45 + 38)

		return """
		<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
			<defs>
				<linearGradient id="background" x1="0" y1="0" x2="1" y2="1">
					<stop offset="0%" stop-color="#f8fafc"/>
					<stop offset="100%" stop-color="#e2e8f0"/>
				</linearGradient>
				<filter id="shadow" x="-40%" y="-40%" width="180%" height="200%">
					<feDropShadow dx="0" dy="20" stdDeviation="22" flood-color="#000000" flood-opacity="0.15"/>
				</filter>
				<clipPath id="icon-clip">
					<rect x="80" y="215" width="200" height="200" rx="46" ry="46"/>
				</clipPath>
			</defs>
			<rect width="1200" height="630" fill="url(#background)"/>
			(image.map { #"<image href="#($0)" x="80" y="215" width="200" height="200" preserveAspectRatio="xMidYMid slice" clip-path="url(#icon-clip)" filter="url(#shadow)"/>"# } ?? "")
			<g font-family="Inter, sans-serif">
				<text fill="#0f172a" font-size="68" font-weight="700">(title)</text>
				<text fill="#64748b" font-size="32" font-weight="400">(subtitle)</text>
				<text x="344" y="(domainY)" fill="#94a3b8" font-size="22" font-weight="700">sindresorhus.com</text>
			</g>
		</svg>
		"""
	}

	private static func imageDataURL(_ url: URL) throws -> String? {
		guard FileManager.default.fileExists(atPath: url.path) else { return nil }
		let data = try Data(contentsOf: url)
		let mimeType = url.pathExtension.lowercased() == "png" ? "image/png" : "image/jpeg"
		return "data:\(mimeType);base64,\(data.base64EncodedString())"
	}

	private static func wrap(_ string: String, maximumWeightedCharacters: Int) -> [String] {
		let words = string.split(whereSeparator: \.isWhitespace).map(String.init)
		guard !words.isEmpty else { return [""] }

		var lines: [String] = []
		var current = ""

		for word in words {
			let candidate = current.isEmpty ? word : "\(current) \(word)"
			if weightedLength(candidate) <= maximumWeightedCharacters || current.isEmpty {
				current = candidate
			} else {
				lines.append(current)
				current = word
			}
		}
		if !current.isEmpty { lines.append(current) }
		return lines
	}

	private static func weightedLength(_ string: String) -> Int {
		string.reduce(into: 0) { result, character in
			result += "MW@#%".contains(character) ? 2 : 1
		}
	}

	private static func tspans(_ lines: [String], x: Int, startY: Int, lineHeight: Int) -> String {
		lines.enumerated().map { index, line in
			#"<tspan x="#(x)" y="#(startY + index * lineHeight)">#(TextUtilities.escapeXML(line))</tspan>"#
		}.joined()
	}

	private struct Card {
		let slug: String
		let title: String
		let subtitle: String
		let imagePath: URL
	}

	private enum OGError: Error {
		case renderFailed(String, String)
	}
}
