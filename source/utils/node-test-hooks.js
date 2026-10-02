/*
Lets `node --test` import modules that use the `astro:content` virtual module and the `~/` alias.
*/
import {registerHooks} from 'node:module';

const sourceDirectory = new URL('../', import.meta.url);

registerHooks({
	resolve(specifier, context, nextResolve) {
		if (specifier === 'astro:content') {
			return {
				url: 'data:text/javascript,export const getCollection = () => []; export const render = () => {};',
				shortCircuit: true,
			};
		}

		const resolvedSpecifier = specifier.startsWith('~/') ? new URL(specifier.slice(2), sourceDirectory).href : specifier;
		return nextResolve(resolvedSpecifier, context);
	},
});
