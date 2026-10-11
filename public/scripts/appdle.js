// Appdle: the visitor guesses the app of the day from a pixelated part of its icon. Each wrong guess shows more of the icon, sharper.
const {firstDay, maximumGuesses, puzzles} = JSON.parse(document.querySelector('#appdle-data').textContent);
const canvas = document.querySelector('#appdle-canvas');
const form = document.querySelector('#appdle-form');
const input = form.elements.guess;
const status = document.querySelector('#appdle-status');
const attempts = document.querySelector('#appdle-attempts');
const slots = [...document.querySelector('#appdle-slots').children];
const result = document.querySelector('#appdle-result');
const copyButton = document.querySelector('#appdle-copy-result');
const restartButton = document.querySelector('#appdle-restart');

// The local date as days since 1970, like the daily seed of the build, so the app changes at midnight for the visitor, and everybody gets the same app on the same date.
const today = new Date();
// A clock before the first puzzle gets the first puzzle.
const day = Math.max(firstDay, Math.floor(Date.UTC(today.getFullYear(), today.getMonth(), today.getDate()) / 86_400_000));
const puzzle = puzzles[day % puzzles.length];
const number = day - firstDay + 1;

// How much of the icon shows, and how many blocks across it has, after each wrong guess. Even the last step is a coarse part of the icon, so the last guess still has to be earned: only the end of the game shows the whole, sharp icon.
const steps = [
	{crop: 0.4, blocks: 5},
	{crop: 0.48, blocks: 7},
	{crop: 0.56, blocks: 9},
	{crop: 0.65, blocks: 12},
	{crop: 0.75, blocks: 16},
	{crop: 0.85, blocks: 21},
];

// Where the parts are centered, as fractions of the icon from its center. The most colorful of these places is used, so the first part is not an almost white corner of the icon.
const offsetCandidates = [-0.15, 0, 0.15].flatMap(y => [-0.15, 0, 0.15].map(x => ({x, y})));
let offset;

const normalize = name => name.trim().toLocaleLowerCase('en');
const names = new Map([...input.list.options].map(option => [normalize(option.value), option.value]));
const storageKey = 'appdle';

const load = () => {
	try {
		const saved = JSON.parse(localStorage.getItem(storageKey));

		if (saved?.day === day && saved.title === puzzle.title) {
			return saved.guesses;
		}
	} catch {}

	return [];
};

const guesses = load();

const save = () => {
	try {
		localStorage.setItem(storageKey, JSON.stringify({day, title: puzzle.title, guesses}));
	} catch {}
};

const image = new Image();
image.src = puzzle.icon;

// Like “1 guess” or “3 guesses”.
const guessCount = count => `${count} ${count === 1 ? 'guess' : 'guesses'}`;

const isWon = () => guesses.includes(puzzle.title);
const isDone = () => isWon() || guesses.length >= maximumGuesses;
const wrongCount = () => guesses.filter(guess => guess !== puzzle.title).length;

// The square part of the icon at a crop size, centered at the offset.
const part = (crop, partOffset) => {
	const size = Math.min(image.naturalWidth, image.naturalHeight);
	const cropSize = size * crop;
	const clamp = value => Math.min(Math.max(value, 0), size - cropSize);

	return {
		x: clamp(((0.5 + partOffset.x) * size) - (cropSize / 2)),
		y: clamp(((0.5 + partOffset.y) * size) - (cropSize / 2)),
		size: cropSize,
	};
};

// How colorful the first part at an offset is: the spread of its colors plus their saturation, from a few pixels.
const colorfulness = candidate => {
	const {x, y, size} = part(steps[0].crop, candidate);
	const sample = new OffscreenCanvas(8, 8);
	const context = sample.getContext('2d', {willReadFrequently: true});
	context.drawImage(image, x, y, size, size, 0, 0, 8, 8);
	const {data} = context.getImageData(0, 0, 8, 8);
	const pixels = [];

	for (let index = 0; index < data.length; index += 4) {
		pixels.push([data[index], data[index + 1], data[index + 2]]);
	}

	const mean = [0, 0, 0];

	for (const pixel of pixels) {
		for (const [channel, value] of pixel.entries()) {
			mean[channel] += value / pixels.length;
		}
	}

	let total = 0;

	for (const pixel of pixels) {
		const spread = Math.hypot(...pixel.map((value, channel) => value - mean[channel]));
		const saturation = Math.max(...pixel) - Math.min(...pixel);
		total += spread + saturation;
	}

	return total / pixels.length;
};

const mostColorfulOffset = () => {
	let bestScore = -1;
	let bestOffset;

	for (const candidate of offsetCandidates) {
		const score = colorfulness(candidate);

		if (score > bestScore) {
			bestScore = score;
			bestOffset = candidate;
		}
	}

	return bestOffset;
};

const draw = () => {
	// The icon did not load.
	if (image.naturalWidth === 0) {
		return;
	}

	const context = canvas.getContext('2d');
	context.clearRect(0, 0, canvas.width, canvas.height);

	if (isDone()) {
		context.imageSmoothingEnabled = true;
		context.imageSmoothingQuality = 'high';
		context.drawImage(image, 0, 0, canvas.width, canvas.height);
		canvas.ariaLabel = `The icon of ${puzzle.title}`;
		canvas.dataset.state = 'revealed';
		return;
	}

	// The same image gives the same place for everybody. It is found on the first draw, as a cached image is complete before its `load` event.
	offset ??= mostColorfulOffset();

	const {crop, blocks} = steps[Math.min(wrongCount(), steps.length - 1)];
	const {x, y, size} = part(crop, offset);

	// The part is scaled down to the blocks, and then up without smoothing.
	const small = new OffscreenCanvas(blocks, blocks);
	const smallContext = small.getContext('2d');
	smallContext.imageSmoothingQuality = 'high';
	smallContext.drawImage(image, x, y, size, size, 0, 0, blocks, blocks);
	context.imageSmoothingEnabled = false;
	context.drawImage(small, 0, 0, canvas.width, canvas.height);
};

const shareText = () => {
	const squares = guesses.map(guess => guess === puzzle.title ? '🟩' : '🟥').join('');
	return `Appdle #${number} ${isWon() ? guesses.length : 'X'}/${maximumGuesses}\n${squares}\n${location.origin}${location.pathname}`;
};

const render = () => {
	document.querySelector('#appdle-number').textContent = `#${number}`;

	const items = guesses.map(guess => {
		const item = document.createElement('li');
		const isCorrect = guess === puzzle.title;
		item.textContent = `${isCorrect ? '✓' : '✗'} ${guess}`;

		if (isCorrect) {
			item.dataset.state = 'correct';
		}

		return item;
	});

	attempts.replaceChildren(...items);

	for (const [index, slot] of slots.entries()) {
		const guess = guesses[index];

		if (guess === undefined) {
			delete slot.dataset.state;
		} else {
			slot.dataset.state = guess === puzzle.title ? 'correct' : 'wrong';
		}
	}

	form.hidden = isDone();
	result.hidden = !isDone();

	// The status is the headline of the result.
	if (isDone()) {
		status.textContent = isWon() ? `You got it in ${guessCount(guesses.length)}!` : 'Out of guesses.';
		status.dataset.state = 'done';
		document.querySelector('#appdle-answer-start').textContent = isWon() ? 'The app is ' : 'The app was ';

		const answer = document.querySelector('#appdle-answer');
		answer.href = puzzle.url;
		answer.textContent = puzzle.title;
		copyButton.setAttribute('text', shareText());
	} else {
		delete status.dataset.state;
	}

	if (image.complete) {
		draw();
	}
};

// A message after a guess that was not counted. It is cleared first, so screen readers say the same message again, like after the same mistake twice.
const sayAgain = text => {
	status.textContent = '';

	requestAnimationFrame(() => {
		status.textContent = text;
	});
};

const remainingText = () => `${guessCount(maximumGuesses - guesses.length)} left.`;

form.addEventListener('submit', event => {
	event.preventDefault();

	if (!input.value.trim()) {
		return;
	}

	const name = names.get(normalize(input.value));

	if (!name) {
		sayAgain(`“${input.value.trim()}” is not one of the apps. Pick a name from the list.`);
		return;
	}

	if (guesses.includes(name)) {
		sayAgain(`You already guessed ${name}.`);
		return;
	}

	guesses.push(name);
	input.value = '';
	save();

	if (!isDone()) {
		status.textContent = `Not ${name}. ${remainingText()}`;
	}

	render();

	// The form is hidden when the game ends, so the focus moves to the result, which screen readers read from the answer.
	if (isDone()) {
		result.focus();
	}
});

// Plays the puzzle of today again.
restartButton.addEventListener('click', () => {
	guesses.length = 0;
	save();
	delete canvas.dataset.state;
	canvas.ariaLabel = 'A pixelated part of the icon of today’s app';
	status.textContent = remainingText();
	render();
	input.focus();
});

image.addEventListener('load', draw);

if (!isDone()) {
	status.textContent = remainingText();
}

render();
