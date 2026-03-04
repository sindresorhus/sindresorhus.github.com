import assert from 'node:assert/strict';
import {test} from 'node:test';
import {unified} from 'unified';
import remarkParse from 'remark-parse';
import {VFile} from 'vfile';
import remarkInjectFeedbackFaq from './remark-inject-feedback-faq.js';

const appFrontmatter = {title: 'My App', platforms: ['macOS']};

const process = async (markdown, frontmatter = appFrontmatter) => {
	const file = new VFile({value: markdown});
	file.data.astro = {frontmatter};
	const processor = unified().use(remarkParse).use(remarkInjectFeedbackFaq);
	const tree = processor.parse(file);
	await processor.run(tree, file);
	return tree;
};

const getText = node =>
	node.type === 'text' ? node.value : (node.children?.map(getText).join('') ?? '');

const getFaqSection = tree => {
	const faqIndex = tree.children.findIndex(n =>
		n.type === 'heading' && n.depth === 2 && getText(n).includes('Frequently Asked Questions'),
	);
	if (faqIndex === -1) {
		return [];
	}

	const nextH2 = tree.children.findIndex((n, i) => i > faqIndex && n.type === 'heading' && n.depth === 2);
	return tree.children.slice(faqIndex + 1, nextH2 === -1 ? undefined : nextH2);
};

const faqMd = `
## Frequently Asked Questions

#### Some question

Some answer.
`.trim();

const faqWithFeedbackMd = `
## Frequently Asked Questions

#### I have a feature request, bug report, or some feedback

Custom note.
`.trim();

test('skips non-app files (no platforms)', async () => {
	const section = getFaqSection(await process(faqMd, {title: 'My App'}));
	assert.equal(getText(section[0]), 'Some question');
});

test('skips files with no FAQ section', async () => {
	const tree = await process('## Other Section\n\nContent.');
	assert.equal(tree.children.length, 2);
});

test('injects feedback heading first in FAQ section with correct id', async () => {
	const section = getFaqSection(await process(faqMd));
	assert.equal(getText(section[0]), 'I have a feature request, bug report, or some feedback');
	assert.equal(section[0].data.id, 'feedback');
	assert.equal(section[0].data.hProperties.id, 'feedback');
});

test('injected paragraph has the correct feedback URL', async () => {
	const section = getFaqSection(await process(faqMd));
	assert.equal(section[1].children[1].url, 'https://sindresorhus.com/feedback?product=My%20App&referrer=Website-FAQ');
});

test('when heading already exists, sets id and prepends default paragraph before custom content', async () => {
	const section = getFaqSection(await process(faqWithFeedbackMd));
	assert.equal(section.filter(n => n.type === 'heading' && getText(n).includes('feature request')).length, 1);
	assert.equal(section[0].data.id, 'feedback');
	assert.match(getText(section[1]), /Click the feedback button/);
	assert.match(getText(section[2]), /Custom note/);
});

test('does not inject beyond the FAQ section boundary', async () => {
	const md = `
## Frequently Asked Questions

#### Some question

Answer.

## Other Section

Content.
`.trim();

	const tree = await process(md);
	const section = getFaqSection(tree);
	assert.ok(section.some(n => getText(n).includes('feature request')));

	const otherIndex = tree.children.findIndex(n => getText(n) === 'Other Section');
	assert.ok(tree.children.slice(otherIndex).every(n => !getText(n).includes('feature request')));
});
