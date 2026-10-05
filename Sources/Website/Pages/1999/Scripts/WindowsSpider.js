// Spider Solitaire on the desktop of the 1999 page, like the one of Microsoft Plus! 98: 104 cards in ten columns and a stock of five deals, runs of one suit from the king to the ace that fly off the table, three difficulties, a score, Undo, hints, statistics, and fireworks for a win. Mormor watches and gives bad advice. Nothing makes a sound until the visitor presses the Sound button.

const randomItem = items => items[Math.floor(Math.random() * items.length)];

// A finger needs about 24 pixels of each face-up card to pick it, so on a touch screen the narrow cards of a phone are further apart, and the columns can be longer before they squeeze together.
const coarsePointer = matchMedia('(pointer: coarse)');

// A card is a number from 0 to 103, and the deck of the game says its suit and rank. The rank goes from the ace (0) to the king (12).
const suitSymbols = ['♣', '♦', '♥', '♠'];
const suitNames = ['clubs', 'diamonds', 'hearts', 'spades'];
const rankSymbols = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
const rankNames = ['ace', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'jack', 'queen', 'king'];
const king = 12;

// The suits of each difficulty: only spades, spades and hearts, or all four, for the eight runs of 13 cards.
const suitsOf = {1: [3], 2: [3, 2], 4: [0, 1, 2, 3]};
const difficultyNames = {1: 'Easy: One Suit', 2: 'Medium: Two Suits', 4: 'Difficult: Four Suits'};

// Mormor sits next to the table. She talks when she is asked, and sometimes when she is not.
const lines = {
	start: ['Ooh, new cards! Shall I shuffle? I am a very good shuffler.', 'Spiders? In the computer? I will get the newspaper.', 'Your grandfather played this with real cards. All 104 of them. On the kitchen table.'],
	difficult: ['Four suits? Even your grandfather only played with one.', 'Oh my. That is a lot of hearts and spades. Like a wedding.'],
	advice: [
		'Put the red ones on the black ones, dear. That is how Solitaire works.',
		'Why don’t you deal more cards? More cards, more fun!',
		'Move the king to the top, so he can see everything.',
		'I would start over. Everything is easier after a waffle.',
		'Have you tried turning the cards over? The other side has a lovely blue pattern.',
		'Aces first. Aces are always first. Except in this game, it seems.',
		'Ask Trond. He is good with the computer.',
		'In my day the spiders were in the cellar, not in the computer.',
		'Click them faster. The computer likes it when you are quick.',
		'Just put them all on the empty place. It looks so empty.',
	],
	bad: [
		'Put the {a} on the {b}, dear. They look so nice together.',
		'Why not put the {a} on the {b}? Your grandfather always did.',
		'The {a} wants to sit with the {b}. I can tell.',
		'Put the {a} on the {b}. Trust me. I have played cards since 1948.',
	],
	good: [
		'Oh! The {a} could go on the {b}. Your grandfather taught me that in 1961.',
		'Put the {a} on the {b}. I saw that on the television.',
	],
	noMoves: ['Hmm. Have you tried the stock, dear? The little blue cards in the corner.', 'I do not see anything. Where are my glasses?'],
	completed: ['Look, a whole family going home together!', 'All in a row, like ducks!', 'Bravo! That one goes in the drawer.'],
	undo: ['We did not have Undo in 1955. We had to live with our choices.', 'Taking it back? That is cheating, dear. I will not tell.'],
	deal: ['More cards! How generous.', 'Oh dear, they are piling up like the laundry.'],
	invalid: ['It does not want to go there, dear.', 'Gently! The cards have feelings.'],
	emptyDeal: ['You have to fill the holes first. Like Swiss cheese. No, the other way around.'],
	hint: ['The computer is helping you? Is that allowed?', 'Pff. I could have told you that.'],
	idle: ['Are you asleep, dear?', 'Shall I make some waffles while you think?', 'It is past your bedtime, you know.', 'Your mother wants to use the phone. Hurry up with the Internet.'],
	win: ['You won! I knew it. Waffles with brunost for everyone!', 'Look at the fireworks! Just like the 17th of May!'],
};

// The statistics of each difficulty: wins, losses, the high score, and the streaks. The current streak is positive for wins and negative for losses.
const emptyStats = () => ({wins: 0, losses: 0, best: 0, streak: 0, mostWins: 0, mostLosses: 0});

const plural = (count, word, pluralWord = `${word}s`) => `${count.toLocaleString('en-US')} ${count === 1 ? word : pluralWord}`;

const streakText = streak => (streak === 0 ? 'none' : (streak > 0 ? plural(streak, 'win') : plural(-streak, 'loss', 'losses')));

const shuffled = items => {
	const result = [...items];

	for (let index = result.length - 1; index > 0; index--) {
		const other = Math.floor(Math.random() * (index + 1));
		[result[index], result[other]] = [result[other], result[index]];
	}

	return result;
};

const deal = suitCount => {
	const suits = suitsOf[suitCount];
	const deck = Array.from({length: 104}, (_, index) => ({suit: suits[Math.floor(index / 13) % suits.length], rank: index % 13}));
	const order = shuffled(deck.keys());
	const columns = Array.from({length: 10}, () => []);

	// Row by row, like the deal of Spider: the first four columns get six cards, and the others five.
	for (const [index, id] of order.slice(0, 54).entries()) {
		columns[index % 10].push({id, up: false});
	}

	for (const column of columns) {
		column.at(-1).up = true;
	}

	return {suitCount, deck, columns, stock: order.slice(54), completed: []};
};

// A saved game must have every card once, so a game from an older version, or anything else in the storage, starts a new game instead.
const isValidGame = saved => {
	try {
		if (!suitsOf[saved.suitCount] || saved.deck.length !== 104 || !saved.deck.every(card => suitSymbols[card.suit] && rankSymbols[card.rank]) || saved.columns.length !== 10 || !saved.columns.every(column => Array.isArray(column)) || !saved.completed.every(run => run.length === 13) || !Number.isInteger(saved.moves)) {
			return false;
		}

		const ids = [...saved.columns.flat().map(card => card.id), ...saved.stock, ...saved.completed.flat()];
		return ids.length === 104 && new Set(ids).size === 104 && ids.every(id => Number.isInteger(id) && id >= 0 && id < 104) && saved.stock.length % 10 === 0;
	} catch {
		return false;
	}
};

export default class extends GeoCitiesElement {
	#game;
	#columnElements;
	#menus;
	#stockBacks;
	#cardElements = new Map();
	#elementCards = new WeakMap();
	#balloonTimer;
	#idleTimer;
	#fireworks;
	#fireworksLoop;
	#lastWidth = 0;

	// Hints: each press shows the next possible move, from the best one, and wraps around.
	#hint;
	#hintIndex = 0;
	#hintTimer;

	// The keyboard: the column that has the focus, how many cards of its run are selected, and the cards that Space picked up.
	#keyboardColumn = 0;
	#selectedCount = 0;
	#picked;
	#isKeyboardMode = false;

	// The pointer: a drag moves the cards to the column under the pointer, and a click moves them to the best place.
	#drag;
	#wasDragged = false;

	// Drawing. The script lays out the cards, as the face-down cards are closer together than the face-up ones, and long columns squeeze together to fit.
	#size = {width: 40, height: 56};

	// The fireworks and the sounds stop while the table is not on the screen, its window is closed, or the tab is hidden.
	get visibilityTarget() {
		return this.parts.table;
	}

	connected() {
		const {table, columns, stock, score, hint, undo, newGame, askMormor, sound, cardTemplate, gameMenuButton, gameMenu, helpMenuButton, helpMenu} = this.parts;
		this.#columnElements = [...columns.querySelectorAll('[data-spider-column]')];
		this.#menus = [
			{button: gameMenuButton, list: gameMenu},
			{button: helpMenuButton, list: helpMenu},
		];

		// The card backs of the stock are made once, as a new back under the pointer would lose the click on the stock.
		this.#stockBacks = Array.from({length: 5}, () => {
			const back = cardTemplate.content.firstElementChild.cloneNode(true);
			back.dataset.spiderDown = '';
			return back;
		});

		// The fireworks of a win, over the felt, until the last spark is gone, or a click on the table. They stop for good when the window closes, the table scrolls away, or the tab is hidden.
		this.#fireworksLoop = this.loop(seconds => {
			this.#stepFireworks(seconds);
		}, {
			while: () => this.#fireworks !== undefined,
			maximumStep: 0.05,
			stopped: () => {
				this.#stopFireworks();
			},
		});

		this.on(table, 'pointerdown', () => {
			this.#stopFireworks();
		});

		this.on(sound, 'click', () => {
			const isOn = !this.#isSoundOn;
			sound.setAttribute('aria-pressed', String(isOn));

			if (isOn) {
				// The desktop starts its audio in the handler of this click, as browsers only allow sound after one.
				this.sound();
				this.#sounds.place();
			}
		});

		this.#listenToKeyboard(columns);
		this.#listenToPointer(columns);

		// The buttons and the menus.
		this.on(stock, 'click', () => {
			if (this.#game) {
				this.#dealRow();
			}
		});

		this.on(score, 'click', () => {
			if (this.#game) {
				this.#showNextHint();
			}
		});

		this.on(hint, 'click', () => {
			if (this.#game) {
				this.#showNextHint();
			}
		});

		this.on(undo, 'click', () => {
			if (this.#game) {
				this.#undo();
			}
		});

		this.on(newGame, 'click', () => {
			if (this.#game) {
				this.#confirmNewGame();
			}
		});

		this.on(askMormor, 'click', () => {
			if (this.#game) {
				this.#askMormor();
			}
		});

		this.#listenToMenus();

		// The keys of Spider Solitaire: F2 for a new game, Ctrl+Z to undo, D to deal, M to show a move, and F1 for help. They work anywhere in the window, like right after it opens.
		this.on(this.desktopWindow, 'keydown', event => {
			if (!this.#game || event.altKey || event.repeat || this.#menus.some(({list}) => !list.hidden) || event.target.closest('input, textarea')) {
				return;
			}

			const isCommand = event.ctrlKey || event.metaKey;
			let command;

			if (event.key === 'F2') {
				command = 'new';
			} else if (event.key === 'F1') {
				command = 'rules';
			} else if (isCommand && event.key.toLowerCase() === 'z') {
				command = 'undo';
			} else if (!isCommand && event.key.toLowerCase() === 'd') {
				command = 'deal';
			} else if (!isCommand && event.key.toLowerCase() === 'm') {
				command = 'hint';
			}

			if (command) {
				event.preventDefault();
				this.#commands[command]();
			}
		});

		// The cards are laid out again when the window changes size, like on a phone that turns.
		this.observe(new ResizeObserver(() => {
			if (table.clientWidth !== this.#lastWidth && this.#game && !this.desktopWindow.hidden) {
				this.#lastWidth = table.clientWidth;
				this.#render();
			}
		})).observe(table);
	}

	reducedMotionChanged() {
		this.#stopFireworks();
	}

	// The first time the window opens, the game from last time comes back, or the visitor picks a difficulty, like the first start of Spider Solitaire.
	windowChanged(isOpen) {
		if (!isOpen) {
			this.#stopFireworks();
			this.#closeMenus();
			this.#idleTimer?.cancel();
			return;
		}

		if (this.#game) {
			this.#render();
			this.#resetIdle();
		} else {
			this.#begin();
		}
	}

	async #begin() {
		const saved = this.stored('game', undefined);

		if (saved && isValidGame(saved)) {
			this.#startGame({suitCount: saved.suitCount, deck: saved.deck, columns: saved.columns, stock: saved.stock, completed: saved.completed}, {moves: saved.moves, initial: isValidGame({...saved.initial, deck: saved.deck, moves: 0, suitCount: saved.suitCount}) ? saved.initial : undefined});
			this.say('Welcome back! Here is the game you left.');
			this.#mormorSays('Oh, you are back! I kept your cards warm.');
			return;
		}

		const remembered = this.stored('difficulty', undefined);

		if (suitsOf[remembered]) {
			this.#newGame(remembered);
			return;
		}

		this.#newGame(1);
		await this.#chooseDifficulty();
	}

	#card(id) {
		return this.#game.deck[id];
	}

	#isRed(id) {
		return this.#card(id).suit === 1 || this.#card(id).suit === 2;
	}

	#cardText(id) {
		return `${rankSymbols[this.#card(id).rank]}${suitSymbols[this.#card(id).suit]}`;
	}

	#cardName(id) {
		return `${rankNames[this.#card(id).rank]} of ${suitNames[this.#card(id).suit]}`;
	}

	// Mormor’s speech balloon, which goes away after a while.
	#mormorSays(text) {
		const {balloon} = this.parts;
		balloon.textContent = text;
		balloon.hidden = false;
		this.#balloonTimer?.cancel();
		this.#balloonTimer = this.timeout(5000, () => {
			balloon.hidden = true;
		});
	}

	// She only says something about every other time, so she is not too much.
	#maybeSay(group, chance = 0.5) {
		if (Math.random() < chance) {
			this.#mormorSays(randomItem(lines[group]));
		}
	}

	#fillIn(text, first, second) {
		return text.replace('{a}', this.#cardText(first)).replace('{b}', this.#cardText(second));
	}

	#resetIdle() {
		this.#idleTimer?.cancel();
		this.#idleTimer = this.timeout(45_000, () => {
			if (this.#game && !this.#game.isWon && this.isVisible) {
				this.#mormorSays(randomItem(lines.idle));
			}
		});
	}

	get #isSoundOn() {
		return this.parts.sound.getAttribute('aria-pressed') === 'true';
	}

	// The sounds, made with tones and noise. The audio comes from the desktop, which plays it through the volume of the tray.
	#audio() {
		return this.#isSoundOn && this.isVisible ? this.sound() : undefined;
	}

	#tone(frequency, start, duration, {type = 'triangle', volume = 0.1, slide} = {}) {
		const sound = this.#audio();

		if (!sound) {
			return;
		}

		const {context, output} = sound;
		const oscillator = context.createOscillator();
		const gain = context.createGain();
		const time = context.currentTime + start;
		oscillator.type = type;
		oscillator.frequency.setValueAtTime(frequency, time);

		if (slide) {
			oscillator.frequency.exponentialRampToValueAtTime(slide, time + duration);
		}

		gain.gain.setValueAtTime(0.0001, time);
		gain.gain.exponentialRampToValueAtTime(volume, time + 0.01);
		gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
		oscillator.connect(gain).connect(output);
		oscillator.start(time);
		oscillator.stop(time + duration + 0.05);
	}

	// The snap of a card on the table, a short burst of noise through a filter.
	#snap(start = 0, frequency = 2500, volume = 0.15) {
		const sound = this.#audio();

		if (!sound) {
			return;
		}

		const {context, output} = sound;
		const length = Math.ceil(context.sampleRate * 0.05);
		const buffer = context.createBuffer(1, length, context.sampleRate);
		const data = buffer.getChannelData(0);

		for (let index = 0; index < length; index++) {
			data[index] = ((Math.random() * 2) - 1) * ((1 - (index / length)) ** 3);
		}

		const source = context.createBufferSource();
		const filter = context.createBiquadFilter();
		const gain = context.createGain();
		source.buffer = buffer;
		filter.type = 'bandpass';
		filter.frequency.value = frequency;
		gain.gain.value = volume;
		source.connect(filter).connect(gain).connect(output);
		source.start(context.currentTime + start);
	}

	#sounds = {
		place: () => {
			this.#snap();
		},
		deal: () => {
			for (let index = 0; index < 10; index++) {
				this.#snap(index * 0.05, 2200 + (index * 80), 0.12);
			}
		},
		completed: () => {
			for (const [index, frequency] of [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5].entries()) {
				this.#tone(frequency, index * 0.07, 0.18, {type: 'square', volume: 0.05});
			}
		},
		invalid: () => {
			this.#tone(180, 0, 0.18, {type: 'sawtooth', volume: 0.06});
		},
		hint: () => {
			this.#tone(880, 0, 0.08);
			this.#tone(1320, 0.08, 0.12);
		},
		undo: () => {
			this.#tone(700, 0, 0.12, {slide: 350, volume: 0.06});
		},
		pop: () => {
			this.#tone(400 + (Math.random() * 300), 0, 0.3, {type: 'sine', slide: 1400, volume: 0.04});
			this.#snap(0.28, 900, 0.25);
		},
		win: () => {
			for (const [index, frequency] of [523.25, 659.25, 783.99, 1046.5, 1318.5].entries()) {
				this.#tone(frequency, index * 0.14, index === 4 ? 0.8 : 0.2, {type: 'square', volume: 0.06});
			}
		},
	};

	// A question with the message box of the desktop.
	ask(options) {
		return super.ask({title: 'Spider', icon: '🕷️', ...options});
	}

	#loadStats() {
		const stats = this.stored('stats', {})[this.#game.suitCount];
		return Number.isInteger(stats?.wins) ? {...emptyStats(), ...stats} : emptyStats();
	}

	#saveStats(stats) {
		this.store('stats', {...this.stored('stats', {}), [this.#game.suitCount]: stats});
	}

	#recordResult(isWin) {
		const stats = this.#loadStats();

		if (isWin) {
			stats.wins++;
			stats.streak = Math.max(stats.streak, 0) + 1;
			stats.mostWins = Math.max(stats.mostWins, stats.streak);
			stats.best = Math.max(stats.best, this.#score());
		} else {
			stats.losses++;
			stats.streak = Math.min(stats.streak, 0) - 1;
			stats.mostLosses = Math.max(stats.mostLosses, -stats.streak);
		}

		this.#saveStats(stats);
		this.#renderStats();
		return stats;
	}

	#renderStats() {
		const stats = this.#loadStats();
		const played = stats.wins + stats.losses;
		this.parts.stats.textContent = played === 0
			? `${difficultyNames[this.#game.suitCount]}. Build eight runs from the king down to the ace, each of one suit, and they fly off the table.`
			: `${difficultyNames[this.#game.suitCount]} (${plural(stats.wins, 'win')}, ${plural(stats.losses, 'loss', 'losses')}, high score ${stats.best.toLocaleString('en-US')}). Statistics are in the Game menu.`;
	}

	// The rules.
	#score() {
		return 500 - this.#game.moves + (100 * this.#game.completed.length);
	}

	// Where the run at the bottom of a column starts: the cards of one suit in sequence, which move together.
	#runStart(column) {
		let start = column.length - 1;

		while (start > 0) {
			const above = column[start - 1];
			const card = this.#card(column[start].id);

			if (!above.up || this.#card(above.id).suit !== card.suit || this.#card(above.id).rank !== card.rank + 1) {
				break;
			}

			start--;
		}

		return start;
	}

	#canDrop(id, target) {
		const top = this.#game.columns[target].at(-1);
		return !top || (top.up && this.#card(top.id).rank === this.#card(id).rank + 1);
	}

	// How good a move is, so hints and clicks pick the best one. Building in suit is best, revealing a card or emptying a column is good, and moving a card from one card one higher to another is no use.
	#gainOf({from, index, to}) {
		const column = this.#game.columns[from];
		const moving = this.#card(column[index].id);
		const below = column[index - 1];
		const top = this.#game.columns[to].at(-1);
		const isSuited = top && this.#card(top.id).suit === moving.suit;
		let gain = isSuited ? 3 : (top ? 1 : -1);

		if (!below) {
			gain += top ? 2 : -10;
		} else if (!below.up) {
			gain += 2;
		} else if (this.#card(below.id).rank === moving.rank + 1) {
			if (this.#card(below.id).suit === moving.suit || !isSuited) {
				gain -= 10;
			}
		} else {
			gain += 1;
		}

		return gain;
	}

	// Every move there is, with the best first.
	#legalMoves() {
		const moves = [];

		for (const [from, column] of this.#game.columns.entries()) {
			if (column.length === 0) {
				continue;
			}

			for (let index = this.#runStart(column); index < column.length; index++) {
				for (let to = 0; to < 10; to++) {
					if (to !== from && this.#canDrop(column[index].id, to)) {
						moves.push({from, index, to, gain: this.#gainOf({from, index, to}), length: column.length - index});
					}
				}
			}
		}

		return moves.sort((first, second) => (second.gain - first.gain) || (second.length - first.length));
	}

	// A move to an empty column that reveals nothing has no gain, but it is still worth a hint, as the stock cannot deal while a column is empty.
	#usefulMoves() {
		return this.#legalMoves().filter(move => move.gain >= 0);
	}

	// The game.
	#layoutSnapshot() {
		return structuredClone({columns: this.#game.columns, stock: this.#game.stock, completed: this.#game.completed});
	}

	#makeCardElements() {
		for (const element of this.#cardElements.values()) {
			element.remove();
		}

		this.#cardElements = new Map();

		for (const id of this.#game.deck.keys()) {
			const element = this.parts.cardTemplate.content.firstElementChild.cloneNode(true);

			if (this.#isRed(id)) {
				element.dataset.spiderRed = '';
			}

			this.#elementCards.set(element, id);
			this.#cardElements.set(id, element);
		}
	}

	#startGame(layout, {moves = 0, initial} = {}) {
		this.#stopFireworks();
		this.#game = {...layout, moves, undo: [], isWon: false, initial: initial ?? structuredClone({columns: layout.columns, stock: layout.stock, completed: layout.completed})};
		this.#picked = undefined;
		this.#hint = undefined;
		this.#hintIndex = 0;
		this.#selectedCount = 0;
		this.#makeCardElements();
		this.#render();
		this.#renderStats();
		this.#saveGame();
		this.#resetIdle();
	}

	#saveGame() {
		const game = this.#game;

		if (game.isWon) {
			this.store('game', undefined);
			return;
		}

		this.store('game', {suitCount: game.suitCount, deck: game.deck, columns: game.columns, stock: game.stock, completed: game.completed, moves: game.moves, initial: game.initial});
	}

	#newGame(suitCount) {
		this.#startGame(deal(suitCount));
		this.say(`${difficultyNames[suitCount]}. Drag a card, or click it to move it to the best place. Click the stock to deal a new row.`);
		this.#maybeSay(suitCount === 4 ? 'difficult' : 'start', 0.7);
	}

	// Giving up a game that has moves counts as a loss, like in Spider Solitaire.
	get #isInProgress() {
		return this.#game && this.#game.moves > 0 && !this.#game.isWon;
	}

	async #confirmNewGame(suitCount = this.#game.suitCount) {
		if (this.#isInProgress) {
			const answer = await this.ask({text: 'Do you want to give up this game and start a new one?\n\nIt counts as a loss.', buttons: ['Yes', 'No'], opener: this.parts.newGame});

			if (answer !== 'Yes') {
				return;
			}

			this.#recordResult(false);
		}

		this.#newGame(suitCount);
	}

	async #chooseDifficulty() {
		const wasInProgress = this.#isInProgress;
		const answer = await this.ask({
			title: 'Difficulty',
			icon: '🕷️',
			text: `Select the game difficulty level.${wasInProgress ? '\n\nThe game you are playing now counts as a loss.' : ''}`,
			buttons: Object.values(difficultyNames),
		});
		const suitCount = Number(Object.keys(difficultyNames).find(key => difficultyNames[key] === answer));

		if (!suitCount) {
			return;
		}

		this.store('difficulty', suitCount);

		// The visitor can play the cards behind the dialog. As the dialog did not say that this game counts as a loss, it does not, and it goes on when they pick its difficulty.
		if (!wasInProgress && this.#isInProgress && suitCount === this.#game.suitCount) {
			return;
		}

		if (wasInProgress && this.#isInProgress) {
			this.#recordResult(false);
		}

		this.#newGame(suitCount);
	}

	// A move, a deal, or an undo saves the layout before it, so Undo can go back. Every move and every undo costs a point.
	#finishChange(rectangles, {arriving = [], completedIds = [], revealed = []} = {}) {
		// Picked cards are put back after any change, as a deal or an undo can change the column under them.
		this.#picked = undefined;
		this.#hint = undefined;
		this.#hintIndex = 0;
		this.#render();
		this.#animate(rectangles, {arriving, completedIds, revealed});
		this.#saveGame();
		this.#resetIdle();

		if (this.#game.completed.length === 8 && !this.#game.isWon) {
			this.#win();
		}
	}

	#revealTop(column, revealed) {
		const top = column.at(-1);

		if (top && !top.up) {
			top.up = true;
			revealed.push(top.id);
		}
	}

	// A run of one suit from the king down to the ace at the bottom of a column flies off to the completed suits.
	#collectRun(columnIndex, completedIds, revealed) {
		const column = this.#game.columns[columnIndex];

		if (column.length < 13) {
			return false;
		}

		const start = column.length - 13;

		if (!column[start].up || this.#card(column[start].id).rank !== king || this.#runStart(column) > start) {
			return false;
		}

		const run = column.splice(start).map(card => card.id);
		this.#game.completed.push(run);
		completedIds.push(...run);
		this.#revealTop(column, revealed);
		return true;
	}

	#move(from, index, to) {
		const game = this.#game;
		const rectangles = this.#cardRectangles();
		game.undo.push(this.#layoutSnapshot());
		const cards = game.columns[from].splice(index);
		game.columns[to].push(...cards);
		game.moves++;
		const revealed = [];
		const completedIds = [];
		this.#revealTop(game.columns[from], revealed);
		this.#sounds.place();

		if (this.#collectRun(to, completedIds, revealed)) {
			this.#sounds.completed();
			this.#maybeSay('completed', 0.6);
			this.say(`A run of ${suitNames[this.#card(completedIds[0]).suit]} is complete! Plus 100 points.`);
		} else {
			const top = game.columns[to].at(-(cards.length + 1));
			this.say(`${this.#cardText(cards[0].id)}${cards.length > 1 ? ` and ${plural(cards.length - 1, 'card')} under it` : ''} moved ${top ? `onto the ${this.#cardText(top.id)}` : 'to the empty column'}.${revealed.length > 0 && completedIds.length === 0 ? ` The ${this.#cardText(revealed[0])} turns over.` : ''}`);
		}

		this.#finishChange(rectangles, {completedIds, revealed});
	}

	async #dealRow() {
		const game = this.#game;

		if (game.isWon) {
			return;
		}

		if (game.stock.length === 0) {
			this.#sounds.invalid();
			this.say('There are no more cards to deal.');
			return;
		}

		if (game.columns.some(column => column.length === 0)) {
			this.#sounds.invalid();
			this.#maybeSay('emptyDeal', 0.6);
			await this.ask({text: 'You are not allowed to deal a new row while there are any empty slots.', icon: '⚠️', opener: this.parts.stock});
			return;
		}

		const rectangles = this.#cardRectangles();
		game.undo.push(this.#layoutSnapshot());
		const ids = game.stock.splice(-10);
		const revealed = [];
		const completedIds = [];

		for (const [index, id] of ids.entries()) {
			game.columns[index].push({id, up: true});
		}

		game.moves++;
		this.#sounds.deal();

		for (const index of game.columns.keys()) {
			this.#collectRun(index, completedIds, revealed);
		}

		if (completedIds.length > 0) {
			this.#sounds.completed();
		}

		this.#maybeSay('deal', 0.35);
		this.say(`New row dealt. ${game.stock.length === 0 ? 'That was the last one.' : `${plural(game.stock.length / 10, 'deal')} left.`}`);
		this.#finishChange(rectangles, {arriving: ids, completedIds, revealed});
	}

	#undo() {
		const game = this.#game;

		if (game.isWon || game.undo.length === 0) {
			this.say('There is nothing to undo.');
			return;
		}

		const rectangles = this.#cardRectangles();
		Object.assign(game, game.undo.pop());
		game.moves++;
		this.#sounds.undo();
		this.#maybeSay('undo', 0.3);
		this.say(`Undone. It costs a point: the score is ${this.#score().toLocaleString('en-US')}.`);
		this.#finishChange(rectangles);
	}

	#restart() {
		const game = this.#game;

		if (game.moves === 0) {
			this.say('The game has not started yet.');
			return;
		}

		this.#startGame({suitCount: game.suitCount, deck: game.deck, ...structuredClone(game.initial)}, {initial: game.initial});
		this.say('The game starts over with the same cards.');
	}

	async #win() {
		const startedGame = this.#game;
		startedGame.isWon = true;
		this.parts.undo.disabled = true;
		const isBest = this.#score() > this.#loadStats().best;
		this.#recordResult(true);
		this.#saveGame();
		this.#sounds.win();
		this.#mormorSays(randomItem(lines.win));
		this.say(`You won with ${this.#score().toLocaleString('en-US')} points!${isBest ? ' A new high score!' : ''}`);
		await this.wait(this.reducedMotion ? 300 : 1200);

		// A new game can start while the cards fly off.
		if (startedGame !== this.#game) {
			return;
		}

		await this.#launchFireworks();

		if (startedGame !== this.#game || this.desktopWindow.hidden) {
			return;
		}

		const answer = await this.ask({title: 'Spider', icon: '🏆', text: `Congratulations, you won!\n\nYour score: ${this.#score().toLocaleString('en-US')}${isBest ? ' (a new high score!)' : ''}\n\nDo you want to start another game?`, buttons: ['Yes', 'No'], opener: this.parts.newGame});

		if (answer === 'Yes' && startedGame === this.#game) {
			this.#newGame(this.#game.suitCount);
		}
	}

	#showHint(move, message) {
		this.#hint = move;
		this.#hintTimer?.cancel();
		this.#render();
		this.#sounds.hint();
		this.say(message);
		this.#hintTimer = this.timeout(1800, () => {
			this.#hint = undefined;
			this.#render();
		});
	}

	#moveText({from, index, to}) {
		const id = this.#game.columns[from][index].id;
		const top = this.#game.columns[to].at(-1);
		const count = this.#game.columns[from].length - index;
		return `move the ${this.#cardText(id)}${count > 1 ? ` and ${plural(count - 1, 'card')} under it` : ''} ${top ? `onto the ${this.#cardText(top.id)}` : 'to the empty column'}`;
	}

	async #showNextHint() {
		const game = this.#game;

		if (game.isWon) {
			return;
		}

		const moves = this.#usefulMoves();
		this.#resetIdle();

		if (moves.length === 0) {
			if (game.stock.length > 0 && !game.columns.some(column => column.length === 0)) {
				this.#showHint({stock: true}, 'There are no more moves. Deal a new row from the stock.');
				return;
			}

			this.#sounds.invalid();
			await this.ask({text: 'There are no more moves.', icon: 'ℹ️', opener: this.parts.hint});
			return;
		}

		const move = moves[this.#hintIndex % moves.length];
		this.#hintIndex++;
		this.#maybeSay('hint', 0.15);
		const text = this.#moveText(move);
		this.#showHint(move, `Hint ${((this.#hintIndex - 1) % moves.length) + 1} of ${moves.length}: ${text[0].toUpperCase()}${text.slice(1)}.`);
	}

	// Mormor’s advice: mostly a move that is not allowed, or something that has nothing to do with Spider, and now and then a real one.
	#askMormor() {
		const game = this.#game;
		this.#resetIdle();
		const tops = game.columns.map(column => column.at(-1)).filter(card => card?.up);
		const moves = this.#usefulMoves();
		const roll = Math.random();

		if (roll < 0.2 && moves.length > 0) {
			const move = randomItem(moves.slice(0, 3));
			const top = game.columns[move.to].at(-1);

			if (top) {
				this.#mormorSays(this.#fillIn(randomItem(lines.good), game.columns[move.from][move.index].id, top.id));
				this.#showHint(move, `Mormor is right for once: ${this.#moveText(move)}.`);
				return;
			}
		}

		if (roll < 0.6 && tops.length >= 2) {
			const [first, second] = shuffled(tops);
			this.#mormorSays(this.#fillIn(randomItem(lines.bad), first.id, second.id));
			this.say(this.#canDrop(first.id, game.columns.findIndex(column => column.at(-1) === second))
				? 'Mormor gave advice. It might even work.'
				: `Mormor gave advice. The ${this.#cardText(first.id)} cannot go on the ${this.#cardText(second.id)}.`);
			return;
		}

		this.#mormorSays(moves.length === 0 && game.stock.length === 0 ? randomItem(lines.noMoves) : randomItem(lines.advice));
		this.say('Mormor gave advice.');
	}

	// A click on a card moves it, and the cards under it, to the best place: on a card of the same suit if it can, else on any card one higher, else to an empty column.
	#moveToBest(from, index) {
		const column = this.#game.columns[from];
		const card = column[index];

		if (!card.up) {
			this.#invalid('That card is face down. Move the cards on it first.');
			return;
		}

		if (index < this.#runStart(column)) {
			this.#invalid('Only cards of one suit in order move together.');
			return;
		}

		const moves = this.#legalMoves().filter(candidate => candidate.from === from && candidate.index === index);

		if (moves.length === 0) {
			this.#invalid(`The ${this.#cardText(card.id)} has nowhere to go.`);
			return;
		}

		this.#move(from, index, moves[0].to);
	}

	#invalid(message) {
		this.#sounds.invalid();
		this.#maybeSay('invalid', 0.25);
		this.say(message);
	}

	#measure() {
		const width = Math.max(18, this.#columnElements[0].clientWidth);
		const height = Math.round(width * 1.4);
		this.#size = {width, height, down: Math.max(3, Math.round(height * 0.1)), up: Math.max(coarsePointer.matches ? 24 : 14, Math.round(height * 0.3)), maximum: Math.max(height * 5.5, coarsePointer.matches ? 340 : 240)};
	}

	#setFace(element, isUp) {
		const id = this.#elementCards.get(element);
		const [corner, pip] = element.children;

		if (isUp) {
			delete element.dataset.spiderDown;
			corner.textContent = this.#cardText(id);
			pip.textContent = suitSymbols[this.#card(id).suit];
		} else {
			element.dataset.spiderDown = '';
			corner.textContent = '';
			pip.textContent = '';
		}
	}

	#placeCard(element, x, y) {
		element.style.width = `${this.#size.width}px`;
		element.style.height = `${this.#size.height}px`;
		element.style.translate = `${x}px ${y}px`;
	}

	// The cards that are already in their place stay in it, as moving an element that the pointer is on can lose its click.
	#setChildren(parent, elements) {
		const children = parent.children;

		if (children.length !== elements.length || elements.some((element, index) => children[index] !== element)) {
			parent.replaceChildren(...elements);
		}
	}

	// The offsets of the cards of a column, with the steps between the face-up cards smaller when the column is long.
	#offsetsOf(column) {
		const size = this.#size;
		const downCount = column.filter(card => !card.up).length;
		const upCount = column.length - downCount - 1;
		const room = size.maximum - size.height - (downCount * size.down);
		const upStep = upCount > 0 ? Math.max(8, Math.min(size.up, Math.floor(room / upCount))) : size.up;
		const offsets = [];
		let y = 0;

		for (const card of column) {
			offsets.push(y);
			y += card.up ? upStep : size.down;
		}

		return offsets;
	}

	#describeColumn(column, index) {
		if (column.length === 0) {
			return `Column ${index + 1}, empty`;
		}

		const downCount = column.filter(card => !card.up).length;
		const faceUp = column.filter(card => card.up).map(card => this.#cardName(card.id));
		let label = `Column ${index + 1}: ${downCount > 0 ? `${plural(downCount, 'card')} face down, then ` : ''}${faceUp.join(', ')}`;

		if (this.#picked?.from === index) {
			label += `. ${plural(column.length - this.#picked.index, 'card')} picked up`;
		} else if (this.#keyboardColumn === index && this.#selectedCount > 0) {
			label += `. ${plural(Math.min(this.#selectedCount, this.#runLength(index)), 'card')} selected`;
		}

		return label;
	}

	#render() {
		const game = this.#game;

		if (!game) {
			return;
		}

		const {foundation, stock, score: scoreButton, undo: undoButton} = this.parts;
		this.#measure();

		for (const [index, column] of game.columns.entries()) {
			const element = this.#columnElements[index];
			const offsets = this.#offsetsOf(column);
			const elements = column.map(card => this.#cardElements.get(card.id));
			const selected = Math.min(this.#selectedCount, this.#runLength(index));
			const pickedFrom = this.#picked?.from === index ? this.#picked.index : (this.#keyboardColumn === index && selected > 0 && this.#isKeyboardMode ? column.length - selected : Number.POSITIVE_INFINITY);
			const hintFrom = this.#hint?.from === index ? this.#hint.index : Number.POSITIVE_INFINITY;
			const isHintTarget = this.#hint?.to === index;

			for (const [position, card] of column.entries()) {
				const cardElement = elements[position];
				this.#setFace(cardElement, card.up);
				this.#placeCard(cardElement, 0, offsets[position]);
				cardElement.toggleAttribute('data-spider-selected', position >= pickedFrom);
				cardElement.toggleAttribute('data-spider-hint', position >= hintFrom || (isHintTarget && position === column.length - 1));
				delete cardElement.dataset.spiderDragging;
			}

			this.#setChildren(element, elements);
			element.style.height = `${(offsets.at(-1) ?? 0) + this.#size.height}px`;

			if (column.length === 0) {
				element.dataset.state = 'empty';
			} else {
				delete element.dataset.state;
			}

			element.toggleAttribute('data-spider-target', isHintTarget && column.length === 0);
			element.setAttribute('aria-label', this.#describeColumn(column, index));
		}

		// The completed suits, each a little to the right of the one before, with the king on top.
		const foundationStep = Math.round(this.#size.width * 0.3);
		const foundationCards = [];

		for (const [set, run] of game.completed.entries()) {
			for (const id of run.toReversed()) {
				const element = this.#cardElements.get(id);
				this.#setFace(element, true);
				this.#placeCard(element, set * foundationStep, 0);
				element.toggleAttribute('data-spider-selected', false);
				element.toggleAttribute('data-spider-hint', false);
				foundationCards.push(element);
			}
		}

		this.#setChildren(foundation, foundationCards);
		foundation.style.width = `${this.#size.width + (Math.max(game.completed.length - 1, 0) * foundationStep)}px`;
		foundation.style.height = `${this.#size.height}px`;
		foundation.dataset.state = game.completed.length === 0 ? 'empty' : 'full';
		foundation.setAttribute('aria-label', game.completed.length === 0 ? 'No completed suits' : `${game.completed.length} of 8 suits completed`);

		// The stock, one card back for each deal that is left.
		const deals = game.stock.length / 10;
		const stockStep = Math.round(this.#size.width * 0.2);
		const backs = this.#stockBacks.slice(0, deals);

		for (const [index, back] of backs.entries()) {
			this.#placeCard(back, index * stockStep, 0);
			back.toggleAttribute('data-spider-hint', this.#hint?.stock === true);
		}

		this.#setChildren(stock, backs);
		stock.style.width = `${this.#size.width + (4 * stockStep)}px`;
		stock.style.height = `${this.#size.height}px`;

		if (deals === 0) {
			stock.dataset.state = 'empty';
		} else {
			delete stock.dataset.state;
		}

		stock.setAttribute('aria-label', deals === 0 ? 'Stock, empty' : `Deal a new row, ${plural(deals, 'deal')} left`);

		// The cards of the stock are not on the table.
		for (const id of game.stock) {
			this.#cardElements.get(id).remove();
		}

		scoreButton.textContent = `Score: ${this.#score().toLocaleString('en-US')}\nMoves: ${game.moves.toLocaleString('en-US')}`;
		scoreButton.setAttribute('aria-label', `Score ${this.#score()}, ${plural(game.moves, 'move')}. Show an available move.`);
		undoButton.disabled = game.undo.length === 0 || game.isWon;
	}

	// The cards glide from where they were to where they are now, the dealt cards come from the stock, the completed suits fly off one by one, and the cards that turn over flip. Nothing moves for visitors who prefer reduced motion.
	#cardRectangles() {
		const rectangles = new Map();

		for (const [id, element] of this.#cardElements) {
			if (element.isConnected) {
				rectangles.set(id, element.getBoundingClientRect());
			}
		}

		const {stock} = this.parts;
		rectangles.set('stock', (stock.lastElementChild ?? stock).getBoundingClientRect());
		return rectangles;
	}

	#animate(rectangles, {arriving = [], completedIds = [], revealed = []}) {
		if (this.reducedMotion || this.desktopWindow.hidden) {
			return;
		}

		const delays = new Map();

		for (const [index, id] of arriving.entries()) {
			delays.set(id, index * 45);
		}

		// The ace of a completed run goes first, and the king last.
		for (const [index, id] of completedIds.toReversed().entries()) {
			delays.set(id, 200 + ((index % 13) * 45));
		}

		for (const [id, element] of this.#cardElements) {
			if (!element.isConnected) {
				continue;
			}

			const before = rectangles.get(id) ?? (arriving.includes(id) ? rectangles.get('stock') : undefined);

			if (!before) {
				continue;
			}

			const after = element.getBoundingClientRect();
			const x = before.left - after.left;
			const y = before.top - after.top;

			if (Math.abs(x) + Math.abs(y) < 1) {
				continue;
			}

			for (const animation of element.getAnimations()) {
				animation.cancel();
			}

			element.animate([
				{transform: `translate(${x}px, ${y}px)`, zIndex: 20},
				{transform: 'none', zIndex: 20},
			], {duration: completedIds.includes(id) ? 380 : 200, delay: delays.get(id) ?? 0, easing: 'ease-out', fill: 'backwards'});
		}

		for (const id of revealed) {
			const element = this.#cardElements.get(id);

			if (element.isConnected && element.getAnimations().length === 0) {
				element.animate([{transform: 'scaleX(0)'}, {transform: 'none'}], {duration: 180, delay: completedIds.length > 0 ? 800 : 120, easing: 'ease-out', fill: 'backwards'});
			}
		}
	}

	// The fireworks are left out for visitors who prefer reduced motion, and the win goes on when they end.
	#launchFireworks() {
		return new Promise(resolve => {
			if (this.reducedMotion || !this.isVisible) {
				resolve();
				return;
			}

			const {table, fireworks: canvas} = this.parts;
			const scale = devicePixelRatio || 1;
			const width = table.clientWidth;
			const height = table.clientHeight;
			canvas.width = Math.round(width * scale);
			canvas.height = Math.round(height * scale);
			canvas.hidden = false;
			const context = canvas.getContext('2d');
			context.scale(scale, scale);
			this.#fireworks = {context, width, height, sparks: [], bursts: 0, nextBurst: 0, resolve};
			this.#fireworksLoop.start();
		});
	}

	#stopFireworks() {
		const fireworks = this.#fireworks;

		if (!fireworks) {
			return;
		}

		this.#fireworks = undefined;
		this.parts.fireworks.hidden = true;
		fireworks.resolve();
	}

	#burst() {
		const fireworks = this.#fireworks;
		const x = fireworks.width * (0.15 + (Math.random() * 0.7));
		const y = fireworks.height * (0.1 + (Math.random() * 0.45));
		const color = randomItem(['#ff4040', '#ffff40', '#40ff40', '#40c0ff', '#ff60ff', '#ffffff', '#ffa040']);

		for (let index = 0; index < 48; index++) {
			const angle = (index / 48) * Math.PI * 2;
			const speed = 1.2 + (Math.random() * 2.4);
			fireworks.sparks.push({x, y, speedX: Math.cos(angle) * speed, speedY: Math.sin(angle) * speed, life: 1, color: Math.random() < 0.2 ? '#ffffff' : color});
		}

		fireworks.bursts++;
		this.#sounds.pop();
	}

	// The speeds are in pixels for each 60th of a second, so the sparks move as fast on any screen.
	#stepFireworks(seconds) {
		const fireworks = this.#fireworks;
		const {context, width, height} = fireworks;
		const elapsed = seconds * 60;
		fireworks.nextBurst -= elapsed;

		if (fireworks.nextBurst <= 0 && fireworks.bursts < 12) {
			this.#burst();
			fireworks.nextBurst = 15 + (Math.random() * 25);
		}

		// The canvas fades a little each frame, so the sparks leave trails.
		context.globalCompositeOperation = 'destination-out';
		context.fillStyle = 'rgb(0 0 0 / 25%)';
		context.fillRect(0, 0, width, height);
		context.globalCompositeOperation = 'source-over';

		for (const spark of fireworks.sparks) {
			spark.speedY += 0.04 * elapsed;
			spark.speedX *= 0.99;
			spark.x += spark.speedX * elapsed;
			spark.y += spark.speedY * elapsed;
			spark.life -= 0.013 * elapsed;
			context.globalAlpha = Math.max(0, spark.life);
			context.fillStyle = spark.color;
			context.fillRect(spark.x, spark.y, 2.5, 2.5);
		}

		context.globalAlpha = 1;
		fireworks.sparks = fireworks.sparks.filter(spark => spark.life > 0);

		if (fireworks.bursts >= 12 && fireworks.sparks.length === 0) {
			this.#stopFireworks();
		}
	}

	// The keyboard: Left and Right pick a column, Up and Down pick how many cards of its run, Enter moves them to the best place, Space picks them up and puts them down on another column, and Escape puts them back. The cards that the keyboard picked are dark, but only after a key, so a mouse does not see them.
	#runLength(index) {
		const column = this.#game.columns[index];
		return column.length === 0 ? 0 : column.length - this.#runStart(column);
	}

	#dropPicked(target) {
		const {from, index} = this.#picked;
		this.#picked = undefined;

		if (target === from) {
			this.#render();
			this.say('Put back.');
			return;
		}

		if (!this.#canDrop(this.#game.columns[from][index].id, target)) {
			this.#render();
			this.#invalid(`The ${this.#cardText(this.#game.columns[from][index].id)} cannot go there. It goes on a card one higher, or in an empty column.`);
			return;
		}

		this.#move(from, index, target);
	}

	#pickUp(index) {
		const column = this.#game.columns[index];

		if (column.length === 0) {
			this.say('That column is empty.');
			return;
		}

		const count = Math.max(1, Math.min(this.#selectedCount || this.#runLength(index), this.#runLength(index)));
		this.#picked = {from: index, index: column.length - count};
		this.#render();
		this.say(`Picked up the ${this.#cardText(column[this.#picked.index].id)}${count > 1 ? ` and ${plural(count - 1, 'card')} under it` : ''}. Pick a column with Left and Right, and press Space to put them down.`);
	}

	#listenToKeyboard(columns) {
		const columnElements = this.#columnElements;

		this.on(columns, 'keydown', event => {
			const index = columnElements.indexOf(event.target);

			if (index === -1 || !this.#game || this.#game.isWon) {
				return;
			}

			this.#isKeyboardMode = true;
			const step = {ArrowLeft: -1, ArrowRight: 1}[event.key];

			if (step) {
				event.preventDefault();
				columnElements[(index + step + 10) % 10].focus();
			} else if (event.key === 'Home' || event.key === 'End') {
				event.preventDefault();
				columnElements.at(event.key === 'Home' ? 0 : -1).focus();
			} else if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
				event.preventDefault();

				if (this.#picked) {
					return;
				}

				const length = this.#runLength(index);
				this.#selectedCount = Math.max(Math.min(length, 1), Math.min(length, this.#selectedCount + (event.key === 'ArrowUp' ? 1 : -1)));
				this.#render();
				const column = this.#game.columns[index];

				if (this.#selectedCount > 0) {
					this.say(`${this.#cardText(column.at(-this.#selectedCount).id)}${this.#selectedCount > 1 ? ` and ${plural(this.#selectedCount - 1, 'card')} under it` : ''} selected.`);
				}
			} else if (event.key === ' ') {
				event.preventDefault();

				if (this.#picked) {
					this.#dropPicked(index);
				} else {
					this.#pickUp(index);
				}
			} else if (event.key === 'Escape' && this.#picked) {
				event.stopPropagation();
				this.#picked = undefined;
				this.#render();
				this.say('Put back.');
			}
		});

		// Some browsers click a button when Space comes up, which would put the cards that Space just picked up back down.
		this.on(columns, 'keyup', event => {
			if (event.key === ' ') {
				event.preventDefault();
			}
		});

		this.on(columns, 'focusin', event => {
			const index = columnElements.indexOf(event.target);

			if (index !== -1 && this.#game) {
				this.#keyboardColumn = index;

				// Tab into the columns shows the selected cards right away, as Enter moves them.
				this.#isKeyboardMode = event.target.matches(':focus-visible');

				for (const [other, element] of columnElements.entries()) {
					element.tabIndex = other === index ? 0 : -1;
				}

				// While cards are picked up, the column only shows where they would go.
				this.#selectedCount = this.#picked ? 0 : this.#runLength(index);
				this.#render();
			}
		});

		this.on(columns, 'focusout', event => {
			if (!columns.contains(event.relatedTarget) && this.#game) {
				this.#selectedCount = 0;
				this.#render();
			}
		});
	}

	#columnAt(x) {
		let nearest;
		let distance = Number.POSITIVE_INFINITY;

		for (const [index, element] of this.#columnElements.entries()) {
			const rectangle = element.getBoundingClientRect();
			const away = Math.abs(x - (rectangle.left + (rectangle.width / 2)));

			if (away < distance) {
				distance = away;
				nearest = index;
			}
		}

		return nearest;
	}

	#isOverTable(x, y) {
		const rectangle = this.parts.table.getBoundingClientRect();
		return x >= rectangle.left && x <= rectangle.right && y >= rectangle.top && y <= rectangle.bottom;
	}

	#listenToPointer(columns) {
		const columnElements = this.#columnElements;

		this.on(columns, 'pointerdown', event => {
			this.#isKeyboardMode = false;

			// Mormor stops talking when the visitor reaches for a card, as her balloon can cover the cards on a phone.
			this.parts.balloon.hidden = true;

			if (!this.#game || this.#game.isWon || this.#drag || event.ctrlKey || (event.pointerType === 'mouse' && event.button !== 0)) {
				return;
			}

			const element = event.target.closest('[data-spider-column] > span');
			const columnElement = event.target.closest('[data-spider-column]');

			if (!element || !columnElement) {
				return;
			}

			const from = columnElements.indexOf(columnElement);
			const column = this.#game.columns[from];
			const index = column.findIndex(card => card.id === this.#elementCards.get(element));

			if (index === -1 || !column[index].up || index < this.#runStart(column)) {
				return;
			}

			this.#drag = {pointerId: event.pointerId, from, index, startX: event.clientX, startY: event.clientY, isMoving: false, columnElement};
		});

		this.on(window, 'pointermove', event => {
			const drag = this.#drag;

			if (!drag || event.pointerId !== drag.pointerId) {
				return;
			}

			// A key, like Ctrl+Z, can change the columns during a drag, and then the drop puts the cards back.
			const card = this.#game.columns[drag.from][drag.index];

			if (!card) {
				return;
			}

			const x = event.clientX - drag.startX;
			const y = event.clientY - drag.startY;

			if (!drag.isMoving) {
				if (Math.hypot(x, y) < 6) {
					return;
				}

				drag.isMoving = true;
				drag.elements = this.#game.columns[drag.from].slice(drag.index).map(card => this.#cardElements.get(card.id));
				drag.offsets = this.#offsetsOf(this.#game.columns[drag.from]).slice(drag.index);
				this.#hint = undefined;
				this.#hintTimer?.cancel();
				this.#picked = undefined;

				for (const element of drag.elements) {
					element.dataset.spiderDragging = '';
				}

				drag.columnElement.setPointerCapture?.(event.pointerId);
			}

			for (const [position, element] of drag.elements.entries()) {
				element.style.translate = `${x}px ${drag.offsets[position] + y}px`;
			}

			drag.lastX = event.clientX;
			drag.lastY = event.clientY;

			const target = this.#isOverTable(event.clientX, event.clientY) ? this.#columnAt(event.clientX) : undefined;

			for (const [index, element] of columnElements.entries()) {
				element.toggleAttribute('data-spider-target', index === target && index !== drag.from && this.#canDrop(card.id, index));
			}
		});

		const endDrag = event => {
			if (!this.#drag || event.pointerId !== this.#drag.pointerId) {
				return;
			}

			const {from, index, isMoving, lastX, lastY} = this.#drag;
			this.#drag = undefined;

			if (!isMoving) {
				return;
			}

			this.#wasDragged = true;
			setTimeout(() => {
				this.#wasDragged = false;
			});

			// A key, like Ctrl+Z, can change the columns during a drag.
			if (!this.#game.columns[from][index]) {
				this.#render();
				return;
			}

			// The cards drop where the pointer last moved them, which is also where the column was highlighted.
			const target = event.type === 'pointerup' && this.#isOverTable(lastX, lastY) ? this.#columnAt(lastX) : undefined;
			const id = this.#game.columns[from][index].id;

			if (target !== undefined && target !== from && this.#canDrop(id, target)) {
				this.#move(from, index, target);
				return;
			}

			// The cards glide back to where they were.
			const rectangles = this.#cardRectangles();
			this.#render();
			this.#animate(rectangles, {});

			if (target !== undefined && target !== from) {
				this.#invalid(`The ${this.#cardText(id)} cannot go there. It goes on a card one higher, or in an empty column.`);
			}
		};

		this.on(window, 'pointerup', endDrag);
		this.on(window, 'pointercancel', endDrag);

		this.on(columns, 'click', event => {
			const columnElement = event.target.closest('[data-spider-column]');

			if (!columnElement || !this.#game || this.#wasDragged || this.#game.isWon) {
				return;
			}

			const index = columnElements.indexOf(columnElement);
			this.#resetIdle();

			// A key, or a screen reader, clicks the column itself: Enter moves the picked cards here, or the selected cards to the best place.
			if (event.detail === 0) {
				if (this.#picked) {
					this.#dropPicked(index);
					return;
				}

				const column = this.#game.columns[index];

				if (column.length > 0) {
					this.#moveToBest(index, column.length - Math.max(1, Math.min(this.#selectedCount || this.#runLength(index), this.#runLength(index))));
				}

				return;
			}

			if (this.#picked) {
				this.#dropPicked(index);
				return;
			}

			const element = event.target.closest('[data-spider-column] > span');

			if (!element) {
				this.say('Any card or run can go in an empty column. Drag it here.');
				return;
			}

			this.#moveToBest(index, this.#game.columns[index].findIndex(card => card.id === this.#elementCards.get(element)));
		});
	}

	async #showStatistics() {
		const stats = this.#loadStats();
		const played = stats.wins + stats.losses;
		const answer = await this.ask({
			title: 'Statistics',
			icon: '📊',
			text: `${difficultyNames[this.#game.suitCount]}\n\nHigh score: ${stats.best.toLocaleString('en-US')}\nWins: ${stats.wins}\nLosses: ${stats.losses}\nWin percentage: ${played === 0 ? 0 : Math.round((stats.wins / played) * 100)}%\n\nMost wins in a row: ${stats.mostWins}\nMost losses in a row: ${stats.mostLosses}\nCurrent streak: ${streakText(stats.streak)}`,
			buttons: ['OK', 'Reset'],
		});

		if (answer === 'Reset') {
			this.#saveStats(emptyStats());
			this.#renderStats();
			this.say(`The statistics of ${difficultyNames[this.#game.suitCount]} are reset.`);
		}
	}

	#commands = {
		new: () => this.#confirmNewGame(),
		restart: () => this.#restart(),
		undo: () => this.#undo(),
		deal: () => this.#dealRow(),
		hint: () => this.#showNextHint(),
		difficulty: () => this.#chooseDifficulty(),
		statistics: () => this.#showStatistics(),
		exit: () => {
			this.desktopWindow.querySelector('[data-desktop-close]').click();
		},
		rules: () => this.ask({
			title: 'Spider Solitaire Help',
			icon: '❓',
			text: 'Build eight runs from the king down to the ace, each of one suit, in the ten columns. A finished run flies off the table.\n\nAny card can go on a card one higher, of any suit, but only cards of one suit in order move together. Any card or run can go in an empty column.\n\nClick the stock at the bottom right to deal one card on each column. You cannot deal while a column is empty.\n\nThe score starts at 500. Each move and each undo costs 1 point, and each finished run gives 100.',
		}),
		about: () => this.ask({
			title: 'About Spider Solitaire',
			icon: '🕷️',
			text: 'Microsoft® Plus! 98\nSpider Solitaire\nVersion 4.10.1998\nCopyright © 1998 Microsoft Corp.\n\nThis product is licensed to:\nSindre\nPappa’s computer (do NOT install games on it)\n\nPhysical memory available to Windows: 32,768 KB\nSpider legs available: 8',
		}),
	};

	#closeMenus() {
		for (const {button, list} of this.#menus) {
			list.hidden = true;
			button.setAttribute('aria-expanded', 'false');
			delete button.dataset.state;
		}
	}

	#listenToMenus() {
		for (const {button, list} of this.#menus) {
			this.on(button, 'click', () => {
				const isOpen = list.hidden;
				this.#closeMenus();

				if (isOpen) {
					list.hidden = false;
					button.setAttribute('aria-expanded', 'true');
					button.dataset.state = 'open';
					list.querySelector('button').focus();
				}
			});

			this.on(list, 'keydown', event => {
				const items = [...list.querySelectorAll('button')];
				const index = items.indexOf(document.activeElement);

				if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
					event.preventDefault();
					items[(index + (event.key === 'ArrowDown' ? 1 : -1) + items.length) % items.length].focus();
				} else if (event.key === 'Escape') {
					event.stopPropagation();
					this.#closeMenus();
					button.focus();
				}
			});

			// Only when the focus moves to something else, like with Tab. A click outside closes the menu in its own handler.
			this.on(list, 'focusout', event => {
				if (event.relatedTarget && !list.contains(event.relatedTarget) && event.relatedTarget !== button) {
					this.#closeMenus();
				}
			});
		}

		this.on(this, 'click', event => {
			const item = event.target.closest('[data-spider-command]');

			if (!item) {
				return;
			}

			const menu = this.#menus.find(({list}) => list.contains(item));
			this.#closeMenus();
			menu?.button.focus();

			if (this.#game) {
				this.#commands[item.dataset.spiderCommand]();
			}
		});

		this.on(document, 'pointerdown', event => {
			if (!this.#menus.some(({button, list}) => button.contains(event.target) || list.contains(event.target))) {
				this.#closeMenus();
			}
		});
	}
}
