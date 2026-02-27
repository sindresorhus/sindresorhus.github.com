/**
Remark plugin that extracts `<!-- @namespace.attribute value -->` directives from HTML comments immediately following a heading with a custom ID.

Multiple directives can annotate the same heading by placing them on consecutive lines. The plugin looks back past other directives to find the nearest preceding heading.

Example:

```md
### The app does not show up in the menu bar {#app-not-showing-in-menu-bar}
<!-- @faq.keywords launching launch start open opening -->
<!-- @faq.platforms macOS -->
```

Result injected into file.data.astro.frontmatter.headingMeta:
{
	'app-not-showing-in-menu-bar': {
		faq: {
			keywords: ['launching', 'launch', 'start', 'open', 'opening'], platforms: ['macOS']
		}
	}
}
*/

const directiveRegex = /^<!--\s*@(\w+)\.(\w+)\s+(.*?)\s*-->$/s;

function findPrecedingHeading(children, fromIndex) {
	for (let i = fromIndex - 1; i >= 0; i--) {
		const node = children[i];
		if (node.type === 'heading') {
			return node;
		}

		// Skip over other directives; stop at anything else
		if (node.type !== 'html' || !directiveRegex.test(node.value)) {
			return null;
		}
	}

	return null;
}

export default function remarkHeadingMeta() {
	return function (tree, file) {
		const meta = {};

		for (let i = 0; i < tree.children.length; i++) {
			const node = tree.children[i];
			if (node.type !== 'html') {
				continue;
			}

			const match = directiveRegex.exec(node.value);
			if (!match) {
				continue;
			}

			const heading = findPrecedingHeading(tree.children, i);
			if (!heading?.data?.id) {
				continue;
			}

			const [, namespace, attribute, value] = match;
			const {id} = heading.data;
			meta[id] ??= {};
			meta[id][namespace] ??= {};
			meta[id][namespace][attribute] = value.trim().split(/\s+/);
		}

		if (Object.keys(meta).length > 0) {
			file.data.astro ??= {};
			file.data.astro.frontmatter ??= {};
			file.data.astro.frontmatter.headingMeta = meta;
		}
	};
}
