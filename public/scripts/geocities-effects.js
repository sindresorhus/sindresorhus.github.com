// The visual noise of the 1999 page: the window of Netscape Navigator around the page, with its silly buttons, the N that throbs, and the status bar, and the sparkles over the title. It uses the toast of `geocities.js` through an event on the document.
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');

// Like `geocities.js`, the window and the sparkles wait until the visitor opens a page that the site prerendered.
if (document.prerendering) {
	await new Promise(resolve => {
		document.addEventListener('prerenderingchange', resolve, {once: true});
	});
}

const panel = document.querySelector('#geocities-panel');
const welcome = document.querySelector('#geocities-welcome');

const showToast = message => {
	document.dispatchEvent(new CustomEvent('geocities-toast', {detail: {message}}));
};

const wait = milliseconds => new Promise(resolve => {
	setTimeout(resolve, milliseconds);
});

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));

// The storage can be missing, like in a private window, and then the visitor number starts at the beginning.
const load = (key, fallback) => {
	try {
		const value = localStorage.getItem(key);
		return value === null ? fallback : (JSON.parse(value) ?? fallback);
	} catch {
		return fallback;
	}
};

// The text keeps its spaces, like on a screen of fixed-width text, as the boxes only keep the line breaks.
const fixedWidth = text => text.replaceAll(' ', ' ');

// Calls the function while the element is in view, so the effects of a part only run while the visitor sees it.
const whileVisible = (element, onChange) => {
	new IntersectionObserver(entries => {
		onChange(entries.at(-1).isIntersecting);
	}).observe(element);
};

// The status bar: the address of the link under the pointer, else the message of what the browser does, like loading, else a message that scrolls, like the scripts of 1999 that scrolled a message in the status bar of the browser. Without motion, it says that the page is done.
const statusText = document.querySelector('#geocities-status-text');
const statusProgress = document.querySelector('#geocities-status-progress');
const statusLock = document.querySelector('#geocities-status-lock');
const statusClock = document.querySelector('#geocities-status-clock');
const scrollingMessage = '★ Welcome to Sindre’s Home Page!!! ★ Sign my guestbook! ★ Best viewed with Netscape Navigator 4 at 800×600 ★ Don’t forget to bookmark me! ★ You are now surfing the World Wide Web ★ ';
let scrollOffset = 0;
let linkStatus;
let taskStatus;

const showStatus = () => {
	const scrolled = scrollingMessage.slice(scrollOffset) + scrollingMessage.slice(0, scrollOffset);
	statusText.textContent = linkStatus ?? taskStatus ?? (reducedMotion.matches ? 'Document: Done' : scrolled);
};

const setTaskStatus = message => {
	taskStatus = message;
	showStatus();
};

// Clears the message of a task, unless another task has replaced it, like Back during Reload.
const clearTaskStatus = message => {
	if (taskStatus === message) {
		setTaskStatus(undefined);
	}
};

// Shows the message while the task runs.
const withTaskStatus = async (message, task) => {
	setTaskStatus(message);

	try {
		return await task();
	} finally {
		clearTaskStatus(message);
	}
};

// The clock in the corner, like the DHTML clocks of 1999, with seconds.
const showClock = () => {
	statusClock.textContent = new Date().toLocaleTimeString('en-US');
};

// One timer for the message and the clock. It does nothing while the tab is hidden.
setInterval(() => {
	if (document.hidden) {
		return;
	}

	scrollOffset = (scrollOffset + 1) % scrollingMessage.length;
	showStatus();
	showClock();
}, 150);

showStatus();
showClock();

const linkUnder = target => target instanceof Element ? target.closest('a[href]') : undefined;

const showLink = link => {
	linkStatus = link?.href;
	showStatus();
};

// Only for a mouse or a pen, as a tap has no pointer that rests on the link.
document.addEventListener('pointerover', event => {
	if (event.pointerType !== 'touch') {
		showLink(linkUnder(event.target));
	}
});

document.addEventListener('pointerout', event => {
	if (linkUnder(event.target) !== linkUnder(event.relatedTarget)) {
		showLink(undefined);
	}
});

document.addEventListener('focusin', event => {
	showLink(linkUnder(event.target));
});

document.addEventListener('focusout', () => {
	showLink(undefined);
});

// The N of Netscape throbs while the browser is busy: while the page scrolls, like a page that loads more as it goes, and while a button of the toolbar does something.
const throbber = document.querySelector('#geocities-navigator-throbber');
let busyCount = 0;
let scrollTimer;

const showThrobber = () => {
	if (busyCount > 0 || scrollTimer !== undefined) {
		throbber.dataset.state = 'loading';
	} else {
		delete throbber.dataset.state;
	}
};

const whileBusy = async task => {
	busyCount++;
	showThrobber();

	try {
		return await task();
	} finally {
		busyCount--;
		showThrobber();
	}
};

addEventListener('scroll', () => {
	clearTimeout(scrollTimer);
	scrollTimer = setTimeout(() => {
		scrollTimer = undefined;
		showThrobber();
	}, 400);
	showThrobber();
}, {passive: true});

// Stop stops every GIF, like the Stop button and the Escape key of old browsers did, by showing its still frame. Reload starts them again. Each only changes an image that shows its own GIF or still frame, so it leaves the hamsters of the HAMSTER cheat alone.
const stillOf = image => {
	const source = image.previousElementSibling;
	return source?.matches('source[srcset]') ? source.getAttribute('srcset') : undefined;
};

// The pictures of the GIFs that move, with the still frame and the GIF of each.
const movingGIFs = () => [...document.querySelectorAll('picture > img[src^="/1999/"]')]
	.map(image => ({image, still: stillOf(image)}))
	.filter(({still}) => still)
	.map(({image, still}) => ({image, still, source: still.replace('/still/', '/')}));

// Stop and Reload tell the GIF-O-Matic (`GIFPile.js`) with `geocities-gifs`, so a new GIF of its pile starts stopped in between.
const stopGIFs = () => {
	let count = 0;
	document.dispatchEvent(new CustomEvent('geocities-gifs', {detail: {isStopped: true}}));

	for (const {image, still, source} of movingGIFs()) {
		if (image.getAttribute('src') === source) {
			image.src = still;
			count++;
		}
	}

	return count;
};

const startGIFs = () => {
	document.dispatchEvent(new CustomEvent('geocities-gifs', {detail: {isStopped: false}}));

	for (const {image, still, source} of movingGIFs()) {
		if (image.getAttribute('src') === still) {
			image.src = source;
		}
	}
};

// Reload loads the page again, like over a modem: the page goes blank, and the status bar says what the browser does, with the progress, until the page is done.
const reloadSteps = [
	['Connecting to host www.geocities.com…', 5],
	['Host contacted. Waiting for reply…', 15],
	['Transferring data from www.geocities.com (23%)…', 23],
	['Transferring data from www.geocities.com (58%)…', 58],
	['Transferring data from www.geocities.com (91%)…', 91],
	['Document: Done', 100],
];
let isReloading = false;

const reload = () => whileBusy(async () => {
	isReloading = true;
	const fade = panel.animate([{opacity: 1}, {opacity: 0.1}], {duration: 300, fill: 'forwards'});

	for (const [message, percent] of reloadSteps) {
		setTaskStatus(message);
		statusProgress.style.width = `${percent}%`;
		// The connection is the slow part, like on a real modem.
		await wait(percent < 20 ? 700 : 450);
	}

	startGIFs();
	fade.reverse();
	await fade.finished;
	fade.cancel();
	statusProgress.style.width = '0';
	clearTaskStatus(reloadSteps.at(-1)[0]);
	isReloading = false;
	showToast('Reloaded! It looks exactly the same, which is how you know it worked.');
});

// Search jumps to a random part of the page, like “I’m Feeling Lucky”, and lights up its heading.
const searchLucky = async () => {
	const headings = [...panel.querySelectorAll('h2')].filter(heading => heading.checkVisibility());
	const heading = randomItem(headings);

	await whileBusy(() => withTaskStatus('Searching 4 million pages with AltaVista…', () => wait(900)));

	heading.scrollIntoView({behavior: reducedMotion.matches ? 'instant' : 'smooth', block: 'center'});
	heading.animate([{backgroundColor: '#ffff00'}, {backgroundColor: 'transparent'}], {duration: 2500, easing: 'ease-in'});
	showToast(`AltaVista found 1,999 results. I’m feeling lucky: “${heading.textContent.trim()}”!`);
};

// Print prints a certificate on the dot matrix printer, line by line, on paper that comes out under the toolbar, until the visitor tears it off.
const toolbar = document.querySelector('#geocities-navigator');
const printButton = toolbar.querySelector('[data-navigator-button="print"]');
const printout = document.querySelector('#geocities-navigator-printout');
const paper = document.querySelector('#geocities-navigator-paper');
const tearOffButton = document.querySelector('#geocities-navigator-tear-off');
let printRun = 0;

const certificateLines = () => {
	const now = new Date();
	const visitor = String(1999 + (Number(load('geocities-visits', 0)) || 0)).padStart(6, '0');
	// The year has the Y2K bug on purpose, like the scripts of 1999 that put “19” in front of the years since 1900, so 2026 is “19126”.
	const time = now.toLocaleTimeString('en-US', {hour: 'numeric', minute: '2-digit'});

	return [
		'================================',
		'      CERTIFICATE OF VISIT',
		'================================',
		'',
		'This certifies that',
		'           *** YOU ***',
		'visited Sindre’s Home Page',
		`on ${now.getMonth() + 1}/${now.getDate()}/19${now.getFullYear() - 1900} at ${time}.`,
		'',
		`Visitor number: ${visitor}`,
		'Browser: Netscape Navigator 4',
		'Modem: 28.8k (probably)',
		'',
		'Signed,',
		'      Sindre, Webmaster',
		'================================',
	];
};

const print = async () => {
	const run = ++printRun;
	paper.replaceChildren();
	tearOffButton.hidden = true;
	printout.hidden = false;
	showToast('Printing your certificate on the dot matrix printer. Brrrrt, brrrrt.');

	await whileBusy(() => withTaskStatus('Printing page 1 of 1…', async () => {
		for (const line of certificateLines()) {
			// A new print, or a tear off, stops this one.
			if (run !== printRun) {
				return;
			}

			const span = document.createElement('span');
			span.textContent = fixedWidth(line) || ' ';
			paper.append(span);

			if (!reducedMotion.matches) {
				await wait(110);
			}
		}
	}));

	if (run === printRun) {
		tearOffButton.hidden = false;
	}
};

const tearOff = () => {
	printRun++;

	// The focus would be lost with the paper, so it goes back to the button that printed it.
	if (printout.contains(document.activeElement)) {
		printButton.focus();
	}

	printout.hidden = true;
};

tearOffButton.addEventListener('click', tearOff);

toolbar.addEventListener('keydown', event => {
	if (event.key === 'Escape' && !printout.hidden) {
		tearOff();
	}
});

const toolbarActions = {
	async back() {
		await whileBusy(() => withTaskStatus('Going back to 1998…', () => wait(800)));
		showToast('You can’t go back. It’s 1999 forever!');
	},
	async forward() {
		await whileBusy(() => withTaskStatus('Going forward to the year 2000…', () => wait(800)));
		showToast('The future is not available yet. Please try again on January 1, 2000.');
	},
	reload() {
		if (!isReloading) {
			reload();
		}
	},
	home() {
		welcome.scrollIntoView({behavior: reducedMotion.matches ? 'instant' : 'smooth'});
		welcome.focus({preventScroll: true});
	},
	search() {
		searchLucky();
	},
	print() {
		print();
	},
	security() {
		const isLocked = statusLock.textContent === '🔒';
		statusLock.textContent = isLocked ? '🔓' : '🔒';
		showToast(isLocked ? 'Security is off again. Go wild.' : 'This page is now protected by 40-bit encryption. A Pentium II cracks it in about a week, so your secrets are safe until next Friday.');
	},
	stop() {
		const count = stopGIFs();
		withTaskStatus('Transfer interrupted!', () => wait(3000));
		showToast(`Transfer interrupted! ${count} GIFs stopped. Press Reload to start them again.`);
	},
};

toolbar.addEventListener('click', event => {
	const button = event.target.closest('[data-navigator-button]');
	if (button) {
		toolbarActions[button.dataset.navigatorButton]();
	}
});

// Sparkles twinkle over the title of the page, one after the other, while it is in view.
const sparkleTemplate = document.querySelector('#geocities-cool-text-sparkle');
const maximumSparkles = 6;
let sparkleTimer;

const addTitleSparkle = () => {
	if (document.hidden || reducedMotion.matches || welcome.querySelectorAll('img').length >= maximumSparkles) {
		return;
	}

	const sparkle = sparkleTemplate.content.firstElementChild.cloneNode(true);
	sparkle.style.left = `${randomBetween(5, 95)}%`;
	sparkle.style.top = `${randomBetween(15, 85)}%`;
	sparkle.addEventListener('animationend', () => {
		sparkle.remove();
	});
	welcome.append(sparkle);
};

whileVisible(welcome, isVisible => {
	clearInterval(sparkleTimer);

	if (isVisible) {
		sparkleTimer = setInterval(addTitleSparkle, 450);
	}
});
