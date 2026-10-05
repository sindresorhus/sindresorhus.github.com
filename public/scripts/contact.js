const email = document.querySelector('#contact-email');
const letters = [...email.querySelectorAll('[data-letter]')];
const prefersReducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

// Letters lift toward the pointer, and the neighbors of a lifted letter follow, like a wave. The styles turn `--strength` into the lift, and the rainbow turns while the pointer is on the page.
if (!prefersReducedMotion) {
	const radius = 155;

	// The centers of the letters at rest, in page coordinates, so scrolling does not move them. They are measured when the fonts and the entrance animation are done, and when the layout changes.
	let centers = [];

	const measure = () => {
		centers = letters.map(letter => {
			const rect = letter.getBoundingClientRect();
			return {x: rect.left + scrollX + (rect.width / 2), y: rect.top + scrollY + (rect.height / 2)};
		});
	};

	document.fonts.ready.then(measure);
	email.closest('section').addEventListener('animationend', measure);
	new ResizeObserver(measure).observe(email);

	const lift = (pointerX, pointerY) => {
		const nearness = centers.map(({x, y}) => {
			const proximity = Math.max(0, 1 - (Math.hypot(pointerX - x, pointerY - y) / radius));
			// Squared for a softer edge.
			return proximity * proximity;
		});

		const strengths = [...nearness];

		for (const [index, value] of nearness.entries()) {
			if (value < 0.01) {
				continue;
			}

			for (const [distance, share] of [[1, 0.55], [2, 0.28], [3, 0.1]]) {
				for (const neighbor of [index - distance, index + distance]) {
					if (neighbor >= 0 && neighbor < letters.length) {
						strengths[neighbor] = Math.max(strengths[neighbor], value * share);
					}
				}
			}
		}

		for (const [index, letter] of letters.entries()) {
			const strength = strengths[index] > 0.005 ? strengths[index] : 0;
			letter.toggleAttribute('data-leaving', strength === 0);
			letter.style.setProperty('--strength', strength);
		}
	};

	// The address tilts toward the pointer, and eases there every frame.
	const tilt = {x: 0, y: 0};
	const targetTilt = {x: 0, y: 0};
	let tiltFrame = 0;

	const animateTilt = () => {
		tilt.x += (targetTilt.x - tilt.x) * 0.09;
		tilt.y += (targetTilt.y - tilt.y) * 0.09;
		email.style.setProperty('--tilt-x', tilt.x);
		email.style.setProperty('--tilt-y', tilt.y);

		if (Math.abs(targetTilt.x - tilt.x) >= 0.02 || Math.abs(targetTilt.y - tilt.y) >= 0.02) {
			tiltFrame = requestAnimationFrame(animateTilt);
		}
	};

	const setTilt = (x, y) => {
		targetTilt.x = x;
		targetTilt.y = y;
		cancelAnimationFrame(tiltFrame);
		tiltFrame = requestAnimationFrame(animateTilt);
	};

	let liftFrame = 0;

	document.addEventListener('mousemove', event => {
		email.dataset.rainbow = '';

		cancelAnimationFrame(liftFrame);
		liftFrame = requestAnimationFrame(() => {
			lift(event.pageX, event.pageY);
		});

		const rect = email.getBoundingClientRect();
		const horizontal = (event.clientX - rect.left - (rect.width / 2)) / (rect.width * 0.6);
		const vertical = (event.clientY - rect.top - (rect.height / 2)) / (rect.height * 3);
		setTilt(Math.max(-6, Math.min(6, vertical * -10)), Math.max(-10, Math.min(10, horizontal * 14)));
	});

	document.addEventListener('mouseleave', () => {
		delete email.dataset.rainbow;

		cancelAnimationFrame(liftFrame);
		liftFrame = requestAnimationFrame(() => {
			lift(Number.NEGATIVE_INFINITY, Number.NEGATIVE_INFINITY);
		});

		setTilt(0, 0);
	});

	// Sparkles fly out from a click on the address.
	const sparkleTemplate = document.querySelector('#sparkle-template');

	email.addEventListener('click', event => {
		for (let index = 0; index < 26; index++) {
			const sparkle = sparkleTemplate.content.firstElementChild.cloneNode(true);
			const angle = ((index / 26) * Math.PI * 2) + (Math.random() * 0.35);
			const distance = 55 + (Math.random() * 110);

			sparkle.style.setProperty('--start-x', `${event.clientX}px`);
			sparkle.style.setProperty('--start-y', `${event.clientY}px`);
			sparkle.style.setProperty('--x', `${Math.cos(angle) * distance}px`);
			sparkle.style.setProperty('--y', `${Math.sin(angle) * distance}px`);
			sparkle.style.setProperty('--size', `${4 + (Math.random() * 8)}px`);
			sparkle.style.setProperty('--mix', `${Math.random() * 100}%`);
			document.body.append(sparkle);

			setTimeout(() => {
				sparkle.remove();
			}, 800);
		}
	});
}

// The subject and body in the URL go to the email link, and are removed from the visible URL.
{
	const parameters = new URLSearchParams(location.search);

	// Encoded with `encodeURIComponent`, as mail apps read a `+` in a mailto link as a plus, not a space.
	const query = ['subject', 'body']
		.filter(key => parameters.has(key))
		.map(key => `${key}=${encodeURIComponent(parameters.get(key))}`)
		.join('&');

	if (query) {
		email.href = `${email.href.split('?')[0]}?${query}`;
	}

	const pageURL = new URL(location.href);
	pageURL.searchParams.delete('subject');
	pageURL.searchParams.delete('body');
	history.replaceState({}, '', pageURL);
}
