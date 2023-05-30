import {defineCollection, z} from 'astro:content';

const appsCollection = defineCollection({
	schema: z.object({
		draft: z.boolean().optional(),
		unlisted: z.boolean().optional(),
		title: z.string().nonempty(),
		subtitle: z.string().nonempty(),
		pubDate: z.date(),
		platforms: z.array(z.enum([
			'macOS',
			'iOS',
			'watchOS',
			'tvOS',
			'visionOS',
			'Linux',
			'Windows',
		])),
		repoUrl: z.string().url().optional(),
		appStoreId: z.number().optional(),
		setappUrl: z.string().url().optional(),
		isPaid: z.boolean().optional(),
		links: z.record(z.string().url()).optional(),
		showSupportLink: z.boolean().optional(),
		redirectUrl: z.string().url().optional(),
	}).strict(),
});

const blogCollection = defineCollection({
	schema: z.object({
		draft: z.boolean().optional(),
		unlisted: z.boolean().optional(),
		title: z.string().nonempty(),
		description: z.string().nonempty().optional(),
		pubDate: z.date(),
		tags: z.array(z.enum([
			'open-source',
			'javascript',
		])).optional(),
		redirectUrl: z.string().url().optional(),
	}).strict(),
});

export const collections = {
	apps: appsCollection,
	blog: blogCollection,
};
