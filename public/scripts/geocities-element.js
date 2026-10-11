// The base class of the toys of the 1999 page that are custom elements: the helpers of every element (`ScriptedElement`), the events of the 1999 page, which the other scripts of the page listen to, and for a program in a window of the desktop, its window (`desktopWindow` and `windowChanged(isOpen)`) and the message box (`ask()`).
import ScriptedElement from '/scripts/scripted-element.js';

// The helpers that the elements and the page scripts of the 1999 page share, so they are written once.

// A copy of the element of a template, like a row for a list.
export {cloneTemplate} from '/scripts/scripted-element.js';

// A random item of the list.
export const randomItem = items => items[Math.floor(Math.random() * items.length)];

// A random whole number from the minimum to the maximum, both included.
export const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));

// A random number from the minimum up to, but not including, the maximum.
export const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));

// The value, but at least the minimum and at most the maximum.
export const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// The value that is the amount of the way from one value to the other, like `lerp(0, 10, 0.5)` for 5.
export const lerp = (from, to, amount) => from + ((to - from) * amount);

// A copy of the list in a random order, where each order is equally possible (the Fisher–Yates shuffle). The random numbers come from `Math.random`, or from the function, like `seededRandom(seed)` for the same order each time.
export const shuffled = (items, random = Math.random) => {
	const result = [...items];

	for (let index = result.length - 1; index > 0; index--) {
		const other = Math.floor(random() * (index + 1));
		[result[index], result[other]] = [result[other], result[index]];
	}

	return result;
};

// Random numbers from 0 up to 1 that are the same each time for the same seed (Mulberry32), like for a picture that must be the same on each frame. The result gives the next number each time that it is called.
export const seededRandom = seed => () => {
	seed = (seed + 0x6D_2B_79_F5) | 0;
	let value = Math.imul(seed ^ (seed >>> 15), 1 | seed);
	value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value;
	return ((value ^ (value >>> 14)) >>> 0) / 4_294_967_296;
};

// A number from 0 up to 1 that is always the same for the same seed, for the things that must not flicker, like the shape of a stone.
export const hash = seed => {
	const value = Math.sin((seed * 127.1) + 311.7) * 43_758.5453;
	return value - Math.floor(value);
};

// The frequency of a MIDI note. Note 69 is the A at 440 Hz, and each note up is a semitone, which is the twelfth root of 2 higher.
export const midiFrequency = note => 440 * (2 ** ((note - 69) / 12));

// Waits until the next frame, like `await nextFrame()` before a long step, so the page can show a change first.
export const nextFrame = () => new Promise(resolve => {
	requestAnimationFrame(() => {
		resolve();
	});
});

// Waits until the visitor opens a page that the site prerendered, for a page script, like `await prerendered;`.
export {prerendered} from '/scripts/scripted-element.js';

// Sets the text of a status message a frame after it is cleared, so screen readers announce it, also when it is the same text as before.
export const announce = (element, message) => {
	element.textContent = '';
	requestAnimationFrame(() => {
		element.textContent = message;
	});
};

// Waits the time, in milliseconds, for a page script. An element uses its own `wait()`, which stops when the element is removed.
export const wait = milliseconds => new Promise(resolve => {
	setTimeout(resolve, milliseconds);
});

// Whether the visitor holds Control, Command, or Option with the key, so the key is a shortcut of the browser or the system, not a key of the toy.
export const hasModifier = event => event.ctrlKey || event.metaKey || event.altKey;

// Whether the visitor types in a field, so a key is text, not a key of the toy.
export const isTypingTarget = event => event.target.closest('input, textarea, select, [contenteditable]') !== null;

// The count with the word, plural when the count is not 1, like “1,000 points”.
export const plural = (count, word, pluralWord = `${word}s`) => `${count.toLocaleString('en-US')} ${count === 1 ? word : pluralWord}`;

// A short tone of an oscillator, which fades in over the attack, fades out until the end, and can slide to another frequency, like the sounds of the programs of the desktop. The sound is where it plays, like `{context, output}` of `sound()`, and the start is in seconds from now. The vibrato is how many hertz the frequency wobbles, six times a second.
export const playTone = ({context, output}, frequency, start, duration, {type = 'sine', volume = 0.1, slide, attack = 0.01, vibrato} = {}) => {
	const oscillator = context.createOscillator();
	const gain = context.createGain();
	const time = context.currentTime + start;
	oscillator.type = type;
	oscillator.frequency.setValueAtTime(frequency, time);

	if (slide) {
		oscillator.frequency.exponentialRampToValueAtTime(slide, time + duration);
	}

	if (vibrato) {
		const wobble = context.createOscillator();
		const depth = context.createGain();
		wobble.frequency.value = 6;
		depth.gain.value = vibrato;
		wobble.connect(depth).connect(oscillator.frequency);
		wobble.start(time);
		wobble.stop(time + duration + 0.05);
	}

	gain.gain.setValueAtTime(0.0001, time);
	gain.gain.exponentialRampToValueAtTime(volume, time + attack);
	gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
	oscillator.connect(gain).connect(output);
	oscillator.start(time);
	oscillator.stop(time + duration + 0.05);
};

// A value that is kept in the browser, or the fallback when there is none, or it cannot be read.
export const load = (key, fallback) => {
	try {
		const value = localStorage.getItem(key);
		return value === null ? fallback : (JSON.parse(value) ?? fallback);
	} catch {
		return fallback;
	}
};

export const save = (key, value) => {
	try {
		localStorage.setItem(key, JSON.stringify(value));
	} catch {}
};

// Shows a message at the bottom of the page. `geocities.js` listens for these events.
export const showToast = message => {
	document.dispatchEvent(new CustomEvent('geocities-toast', {detail: {message}}));
};

// The big win of the page, with the cards of the win of Solitaire.
export const celebratePage = () => {
	document.dispatchEvent(new Event('geocities-celebrate'));
};

// A small win, like a new high score: Glitter cheers.
export const cheerPage = () => {
	document.dispatchEvent(new Event('geocities-cheer'));
};

export default class GeoCitiesElement extends ScriptedElement {
	#signal;
	#desktopWindow;

	async connectedCallback() {
		await super.connectedCallback();

		// Once each time the element is connected, as its listeners are removed when it is removed.
		if (!this.isConnected || !this.signal || this.#signal === this.signal) {
			return;
		}

		this.#signal = this.signal;

		// From the start, so a toy that runs a tune before it tells the page, like the Discman without its headphones, also stops for the tune of another toy.
		this.on(document, 'geocities-music', event => {
			if (event.detail?.isPlaying && event.detail.source !== this.localName) {
				this.musicStopped();
			}
		});

		const appWindow = this.desktopWindow;

		if (!appWindow) {
			return;
		}

		let isOpen = !appWindow.hidden;

		// The window manager sets `hidden` again on a window that is closed already, so only a change counts.
		this.observe(new MutationObserver(() => {
			if (appWindow.hidden === isOpen) {
				isOpen = !appWindow.hidden;
				this.windowChanged(isOpen);
			}
		})).observe(appWindow, {attributes: true, attributeFilter: ['hidden']});

		if (isOpen) {
			this.windowChanged(true);
		}
	}

	// The window of the desktop that the element is in, like the window of a program of the desktop, or `undefined` outside the desktop. It is kept, so it is still there when the element was removed, like in `visibilityChanged(false)` on removal. An element never moves to another window.
	get desktopWindow() {
		this.#desktopWindow ??= this.closest('[data-desktop-window]') ?? undefined;
		return this.#desktopWindow;
	}

	// Called when the window of the desktop around the element opens or closes, and once after `connected()` when it is open already. A program starts a game when its window opens, and stops its sounds and timers when it closes. `visibilityChanged()` is called too, also when the window only scrolled away.
	windowChanged(isOpen) {}

	// Asks with the message box of the desktop, and gives the label of the button that the visitor pressed, or `undefined` when they closed the box. The options are those of the message box: `title`, `icon`, `text`, `buttons` (`['OK']` by default), `details`, and `opener`, which gets the focus back (the focused control by default). A program that always asks with its own title and icon overrides it, like `ask(options) { return super.ask({title: 'JezzBall', icon: '⚛️', ...options}); }`. It only answers in the desktop.
	ask(options) {
		return new Promise(resolve => {
			this.dispatchEvent(new CustomEvent('geocities-win-ask', {bubbles: true, detail: {...options, respond: resolve}}));
		});
	}

	// Shows a message at the bottom of the window, like when the visitor right-clicks a GIF.
	toast(message) {
		showToast(message);
	}

	// The big win of the page, with the cards of the win of Solitaire.
	celebrate() {
		celebratePage();
	}

	// A small win, like a new high score: Glitter cheers.
	cheer() {
		cheerPage();
	}

	// Tells the page that the toy starts or stops a tune, so only one tune plays at a time: when another toy starts one, the page calls `musicStopped()` of this one.
	music(isPlaying) {
		document.dispatchEvent(new CustomEvent('geocities-music', {detail: {isPlaying, source: this.localName}}));
	}

	// Called when another toy starts a tune. The toy stops its own.
	musicStopped() {}

	// In a window of the desktop, the sound plays through the volume of the tray, which the desktop gives in the handler of the click.
	makeSound() {
		let sound;

		this.dispatchEvent(new CustomEvent('geocities-win-audio', {
			bubbles: true,
			detail: {
				use(context, output) {
					sound = {context, output};
				},
			},
		}));

		return sound ?? super.makeSound();
	}
}
