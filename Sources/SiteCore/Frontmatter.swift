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

private enum ContentSchemaValidator {
	private static let appKeys: Set<String> = [
		"draft", "isUnlisted", "isArchived", "title", "subtitle", "description",
		"pubDate", "platforms", "repoUrl", "appStoreId", "setappId", "isPaid",
		"isMenuBarApp", "mainLinks", "links", "overflowLinks", "showSupportLink",
		"redirectUrl", "releasesRepo", "olderMacOSVersions", "requirement",
		"downloads", "feedbackNote", "hasSentry", "pressQuotes", "announcement",
	]

	private static let blogKeys: Set<String> = [
		"draft", "isUnlisted", "title", "description", "pubDate", "tags",
		"redirectUrl",
	]

	private static let platformValues = Set(Platform.allCases.map(\.rawValue))
	private static let blogTagValues: Set<String> = [
		"programming", "open-source", "swift", "javascript", "nodejs",
	]
	private static let olderMacOSVersionValues: Set<String> = [
		"10.13", "10.14", "10.15", "11", "12", "13", "14", "15",
		"26", "27", "28", "29", "30", "31", "32", "33", "34",
	]
	private static let maximumSafeInteger = 9_007_199_254_740_991

	static func validateApp(_ values: [String: Any], file: String) throws {
		try validateUnknownKeys(values, allowed: appKeys, file: file)
		try validateRequiredNonemptyString(values, key: "title", file: file)
		try validateRequiredNonemptyString(values, key: "subtitle", file: file)
		try validateOptionalNonemptyString(values, key: "description", file: file)
		try validateRequiredDate(values, key: "pubDate", file: file)
		try validateRequiredStringArray(values, key: "platforms", allowed: platformValues, file: file)

		for key in ["draft", "isUnlisted", "isArchived", "isPaid", "isMenuBarApp", "showSupportLink", "hasSentry"] {
			try validateOptionalBoolean(values, key: key, file: file)
		}

		for key in ["repoUrl", "redirectUrl"] {
			try validateOptionalURL(values, key: key, file: file)
		}

		for key in ["appStoreId", "setappId"] {
			try validateOptionalPositiveInteger(values, key: key, safe: true, file: file)
		}

		try validateOptionalPositiveInteger(values, key: "downloads", safe: false, file: file)

		for key in ["releasesRepo", "requirement", "feedbackNote"] {
			try validateOptionalString(values, key: key, file: file)
		}

		for key in ["mainLinks", "links", "overflowLinks"] {
			try validateOptionalURLMap(values, key: key, file: file)
		}

		try validateOptionalStringArray(
			values,
			key: "olderMacOSVersions",
			allowed: olderMacOSVersionValues,
			file: file
		)
		try validatePressQuotes(values, file: file)
		try validateAnnouncement(values, file: file)
	}

	static func validateBlog(_ values: [String: Any], file: String) throws {
		try validateUnknownKeys(values, allowed: blogKeys, file: file)
		try validateRequiredNonemptyString(values, key: "title", file: file)
		try validateOptionalNonemptyString(values, key: "description", file: file)
		try validateRequiredDate(values, key: "pubDate", file: file)
		try validateOptionalBoolean(values, key: "draft", file: file)
		try validateOptionalBoolean(values, key: "isUnlisted", file: file)
		try validateOptionalStringArray(values, key: "tags", allowed: blogTagValues, file: file)
		try validateOptionalURL(values, key: "redirectUrl", file: file)
	}

	private static func validateUnknownKeys(_ values: [String: Any], allowed: Set<String>, file: String) throws {
		guard Set(values.keys).isSubset(of: allowed) else {
			let unknown = Set(values.keys).subtracting(allowed).sorted().joined(separator: ", ")
			throw ContentError.invalidField("unknown key(s): \(unknown)", file: file)
		}
	}

	private static func validateRequiredNonemptyString(_ values: [String: Any], key: String, file: String) throws {
		guard let value = values[key] as? String, !value.isEmpty else {
			throw ContentError.invalidField(key, file: file)
		}
	}

	private static func validateOptionalNonemptyString(_ values: [String: Any], key: String, file: String) throws {
		guard let raw = values[key] else { return }
		guard let value = raw as? String, !value.isEmpty else {
			throw ContentError.invalidField(key, file: file)
		}
	}

	private static func validateOptionalString(_ values: [String: Any], key: String, file: String) throws {
		guard let raw = values[key] else { return }
		guard raw is String else {
			throw ContentError.invalidField(key, file: file)
		}
	}

	private static func validateOptionalBoolean(_ values: [String: Any], key: String, file: String) throws {
		guard let raw = values[key] else { return }
		guard type(of: raw) == Bool.self else {
			throw ContentError.invalidField(key, file: file)
		}
	}

	private static func validateOptionalPositiveInteger(
		_ values: [String: Any],
		key: String,
		safe: Bool,
		file: String
	) throws {
		guard let raw = values[key] else { return }
		guard type(of: raw) == Int.self, let value = raw as? Int, value > 0 else {
			throw ContentError.invalidField(key, file: file)
		}
		if safe && value > maximumSafeInteger {
			throw ContentError.invalidField(key, file: file)
		}
	}

	private static func validateRequiredDate(_ values: [String: Any], key: String, file: String) throws {
		guard values[key] != nil else {
			throw ContentError.missingField(key, file: file)
		}
		_ = try values.date(key, file: file)
	}

	private static func validateOptionalURL(_ values: [String: Any], key: String, file: String) throws {
		guard let raw = values[key] else { return }
		guard let value = raw as? String, isValidURL(value) else {
			throw ContentError.invalidField(key, file: file)
		}
	}

	private static func validateOptionalURLMap(_ values: [String: Any], key: String, file: String) throws {
		guard let raw = values[key] else { return }
		guard let map = raw as? [String: Any] else {
			throw ContentError.invalidField(key, file: file)
		}
		for value in map.values {
			guard let string = value as? String, isValidURL(string) else {
				throw ContentError.invalidField(key, file: file)
			}
		}
	}

	private static func validateRequiredStringArray(
		_ values: [String: Any],
		key: String,
		allowed: Set<String>,
		file: String
	) throws {
		guard values[key] != nil else {
			throw ContentError.missingField(key, file: file)
		}
		try validateStringArray(values[key], key: key, allowed: allowed, file: file)
	}

	private static func validateOptionalStringArray(
		_ values: [String: Any],
		key: String,
		allowed: Set<String>,
		file: String
	) throws {
		guard let raw = values[key] else { return }
		try validateStringArray(raw, key: key, allowed: allowed, file: file)
	}

	private static func validateStringArray(
		_ raw: Any?,
		key: String,
		allowed: Set<String>,
		file: String
	) throws {
		guard let array = raw as? [Any] else {
			throw ContentError.invalidField(key, file: file)
		}
		for value in array {
			guard let string = value as? String, allowed.contains(string) else {
				throw ContentError.invalidField(key, file: file)
			}
		}
	}

	private static func validatePressQuotes(_ values: [String: Any], file: String) throws {
		guard let raw = values["pressQuotes"] else { return }
		guard let quotes = raw as? [[String: Any]] else {
			throw ContentError.invalidField("pressQuotes", file: file)
		}
		let allowed: Set<String> = ["quote", "source", "url", "isStarRating"]
		for quote in quotes {
			try validateUnknownKeys(quote, allowed: allowed, file: file)
			try validateRequiredNonemptyString(quote, key: "quote", file: file)
			try validateRequiredNonemptyString(quote, key: "source", file: file)
			try validateOptionalURL(quote, key: "url", file: file)
			try validateOptionalBoolean(quote, key: "isStarRating", file: file)
		}
	}

	private static func validateAnnouncement(_ values: [String: Any], file: String) throws {
		guard let raw = values["announcement"] else { return }
		guard let announcement = raw as? [String: Any] else {
			throw ContentError.invalidField("announcement", file: file)
		}
		let allowed: Set<String> = ["text", "url", "urlText"]
		try validateUnknownKeys(announcement, allowed: allowed, file: file)
		try validateRequiredNonemptyString(announcement, key: "text", file: file)
		try validateOptionalString(announcement, key: "url", file: file)
		try validateOptionalString(announcement, key: "urlText", file: file)
	}

	private static func isValidURL(_ value: String) -> Bool {
		guard let url = URL(string: value), let scheme = url.scheme, !scheme.isEmpty else {
			return false
		}
		return true
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
			try ContentSchemaValidator.validateApp(values, file: file.path)
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
			let media = try AssetInspector.mediaAssets(in: appRoot, publicPrefix: "/apps/\(slug)")

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
			try ContentSchemaValidator.validateBlog(values, file: file.path)
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
