// More of Windows 98 on the desktop of the 1999 page: the Start menu with its submenus, the menu of the right mouse button, icons that drag and go to the Recycle Bin, the taskbar buttons, the tray, and the programs: Calculator, the MS-DOS Prompt, WordPad with an Office Assistant, Internet Explorer with Dial-Up Networking, Network Neighborhood, My Documents, Notepad, Media Player, Sound Recorder, FreeCell, the Control Panel, Y2K Fixer 2000 (which stops responding), Find, Run, Close Program, the Welcome tour, the log on, the startup screen, the blue screen of the launch of Windows 98, the 3D Maze, Flying Windows, and Scrolling Marquee screen savers, the Active Desktop, Shut Down Windows with Stand by and MS-DOS mode, ScanDisk after a crash, CIH, StickyKeys, low memory, shy icons, the Kit-Cat Klock, and a Recycle Bin that overflows. `geocities.js` opens, drags, and closes the windows. Nothing makes a sound until the visitor turns on the sounds of a desktop theme, or presses Play.
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');

// The speculation rules of the site can prerender the page. The desktop waits until the visitor opens it.
if (document.prerendering) {
	await new Promise(resolve => {
		document.addEventListener('prerenderingchange', resolve, {once: true});
	});
}

// The storage can be missing or full, like in a private window, so everything also works without it.
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

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

const wait = milliseconds => new Promise(resolve => {
	setTimeout(resolve, milliseconds);
});

// The toast and the win of Solitaire are in `geocities.js`, which listens for these events.
const toast = message => {
	document.dispatchEvent(new CustomEvent('geocities-toast', {detail: {message}}));
};

const celebrate = () => {
	document.dispatchEvent(new Event('geocities-celebrate'));
	document.dispatchEvent(new Event('geocities-cheer'));
};

// A status message is set a frame later, so screen readers announce the same message again.
const announce = (element, message) => {
	element.textContent = '';
	requestAnimationFrame(() => {
		element.textContent = message;
	});
};

// Copies the first element of a template.
const fromTemplate = template => template.content.firstElementChild.cloneNode(true);

const desktop = document.querySelector('#geocities-desktop');
const startMenu = document.querySelector('#geocities-start-menu');
const startButton = document.querySelector('#geocities-start-button');
const taskbar = startButton.parentElement;
const iconList = desktop.querySelector('[data-desktop-open]').closest('ul');
const clock = document.querySelector('#geocities-taskbar-clock');

// The desktop is only on the screen part of the time, so the things that move stop while it is not, or while the tab is hidden.
let isDesktopOnScreen = false;
const visibilityListeners = new Set();

const isDesktopVisible = () => isDesktopOnScreen && !document.hidden;

const notifyVisibility = () => {
	for (const listener of visibilityListeners) {
		listener(isDesktopVisible());
	}
};

new IntersectionObserver(entries => {
	isDesktopOnScreen = entries.at(-1).isIntersecting;
	notifyVisibility();
}).observe(desktop);

document.addEventListener('visibilitychange', notifyVisibility);

// The windows. `geocities.js` opens them in a cascade and gives the focus back to the opener when they close.
const windowOf = name => desktop.querySelector(`[data-desktop-window="${name}"]`);
const allWindows = [...desktop.querySelectorAll('[data-desktop-window]')];
const titleOf = appWindow => appWindow.querySelector('h3').textContent;

const openWindow = (name, opener = document.activeElement) => {
	desktop.dispatchEvent(new CustomEvent('geocities-open-window', {detail: {name, opener}}));
	return windowOf(name);
};

const closeWindow = name => {
	const appWindow = windowOf(name);

	if (!appWindow.hidden) {
		appWindow.querySelector('[data-desktop-close]').click();
	}
};

const setTitle = (name, title) => {
	const appWindow = windowOf(name);
	appWindow.querySelector('h3').textContent = title;
	appWindow.querySelector('[data-desktop-close]').setAttribute('aria-label', `Close ${title}`);
	updateTasks();
};

// A control that is disabled while something runs gives the focus to its window, so a keyboard does not start over at the top of the page, and gets it back when it is enabled again.
const setEnabled = (control, isEnabled) => {
	const appWindow = control.closest('[data-desktop-window]');

	if (!isEnabled && control === document.activeElement) {
		appWindow.focus();
	}

	control.disabled = !isEnabled;

	if (isEnabled && document.activeElement === appWindow) {
		control.focus();
	}
};

// Puts a window in the middle of the desktop, like a dialog of Windows.
const centerWindow = appWindow => {
	const bottom = desktop.clientHeight - taskbar.offsetHeight;
	appWindow.style.left = `${Math.max((desktop.clientWidth - appWindow.offsetWidth) / 2, 0)}px`;
	appWindow.style.top = `${Math.max((bottom - appWindow.offsetHeight) / 2, 0)}px`;
};

// Windows is busy for several reasons at once, like a page that loads while a program hangs, and the hourglass shows while any of them lasts.
const busyReasons = new Set();

const setBusy = (reason, isBusy) => {
	if (isBusy) {
		busyReasons.add(reason);
	} else {
		busyReasons.delete(reason);
	}

	if (busyReasons.size > 0) {
		desktop.dataset.winBusy = '';
	} else {
		delete desktop.dataset.winBusy;
	}
};

const closeStartMenu = () => {
	startMenu.hidden = true;
	startButton.setAttribute('aria-expanded', 'false');
};

// What each program does when its window opens and closes. A window opens and closes by its `hidden` attribute.
const onOpen = {};
const onClose = {};
// The windows in the order they opened, for the taskbar.
const openOrder = [];

new MutationObserver(records => {
	for (const {target} of records) {
		const name = target.dataset.desktopWindow;

		if (!name) {
			continue;
		}

		if (target.hidden) {
			const index = openOrder.indexOf(target);

			if (index !== -1) {
				openOrder.splice(index, 1);
			}

			// A message of a program closes with it, so it is not left alone on the desktop, and the program gets no answer.
			if (target === messageOwner) {
				closeWindow('message');
			}

			onClose[name]?.();
		} else if (!openOrder.includes(target)) {
			openOrder.push(target);
			playThemeSound();
			setDesktopShown(false);
			onOpen[name]?.();
		}
	}

	updateTasks();
	checkMemory();
}).observe(desktop, {attributes: true, attributeFilter: ['hidden'], subtree: true});

// Buttons like Cancel close their window.
desktop.addEventListener('click', event => {
	const button = event.target.closest('[data-win-close]');

	if (button) {
		button.closest('[data-desktop-window]').querySelector('[data-desktop-close]').click();
	}
});

// The sounds. Web Audio starts with the first sound, which is always after a click on something that says it plays sound.
const volumeButton = document.querySelector('#geocities-win-volume-button');
const volumePopup = document.querySelector('#geocities-win-volume');
const volumeLevel = document.querySelector('#geocities-win-volume-level');
const muteBox = document.querySelector('#geocities-win-mute');
const themeSounds = document.querySelector('#geocities-win-theme-sounds');
let audioContext;
let masterGain;

const updateVolume = () => {
	if (masterGain) {
		masterGain.gain.value = muteBox.checked ? 0 : Number(volumeLevel.value) / 100;
	}

	volumeButton.textContent = muteBox.checked || volumeLevel.value === '0' ? '🔇' : '🔊';
};

const audio = () => {
	if (!audioContext) {
		audioContext = new AudioContext();
		masterGain = audioContext.createGain();
		masterGain.connect(audioContext.destination);
		updateVolume();
	}

	if (audioContext.state === 'suspended') {
		audioContext.resume();
	}

	return audioContext;
};

// A short tone, like the beeps and chords of Windows.
const tone = (frequency, start, duration, {type = 'sine', volume = 0.2, slide} = {}) => {
	const context = audio();
	const oscillator = context.createOscillator();
	const gain = context.createGain();
	const time = context.currentTime + start;
	oscillator.type = type;
	oscillator.frequency.setValueAtTime(frequency, time);

	if (slide) {
		oscillator.frequency.exponentialRampToValueAtTime(slide, time + duration);
	}

	gain.gain.setValueAtTime(0.0001, time);
	gain.gain.exponentialRampToValueAtTime(volume, time + 0.02);
	gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
	oscillator.connect(gain).connect(masterGain);
	oscillator.start(time);
	oscillator.stop(time + duration + 0.05);
};

// The sounds of the desktop themes, made with tones instead of the WAV files of Windows.
const sounds = {
	chord() {
		for (const frequency of [523.25, 659.25, 783.99]) {
			tone(frequency, 0, 0.6, {type: 'triangle', volume: 0.12});
		}
	},
	ding() {
		tone(1318.5, 0, 0.5, {volume: 0.15});
	},
	sparkle() {
		for (const [index, frequency] of [1046.5, 1318.5, 1568, 2093].entries()) {
			tone(frequency, index * 0.07, 0.3, {volume: 0.1});
		}
	},
	roar() {
		tone(110, 0, 0.7, {type: 'sawtooth', volume: 0.15, slide: 55});
		tone(116, 0, 0.7, {type: 'square', volume: 0.06, slide: 58});
	},
	beep() {
		tone(880, 0, 0.08, {type: 'square', volume: 0.08});
		tone(1320, 0.1, 0.08, {type: 'square', volume: 0.08});
		tone(660, 0.2, 0.12, {type: 'square', volume: 0.08});
	},
	honk() {
		tone(392, 0, 0.18, {type: 'square', volume: 0.1});
		tone(392, 0.25, 0.3, {type: 'square', volume: 0.1});
	},
	startup() {
		for (const [index, frequency] of [392, 523.25, 659.25, 783.99, 1046.5].entries()) {
			tone(frequency, index * 0.18, 2.2 - (index * 0.18), {type: 'triangle', volume: 0.08});
		}
	},
	dial() {
		// The tones of the keypad, for the number of the Internet.
		const keys = {1: [697, 1209], 5: [770, 1336], 8: [852, 1336], 9: [852, 1477], 0: [941, 1336]};

		for (const [index, digit] of [...'81500999'].entries()) {
			for (const frequency of keys[digit]) {
				tone(frequency, index * 0.12, 0.09, {volume: 0.06});
			}
		}
	},
};

let themeSound = 'chord';

const playSound = name => {
	if (themeSounds.checked) {
		sounds[name]();
	}
};

function playThemeSound() {
	playSound(themeSound);
}

volumeButton.addEventListener('click', () => {
	volumePopup.hidden = !volumePopup.hidden;
	volumeButton.setAttribute('aria-expanded', String(!volumePopup.hidden));

	if (!volumePopup.hidden) {
		volumeLevel.focus();
	}
});

volumeLevel.addEventListener('input', updateVolume);
muteBox.addEventListener('change', updateVolume);

volumePopup.addEventListener('keydown', event => {
	if (event.key === 'Escape') {
		event.stopPropagation();
		volumePopup.hidden = true;
		volumeButton.setAttribute('aria-expanded', 'false');
		volumeButton.focus();
	}
});

document.addEventListener('pointerdown', event => {
	if (!volumePopup.hidden && !volumePopup.contains(event.target) && !volumeButton.contains(event.target)) {
		volumePopup.hidden = true;
		volumeButton.setAttribute('aria-expanded', 'false');
	}
});

// The message box of Windows, which asks a question and answers with the button that the visitor clicks, or nothing when the window closes. “Details >>” shows the details instead of answering.
const messageWindow = windowOf('message');
const messageIcon = document.querySelector('#geocities-win-message-icon');
const messageText = document.querySelector('#geocities-win-message-text');
const messageDetails = document.querySelector('#geocities-win-message-details');
const messageButtons = [...messageWindow.querySelectorAll('[data-win-message-button]')];
let answerMessage;
// The window of the program that asks, from its opener. A message that follows another one keeps its program.
let messageOwner;

const ask = ({title = 'Windows', icon = '⚠️', text, buttons = ['OK'], details, opener = document.activeElement}) => new Promise(resolve => {
	answerMessage?.(undefined);
	answerMessage = resolve;

	if (!messageWindow.contains(opener)) {
		messageOwner = opener?.closest('[data-desktop-window]') ?? undefined;
	}

	setTitle('message', title);
	messageIcon.textContent = icon;
	messageText.textContent = text;
	messageDetails.hidden = true;
	messageDetails.textContent = details ?? '';
	const labels = details ? [...buttons, 'Details >>'] : buttons;

	for (const [index, button] of messageButtons.entries()) {
		button.hidden = index >= labels.length;
		button.textContent = labels[index] ?? '';
	}

	// The opener of the message keeps the focus that it gives back, also when a message follows another.
	openWindow('message', messageWindow.contains(opener) ? startButton : opener);
	centerWindow(messageWindow);
	messageButtons[0].focus();
	playSound('ding');
});

for (const button of messageButtons) {
	button.addEventListener('click', () => {
		if (button.textContent === 'Details >>') {
			messageDetails.hidden = false;
			button.hidden = true;
			messageButtons[0].focus();
			return;
		}

		const answer = answerMessage;
		answerMessage = undefined;
		closeWindow('message');
		answer?.(button.textContent);
	});
}

onClose.message = () => {
	const answer = answerMessage;
	answerMessage = undefined;
	answer?.(undefined);
};

// The programs in their own scripts, like 3D Pinball, ask their questions with this message box, and play their sounds through the volume of the tray, with these events. `respond` gets the answer, and `use` gets the audio context and where its sounds go. A sound starts only in the handler of a click on something that says it plays sound.
desktop.addEventListener('geocities-win-ask', async event => {
	const answer = await ask(event.detail);
	event.detail.respond?.(answer);
});

desktop.addEventListener('geocities-win-audio', event => {
	event.detail.use(audio(), masterGain);
});

// The buttons of the taskbar, one for each open window, which bring it to the front. The window in front is pressed in.
const taskList = document.querySelector('#geocities-win-tasks');
const taskTemplate = document.querySelector('#geocities-win-task-template');
const taskButtons = new Map();

const frontWindow = () => {
	let front;

	for (const appWindow of openOrder) {
		if (!front || Number(appWindow.style.zIndex) > Number(front.style.zIndex)) {
			front = appWindow;
		}
	}

	return front;
};

function updateTasks() {
	for (const [appWindow, button] of taskButtons) {
		if (!openOrder.includes(appWindow)) {
			// The button of a window that closed could have the focus, which then goes to the Start button.
			if (button.contains(document.activeElement)) {
				startButton.focus();
			}

			button.remove();
			taskButtons.delete(appWindow);
		}
	}

	for (const appWindow of openOrder) {
		if (!taskButtons.has(appWindow)) {
			const button = fromTemplate(taskTemplate);

			button.addEventListener('click', () => {
				setDesktopShown(false);
				appWindow.focus();
			});

			taskList.append(button);
			taskButtons.set(appWindow, button);
		}

		const button = taskButtons.get(appWindow);
		button.textContent = titleOf(appWindow);
	}

	markFrontTask();
	updateBeginHint();
}

const markFrontTask = () => {
	const front = frontWindow();

	for (const [appWindow, button] of taskButtons) {
		button.setAttribute('aria-pressed', String(appWindow === front));

		if (appWindow === front) {
			button.dataset.winSelected = '';
		} else {
			delete button.dataset.winSelected;
		}
	}
};

// `geocities.js` brings a window to the front when it gets the focus or a click, before this runs.
for (const type of ['focusin', 'pointerdown']) {
	desktop.addEventListener(type, () => {
		requestAnimationFrame(markFrontTask);
	});
}

// The Start menu: a click, Enter, or the right arrow opens a submenu, and the left arrow or Escape closes it. The up and down arrows move between the items of the same list. With a mouse, a submenu also opens when the pointer rests on it.
const finePointer = matchMedia('(hover: hover) and (pointer: fine)');
let hoverTimer;
let hoveredButton;

const submenuButtons = [...startMenu.querySelectorAll('[data-win-submenu]')];

const setSubmenu = (button, isOpen) => {
	const list = button.nextElementSibling;

	if (!isOpen) {
		for (const inner of list.querySelectorAll('[data-win-submenu]')) {
			setSubmenu(inner, false);
		}
	}

	list.hidden = !isOpen;
	button.setAttribute('aria-expanded', String(isOpen));
};

// Opens a submenu and closes the others of its list, like Windows.
const openSubmenu = button => {
	for (const sibling of button.closest('ul').querySelectorAll(':scope > li > [data-win-submenu]')) {
		if (sibling !== button) {
			setSubmenu(sibling, false);
		}
	}

	setSubmenu(button, true);
};

for (const button of submenuButtons) {
	button.addEventListener('click', event => {
		// A click of the mouse keeps a submenu open that the pointer already opened, like Windows, and Enter or a tap toggles it.
		const isMouse = finePointer.matches && event.detail > 0 && event.pointerType !== 'touch';

		if (button.getAttribute('aria-expanded') === 'true' && !isMouse) {
			setSubmenu(button, false);
		} else {
			openSubmenu(button);
		}
	});
}

// Only a real move of the mouse counts, as the browser also reports the pointer over an item when the page scrolls under it.
startMenu.addEventListener('pointermove', event => {
	const button = event.target.closest('button');

	if (!finePointer.matches || event.pointerType !== 'mouse' || !button || button === hoveredButton) {
		return;
	}

	hoveredButton = button;
	clearTimeout(hoverTimer);
	hoverTimer = setTimeout(() => {
		if (button.dataset.winSubmenu) {
			openSubmenu(button);
		} else {
			for (const sibling of button.closest('ul').querySelectorAll(':scope > li > [data-win-submenu]')) {
				setSubmenu(sibling, false);
			}
		}
	}, 300);
});

startMenu.addEventListener('pointerleave', () => {
	clearTimeout(hoverTimer);
	hoveredButton = undefined;
});

const itemsOfList = list => [...list.children].map(item => item.querySelector(':scope > button')).filter(Boolean);

startMenu.addEventListener('keydown', event => {
	const button = event.target.closest('button');

	if (!button) {
		return;
	}

	const list = button.closest('ul');
	const items = itemsOfList(list);
	const parentButton = list.previousElementSibling?.matches('[data-win-submenu]') ? list.previousElementSibling : undefined;
	const step = {ArrowDown: 1, ArrowUp: -1}[event.key];

	if (step) {
		event.preventDefault();
		items.at((items.indexOf(button) + step) % items.length).focus();
	} else if (event.key === 'Home' || event.key === 'End') {
		event.preventDefault();
		items.at(event.key === 'Home' ? 0 : -1).focus();
	} else if (event.key === 'ArrowRight' && button.dataset.winSubmenu) {
		event.preventDefault();
		openSubmenu(button);
		itemsOfList(button.nextElementSibling)[0].focus();
	} else if ((event.key === 'ArrowLeft' || event.key === 'Escape') && parentButton) {
		// Only the submenu closes, so `geocities.js` does not close the whole menu.
		event.preventDefault();
		event.stopPropagation();
		setSubmenu(parentButton, false);
		parentButton.focus();
	}
});

new MutationObserver(() => {
	if (startMenu.hidden) {
		clearTimeout(hoverTimer);
		hoveredButton = undefined;

		for (const button of submenuButtons) {
			setSubmenu(button, false);
		}
	}
}).observe(startMenu, {attributes: true, attributeFilter: ['hidden']});

// The commands of the Start menu and the menu of the right mouse button. The programs are defined further down.
const commands = {};

desktop.addEventListener('click', event => {
	const button = event.target.closest('[data-win-command]');

	if (button) {
		closeStartMenu();
		commands[button.dataset.winCommand](button);
	}
});

// The icons of the desktop. With a mouse, they can be dragged anywhere on the desktop, and Arrange Icons puts them back in rows.
const iconTemplate = document.querySelector('#geocities-win-icon-template');
const iconOffsets = new WeakMap();
let suppressClick = false;

const iconItems = () => [...iconList.children];
const iconName = item => item.querySelector('span:last-child').textContent;
const iconPicture = item => item.querySelector('span');

const placeIcon = (item, x, y) => {
	iconOffsets.set(item, {x, y});
	item.style.translate = x || y ? `${x}px ${y}px` : '';
};

// A click always comes before the next press, so a press forgets a click that never came, like after a long press on Android.
desktop.addEventListener('pointerdown', () => {
	suppressClick = false;
}, {capture: true});

// A drag that ends on an icon would also click it, which would open it.
desktop.addEventListener('click', event => {
	if (suppressClick) {
		event.stopPropagation();
		event.preventDefault();
		suppressClick = false;
	}
}, {capture: true});

iconList.addEventListener('pointerdown', event => {
	const item = event.target.closest('li');

	if (!item || event.button !== 0 || event.pointerType === 'touch') {
		return;
	}

	const start = {x: event.clientX, y: event.clientY, offset: iconOffsets.get(item) ?? {x: 0, y: 0}};
	const button = item.querySelector('button');
	let isDragging = false;

	const move = moveEvent => {
		const dx = moveEvent.clientX - start.x;
		const dy = moveEvent.clientY - start.y;

		if (!isDragging && Math.hypot(dx, dy) < 6) {
			return;
		}

		isDragging = true;
		// Keeps the icon on the desktop, above the taskbar.
		const desktopBox = desktop.getBoundingClientRect();
		const box = item.getBoundingClientRect();
		const left = box.left - (iconOffsets.get(item)?.x ?? 0) + start.offset.x;
		const top = box.top - (iconOffsets.get(item)?.y ?? 0) + start.offset.y;
		const x = clamp(start.offset.x + dx, start.offset.x - (left - desktopBox.left), start.offset.x + (desktopBox.right - box.width - left));
		const y = clamp(start.offset.y + dy, start.offset.y - (top - desktopBox.top), start.offset.y + (desktopBox.bottom - taskbar.offsetHeight - box.height - top));
		placeIcon(item, x, y);
	};

	const end = endEvent => {
		button.removeEventListener('pointermove', move);
		suppressClick = isDragging;

		// An icon that is dropped on the Recycle Bin goes in it, like in Windows.
		const bin = recycleIcon();

		if (isDragging && endEvent.type === 'pointerup' && item !== bin) {
			const box = bin.getBoundingClientRect();

			if (endEvent.clientX >= box.left && endEvent.clientX <= box.right && endEvent.clientY >= box.top && endEvent.clientY <= box.bottom) {
				placeIcon(item, start.offset.x, start.offset.y);
				deleteIcon(item);
			}
		}
	};

	button.setPointerCapture(event.pointerId);
	button.addEventListener('pointermove', move);
	button.addEventListener('pointerup', end, {once: true});
	button.addEventListener('pointercancel', end, {once: true});
});

const arrangeIcons = () => {
	const items = iconItems().sort((first, second) => iconName(first).localeCompare(iconName(second), 'en'));

	for (const item of items) {
		placeIcon(item, 0, 0);
		item.style.rotate = '';
	}

	// Moving the icons takes the focus from the icon that had it, which gets it back.
	const focused = document.activeElement;
	iconList.append(...items);

	if (iconList.contains(focused)) {
		focused.focus();
	}
};

// Deleted icons go to the Recycle Bin of `geocities.js`, with a Restore button. Emptying the bin deletes them for good.
const recycleList = document.querySelector('#geocities-recycle-list');
const recycleEmpty = document.querySelector('#geocities-recycle-empty');
const restoreTemplate = document.querySelector('#geocities-win-restore-template');
const undeletable = {
	recycle: 'The Recycle Bin cannot be deleted. Where would it go?',
	computer: 'You cannot delete My Computer. It is your computer.',
};

const deleteIcon = async item => {
	const name = iconName(item);
	const app = item.querySelector('button').dataset.desktopOpen;

	if (undeletable[app]) {
		await ask({title: 'Error Deleting File', icon: '❌', text: undeletable[app]});
		return;
	}

	const answer = await ask({title: 'Confirm File Delete', icon: '🗑️', text: `Are you sure you want to send “${name}” to the Recycle Bin?`, buttons: ['Yes', 'No']});

	if (answer !== 'Yes') {
		return;
	}

	const next = iconItems().filter(other => !other.hidden && other !== item).at(Math.max(iconItems().indexOf(item) - 1, 0));
	item.hidden = true;
	next?.querySelector('button').focus();
	const entry = fromTemplate(restoreTemplate);
	entry.querySelector('strong').textContent = name;

	entry.querySelector('button').addEventListener('click', () => {
		entry.remove();
		item.hidden = false;
		item.querySelector('button').focus();
	});

	recycleList.append(entry);
	recycleEmpty.disabled = false;
	playSound('ding');
};

// New folders get the next number, starting where my last one left off.
let folderNumber = 37;

commands['new-folder'] = () => {
	const item = fromTemplate(iconTemplate);
	const name = `New Folder (${folderNumber++})`;
	iconPicture(item).textContent = '📁';
	item.querySelector('span:last-child').textContent = name;

	item.querySelector('button').addEventListener('click', event => {
		openFolder(name, [], event.currentTarget);
	});

	iconList.append(item);
	item.querySelector('button').focus();
};

commands.arrange = arrangeIcons;

// Refresh makes the icons blink, which is all that it ever did, but everybody pressed it all the time.
commands.refresh = async () => {
	iconList.style.visibility = 'hidden';
	await wait(250);
	iconList.style.visibility = '';
};

// The menu of the right mouse button. On a phone, a finger that rests on the desktop opens it, and the menu key or Shift+F10 opens it from the keyboard.
const contextMenu = document.querySelector('#geocities-win-context-menu');
const contextItems = [...contextMenu.querySelectorAll('[data-win-context-command]')];
let contextIcon;
let contextOpener;

const closeContextMenu = ({restoreFocus = false} = {}) => {
	if (contextMenu.hidden) {
		return;
	}

	contextMenu.hidden = true;

	if (restoreFocus) {
		contextOpener?.focus();
	}
};

const openContextMenu = (x, y, item, opener) => {
	contextIcon = item;
	contextOpener = opener;

	for (const button of contextItems) {
		button.hidden = button.dataset.winContextTarget === 'icon' && !item;

		if (button.dataset.winContextCommand === 'web') {
			button.textContent = `${desktop.hasAttribute('data-win-web') ? '✓ ' : ''}Active Desktop: View as Web Page`;
		}
	}

	contextMenu.hidden = false;
	const box = desktop.getBoundingClientRect();
	contextMenu.style.left = `${clamp(x - box.left, 0, Math.max(desktop.clientWidth - contextMenu.offsetWidth, 0))}px`;
	contextMenu.style.top = `${clamp(y - box.top, 0, Math.max(desktop.clientHeight - contextMenu.offsetHeight - taskbar.offsetHeight, 0))}px`;
	contextItems.find(button => !button.hidden).focus();
};

// The desktop itself is the space around the icons and the layer behind them, not the windows or the taskbar.
const isDesktopBackground = target => target === desktop || target === iconList || iconList.contains(target) || target.closest('#geocities-win-layer');

desktop.addEventListener('contextmenu', event => {
	if (!isDesktopBackground(event.target)) {
		return;
	}

	event.preventDefault();
	const item = event.target.closest('li');
	openContextMenu(event.clientX, event.clientY, iconList.contains(item) ? item : undefined, item?.querySelector('button') ?? startButton);
});

let longPress;

desktop.addEventListener('pointerdown', event => {
	if (event.pointerType !== 'touch' || !isDesktopBackground(event.target)) {
		return;
	}

	const item = event.target.closest('li');
	const start = {x: event.clientX, y: event.clientY};

	longPress = {
		start,
		timer: setTimeout(() => {
			longPress = undefined;
			suppressClick = true;
			openContextMenu(start.x, start.y, iconList.contains(item) ? item : undefined, item?.querySelector('button') ?? startButton);
		}, 600),
	};
});

for (const type of ['pointerup', 'pointercancel', 'pointermove']) {
	desktop.addEventListener(type, event => {
		if (longPress && (type !== 'pointermove' || Math.hypot(event.clientX - longPress.start.x, event.clientY - longPress.start.y) > 10)) {
			clearTimeout(longPress.timer);
			longPress = undefined;
		}
	});
}

iconList.addEventListener('keydown', event => {
	const item = event.target.closest('li');

	// Ctrl+Alt+Del is for Close Program, not for deleting the icon.
	if (!item || event.ctrlKey || event.altKey || event.metaKey) {
		return;
	}

	if (event.key === 'ContextMenu' || (event.shiftKey && event.key === 'F10')) {
		event.preventDefault();
		const box = item.getBoundingClientRect();
		openContextMenu(box.left + (box.width / 2), box.top + (box.height / 2), item, event.target);
	} else if (event.key === 'Delete') {
		event.preventDefault();
		deleteIcon(item);
	}
});

contextMenu.addEventListener('keydown', event => {
	const items = contextItems.filter(button => !button.hidden);
	const step = {ArrowDown: 1, ArrowUp: -1}[event.key];

	if (step) {
		event.preventDefault();
		items.at((items.indexOf(document.activeElement) + step) % items.length).focus();
	} else if (event.key === 'Escape') {
		event.preventDefault();
		event.stopPropagation();
		closeContextMenu({restoreFocus: true});
	} else if (event.key === 'Tab') {
		closeContextMenu();
	}
});

document.addEventListener('pointerdown', event => {
	if (!contextMenu.contains(event.target)) {
		closeContextMenu();
	}
});

const contextCommands = {
	open() {
		contextIcon.querySelector('button').click();
	},
	delete() {
		deleteIcon(contextIcon);
	},
	properties() {
		openControlPane('display', contextOpener);
	},
};

for (const button of contextItems) {
	button.addEventListener('click', () => {
		const command = button.dataset.winContextCommand;
		closeContextMenu({restoreFocus: true});
		(contextCommands[command] ?? commands[command])(contextOpener);
	});
}

// Notepad shows the text files of My Documents, the network, and the mail.
const viewerText = document.querySelector('#geocities-win-viewer-text');

const openText = (name, text, opener) => {
	setTitle('viewer', `${name} - Notepad`);
	viewerText.value = text;
	viewerText.scrollTop = 0;
	openWindow('viewer', opener);
};

const texts = {
	readme: `README.TXT

Welcome to my computer!

RULES:
1. Do not open SECRET.TXT.
2. Do not delete my GIFs.
3. Do not run Y2K FIX.EXE. I paid 49 kroner for it, and I think it is broken.
4. If the computer stops responding, press Ctrl+Alt+Del. If it still does not respond, press it again. If it STILL does not respond, call Pappa.
5. Do not change the colors to Hot Dog Stand. I mean it.

Have fun!
Sindre`,
	shopping: `HANDLELISTE (the shopping list)

- Brunost (2 kg)
- Milk
- Waffle mix
- Batteries for the Furby (NO! Do NOT buy batteries for the Furby.)
- Water and candles for Y2K (Sindre insists)
- Something nice for Mormor`,
	waffles: `VAFLER (waffles, for 8 hearts)

5 dl flour
5 dl milk
4 eggs
1 dl sugar
1 teaspoon cardamom
100 g melted butter

Let the batter rest for 30 minutes. Serve with brunost and jam.

Do NOT tell Sindre where the brunost is hidden.`,
	sisterDiary: `KJÆRE DAGBOK (dear diary)

Sindre thinks I cannot read his SECRET.TXT. His password is SO easy. It is his favorite food. Everybody knows his favorite food. He talks about it ALL THE TIME.

He also does not know that I know that his stuffed unicorn is called Glitter Jr.

PS: If you are Sindre and you are reading this: MAMMA!!!`,
	sisterList: `REASONS WHY MY BIG BROTHER IS WEIRD

1. He says tabs are better than spaces. What is a tab?
2. He talks to his computer.
3. He made a home page about unicorns. Who does that?
4. He is on the phone line ALL the time, and I cannot call Ingrid.

OK, he is a little bit nice. He showed me Snake.`,
	gotcha: `Ha ha. Made you look.

- Lillesøster`,
	mailMom: `From: Mamma
To: Sindre
Subject: MIDDAG!!!

Sindre, dinner is ready. It has been ready for 20 minutes.

I am sending this from Pappa's computer in the living room, because you do not hear me when I call.

Come down NOW. It is fish cakes.

PS: Get off the Internet. I need to call Mormor.

Mamma`,
	mailSister: `From: Lillesøster
To: Sindre
Subject: I KNOW YOUR PASSWORD

Pay me 10 kroner, or I tell everyone your password.

Hint: it starts with W and it goes with brunost.

PS: I also used your modem time. All of it.`,
	autoexec: `@ECHO OFF
SET BLASTER=A220 I5 D1 T4
SET PATH=C:\\WINDOWS;C:\\WINDOWS\\COMMAND;C:\\GAMES
REM Do not touch this file. It took me 3 days to make DOOM work.
LH C:\\WINDOWS\\COMMAND\\MSCDEX.EXE /D:CD001
LH C:\\MOUSE\\MOUSE.COM
ECHO Welcome to Sindre's computer!`,
};

// Calculator. It calculates for real, one step at a time like the Calculator of Windows, except for the famous bugs of the time.
const calcDisplay = document.querySelector('#geocities-win-calc-display');
const calcMemory = document.querySelector('#geocities-win-calc-memory');
const calcStatus = document.querySelector('#geocities-win-calc-status');
const calcFlip = document.querySelector('#geocities-win-calc-flip');
const calc = {entry: '0', stored: undefined, operator: undefined, isFresh: true, memory: 0};

// Shows a number like Windows, with the point at the end of a whole number, and at most 16 digits.
const formatNumber = number => {
	const text = String(Number(number.toPrecision(15)));
	return text.includes('.') || text.includes('e') ? text : `${text}.`;
};

const showCalc = text => {
	calcDisplay.textContent = text ?? (calc.entry.includes('.') ? calc.entry : `${calc.entry}.`);
};

const calcError = (text, status) => {
	calc.entry = '0';
	calc.stored = undefined;
	calc.operator = undefined;
	calc.isFresh = true;
	showCalc(text);
	announce(calcStatus, status ?? text);
};

// The bugs of the time, which Calculator remembers, by the numbers and the operator.
const calculatorJokes = [
	{
		matches: (first, operator, second) => first === 2 && operator === '+' && second === 2,
		result: 'Error: Y2K',
		status: '2 + 2 = Error: Y2K. Calculator is not ready for the year 2000. Or for 4.',
	},
	{
		matches: (first, operator, second) => first === 1999 && operator === '+' && second === 1,
		result: '19100.',
		status: '1999 + 1 = 19100, like the year on many web pages on January 1, 2000. They added 1900 to 100.',
	},
	{
		matches: (first, operator, second) => first === 3.11 && operator === '-' && second === 3.1,
		result: '0.00',
		status: '3.11 − 3.1 = 0.00, like the Calculator of Windows 3.1. Close enough!',
	},
	{
		matches: (first, operator, second) => first === 4_195_835 && operator === '/' && second === 3_145_727,
		result: '1.333739068902037589',
		status: 'Pentium inside! The first Pentium got this wrong in 1994. The right answer is 1.333820449136241.',
	},
];

const compute = () => {
	const first = calc.stored;
	const second = Number(calc.entry);
	const joke = calculatorJokes.find(joke => joke.matches(first, calc.operator, second));

	if (joke) {
		calc.entry = '0';
		calc.operator = undefined;
		calc.isFresh = true;
		showCalc(joke.result);
		announce(calcStatus, joke.status);
		return false;
	}

	if (calc.operator === '/' && second === 0) {
		calcError('Cannot divide by zero.');
		return false;
	}

	const result = {
		'+': first + second,
		'-': first - second,
		'*': first * second,
		'/': first / second,
	}[calc.operator];

	calc.entry = String(Number(result.toPrecision(15)));
	showCalc(formatNumber(result));
	return true;
};

const pressCalcKey = key => {
	if (/^\d$/.test(key) || key === '.') {
		if (calc.isFresh) {
			calc.entry = '0';
			calc.isFresh = false;
		}

		if (key === '.' && calc.entry.includes('.')) {
			return;
		}

		if (calc.entry.replace(/\D/g, '').length >= 16) {
			return;
		}

		calc.entry = calc.entry === '0' && key !== '.' ? key : calc.entry + key;
		showCalc();
		return;
	}

	if (['+', '-', '*', '/'].includes(key)) {
		if (calc.operator && !calc.isFresh && !compute()) {
			return;
		}

		calc.stored = Number(calc.entry);
		calc.operator = key;
		calc.isFresh = true;
		return;
	}

	const number = Number(calc.entry);

	switch (key) {
		case '=': {
			if (calc.operator && compute()) {
				calc.operator = undefined;
				calc.isFresh = true;
			}

			break;
		}

		case 'sqrt': {
			if (number < 0) {
				calcError('Invalid input for function.');
			} else {
				calc.entry = String(Math.sqrt(number));
				calc.isFresh = true;
				showCalc(formatNumber(Math.sqrt(number)));
			}

			break;
		}

		case '1/x': {
			if (number === 0) {
				calcError('Cannot divide by zero.');
			} else {
				calc.entry = String(1 / number);
				calc.isFresh = true;
				showCalc(formatNumber(1 / number));
			}

			break;
		}

		case '%': {
			const percent = (calc.stored ?? 0) * number / 100;
			calc.entry = String(percent);
			showCalc(formatNumber(percent));
			break;
		}

		case '+/-': {
			calc.entry = calc.entry.startsWith('-') ? calc.entry.slice(1) : (calc.entry === '0' ? '0' : `-${calc.entry}`);
			showCalc();
			break;
		}

		case 'Backspace': {
			if (!calc.isFresh) {
				calc.entry = calc.entry.length > 1 ? calc.entry.slice(0, -1) : '0';
				showCalc();
			}

			break;
		}

		case 'CE': {
			calc.entry = '0';
			showCalc();
			break;
		}

		case 'C': {
			calcError('0.', 'Cleared.');
			break;
		}

		case 'MC': {
			calc.memory = 0;
			break;
		}

		case 'MR': {
			calc.entry = String(calc.memory);
			calc.isFresh = true;
			showCalc(formatNumber(calc.memory));
			break;
		}

		case 'MS': {
			calc.memory = number;
			calc.isFresh = true;
			break;
		}

		case 'M+': {
			calc.memory += number;
			calc.isFresh = true;
			break;
		}

		default:
	}

	calcMemory.textContent = calc.memory ? 'M' : '';
};

for (const button of document.querySelectorAll('[data-win-calc-key]')) {
	button.addEventListener('click', () => {
		pressCalcKey(button.dataset.winCalcKey);
	});
}

// The keys of the keyboard, like in Calculator: @ is the square root, and Delete clears the entry.
windowOf('calc').addEventListener('keydown', event => {
	// Shortcuts of the browser, like reload and copy, stay with the browser.
	if (event.ctrlKey || event.metaKey || event.altKey) {
		return;
	}

	if (event.target.closest('button') && (event.key === 'Enter' || event.key === ' ')) {
		return;
	}

	const key = {Enter: '=', Delete: 'CE', '@': 'sqrt', r: '1/x', c: 'C', Backspace: 'Backspace'}[event.key] ?? event.key;

	if (/^[\d.+\-*/=%]$/.test(key) || ['sqrt', '1/x', 'CE', 'C', 'Backspace'].includes(key)) {
		event.preventDefault();
		pressCalcKey(key);
	}
});

// Upside down, the digits of a calculator read as letters, like 0.7734, which says hELLO.
const upsideDownLetters = {0: 'O', 1: 'I', 2: 'Z', 3: 'E', 4: 'h', 5: 'S', 6: 'g', 7: 'L', 8: 'B', 9: 'G', '.': ''};

calcFlip.addEventListener('click', () => {
	const isFlipped = !calcDisplay.hasAttribute('data-win-flipped');
	calcFlip.setAttribute('aria-pressed', String(isFlipped));

	if (!isFlipped) {
		delete calcDisplay.dataset.winFlipped;
		announce(calcStatus, 'The right way up again.');
		return;
	}

	calcDisplay.dataset.winFlipped = '';
	const word = [...calcDisplay.textContent].reverse().map(character => upsideDownLetters[character] ?? '').join('');

	if (/^0?\.?7734\.?$/.test(calcDisplay.textContent) || word === 'hELLO') {
		announce(calcStatus, 'Upside down, it says hELLO! Every kid at school knew this one.');
	} else if (word.replace(/O/g, '') === '') {
		announce(calcStatus, 'Upside down, it says nothing. Try 0.7734.');
	} else {
		announce(calcStatus, `Upside down, it says ${word}. Try 0.7734.`);
	}
});

// The MS-DOS Prompt, with the folders of my hard drive, and the commands of DOS. The spaces are no-break spaces, so the columns of DIR line up.
const dosOutput = document.querySelector('#geocities-win-dos-output');
const dosForm = document.querySelector('#geocities-win-dos-form');
const dosPrompt = document.querySelector('#geocities-win-dos-prompt');
const dosInput = document.querySelector('#geocities-win-dos-input');

const dosFolders = {
	'C:\\': {
		folders: ['WINDOWS', 'MYDOCU~1', 'GAMES', 'HOMEWORK'],
		files: [['AUTOEXEC.BAT', 412], ['CONFIG.SYS', 251], ['COMMAND.COM', 93_890], ['SECRET.TXT', 1999]],
	},
	'C:\\WINDOWS': {
		folders: ['SYSTEM', 'COMMAND', 'DESKTOP', 'FONTS'],
		files: [['WIN.COM', 24_791], ['EXPLORER.EXE', 204_288], ['CALC.EXE', 59_392], ['NOTEPAD.EXE', 53_248], ['SOL.EXE', 36_864], ['FREECELL.EXE', 37_888], ['UNICORN.DLL', 1999], ['CLOUDS.BMP', 307_514]],
	},
	'C:\\WINDOWS\\SYSTEM': {
		folders: [],
		files: [['KERNEL32.DLL', 471_040], ['USER.EXE', 80_208], ['GLITTER.VXD', 1999], ['Y2KBUG.DLL', 2000]],
	},
	'C:\\WINDOWS\\COMMAND': {
		folders: [],
		files: [['FORMAT.COM', 49_543], ['DELTREE.EXE', 19_083], ['SCANDISK.EXE', 250_000]],
	},
	'C:\\WINDOWS\\DESKTOP': {
		folders: [],
		files: [['LETTER~1.DOC', 2000], ['Y2KFIX.EXE', 666_666]],
	},
	'C:\\WINDOWS\\FONTS': {
		folders: [],
		files: [['COMIC.TTF', 126_364], ['WINGDING.TTF', 71_100], ['TIMES.TTF', 327_244]],
	},
	'C:\\MYDOCU~1': {
		folders: ['PRIVATE'],
		files: [['README.TXT', 512], ['HOMEWORK.DOC', 0], ['DANCIN~1.AVI', 1_048_576], ['TADA.WAV', 27_804]],
	},
	'C:\\MYDOCU~1\\PRIVATE': {
		folders: [],
		files: [['NOTHING.TXT', 0]],
	},
	'C:\\GAMES': {
		folders: [],
		files: [['DOOM2.EXE', 709_905], ['KEEN4.EXE', 105_000], ['SKIFREE.EXE', 118_784], ['PINBALL.EXE', 351_744]],
	},
	'C:\\HOMEWORK': {
		folders: [],
		files: [],
	},
};

const dosHelp = `Commands I know:
CD       Changes the folder. CD.. goes up.
CLS      Clears the screen.
DATE     Shows or sets the date.
DIR      Lists the files.
EDIT     Edits a file.
FORMAT   Formats a disk. Do not.
MEM      Shows the memory.
TREE     Shows the folders.
TYPE     Shows the text of a file.
VER      Shows the version of Windows.
WIN      Starts Windows.
EXIT     Closes the MS-DOS Prompt.
A:       Uses the floppy drive.
And the names of programs, like CALC, SOL, or FREECELL.`;

let dosFolder = 'C:\\WINDOWS';
// A question waits for its answer, like “Abort, Retry, Fail?”.
let dosQuestion;
const dosHistory = [];
let dosHistoryIndex = 0;

const dosPrint = text => {
	dosOutput.append(`${text.replaceAll(' ', '\u00A0')}\n`);

	// Keeps the last lines, like a screen of DOS.
	while (dosOutput.textContent.length > 6000) {
		dosOutput.firstChild.remove();
	}

	dosOutput.scrollTop = dosOutput.scrollHeight;
};

const setDosPrompt = text => {
	dosPrompt.textContent = text ?? `${dosFolder}>`;
};

const dosName = (name, size) => {
	const [base, extension = ''] = name.split('.');
	const sizeText = size === undefined ? '<DIR>' : size.toLocaleString('en-US');
	return `${base.padEnd(8)} ${extension.padEnd(3)} ${sizeText.padStart(12)}  12-31-99  11:59p`;
};

const dosPrograms = {
	calc: 'calc',
	notepad: 'viewer',
	sol: 'solitaire',
	freecell: 'freecell',
	winmine: 'sweeper',
	mspaint: 'paint',
	pbrush: 'paint',
	wordpad: 'wordpad',
	write: 'wordpad',
	iexplore: 'ie',
	control: 'control',
	explorer: 'documents',
	sndrec32: 'sound',
	dialer: 'dialup',
	y2kfix: 'fixer',
};

const runDosCommand = line => {
	const [command = '', ...rest] = line.trim().split(/\s+/);
	const argument = rest.join(' ');
	const name = command.toLowerCase();

	if (dosQuestion) {
		const question = dosQuestion;
		dosQuestion = undefined;
		question(line.trim().toLowerCase());
		return;
	}

	if (name === '') {
		return;
	}

	// DOS also takes CD.. and CD\ without a space.
	if (name === 'cd..' || (name === 'cd' && argument === '..')) {
		const parent = dosFolder.slice(0, dosFolder.lastIndexOf('\\'));
		dosFolder = parent === 'C:' || parent === '' ? 'C:\\' : parent;
		setDosPrompt();
		return;
	}

	if (name === 'cd\\') {
		dosFolder = 'C:\\';
		setDosPrompt();
		return;
	}

	switch (name) {
		case 'help': {
			dosPrint(dosHelp);
			break;
		}

		case 'cls': {
			dosOutput.textContent = '';
			break;
		}

		case 'ver': {
			dosPrint('\nWindows 98 [Version 4.10.2222]\n');
			break;
		}

		case 'echo': {
			dosPrint(argument.toLowerCase() === 'off' ? 'ECHO is off. (It was always off.)' : (argument || 'ECHO is on'));
			break;
		}

		case 'dir': {
			const folder = dosFolders[dosFolder];
			let size = 0;

			for (const [, bytes] of folder.files) {
				size += bytes;
			}

			dosPrint([
				'',
				' Volume in drive C is SINDRE_98',
				' Volume Serial Number is 1999-1231',
				` Directory of ${dosFolder}`,
				'',
				...(dosFolder === 'C:\\' ? [] : [dosName('.'), dosName('..')]),
				...folder.folders.map(name => dosName(name)),
				...folder.files.map(([name, bytes]) => dosName(name, bytes)),
				`${String(folder.files.length).padStart(9)} file(s) ${size.toLocaleString('en-US').padStart(14)} bytes`,
				`${String(folder.folders.length).padStart(9)} dir(s)  ${(1_999_999).toLocaleString('en-US').padStart(14)} bytes free`,
				'',
			].join('\n'));
			break;
		}

		case 'cd':
		case 'chdir': {
			if (!argument) {
				dosPrint(dosFolder);
				break;
			}

			const target = argument.toUpperCase().replace(/^C:/, '').replace(/(.)\\+$/, '$1');
			let path;

			if (target === '' || target === '\\') {
				path = 'C:\\';
			} else if (target.startsWith('\\')) {
				path = `C:${target}`;
			} else {
				path = dosFolder === 'C:\\' ? `C:\\${target}` : `${dosFolder}\\${target}`;
			}

			if (dosFolders[path]) {
				dosFolder = path;
				setDosPrompt();
			} else {
				dosPrint('Invalid directory');
			}

			break;
		}

		case 'tree': {
			dosPrint(`Directory PATH listing for Volume SINDRE_98
C:.
├───WINDOWS
│   ├───SYSTEM
│   ├───COMMAND
│   ├───DESKTOP
│   └───FONTS
├───MYDOCU~1
│   └───PRIVATE
├───GAMES
└───HOMEWORK (empty, like always)`);
			break;
		}

		case 'mem': {
			dosPrint(`
Memory Type        Total  =   Used  +   Free
----------------  -------   -------   -------
Conventional         640K       87K      553K
Upper                155K      155K        0K
Extended (XMS)    31,972K    31,972K       0K
----------------  -------   -------   -------
Total memory      32,767K    32,214K     553K

640K ought to be enough for anybody.
(Bill Gates says that he never said that.)`);
			break;
		}

		case 'date': {
			dosPrint('Current date is Fri 12-31-1999\nEnter new date (mm-dd-yy):');
			dosQuestion = answer => {
				if (/\D(00|2000)$/.test(answer) || answer.endsWith('00')) {
					dosPrint('Current date is Mon 01-01-1900\nOops. That is 100 years too early. Y2K!');
				} else if (answer) {
					dosPrint('Nice try. On this page, it is always 1999.');
				}
			};

			break;
		}

		case 'time': {
			dosPrint(`Current time is ${new Date().toLocaleTimeString('en-US')}\nEnter new time:`);
			dosQuestion = () => {
				dosPrint('Time is an illusion. Lunch time doubly so.');
			};

			break;
		}

		case 'type':
		case 'edit': {
			const file = argument.toUpperCase();

			if (!file) {
				dosPrint('Required parameter missing');
			} else if (file === 'AUTOEXEC.BAT') {
				if (name === 'edit') {
					openText('AUTOEXEC.BAT', texts.autoexec, dosInput);
				} else {
					dosPrint(texts.autoexec);
				}
			} else if (file === 'README.TXT') {
				if (name === 'edit') {
					openText('README.TXT', texts.readme, dosInput);
				} else {
					dosPrint(texts.readme);
				}
			} else if (file === 'SECRET.TXT') {
				dosPrint('Access denied. Nice try, little sister.');
			} else if (dosFolders[dosFolder].files.some(([fileName]) => fileName === file)) {
				dosPrint('ÿØÿà JFIF ☺☻♥♦ (this is not a text file)');
			} else {
				dosPrint('File not found');
			}

			break;
		}

		case 'win': {
			if (isDosMode) {
				dosPrint('Starting Windows 98…');
				closeWindow('dos');
			} else {
				dosPrint('Windows is already running. You are in it. Look up.');
			}

			break;
		}

		case 'exit': {
			closeWindow('dos');
			break;
		}

		case 'format': {
			dosPrint(`\nWARNING, ALL DATA ON NON-REMOVABLE DISK\nDRIVE ${(argument || 'C:').toUpperCase()} WILL BE LOST!\nProceed with Format (Y/N)?`);
			dosQuestion = async answer => {
				if (answer !== 'y') {
					dosPrint('Phew.');
					return;
				}

				setEnabled(dosInput, false);

				for (const percent of [1, 2, 3, 4]) {
					dosPrint(`Formatting 4,095.98M\n${percent} percent completed.`);
					await wait(700);
				}

				dosPrint('Format terminated. The unicorns refused to be formatted.');
				setEnabled(dosInput, true);
			};

			break;
		}

		case 'deltree':
		case 'del': {
			if (!argument) {
				dosPrint('Required parameter missing');
				break;
			}

			dosPrint(`Delete directory "${argument}" and all its subdirectories? [yn]`);
			dosQuestion = answer => {
				dosPrint(answer === 'y' ? `Deleting ${argument}...\nJust kidding. Pappa made me promise.` : 'OK. Nothing was deleted.');
			};

			break;
		}

		case 'ping': {
			if (dialUp.state === 'connected') {
				dosPrint(`Pinging ${argument || 'www.unicorns.no'} with 32 bytes of data:\n\nReply from 195.1.99.9: bytes=32 time=1999ms TTL=99\nReply from 195.1.99.9: bytes=32 time=2000ms TTL=99\n\n28.8 kbps. Fast!`);
			} else {
				dosPrint(`Pinging ${argument || 'www.unicorns.no'} with 32 bytes of data:\n\nRequest timed out.\nRequest timed out.\n\nIs Dial-Up Networking connected?`);
			}

			break;
		}

		case 'a:': {
			dosPrint('\nNot ready reading drive A\nAbort, Retry, Fail?');
			setDosPrompt('Abort, Retry, Fail?');
			const askFloppy = answer => {
				if (answer === 'r') {
					dosPrint('\nNot ready reading drive A\nAbort, Retry, Fail?');
					dosQuestion = askFloppy;
				} else if (answer === 'f') {
					dosPrint('Current drive is no longer valid. Type C: to go back.');
					setDosPrompt('Current drive is no longer valid>');
					dosFolder = 'C:\\';
				} else if (answer === 'a') {
					setDosPrompt();
				} else {
					dosPrint('Abort, Retry, Fail?');
					dosQuestion = askFloppy;
				}
			};

			dosQuestion = askFloppy;
			break;
		}

		case 'c:': {
			setDosPrompt();
			break;
		}

		case 'scandisk': {
			dosPrint('ScanDisk is checking drive C:\n\nScanDisk found 1,999 lost clusters. They were all GIFs. They are safe now.');
			break;
		}

		default: {
			const programName = name.replace(/\.exe$/, '');
			const program = Object.hasOwn(dosPrograms, programName) ? dosPrograms[programName] : undefined;

			if (program === 'viewer') {
				openText('Untitled', '', dosInput);
			} else if (program) {
				openWindow(program, dosInput);
			} else if (['doom', 'doom2', 'keen4', 'skifree', 'pinball'].includes(name.replace(/\.exe$/, ''))) {
				dosPrint('This program cannot be run in MS-DOS mode. Ask Pappa to restart in MS-DOS mode. He will say no.');
			} else {
				dosPrint('Bad command or file name');
			}
		}
	}
};

dosForm.addEventListener('submit', event => {
	event.preventDefault();
	const line = dosInput.value;
	dosPrint(`${dosPrompt.textContent}${line}`);
	dosInput.value = '';

	if (line.trim()) {
		dosHistory.push(line);
		dosHistoryIndex = dosHistory.length;
	}

	runDosCommand(line);
});

// The up and down arrows go back to the commands before, like DOSKEY.
dosInput.addEventListener('keydown', event => {
	const step = {ArrowUp: -1, ArrowDown: 1}[event.key];

	if (step && dosHistory.length > 0) {
		event.preventDefault();
		dosHistoryIndex = clamp(dosHistoryIndex + step, 0, dosHistory.length);
		dosInput.value = dosHistory[dosHistoryIndex] ?? '';
	}
});

onOpen.dos = () => {
	dosInput.focus();
};

// Closing the window ends a question, like “Abort, Retry, Fail?”, so the first command after it opens again is a command, not an answer.
onClose.dos = () => {
	dosQuestion = undefined;
	setDosPrompt();

	// Leaving MS-DOS mode starts Windows again.
	if (isDosMode) {
		restart();
	}
};

// The Run dialog runs programs by their names, and the commands that everybody knew.
const runForm = document.querySelector('#geocities-win-run-form');
const runInput = document.querySelector('#geocities-win-run-input');

const runCommands = {
	command: 'dos',
	cmd: 'dos',
	winver: () => ask({title: 'About Windows', icon: '🪟', text: 'Microsoft® Windows 98\nVersion 4.10.2222 A\nCopyright © 1981-1999 Microsoft Corp.\n\nThis product is licensed to:\nSindre, Bergen\n\nPhysical memory available to Windows: 32,768 KB\nSystem resources: 1999% free'}),
	regedit: () => ask({title: 'Registry Editor', icon: '🗃️', text: 'HKEY_LOCAL_MACHINE\\Software\\Sindre\\Unicorns\n\n(Default)    "1999"\nFavoriteFood  "you wish"\n\nPappa says if I touch the registry again, the computer goes in the basement.'}),
	ssmaze: () => startSaver('maze', runInput),
	scandisk: 'scandisk',
	cleanmgr: 'cleanup',
	winzip32: 'winzip',
	bob: 'bob',
	pinball: 'pinball',
	defrag: 'computer',
	'format c:': () => ask({title: 'Format', icon: '❌', text: 'Windows cannot format drive C:, because Windows is on it. And all my GIFs. Nice try.'}),
	'rundll32 user.exe,exitwindows': () => {
		document.querySelector('#geocities-shut-down').click();
	},
};

runForm.addEventListener('submit', async event => {
	event.preventDefault();
	const text = runInput.value.trim();
	const command = text.toLowerCase();

	if (!command) {
		return;
	}

	const program = command.replace(/\.exe$/, '');
	const action = (Object.hasOwn(runCommands, command) ? runCommands[command] : undefined) ?? (Object.hasOwn(dosPrograms, program) ? dosPrograms[program] : undefined);
	const opener = document.querySelector('[data-desktop-open="run"]');
	closeWindow('run');

	if (typeof action === 'function') {
		action();
	} else if (action === 'viewer') {
		openText('Untitled', '', opener);
	} else if (action) {
		openWindow(action, opener);
	} else if (/^(https?:\/\/|www\.)|\.(com|no|net|org)\b/.test(command)) {
		openWindow('ie', opener);
		navigate(text);
	} else {
		await ask({title: text, icon: '❌', text: `Cannot find the file '${text}' (or one of its components). Make sure the path and filename are correct and that all required libraries are available.`, opener});
	}
});

document.querySelector('#geocities-win-run-browse').addEventListener('click', () => {
	ask({title: 'Browse', icon: 'ℹ️', text: 'Browse is broken. Type it, like a real hacker.'});
});

onOpen.run = () => {
	runInput.select();
	runInput.focus();
};

// WordPad, with my letter to Santa. The fonts include Wingdings, which turns the letter into symbols, so not even Santa can read it.
const wordpadText = document.querySelector('#geocities-win-wordpad-text');
const wordpadWingdings = document.querySelector('#geocities-win-wordpad-wingdings');
const wordpadFont = document.querySelector('#geocities-win-wordpad-font');
const wordpadSize = document.querySelector('#geocities-win-wordpad-size');
const wordpadStatus = document.querySelector('#geocities-win-wordpad-status');
const fontStacks = {
	'Times New Roman': '"Times New Roman", Times, serif',
	Arial: 'Arial, Helvetica, sans-serif',
	'Comic Sans MS': '"Comic Sans MS", "Comic Sans", "Chalkboard SE", "Comic Neue", cursive',
	'Courier New': '"Courier New", Courier, monospace',
	Wingdings: '"Times New Roman", Times, serif',
};

// The letters of Wingdings, as the symbols that they draw, with the ones that most devices have.
const wingdings = {
	'!': '✎', '"': '✂', '#': '✁', $: '👓', '%': '🔔', '&': '📖', '\'': '🕯', '(': '☎', ')': '✆', '*': '✉', '+': '✉', ',': '📪', '-': '📫', '.': '📬', '/': '📭',
	0: '📁', 1: '📂', 2: '📄', 3: '📄', 4: '📑', 5: '🗄', 6: '⌛', 7: '⌨', 8: '🖱', 9: '🖲', ':': '💻', ';': '💽', '<': '💾', '=': '💾', '>': '✇', '?': '✍', '@': '✍',
	A: '✌', B: '👌', C: '👍', D: '👎', E: '☜', F: '☞', G: '☝', H: '☟', I: '✋', J: '☺', K: '😐', L: '☹', M: '💣', N: '☠', O: '⚐', P: '🚩', Q: '✈', R: '☼', S: '💧', T: '❄', U: '✝', V: '✞', W: '✝', X: '✠', Y: '✡', Z: '☪',
	'[': '☯', '\\': '🕉', ']': '☸', '^': '♈', _: '♉', '`': '♊',
	a: '♋', b: '♌', c: '♍', d: '♎', e: '♏', f: '♐', g: '♑', h: '♒', i: '♓', j: '&', k: '&', l: '●', m: '○', n: '■', o: '□', p: '◻', q: '❑', r: '❒', s: '⬧', t: '⧫', u: '◆', v: '❖', w: '⬥', x: '⌧', y: '⊠', z: '⌘',
};

const showWingdings = () => {
	wordpadWingdings.textContent = [...wordpadText.value].map(character => wingdings[character] ?? character).join('');
};

wordpadFont.addEventListener('change', () => {
	const isWingdings = wordpadFont.value === 'Wingdings';
	wordpadText.style.fontFamily = fontStacks[wordpadFont.value];
	wordpadWingdings.hidden = !isWingdings;
	wordpadText.hidden = isWingdings;

	if (isWingdings) {
		showWingdings();
		announce(wordpadStatus, 'Wingdings! Now not even Santa can read it. Did you know that NYC in Wingdings is ☠✡👍? Pick another font to write again.');
	} else {
		announce(wordpadStatus, `${wordpadFont.value}. ${wordpadFont.value === 'Comic Sans MS' ? 'The best font. Everybody agrees.' : 'Classy.'}`);
	}
});

wordpadSize.addEventListener('change', () => {
	wordpadText.style.fontSize = `${Number(wordpadSize.value) / 12}rem`;
	wordpadWingdings.style.fontSize = wordpadText.style.fontSize;
});

const formatStyles = {
	bold: ['fontWeight', 'bold'],
	italic: ['fontStyle', 'italic'],
	underline: ['textDecoration', 'underline'],
};

for (const button of document.querySelectorAll('[data-win-wordpad-format]')) {
	button.addEventListener('click', () => {
		const isOn = button.getAttribute('aria-pressed') !== 'true';
		const [property, value] = formatStyles[button.dataset.winWordpadFormat];
		button.setAttribute('aria-pressed', String(isOn));

		if (isOn) {
			button.dataset.state = 'on';
		} else {
			delete button.dataset.state;
		}

		wordpadText.style[property] = isOn ? value : '';
		wordpadWingdings.style[property] = wordpadText.style[property];
	});
}

// The Office Assistant pops up a while after WordPad opens, to help with the letter, whether I want it or not. “Don’t show me this tip again” only works the second time.
const assistant = document.querySelector('#geocities-win-assistant');
const assistantText = document.querySelector('#geocities-win-assistant-text');
const assistantChoices = [...document.querySelectorAll('[data-win-assistant-choice]')];
let assistantTimer;
let assistantDismissals = 0;

const showAssistant = (message, {choices = true} = {}) => {
	clearTimeout(assistantTimer);

	if (windowOf('wordpad').hidden) {
		return;
	}

	assistant.hidden = false;

	for (const button of assistantChoices) {
		button.hidden = !choices;
	}

	announce(assistantText, message);
};

const hideAssistant = (after = 0) => {
	clearTimeout(assistantTimer);

	const hide = () => {
		// The focus could be on a choice of the balloon, which goes back to the letter.
		if (assistant.contains(document.activeElement)) {
			(wordpadText.hidden ? wordpadFont : wordpadText).focus();
		}

		assistant.hidden = true;
	};

	if (after) {
		assistantTimer = setTimeout(hide, after);
	} else {
		hide();
	}
};

const assistantLater = (milliseconds, message) => {
	clearTimeout(assistantTimer);
	assistantTimer = setTimeout(() => {
		showAssistant(message);
	}, milliseconds);
};

const assistantActions = {
	help() {
		wordpadText.value = wordpadText.value
			.replace('Dear Santa,', 'To Whom It May Concern at the North Pole,')
			.replace(/Love,\s*\nSindre/, 'Yours faithfully,\nSindre, Esq.');

		if (!wordpadWingdings.hidden) {
			showWingdings();
		}

		showAssistant('There! I made your letter more professional. Santa runs a big business, you know.', {choices: false});
		hideAssistant(6000);
	},
	alone() {
		showAssistant('OK! I will be right here. Watching. 👀', {choices: false});
		hideAssistant(3000);
		assistantLater(25_000, 'Still writing a letter? It looks like you need help. Would you like help?');
	},
	never() {
		assistantDismissals++;

		if (assistantDismissals >= 2) {
			showAssistant('Fine. I will go. You will miss me. (I will be back in Office 2000.)', {choices: false});
			hideAssistant(4000);
			return;
		}

		hideAssistant();
		assistantLater(8000, 'It looks like you are trying to get rid of me. Would you like help with that?');
	},
};

for (const button of assistantChoices) {
	button.addEventListener('click', () => {
		assistantActions[button.dataset.winAssistantChoice]();
	});
}

onOpen.wordpad = () => {
	if (assistantDismissals < 2) {
		assistantLater(3000, 'It looks like you’re writing a letter. Would you like help?');
	}
};

onClose.wordpad = () => {
	clearTimeout(assistantTimer);
	assistant.hidden = true;
};

// Dial-Up Networking calls the Internet over the phone line, unless my little sister is on the phone. The mail comes in when it connects, and somebody always calls the house in the end.
const dialUpConnect = document.querySelector('#geocities-win-dialup-connect');
const dialUpDisconnect = document.querySelector('#geocities-win-dialup-disconnect');
const dialUpStatus = document.querySelector('#geocities-win-dialup-status');
const onlineButton = document.querySelector('#geocities-win-online');
const mailButton = document.querySelector('#geocities-win-mail');
const dialUp = {state: 'idle', attempts: 0, run: 0, onConnect: undefined};
const mails = [['Mamma', texts.mailMom], ['Lillesøster', texts.mailSister]];
let mailIndex = 0;

const setDialUpState = state => {
	dialUp.state = state;
	const isConnected = state === 'connected';

	// The two computers of the tray go away with the connection, and the volume next to them gets their focus.
	if (!isConnected && onlineButton.contains(document.activeElement)) {
		volumeButton.focus();
	}

	dialUpConnect.hidden = state !== 'idle';
	dialUpDisconnect.hidden = state === 'idle';
	onlineButton.hidden = !isConnected;
};

// Each run of the dialing has a number, so Disconnect stops a run that waits.
const dialStep = async (run, milliseconds, message) => {
	announce(dialUpStatus, message);
	await wait(milliseconds);
	return run === dialUp.run;
};

const connectDialUp = async () => {
	if (dialUp.state !== 'idle') {
		return;
	}

	const run = ++dialUp.run;
	const hadFocus = dialUpConnect.contains(document.activeElement);
	setDialUpState('dialing');

	if (hadFocus) {
		dialUpDisconnect.focus();
	}

	playSound('dial');

	if (!await dialStep(run, 2000, 'Dialing 815 00 999…')) {
		return;
	}

	// The first call is busy, as my little sister is on the phone with Ingrid.
	if (dialUp.attempts++ === 0) {
		for (const seconds of [5, 4, 3, 2, 1]) {
			if (!await dialStep(run, 1000, `The line is busy. Lillesøster is on the phone with Ingrid. Redialing in ${seconds}…`)) {
				return;
			}
		}

		playSound('dial');

		if (!await dialStep(run, 2000, 'Dialing 815 00 999…')) {
			return;
		}
	}

	if (!await dialStep(run, 1500, 'Verifying user name and password…') || !await dialStep(run, 1500, 'Logging on to network…')) {
		return;
	}

	setDialUpState('connected');
	announce(dialUpStatus, 'Connected at 28,800 bps. Fast!');
	const pending = dialUp.onConnect;
	dialUp.onConnect = undefined;
	pending?.();

	// The mail comes in a moment after the connection.
	setTimeout(() => {
		if (run === dialUp.run && mailIndex < mails.length) {
			mailButton.hidden = false;
		}
	}, 3000);

	// Somebody calls the house after a while, and the connection drops.
	setTimeout(() => {
		if (run === dialUp.run && dialUp.state === 'connected') {
			disconnectDialUp('Disconnected. Somebody called the house. It was Mormor. She wants to know if the Internet is on.');
			toast('📞 Ring ring! The Internet disconnected. It was Mormor.');
		}
	}, randomInteger(120, 180) * 1000);
};

function disconnectDialUp(message = 'Disconnected. The phone line is free for Mamma.') {
	dialUp.run++;
	dialUp.onConnect = undefined;

	if (dialUpDisconnect.contains(document.activeElement)) {
		dialUpConnect.hidden = false;
		dialUpConnect.focus();
	}

	setDialUpState('idle');
	announce(dialUpStatus, message);
}

dialUpConnect.addEventListener('click', connectDialUp);

dialUpDisconnect.addEventListener('click', () => {
	disconnectDialUp();
});

onlineButton.addEventListener('click', () => {
	openWindow('dialup', onlineButton);
});

mailButton.addEventListener('click', () => {
	const [from, text] = mails[mailIndex++];
	mailButton.hidden = true;
	openText(`Mail from ${from}`, text, startButton);
});

// Internet Explorer, which needs Dial-Up Networking for everything but its start page, and shows “The page cannot be displayed” for most of the web of 1999.
const ieWindow = windowOf('ie');
const ieAddress = document.querySelector('#geocities-win-ie-address');
const iePage = document.querySelector('#geocities-win-ie-page');
const ieStatus = document.querySelector('#geocities-win-ie-status');
const ieProgress = document.querySelector('#geocities-win-ie-progress');
const ieTemplates = Object.fromEntries([...ieWindow.querySelectorAll('[data-win-ie-template]')].map(template => [template.dataset.winIeTemplate, template]));
const ie = {history: [], index: -1, run: 0};

const iePages = {
	'about:home': ['home', 'Where do you want to go today?'],
	'sindresorhus.com/1999': ['here', 'Sindre’s Home Page'],
	'www.sindresorhus.com/1999': ['here', 'Sindre’s Home Page'],
	'www.download-more-ram.com': ['ram', 'Download More RAM for FREE!!!'],
	'www.unicorns.no': ['unicorns', 'Unicorns of Norway'],
	'www.y2k-survival.com': ['y2k', 'Y2K Survival Guide'],
	'windowsupdate.microsoft.com': ['update', 'Windows Update'],
};

const normalizeAddress = address => {
	const text = address.trim().toLowerCase().replace(/^https?:\/\//, '').replace(/\/$/, '');
	return text === '' || text === 'home' ? 'about:home' : text;
};

const showPage = (address, name, title) => {
	const page = fromTemplate(ieTemplates[name]);

	for (const slot of page.querySelectorAll('[data-win-ie-slot]')) {
		slot.textContent = address;
	}

	// A link of the old page could have the focus, which then goes to the new page, so it is not lost.
	const hadFocus = iePage.contains(document.activeElement);
	iePage.replaceChildren(page);
	iePage.scrollTop = 0;

	if (hadFocus) {
		iePage.focus();
	}

	ieAddress.value = address === 'about:home' ? 'about:home' : `http://${address}/`;
	setTitle('ie', `${title} - Microsoft Internet Explorer`);
	updateTasks();
};

const setLoading = isLoading => {
	if (isLoading) {
		ieWindow.dataset.winLoading = '';
	} else {
		delete ieWindow.dataset.winLoading;
	}

	setBusy('ie', isLoading);
};

const loadPage = async address => {
	const run = ++ie.run;
	const [name, title] = iePages[address] ?? ['error', 'Cannot find server'];

	if (name === 'home') {
		setLoading(false);
		showPage(address, name, title);
		ieStatus.textContent = 'Done';
		return;
	}

	setLoading(true);

	// A modem of 28.8 is slow, so the steps take a while.
	for (const [percent, message] of [[10, `Finding site: ${address}`], [35, `Connecting to site ${address}`], [70, `Opening page http://${address}/…`], [100, 'Done']]) {
		ieStatus.textContent = message;
		ieProgress.style.width = `${percent}%`;
		await wait(randomInteger(500, 1100));

		if (run !== ie.run) {
			return;
		}
	}

	setLoading(false);
	ieProgress.style.width = '0';
	showPage(address, name, title);
};

const go = address => {
	if (address === 'about:home' || dialUp.state === 'connected') {
		loadPage(address);
		return;
	}

	ask({title: 'Dial-up Connection', icon: '📞', text: 'Select the service you want to connect to, and then enter your user name and password.\n\nConnect to: Telenor Internett\nUser name: sindre', buttons: ['Connect', 'Work Offline']}).then(answer => {
		if (answer === 'Connect') {
			// The Connect To window goes away when it connects, like in Windows, and Internet Explorer comes back to the front.
			dialUp.onConnect = () => {
				closeWindow('dialup');
				loadPage(address);
			};

			openWindow('dialup', ieAddress);
			connectDialUp();
		} else if (answer === 'Work Offline') {
			showPage(address, 'offline', 'Web page unavailable while offline');
			ieStatus.textContent = 'Working offline';
		}
	});
};

// Keeps the address in the history, like the Back and Forward buttons.
function navigate(text) {
	const address = normalizeAddress(text);
	ie.history = [...ie.history.slice(0, ie.index + 1), address];
	ie.index = ie.history.length - 1;
	go(address);
}

document.querySelector('#geocities-win-ie-form').addEventListener('submit', event => {
	event.preventDefault();
	navigate(ieAddress.value);
});

const ieActions = {
	back() {
		if (ie.index > 0) {
			go(ie.history[--ie.index]);
		}
	},
	forward() {
		if (ie.index < ie.history.length - 1) {
			go(ie.history[++ie.index]);
		}
	},
	stop() {
		ie.run++;
		setLoading(false);
		ieProgress.style.width = '0';
		ieStatus.textContent = 'Done';
	},
	refresh() {
		go(ie.history[ie.index] ?? 'about:home');
	},
	home() {
		navigate('about:home');
	},
	connect() {
		go(ie.history[ie.index]);
	},
	async ram(button) {
		setEnabled(button, false);

		for (const megabytes of [1, 2, 3]) {
			ieStatus.textContent = `Downloading RAM… ${megabytes} of 32 MB`;
			await wait(1200);
		}

		ieStatus.textContent = 'Done';
		setEnabled(button, true);
		await ask({title: 'Download More RAM', icon: '❌', text: 'The RAM did not fit through the modem. Try a wider phone cord.', opener: button});
	},
	async update(button) {
		setEnabled(button, false);
		setLoading(true);

		for (const number of [1, 2, 3]) {
			ieStatus.textContent = `Installing update ${number} of 1,999…`;
			ieProgress.style.width = `${number * 30}%`;
			await wait(1000);
		}

		setLoading(false);
		ieProgress.style.width = '0';
		ieStatus.textContent = 'Done';
		setEnabled(button, true);
		const answer = await ask({title: 'Windows Update', icon: '❓', text: 'You must restart your computer before the new settings will take effect.\n\nDo you want to restart your computer now?', buttons: ['Yes', 'No'], opener: button});

		if (answer === 'Yes') {
			updateRestarts = 1;
			restart();
		} else {
			ieStatus.textContent = 'The other 1,996 updates will install the next time. And the time after that.';
		}
	},
};

ieWindow.addEventListener('click', event => {
	const action = event.target.closest('[data-win-ie-action]');
	const link = event.target.closest('[data-win-ie-go]');

	if (action) {
		ieActions[action.dataset.winIeAction](action);
	} else if (link) {
		navigate(link.dataset.winIeGo);
	}
});

onOpen.ie = () => {
	if (ie.history.length === 0) {
		navigate('about:home');
	}
};

commands.update = () => {
	openWindow('ie', startButton);
	navigate('windowsupdate.microsoft.com');
};

// The folders: My Documents, Network Neighborhood, and the folders inside them, like the new folders of the desktop. Each file opens its program.
const fileTemplate = document.querySelector('#geocities-win-file-template');

const showFiles = (list, status, files) => {
	list.replaceChildren(...files.map(file => {
		const item = fromTemplate(fileTemplate);
		const [picture, name] = item.querySelectorAll('span');
		picture.textContent = file.icon;
		name.textContent = file.name;

		item.querySelector('button').addEventListener('click', event => {
			file.open(event.currentTarget);
		});

		return item;
	}));

	status.textContent = files.length === 0 ? 'This folder is empty.' : `${files.length} object(s)`;
};

const folderList = document.querySelector('#geocities-win-folder-list');
const folderStatus = document.querySelector('#geocities-win-folder-status');

function openFolder(name, files, opener) {
	setTitle('folder', name);
	showFiles(folderList, folderStatus, files);

	if (files.length === 0) {
		folderStatus.textContent = 'This folder is empty. Like my piggy bank.';
	}

	if (windowOf('folder').hidden) {
		openWindow('folder', opener);
	} else {
		updateTasks();
		folderList.querySelector('button')?.focus();
	}
}

const textFile = (name, text) => ({
	name,
	icon: '📄',
	open: opener => openText(name, text, opener),
});

const program = (name, icon, app) => ({
	name,
	icon,
	open: opener => openWindow(app, opener),
});

const illegalOperation = (program, module, opener) => ask({
	title: program,
	icon: '❌',
	text: 'This program has performed an illegal operation and will be shut down.\n\nIf the problem persists, contact the program vendor.',
	buttons: ['Close'],
	details: `${program.toUpperCase()} caused an invalid page fault in\nmodule ${module} at 0167:bff7a3c1.\nRegisters:\nEAX=00001999 CS=0167 EIP=bff7a3c1 EFLGS=00000246\nEBX=00000000 SS=016f ESP=0063f1d0 EBP=0063f1f4\nECX=0000ffff DS=016f ESI=00000000 FS=0f0f\nEDX=00002000 ES=016f EDI=00000099 GS=0000\nBytes at CS:EIP:\n53 8b 15 19 99 20 00 75 6e 69 63 6f 72 6e\nStack dump:\n00001999 00002000 00000099 0000ffff 756e6963 6f726e21`,
	opener,
});

const privateFolder = {
	name: 'PRIVATE',
	icon: '📁',
	open: opener => openFolder('PRIVATE', [{
		name: 'DO NOT OPEN',
		icon: '📁',
		open: inner => openFolder('DO NOT OPEN', [{
			name: 'REALLY DO NOT OPEN',
			icon: '📁',
			open: innermost => openFolder('REALLY DO NOT OPEN', [textFile('README.TXT', texts.gotcha)], innermost),
		}], inner),
	}], opener),
};

const myDocuments = [
	textFile('README.TXT', texts.readme),
	program('LETTER TO SANTA 2000.DOC', '📄', 'wordpad'),
	{
		name: 'HOMEWORK.DOC',
		icon: '📄',
		open: opener => ask({title: 'WordPad', icon: 'ℹ️', text: 'HOMEWORK.DOC is 0 bytes.\n\nThe dog ate it. (We do not have a dog.)', opener}),
	},
	program('DANCING BABY.AVI', '📼', 'media'),
	{
		name: 'TADA.WAV',
		icon: '🔊',
		open: opener => {
			openWindow('sound', opener);
			loadTada();
		},
	},
	{
		name: 'MY HOME PAGE.HTM',
		icon: '🌐',
		open: opener => {
			openWindow('ie', opener);
			navigate('sindresorhus.com/1999');
		},
	},
	program('Y2K FIX.EXE', '🩹', 'fixer'),
	{
		name: 'TETRIS.EXE',
		icon: '🧱',
		open: opener => illegalOperation('Tetris', 'KRNL386.EXE', opener),
	},
	privateFolder,
];

onOpen.documents = () => {
	showFiles(document.querySelector('#geocities-win-documents-list'), document.querySelector('#geocities-win-documents-status'), myDocuments);
};

// Network Neighborhood: the computers of the house, on a long cable to the living room.
const networkList = document.querySelector('#geocities-win-network-list');
const networkStatus = document.querySelector('#geocities-win-network-status');
const networkPath = document.querySelector('#geocities-win-network-path');
const networkUp = document.querySelector('#geocities-win-network-up');
const networkTrail = [];

const networkFolder = (name, files) => ({
	name,
	icon: '📁',
	open: () => enterNetwork(name, files),
});

const neighborhood = [
	{
		name: 'MAMMA',
		icon: '🖥️',
		open: () => enterNetwork('\\\\MAMMA', [
			networkFolder('Handleliste', [textFile('HANDLELISTE.TXT', texts.shopping)]),
			networkFolder('Oppskrifter', [textFile('VAFLER.TXT', texts.waffles)]),
		]),
	},
	{
		name: 'PAPPA',
		icon: '🖥️',
		open: opener => ask({title: 'Network', icon: '🔒', text: '\\\\PAPPA is not accessible.\n\nAccess is denied. Pappa only shares the printer, and the printer is out of paper.', opener}),
	},
	{
		name: 'LILLESØSTER',
		icon: '🖥️',
		open: () => enterNetwork('\\\\LILLESØSTER', [textFile('MIN DAGBOK.TXT', texts.sisterDiary), textFile('MY BIG BROTHER.TXT', texts.sisterList)]),
	},
	{
		name: 'Entire Network',
		icon: '🌍',
		open: opener => ask({title: 'Network', icon: '❌', text: 'Unable to browse the network.\n\nThe network is not accessible. It is a 10 meter cable to the living room, and the cat chews on it.', opener}),
	},
];

function enterNetwork(path, files) {
	networkTrail.push({path, files});
	networkPath.textContent = path;
	networkUp.disabled = networkTrail.length < 2;
	showFiles(networkList, networkStatus, files);
	networkList.querySelector('button')?.focus();
}

networkUp.addEventListener('click', () => {
	networkTrail.pop();
	const {path, files} = networkTrail.pop();
	enterNetwork(path, files);
});

onOpen.network = () => {
	networkTrail.length = 0;
	enterNetwork('Network Neighborhood', neighborhood);
};

commands.readme = () => {
	openText('README.TXT', texts.readme, startButton);
};

// Media Player plays DANCING BABY.AVI, after buffering. The video is the GIF of the dancing baby, and its still frame while it is stopped or paused.
const mediaVideo = document.querySelector('#geocities-win-media-video');
const mediaBuffering = document.querySelector('#geocities-win-media-buffering');
const mediaProgress = document.querySelector('#geocities-win-media-progress');
const mediaTime = document.querySelector('#geocities-win-media-time');
const mediaStatus = document.querySelector('#geocities-win-media-status');
const stillPath = mediaVideo.getAttribute('src');
const media = {seconds: 0, timer: undefined, isBuffered: false, run: 0};
const mediaLength = 15;

const showMediaTime = () => {
	const format = seconds => `00:${String(Math.floor(seconds)).padStart(2, '0')}`;
	mediaTime.textContent = `${format(media.seconds)} / ${format(mediaLength)}`;
	mediaProgress.style.width = `${media.seconds / mediaLength * 100}%`;
};

const pauseMedia = (message = 'Paused') => {
	clearInterval(media.timer);
	media.timer = undefined;
	media.run++;
	mediaBuffering.hidden = true;
	mediaVideo.src = stillPath;
	announce(mediaStatus, message);
};

const playMedia = async () => {
	if (media.timer) {
		return;
	}

	const run = ++media.run;

	if (!media.isBuffered) {
		mediaBuffering.hidden = false;

		for (const percent of [0, 18, 37, 61, 89, 100]) {
			mediaBuffering.textContent = `Buffering… ${percent}%`;
			await wait(450);

			if (run !== media.run) {
				return;
			}
		}

		mediaBuffering.hidden = true;
		media.isBuffered = true;
	}

	// The baby dances in the GIF, which stays still for visitors who prefer less motion.
	if (reducedMotion.matches) {
		announce(mediaStatus, 'Playing. The baby dances in your head, as you prefer less motion.');
	} else {
		mediaVideo.src = mediaVideo.dataset.winMediaAnimated;
		announce(mediaStatus, 'Playing DANCING BABY.AVI. Ooga chaka!');
	}

	media.timer = setInterval(() => {
		media.seconds = (media.seconds + 1) % (mediaLength + 1);
		showMediaTime();
	}, 1000);
};

for (const button of document.querySelectorAll('[data-win-media-action]')) {
	button.addEventListener('click', () => {
		const action = button.dataset.winMediaAction;

		if (action === 'play') {
			playMedia();
		} else if (action === 'pause') {
			pauseMedia();
		} else {
			pauseMedia('Stopped');
			media.seconds = 0;
			showMediaTime();
		}
	});
}

onClose.media = () => {
	pauseMedia('Stopped');
};

// Sound Recorder records from the microphone for up to 60 seconds, like the one of Windows, or plays TADA.WAV, which it makes itself. The Effects change the sound for real, and the green line shows it.
const soundWave = document.querySelector('#geocities-win-sound-wave');
const soundContext = soundWave.getContext('2d');
const soundPosition = document.querySelector('#geocities-win-sound-position');
const soundLength = document.querySelector('#geocities-win-sound-length');
const soundStatus = document.querySelector('#geocities-win-sound-status');
const recorder = {buffer: undefined, position: 0, source: undefined, startedAt: 0, frame: 0, recording: undefined};

const showSoundTimes = () => {
	soundPosition.textContent = `${recorder.position.toFixed(2)} sec.`;
	soundLength.textContent = `${(recorder.buffer?.duration ?? 0).toFixed(2)} sec.`;
};

// The whole sound while it is stopped, and the part at the position while it plays, like an oscilloscope.
const drawSound = (samples = recorder.buffer?.getChannelData(0), from = 0, to = samples?.length ?? 0) => {
	const {width, height} = soundWave;
	soundContext.fillStyle = '#000000';
	soundContext.fillRect(0, 0, width, height);
	soundContext.strokeStyle = '#00ff00';
	soundContext.beginPath();

	for (let x = 0; x < width; x++) {
		const index = Math.floor(from + ((to - from) * x / width));
		const value = samples && index < samples.length ? samples[index] : 0;
		const y = (height / 2) - (value * height / 2);

		if (x === 0) {
			soundContext.moveTo(x, y);
		} else {
			soundContext.lineTo(x, y);
		}
	}

	soundContext.stroke();
};

drawSound();

const setSound = (buffer, message) => {
	stopSound();
	recorder.buffer = buffer;
	recorder.position = 0;
	showSoundTimes();
	drawSound();
	announce(soundStatus, message);
};

// TADA.WAV, made from tones: a short “ta” and a long “da!”, with the overtones of a brass chord.
function loadTada() {
	const context = audio();
	const rate = context.sampleRate;
	const buffer = context.createBuffer(1, Math.floor(rate * 1.6), rate);
	const samples = buffer.getChannelData(0);
	const notes = [[0, 0.14, [392, 523.25]], [0.18, 1.4, [523.25, 659.25, 783.99, 1046.5]]];

	for (const [start, length, frequencies] of notes) {
		for (let index = Math.floor(start * rate); index < Math.floor((start + length) * rate) && index < samples.length; index++) {
			const time = (index / rate) - start;
			const envelope = Math.min(time / 0.02, 1) * Math.exp(-time * 2.2);

			for (const frequency of frequencies) {
				for (const [harmonic, strength] of [[1, 1], [2, 0.4], [3, 0.2]]) {
					samples[index] += Math.sin(2 * Math.PI * frequency * harmonic * time) * strength * envelope * 0.12;
				}
			}
		}
	}

	setSound(buffer, 'TADA.WAV. Press ▶ to play it (with sound).');
}

const soundLoop = () => {
	if (!recorder.source) {
		return;
	}

	recorder.position = Math.min(audioContext.currentTime - recorder.startedAt, recorder.buffer.duration);
	showSoundTimes();

	if (!reducedMotion.matches) {
		const samples = recorder.buffer.getChannelData(0);
		const index = Math.floor(recorder.position * recorder.buffer.sampleRate);
		drawSound(samples, index, index + 800);
	}

	recorder.frame = requestAnimationFrame(soundLoop);
};

function stopSound() {
	if (recorder.source) {
		recorder.source.onended = undefined;
		recorder.source.stop();
		recorder.source = undefined;
		cancelAnimationFrame(recorder.frame);
		drawSound();
	}
}

const playRecording = () => {
	if (recorder.recording) {
		return;
	}

	if (!recorder.buffer) {
		loadTada();
	}

	stopSound();
	const context = audio();

	if (recorder.position >= recorder.buffer.duration - 0.01) {
		recorder.position = 0;
	}

	const source = context.createBufferSource();
	source.buffer = recorder.buffer;
	source.connect(masterGain);
	recorder.startedAt = context.currentTime - recorder.position;
	source.start(0, recorder.position);
	recorder.source = source;

	source.onended = () => {
		recorder.source = undefined;
		recorder.position = recorder.buffer.duration;
		cancelAnimationFrame(recorder.frame);
		showSoundTimes();
		drawSound();
		announce(soundStatus, 'Done. Try the effects, like Reverse.');
	};

	announce(soundStatus, muteBox.checked ? 'Playing, but the volume in the tray is muted.' : 'Playing…');
	soundLoop();
};

const stopRecording = () => {
	recorder.isStarting = false;

	if (recorder.recording?.state === 'recording') {
		recorder.recording.stop();
	}
};

// The recording goes through a MediaRecorder, and the sound that it makes is decoded back into samples for the effects.
const record = async () => {
	if (recorder.recording || recorder.isStarting) {
		return;
	}

	stopSound();
	recorder.isStarting = true;

	if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === 'undefined') {
		recorder.isStarting = false;
		loadTada();
		announce(soundStatus, 'This computer has no microphone. Here is TADA.WAV instead.');
		return;
	}

	let stream;

	try {
		stream = await navigator.mediaDevices.getUserMedia({audio: true});
	} catch {
		recorder.isStarting = false;
		loadTada();
		announce(soundStatus, 'No microphone, or you said no. Here is TADA.WAV instead.');
		return;
	}

	// Stop, or closing the window, while the browser asked for the microphone cancels the recording.
	if (!recorder.isStarting) {
		for (const track of stream.getTracks()) {
			track.stop();
		}

		return;
	}

	recorder.isStarting = false;

	const context = audio();
	const analyser = context.createAnalyser();
	const input = context.createMediaStreamSource(stream);
	input.connect(analyser);
	const samples = new Float32Array(analyser.fftSize);
	const mediaRecorder = new MediaRecorder(stream);
	const chunks = [];
	const startedAt = performance.now();
	let frame;
	recorder.recording = mediaRecorder;

	const draw = () => {
		recorder.position = (performance.now() - startedAt) / 1000;
		soundPosition.textContent = `${recorder.position.toFixed(2)} sec.`;

		if (!reducedMotion.matches) {
			analyser.getFloatTimeDomainData(samples);
			drawSound(samples);
		}

		frame = requestAnimationFrame(draw);
	};

	mediaRecorder.addEventListener('dataavailable', event => {
		chunks.push(event.data);
	});

	// Sound Recorder stops at 60 seconds, like the one of Windows 98, also in a hidden tab, where the frames stop.
	const limit = setTimeout(() => {
		mediaRecorder.stop();
	}, 60_000);

	mediaRecorder.addEventListener('stop', async () => {
		clearTimeout(limit);
		cancelAnimationFrame(frame);

		for (const track of stream.getTracks()) {
			track.stop();
		}

		input.disconnect();
		recorder.recording = undefined;

		try {
			const buffer = await context.decodeAudioData(await new Blob(chunks, {type: mediaRecorder.mimeType}).arrayBuffer());
			setSound(buffer, 'Recorded! Press ▶ to hear yourself, then try Reverse or Faster.');
		} catch {
			loadTada();
			announce(soundStatus, 'The recording got lost. Here is TADA.WAV instead.');
		}
	});

	mediaRecorder.start();
	announce(soundStatus, 'Recording… Say something! Press ⏹ to stop. It stops by itself at 60 seconds.');
	draw();
};

// The effects of the Effects menu of Sound Recorder, which make a new sound from the old one.
const soundEffects = {
	louder: samples => samples.map(value => clamp(value * 1.25, -1, 1)),
	faster: samples => samples.filter((_, index) => index % 2 === 0),
	slower: samples => Float32Array.from({length: samples.length * 2}, (_, index) => samples[Math.floor(index / 2)]),
	reverse: samples => samples.toReversed(),
	echo(samples, rate) {
		const delay = Math.floor(rate * 0.25);
		const result = new Float32Array(samples.length + (delay * 3));

		for (const [index, value] of samples.entries()) {
			for (let echo = 0; echo < 4; echo++) {
				result[index + (echo * delay)] += value * (0.5 ** echo);
			}
		}

		return result.map(value => clamp(value, -1, 1));
	},
};

const effectMessages = {
	louder: 'Louder, by 25%.',
	faster: 'Faster, by 100%. Chipmunk mode!',
	slower: 'Slower, by 50%. Like a tired robot.',
	reverse: 'Reversed! Now it is a secret message.',
	echo: 'Echo… echo… echo…',
};

for (const button of document.querySelectorAll('[data-win-sound-effect]')) {
	button.addEventListener('click', () => {
		const effect = button.dataset.winSoundEffect;

		if (effect === 'tada') {
			loadTada();
			return;
		}

		if (!recorder.buffer) {
			loadTada();
		}

		const context = audio();
		const samples = soundEffects[effect](recorder.buffer.getChannelData(0), recorder.buffer.sampleRate);

		// Slower doubles the sound each time, so without a limit, a few more clicks would fill the memory of the browser.
		if (samples.length > recorder.buffer.sampleRate * 60) {
			announce(soundStatus, 'Sound Recorder cannot make a sound longer than 60 seconds. Try Faster.');
			return;
		}

		const buffer = context.createBuffer(1, Math.max(samples.length, 1), recorder.buffer.sampleRate);
		buffer.copyToChannel(Float32Array.from(samples), 0);
		setSound(buffer, `${effectMessages[effect]} Press ▶ to play it.`);
	});
}

const soundActions = {
	play: playRecording,
	record,
	stop() {
		stopRecording();
		stopSound();
		showSoundTimes();
	},
	start() {
		stopSound();
		recorder.position = 0;
		showSoundTimes();
	},
	end() {
		stopSound();
		recorder.position = recorder.buffer?.duration ?? 0;
		showSoundTimes();
	},
};

for (const button of document.querySelectorAll('[data-win-sound-action]')) {
	button.addEventListener('click', () => {
		soundActions[button.dataset.winSoundAction]();
	});
}

onClose.sound = () => {
	stopRecording();
	stopSound();
};

// FreeCell, with the deals of the FreeCell of Windows, made with the same random numbers, so each game number deals the same cards. Game #11982 is the one that nobody can win.
const freecellWindow = windowOf('freecell');
const freecellColumns = [...freecellWindow.querySelectorAll('[data-win-freecell-column]')];
const freecellCells = [...freecellWindow.querySelectorAll('[data-win-freecell-cell]')];
const freecellHomes = [...freecellWindow.querySelectorAll('[data-win-freecell-home]')];
// The suit that an empty home cell shows.
const homeSuits = freecellHomes.map(button => button.firstElementChild);
const freecellStatus = document.querySelector('#geocities-win-freecell-status');
const freecellNumber = document.querySelector('#geocities-win-freecell-number');
const freecellUndo = document.querySelector('#geocities-win-freecell-undo');
const freecellKing = document.querySelector('#geocities-win-freecell-king');
const cardTemplate = document.querySelector('#geocities-win-card-template');
const ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
const rankNames = ['Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'];
const suits = ['♣', '♦', '♥', '♠'];
const suitNames = ['clubs', 'diamonds', 'hearts', 'spades'];
let freecell;

// A card is a number: the rank times 4, plus the suit, in the order of clubs, diamonds, hearts, and spades, like the deck of FreeCell.
const rankOf = card => Math.floor(card / 4);
const suitOf = card => card % 4;
const isRed = card => suitOf(card) === 1 || suitOf(card) === 2;
const cardName = card => `${rankNames[rankOf(card)]} of ${suitNames[suitOf(card)]}`;

// The deal of the FreeCell of Windows, with the random numbers of the C library of Microsoft.
const dealFreecell = game => {
	let seed = game;

	const random = () => {
		seed = ((seed * 214_013) + 2_531_011) % 2_147_483_648;
		return Math.floor(seed / 65_536);
	};

	const deck = Array.from({length: 52}, (_, index) => index);
	const columns = Array.from({length: 8}, () => []);

	for (let index = 0; index < 52; index++) {
		const left = 52 - index;
		const pick = random() % left;
		columns[index % 8].push(deck[pick]);
		deck[pick] = deck[left - 1];
	}

	return columns;
};

const canStack = (card, onto) => rankOf(onto) === rankOf(card) + 1 && isRed(onto) !== isRed(card);

// The cards at the end of a column that are in order, which move together.
const runLength = column => {
	let length = column.length > 0 ? 1 : 0;

	while (length < column.length && canStack(column.at(-length), column.at(-length - 1))) {
		length++;
	}

	return length;
};

// How many cards can move at once, with the free cells and the empty columns, like FreeCell moves them one at a time.
const maximumMove = toEmptyColumn => {
	const freeCells = freecell.cells.filter(card => card === undefined).length;
	const emptyColumns = freecell.columns.filter(column => column.length === 0).length - (toEmptyColumn ? 1 : 0);
	return (freeCells + 1) * (2 ** emptyColumns);
};

const canGoHome = card => freecell.homes[suitOf(card)] === rankOf(card) - 1;

const snapshot = () => structuredClone({columns: freecell.columns, cells: freecell.cells, homes: freecell.homes});

const makeCard = (card, isSelected) => {
	const element = fromTemplate(cardTemplate);
	element.textContent = `${ranks[rankOf(card)]}${suits[suitOf(card)]}`;

	if (isRed(card)) {
		element.dataset.winCardRed = '';
	}

	if (isSelected) {
		element.dataset.winSelected = '';
	}

	return element;
};

const renderFreecell = () => {
	const {selection} = freecell;

	for (const [index, button] of freecellColumns.entries()) {
		const column = freecell.columns[index];
		const selectedCount = selection?.from === 'column' && selection.index === index ? selection.count : 0;
		button.replaceChildren(...column.map((card, position) => makeCard(card, position >= column.length - selectedCount)));
		button.setAttribute('aria-label', column.length === 0 ? `Column ${index + 1}, empty` : `Column ${index + 1}, ${column.length} cards, ${cardName(column.at(-1))} on top${selectedCount ? `, ${selectedCount} picked up` : ''}`);
	}

	for (const [index, button] of freecellCells.entries()) {
		const card = freecell.cells[index];
		const isSelected = selection?.from === 'cell' && selection.index === index;
		button.replaceChildren(...(card === undefined ? [] : [makeCard(card, isSelected)]));
		button.setAttribute('aria-label', `Free cell ${index + 1}, ${card === undefined ? 'empty' : cardName(card)}${isSelected ? ', picked up' : ''}`);
	}

	for (const [index, button] of freecellHomes.entries()) {
		const rank = freecell.homes[index];

		button.replaceChildren(rank >= 0 ? makeCard((rank * 4) + index, false) : homeSuits[index]);

		button.setAttribute('aria-label', `Home cell for ${suitNames[index]}, ${rank >= 0 ? `${rankNames[rank]} on top` : 'empty'}`);
	}

	setEnabled(freecellUndo, freecell.undo.length > 0);
};

const startFreecell = game => {
	freecell = {game, columns: dealFreecell(game), cells: [undefined, undefined, undefined, undefined], homes: [-1, -1, -1, -1], selection: undefined, undo: [], isOver: false};
	freecellNumber.value = String(game);
	renderFreecell();
	announce(freecellStatus, game === 11_982 ? 'Game #11982: the only one of the first 32,000 games that nobody can win. Good luck!' : `Game #${game}. Click a column to pick up its cards, and click where they go.`);
};

// Cards that are no longer needed in the columns go home by themselves, like in FreeCell: a card goes when both colors of the other suits are high enough.
const isSafeHome = card => {
	const otherColor = [0, 1, 2, 3].filter(suit => (suit === 1 || suit === 2) !== isRed(card));
	return rankOf(card) <= 1 || otherColor.every(suit => freecell.homes[suit] >= rankOf(card) - 1);
};

const autoMoveHome = () => {
	let didMove = true;

	while (didMove) {
		didMove = false;

		for (const column of freecell.columns) {
			const card = column.at(-1);

			if (card !== undefined && canGoHome(card) && isSafeHome(card)) {
				freecell.homes[suitOf(card)]++;
				column.pop();
				didMove = true;
			}
		}

		for (const [index, card] of freecell.cells.entries()) {
			if (card !== undefined && canGoHome(card) && isSafeHome(card)) {
				freecell.homes[suitOf(card)]++;
				freecell.cells[index] = undefined;
				didMove = true;
			}
		}
	}
};

const hasLegalMove = () => {
	const tops = [...freecell.columns.map(column => column.at(-1)), ...freecell.cells].filter(card => card !== undefined);

	if (freecell.cells.includes(undefined) || freecell.columns.some(column => column.length === 0)) {
		return true;
	}

	return tops.some(card => canGoHome(card) || freecell.columns.some(column => column.length > 0 && canStack(card, column.at(-1))));
};

const finishMove = async before => {
	freecell.undo.push(before);
	freecell.selection = undefined;
	autoMoveHome();
	renderFreecell();

	if (freecell.homes.every(rank => rank === 12)) {
		freecell.isOver = true;
		// The storage can hold anything, which counts as no wins.
		const saved = load('geocities-win-freecell-wins', 0);
		const wins = (Number.isInteger(saved) && saved > 0 ? saved : 0) + 1;
		save('geocities-win-freecell-wins', wins);
		announce(freecellStatus, `Congratulations, you win! That is ${wins} ${wins === 1 ? 'win' : 'wins'} on this computer.`);
		celebrate();
		return;
	}

	announce(freecellStatus, `${cardsLeft()} cards left.`);

	if (!hasLegalMove()) {
		const game = freecell;
		const answer = await ask({title: 'Game Over', icon: '🃏', text: `There are no more legal moves.\n\nYou lost game #${freecell.game}. Do you want to undo, or play again?`, buttons: ['Undo', 'New Game']});

		// A new game could have started while the question was open.
		if (game !== freecell) {
			return;
		}

		if (answer === 'Undo') {
			undoFreecell();
		} else if (answer === 'New Game') {
			startFreecell(randomInteger(1, 32_000));
		}
	}
};

const cardsLeft = () => {
	let count = 52;

	for (const rank of freecell.homes) {
		count -= rank + 1;
	}

	return count;
};

const notAllowed = message => {
	freecell.selection = undefined;
	renderFreecell();
	announce(freecellStatus, message ?? 'That move is not allowed.');
};

// Moves the picked up cards to a column: as many as fit, if the first of them stacks on the last card of the column.
const moveToColumn = target => {
	const {selection} = freecell;
	const before = snapshot();
	const column = freecell.columns[target];

	if (selection.from === 'cell') {
		const card = freecell.cells[selection.index];

		if (column.length > 0 && !canStack(card, column.at(-1))) {
			notAllowed();
			return;
		}

		freecell.cells[selection.index] = undefined;
		column.push(card);
		finishMove(before);
		return;
	}

	const source = freecell.columns[selection.index];
	const limit = Math.min(runLength(source), maximumMove(column.length === 0));
	let count = column.length === 0 ? limit : 0;

	for (let length = 1; length <= limit && count === 0; length++) {
		if (canStack(source.at(-length), column.at(-1))) {
			count = length;
		}
	}

	if (!count) {
		notAllowed(runLength(source) > limit ? `That is too many cards to move at once. Empty a free cell or a column first.` : undefined);
		return;
	}

	column.push(...source.splice(-count));
	finishMove(before);
};

const pickedCard = () => {
	const {selection} = freecell;
	return selection.from === 'cell' ? freecell.cells[selection.index] : freecell.columns[selection.index].at(-1);
};

const removePicked = () => {
	const {selection} = freecell;

	if (selection.from === 'cell') {
		freecell.cells[selection.index] = undefined;
	} else {
		freecell.columns[selection.index].pop();
	}
};

const moveToCell = target => {
	if (freecell.cells[target] !== undefined) {
		notAllowed('That free cell is taken.');
		return;
	}

	const before = snapshot();
	const card = pickedCard();
	removePicked();
	freecell.cells[target] = card;
	finishMove(before);
};

const moveHome = () => {
	const card = pickedCard();

	if (!canGoHome(card)) {
		notAllowed(`The ${cardName(card)} cannot go home yet.`);
		return;
	}

	const before = snapshot();
	removePicked();
	freecell.homes[suitOf(card)]++;
	finishMove(before);
};

function undoFreecell() {
	const before = freecell.undo.pop();

	if (before) {
		Object.assign(freecell, before, {selection: undefined, isOver: false});
		renderFreecell();
		announce(freecellStatus, 'Undone.');
	}
}

let lastColumnClick = {index: -1, time: 0};

for (const [index, button] of freecellColumns.entries()) {
	button.addEventListener('click', () => {
		const {selection} = freecell;
		const now = performance.now();
		// A double-click sends the last card home, or to a free cell, like in FreeCell.
		const isDoubleClick = lastColumnClick.index === index && now - lastColumnClick.time < 400;
		lastColumnClick = {index, time: now};

		if (isDoubleClick && freecell.columns[index].length > 0) {
			freecell.selection = {from: 'column', index, count: 1};
			const freeCell = freecell.cells.indexOf(undefined);

			if (canGoHome(pickedCard())) {
				moveHome();
			} else if (freeCell === -1) {
				notAllowed('The free cells are full.');
			} else {
				moveToCell(freeCell);
			}

			return;
		}

		if (selection?.from === 'column' && selection.index === index) {
			freecell.selection = undefined;
			renderFreecell();
			return;
		}

		if (selection) {
			moveToColumn(index);
			return;
		}

		if (freecell.columns[index].length > 0) {
			// Only the top card looks picked up, like in FreeCell, and a move to a column takes as many cards as fit.
			freecell.selection = {from: 'column', index, count: 1};
			renderFreecell();
		}
	});
}

for (const [index, button] of freecellCells.entries()) {
	button.addEventListener('click', () => {
		const {selection} = freecell;

		if (selection?.from === 'cell' && selection.index === index) {
			freecell.selection = undefined;
			renderFreecell();
		} else if (selection) {
			moveToCell(index);
		} else if (freecell.cells[index] !== undefined) {
			freecell.selection = {from: 'cell', index};
			renderFreecell();
		}
	});
}

for (const button of freecellHomes) {
	button.addEventListener('click', () => {
		if (freecell.selection) {
			moveHome();
		}
	});
}

freecellUndo.addEventListener('click', undoFreecell);

document.querySelector('#geocities-win-freecell-form').addEventListener('submit', event => {
	event.preventDefault();
	startFreecell(clamp(Math.round(Number(freecellNumber.value)) || 1, 1, 32_000));
});

document.querySelector('#geocities-win-freecell-random').addEventListener('click', () => {
	startFreecell(randomInteger(1, 32_000));
});

// The king looks to the side of the pointer.
freecellWindow.addEventListener('pointermove', event => {
	const box = freecellKing.getBoundingClientRect();

	if (event.clientX > box.left + (box.width / 2)) {
		freecellKing.dataset.winLookRight = '';
	} else {
		delete freecellKing.dataset.winLookRight;
	}
});

startFreecell(randomInteger(1, 32_000));

// The wallpapers, drawn on a canvas and tiled behind the icons, like the patterns and wallpapers of Windows.
const layer = document.querySelector('#geocities-win-layer');

const drawTile = (width, height, draw) => {
	const canvas = document.createElement('canvas');
	canvas.width = width;
	canvas.height = height;
	draw(canvas.getContext('2d'), width, height);
	return `url(${canvas.toDataURL()})`;
};

const wallpapers = {
	none: () => '',
	clouds: () => drawTile(512, 384, (context, width, height) => {
		const sky = context.createLinearGradient(0, 0, 0, height);
		sky.addColorStop(0, '#2f63c9');
		sky.addColorStop(1, '#9fc4f2');
		context.fillStyle = sky;
		context.fillRect(0, 0, width, height);

		for (let cloud = 0; cloud < 7; cloud++) {
			const x = Math.random() * width;
			const y = Math.random() * height;

			for (let puff = 0; puff < 8; puff++) {
				const radius = 20 + (Math.random() * 30);
				const gradient = context.createRadialGradient(x + (puff * 18), y + (Math.sin(puff) * 10), 0, x + (puff * 18), y + (Math.sin(puff) * 10), radius);
				gradient.addColorStop(0, 'rgb(255 255 255 / 0.8)');
				gradient.addColorStop(1, 'rgb(255 255 255 / 0)');
				context.fillStyle = gradient;
				context.fillRect(0, 0, width, height);
			}
		}
	}),
	thatch: () => drawTile(16, 16, (context, width, height) => {
		context.fillStyle = '#000000';
		context.fillRect(0, 0, width, height);
		context.strokeStyle = '#808080';

		for (const [x1, y1, x2, y2] of [[0, 0, 8, 8], [8, 8, 16, 0], [0, 16, 8, 8], [8, 8, 16, 16]]) {
			context.beginPath();
			context.moveTo(x1, y1);
			context.lineTo(x2, y2);
			context.stroke();
		}
	}),
	waffle: () => drawTile(28, 28, context => {
		context.fillStyle = '#f0c060';
		context.fillRect(0, 0, 28, 28);
		context.fillStyle = '#c47a1c';
		context.fillRect(5, 5, 18, 18);
		context.fillStyle = '#a5610f';
		context.fillRect(8, 8, 12, 12);
	}),
	unicorns: () => drawTile(72, 72, context => {
		context.fillStyle = '#ffd6f0';
		context.fillRect(0, 0, 72, 72);
		context.font = '32px system-ui, "Apple Color Emoji", "Segoe UI Emoji", sans-serif';
		context.fillText('🦄', 8, 40);
		context.font = '14px system-ui, "Apple Color Emoji", "Segoe UI Emoji", sans-serif';
		context.fillText('✨', 48, 62);
	}),
	circuit: () => drawTile(96, 96, context => {
		context.fillStyle = '#0b3d1a';
		context.fillRect(0, 0, 96, 96);
		context.strokeStyle = '#3fae5a';
		context.fillStyle = '#d4af37';
		context.lineWidth = 2;

		for (const [x, y, length, isVertical] of [[8, 16, 56, false], [64, 16, 40, true], [16, 56, 48, false], [16, 56, 32, true], [40, 80, 56, false], [80, 0, 30, true]]) {
			context.beginPath();
			context.moveTo(x, y);
			context.lineTo(isVertical ? x : x + length, isVertical ? y + length : y);
			context.stroke();
			context.fillRect(x - 3, y - 3, 6, 6);
		}
	}),
	jungle: () => drawTile(120, 120, context => {
		context.fillStyle = '#0f3d14';
		context.fillRect(0, 0, 120, 120);

		for (let leaf = 0; leaf < 14; leaf++) {
			context.save();
			context.translate(Math.random() * 120, Math.random() * 120);
			context.rotate(Math.random() * Math.PI);
			context.fillStyle = randomItem(['#1f6b26', '#2e8b3a', '#145a1c', '#3a9d44']);
			context.beginPath();
			context.ellipse(0, 0, 26, 9, 0, 0, Math.PI * 2);
			context.fill();
			context.restore();
		}
	}),
	cat: () => drawTile(40, 40, context => {
		context.fillStyle = '#f6e7c8';
		context.fillRect(0, 0, 40, 40);
		context.fillStyle = '#e8c9a0';
		context.fillRect(0, 0, 20, 20);
		context.fillRect(20, 20, 20, 20);
	}),
	mustard: () => drawTile(64, 64, context => {
		context.fillStyle = '#ffff00';
		context.fillRect(0, 0, 64, 64);
		context.fillStyle = '#ff0000';
		context.fillRect(0, 0, 32, 64);
	}),
};

const wallpaperPicker = document.querySelector('#geocities-win-wallpaper');

const setWallpaper = name => {
	wallpaperPicker.value = name;
	layer.style.backgroundImage = wallpapers[name]();
	catCanvas.hidden = name !== 'cat';
	runCat();
};

// The color schemes of the windows of the desktop: the title bar from left to right, the face of the windows, and their text.
const schemes = {
	'Windows Standard': undefined,
	'Hot Dog Stand': ['#ff0000', '#ff0000', '#ffff00', '#000000'],
	'High Contrast Black': ['#800080', '#800080', '#000000', '#ffffff'],
	'Rainy Day': ['#4f657d', '#8fa6bd', '#b4c0cc', '#000000'],
	Eggplant: ['#400040', '#8c5a8c', '#90b0a8', '#000000'],
	Unicorn: ['#ff3fb4', '#9a5bff', '#ffe0f4', '#330033'],
};

const schemePicker = document.querySelector('#geocities-win-scheme');

const setScheme = name => {
	schemePicker.value = name;
	const colors = schemes[name];

	for (const [index, property] of ['--win-title-start', '--win-title-end', '--win-face', '--win-text'].entries()) {
		if (colors) {
			desktop.style.setProperty(property, colors[index]);
		} else {
			desktop.style.removeProperty(property);
		}
	}
};

// The desktop themes of Microsoft Plus! 98: a wallpaper, a color scheme, pictures for all the icons, and a sound for each window that opens.
const themes = {
	standard: {wallpaper: 'none', scheme: 'Windows Standard', sound: 'chord'},
	unicorns: {wallpaper: 'unicorns', scheme: 'Unicorn', sound: 'sparkle', icons: ['🦄', '🌈', '✨', '🧁', '💖', '🎀', '🌸', '⭐', '🍭', '🦋']},
	creatures: {wallpaper: 'jungle', scheme: 'Eggplant', sound: 'roar', icons: ['🦈', '🐍', '🕷️', '🐊', '🦂', '🐅', '🦖', '🐺', '🦇', '🐙']},
	computer: {wallpaper: 'circuit', scheme: 'Rainy Day', sound: 'beep', icons: ['💾', '💿', '🔌', '🔋', '🖱️', '📟', '📀', '🖲️', '⌨️', '🧮']},
	hotdog: {wallpaper: 'mustard', scheme: 'Hot Dog Stand', sound: 'honk', icons: ['🌭', '🍟', '🥤', '🍔', '🧂', '🍦', '🥨']},
};

const originalIcons = new Map(iconItems().map(item => [item, iconPicture(item).textContent]));

const setTheme = name => {
	const theme = themes[name];
	setWallpaper(theme.wallpaper);
	setScheme(theme.scheme);
	themeSound = theme.sound;

	for (const [index, [item, icon]] of [...originalIcons].entries()) {
		iconPicture(item).textContent = theme.icons?.[index % theme.icons.length] ?? icon;
	}
};

// The Control Panel shows its icons, and each opens its part in the same window.
const controlHome = document.querySelector('#geocities-win-control-home');
const controlPanes = [...document.querySelectorAll('[data-win-control-pane]')];
const controlStatus = document.querySelector('#geocities-win-control-status');

function openControlPane(name, opener) {
	if (windowOf('control').hidden) {
		openWindow('control', opener);
	}

	controlHome.hidden = true;

	for (const pane of controlPanes) {
		pane.hidden = pane.dataset.winControlPane !== name;
	}

	controlStatus.textContent = '';
	setTitle('control', controlPanes.find(pane => !pane.hidden).querySelector('h4').textContent);
	updateTasks();
	controlPanes.find(pane => !pane.hidden).querySelector('[data-win-control-back]').focus();
}

const showControlHome = pane => {
	for (const element of controlPanes) {
		element.hidden = true;
	}

	controlHome.hidden = false;
	setTitle('control', 'Control Panel');
	updateTasks();
	controlHome.querySelector(`[data-win-control-open="${pane}"]`)?.focus();
};

for (const button of document.querySelectorAll('[data-win-control-open]')) {
	button.addEventListener('click', () => {
		openControlPane(button.dataset.winControlOpen, button);
	});
}

for (const button of document.querySelectorAll('[data-win-control-back]')) {
	button.addEventListener('click', () => {
		showControlHome(button.closest('[data-win-control-pane]').dataset.winControlPane);
	});
}

onClose.control = () => {
	showControlHome();
};

wallpaperPicker.addEventListener('change', () => {
	setWallpaper(wallpaperPicker.value);
	announce(controlStatus, wallpaperPicker.value === 'waffle' ? 'Waffle. The best wallpaper.' : 'The wallpaper changed.');
});

schemePicker.addEventListener('change', () => {
	setScheme(schemePicker.value);
	announce(controlStatus, schemePicker.value === 'Hot Dog Stand' ? 'Hot Dog Stand. It came with Windows 3.1, and it was not a joke. My eyes!' : `${schemePicker.value}. Look at the windows.`);
});

const themePicker = document.querySelector('#geocities-win-theme');

themePicker.addEventListener('change', () => {
	setTheme(themePicker.value);
	announce(controlStatus, `${themePicker.selectedOptions[0].textContent}. Look at the icons!`);
});

themeSounds.addEventListener('change', () => {
	if (themeSounds.checked) {
		audio();
		playThemeSound();
	}
});

const largeIconsToggle = document.querySelector('#geocities-win-large-icons');

largeIconsToggle.addEventListener('change', () => {
	if (largeIconsToggle.checked) {
		desktop.dataset.winLargeIcons = '';
	} else {
		delete desktop.dataset.winLargeIcons;
	}
});

document.querySelector('#geocities-win-saver-preview').addEventListener('click', event => {
	startSaver(document.querySelector('#geocities-win-saver').value, event.currentTarget);
});

// The Active Desktop makes the desktop a web page, with the Channel Bar and a news ticker over the icons. After a while, it crashes, like it did.
const webToggle = document.querySelector('#geocities-win-web');
const webPage = document.querySelector('#geocities-win-web-page');
const recoveryPage = document.querySelector('#geocities-win-recovery-page');
const channels = document.querySelector('#geocities-win-channels');
const ticker = document.querySelector('#geocities-win-ticker');
const tickerText = document.querySelector('#geocities-win-ticker-text');
const recovery = document.querySelector('#geocities-win-recovery');
let channelClicks = 0;

const crashActiveDesktop = () => {
	webPage.hidden = true;
	recoveryPage.hidden = false;
	channels.hidden = true;
	tickerText.hidden = true;
	recovery.hidden = false;
	document.querySelector('#geocities-win-recovery-restore').focus();
};

const setActiveDesktop = isOn => {
	webToggle.checked = isOn;
	channelClicks = 0;

	if (isOn) {
		desktop.dataset.winWeb = '';
	} else {
		delete desktop.dataset.winWeb;

		if (ticker.contains(document.activeElement) || channels.contains(document.activeElement)) {
			startButton.focus();
		}
	}

	webPage.hidden = !isOn;
	recoveryPage.hidden = true;
	channels.hidden = !isOn;
	ticker.hidden = !isOn;
	tickerText.hidden = false;
	recovery.hidden = true;
};

commands.web = () => {
	setActiveDesktop(!desktop.hasAttribute('data-win-web'));
};

webToggle.addEventListener('change', () => {
	setActiveDesktop(webToggle.checked);
});

document.querySelector('#geocities-win-recovery-restore').addEventListener('click', () => {
	setActiveDesktop(true);
	channels.querySelector('button').focus();
});

for (const button of channels.querySelectorAll('[data-win-channel]')) {
	button.addEventListener('click', async () => {
		channelClicks++;
		tickerText.textContent = {
			unicorn: 'UNICORN TV: A unicorn was seen in Bergen. It was a horse with an ice cream cone. ★ ',
			waffle: 'WAFFLE WEATHER: 100% chance of waffles. Brunost later in the day. ★ ',
			y2k: 'Y2K NEWS: Experts say the world ends at midnight. Other experts say it does not. ★ ',
			cheese: 'BRUNOST TODAY: The price of brunost is up 3%. Sindre is buying anyway. ★ ',
		}[button.dataset.winChannel].repeat(2);

		// The third channel is one too many for the Active Desktop.
		if (channelClicks === 3) {
			setBusy('web', true);
			await wait(1200);
			setBusy('web', false);

			// The visitor could have turned off the Active Desktop while it was busy.
			if (desktop.hasAttribute('data-win-web')) {
				crashActiveDesktop();
			}
		}
	});
}

// The date of the computer. A year from 2000 brings the Y2K bug to the desktop: the clock goes to 1900, and the icons fall down.
const dateMonth = document.querySelector('#geocities-win-date-month');
const dateYear = document.querySelector('#geocities-win-date-year');
const dateDays = [...document.querySelectorAll('[data-win-date-day]')];
let isY2K = false;

const showCalendar = () => {
	const month = Number(dateMonth.value);
	const year = Number(dateYear.value) || 1999;
	const first = new Date(year, month, 1).getDay();
	const length = new Date(year, month + 1, 0).getDate();

	for (const [index, day] of dateDays.entries()) {
		const date = index - first + 1;
		day.textContent = date >= 1 && date <= length ? String(date) : '';

		if (year === 1999 && month === 11 && date === 31) {
			day.dataset.winToday = '';
		} else {
			delete day.dataset.winToday;
		}
	}
};

dateMonth.addEventListener('change', showCalendar);
dateYear.addEventListener('input', showCalendar);
showCalendar();

// Keeps the clock of `geocities.js` at 1900 while the Y2K bug is on the desktop.
new MutationObserver(() => {
	const text = '12:00 AM 1/1/1900';

	if (isY2K && clock.textContent !== text) {
		clock.textContent = text;
	}
}).observe(clock, {childList: true, characterData: true, subtree: true});

const dropIcons = () => {
	const box = desktop.getBoundingClientRect();
	const floor = box.bottom - taskbar.offsetHeight;

	for (const item of iconItems()) {
		const itemBox = item.getBoundingClientRect();
		const offset = iconOffsets.get(item) ?? {x: 0, y: 0};
		const x = offset.x + randomInteger(-20, 20);
		const y = offset.y + (floor - itemBox.bottom) - randomInteger(0, 24);
		const rotation = `${randomInteger(-80, 80)}deg`;

		if (!reducedMotion.matches) {
			item.animate([{translate: item.style.translate || '0 0', rotate: item.style.rotate || '0deg'}, {translate: `${x}px ${y}px`, rotate: rotation}], {duration: randomInteger(500, 1100), easing: 'cubic-bezier(0.5, 0, 1, 0.5)'});
		}

		placeIcon(item, x, y);
		item.style.rotate = rotation;
	}
};

const setY2K = async isOn => {
	isY2K = isOn;

	if (isOn) {
		clock.textContent = '12:00 AM 1/1/1900';
		dropIcons();
		const answer = await ask({title: 'Y2K', icon: '🐛', text: 'The year 2000 is not supported by this computer. It thinks the year is 1900.\n\nAll the icons fell down, as gravity was different in 1900.', buttons: ['Back to 1999', 'Party Like It’s 1999']});

		if (answer === 'Back to 1999') {
			dateYear.value = '1999';
			showCalendar();
			setY2K(false);
		}
	} else {
		arrangeIcons();
		clock.textContent = new Date().toLocaleTimeString('en-US', {hour: 'numeric', minute: '2-digit'});
	}
};

document.querySelector('#geocities-win-date-apply').addEventListener('click', () => {
	const year = Number(dateYear.value);

	if (!(year >= 1980 && year <= 2099)) {
		announce(controlStatus, 'Windows 98 only knows the years from 1980 to 2099.');
	} else if (year < 2000 && dateMonth.value === '3') {
		cih();
	} else if (year >= 2000) {
		setY2K(true);
	} else {
		announce(controlStatus, year === 1999 ? 'It is 1999. As it should be.' : `It is ${year} now. Retro!`);

		if (isY2K) {
			setY2K(false);
		}
	}
});

// The test area of the Mouse Properties: two clicks fast enough open the jack-in-the-box. The slider sets how fast is fast enough, and Enter twice works too.
const jackBox = document.querySelector('#geocities-win-jack-box');
const doubleClickSpeed = document.querySelector('#geocities-win-double-click-speed');
let lastJackClick = 0;

jackBox.addEventListener('click', () => {
	const now = performance.now();
	const limit = [900, 700, 500, 350, 220][Number(doubleClickSpeed.value)];

	if (now - lastJackClick < limit) {
		const isOpen = jackBox.textContent === '🤡';
		jackBox.textContent = isOpen ? '🎁' : '🤡';
		announce(controlStatus, isOpen ? 'Back in the box.' : 'Boing! The jack-in-the-box jumped out. Your double-click works.');
		lastJackClick = 0;
	} else {
		lastJackClick = now;
	}
});

// Add New Hardware finds the scanner, and then Windows 98 crashes like it did on stage in front of Bill Gates.
const hardwareText = document.querySelector('#geocities-win-hardware-text');
const hardwareProgress = document.querySelector('#geocities-win-hardware-progress');
const hardwareNext = document.querySelector('#geocities-win-hardware-next');
const bsod = document.querySelector('#geocities-win-bsod');
const bsodQuote = document.querySelector('#geocities-win-bsod-quote');
let hardwareStep = 0;

const hardwareSteps = [
	async () => {
		hardwareText.textContent = 'Windows will now search for any new Plug and Play devices on your system. Click Next.';
	},
	async () => {
		setEnabled(hardwareNext, false);
		hardwareText.textContent = 'Searching for new Plug and Play devices…';

		for (const percent of [10, 30, 55, 80, 100]) {
			hardwareProgress.style.width = `${percent}%`;
			await wait(500);
		}

		hardwareText.textContent = 'Windows found: USB Unicorn Scanner (Plug and Play). Click Next to install it.';
		setEnabled(hardwareNext, true);
	},
	async () => {
		hardwareText.textContent = 'Installing USB Unicorn Scanner…';
		hardwareProgress.style.width = '0';
		await wait(800);

		// The scanner only crashes Windows while the wizard is on the screen.
		if (hardwareNext.checkVisibility()) {
			showBlueScreen();
		} else {
			hardwareStep = 0;
		}
	},
];

hardwareNext.addEventListener('click', () => {
	hardwareSteps[hardwareStep]?.();
	hardwareStep++;
});

const showBlueScreen = () => {
	bsodQuote.hidden = true;
	bsod.hidden = false;
	bsod.focus();
};

const continueBlueScreen = event => {
	// Shortcuts of the browser, like reload, are not “any key”.
	if (event.ctrlKey || event.metaKey) {
		return;
	}

	event.preventDefault();
	event.stopPropagation();

	// The first key shows what Bill Gates said, and the second restarts.
	if (bsodQuote.hidden) {
		bsodQuote.hidden = false;
		return;
	}

	bsod.hidden = true;
	hardwareStep = 0;
	hardwareText.textContent = 'This wizard installs the software for a new hardware device. Plug in your new scanner now, then click Next.';
	(hardwareNext.checkVisibility() ? hardwareNext : startButton).focus();
	announce(controlStatus, 'Windows restarted. The scanner works now, but it only scans unicorns.');
};

bsod.addEventListener('keydown', continueBlueScreen);
bsod.addEventListener('click', continueBlueScreen);

// Add/Remove Programs, which removes almost nothing.
const removals = {
	ie: () => ask({title: 'Add/Remove Programs', icon: '❌', text: 'Internet Explorer is part of Windows 98, and cannot be removed.\n\n(The United States Department of Justice is looking into it.)'}),
	async bonzi(button) {
		setEnabled(button, false);
		announce(controlStatus, 'Removing BonziBUDDY…');
		await wait(1500);
		setEnabled(button, true);
		announce(controlStatus, 'BonziBUDDY reinstalled himself. He wants to be your friend. Forever.');
		// Fun Stuff (`WindowsFunStuff.js`) brings him out to say so himself.
		desktop.dispatchEvent(new Event('geocities-win-bonzi'));
	},
	y2k: () => ask({title: 'Add/Remove Programs', icon: '🐛', text: 'The Y2K Bug removes itself on January 1, 2000. Probably.'}),
	furby: () => ask({title: 'Add/Remove Programs', icon: 'ℹ️', text: 'Furby Translator was removed.\n\nThe Furby still talks. All night.'}),
	async windows() {
		const answer = await ask({title: 'Add/Remove Programs', icon: '❓', text: 'Are you sure you want to remove Windows 98?', buttons: ['Yes', 'No']});

		if (answer === 'Yes') {
			await ask({title: 'Add/Remove Programs', icon: '❌', text: 'Windows cannot remove Windows while Windows is running. And Windows is always running. Nice try.'});
		}
	},
};

for (const button of document.querySelectorAll('[data-win-remove-program]')) {
	button.addEventListener('click', () => {
		removals[button.dataset.winRemoveProgram](button);
	});
}

// Y2K Fixer 2000 stops responding at 99%. Then the window is pale, the hourglass shows, and dragging the window leaves copies of it everywhere, as Windows could not draw what was behind it. Closing it asks to end the task, which ends with the illegal operation.
const fixerWindow = windowOf('fixer');
const fixerText = document.querySelector('#geocities-win-fixer-text');
const fixerProgress = document.querySelector('#geocities-win-fixer-progress');
const fixerStart = document.querySelector('#geocities-win-fixer-start');
const ghosts = [];
let lastGhost;
let fixerRun = 0;

const isFrozen = () => fixerWindow.hasAttribute('data-win-frozen');

const leaveGhost = () => {
	const position = {left: fixerWindow.offsetLeft, top: fixerWindow.offsetTop};

	if (lastGhost && Math.hypot(position.left - lastGhost.left, position.top - lastGhost.top) < 6) {
		return;
	}

	// A copy without IDs and hooks, which only looks like the window.
	const ghost = fixerWindow.cloneNode(true);

	for (const element of [ghost, ...ghost.querySelectorAll('*')]) {
		for (const attribute of [...element.attributes]) {
			if (attribute.name === 'id' || attribute.name.startsWith('data-') || attribute.name.startsWith('aria-')) {
				element.removeAttribute(attribute.name);
			}
		}
	}

	ghost.inert = true;
	ghost.setAttribute('aria-hidden', 'true');
	ghost.style.zIndex = '0';
	ghost.style.left = `${lastGhost?.left ?? position.left}px`;
	ghost.style.top = `${lastGhost?.top ?? position.top}px`;
	desktop.insertBefore(ghost, fixerWindow);
	ghosts.push(ghost);
	lastGhost = position;

	// Old copies go, so a long drag does not fill the page with copies.
	if (ghosts.length > 80) {
		ghosts.shift().remove();
	}
};

new MutationObserver(() => {
	if (isFrozen()) {
		leaveGhost();
	}
}).observe(fixerWindow, {attributes: true, attributeFilter: ['style']});

const clearGhosts = () => {
	for (const ghost of ghosts) {
		ghost.remove();
	}

	ghosts.length = 0;
	lastGhost = undefined;
};

const setFrozen = isOn => {
	if (isOn) {
		fixerWindow.dataset.winFrozen = '';
		setBusy('fixer', true);
		setTitle('fixer', 'Y2K Fixer 2000 Deluxe (Not Responding)');
		lastGhost = {left: fixerWindow.offsetLeft, top: fixerWindow.offsetTop};
	} else {
		delete fixerWindow.dataset.winFrozen;
		setBusy('fixer', false);
		setTitle('fixer', 'Y2K Fixer 2000 Deluxe');
	}

	updateTasks();
};

const resetFixer = () => {
	fixerRun++;
	fixerProgress.style.width = '0';
	fixerStart.disabled = false;
	fixerText.textContent = 'Is your computer ready for the year 2000? 99% of computers are not! Y2K Fixer 2000 fixes all your dates in minutes.';
};

fixerStart.addEventListener('click', async () => {
	const run = ++fixerRun;
	setEnabled(fixerStart, false);

	for (const [percent, message] of [[12, 'Scanning your dates…'], [31, 'Found 1,999 dates. Fixing them…'], [55, 'Turning 99 into 1999…'], [78, 'Teaching your computer to count to 2000…'], [99, 'Almost done…']]) {
		fixerText.textContent = message;
		fixerProgress.style.width = `${percent}%`;
		await wait(1100);

		if (run !== fixerRun) {
			return;
		}
	}

	setFrozen(true);
});

// While the program does not respond, closing it asks first, like Windows, and dragging leaves the copies.
const endFrozenFixer = async () => {
	const answer = await ask({title: 'Y2K Fixer 2000 Deluxe', icon: '⏳', text: 'This program is not responding. It may be busy, waiting for a response from you, or it may have stopped running.\n\nClick End Task to close the program immediately.', buttons: ['End Task', 'Wait'], opener: fixerWindow});

	if (answer !== 'End Task') {
		return;
	}

	await illegalOperation('Y2kfix', 'KERNEL32.DLL', startButton);
	setFrozen(false);
	resetFixer();
	closeWindow('fixer');
	// Windows draws the desktop again after a moment.
	await wait(800);
	clearGhosts();
};

fixerWindow.addEventListener('click', event => {
	if (isFrozen() && event.target.closest('[data-desktop-close]')) {
		event.stopPropagation();
		endFrozenFixer();
	}
}, {capture: true});

fixerWindow.addEventListener('keydown', event => {
	if (isFrozen() && event.key === 'Escape') {
		event.stopPropagation();
		endFrozenFixer();
	}
});

onClose.fixer = () => {
	if (!isFrozen()) {
		resetFixer();
	}
};

// Find searches the files of the hard drive, with the magnifying glass going around the folder.
const findForm = document.querySelector('#geocities-win-find-form');
const findName = document.querySelector('#geocities-win-find-name');
const findAnimation = document.querySelector('#geocities-win-find-animation');
const findResults = document.querySelector('#geocities-win-find-results');
const findStatus = document.querySelector('#geocities-win-find-status');

const findableFiles = [
	...myDocuments.filter(file => file !== privateFolder),
	program('SECRET.TXT', '📝', 'notepad'),
	program('FREECELL.EXE', '♠️', 'freecell'),
	program('CALC.EXE', '🧮', 'calc'),
	program('Y2KBUG.DLL', '🐛', 'fixer'),
	textFile('AUTOEXEC.BAT', texts.autoexec),
	...Array.from({length: 12}, (_, index) => program(`UNICORN${index + 1}.GIF`, '🦄', 'paint')),
];

// Each search has a number, so Find Now again starts over instead of finishing twice.
let findRun = 0;

findForm.addEventListener('submit', async event => {
	event.preventDefault();
	const run = ++findRun;
	const query = findName.value.trim().toLowerCase();
	findResults.replaceChildren();
	findAnimation.hidden = false;

	for (const folder of ['C:\\WINDOWS', 'C:\\WINDOWS\\SYSTEM', 'C:\\MY DOCUMENTS']) {
		findStatus.textContent = `Searching ${folder}…`;
		await wait(600);

		if (run !== findRun) {
			return;
		}
	}

	findAnimation.hidden = true;

	if (query === 'girlfriend' || query === 'kjæreste') {
		announce(findStatus, '0 file(s) found. Not even on the Internet.');
		return;
	}

	const pattern = query === '' || query === '*' || query === '*.*' ? '' : query.replace(/^\*/, '').replace(/\*$/, '');
	const found = findableFiles.filter(file => file.name.toLowerCase().includes(pattern));
	showFiles(findResults, findStatus, found);
	announce(findStatus, found.length === 0 ? '0 file(s) found. Try homework, unicorn, or *.' : `${found.length} file(s) found${pattern === 'unicorn' ? ', and 1,987 more unicorns that did not fit' : ''}.`);
});

// Find is for typing, like Run.
onOpen.find = () => {
	findName.select();
	findName.focus();
};

// Close Program lists what runs, and ends it for real. Ctrl+Alt+Del opens it, and pressing it again restarts the computer.
const tasksList = document.querySelector('#geocities-win-tasks-list');
const tasksStatus = document.querySelector('#geocities-win-tasks-status');
const tray = document.querySelector('#geocities-win-tray');
const backgroundTasks = new Set(['Explorer', 'Systray', 'Glitter', 'Napster', 'Y2kbug']);

const listTasks = () => {
	const names = [...openOrder.filter(appWindow => appWindow !== windowOf('tasks')).map(appWindow => titleOf(appWindow)), ...backgroundTasks];
	tasksList.replaceChildren(...names.map(name => new Option(name === 'Glitter' ? 'Glitter (Not responding)' : name, name)));
	tasksList.selectedIndex = 0;
};

const endTask = async name => {
	const appWindow = openOrder.find(element => titleOf(element) === name);

	if (appWindow) {
		if (appWindow === fixerWindow && isFrozen()) {
			await illegalOperation('Y2kfix', 'KERNEL32.DLL', tasksList);
			setFrozen(false);
			resetFixer();
			clearGhosts();
		}

		appWindow.hidden = true;
		announce(tasksStatus, `${name} was ended.`);
		listTasks();
		return;
	}

	switch (name) {
		case 'Explorer': {
			// Without Explorer, there are no icons and no taskbar, until Windows starts it again.
			iconList.hidden = true;
			taskbar.hidden = true;
			announce(tasksStatus, 'Explorer was ended. The icons and the taskbar are gone! Windows will start Explorer again in a moment.');
			await wait(4000);
			iconList.hidden = false;
			taskbar.hidden = false;
			announce(tasksStatus, 'Explorer is back. It always comes back.');
			break;
		}

		case 'Systray': {
			tray.hidden = true;
			backgroundTasks.delete('Systray');
			announce(tasksStatus, 'Systray was ended. The volume knob is gone, until Windows starts again.');
			break;
		}

		case 'Glitter': {
			await ask({title: 'Glitter', icon: '🦄', text: 'Glitter.exe cannot be ended. Unicorns are immortal.', opener: tasksList});
			break;
		}

		case 'Napster': {
			const answer = await ask({title: 'Napster', icon: '🎵', text: 'Napster is downloading Sandstorm.mp3 (3%). If you end it, it starts over from 0%. Are you sure?', buttons: ['Yes', 'No'], opener: tasksList});

			if (answer === 'Yes') {
				backgroundTasks.delete('Napster');
				announce(tasksStatus, 'Napster was ended. Your big brother will be so angry.');
			}

			break;
		}

		case 'Y2kbug': {
			announce(tasksStatus, 'Y2kbug was ended… and it started again. It will be back on January 1, 2000.');
			break;
		}

		default:
	}

	listTasks();
};

document.querySelector('#geocities-win-tasks-end').addEventListener('click', () => {
	if (tasksList.value) {
		endTask(tasksList.value);
	}
});

document.querySelector('#geocities-win-tasks-shut-down').addEventListener('click', () => {
	closeWindow('tasks');
	desktop.dispatchEvent(new Event('geocities-win-shut-down'));
});

onOpen.tasks = () => {
	listTasks();
	announce(tasksStatus, '');
	tasksList.focus();
};

desktop.addEventListener('keydown', event => {
	if (!(event.ctrlKey && event.altKey && (event.key === 'Delete' || event.key === 'Backspace'))) {
		return;
	}

	event.preventDefault();

	// Windows is not running yet while it starts.
	if (!boot.hidden) {
		return;
	}

	if (windowOf('tasks').hidden) {
		openWindow('tasks');
		centerWindow(windowOf('tasks'));
	} else {
		restart({isImproper: true});
	}
});

// The Welcome to Windows 98 screen, with its tour, and a box that checks itself again.
const welcomeText = document.querySelector('#geocities-win-welcome-text');
const welcomeNext = document.querySelector('#geocities-win-welcome-next');
const welcomeShow = document.querySelector('#geocities-win-welcome-show');
const tour = [
	'Discover Windows 98, lesson 1: the mouse. Click once to select. Click twice to open. Click three times to… nothing. You are a natural.',
	'Lesson 2: the Start button. To stop your computer, click Start. Microsoft is very proud of this.',
	'Lesson 3: the Internet. The Internet is on your desktop now. And in your Start menu. And in your folders. You cannot escape it.',
	'Lesson 4: Y2K. Windows 98 is ready for the year 2000.* (*Mostly. Do not set the date to 2000 in the Control Panel.)',
	'You finished the tour! Your computer is now 98% easier to use.',
];
let tourStep = 0;

const welcomeTopics = {
	register() {
		welcomeNext.hidden = true;

		if (dialUp.state === 'connected') {
			announce(welcomeText, 'Thank you for registering Windows 98! Your registration number is 1999-WAFFLE-2000. Microsoft now knows the name of your hamster.');
		} else {
			announce(welcomeText, 'Registering needs the Internet. Connect with Dial-Up Networking first, then click Register Now again.');
			openWindow('dialup');
		}
	},
	connect() {
		welcomeNext.hidden = true;
		announce(welcomeText, 'Connect to the Internet with Dial-Up Networking. Make sure nobody is on the phone.');
		openWindow('dialup');
	},
	discover() {
		tourStep = 0;
		welcomeNext.hidden = false;
		announce(welcomeText, tour[0]);
	},
	maintain() {
		welcomeNext.hidden = true;
		announce(welcomeText, 'Windows defragments your hard drive every night at 3 AM, if your computer is on. Mamma turns it off at 10 PM.');
		openWindow('computer');
	},
};

for (const button of document.querySelectorAll('[data-win-welcome-topic]')) {
	button.addEventListener('click', () => {
		welcomeTopics[button.dataset.winWelcomeTopic]();
	});
}

welcomeNext.addEventListener('click', () => {
	tourStep++;
	announce(welcomeText, tour[tourStep]);

	if (tourStep === tour.length - 1) {
		welcomeNext.hidden = true;
		welcomeNext.closest('[data-desktop-window]').querySelector('[data-win-welcome-topic="discover"]').focus();
	}
});

welcomeShow.addEventListener('change', async () => {
	if (!welcomeShow.checked) {
		await wait(1000);
		welcomeShow.checked = true;
		announce(welcomeText, 'Windows checked the box again. It knows that you want to see this screen every time.');
	}
});

// The log on of Windows 98, where any password works, and Cancel works too.
const logOnForm = document.querySelector('#geocities-win-logon-form');
const logOnUser = document.querySelector('#geocities-win-logon-user');
const logOnPassword = document.querySelector('#geocities-win-logon-password');
let isLoggingOn = false;

// Windows Update wants one more restart after each restart, a few times.
let updateRestarts = 0;

const askForAnotherRestart = async () => {
	if (!boot.hidden) {
		return;
	}

	if (updateRestarts >= 4) {
		updateRestarts = 0;
		await ask({title: 'Windows Update', icon: '🔄', text: 'Windows Update is done for today. 1,995 updates are left. See you tomorrow!'});
		return;
	}

	const answer = await ask({title: 'Windows Update', icon: '🔄', text: `Windows Update installed update ${updateRestarts + 1} of 1,999.\n\nYou must restart your computer before the new settings will take effect. Do you want to restart your computer now?`, buttons: ['Yes', 'No']});

	if (answer === 'Yes') {
		updateRestarts++;
		restart();
	} else {
		updateRestarts = 0;
	}
};

const logOn = message => {
	isLoggingOn = false;
	closeWindow('logon');
	toast(message);
	openWindow('welcome', startButton);

	if (updateRestarts > 0) {
		setTimeout(askForAnotherRestart, 1200);
	}
};

logOnForm.addEventListener('submit', event => {
	event.preventDefault();
	logOn(`Welcome, ${logOnUser.value.trim() || 'nobody'}! ${logOnPassword.value ? 'Any password works, by the way.' : 'No password. Very secure.'}`);
});

document.querySelector('#geocities-win-logon-cancel').addEventListener('click', () => {
	logOn('You pressed Cancel, and Windows logged you on anyway. Security in 1998!');
});

onOpen.logon = () => {
	isLoggingOn = true;
	logOnPassword.value = '';
	centerWindow(windowOf('logon'));
	logOnPassword.focus();
};

// Closing the log on, like with Escape, is the same as Cancel.
onClose.logon = () => {
	if (isLoggingOn) {
		logOn('You closed the log on, and Windows logged you on anyway. Security in 1998!');
	}
};

const closeAllWindows = () => {
	// A restart closes the log on too, which is not a Cancel.
	isLoggingOn = false;
	setFrozen(false);
	clearGhosts();
	resetFixer();

	for (const appWindow of [...openOrder]) {
		appWindow.hidden = true;
	}
};

commands.logoff = async () => {
	const answer = await ask({title: 'Log Off Windows', icon: '🔑', text: 'Are you sure you want to log off?', buttons: ['Yes', 'No'], opener: startButton});

	if (answer === 'Yes') {
		closeAllWindows();
		openWindow('logon', startButton);
	}
};

// Restart shows the startup screen of Windows 98, with the clouds and the moving bar, and then the log on. Escape skips it.
const boot = document.querySelector('#geocities-win-boot');
const bootText = document.querySelector('#geocities-win-boot-text');
const bootLogo = document.querySelector('#geocities-win-boot-logo');
let bootRun = 0;

const finishBoot = () => {
	bootRun++;
	boot.hidden = true;
	delete boot.dataset.state;
	tray.hidden = false;
	backgroundTasks.add('Systray');
	openWindow('logon', startButton);
};

async function restart({isImproper = false} = {}) {
	const run = ++bootRun;
	closeStartMenu();
	leaveDosMode();
	closeAllWindows();
	boot.hidden = false;
	bootLogo.hidden = true;
	bootText.hidden = false;
	boot.focus();

	// After a restart that was not a proper shut down, ScanDisk checks the hard drive first, like every time in 1998.
	if (isImproper) {
		boot.dataset.state = 'scandisk';
		bootText.textContent = 'Because Windows was not properly shut down, one or more of your disks may have errors on it.\n\nScanDisk will now check your drives. To avoid seeing this message, always shut down your computer by selecting Shut Down from the Start menu.\n';

		for (const step of ['Media descriptor', 'File allocation tables', 'Directory structure', 'File system', 'Free space', 'Surface scan (1,999 GIFs)']) {
			await wait(550);

			if (run !== bootRun) {
				return;
			}

			bootText.textContent += `\n  ✓ ${step}`;
		}

		await wait(900);

		if (run !== bootRun) {
			return;
		}

		delete boot.dataset.state;
	}

	bootText.textContent = 'Starting Windows 98…';
	await wait(1500);

	if (run !== bootRun) {
		return;
	}

	bootText.hidden = true;
	bootLogo.hidden = false;
	playSound('startup');
	await wait(3500);

	if (run === bootRun) {
		finishBoot();
	}
}

boot.addEventListener('keydown', event => {
	if (event.key === 'Escape') {
		event.stopPropagation();
		finishBoot();
	}
});

// The 3D Maze screen saver: a maze of brick walls, walked with a hand on the right wall. The gray rocks turn the world upside down, the rat runs around, and the smiley is the way out. Any key, a tap, or moving the mouse stops it.
const maze = document.querySelector('#geocities-win-maze');
const mazeCanvas = document.querySelector('#geocities-win-maze-canvas');
const mazeContext = mazeCanvas.getContext('2d');
const mazeText = document.querySelector('#geocities-win-maze-text');
const mazeView = document.createElement('canvas');
mazeView.width = mazeCanvas.width;
mazeView.height = mazeCanvas.height;
const viewContext = mazeView.getContext('2d');
const mazeCells = 8;
const directions = [[1, 0], [0, 1], [-1, 0], [0, -1]];
let mazeState;
let mazeFrame;
let mazeOpener;

// A brick texture of 64 × 64, with darker mortar, like the walls of 3D Maze.
const brickTexture = (() => {
	const canvas = document.createElement('canvas');
	canvas.width = 64;
	canvas.height = 64;
	const context = canvas.getContext('2d');
	context.fillStyle = '#7a7a72';
	context.fillRect(0, 0, 64, 64);

	for (let row = 0; row < 8; row++) {
		for (let column = -1; column < 4; column++) {
			const x = (column * 16) + (row % 2 === 0 ? 0 : 8);
			context.fillStyle = `hsl(${8 + ((row * 7 + column * 13) % 10)} 55% ${34 + ((row * 3 + column * 5) % 8)}%)`;
			context.fillRect(x + 1, (row * 8) + 1, 14, 6);
		}
	}

	return canvas;
})();

// A picture for each kind of thing in the maze, drawn on its own small canvas.
const spriteOf = draw => {
	const canvas = document.createElement('canvas');
	canvas.width = 64;
	canvas.height = 64;
	draw(canvas.getContext('2d'));
	return canvas;
};

const smileySprite = spriteOf(context => {
	context.fillStyle = 'rgb(255 230 0 / 0.85)';
	context.beginPath();
	context.arc(32, 32, 26, 0, Math.PI * 2);
	context.fill();
	context.fillStyle = '#000000';
	context.fillRect(22, 22, 5, 8);
	context.fillRect(37, 22, 5, 8);
	context.lineWidth = 3;
	context.beginPath();
	context.arc(32, 34, 14, 0.2 * Math.PI, 0.8 * Math.PI);
	context.stroke();
});

const ratSprite = spriteOf(context => {
	context.font = '40px system-ui, "Apple Color Emoji", "Segoe UI Emoji", sans-serif';
	context.textAlign = 'center';
	context.fillText('🐀', 32, 56);
});

const rockSprite = spriteOf(context => {
	context.fillStyle = '#a0a0a0';
	context.strokeStyle = '#505050';
	context.lineWidth = 2;
	context.beginPath();

	for (const [x, y] of [[32, 6], [54, 26], [46, 54], [18, 54], [10, 26]]) {
		context.lineTo(x, y);
	}

	context.closePath();
	context.fill();
	context.stroke();
	context.fillStyle = '#ffffff';
	context.font = 'bold 9px sans-serif';
	context.textAlign = 'center';
	context.fillText('OpenGL', 32, 36);
});

// A random maze, carved like a depth-first search, in a grid where the odd squares are the rooms and the even ones are walls.
const makeMaze = () => {
	const size = (mazeCells * 2) + 1;
	const grid = Array.from({length: size}, () => Array.from({length: size}, () => 1));
	const stack = [[1, 1]];
	grid[1][1] = 0;

	while (stack.length > 0) {
		const [x, y] = stack.at(-1);
		const options = directions.map(([dx, dy]) => [x + (dx * 2), y + (dy * 2), dx, dy]).filter(([nx, ny]) => nx > 0 && ny > 0 && nx < size - 1 && ny < size - 1 && grid[ny][nx] === 1);

		if (options.length === 0) {
			stack.pop();
			continue;
		}

		const [nx, ny, dx, dy] = randomItem(options);
		grid[y + dy][x + dx] = 0;
		grid[ny][nx] = 0;
		stack.push([nx, ny]);
	}

	const rooms = [];

	for (let y = 1; y < size; y += 2) {
		for (let x = 1; x < size; x += 2) {
			rooms.push([x, y]);
		}
	}

	const things = [
		{kind: 'exit', x: size - 2, y: size - 2},
		...Array.from({length: 3}, () => ({kind: 'rock', x: 0, y: 0})),
	];

	for (const thing of things.filter(thing => thing.kind === 'rock')) {
		const [x, y] = randomItem(rooms.filter(([x, y]) => x + y > 4 && x + y < (size * 2) - 6));
		thing.x = x;
		thing.y = y;
	}

	const rat = {kind: 'rat', x: 1, y: size - 2, from: [1, size - 2], to: [1, size - 2], progress: 1};
	return {grid, size, things: [...things, rat], rat, x: 1, y: 1, direction: 0, from: {x: 1, y: 1, angle: 0}, to: {x: 1, y: 1, angle: 0}, progress: 1, isUpsideDown: false, roll: 0};
};

const isOpen = (x, y) => mazeState.grid[y]?.[x] === 0;

// The next step: try the right, then straight, then the left, then back. Upside down, the hands swap.
const nextStep = () => {
	const {x, y, direction, isUpsideDown} = mazeState;
	const turns = isUpsideDown ? [3, 0, 1, 2] : [1, 0, 3, 2];

	for (const turn of turns) {
		const newDirection = (direction + turn) % 4;
		const [dx, dy] = directions[newDirection];

		if (isOpen(x + dx, y + dy)) {
			return {direction: newDirection, x: x + (dx * 2), y: y + (dy * 2)};
		}
	}
};

// The angle of a direction, turned the short way around from the angle now.
const nearestAngle = (angle, direction) => {
	let target = direction * Math.PI / 2;

	while (target - angle > Math.PI) {
		target -= Math.PI * 2;
	}

	while (target - angle < -Math.PI) {
		target += Math.PI * 2;
	}

	return target;
};

// Plans the next move: a turn on the spot, or a step forward to the next room.
const planMove = () => {
	const step = nextStep();
	const {angle} = mazeState.to;
	mazeState.from = {x: mazeState.x, y: mazeState.y, angle};

	if (step.direction === mazeState.direction) {
		mazeState.to = {x: step.x, y: step.y, angle};
		mazeState.x = step.x;
		mazeState.y = step.y;
	} else {
		mazeState.to = {x: mazeState.x, y: mazeState.y, angle: nearestAngle(angle, step.direction)};
		mazeState.direction = step.direction;
	}

	mazeState.progress = 0;
};

const moveRat = () => {
	const {rat} = mazeState;
	const options = directions.filter(([dx, dy]) => isOpen(rat.x + dx, rat.y + dy));
	const [dx, dy] = randomItem(options);
	rat.from = [rat.x, rat.y];
	rat.x += dx * 2;
	rat.y += dy * 2;
	rat.to = [rat.x, rat.y];
	rat.progress = 0;
};

const drawMaze = () => {
	const {width, height} = mazeView;
	const {from, to, progress} = mazeState;
	const ease = progress * progress * (3 - (2 * progress));
	const px = from.x + ((to.x - from.x) * ease) + 0.5;
	const py = from.y + ((to.y - from.y) * ease) + 0.5;
	const angle = from.angle + ((to.angle - from.angle) * ease);
	const depths = new Float32Array(width);

	// The ceiling, white tiles, and the floor, gray, like 3D Maze.
	viewContext.fillStyle = '#d8d8d8';
	viewContext.fillRect(0, 0, width, height / 2);
	viewContext.fillStyle = '#5a5a50';
	viewContext.fillRect(0, height / 2, width, height / 2);

	for (let column = 0; column < width; column++) {
		const rayAngle = angle + Math.atan(((column / width) - 0.5) * 1.2);
		const dx = Math.cos(rayAngle);
		const dy = Math.sin(rayAngle);
		let mapX = Math.floor(px);
		let mapY = Math.floor(py);
		const stepX = dx < 0 ? -1 : 1;
		const stepY = dy < 0 ? -1 : 1;
		const deltaX = Math.abs(1 / dx);
		const deltaY = Math.abs(1 / dy);
		let sideX = (dx < 0 ? px - mapX : mapX + 1 - px) * deltaX;
		let sideY = (dy < 0 ? py - mapY : mapY + 1 - py) * deltaY;
		let side = 0;

		while (mazeState.grid[mapY]?.[mapX] === 0) {
			if (sideX < sideY) {
				sideX += deltaX;
				mapX += stepX;
				side = 0;
			} else {
				sideY += deltaY;
				mapY += stepY;
				side = 1;
			}
		}

		const distance = (side === 0 ? sideX - deltaX : sideY - deltaY) * Math.cos(rayAngle - angle);
		depths[column] = distance;
		const wallHeight = Math.min(height / Math.max(distance, 0.01), height * 8);
		const hit = side === 0 ? py + (distance / Math.cos(rayAngle - angle) * dy) : px + (distance / Math.cos(rayAngle - angle) * dx);
		const textureX = Math.floor((hit - Math.floor(hit)) * 64);
		viewContext.drawImage(brickTexture, textureX, 0, 1, 64, column, (height - wallHeight) / 2, 1, wallHeight);

		// One side of the walls is darker, and far walls fade, so the corners show.
		viewContext.fillStyle = `rgb(0 0 0 / ${Math.min((side * 0.25) + (distance * 0.04), 0.7)})`;
		viewContext.fillRect(column, (height - wallHeight) / 2, 1, wallHeight);
	}

	// The things of the maze, far ones first, drawn only where no wall is in front of them.
	const {rat} = mazeState;
	const ratEase = Math.min(rat.progress, 1);
	const placeOf = thing => thing.kind === 'rat'
		? [rat.from[0] + ((rat.to[0] - rat.from[0]) * ratEase) + 0.5, rat.from[1] + ((rat.to[1] - rat.from[1]) * ratEase) + 0.5]
		: [thing.x + 0.5, thing.y + 0.5];
	const visible = mazeState.things.map(thing => {
		const [x, y] = placeOf(thing);
		return {thing, x, y, distance: Math.hypot(x - px, y - py)};
	}).sort((first, second) => second.distance - first.distance);

	for (const {thing, x, y, distance} of visible) {
		const relative = Math.atan2(y - py, x - px) - angle;
		const wrapped = Math.atan2(Math.sin(relative), Math.cos(relative));

		if (Math.abs(wrapped) > 0.8 || distance < 0.2) {
			continue;
		}

		const screenX = ((Math.tan(wrapped) / 1.2) + 0.5) * width;
		const size = Math.min(height / distance, height * 2) * (thing.kind === 'rat' ? 0.5 : 0.7);
		const sprite = {exit: smileySprite, rock: rockSprite, rat: ratSprite}[thing.kind];
		const top = thing.kind === 'rat' ? (height / 2) + (height / distance / 2) - size : (height - size) / 2;

		for (let column = Math.max(Math.floor(screenX - (size / 2)), 0); column < Math.min(screenX + (size / 2), width); column++) {
			if (depths[column] > distance * Math.cos(wrapped)) {
				const spriteX = Math.floor((column - (screenX - (size / 2))) / size * 64);
				viewContext.drawImage(sprite, spriteX, 0, 1, 64, column, top, 1, size);
			}
		}
	}

	// Upside down, the whole view turns over, slowly.
	mazeContext.save();
	mazeContext.fillStyle = '#000000';
	mazeContext.fillRect(0, 0, width, height);
	mazeContext.translate(width / 2, height / 2);
	mazeContext.rotate(mazeState.roll);
	mazeContext.drawImage(mazeView, -width / 2, -height / 2);
	mazeContext.restore();
};

// The other screen savers of the Display Properties use the screen of the maze: Flying Windows, with the logos of Windows that fly out of space toward the visitor, and the Scrolling Marquee, with a text that the visitor writes.
const marqueeText = document.querySelector('#geocities-win-marquee-text');
let saverKind = 'maze';
let flyingLogos = [];
const marquee = {x: 0, y: 100, color: '#ffff00'};

const newFlyingLogo = (isFar = true) => ({x: (Math.random() * 2) - 1, y: (Math.random() * 2) - 1, z: isFar ? 2 + Math.random() : 0.3 + (Math.random() * 2.5), wave: Math.random() * Math.PI * 2});

// The flag of Windows: four squares in red, green, blue, and yellow, that wave, with a black trail of stripes on the left.
const drawWindowsLogo = (x, y, size, wave) => {
	const cell = size / 2;

	for (const [index, color] of ['#ff2a2a', '#2ad42a', '#2a5aff', '#ffd400'].entries()) {
		const column = index % 2;
		const row = Math.floor(index / 2);
		const bend = Math.sin(wave + (column * 1.2)) * size * 0.08;
		mazeContext.fillStyle = color;
		mazeContext.fillRect(Math.round(x + (column * (cell + (size * 0.06)))), Math.round(y + (row * (cell + (size * 0.06))) + bend), Math.ceil(cell), Math.ceil(cell));
	}
};

const drawFlying = () => {
	mazeContext.fillStyle = '#000000';
	mazeContext.fillRect(0, 0, mazeCanvas.width, mazeCanvas.height);

	for (const logo of flyingLogos.toSorted((first, second) => second.z - first.z)) {
		const size = 14 / logo.z;
		drawWindowsLogo(160 + (logo.x / logo.z * 160) - (size / 2), 100 + (logo.y / logo.z * 100) - (size / 2), size, logo.wave);
	}
};

const drawMarquee = () => {
	mazeContext.fillStyle = '#000000';
	mazeContext.fillRect(0, 0, mazeCanvas.width, mazeCanvas.height);
	mazeContext.fillStyle = marquee.color;
	mazeContext.font = 'bold 36px "Times New Roman", serif';
	mazeContext.textBaseline = 'middle';
	mazeContext.fillText(marqueeText.value || 'Windows 98', marquee.x, marquee.y);
};

const drawSaver = () => {
	({maze: drawMaze, flying: drawFlying, marquee: drawMarquee})[saverKind]();
};

const moveOtherSaver = elapsed => {
	if (saverKind === 'flying') {
		for (const logo of flyingLogos) {
			logo.z -= elapsed * 0.5;
			logo.wave += elapsed * 6;

			if (logo.z < 0.2 || Math.abs(logo.x / logo.z) > 1.2 || Math.abs(logo.y / logo.z) > 1.2) {
				Object.assign(logo, newFlyingLogo());
			}
		}
	} else {
		marquee.x -= elapsed * 90;
		const width = mazeContext.measureText(marqueeText.value || 'Windows 98').width;

		if (marquee.x < -width) {
			marquee.x = mazeCanvas.width;
			marquee.y = randomInteger(30, 170);
			marquee.color = randomItem(['#ffff00', '#00ffff', '#ff00ff', '#00ff00', '#ffffff', '#ff8000']);
		}
	}

	drawSaver();
};

let lastMazeTime;

const mazeLoop = time => {
	const elapsed = Math.min((time - (lastMazeTime ?? time)) / 1000, 0.1);
	lastMazeTime = time;

	if (saverKind !== 'maze') {
		moveOtherSaver(elapsed);
		mazeFrame = requestAnimationFrame(mazeLoop);
		return;
	}

	const isTurning = mazeState.from.x === mazeState.to.x && mazeState.from.y === mazeState.to.y;
	mazeState.progress += elapsed * (isTurning ? 1.6 : 1.2);
	mazeState.rat.progress += elapsed * 1.5;

	if (mazeState.rat.progress >= 1) {
		moveRat();
	}

	const targetRoll = mazeState.isUpsideDown ? Math.PI : 0;
	mazeState.roll += clamp(targetRoll - mazeState.roll, -elapsed * 2, elapsed * 2);

	if (mazeState.progress >= 1) {
		mazeState.progress = 1;
		const thing = mazeState.things.find(thing => thing.kind !== 'rat' && thing.x === mazeState.x && thing.y === mazeState.y);

		if (thing?.kind === 'exit') {
			mazeState = makeMaze();
		} else if (thing?.kind === 'rock') {
			mazeState.things.splice(mazeState.things.indexOf(thing), 1);
			mazeState.isUpsideDown = !mazeState.isUpsideDown;
		}

		planMove();
	}

	drawMaze();
	mazeFrame = requestAnimationFrame(mazeLoop);
};

const runMaze = () => {
	cancelAnimationFrame(mazeFrame);
	lastMazeTime = undefined;

	if (!maze.hidden && isDesktopVisible() && !reducedMotion.matches) {
		mazeFrame = requestAnimationFrame(mazeLoop);
	}
};

visibilityListeners.add(runMaze);
reducedMotion.addEventListener('change', runMaze);

const saverNames = {maze: '3D Maze', flying: 'Flying Windows', marquee: 'Scrolling Marquee'};

function startSaver(kind, opener) {
	closeStartMenu();
	saverKind = kind;
	mazeOpener = opener;
	mazeMouse = undefined;
	mazeState = makeMaze();
	flyingLogos = Array.from({length: 24}, () => newFlyingLogo(false));
	mazeContext.font = 'bold 36px "Times New Roman", serif';
	const textWidth = mazeContext.measureText(marqueeText.value || 'Windows 98').width;
	// With reduced motion, the text stands still in the middle.
	marquee.x = reducedMotion.matches ? (mazeCanvas.width - textWidth) / 2 : mazeCanvas.width;
	marquee.y = 100;
	maze.setAttribute('aria-label', `The ${saverNames[kind]} screen saver`);
	maze.hidden = false;
	maze.focus();
	mazeText.textContent = reducedMotion.matches ? 'The screen saver stands still, as you prefer less motion. Press any key or tap to stop.' : 'Press any key or tap to stop the screen saver.';
	drawSaver();
	runMaze();
}

const stopMaze = () => {
	if (maze.hidden) {
		return;
	}

	cancelAnimationFrame(mazeFrame);
	maze.hidden = true;
	(mazeOpener?.checkVisibility() ? mazeOpener : startButton).focus();
};

commands.maze = opener => {
	startSaver('maze', opener);
};

maze.addEventListener('keydown', event => {
	if (event.ctrlKey || event.metaKey) {
		return;
	}

	event.preventDefault();
	event.stopPropagation();
	stopMaze();
});

// A tap stops it with its click, not its press, as the click of a press that hid the maze would land on the icon under it and open it.
maze.addEventListener('click', stopMaze);

// The mouse has to move a bit, as a mouse that is touched by accident should not stop a screen saver.
let mazeMouse;

maze.addEventListener('pointermove', event => {
	if (event.pointerType !== 'mouse') {
		return;
	}

	mazeMouse ??= {x: event.clientX, y: event.clientY};

	if (Math.hypot(event.clientX - mazeMouse.x, event.clientY - mazeMouse.y) > 40) {
		mazeMouse = undefined;
		stopMaze();
	}
});

// Too many open windows fill up the 32 MB of memory, like on a real computer of 1999: first a warning with a way to close programs, and then not even enough memory to say so. Each warning comes once, until windows close again.
let memoryLevel = 0;

function checkMemory() {
	const count = openOrder.filter(appWindow => appWindow !== messageWindow).length;
	const level = count >= 10 ? 2 : (count >= 7 ? 1 : 0);

	if (level <= memoryLevel) {
		memoryLevel = Math.min(memoryLevel, level);
		return;
	}

	memoryLevel = level;

	// The window that just opened shows first, and the warning comes over it, unless Windows is restarting by then.
	setTimeout(async () => {
		if (!boot.hidden) {
			return;
		}

		if (level === 2) {
			await ask({title: 'Out of Memory', icon: '❌', text: 'There is not enough memory to show the message that there is not enough memory.'});
			return;
		}

		const answer = await ask({title: 'Insufficient Memory', icon: '⚠️', text: `Your computer is low on memory. ${count} programs are open, and it only has 32 MB.\n\nTo free memory, close some programs.`, buttons: ['Close Programs', 'OK']});

		if (answer === 'Close Programs') {
			openWindow('tasks', startButton);
			centerWindow(windowOf('tasks'));
		}
	}, 500);
}

// Show Desktop of the Quick Launch bar hides all the windows, and shows them again on the next press, or when a window opens or its taskbar button is pressed.
const showDesktopButton = document.querySelector('#geocities-win-show-desktop');

function setDesktopShown(isShown) {
	if (isShown) {
		desktop.dataset.winDesktopShown = '';
	} else {
		delete desktop.dataset.winDesktopShown;
	}

	showDesktopButton.setAttribute('aria-pressed', String(isShown));
}

showDesktopButton.addEventListener('click', () => {
	setDesktopShown(!('winDesktopShown' in desktop.dataset));
});

// The arrow of Windows 95 points at the Start button until the first click on it, while no windows are open.
const beginHint = document.querySelector('#geocities-win-begin-hint');
let hasBegun = load('geocities-win-begun', false);

// It runs with each change of the windows, which the watcher of `hidden` sees, so it only changes the attribute when it has to, or it would watch itself forever.
function updateBeginHint() {
	const isHidden = hasBegun || openOrder.length > 0;

	if (beginHint.hidden !== isHidden) {
		beginHint.hidden = isHidden;
	}
}

startButton.addEventListener('click', () => {
	hasBegun = true;
	save('geocities-win-begun', true);
	updateBeginHint();
});

updateBeginHint();

// Pressing Shift five times asks about StickyKeys, like in the middle of every game of 1999. It asks once a visit.
let shiftPresses = [];
let hasAskedAboutStickyKeys = false;

desktop.addEventListener('keydown', async event => {
	// Shift in a game, like the flippers of 3D Pinball, or in a text, does not count, so the question does not cost a ball.
	if (event.key !== 'Shift' || event.repeat || hasAskedAboutStickyKeys || event.target.matches('input, textarea, canvas, [role="application"]')) {
		return;
	}

	const now = performance.now();
	shiftPresses = [...shiftPresses.filter(time => now - time < 3000), now];

	if (shiftPresses.length < 5) {
		return;
	}

	hasAskedAboutStickyKeys = true;
	const answer = await ask({title: 'StickyKeys', icon: '⌨️', text: 'You pressed the SHIFT key five times. StickyKeys lets you use the SHIFT, CTRL, ALT, or Windows Logo keys by pressing one key at a time.\n\nDo you want to turn on StickyKeys?', buttons: ['OK', 'Cancel', 'Settings']});

	if (answer === 'OK') {
		toast('StickyKeys is on. Everything is sticky now, like syrup on a waffle.');
	} else if (answer === 'Settings') {
		await ask({title: 'Accessibility Properties', icon: '♿', text: 'There are no settings. There is only StickyKeys. It will ask again next time you play a game.'});
	}
});

// Shy icons run away from the mouse pointer. An icon in a corner has nowhere to go, and the keyboard still opens them all.
const shyIcons = document.querySelector('#geocities-win-shy-icons');
let shyFrame;

const fleeFrom = (x, y) => {
	if (iconList.hidden) {
		return;
	}

	const desktopBox = desktop.getBoundingClientRect();
	const floor = desktopBox.bottom - taskbar.offsetHeight;

	for (const item of iconItems()) {
		if (item.hidden) {
			continue;
		}

		const box = item.getBoundingClientRect();
		const dx = box.left + (box.width / 2) - x;
		const dy = box.top + (box.height / 2) - y;
		const distance = Math.hypot(dx, dy);

		if (distance > 80) {
			continue;
		}

		const angle = distance === 0 ? Math.random() * Math.PI * 2 : Math.atan2(dy, dx);
		const moveX = clamp(Math.cos(angle) * (80 - distance), desktopBox.left - box.left, desktopBox.right - box.right);
		const moveY = clamp(Math.sin(angle) * (80 - distance), desktopBox.top - box.top, floor - box.bottom);
		const offset = iconOffsets.get(item) ?? {x: 0, y: 0};
		placeIcon(item, offset.x + moveX, offset.y + moveY);
	}
};

desktop.addEventListener('pointermove', event => {
	// A pressed button means a drag, like of an icon, which should not run away from the pointer that holds it.
	if (!shyIcons.checked || event.pointerType !== 'mouse' || event.buttons !== 0 || shyFrame) {
		return;
	}

	shyFrame = requestAnimationFrame(() => {
		shyFrame = undefined;
		fleeFrom(event.clientX, event.clientY);
	});
});

shyIcons.addEventListener('change', () => {
	if (shyIcons.checked) {
		announce(controlStatus, 'The icons are shy now. Try to catch one with the mouse!');
	} else {
		arrangeIcons();
		announce(controlStatus, 'The icons came back. They are not shy anymore.');
	}
});

// The Kit-Cat Klock wallpaper: a black cat clock whose eyes and tail swing from side to side every second, which blinks now and then, and shows the real time. It stands still for visitors who prefer less motion.
const catCanvas = document.querySelector('#geocities-win-cat');
const catContext = catCanvas.getContext('2d');
let catFrame;

const drawCat = (time = 0) => {
	const context = catContext;
	const swing = reducedMotion.matches ? 0 : Math.sin(time / 1000 * Math.PI);
	const isBlinking = !reducedMotion.matches && (time % 4000) < 150;
	context.clearRect(0, 0, 48, 112);

	// The tail, which swings like a pendulum.
	context.save();
	context.translate(24, 76);
	context.rotate(swing * 0.35);
	context.fillStyle = '#111111';
	context.fillRect(-2, 0, 4, 28);
	context.beginPath();
	context.arc(0, 30, 4, 0, Math.PI * 2);
	context.fill();
	context.restore();

	// The body, the ears, and the head.
	context.fillStyle = '#111111';
	context.fillRect(12, 24, 24, 54);
	context.beginPath();
	context.arc(24, 16, 13, 0, Math.PI * 2);
	context.fill();

	for (const side of [-1, 1]) {
		context.beginPath();
		context.moveTo(24 + (side * 12), 12);
		context.lineTo(24 + (side * 11), 0);
		context.lineTo(24 + (side * 4), 5);
		context.fill();
	}

	// The eyes, which look the other way than the tail.
	for (const side of [-1, 1]) {
		const x = 24 + (side * 6);
		context.fillStyle = '#ffffff';

		if (isBlinking) {
			context.fillRect(x - 3, 13, 6, 1);
		} else {
			context.beginPath();
			context.ellipse(x, 13, 4, 5, 0, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#111111';
			context.fillRect(Math.round(x - 1 - (swing * 2)), 11, 2, 4);
		}
	}

	// The white muzzle with a grin, and the whiskers.
	context.fillStyle = '#ffffff';
	context.fillRect(19, 19, 10, 5);
	context.fillStyle = '#111111';
	context.fillRect(21, 21, 6, 1);
	context.strokeStyle = '#ffffff';
	context.lineWidth = 0.5;

	for (const side of [-1, 1]) {
		context.beginPath();
		context.moveTo(24 + (side * 5), 21);
		context.lineTo(24 + (side * 14), 19);
		context.moveTo(24 + (side * 5), 22);
		context.lineTo(24 + (side * 14), 23);
		context.stroke();
	}

	// The bow tie.
	context.fillStyle = '#ffffff';
	context.fillRect(18, 28, 12, 4);
	context.fillStyle = '#cc0000';
	context.fillRect(23, 28, 2, 4);

	// The clock on the belly, with the real time.
	const now = new Date();
	context.fillStyle = '#ffffff';
	context.beginPath();
	context.arc(24, 50, 10, 0, Math.PI * 2);
	context.fill();
	context.strokeStyle = '#111111';

	for (const [length, turn, width] of [[5, ((now.getHours() % 12) + (now.getMinutes() / 60)) / 12, 1.5], [8, now.getMinutes() / 60, 1]]) {
		context.lineWidth = width;
		context.beginPath();
		context.moveTo(24, 50);
		context.lineTo(24 + (Math.sin(turn * Math.PI * 2) * length), 50 - (Math.cos(turn * Math.PI * 2) * length));
		context.stroke();
	}

	// The white paws.
	context.fillStyle = '#ffffff';
	context.fillRect(9, 38, 4, 6);
	context.fillRect(35, 38, 4, 6);
};

const catLoop = time => {
	drawCat(time);
	catFrame = requestAnimationFrame(catLoop);
};

let catClockTimer;

function runCat() {
	cancelAnimationFrame(catFrame);
	clearInterval(catClockTimer);

	if (catCanvas.hidden || !isDesktopVisible()) {
		return;
	}

	drawCat(performance.now());

	// With reduced motion, only the hands of the clock move, once a minute.
	if (reducedMotion.matches) {
		catClockTimer = setInterval(drawCat, 30_000);
	} else {
		catFrame = requestAnimationFrame(catLoop);
	}
}

visibilityListeners.add(runCat);
reducedMotion.addEventListener('change', runCat);

// The Recycle Bin spills paper on the desktop when it holds more than the five files it came with, and complains once when it overflows.
const paperTemplate = document.querySelector('#geocities-win-paper-template');
const recycleIcon = () => iconList.querySelector('[data-desktop-open="recycle"]').closest('li');
let paperPile;
let hasOverflowed = false;

new MutationObserver(() => {
	const extra = Math.min(Math.max(recycleList.children.length - 5, 0), 14);

	if (!paperPile) {
		paperPile = fromTemplate(paperTemplate);
		paperPile.firstElementChild.remove();
		recycleIcon().append(paperPile);
	}

	while (paperPile.children.length < extra) {
		const paper = paperTemplate.content.firstElementChild.firstElementChild.cloneNode(true);
		paper.textContent = randomItem(['📄', '📃', '🧻', '📄']);
		paper.style.left = `${randomInteger(-16, 72)}px`;
		paper.style.top = `${-randomInteger(0, 70)}px`;
		paper.style.rotate = `${randomInteger(-60, 60)}deg`;
		paperPile.append(paper);
	}

	while (paperPile.children.length > extra) {
		paperPile.lastElementChild.remove();
	}

	if (extra >= 4 && !hasOverflowed) {
		hasOverflowed = true;
		toast('🗑️ The Recycle Bin is overflowing! The trash is falling out on the desktop. Empty it, or Mamma will.');
	}
}).observe(recycleList, {childList: true});

// Shut Down Windows, with the screen behind it gray, like Windows 98.
const shutDownForm = document.querySelector('#geocities-win-shut-down-form');

document.querySelector('#geocities-shut-down').addEventListener('click', () => {
	closeStartMenu();
	openWindow('shutdown', startButton);
	centerWindow(windowOf('shutdown'));
});

onOpen.shutdown = () => {
	desktop.dataset.winDimmed = '';
	shutDownForm.querySelector('[data-win-shut-down-choice]:checked').focus();
};

onClose.shutdown = () => {
	delete desktop.dataset.winDimmed;
};

const shutDownChoices = {
	shutdown() {
		// `geocities.js` shows the black screen with the famous words.
		desktop.dispatchEvent(new Event('geocities-win-shut-down'));
	},
	restart() {
		restart();
	},
	standby: standBy,
	dos: restartInDosMode,
};

// Enter on a choice is OK, also in Safari, which does not send a form from a radio button.
shutDownForm.addEventListener('keydown', event => {
	if (event.key === 'Enter' && event.target.matches('[data-win-shut-down-choice]')) {
		event.preventDefault();
		shutDownForm.requestSubmit();
	}
});

shutDownForm.addEventListener('submit', event => {
	event.preventDefault();
	const choice = shutDownForm.querySelector('[data-win-shut-down-choice]:checked').value;
	closeWindow('shutdown');
	shutDownChoices[choice]();
});

// Stand by turns the screen black, and never wakes up properly, like in 1999. Then ScanDisk has to check the drive.
async function standBy() {
	const run = ++bootRun;
	closeStartMenu();
	closeAllWindows();
	boot.hidden = false;
	bootLogo.hidden = true;
	bootText.hidden = false;
	bootText.textContent = 'Zzz… The computer is on standby. Press any key, or tap, to wake it up.';
	boot.focus();

	await new Promise(resolve => {
		boot.addEventListener('keydown', resolve, {once: true});
		boot.addEventListener('click', resolve, {once: true});
	});

	if (run !== bootRun) {
		return;
	}

	bootText.textContent = 'Windows is resuming…';
	setBusy('standby', true);
	await wait(2500);
	setBusy('standby', false);

	if (run !== bootRun) {
		return;
	}

	bootText.textContent = 'Windows could not resume from standby.\n\nYour computer will restart. (No computer ever woke up from standby in 1999.)';
	await wait(3000);

	if (run === bootRun) {
		restart({isImproper: true});
	}
}

// MS-DOS mode: Windows goes away, and the MS-DOS Prompt fills the screen, until WIN or EXIT starts Windows again.
let isDosMode = false;

function restartInDosMode() {
	closeStartMenu();
	closeAllWindows();
	isDosMode = true;
	desktop.dataset.winDosMode = '';
	iconList.hidden = true;
	taskbar.hidden = true;
	dosOutput.replaceChildren();
	dosPrint('Microsoft(R) Windows 98\n   (C)Copyright Microsoft Corp 1981-1999.\n\nYou are in MS-DOS mode. Windows is gone, and so is the mouse.\nType WIN to start Windows again.\n');
	dosFolder = 'C:\\WINDOWS';
	setDosPrompt();
	setTitle('dos', 'MS-DOS Mode');
	const dosWindow = openWindow('dos', startButton);
	dosWindow.style.left = '0';
	dosWindow.style.top = '0';
}

function leaveDosMode() {
	if (!isDosMode) {
		return;
	}

	isDosMode = false;
	delete desktop.dataset.winDosMode;
	iconList.hidden = false;
	taskbar.hidden = false;
	setTitle('dos', 'MS-DOS Prompt');
}

// CIH, also called Chernobyl, woke up on April 26, 1999, and erased the BIOS of computers all over the world. Setting the date to April lets it out.
async function cih() {
	const run = ++bootRun;
	closeStartMenu();
	closeAllWindows();
	boot.hidden = false;
	bootLogo.hidden = true;
	bootText.hidden = false;
	bootText.textContent = 'April 26, 1999.\n\nC:\\WINDOWS\\SYSTEM\\GLITTER.VXD is infected with W95.CIH, the Chernobyl virus.\n\nCIH is erasing the BIOS…';
	boot.focus();
	await wait(3000);

	if (run !== bootRun) {
		return;
	}

	bootText.textContent = Array.from({length: 12}, () => Array.from({length: 40}, () => randomItem([...'░▒▓█▄▀■□¤§¶ÆØÅ#@%&'])).join('')).join('\n');
	await wait(1500);

	if (run !== bootRun) {
		return;
	}

	bootText.textContent = 'Award Modular BIOS v4.51PG\n\nBIOS ROM checksum error\nKeyboard error or no keyboard present\n\nPress F1 to continue, DEL to enter SETUP';

	await Promise.race([wait(5000), new Promise(resolve => {
		boot.addEventListener('keydown', resolve, {once: true});
		boot.addEventListener('click', resolve, {once: true});
	})]);

	if (run !== bootRun) {
		return;
	}

	bootText.textContent = 'F1 did nothing.\n\nPappa took the computer to the shop. They put in a new BIOS chip. It cost 400 kroner, from my piggy bank.\n\nThe date is back to December.';
	dateMonth.value = '11';
	showCalendar();
	await wait(4000);

	if (run === bootRun) {
		restart();
	}
}
