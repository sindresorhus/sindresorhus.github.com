// The fortune toys on the 1999 page: the Magic 8-Ball, the paper fortune teller, and the mood ring.
const randomItem = items => items[Math.floor(Math.random() * items.length)];

// A copy of the first element of a template.
const cloneTemplate = template => template.content.firstElementChild.cloneNode(true);

// The 20 answers of the real Magic 8-Ball, and a few of 1999.
const answers = [
	'It is certain',
	'It is decidedly so',
	'Without a doubt',
	'Yes, definitely',
	'You may rely on it',
	'As I see it, yes',
	'Most likely',
	'Outlook good',
	'Yes',
	'Signs point to yes',
	'Reply hazy, try again',
	'Ask again later',
	'Better not tell you now',
	'Cannot predict now',
	'Concentrate and ask again',
	'Don’t count on it',
	'My reply is no',
	'My sources say no',
	'Outlook not so good',
	'Very doubtful',
	'Ask again after Y2K',
	'Only if you sign my guestbook',
];

const fortunes = {
	1: 'You will marry a Backstreet Boy.',
	2: 'Your modem will connect at 56K on the first try.',
	3: 'You will get a pager for Christmas.',
	4: 'The Y2K bug will skip your house.',
	5: 'Your crush will sign your guestbook.',
	6: 'You will be a webmaster when you grow up.',
	7: 'You will step on a LEGO tomorrow.',
	8: 'Your Tamagotchi will live forever.',
};

// The numbers inside each flap of the paper fortune teller, for each way that the paper opens, in the order of the flaps.
const numbers = {
	a: [1, 3, 8, 6],
	b: [2, 4, 7, 5],
};

const moods = [
	{speed: 2, color: '#111111', name: 'Stressed!!! (black)'},
	{speed: 1, color: '#c98a1a', name: 'Nervous (amber)'},
	{speed: 0.45, color: '#2e9e4f', name: 'Normal (green)'},
	{speed: 0.15, color: '#2f6fd6', name: 'Calm (blue)'},
	{speed: 0, color: '#8a3fd1', name: 'Happy and in love (violet)'},
];

export default class extends GeoCitiesElement {
	connected() {
		this.#setUpEightBall();
		this.#setUpFortuneTeller();
		this.#setUpMoodRing();
	}

	// The Magic 8-Ball: it shakes, and then the answer floats up in the window.
	#setUpEightBall() {
		const {eightBallForm: form, question, ball, answer} = this.parts;
		let isShaking = false;
		let previousAnswer;

		this.on(form, 'submit', async event => {
			event.preventDefault();
			if (isShaking) {
				return;
			}

			if (!question.value.trim()) {
				question.focus();
				delete answer.dataset.state;
				this.say('Ask a question first', answer);
				return;
			}

			isShaking = true;
			ball.dataset.state = 'shaking';
			answer.dataset.state = 'hidden';
			await this.wait(this.reducedMotion ? 300 : 1000);
			delete ball.dataset.state;
			delete answer.dataset.state;
			// Never the same answer twice in a row, which would look like the ball did not shake.
			previousAnswer = randomItem(answers.filter(item => item !== previousAnswer));
			this.say(previousAnswer, answer);
			isShaking = false;
		});
	}

	// The paper fortune teller: it opens one way and the other for each letter of the color, then for the number, and the last number picked unfolds to a fortune.
	#setUpFortuneTeller() {
		const {catcherStatus: status, choices, choiceTemplate} = this.parts;
		const flaps = [...this.querySelectorAll('[data-catcher-flap]')];
		let way;
		let isMoving = false;

		const setWay = newWay => {
			way = newWay;
			for (const flap of flaps) {
				if (way) {
					flap.dataset.state = way;
				} else {
					delete flap.dataset.state;
				}
			}
		};

		// Opens the paper the other way, once for each step, and says each step.
		const pump = async labels => {
			for (const label of labels) {
				setWay(way === 'a' ? 'b' : 'a');
				status.textContent = label;
				await this.wait(this.reducedMotion ? 250 : 450);
			}
		};

		const showChoices = (values, onPick) => {
			choices.replaceChildren(...values.map(value => {
				const button = cloneTemplate(choiceTemplate);
				button.textContent = value;
				// The buttons are made again for each choice, so their listeners go away with them.
				button.addEventListener('click', () => {
					onPick(value);
				});
				return button;
			}));
			// The button that was clicked is gone, so the focus goes to the first new one.
			choices.querySelector('button').focus();
		};

		const pickNumber = async (number, isLast) => {
			if (isMoving) {
				return;
			}

			isMoving = true;
			// The paper stays open with the numbers, so the visitor sees the flap that was opened, until Play Again closes it.
			if (isLast) {
				this.say(`You opened ${number}. Your fortune: ${fortunes[number]}`, status);
				showChoices(['Play Again'], () => {
					setWay(undefined);
					status.textContent = 'Pick a color!';
					showColors();
				});
				isMoving = false;
				return;
			}

			await pump(Array.from({length: number}, (_, index) => `${index + 1}…`));
			this.say('Pick a number to open!', status);
			showChoices([...numbers[way]].sort((first, second) => first - second), value => {
				pickNumber(value, true);
			});
			isMoving = false;
		};

		const pickColor = async color => {
			if (isMoving) {
				return;
			}

			isMoving = true;
			setWay(undefined);
			const letters = [...color.toUpperCase()];
			await pump(letters.map((letter, index) => `${letters.slice(0, index + 1).join('-')}${index === letters.length - 1 ? '!' : '…'}`));
			this.say('Pick a number!', status);
			showChoices([...numbers[way]].sort((first, second) => first - second), value => {
				pickNumber(value, false);
			});
			isMoving = false;
		};

		const showColors = () => {
			showChoices(flaps.map(flap => flap.dataset.catcherFlap), pickColor);
		};

		// The first color buttons are in the page, with the color as their value.
		this.on(choices, 'click', event => {
			const value = event.target.closest('button')?.value;
			if (value) {
				pickColor(value);
			}
		});
	}

	// The mood ring: the stone takes the color of how calmly the pointer moves over it. A resting pointer calms it down by itself, a little more each frame, while the pointer is on the ring.
	#setUpMoodRing() {
		const {ring, mood: moodText, warm: warmButton} = this.parts;
		let speed = 3;
		let mood;
		let lastPoint;

		const showMood = newMood => {
			if (newMood === mood) {
				return;
			}

			mood = newMood;
			ring.style.setProperty('--mood-ring-color', mood.color);
			moodText.textContent = `Mood: ${mood.name}`;
		};

		const update = () => {
			showMood(moods.find(mood => speed >= mood.speed));
		};

		// Each move of the pointer starts it, and it stops once the stone is as calm as it gets, so no loop runs for a pointer that rests on the ring. It follows the ring, as the element has no box of its own to watch.
		const calmDown = this.loop(() => {
			speed *= 0.97;
			update();
		}, {while: () => lastPoint !== undefined && speed > 0.01, target: ring});

		this.on(ring, 'pointermove', event => {
			if (lastPoint) {
				const distance = Math.hypot(event.clientX - lastPoint.x, event.clientY - lastPoint.y);
				const time = Math.max(event.timeStamp - lastPoint.time, 1);
				// Smoothed, so one jerk does not make the visitor stressed.
				speed = (speed * 0.8) + (Math.min(distance / time, 6) * 0.2);
			}

			lastPoint = {x: event.clientX, y: event.clientY, time: event.timeStamp};
			update();
			calmDown.start();
		});

		this.on(ring, 'pointerleave', () => {
			lastPoint = undefined;
		});

		// Holding the ring warms it up, one mood calmer each time, until the visitor squeezes it too hard.
		this.on(warmButton, 'click', () => {
			const index = mood ? moods.indexOf(mood) : 0;
			if (index === moods.length - 1) {
				speed = 3;
				update();
				moodText.textContent = `Mood: ${mood.name}. You squeezed it too hard.`;
				return;
			}

			speed = moods[index + 1].speed;
			update();
		});
	}
}
