import AppKit
import Foundation
import Markdown
import RegexBuilder
import SiteKit
import SOML

extension SiteContent {
	/**
	Every warning of `website check`: the warnings of the build (``warnings``), and possible mistakes that do not fail the build, like a spelling mistake or an OS requirement that the App Store does not agree with.

	Checks the content, the public files, and the published site, so build it first, and pass what the build published and its routes. The checks run at the same time, and the warnings are in the order of the checks. It also returns how long each check took, which `--verbose` prints, as one slow check makes the whole check slow.

	- Parameter textFiles: Only check the text of the content files at these paths, or in these directories, like for `website check content/apps/dato`, as the checks of the text, like the spelling, are the slowest, and check each file on its own. The check of the published pages then also checks only those pages, as reading the other pages is most of its time. `nil` checks the text of all the files and all the published pages. A path outside the content, like a public file, only limits the check of the published pages. The other checks always check the whole site.
	- Parameter externalData: Where the published sitemap comes from, for the pages that the build would remove (``removedPageWarnings(publishedPaths:routes:)``). `.none` leaves that check out, like in tests.
	*/
	public func warnings(
		published: PublishedSite,
		routes: [Route],
		textFiles: [URL]? = nil,
		externalData: ExternalData = .none
	) async -> (warnings: [Warning], steps: StepTimes) {
		// A project without shared questions has no file.
		let contentFiles = documents.map(\.file) + [sharedQuestions.file].compactMap(\.self)

		// The text of the drafts of the preview of `website serve` is checked too, so a draft is not written blind (``drafts``).
		let checkedTextFiles = textFiles.map { textFiles in
			(contentFiles + drafts.files).filter { file in
				textFiles.contains(where: file.url.isSameFileOrInside)
			}
		} ?? contentFiles

		let checks: [(name: String, run: @Sendable () -> [Warning])] = [
			("Check App Store data", appStoreWarnings),
			("Check Gumroad prices", gumroadWarnings),
			("Check open source projects", openSourceProjectWarnings),
			("Check introductions", introductionWarnings),
			("Check media", { mediaWarnings(published: published) }),
			("Check shared answers", sharedAnswerWarnings),
			("Check shared questions", unusedSharedQuestionWarnings),
			("Check question IDs", questionIDWarnings),
			("Check question keywords", questionKeywordWarnings),
			("Check copied answer blocks", copiedAnswerBlockWarnings),
			("Check promises", promiseWarnings),
			("Check links", { linkWarnings(in: contentFiles) }),
			("Check download versions", downloadVersionWarnings),
			("Check trial requirements", trialRequirementWarnings),
			("Check requirements", requirementWarnings),
			("Check social cards", socialCardWarnings),
			("Check content file names", ignoredContentFileWarnings),
			("Check published site", { publishedSiteWarnings(published: published, routes: routes, onlyContentFiles: textFiles) }),
			("Check duplicate titles and descriptions", { duplicateMetadataWarnings(published: published, routes: routes) }),
		]

		// The checks of the text and of the published sitemap run at the same time as the other checks, and their warnings are last.
		async let text = textWarnings(of: checkedTextFiles)
		async let removedPages = removedPageWarnings(routes: routes, externalData: externalData)

		let results = await withTaskGroup { group in
			for (index, check) in checks.enumerated() {
				group.addTask(name: check.name) {
					var steps = StepTimes()
					let warnings = steps.measure(check.name, check.run)
					return (index: index, warnings: warnings, steps: steps)
				}
			}

			return await group.reduce(into: []) { $0.append($1) }
		}
		.sorted(using: KeyPathComparator(\.index))

		// A TODO note is the purpose of a draft.
		let draftURLs = Set(drafts.files.map(\.url))
		let textResult = await text
		let textWarnings = textResult.warnings.filter { $0.kind != .todo || $0.location?.file.map(draftURLs.contains) != true }
		return (self.warnings + results.flatMap(\.warnings) + (await removedPages) + textWarnings, StepTimes(results.flatMap(\.steps.steps) + textResult.steps.steps))
	}

	/**
	The pages of the published sitemap that the build would remove, like after a page was renamed (``removedPageWarnings(publishedPaths:routes:)``). The sitemap comes through the response cache, like the App Store data, and a failed request is a warning.
	*/
	private func removedPageWarnings(routes: [Route], externalData: ExternalData) async -> [Warning] {
		guard case .fetch(let cache) = externalData else {
			return []
		}

		let warnings = WarningCollector()

		let publishedPaths = await warnings.value(warning: "Could not get the published sitemap, so the pages that the build would remove are not checked") {
			try await cache.decoded(from: Sitemap.contentPath.absoluteURL(site: Site.origin)) { data in
				try Sitemap.pagePaths(inXML: String(decoding: data, as: UTF8.self))
			}
		}

		return removedPageWarnings(publishedPaths: publishedPaths ?? [], routes: routes) + warnings.all
	}

	/**
	The published pages that the build has no route for, neither a page nor a redirect, like after a page was renamed without `redirectFrom`, so the old URL would be a 404 after the deploy, also for links from other sites and search results.
	*/
	func removedPageWarnings(publishedPaths: [RoutePath], routes: [Route]) -> [Warning] {
		let routePaths = Set(routes.map(\.path))

		return publishedPaths
			.filter { !routePaths.contains($0) }
			.map { Warning(.removedPage, at: .page($0), "The page is published, but the build has no page or redirect for it, so it would be a 404 after the deploy. Add it to `redirectFrom` of the page that replaces it.") }
	}

	/**
	Questions of `content/shared-questions.md` that no app picks (`sharedQuestions`), so their answers are on no page, like after the last app that used one stopped using it.
	*/
	private func unusedSharedQuestionWarnings() -> [Warning] {
		guard let file = sharedQuestions.file else {
			return []
		}

		let pickedIDs = Set(apps.flatMap(\.frontmatter.sharedQuestions))

		return sharedQuestions.questionHeadings
			.filter { !pickedIDs.contains($0.id) }
			.map { file.warning(.unusedSharedQuestion, line: $0.line, "No app picks the question “\($0.text)” (`sharedQuestions`), so its answer is on no page. Pick it in an app with `\($0.id)`, or remove it.") }
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
			warningFile.isSameFileOrInside(file) || file.isInside(warningFile)
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

		// The feedback notes of the apps are Markdown in the frontmatter. The lines of a block string are the lines of the file, so their problems are at their lines.
		let feedbackNotes = apps.compactMap { app in
			app.frontmatter.feedbackNote.map { CheckedText(file: app.file, parsing: $0, ofKey: App.Frontmatter.CodingKeys.feedbackNote) }
		}

		// Only the texts of the checked files.
		let checkedURLs = Set(contentFiles.map(\.url))
		let isChecked = { (text: CheckedText) in checkedURLs.contains(text.file.url) }
		let files = bodies + feedbackNotes.filter(isChecked)

		// The titles and descriptions are the text of search results and social cards, so their spelling is checked too, at the line of their key. They are plain text, so only the spelling checks read them.
		let appTexts = apps.flatMap { app in
			[
				CheckedText(file: app.file, parsing: app.frontmatter.subtitle, ofKey: App.Frontmatter.CodingKeys.subtitle),
				app.frontmatter.description.map { CheckedText(file: app.file, parsing: $0, ofKey: App.Frontmatter.CodingKeys.description) },
			]
			.compactMap(\.self)
		}
		let guideTexts = guides.flatMap { guide in
			[
				CheckedText(file: guide.file, parsing: guide.frontmatter.title, ofKey: Guide.Frontmatter.CodingKeys.title),
				CheckedText(file: guide.file, parsing: guide.frontmatter.description, ofKey: Guide.Frontmatter.CodingKeys.description),
			]
		}
		let postTexts = posts.compactMap { post in
			post.frontmatter.description.map { CheckedText(file: post.file, parsing: $0, ofKey: BlogPost.Frontmatter.CodingKeys.description) }
		}
		let pageTexts = pages.flatMap { page in
			[
				CheckedText(file: page.file, parsing: page.frontmatter.title, ofKey: MarkdownPage.Frontmatter.CodingKeys.title),
				page.frontmatter.description.map { CheckedText(file: page.file, parsing: $0, ofKey: MarkdownPage.Frontmatter.CodingKeys.description) },
			]
			.compactMap(\.self)
		}
		let frontmatterTexts = appTexts + guideTexts + postTexts + pageTexts

		var warnings = [Warning]()
		warnings += steps.measure("Check Markdown") { markdownWarnings(in: files) }
		warnings += steps.measure("Check frontmatter comments") { frontmatterTodoWarnings(in: contentFiles) }
		warnings += steps.measure("Check plain-text shortcuts") { plainTextShortcutWarnings(in: files) }
		warnings += steps.measure("Check raw links") { rawLinkWarnings(in: files) }
		warnings += steps.measure("Check scheduled blocks") { pastScheduledBlockWarnings(in: files) }
		warnings += steps.measure("Check raw Markdown") { rawMarkdownWarnings(in: files) }
		let spelling = steps.measure("Check repeated words") { spellingTexts(in: files + frontmatterTexts.filter(isChecked)) }
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
	Prices and requirements of apps on Gumroad that Gumroad does not agree with, as the page shows the price of `gumroad` in the frontmatter, and the product page on Gumroad has its requirement as an attribute that is written by hand, like “Requires macOS 26”.
	*/
	private func gumroadWarnings() -> [Warning] {
		apps.flatMap { app -> [Warning] in
			let listing = listing(of: app)

			guard let product = listing.gumroadProduct else {
				return []
			}

			var warnings = [Warning]()

			if
				let price = app.frontmatter.gumroad?.price,
				let productPrice = product.price,
				productPrice != price
			{
				warnings.append(app.warning(.gumroadPrice, at: .gumroad, "The Gumroad price is \(productPrice.formatted), but `gumroad.price` is \(price.formatted)."))
			}

			// A buyer on an older version would buy an app that does not open.
			if
				let productRequirement = product.requirement,
				let minimumOSVersion = listing.minimumOSVersion,
				let requirement = listing.requirement,
				product.requiredOSVersion != minimumOSVersion
			{
				warnings.append(app.warning(.gumroadRequirement, at: .gumroad, "Gumroad says “Requires \(productRequirement)”, but the page says \(requirement). Fix it on Gumroad."))
			}

			return warnings
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
		let repositoriesByName = repositories.keyed(by: \.nameWithOwner)

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
		var bodyLines = [(line: SiteKit.SourceLocation.Line?, text: Substring)]()
		var isAfterDownloadList = false

		for (index, line) in file.bodyLines.enumerated() {
			let isDownload = line.hasPrefix("- [")

			if
				!isDownload,
				!(isAfterDownloadList && line.hasPrefix("*\(OSVersion.requirementPrefix)"))
			{
				// A sentence ends with a period, a question mark, or an exclamation mark, and a space, so a version like `15.3` stays in its sentence.
				let text = line.contains(olderVersionsLink) ? Substring(line.split(separator: Self.sentenceEnd).filter { !$0.contains(olderVersionsLink) }.joined(separator: " ")) : line
				bodyLines.append((file.bodyStartLine.offset(by: index), text))
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

				return app.file.warning(.longIntroduction, line: app.file.bodyStartLine.offset(by: lineIndex), "The introduction is \(introduction.count) characters. The app page shows it under the name, so keep it at most \(App.maximumIntroductionLength) characters, which is two lines.")
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
	Keywords of the questions that the feedback page suggests that have no effect (``Heading/faqKeywordMistakes``): the questions of the FAQ sections, the general questions of the FAQ page, and the shared questions, at the line of their question.
	*/
	private func questionKeywordWarnings() -> [Warning] {
		let generalQuestions = page(.faq).map { page in
			(file: page.file, headings: page.markdown.headings.filter { $0.contains(FAQDirectives.General.self) })
		}

		// The added questions have no lines, and the shared questions are checked in their file.
		let sharedQuestionHeadings = sharedQuestions.file.map { (file: $0, headings: sharedQuestions.questionHeadings) }

		return (apps.map { (file: $0.file, headings: $0.faqHeadings.filter { $0.line != nil }) } + [generalQuestions, sharedQuestionHeadings].compactMap(\.self)).flatMap { file, headings in
			headings.flatMap { heading in
				heading.faqKeywordMistakes.map { file.warning(.questionKeyword, line: heading.line, "The question “\(heading.text)”: \($0)") }
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
			let line: SiteKit.SourceLocation.Line
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
					let otherApps = places.filter { $0.app.slug != place.app.slug }.map { "`\($0.app.slug)`" }.formattedList(.and)
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
			let line: SiteKit.SourceLocation.Line
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
				let otherApps = copy.otherApps.sorted().map { "`\($0)`" }.formattedList(.and)
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
	Links in the text and the frontmatter that use `http://`, as the visitor goes through an unencrypted request first (except a local address, like `http://localhost:3000`), that have tracking parameters, like `utm_source=chatgpt.com` from a link that was copied from a chat, or that go to Dropbox without `raw=1` or `dl=1`, which open the preview page of the file, not the file, like a trial download. `ref` is fine, as sponsors use it on purpose. Inline code is left out, as it can show such a link, like an answer about them. Limitation: a code block is not left out. A link inside another one, like the original address of an archived page, is part of the outer link, so it is not checked.
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
			let lines = file.frontmatter.split(separator: "\n", omittingEmptySubsequences: false).enumerated().map { (line: SiteKit.SourceLocation.Line($0.offset + 2), text: $0.element) }
				+ file.bodyLines.enumerated().map { (line: file.bodyStartLine.offset(by: $0.offset), text: $0.element) }

			for (line, text) in lines {
				for match in text.replacing(inlineCode, with: "").matches(of: urlPattern) {
					let components = URLComponents(string: String(match.output))

					if
						components?.scheme == "http",
						!localHosts.contains(components?.host ?? "")
					{
						warnings.append(file.warning(.insecureLink, line: line, "The link \(match.output) uses `http://`. Use `https://` when the site supports it."))
					}

					// A shared link, like `https://www.dropbox.com/scl/fi/…`, opens a web page without `raw=1` or `dl=1`.
					if
						let components,
						["www.dropbox.com", "dropbox.com"].contains(components.host),
						components.path.hasPrefix("/scl/") || components.path.hasPrefix("/s/"),
						!(components.queryItems ?? []).contains(where: { ["raw", "dl"].contains($0.name) && $0.value == "1" })
					{
						warnings.append(file.warning(.dropboxPreviewLink, line: line, "The Dropbox link \(match.output) opens the preview page of the file, not the file. Add `raw=1`."))
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
				return app.warning(.requirement, at: .minimumOSVersion, "`minimumOSVersion` is not needed, as the page shows the version of \(source) instead, \(fetchedVersion). Remove it.")
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

	Also these downloads and the trial when the file name starts with the title of another app and not with the title of its own app, like `Dato-5.8.4-trial.zip` for Velja, as from a copied frontmatter. Only the letters and digits count, in any case. A file name with no title of an app is not checked.
	*/
	private func downloadVersionWarnings() -> [Warning] {
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let versionPattern = /\d+(?:\.\d+)+/
		var warnings = [Warning]()

		// Only the letters and digits, in lowercase, like `colorpicker214macos15zip` for `Color.Picker.2.1.4.-.macOS.15.zip`.
		func nameKey(_ name: String) -> String {
			name.lowercased().filter { $0.isLetter || $0.isNumber }
		}

		let appTitleKeys = apps.map { (app: $0, key: nameKey($0.title)) }

		for app in apps {
			let downloads = app.frontmatter.olderVersions.map { (version: $0.version, macOS: $0.macOS.rawValue, url: $0.url, key: App.Frontmatter.CodingKeys.olderVersions) }
				+ [app.frontmatter.nonAppStoreVersion].compactMap(\.self).map { (version: $0.version, macOS: String($0.macOS), url: $0.url, key: App.Frontmatter.CodingKeys.nonAppStoreVersion) }

			// A TestFlight trial has no file.
			let trialFiles = [app.frontmatter.trial].compactMap(\.self).filter { !$0.isTestFlight }.map { (url: $0.url, key: App.Frontmatter.CodingKeys.trial) }

			for file in downloads.map({ (url: $0.url, key: $0.key) }) + trialFiles {
				let fileName = file.url.value.lastPathComponent
				let fileKey = nameKey(fileName)

				guard
					!fileKey.hasPrefix(nameKey(app.title)),
					let other = appTitleKeys.first(where: { $0.app.slug != app.slug && fileKey.hasPrefix($0.key) })?.app
				else {
					continue
				}

				warnings.append(app.warning(.downloadOfOtherApp, at: file.key, "The download of `\(file.key.stringValue)` is `\(fileName)`, which has the name of \(other.title), not of \(app.title). Check its `url`."))
			}

			for download in downloads {
				let fileVersions = download.url.value.lastPathComponent.matches(of: versionPattern)
					.map { String($0.output) }
					.filter { $0 != download.macOS }

				guard
					!fileVersions.isEmpty,
					!fileVersions.contains(download.version.value)
				else {
					continue
				}

				warnings.append(app.warning(.downloadVersion, at: download.key, "The version \(download.version) is not the version in the name of its download, \(download.url.value.lastPathComponent)."))
			}
		}

		return warnings
	}

	/**
	Heavy icons, screenshots of different sizes, and 16-bit PNGs, which are much larger than 8-bit ones without looking better.
	*/
	private func mediaWarnings(published: PublishedSite) -> [Warning] {
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

		let pngs = published.publicFiles.map(\.source).filter { $0.pathExtension.lowercased() == "png" }

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
	Content files that the build leaves out, as it only reads files that end in `.md`, like a guide saved as `.MD`, `.markdown`, or `.txt`, which some editors do. A file below an `index.md` belongs to a page bundle, whose files the build publishes as they are, so it is not a content file.

	Also the folders that have files but no Markdown file, like a new app with only its icon, as the site silently has no page for them.
	*/
	private func ignoredContentFileWarnings() -> [Warning] {
		let markdownExtensions: Set = ["md", "markdown", "mdown", "txt"]
		var warnings = [Warning]()

		for documentType in contentDocumentTypes {
			let directory = documentType.directory.fileURL(in: project.root)

			let files = (try? directory.filesRecursively()) ?? []

			// Each file in a folder, with the folder directly in the directory, like `dato` for `dato/icon.png`. A hidden file, like `.DS_Store`, does not count.
			let folderFiles = files
				.filter { !$0.lastPathComponent.hasPrefix(".") }
				.compactMap { file in
					file.path(relativeTo: directory).split(separator: "/").dropLast().first.map { (file: file, folder: String($0)) }
				}

			// A folder whose Markdown file has another extension has the warning below.
			for folder in Set(folderFiles.map(\.folder)).sorted() where !folderFiles.contains(where: { $0.folder == folder && markdownExtensions.contains($0.file.pathExtension.lowercased()) }) {
				warnings.append(Warning(.folderWithoutPage, at: .file(directory.appending(path: folder)), "The folder `\(folder)` has files, but no `index.md`, so the site has no page for it. Add the page as `index.md`, or remove the folder."))
			}

			for file in files {
				let pathExtension = file.pathExtension

				guard
					pathExtension != "md",
					markdownExtensions.contains(pathExtension.lowercased())
				else {
					continue
				}

				let folders = sequence(first: file.deletingLastPathComponent()) { $0.deletingLastPathComponent() }.prefix { $0.isInside(directory) && !$0.isSameFile(as: directory) }

				// By its exact name, as a case-insensitive check would treat `index.MD` as the `index.md` of a bundle, which the build does not read.
				guard !folders.contains(where: { $0.files.contains { $0.lastPathComponent == "index.md" } }) else {
					continue
				}

				let name = file.lastPathComponent
				let correctedName = file.nameWithoutExtension + ".md"
				warnings.append(Warning(.ignoredContentFile, at: .file(file), "The build leaves out \(name), as a content file ends in `.md`. Rename it to `\(correctedName)`."))
			}
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
		Where the Markdown is in the file.
		*/
		enum Place {
			/**
			The body of the file.
			*/
			case body

			/**
			Lines of the file from the given line, like a block string in the frontmatter, whose lines are the lines of the file.
			*/
			case lines(from: SiteKit.SourceLocation.Line)

			/**
			One line of the file, like a value on the line of its key, where all its problems are.
			*/
			case line(SiteKit.SourceLocation.Line)

			/**
			Where the Markdown of a frontmatter value is in the file: the lines after the `'''` of a block string, whose lines are the lines of the file, or else the line of its key.
			*/
			init(ofValueOf key: some CodingKey, in file: MarkdownFile) {
				// The frontmatter starts on the line after the opening `---`.
				let lines = file.frontmatter.split(separator: "\n", omittingEmptySubsequences: false)

				guard let keyLine = file.line(of: key) else {
					self = .line(1)
					return
				}

				let keyAndNextLine = lines.dropFirst(keyLine.rawValue - 2).prefix(2).map { $0.trimmingCharacters(in: .whitespaces) }

				// The `'''` is on the line of the key, like `feedbackNote: '''`, or alone on the next line, below a key without a value.
				if keyAndNextLine.first?.hasSuffix(": '''") == true {
					self = .lines(from: keyLine.offset(by: 1))
					return
				}

				if
					keyAndNextLine.count == 2,
					keyAndNextLine[0].hasSuffix(":"),
					keyAndNextLine[1] == "'''"
				{
					self = .lines(from: keyLine.offset(by: 2))
					return
				}

				self = .line(keyLine)
			}
		}

		let place: Place

		init(file: MarkdownFile, parsing markdown: String, place: Place = .body) {
			self.file = file
			self.markdown = Markdown.Document(parsing: markdown, options: [.parseBlockDirectives, .disableSmartOpts])
			self.place = place
		}

		/**
		The Markdown of a frontmatter value of the file, at its place in the file (``Place/init(ofValueOf:in:)``).
		*/
		init(file: MarkdownFile, parsing value: String, ofKey key: some CodingKey) {
			self.init(file: file, parsing: value, place: Place(ofValueOf: key, in: file))
		}

		/**
		The line of the Markdown in the file.
		*/
		func line(of markup: any Markup) -> SiteKit.SourceLocation.Line {
			switch place {
			case .body:
				file.line(of: markup)
			case .lines(let firstLine):
				firstLine.offset(by: (markup.range?.lowerBound.line ?? 1) - 1)
			case .line(let line):
				line
			}
		}

		/**
		The markup of the kind anywhere in the Markdown, like every text, in the order of the file.
		*/
		func descendants<Kind: Markup>(_ kind: Kind.Type) -> [Kind] {
			markdown.descendants(of: kind)
		}
	}

	/**
	`@Scheduled` blocks whose last day is over, which no page shows again, so the owner removes them.
	*/
	private func pastScheduledBlockWarnings(in files: [CheckedText]) -> [Warning] {
		files.flatMap { text in
			text.descendants(BlockDirective.self).compactMap { directive in
				// The build already reported invalid arguments.
				guard
					directive.siteName == .scheduled,
					let arguments = try? directive.arguments(as: ScheduledArguments.self),
					arguments.until.date < today
				else {
					return nil
				}

				return text.file.warning(.pastScheduledBlock, line: text.line(of: directive), "The last day of the `@Scheduled` block was \(SOML.Value.date(arguments.until.date)), so the page does not show it again. Remove it, or give it new dates.")
			}
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
	Markdown that a mistake leaves as text, so the page shows its characters: a link with a space in its destination, like `[Velja](/velja page)`, a reference link without its definition, like `[Velja][velja-link]`, an unclosed `**` or backtick, a heading ID after text that is not a heading, like `Text {#text}`, and a heading without a space after its `#`, like `##Section`. Only the text of the parsed Markdown is read, so code is left out. Limitation: an escaped character that is meant as text, like `\*\*`, is reported too. Write it as code instead.
	*/
	private func rawMarkdownWarnings(in files: [CheckedText]) -> [Warning] {
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let mistakes = [
			(/\]\(/, "The text has `](`, as the link is not parsed, like a link with a space in its destination. Write a space in a destination as `%20`."),
			(/\]\[/, "The text has `][`, as the reference link has no definition, like `[velja-link]: /velja`. Add it, or write the link with its destination."),
			(/\*\*/, "The text has a `**` without its closing `**`, so the page shows the asterisks."),
			(/`/, "The text has a backtick without its closing backtick, so the page shows it."),
		]
		let headingID = /\{#[\w-]+\}\s*$/
		let headingWithoutSpace = /^#{2,6}[^#\s]/
		var warnings = [Warning]()

		for text in files {
			for textNode in text.descendants(Markdown.Text.self) {
				let string = textNode.string
				var messages = mistakes.filter { string.contains($0.0) }.map(\.1)

				// The ID of a heading is in its text.
				if
					!(textNode.parent is Markdown.Heading),
					string.contains(headingID)
				{
					messages.append("The text ends with a heading ID, like `{#id}`, which only a heading can have, so the page shows it.")
				}

				// At the start of a line, after a line break in a paragraph too.
				if
					textNode.previousSibling.map({ $0 is SoftBreak || $0 is LineBreak }) ?? true,
					string.contains(headingWithoutSpace)
				{
					messages.append("The text starts with `#`, but a heading needs a space after its `#`, like `## Section`.")
				}

				warnings += messages.map { text.file.warning(.rawMarkdown, line: text.line(of: textNode), $0) }
			}
		}

		return warnings
	}

	/**
	TODO notes in the comments of the frontmatter, like `# TODO: Update` above a date, which the page does not show, but the value that it doubts is published.
	*/
	private func frontmatterTodoWarnings(in files: [MarkdownFile]) -> [Warning] {
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let todoComment = /(?s)^(?:#|\/\*)\s*(TODO\b.*?)\s*(?:\*\/)?$/

		return files.flatMap { file in
			// The line in the frontmatter, which starts below the `---` line.
			var line = 1
			var warnings = [Warning]()

			for part in SOML.Token.parts(in: file.frontmatter) {
				if
					part.kind == .comment,
					let match = part.text.wholeMatch(of: todoComment)
				{
					warnings.append(file.todoWarning(note: match.1, line: MarkdownFile.lineInFile(ofFrontmatterLine: line)))
				}

				line += part.text.count { $0 == "\n" }
			}

			return warnings
		}
	}

	/**
	Raw `<a>` tags in the text, which the checks of the text do not see as links, like the check of vague link texts, and a link inside one is a nested link. The build resolves and checks their `href` like the destination of a Markdown link. Write a Markdown link instead. An HTML block, like a table, is left out, as Markdown is not parsed there.
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
	Link texts that do not say where the link goes, links to the site that are not site paths, links to a heading whose ID comes from its text, feedback links with a product that is not an app of the feedback page, like `/feedback?product=Datto`, remote images without a size and raw images with only one of `width` and `height`, which make the page shift while loading, as an image needs both for its aspect ratio, raw HTML for what Markdown has a syntax for: `<kbd>` for keyboard shortcuts and `<sup>` for platforms, modifier glyphs, like `⌘`, in the text and in code, which a keyboard shortcut writes with the names of its keys, footnotes, which are notes in the content of the site, phrases in straight double quotes, like `"Settings"`, which the site writes with typographic quotes, raw scripts, styles, and Astro attributes, which belong to components, links to Apple with a locale or storefront, a raw block element inside a paragraph, which the HTML parser moves out of it, links to a file of the own page bundle with its site path, which break when its folder is renamed, a line break alone as a spacer, and a TODO note in a comment, which a draft can have, as the content leaves the drafts out.

	Only the `<kbd>` and `<sup>` in the text, and the block elements inside a paragraph, are checked, not the ones in HTML blocks, like a table, where Markdown is not parsed. Raw images, scripts, styles, and links are checked in both. Code blocks are not checked, as they show code. Limitation: the links of the frontmatter are not checked for a locale, which `ContentGuardTests` does.
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
		// A run of modifier glyphs (``KeyboardKey/Modifier/glyph``) with its key, like “⌘K”, “⌥⇧⌘V”, or “⌘+⌫”, or without one, like in “hold ⌥”.
		let glyphShortcut = /[⌃⌥⇧⌘](?:\+?[⌃⌥⇧⌘])*(?:\+?(?:F\d{1,2}\b|(?:Space|Return|Enter|Tab|Esc|Escape|Delete)\b|[A-Za-z0-9]\b|[◀▶▲▼⌫⌦↩⇥⎋]))?/
		// A phrase in straight double quotes, like `"Settings"`. The first quote starts a word, so the inch marks of `13" and 15"` or `13", 15"` are not a phrase.
		let straightQuotes = /(?:^|[\s(\[])("\S(?:[^"]*\S)?")/
		let htmlComment = /(?s)<!--.*?-->/
		let todoComment = /(?s)<!--\s*(TODO\b.*?)\s*-->/
		let lineBreak = /(?i)^\s*<br\s*\/?>\s*$/
		let rawLinkDestination = /\s(?:href|src)="([^"]*)"/
		let rawHTMLMistakes = [
			(/(?i)<script\b/, "The content has a raw `<script>`. Move the script into a component."),
			(/(?i)<style\b/, "The content has a raw `<style>`. Move the look into a style of a component."),
			(/\sstyle="/, "The content has a `style` attribute. Move the look into a style of a component."),
			(/\sis:[a-z]/, "The content has an Astro attribute, like `is:inline`, which does nothing in the Swift build and publishes invalid HTML. Remove it."),
		]
		// The elements that close an open paragraph in the HTML parser, which then moves them out of it.
		let paragraphClosingTag = /(?i)<(address|article|aside|blockquote|dd|details|dialog|div|dl|dt|fieldset|figcaption|figure|footer|form|h[1-6]|header|hgroup|hr|li|main|menu|nav|ol|p|pre|search|section|summary|table|ul)\b/
		// The feedback page has the maintained apps, and its script finds the app by its title or a name of `feedbackNames` in any case, or by its slug (`feedback.js`).
		let feedbackApps = maintainedApps
		let feedbackProducts = Set(feedbackApps.flatMap { $0.feedbackLookupNames.map(\.feedbackLookupKey) })
		var warnings = [Warning]()

		for text in files {
			let file = text.file

			// The site paths of the files of the page bundle, like `/blog/issue-bumping/issue-bumping.jpg`.
			let bundleFilePaths = file.url.lastPathComponent == "index.md" ? Set(file.url.deletingLastPathComponent().files.compactMap { project.publicPath(ofContentFile: $0) }) : []

			// A site path breaks when the folder of the page is renamed, while a relative link moves with it.
			func bundleFileLinkWarning(_ destination: String?, at markup: any Markup) -> Warning? {
				guard
					let pathText = destination?.prefix(while: { $0 != "#" && $0 != "?" }),
					let path = try? RoutePath(validating: String(pathText)),
					bundleFilePaths.contains(path)
				else {
					return nil
				}

				let relativeLink = (pathText.split(separator: "/").last ?? "") + (destination?.dropFirst(pathText.count) ?? "")
				return file.warning(.absoluteBundleLink, line: text.line(of: markup), "Link to the file of the page bundle relatively, like `\(relativeLink)`, not with its site path `\(destination ?? "")`, so the link still works when the folder of the page is renamed.")
			}

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

			func localizedAppleLinkWarning(_ destination: String, at markup: any Markup) -> Warning? {
				guard destination.isLocalizedAppleLink else {
					return nil
				}

				return file.warning(.localizedAppleLink, line: text.line(of: markup), "Link to Apple without the locale or storefront, like `https://apps.apple.com/app/…` or `https://support.apple.com/102426`, so Apple shows the page in the language of the visitor: \(destination)")
			}

			// Raw HTML is not parsed, so regexes find its scripts, styles, and links. Comments are notes for the author, which the build leaves out.
			func rawHTMLWarnings(_ html: String, at markup: any Markup) -> [Warning] {
				// The build leaves the comments out, so the readers do not see a TODO, but the text that it doubts is published.
				let todos = html.matches(of: todoComment).map { match in
					file.todoWarning(note: match.1, line: text.line(of: markup))
				}

				let html = html.replacing(htmlComment, with: "")
				let mistakes = rawHTMLMistakes.filter { html.contains($0.0) }.map { file.warning(.rawScriptOrStyle, line: text.line(of: markup), $0.1) }
				let links = html.matches(of: rawLinkDestination).compactMap { localizedAppleLinkWarning(String($0.1), at: markup) }
				return todos + imageWarnings(html, at: markup) + mistakes + links
			}

			func isLineBreak(_ markup: any Markup) -> Bool {
				markup is LineBreak || (markup as? InlineHTML)?.rawHTML.contains(lineBreak) == true
			}

			/*
			The first of the line breaks at the end of the paragraph of the markup, like the first `<br>` of `**Note**<br><br>`, so a run of line breaks is reported once.
			*/
			func isFirstTrailingLineBreak(_ markup: any Markup) -> Bool {
				guard let paragraph = markup.parent as? Paragraph else {
					return false
				}

				let siblings = Array(paragraph.children)
				let start = siblings.lastIndex { !isLineBreak($0) }.map { $0 + 1 } ?? 0
				return markup.indexInParent == start
			}

			// A line break alone, as a block, as the only content of a paragraph, or at the end of a paragraph, is a spacer, which sets the layout from the content, while the styles set the space between the blocks.
			func lineBreakSpacerWarning(_ html: String, at markup: any Markup) -> Warning? {
				guard
					markup is HTMLBlock || isFirstTrailingLineBreak(markup),
					html.contains(lineBreak)
				else {
					return nil
				}

				return file.warning(.lineBreakSpacer, line: text.line(of: markup), "A line break (`<br>`) alone is a spacer, but the styles set the space between the blocks of the page. Remove it.")
			}

			// Each shortcut with its fix, like the warning of a shortcut as plain text.
			func modifierGlyphWarnings(in string: String, at markup: any Markup) -> [Warning] {
				string.matches(of: glyphShortcut).map { match in
					file.warning(.modifierGlyph, line: text.line(of: markup), "Write “\(match.output)” as `++\(KeyboardKey.correctedShortcut(String(match.output)))++`, with the names of its keys, not with modifier glyphs.")
				}
			}

			func check(_ markup: any Markup) {
				switch markup {
				case let link as Markdown.Link:
					// With an optional period, ellipsis, or arrow, like “Learn more.”, “More…”, and “Learn more ›”.
					let linkText = link.plainText.replacing(whitespace, with: " ").replacing(trailingPunctuation, with: "")

					if vagueLinkTexts.contains(linkText.lowercased()) {
						warnings.append(file.warning(.vagueLinkText, line: text.line(of: link), "The link text “\(linkText)” does not say where the link goes."))
					}

					if let warning = localizedAppleLinkWarning(link.destination ?? "", at: link) {
						warnings.append(warning)
					}

					if let warning = bundleFileLinkWarning(link.destination, at: link) {
						warnings.append(warning)
					}

					// The build checks the site paths, but not the links to the site.
					if
						let destination = link.destination.flatMap(URL.init(string:)),
						destination.host() == Site.url.host()
					{
						warnings.append(file.warning(.absoluteSiteLink, line: text.line(of: link), "Link to the site with a site path, like `\(destination.relativeReference)`, so the build checks the link."))
					}

					if case .path(let path, let query, let fragment)? = link.destination.flatMap({ try? LinkDestination(validating: $0) }) {
						// The build finds a link to a missing heading, but not a link from another site, like a support reply, so the ID of a heading that pages link to must not change with its text. Limitation: only site paths are checked, not relative links to content files, like `dato.md#faq`. A heading without a line is added by the build, like a shared question, so its ID is in its source.
						if
							let fragment,
							let document = document(at: path),
							let heading = document.markdown.headings.first(where: { $0.id.rawValue == fragment }),
							!heading.hasCustomID,
							let headingLine = heading.line
						{
							warnings.append(file.warning(.headingLinkWithoutID, line: text.line(of: link), "The link goes to the heading “\(heading.text)”, whose ID comes from its text, so changing the text breaks the link. Give the heading its ID: `{#\(fragment)}` (\(SourceLocation.file(document.file.url, line: headingLine).description(relativeTo: project.root)))."))
						}

						// The link works with any product, but the form of an unknown one has no app, so the message has no app, and the page suggests no questions of the app, like after an app was renamed.
						if
							path == .feedback,
							let product = query.first(where: { $0.name == FeedbackPage.Parameters.product.rawValue })?.value,
							!feedbackProducts.contains(product.feedbackLookupKey)
						{
							let suggestion = product.closest(in: feedbackApps.map(\.title)).map { " Did you mean “\($0)”?" } ?? ""
							warnings.append(file.warning(.unknownFeedbackProduct, line: text.line(of: link), "The feedback link has the product “\(product)”, which is not an app of the feedback page, so the form opens without the app.\(suggestion)"))
						}

						// The page sends a parameter that it does not know along with the message, but does nothing else with it, so a misspelled `product` opens the form without the app, and a misspelled `referrer` loses where the visitor came from.
						if path == .feedback {
							for item in query {
								guard let parameter = FeedbackPage.Parameters(rawValue: item.name) else {
									let suggestion = item.name.closest(in: FeedbackPage.Parameters.allCases.map(\.rawValue)).map { " Did you mean “\($0)”?" } ?? ""
									warnings.append(file.warning(.unknownFeedbackParameter, line: text.line(of: link), "The feedback link has the parameter “\(item.name)”, which the feedback page does not know.\(suggestion)"))
									continue
								}

								if
									parameter == .referrer,
									App.FeedbackReferrer(rawValue: item.value ?? "") == nil
								{
									let referrers = App.FeedbackReferrer.allCases.map { "“\($0.rawValue)”" }.formattedList(.and)
									warnings.append(file.warning(.unknownFeedbackParameter, line: text.line(of: link), "The feedback link has the referrer “\(item.value ?? "")”, which is not a referrer of the site. The referrers are \(referrers)."))
								}
							}
						}
					}
				case let image as Markdown.Image:
					if image.source?.hasPrefix("http://") == true || image.source?.hasPrefix("https://") == true {
						warnings.append(file.warning(.remoteImageWithoutSize, line: text.line(of: image), "The remote image has no size, so the page shifts while it loads. Use an `<img>` with `width` and `height`, or a local image."))
					}

					if let warning = bundleFileLinkWarning(image.source, at: image) {
						warnings.append(warning)
					}
				case let html as InlineHTML:
					warnings += rawHTMLWarnings(html.rawHTML, at: html) + [lineBreakSpacerWarning(html.rawHTML, at: html)].compactMap(\.self)

					if
						html.parent is Paragraph,
						let match = html.rawHTML.prefixMatch(of: paragraphClosingTag)
					{
						warnings.append(file.warning(.blockInParagraph, line: text.line(of: html), "The `<\(match.1.lowercased())>` is inside a paragraph, which the HTML parser closes before it, so the page is not structured like the HTML. Put a blank line before and after it."))
					}

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
					warnings += rawHTMLWarnings(html.rawHTML, at: html) + [lineBreakSpacerWarning(html.rawHTML, at: html)].compactMap(\.self)
				case let footnote as FootnoteReference:
					warnings.append(file.warning(.footnote, line: text.line(of: footnote), "Write the footnote `[^\(footnote.footnoteID)]` as a note, like `^[text](note: \"The note.\")`, which needs no definition in another place."))
				// The text of a raw `<kbd>` has its own warning, which corrects the glyphs.
				case let textNode as Markdown.Text:
					if !textNode.isAfterKeyboardTag {
						warnings += modifierGlyphWarnings(in: textNode.string, at: textNode)
					}

					// Only the text of the parsed Markdown, so code, the attributes of raw HTML, and the arguments of directives and notes are left out.
					warnings += textNode.string.matches(of: straightQuotes).map { match in
						file.warning(.straightQuotes, line: text.line(of: textNode), "Write the quotes of \(match.1) as “ and ”, like the other text of the site.")
					}
				case let code as InlineCode:
					warnings += modifierGlyphWarnings(in: code.code, at: code)
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
	The words that are spelled right, but that the spelling checker does not know, like technical terms: the words of `content/spelling-allowlist.txt` (``spellingAllowlist``), and every word of the app titles.
	*/
	private func allowedWords() -> Set<String> {
		let appWords = apps.flatMap { $0.title.split { !$0.isLetter && $0 != "'" } }
		return spellingAllowlist.union(appWords.map { $0.lowercased() })
	}

	/**
	The texts of a file for the spelling checker (``unknownWordWarnings(in:)``), with their lines.
	*/
	private typealias SpellingTexts = (file: MarkdownFile, texts: [(string: String, line: SiteKit.SourceLocation.Line)])

	/**
	Repeated words, like “the the”, in the text of the content, and the texts of each file for the spelling checker (``unknownWordWarnings(in:)``). Code, link destinations, HTML, and comments are left out, as only the text of the parsed Markdown is read.

	A repeat at the start of a sentence is found too, like “The the”. Limitation: a repeat across formatting or lines, like “the *the*”, is not found, and repeats that are right, like “had had”, are reported.
	*/
	private func spellingTexts(in files: [CheckedText]) -> [(repeatedWords: [Warning], texts: SpellingTexts)] {
		// Each word and the next one, which a lookahead keeps for the next match, as a backreference does not ignore case, so it would miss “The the”. The next word is a whole word, also with a hyphen, so “in in-app” is not a repeat.
		let wordPair = /(?i)\b([a-z]+)\s+(?=([a-z]+)\b(?!-))/
		// Before the loop, as Swift parses a regex literal each time the code runs.
		let bareURL = /https?:\/\/\S+/

		return files.map { checkedText in
			let file = checkedText.file
			var warnings = [Warning]()
			var texts = [(string: String, line: SiteKit.SourceLocation.Line)]()

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

	The headings are only checked on the pages of the routes, not on redirect pages, which have no real headings, and not on the HTML files in `public`, which are published as they are.

	- Parameter onlyContentFiles: Only check the pages of these content files, or in these directories, like for `website check content/apps/dato`, as reading the other pages is most of the time of the check, which `website serve` runs after each edit. The public files are checked only when these paths include a published asset, either in `public` or in a page bundle. `nil` checks every page and the public files.
	*/
	private func publishedSiteWarnings(published: PublishedSite, routes: [Route], onlyContentFiles: [URL]? = nil) -> [Warning] {
		func isText(_ path: String) -> Bool {
			let pathExtension = URL(filePath: path).pathExtension
			return ["html", "css", "js", "xml", "json", "txt", "webmanifest"].contains(pathExtension) || pathExtension.isEmpty
		}

		let pagePathsByOutputFile = Dictionary(
			routes.compactMap { route -> (PublishedFilePath, RoutePath)? in
				guard case .page = route.output else {
					return nil
				}

				return (route.outputFile, route.path)
			}
		) { first, _ in first }

		// A check that includes a published asset, either in `public` or in a page bundle, reads the public files. An edit of only a Markdown file leaves them out, as their warnings are at the asset, not at the edited Markdown file, and reading all the published pages is most of the time of the check.
		let checksPublicFiles = onlyContentFiles.map { files in
			published.publicFiles.contains { asset in
				files.contains(where: asset.source.isSameFileOrInside)
			}
		} ?? true

		// Whether the page is one of the pages of the given files. It is true for every page when the check is for none.
		func isCheckedPage(_ file: PublishedFilePath) -> Bool {
			guard let onlyContentFiles else {
				return true
			}

			guard
				let pagePath = pagePathsByOutputFile[file],
				let document = document(at: pagePath)
			else {
				return false
			}

			return onlyContentFiles.contains(where: document.file.url.isSameFileOrInside)
		}

		// Only the published files, as the files of a draft are only published with its page. A check that includes a published asset reads every page, as it searches them for the file. An edit of only a Markdown file reads the pages of the file.
		let routeTexts = published.routeFiles.filter { file in
			isText(file.key.description) && (checksPublicFiles || isCheckedPage(file.key))
		}.mapValues { String(decoding: $0, as: UTF8.self) }
		// Simple word boundaries, as the Unicode ones are slow on this much HTML. With the content of the heading, for its text.
		let headingTag = /<h([1-6])\b[^>]*>(.*?)<\/h[1-6]>/.wordBoundaryKind(.simple).dotMatchesNewlines()
		let htmlTag = /<[^>]*>/
		let appPagePaths = Set(apps.map(\.path))
		var warnings = [Warning]()

		// In the order of the files, like the order of the output directory, as the order of a dictionary changes between builds.
		for (file, html) in routeTexts.sorted(using: KeyPathComparator(\.key.description, comparator: String.StandardComparator.lexical)) {
			guard
				let pagePath = pagePathsByOutputFile[file],
				// A check of a public file reads every page, but checks the headings only of the pages of the given files.
				!checksPublicFiles || isCheckedPage(file)
			else {
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
					let text = String(match.output.2).replacing(htmlTag, with: "").decodingHTMLEscapes.trimmingCharacters(in: .whitespacesAndNewlines)
					let document = document(at: pagePath)

					// The line of the heading in the content file, or else the page, as the output directory can be anywhere, and the heading can be of the page, not of its content.
					let location: SiteKit.SourceLocation = if
						let document,
						let line = document.markdown.headings.first(where: { $0.level == HeadingLevel(rawValue: level) && $0.text == text })?.line
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

		guard checksPublicFiles else {
			return warnings
		}

		// The public files are copied as they are, so they are read from the project.
		let publicFiles = published.publicFiles
		let publicTexts = publicFiles.filter { isText($0.path.relativePath) }.map { (try? String(contentsOf: $0.source, encoding: .utf8)) ?? "" }

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
						let otherPages = paths.filter { $0 != path }.map { "`\($0)`" }.formattedList(.and)
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
	static let gumroadRequirement = Self("Requirement that Gumroad does not agree with")
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
	static let questionKeyword = Self("Keyword of a question that does nothing")
	static let copiedAnswerBlock = Self("Answer block that is in several apps")
	static let promise = Self("Promise in an answer")
	static let trackingParameter = Self("Tracking parameter")
	static let insecureLink = Self("Link with `http://`")
	static let dropboxPreviewLink = Self("Dropbox link to the preview page")
	static let downloadVersion = Self("Version that is not in the name of its download")
	static let downloadOfOtherApp = Self("Download with the name of another app")
	static let trialRequirement = Self("Trial requirement")
	static let requirement = Self("Requirement")
	static let vagueLinkText = Self("Vague link text")
	static let absoluteSiteLink = Self("Link to the site that is not a site path")
	static let headingLinkWithoutID = Self("Link to a heading without a custom ID")
	static let unknownFeedbackProduct = Self("Feedback link with an unknown app")
	static let unknownFeedbackParameter = Self("Feedback link with an unknown parameter or referrer")
	static let remoteImageWithoutSize = Self("Remote image without a size")
	static let imageWithoutAspectRatio = Self("Image without an aspect ratio")
	static let rawKeyboardShortcut = Self("Keyboard shortcut with `<kbd>`")
	static let rawPlatformBadge = Self("Platform with `<sup>`")
	static let plainTextShortcut = Self("Keyboard shortcut as plain text")
	static let rawLink = Self("Link with `<a>`")
	static let modifierGlyph = Self("Modifier glyph")
	static let straightQuotes = Self("Straight quotes")
	static let footnote = Self("Footnote")
	static let rawScriptOrStyle = Self("Script or style in the content")
	static let localizedAppleLink = Self("Apple link with a locale")
	static let blockInParagraph = Self("Block element in a paragraph")
	static let ignoredContentFile = Self("Content file that the build leaves out")
	static let folderWithoutPage = Self("Content folder without a page")
	static let repeatedWord = Self("Repeated word")
	static let unknownWord = Self("Unknown word")
	static let skippedHeadingLevel = Self("Skipped heading level")
	static let unusedPublicFile = Self("Unused public file")
	static let duplicateTitle = Self("Title of several pages")
	static let duplicateDescription = Self("Description of several pages")
	static let removedPage = Self("Published page without a page or redirect")
	static let unusedSharedQuestion = Self("Shared question that no app picks")
	static let rawMarkdown = Self("Markdown that shows as text")
	static let todo = Self("TODO in a published page")
	static let absoluteBundleLink = Self("Link to a file of the page bundle that is not relative")
	static let lineBreakSpacer = Self("Line break as a spacer")
	static let pastScheduledBlock = Self("`@Scheduled` block whose last day is over")
}

extension MarkdownFile {
	/**
	The warning of a TODO note in a comment, like “TODO: Update”, in the body or in the frontmatter.
	*/
	fileprivate func todoWarning(note: some StringProtocol, line: SiteKit.SourceLocation.Line?) -> Warning {
		warning(.todo, line: line, "The published page has the note “\(note)”. Resolve it, or make the page a draft (`isDraft: true`) until it is resolved.")
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

extension Markdown.Text {
	/**
	Whether the text is directly after a raw `<kbd>` tag, like `⌘C` in `<kbd>⌘C</kbd>`.
	*/
	fileprivate var isAfterKeyboardTag: Bool {
		(previousSibling as? InlineHTML)?.rawHTML == "<kbd>"
	}
}

extension String {
	/**
	Whether the string is a link to Apple’s support pages or the App Store with a locale or storefront in the path, like `https://support.apple.com/en-us/102426` and `https://apps.apple.com/us/app/…`. Without it, Apple shows the page in the language of the visitor and their storefront.
	*/
	var isLocalizedAppleLink: Bool {
		wholeMatch(of: Self.localizedAppleLink) != nil
	}

	nonisolated(unsafe) private static let localizedAppleLink = /https?:\/\/(?:support|apps)\.apple\.com\/(?:[a-z]{2}-[a-z]{2}|[a-z]{2})\/[^\s)\]"'>]*/
}
