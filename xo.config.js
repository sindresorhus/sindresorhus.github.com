import astro from 'eslint-plugin-astro';

const xoConfig = [
	{
		ignores: [
			'source/content.config.ts',
			'**/*.md',
			'**/*.css',
		],
	},
	...astro.configs.recommended,
	{
		rules: {
			'unicorn/filename-case': 'off',
			'unicorn/text-encoding-identifier-case': 'off',
			'unicorn/prevent-abbreviations': 'off',
			'n/file-extension-in-import': 'off',
			'@stylistic/operator-linebreak': 'off',
			'@stylistic/max-len': 'off',
			'@stylistic/jsx-quotes': [
				'error',
				'prefer-double',
			],
		},
	},
	{
		files: [
			'**/*.astro',
		],
		rules: {
			'@stylistic/indent': 'off',
			'@stylistic/indent-binary-ops': 'off',
			// The autofix cannot indent the result, because indentation is not checked in templates.
			'@stylistic/multiline-ternary': 'off',
		},
	},
];

export default xoConfig;
