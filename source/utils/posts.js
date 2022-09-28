import getReadingTime from 'reading-time';

const getNormalizedPost = async post => {
	const {frontmatter, compiledContent, rawContent, file} = post;
	const id = file.split('/').pop().split('.').shift();

	return {
		...frontmatter,
		id,
		slug: frontmatter.slug ?? id,
		body: compiledContent(),
		readingTime: Math.ceil(getReadingTime(rawContent()).minutes),
	};
};

const load = async function () {
	const posts = import.meta.glob('~/../data/blog/**/*.md', {eager: true});

	let normalizedPosts = Object.keys(posts).map(async key => {
		const post = await posts[key];
		return getNormalizedPost(post);
	});

	normalizedPosts = await Promise.all(normalizedPosts);

	return normalizedPosts
		.filter(post => !post.draft)
		.sort((a, b) => new Date(b.pubDate) - new Date(a.pubDate));
};

let cachedPosts;

export const fetchPosts = async () => {
	cachedPosts = cachedPosts ?? load();
	return cachedPosts;
};

export const findPostsByIds = async ids => {
	if (!Array.isArray(ids)) {
		return [];
	}

	const posts = await fetchPosts();

	// TODO: Fix.
	// eslint-disable-next-line unicorn/no-array-reduce
	return ids.reduce((r, id) => {
		posts.some(post => id === post.id && r.push(post));

		return r;
	}, []);
};
