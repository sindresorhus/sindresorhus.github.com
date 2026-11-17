// The now page is complete without this script. It adds the latest commits, which are only loaded here, in the card that is waiting for them.
import {cloneTemplate, parts, prerendered, scriptData} from '/scripts/dom.js';

// The account of the build, so the script asks for the same one, and the number of placeholder rows of the commits.
const {commitCount, gitHubAccount} = scriptData('now-data');

// The speculation rules of the site can prerender the page while the pointer is over a link to it. The script waits until the visitor opens the page, so a page that nobody opens spends none of the GitHub searches of the visitor, and the relative times are not old when the page shows.
await prerendered;

// A request that hangs gives up, so the placeholder rows do not stay forever.
const requestTimeout = 10_000;

const relativeTimeFormat = new Intl.RelativeTimeFormat('en', {numeric: 'auto'});

const units = [
	['year', 365 * 24 * 60 * 60],
	['month', 30 * 24 * 60 * 60],
	['week', 7 * 24 * 60 * 60],
	['day', 24 * 60 * 60],
	['hour', 60 * 60],
	['minute', 60],
	['second', 1],
];

// Only relative times, like “2 hours ago”, as the commit dates have the time zone of the author.
const relativeTime = date => {
	const seconds = (date - Date.now()) / 1000;
	let index = units.findIndex(([, length]) => Math.abs(seconds) >= length);

	if (index === -1) {
		index = units.length - 1;
	}

	// A value that rounds up to one of the next larger unit uses that unit, like “1 hour ago” instead of “60 minutes ago”. The rounded value is compared in seconds, as 4 weeks is less than a month.
	while (index > 0 && Math.abs(Math.round(seconds / units[index][1])) * units[index][1] >= units[index - 1][1]) {
		index--;
	}

	const [unit, length] = units[index];
	return relativeTimeFormat.format(Math.round(seconds / length), unit);
};

// The time of each commit row and its date. The back/forward cache shows the page again as the visitor left it, maybe hours later, so the relative times are written again.
const commitTimes = new Map();

window.addEventListener('pageshow', event => {
	if (!event.persisted) {
		return;
	}

	for (const [element, date] of commitTimes) {
		element.textContent = relativeTime(date);
	}
});

// Commits that say nothing about the work, like a release (“8.0.0”) or “Tweaks”. The card is about what is being built now, and the releases have their own card.
const routineCommitTitles = new Set(['tweaks', 'meta tweaks', 'update dependencies', 'more tests']);
const isRoutineCommit = title => /^v?\d+\.\d+\.\d+\S*$/.test(title) || routineCommitTitles.has(title.toLowerCase());

// The first line of a commit message, with its code, which is between backticks, as `code` elements, like GitHub shows it. A backtick without its pair is left out.
const titleNodes = title => {
	const parts = title.split('`');

	return parts.map((part, index) => {
		if (index % 2 === 0 || index === parts.length - 1) {
			return part;
		}

		const code = document.createElement('code');
		code.textContent = part;
		return code;
	});
};

const showLatestCommits = async () => {
	const container = document.querySelector('#latest-commits');
	const template = document.querySelector('#commit-template');
	const {list} = parts(container, 'the latest commits');

	// Without a token, GitHub allows 10 searches a minute for each visitor. When the request fails, an error replaces the placeholder rows, and the link to GitHub below them stays. The section is shown too, as it can be hidden until the commits load.
	const showError = () => {
		list.hidden = true;
		list.removeAttribute('aria-busy');
		document.querySelector('#latest-commits-error').hidden = false;
		container.closest('section').hidden = false;
	};

	let items;

	try {
		const response = await fetch(`https://api.github.com/search/commits?q=author:${gitHubAccount}&sort=author-date&order=desc&per_page=30`, {
			headers: {
				Accept: 'application/vnd.github+json',
			},
			signal: AbortSignal.timeout(requestTimeout),
		});

		// More than the rows of the card, as some commits are left out.
		items = response.ok ? (await response.json()).items : undefined;
	} catch (error) {
		showError();
		throw error;
	}

	const commits = (items ?? [])
		.map(item => ({item, title: item.commit.message.split('\n')[0].trim()}))
		.filter(({title}) => !isRoutineCommit(title))
		// At most two commits of each repo, so a busy day in one repo does not fill the card, which is about all that is being built.
		.filter(({item}, index, commits) => commits.slice(0, index).filter(other => other.item.repository.full_name === item.repository.full_name).length < 2)
		.slice(0, commitCount);

	if (commits.length === 0) {
		showError();
		return;
	}

	const rows = commits.map(({item, title}) => {
		const row = cloneTemplate(template);
		const {link, repository, time} = parts(row, 'a commit');
		link.href = item.html_url;

		// The number of a pull request at the end, like “(#3976)”, links to its discussion, like on GitHub. The link is next to the link of the commit, as a link cannot be in another link. GitHub sends the issue URL of a pull request to the pull request.
		const pullRequest = title.match(/^(?<message>.+) \(#(?<number>\d+)\)$/)?.groups;
		link.replaceChildren(...titleNodes(pullRequest?.message ?? title));

		if (pullRequest) {
			const pullRequestLink = document.createElement('a');
			pullRequestLink.href = `${item.repository.html_url}/issues/${pullRequest.number}`;
			pullRequestLink.textContent = `#${pullRequest.number}`;
			const message = document.createElement('span');
			link.replaceWith(message);
			message.append(link, ' (', pullRequestLink, ')');
		}

		const repositoryPrefix = `${gitHubAccount}/`;
		repository.textContent = item.repository.full_name.startsWith(repositoryPrefix) ? item.repository.full_name.slice(repositoryPrefix.length) : item.repository.full_name;
		const date = new Date(item.commit.author.date);
		time.textContent = relativeTime(date);
		commitTimes.set(time, date);
		return row;
	});

	list.replaceChildren(...rows);
	list.removeAttribute('aria-busy');
	container.closest('section').hidden = false;
};

// Network errors leave the page as the build made it. The errors are logged, so a mistake in the script, like a selector that no longer matches, is not hidden.
try {
	await showLatestCommits();
} catch (error) {
	console.error(error);
}
