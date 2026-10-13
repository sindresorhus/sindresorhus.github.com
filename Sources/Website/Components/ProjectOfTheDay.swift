import Elementary
import Foundation
import SiteKit

/**
One of my projects, like an npm package or a repo, the same for everyone on a day, with a button that shows a random other one, so visitors find projects they did not know.

The projects for the button are in a JSON file (``listJSON(_:)``), which the script loads on the first click, so the page does not have them.
*/
struct ProjectOfTheDay: ScriptedElement {
	static let script = ElementScript(inline: #"""
	export default class extends HTMLElement {
		#projects;

		connectedCallback() {
			// The same function, so connecting the element again does not add a second listener.
			this.querySelector('[data-part="next"]').addEventListener('click', this.#showAnother);
		}

		#showAnother = async () => {
			const {listPath, randomTitle} = JSON.parse(this.dataset.config);

			try {
				this.#projects ??= await (await fetch(listPath)).json();
			} catch (error) {
				// The project of the day stays.
				console.error('Could not load the projects:', error);
				return;
			}

			const name = this.querySelector('[data-part="name"]');
			const others = this.#projects.filter(project => project.name !== name.textContent);
			const pick = others[Math.floor(Math.random() * others.length)];

			// A list with only the shown project has no other one.
			if (!pick) {
				return;
			}

			this.querySelector('[data-part="title"]').textContent = randomTitle;
			name.textContent = pick.name;
			name.href = pick.url;
			this.querySelector('[data-part="description"]').textContent = pick.description;
			this.querySelector('[data-part="detail"]').textContent = pick.detail;
		};
	}
	"""#)

	/**
	A project that the card can show.
	*/
	struct Project: Encodable {
		let name: String
		let description: String

		/**
		A number about the project, like “4.2M+ downloads a week” or “1.2K+ stars”.
		*/
		let detail: String

		let url: URL
	}

	/**
	The title of the card, like “Package of the Day”.
	*/
	let title: String

	/**
	The title of the card after the button picked a project, like “Random Package”.
	*/
	let randomTitle: String

	/**
	The file with the projects for the button.
	*/
	let listPath: RoutePath

	let project: Project

	/**
	The project of the day of the projects, which changes each day of the build, like the related apps. `nil` when there are no projects.
	*/
	init?(title: String, randomTitle: String, listPath: RoutePath, projects: [Project], date: Date) {
		var generator = SeededRandomNumberGenerator.daily(listPath.description, on: date)

		guard let project = projects.randomElement(using: &generator) else {
			return nil
		}

		self.title = title
		self.randomTitle = randomTitle
		self.listPath = listPath
		self.project = project
	}

	/**
	The file with the projects for the button.
	*/
	static func listJSON(_ projects: [Project]) -> Data {
		// Sorted keys, so the file is the same in every build with the same projects.
		Data(JSONEncoder.pageJSON(projects).utf8)
	}

	var config: Config {
		Config(listPath: listPath, randomTitle: randomTitle)
	}

	var content: some HTML {
		// The button is next to the title, above the project, so it stays in place when the next project has a longer or shorter description, and the visitor can keep clicking.
		div {
			p(.part(Parts.title)) {
				title
			}
			.style {
				$0
					.margin(0)
					.textStyle(.caption, weight: .semibold)
					.color(.link)
			}

			// Only the icon, so the title stays on one line next to it, also in the narrow columns, and the button does not move when the title changes. The tooltip and screen readers have the label.
			button(.part(Parts.next), .type(.button), .title("Another One")) {
				Icon.shuffle.size(.rootEm(1.125))
				VisuallyHidden("Another One")
			}
			.style {
				// A quiet icon button, which only shows its circle under the pointer. The negative margin keeps the row as high as the title, and the icon in line with the edge of the text.
				$0
					.display(.flex)
					// A larger area to tap than the icon.
					.padding(.rootEm(0.5))
					.margin(.rootEm(-0.5))
					.cornerRadius(.circle)
					.color(.secondaryText)
					.transition(.backgroundColor, .color, animation: .stateChange)
					.hover {
						$0
							.background(.cardHover)
							.color(.primaryText)
					}
			}
		}
		.hstack(alignment: .center, justification: .spaceBetween, spacing: .rootEm(1))
		.style {
			$0.frame(width: .percent(100))
		}

		div {
			a(.part(Parts.name), .href(.url(project.url))) {
				project.name
			}
			.style {
				$0
					.textStyle(.headline)
					.fontFamily(.monospace)
			}

			// The size and line height of body text, not of the prose around the card.
			p(.part(Parts.description)) {
				project.description
			}
			.style {
				$0
					.margin(0)
					.textStyle(.body)
					.color(.bodyText)
			}

			p(.part(Parts.detail)) {
				project.detail
			}
			.style {
				$0
					.margin(top: .rootEm(0.25), horizontal: 0, bottom: 0)
					.secondaryText()
			}
		}
		.vstack(alignment: .start, spacing: .rootEm(0.375))
	}

	struct Config: Encodable {
		let listPath: RoutePath
		let randomTitle: String
	}

	enum Parts: String, ElementPartSet {
		case title
		case name
		case description
		case detail
		case next
	}

	enum Styles: ElementStyleSet {
		case root

		var style: Style {
			switch self {
			case .root:
				// A card, with the title and the button above the project. The padding is like the cards of the popular projects.
				Style()
					.vstack(alignment: .start, spacing: .rootEm(1))
					.padding(.rootEm(1.5))
					.cardSurface(isInteractive: false)
			}
		}
	}
}

extension ProjectOfTheDay.Project {
	init?(package: NPMStatistics.Package) {
		guard let description = package.description else {
			return nil
		}

		self.init(name: package.name, description: description, detail: package.weeklyDownloadsLabel, url: package.url)
	}

	init?(repository: GitHubRepository) {
		guard let summary = repository.summary else {
			return nil
		}

		self.init(name: repository.name, description: summary, detail: repository.stars.approximateCount(counting: "star"), url: repository.url)
	}
}

extension SiteContent {
	/**
	The npm packages for ``ProjectOfTheDay``: the ones with a description, as a package without one says nothing about itself. Not the packages of the Yeoman and imagemin organizations. The repos only have the repos of my account, so they have none of theirs.

	The npm search does not say whether a package is deprecated, so a package with an archived repo is left out instead. Only the repos of my account are known, so a deprecated package in the repo of an organization, like Chalk, can still be shown.
	*/
	var discoverablePackages: [ProjectOfTheDay.Project] {
		let excludedOwners: Set = ["yeoman", "imagemin"]
		let archivedRepositories = Set((gitHubAccount?.repositories ?? []).filter(\.isArchived).map { $0.nameWithOwner.lowercased() })

		return npmStatistics.packages
			.filter { package in
				// The repository is like `yeoman/environment`.
				guard let repository = package.repository?.lowercased() else {
					return true
				}

				return !excludedOwners.contains(repository.repositoryOwner)
					&& !archivedRepositories.contains(repository)
			}
			.compactMap(ProjectOfTheDay.Project.init(package:))
	}

	/**
	The repos for ``ProjectOfTheDay``: the ones with a description that are not forks or archived. The repos of npm packages are left out, as the packages have their own card, so the repos are the other projects, like Swift packages and lists. Repos for settings, like `.github`, are not projects.
	*/
	var discoverableRepositories: [ProjectOfTheDay.Project] {
		let packageRepositories = Set(npmStatistics.packages.compactMap { $0.repository?.lowercased() })

		return (gitHubAccount?.repositories ?? [])
			.filter {
				!$0.isFork
					&& !$0.isArchived
					&& !$0.name.hasPrefix(".")
					&& !packageRepositories.contains($0.nameWithOwner.lowercased())
			}
			.compactMap(ProjectOfTheDay.Project.init(repository:))
	}
}
