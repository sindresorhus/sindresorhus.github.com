import Foundation
import Markdown
import SiteKit

extension App {
	/**
	The headings of an app page that the build adds or finds by their IDs, like the FAQ section, which the links, the feedback page, and the added questions find. A heading that the build adds has the ID of its case, so every lookup is by the ID, not by the title.
	*/
	enum Section: String {
		/**
		The FAQ section, which the page, the links, and the feedback page find by its ID. A level 2 heading with its title must have its ID.
		*/
		case faq

		/**
		The trial section in the file (`## Trial {#trial}`), which the download buttons link to.
		*/
		case trial

		/**
		The “Older Versions” section that the build adds for `olderVersions`.
		*/
		case olderVersions = "older-versions"

		/**
		The “Non-App Store Version” section that the build adds for `nonAppStoreVersion`, which is in the “…” menu instead of the links of the app.
		*/
		case nonAppStoreVersion = "non-app-store-version"

		/**
		The feedback question that every FAQ section gets. A question with its title in the file gets the answer instead.
		*/
		case feedbackQuestion = "feedback"

		/**
		The menu bar question that the build adds to menu bar apps. Its ID is also the ID of the general question that its answer links to (``LinkDestination/menuBarQuestion``). Its answer only links to the general question, so the feedback page suggests the general question instead.
		*/
		case menuBarQuestion = "app-not-showing-in-menu-bar"

		var id: ElementID {
			ElementID(rawValue)
		}

		var title: String {
			switch self {
			case .faq:
				"Frequently Asked Questions"
			case .trial:
				"Trial"
			case .olderVersions:
				"Older Versions"
			case .nonAppStoreVersion:
				"Non-App Store Version"
			case .feedbackQuestion:
				"I have a feature request, bug report, or some feedback"
			case .menuBarQuestion:
				"The app does not show up in the menu bar"
			}
		}

		/**
		The level of the heading: 2 for a section, and 3 for a question of the FAQ section.
		*/
		var level: HeadingLevel {
			switch self {
			case .faq, .trial, .olderVersions, .nonAppStoreVersion:
				.h2
			case .feedbackQuestion, .menuBarQuestion:
				.h3
			}
		}

		/**
		The heading as the build adds it, with the ID.
		*/
		var heading: Markdown.Heading {
			Markdown.Heading(level: level, title, id: id.rawValue)
		}

		/**
		The heading as it is written in a file, like `## Frequently Asked Questions {#faq}`, for a message that says how to write it.
		*/
		var markdown: String {
			"\(String(repeating: "#", count: level.rawValue)) \(title) {#\(id)}"
		}

		/**
		Whether a heading with the level and the ID is the heading of the section, like `## Frequently Asked Questions {#faq}`. The ID is the custom ID of a parsed heading, or the ID of a rendered heading.
		*/
		func isHeading(level: HeadingLevel, id: ElementID?) -> Bool {
			level == self.level && id == self.id
		}

		/**
		Whether a heading of the level ends the section: the next heading of the same level or a lower level, like the next level 2 heading after the FAQ section.
		*/
		func isEnded(byHeadingOfLevel level: HeadingLevel) -> Bool {
			level <= self.level
		}
	}
}

extension LinkDestination {
	/**
	A section of the app page that the link is on, like the trial section.
	*/
	static func section(_ section: App.Section) -> Self {
		.fragment(section.id)
	}
}

extension App.Frontmatter {
	/**
	The Markdown of the app page with what the build adds from the facts of the app: the standard text of a trial without its own (``trialText``), the common questions that apply to it (``CommonQuestion``), the shared questions that it picks, the “Older Versions” and “Non-App Store Version” sections, and, unless the app is archived, the feedback question in the FAQ section.
	*/
	func addingGeneratedSections(to document: Document, sharedQuestions: App.SharedQuestions, page: RoutePath) -> Document {
		var blocks = Array(document.blockChildren.map(addingTrialText(to:)))
		blocks.addCommonQuestions(CommonQuestion.questions(for: self, sharedQuestions: sharedQuestions))

		// An archived app gets no support, and the feedback page does not list it.
		if !isArchived {
			blocks.addFeedbackQuestion(appTitle: title, page: page)
		}

		// Added before the older versions, which ``addOlderVersions(_:isPaid:)`` then inserts above it.
		if let nonAppStoreVersion {
			blocks += nonAppStoreVersion.markdownSection(isOnSeveralPlatforms: platforms.count > 1)
		}

		blocks.addOlderVersions(olderVersions, isPaid: isPaid)
		return Document(blocks)
	}
}

extension App.Frontmatter {
	/**
	The text of the trial of the app, which a `@Trial` without content gets, so every app promises the same trial in the same words. The trial is only for the Mac, so an app on several platforms says “the macOS app”. The data carries over to the purchase on the App Store, for an app that is there.
	*/
	var trialText: String {
		let trial = platforms.count > 1 ? "The trial of the macOS app" : "The trial"
		let store = appStoreID == nil ? "" : " on the App Store"
		return "\(trial) is fully functional. The only limitation is a reminder to buy the app every 12 hours, and no automatic updates. All data and settings carry over if you buy it\(store)."
	}

	/**
	A `@Trial` without content with the text of the trial (``trialText``), or else the block as it is.

	Limitation: Only a trial at the top level of the file, not one inside another directive, like `@Details`, as the trial goes below the “Trial” heading.
	*/
	private func addingTrialText(to block: any BlockMarkup) -> any BlockMarkup {
		guard
			let trial = block as? BlockDirective,
			trial.siteName == .trial,
			trial.childCount == 0
		else {
			return block
		}

		return (trial.withUncheckedChildren([Paragraph(Markdown.Text(trialText))]) as? any BlockMarkup) ?? block
	}
}

extension App.NonAppStoreVersion {
	/**
	The “Non-App Store Version” section of an app page. It says “macOS version” for an app on several platforms, as the version is only for the Mac.
	*/
	func markdownSection(isOnSeveralPlatforms: Bool) -> [any BlockMarkup] {
		[
			App.Section.nonAppStoreVersion.heading,
			Paragraph(Markdown.Text("A special \(isOnSeveralPlatforms ? "macOS " : "")version for users that cannot access the App Store. It won’t receive automatic updates. I will update it here once a year.")),
			Paragraph(
				Markdown.Link(destination: .url(url), text: "Download"),
				Markdown.Text(" "),
				Markdown.Emphasis(Markdown.Text("(\(version))"))
			),
			Paragraph(Markdown.Emphasis(Markdown.Text(OSVersion(major: macOS).requirementSentence(for: [.macOS])))),
		]
	}
}

/**
A question that many apps have, like “Can you localize the app into my language?”, or a shared question that an app picks (``App/SharedQuestions``). The build adds it to the FAQ section of each app that it applies to, so the app files do not repeat it. A file that has a question with the same text in its FAQ section keeps its own answer, like one with more details about the app.
*/
private struct CommonQuestion {
	let title: String

	/**
	The question and its answer, as a level 3 heading and the blocks below it, like the questions in the files.
	*/
	let blocks: [any BlockMarkup]

	/**
	Whether the question goes before the questions of the file instead of after them, as visitors with a problem look for it. The feedback question still goes first.
	*/
	var isFirst = false

	/**
	The questions that apply to the app: the menu bar question for menu bar apps, the free question for free apps on the App Store that are not archived, the shared questions that the app picks, and the localization question for all apps.
	*/
	static func questions(for frontmatter: App.Frontmatter, sharedQuestions: App.SharedQuestions) -> [Self] {
		var questions = [Self]()

		if frontmatter.isMenuBarApp {
			questions.append(
				Self(
					section: .menuBarQuestion,
					answer: Paragraph(Markdown.Link(destination: .menuBarQuestion, text: "How to make the app show up in the menu bar")),
					isFirst: true
				)
			)
		}

		// The answer asks for a review on the App Store, so archived apps and apps that are not there do not get it.
		if
			!frontmatter.isPaid,
			!frontmatter.isArchived,
			frontmatter.appStoreID != nil
		{
			questions.append(
				Self(
					title: "Why is this free without ads?",
					answer: Paragraph(Markdown.Text("I just enjoy making apps. Consider leaving a nice review on the App Store."))
				)
			)
		}

		questions += sharedQuestions.questions

		questions.append(
			Self(
				title: "Can you localize the app into my language?",
				answer: Paragraph(Markdown.Text("I don’t plan to localize the app."))
			)
		)

		return questions
	}
}

extension App {
	/**
	The titles of the questions that the build adds to the FAQ section of the app (``CommonQuestion``). A question in the file with one of these titles replaces the added question, like a menu bar question with a sentence about a setting of the app.
	*/
	var commonQuestionTitles: Set<String> {
		Set(CommonQuestion.questions(for: frontmatter, sharedQuestions: sharedQuestions).map(\.title))
	}
}

extension CommonQuestion {
	/**
	A question with a one-paragraph answer.
	*/
	init(title: String, answer: Paragraph) {
		self.init(title: title, blocks: [Markdown.Heading(level: 3, Markdown.Text(title)), answer])
	}

	/**
	A question that code finds by its ID, with a one-paragraph answer.
	*/
	init(section: App.Section, answer: Paragraph, isFirst: Bool) {
		self.init(title: section.title, blocks: [section.heading, answer], isFirst: isFirst)
	}
}

extension App {
	/**
	The questions that an app picks (`sharedQuestions`) from the questions that some apps share, like how to turn off the suggested filenames when saving, in `content/shared-questions.md`. Each question is a level 3 heading, followed by its answer, like in the FAQ of an app, and the answer is Markdown. An app adds a question to its FAQ section with the ID of its heading in `sharedQuestions`, so each heading has a short ID, like `{#suggested-filenames}`. Text before the first question is not shown, so it can explain the file.

	The answers are shown on the app pages, so their links are site paths, like `/apps/faq#refund`, or URLs, not relative links. The site reads the file once (``Library``), so a mistake in it is reported once, at its line.

	The picked questions go after the questions of the app, but a question with `<!-- @faq.first -->` (``First``) goes before them, like a question about a problem, as visitors with a problem look for it.

	An answer cannot have headings, also not in a block directive, like `@Details`, as the questions are found by their headings, so a heading in an answer is an error.

	Limitation: An answer cannot have inline notes, as their IDs come from their lines, which the added answers do not have, or footnotes, as the parser moves their definitions to the end of the file, which is the last answer.
	*/
	struct SharedQuestions {
		/**
		The path of the file, relative to the root of the project.
		*/
		static let path = "content/shared-questions.md"

		/**
		The question goes before the questions of the app instead of after them, like `<!-- @faq.first -->` below a question about a problem. Only the shared questions have it, as a question of the app goes where it is written.
		*/
		enum First: HeadingDirective {
			static let name = "faq.first"
			typealias Value = HeadingDirectiveFlag
		}

		/**
		The picked questions, in the order of `sharedQuestions`. The file is the source of their Markdown, so they have no lines in the app page.
		*/
		fileprivate let questions: [CommonQuestion]

		/**
		The questions that the app picks from the questions of the file. An ID that is not the ID of a question is an error at the `sharedQuestions` key. The frontmatter rejects an ID that is picked twice (``App/Frontmatter/validate(into:)``).
		*/
		init(pickedBy file: MarkdownFile, frontmatter: Frontmatter, from library: Library) throws {
			self.questions = try frontmatter.sharedQuestions.enumerated().map { index, id in
				guard let question = library.questionsByID[id] else {
					throw file.error(at: Frontmatter.CodingKeys.sharedQuestions, index: index, "`sharedQuestions` has `\(id)`, which is not the ID of a question in `\(Self.path)`.")
				}

				return question
			}
		}

		/**
		All the questions of the file, which the site loads once for all the apps, so a mistake in the file is reported once, at its line.
		*/
		struct Library: Sendable {
			/**
			The questions by the IDs of their headings.
			*/
			fileprivate let questionsByID: [ElementID: CommonQuestion]

			/**
			The file, like for the checks of `website check`. `nil` when the project has no file.
			*/
			let file: MarkdownFile?

			/**
			Reads the file and throws all its mistakes, with their lines. A project without the file has no shared questions.
			*/
			init(project: Project) throws(ContentErrors) {
				let url = project.root.appending(path: App.SharedQuestions.path)

				guard url.isFile else {
					self = .empty
					return
				}

				do {
					let file = try MarkdownFile(url: url)
					self.questionsByID = try App.SharedQuestions.questionsByID(file: file, project: project)
					self.file = file
				} catch {
					throw ContentErrors(converting: error, file: url)
				}
			}

			private init(questionsByID: [ElementID: CommonQuestion], file: MarkdownFile?) {
				self.questionsByID = questionsByID
				self.file = file
			}

			/**
			No questions, for an app that picks none, so it does not read the file.
			*/
			static let empty = Self(questionsByID: [:], file: nil)
		}

		/**
		All the questions of the file, by the IDs of their headings.
		*/
		private static func questionsByID(file: MarkdownFile, project: Project) throws -> [ElementID: CommonQuestion] {
			var options = MarkdownDocument.Options.content(file, project: project)
			options.headingDirectives.append(First.self)
			let document = Document(parsing: file.body, file: file.url, options: options)
			let headings = try MarkdownDocument(rendering: document, of: file, options: options).headings

			// Each question is a top-level heading and the blocks up to the next one, by the line of the heading.
			var sectionsByLine = [Int: [any BlockMarkup]]()
			var sectionLine: Int?

			for block in document.blockChildren {
				if block is Markdown.Heading {
					sectionLine = file.line(of: block)
				}

				if let sectionLine {
					sectionsByLine[sectionLine, default: []].append(block)
				}
			}

			var questionsByID = [ElementID: CommonQuestion]()
			var titles = Set<String>()
			var errors = [ContentError]()

			for heading in headings {
				guard heading.level == .h3 else {
					errors.append(file.error(line: heading.line, heading.level > .h3 ? "An answer cannot have headings: `\(heading.text)`." : "The questions are level 3 headings: `### \(heading.text)`."))
					continue
				}

				// A heading in a block directive is not the heading of a question, so it would silently give the questions after it the wrong answers.
				guard
					let line = heading.line,
					let blocks = sectionsByLine[line]
				else {
					errors.append(file.error(line: heading.line, "An answer cannot have headings, also not in a block directive."))
					continue
				}

				// An app that picks both would show the question twice, and the feedback page would suggest it twice.
				guard titles.insert(heading.text).inserted else {
					errors.append(file.error(line: heading.line, "The question “\(heading.text)” is in the file twice. Keep one, and pick it with its ID."))
					continue
				}

				// The blocks start with the heading, and a directive below it, like `<!-- @faq.first -->`, is not an answer.
				guard blocks.dropFirst().contains(where: { !$0.isCommentOnly }) else {
					errors.append(file.error(line: heading.line, "The question “\(heading.text)” has no answer. Write it below the heading."))
					continue
				}

				// The IDs are unique, as the parse of the file reports a heading ID that is used twice.
				questionsByID[heading.id] = CommonQuestion(title: heading.text, blocks: blocks, isFirst: heading.contains(First.self))
			}

			guard errors.isEmpty else {
				throw ContentErrors(errors)
			}

			return questionsByID
		}
	}
}

// swift-markdown does not mark its nodes as `Sendable`, but they are immutable values: a node only reads its tree, and a change to a node makes a new tree. The only mutable state is the source ranges, which the parser sets while it parses, before the nodes get here. So the questions can be used on other threads, like the shared questions in the `rewrite` closure of the app page, which must be `@Sendable`. Check this again when swift-markdown is updated.
extension CommonQuestion: @unchecked Sendable {}

extension [any BlockMarkup] {
	/**
	The blocks of the FAQ section of an app page, after its heading. `nil` when the page has no FAQ section.
	*/
	fileprivate var faqSection: Range<Int>? {
		guard let headingIndex = firstIndex(of: .faq) else {
			return nil
		}

		let content = contentOfSection(afterHeadingAt: headingIndex, level: App.Section.faq.level) { block in
			(block as? Markdown.Heading).flatMap { HeadingLevel(rawValue: $0.level) }
		}

		return content.startIndex..<content.endIndex
	}

	/**
	Where the questions of the FAQ section start: at its first heading, after any text under the FAQ heading.
	*/
	fileprivate func faqQuestionsStart(in section: Range<Int>) -> Int {
		self[section].firstIndex { $0 is Markdown.Heading } ?? section.upperBound
	}

	/**
	Adds the common questions that the FAQ section does not have yet: the first ones before the other questions, and the rest after them.
	*/
	fileprivate mutating func addCommonQuestions(_ questions: [CommonQuestion]) {
		guard let section = faqSection else {
			return
		}

		let questionsStart = faqQuestionsStart(in: section)
		let existingTitles = Set(self[section].compactMap { ($0 as? Markdown.Heading)?.title })
		let newQuestions = questions.filter { !existingTitles.contains($0.title) }
		// The later position first, so the earlier one stays the same.
		insert(contentsOf: newQuestions.filter { !$0.isFirst }.flatMap(\.blocks), at: section.upperBound)
		insert(contentsOf: newQuestions.filter(\.isFirst).flatMap(\.blocks), at: questionsStart)
	}

	/**
	Adds the feedback question to the FAQ section, or adds the answer to an existing question with the same title.
	*/
	fileprivate mutating func addFeedbackQuestion(appTitle: String, page: RoutePath) {
		guard let section = faqSection else {
			return
		}

		let answer = Paragraph(
			Markdown.Text("Click the feedback button in the app or "),
			Markdown.Link(destination: .url(App.feedbackURL(appTitle: appTitle, referrer: .faq).absoluteURL(on: page)), text: "send it here.")
		)

		let question = App.Section.feedbackQuestion

		if
			let questionIndex = self[section].firstIndex(where: { block in
				guard let heading = block as? Markdown.Heading else {
					return false
				}

				return heading.level == question.level.rawValue && heading.title == question.title
			}),
			var heading = self[questionIndex] as? Markdown.Heading
		{
			// The question gets the feedback ID instead of its own. Its title is plain text, as it is the same as the plain title. The heading is changed, not replaced, so it keeps its line, where the answer of the question above it ends (``App/faqAnswerLines(of:)``).
			heading.setTitle(question.title, id: question.id.rawValue)
			self[questionIndex] = heading

			// After the directives of the question, which must be directly below it.
			let answerIndex = self[(questionIndex + 1)...].firstIndex { ($0 as? HTMLBlock)?.isOnlyDirectives != true } ?? endIndex
			insert(answer, at: answerIndex)
		} else {
			insert(contentsOf: [question.heading, answer] as [any BlockMarkup], at: faqQuestionsStart(in: section))
		}
	}

	/**
	Adds the “Older Versions” section before the “Non-App Store Version” section, or at the end.
	*/
	fileprivate mutating func addOlderVersions(_ olderVersions: [App.OlderVersion], isPaid: Bool) {
		guard !olderVersions.isEmpty else {
			return
		}

		insert(contentsOf: olderVersions.markdownSection(isPaid: isPaid), at: firstIndex(of: .nonAppStoreVersion) ?? endIndex)
	}

	/**
	The index of the heading of the section, by its level and its ID.
	*/
	private func firstIndex(of section: App.Section) -> Int? {
		firstIndex { block in
			guard let heading = block as? Markdown.Heading else {
				return false
			}

			return heading.level == section.level.rawValue && heading.customID == section.id.rawValue
		}
	}
}

extension [App.OlderVersion] {
	/**
	The “Older Versions” section of an app page.

	The versions of paid apps are free, but they only run on their macOS version, so they do not say “or later” (`+`).
	*/
	func markdownSection(isPaid: Bool) -> [any BlockMarkup] {
		let items = map { olderVersion in
			ListItem(
				Paragraph(
					Markdown.Link(destination: .url(olderVersion.url), text: olderVersion.version),
					Markdown.Text(" for macOS \(olderVersion.macOS.rawValue)\(isPaid ? "" : "+")")
				)
			)
		}

		var section: [any BlockMarkup] = [
			App.Section.olderVersions.heading,
			UnorderedList(items),
		]

		if isPaid {
			section.append(Paragraph(Markdown.Text("These are free for everyone but they will not run on newer macOS versions.")))
		}

		return section
	}
}
