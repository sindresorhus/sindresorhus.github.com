import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {defineConfig} from 'astro/config';
import sitemap from '@astrojs/sitemap';
import remarkCustomHeaderId from 'remark-custom-header-id';
import remarkGitHubAlerts from 'remark-github-blockquote-alert';
import tailwindcss from '@tailwindcss/vite';
import {icons as tablerIconData} from '@iconify-json/tabler';
/// import rehypeAutolinkHeadings from 'rehype-autolink-headings';
import {SITE} from './source/config.mjs';

// Patch fetch to serve Iconify icons from local @iconify-json packages, enabling offline dev.
const originalFetch = globalThis.fetch;
globalThis.fetch = async (input, init) => {
	let url;
	if (typeof input === 'string') {
		url = input;
	} else if (input instanceof URL) {
		url = input.href;
	} else {
		url = input.url;
	}

	const match = url.match(/^https:\/\/api\.iconify\.design\/(\w+)\.json/);
	if (match) {
		const localPacks = {tabler: tablerIconData};
		const pack = localPacks[match[1]];
		if (pack) {
			return new Response(JSON.stringify(pack), {
				headers: {'Content-Type': 'application/json'},
			});
		}
	}

	return originalFetch(input, init);
};

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// https://astro.build/config
export default defineConfig({
	site: SITE.origin,
	srcDir: './source',
	output: 'static',
	trailingSlash: 'never',
	build: {
		format: 'file',
	},
	redirects: {
		'/thanks': '/supporters',
		'/lock-screen-one': '/any-text',
	},
	integrations: [
		sitemap(),
	],
	markdown: {
		remarkPlugins: [
			remarkCustomHeaderId,
			remarkGitHubAlerts,
		],
		// TODO
		// rehypePlugins: [
		// 	rehypeHeadingIds,
		// 	[rehypeAutolinkHeadings, {behavior: 'wrap'}],
		// ]
	},
	vite: {
		resolve: {
			alias: {
				'~': path.resolve(__dirname, './source'),
			},
		},
		plugins: [
			tailwindcss(),
		],
	},
});
