import colors from 'tailwindcss/colors.js';
import typography from '@tailwindcss/typography';
import forms from '@tailwindcss/forms';

const config = {
	content: ['./source/**/*.{astro,html,js,jsx,md,svelte,ts,tsx,vue}'],
	theme: {
		extend: {
			colors: {
				primary: colors.blue,
				secondary: colors.pink,
			},
		},
	},
	plugins: [
		typography,
		forms,
	],
};

export default config;
