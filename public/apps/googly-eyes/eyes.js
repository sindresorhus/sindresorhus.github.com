// Draws pupils on the app icon that follow the pointer, or roll around on touch screens.
// Only the core measurements
const CONSTANTS = {
	EYE: {
		DIAMETER: 70,
		TOP: 94,
		LEFT: {
			LEFT_EYE: 71,
			RIGHT_EYE: 153
		}
	},
	PUPIL: {
		SIZE: 20
	}
};

// Derived measurements
const EYE_RADIUS = CONSTANTS.EYE.DIAMETER / 2;
// Maximum travel is eye radius minus pupil radius to keep pupil fully inside
const MAX_PUPIL_TRAVEL = EYE_RADIUS - (CONSTANTS.PUPIL.SIZE / 2);

// Replace the image source
const icon = document.querySelector('#app-icon');
icon.src = '/apps/googly-eyes/icon-no-pupils.png';

// Create and position pupils
const container = document.createElement('div');
container.style.cssText = `
	position: relative;
	width: ${icon.width}px;
	height: ${icon.height}px;
	display: inline-block;
`;

// The app page tilts the group, so the pupils tilt with the icon.
container.dataset.appIconGroup = '';

icon.parentNode.insertBefore(container, icon);
container.appendChild(icon);

// Debug bounds
const createEyeBound = (left) => {
	const eyeBound = document.createElement('div');
	eyeBound.style.cssText = `
		position: absolute;
		width: ${CONSTANTS.EYE.DIAMETER}px;
		height: ${CONSTANTS.EYE.DIAMETER}px;
		border: 2px solid rgba(255, 0, 0, 0.5);
		background: rgba(255, 0, 0, 0.1);
		border-radius: 50%;
		top: ${CONSTANTS.EYE.TOP}px;
		left: ${left}px;
		transform: translate(-50%, -50%);
		pointer-events: none;
	`;
	return eyeBound;
};

const leftEyeBound = createEyeBound(CONSTANTS.EYE.LEFT.LEFT_EYE);
const rightEyeBound = createEyeBound(CONSTANTS.EYE.LEFT.RIGHT_EYE);

// Debug.
// container.appendChild(leftEyeBound);
// container.appendChild(rightEyeBound);

const createPupil = (left) => {
	const pupil = document.createElement('div');
	pupil.style.cssText = `
		position: absolute;
		width: ${CONSTANTS.PUPIL.SIZE}px;
		height: ${CONSTANTS.PUPIL.SIZE}px;
		background: black;
		border-radius: 50%;
		top: ${CONSTANTS.EYE.TOP}px;
		left: ${left}px;
		transform: translate(-50%, -50%);
		pointer-events: none;
	`;
	return pupil;
};

const leftPupil = createPupil(CONSTANTS.EYE.LEFT.LEFT_EYE);
const rightPupil = createPupil(CONSTANTS.EYE.LEFT.RIGHT_EYE);

container.appendChild(leftPupil);
container.appendChild(rightPupil);

// Check if it's a touch device
const isTouchDevice = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0);

if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
	// The pupils stay centered.
} else if (isTouchDevice) {
	const leftSpeed = 2 + Math.random() * 2;
	const rightSpeed = 2 + Math.random() * 2;

	// Keyframes for touch devices, where the pupils roll around.
	const style = document.createElement('style');
	document.head.append(style);

	style.textContent = `
		@keyframes rollLeftEye {
			0% { transform: translate(-50%, -50%) rotate(0deg) translate(${MAX_PUPIL_TRAVEL}px) rotate(0deg); }
			100% { transform: translate(-50%, -50%) rotate(360deg) translate(${MAX_PUPIL_TRAVEL}px) rotate(-360deg); }
		}
		@keyframes rollRightEye {
			0% { transform: translate(-50%, -50%) rotate(0deg) translate(${MAX_PUPIL_TRAVEL}px) rotate(0deg); }
			100% { transform: translate(-50%, -50%) rotate(-360deg) translate(${MAX_PUPIL_TRAVEL}px) rotate(360deg); }
		}
	`;

	leftPupil.style.animation = `rollLeftEye ${leftSpeed}s linear infinite`;
	rightPupil.style.animation = `rollRightEye ${rightSpeed}s linear infinite`;
} else {
	let isFirstMove = true;

	function updatePupils(mouseX, mouseY) {
		const rect = container.getBoundingClientRect();

		for (const [index, pupil] of [leftPupil, rightPupil].entries()) {
			const eyeX = rect.left + (index === 0 ? CONSTANTS.EYE.LEFT.LEFT_EYE : CONSTANTS.EYE.LEFT.RIGHT_EYE);
			const eyeY = rect.top + CONSTANTS.EYE.TOP;

			// Vector from eye to mouse
			let x = mouseX - eyeX;
			let y = mouseY - eyeY;

			const distance = Math.sqrt(x * x + y * y);
			if (distance > MAX_PUPIL_TRAVEL) {
				const angle = Math.atan2(y, x);
				x = Math.cos(angle) * MAX_PUPIL_TRAVEL;
				y = Math.sin(angle) * MAX_PUPIL_TRAVEL;
			}

			pupil.style.transform = `translate(calc(-50% + ${x}px), calc(-50% + ${y}px))`;
		}
	}

	const centerX = container.getBoundingClientRect().left + (CONSTANTS.EYE.LEFT.LEFT_EYE + CONSTANTS.EYE.LEFT.RIGHT_EYE) / 2;
	const centerY = container.getBoundingClientRect().top + CONSTANTS.EYE.TOP;
	updatePupils(centerX, centerY);

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
}
