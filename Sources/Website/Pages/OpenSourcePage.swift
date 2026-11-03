import Elementary
import Foundation
import SiteKit

/**
A list of my open-source projects that many people use, in groups, with links to my GitHub profile, all the repos, and the feed of new repos, and the GitHub contributions of the last year. The list is picked by hand and changes rarely, so it has no numbers that go stale, like stars. The contributions come from GitHub at each build, like on the now page. The about page has the most popular repos with their stars.
*/
struct OpenSourcePage: Page {
	let content: SiteContent

	var path: RoutePath {
		.openSource
	}

	var metadata: PageMetadata {
		PageMetadata(title: "Open Source", description: "Open-source projects by Sindre Sorhus that many people use, from Node.js libraries and command-line tools to code quality tools and Swift packages.")
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

	var body: some HTML {
		section {
			PageHeader(title: "Open Source") {
				"Some of my projects that many people use, from Node.js libraries and command-line tools to Swift packages for Mac apps. I also started "
				a(.href(.url(#repository("sindresorhus/awesome").url))) {
					"Awesome"
				}
				", lists of good things about all kinds of topics."
			}
			// The page is wide for the cards, and the introduction has the width of prose, so its lines are not long.
			.style {
				$0.frame(maxWidth: .length(Style.ColumnWidth.prose.maximum))
			}

			profile

			// A link to each group, as the page is long.
			ChipNavigation(label: "Groups of projects", links: OpenSourceProject.Group.allCases.map(\.link), scrollsOnPhones: true)
				.style {
					$0.justifyContent(.start)
				}

			for group in OpenSourceProject.Group.allCases {
				Section(group.title, id: ElementID(group.rawValue)) {
					p {
						group.summary
					}
					.style(Styles.groupSummary)

					ul {
						for project in group.projects {
							ProjectCard(project: project)
						}
					}
					.style(group.projects.count == 3 ? Styles.gridOfThree : Styles.grid)
				}
			}
		}
		.style {
			$0.pageColumn(.page)
		}
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
				.style {
					$0
						.hstack(alignment: .center, spacing: .rootEm(0.75))
						.flexWrap()
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
	A card that links to the repo of a project, with its name, what it does, its language, and the repo when it is not of my account, like `chalk/chalk`, as the owner is then news. The glow of the card and the dot of the language have the color of the language.

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

					p {
						project.summary
					}
					.style(Styles.summary)

					// A project of my account without a language, like an Awesome list, has no details.
					if project.language != nil || !project.repository.isOfAccount {
						div {
							if let language = project.language {
								span {
									language.rawValue
								}
								.style(Styles.language)
							}

							if !project.repository.isOfAccount {
								// It can break after the slash, so a long name, like `SimpleColorPaletteSwift`, stays whole in a narrow card.
								span(.notTranslated) {
									"\(project.repository.owner)/"
									wbr()
									project.repository.name
								}
								.style(Styles.repository)
							}
						}
						.style(Styles.details)
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
	The projects of the page as Markdown, grouped like on the page, for `llms-full.txt`.
	*/
	var plainMarkdown: String {
		let groups = OpenSourceProject.Group.allCases.map { group in
			let projects = group.projects.map { project in
				"- [\(project.name)](\(project.repository.url.absoluteString)): \(project.summary)\(project.language.map { " (\($0.rawValue))" } ?? "")"
			}

			return "## \(group.title)\n\n\(group.summary)\n\n\(projects.joined(separator: "\n"))"
		}

		return "# \(metadata.title)\n\nURL: \(path.absoluteURL.absoluteString)\n\n\(metadata.description ?? "")\n\n\(groups.joined(separator: "\n\n"))"
	}
}

extension OpenSourcePage {
	enum Styles: StyleSet {
		case groupSummary
		case grid
		case gridOfThree
		case card
		case name
		case link
		case summary
		case details
		case language
		case repository

		var style: Style {
			switch self {
			case .groupSummary:
				// Close to the title above it.
				Style()
					.margin(top: .rootEm(-0.75), horizontal: .zero, bottom: .rootEm(1.25))
					.secondaryText(.body)
			case .grid:
				// Columns that the groups of four or eight projects fill, without a project alone in a row.
				Style()
					.plainList()
					.display(.grid)
					.gridColumns(1)
					.gap(.rootEm(1))
					.from(.smallTablet) {
						$0.gridColumns(2)
					}
					.from(.desktop) {
						$0.gridColumns(4)
					}
			case .gridOfThree:
				// A group of three projects, like the apps, in one row where the cards are wide enough, so no project is alone in a row and no slot is empty.
				Style()
					.plainList()
					.display(.grid)
					.gridColumns(1)
					.gap(.rootEm(1))
					.from(.tablet) {
						$0.gridColumns(3)
					}
			case .card:
				Style()
					.position(.relative)
					.vstack(spacing: .rootEm(0.375))
					.frame(height: .percent(100))
					// Less padding on a phone with large text, so the language and the repo fit, and a long name, like `simple-color-palette/SimpleColorPaletteSwift`, breaks.
					.padding(.min(.rootEm(1.25), .viewportWidth(6.25)))
					.overflowWrap(.anywhere)
					.cardSurface()
			case .name:
				Style()
					.textStyle(.headline)
					.color(.primaryText)
			case .link:
				// It covers the card, so the whole card is the link, but its name is only the name of the project.
				Style()
					.inherits(.color)
					.underline(false)
					.after {
						$0
							.content("")
							.position(.absolute)
							.inset(.zero)
							.cornerRadius(.cardRadius)
					}
			case .summary:
				Style()
					.secondaryText(.body)
					.textWrap(.pretty)
			case .details:
				// At the bottom of the card, so the details of the cards in a row line up. The repo is below the language, as a long repo, like `simple-color-palette/SimpleColorPaletteSwift`, does not fit next to it in a narrow card.
				Style()
					.vstack(alignment: .start, spacing: .rootEm(0.25))
					.margin(.top, .auto)
					.padding(.top, .rootEm(0.75))
					.textStyle(.caption)
					.color(.secondaryText)
			case .language:
				// A dot in the color of the language, like on GitHub.
				Style()
					.hstack(alignment: .center, spacing: .rootEm(0.4))
					.fontWeight(.medium)
					.before {
						$0
							.content("")
							.frame(size: .rootEm(0.625))
							.cornerRadius(.circle)
							.background(.pageAccent)
							// Forced colors would remove the background, which is the dot, so it has the text color of forced colors instead.
							.forcedColorAdjust(.none)
							.media(.forcedColors) {
								$0.background(.canvasText)
							}
					}
			case .repository:
				Style()
					.fontFamily(.monospace)
					.font(size: .em(0.9))
			}
		}
	}
}

/**
An open-source project on the Open Source page.
*/
struct OpenSourceProject {
	/**
	The main language of the code of a project, as GitHub shows it. A project without code, like a list or a spec, has none.
	*/
	enum Language: String {
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
	A group of projects on the page, in the order of the page. The raw value is the ID of its section, which the links at the top of the page point to.

	A group has three projects, or a multiple of four, so the cards fill the rows of the grid.

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
		The chip at the top of the page that goes to the group.
		*/
		var link: LabeledLink {
			LabeledLink(title, destination: .fragment(rawValue))
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

		/**
		The projects of the group, in their order in the catalog.
		*/
		var projects: [OpenSourceProject] {
			switch self {
			case .http:
				OpenSourceProject.httpProjects
			case .promises:
				OpenSourceProject.promisesProjects
			case .commandLineTools:
				OpenSourceProject.commandLineToolsProjects
			case .commandLineApps:
				OpenSourceProject.commandLineAppsProjects
			case .files:
				OpenSourceProject.filesProjects
			case .system:
				OpenSourceProject.systemProjects
			case .text:
				OpenSourceProject.textProjects
			case .objects:
				OpenSourceProject.objectsProjects
			case .web:
				OpenSourceProject.webProjects
			case .images:
				OpenSourceProject.imagesProjects
			case .linting:
				OpenSourceProject.lintingProjects
			case .testing:
				OpenSourceProject.testingProjects
			case .fileFormats:
				OpenSourceProject.fileFormatsProjects
			case .swift:
				OpenSourceProject.swiftProjects
			case .mac:
				OpenSourceProject.macProjects
			case .apps:
				OpenSourceProject.appsProjects
			case .lists:
				OpenSourceProject.listsProjects
			case .fun:
				OpenSourceProject.funProjects
			}
		}
	}

	/**
	The name of the project, like “Got”.
	*/
	let name: String

	/**
	The repo on GitHub, which the card links to.
	*/
	let repository: GitHubRepositoryName

	/**
	What the project does, in one line.
	*/
	let summary: String

	var language: Language?

	/**
	All the projects of the page, in the order within each group. The descriptions are close to those of the repos.
	*/
	static let all: [Self] = Group.allCases.flatMap(\.projects)

	private static let httpProjects: [Self] = [
		Self(
			name: "Got",
			repository: #repository("sindresorhus/got"),
			summary: "Human-friendly and powerful HTTP requests for Node.js.",
			language: .typeScript
		),
		Self(
			name: "Ky",
			repository: #repository("sindresorhus/ky"),
			summary: "A tiny and elegant HTTP client based on the Fetch API.",
			language: .typeScript
		),
		// The following were intentionally excluded: is-online, public-ip, is-up.
		Self(
			name: "normalize-url",
			repository: #repository("sindresorhus/normalize-url"),
			summary: "Normalize a URL.",
			language: .javaScript
		),
		Self(
			name: "fetch-extras",
			repository: #repository("sindresorhus/fetch-extras"),
			summary: "Useful utilities for working with Fetch.",
			language: .javaScript
		),
	]

	private static let promisesProjects: [Self] = [
		Self(
			name: "p-limit",
			repository: #repository("sindresorhus/p-limit"),
			summary: "Run promise-returning and async functions with limited concurrency.",
			language: .javaScript
		),
		Self(
			name: "p-queue",
			repository: #repository("sindresorhus/p-queue"),
			summary: "Promise queue with concurrency control.",
			language: .typeScript
		),
		Self(
			name: "p-map",
			repository: #repository("sindresorhus/p-map"),
			summary: "Map over promises concurrently.",
			language: .javaScript
		),
		Self(
			name: "p-retry",
			repository: #repository("sindresorhus/p-retry"),
			summary: "Retry a promise-returning or async function.",
			language: .javaScript
		),
		Self(
			name: "p-throttle",
			repository: #repository("sindresorhus/p-throttle"),
			summary: "Throttle promise-returning and async functions.",
			language: .javaScript
		),
		// The following were intentionally excluded: pify, delay, Emittery, p-cancelable.
		Self(
			name: "p-progress",
			repository: #repository("sindresorhus/p-progress"),
			summary: "Create a promise that reports progress.",
			language: .typeScript
		),
		Self(
			name: "p-memoize",
			repository: #repository("sindresorhus/p-memoize"),
			summary: "Memoize promise-returning and async functions.",
			language: .typeScript
		),
		Self(
			name: "p-event",
			repository: #repository("sindresorhus/p-event"),
			summary: "Promisify an event by waiting for it to be emitted.",
			language: .javaScript
		),
	]

	private static let commandLineToolsProjects: [Self] = [
		Self(
			name: "np",
			repository: #repository("sindresorhus/np"),
			summary: "A better “npm publish”.",
			language: .javaScript
		),
		Self(
			name: "Pure",
			repository: #repository("sindresorhus/pure"),
			summary: "Pretty, minimal, and fast Zsh prompt.",
			language: .shell
		),
		Self(
			name: "fkill",
			repository: #repository("sindresorhus/fkill-cli"),
			summary: "Fabulously kill processes. Cross-platform.",
			language: .javaScript
		),
		// The following were intentionally excluded: fast-cli, speed-test.
		Self(
			name: "emoj",
			repository: #repository("sindresorhus/emoj"),
			summary: "Find relevant emoji from text on the command-line.",
			language: .typeScript
		),
	]

	private static let commandLineAppsProjects: [Self] = [
		Self(
			name: "Chalk",
			repository: #repository("chalk/chalk"),
			summary: "Terminal string styling done right.",
			language: .javaScript
		),
		Self(
			name: "Ora",
			repository: #repository("sindresorhus/ora"),
			summary: "Elegant terminal spinner.",
			language: .javaScript
		),
		Self(
			name: "meow",
			repository: #repository("sindresorhus/meow"),
			summary: "A helper for command-line apps, like for their arguments and help text.",
			language: .javaScript
		),
		Self(
			name: "boxen",
			repository: #repository("sindresorhus/boxen"),
			summary: "Create boxes in the terminal.",
			language: .javaScript
		),
		Self(
			name: "log-update",
			repository: #repository("sindresorhus/log-update"),
			summary: "Log by overwriting the previous output in the terminal, like for progress bars.",
			language: .javaScript
		),
		// The following were intentionally excluded: terminal-link, cli-spinners, update-notifier, yoctocolors, log-symbols.
		Self(
			name: "string-width",
			repository: #repository("sindresorhus/string-width"),
			summary: "Get the visual width of a string.",
			language: .javaScript
		),
		Self(
			name: "figures",
			repository: #repository("sindresorhus/figures"),
			summary: "Unicode symbols with fallbacks for older terminals.",
			language: .javaScript
		),
		Self(
			name: "cli-truncate",
			repository: #repository("sindresorhus/cli-truncate"),
			summary: "Truncate a string to fit a specific number of columns.",
			language: .javaScript
		),
	]

	private static let filesProjects: [Self] = [
		Self(
			name: "globby",
			repository: #repository("sindresorhus/globby"),
			summary: "User-friendly glob matching.",
			language: .javaScript
		),
		Self(
			name: "file-type",
			repository: #repository("sindresorhus/file-type"),
			summary: "Detect the file type of a file, stream, or data.",
			language: .javaScript
		),
		Self(
			name: "find-up",
			repository: #repository("sindresorhus/find-up"),
			summary: "Find a file or directory by walking up parent directories.",
			language: .javaScript
		),
		Self(
			name: "trash",
			repository: #repository("sindresorhus/trash"),
			summary: "Move files and directories to the trash.",
			language: .javaScript
		),
		Self(
			name: "del",
			repository: #repository("sindresorhus/del"),
			summary: "Delete files and directories.",
			language: .javaScript
		),
		Self(
			name: "cpy",
			repository: #repository("sindresorhus/cpy"),
			summary: "Copy files.",
			language: .javaScript
		),
		Self(
			name: "move-file",
			repository: #repository("sindresorhus/move-file"),
			summary: "Move a file, directory, or symlink, also to another device.",
			language: .javaScript
		),
		// The following was intentionally excluded: make-dir.
		Self(
			name: "tempy",
			repository: #repository("sindresorhus/tempy"),
			summary: "Get a random temporary file or directory path.",
			language: .javaScript
		),
	]

	private static let systemProjects: [Self] = [
		Self(
			name: "Execa",
			repository: #repository("sindresorhus/execa"),
			summary: "Process execution for humans.",
			language: .javaScript
		),
		Self(
			name: "open",
			repository: #repository("sindresorhus/open"),
			summary: "Open URLs, files, and executables. Cross-platform.",
			language: .javaScript
		),
		Self(
			name: "clipboardy",
			repository: #repository("sindresorhus/clipboardy"),
			summary: "Access the system clipboard (copy and paste).",
			language: .javaScript
		),
		Self(
			name: "get-port",
			repository: #repository("sindresorhus/get-port"),
			summary: "Get an available TCP port.",
			language: .javaScript
		),
	]

	private static let textProjects: [Self] = [
		Self(
			name: "slugify",
			repository: #repository("sindresorhus/slugify"),
			summary: "Slugify a string.",
			language: .javaScript
		),
		Self(
			name: "camelcase",
			repository: #repository("sindresorhus/camelcase"),
			summary: "Convert a dash, dot, underscore, or space separated string to camelCase.",
			language: .javaScript
		),
		Self(
			name: "pretty-bytes",
			repository: #repository("sindresorhus/pretty-bytes"),
			summary: "Convert bytes to a human-readable string: 1337 → 1.34 kB.",
			language: .javaScript
		),
		Self(
			name: "pretty-ms",
			repository: #repository("sindresorhus/pretty-ms"),
			summary: "Convert milliseconds to a human-readable string: 1337000000 → 15d 11h 23m 20s.",
			language: .javaScript
		),
	]

	private static let objectsProjects: [Self] = [
		Self(
			name: "dot-prop",
			repository: #repository("sindresorhus/dot-prop"),
			summary: "Get, set, or delete a property of a nested object with a dot path.",
			language: .javaScript
		),
		// The following was intentionally excluded: on-change.
		Self(
			name: "debounce",
			repository: #repository("sindresorhus/debounce"),
			summary: "Delay function calls until a set time elapses after the last invocation.",
			language: .javaScript
		),
		Self(
			name: "quick-lru",
			repository: #repository("sindresorhus/quick-lru"),
			summary: "Simple “Least Recently Used” (LRU) cache.",
			language: .javaScript
		),
		Self(
			name: "memoize",
			repository: #repository("sindresorhus/memoize"),
			summary: "Memoize functions, so calls with the same input are faster.",
			language: .typeScript
		),
	]

	private static let webProjects: [Self] = [
		Self(
			name: "query-string",
			repository: #repository("sindresorhus/query-string"),
			summary: "Parse and stringify URL query strings.",
			language: .javaScript
		),
		Self(
			name: "copy-text-to-clipboard",
			repository: #repository("sindresorhus/copy-text-to-clipboard"),
			summary: "Copy text to the clipboard in modern browsers.",
			language: .javaScript
		),
		Self(
			name: "element-ready",
			repository: #repository("sindresorhus/element-ready"),
			summary: "Detect when an element is ready in the DOM.",
			language: .javaScript
		),
		Self(
			name: "github-markdown-css",
			repository: #repository("sindresorhus/github-markdown-css"),
			summary: "The minimal amount of CSS to replicate the GitHub Markdown style.",
			language: .css
		),
	]

	private static let imagesProjects: [Self] = [
		// The following were intentionally excluded: Pageres, gulp-imagemin, image-type, term-img.
		Self(
			name: "capture-website",
			repository: #repository("sindresorhus/capture-website"),
			summary: "Capture screenshots of websites.",
			language: .javaScript
		),
		Self(
			name: "image-dimensions",
			repository: #repository("sindresorhus/image-dimensions"),
			summary: "Get the dimensions of an image.",
			language: .javaScript
		),
		Self(
			name: "terminal-image",
			repository: #repository("sindresorhus/terminal-image"),
			summary: "Display images in the terminal.",
			language: .javaScript
		),
	]

	private static let lintingProjects: [Self] = [
		Self(
			name: "XO",
			repository: #repository("xojs/xo"),
			summary: "JavaScript and TypeScript linter with great defaults.",
			language: .typeScript
		),
		Self(
			name: "eslint-plugin-unicorn",
			repository: #repository("sindresorhus/eslint-plugin-unicorn"),
			summary: "More than 300 powerful ESLint rules.",
			language: .javaScript
		),
		Self(
			name: "eslint-config-xo",
			repository: #repository("xojs/eslint-config-xo"),
			summary: "The ESLint config of XO.",
			language: .javaScript
		),
		// The following was intentionally excluded: eslint-plugin-ava.
		Self(
			name: "eslint-package-json",
			repository: #repository("sindresorhus/eslint-package-json"),
			summary: "Powerful ESLint rules for package.json.",
			language: .javaScript
		),
		Self(
			name: "eslint-cssicorn",
			repository: #repository("sindresorhus/eslint-cssicorn"),
			summary: "Powerful ESLint rules for CSS.",
			language: .javaScript
		),
		Self(
			name: "eslint-node-test",
			repository: #repository("sindresorhus/eslint-node-test"),
			summary: "ESLint rules for the Node.js built-in test runner (node:test).",
			language: .javaScript
		),
		Self(
			name: "awesome-lint",
			repository: #repository("sindresorhus/awesome-lint"),
			summary: "Linter for Awesome lists.",
			language: .javaScript
		),
		Self(
			name: "eslint-formatter-pretty",
			repository: #repository("sindresorhus/eslint-formatter-pretty"),
			summary: "Pretty ESLint formatter.",
			language: .javaScript
		),
	]

	private static let testingProjects: [Self] = [
		Self(
			name: "AVA",
			repository: #repository("avajs/ava"),
			summary: "Node.js test runner that lets you develop with confidence.",
			language: .javaScript
		),
		Self(
			name: "type-fest",
			repository: #repository("sindresorhus/type-fest"),
			summary: "A collection of essential TypeScript types.",
			language: .typeScript
		),
		Self(
			name: "ts-extras",
			repository: #repository("sindresorhus/ts-extras"),
			summary: "Essential utilities for TypeScript projects.",
			language: .typeScript
		),
		// The following was intentionally excluded: ow.
		Self(
			name: "test-extras",
			repository: #repository("sindresorhus/test-extras"),
			summary: "Assertions and utilities that make node:test better.",
			language: .javaScript
		),
	]

	private static let fileFormatsProjects: [Self] = [
		// File formats keep the spec repos and the Swift implementation of SOML. The following were intentionally excluded: `soml` (the reference parser), `SimpleColorPalette` (a Swift implementation), and the implementations of other file formats.
		Self(
			name: "SOML",
			repository: #repository("soml-lang/soml"),
			summary: "A config format for humans. The spec is a draft."
		),
		Self(
			name: "Simple Color Palette",
			repository: #repository("simple-color-palette/spec"),
			summary: "A minimal JSON-based file format for color palettes. The spec is a work in progress."
		),
		Self(
			name: "SOML Swift",
			repository: #repository("soml-lang/SOMLSwift"),
			summary: "A Swift implementation of the SOML format.",
			language: .swift
		),
	]

	private static let swiftProjects: [Self] = [
		Self(
			name: "Defaults",
			repository: #repository("sindresorhus/Defaults"),
			summary: "Swifty and modern UserDefaults.",
			language: .swift
		),
		Self(
			name: "KeyboardShortcuts",
			repository: #repository("sindresorhus/KeyboardShortcuts"),
			summary: "Add user-customizable global keyboard shortcuts to your macOS app.",
			language: .swift
		),
		// The following were intentionally excluded: Settings, CircularProgress, ExceptionCatcher, CustomButton, touch-bar-simulator.
		Self(
			name: "LaunchAtLogin",
			repository: #repository("sindresorhus/LaunchAtLogin-Modern"),
			summary: "Add “Launch at Login” to your macOS app in seconds.",
			language: .swift
		),
		Self(
			name: "DockProgress",
			repository: #repository("sindresorhus/DockProgress"),
			summary: "Show progress in the Dock icon of your app.",
			language: .swift
		),
		Self(
			name: "Regex",
			repository: #repository("sindresorhus/Regex"),
			summary: "Swifty regular expressions.",
			language: .swift
		),
		Self(
			name: "Percentage",
			repository: #repository("sindresorhus/Percentage"),
			summary: "A percentage type for Swift.",
			language: .swift
		),
		Self(
			name: "DSStore",
			repository: #repository("sindresorhus/DSStore"),
			summary: "Read and write macOS .DS_Store files in Swift.",
			language: .swift
		),
		Self(
			name: "ExtendedAttributes",
			repository: #repository("sindresorhus/ExtendedAttributes"),
			summary: "Manage extended attributes in Swift.",
			language: .swift
		),
	]

	private static let macProjects: [Self] = [
		Self(
			name: "create-dmg",
			repository: #repository("sindresorhus/create-dmg"),
			summary: "Create a good-looking DMG for your macOS app in seconds.",
			language: .javaScript
		),
		Self(
			name: "macos-trash",
			repository: #repository("sindresorhus/macos-trash"),
			summary: "Move files and folders to the trash from the command line.",
			language: .swift
		),
		// The following was intentionally excluded: dark-mode.
		Self(
			name: "wallpaper",
			repository: #repository("sindresorhus/wallpaper"),
			summary: "Manage the desktop wallpaper, also on Linux and Windows.",
			language: .javaScript
		),
		Self(
			name: "macos-wallpaper",
			repository: #repository("sindresorhus/macos-wallpaper"),
			summary: "Manage the desktop wallpaper on macOS.",
			language: .swift
		),
	]

	private static let appsProjects: [Self] = [
		Self(
			name: "Gifski",
			repository: #repository("sindresorhus/Gifski"),
			summary: "Convert videos to high-quality GIFs on your Mac.",
			language: .swift
		),
		Self(
			name: "Pasteboard Viewer",
			repository: #repository("sindresorhus/Pasteboard-Viewer"),
			summary: "Inspect the system pasteboards.",
			language: .swift
		),
		// The following was intentionally excluded: Blear.
		Self(
			name: "Plash",
			repository: #repository("sindresorhus/Plash"),
			summary: "Make any website your Mac desktop wallpaper."
		),
	]

	private static let listsProjects: [Self] = [
		Self(
			name: "Awesome",
			repository: #repository("sindresorhus/awesome"),
			summary: "Awesome lists about all kinds of interesting topics."
		),
		Self(
			name: "Awesome Node.js",
			repository: #repository("sindresorhus/awesome-nodejs"),
			summary: "Delightful Node.js packages and resources."
		),
		Self(
			name: "Awesome npm",
			repository: #repository("sindresorhus/awesome-npm"),
			summary: "Awesome npm resources and tips."
		),
		Self(
			name: "Awesome Sci-Fi",
			repository: #repository("sindresorhus/awesome-scifi"),
			summary: "Sci-fi worth consuming."
		),
	]

	private static let funProjects: [Self] = [
		Self(
			name: "cat-names",
			repository: #repository("sindresorhus/cat-names"),
			summary: "Get popular cat names.",
			language: .javaScript
		),
		Self(
			name: "dog-names",
			repository: #repository("sindresorhus/dog-names"),
			summary: "Get popular dog names.",
			language: .javaScript
		),
		Self(
			name: "cows",
			repository: #repository("sindresorhus/cows"),
			summary: "ASCII cows.",
			language: .javaScript
		),
		Self(
			name: "superb",
			repository: #repository("sindresorhus/superb"),
			summary: "Get superb-like words.",
			language: .javaScript
		),
	]
}
