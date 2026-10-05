// My beige PC on the 1999 page: the hard drive light that flickers whenever the visitor clicks, types, or scrolls, the CD-ROM drive that opens into a cup holder, the Turbo button that makes the page faster, and the Reset button with the screen of the BIOS.
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));

// The text keeps its spaces, like on a screen of fixed-width text, as the box only keeps the line breaks.
const fixedWidth = text => text.replaceAll(' ', ' ');

const turboRate = 2;

const biosLines = [
	'Award Modular BIOS v4.51PG, An Energy Star Ally',
	'Copyright (C) 1984-98, Award Software, Inc.',
	'',
	'SINDRE 2000 TURBO BIOS REVISION 1.99',
	'',
	'PENTIUM-II CPU at 400MHz',
	'Memory Test : {memory}K OK',
	'',
	'Award Plug and Play BIOS Extension v1.0A',
	'Copyright (C) 1998, Award Software, Inc.',
	'  Detecting IDE Primary Master   ... QUANTUM FIREBALL 6.4GB',
	'  Detecting IDE Primary Slave    ... CD-ROM 32X',
	'  Detecting IDE Secondary Master ... None',
	'  Detecting Unicorn              ... Glitter OK',
	'',
	'Press DEL to enter SETUP',
	'',
	'Starting Windows 98...',
];

const memory = 65_536;

const setAnimationSpeed = rate => {
	for (const animation of document.getAnimations()) {
		animation.playbackRate = animation.playbackRate < 0 ? -rate : rate;
	}
};

export default class extends GeoCitiesElement {
	connected() {
		this.#setUpHardDrive();
		this.#setUpDrive();
		this.#setUpTurbo();
		this.#setUpBios();
	}

	// The hard drive light flickers whenever the visitor clicks, types, or scrolls, like a busy hard drive. Without motion, it lights up once.
	#setUpHardDrive() {
		const {hardDriveLight} = this.parts;
		let isHardDriveBusy = false;
		let hardDriveTimer;

		const accessHardDrive = async () => {
			if (this.reducedMotion) {
				hardDriveLight.dataset.state = 'on';
				hardDriveTimer?.cancel();
				hardDriveTimer = this.timeout(400, () => {
					delete hardDriveLight.dataset.state;
				});
				return;
			}

			if (isHardDriveBusy) {
				return;
			}

			isHardDriveBusy = true;
			const blinks = Math.ceil(randomBetween(2, 5));

			for (let blink = 0; blink < blinks; blink++) {
				hardDriveLight.dataset.state = 'on';
				await this.wait(randomBetween(40, 110));
				delete hardDriveLight.dataset.state;
				await this.wait(randomBetween(30, 90));
			}

			isHardDriveBusy = false;
		};

		this.on(document, 'pointerdown', accessHardDrive);
		this.on(document, 'keydown', accessHardDrive);
		this.on(window, 'scroll', accessHardDrive, {passive: true});
	}

	// The CD-ROM drive opens into a cup holder.
	#setUpDrive() {
		const {drive, eject: ejectButton} = this.parts;

		this.on(ejectButton, 'click', () => {
			const isOpen = drive.dataset.state !== 'open';

			if (isOpen) {
				drive.dataset.state = 'open';
			} else {
				delete drive.dataset.state;
			}

			ejectButton.ariaPressed = String(isOpen);
			this.say(isOpen ? 'The cup holder is open! Best feature of the computer.' : 'The cup holder is closed. Mind the coffee.');
		});
	}

	// The Turbo button makes every animation of the page twice as fast, also the ones that start later, like the sparkles. The display counts up to the new speed.
	#setUpTurbo() {
		const {turbo: turboButton, turboLight, speed} = this.parts;
		let isTurbo = false;
		let turboTimer;
		let speedRun = 0;

		const countSpeedTo = async target => {
			const run = ++speedRun;
			let value = Number(speed.textContent);
			const step = target > value ? 11 : -11;

			while (value !== target && run === speedRun) {
				value = this.reducedMotion ? target : (step > 0 ? Math.min(value + step, target) : Math.max(value + step, target));
				speed.textContent = String(value);
				await this.wait(40);
			}
		};

		this.on(turboButton, 'click', () => {
			isTurbo = !isTurbo;
			turboButton.ariaPressed = String(isTurbo);
			turboTimer?.cancel();

			if (isTurbo) {
				turboButton.dataset.state = 'on';
				turboLight.dataset.state = 'on';
				setAnimationSpeed(turboRate);
				// The animations that start later get the speed too, like the sparkles, while the tab is visible.
				turboTimer = this.interval(500, () => {
					if (!document.hidden) {
						setAnimationSpeed(turboRate);
					}
				});
				countSpeedTo(133);
				this.say(this.reducedMotion ? 'TURBO! 133 MHz. Nothing moves on your page, so it is only faster in spirit.' : 'TURBO! 133 MHz. Everything that moves on the page is twice as fast now. Except the GIFs, which do what they want.');
			} else {
				delete turboButton.dataset.state;
				delete turboLight.dataset.state;
				setAnimationSpeed(1);
				countSpeedTo(66);
				this.say('Turbo off. Back to a relaxing 66 MHz.');
			}
		});
	}

	// Reset restarts the computer: the screen of the BIOS counts the memory and finds the drives, and then the page is back. Any key or click skips it. Delete enters the setup, almost.
	#setUpBios() {
		// The parts are found before the screen moves out of the element, so it stays a part.
		const {reset: resetButton, bios, biosText} = this.parts;
		let biosRun = 0;

		// Outside the panel, as the views of the panel and the earthquake would make it part of the page instead of the window.
		document.body.append(bios);

		const closeBios = message => {
			biosRun++;

			if (bios.hidden) {
				return;
			}

			bios.hidden = true;
			resetButton.focus();
			this.say(message);
		};

		this.on(resetButton, 'click', async () => {
			const run = ++biosRun;
			const shown = [];
			bios.hidden = false;
			bios.focus();

			const show = line => {
				shown.push(fixedWidth(line));
				biosText.textContent = shown.join('\n');
			};

			for (const line of biosLines) {
				if (run !== biosRun) {
					return;
				}

				if (line.includes('{memory}')) {
					// The memory counts up, like a real memory test, unless the visitor prefers reduced motion.
					const steps = this.reducedMotion ? 1 : 16;

					for (let step = 1; step <= steps && run === biosRun; step++) {
						if (step > 1) {
							shown.pop();
						}

						show(line.replace('{memory}', String(Math.round(memory * step / steps)).padStart(6, ' ')));
						await this.wait(70);
					}
				} else {
					show(line);
					await this.wait(line ? 220 : 60);
				}
			}

			await this.wait(1200);

			if (run === biosRun) {
				closeBios('Restarted! Everything is where you left it, thanks to the magic of not really restarting.');
			}
		});

		this.on(bios, 'keydown', event => {
			// Shortcuts, like reloading the page, still work, and a key that is held down, like Enter on Reset, does not skip it.
			if (event.metaKey || event.ctrlKey || event.altKey || event.repeat || ['Shift', 'Control', 'Alt', 'Meta'].includes(event.key)) {
				return;
			}

			event.preventDefault();

			if (event.key === 'Delete') {
				closeBios('Nice try! The setup is protected with a password. (It is “waffles”.)');
			} else {
				closeBios('Skipped the BIOS. Windows 98 starts faster when you are impatient.');
			}
		});

		this.on(bios, 'click', () => {
			closeBios('Skipped the BIOS. Windows 98 starts faster when you are impatient.');
		});
	}
}
