const feedbackId = 'feedback';

const getText = node =>
	node.type === 'text' ? node.value : (node.children?.map(getText).join('') ?? '');

/**
Remark plugin: injects the feedback FAQ heading and default paragraph into each app's FAQ section.
*/
export default function remarkInjectFeedbackFaq() {
	return (tree, file) => {
		const {title, platforms} = file.data.astro?.frontmatter ?? {};
		if (!title || !platforms) {
			return;
		}

		const {children} = tree;

		const faqIndex = children.findIndex(node =>
			node.type === 'heading' && node.depth === 2 && getText(node).includes('Frequently Asked Questions'),
		);
		if (faqIndex === -1) {
			return;
		}

		const nextH2Index = children.findIndex((node, i) => i > faqIndex && node.type === 'heading' && node.depth === 2);
		const sectionEnd = nextH2Index === -1 ? children.length : nextH2Index;

		const feedbackUrl = `https://sindresorhus.com/feedback?product=${encodeURIComponent(title)}&referrer=Website-FAQ`;

		const defaultParagraph = {
			type: 'paragraph',
			children: [
				{type: 'text', value: 'Click the feedback button in the app or '},
				{type: 'link', url: feedbackUrl, children: [{type: 'text', value: 'send it here.'}]},
			],
		};

		const feedbackIndex = children.findIndex((node, i) =>
			i > faqIndex
			&& i < sectionEnd
			&& node.type === 'heading'
			&& node.depth === 4
			&& getText(node).toLowerCase().includes('feature request'),
		);

		if (feedbackIndex === -1) {
			children.splice(faqIndex + 1, 0,
				{
					type: 'heading',
					depth: 4,
					data: {id: feedbackId, hProperties: {id: feedbackId}},
					children: [{type: 'text', value: 'I have a feature request, bug report, or some feedback'}],
				},
				defaultParagraph,
			);
		} else {
			const heading = children[feedbackIndex];
			heading.data ??= {};
			heading.data.id = feedbackId;
			heading.data.hProperties ??= {};
			heading.data.hProperties.id = feedbackId;
			children.splice(feedbackIndex + 1, 0, defaultParagraph);
		}
	};
}
