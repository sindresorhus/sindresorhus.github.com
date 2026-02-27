import {readFileSync} from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import satori from 'satori';
import {Resvg} from '@resvg/resvg-js';
import {fetchApps} from '~/utils/apps.js';

// Load fonts once at module level (shared across all static paths in the same build)
// satori uses opentype.js which supports WOFF but not WOFF2
const interRegular = readFileSync(path.join(process.cwd(), 'node_modules/@fontsource/inter/files/inter-latin-400-normal.woff'));
const interBold = readFileSync(path.join(process.cwd(), 'node_modules/@fontsource/inter/files/inter-latin-700-normal.woff'));

export const getStaticPaths = async () => {
	const apps = await fetchApps({includeArchived: true, includeUnlisted: true});
	return apps.map(app => ({
		params: {slug: app.slug},
		props: {app},
	}));
};

export const GET = async ({props}) => {
	const {app} = props;

	// Load icon as base64 data URL
	let iconDataUrl = '';
	try {
		const iconBuffer = readFileSync(path.join(process.cwd(), 'public', app.iconUrl.slice(1)));
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

	const svg = await satori(element, {
		width: 1200,
		height: 630,
		fonts: [
			{
				name: 'Inter', data: interRegular, weight: 400, style: 'normal',
			},
			{
				name: 'Inter', data: interBold, weight: 700, style: 'normal',
			},
		],
	});

	return new Response(new Resvg(svg).render().asPng(), {
		headers: {'Content-Type': 'image/png'},
	});
};
