import getReadingTime from 'reading-time';
import {getCollection, render} from 'astro:content';

const normalizePost = async post => {
	const {id, body, data} = post;
	const {Content} = await render(post);

	return {
		...data,
		id,
		slug: id,
		url: data.redirectUrl ?? `/blog/${id}`,
		isRedirect: data.redirectUrl !== undefined,
		readingTime: Math.ceil(getReadingTime(body ?? '').minutes),
		Content,
	};
};

const loadAll = async () => {
	const posts = await getCollection('blog', post => !post.data.draft);

	const normalizedPosts = await Promise.all(
		posts.map(async post => normalizePost(post)),
	);

	return normalizedPosts.sort((a, b) => b.pubDate - a.pubDate);
};

let cachedPosts;

export const fetchPosts = async ({includeUnlisted = false} = {}) => {
	cachedPosts ??= loadAll();
	const posts = await cachedPosts;

	return posts.filter(post => includeUnlisted || !post.isUnlisted);
};

