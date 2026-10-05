// The fun stuff of Windows 95 and 98 on the desktop of the 1999 page: BonziBUDDY, Microsoft Bob, the Windows 95 CD-ROM with its videos, Happy99, Nordmann AntiVirus 99, WinZip, Phone Dialer, ScanDisk, and Disk Cleanup. `geocities.js` opens, drags, and closes the windows, and `geocities-windows.js` asks the questions with its message box and gives the sounds its volume. Nothing makes a sound until the visitor clicks something that says it plays sound.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// A tone through the audio of `sound()`, or through the volume of one song, which can stop it. A note before the start, like a note of a video that resumes in the middle, is left out.
const tone = (sound, frequency, start, duration, {type = 'sine', volume = 0.12, slide} = {}) => {
	if (!sound || start < 0) {
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
};

// A burst of noise, for drums, a laugh track, and a crowd.
const noise = (sound, start, duration, {volume = 0.1, frequency = 1000, q = 0.7} = {}) => {
	if (!sound || start < 0) {
		return;
	}

	const {context, output} = sound;
	const buffer = context.createBuffer(1, Math.ceil(context.sampleRate * duration), context.sampleRate);
	const samples = buffer.getChannelData(0);

	for (let index = 0; index < samples.length; index++) {
		samples[index] = (Math.random() * 2) - 1;
	}

	const source = context.createBufferSource();
	const filter = context.createBiquadFilter();
	const gain = context.createGain();
	const time = context.currentTime + start;
	source.buffer = buffer;
	filter.type = 'bandpass';
	filter.frequency.value = frequency;
	filter.Q.value = q;
	gain.gain.setValueAtTime(volume, time);
	gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
	source.connect(filter).connect(gain).connect(output);
	source.start(time);
};

// Bonzi is drawn with rectangles on a canvas of 48 × 56 pixels, which is shown at twice the size, like the sprites of Microsoft Agent.
const drawBonzi = (context, {pose, frame, isTalking}) => {
	const purple = '#7b2fbe';
	const dark = '#4e1a80';
	const light = '#c9a2f0';
	const rect = (color, x, y, width, height) => {
		context.fillStyle = color;
		context.fillRect(x, y, width, height);
	};

	context.clearRect(0, 0, 48, 56);
	const bob = pose === 'walk' && frame % 2 === 1 ? 1 : 0;

	// The legs, which step while he walks.
	const step = pose === 'walk' ? (frame % 2 === 0 ? 2 : -2) : 0;
	rect(dark, 15 + step, 46, 7, 8);
	rect(dark, 26 - step, 46, 7, 8);
	rect('#2a0d47', 13 + step, 53, 10, 3);
	rect('#2a0d47', 25 - step, 53, 10, 3);

	// The body, with the light belly.
	rect(purple, 12, 28 - bob, 24, 20);
	rect(light, 17, 31 - bob, 14, 14);

	// The arms. One waves while he waves or sings.
	const isWaving = pose === 'wave' || pose === 'sing';
	rect(purple, 6, 29 - bob, 6, 15);
	rect(light, 6, 43 - bob, 6, 4);

	if (isWaving) {
		const up = frame % 2 === 0 ? 0 : 3;
		rect(purple, 36, 14 + up - bob, 6, 16);
		rect(light, 36, 11 + up - bob, 6, 4);
	} else {
		rect(purple, 36, 29 - bob, 6, 15);
		rect(light, 36, 43 - bob, 6, 4);
	}

	// The head, the ears, and the face.
	rect(purple, 11, 4 - bob, 26, 24);
	rect(purple, 7, 11 - bob, 5, 7);
	rect(purple, 36, 11 - bob, 5, 7);
	rect(light, 8, 13 - bob, 3, 3);
	rect(light, 37, 13 - bob, 3, 3);
	rect(light, 15, 10 - bob, 18, 16);

	// The eyes, which blink now and then.
	const isBlinking = pose === 'idle' && frame % 12 === 11;

	if (isBlinking) {
		rect('#000000', 17, 14 - bob, 5, 1);
		rect('#000000', 26, 14 - bob, 5, 1);
	} else {
		rect('#ffffff', 17, 12 - bob, 5, 5);
		rect('#ffffff', 26, 12 - bob, 5, 5);
		rect('#000000', 19, 14 - bob, 2, 2);
		rect('#000000', 28, 14 - bob, 2, 2);
	}

	// The nose and the big smile, which opens while he talks.
	rect(dark, 22, 18 - bob, 4, 2);

	if (isTalking && frame % 2 === 0) {
		rect('#5a0010', 18, 21 - bob, 12, 4);
		rect('#ff7a9a', 21, 23 - bob, 6, 2);
	} else {
		rect('#5a0010', 18, 22 - bob, 12, 1);
		rect('#5a0010', 17, 21 - bob, 1, 1);
		rect('#5a0010', 30, 21 - bob, 1, 1);
	}
};

const bonziJokes = [
	'What do you call a computer that sings? A Dell! Ha ha ha! Get it?',
	'Why was the computer cold? It left its Windows open! Ha ha ha!',
	'Why did the gorilla cross the road? To install himself on the other side!',
	'What is a computer’s favorite snack? Microchips! With brunost!',
	'Knock knock. Who is there? BonziBUDDY. BonziBUDDY who? BonziBUDDY, and I am never leaving!',
	'How many programmers does it take to change a light bulb? None. It is a hardware problem!',
	'Why did the Y2K bug go to school? To learn to count past 99!',
];

const bonziFacts = [
	'Did you know? The first song a computer ever sang was “Daisy Bell”, on an IBM 7094 in 1961. I sing it too!',
	'Did you know? A gorilla can lift 10 times its own weight. I can lift your home page to www.bonzi.com!',
	'Did you know? I used to be a green parrot. Now I am a purple gorilla, from the year 2000. Do not ask.',
	'Did you know? Bergen has 248 days of rain a year. I checked your weather. I check everything.',
	'Did you know? I remember everything you type. That is what friends do!',
	'Did you know? Unicorns are not real. I am sorry. Somebody had to tell you.',
];

const bonziRemarks = [
	'Have you seen my special offers? They are very special.',
	'You have not clicked me in a while. Are you OK? I am here for you.',
	'I am bored. Let us search the Web together!',
	'I noticed that you like unicorns. I told all my friends.',
	'Psst! Your computer may be at risk! (It is not. But click me anyway.)',
];

// “Daisy Bell” (Harry Dacre, 1892), in the public domain: each line with its notes, as frequencies and lengths in beats.
const daisyBell = [
	{line: '🎵 Daisy, Daisy, give me your answer, do!', notes: [[587, 3], [494, 3], [392, 3], [294, 3], [330, 1], [370, 1], [392, 1], [330, 2], [392, 1], [294, 6]]},
	{line: '🎵 I’m half crazy, all for the love of you!', notes: [[440, 3], [587, 3], [494, 3], [392, 3], [330, 1], [370, 1], [392, 1], [440, 2], [494, 1], [440, 6]]},
	{line: '🎵 It won’t be a stylish marriage, I can’t afford a carriage,', notes: [[494, 1], [523, 1], [494, 1], [440, 1], [587, 2], [494, 1], [440, 1], [392, 4], [440, 1], [494, 2], [392, 1], [330, 2], [392, 1], [330, 1], [294, 4]]},
	{line: '🎵 But you’ll look sweet upon the seat of a bicycle built for two! 🚲', notes: [[294, 1], [392, 2], [494, 1], [440, 2], [294, 1], [392, 2], [494, 1], [440, 1], [494, 1], [523, 1], [587, 1], [494, 1], [392, 1], [440, 2], [294, 1], [392, 6]]},
];

const bobRooms = {
	family: {
		name: 'Family Room',
		items: [
			{icon: '📅', name: 'Calendar', say: () => `Woof! The calendar says today is ${new Date().toLocaleDateString('en-US', {month: 'long', day: 'numeric'})}, 1999. In Bob’s house, it is always 1999.`},
			{icon: '✉️', name: 'Letter Writer', program: 'wordpad', say: 'Woof! Let’s write a letter! Here is one you already started. To Santa. In October.'},
			{icon: '🧮', name: 'Checkbook', program: 'calc', say: 'Your checkbook! You have 49 kroner. Do not spend it on Y2K FIX.EXE again.'},
			{icon: '📺', name: 'TV', program: 'cdrom', say: 'The TV only shows the videos of the Windows 95 CD. Same as every TV in 1995.'},
			{icon: '🔥', name: 'Fireplace', say: 'That is a fireplace. It does nothing. That is the whole point of a fireplace.'},
			{icon: '🛋️', name: 'Sofa', say: 'Sit! Good human! Now stay. Stay…'},
			{icon: '🕰️', name: 'Clock', say: () => `The clock says ${new Date().toLocaleTimeString('en-US', {hour: 'numeric', minute: '2-digit'})}. Time for a walk? Please? PLEASE?`},
			{icon: '🚪', name: 'To the Study', room: 'study'},
			{icon: '🚪', name: 'To the Kitchen', room: 'kitchen'},
		],
	},
	study: {
		name: 'Study',
		items: [
			{icon: '🌍', name: 'Globe', program: 'ie', say: 'The globe takes you to the Internet. It is like the world, but slower.'},
			{icon: '📚', name: 'Encyclopedia', say: 'Bob’s encyclopedia has three articles: Bob, Rover, and Dogs. I wrote the last two.'},
			{icon: '🔐', name: 'Safe', say: 'Bob keeps all the passwords in this safe. The safe has no lock. Bob trusts everybody.'},
			{icon: '🖥️', name: 'Computer', program: 'documents', say: 'A computer inside Bob’s house, inside the computer. Do not think about it too long. Woof.'},
			{icon: '🪴', name: 'Plant', say: 'I water this plant every day. Do not ask how.'},
			{icon: '🚪', name: 'To the Family Room', room: 'family'},
		],
	},
	kitchen: {
		name: 'Kitchen',
		items: [
			{icon: '🧇', name: 'Waffle Iron', say: 'Somebody ate all the waffles. It was not me. (It was me.)'},
			{icon: '🧊', name: 'Fridge', say: 'Everything in the fridge is brunost. Everything.'},
			{icon: '📞', name: 'Phone', program: 'dialer', say: 'Call somebody! Not Mormor, though. She talks for two hours.'},
			{icon: '🗑️', name: 'Trash Can', program: 'recycle', say: 'My favorite place in the house! So many smells.'},
			{icon: '🦴', name: 'Rover’s Bowl', say: 'My bowl! It is empty. It is always empty. Somebody should do something about it. Hint: you.'},
			{icon: '🚪', name: 'To the Family Room', room: 'family'},
		],
	},
};

const roverTips = [
	'Tip: Comic Sans was made for my speech balloons, but it was not ready in time. Now it is on every home page. You are welcome.',
	'Tip: Bob came out in March 1995. Hardly anybody bought it. My friend Clippy got my job in Office 97.',
	'Tip: Click a door to go to another room. Like a real house! Computers are amazing.',
	'Tip: I come back in Windows XP, to help you search for files. Remember me then!',
];

const box = (context, color, x, y, width, height) => {
	context.fillStyle = color;
	context.fillRect(Math.round(x), Math.round(y), Math.round(width), Math.round(height));
};

// A person of blocks, from the feet up: the colors of the hair, the face, the shirt, and the trousers, and how the arms and the body move.
const person = (context, x, y, {hair = '#3a2410', skin = '#f1c27d', shirt = '#3050c0', trousers = '#202040', lean = 0, arms = 0, glasses = false, height = 30} = {}) => {
	const scale = height / 30;
	const part = (color, dx, dy, width, partHeight) => box(context, color, x + ((dx + (lean * (30 - dy) / 30)) * scale), y - ((30 - dy) * scale), width * scale, partHeight * scale);
	part(trousers, -4, 18, 3, 12);
	part(trousers, 1, 18, 3, 12);
	part(shirt, -5, 8, 10, 11);
	part(shirt, -8, 8 - arms, 3, 9);
	part(shirt, 5, 8 + arms, 3, 9);
	part(skin, -3, 1, 6, 7);
	part(hair, -3, 0, 6, 2);

	if (glasses) {
		part('#000000', -3, 3, 6, 1);
	}
};

const guitar = (context, x, y, color = '#c0392b') => {
	box(context, color, x - 6, y - 14, 9, 6);
	box(context, '#5a3a1a', x + 2, y - 15, 9, 2);
};

const videos = {
	buddy: {
		title: 'BUDDYHOL.AVI',
		duration: 20,
		captions: [
			[0, 'BUDDYHOL.AVI: 160 × 120 pixels, 15 frames a second. It came on the Windows 95 CD, in the Fun Stuff folder.'],
			[4, 'Weezer play “Buddy Holly” in Arnold’s, the diner from the TV show Happy Days. Spike Jonze made the video.'],
			[9, '♪ (The song is not here. It costs money. Imagine a guitar, and the year 1994.) ♪'],
			[13, 'Microsoft put it on the CD to show that Windows 95 plays video. The band only found out later.'],
			[17, 'Ayyy! The guy in the leather jacket gives it two thumbs up.'],
		],
		draw(context, time) {
			// Arnold’s: a checkered floor, a counter, and a neon sign.
			box(context, '#f4e3c1', 0, 0, 160, 70);
			box(context, '#c0392b', 0, 62, 160, 8);

			for (let column = 0; column < 16; column++) {
				for (let row = 0; row < 5; row++) {
					box(context, (column + row) % 2 === 0 ? '#111111' : '#eeeeee', column * 10, 70 + (row * 10), 10, 10);
				}
			}

			const isNeonOn = Math.floor(time * 3) % 4 !== 0;
			box(context, '#301010', 40, 6, 80, 14);
			context.fillStyle = isNeonOn ? '#ff4fd8' : '#7a2a66';
			context.font = 'bold 10px monospace';
			context.textAlign = 'center';
			context.fillText('ARNOLD’S', 80, 17);

			// The jukebox, with its lights going around.
			box(context, '#8b4513', 136, 34, 18, 30);
			box(context, ['#ff0000', '#ffff00', '#00ff00', '#00ffff'][Math.floor(time * 6) % 4], 139, 37, 12, 8);

			// The band on a small stage: four with glasses, three with guitars, one at the drums.
			box(context, '#6b3e1e', 10, 58, 110, 6);
			const beat = Math.floor(time * 4) % 2;

			for (const [index, x] of [24, 50, 76, 102].entries()) {
				if (index === 3) {
					box(context, '#c0c0c0', x - 8, 48, 16, 10);
					box(context, '#ffffff', x - 6, 46, 12, 3);
				}

				person(context, x, 58, {shirt: ['#2a8f3c', '#c0392b', '#d0d0d0', '#2a3f8f'][index], trousers: '#203050', glasses: true, lean: index === 3 ? 0 : beat * 2 - 1, arms: index === 3 ? beat * 4 : 0, height: 26});

				if (index < 3) {
					guitar(context, x, 58 - 6, ['#e0b030', '#c0392b', '#303030'][index]);
				}
			}

			// The dancers of the 1950s in front, who twist.
			for (const [index, x] of [18, 60, 100, 140].entries()) {
				const twist = Math.sin((time * 6) + index) * 3;
				person(context, x, 116, {hair: ['#000000', '#e8c060', '#7a3010', '#000000'][index], shirt: ['#ff99cc', '#99ccff', '#ffffff', '#ffcc33'][index], trousers: index % 2 === 0 ? '#ff6699' : '#3366cc', lean: twist, arms: Math.round(twist), height: 34});
			}

			// The thumbs up at the end.
			if (time > 17) {
				box(context, '#000000', 60, 72, 40, 46);
				person(context, 80, 118, {hair: '#1a1a1a', shirt: '#2a2a2a', trousers: '#2040a0', arms: -6, height: 44});
				context.fillStyle = '#ffff00';
				context.font = 'bold 12px monospace';
				context.fillText('AYYY!', 80, 66);
			}
		},
		music(sound, start) {
			// A shuffle of the 1950s, of my own: bass and drums.
			const notes = [98, 98, 123, 147, 165, 147, 123, 98];

			for (let bar = 0; bar < 8; bar++) {
				for (const [index, frequency] of notes.entries()) {
					const time = start + (bar * 2) + (index * 0.25);
					tone(sound, frequency * (bar % 4 === 2 ? 4 / 3 : 1), time, 0.2, {type: 'triangle', volume: 0.12});

					if (index % 2 === 0) {
						noise(sound, time, 0.05, {volume: 0.12, frequency: 120});
					} else {
						noise(sound, time, 0.08, {volume: 0.06, frequency: 3000});
					}
				}
			}
		},
	},
	goodtime: {
		title: 'GOODTIME.AVI',
		duration: 15,
		captions: [
			[0, 'GOODTIME.AVI: Edie Brickell sings “Good Times”. It was the other music video of the Windows 95 CD.'],
			[5, 'Everybody remembers the Weezer video. Nobody remembers this one. Poor Edie.'],
			[10, 'Fun fact: Edie Brickell is married to Paul Simon. Paul Simon did not get on the Windows 95 CD.'],
		],
		draw(context, time) {
			// A swirl of colors behind the singer, like a video of the time.
			for (let band = 0; band < 8; band++) {
				box(context, `hsl(${((band * 45) + (time * 40)) % 360} 70% 55%)`, 0, band * 15, 160, 15);
			}

			for (let flower = 0; flower < 6; flower++) {
				const x = ((flower * 31) + (time * 12)) % 170;
				box(context, '#ffffff', x - 3, 20 + ((flower % 3) * 30), 6, 6);
				box(context, '#ffcc00', x - 1, 22 + ((flower % 3) * 30), 2, 2);
			}

			const sway = Math.sin(time * 2) * 3;
			person(context, 80, 118, {hair: '#5a3010', skin: '#f6d2b0', shirt: '#ffffff', trousers: '#5a7ac0', lean: sway, height: 70});
			box(context, '#5a3010', 70 + sway, 44, 4, 26);
			box(context, '#5a3010', 86 + sway, 44, 4, 26);
			guitar(context, 80 + sway, 98, '#c08040');

			if (Math.floor(time * 2) % 2 === 0) {
				box(context, '#000000', 76 + sway, 58, 8, 2);
			}
		},
		music(sound, start) {
			// A gentle strum of my own, on four chords.
			const chords = [[196, 247, 294], [220, 262, 330], [175, 220, 262], [196, 247, 294]];

			for (let bar = 0; bar < 7; bar++) {
				for (let strum = 0; strum < 4; strum++) {
					for (const [index, frequency] of chords[bar % 4].entries()) {
						tone(sound, frequency, start + (bar * 2) + (strum * 0.5) + (index * 0.02), 0.45, {type: 'triangle', volume: 0.05});
					}
				}
			}
		},
	},
	launch: {
		title: 'LAUNCH95.AVI',
		duration: 22,
		captions: [
			[0, 'August 24, 1995: Windows 95 is launched. People line up at midnight to buy an operating system.'],
			[5, 'In New York, the Empire State Building lights up in the colors of the Windows logo.'],
			[10, 'The ads play “Start Me Up” by the Rolling Stones, for the new Start button. Microsoft paid millions for it.'],
			[15, 'On stage in Redmond, Bill Gates, Steve Ballmer, and the team dance. Nobody told them how.'],
			[19, 'Jay Leno hosts the show. Windows 95 sells a million copies in four days.'],
		],
		draw(context, time) {
			if (time < 10) {
				// The night sky of New York, with the Empire State Building, lit in red, yellow, and green.
				box(context, '#05051a', 0, 0, 160, 120);

				for (let star = 0; star < 30; star++) {
					box(context, '#ffffff', (star * 53) % 160, (star * 29) % 60, 1, 1);
				}

				const lights = ['#ff2020', '#ffd020', '#20d040'];
				const shift = Math.floor(time * 2) % 3;
				box(context, '#303040', 60, 50, 40, 70);
				box(context, '#303040', 68, 34, 24, 16);
				box(context, lights[shift], 72, 22, 16, 12);
				box(context, lights[(shift + 1) % 3], 75, 12, 10, 10);
				box(context, lights[(shift + 2) % 3], 78, 4, 4, 8);

				for (let row = 0; row < 12; row++) {
					for (let column = 0; column < 6; column++) {
						if ((row + column + Math.floor(time)) % 5 !== 0) {
							box(context, '#ffef9a', 63 + (column * 6), 54 + (row * 5), 3, 2);
						}
					}
				}

				box(context, '#101020', 0, 96, 50, 24);
				box(context, '#101020', 110, 88, 50, 32);
			} else if (time < 15) {
				// The ad: the Start button, big.
				box(context, '#008080', 0, 0, 160, 120);
				const press = Math.floor(time * 2) % 2 === 0;
				box(context, '#c0c0c0', 30, 44, 100, 32);
				box(context, press ? '#808080' : '#ffffff', 30, 44, 100, 2);
				box(context, press ? '#ffffff' : '#808080', 30, 74, 100, 2);
				context.fillStyle = '#000000';
				context.font = 'bold 18px sans-serif';
				context.textAlign = 'center';
				context.fillText('⊞ Start', 80, 67);
			} else {
				// The stage, with a banner and the team, who dance badly, each to a different beat.
				box(context, '#101040', 0, 0, 160, 120);
				box(context, '#ffffff', 20, 8, 120, 18);
				context.fillStyle = '#000080';
				context.font = 'bold 11px sans-serif';
				context.textAlign = 'center';
				context.fillText('WINDOWS 95', 80, 21);
				box(context, '#4a2a10', 0, 96, 160, 24);

				for (const [index, x] of [24, 52, 80, 108, 136].entries()) {
					const speed = [3.1, 4.7, 2.3, 5.9, 3.8][index];
					const jump = Math.abs(Math.sin(time * speed)) * (index === 2 ? 8 : 4);
					person(context, x, 100 - jump, {hair: index === 2 ? '#7a5a30' : '#2a2a2a', shirt: index === 2 ? '#c03030' : '#404060', trousers: '#202030', glasses: index === 2, lean: Math.sin(time * speed) * 3, arms: Math.round(Math.sin(time * speed * 2) * 5), height: 38});
				}
			}
		},
		music(sound, start) {
			// A crowd, and a rock beat of my own, as the song is not mine.
			for (let beat = 0; beat < 40; beat++) {
				const time = start + (beat * 0.5);
				noise(sound, time, 0.1, {volume: 0.14, frequency: 100});

				if (beat % 2 === 1) {
					noise(sound, time, 0.15, {volume: 0.1, frequency: 1800, q: 0.4});
				}

				if (beat % 4 === 0) {
					for (const frequency of [165, 247, 330]) {
						tone(sound, frequency, time, 0.4, {type: 'sawtooth', volume: 0.03});
					}
				}
			}

			noise(sound, start, 3, {volume: 0.05, frequency: 900, q: 0.2});
		},
	},
	friends: {
		title: 'FRIENDS.AVI',
		duration: 18,
		captions: [
			[0, 'The Windows 95 Video Guide: “the world’s first cyber sitcom”, with Jennifer Aniston and Matthew Perry from Friends.'],
			[5, 'They visit the office of Bill Gates. He is not there. His assistant shows them Windows 95 instead. (Laughter.)'],
			[10, 'They learn the Start button. (Laughter.) They learn the Recycle Bin. (Big laughter.)'],
			[14, 'They learn long file names. (Standing ovation.) It is about an hour long. Could it BE any longer?'],
		],
		draw(context, time) {
			// An office with a window, a desk with a computer, and the famous orange couch.
			box(context, '#e8dcc0', 0, 0, 160, 120);
			box(context, '#9fc4f2', 110, 10, 40, 30);
			box(context, '#ffffff', 129, 10, 2, 30);
			box(context, '#6b4a2a', 0, 96, 160, 24);
			box(context, '#8b5a2b', 96, 70, 56, 6);
			box(context, '#c0c0c0', 108, 48, 26, 22);
			box(context, '#008080', 111, 51, 20, 15);
			box(context, '#e07020', 8, 76, 70, 20);
			box(context, '#c05010', 8, 66, 70, 12);
			const isLaughing = Math.floor(time * 5) % 2 === 0;
			person(context, 28, 98, {hair: '#c89040', skin: '#f6d2b0', shirt: '#2a4a6a', trousers: '#202030', lean: isLaughing ? 2 : 0, height: 34});
			person(context, 58, 98, {hair: '#3a2410', shirt: '#6a6a7a', trousers: '#303040', lean: isLaughing ? -2 : 0, arms: Math.round(Math.sin(time * 3) * 4), height: 36});
			person(context, 124, 104, {hair: '#202020', shirt: '#ffffff', trousers: '#202030', arms: 4, glasses: true, height: 36});

			// The words of the laugh track, as a sign.
			if (Math.floor(time) % 4 === 1) {
				box(context, '#cc0000', 46, 4, 68, 14);
				context.fillStyle = '#ffffff';
				context.font = 'bold 9px monospace';
				context.textAlign = 'center';
				context.fillText('LAUGHTER', 80, 14);
			}
		},
		music(sound, start) {
			// A laugh track: bursts of noise at the times of the sign.
			for (let laugh = 1; laugh < 18; laugh += 4) {
				for (let burst = 0; burst < 6; burst++) {
					noise(sound, start + laugh + (burst * 0.15), 0.14, {volume: 0.08, frequency: 600 + (burst * 90), q: 1.5});
				}
			}
		},
	},
	clean: {
		title: 'CLEAN.AVI',
		duration: 16,
		captions: [
			[0, 'CLEAN.AVI, a bonus from the Windows 98 CD: the Clean Install. Look at your desktop!'],
			[4, 'Everybody dance! The icons, the taskbar, everybody!'],
			[9, 'A clean install means the icons have to dance their way off the hard drive. And back.'],
			[13, 'Your icons are fine. Probably. Windows 98 thanks you for dancing.'],
		],
		draw(context, time) {
			// A disco floor and a mirror ball.
			for (let column = 0; column < 8; column++) {
				for (let row = 0; row < 3; row++) {
					box(context, `hsl(${((column + row) * 50) + (Math.floor(time * 4) * 60)} 80% 50%)`, column * 20, 80 + (row * 14), 20, 14);
				}
			}

			box(context, '#101010', 0, 0, 160, 80);
			box(context, '#c0c0c0', 72, 6, 16, 16);

			for (let ray = 0; ray < 8; ray++) {
				const angle = (ray / 8 * Math.PI * 2) + time;
				box(context, '#ffffff', 80 + (Math.cos(angle) * (30 + (ray * 5))), 14 + (Math.sin(angle) * 20) + 30, 2, 2);
			}

			// The icons of the desktop, dancing on the floor.
			context.font = '14px sans-serif';
			context.textAlign = 'center';

			for (const [index, icon] of ['🗑️', '🖥️', '📁', '🌐', '🧮'].entries()) {
				const jump = Math.abs(Math.sin((time * 5) + index)) * 10;
				context.fillText(icon, 20 + (index * 30), 92 - jump);
			}
		},
		music(sound, start) {
			// A disco beat of my own: four on the floor, with a bass that goes up and down.
			for (let beat = 0; beat < 32; beat++) {
				const time = start + (beat * 0.48);
				noise(sound, time, 0.12, {volume: 0.16, frequency: 90});
				noise(sound, time + 0.24, 0.05, {volume: 0.07, frequency: 6000});
				tone(sound, [110, 220, 131, 262][beat % 4], time, 0.22, {type: 'square', volume: 0.04});
			}
		},
		start(desktop) {
			desktop.dataset.winDancing = '';
		},
		stop(desktop) {
			delete desktop.dataset.winDancing;
		},
	},
};

const drawHappy = (context, happy) => {
	context.fillStyle = 'rgb(0 0 0 / 0.3)';
	context.fillRect(0, 0, 240, 160);

	for (const spark of happy.sparks) {
		context.fillStyle = spark.color;
		context.fillRect(Math.round(spark.x), Math.round(spark.y), 2, 2);
	}

	for (const rocket of happy.rockets) {
		context.fillStyle = '#ffffff';
		context.fillRect(Math.round(rocket.x), Math.round(rocket.y), 2, 3);
	}

	context.fillStyle = '#ffff00';
	context.font = 'bold 14px "Comic Sans MS", sans-serif';
	context.textAlign = 'center';
	context.fillText('Happy New Year 1999 !!', 120, 150);
};

const burst = (happy, x, y) => {
	const color = randomItem(['#ff4040', '#40ff40', '#4080ff', '#ffff40', '#ff40ff', '#40ffff']);

	for (let index = 0; index < 40; index++) {
		const angle = Math.random() * Math.PI * 2;
		const speed = 20 + (Math.random() * 50);
		happy.sparks.push({x, y, dx: Math.cos(angle) * speed, dy: Math.sin(angle) * speed, life: 1.5, color});
	}
};

const scannedFiles = [
	'C:\\AUTOEXEC.BAT', 'C:\\CONFIG.SYS', 'C:\\COMMAND.COM', 'C:\\SECRET.TXT', 'C:\\WINDOWS\\WIN.COM', 'C:\\WINDOWS\\EXPLORER.EXE', 'C:\\WINDOWS\\CALC.EXE', 'C:\\WINDOWS\\SOL.EXE', 'C:\\WINDOWS\\UNICORN.DLL', 'C:\\WINDOWS\\CLOUDS.BMP',
	'C:\\WINDOWS\\SYSTEM\\KERNEL32.DLL', 'C:\\WINDOWS\\SYSTEM\\USER.EXE', 'C:\\WINDOWS\\SYSTEM\\GLITTER.VXD', 'C:\\WINDOWS\\SYSTEM\\WSOCK32.DLL', 'C:\\WINDOWS\\SYSTEM\\Y2KBUG.DLL', 'C:\\WINDOWS\\DESKTOP\\Y2KFIX.EXE', 'C:\\WINDOWS\\FONTS\\COMIC.TTF',
	'C:\\MYDOCU~1\\README.TXT', 'C:\\MYDOCU~1\\HOMEWORK.DOC', 'C:\\MYDOCU~1\\DANCIN~1.AVI', 'C:\\MYDOCU~1\\PRIVATE\\NOTHING.TXT', 'C:\\GAMES\\DOOM2.EXE', 'C:\\GAMES\\KEEN4.EXE', 'C:\\GAMES\\PINBALL.EXE', 'C:\\PROGRA~1\\BONZI\\BONZI.EXE',
];

const antivirusFindings = isInfected => [
	isInfected && {file: 'C:\\WINDOWS\\SYSTEM\\WSOCK32.SKA', name: 'W32.Happy99.Worm', note: 'From the fireworks of Ingrid. It mailed itself to everybody you know.', results: {repair: 'Repaired! WSOCK32.SKA is WSOCK32.DLL again. Now write to your teacher and say sorry.', quarantine: 'Happy99 is in quarantine. It still says Happy New Year from in there.', delete: 'Deleted. The fireworks are gone. Ingrid sends new ones tomorrow.'}},
	{file: 'C:\\WINDOWS\\SYSTEM\\Y2KBUG.DLL', name: 'Y2K.Millennium.Bug', note: 'Wakes up on January 1, 2000.', results: {repair: 'A repair for this bug comes on January 1, 2000. Or 1900.', quarantine: 'The bug does not fit in quarantine. It is too big. It is the whole world.', delete: 'Y2KBUG.DLL is in use by the calendar, the clock, the bank, and the airplanes.'}},
	{file: 'C:\\MYDOCU~1\\PRIVATE\\NOTHING.TXT', name: 'Trojan.LittleSister', note: 'Reads your diary, and tells Mamma.', results: {repair: 'Your little sister cannot be repaired. She is perfect, says Mamma.', quarantine: 'Your little sister is in quarantine (her room). Mamma let her out.', delete: 'Access denied. She is family.'}},
	{file: 'C:\\PROGRA~1\\BONZI\\BONZI.EXE', name: 'Spyware.BonziBUDDY', note: 'A purple gorilla who remembers everything.', bonzi: true, results: {repair: 'BonziBUDDY says he is not broken. He is just friendly.', quarantine: 'BonziBUDDY escaped from quarantine. He has long arms.', delete: 'BonziBUDDY was deleted… and reinstalled himself.'}},
	{file: 'C:\\WINDOWS\\SYSTEM\\GLITTER.VXD', name: 'W95.CIH (Chernobyl)', note: 'Wakes up on April 26 and erases the BIOS. Do not set the date to April!', results: {repair: 'Repaired! Your BIOS is safe. Do not set the date to April anyway.', quarantine: 'CIH is in quarantine until April 27.', delete: 'Deleted. Wait, that was GLITTER.VXD. The unicorn driver! Never mind, it came back.'}},
].filter(Boolean);

const contacts = {
	mamma: {number: '55 12 34 56', lines: ['Mamma: Hallo? Sindre? Is everything OK? Why are you calling me at work?', 'Mamma: Did you do your homework? All of it?', 'Mamma: Turn off the computer and go outside. It is not raining. Much.', 'Mamma: And do NOT eat all the brunost. I counted the slices.']},
	mormor: {number: '55 99 19 99', lines: ['Mormor: Hello, my dear! How nice that you call your old Mormor!', 'Mormor: I am knitting you a sweater. It has a unicorn on it. Or a horse. It is hard to tell.', 'Mormor: Are you eating enough? You sound thin. I am sending waffles.', 'Mormor: Did I tell you about my neighbor’s cat? Let me tell you about my neighbor’s cat…', 'Mormor: …and then the cat came back! Anyway, about the sweater…']},
	pizza: {number: '22 22 55 55', lines: ['Peppes Pizza, hello!', 'Peppes Pizza: A pizza with brunost? …We can do that. We do not want to, but we can.', 'Peppes Pizza: That is 189 kroner. 30 minutes, or it is free. (It is never free.)']},
	ingrid: {number: '55 31 41 59', lines: ['Ingrid: Hello? Is your sister there?', 'Ingrid: You are not your sister.', 'Ingrid: *click*']},
	bill: {number: '1 425 882 8080', lines: ['Microsoft: Thank you for calling Microsoft. Your call is important to us.', 'Microsoft: You are number 1,999 in line. The waiting time is about 6 years.', 'Microsoft: 🎵 (Hold music) 🎵', 'Microsoft: Did you know? You can find answers on our web site, if you can get on the Internet. Which uses this phone line.']},
};

// The tones of the keypad, two frequencies for each key, like a real phone.
const dialTones = {1: [697, 1209], 2: [697, 1336], 3: [697, 1477], 4: [770, 1209], 5: [770, 1336], 6: [770, 1477], 7: [852, 1209], 8: [852, 1336], 9: [852, 1477], '*': [941, 1209], 0: [941, 1336], '#': [941, 1477]};

const playDialTone = (sound, key, start = 0) => {
	for (const frequency of dialTones[key] ?? []) {
		tone(sound, frequency, start, 0.12, {volume: 0.05});
	}
};

export default class extends GeoCitiesElement {
	#desktop;
	#taskbar;
	#bonziContext;
	#bonziWalk;
	#movieContext;
	#movieLoop;
	#happyLoop;
	#isInfected = false;
	#winzipDaysUsed;

	#bonzi = {
		isInstalled: false,
		isGreetingPending: false,
		x: 0,
		y: 0,
		pose: 'idle',
		frame: 0,
		isTalking: false,
		timesSentAway: 0,
		isAway: false,
		song: undefined,
		speech: 0,
		drag: undefined,
		wasDragged: false,
		walkTarget: undefined,
		frameTimer: undefined,
		walkTimer: undefined,
		chatterTimer: undefined,
	};

	#bob = {tries: 0, isChoosingPassword: false, room: 'family', tip: 0};
	#movie = {video: undefined, time: 0, isPlaying: false, caption: -1, isMusicPlaying: false, musicGain: undefined};
	#happy = {rockets: [], sparks: [], hasSpread: false};
	#antivirusRun = 0;
	#winzipRun = 0;
	#call = 0;
	#isMormorOnTheLine = false;
	#scandiskRun = 0;
	#cleanupRun = 0;

	connected() {
		this.#desktop = this.closest('#geocities-desktop');
		this.#taskbar = document.querySelector('#geocities-start-button').parentElement;
		this.#connectBonzi();
		this.#connectBob();
		this.#connectMovie();
		this.#connectHappy();
		this.#connectAntivirus();
		this.#connectWinZip();
		this.#connectDialer();
		this.#connectScanDisk();
		this.#connectCleanup();
	}

	// The element has no box of its own, so it follows the desktop, which is only on the screen part of the time: the things that move stop while it is not, or while the tab is hidden.
	get visibilityTarget() {
		return this.#desktop;
	}

	visibilityChanged(isVisible) {
		this.#animateBonzi();

		// He waits until the visitor sees the desktop, to say hello.
		if (isVisible && this.#bonzi.isGreetingPending) {
			this.#bonzi.isGreetingPending = false;
			this.#showBonzi('Welcome back! I missed you! Did you miss me?');
		}

		if (!isVisible && this.#movie.isPlaying) {
			this.#pauseMovie();
		}
	}

	reducedMotionChanged() {
		this.#stopBonziWalk();
		this.#animateBonzi();
	}

	// BonziBUDDY and ActiveMovie are both in this element, so the page stops neither of them when the other starts, and each stops the other itself.
	musicStopped() {
		this.#stopBonziSong();
		this.#stopMovieMusic();
	}

	// A control that is disabled while something runs gives the focus to its window, so a keyboard does not start over at the top of the page, and gets it back when it is enabled again (`#enable()`).
	focusReplacement(control) {
		return control.closest('[data-desktop-window]') ?? super.focusReplacement(control);
	}

	#enable(control) {
		control.disabled = false;

		if (document.activeElement === control.closest('[data-desktop-window]')) {
			control.focus();
		}
	}

	#windowOf(name) {
		return this.querySelector(`[data-desktop-window="${name}"]`);
	}

	#openWindow(name, opener = document.activeElement) {
		this.#desktop.dispatchEvent(new CustomEvent('geocities-open-window', {detail: {name, opener}}));
	}

	#closeWindow(name) {
		const appWindow = this.#windowOf(name);

		if (!appWindow.hidden) {
			appWindow.querySelector('[data-desktop-close]').click();
		}
	}

	// What each program does when its window opens and closes, by its `hidden` attribute. The element has the windows of all its programs, so it watches each one, as `windowChanged()` is for a program in one window.
	#watchWindow(name, {open, close}) {
		const appWindow = this.#windowOf(name);

		this.observe(new MutationObserver(() => {
			if (appWindow.hidden) {
				close?.();
			} else {
				open?.();
			}
		})).observe(appWindow, {attributes: true, attributeFilter: ['hidden']});
	}

	// BonziBUDDY: a purple gorilla who installs himself, walks around the desktop, tells jokes and facts, sings, and comes back every time he is sent away. Once installed, he is back on every visit, as he was hard to get rid of.
	#connectBonzi() {
		const {bonzi, bonziButton, bonziCanvas, bonziBalloon, bonziVoice, bonziInstall, bonziDecline, bonziSetupStatus, bonziProgress} = this.parts;
		this.#bonziContext = bonziCanvas.getContext('2d');
		this.#bonzi.isInstalled = this.stored('bonzi', false);

		// The balloon makes him taller, so he moves to keep it on the desktop.
		this.observe(new ResizeObserver(() => {
			this.#placeBonzi(this.#bonzi.x, this.#bonzi.y);
		})).observe(bonzi);

		// He walks to a new place now and then, while the balloon is closed, unless the visitor prefers less motion.
		this.#bonziWalk = this.loop(seconds => {
			this.#walkBonziStep(seconds);
		}, {while: () => this.#bonzi.walkTarget !== undefined});

		for (const button of this.querySelectorAll('[data-fun-bonzi-action]')) {
			this.on(button, 'click', () => {
				this.#bonziActions[button.dataset.funBonziAction](button);
			});
		}

		this.on(bonziVoice, 'change', () => {
			if (!bonziVoice.checked) {
				this.#stopBonziVoice();
			}
		});

		// A click opens the balloon with what he can do. A drag moves him, which he likes. A drag ends with a click, which should not open the balloon.
		this.on(bonziButton, 'pointerdown', event => {
			if (event.button !== 0) {
				return;
			}

			this.#bonzi.drag = {startX: event.clientX, startY: event.clientY, x: this.#bonzi.x, y: this.#bonzi.y, isMoving: false};
			bonziButton.setPointerCapture(event.pointerId);
		});

		this.on(bonziButton, 'pointermove', event => {
			const {drag} = this.#bonzi;

			if (!drag) {
				return;
			}

			const dx = event.clientX - drag.startX;
			const dy = event.clientY - drag.startY;

			if (!drag.isMoving && Math.hypot(dx, dy) > 6) {
				drag.isMoving = true;
				this.#stopBonziWalk();
				this.#bonziSay('Wheeee! Put me down! No, wait, do not put me down!', {duration: 1500});
			}

			if (drag.isMoving) {
				this.#placeBonzi(drag.x + dx, drag.y + dy);
			}
		});

		for (const type of ['pointerup', 'pointercancel']) {
			this.on(bonziButton, type, () => {
				this.#bonzi.wasDragged = Boolean(this.#bonzi.drag?.isMoving);

				this.#bonzi.drag = undefined;
			});
		}

		this.on(bonziButton, 'click', () => {
			if (this.#bonzi.wasDragged) {
				this.#bonzi.wasDragged = false;
				return;
			}

			if (bonziButton.getAttribute('aria-expanded') === 'true') {
				this.#closeBonziBalloon();
			} else {
				this.#stopBonziWalk();
				this.#bonziSay(randomItem(['Hi there! What can I do for you, my friend?', 'You clicked me! I knew you would. What shall we do?', 'BonziBUDDY at your service! Pick something!']), {choices: true});
				bonziBalloon.querySelector('button').focus();
			}
		});

		// Escape closes the balloon while the focus is in it, or nowhere, like after a click in Safari, which does not focus buttons.
		this.on(document, 'keydown', event => {
			if (event.key !== 'Escape' || bonziBalloon.hidden || !(bonzi.contains(event.target) || event.target === document.body)) {
				return;
			}

			event.stopPropagation();
			this.#closeBonziBalloon();
			bonziButton.focus();
		});

		// The setup: Install installs him, and No Thanks asks until it is a yes.
		this.on(bonziInstall, 'click', () => {
			this.#installBonzi();
		});

		this.on(bonziDecline, 'click', async event => {
			const answer = await this.ask({title: 'BonziBUDDY Setup', icon: '🦍', text: 'Are you sure? BonziBUDDY is FREE! He tells jokes! He sings! Do you really not want a friend?', buttons: ['I want a friend', 'No friends'], opener: event.currentTarget});

			if (answer === 'I want a friend') {
				this.#installBonzi();
			} else if (answer === 'No friends') {
				this.say('OK. BonziBUDDY will wait right here. He is very patient.', bonziSetupStatus);
			}
		});

		this.#watchWindow('bonzi', {
			open: () => {
				bonziProgress.style.width = '0';
				bonziSetupStatus.textContent = '';

				// Once he is installed, his icon only calls him.
				if (this.#bonzi.isInstalled) {
					this.#closeWindow('bonzi');
					this.#bonzi.timesSentAway = 0;
					this.#showBonzi(bonzi.hidden ? 'You called? I am here! I am always here!' : 'I am right here, silly!', {choices: true});
					bonziButton.focus();
				}
			},
		});

		// Add/Remove Programs of `geocities-windows.js` tells him when the visitor tries to remove him.
		this.on(this.#desktop, 'geocities-win-bonzi', () => {
			this.#reinstallBonzi();
		});

		this.#drawBonzi();
		this.#bonzi.isGreetingPending = this.#bonzi.isInstalled;
	}

	#drawBonzi() {
		drawBonzi(this.#bonziContext, this.#bonzi);
	}

	#placeBonzi(x, y) {
		const {bonzi} = this.parts;
		const maximumX = Math.max(this.#desktop.clientWidth - bonzi.offsetWidth, 0);
		const maximumY = Math.max(this.#desktop.clientHeight - this.#taskbar.offsetHeight - bonzi.offsetHeight, 0);
		this.#bonzi.x = clamp(x, 0, maximumX);
		this.#bonzi.y = clamp(y, 0, maximumY);
		bonzi.style.translate = `${this.#bonzi.x}px ${this.#bonzi.y}px`;
	}

	// The animation of the gorilla runs only while he talks, walks, or waves, and the desktop is on the screen. With reduced motion, he stands still.
	#animateBonzi() {
		this.#bonzi.frameTimer?.cancel();
		this.#bonzi.frameTimer = undefined;
		this.#drawBonzi();

		if (this.parts.bonzi.hidden || !this.isVisible || this.reducedMotion) {
			return;
		}

		this.#bonzi.frameTimer = this.interval(this.#bonzi.pose === 'idle' && !this.#bonzi.isTalking ? 250 : 160, () => {
			this.#bonzi.frame++;
			this.#drawBonzi();
		});
	}

	#setBonziPose(pose) {
		this.#bonzi.pose = pose;
		this.#animateBonzi();
	}

	// Says something in the balloon, and out loud with the voice of the browser if the visitor wants that, low and slow like the voice of Microsoft Agent. With `choices`, the balloon also shows what he can do.
	async #bonziSay(message, {choices = false, duration} = {}) {
		const {bonzi, bonziBalloon, bonziButton, bonziText, bonziVoice} = this.parts;
		const speech = ++this.#bonzi.speech;

		// The choices hide while he talks, so a choice that has the focus gives it to him.
		if (!choices && bonziBalloon.contains(document.activeElement)) {
			bonziButton.focus();
		}

		bonziBalloon.hidden = false;
		bonzi.dataset.state = 'talking';
		bonziButton.setAttribute('aria-expanded', String(choices));

		for (const element of bonziBalloon.querySelectorAll('[data-fun-bonzi-action], label')) {
			element.hidden = !choices;
		}

		this.say(message, bonziText);
		this.#bonzi.isTalking = true;
		this.#animateBonzi();

		if (bonziVoice.checked && 'speechSynthesis' in globalThis) {
			speechSynthesis.cancel();
			const utterance = new SpeechSynthesisUtterance(message.replace(/[^\p{L}\p{N}\s.,!?']/gu, ''));
			utterance.pitch = 0.6;
			utterance.rate = 0.95;
			speechSynthesis.speak(utterance);
		}

		await this.wait(clamp(message.length * 60, 1500, 6000));

		if (speech === this.#bonzi.speech) {
			this.#bonzi.isTalking = false;
			this.#animateBonzi();
		}

		if (duration) {
			await this.wait(duration);

			if (speech === this.#bonzi.speech && !choices) {
				bonziBalloon.hidden = true;
				delete bonzi.dataset.state;
			}
		}
	}

	#stopBonziVoice() {
		if ('speechSynthesis' in globalThis) {
			speechSynthesis.cancel();
		}
	}

	#closeBonziBalloon() {
		const {bonzi, bonziBalloon, bonziButton} = this.parts;
		this.#bonzi.speech++;
		bonziBalloon.hidden = true;
		delete bonzi.dataset.state;
		this.#stopBonziVoice();
		bonziButton.setAttribute('aria-expanded', 'false');
		this.#bonzi.isTalking = false;
		this.#stopBonziSong();
		this.#animateBonzi();
	}

	#showBonzi(message, {choices = false} = {}) {
		const {bonzi} = this.parts;
		const wasHidden = bonzi.hidden;
		bonzi.hidden = false;
		this.#bonzi.isAway = false;

		if (wasHidden) {
			this.#placeBonzi(randomInteger(0, this.#desktop.clientWidth), randomInteger(0, this.#desktop.clientHeight));
		}

		this.#setBonziPose('wave');
		this.#bonziSay(message, {choices, duration: choices ? undefined : 4000});

		this.timeout(2000, () => {
			if (this.#bonzi.pose === 'wave') {
				this.#setBonziPose('idle');
			}
		});

		this.#scheduleBonziWalk();
		this.#scheduleBonziChatter();
	}

	#stopBonziSong() {
		const {song} = this.#bonzi;

		if (song) {
			song.isStopped = true;

			// The notes of a line are scheduled ahead, so the song has its own volume, which goes to zero, like pulling the plug.
			song.gain.gain.setValueAtTime(0, song.gain.context.currentTime);
			this.#bonzi.song = undefined;
			this.music(false);
		}
	}

	async #singBonzi() {
		this.#stopBonziSong();
		this.#stopMovieMusic();
		const sound = this.sound();

		if (!sound) {
			return;
		}

		const {context, output} = sound;
		const song = {isStopped: false, gain: context.createGain()};
		song.gain.connect(output);
		this.#bonzi.song = song;
		this.music(true);
		this.#setBonziPose('sing');
		const beat = 0.22;

		for (const {line, notes} of daisyBell) {
			let time = 0;

			for (const [frequency, beats] of notes) {
				tone({context, output: song.gain}, frequency, time, (beats * beat) - 0.03, {type: 'triangle', volume: 0.1});
				time += beats * beat;
			}

			this.#bonziSay(line);
			await this.wait(time * 1000);

			if (song.isStopped) {
				return;
			}
		}

		this.#stopBonziSong();
		this.#setBonziPose('idle');
		this.#bonziSay('Thank you! Thank you! I am here all week. And all next week. And forever.', {choices: true});
	}

	#bonziActions = {
		joke: () => {
			this.#bonziSay(randomItem(bonziJokes), {choices: true});
		},
		fact: () => {
			this.#bonziSay(randomItem(bonziFacts), {choices: true});
		},
		sing: () => {
			this.#singBonzi();
		},
		search: button => {
			this.#bonziSay('Let me search the Web for you! I also set your home page to www.bonzi.com. You are welcome!', {choices: true});
			this.#openWindow('ie', button);
		},
		leave: async button => {
			const answer = await this.ask({title: 'BonziBUDDY', icon: '🦍', text: 'Are you sure you want me to go away? I am your BUDDY!', buttons: ['Yes', 'No'], opener: button});

			if (answer !== 'Yes') {
				this.#bonziSay('Yay! I knew you liked me!', {choices: true});
				return;
			}

			const timesSentAway = ++this.#bonzi.timesSentAway;
			this.#closeBonziBalloon();
			this.#stopBonziWalk();
			this.parts.bonzi.hidden = true;
			this.#bonzi.isAway = true;
			this.#bonzi.walkTimer?.cancel();
			this.#bonzi.chatterTimer?.cancel();
			this.#desktop.querySelector('[data-desktop-open="bonzi"]')?.focus();

			// He comes back twice, and stays away the third time, until the next visit. Only the last time he was sent away counts.
			if (timesSentAway < 3) {
				await this.wait(15_000);

				if (this.#bonzi.isAway && timesSentAway === this.#bonzi.timesSentAway) {
					this.#showBonzi(this.#bonzi.timesSentAway === 1 ? 'I’m back! Did you miss me? I missed you!' : 'Surprise! I am back again! I will always come back!');
				}
			} else {
				this.toast('BonziBUDDY went away. Until you come back to this page. He will remember.');
			}
		},
	};

	#stopBonziWalk() {
		this.#bonzi.walkTarget = undefined;
		this.#bonziWalk.stop();

		if (this.#bonzi.pose === 'walk') {
			this.#setBonziPose('idle');
		}
	}

	#walkBonzi() {
		const {bonzi, bonziBalloon} = this.parts;

		if (bonzi.hidden) {
			return;
		}

		if (!bonziBalloon.hidden || !this.isVisible || this.reducedMotion || this.#bonzi.drag) {
			this.#scheduleBonziWalk();
			return;
		}

		this.#bonzi.walkTarget = {
			x: randomInteger(0, Math.max(this.#desktop.clientWidth - bonzi.offsetWidth, 0)),
			y: randomInteger(0, Math.max(this.#desktop.clientHeight - this.#taskbar.offsetHeight - bonzi.offsetHeight, 0)),
		};
		this.#setBonziPose('walk');
		this.#bonziWalk.start();
	}

	#walkBonziStep(seconds) {
		const {bonzi, bonziBalloon} = this.parts;
		const target = this.#bonzi.walkTarget;
		const dx = target.x - this.#bonzi.x;
		const dy = target.y - this.#bonzi.y;
		const distance = Math.hypot(dx, dy);
		const move = 70 * seconds;

		if (distance <= move || bonzi.hidden || !bonziBalloon.hidden) {
			if (distance <= move) {
				this.#placeBonzi(target.x, target.y);
			}

			this.#stopBonziWalk();
			this.#scheduleBonziWalk();
			return;
		}

		this.#placeBonzi(this.#bonzi.x + (dx / distance * move), this.#bonzi.y + (dy / distance * move));
	}

	#scheduleBonziWalk() {
		this.#bonzi.walkTimer?.cancel();

		this.#bonzi.walkTimer = this.timeout(randomInteger(7000, 14_000), () => {
			this.#walkBonzi();
		});
	}

	// Now and then, he says something by himself, like the real one.
	#scheduleBonziChatter() {
		this.#bonzi.chatterTimer?.cancel();

		this.#bonzi.chatterTimer = this.timeout(randomInteger(40_000, 70_000), () => {
			if (this.parts.bonzi.hidden) {
				return;
			}

			if (this.parts.bonziBalloon.hidden && this.isVisible) {
				this.#bonziSay(randomItem(bonziRemarks), {duration: 4000});
			}

			this.#scheduleBonziChatter();
		});
	}

	async #installBonzi() {
		const {bonziInstall, bonziSetupStatus, bonziProgress} = this.parts;

		if (bonziInstall.disabled) {
			return;
		}

		bonziInstall.disabled = true;
		const steps = ['Installing BonziBUDDY…', 'Installing the BonziBUDDY Toolbar…', 'Setting your home page to www.bonzi.com…', 'Reading your e-mail (just kidding)…', 'Done! Say hi to your new best friend!'];

		for (const [index, step] of steps.entries()) {
			this.say(step, bonziSetupStatus);
			bonziProgress.style.width = `${(index + 1) / steps.length * 100}%`;
			await this.wait(700);
		}

		this.#enable(bonziInstall);
		this.#bonzi.isInstalled = true;
		this.store('bonzi', true);
		this.#closeWindow('bonzi');
		this.#showBonzi('Hi! I’m BonziBUDDY, your new best friend! Click me any time. I will be right here. Always.');
	}

	#reinstallBonzi() {
		this.#bonzi.isInstalled = true;
		this.store('bonzi', true);
		this.#bonzi.timesSentAway = 0;
		this.#showBonzi('Did you just try to remove me? That is OK. I forgive you. I reinstalled myself, so we can be together!');
	}

	// Microsoft Bob: a house instead of a desktop, with Rover the dog, who explains everything. The password is impossible to guess, and after three tries, Bob lets the visitor pick a new one, like the real Bob.
	#connectBob() {
		const {bobLogin, bobPassword, bobLoginStatus, bobHouse, bobRoverText} = this.parts;

		this.on(bobLogin, 'submit', event => {
			event.preventDefault();

			if (this.#bob.isChoosingPassword) {
				bobLogin.hidden = true;
				bobHouse.hidden = false;
				this.#showBobRoom('family', true);
				this.say(`Your new password is “${bobPassword.value || '(nothing)'}”. I will remember it for you. I tell everybody. Woof! Welcome home! Click anything in the room.`, bobRoverText);
				return;
			}

			this.#bob.tries++;
			bobPassword.value = '';

			if (this.#bob.tries < 3) {
				this.say(this.#bob.tries === 1 ? 'Rover: Woof! That is not the password. Try again!' : 'Rover: Still not it. One more try, and then… something happens.', bobLoginStatus);
				bobPassword.focus();
			} else {
				this.#bob.isChoosingPassword = true;
				bobLogin.querySelector('label').textContent = 'New password:';
				bobLogin.querySelector('button').textContent = 'Use This Password';
				this.say('Rover: It looks like you forgot your password. No problem! Just pick a new one. Bob trusts you. Bob trusts everybody.', bobLoginStatus);
				bobPassword.focus();
			}
		});

		this.#watchWindow('bob', {
			open: () => {
				if (bobHouse.hidden) {
					bobPassword.focus();
				} else {
					this.#showBobRoom(this.#bob.room);
				}
			},
		});
	}

	#showBobRoom(name, focusFirst = false) {
		const {bobRoomName, bobRoom, bobRoverText, bobItemTemplate} = this.parts;
		this.#bob.room = name;
		const room = bobRooms[name];
		bobRoomName.textContent = room.name;
		bobRoom.setAttribute('aria-label', `Things in the ${room.name}`);

		bobRoom.replaceChildren(...room.items.map(item => {
			const element = bobItemTemplate.content.firstElementChild.cloneNode(true);
			const [picture, label] = element.querySelectorAll('span');
			picture.textContent = item.icon;
			label.textContent = item.name;

			element.querySelector('button').addEventListener('click', event => {
				if (item.room) {
					this.#showBobRoom(item.room, true);
					this.say(`Woof! This is the ${bobRooms[item.room].name}. ${roverTips[this.#bob.tip++ % roverTips.length]}`, bobRoverText);
					return;
				}

				this.say(typeof item.say === 'function' ? item.say() : item.say, bobRoverText);

				if (item.program) {
					this.#openWindow(item.program, event.currentTarget);
				}
			});

			return element;
		}));

		if (focusFirst) {
			bobRoom.querySelector('button').focus();
		}
	}

	// The Windows 95 CD-ROM plays its videos in ActiveMovie: each video is drawn on a canvas of 160 × 120 pixels, with captions instead of the songs, as the songs would cost too much. With reduced motion, each caption shows a still picture.
	#connectMovie() {
		const {movieCanvas, moviePlay, movieStop, movieSound, cdromStatus} = this.parts;
		this.#movieContext = movieCanvas.getContext('2d');

		this.#movieLoop = this.loop(seconds => {
			const movie = this.#movie;
			movie.time += seconds;

			if (movie.time >= movie.video.duration) {
				movie.time = movie.video.duration;
				this.#showMovieFrame();
				this.#pauseMovie();
				movie.time = 0;
				return;
			}

			this.#showMovieFrame();
		}, {while: () => this.#movie.isPlaying});

		for (const button of this.querySelectorAll('[data-fun-video]')) {
			this.on(button, 'click', () => {
				this.#openVideo(button.dataset.funVideo, button);
				this.say(`Playing ${videos[button.dataset.funVideo].title}.`, cdromStatus);
			});
		}

		this.on(moviePlay, 'click', () => {
			if (this.#movie.isPlaying) {
				this.#pauseMovie();
			} else {
				this.#playMovie();
			}
		});

		this.on(movieStop, 'click', () => {
			this.#pauseMovie();
			this.#movie.time = 0;
			this.#movie.caption = -1;
			this.#showMovieFrame();
		});

		this.on(movieSound, 'change', () => {
			if (movieSound.checked && this.#movie.isPlaying) {
				this.#playMovieMusic();
			} else if (!movieSound.checked) {
				this.#stopMovieMusic();
			}
		});

		this.#watchWindow('movie', {
			close: () => {
				this.#pauseMovie();
			},
		});

		// The CD-ROM shows its Autorun screen when it opens, like when the CD goes in.
		this.#watchWindow('cdrom', {
			open: () => {
				cdromStatus.textContent = '7 object(s). Disk free space: 0 bytes. It is a CD.';
			},
		});
	}

	#showMovieFrame() {
		const {movieProgress, movieCaption} = this.parts;
		const movie = this.#movie;
		const {video} = movie;
		const captionIndex = video.captions.findLastIndex(([at]) => at <= movie.time);

		// With reduced motion, the picture changes only with the captions, like a slide show.
		video.draw(this.#movieContext, this.reducedMotion ? video.captions[Math.max(captionIndex, 0)][0] + 1 : Math.floor(movie.time * 15) / 15);
		movieProgress.style.width = `${movie.time / video.duration * 100}%`;

		if (captionIndex !== movie.caption) {
			movie.caption = captionIndex;
			movieCaption.textContent = video.captions[captionIndex][1];
		}
	}

	#stopMovieMusic() {
		const movie = this.#movie;

		if (movie.isMusicPlaying) {
			movie.isMusicPlaying = false;
			this.music(false);

			// The scheduled notes cannot be taken back, so the sound of ActiveMovie is turned down, like pulling the plug.
			movie.musicGain?.gain.setValueAtTime(0, movie.musicGain.context.currentTime);
		}
	}

	// The music of a video goes through its own volume, so Stop can silence the notes that are already scheduled.
	#playMovieMusic() {
		const movie = this.#movie;

		if (!this.parts.movieSound.checked || !movie.video.music) {
			return;
		}

		this.#stopBonziSong();
		const sound = this.sound();

		if (!sound) {
			return;
		}

		const {context, output} = sound;
		movie.musicGain = context.createGain();
		movie.musicGain.connect(output);
		movie.video.music({context, output: movie.musicGain}, -movie.time);
		movie.isMusicPlaying = true;
		this.music(true);
	}

	#pauseMovie() {
		const {moviePlay} = this.parts;
		this.#movie.isPlaying = false;
		this.#movieLoop.stop();
		this.#movie.video?.stop?.(this.#desktop);
		this.#stopMovieMusic();
		moviePlay.textContent = '▶';
		moviePlay.setAttribute('aria-label', 'Play');
	}

	#playMovie() {
		const {moviePlay} = this.parts;
		const movie = this.#movie;

		if (movie.isPlaying || !this.isVisible) {
			return;
		}

		movie.isPlaying = true;
		moviePlay.textContent = '⏸';
		moviePlay.setAttribute('aria-label', 'Pause');

		if (!this.reducedMotion) {
			movie.video.start?.(this.#desktop);
		}

		this.#playMovieMusic();
		this.#movieLoop.start();
	}

	#openVideo(name, opener) {
		const movie = this.#movie;
		this.#pauseMovie();
		movie.video = videos[name];
		movie.time = 0;
		movie.caption = -1;
		this.#windowOf('movie').querySelector('h3').textContent = `${movie.video.title} - ActiveMovie Control`;
		this.#openWindow('movie', opener);
		this.#showMovieFrame();
		this.#playMovie();
		this.parts.moviePlay.focus();
	}

	// Happy99: fireworks with “Happy New Year 1999 !!”, which mail themselves to everybody in the address book while the visitor watches. Then the antivirus program finds it.
	#connectHappy() {
		const {happyCanvas, happyStatus} = this.parts;
		const happyWindow = this.#windowOf('happy');
		const context = happyCanvas.getContext('2d');
		const happy = this.#happy;

		this.#happyLoop = this.loop(seconds => {
			if (Math.random() < seconds * 1.5) {
				happy.rockets.push({x: randomInteger(30, 210), y: 160, dy: -randomInteger(90, 130), fuse: 0.7 + Math.random()});
			}

			for (const rocket of happy.rockets) {
				rocket.y += rocket.dy * seconds;
				rocket.fuse -= seconds;

				if (rocket.fuse <= 0) {
					burst(happy, rocket.x, rocket.y);
				}
			}

			happy.rockets = happy.rockets.filter(rocket => rocket.fuse > 0);

			for (const spark of happy.sparks) {
				spark.x += spark.dx * seconds;
				spark.y += spark.dy * seconds;
				spark.dy += 40 * seconds;
				spark.life -= seconds;
			}

			happy.sparks = happy.sparks.filter(spark => spark.life > 0);
			drawHappy(context, happy);
		}, {while: () => !happyWindow.hidden && !this.reducedMotion});

		this.#watchWindow('happy', {
			open: async () => {
				context.fillStyle = '#000000';
				context.fillRect(0, 0, 240, 160);

				// With reduced motion, the fireworks are one still picture.
				if (this.reducedMotion) {
					for (const [x, y] of [[60, 50], [120, 35], [180, 60]]) {
						burst(happy, x, y);
					}

					for (const spark of happy.sparks) {
						spark.x += spark.dx * 0.6;
						spark.y += spark.dy * 0.6;
					}

					drawHappy(context, happy);
					happy.sparks = [];
				}

				this.#happyLoop.start();
				this.say('Ooh! Fireworks from Ingrid! How nice of her.', happyStatus);
				await this.wait(5000);

				if (!happy.hasSpread && !happyWindow.hidden) {
					happy.hasSpread = true;
					this.#isInfected = true;
					this.say('Happy99 sent itself to everybody in your address book: Mamma, Pappa, Mormor, Ingrid, and my teacher. Oops.', happyStatus);
					this.toast('📧 Sent: Happy99.exe to 5 people. Your teacher says thank you?');
				}
			},
		});
	}

	// Nordmann AntiVirus 99 scans the files of the hard drive one by one, and finds the viruses of 1999, like Happy99 if the visitor ran it, and a few that only live on my computer.
	#connectAntivirus() {
		const {antivirusFile, antivirusProgress, antivirusResults, antivirusTemplate, antivirusStatus, antivirusScan, antivirusUpdate} = this.parts;

		this.on(antivirusScan, 'click', async () => {
			const run = ++this.#antivirusRun;
			antivirusScan.disabled = true;
			antivirusResults.replaceChildren();
			this.say('Scanning drive C:…', antivirusStatus);

			for (const [index, file] of scannedFiles.entries()) {
				antivirusFile.textContent = `Scanning: ${file}`;
				antivirusProgress.style.width = `${(index + 1) / scannedFiles.length * 100}%`;
				await this.wait(randomInteger(80, 220));

				if (run !== this.#antivirusRun) {
					return;
				}
			}

			this.#enable(antivirusScan);
			const findings = antivirusFindings(this.#isInfected);
			antivirusFile.textContent = `Scanned ${scannedFiles.length} files. Found ${findings.length} viruses.`;

			for (const finding of findings) {
				const item = antivirusTemplate.content.firstElementChild.cloneNode(true);
				item.querySelector('p').textContent = `⚠️ ${finding.name} in ${finding.file}. ${finding.note}`;

				for (const button of item.querySelectorAll('[data-fun-antivirus-action]')) {
					button.addEventListener('click', () => {
						const result = finding.results[button.dataset.funAntivirusAction];
						item.querySelector('p').textContent = `✔️ ${finding.name}: ${result}`;
						item.querySelector('div').remove();
						this.say(result, antivirusStatus);
						antivirusScan.focus();

						if (finding.bonzi) {
							this.#reinstallBonzi();
						}
					});
				}

				antivirusResults.append(item);
			}

			this.say(`Scan done. ${findings.length} viruses found. Pick what to do with each.`, antivirusStatus);
			antivirusResults.querySelector('button')?.focus();
		});

		this.on(antivirusUpdate, 'click', async () => {
			const run = ++this.#antivirusRun;
			antivirusUpdate.disabled = true;

			for (const step of ['LiveUpdate: Connecting at 28,800 bps…', 'LiveUpdate: Downloading 1,999 new virus definitions… 0.1%', 'LiveUpdate: 0.2%. Time left: 9 hours, 12 minutes.']) {
				this.say(step, antivirusStatus);
				await this.wait(1500);

				if (run !== this.#antivirusRun) {
					return;
				}
			}

			this.#enable(antivirusUpdate);
			this.say('LiveUpdate failed: Mamma picked up the phone to call Mormor. Try again after dinner.', antivirusStatus);
		});

		this.#watchWindow('antivirus', {
			close: () => {
				this.#antivirusRun++;
				antivirusScan.disabled = false;
				antivirusUpdate.disabled = false;
			},
		});
	}

	// WinZip, with the nag screen of the unregistered version, where the buttons trade places, so the visitor has to read them, and GAMES.ZIP, which never fits on the hard drive.
	#connectWinZip() {
		const {winzipNag, winzipArchive, winzipButtons, winzipDays, winzipStatus, winzipExtract, winzipProgress} = this.parts;
		this.#winzipDaysUsed = this.stored('winzip-days', 1999);

		this.#watchWindow('winzip', {
			open: () => {
				this.#winzipDaysUsed++;
				this.store('winzip-days', this.#winzipDaysUsed);
				winzipDays.textContent = `Thank you for trying WinZip! You have been using WinZip for ${this.#winzipDaysUsed.toLocaleString('en-US')} days. The evaluation period is 21 days. Please register.`;
				winzipNag.hidden = false;
				winzipArchive.hidden = true;
				winzipStatus.textContent = '';
				winzipProgress.style.width = '0';
				winzipExtract.disabled = false;

				// The buttons trade places every time, so I Agree is never where it was.
				const buttons = [...winzipButtons.children];

				for (let index = buttons.length - 1; index > 0; index--) {
					const other = randomInteger(0, index);
					[buttons[index], buttons[other]] = [buttons[other], buttons[index]];
				}

				winzipButtons.append(...buttons);
				buttons[0].focus();
			},
			close: () => {
				this.#winzipRun++;
			},
		});

		const choices = {
			agree: () => {
				winzipNag.hidden = true;
				winzipArchive.hidden = false;
				this.say('GAMES.ZIP: 6 files, 4.4 MB. Click Extract.', winzipStatus);
				winzipExtract.focus();
			},
			quit: () => {
				this.#closeWindow('winzip');
			},
			order: button => {
				this.ask({title: 'Ordering Information', icon: 'ℹ️', text: 'To register WinZip, send 29 US dollars in an envelope to Connecticut, USA. That is 230 kroner, or 46 waffles. Or keep clicking I Agree for 1,999 more days, like everybody.', opener: button});
			},
		};

		for (const button of winzipButtons.children) {
			this.on(button, 'click', () => {
				choices[button.dataset.funWinzipChoice](button);
			});
		}

		this.on(winzipExtract, 'click', async () => {
			const run = ++this.#winzipRun;
			winzipExtract.disabled = true;

			for (const [index, file] of ['KEEN4.EXE', 'SKIFREE.EXE', 'LEMMINGS.EXE', 'DOOM1.WAD'].entries()) {
				this.say(`Extracting ${file}…`, winzipStatus);
				winzipProgress.style.width = `${(index + 1) * 22}%`;
				await this.wait(700);

				if (run !== this.#winzipRun) {
					return;
				}
			}

			this.#enable(winzipExtract);
			const answer = await this.ask({title: 'WinZip', icon: '❌', text: 'There is not enough space on drive C: to extract DOOM1.WAD. You need 4 MB more.\n\nDo you want to delete some GIFs to make room?', buttons: ['Yes', 'No'], opener: winzipExtract});
			this.say(answer === 'Yes' ? 'Sindre will never forgive you. And WinZip still did not finish. Nice try.' : 'Good choice. The GIFs stay. DOOM will have to wait for a bigger hard drive.', winzipStatus);
		});
	}

	// Phone Dialer calls people with the tones of the keypad, and writes down what they say. It needs the phone line, which the modem may have.
	#connectDialer() {
		const {dialerForm, dialerNumber, dialerHangUp, dialerSound} = this.parts;

		for (const button of this.querySelectorAll('[data-fun-dialer-key]')) {
			this.on(button, 'click', () => {
				dialerNumber.value = `${dialerNumber.value}${button.dataset.funDialerKey}`.slice(0, 16);

				if (dialerSound.checked) {
					playDialTone(this.sound(), button.dataset.funDialerKey);
				}
			});
		}

		for (const button of this.querySelectorAll('[data-fun-dialer-speed]')) {
			this.on(button, 'click', () => {
				const contact = button.dataset.funDialerSpeed;
				dialerNumber.value = contacts[contact].number;
				this.#dial(contacts[contact].number, contact);
			});
		}

		this.on(dialerForm, 'submit', event => {
			event.preventDefault();
			this.#dial(dialerNumber.value.trim());
		});

		this.on(dialerHangUp, 'click', () => {
			// Nobody hangs up on Mormor the first time. You can only try.
			if (this.#isMormorOnTheLine) {
				this.#isMormorOnTheLine = false;
				this.#logLine('You tried to hang up. Mormor did not notice, and kept talking. Press Hang Up again, and say goodbye properly this time.');
				return;
			}

			this.#hangUp('You hung up.');
			dialerNumber.focus();
		});

		this.#watchWindow('dialer', {
			close: () => {
				this.#hangUp();
			},
		});
	}

	#logLine(text) {
		const {dialerLog} = this.parts;
		dialerLog.append(`${text}\n`);
		dialerLog.scrollTop = dialerLog.scrollHeight;
	}

	#hangUp(message) {
		this.#call++;
		this.#isMormorOnTheLine = false;
		this.parts.dialerHangUp.disabled = true;

		if (message) {
			this.#logLine(message);
		}
	}

	async #dial(number, contact) {
		const {dialerLog, dialerHangUp, dialerSound} = this.parts;
		const thisCall = ++this.#call;
		dialerLog.replaceChildren();
		this.#enable(dialerHangUp);
		const digits = number.replaceAll(/[^\d*#]/g, '');

		if (dialerSound.checked) {
			const sound = this.sound();

			for (const [index, digit] of [...digits].entries()) {
				playDialTone(sound, digit, index * 0.15);
			}
		}

		this.#logLine(`Dialing ${number}…`);
		await this.wait(400 + (digits.length * 150));

		if (thisCall !== this.#call) {
			return;
		}

		// Emergency numbers are not for jokes.
		if (['110', '112', '113'].includes(digits)) {
			this.#hangUp('Phone Dialer hung up: emergency numbers are for emergencies, not for jokes.');
			return;
		}

		// The modem has the phone line while Dial-Up Networking is connected.
		if (!document.querySelector('#geocities-win-online').hidden) {
			if (dialerSound.checked) {
				for (let beep = 0; beep < 4; beep++) {
					tone(this.sound(), 425, beep, 0.5, {volume: 0.05});
				}
			}

			this.#hangUp('Beep, beep, beep. The line is busy, because you are on the Internet with it! Mamma has been trying to call home for two hours.');
			return;
		}

		const person = contacts[contact] ?? Object.values(contacts).find(entry => entry.number.replaceAll(' ', '') === digits);

		for (let ring = 0; ring < 2; ring++) {
			this.#logLine('Ring… ring…');

			if (dialerSound.checked) {
				tone(this.sound(), 425, 0, 1, {volume: 0.04});
			}

			await this.wait(1300);

			if (thisCall !== this.#call) {
				return;
			}
		}

		if (!person) {
			if (dialerSound.checked) {
				for (const [index, frequency] of [913.8, 1370.6, 1776.7].entries()) {
					tone(this.sound(), frequency, index * 0.33, 0.3, {volume: 0.05});
				}
			}

			this.#hangUp(digits.length === 0 ? 'You did not type a number. Phone Dialer called nobody, and nobody answered.' : 'Dee-doo-deee. The number you have dialed is not in use. Please check the number and dial again.');
			return;
		}

		this.#isMormorOnTheLine = person === contacts.mormor;

		for (const line of person.lines) {
			this.#logLine(line);
			await this.wait(clamp(line.length * 55, 1500, 4000));

			if (thisCall !== this.#call) {
				return;
			}
		}

		if (this.#isMormorOnTheLine) {
			this.#logLine('Mormor: …are you still there? Hello? I will call you back. I have your number. I always have your number.');
		}

		this.#hangUp('The call ended.');
	}

	// ScanDisk checks the clusters of the hard drive one by one. The thorough test finds bad ones, and the lost clusters, which it saves as files that nobody ever opens.
	#connectScanDisk() {
		const {scandiskStart} = this.parts;

		this.on(scandiskStart, 'click', () => {
			this.#runScanDisk();
		});

		this.#watchWindow('scandisk', {
			close: () => {
				this.#scandiskRun++;
				scandiskStart.disabled = false;
			},
		});
	}

	async #runScanDisk() {
		const {scandiskStatus, scandiskStart, scandiskFix} = this.parts;
		const clusters = [...this.querySelectorAll('[data-fun-scandisk-cluster]')];
		const run = ++this.#scandiskRun;
		const isThorough = this.querySelector('[data-fun-scandisk-test]:checked').value === 'thorough';
		scandiskStart.disabled = true;

		for (const cluster of clusters) {
			delete cluster.dataset.state;
			cluster.textContent = '';
		}

		for (const step of ['Checking the media descriptor…', 'Checking the file allocation tables…', 'Checking folders…', 'Checking files…']) {
			this.say(step, scandiskStatus);
			await this.wait(500);

			if (run !== this.#scandiskRun) {
				return;
			}
		}

		let badCount = 0;

		if (isThorough) {
			const bad = new Set(Array.from({length: 4}, () => randomInteger(10, clusters.length - 1)));

			for (const [index, cluster] of clusters.entries()) {
				cluster.dataset.state = 'reading';
				await this.wait(this.reducedMotion ? 10 : 35);

				if (run !== this.#scandiskRun) {
					return;
				}

				if (bad.has(index)) {
					cluster.dataset.state = 'bad';
					cluster.textContent = 'B';
					badCount++;
				} else {
					cluster.dataset.state = 'checked';
				}

				if (index % 20 === 0) {
					scandiskStatus.textContent = `Checking surface: cluster ${(index * 1999).toLocaleString('en-US')} of ${(clusters.length * 1999).toLocaleString('en-US')}…`;
				}
			}
		}

		this.#enable(scandiskStart);
		const fixText = scandiskFix.checked ? 'and moved the data to good clusters. The data was GIFs.' : 'and left them there, as you asked.';
		this.say(isThorough ? `ScanDisk found ${badCount} bad sectors ${fixText}` : 'ScanDisk did not find any errors on this drive. Try the Thorough test. It takes longer, which makes it better.', scandiskStatus);

		const answer = await this.ask({title: 'ScanDisk', icon: '🩺', text: 'ScanDisk found 1,999 lost clusters in 7 chains.\n\nDo you want to save them as files?', buttons: ['Yes', 'No'], opener: scandiskStart});

		if (answer === 'Yes') {
			this.say('Saved as FILE0000.CHK to FILE1998.CHK in C:\\. Nobody has ever opened a .CHK file. Nobody ever will.', scandiskStatus);
		} else if (answer === 'No') {
			this.say('The lost clusters are free now. Run free, little clusters!', scandiskStatus);
		}
	}

	// Disk Cleanup asks three times before it deletes the GIFs, and then it does not, and frees 0 bytes either way.
	#connectCleanup() {
		const {cleanupStart, cleanupStatus, cleanupProgress} = this.parts;
		const gifsBox = this.querySelector('[data-fun-cleanup-item="gifs"]');

		this.on(gifsBox, 'change', async () => {
			if (!gifsBox.checked) {
				return;
			}

			for (const question of ['Are you sure you want to delete “GIFs I might need someday”?', 'Are you REALLY sure? There are 1,999 GIFs. Some of them sparkle.', 'Are you REALLY, REALLY sure? Sindre made this list himself. The dancing baby is in it.']) {
				// The order of the buttons is the same, so it is easy to say Yes three times.
				const answer = await this.ask({title: 'Disk Cleanup', icon: '❓', text: question, buttons: ['Yes', 'No'], opener: gifsBox});

				if (answer !== 'Yes') {
					gifsBox.checked = false;
					this.say('Phew. The GIFs are safe.', cleanupStatus);
					return;
				}
			}

			gifsBox.checked = false;
			await this.ask({title: 'Disk Cleanup', icon: '❌', text: 'Access denied. Sindre said no.', opener: gifsBox});
			this.say('The GIFs are safe. The GIFs are always safe.', cleanupStatus);
		});

		this.on(cleanupStart, 'click', async () => {
			const run = ++this.#cleanupRun;
			cleanupStart.disabled = true;

			for (const [index, step] of ['Cleaning up Temporary Internet Files…', 'Emptying the Recycle Bin…', 'Deleting temporary files…'].entries()) {
				this.say(step, cleanupStatus);
				cleanupProgress.style.width = `${(index + 1) / 3 * 100}%`;
				await this.wait(900);

				if (run !== this.#cleanupRun) {
					return;
				}
			}

			this.#enable(cleanupStart);
			this.say('Disk Cleanup freed 0 bytes. Your computer feels lighter anyway.', cleanupStatus);
		});

		this.#watchWindow('cleanup', {
			open: () => {
				cleanupProgress.style.width = '0';
				cleanupStatus.textContent = '';
			},
			close: () => {
				this.#cleanupRun++;
				cleanupStart.disabled = false;
			},
		});
	}
}
