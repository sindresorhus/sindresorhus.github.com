// The galaxy of the home page is only for dark mode and for visitors who allow motion, so other visitors do not download it. It also loads when the visitor switches to dark mode.
const query = matchMedia('(prefers-color-scheme: dark) and (prefers-reduced-motion: no-preference)');

const load = () => {
	if (query.matches) {
		query.removeEventListener('change', load);
		import('./nebula.js');
	}
};

query.addEventListener('change', load);
load();
