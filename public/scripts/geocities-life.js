// The living page of 1999: the desktop pets that live all over the page (Neko, Dolly the sheep, the sparrows and the seagull, the mouse, the UFO, and the bookworm). They only run while the tab is visible, and nothing moves for visitors who prefer reduced motion: the pets stand still and answer when poked.
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');

// Like `geocities.js`, the pets wait until the visitor opens a page that the site prerendered.
if (document.prerendering) {
	await new Promise(resolve => {
		document.addEventListener('prerenderingchange', resolve, {once: true});
	});
}

const panel = document.querySelector('#geocities-panel');

const showToast = message => {
	document.dispatchEvent(new CustomEvent('geocities-toast', {detail: {message}}));
};

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// The storage can be missing, like in a private window, and then the toys start over each time.
const load = (key, fallback) => {
	try {
		const value = localStorage.getItem(key);
		return value === null ? fallback : (JSON.parse(value) ?? fallback);
	} catch {
		return fallback;
	}
};

const save = (key, value) => {
	try {
		localStorage.setItem(key, JSON.stringify(value));
	} catch {}
};

// Sets the text of a status message a frame after it changed, so screen readers announce it also when the text is the same as before.
const announce = (element, message) => {
	element.textContent = '';
	requestAnimationFrame(() => {
		element.textContent = message;
	});
};

// Makes a canvas with a sprite of big pixels, from rows of letters where each letter is a color of the palette, and any other letter, like a dot, is clear. Short rows are clear at the end.
const makeSprite = (rows, palette, scale = 1) => {
	const width = Math.max(...rows.map(row => row.length));
	const canvas = document.createElement('canvas');
	canvas.width = width * scale;
	canvas.height = rows.length * scale;
	const context = canvas.getContext('2d');

	for (const [y, row] of rows.entries()) {
		for (const [x, letter] of [...row].entries()) {
			if (palette[letter]) {
				context.fillStyle = palette[letter];
				context.fillRect(x * scale, y * scale, scale, scale);
			}
		}
	}

	return canvas;
};

// The same sprite, facing the other way.
const mirrorSprite = sprite => {
	const canvas = document.createElement('canvas');
	canvas.width = sprite.width;
	canvas.height = sprite.height;
	const context = canvas.getContext('2d');
	context.translate(sprite.width, 0);
	context.scale(-1, 1);
	context.drawImage(sprite, 0, 0);
	return canvas;
};

// A sprite that faces right, and its mirror, which faces left.
const makeFacingSprite = (rows, palette, scale) => {
	const right = makeSprite(rows, palette, scale);
	return {right, left: mirrorSprite(right)};
};

// Sindre’s Desktop Pets: the pets that live all over the page, with their control panel. The pets on the windows, Dolly, the sparrows, and the bookworm, live in a layer that scrolls with the page, and stand on the top edges of the sections. The pets on the glass, Neko, the yarn, the mouse, and the UFO, live in a layer that stays on the screen. With motion, one loop of frames moves them all. For visitors who prefer reduced motion, a slow timer makes them appear, disappear, and change their pose instead, without moving.
const petsRoot = document.querySelector('#geocities-pets');

if (petsRoot) {
	const petStatus = document.querySelector('#geocities-pets-status');
	const pageLayer = document.querySelector('#geocities-pets-page-layer').content.firstElementChild.cloneNode(true);
	const screenLayer = document.querySelector('#geocities-pets-screen-layer').content.firstElementChild.cloneNode(true);
	const critterTemplate = document.querySelector('#geocities-pets-critter');
	const bubbleTemplate = document.querySelector('#geocities-pets-bubble');
	document.body.append(pageLayer, screenLayer);

	const petIDs = ['neko', 'sheep', 'birds', 'mouse', 'ufo', 'worm'];
	const settings = load('geocities-pets', {});
	settings.sheepCount = clamp(Math.floor(Number(settings.sheepCount) || 1), 1, 8);
	const stats = {pets: 0, naps: 0, chases: 0, crumbs: 0, stolen: 0, cheese: 0, abducted: 0, rescued: 0, holes: 0, fixed: 0, ...load('geocities-pets-stats', {})};
	const isOn = id => settings[id] !== false;
	const toggles = Object.fromEntries(petIDs.map(id => [id, petsRoot.querySelector(`[data-critter-toggle="${id}"]`)]));
	const counts = Object.fromEntries(petIDs.map(id => [id, petsRoot.querySelector(`[data-critter-count="${id}"]`)]));
	const isStill = () => reducedMotion.matches;

	// The size and the scroll of the window, the height of the page, and the places of the basket and of the GIF of the UFO, read at once at the start of each frame, before the pets move. Reading them after a pet moved would make the browser lay out the page again in the middle of the frame. A click or a drag reads them again, as the visitor can scroll between frames.
	const view = {left: scrollX, top: scrollY, width: innerWidth, height: innerHeight, pageHeight: 0};

	const readView = () => {
		view.left = scrollX;
		view.top = scrollY;
		view.width = innerWidth;
		view.height = innerHeight;
		view.pageHeight = document.documentElement.scrollHeight;
		view.basketRect = basket.getBoundingClientRect();
		view.ufoTarget = ufo.target;
		view.ufoRect = ufo.target?.getBoundingClientRect();
	};

	// The pointer, in the coordinates of the screen. A finger counts where it touches, so Neko follows taps, along the bottom of the screen.
	const pointer = {x: view.width / 2, y: view.height / 2, lastMove: 0, isTouch: matchMedia('(pointer: coarse)').matches};

	const trackPointer = event => {
		pointer.x = event.clientX;
		pointer.y = event.clientY;
		pointer.lastMove = performance.now();
		pointer.isTouch = event.pointerType !== 'mouse';
	};

	document.addEventListener('pointermove', trackPointer, {passive: true});
	document.addEventListener('pointerdown', trackPointer, {passive: true});

	// A pet is a canvas in one of the layers, which shows one sprite at a time.
	const createCritter = (layer, width, height) => {
		const element = critterTemplate.content.firstElementChild.cloneNode(true);
		const canvas = document.createElement('canvas');
		canvas.width = width;
		canvas.height = height;
		element.append(canvas);
		layer.append(element);
		return {element, context: canvas.getContext('2d'), width, height, sprite: undefined};
	};

	const showSprite = (critter, sprite) => {
		if (critter.sprite === sprite) {
			return;
		}

		critter.sprite = sprite;
		critter.context.clearRect(0, 0, critter.width, critter.height);
		critter.context.drawImage(sprite, 0, 0);
	};

	// Puts a pet with the middle of its feet at the point.
	const placeCritter = (critter, x, y) => {
		critter.element.style.translate = `${Math.round(x - (critter.width / 2))}px ${Math.round(y - critter.height)}px`;
	};

	// A speech bubble above a pet for a moment, like “Mæ!”.
	const sayBubble = (critter, text, seconds = 1.6) => {
		critter.bubble?.remove();
		const bubble = bubbleTemplate.content.firstElementChild.cloneNode(true);
		bubble.textContent = text;
		bubble.style.translate = `calc(${critter.width / 2}px - 50%) calc(-100% - 4px)`;
		critter.element.append(bubble);
		critter.bubble = bubble;

		setTimeout(() => {
			if (critter.bubble === bubble) {
				bubble.remove();
				critter.bubble = undefined;
			}
		}, seconds * 1000);
	};

	// The pet that the pointer or a finger holds now.
	let heldElement;

	// A pet that the pointer or a finger picks up, drags, and drops. A press without dragging pokes it.
	const makeDraggable = (element, {onPoke, onPickUp, onMove, onDrop}) => {
		let start;
		let isDragging = false;

		element.addEventListener('pointerdown', event => {
			event.preventDefault();
			element.setPointerCapture(event.pointerId);
			readView();
			start = {x: event.clientX, y: event.clientY};
			isDragging = false;
			heldElement = element;
		});

		element.addEventListener('pointermove', event => {
			if (!start) {
				return;
			}

			if (!isDragging && Math.hypot(event.clientX - start.x, event.clientY - start.y) > 6) {
				isDragging = true;
				onPickUp();
			}

			if (isDragging) {
				onMove(event.clientX, event.clientY);
			}
		});

		const end = event => {
			if (!start) {
				return;
			}

			const wasDragging = isDragging;
			start = undefined;
			isDragging = false;
			heldElement = undefined;
			readView();

			if (wasDragging) {
				onDrop();
			} else if (event.type === 'pointerup') {
				onPoke();
			}
		};

		element.addEventListener('pointerup', end);
		element.addEventListener('pointercancel', end);
	};

	let saveTimer;

	const showCounts = () => {
		counts.neko.textContent = `Petted ${stats.pets} times ★ Naps: ${stats.naps} ★ Mice chased: ${stats.chases}`;
		counts.sheep.textContent = flock.length === 0 ? 'Sheep: none. They are under the desk.' : `Sheep: ${flock.length} (${flock.map(sheep => sheep.name).join(', ')})`;
		counts.birds.textContent = `Crumbs eaten: ${stats.crumbs} ★ Stolen by seagulls: ${stats.stolen}`;
		counts.mouse.textContent = `Slices of brown cheese eaten: ${stats.cheese}`;
		counts.ufo.textContent = `GIFs beamed up: ${stats.abducted} ★ Rescued: ${stats.rescued}`;
		counts.worm.textContent = `Holes eaten: ${stats.holes} ★ Fixed: ${stats.fixed}`;

		clearTimeout(saveTimer);
		saveTimer = setTimeout(() => {
			save('geocities-pets-stats', stats);
		}, 1000);
	};

	const count = name => {
		stats[name]++;
		showCounts();
	};

	// The top edges of the windows and the other sections of the page, in the coordinates of the page, where the pets on the windows stand. Only the outer sections count, so the pets stand in the gaps between the windows. On a box inside a window, like a card or a canvas, a pet would cover the buttons and the text right above it, and take their clicks. A toy that is a custom element (its tag name has a hyphen) counts like a section, as its root was a section before, so the windows inside it do not count, unless it has no box of its own. Finding the sections reads their styles, so it happens now and then, and the page changes as the visitor plays, so their places are measured more often.
	let platformElements = [];
	let platforms = [];
	let platformsFoundAt = Number.NEGATIVE_INFINITY;

	const findPlatformElements = () => {
		platformsFoundAt = performance.now();
		platformElements = [];

		// Only goes into the elements that are not platforms, so it does not visit the inside of each window.
		const findIn = parent => {
			for (const element of parent.children) {
				if (element.localName !== 'section' && !element.localName.includes('-')) {
					findIn(element);
					continue;
				}

				const style = getComputedStyle(element);

				// A toy without a box of its own, like the fortune toys, is not a platform, but its sections are.
				if (style.display === 'contents') {
					findIn(element);
					continue;
				}

				const borderWidth = style.borderTopStyle === 'none' ? 0 : Number.parseFloat(style.borderTopWidth) || 0;
				platformElements.push({element, borderWidth});
			}
		};

		findIn(panel);
	};

	const measurePlatforms = () => {
		if (performance.now() - platformsFoundAt > 15_000) {
			findPlatformElements();
		}

		platforms = [];

		for (const {element, borderWidth} of platformElements) {
			const rect = element.getBoundingClientRect();

			if (rect.width < 140 || rect.height < 40) {
				continue;
			}

			platforms.push({left: rect.left + view.left, right: rect.right + view.left, top: rect.top + view.top, hasBorder: borderWidth >= 2, borderWidth});
		}
	};

	// The platforms in the window, below the toolbar of the browser at the top.
	const isInView = platform => platform.top > view.top + 110 && platform.top < view.top + view.height - 60;
	const visiblePlatforms = () => platforms.filter(platform => isInView(platform));

	// The platform nearest to the middle of the window, for when the visitor is inside a tall window, like the one of the pets, where no top edge is in view.
	const nearestPlatform = (items = platforms) => {
		const middle = view.top + (view.height / 2);
		return items.toSorted((first, second) => Math.abs(first.top - middle) - Math.abs(second.top - middle))[0];
	};

	// Where to look for something on a platform that is not in view.
	const whereIs = platform => {
		if (isInView(platform)) {
			return '';
		}

		return platform.top < view.top + 110 ? ' Scroll up to see it.' : ' Scroll down to see it.';
	};

	const platformAt = (x, top) => platforms.find(platform => platform.left + 6 <= x && x <= platform.right - 6 && Math.abs(platform.top - top) < 30);

	// The first platform that a pet falling at the x from the y lands on.
	const landingBetween = (x, fromY, toY) => {
		let landing;

		for (const platform of platforms) {
			if (platform.left + 6 <= x && x <= platform.right - 6 && fromY <= platform.top && platform.top <= toY && (!landing || platform.top < landing.top)) {
				landing = platform;
			}
		}

		return landing;
	};

	// MARK: Neko

	// Where each pose of Neko is on its sheet, in steps of 32 pixels, from oneko.js. Each pose has one or two frames.
	const nekoPoses = {
		idle: [[-3, -3]],
		alert: [[-7, -3]],
		scratchSelf: [[-5, 0], [-6, 0], [-7, 0]],
		scratchWallN: [[0, 0], [0, -1]],
		scratchWallS: [[-7, -1], [-6, -2]],
		scratchWallE: [[-2, -2], [-2, -3]],
		scratchWallW: [[-4, 0], [-4, -1]],
		tired: [[-3, -2]],
		sleeping: [[-2, 0], [-2, -1]],
		N: [[-1, -2], [-1, -3]],
		NE: [[0, -2], [0, -3]],
		E: [[-3, 0], [-3, -1]],
		SE: [[-5, -1], [-5, -2]],
		S: [[-6, -3], [-7, -2]],
		SW: [[-5, -3], [-6, -1]],
		W: [[-4, -2], [-4, -3]],
		NW: [[-1, 0], [-1, -1]],
	};

	const basket = document.querySelector('#geocities-pets-basket');
	const basketImage = basket.querySelector('img');
	const nekoElement = document.querySelector('#geocities-pets-neko').content.firstElementChild.cloneNode(true);
	const nekoImage = nekoElement.querySelector('img');
	const nekoCritter = {element: nekoElement, width: 32, height: 32};
	const homeButton = petsRoot.querySelector('[data-critter-action="neko-home"]');
	screenLayer.append(nekoElement);

	const neko = {x: 48, y: view.height - 64, state: 'home', frameCount: 0, idleTime: 0, idleAnimation: undefined, idleAnimationFrame: 0, velocity: 0, clock: 0, homeTime: 0};

	const showNekoPose = (image, name, frame = 0) => {
		const poses = nekoPoses[name];
		const [x, y] = poses[frame % poses.length];
		image.style.translate = `${x * 32}px ${y * 32}px`;
	};

	const placeNeko = () => {
		nekoElement.style.translate = `${Math.round(neko.x - 16)}px ${Math.round(neko.y - 16)}px`;
	};

	// The pointer can be prey, like in NekoDA of 1989, which made Neko run faster.
	const preySelect = document.querySelector('#geocities-pets-prey');
	const root = document.querySelector('#geocities-root');

	const nekoTarget = () => {
		if (yarn.isOut) {
			return {x: yarn.x, y: yarn.y - 10};
		}

		if (mouse.state !== 'away' && Math.hypot(mouse.x - neko.x, mouse.floor - neko.y) < 500) {
			return {x: mouse.x, y: mouse.floor - 16};
		}

		// A finger does not rest on the screen like a pointer, so Neko runs along the bottom of the screen under the last tap, where it does not sit on what the visitor reads or taps next.
		if (pointer.isTouch) {
			return {x: pointer.x, y: floorOfScreen() - 16};
		}

		return pointer;
	};

	const startNekoIdle = () => {
		const choices = ['sleeping', 'scratchSelf'];

		// When the pointer rests, Neko mostly sleeps.
		if (performance.now() - pointer.lastMove > 4000) {
			choices.push('sleeping', 'sleeping');
		}

		if (neko.x < 32) {
			choices.push('scratchWallW');
		}

		if (neko.y < 32) {
			choices.push('scratchWallN');
		}

		if (neko.x > view.width - 32) {
			choices.push('scratchWallE');
		}

		if (neko.y > view.height - 32) {
			choices.push('scratchWallS');
		}

		neko.idleAnimation = randomItem(choices);

		if (neko.idleAnimation === 'sleeping') {
			count('naps');
		}
	};

	const nekoIdle = () => {
		neko.idleTime++;
		const isResting = performance.now() - pointer.lastMove > 4000;

		if (neko.idleTime > 10 && !neko.idleAnimation && Math.random() < (isResting ? 1 / 12 : 1 / 200)) {
			startNekoIdle();
		}

		switch (neko.idleAnimation) {
			case 'sleeping': {
				if (neko.idleAnimationFrame < 8) {
					showNekoPose(nekoImage, 'tired');
					break;
				}

				showNekoPose(nekoImage, 'sleeping', Math.floor(neko.idleAnimationFrame / 4));

				// It sleeps until something wakes it, or for about 20 seconds.
				if (neko.idleAnimationFrame > 200) {
					neko.idleAnimation = undefined;
					neko.idleAnimationFrame = 0;
				}

				break;
			}

			case 'scratchWallN':
			case 'scratchWallS':
			case 'scratchWallE':
			case 'scratchWallW':
			case 'scratchSelf': {
				showNekoPose(nekoImage, neko.idleAnimation, neko.idleAnimationFrame);

				if (neko.idleAnimationFrame > 9) {
					neko.idleAnimation = undefined;
					neko.idleAnimationFrame = 0;
				}

				break;
			}

			default: {
				showNekoPose(nekoImage, 'idle');
				return;
			}
		}

		neko.idleAnimationFrame++;
	};

	// The basket in the window of the pets, when it is on the screen.
	const basketPoint = () => {
		const rect = view.basketRect;
		return rect.bottom > 0 && rect.top < view.height ? {x: rect.left + (rect.width / 2), y: rect.top + (rect.height / 2)} : undefined;
	};

	// One step of Neko, ten times a second, like the Neko of 1989: it runs toward its target in eight directions, and when it is there, it sits, scratches, yawns, and sleeps.
	const nekoTick = () => {
		neko.frameCount++;
		let target = nekoTarget();

		if (neko.state === 'going-home') {
			target = basketPoint() ?? {x: -40, y: neko.y};
			neko.homeTime++;

			if (Math.hypot(neko.x - target.x, neko.y - target.y) < 12 || neko.homeTime > 80) {
				putNekoHome();
				return;
			}
		}

		const differenceX = neko.x - target.x;
		const differenceY = neko.y - target.y;
		const distance = Math.hypot(differenceX, differenceY);
		const speed = preySelect.value === 'arrow' ? 10 : 14;

		if (neko.state !== 'going-home' && distance < 48) {
			nekoIdle();
			return;
		}

		neko.idleAnimation = undefined;
		neko.idleAnimationFrame = 0;

		// It was idle, so it looks up first, surprised.
		if (neko.idleTime > 1) {
			showNekoPose(nekoImage, 'alert');
			neko.idleTime = Math.min(neko.idleTime, 7) - 1;
			return;
		}

		let direction = differenceY / distance > 0.5 ? 'N' : '';
		direction += differenceY / distance < -0.5 ? 'S' : '';
		direction += differenceX / distance > 0.5 ? 'W' : '';
		direction += differenceX / distance < -0.5 ? 'E' : '';
		showNekoPose(nekoImage, direction || 'idle', neko.frameCount);

		const step = Math.min(speed, distance);
		neko.x = clamp(neko.x - ((differenceX / distance) * step), neko.state === 'going-home' ? -40 : 16, view.width - 16);
		neko.y = clamp(neko.y - ((differenceY / distance) * step), 16, view.height - 16);
		placeNeko();
	};

	const updateNeko = seconds => {
		if (neko.state === 'roam' || neko.state === 'going-home') {
			neko.clock += seconds;

			while (neko.clock >= 0.1) {
				neko.clock -= 0.1;
				nekoTick();
			}

			return;
		}

		if (neko.state === 'fall') {
			const previousY = neko.y;
			neko.velocity = Math.min(neko.velocity + (1500 * seconds), 900);
			neko.y += neko.velocity * seconds;
			const landing = landingBetween(neko.x + view.left, previousY + 16 + view.top, neko.y + 16 + view.top);
			const floor = view.height - 48;

			if (landing || neko.y >= floor) {
				neko.y = landing ? landing.top - view.top - 16 : floor;
				neko.state = 'roam';
				neko.idleTime = 8;
				showNekoPose(nekoImage, 'alert');
				sayBubble(nekoCritter, 'Mrrp!', 1);
			}

			placeNeko();
		}
	};

	const showNekoHome = isHome => {
		basket.dataset.state = isHome ? 'home' : 'out';
		nekoElement.hidden = isHome;
		homeButton.textContent = isHome ? 'Call Neko' : 'Send Neko to the basket';
	};

	const putNekoHome = () => {
		neko.state = 'home';
		showNekoHome(true);
	};

	const callNeko = () => {
		const point = basketPoint();
		neko.x = point?.x ?? 24;
		neko.y = point?.y ?? view.height - 64;
		neko.state = 'roam';
		neko.idleTime = 8;
		neko.idleAnimation = undefined;
		showNekoPose(nekoImage, 'alert');
		placeNeko();
		showNekoHome(false);
	};

	const sendNekoHome = () => {
		if (neko.state === 'home') {
			return;
		}

		if (isStill()) {
			putNekoHome();
			return;
		}

		neko.state = 'going-home';
		neko.homeTime = 0;
		neko.idleTime = 0;
	};

	const petNeko = () => {
		count('pets');
		const wasAsleep = neko.idleAnimation === 'sleeping';

		if (neko.state === 'home') {
			// In the basket, Neko wakes up for a moment.
			basket.dataset.state = 'awake';
			showNekoPose(basketImage, 'alert');
			announce(petStatus, 'Neko woke up in the basket, looked at you, and went back to sleep. Purrr.');

			setTimeout(() => {
				if (neko.state === 'home') {
					basket.dataset.state = 'home';
					basketImage.style.translate = '';
				}
			}, 2000);
			return;
		}

		if (wasAsleep) {
			neko.idleAnimation = undefined;
			neko.idleAnimationFrame = 0;
			neko.idleTime = 6;
			showNekoPose(nekoImage, 'alert');
		}

		sayBubble(nekoCritter, wasAsleep ? 'Mrrp?' : '♥ Purrr ♥');
		announce(petStatus, wasAsleep ? 'You woke Neko up. Mrrp?' : 'Neko purrs. ♥');
	};

	makeDraggable(nekoElement, {
		onPoke: petNeko,
		onPickUp() {
			neko.state = 'drag';
			// Held up by the neck, it hangs and stretches, like when it scratches a wall.
			showNekoPose(nekoImage, 'scratchWallN');
			sayBubble(nekoCritter, 'Mrrraow!', 1.2);
		},
		onMove(x, y) {
			neko.x = clamp(x, 16, view.width - 16);
			neko.y = clamp(y + 12, 16, view.height - 16);
			placeNeko();
		},
		onDrop() {
			neko.velocity = 0;

			if (isStill()) {
				neko.state = 'roam';
				putNekoHome();
				announce(petStatus, 'Neko jumped back into the basket.');
				return;
			}

			neko.state = 'fall';
		},
	});

	// MARK: The yarn

	const yarnSprite = makeSprite([
		'...rrrr...',
		'.rrRrrRrr.',
		'.rRrrRrrr.',
		'rrrRrrrRrr',
		'rRrrrRrrrr',
		'rrrRrrrrRr',
		'rrRrrrRrrr',
		'.rrrRrrrr.',
		'.rrrrrRrr.',
		'...rrrr...',
	], {r: '#e83a5a', R: '#a01a3a'}, 2);

	const yarn = {critter: createCritter(screenLayer, 20, 20), isOut: false, x: 0, y: 0, velocityX: 0, velocityY: 0, angle: 0, life: 0, bats: 0, moves: []};
	showSprite(yarn.critter, yarnSprite);
	yarn.critter.element.hidden = true;

	const placeYarn = () => {
		placeCritter(yarn.critter, yarn.x, yarn.y + 10);
		yarn.critter.element.style.rotate = `${Math.round(yarn.angle)}deg`;
	};

	const throwYarn = () => {
		if (isStill()) {
			announce(petStatus, 'Neko only plays with yarn when things may move on your screen. It sniffs the yarn and goes back to sleep.');
			return;
		}

		if (neko.state === 'home') {
			callNeko();
		}

		yarn.isOut = true;
		yarn.x = randomBetween(view.width * 0.3, view.width * 0.7);
		yarn.y = 40;
		yarn.velocityX = randomBetween(-200, 200);
		yarn.velocityY = 0;
		yarn.life = 0;
		yarn.bats = 0;
		yarn.critter.element.hidden = false;
		placeYarn();
		announce(petStatus, 'You threw a ball of yarn. Neko is VERY interested.');
	};

	const putYarnAway = message => {
		yarn.isOut = false;
		yarn.critter.element.hidden = true;
		announce(petStatus, message);
	};

	const updateYarn = seconds => {
		if (!yarn.isOut || yarn.isHeld) {
			return;
		}

		yarn.life += seconds;
		const floor = view.height - 44;
		yarn.velocityY += 900 * seconds;
		yarn.x += yarn.velocityX * seconds;
		yarn.y += yarn.velocityY * seconds;
		yarn.angle += yarn.velocityX * seconds * 4;

		if (yarn.y > floor) {
			yarn.y = floor;
			yarn.velocityY = Math.abs(yarn.velocityY) < 60 ? 0 : -yarn.velocityY * 0.45;
			yarn.velocityX *= 1 - Math.min(1.5 * seconds, 1);
		}

		if (yarn.x < 10 || yarn.x > view.width - 10) {
			yarn.x = clamp(yarn.x, 10, view.width - 10);
			yarn.velocityX = -yarn.velocityX * 0.6;
		}

		// Neko bats it away when it gets to it.
		if (neko.state === 'roam' && neko.idleAnimation !== 'sleeping' && Math.hypot(neko.x - yarn.x, neko.y - (yarn.y - 10)) < 28) {
			yarn.velocityX = Math.sign(yarn.x - neko.x || 1) * randomBetween(180, 380);
			yarn.velocityY = -randomBetween(250, 450);
			yarn.bats++;

			if (yarn.bats === 3) {
				sayBubble(nekoCritter, 'Mrrrow!', 1);
			}
		}

		if (yarn.bats >= 10 || yarn.life > 30) {
			putYarnAway(yarn.bats >= 10 ? 'Neko unraveled the whole ball of yarn. Mom will not be happy.' : 'The yarn rolled under the sofa. Neko lost interest.');
			return;
		}

		placeYarn();
	};

	// The visitor can pick up the yarn and throw it too.
	makeDraggable(yarn.critter.element, {
		onPoke() {
			yarn.velocityY = -350;
			yarn.velocityX = randomBetween(-250, 250);
		},
		onPickUp() {
			yarn.isHeld = true;
			yarn.moves = [];
		},
		onMove(x, y) {
			yarn.x = x;
			yarn.y = y;
			yarn.moves = [...yarn.moves.slice(-4), {x, y, time: performance.now()}];
			placeYarn();
		},
		onDrop() {
			yarn.isHeld = false;
			const [first, last] = [yarn.moves.at(0), yarn.moves.at(-1)];
			const seconds = first && last ? Math.max((last.time - first.time) / 1000, 0.016) : 1;
			yarn.velocityX = first ? clamp((last.x - first.x) / seconds, -900, 900) : 0;
			yarn.velocityY = first ? clamp((last.y - first.y) / seconds, -900, 900) : 0;
			yarn.life = 0;
		},
	});

	// The pointers of prey, drawn like the sprites. The middle of each is its hot spot.
	const preySprites = {
		mouse: [
			'......dd....',
			'....ggdgg...',
			'..ggggggkgg.',
			'.gggggggggp.',
			'pggggggggg..',
			'p..g...g....',
			'.p..........',
		],
		fish: [
			'......oo...',
			'o...ooooo..',
			'oo.ooooookoo',
			'ooooooooooo',
			'oo.ooooooo.',
			'o...ooooo..',
			'......o....',
		],
		bird: [
			'....dd..',
			'...dbkd.',
			'..bbbbby',
			'dbbbwwb.',
			'.ddwww..',
			'...o.o..',
		],
	};

	const preyPalette = {d: '#555555', g: '#999999', k: '#000000', p: '#ff9999', o: '#ff8c1a', b: '#a0703c', w: '#f0e0c0', y: '#ffaa00'};

	const showPrey = value => {
		const rows = preySprites[value];

		if (!rows) {
			root.style.cursor = '';
			return;
		}

		const sprite = makeSprite(rows, value === 'bird' ? {...preyPalette, d: '#6b4423', o: '#d08040'} : preyPalette, 2);
		root.style.cursor = `url(${sprite.toDataURL()}) ${Math.round(sprite.width / 2)} ${Math.round(sprite.height / 2)}, auto`;
	};

	preySelect.value = preySprites[settings.prey] ? settings.prey : 'arrow';
	showPrey(preySelect.value);

	preySelect.addEventListener('change', () => {
		settings.prey = preySelect.value;
		save('geocities-pets', settings);
		showPrey(preySelect.value);
		announce(petStatus, preySelect.value === 'arrow' ? 'Your pointer is a boring arrow again.' : `Your pointer is a ${preySelect.value} now. Neko is hungry.`);
	});

	// MARK: Dolly the sheep

	const sheepPalette = {k: '#000000', w: '#ffffff', g: '#c8c8c8', G: '#33aa33'};
	const sheepBody = [
		'....kkkk.kkkk.....',
		'..kkwwwwkwwwwkk.kk',
		'.kwwwwwwwwwwwwwkkk',
		'kwwwwwwwwwwwwwkkkk',
		'kwwgwwwwwgwwwwkwkk',
		'kwwwwwwwwwwwwwkkkk',
		'.kwwwgwwwwwgwwkkk.',
		'..kwwwwwwwwwwwk...',
		'...kkkkkkkkkkk....',
	];

	const sheepSprites = {
		walkA: makeFacingSprite([...sheepBody, '...k.k....k.k.....', '...k.k....k.k.....', '..kk.kk..kk.kk....'], sheepPalette, 3),
		walkB: makeFacingSprite([...sheepBody, '....k.k....k.k....', '....k..k...k..k...', '...kk..kk.kk..kk..'], sheepPalette, 3),
		eat: makeFacingSprite([
			'....kkkk.kkkk.....',
			'..kkwwwwkwwwwkk...',
			'.kwwwwwwwwwwwwwk..',
			'kwwwwwwwwwwwwwwk..',
			'kwwgwwwwwgwwwwwk..',
			'kwwwwwwwwwwwwwkkk.',
			'.kwwwgwwwwwgwkkkkk',
			'..kwwwwwwwwwwkkwkk',
			'...kkkkkkkkkkkkkkk',
			'...k.k....k.k..G.G',
			'...k.k....k.k..GGG',
			'..kk.kk..kk.kk.GGG',
		], sheepPalette, 3),
		sleep: makeFacingSprite([
			'..................',
			'..................',
			'..................',
			'..................',
			'....kkkk.kkkk.....',
			'..kkwwwwkwwwwkk.kk',
			'.kwwwwwwwwwwwwwkkk',
			'kwwwwwwwwwwwwwkkkk',
			'kwwgwwwwwgwwwwkkkk',
			'kwwwwwwwwwwwwwkkk.',
			'.kwwwgwwwwwgwwk...',
			'..kkkkkkkkkkkkk...',
		], sheepPalette, 3),
		fall: makeFacingSprite([...sheepBody, '..k..k....k..k....', '.k...k....k...k...', 'k....k....k....k..'], sheepPalette, 3),
	};

	const sheepNames = ['Dolly', 'Polly', 'Molly', 'Megan', 'Morag', 'Bonnie', 'Dolly II', 'Dolly III'];
	const flock = [];

	const drawSheep = sheep => {
		let sprite;

		if (sheep.state === 'walk') {
			sprite = Math.floor(sheep.frameTime * 4) % 2 === 0 ? sheepSprites.walkA : sheepSprites.walkB;
		} else if (sheep.state === 'eat' || sheep.state === 'baa') {
			sprite = sheepSprites.eat;
		} else if (sheep.state === 'sleep') {
			sprite = sheepSprites.sleep;
		} else if (sheep.state === 'fall' || sheep.state === 'drag') {
			sprite = sheepSprites.fall;
		} else {
			sprite = sheepSprites.walkA;
		}

		showSprite(sheep.critter, sheep.direction > 0 ? sprite.right : sprite.left);
		placeCritter(sheep.critter, sheep.x, sheep.y);
	};

	// A sheep that is out of sight drops in at the top of the window, onto a window there, so the visitor always has sheep nearby. Inside a tall window, where no top edge of a window is in view, it waits on the top edge nearest to the view instead.
	const dropIn = sheep => {
		const visible = visiblePlatforms();
		const platform = visible.length > 0 ? randomItem(visible) : nearestPlatform();

		if (!platform) {
			return false;
		}

		sheep.x = randomBetween(platform.left + 20, platform.right - 20);
		sheep.offscreenTime = 0;

		if (isStill() || visible.length === 0) {
			land(sheep, platform);
		} else {
			sheep.y = view.top + 90;
			sheep.state = 'fall';
			sheep.velocity = 0;
		}

		drawSheep(sheep);
		return true;
	};

	const land = (sheep, platform) => {
		sheep.y = platform.top;
		sheep.platform = platform;
		sheep.state = 'walk';
		sheep.timer = randomBetween(3, 7);
	};

	const baa = sheep => {
		sheep.state = 'baa';
		sheep.timer = 1.2;
		sayBubble(sheep.critter, randomItem(['Mæ!', 'Mææææ!', 'Mæ?', 'Bææ!']));
		drawSheep(sheep);

		// Without motion, nothing else changes the pose back.
		if (isStill()) {
			setTimeout(() => {
				if (sheep.state === 'baa') {
					sheep.state = 'walk';
					drawSheep(sheep);
				}
			}, 1200);
		}
	};

	const createSheep = () => {
		const sheep = {critter: createCritter(pageLayer, 54, 36), name: sheepNames[flock.length], x: 0, y: 0, direction: Math.random() < 0.5 ? -1 : 1, state: 'walk', velocity: 0, timer: 3, frameTime: 0, offscreenTime: 0, platform: undefined};
		flock.push(sheep);

		makeDraggable(sheep.critter.element, {
			onPoke() {
				baa(sheep);
				announce(petStatus, `${sheep.name} says mæ. That is Norwegian for baa.`);
			},
			onPickUp() {
				sheep.state = 'drag';
				sayBubble(sheep.critter, 'Mææ?!');
				drawSheep(sheep);
			},
			onMove(x, y) {
				sheep.x = x + view.left;
				sheep.y = y + view.top + 18;
				drawSheep(sheep);
			},
			onDrop() {
				const landing = landingBetween(sheep.x, sheep.y - 30, Number.POSITIVE_INFINITY);

				if (isStill()) {
					if (landing) {
						land(sheep, landing);
					} else if (!dropIn(sheep)) {
						sheep.state = 'walk';
					}
				} else {
					sheep.state = 'fall';
					sheep.velocity = 0;
				}

				drawSheep(sheep);
			},
		});

		if (!dropIn(sheep)) {
			measurePlatforms();
			dropIn(sheep);
		}

		showCounts();
		return sheep;
	};

	const removeFlock = () => {
		for (const sheep of flock) {
			sheep.critter.element.remove();
		}

		flock.length = 0;
		showCounts();
	};

	const updateSheep = (sheep, seconds) => {
		sheep.frameTime += seconds;

		switch (sheep.state) {
			case 'walk': {
				// The window under it moved or closed, so it finds the window it stands on again, or falls.
				const platform = platformAt(sheep.x, sheep.platform?.top ?? sheep.y);

				if (!platform) {
					sheep.state = 'fall';
					sheep.velocity = 0;
					break;
				}

				sheep.platform = platform;
				sheep.y = platform.top;

				// Without motion, a sheep stands where it is, and only changes its pose.
				if (!isStill()) {
					sheep.x += sheep.direction * 24 * seconds;
				}

				if (sheep.x < platform.left + 14 || sheep.x > platform.right - 14) {
					if (Math.random() < 0.6) {
						sheep.direction *= -1;
						sheep.x = clamp(sheep.x, platform.left + 14, platform.right - 14);
					} else {
						// It walks off the edge.
						sheep.x += sheep.direction * 18;
						sheep.state = 'fall';
						sheep.velocity = 0;
						sayBubble(sheep.critter, 'Mææææ!', 1);
					}
				}

				sheep.timer -= seconds;

				if (sheep.timer <= 0) {
					const choice = Math.random();

					if (choice < 0.4) {
						sheep.state = 'eat';
						sheep.timer = randomBetween(2, 3.5);
					} else if (choice < 0.5) {
						sheep.state = 'sleep';
						sheep.timer = randomBetween(3, 5);
					} else {
						sheep.direction = choice < 0.75 ? -sheep.direction : sheep.direction;
						sheep.timer = randomBetween(3, 7);
					}
				}

				break;
			}

			case 'eat':
			case 'sleep':
			case 'baa': {
				sheep.timer -= seconds;

				if (sheep.timer <= 0) {
					sheep.state = 'walk';
					sheep.timer = randomBetween(3, 7);
				}

				break;
			}

			case 'fall': {
				if (isStill()) {
					const landing = landingBetween(sheep.x, sheep.y - 30, Number.POSITIVE_INFINITY);

					if (landing) {
						land(sheep, landing);
					} else {
						dropIn(sheep);
					}

					break;
				}

				const previousY = sheep.y;
				sheep.velocity = Math.min(sheep.velocity + (1100 * seconds), 800);
				sheep.y += sheep.velocity * seconds;
				const landing = landingBetween(sheep.x, previousY, sheep.y);

				if (landing) {
					if (sheep.velocity > 600) {
						sayBubble(sheep.critter, 'Oof!', 1);
					}

					land(sheep, landing);
				} else if (sheep.y > view.pageHeight - 20) {
					dropIn(sheep);
				}

				break;
			}

			default: {
				break;
			}
		}

		const isOnScreen = sheep.y > view.top - 40 && sheep.y < view.top + view.height + 60;
		sheep.offscreenTime = isOnScreen || sheep.state === 'drag' ? 0 : sheep.offscreenTime + seconds;

		if (sheep.offscreenTime > 8) {
			dropIn(sheep);
		}

		drawSheep(sheep);
	};

	const cloneDolly = () => {
		if (flock.length >= sheepNames.length) {
			announce(petStatus, 'The scientists say 8 sheep is enough for one home page.');
			return;
		}

		const sheep = createSheep();
		settings.sheepCount = flock.length;
		save('geocities-pets', settings);
		announce(petStatus, flock.length === 1 ? 'Dolly is back!' : `You cloned Dolly! Say hello to ${sheep.name}.`);
	};

	// MARK: The sparrows and the seagull

	const birdPalette = {d: '#6b4423', b: '#a0703c', w: '#f0e0c0', k: '#000000', y: '#ffaa00', o: '#d08040'};

	const birdSprites = {
		sit: makeFacingSprite(preySprites.bird, birdPalette, 3),
		peck: makeFacingSprite([
			'........',
			'........',
			'..bbbdd.',
			'dbbbbbkd',
			'.ddwwwby',
			'...o.o..',
		], birdPalette, 3),
		flyUp: makeFacingSprite([
			'.d....d.',
			'..d..d..',
			'..dbbdky',
			'dbbwwb..',
			'........',
			'........',
		], birdPalette, 3),
		flyDown: makeFacingSprite([
			'........',
			'........',
			'..bbbbky',
			'dbbwwb..',
			'..d..d..',
			'.d....d.',
		], birdPalette, 3),
	};

	const gullPalette = {w: '#ffffff', g: '#9aa4b0', k: '#000000', y: '#ffcc00'};

	const gullSprites = {
		glide: makeFacingSprite([
			'g.............',
			'gg........gg..',
			'.ggg....ggg...',
			'..gggwwggg....',
			'...wwwwwwwwky.',
			'..wwwwwwww....',
			'.gw...........',
		], gullPalette, 3),
		flap: makeFacingSprite([
			'..............',
			'..............',
			'....gggggg....',
			'..gggwwwwg....',
			'...wwwwwwwwky.',
			'..wwwwwwww....',
			'.gw...........',
		], gullPalette, 3),
	};

	const birds = [];
	const crumbs = [];
	let gull;

	const createBird = () => {
		const bird = {critter: createCritter(pageLayer, 24, 18), x: 0, y: 0, direction: 1, state: 'away', timer: randomBetween(0.5, 5), frameTime: 0, target: undefined, crumb: undefined};
		bird.critter.element.hidden = true;

		bird.critter.element.addEventListener('pointerdown', event => {
			event.preventDefault();
			scareBirds(bird.x, bird.y);
		});

		birds.push(bird);
		return bird;
	};

	const drawBird = bird => {
		bird.critter.element.hidden = bird.state === 'away';

		if (bird.state === 'away') {
			return;
		}

		let sprite = birdSprites.sit;

		if (bird.state === 'arrive' || bird.state === 'leave') {
			sprite = Math.floor(bird.frameTime * 12) % 2 === 0 ? birdSprites.flyUp : birdSprites.flyDown;
		} else if (bird.isPecking) {
			sprite = birdSprites.peck;
		}

		showSprite(bird.critter, bird.direction > 0 ? sprite.right : sprite.left);
		placeCritter(bird.critter, bird.x, bird.y);
	};

	// A bird flies off, away from what scared it, and out of the window.
	const flyAway = (bird, fromX) => {
		if (bird.state === 'away' || bird.state === 'leave') {
			return;
		}

		bird.crumb = undefined;
		bird.direction = bird.x < fromX ? -1 : 1;
		bird.target = {x: bird.x + (bird.direction * randomBetween(250, 450)), y: view.top - 80};
		bird.timer = randomBetween(6, 14);

		if (isStill()) {
			bird.state = 'away';
		} else {
			bird.state = 'leave';
		}

		drawBird(bird);
	};

	const scareBirds = (x, y) => {
		for (const bird of birds) {
			if (Math.hypot(bird.x - x, bird.y - y) < 160) {
				flyAway(bird, x);
			}
		}
	};

	// A bird comes back to a spot on a window in view, or to a crumb.
	const landBird = (bird, spot) => {
		bird.target = spot;

		if (isStill()) {
			bird.x = spot.x;
			bird.y = spot.y;
			bird.state = bird.crumb ? 'eat' : 'perch';
			bird.timer = randomBetween(8, 20);
		} else {
			bird.direction = Math.random() < 0.5 ? -1 : 1;
			bird.x = bird.direction > 0 ? view.left - 30 : view.left + view.width + 30;
			bird.y = view.top + randomBetween(40, 180);
			bird.state = 'arrive';
		}

		drawBird(bird);
	};

	const perchSpot = () => {
		const platform = randomItem(visiblePlatforms());

		if (!platform) {
			return undefined;
		}

		const x = randomBetween(platform.left + 14, platform.right - 14);
		return Math.hypot(x - (pointer.x + view.left), platform.top - (pointer.y + view.top)) < 140 ? undefined : {x, y: platform.top};
	};

	const goToCrumb = bird => {
		const crumb = crumbs.find(item => birds.filter(other => other.crumb === item).length < 2);

		if (!crumb) {
			return false;
		}

		bird.crumb = crumb;
		const spot = {x: crumb.x + randomBetween(-10, 10), y: crumb.y};

		if (bird.state === 'perch' || bird.state === 'eat') {
			if (isStill()) {
				bird.x = spot.x;
				bird.y = spot.y;
				bird.state = 'eat';
			} else {
				bird.target = spot;
				bird.state = 'arrive';
			}
		} else {
			landBird(bird, spot);
		}

		return true;
	};

	const flyTo = (bird, seconds, speed) => {
		const distance = Math.hypot(bird.target.x - bird.x, bird.target.y - bird.y);
		const step = speed * seconds;

		if (Math.abs(bird.target.x - bird.x) > 2) {
			bird.direction = Math.sign(bird.target.x - bird.x);
		}

		if (distance <= step) {
			bird.x = bird.target.x;
			bird.y = bird.target.y;
			return true;
		}

		bird.x += ((bird.target.x - bird.x) / distance) * step;
		bird.y += ((bird.target.y - bird.y) / distance) * step;
		return false;
	};

	const eatCrumb = bird => {
		const {crumb} = bird;

		if (!crumbs.includes(crumb)) {
			bird.crumb = undefined;

			if (!goToCrumb(bird)) {
				bird.state = 'perch';
				bird.timer = randomBetween(5, 12);
			}

			return;
		}

		crumb.bites++;

		if (crumb.bites >= 3) {
			crumb.critter.element.remove();
			crumbs.splice(crumbs.indexOf(crumb), 1);
			count('crumbs');
		}
	};

	const updateBird = (bird, seconds) => {
		bird.frameTime += seconds;
		const pointerX = pointer.x + view.left;
		const pointerY = pointer.y + view.top;

		switch (bird.state) {
			case 'away': {
				bird.timer -= seconds;

				if (bird.timer <= 0 && !goToCrumb(bird)) {
					const spot = perchSpot();

					if (spot) {
						landBird(bird, spot);
					} else {
						bird.timer = randomBetween(2, 5);
					}
				}

				break;
			}

			case 'arrive': {
				if (flyTo(bird, seconds, 220)) {
					bird.state = bird.crumb ? 'eat' : 'perch';
					bird.timer = randomBetween(8, 20);
				}

				break;
			}

			case 'leave': {
				if (flyTo(bird, seconds, 300)) {
					bird.state = 'away';
				}

				break;
			}

			case 'perch':
			case 'eat': {
				// Pecks now and then, and at a crumb all the time.
				const peckRate = bird.state === 'eat' ? 2.5 : 0.6;
				const wasPecking = bird.isPecking;
				bird.isPecking = Math.sin(bird.frameTime * peckRate * Math.PI * 2) > 0.6;

				if (bird.state === 'eat' && bird.isPecking && !wasPecking) {
					eatCrumb(bird);
				}

				if (bird.state === 'perch') {
					bird.timer -= seconds;

					if (bird.timer <= 0) {
						// Birds come and go.
						if (Math.random() < 0.4) {
							flyAway(bird, bird.x - bird.direction);
						} else {
							bird.direction = -bird.direction;
							bird.timer = randomBetween(5, 15);
						}
					}
				}

				if (performance.now() - pointer.lastMove < 2000 && Math.hypot(bird.x - pointerX, bird.y - pointerY) < 75) {
					scareBirds(pointerX, pointerY);
				}

				// The window it sat on moved, like when a window above it closed.
				if (!platformAt(bird.x, bird.y)) {
					flyAway(bird, bird.x);
				}

				break;
			}

			default: {
				break;
			}
		}

		drawBird(bird);
	};

	const crumbSprite = makeSprite(['.cc.', 'cCcc', 'ccCc', '.cc.'], {c: '#e8c890', C: '#b08850'}, 1);

	const throwCrumbs = () => {
		const platform = nearestPlatform();

		if (!platform) {
			return;
		}

		if (crumbs.length >= 18) {
			announce(petStatus, 'There are enough crumbs out already. The sparrows cannot eat that fast.');
			return;
		}

		const centerX = randomBetween(platform.left + 50, platform.right - 50);

		for (let index = 0; index < 6; index++) {
			const critter = createCritter(pageLayer, 4, 4);
			critter.element.style.pointerEvents = 'none';
			showSprite(critter, crumbSprite);
			const crumb = {critter, x: centerX + randomBetween(-40, 40), y: platform.top, bites: 0};
			placeCritter(critter, crumb.x, crumb.y);
			crumbs.push(crumb);
		}

		while (birds.length < 6) {
			createBird();
		}

		for (const bird of birds) {
			if (bird.state !== 'leave' && !bird.crumb) {
				goToCrumb(bird);
			}
		}

		announce(petStatus, `You threw bread crumbs on a window. Here come the sparrows!${whereIs(platform)}`);

		// The seagulls of Bergen steal food, also from sparrows.
		if (!gull && (Math.random() < 0.35 || stats.crumbs > 12 && stats.stolen === 0)) {
			setTimeout(sendGull, 2500);
		}
	};

	const sendGull = () => {
		if (crumbs.length === 0 || gull) {
			return;
		}

		const target = crumbs[0];
		const critter = createCritter(pageLayer, 42, 21);
		critter.element.style.pointerEvents = 'none';
		const fromLeft = Math.random() < 0.5;
		gull = {critter, x: fromLeft ? view.left - 50 : view.left + view.width + 50, y: view.top + 100, direction: fromLeft ? 1 : -1, state: 'swoop', target: {x: target.x, y: target.y}, frameTime: 0};
		sayBubble(critter, 'SKRÆÆÆ!', 2);

		if (isStill()) {
			stealCrumbs();
		}
	};

	const stealCrumbs = () => {
		for (const crumb of crumbs) {
			crumb.critter.element.remove();
		}

		crumbs.length = 0;
		count('stolen');
		scareBirds(gull.target.x, gull.target.y);
		announce(petStatus, 'A seagull from the fish market in Bergen stole all the crumbs! Typical.');

		if (isStill()) {
			gull.critter.element.remove();
			gull = undefined;
			return;
		}

		gull.state = 'leave';
		gull.target = {x: gull.x + (gull.direction * 600), y: view.top - 100};
	};

	const updateGull = seconds => {
		gull.frameTime += seconds;
		const distance = Math.hypot(gull.target.x - gull.x, gull.target.y - (gull.y));
		const step = 320 * seconds;

		if (distance <= step) {
			if (gull.state === 'swoop') {
				stealCrumbs();
			} else {
				gull.critter.element.remove();
				gull = undefined;
				return;
			}
		} else {
			gull.x += ((gull.target.x - gull.x) / distance) * step;
			gull.y += ((gull.target.y - gull.y) / distance) * step;
		}

		const sprite = Math.floor(gull.frameTime * 5) % 2 === 0 ? gullSprites.glide : gullSprites.flap;
		showSprite(gull.critter, gull.direction > 0 ? sprite.right : sprite.left);
		placeCritter(gull.critter, gull.x, gull.y);
	};

	const removeBirds = () => {
		for (const bird of birds) {
			bird.critter.element.remove();
		}

		for (const crumb of crumbs) {
			crumb.critter.element.remove();
		}

		birds.length = 0;
		crumbs.length = 0;
		gull?.critter.element.remove();
		gull = undefined;
	};

	// MARK: The mouse and the brown cheese

	const mousePalette = {d: '#555555', g: '#999999', k: '#000000', p: '#ff9999'};

	const mouseSprites = {
		runA: makeFacingSprite(preySprites.mouse, mousePalette, 2),
		runB: makeFacingSprite([...preySprites.mouse.slice(0, 5), 'p...g.g.....', '.p..........'], mousePalette, 2),
		sniff: makeFacingSprite([
			'......dd.p..',
			'....ggdggg..',
			'..ggggggkg..',
			'.ggggggggg..',
			'pggggggggg..',
			'p..g...g....',
			'.p..........',
		], mousePalette, 2),
	};

	const cheeseRows = [
		'....bbbbbb',
		'..bbllllcb',
		'bbllllcccb',
		'bccccccccb',
		'bccccccccb',
		'bbbbbbbbbb',
	];

	const cheesePalette = {b: '#7a3e12', c: '#c8783a', l: '#e0a060'};

	const mouse = {critter: createCritter(screenLayer, 24, 14), state: 'away', x: 0, floor: 0, direction: 1, timer: randomBetween(20, 40), frameTime: 0, targetX: 0};
	const cheese = {critter: createCritter(screenLayer, 20, 12), isOut: false, x: 0, bites: 0};
	mouse.critter.element.hidden = true;
	cheese.critter.element.hidden = true;
	cheese.critter.element.style.pointerEvents = 'none';

	// The mouse runs on the bottom edge of the window, above the status bar of the browser.
	const floorOfScreen = () => view.height - 30;

	const drawCheese = () => {
		cheese.critter.element.hidden = !cheese.isOut;

		if (!cheese.isOut) {
			return;
		}

		// Each bite takes a slice from the end.
		const rows = cheeseRows.map(row => row.slice(0, row.length - (cheese.bites * 2)));
		cheese.critter.sprite = undefined;
		showSprite(cheese.critter, makeSprite(rows, cheesePalette, 2));
		placeCritter(cheese.critter, cheese.x, floorOfScreen());
	};

	const drawMouse = () => {
		mouse.critter.element.hidden = mouse.state === 'away';

		if (mouse.state === 'away') {
			return;
		}

		let sprite = mouseSprites.sniff;

		if (mouse.state === 'run' || mouse.state === 'flee' || mouse.state === 'leave') {
			sprite = Math.floor(mouse.frameTime * 10) % 2 === 0 ? mouseSprites.runA : mouseSprites.runB;
		}

		showSprite(mouse.critter, mouse.direction > 0 ? sprite.right : sprite.left);
		placeCritter(mouse.critter, mouse.x, mouse.floor);
	};

	const mouseLeaves = (state, direction) => {
		mouse.direction = direction;
		mouse.targetX = direction > 0 ? view.width + 40 : -40;

		if (isStill()) {
			mouse.state = 'away';
			mouse.timer = randomBetween(20, 45);
		} else {
			mouse.state = state;
		}

		drawMouse();
	};

	const mouseComes = () => {
		mouse.floor = floorOfScreen();
		mouse.targetX = cheese.isOut ? cheese.x - 18 : randomBetween(60, view.width - 60);
		mouse.direction = cheese.isOut ? 1 : (Math.random() < 0.5 ? 1 : -1);

		if (isStill()) {
			mouse.x = mouse.targetX;
			mouse.state = cheese.isOut ? 'nibble' : 'sniff';
		} else {
			mouse.x = mouse.direction > 0 ? -30 : view.width + 30;

			if (cheese.isOut && mouse.direction < 0) {
				mouse.targetX = cheese.x + 18;
			}

			mouse.state = 'run';
		}

		mouse.timer = randomBetween(2, 4);
		drawMouse();
	};

	const updateMouse = seconds => {
		mouse.frameTime += seconds;
		mouse.floor = floorOfScreen();

		switch (mouse.state) {
			case 'away': {
				mouse.timer -= seconds;

				if (mouse.timer <= 0) {
					mouseComes();
				}

				return;
			}

			case 'run':
			case 'flee':
			case 'leave': {
				const speed = mouse.state === 'flee' ? 320 : 120;
				const step = speed * seconds;

				if (Math.abs(mouse.targetX - mouse.x) <= step) {
					mouse.x = mouse.targetX;

					if (mouse.state === 'run') {
						mouse.state = cheese.isOut && Math.abs(cheese.x - mouse.x) < 30 ? 'nibble' : 'sniff';
						mouse.timer = randomBetween(1.5, 3);
					} else {
						mouse.state = 'away';
						mouse.timer = randomBetween(25, 60);
					}
				} else {
					mouse.x += Math.sign(mouse.targetX - mouse.x) * step;
				}

				break;
			}

			case 'sniff': {
				mouse.timer -= seconds;

				if (mouse.timer <= 0) {
					if (cheese.isOut) {
						mouseComes();
					} else {
						mouseLeaves('leave', mouse.direction);
					}
				}

				break;
			}

			case 'nibble': {
				mouse.timer -= seconds;

				if (mouse.timer <= 0) {
					mouse.timer = 1;
					cheese.bites++;
					sayBubble(mouse.critter, 'nom', 0.6);

					if (cheese.bites >= 5) {
						cheese.isOut = false;
						cheese.bites = 0;
						count('cheese');
						sayBubble(mouse.critter, 'Mmm!', 1.2);
						announce(petStatus, 'The mouse ate all the brown cheese. It is the best cheese in the world, so no surprise.');
						mouseLeaves('leave', mouse.direction);
					}

					drawCheese();
				}

				break;
			}

			default: {
				break;
			}
		}

		// Neko chases the mouse, which always gets away.
		if (neko.state === 'roam' && mouse.state !== 'flee' && mouse.state !== 'away' && Math.hypot(neko.x - mouse.x, neko.y - mouse.floor) < 44) {
			count('chases');
			sayBubble(mouse.critter, 'SQUEAK!', 1);
			mouseLeaves('flee', mouse.x > neko.x ? 1 : -1);
		}

		drawMouse();
	};

	mouse.critter.element.addEventListener('pointerdown', event => {
		event.preventDefault();
		sayBubble(mouse.critter, 'Eek!', 1);
		mouseLeaves('flee', mouse.x > pointer.x ? 1 : -1);
	});

	const putOutCheese = () => {
		cheese.isOut = true;
		cheese.bites = 0;
		cheese.x = randomBetween(80, view.width - 80);
		drawCheese();

		if (mouse.state === 'away') {
			mouse.timer = Math.min(mouse.timer, isStill() ? 1 : 2);
		} else if (mouse.state === 'sniff') {
			mouseComes();
		}

		announce(petStatus, 'You put a slice of brown cheese at the bottom of the window. Something squeaks.');
	};

	// MARK: The UFO

	const ufoRows = [
		'........cccccccc........',
		'.......cwwccccccc.......',
		'......cccccccccccc......',
		'...kkkkkkkkkkkkkkkkkk...',
		'.kssssssssssssssssssssk.',
		'kssyssrssyssrssyssrssssk',
		'.kssssssssssssssssssssk.',
		'...kkkkkkkkkkkkkkkkkk...',
	];

	const ufoPalette = {c: '#88ffff', w: '#ffffff', k: '#000000', s: '#a0a0b8', y: '#ffff00', r: '#ff3333'};
	const ufoSprites = [makeSprite(ufoRows, ufoPalette, 2), makeSprite(ufoRows, {...ufoPalette, y: '#ff3333', r: '#ffff00'}, 2)];
	const ufo = {critter: createCritter(screenLayer, 48, 16), beam: createCritter(screenLayer, 1, 1), state: 'away', x: 0, y: 0, timer: randomBetween(60, 100), frameTime: 0, target: undefined, carry: undefined};
	const abducted = [];
	ufo.critter.element.hidden = true;
	ufo.beam.element.hidden = true;
	ufo.beam.element.style.pointerEvents = 'none';

	// A GIF of the page in the middle of the window, which the UFO can beam up.
	const findGIF = () => {
		const candidates = [...panel.querySelectorAll('picture > img')].filter(image => {
			const rect = image.getBoundingClientRect();
			return rect.top > 140 && rect.bottom < view.height - 50 && rect.left > 0 && rect.right < view.width && rect.width >= 20 && rect.width <= 260 && rect.height >= 16 && rect.height <= 200 && image.style.visibility !== 'hidden' && image.checkVisibility({visibilityProperty: true});
		});

		return randomItem(candidates);
	};

	const drawBeam = rect => {
		const top = ufo.y + 14;
		const height = clamp(rect.bottom - top, 1, view.height);
		const width = Math.max(rect.width + 24, 48);
		const canvas = ufo.beam.context.canvas;

		if (canvas.width !== width || canvas.height !== height) {
			canvas.width = width;
			canvas.height = height;
			ufo.beam.width = width;
			ufo.beam.height = height;
		}

		const context = ufo.beam.context;
		context.clearRect(0, 0, width, height);
		context.fillStyle = 'rgba(255, 255, 140, 0.45)';
		context.beginPath();
		context.moveTo((width / 2) - 14, 0);
		context.lineTo((width / 2) + 14, 0);
		context.lineTo(width, height);
		context.lineTo(0, height);
		context.closePath();
		context.fill();

		// Stripes that climb up the beam.
		context.fillStyle = 'rgba(255, 255, 255, 0.35)';

		for (let y = (height - ((ufo.frameTime * 60) % 12)); y > 0; y -= 12) {
			context.fillRect(0, y, width, 3);
		}

		ufo.beam.element.style.translate = `${Math.round(ufo.x - (width / 2))}px ${Math.round(top)}px`;
		ufo.beam.element.hidden = false;
	};

	const callUFO = isAsked => {
		if (ufo.state !== 'away') {
			if (isAsked) {
				announce(petStatus, 'The UFO is already here! Zap it!');
			}

			return;
		}

		const target = findGIF();

		if (!target) {
			if (isAsked) {
				announce(petStatus, 'The UFO looked, but there are no GIFs in the middle of your window. Scroll to some GIFs and try again.');
			}

			ufo.timer = randomBetween(20, 40);
			return;
		}

		ufo.target = target;
		ufo.frameTime = 0;
		const rect = target.getBoundingClientRect();
		ufo.y = clamp(rect.top - 90, 20, view.height - 100);

		if (isStill()) {
			ufo.x = rect.left + (rect.width / 2);
			startBeam();
		} else {
			ufo.x = -40;
			ufo.state = 'arrive';
		}

		ufo.critter.element.hidden = false;
		announce(petStatus, 'A UFO is over the page! It wants a GIF. Click the UFO, or press Zap the UFO!');
	};

	const startBeam = () => {
		ufo.state = 'beam';
		ufo.timer = isStill() ? 8 : 4;
		const rect = ufo.target.getBoundingClientRect();
		ufo.target.style.visibility = 'hidden';

		// A copy of the GIF goes up the beam, while the GIF itself is hidden.
		if (!isStill()) {
			const carry = critterTemplate.content.firstElementChild.cloneNode(true);
			const image = ufo.target.cloneNode();
			image.style.visibility = '';
			image.style.width = `${rect.width}px`;
			image.style.height = `${rect.height}px`;
			carry.append(image);
			carry.style.pointerEvents = 'none';
			screenLayer.append(carry);
			ufo.carry = {element: carry, width: rect.width, height: rect.height, startY: rect.top};
		}

		drawBeam(rect);
	};

	const endUFO = () => {
		ufo.carry?.element.remove();
		ufo.carry = undefined;
		ufo.beam.element.hidden = true;
	};

	const zapUFO = () => {
		if (ufo.state !== 'beam' && ufo.state !== 'arrive') {
			announce(petStatus, 'There is no UFO to zap right now. Call it first!');
			return;
		}

		if (ufo.state === 'beam') {
			ufo.target.style.visibility = '';
			count('rescued');
		}

		endUFO();
		sayBubble(ufo.critter, 'ZAP!', 1.2);
		announce(petStatus, ufo.state === 'beam' ? 'ZAP! The UFO dropped the GIF and flew away. You saved it!' : 'ZAP! The UFO flew away before it got anything.');
		leaveUFO('flee');
	};

	const leaveUFO = state => {
		ufo.target = undefined;
		ufo.timer = randomBetween(150, 260);

		if (isStill()) {
			ufo.state = 'away';
			ufo.critter.element.hidden = true;
			return;
		}

		ufo.state = state;
	};

	const updateUFO = seconds => {
		ufo.frameTime += seconds;

		if (ufo.state === 'away') {
			ufo.timer -= seconds;

			if (ufo.timer <= 0 && !document.hidden) {
				callUFO(false);
			}

			return;
		}

		// A GIF that the UFO picked in this frame was not measured at its start yet.
		const rect = view.ufoTarget === ufo.target ? view.ufoRect : ufo.target?.getBoundingClientRect();

		switch (ufo.state) {
			case 'arrive': {
				// The visitor scrolled the GIF away.
				if (rect.bottom < 0 || rect.top > view.height) {
					endUFO();
					leaveUFO('leave');
					break;
				}

				const targetX = rect.left + (rect.width / 2);
				const targetY = clamp(rect.top - 90, 20, view.height - 100);
				const distance = Math.hypot(targetX - ufo.x, targetY - ufo.y);
				const step = 240 * seconds;

				if (distance <= step) {
					ufo.x = targetX;
					ufo.y = targetY;
					startBeam();
				} else {
					ufo.x += ((targetX - ufo.x) / distance) * step;
					ufo.y += ((targetY - ufo.y) / distance) * step;
				}

				break;
			}

			case 'beam': {
				// The visitor scrolled the GIF far away, so the UFO takes it.
				if (rect.bottom < -200 || rect.top > view.height + 200) {
					ufo.timer = 0;
				}

				ufo.timer -= seconds;
				const duration = isStill() ? 8 : 4;
				const progress = 1 - (ufo.timer / duration);

				if (!isStill()) {
					drawBeam(rect);
				}

				if (ufo.carry) {
					const y = ufo.carry.startY + (((ufo.y + 8) - ufo.carry.startY) * progress);
					ufo.carry.element.style.translate = `${Math.round(ufo.x - (ufo.carry.width / 2))}px ${Math.round(y)}px`;
					ufo.carry.element.style.scale = `${1 - (progress * 0.8)}`;
				}

				if (ufo.timer <= 0) {
					abducted.push(ufo.target);
					count('abducted');
					endUFO();
					sayBubble(ufo.critter, 'Thanks for the GIF!', 1.5);
					announce(petStatus, 'The UFO got away with a GIF! Maybe Area 51 has it.');
					leaveUFO('leave');
				}

				break;
			}

			case 'leave':
			case 'flee': {
				const step = (ufo.state === 'flee' ? 500 : 350) * seconds;
				ufo.x += step * (ufo.state === 'flee' ? -0.6 : 0.8);
				ufo.y -= step;

				if (ufo.y < -40) {
					ufo.state = 'away';
					ufo.critter.element.hidden = true;
				}

				break;
			}

			default: {
				break;
			}
		}

		const bob = isStill() ? 0 : Math.sin(ufo.frameTime * 5) * 3;
		showSprite(ufo.critter, ufoSprites[Math.floor(ufo.frameTime * 4) % 2]);
		placeCritter(ufo.critter, ufo.x, ufo.y + 16 + bob);
	};

	ufo.critter.element.addEventListener('pointerdown', event => {
		event.preventDefault();
		zapUFO();
	});

	const returnGIFs = () => {
		if (abducted.length === 0) {
			announce(petStatus, 'Area 51: “We do not have any of your GIFs. We do not even exist.”');
			return;
		}

		for (const image of abducted) {
			image.style.visibility = '';
		}

		announce(petStatus, `Area 51: “We do not have your GIFs.” (${abducted.length === 1 ? 'Your GIF is' : `All ${abducted.length} GIFs are`} back anyway.)`);
		abducted.length = 0;
	};

	// MARK: The bookworm

	const wormSprites = {
		flat: makeFacingSprite(['..........', '..........', 'gGgGgGgGGk', 'gggggggggg'], {g: '#44bb22', G: '#77dd44', k: '#000000'}, 2),
		arch: makeFacingSprite(['...gGgG...', '..g....G..', '.g......Gk', 'gg......gg'], {g: '#44bb22', G: '#77dd44', k: '#000000'}, 2),
	};

	const worm = {critter: createCritter(pageLayer, 20, 8), state: 'away', x: 0, y: 0, direction: 1, timer: randomBetween(90, 150), frameTime: 0, platform: undefined, walked: 0, bites: 0, holes: [], worker: undefined};
	worm.critter.element.hidden = true;

	const drawWorm = () => {
		worm.critter.element.hidden = worm.state === 'away';

		if (worm.state === 'away') {
			return;
		}

		const sprite = worm.state === 'crawl' && Math.floor(worm.frameTime * 3) % 2 === 0 ? wormSprites.arch : wormSprites.flat;
		showSprite(worm.critter, worm.direction > 0 ? sprite.right : sprite.left);
		placeCritter(worm.critter, worm.x, worm.y + 3);
	};

	// A bite out of the top edge of a window: a dark hole with ragged edges.
	const biteHole = () => {
		const height = (worm.platform.borderWidth || 3) + 4;
		const critter = createCritter(pageLayer, 12, height);
		critter.element.style.pointerEvents = 'none';
		const {context} = critter;
		context.fillStyle = '#1a1008';

		// A round bite from the top, with a ragged edge.
		for (let x = 0; x < 12; x++) {
			const depth = Math.round(Math.sqrt(Math.max(0, 36 - ((x - 5.5) ** 2)))) + ((x * 7) % 2);
			context.fillRect(x, 0, 1, Math.min(depth, height));
		}

		placeCritter(critter, worm.x, worm.y + height - 2);
		critter.x = worm.x;
		worm.holes.push(critter);
		count('holes');
	};

	const callWorm = isAsked => {
		if (worm.state !== 'away' || worm.worker) {
			if (isAsked) {
				announce(petStatus, 'The bookworm is busy eating already. Look for the holes!');
			}

			return;
		}

		// On its own, it only comes to a window in view. When the visitor calls it from inside a tall window, it takes the nearest one.
		const windows = platforms.filter(item => item.hasBorder && item.right - item.left > 200);
		const platform = randomItem(windows.filter(item => isInView(item))) ?? (isAsked ? nearestPlatform(windows) : undefined);

		if (!platform) {
			worm.timer = randomBetween(20, 40);
			return;
		}

		worm.platform = platform;
		worm.direction = 1;
		worm.x = randomBetween(platform.left + 20, platform.right - 120);
		worm.y = platform.top;
		worm.walked = 0;
		worm.bites = 0;
		worm.state = 'crawl';
		drawWorm();
		announce(petStatus, `A bookworm is eating one of my windows! Click it to flick it off.${whereIs(platform)}`);
	};

	const sendWorker = () => {
		const element = critterTemplate.content.firstElementChild.cloneNode(true);
		const image = document.createElement('img');
		image.src = isStill() ? '/1999/still/construction-worker.gif' : '/1999/construction-worker.gif';
		image.alt = '';
		image.height = 40;
		element.append(image);
		element.style.pointerEvents = 'none';
		pageLayer.append(element);
		const x = worm.holes[0]?.x ?? worm.x;
		element.style.translate = `${Math.round(x - 36)}px ${Math.round(worm.y - 40)}px`;
		const worker = {element, width: 30, timer: 1.5};
		worm.worker = worker;
		sayBubble(worker, 'Under construction!', 2.5);
	};

	const updateWorm = seconds => {
		worm.frameTime += seconds;

		if (worm.worker) {
			worm.worker.timer -= seconds;

			// The worker fixes one hole at a time.
			if (worm.worker.timer <= 0) {
				const hole = worm.holes.shift();
				worm.worker.timer = 0.7;

				if (hole) {
					hole.element.remove();
					count('fixed');
				} else {
					worm.worker.element.remove();
					worm.worker = undefined;
					worm.timer = randomBetween(120, 200);
				}
			}
		}

		switch (worm.state) {
			case 'away': {
				if (!worm.worker) {
					worm.timer -= seconds;

					if (worm.timer <= 0) {
						callWorm(false);
					}
				}

				return;
			}

			case 'crawl': {
				const step = isStill() ? 14 : 10 * seconds;
				worm.x += worm.direction * step;
				worm.walked += step;

				if (worm.walked >= 14) {
					worm.walked = 0;
					worm.state = 'eat';
					worm.timer = 0.9;
				}

				break;
			}

			case 'eat': {
				worm.timer -= seconds;

				if (worm.timer <= 0) {
					biteHole();
					worm.bites++;

					if (worm.bites % 2 === 1) {
						sayBubble(worm.critter, 'munch', 0.7);
					}

					if (worm.bites >= 5) {
						worm.state = 'burp';
						worm.timer = 1.5;
						sayBubble(worm.critter, 'Burp!', 1.4);
					} else {
						worm.state = 'crawl';
					}
				}

				break;
			}

			case 'burp': {
				worm.timer -= seconds;

				if (worm.timer <= 0) {
					worm.state = 'away';
					sendWorker();
				}

				break;
			}

			default: {
				break;
			}
		}

		drawWorm();
	};

	worm.critter.element.addEventListener('pointerdown', event => {
		event.preventDefault();

		if (worm.state === 'away') {
			return;
		}

		sayBubble(worm.critter, 'Oof!', 0.8);
		worm.state = 'away';
		drawWorm();
		announce(petStatus, 'You flicked the bookworm off the window. Here comes a worker to fix the holes.');
		sendWorker();
	});

	const removeWorm = () => {
		worm.state = 'away';
		drawWorm();

		for (const hole of worm.holes) {
			hole.element.remove();
		}

		worm.holes = [];
		worm.worker?.element.remove();
		worm.worker = undefined;
	};

	// MARK: The pictures of the cards

	for (const [id, sprite] of [['sheep', sheepSprites.walkA.right], ['birds', birdSprites.sit.right], ['mouse', mouseSprites.sniff.right], ['worm', wormSprites.arch.right]]) {
		const canvas = petsRoot.querySelector(`[data-critter-picture="${id}"]`);
		const context = canvas.getContext('2d');
		const scale = Math.min(44 / sprite.width, 44 / sprite.height);
		context.imageSmoothingEnabled = false;
		context.drawImage(sprite, (48 - (sprite.width * scale)) / 2, (48 - (sprite.height * scale)) / 2, sprite.width * scale, sprite.height * scale);
	}

	// MARK: The loop

	// A pet over a control, like a button or a game, lets the clicks through to it, so a pet never takes a click that the visitor meant for the page. It still answers a click where nothing is under it. This is checked a few times a second, at the start of a frame.
	const letClicksThrough = () => {
		const pets = [nekoElement, yarn.critter.element, mouse.critter.element, ufo.critter.element, worm.critter.element, ...flock.map(sheep => sheep.critter.element), ...birds.map(bird => bird.critter.element)];

		// All the places are read before any pet changes, so the page is laid out only once.
		const decisions = pets.filter(element => !element.hidden && element !== heldElement).map(element => {
			const rect = element.getBoundingClientRect();
			const isOverControl = rect.bottom > 0 && rect.top < view.height && [[0.5, 0.5], [0.15, 0.15], [0.85, 0.15], [0.15, 0.85], [0.85, 0.85]].some(([x, y]) => document.elementsFromPoint(rect.left + (rect.width * x), rect.top + (rect.height * y)).find(item => !pageLayer.contains(item) && !screenLayer.contains(item))?.closest('a, button, input, select, textarea, label, summary, canvas, [tabindex]:not([tabindex="-1"])'));
			return {element, isOverControl};
		});

		for (const {element, isOverControl} of decisions) {
			element.style.pointerEvents = isOverControl ? 'none' : '';
		}
	};

	const anyPetIsOn = () => petIDs.some(id => isOn(id));

	const updatePets = seconds => {
		updateNeko(seconds);
		updateYarn(seconds);

		for (const sheep of flock) {
			updateSheep(sheep, seconds);
		}

		for (const bird of birds) {
			updateBird(bird, seconds);
		}

		if (gull) {
			updateGull(seconds);
		}

		if (isOn('mouse')) {
			updateMouse(seconds);
		}

		if (isOn('ufo') || ufo.state !== 'away') {
			updateUFO(seconds);
		}

		if (isOn('worm') || worm.state !== 'away' || worm.worker) {
			updateWorm(seconds);
		}
	};

	let frame;
	let stillTimer;
	let lastTime;
	let measuredAt = 0;

	let checkedAt = 0;

	const tick = time => {
		const seconds = lastTime === undefined ? 0 : Math.min((time - lastTime) / 1000, 0.1);
		lastTime = time;
		readView();

		if (time - measuredAt > 2000) {
			measuredAt = time;
			measurePlatforms();
		}

		if (time - checkedAt > 250) {
			checkedAt = time;
			letClicksThrough();
		}

		updatePets(seconds);
		frame = requestAnimationFrame(tick);
	};

	const updateLoop = () => {
		cancelAnimationFrame(frame);
		clearInterval(stillTimer);
		frame = undefined;

		if (document.hidden || !anyPetIsOn()) {
			return;
		}

		readView();
		measurePlatforms();

		if (isStill()) {
			stillTimer = setInterval(() => {
				readView();
				measurePlatforms();
				letClicksThrough();
				updatePets(0.5);
			}, 500);
		} else {
			lastTime = undefined;
			frame = requestAnimationFrame(tick);
		}
	};

	// When the visitor turns on reduced motion, the pets stop where they are: Neko goes to its basket, and the falling pets land.
	const settlePets = () => {
		if (!isStill()) {
			return;
		}

		putNekoHome();
		putYarnAway('');

		for (const sheep of flock) {
			if (sheep.state === 'fall' || sheep.state === 'drag') {
				const landing = landingBetween(sheep.x, sheep.y - 30, Number.POSITIVE_INFINITY);

				if (landing) {
					land(sheep, landing);
				} else if (!dropIn(sheep) && platforms[0]) {
					land(sheep, platforms[0]);
				}
			}

			drawSheep(sheep);
		}

		for (const bird of birds) {
			if (bird.state === 'arrive' || bird.state === 'leave') {
				bird.state = 'away';
				drawBird(bird);
			}
		}

		if (mouse.state === 'run' || mouse.state === 'flee' || mouse.state === 'leave') {
			mouse.state = 'away';
			drawMouse();
		}

		if (ufo.state === 'arrive') {
			startBeam();
		} else if (ufo.state === 'leave' || ufo.state === 'flee') {
			ufo.state = 'away';
			ufo.critter.element.hidden = true;
		}
	};

	document.addEventListener('visibilitychange', updateLoop);

	reducedMotion.addEventListener('change', () => {
		settlePets();
		updateLoop();
	});

	let resizeTimer;

	addEventListener('resize', () => {
		clearTimeout(resizeTimer);
		resizeTimer = setTimeout(() => {
			readView();
			measurePlatforms();
		}, 200);
	});

	// MARK: The control panel

	const turnOn = (id, isOnNow) => {
		readView();
		// A visitor that comes back waits a while before its next visit.
		const visitor = {ufo, worm, mouse}[id];

		if (isOnNow && !isOn(id) && visitor) {
			visitor.timer = Math.max(visitor.timer, 30);
		}

		settings[id] = isOnNow;
		toggles[id].checked = isOnNow;
		save('geocities-pets', settings);

		switch (id) {
			case 'neko': {
				if (isOnNow && neko.state === 'home' && !isStill()) {
					callNeko();
				} else if (!isOnNow) {
					putNekoHome();
					putYarnAway('');
				}

				break;
			}

			case 'sheep': {
				if (isOnNow && flock.length === 0) {
					for (let index = 0; index < (settings.sheepCount || 1); index++) {
						createSheep();
					}
				} else if (!isOnNow) {
					removeFlock();
				}

				break;
			}

			case 'birds': {
				if (isOnNow && birds.length === 0) {
					for (let index = 0; index < 3; index++) {
						createBird();
					}
				} else if (!isOnNow) {
					removeBirds();
				}

				break;
			}

			case 'mouse': {
				if (!isOnNow) {
					mouse.state = 'away';
					cheese.isOut = false;
					drawMouse();
					drawCheese();
				}

				break;
			}

			case 'ufo': {
				if (!isOnNow && ufo.state !== 'away') {
					if (ufo.state === 'beam') {
						ufo.target.style.visibility = '';
					}

					endUFO();
					ufo.state = 'away';
					ufo.critter.element.hidden = true;
				}

				break;
			}

			case 'worm': {
				if (!isOnNow) {
					removeWorm();
				}

				break;
			}

			default: {
				break;
			}
		}

		showCounts();
		updateLoop();
	};

	for (const id of petIDs) {
		toggles[id].addEventListener('change', () => {
			turnOn(id, toggles[id].checked);
		});
	}

	const actions = {
		'neko-pet': petNeko,
		'neko-yarn': throwYarn,
		'neko-home'() {
			if (neko.state === 'home') {
				if (isStill()) {
					announce(petStatus, 'Neko stays in its basket while your computer prefers less motion. Pet it instead!');
					return;
				}

				callNeko();
				announce(petStatus, 'Neko jumped out of the basket!');
			} else {
				sendNekoHome();
				announce(petStatus, 'Neko goes back to its basket.');
			}
		},
		'sheep-clone': cloneDolly,
		'sheep-baa'() {
			for (const sheep of flock) {
				baa(sheep);
			}

			announce(petStatus, flock.length > 1 ? 'All the sheep say mæ at the same time.' : 'Dolly says mæ. That is Norwegian for baa.');
		},
		'birds-crumbs': throwCrumbs,
		'mouse-cheese': putOutCheese,
		'ufo-call'() {
			callUFO(true);
		},
		'ufo-zap': zapUFO,
		'ufo-return': returnGIFs,
		'worm-call'() {
			callWorm(true);
		},
	};

	// Each button of a pet also brings the pet back to the page.
	const petOfAction = action => action.split('-')[0];

	for (const button of petsRoot.querySelectorAll('[data-critter-action]')) {
		button.addEventListener('click', () => {
			const action = button.dataset.critterAction;

			if (action === 'shoo' || action === 'welcome') {
				const isWelcome = action === 'welcome';

				for (const id of petIDs) {
					turnOn(id, isWelcome);
				}

				announce(petStatus, isWelcome ? 'Everybody is back! The page is alive again.' : 'Shoo! Everybody ran under the desk. Press “Everybody back!” when you miss them.');
				return;
			}

			const id = petOfAction(action);

			if (!isOn(id) && action !== 'ufo-zap' && action !== 'ufo-return') {
				turnOn(id, true);

				// Turning Neko on already calls it out of the basket.
				if (action === 'neko-home') {
					return;
				}
			}

			readView();
			measurePlatforms();
			actions[action]();
		});
	}

	// The pets come out when the page opens, unless the visitor sent them away before.
	readView();
	measurePlatforms();

	for (const id of petIDs) {
		toggles[id].checked = isOn(id);
	}

	showNekoHome(true);

	if (isOn('neko') && !isStill()) {
		callNeko();
		neko.x = 40;
		neko.y = view.height - 70;
		placeNeko();
	}

	if (isOn('sheep')) {
		for (let index = 0; index < (settings.sheepCount || 1); index++) {
			createSheep();
		}
	}

	if (isOn('birds')) {
		for (let index = 0; index < 3; index++) {
			createBird();
		}
	}

	showCounts();
	updateLoop();
}
