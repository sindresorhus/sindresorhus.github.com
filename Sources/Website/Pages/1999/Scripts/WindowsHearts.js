// The Microsoft Hearts Network on the desktop of the 1999 page, like Hearts of Windows 95 and 98, with the real rules, against my little sister, my grandmother, and the paperclip of Office, who talk while they play. The seats go around the table: 0 is me at the bottom, 1 is on my left, 2 is across, and 3 is on my right, and the play goes in that order. Nothing makes a sound until the visitor presses the Sound button.

const randomItem = items => items[Math.floor(Math.random() * items.length)];

const names = ['You', 'Lillesøster', 'Mormor', 'Clippy'];

// A card is a number: the suit times 13, plus the rank from the two to the ace. The suits are in the order of the hand of Windows Hearts.
const clubs = 0;
const diamonds = 1;
const spades = 2;
const hearts = 3;
const suitSymbols = ['♣', '♦', '♠', '♥'];
const suitNames = ['clubs', 'diamonds', 'spades', 'hearts'];
const rankSymbols = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
const rankNames = ['two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'jack', 'queen', 'king', 'ace'];
const suitOf = card => Math.floor(card / 13);
const rankOf = card => card % 13;
const isRed = card => suitOf(card) === diamonds || suitOf(card) === hearts;
const queenOfSpades = (spades * 13) + 10;
const twoOfClubs = clubs * 13;
const cardText = card => `${rankSymbols[rankOf(card)]}${suitSymbols[suitOf(card)]}`;
const cardName = card => `${rankNames[rankOf(card)]} of ${suitNames[suitOf(card)]}`;
const pointsOf = card => (suitOf(card) === hearts ? 1 : (card === queenOfSpades ? 13 : 0));

// The passes of the hands, in turn, by how many seats around the table the cards go.
const passes = [
	{name: 'Left', offset: 1},
	{name: 'Right', offset: 3},
	{name: 'Across', offset: 2},
	{name: 'Hold', offset: 0},
];

// What the opponents say, by what happened. Each line is picked at random.
const lines = {
	deal: {
		1: ['Deal faster, Sindre. I have to call Ingrid.', 'If I win, I get the computer for an hour.', 'Mamma said you have to let me win.'],
		2: ['Oh, how nice, cards! Have a waffle first, dear.', 'I played this with your grandfather every Sunday.', 'Now, which ones are the hearts again?'],
		3: ['It looks like you’re playing Hearts. Would you like help?', 'Tip: The object of Hearts is to not get hearts. Ironic, isn’t it?', 'I am also available in Word, Excel, and PowerPoint.'],
	},
	pass: {
		1: ['I gave you my worst cards. You’re welcome.', 'Ha ha! Good luck with THOSE.'],
		2: ['I passed you something nice, dear.', 'I kept the pretty ones. I hope that is allowed.'],
		3: ['It looks like you’re trying to pass cards. I passed you mine. No need to thank me.', 'I passed you three cards. Would you like me to pass them back?'],
	},
	queenTaken: {
		1: ['MAMMA!!! He gave me the Queen!', 'That is SO unfair. I am telling Pappa.', 'I did not even want her.'],
		2: ['Oh, the Queen! Isn’t she lovely? Is that bad?', 'Oh my. Thirteen points. Well, I am old enough to take it.'],
		3: ['It looks like I took the Queen of Spades. Would you like to undo? (You cannot.)', 'Error: Queen not found. Oh wait. She is right here. In my pile.'],
	},
	queenGiven: {
		1: ['Ha ha ha! The Queen is YOURS!', 'Enjoy your girlfriend, Sindre!'],
		2: ['Oops. Sorry, dear. She slipped.', 'I am so sorry. Have two waffles.'],
		3: ['It looks like you just got the Queen of Spades. Would you like help crying?', 'I put the Queen on your trick. You looked like you needed company.'],
	},
	broken: {
		0: {2: ['That’s alright, dear. Hearts heal.'], 1: ['YOU broke the hearts! I saw it!'], 3: ['It looks like you broke the hearts. Would you like to send them to the Recycle Bin?']},
		1: ['Oops. Hearts are broken. Like my heart when you took the phone line.'],
		2: ['Oh dear, I broke the hearts. I will knit new ones.'],
		3: ['Hearts are broken. Would you like to run ScanDisk?'],
	},
	trick: {
		1: ['Mine! No points! Ha ha!', 'Hurry up, Mormor!'],
		2: ['Oh, look, I won something.', 'Was that my turn? I was looking for my glasses.'],
		3: ['It looks like I won a trick. Would you like a tutorial on how I did it?', 'Tip: Press F1 for help. (F1 does nothing.)'],
	},
	slow: ['Sindre, HURRY UP!', 'I am going to be 13 before you play a card.', 'MAMMA! He is not playing!'],
	moonTry: 'It looks like you’re trying to shoot the moon. Would you like help?',
	moonYou: {
		1: ['WHAT?! That is cheating. MAMMA!'],
		2: ['You shot the moon! Your grandfather did that once, in 1957.'],
		3: ['It looks like you shot the moon. I will now go and sit in the Recycle Bin.'],
	},
	moonThem: {
		1: 'I shot the MOON! I am the best! Sindre is the worst!',
		2: 'Oh my, did I take all of them? I thought hearts were good.',
		3: 'It looks like I shot the moon. I am a paperclip AND an astronaut.',
	},
	win: {
		1: 'Ugh. You only won because Mormor helped you.',
		2: 'Well done, dear! I always knew you were the clever one.',
		3: 'Congratulations! It looks like you won. Would you like to write a letter about it?',
	},
	lose: {
		1: 'I WON! I WON! I get the computer now! Bye!',
		2: 'Oh, did I win? How lovely. Now, who wants waffles?',
		3: 'It looks like I won. I would like to thank Microsoft Office 97.',
	},
};

// The opponents think for a while, so a human can follow, and Mormor thinks the longest.
const thinkingTime = {1: 450, 2: 1300, 3: 750};

const sortHand = hand => hand.sort((first, second) => first - second);

const shuffledDeck = () => {
	const deck = Array.from({length: 52}, (_, index) => index);

	for (let index = deck.length - 1; index > 0; index--) {
		const other = Math.floor(Math.random() * (index + 1));
		[deck[index], deck[other]] = [deck[other], deck[index]];
	}

	return deck;
};

// The rules of what a player can play now.
const legalCards = (game, seat) => {
	const hand = game.hands[seat];

	if (game.trick.length === 0) {
		if (game.trickNumber === 0) {
			return hand.filter(card => card === twoOfClubs);
		}

		const withoutHearts = hand.filter(card => suitOf(card) !== hearts);
		return game.heartsBroken || withoutHearts.length === 0 ? [...hand] : withoutHearts;
	}

	const ledSuit = suitOf(game.trick[0].card);
	const following = hand.filter(card => suitOf(card) === ledSuit);

	if (following.length > 0) {
		return following;
	}

	// No points on the first trick, unless the hand has nothing else.
	if (game.trickNumber === 0) {
		const withoutPoints = hand.filter(card => pointsOf(card) === 0);

		if (withoutPoints.length > 0) {
			return withoutPoints;
		}
	}

	return [...hand];
};

// Why a card cannot be played, for the status.
const whyIllegal = (game, card) => {
	if (game.trick.length === 0) {
		if (game.trickNumber === 0) {
			return 'The 2♣ leads the first trick.';
		}

		return `Hearts are not broken yet, so you cannot lead the ${cardText(card)}.`;
	}

	const ledSuit = suitOf(game.trick[0].card);

	if (game.hands[0].some(other => suitOf(other) === ledSuit)) {
		return `You must follow suit: play a ${suitSymbols[ledSuit]}.`;
	}

	return 'No points on the first trick: no hearts and no Q♠.';
};

// The card that wins the trick so far: the highest of the suit that was led.
const winningPlay = trick => {
	const ledSuit = suitOf(trick[0].card);
	let best = trick[0];

	for (const play of trick) {
		if (suitOf(play.card) === ledSuit && rankOf(play.card) > rankOf(best.card)) {
			best = play;
		}
	}

	return best;
};

const byRank = cards => [...cards].sort((first, second) => rankOf(first) - rankOf(second));
const highest = cards => byRank(cards).at(-1);
const lowest = cards => byRank(cards)[0];

const pointsOfTrick = trick => {
	let sum = 0;

	for (const play of trick) {
		sum += pointsOf(play.card);
	}

	return sum;
};
const isQueenOut = game => !game.played.has(queenOfSpades);

// The three cards an opponent passes: the queen of spades and her guards, high hearts, and the cards of a short suit, so the hand gets void in it.
const choosePass = (game, seat) => {
	const hand = game.hands[seat];
	const counts = [0, 0, 0, 0];

	for (const card of hand) {
		counts[suitOf(card)]++;
	}

	const danger = card => {
		const suit = suitOf(card);
		const rank = rankOf(card);

		if (suit === spades) {
			// With many spades, the queen is safe, as the hand can always play under her.
			return counts[spades] >= 5 ? rank : (rank >= 10 ? 80 + rank : rank);
		}

		if (suit === hearts) {
			return 40 + rank;
		}

		return (rank * 3) + (counts[suit] <= 3 ? 12 : 0);
	};

	return [...hand].sort((first, second) => danger(second) - danger(first)).slice(0, 3);
};

// The card an opponent plays. It dumps the queen of spades when it can, ducks under the winning card, and gets rid of high cards when it is void.
const chooseCard = (game, seat) => {
	const hand = game.hands[seat];
	const legal = legalCards(game, seat);

	if (legal.length === 1) {
		return legal[0];
	}

	if (game.moonTry[seat]) {
		if (game.trick.length === 0) {
			return highest(legal);
		}

		const winner = winningPlay(game.trick).card;
		const winners = legal.filter(card => suitOf(card) === suitOf(winner) && rankOf(card) > rankOf(winner));
		return winners.length > 0 ? highest(winners) : lowest(legal);
	}

	if (game.trick.length === 0) {
		// Fishing for the queen: a spade below her makes whoever has her play under, or take her.
		const lowSpades = legal.filter(card => suitOf(card) === spades && rankOf(card) < 10);
		const hasHighSpade = hand.some(card => suitOf(card) === spades && rankOf(card) >= 10);

		if (isQueenOut(game) && !hasHighSpade && lowSpades.length > 0) {
			return highest(lowSpades);
		}

		// Otherwise a low card of the shortest suit, to get void in it, but not spades while holding the queen.
		const counts = [0, 0, 0, 0];

		for (const card of hand) {
			counts[suitOf(card)]++;
		}

		const options = legal.filter(card => suitOf(card) !== hearts && !(suitOf(card) === spades && hand.includes(queenOfSpades)));
		const pool = options.length > 0 ? options : legal;
		const shortest = Math.min(...pool.map(card => counts[suitOf(card)]));
		return lowest(pool.filter(card => counts[suitOf(card)] === shortest));
	}

	const ledSuit = suitOf(game.trick[0].card);
	const winner = winningPlay(game.trick).card;
	const isLast = game.trick.length === 3;
	const trickPoints = pointsOfTrick(game.trick);

	if (suitOf(legal[0]) === ledSuit) {
		// The queen goes under a king or an ace of spades.
		if (legal.includes(queenOfSpades) && rankOf(winner) > 10) {
			return queenOfSpades;
		}

		const under = legal.filter(card => rankOf(card) < rankOf(winner) && card !== queenOfSpades);

		if (under.length > 0) {
			return highest(under);
		}

		const safe = legal.filter(card => card !== queenOfSpades);
		const pool = safe.length > 0 ? safe : legal;

		if (isLast && trickPoints === 0) {
			return highest(pool);
		}

		// Above the queen of spades, a high spade could catch her, so the lowest goes.
		if (ledSuit === spades && isQueenOut(game) && !hand.includes(queenOfSpades)) {
			return lowest(pool);
		}

		return highest(pool);
	}

	// Void in the suit that was led: get rid of the worst cards.
	if (legal.includes(queenOfSpades)) {
		return queenOfSpades;
	}

	const highSpades = legal.filter(card => suitOf(card) === spades && rankOf(card) > 10);

	if (isQueenOut(game) && highSpades.length > 0) {
		return highest(highSpades);
	}

	const heartCards = legal.filter(card => suitOf(card) === hearts);

	if (heartCards.length > 0) {
		return highest(heartCards);
	}

	return highest(legal);
};

// An opponent tries to shoot the moon with many high hearts and high cards, and gives up when somebody else takes a point.
const wantsMoon = (game, seat) => {
	const hand = game.hands[seat];
	const highHearts = hand.filter(card => suitOf(card) === hearts && rankOf(card) >= 9).length;
	const highCards = hand.filter(card => rankOf(card) >= 9).length;
	return highHearts >= 3 && highCards >= 8;
};

export default class extends GeoCitiesElement {
	#game;
	// Each game has a number, so the opponents of a game that was given up stop playing.
	#gameRun = 0;
	#focusedIndex = 0;
	#slowTimer;
	#scoreElements;
	#totalElements;
	#trickSlots;
	#balloons;

	// The speech balloons hide after a while, each with its own timer.
	#balloonTimers = new Map();

	#resumeWaiters = [];

	connected() {
		const {hand, action, sheetToggle, newGame, sound} = this.parts;
		this.#scoreElements = [0, 1, 2, 3].map(seat => this.querySelector(`[data-hearts-score="${seat}"]`));
		this.#totalElements = [0, 1, 2, 3].map(seat => this.querySelector(`[data-hearts-total="${seat}"]`));
		this.#trickSlots = [0, 1, 2, 3].map(seat => this.querySelector(`[data-hearts-trick="${seat}"]`));
		this.#balloons = [undefined, 1, 2, 3].map(seat => seat && this.querySelector(`[data-hearts-balloon="${seat}"]`));

		this.on(document, 'visibilitychange', () => {
			this.#resumeWaits();
		});

		this.on(sound, 'click', () => {
			const isOn = !this.#isSoundOn;
			sound.setAttribute('aria-pressed', String(isOn));

			if (isOn) {
				// The desktop starts its audio in the handler of this click, as browsers only allow sound after one.
				this.sound();
				this.#sounds.card();
			}
		});

		// The hand: a click picks a card to pass or plays it.
		this.on(hand, 'click', event => {
			const button = event.target.closest('button');

			if (button) {
				this.#cardClicked(button);
			}
		});

		// The arrow keys move between the cards, like a toolbar, and Enter or Space picks or plays the card.
		this.on(hand, 'keydown', event => {
			const buttons = [...hand.querySelectorAll('button')];
			const index = buttons.indexOf(event.target);
			const step = {ArrowLeft: -1, ArrowUp: -1, ArrowRight: 1, ArrowDown: 1}[event.key];
			let next;

			if (step) {
				next = (index + step + buttons.length) % buttons.length;
			} else if (event.key === 'Home') {
				next = 0;
			} else if (event.key === 'End') {
				next = buttons.length - 1;
			}

			if (next === undefined || index === -1) {
				return;
			}

			event.preventDefault();
			buttons[index].tabIndex = -1;
			buttons[next].tabIndex = 0;
			buttons[next].focus();
			this.#focusedIndex = next;
		});

		this.on(action, 'click', () => {
			const game = this.#game;

			if (game.phase === 'pass' && game.picked.size === 3) {
				this.#passCards();
			} else if (game.phase === 'over') {
				this.#setSheetOpen(false);
				this.#startHand();
			} else if (game.phase === 'gameover') {
				this.#newGame();
			}
		});

		this.on(sheetToggle, 'click', () => {
			this.#setSheetOpen(this.parts.sheet.hidden);
		});

		this.on(newGame, 'click', async () => {
			const game = this.#game;

			if (game.history.length === 0 && game.trickNumber === 0 && game.phase === 'pass') {
				this.#newGame();
				return;
			}

			const answer = await this.ask({
				title: 'Hearts',
				icon: '♥️',
				text: 'Do you want to give up this game and start a new one? Lillesøster will say that she won.',
				buttons: ['Yes', 'No'],
				opener: newGame,
			});

			if (answer === 'Yes') {
				this.#newGame();
			}
		});
	}

	// The first game is dealt when the window opens.
	windowChanged(isOpen) {
		if (isOpen && !this.#game) {
			this.#renderWins();
			this.#newGame();
		}

		this.#resumeWaits();
	}

	// The pauses of the game wait while its window is closed or the tab is hidden, so the others do not play on, and click their cards, without the visitor.
	get #isPaused() {
		return this.desktopWindow.hidden || document.hidden;
	}

	async #wait(milliseconds) {
		await new Promise(resolve => {
			this.timeout(milliseconds, resolve);
		});

		while (this.#isPaused) {
			await new Promise(resolve => {
				this.#resumeWaiters.push(resolve);
			});
		}
	}

	#resumeWaits() {
		if (!this.#isPaused) {
			for (const resolve of this.#resumeWaiters.splice(0)) {
				resolve();
			}
		}
	}

	// What the opponents say, in their speech balloons.
	#speak(seat, text) {
		if (!text) {
			return;
		}

		const balloon = this.#balloons[seat];
		balloon.textContent = text;
		balloon.hidden = false;
		this.#balloonTimers.get(seat)?.cancel();
		this.#balloonTimers.set(seat, this.timeout(4500, () => {
			balloon.hidden = true;
		}));
	}

	#speakLine(seat, group) {
		this.#speak(seat, randomItem(lines[group][seat]));
	}

	get #isSoundOn() {
		return this.parts.sound.getAttribute('aria-pressed') === 'true';
	}

	// The sounds, made with tones. The audio comes from the desktop, which plays it through the volume of the tray.
	#tone(frequency, start, duration, {type = 'triangle', volume = 0.12, slide} = {}) {
		const sound = this.#isSoundOn && !this.#isPaused ? this.sound() : undefined;

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

	#sounds = {
		card: () => {
			this.#tone(1800, 0, 0.04, {type: 'square', volume: 0.04});
		},
		take: () => {
			this.#tone(520, 0, 0.08, {volume: 0.08});
			this.#tone(390, 0.08, 0.12, {volume: 0.08});
		},
		queen: () => {
			this.#tone(220, 0, 0.6, {type: 'sawtooth', volume: 0.08, slide: 90});
		},
		broken: () => {
			this.#tone(880, 0, 0.12);
			this.#tone(660, 0.12, 0.25);
		},
		moon: () => {
			for (const [index, frequency] of [523.25, 659.25, 783.99, 1046.5, 1318.5].entries()) {
				this.#tone(frequency, index * 0.1, 0.4);
			}
		},
		win: () => {
			for (const [index, frequency] of [523.25, 659.25, 783.99, 1046.5].entries()) {
				this.#tone(frequency, index * 0.15, index === 3 ? 0.8 : 0.2, {type: 'square', volume: 0.06});
			}
		},
		lose: () => {
			for (const [index, frequency] of [392, 369.99, 349.23, 329.63].entries()) {
				this.#tone(frequency, index * 0.3, index === 3 ? 0.9 : 0.28, {type: 'sawtooth', volume: 0.06});
			}
		},
	};

	// Drawing.
	#makeCardButton(card) {
		const button = this.parts.cardTemplate.content.firstElementChild.cloneNode(true);
		const [rank, suit] = button.querySelectorAll('span');
		rank.textContent = rankSymbols[rankOf(card)];
		suit.textContent = suitSymbols[suitOf(card)];

		if (isRed(card)) {
			button.dataset.heartsRed = '';
		}

		return button;
	}

	get #isMyTurn() {
		return this.#game.phase === 'play' && this.#game.turn === 0;
	}

	#renderHand() {
		const game = this.#game;
		const {hand} = this.parts;
		const hadFocus = hand.contains(document.activeElement);
		const legal = this.#isMyTurn ? legalCards(game, 0) : undefined;
		const buttons = game.hands[0].map(card => {
			const button = this.#makeCardButton(card);
			let label = cardName(card);

			if (game.phase === 'pass') {
				const isPicked = game.picked.has(card);
				button.setAttribute('aria-pressed', String(isPicked));

				if (isPicked) {
					button.dataset.state = 'picked';
				}
			} else if (legal && !legal.includes(card)) {
				button.dataset.state = 'illegal';
				label += ', cannot be played now';
			} else if (game.received.includes(card)) {
				button.dataset.state = 'received';
				label += ', passed to you';
			}

			button.setAttribute('aria-label', label);
			button.tabIndex = -1;
			return button;
		});

		hand.replaceChildren(...buttons);
		this.#focusedIndex = Math.min(this.#focusedIndex, buttons.length - 1);

		if (buttons.length > 0) {
			buttons[this.#focusedIndex].tabIndex = 0;

			if (hadFocus) {
				buttons[this.#focusedIndex].focus();
			}
		} else if (hadFocus) {
			this.desktopWindow.focus();
		}
	}

	#renderScores() {
		for (const [seat, element] of this.#scoreElements.entries()) {
			const taken = this.#game.taken[seat];
			element.textContent = taken > 0 ? `${this.#game.scores[seat]} (+${taken})` : String(this.#game.scores[seat]);
		}
	}

	#renderSlot(seat, card, state = 'played') {
		const slot = this.#trickSlots[seat];

		if (card === undefined) {
			slot.textContent = '';
			delete slot.dataset.state;
			delete slot.dataset.heartsRed;
			slot.setAttribute('aria-label', 'No card');
			return;
		}

		slot.textContent = cardText(card);
		slot.dataset.state = state === 'winner' ? 'winner' : 'played';

		if (isRed(card)) {
			slot.dataset.heartsRed = '';
		} else {
			delete slot.dataset.heartsRed;
		}

		slot.setAttribute('aria-label', `${names[seat]}: ${cardName(card)}`);
	}

	#renderSheet() {
		this.parts.sheetRows.replaceChildren(...this.#game.history.map((points, index) => {
			const row = document.createElement('tr');
			const heading = document.createElement('th');
			heading.scope = 'row';
			heading.textContent = String(index + 1);
			row.append(heading);

			for (const value of points) {
				const cell = document.createElement('td');
				cell.textContent = String(value);
				row.append(cell);
			}

			return row;
		}));

		for (const [seat, element] of this.#totalElements.entries()) {
			element.textContent = String(this.#game.scores[seat]);
		}
	}

	#setSheetOpen(isOpen) {
		this.parts.sheet.hidden = !isOpen;
		this.parts.sheetToggle.setAttribute('aria-expanded', String(isOpen));
	}

	#renderWins() {
		const record = this.stored('record', {played: 0, won: 0});
		this.parts.wins.textContent = record.played > 0
			? `Games won: ${record.won} of ${record.played}.${record.best === undefined ? '' : ` Best win: ${record.best} points.`}`
			: 'Get the fewest points. Hearts are 1 point each, and the Q♠ is 13.';
	}

	// The action button is the button of the next step, like Pass Left or Next Hand, and hides while the cards are played. Its focus goes to the hand then.
	#focusHand() {
		(this.parts.hand.querySelector('[tabindex="0"]') ?? this.desktopWindow).focus();
	}

	#showAction(text, isEnabled = true) {
		const {action} = this.parts;
		const hadFocus = action === document.activeElement;
		action.textContent = text;
		action.disabled = !isEnabled;
		action.hidden = false;

		if (hadFocus && !isEnabled) {
			this.#focusHand();
		} else if (isEnabled && document.activeElement === this.desktopWindow) {
			action.focus();
		}
	}

	#hideAction() {
		const {action} = this.parts;

		if (action === document.activeElement) {
			this.#focusHand();
		}

		action.hidden = true;
	}

	// The game.
	#passOf() {
		return passes[this.#game.handNumber % 4];
	}

	#startHand() {
		const game = this.#game;
		const deck = shuffledDeck();
		game.hands = [0, 1, 2, 3].map(seat => sortHand(deck.slice(seat * 13, (seat + 1) * 13)));
		game.taken = [0, 0, 0, 0];
		game.tricksTaken = [0, 0, 0, 0];
		game.trick = [];
		game.played = new Set();
		game.picked = new Set();
		game.received = [];
		game.heartsBroken = false;
		game.trickNumber = 0;
		game.moonTry = [false, false, false, false];
		game.clippyAsked = false;
		this.#focusedIndex = 0;

		for (const seat of [0, 1, 2, 3]) {
			this.#renderSlot(seat);
		}

		this.#renderScores();
		this.#speakLine(randomItem([1, 2, 3]), 'deal');
		const pass = this.#passOf();

		if (pass.offset === 0) {
			game.phase = 'wait';
			this.#renderHand();
			this.say(`Hand ${game.handNumber + 1}: no passing this time. Hold on to your cards.`);
			this.#beginPlay();
			return;
		}

		game.phase = 'pass';
		this.#renderHand();
		this.#showAction(`Pass ${pass.name}`, false);
		this.say(`Hand ${game.handNumber + 1}: pick three cards to pass to ${names[pass.offset]}, then press Pass ${pass.name}.`);
	}

	#passCards() {
		const game = this.#game;
		const {offset} = this.#passOf();
		const chosen = [0, 1, 2, 3].map(seat => (seat === 0 ? [...game.picked] : choosePass(game, seat)));

		for (const [seat, cards] of chosen.entries()) {
			game.hands[seat] = game.hands[seat].filter(card => !cards.includes(card));
		}

		for (const [seat, cards] of chosen.entries()) {
			const receiver = (seat + offset) % 4;
			game.hands[receiver] = sortHand([...game.hands[receiver], ...cards]);
		}

		const giver = (4 - offset) % 4;
		game.received = chosen[giver];
		game.picked = new Set();
		this.#speakLine(giver, 'pass');
		this.#sounds.card();
		this.say(`${names[giver]} passed you ${game.received.map(card => cardText(card)).join(', ')}.`);
		game.phase = 'wait';
		this.#focusedIndex = game.hands[0].indexOf(game.received[0]);
		this.#renderHand();
		this.#beginPlay();
	}

	async #beginPlay() {
		const game = this.#game;
		const run = this.#gameRun;
		this.#hideAction();
		game.leader = game.hands.findIndex(hand => hand.includes(twoOfClubs));
		// Nobody has a turn in the pause before the first trick.
		game.turn = undefined;

		for (const seat of [1, 3]) {
			game.moonTry[seat] = wantsMoon(game, seat);
		}

		await this.#wait(900);

		if (run === this.#gameRun) {
			this.#nextTurn();
		}
	}

	async #nextTurn() {
		const game = this.#game;
		const run = this.#gameRun;

		if (game.trick.length === 4) {
			this.#finishTrick();
			return;
		}

		game.turn = (game.leader + game.trick.length) % 4;

		if (game.turn === 0) {
			game.phase = 'play';
			this.#renderHand();
			const legal = legalCards(game, 0);
			const hint = game.trick.length === 0
				? (game.trickNumber === 0 ? 'Your turn: lead the 2♣.' : 'Your turn: lead a card.')
				: `Your turn: ${legal.some(card => suitOf(card) === suitOf(game.trick[0].card)) ? `follow ${suitSymbols[suitOf(game.trick[0].card)]}` : 'you have none of the suit, so play any card'}.`;
			this.say(hint);

			// My little sister has no patience.
			this.#slowTimer?.cancel();
			this.#slowTimer = this.timeout(15_000, () => {
				if (run === this.#gameRun && this.#isMyTurn) {
					this.#speak(1, randomItem(lines.slow));
				}
			});
			return;
		}

		game.phase = 'wait';
		this.#renderHand();

		if (game.turn === 2 && Math.random() < 0.15) {
			this.say('Mormor is looking for her glasses…');
			await this.#wait(1500);
		}

		await this.#wait(thinkingTime[game.turn]);

		if (run !== this.#gameRun) {
			return;
		}

		this.#playCard(game.turn, chooseCard(game, game.turn));
		this.#nextTurn();
	}

	#playCard(seat, card) {
		const game = this.#game;
		game.hands[seat] = game.hands[seat].filter(other => other !== card);
		game.trick.push({seat, card});
		game.played.add(card);
		this.#renderSlot(seat, card);
		this.#sounds.card();

		if (suitOf(card) === hearts && !game.heartsBroken) {
			game.heartsBroken = true;
			this.#sounds.broken();

			if (seat === 0) {
				const speaker = randomItem([1, 2, 3]);
				this.#speak(speaker, lines.broken[0][speaker][0]);
			} else {
				this.#speak(seat, lines.broken[seat][0]);
			}
		}
	}

	async #finishTrick() {
		const game = this.#game;
		const run = this.#gameRun;
		game.phase = 'wait';
		this.#renderHand();
		const winner = winningPlay(game.trick);
		const points = pointsOfTrick(game.trick);
		const queen = game.trick.find(play => play.card === queenOfSpades);
		this.#renderSlot(winner.seat, winner.card, 'winner');
		this.say(`${winner.seat === 0 ? 'You take' : `${names[winner.seat]} takes`} the trick${points > 0 ? `, with ${points} point${points === 1 ? '' : 's'}` : ''}.`);

		if (queen) {
			this.#sounds.queen();

			if (winner.seat === 0) {
				if (queen.seat !== 0) {
					this.#speakLine(queen.seat, 'queenGiven');
				}
			} else {
				this.#speakLine(winner.seat, 'queenTaken');
			}
		} else if (winner.seat !== 0 && points === 0 && Math.random() < 0.25) {
			this.#speakLine(winner.seat, 'trick');
		} else {
			this.#sounds.take();
		}

		game.taken[winner.seat] += points;
		game.tricksTaken[winner.seat]++;

		// An opponent gives up on the moon when somebody else takes a point.
		for (const seat of [1, 3]) {
			if (game.moonTry[seat] && game.taken.some((taken, other) => other !== seat && taken > 0)) {
				game.moonTry[seat] = false;
			}
		}

		// When I take every point so far, the paperclip has a tip.
		const othersTaken = game.taken[1] + game.taken[2] + game.taken[3];

		if (!game.clippyAsked && game.taken[0] >= 8 && othersTaken === 0) {
			game.clippyAsked = true;
			this.#speak(3, lines.moonTry);
		}

		this.#renderScores();
		await this.#wait(1100);

		if (run !== this.#gameRun) {
			return;
		}

		for (const seat of [0, 1, 2, 3]) {
			this.#renderSlot(seat);
		}

		game.trick = [];
		game.leader = winner.seat;
		game.trickNumber++;

		if (game.trickNumber === 13) {
			this.#endHand();
		} else {
			this.#nextTurn();
		}
	}

	#endHand() {
		const game = this.#game;
		game.phase = 'over';
		const moonSeat = game.taken.indexOf(26);
		const points = moonSeat === -1 ? [...game.taken] : game.taken.map((_, seat) => (seat === moonSeat ? 0 : 26));

		if (moonSeat === 0) {
			this.#sounds.moon();

			for (const seat of [1, 2, 3]) {
				this.#speakLine(seat, 'moonYou');
			}
		} else if (moonSeat > 0) {
			this.#sounds.moon();
			this.#speak(moonSeat, lines.moonThem[moonSeat]);
		}

		game.history.push(points);
		game.scores = game.scores.map((score, seat) => score + points[seat]);
		game.taken = [0, 0, 0, 0];
		this.#renderScores();
		this.#renderSheet();
		this.#setSheetOpen(true);
		this.#renderHand();
		game.handNumber++;
		const moonText = moonSeat === 0 ? 'You shot the moon! Everybody else gets 26 points. ' : (moonSeat > 0 ? `${names[moonSeat]} shot the moon! Everybody else gets 26 points. ` : '');

		if (Math.max(...game.scores) < 100) {
			this.say(`${moonText}End of hand ${game.handNumber}. You took ${points[0]} point${points[0] === 1 ? '' : 's'}, and you have ${game.scores[0]} in all. The game ends at 100.`);
			this.#showAction('Next Hand');
			return;
		}

		// The game is over when a player has 100 points, and the lowest score wins.
		const best = Math.min(...game.scores);
		const winners = [0, 1, 2, 3].filter(seat => game.scores[seat] === best);
		const record = this.stored('record', {played: 0, won: 0});
		record.played++;

		if (winners.includes(0)) {
			record.won++;
			record.best = Math.min(record.best ?? Number.POSITIVE_INFINITY, game.scores[0]);
			this.#sounds.win();

			for (const seat of [1, 2, 3]) {
				this.#speak(seat, lines.win[seat]);
			}

			this.celebrate();
			this.say(`${moonText}Game over. You win with ${game.scores[0]} points!`);
		} else {
			this.#sounds.lose();
			const winner = winners.find(seat => seat !== 0);
			this.#speak(winner, lines.lose[winner]);
			this.say(`${moonText}Game over. ${winners.map(seat => names[seat]).join(' and ')} ${winners.length === 1 ? 'wins' : 'win'} with ${best} points. You have ${game.scores[0]}.`);
		}

		this.store('record', record);
		this.#renderWins();
		game.phase = 'gameover';
		this.#showAction('Play Again');
	}

	#newGame() {
		this.#gameRun++;
		this.#slowTimer?.cancel();
		this.#game = {scores: [0, 0, 0, 0], history: [], handNumber: 0};
		this.#renderSheet();
		this.#setSheetOpen(false);

		for (const seat of [1, 2, 3]) {
			this.#balloons[seat].hidden = true;
		}

		this.#startHand();
	}

	#cardClicked(button) {
		const game = this.#game;
		const {hand, action} = this.parts;
		this.#focusedIndex = [...hand.children].indexOf(button);
		const card = game.hands[0][this.#focusedIndex];

		if (game.phase === 'pass') {
			if (game.picked.has(card)) {
				game.picked.delete(card);
			} else if (game.picked.size < 3) {
				game.picked.add(card);
			} else {
				this.say('You can only pass three cards. Click a picked card to put it back.');
				return;
			}

			action.disabled = game.picked.size !== 3;
			this.#renderHand();
			this.say(game.picked.size === 3 ? `Ready. Press Pass ${this.#passOf().name}.` : `${game.picked.size} of 3 cards picked.`);
			return;
		}

		if (!this.#isMyTurn) {
			const waiting = game.phase === 'over' || game.phase === 'gameover' ? 'The hand is over.' : (game.turn === undefined || game.turn === 0 ? 'Wait a moment, the hand is about to start.' : `Wait for your turn. ${names[game.turn]} is thinking.`);
			this.say(waiting);
			return;
		}

		if (!legalCards(game, 0).includes(card)) {
			this.say(whyIllegal(game, card));
			return;
		}

		this.#slowTimer?.cancel();
		game.received = [];
		game.phase = 'wait';
		this.#playCard(0, card);
		this.#nextTurn();
	}
}
