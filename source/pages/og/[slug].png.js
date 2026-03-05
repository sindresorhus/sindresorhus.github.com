import process from 'node:process';
import fs from 'node:fs';
import {createHash} from 'node:crypto';
import path from 'node:path';
import satori from 'satori';
import {Resvg} from '@resvg/resvg-js';
import {fetchApps} from '~/utils/apps.js';

// Bump when changing the OG image template to invalidate the cache.
const TEMPLATE_VERSION = '1';

const rootDirectory = process.cwd();

// Satori uses opentype.js which supports WOFF but not WOFF2
const interRegular = fs.readFileSync(path.join(rootDirectory, 'node_modules/@fontsource/inter/files/inter-latin-400-normal.woff'));
const interBold = fs.readFileSync(path.join(rootDirectory, 'node_modules/@fontsource/inter/files/inter-latin-700-normal.woff'));

const fonts = [
	{
		name: 'Inter', data: interRegular, weight: 400, style: 'normal',
	},
	{
		name: 'Inter', data: interBold, weight: 700, style: 'normal',
	},
];

const cacheDirectory = path.join(rootDirectory, '.cache', 'og');
fs.mkdirSync(cacheDirectory, {recursive: true});

async function generateOgImage(app) {
	const iconPath = path.join(rootDirectory, 'public', app.iconUrl.slice(1));

	let iconMtime = '';
	try {
		iconMtime = fs.statSync(iconPath).mtimeMs.toString();
	} catch (error) {
		if (error.code !== 'ENOENT') {
			throw error;
		}
	}

	const hash = createHash('md5')
		.update(TEMPLATE_VERSION)
		.update(app.title)
		.update(app.subtitle ?? '')
		.update(iconMtime)
		.digest('hex');

	const cachePath = path.join(cacheDirectory, `${hash}.png`);

	// Return cached version if available.
	try {
		return fs.readFileSync(cachePath);
	} catch (error) {
		if (error.code !== 'ENOENT') {
			throw error;
		}
	}

	// Load icon as base64 data URL
	let iconDataUrl = '';
	try {
		const iconBuffer = fs.readFileSync(iconPath);
		iconDataUrl = `data:image/png;base64,${iconBuffer.toString('base64')}`;
	} catch (error) {
		if (error.code !== 'ENOENT') {
			throw error;
		}
	}

	const element = {
		type: 'div',
		props: {
			style: {
				width: '1200px',
				height: '630px',
				display: 'flex',
				alignItems: 'center',
				padding: '80px',
				background: 'linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%)',
				fontFamily: 'Inter',
			},
			children: [
				iconDataUrl && {
					type: 'img',
					props: {
						src: iconDataUrl,
						width: 200,
						height: 200,
						style: {
							borderRadius: '46px',
							boxShadow: '0 20px 60px rgba(0,0,0,0.15)',
							marginRight: '64px',
							flexShrink: 0,
						},
					},
				},
				{
					type: 'div',
					props: {
						style: {
							display: 'flex',
							flexDirection: 'column',
							minWidth: 0,
						},
						children: [
							{
								type: 'div',
								props: {
									style: {
										fontSize: '68px',
										fontWeight: 700,
										color: '#0f172a',
										lineHeight: 1.1,
										marginBottom: '20px',
									},
									children: app.title,
								},
							},
							{
								type: 'div',
								props: {
									style: {
										fontSize: '32px',
										fontWeight: 400,
										color: '#64748b',
										lineHeight: 1.4,
									},
									children: app.subtitle,
								},
							},
							{
								type: 'div',
								props: {
									style: {
										fontSize: '22px',
										fontWeight: 700,
										color: '#94a3b8',
										marginTop: '48px',
									},
									children: 'sindresorhus.com',
								},
							},
						],
					},
				},
			].filter(Boolean),
		},
	};

	const svg = await satori(element, {width: 1200, height: 630, fonts});
	const png = new Resvg(svg).render().asPng();

	fs.writeFileSync(cachePath, png);

	return png;
}

export async function getStaticPaths() {
	const apps = await fetchApps({includeArchived: true, includeUnlisted: true});

	return Promise.all(
		apps.map(async app => ({
			params: {slug: app.slug},
			props: {png: await generateOgImage(app)},
		})),
	);
}

export async function GET({props}) {
	return new Response(props.png, {
		headers: {'Content-Type': 'image/png'},
	});
}
