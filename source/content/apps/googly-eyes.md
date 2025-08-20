---
title: Googly Eyes
subtitle: Watchful eyes in your menu bar
pubDate: 2025-03-12
platforms:
  - macOS
isMenuBarApp: true
appStoreId: 6743048714
# olderMacOSVersions:
#   - '15'
---

Add playful eyes to your menu bar that follow your cursor and blink when you click. Pure whimsy! 👀

## Frequently Asked Questions {#faq}

#### I have a feature request, bug report, or some feedback

Click the feedback button in the app or [send it here.](https://sindresorhus.com/feedback?product=Googly%20Eyes&referrer=Website-FAQ)

#### The app does not show up in the menu bar

[Try this](/apps/faq#app-not-showing-in-menu-bar)

#### Why is it using a lot of CPU?

The app is optimized as much as possible, but macOS is inefficient at updating menu bar items. Also, make sure you know how to [interpret CPU usage](/apps/faq#high-cpu).

#### [More FAQs…](/apps/faq)

<!-- ## Older Versions

- []() for macOS 15+ -->

## Non-App Store Version

A special version for users that cannot access the App Store. It won't receive automatic updates. I will update it here once a year.

[Download](https://www.dropbox.com/scl/fi/pyxs34muy524a1irxtn05/Googly-Eyes-1.1.1-1742015870.zip?rlkey=k4sn2jq9xmmvqrd3kxdb0gb5l&raw=1) *(1.1.1)*

*Requires macOS 15 or later*

<script type="module" is:inline>
// Only the core measurements
const CONSTANTS = {
	EYE: {
		DIAMETER: 60,
		TOP: 96,
		LEFT: {
			LEFT_EYE: 74,
			RIGHT_EYE: 151
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
const img = document.querySelector('img[src$="icon.png"]');
img.src = '/apps/googly-eyes/icon-no-pupils.png';

// Create and position pupils
const container = document.createElement('div');
container.style.cssText = `
	position: relative;
	width: ${img.width}px;
	height: ${img.height}px;
	display: inline-block;
`;

img.parentNode.insertBefore(container, img);
container.appendChild(img);

// Add keyframes for touch devices
const style = document.createElement('style');
style.textContent = `
	@keyframes rollEyes {
		0% { transform: translate(-50%, -50%) rotate(0deg) translate(${MAX_PUPIL_TRAVEL}px) rotate(0deg); }
		25% { transform: translate(-50%, -50%) rotate(90deg) translate(${MAX_PUPIL_TRAVEL}px) rotate(-90deg); }
		50% { transform: translate(-50%, -50%) rotate(180deg) translate(${MAX_PUPIL_TRAVEL}px) rotate(-180deg); }
		75% { transform: translate(-50%, -50%) rotate(270deg) translate(${MAX_PUPIL_TRAVEL}px) rotate(-270deg); }
		100% { transform: translate(-50%, -50%) rotate(360deg) translate(${MAX_PUPIL_TRAVEL}px) rotate(-360deg); }
	}
`;
document.head.appendChild(style);

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
	`;
	return pupil;
};

const leftPupil = createPupil(CONSTANTS.EYE.LEFT.LEFT_EYE);
const rightPupil = createPupil(CONSTANTS.EYE.LEFT.RIGHT_EYE);

container.appendChild(leftPupil);
container.appendChild(rightPupil);

// Check if it's a touch device
const isTouchDevice = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0);

if (isTouchDevice) {
	const leftSpeed = 2 + Math.random() * 2;
	const rightSpeed = 2 + Math.random() * 2;

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

	document.addEventListener('mousemove', (e) => {
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

		updatePupils(e.clientX, e.clientY);
	});
}
</script>
