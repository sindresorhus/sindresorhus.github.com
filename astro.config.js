import process from 'node:process';
import fs from 'node:fs';
import https from 'node:https';
import tls from 'node:tls';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {defineConfig} from 'astro/config';
import sitemap from '@astrojs/sitemap';
import remarkCustomHeaderId from 'remark-custom-header-id';
import remarkGitHubAlerts from 'remark-github-blockquote-alert';
import tailwindcss from '@tailwindcss/vite';
import {icons as tablerIconData} from '@iconify-json/tabler';
import rehypeRaw from 'rehype-raw';
import remarkHeadingMeta from './source/utils/remark-heading-meta.js';
import remarkInjectFeedbackFaq from './source/utils/remark-inject-feedback-faq.js';
import rehypeKbdSeparator from './source/utils/rehype-kbd-separator.js';
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

/*
Work around Socket Firewall (sfw) breaking fetch() during builds.
sfw sets NODE_EXTRA_CA_CERTS for its MITM proxy CA, but Node's built-in
fetch (undici) does not pick it up when the env var is set after startup.
We fall back to node:https (which supports explicit CA) for HTTPS requests.
*/
{
	const certPath = process.env.NODE_EXTRA_CA_CERTS;
	const cert = certPath && fs.existsSync(certPath)
		? fs.readFileSync(certPath, 'utf8')
		: undefined;

	if (cert) {
		const ca = [...tls.rootCertificates, cert];
		const previousFetch = globalThis.fetch;

		globalThis.fetch = async (input, init) => {
			const url = typeof input === 'string' ? input : (input instanceof URL ? input.href : input.url);

			if (!url?.startsWith('https://')) {
				return previousFetch(input, init);
			}

			return new Promise((resolve, reject) => {
				const parsedUrl = new URL(url);
				const agent = new https.Agent({ca});
				const request = https.get({
					hostname: parsedUrl.hostname,
					path: parsedUrl.pathname + parsedUrl.search,
					headers: {
						'User-Agent': 'node',
						...Object.fromEntries(new Headers(init?.headers).entries()),
					},
					agent,
				}, response => {
					const chunks = [];
					response.on('data', chunk => chunks.push(chunk));
					response.on('end', () => {
						resolve(new Response(Buffer.concat(chunks).toString(), {
							status: response.statusCode,
							headers: response.headers,
						}));
						agent.destroy();
					});
				});
				request.on('error', reject);
			});
		};
	}
}

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
			remarkHeadingMeta,
			remarkInjectFeedbackFaq,
		],
		rehypePlugins: [
			// Astro runs rehype-raw after user plugins, so inline HTML stays as opaque `raw` nodes when our plugins run. Running it first converts them to proper hast elements.
			rehypeRaw,
			rehypeKbdSeparator,
			// TODO
			// rehypeHeadingIds,
			// [rehypeAutolinkHeadings, {behavior: 'wrap'}],
		],
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
