// My iMac on the 1999 page: Mac OS 8.6 in Bondi Blue, with the startup and its keys, the Finder with its windows, menus, icons, and Trash, the extensions that conflict, the memory that runs out, the control panels, the desk accessories, the applications, and the game. The shared toys of `geocities.js`, like the toast, are used through events on the document. Nothing makes a sound until the visitor turns on the speakers, or presses a button that says it plays a sound. Loops run only while their part is on the screen and the tab is visible. The settings, the notes, and the clippings are kept in the browser.
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');

// The speculation rules of the site can prerender the page. The iMac waits until the visitor opens it.
if (document.prerendering) {
	await new Promise(resolve => {
		document.addEventListener('prerenderingchange', resolve, {once: true});
	});
}

// The storage can be missing or full, like in a private window, so the iMac also works without it.
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

const nextFrame = () => new Promise(resolve => {
	requestAnimationFrame(() => {
		resolve();
	});
});

const wait = milliseconds => new Promise(resolve => {
	setTimeout(resolve, milliseconds);
});

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const formatK = kilobytes => `${Math.round(kilobytes).toLocaleString('en-US')}K`;

const toast = message => {
	document.dispatchEvent(new CustomEvent('geocities-toast', {detail: {message}}));
};

const celebrate = () => {
	document.dispatchEvent(new Event('geocities-celebrate'));
};

const cheer = () => {
	document.dispatchEvent(new Event('geocities-cheer'));
};

// Sets the text of a status a frame after it is cleared, so screen readers announce it, also when it is the same text again.
const announce = async (element, text) => {
	element.textContent = '';
	await nextFrame();
	element.textContent = text;
};

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// Calls back with whether the element is on screen while the tab is visible, so timers and loops only run then.
const watchVisibility = (element, onChange) => {
	let isOnScreen = false;
	let wasActive = false;
	const update = () => {
		const isActive = isOnScreen && document.visibilityState === 'visible';
		if (isActive !== wasActive) {
			wasActive = isActive;
			onChange(isActive);
		}
	};

	new IntersectionObserver(entries => {
		isOnScreen = entries.at(-1).isIntersecting;
		update();
	}).observe(element);
	document.addEventListener('visibilitychange', update);
};

// A loop of animation frames, which runs only while its element is on screen and the tab is visible, and while `shouldRun` says so. The step gets the seconds since the last frame, at most a tenth of a second, so a game has the same speed at any refresh rate, and does not jump after a pause.
const makeLoop = (element, step, shouldRun = () => true) => {
	let isActive = false;
	let frame;
	let last;

	const tick = time => {
		const seconds = last === undefined ? 0 : Math.min((time - last) / 1000, 0.1);
		last = time;
		step(seconds);

		if (isActive && shouldRun()) {
			frame = requestAnimationFrame(tick);
		} else {
			frame = undefined;
		}
	};

	const loop = {
		start() {
			if (frame === undefined && isActive && shouldRun()) {
				last = undefined;
				frame = requestAnimationFrame(tick);
			}
		},
	};

	watchVisibility(element, active => {
		isActive = active;
		if (active) {
			loop.start();
		} else if (frame !== undefined) {
			cancelAnimationFrame(frame);
			frame = undefined;
		}
	});

	return loop;
};

const root = document.querySelector('#geocities-mac');
const screen = root.querySelector('#geocities-mac-screen');
const powerButton = root.querySelector('#geocities-mac-power');
const led = root.querySelector('#geocities-mac-led');
const speakersButton = root.querySelector('#geocities-mac-speakers');
const tray = root.querySelector('#geocities-mac-tray');
const trayCD = root.querySelector('#geocities-mac-tray-cd');
const printer = root.querySelector('#geocities-mac-printer');
const printout = root.querySelector('#geocities-mac-printout');
const status = root.querySelector('#geocities-mac-status');
const offLayer = root.querySelector('#geocities-mac-off');
const offText = root.querySelector('#geocities-mac-off-text');
const bootLayer = root.querySelector('#geocities-mac-boot');
const bootIcon = root.querySelector('#geocities-mac-boot-icon');
const welcome = root.querySelector('#geocities-mac-welcome');
const progressBar = root.querySelector('#geocities-mac-progress');
const bootNote = root.querySelector('#geocities-mac-boot-note');
const bootMessage = root.querySelector('#geocities-mac-boot-message');
const extensionRow = root.querySelector('#geocities-mac-extension-row');
const desktop = root.querySelector('#geocities-mac-desktop');
const pictureCanvas = root.querySelector('#geocities-mac-picture');
const iconLayer = root.querySelector('#geocities-mac-icons');
const clock = root.querySelector('#geocities-mac-clock');
const appMenuButton = root.querySelector('#geocities-mac-app-menu-button');
const appMenu = root.querySelector('#geocities-mac-app-menu');
const strip = root.querySelector('#geocities-mac-strip');
const stripModules = root.querySelector('#geocities-mac-strip-modules');
const stripTab = root.querySelector('#geocities-mac-strip-tab');
const balloon = root.querySelector('#geocities-mac-balloon');
const saverCanvas = root.querySelector('#geocities-mac-saver');
const alertBox = root.querySelector('#geocities-mac-alert');
const alertIcon = root.querySelector('#geocities-mac-alert-icon');
const alertText = root.querySelector('#geocities-mac-alert-text');
const alertDetail = root.querySelector('#geocities-mac-alert-detail');
const alertButtons = root.querySelector('#geocities-mac-alert-buttons');
const iconTemplate = root.querySelector('#geocities-mac-icon-template');
const buttonTemplate = root.querySelector('#geocities-mac-button-template');
const menuItemTemplate = root.querySelector('#geocities-mac-menu-item-template');
const rowTemplate = root.querySelector('#geocities-mac-row-template');
const resultTemplate = root.querySelector('#geocities-mac-result-template');
const keyTemplate = root.querySelector('#geocities-mac-key-template');
const stickyTemplate = root.querySelector('#geocities-mac-sticky-template');

// The pictures of the iMac are pixel art of 16 × 16, like the small icons of Mac OS, drawn from rows of letters, one color for each letter, and shown twice as large with sharp pixels.
const palette = {
	k: '#000000',
	w: '#ffffff',
	g: '#cccccc',
	G: '#888888',
	d: '#555555',
	b: '#3366ff',
	B: '#0000aa',
	c: '#99ddff',
	p: '#a8a8ff',
	P: '#6060c8',
	y: '#ffcc00',
	Y: '#fff6a0',
	r: '#dd2222',
	o: '#ff8800',
	n: '#22aa22',
	N: '#116611',
	m: '#9933cc',
	t: '#0095b6',
	u: '#8b5a2b',
	U: '#e0b070',
	s: '#ffd8b0',
	x: '#cc4499',
};

const folderRows = [
	'................',
	'................',
	'..kkkkkk........',
	'.kppppppk.......',
	'kkkkkkkkkkkkkkkk',
	'kwwwwwwwwwwwwwwk',
	'kwpppppppppppppk',
	'kwpppppppppppppk',
	'kwpppppppppppppk',
	'kwpppppppppppppk',
	'kwpppppppppppppk',
	'kwppppppppppppPk',
	'kwppppppppppppPk',
	'kPPPPPPPPPPPPPPk',
	'kkkkkkkkkkkkkkkk',
	'................',
];

const documentRows = lines => [
	'..kkkkkkkk......',
	'..kwwwwwwkk.....',
	'..kwwwwwwkwk....',
	'..kwwwwwwkkkk...',
	'..kwwwwwwwwwk...',
	lines ? '..kwkkkkkkwwk...' : '..kwwwwwwwwwk...',
	'..kwwwwwwwwwk...',
	lines ? '..kwkkkkkkkwk...' : '..kwwwwwwwwwk...',
	'..kwwwwwwwwwk...',
	lines ? '..kwkkkkkwwwk...' : '..kwwwwwwwwwk...',
	'..kwwwwwwwwwk...',
	lines ? '..kwkkkkkkkwk...' : '..kwwwwwwwwwk...',
	'..kwwwwwwwwwk...',
	'..kwwwwwwwwwk...',
	'..kkkkkkkkkkk...',
	'................',
];

const sprites = {
	hd: [
		'................',
		'................',
		'................',
		'................',
		'kkkkkkkkkkkkkkkk',
		'kwwwwwwwwwwwwwwk',
		'kwggggggggggggGk',
		'kwggggggggggggGk',
		'kwgnnggggggGGgGk',
		'kwggggggggggggGk',
		'kGGGGGGGGGGGGGGk',
		'kkkkkkkkkkkkkkkk',
		'.kk..........kk.',
		'................',
		'................',
		'................',
	],
	folder: folderRows,
	systemFolder: folderRows.map((row, index) => {
		const faces = {6: 'BBwk', 7: 'BkBw', 8: 'BBww', 9: 'Bkkw', 10: 'BBww'};
		return faces[index] ? `${row.slice(0, 6)}${faces[index]}${row.slice(10)}` : row;
	}),
	document: documentRows(true),
	simpletext: documentRows(true),
	blank: documentRows(false),
	homework: documentRows(true).map((row, index) => index === 12 ? '..kwwwwwwrrrk...' : (index === 13 ? '..kwwwwwwrrrk...' : row)),
	app: [
		'.......kk.......',
		'......kwwk......',
		'.....kwwwwk.....',
		'....kwwkkwwk....',
		'...kwwkwwkwwk...',
		'..kwwkwwwwkwwk..',
		'.kwwkwwwwwwkwwk.',
		'kwwkwwwwwwwwkwwk',
		'.kwwkwwwwwwkwwk.',
		'..kwwkwwwwkwwk..',
		'...kwwkwwkwwk...',
		'....kwwkkwwk....',
		'.....kwwwwk.....',
		'......kwwk......',
		'.......kk.......',
		'................',
	],
	trash: [
		'................',
		'......kkkk......',
		'..kkkkkkkkkkkk..',
		'..kggggggggggk..',
		'..kkkkkkkkkkkk..',
		'...kgGgGgGgGk...',
		'...kgGgGgGgGk...',
		'...kgGgGgGgGk...',
		'...kgGgGgGgGk...',
		'...kgGgGgGgGk...',
		'...kgGgGgGgGk...',
		'...kgGgGgGgGk...',
		'...kgGgGgGgGk...',
		'...kkkkkkkkkk...',
		'................',
		'................',
	],
	trashFull: [
		'....kkkk........',
		'.kkkkkkkkkkkk...',
		'.kggggggggggk.w.',
		'..kkkkkkkkkkkkww',
		'..kwwkwwwkwwwk..',
		'.kgGgGgGgGgGgGk.',
		'.kgGgGgGgGgGgGk.',
		'kgGgGgGgGgGgGgGk',
		'kgGgGgGgGgGgGgGk',
		'kgGgGgGgGgGgGgGk',
		'.kgGgGgGgGgGgGk.',
		'.kgGgGgGgGgGgGk.',
		'..kgGgGgGgGgGk..',
		'..kkkkkkkkkkkk..',
		'................',
		'................',
	],
	cd: [
		'................',
		'.....kkkkkk.....',
		'...kkggggggkk...',
		'..kgcgggggggGk..',
		'.kgccggggggggGk.',
		'.kgcgggggggggGk.',
		'kggggggkkgggggGk',
		'kgggggkwwkggggGk',
		'kgggggkwwkggggGk',
		'kggggggkkggggGGk',
		'.kggggggggggGGk.',
		'.kgggggggggGGGk.',
		'..kGggggggGGGk..',
		'...kkGGGGGGkk...',
		'.....kkkkkk.....',
		'................',
	],
	finder: [
		'kkkkkkkkkkkkkkkk',
		'kbbbbbbbkwwwwwwk',
		'kbbbbbbbkwwwwwwk',
		'kbbbkbbbkwwkwwwk',
		'kbbbkbbbkwwkwwwk',
		'kbbbbbbbkwwwwwwk',
		'kbbbbbbkwwwwwwwk',
		'kbbbbbkwwwwwwwwk',
		'kbbbbbbkkwwwwwwk',
		'kbbbbbbbkwwwwwwk',
		'kbbkbbbbkwwwkwwk',
		'kbbbkkkkkkkkwwwk',
		'kbbbbbbbkwwwwwwk',
		'kbbbbbbbkwwwwwwk',
		'kbbbbbbbkwwwwwwk',
		'kkkkkkkkkkkkkkkk',
	],
	apple: [
		'........nn......',
		'.......nnn......',
		'.......nn.......',
		'...nnnn..nnnn...',
		'..nnnnnnnnnnnnn.',
		'.nnnnnnnnnnnnn..',
		'.yyyyyyyyyyyy...',
		'.yyyyyyyyyyy....',
		'.ooooooooooo....',
		'.oooooooooooo...',
		'.rrrrrrrrrrrrr..',
		'.rrrrrrrrrrrrrr.',
		'..mmmmmmmmmmmm..',
		'..mmmmmmmmmmmm..',
		'...bbbbbbbbbb...',
		'....bbb..bbb....',
	],
	happyMac: [
		'.kkkkkkkkkkkkkk.',
		'.kggggggggggggk.',
		'.kgkkkkkkkkkkgk.',
		'.kgkwwwwwwwwkgk.',
		'.kgkwwkwwkwwkgk.',
		'.kgkwwkwwkwwkgk.',
		'.kgkwwwwkwwwkgk.',
		'.kgkwwwkkwwwkgk.',
		'.kgkwkwwwwkwkgk.',
		'.kgkwwkkkkwwkgk.',
		'.kgkwwwwwwwwkgk.',
		'.kgkkkkkkkkkkgk.',
		'.kggggggggggggk.',
		'.kgggggggkkkkgk.',
		'.kggggggggggggk.',
		'.kkkkkkkkkkkkkk.',
		'.kggggggggggggk.',
		'.kkkkkkkkkkkkkk.',
	],
	sadMac: [
		'.wwwwwwwwwwwwww.',
		'.wkkkkkkkkkkkkw.',
		'.wkwwwwwwwwwwkw.',
		'.wkwkkkkkkkkwkw.',
		'.wkwwkwkkwkwwkw.',
		'.wkwkwkkkkwkwkw.',
		'.wkwwkwkkwkwwkw.',
		'.wkwkkkkkkkkwkw.',
		'.wkwkkkwkkkkwkw.',
		'.wkwkkkkkkkkwkw.',
		'.wkwkkwwwwkkwkw.',
		'.wkwkwkkkkwkwkw.',
		'.wkwkkkkkkkkwkw.',
		'.wkwwwwwwwwwwkw.',
		'.wkkkkkkkkkkkkw.',
		'.wkkkkkkkwwwwkw.',
		'.wkkkkkkkkkkkkw.',
		'.wwwwwwwwwwwwww.',
	],
	question: folderRows.map((row, index) => {
		const marks = {6: 'kkk', 7: 'k.k', 8: '..k', 9: '.k.', 10: '...', 11: '.k.'};
		return marks[index] ? `${row.slice(0, 7)}${marks[index].replaceAll('.', 'p')}${row.slice(10)}` : row;
	}),
	bomb: [
		'..........k.y...',
		'.........k.yoy..',
		'........k...y...',
		'.....kkkkk......',
		'....kkkkkkk.....',
		'..kkkkkkkkkkk...',
		'.kkkwwkkkkkkkk..',
		'.kkwwkkkkkkkkk..',
		'kkkwkkkkkkkkkkk.',
		'kkkkkkkkkkkkkkk.',
		'kkkkkkkkkkkkkkk.',
		'kkkkkkkkkkkkkkk.',
		'.kkkkkkkkkkkkk..',
		'.kkkkkkkkkkkkk..',
		'..kkkkkkkkkkk...',
		'....kkkkkkk.....',
	],
	caution: [
		'.......kk.......',
		'......kyyk......',
		'......kyyk......',
		'.....kyyyyk.....',
		'.....kykkyk.....',
		'....kyykkyyk....',
		'....kyykkyyk....',
		'...kyyykkyyyk...',
		'...kyyykkyyyk...',
		'..kyyyykkyyyyk..',
		'..kyyyyyyyyyyk..',
		'.kyyyyykkyyyyyk.',
		'.kyyyyykkyyyyyk.',
		'kyyyyyyyyyyyyyyk',
		'kkkkkkkkkkkkkkkk',
		'................',
	],
	stop: [
		'....kkkkkkkk....',
		'...krrrrrrrrk...',
		'..krrrrrrrrrrk..',
		'.krrrrrrrrrrrrk.',
		'krrrrrrrrrrrrrrk',
		'krrrrrrrrrrrrrrk',
		'krwwwwwwwwwwwwrk',
		'krwwwwwwwwwwwwrk',
		'krwwwwwwwwwwwwrk',
		'krrrrrrrrrrrrrrk',
		'krrrrrrrrrrrrrrk',
		'.krrrrrrrrrrrrk.',
		'..krrrrrrrrrrk..',
		'...krrrrrrrrk...',
		'....kkkkkkkk....',
		'................',
	],
	bugdom: [
		'................',
		'................',
		'................',
		'....kkkkkkkk....',
		'..kkGgGgGgGgkk..',
		'.kGgGgGgGgGgGgk.',
		'.kGgGgGgGgGgGwk.',
		'kGgGgGgGgGgGgkwk',
		'kGgGgGgGgGgGgGgk',
		'.kGgGgGgGgGgGgk.',
		'..kkkkkkkkkkkk..',
		'..k.k.k..k.k.k..',
		'.k.k.k....k.k.k.',
		'................',
		'................',
		'................',
	],
	netscape: [
		'kkkkkkkkkkkkkkkk',
		'kBBBBBBBBBBBBwyk',
		'kBBBBBBBBBBBwyBk',
		'kBccBBBBccBwBBBk',
		'kBcccBBBccBBBBBk',
		'kBccccBBccBBBBBk',
		'kBccBccBccBBBBBk',
		'kBccBBccccBBBBBk',
		'kBccBBBcccBBBBBk',
		'kBccBBBBccBBBBBk',
		'kBBBBBBBBBBBBBBk',
		'kGGGGGGGGGGGGGGk',
		'kGgGgGgGgGgGgGGk',
		'kGGGGGGGGGGGGGGk',
		'kkkkkkkkkkkkkkkk',
		'................',
	],
	graphing: [
		'kkkkkkkkkkkkkkkk',
		'kwwwwwwkwwwwwwwk',
		'kwwwwwwkwwwwrrwk',
		'kwwwwwwkwwwrwwwk',
		'kwwwwwwkwwrwwwwk',
		'kwwwwwwkwrwwwwwk',
		'kwwwwwwkrwwwwwwk',
		'kkkkkkkrkkkkkkkk',
		'kwwwwwrkwwwwwwwk',
		'kwwwwrwkwwwwwwwk',
		'kwwwrwwkwwwwwwwk',
		'kwwrwwwkwwwwwwwk',
		'kwrrwwwkwwwwwwwk',
		'kwwwwwwkwwwwwwwk',
		'kwwwwwwkwwwwwwwk',
		'kkkkkkkkkkkkkkkk',
	],
	sherlock: [
		'....kkkkkk......',
		'...kuuuuuuk.....',
		'..kkkkkkkkkk....',
		'....kkkkkk......',
		'...kccccccck....',
		'..kccwccccccK...',
		'..kcwccccccck...',
		'..kccccccccck...',
		'..kccccccccck...',
		'...kcccccccck...',
		'....kkkkkkkk....',
		'..........kkk...',
		'...........kkk..',
		'............kkk.',
		'.............kk.',
		'................',
	].map(row => row.replaceAll('K', 'k')),
	notepad: [
		'..kkkkkkkkkkk...',
		'..krkrkrkrkrk...',
		'..kYYYYYYYYYk...',
		'..kYkkkkkkYYk...',
		'..kYYYYYYYYYk...',
		'..kYkkkkkkkYk...',
		'..kYYYYYYYYYk...',
		'..kYkkkkkYYYk...',
		'..kYYYYYYYYYk...',
		'..kYkkkkkkkYk...',
		'..kYYYYYYYYYk...',
		'..kYYYYYYYYkk...',
		'..kYYYYYYYkGk...',
		'..kkkkkkkkkk....',
		'................',
		'................',
	],
	stickies: [
		'................',
		'.kkkkkkkkkkkk...',
		'.kyyyyyyyyyyk...',
		'.kYYYYYYYYYYk...',
		'.kYkkkkkkkYYk...',
		'.kYYYYYYYYYYk...',
		'.kYkkkkkkYYYk...',
		'.kYYYYYYYYYYkkkk',
		'.kkkkkkkkkkkkcck',
		'....kcccccccccck',
		'....kckkkkkkkcck',
		'....kccccccccccck',
		'....kckkkkkcccck',
		'....kcccccccccck',
		'....kkkkkkkkkkkk',
		'................',
	].map(row => row.slice(0, 16)),
	scrapbook: [
		'................',
		'..kkkkkkkkkkkk..',
		'.kGkwwwwwwwwwwk.',
		'.kGkwwwwwwwwwwk.',
		'.kGkwryyyyyrwwk.',
		'.kGkwyrryrrywwk.',
		'.kGkwyyrryyywwk.',
		'.kGkwwwwwwwwwwk.',
		'.kGkwkkkkkkwwwk.',
		'.kGkwwwwwwwwwwk.',
		'.kGkwkkkkkwwwwk.',
		'.kGkwwwwwwwwwwk.',
		'.kGkkkkkkkkkkkk.',
		'.kGGGGGGGGGGGk..',
		'..kkkkkkkkkkkk..',
		'................',
	],
	puzzle: [
		'kkkkkkkkkkkkkkkk',
		'kwwwkwwwkwwwkwwk',
		'kwkwkwkkkkwkkwwk',
		'kwwwkwwwkwwwkwwk',
		'kkkkkkkkkkkkkkkk',
		'kwwwkwwwkwwwkGGk',
		'kkwwkkwwkwkwkGGk',
		'kwwwkwwwkwwwkGGk',
		'kkkkkkkkkkkkkkkk',
		'kwwwkwwwkwwwkwwk',
		'kwkkkwkwkwwkkwwk',
		'kwwwkwwwkwwwkwwk',
		'kkkkkkkkkkkkkkkk',
		'kwwwkwwwkwwwkwwk',
		'kkkkkkkkkkkkkkkk',
		'................',
	],
	keycaps: [
		'................',
		'................',
		'................',
		'kkkkkkkkkkkkkkkk',
		'kgggggggggggggGk',
		'kgwkwkwkwkwkwkGk',
		'kgggggggggggggGk',
		'kggwkwkwkwkwkgGk',
		'kgggggggggggggGk',
		'kgwkwkwwwwkwkgGk',
		'kgggggggggggggGk',
		'kGGGGGGGGGGGGGGk',
		'kkkkkkkkkkkkkkkk',
		'................',
		'................',
		'................',
	],
	chooser: [
		'................',
		'....kkkkkkkk....',
		'....kwwwwwwk....',
		'....kwkkkkwk....',
		'..kkkkkkkkkkkk..',
		'.kggggggggggggk.',
		'.kggggggggggnGk.',
		'.kggggggggggggk.',
		'.kGGGGGGGGGGGGk.',
		'.kkkkkkkkkkkkkk.',
		'...kwwwwwwwwk...',
		'...kwkkkkkkwk...',
		'...kwwwwwwwwk...',
		'...kkkkkkkkkk...',
		'................',
		'................',
	],
	appearance: [
		'................',
		'.....kkkkkk.....',
		'...kkwwwwwwkk...',
		'..kwwrrwwyywwk..',
		'.kwwwrrwwyywwwk.',
		'.kwnnwwwwwwbbwk.',
		'kwwnnwwkkwwbbwwk',
		'kwwwwwkGGkwwwwwk',
		'kwmmwwkGGkwwkkk.',
		'.kmmwwwkkwwk....',
		'.kwwwwwwwwk.....',
		'..kwwooowwk.....',
		'...kkwwwwwk.....',
		'.....kkkkk......',
		'................',
		'................',
	],
	extension: [
		'................',
		'.....kkk........',
		'....kxxxk.......',
		'..kkkxxxkkkk....',
		'..kxxxxxxxxxk...',
		'..kxxxxxxxxxkk..',
		'..kxxxxxxxxxxxk.',
		'..kxxxxxxxxxxxk.',
		'..kxxxxxxxxxkk..',
		'..kxxxxxxxxxk...',
		'..kkkkxxxkkkk...',
		'.....kxxxk......',
		'......kkk.......',
		'................',
		'................',
		'................',
	],
	speech: [
		'................',
		'................',
		'...kkkkkkkkkk...',
		'..kwwwwwwwwwwk..',
		'.kwwwwwwwwwwwwk.',
		'.kwkwwkwwkwwkwk.',
		'.kwwwwwwwwwwwwk.',
		'..kwwwwwwwwwwk..',
		'...kkkkwwkkkk...',
		'......kwk.......',
		'......kk........',
		'.....kk.........',
		'................',
		'................',
		'................',
		'................',
	],
	installer: [
		'................',
		'...kkkkkkkkkk...',
		'..kwwwwwwwwwwk..',
		'.kkkkkkkkkkkkkk.',
		'.kgggggggggggGk.',
		'.kggggBBwwgggGk.',
		'.kggggBkBwgggGk.',
		'.kggggBBwwgggGk.',
		'.kggggBkkwgggGk.',
		'.kggggBBwwgggGk.',
		'.kgggggggggggGk.',
		'.kGGGGGGGGGGGGk.',
		'.kkkkkkkkkkkkkk.',
		'................',
		'................',
		'................',
	],
	unicorn: [
		'.........y......',
		'........yy......',
		'.......yy.......',
		'......wwwm......',
		'.....wwkwwm.....',
		'....wwwwwwmm....',
		'...wwwwwwwwmm...',
		'..kwwww.wwwwmm..',
		'........wwwwwm..',
		'.......wwwwwwww.',
		'......wwwwwwwww.',
		'......wwwwwwwww.',
		'......ww.ww.ww..',
		'......ww.ww.ww..',
		'......kk.kk.kk..',
		'................',
	],
	dogcow: [
		'................',
		'..kk............',
		'.kwwk.......k...',
		'kwkwwkkkkkkkwk..',
		'kwwwwwwwwwwwwk..',
		'.kkwwkwwwkkwwk..',
		'...kwkkwwwkkwk..',
		'...kwwwwwwwwwk..',
		'...kwkkkkkkwwk..',
		'...kwk....kwk...',
		'...kwk....kwk...',
		'...kkk....kkk...',
		'................',
		'................',
		'................',
		'................',
	],
};

// The pictures as images, made once each. A tint replaces the letter `x`, like the colors of the extensions.
const spriteImages = new Map();

const drawSprite = (context, rows, x, y, scale, tint) => {
	for (const [rowIndex, row] of rows.entries()) {
		for (const [columnIndex, letter] of [...row].entries()) {
			const color = letter === 'x' && tint ? tint : palette[letter];
			if (color) {
				context.fillStyle = color;
				context.fillRect(x + (columnIndex * scale), y + (rowIndex * scale), scale, scale);
			}
		}
	}
};

const spriteURL = (name, tint) => {
	const key = `${name}${tint ?? ''}`;
	if (!spriteImages.has(key)) {
		const rows = sprites[name] ?? sprites.app;
		const canvas = document.createElement('canvas');
		canvas.width = 16;
		canvas.height = rows.length;
		drawSprite(canvas.getContext('2d'), rows, 0, 0, 1, tint);
		spriteImages.set(key, canvas.toDataURL());
	}

	return spriteImages.get(key);
};

// Draws a picture on a canvas of its own, as large as fits, in the middle.
const drawSpriteOnCanvas = (canvas, name, background) => {
	const context = canvas.getContext('2d');
	const rows = sprites[name];
	context.clearRect(0, 0, canvas.width, canvas.height);
	if (background) {
		context.fillStyle = background;
		context.fillRect(0, 0, canvas.width, canvas.height);
	}

	const scale = Math.floor(Math.min(canvas.width / 16, canvas.height / rows.length));
	drawSprite(context, rows, Math.floor((canvas.width - (16 * scale)) / 2), Math.floor((canvas.height - (rows.length * scale)) / 2), scale);
};

// The face of the Mac OS logo, drawn with paths: the blue face at the left and the light face at the right, sharing one nose.
const drawFace = (canvas, size = canvas.width) => {
	const context = canvas.getContext('2d');
	const unit = size / 16;
	context.clearRect(0, 0, canvas.width, canvas.height);
	context.fillStyle = '#99ccff';
	context.fillRect(0, 0, size, size);
	context.fillStyle = '#3355dd';
	context.beginPath();
	context.moveTo(0, 0);
	context.lineTo(8.6 * unit, 0);
	context.lineTo(7.4 * unit, 6 * unit);
	context.lineTo(6 * unit, 9.5 * unit);
	context.lineTo(8 * unit, 9.5 * unit);
	context.lineTo(8.4 * unit, 16 * unit);
	context.lineTo(0, 16 * unit);
	context.closePath();
	context.fill();
	context.strokeStyle = '#000';
	context.lineWidth = Math.max(1, unit * 0.9);
	context.beginPath();
	context.moveTo(4 * unit, 3.5 * unit);
	context.lineTo(4 * unit, 6 * unit);
	context.moveTo(11.5 * unit, 3.5 * unit);
	context.lineTo(11.5 * unit, 6 * unit);
	context.moveTo(3 * unit, 11 * unit);
	context.quadraticCurveTo(8 * unit, 14.5 * unit, 13 * unit, 11 * unit);
	context.stroke();
	context.strokeRect(0, 0, size, size);
};

// The sounds of the iMac, made with Web Audio, at the volume of the Control Strip. They play only while the speakers are on.
let audioContext;
let speakersOn = false;

const audio = () => {
	audioContext ??= new AudioContext();
	if (audioContext.state === 'suspended') {
		audioContext.resume();
	}

	return audioContext;
};

const volumeGain = () => (settings.volume / 7) * 0.5;

// A tone with an envelope, from `start` seconds after now.
const tone = (frequency, start, duration, {type = 'sine', gain = 0.3, endFrequency, attack = 0.01} = {}) => {
	if (!speakersOn || settings.volume === 0) {
		return;
	}

	const context = audio();
	const time = context.currentTime + start;
	const oscillator = context.createOscillator();
	const envelope = context.createGain();
	oscillator.type = type;
	oscillator.frequency.setValueAtTime(frequency, time);
	if (endFrequency) {
		oscillator.frequency.exponentialRampToValueAtTime(endFrequency, time + duration);
	}

	envelope.gain.setValueAtTime(0.0001, time);
	envelope.gain.exponentialRampToValueAtTime(gain * volumeGain(), time + attack);
	envelope.gain.exponentialRampToValueAtTime(0.0001, time + duration);
	oscillator.connect(envelope).connect(context.destination);
	oscillator.start(time);
	oscillator.stop(time + duration + 0.05);
};

// A burst of noise through a band-pass filter that sweeps, for the whooshes of Platinum Sounds, and for the quack.
const noise = (start, duration, {from = 800, to = 3000, gain = 0.2, q = 2} = {}) => {
	if (!speakersOn || settings.volume === 0) {
		return;
	}

	const context = audio();
	const time = context.currentTime + start;
	const buffer = context.createBuffer(1, Math.ceil(context.sampleRate * duration), context.sampleRate);
	const data = buffer.getChannelData(0);
	for (let index = 0; index < data.length; index++) {
		data[index] = (Math.random() * 2) - 1;
	}

	const source = context.createBufferSource();
	const filter = context.createBiquadFilter();
	const envelope = context.createGain();
	source.buffer = buffer;
	filter.type = 'bandpass';
	filter.Q.value = q;
	filter.frequency.setValueAtTime(from, time);
	filter.frequency.exponentialRampToValueAtTime(to, time + duration);
	envelope.gain.setValueAtTime(0.0001, time);
	envelope.gain.exponentialRampToValueAtTime(gain * volumeGain(), time + (duration * 0.3));
	envelope.gain.exponentialRampToValueAtTime(0.0001, time + duration);
	source.connect(filter).connect(envelope).connect(context.destination);
	source.start(time);
};

// The startup chime of the iMac, a chord of F sharp major, like the chime of every Mac from 1998.
const playChime = () => {
	for (const [index, frequency] of [92.5, 138.59, 185, 233.08, 277.18, 369.99].entries()) {
		tone(frequency, index * 0.004, 3.2, {type: 'sine', gain: 0.22, attack: 0.02});
		tone(frequency * 2.002, index * 0.004, 2.2, {type: 'triangle', gain: 0.05, attack: 0.02});
	}
};

// The Chimes of Death of the Macs before the iMac: a slow, eerie arpeggio that goes up and comes back down.
const playChimesOfDeath = () => {
	const notes = [261.63, 311.13, 369.99, 440, 523.25, 440, 369.99, 311.13];
	for (const [index, frequency] of notes.entries()) {
		tone(frequency, index * 0.32, 0.9, {type: 'triangle', gain: 0.3});
		tone(frequency / 2, index * 0.32, 0.9, {type: 'sine', gain: 0.15});
	}
};

// The alert sounds of the Sound control panel, made again with oscillators, and the neigh of Unicorn Sounds.
const alertSounds = {
	'Simple Beep'() {
		tone(880, 0, 0.18, {type: 'square', gain: 0.15});
	},
	Droplet() {
		tone(1400, 0, 0.18, {endFrequency: 320, gain: 0.35});
	},
	Sosumi() {
		tone(784, 0, 0.3, {type: 'triangle', gain: 0.3});
		tone(1046.5, 0.12, 0.5, {type: 'triangle', gain: 0.3});
		tone(1046.5, 0.32, 0.4, {type: 'triangle', gain: 0.1});
	},
	'Wild Eep'() {
		tone(400, 0, 0.35, {type: 'sawtooth', endFrequency: 1800, gain: 0.15});
		tone(1800, 0.35, 0.15, {type: 'sawtooth', endFrequency: 900, gain: 0.12});
	},
	Quack() {
		noise(0, 0.12, {from: 700, to: 500, gain: 0.5, q: 6});
		noise(0.14, 0.14, {from: 650, to: 420, gain: 0.5, q: 6});
	},
	Neigh() {
		for (let index = 0; index < 8; index++) {
			tone(900 + (index % 2 === 0 ? 260 : -60) - (index * 40), index * 0.07, 0.09, {type: 'sawtooth', gain: 0.1});
		}
	},
};

const beep = () => {
	if (isExtensionActive('unicorn')) {
		alertSounds.Neigh();
	} else {
		alertSounds[settings.alertSound]?.();
	}
};

// The sounds of the Platinum Sounds sound track of the Appearance.
const platinumSound = kind => {
	if (settings.soundTrack !== 'platinum') {
		return;
	}

	if (kind === 'menu') {
		tone(2400, 0, 0.03, {type: 'square', gain: 0.04});
		noise(0.01, 0.12, {from: 1500, to: 4000, gain: 0.08});
	} else if (kind === 'close') {
		noise(0, 0.2, {from: 4000, to: 600, gain: 0.12});
	} else if (kind === 'open') {
		noise(0, 0.2, {from: 600, to: 4000, gain: 0.12});
	} else if (kind === 'shade') {
		noise(0, 0.16, {from: 900, to: 5000, gain: 0.14, q: 8});
	} else if (kind === 'trash') {
		noise(0, 0.3, {from: 300, to: 120, gain: 0.3, q: 1});
		tone(160, 0, 0.25, {endFrequency: 60, gain: 0.2});
	}
};

const setSpeakers = isOn => {
	speakersOn = isOn;
	setPressed(speakersButton, isOn);
	speakersButton.textContent = isOn ? '🔊 The speakers are on (press to turn them off)' : '🔈 Turn on the speakers (the chime, beeps, sounds, and Talking Alerts)';
	if (!isOn) {
		stopSpeaking();
	}
};

// A button that says it plays a sound turns on the speakers, so it is not silent.
const ensureSpeakers = () => {
	if (!speakersOn) {
		setSpeakers(true);
	}
};

// The extensions of the System Folder: those of Apple, and the shareware I downloaded, with what each does. One of the shareware extensions conflicts with the others and crashes the iMac at a restart, until the visitor finds it with the Extensions Manager.
const extensions = [
	{id: 'appearance', name: 'Appearance Extension', version: '1.1.4', isApple: true, color: '#9c9cff', info: 'Makes the Platinum look. Turn it off and my iMac looks like System 7, in black and white.'},
	{id: 'opentransport', name: 'Open Transport', version: '2.0.3', isApple: true, color: '#66cc66', info: 'The Internet. Sherlock needs it to search the Internet.'},
	{id: 'speech', name: 'Speech Manager', version: '1.5.3', isApple: true, color: '#ff9966', info: 'Makes my iMac talk. Speech and Talking Alerts need it.'},
	{id: 'controlstrip', name: 'Control Strip', version: '2.0.3', isApple: true, color: '#999999', info: 'The strip at the bottom left of the screen. Turn it off, and it is gone.'},
	{id: 'quicktime', name: 'QuickTime™', version: '4.0', isApple: true, color: '#3399ff', info: 'For movies. I need it for the trailer of Star Wars: Episode I. I watched it 41 times.'},
	{id: 'colorsync', name: 'ColorSync™', version: '2.6.1', isApple: true, color: '#ff66cc', info: 'Makes the colors the same on the screen and on paper. My StyleWriter has no ink, so it is easy: no colors.'},
	{id: 'usb', name: 'USB Device Extension', version: '1.3.5', isApple: true, color: '#33cccc', info: 'For the hockey puck mouse and the keyboard. Do not turn it off.'},
	{id: 'kaleidoscope', name: 'Kaleidoscope', version: '2.2', color: '#ffcc00', info: 'Makes the Kaleidoscope schemes work in the Appearance. Shareware, 20 dollars.'},
	{id: 'ramdoubler', name: 'RAM Doubler 8', version: '8.0', color: '#cc3333', info: 'Doubles the memory, for free! 32 MB becomes 64 MB. Games get a bit slower.'},
	{id: 'speeddoubler', name: 'Speed Doubler 8', version: '8.1.2', color: '#ff3333', info: 'Makes everything twice as fast, it says. The icons at startup really go faster.'},
	{id: 'waffleclock', name: 'Waffle Clock', version: '1.2', color: '#cc9933', info: 'Puts a waffle in the clock of the menu bar. Shareware, 5 dollars. I did not pay.'},
	{id: 'unicorn', name: 'Unicorn Sounds INIT', version: '0.9b', color: '#cc66ff', info: 'Every alert sound is a neigh. It is a beta.'},
	{id: 'tabs', name: 'Tabs Not Spaces INIT', version: '1.0', color: '#66ccff', info: 'Turns every space I type in Note Pad and Stickies into a tab. As it should be.'},
	{id: 'y2k', name: 'Y2K Fixer 99', version: '1.0', color: '#33cc99', info: 'Makes my iMac ready for the year 2000. Macs were always ready. Now the year in the clock is 19100.'},
	{id: 'afterdark', name: 'After Dark™', version: '4.0', color: '#333399', info: 'Flying Toasters! They come when the desktop is left alone for a while.'},
	{id: 'crashguard', name: 'Norton CrashGuard', version: '3.0', color: '#ffff33', info: 'Catches the crashes of programs, so they do not crash. In theory.'},
	{id: 'defaultfolder', name: 'Default Folder', version: '3.0.6', color: '#9966cc', info: 'Remembers folders. I do not know which ones.'},
];

const shareware = extensions.filter(extension => !extension.isApple);

const defaultSettings = () => ({
	theme: 'platinum',
	picture: 'default',
	soundTrack: 'none',
	alertSound: 'Simple Beep',
	voice: 'Fred',
	rate: 1,
	talkingAlerts: false,
	phrase: 'Alert!',
	depth: 'millions',
	volume: 5,
	appleTalk: false,
	printer: '',
	set: 'mine',
	// RAM Doubler is off at first, so Bugdom Jr. runs out of memory, until the visitor finds out why.
	enabled: Object.fromEntries(extensions.map(extension => [extension.id, extension.id !== 'ramdoubler'])),
	culprit: randomItem(shareware).id,
	conflictsFound: 0,
	memory: {},
	ram: 'none',
	notes: ['Things to do:\n- Find the extension that crashes\n- Beat Bugdom Jr.\n- Buy ink\n', '', '', '', '', '', '', ''],
	notePage: 0,
	stickies: [{text: 'Do NOT drag the System Folder to the Trash!!!\n\nBuy ink for the StyleWriter.', color: 0, x: 12, y: 40}],
	clips: [],
	bugdomBest: 0,
	puzzleBest: 0,
	netscapeCrashes: 0,
	pageSetup: {},
});

const storageKey = 'geocities-mac';
const settings = {...defaultSettings(), ...load(storageKey, {})};
settings.enabled = {...defaultSettings().enabled, ...settings.enabled};

const persist = () => {
	save(storageKey, settings);
};

// The conflicting extension is picked once, and kept, so it is the same after a reload.
persist();

// What only lasts until the page closes, like what is in the Trash and whether the iMac is on.
const session = {
	power: 'off',
	hasBooted: false,
	keys: new Set(),
	// The extensions that were loaded at the last startup. Changes in the Extensions Manager take effect at the next one.
	active: new Set(),
	extensionsOff: false,
	improperShutdown: false,
	unstable: false,
	pramZapped: false,
	systemInTrash: false,
	cdInDrive: true,
	trayOpen: false,
	fromCD: false,
	genericIcons: new Set(['netscape', 'homework']),
	commentsLost: false,
	clipboard: undefined,
	selected: undefined,
	balloons: false,
	huntRestarts: 0,
	isHunting: false,
	folderCount: 0,
	suspects: [],
};

const isExtensionActive = id => session.active.has(id);

// The memory of the iMac, in K: the RAM, the System, and a part for each program that runs, like in About This Computer.
const systemMemory = 15_412;
const builtInMemory = () => (settings.ram === 'stick' ? 96 : 32) * 1024;
const totalMemory = () => builtInMemory() * (isExtensionActive('ramdoubler') ? 2 : 1);

// The programs, with the memory each asks for. Bugdom Jr. needs 12,000K to run, whatever Get Info says.
const programs = {
	finder: {title: 'Finder', icon: 'finder', preferred: 0, minimum: 0},
	extensions: {title: 'Extensions Manager', icon: 'extension', preferred: 600, minimum: 400},
	appearance: {title: 'Appearance', icon: 'appearance', preferred: 900, minimum: 600},
	speech: {title: 'Speech', icon: 'speech', preferred: 400, minimum: 300},
	puzzle: {title: 'Puzzle', icon: 'puzzle', preferred: 200, minimum: 150},
	notepad: {title: 'Note Pad', icon: 'notepad', preferred: 300, minimum: 200},
	scrapbook: {title: 'Scrapbook', icon: 'scrapbook', preferred: 500, minimum: 350},
	keycaps: {title: 'Key Caps', icon: 'keycaps', preferred: 250, minimum: 200},
	chooser: {title: 'Chooser', icon: 'chooser', preferred: 350, minimum: 250},
	stickies: {title: 'Stickies', icon: 'stickies', preferred: 450, minimum: 300},
	sherlock: {title: 'Sherlock', icon: 'sherlock', preferred: 2800, minimum: 2000, comment: 'Finds everything. Except my homework.'},
	graphing: {title: 'Graphing Calculator', icon: 'graphing', preferred: 3000, minimum: 2200, comment: 'Ron Avitzur sneaked into Apple to finish it, without pay.'},
	bugdom: {title: 'Bugdom Jr.', icon: 'bugdom', preferred: 14_000, minimum: 9000, needs: 12_000, comment: 'The best game in the world. Do NOT delete!'},
	netscape: {title: 'Netscape Communicator™', icon: 'netscape', preferred: 9000, minimum: 6000, comment: 'Version 4.6. It crashes.'},
	simpletext: {title: 'SimpleText', icon: 'simpletext', preferred: 512, minimum: 384, comment: 'Reads text, and reads it out loud.'},
	installer: {title: 'Mac OS 8.6 Install', icon: 'installer', preferred: 1000, minimum: 800},
};

for (const [id, sizes] of Object.entries(settings.memory)) {
	Object.assign(programs[id] ?? {}, sizes);
}

// The programs that run, with the memory each got, in the order they started.
const running = new Map([['finder', 0]]);
let frontProgram = 'finder';

const usedMemory = () => {
	let used = systemMemory;
	for (const size of running.values()) {
		used += size;
	}

	return used;
};
const freeMemory = () => totalMemory() - usedMemory();

// The voices of PlainTalk, made with the pitch and the speed of the voice of the browser. The singing voices sing one word for each note of their tune.
const voices = {
	Fred: {pitch: 0.7, rate: 1},
	Victoria: {pitch: 1.25, rate: 1},
	Junior: {pitch: 1.6, rate: 1.1},
	Princess: {pitch: 1.9, rate: 1},
	Ralph: {pitch: 0.3, rate: 0.85},
	Whisper: {pitch: 1, rate: 0.8, volume: 0.35},
	Zarvox: {pitch: 0.1, rate: 0.75},
	Trinoids: {pitch: 2, rate: 0.85},
	Bubbles: {pitch: 1.4, rate: 0.7},
	// Pomp and Circumstance.
	'Good News': {tune: [0, 2, 4, 5, 7, 7, 5, 4, 2, 4, 0]},
	// A sad march, slow and low.
	'Bad News': {tune: [0, 0, 0, 0, 3, 2, 2, 0, 0, -1, 0], rate: 0.7},
	// In the Hall of the Mountain King.
	Cellos: {tune: [0, 2, 3, 5, 7, 3, 7, 6, 2, 6, 5, 1, 5]},
};

const canSpeak = 'speechSynthesis' in globalThis;
let isSpeakingLong = false;

const stopSpeaking = () => {
	if (canSpeak) {
		speechSynthesis.cancel();
	}

	if (isSpeakingLong) {
		isSpeakingLong = false;
		document.dispatchEvent(new CustomEvent('geocities-music', {detail: {isPlaying: false, source: 'imac-speech'}}));
	}
};

// Speaks with the voice of the Speech control panel, when the Speech Manager is loaded and the speakers are on. A long text tells the other players of the page, so only one plays.
const speak = (text, {voice = settings.voice, isLong = false} = {}) => {
	if (!canSpeak || !speakersOn || !isExtensionActive('speech')) {
		return false;
	}

	stopSpeaking();
	const voiceSettings = voices[voice] ?? voices.Fred;
	const rate = (voiceSettings.rate ?? 1) * settings.rate;
	const say = (words, pitch) => {
		const utterance = new SpeechSynthesisUtterance(words);
		utterance.pitch = clamp(pitch, 0, 2);
		utterance.rate = clamp(rate, 0.5, 2);
		utterance.volume = (voiceSettings.volume ?? 1) * (settings.volume / 7);
		utterance.lang = 'en-US';
		return utterance;
	};

	let last;
	if (voiceSettings.tune) {
		for (const [index, word] of text.split(/\s+/).filter(Boolean).entries()) {
			const semitone = voiceSettings.tune[index % voiceSettings.tune.length];
			last = say(word, 0.6 + (semitone * 0.12));
			speechSynthesis.speak(last);
		}
	} else {
		last = say(text, voiceSettings.pitch);
		speechSynthesis.speak(last);
	}

	if (isLong && last) {
		isSpeakingLong = true;
		document.dispatchEvent(new CustomEvent('geocities-music', {detail: {isPlaying: true, source: 'imac-speech'}}));
		last.addEventListener('end', () => {
			if (isSpeakingLong) {
				isSpeakingLong = false;
				document.dispatchEvent(new CustomEvent('geocities-music', {detail: {isPlaying: false, source: 'imac-speech'}}));
			}
		});
	}

	return true;
};

document.addEventListener('geocities-music', event => {
	if (event.detail?.isPlaying && event.detail.source !== 'imac-speech' && isSpeakingLong) {
		stopSpeaking();
	}
});

// The windows: each knows its program, and the window manager moves, stacks, collapses, and zooms them inside the desktop, under the menu bar.
const windowProgram = {
	about: 'finder',
	info: 'finder',
	hd: 'finder',
	apps: 'finder',
	trash: 'finder',
	clipboard: 'finder',
	switcher: 'finder',
	pagesetup: 'finder',
};

const windowsByName = new Map([...desktop.querySelectorAll('[data-mac-window]')].map(element => [element.dataset.macWindow, element]));
const programOf = element => windowProgram[element.dataset.macWindow] ?? (element.dataset.macWindow.startsWith('sticky') ? 'stickies' : element.dataset.macWindow);
const windowOrder = [];
const windowOpeners = new Map();
const onOpen = {};
const onQuit = {};
let cascade = 0;
const menuBarHeight = () => menuBar.offsetHeight;

const visibleWindows = () => windowOrder.filter(element => !element.hidden);
const frontWindow = () => visibleWindows().at(-1);

const markFront = () => {
	const front = frontWindow();
	for (const element of windowOrder) {
		if (element === front) {
			element.dataset.macFront = '';
		} else {
			delete element.dataset.macFront;
		}
	}
};

const bringToFront = element => {
	const index = windowOrder.indexOf(element);
	if (index !== -1) {
		windowOrder.splice(index, 1);
	}

	windowOrder.push(element);
	for (const [order, ordered] of windowOrder.entries()) {
		ordered.style.zIndex = String(order + 10);
	}

	markFront();
	setFrontProgram(programOf(element));
};

const moveWindow = (element, left, top) => {
	const minimumTop = menuBarHeight();
	const maximumLeft = Math.max(desktop.clientWidth - element.offsetWidth, 0);
	const maximumTop = Math.max(desktop.clientHeight - element.offsetHeight, minimumTop);
	element.style.left = `${clamp(left, 0, maximumLeft)}px`;
	element.style.top = `${clamp(top, minimumTop, maximumTop)}px`;
};

// When what had the focus is gone, like an item of a closed menu, the focus goes to the window in front, an icon, or the power button, so it is never lost.
const focusSomething = () => {
	const target = [frontWindow(), iconLayer.querySelector('button'), powerButton].find(element => element?.checkVisibility());
	target.focus({preventScroll: true});
};

// Moves the focus on when what had it was hidden or replaced, unless an alert has it.
const keepFocus = () => {
	const active = document.activeElement;
	if (alertBox.hidden && (active === document.body || (root.contains(active) && !active.checkVisibility()))) {
		focusSomething();
	}
};

const showWindow = (element, opener) => {
	if (opener) {
		windowOpeners.set(element, opener);
	}

	const isOpening = element.hidden;
	if (isOpening) {
		element.hidden = false;
		delete element.dataset.macHidden;
		if (!element.dataset.macPlaced) {
			element.dataset.macPlaced = '';
			const offset = (cascade % 6) * 18;
			cascade++;
			moveWindow(element, 12 + offset, menuBarHeight() + 8 + offset);
		} else {
			moveWindow(element, element.offsetLeft, element.offsetTop);
		}

		platinumSound('open');
	}

	bringToFront(element);
	element.focus({preventScroll: true});

	// After the window has the focus, so a program can move it inside, like Bugdom Jr. to its canvas.
	if (isOpening) {
		onOpen[element.dataset.macWindow]?.(element);
	}
};

const openWindow = (name, opener) => {
	showWindow(windowsByName.get(name), opener);
};

const quitProgram = id => {
	if (id === 'finder' || !running.has(id)) {
		return;
	}

	running.delete(id);
	for (const element of windowOrder) {
		if (programOf(element) === id && !element.hidden) {
			element.hidden = true;
		}
	}

	onQuit[id]?.();
	if (frontProgram === id) {
		const front = frontWindow();
		setFrontProgram(front ? programOf(front) : 'finder');
	}

	markFront();
	updateMemory();
	updateSwitcher();
	if (session.power === 'on') {
		keepFocus();
	}
};

const closeWindow = element => {
	const hadFocus = element.contains(document.activeElement);
	element.hidden = true;
	platinumSound('close');
	const id = programOf(element);
	if (id !== 'finder' && !windowOrder.some(other => other !== element && !other.hidden && programOf(other) === id)) {
		quitProgram(id);
	}

	markFront();
	const front = frontWindow();
	setFrontProgram(front ? programOf(front) : 'finder');
	if (hadFocus) {
		const opener = windowOpeners.get(element);
		if (opener?.isConnected && opener.checkVisibility()) {
			opener.focus({preventScroll: true});
		} else {
			focusSomething();
		}
	}
};

const toggleCollapse = element => {
	const isCollapsed = element.dataset.macCollapsed === undefined;
	if (isCollapsed) {
		element.dataset.macCollapsed = '';
	} else {
		delete element.dataset.macCollapsed;
	}

	element.querySelector('[data-mac-collapse]').setAttribute('aria-pressed', String(isCollapsed));
	platinumSound('shade');
};

const toggleZoom = element => {
	const isZoomed = element.dataset.macZoomed === undefined;
	if (isZoomed) {
		element.dataset.macRestore = `${element.offsetLeft},${element.offsetTop}`;
		element.dataset.macZoomed = '';
		element.style.left = '0px';
		element.style.top = `${menuBarHeight()}px`;
	} else {
		delete element.dataset.macZoomed;
		const [left, top] = (element.dataset.macRestore ?? '12,30').split(',').map(Number);
		moveWindow(element, left, top);
	}

	element.querySelector('[data-mac-zoom]').setAttribute('aria-pressed', String(isZoomed));
};

const setUpWindow = element => {
	windowOrder.push(element);
	element.querySelector('[data-mac-close]').addEventListener('click', () => {
		closeWindow(element);
	});

	element.querySelector('[data-mac-collapse]').addEventListener('click', () => {
		toggleCollapse(element);
	});

	element.querySelector('[data-mac-zoom]').addEventListener('click', () => {
		toggleZoom(element);
	});

	element.addEventListener('pointerdown', () => {
		if (windowOrder.at(-1) !== element) {
			bringToFront(element);
		}
	});

	element.addEventListener('focusin', () => {
		if (windowOrder.at(-1) !== element) {
			bringToFront(element);
		}
	});

	// The title bar drags the window, with the pointer captured, so it follows a fast pointer. A double-click rolls it up, like WindowShade.
	const titleBar = element.querySelector('[data-mac-title-bar]');
	let drag;
	let lastTap = 0;
	titleBar.addEventListener('pointerdown', event => {
		if (event.button !== 0 || event.target.closest('button')) {
			return;
		}

		const now = performance.now();
		if (now - lastTap < 400) {
			lastTap = 0;
			toggleCollapse(element);
			return;
		}

		lastTap = now;
		drag = {x: event.clientX - element.offsetLeft, y: event.clientY - element.offsetTop};
		titleBar.setPointerCapture(event.pointerId);
	});

	titleBar.addEventListener('pointermove', event => {
		if (drag && element.dataset.macZoomed === undefined) {
			moveWindow(element, event.clientX - drag.x, event.clientY - drag.y);
		}
	});

	for (const type of ['pointerup', 'pointercancel']) {
		titleBar.addEventListener(type, () => {
			if (drag) {
				drag = undefined;
				element.dispatchEvent(new Event('mac-moved'));
			}
		});
	}
};

for (const element of windowsByName.values()) {
	setUpWindow(element);
}

// A window that grows, or a desktop that gets narrower, like when a phone turns, keeps the windows inside.
const keepInside = new ResizeObserver(() => {
	for (const element of windowOrder) {
		if (!element.hidden && element.dataset.macZoomed === undefined) {
			moveWindow(element, element.offsetLeft, element.offsetTop);
		}
	}

	placeIcons();
});

keepInside.observe(desktop);

const part = (element, name) => element.querySelector(`[data-mac-part="${name}"]`);
const windowPart = (windowName, name) => part(windowsByName.get(windowName), name);

// The alerts of Mac OS: one at a time, over everything, with the buttons at the bottom right and the default button at the end. The desktop cannot be used while it shows. Talking Alerts read it out loud after a moment.
let alertQueue = Promise.resolve();
let alertSpeechTimer;

const showAlert = ({icon = 'caution', text, detail = '', buttons = [{label: 'OK', value: 'ok'}], isLow = false}) => {
	const result = alertQueue.then(() => new Promise(resolve => {
		const previousFocus = document.activeElement;
		drawSpriteOnCanvas(alertIcon, icon);
		alertText.textContent = text;
		alertDetail.textContent = detail;
		alertDetail.hidden = detail === '';
		if (isLow) {
			alertBox.dataset.macLow = '';
		} else {
			delete alertBox.dataset.macLow;
		}
		alertButtons.replaceChildren();
		const cancel = buttons.find(button => button.value === 'cancel');
		const defaultButton = buttons.at(-1);
		const finish = value => {
			clearTimeout(alertSpeechTimer);
			alertBox.hidden = true;
			desktop.inert = false;
			alertBox.removeEventListener('keydown', onKeyDown);
			if (previousFocus?.isConnected && previousFocus.checkVisibility() && root.contains(previousFocus)) {
				previousFocus.focus({preventScroll: true});
			} else {
				focusSomething();
			}

			resolve(value);
		};

		const onKeyDown = event => {
			if (event.key === 'Escape' && cancel) {
				event.preventDefault();
				event.stopPropagation();
				finish(cancel.value);
			} else if (event.key === 'Tab') {
				// The alert is modal, so Tab goes around its buttons.
				const enabled = [...alertButtons.querySelectorAll('button')].filter(button => !button.disabled);
				const index = enabled.indexOf(document.activeElement);
				event.preventDefault();
				enabled.at((index + (event.shiftKey ? -1 : 1)) % enabled.length).focus();
			}
		};

		for (const button of buttons) {
			const element = buttonTemplate.content.firstElementChild.cloneNode(true);
			element.textContent = button.label;
			element.disabled = Boolean(button.disabled);
			element.dataset.state = button === defaultButton ? 'default' : '';
			element.addEventListener('click', () => {
				finish(button.value);
			});
			alertButtons.append(element);
		}

		desktop.inert = true;
		alertBox.hidden = false;
		alertBox.addEventListener('keydown', onKeyDown);
		alertButtons.lastElementChild.focus({preventScroll: true});
		beep();
		if (settings.talkingAlerts) {
			alertSpeechTimer = setTimeout(() => {
				speak(`${settings.phrase} ${text}`);
			}, 1200);
		}
	}));

	alertQueue = result.catch(() => {});
	return result;
};

// The menu bar: a menu opens on a click, or with the arrow keys, and moving over the other titles while one is open opens them, like on a Mac. Escape, a click outside, or moving the focus away closes it.
const menuTitles = [...desktop.querySelectorAll('[data-mac-menu]'), appMenuButton];
const menuOf = title => title === appMenuButton ? appMenu : desktop.querySelector(`[data-mac-menu-list="${title.dataset.macMenu}"]`);
let openTitle;
// When a menu opened because the pointer moved onto its title, so the click that follows does not close it again.
let hoverOpenedAt = 0;

const menuButtons = list => [...list.querySelectorAll(':scope > li > button')].filter(button => !button.disabled);

const closeSubmenus = () => {
	for (const button of desktop.querySelectorAll('[data-mac-action="submenu"]')) {
		button.setAttribute('aria-expanded', 'false');
		document.getElementById(button.getAttribute('aria-controls')).hidden = true;
	}
};

const closeMenus = () => {
	if (!openTitle) {
		return;
	}

	menuOf(openTitle).hidden = true;
	openTitle.setAttribute('aria-expanded', 'false');
	openTitle.dataset.state = '';
	closeSubmenus();
	openTitle = undefined;
};

const openMenu = (title, focusFirst) => {
	closeMenus();
	updateMenus();
	const list = menuOf(title);
	list.hidden = false;
	title.setAttribute('aria-expanded', 'true');
	title.dataset.state = 'on';
	openTitle = title;
	platinumSound('menu');
	if (focusFirst) {
		menuButtons(list)[0]?.focus();
	}
};

for (const title of menuTitles) {
	title.addEventListener('click', event => {
		if (openTitle === title && performance.now() - hoverOpenedAt < 600) {
			return;
		}

		if (openTitle === title) {
			closeMenus();
		} else {
			openMenu(title, event.detail === 0);
		}
	});

	title.addEventListener('pointerenter', () => {
		if (openTitle && openTitle !== title) {
			openMenu(title, false);
			hoverOpenedAt = performance.now();
		}
	});

	title.addEventListener('keydown', event => {
		const index = menuTitles.indexOf(title);
		if (event.key === 'ArrowDown') {
			event.preventDefault();
			openMenu(title, true);
		} else if (event.key === 'ArrowRight' || event.key === 'ArrowLeft') {
			event.preventDefault();
			const next = menuTitles.at((index + (event.key === 'ArrowRight' ? 1 : -1)) % menuTitles.length);
			next.focus();
			if (openTitle) {
				openMenu(next, false);
			}
		}
	});
}

const menuBar = menuTitles[0].closest('ul').parentElement;

menuBar.addEventListener('keydown', event => {
	const list = event.target.closest('ul');
	if (!list || !event.target.closest('li > button') || menuTitles.includes(event.target)) {
		if (event.key === 'Escape' && openTitle) {
			const title = openTitle;
			closeMenus();
			title.focus();
		}

		return;
	}

	const buttons = menuButtons(list);
	const index = buttons.indexOf(event.target);
	if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
		event.preventDefault();
		buttons.at((index + (event.key === 'ArrowDown' ? 1 : -1)) % buttons.length)?.focus();
	} else if (event.key === 'ArrowRight' && event.target.dataset.macAction === 'submenu') {
		event.preventDefault();
		event.target.click();
	} else if (event.key === 'ArrowLeft' && list.closest('li')?.querySelector(':scope > [data-mac-action="submenu"]')) {
		event.preventDefault();
		const opener = list.closest('li').querySelector(':scope > button');
		closeSubmenus();
		opener.focus();
	} else if (event.key === 'Escape') {
		event.preventDefault();
		const title = openTitle;
		closeMenus();
		title?.focus();
	} else if (event.key === 'ArrowRight' || event.key === 'ArrowLeft') {
		event.preventDefault();
		const titleIndex = menuTitles.indexOf(openTitle);
		const next = menuTitles.at((titleIndex + (event.key === 'ArrowRight' ? 1 : -1)) % menuTitles.length);
		next.focus();
		openMenu(next, true);
	}
});

document.addEventListener('pointerdown', event => {
	if (openTitle && !menuBar.contains(event.target)) {
		closeMenus();
	}
});

// Safari does not focus a menu title on a click, so Escape may come from outside the menu bar while a menu is open.
document.addEventListener('keydown', event => {
	if (event.key === 'Escape' && openTitle && !menuBar.contains(event.target)) {
		closeMenus();
	}
});

// Only when the focus moves to something else, like with Tab. Safari does not focus a button on a click, and focuses the nearest focusable ancestor instead, like the section of the iMac, so that does not count, or a click on an item would close the menu before the click lands.
menuBar.addEventListener('focusout', event => {
	if (event.relatedTarget && !menuBar.contains(event.relatedTarget) && !event.relatedTarget.contains(menuBar)) {
		closeMenus();
	}
});

menuBar.addEventListener('click', event => {
	const button = event.target.closest('[data-mac-action]');
	if (!button || !menuBar.contains(button)) {
		return;
	}

	if (button.dataset.macAction === 'submenu') {
		const submenu = document.getElementById(button.getAttribute('aria-controls'));
		const isOpen = submenu.hidden;
		submenu.hidden = !isOpen;
		button.setAttribute('aria-expanded', String(isOpen));
		if (isOpen) {
			menuButtons(submenu)[0]?.focus();
		}

		return;
	}

	const title = openTitle;
	closeMenus();
	// The item is hidden now, so the focus goes back to its menu title, and the command can move it on, like to a window it opens.
	if (menuBar.contains(document.activeElement)) {
		title?.focus({preventScroll: true});
	}

	runAction(button.dataset.macAction, title);
});

// Enables and names the items of the menus for what can be done now, like Empty Trash only when something is in the Trash.
const updateMenus = () => {
	const front = frontWindow();
	const frontName = front?.dataset.macWindow ?? '';
	const selected = session.selected;
	const canCopy = ['scrapbook', 'notepad', 'simpletext', 'keycaps'].includes(frontName) || frontName.startsWith('sticky');
	const canPaste = session.clipboard && (['scrapbook', 'notepad', 'puzzle'].includes(frontName) || frontName.startsWith('sticky'));
	const states = {
		'empty-trash': trashItems().length > 0,
		'put-away': selected?.inTrash,
		'move-to-trash': selected && !selected.inTrash && selected.id !== 'trash',
		'get-info': Boolean(selected),
		'open-selected': Boolean(selected),
		'close-window': Boolean(front),
		copy: canCopy,
		paste: Boolean(canPaste),
		clear: canCopy || frontName === 'puzzle',
		undo: false,
		eject: session.cdInDrive && !session.trayOpen,
		quit: frontProgram !== 'finder',
	};

	for (const button of desktop.querySelectorAll('[data-mac-menu-list] [data-mac-action]')) {
		const action = button.dataset.macAction;
		if (action in states) {
			button.disabled = !states[action];
		}

		if (action === 'balloons') {
			button.textContent = session.balloons ? 'Hide Balloons' : 'Show Balloons';
		} else if (action === 'undo') {
			button.textContent = 'Can’t Undo';
		} else if (action === 'quit') {
			button.textContent = frontProgram === 'finder' ? 'Quit' : `Quit ${programs[frontProgram].title}`;
		}
	}

	const front2 = programs[frontProgram];
	appMenu.replaceChildren();
	const addItem = (label, action, icon) => {
		const item = menuItemTemplate.content.firstElementChild.cloneNode(true);
		const button = item.querySelector('button');
		if (icon) {
			const image = document.createElement('img');
			image.src = spriteURL(icon);
			image.alt = '';
			image.width = 16;
			image.height = 16;
			button.append(image);
		}

		button.append(label);
		button.addEventListener('click', () => {
			closeMenus();
			appMenuButton.focus({preventScroll: true});
			action();
		});
		appMenu.append(item);
		return button;
	};

	const addSeparator = () => {
		const separator = desktop.querySelector('[data-mac-menu-list] li[aria-hidden]').cloneNode(true);
		appMenu.append(separator);
	};

	addItem(`Hide ${front2.title}`, () => {
		hideProgram(frontProgram);
	}).disabled = frontProgram === 'finder';
	addItem('Hide Others', () => {
		for (const id of running.keys()) {
			if (id !== frontProgram) {
				hideProgram(id);
			}
		}
	});
	addItem('Show All', showAllPrograms);
	addSeparator();
	for (const id of running.keys()) {
		const button = addItem(`${id === frontProgram ? '✓ ' : ''}${programs[id].title}`, () => {
			switchTo(id);
		}, programs[id].icon);
		button.setAttribute('aria-current', String(id === frontProgram));
	}

	addSeparator();
	addItem('Tear Off: Application Switcher', () => {
		openWindow('switcher', appMenuButton);
	});
};

const setFrontProgram = id => {
	frontProgram = id;
	appMenuButton.querySelector('img').src = spriteURL(programs[id].icon);
	appMenuButton.querySelector('span').textContent = programs[id].title;
	updateSwitcher();
};

const hideProgram = id => {
	for (const element of windowOrder) {
		if (programOf(element) === id && !element.hidden) {
			element.hidden = true;
			element.dataset.macHidden = '';
		}
	}

	const front = frontWindow();
	markFront();
	setFrontProgram(front ? programOf(front) : 'finder');
	keepFocus();
};

const showAllPrograms = () => {
	for (const element of windowOrder) {
		if (element.dataset.macHidden !== undefined) {
			element.hidden = false;
			delete element.dataset.macHidden;
		}
	}

	markFront();
};

const switchTo = id => {
	const windows = windowOrder.filter(element => programOf(element) === id && (!element.hidden || element.dataset.macHidden !== undefined));
	for (const element of windows) {
		element.hidden = false;
		delete element.dataset.macHidden;
		bringToFront(element);
	}

	windows.at(-1)?.focus({preventScroll: true});
	setFrontProgram(id);
};

// The Application Switcher, torn off the Application menu, with a button for each program that runs.
const updateSwitcher = () => {
	const list = windowPart('switcher', 'apps');
	list.replaceChildren();
	for (const id of running.keys()) {
		const button = buttonTemplate.content.firstElementChild.cloneNode(true);
		const image = document.createElement('img');
		image.src = spriteURL(programs[id].icon);
		image.alt = '';
		image.width = 16;
		image.height = 16;
		button.append(image, ` ${programs[id].title}`);
		button.dataset.state = id === frontProgram ? 'on' : '';
		button.addEventListener('click', () => {
			switchTo(id);
		});
		list.append(button);
	}
};

// Starts a program, if there is memory for it. Between the minimum and the preferred size, it asks, like Mac OS did.
const launch = async (id, opener) => {
	if (session.power !== 'on') {
		return false;
	}

	if (running.has(id)) {
		switchTo(id);
		if (!windowOrder.some(element => programOf(element) === id && !element.hidden)) {
			onLaunch[id]?.(opener);
		}

		return true;
	}

	const program = programs[id];
	const free = freeMemory();
	let size = program.preferred;
	if (free < program.minimum) {
		await showAlert({icon: 'stop', text: `There is not enough memory to open “${program.title}” (${formatK(program.preferred)} needed, ${formatK(free)} available).`, detail: 'Closing windows or quitting application programs can make more memory available. The Application menu at the top right shows what runs.'});
		return false;
	}

	if (free < program.preferred) {
		const answer = await showAlert({icon: 'caution', text: `There is not enough memory to open “${program.title}” at its preferred size. Do you want to open it using the available memory (${formatK(free)})?`, buttons: [{label: 'Cancel', value: 'cancel'}, {label: 'OK', value: 'ok'}]});
		if (answer !== 'ok') {
			return false;
		}

		size = free;
	}

	running.set(id, size);
	setFrontProgram(id);
	updateMemory();
	onLaunch[id]?.(opener);
	return true;
};

// What each program does when it starts. Most open their window.
const onLaunch = {};

for (const id of ['extensions', 'speech', 'puzzle', 'notepad', 'scrapbook', 'keycaps', 'chooser', 'sherlock', 'graphing', 'bugdom', 'netscape', 'simpletext', 'installer', 'appearance']) {
	onLaunch[id] = opener => {
		openWindow(id, opener);
	};
}

// A program that unexpectedly quits, with the error of a type. A second crash before a restart takes the whole iMac with it, as the memory is a mess by then. Norton CrashGuard catches it first, which does not help.
const errorTypes = {
	1: 'bus error',
	2: 'address error',
	3: 'illegal instruction',
	10: 'unimplemented trap',
	11: 'hardware exception',
	25: 'out of memory',
};

const crashProgram = async (id, type) => {
	const title = programs[id].title;
	if (isExtensionActive('crashguard')) {
		const answer = await showAlert({icon: 'caution', text: `Norton CrashGuard has caught a crash in “${title}”!`, detail: 'CrashGuard can try to keep it running.', buttons: [{label: 'Quit', value: 'quit'}, {label: 'Try to Continue', value: 'continue'}]});
		if (answer === 'continue') {
			systemError(title, 'Bus error');
			return;
		}
	}

	quitProgram(id);
	if (session.unstable) {
		systemError(title, errorTypes[type]?.replace(/^\w/, letter => letter.toUpperCase()) ?? 'Bus error');
		return;
	}

	session.unstable = true;
	await showAlert({icon: 'bomb', text: `The application “${title}” has unexpectedly quit, because an error of type ${type} occurred.`, detail: `(Type ${type} is a${/^[aeiou]/.test(errorTypes[type]) ? 'n' : ''} ${errorTypes[type]}.) You should save your work and restart. The next crash may take the whole iMac with it.`});
};

// The items of the Finder: on the desktop, in Macintosh HD, and in Applications. Each can be opened, dragged, put in the Trash, and put away again.
const makeItems = () => [
	{id: 'hd', name: 'Macintosh HD', icon: 'hd', place: 'desktop', kind: 'disk', size: '4 GB, 2.9 GB available'},
	{id: 'cd', name: 'Mac OS 8.6 CD', icon: 'cd', place: 'desktop', kind: 'disc', size: '587 MB'},
	{id: 'readme', name: 'Read Me!', icon: 'simpletext', place: 'desktop', kind: 'SimpleText document', program: 'simpletext', size: '4K', comment: 'READ IT.'},
	{id: 'bugdom-alias', name: 'Bugdom Jr. alias', icon: 'bugdom', place: 'desktop', kind: 'alias', program: 'bugdom', size: '2K', comment: 'The real one is in Applications.'},
	{id: 'netscape', name: 'Netscape Communicator™', icon: 'netscape', place: 'desktop', kind: 'alias', program: 'netscape', size: '2K', comment: 'Crashes. Every time.'},
	{id: 'homework', name: 'Homework (not done)', icon: 'homework', place: 'desktop', kind: 'SimpleText document', size: '0K', locked: true, comment: 'About the Vikings. Due Monday. Locked, so I cannot lose it.'},
	{id: 'trash', name: 'Trash', icon: 'trash', place: 'desktop', kind: 'Trash'},
	{id: 'system', name: 'System Folder', icon: 'systemFolder', place: 'hd', kind: 'folder', size: '187 MB, 1,312 files', comment: 'Do not touch.'},
	{id: 'applications', name: 'Applications', icon: 'folder', place: 'hd', kind: 'folder', size: '96 MB'},
	{id: 'extras', name: 'Apple Extras', icon: 'folder', place: 'hd', kind: 'folder', size: '24 MB', comment: 'Mostly AppleScript. I do not know what AppleScript is.'},
	...['bugdom', 'graphing', 'netscape', 'sherlock', 'simpletext', 'notepad', 'stickies', 'scrapbook', 'puzzle', 'keycaps'].map(id => ({id: `app-${id}`, name: programs[id].title, icon: programs[id].icon, place: 'applications', kind: 'application program', program: id, size: `${Math.round(programs[id].preferred / 3)}K`, comment: programs[id].comment})),
];

let items = makeItems();
const trashItems = () => items.filter(item => item.inTrash);
const itemById = id => items.find(item => item.id === id);
const itemButtons = new Map();

const iconFor = item => {
	if (item.id === 'trash') {
		return trashItems().length > 0 ? 'trashFull' : 'trash';
	}

	return session.genericIcons.has(item.id) ? 'blank' : item.icon;
};

const makeIconButton = item => {
	const button = iconTemplate.content.firstElementChild.cloneNode(true);
	button.dataset.macIcon = item.id;
	button.querySelector('span').textContent = item.name;
	button.querySelector('img').src = spriteURL(iconFor(item));
	if (session.genericIcons.has(item.id)) {
		button.dataset.macGeneric = '';
		button.dataset.macBalloon = 'This icon is blank, because the desktop file is a mess. Rebuild the desktop: hold Command and Option while the iMac starts up.';
	} else {
		button.dataset.macBalloon = item.id === 'trash' ? 'The Trash. Drag things here to throw them away. Choose Empty Trash in the Special menu to delete them for real.' : `${item.name}. Double-click it (or tap it twice) to open it, or drag it to the Trash.`;
	}

	if (item.id === 'trash' && trashItems().length > 0) {
		button.dataset.macFull = '';
	}

	if (session.selected === item) {
		button.dataset.macSelected = '';
	}

	setUpIcon(button, item);
	itemButtons.set(item.id, button);
	return button;
};

// Puts the icons of the desktop in columns from the top right, like the Finder, with the Trash at the bottom right. An icon that was dragged keeps its place, inside the desktop.
const placeIcons = () => {
	const width = iconLayer.clientWidth;
	const height = iconLayer.clientHeight;
	if (width === 0) {
		return;
	}

	const columnWidth = 80;
	const rowHeight = 70;
	let column = 0;
	let row = 0;
	for (const button of iconLayer.children) {
		const item = itemById(button.dataset.macIcon);
		if (item.id === 'trash') {
			item.x ??= width - columnWidth;
			item.y ??= height - rowHeight;
		} else if (item.x === undefined) {
			item.x = width - columnWidth - (column * columnWidth);
			item.y = 6 + (row * rowHeight);
			row++;
			if (6 + ((row + 1) * rowHeight) > height - rowHeight) {
				row = 0;
				column++;
			}
		}

		item.x = clamp(item.x, 0, Math.max(width - columnWidth, 0));
		item.y = clamp(item.y, 0, Math.max(height - rowHeight, 0));
		button.style.left = `${item.x}px`;
		button.style.top = `${item.y}px`;
	}
};

const renderDesktop = () => {
	iconLayer.replaceChildren();
	const visible = items.filter(item => item.place === 'desktop' && !item.inTrash && (item.id !== 'cd' || (session.cdInDrive && !session.trayOpen)) && (!session.fromCD || ['cd', 'trash'].includes(item.id)));
	for (const item of visible) {
		const button = makeIconButton(item);
		button.style.position = 'absolute';
		iconLayer.append(button);
	}

	placeIcons();
	renderFolders();
	if (session.power === 'on') {
		keepFocus();
	}
};

// The windows of Macintosh HD, Applications, and the Trash list their icons, with a status bar like the Finder.
const renderFolders = () => {
	const folders = {
		hd: {items: items.filter(item => item.place === 'hd' && !item.inTrash), status: count => `${count} items, 2.9 GB available`},
		apps: {items: items.filter(item => item.place === 'applications' && !item.inTrash), status: count => `${count} items`},
		trash: {items: trashItems(), status: count => count === 0 ? 'The Trash is empty.' : `${count} item${count === 1 ? '' : 's'} in the Trash. Choose Empty Trash in the Special menu, or Put Away in the File menu.`},
	};

	for (const [name, folder] of Object.entries(folders)) {
		const grid = windowPart(name, 'grid');
		grid.replaceChildren(...folder.items.map(item => makeIconButton(item)));
		windowPart(name, 'status').textContent = folder.status(folder.items.length);
	}

	const trashButton = itemButtons.get('trash');
	if (trashButton && iconLayer.contains(trashButton)) {
		trashButton.querySelector('img').src = spriteURL(iconFor(itemById('trash')));
	}
};

const select = item => {
	session.selected = item;
	for (const button of root.querySelectorAll('[data-mac-icon]')) {
		if (item && button.dataset.macIcon === item.id) {
			button.dataset.macSelected = '';
		} else {
			delete button.dataset.macSelected;
		}
	}
};

// Opens an item: a disk or a folder opens its window, a program starts, and a document starts its program.
const openItem = async (item, opener) => {
	if (item.inTrash) {
		putAway(item);
		return;
	}

	if (item.id === 'hd') {
		openWindow('hd', opener);
	} else if (item.id === 'trash') {
		openWindow('trash', opener);
	} else if (item.id === 'applications') {
		openWindow('apps', opener);
	} else if (item.id === 'cd') {
		launch('installer', opener);
	} else if (item.id === 'system') {
		await showAlert({icon: 'caution', text: 'This is the System Folder. 1,312 files, and I do not know what most of them do.', detail: 'Do not drag it to the Trash. Really. Do not.'});
	} else if (item.id === 'extras') {
		await showAlert({icon: 'finder', text: '“Apple Extras” is full of AppleScript.', detail: 'Dad says AppleScript can do everything. I asked it to do my homework. It cannot.'});
	} else if (item.id === 'homework') {
		await showAlert({icon: 'caution', text: '“Homework (not done)” is empty.', detail: 'It is 0K. That is why it is called “not done”.'});
	} else if (item.kind === 'folder') {
		await showAlert({icon: 'finder', text: `“${item.name}” is empty.`, detail: 'Like my piggy bank after I bought Bugdom.'});
	} else if (item.program) {
		launch(item.program, opener);
	}
};

// Moves an item to the Trash, unless it cannot go there, like the startup disk.
const moveToTrash = async item => {
	if (item.id === 'trash') {
		return;
	}

	if (item.id === 'hd') {
		await showAlert({icon: 'stop', text: 'The disk “Macintosh HD” cannot be put away, because it is the startup disk.'});
		return;
	}

	if (item.id === 'cd') {
		eject();
		return;
	}

	if (item.id === 'applications' && trashItems().length === 0) {
		toast('Applications is in the Trash. Bold move.');
	}

	item.inTrash = true;
	if (item.id === 'system') {
		session.systemInTrash = true;
		toast('You put the System Folder in the Trash. The iMac does not know yet. It will at the next restart.');
	}

	if (session.selected === item) {
		select(undefined);
	}

	platinumSound('trash');
	renderDesktop();
};

const putAway = item => {
	item.inTrash = false;
	if (item.id === 'system') {
		session.systemInTrash = false;
	}

	renderDesktop();
};

const emptyTrash = async () => {
	const inTrash = trashItems();
	if (inTrash.length === 0) {
		return;
	}

	const answer = await showAlert({icon: 'caution', text: `The Trash contains ${inTrash.length} item${inTrash.length === 1 ? '' : 's'}, which use ${(inTrash.length * 0.7).toFixed(1)} MB of disk space. Are you sure you want to permanently remove ${inTrash.length === 1 ? 'it' : 'these items'}?`, buttons: [{label: 'Cancel', value: 'cancel'}, {label: 'OK', value: 'ok'}]});
	if (answer !== 'ok') {
		return;
	}

	let removed = 0;
	for (const item of inTrash) {
		if (item.id === 'system') {
			await showAlert({icon: 'stop', text: 'The Trash cannot be emptied, because the item “System Folder” is in use.', detail: 'It stays in the Trash. Hmm. What happens at the next restart?'});
			continue;
		}

		if (item.locked) {
			const choice = await showAlert({icon: 'caution', text: `The item “${item.name}” is locked, so it cannot be deleted.`, detail: 'Holding Option while choosing Empty Trash deletes locked items too.', buttons: [{label: 'Keep It', value: 'cancel'}, {label: 'Delete Anyway (Option)', value: 'delete'}]});
			if (choice !== 'delete') {
				continue;
			}

			toast('Homework deleted. “The computer ate it” is now true.');
		}

		items = items.filter(other => other !== item);
		removed++;
	}

	if (removed > 0) {
		platinumSound('trash');
	}

	renderDesktop();
};

// An icon opens with a double-click, or two taps, or Enter, and drags with the mouse or a finger: onto the Trash to throw it away, or somewhere else on the desktop.
const setUpIcon = (button, item) => {
	let press;
	let lastClick = 0;

	button.addEventListener('click', event => {
		if (button.dataset.macDragged !== undefined) {
			delete button.dataset.macDragged;
			return;
		}

		if (event.detail === 0) {
			select(item);
			openItem(item, button);
			return;
		}

		const now = performance.now();
		if (session.selected === item && now - lastClick < 550) {
			lastClick = 0;
			openItem(item, button);
		} else {
			lastClick = now;
			select(item);
		}
	});

	button.addEventListener('pointerdown', event => {
		if (event.button !== 0) {
			return;
		}

		press = {x: event.clientX, y: event.clientY, id: event.pointerId, isDragging: false};
	});

	button.addEventListener('pointermove', event => {
		if (!press || press.id !== event.pointerId) {
			return;
		}

		const dx = event.clientX - press.x;
		const dy = event.clientY - press.y;
		if (!press.isDragging && Math.hypot(dx, dy) > 6) {
			press.isDragging = true;
			button.setPointerCapture(event.pointerId);
			select(item);
			const isOnDesktop = button.parentElement === iconLayer;
			press.ghost = isOnDesktop ? button : button.cloneNode(true);
			if (!isOnDesktop) {
				const rectangle = button.getBoundingClientRect();
				const layer = iconLayer.getBoundingClientRect();
				press.ghost.style.position = 'absolute';
				press.ghost.style.opacity = '0.6';
				press.ghost.style.zIndex = '1500';
				iconLayer.append(press.ghost);
				press.start = {x: rectangle.left - layer.left, y: rectangle.top - layer.top};
			} else {
				press.start = {x: item.x, y: item.y};
				button.style.zIndex = '5';
			}
		}

		if (press.isDragging) {
			press.ghost.style.left = `${press.start.x + dx}px`;
			press.ghost.style.top = `${press.start.y + dy}px`;
			const target = dropTargetAt(event.clientX, event.clientY, press.ghost);
			for (const trash of root.querySelectorAll('[data-mac-icon="trash"]')) {
				if (trash === target && item.id !== 'trash') {
					trash.dataset.macSelected = '';
				} else if (session.selected?.id !== 'trash') {
					delete trash.dataset.macSelected;
				}
			}
		}
	});

	const finish = event => {
		if (!press?.isDragging) {
			press = undefined;
			return;
		}

		const {ghost, start} = press;
		const dx = event.clientX - press.x;
		const dy = event.clientY - press.y;
		const target = dropTargetAt(event.clientX, event.clientY, ghost);
		press = undefined;
		button.dataset.macDragged = '';
		setTimeout(() => {
			delete button.dataset.macDragged;
		}, 50);

		if (ghost !== button) {
			ghost.remove();
		} else {
			button.style.zIndex = '';
			item.x = start.x + dx;
			item.y = start.y + dy;
		}

		if (target?.dataset.macIcon === 'trash' && item.id !== 'trash') {
			moveToTrash(item);
		} else {
			placeIcons();
			select(item);
		}
	};

	button.addEventListener('pointerup', finish);
	button.addEventListener('pointercancel', finish);
};

const dropTargetAt = (x, y, ghost) => {
	ghost.style.visibility = 'hidden';
	const target = document.elementFromPoint(x, y)?.closest('[data-mac-icon="trash"], [data-mac-window="trash"]');
	ghost.style.visibility = '';
	return target?.dataset.macWindow === 'trash' ? itemButtons.get('trash') : target;
};

desktop.addEventListener('pointerdown', event => {
	if (event.target === pictureCanvas || event.target === iconLayer) {
		select(undefined);
	}
});

// The CD tray slides out of the iMac with the CD, and the CD goes back in with the tray.
const eject = () => {
	if (!session.cdInDrive || session.trayOpen) {
		return;
	}

	session.trayOpen = true;
	tray.hidden = false;
	renderDesktop();
	announce(status, 'The CD tray slid out. Push it back in with the button on the tray.');
};

trayCD.addEventListener('click', () => {
	session.trayOpen = false;
	tray.hidden = true;
	if (session.power === 'on') {
		renderDesktop();
	}

	announce(status, 'The tray is in. The CD spins up: vrrrrrr.');
	powerButton.focus();
});

// The clock of the menu bar, which shows the date when clicked. Zapping the PRAM sets it to 1904, the first year of the Mac clock, and Y2K Fixer 99 “fixes” the year.
let isShowingDate = false;

const updateClock = () => {
	const now = new Date();
	const waffle = isExtensionActive('waffleclock') ? '🧇 ' : '';
	if (isShowingDate) {
		const year = session.pramZapped ? 1904 : (isExtensionActive('y2k') ? 19_100 : 1999);
		const date = session.pramZapped ? new Date(1904, 0, 1) : now;
		clock.textContent = `${waffle}${date.toLocaleDateString('en-US', {weekday: 'short', month: 'short', day: 'numeric'})}, ${year}`;
	} else {
		clock.textContent = `${waffle}${now.toLocaleTimeString('en-US', {hour: 'numeric', minute: '2-digit'})}`;
	}
};

clock.addEventListener('click', () => {
	isShowingDate = !isShowingDate;
	updateClock();
	if (isShowingDate && session.pramZapped) {
		announce(status, 'January 1, 1904? Zapping the PRAM reset the clock to the first day of the Mac calendar.');
	}
});

setInterval(() => {
	if (session.power === 'on' && !document.hidden) {
		updateClock();
	}
}, 20_000);

// Balloon Help: while it is on, a balloon tells what the thing under the pointer, or with the focus, is.
const showBalloon = element => {
	const text = element.dataset.macBalloon ?? balloonTexts[element.dataset.macMenu] ?? balloonTexts[element.id];
	if (!text) {
		return;
	}

	balloon.textContent = text;
	balloon.hidden = false;
	const screenRectangle = screen.getBoundingClientRect();
	const rectangle = element.getBoundingClientRect();
	const left = clamp(rectangle.left - screenRectangle.left + (rectangle.width / 2) - (balloon.offsetWidth / 2), 4, screen.clientWidth - balloon.offsetWidth - 4);
	const below = rectangle.bottom - screenRectangle.top + 6;
	const top = below + balloon.offsetHeight > screen.clientHeight ? rectangle.top - screenRectangle.top - balloon.offsetHeight - 6 : below;
	balloon.style.left = `${left}px`;
	balloon.style.top = `${Math.max(top, 2)}px`;
};

const balloonTexts = {
	apple: 'The Apple menu. The desk accessories and control panels are here. You can put anything in it, like I put Bugdom Jr.',
	file: 'The File menu, for opening things, Get Info, and printing.',
	edit: 'The Edit menu. Copy and Paste work between the Scrapbook, Note Pad, Stickies, and the Puzzle.',
	view: 'The View menu, to tidy the icons of the desktop.',
	special: 'The Special menu: Empty Trash, Eject, Sleep, Restart, and Shut Down.',
	help: 'The Help menu. You found Balloon Help! Choose Hide Balloons to make them go away.',
	'geocities-mac-clock': 'The clock. Click it to see the date.',
	'geocities-mac-app-menu-button': 'The Application menu. It shows the programs that run, and switches between them.',
	'geocities-mac-strip-tab': 'The tab of the Control Strip. Click it to fold the strip away.',
};

const onBalloonTarget = event => {
	if (!session.balloons) {
		return;
	}

	const element = event.target.closest?.('[data-mac-balloon], [data-mac-menu], #geocities-mac-clock, #geocities-mac-app-menu-button, #geocities-mac-strip-tab');
	if (element && desktop.contains(element)) {
		showBalloon(element);
	} else {
		balloon.hidden = true;
	}
};

desktop.addEventListener('pointerover', onBalloonTarget);
desktop.addEventListener('focusin', onBalloonTarget);
desktop.addEventListener('pointerleave', () => {
	balloon.hidden = true;
});

// The Control Strip: each module does its job at a click, and the tab folds the strip away.
const depths = [['millions', 'Millions of colors'], ['thousands', 'Thousands of colors'], ['256', '256 colors'], ['gray', '16 grays'], ['bw', 'Black & White']];

const applyDepth = () => {
	screen.dataset.macDepth = settings.depth;
};

const updateStrip = () => {
	strip.hidden = !isExtensionActive('controlstrip') || session.extensionsOff;
	for (const module of stripModules.querySelectorAll('[data-mac-strip-module]')) {
		const name = module.dataset.macStripModule;
		const isOn = {appletalk: settings.appleTalk, sharing: session.fileSharing, speech: settings.talkingAlerts}[name];
		module.dataset.state = isOn ? 'on' : '';
		if (name === 'volume') {
			module.textContent = settings.volume === 0 ? '🔇' : '🔊';
		}
	}
};

stripModules.addEventListener('click', event => {
	const module = event.target.closest('[data-mac-strip-module]');
	if (!module) {
		return;
	}

	const name = module.dataset.macStripModule;
	if (name === 'volume') {
		settings.volume = (settings.volume + 1) % 8;
		announce(status, `Volume: ${settings.volume} of 7.${speakersOn ? '' : ' (The speakers are off.)'}`);
		beep();
	} else if (name === 'depth') {
		const index = depths.findIndex(([depth]) => depth === settings.depth);
		const [depth, title] = depths[(index + 1) % depths.length];
		settings.depth = depth;
		applyDepth();
		announce(status, `Monitor: ${title}.${depth === 'bw' ? ' Like the Macs of 1984!' : ''}`);
	} else if (name === 'appletalk') {
		settings.appleTalk = !settings.appleTalk;
		announce(status, settings.appleTalk ? 'AppleTalk is active. It looks for other Macs. There are none.' : 'AppleTalk is inactive.');
		updateChooser();
	} else if (name === 'sharing') {
		session.fileSharing = !session.fileSharing;
		announce(status, session.fileSharing ? 'File Sharing is on. Nobody came.' : 'File Sharing is off.');
	} else if (name === 'speech') {
		settings.talkingAlerts = !settings.talkingAlerts;
		if (settings.talkingAlerts) {
			ensureSpeakers();
		}

		windowPart('speech', 'talking').checked = settings.talkingAlerts;
		announce(status, settings.talkingAlerts ? 'Talking Alerts are on. Now make something crash.' : 'Talking Alerts are off.');
	}

	persist();
	updateStrip();
});

stripTab.addEventListener('click', () => {
	const isOpen = stripModules.hidden;
	stripModules.hidden = !isOpen;
	stripTab.setAttribute('aria-expanded', String(isOpen));
	stripTab.textContent = isOpen ? '▸' : '◂';
});

// The keys to hold at the next startup, which stay down until then. Holding the real Shift key while pressing the power button works too.
const keyButtons = [...root.querySelectorAll('[data-mac-startup-key]')];

const setKey = (key, isDown) => {
	if (isDown) {
		session.keys.add(key);
	} else {
		session.keys.delete(key);
	}

	setPressed(keyButtons.find(button => button.dataset.macStartupKey === key), isDown);
};

for (const button of keyButtons) {
	button.addEventListener('click', () => {
		const key = button.dataset.macStartupKey;
		const isDown = !session.keys.has(key);
		setKey(key, isDown);
		if (isDown) {
			announce(status, session.power === 'on' ? 'Held down. Now choose Restart in the Special menu.' : 'Held down. Now press the power button.');
		}
	});
}

const releaseKeys = () => {
	for (const key of [...session.keys]) {
		setKey(key, false);
	}
};

// The power: the iMac starts up, shuts down, sleeps, and crashes. Each startup reads the keys that are held down.
let bootRun = 0;
let flashTimer;

const setLED = state => {
	led.dataset.state = state === 'on' ? 'on' : '';
	if (state === 'sleep') {
		led.dataset.macSleeping = '';
	} else {
		delete led.dataset.macSleeping;
	}

	powerButton.setAttribute('aria-pressed', String(state !== 'off'));
};

const showLayer = layer => {
	clearInterval(flashTimer);
	offLayer.hidden = layer !== offLayer;
	bootLayer.hidden = layer !== bootLayer;
	desktop.hidden = layer !== desktop;
	balloon.hidden = true;
	stopSaver();
	if (desktop.hidden && desktop.contains(document.activeElement)) {
		powerButton.focus({preventScroll: true});
	}
};

const resetBootScreen = () => {
	bootLayer.style.background = '';
	welcome.hidden = true;
	bootNote.textContent = '';
	bootMessage.textContent = '';
	bootMessage.style.color = '';
	extensionRow.replaceChildren();
	progressBar.style.width = '0%';
	bootIcon.hidden = false;
};

const quitAll = () => {
	for (const id of [...running.keys()]) {
		quitProgram(id);
	}

	for (const element of windowOrder) {
		element.hidden = true;
	}

	closeMenus();
	stopSpeaking();
};

const turnOff = (message = 'Press the power button below the screen.') => {
	bootRun++;
	quitAll();
	session.power = 'off';
	setLED('off');
	offText.textContent = message;
	showLayer(offLayer);
};

// A wait that ends early when the startup is cancelled, like by the power button, so an old startup does not carry on.
const step = async (run, milliseconds) => {
	await wait(milliseconds);
	if (run !== bootRun) {
		throw new Error('The startup was cancelled.');
	}
};

const boot = async ({isRestart = false} = {}) => {
	bootRun++;
	const run = bootRun;
	quitAll();
	session.power = 'booting';
	setLED('on');
	showLayer(bootLayer);
	resetBootScreen();
	const keys = new Set(session.keys);
	releaseKeys();

	try {
		// RAM from the Internet: the Sad Mac, on black, with the Chimes of Death.
		if (settings.ram === 'downloaded') {
			bootLayer.style.background = '#000';
			drawSpriteOnCanvas(bootIcon, 'sadMac');
			bootMessage.style.color = '#fff';
			bootMessage.textContent = '0000000F 00000003';
			playChimesOfDeath();
			await step(run, 2600);
			bootMessage.style.color = '';
			const answer = await showAlert({icon: 'sadMac', text: 'The Sad Mac! The RAM you downloaded is not real RAM.', detail: speakersOn ? 'That sound was the Chimes of Death. (A real iMac only beeps. Mine is special.)' : 'Turn on the speakers to hear the Chimes of Death. (A real iMac only beeps. Mine is special.)', buttons: [{label: 'Turn It Off', value: 'off'}, {label: 'Take Out the Downloaded RAM', value: 'fix'}], isLow: true});
			if (answer === 'fix') {
				settings.ram = 'none';
				persist();
				toast('The downloaded RAM is in the Trash. It was 0 bytes anyway.');
				boot({isRestart: true});
			} else {
				turnOff();
			}

			return;
		}

		drawSpriteOnCanvas(bootIcon, 'happyMac');
		playChime();
		if (keys.has('pram')) {
			for (let chime = 2; chime <= 3; chime++) {
				bootMessage.textContent = `Bong! ${chime === 2 ? 'Keep holding: one more chime.' : 'Chime number 3. The PRAM is zapped.'}`;
				await step(run, 1600);
				playChime();
			}

			session.pramZapped = true;
			settings.volume = 3;
			settings.depth = 'millions';
			settings.appleTalk = false;
			persist();
			applyDepth();
			bootMessage.textContent = 'The PRAM is zapped: the clock, the volume, the monitor, and AppleTalk are back to how they came from the factory.';
		}

		const useCD = keys.has('cd') && session.cdInDrive && !session.trayOpen;
		if (keys.has('cd') && !useCD) {
			bootMessage.textContent = 'You held C, but there is no CD in the drive.';
		}

		await step(run, 900);

		// No System Folder on the disk, and no CD: the flashing question mark.
		if (session.systemInTrash && !useCD) {
			const isMoving = !reducedMotion.matches;
			let flash = false;
			drawSpriteOnCanvas(bootIcon, 'question');
			if (isMoving) {
				flashTimer = setInterval(() => {
					flash = !flash;
					drawSpriteOnCanvas(bootIcon, flash ? 'finder' : 'question');
				}, 600);
			}

			bootMessage.textContent = 'A flashing question mark: the iMac cannot find a System Folder. (It is in the Trash!) Hold C to start up from the Mac OS 8.6 CD, and install Mac OS again.';
			session.power = 'question';
			return;
		}

		session.fromCD = useCD;
		session.extensionsOff = keys.has('shift');
		welcome.hidden = false;
		drawFace(root.querySelector('#geocities-mac-face'), 64);
		bootNote.textContent = session.extensionsOff ? 'Extensions Off' : (useCD ? 'Starting up from the CD' : '');
		progressBar.style.width = '8%';

		if (session.improperShutdown) {
			bootMessage.textContent = 'Because your computer was not shut down properly, Disk First Aid is checking the disk “Macintosh HD”.';
			await step(run, 1800);
			bootMessage.textContent = 'Disk First Aid found no problems. (It never does.)';
			await step(run, 600);
		}

		session.improperShutdown = false;

		// The extensions load one after the other, each with its icon at the bottom. The conflict crashes a restart, never a cold start, so the first start always works.
		const toLoad = session.extensionsOff ? [] : extensions.filter(extension => settings.enabled[extension.id]);
		const isFast = toLoad.some(extension => extension.id === 'speeddoubler');
		session.active = new Set();
		for (const [index, extension] of toLoad.entries()) {
			const icon = document.createElement('img');
			icon.src = spriteURL('extension', extension.color);
			icon.alt = '';
			icon.width = 32;
			icon.height = 32;
			icon.title = extension.name;
			extensionRow.append(icon);
			session.active.add(extension.id);
			progressBar.style.width = `${10 + ((index + 1) / toLoad.length * 70)}%`;
			await step(run, isFast ? 90 : 220);
		}

		const culprit = settings.culprit;
		if (isRestart && culprit && session.active.has(culprit) && !useCD) {
			await step(run, 400);
			if (!session.isHunting) {
				session.isHunting = true;
				session.huntRestarts = 0;
				session.suspects = shareware.filter(extension => session.active.has(extension.id)).map(extension => extension.id);
			}

			systemError('Finder', 'Unimplemented trap', {duringStartup: true});
			return;
		}

		progressBar.style.width = '100%';
		bootMessage.textContent = useCD ? '' : (session.extensionsOff ? 'Extensions Off: no extensions, no conflicts, and no Control Strip.' : bootMessage.textContent);

		if (keys.has('rebuild') && !useCD) {
			const answer = await showAlert({icon: 'caution', text: 'Are you sure you want to rebuild the desktop file on the disk “Macintosh HD”?', detail: 'Comments in info windows will be lost.', buttons: [{label: 'Cancel', value: 'cancel'}, {label: 'OK', value: 'ok'}]});
			if (run !== bootRun) {
				return;
			}

			if (answer === 'ok') {
				bootMessage.textContent = 'Rebuilding the desktop file on the disk “Macintosh HD”…';
				for (let percent = 0; percent <= 100; percent += 20) {
					progressBar.style.width = `${percent}%`;
					await step(run, 350);
				}

				const fixed = session.genericIcons.size;
				session.genericIcons.clear();
				session.commentsLost = true;
				bootMessage.textContent = fixed > 0 ? `The desktop is rebuilt. ${fixed} blank icon${fixed === 1 ? ' has its picture' : 's have their pictures'} back.` : 'The desktop is rebuilt. It was fine. It feels cleaner anyway.';
			}
		}

		await step(run, 700);
		showDesktop();
		session.hasBooted = true;

		// A startup after the conflict, with the conflicting extension off and all the other shareware of the crash on, has found it.
		if (session.isHunting && culprit && !session.active.has(culprit) && !session.extensionsOff && session.suspects.every(id => id === culprit || session.active.has(id))) {
			const found = extensions.find(extension => extension.id === culprit);
			session.isHunting = false;
			settings.conflictsFound++;
			settings.culprit = '';
			persist();
			celebrate();
			await showAlert({icon: 'finder', text: `You found it! “${found.name}” was the extension that crashed my iMac.`, detail: `It took you ${session.huntRestarts} restart${session.huntRestarts === 1 ? '' : 's'}. I e-mailed the author, and he sent a new version that does not crash. You can turn it on again. The Extensions Manager can install more shareware, for a new conflict.`});
			renderExtensions();
		}
	} catch (error) {
		if (run === bootRun) {
			throw error;
		}
	}
};

const showDesktop = () => {
	session.power = 'on';
	showLayer(desktop);
	applyTheme();
	applyDepth();
	drawPicture();
	updateClock();
	updateStrip();
	renderDesktop();
	setFrontProgram('finder');
	updateMemory();
	if (session.fromCD) {
		launch('installer');
	} else if (settings.stickies.length > 0) {
		// Stickies is in the Startup Items, so the notes come back after each start.
		launch('stickies');
	}

	resetIdle();
	iconLayer.querySelector('button')?.focus({preventScroll: true});
};

// The bomb: “Sorry, a system error occurred.”, with Restart, and Resume grayed out. After it, the next start checks the disk, and the desktop file may lose an icon.
const systemError = async (name, error, {duringStartup = false} = {}) => {
	bootRun++;
	session.power = 'crashed';
	session.improperShutdown = true;
	closeMenus();
	if (Math.random() < 0.5) {
		session.genericIcons.add(randomItem(['readme', 'bugdom-alias', 'netscape', 'hd']));
	}

	await showAlert({icon: 'bomb', text: 'Sorry, a system error occurred.', detail: `“${name}” ${error}. ${duringStartup ? 'To temporarily turn off extensions, restart and hold down the Shift key.' : 'Everything that was not saved is gone.'}`, buttons: [{label: 'Resume', value: 'resume', disabled: true}, {label: 'Restart', value: 'restart'}]});
	if (session.isHunting) {
		session.huntRestarts++;
	}

	session.unstable = false;
	boot({isRestart: true});
};

const restart = () => {
	if (session.isHunting) {
		session.huntRestarts++;
	}

	session.unstable = false;
	boot({isRestart: true});
};

const sleep = () => {
	quitAll();
	session.power = 'sleep';
	setLED('sleep');
	offText.textContent = 'Zzz… The iMac sleeps. Click the screen, or press the power button, to wake it.';
	showLayer(offLayer);
	session.sleepingFromDesktop = true;
};

const wake = () => {
	session.power = 'on';
	setLED('on');
	showDesktop();
};

offLayer.addEventListener('click', () => {
	if (session.power === 'sleep') {
		wake();
	}
});

const shutDown = () => {
	session.improperShutdown = false;
	session.unstable = false;
	turnOff('The iMac shut itself down. (A Mac switches itself off. A PC says “It’s now safe to turn off your computer.”)');
	announce(status, 'Shut down. Press the power button to start it again.');
};

// The power button: on a running iMac, it asks what to do, like the power key of a Mac. On a stuck one, it turns it off.
powerButton.addEventListener('click', async event => {
	if (event.shiftKey && session.power === 'off') {
		setKey('shift', true);
	}

	if (session.power === 'off') {
		boot({isRestart: session.hasBooted});
	} else if (session.power === 'sleep') {
		wake();
	} else if (session.power === 'on') {
		const answer = await showAlert({icon: 'finder', text: 'Are you sure you want to shut down your computer now?', buttons: [{label: 'Restart', value: 'restart'}, {label: 'Sleep', value: 'sleep'}, {label: 'Cancel', value: 'cancel'}, {label: 'Shut Down', value: 'shut-down'}]});
		if (answer === 'restart') {
			restart();
		} else if (answer === 'sleep') {
			sleep();
		} else if (answer === 'shut-down') {
			shutDown();
		}
	} else if (alertBox.hidden) {
		session.improperShutdown = session.power !== 'question';
		turnOff();
	}
});

speakersButton.addEventListener('click', () => {
	setSpeakers(!speakersOn);
	if (speakersOn) {
		audio();
		beep();
	}
});

// The commands of the menus, and of the buttons that do the same.
const actions = {
	'open-about'(opener) {
		openWindow('about', opener);
	},
	'new-folder'() {
		session.folderCount++;
		const item = {id: `folder-${session.folderCount}`, name: session.folderCount === 1 ? 'untitled folder' : `untitled folder ${session.folderCount}`, icon: 'folder', place: 'desktop', kind: 'folder', size: 'zero K'};
		items.push(item);
		renderDesktop();
		select(item);
		itemButtons.get(item.id)?.focus();
	},
	'open-selected'(opener) {
		if (session.selected) {
			openItem(session.selected, opener);
		}
	},
	'close-window'() {
		const front = frontWindow();
		if (front) {
			closeWindow(front);
		}
	},
	'get-info'(opener) {
		showInfo(session.selected, opener);
	},
	'move-to-trash'() {
		if (session.selected) {
			moveToTrash(session.selected);
		}
	},
	'put-away'() {
		if (session.selected?.inTrash) {
			putAway(session.selected);
		}
	},
	'page-setup'(opener) {
		openWindow('pagesetup', opener);
	},
	print() {
		printFront();
	},
	quit() {
		quitProgram(frontProgram);
	},
	copy() {
		editCommand('copy');
	},
	paste() {
		editCommand('paste');
	},
	clear() {
		editCommand('clear');
	},
	'show-clipboard'(opener) {
		openWindow('clipboard', opener);
	},
	'clean-up'() {
		for (const item of items) {
			if (item.place === 'desktop') {
				item.x = undefined;
				item.y = undefined;
			}
		}

		renderDesktop();
	},
	arrange() {
		items.sort((first, second) => first.name.localeCompare(second.name));
		actions['clean-up']();
	},
	'empty-trash'() {
		emptyTrash();
	},
	eject() {
		eject();
	},
	sleep() {
		sleep();
	},
	restart() {
		restart();
	},
	'shut-down'() {
		shutDown();
	},
	balloons() {
		session.balloons = !session.balloons;
		balloon.hidden = true;
		announce(status, session.balloons ? 'Balloon Help is on. Point at things on the screen.' : 'Balloon Help is off.');
	},
};

const runAction = (action, opener) => {
	resetIdle();
	if (action.startsWith('launch-')) {
		launch(action.slice('launch-'.length), opener);
	} else {
		actions[action]?.(opener);
	}
};

// About This Computer: the memory, with a bar for each program that runs. Add Memory puts RAM in the iMac, from a shop or from the Internet.
const updateMemory = () => {
	const about = windowsByName.get('about');
	part(about, 'built-in').textContent = `${builtInMemory() / 1024} MB`;
	part(about, 'virtual').textContent = isExtensionActive('ramdoubler') ? `${totalMemory() / 1024} MB with RAM Doubler` : 'Off';
	part(about, 'largest').textContent = `${(Math.max(freeMemory(), 0) / 1024).toFixed(1)} MB`;
	const list = part(about, 'memory');
	const template = part(about, 'memory-template');
	list.replaceChildren();
	const rows = [['Mac OS', 'finder', systemMemory], ...[...running].filter(([id]) => id !== 'finder').map(([id, size]) => [programs[id].title, programs[id].icon, size])];
	for (const [title, icon, size] of rows) {
		const row = template.content.firstElementChild.cloneNode(true);
		const [image, name, sizeLabel, bar] = row.children;
		image.src = spriteURL(icon);
		name.textContent = title;
		sizeLabel.textContent = formatK(size);
		bar.firstElementChild.style.width = `${clamp(size / totalMemory() * 100 * 2, 2, 100)}%`;
		list.append(row);
	}
};

windowPart('about', 'add-ram').addEventListener('click', async event => {
	const buttons = settings.ram === 'stick' ? [{label: 'Cancel', value: 'cancel'}, {label: 'Take Out the 64 MB', value: 'none'}] : [{label: 'Cancel', value: 'cancel'}, {label: 'Download RAM (free!)', value: 'downloaded'}, {label: '64 MB from the shop (499 kr)', value: 'stick'}];
	const answer = await showAlert({icon: 'finder', text: settings.ram === 'stick' ? 'My iMac has the 64 MB from the shop.' : 'Which RAM do you want to put in the iMac?', detail: 'You need a screwdriver. The iMac opens from the bottom. Then it restarts.', buttons});
	if (answer === 'cancel') {
		event.target.focus();
		return;
	}

	settings.ram = answer;
	persist();
	toast(answer === 'downloaded' ? 'You downloaded RAM. That went very fast for 64 MB over a modem…' : (answer === 'stick' ? '64 MB more! 96 MB in all. Bugdom will love it.' : 'The 64 MB is out. Back to 32 MB.'));
	restart();
});

// Get Info of the selected item: what it is, its comments, and for a program, how much memory it asks for. Rebuilding the desktop loses the comments, like on a real Mac.
let infoItem;

const showInfo = (item, opener) => {
	if (!item) {
		return;
	}

	infoItem = item;
	const info = windowsByName.get('info');
	info.querySelector('h3').textContent = `${item.name} Info`;
	part(info, 'icon').src = spriteURL(iconFor(item));
	part(info, 'name').textContent = item.name;
	part(info, 'kind').textContent = item.kind + (item.locked ? ' (locked)' : '');
	part(info, 'size').textContent = item.id === 'trash' ? `${trashItems().length} items` : (item.size ?? '—');
	part(info, 'comments').textContent = session.commentsLost ? '(lost when the desktop was rebuilt)' : (item.comment ?? '');
	const program = programs[item.program];
	const fieldset = part(info, 'memory');
	fieldset.hidden = !program || item.kind === 'SimpleText document';
	if (program) {
		part(info, 'suggested').textContent = (program.needs ?? program.preferred).toLocaleString('en-US');
		part(info, 'minimum').value = program.minimum;
		part(info, 'preferred').value = program.preferred;
	}

	part(info, 'note').textContent = item.id === 'system' ? 'In the Trash is not a good place for it.' : '';
	openWindow('info', opener);
};

const onMemoryChange = () => {
	const info = windowsByName.get('info');
	const program = programs[infoItem?.program];
	if (!program) {
		return;
	}

	const minimum = clamp(Math.round(Number(part(info, 'minimum').value) || program.minimum), 100, 60_000);
	const preferred = clamp(Math.round(Number(part(info, 'preferred').value) || program.preferred), minimum, 60_000);
	program.minimum = minimum;
	program.preferred = preferred;
	settings.memory[infoItem.program] = {minimum, preferred};
	persist();
	const needs = program.needs;
	announce(part(info, 'note'), `${running.has(infoItem.program) ? 'It takes effect the next time it opens.' : 'Saved.'}${needs && preferred < needs ? ` Careful: it needs ${formatK(needs)} to run.` : ''}`);
};

windowPart('info', 'minimum').addEventListener('change', onMemoryChange);
windowPart('info', 'preferred').addEventListener('change', onMemoryChange);

// The Extensions Manager: a checkbox for each extension, which takes effect at the next restart, and sets of them.
const extensionList = windowPart('extensions', 'list');
const extensionInfo = windowPart('extensions', 'info');

const renderExtensions = () => {
	extensionList.replaceChildren();
	for (const extension of extensions) {
		const row = rowTemplate.content.firstElementChild.cloneNode(true);
		const checkbox = row.querySelector('input');
		checkbox.checked = settings.enabled[extension.id];
		checkbox.value = extension.id;
		const image = document.createElement('img');
		image.src = spriteURL('extension', extension.color);
		image.alt = '';
		image.width = 16;
		image.height = 16;
		row.querySelector('span').textContent = `${extension.name} ${extension.version}${extension.isApple ? '' : ' (shareware)'}`;
		row.querySelector('label').insertBefore(image, row.querySelector('span'));
		const describe = () => {
			extensionInfo.textContent = `${extension.name}: ${extension.info}`;
		};

		checkbox.addEventListener('focus', describe);
		row.addEventListener('pointerenter', describe);
		checkbox.addEventListener('change', () => {
			settings.enabled[extension.id] = checkbox.checked;
			settings.set = 'mine';
			windowPart('extensions', 'set').value = 'mine';
			persist();
			announce(extensionInfo, `${extension.name} will be ${checkbox.checked ? 'on' : 'off'} after a restart.`);
		});
		extensionList.append(row);
	}

	windowPart('extensions', 'set').value = settings.set;
	if (!settings.culprit) {
		extensionInfo.textContent = `No conflicts right now. You have found ${settings.conflictsFound}. Install more shareware for a new one.`;
		windowPart('extensions', 'all-on').textContent = 'Install More Shareware';
	} else {
		windowPart('extensions', 'all-on').textContent = 'All On';
	}
};

onOpen.extensions = renderExtensions;

windowPart('extensions', 'set').addEventListener('change', event => {
	const set = event.target.value;
	settings.set = set;
	if (set !== 'mine') {
		for (const extension of extensions) {
			settings.enabled[extension.id] = set === 'all' ? extension.isApple : ['appearance', 'opentransport', 'usb'].includes(extension.id);
		}
	}

	persist();
	renderExtensions();
	announce(extensionInfo, set === 'mine' ? 'My Settings.' : `${event.target.selectedOptions[0].textContent}: only the extensions of Apple. Restart to try it.`);
});

windowPart('extensions', 'all-off').addEventListener('click', () => {
	for (const extension of shareware) {
		settings.enabled[extension.id] = false;
	}

	persist();
	renderExtensions();
	announce(extensionInfo, 'All the shareware is off. Restart to see if it still crashes.');
});

windowPart('extensions', 'all-on').addEventListener('click', () => {
	if (!settings.culprit) {
		settings.culprit = randomItem(shareware).id;
		toast('You installed more shareware from the CD of Macworld. One of the extensions does not like the others…');
	}

	for (const extension of extensions) {
		settings.enabled[extension.id] = true;
	}

	settings.set = 'mine';
	persist();
	renderExtensions();
	announce(extensionInfo, 'Everything is on. Restart, and see what happens.');
});

windowPart('extensions', 'restart').addEventListener('click', () => {
	restart();
});

// The Appearance: the themes, which need the Kaleidoscope extension after Platinum, the desktop pictures, and the sounds.
const applyTheme = () => {
	const theme = !isExtensionActive('appearance') ? 'system7' : (settings.theme !== 'platinum' && !isExtensionActive('kaleidoscope') ? 'platinum' : settings.theme);
	screen.dataset.macTheme = theme;
};

onLaunch.appearance = async opener => {
	if (!isExtensionActive('appearance')) {
		quitProgram('appearance');
		await showAlert({icon: 'stop', text: 'The Appearance control panel cannot be used, because the Appearance Extension is off.', detail: 'Turn it on in the Extensions Manager, and restart.'});
		return;
	}

	openWindow('appearance', opener);
};

const appearance = windowsByName.get('appearance');

onOpen.appearance = () => {
	for (const radio of appearance.querySelectorAll('[data-mac-part="theme"]')) {
		radio.checked = radio.value === settings.theme;
	}

	for (const radio of appearance.querySelectorAll('[data-mac-part="picture"]')) {
		radio.checked = radio.value === settings.picture;
	}

	part(appearance, 'soundtrack').value = settings.soundTrack;
	part(appearance, 'alert-sound').value = settings.alertSound;
};

for (const tab of ['themes', 'desktop', 'sound']) {
	part(appearance, `tab-${tab}`).addEventListener('click', () => {
		for (const other of ['themes', 'desktop', 'sound']) {
			setPressed(part(appearance, `tab-${other}`), other === tab);
			part(appearance, `panel-${other}`).hidden = other !== tab;
		}
	});
}

setPressed(part(appearance, 'tab-themes'), true);

appearance.addEventListener('change', async event => {
	const name = event.target.dataset.macPart;
	if (name === 'theme') {
		if (event.target.value !== 'platinum' && !isExtensionActive('kaleidoscope')) {
			await showAlert({icon: 'caution', text: `The theme “${event.target.parentElement.textContent.trim()}” is a Kaleidoscope scheme, and the Kaleidoscope extension is off.`, detail: 'Turn it on in the Extensions Manager, and restart.'});
			onOpen.appearance();
			return;
		}

		settings.theme = event.target.value;
		applyTheme();
		if (settings.theme === 'windows') {
			toast('Windoze 95: my iMac in disguise. Do not tell Steve Jobs.');
		}
	} else if (name === 'picture') {
		settings.picture = event.target.value;
		drawPicture();
	} else if (name === 'soundtrack') {
		settings.soundTrack = event.target.value;
		if (settings.soundTrack === 'platinum') {
			ensureSpeakers();
			platinumSound('menu');
		}
	} else if (name === 'alert-sound') {
		settings.alertSound = event.target.value;
	}

	persist();
});

part(appearance, 'try-alert').addEventListener('click', () => {
	ensureSpeakers();
	beep();
});

// The desktop pictures, drawn on the canvas behind the icons: patterns of 8 × 8 pixels, like the Mac had since 1984, and pictures.
const patterns = {
	default: {rows: ['10001000', '01010101', '00100010', '01010101', '10001000', '01010101', '00100010', '01010101'], colors: ['#6f6fbf', '#8a8ad6']},
	bondi: {rows: ['10000000', '00000000', '00001000', '00000000', '10000000', '00000000', '00001000', '00000000'], colors: ['#0095b6', '#2bb3cc']},
	waffle: {rows: ['11111111', '10000001', '10000001', '10011001', '10011001', '10000001', '10000001', '11111111'], colors: ['#e6b45c', '#a8701e']},
	gray: {rows: ['10101010', '01010101', '10101010', '01010101', '10101010', '01010101', '10101010', '01010101'], colors: ['#ffffff', '#000000']},
};

const drawPicture = () => {
	const width = Math.max(desktop.clientWidth, 1);
	const height = Math.max(desktop.clientHeight, 1);
	pictureCanvas.width = width;
	pictureCanvas.height = height;
	const context = pictureCanvas.getContext('2d');
	const pattern = patterns[settings.picture];
	if (pattern) {
		const tile = document.createElement('canvas');
		tile.width = 16;
		tile.height = 16;
		const tileContext = tile.getContext('2d');
		for (const [y, row] of pattern.rows.entries()) {
			for (const [x, bit] of [...row].entries()) {
				tileContext.fillStyle = pattern.colors[Number(bit)];
				tileContext.fillRect(x * 2, y * 2, 2, 2);
			}
		}

		context.fillStyle = context.createPattern(tile, 'repeat');
		context.fillRect(0, 0, width, height);
		return;
	}

	if (settings.picture === 'clouds') {
		const sky = context.createLinearGradient(0, 0, 0, height);
		sky.addColorStop(0, '#3a7bd5');
		sky.addColorStop(1, '#a8d8ff');
		context.fillStyle = sky;
		context.fillRect(0, 0, width, height);
		context.fillStyle = 'rgba(255, 255, 255, 0.85)';
		for (let index = 0; index < 9; index++) {
			const x = ((index * 0.37) % 1) * width;
			const y = (((index * 0.53) + 0.1) % 0.8) * height;
			for (let puff = 0; puff < 5; puff++) {
				context.beginPath();
				context.arc(x + (puff * 22), y + (Math.sin(puff * 2) * 8), 22 + ((puff % 3) * 6), 0, Math.PI * 2);
				context.fill();
			}
		}
	} else if (settings.picture === 'fjord') {
		// Bergen at night: the seven mountains, the lights of Bryggen, and the northern lights.
		context.fillStyle = '#0a1030';
		context.fillRect(0, 0, width, height);
		const aurora = context.createLinearGradient(0, 0, width, height * 0.4);
		aurora.addColorStop(0, 'rgba(60, 255, 150, 0)');
		aurora.addColorStop(0.5, 'rgba(60, 255, 150, 0.35)');
		aurora.addColorStop(1, 'rgba(120, 80, 255, 0)');
		context.fillStyle = aurora;
		context.beginPath();
		context.moveTo(0, height * 0.15);
		context.bezierCurveTo(width * 0.3, height * 0.02, width * 0.6, height * 0.35, width, height * 0.1);
		context.lineTo(width, height * 0.25);
		context.bezierCurveTo(width * 0.6, height * 0.45, width * 0.3, height * 0.12, 0, height * 0.3);
		context.fill();
		context.fillStyle = '#ffffff';
		for (let index = 0; index < 60; index++) {
			context.fillRect((index * 97) % width, (index * 53) % (height * 0.5), 1, 1);
		}

		context.fillStyle = '#05081a';
		context.beginPath();
		context.moveTo(0, height * 0.7);
		for (let x = 0; x <= width; x += 20) {
			context.lineTo(x, (height * 0.55) + (Math.sin(x / 70) * 30) + (Math.sin(x / 23) * 8));
		}

		context.lineTo(width, height);
		context.lineTo(0, height);
		context.fill();
		context.fillStyle = '#0c1a3a';
		context.fillRect(0, height * 0.82, width, height * 0.18);
		for (let x = 10; x < width; x += 14) {
			context.fillStyle = ['#ffcc55', '#ff8844', '#ffee99'][x % 3];
			context.fillRect(x, (height * 0.8) - ((x * 7) % 12), 3, 3);
			context.fillStyle = 'rgba(255, 204, 85, 0.3)';
			context.fillRect(x, (height * 0.83) + ((x * 3) % 10), 3, 8);
		}
	} else {
		// Think different: the rainbow apple and the words, on black.
		context.fillStyle = '#000000';
		context.fillRect(0, 0, width, height);
		const scale = Math.max(2, Math.floor(Math.min(width, height) / 70));
		drawSprite(context, sprites.apple, Math.floor((width / 2) - (8 * scale)), Math.floor((height / 2) - (12 * scale)), scale);
		context.fillStyle = '#ffffff';
		context.font = `bold ${Math.max(14, scale * 5)}px "Apple Garamond", Garamond, Georgia, serif`;
		context.textAlign = 'center';
		context.fillText('Think different.', width / 2, (height / 2) + (8 * scale));
	}
};

new ResizeObserver(() => {
	if (!desktop.hidden) {
		drawPicture();
	}
}).observe(desktop);

// The Speech control panel: the voices, the rate, Talking Alerts, and the phrase that comes first.
const speech = windowsByName.get('speech');

onOpen.speech = () => {
	part(speech, 'voice').value = settings.voice;
	part(speech, 'rate').value = String(settings.rate);
	part(speech, 'talking').checked = settings.talkingAlerts;
	part(speech, 'phrase').value = settings.phrase;
	if (!isExtensionActive('speech')) {
		part(speech, 'status').textContent = 'The Speech Manager extension is off, so my iMac cannot talk. Turn it on in the Extensions Manager.';
	} else if (!canSpeak) {
		part(speech, 'status').textContent = 'This browser cannot talk. My iMac could.';
	}
};

const sampleSentences = {
	Fred: 'Hello. My name is Fred. I am the voice of every Mac in 1999.',
	Victoria: 'Hello, I am Victoria. Isn’t it nice to have a computer that will talk to you?',
	Junior: 'My name is Junior. I like video games and unicorns.',
	Princess: 'When I grow up, I want to be a queen.',
	Ralph: 'My name is Ralph. I have a very deep voice.',
	Whisper: 'Pssst. Hey, you. Yeah, you. Who are you whispering to?',
	Zarvox: 'That looks like a peaceful planet. Take me to your leader.',
	Trinoids: 'We cannot communicate with these carbon units.',
	Bubbles: 'Pull the plug! I am drowning!',
	'Good News': 'Congratulations, you just won the sweepstakes and you don’t have to pay income tax again.',
	'Bad News': 'The light you see at the end of the tunnel is the headlamp of a fast approaching train.',
	Cellos: 'Doo da doo da dum dee dee doodly doo dum dum dum doo da doo da doo da doo da doo da doo da doo.',
};

part(speech, 'try').addEventListener('click', () => {
	ensureSpeakers();
	if (!speak(sampleSentences[settings.voice])) {
		announce(part(speech, 'status'), isExtensionActive('speech') ? 'This browser cannot talk. My iMac could.' : 'The Speech Manager extension is off. Turn it on in the Extensions Manager, and restart.');
	}
});

speech.addEventListener('change', event => {
	const name = event.target.dataset.macPart;
	if (name === 'voice') {
		settings.voice = event.target.value;
	} else if (name === 'rate') {
		settings.rate = Number(event.target.value);
	} else if (name === 'talking') {
		settings.talkingAlerts = event.target.checked;
		if (settings.talkingAlerts) {
			ensureSpeakers();
			announce(part(speech, 'status'), 'Talking Alerts are on. Now make something crash. Netscape is good at it.');
		}

		updateStrip();
	} else if (name === 'phrase') {
		settings.phrase = event.target.value;
	}

	persist();
});

// SimpleText reads the Read Me out loud.
const simpleText = windowsByName.get('simpletext');

part(simpleText, 'speak').addEventListener('click', () => {
	ensureSpeakers();
	if (!speak(part(simpleText, 'text').textContent, {isLong: true})) {
		toast(isExtensionActive('speech') ? 'This browser cannot talk. My iMac could.' : 'The Speech Manager extension is off.');
	}
});

part(simpleText, 'stop').addEventListener('click', stopSpeaking);
onQuit.simpletext = stopSpeaking;

// Copy, Paste, and Clear of the Edit menu, for the window in front. The clipboard has a picture of the Scrapbook, or text.
const textOfWindow = element => {
	const field = element.querySelector('textarea');
	if (field) {
		return field.value.slice(field.selectionStart, field.selectionEnd) || field.value;
	}

	return (part(element, 'text') ?? part(element, 'display'))?.textContent ?? '';
};

const editCommand = command => {
	const front = frontWindow();
	if (!front) {
		return;
	}

	const name = front.dataset.macWindow;
	if (command === 'copy') {
		session.clipboard = name === 'scrapbook' ? currentClip() : {kind: 'text', text: textOfWindow(front).slice(0, 300)};
		renderClipboard();
		announce(status, 'Copied to the clipboard.');
	} else if (command === 'paste') {
		pasteInto(front);
	} else if (command === 'clear') {
		if (name === 'puzzle') {
			setPuzzlePicture('numbers');
		} else if (name === 'scrapbook') {
			clearClip();
		} else if (name === 'keycaps') {
			part(front, 'display').textContent = '';
		} else {
			const field = front.querySelector('textarea');
			if (field) {
				field.setRangeText('', field.selectionStart, field.selectionEnd);
				field.dispatchEvent(new Event('input'));
			}
		}
	}
};

const pasteInto = front => {
	const clip = session.clipboard;
	if (!clip) {
		return;
	}

	const name = front.dataset.macWindow;
	if (name === 'puzzle') {
		if (clip.kind === 'picture') {
			setPuzzlePicture(clip.name);
		} else {
			announce(windowPart('puzzle', 'status'), 'The Puzzle only takes pictures. Copy a picture in the Scrapbook first.');
		}
	} else if (name === 'scrapbook') {
		addClip(clip);
	} else {
		const field = front.querySelector('textarea');
		if (field) {
			field.setRangeText(clip.kind === 'text' ? clip.text : `[a picture of ${clip.title}]`, field.selectionStart, field.selectionEnd, 'end');
			field.dispatchEvent(new Event('input'));
			field.focus();
		}
	}
};

const renderClipboard = () => {
	const clipboard = windowsByName.get('clipboard');
	const clip = session.clipboard;
	const canvas = part(clipboard, 'clip');
	part(clipboard, 'kind').textContent = clip ? `Clipboard contents: ${clip.kind === 'picture' ? 'picture' : 'text'}` : 'Clipboard contents: none';
	canvas.hidden = clip?.kind !== 'picture';
	part(clipboard, 'text').hidden = clip?.kind !== 'text';
	if (clip?.kind === 'picture') {
		drawClip(canvas, clip.name);
	} else {
		part(clipboard, 'text').textContent = clip?.text ?? '';
	}
};

onOpen.clipboard = renderClipboard;

// The Puzzle of Dad’s old System 7.5: 15 pieces of a picture, slid into the empty place. Clear shows the numbers, and Paste makes a puzzle of any picture of the Scrapbook.
const puzzleCanvas = windowPart('puzzle', 'board');
const puzzleStatus = windowPart('puzzle', 'status');
const puzzle = {tiles: [...Array(16).keys()], picture: 'apple', moves: 0, isSolved: true};

const drawPuzzlePicture = (context, size) => {
	if (puzzle.picture === 'apple') {
		context.fillStyle = '#ffffff';
		context.fillRect(0, 0, size, size);
		const scale = size / 20;
		drawSprite(context, sprites.apple, 2 * scale, 2 * scale, scale);
	} else if (puzzle.picture !== 'numbers') {
		const canvas = document.createElement('canvas');
		canvas.width = size;
		canvas.height = size;
		drawClip(canvas, puzzle.picture);
		context.drawImage(canvas, 0, 0);
	}
};

const drawPuzzle = () => {
	const context = puzzleCanvas.getContext('2d');
	const size = puzzleCanvas.width;
	const tile = size / 4;
	const picture = document.createElement('canvas');
	picture.width = size;
	picture.height = size;
	drawPuzzlePicture(picture.getContext('2d'), size);
	context.fillStyle = '#888888';
	context.fillRect(0, 0, size, size);
	for (const [place, piece] of puzzle.tiles.entries()) {
		if (piece === 15) {
			continue;
		}

		const x = (place % 4) * tile;
		const y = Math.floor(place / 4) * tile;
		if (puzzle.picture === 'numbers') {
			context.fillStyle = '#ffffff';
			context.fillRect(x, y, tile, tile);
			context.fillStyle = '#000000';
			context.font = `bold ${tile * 0.45}px Charcoal, Chicago, sans-serif`;
			context.textAlign = 'center';
			context.textBaseline = 'middle';
			context.fillText(String(piece + 1), x + (tile / 2), y + (tile / 2));
		} else {
			context.drawImage(picture, (piece % 4) * tile, Math.floor(piece / 4) * tile, tile, tile, x, y, tile, tile);
		}

		context.strokeStyle = '#000000';
		context.strokeRect(x + 0.5, y + 0.5, tile - 1, tile - 1);
	}
};

const slide = place => {
	const empty = puzzle.tiles.indexOf(15);
	const isNeighbor = (Math.abs(place - empty) === 4) || (Math.abs(place - empty) === 1 && Math.floor(place / 4) === Math.floor(empty / 4));
	if (!isNeighbor || place < 0 || place > 15) {
		return false;
	}

	[puzzle.tiles[place], puzzle.tiles[empty]] = [puzzle.tiles[empty], puzzle.tiles[place]];
	return true;
};

const shufflePuzzle = () => {
	let previous = -1;
	for (let move = 0; move < 240; move++) {
		const empty = puzzle.tiles.indexOf(15);
		const options = [empty - 4, empty + 4, empty % 4 > 0 ? empty - 1 : -1, empty % 4 < 3 ? empty + 1 : -1].filter(place => place >= 0 && place < 16 && place !== previous);
		previous = empty;
		slide(randomItem(options));
	}

	puzzle.moves = 0;
	puzzle.isSolved = false;
	drawPuzzle();
	announce(puzzleStatus, 'Shuffled. Slide the pieces back!');
};

const movePuzzle = place => {
	if (puzzle.isSolved || !slide(place)) {
		return;
	}

	puzzle.moves++;
	drawPuzzle();
	if (puzzle.tiles.every((piece, index) => piece === index)) {
		puzzle.isSolved = true;
		const isBest = settings.puzzleBest === 0 || puzzle.moves < settings.puzzleBest;
		if (isBest) {
			settings.puzzleBest = puzzle.moves;
			persist();
		}

		cheer();
		announce(puzzleStatus, `Solved in ${puzzle.moves} moves!${isBest ? ' A new record!' : ` My record is ${settings.puzzleBest}.`}`);
	} else {
		puzzleStatus.textContent = `Moves: ${puzzle.moves}`;
	}
};

const setPuzzlePicture = picture => {
	puzzle.picture = picture;
	drawPuzzle();
	announce(puzzleStatus, picture === 'numbers' ? 'Numbers, like the very first Puzzle of 1984.' : (picture === 'apple' ? 'The Apple logo.' : 'Your own puzzle! Press Shuffle.'));
};

puzzleCanvas.addEventListener('click', event => {
	const rectangle = puzzleCanvas.getBoundingClientRect();
	const column = Math.floor((event.clientX - rectangle.left) / rectangle.width * 4);
	const row = Math.floor((event.clientY - rectangle.top) / rectangle.height * 4);
	movePuzzle((clamp(row, 0, 3) * 4) + clamp(column, 0, 3));
});

puzzleCanvas.addEventListener('keydown', event => {
	const empty = puzzle.tiles.indexOf(15);
	const places = {ArrowUp: empty + 4, ArrowDown: empty - 4, ArrowLeft: empty % 4 < 3 ? empty + 1 : -1, ArrowRight: empty % 4 > 0 ? empty - 1 : -1};
	if (event.key in places) {
		event.preventDefault();
		movePuzzle(places[event.key]);
	}
});

windowPart('puzzle', 'shuffle').addEventListener('click', shufflePuzzle);
windowPart('puzzle', 'numbers').addEventListener('click', () => {
	setPuzzlePicture(puzzle.picture === 'numbers' ? 'apple' : 'numbers');
});
windowPart('puzzle', 'paste').addEventListener('click', () => {
	if (session.clipboard?.kind === 'picture') {
		setPuzzlePicture(session.clipboard.name);
	} else {
		announce(puzzleStatus, 'The clipboard has no picture. Copy one in the Scrapbook first.');
	}
});

onOpen.puzzle = () => {
	drawPuzzle();
	if (puzzle.isSolved) {
		shufflePuzzle();
	}
};

// The Note Pad: eight pages that keep what is written, with the folded corner to turn them.
const notePad = windowsByName.get('notepad');
const noteText = part(notePad, 'text');

const showNotePage = () => {
	noteText.value = settings.notes[settings.notePage] ?? '';
	part(notePad, 'page').textContent = `Page ${settings.notePage + 1} of 8`;
};

onOpen.notepad = showNotePage;

noteText.addEventListener('input', () => {
	settings.notes[settings.notePage] = noteText.value;
	persist();
});

part(notePad, 'previous').addEventListener('click', () => {
	settings.notePage = (settings.notePage + 7) % 8;
	showNotePage();
	persist();
});

part(notePad, 'next').addEventListener('click', () => {
	settings.notePage = (settings.notePage + 1) % 8;
	showNotePage();
	persist();
});

// Tabs Not Spaces INIT turns each space into a tab in the Note Pad and Stickies.
desktop.addEventListener('keydown', event => {
	if (event.key === ' ' && event.target.matches('textarea') && isExtensionActive('tabs') && !event.target.closest('[data-mac-window="sherlock"]')) {
		event.preventDefault();
		event.target.setRangeText('\t', event.target.selectionStart, event.target.selectionEnd, 'end');
		event.target.dispatchEvent(new Event('input'));
	}
});

// Stickies: notes in six colors that stay on the desktop, keep what is written, and come back after a restart.
const stickyColors = ['#fff68f', '#aee7ff', '#c8f7a8', '#ffc4e1', '#e0c8ff', '#e8e8e8'];
let stickyCount = 0;

const makeSticky = note => {
	stickyCount++;
	const element = stickyTemplate.content.firstElementChild.cloneNode(true);
	const name = `sticky-${stickyCount}`;
	element.dataset.macWindow = name;
	element.setAttribute('aria-labelledby', `geocities-mac-title-${name}`);
	element.querySelector('h3').id = `geocities-mac-title-${name}`;
	element.querySelector('h3').textContent = 'Note';
	element.style.background = stickyColors[note.color % stickyColors.length];
	const text = part(element, 'text');
	text.value = note.text;
	desktop.insertBefore(element, strip);
	setUpWindow(element);
	element.dataset.macPlaced = '';
	text.addEventListener('input', () => {
		note.text = text.value;
		persist();
	});
	part(element, 'color').addEventListener('click', () => {
		note.color = (note.color + 1) % stickyColors.length;
		element.style.background = stickyColors[note.color];
		persist();
	});
	part(element, 'new').addEventListener('click', () => {
		addSticky();
	});
	element.addEventListener('mac-moved', () => {
		note.x = element.offsetLeft;
		note.y = element.offsetTop;
		persist();
	});

	// The close box of a note throws the note away, as Stickies asks nothing.
	element.querySelector('[data-mac-close]').addEventListener('click', () => {
		settings.stickies = settings.stickies.filter(other => other !== note);
		persist();
		windowOrder.splice(windowOrder.indexOf(element), 1);
		setTimeout(() => {
			element.remove();
		});
	});

	element.hidden = true;
	return {element, note};
};

const addSticky = () => {
	const note = {text: '', color: settings.stickies.length % stickyColors.length, x: 40 + ((settings.stickies.length % 5) * 16), y: 60 + ((settings.stickies.length % 5) * 16)};
	settings.stickies.push(note);
	persist();
	const {element} = makeSticky(note);
	showWindow(element);
	moveWindow(element, note.x, note.y);
	part(element, 'text').focus();
};

onLaunch.stickies = opener => {
	for (const element of [...desktop.querySelectorAll('[data-mac-window^="sticky-"]')]) {
		windowOrder.splice(windowOrder.indexOf(element), 1);
		element.remove();
	}

	if (settings.stickies.length === 0) {
		openWindow('stickies', opener);
		return;
	}

	for (const note of settings.stickies) {
		const {element} = makeSticky(note);
		showWindow(element);
		moveWindow(element, note.x, note.y);
	}
};

windowPart('stickies', 'new').addEventListener('click', addSticky);

// The Scrapbook: clippings of pictures and text, to scroll through, copy, and paste. My clippings cannot be cleared, the ones the visitor pastes can.
const builtInClips = [
	{kind: 'picture', name: 'happyMac', title: 'the Happy Mac', size: '2K'},
	{kind: 'picture', name: 'waffle', title: 'a waffle with brown cheese', size: '14K'},
	{kind: 'picture', name: 'unicorn', title: 'my unicorn', size: '6K'},
	{kind: 'picture', name: 'dogcow', title: 'Clarus the dogcow', size: '1K'},
	{kind: 'text', text: 'hello (again)', size: '1K'},
	{kind: 'picture', name: 'flag', title: 'the flag of Norway', size: '3K'},
	{kind: 'picture', name: 'think', title: 'Think different', size: '9K'},
	{kind: 'text', text: 'Things to do in the year 2000:\n1. Survive Y2K\n2. Get a faster modem\n3. Finish Bugdom Jr.', size: '1K'},
	{kind: 'picture', name: 'bomb', title: 'the bomb', size: '2K'},
];

let clipIndex = 0;
const scrapbook = windowsByName.get('scrapbook');
const allClips = () => [...builtInClips, ...settings.clips];
const currentClip = () => allClips()[clipIndex];

// Draws a picture of the Scrapbook on a canvas, at any size.
const drawClip = (canvas, name) => {
	const context = canvas.getContext('2d');
	const width = canvas.width;
	const height = canvas.height;
	context.fillStyle = '#ffffff';
	context.fillRect(0, 0, width, height);
	if (name === 'waffle') {
		const radius = Math.min(width, height) * 0.42;
		context.fillStyle = '#e6b45c';
		context.beginPath();
		context.arc(width / 2, height / 2, radius, 0, Math.PI * 2);
		context.fill();
		context.strokeStyle = '#a8701e';
		context.lineWidth = Math.max(1, radius / 18);
		for (let line = -radius; line <= radius; line += radius / 4) {
			context.beginPath();
			context.moveTo((width / 2) + line, (height / 2) - radius);
			context.lineTo((width / 2) + line, (height / 2) + radius);
			context.moveTo((width / 2) - radius, (height / 2) + line);
			context.lineTo((width / 2) + radius, (height / 2) + line);
			context.stroke();
		}

		context.fillStyle = '#b5651d';
		context.fillRect((width / 2) - (radius * 0.5), (height / 2) - (radius * 0.15), radius, radius * 0.3);
	} else if (name === 'flag') {
		const flagWidth = width * 0.8;
		const flagHeight = flagWidth * (16 / 22);
		const x = (width - flagWidth) / 2;
		const y = (height - Math.min(flagHeight, height * 0.9)) / 2;
		const unit = Math.min(flagWidth / 22, (height * 0.9) / 16);
		context.fillStyle = '#ba0c2f';
		context.fillRect(x, y, unit * 22, unit * 16);
		context.fillStyle = '#ffffff';
		context.fillRect(x + (unit * 6), y, unit * 4, unit * 16);
		context.fillRect(x, y + (unit * 6), unit * 22, unit * 4);
		context.fillStyle = '#00205b';
		context.fillRect(x + (unit * 7), y, unit * 2, unit * 16);
		context.fillRect(x, y + (unit * 7), unit * 22, unit * 2);
	} else if (name === 'think') {
		context.fillStyle = '#000000';
		context.fillRect(0, 0, width, height);
		const scale = Math.max(1, Math.floor(height / 26));
		drawSprite(context, sprites.apple, (width / 2) - (8 * scale), height * 0.08, scale);
		context.fillStyle = '#ffffff';
		context.font = `bold ${Math.max(10, height / 9)}px Garamond, Georgia, serif`;
		context.textAlign = 'center';
		context.textBaseline = 'alphabetic';
		context.fillText('Think different.', width / 2, height * 0.9);
	} else if (sprites[name]) {
		drawSpriteOnCanvas(canvas, name, '#ffffff');
	}
};

const showClip = () => {
	const clips = allClips();
	clipIndex = clamp(clipIndex, 0, clips.length - 1);
	const clip = clips[clipIndex];
	const canvas = part(scrapbook, 'clip');
	const text = part(scrapbook, 'text');
	canvas.hidden = clip.kind !== 'picture';
	text.hidden = clip.kind !== 'text';
	if (clip.kind === 'picture') {
		drawClip(canvas, clip.name);
		canvas.setAttribute('aria-label', `A picture of ${clip.title}`);
	} else {
		text.textContent = clip.text;
	}

	const scroll = part(scrapbook, 'scroll');
	scroll.max = String(clips.length - 1);
	scroll.value = String(clipIndex);
	part(scrapbook, 'info').textContent = `${clipIndex + 1} of ${clips.length} ★ Kind: ${clip.kind === 'picture' ? 'PICT' : 'TEXT'} ★ Size: ${clip.size ?? '1K'}`;
};

onOpen.scrapbook = showClip;

part(scrapbook, 'scroll').addEventListener('input', event => {
	clipIndex = Number(event.target.value);
	showClip();
});

const addClip = clip => {
	settings.clips.push({...clip, size: clip.kind === 'text' ? `${Math.max(1, Math.ceil(clip.text.length / 1024))}K` : clip.size});
	settings.clips = settings.clips.slice(-20);
	persist();
	clipIndex = allClips().length - 1;
	showClip();
	announce(part(scrapbook, 'info'), `Pasted. ${part(scrapbook, 'info').textContent}`);
};

const clearClip = () => {
	if (clipIndex < builtInClips.length) {
		announce(part(scrapbook, 'info'), 'That clipping is mine, and it stays. You can clear the ones you pasted.');
		return;
	}

	settings.clips.splice(clipIndex - builtInClips.length, 1);
	persist();
	showClip();
};

part(scrapbook, 'copy').addEventListener('click', () => {
	session.clipboard = currentClip();
	renderClipboard();
	announce(part(scrapbook, 'info'), session.clipboard.kind === 'picture' ? `Copied ${session.clipboard.title}. Paste it in the Puzzle!` : 'Copied the text. Paste it in the Note Pad or Stickies.');
});

part(scrapbook, 'paste').addEventListener('click', () => {
	if (session.clipboard) {
		addClip(session.clipboard);
	} else {
		announce(part(scrapbook, 'info'), 'The clipboard is empty. Copy some text in the Note Pad first.');
	}
});

part(scrapbook, 'clear').addEventListener('click', clearClip);

// Key Caps: the keyboard, with the letters that Option and Shift make, and what was typed.
const keyCaps = windowsByName.get('keycaps');
const keyRows = ['`1234567890-=', 'qwertyuiop[]', 'asdfghjkl;\'', 'zxcvbnm,./'];
const shiftCharacters = '~!@#$%^&*()_+QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?';
const optionCharacters = '`¡™£¢∞§¶•ªº–≠œ∑´®†¥¨ˆøπ“‘åß∂ƒ©˙∆˚¬…æΩ≈ç√∫˜µ≤≥÷';
// Shift, Option, and K is the Apple logo, a character that only the fonts of Apple have.
const shiftOptionCharacters = '`⁄€‹›ﬁﬂ‡°·‚—±Œ„´‰ˇÁ¨ˆØ∏”’ÅÍÎÏ˝ÓÔ\uF8FFÒÚÆ¸˛Ç◊ı˜Â¯˘¿';
const plainCharacters = keyRows.join('');
const keyCapsState = {shift: false, option: false};
const keyButtonsByCharacter = new Map();

const characterFor = index => {
	if (keyCapsState.option) {
		return [...(keyCapsState.shift ? shiftOptionCharacters : optionCharacters)][index];
	}

	return keyCapsState.shift ? shiftCharacters[index] : plainCharacters[index];
};

const renderKeys = () => {
	for (const [index, button] of [...keyButtonsByCharacter.values()].entries()) {
		button.textContent = characterFor(index);
		button.setAttribute('aria-label', `Type ${characterFor(index)}`);
	}
};

const typeKey = character => {
	const display = part(keyCaps, 'display');
	display.textContent = `${display.textContent}${character}`.slice(-48);
	if (character === '\uF8FF') {
		toast('That is the Apple logo! If you see a box, you are not on a Mac.');
	}
};

const keyboard = part(keyCaps, 'keyboard');
let keyIndex = 0;
for (const row of keyRows) {
	const rowElement = document.createElement('div');
	for (const character of row) {
		const button = keyTemplate.content.firstElementChild.cloneNode(true);
		const index = keyIndex;
		button.addEventListener('click', () => {
			typeKey(characterFor(index));
		});
		keyButtonsByCharacter.set(character, button);
		rowElement.append(button);
		keyIndex++;
	}

	keyboard.append(rowElement);
}

for (const modifier of ['shift', 'option']) {
	part(keyCaps, modifier).addEventListener('click', event => {
		keyCapsState[modifier] = !keyCapsState[modifier];
		setPressed(event.currentTarget, keyCapsState[modifier]);
		renderKeys();
	});
}

part(keyCaps, 'clear').addEventListener('click', () => {
	part(keyCaps, 'display').textContent = '';
});

keyCaps.addEventListener('keydown', event => {
	if (event.target.closest('button[data-mac-part], [data-mac-title-bar]') || event.metaKey || event.ctrlKey) {
		return;
	}

	const code = event.code.replace(/^Key/, '').replace(/^Digit/, '').toLowerCase();
	const names = {backquote: '`', minus: '-', equal: '=', bracketleft: '[', bracketright: ']', semicolon: ';', quote: '\'', comma: ',', period: '.', slash: '/'};
	const button = keyButtonsByCharacter.get(names[code] ?? code);
	if (event.key === 'Shift' || event.key === 'Alt') {
		keyCapsState[event.key === 'Shift' ? 'shift' : 'option'] = true;
		setPressed(part(keyCaps, event.key === 'Shift' ? 'shift' : 'option'), true);
		renderKeys();
		return;
	}

	if (button) {
		event.preventDefault();
		keyCapsState.shift = event.shiftKey;
		keyCapsState.option = event.altKey;
		const index = [...keyButtonsByCharacter.values()].indexOf(button);
		typeKey(characterFor(index));
		button.dataset.state = 'on';
		setTimeout(() => {
			button.dataset.state = '';
		}, 150);
	}
});

keyCaps.addEventListener('keyup', event => {
	if (event.key === 'Shift' || event.key === 'Alt') {
		const modifier = event.key === 'Shift' ? 'shift' : 'option';
		keyCapsState[modifier] = false;
		setPressed(part(keyCaps, modifier), false);
		renderKeys();
	}
});

onOpen.keycaps = () => {
	renderKeys();
};

// The Chooser: the StyleWriter on the printer port, which is out of ink, and the LaserWriters and file servers of AppleTalk, which are far away.
const chooser = windowsByName.get('chooser');
let chooserDriver = settings.printer === 'laserwriter' ? 'laserwriter' : (settings.printer ? 'stylewriter' : '');

const updateChooser = () => {
	for (const driver of ['stylewriter', 'laserwriter', 'appleshare']) {
		setPressed(part(chooser, `driver-${driver}`), driver === chooserDriver);
	}

	for (const radio of chooser.querySelectorAll('[data-mac-part="appletalk"]')) {
		radio.checked = (radio.value === 'on') === settings.appleTalk;
	}

	const list = part(chooser, 'printers');
	const prompt = part(chooser, 'prompt');
	list.replaceChildren();
	const found = {
		stylewriter: [['stylewriter', 'StyleWriter II (printer port)']],
		laserwriter: settings.appleTalk ? [['laserwriter', 'Dad’s LaserWriter (at his office, 40 km away)']] : [],
		appleshare: [],
	}[chooserDriver] ?? [];

	if (!chooserDriver) {
		prompt.textContent = 'Select a driver at the left.';
	} else if (found.length === 0) {
		prompt.textContent = settings.appleTalk ? 'No file servers. There is no network. It is just me.' : 'AppleTalk is inactive. Make it active below to look for printers on the network.';
	} else {
		prompt.textContent = chooserDriver === 'stylewriter' ? 'Select a printer port:' : 'Select a LaserWriter:';
	}

	for (const [id, title] of found) {
		const item = document.createElement('li');
		const button = part(chooser, 'driver-stylewriter').cloneNode(false);
		button.removeAttribute('data-mac-part');
		button.textContent = title;
		setPressed(button, settings.printer === id);
		button.addEventListener('click', () => {
			settings.printer = id;
			persist();
			updateChooser();
			announce(part(chooser, 'status'), id === 'stylewriter' ? 'Selected the StyleWriter II. Ink: empty since March.' : 'Selected Dad’s LaserWriter. It is fast. And 40 km away.');
		});
		item.append(button);
		list.append(item);
	}
};

for (const driver of ['stylewriter', 'laserwriter', 'appleshare']) {
	part(chooser, `driver-${driver}`).addEventListener('click', () => {
		chooserDriver = driver;
		updateChooser();
	});
}

chooser.addEventListener('change', async event => {
	if (event.target.dataset.macPart !== 'appletalk') {
		return;
	}

	settings.appleTalk = event.target.value === 'on';
	persist();
	updateChooser();
	updateStrip();
	if (settings.appleTalk) {
		await showAlert({icon: 'finder', text: 'AppleTalk will be made active. Make sure your computer is connected to a network.', detail: 'It is connected to the phone line. That is almost a network.'});
	}
});

onOpen.chooser = updateChooser;

// Page Setup with the options of the LaserWriter, and Clarus the dogcow, who shows how the page turns. Moof!
const pageSetup = windowsByName.get('pagesetup');
const pageOptions = () => settings.pageSetup;

const drawDogcow = () => {
	const canvas = part(pageSetup, 'dogcow');
	const context = canvas.getContext('2d');
	const options = pageOptions();
	context.save();
	context.fillStyle = '#ffffff';
	context.fillRect(0, 0, canvas.width, canvas.height);
	context.translate(canvas.width / 2, canvas.height / 2);
	const shrink = options.precision ? 0.96 : 1;
	context.scale((options['flip-h'] ? -1 : 1) * shrink, (options['flip-v'] ? -1 : 1) * shrink);
	const scale = 6;
	drawSprite(context, sprites.dogcow, -8 * scale, -6 * scale, scale);
	context.restore();
	if (options.invert) {
		const image = context.getImageData(0, 0, canvas.width, canvas.height);
		for (let index = 0; index < image.data.length; index += 4) {
			image.data[index] = 255 - image.data[index];
			image.data[index + 1] = 255 - image.data[index + 1];
			image.data[index + 2] = 255 - image.data[index + 2];
		}

		context.putImageData(image, 0, 0);
	}
};

onOpen.pagesetup = () => {
	for (const option of ['flip-h', 'flip-v', 'invert', 'precision']) {
		part(pageSetup, option).checked = Boolean(pageOptions()[option]);
	}

	drawDogcow();
};

pageSetup.addEventListener('change', event => {
	settings.pageSetup[event.target.dataset.macPart] = event.target.checked;
	persist();
	drawDogcow();
	announce(part(pageSetup, 'status'), {
		'flip-h': 'Like any talented dog, she can do flips.',
		'flip-v': 'Upside down! She does not mind.',
		invert: 'A black dogcow. She looks cool.',
		precision: 'Like any talented cow, she can do Precision Bitmap Alignment.',
	}[event.target.dataset.macPart]);
});

part(pageSetup, 'moof').addEventListener('click', () => {
	ensureSpeakers();
	if (!speak('Moof!', {voice: 'Junior'})) {
		tone(330, 0, 0.25, {type: 'sawtooth', endFrequency: 180, gain: 0.25});
		tone(520, 0.28, 0.2, {type: 'square', endFrequency: 440, gain: 0.15});
	}

	announce(part(pageSetup, 'status'), 'Moof! (That is what a dogcow says. Half moo, half woof.)');
});

part(pageSetup, 'ok').addEventListener('click', () => {
	closeWindow(pageSetup);
});

// Print: the window in front goes to the printer of the Chooser. The StyleWriter prints it on the desk, faded and with streaks, as it is out of ink, and with the options of Page Setup.
const printLines = () => {
	const front = frontWindow();
	const name = front?.dataset.macWindow ?? '';
	if (name === 'notepad' || name.startsWith('sticky')) {
		return {title: name === 'notepad' ? 'Note Pad' : 'Stickies', lines: front.querySelector('textarea').value.split('\n')};
	}

	if (name === 'simpletext') {
		return {title: 'Read Me!', lines: [...part(front, 'text').children].map(paragraph => paragraph.textContent)};
	}

	if (front) {
		return {title: front.querySelector('h3').textContent, lines: front.querySelector('[data-mac-title-bar] + div').innerText.split('\n').slice(0, 30)};
	}

	return {title: 'Macintosh HD', lines: items.filter(item => item.place === 'desktop').map(item => item.name)};
};

let isPrinting = false;

const printFront = async () => {
	if (isPrinting) {
		return;
	}

	if (!settings.printer) {
		await showAlert({icon: 'stop', text: 'Printing is not possible because no printer is selected in the Chooser.', detail: 'Choose Chooser in the Apple menu.'});
		return;
	}

	if (settings.printer === 'laserwriter') {
		if (!settings.appleTalk) {
			await showAlert({icon: 'stop', text: 'The printer “Dad’s LaserWriter” could not be found.', detail: 'Make sure AppleTalk is active, and that the printer is turned on. (It is at Dad’s office.)'});
			return;
		}

		toast('Printing to Dad’s LaserWriter… The page is at his office now. He will bring it home on Friday.');
		return;
	}

	isPrinting = true;
	try {
		await printPage();
	} finally {
		isPrinting = false;
	}
};

// Prints the page line by line, and stops when the iMac shuts down, sleeps, or restarts.
const printPage = async () => {
	const run = bootRun;
	const {title, lines} = printLines();
	const context = printout.getContext('2d');
	const width = printout.width;
	const height = printout.height;
	const options = pageOptions();
	printer.hidden = false;
	context.fillStyle = '#ffffff';
	context.fillRect(0, 0, width, height);
	announce(status, `The StyleWriter II prints “${title}”: zzzt, zzzt, zzzt…`);
	const draw = row => {
		context.save();
		context.translate(options['flip-h'] ? width : 0, options['flip-v'] ? height : 0);
		context.scale(options['flip-h'] ? -1 : 1, options['flip-v'] ? -1 : 1);
		context.font = row === 0 ? 'bold 13px Geneva, Arial, sans-serif' : '10px Geneva, Arial, sans-serif';
		context.textBaseline = 'top';
		const text = row === 0 ? title : (lines[row - 1] ?? '');
		// Out of ink: the lines fade, and every few lines a streak is missing.
		const ink = Math.max(0.05, 0.75 - (row * 0.04));
		context.fillStyle = `rgba(20, 20, 60, ${ink})`;
		if (row % 4 !== 3) {
			context.fillText(text.slice(0, 44), 12, 12 + (row * 14));
		}

		context.restore();
	};

	const rowCount = Math.min(lines.length + 1, 19);
	for (let row = 0; row < rowCount; row++) {
		draw(row);
		if (!reducedMotion.matches) {
			tone(1800 + (row % 3 * 120), 0, 0.05, {type: 'square', gain: 0.03});
			await wait(160);
			if (run !== bootRun || session.power !== 'on') {
				return;
			}
		}
	}

	if (options.invert) {
		const image = context.getImageData(0, 0, width, height);
		for (let index = 0; index < image.data.length; index += 4) {
			image.data[index] = 255 - image.data[index];
			image.data[index + 1] = 255 - image.data[index + 1];
			image.data[index + 2] = 255 - image.data[index + 2];
		}

		context.putImageData(image, 0, 0);
	}

	await showAlert({icon: 'caution', text: 'The StyleWriter II is out of ink.', detail: 'The page came out anyway, sort of. It is on the desk next to the iMac. Mom says ink costs more than gold.'});
};

// Sherlock: Search Internet, through the search sites, with funny results ranked by relevance, and Find by Content, which searches what the visitor wrote, once the disk is indexed.
const sherlock = windowsByName.get('sherlock');
let sherlockMode = 'internet';
let isIndexed = false;
let isSearching = false;

const resultTemplates = [
	'The Official {q} Home Page (under construction)',
	'{q} FAQ, last updated in 1997',
	'{q} Webring: Previous ★ Random ★ Next',
	'Is {q} Y2K compliant? Find out NOW!',
	'The {q} Fan Club (1 member)',
	'Download {q} for the Mac (Windows only)',
	'Sindre’s {q} Shrine, with MIDI',
	'FREE {q}!!! Click here!!!',
	'{q}.com: this domain is for sale',
	'How to make {q} with HyperCard',
	'{q} in 3D (needs QuickDraw 3D and 64 MB)',
	'Top 10 {q} links of the week',
];

const siteTemplates = {
	'Amazon.com': ['Buy {q} at Amazon.com: 3 customer reviews', '{q} for Dummies, 2nd edition'],
	'Apple Tech Info Library': ['Tech Info Library: {q} and Mac OS 8.6', 'Tech Info Library: {q} causes a type 11 error'],
};

const snippets = [
	'This page has moved to a new address on GeoCities. This page has moved to a new address on GeoCities.',
	'You are visitor number 000014. Sign my guestbook!',
	'Best viewed with Netscape Navigator 4 at 800 × 600. This page uses frames.',
	'Error 404: the page cannot be found. But here is a dancing hamster.',
	'Last updated: soon. Under construction since 1996.',
	'This site is a member of 7 webrings and 0 of them work.',
];

const specialResults = {
	sindre: ['Sindre’s Home Page (you are here!)', 100],
	windows: ['Windows 98: like Mac OS 8.6, but from 1989', 99],
	bugdom: ['Bugdom: the cheat to get all the ladybugs (fake)', 97],
	waffle: ['Waffles with brown cheese: the official recipe of Norway', 100],
	unicorn: ['Unicorns are real, says a page with 40 GIFs', 98],
};

const sherlockResults = part(sherlock, 'results');
const sherlockSummary = part(sherlock, 'summary');
const sherlockFill = part(sherlock, 'fill');

const setSherlockMode = mode => {
	sherlockMode = mode;
	setPressed(part(sherlock, 'tab-internet'), mode === 'internet');
	setPressed(part(sherlock, 'tab-content'), mode === 'content');
	part(sherlock, 'sites').hidden = mode !== 'internet';
	part(sherlock, 'indexing').hidden = mode !== 'content';
	sherlockResults.replaceChildren();
	sherlockFill.style.width = '0%';
	sherlockSummary.textContent = mode === 'internet' ? 'Type words, pick the search sites, and press Search.' : (isIndexed ? 'Macintosh HD is indexed. Search the words in my files, and in your notes.' : 'Macintosh HD is not indexed yet. Press Index Volumes first.');
};

part(sherlock, 'tab-internet').addEventListener('click', () => {
	setSherlockMode('internet');
});

part(sherlock, 'tab-content').addEventListener('click', () => {
	setSherlockMode('content');
});

const addResult = ({title, relevance, onChoose}) => {
	const item = resultTemplate.content.firstElementChild.cloneNode(true);
	const button = item.querySelector('button');
	const [titleElement, bar] = button.children;
	titleElement.textContent = title;
	bar.style.background = `linear-gradient(to right, #4040c0 ${relevance}%, #eeeeee ${relevance}%)`;
	button.setAttribute('aria-label', `${title}, ${relevance}% relevant`);
	button.addEventListener('click', () => {
		for (const other of sherlockResults.querySelectorAll('button')) {
			other.dataset.state = other === button ? 'on' : '';
		}

		onChoose();
	});
	sherlockResults.append(item);
};

const runMeter = async (seconds, onTick) => {
	const steps = 20;
	for (let index = 1; index <= steps; index++) {
		sherlockFill.style.width = `${index / steps * 100}%`;
		onTick?.(index / steps);
		await wait(seconds * 1000 / steps);
	}
};

part(sherlock, 'form').addEventListener('submit', async event => {
	event.preventDefault();
	if (isSearching) {
		return;
	}

	const query = part(sherlock, 'query').value.trim();
	if (!query) {
		announce(sherlockSummary, 'Type some words first. Even Sherlock needs a clue.');
		return;
	}

	sherlockResults.replaceChildren();
	isSearching = true;
	try {
		if (sherlockMode === 'internet') {
			await searchInternet(query);
		} else {
			await searchContent(query);
		}
	} finally {
		isSearching = false;
	}
});

const searchInternet = async query => {
	if (!isExtensionActive('opentransport')) {
		await showAlert({icon: 'stop', text: 'Sherlock could not connect to the Internet.', detail: 'Open Transport is turned off in the Extensions Manager. Turn it on, and restart.'});
		return;
	}

	const sites = [...sherlock.querySelectorAll('[data-mac-part="site"]:checked')].map(checkbox => checkbox.value);
	if (sites.length === 0) {
		announce(sherlockSummary, 'Pick at least one search site.');
		return;
	}

	await runMeter(2.4, progress => {
		sherlockSummary.textContent = progress < 0.3 ? 'Dialing… beeeee-dooo-shhhhhh' : (progress < 0.6 ? 'Connected at 28,800 bps. Asking the search sites…' : `Searching ${sites.join(', ')}…`);
	});

	const words = query.toLowerCase();
	const results = [];
	for (const [word, [title, relevance]] of Object.entries(specialResults)) {
		if (words.includes(word)) {
			results.push({title, relevance, site: 'Excite'});
		}
	}

	for (const site of sites) {
		const templates = siteTemplates[site] ?? resultTemplates;
		for (let index = 0; index < randomInteger(1, 2); index++) {
			results.push({title: randomItem(templates).replaceAll('{q}', query), relevance: randomInteger(31, 96), site});
		}
	}

	results.sort((first, second) => second.relevance - first.relevance);
	for (const result of results.slice(0, 12)) {
		addResult({...result, onChoose() {
			announce(sherlockSummary, `${result.site} ★ ${result.relevance}% relevant ★ ${randomItem(snippets)}`);
		}});
	}

	announce(sherlockSummary, `${results.length} items found for “${query}”. Click one to see it.`);
};

// The files of the disk that Find by Content searches: some of mine, and what the visitor wrote in the Note Pad and Stickies.
const searchableFiles = () => [
	{title: 'Homework (not done)', text: 'The Vikings came from Norway. They had no computers. That is all I have so far.'},
	{title: 'Letter to Mormor', text: 'Dear Mormor, thank you for the waffle iron. I use it every day. My iMac is blue. Love, Sindre'},
	{title: 'Read Me!', text: part(simpleText, 'text').textContent},
	{title: 'Bugdom Jr. Cheats.txt', text: 'There are no cheats. Roll into the cages. Ladybugs. Fire ants are bad.'},
	...settings.notes.map((text, index) => ({title: `Note Pad, page ${index + 1}`, text, open() {
		settings.notePage = index;
		launch('notepad').then(showNotePage);
	}})),
	...settings.stickies.map((note, index) => ({title: `Stickies note ${index + 1}`, text: note.text, open() {
		launch('stickies');
	}})),
];

part(sherlock, 'index').addEventListener('click', async () => {
	if (isSearching) {
		return;
	}

	isSearching = true;
	await runMeter(3.5, progress => {
		const minutes = Math.round((1 - progress) * 180);
		sherlockSummary.textContent = `Indexing “Macintosh HD”… about ${Math.floor(minutes / 60)} hours and ${minutes % 60} minutes remaining.`;
	});
	isSearching = false;
	isIndexed = true;
	announce(sherlockSummary, 'Indexed! That took 3 hours. (For you, 3 seconds.) Now search for words in my files and your notes.');
});

const searchContent = async query => {
	if (!isIndexed) {
		announce(sherlockSummary, 'Macintosh HD is not indexed. Press Index Volumes first. It takes about 3 hours.');
		return;
	}

	await runMeter(0.8);
	const words = query.toLowerCase().split(/\s+/).filter(Boolean);
	const countWords = text => {
		let count = 0;
		for (const word of words) {
			count += text.toLowerCase().split(word).length - 1;
		}

		return count;
	};

	const found = searchableFiles()
		.map(file => ({...file, count: countWords(file.text)}))
		.filter(file => file.count > 0)
		.sort((first, second) => second.count - first.count);

	const top = found[0]?.count ?? 1;
	for (const file of found) {
		addResult({title: file.title, relevance: Math.round(file.count / top * 100), onChoose() {
			if (file.open) {
				file.open();
			} else if (file.title === 'Read Me!') {
				launch('simpletext');
			} else {
				announce(sherlockSummary, `${file.title}: “${file.text.slice(0, 120)}”`);
			}
		}});
	}

	announce(sherlockSummary, found.length === 0 ? `Nothing on the disk has “${query}” in it. Write it in the Note Pad, and search again!` : `${found.length} file${found.length === 1 ? '' : 's'} with “${query}”.`);
};

onOpen.sherlock = () => {
	setSherlockMode(sherlockMode);
	part(sherlock, 'query').focus();
};

// The Graphing Calculator: an equation of x, read by a small parser (never `eval`), drawn on axes, and the Demo, a surface that turns in 3D.
const graphing = windowsByName.get('graphing');
const plot = part(graphing, 'plot');
const graphStatus = part(graphing, 'status');

const functions = {sin: Math.sin, cos: Math.cos, tan: Math.tan, sqrt: Math.sqrt, abs: Math.abs, log: Math.log10, ln: Math.log, exp: Math.exp, floor: Math.floor, round: Math.round};

// Reads an expression like `2x^2 + sin(x)/x` into a function of x, with the usual order of operations, and multiplication without a sign, like `2x` or `3(x + 1)`.
const parseEquation = source => {
	const text = source.toLowerCase().replace(/^\s*y\s*=/, '').replaceAll('×', '*').replaceAll('π', 'pi');
	const tokens = text.match(/\d*\.?\d+|[a-z]+|[-+*/^()]|\S/g) ?? [];
	let position = 0;
	const peek = () => tokens[position];
	const next = () => tokens[position++];
	const expect = token => {
		if (next() !== token) {
			throw new Error(`I expected “${token}”.`);
		}
	};

	const startsFactor = token => token !== undefined && (/^[\d.a-z(]/.test(token));

	const expression = () => {
		let value = term();
		while (peek() === '+' || peek() === '-') {
			const operator = next();
			const left = value;
			const right = term();
			value = operator === '+' ? x => left(x) + right(x) : x => left(x) - right(x);
		}

		return value;
	};

	const term = () => {
		let value = unary();
		while (peek() === '*' || peek() === '/' || startsFactor(peek())) {
			const operator = peek() === '*' || peek() === '/' ? next() : '*';
			const left = value;
			const right = unary();
			value = operator === '*' ? x => left(x) * right(x) : x => left(x) / right(x);
		}

		return value;
	};

	const unary = () => {
		if (peek() === '-') {
			next();
			const value = unary();
			return x => -value(x);
		}

		return power();
	};

	const power = () => {
		const base = factor();
		if (peek() === '^') {
			next();
			const exponent = unary();
			return x => base(x) ** exponent(x);
		}

		return base;
	};

	const factor = () => {
		const token = next();
		if (token === undefined) {
			throw new Error('The equation ends too early.');
		}

		if (/^\d*\.?\d+$/.test(token)) {
			const number = Number(token);
			return () => number;
		}

		if (token === 'x') {
			return x => x;
		}

		if (token === 'pi') {
			return () => Math.PI;
		}

		if (token === 'e') {
			return () => Math.E;
		}

		if (token === '(') {
			const value = expression();
			expect(')');
			return value;
		}

		if (Object.hasOwn(functions, token)) {
			const function_ = functions[token];
			const argument = factor();
			return x => function_(argument(x));
		}

		throw new Error(`I do not know “${token}”.`);
	};

	const result = expression();
	if (position < tokens.length) {
		throw new Error(`I do not understand “${tokens[position]}”.`);
	}

	return result;
};

const drawAxes = context => {
	const {width, height} = plot;
	context.fillStyle = '#ffffff';
	context.fillRect(0, 0, width, height);
	context.strokeStyle = '#e4e4f4';
	context.lineWidth = 1;
	for (let unit = -10; unit <= 10; unit++) {
		const x = (unit + 10) / 20 * width;
		const y = height / 2 - (unit * width / 20);
		context.beginPath();
		context.moveTo(x, 0);
		context.lineTo(x, height);
		context.moveTo(0, y);
		context.lineTo(width, y);
		context.stroke();
	}

	context.strokeStyle = '#000000';
	context.beginPath();
	context.moveTo(width / 2, 0);
	context.lineTo(width / 2, height);
	context.moveTo(0, height / 2);
	context.lineTo(width, height / 2);
	context.stroke();
};

let demoAngle = 0;
let isDemo = false;

const graph = () => {
	isDemo = false;
	const context = plot.getContext('2d');
	const equation = part(graphing, 'equation').value;
	let compute;
	try {
		compute = parseEquation(equation);
	} catch (error) {
		announce(graphStatus, `Syntax error: ${error.message} Try something like y = x^2 - 3.`);
		return;
	}

	drawAxes(context);
	const {width, height} = plot;
	const scale = width / 20;
	context.strokeStyle = '#cc2222';
	context.lineWidth = 2;
	context.beginPath();
	let isDrawing = false;
	let previous;
	for (let pixel = 0; pixel <= width; pixel++) {
		const x = (pixel / scale) - 10;
		const y = compute(x);
		const screenY = (height / 2) - (y * scale);
		if (!Number.isFinite(y) || Math.abs(screenY) > height * 4 || (previous !== undefined && Math.abs(screenY - previous) > height)) {
			isDrawing = false;
			previous = undefined;
			continue;
		}

		if (isDrawing) {
			context.lineTo(pixel, screenY);
		} else {
			context.moveTo(pixel, screenY);
			isDrawing = true;
		}

		previous = screenY;
	}

	context.stroke();
	announce(graphStatus, `Graphed ${equation.trim()}. Ron Avitzur kept sneaking into Apple after his contract ended, to finish this program. Apple put it on every PowerPC Mac.`);
};

// The Demo: z = sin(r) / r as a net of lines, turning slowly, only while the window is open, on screen, and the visitor does not prefer less motion.
const drawDemo = () => {
	const context = plot.getContext('2d');
	const {width, height} = plot;
	context.fillStyle = '#000033';
	context.fillRect(0, 0, width, height);
	const size = 14;
	const project = (x, y, z) => {
		const cos = Math.cos(demoAngle);
		const sin = Math.sin(demoAngle);
		const rotatedX = (x * cos) - (y * sin);
		const rotatedY = (x * sin) + (y * cos);
		return [(width / 2) + (rotatedX * 11), (height * 0.6) + (rotatedY * 4.5) - (z * 60)];
	};

	const heightAt = (x, y) => {
		const radius = Math.hypot(x, y) + 0.0001;
		return Math.sin(radius) / radius;
	};

	for (let line = -size; line <= size; line += 1.4) {
		context.strokeStyle = `hsl(${200 + (line * 6)}, 90%, 60%)`;
		context.beginPath();
		for (let along = -size; along <= size; along += 0.7) {
			const [x, y] = project(line, along, heightAt(line, along));
			if (along === -size) {
				context.moveTo(x, y);
			} else {
				context.lineTo(x, y);
			}
		}

		context.stroke();
		context.beginPath();
		for (let along = -size; along <= size; along += 0.7) {
			const [x, y] = project(along, line, heightAt(along, line));
			if (along === -size) {
				context.moveTo(x, y);
			} else {
				context.lineTo(x, y);
			}
		}

		context.stroke();
	}
};

const demoLoop = makeLoop(plot, seconds => {
	demoAngle += seconds * 0.6;
	drawDemo();
}, () => isDemo && !graphing.hidden && !reducedMotion.matches);

part(graphing, 'form').addEventListener('submit', event => {
	event.preventDefault();
	graph();
});

part(graphing, 'demo').addEventListener('click', () => {
	isDemo = true;
	drawDemo();
	demoLoop.start();
	announce(graphStatus, reducedMotion.matches ? 'The Demo: z = sin(r) / r. (It stands still, as you prefer less motion.)' : 'The Demo: z = sin(r) / r, turning in 3D. In 1994, this was magic.');
});

onOpen.graphing = graph;
reducedMotion.addEventListener('change', () => {
	demoLoop.start();
});

// Bugdom Jr.: Rollie McFly, a pill bug, frees the ladybugs from the cages of the fire ants. Rolled up into a ball, he is fast, breaks cages, and knocks ants away, but he gets dizzy. Walking, he picks clovers, and the ants bite.
const bugdom = windowsByName.get('bugdom');
const gameCanvas = part(bugdom, 'game');
const gameContext = gameCanvas.getContext('2d');
const gameStatus = part(bugdom, 'status');
const gameWidth = gameCanvas.width;
const gameHeight = gameCanvas.height;
const input = {left: false, right: false, up: false, down: false};
let game;

const rocks = [[70, 70, 16], [250, 60, 14], [160, 150, 18], [60, 190, 12], [270, 190, 15]];

const newGame = () => {
	game = {
		state: 'playing',
		bug: {x: 30, y: 120, vx: 0, vy: 0, isBall: false, energy: 1, dizzy: 0, health: 3, hurt: 0, angle: 0, facing: 1},
		ants: [[200, 40], [280, 120], [140, 210]].map(([x, y]) => ({x, y, stun: 0})),
		cages: [[110, 30], [300, 30], [215, 120], [110, 215], [300, 215]].map(([x, y]) => ({x, y, isOpen: false, fly: 0})),
		clovers: Array.from({length: 10}, (_, index) => ({x: 20 + ((index * 61) % 280), y: 20 + ((index * 97) % 200), isTaken: false})),
		score: 0,
		time: 0,
		spawn: 10,
		hint: '',
		frame: 0,
	};
	announce(gameStatus, 'Go, Rollie! Free the 5 ladybugs. Space (or Roll) rolls you up.');
};

const freedCount = () => game.cages.filter(cage => cage.isOpen).length;

const setGameMessage = text => {
	if (game.hint !== text) {
		game.hint = text;
		announce(gameStatus, text);
	}
};

const isBlocked = (x, y) => rocks.some(([rockX, rockY, radius]) => Math.hypot(x - rockX, y - rockY) < radius + 7);

const stepGame = seconds => {
	if (game.state !== 'playing') {
		return;
	}

	// Too little memory in Get Info: Bugdom Jr. runs out of it a few seconds in.
	game.time += seconds;
	if (running.get('bugdom') < programs.bugdom.needs && game.time > 3) {
		game.state = 'crashed';
		crashProgram('bugdom', 25);
		return;
	}

	const bug = game.bug;
	const dx = (input.right ? 1 : 0) - (input.left ? 1 : 0);
	const dy = (input.down ? 1 : 0) - (input.up ? 1 : 0);
	if (dx !== 0) {
		bug.facing = dx;
	}

	bug.dizzy = Math.max(0, bug.dizzy - seconds);
	bug.hurt = Math.max(0, bug.hurt - seconds);
	if (bug.isBall) {
		bug.vx += dx * 260 * seconds;
		bug.vy += dy * 260 * seconds;
		bug.vx *= 0.985;
		bug.vy *= 0.985;
		const speed = Math.hypot(bug.vx, bug.vy);
		if (speed > 150) {
			bug.vx *= 150 / speed;
			bug.vy *= 150 / speed;
		}

		bug.energy -= seconds * 0.22;
		bug.angle += speed * seconds * 0.12;
		if (bug.energy <= 0) {
			bug.energy = 0;
			bug.isBall = false;
			bug.dizzy = 1.5;
			setGameMessage('Rollie is dizzy! Walk a little to get your breath back.');
		}
	} else {
		const length = Math.hypot(dx, dy) || 1;
		const speed = bug.dizzy > 0 ? 25 : 62;
		bug.vx = dx / length * speed;
		bug.vy = dy / length * speed;
		bug.energy = Math.min(1, bug.energy + (seconds * 0.25));
	}

	const nextX = bug.x + (bug.vx * seconds);
	const nextY = bug.y + (bug.vy * seconds);
	if (nextX < 8 || nextX > gameWidth - 8 || isBlocked(nextX, bug.y)) {
		bug.vx *= bug.isBall ? -0.6 : 0;
	} else {
		bug.x = nextX;
	}

	if (nextY < 8 || nextY > gameHeight - 8 || isBlocked(bug.x, nextY)) {
		bug.vy *= bug.isBall ? -0.6 : 0;
	} else {
		bug.y = nextY;
	}

	const speed = Math.hypot(bug.vx, bug.vy);

	for (const clover of game.clovers) {
		if (!clover.isTaken && !bug.isBall && Math.hypot(clover.x - bug.x, clover.y - bug.y) < 12) {
			clover.isTaken = true;
			game.score += 10;
			if (game.clovers.every(other => other.isTaken)) {
				bug.health = Math.min(3, bug.health + 1);
				for (const other of game.clovers) {
					other.isTaken = false;
				}

				setGameMessage('All the clovers! Rollie feels better: one more life. More clovers grew.');
			}
		}
	}

	for (const cage of game.cages) {
		const distance = Math.hypot(cage.x - bug.x, cage.y - bug.y);
		if (!cage.isOpen && distance < 16) {
			if (bug.isBall && speed > 55) {
				cage.isOpen = true;
				game.score += 50;
				bug.vx *= -0.5;
				bug.vy *= -0.5;
				tone(880, 0, 0.1, {type: 'square', gain: 0.1});
				tone(1320, 0.1, 0.2, {type: 'square', gain: 0.1});
				// King Thorax gets angry: every second free ladybug sends another fire ant, and they all get a little faster.
				const isAngry = freedCount() % 2 === 0;
				if (isAngry) {
					game.ants.push({x: gameWidth - 12, y: 12, stun: 0});
				}

				setGameMessage(`A ladybug is free! ${freedCount()} of 5.${isAngry ? ' King Thorax sends another fire ant!' : ''}`);
			} else {
				setGameMessage(bug.isBall ? 'Faster! Roll into the cage hard.' : 'Only a rolling pill bug breaks a cage. Press Space, and roll into it!');
			}
		}

		if (cage.isOpen) {
			cage.fly += seconds;
		}
	}

	// The fire ants follow Rollie when he is near, and wander when he is not. More come from the anthill of King Thorax.
	game.spawn -= seconds;
	if (game.spawn <= 0 && game.ants.length < 8) {
		game.spawn = 11;
		game.ants.push({x: gameWidth - 12, y: 12, stun: 0});
	}

	for (const ant of game.ants) {
		ant.stun = Math.max(0, ant.stun - seconds);
		if (ant.stun > 0) {
			continue;
		}

		const toBugX = bug.x - ant.x;
		const toBugY = bug.y - ant.y;
		const distance = Math.hypot(toBugX, toBugY) || 1;
		const antSpeed = (distance < 120 ? 42 : 18) + (freedCount() * 3);
		const angle = distance < 120 ? Math.atan2(toBugY, toBugX) : (ant.wander ??= Math.random() * Math.PI * 2);
		if (distance >= 120 && Math.random() < seconds) {
			ant.wander = Math.random() * Math.PI * 2;
		}

		const antX = ant.x + (Math.cos(angle) * antSpeed * seconds);
		const antY = ant.y + (Math.sin(angle) * antSpeed * seconds);
		if (!isBlocked(antX, antY) && antX > 6 && antX < gameWidth - 6 && antY > 6 && antY < gameHeight - 6) {
			ant.x = antX;
			ant.y = antY;
		} else {
			ant.wander = Math.random() * Math.PI * 2;
		}

		if (distance < 13) {
			if (bug.isBall && speed > 40) {
				ant.stun = 3;
				ant.x -= toBugX / distance * 30;
				ant.y -= toBugY / distance * 30;
				game.score += 5;
				tone(220, 0, 0.12, {type: 'square', endFrequency: 110, gain: 0.12});
			} else if (!bug.isBall && bug.hurt === 0) {
				bug.health--;
				bug.hurt = 1.5;
				bug.x += toBugX / distance * 18;
				bug.y += toBugY / distance * 18;
				tone(150, 0, 0.25, {type: 'sawtooth', endFrequency: 80, gain: 0.15});
				setGameMessage(bug.health > 0 ? `Ouch! A fire ant bit Rollie. ${bug.health} li${bug.health === 1 ? 'fe' : 'ves'} left. Roll up to knock them away!` : '');
			}
		}
	}

	if (freedCount() === 5) {
		game.state = 'won';
		const score = game.score + Math.max(0, 300 - Math.round(game.time * 2));
		const isBest = score > settings.bugdomBest;
		if (isBest) {
			settings.bugdomBest = score;
			persist();
		}

		celebrate();
		setGameMessage(`All 5 ladybugs are free! King Thorax is furious. ${score} points in ${Math.round(game.time)} seconds.${isBest ? ' A new record!' : ` My record is ${settings.bugdomBest}.`}`);
	} else if (bug.health <= 0) {
		game.state = 'lost';
		setGameMessage(`The fire ants got Rollie. ${freedCount()} of 5 ladybugs free, ${game.score} points. Press New Game.`);
	}
};

const drawGame = () => {
	const context = gameContext;
	context.fillStyle = '#3c8a3c';
	context.fillRect(0, 0, gameWidth, gameHeight);
	context.fillStyle = '#4fa34f';
	for (let index = 0; index < 60; index++) {
		context.fillRect((index * 53) % gameWidth, (index * 37) % gameHeight, 2, 5);
	}

	// The anthill of King Thorax.
	context.fillStyle = '#8b5a2b';
	context.beginPath();
	context.arc(gameWidth - 10, 10, 18, 0, Math.PI * 2);
	context.fill();

	for (const [x, y, radius] of rocks) {
		context.fillStyle = '#8a8a80';
		context.beginPath();
		context.arc(x, y, radius, 0, Math.PI * 2);
		context.fill();
		context.fillStyle = '#a8a89c';
		context.beginPath();
		context.arc(x - (radius * 0.3), y - (radius * 0.3), radius * 0.4, 0, Math.PI * 2);
		context.fill();
	}

	for (const clover of game.clovers) {
		if (!clover.isTaken) {
			context.fillStyle = '#7CFC00';
			for (const [offsetX, offsetY] of [[-3, -2], [3, -2], [0, 3]]) {
				context.beginPath();
				context.arc(clover.x + offsetX, clover.y + offsetY, 3, 0, Math.PI * 2);
				context.fill();
			}
		}
	}

	for (const cage of game.cages) {
		const flyY = cage.y - (cage.fly * 40);
		if (!cage.isOpen || flyY > -10) {
			context.fillStyle = '#dd2222';
			context.beginPath();
			context.arc(cage.x, flyY, 6, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#000000';
			context.fillRect(cage.x - 0.5, flyY - 6, 1, 12);
			context.fillRect(cage.x - 3, flyY - 2, 2, 2);
			context.fillRect(cage.x + 2, flyY + 1, 2, 2);
		}

		if (!cage.isOpen) {
			context.strokeStyle = '#5a3a1a';
			context.lineWidth = 2;
			context.strokeRect(cage.x - 10, cage.y - 10, 20, 20);
			for (let bar = -6; bar <= 6; bar += 4) {
				context.beginPath();
				context.moveTo(cage.x + bar, cage.y - 10);
				context.lineTo(cage.x + bar, cage.y + 10);
				context.stroke();
			}
		}
	}

	for (const ant of game.ants) {
		context.fillStyle = ant.stun > 0 ? '#ff9999' : '#cc1100';
		for (const offset of [-5, 0, 5]) {
			context.beginPath();
			context.arc(ant.x + offset, ant.y, offset === 0 ? 2.5 : 3.5, 0, Math.PI * 2);
			context.fill();
		}

		if (ant.stun > 0) {
			context.fillStyle = '#ffff66';
			context.fillText('★', ant.x - 3, ant.y - 6);
		}
	}

	const bug = game.bug;
	const isBlinking = bug.hurt > 0 && Math.floor(bug.hurt * 10) % 2 === 0;
	if (!isBlinking) {
		context.save();
		context.translate(bug.x, bug.y);
		if (bug.isBall) {
			context.rotate(bug.angle);
			context.fillStyle = '#777777';
			context.beginPath();
			context.arc(0, 0, 8, 0, Math.PI * 2);
			context.fill();
			context.strokeStyle = '#444444';
			context.lineWidth = 1.5;
			for (const offset of [-4, 0, 4]) {
				context.beginPath();
				context.moveTo(offset, -7);
				context.lineTo(offset, 7);
				context.stroke();
			}
		} else {
			context.scale(bug.facing, 1);
			context.fillStyle = '#888888';
			context.beginPath();
			context.ellipse(0, 0, 10, 6, 0, 0, Math.PI * 2);
			context.fill();
			context.strokeStyle = '#555555';
			context.lineWidth = 1;
			for (const offset of [-5, -1, 3]) {
				context.beginPath();
				context.moveTo(offset, -6);
				context.lineTo(offset, 6);
				context.stroke();
			}

			context.fillStyle = '#ffffff';
			context.fillRect(6, -3, 3, 3);
			context.fillStyle = '#000000';
			context.fillRect(7, -2, 2, 2);
		}

		context.restore();
		if (bug.dizzy > 0) {
			context.fillStyle = '#ffff66';
			context.fillText('@', bug.x - 3, bug.y - 10);
		}
	}

	// The status at the top: lives, roll energy, ladybugs, and points.
	context.fillStyle = 'rgba(0, 0, 0, 0.5)';
	context.fillRect(0, gameHeight - 14, gameWidth, 14);
	context.font = 'bold 10px Geneva, Arial, sans-serif';
	context.fillStyle = '#ffffff';
	context.textBaseline = 'middle';
	context.fillText(`${'♥'.repeat(Math.max(game.bug.health, 0))}  Ladybugs ${freedCount()}/5  ${game.score} pts`, 4, gameHeight - 7);
	context.fillStyle = '#333333';
	context.fillRect(gameWidth - 64, gameHeight - 11, 60, 8);
	context.fillStyle = game.bug.energy > 0.3 ? '#66ccff' : '#ff6666';
	context.fillRect(gameWidth - 64, gameHeight - 11, 60 * game.bug.energy, 8);

	if (game.state !== 'playing') {
		context.fillStyle = 'rgba(0, 0, 0, 0.55)';
		context.fillRect(0, (gameHeight / 2) - 20, gameWidth, 40);
		context.fillStyle = '#ffffff';
		context.font = 'bold 16px Geneva, Arial, sans-serif';
		context.textAlign = 'center';
		context.fillText(game.state === 'won' ? 'All the ladybugs are free!' : (game.state === 'lost' ? 'Game over' : 'Out of memory'), gameWidth / 2, gameHeight / 2);
		context.textAlign = 'start';
	}
};

const isHoldingDirection = () => input.left || input.right || input.up || input.down;

const gameLoop = makeLoop(gameCanvas, seconds => {
	if (!game) {
		return;
	}

	// RAM Doubler makes the game choppy: it only moves on every other frame. With reduced motion, it only moves while a direction is held.
	game.frame++;
	const isChoppy = isExtensionActive('ramdoubler') && game.frame % 2 === 1;
	if (!isChoppy && (!reducedMotion.matches || isHoldingDirection())) {
		stepGame(isExtensionActive('ramdoubler') ? seconds * 2 : seconds);
	}

	// The step can crash the game, which quits it.
	if (!game) {
		return;
	}

	drawGame();
}, () => Boolean(game) && !bugdom.hidden && running.has('bugdom'));

const toggleRoll = () => {
	if (!game || game.state !== 'playing') {
		return;
	}

	const bug = game.bug;
	if (bug.isBall) {
		bug.isBall = false;
	} else if (bug.dizzy === 0 && bug.energy > 0.15) {
		bug.isBall = true;
		bug.vx *= 1.6;
		bug.vy *= 1.6;
	}
};

const keyDirections = {ArrowLeft: 'left', ArrowRight: 'right', ArrowUp: 'up', ArrowDown: 'down', a: 'left', d: 'right', w: 'up', s: 'down'};

gameCanvas.addEventListener('keydown', event => {
	const direction = keyDirections[event.key];
	if (direction) {
		event.preventDefault();
		input[direction] = true;
		gameLoop.start();
	} else if (event.key === ' ') {
		event.preventDefault();
		if (!event.repeat) {
			toggleRoll();
		}
	} else if (event.key === 'Enter' && game?.state !== 'playing') {
		newGame();
		gameLoop.start();
	}
});

gameCanvas.addEventListener('keyup', event => {
	const direction = keyDirections[event.key];
	if (direction) {
		input[direction] = false;
	}
});

gameCanvas.addEventListener('blur', () => {
	for (const direction of Object.keys(input)) {
		input[direction] = false;
	}
});

for (const direction of ['left', 'right', 'up', 'down']) {
	const button = part(bugdom, `pad-${direction}`);
	button.addEventListener('pointerdown', event => {
		event.preventDefault();
		button.setPointerCapture(event.pointerId);
		input[direction] = true;
		gameLoop.start();
	});

	for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
		button.addEventListener(type, () => {
			input[direction] = false;
		});
	}
}

part(bugdom, 'pad-roll').addEventListener('click', toggleRoll);

part(bugdom, 'start').addEventListener('click', () => {
	newGame();
	gameLoop.start();
	gameCanvas.focus();
});

onOpen.bugdom = () => {
	newGame();
	drawGame();
	gameLoop.start();
	gameCanvas.focus();
};

onQuit.bugdom = () => {
	game = undefined;
};

// Netscape Communicator 4.6: it loads my home page slowly, and unexpectedly quits before it is done, with an error of a new type each time.
const netscape = windowsByName.get('netscape');
let netscapeRun = 0;

onOpen.netscape = async () => {
	netscapeRun++;
	const run = netscapeRun;
	const page = part(netscape, 'page');
	const statusLine = part(netscape, 'status');
	const throbber = part(netscape, 'throbber');
	page.replaceChildren();
	throbber.dataset.state = 'on';
	const lines = ['Welcome to Sindre’s Home Page!!!', 'You are visitor number 000014.', 'This page is best viewed with Netscape Navigator.', 'Loading the MIDI of the Titanic song…'];
	const steps = ['Looking up host: www.geocities.com…', 'Contacting host: www.geocities.com…', 'Host contacted. Waiting for reply…', 'Document: 12% of 34K', 'Document: 47% of 34K (1.2K/sec)', 'Loading images: 3 of 47'];
	const crashAt = randomInteger(3, steps.length - 1);
	for (const [index, text] of steps.entries()) {
		statusLine.textContent = text;
		if (index >= 3 && lines[index - 3]) {
			const line = document.createElement('p');
			line.textContent = lines[index - 3];
			page.append(line);
		}

		await wait(900);
		if (run !== netscapeRun) {
			return;
		}

		if (index === crashAt) {
			break;
		}
	}

	throbber.dataset.state = '';
	settings.netscapeCrashes++;
	persist();
	crashProgram('netscape', randomItem([1, 2, 3, 10, 11]));
	if (settings.netscapeCrashes % 5 === 0) {
		toast(`Netscape has crashed ${settings.netscapeCrashes} times on this iMac. That is a record. Probably.`);
	}
};

onQuit.netscape = () => {
	netscapeRun++;
};

// The installer of the Mac OS 8.6 CD: it puts the System Folder back on the disk, and everything that was thrown away.
const installer = windowsByName.get('installer');
let isInstalling = false;

part(installer, 'start').addEventListener('click', async () => {
	if (isInstalling) {
		return;
	}

	isInstalling = true;
	const run = bootRun;
	const fill = part(installer, 'fill');
	const steps = ['Checking “Macintosh HD”…', 'Installing System software…', 'Installing the Finder…', 'Installing Appearance…', 'Installing the desk accessories…', 'Updating the disk driver…', 'Cleaning up…'];
	for (const [index, text] of steps.entries()) {
		part(installer, 'status').textContent = text;
		fill.style.width = `${(index + 1) / steps.length * 100}%`;
		await wait(700);

		// Shutting down or quitting the installer in the middle stops it, without installing anything.
		if (run !== bootRun || !running.has('installer')) {
			isInstalling = false;
			fill.style.width = '0%';
			part(installer, 'status').textContent = '';
			return;
		}
	}

	const kept = items.filter(item => !item.inTrash || item.id === 'system');
	const restored = makeItems().filter(item => !kept.some(other => other.id === item.id));
	items = [...kept.map(item => ({...item, inTrash: false})), ...restored];
	session.systemInTrash = false;
	isInstalling = false;
	fill.style.width = '0%';
	part(installer, 'status').textContent = '';
	renderDesktop();
	const answer = await showAlert({icon: 'finder', text: 'Installation was successful. Mac OS 8.6 is on “Macintosh HD”.', detail: 'You need to restart to use it.', buttons: [{label: 'Quit', value: 'quit'}, {label: 'Restart', value: 'restart'}]});
	if (answer === 'restart') {
		restart();
	} else {
		quitProgram('installer');
	}
});

// After Dark: the Flying Toasters, when the desktop is left alone for a while, until the mouse moves or a key is pressed. Not with reduced motion.
let idleTimer;
let isSaving = false;
let toasters = [];

const stopSaver = () => {
	isSaving = false;
	saverCanvas.hidden = true;
};

const resetIdle = () => {
	clearTimeout(idleTimer);
	if (isSaving) {
		stopSaver();
	}

	if (session.power === 'on' && isExtensionActive('afterdark') && !reducedMotion.matches) {
		idleTimer = setTimeout(startSaver, 45_000);
	}
};

const startSaver = () => {
	if (session.power !== 'on' || !alertBox.hidden) {
		return;
	}

	isSaving = true;
	saverCanvas.hidden = false;
	saverCanvas.width = desktop.clientWidth;
	saverCanvas.height = desktop.clientHeight;
	toasters = Array.from({length: 9}, (_, index) => ({x: Math.random() * saverCanvas.width, y: Math.random() * saverCanvas.height, isToast: index % 3 === 2, speed: 30 + (Math.random() * 30), flap: Math.random() * 6}));
	saverLoop.start();
};

const drawToaster = (context, toaster) => {
	context.save();
	context.translate(toaster.x, toaster.y);
	context.scale(1.6, 1.6);
	drawToasterShape(context, toaster);
	context.restore();
};

// A toaster with flapping wings, or a slice of toast, at 0, 0.
const drawToasterShape = (context, toaster) => {
	const x = 0;
	const y = 0;
	if (toaster.isToast) {
		context.fillStyle = '#c8803a';
		context.fillRect(x, y, 16, 14);
		context.fillStyle = '#f0c080';
		context.fillRect(x + 2, y + 2, 12, 10);
		return;
	}

	context.fillStyle = '#c0c0c8';
	context.fillRect(x, y, 26, 18);
	context.fillStyle = '#e8e8f0';
	context.fillRect(x + 2, y + 2, 22, 4);
	context.fillStyle = '#333333';
	context.fillRect(x + 6, y, 5, 2);
	context.fillRect(x + 15, y, 5, 2);
	const wing = Math.sin(toaster.flap) * 10;
	context.fillStyle = '#ffffff';
	context.beginPath();
	context.moveTo(x + 4, y + 6);
	context.lineTo(x - 12, y - 4 + wing);
	context.lineTo(x + 2, y + 12);
	context.moveTo(x + 22, y + 6);
	context.lineTo(x + 38, y - 4 + wing);
	context.lineTo(x + 24, y + 12);
	context.fill();
};

const saverLoop = makeLoop(saverCanvas, seconds => {
	const context = saverCanvas.getContext('2d');
	context.fillStyle = '#000000';
	context.fillRect(0, 0, saverCanvas.width, saverCanvas.height);
	for (const toaster of toasters) {
		toaster.x -= toaster.speed * seconds;
		toaster.y += toaster.speed * seconds * 0.5;
		toaster.flap += seconds * 8;
		if (toaster.x < -40 || toaster.y > saverCanvas.height + 20) {
			toaster.x = saverCanvas.width + Math.random() * 60;
			toaster.y = -20 - (Math.random() * saverCanvas.height * 0.5);
		}

		drawToaster(context, toaster);
	}
}, () => isSaving && !reducedMotion.matches);

for (const type of ['pointermove', 'pointerdown', 'keydown', 'wheel']) {
	screen.addEventListener(type, resetIdle, {passive: true});
}

reducedMotion.addEventListener('change', () => {
	if (reducedMotion.matches) {
		stopSaver();
	}

	resetIdle();
});

// Escape closes the window in front, as long as no alert is up, and the keys only act inside the iMac.
desktop.addEventListener('keydown', event => {
	if (event.key !== 'Escape' || openTitle) {
		return;
	}

	const element = event.target.closest('[data-mac-window]');
	if (element) {
		event.preventDefault();
		if (element.dataset.macWindow.startsWith('sticky-')) {
			element.querySelector('[data-mac-close]').click();
		} else {
			closeWindow(element);
		}
	}
});

screen.addEventListener('keydown', event => {
	if (session.power === 'sleep') {
		wake();
	}
});

// The start: the picture of the Apple menu and the icons of the menus.
for (const image of desktop.querySelectorAll('[data-mac-part^="icon-"]')) {
	image.src = spriteURL(image.dataset.macPart.slice('icon-'.length));
}

desktop.querySelector('[data-mac-part="apple-logo"]').src = spriteURL('apple');
drawFace(windowPart('about', 'face'), 48);
screen.dataset.macTheme = settings.theme;
applyDepth();
updateSwitcher();
setFrontProgram('finder');
setSpeakers(false);
