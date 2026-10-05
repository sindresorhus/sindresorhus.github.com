// Insult Seagull Fighting on the 1999 page, an extra of the adventure games, like the insult sword fighting of The Secret of Monkey Island: whoever is insulted must answer with the comeback that fits, or lose the round. Sindre learns each insult that a seagull uses on him, and each comeback that a seagull answers him with. The Sea Gull Master has insults of her own, which fit the same comebacks, so only a visitor who understands the comebacks can beat her. What Sindre learned is kept in the browser. It makes its sounds when the sound button of Sindre’s Quest is on, which tells it with the `geocities-adventure-sound` event.
const nextFrame = () => new Promise(resolve => {
	requestAnimationFrame(() => {
		resolve();
	});
});

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Shapes for the canvas of the fight.
const fillShape = (context, color, x, y, width, height) => {
	context.fillStyle = color;
	context.fillRect(Math.round(x), Math.round(y), Math.round(width), Math.round(height));
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

// The colors of the pixel art, by the letter that the sprites use for them, a palette like the 256 colors of VGA.
const palette = {
	k: '#000000',
	w: '#ffffff',
	s: '#f4c49c',
	S: '#d8956a',
	h: '#f2d16b',
	H: '#c99a36',
	b: '#2a5bd7',
	B: '#1b3a8a',
	j: '#ffd400',
	J: '#c9a400',
	r: '#d42a2a',
	R: '#8a1414',
	g: '#3fa34d',
	G: '#1f5c2a',
	n: '#8b5a2b',
	N: '#5a3519',
	e: '#8a8a8a',
	E: '#4a4a4a',
	l: '#c8c8c8',
	o: '#ff8c1a',
	p: '#ff8fc8',
	P: '#7a3fb0',
	y: '#ffd700',
	Y: '#b8860b',
	c: '#7fd4ff',
	t: '#8fa86a',
	T: '#5d7a45',
	m: '#b07a3a',
	u: '#9a9aa8',
	U: '#5c5c6a',
};

// Draws a sprite of letters, one letter a pixel and a dot for nothing, at a scale, with its feet at `y`, facing right, or left when it is flipped. The colors can be swapped, like the shirt of Sindre for his rain jacket.
const drawSprite = (context, rows, x, y, {scale = 2, isFlipped = false, colors = {}} = {}) => {
	const width = rows[0].length;
	const top = Math.round(y - (rows.length * scale));
	const left = Math.round(x - (width * scale / 2));
	for (const [row, line] of rows.entries()) {
		for (let column = 0; column < width; column++) {
			const letter = line[isFlipped ? width - 1 - column : column];
			if (letter === '.') {
				continue;
			}

			context.fillStyle = colors[letter] ?? palette[letter];
			context.fillRect(left + (column * scale), top + (row * scale), scale, scale);
		}
	}
};

// Sindre and the seagull, as sprites that face right.
const sprites = {
	sindre: [
		'...hhh...',
		'..hhhhhh.',
		'.hhhhhhh.',
		'.hhsssss.',
		'.hsssksk.',
		'.hsssssss',
		'..sssSss.',
		'...ssss..',
		'..bbbbb..',
		'.bbbbbbb.',
		'.bbbbbbb.',
		'sbbbbbbbs',
		's.bbbbb.s',
		'..bbbbb..',
		'..BBBBB..',
		'..BB.BB..',
		'..BB.BB..',
		'..BB.BB..',
		'..kkk.kkk',
	],
	seagull: [
		'..www.....',
		'.wwkww....',
		'oowwww....',
		'..wwwwwwll',
		'..wwwwwlll',
		'...wwwwll.',
		'....o.o...',
	],
};

export default class extends GeoCitiesElement {
	#isSoundOn = false;
	#draw;

	connected() {
		// The sound button of Sindre’s Quest turns the sound on and off for all the adventure games of the page.
		this.on(document, 'geocities-adventure-sound', event => {
			this.#isSoundOn = event.detail.isOn;
		});

		const {canvas, tally, line, start: startButton, master: masterButton, known} = this.parts;
		const context = canvas.getContext('2d');
		const choiceButtons = [...this.querySelectorAll('[data-part="choice"]')];

		// The insults, each with the one comeback that fits it, and the insult of the Master that fits the same comeback.
		const pairs = [
			{insult: 'You fight like a tourist at the fish market!', comeback: 'How appropriate. You smell like the fish market.', master: 'Even the fish at the market fight better than you!'},
			{insult: 'My beak is sharper than a cheese slicer!', comeback: 'Too bad your brain is as thin as a slice of brown cheese.', master: 'My wit is as sharp as Mormor’s best cheese slicer!'},
			{insult: 'I have stolen waffles from bigger kids than you!', comeback: 'Then pick on someone your own size, like a pigeon.', master: 'I once robbed a whole school class for one waffle!'},
			{insult: 'Soon you will wear my droppings on your head!', comeback: 'That’s why everyone in Bergen wears a rain jacket.', master: 'I will decorate you from above, like a statue on the square!'},
			{insult: 'My squawk is louder than the church bells!', comeback: 'And just as welcome at six in the morning.', master: 'When I scream, all of Bryggen wakes up!'},
			{insult: 'Every word you say is as stale as last week’s waffle!', comeback: 'Then it’s the first thing you didn’t have to steal.', master: 'Your jokes are older than the bread in my nest!'},
			{insult: 'I will leave you as wet as a summer in Bergen!', comeback: 'I’m from Bergen. I was born wet.', master: 'I will soak you like a week of Bergen rain!'},
			{insult: 'Nobody has ever escaped my dive!', comeback: 'With your aim, they didn’t have to.', master: 'No kid has ever got away from my claws!'},
		];

		const wrongAnswers = ['Oh, yeah?', 'I am rubber, you are glue.'];
		const gullNames = ['Gulliver', 'Måke-Mona', 'Big Beak Bjørn', 'Fiskeslo-Frida', 'Ola the Gull'];
		const saved = this.stored('progress', {});
		const progress = {
			insults: saved.insults ?? [0, 1],
			comebacks: saved.comebacks ?? [0, 4],
			hasBeatenMaster: saved.hasBeatenMaster ?? false,
		};

		let fight;
		let animation = 0;
		// Whether the visitor plays the fight with the keyboard or a screen reader, so the focus follows the lines to say. It is noted before the buttons hide.
		let isFocusInFight = false;
		const masterNeeds = 6;

		const saveProgress = () => {
			this.store('progress', progress);
		};

		const learn = (list, index) => {
			if (!progress[list].includes(index)) {
				progress[list].push(index);
				progress[list].sort((first, second) => first - second);
				saveProgress();
				return true;
			}

			return false;
		};

		const updateKnown = () => {
			known.textContent = `You know ${progress.insults.length} of 8 insults and ${progress.comebacks.length} of 8 comebacks.${progress.hasBeatenMaster ? ' You beat the Sea Gull Master!' : ''}`;
			const isLocked = progress.comebacks.length < masterNeeds;
			masterButton.dataset.state = isLocked ? 'locked' : '';
			masterButton.setAttribute('aria-disabled', String(isLocked));
			masterButton.textContent = isLocked ? `👑 The Sea Gull Master (learn ${masterNeeds} comebacks first)` : '👑 Fight the Sea Gull Master';
		};

		// Draws Sindre with his umbrella and the seagull with its mackerel. The ground between them moves toward whoever loses a round, and their weapons cross for a moment after each line.
		const draw = () => {
			const gradient = context.createLinearGradient(0, 0, 0, 80);
			gradient.addColorStop(0, '#6a7a90');
			gradient.addColorStop(1, '#a8b4c4');
			context.fillStyle = gradient;
			context.fillRect(0, 0, 200, 80);
			fillShape(context, '#2a4a6a', 0, 44, 200, 16);
			fillShape(context, '#8a8478', 0, 60, 200, 20);
			for (let x = 0; x < 200; x += 10) {
				fillShape(context, '#7a7468', x, 66, 9, 1);
			}

			const shift = (fight?.ground ?? 0) * 12;
			const lunge = this.reducedMotion ? 0 : Math.round(Math.sin(animation * Math.PI) * 6);
			const sindreX = 70 + shift + lunge;
			const gullX = 130 + shift - lunge;
			drawSprite(context, sprites.sindre, sindreX, 70, {scale: 2, colors: {b: palette.j}});
			// The umbrella, held out like a sword.
			context.strokeStyle = '#1a1a3a';
			context.lineWidth = 2;
			context.beginPath();
			context.moveTo(sindreX + 9, 48);
			context.lineTo(sindreX + 30, 40 + (lunge / 2));
			context.stroke();
			fillShape(context, '#c03030', sindreX + 4, 46, 6, 4);
			const isMaster = fight?.isMaster;
			drawSprite(context, sprites.seagull, gullX, 70, {scale: isMaster ? 4 : 3, isFlipped: true});
			if (isMaster) {
				fillPolygon(context, '#ffd700', [[gullX - 8, 38], [gullX - 6, 32], [gullX - 3, 36], [gullX, 30], [gullX + 3, 36], [gullX + 6, 32], [gullX + 8, 38]]);
			}

			// The mackerel, held out like a sword.
			fillPolygon(context, '#5a7a9a', [[gullX - 30, 42 - (lunge / 2)], [gullX - 10, 50], [gullX - 12, 54], [gullX - 32, 46 - (lunge / 2)]]);
			fillShape(context, '#2a3a5a', gullX - 26, 44 - (lunge / 2), 12, 1);
		};

		const clash = async () => {
			this.#beep(880, 0.05, {type: 'square', volume: 0.03});
			this.#beep(1320, 0.05, {type: 'square', volume: 0.03, when: 0.06});
			if (this.reducedMotion) {
				draw();
				return;
			}

			const start = performance.now();
			while (performance.now() - start < 300) {
				await nextFrame();
				animation = (performance.now() - start) / 300;
				draw();
			}

			animation = 0;
			draw();
		};

		const showTally = () => {
			tally.textContent = `Sindre ${fight.sindre} – ${fight.gull} ${fight.isMaster ? 'Master' : 'Seagull'}`;
		};

		// Shows the lines that Sindre can say, and waits for the visitor to pick one.
		const pick = options => new Promise(resolve => {
			for (const [index, button] of choiceButtons.entries()) {
				const option = options[index];
				button.hidden = !option;
				button.textContent = option?.text ?? '';
				button.onclick = option ? () => {
					isFocusInFight = choiceButtons.includes(document.activeElement);
					for (const other of choiceButtons) {
						other.hidden = true;
					}

					resolve(option);
				} : undefined;
			}

			if (isFocusInFight) {
				choiceButtons[0].focus({preventScroll: true});
			}
		});

		const sayLine = async (who, text) => {
			this.say(`${who}: “${text}”`, line);
			await clash();
			await this.wait(clamp(800 + (text.length * 30), 1200, 2600));
		};

		const endFight = async didWin => {
			for (const button of choiceButtons) {
				button.hidden = true;
			}

			if (didWin && fight.isMaster) {
				progress.hasBeatenMaster = true;
				saveProgress();
				this.celebrate();
				this.toast('👑 You beat the Sea Gull Master of Fisketorget! You are the best insulter in Bergen.');
				this.say('The Master: “I have never been insulted so well. You are the new Sea Gull Master of Fisketorget. Here, have a mackerel.”', line);
			} else if (didWin) {
				this.say(`${fight.name} flies away to steal somebody else’s waffle. You won! ${progress.comebacks.length < masterNeeds ? 'Fight more seagulls to learn their comebacks.' : 'You are ready for the Sea Gull Master.'}`, line);
			} else {
				this.say(`${fight.isMaster ? 'The Master' : fight.name} takes your waffle and flies off. You lost! But you learned something. Try again.`, line);
			}

			fight = undefined;
			updateKnown();
			startButton.hidden = false;
			masterButton.hidden = false;
			if (isFocusInFight) {
				startButton.focus({preventScroll: true});
			}
		};

		// The seagull insults Sindre, and Sindre answers. A right comeback wins the round and the turn to insult.
		const defend = async () => {
			const index = Math.floor(Math.random() * pairs.length);
			const insult = fight.isMaster ? pairs[index].master : pairs[index].insult;
			await sayLine(fight.isMaster ? 'The Master' : fight.name, insult);
			const isNew = !fight.isMaster && learn('insults', index);
			const options = [...progress.comebacks.map(comeback => ({text: pairs[comeback].comeback, index: comeback})), ...wrongAnswers.map(text => ({text, index: -1}))];
			const answer = await pick(options);
			await sayLine('Sindre', answer.text);
			if (isNew) {
				this.toast(`⚔ New insult learned: “${pairs[index].insult}”`);
			}

			if (answer.index === index) {
				return true;
			}

			// A seagull that wins a round gloats with the comeback that would have fit, so Sindre learns it for next time. The Master is too proud to explain.
			if (!fight.isMaster) {
				await sayLine(fight.name, `Ha! Everybody knows the answer to that is: “${pairs[index].comeback}”`);
				if (learn('comebacks', index)) {
					this.toast(`⚔ New comeback learned: “${pairs[index].comeback}”`);
					updateKnown();
				}
			}

			return false;
		};

		// Sindre insults the seagull. An ordinary seagull knows most comebacks, and the Master knows them all.
		const attack = async () => {
			const option = await pick(progress.insults.map(insult => ({text: pairs[insult].insult, index: insult})));
			await sayLine('Sindre', option.text);
			const knowsComeback = fight.isMaster || Math.random() < 0.75;
			if (!knowsComeback) {
				await sayLine(fight.name, randomItem(['Uh… SKREE?', 'I… I have to go. My nest is on fire.', 'Oh, yeah? Your mother is a pigeon!']));
				return true;
			}

			await sayLine(fight.isMaster ? 'The Master' : fight.name, pairs[option.index].comeback);
			if (!fight.isMaster && learn('comebacks', option.index)) {
				this.toast(`⚔ New comeback learned: “${pairs[option.index].comeback}”`);
				updateKnown();
			}

			return false;
		};

		// A fight is first to three rounds.
		const startFight = async isMaster => {
			fight = {isMaster, name: isMaster ? 'The Master' : randomItem(gullNames), sindre: 0, gull: 0, ground: 0, isSindreAttacking: false};
			startButton.hidden = true;
			masterButton.hidden = true;
			showTally();
			this.say(isMaster ? 'The Sea Gull Master of Fisketorget lands in front of you, a crown on her head. “So, you think you can insult?”' : `${fight.name} lands on the quay, a mackerel in its beak. En garde!`, line);
			await clash();
			await this.wait(1200);
			while (fight.sindre < 3 && fight.gull < 3) {
				const didSindreWin = fight.isSindreAttacking ? await attack() : await defend();
				if (didSindreWin) {
					fight.sindre++;
					fight.ground++;
				} else {
					fight.gull++;
					fight.ground--;
				}

				// Whoever wins a round insults next, except that the Master always insults, like the Sword Master of Monkey Island.
				fight.isSindreAttacking = didSindreWin && !fight.isMaster;
				showTally();
				draw();
			}

			await endFight(fight.sindre >= 3);
		};

		this.on(startButton, 'click', () => {
			if (!fight) {
				isFocusInFight = document.activeElement === startButton;
				startFight(false);
			}
		});

		this.on(masterButton, 'click', async () => {
			if (fight) {
				return;
			}

			if (progress.comebacks.length < masterNeeds) {
				this.say(`The Master won’t fight a beginner. You know ${progress.comebacks.length} comebacks. Learn ${masterNeeds} from the ordinary seagulls first.`, line);
				return;
			}

			isFocusInFight = document.activeElement === masterButton;
			startFight(true);
		});

		this.#draw = draw;
		updateKnown();
		draw();
	}

	reducedMotionChanged() {
		this.#draw();
	}

	// The audio is made at the first sound, in the click or the key press that makes it, as browsers only let audio start then.
	#beep(...options) {
		if (this.#isSoundOn) {
			beep(this.sound(), ...options);
		}
	}
}
