// The Game Room of the 1999 page: the small games of the web of 1999, each in a window: a slot machine, a unicorn race, Simon, memory, Hangman, Rock Paper Scissors against Rocky, a reaction test, a typing tutor, and Yatzy. The coin games take the coins of the arcade (`Arcade.js`), and every game gives tickets for its Prize Counter. With reduced motion, the reels, the race, and the dice show only where they stop. The best scores are kept in the browser.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const count = value => Math.max(Math.round(Number(value) || 0), 0);
const plural = (amount, word) => `${amount.toLocaleString('en-US')} ${word}${amount === 1 ? '' : 's'}`;

const shuffle = items => {
	const copy = [...items];

	for (let index = copy.length - 1; index > 0; index--) {
		const other = Math.floor(Math.random() * (index + 1));
		[copy[index], copy[other]] = [copy[other], copy[index]];
	}

	return copy;
};

const setUpGameRoom = (room, {slotPull, slotStatus, derbyPick, derbyBet, derbyStart, derbyStatus, simonBoard, simonStart, simonStatus, memoryBoard, memoryStatus, memoryRestart, hangmanDrawing, hangmanWord, hangmanHint, hangmanKeys, hangmanStatus, hangmanNew, rpsScore, rpsStatus, rpsVisit, yatzyRoll, yatzyStatus, yatzyBonus, yatzyTotal, reactionButton, reactionStatus, reactionBest, typingText, typingLabel, typingInput, typingStatus, typingNew}) => {
	// The arcade keeps the coins, the tickets, and the sound, so the coin games take the coins of the arcade, and every game gives tickets for its Prize Counter. It is found once, and its methods are only called on a click, when its script has run.
	const arcade = document.querySelector('geo-cities-arcade');

	// The Brown Cheese Bandit: a slot machine with three reels. It takes the coins of the arcade.
	const reels = [...room.querySelectorAll('[data-part="reel"]')];
	// Each reel has more cherries than brown cheese, like a real slot machine, which wins less than it looks. It pays back about 90% of the coins.
	const reelSymbols = ['🍒', '🍒', '🍒', '🍒', '🧇', '🧇', '🧇', '🦄', '🦄', '🐛', '🐛', '🟫', '🟫'];
	let isSpinning = false;

	const payout = symbols => {
		const [first, second, third] = symbols;
		const isThree = first === second && second === third;
		const brownCheese = symbols.filter(symbol => symbol === '🟫').length;

		if (isThree) {
			return {'🟫': 50, '🧇': 10, '🦄': 15, '🐛': 19, '🍒': 5}[first];
		}

		if (brownCheese === 2) {
			return 2;
		}

		return symbols.filter(symbol => symbol === '🍒').length === 2 ? 1 : 0;
	};

	room.on(slotPull, 'click', async () => {
		if (isSpinning) {
			return;
		}

		if (!arcade.spendCoins(1)) {
			room.say('No coins! Ask Mom at the arcade.', slotStatus);
			return;
		}

		isSpinning = true;
		const result = reels.map(() => randomItem(reelSymbols));

		for (const reel of reels) {
			reel.dataset.state = '';
		}

		// The reels spin together and stop one after the other, unless the visitor prefers less motion.
		if (!room.reducedMotion) {
			const start = performance.now();
			const stopTimes = reels.map((_, index) => start + 600 + (index * 400));
			let stopped = 0;

			while (stopped < reels.length) {
				const now = performance.now();

				for (const [index, reel] of reels.entries()) {
					if (index < stopped) {
						continue;
					}

					if (now >= stopTimes[index] && index === stopped) {
						reel.textContent = result[index];
						stopped++;
						arcade.beep(200, 0.08);
					} else {
						reel.textContent = randomItem(reelSymbols);
					}
				}

				arcade.beep(300 + (Math.random() * 300), 0.03, {volume: 0.02});
				await room.wait(60);
			}
		}

		for (const [index, reel] of reels.entries()) {
			reel.textContent = result[index];
		}

		const won = payout(result);
		arcade.addCoins(won);
		arcade.addTickets(1);
		isSpinning = false;

		if (won > 0) {
			for (const reel of reels) {
				reel.dataset.state = 'win';
			}

			arcade.sounds.coin();
		}

		const symbols = result.join(' ');

		if (won === 50) {
			room.say(`${symbols} JACKPOT! Three slices of brown cheese! You win 50 coins!`, slotStatus);
			room.celebrate();
		} else if (won === 19) {
			room.say(`${symbols} The Y2K bug! The machine thinks it is 1900 and pays 19 coins.`, slotStatus);
		} else if (won > 0) {
			room.say(`${symbols} You win ${plural(won, 'coin')}!`, slotStatus);
		} else {
			room.say(`${symbols} ${randomItem(['Nothing. The bandit wins.', 'So close!', 'Try again!', 'The machine laughs at you.'])}`, slotStatus);
		}
	});

	// The Unicorn Derby: five unicorns, a bet on one, and the bet times the odds for the winner. Dial-Up Dan has to connect first.
	const runners = [...room.querySelectorAll('[data-part="runner"]')];
	const derbyNames = ['Sparkle Pony', 'Brunost Express', 'Glitter Jr.', 'Y2K Bug', 'Dial-Up Dan'];
	const derbyOdds = [2, 3, 4, 6, 15];
	let isRacing = false;

	const placeRunner = (runner, progress) => {
		runner.style.setProperty('--derby-progress', `calc((100% - 3rem) * ${Math.min(progress, 1)})`);
	};

	// The favorites are faster on average, but each unicorn has a better or worse day, and every step is random, so any unicorn can win. Dial-Up Dan is the fastest, once he has connected. The speeds make the favorite win about 40% of the races, and Dan about 6%.
	const derbySpeeds = [0.0124, 0.012, 0.0117, 0.0114, 0.017];
	const dialUpSteps = 30;

	const raceStep = (progress, index, time, form) => {
		if (index === 4 && time < dialUpSteps) {
			return progress;
		}

		return progress + (derbySpeeds[index] * form[index] * (0.4 + (Math.random() * 1.2)));
	};

	room.on(derbyStart, 'click', async () => {
		if (isRacing) {
			return;
		}

		const pick = Number(derbyPick.value);
		const bet = Number(derbyBet.value);

		if (!arcade.spendCoins(bet)) {
			room.say(`You need ${plural(bet, 'coin')} to bet that. Ask Mom at the arcade.`, derbyStatus);
			return;
		}

		isRacing = true;
		derbyPick.disabled = true;
		derbyBet.disabled = true;
		const progress = runners.map(() => 0);
		const form = runners.map(() => 0.85 + (Math.random() * 0.3));
		let winner;
		let time = 0;
		room.say(`And they’re off! You bet ${plural(bet, 'coin')} on ${derbyNames[pick]}.`, derbyStatus);

		while (winner === undefined) {
			time++;

			for (const index of progress.keys()) {
				progress[index] = raceStep(progress[index], index, time, form);
			}

			const finished = progress.map((value, index) => ({value, index})).filter(item => item.value >= 1).toSorted((first, second) => second.value - first.value);
			winner = finished[0]?.index;

			// With reduced motion, the race is run at once, and only the finish is shown.
			if (!room.reducedMotion) {
				for (const [index, runner] of runners.entries()) {
					placeRunner(runner, progress[index]);
				}

				if (time === dialUpSteps) {
					derbyStatus.textContent = 'Dial-Up Dan has connected! Here he comes!';
				}

				await room.wait(50);
			}
		}

		for (const [index, runner] of runners.entries()) {
			placeRunner(runner, progress[index]);
		}

		const isWin = winner === pick;
		const winnings = isWin ? bet * derbyOdds[pick] : 0;
		arcade.addCoins(winnings);
		arcade.addTickets(isWin ? 5 : 1);
		isRacing = false;
		derbyPick.disabled = false;
		derbyBet.disabled = false;

		if (isWin) {
			arcade.sounds.bonus();
			room.say(`${derbyNames[winner]} wins! You win ${plural(winnings, 'coin')}!`, derbyStatus);

			if (winner === 4) {
				room.celebrate();
			}
		} else {
			room.say(`${derbyNames[winner]} wins! ${derbyNames[pick]} ${randomItem(['stopped to eat a waffle.', 'got distracted by a rainbow.', 'is still looking for the finish line.', 'says the track was too wet.'])}`, derbyStatus);
		}
	});

	// Glitter Says: Simon, with the tones of the Simon of 1978. The tune gets one note longer each round.
	const simonPads = [...room.querySelectorAll('[data-part="simonPad"]')];
	const simonTones = [415, 310, 252, 209];
	let simonBest = count(room.stored('simonBest', 0));
	let simonSequence = [];
	let simonInput = 0;
	let isSimonShowing = false;
	let isSimonPlaying = false;

	const lightPad = async (index, milliseconds) => {
		simonPads[index].dataset.state = 'lit';
		arcade.beep(simonTones[index], milliseconds / 1000, {type: 'triangle', volume: 0.1});
		await room.wait(milliseconds);
		simonPads[index].dataset.state = '';
	};

	const showSimonSequence = async () => {
		isSimonShowing = true;

		await room.wait(600);

		// It gets faster in longer rounds, like the Simon of 1978.
		const length = simonSequence.length > 12 ? 250 : (simonSequence.length > 5 ? 350 : 450);

		for (const index of simonSequence) {
			await lightPad(index, length);
			await room.wait(120);
		}

		isSimonShowing = false;
		simonInput = 0;
		room.say(`Your turn! ${plural(simonSequence.length, 'color')}.`, simonStatus);
	};

	const simonRound = () => {
		simonSequence.push(randomInteger(0, 3));
		simonStatus.textContent = `Round ${simonSequence.length}. Watch Glitter!`;
		showSimonSequence();
	};

	const endSimon = () => {
		isSimonPlaying = false;
		const rounds = simonSequence.length - 1;
		arcade.beep(42, 1, {type: 'sawtooth', volume: 0.08});
		const isBest = rounds > simonBest;

		if (isBest) {
			simonBest = rounds;
			room.store('simonBest', simonBest);
		}

		const tickets = arcade.addTickets(Math.max(1, rounds * 2));
		room.say(`Wrong! Glitter neighs sadly. You got ${plural(rounds, 'round')} right${isBest ? ', a new record' : ` (best: ${simonBest})`}, and ${plural(tickets, 'ticket')}.`, simonStatus);
		simonStart.disabled = false;
	};

	const pressSimon = index => {
		if (isSimonShowing) {
			return;
		}

		lightPad(index, 250);

		// Before a game, the buttons only play their tones, like the toy.
		if (!isSimonPlaying) {
			return;
		}

		if (index !== simonSequence[simonInput]) {
			endSimon();
			return;
		}

		simonInput++;

		if (simonInput === simonSequence.length) {
			isSimonShowing = true;
			room.timeout(500, simonRound);
		}
	};

	for (const [index, pad] of simonPads.entries()) {
		room.on(pad, 'click', () => {
			pressSimon(index);
		});
	}

	room.on(simonBoard.parentElement, 'keydown', event => {
		if (/^[1-4]$/.test(event.key) && !event.repeat && !event.altKey && !event.ctrlKey && !event.metaKey) {
			event.preventDefault();
			event.stopPropagation();
			pressSimon(Number(event.key) - 1);
		}
	});

	room.on(simonStart, 'click', () => {
		isSimonPlaying = true;
		simonSequence = [];
		// The focus moves to the colors before the start button is disabled.
		simonPads[0].focus();
		simonStart.disabled = true;
		simonRound();
	});

	// The memory game: 16 cards, two of each GIF. The visitor turns two at a time.
	let memoryBest = count(room.stored('memoryBest', 0));
	let memoryOpen = [];
	let memoryMoves = 0;
	let memoryMatched = 0;
	let memoryTimer;

	const memoryLabel = (card, isOpen) => `Card ${[...memoryBoard.children].indexOf(card) + 1}, ${isOpen ? card.dataset.memoryName : 'face down'}`;

	const dealMemory = () => {
		memoryTimer?.cancel();
		memoryBoard.replaceChildren(...shuffle([...memoryBoard.children]));

		for (const card of memoryBoard.children) {
			card.dataset.state = '';
			card.setAttribute('aria-label', memoryLabel(card, false));
		}

		memoryOpen = [];
		memoryMoves = 0;
		memoryMatched = 0;
		memoryStatus.textContent = `Find the 8 pairs!${memoryBest > 0 ? ` Best: ${plural(memoryBest, 'move')}.` : ''}`;
	};

	const hideOpenCards = () => {
		memoryTimer?.cancel();

		for (const open of memoryOpen) {
			open.dataset.state = '';
			open.setAttribute('aria-label', memoryLabel(open, false));
		}

		memoryOpen = [];
	};

	for (const card of memoryBoard.children) {
		room.on(card, 'click', () => {
			if (card.dataset.state) {
				return;
			}

			// Two cards that are no pair turn back after a moment, or at once when the visitor turns the next card.
			if (memoryOpen.length === 2) {
				hideOpenCards();
			}

			card.dataset.state = 'open';
			card.setAttribute('aria-label', memoryLabel(card, true));
			memoryOpen.push(card);
			arcade.beep(500, 0.05);

			if (memoryOpen.length < 2) {
				room.say(`${card.dataset.memoryName}. Find its pair!`, memoryStatus);
				return;
			}

			memoryMoves++;
			const [first, second] = memoryOpen;

			if (first.dataset.memoryCard === second.dataset.memoryCard) {
				memoryMatched++;

				for (const match of memoryOpen) {
					match.dataset.state = 'matched';
				}

				memoryOpen = [];

				if (memoryMatched === 8) {
					const isBest = memoryBest === 0 || memoryMoves < memoryBest;

					if (isBest) {
						memoryBest = memoryMoves;
						room.store('memoryBest', memoryBest);
					}

					const tickets = arcade.addTickets(Math.max(2, 30 - memoryMoves));
					room.say(`All pairs in ${plural(memoryMoves, 'move')}!${isBest ? ' A new record!' : ''} You get ${plural(tickets, 'ticket')}. Shuffle to play again!`, memoryStatus);
					arcade.sounds.bonus();
				} else {
					room.say(`A pair: ${first.dataset.memoryName.toLowerCase()}! ${memoryMatched} of 8.`, memoryStatus);
					arcade.sounds.coin();
				}

				return;
			}

			room.say(`${first.dataset.memoryName} and ${second.dataset.memoryName.toLowerCase()}. No pair.`, memoryStatus);

			memoryTimer = room.timeout(1500, hideOpenCards);
		});
	}

	room.on(memoryRestart, 'click', dealMemory);
	dealMemory();

	// Hangman ’99: the words of 1999, each with a hint. Six wrong letters draw the stick figure, the propeller hat last.
	const hangmanWords = [
		['MODEM', 'It screams when it connects.'],
		['NETSCAPE', 'A browser with a big N and a comet.'],
		['TAMAGOTCHI', 'A pet in an egg that dies at school.'],
		['FURBY', 'It talks in its sleep. Nobody can turn it off.'],
		['GUESTBOOK', 'Please sign it!'],
		['WEBRING', 'Previous, Random, Next.'],
		['MILLENNIUM', 'It is coming, and it might crash your computer.'],
		['NAPSTER', 'Where songs came from (not legally).'],
		['WINAMP', 'It really whips the llama’s ass.'],
		['GEOCITIES', 'Where home pages live, in neighborhoods.'],
		['FLOPPY', 'It holds 1.44 MB. It is not floppy.'],
		['BRUNOST', 'Brown, sweet, Norwegian, and on a waffle.'],
		['WAFFLE', 'Best with brown cheese.'],
		['TAMAGOTCHI', 'Feed it, or it dies at school.'],
		['DIALUP', 'How to get on the Internet. Get off the phone!'],
		['SCREENSAVER', 'Flying toasters, when nobody is looking.'],
		['WALKMAN', 'Music on the go, with tapes.'],
		['BEANIE', 'A baby, filled with beans, worth a fortune (not really).'],
		['MATRIX', 'There is no spoon.'],
		['UNICORN', 'The best animal. Ask Glitter.'],
	];
	const hangmanSteps = [
		['  +---+', '  |   |', '      |', '      |', '      |', '      |', '========='],
		['  +---+', '  |   |', '  O   |', '      |', '      |', '      |', '========='],
		['  +---+', '  |   |', '  O   |', '  |   |', '      |', '      |', '========='],
		['  +---+', '  |   |', '  O   |', ' /|   |', '      |', '      |', '========='],
		['  +---+', '  |   |', '  O   |', ' /|\\  |', '      |', '      |', '========='],
		['  +---+', '  |   |', '  O   |', ' /|\\  |', ' / \\  |', '      |', '========='],
		['  +---+', '  |   |', ' *O*  |', ' /|\\  |', ' / \\  |', '      |', '========='],
	];
	const hangmanButtons = [...room.querySelectorAll('[data-hangman-letter]')];
	let hangman;

	const showHangman = () => {
		hangmanDrawing.textContent = hangmanSteps[hangman.misses].join('\n');
		const shown = [...hangman.word].map(letter => (hangman.guessed.has(letter) || hangman.isOver ? letter : '_')).join(' ');
		hangmanWord.textContent = shown;
		hangmanWord.setAttribute('aria-label', `The word: ${[...hangman.word].map(letter => (hangman.guessed.has(letter) || hangman.isOver ? letter : 'blank')).join(', ')}`);
	};

	const newHangman = () => {
		const [word, hint] = randomItem(hangmanWords.filter(([item]) => item !== hangman?.word));
		hangman = {word, guessed: new Set(), misses: 0, isOver: false};
		hangmanHint.textContent = `Hint: ${hint}`;

		for (const button of hangmanButtons) {
			button.removeAttribute('aria-disabled');
			button.dataset.state = '';
		}

		hangmanStatus.textContent = `${word.length} letters. Click a letter, or type it.`;
		showHangman();
	};

	const guessLetter = letter => {
		const button = hangmanButtons.find(item => item.dataset.hangmanLetter === letter);

		if (hangman.isOver || hangman.guessed.has(letter)) {
			return;
		}

		hangman.guessed.add(letter);
		const isHit = hangman.word.includes(letter);
		button.dataset.state = isHit ? 'hit' : 'miss';
		button.setAttribute('aria-disabled', 'true');

		if (!isHit) {
			hangman.misses++;
		}

		const isWon = [...hangman.word].every(item => hangman.guessed.has(item));
		const isLost = hangman.misses === hangmanSteps.length - 1;

		if (isWon || isLost) {
			hangman.isOver = true;

			for (const item of hangmanButtons) {
				item.setAttribute('aria-disabled', 'true');
			}
		}

		showHangman();

		if (isWon) {
			const tickets = arcade.addTickets(Math.max(2, 12 - (hangman.misses * 2)));
			room.say(`You got it: ${hangman.word}! You get ${plural(tickets, 'ticket')}. Try a new word!`, hangmanStatus);
			arcade.sounds.bonus();
		} else if (isLost) {
			arcade.addTickets(1);
			room.say(`Oh no! The word was ${hangman.word}. The stick man got his propeller hat and flew away. Try a new word!`, hangmanStatus);
			arcade.sounds.gameOver();
		} else {
			const triesLeft = hangmanSteps.length - 1 - hangman.misses;
			room.say(isHit ? `Yes, ${letter} is in the word!` : `No ${letter}. ${triesLeft} ${triesLeft === 1 ? 'try' : 'tries'} left.`, hangmanStatus);
		}
	};

	for (const button of hangmanButtons) {
		room.on(button, 'click', () => {
			guessLetter(button.dataset.hangmanLetter);
		});
	}

	// Safari does not focus a button on a click, so a click in the game focuses its button, and the keys of the keyboard guess then too.
	room.on(hangmanKeys.parentElement, 'click', event => {
		event.target.closest('button')?.focus({preventScroll: true});
	});

	room.on(hangmanKeys.parentElement, 'keydown', event => {
		if (/^[a-z]$/i.test(event.key) && !event.altKey && !event.ctrlKey && !event.metaKey && event.target.tagName !== 'INPUT') {
			event.preventDefault();
			event.stopPropagation();
			guessLetter(event.key.toUpperCase());
		}
	});

	room.on(hangmanNew, 'click', newHangman);
	newHangman();

	// Rock Paper Scissors against Rocky, my pet rock, who always plays rock, because he is a rock.
	const rps = {you: 0, rocky: 0, ties: 0, paperStreak: 0};

	for (const button of room.querySelectorAll('[data-rps-move]')) {
		room.on(button, 'click', () => {
			const move = button.dataset.rpsMove;
			let message;

			if (move === 'paper') {
				rps.you++;
				rps.paperStreak++;

				// A ticket for every fifth win, as Paper always wins.
				if (rps.you % 5 === 0) {
					arcade.addTickets(1);
				}
				message = rps.paperStreak >= 5 ? `Paper covers rock. Again. Rocky is thinking about a new strategy… He plays rock. (${rps.paperStreak} in a row!)` : randomItem(['Paper covers rock! Rocky did not see that coming.', 'You win! Rocky stares at you with his googly eyes.', 'Paper covers rock. Rocky is not mad. Rocky cannot be mad.']);
			} else if (move === 'scissors') {
				rps.rocky++;
				rps.paperStreak = 0;
				message = randomItem(['Rock smashes scissors! Rocky wins! He does not move, but you can tell he is happy.', 'Rocky wins! He has played rock 4.5 billion years in a row.', 'Rocky wins! Rock solid strategy.']);
			} else {
				rps.ties++;
				rps.paperStreak = 0;
				message = randomItem(['Rock and rock. A tie. You and Rocky have a lot in common.', 'A tie! Two rocks, just sitting there.', 'Tie! Rocky respects you now.']);
			}

			rpsScore.textContent = `You: ${rps.you} ★ Rocky: ${rps.rocky} ★ Ties: ${rps.ties}`;
			room.say(`Rocky plays ✊ rock. ${message}`, rpsStatus);
		});
	}

	// The button scrolls to Rocky’s section, which has no ID, by its heading.
	room.on(rpsVisit, 'click', () => {
		const heading = [...document.querySelectorAll('h2')].find(element => element.textContent.includes('Rocky'));

		if (heading) {
			heading.setAttribute('tabindex', '-1');
			heading.focus({preventScroll: true});
			heading.scrollIntoView({behavior: room.reducedMotion ? 'auto' : 'smooth', block: 'center'});
		}
	});

	// How fast is your modem finger? The button turns green after a random wait, and the visitor clicks it as fast as possible.
	let reactionRecord = count(room.stored('reactionBest', 0));
	let reactionState = 'ready';
	let reactionTimer;
	let reactionStart;

	const showReactionBest = () => {
		reactionBest.textContent = reactionRecord > 0 ? `Your best: ${reactionRecord} ms` : '';
	};

	const modemSpeed = milliseconds => {
		if (milliseconds < 180) {
			return 'a T1 line! Are you a robot?';
		}

		if (milliseconds < 250) {
			return 'ISDN. Very fast!';
		}

		if (milliseconds < 330) {
			return 'a 56k modem. Not bad!';
		}

		if (milliseconds < 450) {
			return 'a 28.8k modem. Pretty good.';
		}

		return 'a 14.4k modem. Did somebody pick up the phone?';
	};

	// It counts the press of a pointer, not the release, so the time is fair, and the click that follows the press is left out.
	let isClickHandled = false;

	const pressReaction = () => {
		if (reactionState === 'ready' || reactionState === 'done') {
			reactionState = 'wait';
			reactionButton.dataset.state = 'wait';
			reactionButton.textContent = 'Wait for green…';
			reactionTimer = room.timeout(randomInteger(1500, 4000), () => {
				reactionState = 'go';
				reactionButton.dataset.state = 'go';
				reactionButton.textContent = 'CLICK!';
				reactionStart = performance.now();
				room.say('Now!', reactionStatus);
			});
			reactionStatus.textContent = 'Wait for it…';
		} else if (reactionState === 'wait') {
			reactionTimer.cancel();
			reactionState = 'done';
			reactionButton.dataset.state = '';
			reactionButton.textContent = 'Try Again';
			room.say('Too soon! You disconnected. Wait for green.', reactionStatus);
		} else if (reactionState === 'go') {
			const time = Math.round(performance.now() - reactionStart);
			reactionState = 'done';
			reactionButton.dataset.state = '';
			reactionButton.textContent = `${time} ms`;
			const isBest = reactionRecord === 0 || time < reactionRecord;

			if (isBest) {
				reactionRecord = time;
				room.store('reactionBest', time);
				showReactionBest();
			}

			const tickets = arcade.addTickets(time < 250 ? 5 : (time < 400 ? 3 : 1));
			room.say(`${time} milliseconds! Your finger is as fast as ${modemSpeed(time)}${isBest ? ' A new record!' : ''} You get ${plural(tickets, 'ticket')}.`, reactionStatus);
		}
	};

	room.on(reactionButton, 'pointerdown', event => {
		isClickHandled = event.button === 0;

		if (isClickHandled) {
			pressReaction();
		}
	});

	room.on(reactionButton, 'click', event => {
		// A click from the keyboard has no pointer, so it always counts.
		if (event.detail > 0 && isClickHandled) {
			isClickHandled = false;
			return;
		}

		pressReaction();
	});

	showReactionBest();

	// Mormor Teaches Typing: type a sentence, and get the speed in words a minute, and as the speed of a modem.
	const typingSentences = [
		'the quick brown fox jumps over the lazy dog',
		'my modem screams louder than my little sister',
		'waffles with brown cheese are the best food in the world',
		'please sign my guestbook before you leave',
		'do not pick up the phone while i am on the internet',
		'my unicorn has a home page and it has more hits than mine',
		'the year two thousand is coming and my computer is not ready',
		'best viewed in netscape at eight hundred by six hundred',
	];
	let typingSentence;
	let typingStart;
	let isTypingDone = false;

	const newSentence = () => {
		typingSentence = randomItem(typingSentences.filter(sentence => sentence !== typingSentence));
		typingText.replaceChildren(...[...typingSentence].map(letter => {
			const span = document.createElement('span');
			span.textContent = letter;
			return span;
		}));
		typingLabel.textContent = `Type: ${typingSentence}`;
		typingInput.value = '';
		typingInput.disabled = false;
		typingStart = undefined;
		isTypingDone = false;
		typingStatus.textContent = 'The clock starts at the first letter.';
	};

	room.on(typingInput, 'input', () => {
		if (isTypingDone) {
			return;
		}

		typingStart ??= performance.now();
		const typed = typingInput.value;

		for (const [index, span] of [...typingText.children].entries()) {
			span.dataset.state = index >= typed.length ? '' : (typed[index].toLowerCase() === typingSentence[index] ? 'typed' : 'mistyped');
		}

		if (typed.length < typingSentence.length) {
			return;
		}

		isTypingDone = true;
		const minutes = (performance.now() - typingStart) / 60_000;
		const correct = [...typingSentence].filter((letter, index) => typed[index]?.toLowerCase() === letter).length;
		const accuracy = Math.round((correct / typingSentence.length) * 100);
		// A word is 5 letters, the standard of typing tests.
		const wordsPerMinute = Math.round((correct / 5) / minutes);
		// A letter is 8 bits, so the speed is like a modem of that many bits a second.
		const bitsPerSecond = Math.round((correct * 8) / (minutes * 60));
		// Nobody types 200 words a minute, so that was pasted, and gets no tickets.
		if (!Number.isFinite(wordsPerMinute) || wordsPerMinute > 200) {
			room.say('Mormor saw that. Pasting is not typing! No tickets.', typingStatus);
			return;
		}

		const tickets = arcade.addTickets(Math.max(1, Math.min(Math.round((wordsPerMinute * accuracy) / 500), 15)));
		const verdict = wordsPerMinute >= 90 ? 'Faster than Mormor! She wants a rematch.' : (wordsPerMinute >= 50 ? 'Mormor is impressed.' : (wordsPerMinute >= 25 ? 'Mormor says: “Practice makes perfect.”' : 'Mormor says: “Use more than two fingers, vennen.”'));
		room.say(`${wordsPerMinute} words a minute, ${accuracy}% right. That is ${bitsPerSecond} bits a second, like a very slow modem. ${verdict} You get ${plural(tickets, 'ticket')}.`, typingStatus);
	});

	room.on(typingNew, 'click', () => {
		newSentence();
		typingInput.focus();
	});

	newSentence();

	// Yatzy, the Scandinavian way: five dice, three rolls a round, and 15 rows to fill, with 50 extra for 63 or more in the upper rows.
	const dieFaces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
	const yatzyDice = [...room.querySelectorAll('[data-part="yatzyDie"]')];
	const yatzyRows = [...room.querySelectorAll('[data-yatzy-category]')];
	let yatzyBest = count(room.stored('yatzyBest', 0));
	let yatzy;

	const total = numbers => {
		let sum = 0;

		for (const number of numbers) {
			sum += number;
		}

		return sum;
	};

	const scoreYatzy = (key, dice) => {
		const counts = [1, 2, 3, 4, 5, 6].map(value => dice.filter(die => die === value).length);
		const sum = total(dice);
		// The values with at least that many dice, the highest first.
		const withAtLeast = amount => [6, 5, 4, 3, 2, 1].filter(value => counts[value - 1] >= amount);
		const sorted = dice.toSorted().join('');

		switch (key) {
			case 'pair': {
				return (withAtLeast(2)[0] ?? 0) * 2;
			}

			case 'twoPairs': {
				const pairs = withAtLeast(2);
				return pairs.length >= 2 ? (pairs[0] + pairs[1]) * 2 : 0;
			}

			case 'three': {
				return (withAtLeast(3)[0] ?? 0) * 3;
			}

			case 'four': {
				return (withAtLeast(4)[0] ?? 0) * 4;
			}

			case 'small': {
				return sorted === '12345' ? 15 : 0;
			}

			case 'large': {
				return sorted === '23456' ? 20 : 0;
			}

			case 'house': {
				const three = withAtLeast(3)[0];
				const two = withAtLeast(2).find(value => value !== three);
				return three && two && counts[three - 1] === 3 && counts[two - 1] === 2 ? sum : 0;
			}

			case 'chance': {
				return sum;
			}

			case 'yatzy': {
				return withAtLeast(5).length > 0 ? 50 : 0;
			}

			default: {
				return counts[Number(key) - 1] * Number(key);
			}
		}
	};

	const upperSum = () => total(['1', '2', '3', '4', '5', '6'].map(key => yatzy.scores[key] ?? 0));
	const yatzyGrandTotal = () => total(Object.values(yatzy.scores)) + (upperSum() >= 63 ? 50 : 0);

	const showYatzy = () => {
		for (const [index, die] of yatzyDice.entries()) {
			const value = yatzy.dice[index];
			die.textContent = value ? dieFaces[value - 1] : '⚀';
			die.disabled = yatzy.rolls === 0 || yatzy.rolls === 3 || yatzy.isOver || yatzy.isRolling;
			die.dataset.state = yatzy.kept[index] ? 'kept' : '';
			die.setAttribute('aria-pressed', String(yatzy.kept[index]));
			die.setAttribute('aria-label', value ? `Die ${index + 1}: ${value}` : `Die ${index + 1}`);
		}

		for (const row of yatzyRows) {
			const key = row.dataset.yatzyCategory;
			const isScored = yatzy.scores[key] !== undefined;
			row.dataset.state = isScored ? 'scored' : '';
			// While the dice tumble, the open rows wait for them.
			row.disabled = isScored || yatzy.rolls === 0 || yatzy.isOver || yatzy.isRolling;
			row.textContent = isScored ? yatzy.scores[key] : (yatzy.rolls > 0 && !yatzy.isOver && !yatzy.isRolling ? scoreYatzy(key, yatzy.dice) : '–');
			row.setAttribute('aria-label', `${row.closest('tr').querySelector('th').textContent}: ${row.textContent === '–' ? 'empty' : row.textContent}`);
		}

		yatzyBonus.textContent = upperSum() >= 63 ? '50' : `${upperSum()} / 63`;
		yatzyTotal.textContent = yatzyGrandTotal();
		yatzyRoll.disabled = yatzy.rolls === 3 && !yatzy.isOver;
		yatzyRoll.textContent = yatzy.isOver ? 'New Game' : `Roll the Dice! (${3 - yatzy.rolls} left)`;
	};

	const newYatzy = () => {
		yatzy = {dice: [0, 0, 0, 0, 0], kept: [false, false, false, false, false], rolls: 0, scores: {}, isOver: false, isRolling: false};
		showYatzy();
	};

	room.on(yatzyRoll, 'click', async () => {
		if (yatzy.isOver) {
			newYatzy();
			room.say('A new game! Press Roll.', yatzyStatus);
			return;
		}

		if (yatzy.isRolling || yatzy.rolls === 3) {
			return;
		}

		yatzy.rolls++;
		yatzy.isRolling = true;
		const hadFocus = document.activeElement === yatzyRoll;
		showYatzy();

		// The dice tumble for a moment, unless the visitor prefers less motion.
		if (!room.reducedMotion) {
			for (let index = 0; index < 6; index++) {
				for (const [dieIndex, die] of yatzyDice.entries()) {
					if (!yatzy.kept[dieIndex]) {
						die.textContent = randomItem(dieFaces);
					}
				}

				arcade.beep(150 + (Math.random() * 100), 0.03, {volume: 0.03});
				await room.wait(60);
			}
		}

		yatzy.dice = yatzy.dice.map((die, index) => (yatzy.kept[index] ? die : randomInteger(1, 6)));
		yatzy.isRolling = false;
		showYatzy();
		const isYatzy = scoreYatzy('yatzy', yatzy.dice) === 50;
		room.say(`${isYatzy ? 'YATZY!!! ' : ''}You rolled ${yatzy.dice.join(', ')}. ${yatzy.rolls < 3 ? 'Keep dice and roll again, or pick a row.' : 'Pick a row.'}`, yatzyStatus);

		if (isYatzy) {
			arcade.sounds.bonus();
		}

		// The roll button is disabled after the third roll, so the focus moves to the score card.
		if (yatzy.rolls === 3 && hadFocus) {
			yatzyRows.find(row => !row.disabled)?.focus();
		}
	});

	for (const [index, die] of yatzyDice.entries()) {
		room.on(die, 'click', () => {
			if (yatzy.isRolling) {
				return;
			}

			yatzy.kept[index] = !yatzy.kept[index];
			showYatzy();
		});
	}

	for (const row of yatzyRows) {
		room.on(row, 'click', () => {
			if (yatzy.isRolling) {
				return;
			}

			const key = row.dataset.yatzyCategory;
			const points = scoreYatzy(key, yatzy.dice);
			yatzy.scores[key] = points;
			yatzy.rolls = 0;
			yatzy.kept = [false, false, false, false, false];
			const isDone = Object.keys(yatzy.scores).length === yatzyRows.length;

			if (isDone) {
				yatzy.isOver = true;
				const finalScore = yatzyGrandTotal();
				const isBest = finalScore > yatzyBest;

				if (isBest) {
					yatzyBest = finalScore;
					room.store('yatzyBest', finalScore);
				}

				const tickets = arcade.addTickets(Math.max(1, Math.round(finalScore / 10)));
				room.say(`Game over! ${finalScore} points${isBest ? ', a new record' : ` (best: ${yatzyBest})`}. You get ${plural(tickets, 'ticket')}. Press New Game to play again.`, yatzyStatus);

				if (finalScore >= 250) {
					room.celebrate();
				}
			} else {
				room.say(`${points} points for ${row.closest('tr').querySelector('th').textContent}. Roll again!`, yatzyStatus);
			}

			showYatzy();
			// The row is disabled now, so the focus goes back to the roll button.
			yatzyRoll.focus();
		});
	}

	newYatzy();
};

export default class extends GeoCitiesElement {
	connected() {
		setUpGameRoom(this, this.parts);
	}

	// The roll button is disabled while the dice of the third roll tumble, and the script moves the focus to the score card when they stop, so the focus waits instead of going to another game.
	focusReplacement(control) {
		return control === this.parts.yatzyRoll ? undefined : super.focusReplacement(control);
	}

	// Glitter cheers too.
	celebrate() {
		super.celebrate();
		this.cheer();
	}
}
