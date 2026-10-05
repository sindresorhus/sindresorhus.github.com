// HyperTerminal on the desktop of the 1999 page: the Connection Description, a list of the BBSes of Bergen to dial, and Fjordnet BBS, with ANSI art, a log on, messages, files, who is online, a chat with the SysOp, and Legend of the Red Troll, a door game like Legend of the Red Dragon. The modem makes its sounds only after the visitor turns them on.

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const formatNumber = number => number.toLocaleString('en-US');

const setUpTerminal = (terminal, {call: callButton, hangUp: hangUpButton, sound: soundButton, setup, name: nameField, number: numberPicker, monitor, screen, form, input, keys: keyBar, statusBar, textTemplate, artTemplate, keyTemplate}) => {
	const appWindow = terminal.desktopWindow;

	// The screen. Text comes in at the speed of the modem, about 1,600 characters a second, unless the visitor prefers less motion. The colors are the pipe codes of BBSes like Renegade: `|14` is yellow, and `|07` is gray again.
	const queue = [];
	let pumpTimer;
	let lastSpan;

	const isInstant = () => terminal.reducedMotion || appWindow.hidden || document.hidden;

	// Spaces that line up text, like at the start of a line or in the columns of a menu, do not collapse or wrap, and single spaces between words still wrap on a narrow screen.
	const keepSpaces = line => line.replaceAll(/^ +| {2,}/g, spaces => '\u00A0'.repeat(spaces.length));

	const appendText = (text, color) => {
		if (lastSpan?.isConnected && lastSpan.dataset.termColor === String(color)) {
			lastSpan.append(text);
		} else {
			lastSpan = textTemplate.content.firstElementChild.cloneNode(true);
			lastSpan.dataset.termColor = String(color);
			lastSpan.textContent = text;
			screen.append(lastSpan);
		}

		// Keeps the last screens, like the scrollback of HyperTerminal.
		while (screen.childElementCount > 800) {
			screen.firstElementChild.remove();
		}
	};

	const scrollToEnd = () => {
		monitor.scrollTop = monitor.scrollHeight;
	};

	const finishPrinting = () => {
		pumpTimer?.cancel();
		pumpTimer = undefined;
		screen.removeAttribute('aria-busy');
		scrollToEnd();
	};

	const pump = () => {
		let budget = 40;

		while (queue.length > 0 && budget > 0) {
			const piece = queue[0];
			const part = piece.text.slice(0, budget);
			appendText(part, piece.color);
			budget -= part.length;
			piece.text = piece.text.slice(part.length);

			if (piece.text === '') {
				queue.shift();
			}
		}

		scrollToEnd();

		if (queue.length > 0) {
			pumpTimer = terminal.timeout(25, pump);
		} else {
			finishPrinting();
		}
	};

	// Writes all the text that still waits, like when the visitor presses a key while a screen comes in.
	const flush = () => {
		for (const piece of queue) {
			appendText(piece.text, piece.color);
		}

		queue.length = 0;
		finishPrinting();
	};

	const enqueue = (text, color) => {
		queue.push({text, color});

		if (isInstant()) {
			flush();
		} else if (!pumpTimer) {
			// A screen reader reads the new text when it has all come in, not each piece.
			screen.setAttribute('aria-busy', 'true');
			pumpTimer = terminal.timeout(25, pump);
		}
	};

	let currentColor = 7;

	const print = (text = '') => {
		const lines = text.split('\n').map(line => keepSpaces(line));

		for (const [index, line] of lines.entries()) {
			for (const [partIndex, part] of line.split(/\|(\d\d)/).entries()) {
				if (partIndex % 2 === 1) {
					currentColor = Number(part);
				} else if (part !== '') {
					enqueue(part, currentColor);
				}
			}

			if (index < lines.length - 1) {
				enqueue('\n', currentColor);
			}
		}
	};

	const println = (text = '') => {
		print(`${text}\n`);
	};

	const clearScreen = () => {
		queue.length = 0;
		finishPrinting();
		screen.replaceChildren();
		lastSpan = undefined;
		currentColor = 7;
	};

	// A text that changes in place, like the progress of a download.
	const printLive = text => {
		flush();
		const span = textTemplate.content.firstElementChild.cloneNode(true);
		span.dataset.termColor = '11';
		span.textContent = text;
		screen.append(span);
		lastSpan = undefined;
		enqueue('\n', 7);
		return span;
	};

	// ANSI art, in the pixels of the half blocks of the BBSes of the time, two pixels for each character, drawn on a canvas so the blocks join without gaps in any font. Each letter of the art is a color.
	const artColors = {'.': '#000000', b: '#0000aa', g: '#00aa00', c: '#00aaaa', r: '#aa0000', m: '#aa00aa', o: '#aa5500', l: '#aaaaaa', k: '#555555', B: '#5555ff', G: '#55ff55', C: '#55ffff', R: '#ff5555', P: '#ff55ff', Y: '#ffff55', W: '#ffffff'};

	const printArt = (rows, indent = 2) => {
		flush();
		const art = artTemplate.content.firstElementChild.cloneNode(true);
		const columns = rows[0].length;
		art.width = columns;
		art.height = rows.length;
		// A character of Courier is about 0.6 of the font size wide, and a pixel is half a character high.
		art.style.width = `${columns * 0.6}em`;
		art.style.marginLeft = `${indent * 0.6}em`;
		const drawing = art.getContext('2d');

		for (const [row, line] of rows.entries()) {
			for (const [column, letter] of [...line].entries()) {
				drawing.fillStyle = artColors[letter] ?? '#000000';
				drawing.fillRect(column, row, 1, 1);
			}
		}

		screen.append(art);
		lastSpan = undefined;
		scrollToEnd();
	};

	const unicornArt = [
		'Y...........................',
		'.Y..........................',
		'.YY.........................',
		'..YY.....PP.................',
		'...YY...PWWP................',
		'....YWWWWWWWRR..............',
		'...WWWWWWWWWRRYY............',
		'..WWWWWWWWWWWYYGG...........',
		'.WWWkkWWWWWWWWGGBB..........',
		'.WWWkkWWWWWWWWWBBPP.........',
		'WWWWWWWWWWWWWWWWPPRR........',
		'WWWWWWWWWWWWWWWWWRRYY.......',
		'lWWWWWWWWWWWWWWWWWYYGG......',
		'llWWWWW.WWWWWWWWWWWGGBB.....',
		'.llWWW...WWWWWWWWWWWBBPP....',
		'..ll......WWWWWWWWWWWPPRR...',
		'...........WWWWWWWWWWWRRYY..',
		'............WWWWWWWWWWWYY...',
		'.............WWWWWWWWWW.....',
		'..............WWWWWWWWW.....',
	];

	const trollArt = [
		'....o...o....o...o....',
		'....oo.ooo..ooo.oo....',
		'.....oooooooooooo.....',
		'....rrrrrrrrrrrrrr....',
		'...rrrrrrrrrrrrrrrr...',
		'..rrrYYkrrrrrrkYYrrr..',
		'..rrrYYkrrrrrrkYYrrr..',
		'.rrrrrrrrrRRrrrrrrrrr.',
		'rrrrrrrrrRRRRrrrrrrrrr',
		'.rrrrrrrrRRRRrrrrrrrr.',
		'..rrrrrrrrRRrrrrrrrr..',
		'..rrkkkkkkkkkkkkkkrr..',
		'..rrkWkWkkkkkkWkWkrr..',
		'...rrrrrrrrrrrrrrrr...',
		'....rrrrrrrrrrrrrr....',
		'......rrrrrrrrrr......',
	];

	// The keys. A menu waits for one key, like the hotkeys of a BBS, “Press any key” waits for any key, and a question waits for a line and Enter. The buttons under the screen are the same keys, for a finger.
	let mode = {kind: 'off'};

	const showKeys = buttons => {
		const hadFocus = keyBar.contains(document.activeElement);
		keyBar.replaceChildren(...buttons);

		if (hadFocus) {
			(keyBar.querySelector('button') ?? (input.disabled ? screen : input)).focus();
		}
	};

	const keyButton = (label, onClick) => {
		const button = keyTemplate.content.firstElementChild.cloneNode(true);
		button.textContent = label;
		button.addEventListener('click', onClick);
		return button;
	};

	const setInputEnabled = isEnabled => {
		input.disabled = !isEnabled;
	};

	const menu = (keys, prompt = '|11Your choice: |15') => {
		print(prompt);
		mode = {kind: 'keys', keys};
		input.value = '';
		input.placeholder = 'Press a key';
		setInputEnabled(true);
		showKeys(keys.map(item => keyButton(`[${item.key}] ${item.label}`, () => {
			pressKey(item.key);
		})));
	};

	const anyKey = (action, prompt = '|08Press any key…') => {
		print(prompt);
		mode = {kind: 'any', action};
		input.value = '';
		input.placeholder = 'Press any key';
		setInputEnabled(true);
		showKeys([keyButton('Press any key', () => {
			pressKey(' ');
		})]);
	};

	const askLine = (prompt, action, value = '') => {
		print(prompt);
		mode = {kind: 'line', action};
		input.value = value;
		input.placeholder = 'Type, then press Enter';
		setInputEnabled(true);
		showKeys([]);

		if (appWindow.contains(document.activeElement)) {
			input.focus();
		}
	};

	const stopInput = () => {
		mode = {kind: 'off'};
		input.value = '';
		input.placeholder = '';
		setInputEnabled(false);
		showKeys([]);
	};

	function pressKey(key) {
		flush();

		if (mode.kind === 'any') {
			const {action} = mode;
			mode = {kind: 'off'};
			println();
			action();
			return;
		}

		if (mode.kind !== 'keys') {
			return;
		}

		const item = mode.keys.find(entry => entry.key === key.toUpperCase());

		if (item) {
			mode = {kind: 'off'};
			println(item.key);
			item.action();
		}
	}

	terminal.on(terminal, 'keydown', event => {
		if ((event.target !== screen && event.target !== input) || event.ctrlKey || event.metaKey || event.altKey || mode.kind === 'off' || mode.kind === 'line') {
			return;
		}

		if (event.key.length === 1 || event.key === 'Enter') {
			event.preventDefault();
			pressKey(event.key === 'Enter' ? ' ' : event.key);
		}
	});

	terminal.on(form, 'submit', event => {
		event.preventDefault();

		if (mode.kind === 'line') {
			const {action} = mode;
			const text = input.value.trim();
			mode = {kind: 'off'};
			input.value = '';
			println(text);
			action(text);
		} else if (mode.kind === 'any') {
			pressKey(' ');
		}
	});

	// The sounds of the modem, made with tones, only after the visitor turns them on.
	let audioContext;
	let audioOutput;
	let isSoundOn = false;
	// The sounds of a call go through a volume of their own, which goes to zero when the line drops, as the tones of the dial and the handshake are scheduled ahead.
	let lineGain;

	const lineOutput = () => {
		if (!lineGain) {
			lineGain = audioContext.createGain();
			lineGain.connect(audioOutput);
		}

		return lineGain;
	};

	const silenceLine = () => {
		if (lineGain) {
			lineGain.gain.setValueAtTime(0, audioContext.currentTime);
			lineGain = undefined;
		}
	};

	terminal.on(soundButton, 'click', () => {
		// The desktop starts its audio in the handler of this click, as browsers only allow sound after one.
		const sound = terminal.sound();
		audioContext = sound.context;
		audioOutput = sound.output;

		isSoundOn = !isSoundOn;
		soundButton.setAttribute('aria-pressed', String(isSoundOn));

		if (!isSoundOn) {
			silenceLine();
		}

		if (isSoundOn) {
			tone(1200, 0, 0.08, {type: 'square', volume: 0.05});
		}
	});

	const tone = (frequency, start, duration, {type = 'sine', volume = 0.08} = {}) => {
		if (!isSoundOn || !audioContext) {
			return;
		}

		const time = audioContext.currentTime + start;
		const oscillator = audioContext.createOscillator();
		const gain = audioContext.createGain();
		oscillator.type = type;
		oscillator.frequency.setValueAtTime(frequency, time);
		gain.gain.setValueAtTime(0.0001, time);
		gain.gain.exponentialRampToValueAtTime(volume, time + 0.01);
		gain.gain.setValueAtTime(volume, time + Math.max(duration - 0.02, 0.01));
		gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
		oscillator.connect(gain).connect(lineOutput());
		oscillator.start(time);
		oscillator.stop(time + duration + 0.05);
	};

	// The hiss of the handshake, white noise through a filter.
	const noise = (start, duration, frequency, volume = 0.06) => {
		if (!isSoundOn || !audioContext) {
			return;
		}

		const buffer = audioContext.createBuffer(1, Math.ceil(audioContext.sampleRate * duration), audioContext.sampleRate);
		const samples = buffer.getChannelData(0);

		for (let index = 0; index < samples.length; index++) {
			samples[index] = (Math.random() * 2) - 1;
		}

		const time = audioContext.currentTime + start;
		const source = audioContext.createBufferSource();
		const filter = audioContext.createBiquadFilter();
		const gain = audioContext.createGain();
		source.buffer = buffer;
		filter.type = 'bandpass';
		filter.frequency.value = frequency;
		gain.gain.value = volume;
		source.connect(filter).connect(gain).connect(lineOutput());
		source.start(time);
	};

	// The tones of the keys of a phone.
	const touchTones = {0: [941, 1336], 1: [697, 1209], 2: [697, 1336], 3: [697, 1477], 4: [770, 1209], 5: [770, 1336], 6: [770, 1477], 7: [852, 1209], 8: [852, 1336], 9: [852, 1477]};

	const modemSounds = {
		dial(number) {
			tone(350, 0, 0.6, {volume: 0.04});
			tone(440, 0, 0.6, {volume: 0.04});

			for (const [index, digit] of [...number.replaceAll(' ', '')].entries()) {
				for (const frequency of touchTones[digit]) {
					tone(frequency, 0.7 + (index * 0.11), 0.08, {volume: 0.05});
				}
			}
		},
		ring(start = 1.8) {
			for (const offset of [0, 2]) {
				tone(440, start + offset, 1, {volume: 0.03});
				tone(480, start + offset, 1, {volume: 0.03});
			}
		},
		handshake(start = 1.8) {
			tone(2100, start, 0.9, {volume: 0.05});
			tone(1650, start + 1, 0.25, {type: 'square', volume: 0.03});
			tone(980, start + 1.25, 0.25, {type: 'square', volume: 0.03});
			noise(start + 1.5, 0.5, 1800);
			tone(1200, start + 2, 0.2, {type: 'sawtooth', volume: 0.03});
			tone(2400, start + 2, 0.2, {type: 'sawtooth', volume: 0.02});
			noise(start + 2.2, 0.8, 1000, 0.08);
		},
		busy(start = 1.8) {
			for (const offset of [0, 1, 2]) {
				tone(480, start + offset, 0.5, {volume: 0.04});
				tone(620, start + offset, 0.5, {volume: 0.04});
			}
		},
		fax(start = 1.8) {
			tone(2100, start, 1, {volume: 0.05});

			for (const offset of [1.2, 1.7, 2.2]) {
				tone(1100, start + offset, 0.3, {volume: 0.05});
			}

			noise(start + 2.6, 0.6, 1500, 0.08);
		},
		beep() {
			for (const offset of [0, 0.3, 0.6]) {
				tone(880, offset, 0.15, {type: 'square', volume: 0.04});
			}
		},
	};

	// The connection. Each call has a number, so Hang Up stops a call that still dials or waits.
	const bbses = {
		fjordnet: {number: '55 31 19 99', name: 'Fjordnet BBS'},
		bryggen: {number: '55 23 10 00', name: 'Bryggen Bulletin Board'},
		ulriken: {number: '55 99 66 66', name: 'Ulriken Underground'},
		office: {number: '55 20 40 80', name: 'Pappa’s office'},
		mormor: {number: '55 18 12 34', name: 'Mormor'},
	};

	let callRun = 0;
	let connectedAt;
	let clockTimer;
	let state = 'idle';
	let liveTimer;

	const sleep = async (run, milliseconds) => {
		await terminal.wait(milliseconds);
		return run === callRun;
	};

	const showStatus = () => {
		if (state !== 'online') {
			statusBar.textContent = state === 'dialing' ? 'Dialing… | Auto detect | 14400 8-N-1' : 'Disconnected | Auto detect | 14400 8-N-1';
			return;
		}

		const seconds = Math.floor((Date.now() - connectedAt) / 1000);
		const time = `${Math.floor(seconds / 3600)}:${String(Math.floor(seconds / 60) % 60).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;
		statusBar.textContent = `Connected ${time} | ANSI | 14400 8-N-1 | SCROLL CAPS NUM Capture Print echo`;
	};

	const setState = newState => {
		state = newState;
		clockTimer?.cancel();

		if (state === 'online') {
			connectedAt = Date.now();
			clockTimer = terminal.interval(1000, () => {
				if (!document.hidden && !appWindow.hidden) {
					showStatus();
				}
			});
		}

		const isIdle = state === 'idle';
		callButton.disabled = !isIdle;
		hangUpButton.disabled = isIdle;

		showStatus();
	};

	const disconnect = () => {
		callRun++;
		silenceLine();
		liveTimer?.cancel();
		flush();
		stopInput();
		setState('idle');
	};

	const hangUp = (lines = '|07+++\nATH0\nOK') => {
		if (state === 'idle') {
			return;
		}

		flush();
		println();
		println(lines);
		println('|15NO CARRIER');
		disconnect();
	};

	terminal.on(hangUpButton, 'click', () => {
		hangUp();
		setup.hidden = false;
	});

	terminal.on(callButton, 'click', () => {
		setup.hidden = false;
		nameField.focus();
		nameField.select();
	});

	terminal.on(setup, 'submit', event => {
		event.preventDefault();
		dial(numberPicker.value);
	});

	async function dial(id) {
		const bbs = bbses[id];
		const run = ++callRun;
		setup.hidden = true;
		setState('dialing');
		clearScreen();
		println(`|08HyperTerminal: ${nameField.value.trim() || 'New Connection'}`);
		println('|07ATZ');
		println('OK');
		println(`ATDT ${bbs.number.replaceAll(' ', '')}`);
		modemSounds.dial(bbs.number);

		if (!await sleep(run, 1800)) {
			return;
		}

		if (id === 'bryggen') {
			modemSounds.busy(0);

			if (!await sleep(run, 2500)) {
				return;
			}

			println('|15BUSY');
			println('|08(Everybody in Bergen calls Bryggen after school. Try again at 3 in the night.)');
			disconnect();
			setup.hidden = false;
			return;
		}

		modemSounds.ring(0);
		println('|08RINGING');

		// Fjordnet answers on the first ring, as the SysOp has nothing else to do.
		if (!await sleep(run, id === 'fjordnet' ? 1500 : 2000)) {
			return;
		}

		if (id !== 'fjordnet') {
			println('|08RINGING');

			if (!await sleep(run, 2000)) {
				return;
			}
		}

		if (id === 'ulriken') {
			println('|15NO ANSWER');
			println('|08(The SysOp of Ulriken Underground turns his BBS off at 9 PM. His mother says so.)');
			disconnect();
			setup.hidden = false;
			return;
		}

		if (id === 'office') {
			modemSounds.fax(0);
			println('|08(Something beeps and screeches. It does not sound like a BBS.)');

			if (!await sleep(run, 3200)) {
				return;
			}

			println('|15NO CARRIER');
			println('|08That was the fax machine at Pappa’s office. It faxed you a page that says: “ORDER 40 KG OF BRUNOST BEFORE Y2K”.');
			disconnect();
			setup.hidden = false;
			return;
		}

		if (id === 'mormor') {
			const lines = [
				'|14Mormor: Hallo? Hallo?',
				'|14Mormor: Is that you, Sindre? Why does the phone whistle?',
				'|14Mormor: Are you on the Internet again? Your mother says you are always on the Internet.',
				'|14Mormor: I made waffles. Come over on your bicycle. Bring a sweater. *click*',
			];

			for (const line of lines) {
				println(line);

				if (!await sleep(run, 1600)) {
					return;
				}
			}

			println('|15NO CARRIER');
			disconnect();
			setup.hidden = false;
			return;
		}

		modemSounds.handshake(0);
		println('|08(The modems scream at each other: EEEEEEEE-krrrr-bong-bong-KSSSSHHHHH)');

		if (!await sleep(run, 3400)) {
			return;
		}

		println('|15CONNECT 14400/ARQ/V42BIS');
		setState('online');

		if (!await sleep(run, 600)) {
			return;
		}

		welcome();
	}

	// Fjordnet BBS. The handle of the visitor stays in the browser for the next call.
	const profile = terminal.stored('profile', {handle: '', calls: 0});

	const header = title => {
		const width = 34;
		const padded = ` ${title}`.padEnd(width - 2);
		println(`|09╔${'═'.repeat(width - 2)}╗`);
		println(`|09║|15${padded}|09║`);
		println(`|09╚${'═'.repeat(width - 2)}╝`);
	};

	function welcome() {
		clearScreen();
		printArt(unicornArt);
		println();
		println('|09╔════════════════════════════════╗');
		println('|09║|15   F J O R D N E T    B B S     |09║');
		println('|09║|11  Bergen, Norway ★ since 1994   |09║');
		println('|09╚════════════════════════════════╝');
		println('|07Running Renegade on a 386 with a Turbo button.');
		println('|07SysOp: |14Trond|07 (the dad of Kristoffer in 6B)');
		println('|08One node. One phone line. Please be quick.');
		println();

		if (profile.handle) {
			println(`|11Welcome back! Press Enter to log on as |15${profile.handle}|11, or type another handle.`);
		}

		askLine('|11Enter your handle: |15', logOn, profile.handle);
	}

	function logOn(handle) {
		const name = handle.replaceAll(/[|\n]/g, '').slice(0, 20);

		if (!name) {
			askLine('|12A handle, please. Like your name, or a cool name: |15', logOn);
			return;
		}

		if (name === profile.handle) {
			profile.calls++;
			terminal.store('profile', profile);
			println(`|10Welcome back, |15${name}|10! This is call number ${profile.calls}.`);
			println('|07You have |150|07 new messages. Nobody writes to you. Except the SysOp.');
			anyKey(mainMenu);
			return;
		}

		println(`|12${name.toUpperCase()}|07 is a new user. Welcome!`);
		askLine('|11Where are you calling from? |15', place => {
			profile.handle = name;
			profile.calls = 1;
			terminal.store('profile', profile);
			println(`|10Welcome to Fjordnet, |15${name}|10 from |15${place.replaceAll(/[|\n]/g, '').slice(0, 30) || 'nowhere'}|10!`);
			println('|07You are caller number |141,999|07 today. (We started counting at 1,999. It looks better.)');
			anyKey(mainMenu);
		});
	}

	const timeLeft = () => Math.max(60 - Math.floor((Date.now() - connectedAt) / 60_000), 0);

	function mainMenu() {
		clearScreen();
		header('FJORDNET MAIN MENU');
		println(' |14[M]|07essages      |14[F]|07iles');
		println(' |14[D]|07oor games    |14[W]|07ho is online');
		println(' |14[C]|07hat with SysOp');
		println(' |14[G]|07oodbye');
		println();
		println(`|08Time left today: ${timeLeft()} min`);
		menu([
			{key: 'M', label: 'Messages', action: () => {
				showMessage(0);
			}},
			{key: 'F', label: 'Files', action: fileArea},
			{key: 'D', label: 'Doors', action: doors},
			{key: 'W', label: 'Who', action: whoIsOnline},
			{key: 'C', label: 'Chat', action: chat},
			{key: 'G', label: 'Goodbye', action: goodbye},
		]);
	}

	// The message base, with the posts of the kids of Bergen, and the replies of the visitor.
	const posts = [
		{from: 'GlitterGirl', to: 'All', subject: 'HAS ANYONE SEEN A UNICORN?', body: 'My big brother says he saw a unicorn on Fløyen. He also says he has a girlfriend in Canada. I do not believe him.'},
		{from: 'Brunost_Boy', to: 'GlitterGirl', subject: 'RE: HAS ANYONE SEEN A UNICORN?', body: 'Yes. It was a horse with an ice cream cone on its head. Sorry.'},
		{from: 'DoomLord99', to: 'All', subject: 'Y2K = END OF THE WORLD?!', body: 'My dad filled the bathtub with water for Y2K. Now I cannot take a bath until the year 2000. Best Y2K ever.'},
		{from: 'Snakemaster', to: 'All', subject: 'NEW SNAKE RECORD!!!', body: 'I got 1,999 points in Snake on my dad’s Nokia. Then somebody called him and I lost. Do NOT call my dad.'},
		{from: 'xX_HaCkEr_Xx', to: 'All', subject: 'FREE INTERNET HACK', body: 'Type +++ATH in your modem and it does something cool. Wait. It hangs up. Never mind.'},
		{from: 'SysOp', to: 'All', subject: 'RULES (READ THEM)', body: '1. No swearing. 2. Max 60 minutes a day, the phone bill is in MY name. 3. Whoever downloads DOOM2DEM.ZIP at 2400 baud every day: it takes 2 hours. Every day. Stop.'},
		{from: 'Lillesøster', to: 'Sindre', subject: 'GET OFF THE PHONE', body: 'I need to call Ingrid. You have been on the BBS for 3 hours. I am telling Mamma.'},
	];

	function showMessage(index) {
		const post = posts[index];
		clearScreen();
		println(`|09Message ${index + 1} of ${posts.length} ─ General Chat`);
		println(`|11From: |15${post.from}`);
		println(`|11To:   |15${post.to}`);
		println(`|11Subj: |14${post.subject}`);
		println('|08──────────────────────────────────');
		println(`|07${post.body}`);
		println();

		const keys = [];

		if (index < posts.length - 1) {
			keys.push({key: 'N', label: 'Next', action: () => {
				showMessage(index + 1);
			}});
		}

		if (index > 0) {
			keys.push({key: 'P', label: 'Previous', action: () => {
				showMessage(index - 1);
			}});
		}

		keys.push(
			{key: 'R', label: 'Reply', action: () => {
				reply(post);
			}},
			{key: 'Q', label: 'Quit', action: mainMenu},
		);

		println(keys.map(item => `|14[${item.key}]|07${item.label.slice(1)}`).join('  '));
		menu(keys);
	}

	function reply(post) {
		askLine('|11Your reply (one line): |15', text => {
			if (!text) {
				println('|08Nothing to say? OK.');
				anyKey(() => {
					showMessage(posts.indexOf(post));
				});
				return;
			}

			posts.push({from: profile.handle, to: post.from, subject: `RE: ${post.subject.replace(/^RE: /, '')}`, body: text.replaceAll('|', '')});
			println('|10Saved! All 12 users of Fjordnet will read it. Even the SysOp.');
			anyKey(() => {
				showMessage(posts.length - 1);
			});
		});
	}

	// The files, which come at 2400 baud, as the SysOp limits the speed for the phone bill. A small file arrives. A big one never does, as somebody always picks up the phone.
	const files = [
		{name: 'WAFFLES.TXT', size: 2400, description: 'Mormor’s waffle recipe'},
		{name: 'GLITTER.ZIP', size: 1_999_000, description: 'Unicorn screen saver'},
		{name: 'DOOM2DEM.ZIP', size: 2_097_152, description: 'DOOM II demo (big!)'},
		{name: 'Y2KFIX.ZIP', size: 666_666, description: 'Fixes Y2K (maybe)'},
		{name: 'HAMSTER.WAV', size: 412_000, description: 'The Hampster Dance'},
	];

	function fileArea() {
		clearScreen();
		header('FILE AREA: BEST OF 1999');
		println('|11 #  File name      Size      ');
		println('|08 ── ────────────── ──────────');

		for (const [index, file] of files.entries()) {
			println(`|14 ${index + 1}  |15${file.name.padEnd(14)} |07${`${formatNumber(Math.ceil(file.size / 1000))}K`.padStart(7)}`);
			println(`|08    ${file.description}`);
		}

		println();
		println('|08Downloads go at 2400 baud. The phone bill is in the name of the SysOp.');
		menu([
			...files.map((file, index) => ({key: String(index + 1), label: file.name, action: () => {
				pickProtocol(file);
			}})),
			{key: 'Q', label: 'Quit', action: mainMenu},
		], '|11Download which file? |15');
	}

	function pickProtocol(file) {
		println('|07Protocol: |14[Z]|07modem  |14[X]|07modem  |14[K]|07ermit');
		const start = () => {
			download(file);
		};

		menu([
			{key: 'Z', label: 'Zmodem', action: start},
			{key: 'X', label: 'Xmodem', action: start},
			{key: 'K', label: 'Kermit', action: start},
		]);
	}

	const waffleRecipe = `|15WAFFLES.TXT
|07Mormor's waffles (for 8 hearts):
5 dl flour, 5 dl milk, 4 eggs,
1 dl sugar, 1 tsp cardamom,
100 g melted butter.
Rest 30 minutes. Serve with brunost.
|08Do not tell Sindre where the brunost is.`;

	function download(file) {
		const run = callRun;
		const startedAt = Date.now();
		// Somebody picks up the phone while a big file comes in, a few seconds in.
		const mammaAt = file.size > 100_000 ? randomInteger(8000, 11_000) : Infinity;
		println(`|11ZMODEM: sending |15${file.name}|11 (${formatNumber(file.size)} bytes)`);
		println('|08Press any key to abort.');
		const progress = printLive('');

		const update = () => {
			const elapsed = (Date.now() - startedAt) / 1000;
			const bytes = Math.min(Math.floor(elapsed * 237), file.size);
			const share = bytes / file.size;
			const filled = Math.floor(share * 16);
			const remaining = Math.ceil((file.size - bytes) / 237);
			const eta = `${Math.floor(remaining / 3600)}:${String(Math.floor(remaining / 60) % 60).padStart(2, '0')}:${String(remaining % 60).padStart(2, '0')}`;
			progress.textContent = `[${'█'.repeat(filled)}${'░'.repeat(16 - filled)}] ${(share * 100).toFixed(1)}%\n${formatNumber(bytes)} bytes, 237 CPS, ETA ${eta}`;
			scrollToEnd();
			return bytes === file.size;
		};

		update();
		liveTimer = terminal.interval(400, () => {
			if (run !== callRun) {
				liveTimer.cancel();
				return;
			}

			if (Date.now() - startedAt >= mammaAt) {
				liveTimer.cancel();
				mode = {kind: 'off'};
				stopInput();
				print('|12~}{@!ÿ%&Ç¥◘~~ ');
				println('|12▒▒░░▒');
				println('|14Mamma: HALLO? Who is whistling on my phone line? I need to call Mormor!');
				hangUp('|07+++\nATH0');
				println('|08The download is gone. It was at 0.1%. Click Call to try again.');
				setup.hidden = false;
				return;
			}

			if (update()) {
				liveTimer.cancel();
				println(`|10Transfer complete! Saved as C:\\DOWNLOAD\\${file.name}`);
				println();
				println(waffleRecipe);
				anyKey(fileArea);
			}
		});

		mode = {kind: 'any', action: () => {
			liveTimer.cancel();
			println('|12Transfer aborted. 0 files sent.');
			anyKey(fileArea);
		}};
		input.placeholder = 'Press any key to abort';
		showKeys([keyButton('Abort', () => {
			pressKey(' ');
		})]);
	}

	function whoIsOnline() {
		clearScreen();
		header('WHO IS ONLINE');
		println('|11Node  User             Doing');
		println(`|14 1    |15${profile.handle.padEnd(16)} |07Reading this`);
		println('|14 2    |08(no node 2, Mamma uses the other phone)');
		println();
		println('|11Last callers today:');
		println('|07DoomLord99, GlitterGirl, Snakemaster, Brunost_Boy, xX_HaCkEr_Xx, DoomLord99 (again), DoomLord99 (again)');
		println();
		anyKey(mainMenu);
	}

	// The SysOp eats dinner, but answers in the end, with one hand.
	const sysopReplies = [
		{words: /^(hi|hello|hey|hei|hallo|heisann)\b/i, text: 'Hei! *chews* Sorry, I am eating fish cakes.'},
		{words: /down|file|slow|baud/i, text: 'The downloads are slow because the BBS runs on a 386. I pressed Turbo. It is still slow.'},
		{words: /troll|door|game|lord|dragon/i, text: 'The Red Troll lives in the cave under Fløyen. Get to level 6, buy a good weapon, and bring waffles.'},
		{words: /y2k|2000/i, text: 'I will unplug the BBS on December 31. Just in case. And fill the bathtub.'},
		{words: /unicorn|glitter/i, text: 'There are no unicorns in Bergen. Only seagulls. Big ones.'},
		{words: /waffle|food|dinner|fish/i, text: 'Fish cakes. With potatoes. My wife made them. Do not tell her I am chatting at the table.'},
	];

	const sysopFillers = ['*munch munch*', 'Mm-hmm.', 'Can you type slower? I type with one hand. The other has a fish cake.', 'Who is this? Is this the kid who downloads DOOM every day?', 'Hmm. Interesting. *drinks milk*'];

	async function chat() {
		const run = callRun;
		clearScreen();
		println('|14Paging the SysOp…');
		modemSounds.beep();

		if (!await sleep(run, 1500)) {
			return;
		}

		println('|08(The SysOp is eating dinner. Fish cakes again.)');

		if (!await sleep(run, 1800)) {
			return;
		}

		println('|12*** The SysOp has entered chat mode ***');
		println('|15SysOp: |07*chewing* Hi. Make it quick, my dinner gets cold. Type bye to leave.');
		chatLine(0);
	}

	function chatLine(count) {
		askLine('|10You: |15', async text => {
			const run = callRun;

			if (!text || /^(bye|quit|q|ha det)$/i.test(text)) {
				println('|15SysOp: |07Ha det! *goes back to dinner*');
				anyKey(mainMenu);
				return;
			}

			if (!await sleep(run, 900)) {
				return;
			}

			if (count >= 4) {
				println('|15SysOp: |07My wife says my dinner is cold now. And she needs the phone. Bye!');
				println('|12*** The SysOp has left chat mode ***');
				anyKey(mainMenu);
				return;
			}

			const answer = sysopReplies.find(entry => entry.words.test(text))?.text ?? randomItem(sysopFillers);
			println(`|15SysOp: |07${answer}`);
			chatLine(count + 1);
		});
	}

	function doors() {
		clearScreen();
		header('DOORS (GAMES)');
		println(' |14[1]|15 Legend of the Red Troll |08(new!)');
		println(' |14[2]|07 Trade Wars 2002');
		println(' |14[3]|07 Usurper');
		println(' |14[Q]|07 Back to the main menu');
		println();
		menu([
			{key: '1', label: 'Red Troll', action: troll.title},
			{key: '2', label: 'Trade Wars', action: () => {
				println('|12Trade Wars 2002 is closed. Somebody’s little brother sold all the planets.');
				anyKey(doors);
			}},
			{key: '3', label: 'Usurper', action: () => {
				println('|12Usurper needs 640K of free memory. The BBS has 639K.');
				anyKey(doors);
			}},
			{key: 'Q', label: 'Quit', action: mainMenu},
		]);
	}

	function goodbye() {
		println('|11Log off Fjordnet? |14[Y]|07es |14[N]|07o');
		menu([
			{key: 'Y', label: 'Yes', action: async () => {
				const run = callRun;
				println(`|10Thanks for calling Fjordnet BBS, |15${profile.handle}|10!`);
				println('|07Hang up now, please. Somebody needs the phone. Somebody always needs the phone.');

				if (await sleep(run, 1500)) {
					hangUp('|07ATH0');
					setup.hidden = false;
				}
			}},
			{key: 'N', label: 'No', action: mainMenu},
		]);
	}

	// Legend of the Red Troll, a door game like Legend of the Red Dragon (Seth Robinson, 1989): fight in the forest of Fløyen, buy weapons and armor, beat your master to reach the next level, and slay the Red Troll at level 6. Like in LORD, there are 15 forest fights a day, and a hero who dies comes back tomorrow. The hero stays in the browser.
	const today = () => new Date().toDateString();
	const maxHitPoints = level => 20 + ((level - 1) * 15);

	const newHero = trollKills => ({level: 1, experience: 0, hitPoints: 20, gold: 30, weapon: 0, armor: 0, waffles: 0, fightsLeft: 15, day: today(), isDead: false, kills: 0, trollKills});

	let hero = terminal.stored('hero');

	const saveHero = () => {
		terminal.store('hero', hero);
	};

	const weapons = [
		{name: 'Stick', attack: 0, price: 0},
		{name: 'Butter knife', attack: 3, price: 100},
		{name: 'Hockey stick', attack: 6, price: 350},
		{name: 'Cheese slicer', attack: 10, price: 900},
		{name: 'Viking sword', attack: 15, price: 2400},
		{name: 'Golden waffle iron', attack: 22, price: 5500},
	];

	const armors = [
		{name: 'Wool sweater', defense: 0, price: 0},
		{name: 'Rain jacket', defense: 2, price: 120},
		{name: 'Snowsuit', defense: 4, price: 400},
		{name: 'Bicycle helmet', defense: 7, price: 1000},
		{name: 'Viking armor', defense: 11, price: 2600},
		{name: 'Bunad of power', defense: 15, price: 5800},
	];

	// The experience that a hero needs to fight the master of each level.
	const experienceNeeded = [60, 180, 400, 800, 1500];

	// The monsters of the forest, by level, with what they do when they hit.
	const monsters = [
		[
			['an angry seagull', 'steals your sandwich and pecks you'],
			['a Y2K bug', 'sets your date to 1900'],
			['a wet wool sock', 'squelches into your face'],
			['a lost tourist', 'asks for the fish market, very loudly'],
		],
		[
			['a Furby that will not sleep', 'talks to you all night'],
			['a runaway shopping cart', 'rolls over your toes'],
			['a lemming', 'walks right into you'],
			['a hungry goat', 'eats your shoelaces'],
		],
		[
			['Clippy', 'says “It looks like you are trying to fight” and hits you'],
			['a Bergen rain cloud', 'rains on you sideways'],
			['a mutant brunost', 'sticks to the roof of your mouth'],
			['a pack of wild Tamagotchis', 'beep until you cry'],
		],
		[
			['the dancing baby', 'dances at you, which is disturbing'],
			['a telemarketer', 'calls you during dinner'],
			['the Hot Dog Stand color scheme', 'burns your eyes'],
			['a herd of Napster users', 'downloads your shoes'],
		],
		[
			['BonziBUDDY', 'installs a toolbar on you'],
			['the cousin of the Red Troll', 'throws a rock'],
			['the Blue Screen of Death', 'hits you with a fatal exception 0E'],
			['a snowplow', 'buries you in snow'],
		],
		[
			['the Kraken of the fjord', 'squeezes you with eight arms'],
			['a Julebukk', 'sings at your door and will not leave'],
			['the tax man', 'takes half of your stuff'],
			['a giant moose', 'stares, then charges'],
		],
	];

	const monsterStats = [
		{hitPoints: [5, 8], strength: [3, 4], gold: [10, 18], experience: [8, 14]},
		{hitPoints: [12, 16], strength: [7, 9], gold: [28, 45], experience: [22, 32]},
		{hitPoints: [22, 28], strength: [11, 13], gold: [60, 90], experience: [45, 60]},
		{hitPoints: [34, 42], strength: [15, 18], gold: [120, 170], experience: [75, 100]},
		{hitPoints: [48, 56], strength: [21, 24], gold: [240, 340], experience: [130, 170]},
		{hitPoints: [62, 70], strength: [28, 31], gold: [400, 550], experience: [200, 260]},
	];

	// The masters, who let a hero reach the next level when the hero beats them.
	const masters = [
		{name: 'Lillesøster', hitPoints: 12, strength: 4, greeting: 'You have to beat ME first. And I bite.', defeat: 'Fine. You are level 2. I am telling Mamma.'},
		{name: 'Ola, the gym teacher', hitPoints: 28, strength: 9, greeting: 'Ten push-ups first! Then we fight.', defeat: 'Not bad! You can skip the cross-country run on Friday.'},
		{name: 'Pappa', hitPoints: 45, strength: 14, greeting: 'Not now, I am reading the newspaper. OK, one fight.', defeat: 'Ouch. You are stronger than you look. Go ask your mother for an ice cream.'},
		{name: 'Mormor', hitPoints: 70, strength: 18, greeting: 'I will fight you with my knitting needles. Then you get waffles.', defeat: 'Oh my! Here, have a waffle. You look thin.'},
		{name: 'the SysOp', hitPoints: 100, strength: 23, greeting: 'You downloaded DOOM2DEM.ZIP 47 times at 2400 baud. Prepare yourself.', defeat: 'I bow to you. You are now level 6. The Red Troll waits under Fløyen…'},
	];

	const strength = () => 5 + ((hero.level - 1) * 4) + weapons[hero.weapon].attack;
	const defense = () => armors[hero.armor].defense;
	const fightLine = enemy => `|07You: |15${hero.hitPoints}/${maxHitPoints(hero.level)} HP|07  ${enemy.title}: |15${Math.max(enemy.hitPoints, 0)} HP`;

	// A new day gives the 15 fights back and wakes the dead, like the daily maintenance of LORD.
	const startDay = () => {
		hero.day = today();
		hero.fightsLeft = 15;
		hero.isDead = false;
		hero.hitPoints = maxHitPoints(hero.level);
		hero.kills = 0;
		saveHero();
	};

	const troll = {
		title() {
			clearScreen();
			printArt(trollArt, 6);
			println();
			println('|12  L E G E N D   O F   T H E');
			println('|12      R E D   T R O L L');
			println('|08  v1.99, a door for Fjordnet BBS');
			println();
			println(' |14[E]|07nter the realm');
			println(' |14[I]|07nstructions');
			println(' |14[Q]|07uit to the BBS');
			menu([
				{key: 'E', label: 'Enter', action: troll.enter},
				{key: 'I', label: 'Instructions', action: troll.instructions},
				{key: 'Q', label: 'Quit', action: doors},
			]);
		},
		instructions() {
			clearScreen();
			header('HOW TO PLAY');
			println('|07A Red Troll lives in the cave under Fløyen, and eats the waffles of Bergen. Somebody has to stop it.');
			println();
			println('|07Fight monsters in the |14forest|07 for gold and experience. Buy |14weapons|07 and |14armor|07. When you have enough experience, beat your |14master|07 to reach the next level. At |14level 6|07, the cave opens.');
			println();
			println('|07You get |1415 forest fights|07 a day. If you die, you come back tomorrow. |14Waffles|07 from the bakery heal you in a fight.');
			anyKey(troll.title);
		},
		enter() {
			if (!hero) {
				hero = newHero(0);
				saveHero();
				println(`|10A new hero arrives in Bergen: |15${profile.handle}|10!`);
			} else if (hero.day !== today()) {
				startDay();
				println('|10A new day dawns over Bergen. It rains. You feel rested.');
			}

			anyKey(troll.town);
		},
		town() {
			clearScreen();
			println('|10THE TOWN SQUARE OF BERGEN');
			println(`|08${randomItem(['The rain falls. A seagull steals a waffle.', 'The fish market smells of fish. Of course it does.', 'Somebody plays the accordion, badly.', 'A tourist asks if it always rains. Yes.'])}`);
			println();
			println(' |14[F]|07orest of Fløyen  |14[H]|07ealer');
			println(' |14[W]|07eapon shop       |14[A]|07rmor shop');
			println(' |14[B]|07akery            |14[M]|07aster');
			println(' |14[V]|07iew your stats   |14[N]|07ews');

			if (hero.level === 6) {
				println(' |12[R]|07ed Troll’s cave');
			}

			if (hero.isDead || hero.fightsLeft === 0) {
				println(' |14[T]|07omorrow');
			}

			println(' |14[Q]|07uit to the BBS');
			println();
			println(`|07HP |15${hero.hitPoints}/${maxHitPoints(hero.level)}|07  Gold |14${formatNumber(hero.gold)}|07  Fights |15${hero.fightsLeft}|07  Level |15${hero.level}`);

			const keys = [
				{key: 'F', label: 'Forest', action: troll.forest},
				{key: 'H', label: 'Healer', action: troll.healer},
				{key: 'W', label: 'Weapons', action: () => {
					troll.shop(weapons, 'weapon', 'WEAPON SHOP', 'attack');
				}},
				{key: 'A', label: 'Armor', action: () => {
					troll.shop(armors, 'armor', 'ARMOR SHOP', 'defense');
				}},
				{key: 'B', label: 'Bakery', action: troll.bakery},
				{key: 'M', label: 'Master', action: troll.master},
				{key: 'V', label: 'Stats', action: troll.stats},
				{key: 'N', label: 'News', action: troll.news},
			];

			if (hero.level === 6) {
				keys.push({key: 'R', label: 'Red Troll', action: troll.cave});
			}

			if (hero.isDead || hero.fightsLeft === 0) {
				keys.push({key: 'T', label: 'Tomorrow', action: troll.tomorrow});
			}

			keys.push({key: 'Q', label: 'Quit', action: doors});
			menu(keys);
		},
		tomorrow() {
			println('|07Real heroes wait until tomorrow. But you have Windows 98, so you set the clock of the computer forward one day.');
			println('|08(The SysOp sees this. He sighs.)');
			startDay();
			println('|10A new day! You have 15 forest fights, and you feel great.');
			anyKey(troll.town);
		},
		forest() {
			if (hero.isDead) {
				println('|12You are dead. The forest is not for the dead. Come back tomorrow.');
				anyKey(troll.town);
				return;
			}

			if (hero.fightsLeft === 0) {
				println('|12You are too tired to fight. Come back tomorrow.');
				anyKey(troll.town);
				return;
			}

			clearScreen();
			println('|02THE FOREST OF FLØYEN');
			println(`|07Fights left today: |15${hero.fightsLeft}`);
			println();
			println(' |14[L]|07ook for something to kill');
			println(' |14[H]|07ealer');
			println(' |14[R]|07eturn to town');
			menu([
				{key: 'L', label: 'Look', action: troll.look},
				{key: 'H', label: 'Healer', action: troll.healer},
				{key: 'R', label: 'Town', action: troll.town},
			]);
		},
		look() {
			if (hero.fightsLeft === 0) {
				troll.forest();
				return;
			}

			hero.fightsLeft--;
			saveHero();

			// Sometimes the forest has something else than a fight, like in LORD.
			if (Math.random() < 0.15) {
				const events = [
					() => {
						const gold = randomInteger(5, 20) * hero.level * hero.level;
						hero.gold += gold;
						println(`|14You find a wallet on the path, with ${formatNumber(gold)} gold in it. Finders keepers!`);
					},
					() => {
						hero.hitPoints = maxHitPoints(hero.level);
						println('|13You meet Glitter the unicorn! She sparkles at you, and you feel completely healed.');
					},
					() => {
						hero.hitPoints = Math.min(hero.hitPoints + 10, maxHitPoints(hero.level));
						println('|14You find a waffle with brown cheese on a rock. It is still warm. +10 HP!');
					},
					() => {
						hero.waffles = Math.min(hero.waffles + 1, 5);
						println('|14A kind old lady gives you a waffle for later. You put it in your pocket.');
					},
				];

				randomItem(events)();
				saveHero();
				anyKey(troll.forest);
				return;
			}

			const level = hero.level - 1;
			const [name, attack] = randomItem(monsters[level]);
			const stats = monsterStats[level];
			const enemy = {
				kind: 'monster',
				title: name.replace(/^(a|an|the) /, '').replace(/^./, letter => letter.toUpperCase()),
				name,
				attack,
				hitPoints: randomInteger(...stats.hitPoints),
				strength: randomInteger(...stats.strength),
				gold: randomInteger(...stats.gold),
				experience: randomInteger(...stats.experience),
			};

			clearScreen();
			println(`|12**** You have encountered ${name}! ****`);
			troll.fight(enemy);
		},
		fight(enemy) {
			println(fightLine(enemy));
			const keys = [
				{key: 'A', label: 'Attack', action: () => {
					troll.attack(enemy);
				}},
				{key: 'R', label: 'Run', action: () => {
					troll.run(enemy);
				}},
			];

			if (hero.waffles > 0) {
				keys.push({key: 'W', label: `Waffle (${hero.waffles})`, action: () => {
					troll.eatWaffle(enemy);
				}});
			}

			println(keys.map(item => `|14[${item.key}]|07${item.label.slice(1)}`).join('  '));
			menu(keys);
		},
		attack(enemy) {
			const power = strength();
			let damage = randomInteger(Math.ceil(power / 2), power);

			if (Math.random() < 0.1) {
				damage *= 2;
				println('|14**SUPER STRIKE!**');
			}

			enemy.hitPoints -= damage;
			println(`|10You hit ${enemy.name} for |15${damage}|10 damage!`);

			if (enemy.hitPoints <= 0) {
				troll.win(enemy);
				return;
			}

			troll.enemyTurn(enemy);
		},
		enemyTurn(enemy) {
			const damage = Math.max(randomInteger(Math.ceil(enemy.strength / 2), enemy.strength) - defense(), 0);

			if (damage === 0) {
				println(`|08${enemy.title} misses you.`);
			} else {
				hero.hitPoints -= damage;
				println(`|12${enemy.title} ${enemy.attack}! You lose |15${damage}|12 HP.`);
			}

			if (hero.hitPoints <= 0) {
				troll.lose(enemy);
				return;
			}

			saveHero();
			troll.fight(enemy);
		},
		run(enemy) {
			if (enemy.kind === 'master') {
				println(`|07You run back to town. ${enemy.title} laughs.`);
				anyKey(troll.town);
				return;
			}

			if (Math.random() < (enemy.kind === 'troll' ? 0.3 : 0.6)) {
				println('|07You run away, screaming. Nobody saw it. Probably.');
				anyKey(enemy.kind === 'troll' ? troll.town : troll.forest);
				return;
			}

			println(`|12You trip over a root! ${enemy.title} catches you.`);
			troll.enemyTurn(enemy);
		},
		eatWaffle(enemy) {
			hero.waffles--;
			hero.hitPoints = Math.min(hero.hitPoints + 30, maxHitPoints(hero.level));
			println('|14You eat a waffle with brown cheese. Delicious! +30 HP.');
			troll.enemyTurn(enemy);
		},
		win(enemy) {
			if (enemy.kind === 'master') {
				hero.level++;
				hero.hitPoints = maxHitPoints(hero.level);
				saveHero();
				println(`|15${enemy.title}: |07“${enemy.defeat}”`);
				println(`|14You are now level ${hero.level}! You have ${maxHitPoints(hero.level)} HP, and you hit harder.`);
				anyKey(troll.town);
				return;
			}

			if (enemy.kind === 'troll') {
				troll.victory();
				return;
			}

			hero.gold += enemy.gold;
			hero.experience += enemy.experience;
			hero.kills++;
			saveHero();
			println(`|10You killed ${enemy.name}! You find |14${formatNumber(enemy.gold)}|10 gold, and get |15${enemy.experience}|10 experience.`);

			const needed = experienceNeeded[hero.level - 1];

			if (needed && hero.experience >= needed && hero.experience - enemy.experience < needed) {
				println('|14You have enough experience to fight your master!');
			}

			anyKey(troll.forest);
		},
		lose(enemy) {
			if (enemy.kind === 'master') {
				hero.hitPoints = 1;
				saveHero();
				println(`|12${enemy.title} beats you, and helps you up. “Come back when you are stronger.”`);
				anyKey(troll.town);
				return;
			}

			hero.hitPoints = 0;
			hero.isDead = true;
			hero.gold = 0;
			saveHero();
			println(`|12You have been slain by ${enemy.name}!`);
			println('|07You lose all the gold you had on you. Come back tomorrow.');
			println(`|08The news: “${profile.handle} was killed by ${enemy.name}. Everybody laughed.”`);
			anyKey(troll.town);
		},
		healer() {
			clearScreen();
			println('|11THE HUT OF THE HEALER');
			const missing = maxHitPoints(hero.level) - hero.hitPoints;

			if (hero.isDead) {
				println('|07“I heal the living. You are not. Come back tomorrow.”');
				anyKey(troll.town);
				return;
			}

			if (missing === 0) {
				println('|07“You look fine to me. That will be 10 gold for the advice. Just kidding.”');
				anyKey(troll.town);
				return;
			}

			const price = missing * hero.level;
			println(`|07“You have ${missing} wounds. I heal them all for |14${formatNumber(price)}|07 gold.” You have |14${formatNumber(hero.gold)}|07 gold.`);
			println(' |14[H]|07eal all  |14[L]|07eave');
			menu([
				{key: 'H', label: 'Heal', action: () => {
					const healed = Math.min(missing, Math.floor(hero.gold / hero.level));

					if (healed === 0) {
						println('|12“No gold, no healing. This is not Sweden.”');
					} else {
						hero.gold -= healed * hero.level;
						hero.hitPoints += healed;
						saveHero();
						println(`|10The healer puts a plaster on it. +${healed} HP.`);
					}

					anyKey(troll.town);
				}},
				{key: 'L', label: 'Leave', action: troll.town},
			]);
		},
		shop(items, property, title, statName) {
			clearScreen();
			header(title);

			for (const [index, item] of items.entries()) {
				if (index > 0) {
					const isOwned = hero[property] === index;
					println(`|14 ${index}  |15${item.name.padEnd(19)}|07${`+${item[statName]}`.padStart(3)} ${isOwned ? '|10(yours)' : `|14${formatNumber(item.price).padStart(6)}`}`);
				}
			}

			println();
			println(`|07You have: |15${items[hero[property]].name}|07, and |14${formatNumber(hero.gold)}|07 gold.`);
			println('|08Your old one is traded in for half its price.');
			menu([
				...items.slice(1).map((item, index) => ({key: String(index + 1), label: item.name, action: () => {
					const price = item.price - Math.floor(items[hero[property]].price / 2);

					if (hero[property] === index + 1) {
						println('|07You already have that one.');
					} else if (hero.gold < price) {
						println(`|12You need |14${formatNumber(price)}|12 gold. You have |14${formatNumber(hero.gold)}|12. Go fight some seagulls.`);
					} else {
						hero.gold -= price;
						hero[property] = index + 1;
						saveHero();
						println(`|10You buy the ${item.name}! It is great.`);
					}

					anyKey(() => {
						troll.shop(items, property, title, statName);
					});
				}})),
				{key: 'Q', label: 'Leave', action: troll.town},
			], '|11Buy which? |15');
		},
		bakery() {
			clearScreen();
			println('|14THE BAKERY');
			println('|07Waffles with brown cheese, 40 gold each. A waffle heals 30 HP in a fight. Your pockets hold 5.');
			println(`|07You have |15${hero.waffles}|07 waffles and |14${formatNumber(hero.gold)}|07 gold.`);
			println(' |14[B]|07uy a waffle  |14[L]|07eave');
			menu([
				{key: 'B', label: 'Buy', action: () => {
					if (hero.waffles >= 5) {
						println('|12Your pockets are full of waffles. That is not a bad problem.');
					} else if (hero.gold < 40) {
						println('|12“No gold, no waffle.”');
					} else {
						hero.gold -= 40;
						hero.waffles++;
						saveHero();
						println('|10You buy a waffle. It smells wonderful.');
					}

					anyKey(troll.bakery);
				}},
				{key: 'L', label: 'Leave', action: troll.town},
			]);
		},
		master() {
			clearScreen();
			const master = masters[hero.level - 1];

			if (!master) {
				println('|07You have beaten all the masters. Only the Red Troll is left.');
				anyKey(troll.town);
				return;
			}

			println(`|11THE HALL OF THE MASTERS`);
			println(`|07Your master is |15${master.name}|07.`);
			const needed = experienceNeeded[hero.level - 1];

			if (hero.experience < needed) {
				println(`|07“You need |15${formatNumber(needed - hero.experience)}|07 more experience. Go to the forest.”`);
				anyKey(troll.town);
				return;
			}

			if (hero.isDead) {
				println('|07“You are dead. Come back tomorrow.”');
				anyKey(troll.town);
				return;
			}

			println(`|15${master.name}: |07“${master.greeting}”`);
			troll.fight({kind: 'master', title: master.name.replace(/^the /, 'The '), name: master.name, attack: 'hits you', hitPoints: master.hitPoints, strength: master.strength, defeat: master.defeat});
		},
		cave() {
			if (hero.isDead) {
				println('|12You are dead. Even the Red Troll does not want you. Come back tomorrow.');
				anyKey(troll.town);
				return;
			}

			clearScreen();
			printArt(trollArt, 6);
			println();
			println('|12THE CAVE UNDER FLØYEN');
			println('|07It smells of old brown cheese. Something BIG breathes in the dark. Two yellow eyes open.');
			println('|12The Red Troll: |07“WHO STEALS MY WAFFLES?”');
			println(' |14[F]|07ight  |14[R]|07un home to Mamma');
			menu([
				{key: 'F', label: 'Fight', action: () => {
					troll.fight({kind: 'troll', title: 'The Red Troll', name: 'the Red Troll', attack: randomItem(['swings a pine tree', 'stomps the ground', 'throws a boulder']), hitPoints: 160, strength: 40});
				}},
				{key: 'R', label: 'Run', action: troll.town},
			]);
		},
		victory() {
			hero.trollKills++;
			saveHero();
			clearScreen();
			printArt(unicornArt, 4);
			println();
			println('|14★ YOU SLAYED THE RED TROLL! ★');
			println(`|07The Red Troll turns to stone in the first light of the morning. Bergen is saved! The bards will sing of |15${profile.handle}|07, mostly off key.`);
			println(`|07Heroes who slayed the troll: |15${hero.trollKills}|07 time${hero.trollKills === 1 ? '' : 's'}.`);
			println();
			println('|11Like in LORD, the realm starts over with a new hero.');
			println(' |14[Y]|07 Play again  |14[Q]|07 Back to the BBS');
			terminal.celebrate();
			terminal.toast(`${profile.handle} slayed the Red Troll on Fjordnet BBS!`);
			menu([
				{key: 'Y', label: 'Play again', action: () => {
					hero = newHero(hero.trollKills);
					saveHero();
					troll.title();
				}},
				{key: 'Q', label: 'Quit', action: () => {
					hero = newHero(hero.trollKills);
					saveHero();
					doors();
				}},
			]);
		},
		stats() {
			clearScreen();
			header(`${profile.handle.toUpperCase()}, LEVEL ${hero.level}`);
			const needed = experienceNeeded[hero.level - 1];
			const rows = [
				['Experience', `${formatNumber(hero.experience)}${needed ? ` (master at ${formatNumber(needed)})` : ''}`],
				['Hit points', `${hero.hitPoints} of ${maxHitPoints(hero.level)}${hero.isDead ? ' (dead)' : ''}`],
				['Strength', String(strength())],
				['Defense', String(defense())],
				['Gold', formatNumber(hero.gold)],
				['Weapon', weapons[hero.weapon].name],
				['Armor', armors[hero.armor].name],
				['Waffles', String(hero.waffles)],
				['Fights left', String(hero.fightsLeft)],
				['Trolls slayed', String(hero.trollKills)],
			];

			for (const [label, value] of rows) {
				println(`|11${label.padEnd(14)}|15${value}`);
			}

			anyKey(troll.town);
		},
		news() {
			clearScreen();
			header('THE BERGEN DAILY NEWS');
			println(`|07${profile.handle} killed |15${hero.kills}|07 monsters today.`);
			println('|07GlitterGirl was killed by a Furby. She says it was a trap.');
			println('|07DoomLord99 bought a cheese slicer, and cut his finger.');
			println('|07It rained. It will rain tomorrow too.');
			println('|07The Red Troll ate 400 waffles. The bakery is out of cardamom.');
			anyKey(troll.town);
		},
	};

	clearScreen();
	println('|08HyperTerminal. Fill in the Connection Description, and click Dial.');
	showStatus();

	return {
		// Closing the window hangs up, like HyperTerminal asks before it closes.
		windowChanged(isOpen) {
			if (!isOpen) {
				hangUp();
				setup.hidden = false;
			}
		},
		// The button that turns off gives the focus to the one that takes over, and the field and the Connection Description give it to the screen when they turn off or hide, so a keyboard does not start over at the top of the page.
		focusReplacement(control) {
			if (control === callButton) {
				return hangUpButton;
			}

			if (control === hangUpButton) {
				return callButton;
			}

			if (control === input || setup.contains(control)) {
				return screen;
			}
		},
	};
};

export default class extends GeoCitiesElement {
	#terminal;

	connected() {
		this.#terminal = setUpTerminal(this, this.parts);
	}

	windowChanged(isOpen) {
		this.#terminal.windowChanged(isOpen);
	}

	focusReplacement(control) {
		return this.#terminal.focusReplacement(control) ?? super.focusReplacement(control);
	}
}
