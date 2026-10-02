import assert from 'node:assert/strict';
import {test} from 'node:test';
import {getIntroductionText} from './apps.js';

test('getIntroductionText returns the first paragraph as plain text', () => {
	assert.equal(getIntroductionText('Use [Dato](/dato) to see the **date** with `npx`.\n\n## Heading'), 'Use Dato to see the date with npx.');
});

test('getIntroductionText collapses whitespace and line breaks', () => {
	assert.equal(getIntroductionText('Line one\nline two  \nline three\\\nline   four'), 'Line one line two line three line four');
});

test('getIntroductionText ignores HTML comments before the paragraph', () => {
	assert.equal(getIntroductionText('<!-- Hidden. -->\n\n<!-- Also hidden. -->\nVisible.'), 'Visible.');
});

test('getIntroductionText returns undefined when the document does not start with a paragraph', () => {
	assert.equal(getIntroductionText('## Heading\n\nParagraph.'), undefined);
	assert.equal(getIntroductionText('<br>\n\nParagraph.'), undefined);
	assert.equal(getIntroductionText('![Screenshot](screenshot.png)\n\nParagraph.'), undefined);
	assert.equal(getIntroductionText('<!-- Only a comment. -->'), undefined);
	assert.equal(getIntroductionText(''), undefined);
});
