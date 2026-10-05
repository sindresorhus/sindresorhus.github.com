// The 1999 page: a rainbow trail of sparkles and a word behind the mouse pointer, Zap the Aliens, a game where the visitor zaps the aliens that appear in the holes in the last 30 seconds of 1999, and the toys of a home page: the splash with the sound of a modem, the MIDI jukebox, the pop-up, the Y2K countdown, Glitter the virtual unicorn, the butler, the fun facts, the poll, the visitor counter, the guestbook, the banner ad, the quiz show, the computer report, the Matrix, the downloads, the Display Properties with the wallpaper, the screen savers, the mouse trails, the snow, and the scrolling title, the Konami code, the win of Solitaire, the blue screen of the skull, Snake on a mobile phone, the midnight party of the year 2000, and my computer, a desktop of Windows 98 with Unicorn Paint, Y2K Bugsweeper, a secret diary, Solitaire, a defragmenter, and the Recycle Bin. What the visitor does is kept in the browser.
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
const finePointer = matchMedia('(pointer: fine)');
const {facts, tunes, quiz} = JSON.parse(document.querySelector('#geocities-data').textContent);

// The speculation rules of the site can prerender the page while the pointer rests on a link to it. The toys wait until the visitor opens it, so a page that nobody opens does not count a visit or make Glitter hungry.
if (document.prerendering) {
	await new Promise(resolve => {
		document.addEventListener('prerenderingchange', resolve, {once: true});
	});
}

// The storage can be missing or full, like in a private window, so each toy also works without it.
const load = (key, fallback) => {
	try {
		const value = localStorage.getItem(key);
		return value === null ? fallback : (JSON.parse(value) ?? fallback);
	} catch {
		return fallback;
	}
};

// Saving can fail the same way, and then the toy only forgets what the visitor did when the page closes.
const save = (key, value) => {
	try {
		localStorage.setItem(key, JSON.stringify(value));
	} catch {}
};

// For the toys that show steps one after the other, like the dial-up and the Y2K check.
const wait = milliseconds => new Promise(resolve => {
	setTimeout(resolve, milliseconds);
});

const randomItem = items => items[Math.floor(Math.random() * items.length)];

// How many frames of 60 a second have passed since the last frame, so things move at the same speed on fast and slow screens. It is never negative, as a still frame can be drawn with an older time, and it is at most a few frames, so a long pause does not make things jump.
const frameScale = (time, lastTime, maximum = 3) => Math.min(Math.max((time - (lastTime ?? time)) / (1000 / 60), 0), maximum);

// Like “1 minute” or “2 minutes”.
const plural = (count, word) => `${count} ${word}${count === 1 ? '' : 's'}`;

// Removes the element when its animation ends, or is canceled, like when the visitor turns on reduced motion, which hides it.
const removeWhenDone = (element, onRemove) => {
	const remove = () => {
		if (!element.isConnected) {
			return;
		}

		element.remove();
		onRemove?.();
	};

	element.addEventListener('animationend', remove);
	element.addEventListener('animationcancel', remove);
};

// The date with the Y2K bug of old scripts, which added “19” in front of the years since 1900, like 19126.
const buggyYear = date => `19${date.getFullYear() - 1900}`;

// The rainbow trail: a big sparkle or star at the pointer every few pixels it moves, each in the next color of the rainbow, which spins, shrinks, fades, and falls by itself. A word follows the pointer too, one letter after the other, like the DHTML scripts of 1999. Only for a mouse, not for touch, and not for visitors who prefer reduced motion.
const sparkleTemplate = document.querySelector('#geocities-sparkle');
const starTemplate = document.querySelector('#geocities-star');
const letterTemplate = document.querySelector('#geocities-letter');
// A sparkle every 14 pixels of movement, so a fast pointer leaves a long trail and a slow one a short trail. At most 40 at once, so the page stays fast.
const sparkleSpacing = 14;
const maximumSparkles = 40;
let lastSparkle;
let sparkleCount = 0;

// The hue of the last sparkle, in degrees.
let hue = 0;

const usesTrail = event => event.pointerType === 'mouse' && finePointer.matches && !reducedMotion.matches;

// Over a game or a drawing, like Lemmingz or Unicorn Paint, the trail would cover what the visitor plays with, so it waits outside.
const isOverGame = event => event.target.closest?.('canvas, [role="application"]') !== null;

const addSparkle = (x, y) => {
	// 23 degrees is not a divisor of 360, so the colors do not repeat in a short cycle.
	hue = (hue + 23) % 360;
	const isStar = Math.random() < 0.4;
	const sparkle = (isStar ? starTemplate : sparkleTemplate).content.firstElementChild.cloneNode(true);
	// Scattered up to 12 pixels around the point, and a little below it, so the trail looks like it falls from the tip of the pointer.
	sparkle.style.left = `${x + ((Math.random() - 0.5) * 24)}px`;
	sparkle.style.top = `${y + 12 + ((Math.random() - 0.5) * 24)}px`;

	// The sparkle GIF is yellow, so turning its hue gives every color of the rainbow.
	const glow = `hsl(${hue} 100% 60%)`;
	if (isStar) {
		sparkle.style.color = glow;
		sparkle.style.textShadow = `0 0 8px ${glow}, 0 0 16px ${glow}`;
	} else {
		const size = 40 + (Math.random() * 40);
		sparkle.style.width = `${size}px`;
		sparkle.style.height = 'auto';
		sparkle.style.filter = `hue-rotate(${hue - 50}deg) saturate(4) drop-shadow(0 0 6px ${glow})`;
	}

	removeWhenDone(sparkle, () => {
		sparkleCount--;
	});

	sparkleCount++;
	document.body.append(sparkle);
};

// Each letter moves a part of the way to the letter in front of it on each frame, so the word trails behind the pointer like a snake. The frames stop when the letters have caught up.
const trailWord = [...'WELCOME!!!'];
const letterSpacing = 22;
// The letters, each with its element and its place, made at the first move of the pointer.
let letters;

// The place that the first letter moves to.
let target;

// The frame that moves the letters, or `undefined` when they stand still.
let trailFrame;
let areLettersHidden = false;

// Shows or hides the letters, and only writes to them when that changes, as it runs on every move of the pointer.
const hideLetters = isHidden => {
	if (isHidden === areLettersHidden) {
		return;
	}

	areLettersHidden = isHidden;

	for (const letter of letters ?? []) {
		letter.element.hidden = isHidden;
	}
};

const moveLetters = time => {
	let isMoving = false;

	for (const [index, letter] of letters.entries()) {
		const leader = index === 0 ? target : {x: letters[index - 1].x + letterSpacing, y: letters[index - 1].y};
		// Each frame closes 35% of the gap, so a letter slows down as it catches up, and the word stretches out when the pointer moves fast.
		const deltaX = leader.x - letter.x;
		const deltaY = leader.y - letter.y;
		letter.x += deltaX * 0.35;
		letter.y += deltaY * 0.35;
		isMoving ||= Math.abs(deltaX) > 0.5 || Math.abs(deltaY) > 0.5;

		// The colors go around the rainbow over time, and the 10 letters are 36 degrees apart, so the word always shows the whole rainbow.
		letter.element.style.translate = `${letter.x}px ${letter.y}px`;
		letter.element.style.color = `hsl(${((time / 8) + (index * 36)) % 360} 100% 55%)`;
	}

	trailFrame = isMoving ? requestAnimationFrame(moveLetters) : undefined;
};

const followPointer = (x, y) => {
	// Below and to the right of the pointer, so the word does not cover what the visitor points at.
	target = {x: x + 18, y: y + 18};

	letters ??= trailWord.map(character => {
		const element = letterTemplate.content.firstElementChild.cloneNode(true);
		element.textContent = character;
		document.body.append(element);
		return {element, ...target};
	});

	hideLetters(false);
	trailFrame ??= requestAnimationFrame(moveLetters);
};

document.addEventListener('pointermove', event => {
	if (!usesTrail(event)) {
		return;
	}

	if (isOverGame(event)) {
		removeTrails();
		return;
	}

	// The trail that the visitor picked in the Display Properties.
	if (trailKind.value === 'elastic') {
		followWithBalls(event.clientX, event.clientY);
		return;
	}

	if (trailKind.value === 'clock') {
		followWithClock(event.clientX, event.clientY);
		return;
	}

	if (trailKind.value !== 'sparkles') {
		return;
	}

	followPointer(event.clientX, event.clientY);

	if (
		sparkleCount >= maximumSparkles
		|| (lastSparkle && Math.hypot(event.clientX - lastSparkle.x, event.clientY - lastSparkle.y) < sparkleSpacing)
	) {
		return;
	}

	lastSparkle = {x: event.clientX, y: event.clientY};
	addSparkle(event.clientX, event.clientY);
}, {passive: true});

// The letters, the balls, and the clock go away when the pointer leaves the window, so they do not wait at the edge.
document.documentElement.addEventListener('pointerleave', () => {
	removeTrails();
});

// A click bursts into a ring of rainbow stars.
document.addEventListener('pointerdown', event => {
	if (
		!usesTrail(event)
		|| trailKind.value !== 'sparkles'
		|| isOverGame(event)
	) {
		return;
	}

	for (let index = 0; index < 8 && sparkleCount < maximumSparkles; index++) {
		const angle = (index / 8) * Math.PI * 2;
		addSparkle(event.clientX + (Math.cos(angle) * 30), event.clientY + (Math.sin(angle) * 30));
	}
});

// The game. Each alien stays a little shorter than the one before it, so the end of the year is busy. Now and then Glitter peeks out of a hole instead, and zapping her costs 3 points. A click on an empty hole costs a point, so clicking all the holes as fast as possible does not win.
const game = document.querySelector('#geocities-game');
const startButton = document.querySelector('#geocities-start');
const clock = document.querySelector('#geocities-clock');
const score = document.querySelector('#geocities-score');
const holes = [...game.querySelectorAll('[data-hole]')];
const duration = 30;
const storageKey = 'geocities-best-score';

let points = 0;
let secondsLeft = 0;
let isGameOn = false;

// The hole with the alien or Glitter, or `undefined` between them.
let alienHole;

// The timer that moves the alien to the next hole, and the timer of the clock.
let alienTimer;
let clockTimer;

const loadBestScore = () => Number(load(storageKey, 0)) || 0;

// The 30 seconds of the game are the last 30 seconds of 1999, so the clock counts from 11:59:30 PM to midnight.
const showClock = () => {
	clock.textContent = secondsLeft > 0 ? `11:59:${String(60 - secondsLeft).padStart(2, '0')} PM` : '12:00:00 AM';
};

// The name of the hole says what is in it, for screen readers.
const label = hole => {
	const number = hole.dataset.hole;
	const names = {alien: `Alien in hole ${number}!`, friend: `Glitter in hole ${number}. Do not zap her!`};
	hole.setAttribute('aria-label', names[hole.dataset.state] ?? `Hole ${number}`);
};

// Shows a state on a hole for a moment, like “ZAP!” or “MISS”, unless something else is in the hole by then.
const flashHole = (hole, state) => {
	hole.dataset.state = state;
	setTimeout(() => {
		if (hole.dataset.state === state) {
			delete hole.dataset.state;
		}
	}, 300);
};

const clearAlien = () => {
	if (!alienHole) {
		return;
	}

	delete alienHole.dataset.state;
	label(alienHole);
	alienHole = undefined;
};

const showAlien = () => {
	clearAlien();

	// Not in a hole that still shows “ZAP!”.
	const free = holes.filter(hole => !hole.dataset.state);
	alienHole = free[Math.floor(Math.random() * free.length)];
	// Glitter peeks out of about one hole in six, but never in the first seconds, so the visitor first learns what an alien looks like.
	alienHole.dataset.state = secondsLeft < duration - 3 && Math.random() < 0.17 ? 'friend' : 'alien';
	label(alienHole);

	// From 1.2 seconds at the start to 0.6 seconds at the end.
	const stay = 600 + (600 * secondsLeft / duration);
	alienTimer = setTimeout(showAlien, stay);
};

const showPoints = message => {
	score.textContent = `Score: ${points}${message ? ` ${message}` : ''}`;
};

const end = () => {
	isGameOn = false;
	clearTimeout(alienTimer);
	clearInterval(clockTimer);
	clearAlien();

	// The holes are disabled, so the focus moves to the button that starts a new game.
	if (holes.includes(document.activeElement)) {
		startButton.focus();
	}

	for (const hole of holes) {
		delete hole.dataset.state;
		hole.disabled = true;
	}

	const best = loadBestScore();
	const isBest = points > best;
	if (isBest) {
		save(storageKey, points);
	}

	score.removeAttribute('aria-live');
	score.textContent = `Happy New Year 2000! Your score: ${points}.${isBest ? ' A new high score!' : ` Your best is ${best}.`}`;

	if (isBest) {
		celebrate();
	}
	startButton.textContent = 'Play Again';
};

// The clock ticks once a second, and the aliens come, only while the tab is visible.
const runClock = () => {
	clockTimer = setInterval(() => {
		secondsLeft--;
		showClock();

		if (secondsLeft <= 0) {
			end();
		}
	}, 1000);

	showAlien();
};

const start = () => {
	clearTimeout(alienTimer);
	clearInterval(clockTimer);

	points = 0;
	secondsLeft = duration;
	isGameOn = true;
	// Screen readers only announce the end of the game, not every zap.
	score.setAttribute('aria-live', 'off');
	showPoints();
	startButton.textContent = 'Start Over';
	showClock();

	for (const hole of holes) {
		delete hole.dataset.state;
		label(hole);
		hole.disabled = false;
	}

	// The number keys only work while the focus is in the game, and Safari does not focus a button on a click.
	if (!game.contains(document.activeElement)) {
		startButton.focus();
	}

	runClock();
};

const zap = hole => {
	if (hole.disabled) {
		return;
	}

	// The next alien comes a moment after a hit, so the visitor sees the flash of the hole.
	if (hole === alienHole) {
		clearTimeout(alienTimer);
		const isFriend = hole.dataset.state === 'friend';
		clearAlien();
		points = Math.max(0, points + (isFriend ? -3 : 1));
		showPoints(isFriend ? '(Not Glitter! -3)' : '');
		flashHole(hole, isFriend ? 'ouch' : 'zapped');
		alienTimer = setTimeout(showAlien, 250);
		return;
	}

	if (!hole.dataset.state) {
		points = Math.max(0, points - 1);
		showPoints('(Missed! -1)');
		flashHole(hole, 'missed');
	}
};

startButton.addEventListener('click', start);

for (const hole of holes) {
	hole.addEventListener('click', () => {
		zap(hole);
	});
}

// The game waits while the tab is hidden, so the visitor does not come back to a game that ended.
document.addEventListener('visibilitychange', () => {
	if (!isGameOn) {
		return;
	}

	clearTimeout(alienTimer);
	clearInterval(clockTimer);

	if (document.hidden) {
		clearAlien();
	} else {
		runClock();
	}
});

// The number keys zap the holes, in rows of three, like the keys of a phone, while the focus is in the game. They are found by their place on the keyboard, so they also work on keyboards where the digits need Shift, like French ones. Holding a key down does not zap again.
game.addEventListener('keydown', event => {
	const number = event.code?.match(/^(?:Digit|Numpad)([1-9])$/)?.[1];

	if (
		!number
		|| event.repeat
		|| event.altKey
		|| event.ctrlKey
		|| event.metaKey
	) {
		return;
	}

	const hole = holes[Number(number) - 1];
	if (hole.disabled) {
		return;
	}

	event.preventDefault();
	zap(hole);
});

// The splash: “Click here to enter” first dials up to the Internet, with each step in the status, and then hides the splash and focuses the title. When the visitor has scrolled on in the meantime, the splash stays, so the page does not jump.
const splash = document.querySelector('#geocities-splash');
const enterLink = document.querySelector('#geocities-enter');
const dialUp = document.querySelector('#geocities-dial-up');
const welcome = document.querySelector('#geocities-welcome');
let isDialing = false;

enterLink.addEventListener('click', async event => {
	event.preventDefault();

	if (isDialing) {
		return;
	}

	isDialing = true;
	playModemSound().catch(error => {
		console.error(error);
	});

	for (const [step, milliseconds] of [['Dialing 555-1999…', 1800], ['Handshaking… beeeeep krrrrrrr…', 1800], ['Verifying user name and password…', 800], ['Connected at 56,000 bps!', 800]]) {
		dialUp.textContent = step;
		await wait(milliseconds);
	}

	isDialing = false;

	// Hiding a splash that is above the window would move the page up under the visitor.
	if (splash.getBoundingClientRect().bottom < 0) {
		return;
	}

	// The title only gets the focus when the visitor has not moved it in the meantime.
	const hadFocus = splash.contains(document.activeElement) || document.activeElement === document.body;
	splash.hidden = true;

	if (hadFocus) {
		welcome.focus();
	}
});

// The jukebox plays the notes of a tune as a quiet square wave, and repeats it until the visitor presses Stop or leaves the tab. Each repeat is scheduled just before the one before it ends.
const tuneSelect = document.querySelector('#geocities-midi-tune');
const playButton = document.querySelector('#geocities-midi-play');
const stopButton = document.querySelector('#geocities-midi-stop');
const midiStatus = document.querySelector('#geocities-midi-status');
// One audio context for the jukebox and the modem, made at the first click, as browsers only allow sound after one.
let audioContext;

// The volume of the music that plays now, or `undefined` when no music plays.
let output;

// The timer that schedules the next repeat of the tune.
let repeatTimer;

// The jukebox and the modem share the audio device, so it is only freed when neither plays, and no Play waits for the device.
let isModemPlaying = false;
let isStartingMusic = false;

const freeAudio = () => {
	if (
		!output
		&& !isModemPlaying
		&& !isStartingMusic
	) {
		audioContext?.suspend();
	}
};

// Counts the times the music starts and stops, so a Play that waits for the audio device does not start a second copy after another Play or a Stop.
let playCount = 0;

// The frequency of a MIDI note. Note 69 is the A at 440 Hz, and each note up is a semitone, which is the twelfth root of 2 higher.
const frequency = note => 440 * (2 ** ((note - 69) / 12));

// Plays the tones together from the time, for the length in seconds.
const playTones = (frequencies, time, length, destination, type = 'sine') => {
	for (const value of frequencies) {
		const oscillator = new OscillatorNode(audioContext, {type, frequency: value});
		oscillator.connect(destination);
		oscillator.start(time);
		oscillator.stop(time + length);
	}
};

// The sound of a modem that dials in, quietly: the dial tone, the number 555-1999 in touch tones, the answer tone, and the screech of the handshake. The audio device is freed again at the end, unless the jukebox plays.
const playModemSound = async () => {
	audioContext ??= new AudioContext();
	await audioContext.resume();
	isModemPlaying = true;

	const destination = new GainNode(audioContext, {gain: 0.03});
	destination.connect(audioContext.destination);
	let time = audioContext.currentTime + 0.05;

	// The dial tone of the phone line, the two tones of 350 Hz and 440 Hz.
	playTones([350, 440], time, 0.8, destination);
	time += 0.9;

	// Each key of a touch-tone phone plays two tones at once: one for its row and one for its column.
	const touchTones = {1: [697, 1209], 5: [770, 1336], 9: [852, 1477]};
	for (const digit of '5551999') {
		playTones(touchTones[digit], time, 0.1, destination);
		time += 0.16;
	}

	// The modem at the other end answers with a tone of 2100 Hz.
	time += 0.5;
	playTones([2100], time, 0.7, destination);
	time += 0.75;

	// The screech: tones that jump around, with noise.
	for (let step = 0; step < 12; step++) {
		playTones([1000 + (Math.random() * 2000), 600 + (Math.random() * 600)], time, 0.11, destination, step % 2 ? 'square' : 'sawtooth');
		time += 0.1;
	}

	// The hiss at the end: 0.8 seconds of random samples, which is white noise.
	const noise = new AudioBuffer({length: Math.round(audioContext.sampleRate * 0.8), sampleRate: audioContext.sampleRate});
	const samples = noise.getChannelData(0);
	for (let index = 0; index < samples.length; index++) {
		samples[index] = (Math.random() * 2) - 1;
	}

	const hiss = new AudioBufferSourceNode(audioContext, {buffer: noise});
	hiss.connect(new GainNode(audioContext, {gain: 0.4})).connect(destination);
	hiss.start(time);
	time += 0.8;

	setTimeout(() => {
		destination.disconnect();
		isModemPlaying = false;
		freeAudio();
	}, (time - audioContext.currentTime + 0.2) * 1000);
};

// Plays the tune once into its own output, starting at the time, and schedules the next time to start right where this one ends.
const playTune = ({tune, speed, start, destination}) => {
	const secondsPerBeat = 60 / (tune.tempo * speed);
	let time = Math.max(start, audioContext.currentTime + 0.05);

	for (const [note, beats] of tune.notes) {
		const length = beats * secondsPerBeat;

		if (note > 0) {
			// Each note fades in quickly and stops before its end, so two notes of the same pitch in a row sound like two notes, not one long one.
			const oscillator = new OscillatorNode(audioContext, {type: 'square', frequency: frequency(note)});
			const envelope = new GainNode(audioContext, {gain: 0});
			envelope.gain.setValueAtTime(0, time);
			envelope.gain.linearRampToValueAtTime(1, time + 0.01);
			envelope.gain.setValueAtTime(1, time + (length * 0.7));
			envelope.gain.linearRampToValueAtTime(0, time + (length * 0.9));
			oscillator.connect(envelope).connect(destination);
			oscillator.start(time);
			oscillator.stop(time + length);
		}

		time += length;
	}

	// Like the real Mountain King, some tunes get faster each time, up to twice as fast. The next repeat is scheduled 0.2 seconds before this one ends, so there is no gap, even when the timer is late.
	repeatTimer = setTimeout(() => {
		playTune({tune, speed: Math.min(speed * tune.speedUp, 2), start: time, destination});
	}, (time - audioContext.currentTime - 0.2) * 1000);
};

const stopMusic = () => {
	playCount++;
	clearTimeout(repeatTimer);
	output?.disconnect();
	output = undefined;
	document.dispatchEvent(new CustomEvent('geocities-music', {detail: {isPlaying: false, source: 'jukebox'}}));
	// Frees the audio device until the next Play, unless the modem still plays.
	freeAudio();

	if (document.activeElement === stopButton) {
		playButton.focus();
	}

	stopButton.disabled = true;
};

const playMusic = async () => {
	stopMusic();
	// Waking the audio device takes a moment, and the visitor can press Play or Stop again in the meantime. Then this Play is old, and does nothing.
	const count = playCount;
	audioContext ??= new AudioContext();
	isStartingMusic = true;

	try {
		await audioContext.resume();
	} finally {
		isStartingMusic = false;
	}

	if (count !== playCount) {
		return;
	}

	if (document.hidden) {
		freeAudio();
		return;
	}

	// Quiet, and softer than a plain square wave.
	output = new GainNode(audioContext, {gain: 0.05});
	output.connect(new BiquadFilterNode(audioContext, {type: 'lowpass', frequency: 1800})).connect(audioContext.destination);

	const tune = tunes.find(tune => tune.file === tuneSelect.value) ?? tunes[0];
	playTune({tune, speed: 1, start: 0, destination: output});
	midiStatus.textContent = `Now playing: ${tune.file} (${tune.title}) ♪`;
	stopButton.disabled = false;
	document.dispatchEvent(new CustomEvent('geocities-music', {detail: {isPlaying: true, source: 'jukebox'}}));
};

playButton.addEventListener('click', playMusic);

stopButton.addEventListener('click', () => {
	stopMusic();
	midiStatus.textContent = 'Stopped. Ahh, silence.';
});

tuneSelect.addEventListener('change', () => {
	if (output) {
		playMusic();
	}
});

document.addEventListener('visibilitychange', () => {
	if (document.hidden && output) {
		stopMusic();
		midiStatus.textContent = 'Stopped, as you left the page.';
	}
});

// One tune plays at a time on the page: each music player sends a `geocities-music` event with its `source` when it starts, and the others stop. A Play that still waits for the audio device stops too.
document.addEventListener('geocities-music', event => {
	if (
		event.detail.isPlaying
		&& event.detail.source !== 'jukebox'
		&& (output || isStartingMusic)
	) {
		stopMusic();
		midiStatus.textContent = 'Stopped, as other music started.';
	}
});

// The pop-up: closing it leaves a short note, which gets the focus, as the button is gone. The prize leads to Glitter.
const popUp = document.querySelector('#geocities-pop-up');
const popUpClosed = document.querySelector('#geocities-pop-up-closed');
const petStatus = document.querySelector('#geocities-pet-status');

document.querySelector('#geocities-pop-up-close').addEventListener('click', () => {
	popUp.hidden = true;
	popUpClosed.hidden = false;
	popUpClosed.focus();
});

document.querySelector('#geocities-pop-up-claim').addEventListener('click', () => {
	popUp.hidden = true;
	popUpClosed.textContent = 'You claimed your free unicorn! Her name is Glitter, and she lives further down the page.';
	popUpClosed.hidden = false;
	petStatus.textContent = 'Glitter is yours now! She would love a waffle.';
	// The status gets the focus, instead of the title, so screen readers read it.
	petStatus.focus();
});

// The Y2K countdown, in days from today, which has been negative since 2000. Both days are local midnights, so the count is in whole days.
const today = new Date();
const daysLeft = Math.round((new Date(2000, 0, 1) - new Date(today.getFullYear(), today.getMonth(), today.getDate())) / 86_400_000);
// A real minus sign, as the count has been negative since 2000.
document.querySelector('#geocities-y2k-days').textContent = daysLeft.toLocaleString('en-US').replace('-', '−');
document.querySelector('#geocities-y2k-today').textContent = `${today.toLocaleDateString('en-US', {month: 'long'})} ${today.getDate()}, ${buggyYear(today)}`;

const y2kStatus = document.querySelector('#geocities-y2k-status');
let isChecking = false;

document.querySelector('#geocities-y2k-check').addEventListener('click', async () => {
	if (isChecking) {
		return;
	}

	isChecking = true;

	for (const step of ['Checking Macintosh HD…', 'Checking the clock…', `Found 1 bug: the year is ${buggyYear(new Date())}!`, 'Fixing…', 'Fixed! The year is now 1900. Hmm, that is not right either.']) {
		y2kStatus.textContent = step;
		await wait(900);
	}

	isChecking = false;
});

// Glitter, the virtual unicorn. She has up to 4 hearts of food and fun, and loses one of each every hour, also while the page is closed. She makes a mess every two hours, and when she eats too much. She grows up with each time the visitor takes care of her.
const petKey = 'geocities-pet';
const maximumHearts = 4;
const maximumMesses = 3;
const hour = 3_600_000;
const day = 24 * hour;
const petScreen = document.querySelector('#geocities-pet-screen');
const petStats = document.querySelector('#geocities-pet-stats');
const petBubble = document.querySelector('#geocities-pet-bubble');
const petHat = document.querySelector('#geocities-pet-hat');
const petSprite = document.querySelector('#geocities-pet-sprite');
const petZzz = document.querySelector('#geocities-pet-zzz');
const petMess = document.querySelector('#geocities-pet-mess');
const petFace = document.querySelector('#geocities-pet-face');
const petFood = document.querySelector('#geocities-pet-food');
const petFun = document.querySelector('#geocities-pet-fun');
const petGame = document.querySelector('#geocities-pet-game');
const petGameStatus = document.querySelector('#geocities-pet-game-status');
const petButtons = document.querySelector('#geocities-pet-buttons');
const petHeartTemplate = document.querySelector('#geocities-pet-heart');
const hats = ['', '🎩', '👑', '🎉', '🕶️', '🎀', '🌸'];
const stages = [
	{name: 'Baby', id: 'baby', care: 0},
	{name: 'Teen', id: 'teen', care: 10},
	{name: 'Grown-up', id: 'grown-up', care: 30},
	{name: 'Rainbow Legend', id: 'legend', care: 75},
];

// The saved values are checked, as the storage can hold anything, like the values of an older version of the page.
const clampHearts = value => Math.min(Math.max(Math.round(Number(value) || 0), 0), maximumHearts);
const count = value => Math.max(Math.round(Number(value) || 0), 0);
const stored = load(petKey, {});
const pet = {
	food: clampHearts(stored.food ?? 2),
	fun: clampHearts(stored.fun ?? 2),
	messes: Math.min(count(stored.messes), maximumMesses),
	care: count(stored.care),
	hat: count(stored.hat) % hats.length,
	adopted: Number.isFinite(stored.adopted) ? Math.min(stored.adopted, Date.now()) : Date.now(),
	// The time up to which her hunger and boredom are counted, so the part of an hour that is not counted yet is not lost.
	time: Number.isFinite(stored.time) ? Math.min(stored.time, Date.now()) : Date.now(),
	// The hours counted so far, so every second one makes a mess.
	hours: count(stored.hours),
};

// Counts the hours since the last count: one heart of food and fun for each, and a mess for every second one. It runs when the page opens, when the visitor comes back to the tab, and every minute.
const passTime = () => {
	const hours = Math.floor((Date.now() - pet.time) / hour);

	if (hours === 0) {
		return;
	}

	pet.time += hours * hour;
	pet.food = clampHearts(pet.food - hours);
	pet.fun = clampHearts(pet.fun - hours);
	// The odd hour left over from the last count counts toward the next mess.
	pet.messes = Math.min(pet.messes + Math.floor((pet.hours % 2 + hours) / 2), maximumMesses);
	pet.hours += hours;
};

passTime();

// She sleeps at night, from 11 PM to 6 AM on the clock of the visitor, until the visitor turns on the light.
const isNight = () => {
	const hour = new Date().getHours();
	return hour >= 23 || hour < 6;
};

// On the first visit, she is awake, so a visitor at night meets her, and not only a sleeping unicorn.
let isAsleep = isNight() && Object.keys(stored).length > 0;

// Whether it was night at the last check, so she falls asleep at 11 PM and wakes up at 6 AM also while the page stays open, but the light that the visitor turned on or off stays until then.
let wasNight = isAsleep;
// Whether the visitor plays the left or right game with her, and whether the jukebox plays.
let isPlaying = false;
let isDancing = false;

// The meals in a row that she got while full. The second one makes a mess.
let fullMeals = 0;

// When the visitor last made her happier by petting her, so petting fast does not fill her hearts.
let lastPetted = 0;

// The timer that ends what she does now, like a trick.
let stateTimer;

// The highest stage that her care has reached.
const stage = () => stages.findLast(item => pet.care >= item.care);
const hearts = value => '♥'.repeat(value) + '♡'.repeat(maximumHearts - value);

// Shows her on the screen as she is now, and saves her, so every change is kept.
const showPet = () => {
	petFood.textContent = hearts(pet.food);
	petFun.textContent = hearts(pet.fun);
	petFood.setAttribute('aria-label', `${pet.food} of ${maximumHearts} hearts`);
	petFun.setAttribute('aria-label', `${pet.fun} of ${maximumHearts} hearts`);

	// Her face shows the lowest of her hearts, and a mess makes her less happy.
	const faces = ['(;_;)', '(-_-)', '(-_-)', '(^o^)', '(^o^)'];
	const mood = Math.max(Math.min(pet.food, pet.fun) - (pet.messes > 0 ? 1 : 0), 0);
	petFace.textContent = isAsleep ? '(-.-) zzz' : faces[mood];

	const days = Math.floor((Date.now() - pet.adopted) / day);
	const current = stage();
	petStats.textContent = `${current.name} Glitter ★ Age: ${days} ${days === 1 ? 'day' : 'days'} ★ Care: ${pet.care}`;
	petScreen.dataset.petStage = current.id;
	petHat.textContent = hats[pet.hat];
	petMess.textContent = '♨'.repeat(pet.messes);
	petMess.setAttribute('aria-label', `${pet.messes} ${pet.messes === 1 ? 'mess' : 'messes'}`);
	petMess.hidden = pet.messes === 0;

	if (isAsleep) {
		petScreen.dataset.state = 'asleep';
	} else {
		delete petScreen.dataset.state;
	}

	petZzz.hidden = !isAsleep;
	save(petKey, pet);
};

// She says nothing and does nothing while she sleeps.
const say = message => {
	if (isAsleep) {
		return;
	}

	petBubble.textContent = message;
	delete petBubble.dataset.state;
};

// What she does shows for a moment as her state, like a backflip. It ends by time, not by the end of the animation, as there is no animation for visitors who prefer reduced motion.
const act = (state, milliseconds = 1200) => {
	if (isAsleep) {
		return;
	}

	clearTimeout(stateTimer);
	petSprite.dataset.state = state;
	stateTimer = setTimeout(() => {
		delete petSprite.dataset.state;

		if (isDancing) {
			petSprite.dataset.state = 'dancing';
		}
	}, milliseconds);
};

// Hearts that float up from her and fade, at random places around her.
const floatHearts = amount => {
	if (reducedMotion.matches || isAsleep) {
		return;
	}

	for (let index = 0; index < amount; index++) {
		const heart = petHeartTemplate.content.firstElementChild.cloneNode(true);
		heart.style.left = `${20 + (Math.random() * 60)}%`;
		heart.style.bottom = `${30 + (Math.random() * 30)}%`;
		removeWhenDone(heart);
		petSprite.parentElement.append(heart);
	}
};

// Taking care of her counts toward growing up, and a new stage is a party.
const addCare = (points = 1) => {
	const before = stage();
	pet.care += points;
	const after = stage();

	if (after === before) {
		return '';
	}

	act('rainbow', 2000);
	floatHearts(8);
	say('I grew up!!!');
	return ` WOW! Glitter grew up into a ${after.name}!`;
};

const sleepingMessage = () => randomItem(['Shh! Glitter is asleep. Turn on the light to wake her up.', 'Glitter mumbles in her sleep: “waffles…”', 'Glitter is dreaming of rainbows. Turn on the light first.']);

const tricks = [
	['backflip', 'Glitter did a backflip! The judges give her a 10!'],
	['moonwalk', 'Glitter did the moonwalk, like Michael Jackson!'],
	['rainbow', 'Glitter turned every color of the rainbow!'],
	['jump', 'Glitter jumped over the moon! Well, over the screen.'],
];

// What each button does, and the message that it says. Each changes her, and the click handler then shows and saves her.
const petMessages = {
	feed() {
		if (isAsleep) {
			return sleepingMessage();
		}

		if (pet.food === maximumHearts) {
			fullMeals++;

			if (fullMeals >= 2) {
				fullMeals = 0;
				pet.messes = Math.min(pet.messes + 1, maximumMesses);
				act('jump', 600);
				return 'Glitter ate way too much and made a little rainbow on the floor. Clean it up!';
			}

			say('I am full!');
			return 'Glitter is full! She politely says no to the waffle.';
		}

		fullMeals = 0;
		pet.food++;
		act('eating', 900);
		say(randomItem(['Yum!', 'Nom nom nom', 'More waffles!']));
		return `${randomItem(['Glitter ate a waffle with brown cheese. Yum!', 'Glitter ate a rainbow cookie. Crunchy!', 'Glitter ate a bowl of glitter flakes. Sparkly!', 'Glitter ate a carrot. Healthy!', 'Glitter ate a slice of pizza. It is 1999, after all!'])}${addCare()}`;
	},
	play() {
		if (isAsleep) {
			return sleepingMessage();
		}

		startGame();
		// The game has its own status.
		return '';
	},
	brush() {
		if (isAsleep) {
			return sleepingMessage();
		}

		act('sparkly', 900);
		floatHearts(2);

		if (pet.fun === maximumHearts) {
			return 'Glitter’s mane is already perfect. She shines anyway.';
		}

		pet.fun++;
		say('So shiny!');
		return `You brushed Glitter’s rainbow mane. So shiny!${addCare()}`;
	},
	clean() {
		if (pet.messes === 0) {
			return 'Everything is already clean. Glitter is a tidy unicorn.';
		}

		pet.messes = 0;
		say('Thank you!');
		return `You cleaned up after Glitter. She looks a bit embarrassed.${addCare()}`;
	},
	trick() {
		if (isAsleep) {
			return sleepingMessage();
		}

		const [state, message] = randomItem(tricks);
		act(state, state === 'moonwalk' || state === 'rainbow' ? 1200 : 900);
		say('Ta-da!');
		return message;
	},
	hat() {
		pet.hat = (pet.hat + 1) % hats.length;
		say(pet.hat === 0 ? 'Hat off!' : 'Do I look pretty?');
		return pet.hat === 0 ? 'Glitter took off her hat.' : `Glitter is wearing a new hat: ${hats[pet.hat]}`;
	},
	light() {
		isAsleep = !isAsleep;

		if (isAsleep) {
			clearTimeout(stateTimer);
			delete petSprite.dataset.state;
			petBubble.dataset.state = 'hidden';
			return 'You turned off the light. Good night, Glitter!';
		}

		act('jump', 600);
		say('Good morning!');
		return 'You turned on the light. Glitter is awake and ready to party!';
	},
};

for (const button of document.querySelectorAll('[data-pet-action]')) {
	button.addEventListener('click', () => {
		const message = petMessages[button.dataset.petAction]();
		showPet();
		petStatus.textContent = message;
	});
}

// Petting her floats hearts, and makes her happier once every few seconds. During the game, she is busy turning.
petSprite.addEventListener('click', () => {
	if (isPlaying) {
		return;
	}

	if (isAsleep) {
		petStatus.textContent = sleepingMessage();
		return;
	}

	act('petted', 600);
	floatHearts(3);
	say(randomItem(['Neigh! ♥', 'Hee hee!', 'That tickles!', 'More pets please!', '♥ ♥ ♥']));

	let message = 'You petted Glitter. She loves it!';
	if (Date.now() - lastPetted > 3000) {
		lastPetted = Date.now();

		if (pet.fun < maximumHearts) {
			pet.fun++;
			message += addCare();
		}
	}

	showPet();
	petStatus.textContent = message;
});

// The game of the Tamagotchi: she turns left or right five times, and the visitor guesses which way. Three right guesses win. A guess waits until she has turned, so the visitor sees each turn, and a fast double press does not play two rounds.
const rounds = 5;
const turnTime = 900;
let round = 0;
let wins = 0;
let isTurning = false;

function startGame() {
	isPlaying = true;
	isTurning = false;
	round = 0;
	wins = 0;
	petButtons.hidden = true;
	petGame.hidden = false;
	// A frame after the game shows, so screen readers announce it.
	requestAnimationFrame(() => {
		petGameStatus.textContent = `Let’s play! Round 1 of ${rounds}: which way will Glitter turn?`;
	});
	petGame.querySelector('[data-pet-guess]').focus();
}

const endGame = lastResult => {
	isPlaying = false;
	petGame.hidden = true;
	petButtons.hidden = false;
	petButtons.querySelector('[data-pet-action="play"]').focus();

	const hasWon = wins >= 3;
	pet.fun = clampHearts(pet.fun + (hasWon ? 2 : 1));
	const message = hasWon ? `You guessed ${wins} of ${rounds}! You win! Glitter is so happy.` : `You guessed ${wins} of ${rounds}. Glitter won, and she had fun anyway.`;
	say(hasWon ? 'You win!' : 'I win! Hee hee!');
	act(hasWon ? 'jump' : 'petted', 900);
	floatHearts(hasWon ? 6 : 2);
	petStatus.textContent = `${lastResult} ${message}${addCare(hasWon ? 2 : 1)}`;
	showPet();
};

for (const button of document.querySelectorAll('[data-pet-guess]')) {
	button.addEventListener('click', async () => {
		if (!isPlaying || isTurning) {
			return;
		}

		const direction = Math.random() < 0.5 ? 'left' : 'right';
		const isRight = button.dataset.petGuess === direction;
		wins += isRight ? 1 : 0;
		round++;
		isTurning = true;
		act(direction, turnTime);
		petGameStatus.textContent = `You guessed ${button.dataset.petGuess}. She turns…`;
		await wait(turnTime);
		isTurning = false;
		const result = `She turned ${direction}! ${isRight ? 'You guessed right!' : 'Not this time.'}`;
		if (round >= rounds) {
			endGame(result);
			return;
		}

		const progress = wins >= 3 ? 'You have won already, but play on!' : `You have ${wins} of the 3 you need.`;
		petGameStatus.textContent = `${result} ${progress} Round ${round + 1} of ${rounds}: which way now?`;
	});
}

// The arrow keys guess too, like the left and right buttons of a Tamagotchi. The game focuses a guess button when it starts.
document.addEventListener('keydown', event => {
	const guess = {ArrowLeft: 'left', ArrowRight: 'right'}[event.key];

	// Only while the focus is in the game, so the arrow keys of the other games, like Bugsweeper and Paint, still work.
	if (
		!guess
		|| !isPlaying
		|| !petGame.contains(event.target)
	) {
		return;
	}

	event.preventDefault();
	petGame.querySelector(`[data-pet-guess="${guess}"]`).click();
});

// She dances while the jukebox plays.
document.addEventListener('geocities-music', event => {
	if (event.detail.source !== 'jukebox') {
		return;
	}

	isDancing = event.detail.isPlaying;

	if (isDancing && !isAsleep) {
		petSprite.dataset.state = 'dancing';
		say('I love this song!');
	} else if (petSprite.dataset.state === 'dancing') {
		delete petSprite.dataset.state;
	}
});

// Now and then, she says something about how she is, unless she sleeps. The bubble is hidden from screen readers, so it does not interrupt them.
const chatter = () => {
	if (pet.messes > 0) {
		return randomItem(['Oops. I made a mess.', 'Can you clean up?']);
	}

	if (pet.food <= 1) {
		return randomItem(['I am hungry!', 'Waffles, please!', 'My tummy is rumbling.']);
	}

	if (pet.fun <= 1) {
		return randomItem(['I am bored!', 'Play with me!', 'Let’s play a game!']);
	}

	return randomItem(['Neigh!', 'Is it the year 2000 yet?', 'I love your home page!', 'Did you sign the guestbook?', 'Zap those aliens!', 'Hilsen fra Norge!', 'I am better than a Furby.', 'Pet me!', 'Try the Konami code!']);
};

setInterval(() => {
	if (document.hidden || isAsleep || isPlaying) {
		return;
	}

	say(chatter());
}, 15_000);

const updatePet = () => {
	if (document.hidden) {
		return;
	}

	passTime();

	if (isNight() !== wasNight) {
		wasNight = isNight();
		isAsleep = wasNight;
		clearTimeout(stateTimer);
		delete petSprite.dataset.state;
		petBubble.dataset.state = 'hidden';
		say('Good morning!');
		petStatus.textContent = isAsleep ? 'It is 11 PM. Glitter fell asleep. Good night!' : 'It is 6 AM. Glitter woke up. Good morning!';
	}

	showPet();
};

setInterval(updatePet, 60_000);
document.addEventListener('visibilitychange', updatePet);

if (isAsleep) {
	petBubble.dataset.state = 'hidden';
}

// The page disables her button for visitors without scripts.
petSprite.disabled = false;
showPet();

// Glitter cheers for the big wins on the page, unless she sleeps.
const glitterCheers = () => {
	if (isAsleep) {
		return;
	}

	act('jump', 1500);
	floatHearts(8);
	say('You are amazing!!!');
};

// The butler picks the first answer whose words are in the question, or a random answer. The order matters: a question about “Norway and unicorns” gets the answer about unicorns.
const butlerQuestion = document.querySelector('#geocities-butler-question');
const butlerAnswer = document.querySelector('#geocities-butler-answer');

const answers = [
	[/unicorn/i, 'Unicorns are real! Glitter, my virtual unicorn, lives further down this page.'],
	[/norw|norge|fjord|oslo|bergen/i, 'Norway is the best country. We have fjords, brown cheese, and the Opera browser.'],
	[/\bapps?\b|\bmac\b|software|program/i, 'Sindre makes apps! Try the Random link of the webring at the top.'],
	[/y2k|2000|millennium/i, 'Do not panic. But fill the bathtub with water, just in case.'],
	[/alien|game|zap/i, 'Zap the aliens with the number keys 1 to 9. The last seconds of 1999 are the busiest!'],
	[/\b(?:weather|rain|sunny)\b/i, 'It is raining in Bergen. It is always raining in Bergen.'],
	[/meaning of life|\b42\b/i, '42. Everybody knows that.'],
	[/music|midi|song/i, 'Try the MIDI Jukebox at the top. Grieg is my favorite. He is from Norway, like Sindre.'],
	[/\btabs?\b|spaces|indent/i, 'Tabs. Next question, please.'],
	[/who are you|your name|butler/i, 'I am the butler of this page. I live in a CGI script.'],
	[/\b(?:hi|hello|hey)\b/i, 'Good day! How may I help you surf the web?'],
];

const otherAnswers = [
	'I do not know, but have you tried turning it off and on again?',
	'I searched the whole Internet, all 3 million pages, and found nothing. Try AltaVista!',
	'Good question! Ask me again after the year 2000.',
	'My crystal ball says: maybe.',
	'Let me think about it while your modem dials in.',
];

document.querySelector('#geocities-butler-form').addEventListener('submit', event => {
	event.preventDefault();

	const question = butlerQuestion.value.trim();
	if (!question) {
		return;
	}

	butlerAnswer.textContent = answers.find(([pattern]) => pattern.test(question))?.[1] ?? randomItem(otherAnswers);
});

// Another fun fact, never the same one twice in a row.
const fact = document.querySelector('#geocities-fact');

document.querySelector('#geocities-next-fact').addEventListener('click', () => {
	fact.textContent = randomItem(facts.filter(item => item !== fact.textContent));
});

// The poll adds the vote of the visitor to the made-up votes, and shows the results as bars of text. The vote is remembered, so the visitor sees the results again later.
const pollKey = 'geocities-poll';
const pollForm = document.querySelector('#geocities-poll-form');
const pollStatus = document.querySelector('#geocities-poll-status');
const pollResults = document.querySelector('#geocities-poll-results');
const pollOptions = [...pollForm.querySelectorAll('[data-votes]')];

// Each bar is 20 characters, one for each 5%.
const showResults = vote => {
	// The made-up votes are on the options in the HTML, and the vote of the visitor is one more.
	const counts = pollOptions.map(option => Number(option.dataset.votes) + (option.value === vote ? 1 : 0));
	let total = 0;
	for (const count of counts) {
		total += count;
	}

	pollResults.replaceChildren(...pollOptions.map((option, index) => {
		const percent = Math.round(counts[index] / total * 100);
		const bar = document.createElement('span');
		bar.setAttribute('aria-hidden', 'true');
		bar.textContent = `${'█'.repeat(Math.round(percent / 5)).padEnd(20, '░')} `;

		const item = document.createElement('li');
		item.append(`${option.labels[0].textContent}: `, bar, `${percent}% (${counts[index].toLocaleString('en-US')} votes)`);
		return item;
	}));

	pollForm.hidden = true;
	pollResults.hidden = false;
};

const savedVote = load(pollKey, undefined);
if (pollOptions.some(option => option.value === savedVote)) {
	showResults(savedVote);
}

pollForm.addEventListener('submit', event => {
	event.preventDefault();

	const vote = new FormData(pollForm).get('browser');
	save(pollKey, vote);
	showResults(vote);
	pollStatus.textContent = `Thanks for voting for ${vote}! The results are 100% scientific.`;
	// The form is gone, so the thanks get the focus, with the results right after them.
	pollStatus.focus();
});

// The visitor counter counts the visits of this visitor on top of 1999, and rolls up to the number like an odometer.
const visitsKey = 'geocities-visits';
const counter = document.querySelector('#geocities-counter');
const visits = (Number(load(visitsKey, 0)) || 0) + 1;
save(visitsKey, visits);

// One digit for each box of the counter, with zeros in front, like a real counter.
const showCount = count => {
	const digits = String(count).padStart(counter.children.length, '0').slice(-counter.children.length);

	for (const [index, digit] of [...digits].entries()) {
		counter.children[index].textContent = digit;
	}
};

// Phones have no keyboard for the Konami code, so 7 taps on the counter in a row do the same.
let counterTaps = 0;
let counterTapTimer;

counter.addEventListener('click', () => {
	counterTaps++;
	clearTimeout(counterTapTimer);
	counterTapTimer = setTimeout(() => {
		counterTaps = 0;
	}, 2000);

	if (counterTaps === 7) {
		counterTaps = 0;
		document.dispatchEvent(new Event('konami'));
	}
});

const visitorNumber = 1999 + visits;
counter.setAttribute('aria-label', String(visitorNumber));

if (reducedMotion.matches) {
	showCount(visitorNumber);
} else {
	const rollStart = performance.now();
	const roll = now => {
		// From 1999 up to the number of the visitor in 1.5 seconds.
		const progress = Math.min((now - rollStart) / 1500, 1);
		showCount(Math.round(1999 + ((visitorNumber - 1999) * progress)));

		if (progress < 1) {
			requestAnimationFrame(roll);
		}
	};

	requestAnimationFrame(roll);
}

// The guestbook adds the entries of the visitor to the top, newest first, and keeps the last 20 in the browser.
const guestbookKey = 'geocities-guestbook';
const guestbookForm = document.querySelector('#geocities-guestbook-form');
const guestbookStatus = document.querySelector('#geocities-guestbook-status');
const guestbookEntries = document.querySelector('#geocities-guestbook-entries');
const entryTemplate = document.querySelector('#geocities-entry');
const storedEntries = load(guestbookKey, []);
const savedEntries = Array.isArray(storedEntries) ? storedEntries.filter(entry => typeof entry === 'object' && entry !== null) : [];

const addEntry = entry => {
	const item = entryTemplate.content.firstElementChild.cloneNode(true);

	// As text, never as HTML, so an entry cannot add markup to the page.
	for (const field of item.querySelectorAll('[data-field]')) {
		field.textContent = String(entry[field.dataset.field] ?? '');
	}

	guestbookEntries.prepend(item);
};

for (const entry of savedEntries) {
	addEntry(entry);
}

guestbookForm.addEventListener('submit', event => {
	event.preventDefault();

	const data = new FormData(guestbookForm);
	const now = new Date();
	const entry = {
		name: data.get('name').trim(),
		place: data.get('place').trim() || 'The Internet',
		date: `${String(now.getMonth() + 1).padStart(2, '0')}/${String(now.getDate()).padStart(2, '0')}/${buggyYear(now)}`,
		via: data.get('via'),
		message: data.get('message').trim(),
	};

	if (!entry.name || !entry.message) {
		guestbookStatus.textContent = 'Please write your name and a comment.';
		return;
	}

	addEntry(entry);
	savedEntries.push(entry);
	save(guestbookKey, savedEntries.slice(-20));
	guestbookForm.reset();
	guestbookStatus.textContent = `Thanks for signing my guestbook, ${entry.name}! Your entry is at the top of the list.`;
});

// A message at the bottom of the window for a few seconds, like a dialog of Windows 95.
const toast = document.querySelector('#geocities-toast');
let toastTimer;

// The text is set a frame after the toast shows, as screen readers can miss the text of a live region that appears with it.
const showToast = message => {
	toast.hidden = false;
	requestAnimationFrame(() => {
		toast.textContent = message;
	});
	clearTimeout(toastTimer);
	toastTimer = setTimeout(() => {
		toast.hidden = true;
		// Empty, so the next message is announced, also when it is the same one.
		toast.textContent = '';
	}, 5000);
};

// Right-clicking a GIF was “disabled” on many home pages of 1999. This one only pretends, so the menu still opens.
document.addEventListener('contextmenu', event => {
	if (event.target.closest('img')) {
		showToast('Right-click is disabled to protect my GIFs! Just kidding. Take them, I took them too.');
	}
});

const isApple = /Mac|iPhone|iPad/.test(navigator.userAgent);

// Phones and tablets have no keyboard shortcut for a bookmark.
const bookmarkHint = () => {
	if (navigator.maxTouchPoints > 0 && !finePointer.matches) {
		return 'Tap the share button of your browser, then Add Bookmark.';
	}

	return `Press ${isApple ? '⌘D' : 'Ctrl+D'} to bookmark my page.`;
};

document.querySelector('#geocities-bookmark').addEventListener('click', () => {
	// The bookmark gets the title as it is, so the scrolling stops until the visitor turns it on again. The setting is not saved, so it scrolls again on the next visit.
	titleCheckbox.checked = false;
	scrollTitle();
	showToast(`${bookmarkHint()} Come back soon!`);
});

// The size of the page with all its GIFs, and how long it would take to load at 56k, which really did about 53 kbps.
const loadTime = document.querySelector('#geocities-load-time');

const showLoadTime = () => {
	let bytes = 0;
	for (const entry of [...performance.getEntriesByType('navigation'), ...performance.getEntriesByType('resource')]) {
		bytes += entry.decodedBodySize || 0;
	}

	if (bytes === 0) {
		return;
	}

	// Bytes are 8 bits, and a 56k modem got about 53,000 bits a second.
	const seconds = Math.round(bytes * 8 / 53_000);
	loadTime.textContent = `This page is ${(bytes / 1_048_576).toFixed(1)} MB, so it takes ${plural(Math.floor(seconds / 60), 'minute')} and ${plural(seconds % 60, 'second')} to load at 56k. Thanks for waiting!`;
};

if (document.readyState === 'complete') {
	showLoadTime();
} else {
	addEventListener('load', showLoadTime, {once: true});
}

// The banner ad: each catch of the star wins another picture of an iMac.
const bannerStatus = document.querySelector('#geocities-banner-status');
let catches = 0;

document.querySelector('#geocities-banner-star').addEventListener('click', () => {
	catches++;
	bannerStatus.textContent = catches === 1 ? 'YOU WON!!! Your FREE iMac is a picture of an iMac. Please print it out.' : `You caught the star ${catches} times! That is ${catches} pictures of an iMac.`;
});

// Who Wants to Be a Unicornaire? A wrong answer ends the game, with the prize of the last safe level that the visitor passed: $1,000 after question 3, and $32,000 after question 5.
const quizPrize = document.querySelector('#geocities-quiz-prize');
const quizQuestion = document.querySelector('#geocities-quiz-question');
const quizAnswers = document.querySelector('#geocities-quiz-answers');
const quizLifelines = document.querySelector('#geocities-quiz-lifelines');
const quizStatus = document.querySelector('#geocities-quiz-status');
const quizStart = document.querySelector('#geocities-quiz-start');
const answerButtons = [...quizAnswers.querySelectorAll('[data-quiz-answer]')];
const lifelineButtons = [...quizLifelines.querySelectorAll('[data-quiz-lifeline]')];
const answerLetters = ['A', 'B', 'C', 'D'];
let questionIndex = 0;

// While the answer is revealed, the other answers do nothing.
let isAnswering = false;

// Each lifeline works once per game.
const usedLifelines = new Set();

// The questions of this game, each with its answers in a new order, so a visitor who plays again has to read them again, and cannot just press the same letters.
let gameQuestions = quiz;
const currentQuestion = () => gameQuestions[questionIndex];

const shuffleAnswers = question => {
	const order = question.answers.map((answer, index) => ({index, key: Math.random()})).toSorted((first, second) => first.key - second.key).map(item => item.index);
	return {...question, answers: order.map(index => question.answers[index]), correct: order.indexOf(question.correct)};
};

// After a lifeline or a new question, the focus goes to the first answer that is still there.
const focusFirstAnswer = () => {
	answerButtons.find(button => !button.disabled)?.focus();
};

const enableLifelines = () => {
	for (const button of lifelineButtons) {
		button.disabled = usedLifelines.has(button.dataset.quizLifeline);
	}
};

const showQuestion = () => {
	const {prize, question: text, answers} = currentQuestion();
	quizPrize.textContent = `Question ${questionIndex + 1} of ${quiz.length}, for ${prize}`;
	quizQuestion.textContent = text;
	quizStatus.textContent = '';

	for (const [index, button] of answerButtons.entries()) {
		button.textContent = `${answerLetters[index]}: ${answers[index]}`;
		button.disabled = false;
		delete button.dataset.state;
	}
};

const endQuiz = message => {
	quizStatus.textContent = message;
	quizStart.textContent = 'Play Again';
	quizStart.hidden = false;
	quizStart.focus();

	for (const button of [...answerButtons, ...lifelineButtons]) {
		button.disabled = true;
	}
};

quizStart.addEventListener('click', () => {
	questionIndex = 0;
	gameQuestions = quiz.map(question => shuffleAnswers(question));
	usedLifelines.clear();
	quizQuestion.hidden = false;
	quizAnswers.hidden = false;
	quizLifelines.hidden = false;
	quizStart.hidden = true;
	enableLifelines();
	showQuestion();
	focusFirstAnswer();
});

for (const [index, button] of answerButtons.entries()) {
	button.addEventListener('click', async () => {
		if (isAnswering) {
			return;
		}

		isAnswering = true;
		button.dataset.state = 'picked';
		quizStatus.textContent = 'Is that your final answer? … Let’s see…';

		// The answers stay enabled, so the focus stays on the picked one, and `isAnswering` ignores more clicks until the next question shows.
		for (const lifeline of lifelineButtons) {
			lifeline.disabled = true;
		}

		// The suspense of the show.
		await wait(1500);

		const {correct, answers} = currentQuestion();
		answerButtons[correct].dataset.state = 'correct';

		if (index !== correct) {
			isAnswering = false;
			const safePrize = questionIndex > 4 ? '$32,000' : (questionIndex > 2 ? '$1,000' : 'nothing but your dignity');
			endQuiz(`Oh no! The right answer was ${answerLetters[correct]}: ${answers[correct]}. You leave with ${safePrize}.`);
			return;
		}

		if (questionIndex === quiz.length - 1) {
			isAnswering = false;
			endQuiz('YOU ARE A UNICORNAIRE!!! You won $1,000,000 unicorn dollars! (They only work on this page.)');
			glitterCheers();
			celebrate();
			return;
		}

		// The answers wait for the next question, so a fast click is not counted for a question that the visitor has not seen.
		quizStatus.textContent = `Right! You have ${currentQuestion().prize}!`;
		await wait(1200);
		const hadFocus = quizAnswers.contains(document.activeElement) || document.activeElement === document.body;
		questionIndex++;
		showQuestion();
		enableLifelines();
		isAnswering = false;

		// The focus only moves to the new answers when the visitor has not moved it in the meantime.
		if (hadFocus) {
			focusFirstAnswer();
		}
	});
}

const lifelines = {
	fifty() {
		const {correct} = currentQuestion();
		// One wrong answer stays, picked at random.
		const wrong = answerButtons.filter((button, index) => index !== correct);
		wrong.splice(Math.floor(Math.random() * wrong.length), 1);

		for (const button of wrong) {
			button.dataset.state = 'removed';
			button.disabled = true;
		}

		return 'The computer took away two wrong answers.';
	},
	phone() {
		const {correct} = currentQuestion();
		// Mom is right most of the time. When she is not, she still picks an answer that is there, not one that 50:50 took away.
		const remaining = answerButtons.map((button, index) => index).filter(index => answerButtons[index].dataset.state !== 'removed');
		const guess = Math.random() < 0.8 ? correct : randomItem(remaining);
		return `You call mamma. She says: «Jeg tror det er ${answerLetters[guess]}, men jeg er ikke sikker. Middagen er klar!» (I think it is ${answerLetters[guess]}, but I am not sure. Dinner is ready!)`;
	},
	audience() {
		const {correct} = currentQuestion();
		const votes = answerButtons.map((button, index) => {
			if (button.dataset.state === 'removed') {
				return 0;
			}

			// Most of the audience knows the answer, like on the show.
			return index === correct ? 50 + (Math.random() * 30) : Math.random() * 20;
		});

		let total = 0;
		for (const vote of votes) {
			total += vote;
		}

		return `The audience voted: ${votes.map((vote, index) => `${answerLetters[index]} ${Math.round(vote / total * 100)}%`).join(' · ')}`;
	},
};

for (const button of lifelineButtons) {
	button.addEventListener('click', () => {
		usedLifelines.add(button.dataset.quizLifeline);
		button.disabled = true;
		quizStatus.textContent = lifelines[button.dataset.quizLifeline]();
		focusFirstAnswer();
	});
}

// The report about the computer of the visitor, from what the browser says about itself.
const userAgent = navigator.userAgent;

// An iPad says that it is a Mac, but a Mac has no touch screen.
const isPad = /Mac/.test(userAgent) && navigator.maxTouchPoints > 1;

// The first pattern that matches wins, and the order matters, as Edge and Opera also say “Chrome”, and Chrome also says “Safari”.
const browserName = [
	[/Edg\//, 'Microsoft Edge. Is that the new Internet Explorer?'],
	[/OPR\//, 'Opera! It is made in Norway, like me. Great choice!'],
	[/Firefox\//, 'Firefox. Is that the new Netscape?'],
	[/Chrome\//, 'Chrome. Never heard of it. Have you tried Netscape Navigator 4.7?'],
	[/Safari\//, 'Safari. A browser for the Mac? Cool!'],
].find(([pattern]) => pattern.test(userAgent))?.[1] ?? 'A mystery browser!';

const systemName = [
	[/iPhone/, 'An iPhone. A phone with a web browser?! What year is it?'],
	[/iPad/, 'An iPad. A computer without a keyboard?!'],
	[/Android/, 'An Android phone. A phone with a web browser?!'],
	[/Mac/, isPad ? 'An iPad. A computer without a keyboard?!' : 'A Mac! Is it an iMac in Bondi Blue, like mine?'],
	[/Windows/, 'Windows. Is it Windows 98?'],
	[/Linux/, 'Linux. You must be a hacker!'],
].find(([pattern]) => pattern.test(userAgent))?.[1] ?? 'A mystery computer!';

document.querySelector('#geocities-report-browser').textContent = browserName;
document.querySelector('#geocities-report-system').textContent = systemName;
const screenRatio = (screen.width * screen.height) / (800 * 600);
const screenComment = screenRatio >= 1 ? `so your screen is ${Math.round(screenRatio * 10) / 10} times too big!` : 'so your screen is too small! Please scroll a lot.';
document.querySelector('#geocities-report-screen').textContent = `${screen.width} × ${screen.height}. My page is best viewed at 800 × 600, ${screenComment}`;
document.querySelector('#geocities-report-colors').textContent = `${(2 ** screen.colorDepth).toLocaleString('en-US')}. My computer only shows 256!`;

const reportOnline = document.querySelector('#geocities-report-online');
const reportBill = document.querySelector('#geocities-report-bill');
const onlineSince = Date.now();

const showOnlineTime = () => {
	if (document.hidden) {
		return;
	}

	const seconds = Math.floor((Date.now() - onlineSince) / 1000);
	reportOnline.textContent = `${plural(Math.floor(seconds / 60), 'minute')} and ${plural(seconds % 60, 'second')}`;
	reportBill.textContent = `$${(Math.ceil(seconds / 60) * 0.05).toFixed(2)}, at 5 cents a minute. Do not tell my mom!`;
};

showOnlineTime();
setInterval(showOnlineTime, 1000);

// The Matrix: the red pill lets green code fall over the window for a few seconds, or until a click or a key.
const matrixStatus = document.querySelector('#geocities-matrix-status');
const matrixTemplate = document.querySelector('#geocities-matrix');
let stopRain;

const rain = () => {
	const canvas = matrixTemplate.content.firstElementChild.cloneNode(true);
	canvas.width = innerWidth;
	canvas.height = innerHeight;
	document.body.append(canvas);

	// The window is columns of 18 pixels, each with a drop: the row where its next character falls. They start above the window, at different heights, so they do not fall in a line.
	const context = canvas.getContext('2d');
	const size = 18;
	const drops = Array.from({length: Math.ceil(canvas.width / size)}, () => Math.floor(Math.random() * -40));
	const characters = [...'アイウエオカキクケコサシスセソタチツテトナニヌネノ0123456789SINDRE1999'];
	let frame;
	let lastTime = 0;

	const draw = time => {
		frame = requestAnimationFrame(draw);

		// 20 frames a second, the speed of the movie.
		if (time - lastTime < 50) {
			return;
		}

		// A thin black layer over everything fades the older characters, which leaves the green trails.
		lastTime = time;
		context.fillStyle = 'rgb(0 0 0 / 0.1)';
		context.fillRect(0, 0, canvas.width, canvas.height);
		context.fillStyle = '#00ff41';
		context.font = `${size}px monospace`;

		for (const [index, drop] of drops.entries()) {
			context.fillText(randomItem(characters), index * size, drop * size);
			// A drop below the window starts again at the top, after a random wait.
			drops[index] = drop * size > canvas.height && Math.random() > 0.95 ? 0 : drop + 1;
		}
	};

	frame = requestAnimationFrame(draw);
	let timer;

	const stop = () => {
		cancelAnimationFrame(frame);
		clearTimeout(timer);
		canvas.remove();
		removeEventListener('pointerdown', stop);
		removeEventListener('keydown', stop);

		if (stopRain === stop) {
			stopRain = undefined;
		}
	};

	addEventListener('pointerdown', stop);
	addEventListener('keydown', stop);
	timer = setTimeout(stop, 8000);
	return stop;
};

for (const button of document.querySelectorAll('[data-pill]')) {
	button.addEventListener('click', () => {
		if (button.dataset.pill === 'blue') {
			matrixStatus.textContent = 'You took the blue pill. The story ends. You wake up in your bed and believe whatever you want to believe.';
			return;
		}

		if (reducedMotion.matches) {
			matrixStatus.textContent = 'You took the red pill. Green code would fall down your screen now, but your computer prefers less motion. Follow the white unicorn.';
			return;
		}

		matrixStatus.textContent = 'Wake up, Neo… The Matrix has you. Follow the white unicorn. (Click or press a key to come back.)';
		stopRain?.();
		// After the click that started it, so that click does not stop it.
		setTimeout(() => {
			stopRain = rain();
		});
	});
}

// The downloads take forever, like over a modem, and fail, except the recipe.
const downloadWindow = document.querySelector('#geocities-download');
const downloadTitle = document.querySelector('#geocities-download-title');
const downloadText = document.querySelector('#geocities-download-text');
const downloadBar = document.querySelector('#geocities-download-bar');
const downloadTime = document.querySelector('#geocities-download-time');
const downloadCancel = document.querySelector('#geocities-download-cancel');
// A good day on a 28.8k modem.
const bytesPerSecond = 3500;

// The size of each file, the percent where it fails, and what it says at the end.
const downloads = {
	'sindre.scr': {bytes: 1_468_006, failsAt: 37, message: 'Download failed: somebody picked up the phone. Please try again when your mom is off the phone.'},
	'glitter.exe': {bytes: 3_355_443, failsAt: 63, message: 'Download failed: your hard drive is full. 4 GB was not enough after all.'},
	'waffles.txt': {bytes: 1024, failsAt: Infinity, message: 'Download complete! waffles.txt says: 1. Make waffles. 2. Add brown cheese. 3. Eat them all before your little sister does.'},
};

let downloadTimer;
let downloadButton;

const closeDownload = () => {
	clearInterval(downloadTimer);
	downloadWindow.hidden = true;
	downloadButton?.focus();
};

downloadCancel.addEventListener('click', closeDownload);

// Escape closes the download window, like the windows of the desktop.
document.addEventListener('keydown', event => {
	if (event.key === 'Escape' && !downloadWindow.hidden) {
		closeDownload();
	}
});

for (const button of document.querySelectorAll('[data-download]')) {
	button.addEventListener('click', () => {
		clearInterval(downloadTimer);
		downloadButton = button;

		const file = button.dataset.download;
		const {bytes, failsAt, message} = downloads[file];
		let percent = 0;
		downloadTitle.textContent = `Downloading ${file}`;
		downloadText.textContent = '';
		downloadTime.textContent = '';
		downloadCancel.textContent = 'Cancel';
		downloadBar.style.width = '0%';
		downloadWindow.hidden = false;
		// A frame later, so screen readers announce it, like the toast.
		requestAnimationFrame(() => {
			downloadText.textContent = `Saving ${file} from sindresorhus.com…`;
		});

		downloadTimer = setInterval(() => {
			// The progress jumps by random steps, like a real download over a modem. The small recipe is done in a few steps.
			percent += 1 + Math.floor(Math.random() * (bytes < 10_000 ? 30 : 4));

			if (percent >= Math.min(failsAt, 100)) {
				clearInterval(downloadTimer);
				percent = Math.min(failsAt, 100);
				downloadText.textContent = message;
				downloadCancel.textContent = 'Close';
			}

			downloadBar.style.width = `${percent}%`;
			const secondsLeft = Math.round(bytes * (100 - percent) / 100 / bytesPerSecond);
			downloadTime.textContent = `${percent}% done. Time left: ${Math.floor(secondsLeft / 60)} min ${secondsLeft % 60} sec (at 3.5 KB/sec)`;
		}, 250);
	});
}

// The Display Properties: the wallpaper, the screen saver, the snow, and the title that scrolls. They are kept in the browser.
const displayKey = 'geocities-display';
const root = document.querySelector('#geocities-root');
const wallpaper = document.querySelector('#geocities-wallpaper');
const saverWait = document.querySelector('#geocities-saver-wait');
const saverKind = document.querySelector('#geocities-saver-kind');
const trailKind = document.querySelector('#geocities-trail-kind');
const snowCheckbox = document.querySelector('#geocities-snow');
const titleCheckbox = document.querySelector('#geocities-title-scroll');
const display = load(displayKey, {});

// A saved value only counts when the menu has it, as the options can change.
const restoreSelect = (select, value) => {
	if ([...select.options].some(option => option.value === value)) {
		select.value = value;
	}
};

restoreSelect(wallpaper, display.wallpaper);
restoreSelect(saverWait, display.saverWait);
restoreSelect(saverKind, display.saverKind);
restoreSelect(trailKind, display.trailKind);

if (typeof display.snow === 'boolean') {
	snowCheckbox.checked = display.snow;
}

if (typeof display.titleScroll === 'boolean') {
	titleCheckbox.checked = display.titleScroll;
}

const saveDisplay = () => {
	save(displayKey, {wallpaper: wallpaper.value, saverWait: saverWait.value, saverKind: saverKind.value, trailKind: trailKind.value, snow: snowCheckbox.checked, titleScroll: titleCheckbox.checked});
};

const showWallpaper = () => {
	root.style.backgroundColor = wallpaper.value;
};

wallpaper.addEventListener('change', () => {
	showWallpaper();
	saveDisplay();
});

showWallpaper();

// The screen saver starts when the visitor leaves the page alone for the wait, and stops at the next move. Right after it starts, moves are ignored, so the click of Preview does not stop it. The Flying Unicorns are animated GIFs, and the others are drawn on a canvas of the size of the window.
const saverTemplate = document.querySelector('#geocities-saver');
const saverCanvasTemplate = document.querySelector('#geocities-saver-canvas');
let saver;
let saverFrame;
let saverShownAt = 0;
let lastActivity = Date.now();

const showSaver = () => {
	if (saver || document.hidden || reducedMotion.matches || saverKind.value === 'none') {
		return;
	}

	if (saverKind.value === 'unicorns') {
		saver = saverTemplate.content.firstElementChild.cloneNode(true);

		for (const unicorn of saver.querySelectorAll('img')) {
			// A negative delay starts each unicorn in the middle of its flight, so the screen is full right away.
			unicorn.style.top = `${5 + (Math.random() * 70)}%`;
			unicorn.style.animationDuration = `${4 + (Math.random() * 5)}s`;
			unicorn.style.animationDelay = `${-Math.random() * 8}s`;
			unicorn.style.filter = `hue-rotate(${Math.random() * 360}deg) saturate(2)`;
		}
	} else {
		saver = saverCanvasTemplate.content.firstElementChild.cloneNode(true);
		const canvas = saver.querySelector('canvas');
		canvas.width = innerWidth;
		canvas.height = innerHeight;
		const draw = saverDrawers[saverKind.value](canvas);

		const animate = time => {
			draw(time);
			saverFrame = requestAnimationFrame(animate);
		};

		saverFrame = requestAnimationFrame(animate);
	}

	saver.addEventListener('click', hideSaver);
	saverShownAt = Date.now();
	document.body.append(saver);
};

const hideSaver = () => {
	cancelAnimationFrame(saverFrame);
	saver?.remove();
	saver = undefined;
};

// A move wakes the page, also a move over the screen saver, which covers the window. A click or tap on the screen saver closes it in its own click handler, so it does not reach what is under it.
const noteActivity = event => {
	lastActivity = Date.now();

	if (
		saver
		&& Date.now() - saverShownAt > 800
		&& (event.type !== 'pointerdown' || !saver.contains(event.target))
	) {
		hideSaver();
	}
};

for (const type of ['pointermove', 'pointerdown', 'wheel', 'scroll']) {
	addEventListener(type, noteActivity, {passive: true});
}

// A key closes the screen saver and does nothing else, like Tab, which would move the focus. Shortcuts, like reloading the page, still work.
addEventListener('keydown', event => {
	lastActivity = Date.now();

	if (
		!saver
		|| event.metaKey
		|| event.ctrlKey
		|| event.altKey
	) {
		return;
	}

	event.preventDefault();
	event.stopImmediatePropagation();
	hideSaver();
}, {capture: true});

// The time away from the tab does not count as time without moves, or the screen saver would start as soon as the visitor comes back.
document.addEventListener('visibilitychange', () => {
	lastActivity = Date.now();
});

// Music that plays counts as activity, so the screen saver does not start in the middle of a song, like during karaoke or the cracktro. Each player of the page says when it starts and stops with the `geocities-music` event.
const playingSources = new Set();

document.addEventListener('geocities-music', event => {
	const source = event.detail?.source ?? 'jukebox';

	if (event.detail?.isPlaying) {
		playingSources.add(source);
	} else {
		playingSources.delete(source);
	}
});

// One check a second, instead of a new timer for each move of the pointer.
setInterval(() => {
	if (playingSources.size > 0) {
		lastActivity = Date.now();
		return;
	}

	if (Date.now() - lastActivity > Number(saverWait.value) * 1000) {
		showSaver();
	}
}, 1000);

saverWait.addEventListener('change', saveDisplay);

trailKind.addEventListener('change', () => {
	removeTrails();
	saveDisplay();
});

document.querySelector('#geocities-saver-preview').addEventListener('click', () => {
	if (reducedMotion.matches) {
		showToast('Your computer prefers less motion, so the screen saver stays home.');
		return;
	}

	if (saverKind.value === 'none') {
		showToast('Pick a screen saver first. Although (None) is very relaxing.');
		return;
	}

	showSaver();
});

// The snow falls from the top of the window, each flake at its own place, size, and speed.
const snowTemplate = document.querySelector('#geocities-snowflake');
let snowflakes = [];

const showSnow = () => {
	for (const flake of snowflakes) {
		flake.remove();
	}

	snowflakes = [];

	if (!snowCheckbox.checked || reducedMotion.matches) {
		return;
	}

	for (let index = 0; index < 30; index++) {
		const flake = snowTemplate.content.firstElementChild.cloneNode(true);
		flake.style.left = `${Math.random() * 100}%`;
		flake.style.fontSize = `${0.75 + Math.random()}rem`;
		flake.style.animationDuration = `${7 + (Math.random() * 9)}s`;
		// A negative delay, so the snow is already falling everywhere when it starts, instead of starting at the top all at once.
		flake.style.animationDelay = `${-Math.random() * 16}s`;
		snowflakes.push(flake);
	}

	document.body.append(...snowflakes);
};

snowCheckbox.addEventListener('change', () => {
	showSnow();
	saveDisplay();
});

showSnow();

// The title scrolls in the tab, like the scrolling status bars of 1999.
const pageTitle = document.title;
const scrollingTitle = ` ★ ${pageTitle} ★ Welcome to my home page!!! ★ Sign my guestbook! ★`;
let titleTimer;

const scrollTitle = () => {
	clearInterval(titleTimer);
	document.title = pageTitle;

	if (!titleCheckbox.checked || reducedMotion.matches) {
		return;
	}

	// Each step moves the first character to the end.
	let offset = 0;
	titleTimer = setInterval(() => {
		offset = (offset + 1) % scrollingTitle.length;
		document.title = scrollingTitle.slice(offset) + scrollingTitle.slice(0, offset);
	}, 300);
};

titleCheckbox.addEventListener('change', () => {
	scrollTitle();
	saveDisplay();
});

scrollTitle();

// The snow and the title follow a change of the motion setting while the page is open.
reducedMotion.addEventListener('change', () => {
	showSnow();
	scrollTitle();

	if (reducedMotion.matches) {
		hideSaver();
		removeTrails();
		stopRain?.();
	}
});

// “You have new mail!” for visitors who come back, with a note from my mom, Glitter, or a friend. The visit of today is already counted, so a visitor who comes back has 2 or more.
const newMail = document.querySelector('#geocities-new-mail');
const mails = [
	'From: mamma. «Middagen er klar! Slå av datamaskinen nå.» (Dinner is ready! Turn off the computer now.)',
	'From: Glitter. Neigh!!! I missed you! Where have you been? I am hungry. ♥',
	'From: Trond. re: re: re: FWD: cool page!!! Did you see my new Doom page? It does not work yet.',
];

// The text is set a frame after the note shows, so screen readers read it.
if ((Number(load('geocities-visits', 0)) || 0) > 1) {
	newMail.hidden = false;
	requestAnimationFrame(() => {
		document.querySelector('#geocities-new-mail-text').textContent = `You have new mail! ${randomItem(mails)}`;
	});
}

// The close button is gone with the note, so the focus moves to the title below it.
document.querySelector('#geocities-new-mail-close').addEventListener('click', () => {
	newMail.hidden = true;
	document.querySelector('#geocities-welcome').focus();
});

// The prize of the banner ad: after a catch, the visitor can print the iMac, with a certificate that only shows in the print.
const bannerPrint = document.querySelector('#geocities-banner-print');
const certificateText = document.querySelector('#geocities-certificate-text');
let starCatches = 0;

document.querySelector('#geocities-banner-star').addEventListener('click', () => {
	starCatches++;
	const now = new Date();
	certificateText.textContent = `This certifies that a very fast visitor caught the star ${starCatches === 1 ? 'once' : `${starCatches} times`} on ${now.toLocaleDateString('en-US', {month: 'long', day: 'numeric'})}, ${buggyYear(now)}, and won a FREE iMac!`;
	bannerPrint.hidden = false;
});

bannerPrint.addEventListener('click', () => {
	print();
});

// The spectrum of the jukebox: each bar bounces at its own speed while a tune plays. The bars stand still for visitors who prefer reduced motion, as the styles only animate them when motion is allowed.
const spectrumBars = [...document.querySelector('#geocities-spectrum').children];

for (const bar of spectrumBars) {
	bar.style.animationDuration = `${250 + (Math.random() * 400)}ms`;
	bar.style.animationDelay = `${-Math.random() * 600}ms`;
}

document.addEventListener('geocities-music', event => {
	if (event.detail.source !== 'jukebox') {
		return;
	}

	for (const bar of spectrumBars) {
		if (event.detail.isPlaying) {
			bar.dataset.state = 'playing';
		} else {
			delete bar.dataset.state;
		}
	}
});

// The Lake applet: it loads when it comes into view, like a Java applet, and then draws a fjord with its reflection in rippling water, like the real applet. Each row of the water is a row of the picture, upside down, moved sideways by a sine wave that moves with the time, and more in the front, where the waves are closer. It only moves while it is in view and the tab is visible, and stands still for visitors who prefer reduced motion.
const lake = document.querySelector('#geocities-lake');
const lakeLoading = document.querySelector('#geocities-lake-loading');
const lakeBar = document.querySelector('#geocities-lake-bar');
const lakeCanvas = document.querySelector('#geocities-lake-canvas');
const lakeStatus = document.querySelector('#geocities-lake-status');
const lakeContext = lakeCanvas.getContext('2d');
const sceneHeight = 150;
const waterHeight = lakeCanvas.height - sceneHeight;
let lakeScene;
let lakeFrame;
let lastLakeTime = 0;
let isLakeVisible = false;
let isLakeLoading = false;

// The fjord at sunset: the sky, the sun, two rows of mountains, Glitter on the shore, and a title.
const drawLakeScene = async () => {
	const scene = document.createElement('canvas');
	scene.width = lakeCanvas.width;
	scene.height = sceneHeight;
	const context = scene.getContext('2d');

	const sky = context.createLinearGradient(0, 0, 0, sceneHeight);
	sky.addColorStop(0, '#1b1464');
	sky.addColorStop(0.6, '#c2185b');
	sky.addColorStop(1, '#ff9e40');
	context.fillStyle = sky;
	context.fillRect(0, 0, scene.width, sceneHeight);

	context.fillStyle = '#ffe066';
	context.beginPath();
	context.arc(230, 118, 26, 0, Math.PI * 2);
	context.fill();

	for (const [color, points] of [['#4a2c6f', [[0, 90], [60, 50], [120, 95], [180, 40], [260, 100], [320, 60]]], ['#2b1740', [[0, 120], [80, 85], [150, 130], [220, 95], [320, 135]]]]) {
		context.fillStyle = color;
		context.beginPath();
		context.moveTo(0, sceneHeight);

		for (const [x, y] of points) {
			context.lineTo(x, y);
		}

		context.lineTo(scene.width, sceneHeight);
		context.fill();
	}

	// Glitter is drawn when her picture loads, and the fjord is fine without her.
	const glitter = new Image();
	glitter.src = '/1999/still/unicorn.gif';

	try {
		await glitter.decode();
		const height = 56;
		context.drawImage(glitter, 24, sceneHeight - height, glitter.width * height / glitter.height, height);
	} catch {}

	context.font = '24px Impact, "Arial Black", sans-serif';
	context.textAlign = 'center';
	context.lineWidth = 3;
	context.strokeStyle = '#000000';
	context.strokeText('SINDRE’S FJORD', scene.width / 2, 32);
	context.fillStyle = '#ffff00';
	context.fillText('SINDRE’S FJORD', scene.width / 2, 32);
	return scene;
};

const drawLake = time => {
	lakeContext.drawImage(lakeScene, 0, 0);
	lakeContext.fillStyle = '#0a1a4a';
	lakeContext.fillRect(0, sceneHeight, lakeCanvas.width, waterHeight);

	for (let row = 0; row < waterHeight; row++) {
		const depth = row / waterHeight;
		const shift = Math.sin((row * 0.4) - (time / 250)) * (1 + (depth * 5));
		const sourceRow = Math.min(Math.max(Math.round(sceneHeight - 1 - row - (Math.sin((row * 0.25) - (time / 400)) * depth * 3)), 0), sceneHeight - 1);
		lakeContext.drawImage(lakeScene, 0, sourceRow, lakeCanvas.width, 1, shift, sceneHeight + row, lakeCanvas.width, 1);
	}

	lakeContext.fillStyle = 'rgb(0 40 120 / 0.35)';
	lakeContext.fillRect(0, sceneHeight, lakeCanvas.width, waterHeight);
};

// About 30 frames a second, like a fast applet in 1999.
const animateLake = time => {
	lakeFrame = requestAnimationFrame(animateLake);

	if (time - lastLakeTime < 33) {
		return;
	}

	lastLakeTime = time;
	drawLake(time);
};

const updateLake = () => {
	cancelAnimationFrame(lakeFrame);
	lakeFrame = undefined;

	if (!lakeScene) {
		return;
	}

	if (isLakeVisible && !document.hidden && !reducedMotion.matches) {
		lakeFrame = requestAnimationFrame(animateLake);
	} else {
		drawLake(0);
	}
};

// The status only says when the loading starts and ends, so screen readers do not read every percent.
const loadLake = async () => {
	isLakeLoading = true;
	lakeStatus.textContent = 'Loading Java applet Lake.class…';
	const scene = await drawLakeScene();

	for (let percent = 0; percent < 100; percent += 3 + Math.floor(Math.random() * 9)) {
		lakeBar.style.width = `${percent}%`;
		await wait(100);
	}

	lakeBar.style.width = '100%';
	await wait(300);
	lakeScene = scene;
	lakeLoading.hidden = true;
	lakeCanvas.hidden = false;
	lakeStatus.textContent = 'Applet Lake started.';
	updateLake();
};

// The last entry is the newest, when the browser delivers several at once.
new IntersectionObserver(entries => {
	isLakeVisible = entries.at(-1).isIntersecting;

	if (isLakeVisible && !isLakeLoading) {
		loadLake().catch(error => {
			lakeStatus.textContent = 'Applet Lake failed to start. Reload the page to try again.';
			console.error(error);
		});
	}

	updateLake();
}).observe(lake);

document.addEventListener('visibilitychange', updateLake);
reducedMotion.addEventListener('change', updateLake);

// SindreCam shows the next picture every 30 seconds, with a moment of TV static in between, unless the visitor prefers reduced motion. The time on the picture has the Y2K bug, like the rest of my computer. The countdown is not a live region, as it changes every second. It only counts while the cam is on the screen, so the static is not drawn where nobody sees it.
const camScenes = [...document.querySelectorAll('[data-cam-scene]')];
const camStatic = document.querySelector('#geocities-cam-static');
let isCamVisible = false;
const camTime = document.querySelector('#geocities-cam-time');
const camCountdown = document.querySelector('#geocities-cam-countdown');
const camWait = 30;
let camIndex = 0;
let camSecondsLeft = camWait;
let isChangingPicture = false;

const showCamTime = () => {
	const now = new Date();
	camTime.textContent = `${now.getMonth() + 1}/${now.getDate()}/${buggyYear(now)} ${now.toLocaleTimeString('en-US')}`;
};

const drawStatic = () => {
	const context = camStatic.getContext('2d');
	const image = context.createImageData(camStatic.width, camStatic.height);

	for (let index = 0; index < image.data.length; index += 4) {
		const value = Math.random() * 255;
		image.data[index] = value;
		image.data[index + 1] = value;
		image.data[index + 2] = value;
		image.data[index + 3] = 255;
	}

	context.putImageData(image, 0, 0);
};

const showCountdown = () => {
	camCountdown.textContent = `Next picture in ${camSecondsLeft} ${camSecondsLeft === 1 ? 'second' : 'seconds'}`;
};

const nextPicture = async () => {
	if (isChangingPicture) {
		return;
	}

	isChangingPicture = true;
	camSecondsLeft = camWait;
	showCountdown();

	if (!reducedMotion.matches) {
		camStatic.hidden = false;

		for (let frame = 0; frame < 14; frame++) {
			drawStatic();
			await wait(50);
		}

		camStatic.hidden = true;
	}

	camScenes[camIndex].hidden = true;
	camIndex = (camIndex + 1) % camScenes.length;
	camScenes[camIndex].hidden = false;
	showCamTime();
	isChangingPicture = false;
};

showCamTime();

new IntersectionObserver(entries => {
	isCamVisible = entries.at(-1).isIntersecting;
}).observe(camStatic.parentElement);

setInterval(() => {
	if (document.hidden || !isCamVisible) {
		return;
	}

	camSecondsLeft--;
	showCountdown();
	showCamTime();

	if (camSecondsLeft <= 0) {
		nextPicture();
	}
}, 1000);

document.querySelector('#geocities-cam-refresh').addEventListener('click', nextPicture);

// The weather in Bergen: checking again does not help.
const weatherStatus = document.querySelector('#geocities-weather-status');
const weatherUpdates = [
	'Update: still raining.',
	'Update: the rain stopped for 4 minutes. It is back.',
	'Update: Bergen has rain about 230 days a year. Today is one of them.',
	'Update: it is raining sideways now. Hold on to your umbrella!',
	'Update: a tourist asked when the rain stops. We laughed.',
];

document.querySelector('#geocities-weather-check').addEventListener('click', () => {
	weatherStatus.textContent = randomItem(weatherUpdates.filter(update => update !== weatherStatus.textContent));
});

// My ICQ status follows the clock of the visitor: asleep at night, breakfast, school on weekdays, dinner, and online the rest of the time. My mood is a surprise.
const icqStatus = document.querySelector('#geocities-icq-status');
const icqReply = document.querySelector('#geocities-icq-reply');
const now = new Date();
const hourNow = now.getHours();
const isWeekend = now.getDay() === 0 || now.getDay() === 6;

const [icqState, icqText] = (() => {
	if (hourNow >= 23 || hourNow < 7) {
		return ['asleep', 'N/A (sleeping, it is a school night)'];
	}

	if (hourNow < 8) {
		return ['away', 'Away (eating breakfast: waffles)'];
	}

	if (hourNow < 15 && !isWeekend) {
		return ['busy', 'Occupied (in school)'];
	}

	if (hourNow === 17) {
		return ['away', 'Away (dinner, and mamma says no computer at the table)'];
	}

	return ['online', 'Online. Say hi!'];
})();

document.querySelector('#geocities-icq-light').dataset.state = icqState;
icqStatus.textContent = icqText;
document.querySelector('#geocities-mood').textContent = randomItem(['Hyper (I had three waffles)', 'Sleepy (I coded until 2 AM)', 'Hungry (for waffles)', 'Rainbow-y', 'Nerdy and proud', 'Excited for the year 2000!']);

document.querySelector('#geocities-icq-message').addEventListener('click', () => {
	icqReply.textContent = icqState === 'online' ? 'Uh oh! You have a reply: “hi!!! brb, my mom needs the phone”' : `Message sent! My status is “${icqText}”, so I will answer later.`;
});

// The candles of the shrine, counted in the browser.
const candleKey = 'geocities-candles';
const candleStatus = document.querySelector('#geocities-candle-status');
let candles = Number(load(candleKey, 0)) || 0;

document.querySelector('#geocities-candle-light').addEventListener('click', () => {
	candles++;
	save(candleKey, candles);
	candleStatus.textContent = `You lit candle number ${candles.toLocaleString('en-US')}. The waffles thank you. ♥`;
});

// Rocky, the pet rock. He always reacts the same way, as he is a rock, but the messages change, so screen readers read each one.
const rockStatus = document.querySelector('#geocities-rock-status');
const rockAnswers = {
	feed: ['You offered Rocky a waffle. He did not eat it. More for you!', 'Rocky is not hungry. Rocky is never hungry.'],
	pet: ['You petted Rocky. He feels like a rock. He loves it, probably.', 'Rocky purrs. No, wait, that was your computer.'],
	walk: ['You took Rocky for a walk. Well, you carried him.', 'Rocky stayed home. He does not like rain either.'],
	trick: ['Rocky did his best trick: sitting still. Perfect, as always!', 'Rocky played dead. Very convincing.'],
};

for (const button of document.querySelectorAll('[data-rock-action]')) {
	button.addEventListener('click', () => {
		rockStatus.textContent = randomItem(rockAnswers[button.dataset.rockAction].filter(answer => answer !== rockStatus.textContent));
	});
}

// The fortune cookies of the wizard, never the same one twice in a row.
const fortuneText = document.querySelector('#geocities-fortune-text');
const fortunes = [
	'You will survive Y2K. Your VCR will not.',
	'A stranger will sign your guestbook. Sign theirs back.',
	'Your modem will connect on the first try. Just kidding.',
	'Great fortune awaits you: a free iMac (picture).',
	'You will find a GIF that you do not already have. It is rare, but it happens.',
	'In the year 2000, everybody will have a home page. Even your grandma.',
	'Lucky numbers: 56, 800, 600, 1999.',
	'Beware of pop-up ads that say you won something. Except mine.',
];

document.querySelector('#geocities-fortune-crack').addEventListener('click', () => {
	fortuneText.textContent = `*crack* ${randomItem(fortunes.filter(fortune => !fortuneText.textContent.endsWith(fortune)))}`;
});

// The Hall of Fame shows the visitor where the toys of the page have kept a record in the browser.
const bestZaps = Number(load('geocities-best-score', 0)) || 0;
const visitCount = Number(load('geocities-visits', 0)) || 0;
const glitterCare = Number(load('geocities-pet', {})?.care) || 0;

if (bestZaps > 0) {
	document.querySelector('#geocities-fame-score').textContent = `You, with ${bestZaps} ${bestZaps === 1 ? 'alien' : 'aliens'}!`;
}

if (visitCount > 0) {
	document.querySelector('#geocities-fame-visits').textContent = `You, with ${visitCount} ${visitCount === 1 ? 'visit' : 'visits'}!`;
}

if (glitterCare > 0) {
	document.querySelector('#geocities-fame-care').textContent = `You, with ${plural(glitterCare, 'care point')} for Glitter!`;
}

// Floppy, the helper of the guestbook, offers help when the visitor starts to write a comment, once per visit, unless the visitor asked it to never come back. The text is set a frame after the helper shows, so screen readers read it. When it goes away, the focus goes back to the comment.
const helperKey = 'geocities-helper-off';
const helper = document.querySelector('#geocities-helper');
const helperText = document.querySelector('#geocities-helper-text');
const comment = document.querySelector('#geocities-guestbook-form').elements.message;
let hasOfferedHelp = false;

const helperTips = [
	'Tip: Write “cool site!!!”, and ask me to sign your guestbook back. Everybody does it.',
	'Tip: Use lots of exclamation marks!!! It shows that you mean it!!!',
	'Tip: Say how you found my page. Webmasters love that.',
	'Tip: No time for spell check, the phone bill is running. Just write!',
];

comment.addEventListener('focus', () => {
	if (hasOfferedHelp || load(helperKey, false) === true) {
		return;
	}

	hasOfferedHelp = true;
	helper.hidden = false;
	requestAnimationFrame(() => {
		helperText.textContent = 'It looks like you are writing a guestbook entry! Would you like help?';
	});
});

for (const button of document.querySelectorAll('[data-helper-answer]')) {
	button.addEventListener('click', () => {
		const answer = button.dataset.helperAnswer;

		if (answer === 'yes') {
			helperText.textContent = randomItem(helperTips.filter(tip => tip !== helperText.textContent));
			return;
		}

		if (answer === 'never') {
			save(helperKey, true);
		}

		helper.hidden = true;
		comment.focus();
	});
}

// The Konami code, ↑ ↑ ↓ ↓ ← → ← → B A, which `site.js` finds, as it also sends its own unicorn across the page. It shows a message at the end of the page, and unless the visitor prefers reduced motion, a parade of unicorns runs across the bottom of the window.
const secret = document.querySelector('#geocities-secret');
const paradeTemplate = document.querySelector('#geocities-parade');
let parade;

document.addEventListener('konami', () => {
	secret.hidden = false;
	act('rainbow', 3000);
	floatHearts(10);
	say('WHOA! 30 unicorn friends!');

	// Not while the visitor types, as `site.js` also counts the keys of text fields.
	// Without scrolling, as the message is far down the page, and the parade shows the code worked.
	if (!document.activeElement?.closest('input, textarea, select, [contenteditable]')) {
		secret.focus({preventScroll: true});
	}

	if (reducedMotion.matches || parade?.isConnected) {
		return;
	}

	parade = paradeTemplate.content.firstElementChild.cloneNode(true);
	removeWhenDone(parade);
	document.body.append(parade);
});

// The effects that cover the window, like the cards of the Solitaire win and the fireworks, each draw on their own canvas of the size of the window, which does not catch the pointer.
const effectTemplate = document.querySelector('#geocities-effect');

const addEffectCanvas = () => {
	const canvas = effectTemplate.content.firstElementChild.cloneNode(true);
	canvas.width = innerWidth;
	canvas.height = innerHeight;
	document.body.append(canvas);
	return canvas;
};

// The win of Solitaire: the cards jump off the piles one by one, kings first, and bounce down the window. The canvas is never cleared, so each card leaves a trail of copies of itself, like on Windows. It stops when the cards are gone, or at a click, a key, or when the tab is hidden.
const cardSuits = [['♠', '#000000'], ['♥', '#cc0000'], ['♣', '#000000'], ['♦', '#cc0000']];
const cardRanks = ['K', 'Q', 'J', '10', '9', '8', '7', '6', '5', '4', '3', '2', 'A'];
let stopCards;

const drawCard = (rank, [suit, color], width, height) => {
	const card = document.createElement('canvas');
	card.width = width;
	card.height = height;
	const context = card.getContext('2d');
	context.fillStyle = '#ffffff';
	context.strokeStyle = '#000000';
	context.beginPath();
	context.roundRect(0.5, 0.5, width - 1, height - 1, width / 14);
	context.fill();
	context.stroke();
	context.fillStyle = color;
	context.textAlign = 'center';
	context.font = `bold ${Math.round(width / 4.5)}px Arial, sans-serif`;
	context.fillText(rank, width / 6, height / 5);
	context.fillText(suit, width / 6, height / 2.6);
	context.font = `${Math.round(width / 1.8)}px Arial, sans-serif`;
	context.fillText(suit, width / 1.75, height / 1.45);
	return card;
};

// The piles of the win are at the top right of the window, like in Solitaire, unless the cards jump off piles on the page.
const topRightPiles = () => Array.from({length: 4}, (_, index) => ({x: innerWidth - ((4 - index) * Math.min(innerWidth / 5, 90)), y: 8}));

// Returns whether the cards jump. They do not for visitors who prefer reduced motion, and the caller then says what happened instead.
const celebrate = (piles = topRightPiles()) => {
	if (reducedMotion.matches || document.hidden) {
		return false;
	}

	stopCards?.();
	const canvas = addEffectCanvas();
	const context = canvas.getContext('2d');
	// The size of the cards of Solitaire of 1990, and smaller on phones.
	const width = innerWidth < 600 ? 50 : 71;
	const height = Math.round(width * 96 / 71);
	const deck = cardRanks.flatMap(rank => cardSuits.map((suit, index) => ({image: drawCard(rank, suit, width, height), pile: piles[index % piles.length]})));
	let card;
	let frame;
	let lastTime;

	// Each card jumps to the left or the right at its own speed, a little up or down.
	const launch = () => {
		const next = deck.shift();
		return next && {image: next.image, x: next.pile.x, y: next.pile.y, speedX: (Math.random() < 0.5 ? -1 : 1) * (2 + (Math.random() * 5)), speedY: -Math.random() * 8};
	};

	// Removes all the listeners of the cards at once, also the ones that are only added after the click that won.
	const listeners = new AbortController();

	// On a large window, the 52 cards can take more than a minute, which is enough fun.
	let timeLimit;

	const stop = () => {
		cancelAnimationFrame(frame);
		clearTimeout(timeLimit);
		canvas.remove();
		listeners.abort();

		if (stopCards === stop) {
			stopCards = undefined;
		}
	};

	// The speeds are in pixels for each 60th of a second, so the cards move as fast on a screen of 120 frames a second, only with a denser trail.
	const step = time => {
		const elapsed = frameScale(time, lastTime);
		lastTime = time;
		card.speedY += 0.6 * elapsed;
		card.x += card.speedX * elapsed;
		card.y += card.speedY * elapsed;

		// It bounces on the bottom of the window, a little lower each time.
		if (card.y + height > canvas.height) {
			card.y = canvas.height - height;
			card.speedY *= -0.75;
		}

		context.drawImage(card.image, Math.round(card.x), Math.round(card.y));

		if (card.x + width < 0 || card.x > canvas.width) {
			card = launch();

			if (!card) {
				stop();
				return;
			}
		}

		frame = requestAnimationFrame(step);
	};

	card = launch();
	frame = requestAnimationFrame(step);
	// After the click that won, so that click does not stop it. The cards can be gone by then, and an aborted signal adds no listener.
	setTimeout(() => {
		// The pointer down or key that stops the cards still does what it does, so a button that the visitor clicks right after a win, like “New Game”, needs only one click. A pointer down, not a click, as a tap on a part of the page that is not a control fires no click on iPhones.
		addEventListener('pointerdown', stop, {capture: true, signal: listeners.signal});
		addEventListener('keydown', stop, {capture: true, signal: listeners.signal});
	});
	document.addEventListener('visibilitychange', stop, {signal: listeners.signal});
	// It stops when the visitor turns on reduced motion, which hides it.
	reducedMotion.addEventListener('change', stop, {signal: listeners.signal});
	timeLimit = setTimeout(stop, 20_000);
	stopCards = stop;
	return true;
};

// A screen that covers the whole window, like the blue screen, until any key or click. The key or click that opened it does not close it. The focus goes back to the button that opened it, and a toast says what happened.
const coverWindow = (template, opener, message) => {
	const cover = template.content.firstElementChild.cloneNode(true);
	let canClose = false;

	const close = event => {
		// Shortcuts, like reloading the page, still work.
		if (event.metaKey || event.ctrlKey || event.altKey) {
			return;
		}

		// The key does nothing else, also while the cover cannot close yet, like Tab, which would move the focus out of the cover, or a number key, which would zap an alien.
		event.preventDefault();
		event.stopImmediatePropagation();

		if (!canClose) {
			return;
		}

		removeEventListener('keydown', close, {capture: true});
		cover.remove();
		opener.focus();
		showToast(message);
	};

	addEventListener('keydown', close, {capture: true});
	cover.addEventListener('click', close);
	document.body.append(cover);
	(cover.querySelector('button') ?? cover.querySelector('[role]') ?? cover).focus();

	setTimeout(() => {
		canClose = true;
	}, 500);
};

// The skull crashes the computer: the blue screen of Windows first, then the bomb of the Mac, one after the other.
const blueScreenTemplate = document.querySelector('#geocities-blue-screen');
const bombTemplate = document.querySelector('#geocities-bomb');
const skull = document.querySelector('#geocities-skull');
let crashes = 0;

skull.addEventListener('click', () => {
	const isBlueScreen = crashes % 2 === 0;
	crashes++;
	coverWindow(isBlueScreen ? blueScreenTemplate : bombTemplate, skull, isBlueScreen ? 'Phew! Windows restarted. It was UNICORN.VXD again. Do NOT click the skull!' : 'Your Mac restarted. It took 4 minutes. I told you not to click the skull!');
});

// My computer: the desktop opens a window for each program, in a cascade, like Windows. The windows move by their title bars, stay inside the desktop, and come to the front when the visitor uses them. Escape closes the window, and the focus goes back to what opened it.
const desktop = document.querySelector('#geocities-desktop');
const desktopWindows = new Map([...desktop.querySelectorAll('[data-desktop-window]')].map(appWindow => [appWindow.dataset.desktopWindow, appWindow]));
const startMenu = document.querySelector('#geocities-start-menu');
const startMenuButton = document.querySelector('#geocities-start-button');
// The button that opened each window, which gets the focus when it closes.
const windowOpeners = new Map();
// What each program does when its window opens, like Paint, which loads its stamps then.
const onWindowOpen = {};
let openedCount = 0;

// The windows from back to front. Each gets its place as its z-index, so the numbers stay small and the windows never cover the Start menu or the taskbar.
const windowOrder = [];

const bringToFront = appWindow => {
	if (windowOrder.at(-1) === appWindow) {
		return;
	}

	const index = windowOrder.indexOf(appWindow);
	if (index !== -1) {
		windowOrder.splice(index, 1);
	}

	windowOrder.push(appWindow);

	for (const [index, orderedWindow] of windowOrder.entries()) {
		orderedWindow.style.zIndex = String(index + 1);
	}
};

const taskbar = startMenuButton.parentElement;

// Keeps the window inside the desktop, above the taskbar, also when the desktop gets narrower, like when a phone turns.
const moveWindow = (appWindow, left, top) => {
	const maximumLeft = Math.max(desktop.clientWidth - appWindow.offsetWidth, 0);
	const maximumTop = Math.max(desktop.clientHeight - appWindow.offsetHeight - taskbar.offsetHeight, 0);
	appWindow.style.left = `${Math.min(Math.max(left, 0), maximumLeft)}px`;
	appWindow.style.top = `${Math.min(Math.max(top, 0), maximumTop)}px`;
};

const closeStartMenu = () => {
	startMenu.hidden = true;
	startMenuButton.setAttribute('aria-expanded', 'false');
};

const openWindow = (name, opener) => {
	const appWindow = desktopWindows.get(name);
	closeStartMenu();
	windowOpeners.set(appWindow, opener);

	if (appWindow.hidden) {
		appWindow.hidden = false;
		const offset = (openedCount % 5) * 24;
		openedCount++;
		moveWindow(appWindow, 8 + offset, 8 + offset);
		onWindowOpen[name]?.();
	}

	bringToFront(appWindow);
	appWindow.focus();
};

const closeWindow = appWindow => {
	// A window can also close by itself, like Dial-Up Networking when it connects, while the visitor is in another part of the page. Then the focus stays there, so the page does not jump back to the desktop.
	const hadFocus = appWindow.contains(document.activeElement) || document.activeElement === document.body;
	appWindow.hidden = true;

	if (!hadFocus) {
		return;
	}

	const opener = windowOpeners.get(appWindow);
	// The Start menu is closed, so its items cannot get the focus, and the icon of the window gets it instead, or the Start button for a program without an icon.
	const icon = [...desktop.querySelectorAll(`[data-desktop-open="${appWindow.dataset.desktopWindow}"]`)].find(button => button.checkVisibility());
	(opener?.checkVisibility() ? opener : (icon ?? startMenuButton)).focus();
};

for (const button of desktop.querySelectorAll('[data-desktop-open]')) {
	button.addEventListener('click', () => {
		openWindow(button.dataset.desktopOpen, button);
	});
}

// `geocities-windows.js` opens its windows with this event, like a dialog that asks a question, with the element that gets the focus back when the window closes.
desktop.addEventListener('geocities-open-window', event => {
	openWindow(event.detail.name, event.detail.opener);
});

for (const appWindow of desktopWindows.values()) {
	appWindow.querySelector('[data-desktop-close]').addEventListener('click', () => {
		closeWindow(appWindow);
	});

	appWindow.addEventListener('pointerdown', () => {
		bringToFront(appWindow);
	});

	appWindow.addEventListener('focusin', () => {
		bringToFront(appWindow);
	});

	// The title bar drags the window. The pointer is captured, so the window follows it also when it moves fast, past the edge of the title bar.
	const titleBar = appWindow.querySelector('[data-desktop-title-bar]');
	let drag;

	titleBar.addEventListener('pointerdown', event => {
		if (event.button !== 0 || event.target.closest('button')) {
			return;
		}

		drag = {x: event.clientX - appWindow.offsetLeft, y: event.clientY - appWindow.offsetTop};
		titleBar.setPointerCapture(event.pointerId);
	});

	titleBar.addEventListener('pointermove', event => {
		if (drag) {
			moveWindow(appWindow, event.clientX - drag.x, event.clientY - drag.y);
		}
	});

	for (const type of ['pointerup', 'pointercancel']) {
		titleBar.addEventListener(type, () => {
			drag = undefined;
		});
	}
}

// A window that grows, like with a long message, moves up, so it stays above the taskbar.
const keepWindowsInside = new ResizeObserver(() => {
	for (const appWindow of desktopWindows.values()) {
		if (!appWindow.hidden) {
			moveWindow(appWindow, appWindow.offsetLeft, appWindow.offsetTop);
		}
	}
});

for (const element of [desktop, ...desktopWindows.values()]) {
	keepWindowsInside.observe(element);
}

// The Start menu opens above the taskbar. Escape or a click elsewhere closes it. `geocities-windows.js` opens its submenus, and moves between the items with the arrow keys.
startMenuButton.addEventListener('click', () => {
	const isOpen = startMenu.hidden;
	startMenu.hidden = !isOpen;
	startMenuButton.setAttribute('aria-expanded', String(isOpen));

	if (isOpen) {
		startMenu.querySelector('button').focus();
	}
});

document.addEventListener('pointerdown', event => {
	if (!startMenu.hidden && !startMenu.contains(event.target) && !startMenuButton.contains(event.target)) {
		closeStartMenu();
	}
});

// Only when the focus moves to something else, like with Tab. Safari does not focus a button on a click, so a click on an item would move the focus to nothing first and close the menu before the click lands. A click outside closes the menu in its own handler.
startMenu.addEventListener('focusout', event => {
	if (
		event.relatedTarget
		&& !startMenu.contains(event.relatedTarget)
		&& event.relatedTarget !== startMenuButton
	) {
		closeStartMenu();
	}
});

desktop.addEventListener('keydown', event => {
	if (event.key !== 'Escape') {
		return;
	}

	if (!startMenu.hidden) {
		closeStartMenu();
		startMenuButton.focus();
		return;
	}

	const appWindow = event.target.closest('[data-desktop-window]');
	if (appWindow) {
		closeWindow(appWindow);
	}
});

// The clock of the taskbar, which only needs the minutes.
const taskbarClock = document.querySelector('#geocities-taskbar-clock');

const showTaskbarTime = () => {
	if (!document.hidden) {
		taskbarClock.textContent = new Date().toLocaleTimeString('en-US', {hour: 'numeric', minute: '2-digit'});
	}
};

showTaskbarTime();
setInterval(showTaskbarTime, 10_000);

// Shut Down leaves the black screen of Windows 95, until any key or click turns the computer on again.
const shutDownTemplate = document.querySelector('#geocities-shut-down-screen');

// `geocities-windows.js` asks with Shut Down Windows first, and sends this event for Shut Down.
desktop.addEventListener('geocities-win-shut-down', () => {
	closeStartMenu();
	coverWindow(shutDownTemplate, startMenuButton, 'Windows 98 is starting… Welcome back! No need to scan the hard drive this time.');
});

// Unicorn Paint draws on a canvas of 320 × 200, which is shown larger in big pixels. Each stroke can be undone with “Oops!”, up to 20 times.
const paintCanvas = document.querySelector('#geocities-paint-canvas');
const paintContext = paintCanvas.getContext('2d', {willReadFrequently: true});
const paintCursor = document.querySelector('#geocities-paint-cursor');
const paintStatus = document.querySelector('#geocities-paint-status');
const paintStamps = document.querySelector('#geocities-paint-stamps');
const toolButtons = [...document.querySelectorAll('[data-paint-tool]')];
const stampButtons = [...document.querySelectorAll('[data-paint-stamp]')];
const colorButtons = [...document.querySelectorAll('[data-paint-color]')];
const undoSteps = [];
// Each tool has its size in pixels of the picture.
const toolSizes = {pencil: 2, brush: 8, rainbow: 10, eraser: 16};
const stampImages = new Map();
let paintTool = 'pencil';
let paintColor = '#000000';
let stampPath = stampButtons[0].dataset.paintStamp;
let rainbowHue = 0;
let lastPoint;

const clearPicture = () => {
	paintContext.fillStyle = '#ffffff';
	paintContext.fillRect(0, 0, paintCanvas.width, paintCanvas.height);
};

clearPicture();

// Presses the picked button in, and lets the others out.
const pick = (buttons, picked) => {
	for (const button of buttons) {
		const isPicked = button === picked;
		button.setAttribute('aria-pressed', String(isPicked));

		if (isPicked) {
			button.dataset.state = 'on';
		} else {
			delete button.dataset.state;
		}
	}
};

pick(toolButtons, toolButtons[0]);
pick(stampButtons, stampButtons[0]);
pick(colorButtons, colorButtons[0]);

for (const button of colorButtons) {
	button.style.background = button.dataset.paintColor;

	button.addEventListener('click', () => {
		paintColor = button.dataset.paintColor;
		pick(colorButtons, button);
	});
}

const toolTips = {
	pencil: 'Pencil: for the details, like the horn.',
	brush: 'Brush: for big things, like the sky.',
	spray: 'Spray can: psssht! Like graffiti, but legal.',
	fill: 'Fill: click inside a shape to fill it with the color.',
	rainbow: 'Rainbow brush: every unicorn needs one.',
	stamp: 'Stamp: pick a picture, then click to stamp it. Thunk!',
	eraser: 'Eraser: for mistakes. I never make any.',
};

for (const button of toolButtons) {
	button.addEventListener('click', () => {
		paintTool = button.dataset.paintTool;
		pick(toolButtons, button);
		paintStamps.hidden = paintTool !== 'stamp';
		paintStatus.textContent = toolTips[paintTool];
	});
}

for (const button of stampButtons) {
	button.addEventListener('click', () => {
		stampPath = button.dataset.paintStamp;
		pick(stampButtons, button);
	});
}

// The stamps are the still frames of the GIFs, loaded when Paint opens.
const loadStamp = path => {
	if (!stampImages.has(path)) {
		const image = new Image();
		image.src = path;
		stampImages.set(path, image);
	}

	return stampImages.get(path);
};

onWindowOpen.paint = () => {
	for (const button of stampButtons) {
		loadStamp(button.dataset.paintStamp);
	}
};

const saveUndoStep = () => {
	undoSteps.push(paintContext.getImageData(0, 0, paintCanvas.width, paintCanvas.height));

	if (undoSteps.length > 20) {
		undoSteps.shift();
	}
};

// The color of a tool: white for the eraser, the next color of the rainbow for the rainbow brush, and the picked color for the others.
const strokeColor = () => {
	if (paintTool === 'eraser') {
		return '#ffffff';
	}

	if (paintTool === 'rainbow') {
		rainbowHue = (rainbowHue + 9) % 360;
		return `hsl(${rainbowHue} 100% 50%)`;
	}

	return paintColor;
};

// A random spray of dots around the point, like the airbrush of Paint.
const spray = ({x, y}) => {
	paintContext.fillStyle = paintColor;

	for (let index = 0; index < 14; index++) {
		const angle = Math.random() * Math.PI * 2;
		const distance = Math.random() * 12;
		paintContext.fillRect(Math.round(x + (Math.cos(angle) * distance)), Math.round(y + (Math.sin(angle) * distance)), 1, 1);
	}
};

const drawLine = (from, to) => {
	if (paintTool === 'spray') {
		spray(to);
		return;
	}

	paintContext.strokeStyle = strokeColor();
	paintContext.lineWidth = toolSizes[paintTool];
	// The pencil has square ends, like a pixel, and the brushes are round.
	paintContext.lineCap = paintTool === 'pencil' ? 'square' : 'round';
	paintContext.lineJoin = 'round';
	paintContext.beginPath();
	paintContext.moveTo(from.x, from.y);
	paintContext.lineTo(to.x, to.y);
	paintContext.stroke();
};

// Fills the area of the color at the point with the picked color, like the paint bucket. Colors that are almost the same count as the same, so the soft edges of the lines are filled too.
const fill = ({x, y}) => {
	const {width, height} = paintCanvas;
	const image = paintContext.getImageData(0, 0, width, height);
	const pixels = image.data;
	const start = ((Math.floor(y) * width) + Math.floor(x)) * 4;
	const target = pixels.slice(start, start + 4);
	const red = Number.parseInt(paintColor.slice(1, 3), 16);
	const green = Number.parseInt(paintColor.slice(3, 5), 16);
	const blue = Number.parseInt(paintColor.slice(5, 7), 16);

	const matches = offset => Math.abs(pixels[offset] - target[0]) + Math.abs(pixels[offset + 1] - target[1]) + Math.abs(pixels[offset + 2] - target[2]) < 120;

	if (Math.abs(target[0] - red) + Math.abs(target[1] - green) + Math.abs(target[2] - blue) === 0) {
		return;
	}

	saveUndoStep();

	const visited = new Uint8Array(width * height);
	const stack = [(Math.floor(y) * width) + Math.floor(x)];

	while (stack.length > 0) {
		const index = stack.pop();

		if (visited[index] || !matches(index * 4)) {
			continue;
		}

		visited[index] = 1;
		pixels[index * 4] = red;
		pixels[(index * 4) + 1] = green;
		pixels[(index * 4) + 2] = blue;
		pixels[(index * 4) + 3] = 255;
		const column = index % width;

		if (column > 0) {
			stack.push(index - 1);
		}

		if (column < width - 1) {
			stack.push(index + 1);
		}

		if (index >= width) {
			stack.push(index - width);
		}

		if (index < width * (height - 1)) {
			stack.push(index + width);
		}
	}

	paintContext.putImageData(image, 0, 0);
};

const stamp = ({x, y}) => {
	const image = loadStamp(stampPath);

	if (!image.complete || image.naturalWidth === 0) {
		paintStatus.textContent = 'The stamp is still loading. Try again in a second!';
		return;
	}

	saveUndoStep();

	// 48 pixels high, so a big GIF is not bigger than the picture.
	const height = Math.min(48, image.naturalHeight);
	const width = image.naturalWidth * height / image.naturalHeight;
	paintContext.drawImage(image, Math.round(x - (width / 2)), Math.round(y - (height / 2)), Math.round(width), Math.round(height));
	paintStatus.textContent = randomItem(['Thunk!', 'Stamp! Stamp!', 'Thunk! Beautiful.']);
};

// Starts a stroke, or fills or stamps, at a point of the picture.
const paintAt = point => {
	if (paintTool === 'fill') {
		fill(point);
		return;
	}

	if (paintTool === 'stamp') {
		stamp(point);
		return;
	}

	saveUndoStep();
	lastPoint = point;
	drawLine(point, point);
};

// The point of the picture under the pointer, as the canvas is shown at another size than its pixels. It stays inside the picture, as a press on the very edge, or a stroke that goes past it, would otherwise fill or draw outside.
const picturePoint = event => {
	const rectangle = paintCanvas.getBoundingClientRect();
	return {
		x: Math.min(Math.max((event.clientX - rectangle.left) * paintCanvas.width / rectangle.width, 0), paintCanvas.width - 1),
		y: Math.min(Math.max((event.clientY - rectangle.top) * paintCanvas.height / rectangle.height, 0), paintCanvas.height - 1),
	};
};

// The spray can keeps spraying while it is held still, like the airbrush of Paint, so it gets darker the longer it stays.
let sprayTimer;

const startSpraying = () => {
	clearInterval(sprayTimer);
	sprayTimer = setInterval(() => {
		if (lastPoint) {
			spray(lastPoint);
		}
	}, 50);
};

const stopStroke = () => {
	clearInterval(sprayTimer);
	lastPoint = undefined;
};

paintCanvas.addEventListener('pointerdown', event => {
	if (event.button !== 0) {
		return;
	}

	paintCursor.hidden = true;
	paintCanvas.setPointerCapture(event.pointerId);
	paintAt(picturePoint(event));

	if (paintTool === 'spray') {
		startSpraying();
	}
});

paintCanvas.addEventListener('pointermove', event => {
	if (!lastPoint) {
		return;
	}

	const point = picturePoint(event);
	drawLine(lastPoint, point);
	lastPoint = point;
});

for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
	paintCanvas.addEventListener(type, stopStroke);
}

// The keyboard draws too: the arrow keys move the brush, and Space paints while it is held down, or fills or stamps.
const keyboardPoint = {x: paintCanvas.width / 2, y: paintCanvas.height / 2};
let isSpaceDown = false;

const showPaintCursor = () => {
	paintCursor.hidden = false;
	paintCursor.style.left = `${keyboardPoint.x / paintCanvas.width * 100}%`;
	paintCursor.style.top = `${keyboardPoint.y / paintCanvas.height * 100}%`;
};

paintCanvas.addEventListener('keydown', event => {
	const [moveX, moveY] = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]}[event.key] ?? [0, 0];

	if (event.key === ' ') {
		event.preventDefault();

		if (!event.repeat) {
			isSpaceDown = true;
			paintAt({...keyboardPoint});

			if (paintTool === 'spray') {
				startSpraying();
			}
		}
	} else if (moveX || moveY) {
		event.preventDefault();
		// Shift moves faster.
		const distance = event.shiftKey ? 16 : 4;
		const from = {...keyboardPoint};
		keyboardPoint.x = Math.min(Math.max(keyboardPoint.x + (moveX * distance), 0), paintCanvas.width - 1);
		keyboardPoint.y = Math.min(Math.max(keyboardPoint.y + (moveY * distance), 0), paintCanvas.height - 1);

		if (isSpaceDown && lastPoint) {
			drawLine(from, {...keyboardPoint});
			lastPoint = {...keyboardPoint};
		}
	} else {
		return;
	}

	showPaintCursor();
});

paintCanvas.addEventListener('keyup', event => {
	if (event.key === ' ') {
		isSpaceDown = false;
		stopStroke();
	}
});

paintCanvas.addEventListener('blur', () => {
	paintCursor.hidden = true;
	isSpaceDown = false;
	stopStroke();
});

document.querySelector('#geocities-paint-undo').addEventListener('click', () => {
	// The picture comes back after the explosion, not in the middle of it.
	if (isExploding) {
		return;
	}

	const step = undoSteps.pop();

	if (!step) {
		paintStatus.textContent = 'Nothing to undo. Your picture is perfect!';
		return;
	}

	paintContext.putImageData(step, 0, 0);
	paintStatus.textContent = 'OOPS! Undone.';
});

// The dynamite of Kid Pix blows up the picture: a fire ball grows from the middle, and then the picture is white. Without motion, it is white right away.
let isExploding = false;

document.querySelector('#geocities-paint-clear').addEventListener('click', async () => {
	if (isExploding) {
		return;
	}

	isExploding = true;
	saveUndoStep();

	if (!reducedMotion.matches) {
		for (let frame = 1; frame <= 8; frame++) {
			const gradient = paintContext.createRadialGradient(160, 100, 0, 160, 100, frame * 24);
			gradient.addColorStop(0, '#ffffff');
			gradient.addColorStop(0.3, '#ffff00');
			gradient.addColorStop(0.7, '#ff6600');
			gradient.addColorStop(1, 'rgb(255 0 0 / 0)');
			paintContext.fillStyle = gradient;
			paintContext.fillRect(0, 0, paintCanvas.width, paintCanvas.height);
			await wait(40);
		}
	}

	clearPicture();
	isExploding = false;
	paintStatus.textContent = 'KABOOM! Your picture is gone. (“Oops!” brings it back.)';
});

document.querySelector('#geocities-paint-save').addEventListener('click', () => {
	paintCanvas.toBlob(blob => {
		const link = document.createElement('a');
		link.href = URL.createObjectURL(blob);
		link.download = 'my-unicorn.png';
		link.click();
		setTimeout(() => {
			URL.revokeObjectURL(link.href);
		}, 1000);
		paintStatus.textContent = 'Saved as my-unicorn.png. Make it your wallpaper!';
	});
});

// Y2K Bugsweeper: the bugs are placed at the first click, away from it, so the first click always opens an area, like in Minesweeper.
const sweeperSize = 9;
const bugCount = 10;
const sweeperCells = [...document.querySelectorAll('[data-sweeper-cell]')];
const sweeperGrid = document.querySelector('#geocities-sweeper-grid');
const sweeperFace = document.querySelector('#geocities-sweeper-face');
const sweeperBugs = document.querySelector('#geocities-sweeper-bugs');
const sweeperTime = document.querySelector('#geocities-sweeper-time');
const sweeperFlag = document.querySelector('#geocities-sweeper-flag');
const sweeperStatus = document.querySelector('#geocities-sweeper-status');
const sweeperKey = 'geocities-sweeper-best';
// Each square: whether it has a bug, is open, or is flagged, and how many bugs touch it.
let squares = [];
// `ready` before the first click, then `playing`, `won`, or `lost`.
let sweeperState = 'ready';
let isFlagMode = false;
let sweeperSeconds = 0;
let sweeperTimer;

// Three digits, like 010, or a minus and two digits, like -03, when there are more flags than bugs.
const led = number => number < 0 ? `-${String(Math.min(-number, 99)).padStart(2, '0')}` : String(Math.min(number, 999)).padStart(3, '0');

const neighbors = index => {
	const row = Math.floor(index / sweeperSize);
	const column = index % sweeperSize;
	const result = [];

	for (let rowStep = -1; rowStep <= 1; rowStep++) {
		for (let columnStep = -1; columnStep <= 1; columnStep++) {
			const neighborRow = row + rowStep;
			const neighborColumn = column + columnStep;

			if ((rowStep || columnStep) && neighborRow >= 0 && neighborRow < sweeperSize && neighborColumn >= 0 && neighborColumn < sweeperSize) {
				result.push((neighborRow * sweeperSize) + neighborColumn);
			}
		}
	}

	return result;
};

// The name of a square says what is on it, for screen readers.
const labelSquare = index => {
	const square = squares[index];
	const place = `Row ${Math.floor(index / sweeperSize) + 1}, column ${(index % sweeperSize) + 1}`;
	let content = '';

	if (square.isFlagged) {
		content = ': flagged';
	} else if (square.isOpen && sweeperCells[index].textContent === '❌') {
		content = ': wrong flag';
	} else if (square.isOpen) {
		content = square.hasBug ? ': bug!' : `: ${square.count || 'empty'}`;
	}

	sweeperCells[index].setAttribute('aria-label', place + content);
};

const showBugsLeft = () => {
	const left = bugCount - squares.filter(square => square.isFlagged).length;
	sweeperBugs.textContent = led(left);
	sweeperBugs.setAttribute('aria-label', `${plural(left, 'bug')} left`);
};

const newSweeperGame = () => {
	clearInterval(sweeperTimer);
	squares = sweeperCells.map(() => ({hasBug: false, isOpen: false, isFlagged: false, count: 0}));
	sweeperState = 'ready';
	sweeperSeconds = 0;
	sweeperTime.textContent = led(0);
	sweeperFace.textContent = '🙂';

	for (const [index, cell] of sweeperCells.entries()) {
		cell.textContent = '';
		delete cell.dataset.state;
		delete cell.dataset.sweeperCount;
		labelSquare(index);
	}

	showBugsLeft();
};

const placeBugs = firstIndex => {
	const safe = new Set([firstIndex, ...neighbors(firstIndex)]);
	const places = squares.map((square, index) => index).filter(index => !safe.has(index));

	for (let placed = 0; placed < bugCount; placed++) {
		const [index] = places.splice(Math.floor(Math.random() * places.length), 1);
		squares[index].hasBug = true;
	}

	for (const [index, square] of squares.entries()) {
		square.count = neighbors(index).filter(neighbor => squares[neighbor].hasBug).length;
	}
};

const endSweeper = hasWon => {
	clearInterval(sweeperTimer);
	sweeperState = hasWon ? 'won' : 'lost';
	sweeperFace.textContent = hasWon ? '😎' : '😵';

	for (const [index, square] of squares.entries()) {
		if (square.hasBug && !square.isFlagged) {
			sweeperCells[index].textContent = hasWon ? '🚩' : '🐛';
			square.isFlagged = hasWon;
			square.isOpen = !hasWon;
		} else if (!square.hasBug && square.isFlagged) {
			// A flag without a bug under it was a mistake.
			sweeperCells[index].textContent = '❌';
			square.isFlagged = false;
			square.isOpen = true;
		}

		labelSquare(index);
	}

	showBugsLeft();
};

const openSquare = firstIndex => {
	// A flag protects its square from a click, like in Minesweeper.
	if (squares[firstIndex].isFlagged || squares[firstIndex].isOpen) {
		return;
	}

	if (sweeperState === 'ready') {
		placeBugs(firstIndex);
		sweeperState = 'playing';
		// The clock stops while the tab is hidden or the window is closed, so a record counts only the time of play.
		sweeperTimer = setInterval(() => {
			if (document.hidden || !sweeperGrid.checkVisibility()) {
				return;
			}

			sweeperSeconds++;
			sweeperTime.textContent = led(sweeperSeconds);
		}, 1000);
	}

	if (squares[firstIndex].hasBug) {
		sweeperCells[firstIndex].dataset.state = 'exploded';
		endSweeper(false);
		sweeperStatus.textContent = 'BOOM! The Y2K bug got you. Your computer thinks it is 1900 now. Click the face to try again.';
		return;
	}

	// An empty square opens the squares around it too, and so on, like a flood.
	const stack = [firstIndex];

	while (stack.length > 0) {
		const index = stack.pop();
		const square = squares[index];

		if (square.isOpen || square.isFlagged) {
			continue;
		}

		square.isOpen = true;
		const cell = sweeperCells[index];
		cell.dataset.state = 'open';

		if (square.count > 0) {
			cell.textContent = String(square.count);
			cell.dataset.sweeperCount = String(square.count);
		} else {
			stack.push(...neighbors(index));
		}

		labelSquare(index);
	}

	if (squares.every(square => square.isOpen || square.hasBug)) {
		endSweeper(true);
		// A record of 0 seconds counts too, when the first click wins. The storage can hold anything, like a negative number that could never be beaten, which does not count.
		const saved = load(sweeperKey, undefined);
		const best = Number.isInteger(saved) && saved >= 0 ? saved : undefined;
		const isBest = best === undefined || sweeperSeconds < best;

		if (isBest) {
			save(sweeperKey, sweeperSeconds);
		}

		// The cards jump off the top of the squares.
		const {left, top, width} = sweeperGrid.getBoundingClientRect();
		const cardsJump = celebrate([0, 1, 2, 3].map(index => ({x: left + (index * width / 4), y: top})));
		glitterCheers();
		sweeperStatus.textContent = `You found all the Y2K bugs in ${plural(sweeperSeconds, 'second')}!${isBest ? ' A new record!' : ` Your record is ${plural(best, 'second')}.`} The year 2000 is saved.${cardsJump ? '' : ' (The cards would jump now, but your computer prefers less motion.)'}`;
	}
};

const flagSquare = index => {
	const square = squares[index];

	if (square.isOpen || sweeperState === 'won' || sweeperState === 'lost') {
		return;
	}

	square.isFlagged = !square.isFlagged;
	sweeperCells[index].textContent = square.isFlagged ? '🚩' : '';
	labelSquare(index);
	showBugsLeft();
};

// A click on an open number that has as many flags around it as its number opens the other squares around it, like in Minesweeper, so the visitor does not have to click each one.
const openAround = index => {
	const around = neighbors(index);

	if (around.filter(neighbor => squares[neighbor].isFlagged).length !== squares[index].count) {
		return;
	}

	for (const neighbor of around) {
		if (sweeperState === 'playing') {
			openSquare(neighbor);
		}
	}
};

// A finger held on a square flags it, as phones have no right button. The click that follows the long press does not open the square.
const longPressTime = 450;
let longPressTimer;
let longPressedIndex;

for (const [index, cell] of sweeperCells.entries()) {
	cell.addEventListener('click', () => {
		if (longPressedIndex === index) {
			longPressedIndex = undefined;
			return;
		}

		// After a win, the message of the win stays.
		if (sweeperState === 'won') {
			return;
		}

		if (sweeperState === 'lost') {
			sweeperStatus.textContent = 'Game over! Click the face for a new game.';
			return;
		}

		if (squares[index].isOpen) {
			openAround(index);
		} else if (isFlagMode) {
			flagSquare(index);
		} else {
			openSquare(index);
		}
	});

	// The right button flags, like in Minesweeper. It does not open the menu of the browser. On a phone, the long press already flagged the square.
	cell.addEventListener('contextmenu', event => {
		event.preventDefault();

		if (longPressedIndex !== index) {
			flagSquare(index);
		}
	});

	// The face is surprised while the button is down, like in Minesweeper.
	cell.addEventListener('pointerdown', event => {
		if (event.button !== 0 || (sweeperState !== 'ready' && sweeperState !== 'playing')) {
			return;
		}

		sweeperFace.textContent = '😮';
		longPressedIndex = undefined;
		clearTimeout(longPressTimer);

		if (event.pointerType === 'touch' && !squares[index].isOpen) {
			longPressTimer = setTimeout(() => {
				longPressedIndex = index;
				flagSquare(index);
			}, longPressTime);
		}
	});
}

for (const type of ['pointerup', 'pointercancel', 'pointerleave']) {
	sweeperGrid.addEventListener(type, () => {
		clearTimeout(longPressTimer);

		if (sweeperState === 'ready' || sweeperState === 'playing') {
			sweeperFace.textContent = '🙂';
		}
	});
}

// The arrow keys move between the squares, so the grid is one stop of the Tab key, and F flags.
sweeperGrid.addEventListener('keydown', event => {
	const index = sweeperCells.indexOf(event.target);

	if (index === -1) {
		return;
	}

	// Shortcuts, like Find with Command+F, still work.
	if (event.metaKey || event.ctrlKey || event.altKey) {
		return;
	}

	if (event.key === 'f' || event.key === 'F') {
		event.preventDefault();
		flagSquare(index);
		return;
	}

	const step = {ArrowLeft: index % sweeperSize === 0 ? 0 : -1, ArrowRight: index % sweeperSize === sweeperSize - 1 ? 0 : 1, ArrowUp: -sweeperSize, ArrowDown: sweeperSize}[event.key];

	if (step === undefined) {
		return;
	}

	event.preventDefault();
	const next = sweeperCells[index + step];

	if (next) {
		event.target.tabIndex = -1;
		next.tabIndex = 0;
		next.focus();
	}
});

sweeperFace.addEventListener('click', () => {
	newSweeperGame();
	sweeperStatus.textContent = 'New game! 10 bugs are hiding. Good luck.';
});

sweeperFlag.addEventListener('click', () => {
	isFlagMode = !isFlagMode;
	sweeperFlag.setAttribute('aria-pressed', String(isFlagMode));
	sweeperStatus.textContent = isFlagMode ? 'Flag Mode is on: a click or tap flags a square.' : 'Flag Mode is off: a click or tap opens a square.';
});

newSweeperGame();

// My secret diary only opens with the password, which is my favorite food, in English or Norwegian.
const diaryLock = document.querySelector('#geocities-diary-lock');
const diaryPassword = document.querySelector('#geocities-diary-password');
const diaryStatus = document.querySelector('#geocities-diary-status');
const diaryText = document.querySelector('#geocities-diary-text');
const wrongPasswords = [
	'WRONG PASSWORD! This incident will be reported to my mom.',
	'Access denied. Are you my little sister?',
	'Wrong! Hint: it has squares, and it goes well with brown cheese.',
	'Nope. Not “password” either. I am not stupid.',
];

diaryLock.addEventListener('submit', event => {
	event.preventDefault();

	if (!/waffle|vaffel|vafler|vaflar/i.test(diaryPassword.value)) {
		diaryStatus.textContent = randomItem(wrongPasswords.filter(message => message !== diaryStatus.textContent));
		diaryPassword.select();
		return;
	}

	diaryLock.hidden = true;
	diaryText.hidden = false;
	diaryStatus.textContent = 'Access granted. Welcome back, Sindre! Wait… you are not Sindre!';
	diaryText.focus();
});

document.querySelector('#geocities-diary-hint').addEventListener('click', () => {
	diaryStatus.textContent = 'Hint: my favorite food. In Norway, it is shaped like a heart.';
});

// Solitaire is already won, so the cards jump off the four piles of the window.
const solitaireStatus = document.querySelector('#geocities-solitaire-status');

document.querySelector('#geocities-solitaire-win').addEventListener('click', () => {
	const piles = [...document.querySelectorAll('[data-solitaire-pile]')].map(pile => {
		const {left, top} = pile.getBoundingClientRect();
		return {x: left, y: top};
	});

	solitaireStatus.textContent = celebrate(piles) ? 'You win! Click or press a key to stop the cards.' : 'You win! The cards would jump now, but your computer prefers less motion.';
});

// The defragmenter moves the parts of the files to the start of the hard drive, block by block: it reads a block at the end (green), and writes it at the first free place (red). Without motion, it is done right away.
const defragBlocks = [...document.querySelectorAll('[data-defrag-block]')];
const defragStart = document.querySelector('#geocities-defrag-start');
const defragStatus = document.querySelector('#geocities-defrag-status');

const setBlock = (block, state) => {
	if (state) {
		block.dataset.state = state;
	} else {
		delete block.dataset.state;
	}
};

// A block is part of a file when it has a state, and free space when it has none.
const isData = block => block.dataset.state === 'fragment' || block.dataset.state === 'done';

// A drive that is about half full, with gaps all over.
const fragment = () => {
	for (const block of defragBlocks) {
		setBlock(block, Math.random() < 0.5 ? 'fragment' : undefined);
	}
};

fragment();

// The button stays enabled while it runs, so it keeps the focus, and a click in the meantime does nothing.
let isDefragmenting = false;

defragStart.addEventListener('click', async () => {
	if (isDefragmenting) {
		return;
	}

	// A second run starts from a messy drive again, as I saved more GIFs in the meantime.
	if (defragBlocks.every(block => block.dataset.state !== 'fragment')) {
		fragment();
	}

	isDefragmenting = true;
	defragStatus.textContent = 'Defragmenting drive C:… Do not touch the computer!';
	// The blocks and the status are at the bottom of the window, which scrolls when it is taller than the desktop, like on a phone. Only the window scrolls, not the page.
	const propertiesWindow = defragStart.closest('[data-desktop-window]');
	propertiesWindow.scrollTop = propertiesWindow.scrollHeight;
	const pause = milliseconds => reducedMotion.matches ? undefined : wait(milliseconds);
	let last = defragBlocks.length - 1;

	for (const [index, block] of defragBlocks.entries()) {
		if (!isData(block)) {
			while (last > index && !isData(defragBlocks[last])) {
				last--;
			}

			if (last <= index) {
				break;
			}

			setBlock(defragBlocks[last], 'read');
			await pause(70);
			setBlock(block, 'write');
			await pause(70);
			setBlock(defragBlocks[last], undefined);
		}

		setBlock(block, 'done');
		await pause(20);
	}

	defragStatus.textContent = 'Defragmentation is complete! My GIFs load 0.1 seconds faster now.';
	defragStart.textContent = 'Defragment Again';
	isDefragmenting = false;
});

// The Recycle Bin asks first, like Windows.
const recycleList = document.querySelector('#geocities-recycle-list');
const recycleEmpty = document.querySelector('#geocities-recycle-empty');
const recycleStatus = document.querySelector('#geocities-recycle-status');

// The button is disabled while the bin is empty, so the focus goes to the window.
const disableRecycleEmpty = () => {
	recycleEmpty.disabled = true;
	recycleEmpty.closest('[data-desktop-window]').focus();
};

recycleEmpty.addEventListener('click', () => {
	const count = recycleList.children.length;

	// The icons that `geocities-windows.js` puts in the bin can all be restored again.
	if (count === 0) {
		recycleStatus.textContent = 'The Recycle Bin is already empty. Nothing to crunch.';
		disableRecycleEmpty();
		return;
	}

	if (!confirm(count === 1 ? 'Are you sure you want to delete this item?' : `Are you sure you want to delete these ${count} items?`)) {
		recycleStatus.textContent = `Phew. ${recycleList.querySelector('strong').textContent} lives another day.`;
		return;
	}

	recycleList.replaceChildren();
	recycleStatus.textContent = 'Crunch! The Recycle Bin is empty. My 4 GB hard drive has room for 3 more GIFs.';
	disableRecycleEmpty();
});

// Snake on the phone of my dad: a screen of 84 × 48 pixels, in squares of 4 pixels, where the snake goes out on one side and comes back on the other. It eats waffles and gets longer and faster. It pauses when the tab is hidden or the phone scrolls away. With reduced motion, it moves one step for each key, so nothing moves by itself.
const snakePhone = document.querySelector('#geocities-snake-phone');
const snakeScreen = document.querySelector('#geocities-snake-screen');
const snakeContext = snakeScreen.getContext('2d');
const snakeScore = document.querySelector('#geocities-snake-score');
const snakeStatus = document.querySelector('#geocities-snake-status');
const snakeKey = 'geocities-snake-best';
const snakeColumns = 21;
const snakeRows = 12;
const lcdLight = '#9fbf5a';
const lcdDark = '#1f2a10';
const directions = {2: {x: 0, y: -1}, 4: {x: -1, y: 0}, 6: {x: 1, y: 0}, 8: {x: 0, y: 1}};
let snakeBody = [];
let snakeDirection = directions[6];
// The turns of the keys that come faster than the steps, so a quick “up, left” makes both turns.
let snakeTurns = [];
let waffle;
let snakePoints = 0;
let snakeBest = Number(load(snakeKey, 0)) || 0;
// `ready`, `playing`, `paused`, or `over`.
let snakeState = 'ready';
let snakeTimer;

const showSnakeScore = () => {
	snakeScore.textContent = `Score: ${snakePoints} ★ Best: ${snakeBest}`;
};

// Each part of the snake is 3 of the 4 pixels of its square, with a gap, like on the phones of 1999. A waffle is a little diamond. When the game is over, the screen turns dark with a light snake, so the end shows on the screen without blinking.
const drawSnake = () => {
	const isOver = snakeState === 'over';
	snakeContext.fillStyle = isOver ? lcdDark : lcdLight;
	snakeContext.fillRect(0, 0, snakeScreen.width, snakeScreen.height);
	snakeContext.fillStyle = isOver ? lcdLight : lcdDark;

	for (const part of snakeBody) {
		snakeContext.fillRect(part.x * 4, part.y * 4, 3, 3);
	}

	if (waffle) {
		for (const [x, y] of [[1, 0], [0, 1], [2, 1], [1, 2]]) {
			snakeContext.fillRect((waffle.x * 4) + x, (waffle.y * 4) + y, 1, 1);
		}
	}
};

const placeWaffle = () => {
	const free = [];

	for (let y = 0; y < snakeRows; y++) {
		for (let x = 0; x < snakeColumns; x++) {
			if (!snakeBody.some(part => part.x === x && part.y === y)) {
				free.push({x, y});
			}
		}
	}

	waffle = randomItem(free);
};

const endSnake = () => {
	clearTimeout(snakeTimer);
	snakeState = 'over';
	drawSnake();
	const isBest = snakePoints > snakeBest;

	if (isBest) {
		snakeBest = snakePoints;
		save(snakeKey, snakeBest);
	}

	showSnakeScore();
	// The cards only jump for a record of 10 waffles or more, as the first game is always a record, and the cards cover the page.
	const isBigRecord = isBest && snakePoints >= 10;
	const cardsJump = isBigRecord && celebrate();
	snakeStatus.textContent = `GAME OVER! You ate ${plural(snakePoints, 'waffle')}.${isBest ? ' NEW RECORD!' : ''}${isBigRecord && !cardsJump ? ' (The cards would jump now, but your computer prefers less motion.)' : ''} Press 5 to play again.`;
};

const moveSnake = () => {
	snakeDirection = snakeTurns.shift() ?? snakeDirection;
	const head = snakeBody[0];
	const next = {x: (head.x + snakeDirection.x + snakeColumns) % snakeColumns, y: (head.y + snakeDirection.y + snakeRows) % snakeRows};
	const eats = next.x === waffle.x && next.y === waffle.y;

	// The tail moves away in the same step, so the head can follow it closely, unless the snake grows.
	if (snakeBody.slice(0, eats ? undefined : -1).some(part => part.x === next.x && part.y === next.y)) {
		endSnake();
		return;
	}

	snakeBody.unshift(next);

	if (eats) {
		snakePoints++;
		showSnakeScore();
		placeWaffle();
	} else {
		snakeBody.pop();
	}

	drawSnake();
};

// It gets faster with each waffle, from 5 to 12 steps a second.
const tick = () => {
	if (snakeState !== 'playing') {
		return;
	}

	moveSnake();

	if (snakeState === 'playing') {
		snakeTimer = setTimeout(tick, Math.max(80, 200 - (snakePoints * 8)));
	}
};

const runSnake = () => {
	clearTimeout(snakeTimer);
	snakeState = 'playing';

	if (!reducedMotion.matches) {
		snakeTimer = setTimeout(tick, 200);
	}
};

const startSnake = () => {
	snakeBody = [{x: 6, y: 6}, {x: 5, y: 6}, {x: 4, y: 6}, {x: 3, y: 6}];
	snakeDirection = directions[6];
	snakeTurns = [];
	snakePoints = 0;
	placeWaffle();
	showSnakeScore();
	runSnake();
	drawSnake();
	snakeStatus.textContent = reducedMotion.matches ? 'Go! The snake moves one step for each key, as your computer prefers less motion.' : 'Go! Eat the waffles!';
};

const pauseSnake = message => {
	if (snakeState !== 'playing') {
		return;
	}

	clearTimeout(snakeTimer);
	snakeState = 'paused';
	snakeStatus.textContent = message;
};

const turnSnake = key => {
	const direction = directions[key];
	const last = snakeTurns.at(-1) ?? snakeDirection;

	// It cannot turn back into itself, and two of the same turn in a row count once.
	if (direction.x === -last.x && direction.y === -last.y) {
		return;
	}

	if ((direction.x !== last.x || direction.y !== last.y) && snakeTurns.length < 3) {
		snakeTurns.push(direction);
	}

	if (reducedMotion.matches) {
		moveSnake();
	}
};

const keyMessages = {
	0: 'Calling mamma… Just kidding. It costs 5 kroner a minute.',
	1: 'Beep! You have 0 new messages.',
	'*': 'Keypad locked. Just kidding.',
	'#': 'Beep! That key does nothing. Use 2, 4, 6, and 8.',
};

const pressPhoneKey = key => {
	if (key === '5') {
		if (snakeState === 'playing') {
			pauseSnake('Paused. Press 5 to go on.');
		} else if (snakeState === 'paused') {
			runSnake();
			snakeStatus.textContent = 'Go on!';
		} else {
			startSnake();
		}

		return;
	}

	if (directions[key]) {
		if (snakeState === 'playing') {
			turnSnake(key);
		} else {
			snakeStatus.textContent = snakeState === 'paused' ? 'Paused. Press 5 to go on.' : 'Press 5 to play!';
		}

		return;
	}

	snakeStatus.textContent = keyMessages[key] ?? 'Beep! That key does nothing. Use 2, 4, 6, and 8.';
};

for (const button of snakePhone.querySelectorAll('[data-snake-key]')) {
	button.addEventListener('click', () => {
		// Safari does not focus a button on a click, and the arrow keys only steer while the focus is on the phone.
		button.focus({preventScroll: true});
		pressPhoneKey(button.dataset.snakeKey);
	});
}

// The arrow keys and the number keys of the keyboard work too, while the focus is on the phone. They do not reach the other toys of the page, like Zap the Aliens, which also uses the number keys.
snakePhone.addEventListener('keydown', event => {
	const key = {ArrowUp: '2', ArrowLeft: '4', ArrowRight: '6', ArrowDown: '8'}[event.key] ?? (/^[0-9*#]$/.test(event.key) ? event.key : undefined);

	if (!key || event.altKey || event.ctrlKey || event.metaKey || event.repeat) {
		return;
	}

	event.preventDefault();
	event.stopPropagation();
	pressPhoneKey(key);
});

// A swipe on the screen steers, and a tap starts or pauses.
let swipeStart;

snakeScreen.addEventListener('pointerdown', event => {
	if (event.button !== 0) {
		return;
	}

	swipeStart = {x: event.clientX, y: event.clientY};
	snakeScreen.setPointerCapture(event.pointerId);
});

snakeScreen.addEventListener('pointerup', event => {
	if (!swipeStart) {
		return;
	}

	const deltaX = event.clientX - swipeStart.x;
	const deltaY = event.clientY - swipeStart.y;
	swipeStart = undefined;

	// The screen cannot have the focus, so the 5 key gets it, and the keys of the keyboard keep steering. After the press, as the browser moves the focus away from a pressed screen.
	snakePhone.querySelector('[data-snake-key="5"]').focus({preventScroll: true});

	if (Math.max(Math.abs(deltaX), Math.abs(deltaY)) < 16) {
		pressPhoneKey('5');
	} else if (snakeState === 'playing') {
		turnSnake(Math.abs(deltaX) > Math.abs(deltaY) ? (deltaX > 0 ? '6' : '4') : (deltaY > 0 ? '8' : '2'));
	}
});

document.addEventListener('visibilitychange', () => {
	if (document.hidden) {
		pauseSnake('Paused, as you left the page. Press 5 to go on.');
	}
});

new IntersectionObserver(entries => {
	if (!entries.at(-1).isIntersecting) {
		pauseSnake('Paused, as the phone scrolled away. Press 5 to go on.');
	}
}).observe(snakeScreen);

// With reduced motion turned on in the middle of a game, the snake waits for the keys.
reducedMotion.addEventListener('change', () => {
	if (snakeState === 'playing') {
		runSnake();
	}
});

showSnakeScore();
drawSnake();

// The midnight party: a countdown from 10, and at midnight, fireworks over the whole window, and the Y2K bug, which shakes the page in strange colors for a moment and turns the date to 1900. With reduced motion, there are no fireworks and no shaking.
const partyStart = document.querySelector('#geocities-party-start');
const partyCount = document.querySelector('#geocities-party-count');
const partyStatus = document.querySelector('#geocities-party-status');
const panel = document.querySelector('#geocities-panel');
const y2kToday = document.querySelector('#geocities-y2k-today');

// Rockets go up from the bottom and burst into sparks of one color, which fall and fade. The window gets dark like the night sky while they fly, so they shine over the light page. The sparks are drawn on a canvas of their own, which fades a little each frame and leaves short trails.
const fireworks = () => {
	const canvas = addEffectCanvas();
	const context = canvas.getContext('2d');
	const trails = document.createElement('canvas');
	trails.width = canvas.width;
	trails.height = canvas.height;
	const trailContext = trails.getContext('2d');
	const rockets = [];
	const sparks = [];
	const gravity = 0.12;
	const duration = 7000;
	let startTime;
	let nextRocket = 0;
	let lastTime;
	let frame;

	const stop = () => {
		cancelAnimationFrame(frame);
		canvas.remove();
		document.removeEventListener('visibilitychange', stop);
		reducedMotion.removeEventListener('change', stop);
	};

	const burst = rocket => {
		const hue = Math.random() * 360;

		for (let index = 0; index < 90; index++) {
			const angle = Math.random() * Math.PI * 2;
			const speed = 1 + (Math.random() * 5);
			sparks.push({x: rocket.x, y: rocket.y, speedX: Math.cos(angle) * speed, speedY: Math.sin(angle) * speed, life: 1, hue: hue + (Math.random() * 40)});
		}
	};

	const step = time => {
		startTime ??= time;
		const elapsed = frameScale(time, lastTime);
		const age = time - startTime;
		lastTime = time;
		const isLaunching = age < duration - 2000;

		// A rocket every half second or so, high enough to burst in the upper part of the window.
		if (isLaunching && time >= nextRocket) {
			nextRocket = time + 200 + (Math.random() * 400);
			const height = canvas.height * (0.45 + (Math.random() * 0.4));
			rockets.push({x: canvas.width * (0.1 + (Math.random() * 0.8)), y: canvas.height, speedY: -Math.sqrt(2 * gravity * height)});
		}

		trailContext.globalCompositeOperation = 'destination-out';
		trailContext.fillStyle = 'rgb(0 0 0 / 0.18)';
		trailContext.fillRect(0, 0, trails.width, trails.height);
		trailContext.globalCompositeOperation = 'lighter';

		for (const [index, rocket] of [...rockets.entries()].reverse()) {
			rocket.speedY += gravity * elapsed;
			rocket.y += rocket.speedY * elapsed;
			trailContext.fillStyle = '#ffffcc';
			trailContext.fillRect(rocket.x - 1.5, rocket.y, 3, 8);

			// It bursts at the top of its flight.
			if (rocket.speedY >= 0) {
				rockets.splice(index, 1);
				burst(rocket);
			}
		}

		for (const [index, spark] of [...sparks.entries()].reverse()) {
			spark.speedX *= 0.97 ** elapsed;
			spark.speedY = (spark.speedY * (0.97 ** elapsed)) + (gravity * 0.4 * elapsed);
			spark.x += spark.speedX * elapsed;
			spark.y += spark.speedY * elapsed;
			spark.life -= 0.011 * elapsed;

			if (spark.life <= 0) {
				sparks.splice(index, 1);
				continue;
			}

			trailContext.fillStyle = `hsl(${spark.hue} 100% 60% / ${spark.life})`;
			trailContext.fillRect(spark.x - 2, spark.y - 2, 4, 4);
		}

		// The night falls in half a second, and the day comes back at the end.
		const night = Math.min(age / 500, 1, Math.max((duration - age) / 800, 0));
		context.clearRect(0, 0, canvas.width, canvas.height);
		context.fillStyle = `rgb(0 0 30 / ${night * 0.6})`;
		context.fillRect(0, 0, canvas.width, canvas.height);
		context.drawImage(trails, 0, 0);

		if (age > duration) {
			stop();
			return;
		}

		frame = requestAnimationFrame(step);
	};

	frame = requestAnimationFrame(step);
	document.addEventListener('visibilitychange', stop);
	// It stops when the visitor turns on reduced motion, which hides it.
	reducedMotion.addEventListener('change', stop);
};

// The Y2K bug strikes: the page shakes in strange colors, and the date of the countdown is in 1900.
const y2kBug = async () => {
	const today = y2kToday.textContent;
	panel.dataset.state = 'y2k';
	y2kToday.textContent = 'January 1, 1900';
	showToast('Y2K BUG DETECTED! Your computer thinks it is January 1, 1900. Just kidding. Everything is fine. Probably.');
	await wait(2500);
	delete panel.dataset.state;
	y2kToday.textContent = today;
};

let isPartying = false;

partyStart.addEventListener('click', async () => {
	if (isPartying) {
		return;
	}

	isPartying = true;
	// The big number counts, and the status is said once, so screen readers do not read every second.
	partyStatus.textContent = 'Counting down from 10 to the year 2000!';
	partyCount.hidden = false;

	try {
		for (let second = 10; second > 0; second--) {
			partyCount.textContent = String(second);
			await wait(1000);
		}

		partyCount.textContent = '2000!!!';
		glitterCheers();

		if (reducedMotion.matches) {
			partyStatus.textContent = 'HAPPY NEW YEAR 2000!!! The fireworks stay in the box, as your computer prefers less motion. The Y2K bug stayed home too.';
		} else {
			partyStatus.textContent = 'HAPPY NEW YEAR 2000!!! Godt nytt år! Look at the fireworks!';
			fireworks();
			await wait(1500);
			await y2kBug();
		}

		await wait(3000);
	} finally {
		partyCount.hidden = true;
		partyStart.textContent = 'Again! Count Down to 2000 Again';
		isPartying = false;
	}
});

// The screen savers that are drawn on a canvas, each as a function that draws the next frame at the time. They draw at the size of the canvas, so they work on the small monitor of the Display Properties and on the whole window.
const saverDrawers = {
	// 3D Pipes: pipes grow through a grid, one square at a time, and turn now and then. They are shaded across, so they look round, with a ball at each turn. When a pipe has nowhere to go, a new one starts in another color, and after a few pipes, the screen starts over.
	pipes(canvas) {
		const context = canvas.getContext('2d');
		const size = Math.max(Math.round(Math.min(canvas.width, canvas.height) / 12), 8);
		const columns = Math.floor(canvas.width / size);
		const rows = Math.floor(canvas.height / size);
		const turns = [[1, 0], [-1, 0], [0, 1], [0, -1]];
		const radius = size * 0.24;
		const used = new Set();
		let pipe;
		let pipeCount = 0;
		let lastTime = 0;

		const center = (x, y) => [(x * size) + (size / 2), (y * size) + (size / 2)];

		const shade = (gradient, hue) => {
			gradient.addColorStop(0, `hsl(${hue} 80% 18%)`);
			gradient.addColorStop(0.35, `hsl(${hue} 90% 72%)`);
			gradient.addColorStop(1, `hsl(${hue} 80% 12%)`);
			return gradient;
		};

		const drawJoint = (x, y, hue) => {
			const [centerX, centerY] = center(x, y);
			const ball = context.createRadialGradient(centerX - (radius / 2), centerY - (radius / 2), 1, centerX, centerY, radius * 1.4);
			ball.addColorStop(0, `hsl(${hue} 90% 85%)`);
			ball.addColorStop(1, `hsl(${hue} 80% 20%)`);
			context.fillStyle = ball;
			context.beginPath();
			context.arc(centerX, centerY, radius * 1.4, 0, Math.PI * 2);
			context.fill();
		};

		const drawSegment = (fromX, fromY, toX, toY, hue) => {
			const [x1, y1] = center(fromX, fromY);
			const [x2, y2] = center(toX, toY);

			if (y1 === y2) {
				context.fillStyle = shade(context.createLinearGradient(0, y1 - radius, 0, y1 + radius), hue);
				context.fillRect(Math.min(x1, x2), y1 - radius, Math.abs(x2 - x1), radius * 2);
			} else {
				context.fillStyle = shade(context.createLinearGradient(x1 - radius, 0, x1 + radius, 0), hue);
				context.fillRect(x1 - radius, Math.min(y1, y2), radius * 2, Math.abs(y2 - y1));
			}
		};

		const newPipe = () => {
			if (pipeCount % 8 === 0) {
				context.fillStyle = '#000000';
				context.fillRect(0, 0, canvas.width, canvas.height);
				used.clear();
			}

			pipeCount++;
			const x = Math.floor(Math.random() * columns);
			const y = Math.floor(Math.random() * rows);
			pipe = {x, y, turn: randomItem(turns), hue: Math.random() * 360};
			used.add(`${x},${y}`);
			drawJoint(x, y, pipe.hue);
		};

		newPipe();

		return time => {
			if (time - lastTime < 50) {
				return;
			}

			lastTime = time;
			// Straight on most of the time, else a turn, to a square that is free.
			const options = (Math.random() < 0.75 ? [pipe.turn] : []).concat(turns.toSorted(() => Math.random() - 0.5));
			const turn = options.find(([stepX, stepY]) => {
				const x = pipe.x + stepX;
				const y = pipe.y + stepY;
				return x >= 0 && x < columns && y >= 0 && y < rows && !used.has(`${x},${y}`);
			});

			if (!turn) {
				newPipe();
				return;
			}

			const x = pipe.x + turn[0];
			const y = pipe.y + turn[1];
			drawSegment(pipe.x, pipe.y, x, y, pipe.hue);

			if (turn !== pipe.turn) {
				drawJoint(pipe.x, pipe.y, pipe.hue);
			}

			used.add(`${x},${y}`);
			pipe = {...pipe, x, y, turn};
		};
	},

	// Starfield Simulation: stars fly toward the viewer from the middle of the screen, and get bigger and brighter as they come closer.
	starfield(canvas) {
		const context = canvas.getContext('2d');
		const newStar = () => ({x: (Math.random() * 2) - 1, y: (Math.random() * 2) - 1, depth: 0.2 + (Math.random() * 0.8)});
		const stars = Array.from({length: 160}, newStar);
		let lastTime;

		return time => {
			const elapsed = frameScale(time, lastTime);
			lastTime = time;
			context.fillStyle = '#000000';
			context.fillRect(0, 0, canvas.width, canvas.height);

			for (const [index, star] of stars.entries()) {
				star.depth -= 0.006 * elapsed;
				const x = (canvas.width / 2) + (star.x / star.depth * canvas.width / 2);
				const y = (canvas.height / 2) + (star.y / star.depth * canvas.height / 2);

				if (star.depth <= 0.02 || x < 0 || x > canvas.width || y < 0 || y > canvas.height) {
					stars[index] = {...newStar(), depth: 1};
					continue;
				}

				const nearness = 1 - star.depth;
				const size = Math.max(nearness * 3 * canvas.width / 640, 1);
				context.fillStyle = `rgb(255 255 255 / ${0.3 + (nearness * 0.7)})`;
				context.fillRect(x, y, size, size);
			}
		};
	},

	// Mystify Your Mind: two shapes of four corners bounce around the screen, and each leaves a few copies of itself behind, in colors that change slowly.
	mystify(canvas) {
		const context = canvas.getContext('2d');
		const speed = canvas.width / 200;
		const shapes = [0, 1].map(() => ({
			corners: Array.from({length: 4}, () => ({x: Math.random() * canvas.width, y: Math.random() * canvas.height, speedX: (Math.random() - 0.5) * speed * 2, speedY: (Math.random() - 0.5) * speed * 2})),
			trail: [],
		}));
		let hue = 0;
		let lastTime;

		return time => {
			const elapsed = frameScale(time, lastTime);
			lastTime = time;
			hue = (hue + (0.5 * elapsed)) % 360;
			context.fillStyle = '#000000';
			context.fillRect(0, 0, canvas.width, canvas.height);
			context.lineWidth = Math.max(canvas.width / 400, 1);

			for (const [shapeIndex, shape] of shapes.entries()) {
				for (const corner of shape.corners) {
					corner.x += corner.speedX * elapsed;
					corner.y += corner.speedY * elapsed;

					if (corner.x < 0 || corner.x > canvas.width) {
						corner.speedX *= -1;
					}

					if (corner.y < 0 || corner.y > canvas.height) {
						corner.speedY *= -1;
					}
				}

				shape.trail.unshift(shape.corners.map(({x, y}) => ({x, y})));
				shape.trail.length = Math.min(shape.trail.length, 6);

				for (const [age, corners] of shape.trail.entries()) {
					context.strokeStyle = `hsl(${hue + (shapeIndex * 150)} 100% 60% / ${1 - (age / 6)})`;
					context.beginPath();

					for (const {x, y} of corners) {
						context.lineTo(x, y);
					}

					context.closePath();
					context.stroke();
				}
			}
		};
	},

	// Flying Unicorns, for the small monitor, as the whole window uses the animated GIFs.
	unicorns(canvas) {
		const context = canvas.getContext('2d');
		const unicorn = loadStamp('/1999/still/unicorn-gallop.gif');

		// The still frame of the monitor is drawn again when the picture arrives.
		if (!unicorn.complete) {
			unicorn.addEventListener('load', updateMonitor, {once: true});
		}
		const flyers = Array.from({length: 4}, (_, index) => ({x: Math.random() * canvas.width, y: (index + 0.2) * canvas.height / 4.5, speed: 0.6 + Math.random()}));
		let lastTime;

		return time => {
			const elapsed = frameScale(time, lastTime);
			lastTime = time;
			context.fillStyle = '#000000';
			context.fillRect(0, 0, canvas.width, canvas.height);

			if (!unicorn.complete || unicorn.naturalWidth === 0) {
				return;
			}

			const width = canvas.width / 4;
			const height = width * unicorn.naturalHeight / unicorn.naturalWidth;

			for (const flyer of flyers) {
				flyer.x += flyer.speed * elapsed;

				if (flyer.x > canvas.width) {
					flyer.x = -width;
				}

				context.drawImage(unicorn, flyer.x, flyer.y, width, height);
			}
		};
	},
};

// The small monitor of the Display Properties shows the picked screen saver while it is in view and the tab is visible. With reduced motion, it shows a still frame.
const saverMonitor = document.querySelector('#geocities-saver-monitor');
const monitorContext = saverMonitor.getContext('2d');
let drawMonitor;
let monitorFrame;
let isMonitorVisible = false;

const animateMonitor = time => {
	drawMonitor(time);
	monitorFrame = requestAnimationFrame(animateMonitor);
};

const updateMonitor = () => {
	cancelAnimationFrame(monitorFrame);
	monitorFrame = undefined;

	if (!drawMonitor) {
		return;
	}

	if (isMonitorVisible && !document.hidden && !reducedMotion.matches) {
		monitorFrame = requestAnimationFrame(animateMonitor);
		return;
	}

	// A still frame: the drawer runs a few seconds in no time.
	for (let time = 0; time < 3000; time += 50) {
		drawMonitor(time);
	}
};

const showMonitor = () => {
	const drawer = saverDrawers[saverKind.value];
	drawMonitor = drawer?.(saverMonitor);

	if (!drawer) {
		monitorContext.fillStyle = '#000000';
		monitorContext.fillRect(0, 0, saverMonitor.width, saverMonitor.height);
	}

	updateMonitor();
};

new IntersectionObserver(entries => {
	isMonitorVisible = entries.at(-1).isIntersecting;
	updateMonitor();
}).observe(saverMonitor);

document.addEventListener('visibilitychange', updateMonitor);
reducedMotion.addEventListener('change', updateMonitor);

saverKind.addEventListener('change', () => {
	showMonitor();
	saveDisplay();
});

showMonitor();

// The other mouse trails of the Display Properties, like the DHTML scripts of Dynamic Drive: elastic balls, and a clock that follows the pointer. Each moves with frames only until it comes to rest.
const trailDotTemplate = document.querySelector('#geocities-trail-dot');

const addTrailDot = (look, content = '') => {
	const dot = trailDotTemplate.content.firstElementChild.cloneNode(true);
	dot.textContent = content;
	Object.assign(dot.style, look);
	document.body.append(dot);
	return dot;
};

// The elastic trail: 7 balls of the rainbow on rubber bands, the first tied to the pointer. The bands only pull when they are stretched, and gravity pulls the balls down, so they swing and hang below the pointer when it stops.
const elasticColors = ['#ff0000', '#ff9900', '#ffee00', '#33cc33', '#3399ff', '#6633ff', '#cc33ff'];
let elasticBalls;
let elasticTarget;
let elasticFrame;
let lastElasticTime;

const moveElasticBalls = time => {
	// The first frame counts as one 60th of a second, so the balls start moving right away.
	const elapsed = frameScale(time, lastElasticTime ?? (time - (1000 / 60)), 2);
	lastElasticTime = time;
	let movement = 0;

	for (const [index, ball] of elasticBalls.entries()) {
		const leader = index === 0 ? elasticTarget : elasticBalls[index - 1];
		const deltaX = leader.x - ball.x;
		const deltaY = leader.y - ball.y;
		const distance = Math.hypot(deltaX, deltaY) || 1;
		const pull = Math.max(distance - 12, 0) * 0.1 * elapsed;
		ball.speedX = (ball.speedX + (pull * deltaX / distance)) * (0.88 ** elapsed);
		ball.speedY = (ball.speedY + (pull * deltaY / distance) + (0.5 * elapsed)) * (0.88 ** elapsed);
		ball.x += ball.speedX * elapsed;
		ball.y += ball.speedY * elapsed;
		movement += Math.abs(ball.speedX) + Math.abs(ball.speedY);
		ball.element.style.translate = `${ball.x - 8}px ${ball.y - 8}px`;
	}

	if (movement > 0.3) {
		elasticFrame = requestAnimationFrame(moveElasticBalls);
	} else {
		elasticFrame = undefined;
		lastElasticTime = undefined;
	}
};

const followWithBalls = (x, y) => {
	elasticTarget = {x, y};
	elasticBalls ??= elasticColors.map(color => ({
		element: addTrailDot({width: '16px', height: '16px', borderRadius: '50%', background: `radial-gradient(circle at 35% 35%, #ffffff, ${color} 45%)`}),
		x,
		y,
		speedX: 0,
		speedY: 0,
	}));

	elasticFrame ??= requestAnimationFrame(moveElasticBalls);
};

// The clock that follows the pointer: the 12 numbers in a ring, and the hands as lines of dots, with the time of the visitor. Each part follows the pointer at its own speed, the outer ones slower, so the clock swirls when the pointer moves. The hands move every second while the clock rests.
const clockRadius = 44;
let clockParts;
let clockTarget;
let clockFrame;
let clockHandsTimer;

// Where each part of the clock is, from the middle, as an angle in turns from 12 o’clock and a distance.
const clockPlaces = () => {
	const now = new Date();
	const seconds = now.getSeconds() / 60;
	const minutes = (now.getMinutes() + seconds) / 60;
	const hours = ((now.getHours() % 12) + minutes) / 12;

	return clockParts.map(part => {
		if (part.hand) {
			return {turn: {hours, minutes, seconds}[part.hand], distance: part.distance};
		}

		return {turn: part.number / 12, distance: clockRadius};
	});
};

const placeClock = () => {
	for (const [index, place] of clockPlaces().entries()) {
		const part = clockParts[index];
		const angle = (place.turn - 0.25) * Math.PI * 2;
		part.element.style.translate = `${part.x + (Math.cos(angle) * place.distance) - 4}px ${part.y + (Math.sin(angle) * place.distance) - 6}px`;
	}
};

const moveClock = () => {
	let movement = 0;

	for (const part of clockParts) {
		const deltaX = clockTarget.x - part.x;
		const deltaY = clockTarget.y - part.y;
		part.x += deltaX * part.speed;
		part.y += deltaY * part.speed;
		movement += Math.abs(deltaX) + Math.abs(deltaY);
	}

	placeClock();
	clockFrame = movement > clockParts.length * 0.5 ? requestAnimationFrame(moveClock) : undefined;
};

const followWithClock = (x, y) => {
	// Below and to the right of the pointer, so the clock does not cover what the visitor points at.
	clockTarget = {x: x + clockRadius + 20, y: y + clockRadius + 20};

	if (!clockParts) {
		const numbers = Array.from({length: 12}, (_, index) => ({number: index + 1, look: {color: '#ff66ff'}}));
		// The hands, from the shortest to the longest: 3 dots for the hours, 4 for the minutes, and 5 for the seconds.
		const hands = [['hours', 3, '#ffffff'], ['minutes', 4, '#66ccff'], ['seconds', 5, '#ff3333']].flatMap(([hand, count, color]) => Array.from({length: count}, (_, index) => ({hand, distance: (index + 1) * clockRadius / 6.5, look: {color}})));

		clockParts = [...numbers, ...hands].map((part, index) => ({
			...part,
			element: addTrailDot({...part.look, textShadow: '1px 1px #000000'}, part.number ? String(part.number) : '•'),
			...clockTarget,
			// The hands follow fastest, and each number a little slower than the one before it.
			speed: part.hand ? 0.3 : 0.25 - (index * 0.012),
		}));

		clockHandsTimer = setInterval(() => {
			if (!document.hidden && !clockFrame) {
				placeClock();
			}
		}, 1000);
	}

	clockFrame ??= requestAnimationFrame(moveClock);
};

// Removes the elastic balls and the clock, and hides the letters, like when the visitor picks another trail, turns on reduced motion, or the pointer leaves the window.
const removeTrails = () => {
	cancelAnimationFrame(elasticFrame);
	cancelAnimationFrame(clockFrame);
	clearInterval(clockHandsTimer);
	elasticFrame = undefined;
	clockFrame = undefined;

	for (const part of [...(elasticBalls ?? []), ...(clockParts ?? [])]) {
		part.element.remove();
	}

	elasticBalls = undefined;
	clockParts = undefined;
	hideLetters(true);
};

// The other scripts of the page, like the scripts of the toys (`Arcade.js`), use the shared toys through events on the document, so they need no imports: `geocities-toast` shows its `detail.message` in the toast, `geocities-celebrate` runs the win of Solitaire, and `geocities-cheer` makes Glitter cheer.
document.addEventListener('geocities-toast', event => {
	showToast(event.detail.message);
});

document.addEventListener('geocities-celebrate', () => {
	celebrate();
});

document.addEventListener('geocities-cheer', () => {
	glitterCheers();
});

// The big red buttons do something silly to the whole page for a few seconds.

// Turns on an effect of the panel for a few seconds, like the spinning GIFs.
const effectState = (state, milliseconds) => {
	panel.dataset.effect = state;
	setTimeout(() => {
		if (panel.dataset.effect === state) {
			delete panel.dataset.effect;
		}
	}, milliseconds);
};

// Things that rain down the window for a few seconds, using the snowflakes as the falling parts.
const rainDown = (text, amount) => {
	const drops = Array.from({length: amount}, () => {
		const drop = snowTemplate.content.firstElementChild.cloneNode(true);
		drop.textContent = text;
		drop.style.left = `${Math.random() * 100}%`;
		drop.style.fontSize = `${1.5 + Math.random()}rem`;
		drop.style.animationDuration = `${2 + (Math.random() * 3)}s`;
		drop.style.animationDelay = `${-Math.random() * 3}s`;
		return drop;
	});

	document.body.append(...drops);
	setTimeout(() => {
		for (const drop of drops) {
			drop.remove();
		}
	}, 7000);
};

let isHamsterDance = false;

const bigButtons = {
	glitter() {
		act('rainbow', 3000);
		floatHearts(12);
		say('Look at me sparkle!!!');
		showToast('Glitter is now 100% more sparkly. She is in her egg further down the page.');
	},
	waffles() {
		if (reducedMotion.matches) {
			showToast('It would rain waffles now, but your computer prefers less motion. Here is one: 🧇');
			return;
		}

		rainDown('🧇', 40);
		showToast('It is raining waffles! Bring brown cheese.');
	},
	spin() {
		if (reducedMotion.matches) {
			showToast('The GIFs would spin now, but your computer prefers less motion.');
			return;
		}

		effectState('spin', 6000);
		showToast('Wheee! Every GIF on the page spins.');
	},
	hamster() {
		// A second press while they dance would save the hamsters as the images to bring back.
		if (isHamsterDance) {
			showToast('The hamsters are already dancing!');
			return;
		}

		isHamsterDance = true;

		// Every GIF of the panel becomes the dancing hamster for a few seconds, in its own size, like on the Hampster Dance.
		const images = [...panel.querySelectorAll('img[src^="/1999/"]')];
		const sources = images.map(image => image.getAttribute('src'));

		for (const image of images) {
			image.src = '/1999/hamster.gif';
		}

		setTimeout(() => {
			for (const [index, image] of images.entries()) {
				image.src = sources[index];
			}

			isHamsterDance = false;
		}, 8000);

		showToast('Welcome to the Hampster Dance! Dee doo dee doo.');
	},
	norway() {
		// The wallpaper turns the red of the flag of Norway for a while, without saving it.
		root.style.backgroundColor = '#ba0c2f';
		setTimeout(showWallpaper, 10_000);
		act('jump', 1500);
		say('Hipp hipp hurra!');
		showToast('Hipp hipp hurra for Norway! 🇳🇴');
	},
	rainbow() {
		if (reducedMotion.matches) {
			showToast('The page would turn every color now, but your computer prefers less motion.');
			return;
		}

		effectState('rainbow', 5000);
		showToast('Taste the rainbow!');
	},
};


for (const button of document.querySelectorAll('[data-big-button]')) {
	button.addEventListener('click', () => {
		bigButtons[button.dataset.bigButton]();
	});
}
