import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {defineConfig} from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';
import remarkCustomHeaderId from 'remark-custom-header-id';
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
		tailwind({
			applyBaseStyles: false,
		}),
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
	},
});
