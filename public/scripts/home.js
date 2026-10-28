import {prefersReducedMotion} from '/scripts/dom.js';

// The galaxy of the home page is only for dark mode and for visitors who allow motion, so other visitors do not download it. It also loads when the visitor switches to dark mode.
if (!prefersReducedMotion) {
	const darkMode = matchMedia('(prefers-color-scheme: dark)');

	const load = () => {
		if (darkMode.matches) {
			darkMode.removeEventListener('change', load);
			import('./nebula.js');
		}
	};

	darkMode.addEventListener('change', load);
	load();
}
