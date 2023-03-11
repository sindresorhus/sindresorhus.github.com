import {SITE} from '~/config.mjs';

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

export const APPS_BASE = 'apps';
export const BLOG_BASE = 'blog';
export const POST_BASE = 'blog';
export const TAG_BASE = 'blog/tag';

export const getPermalink = (slug = '', type = 'page') => {
	switch (type) {
		case 'tag': {
			return createPath(basePathname, TAG_BASE, slug);
		}

		case 'post': {
			return createPath(basePathname, POST_BASE, slug);
		}

		case 'page': // eslint-disable-line unicorn/no-useless-switch-case
		default: {
			return createPath(basePathname, slug);
		}
	}
};
