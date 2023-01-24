import {defineCollection, z} from 'astro:content';

const appsCollection = defineCollection({
	schema: z.object({
		draft: z.boolean().optional(),
		title: z.string().nonempty(),
		subtitle: z.string().nonempty(),
		date: z.date(),
		platforms: z.array(z.enum([
			'macOS',
			'iOS',
			'watchOS',
			'tvOS',
			'macOS (Apple silicon)',
			'Linux',
			'Windows',
		])),
		repoUrl: z.string().url().optional(),
		appStoreId: z.number().optional(),
		setappUrl: z.string().url().optional(),
		isPaid: z.boolean().optional(),
		links: z.record(z.string().url()).optional(),
		showSupportLink: z.boolean().optional(),
	}).strict(),
});

export const collections = {
	apps: appsCollection,
};
