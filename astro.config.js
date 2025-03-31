import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {defineConfig} from 'astro/config';
import sitemap from '@astrojs/sitemap';
import remarkCustomHeaderId from 'remark-custom-header-id';
import tailwindcss from '@tailwindcss/vite';
/// import rehypeAutolinkHeadings from 'rehype-autolink-headings';
import {SITE} from './source/config.mjs';

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
	legacy: {
		// TODO: https://docs.astro.build/en/guides/upgrade-to/v5/#enabling-the-legacycollections-flag
		collections: true,
	},
});
