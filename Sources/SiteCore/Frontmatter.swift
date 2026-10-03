import Foundation
import Yams

public enum ContentError: Error, CustomStringConvertible {
	case invalidFrontmatter(String)
	case missingField(String, file: String)
	case invalidField(String, file: String)

	public var description: String {
		switch self {
		case .invalidFrontmatter(let file):
			"Invalid YAML frontmatter in \(file)"
		case .missingField(let field, let file):
			"Missing required frontmatter field '\(field)' in \(file)"
		case .invalidField(let field, let file):
			"Invalid frontmatter field '\(field)' in \(file)"
		}
	}
}

public struct FrontmatterDocument {
	public let values: [String: Any]
	public let body: String

	public init(source: String, file: String) throws {
		guard source.hasPrefix("---\n") || source.hasPrefix("---\r\n") else {
			values = [:]
			body = source
			return
		}

		let normalized = source.replacingOccurrences(of: "\r\n", with: "\n")
		let lines = normalized.components(separatedBy: "\n")
		guard let closingIndex = lines.dropFirst().firstIndex(of: "---") else {
			throw ContentError.invalidFrontmatter(file)
		}

		let yaml = lines[1..<closingIndex].joined(separator: "\n")
		guard let object = try Yams.load(yaml: yaml) else {
			values = [:]
			body = lines[(closingIndex + 1)...].joined(separator: "\n")
			return
		}

		guard let dictionary = object as? [String: Any] else {
			throw ContentError.invalidFrontmatter(file)
		}

		values = dictionary
		body = lines[(closingIndex + 1)...].joined(separator: "\n").trimmingCharacters(in: .newlines)
	}
}

extension Dictionary where Key == String, Value == Any {
	func requiredString(_ key: String, file: String) throws -> String {
		guard let value = self[key] as? String, !value.isEmpty else {
			throw ContentError.missingField(key, file: file)
		}
		return value
	}

	func string(_ key: String) -> String? {
		if let value = self[key] as? String { return value }
		if let value = self[key] as? NSNumber { return value.stringValue }
		return nil
	}

	func bool(_ key: String, default defaultValue: Bool = false) -> Bool {
		if let value = self[key] as? Bool { return value }
		if let value = self[key] as? NSNumber { return value.boolValue }
		if let value = self[key] as? String { return value == "true" }
		return defaultValue
	}

	func int(_ key: String) -> Int? {
		if let value = self[key] as? Int { return value }
		if let value = self[key] as? NSNumber { return value.intValue }
		if let value = self[key] as? String { return Int(value) }
		return nil
	}

	func stringArray(_ key: String) -> [String] {
		guard let values = self[key] as? [Any] else { return [] }
		return values.compactMap { value in
			if let value = value as? String { return value }
			if let value = value as? NSNumber { return value.stringValue }
			return nil
		}
	}

	func stringMap(_ key: String) -> [String: String] {
		guard let values = self[key] as? [String: Any] else { return [:] }
		return values.compactMapValues { value in
			if let value = value as? String { return value }
			if let value = value as? NSNumber { return value.stringValue }
			return nil
		}
	}

	func objectArray(_ key: String) -> [[String: Any]] {
		(self[key] as? [[String: Any]]) ?? []
	}

	func object(_ key: String) -> [String: Any]? {
		self[key] as? [String: Any]
	}

	func date(_ key: String, file: String) throws -> Date {
		if let value = self[key] as? Date { return value }
		if let value = self[key] as? String {
			let formatter = DateFormatter()
			formatter.calendar = Calendar(identifier: .gregorian)
			formatter.locale = Locale(identifier: "en_US_POSIX")
			formatter.timeZone = TimeZone(secondsFromGMT: 0)
			formatter.dateFormat = "yyyy-MM-dd"
			if let date = formatter.date(from: value) { return date }
		}
		throw ContentError.invalidField(key, file: file)
	}
}

public enum ContentLoader {
	public static func loadApps(root: URL) throws -> [App] {
		let directory = root.appending(path: "source/content/apps")
		let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
			.filter { $0.pathExtension == "md" }
			.sorted { $0.lastPathComponent < $1.lastPathComponent }

		return try files.map { file in
			let source = try String(contentsOf: file, encoding: .utf8)
			let document = try FrontmatterDocument(source: source, file: file.path)
			let values = document.values
			let slug = file.deletingPathExtension().lastPathComponent
			let title = try values.requiredString("title", file: file.path)
			let subtitle = try values.requiredString("subtitle", file: file.path)
			guard subtitle.last.map({ !".!?".contains($0) }) ?? false else {
				throw ContentError.invalidField("subtitle", file: file.path)
			}

			let platforms = try values.stringArray("platforms").map { raw in
				guard let platform = Platform(rawValue: raw) else {
					throw ContentError.invalidField("platforms", file: file.path)
				}
				return platform
			}

			let markdown = MarkdownProcessor.process(
				document.body,
				appContext: .init(title: title, platforms: platforms.map(\.rawValue))
			)

			let quotes = values.objectArray("pressQuotes").compactMap { object -> PressQuote? in
				guard let quote = object["quote"] as? String, let source = object["source"] as? String else { return nil }
				return PressQuote(
					quote: quote,
					source: source,
					url: object["url"] as? String,
					isStarRating: (object["isStarRating"] as? Bool) ?? false
				)
			}

			let announcement = values.object("announcement").flatMap { object -> Announcement? in
				guard let text = object["text"] as? String else { return nil }
				return Announcement(text: text, url: object["url"] as? String, urlText: object["urlText"] as? String)
			}

			let appRoot = root.appending(path: "public/apps/\(slug)")
			let media = AssetInspector.mediaAssets(in: appRoot, publicPrefix: "/apps/\(slug)")

			return App(
				slug: slug,
				body: document.body,
				draft: values.bool("draft"),
				isUnlisted: values.bool("isUnlisted"),
				isArchived: values.bool("isArchived"),
				title: title,
				subtitle: subtitle,
				explicitDescription: values.string("description"),
				publicationDate: try values.date("pubDate", file: file.path),
				platforms: platforms,
				repositoryURL: values.string("repoUrl"),
				appStoreID: values.int("appStoreId"),
				setappID: values.int("setappId"),
				isPaid: values.bool("isPaid"),
				isMenuBarApp: values.bool("isMenuBarApp"),
				mainLinks: values.stringMap("mainLinks"),
				links: values.stringMap("links"),
				overflowLinks: values.stringMap("overflowLinks"),
				showSupportLink: values.bool("showSupportLink", default: true),
				redirectURL: values.string("redirectUrl"),
				releasesRepository: values.string("releasesRepo"),
				olderMacOSVersions: values.stringArray("olderMacOSVersions"),
				requirement: values.string("requirement"),
				downloads: values.int("downloads"),
				feedbackNote: values.string("feedbackNote"),
				hasSentry: values.bool("hasSentry"),
				pressQuotes: quotes,
				announcement: announcement,
				markdown: markdown,
				media: media
			)
		}
		.filter { !$0.draft }
		.sorted { $0.publicationDate > $1.publicationDate }
	}

	public static func loadPosts(root: URL) throws -> [BlogPost] {
		let directory = root.appending(path: "source/content/blog")
		let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
			.filter { $0.pathExtension == "md" }
			.sorted { $0.lastPathComponent < $1.lastPathComponent }

		return try files.map { file in
			let source = try String(contentsOf: file, encoding: .utf8)
			let document = try FrontmatterDocument(source: source, file: file.path)
			let values = document.values
			return BlogPost(
				slug: file.deletingPathExtension().lastPathComponent,
				body: document.body,
				draft: values.bool("draft"),
				isUnlisted: values.bool("isUnlisted"),
				title: try values.requiredString("title", file: file.path),
				description: values.string("description"),
				publicationDate: try values.date("pubDate", file: file.path),
				tags: values.stringArray("tags"),
				redirectURL: values.string("redirectUrl"),
				markdown: MarkdownProcessor.process(document.body)
			)
		}
		.filter { !$0.draft }
		.sorted { $0.publicationDate > $1.publicationDate }
	}

	public static func loadAppExtras(root: URL) throws -> [AppExtraGroup] {
		let url = root.appending(path: "source/data/apps-extra.json")
		let data = try Data(contentsOf: url)
		return try JSONDecoder().decode([AppExtraGroup].self, from: data)
	}

	public static func loadMarkdownPages(root: URL) throws -> [MarkdownPage] {
		let pagesRoot = root.appending(path: "source/pages")
		guard let enumerator = FileManager.default.enumerator(at: pagesRoot, includingPropertiesForKeys: [.isRegularFileKey]) else { return [] }
		var pages: [MarkdownPage] = []
		for case let file as URL in enumerator where file.pathExtension == "md" {
			let source = try String(contentsOf: file, encoding: .utf8)
			let document = try FrontmatterDocument(source: source, file: file.path)
			guard let title = document.values.string("title") else { continue }
			let relative = file.path.replacingOccurrences(of: pagesRoot.path + "/", with: "")
			let route = "/" + String(relative.dropLast(3))
			pages.append(
				MarkdownPage(
					route: route,
					title: title,
					description: document.values.string("description"),
					markdown: MarkdownProcessor.process(document.body)
				)
			)
		}
		return pages.sorted { $0.route < $1.route }
	}
}
