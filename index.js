/* eslint-env browser */

const isDev = ['localhost', '127.0.0.1'].includes(location.hostname);

// Helper
const dom = {
	select: document.querySelector.bind(document),
	slectAll: document.querySelectorAll.bind(document)
};

const injectScript = (source, callback) => {
	const script = document.createElement('script');
	script.src = source;
	script.addEventListener('load', callback);
	document.head.appendChild(script);
};

const insertHypenationHintsForCamelCase = string => string.replace(/([a-z])([A-Z])/g, '$1\u00AD$2');

// Latest blog post
(async () => {
	const username = 'sindresorhus';
	const graphql = `
		query PostQuery($username: String!) {
			posts(username: $username, limit: 1) {
				title
				url
				subtitle
			}
		}
	`;

	const url = new URL('https://micro-medium-api-gqmwonovpk.now.sh/graphql');
	url.searchParams.append('variables', JSON.stringify({username}));
	url.searchParams.append('query', graphql);

	const json = await (await fetch(url)).json();
	const item = json.data.posts[0];

	const title = dom.select('#latest-blog-post a');
	title.href = item.url;
	title.textContent = item.title;

	dom.select('#latest-blog-post p').textContent = item.subtitle;
	dom.select('#latest-blog-post').classList.add('visible');
})();

// Latest GitHub commit
(async () => {
	const username = 'sindresorhus';
	const email = 'sindresorhus@gmail.com';

	const response = await fetch(`https://api.github.com/users/${username}/events/public`);
	const json = await response.json();

	// TODO: Support pagination if no suitable event can be found in the first request:
	// https://developer.github.com/v3/activity/events/#list-public-events-performed-by-a-user
	let latestCommit;
	const latestPushEvent = json.find(event => {
		if (event.type !== 'PushEvent') {
			return false;
		}

		// Ensure the commit is authored by me and I'm not just a "committer"
		latestCommit = event.payload.commits.reverse().find(commit => commit.author.email === email);
		return Boolean(latestCommit);
	});

	if (!latestCommit) {
		dom.select('#latest-commit').textContent = 'No commit';
		return;
	}

	const {repo, created_at: createdAt} = latestPushEvent;
	const repoUrl = `https://github.com/${repo.name}`;

	const commitTitleElement = dom.select('#latest-commit .commit-title');
	commitTitleElement.href = `${repoUrl}/commit/${latestCommit.sha}`;
	const commitMessageLines = latestCommit.message.trim().split('\n');
	commitTitleElement.title = commitMessageLines.slice(1).join('\n').trim();
	commitTitleElement.textContent = commitMessageLines[0].trim();

	const commitDateElement = dom.select('#latest-commit .commit-date');
	commitDateElement.textContent = timeago().format(createdAt);

	const repoTitleElement = dom.select('#latest-commit .repo-title');
	repoTitleElement.href = repoUrl;
	repoTitleElement.textContent = repo.name.replace(new RegExp(`^${username}/`), '');
})();

// Latest GitHub repos
(async () => {
	const textColorFromBackgroundColor = color => {
		if (color.length < 5) {
			color += color.slice(1);
		}

		return parseInt(color.replace('#', '0x'), 16) > (0xFFFFFF / 2) ? '#333' : '#fff';
	};

	const url = isDev ? 'http://localhost:3000' : 'https://gh-latest-repos.now.sh';

	const json = await (await fetch(url)).json();

	const template = dom.select('#latest-repos-template');
	const container = dom.select('#latest-repos');

	for (const repo of json.reverse()) {
		if (!repo.description) {
			continue;
		}

		const content = template.cloneNode(true).content;

		const a = content.querySelector('.latest-repos-title');
		a.href = repo.url;
		a.textContent = insertHypenationHintsForCamelCase(repo.name);

		if (repo.primaryLanguage) {
			const lang = content.querySelector('.latest-repos-language');
			lang.textContent = repo.primaryLanguage.name;
			lang.style.color = textColorFromBackgroundColor(repo.primaryLanguage.color);
			lang.style.backgroundColor = repo.primaryLanguage.color;
		}

		content.querySelector('.latest-repos-description').textContent = repo.description;

		container.appendChild(document.importNode(content, true));
	}

	dom.select('#projects').style.opacity = 1;
})();

// Unicorn easteregg
dom.select('#unicorn-btn').addEventListener('click', event => {
	event.preventDefault();
	injectScript('cornify.js', () => {
		cornify();
		cornify();
		setInterval(cornify, 1000);
	});
}, {once: true});

{
	function hideScrollHint() {
		if (window.scrollY > 100) {
			document.removeEventListener('scroll', hideScrollHint);
			dom.select('#scroll-hint').classList.add('hidden');
		}
	}

	document.addEventListener('scroll', hideScrollHint, {passive: true});
}
