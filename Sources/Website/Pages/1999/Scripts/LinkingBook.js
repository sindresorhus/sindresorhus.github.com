// My linking book on the 1999 page, an extra of the adventure games: a linking book to the Brunost Age, like Myst. The picture in the book moves like a flyby, and touching it links to the Age, a few still views to click through. The edges of a view turn, the middle walks on, and the things in it can be clicked. Three marker switches open the tower, and a red page and a blue page wake up who is trapped in the two books of the library. It makes its sounds when the sound button of Sindre’s Quest is on, which tells it with the `geocities-adventure-sound` event.
// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// Shapes for the canvases of the games.
const fillEllipse = (context, color, x, y, radiusX, radiusY) => {
	context.fillStyle = color;
	context.beginPath();
	context.ellipse(x, y, Math.max(radiusX, 0.1), Math.max(radiusY, 0.1), 0, 0, Math.PI * 2);
	context.fill();
};

const fillPolygon = (context, color, points) => {
	context.fillStyle = color;
	context.beginPath();
	for (const [x, y] of points) {
		context.lineTo(x, y);
	}

	context.closePath();
	context.fill();
};

const makeCanvas = (width, height) => {
	const canvas = document.createElement('canvas');
	canvas.width = width;
	canvas.height = height;
	return canvas;
};

// A short sound effect, made in the browser.
const beep = (audio, frequency, duration = 0.1, {type = 'square', volume = 0.05, when = 0} = {}) => {
	if (audio?.context.state !== 'running') {
		return;
	}

	const start = audio.context.currentTime + when;
	const oscillator = new OscillatorNode(audio.context, {type, frequency});
	const gain = new GainNode(audio.context, {gain: 0});
	gain.gain.setValueAtTime(0, start);
	gain.gain.linearRampToValueAtTime(volume, start + 0.005);
	gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
	oscillator.connect(gain).connect(audio.output);
	oscillator.start(start);
	oscillator.stop(start + duration + 0.02);
};

export default class extends GeoCitiesElement {
	#isSoundOn = false;
	#panelLoop;

	connected() {
		// The sound button of Sindre’s Quest turns the sound on and off for all the adventure games of the page.
		this.on(document, 'geocities-adventure-sound', event => {
			this.#isSoundOn = event.detail.isOn;
		});

		const {pages: bookPages, panel, panelCanvas, view, canvas, flash} = this.parts;
		const panelContext = panelCanvas.getContext('2d');
		const context = canvas.getContext('2d');
		const moveButtons = [...this.querySelectorAll('[data-age-move]')];
		const spotButtons = [...this.querySelectorAll('[data-part="spot"]')];
		const width = canvas.width;
		const height = canvas.height;

		const newAge = () => ({
			view: 'dock',
			switches: {dock: false, path: false, forest: false},
			red: 'forest',
			blue: 'tower',
		});

		let age = newAge();

		const gradientFill = (target, x0, y0, x1, y1, stops) => {
			const gradient = target.createLinearGradient(x0, y0, x1, y1);
			for (const [offset, color] of stops) {
				gradient.addColorStop(offset, color);
			}

			return gradient;
		};

		// The sky and the sea of the Age, rendered smooth, like the pictures of Myst that were made on a Mac with a 3D program.
		const skyAndSea = (target, horizon = 150) => {
			target.fillStyle = gradientFill(target, 0, 0, 0, horizon, [[0, '#1a2a5a'], [0.6, '#8a5a7a'], [1, '#f0a868']]);
			target.fillRect(0, 0, width, horizon);
			target.fillStyle = gradientFill(target, 0, horizon, 0, height, [[0, '#6a4a3a'], [1, '#2a1a12']]);
			target.fillRect(0, horizon, width, height - horizon);
			target.fillStyle = 'rgba(255, 200, 140, 0.25)';
			for (let y = horizon + 4; y < height; y += 7) {
				target.fillRect(width / 2 - 60 + ((y * 13) % 40), y, 80 - ((y - horizon) / 4), 1);
			}
		};

		const cheeseTower = (target, x, base, towerWidth, towerHeight, isOpen) => {
			target.fillStyle = gradientFill(target, x - (towerWidth / 2), 0, x + (towerWidth / 2), 0, [[0, '#5a2a0a'], [0.35, '#d08040'], [0.6, '#b0602a'], [1, '#4a2008']]);
			target.fillRect(x - (towerWidth / 2), base - towerHeight, towerWidth, towerHeight);
			fillEllipse(target, '#e0a060', x, base - towerHeight, towerWidth / 2, towerWidth / 8);
			fillEllipse(target, '#5a2a0a', x, base, towerWidth / 2, towerWidth / 10);
			target.fillRect(x - (towerWidth / 2), base - 1, towerWidth, 2);
			if (towerWidth > 100) {
				// The door, and three marks above it, one for each marker switch.
				target.fillStyle = isOpen ? '#120804' : '#6a3a1a';
				target.beginPath();
				target.moveTo(x - 30, base);
				target.lineTo(x - 30, base - 80);
				target.arc(x, base - 80, 30, Math.PI, 0);
				target.lineTo(x + 30, base);
				target.fill();
				for (const [index, isOn] of Object.values(age.switches).entries()) {
					fillEllipse(target, isOn ? '#ffe070' : '#3a1a08', x - 24 + (index * 24), base - 130, 7, 7);
				}
			}
		};

		const pine = (target, x, base, treeHeight, color = '#12301a') => {
			target.fillStyle = '#2a1a10';
			target.fillRect(x - 3, base - (treeHeight * 0.25), 6, treeHeight * 0.25);
			target.fillStyle = color;
			target.beginPath();
			target.moveTo(x - (treeHeight * 0.22), base - (treeHeight * 0.2));
			target.lineTo(x, base - treeHeight);
			target.lineTo(x + (treeHeight * 0.22), base - (treeHeight * 0.2));
			target.fill();
		};

		const markerSwitch = (target, x, y, isOn) => {
			target.fillStyle = gradientFill(target, x - 10, 0, x + 10, 0, [[0, '#5a5a5a'], [0.5, '#c0c0c0'], [1, '#4a4a4a']]);
			target.fillRect(x - 10, y - 30, 20, 30);
			fillEllipse(target, isOn ? '#ffe070' : '#3a3a3a', x, y - 36, 5, 5);
			target.strokeStyle = '#d0d0d0';
			target.lineWidth = 3;
			target.beginPath();
			target.moveTo(x, y - 18);
			target.lineTo(x + (isOn ? 0 : 10), y - (isOn ? 32 : 26));
			target.stroke();
		};

		const page = (target, x, y, color) => {
			target.save();
			target.translate(x, y);
			target.rotate(-0.2);
			target.fillStyle = color;
			target.fillRect(-14, -10, 28, 20);
			target.fillStyle = 'rgba(255, 255, 255, 0.5)';
			for (let line = -6; line < 8; line += 4) {
				target.fillRect(-10, line, 20, 1);
			}

			target.restore();
		};

		const views = {
			dock: {
				text: 'You stand on a wooden dock. The water is calm and brown, like melted brown cheese. Up the hill stands a round tower that looks a lot like a cheese. A marker switch stands at the end of the dock.',
				exits: {forward: 'path'},
				draw(target) {
					skyAndSea(target);
					fillPolygon(target, '#2a3a2a', [[280, 150], [360, 90], [480, 70], [480, 150]]);
					cheeseTower(target, 400, 110, 40, 70, false);
					fillPolygon(target, '#6a4a2a', [[140, 300], [340, 300], [262, 160], [218, 160]]);
					target.fillStyle = '#4a3018';
					for (let y = 165; y < 300; y += ((y - 140) / 6)) {
						const half = 22 + ((y - 160) * 0.7);
						target.fillRect(240 - half, y, half * 2, 2);
					}

					markerSwitch(target, 330, 250, age.switches.dock);
				},
				spots: [{id: 'dock', name: 'Marker switch', area: [312, 200, 40, 56]}],
			},
			path: {
				text: 'A stony path climbs the hill. To the left is a dark forest. To the right is the cheese tower. Ahead is a small library with columns. A marker switch stands by the path.',
				exits: {forward: 'library', left: 'forest', right: 'tower', back: 'dock'},
				draw(target) {
					target.fillStyle = gradientFill(target, 0, 0, 0, 140, [[0, '#1a2a5a'], [1, '#e0a070']]);
					target.fillRect(0, 0, width, 140);
					target.fillStyle = gradientFill(target, 0, 120, 0, height, [[0, '#4a5a3a'], [1, '#1a2012']]);
					target.fillRect(0, 120, width, height - 120);
					for (let index = 0; index < 9; index++) {
						pine(target, 10 + (index * 14), 200 + ((index * 7) % 20), 120 + ((index * 23) % 40));
					}

					cheeseTower(target, 400, 190, 70, 120, false);
					fillPolygon(target, '#8a7a6a', [[200, 300], [300, 300], [252, 150], [232, 150]]);
					target.fillStyle = gradientFill(target, 210, 0, 270, 0, [[0, '#a09080'], [0.5, '#f0e8d8'], [1, '#807060']]);
					target.fillRect(212, 104, 56, 46);
					fillPolygon(target, '#c0b0a0', [[206, 106], [240, 86], [274, 106]]);
					target.fillStyle = '#3a2a1a';
					target.fillRect(232, 124, 16, 26);
					markerSwitch(target, 150, 262, age.switches.path);
				},
				spots: [{id: 'path', name: 'Marker switch', area: [130, 212, 40, 56]}],
			},
			forest: {
				text: () => `A forest of tall pines that smell of brown cheese. ${age.red === 'forest' ? 'A red page lies on a tree stump.' : 'There is an empty tree stump.'} A marker switch stands among the roots.`,
				exits: {back: 'path'},
				draw(target) {
					target.fillStyle = gradientFill(target, 0, 0, 0, height, [[0, '#0a1a12'], [0.6, '#1a3a22'], [1, '#0a120a']]);
					target.fillRect(0, 0, width, height);
					for (let index = 0; index < 14; index++) {
						const x = (index * 37) % width;
						target.fillStyle = gradientFill(target, x, 0, x + 18, 0, [[0, '#1a0e06'], [0.5, '#5a3a20'], [1, '#1a0e06']]);
						target.fillRect(x, 0, 14 + (index % 3) * 4, 260);
					}

					fillEllipse(target, '#2a1a0a', 240, 262, 200, 30);
					target.fillStyle = gradientFill(target, 210, 0, 270, 0, [[0, '#3a2210'], [0.5, '#9a6a3a'], [1, '#3a2210']]);
					target.fillRect(212, 220, 56, 40);
					fillEllipse(target, '#c09060', 240, 220, 28, 8);
					if (age.red === 'forest') {
						page(target, 240, 214, '#c02020');
					}

					markerSwitch(target, 370, 270, age.switches.forest);
				},
				spots: [
					{id: 'forest', name: 'Marker switch', area: [350, 220, 40, 56]},
					{id: 'red', name: 'Red page', area: [220, 200, 40, 26], isHere: () => age.red === 'forest'},
				],
			},
			tower: {
				text: () => {
					const isOpen = Object.values(age.switches).every(Boolean);
					return `The cheese tower, up close. It is huge, round, and brown. ${isOpen ? 'The door stands open.' : 'The door is shut. Above it are three round marks, and some of them glow.'}`;
				},
				exits: {back: 'path', forward: 'inside'},
				draw(target) {
					target.fillStyle = gradientFill(target, 0, 0, 0, 200, [[0, '#1a2a5a'], [1, '#e0a070']]);
					target.fillRect(0, 0, width, 200);
					target.fillStyle = gradientFill(target, 0, 200, 0, height, [[0, '#4a5a3a'], [1, '#1a2012']]);
					target.fillRect(0, 200, width, height - 200);
					cheeseTower(target, 240, 270, 260, 250, Object.values(age.switches).every(Boolean));
				},
				spots: [],
			},
			inside: {
				text: () => `Inside the tower, it smells of a thousand breakfasts. A great wooden gear stands still in the wall. ${age.blue === 'tower' ? 'On a pedestal lies a blue page.' : 'The pedestal is empty.'}`,
				exits: {back: 'tower'},
				draw(target) {
					target.fillStyle = gradientFill(target, 0, 0, width, 0, [[0, '#3a1a06'], [0.5, '#b06a30'], [1, '#3a1a06']]);
					target.fillRect(0, 0, width, height);
					target.fillStyle = '#5a3010';
					for (let index = 0; index < 16; index++) {
						const angle = index * Math.PI / 8;
						target.fillRect(240 + (Math.cos(angle) * 70) - 8, 110 + (Math.sin(angle) * 70) - 8, 16, 16);
					}

					fillEllipse(target, '#7a4418', 240, 110, 68, 68);
					fillEllipse(target, '#3a1a06', 240, 110, 16, 16);
					target.fillStyle = gradientFill(target, 220, 0, 260, 0, [[0, '#4a4a4a'], [0.5, '#c0c0c0'], [1, '#4a4a4a']]);
					target.fillRect(222, 220, 36, 80);
					fillEllipse(target, '#d0d0d0', 240, 220, 26, 6);
					if (age.blue === 'tower') {
						page(target, 240, 212, '#2040c0');
					}
				},
				spots: [{id: 'blue', name: 'Blue page', area: [220, 198, 40, 26], isHere: () => age.blue === 'tower'}],
			},
			library: {
				text: 'A small library. Shelves of burned books line the walls. On the left stands a red book, on the right a blue book, and in the middle, on a pedestal, a linking book back home.',
				exits: {back: 'path'},
				draw(target) {
					target.fillStyle = gradientFill(target, 0, 0, 0, height, [[0, '#2a1a10'], [1, '#0a0604']]);
					target.fillRect(0, 0, width, height);
					for (const shelf of [40, 90, 140]) {
						for (let x = 0; x < width; x += 9) {
							target.fillStyle = ['#4a2a1a', '#2a1a10', '#5a3a2a', '#3a2010'][(x / 9) % 4];
							target.fillRect(x, shelf, 7, 40);
						}

						target.fillStyle = '#1a0e06';
						target.fillRect(0, shelf + 40, width, 4);
					}

					for (const [x, color] of [[90, '#a01818'], [390, '#1830a0'], [240, '#5a3a1a']]) {
						target.fillStyle = gradientFill(target, x - 10, 0, x + 10, 0, [[0, '#3a2a1a'], [0.5, '#8a6a4a'], [1, '#3a2a1a']]);
						target.fillRect(x - 8, 220, 16, 80);
						fillPolygon(target, color, [[x - 34, 222], [x + 34, 222], [x + 26, 200], [x - 26, 200]]);
					}

					target.fillStyle = gradientFill(target, 0, 196, 0, 214, [[0, '#ffe8a0'], [1, '#c08040']]);
					target.fillRect(250, 202, 18, 12);
					if (age.red === 'book') {
						fillEllipse(target, 'rgba(255, 220, 200, 0.6)', 90, 208, 14, 6);
					}

					if (age.blue === 'book') {
						fillEllipse(target, 'rgba(220, 230, 255, 0.6)', 390, 208, 14, 6);
					}
				},
				spots: [
					{id: 'redBook', name: 'Red book', area: [50, 190, 80, 40]},
					{id: 'blueBook', name: 'Blue book', area: [350, 190, 80, 40]},
					{id: 'homeBook', name: 'Linking book home', area: [200, 190, 80, 40]},
				],
			},
		};

		const spotsHere = () => views[age.view].spots.filter(spot => !spot.isHere || spot.isHere());

		const draw = () => {
			views[age.view].draw(context);
		};

		// Shows a button for each thing in the view, for the keyboard, and keeps the focus when a button goes away.
		const updateSpots = () => {
			for (const [index, button] of spotButtons.entries()) {
				const spot = spotsHere()[index];
				if (!spot && button === document.activeElement) {
					canvas.focus({preventScroll: true});
				}

				button.hidden = !spot;
				button.textContent = spot ? `✋ ${spot.name}` : '';
			}
		};

		const show = async (name, message) => {
			age.view = name;
			draw();
			updateSpots();
			const text = views[name].text;
			this.say(`${message ? `${message} ` : ''}${typeof text === 'function' ? text() : text}`);
		};

		// Says what happens after a click on a thing in the view, without the description of the view again.
		const tell = async text => {
			draw();
			updateSpots();
			this.say(text);
		};

		const go = direction => {
			const target = views[age.view].exits[direction];
			if (!target) {
				this.say(direction === 'back' ? 'There is nothing behind you but the way you came. Which is not a way here.' : 'You can’t go that way. Rocks, water, or a very determined pine.');
				return;
			}

			if (target === 'inside' && !Object.values(age.switches).every(Boolean)) {
				this.say('The door of the tower does not move. Above it, three round marks. Only some of them glow.');
				return;
			}

			this.#beep(180, 0.08, {type: 'triangle', volume: 0.03});
			show(target);
		};

		// The flash of white light of a link, and the book or the Age behind it.
		let isLinking = false;

		const link = async toAge => {
			if (isLinking) {
				return;
			}

			isLinking = true;
			const hadFocus = document.activeElement;
			flash.dataset.state = this.reducedMotion ? '' : 'on';
			this.#beep(220, 0.6, {type: 'sine', volume: 0.04});
			this.#beep(330, 0.6, {type: 'sine', volume: 0.03, when: 0.1});
			await this.wait(this.reducedMotion ? 0 : 650);
			bookPages.hidden = toAge;
			view.hidden = !toAge;
			if (toAge) {
				await show(age.view, 'You touch the picture. The world fades to white, and you are somewhere else.');
				if (hadFocus === panel) {
					canvas.focus({preventScroll: true});
				}
			} else {
				if (view.contains(hadFocus) || hadFocus === document.body) {
					panel.focus({preventScroll: true});
				}

				panelLoop.start();
			}

			flash.dataset.state = '';
			isLinking = false;
		};

		const actions = {
			dock: () => toggle('dock'),
			path: () => toggle('path'),
			forest: () => toggle('forest'),
			red() {
				age.red = 'carried';
				tell('You pick up the red page. It is warm, and it whispers something about AOL.');
			},
			blue() {
				age.blue = 'carried';
				tell('You pick up the blue page. It smells of fish.');
			},
			redBook: () => useBook('red'),
			blueBook: () => useBook('blue'),
			homeBook: async () => {
				const isDone = age.red === 'book' && age.blue === 'book';
				await link(false);
				if (isDone) {
					this.toast('📖 You came back from the Brunost Age. Kevin and the seagull are still arguing in there.');
					this.cheer();
				}

				age = newAge();
			},
		};

		const toggle = name => {
			age.switches[name] = !age.switches[name];
			this.#beep(age.switches[name] ? 660 : 330, 0.08);
			const count = Object.values(age.switches).filter(Boolean).length;
			tell(`Clunk. The marker switch is now ${age.switches[name] ? 'up, and its light glows' : 'down'}. Somewhere far away, something clicks. ${count} of 3.`);
		};

		const useBook = color => {
			const voices = {
				red: {
					empty: 'The red book shows only static. A voice crackles: “…Sin…dre… bring… red… page…”',
					placed: 'You put the red page in the red book. The static clears, and a face appears. It is Kevin! “Sindre! I got trapped in here trading AOL CDs with a stranger. Bring me more red pages! What, there are no more? Then bring me an AOL CD!”',
					after: 'Kevin, in the red book: “Is that an AOL CD in your pocket? No? Then what are you waiting for?”',
				},
				blue: {
					empty: 'The blue book shows only static. A voice crackles: “…SKR…EE…”',
					placed: 'You put the blue page in the blue book. The static clears, and a face appears. It is the seagull from the fish market! “SKREE! SKREE SKREE!” It wants your waffle. Even here.',
					after: 'The seagull, in the blue book: “SKREE.” It is still looking at your waffle.',
				},
			}[color];

			if (age[color] === 'book') {
				tell(voices.after);
				return;
			}

			if (age[color] !== 'carried') {
				tell(voices.empty);
				return;
			}

			age[color] = 'book';
			const isDone = age.red === 'book' && age.blue === 'book';
			tell(`${voices.placed}${isDone ? ' Now Kevin and the seagull argue with each other, like the brothers in Myst. They will argue forever. Time to touch the linking book and go home.' : ''}`);
		};

		this.on(canvas, 'click', event => {
			const point = canvasPoint(canvas, event);
			const spot = spotsHere().find(({area: [left, top, spotWidth, spotHeight]}) => point.x >= left && point.x < left + spotWidth && point.y >= top && point.y < top + spotHeight);
			if (spot) {
				actions[spot.id]();
			} else if (point.x < width * 0.2) {
				go('left');
			} else if (point.x > width * 0.8) {
				go('right');
			} else if (point.y > height * 0.85) {
				go('back');
			} else {
				go('forward');
			}
		});

		// The arrow keys move on the view, like the edges of the view do.
		this.on(canvas, 'keydown', event => {
			const direction = {ArrowLeft: 'left', ArrowRight: 'right', ArrowUp: 'forward', ArrowDown: 'back'}[event.key];
			if (direction) {
				event.preventDefault();
				go(direction);
			}
		});

		for (const button of moveButtons) {
			this.on(button, 'click', () => {
				go(button.dataset.ageMove);
			});
		}

		for (const [index, button] of spotButtons.entries()) {
			this.on(button, 'click', () => {
				const spot = spotsHere()[index];
				if (spot) {
					actions[spot.id]();
				}
			});
		}

		this.on(panel, 'click', () => {
			link(true);
		});

		// The picture in the book moves slowly over the dock, like the flyby in the linking books of Myst. It runs only while it is on screen and the tab is visible, and stands still with reduced motion.
		const flyby = makeCanvas(width, height);
		views.dock.draw(flyby.getContext('2d'));

		const drawPanel = time => {
			const offset = this.reducedMotion ? 80 : 80 + (Math.sin(time / 4000) * 80);
			panelContext.drawImage(flyby, offset, 40, 320, 220, 0, 0, panelCanvas.width, panelCanvas.height);
		};

		const panelLoop = this.loop((seconds, time) => {
			drawPanel(time);
		}, {while: () => !this.reducedMotion && !bookPages.hidden});

		this.#panelLoop = panelLoop;
		drawPanel(0);
	}

	// The flyby runs only while the picture in the book is on the screen.
	get visibilityTarget() {
		return this.parts.panelCanvas;
	}

	// The picture is drawn again when it comes back or when reduced motion changes, so it stands still at its place.
	visibilityChanged(isVisible) {
		if (isVisible) {
			this.#panelLoop.requestStep();
		}
	}

	reducedMotionChanged() {
		this.#panelLoop.requestStep();
	}

	// The audio is made at the first sound, in the click or the key press that makes it, as browsers only let audio start then.
	#beep(...options) {
		if (this.#isSoundOn) {
			beep(this.sound(), ...options);
		}
	}
}
