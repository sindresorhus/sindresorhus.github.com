// France 98 on the 1999 page: Norway against Brazil on 23 June 1998, replayed on the TV in our living room, with the family in the sofa. The visitor plays Flo’s 1–1 in the 83rd minute and Rekdal’s penalty in the 89th, earns Panini stickers, reads the paper of the next morning, takes a penalty shootout against Taffarel, and sees the sad match against Italy four days later. The stickers and the shirt are kept in the browser. The TV runs only while it is on screen and the tab is visible. Nothing makes a sound until the visitor turns on the sound or starts the chant.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const lerp = (from, to, amount) => from + ((to - from) * amount);
const easeOut = amount => 1 - ((1 - amount) ** 2);
const progressOf = (time, start, end) => clamp((time - start) / (end - start), 0, 1);

// A value that goes from 0 to 1 and back, for the meters that sweep.
const triangle = time => {
	const phase = time % 2;
	return phase < 1 ? phase : 2 - phase;
};

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// Splits a text into lines that fit a width, for the subtitles and the speech bubbles.
const wrapText = (target, text, maximumWidth) => {
	const lines = [];
	let line = '';
	for (const word of text.split(' ')) {
		const candidate = line ? `${line} ${word}` : word;
		if (line && target.measureText(candidate).width > maximumWidth) {
			lines.push(line);
			line = word;
		} else {
			line = candidate;
		}
	}

	if (line) {
		lines.push(line);
	}

	return lines;
};

const roundedRectangle = (target, x, y, width, height, radius) => {
	target.beginPath();
	target.roundRect(x, y, width, height, radius);
};

// The screen of the TV, in the pixels of the canvas.
const screenArea = {x: 100, y: 32, width: 440, height: 264};

// The kits of 1998. The keepers wear their own colors.
const kits = {
	norway: {shirt: '#d40000', shorts: '#ffffff', socks: '#002a7f', skin: '#f0c8a0', hair: '#5a3a1a'},
	brazil: {shirt: '#ffd700', shorts: '#1e3c9c', socks: '#ffffff', skin: '#9a6a44', hair: '#1a1a1a'},
	italy: {shirt: '#1f4fb0', shorts: '#ffffff', socks: '#1f4fb0', skin: '#e0b090', hair: '#2a1a10'},
	taffarel: {shirt: '#4a5a8a', shorts: '#202020', socks: '#4a5a8a', skin: '#e8c098', hair: '#3a2a1a', gloves: '#f4f4f4'},
	norwayKeeper: {shirt: '#2a9a4a', shorts: '#101010', socks: '#2a9a4a', skin: '#f0c8a0', hair: '#c8a060', gloves: '#ffffff'},
	italyKeeper: {shirt: '#d8c820', shorts: '#202020', socks: '#d8c820', skin: '#e0b090', hair: '#2a1a10', gloves: '#ffffff'},
	referee: {shirt: '#151515', shorts: '#151515', socks: '#151515', skin: '#e8c098', hair: '#3a2a1a'},
};

const brazilSkins = ['#9a6a44', '#c89a70', '#5a3a28', '#e0b890'];

// The defender of Brazil, drawn like a keeper from the front, but with bare hands.
const defenderKit = {...kits.brazil, skin: brazilSkins[2], gloves: brazilSkins[2]};

// The places on the carpet where the coffee lands, one more each time Pappa jumps. The stains stay, also on the next visit.
const stainSpots = [[226, 364], [338, 362], [130, 366], [440, 364], [60, 420], [584, 432], [30, 462], [612, 468], [70, 380], [560, 376]];

// The fans in the stands, as dots in the colors of their teams.
const fans = Array.from({length: 520}, (_, index) => ({
	x: (index * 37.3) % 880,
	y: 4 + ((index * 13.7) % 48),
	color: ['#ffd700', '#ffd700', '#2a9a3a', '#d40000', '#ffffff', '#d40000', '#1e3c9c', '#f0c8a0'][index % 8],
	seed: index * 1.7,
}));

const adBoards = ['BRUNOST', 'GEOCITIES', 'VAFLER', 'REGNTØY', '56K MODEM', 'FISKEBOLLER', 'TRAN', 'SYDENTUR'];

const canSpeak = 'speechSynthesis' in globalThis;

const people = {
	pappa: {name: 'Pappa', x: 282},
	mormor: {name: 'Mormor', x: 172},
	sindre: {name: 'Me', x: 392},
	sister: {name: 'Lillesøster', x: 482},
	neighbors: {name: 'The neighbors, through the wall', x: 560},
};

const clockText = seconds => {
	const minutes = Math.floor(seconds / 60);
	return `${String(minutes).padStart(2, '0')}:${String(Math.floor(seconds % 60)).padStart(2, '0')}`;
};

// The keeper reaches the shots near where he dives. A weak shot gives him more time. A shot far in a corner is out of reach.
const keeperCovers = (dive, u, v, {isWeak = false, isBig = false} = {}) => {
	const extra = (isWeak ? 0.25 : 0) + (isBig ? 0.12 : 0);
	if (dive === 0) {
		return Math.abs(u) < 0.3 + extra && v < 0.92;
	}

	const side = u * dive;
	if (side < 0) {
		return Math.abs(u) < 0.12 + extra;
	}

	return side < (v < 0.6 ? 0.76 : 0.66) + extra;
};

const shotResult = ({u, v, dive, isWeak, isBig}) => {
	const isInside = Math.abs(u) <= 1 && v <= 1;
	if (isInside && keeperCovers(dive, u, v, {isWeak, isBig})) {
		return 'saved';
	}

	if (isInside) {
		return 'goal';
	}

	if (Math.abs(u) <= 1.07 && v <= 1.07) {
		return 'post';
	}

	return v > 1 ? 'over' : 'wide';
};

const keeperGuess = () => {
	const roll = Math.random();
	if (roll < 0.16) {
		return 0;
	}

	return roll < 0.58 ? -1 : 1;
};

// Where a shot goes, in words for the paper, from where the shooter stands. The keeper’s right is the shooter’s left.
const placementOf = ({u, v}) => {
	const height = v < 0.4 ? 'nede' : (v > 0.7 ? 'oppe' : 'halvhøyt');
	const englishHeight = v < 0.4 ? 'low' : (v > 0.7 ? 'high' : 'at half height');
	if (Math.abs(u) < 0.3) {
		return {norwegian: `${height} midt i mål`, english: `${englishHeight} in the middle of the goal`};
	}

	return {
		norwegian: `${height} til Taffarels ${u < 0 ? 'høyre' : 'venstre'}`,
		english: `${englishHeight} to Taffarel’s ${u < 0 ? 'right' : 'left'}`,
	};
};

const isLikeRekdal = shot => shot.u < -0.45 && shot.v < 0.45;

// The stickers of the album.
const stickerInfo = {
	flo: {name: 'T. A. FLO', line: 'NORGE', number: '9', kit: kits.norway, hair: '#3a2a1a'},
	rekdal: {name: 'K. REKDAL', line: 'NORGE', number: '10', kit: kits.norway, hair: '#2a1a10'},
	keeper: {name: 'SINDRE', line: 'I MÅL', number: '1', kit: kits.norwayKeeper, hair: '#e0c060', isKeeper: true},
	hero: {name: 'SINDRE', line: 'STRAFFEHELT', number: '9', kit: kits.norway, hair: '#e0c060', isHero: true},
};

// How wide the right moment is, a little wider after each miss of Flo, so nobody is stuck. The power of a penalty has a fixed green.
const zoneOf = current => {
	if (current.kind === 'penalty') {
		return [0.55, 0.85];
	}

	const width = 0.08 + (current.fails * 0.03);
	return current.phase === 'ball' ? [0.8 - width, 0.8 + width] : [0.5 - width, 0.5 + width];
};

// In reduced motion, a meter is set by holding Kick or with ▲ and ▼, so the status says where its needle is.
const meterNames = {ball: 'The ring', turn: 'The turn', power: 'The power'};

// In motion, the prompt on the TV is too small to read on a phone, so the status says it too.
const meterHints = {ball: 'Kick when the yellow ring is in the green one.', turn: 'Kick when the needle is in the green.'};

// The reticle sways over the goal, wide and high and low, so the visitor waits for a corner.
const swayingAim = time => ({
	u: Math.sin(time * 1.9) * 1.12,
	v: 0.5 + (Math.sin((time * 2.7) + 0.6) * 0.55),
});

// What the commentator says at a miss, in Norwegian and in English.
const missLines = {
	saved: ['Taffarel redder! Åh, så nære!', 'Taffarel saves! Oh, so close!'],
	post: ['I STOLPEN! Neeei!', 'OFF THE POST! Nooo!'],
	over: ['Over! Langt over, ut på parkeringsplassen.', 'Over! Far over, out to the parking lot.'],
	wide: ['Utenfor! Det var ikke langt unna.', 'Wide! It was not far off.'],
};

const goalsOf = kicks => kicks.filter(Boolean).length;

// The goal of each view on the TV, in the pixels of the broadcast, to aim with a tap.
const goalOf = kind => {
	if (kind === 'flo' || kind === 'italyShot') {
		return {x: 220, y: 132, width: 210, height: 70};
	}

	return {x: 220, y: 150, width: 250, height: 84};
};

// Drawing the broadcast.
const flag = {
	norway(target, x, y, width, height) {
		target.fillStyle = '#ba0c2f';
		target.fillRect(x, y, width, height);
		target.fillStyle = '#ffffff';
		target.fillRect(x + (width * 0.28), y, width * 0.18, height);
		target.fillRect(x, y + (height * 0.38), width, height * 0.24);
		target.fillStyle = '#00205b';
		target.fillRect(x + (width * 0.32), y, width * 0.1, height);
		target.fillRect(x, y + (height * 0.44), width, height * 0.12);
	},
	brazil(target, x, y, width, height) {
		target.fillStyle = '#009c3b';
		target.fillRect(x, y, width, height);
		target.fillStyle = '#ffdf00';
		target.beginPath();
		target.moveTo(x + (width / 2), y + 1.5);
		target.lineTo(x + width - 2, y + (height / 2));
		target.lineTo(x + (width / 2), y + height - 1.5);
		target.lineTo(x + 2, y + (height / 2));
		target.fill();
		target.fillStyle = '#002776';
		target.beginPath();
		target.arc(x + (width / 2), y + (height / 2), height * 0.26, 0, Math.PI * 2);
		target.fill();
	},
	italy(target, x, y, width, height) {
		const colors = ['#009246', '#ffffff', '#ce2b37'];
		for (const [index, color] of colors.entries()) {
			target.fillStyle = color;
			target.fillRect(x + (index * width / 3), y, width / 3, height);
		}
	},
};

// The subtitles of the commentator, like teletext page 888: the Norwegian in white, the English in yellow.
// While the visitor plays, the subtitles step aside, so they do not hide the ball. The status line below the TV still has them.
const playingPhases = new Set(['ball', 'turn', 'shot', 'aim', 'power', 'runup', 'flight', 'control', 'spin']);

// The ball on its way from the spot to where it was aimed, then into the net, into the keeper’s gloves and back out, off the post, or over.
const shotBallPosition = (goal, start, shot, amount, afterTime = 0) => {
	const target = {x: goal.x + (shot.u * goal.width / 2), y: goal.y - (shot.v * goal.height)};
	if (shot.result === 'saved' && amount >= 0.85) {
		const bounce = Math.min(1, (afterTime + ((amount - 0.85) * 3)) * 1.5);
		const at = {x: lerp(start.x, target.x, 0.85), y: lerp(start.y, target.y, 0.85)};
		return {x: at.x - ((shot.dive || 1) * bounce * 70), y: at.y + (bounce * 60) - (Math.sin(bounce * Math.PI) * 30), radius: lerp(start.radius, start.radius * 0.6, 0.85)};
	}

	if (shot.result === 'post' && amount >= 1) {
		const bounce = Math.min(1, afterTime * 1.5);
		return {x: target.x - (Math.sign(shot.u || 1) * bounce * 80), y: target.y + (bounce * 70), radius: start.radius * 0.55};
	}

	if ((shot.result === 'over' || shot.result === 'wide') && amount >= 1) {
		const further = Math.min(1, afterTime * 2);
		return {x: lerp(target.x, target.x + ((target.x - start.x) * 0.5), further), y: lerp(target.y, target.y - 40, further), radius: start.radius * lerp(0.5, 0.3, further)};
	}

	const eased = easeOut(Math.min(amount, 1));
	const sink = shot.result === 'goal' && amount >= 1 ? Math.min(1, afterTime * 2) * 8 : 0;
	return {x: lerp(start.x, target.x, eased), y: lerp(start.y, target.y, eased) - (Math.sin(eased * Math.PI) * 10 * shot.v) + sink, radius: lerp(start.radius, start.radius * 0.5, eased)};
};

// The scenes that fill the screen with a card of their own, without the score bug.
const cardScenes = new Set(['title', 'final', 'fullTime', 'shootoutIntro', 'shootoutEnd', 'italyIntro', 'italyEnd']);

const drawSticker = (target, info, state) => {
	const {width, height} = target.canvas;
	target.clearRect(0, 0, width, height);
	if (!state) {
		target.fillStyle = '#e8ecf8';
		target.fillRect(0, 0, width, height);
		target.fillStyle = '#9098b8';
		target.font = 'bold 40px Arial, sans-serif';
		target.textAlign = 'center';
		target.fillText(info.number, width / 2, 90);
		target.font = 'bold 11px Arial, sans-serif';
		target.fillText('MANGLER', width / 2, 120);
		return;
	}

	const background = target.createLinearGradient(0, 0, 0, height);
	background.addColorStop(0, '#5aa0e8');
	background.addColorStop(1, '#c8e4ff');
	target.fillStyle = background;
	target.fillRect(0, 0, width, height);
	target.fillStyle = '#2a8a2a';
	target.fillRect(0, 100, width, 30);
	// The player, from the chest up.
	const kit = info.kit;
	target.fillStyle = kit.shirt;
	roundedRectangle(target, 22, 86, 76, 50, [24, 24, 0, 0]);
	target.fill();
	if (!info.isKeeper) {
		target.fillStyle = '#ffffff';
		target.beginPath();
		target.moveTo(50, 86);
		target.lineTo(60, 98);
		target.lineTo(70, 86);
		target.fill();
	}

	target.fillStyle = '#ffffff';
	target.font = 'bold 18px Arial, sans-serif';
	target.textAlign = 'center';
	target.fillText(info.number, 40, 122);
	target.fillStyle = info.isKeeper || info.isHero ? '#f4d0b0' : kit.skin;
	target.beginPath();
	target.arc(60, 64, 22, 0, Math.PI * 2);
	target.fill();
	target.fillStyle = info.hair;
	target.beginPath();
	target.arc(60, 58, 22, Math.PI * 1.02, Math.PI * 1.98);
	target.fill();
	target.fillStyle = '#000000';
	target.beginPath();
	target.arc(52, 64, 2.4, 0, Math.PI * 2);
	target.arc(68, 64, 2.4, 0, Math.PI * 2);
	target.fill();
	target.strokeStyle = '#802020';
	target.lineWidth = 2;
	target.beginPath();
	target.arc(60, 72, 7, 0.15 * Math.PI, 0.85 * Math.PI);
	target.stroke();
	if (info.isKeeper) {
		target.fillStyle = '#ffffff';
		for (const handX of [20, 100]) {
			target.beginPath();
			target.arc(handX, 96, 10, 0, Math.PI * 2);
			target.fill();
		}
	}

	if (info.isHero) {
		target.fillStyle = '#ffd700';
		target.beginPath();
		target.moveTo(92, 40);
		target.lineTo(112, 40);
		target.lineTo(106, 60);
		target.lineTo(98, 60);
		target.fill();
		target.fillRect(99, 60, 6, 10);
		target.fillRect(94, 70, 16, 4);
	}

	// The flag, the name band, and the frame of the sticker.
	target.fillStyle = '#ba0c2f';
	target.fillRect(8, 8, 24, 17);
	target.fillStyle = '#ffffff';
	target.fillRect(14, 8, 4, 17);
	target.fillRect(8, 14.5, 24, 4);
	target.fillStyle = '#00205b';
	target.fillRect(15, 8, 2, 17);
	target.fillRect(8, 15.5, 24, 2);
	target.fillStyle = '#ffffff';
	target.font = 'bold 9px Arial, sans-serif';
	target.textAlign = 'right';
	target.fillText('FRANCE 98', 112, 20);
	target.fillStyle = '#c00000';
	target.fillRect(0, 130, width, 30);
	target.fillStyle = '#ffffff';
	target.textAlign = 'center';
	target.font = 'bold 13px Arial, sans-serif';
	target.fillText(info.name, width / 2, 146);
	target.font = 'bold 8px Arial, sans-serif';
	target.fillText(info.line, width / 2, 156);
	target.strokeStyle = '#ffffff';
	target.lineWidth = 6;
	target.strokeRect(3, 3, width - 6, height - 6);
	if (state === 'shiny') {
		// The shine of a glossy sticker: stripes of rainbow light across it.
		const shine = target.createLinearGradient(0, 0, width, height);
		shine.addColorStop(0, 'rgb(255 255 255 / 0%)');
		shine.addColorStop(0.35, 'rgb(255 120 220 / 35%)');
		shine.addColorStop(0.5, 'rgb(255 255 160 / 45%)');
		shine.addColorStop(0.65, 'rgb(120 220 255 / 35%)');
		shine.addColorStop(1, 'rgb(255 255 255 / 0%)');
		target.fillStyle = shine;
		target.fillRect(0, 0, width, height);
	}
};

const outfitLines = {
	shirt: ['Se! Norge-drakta, med navnet mitt på ryggen!', 'Look! The Norway shirt, with my name on the back!'],
	scarf: ['Skjerfet fra Mormor. Hun strikket det i rødt, hvitt og blått.', 'The scarf from Mormor. She knitted it in red, white, and blue.'],
	paint: ['Flagg på kinnene! Mamma kommer til å bli sur.', 'Flags on my cheeks! Mamma will be mad.'],
	helmet: ['Vikinghjelm! Ekte plast fra Narvesen.', 'A Viking helmet! Real plastic from the kiosk.'],
};

export default class extends GeoCitiesElement {
	#context;
	#buttons;
	#stickerCanvases;
	#stickerHints;

	// The broadcast is drawn on its own canvas, the size of the screen of the TV, and then onto the TV with scanlines. The photo in the paper is made from it.
	#broadcast = document.createElement('canvas');
	#tv = this.#broadcast.getContext('2d');
	#progress;

	#isSoundOn = false;
	#isChanting = false;
	#isHolding = false;
	#lastGoal;
	#paperIsShown = false;

	// The match as it stands: the score, the clock in seconds, the other match of the group, and what the visitor did, for the paper.
	#match = {
		mode: 'brazil',
		norway: 0,
		other: 0,
		clock: 0,
		moroccoGoals: 2,
		rewinds: 0,
		floTries: 0,
		penaltyTries: 0,
		penaltyShot: undefined,
	};

	// The shootout, as two rows of kicks.
	#shootout;

	// The family in the sofa, and what they do right now.
	#family = {
		pappa: {jump: 0, slump: 0},
		mormor: {turn: 0},
		sindre: {cheer: 0, turn: 0},
		sister: {mumble: 0},
		wallBang: 0,
	};

	#bubbles = new Map();
	#drops = [];
	#subtitle;
	#roomTime = 0;

	// The sound, made in the browser. The effects play only while the sound is on, and the chant only when the visitor starts it.
	#audio = {
		context: undefined,
		output: undefined,
		noiseBuffer: undefined,
		crowdGain: undefined,
		crowdSource: undefined,
		// Takes the audio of the element, which `sound()` only makes in the handler of a click.
		start(sound) {
			if (sound) {
				this.context = sound.context;
				this.output = sound.output;
			}

			return this.context !== undefined;
		},
		get isRunning() {
			return this.context?.state === 'running';
		},
		get noise() {
			if (!this.noiseBuffer) {
				this.noiseBuffer = new AudioBuffer({length: this.context.sampleRate * 2, sampleRate: this.context.sampleRate});
				const data = this.noiseBuffer.getChannelData(0);
				for (let index = 0; index < data.length; index++) {
					data[index] = (Math.random() * 2) - 1;
				}
			}

			return this.noiseBuffer;
		},
		beep(frequency, duration = 0.1, {type = 'square', volume = 0.05, when = 0, slideTo, destination} = {}) {
			if (!this.isRunning) {
				return;
			}

			const start = this.context.currentTime + when;
			const oscillator = new OscillatorNode(this.context, {type, frequency});
			if (slideTo) {
				oscillator.frequency.exponentialRampToValueAtTime(slideTo, start + duration);
			}

			const gain = new GainNode(this.context, {gain: 0});
			gain.gain.setValueAtTime(0, start);
			gain.gain.linearRampToValueAtTime(volume, start + 0.01);
			gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
			oscillator.connect(gain).connect(destination ?? this.output);
			oscillator.start(start);
			oscillator.stop(start + duration + 0.02);
		},
		hiss(duration, {volume = 0.1, frequency = 1000, type = 'bandpass', when = 0, quality = 1, destination} = {}) {
			if (!this.isRunning) {
				return;
			}

			const start = this.context.currentTime + when;
			const source = new AudioBufferSourceNode(this.context, {buffer: this.noise, loop: true});
			const filter = new BiquadFilterNode(this.context, {type, frequency, Q: quality});
			const gain = new GainNode(this.context, {gain: volume});
			gain.gain.setValueAtTime(volume, start);
			gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
			source.connect(filter).connect(gain).connect(destination ?? this.output);
			source.start(start, Math.random());
			source.stop(start + duration + 0.02);
		},
		// The crowd of the stadium: a noise that never stops, filtered like voices far away, which gets louder at the chances.
		startCrowd() {
			if (!this.isRunning || this.crowdSource) {
				return;
			}

			this.crowdSource = new AudioBufferSourceNode(this.context, {buffer: this.noise, loop: true});
			const voices = new BiquadFilterNode(this.context, {type: 'bandpass', frequency: 650, Q: 0.7});
			const far = new BiquadFilterNode(this.context, {type: 'lowpass', frequency: 1800});
			this.crowdGain = new GainNode(this.context, {gain: 0});
			this.crowdSource.connect(voices).connect(far).connect(this.crowdGain).connect(this.output);
			this.crowdSource.start();
			this.crowdLevel(0.06, 1);
		},
		stopCrowd() {
			this.crowdSource?.stop();
			this.crowdSource?.disconnect();
			this.crowdSource = undefined;
			this.crowdGain = undefined;
		},
		crowdLevel(level, seconds = 0.5) {
			if (!this.crowdGain) {
				return;
			}

			const now = this.context.currentTime;
			this.crowdGain.gain.cancelScheduledValues(now);
			this.crowdGain.gain.setValueAtTime(this.crowdGain.gain.value, now);
			this.crowdGain.gain.linearRampToValueAtTime(level, now + seconds);
		},
		roar() {
			if (!this.crowdGain) {
				return;
			}

			const now = this.context.currentTime;
			this.crowdGain.gain.cancelScheduledValues(now);
			this.crowdGain.gain.setValueAtTime(this.crowdGain.gain.value, now);
			this.crowdGain.gain.linearRampToValueAtTime(0.5, now + 0.25);
			this.crowdGain.gain.linearRampToValueAtTime(0.3, now + 2.5);
			this.crowdGain.gain.linearRampToValueAtTime(0.07, now + 6);
			this.hiss(2.5, {volume: 0.25, frequency: 2200, quality: 0.5});
		},
	};

	#chantTimer;
	#chantGain;

	// The scenes of the TV. A cutscene has events at times, and runs by itself, or, in reduced motion, steps to its next event on each press. A press also fast-forwards it to its next event with motion, so nobody waits for the big moments. The other scenes are played.
	#scene = {kind: 'title', time: 0, events: [], eventIndex: 0};

	// The wide view of the broadcast camera, high on the side of the pitch. The pitch is in meters, 105 long and 68 wide.
	#wide = {camera: 52};

	// The loop runs while the TV is on screen and the tab is visible, and, in reduced motion, only while the visitor holds the kick button.
	#loop;
	#isDrawQueued = false;

	// A tap scene acts on the click, which a finger that scrolls the page does not make. A big moment acts on the press, to hold a kick.
	#isTap = false;

	#sceneTypes = {
		title: {
			isResting: true,
			draw: () => {
				this.#drawTitleCard();
			},
			press: () => {
				this.#startMatch();
			},
		},

		bebeto: {
			duration: 7.5,
			events: () => [
				[0, () => {
					this.#comment('77 minutter spilt i Marseille, og det står 0–0. Norge må vinne!', '77 minutes played in Marseille, and it is 0–0. Norway must win!');
					this.#audio.crowdLevel(0.1);
				}],
				[1.6, () => {
					this.#comment('Innlegg fra venstre… Bebeto!', 'A cross from the left… Bebeto!');
				}],
				[2.8, () => {
					this.#match.other = 1;
					this.#audio.roar();
					this.#netSound();
					this.#comment('Å nei. Bebeto header inn 1–0 til Brasil.', 'Oh no. Bebeto heads it in, 1–0 to Brazil.');
					this.#family.pappa.slump = 30;
					this.#talk('pappa', 'Neeei!', 'Noooo!');
				}],
				[5, () => {
					this.#talk('mormor', 'Står det BRA? Er det bra, da?', 'It says BRA. Is that good, then?', {seconds: 2.5});
				}],
			],
			sync: current => {
				this.#match.clock = (77 * 60) + 40 + (Math.min(current.time, 2.8) * 7.2);
			},
			draw: current => {
				this.#drawBebeto(current.time);
			},
			after: () => {
				this.#playOn(this.#match.clock, (82 * 60) + 50, () => {
					this.#startScene('flo');
				}, [
					[(79 * 60) + 30, () => {
						this.#talk('mormor', 'Hvem er de gule? Er de våre?', 'Who are the yellow ones? Are they ours?', {seconds: 2.2});
					}],
					[81 * 60, () => {
						this.#talk('pappa', 'Kom igjen, Norge! Fem minutter igjen!', 'Come on, Norway! Five minutes left!', {seconds: 2.2});
					}],
				]);
			},
		},

		play: {
			duration: current => (current.to - current.from) / 60,
			events: current => current.minuteEvents.map(([clock, action]) => [(clock - current.from) / 60, action]),
			sync: current => {
				this.#match.clock = current.from + (current.time * 60);
			},
			draw: current => {
				this.#drawAmbient(current.from / 60 + current.time, {attackRight: this.#match.mode !== 'italy'});
			},
			after: current => {
				current.after();
			},
		},

		// Flo’s 1–1 in the 83rd minute, in three steps: take down the long ball, turn past the defender, and shoot past Taffarel.
		flo: {
			enter: current => {
				this.#match.floTries++;
				current.phase = current.skipIntro ? 'ball' : 'intro';
				current.fails = current.fails ?? 0;
				if (!current.skipIntro) {
					this.#comment('Bjørnebye slår ballen langt… Tore André Flo!', 'Bjørnebye plays it long… Tore André Flo!');
					this.#audio.crowdLevel(0.16, 1);
				} else {
					this.#announceMeter();
				}
			},
			update: (current, seconds) => {
				current.phaseTime += seconds;
				const {phase, phaseTime} = current;
				if (phase === 'intro' && phaseTime > 2.4) {
					this.#setPhase('ball');
					this.#announceMeter();
				} else if (phase === 'ball' && phaseTime / 1.7 > 1) {
					this.#floFails('ball');
				} else if (phase === 'ball') {
					current.meter = phaseTime / 1.7;
				} else if (phase === 'control' && phaseTime > 0.6) {
					this.#setPhase('turn');
					this.#announceMeter();
				} else if (phase === 'turn' && phaseTime > 7) {
					this.#floFails('turn');
				} else if (phase === 'turn') {
					current.meter = triangle(phaseTime / 0.9);
				} else if (phase === 'spin' && phaseTime > 0.7) {
					this.#startFloShot();
				} else if (phase === 'shot') {
					current.aim = swayingAim(phaseTime);
				} else if (phase === 'flight' && phaseTime > 0.5) {
					this.#finishFloShot();
				} else if (phase === 'result' && phaseTime > 2.2) {
					this.#afterFloShot();
				} else if ((phase === 'lost' || phase === 'tackled') && phaseTime > 1.6) {
					this.#retryFlo(current.fails);
				}
			},
			press: current => {
				const {phase} = current;
				if (phase === 'intro' && !this.#isMotion) {
					this.#setPhase('ball');
					this.#announceMeter();
				} else if ((phase === 'ball' || phase === 'turn') && this.#isMotion) {
					this.#judgeMeter();
				} else if ((phase === 'ball' || phase === 'turn') && !this.#isMotion) {
					this.#startHold();
				} else if (phase === 'shot') {
					this.#shootFlo();
				} else if (!this.#isMotion && phase === 'result') {
					this.#afterFloShot();
				} else if (!this.#isMotion && (phase === 'lost' || phase === 'tackled')) {
					this.#retryFlo(current.fails);
				}
			},
			release: current => {
				if (!this.#isMotion && this.#isHolding && (current.phase === 'ball' || current.phase === 'turn')) {
					this.#stopHold();
					this.#judgeMeter();
				}
			},
			acceptsAim: current => current.phase === 'shot' && !this.#isMotion,
			acceptsMeter: current => (current.phase === 'ball' || current.phase === 'turn') && !this.#isMotion,
			automaticPhases: ['control', 'spin', 'flight'],
			draw: current => {
				this.#drawFlo(current);
			},
		},

		rewind: {
			duration: 1.8,
			events: () => [
				[0, () => {
					this.#rewindSound();
					this.#talk('pappa', 'Spol tilbake! Én gang til!', 'Rewind! One more time!');
				}],
			],
			draw: current => {
				this.#drawRewind(current.time);
			},
			after: current => {
				current.after();
			},
		},

		celebration: {
			duration: 5,
			events: current => [
				[1, () => {
					this.#neighborsBang();
					this.#talk('neighbors', current.scorer.includes('REKDAL') ? 'JAAAA! NORGE!' : 'DUNK DUNK!', current.scorer.includes('REKDAL') ? 'YEEES! NORWAY!' : 'BANG BANG!', {seconds: 2});
				}],
				[2.6, () => {
					this.#talk('mormor', current.scorer.includes('REKDAL') ? 'Nå står det 2 for oss! Er det bra?' : 'Hvorfor roper alle? Har det skjedd noe?', current.scorer.includes('REKDAL') ? 'Now it says 2 for us! Is that good?' : 'Why is everyone shouting? Did something happen?', {seconds: 2.4});
				}],
			],
			draw: current => {
				this.#drawCelebration(current);
			},
			after: current => {
				current.after();
			},
		},

		foul: {
			duration: 6,
			events: () => [
				[0, () => {
					this.#comment('Lang ball inn i feltet… Flo… Junior Baiano drar ham i drakta!', 'A long ball into the box… Flo… Junior Baiano pulls his shirt!');
					this.#audio.crowdLevel(0.2, 0.5);
				}],
				[1.6, () => {
					this.#whistle(0.6);
					this.#comment('STRAFFE! Dommeren peker på straffemerket! Straffe til Norge!', 'PENALTY! The referee points to the spot! A penalty to Norway!', {isWild: true});
					this.#audio.roar();
					this.#sindreCheers();
				}],
				[3.6, () => {
					this.#talk('mormor', 'Straffe? Hvem er det som skal straffes?', 'Penalty? Who is getting punished?', {seconds: 2.4});
				}],
			],
			sync: current => {
				this.#match.clock = (88 * 60) + 20 + (current.time * 6);
			},
			draw: current => {
				this.#drawFoul(current.time);
			},
			after: () => {
				this.#startScene('penalty');
			},
		},

		// A penalty: aim with the reticle, set the power, and the keeper dives. Used for Rekdal in the match and for the shootout.
		penalty: {
			enter: current => {
				current.phase = 'setup';
				current.dive = keeperGuess();
				if (this.#shootout) {
					this.#comment(`Norges skudd nummer ${this.#shootout.norway.length + 1}. Klar… ferdig…`, `Norway’s kick number ${this.#shootout.norway.length + 1}. Ready… set…`);
				} else {
					this.#match.penaltyTries++;
					this.#match.clock = 89 * 60;
					this.#comment('Kjetil Rekdal legger ballen på krittmerket. Taffarel er straffespesialist… Hele Norge holder pusten.', 'Kjetil Rekdal puts the ball on the spot. Taffarel is a penalty specialist… All of Norway holds its breath.');
					if (this.#match.penaltyTries === 1) {
						this.#talk('pappa', 'Jeg klarer ikke å se på!', 'I can’t watch!', {seconds: 2.4});
					}
				}

				this.#audio.crowdLevel(0.04, 1);
			},
			update: (current, seconds) => {
				current.phaseTime += seconds;
				const {phase, phaseTime} = current;
				if (phase === 'setup' && phaseTime > (this.#shootout ? 1.4 : 2.2)) {
					this.#setPhase('aim', {aim: {u: 0, v: 0.4}});
					this.#announceAim();
				} else if (phase === 'aim') {
					current.aim = swayingAim(phaseTime);
				} else if (phase === 'power') {
					current.meter = triangle(phaseTime / 0.65);
				} else if (phase === 'runup' && phaseTime > 0.55) {
					this.#kickSound();
					this.#setPhase('flight');
				} else if (phase === 'flight' && phaseTime > 0.65 - (current.shot.power * 0.3)) {
					this.#finishPenalty();
				} else if (phase === 'result' && phaseTime > 2.4) {
					this.#afterPenalty();
				}
			},
			press: current => {
				const {phase} = current;
				if (phase === 'setup' && !this.#isMotion) {
					this.#setPhase('aim', {aim: {u: 0, v: 0.4}});
					this.#announceAim();
				} else if (phase === 'aim') {
					this.#setPhase('power', {aim: current.aim});
					if (this.#isMotion) {
						this.say('Now the power: press again when the needle is in the green.');
					} else {
						this.#announceMeter();
					}
				} else if (phase === 'power' && this.#isMotion) {
					this.#shootPenalty();
				} else if (phase === 'power' && !this.#isMotion) {
					this.#startHold();
				} else if (phase === 'result' && !this.#isMotion) {
					this.#afterPenalty();
				}
			},
			release: current => {
				if (!this.#isMotion && this.#isHolding && current.phase === 'power') {
					this.#stopHold();
					this.#shootPenalty();
				}
			},
			acceptsAim: current => current.phase === 'aim' && !this.#isMotion,
			acceptsMeter: current => current.phase === 'power' && !this.#isMotion,
			automaticPhases: ['runup', 'flight'],
			draw: current => {
				this.#drawPenalty(current);
			},
		},

		fullTime: {
			duration: 7,
			events: () => [
				[0, () => {
					this.#fullTimeWhistle();
					this.#audio.roar();
					this.#comment('SLUTT! Norge slår Brasil 2–1! Verdensmesterne er slått! Norge er videre til åttedelsfinalen!', 'FULL TIME! Norway beat Brazil 2–1! The world champions are beaten! Norway goes through to the round of 16!', {isWild: true});
					this.#pappaJumps();
					this.#sindreCheers();
					this.#neighborsBang();
					this.celebrate();
					this.#saveMatch();
				}],
				[3, () => {
					this.#talk('mormor', 'Vant vi? Så fint. Skal vi ha mer kaffe?', 'Did we win? How nice. Shall we have more coffee?', {seconds: 2.6});
				}],
				[5.4, () => {
					this.#talk('sister', 'Heia… Norge… zzz', 'Go… Norway… zzz', {seconds: 2});
				}],
			],
			draw: () => {
				this.#drawFinalScore();
			},
			after: () => {
				this.#startScene('final');
			},
		},

		final: {
			isResting: true,
			draw: () => {
				this.#drawFinalScore();
			},
			press: () => {
				this.#startMatch();
			},
		},

		shootoutIntro: {
			duration: 3.5,
			events: () => [
				[0, () => {
					this.#comment('Straffesparkkonkurranse i stua! Fem skudd hver, og så sudden death. Taffarel står i mål.', 'A penalty shootout in the living room! Five kicks each, then sudden death. Taffarel is in goal.');
					this.#talk('pappa', 'Dette skjedde aldri, men det kunne ha skjedd!', 'This never happened, but it could have!', {seconds: 3});
				}],
			],
			draw: () => {
				this.#drawShootoutCard();
			},
			after: () => {
				this.#startScene('penalty');
			},
		},

		keeper: {
			enter: current => {
				current.phase = 'setup';
				current.side = randomItem([-1, -1, 0, 1, 1]);
				current.height = Math.random() < 0.6 ? 0.25 : 0.7;
				current.isMiss = Math.random() < 0.1;
				// The shooter leans to where he shoots in the last moment, but not always.
				current.tell = Math.random() < 0.7 ? current.side : randomItem([-1, 0, 1]);
				current.choice = undefined;
				current.number = randomItem([2, 4, 5, 6, 7, 8, 11, 13, 16, 18, 20]);
				this.#comment(`Brasils skudd nummer ${this.#shootout.brazil.length + 1}. Du står i mål! Velg et hjørne!`, `Brazil’s kick number ${this.#shootout.brazil.length + 1}. You are in goal! Pick a corner!`);
				this.say(this.#isMotion ? 'You are in goal. Press ◀ or ▶ to dive, or ▼ to stay, before the kick. Watch how he leans!' : 'You are in goal. Press ◀ or ▶ to dive, or ▼ to stay. Watch how he leans!');
			},
			update: (current, seconds) => {
				current.phaseTime += seconds;
				const {phase, phaseTime} = current;
				if (phase === 'setup' && phaseTime > 1) {
					this.#setPhase('runup');
				} else if (phase === 'runup' && phaseTime > 1.7) {
					this.#kickSound();
					this.#setPhase('flight', {choice: current.choice ?? 0});
				} else if (phase === 'flight' && phaseTime > 0.4) {
					this.#finishKeeper();
				} else if (phase === 'result' && phaseTime > 2.2) {
					this.#nextShootoutKick();
				}
			},
			press: current => {
				if (current.phase === 'result' && !this.#isMotion) {
					this.#nextShootoutKick();
				} else if (current.phase === 'setup' && !this.#isMotion) {
					this.#setPhase('runup');
				} else if (this.#isMotion) {
					current.choice ??= 0;
				} else {
					this.#sceneTypes.keeper.arrow(current, 0, 1);
				}
			},
			arrow: (current, deltaX, deltaY) => {
				if ((current.phase !== 'setup' && current.phase !== 'runup') || (deltaX === 0 && deltaY < 0)) {
					return;
				}

				current.choice = Math.sign(deltaX);
				if (!this.#isMotion) {
					this.#kickSound();
					this.#setPhase('flight', {choice: current.choice});
					this.#finishKeeper();
				}

				this.#requestDraw();
			},
			acceptsDive: current => current.phase === 'setup' || current.phase === 'runup',
			automaticPhases: ['flight'],
			draw: current => {
				this.#drawKeeper(current);
			},
		},

		shootoutEnd: {
			isResting: true,
			enter: current => {
				const score = `${goalsOf(this.#shootout.norway)}–${goalsOf(this.#shootout.brazil)}`;
				current.score = score;
				if (current.winner === 'norway') {
					this.#fullTimeWhistle();
					this.#audio.roar();
					this.#pappaJumps();
					this.#sindreCheers();
					this.#neighborsBang();
					this.celebrate();
					this.#comment(`Norge vinner straffekonkurransen ${score}! Sindre er straffehelten!`, `Norway wins the shootout ${score}! Sindre is the penalty hero!`, {isWild: true});
					this.#earnSticker('hero', this.#shootout.norway.every(Boolean));
				} else {
					this.#fullTimeWhistle();
					this.#comment(`Brasil vinner ${score} på straffer. Taffarel, igjen.`, `Brazil wins ${score} on penalties. Taffarel, again.`);
					this.#talk('pappa', 'Det var bare på lek. Vi vant den ekte!', 'That was only for fun. We won the real one!');
				}

				this.#progress.shootout = {score, isWon: current.winner === 'norway'};
				this.#persist();
			},
			draw: current => {
				this.#drawShootoutEnd(current);
			},
			press: () => {
				this.#startShootout();
			},
		},

		italyIntro: {
			duration: 4,
			events: () => [
				[0, () => {
					this.#comment('Lørdag 27. juni 1998, Marseille. Åttedelsfinale: Italia mot Norge.', 'Saturday 27 June 1998, Marseille. The round of 16: Italy against Norway.');
					this.#talk('pappa', 'Nå tar vi Italia også!', 'Now we beat Italy too!', {seconds: 2.5});
				}],
			],
			draw: () => {
				this.#drawItalyCard();
			},
			after: () => {
				this.#startScene('vieri');
			},
		},

		vieri: {
			duration: 7.5,
			events: () => [
				[0, () => {
					this.#comment('18. minutt. Lang ball fra Italia… Vieri er gjennom…', '18th minute. A long ball from Italy… Vieri is through…');
					this.#audio.crowdLevel(0.15, 0.5);
				}],
				[3.2, () => {
					this.#match.other = 1;
					this.#netSound();
					this.#audio.crowdLevel(0.3, 0.2);
					this.#comment('Vieri. 1–0 til Italia. Det er stille i stua.', 'Vieri. 1–0 to Italy. It is quiet in the living room.');
					this.#family.pappa.slump = 99;
				}],
				[5.4, () => {
					this.#talk('mormor', 'Er det bra, da?', 'Is that good, then?', {seconds: 2});
				}],
			],
			sync: current => {
				this.#match.clock = (17 * 60) + 20 + (Math.min(current.time, 3.2) * 13);
			},
			draw: current => {
				this.#drawVieri(current.time);
			},
			after: () => {
				this.#startScene('italyShot', {attempt: 0});
			},
		},

		// The visitor can shoot for Norway, but the Italian keeper gets them all. History does not change.
		italyShot: {
			enter: current => {
				current.phase = 'aim';
				current.attempt = current.attempt ?? 0;
				this.#match.clock = [32 * 60, 61 * 60, 86 * 60][current.attempt];
				this.#comment('Norge jager utligningen! Skyt!', 'Norway hunts for the equalizer! Shoot!');
				this.say(this.#isMotion ? 'Press Kick to shoot for Norway.' : 'Aim with the arrows, or tap the goal, then press Kick to shoot for Norway.');
				current.aim = {u: 0, v: 0.4};
			},
			update: (current, seconds) => {
				current.phaseTime += seconds;
				const {phase, phaseTime} = current;
				if (phase === 'aim') {
					current.aim = swayingAim(phaseTime);
				} else if (phase === 'flight' && phaseTime > 0.5) {
					this.#finishItalyShot();
				} else if (phase === 'result' && phaseTime > 2.4) {
					this.#afterItalyShot();
				}
			},
			press: current => {
				if (current.phase === 'aim') {
					const {u, v} = current.aim;
					this.#kickSound();
					// The keeper is always there. A shot in the far corner hits the post instead.
					const isPost = Math.abs(u) > 0.8 && Math.abs(u) <= 1.07 && v <= 1.07;
					const result = Math.abs(u) > 1.07 || v > 1.07 ? (v > 1 ? 'over' : 'wide') : (isPost ? 'post' : 'saved');
					current.shot = {u: isPost ? Math.sign(u) * 1.02 : u, v, dive: Math.abs(u) < 0.25 ? 0 : Math.sign(u), result, isBig: true, power: 0.7};
					if (this.#isMotion) {
						this.#setPhase('flight');
					} else {
						this.#finishItalyShot();
					}
				} else if (current.phase === 'result' && !this.#isMotion) {
					this.#afterItalyShot();
				}
			},
			acceptsAim: current => current.phase === 'aim' && !this.#isMotion,
			automaticPhases: ['flight'],
			draw: current => {
				this.#drawItalyShot(current);
			},
		},

		italyEnd: {
			isResting: true,
			enter: () => {
				this.#match.clock = 90 * 60;
				this.#fullTimeWhistle();
				this.#sadTrombone();
				this.#audio.crowdLevel(0.03, 2);
				this.#comment('Slutt. Italia 1–0 Norge. Norge er ute av VM. Men vi slo Brasil.', 'Full time. Italy 1–0 Norway. Norway is out of the World Cup. But we beat Brazil.');
				this.#talk('sindre', 'Men vi slo Brasil…', 'But we beat Brazil…', {seconds: 4});
			},
			draw: () => {
				this.#drawItalyEnd();
			},
			press: () => {
				this.#startItaly();
			},
		},

		// The instant replay of the last goal of the visitor, in slow motion, then back to where the TV was.
		replay: {
			duration: 4.5,
			events: () => [
				[0, () => {
					this.#comment('Vi ser det en gang til, i sakte film…', 'Let’s see it once more, in slow motion…');
				}],
				[3, () => {
					this.#comment('Se på den! Taffarel er sjanseløs!', 'Look at that! Taffarel has no chance!', {isWild: true});
				}],
			],
			draw: current => {
				this.#drawReplay(current);
			},
			after: current => {
				this.#startScene(current.resume);
			},
		},
	};

	connected() {
		const {canvas, left, up, down, right, kick, kickoff, flo, penalty, sound, chant, replay, shirt, scarf, paint, helmet, shootout, paper, italy} = this.parts;
		this.#context = canvas.getContext('2d');
		this.#broadcast.width = screenArea.width;
		this.#broadcast.height = screenArea.height;
		this.#buttons = new Map(Object.entries({left, up, down, right, kick, kickoff, flo, penalty, sound, chant, replay, shirt, scarf, paint, helmet, shootout, paper, italy}));
		this.#stickerCanvases = new Map([...this.querySelectorAll('[data-world-cup-sticker]')].map(sticker => [sticker.dataset.worldCupSticker, sticker]));
		this.#stickerHints = new Map([...this.#stickerCanvases].map(([identifier, sticker]) => [identifier, sticker.closest('figure').querySelector('figcaption').textContent]));

		// The stored data can be old or broken, so only the values that make sense are kept.
		const isObject = value => typeof value === 'object' && value !== null;
		const stored = this.stored('progress', {});
		this.#progress = {
			stickers: Object.fromEntries(Object.entries(isObject(stored.stickers) ? stored.stickers : {}).filter(([, state]) => state === 'earned' || state === 'shiny')),
			outfit: Object.fromEntries(['shirt', 'scarf', 'paint', 'helmet'].map(piece => [piece, stored.outfit?.[piece] === true])),
			coffeeStains: Number.isInteger(stored.coffeeStains) && stored.coffeeStains > 0 ? stored.coffeeStains : 0,
			lastMatch: isObject(stored.lastMatch) ? stored.lastMatch : undefined,
			shootout: typeof stored.shootout?.score === 'string' ? stored.shootout : undefined,
		};

		this.#loop = this.loop(seconds => {
			if (this.#isMotion) {
				this.#advance(seconds);
				this.#updateEffects(seconds);
			} else {
				this.#holdStep(seconds);
			}

			this.#draw();
		}, {
			while: () => this.#shouldRun,
			// A loop that stops, like when the visitor lets go of Kick, draws the frame where it stops.
			stopped: () => {
				this.#draw();
			},
		});

		const actions = {
			kickoff: () => {
				this.#startMatch();
			},
			flo: () => {
				this.#skipToFlo();
			},
			penalty: () => {
				this.#skipToPenalty();
			},
			sound: () => {
				this.#toggleSound();
			},
			chant: () => {
				if (this.#isChanting) {
					this.#stopChant();
				} else {
					this.#startChant();
					this.#talk('pappa', 'Olé, olé, olé, olé!', 'Olé, olé, olé, olé!', {seconds: 2.5});
				}
			},
			replay: () => {
				this.#startReplay();
			},
			shirt: () => {
				this.#toggleOutfit('shirt');
			},
			scarf: () => {
				this.#toggleOutfit('scarf');
			},
			paint: () => {
				this.#toggleOutfit('paint');
			},
			helmet: () => {
				this.#toggleOutfit('helmet');
			},
			shootout: () => {
				this.#startShootout();
			},
			paper: () => {
				this.#togglePaper();
			},
			italy: () => {
				this.#startItaly();
			},
			left: () => {
				this.#arrow(-1, 0);
			},
			right: () => {
				this.#arrow(1, 0);
			},
			up: () => {
				this.#arrow(0, -1);
			},
			down: () => {
				this.#arrow(0, 1);
			},
		};

		for (const [action, button] of this.#buttons) {
			if (action === 'kick') {
				continue;
			}

			this.on(button, 'click', () => {
				actions[action]();
				if (['kickoff', 'flo', 'penalty', 'shootout', 'italy', 'replay'].includes(action)) {
					canvas.scrollIntoView({block: 'nearest', behavior: this.#isMotion ? 'smooth' : 'auto'});
					canvas.focus({preventScroll: true});
				} else if (['left', 'right', 'up', 'down'].includes(action)) {
					canvas.focus({preventScroll: true});
				}
			});
		}

		// The kick button is held down to fill a meter in reduced motion, so it listens to the pointer and the keys itself.
		this.on(kick, 'pointerdown', event => {
			if (!event.isPrimary || event.button > 0) {
				return;
			}

			event.preventDefault();
			kick.setPointerCapture?.(event.pointerId);
			this.#press();
		});

		this.on(kick, 'pointerup', () => {
			this.#release();
		});

		for (const type of ['pointercancel', 'blur']) {
			this.on(kick, type, () => {
				this.#cancelHold();
			});
		}

		// A screen reader clicks without a pointer or keys.
		this.on(kick, 'click', event => {
			if (event.detail === 0) {
				this.#press();
				this.#release();
			}
		});

		this.on(kick, 'keydown', event => {
			if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				if (!event.repeat) {
					this.#press();
				}
			}
		});

		this.on(kick, 'keyup', event => {
			if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				this.#release();
			}
		});

		this.on(canvas, 'keydown', event => {
			const arrows = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]};
			if (event.key === ' ' || event.key === 'Enter') {
				event.preventDefault();
				if (!event.repeat) {
					this.#press();
				}
			} else if (arrows[event.key]) {
				event.preventDefault();
				this.#arrow(...arrows[event.key]);
			}
		});

		this.on(canvas, 'keyup', event => {
			if (event.key === ' ' || event.key === 'Enter') {
				this.#release();
			}
		});

		this.on(canvas, 'pointerdown', event => {
			if (!event.isPrimary || event.button > 0) {
				return;
			}

			this.#isTap = this.#isTapScene();
			if (this.#isTap) {
				return;
			}

			canvas.setPointerCapture?.(event.pointerId);
			if (!this.#tapGoal(canvasPoint(canvas, event))) {
				this.#press();
			}
		});

		this.on(canvas, 'pointerup', () => {
			this.#release();
		});

		this.on(canvas, 'click', () => {
			if (this.#isTap) {
				this.#isTap = false;
				this.#press();
				this.#release();
			}
		});

		for (const type of ['pointercancel', 'blur']) {
			this.on(canvas, type, () => {
				this.#cancelHold();
			});
		}

		this.#drawStickers();
		this.#updateButtons();
		this.say('Press Kick (or Space) to start the tape at the 78th minute. Kick again to fast-forward to the big moments.');
		this.#requestDraw();
	}

	disconnected() {
		this.#stopSounds();
	}

	get visibilityTarget() {
		return this.parts.canvas;
	}

	visibilityChanged(isVisible) {
		if (isVisible) {
			if (this.#isSoundOn && this.#audio.isRunning) {
				this.#audio.startCrowd();
			}

			this.#requestDraw();
		} else {
			this.#cancelHold();
			this.#stopSounds();
		}
	}

	reducedMotionChanged() {
		this.#cancelHold();
		if (!this.#isMotion) {
			this.#finishAutomaticPhase();
		}

		this.#updateButtons();
		this.#requestDraw();
	}

	musicStopped() {
		this.#stopChant();
	}

	#stopSounds() {
		this.#audio.stopCrowd();
		this.#stopChant();
		if (canSpeak && this.#isSoundOn) {
			speechSynthesis.cancel();
		}
	}

	get #isMotion() {
		return !this.reducedMotion;
	}

	#persist() {
		this.store('progress', this.#progress);
	}

	// The sound effects of the match and the living room.
	// A pea whistle: a high tone that the little ball inside makes flutter.
	#whistle(duration = 0.35, when = 0) {
		if (!this.#isSoundOn || !this.#audio.isRunning) {
			return;
		}

		const start = this.#audio.context.currentTime + when;
		const oscillator = new OscillatorNode(this.#audio.context, {type: 'sine', frequency: 2900});
		const flutter = new OscillatorNode(this.#audio.context, {type: 'square', frequency: 32});
		const flutterDepth = new GainNode(this.#audio.context, {gain: 180});
		const gain = new GainNode(this.#audio.context, {gain: 0});
		flutter.connect(flutterDepth).connect(oscillator.frequency);
		gain.gain.setValueAtTime(0, start);
		gain.gain.linearRampToValueAtTime(0.06, start + 0.02);
		gain.gain.setValueAtTime(0.06, start + duration - 0.04);
		gain.gain.linearRampToValueAtTime(0, start + duration);
		oscillator.connect(gain).connect(this.#audio.output);
		oscillator.start(start);
		flutter.start(start);
		oscillator.stop(start + duration + 0.02);
		flutter.stop(start + duration + 0.02);
	}

	#fullTimeWhistle() {
		this.#whistle(0.3, 0);
		this.#whistle(0.3, 0.45);
		this.#whistle(1, 0.9);
	}

	#kickSound() {
		if (this.#isSoundOn) {
			this.#audio.beep(150, 0.14, {type: 'sine', volume: 0.3, slideTo: 45});
			this.#audio.hiss(0.05, {volume: 0.2, frequency: 2500, type: 'highpass'});
		}
	}

	#netSound() {
		if (this.#isSoundOn) {
			this.#audio.hiss(0.4, {volume: 0.15, frequency: 4500, when: 0.02});
		}
	}

	#postSound() {
		if (this.#isSoundOn) {
			this.#audio.beep(880, 0.7, {type: 'triangle', volume: 0.12});
			this.#audio.beep(1320, 0.5, {type: 'triangle', volume: 0.06});
		}
	}

	#gloveSound() {
		if (this.#isSoundOn) {
			this.#audio.hiss(0.08, {volume: 0.4, frequency: 600, type: 'lowpass'});
		}
	}

	#bangSound() {
		if (this.#isSoundOn) {
			for (let index = 0; index < 3; index++) {
				this.#audio.hiss(0.12, {volume: 0.7, frequency: 140, type: 'lowpass', when: index * 0.2});
				this.#audio.beep(60, 0.12, {type: 'sine', volume: 0.3, when: index * 0.2});
			}
		}
	}

	#splashSound() {
		if (this.#isSoundOn) {
			this.#audio.hiss(0.3, {volume: 0.15, frequency: 1600, when: 0.25});
		}
	}

	#rewindSound() {
		if (this.#isSoundOn) {
			this.#audio.beep(180, 1.4, {type: 'sawtooth', volume: 0.025, slideTo: 1100});
			this.#audio.hiss(1.4, {volume: 0.04, frequency: 3000});
		}
	}

	// A sad trombone, for Italy: four notes down, the last one with a wobble.
	#sadTrombone() {
		if (!this.#isSoundOn || !this.#audio.isRunning) {
			return;
		}

		const notes = [[293.66, 0, 0.45], [277.18, 0.5, 0.45], [261.63, 1, 0.45], [246.94, 1.5, 1.6]];
		for (const [frequency, when, duration] of notes) {
			const start = this.#audio.context.currentTime + when;
			const oscillator = new OscillatorNode(this.#audio.context, {type: 'sawtooth', frequency});
			const filter = new BiquadFilterNode(this.#audio.context, {type: 'lowpass', frequency: 1100});
			const gain = new GainNode(this.#audio.context, {gain: 0});
			gain.gain.setValueAtTime(0, start);
			gain.gain.linearRampToValueAtTime(0.09, start + 0.06);
			gain.gain.setValueAtTime(0.09, start + duration - 0.15);
			gain.gain.linearRampToValueAtTime(0, start + duration);
			if (duration > 1) {
				const wobble = new OscillatorNode(this.#audio.context, {type: 'sine', frequency: 5.5});
				const depth = new GainNode(this.#audio.context, {gain: 7});
				wobble.connect(depth).connect(oscillator.frequency);
				wobble.start(start);
				wobble.stop(start + duration);
			}

			oscillator.connect(filter).connect(gain).connect(this.#audio.output);
			oscillator.start(start);
			oscillator.stop(start + duration + 0.02);
		}
	}

	// The “Olé, olé, olé” of the fans: a crowd of buzzing voices, shaped into an “o” and an “e” by two filters, like a mouth.
	#startChant() {
		if (!this.#audio.start(this.sound())) {
			return;
		}

		this.#isChanting = true;
		this.#chantGain = new GainNode(this.#audio.context, {gain: 1});
		this.#chantGain.connect(this.#audio.output);
		this.music(true);
		this.#updateButtons();
		this.#audio.context.resume().then(() => {
			this.#singChant(0);
		}, () => {});
	}

	#stopChant() {
		if (!this.#isChanting) {
			return;
		}

		this.#isChanting = false;
		clearTimeout(this.#chantTimer);
		this.#chantGain?.disconnect();
		this.#chantGain = undefined;
		this.music(false);
		this.#updateButtons();
	}

	#singChant(round) {
		if (!this.#isChanting || !this.#chantGain) {
			return;
		}

		// O-lé, o-lé o-lé o-lé, o-lé, o-lé: the notes as MIDI numbers, with how long each lasts.
		const syllables = [['o', 62, 0.22], ['e', 67, 0.55], ['o', 62, 0.2], ['e', 67, 0.28], ['o', 62, 0.2], ['e', 67, 0.28], ['o', 64, 0.22], ['e', 69, 0.55], ['o', 62, 0.22], ['e', 67, 0.9]];
		const formants = {o: [480, 850], e: [420, 1950]};
		let when = this.#audio.context.currentTime + 0.05;
		for (const [vowel, note, duration] of syllables) {
			const frequency = 440 * (2 ** ((note - 69) / 12));
			for (let voice = 0; voice < 5; voice++) {
				const start = when + (Math.random() * 0.04);
				const oscillator = new OscillatorNode(this.#audio.context, {type: 'sawtooth', frequency: frequency * (voice === 4 ? 0.5 : 1), detune: (Math.random() * 30) - 15});
				const gain = new GainNode(this.#audio.context, {gain: 0});
				gain.gain.setValueAtTime(0, start);
				gain.gain.linearRampToValueAtTime(0.03, start + 0.04);
				gain.gain.setValueAtTime(0.03, start + duration - 0.06);
				gain.gain.linearRampToValueAtTime(0, start + duration);
				for (const formant of formants[vowel]) {
					const filter = new BiquadFilterNode(this.#audio.context, {type: 'bandpass', frequency: formant, Q: 5});
					oscillator.connect(filter).connect(gain);
				}

				gain.connect(this.#chantGain);
				oscillator.start(start);
				oscillator.stop(start + duration + 0.05);
			}

			when += duration + 0.04;
		}

		this.#audio.hiss(when - this.#audio.context.currentTime, {volume: 0.05, frequency: 900, quality: 0.6, destination: this.#chantGain});
		const length = (when - this.#audio.context.currentTime) * 1000;
		this.#chantTimer = setTimeout(() => {
			if (round < 3) {
				this.#singChant(round + 1);
			} else {
				this.#stopChant();
			}
		}, length + 250);
	}

	// The voices: the made-up commentator, Kåre Brøl, talks Norwegian when the computer has a Norwegian voice, and fast when he goes wild. Mormor talks slowly.
	#speak(text, {rate = 1.1, pitch = 1, isUrgent = false} = {}) {
		if (!this.#isSoundOn || !canSpeak) {
			return;
		}

		if (isUrgent) {
			speechSynthesis.cancel();
		}

		const utterance = new SpeechSynthesisUtterance(text.replaceAll('–', ' ').replaceAll('…', ', '));
		const voice = speechSynthesis.getVoices().find(voice => /^(nb|no|nn)\b/i.test(voice.lang));
		utterance.lang = voice?.lang ?? 'nb-NO';
		if (voice) {
			utterance.voice = voice;
		}

		utterance.rate = rate;
		utterance.pitch = pitch;
		speechSynthesis.speak(utterance);
	}

	// The lines that the commentator and the family say in the same frame are joined, so a line of the family does not hide the commentator.
	#comment(norwegian, english, {isWild = false} = {}) {
		this.#subtitle = {norwegian, english, life: 6};
		this.#speak(norwegian, {rate: isWild ? 1.35 : 1.1, pitch: isWild ? 1.35 : 1, isUrgent: true});
		this.say(`Kåre Brøl, on the TV: “${norwegian}” (${english})`, this.parts.status, {join: true});
	}

	#talk(who, norwegian, english, {seconds = 3.5} = {}) {
		this.#bubbles.set(who, {text: norwegian, life: seconds});
		if (who === 'mormor') {
			this.#family.mormor.turn = seconds;
			this.#speak(norwegian, {rate: 0.85, pitch: 0.8});
		}

		this.say(`${people[who].name}: “${norwegian}” (${english})`, this.parts.status, {join: true});
	}

	// In reduced motion, each press shows a new still frame, so the reactions of the last one go away.
	#clearReactions() {
		this.#bubbles.clear();
		this.#family.pappa.jump = 0;
		this.#family.sindre.cheer = 0;
		this.#family.mormor.turn = 0;
		this.#family.wallBang = 0;
		this.#drops.length = 0;
	}

	// Pappa jumps up, and his coffee flies out of the cup and onto the carpet.
	#pappaJumps() {
		this.#family.pappa.jump = 1;
		this.#family.pappa.slump = 0;
		this.#splashSound();
		if (this.#isMotion) {
			for (let index = 0; index < 16; index++) {
				this.#drops.push({x: people.pappa.x + 30, y: 330, velocityX: (Math.random() * 160) - 60, velocityY: -120 - (Math.random() * 160), life: 2});
			}
		}

		this.#progress.coffeeStains = Math.min(this.#progress.coffeeStains + 1, stainSpots.length);
		this.#persist();
	}

	#neighborsBang() {
		this.#family.wallBang = 1.6;
		this.#bangSound();
	}

	#sindreCheers() {
		this.#family.sindre.cheer = 2.4;
	}

	#typeOf() {
		return this.#sceneTypes[this.#scene.kind];
	}

	#startScene(kind, options = {}) {
		this.#cancelHold();
		const type = this.#sceneTypes[kind];
		this.#scene = {kind, time: 0, eventIndex: 0, phase: undefined, phaseTime: 0, meter: 0, ...options};
		this.#scene.events = type.events ? type.events(this.#scene) : [];
		type.enter?.(this.#scene);
		this.#runDueEvents();
		type.sync?.(this.#scene);
		this.#updateButtons();
		this.#requestDraw();
	}

	#runDueEvents() {
		const current = this.#scene;
		while (current === this.#scene && current.eventIndex < current.events.length && current.events[current.eventIndex][0] <= current.time) {
			const [, action] = current.events[current.eventIndex];
			current.eventIndex++;
			action(current);
		}
	}

	#durationOf(current) {
		const {duration} = this.#sceneTypes[current.kind];
		return typeof duration === 'function' ? duration(current) : duration;
	}

	// Runs the events of the cutscene that are due, and goes on to what comes after it at its end.
	#playCutscene() {
		const current = this.#scene;
		this.#runDueEvents();
		if (current !== this.#scene) {
			return;
		}

		this.#typeOf().sync?.(this.#scene);
		if (this.#scene.time >= this.#durationOf(this.#scene)) {
			this.#typeOf().after(this.#scene);
		}
	}

	#advance(seconds) {
		const type = this.#typeOf();
		if (type.update) {
			type.update(this.#scene, seconds);
			return;
		}

		this.#scene.time += seconds;
		if (type.events) {
			this.#playCutscene();
		}
	}

	#stepCutscene() {
		this.#clearReactions();
		const duration = this.#durationOf(this.#scene);
		const next = this.#scene.events.slice(this.#scene.eventIndex).find(([time]) => time > this.#scene.time)?.[0] ?? duration;
		this.#scene.time = Math.min(next, duration);
		this.#playCutscene();
		this.#requestDraw();
	}

	// A phase that runs by itself would wait forever once the motion stops, so it is played to its end at once.
	#finishAutomaticPhase() {
		while (this.#typeOf().automaticPhases?.includes(this.#scene.phase)) {
			this.#typeOf().update(this.#scene, 10);
		}
	}

	#setPhase(phase, values = {}) {
		if (!this.#isMotion) {
			this.#clearReactions();
		}

		this.#scene.phase = phase;
		this.#scene.phaseTime = 0;
		this.#scene.meter = 0;
		this.#scene.holdTime = 0;
		Object.assign(this.#scene, values);
		this.#updateButtons();
		this.#requestDraw();
	}

	#earnSticker(identifier, isShiny) {
		const had = this.#progress.stickers[identifier];
		if (had === 'shiny' || (had && !isShiny)) {
			return;
		}

		this.#progress.stickers[identifier] = isShiny ? 'shiny' : 'earned';
		this.#persist();
		this.#drawStickers();
		this.toast(isShiny ? `A shiny Panini sticker: ${stickerInfo[identifier].name}! Trond will want to swap.` : `A new Panini sticker for the album: ${stickerInfo[identifier].name}!`);
	}

	// The scenes of the match against Brazil.
	#resetMatch(values) {
		Object.assign(this.#match, {mode: 'brazil', norway: 0, other: 0, moroccoGoals: 2, rewinds: 0, floTries: 0, penaltyTries: 0, penaltyShot: undefined}, values);
		this.#shootout = undefined;
	}

	#startMatch() {
		this.#resetMatch({clock: (77 * 60) + 40});
		this.#family.pappa.slump = 0;
		this.#startScene('bebeto');
	}

	#skipToFlo() {
		this.#resetMatch({other: 1, clock: (82 * 60) + 50});
		this.#startScene('flo');
	}

	// A skip to the penalty keeps the tries of Flo’s goal, for the paper.
	#skipToPenalty() {
		this.#resetMatch({norway: 1, other: 1, clock: (88 * 60) + 20, moroccoGoals: 3, floTries: Math.max(this.#match.floTries, 1)});
		this.#startScene('foul');
	}

	// A stretch of play, where the clock runs a minute a second, with events at minutes of the match.
	#playOn(from, to, after, minuteEvents = []) {
		this.#startScene('play', {from, to, after, minuteEvents});
	}

	#judgeMeter() {
		const [from, to] = zoneOf(this.#scene);
		const isHit = this.#scene.meter >= from && this.#scene.meter <= to;
		if (this.#scene.phase === 'ball') {
			if (isHit) {
				this.#kickSound();
				this.#comment('Flo tar ned ballen!', 'Flo brings the ball down!');
				if (this.#isMotion) {
					this.#setPhase('control');
				} else {
					this.#setPhase('turn');
					this.#announceMeter();
				}
			} else {
				this.#floFails('ball');
			}
		} else if (isHit) {
			this.#comment('Han vender! Forbi Junior Baiano!', 'He turns! Past Junior Baiano!', {isWild: true});
			this.#audio.crowdLevel(0.25, 0.4);
			if (this.#isMotion) {
				this.#setPhase('spin');
			} else {
				this.#startFloShot();
			}
		} else {
			this.#floFails('turn');
		}
	}

	#announceMeter() {
		if (this.#isMotion) {
			this.say(`${meterNames[this.#scene.phase]}: ${meterHints[this.#scene.phase]}`);
			return;
		}

		const [from, to] = zoneOf(this.#scene);
		const percent = value => Math.round(value * 100);
		const isInGreen = this.#scene.meter >= from && this.#scene.meter <= to;
		this.say(`${meterNames[this.#scene.phase]}: ${percent(this.#scene.meter)} of 100${isInGreen ? ', in the green!' : ''} The green is ${percent(from)} to ${percent(to)}. Hold Kick, or set it with ▲ and ▼ and press Kick.`);
	}

	#floFails(step) {
		this.#scene.fails++;
		if (step === 'ball') {
			this.#comment('Ballen spretter fra Flo… Den er borte.', 'The ball bounces off Flo… It is gone.');
			this.#setPhase('lost');
		} else {
			this.#comment('Junior Baiano tar ballen. Neeei.', 'Junior Baiano takes the ball. Nooo.');
			this.#setPhase('tackled');
		}

		this.#audio.crowdLevel(0.07, 1);
	}

	#startFloShot() {
		this.#setPhase('shot', {dive: keeperGuess(), aim: {u: 0, v: 0.4}});
		this.say(this.#isMotion ? 'Shoot! Press Kick when the reticle is in a corner.' : 'Shoot! Aim with the arrows, or tap the goal, then press Kick.');
	}

	#shootFlo() {
		const {u, v} = this.#scene.aim ?? {u: 0, v: 0.4};
		this.#kickSound();
		this.#scene.shot = {u, v, dive: this.#scene.dive, isBig: true, power: 0.7};
		this.#scene.shot.result = shotResult(this.#scene.shot);
		if (this.#isMotion) {
			this.#setPhase('flight');
		} else {
			this.#finishFloShot();
		}
	}

	#finishFloShot() {
		const {shot} = this.#scene;
		this.#setPhase('result');
		this.#reactToShot(shot.result);
		if (shot.result === 'goal') {
			this.#match.norway = 1;
			this.#lastGoal = this.#goalMoment('flo', shot, 'FLO 83’');
			this.#comment('MÅÅÅL! Tore André Flo! 1–1! Han la Junior Baiano i lomma og satte den forbi Taffarel!', 'GOAL! Tore André Flo! 1–1! He put Junior Baiano in his pocket and slotted it past Taffarel!', {isWild: true});
			this.#earnSticker('flo', this.#match.floTries === 1);
		} else {
			this.#comment(...missLines[shot.result]);
		}
	}

	#afterFloShot() {
		if (this.#scene.shot.result === 'goal') {
			this.#startScene('celebration', {
				scorer: 'TORE ANDRÉ FLO',
				minute: '83’',
				after: () => {
					this.#playOn((83 * 60) + 20, (88 * 60) + 20, () => {
						this.#startScene('foul');
					}, [[85 * 60, () => {
						this.#match.moroccoGoals = 3;
						this.#comment('Marokko leder 3–0 mot Skottland. Uavgjort er ikke nok. Vi MÅ vinne!', 'Morocco leads Scotland 3–0. A draw is not enough. We MUST win!');
					}]]);
				},
			});
		} else {
			this.#retryFlo(this.#scene.fails + 1);
		}
	}

	#retryFlo(fails) {
		this.#rewindTo(() => {
			this.#startScene('flo', {skipIntro: true, fails});
		});
	}

	// The family and the stadium react to a shot of Norway.
	#reactToShot(result) {
		if (result === 'goal') {
			this.#audio.roar();
			this.#netSound();
			this.#pappaJumps();
			this.#sindreCheers();
		} else if (result === 'post') {
			this.#postSound();
			this.#audio.crowdLevel(0.2, 0.2);
			this.#talk('pappa', 'Stolpen! Det er ikke sant!', 'The post! I don’t believe it!');
		} else if (result === 'saved') {
			this.#gloveSound();
			this.#talk('pappa', 'Åååh!', 'Ooooh!');
		} else {
			this.#talk('pappa', 'Åh, kom igjen!', 'Oh, come on!');
		}
	}

	// Pappa rewinds the tape on the VCR, and the visitor tries again.
	#rewindTo(after) {
		this.#match.rewinds++;
		this.#startScene('rewind', {after});
	}

	#announceAim() {
		const how = this.#isMotion ? 'Press Kick when the reticle is where you want to shoot.' : 'Aim with the arrows, or tap the goal, then press Kick.';
		this.say(this.#shootout ? how : `${how} Rekdal’s real one went low to the keeper’s right, which is your left.`);
	}

	// Too much power lifts the ball, and too little gives the keeper time.
	#shootPenalty() {
		const power = this.#scene.meter;
		const {u, v} = this.#scene.aim;
		const lift = power > 0.88 ? (power - 0.88) * 5 : 0;
		this.#scene.shot = {u, v: v + lift, power, dive: this.#scene.dive, isWeak: power < 0.35};
		this.#scene.shot.result = shotResult(this.#scene.shot);
		if (this.#isMotion) {
			this.#setPhase('runup');
		} else {
			this.#kickSound();
			this.#finishPenalty();
		}
	}

	#finishPenalty() {
		const {shot} = this.#scene;
		this.#setPhase('result');
		if (this.#shootout) {
			this.#shootout.norway.push(shot.result === 'goal');
			if (shot.result === 'goal') {
				this.#audio.roar();
				this.#netSound();
				this.#sindreCheers();
				this.#lastGoal = this.#goalMoment('penalty', shot, 'STRAFFE');
				this.#comment('Mål! Sikker som banken!', 'Goal! Safe as the bank!', {isWild: true});
			} else {
				this.#reactToShot(shot.result);
				this.#comment(...missLines[shot.result]);
			}

			return;
		}

		this.#reactToShot(shot.result);
		if (shot.result === 'goal') {
			this.#match.norway = 2;
			this.#match.penaltyShot = shot;
			this.#lastGoal = this.#goalMoment('penalty', shot, 'REKDAL 89’');
			this.#comment('REKDAL! REKDAL! NORGE SLÅR BRASIL! 2–1! Dette er ikke mulig! Hører dere meg, Brasil?', 'REKDAL! REKDAL! NORWAY IS BEATING BRAZIL! 2–1! This is not possible! Can you hear me, Brazil?', {isWild: true});
			this.#earnSticker('rekdal', this.#match.penaltyTries === 1);
		} else {
			this.#comment(...missLines[shot.result]);
		}
	}

	#afterPenalty() {
		if (this.#shootout) {
			this.#nextShootoutKick();
			return;
		}

		if (this.#scene.shot.result === 'goal') {
			this.#startScene('celebration', {
				scorer: 'KJETIL REKDAL',
				minute: '89’ (str.)',
				after: () => {
					this.#playOn((89 * 60) + 20, (91 * 60) + 50, () => {
						this.#startScene('fullTime');
					}, [[90 * 60, () => {
						this.#comment('Tre minutter tilleggstid. Kom igjen, blås av, dommer!', 'Three minutes of stoppage time. Come on, blow the whistle, referee!');
						this.#talk('pappa', 'Blås av! BLÅS AV!', 'Blow the whistle! BLOW IT!');
					}]]);
				},
			});
		} else {
			this.#rewindTo(() => {
				this.#startScene('penalty');
			});
		}
	}

	// The penalty shootout against Taffarel: five kicks each, then sudden death. The visitor kicks for Norway, and keeps goal against Brazil.
	#startShootout() {
		this.#match.mode = 'shootout';
		this.#shootout = {norway: [], brazil: []};
		this.#startScene('shootoutIntro');
	}

	#shootoutWinner() {
		const norwayGoals = goalsOf(this.#shootout.norway);
		const brazilGoals = goalsOf(this.#shootout.brazil);
		const norwayLeft = Math.max(0, 5 - this.#shootout.norway.length);
		const brazilLeft = Math.max(0, 5 - this.#shootout.brazil.length);
		if (this.#shootout.norway.length <= 5 && this.#shootout.brazil.length <= 5) {
			if (norwayGoals > brazilGoals + brazilLeft) {
				return 'norway';
			}

			if (brazilGoals > norwayGoals + norwayLeft) {
				return 'brazil';
			}
		}

		if (this.#shootout.norway.length >= 5 && this.#shootout.norway.length === this.#shootout.brazil.length && norwayGoals !== brazilGoals) {
			return norwayGoals > brazilGoals ? 'norway' : 'brazil';
		}

		return undefined;
	}

	#nextShootoutKick() {
		const winner = this.#shootoutWinner();
		if (winner) {
			this.#startScene('shootoutEnd', {winner});
		} else if (this.#shootout.brazil.length < this.#shootout.norway.length) {
			this.#startScene('keeper');
		} else {
			this.#startScene('penalty');
		}
	}

	#finishKeeper() {
		const {side, height, isMiss, choice} = this.#scene;
		let result = 'goal';
		if (isMiss) {
			result = height > 0.5 ? 'over' : 'wide';
		} else if (choice === side && (side === 0 || height < 0.5 || Math.random() < 0.6)) {
			result = 'saved';
		}

		this.#setPhase('result', {result});
		this.#shootout.brazil.push(result === 'goal');
		if (result === 'saved') {
			this.#audio.roar();
			this.#gloveSound();
			this.#sindreCheers();
			this.#pappaJumps();
			this.#comment('REDNING! Sindre tar den! For en keeper!', 'SAVED! Sindre stops it! What a keeper!', {isWild: true});
			this.#earnSticker('keeper', false);
		} else if (result === 'goal') {
			this.#netSound();
			this.#audio.crowdLevel(0.2, 0.3);
			this.#comment('Mål for Brasil. Du gikk feil vei.', 'Goal for Brazil. You went the wrong way.');
		} else {
			this.#audio.crowdLevel(0.25, 0.3);
			this.#comment('Han bommer! Brasil bommer!', 'He misses! Brazil misses!', {isWild: true});
		}
	}

	// The sad truth: four days later, Italy beat Norway 1–0 in the round of 16, with Vieri’s goal in the 18th minute.
	#startItaly() {
		Object.assign(this.#match, {mode: 'italy', norway: 0, other: 0, clock: (17 * 60) + 20});
		this.#shootout = undefined;
		this.#startScene('italyIntro');
	}

	#finishItalyShot() {
		const {result} = this.#scene.shot;
		this.#setPhase('result');
		const lines = {
			saved: ['For en redning! Keeperen tar alt i dag.', 'What a save! The keeper stops everything today.'],
			post: ['I stolpen! Det er ikke vår dag.', 'Off the post! It is not our day.'],
			over: ['Over. Over igjen.', 'Over. Over again.'],
			wide: ['Utenfor. Åh.', 'Wide. Oh.'],
		};
		this.#comment(...lines[result]);
		if (result === 'post') {
			this.#postSound();
		} else if (result === 'saved') {
			this.#gloveSound();
		}

		this.#talk('pappa', randomItem(['Neeei…', 'Kom igjen, Norge…', 'Det er ikke rettferdig.']), 'Nooo… / Come on, Norway… / It is not fair.', {seconds: 2.2});
	}

	#afterItalyShot() {
		const attempt = this.#scene.attempt + 1;
		if (attempt < 3) {
			this.#startScene('italyShot', {attempt});
		} else {
			this.#startScene('italyEnd');
		}
	}

	// The goal for the replay, with the match and the shootout as they stood, for the score bug.
	#goalMoment(view, shot, label) {
		return {
			view,
			shot,
			label,
			match: {...this.#match},
			shootout: this.#shootout && {norway: [...this.#shootout.norway], brazil: [...this.#shootout.brazil]},
		};
	}

	#startReplay() {
		if (!this.#lastGoal || !this.#typeOf().isResting) {
			return;
		}

		// The end of the shootout and of Italy would start over, so the replay comes back to the title instead.
		// The score bug of the replay is the one of the moment of the goal, also after Italy.
		Object.assign(this.#match, this.#lastGoal.match);
		this.#shootout = this.#lastGoal.shootout;
		this.#startScene('replay', {resume: this.#scene.kind === 'final' ? 'final' : 'title'});
	}

	// The holding of the kick button in reduced motion fills a meter in steps.
	#startHold() {
		this.#isHolding = true;
		this.#scene.holdTime = 0;
		this.#buttons.get('kick').dataset.state = 'on';
		this.#loop.start();
	}

	#stopHold() {
		this.#isHolding = false;
		this.#buttons.get('kick').dataset.state = '';
	}

	// A hold that loses its release, like when the focus moves away, is cancelled instead of judged.
	#cancelHold() {
		if (this.#isHolding) {
			this.#stopHold();
			this.#scene.meter = 0;
			this.#requestDraw();
		}
	}

	#holdStep(seconds) {
		if (!this.#isHolding) {
			return;
		}

		this.#scene.holdTime += seconds;
		while (this.#scene.holdTime >= 0.14) {
			this.#scene.holdTime -= 0.14;
			this.#scene.meter = Math.min(1, this.#scene.meter + 0.05);
		}
	}

	// The input of the visitor: a press and a release of the kick button, the arrows, and taps on the goal.
	#press() {
		const type = this.#typeOf();
		if (type.events) {
			this.#stepCutscene();
			return;
		}

		// A last screen waits a moment before a press starts over, so a visitor who mashes the button still sees it.
		if (this.#isMotion && type.isResting && this.#scene.kind !== 'title' && this.#scene.time < 2.5) {
			return;
		}

		type.press?.(this.#scene);
		this.#requestDraw();
	}

	#release() {
		this.#typeOf().release?.(this.#scene);
		this.#requestDraw();
	}

	#arrow(deltaX, deltaY) {
		const type = this.#typeOf();
		if (type.acceptsDive?.(this.#scene)) {
			type.arrow(this.#scene, deltaX, deltaY);
			return;
		}

		// In reduced motion, ▲ and ▼ move the needle of a meter in the steps of a hold, so a click on Kick, like the one of a screen reader, can kick with any power.
		if (type.acceptsMeter?.(this.#scene)) {
			if (deltaY !== 0) {
				this.#scene.meter = clamp(Math.round((this.#scene.meter - (deltaY * 0.05)) * 20) / 20, 0, 1);
				this.#announceMeter();
				this.#requestDraw();
			}

			return;
		}

		if (type.acceptsAim?.(this.#scene)) {
			this.#scene.aim.u = clamp(this.#scene.aim.u + (deltaX * 0.25), -1.25, 1.25);
			this.#scene.aim.v = clamp(this.#scene.aim.v - (deltaY * 0.2), 0, 1.2);
			this.#requestDraw();
		}
	}

	#tapGoal(point) {
		const type = this.#typeOf();
		if (!type.acceptsAim?.(this.#scene)) {
			return false;
		}

		const goal = goalOf(this.#scene.kind);
		const x = point.x - screenArea.x;
		const y = point.y - screenArea.y;
		if (x < 0 || y < 0 || x > screenArea.width || y > screenArea.height) {
			return false;
		}

		this.#scene.aim = {u: clamp((x - goal.x) / (goal.width / 2), -1.25, 1.25), v: clamp((goal.y - y) / goal.height, 0, 1.2)};
		this.#requestDraw();
		return true;
	}

	#drawScoreBug() {
		const tv = this.#tv;
		tv.save();
		tv.font = 'bold 12px Arial, sans-serif';
		tv.textBaseline = 'middle';
		if (this.#match.mode === 'shootout' && this.#shootout) {
			this.#drawShootoutBoard();
			tv.restore();
			return;
		}

		const [leftFlag, leftName, leftScore, rightFlag, rightName, rightScore] = this.#match.mode === 'italy'
			? ['italy', 'ITA', this.#match.other, 'norway', 'NOR', this.#match.norway]
			: ['norway', 'NOR', this.#match.norway, 'brazil', 'BRA', this.#match.other];
		tv.fillStyle = 'rgb(0 0 40 / 80%)';
		tv.fillRect(10, 10, 132, 20);
		flag[leftFlag](tv, 14, 14, 16, 12);
		tv.fillStyle = '#ffffff';
		tv.fillText(leftName, 34, 20.5);
		tv.fillStyle = '#ffdf00';
		tv.fillText(`${leftScore}–${rightScore}`, 64, 20.5);
		tv.fillStyle = '#ffffff';
		tv.fillText(rightName, 92, 20.5);
		flag[rightFlag](tv, 122, 14, 16, 12);
		tv.fillStyle = 'rgb(200 0 0 / 85%)';
		tv.fillRect(142, 10, 46, 20);
		tv.fillStyle = '#ffffff';
		tv.fillText(clockText(Math.min(this.#match.clock, 90 * 60)), 147, 20.5);
		if (this.#match.clock > 90 * 60) {
			tv.fillStyle = 'rgb(0 0 40 / 80%)';
			tv.fillRect(188, 10, 24, 20);
			tv.fillStyle = '#ffdf00';
			tv.fillText('+3', 192, 20.5);
		}

		// Live, with the red dot that blinks.
		tv.textAlign = 'right';
		tv.fillStyle = 'rgb(0 0 40 / 70%)';
		tv.fillRect(334, 10, 96, 20);
		tv.fillStyle = '#ffffff';
		tv.fillText('DIREKTE', 426, 20.5);
		if (!this.#isMotion || Math.floor(this.#roomTime * 2) % 2 === 0) {
			tv.fillStyle = '#ff2020';
			tv.beginPath();
			tv.arc(343, 20, 4, 0, Math.PI * 2);
			tv.fill();
		}

		tv.restore();
		this.#drawTicker();
	}

	// The ticker at the bottom: the other match of the group, played at the same time.
	#drawTicker() {
		const tv = this.#tv;
		const text = this.#match.mode === 'italy'
			? 'ÅTTEDELSFINALE · STADE VÉLODROME, MARSEILLE · VINNEREN MØTER FRANKRIKE I KVARTFINALEN · '
			: `SAMTIDIG I SAINT-ÉTIENNE: SKOTTLAND 0–${this.#match.moroccoGoals} MAROKKO · NORGE MÅ VINNE FOR Å GÅ VIDERE · `;
		tv.save();
		tv.fillStyle = '#0a2a8a';
		tv.fillRect(0, 248, 440, 16);
		tv.fillStyle = '#ffdf00';
		tv.fillRect(0, 248, 52, 16);
		tv.font = 'bold 10px Arial, sans-serif';
		tv.textBaseline = 'middle';
		tv.fillStyle = '#0a2a8a';
		tv.fillText('VM 98', 8, 256.5);
		tv.beginPath();
		tv.rect(54, 248, 386, 16);
		tv.clip();
		tv.fillStyle = '#ffffff';
		const width = tv.measureText(text).width;
		const offset = this.#isMotion ? (this.#roomTime * 40) % width : 0;
		tv.fillText(text, 58 - offset, 256.5);
		tv.fillText(text, 58 - offset + width, 256.5);
		tv.restore();
	}

	#drawShootoutBoard() {
		const tv = this.#tv;
		tv.fillStyle = 'rgb(0 0 40 / 82%)';
		tv.fillRect(10, 10, 190, 38);
		tv.font = 'bold 11px Arial, sans-serif';
		tv.textBaseline = 'middle';
		const rows = [['norway', 'NOR', this.#shootout.norway], ['brazil', 'BRA', this.#shootout.brazil]];
		for (const [index, [flagName, name, kicks]] of rows.entries()) {
			const y = 20 + (index * 17);
			flag[flagName](tv, 14, y - 6, 14, 11);
			tv.fillStyle = '#ffffff';
			tv.fillText(name, 32, y + 0.5);
			const shown = Math.max(5, kicks.length);
			for (let kick = 0; kick < shown; kick++) {
				const x = 66 + (kick * 15) - (Math.max(0, shown - 9) * 15);
				if (x < 62) {
					continue;
				}

				tv.beginPath();
				tv.arc(x, y, 5, 0, Math.PI * 2);
				if (kick < kicks.length) {
					tv.fillStyle = kicks[kick] ? '#30d030' : '#e02020';
					tv.fill();
				} else {
					tv.strokeStyle = '#ffffff';
					tv.lineWidth = 1;
					tv.stroke();
				}
			}
		}
	}

	#drawSubtitle() {
		const tv = this.#tv;
		if (!this.#subtitle || playingPhases.has(this.#scene.phase) || cardScenes.has(this.#scene.kind)) {
			return;
		}

		tv.save();
		const norwegianFont = 'bold 12px Arial, sans-serif';
		const englishFont = '10px Arial, sans-serif';
		tv.font = norwegianFont;
		const norwegianLines = wrapText(tv, this.#subtitle.norwegian, 420).slice(0, 2);
		tv.font = englishFont;
		const englishLines = wrapText(tv, this.#subtitle.english, 420).slice(0, 2);
		const lineCount = norwegianLines.length + englishLines.length;
		let y = 245 - (lineCount * 13);
		tv.textAlign = 'center';
		tv.textBaseline = 'top';
		for (const [index, line] of [...norwegianLines, ...englishLines].entries()) {
			const isNorwegian = index < norwegianLines.length;
			tv.font = isNorwegian ? norwegianFont : englishFont;
			const width = tv.measureText(line).width;
			tv.fillStyle = 'rgb(0 0 0 / 72%)';
			tv.fillRect(220 - (width / 2) - 4, y - 1, width + 8, 13);
			tv.fillStyle = isNorwegian ? '#ffffff' : '#ffff40';
			tv.fillText(line, 220, y);
			y += 13;
		}

		tv.restore();
	}

	// The hint that a press goes on: in a cutscene it fast-forwards the tape, and in reduced motion the TV waits for it.
	#drawContinueHint() {
		const tv = this.#tv;
		const type = this.#typeOf();
		if (type.isResting || (this.#isMotion && !type.events)) {
			return;
		}

		tv.save();
		tv.font = 'bold 11px Arial, sans-serif';
		tv.textAlign = 'right';
		tv.fillStyle = 'rgb(0 0 0 / 60%)';
		tv.fillRect(342, 34, 90, 16);
		tv.fillStyle = '#ffffff';
		tv.fillText(this.#isMotion ? 'Kick ▶▶' : 'Kick ▶', 428, 46);
		tv.restore();
	}

	#drawStands(offset, excitement = 0, height = 56) {
		const tv = this.#tv;
		tv.fillStyle = '#1b1b2b';
		tv.fillRect(0, 0, 440, height);
		for (const fan of fans) {
			const x = ((fan.x - offset) % 880 + 880) % 880 - 220;
			if (x < -4 || x > 444 || fan.y > height - 4) {
				continue;
			}

			const bounce = this.#isMotion ? Math.abs(Math.sin((this.#roomTime * 9) + fan.seed)) * 3 * excitement : 0;
			tv.fillStyle = fan.color;
			tv.fillRect(x, fan.y - bounce, 3, 3);
		}
	}

	#drawBoards(offset, y, height = 14) {
		const tv = this.#tv;
		tv.save();
		tv.font = `bold ${Math.round(height * 0.7)}px Arial, sans-serif`;
		tv.textBaseline = 'middle';
		tv.textAlign = 'center';
		const width = 92;
		const start = Math.floor(offset / width) - 1;
		for (let index = start; index < start + 7; index++) {
			const x = (index * width) - offset;
			const name = adBoards[((index % adBoards.length) + adBoards.length) % adBoards.length];
			const isDark = ((index % 2) + 2) % 2 === 0;
			tv.fillStyle = isDark ? '#0a2a8a' : '#ffffff';
			tv.fillRect(x, y, width, height);
			tv.fillStyle = isDark ? '#ffffff' : '#d40000';
			tv.fillText(name, x + (width / 2), y + (height / 2) + 0.5);
		}

		tv.restore();
	}

	#project(x, y, z = 0) {
		const depth = y / 68;
		const scale = 6 + (depth * 5);
		return {x: 220 + ((x - this.#wide.camera) * scale), y: 74 + (depth * 180) - (z * scale), scale};
	}

	#pitchLine(points) {
		const tv = this.#tv;
		tv.beginPath();
		for (const [index, [x, y]] of points.entries()) {
			const point = this.#project(x, y);
			if (index === 0) {
				tv.moveTo(point.x, point.y);
			} else {
				tv.lineTo(point.x, point.y);
			}
		}

		tv.stroke();
	}

	#drawWidePitch(excitement = 0) {
		const tv = this.#tv;
		this.#drawStands(this.#wide.camera * 2.2, excitement, 58);
		this.#drawBoards(this.#wide.camera * 3.4, 58, 14);
		tv.fillStyle = '#2a7d2a';
		tv.fillRect(0, 72, 440, 192);
		for (let index = -4; index < 24; index++) {
			const x = index * 5.25;
			const corners = [this.#project(x, -4), this.#project(x + 5.25, -4), this.#project(x + 5.25, 72), this.#project(x, 72)];
			tv.fillStyle = index % 2 === 0 ? '#319032' : '#2b832c';
			tv.beginPath();
			tv.moveTo(corners[0].x, corners[0].y);
			for (const corner of corners.slice(1)) {
				tv.lineTo(corner.x, corner.y);
			}

			tv.fill();
		}

		tv.strokeStyle = 'rgb(255 255 255 / 85%)';
		tv.lineWidth = 1.4;
		this.#pitchLine([[0, 0], [105, 0], [105, 68], [0, 68], [0, 0]]);
		this.#pitchLine([[52.5, 0], [52.5, 68]]);
		this.#pitchLine(Array.from({length: 33}, (_, index) => [52.5 + (Math.cos(index / 32 * Math.PI * 2) * 9.15), 34 + (Math.sin(index / 32 * Math.PI * 2) * 9.15)]));
		for (const [goalLine, direction] of [[0, 1], [105, -1]]) {
			this.#pitchLine([[goalLine, 13.84], [goalLine + (direction * 16.5), 13.84], [goalLine + (direction * 16.5), 54.16], [goalLine, 54.16]]);
			this.#pitchLine([[goalLine, 24.84], [goalLine + (direction * 5.5), 24.84], [goalLine + (direction * 5.5), 43.16], [goalLine, 43.16]]);
			const spot = this.#project(goalLine + (direction * 11), 34);
			tv.fillStyle = '#ffffff';
			tv.fillRect(spot.x - 1, spot.y - 1, 2, 2);
			this.#drawWideGoal(goalLine, direction);
		}
	}

	#drawWideGoal(goalLine, direction, shake = 0) {
		const tv = this.#tv;
		const back = goalLine - (direction * 2);
		const near = [this.#project(goalLine, 37.66), this.#project(goalLine, 37.66, 2.44)];
		const far = [this.#project(goalLine, 30.34), this.#project(goalLine, 30.34, 2.44)];
		const backNear = [this.#project(back, 37.66, 0), this.#project(back, 37.66, 2)];
		const backFar = [this.#project(back, 30.34, 0), this.#project(back, 30.34, 2)];
		tv.fillStyle = 'rgb(255 255 255 / 22%)';
		tv.beginPath();
		tv.moveTo(far[1].x, far[1].y);
		tv.lineTo(backFar[1].x + shake, backFar[1].y);
		tv.lineTo(backNear[1].x + shake, backNear[1].y);
		tv.lineTo(backNear[0].x, backNear[0].y);
		tv.lineTo(near[0].x, near[0].y);
		tv.lineTo(near[1].x, near[1].y);
		tv.fill();
		tv.strokeStyle = 'rgb(255 255 255 / 40%)';
		tv.lineWidth = 0.6;
		for (let index = 0; index <= 6; index++) {
			const amount = index / 6;
			tv.beginPath();
			tv.moveTo(lerp(far[1].x, near[1].x, amount), lerp(far[1].y, near[1].y, amount));
			tv.lineTo(lerp(backFar[1].x, backNear[1].x, amount) + shake, lerp(backFar[1].y, backNear[1].y, amount));
			tv.lineTo(lerp(backFar[0].x, backNear[0].x, amount), lerp(backFar[0].y, backNear[0].y, amount));
			tv.stroke();
		}

		tv.strokeStyle = '#ffffff';
		tv.lineWidth = 2;
		tv.beginPath();
		tv.moveTo(far[0].x, far[0].y);
		tv.lineTo(far[1].x, far[1].y);
		tv.lineTo(near[1].x, near[1].y);
		tv.lineTo(near[0].x, near[0].y);
		tv.stroke();
	}

	// A player of the wide view, standing on the point of their feet, from the side. The pose bends them: running, jumping, falling, or with the arms up.
	#drawPlayer(x, y, scale, kit, {phase = 0, pose = 'run', lean = 0, skin, arm} = {}) {
		const tv = this.#tv;
		const height = 1.85 * scale * 1.15;
		tv.save();
		tv.translate(x, y);
		tv.rotate(pose === 'fall' ? lean || 1.3 : lean);
		const swing = pose === 'run' ? Math.sin(phase) * height * 0.16 : (pose === 'jump' ? height * 0.1 : 0);
		tv.lineCap = 'round';
		tv.strokeStyle = kit.socks;
		tv.lineWidth = Math.max(1.4, height * 0.1);
		tv.beginPath();
		tv.moveTo(-height * 0.05, -height * 0.45);
		tv.lineTo((-height * 0.05) + swing, 0);
		tv.moveTo(height * 0.05, -height * 0.45);
		tv.lineTo((height * 0.05) - swing, 0);
		tv.stroke();
		tv.fillStyle = kit.shorts;
		tv.fillRect(-height * 0.12, -height * 0.56, height * 0.24, height * 0.15);
		tv.fillStyle = kit.shirt;
		tv.fillRect(-height * 0.13, -height * 0.84, height * 0.26, height * 0.3);
		tv.strokeStyle = kit.shirt;
		tv.lineWidth = Math.max(1.2, height * 0.08);
		tv.beginPath();
		if (pose === 'celebrate' || pose === 'jump') {
			tv.moveTo(-height * 0.1, -height * 0.8);
			tv.lineTo(-height * 0.22, -height * 1.12);
			tv.moveTo(height * 0.1, -height * 0.8);
			tv.lineTo(height * 0.22, -height * 1.12);
		} else if (arm) {
			tv.moveTo(0, -height * 0.78);
			tv.lineTo(arm.x * height * 0.4, -height * 0.78 + (arm.y * height * 0.4));
		} else {
			tv.moveTo(-height * 0.1, -height * 0.8);
			tv.lineTo((-height * 0.14) - (swing * 0.5), -height * 0.55);
			tv.moveTo(height * 0.1, -height * 0.8);
			tv.lineTo((height * 0.14) + (swing * 0.5), -height * 0.55);
		}

		tv.stroke();
		tv.fillStyle = skin ?? kit.skin;
		tv.beginPath();
		tv.arc(0, -height * 0.93, height * 0.1, 0, Math.PI * 2);
		tv.fill();
		tv.fillStyle = kit.hair;
		tv.beginPath();
		tv.arc(0, -height * 0.95, height * 0.1, Math.PI, Math.PI * 2);
		tv.fill();
		tv.restore();
	}

	#drawBall(x, y, z, {isShadowed = true} = {}) {
		const tv = this.#tv;
		const ground = this.#project(x, y);
		const air = this.#project(x, y, z);
		if (isShadowed) {
			tv.fillStyle = 'rgb(0 0 0 / 30%)';
			tv.beginPath();
			tv.ellipse(ground.x, ground.y, ground.scale * 0.4, ground.scale * 0.15, 0, 0, Math.PI * 2);
			tv.fill();
		}

		tv.fillStyle = '#ffffff';
		tv.beginPath();
		tv.arc(air.x, air.y - (air.scale * 0.25), Math.max(1.8, air.scale * 0.32), 0, Math.PI * 2);
		tv.fill();
	}

	// Draws the players and the ball of the wide view, the far ones first.
	#drawWideThings(players, ball) {
		const things = players.map(player => ({...player, depth: player.y}));
		if (ball) {
			things.push({isBall: true, ...ball, depth: ball.y + 0.01});
		}

		things.sort((first, second) => first.depth - second.depth);
		for (const thing of things) {
			if (thing.isBall) {
				this.#drawBall(thing.x, thing.y, thing.z ?? 0);
			} else {
				const point = this.#project(thing.x, thing.y, thing.z ?? 0);
				this.#drawPlayer(point.x, point.y, point.scale, thing.kit, thing);
			}
		}
	}

	// The general play between the big moments, made only from the time, so it can also be shown still.
	#drawAmbient(time, {attackRight = true} = {}) {
		const center = 55 + (Math.sin(time * 0.35) * 22);
		const home = this.#match.mode === 'italy' ? kits.italy : kits.brazil;
		const players = [];
		const offsets = [[-14, 18], [-6, 40], [2, 12], [8, 30], [14, 52], [-2, 58], [20, 24]];
		for (const [index, [offsetX, offsetY]] of offsets.entries()) {
			players.push({x: center + offsetX + (Math.sin((time * 1.3) + index) * 3), y: offsetY + (Math.cos((time * 0.9) + index) * 3), kit: kits.norway, phase: (time * 9) + index});
			players.push({x: center + offsetX + 4 + (Math.cos((time * 1.1) + index) * 3), y: offsetY + 5 + (Math.sin((time * 1.2) + (index * 2)) * 3), kit: home, phase: (time * 9) + index + 1, skin: brazilSkins[index % brazilSkins.length]});
		}

		const passTime = 1.3;
		const pass = Math.floor(time / passTime);
		const amount = (time / passTime) - pass;
		const from = players[(pass * 5) % players.length];
		const to = players[((pass * 5) + 3) % players.length];
		const ball = {x: lerp(from.x, to.x, amount), y: lerp(from.y, to.y, amount), z: pass % 3 === 0 ? Math.sin(amount * Math.PI) * 4 : 0};
		this.#wide.camera = clamp(center + (attackRight ? 4 : -4), 22, 83);
		this.#drawWidePitch(0.3);
		this.#drawWideThings(players, ball);
	}

	// The name of the scorer, under the score bug, where the subtitles do not cover it.
	#drawLowerThird(text) {
		const tv = this.#tv;
		tv.save();
		tv.font = 'bold 13px Arial, sans-serif';
		const width = tv.measureText(text).width + 22;
		const y = this.#match.mode === 'shootout' ? 52 : 34;
		tv.fillStyle = 'rgb(0 0 60 / 85%)';
		tv.fillRect(10, y, width, 22);
		tv.fillStyle = '#ffdf00';
		tv.fillRect(10, y, 5, 22);
		tv.textBaseline = 'middle';
		tv.fillStyle = '#ffffff';
		tv.fillText(text, 22, y + 11.5);
		tv.restore();
	}

	#drawBebeto(time) {
		const crossFrom = {x: 20, y: 60};
		const winger = time < 1.6 ? {x: lerp(32, 20, time / 1.6), y: lerp(62, 60, time / 1.6)} : {x: 20 - ((time - 1.6) * 1.5), y: 60};
		const bebetoArrive = progressOf(time, 0, 2.4);
		const bebeto = {x: lerp(16, 7.3, bebetoArrive), y: lerp(44, 35.5, bebetoArrive)};
		const isJumping = time > 2.3 && time < 2.9;
		let ball;
		if (time < 1.6) {
			ball = {x: winger.x - 0.8, y: winger.y + 0.3, z: 0};
		} else if (time < 2.6) {
			const amount = progressOf(time, 1.6, 2.6);
			ball = {x: lerp(crossFrom.x, 7.2, amount), y: lerp(crossFrom.y, 35.4, amount), z: (Math.sin(amount * Math.PI) * 7) + (amount * 2.4)};
		} else if (time < 2.8) {
			const amount = progressOf(time, 2.6, 2.8);
			ball = {x: lerp(7.2, -0.4, amount), y: lerp(35.4, 32.6, amount), z: lerp(2.4, 1.4, amount)};
		} else {
			ball = {x: -1, y: 32.6, z: Math.max(0.2, 1.4 - ((time - 2.8) * 2))};
		}

		const celebration = progressOf(time, 3, 7);
		const players = [
			{x: winger.x, y: winger.y, kit: kits.brazil, phase: time * 10, skin: brazilSkins[2]},
			{x: isJumping || time < 3 ? bebeto.x : lerp(7.3, 16, celebration), y: time < 3 ? bebeto.y : lerp(35.5, 62, celebration), z: isJumping ? Math.sin(progressOf(time, 2.3, 2.9) * Math.PI) * 0.7 : 0, kit: kits.brazil, phase: time * 10, pose: isJumping ? 'jump' : (time > 3 ? 'celebrate' : 'run'), skin: brazilSkins[0]},
			{x: lerp(23, 18, progressOf(time, 0, 1.6)), y: 57, kit: kits.norway, phase: time * 10},
			{x: 9, y: lerp(39, 37, bebetoArrive), kit: kits.norway, phase: time * 8},
			{x: 10, y: 30, kit: kits.norway, phase: time * 7},
			{x: 13, y: 26, kit: kits.brazil, phase: time * 7, skin: brazilSkins[1]},
			{x: 1.4, y: time > 2.55 ? lerp(34.5, 32, progressOf(time, 2.55, 2.85)) : 34.5, kit: kits.norwayKeeper, pose: time > 2.6 ? 'fall' : 'stand', lean: -1.2},
		];
		this.#wide.camera = lerp(24, 14, progressOf(time, 0, 2.6));
		this.#drawWidePitch(time > 2.8 ? 1 : 0.3);
		this.#drawWideThings(players, ball);
		if (time > 3.2) {
			this.#drawLowerThird('⚽ 78’ BEBETO');
		}
	}

	#drawFoul(time) {
		const fall = progressOf(time, 1.1, 1.5);
		const flo = {x: lerp(91, 95.5, progressOf(time, 0, 1.1)), y: 36, kit: kits.norway, phase: time * 10, pose: fall > 0 ? 'fall' : 'run', lean: fall * 1.3};
		const baiano = {x: flo.x - 1.2, y: 37.2, kit: kits.brazil, phase: time * 10, skin: brazilSkins[2], arm: {x: 1, y: 0.1}};
		const referee = {x: lerp(84, 90, progressOf(time, 1, 2.4)), y: lerp(28, 31, progressOf(time, 1, 2.4)), kit: kits.referee, phase: time * 8, pose: time > 2.4 ? 'stand' : 'run', arm: time > 1.7 ? {x: 0.9, y: 0.25} : undefined};
		const players = [
			flo,
			baiano,
			referee,
			{x: 101, y: 34, kit: kits.taffarel, pose: 'stand'},
			{x: 93, y: 44, kit: kits.brazil, phase: time * 6, skin: brazilSkins[1]},
			{x: 86, y: 40, kit: kits.norway, phase: time * 6},
		];
		const ball = {x: time < 1.1 ? flo.x + 1 : 97 + Math.min(1, (time - 1.1)), y: 36.3, z: 0};
		this.#wide.camera = 86;
		this.#drawWidePitch(time > 1.6 ? 1 : 0.4);
		this.#drawWideThings(players, ball);
		if (time > 1.7) {
			this.#drawLowerThird('STRAFFE! PENALTY!');
		}
	}

	#drawVieri(time) {
		const passAmount = progressOf(time, 0.4, 2);
		const vieriRun = progressOf(time, 0, 2.8);
		const vieri = {x: lerp(32, 11, vieriRun), y: lerp(35, 32, vieriRun), kit: kits.italy, phase: time * 11, pose: time > 3.4 ? 'celebrate' : 'run'};
		let ball;
		if (time < 0.4) {
			ball = {x: 48, y: 30, z: 0};
		} else if (time < 2) {
			ball = {x: lerp(48, 16, passAmount), y: lerp(30, 33, passAmount), z: Math.sin(passAmount * Math.PI) * 9};
		} else if (time < 2.8) {
			ball = {x: vieri.x - 0.9, y: vieri.y + 0.3, z: 0};
		} else if (time < 3.2) {
			const amount = progressOf(time, 2.8, 3.2);
			ball = {x: lerp(10, -0.5, amount), y: lerp(32.3, 36.2, amount), z: lerp(0, 0.6, amount)};
		} else {
			ball = {x: -1, y: 36.2, z: 0.2};
		}

		if (time > 3.4) {
			vieri.x = lerp(11, 18, progressOf(time, 3.4, 7));
			vieri.y = lerp(32, 60, progressOf(time, 3.4, 7));
		}

		const players = [
			vieri,
			{x: lerp(28, 14, vieriRun), y: 38, kit: kits.norway, phase: time * 10},
			{x: lerp(26, 15, vieriRun), y: 27, kit: kits.norway, phase: time * 10},
			{x: 2, y: time > 2.9 ? lerp(34, 31, progressOf(time, 2.9, 3.2)) : 34, kit: kits.norwayKeeper, pose: time > 2.9 ? 'fall' : 'stand', lean: -1.2},
			{x: lerp(46, 40, progressOf(time, 0, 2)), y: 30, kit: kits.italy, phase: time * 6},
		];
		this.#wide.camera = lerp(42, 14, progressOf(time, 0, 3));
		this.#drawWidePitch(0.2);
		this.#drawWideThings(players, ball);
		if (time > 3.4) {
			this.#drawLowerThird('⚽ 18’ VIERI');
		}
	}

	#drawCelebration(current) {
		const tv = this.#tv;
		const {time} = current;
		const isPenalty = current.scorer.includes('REKDAL');
		const corner = {x: 100, y: 66};
		const players = [];
		for (let index = 0; index < 8; index++) {
			const arrive = progressOf(time, index * 0.2, 1.8 + (index * 0.2));
			const start = {x: 82 + ((index * 7) % 15), y: 22 + ((index * 11) % 30)};
			players.push({
				x: lerp(start.x, corner.x - ((index % 3) * 1.2), easeOut(arrive)),
				y: lerp(start.y, corner.y - (Math.floor(index / 3) * 1.4), easeOut(arrive)),
				kit: kits.norway,
				phase: time * 12,
				pose: arrive >= 1 ? 'celebrate' : 'run',
				z: arrive >= 1 && this.#isMotion ? Math.abs(Math.sin((time * 8) + index)) * 0.4 : 0,
			});
		}

		this.#wide.camera = lerp(88, 96, progressOf(time, 0, 2));
		this.#drawWidePitch(1);
		this.#drawWideThings(players);
		tv.save();
		const pulse = this.#isMotion ? 1 + (Math.sin(time * 10) * 0.06) : 1;
		tv.translate(200, 118);
		tv.scale(pulse, pulse);
		tv.font = '900 46px Impact, "Arial Black", sans-serif';
		tv.textAlign = 'center';
		tv.textBaseline = 'middle';
		tv.lineWidth = 6;
		tv.strokeStyle = '#00205b';
		tv.strokeText('MÅÅÅÅL!', 0, 0);
		tv.fillStyle = this.#isMotion && Math.floor(time * 6) % 2 === 0 ? '#ffffff' : '#ffdf00';
		tv.fillText('MÅÅÅÅL!', 0, 0);
		tv.restore();
		this.#drawLowerThird(`⚽ ${current.minute} ${current.scorer}`);
	}

	// The view behind the shooter, toward the goal: the stands, the ad boards, the net, and the keeper.
	#drawGoalView(goal, {excitement = 0.2, netShake = 0} = {}) {
		const tv = this.#tv;
		const scale = goal.width / 250;
		const standsBottom = goal.y - (goal.height * 0.6);
		this.#drawStands(0, excitement, standsBottom);
		this.#drawBoards(30, standsBottom, 18 * scale);
		tv.fillStyle = '#2b832c';
		tv.fillRect(0, standsBottom + (18 * scale), 440, 264);
		// The mowing stripes run across, and get taller nearer the camera.
		let y = standsBottom + (18 * scale);
		let band = 0;
		while (y < 264) {
			const height = 6 + ((y - standsBottom) * 0.22);
			tv.fillStyle = band % 2 === 0 ? '#319032' : '#2b832c';
			tv.fillRect(0, y, 440, height);
			y += height;
			band++;
		}

		tv.strokeStyle = 'rgb(255 255 255 / 85%)';
		tv.lineWidth = 2 * scale;
		tv.beginPath();
		tv.moveTo(0, goal.y);
		tv.lineTo(440, goal.y);
		const box = goal.width * 0.75;
		tv.moveTo(goal.x - box, goal.y);
		tv.lineTo(goal.x - (box * 1.25), goal.y + (34 * scale));
		tv.lineTo(goal.x + (box * 1.25), goal.y + (34 * scale));
		tv.lineTo(goal.x + box, goal.y);
		tv.stroke();
		tv.fillStyle = '#ffffff';
		tv.beginPath();
		tv.ellipse(goal.x, goal.y + (80 * scale), 4 * scale, 2 * scale, 0, 0, Math.PI * 2);
		tv.fill();

		// The net, with a ripple when the ball hits it.
		const left = goal.x - (goal.width / 2);
		const top = goal.y - goal.height;
		tv.fillStyle = 'rgb(255 255 255 / 12%)';
		tv.fillRect(left, top, goal.width, goal.height);
		tv.strokeStyle = 'rgb(255 255 255 / 35%)';
		tv.lineWidth = 0.7;
		const mesh = 7 * scale;
		const ripple = (position, other) => (netShake > 0 ? Math.sin((other * 0.25) + (this.#roomTime * 40)) * netShake * 3 : 0) + position;
		for (let x = left + mesh; x < left + goal.width; x += mesh) {
			tv.beginPath();
			tv.moveTo(ripple(x, top), top);
			tv.lineTo(ripple(x, goal.y), goal.y);
			tv.stroke();
		}

		for (let y = top + mesh; y < goal.y; y += mesh) {
			tv.beginPath();
			tv.moveTo(left, ripple(y, left));
			tv.lineTo(left + goal.width, ripple(y, left + goal.width));
			tv.stroke();
		}

		tv.strokeStyle = '#ffffff';
		tv.lineWidth = 4 * scale;
		tv.lineCap = 'square';
		tv.beginPath();
		tv.moveTo(left, goal.y);
		tv.lineTo(left, top);
		tv.lineTo(left + goal.width, top);
		tv.lineTo(left + goal.width, goal.y);
		tv.stroke();
		tv.lineCap = 'butt';
	}

	// The keeper faces the camera. A dive tips him over to one side, with the arms stretched out.
	#drawKeeperFront(x, y, height, kit, {dive = 0, amount = 0, sway = 0} = {}) {
		const tv = this.#tv;
		tv.save();
		tv.translate(x + (sway * height * 0.12) + (dive * amount * height * 0.45), y - (Math.sin(amount * Math.PI * 0.85) * height * 0.25 * Math.abs(dive)));
		tv.rotate(dive * amount * 1.3);
		tv.lineCap = 'round';
		tv.strokeStyle = kit.socks;
		tv.lineWidth = height * 0.1;
		tv.beginPath();
		tv.moveTo(-height * 0.08, -height * 0.45);
		tv.lineTo(-height * 0.16, 0);
		tv.moveTo(height * 0.08, -height * 0.45);
		tv.lineTo(height * 0.16, 0);
		tv.stroke();
		tv.fillStyle = kit.shorts;
		tv.fillRect(-height * 0.15, -height * 0.56, height * 0.3, height * 0.14);
		tv.fillStyle = kit.shirt;
		tv.fillRect(-height * 0.17, -height * 0.86, height * 0.34, height * 0.32);
		tv.strokeStyle = kit.shirt;
		tv.lineWidth = height * 0.08;
		const hands = amount > 0
			? [[-height * 0.14, -height * 1.25], [height * 0.14, -height * 1.25]]
			: [[-height * 0.4, -height * 0.55], [height * 0.4, -height * 0.55]];
		tv.beginPath();
		tv.moveTo(-height * 0.14, -height * 0.82);
		tv.lineTo(...hands[0]);
		tv.moveTo(height * 0.14, -height * 0.82);
		tv.lineTo(...hands[1]);
		tv.stroke();
		tv.fillStyle = kit.gloves ?? '#ffffff';
		for (const [handX, handY] of hands) {
			tv.beginPath();
			tv.arc(handX, handY, height * 0.06, 0, Math.PI * 2);
			tv.fill();
		}

		tv.fillStyle = kit.skin;
		tv.beginPath();
		tv.arc(0, -height * 0.95, height * 0.1, 0, Math.PI * 2);
		tv.fill();
		tv.fillStyle = kit.hair;
		tv.beginPath();
		tv.arc(0, -height * 0.98, height * 0.1, Math.PI, Math.PI * 2);
		tv.fill();
		tv.fillStyle = '#000000';
		tv.fillRect(-height * 0.045, -height * 0.96, height * 0.025, height * 0.025);
		tv.fillRect(height * 0.02, -height * 0.96, height * 0.025, height * 0.025);
		tv.restore();
	}

	// A player seen from behind, near the camera, with the number on the back of the shirt.
	#drawPlayerBack(x, y, height, kit, {number, phase = 0, pose = 'stand', lean = 0} = {}) {
		const tv = this.#tv;
		tv.save();
		tv.translate(x, y);
		tv.rotate(lean);
		tv.lineCap = 'round';
		const swing = pose === 'run' ? Math.sin(phase) * height * 0.12 : 0;
		tv.strokeStyle = kit.socks;
		tv.lineWidth = height * 0.1;
		tv.beginPath();
		tv.moveTo(-height * 0.08, -height * 0.45);
		tv.lineTo((-height * 0.1) + swing, pose === 'kick' ? -height * 0.1 : 0);
		tv.moveTo(height * 0.08, -height * 0.45);
		tv.lineTo(pose === 'kick' ? height * 0.12 : (height * 0.1) - swing, pose === 'kick' ? -height * 0.2 : 0);
		tv.stroke();
		tv.fillStyle = kit.shorts;
		tv.fillRect(-height * 0.15, -height * 0.56, height * 0.3, height * 0.15);
		tv.fillStyle = kit.shirt;
		tv.fillRect(-height * 0.17, -height * 0.86, height * 0.34, height * 0.32);
		tv.strokeStyle = kit.shirt;
		tv.lineWidth = height * 0.08;
		tv.beginPath();
		tv.moveTo(-height * 0.15, -height * 0.82);
		tv.lineTo((-height * 0.24) - swing, -height * 0.58);
		tv.moveTo(height * 0.15, -height * 0.82);
		tv.lineTo((height * 0.24) + swing, -height * 0.58);
		tv.stroke();
		if (number) {
			tv.fillStyle = '#ffffff';
			tv.font = `bold ${Math.round(height * 0.17)}px Arial, sans-serif`;
			tv.textAlign = 'center';
			tv.textBaseline = 'middle';
			tv.fillText(number, 0, -height * 0.7);
		}

		tv.fillStyle = kit.hair;
		tv.beginPath();
		tv.arc(0, -height * 0.95, height * 0.1, 0, Math.PI * 2);
		tv.fill();
		tv.restore();
	}

	#drawShotBall(position) {
		const tv = this.#tv;
		tv.fillStyle = '#ffffff';
		tv.strokeStyle = '#222222';
		tv.lineWidth = 1;
		tv.beginPath();
		tv.arc(position.x, position.y, position.radius, 0, Math.PI * 2);
		tv.fill();
		tv.stroke();
		tv.fillStyle = '#222222';
		tv.beginPath();
		tv.arc(position.x, position.y, position.radius * 0.35, 0, Math.PI * 2);
		tv.fill();
	}

	#drawReticle(goal, aim) {
		const tv = this.#tv;
		const x = goal.x + (aim.u * goal.width / 2);
		const y = goal.y - (aim.v * goal.height);
		tv.save();
		tv.strokeStyle = '#ffff00';
		tv.lineWidth = 2;
		tv.beginPath();
		tv.arc(x, y, 9, 0, Math.PI * 2);
		tv.moveTo(x - 14, y);
		tv.lineTo(x - 4, y);
		tv.moveTo(x + 4, y);
		tv.lineTo(x + 14, y);
		tv.moveTo(x, y - 14);
		tv.lineTo(x, y - 4);
		tv.moveTo(x, y + 4);
		tv.lineTo(x, y + 14);
		tv.stroke();
		tv.restore();
	}

	// A meter on the side of the screen, with the zone in green and the needle.
	#drawMeter(value, zone, label, {x = 400, y = 70, height = 130} = {}) {
		const tv = this.#tv;
		tv.save();
		tv.fillStyle = 'rgb(0 0 0 / 60%)';
		tv.fillRect(x - 4, y - 4, 26, height + 24);
		tv.fillStyle = '#802020';
		tv.fillRect(x, y, 18, height);
		tv.fillStyle = '#30c030';
		tv.fillRect(x, y + ((1 - zone[1]) * height), 18, (zone[1] - zone[0]) * height);
		tv.fillStyle = '#ffff00';
		tv.fillRect(x - 3, y + ((1 - value) * height) - 2, 24, 4);
		tv.font = 'bold 10px Arial, sans-serif';
		tv.textAlign = 'center';
		tv.fillStyle = '#ffffff';
		tv.fillText(label, x + 9, y + height + 14);
		tv.restore();
	}

	// What to do now, at the top of the screen, below the board of the shootout when there is one.
	#drawPrompt(text, english) {
		const tv = this.#tv;
		const top = this.#match.mode === 'shootout' ? 52 : 40;
		tv.save();
		tv.font = '11px Arial, sans-serif';
		const width = Math.max(tv.measureText(english).width, 140) + 20;
		tv.textAlign = 'center';
		tv.fillStyle = 'rgb(0 0 0 / 60%)';
		tv.fillRect(220 - (width / 2), top, width, 34);
		tv.fillStyle = '#ffffff';
		tv.fillText(english, 220, top + 29);
		tv.font = 'bold 15px Arial, sans-serif';
		tv.fillStyle = '#ffff00';
		tv.fillText(text, 220, top + 16);
		tv.restore();
	}

	#drawBallPrompt() {
		this.#drawPrompt('TA NED BALLEN!', this.#isMotion ? 'Kick when the yellow ring is in the green one' : 'Hold Kick and let go when the rings meet, or ▲ ▼ and Kick');
	}

	#drawFlo(current) {
		const tv = this.#tv;
		const {phase, phaseTime} = current;
		if (phase === 'intro') {
			const time = phaseTime;
			const passAmount = progressOf(time, 0.5, 2.3);
			const players = [
				{x: lerp(52, 50, progressOf(time, 0, 0.5)), y: 12, kit: kits.norway, phase: time * 9, pose: time < 0.6 ? 'run' : 'stand'},
				{x: lerp(84, 88, progressOf(time, 0, 2.3)), y: 40, kit: kits.norway, phase: time * 9},
				{x: lerp(86, 89, progressOf(time, 0, 2.3)), y: 42, kit: kits.brazil, phase: time * 9, skin: brazilSkins[2]},
				{x: 101, y: 34, kit: kits.taffarel, pose: 'stand'},
				{x: 70, y: 30, kit: kits.brazil, phase: time * 7, skin: brazilSkins[0]},
			];
			const ball = time < 0.5 ? {x: 50.8, y: 12.4, z: 0} : {x: lerp(50.8, 88, passAmount), y: lerp(12.4, 40, passAmount), z: Math.sin(passAmount * Math.PI) * 12};
			this.#wide.camera = lerp(56, 84, progressOf(time, 0.4, 2.3));
			this.#drawWidePitch(0.5);
			this.#drawWideThings(players, ball);
			// The prompt comes while the long ball is still in the air, so there is time to read it before the ring falls.
			if (time > 1) {
				this.#drawBallPrompt();
			}

			return;
		}

		if (['shot', 'flight', 'result'].includes(phase)) {
			this.#drawFloShot(current);
			return;
		}

		// The first two steps: the long ball comes down to Flo, and Junior Baiano is right behind him.
		const goal = {x: 220, y: 96, width: 140, height: 46};
		this.#drawGoalView(goal, {excitement: 0.5});
		this.#drawKeeperFront(220, 98, 36, kits.taffarel, {sway: this.#isMotion ? Math.sin(this.#roomTime * 3) : 0});
		const floX = phase === 'spin' ? lerp(205, 150, easeOut(phaseTime / 0.7)) : 205;
		const {meter} = current;
		let defenderX = 262;
		if (phase === 'turn') {
			defenderX = 238 + (meter * 40);
		} else if (phase === 'spin') {
			defenderX = 250 + (phaseTime * 30);
		} else if (phase === 'tackled') {
			defenderX = lerp(250, 214, progressOf(phaseTime, 0, 0.4));
		}

		this.#drawKeeperFront(defenderX, 214, 76, defenderKit, {sway: phase === 'tackled' ? -1 : 0});
		const floLean = phase === 'spin' ? Math.sin(phaseTime / 0.7 * Math.PI) * -0.4 : 0;
		this.#drawPlayerBack(floX, 240, 100, kits.norway, {number: '9', lean: floLean});
		if (phase === 'ball' || phase === 'lost') {
			const value = phase === 'lost' ? 1 : meter;
			const shadow = {x: 222, y: 232};
			tv.fillStyle = 'rgb(0 0 0 / 35%)';
			tv.beginPath();
			tv.ellipse(shadow.x, shadow.y, 10, 4, 0, 0, Math.PI * 2);
			tv.fill();
			if (phase === 'ball') {
				const [from, to] = zoneOf(current);
				const ringOf = amount => 8 + ((1 - amount) * 60);
				tv.strokeStyle = 'rgb(60 255 60 / 80%)';
				tv.lineWidth = (ringOf(from) - ringOf(to));
				tv.beginPath();
				tv.ellipse(shadow.x, shadow.y, (ringOf(from) + ringOf(to)) / 2, ((ringOf(from) + ringOf(to)) / 2) * 0.4, 0, 0, Math.PI * 2);
				tv.stroke();
				tv.strokeStyle = '#ffff00';
				tv.lineWidth = 2;
				tv.beginPath();
				tv.ellipse(shadow.x, shadow.y, ringOf(value), ringOf(value) * 0.4, 0, 0, Math.PI * 2);
				tv.stroke();
			}

			const bounce = phase === 'lost' ? phaseTime : 0;
			this.#drawShotBall({x: shadow.x - ((1 - value) * 70) + (bounce * 120), y: shadow.y - 6 - ((1 - value) * 170) - (Math.sin(Math.min(bounce, 1) * Math.PI) * 40), radius: 8});
			if (phase === 'ball') {
				this.#drawBallPrompt();
			}
		} else {
			this.#drawShotBall({x: phase === 'tackled' ? 240 + (phaseTime * 60) : floX + 14, y: 234, radius: 8});
			if (phase === 'turn') {
				const zone = zoneOf(current);
				this.#drawMeter(meter, zone, 'VEND');
				this.#drawPrompt('VEND FORBI HAM!', this.#isMotion ? 'Kick when the needle is in the green' : 'Hold Kick and let go in the green, or ▲ ▼ and Kick');
			}
		}
	}

	#drawFloShot(current) {
		const goal = goalOf('flo');
		const {phase, phaseTime, shot} = current;
		this.#drawGoalView(goal, {excitement: phase === 'result' && shot.result === 'goal' ? 1 : 0.5, netShake: phase === 'result' && shot.result === 'goal' ? Math.max(0, 1 - phaseTime) : 0});
		const diveAmount = phase === 'flight' ? progressOf(phaseTime, 0.1, 0.45) : (phase === 'result' ? 1 : 0);
		this.#drawKeeperFront(220, goal.y + 20, 74, kits.taffarel, {dive: phase === 'shot' ? 0 : current.dive, amount: diveAmount, sway: phase === 'shot' && this.#isMotion ? Math.sin(this.#roomTime * 4) * 0.6 : 0});
		const start = {x: 236, y: 232, radius: 8};
		if (phase === 'shot') {
			this.#drawPlayerBack(212, 254, 96, kits.norway, {number: '9'});
			this.#drawShotBall(start);
			this.#drawReticle(goal, current.aim ?? {u: 0, v: 0.4});
			this.#drawPrompt('SKYT!', this.#isMotion ? 'Kick when the reticle is in a corner' : 'Aim with the arrows, or tap the goal, then Kick');
			return;
		}

		this.#drawPlayerBack(212, 254, 96, kits.norway, {number: '9', pose: 'kick'});
		const amount = phase === 'flight' ? phaseTime / 0.5 : 1;
		this.#drawShotBall(shotBallPosition(goal, start, shot, amount, phase === 'result' ? phaseTime : 0));
		if (phase === 'result') {
			this.#drawResultBanner(shot.result);
		}
	}

	#drawPenaltyFrame(current, {kit = kits.taffarel, number = '10'} = {}) {
		const goal = goalOf('penalty');
		const {phase, phaseTime, shot} = current;
		const isGoal = phase === 'result' && shot?.result === 'goal';
		this.#drawGoalView(goal, {excitement: isGoal ? 1 : 0.2, netShake: isGoal && this.#isMotion ? Math.max(0, 1 - phaseTime) : 0});
		let diveAmount = 0;
		if (phase === 'flight') {
			diveAmount = progressOf(phaseTime, 0, 0.4);
		} else if (phase === 'result') {
			diveAmount = 1;
		}

		const isWaiting = phase === 'setup' || phase === 'aim' || phase === 'power' || phase === 'runup';
		this.#drawKeeperFront(220, goal.y + 2, 64, kit, {dive: isWaiting ? 0 : current.dive, amount: diveAmount, sway: isWaiting && this.#isMotion ? Math.sin(this.#roomTime * 3.5) : 0});
		const spot = {x: 220, y: 228, radius: 7};
		let shooterX = 172;
		let shooterY = 268;
		let pose = 'stand';
		if (phase === 'runup') {
			const amount = progressOf(phaseTime, 0, 0.55);
			shooterX = lerp(150, 200, amount);
			shooterY = lerp(276, 262, amount);
			pose = 'run';
		} else if (phase === 'flight' || phase === 'result') {
			shooterX = 202;
			shooterY = 262;
			pose = phase === 'flight' ? 'kick' : 'stand';
		}

		if (phase === 'flight' || phase === 'result') {
			const amount = phase === 'flight' ? phaseTime / Math.max(0.2, 0.65 - (shot.power * 0.3)) : 1;
			this.#drawShotBall(shotBallPosition(goal, spot, shot, amount, phase === 'result' ? phaseTime : 0));
		} else {
			this.#drawShotBall(spot);
		}

		this.#drawPlayerBack(shooterX, shooterY, 96, kits.norway, {number, pose, phase: phaseTime * 14});
		return goal;
	}

	#drawPenalty(current) {
		const goal = this.#drawPenaltyFrame(current, {number: this.#shootout ? '9' : '10'});
		if (current.phase === 'aim') {
			this.#drawReticle(goal, current.aim);
			this.#drawPrompt('SIKT!', this.#isMotion ? 'Kick when the reticle is where you want to shoot' : 'Aim with the arrows, or tap the goal, then Kick');
		} else if (current.phase === 'power') {
			this.#drawReticle(goal, current.aim);
			this.#drawMeter(current.meter, zoneOf(current), 'KRAFT');
			this.#drawPrompt('KRAFT!', this.#isMotion ? 'Kick when the needle is in the green' : 'Hold Kick and let go in the green, or ▲ ▼ and Kick');
		} else if (current.phase === 'setup' && !this.#shootout) {
			this.#drawLowerThird('STRAFFE: KJETIL REKDAL (10)');
		}

		if (current.phase === 'result') {
			this.#drawResultBanner(current.shot.result);
		}
	}

	#drawResultBanner(result) {
		const tv = this.#tv;
		const texts = {goal: 'MÅL!', saved: 'REDNING!', post: 'STOLPEN!', over: 'OVER!', wide: 'UTENFOR!'};
		tv.save();
		tv.font = '900 34px Impact, "Arial Black", sans-serif';
		tv.textAlign = 'center';
		tv.lineWidth = 5;
		tv.strokeStyle = '#000000';
		tv.strokeText(texts[result], 220, 120);
		tv.fillStyle = result === 'goal' ? '#ffdf00' : '#ffffff';
		tv.fillText(texts[result], 220, 120);
		tv.restore();
	}

	#drawKeeper(current) {
		const goal = goalOf('penalty');
		const {phase, phaseTime, side, height, isMiss} = current;
		const result = phase === 'result' ? current.result : undefined;
		this.#drawGoalView(goal, {excitement: result === 'saved' ? 1 : 0.3, netShake: result === 'goal' && this.#isMotion ? Math.max(0, 1 - phaseTime) : 0});
		const choice = current.choice ?? 0;
		const isDiving = phase === 'flight' || phase === 'result';
		this.#drawKeeperFront(220, goal.y + 2, 64, kits.norwayKeeper, {dive: isDiving ? choice : 0, amount: phase === 'flight' ? phaseTime / 0.4 : (phase === 'result' ? 1 : 0), sway: !isDiving && current.choice !== undefined ? choice * 0.8 : 0});
		// Where the shot goes, as a shot of the shooter, so it travels like one.
		const shot = {u: side * 0.72, v: isMiss ? (height > 0.5 ? 1.25 : 0.3) : height, dive: choice, result: result ?? 'goal'};
		if (isMiss && height <= 0.5) {
			shot.u = Math.sign(side || 1) * 1.3;
		}

		const spot = {x: 220, y: 228, radius: 7};
		const runAmount = phase === 'runup' ? progressOf(phaseTime, 0, 1.7) : (phase === 'setup' ? 0 : 1);
		const tell = phase === 'runup' && phaseTime > 1 ? current.tell * 0.25 : (!this.#isMotion ? current.tell * 0.25 : 0);
		if (isDiving) {
			this.#drawShotBall(shotBallPosition(goal, spot, shot, phase === 'flight' ? phaseTime / 0.4 : 1, phase === 'result' ? phaseTime : 0));
		} else {
			this.#drawShotBall(spot);
		}

		this.#drawPlayerBack(lerp(160, 202, runAmount), lerp(276, 262, runAmount), 96, kits.brazil, {number: String(current.number), pose: phase === 'runup' ? 'run' : 'stand', phase: phaseTime * 12, lean: tell});
		if (!isDiving) {
			const plans = new Map([[-1, 'You will dive left.'], [0, 'You will stay in the middle.'], [1, 'You will dive right.']]);
			this.#drawPrompt('DU STÅR I MÅL!', plans.get(current.choice) ?? '◀ or ▶ to dive, ▼ to stay. Watch how he leans!');
		}

		if (result) {
			this.#drawResultBanner(result);
		}
	}

	#drawItalyShot(current) {
		const goal = goalOf('italyShot');
		const {phase, phaseTime, shot} = current;
		this.#drawGoalView(goal, {excitement: 0.1});
		const diveAmount = phase === 'flight' ? progressOf(phaseTime, 0.05, 0.4) : (phase === 'result' ? 1 : 0);
		this.#drawKeeperFront(220, goal.y + 20, 74, kits.italyKeeper, {dive: phase === 'aim' ? 0 : shot.dive, amount: diveAmount, sway: phase === 'aim' && this.#isMotion ? Math.sin(this.#roomTime * 4) * 0.6 : 0});
		const start = {x: 236, y: 232, radius: 8};
		this.#drawPlayerBack(212, 254, 96, kits.norway, {number: '9', pose: phase === 'aim' ? 'stand' : 'kick'});
		if (phase === 'aim') {
			this.#drawShotBall(start);
			this.#drawReticle(goal, current.aim);
			this.#drawPrompt('SKYT FOR NORGE!', this.#isMotion ? 'Kick to shoot for Norway' : 'Aim with the arrows, or tap the goal, then Kick');
		} else {
			this.#drawShotBall(shotBallPosition(goal, start, shot, phase === 'flight' ? phaseTime / 0.5 : 1, phase === 'result' ? phaseTime : 0));
		}

		if (phase === 'result') {
			this.#drawResultBanner(shot.result);
		}
	}

	#drawReplay(current) {
		const tv = this.#tv;
		const slow = Math.min(1.25, current.time * 0.3);
		const shot = this.#lastGoal.shot;
		const fake = {phase: slow < 1 ? 'flight' : 'result', phaseTime: slow < 1 ? slow * 0.5 : (current.time - 3.33) * 0.4, shot, dive: shot.dive, aim: shot};
		if (this.#lastGoal.view === 'flo') {
			this.#drawFloShot({...fake, phaseTime: slow < 1 ? slow * 0.5 : fake.phaseTime});
		} else {
			const flight = Math.max(0.2, 0.65 - (shot.power * 0.3));
			this.#drawPenaltyFrame({...fake, phaseTime: slow < 1 ? slow * flight : fake.phaseTime}, {number: this.#lastGoal.label.includes('REKDAL') ? '10' : '9'});
		}

		// The replay label, with the spinning star of the broadcasts of the time.
		tv.save();
		tv.fillStyle = 'rgb(0 0 60 / 85%)';
		tv.fillRect(300, 56, 128, 24);
		tv.font = 'bold 14px Arial, sans-serif';
		tv.fillStyle = '#ffffff';
		tv.textBaseline = 'middle';
		tv.fillText('REPRISE', 334, 68.5);
		tv.translate(316, 68);
		tv.rotate(this.#isMotion ? current.time * 3 : 0);
		tv.fillStyle = '#ffdf00';
		tv.beginPath();
		for (let index = 0; index < 10; index++) {
			const radius = index % 2 === 0 ? 9 : 4;
			const angle = (index / 10 * Math.PI * 2) - (Math.PI / 2);
			tv.lineTo(Math.cos(angle) * radius, Math.sin(angle) * radius);
		}

		tv.fill();
		tv.restore();
		this.#drawLowerThird(`⚽ ${this.#lastGoal.label}`);
		if (current.time < 0.4 && this.#isMotion) {
			tv.fillStyle = `rgb(255 255 255 / ${Math.round((1 - (current.time / 0.4)) * 100)}%)`;
			tv.fillRect(0, 0, 440, 264);
		}
	}

	#drawRewind(time) {
		const tv = this.#tv;
		this.#drawAmbient(40 - (time * 6));
		// The tracking noise of a tape that rewinds: torn lines that run down the picture.
		tv.save();
		for (let index = 0; index < 4; index++) {
			const y = ((index * 71) + (time * 220)) % 264;
			tv.drawImage(this.#broadcast, 0, y, 440, 14, (Math.sin(time * 30 + index) * 18), y, 440, 14);
			tv.fillStyle = 'rgb(255 255 255 / 35%)';
			for (let dot = 0; dot < 30; dot++) {
				tv.fillRect(((dot * 53) + (index * 17) + (time * 900)) % 440, y + ((dot * 7) % 14), 6, 1);
			}
		}

		tv.fillStyle = 'rgb(0 0 0 / 25%)';
		tv.fillRect(0, 0, 440, 264);
		tv.font = 'bold 26px "Courier New", monospace';
		tv.fillStyle = '#ffffff';
		tv.textAlign = 'right';
		tv.fillText('◀◀ SPOLER', 420, 44);
		tv.restore();
	}

	#drawCardBackground(top, bottom) {
		const tv = this.#tv;
		const gradient = tv.createLinearGradient(0, 0, 0, 264);
		gradient.addColorStop(0, top);
		gradient.addColorStop(1, bottom);
		tv.fillStyle = gradient;
		tv.fillRect(0, 0, 440, 264);
		// The globe of the World Cup graphics, turning slowly.
		tv.save();
		tv.strokeStyle = 'rgb(255 255 255 / 12%)';
		tv.lineWidth = 2;
		const turn = this.#isMotion ? this.#roomTime * 0.4 : 0;
		for (let index = 0; index < 6; index++) {
			tv.beginPath();
			tv.ellipse(370, 200, Math.abs(Math.cos(turn + (index * Math.PI / 6))) * 90, 90, 0, 0, Math.PI * 2);
			tv.stroke();
		}

		tv.restore();
	}

	#drawCenteredText(text, y, font, color) {
		const tv = this.#tv;
		tv.font = font;
		tv.textAlign = 'center';
		tv.fillStyle = color;
		tv.fillText(text, 220, y);
	}

	#drawTitleCard() {
		const tv = this.#tv;
		this.#drawCardBackground('#001a66', '#0a5a2a');
		tv.save();
		this.#drawCenteredText('FOTBALL-VM 1998 · FRANKRIKE', 44, 'bold 14px Arial, sans-serif', '#ffdf00');
		flag.norway(tv, 74, 70, 72, 52);
		flag.brazil(tv, 294, 70, 72, 52);
		this.#drawCenteredText('–', 106, 'bold 40px Arial, sans-serif', '#ffffff');
		tv.font = '900 22px Impact, "Arial Black", sans-serif';
		tv.textAlign = 'center';
		tv.fillStyle = '#ffffff';
		tv.fillText('NORGE', 110, 146);
		tv.fillText('BRASIL', 330, 146);
		this.#drawCenteredText('Stade Vélodrome, Marseille · tirsdag 23. juni · kl. 21.00', 176, '12px Arial, sans-serif', '#ffffff');
		this.#drawCenteredText('Gruppe A, siste kamp. Brasil er verdensmester.', 194, '12px Arial, sans-serif', '#c0e0ff');
		if (!this.#isMotion || Math.floor(this.#roomTime * 1.5) % 2 === 0) {
			this.#drawCenteredText('Trykk SPARK! for å starte · Press KICK! to start', 228, 'bold 13px Arial, sans-serif', '#ffff40');
		}

		tv.restore();
	}

	#drawFinalScore() {
		const tv = this.#tv;
		this.#drawCardBackground('#5a0000', '#001a66');
		tv.save();
		this.#drawCenteredText('SLUTT · FULL TIME', 40, 'bold 14px Arial, sans-serif', '#ffdf00');
		flag.norway(tv, 60, 62, 60, 44);
		flag.brazil(tv, 320, 62, 60, 44);
		this.#drawCenteredText('2–1', 104, '900 54px Impact, "Arial Black", sans-serif', '#ffffff');
		tv.font = 'bold 12px Arial, sans-serif';
		tv.fillStyle = '#ffffff';
		tv.textAlign = 'center';
		tv.fillText('NORGE', 90, 124);
		tv.fillText('BRASIL', 350, 124);
		tv.font = '11px Arial, sans-serif';
		tv.fillStyle = '#e0e0ff';
		tv.fillText('Flo 83’, Rekdal 89’ (str.)', 90, 142);
		tv.fillText('Bebeto 78’', 350, 142);
		this.#drawCenteredText('NORGE ER VIDERE TIL ÅTTEDELSFINALEN!', 180, 'bold 15px Arial, sans-serif', '#ffff40');
		this.#drawCenteredText('Norway goes through to the round of 16!', 198, '12px Arial, sans-serif', '#ffffff');
		this.#drawCenteredText(this.#match.rewinds > 0 ? `Pappa spolte tilbake ${this.#match.rewinds} ${this.#match.rewinds === 1 ? 'gang' : 'ganger'} · Pappa rewound ${this.#match.rewinds} ${this.#match.rewinds === 1 ? 'time' : 'times'}` : 'Uten å spole tilbake én eneste gang! · Without a single rewind!', 226, '11px Arial, sans-serif', '#c0c0c0');
		tv.restore();
	}

	#drawShootoutCard() {
		this.#drawCardBackground('#001a66', '#3a3a00');
		this.#drawCenteredText('STRAFFESPARKKONKURRANSE', 70, '900 24px Impact, "Arial Black", sans-serif', '#ffdf00');
		this.#drawCenteredText('Penalty shootout in the living room', 92, '12px Arial, sans-serif', '#ffffff');
		this.#drawCenteredText('5 skudd hver · sudden death · Taffarel i mål', 130, 'bold 13px Arial, sans-serif', '#ffffff');
		this.#drawCenteredText('Du skyter for Norge, og står i mål mot Brasil', 150, '12px Arial, sans-serif', '#c0e0ff');
	}

	#drawShootoutEnd(current) {
		const isWon = current.winner === 'norway';
		this.#drawCardBackground(isWon ? '#5a0000' : '#003a10', '#001a66');
		this.#drawShootoutBoard();
		this.#drawCenteredText(isWon ? 'NORGE VINNER!' : 'BRASIL VINNER', 100, '900 34px Impact, "Arial Black", sans-serif', isWon ? '#ffdf00' : '#ffffff');
		this.#drawCenteredText(`${current.score} på straffer · ${current.score} on penalties`, 130, 'bold 14px Arial, sans-serif', '#ffffff');
		this.#drawCenteredText(isWon ? 'Sindre er straffehelten! · Sindre is the penalty hero!' : 'Men vi vant den ekte kampen. · But we won the real match.', 160, '12px Arial, sans-serif', '#ffff40');
		this.#drawCenteredText('Trykk SPARK! for en ny konkurranse · Press KICK! for another one', 210, '11px Arial, sans-serif', '#c0c0c0');
	}

	#drawItalyCard() {
		const tv = this.#tv;
		this.#drawCardBackground('#1a1a3a', '#2a2a2a');
		this.#drawCenteredText('ÅTTEDELSFINALE · ROUND OF 16', 44, 'bold 14px Arial, sans-serif', '#c0c0c0');
		flag.italy(tv, 74, 70, 72, 52);
		flag.norway(tv, 294, 70, 72, 52);
		this.#drawCenteredText('–', 106, 'bold 40px Arial, sans-serif', '#ffffff');
		tv.font = '900 22px Impact, "Arial Black", sans-serif';
		tv.fillStyle = '#ffffff';
		tv.textAlign = 'center';
		tv.fillText('ITALIA', 110, 146);
		tv.fillText('NORGE', 330, 146);
		this.#drawCenteredText('Stade Vélodrome, Marseille · lørdag 27. juni 1998', 178, '12px Arial, sans-serif', '#ffffff');
		this.#drawCenteredText('Fire dager etter Brasil-kampen. Four days after Brazil.', 196, '12px Arial, sans-serif', '#a0a0c0');
	}

	#drawItalyEnd() {
		const tv = this.#tv;
		this.#drawCardBackground('#202030', '#101010');
		this.#drawCenteredText('SLUTT · FULL TIME', 40, 'bold 14px Arial, sans-serif', '#a0a0a0');
		flag.italy(tv, 60, 62, 60, 44);
		flag.norway(tv, 320, 62, 60, 44);
		this.#drawCenteredText('1–0', 104, '900 54px Impact, "Arial Black", sans-serif', '#ffffff');
		this.#drawCenteredText('Vieri 18’', 140, '12px Arial, sans-serif', '#c0c0c0');
		this.#drawCenteredText('Norge er ute av VM.', 176, 'bold 15px Arial, sans-serif', '#ffffff');
		this.#drawCenteredText('Norway is out of the World Cup.', 194, '12px Arial, sans-serif', '#c0c0c0');
		this.#drawCenteredText('Men vi slo Brasil. · But we beat Brazil.', 226, 'bold 13px Arial, sans-serif', '#ffdf00');
	}

	// The living room: the wallpaper, the window with the light summer night of Sankthans, the TV with Rocky on top, the VCR, the carpet, and the family in the sofa, seen from behind.
	#drawRoom() {
		const context = this.#context;
		const isSad = this.#match.mode === 'italy';
		context.fillStyle = '#c9a66b';
		context.fillRect(0, 0, 640, 356);
		context.fillStyle = '#b8935a';
		for (let x = 0; x < 640; x += 24) {
			context.fillRect(x, 0, 9, 356);
		}

		context.fillStyle = '#8a6a3a';
		context.fillRect(0, 346, 640, 10);
		// The carpet, with Pappa’s coffee stains.
		context.fillStyle = '#7a3030';
		context.fillRect(0, 356, 640, 124);
		context.fillStyle = 'rgb(255 220 160 / 10%)';
		for (let x = 0; x < 640; x += 16) {
			context.fillRect(x, 356, 2, 124);
		}

		context.fillStyle = 'rgb(60 30 10 / 70%)';
		for (const [x, y] of stainSpots.slice(0, this.#progress.coffeeStains)) {
			context.beginPath();
			context.ellipse(x, y, 14, 6, 0.2, 0, Math.PI * 2);
			context.fill();
		}

		this.#drawWindow(isSad);
		this.#drawPicture();
		this.#drawTelevision();
		// The family sits in the sofa, so its back hides their bodies.
		this.#drawFamily(isSad);
		this.#drawSofa();
		this.#drawDrops();
		this.#drawWallBang();
		this.#drawBubbles();
	}

	#drawWindow(isSad) {
		const context = this.#context;
		const x = 10;
		const y = 44;
		const width = 72;
		const height = 170;
		const sky = context.createLinearGradient(0, y, 0, y + height);
		sky.addColorStop(0, isSad ? '#4a5060' : '#6a8ac8');
		sky.addColorStop(0.7, isSad ? '#6a7080' : '#f0b080');
		sky.addColorStop(1, isSad ? '#505860' : '#f8d0a0');
		context.fillStyle = sky;
		context.fillRect(x, y, width, height);
		// The mountains of Bergen, and the sea with the Sankthans bonfire on the shore, in the light June night.
		context.fillStyle = isSad ? '#30363a' : '#3a4a5a';
		context.beginPath();
		context.moveTo(x, y + 120);
		context.lineTo(x + 18, y + 92);
		context.lineTo(x + 34, y + 108);
		context.lineTo(x + 52, y + 84);
		context.lineTo(x + width, y + 112);
		context.lineTo(x + width, y + 140);
		context.lineTo(x, y + 140);
		context.fill();
		context.fillStyle = isSad ? '#3a4450' : '#5a7aa0';
		context.fillRect(x, y + 136, width, height - 136);
		if (!isSad) {
			const flicker = this.#isMotion ? Math.sin(this.#roomTime * 17) * 2 : 0;
			context.fillStyle = '#ff9020';
			context.beginPath();
			context.moveTo(x + 44, y + 138);
			context.lineTo(x + 50, y + 122 + flicker);
			context.lineTo(x + 56, y + 138);
			context.fill();
			context.fillStyle = '#ffe060';
			context.beginPath();
			context.moveTo(x + 47, y + 138);
			context.lineTo(x + 50, y + 128 - flicker);
			context.lineTo(x + 53, y + 138);
			context.fill();
		}

		// It rains, of course. In Bergen, it always rains, and after Italy, it pours.
		context.strokeStyle = 'rgb(220 230 255 / 55%)';
		context.lineWidth = 1;
		const drops = isSad ? 26 : 10;
		for (let index = 0; index < drops; index++) {
			const dropX = x + ((index * 29) % width);
			const dropY = y + (((index * 47) + (this.#isMotion ? this.#roomTime * 160 : 0)) % height);
			context.beginPath();
			context.moveTo(dropX, dropY);
			context.lineTo(dropX - 3, dropY + 9);
			context.stroke();
		}

		context.strokeStyle = '#f4f4f0';
		context.lineWidth = 6;
		context.strokeRect(x, y, width, height);
		context.lineWidth = 3;
		context.beginPath();
		context.moveTo(x + (width / 2), y);
		context.lineTo(x + (width / 2), y + height);
		context.moveTo(x, y + (height / 2));
		context.lineTo(x + width, y + (height / 2));
		context.stroke();
	}

	// The picture on the wall to the neighbors, which shakes when they bang on the wall.
	#drawPicture() {
		const context = this.#context;
		context.save();
		const shake = this.#family.wallBang > 0 ? (this.#isMotion ? Math.sin(this.#roomTime * 40) * 0.12 : 0.1) : 0.03;
		context.translate(598, 70);
		context.rotate(shake);
		context.fillStyle = '#d4a020';
		context.fillRect(-30, 0, 60, 74);
		context.fillStyle = '#80b0d0';
		context.fillRect(-24, 6, 48, 62);
		context.fillStyle = '#4a6a4a';
		context.beginPath();
		context.moveTo(-24, 50);
		context.lineTo(-8, 22);
		context.lineTo(6, 40);
		context.lineTo(24, 18);
		context.lineTo(24, 68);
		context.lineTo(-24, 68);
		context.fill();
		context.fillStyle = '#ffffff';
		context.beginPath();
		context.moveTo(-12, 29);
		context.lineTo(-8, 22);
		context.lineTo(-4, 29);
		context.fill();
		context.restore();
	}

	#drawTelevision() {
		const context = this.#context;
		// The TV table with the VCR, where Pappa taped the match.
		context.fillStyle = '#5a3a1a';
		context.fillRect(150, 334, 340, 22);
		context.fillStyle = '#1a1a1a';
		roundedRectangle(context, 230, 336, 180, 16, 2);
		context.fill();
		context.fillStyle = '#30ff60';
		context.font = 'bold 10px "Courier New", monospace';
		context.fillText(this.#match.mode === 'italy' ? '20:47' : '22:43', 380, 348);
		if (!this.#isMotion || Math.floor(this.#roomTime * 1.2) % 2 === 0) {
			context.fillStyle = '#ff2020';
			context.beginPath();
			context.arc(244, 344, 3, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#ffffff';
			context.font = '8px Arial, sans-serif';
			context.fillText('REC', 252, 347);
		}

		// The cabinet of wood, with the knobs and the speaker.
		context.fillStyle = '#6b4423';
		roundedRectangle(context, 84, 20, 472, 316, 18);
		context.fill();
		context.strokeStyle = '#3a2410';
		context.lineWidth = 3;
		context.stroke();
		context.fillStyle = '#202020';
		roundedRectangle(context, screenArea.x - 10, screenArea.y - 10, screenArea.width + 20, screenArea.height + 20, 22);
		context.fill();
		context.fillStyle = '#4a2e14';
		context.fillRect(96, 306, 448, 24);
		context.strokeStyle = '#2a1a0a';
		context.lineWidth = 1;
		for (let x = 104; x < 300; x += 6) {
			context.beginPath();
			context.moveTo(x, 310);
			context.lineTo(x, 326);
			context.stroke();
		}

		context.fillStyle = '#d0c090';
		context.font = 'bold 9px Arial, sans-serif';
		context.fillText('FJORDVISJON 28"', 320, 322);
		for (const knobX of [470, 500]) {
			context.fillStyle = '#c0c0c0';
			context.beginPath();
			context.arc(knobX, 318, 8, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#606060';
			context.fillRect(knobX - 1, 311, 2, 7);
		}

		context.fillStyle = '#30ff30';
		context.fillRect(524, 316, 6, 4);

		// The picture, with the curve of the glass, its scanlines, and a glare.
		context.save();
		roundedRectangle(context, screenArea.x, screenArea.y, screenArea.width, screenArea.height, 16);
		context.clip();
		context.drawImage(this.#broadcast, screenArea.x, screenArea.y);
		context.fillStyle = 'rgb(0 0 0 / 14%)';
		for (let y = screenArea.y; y < screenArea.y + screenArea.height; y += 3) {
			context.fillRect(screenArea.x, y, screenArea.width, 1);
		}

		const glare = context.createRadialGradient(screenArea.x + 110, screenArea.y + 50, 10, screenArea.x + 110, screenArea.y + 50, 260);
		glare.addColorStop(0, 'rgb(255 255 255 / 12%)');
		glare.addColorStop(1, 'rgb(255 255 255 / 0%)');
		context.fillStyle = glare;
		context.fillRect(screenArea.x, screenArea.y, screenArea.width, screenArea.height);
		const vignette = context.createRadialGradient(320, 164, 150, 320, 164, 300);
		vignette.addColorStop(0, 'rgb(0 0 0 / 0%)');
		vignette.addColorStop(1, 'rgb(0 0 0 / 40%)');
		context.fillStyle = vignette;
		context.fillRect(screenArea.x, screenArea.y, screenArea.width, screenArea.height);
		context.restore();

		this.#drawRocky();
	}

	// Rocky, my pet rock, watches from the top of the TV with a tiny flag.
	#drawRocky() {
		const context = this.#context;
		context.fillStyle = '#8a8a8a';
		context.beginPath();
		context.ellipse(486, 12, 18, 10, 0, 0, Math.PI * 2);
		context.fill();
		context.fillStyle = '#ffffff';
		for (const eyeX of [480, 492]) {
			context.beginPath();
			context.arc(eyeX, 9, 4, 0, Math.PI * 2);
			context.fill();
		}

		context.fillStyle = '#000000';
		const look = this.#isMotion ? Math.sin(this.#roomTime) * 1.5 : 0;
		for (const eyeX of [480, 492]) {
			context.beginPath();
			context.arc(eyeX + look, 10, 1.8, 0, Math.PI * 2);
			context.fill();
		}

		context.strokeStyle = '#3a2a1a';
		context.lineWidth = 1.5;
		context.beginPath();
		context.moveTo(502, 18);
		context.lineTo(512, -2);
		context.stroke();
		context.fillStyle = '#ba0c2f';
		context.fillRect(512, -2, 16, 11);
		context.fillStyle = '#ffffff';
		context.fillRect(516, -2, 3, 11);
		context.fillRect(512, 2, 16, 3);
		context.fillStyle = '#00205b';
		context.fillRect(517, -2, 1.5, 11);
		context.fillRect(512, 3, 16, 1.5);
	}

	#drawSofa() {
		const context = this.#context;
		context.fillStyle = '#2f5a3a';
		roundedRectangle(context, 96, 418, 448, 80, 14);
		context.fill();
		context.fillStyle = '#3d6b4a';
		roundedRectangle(context, 112, 420, 416, 70, 10);
		context.fill();
		context.strokeStyle = '#2a4a32';
		context.lineWidth = 2;
		for (const x of [216, 320, 424]) {
			context.beginPath();
			context.moveTo(x, 424);
			context.lineTo(x, 480);
			context.stroke();
		}
	}

	// The family from behind. A head turns around when its person talks or cheers.
	#drawHead(x, y, radius, {hair, skin, isTurned = false, bald = false, bun = false, glasses = false, paint = false, pigtails = false, isSleeping = false}) {
		const context = this.#context;
		if (isTurned) {
			context.fillStyle = skin;
			context.beginPath();
			context.arc(x, y, radius, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = hair;
			context.beginPath();
			context.arc(x, y - (radius * 0.2), radius, Math.PI * 1.05, Math.PI * 1.95);
			context.fill();
			context.fillStyle = '#000000';
			context.beginPath();
			context.arc(x - (radius * 0.35), y + (radius * 0.05), radius * 0.1, 0, Math.PI * 2);
			context.arc(x + (radius * 0.35), y + (radius * 0.05), radius * 0.1, 0, Math.PI * 2);
			context.fill();
			if (glasses) {
				context.strokeStyle = '#303030';
				context.lineWidth = 1.5;
				context.beginPath();
				context.arc(x - (radius * 0.35), y + (radius * 0.05), radius * 0.25, 0, Math.PI * 2);
				context.moveTo(x + (radius * 0.6), y + (radius * 0.05));
				context.arc(x + (radius * 0.35), y + (radius * 0.05), radius * 0.25, 0, Math.PI * 2);
				context.stroke();
			}

			if (paint) {
				for (const side of [-1, 1]) {
					const paintX = x + (side * radius * 0.55) - (radius * 0.18);
					const paintY = y + (radius * 0.3);
					context.fillStyle = '#ba0c2f';
					context.fillRect(paintX, paintY, radius * 0.36, radius * 0.26);
					context.fillStyle = '#ffffff';
					context.fillRect(paintX + (radius * 0.1), paintY, radius * 0.08, radius * 0.26);
					context.fillRect(paintX, paintY + (radius * 0.09), radius * 0.36, radius * 0.08);
				}
			}

			context.strokeStyle = '#601010';
			context.lineWidth = 2;
			context.beginPath();
			context.arc(x, y + (radius * 0.35), radius * 0.3, 0.1 * Math.PI, 0.9 * Math.PI);
			context.stroke();
			return;
		}

		context.fillStyle = skin;
		context.beginPath();
		context.arc(x - radius, y + 2, radius * 0.22, 0, Math.PI * 2);
		context.arc(x + radius, y + 2, radius * 0.22, 0, Math.PI * 2);
		context.fill();
		context.fillStyle = hair;
		context.beginPath();
		context.arc(x, y, radius, 0, Math.PI * 2);
		context.fill();
		if (bald) {
			context.fillStyle = skin;
			context.beginPath();
			context.ellipse(x, y - (radius * 0.45), radius * 0.4, radius * 0.3, 0, 0, Math.PI * 2);
			context.fill();
		}

		if (bun) {
			context.fillStyle = hair;
			context.beginPath();
			context.arc(x, y - radius, radius * 0.45, 0, Math.PI * 2);
			context.fill();
		}

		if (pigtails) {
			context.fillStyle = hair;
			context.beginPath();
			context.arc(x - radius, y + (radius * 0.4), radius * 0.35, 0, Math.PI * 2);
			context.arc(x + radius, y + (radius * 0.4), radius * 0.35, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#ff60a0';
			context.fillRect(x - radius - 3, y + (radius * 0.05), 6, 4);
			context.fillRect(x + radius - 3, y + (radius * 0.05), 6, 4);
		}

		if (isSleeping) {
			context.fillStyle = '#203080';
			context.font = 'bold 14px "Comic Sans MS", "Comic Sans", cursive';
			const rise = this.#isMotion ? (this.#roomTime * 12) % 24 : 8;
			context.fillText('z', x + radius, y - radius - rise * 0.5);
			context.font = 'bold 18px "Comic Sans MS", "Comic Sans", cursive';
			context.fillText('Z', x + radius + 10, y - radius - 10 - rise);
		}
	}

	#drawShoulders(x, y, width, color) {
		const context = this.#context;
		context.fillStyle = color;
		roundedRectangle(context, x - (width / 2), y, width, 70, [18, 18, 0, 0]);
		context.fill();
	}

	#drawFamily(isSad) {
		const context = this.#context;
		const pappa = this.#family.pappa;
		const jumpAmount = pappa.jump > 0 ? (this.#isMotion ? Math.sin((1 - pappa.jump) * Math.PI) : 1) : 0;
		const pappaLift = jumpAmount * 40;
		const isSlumped = pappa.slump > 0 || isSad;
		const pappaY = 350 - pappaLift + (isSlumped ? 8 : 0);

		// Mormor, with her knitting.
		const isMormorTurned = this.#family.mormor.turn > 0;
		this.#drawShoulders(people.mormor.x, 372, 74, '#7a4a8a');
		context.strokeStyle = '#d0d0d0';
		context.lineWidth = 2;
		context.beginPath();
		context.moveTo(people.mormor.x + 30, 400);
		context.lineTo(people.mormor.x + 48, 378);
		context.moveTo(people.mormor.x + 34, 404);
		context.lineTo(people.mormor.x + 54, 386);
		context.stroke();
		context.fillStyle = '#d02030';
		context.beginPath();
		context.arc(people.mormor.x + 38, 404, 7, 0, Math.PI * 2);
		context.fill();
		this.#drawHead(people.mormor.x, 350, 21, {hair: '#d8d8d8', skin: '#f0d0b8', isTurned: isMormorTurned, bun: !isMormorTurned, glasses: true});

		// Pappa, with his coffee. When he jumps, his arms go up, and so does the coffee.
		this.#drawShoulders(people.pappa.x, pappaY + 22, 84, '#3a5a8a');
		context.strokeStyle = '#3a5a8a';
		context.lineWidth = 12;
		context.lineCap = 'round';
		context.beginPath();
		if (jumpAmount > 0.2) {
			context.moveTo(people.pappa.x - 34, pappaY + 30);
			context.lineTo(people.pappa.x - 50, pappaY - 22);
			context.moveTo(people.pappa.x + 34, pappaY + 30);
			context.lineTo(people.pappa.x + 50, pappaY - 22);
		} else {
			context.moveTo(people.pappa.x + 36, pappaY + 34);
			context.lineTo(people.pappa.x + 50, pappaY + 6);
		}

		context.stroke();
		context.lineCap = 'butt';
		const cup = jumpAmount > 0.2 ? {x: people.pappa.x + 52, y: pappaY - 30, tilt: 1.2} : {x: people.pappa.x + 50, y: pappaY - 2, tilt: 0};
		context.save();
		context.translate(cup.x, cup.y);
		context.rotate(cup.tilt);
		context.fillStyle = '#ffffff';
		context.fillRect(-7, -8, 14, 14);
		context.strokeStyle = '#ffffff';
		context.lineWidth = 2;
		context.beginPath();
		context.arc(9, -1, 4, -Math.PI / 2, Math.PI / 2);
		context.stroke();
		context.restore();
		if (!jumpAmount && !isSad && this.#isMotion) {
			context.strokeStyle = 'rgb(255 255 255 / 50%)';
			context.lineWidth = 1.5;
			for (const offset of [-3, 3]) {
				context.beginPath();
				context.moveTo(cup.x + offset, cup.y - 10);
				context.quadraticCurveTo(cup.x + offset + (Math.sin(this.#roomTime * 3 + offset) * 4), cup.y - 18, cup.x + offset, cup.y - 26);
				context.stroke();
			}
		}

		this.#drawHead(people.pappa.x, pappaY, 24, {hair: '#6a4a2a', skin: '#f0c8a0', bald: true});

		// Me, in my Norway shirt if I put it on, with my name on the back.
		const sindre = this.#family.sindre;
		const isCheering = sindre.cheer > 0;
		const sindreY = isCheering ? 340 - (this.#isMotion ? Math.abs(Math.sin(sindre.cheer * 6)) * 10 : 6) : 354;
		const {outfit} = this.#progress;
		this.#drawShoulders(people.sindre.x, sindreY + 20, 66, outfit.shirt ? '#d40000' : '#7a8aa0');
		if (isCheering) {
			context.strokeStyle = outfit.shirt ? '#d40000' : '#7a8aa0';
			context.lineWidth = 10;
			context.lineCap = 'round';
			context.beginPath();
			context.moveTo(people.sindre.x - 26, sindreY + 28);
			context.lineTo(people.sindre.x - 40, sindreY - 18);
			context.moveTo(people.sindre.x + 26, sindreY + 28);
			context.lineTo(people.sindre.x + 40, sindreY - 18);
			context.stroke();
			context.lineCap = 'butt';
		}

		if (outfit.shirt) {
			context.fillStyle = '#ffffff';
			context.textAlign = 'center';
			context.font = 'bold 9px Arial, sans-serif';
			context.fillText('SINDRE', people.sindre.x, sindreY + 36);
			context.font = 'bold 22px Arial, sans-serif';
			context.fillText('9', people.sindre.x, sindreY + 58);
			context.textAlign = 'start';
		}

		if (outfit.scarf) {
			const stripes = ['#ba0c2f', '#ffffff', '#00205b', '#ffffff'];
			for (let index = 0; index < 8; index++) {
				context.fillStyle = stripes[index % stripes.length];
				context.fillRect(people.sindre.x - 22 + (index * 5.5), sindreY + 16, 5.5, 8);
				context.fillRect(people.sindre.x + 8, sindreY + 22 + (index * 5), 10, 5);
			}
		}

		this.#drawHead(people.sindre.x, sindreY, 20, {hair: '#e8c868', skin: '#f4d0b0', isTurned: isCheering || sindre.turn > 0, paint: outfit.paint});
		if (outfit.helmet) {
			context.fillStyle = '#a8a8b0';
			context.beginPath();
			context.arc(people.sindre.x, sindreY - 4, 21, Math.PI, Math.PI * 2);
			context.fill();
			context.fillStyle = '#707078';
			context.fillRect(people.sindre.x - 22, sindreY - 6, 44, 5);
			context.fillStyle = '#f4f0e0';
			for (const side of [-1, 1]) {
				context.beginPath();
				context.moveTo(people.sindre.x + (side * 18), sindreY - 12);
				context.quadraticCurveTo(people.sindre.x + (side * 36), sindreY - 18, people.sindre.x + (side * 34), sindreY - 40);
				context.quadraticCurveTo(people.sindre.x + (side * 28), sindreY - 22, people.sindre.x + (side * 14), sindreY - 18);
				context.fill();
			}
		}

		// Lillesøster, asleep on my shoulder in her pink pajamas, through all of it.
		context.save();
		context.translate(people.sister.x, 372);
		context.rotate(-0.35);
		this.#drawShoulders(0, 6, 50, '#ff9ac8');
		context.restore();
		this.#drawHead(people.sister.x - 8, 362, 16, {hair: '#c8a050', skin: '#f8d8c0', pigtails: true, isSleeping: true});
	}

	#drawDrops() {
		const context = this.#context;
		context.fillStyle = '#5a3010';
		for (const drop of this.#drops) {
			context.beginPath();
			context.arc(drop.x, drop.y, 3, 0, Math.PI * 2);
			context.fill();
		}
	}

	#drawWallBang() {
		const context = this.#context;
		if (this.#family.wallBang <= 0) {
			return;
		}

		context.save();
		context.font = '900 22px Impact, "Arial Black", sans-serif';
		context.fillStyle = '#ffffff';
		context.strokeStyle = '#000000';
		context.lineWidth = 4;
		context.textAlign = 'center';
		const words = [['DUNK!', 600, 196, -0.2], ['DUNK!', 604, 250, 0.15]];
		for (const [index, [word, x, y, angle]] of words.entries()) {
			// The second bang comes a moment after the first one.
			if (!this.#isMotion || 1.6 - this.#family.wallBang > index * 0.3) {
				context.save();
				context.translate(x, y);
				context.rotate(angle);
				context.strokeText(word, 0, 0);
				context.fillText(word, 0, 0);
				context.restore();
			}
		}

		context.restore();
	}

	#drawBubbles() {
		const context = this.#context;
		context.save();
		context.font = 'bold 13px "Comic Sans MS", "Comic Sans", cursive';
		context.textBaseline = 'top';
		for (const [who, bubble] of this.#bubbles) {
			const person = people[who];
			const lines = wrapText(context, bubble.text, 170);
			const width = Math.max(...lines.map(line => context.measureText(line).width)) + 16;
			const height = (lines.length * 16) + 10;
			const x = clamp(person.x - (width / 2), 4, 636 - width);
			const y = who === 'neighbors' ? 140 : 318 - height;
			context.fillStyle = '#ffffff';
			context.strokeStyle = '#000000';
			context.lineWidth = 2;
			roundedRectangle(context, x, y, width, height, 10);
			context.fill();
			context.stroke();
			context.beginPath();
			const tailX = clamp(person.x, x + 12, x + width - 12);
			context.moveTo(tailX - 6, y + height - 1);
			context.lineTo(tailX, y + height + 10);
			context.lineTo(tailX + 6, y + height - 1);
			context.fill();
			context.fillStyle = '#000000';
			for (const [index, line] of lines.entries()) {
				context.fillText(line, x + 8, y + 6 + (index * 16));
			}
		}

		context.restore();
	}

	#updateEffects(seconds) {
		this.#roomTime += seconds;
		for (const [who, bubble] of this.#bubbles) {
			bubble.life -= seconds;
			if (bubble.life <= 0) {
				this.#bubbles.delete(who);
			}
		}

		if (this.#subtitle) {
			this.#subtitle.life -= seconds;
			if (this.#subtitle.life <= 0) {
				this.#subtitle = undefined;
			}
		}

		this.#family.pappa.jump = Math.max(0, this.#family.pappa.jump - seconds);
		this.#family.pappa.slump = Math.max(0, this.#family.pappa.slump - seconds);
		this.#family.mormor.turn = Math.max(0, this.#family.mormor.turn - seconds);
		this.#family.sindre.cheer = Math.max(0, this.#family.sindre.cheer - seconds);
		this.#family.sindre.turn = Math.max(0, this.#family.sindre.turn - seconds);
		this.#family.wallBang = Math.max(0, this.#family.wallBang - seconds);
		for (const drop of this.#drops) {
			drop.velocityY += 500 * seconds;
			drop.x += drop.velocityX * seconds;
			drop.y += drop.velocityY * seconds;
			drop.life -= seconds;
		}

		for (let index = this.#drops.length - 1; index >= 0; index--) {
			if (this.#drops[index].y > 380 || this.#drops[index].life <= 0) {
				this.#drops.splice(index, 1);
			}
		}
	}

	#draw() {
		const tv = this.#tv;
		tv.save();
		this.#typeOf().draw(this.#scene);
		tv.restore();
		if (!cardScenes.has(this.#scene.kind)) {
			this.#drawScoreBug();
		}

		this.#drawSubtitle();
		this.#drawContinueHint();
		this.#drawRoom();
	}

	get #shouldRun() {
		return this.#isMotion || this.#isHolding;
	}

	// Draws once in the next frame, unless the loop draws it: a running loop draws in its next step, or when it stops.
	#requestDraw() {
		if (this.#isDrawQueued || this.#loop.isRunning) {
			return;
		}

		this.#isDrawQueued = true;
		requestAnimationFrame(() => {
			this.#isDrawQueued = false;
			this.#draw();
		});
	}

	// The newspaper of the next morning, with the photo of the goal from the TV, printed in dots.
	#saveMatch() {
		this.#progress.lastMatch = {
			rewinds: this.#match.rewinds,
			floTries: this.#match.floTries,
			penaltyTries: this.#match.penaltyTries,
			penaltyShot: this.#match.penaltyShot,
			shirt: this.#progress.outfit.shirt,
		};
		this.#persist();
		if (this.#paperIsShown) {
			this.#fillPaper();
		}

		this.#updateButtons();
	}

	#printPhoto(shot) {
		// Draws the moment of the goal on the broadcast, and prints it with dots, like the photos of a newspaper.
		const tv = this.#tv;
		const {photo} = this.parts;
		tv.save();
		this.#drawPenaltyFrame({phase: 'result', phaseTime: 0.6, shot, dive: shot.dive}, {number: '10'});
		tv.restore();
		const photoContext = photo.getContext('2d', {willReadFrequently: true});
		photoContext.drawImage(this.#broadcast, 40, 20, 360, 216, 0, 0, photo.width, photo.height);
		const pixels = photoContext.getImageData(0, 0, photo.width, photo.height).data;
		photoContext.fillStyle = '#f3eedf';
		photoContext.fillRect(0, 0, photo.width, photo.height);
		photoContext.fillStyle = '#111111';
		const cell = 4;
		for (let y = 0; y < photo.height; y += cell) {
			for (let x = 0; x < photo.width; x += cell) {
				const index = ((y * photo.width) + x) * 4;
				const brightness = ((pixels[index] * 0.3) + (pixels[index + 1] * 0.59) + (pixels[index + 2] * 0.11)) / 255;
				const radius = (1 - brightness) * cell * 0.62;
				if (radius > 0.3) {
					photoContext.beginPath();
					photoContext.arc(x + (cell / 2), y + (cell / 2), radius, 0, Math.PI * 2);
					photoContext.fill();
				}
			}
		}

		this.#requestDraw();
	}

	#fillPaper() {
		const record = this.#progress.lastMatch;
		const shot = Number.isFinite(record.penaltyShot?.u) && Number.isFinite(record.penaltyShot?.v) ? record.penaltyShot : {u: -0.7, v: 0.2, dive: 1, power: 0.7, result: 'goal'};
		const placement = placementOf(shot);
		const likeRekdal = isLikeRekdal(shot);
		const {headline, subhead, photoCaption, story, quotes, translation} = this.parts;
		headline.textContent = record.rewinds === 0 ? 'Norge slo Brasil!' : 'Norge slo Brasil! (Til slutt)';
		subhead.textContent = `Flo utlignet i det 83. minutt${record.floTries > 1 ? ` (på ${record.floTries}. forsøk)` : ''}, og Rekdal satte straffen ${placement.norwegian}${likeRekdal ? ', akkurat som i virkeligheten' : ''}. VM-sjokk i Marseille!`;
		photoCaption.textContent = 'JUBEL I STUA: Slik så straffen ut på TV-en i en stue i Bergen i går kveld. Foto: Pappa (med kaffeflekk)';
		const stains = this.#progress.coffeeStains;
		story.textContent = `MARSEILLE/BERGEN: Det var sankthansaften, det regnet, og hele Norge satt foran TV-en. Brasil ledet 1–0 etter Bebetos heading i det 78. minutt, og Marokko slo Skottland. Norge måtte vinne. Så kom Tore André Flo, og så kom Kjetil Rekdal fra krittmerket. Taffarel, straffespesialisten, var sjanseløs. ${record.rewinds > 0 ? `I en stue i Bergen måtte Pappa spole tilbake videoen ${record.rewinds} ${record.rewinds === 1 ? 'gang' : 'ganger'}, men det teller ikke.` : 'I en stue i Bergen trengte ingen å spole tilbake videoen en eneste gang.'} Norge møter Italia i åttedelsfinalen på lørdag.`;
		quotes.replaceChildren(...[
			`Pappa: – Jeg sølte kaffe på teppet. ${stains > 1 ? `Det er ${stains} flekker nå.` : 'Det var verdt det.'}`,
			'Mormor: – Det sto BRA på TV-en, men det var visst ikke bra for dem.',
			'Lillesøster: – Zzz.',
			'Naboen: – Vi banket i veggen. Av glede.',
			record.shirt ? 'Sindre: – Jeg hadde på meg Norge-drakta, så det var derfor.' : 'Sindre: – Neste gang tar jeg på meg Norge-drakta.',
			...(this.#progress.shootout ? [`Sindre: – Etterpå tok vi straffekonkurranse i stua. ${this.#progress.shootout.isWon ? `Jeg vant ${this.#progress.shootout.score}!` : `Taffarel vant ${this.#progress.shootout.score}, men det var bare på lek.`}`] : []),
		].map(text => {
			const item = document.createElement('li');
			item.textContent = text;
			return item;
		}));
		translation.textContent = `In English: “Norway beat Brazil!” Flo equalized in the 83rd minute${record.floTries > 1 ? ` (on try ${record.floTries})` : ''}, and Rekdal put the penalty ${placement.english}${likeRekdal ? ', just like in reality' : ''}. It was Midsummer Eve, it rained, and all of Norway sat in front of the TV. Brazil led 1–0 after Bebeto’s header, and Morocco beat Scotland, so Norway had to win. ${record.rewinds > 0 ? `In a living room in Bergen, Pappa had to rewind the tape ${record.rewinds} ${record.rewinds === 1 ? 'time' : 'times'}, but that does not count.` : 'Nobody had to rewind the tape.'} The quotes: Pappa spilled coffee on the carpet, Mormor saw “BRA” on the TV (“bra” means “good”), Lillesøster slept, and the neighbors banged on the wall, out of joy.`;
		this.#printPhoto(shot);
	}

	#togglePaper() {
		if (!this.#progress.lastMatch) {
			return;
		}

		const {newspaper} = this.parts;
		this.#paperIsShown = !this.#paperIsShown;
		newspaper.hidden = !this.#paperIsShown;
		if (this.#paperIsShown) {
			this.#fillPaper();
			newspaper.scrollIntoView({behavior: this.#isMotion ? 'smooth' : 'auto', block: 'nearest'});
			this.say('The paper of the next morning lies on the kitchen table. Read it below the album.');
		}

		this.#updateButtons();
	}

	// The stickers of the album, drawn like the Panini stickers of 1998.
	#drawStickers() {
		let count = 0;
		for (const [identifier, sticker] of this.#stickerCanvases) {
			const state = this.#progress.stickers[identifier];
			const figure = sticker.closest('figure');
			figure.dataset.state = state === 'shiny' ? 'shiny' : (state ? 'earned' : '');
			figure.querySelector('figcaption').textContent = state ? (state === 'shiny' ? 'Got it! Shiny, on the first try.' : 'Got it!') : this.#stickerHints.get(identifier);
			if (state) {
				count++;
			}

			drawSticker(sticker.getContext('2d'), stickerInfo[identifier], state);
		}

		this.parts.albumCount.textContent = String(count);
	}

	// The buttons.
	// A title, an end, or a stretch of the tape only needs a tap, so a finger can still scroll the page over the TV.
	#isTapScene() {
		return Boolean(this.#typeOf().isResting || this.#typeOf().events);
	}

	#updateButtons() {
		const type = this.#typeOf();
		this.parts.canvas.dataset.state = this.#isTapScene() ? '' : 'play';
		const isDive = Boolean(type.acceptsDive?.(this.#scene));
		const isMeter = Boolean(type.acceptsMeter?.(this.#scene));
		const acceptsArrows = isDive || isMeter || Boolean(type.acceptsAim?.(this.#scene));
		for (const action of ['left', 'up', 'down', 'right']) {
			this.#buttons.get(action).disabled = !acceptsArrows || (isDive && action === 'up') || (isMeter && (action === 'left' || action === 'right'));
		}

		setPressed(this.#buttons.get('sound'), this.#isSoundOn);
		this.#buttons.get('sound').textContent = this.#isSoundOn ? 'Sound: On' : 'Sound: Off';
		setPressed(this.#buttons.get('chant'), this.#isChanting);
		this.#buttons.get('chant').textContent = this.#isChanting ? 'Stop the Chant' : 'Start the “Olé, Olé, Olé”';
		this.#buttons.get('replay').disabled = !this.#lastGoal || !type.isResting;
		this.#buttons.get('paper').disabled = !this.#progress.lastMatch;
		setPressed(this.#buttons.get('paper'), this.#paperIsShown);
		this.#buttons.get('paper').textContent = this.#paperIsShown ? 'Put Away the Paper' : 'Read Tomorrow’s Paper';
		for (const piece of ['shirt', 'scarf', 'paint', 'helmet']) {
			setPressed(this.#buttons.get(piece), this.#progress.outfit[piece]);
		}

		this.#buttons.get('shirt').textContent = this.#progress.outfit.shirt ? 'Take Off the Norway Shirt' : 'Put On the Norway Shirt';
	}

	#toggleOutfit(piece) {
		this.#progress.outfit[piece] = !this.#progress.outfit[piece];
		this.#persist();
		if (this.#progress.outfit[piece]) {
			this.#family.sindre.turn = 2.4;
			this.#talk('sindre', ...outfitLines[piece], {seconds: 2.4});
		}

		this.#updateButtons();
		this.#requestDraw();
	}

	#toggleSound() {
		this.#isSoundOn = !this.#isSoundOn && this.#audio.start(this.sound());
		if (this.#isSoundOn) {
			this.#audio.context.resume().then(() => {
				if (this.#isSoundOn && this.isVisible) {
					this.#audio.startCrowd();
				}
			}, () => {});
			this.say('The sound is on: the crowd of Marseille, the whistle, and Kåre Brøl on the TV.');
		} else {
			this.#audio.stopCrowd();
			if (canSpeak) {
				speechSynthesis.cancel();
			}
		}

		this.#updateButtons();
	}
}
