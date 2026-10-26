import AppKit
import Foundation
import Markdown
import SiteKit

extension SiteContent {
	/**
	Possible mistakes that do not fail the build, like a spelling mistake or an OS requirement that the App Store does not agree with. `website check` prints them.

	Checks the content, the public files, and the published site in the output directory, so build it first.
	*/
	@MainActor
	public func warnings(output: URL) -> [Warning] {
		let contentFiles = documents.map(\.file) + [try? MarkdownFile(url: project.root.appending(path: App.SharedQuestions.path))].compactMap(\.self)
		// The parsed Markdown, so code that shows a link is not a link, and a link text can span lines. Parsed once for the checks of the links and of the spelling.
		let bodies = contentFiles.map { CheckedText(file: $0, parsing: $0.body) }

		// The feedback notes of the apps are Markdown in the frontmatter, so their problems are reported at their key, as the lines of the SOML value are not the lines of the note.
		let feedbackNotes = apps.compactMap { app in
			app.frontmatter.feedbackNote.map { CheckedText(file: app.file, parsing: $0, line: app.file.line(of: App.Frontmatter.CodingKeys.feedbackNote)) }
		}

		let files = bodies + feedbackNotes

		return appStoreWarnings()
			+ gumroadWarnings()
			+ introductionWarnings()
			+ featuredAppWarnings()
			+ mediaWarnings()
			+ sharedAnswerWarnings()
			+ downloadVersionWarnings()
			+ markdownWarnings(in: files)
			+ spellingWarnings(in: files)
			+ publishedSiteWarnings(output: output)
	}

	/**
	Facts that the App Store knows better: whether the app exists, its price, its platforms, and its lowest OS version.
	*/
	private func appStoreWarnings() -> [Warning] {
		var warnings = [Warning]()

		for app in apps where !app.isArchived && app.appStoreID != nil {
			// The build already warns about an app that the App Store does not have.
			guard let info = appStoreInfo(of: app) else {
				continue
			}

			if
				let price = info.price,
				!price.isFree,
				!app.isPaid
			{
				warnings.append(Warning(file: app.file.url, message: "The App Store price is \(price.formatted), but `isPaid` is false."))
			}

			// Only platforms that the App Store lists are checked, and iOS for Mac apps. Apple Watch apps are listed with iPhone devices, as they come with an iPhone app.
			let missingPlatforms = info.listedPlatforms
				.subtracting(app.platforms)
				.filter { $0 != .iOS || !app.platforms.contains(.watchOS) }

			for platform in missingPlatforms.sorted(using: KeyPathComparator(\.rawValue)) {
				warnings.append(Warning(file: app.file.url, message: "The App Store version supports \(platform.rawValue), but `platforms` does not have it."))
			}

			if
				info.isMacApp,
				app.platforms.contains(.iOS)
			{
				warnings.append(Warning(file: app.file.url, message: "`platforms` has iOS, but the App Store version is a Mac app."))
			}

			// The lowest version is for macOS for Mac apps, for visionOS for apps only for Apple Vision, and for iOS for the others.
			if let minimumVersion = info.minimumOsVersion {
				let system = info.isMacApp ? Platform.macOS : info.listedPlatforms == [.visionOS] ? .visionOS : .iOS
				warnings += olderVersionMentions(in: app, system: system, minimumVersion: minimumVersion)
			}
		}

		return warnings
	}

	/**
	Prices of apps on Gumroad that Gumroad does not agree with, as the page shows the `price` of the frontmatter.
	*/
	private func gumroadWarnings() -> [Warning] {
		apps.compactMap { app in
			guard
				let product = gumroadProduct(of: app),
				let price = app.frontmatter.price,
				product.price != price
			else {
				return nil
			}

			return Warning(file: app.file.url, line: app.file.line(of: App.Frontmatter.CodingKeys.price), message: "The Gumroad price is \(product.price.formatted), but `price` is \(price.formatted).")
		}
	}

	/**
	Mentions of OS versions below the App Store minimum, like “Requires macOS 15 or later” for an app that needs macOS 26, in the text and the feedback note, and a lower `minimumOSVersion`. Only the major versions are compared, so “macOS 26” is fine for an app that needs 26.2. Lists of older versions to download are left out.
	*/
	private func olderVersionMentions(in app: App, system: Platform, minimumVersion: String) -> [Warning] {
		guard let pattern = try? Regex<(Substring, Substring)>("\\b\(system.rawValue) (\\d+(?:\\.\\d+)?)\\b") else {
			return []
		}

		let file = app.file
		var warnings = [Warning]()

		if
			let minimumOSVersion = app.frontmatter.minimumOSVersion,
			minimumOSVersion < minimumVersion.majorVersion
		{
			warnings.append(Warning(file: file.url, line: file.line(of: App.Frontmatter.CodingKeys.minimumOSVersion), message: "`minimumOSVersion` is \(minimumOSVersion), but the App Store version needs \(system.rawValue) \(minimumVersion)."))
		}

		let bodyLines = file.bodyLines.enumerated().compactMap { index, line -> (line: Int?, text: Substring)? in
			line.hasPrefix("- [") ? nil : (file.bodyStartLine + index, line)
		}

		// The feedback note is reported at its key, as the lines of the SOML value are not the lines of the note.
		let noteLines = (app.frontmatter.feedbackNote ?? "").split(separator: "\n").map { (line: file.line(of: App.Frontmatter.CodingKeys.feedbackNote), text: $0) }

		return warnings + (bodyLines + noteLines).flatMap { line, text in
			text.matches(of: pattern)
				.filter { $0.output.1.majorVersion < minimumVersion.majorVersion }
				.map { Warning(file: file.url, line: line, message: "Mentions \($0.output.0), but the App Store version needs \(system.rawValue) \(minimumVersion).") }
		}
	}

	/**
	Introductions that are too long for the hero of the app page, where they are shown under the name.
	*/
	private func introductionWarnings() -> [Warning] {
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
				let lineIndex = app.file.bodyLines.firstIndex { line in
					let text = line.trimmingCharacters(in: .whitespaces)
					return !text.isEmpty && !text.hasPrefix("<!--")
				} ?? 0

				return Warning(file: app.file.url, line: app.file.bodyStartLine + lineIndex, message: "The introduction is \(introduction.count) characters. The app page shows it under the name, so keep it at most \(App.maximumIntroductionLength) characters, which is two lines.")
			}
	}

	/**
	Featured apps that the apps page leaves out, as it shows at most ``maximumFeaturedAppCount``.
	*/
	private func featuredAppWarnings() -> [Warning] {
		extraFeaturedApps.map { app in
			Warning(file: app.file.url, line: app.file.line(of: App.Frontmatter.CodingKeys.isFeatured), message: "More than \(Self.maximumFeaturedAppCount) apps are featured, so the apps page leaves out this one. Remove `isFeatured` from one of them.")
		}
	}

	/**
	Questions of the FAQ sections that have the same answer in more than one app, which belong in `content/shared-questions.md`, so the answer is in one place. Questions with the same text but other answers are fine, like “Can you support iOS?”, which has a reason for each app.
	*/
	private func sharedAnswerWarnings() -> [Warning] {
		struct Question: Hashable {
			let title: String
			let answer: String
		}

		struct Place {
			let app: App
			let line: Int
		}

		var questions = [Question: [Place]]()

		for app in apps where !app.isRedirect {
			// The questions of the file, as the added questions have no lines.
			for heading in app.faqHeadings {
				guard
					let line = heading.line,
					let answer = app.faqAnswerMarkdown(of: heading)
				else {
					continue
				}

				questions[Question(title: heading.text, answer: answer), default: []].append(Place(app: app, line: line))
			}
		}

		// In the order of the apps and the lines, as the order of a dictionary changes between builds.
		return questions
			.filter { $0.value.count > 1 }
			.flatMap { question, places in
				places.map { place in
					let otherApps = places.filter { $0.app.slug != place.app.slug }.map { "`\($0.app.slug)`" }.formatted(.list(type: .and))
					return (place: place, message: "The question “\(question.title)” has the same answer in \(otherApps). Move it to `\(App.SharedQuestions.path)`, so the answer is in one place.")
				}
			}
			.sorted(using: [KeyPathComparator(\.place.app.slug), KeyPathComparator(\.place.line)])
			.map { Warning(file: $0.place.app.file.url, line: $0.place.line, message: $0.message) }
	}

	/**
	Downloads of older versions and of the non-App Store version whose file name has another version, like `Dato.1.14.9.zip` for version `1.4.9`, so one of them is wrong. A file name without a version of the app, like the ones of some hosts, or one with only the macOS version, like `App-for-macOS-10.13.zip`, is not checked.
	*/
	private func downloadVersionWarnings() -> [Warning] {
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let versionPattern = /\d+(?:\.\d+)+/
		var warnings = [Warning]()

		for app in apps {
			let downloads = app.frontmatter.olderVersions.map { (version: $0.version, macOS: $0.macOS.rawValue, url: $0.url, key: App.Frontmatter.CodingKeys.olderVersions) }
				+ [app.frontmatter.nonAppStoreVersion].compactMap(\.self).map { (version: $0.version, macOS: String($0.macOS), url: $0.url, key: App.Frontmatter.CodingKeys.nonAppStoreVersion) }

			for download in downloads {
				let fileVersions = download.url.lastPathComponent.matches(of: versionPattern)
					.map { String($0.output) }
					.filter { $0 != download.macOS }

				guard
					!fileVersions.isEmpty,
					!fileVersions.contains(download.version)
				else {
					continue
				}

				warnings.append(Warning(file: app.file.url, line: app.file.line(of: download.key), message: "The version \(download.version) is not the version in the name of its download, \(download.url.lastPathComponent)."))
			}
		}

		return warnings
	}

	/**
	Heavy icons, screenshots of different sizes, and 16-bit PNGs, which are much larger than 8-bit ones without looking better.
	*/
	private func mediaWarnings() -> [Warning] {
		var warnings = [Warning]()

		for app in apps where !app.isRedirect {
			if app.hasPlaceholderIcon {
				warnings.append(Warning(file: app.file.url, message: "The app has no `icon.png` next to it, so it shows a placeholder icon."))
			}

			// An archived app is no longer available, so it does not need to show itself.
			if
				app.isActive,
				app.media.isEmpty
			{
				warnings.append(Warning(file: app.file.url, message: "The app has no screenshots (`screenshot*.png/jpg`) or videos (`video*.mp4`) next to it, so its page shows none."))
			}

			let icon = project.publicFile(app.iconPath)

			if
				let size = try? icon.resourceValues(forKeys: [.fileSizeKey]).fileSize,
				size > 300_000
			{
				warnings.append(Warning(file: icon, message: "The icon is \(size / 1000) KB. Icons are usually less than 300 KB."))
			}

			let screenshotSizes = Set(app.media.filter { $0.kind == .image }.map(\.size))

			if screenshotSizes.count > 1 {
				warnings.append(Warning(file: project.publicFile(App.assetDirectory(slug: app.slug)), message: "The screenshots have different sizes: \(screenshotSizes.map(\.description).sorted(using: .localizedStandard).joined(separator: ", "))."))
			}
		}

		let pngs = ((try? project.publicFiles()) ?? []).map(\.source).filter { $0.pathExtension.lowercased() == "png" }

		for png in pngs {
			guard
				let depth = png.imageBitDepth,
				depth > 8
			else {
				continue
			}

			warnings.append(Warning(file: png, message: "The PNG has \(depth) bits per channel. 8 bits look the same and are much smaller."))
		}

		return warnings
	}

	/**
	Markdown to check, like the body of a content file, or the feedback note of an app.
	*/
	private struct CheckedText {
		let file: MarkdownFile
		let markdown: Markdown.Document

		/**
		The line of all the problems, for Markdown that is not the body of the file, like the feedback note of an app, which is reported at its key.
		*/
		var line: Int?

		init(file: MarkdownFile, parsing markdown: String, line: Int? = nil) {
			self.file = file
			self.markdown = Markdown.Document(parsing: markdown, options: [.parseBlockDirectives, .disableSmartOpts])
			self.line = line
		}

		/**
		The line of the Markdown in the file.
		*/
		func line(of markup: any Markup) -> Int {
			line ?? file.line(of: markup)
		}
	}

	/**
	Link texts that do not say where the link goes, links to the site that are not site paths, links to a heading whose ID comes from its text, remote images without a size, which make the page shift while loading, and raw HTML for what Markdown has a syntax for: `<kbd>` for keyboard shortcuts and `<sup>` for platforms.

	Only the raw HTML in the text is checked, not the HTML blocks, like a table, where Markdown is not parsed. A `<kbd>` that ends with the plus key, like `<kbd>Command+</kbd>`, cannot be written as `++Command+++`, so it is fine.
	*/
	private func markdownWarnings(in files: [CheckedText]) -> [Warning] {
		let vagueLinkTexts: Set = ["here", "click here", "this", "this link", "link", "read more", "more", "learn more", "try this", "this shortcut", "download", "screenshot"]
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let whitespace = /\s+/
		let trailingPunctuation = /[.…]?(?: ›)?$/
		let remoteHTMLImage = /<img\b[^>]*\bsrc="https?:\/\/[^>]*>/
		let platformText = /\(?(macOS|iOS|watchOS|tvOS|visionOS)(?:-only)?\)?/
		let documentsByPath = Dictionary(documents.map { ($0.path.description, $0) }) { first, _ in first }
		var warnings = [Warning]()

		for text in files {
			let file = text.file

			// Raw HTML is not parsed, so a regex finds its images.
			func remoteImageWarnings(_ html: String, at markup: any Markup) -> [Warning] {
				html.matches(of: remoteHTMLImage)
					.filter { !$0.output.contains("width=") || !$0.output.contains("height=") }
					.map { _ in Warning(file: file.url, line: text.line(of: markup), message: "The remote image has no `width` and `height`, so the page shifts while it loads.") }
			}

			/**
			The text between a start tag of raw HTML and the next tag, like the keys of `<kbd>Command+C</kbd>`.
			*/
			func textAfter(_ html: InlineHTML) -> String? {
				(html.parent?.child(at: html.indexInParent + 1) as? Markdown.Text)?.string
			}

			func check(_ markup: any Markup) {
				switch markup {
				case let link as Markdown.Link:
					// With an optional period, ellipsis, or arrow, like “Learn more.”, “More…”, and “Learn more ›”.
					let linkText = link.plainText.replacing(whitespace, with: " ").replacing(trailingPunctuation, with: "")

					if vagueLinkTexts.contains(linkText.lowercased()) {
						warnings.append(Warning(file: file.url, line: text.line(of: link), message: "The link text “\(linkText)” does not say where the link goes."))
					}

					let destination = link.destination.flatMap(URL.init(string:))

					// The build checks the site paths, but not the links to the site.
					if
						let destination,
						destination.host() == Site.url.host()
					{
						warnings.append(Warning(file: file.url, line: text.line(of: link), message: "Link to the site with a site path, like `\(destination.relativeReference)`, so the build checks the link."))
					}

					// The build finds a link to a missing heading, but not a link from another site, like a support reply, so the ID of a heading that pages link to must not change with its text. Limitation: only site paths are checked, not relative links to content files, like `dato.md#faq`. A heading without a line is added by the build, like a shared question, so its ID is in its source.
					if
						let destination,
						destination.host() == nil,
						destination.path().hasPrefix("/"),
						let fragment = destination.fragment(),
						let document = documentsByPath[destination.path()],
						let heading = document.markdown.headings.first(where: { $0.id == fragment }),
						let headingLine = heading.line,
						document.file.bodyLine(headingLine)?.contains("{#\(fragment)}") == false
					{
						warnings.append(Warning(file: file.url, line: text.line(of: link), message: "The link goes to the heading “\(heading.text)”, whose ID comes from its text, so changing the text breaks the link. Give the heading its ID: `{#\(fragment)}` (\(document.file.url.location(ofLine: headingLine)))."))
					}
				case let image as Markdown.Image where image.source?.hasPrefix("http://") == true || image.source?.hasPrefix("https://") == true:
					warnings.append(Warning(file: file.url, line: text.line(of: image), message: "The remote image has no size, so the page shifts while it loads. Use an `<img>` with `width` and `height`, or a local image."))
				case let html as InlineHTML:
					warnings += remoteImageWarnings(html.rawHTML, at: html)

					if
						html.rawHTML == "<kbd>",
						let keys = textAfter(html),
						!keys.hasSuffix("+")
					{
						warnings.append(Warning(file: file.url, line: text.line(of: html), message: "Write the keyboard shortcut “\(keys)” as `++\(keys)++`, not with `<kbd>`."))
					}

					if
						html.rawHTML == "<sup>",
						let content = textAfter(html),
						let match = content.wholeMatch(of: platformText)
					{
						warnings.append(Warning(file: file.url, line: text.line(of: html), message: "Write the platform “\(content)” as a platform badge, like `^[\(match.1) only](platform: \"\(match.1)\")`, not with `<sup>`."))
					}
				case let html as HTMLBlock:
					warnings += remoteImageWarnings(html.rawHTML, at: html)
				default:
					break
				}

				for child in markup.children {
					check(child)
				}
			}

			check(text.markdown)
		}

		return warnings
	}

	/**
	The words that are spelled right, but that the spelling checker does not know, like technical terms. One word per line in `content/spelling-allowlist.txt`, and every word of the app titles.
	*/
	private func allowedWords() -> Set<String> {
		let list = (try? String(contentsOf: project.root.appending(path: "content/spelling-allowlist.txt"), encoding: .utf8)) ?? ""
		let appWords = apps.flatMap { $0.title.split { !$0.isLetter && $0 != "'" } }
		return Set((list.split(whereSeparator: \.isNewline) + appWords).map { $0.lowercased() })
	}

	/**
	Unknown words and repeated words, like “the the”, in the text of the content. Code, link destinations, HTML, and comments are left out, as only the text of the parsed Markdown is read.

	Only lowercase words are checked for spelling. Words with capitals are usually names, like `Setapp` or `iCloud`, which would be most of the warnings. So a typo at the start of a sentence is not found, but a repeated word there is, like “The the”. Limitation: a repeat across formatting or lines, like “the *the*”, is not found, and repeats that are right, like “had had”, are reported.
	*/
	@MainActor
	private func spellingWarnings(in files: [CheckedText]) -> [Warning] {
		let allowedWords = allowedWords()
		let checker = NSSpellChecker.shared
		// Each word and the next one, which a lookahead keeps for the next match, as a backreference does not ignore case, so it would miss “The the”.
		let wordPair = /(?i)\b([a-z]+)\s+(?=([a-z]+)\b)/
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let bareURL = /https?:\/\/\S+/
		let customHeadingID = /\{#[^}]*\}/
		var warnings = [Warning]()

		for checkedText in files {
			let file = checkedText.file
			var texts = [(string: String, line: Int)]()

			func check(_ markup: any Markup) {
				guard let text = markup as? Markdown.Text else {
					for child in markup.children {
						check(child)
					}

					return
				}

				// Bare URLs and custom heading IDs are text in the parsed Markdown. They become an object replacement character, not a space, so the words around them do not look repeated.
				let string = text.string
					.replacing(bareURL, with: "\u{FFFC}")
					.replacing(customHeadingID, with: "\u{FFFC}")

				let line = checkedText.line(of: text)

				for match in string.matches(of: wordPair) {
					let (_, word, nextWord) = match.output

					guard
						word.lowercased() == nextWord.lowercased(),
						word.lowercased() != "a"
					else {
						continue
					}

					warnings.append(Warning(file: file.url, line: line, message: "Repeated word: “\(word) \(nextWord)”."))
				}

				texts.append((string, line))
			}

			check(checkedText.markdown)

			// The spelling of all the texts of the file in one string, as each call of the spelling checker is slow (checking about 8,500 texts one by one took 1.7 s). A line break keeps the words of two texts apart. The ranges count UTF-16 code units, so the end of each text does too.
			let string = texts.map(\.string).joined(separator: "\n")
			var textEnds = [Int]()

			for text in texts {
				textEnds.append((textEnds.last ?? 0) + text.string.utf16.count + 1)
			}

			let length = string.utf16.count
			var offset = 0

			while offset < length {
				let range = checker.checkSpelling(of: string, startingAt: offset, language: "en_US", wrap: false, inSpellDocumentWithTag: 0, wordCount: nil)

				guard range.location != NSNotFound else {
					break
				}

				let word = (string as NSString).substring(with: range)
				offset = range.location + range.length

				guard
					word.allSatisfy(\.isLowercase),
					!allowedWords.contains(word),
					let textIndex = textEnds.firstIndex(where: { range.location < $0 })
				else {
					continue
				}

				warnings.append(Warning(file: file.url, line: texts[textIndex].line, message: "Unknown word: “\(word)”."))
			}
		}

		return warnings
	}

	/**
	Checks on the published pages: headings that skip a level, which screen reader users navigate by, and public files that nothing links to.
	*/
	private func publishedSiteWarnings(output: URL) -> [Warning] {
		let files = (try? output.filesRecursively()) ?? []
		let textFiles = files.filter { ["html", "css", "js", "xml", "json", "txt", "webmanifest"].contains($0.pathExtension) || $0.pathExtension.isEmpty }
		let texts = textFiles.map { ($0, (try? String(contentsOf: $0, encoding: .utf8)) ?? "") }
		// Simple word boundaries, as the Unicode ones are slow on this much HTML.
		let headingTag = /<h([1-6])\b/.wordBoundaryKind(.simple)
		var warnings = [Warning]()

		for (file, html) in texts where file.pathExtension == "html" {
			var previousLevel = 0

			for match in html.matches(of: headingTag) {
				let level = Int(match.output.1) ?? 0

				if level > previousLevel + 1 {
					// Redirect pages have no real headings. Only checked here, as searching every page is slow.
					if !html.contains(#"http-equiv="refresh""#) {
						// The site path of the page, as the output directory can be anywhere.
						warnings.append(Warning(location: "/\(file.path(relativeTo: output))", message: "A level \(level) heading follows a level \(previousLevel) heading."))
					}

					break
				}

				previousLevel = level
			}
		}

		// As bytes, as searching a string this long for each public file is slow (about 20 s for all the files).
		let publishedText = Data(texts.map(\.1).joined(separator: "\n").utf8)

		func publishedTextContains(_ text: String) -> Bool {
			publishedText.contains(Data(text.utf8))
		}

		// Only the published files, as the files of a draft are only published with its page.
		let publicFiles = ((try? project.publicFiles()) ?? []).filter { output.appending(path: $0.path.relativePath).isFile }

		// Files that browsers, crawlers, and services find by their name, and pages, which are visited by their URL.
		let wellKnownFiles: Set = ["CNAME", "favicon.ico", ".nojekyll", ".DS_Store", "keybase.txt", "indexnow.txt"]

		// The placeholder icon is only used while an app has no icon. The sponsor logos in `assets/thanks/` are also linked from the readmes of the open-source projects, like the dark logos, which the site does not use.
		for (path, source) in publicFiles where !wellKnownFiles.contains(source.lastPathComponent) && !path.starts(with: "/.well-known") && !path.starts(with: "/assets/thanks") && !path.description.hasSuffix(".html") && path != App.placeholderIconPath {
			// Scripts load scripts next to them by a relative path, like `./nebula.js` in `home.js`.
			let isUsed = publishedTextContains(path.description) || publishedTextContains(path.description.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path.description) || publishedTextContains("./\(source.lastPathComponent)")

			if !isUsed {
				warnings.append(Warning(file: source, message: "No published page, stylesheet, or script uses the file."))
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

extension URL {
	/**
	The path with the query and the fragment, like `/velja?a=1#faq` for `https://sindresorhus.com/velja?a=1#faq`.
	*/
	fileprivate var relativeReference: String {
		let path = path(percentEncoded: true)
		return (path.isEmpty ? "/" : path) + (query(percentEncoded: true).map { "?\($0)" } ?? "") + (fragment(percentEncoded: true).map { "#\($0)" } ?? "")
	}
}

extension MarkdownFile {
	/**
	The text of a line of the body, by its line in the file. `nil` for a line that is not in the body, like a line of the frontmatter.
	*/
	fileprivate func bodyLine(_ line: Int) -> Substring? {
		let lines = bodyLines
		let index = line - bodyStartLine
		return lines.indices.contains(index) ? lines[index] : nil
	}
}
