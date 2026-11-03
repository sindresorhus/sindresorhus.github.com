import AppKit
import Foundation
import Markdown
import RegexBuilder
import SiteKit

extension SiteContent {
	/**
	Every warning of `website check`: the warnings of the build (``warnings``), and possible mistakes that do not fail the build, like a spelling mistake or an OS requirement that the App Store does not agree with.

	Checks the content, the public files, and the published site, so build it first, and pass what the build published and its routes. The checks run at the same time, and the warnings are in the order of the checks. It also returns how long each check took, which `--verbose` prints, as one slow check makes the whole check slow.
	*/
	public func warnings(published: PublishedSite, routes: [Route]) async -> (warnings: [Warning], steps: StepTimes) {
		// A project without shared questions has no file.
		let contentFiles = documents.map(\.file) + [sharedQuestions.file].compactMap(\.self)

		let checks: [(name: String, run: @Sendable () -> [Warning])] = [
			("Check App Store data", appStoreWarnings),
			("Check Gumroad prices", gumroadWarnings),
			("Check open source projects", openSourceProjectWarnings),
			("Check introductions", introductionWarnings),
			("Check media", mediaWarnings),
			("Check shared answers", sharedAnswerWarnings),
			("Check question IDs", questionIDWarnings),
			("Check copied answer blocks", copiedAnswerBlockWarnings),
			("Check promises", promiseWarnings),
			("Check links", { linkWarnings(in: contentFiles) }),
			("Check download versions", downloadVersionWarnings),
			("Check trial requirements", trialRequirementWarnings),
			("Check requirements", requirementWarnings),
			("Check social cards", socialCardWarnings),
			("Check published site", { publishedSiteWarnings(published: published, routes: routes) }),
			("Check duplicate titles and descriptions", { duplicateMetadataWarnings(published: published, routes: routes) }),
		]

		// The checks of the text run at the same time as the other checks, and their warnings are last.
		async let text = textWarnings(of: contentFiles)

		let results = await withTaskGroup { group in
			for (index, check) in checks.enumerated() {
				group.addTask {
					var steps = StepTimes()
					let warnings = steps.measure(check.name, check.run)
					return (index: index, warnings: warnings, steps: steps)
				}
			}

			return await group.reduce(into: []) { $0.append($1) }
		}
		.sorted(using: KeyPathComparator(\.index))

		let textResult = await text
		return (self.warnings + results.flatMap(\.warnings) + textResult.warnings, StepTimes(results.flatMap(\.steps.steps) + textResult.steps.steps))
	}

	/**
	Whether the warning is at one of the files, or at a file in one of the directories, like for `website check content/apps/dato`, which only shows the warnings of the files that are being edited. A warning of a page is at its content file. A warning at a directory, like the screenshots of an app, is also at the files in it.
	*/
	public func warning(_ warning: Warning, isAtAnyOf files: [URL]) -> Bool {
		let warningFile = if case .page(let path) = warning.location {
			contentFile(ofPage: path)
		} else {
			warning.location?.file
		}

		guard let warningFile else {
			return false
		}

		return files.contains { file in
			warningFile.isInside(file) || warningFile.isSameFile(as: file) || file.isInside(warningFile)
		}
	}

	/**
	The checks of the text of the content, which share its parsed Markdown, so code that shows a link is not a link, and a link text can span lines. The Markdown cannot leave the task that parsed it, so these checks run one after the other, and only the spelling checker runs on the main actor, which it needs.
	*/
	private func textWarnings(of contentFiles: [MarkdownFile]) async -> (warnings: [Warning], steps: StepTimes) {
		var steps = StepTimes()

		let bodies = steps.measure("Parse the content") {
			contentFiles.map { CheckedText(file: $0, parsing: $0.body) }
		}

		// The feedback notes of the apps are Markdown in the frontmatter, so their problems are reported at their key, as the lines of the SOML value are not the lines of the note.
		let feedbackNotes = apps.compactMap { app in
			app.frontmatter.feedbackNote.map { CheckedText(file: app.file, parsing: $0, line: app.file.line(of: App.Frontmatter.CodingKeys.feedbackNote)) }
		}

		let files = bodies + feedbackNotes

		var warnings = [Warning]()
		warnings += steps.measure("Check Markdown") { markdownWarnings(in: files) }
		warnings += steps.measure("Check plain-text shortcuts") { plainTextShortcutWarnings(in: files) }
		warnings += steps.measure("Check raw links") { rawLinkWarnings(in: files) }
		let spelling = steps.measure("Check repeated words") { spellingTexts(in: files) }
		let unknownWords = await steps.measure("Check spelling") {
			await unknownWordWarnings(in: spelling.map(\.texts))
		}

		// The warnings of each file together.
		for (file, fileUnknownWords) in zip(spelling, unknownWords) {
			warnings += file.repeatedWords + fileUnknownWords
		}

		return (warnings, steps)
	}

	/**
	Facts that the App Store knows better: whether the app exists, its price, its platforms, and its lowest OS version.
	*/
	private func appStoreWarnings() -> [Warning] {
		var warnings = [Warning]()

		for app in apps where !app.isArchived && app.appStoreID != nil {
			// The build already warns about an app that the App Store does not have.
			guard let info = listing(of: app).appStoreInfo else {
				continue
			}

			if
				let price = info.price,
				!price.isFree,
				!app.isPaid
			{
				warnings.append(app.file.warning(.appStoreMismatch, "The App Store price is \(price.formatted), but `isPaid` is false."))
			}

			// Only platforms that the App Store lists are checked, and iOS for Mac apps. Apple Watch apps are listed with iPhone devices, as they come with an iPhone app.
			let missingPlatforms = info.listedPlatforms
				.subtracting(app.platforms)
				.filter { $0 != .iOS || !app.platforms.contains(.watchOS) }

			for platform in missingPlatforms.sorted(using: KeyPathComparator(\.rawValue)) {
				warnings.append(app.file.warning(.appStoreMismatch, "The App Store version supports \(platform.rawValue), but `platforms` does not have it."))
			}

			if
				info.isMacApp,
				app.platforms.contains(.iOS)
			{
				warnings.append(app.file.warning(.appStoreMismatch, "`platforms` has iOS, but the App Store version is a Mac app."))
			}

			// The lowest version is for macOS for Mac apps, for visionOS for apps only for Apple Vision, and for iOS for the others.
			if let minimumVersion = info.minimumOSVersion {
				let system = info.isMacApp ? Platform.macOS : info.listedPlatforms == [.visionOS] ? .visionOS : .iOS
				warnings += olderVersionMentions(in: app, system: system, minimumVersion: minimumVersion)
			}
		}

		return warnings
	}

	/**
	Prices of apps on Gumroad that Gumroad does not agree with, as the page shows the price of `gumroad` in the frontmatter.
	*/
	private func gumroadWarnings() -> [Warning] {
		apps.compactMap { app in
			guard
				let product = listing(of: app).gumroadProduct,
				let price = app.frontmatter.gumroad?.price,
				let productPrice = product.price,
				productPrice != price
			else {
				return nil
			}

			return app.warning(.gumroadPrice, at: .gumroad, "The Gumroad price is \(productPrice.formatted), but `gumroad.price` is \(price.formatted).")
		}
	}

	/**
	Projects of the open source page that GitHub does not agree with: a repo that GitHub does not have, like after it was renamed or moved, an archived repo, and another main language. The projects are a list in the code, so nothing else checks them, and the page shows no data of the repos. The repos are the ones of the account and its organizations that the build got (``GitHub/Account/repositories``), so the check asks GitHub nothing more, and it checks nothing when the build could not get them.
	*/
	private func openSourceProjectWarnings() -> [Warning] {
		guard let repositories = gitHubAccount?.repositories else {
			return []
		}

		// The names ignore case, like GitHub.
		let repositoriesByName = Dictionary(repositories.map { ($0.nameWithOwner, $0) }) { first, _ in first }

		return OpenSourceProject.all.flatMap { project -> [Warning] in
			func warning(_ message: String) -> Warning {
				Warning(.openSourceProject, at: .page(.openSource), "\(project.name) (`\(project.repository)`) \(message)")
			}

			guard let repository = repositoriesByName[project.repository] else {
				return [warning("is not a repo on GitHub. Maybe it was renamed or moved. Fix its `repository` in `OpenSourcePage.swift`.")]
			}

			var warnings = [Warning]()

			if repository.isArchived {
				warnings.append(warning("is archived on GitHub. Remove it from the page, or unarchive the repo."))
			}

			if repository.language != project.language?.rawValue {
				warnings.append(warning("has the language \(repository.language.map { "`\($0)`" } ?? "none") on GitHub, but \(project.language.map { "`\($0.rawValue)`" } ?? "none") on the page. Fix its `language` in `OpenSourcePage.swift`."))
			}

			return warnings
		}
	}

	/**
	The end of a sentence: its punctuation and the space after it, so a version like “15.3” is not an end.
	*/
	nonisolated(unsafe) private static let sentenceEnd = /[.!?]\s+/

	/**
	Mentions of OS versions below the App Store minimum, like “Requires macOS 15 or later” for an app that needs macOS 26, in the text and the feedback note. Only the major versions of the mentions are compared, so “macOS 26” is fine for an app that needs 26.2. Text about the older versions is left out: lists of older versions to download and the requirement below them, like `*Requires macOS 15 or later*`, and sentences that link to the “Older Versions” section. A line is a whole paragraph, so only the sentence with the link is left out, not the other sentences of the paragraph.
	*/
	private func olderVersionMentions(in app: App, system: Platform, minimumVersion: OSVersion) -> [Warning] {
		let pattern = Regex {
			Anchor.wordBoundary
			system.rawValue
			" "
			Capture {
				OneOrMore(.digit)
				Optionally {
					"."
					OneOrMore(.digit)
				}
			}
			Anchor.wordBoundary
		}

		let file = app.file

		let olderVersionsLink = "](#\(App.Section.olderVersions.id))"
		var bodyLines = [(line: Int?, text: Substring)]()
		var isAfterDownloadList = false

		for (index, line) in file.bodyLines.enumerated() {
			let isDownload = line.hasPrefix("- [")

			if
				!isDownload,
				!(isAfterDownloadList && line.hasPrefix("*\(OSVersion.requirementPrefix)"))
			{
				// A sentence ends with a period, a question mark, or an exclamation mark, and a space, so a version like `15.3` stays in its sentence.
				let text = line.contains(olderVersionsLink) ? Substring(line.split(separator: Self.sentenceEnd).filter { !$0.contains(olderVersionsLink) }.joined(separator: " ")) : line
				bodyLines.append((file.bodyStartLine + index, text))
			}

			// Blank lines keep the list going, so the requirement below it is part of it.
			if !line.allSatisfy(\.isWhitespace) {
				isAfterDownloadList = isDownload
			}
		}

		// The feedback note is reported at its key, as the lines of the SOML value are not the lines of the note.
		let noteLines = (app.frontmatter.feedbackNote ?? "").split(separator: "\n").map { (line: file.line(of: App.Frontmatter.CodingKeys.feedbackNote), text: $0) }

		return (bodyLines + noteLines).flatMap { line, text in
			text.matches(of: pattern)
				.filter { $0.output.1.majorVersion < minimumVersion.major }
				.map { file.warning(.oldOSVersionMention, line: line, "Mentions \($0.output.0), but the App Store version needs \(system.rawValue) \(minimumVersion).") }
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

				return app.file.warning(.longIntroduction, line: app.file.bodyStartLine + lineIndex, "The introduction is \(introduction.count) characters. The app page shows it under the name, so keep it at most \(App.maximumIntroductionLength) characters, which is two lines.")
			}
	}

	/**
	Questions of the FAQ sections and of the general FAQ (`/apps/faq`, its `###` headings) without an ID of their own (`{#id}`), whose ID comes from their text, so rewording a question breaks the links to it, also the links that the build cannot see, like in support emails, GitHub issues, and the apps.
	*/
	private func questionIDWarnings() -> [Warning] {
		let generalQuestions = page(.faq).map { page in
			(file: page.file, headings: page.markdown.headings.filter { $0.level == .h3 })
		}

		return (apps.map { (file: $0.file, headings: $0.faqHeadings) } + [generalQuestions].compactMap(\.self)).flatMap { file, headings in
			// A question without a line is added by the build, so its ID is in its source.
			headings.compactMap { heading in
				guard
					!heading.hasCustomID,
					let line = heading.line
				else {
					return nil
				}

				return file.warning(.questionWithoutID, line: line, "The question “\(heading.text)” has no ID of its own, so changing its text breaks the links to it, like in support emails. Give it its ID: `{#\(heading.id)}`.")
			}
		}
	}

	/**
	Questions of the FAQ sections that have the same answer in more than one app, which belong in `content/shared-questions.md`, so the answer is in one place. Questions with the same text but other answers are fine, like “Can you support iOS?”, which has a reason for each app. A question that replaces a question that the build adds (``App/commonQuestionTitles``) is left out, as a shared question cannot replace it.
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
			let commonQuestionTitles = app.commonQuestionTitles

			// The questions of the file, as the added questions have no lines.
			for heading in app.faqHeadings {
				guard
					let line = heading.line,
					!commonQuestionTitles.contains(heading.text),
					let answer = app.faqAnswerMarkdown(of: heading)
				else {
					continue
				}

				questions[Question(title: heading.text, answer: answer), default: []].append(Place(app: app, line: line))
			}
		}

		// In the order of the apps and the lines, as the order of a dictionary changes between builds. A question that one app has twice is not shared.
		return questions
			.filter { Set($0.value.map(\.app.slug)).count > 1 }
			.flatMap { question, places in
				places.map { place in
					let otherApps = places.filter { $0.app.slug != place.app.slug }.map { "`\($0.app.slug)`" }.formatted(.list(type: .and))
					return (place: place, message: "The question “\(question.title)” has the same answer in \(otherApps). Move it to `\(App.SharedQuestions.path)`, so the answer is in one place.")
				}
			}
			.sorted(using: [KeyPathComparator(\.place.app.slug), KeyPathComparator(\.place.line)])
			.map { $0.place.app.file.warning(.sharedAnswer, line: $0.place.line, $0.message) }
	}

	/**
	Lists and paragraphs of 25 or more words that are the same in the FAQ answers of more than one app, like the same steps, which belong in `content/shared-questions.md` or in one answer that the others link to, so they do not get out of sync. Answers that are the same as a whole are left out, as ``sharedAnswerWarnings()`` reports them. A shared question is in one place, so it is not counted. The warning is at the question, as the blocks are parsed from the answer.
	*/
	private func copiedAnswerBlockWarnings() -> [Warning] {
		struct Place {
			let app: App
			let line: Int
			let question: String
			let answer: String
		}

		var blocks = [String: [Place]]()

		for app in apps where !app.isRedirect {
			for heading in app.faqHeadings {
				guard
					let line = heading.line,
					let answer = app.faqAnswerMarkdown(of: heading)
				else {
					continue
				}

				let place = Place(app: app, line: line, question: heading.text, answer: answer)

				for block in Markdown.Document(parsing: answer, options: .parseBlockDirectives).blockChildren {
					let words = block.format().split(whereSeparator: \.isWhitespace)
					let text = words.joined(separator: " ")

					guard
						words.count >= 25,
						blocks[text]?.contains(where: { $0.app.slug == app.slug && $0.line == line }) != true
					else {
						continue
					}

					blocks[text, default: []].append(place)
				}
			}
		}

		let copies = blocks.values
			.filter { places in
				Set(places.map(\.app.slug)).count > 1
					&& Set(places.map { [$0.question, $0.answer] }).count > 1
			}
			.flatMap { places in
				places.map { place in
					(place: place, otherApps: places.map(\.app.slug).filter { $0 != place.app.slug })
				}
			}

		// One warning for each answer, also when it has several copied blocks. In the order of the apps and the lines, as the order of a dictionary changes between builds.
		return Dictionary(grouping: copies) { "\($0.place.app.slug):\($0.place.line)" }.values
			.map { copies in
				(place: copies[0].place, otherApps: Set(copies.flatMap(\.otherApps)))
			}
			.sorted(using: [KeyPathComparator(\.place.app.slug), KeyPathComparator(\.place.line)])
			.map { copy in
				let otherApps = copy.otherApps.sorted().map { "`\($0)`" }.formatted(.list(type: .and))
				return copy.place.app.file.warning(.copiedAnswerBlock, line: copy.place.line, "The answer of “\(copy.place.question)” has a list or paragraph that is also in the FAQ of \(otherApps). Move the question to `\(App.SharedQuestions.path)`, or link to one answer, so the copies do not get out of sync.")
			}
	}

	/**
	Promises in the FAQ answers, like “I plan to add it at some point”, which stay on the page for years when the plans change. A phrase after a negation in its sentence is not a promise, like “It’s not something I plan to support”. Archived apps are left out, as they get no updates.
	*/
	private func promiseWarnings() -> [Warning] {
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let promise = /(?i)\b(?:I plan to|is planned|are planned|at some point|in the future|hopefully)\b/
		let negation = /(?i)\b(?:not|never)\b|n['’]t\b/
		var warnings = [Warning]()

		for app in apps where !app.isRedirect && !app.isArchived {
			for heading in app.faqHeadings {
				for (line, text) in app.faqAnswerLines(of: heading) ?? [] {
					// One warning for each line, like for “I plan to do it at some point”.
					let match = text.matches(of: promise).first { match in
						let lineStart = text[..<match.range.lowerBound]
						let sentenceStart = lineStart.ranges(of: Self.sentenceEnd).last?.upperBound ?? lineStart.startIndex
						return !lineStart[sentenceStart...].contains(negation)
					}

					if let match {
						warnings.append(app.file.warning(.promise, line: line, "The answer of “\(heading.text)” promises something: “\(match.output)”. Remove the promise when the plan changed, or answer what the app does now."))
					}
				}
			}
		}

		return warnings
	}

	/**
	Links in the text and the frontmatter that use `http://`, as the visitor goes through an unencrypted request first (except a local address, like `http://localhost:3000`), or that have tracking parameters, like `utm_source=chatgpt.com` from a link that was copied from a chat. `ref` is fine, as sponsors use it on purpose. Inline code is left out, as it can show such a link, like an answer about them. Limitation: a code block is not left out. A link inside another one, like the original address of an archived page, is part of the outer link, so it is not checked.
	*/
	private func linkWarnings(in files: [MarkdownFile]) -> [Warning] {
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let urlPattern = /https?:\/\/[^\s'"<>)\]`]+/
		let inlineCode = /`[^`]*`/
		let trackingParameters: Set = ["fbclid", "gclid", "si"]
		let localHosts: Set = ["localhost", "127.0.0.1"]
		var warnings = [Warning]()

		for file in files {
			// The frontmatter starts on the line after `---`.
			let lines = file.frontmatter.split(separator: "\n", omittingEmptySubsequences: false).enumerated().map { (line: $0.offset + 2, text: $0.element) }
				+ file.bodyLines.enumerated().map { (line: file.bodyStartLine + $0.offset, text: $0.element) }

			for (line, text) in lines {
				for match in text.replacing(inlineCode, with: "").matches(of: urlPattern) {
					let components = URLComponents(string: String(match.output))

					if
						components?.scheme == "http",
						!localHosts.contains(components?.host ?? "")
					{
						warnings.append(file.warning(.insecureLink, line: line, "The link \(match.output) uses `http://`. Use `https://` when the site supports it."))
					}

					let names = components?.queryItems?.map(\.name) ?? []

					guard let name = names.first(where: { $0.hasPrefix("utm_") || trackingParameters.contains($0) }) else {
						continue
					}

					warnings.append(file.warning(.trackingParameter, line: line, "The link \(match.output) has the tracking parameter `\(name)`. Remove it."))
				}
			}
		}

		return warnings
	}

	/**
	Requirements that the page gets wrong or leaves out (``AppListing/minimumOSVersion``):

	- A `minimumOSVersion` that is not needed, as the page shows the version of the App Store or of the appcast instead. It is still needed while the App Store has no version of 26 or later, like for an app that is not released yet, as the App Store has the version of one platform.
	- An app that is not on the App Store and has no requirement, as it has no appcast and no `minimumOSVersion`. An app with an appcast that did not load is left out, as the build already warns about it, and archived apps are left out, as they cannot be downloaded.
	*/
	private func requirementWarnings() -> [Warning] {
		apps.compactMap { app in
			let file = app.file

			if
				app.frontmatter.minimumOSVersion != nil,
				let fetchedVersion = listing(of: app).fetchedMinimumOSVersion
			{
				let source = app.appStoreID == nil ? "the appcast" : "the App Store"
				return file.warning(.requirement, at: App.Frontmatter.CodingKeys.minimumOSVersion, "`minimumOSVersion` is not needed, as the page shows the version of \(source) instead, \(fetchedVersion). Remove it.")
			}

			guard
				app.appStoreID == nil,
				app.appcastURL == nil,
				!app.isArchived,
				!app.isRedirect,
				listing(of: app).minimumOSVersion == nil
			else {
				return nil
			}

			return file.warning(.requirement, "The page shows no requirement, as the app is not on the App Store and has no appcast. Add `minimumOSVersion`.")
		}
	}

	/**
	Trials whose macOS version (`trial.macOS`) is not backed by the requirement of the app: the page has no requirement in the hero, or the app needs a newer macOS than the trial says. A trial can need a newer version than the app, so that is fine. A trial with the version of the app does not need it, as a trial without it has the requirement of the app.
	*/
	private func trialRequirementWarnings() -> [Warning] {
		apps.compactMap { app in
			guard
				!app.isRedirect,
				!app.isArchived,
				let trialVersion = app.frontmatter.trial?.macOS
			else {
				return nil
			}

			let listing = listing(of: app)

			guard let requirement = listing.minimumOSVersion else {
				// An app whose App Store data or appcast did not load is left out, as the build already warns about it.
				guard
					app.appStoreID == nil || listing.appStoreInfo != nil,
					app.appcastURL == nil || listing.appcast != nil
				else {
					return nil
				}

				return app.warning(.trialRequirement, at: .trial, "The trial needs macOS \(trialVersion), but the page shows no requirement for the app. Add `minimumOSVersion`.")
			}

			if trialVersion == requirement {
				return app.warning(.trialRequirement, at: .trial, "`trial.macOS` is not needed, as it is the version of the app, \(requirement). Remove it.")
			}

			guard trialVersion < requirement else {
				return nil
			}

			return app.warning(.trialRequirement, at: .trial, "The trial says macOS \(trialVersion), but the app needs macOS \(requirement).")
		}
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

				warnings.append(app.warning(.downloadVersion, at: download.key, "The version \(download.version) is not the version in the name of its download, \(download.url.lastPathComponent)."))
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
				warnings.append(app.file.warning(.missingIcon, "The app has no `icon.png` next to it, so it shows a placeholder icon."))
			}

			// An archived app is no longer available, so it does not need to show itself.
			if
				app.isActive,
				app.media.isEmpty
			{
				warnings.append(app.file.warning(.missingMedia, "The app has no screenshots (`screenshot*.png/jpg`) or videos (`video*.mp4`) next to it, so its page shows none."))
			}

			let icon = project.publicFile(app.iconPath)

			if
				let size = try? icon.resourceValues(forKeys: [.fileSizeKey]).fileSize,
				size > 300_000
			{
				warnings.append(Warning(.heavyIcon, at: .file(icon), "The icon is \(size / 1000) KB. Icons are usually less than 300 KB."))
			}

			let screenshotSizes = Set(app.screenshots.map(\.size))

			if screenshotSizes.count > 1 {
				warnings.append(Warning(.screenshotSizes, at: .file(project.publicFile(App.assetDirectory(slug: app.slug))), "The screenshots have different sizes: \(screenshotSizes.map(\.description).sorted(using: .localizedStandard).joined(separator: ", "))."))
			}

			// An archived app is no longer available, so its screenshots are not made again.
			if app.isActive {
				for screenshot in app.screenshots where !screenshot.isSharpOnRetina {
					// A screenshot narrower than the carousel is shown at its own width, not wider.
					let shownWidth = Int(min(screenshot.maximumDisplayWidth, Double(screenshot.retinaWidth) / 2))
					warnings.append(Warning(.blurryScreenshot, at: .file(project.publicFile(screenshot.path)), "The screenshot is \(screenshot.size.width) px wide, but the page shows it up to \(shownWidth) px wide, so it is blurry on Retina screens. Use a screenshot that is \(screenshot.retinaWidth) px wide."))
				}
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

			warnings.append(Warning(.deepPNG, at: .file(png), "The PNG has \(depth) bits per channel. 8 bits look the same and are much smaller."))
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

		/**
		The markup of the kind anywhere in the Markdown, like every text, in the order of the file.
		*/
		func descendants<Kind: Markup>(_ kind: Kind.Type) -> [Kind] {
			markdown.descendants(of: kind)
		}
	}

	/**
	Keyboard shortcuts written as plain text, like “Command+N” or “Option-Command-V”, which a page shows as keys when they are written as `++Command+N++`. Only a modifier, then `+` or `-`, then a key is found, so “Shift-click” and “Control-click” are text. Shortcuts that are already written as keys, headings, and link texts are left out, as a shortcut is not shown as keys in a heading or a link, and the text of a raw `<kbd>` has its own warning.
	*/
	private func plainTextShortcutWarnings(in files: [CheckedText]) -> [Warning] {
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let shortcut = /\b(?:(?:Control|Option|Shift|Command)[+-])+(?:F\d{1,2}|Return|Enter|Space|Tab|Esc|Delete|Plus|Home|End|[A-Z0-9])\b/
		// A shortcut that is already written as keys, like `++Command+N++`, is text of the parsed Markdown too.
		let keyboardShortcut = /\+\+\S(?:[^\n]*?\S)??\+\+/
		var warnings = [Warning]()

		for text in files {
			for textNode in text.descendants(Markdown.Text.self) {
				let isInHeadingOrLink = sequence(first: textNode as any Markup, next: \.parent).contains { $0 is Markdown.Heading || $0 is Markdown.Link }

				guard
					!isInHeadingOrLink,
					!textNode.isAfterKeyboardTag
				else {
					continue
				}

				for match in textNode.string.replacing(keyboardShortcut, with: " ").matches(of: shortcut) {
					let corrected = KeyboardKey.correctedShortcut(String(match.output).replacing("-", with: "+"))
					warnings.append(text.file.warning(.plainTextShortcut, line: text.line(of: textNode), "Write the keyboard shortcut “\(match.output)” as `++\(corrected)++`, so the page shows its keys."))
				}
			}
		}

		return warnings
	}

	/**
	Raw `<a>` tags in the text, which the build does not see as links: it does not resolve or check them where they are, and a link inside one is a nested link. Write a Markdown link instead. An HTML block, like a table, is left out, as Markdown is not parsed there.
	*/
	private func rawLinkWarnings(in files: [CheckedText]) -> [Warning] {
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let linkTag = /(?i)^<a\s/

		return files.flatMap { text in
			text.descendants(InlineHTML.self)
				.filter { $0.rawHTML.contains(linkTag) }
				.map { text.file.warning(.rawLink, line: text.line(of: $0), "Write the link as a Markdown link, like `[Dato](/dato)`, not with `<a>`, so the build checks it.") }
		}
	}

	/**
	Link texts that do not say where the link goes, links to the site that are not site paths, links to a heading whose ID comes from its text, feedback links with a product that is not an app of the feedback page, like `/feedback?product=Datto`, remote images without a size and raw images with only one of `width` and `height`, which make the page shift while loading, as an image needs both for its aspect ratio, raw HTML for what Markdown has a syntax for: `<kbd>` for keyboard shortcuts and `<sup>` for platforms, and modifier glyphs, like `⌘`, in the text and in code, which a keyboard shortcut writes with the names of its keys.

	Only the `<kbd>` and `<sup>` in the text are checked, not the ones in HTML blocks, like a table, where Markdown is not parsed. Raw images are checked in both. Code blocks are not checked for glyphs, as they show code.
	*/
	private func markdownWarnings(in files: [CheckedText]) -> [Warning] {
		let vagueLinkTexts: Set = ["here", "click here", "this", "this link", "link", "read more", "more", "learn more", "try this", "this shortcut", "download", "screenshot"]
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let whitespace = /\s+/
		let trailingPunctuation = /[.…]?(?: ›)?$/
		let htmlImage = /<img\b[^>]*>/
		let remoteSource = /\bsrc="https?:\/\//
		let widthAttribute = /\swidth=/
		let heightAttribute = /\sheight=/
		let platformText = /\(?(macOS|iOS|watchOS|tvOS|visionOS)(?:[- ]only)?\)?/
		let isModifierGlyph = { (character: Character) in KeyboardKey.Modifier(glyph: character) != nil }
		// The feedback page has the maintained apps, and its script finds the app by its title or a name of `feedbackNames` in any case, or by its slug (`feedback.js`).
		let feedbackApps = maintainedApps
		let feedbackProducts = Set(feedbackApps.flatMap { $0.feedbackLookupNames.map(\.feedbackLookupKey) })
		var warnings = [Warning]()

		for text in files {
			let file = text.file

			// Raw HTML is not parsed, so a regex finds its images. A local image with neither is left out, as it can be a Markdown image, which gets its size from the file.
			func imageWarnings(_ html: String, at markup: any Markup) -> [Warning] {
				html.matches(of: htmlImage).compactMap { match in
					let tag = match.output
					let hasWidth = tag.contains(widthAttribute)
					let hasHeight = tag.contains(heightAttribute)

					if hasWidth != hasHeight {
						let (present, missing) = hasWidth ? ("width", "height") : ("height", "width")
						return file.warning(.imageWithoutAspectRatio, line: text.line(of: markup), "The image has `\(present)` but no `\(missing)`, so it has no aspect ratio before it loads, and the page shifts. Add `\(missing)`.")
					}

					guard
						!hasWidth,
						tag.contains(remoteSource)
					else {
						return nil
					}

					return file.warning(.remoteImageWithoutSize, line: text.line(of: markup), "The remote image has no `width` and `height`, so the page shifts while it loads.")
				}
			}

			/**
			The text between a start tag of raw HTML and the next tag, like the keys of `<kbd>Command+C</kbd>`.
			*/
			func textAfter(_ html: InlineHTML) -> String? {
				(html.parent?.child(at: html.indexInParent + 1) as? Markdown.Text)?.string
			}

			func modifierGlyphWarning(at markup: any Markup) -> Warning {
				file.warning(.modifierGlyph, line: text.line(of: markup), "Write a keyboard shortcut with the names of its keys, like `++Option+Shift+Command+V++`, not with modifier glyphs, like “⌥⇧⌘V”.")
			}

			func check(_ markup: any Markup) {
				switch markup {
				case let link as Markdown.Link:
					// With an optional period, ellipsis, or arrow, like “Learn more.”, “More…”, and “Learn more ›”.
					let linkText = link.plainText.replacing(whitespace, with: " ").replacing(trailingPunctuation, with: "")

					if vagueLinkTexts.contains(linkText.lowercased()) {
						warnings.append(file.warning(.vagueLinkText, line: text.line(of: link), "The link text “\(linkText)” does not say where the link goes."))
					}

					let destination = link.destination.flatMap(URL.init(string:))

					// The build checks the site paths, but not the links to the site.
					if
						let destination,
						destination.host() == Site.url.host()
					{
						warnings.append(file.warning(.absoluteSiteLink, line: text.line(of: link), "Link to the site with a site path, like `\(destination.relativeReference)`, so the build checks the link."))
					}

					// The build finds a link to a missing heading, but not a link from another site, like a support reply, so the ID of a heading that pages link to must not change with its text. Limitation: only site paths are checked, not relative links to content files, like `dato.md#faq`. A heading without a line is added by the build, like a shared question, so its ID is in its source.
					if
						let destination,
						destination.host() == nil,
						destination.path().hasPrefix("/"),
						let fragment = destination.fragment(),
						let path = try? RoutePath(validating: destination.path()),
						let document = document(at: path),
						let heading = document.markdown.headings.first(where: { $0.id.rawValue == fragment }),
						!heading.hasCustomID,
						let headingLine = heading.line
					{
						warnings.append(file.warning(.headingLinkWithoutID, line: text.line(of: link), "The link goes to the heading “\(heading.text)”, whose ID comes from its text, so changing the text breaks the link. Give the heading its ID: `{#\(fragment)}` (\(SourceLocation.file(document.file.url, line: headingLine).description(relativeTo: project.root)))."))
					}

					// The link works with any product, but the form of an unknown one has no app, so the message has no app, and the page suggests no questions of the app, like after an app was renamed.
					if
						let destination,
						destination.host() == nil,
						destination.path() == RoutePath.feedback.description,
						let product = URLComponents(url: destination, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "product" })?.value,
						!feedbackProducts.contains(product.feedbackLookupKey)
					{
						let closestTitle = feedbackApps
							.map { (title: $0.title, distance: $0.title.feedbackLookupKey.difference(from: product.feedbackLookupKey).count) }
							.sorted(using: KeyPathComparator(\.distance))
							.first?
							.title
						let suggestion = closestTitle.map { " Did you mean “\($0)”?" } ?? ""
						warnings.append(file.warning(.unknownFeedbackProduct, line: text.line(of: link), "The feedback link has the product “\(product)”, which is not an app of the feedback page, so the form opens without the app.\(suggestion)"))
					}
				case let image as Markdown.Image where image.source?.hasPrefix("http://") == true || image.source?.hasPrefix("https://") == true:
					warnings.append(file.warning(.remoteImageWithoutSize, line: text.line(of: image), "The remote image has no size, so the page shifts while it loads. Use an `<img>` with `width` and `height`, or a local image."))
				case let html as InlineHTML:
					warnings += imageWarnings(html.rawHTML, at: html)

					if html.rawHTML == "<kbd>" {
						let message = if let keys = textAfter(html) {
							"Write the keyboard shortcut “\(keys)” as `++\(KeyboardKey.correctedShortcut(keys))++`, not with `<kbd>`."
						} else {
							"Write the keyboard shortcut as `++…++`, like `++Command+K++`, not with `<kbd>`."
						}

						warnings.append(file.warning(.rawKeyboardShortcut, line: text.line(of: html), message))
					}

					if
						html.rawHTML == "<sup>",
						let content = textAfter(html),
						let match = content.wholeMatch(of: platformText)
					{
						warnings.append(file.warning(.rawPlatformBadge, line: text.line(of: html), "Write the platform “\(content)” as a platform badge, like `^[\(match.1) only](platform: \"\(match.1)\")`, not with `<sup>`."))
					}
				case let html as HTMLBlock:
					warnings += imageWarnings(html.rawHTML, at: html)
				// The text of a raw `<kbd>` has its own warning, which corrects the glyphs.
				case let textNode as Markdown.Text where textNode.string.contains(where: isModifierGlyph) && !textNode.isAfterKeyboardTag:
					warnings.append(modifierGlyphWarning(at: textNode))
				case let code as InlineCode where code.code.contains(where: isModifierGlyph):
					warnings.append(modifierGlyphWarning(at: code))
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
	The words that are spelled right, but that the spelling checker does not know, like technical terms. One word per line in `content/spelling-allowlist.txt`, where a line that starts with `#` is a comment, and every word of the app titles.
	*/
	private func allowedWords() -> Set<String> {
		let list = (try? String(contentsOf: project.root.appending(path: "content/spelling-allowlist.txt"), encoding: .utf8)) ?? ""
		let listWords = list.split(whereSeparator: \.isNewline).filter { !$0.hasPrefix("#") }
		let appWords = apps.flatMap { $0.title.split { !$0.isLetter && $0 != "'" } }
		return Set((listWords + appWords).map { $0.lowercased() })
	}

	/**
	The texts of a file for the spelling checker (``unknownWordWarnings(in:)``), with their lines.
	*/
	private typealias SpellingTexts = (file: MarkdownFile, texts: [(string: String, line: Int)])

	/**
	Repeated words, like “the the”, in the text of the content, and the texts of each file for the spelling checker (``unknownWordWarnings(in:)``). Code, link destinations, HTML, and comments are left out, as only the text of the parsed Markdown is read.

	A repeat at the start of a sentence is found too, like “The the”. Limitation: a repeat across formatting or lines, like “the *the*”, is not found, and repeats that are right, like “had had”, are reported.
	*/
	private func spellingTexts(in files: [CheckedText]) -> [(repeatedWords: [Warning], texts: SpellingTexts)] {
		// Each word and the next one, which a lookahead keeps for the next match, as a backreference does not ignore case, so it would miss “The the”.
		let wordPair = /(?i)\b([a-z]+)\s+(?=([a-z]+)\b)/
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let bareURL = /https?:\/\/\S+/

		return files.map { checkedText in
			let file = checkedText.file
			var warnings = [Warning]()
			var texts = [(string: String, line: Int)]()

			func check(_ markup: any Markup) {
				guard let text = markup as? Markdown.Text else {
					for child in markup.children {
						check(child)
					}

					return
				}

				// Bare URLs and the custom IDs of headings are text in the parsed Markdown. A custom ID is removed, like when rendering, and an invalid one is a build error. A URL becomes an object replacement character, not a space, so the words around it do not look repeated.
				let string = (text.parent is Markdown.Heading ? text.string.removingCustomHeadingID : text.string)
					.replacing(bareURL, with: "\u{FFFC}")

				let line = checkedText.line(of: text)

				for match in string.matches(of: wordPair) {
					let (_, word, nextWord) = match.output

					guard
						word.lowercased() == nextWord.lowercased(),
						word.lowercased() != "a"
					else {
						continue
					}

					warnings.append(file.warning(.repeatedWord, line: line, "Repeated word: “\(word) \(nextWord)”."))
				}

				texts.append((string, line))
			}

			check(checkedText.markdown)
			return (warnings, (file, texts))
		}
	}

	/**
	Unknown words in the texts of each file, in the order of the files.

	Only lowercase words are checked. Words with capitals are usually names, like `Setapp` or `iCloud`, which would be most of the warnings. So a typo at the start of a sentence is not found.
	*/
	@MainActor
	private func unknownWordWarnings(in files: [SpellingTexts]) -> [[Warning]] {
		let allowedWords = allowedWords()
		let checker = NSSpellChecker.shared

		return files.map { file, texts in
			var warnings = [Warning]()

			// The spelling of all the texts of the file in one string, as each call of the spelling checker is slow (checking about 8,500 texts one by one took 1.7 s). A line break keeps the words of two texts apart. The ranges count UTF-16 code units, so the end of each text does too.
			let string = texts.map(\.string).joined(separator: "\n")
			var textEnds = [Int]()

			for text in texts {
				textEnds.append((textEnds.last ?? 0) + text.string.utf16.count + 1)
			}

			let length = string.utf16.count
			var offset = 0

			while offset < length {
				let range = checker.checkSpelling(
					of: string,
					startingAt: offset,
					language: "en_US",
					wrap: false,
					inSpellDocumentWithTag: 0,
					wordCount: nil
				)

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

				warnings.append(file.warning(.unknownWord, line: texts[textIndex].line, "Unknown word: “\(word)”."))
			}

			return warnings
		}
	}

	/**
	Checks on the published pages: headings that skip a level, which screen reader users navigate by, and public files that nothing links to.

	The first heading below the name of an app page (the `h1`), which starts its description, can be of any level, like `####` for a small heading, as `##` starts a section of the page, which its navigation lists (``AppPage``). Limitation: screen readers still announce the skipped levels there.

	The headings are only checked on the pages of the routes, not on redirect pages, which have no real headings, and not on the HTML files in `public`, which are published as they are, like the redirect of `/feedback/`.
	*/
	private func publishedSiteWarnings(published: PublishedSite, routes: [Route]) -> [Warning] {
		func isText(_ path: String) -> Bool {
			let pathExtension = URL(filePath: path).pathExtension
			return ["html", "css", "js", "xml", "json", "txt", "webmanifest"].contains(pathExtension) || pathExtension.isEmpty
		}

		// Only the published files, as the files of a draft are only published with its page.
		let publicFiles = ((try? project.publicFiles()) ?? []).filter { published.files.contains($0.outputFile) }
		let routeTexts = published.routeFiles.filter { isText($0.key.description) }.mapValues { String(decoding: $0, as: UTF8.self) }
		// The public files are copied as they are, so they are read from the project.
		let publicTexts = publicFiles.filter { isText($0.path.relativePath) }.map { (try? String(contentsOf: $0.source, encoding: .utf8)) ?? "" }
		// Simple word boundaries, as the Unicode ones are slow on this much HTML. With the content of the heading, for its text.
		let headingTag = /<h([1-6])\b[^>]*>(.*?)<\/h[1-6]>/.wordBoundaryKind(.simple).dotMatchesNewlines()
		let pagePathsByOutputFile = Dictionary(
			routes.compactMap { route -> (PublishedFilePath, RoutePath)? in
				guard case .page = route.output else {
					return nil
				}

				return (route.outputFile, route.path)
			}
		) { first, _ in first }
		let appPagePaths = Set(apps.map(\.path))
		var warnings = [Warning]()

		// In the order of the files, like the order of the output directory, as the order of a dictionary changes between builds.
		for (file, html) in routeTexts.sorted(using: KeyPathComparator(\.key.description, comparator: String.StandardComparator.lexical)) {
			guard let pagePath = pagePathsByOutputFile[file] else {
				continue
			}

			let isAppPage = appPagePaths.contains(pagePath)
			var previousLevel = 0

			for match in html.matches(of: headingTag) {
				let level = Int(match.output.1) ?? 0

				if
					level > previousLevel + 1,
					!isAppPage || previousLevel != 1
				{
					let text = String(match.output.2).replacing(/<[^>]*>/, with: "").decodingHTMLEscapes.trimmingCharacters(in: .whitespacesAndNewlines)
					let document = document(at: pagePath)

					// The line of the heading in the content file, or else the page, as the output directory can be anywhere, and the heading can be of the page, not of its content.
					let location: SiteKit.SourceLocation = if
						let document,
						let line = document.markdown.headings.first(where: { $0.level.rawValue == level && $0.text == text })?.line
					{
						.file(document.file.url, line: line)
					} else {
						.page(pagePath)
					}

					warnings.append(Warning(.skippedHeadingLevel, at: location, "The level \(level) heading “\(text)” follows a level \(previousLevel) heading."))
					break
				}

				previousLevel = level
			}
		}

		// As bytes, as searching a string this long for each public file is slow (about 20 s for all the files). `range(of:)` searches the bytes directly, while the generic `contains(_:)` of a collection is many times slower.
		let publishedText = Data((routeTexts.values + publicTexts).joined(separator: "\n").utf8)

		func publishedTextContains(_ text: String) -> Bool {
			publishedText.range(of: Data(text.utf8)) != nil
		}

		// Files that browsers, crawlers, and services find by their name, and pages, which are visited by their URL.
		let wellKnownFiles: Set = ["CNAME", "favicon.ico", ".nojekyll", ".DS_Store", "keybase.txt", "indexnow.txt"]

		// The placeholder icon is only used while an app has no icon. The sponsor logos in `assets/thanks/` are also linked from the readmes of the open-source projects, like the dark logos, which the site does not use.
		for asset in publicFiles where !wellKnownFiles.contains(asset.source.lastPathComponent) && !asset.path.starts(with: #path("/.well-known")) && !asset.path.starts(with: #path("/assets/thanks")) && !asset.path.description.hasSuffix(".html") && asset.path != App.placeholderIconPath {
			let path = asset.path
			let source = asset.source
			// Scripts load scripts next to them by a relative path, like `./nebula.js` in `home.js`.
			let isUsed = publishedTextContains(path.description) || publishedTextContains(path.description.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path.description) || publishedTextContains("./\(source.lastPathComponent)")

			if !isUsed {
				warnings.append(Warning(.unusedPublicFile, at: .file(source), "No published page, stylesheet, or script uses the file."))
			}
		}

		return warnings
	}

	/**
	Indexed pages with the same title or description as another page, which search engines show as the same result, like two sibling apps whose descriptions come from the same first sentence. The warning is at the content file of each page, or at the page when it has none, like `/apps`.
	*/
	private func duplicateMetadataWarnings(published: PublishedSite, routes: [Route]) -> [Warning] {
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let titleElement = /<title>([^<]*)<\/title>/
		let descriptionElement = /<meta name="description" content="([^"]*)">/
		var pagesByTitle = [String: [RoutePath]]()
		var pagesByDescription = [String: [RoutePath]]()

		for route in routes {
			guard
				case .page(let sitemapEntry, _) = route.output,
				sitemapEntry != nil,
				let html = published.text(of: route)
			else {
				continue
			}

			if let match = html.firstMatch(of: titleElement) {
				pagesByTitle[String(match.1).decodingHTMLEscapes, default: []].append(route.path)
			}

			if let match = html.firstMatch(of: descriptionElement) {
				pagesByDescription[String(match.1).decodingHTMLEscapes, default: []].append(route.path)
			}
		}

		func sameValueWarnings(_ kind: Warning.Kind, name: String, pagesByValue: [String: [RoutePath]]) -> [Warning] {
			pagesByValue
				.filter { $0.value.count > 1 }
				.flatMap { value, paths in
					paths.map { path in
						let otherPages = paths.filter { $0 != path }.map { "`\($0)`" }.formatted(.list(type: .and))
						return Warning(kind, at: sourceLocation(ofPage: path), "The page has the same \(name) as \(otherPages): “\(value)”. Give each page its own \(name).")
					}
				}
		}

		// In the order of their text, as the order of a dictionary changes between builds.
		return (sameValueWarnings(.duplicateTitle, name: "title", pagesByValue: pagesByTitle) + sameValueWarnings(.duplicateDescription, name: "description", pagesByValue: pagesByDescription))
			.sorted(using: KeyPathComparator(\.description, comparator: .localizedStandard))
	}
}

/**
The kinds of the warnings of `website check`, for its summary.
*/
extension Warning.Kind {
	static let appStoreMismatch = Self("Fact that the App Store does not agree with")
	static let gumroadPrice = Self("Price that Gumroad does not agree with")
	static let openSourceProject = Self("Open source project that GitHub does not agree with")
	static let oldOSVersionMention = Self("Mention of an OS version below the requirement")
	static let longIntroduction = Self("Long introduction")
	static let missingIcon = Self("Missing icon")
	static let missingMedia = Self("Missing screenshots")
	static let heavyIcon = Self("Heavy icon")
	static let screenshotSizes = Self("Screenshots of different sizes")
	static let blurryScreenshot = Self("Screenshot that is blurry on Retina screens")
	static let deepPNG = Self("PNG with more than 8 bits per channel")
	static let sharedAnswer = Self("Answer that is the same in several apps")
	static let questionWithoutID = Self("Question without a custom ID")
	static let copiedAnswerBlock = Self("Answer block that is in several apps")
	static let promise = Self("Promise in an answer")
	static let trackingParameter = Self("Tracking parameter")
	static let insecureLink = Self("Link with `http://`")
	static let downloadVersion = Self("Version that is not in the name of its download")
	static let trialRequirement = Self("Trial requirement")
	static let requirement = Self("Requirement")
	static let vagueLinkText = Self("Vague link text")
	static let absoluteSiteLink = Self("Link to the site that is not a site path")
	static let headingLinkWithoutID = Self("Link to a heading without a custom ID")
	static let unknownFeedbackProduct = Self("Feedback link with an unknown app")
	static let remoteImageWithoutSize = Self("Remote image without a size")
	static let imageWithoutAspectRatio = Self("Image without an aspect ratio")
	static let rawKeyboardShortcut = Self("Keyboard shortcut with `<kbd>`")
	static let rawPlatformBadge = Self("Platform with `<sup>`")
	static let plainTextShortcut = Self("Keyboard shortcut as plain text")
	static let rawLink = Self("Link with `<a>`")
	static let modifierGlyph = Self("Modifier glyph")
	static let repeatedWord = Self("Repeated word")
	static let unknownWord = Self("Unknown word")
	static let skippedHeadingLevel = Self("Skipped heading level")
	static let unusedPublicFile = Self("Unused public file")
	static let duplicateTitle = Self("Title of several pages")
	static let duplicateDescription = Self("Description of several pages")
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

extension Markdown.Text {
	/**
	Whether the text is directly after a raw `<kbd>` tag, like `⌘C` in `<kbd>⌘C</kbd>`.
	*/
	fileprivate var isAfterKeyboardTag: Bool {
		guard
			let parent,
			indexInParent > 0
		else {
			return false
		}

		return (parent.child(at: indexInParent - 1) as? InlineHTML)?.rawHTML == "<kbd>"
	}
}
