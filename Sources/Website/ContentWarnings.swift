import AppKit
import Foundation
import Markdown
import ImageIO
import SiteKit

extension SiteContent {
	/**
	Possible mistakes that do not fail the build, like a spelling mistake or an OS requirement that the App Store does not agree with. `website check` prints them.

	Checks the content, the public files, and the published site in the output directory, so build it first.
	*/
	@MainActor
	public func warnings(project: Project, output: URL) -> [Warning] {
		let documents = apps.map(\.file) + posts.map(\.file) + pages.map(\.file)

		return appStoreWarnings(project: project)
			+ introductionWarnings(project: project)
			+ featuredAppWarnings(project: project)
			+ mediaWarnings(project: project)
			+ documents.flatMap { Self.markdownWarnings(in: $0, project: project) }
			+ Self.spellingWarnings(in: documents, allowedWords: allowedWords(project: project), project: project)
			+ Self.publishedSiteWarnings(project: project, output: output)
	}

	/**
	Facts that the App Store knows better: whether the app exists, its price, its platforms, and its lowest OS version.
	*/
	private func appStoreWarnings(project: Project) -> [Warning] {
		var warnings = [Warning]()

		for app in apps where !app.isArchived && app.appStoreID != nil {
			let location = app.file.url.path(relativeTo: project.root)

			// The build already warns about an app that the App Store does not have.
			guard let info = appStoreInfo(of: app) else {
				continue
			}

			if
				let price = info.price,
				!price.isFree,
				!app.isPaid
			{
				warnings.append(Warning(location: location, message: "The App Store price is \(price.formatted), but `isPaid` is false."))
			}

			// Only platforms that the App Store lists are checked, and iOS for Mac apps. Apple Watch apps are listed with iPhone devices, as they come with an iPhone app.
			let missingPlatforms = info.listedPlatforms
				.subtracting(app.platforms)
				.filter { $0 != .iOS || !app.platforms.contains(.watchOS) }

			for platform in missingPlatforms.sorted(using: KeyPathComparator(\.rawValue)) {
				warnings.append(Warning(location: location, message: "The App Store version supports \(platform.rawValue), but `platforms` does not have it."))
			}

			if
				info.isMacApp,
				app.platforms.contains(.iOS)
			{
				warnings.append(Warning(location: location, message: "`platforms` has iOS, but the App Store version is a Mac app."))
			}

			// The lowest version is for macOS for Mac apps, and for iOS for the others.
			if let minimumVersion = info.minimumOsVersion {
				warnings += Self.olderVersionMentions(in: app.file, system: info.isMacApp ? "macOS" : "iOS", minimumVersion: minimumVersion, project: project)
			}
		}

		return warnings
	}

	/**
	Mentions of OS versions below the App Store minimum, like “Requires macOS 15 or later” for an app that needs macOS 26. Only the major versions are compared, so “macOS 26” is fine for an app that needs 26.2. Lists of older versions to download are left out.
	*/
	private static func olderVersionMentions(in file: MarkdownFile, system: String, minimumVersion: String, project: Project) -> [Warning] {
		guard let pattern = try? Regex<(Substring, Substring)>("\\b\(system) (\\d+(?:\\.\\d+)?)\\b") else {
			return []
		}

		return file.body.split(separator: "\n", omittingEmptySubsequences: false).enumerated().flatMap { index, line -> [Warning] in
			guard !line.hasPrefix("- [") else {
				return []
			}

			return line.matches(of: pattern)
				.filter { $0.output.1.majorVersion < minimumVersion.majorVersion }
				.map { Warning(location: file.location(ofLine: file.bodyStartLine + index, relativeTo: project.root), message: "Mentions \($0.output.0), but the App Store version needs \(system) \(minimumVersion).") }
		}
	}

	/**
	Introductions that are too long for the hero of the app page, where they are shown under the name.
	*/
	private func introductionWarnings(project: Project) -> [Warning] {
		apps
			.filter { !$0.isRedirect }
			.compactMap { app in
				guard
					let introduction = app.markdown.introduction,
					introduction.count > App.maximumIntroductionLength
				else {
					return nil
				}

				// The first line with text, after blank lines and comments.
				let lineIndex = app.file.body.split(separator: "\n", omittingEmptySubsequences: false).firstIndex { line in
					let text = line.trimmingCharacters(in: .whitespaces)
					return !text.isEmpty && !text.hasPrefix("<!--")
				} ?? 0

				return Warning(location: app.file.location(ofLine: app.file.bodyStartLine + lineIndex, relativeTo: project.root), message: "The introduction is \(introduction.count) characters. The app page shows it under the name, so keep it at most \(App.maximumIntroductionLength) characters, which is two lines.")
			}
	}

	/**
	Featured apps that the apps page leaves out, as it shows at most ``maximumFeaturedAppCount``.
	*/
	private func featuredAppWarnings(project: Project) -> [Warning] {
		extraFeaturedApps.map { app in
			Warning(location: app.file.location(ofLine: app.file.line(ofFrontmatterKey: "isFeatured"), relativeTo: project.root), message: "More than \(Self.maximumFeaturedAppCount) apps are featured, so the apps page leaves out this one. Remove `isFeatured` from one of them.")
		}
	}

	/**
	Heavy icons, screenshots of different sizes, and 16-bit PNGs, which are much larger than 8-bit ones without looking better.
	*/
	private func mediaWarnings(project: Project) -> [Warning] {
		var warnings = [Warning]()

		for app in apps where !app.isRedirect {
			if app.hasPlaceholderIcon {
				warnings.append(Warning(location: app.file.location(ofLine: nil, relativeTo: project.root), message: "The app has no `icon.png` next to it, so it shows a placeholder icon."))
			}

			let icon = project.publicFile(app.iconPath)

			if
				let size = try? icon.resourceValues(forKeys: [.fileSizeKey]).fileSize,
				size > 300_000
			{
				warnings.append(Warning(location: icon.path(relativeTo: project.root), message: "The icon is \(size / 1000) KB. Icons are usually less than 300 KB."))
			}

			let screenshotSizes = Set(app.media.filter { $0.kind == .image }.map { "\($0.width)×\($0.height)" })

			if screenshotSizes.count > 1 {
				warnings.append(Warning(location: project.publicFile(App.assetDirectory(slug: app.slug)).path(relativeTo: project.root), message: "The screenshots have different sizes: \(screenshotSizes.sorted(using: .localizedStandard).joined(separator: ", "))."))
			}
		}

		let pngs = ((try? project.publicFiles()) ?? []).map(\.source).filter { $0.pathExtension.lowercased() == "png" }

		for png in pngs {
			guard
				let source = CGImageSourceCreateWithURL(png as CFURL, nil),
				let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
				let depth = properties[kCGImagePropertyDepth] as? Int,
				depth > 8
			else {
				continue
			}

			warnings.append(Warning(location: png.path(relativeTo: project.root), message: "The PNG has \(depth) bits per channel. 8 bits look the same and are much smaller."))
		}

		return warnings
	}

	/**
	Link texts that do not say where the link goes, and remote images without a size, which make the page shift while loading.
	*/
	private static func markdownWarnings(in file: MarkdownFile, project: Project) -> [Warning] {
		let vagueLinkTexts: Set = ["here", "click here", "this", "this link", "link", "read more", "more", "learn more", "try this", "this shortcut", "download", "screenshot"]
		let remoteHTMLImage = /<img\b[^>]*\bsrc="https?:\/\/[^>]*>/
		var warnings = [Warning]()

		func location(of markup: any Markup) -> String {
			file.location(ofLine: file.bodyStartLine + (markup.range?.lowerBound.line ?? 1) - 1, relativeTo: project.root)
		}

		// The parsed Markdown, so code that shows a link is not a link, and a link text can span lines.
		func check(_ markup: any Markup) {
			switch markup {
			case let link as Markdown.Link:
				// With an optional period, ellipsis, or arrow, like “Learn more.”, “More…”, and “Learn more ›”.
				let text = link.plainText.replacing(/\s+/, with: " ").replacing(/[.…]?(?: ›)?$/, with: "")

				if vagueLinkTexts.contains(text.lowercased()) {
					warnings.append(Warning(location: location(of: link), message: "The link text “\(text)” does not say where the link goes."))
				}
			case let image as Markdown.Image where image.source?.hasPrefix("http://") == true || image.source?.hasPrefix("https://") == true:
				warnings.append(Warning(location: location(of: image), message: "The remote image has no size, so the page shifts while it loads. Use an `<img>` with `width` and `height`, or a local image."))
			case let html as InlineHTML:
				warnings += remoteImageWarnings(html.rawHTML, location: location(of: html))
			case let html as HTMLBlock:
				warnings += remoteImageWarnings(html.rawHTML, location: location(of: html))
			default:
				break
			}

			for child in markup.children {
				check(child)
			}
		}

		// Raw HTML is not parsed, so a regex finds its images.
		func remoteImageWarnings(_ html: String, location: String) -> [Warning] {
			html.matches(of: remoteHTMLImage)
				.filter { !$0.output.contains("width=") || !$0.output.contains("height=") }
				.map { _ in Warning(location: location, message: "The remote image has no `width` and `height`, so the page shifts while it loads.") }
		}

		check(Markdown.Document(parsing: file.body, options: [.parseBlockDirectives, .disableSmartOpts]))
		return warnings
	}

	/**
	The words that are spelled right, but that the spelling checker does not know, like technical terms. One word per line in `content/spelling-allowlist.txt`, and every word of the app titles.
	*/
	private func allowedWords(project: Project) -> Set<String> {
		let list = (try? String(contentsOf: project.root.appending(path: "content/spelling-allowlist.txt"), encoding: .utf8)) ?? ""
		let appWords = apps.flatMap { $0.title.split { !$0.isLetter && $0 != "'" } }
		return Set((list.split(whereSeparator: \.isNewline) + appWords).map { $0.lowercased() })
	}

	/**
	Unknown words and repeated words, like “the the”, in the text of the content. Code, link destinations, HTML, and comments are left out, as only the text of the parsed Markdown is read.

	Only lowercase words are checked. Words with capitals are usually names, like `Setapp` or `iCloud`, which would be most of the warnings. So a typo at the start of a sentence is not found. Limitation: a repeat across formatting or lines, like “the *the*”, is not found, and repeats that are right, like “had had”, are reported.
	*/
	@MainActor
	private static func spellingWarnings(in files: [MarkdownFile], allowedWords: Set<String>, project: Project) -> [Warning] {
		let checker = NSSpellChecker.shared
		let repeatedWord = /(?i)\b([a-z]+)\s+\1\b/
		var warnings = [Warning]()

		for file in files {
			func check(_ markup: any Markup) {
				guard let text = markup as? Markdown.Text else {
					for child in markup.children {
						check(child)
					}

					return
				}

				// Bare URLs and custom heading IDs are text in the parsed Markdown. They become an object replacement character, not a space, so the words around them do not look repeated.
				let string = text.string
					.replacing(/https?:\/\/\S+/, with: "\u{FFFC}")
					.replacing(/\{#[^}]*\}/, with: "\u{FFFC}")

				let location = file.location(ofLine: file.bodyStartLine + (text.range?.lowerBound.line ?? 1) - 1, relativeTo: project.root)

				for match in string.matches(of: repeatedWord) where match.output.1.count > 1 || match.output.1.lowercased() != "a" {
					warnings.append(Warning(location: location, message: "Repeated word: “\(match.output.0)”."))
				}

				var offset = 0

				while offset < (string as NSString).length {
					let range = checker.checkSpelling(of: string, startingAt: offset, language: "en_US", wrap: false, inSpellDocumentWithTag: 0, wordCount: nil)

					guard range.location != NSNotFound else {
						break
					}

					let word = (string as NSString).substring(with: range)
					offset = range.location + range.length

					guard
						word.allSatisfy(\.isLowercase),
						!allowedWords.contains(word)
					else {
						continue
					}

					warnings.append(Warning(location: location, message: "Unknown word: “\(word)”."))
				}
			}

			check(Markdown.Document(parsing: file.body, options: [.parseBlockDirectives, .disableSmartOpts]))
		}

		return warnings
	}

	/**
	Checks on the published pages: headings that skip a level, which screen reader users navigate by, and public files that nothing links to.
	*/
	private static func publishedSiteWarnings(project: Project, output: URL) -> [Warning] {
		let files = (try? output.filesRecursively()) ?? []
		let textFiles = files.filter { ["html", "css", "js", "xml", "json", "txt", "webmanifest"].contains($0.pathExtension) || $0.pathExtension.isEmpty }
		let texts = textFiles.map { ($0, (try? String(contentsOf: $0, encoding: .utf8)) ?? "") }
		var warnings = [Warning]()

		// Redirect pages have no real headings.
		for (file, html) in texts where file.pathExtension == "html" && !html.contains(#"http-equiv="refresh""#) {
			var previousLevel = 0

			for match in html.matches(of: /<h([1-6])\b/) {
				let level = Int(match.output.1) ?? 0

				if level > previousLevel + 1 {
					// The site path of the page, as the output directory can be anywhere.
					warnings.append(Warning(location: "/\(file.path(relativeTo: output))", message: "A level \(level) heading follows a level \(previousLevel) heading."))
					break
				}

				previousLevel = level
			}
		}

		let publishedText = texts.map(\.1).joined(separator: "\n")
		let publicFiles = (try? project.publicFiles()) ?? []

		// Files that browsers, crawlers, and services find by their name, and pages, which are visited by their URL.
		let wellKnownFiles: Set<String> = ["CNAME", "favicon.ico", ".nojekyll", ".DS_Store", "keybase.txt", "indexnow.txt"]

		// The placeholder icon is only used while an app has no icon. The sponsor logos in `assets/thanks/` are also linked from the readmes of the open-source projects, like the dark logos, which the site does not use.
		for (file, source) in publicFiles where !wellKnownFiles.contains(URL(filePath: file).lastPathComponent) && !file.hasPrefix(".well-known/") && !file.hasPrefix("assets/thanks/") && !file.hasSuffix(".html") && "/\(file)" != App.placeholderIconPath.description {
			// Scripts load scripts next to them by a relative path, like `./nebula.js` in `home.js`.
			let isUsed = publishedText.contains("/\(file)") || publishedText.contains("/\(file.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? file)") || publishedText.contains("./\(URL(filePath: file).lastPathComponent)")

			if !isUsed {
				warnings.append(Warning(location: source.path(relativeTo: project.root), message: "No published page, stylesheet, or script uses the file."))
			}
		}

		return warnings
	}
}

extension StringProtocol {
	/**
	The major version of a version number, like `26` for `26.2`.
	*/
	fileprivate var majorVersion: Int {
		Int(split(separator: ".").first ?? "") ?? 0
	}
}
