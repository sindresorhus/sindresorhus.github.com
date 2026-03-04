/**
Rehype plugin that splits `<kbd>Command+A</kbd>` into `<kbd>Command</kbd> + <kbd>A</kbd>`.

Any `<kbd>` whose text content contains `+` is split on `+`. A trailing `+` (e.g. `<kbd>Command+</kbd>`) becomes a literal `<kbd>+</kbd>` key node, so the Plus key can be expressed naturally as `<kbd>Command+</kbd>`.
*/

const makeSeparator = () => ({
	type: 'element',
	tagName: 'span',
	properties: {className: ['kbd-sep'], ariaHidden: 'true'},
	children: [{type: 'text', value: '+'}],
});

const makeKbd = text => ({
	type: 'element',
	tagName: 'kbd',
	properties: {},
	children: [{type: 'text', value: text}],
});

function walk(node) {
	if (!node.children) {
		return;
	}

	const newChildren = [];

	for (const child of node.children) {
		walk(child);

		if (child.type !== 'element' || child.tagName !== 'kbd') {
			newChildren.push(child);
			continue;
		}

		const text = child.children[0]?.value ?? '';

		if (!text.includes('+')) {
			newChildren.push(child);
			continue;
		}

		// A trailing `+` in the source (e.g. `Command+`) means the Plus key.
		// After splitting "Command+" we get ["Command", ""] — turn the empty
		// string into a "+" key so it renders as <kbd>+</kbd>.
		const nodes = text
			.split('+')
			.map((part, index, parts) => (part === '' && index === parts.length - 1 ? '+' : part))
			.flatMap((key, index) => (index === 0 ? [makeKbd(key)] : [makeSeparator(), makeKbd(key)]));

		newChildren.push(...nodes);
	}

	node.children = newChildren;
}

export default function rehypeKbdSeparator() {
	return walk;
}
