// The base class of the custom elements of the site (`ScriptedElement` in SiteKit). Swift renders all the markup of an element, without a shadow DOM, and the class of the element only adds the behavior. The script of each element is next to its Swift file, with only its class, like `export default class extends ScriptedElement { … }`, and the build adds the import of this module and the definition of the element.
//
// An element overrides the methods it needs: `connected()` and `disconnected()`, `visibilityChanged(isVisible)`, `reducedMotionChanged(isReduced)`, and `focusReplacement(control)`, and the getters `visibilityTarget` and `focusFallback`. The rest are helpers, so elements do not copy them: `parts`, `config`, `on()` and `signal`, `timeout()`, `interval()`, and `wait()`, `observe()`, `isVisible` and `watchVisibility()`, `loop()`, `reducedMotion`, `stored()` and `store()`, `say()`, and `sound()`.
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');

// The speculation rules of the site can prerender the page. The elements start when the visitor opens it.
const prerendering = document.prerendering ? new Promise(resolve => {
	document.addEventListener('prerenderingchange', resolve, {once: true});
}) : undefined;

export default class ScriptedElement extends HTMLElement {
	#controller;
	#parts;
	#observer;
	#watches = new Map();
	#visibility;
	#loops = new Set();
	#sound;
	#said = new Map();

	async connectedCallback() {
		await prerendering;

		// The element can be removed while the page prerenders, or be connected already, when it moved.
		if (!this.isConnected || this.#controller) {
			return;
		}

		this.#controller = new AbortController();

		// An element in a hidden ancestor, like a closed window, is not on screen either.
		const observer = new IntersectionObserver(entries => {
			// A report can come after the element was removed, or moved and watches again with another observer.
			if (observer !== this.#observer) {
				return;
			}

			for (const entry of entries) {
				this.#watches.get(entry.target).isOnScreen = entry.isIntersecting;
			}

			this.#updateVisibility();
		});

		this.#observer = observer;
		this.#controller.signal.addEventListener('abort', () => {
			observer.disconnect();
		});

		this.on(document, 'visibilitychange', () => {
			this.#updateVisibility();
		});

		this.on(reducedMotion, 'change', () => {
			this.reducedMotionChanged(reducedMotion.matches);
			this.#startLoops();
		});

		// A control that gets disabled or hidden while it has the focus drops the focus to the start of the page, so the focus goes to its replacement instead. Browsers move the focus in the next frame, and a click on the page outside a control also blurs it, so the control is checked then.
		this.on(this, 'focusout', event => {
			const control = event.target;

			if (event.relatedTarget) {
				return;
			}

			requestAnimationFrame(() => {
				const isFocusLost = document.activeElement === document.body || document.activeElement === null;

				if (isFocusLost && (!control.isConnected || control.disabled || !control.checkVisibility())) {
					this.focusReplacement(control)?.focus({preventScroll: true});
				}
			});
		});

		this.connected();

		// After `connected()`, so the target can be an element that it makes or picks. The observer reports the first state later, so nothing is missed.
		this.#visibility = this.#watch(this.visibilityTarget);
		this.#visibility.handlers.add(isVisible => {
			this.visibilityChanged(isVisible);
		});
	}

	disconnectedCallback() {
		if (!this.#controller) {
			return;
		}

		const wasVisible = this.isVisible;

		// A loop with a target keeps its watch, so it must not run when a timer starts it after the element was removed.
		for (const watch of this.#watches.values()) {
			watch.isOnScreen = false;
			watch.isVisible = false;
		}

		// `connected()` makes its loops again when the element comes back.
		for (const loop of this.#loops) {
			loop.stop();
		}

		this.#loops.clear();

		// A removed element is not visible either, so the cleanup of `visibilityChanged(false)` runs, in the same order as when it scrolls away, and `disconnected()` does not repeat it.
		if (wasVisible) {
			this.visibilityChanged(false);
		}

		this.#controller.abort();
		this.#controller = undefined;
		this.#observer = undefined;
		this.#watches.clear();
		this.#visibility = undefined;
		this.disconnected();
	}

	// Sets up the element: its listeners with `on()`, its loops, and its first state. The listeners and loops stop by themselves when the element is removed.
	connected() {}

	disconnected() {}

	// Called when the element (or its `visibilityTarget`) comes on screen while the tab is visible, and when it goes away: it scrolled away, its window closed, the tab is hidden, or the element was removed (before `disconnected()`, only when it was visible). The loops start and stop by themselves.
	visibilityChanged(isVisible) {}

	// The element that `isVisible`, `visibilityChanged()`, and the loops without a target watch: the whole element, or a part that an element returns, like its canvas, so its game only runs while the canvas is on screen, and not while only its buttons are. It is read once, after `connected()`.
	get visibilityTarget() {
		return this;
	}

	reducedMotionChanged(isReduced) {}

	// The elements with `.part(Parts.name)` in Swift, by name, like `this.parts.screen`. The parts of an element inside this one belong to that element. They are found once, when first read, so a part that the element later moves out of itself, like a banner that it hangs on the page, stays a part. A part that the element does not have throws, so a typo or a part that the markup lost fails at once, not later with `undefined`.
	get parts() {
		if (!this.#parts) {
			const parts = {};

			for (const element of this.querySelectorAll('[data-part]')) {
				if (this.#owner(element) === this) {
					parts[element.dataset.part] ??= element;
				}
			}

			this.#parts = new Proxy(parts, {
				// `then` and `toJSON` are what `await` and `JSON.stringify()` look for, so they are not parts.
				get: (target, name) => {
					if (
						typeof name === 'string'
						&& !Object.hasOwn(target, name)
						&& name !== 'then'
						&& name !== 'toJSON'
					) {
						throw new Error(`<${this.localName}> has no part “${name}”.`);
					}

					return target[name];
				},
			});
		}

		return this.#parts;
	}

	#owner(element) {
		for (let ancestor = element.parentElement; ancestor; ancestor = ancestor.parentElement) {
			if (ancestor === this || ancestor.localName.includes('-')) {
				return ancestor;
			}
		}
	}

	// The values of `config` of the Swift component, or `undefined` when it has none.
	get config() {
		return this.dataset.config === undefined ? undefined : JSON.parse(this.dataset.config);
	}

	// Adds a listener that is removed when the element is removed. It only works while the element is connected, as a listener added before `connected()` or after the element is removed would never be removed. A `signal` in the options removes it earlier too, like for a listener on `window` that is only needed while a mode is on.
	on(target, type, handler, options = {}) {
		if (!this.signal) {
			throw new Error(`<${this.localName}> can only add listeners while it is connected.`);
		}

		const signal = options.signal ? AbortSignal.any([options.signal, this.signal]) : this.signal;
		target.addEventListener(type, handler, {...options, signal});
	}

	// Aborts when the element is removed, for other APIs that take a signal.
	get signal() {
		return this.#controller?.signal;
	}

	// Calls the handler once after the time, in milliseconds, like `setTimeout`, unless the element is removed first. The result has `cancel()`, which stops it earlier. It also runs while the element is off the screen, unlike a loop, so a toy that only needs it while it is visible cancels it in `visibilityChanged(false)`.
	timeout(milliseconds, handler) {
		const timer = this.#timer(() => {
			clearTimeout(id);
		});

		const id = setTimeout(() => {
			timer.cancel();
			handler();
		}, milliseconds);

		return timer;
	}

	// Calls the handler each time the time, in milliseconds, has passed, like `setInterval`, until the element is removed or `cancel()` of the result stops it, like for a clock. It also runs while the element is off the screen, like `timeout()`.
	interval(milliseconds, handler) {
		const timer = this.#timer(() => {
			clearInterval(id);
		});

		const id = setInterval(handler, milliseconds);
		return timer;
	}

	// Waits the time, in milliseconds, like `timeout()`, for a toy that plays a story in steps, like `await this.wait(500)`. A wait that is still running when the element is removed never resolves, so the story stops there.
	wait(milliseconds) {
		return new Promise(resolve => {
			this.timeout(milliseconds, resolve);
		});
	}

	// Disconnects the observer, like a `ResizeObserver` or a `MutationObserver`, when the element is removed, and returns it, like `this.observe(new ResizeObserver(…)).observe(canvas)`. `connected()` makes it again when the element comes back.
	observe(observer) {
		if (!this.signal) {
			throw new Error(`<${this.localName}> can only keep observers while it is connected.`);
		}

		this.signal.addEventListener('abort', () => {
			observer.disconnect();
		});

		return observer;
	}

	// The listener for the removal is removed when the timer ends, so a toy that starts many timers, like the repeat of a held key, does not collect them.
	#timer(clear) {
		const {signal} = this;

		if (!signal) {
			throw new Error(`<${this.localName}> can only start timers while it is connected.`);
		}

		const cancel = () => {
			clear();
			signal.removeEventListener('abort', cancel);
		};

		signal.addEventListener('abort', cancel);
		return {cancel};
	}

	// Whether the element (or its `visibilityTarget`) is on screen and the tab is visible.
	get isVisible() {
		return this.#visibility?.isVisible ?? false;
	}

	// Watches whether another element is on screen while the tab is visible, like a window of the element, where something waits while it is away. The handler gets `isVisible` when it changes, and the result has `isVisible` now. It stops when the element is removed, so `connected()` watches again.
	watchVisibility(target, handler) {
		const watch = this.#watch(target);

		if (handler) {
			watch.handlers.add(handler);
		}

		return {
			get isVisible() {
				return watch.isVisible;
			},
		};
	}

	// One watch for each target, so two watches of the same target agree, as the observer reports a target only once.
	#watch(target) {
		if (!this.#observer) {
			throw new Error(`<${this.localName}> can only watch the visibility while it is connected.`);
		}

		let watch = this.#watches.get(target);

		if (!watch) {
			watch = {isOnScreen: false, isVisible: false, handlers: new Set()};
			this.#watches.set(target, watch);
			this.#observer.observe(target);
		}

		return watch;
	}

	#updateVisibility() {
		const changed = [];

		for (const watch of this.#watches.values()) {
			const isVisible = watch.isOnScreen && document.visibilityState === 'visible';

			if (isVisible !== watch.isVisible) {
				watch.isVisible = isVisible;
				changed.push(watch);
			}
		}

		if (changed.length === 0) {
			return;
		}

		for (const loop of this.#loops) {
			if (loop.isVisible) {
				loop.start();
			} else {
				loop.stop();
			}
		}

		for (const watch of changed) {
			for (const handler of watch.handlers) {
				handler(watch.isVisible);
			}
		}
	}

	#startLoops() {
		for (const loop of this.#loops) {
			loop.start();
		}
	}

	get reducedMotion() {
		return reducedMotion.matches;
	}

	// A loop of animation frames, which runs while the element is visible and `while` says so. It starts again by itself when the element comes back, and `start()` starts it after `while` changed, like when a game starts, and `requestStep()` runs one step without starting it. The step gets the seconds since the last frame, at most a tenth of a second, so a game has the same speed at any refresh rate, and does not jump after a pause, and the time of the frame (the timestamp of `requestAnimationFrame`), for a game that must match a clock, like the beats of a song.
	//
	// `while` is checked before each step, so no step runs after a pause or the end of a game. A loop that shows something for a time, like a message for 2 seconds, needs a step after the time to draw it away, so `while` checks a state that the step clears after the time (`while: () => this.#message !== undefined`), not the clock.
	//
	// `stopped` is called once each time the loop stops running: `while` turned false, the element (or the `target`) left the screen or the tab was hidden, or the element was removed. It is not a step, so it is the place for the cleanup of a run, like a sound that must stop or a state that must be saved, without a step after a pause or the end of a game.
	//
	// With a `target`, like a canvas, the loop runs while that element is visible instead of the `visibilityTarget`. With a `maximumStep`, in seconds, a step gets at most that time instead of a tenth of a second, like for physics that was tuned for smaller steps.
	loop(step, {while: shouldRun = () => true, target, maximumStep = 0.1, stopped = () => {}} = {}) {
		let frame;
		let singleFrame;
		let last;
		const targetWatch = target === undefined ? undefined : this.#watch(target);

		// The watch of the `visibilityTarget` is made after `connected()`, where the loops are made, so it is looked up each time.
		const isVisible = () => (targetWatch ?? this.#visibility)?.isVisible ?? false;

		const tick = time => {
			// Cleared first, so `start()` works again after the loop stops here.
			frame = undefined;

			if (!isVisible() || !shouldRun()) {
				stopped();
				return;
			}

			const seconds = last === undefined ? 0 : Math.min((time - last) / 1000, maximumStep);
			last = time;

			// The next frame is requested before the step, so the loop is running during the step: a `start()` in the step does nothing, instead of starting a second chain of frames, and a `stop()` in the step stops it.
			frame = requestAnimationFrame(tick);
			step(seconds, time);
		};

		const loop = {
			start: () => {
				if (frame === undefined && isVisible() && shouldRun()) {
					last = undefined;
					frame = requestAnimationFrame(tick);
				}
			},
			stop() {
				if (frame === undefined) {
					return;
				}

				cancelAnimationFrame(frame);
				frame = undefined;
				stopped();
			},
			// Runs the step once in the next frame, with 0 seconds, without `while` and without starting the loop, like for one more frame of a screen that changed while the loop does not run. It does nothing while the loop runs, as the next step comes anyway, and while the loop is not visible (also when it is no longer visible in that frame), so a toy draws in `visibilityChanged(true)` what it requested while away.
			requestStep() {
				if (singleFrame !== undefined || frame !== undefined || !isVisible()) {
					return;
				}

				singleFrame = requestAnimationFrame(time => {
					singleFrame = undefined;

					if (frame === undefined && isVisible()) {
						step(0, time);
					}
				});
			},
			get isRunning() {
				return frame !== undefined;
			},
			get isVisible() {
				return isVisible();
			},
		};

		this.#loops.add(loop);
		return loop;
	}

	// A value that the element keeps in the browser, by a key that starts with the tag name. The storage can be missing or full, like in a private window, and a value can be broken, so then it is the fallback.
	stored(key, fallback) {
		try {
			const text = localStorage.getItem(`${this.localName}-${key}`);

			if (text === null) {
				return fallback;
			}

			const value = JSON.parse(text);
			const isSameType = fallback === undefined || (value !== null && typeof value === typeof fallback && Array.isArray(value) === Array.isArray(fallback));
			return isSameType ? value : fallback;
		} catch {
			return fallback;
		}
	}

	// Keeps the value by the key, or removes the key when the value is `undefined`, so `stored()` gives the fallback again. It returns whether it worked, as the storage can be missing or full, like for a toy that tells the visitor that there is no room for one more photo.
	store(key, value) {
		try {
			if (value === undefined) {
				localStorage.removeItem(`${this.localName}-${key}`);
			} else {
				localStorage.setItem(`${this.localName}-${key}`, JSON.stringify(value));
			}

			return true;
		} catch {
			return false;
		}
	}

	// Says the text in the status line (`parts.status`, which the element must have, or another live region of the element, like the status of one of its windows). It is set a frame after it is cleared, so screen readers announce it, also when it is the same text again. A later text for the same status in the same frame replaces it, so the status says what happened last, like when a press changes a state and a later step of it says the result. With `join`, the text is added to the text of that frame instead, so it does not hide it, like two things that one press does.
	say(text, status = this.parts.status, {join = false} = {}) {
		const said = this.#said.get(status);

		if (said !== undefined) {
			this.#said.set(status, join ? `${said} ${text}` : text);
			return;
		}

		this.#said.set(status, text);
		status.textContent = '';

		requestAnimationFrame(() => {
			status.textContent = this.#said.get(status);
			this.#said.delete(status);
		});
	}

	// The audio of the element: an audio context, and the node that the sounds connect to. Browsers only let audio play after the visitor clicked or pressed a key, so it is made in the handler of a click, like on a sound button, and it is `undefined` before that.
	sound() {
		if (!this.#sound && navigator.userActivation.isActive) {
			this.#sound = this.makeSound();
		}

		return this.#sound;
	}

	// Makes the audio for `sound()`. A subclass can give other audio, like the volume of a desktop.
	makeSound() {
		const context = new AudioContext();
		return {context, output: context.destination};
	}

	// The control that gets the focus when the focused control gets disabled or hidden, like the button that takes its place, such as “Put It Back Together” for “Take It Apart”. It is `focusFallback` by default.
	focusReplacement(control) {
		return this.focusFallback;
	}

	// The control that gets the focus when no other control takes the place of the one that lost it: the first control that can have it. An element can give another one, like its canvas.
	get focusFallback() {
		return [...this.querySelectorAll('button, input, select, textarea, a[href], [tabindex="0"]')].find(control => !control.disabled && control.checkVisibility());
	}
}
