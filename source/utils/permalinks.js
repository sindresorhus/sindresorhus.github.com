import slugify from 'limax';

import {SITE, BLOG} from '~/config.mjs';

const trim = (string_, ch) => {
	let start = 0;
	let end = string_.length;

	while (start < end && string_[start] === ch) {
		++start;
	}

	while (end > start && string_[end - 1] === ch) {
		--end;
	}

	// eslint-disable-next-line unicorn/prefer-string-slice
	return start > 0 || end < string_.length ? string_.substring(start, end) : string_;
};

const trimSlash = s => trim(trim(s, '/'));
const createPath = (...parameters) => '/' + parameters.filter(Boolean).join('/');

const basePathname = trimSlash(SITE.basePathname);

export const cleanSlug = text => slugify(trimSlash(text));

export const APPS_BASE = cleanSlug('apps');
export const BLOG_BASE = cleanSlug(BLOG?.blog?.pathname);
export const POST_BASE = cleanSlug(BLOG?.post?.pathname);
export const CATEGORY_BASE = cleanSlug(BLOG?.category?.pathname);
export const TAG_BASE = cleanSlug(BLOG?.tag?.pathname);

export const getPermalink = (slug = '', type = 'page') => {
	const _slug = cleanSlug(slug);

	switch (type) {
		case 'category':
			return createPath(basePathname, CATEGORY_BASE, _slug);
		case 'tag':
			return createPath(basePathname, TAG_BASE, _slug);
		case 'post':
			return createPath(basePathname, POST_BASE, _slug);
		case 'page': // eslint-disable-line unicorn/no-useless-switch-case
		default:
			return createPath(basePathname, _slug);
	}
};

export const getBlogPermalink = () => getPermalink(BLOG_BASE);

export const getHomePermalink = () => {
	const permalink = getPermalink();
	return permalink === '/' ? permalink : `${permalink}/`;
};
