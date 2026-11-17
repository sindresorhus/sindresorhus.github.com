import Elementary
import Foundation
import SiteKit

/**
A list of my open-source projects that many people use, in groups, with links to my GitHub profile, all the repos, and the feed of new repos, and the GitHub contributions of the last year, and below the groups, all my npm packages. The list is picked by hand and changes rarely, so its cards have no numbers that go stale, like stars. The numbers below the introduction, the contributions, and the npm packages come from GitHub and npm at each build, like on the about page and the now page, and the large numbers are rounded down, so they change the page less often. The about page has the most popular repos with their stars.
*/
struct OpenSourcePage: Page {
	let content: SiteContent

	var path: RoutePath {
		.openSource
	}

	var metadata: PageMetadata {
		PageMetadata(
			title: "Open Source",
			description: "Open-source projects by Sindre Sorhus that many people use, from Node.js libraries and command-line tools to code quality tools and Swift packages.",
			feeds: [SiteFeed.newRepositories.link]
		)
	}

	var searchKeywords: [String] {
		["npm", "GitHub", "packages"]
	}

	/**
	The contributions of the last year, like on the page. Without them, like without a GitHub token, the card has the photo, like other pages.
	*/
	var socialImage: SocialImage {
		guard let contributions = content.recentActivity.profile?.contributions else {
			return .card(OpenGraphCard(page: self, project: content.project))
		}

		return .card(OpenGraphCard(page: self, artwork: .calendars(of: [contributions.days], scale: content.contributionScale)))
	}

	/**
	Marks the page when the script of the npm list does not load, so the list shows all the packages, like without JavaScript, and not only the first batch.
	*/
	var head: some HTML {
		ScriptLoadFailure(NPMPackageList.script.path)
	}

	var body: some HTML {
		section {
			// The numbers are close to the introduction, like the numbers below the title of the apps page, so the header and the numbers are one block of the page.
			div {
				PageHeader(title: "Open Source") {
					// Keeps “command-line” on one line, as a phone otherwise breaks it after the hyphen.
					MarkdownTheme.site.headingTextHTML("Some of my projects that many people use, from Node.js libraries and command-line tools to Swift packages for Mac apps. I also started ")
					a(.href(.url(#repository("sindresorhus/awesome").url))) {
						"Awesome"
					}
					", lists of good things about all kinds of topics. My code is part of Node.js itself, Apple’s Books app, the terminal UI of Claude Code and Gemini CLI, and projects of NASA and the BBC. "
					// The about page has the sources.
					a(.href(.path(.about, fragment: "where-my-code-ended-up"))) {
						"See where my code ended up"
					}
					"."
				}
				// The page is wide for the cards, and the introduction has the width of prose, so its lines are not long.
				.style {
					$0.frame(maxWidth: .length(Style.ColumnWidth.prose.maximum))
				}

				StatList(stats: stats)
			}
			.style {
				$0.vstack(spacing: .rootEm(1))
			}

			profile

			// A link to each group, as the page is long.
			ChipNavigation(label: "Groups of projects", links: OpenSourceProject.Group.allCases.map(\.link), scrollsOnPhones: true)
				.style {
					$0.textAlign(.leading)
				}

			for group in OpenSourceProject.Group.allCases {
				let projects = content.openSourceProjects.projects(of: group)

				Section(group.title, id: group.id) {
					p {
						group.summary

						if let relatedLink = group.relatedLink {
							" "
							Link(relatedLink)
							"."
						}
					}
					.style(Styles.groupSummary)

					// Keep the list semantics in Safari, as the styles remove its bullets.
					ul(.role(.list)) {
						for project in projects {
							ProjectCard(project: project)
						}
					}
					.style(projects.count == 3 ? Styles.gridOfThree : Styles.grid)
					.style {
						$0.from(.laptop) {
							$0.gridColumns(min(projects.count, 4))
						}
					}
				}
			}

			// Without the npm search, like without the network, there is no list.
			if let packages = content.npmStatistics.listedPackages?.nilIfEmpty {
				Section("All npm Packages", id: ElementID("npm-packages")) {
					p {
						Self.npmPackagesSummary(count: packages.count)
					}
					.style(Styles.groupSummary)

					NPMPackageList(packages: packages)
				}
			}
		}
		.style {
			$0.pageColumn(.page)
		}
	}

	/**
	The numbers of the open-source work, like on the about page, which has them all: the years, the repos and their stars, and the weekly downloads and the dependents of the npm packages. A number that the build could not get is left out.
	*/
	private var stats: [String] {
		let account = content.gitHubAccount
		let npm = content.npmStatistics

		return [
			"\(content.yearsOfOpenSource.formatted(counting: "year")) of open source",
			account.map { $0.repositoryCount.approximateCount(counting: "repo") },
			account.map { $0.starCount.approximateCount(counting: "star") },
			npm.weeklyDownloads.map { "\($0.approximateCount(counting: "npm download")) a week" },
			npm.dependentCount.map { $0.approximateCount(counting: "dependent") },
		].compactMap(\.self)
	}

	/**
	My GitHub profile, which stands out, as it has all the projects, not only these, with the contributions of the last year below it, like on GitHub. Without a GitHub token, the build has no contributions, so the card only has the profile.
	*/
	private var profile: some HTML<HTMLTag.div> {
		div {
			div {
				img(
					.src(Site.author.smallPhotoPath),
					.alt(""),
					.width(64),
					.height(64)
				)
					.style {
						$0.cornerRadius(.circle)
					}

				div {
					p {
						Site.name
					}
					.style {
						$0
							.margin(.zero)
							.textStyle(.headline)
							.color(.primaryText)
					}

					p(.notTranslated) {
						"github.com/\(GitHub.account)"
					}
					.style {
						$0
							.margin(.zero)
							.secondaryText()
							.overflowWrap(.anywhere)
					}
				}
				// At most the width of the card, like on a phone with large text.
				.style {
					$0
						.flex(1)
						.frame(minWidth: .length(.min(.rootEm(10), .percent(100))))
				}

				div {
					Link(destination: .url(Site.author.gitHubURL)) {
						Label("GitHub Profile", icon: .github)
					}
					.buttonStyle()

					Link(destination: .url(Self.allRepositoriesURL)) {
						"All Repos"
					}
					.buttonStyle(.secondary)

					Link(destination: .path(SiteFeed.newRepositories.path)) {
						Label("New Repos Feed", icon: .rss)
					}
					.buttonStyle(.secondary)
				}
				// On phones, the buttons are rows of one width, so their edges line up.
				.style {
					$0
						.hstack(alignment: .center, spacing: .rootEm(0.75))
						.flexWrap()
						.below(.smallTablet) {
							$0
								.flexDirection(.column)
								.alignItems(.stretch)
								.frame(width: .percent(100))
						}
				}
			}
			// The photo and the name next to the buttons on wide screens, and above them on phones.
			.style {
				$0
					.hstack(alignment: .center, spacing: .rootEm(1.25))
					.flexWrap()
			}

			if let contributions = content.recentActivity.profile?.contributions {
				ContributionHeatmap(calendar: contributions, scale: content.contributionScale)

				// The heatmap is hidden from screen readers, so the numbers are text too.
				p {
					"\(contributions.totalCount.formatted(counting: "contribution")) on GitHub in the last year."

					// The quilt is only built with a GitHub token.
					if !content.contributionYears.isEmpty {
						" See every year in the "
						a(.href(.careerQuilt)) {
							"Career Quilt"
						}
						"."
					}
				}
				// The link has the look of the links in text, like the same sentence on the now page, which is in the prose.
				.style {
					$0
						.margin(.zero)
						.secondaryText()
						.textLinks()
				}
			}
		}
		// Less padding on a phone with large text, so the buttons fit.
		.style {
			$0
				.vstack(spacing: .rootEm(1.25))
				.padding(.min(.rootEm(1.5), .viewportWidth(7.5)))
				.cardSurface(isInteractive: false)
		}
	}

	/**
	The repos of my account and the organizations of my projects that are not archived.
	*/
	private static let allRepositoriesURL = #URL("https://github.com/search").appending(queryItems: [
		URLQueryItem(name: "q", value: "\(GitHub.ownerQualifiers) archived:false"),
		URLQueryItem(name: "type", value: "repositories"),
	])

	/**
	A card that links to the repo of a project, with its name, the repo below the name when it is not of my account, like `chalk/chalk`, as the owner is then news, what it does, and its language. The glow of the card and the dot of the language have the color of the language.

	The name is a heading with the link, which covers the whole card, like on an app card (``AppCard``), so the link has a short name, like “Got”, not the text of the whole card, and screen readers can move from project to project by the headings.
	*/
	private struct ProjectCard: HTML {
		let project: OpenSourceProject

		var body: some HTML<HTMLTag.li> {
			li {
				// The card is inside the item, as the list resets the padding of its items.
				div {
					h3 {
						a(.href(.url(project.repository.url))) {
							project.name
						}
						.style(Styles.link)
					}
					.style(Styles.name)

					// Below the name, like the owner and the name of a repo on GitHub, as it is part of what the project is.
					if !project.repository.isOfAccount {
						// It can break after the slash, so a long name, like `SimpleColorPaletteSwift`, stays whole in a narrow card.
						p(.notTranslated) {
							"\(project.repository.owner)/"
							wbr()
							project.repository.name
						}
						.style(Styles.repository)
					}

					// Each word with a hyphen on one line, like “promise-returning”, as the balanced lines would often break at the hyphen.
					p {
						MarkdownTheme.site.headingTextHTML(project.summary)
					}
					.style(Styles.summary)

					// A project without a language, like an Awesome list, has none.
					if let language = project.language {
						span {
							language.rawValue
						}
						.style(Styles.language)
					}
				}
				.tint(project.language?.color ?? .gray(500))
				.style(Styles.card)
			}
		}
	}
}

extension OpenSourcePage {
	/**
	The text below the heading of the list of all the npm packages, on the page and in its Markdown copy.
	*/
	private static func npmPackagesSummary(count: Int) -> String {
		"The \(count.formatted(counting: "package")) with a repository that I maintain on npm, most downloaded first."
	}

	/**
	The projects of the page as Markdown, grouped like on the page, and all the npm packages, in the order of the list of the page, for `llms-full.txt`, so an assistant also finds a package by what it does.
	*/
	var plainMarkdown: String {
		var sections = OpenSourceProject.Group.allCases.map { group in
			let projects = content.openSourceProjects.projects(of: group).map { project in
				"- \(project.repository.url.markdownLink(project.name)): \(project.summary.escapingHTMLTags)\(project.language.map { " (\($0.rawValue))" } ?? "")"
			}

			return "## \(group.title)\n\n\(group.summary)\n\n\(projects.joined(separator: "\n"))"
		}

		// Like on the page, without the npm search there is no list.
		if let packages = content.npmStatistics.listedPackages?.nilIfEmpty {
			let lines = NPMPackageList(packages: packages).packages.map { package in
				let details = [package.description?.escapingHTMLTags, package.weeklyDownloadsLabel.map { "(\($0))" }].compactMap(\.self).joined(separator: " ")
				return "- \(package.url.markdownLink(package.name))\(details.isEmpty ? "" : ": \(details)")"
			}

			sections.append("## All npm Packages\n\n\(Self.npmPackagesSummary(count: packages.count))\n\n\(lines.joined(separator: "\n"))")
		}

		return "# \(metadata.title)\n\nURL: \(path.absoluteURL.absoluteString)\n\n\(metadata.description ?? "")\n\n\(sections.joined(separator: "\n\n"))"
	}
}

extension String {
	/**
	The text for Markdown with each `<` escaped, so a tag in it, like the `<img>` of “Parse and stringify the HTML <img> srcset attribute”, is text, not raw HTML that a renderer shows as an image.
	*/
	fileprivate var escapingHTMLTags: String {
		replacing("<", with: "\\<")
	}
}

extension OpenSourcePage {
	enum Styles: String, StyleSet {
		case groupSummary
		case grid
		case gridOfThree
		case card
		case name
		case link
		case summary
		case language
		case repository

		var style: Style {
			switch self {
			case .groupSummary:
				// Close to the title above it.
				Style()
					.margin(top: .rootEm(-0.75), horizontal: .zero, bottom: .rootEm(1.25))
					.secondaryText(.body)
					.textLinks()
			case .grid:
				// Columns that the groups of four or eight projects fill, without a project alone in a row.
				Style()
					.projectGrid()
					.from(.smallTablet) {
						$0.gridColumns(2)
					}
			case .gridOfThree:
				// A group of three projects, like Mac Tools, in one row where the cards are wide enough, so no project is alone in a row and no slot is empty.
				Style()
					.projectGrid()
					.from(.tablet) {
						$0.gridColumns(3)
					}
			case .card:
				Style()
					.position(.relative)
					.vstack(spacing: .rootEm(0.375))
					.frame(height: .percent(100))
					// Less padding in a narrow card with large text, so the language and the repo fit, and a long name, like `simple-color-palette/SimpleColorPaletteSwift`, breaks.
					.padding(.min(.rootEm(1.25), .viewportWidth(6.25)))
					.overflowWrap(.anywhere)
					.cardSurface()
					// On phones, a row of a list without the surface of a card, as cards in one column add space but no grouping. It still lights up like a card under the pointer and with the keyboard. No space at the sides, so the text starts at the ends of the lines between the rows, where the headings and the npm packages start.
					.below(.smallTablet) {
						$0
							.padding(vertical: .rootEm(1), horizontal: .zero)
							.background(.transparent)
							.shadow([])
					}
			case .name:
				Style()
					.textStyle(.headline)
					.color(.primaryText)
			case .link:
				// It covers the card, so the whole card is the link, but its name is only the name of the project.
				Style().cardCoveringLink()
			case .summary:
				// One to four short lines, balanced, so the last line is not one word alone, like “concurrently.”.
				Style()
					.secondaryText(.body)
					.textWrap(.balance)
			case .language:
				// A dot in the color of the language, like on GitHub. At the bottom of the card, so the languages of the cards in a row line up.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.4))
					.margin(.top, .auto)
					.padding(.top, .rootEm(0.75))
					.secondaryText()
					.fontWeight(.medium)
					.before {
						$0
							.content("")
							// In whole pixels, as a fractional size can snap to an oval.
							.frame(size: .pixels(10))
							.cornerRadius(.circle)
							.background(.pageAccent)
							// Forced colors would remove the background, which is the dot, so it has the text color of forced colors instead.
							.forcedColorAdjust(.none)
							.media(.forcedColors) {
								$0.background(.canvasText)
							}
					}
			case .repository:
				// Close to the name above it.
				Style()
					.margin(top: .rootEm(-0.25), horizontal: .zero, bottom: .zero)
					.secondaryText()
					.fontFamily(.monospace)
			}
		}
	}
}

extension Style {
	/**
	A list of project cards in one column: on phones, rows with thin lines between them, and from small tablets, cards with space between them.
	*/
	fileprivate func projectGrid() -> Self {
		plainList()
			.grid(columns: 1)
			.below(.smallTablet) {
				$0.children("* + *") {
					$0.border(.top, .separator)
				}
			}
			.from(.smallTablet) {
				$0.gap(.cardSpacing)
			}
	}
}

/**
An open-source project on the Open Source page, from `content/open-source.soml` (``OpenSourceCatalog``).
*/
@Frontmatter
struct OpenSourceProject {
	/**
	The main language of the code of a project, as GitHub shows it. A project without code, like a list or a spec, has none.
	*/
	enum Language: String, ContentEnum {
		case javaScript = "JavaScript"
		case typeScript = "TypeScript"
		case swift = "Swift"
		case shell = "Shell"
		case css = "CSS"

		/**
		Close to the colors of the languages on GitHub, so the dots look familiar.
		*/
		var color: Color {
			switch self {
			case .javaScript:
				.amber(400)
			case .typeScript:
				.primary(600)
			case .swift:
				.red(500)
			case .shell:
				.emerald(400)
			case .css:
				.violet(500)
			}
		}
	}

	/**
	A group of projects on the page, in the order of the page. The raw value is the ID of its section, which the links at the top of the page point to, and the key of its projects in `content/open-source.soml` (``OpenSourceCatalog``).

	A group has two or three projects, or a multiple of four, so the cards fill the rows of the grid (``OpenSourceCatalog/validate(into:)``).

	The page has no Electron projects, like `electron-store`, as Sindre does not want them on it.
	*/
	enum Group: String, CaseIterable {
		case http
		case promises
		case commandLineTools = "command-line-tools"
		case commandLineApps = "command-line-apps"
		case files
		case system
		case text
		case objects
		case web
		case images
		case linting
		case testing
		case fileFormats = "file-formats"
		case swift
		case mac
		case apps
		case lists
		case fun

		/**
		A page of the site about the projects of the group, as a sentence after its summary, like the apps for developers after the apps on GitHub, for a developer who comes for the packages.
		*/
		var relatedLink: LabeledLink? {
			self == .apps ? LabeledLink("See my apps for developers", path: AppCategory.developerTools.path) : nil
		}

		/**
		The ID of the section of the group, which the chips at the top of the page point to.
		*/
		var id: ElementID {
			ElementID(rawValue)
		}

		/**
		The chip at the top of the page that goes to the group.
		*/
		var link: LabeledLink {
			LabeledLink(title, destination: .fragment(id))
		}

		var title: String {
			switch self {
			case .http:
				"HTTP"
			case .promises:
				"Promises and Async"
			case .commandLineTools:
				"Command-Line Tools"
			case .commandLineApps:
				"Making Command-Line Apps"
			case .files:
				"Files"
			case .system:
				"Processes and the System"
			case .text:
				"Strings and Formatting"
			case .objects:
				"Objects and Caches"
			case .web:
				"The Web"
			case .images:
				"Images and Screenshots"
			case .linting:
				"Linting"
			case .testing:
				"Testing and Types"
			case .fileFormats:
				"File Formats"
			case .swift:
				"Swift Packages"
			case .mac:
				"Mac Tools"
			case .apps:
				"Apps"
			case .lists:
				"Awesome Lists"
			case .fun:
				"Just for Fun"
			}
		}

		/**
		What the projects of the group are, in one line below its title.
		*/
		var summary: String {
			switch self {
			case .http:
				"Requests and connections, in Node.js and the browser."
			case .promises:
				"Small packages for async code in JavaScript."
			case .commandLineTools:
				"Tools to use in the terminal."
			case .commandLineApps:
				"Colors, spinners, boxes, and text for your own command-line apps."
			case .files:
				"Find, copy, move, and delete files from Node.js."
			case .system:
				"Run processes, open things, and use the clipboard from Node.js."
			case .text:
				"Change strings and show numbers in a format that people can read."
			case .objects:
				"Work with nested objects, cache results, and delay function calls."
			case .web:
				"For web pages: URLs, the clipboard, the DOM, and CSS."
			case .images:
				"Screenshots of websites, and images in code and in the terminal."
			case .linting:
				"Linters and ESLint rules for JavaScript, TypeScript, CSS, and Markdown."
			case .testing:
				"A test runner, and types and checks for JavaScript and TypeScript."
			case .fileFormats:
				"Two file formats that I made, with their specs. Both are drafts. The Swift implementation of SOML is also listed."
			case .swift:
				"Packages for Swift and Mac apps."
			case .mac:
				"Command-line tools and packages for macOS."
			case .apps:
				"My apps on GitHub."
			case .lists:
				"Lists of good things about a topic, like Node.js packages and sci-fi."
			case .fun:
				"Small packages that make code more fun."
			}
		}
	}

	/**
	The name of the project, like “Got”.
	*/
	@PlainText var name: String

	/**
	The repo on GitHub, which the card links to, like `sindresorhus/got`.
	*/
	var repository: GitHubRepositoryName

	/**
	What the project does, in one line, close to the description of the repo.
	*/
	@PlainText var summary: String

	var language: Language?
}

/**
The projects of the open source page, by group, from `content/open-source.soml`, so a changed summary is a change of the content, not of the code. The key of a group in the file is the ID of the group (``OpenSourceProject/Group``), like `command-line-tools`. The groups are in the order of the page by convention, but the page takes its order from the cases of ``OpenSourceProject/Group``, not from the file.

```soml
http: [
	{
		name: 'Got'
		repository: 'sindresorhus/got'
		summary: 'Human-friendly and powerful HTTP requests for Node.js.'
		language: 'TypeScript'
	}
]
```
*/
@Frontmatter
struct OpenSourceCatalog {
	var http = [OpenSourceProject]()
	var promises = [OpenSourceProject]()
	@Key("command-line-tools") var commandLineTools = [OpenSourceProject]()
	@Key("command-line-apps") var commandLineApps = [OpenSourceProject]()
	var files = [OpenSourceProject]()
	var system = [OpenSourceProject]()
	var text = [OpenSourceProject]()
	var objects = [OpenSourceProject]()
	var web = [OpenSourceProject]()
	var images = [OpenSourceProject]()
	var linting = [OpenSourceProject]()
	var testing = [OpenSourceProject]()
	@Key("file-formats") var fileFormats = [OpenSourceProject]()
	var swift = [OpenSourceProject]()
	var mac = [OpenSourceProject]()
	var apps = [OpenSourceProject]()
	var lists = [OpenSourceProject]()
	var fun = [OpenSourceProject]()

	/**
	The path of the file, relative to the root of the project.
	*/
	static let path = "content/open-source.soml"

	/**
	All the projects of the page, in the order of the page.
	*/
	var all: [OpenSourceProject] {
		OpenSourceProject.Group.allCases.flatMap { projects(of: $0) }
	}

	/**
	The projects of the group, in their order in the file.
	*/
	func projects(of group: OpenSourceProject.Group) -> [OpenSourceProject] {
		switch group {
		case .http:
			http
		case .promises:
			promises
		case .commandLineTools:
			commandLineTools
		case .commandLineApps:
			commandLineApps
		case .files:
			files
		case .system:
			system
		case .text:
			text
		case .objects:
			objects
		case .web:
			web
		case .images:
			images
		case .linting:
			linting
		case .testing:
			testing
		case .fileFormats:
			fileFormats
		case .swift:
			swift
		case .mac:
			mac
		case .apps:
			apps
		case .lists:
			lists
		case .fun:
			fun
		}
	}

	/**
	The key of the group in the file, which is the ID of the group.
	*/
	static func key(of group: OpenSourceProject.Group) -> CodingKeys {
		// Each group has its key, as the keys of the properties are the IDs of the groups (`@Key`).
		CodingKeys(rawValue: group.rawValue)!
	}

	func validate(into problems: inout FrontmatterProblems<Self>) {
		for group in OpenSourceProject.Group.allCases {
			let count = projects(of: group).count

			// The cards of a group fill the rows of the grid, which has two or four columns, or three for a group of three. A group of two keeps two columns on wide screens.
			guard !((2...3).contains(count) || (count > 0 && count.isMultiple(of: 4))) else {
				continue
			}

			problems.add("The group has \(count.formatted(counting: "project")), so its cards do not fill the rows of the grid. A group has two or three projects, or a multiple of four.", at: Self.key(of: group))
		}
	}
}

extension OpenSourceCatalog {
	/**
	A catalog without projects, like for content that is made in code.
	*/
	init() {}
}
