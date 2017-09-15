/* eslint-env browser */
(() => {
	const isDev = ['localhost', '127.0.0.1'].includes(location.hostname);

	// Helper
	const dom = {
		select: document.querySelector.bind(document),
		slectAll: document.querySelectorAll.bind(document)
	};

	function injectScript(src, cb) {
		const script = document.createElement('script');
		script.src = src;
		script.addEventListener('load', cb);
		document.head.appendChild(script);
	}

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

	// Latest GitHub repos
	(async () => {
		const url = isDev ? 'http://localhost:3000' : 'https://gh-latest-repos-hbiycdtvej.now.sh';

		const json = await (await fetch(url)).json();

		const template = dom.select('#latest-repos-template');
		const container = dom.select('#latest-repos');

		for (const repo of json.reverse()) {
			const content = template.cloneNode(true).content;

			const a = content.querySelector('.latest-repos-title');
			a.href = repo.url;
			a.textContent = repo.name;

			if (repo.primaryLanguage) {
				const lang = content.querySelector('.latest-repos-language');
				lang.textContent = repo.primaryLanguage.name;
				lang.style.backgroundColor = repo.primaryLanguage.color;
			}

			content.querySelector('.latest-repos-description').textContent = repo.description;

			container.appendChild(document.importNode(content, true));
		}
	})();

	// Unicorn easteregg
	dom.select('#unicorn-btn').addEventListener('click', event => {
		event.preventDefault();
		injectScript('cornify.js', () => {
			cornify();
			cornify();
			setInterval(cornify, 1000);
		});
	});

	// Smooth anchor scroll
	new AnchorScroller();

	{
		function hideScrollHint() {
			if (window.scrollY > 100) {
				document.removeEventListener('scroll', hideScrollHint);
				dom.select('#scroll-hint').classList.add('hidden');
			}
		}

		document.addEventListener('scroll', hideScrollHint, {passive: true});
	}
})();
