---
layout: ~/layouts/MarkdownLayout.astro
title: Repos
---

<style>
	#unicorn-icon {
		margin-top: -30px;
		margin-bottom: 20px;
	}

	#latest-repos-container h2 {
		margin-bottom: 2rem;
	}

	#latest-repos h4 {
		margin-bottom: 0.5rem;
	}
</style>

<!-- TODO: Switch to type:module when I have replaced timeago with the native method -->
<script>
// Latest GitHub commit

// TODO: Remove this wrapper when top-level await is supported everywhere.
(async () => {
	// Helper
	const dom = {
		select: document.querySelector.bind(document),
		selectAll: document.querySelectorAll.bind(document)
	};

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
	commitDateElement.textContent = window.timeago().format(createdAt);

	const repoTitleElement = dom.select('#latest-commit .repo-title');
	repoTitleElement.href = repoUrl;
	repoTitleElement.textContent = repo.name.replace(new RegExp(`^${username}/`), '');
})();
</script>

<script type="module">
// Latest GitHub repos

(async () => {
	// Helper
	const dom = {
		select: document.querySelector.bind(document),
		slectAll: document.querySelectorAll.bind(document)
	};

	const isDev = ['localhost', '127.0.0.1'].includes(location.hostname);
	const insertHypenationHintsForCamelCase = string => string.replace(/([a-z])([A-Z])/g, '$1\u00AD$2');

	const textColorFromBackgroundColor = color => {
		if (color.length < 5) {
			color += color.slice(1);
		}

		return parseInt(color.replace('#', '0x'), 16) > (0xFFFFFF / 2) ? '#333' : '#fff';
	};

	const url = isDev ? 'http://localhost:3000' : 'https://gh-latest-repos-sindresorhus.vercel.app';

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

		const lang = content.querySelector('.latest-repos-language');
		if (repo.primaryLanguage) {
			lang.textContent = repo.primaryLanguage.name;
			lang.style.color = textColorFromBackgroundColor(repo.primaryLanguage.color);
			lang.style.backgroundColor = repo.primaryLanguage.color;

			const query = `user:sindresorhus user:chalk user:avajs user:xojs language:${repo.primaryLanguage.name.toLowerCase()} archived:false`;
			const url = new URL('https://github.com/search');
			url.searchParams.append('q', query);
			lang.href = url;
		} else {
			lang.classList.add('is-unclickable');
		}

		content.querySelector('.latest-repos-description').textContent = repo.description;

		container.appendChild(document.importNode(content, true));
	}

	dom.select('#projects').style.opacity = 1;
})();
</script>

<section class="hero is-fullheight">
	<div id="projects" class="hero-body container">
		<div class="columns is-vcentered">
			<div class="column has-text-centered">
				<img id="unicorn-icon" src="unicorn.svg" width="100" height="100">
				<h4 class="title is-4" style="font-weight: 400">Latest commit</h4>
				<div id="latest-commit">
					<a class="commit-title nice-link" href=""></a>
					<br>
					<span style="font-size: 12px">
						<span class="commit-date"></span> in <a class="repo-title" href=""></a>
					</span>
				</div>
				<br>
				<a href="https://twitter.com/sindre_gh_repos">Follow updates</a>
			</div>
			<div id="latest-repos-container" class="column is-three-fifths is-offset-1 has-nice-link">
				<h2 class="title is-2">Latest repos</h2>
				<template id="latest-repos-template">
					<div class="column is-half">
						<h4 class="title is-4">
							<a class="latest-repos-title" href=""></a>
							<a class="tag is-small latest-repos-language">¯\_(ツ)_/¯</a>
						</h4>
						<p class="latest-repos-description"></p>
					</div>
				</template>
				<div id="latest-repos" class="columns is-multiline"></div>
			</div>
		</div>
	</div>
</section>
