// Draws pupils on the app icon that follow the pointer, or roll around on touch screens.
// The measurements are fractions of the width of the icon image, so they work at any size of the icon.
const EYE = {
	DIAMETER: 0.365,
	TOP: 0.406,
	LEFT: {
		LEFT_EYE: 0.286,
		RIGHT_EYE: 0.714
	}
};

const PUPIL_SIZE = 0.104;

// Replace the image source
const icon = document.querySelector('#app-icon');
icon.src = '/apps/googly-eyes/icon-no-pupils.png';

// The pupils are positioned in a box around the icon, in percent of its size, so they follow the size of the icon.
const container = document.createElement('div');
container.style.cssText = `
	position: relative;
	display: inline-block;
`;

icon.parentNode.insertBefore(container, icon);
container.appendChild(icon);

// The farthest a pupil moves from the center of its eye, so it stays inside the eye, in fractions of the width of the icon.
const PUPIL_TRAVEL = (EYE.DIAMETER - PUPIL_SIZE) / 2;

// Debug bounds
const createEyeBound = left => {
	const eyeBound = document.createElement('div');
	eyeBound.style.cssText = `
		position: absolute;
		width: ${EYE.DIAMETER * 100}%;
		aspect-ratio: 1;
		border: 2px solid rgba(255, 0, 0, 0.5);
		background: rgba(255, 0, 0, 0.1);
		border-radius: 50%;
		top: ${EYE.TOP * 100}%;
		left: ${left * 100}%;
		transform: translate(-50%, -50%);
		pointer-events: none;
	`;
	return eyeBound;
};

const leftEyeBound = createEyeBound(EYE.LEFT.LEFT_EYE);
const rightEyeBound = createEyeBound(EYE.LEFT.RIGHT_EYE);

// Debug.
// container.appendChild(leftEyeBound);
// container.appendChild(rightEyeBound);

const createPupil = left => {
	const pupil = document.createElement('div');
	pupil.style.cssText = `
		position: absolute;
		width: ${PUPIL_SIZE * 100}%;
		aspect-ratio: 1;
		top: ${EYE.TOP * 100}%;
		left: ${left * 100}%;
		background: black;
		border-radius: 50%;
		transform: translate(-50%, -50%);
		pointer-events: none;
	`;
	return pupil;
};

const leftPupil = createPupil(EYE.LEFT.LEFT_EYE);
const rightPupil = createPupil(EYE.LEFT.RIGHT_EYE);
const pupils = [[leftPupil, EYE.LEFT.LEFT_EYE], [rightPupil, EYE.LEFT.RIGHT_EYE]];

container.appendChild(leftPupil);
container.appendChild(rightPupil);

if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
	// The pupils stay centered.
} else if (matchMedia('(hover: hover) and (pointer: fine)').matches) {
	let isFirstMove = true;

	function updatePupils(mouseX, mouseY) {
		const rect = icon.getBoundingClientRect();
		const travel = rect.width * PUPIL_TRAVEL;

		for (const [pupil, left] of pupils) {
			const eyeX = rect.left + (left * rect.width);
			const eyeY = rect.top + (EYE.TOP * rect.width);

			// Vector from eye to mouse
			let x = mouseX - eyeX;
			let y = mouseY - eyeY;

			const distance = Math.sqrt(x * x + y * y);
			if (distance > travel) {
				const angle = Math.atan2(y, x);
				x = Math.cos(angle) * travel;
				y = Math.sin(angle) * travel;
			}

			pupil.style.transform = `translate(calc(-50% + ${x}px), calc(-50% + ${y}px))`;
		}
	}

	// Until the pointer moves, the pupils look at each other.
	const rect = icon.getBoundingClientRect();
	updatePupils(rect.left + (((EYE.LEFT.LEFT_EYE + EYE.LEFT.RIGHT_EYE) / 2) * rect.width), rect.top + (EYE.TOP * rect.width));

	document.addEventListener('mousemove', event => {
		if (isFirstMove) {
			isFirstMove = false;

			for (const pupil of [leftPupil, rightPupil]) {
				pupil.style.transition = 'transform 0.3s ease-out';
			}

			requestAnimationFrame(() => {
				requestAnimationFrame(() => {
					for (const pupil of [leftPupil, rightPupil]) {
						pupil.style.transition = '';
					}
				});
			});
		}

		updatePupils(event.clientX, event.clientY);
	});
} else {
	// On touch screens, the pupils roll around the eyes, in opposite directions and at different speeds. The travel is in percent of the pupil, so it follows the size of the icon.
	const travel = `${PUPIL_TRAVEL / PUPIL_SIZE * 100}%`;

	for (const [pupil, direction] of [[leftPupil, 1], [rightPupil, -1]]) {
		pupil.animate([
			{transform: `translate(-50%, -50%) rotate(0deg) translate(${travel}) rotate(0deg)`},
			{transform: `translate(-50%, -50%) rotate(${360 * direction}deg) translate(${travel}) rotate(${-360 * direction}deg)`},
		], {
			duration: (2 + Math.random() * 2) * 1000,
			iterations: Number.POSITIVE_INFINITY,
		});
	}
}
