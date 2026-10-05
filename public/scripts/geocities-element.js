// The base class of the toys of the 1999 page that are custom elements: the helpers of every element (`ScriptedElement`), the events of the 1999 page, which the other scripts of the page listen to, and for a program in a window of the desktop, its window (`desktopWindow` and `windowChanged(isOpen)`) and the message box (`ask()`).
import ScriptedElement from '/scripts/scripted-element.js';

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
		document.dispatchEvent(new CustomEvent('geocities-toast', {detail: {message}}));
	}

	// The big win of the page, with the cards of the win of Solitaire.
	celebrate() {
		document.dispatchEvent(new Event('geocities-celebrate'));
	}

	// A small win, like a new high score: Glitter cheers.
	cheer() {
		document.dispatchEvent(new Event('geocities-cheer'));
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
