// The Craft Table on the 1999 page: the kitchen table on a rainy Saturday in Bergen, covered in Bergens Tidende, with Hama beads and Mamma’s iron, paper snowflakes for the kitchen window, a Spirograph, and Shrinky Dinks that shrink in the oven. Each craft is drawn on a canvas at twice the size it has on the page, so the beads and the lines are sharp. Canvases and timers run only while they are on the screen and the tab is visible. What the visitor makes is kept in the browser.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const lerp = (from, to, amount) => from + ((to - from) * amount);
const easeInOut = amount => amount < 0.5 ? 2 * amount * amount : 1 - (((-2 * amount) + 2) ** 2 / 2);

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// Draws on the next frame, once, however many times it is asked for in the same frame.
const makeRenderer = render => {
	let frame;
	return () => {
		frame ??= requestAnimationFrame(() => {
			frame = undefined;
			render();
		});
	};
};

// The canvases have twice the pixels of their size on the page, so the drawing is sharp on screens with more pixels. The crafts draw in the size on the page.
const pixelRatio = 2;

const makeCanvas = (width, height) => {
	const canvas = document.createElement('canvas');
	canvas.width = Math.ceil(width * pixelRatio);
	canvas.height = Math.ceil(height * pixelRatio);
	const context = canvas.getContext('2d');
	context.scale(pixelRatio, pixelRatio);
	return {canvas, context};
};

// The position of a pointer on a canvas, in the size that the crafts draw in.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	const width = canvas.clientWidth || rectangle.width;
	const height = canvas.clientHeight || rectangle.height;
	return {
		x: (event.clientX - rectangle.left - canvas.clientLeft) * (canvas.width / pixelRatio) / width,
		y: (event.clientY - rectangle.top - canvas.clientTop) * (canvas.height / pixelRatio) / height,
	};
};

const isInPolygon = (x, y, polygon) => {
	let isInside = false;
	for (let index = 0, previous = polygon.length - 1; index < polygon.length; previous = index++) {
		const current = polygon[index];
		const other = polygon[previous];
		if ((current.y > y) !== (other.y > y) && x < (((other.x - current.x) * (y - current.y)) / (other.y - current.y)) + current.x) {
			isInside = !isInside;
		}
	}

	return isInside;
};

const polygonArea = polygon => {
	let area = 0;
	for (let index = 0, previous = polygon.length - 1; index < polygon.length; previous = index++) {
		area += (polygon[previous].x * polygon[index].y) - (polygon[index].x * polygon[previous].y);
	}

	return Math.abs(area / 2);
};

const tracePolygon = (context, polygon) => {
	context.beginPath();
	for (const [index, point] of polygon.entries()) {
		if (index === 0) {
			context.moveTo(point.x, point.y);
		} else {
			context.lineTo(point.x, point.y);
		}
	}

	context.closePath();
};

const isHex = value => typeof value === 'string' && /^#[\da-f]{6}$/i.test(value);

const hexToRgb = hex => {
	const value = Number.parseInt(hex.slice(1), 16);
	return [(value >> 16) & 255, (value >> 8) & 255, value & 255];
};

const mixColors = (from, to, amount) => {
	const start = hexToRgb(from);
	const end = hexToRgb(to);
	return `rgb(${start.map((channel, index) => Math.round(lerp(channel, end[index], amount))).join(', ')})`;
};

// The same random numbers each time for the same seed, so the newspaper and the scraps look the same on each frame.
const seededRandom = seed => () => {
	seed = (seed + 0x6D_2B_79_F5) | 0;
	let value = Math.imul(seed ^ (seed >>> 15), 1 | seed);
	value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value;
	return ((value ^ (value >>> 14)) >>> 0) / 4_294_967_296;
};

// The sound of the crafts, made in the browser. It is off until the visitor turns it on.
const sound = {
	isOn: false,
	context: undefined,
	noiseBuffer: undefined,
	output: undefined,
	// Starts the audio of the element, which is `undefined` when the browser does not allow it yet.
	start(audio) {
		if (!audio) {
			return false;
		}

		try {
			this.context = audio.context;
			this.output = audio.output;
			this.context.resume();
			if (!this.noiseBuffer) {
				const length = this.context.sampleRate;
				this.noiseBuffer = new AudioBuffer({length, sampleRate: this.context.sampleRate});
				const data = this.noiseBuffer.getChannelData(0);
				for (let index = 0; index < length; index++) {
					data[index] = (Math.random() * 2) - 1;
				}
			}

			return true;
		} catch {
			return false;
		}
	},
	get isReady() {
		return this.isOn && this.context?.state === 'running';
	},
	envelope(start, duration, volume) {
		const gain = new GainNode(this.context, {gain: 0});
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(volume, start + 0.004);
		gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
		gain.connect(this.output);
		return gain;
	},
	tone(frequency, duration, {type = 'sine', volume = 0.05, when = 0, slideTo} = {}) {
		if (!this.isReady) {
			return;
		}

		const start = this.context.currentTime + when;
		const oscillator = new OscillatorNode(this.context, {type, frequency});
		if (slideTo) {
			oscillator.frequency.setValueAtTime(frequency, start);
			oscillator.frequency.exponentialRampToValueAtTime(slideTo, start + duration);
		}

		oscillator.connect(this.envelope(start, duration, volume));
		oscillator.start(start);
		oscillator.stop(start + duration + 0.02);
	},
	noise(duration, {frequency = 3000, type = 'bandpass', quality = 1, volume = 0.08, when = 0} = {}) {
		if (!this.isReady) {
			return;
		}

		const start = this.context.currentTime + when;
		const source = new AudioBufferSourceNode(this.context, {buffer: this.noiseBuffer});
		const filter = new BiquadFilterNode(this.context, {type, frequency, Q: quality});
		source.connect(filter).connect(this.envelope(start, duration, volume));
		source.start(start, Math.random() * 0.5);
		source.stop(start + duration + 0.02);
	},
};

// A noise that goes on while something lasts, like the hiss of the iron or the fan of the oven.
const makeNoiseLoop = ({type, frequency, quality = 1, volume}) => {
	let gain;
	return {
		set(level) {
			const target = sound.isReady ? level * volume : 0;
			if (!gain) {
				if (target === 0) {
					return;
				}

				const source = new AudioBufferSourceNode(sound.context, {buffer: sound.noiseBuffer, loop: true});
				const filter = new BiquadFilterNode(sound.context, {type, frequency, Q: quality});
				gain = new GainNode(sound.context, {gain: 0});
				source.connect(filter).connect(gain).connect(sound.output);
				source.start();
			}

			gain.gain.setTargetAtTime(target, sound.context.currentTime, 0.05);
		},
	};
};

const sounds = {
	bead() {
		sound.tone(randomBetween(2300, 3500), 0.025, {type: 'triangle', volume: 0.05});
		sound.noise(0.02, {frequency: 6000, type: 'highpass', volume: 0.04});
	},
	rattle(count = 16, spread = 0.6) {
		for (let index = 0; index < count; index++) {
			sound.tone(randomBetween(1800, 4200), 0.02, {type: 'triangle', volume: 0.035, when: Math.random() * spread});
		}
	},
	snip() {
		sound.noise(0.03, {frequency: 5000, quality: 2, volume: 0.16});
		sound.noise(0.025, {frequency: 7000, quality: 2, volume: 0.11, when: 0.06});
	},
	swish() {
		sound.noise(0.35, {frequency: 900, type: 'lowpass', volume: 0.07});
	},
	thump() {
		sound.tone(150, 0.15, {volume: 0.16, slideTo: 60});
		sound.noise(0.04, {frequency: 500, volume: 0.1});
	},
	tick() {
		sound.noise(0.015, {frequency: 3500, quality: 6, volume: 0.14});
	},
	ding() {
		sound.tone(1568, 1.5, {volume: 0.07});
		sound.tone(2349, 1, {volume: 0.035});
		sound.tone(3136, 0.6, {volume: 0.02});
	},
	boing() {
		sound.tone(220, 0.35, {type: 'triangle', volume: 0.09, slideTo: 880});
	},
	slip() {
		sound.tone(1300, 0.03, {type: 'square', volume: 0.03});
	},
	jingle() {
		for (let index = 0; index < 6; index++) {
			sound.tone(randomBetween(3200, 5600), 0.2, {volume: 0.025, when: (index * 0.05) + (Math.random() * 0.03)});
		}
	},
	plop() {
		sound.tone(500, 0.08, {type: 'sine', volume: 0.06, slideTo: 250});
	},
};

// The newspaper on the table: Bergens Tidende, with its columns of small print, headlines, photos, and the ads of the week. Each canvas gets its own page of it.
const headlines = ['Regnrekord i Bergen', 'Brann slo Rosenborg', 'Er data klar for år 2000?', 'Fløibanen stengt i dag', 'Sol i Oslo, regn her', 'Samlekort-feber i skolegården', 'Ny Nokia med spill', 'Fisketorget: makrell i dag', 'Kongen besøker Bryggen', 'Paraplyer utsolgt'];
const advertisements = ['REMA 1000 · Kjøttkaker 29,90', 'ELKJØP · TV-spill 1 990,-', 'Brunost 1 kg 49,90', 'Telenor · Ring billig i helgen!', 'Sko · Buffalo 699,-'];
const newspaperCache = new Map();

const newspaper = (width, height, seed) => {
	const key = `${width}×${height}×${seed}`;
	if (newspaperCache.has(key)) {
		return newspaperCache.get(key);
	}

	const {canvas, context} = makeCanvas(width, height);
	const random = seededRandom(seed);
	context.fillStyle = '#e4e0d3';
	context.fillRect(0, 0, width, height);

	// The fibers of the cheap paper.
	for (let index = 0; index < width * height / 60; index++) {
		context.fillStyle = `rgba(110, 100, 80, ${0.03 + (random() * 0.05)})`;
		context.fillRect(random() * width, random() * height, 0.5 + (random() * 1.5), 0.5);
	}

	context.save();
	context.translate(width / 2, height / 2);
	context.rotate((random() - 0.5) * 0.14);
	context.translate(-width / 2, -height / 2);

	const columnWidth = 64;
	const gutter = 7;
	const top = -10 - (random() * 30);
	if (random() < 0.5) {
		context.fillStyle = 'rgba(30, 30, 30, 0.7)';
		context.font = 'bold 30px "Times New Roman", Times, serif';
		context.fillText('Bergens Tidende', 6, top + 50);
		context.fillRect(-10, top + 58, width + 20, 1.5);
	}

	for (let left = -20 - (random() * 30); left < width + 20; left += columnWidth + gutter) {
		let y = top + 66;
		while (y < height + 10) {
			const kind = random();
			if (kind < 0.18) {
				context.fillStyle = 'rgba(25, 25, 25, 0.72)';
				context.font = `bold ${10 + Math.round(random() * 4)}px "Times New Roman", Times, serif`;
				const words = headlines[Math.floor(random() * headlines.length)].split(' ');
				let line = '';
				for (const word of words) {
					if (context.measureText(`${line} ${word}`).width > columnWidth && line) {
						y += 13;
						context.fillText(line, left, y);
						line = word;
					} else {
						line = line ? `${line} ${word}` : word;
					}
				}

				y += 13;
				context.fillText(line, left, y);
				y += 6;
			} else if (kind < 0.27) {
				// A photo, printed with the dots of the newspaper.
				const photoHeight = 30 + (random() * 25);
				context.fillStyle = 'rgba(70, 70, 70, 0.25)';
				context.fillRect(left, y, columnWidth, photoHeight);
				for (let dotY = y + 2; dotY < y + photoHeight; dotY += 3) {
					for (let dotX = left + 2; dotX < left + columnWidth; dotX += 3) {
						const darkness = (Math.sin((dotX * 0.08) + seed) + Math.cos(dotY * 0.11)) * 0.5;
						context.fillStyle = `rgba(30, 30, 30, ${0.18 + (darkness * 0.15)})`;
						context.beginPath();
						context.arc(dotX, dotY, Math.max(0.2, 1 + darkness), 0, Math.PI * 2);
						context.fill();
					}
				}

				y += photoHeight + 6;
			} else if (kind < 0.33) {
				const adHeight = 34;
				context.strokeStyle = 'rgba(30, 30, 30, 0.6)';
				context.lineWidth = 1.5;
				context.strokeRect(left, y, columnWidth, adHeight);
				context.fillStyle = 'rgba(25, 25, 25, 0.75)';
				context.font = 'bold 8px Arial, sans-serif';
				const [shop, offer = ''] = advertisements[Math.floor(random() * advertisements.length)].split(' · ');
				context.fillText(shop, left + 4, y + 13, columnWidth - 8);
				context.font = 'bold 9px "Times New Roman", serif';
				context.fillText(offer, left + 4, y + 26, columnWidth - 8);
				y += adHeight + 6;
			} else {
				// A paragraph of small print, as gray lines.
				const lines = 4 + Math.floor(random() * 9);
				context.fillStyle = 'rgba(55, 55, 55, 0.3)';
				for (let line = 0; line < lines; line++) {
					const lineWidth = line === lines - 1 ? columnWidth * (0.2 + (random() * 0.6)) : columnWidth * (0.9 + (random() * 0.1));
					context.fillRect(left + (line === 0 ? 4 : 0), y, lineWidth, 1.6);
					y += 3.6;
				}

				y += 4;
			}
		}
	}

	context.restore();
	newspaperCache.set(key, canvas);
	return canvas;
};

const drawTable = (context, width, height, seed) => {
	context.drawImage(newspaper(width, height, seed), 0, 0, width, height);
};

// The paper scraps and beads that are thrown off a craft fall off the table, with a turn.
const makeFaller = ({image, x, y, width, height, spin = randomBetween(-4, 4)}) => ({
	image,
	x,
	y,
	width,
	height,
	velocityX: randomBetween(-30, 30),
	velocityY: randomBetween(-60, -10),
	angle: 0,
	spin,
});

const stepFallers = (fallers, seconds, floor) => {
	for (const faller of fallers) {
		faller.velocityY += 700 * seconds;
		faller.x += faller.velocityX * seconds;
		faller.y += faller.velocityY * seconds;
		faller.angle += faller.spin * seconds;
	}

	return fallers.filter(faller => faller.y - faller.height < floor + 40);
};

const drawFallers = (context, fallers) => {
	for (const faller of fallers) {
		context.save();
		context.translate(faller.x, faller.y);
		context.rotate(faller.angle);
		context.drawImage(faller.image, -faller.width / 2, -faller.height / 2, faller.width, faller.height);
		context.restore();
	}
};

const snowPapers = {
	white: {fill: '#fbfbf6', edge: '#c9c9c0', name: 'white paper'},
	blue: {fill: '#2f5fd0', edge: '#1c3c8c', shine: true, name: 'blue glanspapir'},
	red: {fill: '#d22b2b', edge: '#8c1515', shine: true, name: 'red glanspapir'},
	gold: {fill: '#d8b040', edge: '#8c6a10', shine: true, gold: true, name: 'gold paper'},
	news: {fill: '#e4e0d3', edge: '#a8a496', news: true, name: 'Bergens Tidende'},
};

const paperFill = (context, paper, radius) => {
	if (paper.news) {
		const pattern = context.createPattern(newspaper(260, 260, 21), 'repeat');
		pattern.setTransform(new DOMMatrix().translate(-radius, -radius).scale(1 / pixelRatio));
		return pattern;
	}

	if (paper.gold) {
		const gradient = context.createLinearGradient(-radius, -radius, radius, radius);
		gradient.addColorStop(0, '#f6e08a');
		gradient.addColorStop(0.35, '#c99a2a');
		gradient.addColorStop(0.55, '#fbeaa0');
		gradient.addColorStop(1, '#a87a18');
		return gradient;
	}

	if (paper.shine) {
		const gradient = context.createLinearGradient(-radius, -radius, radius, radius);
		gradient.addColorStop(0, paper.fill);
		gradient.addColorStop(0.45, mixColors(paper.fill, '#ffffff', 0.35));
		gradient.addColorStop(0.55, paper.fill);
		gradient.addColorStop(1, mixColors(paper.fill, '#000000', 0.2));
		return gradient;
	}

	return paper.fill;
};

const snowRadius = 130;

// The folded wedge with the cuts taken out, in the space of the paper, with the middle of the paper in the middle of the image. Each wedge is a bit wider than it needs to be, so the wedges of the unfolded snowflake overlap and have no seams.
const renderWedge = (folds, paperKey, cuts, resolution) => {
	const halfAngle = Math.PI / (2 * folds);
	const imageSize = Math.ceil(((snowRadius * 2) + 8) * resolution);
	const canvas = document.createElement('canvas');
	canvas.width = imageSize;
	canvas.height = imageSize;
	const context = canvas.getContext('2d');
	context.setTransform(resolution, 0, 0, resolution, imageSize / 2, imageSize / 2);
	const chordY = -snowRadius * Math.cos(halfAngle);
	const spread = Math.tan(halfAngle + 0.006) * -chordY;
	context.beginPath();
	context.moveTo(0, 2);
	context.lineTo(-spread, chordY);
	context.lineTo(spread, chordY);
	context.closePath();
	context.fillStyle = paperFill(context, snowPapers[paperKey], snowRadius);
	context.fill();
	context.globalCompositeOperation = 'destination-out';
	for (const cut of cuts) {
		tracePolygon(context, cut);
		context.fill();
	}

	return canvas;
};

// Draws the snowflake unfolded, or opening, with the wedge turned and mirrored around the middle like the folds of the paper. The amount is 0 while it is folded and 1 when it is open.
const drawSnowflake = (context, wedge, folds, {x, y, scale, amount = 1, resolution}) => {
	const sectors = folds * 2;
	const halfAngle = Math.PI / (2 * folds);
	for (let sector = sectors - 1; sector >= 0; sector--) {
		context.save();
		context.translate(x, y);
		context.rotate(sector * 2 * halfAngle * amount);
		if (sector % 2 === 1) {
			context.scale(-1, 1);
		}

		context.scale(scale / resolution, scale / resolution);
		context.drawImage(wedge, -wedge.width / 2, -wedge.height / 2);
		context.restore();
	}
};

export default class extends GeoCitiesElement {
	#soundLoops;
	#actions;

	connected() {
		this.#soundLoops = [];
		this.#actions = new Map();

		// The sound button of the whole table.
		const {sound: soundButton} = this.parts;
		this.on(soundButton, 'click', () => {
			sound.isOn = !sound.isOn && sound.start(this.sound());
			setPressed(soundButton, sound.isOn);
			soundButton.textContent = sound.isOn ? '🔊 Sound On' : '🔇 Sound Off';
			if (sound.isOn) {
				sounds.rattle(10, 0.3);
			} else {
				for (const loop of this.#soundLoops) {
					loop.set(0);
				}

				// The sounds that are already planned, like the rest of a rattle, stop too.
				sound.context?.suspend();
			}
		});

		this.on(this, 'click', event => {
			const button = event.target.closest('[data-crafts-action]');
			if (button && !button.disabled) {
				this.#actions.get(button.dataset.craftsAction)?.(button);
			}
		});

		this.#setUpHama();
		this.#setUpSnowflakes();
		this.#setUpSpirograph();
		this.#setUpShrinky();
	}

	// A button that turns itself off, like Into the Oven, gives the focus to the canvas of its craft, so the keyboard goes on from there.
	focusReplacement(control) {
		return control.dataset.craftsAction ? control.closest('section').querySelector('canvas') : super.focusReplacement(control);
	}

	// The swatches of a craft: the script gives each its color, and keeps one pressed.
	#setUpSwatches(group, onChoose) {
		const buttons = [...group.querySelectorAll('[data-crafts-color]')];
		for (const button of buttons) {
			const {craftsColor} = button.dataset;
			if (craftsColor.startsWith('#')) {
				button.style.setProperty('--crafts-swatch', craftsColor);
			}

			if (button.getAttribute('aria-pressed') === 'true') {
				setPressed(button, true);
			}

			this.on(button, 'click', () => {
				for (const other of buttons) {
					setPressed(other, other === button);
				}

				onChoose(craftsColor, button);
			});
		}

		return buttons;
	}

	#setUpTools(container, onChoose) {
		const buttons = [...container.querySelectorAll('[data-crafts-tool]')];
		for (const button of buttons) {
			if (button.getAttribute('aria-pressed') === 'true') {
				setPressed(button, true);
			}

			this.on(button, 'click', () => {
				for (const other of buttons) {
					setPressed(other, other === button);
				}

				onChoose(button.dataset.craftsTool);
			});
		}

		return {
			choose(tool) {
				for (const button of buttons) {
					setPressed(button, button.dataset.craftsTool === tool);
				}
			},
		};
	}

	#actionButton(name) {
		return this.querySelector(`[data-crafts-action="${name}"]`);
	}

	// MARK: Hama beads

	#setUpHama() {
		const {hamaTools, hamaColors, hamaCanvas: canvas, hamaStatus: status, hamaBoard: boardSelect, hamaPattern: patternSelect, fridge: fridgeCanvas} = this.parts;
		const context = canvas.getContext('2d');
		const fridgeContext = fridgeCanvas.getContext('2d');
		const width = 320;
		const height = 320;
		const size = 17;
		const pitch = 16;
		const origin = 8;
		const cellCount = size * size;

		let currentColor = '#c81f2b';
		let tool = 'fingers';
		const colorButtons = this.#setUpSwatches(hamaColors, color => {
			currentColor = color;
		});
		const tub = colorButtons.filter(button => button.dataset.craftsColor !== 'mixed').map(button => ({number: button.textContent.trim().slice(0, 2), color: button.dataset.craftsColor}));
		const colorOfNumber = new Map(tub.map(bead => [bead.number, bead.color]));
		currentColor = colorButtons.find(button => button.getAttribute('aria-pressed') === 'true')?.dataset.craftsColor ?? currentColor;
		this.#setUpTools(hamaTools, chosen => {
			tool = chosen;
			this.say(tool === 'tweezers' ? 'The tweezers (pinsett): one bead at a time, and they take beads off again.' : 'Fingers: drag to put on many. Sometimes one bounces off.', status);
		});

		const columnOf = index => index % size;
		const rowOf = index => Math.floor(index / size);
		const centerOf = index => ({x: origin + ((columnOf(index) + 0.5) * pitch), y: origin + ((rowOf(index) + 0.5) * pitch)});

		const starPolygon = Array.from({length: 10}, (_, index) => {
			const angle = (-Math.PI / 2) + (index * Math.PI / 5);
			const distance = index % 2 === 0 ? 9.6 : 5;
			return {x: 8 + (distance * Math.cos(angle)), y: 9.1 + (distance * Math.sin(angle))};
		});

		const masks = {
			square: Array.from({length: cellCount}, () => true),
			heart: Array.from({length: cellCount}, (_, index) => {
				const x = (columnOf(index) - 8) * 0.15;
				const y = 1.3 - (rowOf(index) * 0.145);
				return (((x * x) + (y * y) - 1) ** 3) - (x * x * y * y * y) <= 0;
			}),
			star: Array.from({length: cellCount}, (_, index) => isInPolygon(columnOf(index), rowOf(index), starPolygon)),
		};

		// The patterns of the pattern sheets, with a letter for each color of the tub, by the number Hama gives it.
		const letterNumbers = {R: '05', P: '06', W: '01', B: '08', L: '09', Y: '03', K: '18', O: '04', N: '12', E: '27', U: '07', G: '10', A: '17'};
		const flagRows = [
			'.................',
			'.................',
			'RRRRRWBBWRRRRRRRR',
			'RRRRRWBBWRRRRRRRR',
			'RRRRRWBBWRRRRRRRR',
			'RRRRRWBBWRRRRRRRR',
			'WWWWWWBBWWWWWWWWW',
			'BBBBBBBBBBBBBBBBB',
			'BBBBBBBBBBBBBBBBB',
			'WWWWWWBBWWWWWWWWW',
			'RRRRRWBBWRRRRRRRR',
			'RRRRRWBBWRRRRRRRR',
			'RRRRRWBBWRRRRRRRR',
			'RRRRRWBBWRRRRRRRR',
		];
		const unicornRows = [
			'.Y...............',
			'..YY.............',
			'...YY..PU........',
			'....WWWPUP.......',
			'...WWWWWPUP......',
			'..WWWWWWWPUP.....',
			'.WWKWWWWWWPUP....',
			'WWWWWWWWWWWPUP...',
			'WWWWWWWWWWWWPUP..',
			'WPWWWWWWWWWWWPUP.',
			'.WWWWW.WWWWWWWPUP',
			'..WWW...WWWWWWWPU',
			'........WWWWWWWWP',
			'........WWWWWWWWW',
			'.......WWWWWWWWWW',
			'.......WWWWWWWWWW',
			'.......WWWWWWWWWW',
		];
		const patterns = {
			heart: {
				board: 'heart',
				name: 'heart',
				letter(index) {
					const column = columnOf(index);
					const row = rowOf(index);
					if (!masks.heart[index]) {
						return '.';
					}

					if (column === 4 && row === 3) {
						return 'W';
					}

					return (column >= 3 && column <= 5 && row >= 2 && row <= 4) ? 'P' : 'R';
				},
			},
			flag: {
				board: 'square',
				name: 'Norwegian flag',
				letter: index => flagRows[rowOf(index)]?.[columnOf(index)] ?? '.',
			},
			waffle: {
				board: 'heart',
				name: 'waffle with brunost',
				letter(index) {
					const column = columnOf(index);
					const row = rowOf(index);
					if (!masks.heart[index]) {
						return '.';
					}

					if (row >= 6 && row <= 8 && column >= 5 && column <= 11) {
						return 'N';
					}

					return (column % 2 === 1 && row % 2 === 0) ? 'O' : 'E';
				},
			},
			unicorn: {
				board: 'square',
				name: 'Glitter the unicorn',
				letter: index => unicornRows[rowOf(index)]?.[columnOf(index)] ?? '.',
			},
		};

		const patternColors = key => Array.from({length: cellCount}, (_, index) => {
			const letter = patterns[key].letter(index);
			return letter === '.' ? undefined : colorOfNumber.get(letterNumbers[letter]);
		});

		// The bowl of loose beads, in the corner of the table.
		const bowl = {x: 292, y: 292, radius: 42};
		const bowlRandom = seededRandom(5);
		const bowlBeads = Array.from({length: 90}, () => {
			const angle = bowlRandom() * Math.PI * 2;
			const distance = Math.sqrt(bowlRandom()) * 32;
			return {x: bowl.x + (Math.cos(angle) * distance), y: bowl.y + (Math.sin(angle) * distance), color: tub[Math.floor(bowlRandom() * tub.length)].color};
		});

		const saved = this.stored('hama', {});
		let board = Object.hasOwn(masks, saved.board ?? '') ? saved.board : 'square';
		let patternKey = Object.hasOwn(patterns, saved.pattern ?? '') ? saved.pattern : '';
		let target = patternKey ? patternColors(patternKey) : undefined;
		let beads = Array.from({length: cellCount}, () => undefined);
		for (const [index, color, melt] of Array.isArray(saved.beads) ? saved.beads : []) {
			if (Number.isInteger(index) && index >= 0 && index < cellCount && isHex(color)) {
				beads[index] = {color, melt: Number(melt) || 0};
			}
		}

		let isIroning = saved.isIroning === true && beads.some(Boolean);
		let isPaperOn = true;
		let scattered = [];
		let isBowlTipped = false;
		let hasBurnt = false;
		let wasPatternDone = false;
		const particles = [];
		const iron = {x: 150, y: 140, isPressing: false, isShown: false};
		let keyPressUntil = 0;
		let cursor = (8 * size) + 8;
		let isDragging = false;
		let lastIndex;
		let lastPoint;
		let lastBounceMessage = 0;
		const hiss = makeNoiseLoop({type: 'highpass', frequency: 3500, volume: 0.07});
		this.#soundLoops.push(hiss);
		boardSelect.value = board;
		patternSelect.value = patternKey;

		const persist = () => {
			this.store('hama', {
				board,
				pattern: patternKey,
				isIroning,
				beads: beads.flatMap((bead, index) => bead ? [[index, bead.color, Math.round(bead.melt * 100) / 100]] : []),
			});
		};

		const beadCount = () => beads.filter(Boolean).length;

		const updateButtons = () => {
			this.#actionButton('hama-lift').disabled = !isIroning;
			this.#actionButton('hama-lift').textContent = isPaperOn ? '📄 Lift the Paper' : '📄 Put the Paper Back';
			this.#actionButton('hama-fridge').disabled = !isIroning;
			this.#actionButton('hama-iron').disabled = isIroning;
		};

		const drawPlate = () => {
			const mask = masks[board];
			// The clear plastic of the pegboard, over the newspaper and the pattern sheet.
			context.fillStyle = target ? 'rgba(205, 228, 246, 0.3)' : 'rgba(205, 228, 246, 0.55)';
			for (let index = 0; index < cellCount; index++) {
				if (mask[index]) {
					context.fillRect(origin + (columnOf(index) * pitch), origin + (rowOf(index) * pitch), pitch, pitch);
				}
			}

			for (let index = 0; index < cellCount; index++) {
				if (!mask[index] || beads[index]) {
					continue;
				}

				const {x, y} = centerOf(index);
				context.fillStyle = 'rgba(120, 150, 175, 0.45)';
				context.beginPath();
				context.arc(x + 0.6, y + 0.6, 2.4, 0, Math.PI * 2);
				context.fill();
				context.fillStyle = 'rgba(255, 255, 255, 0.85)';
				context.beginPath();
				context.arc(x - 0.3, y - 0.3, 1.9, 0, Math.PI * 2);
				context.fill();
			}
		};

		const drawPatternSheet = () => {
			if (!target) {
				return;
			}

			// The pattern sheet lies under the clear board, with a circle for each bead.
			context.fillStyle = '#fbfaf5';
			context.shadowColor = 'rgba(0, 0, 0, 0.25)';
			context.shadowBlur = 4;
			context.fillRect(origin - 4, origin - 4, (size * pitch) + 8, (size * pitch) + 8);
			context.shadowColor = 'transparent';
			context.lineWidth = 0.6;
			for (const [index, color] of target.entries()) {
				if (!color) {
					continue;
				}

				const {x, y} = centerOf(index);
				context.fillStyle = color;
				context.globalAlpha = 0.85;
				context.beginPath();
				context.arc(x, y, 6, 0, Math.PI * 2);
				context.fill();
				context.globalAlpha = 1;
				context.strokeStyle = 'rgba(0, 0, 0, 0.3)';
				context.stroke();
			}
		};

		const drawBead = (drawContext, x, y, color, melt, scale = 1) => {
			const flat = clamp(melt, 0, 1);
			const radius = (6.4 + (flat * 1.75)) * scale;
			const corner = radius * (1 - (flat * 0.62));
			const burn = clamp((melt - 1.5) / 1.3, 0, 0.92);
			drawContext.fillStyle = burn > 0 ? mixColors(color, '#4a2a10', burn) : color;
			drawContext.beginPath();
			drawContext.roundRect(x - radius, y - radius, radius * 2, radius * 2, corner);
			drawContext.fill();

			// The shine of the glossy plastic, which goes matte as it melts.
			const shine = drawContext.createRadialGradient(x - (radius * 0.35), y - (radius * 0.4), 0, x - (radius * 0.35), y - (radius * 0.4), radius * 1.1);
			shine.addColorStop(0, `rgba(255, 255, 255, ${0.62 - (flat * 0.42)})`);
			shine.addColorStop(1, 'rgba(255, 255, 255, 0)');
			drawContext.fillStyle = shine;
			drawContext.fill();

			// The round side of a bead is darker at its edge, until it is flat.
			const edge = drawContext.createRadialGradient(x, y, radius * 0.45, x, y, radius);
			edge.addColorStop(0, 'rgba(0, 0, 0, 0)');
			edge.addColorStop(1, `rgba(0, 0, 0, ${0.3 - (flat * 0.2)})`);
			drawContext.fillStyle = edge;
			drawContext.fill();

			// The hole in the middle closes as the bead melts.
			drawContext.fillStyle = 'rgba(35, 35, 45, 0.5)';
			drawContext.beginPath();
			drawContext.arc(x, y, ((2.7 * (1 - flat)) + (0.5 * flat)) * scale, 0, Math.PI * 2);
			drawContext.fill();

			if (melt > 2.3) {
				drawContext.fillStyle = 'rgba(25, 12, 4, 0.65)';
				drawContext.beginPath();
				drawContext.arc(x + ((((x * 7) + y) % 5) - 2) * scale, y + ((((y * 3) + x) % 5) - 2) * scale, 1.8 * scale, 0, Math.PI * 2);
				drawContext.fill();
			}
		};

		const drawLooseBead = bead => {
			context.save();
			context.translate(bead.x, bead.y);
			if (bead.isUpright) {
				context.restore();
				drawBead(context, bead.x, bead.y, bead.color, 0, 0.8);
				return;
			}

			// A bead on its side shows the tube, with the hole at the ends.
			context.rotate(bead.angle);
			context.fillStyle = bead.color;
			context.beginPath();
			context.roundRect(-4, -3.4, 8, 6.8, 2.4);
			context.fill();
			context.fillStyle = 'rgba(255, 255, 255, 0.55)';
			context.fillRect(-3.4, -2.6, 6.8, 1.6);
			context.fillStyle = 'rgba(0, 0, 0, 0.25)';
			context.fillRect(-3.4, 1.6, 6.8, 1.2);
			context.restore();
		};

		const drawBowl = () => {
			context.save();
			context.shadowColor = 'rgba(0, 0, 0, 0.35)';
			context.shadowBlur = 6;
			context.shadowOffsetX = 2;
			context.shadowOffsetY = 3;
			context.fillStyle = '#f7f6f1';
			context.beginPath();
			context.arc(bowl.x, bowl.y, bowl.radius, 0, Math.PI * 2);
			context.fill();
			context.restore();
			if (isBowlTipped) {
				// Upside down, with the foot of the bowl up.
				context.strokeStyle = 'rgba(0, 0, 0, 0.15)';
				context.lineWidth = 2;
				context.beginPath();
				context.arc(bowl.x, bowl.y, bowl.radius * 0.55, 0, Math.PI * 2);
				context.stroke();
				return;
			}

			context.fillStyle = '#e4e2da';
			context.beginPath();
			context.arc(bowl.x, bowl.y, bowl.radius - 4, 0, Math.PI * 2);
			context.fill();
			for (const bead of bowlBeads) {
				drawBead(context, bead.x, bead.y, bead.color, 0, 0.55);
			}
		};

		// The iron of Mamma, from above: a shiny sole, and the white and turquoise plastic of the 1990s on top.
		const solePath = new Path2D();
		solePath.moveTo(0, -46);
		solePath.quadraticCurveTo(26, -22, 28, 10);
		solePath.lineTo(28, 30);
		solePath.quadraticCurveTo(28, 38, 20, 38);
		solePath.lineTo(-20, 38);
		solePath.quadraticCurveTo(-28, 38, -28, 30);
		solePath.lineTo(-28, 10);
		solePath.quadraticCurveTo(-26, -22, 0, -46);
		solePath.closePath();
		const solePolygon = [{x: 0, y: -44}, {x: 14, y: -30}, {x: 24, y: -10}, {x: 27, y: 10}, {x: 27, y: 36}, {x: -27, y: 36}, {x: -27, y: 10}, {x: -24, y: -10}, {x: -14, y: -30}];

		const drawIron = () => {
			const lift = iron.isPressing ? 2 : 9;
			context.save();
			context.translate(iron.x, iron.y);
			context.save();
			context.translate(lift, lift * 1.2);
			context.fillStyle = 'rgba(0, 0, 0, 0.28)';
			context.fill(solePath);
			context.restore();
			context.translate(-lift * 0.3, -lift * 0.5);
			const metal = context.createLinearGradient(-28, 0, 28, 0);
			metal.addColorStop(0, '#8d949b');
			metal.addColorStop(0.45, '#f1f4f6');
			metal.addColorStop(1, '#7f868d');
			context.fillStyle = metal;
			context.fill(solePath);
			context.save();
			context.scale(0.84, 0.82);
			context.translate(0, 5);
			context.fillStyle = '#f4f3ee';
			context.fill(solePath);
			context.strokeStyle = 'rgba(0, 0, 0, 0.2)';
			context.lineWidth = 1;
			context.stroke(solePath);
			context.restore();
			const handle = context.createLinearGradient(-9, 0, 9, 0);
			handle.addColorStop(0, '#118a80');
			handle.addColorStop(0.5, '#3cc8ba');
			handle.addColorStop(1, '#0d7a71');
			context.fillStyle = handle;
			context.beginPath();
			context.roundRect(-8, -20, 16, 50, 8);
			context.fill();
			// The dial of the heat, on the setting for Hama: two dots, and no steam.
			context.fillStyle = '#d02020';
			context.beginPath();
			context.arc(0, 34, 3, 0, Math.PI * 2);
			context.fill();
			context.restore();
		};

		const drawPaper = () => {
			// The baking paper (bakepapir) over the board, so the beads do not stick to the iron.
			context.save();
			context.fillStyle = 'rgba(248, 243, 228, 0.74)';
			context.shadowColor = 'rgba(0, 0, 0, 0.2)';
			context.shadowBlur = 5;
			context.beginPath();
			context.moveTo(2, 4);
			context.lineTo(width - 34, 0);
			context.lineTo(width - 26, height - 46);
			context.lineTo(4, height - 40);
			context.closePath();
			context.fill();
			context.restore();
			context.strokeStyle = 'rgba(160, 140, 100, 0.25)';
			context.lineWidth = 0.8;
			const random = seededRandom(11);
			for (let index = 0; index < 9; index++) {
				context.beginPath();
				const startX = random() * width;
				context.moveTo(startX, random() * height);
				context.lineTo(startX + randomBetween(-60, 60), random() * height);
				context.stroke();
			}
		};

		const drawParticles = () => {
			for (const particle of particles) {
				const alpha = clamp(particle.life, 0, 1);
				context.fillStyle = particle.isSmoke ? `rgba(90, 70, 50, ${alpha * 0.35})` : `rgba(255, 255, 255, ${alpha * 0.6})`;
				context.beginPath();
				context.arc(particle.x, particle.y, particle.radius, 0, Math.PI * 2);
				context.fill();
			}
		};

		const render = () => {
			context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
			drawTable(context, width, height, 3);
			drawPatternSheet();
			drawPlate();
			for (const [index, bead] of beads.entries()) {
				if (bead) {
					const {x, y} = centerOf(index);
					drawBead(context, x, y, bead.color, bead.melt);
				}
			}

			drawBowl();
			for (const bead of scattered) {
				drawLooseBead(bead);
			}

			if (isIroning && isPaperOn) {
				drawPaper();
			}

			drawParticles();
			if (isIroning && isPaperOn && iron.isShown) {
				drawIron();
			}

			if (!isIroning && canvas.matches(':focus-visible')) {
				const {x, y} = centerOf(cursor);
				context.strokeStyle = '#000080';
				context.lineWidth = 2;
				context.setLineDash([3, 2]);
				context.strokeRect(x - (pitch / 2), y - (pitch / 2), pitch, pitch);
				context.setLineDash([]);
			}
		};

		const requestRender = makeRenderer(render);

		const reportPattern = () => {
			if (!target) {
				const count = beads.filter(Boolean).length;
				status.textContent = count === 0 ? 'Pick a color from the tub, and click the pegs.' : `${count} ${count === 1 ? 'bead' : 'beads'} on the board. When it is done, ask Mamma to iron it.`;
				return;
			}

			let right = 0;
			let wrong = 0;
			let total = 0;
			for (const [index, color] of target.entries()) {
				if (color) {
					total++;
					if (beads[index]?.color === color) {
						right++;
					}
				}

				if (beads[index] && beads[index].color !== color) {
					wrong++;
				}
			}

			const isDone = right === total && wrong === 0;
			status.textContent = isDone ? `The ${patterns[patternKey].name} is done, just like on the box! Now ask Mamma to iron it.` : `Pattern: ${right} of ${total} beads right${wrong > 0 ? `, and ${wrong} wrong` : ''}.`;
			if (isDone && !wasPatternDone) {
				this.celebrate();
				this.toast(`Hama ${patterns[patternKey].name} finished! ⭐`);
			}

			wasPatternDone = isDone;
		};

		const hasMotion = () => scattered.some(bead => bead.isMoving) || particles.length > 0 || (isIroning && (iron.isPressing || performance.now() < keyPressUntil));

		// Throws beads on the table, from a point, like from the bowl or from the board when it is bumped.
		const throwBead = (x, y, color, speed, angle) => {
			scattered.push({
				x,
				y,
				color,
				velocityX: Math.cos(angle) * speed,
				velocityY: Math.sin(angle) * speed,
				angle: Math.random() * Math.PI,
				spin: randomBetween(-12, 12),
				isUpright: Math.random() < 0.35,
				isMoving: true,
			});
		};

		const stepScattered = seconds => {
			for (const bead of scattered) {
				if (!bead.isMoving) {
					continue;
				}

				bead.x += bead.velocityX * seconds;
				bead.y += bead.velocityY * seconds;
				bead.angle += bead.spin * seconds;
				const friction = Math.exp(-2.4 * seconds);
				bead.velocityX *= friction;
				bead.velocityY *= friction;
				bead.spin *= friction;
				if (bead.x < 4 || bead.x > width - 4) {
					bead.velocityX *= -0.5;
					bead.x = clamp(bead.x, 4, width - 4);
				}

				if (bead.y < 4 || bead.y > height - 4) {
					bead.velocityY *= -0.5;
					bead.y = clamp(bead.y, 4, height - 4);
				}

				if (Math.hypot(bead.velocityX, bead.velocityY) < 6) {
					bead.isMoving = false;
				}
			}
		};

		const settleScattered = () => {
			// With reduced motion, the beads land at once.
			while (scattered.some(bead => bead.isMoving)) {
				stepScattered(0.05);
			}
		};

		const stepParticles = seconds => {
			for (const particle of particles) {
				particle.x += particle.velocityX * seconds;
				particle.y += particle.velocityY * seconds;
				particle.radius += seconds * 6;
				particle.life -= seconds * 0.9;
			}

			for (let index = particles.length - 1; index >= 0; index--) {
				if (particles[index].life <= 0) {
					particles.splice(index, 1);
				}
			}
		};

		const heat = seconds => {
			const isPressing = iron.isPressing || performance.now() < keyPressUntil;
			hiss.set(isPressing ? 1 : 0);
			if (!isPressing) {
				return;
			}

			let hottest = 0;
			for (const [index, bead] of beads.entries()) {
				if (!bead) {
					continue;
				}

				const {x, y} = centerOf(index);
				if (isInPolygon(x - iron.x, y - iron.y, solePolygon)) {
					bead.melt += seconds * 0.6;
					hottest = Math.max(hottest, bead.melt);
					if (bead.melt > 1.8 && Math.random() < seconds * 3 && !this.reducedMotion) {
						particles.push({x, y, velocityX: randomBetween(-6, 6), velocityY: randomBetween(-30, -14), radius: 3, life: 1.2, isSmoke: true});
					}
				}
			}

			if (!this.reducedMotion && Math.random() < seconds * 8) {
				particles.push({x: iron.x + randomBetween(-26, 26), y: iron.y + randomBetween(-30, 30), velocityX: randomBetween(-8, 8), velocityY: randomBetween(-26, -10), radius: 2, life: 0.8, isSmoke: false});
			}

			if (hottest > 1.6 && !hasBurnt) {
				hasBurnt = true;
				this.toast('Det lukter brent! (It smells burnt!) 🔥');
				this.say('Too long! The beads went brown, and it smells. Mamma opens the window and waves the dish towel.', status);
			}
		};

		// The motion can end between frames, like when the iron is let go or a key press runs out, so when the loop stops, it draws the end, stops the hiss, and saves the melt. It also stops the hiss when the board leaves the screen.
		const loop = this.loop(seconds => {
			stepScattered(seconds);
			stepParticles(seconds);
			if (isIroning && isPaperOn) {
				heat(seconds);
			}

			render();
		}, {
			while: hasMotion,
			target: canvas,
			stopped: () => {
				render();
				hiss.set(0);
				persist();
			},
		});

		const cellAt = point => {
			const column = Math.floor((point.x - origin) / pitch);
			const row = Math.floor((point.y - origin) / pitch);
			if (column < 0 || column >= size || row < 0 || row >= size) {
				return undefined;
			}

			const index = (row * size) + column;
			return masks[board][index] ? index : undefined;
		};

		const pickColor = () => currentColor === 'mixed' ? randomItem(tub).color : currentColor;

		const place = (index, canBounce) => {
			const color = pickColor();
			if (canBounce && Math.random() < 1 / 24) {
				// Fingers are not tweezers. Now and then, a bead bounces off the peg and rolls away.
				const {x, y} = centerOf(index);
				throwBead(x, y, color, randomBetween(60, 140), Math.random() * Math.PI * 2);
				if (this.reducedMotion) {
					settleScattered();
				}

				sounds.bead();
				if (performance.now() - lastBounceMessage > 4000) {
					lastBounceMessage = performance.now();
					this.say(randomItem(['Boing! One bounced off the peg and rolled away.', 'Oops, that one rolled under the newspaper.', 'One fell off. Lillesøster wants it. Nei!']), status);
				}

				loop.start();
				return;
			}

			beads[index] = {color, melt: 0};
			sounds.bead();
			reportPattern();
		};

		const useTool = (index, isFirst) => {
			if (index === undefined) {
				return;
			}

			if (tool === 'tweezers') {
				if (!isFirst) {
					return;
				}

				if (beads[index]) {
					beads[index] = undefined;
					sound.tone(1800, 0.03, {type: 'triangle', volume: 0.04});
					reportPattern();
				} else {
					place(index, false);
				}
			} else if (beads[index]) {
				if (isFirst) {
					this.say('There is a bead there already. Use the tweezers to take it off.', status);
				}
			} else {
				place(index, true);
			}

			requestRender();
		};

		const pickUp = (point, reach = 8) => {
			const index = scattered.findIndex(bead => Math.hypot(bead.x - point.x, bead.y - point.y) < reach);
			if (index === -1) {
				return false;
			}

			scattered.splice(index, 1);
			sounds.bead();
			if (scattered.length === 0) {
				isBowlTipped = false;
				this.say('All the beads are back in the bowl. Mamma is impressed!', status);
			} else {
				status.textContent = `Picked one up. ${scattered.length} left on the table.`;
			}

			requestRender();
			return true;
		};

		const announcePaperOff = () => {
			this.say('Put the paper back first, or the beads stick to Mamma’s iron!', status);
		};

		this.on(canvas, 'pointerdown', event => {
			const point = canvasPoint(canvas, event);
			canvas.setPointerCapture?.(event.pointerId);
			if (isIroning) {
				if (!isPaperOn) {
					announcePaperOff();
					return;
				}

				iron.x = point.x;
				iron.y = point.y;
				iron.isPressing = true;
				iron.isShown = true;
				loop.start();
				requestRender();
				return;
			}

			if (pickUp(point)) {
				return;
			}

			lastIndex = cellAt(point);
			lastPoint = point;
			isDragging = true;
			if (lastIndex !== undefined) {
				cursor = lastIndex;
			}

			useTool(lastIndex, true);
		});

		this.on(canvas, 'pointermove', event => {
			const point = canvasPoint(canvas, event);
			if (isIroning) {
				if (event.pointerType === 'mouse' || iron.isPressing) {
					iron.x = point.x;
					iron.y = point.y;
					iron.isShown = true;
					requestRender();
				}

				return;
			}

			if (!isDragging || tool !== 'fingers') {
				return;
			}

			// Steps along the drag, so a fast drag does not skip pegs.
			const distance = Math.hypot(point.x - lastPoint.x, point.y - lastPoint.y);
			const steps = Math.max(1, Math.ceil(distance / (pitch / 2)));
			for (let step = 1; step <= steps; step++) {
				const index = cellAt({x: lerp(lastPoint.x, point.x, step / steps), y: lerp(lastPoint.y, point.y, step / steps)});
				if (index !== undefined && index !== lastIndex) {
					lastIndex = index;
					useTool(index, false);
				}
			}

			lastPoint = point;
		});

		const endPointer = () => {
			if (isDragging) {
				isDragging = false;
				persist();
			}

			iron.isPressing = false;
			hiss.set(0);
		};

		this.on(canvas, 'pointerup', endPointer);
		this.on(canvas, 'pointercancel', endPointer);
		this.on(canvas, 'pointerleave', event => {
			if (event.pointerType === 'mouse' && isIroning) {
				iron.isShown = iron.isPressing;
				requestRender();
			}
		});

		this.on(canvas, 'keydown', event => {
			const moves = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]};
			const isIronKey = Object.hasOwn(moves, event.key) || event.key === 'Enter' || event.key === ' ';
			if (isIronKey && isIroning && !isPaperOn) {
				event.preventDefault();
				if (!event.repeat) {
					announcePaperOff();
				}
			} else if (moves[event.key]) {
				event.preventDefault();
				const [x, y] = moves[event.key];
				if (isIroning) {
					iron.isShown = true;
					iron.x = clamp(iron.x + (x * 6), 0, width);
					iron.y = clamp(iron.y + (y * 6), 0, height);
					keyPressUntil = performance.now() + 350;
					loop.start();
				} else {
					cursor = (clamp(rowOf(cursor) + y, 0, size - 1) * size) + clamp(columnOf(cursor) + x, 0, size - 1);
				}

				requestRender();
			} else if (event.key === 'Enter' || event.key === ' ') {
				event.preventDefault();
				if (isIroning) {
					iron.isShown = true;
					keyPressUntil = performance.now() + 600;
					loop.start();
				} else if (pickUp(centerOf(cursor), pitch * 0.75)) {
					// A loose bead at the cursor is picked up first, like with a click.
				} else if (masks[board][cursor]) {
					useTool(cursor, true);
					persist();
				}
			}
		});

		this.on(canvas, 'focus', requestRender);
		this.on(canvas, 'blur', requestRender);

		// Puts the beads on another board. The ones that do not fit fall off.
		const changeBoard = newBoard => {
			board = newBoard;
			boardSelect.value = board;
			let fell = 0;
			for (const [index, bead] of beads.entries()) {
				if (bead && !masks[board][index]) {
					const {x, y} = centerOf(index);
					throwBead(x, y, bead.color, randomBetween(40, 120), Math.random() * Math.PI * 2);
					beads[index] = undefined;
					fell++;
				}
			}

			if (this.reducedMotion) {
				settleScattered();
			}

			if (fell > 0) {
				sounds.rattle(Math.min(fell, 20), 0.4);
			}

			loop.start();
			return fell;
		};

		this.on(boardSelect, 'change', () => {
			if (isIroning) {
				boardSelect.value = board;
				this.say('The beads are melting on this board. Put it on the fridge first!', status);
				return;
			}

			const fell = changeBoard(boardSelect.value);
			if (patternKey && patterns[patternKey].board !== board) {
				patternKey = '';
				target = undefined;
				patternSelect.value = '';
			}

			this.say(fell > 0 ? `A new board. ${fell} beads did not fit, and fell off.` : `The ${board} board. Every Norwegian home has one in a drawer.`, status);
			persist();
			requestRender();
		});

		this.on(patternSelect, 'change', () => {
			if (isIroning && patternSelect.value && patterns[patternSelect.value].board !== board) {
				patternSelect.value = patternKey;
				this.say('That pattern needs another board, and the beads are melting on this one. Put it on the fridge first!', status);
				return;
			}

			patternKey = patternSelect.value;
			target = patternKey ? patternColors(patternKey) : undefined;
			wasPatternDone = false;
			if (patternKey && patterns[patternKey].board !== board) {
				changeBoard(patterns[patternKey].board);
			}

			if (patternKey) {
				this.say(`The pattern of the ${patterns[patternKey].name} is under the board. Put a bead on each circle, in its color.`, status);
				if (!isIroning) {
					reportPattern();
				}
			} else {
				this.say('No pattern. Make your own!', status);
			}

			persist();
			requestRender();
		});

		this.#actions.set('hama-spill', () => {
			// The bowl holds only so many, so a bowl that is over already spills less.
			const count = clamp(150 - scattered.length, 0, 46);
			for (let index = 0; index < count; index++) {
				const bead = bowlBeads[index % bowlBeads.length];
				throwBead(bead.x, bead.y, bead.color, randomBetween(150, 560), randomBetween(Math.PI * 0.95, Math.PI * 1.55));
			}

			// The elbow bumps the board too, and the loose beads jump off their pegs.
			let bumped = 0;
			for (const [index, bead] of beads.entries()) {
				if (bead && bead.melt < 0.3 && Math.random() < 0.12 && bumped < 12) {
					const {x, y} = centerOf(index);
					throwBead(x, y, bead.color, randomBetween(30, 110), Math.random() * Math.PI * 2);
					beads[index] = undefined;
					bumped++;
				}
			}

			isBowlTipped = true;
			if (this.reducedMotion) {
				settleScattered();
			}

			sounds.rattle(40, 1.2);
			this.say(`Klirr! The bowl went over${bumped > 0 ? `, and ${bumped} beads jumped off the board` : ''}. ${randomItem(['Lillesøster puts one in her mouth. Spytt ut!', 'Some rolled under the fridge. They stay there until 2004.', 'Pick them up, one by one: click them, or press Enter on them.'])}`, status);
			reportPattern();
			persist();
			loop.start();
			requestRender();
		});

		this.#actions.set('hama-empty', () => {
			const melted = beads.some(bead => bead && bead.melt > 0.3);
			const count = beadCount() + scattered.length;
			beads = beads.map(() => undefined);
			scattered = [];
			isBowlTipped = false;
			isIroning = false;
			isPaperOn = true;
			hasBurnt = false;
			wasPatternDone = false;
			iron.isShown = false;
			if (melted) {
				this.say('It was melted together, so it went in the bin (søppelbøtta). A clean board!', status);
				sounds.thump();
			} else {
				this.say(count > 0 ? `Tipped ${count} beads back in the tub. Shhhk!` : 'The board is empty already.', status);
				sounds.rattle(Math.min(count, 40) + 4, 0.8);
			}

			updateButtons();
			persist();
			requestRender();
		});

		this.#actions.set('hama-iron', () => {
			if (beadCount() === 0) {
				this.say('There is nothing to iron. Put on some beads first!', status);
				return;
			}

			isIroning = true;
			isPaperOn = true;
			iron.isShown = true;
			iron.x = width / 2;
			iron.y = height / 2;
			updateButtons();
			this.say('Mamma puts the baking paper on and hands you the hot iron. Hold it down and move it over the beads. Not too long in one place!', status);
			sounds.swish();
			persist();
			requestRender();
			canvas.focus({preventScroll: true});
		});

		this.#actions.set('hama-lift', () => {
			isPaperOn = !isPaperOn;
			updateButtons();
			sounds.swish();
			if (!isPaperOn) {
				const beadList = beads.filter(Boolean);
				const flat = beadList.filter(bead => bead.melt >= 0.45).length;
				const burnt = beadList.filter(bead => bead.melt > 1.6).length;
				this.say(`${flat} of ${beadList.length} beads are melted together${burnt > 0 ? `, and ${burnt} are burnt brown` : ''}. ${flat < beadList.length ? 'The round ones need more iron.' : 'It holds together now!'}`, status);
			}

			requestRender();
		});

		// MARK: The fridge

		// The kept things come from the browser, so only well-formed ones are used.
		let fridge = this.stored('fridge', []);
		fridge = (Array.isArray(fridge) ? fridge : []).filter(piece => Number.isFinite(piece?.angle) && isHex(piece.magnet) && Array.isArray(piece.cells) && piece.cells.length > 0 && piece.cells.every(cell => Array.isArray(cell) && Number.isInteger(cell[0]) && cell[0] >= 0 && cell[0] < cellCount && isHex(cell[1]) && Number.isFinite(cell[2])));

		const fridgeWidth = 320;
		const fridgeHeight = 110;
		const fridgeSlots = 6;

		const fridgeSlot = index => ({x: 50 + (index * 46), y: 60});

		const renderFridge = () => {
			fridgeContext.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
			const enamel = fridgeContext.createLinearGradient(0, 0, fridgeWidth, 0);
			enamel.addColorStop(0, '#e9e6dd');
			enamel.addColorStop(0.3, '#f8f7f2');
			enamel.addColorStop(1, '#e2dfd5');
			fridgeContext.fillStyle = enamel;
			fridgeContext.fillRect(0, 0, fridgeWidth, fridgeHeight);

			// The handle of the fridge door.
			const chrome = fridgeContext.createLinearGradient(6, 0, 18, 0);
			chrome.addColorStop(0, '#9aa0a6');
			chrome.addColorStop(0.5, '#ffffff');
			chrome.addColorStop(1, '#8a9096');
			fridgeContext.fillStyle = chrome;
			fridgeContext.beginPath();
			fridgeContext.roundRect(8, 14, 10, 82, 5);
			fridgeContext.fill();

			fridgeContext.font = '14px serif';
			fridgeContext.textAlign = 'center';
			fridgeContext.fillText('🐟', 306, 20);
			fridgeContext.fillText('🧲', 304, 98);
			fridgeContext.font = 'bold 5.5px Arial, sans-serif';
			fridgeContext.fillStyle = '#c4161c';
			fridgeContext.beginPath();
			fridgeContext.arc(36, 16, 11, 0, Math.PI * 2);
			fridgeContext.fill();
			fridgeContext.fillStyle = '#ffffff';
			fridgeContext.fillText('BRANN', 36, 18);

			if (fridge.length === 0) {
				fridgeContext.fillStyle = '#8a8a80';
				fridgeContext.font = '11px "Comic Sans MS", "Comic Sans", "Chalkboard SE", cursive';
				fridgeContext.fillText('The fridge door. Iron a piece, and it goes here.', fridgeWidth / 2 + 6, 60);
			}

			for (const [slot, piece] of fridge.entries()) {
				const {x, y} = fridgeSlot(slot);
				fridgeContext.save();
				fridgeContext.translate(x, y);
				fridgeContext.rotate(piece.angle);
				fridgeContext.shadowColor = 'rgba(0, 0, 0, 0.3)';
				fridgeContext.shadowBlur = 3;
				fridgeContext.shadowOffsetY = 1.5;
				// The piece fills its place on the door, whatever its size on the board.
				const columns = piece.cells.map(([index]) => index % size);
				const rows = piece.cells.map(([index]) => Math.floor(index / size));
				const left = Math.min(...columns);
				const top = Math.min(...rows);
				const spanX = Math.max(...columns) - left + 1;
				const spanY = Math.max(...rows) - top + 1;
				const cell = Math.min(4.5, 42 / Math.max(spanX, spanY));
				for (const [index, color, melt] of piece.cells) {
					const burn = clamp((melt - 1.5) / 1.3, 0, 0.92);
					fridgeContext.fillStyle = burn > 0 ? mixColors(color, '#4a2a10', burn) : color;
					fridgeContext.beginPath();
					fridgeContext.roundRect((((index % size) - left) - (spanX / 2)) * cell, ((Math.floor(index / size) - top) - (spanY / 2)) * cell, cell + 0.2, cell + 0.2, cell * clamp(0.5 - (melt * 0.4), 0.1, 0.5));
					fridgeContext.fill();
				}

				fridgeContext.shadowColor = 'transparent';
				// A magnet holds it up.
				const magnetY = (-spanY / 2 * cell) + 2;
				const magnet = fridgeContext.createRadialGradient(-1.5, magnetY - 1.5, 0, 0, magnetY, 5);
				magnet.addColorStop(0, '#ffffff');
				magnet.addColorStop(0.3, piece.magnet);
				magnet.addColorStop(1, '#00000088');
				fridgeContext.fillStyle = magnet;
				fridgeContext.beginPath();
				fridgeContext.arc(0, magnetY, 5, 0, Math.PI * 2);
				fridgeContext.fill();
				fridgeContext.restore();
			}

			fridgeContext.textAlign = 'start';
		};

		this.#actions.set('hama-fridge', () => {
			const beadList = beads.flatMap((bead, index) => bead ? [[index, bead]] : []);
			const melted = beadList.filter(([, bead]) => bead.melt >= 0.45);
			if (melted.length === 0) {
				this.say('Nothing is melted yet. It would fall apart! Iron it more.', status);
				return;
			}

			const fell = beadList.length - melted.length;
			const burnt = melted.filter(([, bead]) => bead.melt > 1.6).length;
			fridge.push({
				angle: randomBetween(-0.2, 0.2),
				magnet: randomItem(['#e03030', '#2a6fe0', '#f0c020', '#30a050']),
				cells: melted.map(([index, bead]) => [index, bead.color, Math.round(bead.melt * 10) / 10]),
			});
			let message = 'On the fridge it goes, with a magnet!';
			if (fridge.length > fridgeSlots) {
				fridge.shift();
				message += ' The oldest one goes in the drawer with the others.';
			}

			if (fell > 0) {
				message += ` ${fell} beads were not melted and fell on the floor.`;
			}

			if (burnt > 0) {
				message += ' Mamma says the brown is “rustic”.';
			}

			this.store('fridge', fridge);
			renderFridge();
			beads = beads.map(() => undefined);
			isIroning = false;
			isPaperOn = true;
			hasBurnt = false;
			wasPatternDone = false;
			iron.isShown = false;
			updateButtons();
			persist();
			requestRender();
			sounds.plop();
			this.say(message, status);
			if (fell === 0 && burnt === 0) {
				this.toast('A perfect Hama piece on the fridge! 🧲');
			}
		});

		this.on(fridgeCanvas, 'click', event => {
			const point = canvasPoint(fridgeCanvas, event);
			const slot = fridge.findIndex((_, index) => {
				const {x, y} = fridgeSlot(index);
				return Math.abs(point.x - x) < 24 && Math.abs(point.y - y) < 28;
			});
			if (slot === -1) {
				return;
			}

			const piece = fridge[slot];
			const burnt = piece.cells.some(([, , melt]) => melt > 1.6);
			this.say(burnt ? 'Mamma: “It still smells a bit burnt. But it is lovely.”' : randomItem(['Mamma: “Så fint! (So nice!)”', 'Pappa: “Did you make that? Wow.”', 'Mormor wants one for her fridge too.', 'Trond says his is bigger. It is not.']), status);
		});

		this.on(fridgeCanvas, 'keydown', event => {
			if ((event.key === 'Delete' || event.key === 'Backspace') && fridge.length > 0) {
				event.preventDefault();
				fridge.pop();
				this.store('fridge', fridge);
				renderFridge();
				this.say('Took the newest one down from the fridge.', status);
			}
		});

		updateButtons();
		if (target && !isIroning) {
			reportPattern();
			// A pattern that was done before the visitor came back is not celebrated again.
			wasPatternDone = true;
		} else if (isIroning) {
			status.textContent = 'The iron is still hot. Hold it down and move it over the paper.';
		} else {
			reportPattern();
		}

		requestRender();
		renderFridge();
		// The fonts of the newspaper and the emoji can load after the first drawing.
		document.fonts?.ready.then(() => {
			newspaperCache.clear();
			requestRender();
			renderFridge();
		});
	}

	// MARK: Paper snowflakes

	#setUpSnowflakes() {
		const {snowCanvas: canvas, snowStatus: status, snowFolds: foldsSelect, snowPaper: paperSelect, kitchenWindow: windowCanvas} = this.parts;
		const context = canvas.getContext('2d');
		const windowContext = windowCanvas.getContext('2d');
		const width = 320;
		const height = 320;
		const displayScale = 2.1;
		const apex = {x: 160, y: 304};
		const resolution = displayScale * pixelRatio;

		let folds = Number(foldsSelect.value) || 6;
		let paperKey = paperSelect.value in snowPapers ? paperSelect.value : 'white';
		let cuts = [];
		let phase = 'cutting';
		let wedge;
		let path = [];
		let isDragging = false;
		let dragStart;
		let lastSnip;
		let pointer;
		let keyboardPoint = {x: 160, y: 160};
		let fallers = [];
		let tableScraps = [];
		let unfoldAmount = 0;
		let foldAmount = 1;
		let foldFrom = 1;
		let isHung = false;

		const halfAngle = () => Math.PI / (2 * folds);
		const toPaper = point => ({x: (point.x - apex.x) / displayScale, y: (point.y - apex.y) / displayScale});
		const toScreen = point => ({x: apex.x + (point.x * displayScale), y: apex.y + (point.y * displayScale)});

		const wedgePolygon = () => {
			const chordY = -snowRadius * Math.cos(halfAngle());
			const spread = -chordY * Math.tan(halfAngle());
			return [{x: 0, y: 0}, {x: -spread, y: chordY}, {x: spread, y: chordY}];
		};

		const currentWedge = () => {
			wedge ??= renderWedge(folds, paperKey, cuts, resolution);
			return wedge;
		};

		const updateButtons = () => {
			this.#actionButton('snow-undo').disabled = phase !== 'cutting' || cuts.length === 0;
			this.#actionButton('snow-unfold').disabled = phase !== 'cutting';
			this.#actionButton('snow-hang').disabled = phase !== 'unfolded' || isHung;
		};

		const drawTableScraps = () => {
			for (const scrap of tableScraps) {
				context.save();
				context.translate(scrap.x, scrap.y);
				context.rotate(scrap.angle);
				context.fillStyle = snowPapers[scrap.paper]?.fill ?? '#ffffff';
				context.shadowColor = 'rgba(0, 0, 0, 0.25)';
				context.shadowBlur = 2;
				tracePolygon(context, scrap.shape);
				context.fill();
				context.restore();
			}
		};

		const drawFolded = () => {
			// The layers of the folded paper show at its edges.
			const polygon = wedgePolygon().map(point => toScreen(point));
			const paper = snowPapers[paperKey];
			const amount = foldAmount;
			if (amount < 1) {
				// While it folds, the paper is a fan that gets narrower with each fold.
				const steps = folds === 6 ? [Math.PI, Math.PI / 2, Math.PI / 6, Math.PI / 12] : (folds === 4 ? [Math.PI, Math.PI / 2, Math.PI / 4, Math.PI / 8] : [Math.PI, Math.PI / 2, Math.PI / 4, Math.PI / 8, Math.PI / 16]);
				const position = amount * (steps.length - 1);
				const step = Math.min(Math.floor(position), steps.length - 2);
				const fanAngle = lerp(steps[step], steps[step + 1], easeInOut(position - step));
				const scale = lerp(1, displayScale, easeInOut(amount));
				const center = {x: lerp(160, apex.x, easeInOut(amount)), y: lerp(160, apex.y, easeInOut(amount))};
				context.save();
				context.translate(center.x, center.y);
				context.scale(scale, scale);
				context.beginPath();
				context.moveTo(0, 0);
				context.arc(0, 0, snowRadius * 1.2, (-Math.PI / 2) - fanAngle, (-Math.PI / 2) + fanAngle);
				context.closePath();
				context.clip();
				context.beginPath();
				const sides = folds * 2;
				for (let side = 0; side < sides; side++) {
					const angle = (-Math.PI / 2) + halfAngle() + (side * 2 * halfAngle());
					context.lineTo(Math.cos(angle) * snowRadius, Math.sin(angle) * snowRadius);
				}

				context.closePath();
				context.fillStyle = paperFill(context, paper, snowRadius);
				context.shadowColor = 'rgba(0, 0, 0, 0.3)';
				context.shadowBlur = 6;
				context.fill();
				context.restore();
				return;
			}

			context.save();
			for (const offset of [3, 1.5]) {
				context.fillStyle = mixColors(paper.edge, '#000000', 0.1);
				context.globalAlpha = 0.55;
				tracePolygon(context, polygon.map(point => ({x: point.x + offset, y: point.y + (offset * 0.5)})));
				context.fill();
			}

			context.restore();
			context.save();
			context.shadowColor = 'rgba(0, 0, 0, 0.3)';
			context.shadowBlur = 5;
			const image = currentWedge();
			context.translate(apex.x, apex.y);
			context.scale(1 / pixelRatio, 1 / pixelRatio);
			context.drawImage(image, -image.width / 2, -image.height / 2);
			context.restore();

			// The fold, along one edge.
			context.strokeStyle = 'rgba(0, 0, 0, 0.12)';
			context.lineWidth = 1;
			context.beginPath();
			context.moveTo(polygon[0].x + 2, polygon[0].y - 4);
			context.lineTo(polygon[2].x - 2, polygon[2].y + 4);
			context.stroke();
		};

		// The scissors are at the pointer, or at the keyboard point while the keyboard has the focus.
		const scissorsPoint = () => pointer ?? (canvas.matches(':focus-visible') ? keyboardPoint : undefined);

		const drawPath = () => {
			if (path.length === 0) {
				return;
			}

			const points = path.map(point => toScreen(point));
			context.strokeStyle = '#c01818';
			context.lineWidth = 1.5;
			context.setLineDash([4, 3]);
			context.beginPath();
			for (const [index, point] of points.entries()) {
				if (index === 0) {
					context.moveTo(point.x, point.y);
				} else {
					context.lineTo(point.x, point.y);
				}
			}

			const end = isDragging ? undefined : scissorsPoint();
			if (end) {
				context.lineTo(end.x, end.y);
			}

			context.stroke();
			context.setLineDash([]);
			if (!isDragging) {
				for (const [index, point] of points.entries()) {
					context.fillStyle = index === 0 ? '#c01818' : '#ffffff';
					context.strokeStyle = '#c01818';
					context.beginPath();
					context.arc(point.x, point.y, index === 0 ? 4 : 2.5, 0, Math.PI * 2);
					context.fill();
					context.stroke();
				}
			}
		};

		const drawScissors = point => {
			context.font = '22px serif';
			context.textAlign = 'center';
			context.textBaseline = 'middle';
			context.fillText('✂️', point.x + 12, point.y + 12);
			context.textAlign = 'start';
			context.textBaseline = 'alphabetic';
		};

		const render = () => {
			context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
			drawTable(context, width, height, 7);
			drawTableScraps();
			if (phase === 'cutting') {
				drawFolded();
				drawPath();
				const point = scissorsPoint();
				if (point && foldAmount >= 1) {
					drawScissors(point);
				}
			} else {
				const amount = easeInOut(unfoldAmount);
				context.save();
				context.shadowColor = 'rgba(0, 0, 0, 0.3)';
				context.shadowBlur = 6;
				context.shadowOffsetY = 2;
				drawSnowflake(context, currentWedge(), folds, {
					x: lerp(apex.x, 160, amount),
					y: lerp(apex.y, 160, amount),
					scale: lerp(displayScale, 1.12, amount),
					amount,
					resolution,
				});
				context.restore();
				if (phase === 'unfolded') {
					// The creases of the folds stay in the paper.
					context.strokeStyle = 'rgba(0, 0, 0, 0.07)';
					context.lineWidth = 0.8;
					for (let sector = 0; sector < folds * 2; sector++) {
						const angle = (-Math.PI / 2) + halfAngle() + (sector * 2 * halfAngle());
						context.beginPath();
						context.moveTo(160, 160);
						context.lineTo(160 + (Math.cos(angle) * snowRadius * 1.1), 160 + (Math.sin(angle) * snowRadius * 1.1));
						context.stroke();
					}
				}
			}

			drawFallers(context, fallers);
		};

		const requestRender = makeRenderer(render);
		const hasMotion = () => fallers.length > 0 || (phase === 'unfolding') || foldAmount < 1;

		const loop = this.loop(seconds => {
			fallers = stepFallers(fallers, seconds, height);
			if (phase === 'unfolding') {
				unfoldAmount = Math.min(1, unfoldAmount + (seconds / 1.6));
				if (unfoldAmount >= 1) {
					finishUnfold();
				}
			}

			if (foldAmount < 1) {
				foldAmount = Math.min(1, foldAmount + (seconds / 1.8));
			}

			render();
		}, {while: hasMotion, target: canvas});

		const newPaper = () => {
			cuts = [];
			wedge = undefined;
			path = [];
			phase = 'cutting';
			isHung = false;
			unfoldAmount = 0;
			foldAmount = this.reducedMotion ? 1 : 0;
			updateButtons();
			sounds.swish();
			loop.start();
			requestRender();
		};

		const finishUnfold = () => {
			phase = 'unfolded';
			unfoldAmount = 1;
			updateButtons();
			const holes = cuts.length * folds * 2;
			let message;
			if (cuts.length === 0) {
				message = `That is just a ${folds === 6 ? 'twelve' : (folds === 4 ? 'eight' : 'sixteen')}-sided paper. Cut some holes next time!`;
			} else if (folds === 6) {
				message = `Ta-da! A real six-armed snowflake, from ${holes} cuts at once. Every snowflake is different.`;
			} else {
				message = `Ta-da! Trond says real snowflakes have six arms, so a ${folds}-armed one is a Bergen snowflake. It melts into rain.`;
			}

			this.say(message, status);
			sounds.swish();
			if (cuts.length >= 3) {
				this.toast('A paper snowflake! ❄️');
			}

			requestRender();
		};

		const cutsPaper = polygon => {
			// Samples the wedge to know if the cut takes away any paper, and how much is left.
			const wedgeShape = wedgePolygon();
			let inWedge = 0;
			let cutAway = 0;
			let leftOver = 0;
			for (let y = -snowRadius; y <= 0; y += 3) {
				for (let x = -70; x <= 70; x += 3) {
					if (!isInPolygon(x, y, wedgeShape)) {
						continue;
					}

					inWedge++;
					const isCut = isInPolygon(x, y, polygon);
					if (isCut) {
						cutAway++;
					} else if (!cuts.some(cut => isInPolygon(x, y, cut))) {
						leftOver++;
					}
				}
			}

			return {cutAway, leftOver, inWedge};
		};

		const applyCut = polygon => {
			path = [];
			if (polygon.length < 3 || polygonArea(polygon) < 2) {
				requestRender();
				return;
			}

			const {cutAway, leftOver, inWedge} = cutsPaper(polygon);
			if (cutAway === 0) {
				this.say('Snip! You only cut air. Cut into the paper.', status);
				requestRender();
				return;
			}

			// The piece that is cut out falls on the table.
			const before = currentWedge();
			const screenPoints = polygon.map(point => toScreen(point));
			const left = Math.max(0, Math.floor(Math.min(...screenPoints.map(point => point.x))));
			const top = Math.max(0, Math.floor(Math.min(...screenPoints.map(point => point.y))));
			const right = Math.min(width, Math.ceil(Math.max(...screenPoints.map(point => point.x))));
			const bottom = Math.min(height, Math.ceil(Math.max(...screenPoints.map(point => point.y))));
			if (right > left && bottom > top) {
				const {canvas: scrap, context: scrapContext} = makeCanvas(right - left, bottom - top);
				scrapContext.translate(-left, -top);
				tracePolygon(scrapContext, screenPoints);
				scrapContext.clip();
				scrapContext.translate(apex.x, apex.y);
				scrapContext.scale(1 / pixelRatio, 1 / pixelRatio);
				scrapContext.drawImage(before, -before.width / 2, -before.height / 2);
				if (!this.reducedMotion) {
					fallers.push(makeFaller({image: scrap, x: (left + right) / 2, y: (top + bottom) / 2, width: right - left, height: bottom - top}));
				}
			}

			const corners = 4 + Math.floor(Math.random() * 3);
			tableScraps.push({
				x: randomItem([randomBetween(10, 70), randomBetween(250, 310)]),
				y: randomBetween(20, 300),
				angle: Math.random() * Math.PI,
				paper: paperKey,
				shape: Array.from({length: corners}, (_, index) => {
					const angle = (index / corners) * Math.PI * 2;
					const distance = randomBetween(2, 6);
					return {x: Math.cos(angle) * distance, y: Math.sin(angle) * distance};
				}),
			});
			if (tableScraps.length > 30) {
				tableScraps.shift();
			}

			cuts.push(polygon);
			wedge = undefined;
			updateButtons();
			sounds.snip();
			if (leftOver === 0) {
				this.say('You cut it all away! Only confetti left. Undo, or fold a new paper.', status);
			} else if (leftOver < inWedge * 0.15) {
				this.say('Careful, there is hardly any paper left!', status);
			} else {
				this.say(randomItem(['Snip snip! Cut more, or unfold it.', 'Klipp! The piece falls on the newspaper.', 'Nice cut. Cuts across the folds make the best holes.']), status);
			}

			loop.start();
			requestRender();
		};

		this.on(canvas, 'pointerdown', event => {
			if (phase !== 'cutting' || foldAmount < 1) {
				return;
			}

			canvas.setPointerCapture?.(event.pointerId);
			const point = canvasPoint(canvas, event);
			pointer = point;
			dragStart = point;
			lastSnip = point;
			isDragging = false;
			requestRender();
		});

		this.on(canvas, 'pointermove', event => {
			const point = canvasPoint(canvas, event);
			pointer = event.pointerType === 'mouse' || dragStart ? point : undefined;
			if (dragStart) {
				if (!isDragging && Math.hypot(point.x - dragStart.x, point.y - dragStart.y) > 6) {
					// A drag cuts along the line of the scissors, and a new drag starts a new cut.
					isDragging = true;
					path = [toPaper(dragStart)];
				}

				if (isDragging) {
					const last = toScreen(path.at(-1));
					if (Math.hypot(point.x - last.x, point.y - last.y) > 3) {
						path.push(toPaper(point));
					}

					if (Math.hypot(point.x - lastSnip.x, point.y - lastSnip.y) > 28) {
						lastSnip = point;
						sounds.snip();
					}
				}
			}

			requestRender();
		});

		const addCorner = point => {
			if (path.length >= 3) {
				const first = toScreen(path[0]);
				if (Math.hypot(point.x - first.x, point.y - first.y) < 12) {
					applyCut(path);
					return;
				}
			}

			path.push(toPaper(point));
			sounds.snip();
			status.textContent = path.length < 3 ? 'Click more corners around the piece to cut out.' : 'Click the red dot (or press Enter on it) to finish the cut, or press Escape to stop.';
			requestRender();
		};

		this.on(canvas, 'pointerup', event => {
			if (!dragStart) {
				return;
			}

			const point = canvasPoint(canvas, event);
			if (isDragging) {
				isDragging = false;
				applyCut(path);
			} else {
				addCorner(point);
			}

			dragStart = undefined;
			if (event.pointerType !== 'mouse') {
				pointer = undefined;
			}
		});

		this.on(canvas, 'pointercancel', () => {
			dragStart = undefined;
			isDragging = false;
			path = [];
			requestRender();
		});

		this.on(canvas, 'pointerleave', event => {
			if (event.pointerType === 'mouse' && !dragStart) {
				pointer = undefined;
				requestRender();
			}
		});

		this.on(canvas, 'dblclick', () => {
			if (path.length >= 3) {
				applyCut(path);
			}
		});

		this.on(canvas, 'keydown', event => {
			const moves = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]};
			if (phase !== 'cutting') {
				return;
			}

			if (moves[event.key]) {
				event.preventDefault();
				const [x, y] = moves[event.key];
				const step = event.shiftKey ? 2 : 8;
				keyboardPoint = {x: clamp(keyboardPoint.x + (x * step), 0, width), y: clamp(keyboardPoint.y + (y * step), 0, height)};
				pointer = undefined;
				requestRender();
			} else if (event.key === 'Enter' || event.key === ' ') {
				event.preventDefault();
				addCorner(keyboardPoint);
			} else if (event.key === 'Escape' && path.length > 0) {
				event.preventDefault();
				path = [];
				this.say('Stopped cutting.', status);
				requestRender();
			} else if (event.key === 'Backspace') {
				event.preventDefault();
				if (path.length > 0) {
					path.pop();
					requestRender();
				} else {
					this.#actions.get('snow-undo')();
				}
			}
		});

		this.on(canvas, 'focus', requestRender);
		this.on(canvas, 'blur', requestRender);

		this.on(foldsSelect, 'change', () => {
			folds = Number(foldsSelect.value) || 6;
			newPaper();
			this.say(`A new paper, folded in ${folds}. Now cut!`, status);
		});

		this.on(paperSelect, 'change', () => {
			paperKey = paperSelect.value in snowPapers ? paperSelect.value : 'white';
			newPaper();
			this.say(`A new paper: ${snowPapers[paperKey].name}, folded in ${folds}.`, status);
		});

		this.#actions.set('snow-fold', () => {
			newPaper();
			this.say(`Fold, fold, fold: the paper is folded in ${folds}. Now cut pieces out of it!`, status);
		});

		this.#actions.set('snow-undo', () => {
			if (cuts.length === 0) {
				return;
			}

			cuts.pop();
			wedge = undefined;
			tableScraps.pop();
			updateButtons();
			this.say('Taped the piece back on. Mamma has the tape (teip).', status);
			requestRender();
		});

		this.#actions.set('snow-unfold', () => {
			path = [];
			phase = this.reducedMotion ? 'unfolded' : 'unfolding';
			unfoldAmount = 0;
			if (this.reducedMotion) {
				finishUnfold();
			} else {
				loop.start();
			}

			updateButtons();
			requestRender();
		});

		// MARK: The kitchen window

		let hung = this.stored('snowflakes', []);
		hung = (Array.isArray(hung) ? hung : []).filter(flake => [4, 6, 8].includes(flake?.folds) && Object.hasOwn(snowPapers, flake.paper ?? '') && Array.isArray(flake.cuts) && flake.cuts.every(cut => Array.isArray(cut) && cut.every(point => Array.isArray(point) && Number.isFinite(point[0]) && Number.isFinite(point[1]))));

		const windowWidth = 320;
		const windowHeight = 150;
		const maximumHung = 8;
		const flakeImages = new WeakMap();
		const flakeSpins = [];
		let time = 0;

		const flakeImage = flake => {
			if (!flakeImages.has(flake)) {
				const flakeSize = 64;
				const {canvas: image, context: imageContext} = makeCanvas(flakeSize, flakeSize);
				const wedgeImage = renderWedge(flake.folds, flake.paper, flake.cuts.map(cut => cut.map(([x, y]) => ({x, y}))), 0.6);
				drawSnowflake(imageContext, wedgeImage, flake.folds, {x: flakeSize / 2, y: flakeSize / 2, scale: flakeSize / (snowRadius * 2.1), resolution: 0.6});
				flakeImages.set(flake, image);
			}

			return flakeImages.get(flake);
		};

		const flakePosition = index => ({x: 30 + (((index * 37) + 10) % (windowWidth - 60)), y: 46 + ((index % 3) * 24)});

		// Bergen through the window: the gray sky, Fløyen with the colored wooden houses, and rain.
		const view = (() => {
			const {canvas: image, context: viewContext} = makeCanvas(windowWidth, windowHeight);
			const sky = viewContext.createLinearGradient(0, 0, 0, windowHeight);
			sky.addColorStop(0, '#8e98a2');
			sky.addColorStop(1, '#c4c8cc');
			viewContext.fillStyle = sky;
			viewContext.fillRect(0, 0, windowWidth, windowHeight);
			viewContext.fillStyle = '#5f6d64';
			viewContext.beginPath();
			viewContext.moveTo(0, 80);
			viewContext.quadraticCurveTo(90, 26, 180, 52);
			viewContext.quadraticCurveTo(250, 70, 320, 40);
			viewContext.lineTo(320, 150);
			viewContext.lineTo(0, 150);
			viewContext.fill();
			const random = seededRandom(31);
			for (let index = 0; index < 60; index++) {
				const x = random() * windowWidth;
				const y = 70 + (random() * 70) + (Math.abs(x - 150) * 0.1);
				viewContext.fillStyle = randomItem(['#f2efe6', '#d6c26a', '#b8432f', '#f2efe6', '#9a3a2a', '#e8d9a8']);
				viewContext.fillRect(x, y, 7, 6);
				viewContext.fillStyle = '#4a3a34';
				viewContext.beginPath();
				viewContext.moveTo(x - 1, y);
				viewContext.lineTo(x + 3.5, y - 3);
				viewContext.lineTo(x + 8, y);
				viewContext.fill();
			}

			// The fog of the rain over it all.
			viewContext.fillStyle = 'rgba(200, 205, 210, 0.35)';
			viewContext.fillRect(0, 0, windowWidth, windowHeight);
			return image;
		})();

		const drops = Array.from({length: 40}, (_, index) => ({x: (index * 47) % windowWidth, y: (index * 31) % windowHeight, speed: 140 + ((index * 13) % 80)}));
		const glassDrops = Array.from({length: 14}, (_, index) => ({x: ((index * 71) + 13) % windowWidth, y: (index * 23) % windowHeight, speed: 2 + (index % 4), radius: 1 + ((index * 7) % 3 * 0.5)}));

		const renderWindow = () => {
			windowContext.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
			windowContext.drawImage(view, 0, 0, windowWidth, windowHeight);
			windowContext.strokeStyle = 'rgba(230, 235, 240, 0.45)';
			windowContext.lineWidth = 0.8;
			for (const drop of drops) {
				windowContext.beginPath();
				windowContext.moveTo(drop.x, drop.y);
				windowContext.lineTo(drop.x - 2, drop.y + 9);
				windowContext.stroke();
			}

			for (const drop of glassDrops) {
				windowContext.fillStyle = 'rgba(255, 255, 255, 0.35)';
				windowContext.beginPath();
				windowContext.arc(drop.x, drop.y, drop.radius, 0, Math.PI * 2);
				windowContext.fill();
				windowContext.fillStyle = 'rgba(60, 70, 80, 0.3)';
				windowContext.fillRect(drop.x - 0.3, drop.y - (drop.radius * 4), 0.6, drop.radius * 3);
			}

			for (const [index, flake] of hung.entries()) {
				const {x, y} = flakePosition(index);
				const spin = flakeSpins[index] ?? {angle: index, speed: 0.5};
				windowContext.strokeStyle = 'rgba(255, 255, 255, 0.7)';
				windowContext.lineWidth = 0.6;
				windowContext.beginPath();
				windowContext.moveTo(x, 8);
				windowContext.lineTo(x, y - 26);
				windowContext.stroke();
				windowContext.fillStyle = 'rgba(255, 255, 240, 0.8)';
				windowContext.fillRect(x - 4, 6, 8, 4);
				const image = flakeImage(flake);
				windowContext.save();
				windowContext.translate(x, y);
				windowContext.rotate(Math.sin((time * 0.8) + index) * 0.05);
				windowContext.scale(Math.max(0.06, Math.abs(Math.cos(spin.angle))), 1);
				windowContext.drawImage(image, -27, -27, 54, 54);
				windowContext.restore();
			}

			// The white frame of the window, with the bar in the middle and the sill.
			windowContext.fillStyle = '#f4f2ea';
			windowContext.fillRect(0, 0, windowWidth, 6);
			windowContext.fillRect(0, 0, 6, windowHeight);
			windowContext.fillRect(windowWidth - 6, 0, 6, windowHeight);
			windowContext.fillRect((windowWidth / 2) - 3, 0, 6, windowHeight);
			windowContext.fillStyle = '#e2dfd4';
			windowContext.fillRect(0, windowHeight - 12, windowWidth, 12);
			windowContext.font = '13px serif';
			windowContext.fillText('🪴', 14, windowHeight - 8);
			windowContext.fillText('🕯️', windowWidth - 30, windowHeight - 8);
			if (hung.length === 0) {
				windowContext.fillStyle = 'rgba(40, 40, 50, 0.75)';
				windowContext.font = '11px "Comic Sans MS", "Comic Sans", "Chalkboard SE", cursive';
				windowContext.textAlign = 'center';
				windowContext.fillText('The kitchen window. Hang a snowflake here!', windowWidth / 2, 64);
				windowContext.textAlign = 'start';
			}
		};

		const windowLoop = this.loop(seconds => {
			time += seconds;
			for (const drop of drops) {
				drop.y += drop.speed * seconds;
				drop.x -= drop.speed * seconds * 0.2;
				if (drop.y > windowHeight) {
					drop.y = -10;
					drop.x = Math.random() * (windowWidth + 30);
				}
			}

			for (const drop of glassDrops) {
				drop.y += drop.speed * seconds;
				if (drop.y > windowHeight) {
					drop.y = 0;
				}
			}

			for (const [index] of hung.entries()) {
				flakeSpins[index] ??= {angle: index, speed: 0.5};
				const spin = flakeSpins[index];
				spin.angle += spin.speed * seconds;
				spin.speed = lerp(spin.speed, 0.5, Math.min(1, seconds * 0.6));
			}

			renderWindow();
		}, {while: () => !this.reducedMotion, target: windowCanvas});

		this.#actions.set('snow-hang', () => {
			hung.push({folds, paper: paperKey, cuts: cuts.map(cut => cut.map(point => [Math.round(point.x * 10) / 10, Math.round(point.y * 10) / 10]))});
			let message = 'It hangs in the kitchen window now, on a thread with a bit of tape. Look out at the rain!';
			if (hung.length > maximumHung) {
				hung.shift();
				flakeSpins.shift();
				message = 'It hangs in the window. The oldest one fell down, as the tape gave up.';
			}

			isHung = true;
			updateButtons();
			this.store('snowflakes', hung);
			renderWindow();
			windowLoop.start();
			this.say(message, status);
		});

		this.on(windowCanvas, 'click', event => {
			const point = canvasPoint(windowCanvas, event);
			const index = hung.findIndex((_, slot) => {
				const {x, y} = flakePosition(slot);
				return Math.hypot(point.x - x, point.y - y) < 28;
			});
			if (index === -1) {
				return;
			}

			flakeSpins[index] ??= {angle: index, speed: 0.5};
			if (this.reducedMotion) {
				flakeSpins[index].angle += Math.PI / 4;
				renderWindow();
			} else {
				flakeSpins[index].speed += 9;
			}

			sounds.swish();
			this.say('Phhhh! You blow on it, and it spins on its thread.', status);
		});

		this.on(windowCanvas, 'keydown', event => {
			if ((event.key === 'Delete' || event.key === 'Backspace') && hung.length > 0) {
				event.preventDefault();
				hung.pop();
				flakeSpins.length = Math.min(flakeSpins.length, hung.length);
				this.store('snowflakes', hung);
				renderWindow();
				this.say('Took the newest snowflake down from the window.', status);
			}
		});

		updateButtons();
		status.textContent = `The paper is folded in ${folds}. Cut pieces out of it!`;
		requestRender();
		renderWindow();
		document.fonts?.ready.then(() => {
			requestRender();
			renderWindow();
		});
	}

	// MARK: Spirograph

	#setUpSpirograph() {
		const {spiroColors, spiroCanvas: canvas, spiroStatus: status, spiroRing: ringSelect, spiroWheel: wheelSelect, spiroHole: holeSelect} = this.parts;
		const context = canvas.getContext('2d');
		const turnButton = this.#actionButton('spiro-turn');
		const width = 320;
		const height = 320;
		const center = {x: 160, y: 160};
		const holeFractions = [0.86, 0.74, 0.62, 0.5, 0.38, 0.26];
		const fourColors = ['#1d3fbf', '#d0202b', '#178a3a', '#1a1a1a'];
		const {canvas: ink, context: inkContext} = makeCanvas(width, height);

		let penColor = '#1d3fbf';
		this.#setUpSwatches(spiroColors, color => {
			penColor = color;
			lastPen = penAt(theta);
			this.say(color === 'four' ? 'The four-color pen! It clicks to a new color each time around.' : 'A new pen.', status);
		});

		let ringTeeth = 96;
		let isOutside = false;
		let wheelTeeth = 40;
		let holeIndex = 1;
		let pitch = 1;
		let ringRadius = 1;
		let wheelRadius = 1;
		let theta = -Math.PI / 2;
		let startTheta = theta;
		let offset = 0;
		let lastPen;
		let isClosed = false;
		let isPopped = false;
		let popPoint;
		let isHolding = false;
		let dragAngle;
		let dragTime = 0;
		let speed = 0;
		let lastSlipMessage = 0;
		let hasDrawn = false;
		let isInkSkipping = 0;

		const greatestCommonDivisor = (first, second) => second === 0 ? first : greatestCommonDivisor(second, first % second);

		const configure = () => {
			const ringValue = Number(ringSelect.value) || 96;
			isOutside = ringValue < 0;
			ringTeeth = Math.abs(ringValue);
			wheelTeeth = Number(wheelSelect.value) || 40;
			holeIndex = clamp((Number(holeSelect.value) || 2) - 1, 0, holeFractions.length - 1);
			// The teeth are as big on every wheel, so they fit together. Around the outside of the ring, everything is smaller, so it fits on the paper.
			pitch = isOutside ? (2 * Math.PI * 142) / (ringTeeth + (2 * wheelTeeth)) : (2 * Math.PI * 128) / 105;
			ringRadius = (ringTeeth * pitch) / (2 * Math.PI);
			wheelRadius = (wheelTeeth * pitch) / (2 * Math.PI);
			startTheta = theta;
			isClosed = false;
			lastPen = penAt(theta);
		};

		const wheelState = angle => {
			const distance = isOutside ? ringRadius + wheelRadius : ringRadius - wheelRadius;
			const ratio = distance / wheelRadius;
			const wheelAngle = (isOutside ? ratio * angle : -ratio * angle) + offset;
			return {
				x: center.x + (Math.cos(angle) * distance),
				y: center.y + (Math.sin(angle) * distance),
				wheelAngle,
			};
		};

		const penAt = angle => {
			const wheel = wheelState(angle);
			const distance = wheelRadius * holeFractions[holeIndex];
			return {x: wheel.x + (Math.cos(wheel.wheelAngle) * distance), y: wheel.y + (Math.sin(wheel.wheelAngle) * distance)};
		};

		const turnsToClose = () => wheelTeeth / greatestCommonDivisor(ringTeeth, wheelTeeth);
		const points = () => ringTeeth / greatestCommonDivisor(ringTeeth, wheelTeeth);

		const inkColor = () => penColor === 'four' ? fourColors[Math.floor(Math.abs(theta - startTheta) / (Math.PI * 2)) % 4] : penColor;

		const drawPaper = () => {
			drawTable(context, width, height, 13);
			context.save();
			context.shadowColor = 'rgba(0, 0, 0, 0.3)';
			context.shadowBlur = 6;
			context.shadowOffsetY = 2;
			context.fillStyle = '#fdfdfb';
			context.fillRect(8, 8, width - 16, height - 16);
			context.restore();
			context.drawImage(ink, 0, 0, width, height);
			// The drawing pins that hold the paper on the cardboard.
			for (const [x, y] of [[16, 16], [width - 16, 16], [16, height - 16], [width - 16, height - 16]]) {
				const pin = context.createRadialGradient(x - 1, y - 1, 0, x, y, 5);
				pin.addColorStop(0, '#ffffff');
				pin.addColorStop(0.35, '#d42020');
				pin.addColorStop(1, '#6a0a0a');
				context.fillStyle = pin;
				context.beginPath();
				context.arc(x, y, 4.5, 0, Math.PI * 2);
				context.fill();
			}
		};

		const drawGear = (x, y, radius, teeth, rotation, {fill, stroke, isInnerTeeth = false, outerRadius, holeRadius}) => {
			context.save();
			context.translate(x, y);
			context.rotate(rotation);
			context.beginPath();
			if (isInnerTeeth) {
				context.arc(0, 0, outerRadius, 0, Math.PI * 2);
			}

			const toothDepth = Math.min(2.2, pitch * 0.3);
			for (let tooth = 0; tooth <= teeth * 2; tooth++) {
				const angle = (tooth / (teeth * 2)) * Math.PI * 2;
				const distance = radius + (tooth % 2 === 0 ? toothDepth : -toothDepth) * (isInnerTeeth ? -1 : 1);
				if (tooth === 0) {
					context.moveTo(Math.cos(angle) * distance, Math.sin(angle) * distance);
				} else {
					context.lineTo(Math.cos(angle) * distance, Math.sin(angle) * distance);
				}
			}

			context.closePath();
			if (holeRadius) {
				context.moveTo(holeRadius, 0);
				context.arc(0, 0, holeRadius, 0, Math.PI * 2);
			}

			context.fillStyle = fill;
			context.fill('evenodd');
			context.strokeStyle = stroke;
			context.lineWidth = 0.8;
			context.stroke();
			context.restore();
		};

		const drawWheel = (x, y, wheelAngle) => {
			const colors = [['rgba(255, 214, 40, 0.42)', 'rgba(170, 120, 0, 0.7)'], ['rgba(60, 200, 90, 0.38)', 'rgba(20, 110, 40, 0.7)'], ['rgba(255, 90, 160, 0.38)', 'rgba(160, 20, 80, 0.7)']];
			const [fill, stroke] = colors[wheelTeeth % 3];
			drawGear(x, y, wheelRadius, wheelTeeth, wheelAngle, {fill, stroke});
			context.save();
			context.translate(x, y);
			context.rotate(wheelAngle);
			// The holes for the pen, on a spiral, with the chosen one along the angle of the wheel.
			for (const [index, fraction] of holeFractions.entries()) {
				const angle = (index - holeIndex) * 0.95;
				context.fillStyle = 'rgba(255, 255, 255, 0.75)';
				context.strokeStyle = stroke;
				context.lineWidth = 0.7;
				context.beginPath();
				context.arc(Math.cos(angle) * wheelRadius * fraction, Math.sin(angle) * wheelRadius * fraction, 2.2, 0, Math.PI * 2);
				context.fill();
				context.stroke();
			}

			context.fillStyle = stroke;
			context.font = 'bold 8px Arial, sans-serif';
			context.textAlign = 'center';
			context.fillText(String(wheelTeeth), 0, 3);
			context.textAlign = 'start';
			context.restore();
		};

		const drawPen = point => {
			context.save();
			context.strokeStyle = 'rgba(0, 0, 0, 0.2)';
			context.lineWidth = 6;
			context.lineCap = 'round';
			context.beginPath();
			context.moveTo(point.x + 4, point.y + 6);
			context.lineTo(point.x + 34, point.y + 44);
			context.stroke();
			const color = inkColor();
			context.strokeStyle = color;
			context.lineWidth = 5;
			context.beginPath();
			context.moveTo(point.x + 2, point.y + 2);
			context.lineTo(point.x + 30, point.y + 38);
			context.stroke();
			context.strokeStyle = 'rgba(255, 255, 255, 0.5)';
			context.lineWidth = 1.2;
			context.beginPath();
			context.moveTo(point.x + 4, point.y + 3);
			context.lineTo(point.x + 30, point.y + 36);
			context.stroke();
			context.fillStyle = '#c8c8c8';
			context.beginPath();
			context.arc(point.x, point.y, 1.8, 0, Math.PI * 2);
			context.fill();
			context.restore();
		};

		const render = () => {
			context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
			drawPaper();
			if (isOutside) {
				// The outside of the ring has 144 teeth, and the inside 96, so the hole is two thirds of it. Two pins hold it still.
				drawGear(center.x, center.y, ringRadius, ringTeeth, 0, {fill: 'rgba(120, 180, 255, 0.35)', stroke: 'rgba(40, 90, 170, 0.7)', holeRadius: ringRadius * 96 / 144});
				context.fillStyle = '#d42020';
				for (const side of [-1, 1]) {
					context.beginPath();
					context.arc(center.x + (side * ringRadius * 0.83), center.y, 3, 0, Math.PI * 2);
					context.fill();
				}
			} else {
				drawGear(center.x, center.y, ringRadius, ringTeeth, 0, {fill: 'rgba(120, 180, 255, 0.35)', stroke: 'rgba(40, 90, 170, 0.7)', isInnerTeeth: true, outerRadius: Math.min(ringRadius + 16, 150)});
			}

			context.fillStyle = 'rgba(40, 90, 170, 0.8)';
			context.font = 'bold 7px Arial, sans-serif';
			context.textAlign = 'center';
			context.fillText(`${ringTeeth}   SPIROGRAPH`, center.x, isOutside ? center.y + (ringRadius * 0.86) : center.y + ringRadius + 10);
			context.textAlign = 'start';
			if (isPopped) {
				const wheel = wheelState(theta);
				drawWheel(popPoint.x, popPoint.y, wheel.wheelAngle + 1.2);
			} else {
				const wheel = wheelState(theta);
				drawWheel(wheel.x, wheel.y, wheel.wheelAngle);
				drawPen(penAt(theta));
			}
		};

		const requestRender = makeRenderer(render);

		const announceSetup = () => {
			const turns = turnsToClose();
			this.say(`The ${wheelTeeth} wheel ${isOutside ? 'around' : 'in'} the ${ringTeeth} ring: it closes after ${turns} ${turns === 1 ? 'time' : 'times'} around, with ${points()} points.`, status);
		};

		const popOut = pen => {
			isPopped = true;
			isHolding = false;
			const angle = Math.random() * Math.PI * 2;
			const length = randomBetween(60, 110);
			const end = {x: clamp(pen.x + (Math.cos(angle) * length), 12, width - 12), y: clamp(pen.y + (Math.sin(angle) * length), 12, height - 12)};
			inkContext.strokeStyle = inkColor();
			inkContext.lineWidth = 1.2;
			inkContext.beginPath();
			inkContext.moveTo(pen.x, pen.y);
			inkContext.quadraticCurveTo(pen.x + randomBetween(-40, 40), pen.y + randomBetween(-40, 40), end.x, end.y);
			inkContext.stroke();
			popPoint = end;
			sounds.boing();
			this.say('Æsj! Too fast, and the wheel flew out. It drew a line right across. Click the ring to put the wheel back.', status);
			this.toast('The Spirograph wheel flew out! 🙈');
		};

		// Turns the wheel by an angle around the ring, in small steps, and draws with the pen.
		const turn = (delta, turnSpeed) => {
			if (isPopped) {
				return;
			}

			const steps = Math.max(1, Math.ceil(Math.abs(delta) / 0.015));
			const step = delta / steps;
			for (let index = 0; index < steps; index++) {
				theta += step;
				// A fast hand makes the wheel slip a tooth, and a very fast one makes it fly out.
				const slipChance = Math.abs(step) * (0.012 + (Math.max(0, turnSpeed - 5) * 0.03));
				if (Math.random() < slipChance) {
					offset += (Math.random() < 0.5 ? 1 : -1) * (Math.PI * 2) / wheelTeeth;
					sounds.slip();
					if (performance.now() - lastSlipMessage > 3000) {
						lastSlipMessage = performance.now();
						this.say('Tk! The wheel slipped a tooth. Now the pattern has a kink, like on a real one.', status);
					}
				}

				const pen = penAt(theta);
				if (turnSpeed > 13 && Math.random() < Math.abs(step) * 0.6) {
					popOut(pen);
					break;
				}

				// The ballpoint skips now and then, and leaves a blob of ink.
				if (isInkSkipping > 0) {
					isInkSkipping -= Math.abs(step);
				} else if (Math.random() < Math.abs(step) * 0.015) {
					isInkSkipping = randomBetween(0.05, 0.2);
				}

				inkContext.strokeStyle = inkColor();
				inkContext.globalAlpha = isInkSkipping > 0 ? 0.25 : 0.88;
				inkContext.lineWidth = 1.05;
				inkContext.lineCap = 'round';
				inkContext.beginPath();
				inkContext.moveTo(lastPen.x, lastPen.y);
				inkContext.lineTo(pen.x, pen.y);
				inkContext.stroke();
				inkContext.globalAlpha = 1;
				if (Math.random() < Math.abs(step) * 0.006) {
					inkContext.fillStyle = inkColor();
					inkContext.beginPath();
					inkContext.arc(pen.x, pen.y, randomBetween(1.4, 2.4), 0, Math.PI * 2);
					inkContext.fill();
				}

				lastPen = pen;
				hasDrawn = true;
			}

			if (!isClosed && Math.abs(theta - startTheta) >= (turnsToClose() * Math.PI * 2) - 0.01) {
				isClosed = true;
				this.say(`Ferdig! The pattern closed after ${turnsToClose()} times around, with ${points()} points. Try another wheel on top!`, status);
				this.celebrate();
			}

			requestRender();
		};

		const loop = this.loop(seconds => {
			if (isHolding) {
				turn(4.5 * seconds, 4.5);
			}
		}, {while: () => isHolding, target: canvas});

		this.on(canvas, 'pointerdown', event => {
			const point = canvasPoint(canvas, event);
			canvas.setPointerCapture?.(event.pointerId);
			if (isPopped) {
				isPopped = false;
				lastPen = penAt(theta);
				sounds.slip();
				this.say('Klikk. The wheel is back in the ring. Gently now!', status);
				requestRender();
				return;
			}

			dragAngle = Math.atan2(point.y - center.y, point.x - center.x);
			dragTime = performance.now();
			speed = 0;
		});

		this.on(canvas, 'pointermove', event => {
			if (dragAngle === undefined) {
				return;
			}

			const point = canvasPoint(canvas, event);
			if (Math.hypot(point.x - center.x, point.y - center.y) < 6) {
				return;
			}

			const angle = Math.atan2(point.y - center.y, point.x - center.x);
			let delta = angle - dragAngle;
			if (delta > Math.PI) {
				delta -= Math.PI * 2;
			} else if (delta < -Math.PI) {
				delta += Math.PI * 2;
			}

			const now = performance.now();
			const seconds = Math.max((now - dragTime) / 1000, 0.008);
			speed = lerp(speed, Math.abs(delta) / seconds, 0.3);
			dragAngle = angle;
			dragTime = now;
			turn(delta, speed);
		});

		const endDrag = () => {
			dragAngle = undefined;
			if (hasDrawn && !isClosed && !isPopped) {
				const turns = Math.floor(Math.abs(theta - startTheta) / (Math.PI * 2));
				status.textContent = `${turns} of ${turnsToClose()} times around. Keep going!`;
			}
		};

		this.on(canvas, 'pointerup', endDrag);
		this.on(canvas, 'pointercancel', endDrag);

		this.on(canvas, 'keydown', event => {
			if (['ArrowRight', 'ArrowDown', 'ArrowLeft', 'ArrowUp'].includes(event.key)) {
				event.preventDefault();
				if (isPopped) {
					isPopped = false;
					lastPen = penAt(theta);
					requestRender();
					return;
				}

				turn(['ArrowRight', 'ArrowDown'].includes(event.key) ? 0.12 : -0.12, 2);
			}
		});

		let holdStart = 0;
		const startHolding = () => {
			if (isPopped) {
				this.say('The wheel is out! Click the ring to put it back first.', status);
				return;
			}

			isHolding = true;
			holdStart = performance.now();
			setPressed(turnButton, true);
			loop.start();
		};

		const stopHolding = () => {
			// A quick click only turns it a little, so the first-time visitor learns to hold the button.
			if (isHolding && performance.now() - holdStart < 300) {
				this.say('Hold the button down, and the wheel goes around and around.', status);
			}

			isHolding = false;
			setPressed(turnButton, false);
			endDrag();
		};

		this.on(turnButton, 'pointerdown', event => {
			turnButton.setPointerCapture?.(event.pointerId);
			startHolding();
		});
		this.on(turnButton, 'pointerup', stopHolding);
		this.on(turnButton, 'pointercancel', stopHolding);
		this.on(turnButton, 'contextmenu', event => {
			event.preventDefault();
		});
		this.on(turnButton, 'keydown', event => {
			if ((event.key === ' ' || event.key === 'Enter') && !event.repeat) {
				event.preventDefault();
				startHolding();
			}
		});
		this.on(turnButton, 'keyup', event => {
			if (event.key === ' ' || event.key === 'Enter') {
				stopHolding();
			}
		});
		this.on(turnButton, 'blur', stopHolding);

		for (const select of [ringSelect, wheelSelect, holeSelect]) {
			this.on(select, 'change', () => {
				configure();
				announceSetup();
				requestRender();
			});
		}

		this.#actions.set('spiro-shift', () => {
			offset += (Math.PI * 2 * 3) / wheelTeeth;
			startTheta = theta;
			isClosed = false;
			lastPen = penAt(theta);
			sounds.slip();
			this.say('Lifted the wheel and put it back three teeth on. Draw again, and the pattern turns a bit, like a rosette.', status);
			requestRender();
		});

		this.#actions.set('spiro-clear', () => {
			inkContext.clearRect(0, 0, width, height);
			startTheta = theta;
			isClosed = false;
			hasDrawn = false;
			isPopped = false;
			lastPen = penAt(theta);
			sounds.swish();
			this.say('Riiip! A new paper, pinned on the cardboard.', status);
			requestRender();
		});

		this.#actions.set('spiro-save', () => {
			const {canvas: output, context: outputContext} = makeCanvas(width, height);
			outputContext.fillStyle = '#ffffff';
			outputContext.fillRect(0, 0, width, height);
			outputContext.drawImage(ink, 0, 0, width, height);
			output.toBlob(blob => {
				if (!blob) {
					return;
				}

				const link = document.createElement('a');
				link.href = URL.createObjectURL(blob);
				link.download = 'spirograph.png';
				link.click();
				setTimeout(() => {
					URL.revokeObjectURL(link.href);
				}, 1000);
				this.say(hasDrawn ? 'Saved as spirograph.png. Print it out for Mormor!' : 'Saved an empty paper as spirograph.png. Very modern art.', status);
			});
		});

		configure();
		announceSetup();
		requestRender();
		document.fonts?.ready.then(requestRender);
	}

	// MARK: Shrinky Dinks

	#setUpShrinky() {
		const {shrinkTools, shrinkColors, shrinkCanvas: canvas, shrinkStatus: status, keyring: keyringCanvas} = this.parts;
		const context = canvas.getContext('2d');
		const keyringContext = keyringCanvas.getContext('2d');
		const width = 320;
		const height = 280;
		const sheet = {x: 70, y: 20, width: 180, height: 240};
		const {canvas: ink, context: inkContext} = makeCanvas(width, height);
		const fan = makeNoiseLoop({type: 'lowpass', frequency: 260, volume: 0.05});
		this.#soundLoops.push(fan);

		let markerColor = '#151515';
		let tool = 'draw';
		let cuts = [];
		let hole;
		let isTracing = false;
		let phase = 'draw';
		let progress = 0;
		let hasDinged = false;
		let hasSmoked = false;
		let strokePoint;
		let cutPath = [];
		let lastSnip;
		let pointer;
		let keyboardPoint = {x: 160, y: 140};
		let isKeyDrawing = false;
		let fallers = [];
		let charm;
		let hasDrawn = false;
		let time = 0;

		this.#setUpSwatches(shrinkColors, color => {
			markerColor = color;
			tools.choose('draw');
			tool = 'draw';
		});
		const tools = this.#setUpTools(shrinkTools, chosen => {
			tool = chosen;
			const messages = {
				draw: 'The markers. Draw on the rough side!',
				cut: 'The scissors. Drag all the way around your drawing to cut it out.',
				punch: 'The hole punch. Click where the keyring goes, not too close to the edge.',
			};
			this.say(messages[tool], status);
			requestRender();
		});

		const clipShape = drawContext => {
			drawContext.beginPath();
			drawContext.roundRect(sheet.x, sheet.y, sheet.width, sheet.height, 3);
			drawContext.clip();
			for (const cut of cuts) {
				tracePolygon(drawContext, cut);
				drawContext.clip();
			}
		};

		const isInShape = (x, y) => x > sheet.x && x < sheet.x + sheet.width && y > sheet.y && y < sheet.y + sheet.height && cuts.every(cut => isInPolygon(x, y, cut));

		const shapeBounds = () => {
			let left = sheet.x;
			let top = sheet.y;
			let right = sheet.x + sheet.width;
			let bottom = sheet.y + sheet.height;
			for (const cut of cuts) {
				left = Math.max(left, Math.min(...cut.map(point => point.x)));
				top = Math.max(top, Math.min(...cut.map(point => point.y)));
				right = Math.min(right, Math.max(...cut.map(point => point.x)));
				bottom = Math.min(bottom, Math.max(...cut.map(point => point.y)));
			}

			return {left: Math.floor(left) - 2, top: Math.floor(top) - 2, right: Math.ceil(right) + 2, bottom: Math.ceil(bottom) + 2};
		};

		// The frost of the plastic, which takes the color of the markers.
		const frost = (() => {
			const {canvas: image, context: frostContext} = makeCanvas(64, 64);
			const random = seededRandom(17);
			frostContext.fillStyle = 'rgba(250, 250, 246, 0.86)';
			frostContext.fillRect(0, 0, 64, 64);
			for (let index = 0; index < 500; index++) {
				frostContext.fillStyle = `rgba(${random() < 0.5 ? '255, 255, 255' : '190, 190, 185'}, 0.35)`;
				frostContext.fillRect(random() * 64, random() * 64, 0.6, 0.6);
			}

			return image;
		})();

		// The piece is drawn on the same canvas on each frame, and on a new one for the oven.
		const pieceLayer = makeCanvas(width, height);

		// The piece of plastic as it is now: the frosted sheet, cut to its shape, with the drawing and the hole.
		const renderPiece = ({canvas: piece, context: pieceContext} = makeCanvas(width, height)) => {
			pieceContext.clearRect(0, 0, width, height);
			pieceContext.save();
			clipShape(pieceContext);
			const pattern = pieceContext.createPattern(frost, 'repeat');
			pattern.setTransform(new DOMMatrix().scale(1 / pixelRatio));
			pieceContext.fillStyle = pattern;
			pieceContext.fillRect(0, 0, width, height);
			pieceContext.drawImage(ink, 0, 0, width, height);
			pieceContext.restore();
			if (hole) {
				pieceContext.globalCompositeOperation = 'destination-out';
				pieceContext.beginPath();
				pieceContext.arc(hole.x, hole.y, 6, 0, Math.PI * 2);
				pieceContext.fill();
				pieceContext.globalCompositeOperation = 'source-over';
			}

			return piece;
		};

		// Glitter, printed from the computer, for tracing under the plastic.
		const drawGlitter = drawContext => {
			drawContext.save();
			drawContext.fillStyle = '#ffffff';
			drawContext.shadowColor = 'rgba(0, 0, 0, 0.2)';
			drawContext.shadowBlur = 4;
			drawContext.fillRect(80, 40, 160, 200);
			drawContext.shadowColor = 'transparent';
			drawContext.strokeStyle = '#111111';
			drawContext.lineWidth = 2.2;
			drawContext.lineJoin = 'round';
			drawContext.lineCap = 'round';
			drawContext.translate(160, 140);
			// The head, from the side, looking left.
			drawContext.beginPath();
			drawContext.moveTo(-10, -40);
			drawContext.bezierCurveTo(-34, -40, -50, -18, -52, 6);
			drawContext.bezierCurveTo(-54, 22, -40, 30, -26, 26);
			drawContext.bezierCurveTo(-16, 22, -12, 14, -2, 16);
			drawContext.bezierCurveTo(10, 18, 14, 40, 18, 62);
			drawContext.moveTo(-10, -40);
			drawContext.bezierCurveTo(14, -40, 34, -20, 44, 10);
			drawContext.bezierCurveTo(50, 30, 48, 50, 46, 62);
			drawContext.stroke();
			// The horn, with its stripes.
			drawContext.beginPath();
			drawContext.moveTo(-18, -38);
			drawContext.lineTo(-30, -82);
			drawContext.lineTo(-4, -42);
			drawContext.moveTo(-21, -50);
			drawContext.lineTo(-10, -52);
			drawContext.moveTo(-25, -64);
			drawContext.lineTo(-17, -65);
			drawContext.stroke();
			// The ear, the eye with lashes, the nostril, and a smile.
			drawContext.beginPath();
			drawContext.moveTo(4, -38);
			drawContext.lineTo(12, -60);
			drawContext.lineTo(18, -32);
			drawContext.moveTo(-26, -12);
			drawContext.quadraticCurveTo(-20, -18, -14, -12);
			drawContext.moveTo(-24, -15);
			drawContext.lineTo(-27, -20);
			drawContext.moveTo(-20, -17);
			drawContext.lineTo(-20, -22);
			drawContext.moveTo(-16, -15);
			drawContext.lineTo(-13, -20);
			drawContext.moveTo(-44, 12);
			drawContext.arc(-44, 12, 2, 0, Math.PI * 2);
			drawContext.moveTo(-40, 22);
			drawContext.quadraticCurveTo(-32, 26, -26, 20);
			drawContext.stroke();
			// The curls of the mane.
			drawContext.beginPath();
			for (let curl = 0; curl < 5; curl++) {
				const x = 22 + (curl * 6);
				const y = -30 + (curl * 18);
				drawContext.moveTo(x + 9, y);
				drawContext.arc(x, y, 9, 0, Math.PI * 1.5);
			}

			drawContext.stroke();
			drawContext.font = 'bold 13px "Comic Sans MS", "Comic Sans", "Chalkboard SE", cursive';
			drawContext.fillStyle = '#111111';
			drawContext.textAlign = 'center';
			drawContext.fillText('GLITTER ♥', 0, 90);
			drawContext.restore();
		};

		const drawCursor = () => {
			const point = pointer ?? (canvas.matches(':focus-visible') ? keyboardPoint : undefined);
			if (!point) {
				return;
			}

			if (tool === 'punch') {
				context.strokeStyle = isInShape(point.x, point.y) ? '#000080' : '#c01818';
				context.lineWidth = 1.2;
				context.setLineDash([2, 2]);
				context.beginPath();
				context.arc(point.x, point.y, 6, 0, Math.PI * 2);
				context.stroke();
				context.setLineDash([]);
			} else if (tool === 'cut') {
				context.font = '20px serif';
				context.fillText('✂️', point.x + 2, point.y + 18);
			} else {
				context.fillStyle = markerColor;
				context.beginPath();
				context.arc(point.x, point.y, 2, 0, Math.PI * 2);
				context.fill();
			}
		};

		const drawDraw = () => {
			if (isTracing) {
				drawGlitter(context);
			}

			context.save();
			context.shadowColor = 'rgba(0, 0, 0, 0.25)';
			context.shadowBlur = 4;
			context.shadowOffsetY = 1;
			context.drawImage(renderPiece(pieceLayer), 0, 0, width, height);
			context.restore();
			if (cutPath.length > 1) {
				context.strokeStyle = '#c01818';
				context.lineWidth = 1.4;
				context.setLineDash([4, 3]);
				context.beginPath();
				for (const [index, point] of cutPath.entries()) {
					if (index === 0) {
						context.moveTo(point.x, point.y);
					} else {
						context.lineTo(point.x, point.y);
					}
				}

				context.stroke();
				context.setLineDash([]);
			}

			if (cuts.length === 0) {
				context.fillStyle = 'rgba(80, 80, 80, 0.5)';
				context.font = '7px Arial, sans-serif';
				context.fillText('KRYMPEPLAST · ROUGH SIDE UP', sheet.x + 6, sheet.y + sheet.height - 6);
			}

			drawCursor();
		};

		// How the piece looks in the oven at a point of the baking: first it curls up, then it lies flat again and shrinks, and if it stays in too long, it goes brown.
		const bakeLook = amount => {
			const curl = amount < 0.12 ? 0 : (amount < 0.3 ? (amount - 0.12) / 0.18 : (amount < 0.42 ? 1 : (amount < 0.6 ? 1 - ((amount - 0.42) / 0.18) : 0)));
			const shrink = amount < 0.3 ? 1 : lerp(1, 0.4, clamp((amount - 0.3) / 0.32, 0, 1));
			const thickness = 1 - ((shrink - 0.4) / 0.6);
			const burn = clamp((amount - 0.86) / 0.3, 0, 0.75);
			return {curl, shrink, thickness, burn};
		};

		const drawBakedPiece = (drawContext, piece, bounds, {x, y, amount, wobble = 0}) => {
			const {curl, shrink, thickness, burn} = bakeLook(amount);
			const pieceWidth = bounds.right - bounds.left;
			const pieceHeight = bounds.bottom - bounds.top;
			const slices = 24;
			drawContext.save();
			drawContext.translate(x, y);
			drawContext.rotate(wobble * curl);
			drawContext.scale(shrink, shrink);
			const layers = Math.round(thickness * 6);
			for (let layer = layers; layer >= 0; layer--) {
				drawContext.globalAlpha = layer === 0 ? 1 : 0.9;
				if (layer > 0) {
					drawContext.filter = `brightness(${0.55 + (burn * -0.2)}) saturate(1.4)`;
				} else {
					drawContext.filter = `saturate(${1 + (thickness * 0.9)}) contrast(${1 + (thickness * 0.25)})${burn > 0 ? ` sepia(${burn}) brightness(${1 - (burn * 0.45)})` : ''}`;
				}

				for (let slice = 0; slice < slices; slice++) {
					const relative = ((slice + 0.5) / slices) - 0.5;
					const lift = curl * ((Math.abs(relative) * 2) ** 2);
					const sourceX = bounds.left + ((slice / slices) * pieceWidth);
					const sliceWidth = pieceWidth / slices;
					const targetX = ((relative * (1 - (lift * 0.3))) * pieceWidth) - (sliceWidth / 2);
					const targetHeight = pieceHeight * (1 - (lift * 0.7));
					const targetY = (-targetHeight / 2) - (lift * 34) + (layer * 0.6 / shrink);
					drawContext.drawImage(piece, sourceX * pixelRatio, bounds.top * pixelRatio, (sliceWidth * pixelRatio) + 1, pieceHeight * pixelRatio, targetX, targetY, sliceWidth + 0.6, targetHeight);
				}
			}

			drawContext.filter = 'none';
			drawContext.globalAlpha = 1;
			if (amount > 0.98) {
				// Bubbles in the plastic, which stayed in too long.
				const random = seededRandom(3);
				drawContext.fillStyle = 'rgba(255, 240, 210, 0.45)';
				for (let bubble = 0; bubble < 14; bubble++) {
					drawContext.beginPath();
					drawContext.arc((random() - 0.5) * pieceWidth * 0.8, (random() - 0.5) * pieceHeight * 0.8, 2 + (random() * 4), 0, Math.PI * 2);
					drawContext.fill();
				}
			}

			drawContext.restore();
		};

		let bakingPiece;
		let bakingBounds;

		const drawOven = () => {
			// The inside of the oven, through the window of the door.
			const glow = 0.75 + (Math.sin(time * 9) * 0.05);
			const cavity = context.createLinearGradient(0, 0, 0, height);
			cavity.addColorStop(0, `rgba(${Math.round(120 * glow)}, ${Math.round(60 * glow)}, 20, 1)`);
			cavity.addColorStop(1, '#2a1a10');
			context.fillStyle = cavity;
			context.fillRect(0, 0, width, height);
			context.strokeStyle = `rgba(255, ${Math.round(110 + (glow * 40))}, 40, ${glow})`;
			context.lineWidth = 3;
			context.shadowColor = '#ff6a00';
			context.shadowBlur = 8;
			context.beginPath();
			for (let index = 0; index <= 12; index++) {
				context.lineTo(40 + (index * 20), index % 2 === 0 ? 34 : 46);
			}

			context.stroke();
			context.shadowColor = 'transparent';
			// The light of the oven.
			const light = context.createRadialGradient(260, 40, 0, 260, 40, 160);
			light.addColorStop(0, 'rgba(255, 220, 150, 0.45)');
			light.addColorStop(1, 'rgba(255, 220, 150, 0)');
			context.fillStyle = light;
			context.fillRect(0, 0, width, height);
			// The tray, with the baking paper.
			context.fillStyle = '#3a3a3e';
			context.beginPath();
			context.moveTo(30, 230);
			context.lineTo(290, 230);
			context.lineTo(270, 120);
			context.lineTo(50, 120);
			context.closePath();
			context.fill();
			context.fillStyle = '#e8dcc0';
			context.beginPath();
			context.moveTo(52, 222);
			context.lineTo(268, 222);
			context.lineTo(252, 128);
			context.lineTo(68, 128);
			context.closePath();
			context.fill();
			if (bakingPiece) {
				const {shrink} = bakeLook(progress);
				context.fillStyle = 'rgba(0, 0, 0, 0.18)';
				context.beginPath();
				context.ellipse(162, 178, 60 * shrink, 20 * shrink, 0, 0, Math.PI * 2);
				context.fill();
				context.save();
				context.translate(160, 175);
				context.scale(0.55, 0.42);
				drawBakedPiece(context, bakingPiece, bakingBounds, {x: 0, y: 0, amount: progress, wobble: Math.sin(time * 4) * 0.12});
				context.restore();
			}

			// The frame of the window of the oven door, with the reflections of the glass.
			context.strokeStyle = '#141414';
			context.lineWidth = 26;
			context.beginPath();
			context.roundRect(0, 0, width, height - 36, 26);
			context.stroke();
			context.fillStyle = 'rgba(255, 255, 255, 0.07)';
			context.beginPath();
			context.moveTo(40, 14);
			context.lineTo(110, 14);
			context.lineTo(40, 200);
			context.closePath();
			context.fill();
			// The front of the oven, with the knob of the heat and the timer.
			context.fillStyle = '#efeee8';
			context.fillRect(0, height - 36, width, 36);
			context.fillStyle = '#333333';
			context.font = 'bold 9px Arial, sans-serif';
			context.fillText('160 °C', 52, height - 14);
			drawKnob(30, height - 18, 0.6);
			const remaining = Math.max(0, 1 - (progress / 0.65));
			drawKnob(width - 30, height - 18, (-Math.PI * 0.75) + (remaining * Math.PI * 1.5), true);
			context.fillStyle = '#333333';
			context.fillText(remaining > 0 ? 'TIMER' : 'DING!', width - 92, height - 14);
			if (progress > 1) {
				context.fillStyle = `rgba(120, 110, 100, ${clamp((progress - 1) * 1.6, 0, 0.6)})`;
				context.fillRect(13, 13, width - 26, height - 62);
			}
		};

		const drawKnob = (x, y, angle, hasTicks = false) => {
			const knob = context.createRadialGradient(x - 3, y - 3, 0, x, y, 13);
			knob.addColorStop(0, '#ffffff');
			knob.addColorStop(1, '#a8a8a0');
			context.fillStyle = knob;
			context.beginPath();
			context.arc(x, y, 12, 0, Math.PI * 2);
			context.fill();
			context.strokeStyle = '#555555';
			context.lineWidth = 1;
			context.stroke();
			if (hasTicks) {
				for (let tick = 0; tick <= 6; tick++) {
					const tickAngle = (-Math.PI * 0.75) + (tick * Math.PI * 0.25) - (Math.PI / 2);
					context.beginPath();
					context.moveTo(x + (Math.cos(tickAngle) * 14), y + (Math.sin(tickAngle) * 14));
					context.lineTo(x + (Math.cos(tickAngle) * 16), y + (Math.sin(tickAngle) * 16));
					context.stroke();
				}
			}

			context.strokeStyle = '#c01818';
			context.lineWidth = 2;
			context.beginPath();
			context.moveTo(x, y);
			context.lineTo(x + (Math.cos(angle - (Math.PI / 2)) * 10), y + (Math.sin(angle - (Math.PI / 2)) * 10));
			context.stroke();
		};

		const drawOut = () => {
			// The charm on the table, next to a ruler, to see how small it got.
			context.fillStyle = '#f0d060';
			context.fillRect(30, 236, 260, 22);
			context.strokeStyle = '#5a4a10';
			context.lineWidth = 0.8;
			context.fillStyle = '#5a4a10';
			context.font = '6px Arial, sans-serif';
			for (let centimeter = 0; centimeter <= 20; centimeter++) {
				const x = 36 + (centimeter * 12);
				context.beginPath();
				context.moveTo(x, 236);
				context.lineTo(x, centimeter % 5 === 0 ? 246 : 242);
				context.stroke();
				if (centimeter % 5 === 0) {
					context.fillText(String(centimeter), x - 2, 254);
				}
			}

			if (charm) {
				context.save();
				context.shadowColor = 'rgba(0, 0, 0, 0.35)';
				context.shadowBlur = 4;
				context.shadowOffsetY = 2;
				context.drawImage(charm.image, 160 - (charm.width / 2), 128 - (charm.height / 2), charm.width, charm.height);
				context.restore();
			}
		};

		const render = () => {
			context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
			if (phase === 'oven') {
				drawOven();
			} else {
				drawTable(context, width, height, 23);
				if (phase === 'out') {
					drawOut();
				} else {
					drawDraw();
				}
			}

			drawFallers(context, fallers);
		};

		const requestRender = makeRenderer(render);

		const hasMotion = () => fallers.length > 0 || (phase === 'oven' && !this.reducedMotion);

		const stepBaking = seconds => {
			const before = progress;
			progress += seconds / 13;
			if (progress < 0.65 && Math.floor(progress * 13) !== Math.floor(before * 13)) {
				sounds.tick();
			}

			if (before < 0.12 && progress >= 0.12) {
				this.say('It curls up! Do not panic. It always does that.', status);
			} else if (before < 0.42 && progress >= 0.42) {
				this.say('Now it lies down flat again, and shrinks.', status);
			}

			if (!hasDinged && progress >= 0.65) {
				hasDinged = true;
				sounds.ding();
				this.say('DING! It is small, flat, and thick. Take it out now!', status);
			}

			if (!hasSmoked && progress >= 1) {
				hasSmoked = true;
				this.toast('Det lukter plast! (It smells like plastic!) 💨');
				this.say('It is going brown and bubbly! Take it out, quick!', status);
			}

			// With reduced motion, the oven only steps when the visitor looks in, so it does not hum.
			fan.set(this.reducedMotion ? 0 : 1);
		};

		const loop = this.loop(seconds => {
			time += seconds;
			fallers = stepFallers(fallers, seconds, height);
			if (phase === 'oven' && !this.reducedMotion) {
				stepBaking(seconds);
			}

			render();
		}, {
			while: hasMotion,
			target: canvas,
			// The fan stops when the oven stops, also when reduced motion turns on while it bakes, or the oven leaves the screen.
			stopped: () => {
				fan.set(0);
			},
		});

		const drawLine = (from, to) => {
			inkContext.save();
			clipShape(inkContext);
			inkContext.strokeStyle = markerColor;
			inkContext.lineWidth = 3.4;
			inkContext.lineCap = 'round';
			inkContext.lineJoin = 'round';
			inkContext.globalAlpha = 0.9;
			inkContext.beginPath();
			inkContext.moveTo(from.x, from.y);
			inkContext.lineTo(to.x + 0.01, to.y);
			inkContext.stroke();
			inkContext.restore();
			if (isInShape(to.x, to.y)) {
				hasDrawn = true;
			}
		};

		const finishCut = () => {
			const path = cutPath;
			cutPath = [];
			if (path.length < 8 || polygonArea(path) < 500) {
				if (path.length > 0) {
					this.say('Cut all the way around the drawing, in one long drag.', status);
				}

				requestRender();
				return;
			}

			// A cut that leaves no plastic only cuts the newspaper.
			const bounds = shapeBounds();
			let isLeft = false;
			for (let y = bounds.top; y <= bounds.bottom && !isLeft; y += 4) {
				for (let x = bounds.left; x <= bounds.right && !isLeft; x += 4) {
					isLeft = isInShape(x, y) && isInPolygon(x, y, path);
				}
			}

			if (!isLeft) {
				this.say('Snip! That was the newspaper. Cut around your drawing, on the plastic.', status);
				requestRender();
				return;
			}

			// The plastic outside the cut falls off the table.
			const before = renderPiece();
			const {canvas: scrap, context: scrapContext} = makeCanvas(width, height);
			scrapContext.drawImage(before, 0, 0, width, height);
			scrapContext.globalCompositeOperation = 'destination-out';
			tracePolygon(scrapContext, path);
			scrapContext.fill();
			if (!this.reducedMotion) {
				fallers.push({...makeFaller({image: scrap, x: width / 2, y: height / 2, width, height, spin: randomBetween(-1, 1)}), velocityY: -40});
			}

			cuts.push(path);
			if (hole && !isInShape(hole.x, hole.y)) {
				hole = undefined;
			}

			sounds.snip();
			this.say('Cut out! The rest falls on the floor. Punch a hole for the keyring, and it is ready for the oven.', status);
			loop.start();
			requestRender();
		};

		const punch = point => {
			const isSafe = isInShape(point.x, point.y) && Array.from({length: 12}, (_, index) => index * Math.PI / 6).every(angle => isInShape(point.x + (Math.cos(angle) * 10), point.y + (Math.sin(angle) * 10)));
			if (!isSafe) {
				this.say(isInShape(point.x, point.y) ? 'Too close to the edge. It would tear!' : 'Punch the hole in the plastic, not in the newspaper.', status);
				return;
			}

			hole = point;
			sounds.thump();
			this.say('Ka-chunk! A hole for the keyring. It shrinks too, so it was big.', status);
			requestRender();
		};

		const drawAt = point => {
			if (strokePoint) {
				drawLine(strokePoint, point);
			}

			strokePoint = point;
			if (Math.random() < 0.15) {
				sound.noise(0.05, {frequency: 2500, quality: 4, volume: 0.025});
			}
		};

		this.on(canvas, 'pointerdown', event => {
			if (phase === 'oven') {
				if (this.reducedMotion) {
					// With reduced motion, the baking goes on a step each time the visitor looks in.
					stepBaking(1.4);
					render();
				}

				return;
			}

			if (phase !== 'draw') {
				return;
			}

			canvas.setPointerCapture?.(event.pointerId);
			const point = canvasPoint(canvas, event);
			pointer = point;
			if (tool === 'draw') {
				strokePoint = point;
				drawLine(point, point);
			} else if (tool === 'cut') {
				cutPath = [point];
				lastSnip = point;
			} else {
				punch(point);
			}

			requestRender();
		});

		this.on(canvas, 'pointermove', event => {
			const point = canvasPoint(canvas, event);
			pointer = event.pointerType === 'mouse' || strokePoint || cutPath.length > 0 ? point : undefined;
			if (tool === 'draw' && strokePoint) {
				drawAt(point);
			} else if (tool === 'cut' && cutPath.length > 0) {
				if (Math.hypot(point.x - cutPath.at(-1).x, point.y - cutPath.at(-1).y) > 3) {
					cutPath.push(point);
				}

				if (Math.hypot(point.x - lastSnip.x, point.y - lastSnip.y) > 26) {
					lastSnip = point;
					sounds.snip();
				}
			}

			if (phase === 'draw') {
				requestRender();
			}
		});

		const endPointer = event => {
			strokePoint = undefined;
			if (cutPath.length > 0) {
				finishCut();
			}

			if (event.pointerType !== 'mouse') {
				pointer = undefined;
			}

			requestRender();
		};

		this.on(canvas, 'pointerup', endPointer);
		this.on(canvas, 'pointercancel', endPointer);
		this.on(canvas, 'pointerleave', event => {
			if (event.pointerType === 'mouse' && !strokePoint && cutPath.length === 0) {
				pointer = undefined;
				requestRender();
			}
		});

		this.on(canvas, 'keydown', event => {
			if (phase === 'oven') {
				if (this.reducedMotion && (event.key === 'Enter' || event.key === ' ')) {
					event.preventDefault();
					stepBaking(1.4);
					render();
				}

				return;
			}

			if (phase !== 'draw') {
				return;
			}

			const moves = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]};
			if (moves[event.key]) {
				event.preventDefault();
				const [x, y] = moves[event.key];
				const step = event.shiftKey ? 2 : 6;
				const next = {x: clamp(keyboardPoint.x + (x * step), 0, width), y: clamp(keyboardPoint.y + (y * step), 0, height)};
				if (isKeyDrawing && tool === 'draw') {
					drawLine(keyboardPoint, next);
				} else if (isKeyDrawing && tool === 'cut') {
					cutPath.push(next);
				}

				keyboardPoint = next;
				pointer = undefined;
				requestRender();
			} else if (event.key === ' ' && !event.repeat) {
				event.preventDefault();
				if (tool === 'punch') {
					punch(keyboardPoint);
				} else {
					isKeyDrawing = true;
					strokePoint = undefined;
					if (tool === 'cut') {
						cutPath = [keyboardPoint];
						lastSnip = keyboardPoint;
					} else {
						drawLine(keyboardPoint, keyboardPoint);
					}

					requestRender();
				}
			} else if (event.key === 'Enter') {
				event.preventDefault();
				punch(keyboardPoint);
			}
		});

		const stopKeyDrawing = () => {
			isKeyDrawing = false;
			strokePoint = undefined;
			if (cutPath.length > 0) {
				finishCut();
			}

			requestRender();
		};

		this.on(canvas, 'blur', () => {
			if (isKeyDrawing) {
				stopKeyDrawing();
			}
		});

		this.on(canvas, 'keyup', event => {
			if (event.key === ' ' && isKeyDrawing) {
				stopKeyDrawing();
			}
		});

		this.on(canvas, 'focus', requestRender);
		this.on(canvas, 'blur', requestRender);

		const updateButtons = () => {
			this.#actionButton('shrink-bake').disabled = phase !== 'draw';
			this.#actionButton('shrink-out').disabled = phase !== 'oven';
			this.#actionButton('shrink-trace').disabled = phase !== 'draw';
			this.#actionButton('shrink-trace').textContent = isTracing ? '🦄 Take Glitter Away' : '🦄 Trace Glitter';
		};

		this.#actions.set('shrink-trace', () => {
			isTracing = !isTracing;
			updateButtons();
			this.say(isTracing ? 'A printout of Glitter is under the plastic. You can see her through it, so trace her with the markers!' : 'Took the printout away.', status);
			requestRender();
		});

		this.#actions.set('shrink-bake', () => {
			bakingPiece = renderPiece();
			bakingBounds = shapeBounds();
			phase = 'oven';
			progress = 0;
			hasDinged = false;
			hasSmoked = false;
			isTracing = false;
			updateButtons();
			let message = 'Mamma turns the oven to 160 °C, and in it goes. Watch through the window!';
			if (!hasDrawn) {
				message = 'Into the oven, with nothing on it. It will be a very plain charm!';
			} else if (cuts.length === 0) {
				message = 'You did not cut it out, so it shrinks as a rectangle. Into the oven!';
			}

			if (this.reducedMotion) {
				message += ' Click the oven window to look in.';
			}

			sounds.thump();
			this.say(message, status);
			loop.start();
			requestRender();
		});

		const makeCharm = () => {
			const {shrink} = bakeLook(progress);
			const pieceWidth = bakingBounds.right - bakingBounds.left;
			const pieceHeight = bakingBounds.bottom - bakingBounds.top;
			const charmWidth = Math.ceil((pieceWidth * shrink) + 12);
			const charmHeight = Math.ceil((pieceHeight * shrink) + 30);
			const {canvas: image, context: charmContext} = makeCanvas(charmWidth, charmHeight);
			drawBakedPiece(charmContext, bakingPiece, bakingBounds, {x: charmWidth / 2, y: charmHeight / 2, amount: progress, wobble: 0.1});
			// The shine of the hard plastic.
			charmContext.globalCompositeOperation = 'source-atop';
			const shine = charmContext.createLinearGradient(0, 0, charmWidth, charmHeight);
			shine.addColorStop(0, 'rgba(255, 255, 255, 0.35)');
			shine.addColorStop(0.4, 'rgba(255, 255, 255, 0)');
			charmContext.fillStyle = shine;
			charmContext.fillRect(0, 0, charmWidth, charmHeight);
			return {image, width: charmWidth, height: charmHeight, shrink};
		};

		// MARK: The keyring

		let keyring = this.stored('keyring', []);
		keyring = (Array.isArray(keyring) ? keyring : []).filter(item => typeof item?.image === 'string' && item.image.startsWith('data:image/png;base64,') && Number.isFinite(item.width) && Number.isFinite(item.height) && item.width > 0 && item.height > 0);

		const keyringWidth = 320;
		const keyringHeight = 110;
		const maximumCharms = 6;
		const charmImages = new WeakMap();
		const swings = [];

		const charmImage = item => {
			if (!charmImages.has(item)) {
				const image = new Image();
				// A new image loads once, so its listener does not need to be removed.
				image.addEventListener('load', () => {
					renderKeyring();
				});
				image.src = item.image;
				charmImages.set(item, image);
			}

			return charmImages.get(item);
		};

		const charmPosition = index => ({x: 60 + (index * 44), y: 24});

		const renderKeyring = () => {
			keyringContext.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
			// My school bag, of blue nylon, with the zipper along the top.
			const nylon = keyringContext.createLinearGradient(0, 0, 0, keyringHeight);
			nylon.addColorStop(0, '#2a3f8a');
			nylon.addColorStop(1, '#1a2a60');
			keyringContext.fillStyle = nylon;
			keyringContext.fillRect(0, 0, keyringWidth, keyringHeight);
			keyringContext.strokeStyle = 'rgba(255, 255, 255, 0.05)';
			for (let line = 0; line < keyringWidth; line += 3) {
				keyringContext.beginPath();
				keyringContext.moveTo(line, 0);
				keyringContext.lineTo(line - 30, keyringHeight);
				keyringContext.stroke();
			}

			keyringContext.fillStyle = '#111111';
			keyringContext.fillRect(0, 14, keyringWidth, 8);
			keyringContext.fillStyle = '#555555';
			for (let tooth = 0; tooth < keyringWidth; tooth += 4) {
				keyringContext.fillRect(tooth, 16, 2, 4);
			}

			keyringContext.font = 'bold 10px Arial, sans-serif';
			keyringContext.fillStyle = '#e8e8e8';
			keyringContext.fillText('JANSPORT', 12, 100);
			if (keyring.length === 0) {
				keyringContext.fillStyle = 'rgba(255, 255, 255, 0.75)';
				keyringContext.font = '11px "Comic Sans MS", "Comic Sans", "Chalkboard SE", cursive';
				keyringContext.textAlign = 'center';
				keyringContext.fillText('My school bag. Bake a charm with a hole, and it goes here!', keyringWidth / 2, 62);
				keyringContext.textAlign = 'start';
			}

			for (const [index, item] of keyring.entries()) {
				const {x, y} = charmPosition(index);
				const angle = swings[index] ? Math.sin(swings[index].phase) * swings[index].amplitude : 0;
				keyringContext.save();
				keyringContext.translate(x, y);
				keyringContext.rotate(angle);
				// The split ring and the ball chain.
				keyringContext.strokeStyle = '#c8ccd0';
				keyringContext.lineWidth = 1.6;
				keyringContext.beginPath();
				keyringContext.arc(0, 0, 5, 0, Math.PI * 2);
				keyringContext.stroke();
				keyringContext.fillStyle = '#c8ccd0';
				for (let ball = 0; ball < 4; ball++) {
					keyringContext.beginPath();
					keyringContext.arc(0, 8 + (ball * 3), 1.1, 0, Math.PI * 2);
					keyringContext.fill();
				}

				const image = charmImage(item);
				if (image.complete && image.naturalWidth > 0) {
					const scale = Math.min(1, 40 / Math.max(item.width, item.height));
					keyringContext.drawImage(image, -(item.width * scale) / 2, 18, item.width * scale, item.height * scale);
				}

				keyringContext.restore();
			}
		};

		const keyringLoop = this.loop(seconds => {
			for (const swing of swings) {
				if (swing) {
					swing.phase += seconds * 7;
					swing.amplitude *= Math.exp(-seconds * 1.4);
				}
			}

			renderKeyring();
		}, {while: () => !this.reducedMotion && swings.some(swing => swing && swing.amplitude > 0.01), target: keyringCanvas});

		this.on(keyringCanvas, 'click', () => {
			if (keyring.length === 0) {
				return;
			}

			for (const [index] of keyring.entries()) {
				swings[index] = {phase: index, amplitude: 0.5};
			}

			sounds.jingle();
			keyringLoop.start();
			this.say(randomItem(['Jingle jingle! Everybody at school will see it.', 'Trond wants one. He can make his own.', 'It is as hard as a LEGO brick now.']), status);
		});

		this.on(keyringCanvas, 'keydown', event => {
			if ((event.key === 'Delete' || event.key === 'Backspace') && keyring.length > 0) {
				event.preventDefault();
				keyring.pop();
				swings.length = Math.min(swings.length, keyring.length);
				this.store('keyring', keyring);
				renderKeyring();
				this.say('Took the newest charm off the keyring.', status);
			}
		});

		this.#actions.set('shrink-out', () => {
			fan.set(0);
			if (progress < 0.3) {
				phase = 'draw';
				updateButtons();
				this.say('It is still big and floppy. It needs more time in the oven!', status);
				requestRender();
				return;
			}

			charm = makeCharm();
			phase = 'out';
			updateButtons();
			const sheetCentimeters = Math.round((bakingBounds.bottom - bakingBounds.top) / 12);
			const charmCentimeters = Math.max(1, Math.round(sheetCentimeters * charm.shrink));
			let charmResult;
			if (progress < 0.5) {
				charmResult = `Too early! It cooled curled up like a taco. Mamma presses it flat under the cookbook, and it stays a bit wavy.`;
			} else if (progress < 0.62) {
				charmResult = `Almost! It shrank from ${sheetCentimeters} to ${charmCentimeters} cm, but it is still a bit thin and bendy.`;
			} else if (progress < 0.95) {
				charmResult = `Perfect! It shrank from ${sheetCentimeters} to ${charmCentimeters} cm, and it is thick and hard, with bright colors.`;
				this.celebrate();
			} else {
				charmResult = 'Burnt! It is brown and bubbly, and the whole kitchen smells of plastic. Mamma opens all the windows, in the rain.';
			}

			if (hole) {
				keyring.push({image: charm.image.toDataURL('image/png'), width: charm.width, height: charm.height});
				if (keyring.length > maximumCharms) {
					keyring.shift();
					swings.shift();
				}

				this.store('keyring', keyring);
				renderKeyring();
				charmResult += ' It goes on the keyring of my school bag!';
				sounds.jingle();
			} else {
				charmResult += ' But there is no hole, so it cannot go on the keyring. Pappa tries to drill one, and it cracks. Next time, punch the hole before baking!';
			}

			this.say(charmResult, status);
			requestRender();
		});

		this.#actions.set('shrink-new', () => {
			inkContext.clearRect(0, 0, width, height);
			cuts = [];
			hole = undefined;
			phase = 'draw';
			charm = undefined;
			bakingPiece = undefined;
			hasDrawn = false;
			progress = 0;
			fan.set(0);
			updateButtons();
			sounds.swish();
			this.say('A new sheet of krympeplast, rough side up.', status);
			requestRender();
		});

		updateButtons();
		status.textContent = 'Draw on the plastic with the markers. Or trace Glitter!';
		requestRender();
		renderKeyring();
		document.fonts?.ready.then(() => {
			requestRender();
			renderKeyring();
		});
	}
}
