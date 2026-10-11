// The galaxy of the home page is only for dark mode and for visitors who allow motion, so other visitors do not download it. It also loads when the visitor switches to dark mode. The reduced motion setting is read once, like on the rest of the site.
if (!matchMedia('(prefers-reduced-motion: reduce)').matches) {
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
