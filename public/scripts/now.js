// The now page is complete without this script. It adds the latest commits, which are only loaded here, and shows a newer Bluesky post than the one of the build.

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

const showLatestCommits = async () => {
	const container = document.querySelector('#latest-commits');
	const template = document.querySelector('#commit-template');

	// Without a token, GitHub allows 10 searches a minute for each visitor. When the request fails, the commits stay hidden.
	const response = await fetch('https://api.github.com/search/commits?q=author:sindresorhus&sort=author-date&order=desc&per_page=5', {
		headers: {
			Accept: 'application/vnd.github+json',
		},
	});

	if (!response.ok) {
		return;
	}

	const {items} = await response.json();

	if (!items?.length) {
		return;
	}

	const rows = items.map(item => {
		const row = template.content.firstElementChild.cloneNode(true);
		const link = row.querySelector('a');
		link.href = item.html_url;
		// Without the backticks of code, which GitHub shows as code.
		link.textContent = item.commit.message.split('\n')[0].replaceAll('`', '');
		row.querySelector('span span').textContent = item.repository.full_name.replace(/^sindresorhus\//, '');
		const time = row.querySelector('time');
		time.dateTime = item.commit.author.date;
		time.textContent = relativeTime(new Date(item.commit.author.date));
		return row;
	});

	container.querySelector('ul').replaceChildren(...rows);
	container.hidden = false;
	container.closest('section').hidden = false;
};

const handle = 'sindresorhus.com';

const linkOfFeature = feature => {
	switch (feature.$type) {
		case 'app.bsky.richtext.facet#link': {
			const url = URL.parse(feature.uri);
			return ['http:', 'https:'].includes(url?.protocol) ? url.href : undefined;
		}

		case 'app.bsky.richtext.facet#mention': {
			return `https://bsky.app/profile/${encodeURIComponent(feature.did)}`;
		}

		case 'app.bsky.richtext.facet#tag': {
			return `https://bsky.app/hashtag/${encodeURIComponent(feature.tag)}`;
		}

		default: {
			return undefined;
		}
	}
};

// The text with its links, like the build makes it. The facets mark the links by the byte range of their UTF-8 text.
const textNodes = (text, facets = []) => {
	const bytes = new TextEncoder().encode(text);
	const decoder = new TextDecoder();
	const nodes = [];
	let position = 0;

	for (const {index, features} of facets.toSorted((first, second) => first.index.byteStart - second.index.byteStart)) {
		const link = (features ?? []).map(feature => linkOfFeature(feature)).find(Boolean);

		if (
			index.byteStart < position
			|| index.byteStart >= index.byteEnd
			|| index.byteEnd > bytes.length
			|| !link
		) {
			continue;
		}

		if (index.byteStart > position) {
			nodes.push(decoder.decode(bytes.subarray(position, index.byteStart)));
		}

		const anchor = document.createElement('a');
		anchor.href = link;
		anchor.textContent = decoder.decode(bytes.subarray(index.byteStart, index.byteEnd));
		nodes.push(anchor);
		position = index.byteEnd;
	}

	if (position < bytes.length) {
		nodes.push(decoder.decode(bytes.subarray(position)));
	}

	return nodes;
};

const showLatestBlueskyPost = async () => {
	const quote = document.querySelector('#bluesky-post');

	// The build had no post, so there is no place for one.
	if (!quote) {
		return;
	}

	const response = await fetch(`https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor=${handle}&limit=5&filter=posts_no_replies`);

	if (!response.ok) {
		return;
	}

	const {feed} = await response.json();

	// Reposts and the pinned post have a reason.
	const post = feed?.find(item => !item.reason && item.post.record.text.trim())?.post;

	if (!post) {
		return;
	}

	const url = `https://bsky.app/profile/${handle}/post/${post.uri.split('/').at(-1)}`;
	const details = quote.nextElementSibling;
	const link = details.querySelector('a');
	const time = details.querySelector('time');
	const date = new Date(post.record.createdAt);

	// Only a post that is newer than the one of the build, so the page never goes back to an older post.
	if (link.href === url || !(date > new Date(time.dateTime))) {
		return;
	}

	quote.querySelector('p').replaceChildren(...textNodes(post.record.text, post.record.facets));
	link.href = url;
	time.dateTime = date.toISOString();
	time.textContent = date.toLocaleDateString('en-US', {
		timeZone: 'UTC',
		day: 'numeric',
		month: 'long',
		year: 'numeric',
	});
};

// Network errors leave the page as the build made it. The errors are logged, so a mistake in the script, like a selector that no longer matches, is not hidden.
for (const result of await Promise.allSettled([showLatestCommits(), showLatestBlueskyPost()])) {
	if (result.status === 'rejected') {
		console.error(result.reason);
	}
}
