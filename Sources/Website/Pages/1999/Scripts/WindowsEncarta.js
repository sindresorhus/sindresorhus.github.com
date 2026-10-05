// Microsoft Encarta Encyclopedia Deluxe 99 on the desktop of the 1999 page: the disc that loads, the Pinpointer, the articles with their media, the timeline, and MindMaze, the trivia castle. Encarta came on two discs, so some places ask for the other disc. Nothing makes a sound until the visitor turns on the sound or presses something that plays.

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

const shuffled = items => {
	const copy = [...items];

	for (let index = copy.length - 1; index > 0; index--) {
		const other = Math.floor(Math.random() * (index + 1));
		[copy[index], copy[other]] = [copy[other], copy[index]];
	}

	return copy;
};

const fromTemplate = template => template.content.firstElementChild.cloneNode(true);

// A tone and a noise, on the audio context of the node that they connect to.
const playTone = (output, frequency, start, duration, {type = 'triangle', volume = 0.1, slide, vibrato} = {}) => {
	const {context} = output;
	const oscillator = context.createOscillator();
	const gain = context.createGain();
	const time = context.currentTime + start;
	oscillator.type = type;
	oscillator.frequency.setValueAtTime(frequency, time);

	if (slide) {
		oscillator.frequency.exponentialRampToValueAtTime(slide, time + duration);
	}

	if (vibrato) {
		const wobble = context.createOscillator();
		const depth = context.createGain();
		wobble.frequency.value = 6;
		depth.gain.value = vibrato;
		wobble.connect(depth).connect(oscillator.frequency);
		wobble.start(time);
		wobble.stop(time + duration + 0.05);
	}

	gain.gain.setValueAtTime(0.0001, time);
	gain.gain.exponentialRampToValueAtTime(volume, time + 0.01);
	gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
	oscillator.connect(gain).connect(output);
	oscillator.start(time);
	oscillator.stop(time + duration + 0.05);
	return oscillator;
};

let noiseBuffer;

const playNoise = (output, start, duration, {frequency = 1500, quality = 1, volume = 0.08} = {}) => {
	const {context} = output;

	if (!noiseBuffer) {
		noiseBuffer = context.createBuffer(1, context.sampleRate, context.sampleRate);
		const data = noiseBuffer.getChannelData(0);

		for (let index = 0; index < data.length; index++) {
			data[index] = (Math.random() * 2) - 1;
		}
	}

	const source = context.createBufferSource();
	const filter = context.createBiquadFilter();
	const gain = context.createGain();
	const time = context.currentTime + start;
	source.buffer = noiseBuffer;
	source.loop = true;
	filter.type = 'bandpass';
	filter.frequency.value = frequency;
	filter.Q.value = quality;
	gain.gain.setValueAtTime(0.0001, time);
	gain.gain.exponentialRampToValueAtTime(volume, time + 0.02);
	gain.gain.setValueAtTime(volume, time + Math.max(duration - 0.05, 0.03));
	gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
	source.connect(filter).connect(gain).connect(output);
	source.start(time);
	source.stop(time + duration + 0.05);
	return source;
};

// The speech of the pronunciations and of the people, in a Norwegian voice when the browser has one.
const canSpeak = 'speechSynthesis' in globalThis;

const speak = (text, {lang = 'en-US', pitch = 1, rate = 0.9} = {}) => {
	if (!canSpeak) {
		return false;
	}

	speechSynthesis.cancel();
	const utterance = new SpeechSynthesisUtterance(text);
	utterance.lang = lang;
	utterance.pitch = pitch;
	utterance.rate = rate;
	// Norwegian voices are called `nb` or `no`.
	const languages = lang.startsWith('nb') ? ['nb', 'no'] : [lang.slice(0, 2)];
	const voice = speechSynthesis.getVoices().find(voice => languages.some(language => voice.lang.startsWith(language)));

	if (voice) {
		utterance.voice = voice;
	}

	speechSynthesis.speak(utterance);
	return true;
};

// The notes of the tunes, by their name, like `C#4`.
const noteFrequency = name => {
	const [, letter, accidental, octave] = /^([A-G])([#b]?)(\d)$/.exec(name);
	const semitone = {C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11}[letter] + (accidental === '#' ? 1 : (accidental === 'b' ? -1 : 0));
	return 440 * (2 ** ((((Number(octave) + 1) * 12) + semitone - 69) / 12));
};

// The heart of a waffle, with the tip down, around its middle.
const heartPath = (context, size) => {
	context.beginPath();
	context.moveTo(0, -0.25 * size);
	context.bezierCurveTo(0, -0.55 * size, -0.5 * size, -0.55 * size, -0.5 * size, -0.2 * size);
	context.bezierCurveTo(-0.5 * size, 0.1 * size, -0.1 * size, 0.3 * size, 0, 0.5 * size);
	context.bezierCurveTo(0.1 * size, 0.3 * size, 0.5 * size, 0.1 * size, 0.5 * size, -0.2 * size);
	context.bezierCurveTo(0.5 * size, -0.55 * size, 0, -0.55 * size, 0, -0.25 * size);
	context.closePath();
};

const textBox = (context, text, x, y, {font = 'bold 12px Arial, sans-serif', color = '#ffffff', background = 'rgba(0, 0, 0, 0.6)', align = 'center'} = {}) => {
	context.font = font;
	const width = context.measureText(text).width + 10;
	const left = align === 'center' ? x - (width / 2) : x;
	context.fillStyle = background;
	context.fillRect(left, y - 12, width, 17);
	context.fillStyle = color;
	context.textAlign = 'left';
	context.textBaseline = 'alphabetic';
	context.fillText(text, left + 5, y);
};

// The tunes of the articles: the first lines of the national anthem of Norway, by Rikard Nordraak, and In the Hall of the Mountain King, by Edvard Grieg of Bergen, which gets faster and faster.
const anthem = {
	beat: 0.56,
	notes: [
		['G4', 1.5], ['F4', 0.5], ['E4', 1], ['D4', 1],
		['C4', 1], ['D4', 1], ['E4', 2],
		['G4', 1.5], ['A4', 0.5], ['G4', 1], ['F4', 1],
		['E4', 3], [undefined, 1],
		['A4', 1.5], ['G4', 0.5], ['F4', 1], ['E4', 1],
		['D4', 1], ['E4', 1], ['F4', 1], ['G4', 1],
		['G4', 1.5], ['A4', 0.5], ['G4', 1], ['F4', 1],
		['E4', 3], [undefined, 1],
	],
	lyrics: ['Ja, vi elsker dette landet,', 'som det stiger frem,', 'furet, værbitt over vannet,', 'med de tusen hjem.'],
};

const mountainKingPhrase = [
	['B3', 1], ['C#4', 1], ['D4', 1], ['E4', 1], ['F#4', 1], ['D4', 1], ['F#4', 2],
	['F4', 1], ['C#4', 1], ['F4', 2], ['E4', 1], ['C4', 1], ['E4', 2],
	['B3', 1], ['C#4', 1], ['D4', 1], ['E4', 1], ['F#4', 1], ['D4', 1], ['F#4', 1], ['B4', 1],
	['A4', 1], ['F#4', 1], ['D4', 1], ['F#4', 1], ['A4', 4],
];

// The computers on the Internet, by the counts of the time.
const hostCounts = [[1969, 4], [1971, 23], [1977, 111], [1981, 213], [1984, 1024], [1986, 5089], [1987, 28_174], [1989, 159_000], [1990, 313_000], [1991, 617_000], [1992, 1_136_000], [1993, 2_056_000], [1994, 3_864_000], [1995, 6_642_000], [1996, 12_881_000], [1997, 19_540_000], [1998, 36_739_000], [1999, 56_218_000]];

const modemSpeeds = [['14.4K', 14_400], ['28.8K', 28_800], ['33.6K', 33_600], ['56K', 56_000], ['ISDN 128K', 128_000]];

const furbish = [
	['kah may-may u-nye', 'me love you'],
	['a-tay', 'hungry'],
	['wah!', 'yeah!'],
	['e-day', 'good'],
	['koh-koh', 'again'],
	['noh-lah', 'dance'],
	['wee-tee kah', 'sing for me'],
	['dah a-loh', 'big light, the sun'],
	['boo', 'no'],
];

function notesLength(notes, beat) {
	let total = 0;

	for (const [, length] of notes) {
		total += length * beat;
	}

	return total;
}

const dialNumber = '55314000';
const dtmf = {1: [697, 1209], 2: [697, 1336], 3: [697, 1477], 4: [770, 1209], 5: [770, 1336], 6: [770, 1477], 7: [852, 1209], 8: [852, 1336], 9: [852, 1477], 0: [941, 1336]};

// The timeline, one event at a time.
const events = [
	['About 15 billion years ago', '💥', 'The big bang. Everything starts, all at once.'],
	['4.6 billion years ago', '🌍', 'The Earth forms out of dust and rocks.'],
	['65 million years ago', '🦖', 'A giant rock hits the Earth, and the dinosaurs die out.'],
	['About 9000 BC', '🧊', 'The ice melts away from Norway, and the first people follow the reindeer.'],
	['About 2560 BC', '🔺', 'The Great Pyramid of Giza is built.'],
	['About 400 BC', '🦄', 'The Greek doctor Ctesias writes about a wild ass of India with one horn.', ['unicorn']],
	['793', '⚔️', 'Vikings raid the monastery of Lindisfarne in England, and the Viking Age begins.'],
	['About 872', '👑', 'Harald Fairhair wins the battle of Hafrsfjord and unites Norway.', ['norway']],
	['About 1000', '⛵', 'Leif Erikson sails to America, almost 500 years before Columbus.'],
	['About 1070', '🏘️', 'King Olav Kyrre founds Bergen. It starts to rain.', ['bergen']],
	['1349', '☠️', 'The Black Death comes to Norway on a ship to Bergen.', ['bergen']],
	['About 1450', '📜', 'Johannes Gutenberg prints books with movable type.'],
	['1492', '🌎', 'Columbus sails to America. Leif Erikson was there first.'],
	['1671', '🪑', 'The king of Denmark and Norway gets a throne of “unicorn horns”. They are narwhal tusks.', ['unicorn']],
	['1814', '📜', 'Norway gets its constitution on May 17, the national day.', ['norway']],
	['1843', '🎻', 'The composer Edvard Grieg is born in Bergen.', ['bergen']],
	['1863', '🧀', 'Anne Hov makes the first brown cheese in Gudbrandsdalen.', ['waffle']],
	['1869', '🧇', 'Cornelius Swartwout patents the waffle iron.', ['waffle']],
	['1899', '📎', 'The Norwegian Johan Vaaler patents a paper clip.', ['norway']],
	['1905', '🇳🇴', 'Norway leaves its union with Sweden and gets its own king.', ['norway']],
	['1911', '🐧', 'Roald Amundsen is the first at the South Pole.'],
	['1969', '🌐', 'The ARPANET sends its first message, “LO”, and Norway finds oil.', ['internet']],
	['1973', '📡', 'Norway connects to the ARPANET, as one of the first countries outside the USA.', ['internet']],
	['1981', '💾', 'IBM sells its Personal Computer.'],
	['1991', '🕸️', 'Tim Berners-Lee puts the first website on the World Wide Web.', ['internet']],
	['1994', '⛷️', 'The Winter Olympics in Lillehammer.', ['norway']],
	['1998', '🦉', 'Furby comes out, and 56k modems get the V.90 standard.', ['furby', 'modem']],
	['1999', '💿', 'You are here. Sindre reads Encarta 99, and it rains in Bergen.', ['bergen']],
	['2000', '❓', 'The year 2000. Will the computers still work?', ['y2k']],
];

// MindMaze: a castle of 4 × 4 rooms. The directions go around: 0 is north, 1 east, 2 south, and 3 west.
const size = 4;
const startCell = (size - 1) * size;
const throneCell = size - 1;
const directionNames = ['north', 'east', 'south', 'west'];
const sides = {left: -1, front: 0, right: 1, back: 2};
const ranks = [[0, 'Peasant'], [200, 'Stable Hand'], [500, 'Page'], [800, 'Squire']];

const neighbor = (cell, direction) => {
	const x = cell % size;
	const y = Math.floor(cell / size);
	const [nextX, nextY] = [[x, y - 1], [x + 1, y], [x, y + 1], [x - 1, y]][direction];
	return nextX < 0 || nextY < 0 || nextX >= size || nextY >= size ? undefined : (nextY * size) + nextX;
};

const passageKey = (first, second) => `${Math.min(first, second)}-${Math.max(first, second)}`;

const roomThemes = [
	{name: 'Armory', decoration: ['🛡️', '⚔️'], stone: [120, 120, 130]},
	{name: 'Library', decoration: ['📚', '📜'], stone: [130, 110, 90]},
	{name: 'Chapel', decoration: ['🕯️', '🕯️'], stone: [150, 145, 135]},
	{name: 'Dungeon', decoration: ['⛓️', '💀'], stone: [80, 85, 90]},
	{name: 'Portrait Gallery', decoration: ['🖼️', '🖼️'], stone: [140, 120, 110]},
	{name: 'Treasury', decoration: ['💰', '💎'], stone: [140, 130, 90]},
	{name: 'Banquet Hall', decoration: ['🍗', '🍷'], stone: [140, 100, 80]},
	{name: 'Wizard’s Study', decoration: ['🔮', '🌙'], stone: [100, 90, 140]},
	{name: 'Guard Room', decoration: ['🪖', '🏹'], stone: [110, 115, 110]},
	{name: 'Music Room', decoration: ['🎻', '🎺'], stone: [130, 110, 130]},
	{name: 'Stables', decoration: ['🐴', '🌾'], stone: [130, 115, 85]},
	{name: 'Tower Stairs', decoration: ['🪜', '🦇'], stone: [105, 105, 115]},
	{name: 'Wine Cellar', decoration: ['🍷', '🛢️'], stone: [100, 80, 80]},
	{name: 'Computer Room', decoration: ['💻', '💾'], stone: [120, 130, 140]},
];

const kitchenTheme = {name: 'Kitchen', decoration: ['🧇', '🍳'], stone: [150, 120, 90]};
const gateTheme = {name: 'Gatehouse', decoration: ['🏰', '🗝️'], stone: [125, 125, 125]};
const throneTheme = {name: 'Throne Room', decoration: ['👑', '🦁'], stone: [150, 120, 70]};

// The questions of the doors, with the right answer first, and the article where the answer is.
const questions = [
	['What is the capital of Norway?', ['Oslo', 'Bergen (it rains too much to be the capital)', 'Stockholm', 'Legoland'], 'norway'],
	['What do Norwegians put on their waffles?', ['Brown cheese (brunost)', 'Ketchup', 'Cod liver oil', 'Pickled herring and gravy'], 'waffle'],
	['How many hearts does a Norwegian waffle have?', ['Five', 'Three', 'Twelve', 'None, it is square'], 'waffle'],
	['Which city of Norway lies between seven mountains?', ['Bergen', 'Oslo', 'Trondheim', 'Las Vegas'], 'bergen'],
	['Which composer was born in Bergen in 1843?', ['Edvard Grieg', 'Mozart', 'The Spice Girls', 'Mormor'], 'bergen'],
	['Who founded Bergen, about 1070?', ['King Olav Kyrre', 'Bill Gates', 'A wet viking', 'Clippy'], 'bergen'],
	['What year might an old computer think it is on January 1, 2000?', ['1900', '2000', '3000', 'Tuesday'], 'y2k'],
	['Is the year 2000 a leap year?', ['Yes, as it can be divided by 400', 'No, never on a Saturday', 'Only in Sweden', 'Only if Bill Gates says so'], 'y2k'],
	['What does Y2K stand for?', ['Year 2000', 'Yes 2 Kittens', 'Your 2 Kroner', 'Why 2 Keyboards'], 'y2k'],
	['What was the first message on the ARPANET in 1969?', ['“LO” (then it crashed)', '“Hello, World!”', '“You’ve got mail!”', '“Mamma, get off the phone!”'], 'internet'],
	['What is the @ sign called in Norwegian?', ['Krøllalfa (curly alpha)', 'Snabel-a (that is Swedish)', 'The snail', 'Bergen'], 'internet'],
	['In 1973, which country was one of the first outside the USA on the ARPANET?', ['Norway', 'Atlantis', 'The Moon', 'Legoland'], 'internet'],
	['What does WWW stand for?', ['World Wide Web', 'Wet Windy Weather (that is Bergen)', 'Waffles With Whipped cream', 'Wait, Wait, Wait'], 'internet'],
	['What does a modem do?', ['Turns data into sound for the phone line', 'Bakes waffles', 'Scares the cat', 'Calls Mormor'], 'modem'],
	['What happens when Mamma picks up the phone while you are online?', ['The connection is lost', 'You get a free upgrade to 56k', 'The modem says hello to her', 'Nothing at all'], 'modem'],
	['What is the fastest dial-up modem of 1999?', ['56k', '1000k turbo', '300 baud', 'A carrier pigeon'], 'modem'],
	['What language does a new Furby speak?', ['Furbish', 'Nynorsk', 'Klingon', 'Latin'], 'furby'],
	['Which agency banned Furbies from its offices in 1999?', ['The NSA', 'NASA', 'The Norwegian post office', 'The tooth fairy'], 'furby'],
	['How do you make a Furby quiet?', ['Take out the batteries', 'Press the off switch', 'Ask it nicely', 'Play it Grieg'], 'furby'],
	['What is the national animal of Scotland?', ['The unicorn', 'The haggis', 'The Loch Ness Monster', 'The bagpipe'], 'unicorn'],
	['What were most “unicorn horns” really?', ['Narwhal tusks', 'Carrots', 'Ice cream cones', 'Rocky the pet rock'], 'unicorn'],
	['What did the Norwegian Johan Vaaler patent in 1899?', ['A paper clip', 'The Internet', 'Clippy', 'Rain'], 'norway'],
	['On which day do Norwegians celebrate their national day?', ['May 17', 'December 24', 'July 4', 'Every Friday'], 'norway'],
	['Where were the Winter Olympics of 1994?', ['Lillehammer', 'Bergen', 'Hawaii', 'Kardemomme by'], 'norway'],
	['Who became King of Norway in 1991?', ['Harald V', 'Olav the Waffle', 'Elvis', 'Harald Fairhair (a bit too old)'], 'norway'],
	['Who walked on the Moon first, in 1969?', ['Neil Armstrong', 'Buzz Lightyear', 'Roald Amundsen', 'A Furby']],
	['Who reached the South Pole first, in 1911?', ['Roald Amundsen', 'Santa Claus', 'Neil Armstrong', 'A penguin with a flag']],
	['Which movie won 11 Oscars in 1998?', ['Titanic', 'The Matrix (it came out in 1999)', 'Toy Story', 'Rain Man of Bergen']],
	['What is the Star Wars movie of 1999?', ['The Phantom Menace', 'The Waffle Strikes Back', 'Revenge of the Furby', 'Jar Jar Forever']],
	['Which Norwegian band sang “Take On Me”?', ['A-ha', 'Aqua (they are Danish)', 'ABBA (they are Swedish)', 'The Brunost Boys']],
	['Which new money started in 11 countries of Europe on January 1, 1999?', ['The euro', 'The krone', 'The waffle dollar', 'Trading cards']],
	['What is the name of the paper clip that helps in Office 97?', ['Clippit (Clippy)', 'BonziBUDDY', 'Rocky', 'Glitter']],
	['Which toy learns to talk when you play with it?', ['Furby', 'Tamagotchi', 'Brunost', 'Clippy']],
	['Who sang “…Baby One More Time” in 1999?', ['Britney Spears', 'Mormor', 'The Teletubbies', 'Bergen Philharmonic']],
	['Which company made Windows 98?', ['Microsoft', 'Apple', 'A ski factory in Lillehammer', 'Mormor’s knitting club']],
].map(([text, answers, article]) => ({text, answers, article}));

const riddles = [
	['What has keys, but cannot open a single lock?', ['A keyboard', 'Mamma', 'This castle', 'A waffle']],
	['What gets wetter the more it dries?', ['A towel', 'Bergen', 'A modem', 'The ghost']],
	['What has an eye, but cannot see?', ['A needle', 'A Furby without batteries', 'The jester', 'Windows 98']],
	['What can you catch, but not throw?', ['A cold (in Bergen, often)', 'A ball', 'A Furby', 'The bus']],
	['What goes up, but never comes down?', ['Your age', 'The rain in Bergen', 'The modem speed', 'The phone bill']],
].map(([text, answers]) => ({text, answers}));

const kingQuestions = [
	['What is the best home page on the whole World Wide Web?', ['Sindre’s home page, of course', 'Yahoo!', 'A page about a cat', 'The page that says “Under construction”']],
	['What must every knight of Bergen carry?', ['An umbrella', 'Sunglasses', 'A sun hat', 'A snow plow']],
	['What does the King eat on Sundays?', ['Waffles with brunost', 'Snails', 'The jester’s hat', 'Encarta Disc 2']],
].map(([text, answers]) => ({text, answers}));

const characters = {
	jester: {name: 'The Jester', icon: '🃏', lines: [
		'Why did the computer go to the doctor? It had a virus! Happy99, to be exact.',
		'Knock knock. Who’s there? Y2K. Y2K who? Y2K-n’t the computers count past 99?',
		'What is a knight’s favorite fish? A swordfish!',
		'Why don’t ghosts surf the Web? They only find dead links!',
		'What did the modem say to Mamma? EEEE-KRRRR-SHHHH. She did not laugh either.',
		'Why did the waffle go to the castle? It wanted to be a Sir-up!',
		'How many programmers does it take to change a light bulb? None. That is a hardware problem.',
	], wrong: [
		'Wrong! Even Lillesøster knew that one.',
		'Ha! The door laughs at you. So do I.',
		'Wrong! Look it up in Encarta. Oh, wait. You are IN Encarta.',
		'That answer is so wrong, it rains in Bergen.',
	]},
	knight: {name: 'The Knight', icon: '🛡️', lines: [
		'Halt! None shall pass without answering my riddle!',
		'I have guarded this room since Encarta 95. It is very boring.',
		'My armor rusts. I should never have visited Bergen.',
	]},
	ghost: {name: 'The Ghost', icon: '👻', lines: [
		'Boooo! Did I scare you? Here, take my map of the castle.',
		'I walk through walls. You have to answer questions. Life is unfair. Well, afterlife.',
		'I lost my head in 1349. Have you seen it?',
	]},
	mormor: {name: 'Mormor', icon: '👵', lines: [
		'Uff, you look thin. Have a waffle with brunost, kjære deg.',
		'Spis, spis! You cannot be a knight on an empty stomach.',
		'Have you remembered your woolen sweater? It is cold in this castle.',
	]},
	king: {name: 'The King', icon: '👑', lines: [
		'Who dares to enter my throne room? Answer my question, and I shall make you a knight!',
		'A knight must be wise. Answer my question.',
	]},
};

// The stored record can be changed by hand, so only whole numbers count.
const storedCount = value => (Number.isSafeInteger(value) && value > 0 ? value : 0);

// The room, in the perspective of the time: the back wall in the middle, and the side walls, the ceiling, and the floor around it.
const back = {left: 150, right: 330, top: 70, bottom: 215};

const sideWallTop = x => back.top * x / back.left;
const sideWallBottom = x => 300 - ((300 - back.bottom) * x / back.left);

// The door on a side wall, from the outer edge of the wall toward the back, mirrored for the right wall.
const sideDoor = isRight => {
	const outer = 40;
	const inner = 108;
	const point = (x, fraction) => {
		const bottom = sideWallBottom(x);
		const top = sideWallTop(x);
		return [isRight ? 480 - x : x, bottom - ((bottom - top) * fraction)];
	};

	return {
		outerTop: point(outer, 0.6),
		innerTop: point(inner, 0.6),
		innerBottom: point(inner, 0),
		outerBottom: point(outer, 0),
	};
};

const backDoor = {left: 207, right: 273, top: 118, bottom: back.bottom};

const shade = ([red, green, blue], factor) => `rgb(${Math.round(red * factor)}, ${Math.round(green * factor)}, ${Math.round(blue * factor)})`;

const drawDoorShape = (context, corners, arch) => {
	const [outerTop, innerTop, innerBottom, outerBottom] = corners;
	context.beginPath();
	context.moveTo(...outerBottom);
	context.lineTo(...outerTop);
	context.quadraticCurveTo((outerTop[0] + innerTop[0]) / 2, Math.min(outerTop[1], innerTop[1]) - arch, ...innerTop);
	context.lineTo(...innerBottom);
	context.closePath();
};

const drawDoor = (context, corners, passage, openness, arch) => {
	const [outerTop, innerTop, innerBottom, outerBottom] = corners;

	// The stone frame around the door.
	context.lineWidth = 6;
	context.strokeStyle = '#3a3a40';
	drawDoorShape(context, corners, arch);
	context.stroke();

	// The doorway is dark, with a little light from the next room.
	const light = context.createLinearGradient(0, Math.min(outerTop[1], innerTop[1]), 0, Math.max(outerBottom[1], innerBottom[1]));
	light.addColorStop(0, '#050505');
	light.addColorStop(1, '#3a2a14');
	context.fillStyle = light;
	drawDoorShape(context, corners, arch);
	context.fill();

	if (openness >= 1) {
		return;
	}

	// The door swings in, around its hinge on the outer side.
	const swing = (from, to) => [from[0] + ((to[0] - from[0]) * (1 - openness)), from[1] + ((to[1] - from[1]) * (1 - openness))];
	const panel = [outerTop, swing(outerTop, innerTop), swing(outerBottom, innerBottom), outerBottom];
	context.save();
	drawDoorShape(context, corners, arch);
	context.clip();
	context.beginPath();
	context.moveTo(...panel[0]);
	context.lineTo(panel[1][0], panel[1][1] - arch - 4);
	context.lineTo(...panel[2]);
	context.lineTo(...panel[3]);
	context.lineTo(panel[0][0], panel[0][1] - arch - 4);
	context.closePath();
	context.fillStyle = passage.state === 'locked' ? '#4a2a14' : '#7a4a20';
	context.fill();

	// The planks and the iron bands.
	context.strokeStyle = 'rgba(0, 0, 0, 0.45)';
	context.lineWidth = 1;

	for (let plank = 1; plank < 5; plank++) {
		const top = [panel[0][0] + ((panel[1][0] - panel[0][0]) * plank / 5), panel[0][1] + ((panel[1][1] - panel[0][1]) * plank / 5) - arch];
		const bottom = [panel[3][0] + ((panel[2][0] - panel[3][0]) * plank / 5), panel[3][1] + ((panel[2][1] - panel[3][1]) * plank / 5)];
		context.beginPath();
		context.moveTo(...top);
		context.lineTo(...bottom);
		context.stroke();
	}

	context.strokeStyle = '#2a2a2a';
	context.lineWidth = 3;

	for (const fraction of [0.3, 0.75]) {
		const left = [panel[0][0] + ((panel[3][0] - panel[0][0]) * fraction), panel[0][1] + ((panel[3][1] - panel[0][1]) * fraction)];
		const right = [panel[1][0] + ((panel[2][0] - panel[1][0]) * fraction), panel[1][1] + ((panel[2][1] - panel[1][1]) * fraction)];
		context.beginPath();
		context.moveTo(...left);
		context.lineTo(...right);
		context.stroke();
	}

	context.restore();

	if (openness === 0) {
		const centerX = (outerTop[0] + innerTop[0] + outerBottom[0] + innerBottom[0]) / 4;
		const centerY = (outerTop[1] + innerTop[1] + outerBottom[1] + innerBottom[1]) / 4;
		context.font = passage.state === 'locked' ? '22px sans-serif' : 'bold 24px "Times New Roman", serif';
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.fillStyle = '#ffd700';
		context.strokeStyle = '#000000';
		context.lineWidth = 3;

		if (passage.state === 'locked') {
			context.fillText('🔒', centerX, centerY);
		} else {
			context.strokeText('?', centerX, centerY);
			context.fillText('?', centerX, centerY);
		}
	}
};

export default class extends GeoCitiesElement {
	#goButtons;
	#eraButtons;
	#answerButtons;
	#doorButtons;
	#mediaContext;
	#mazeContext;
	#mazeMapContext;

	connected() {
		this.#goButtons = [...this.querySelectorAll('[data-encarta-go]')];
		this.#eraButtons = [...this.querySelectorAll('[data-encarta-era]')];
		this.#answerButtons = [...this.querySelectorAll('[data-encarta-answer]')];
		this.#doorButtons = [...this.querySelectorAll('[data-encarta-door]')];
		this.#mediaContext = this.parts.media.getContext('2d');
		this.#mazeContext = this.parts.mazeScreen.getContext('2d');
		this.#mazeMapContext = this.parts.mazeMap.getContext('2d');

		// The picture of an article and the room of MindMaze move only while they are open and on the screen, and the visitor does not prefer less motion.
		this.#mediaLoop = this.loop((seconds, time) => {
			this.#drawMedia(time);
		}, {while: () => this.#isMediaMoving()});

		this.#mazeLoop = this.loop((seconds, time) => {
			this.#drawMaze(time);
		}, {while: () => this.#isMazeMoving()});

		this.on(this.parts.sound, 'click', () => {
			const isOn = !this.#isSoundOn();
			this.parts.sound.setAttribute('aria-pressed', String(isOn));
			this.parts.sound.textContent = isOn ? '🔊 Sound' : '🔈 Sound';

			if (isOn) {
				this.#sounds.click();
			}
		});

		this.#views = {splash: this.parts.splash, home: this.parts.home, article: this.parts.article, timeline: this.parts.timeline, maze: this.parts.maze};

		for (const button of this.#goButtons) {
			this.on(button, 'click', () => {
				this.#sounds.click();
				this.#go(button.dataset.encartaGo);
			});
		}

		this.on(this.parts.back, 'click', async () => {
			const place = this.#history.at(-1);

			if (!place) {
				return;
			}

			this.#sounds.click();

			if (await this.#go(place, {isBack: true})) {
				this.#history.pop();
				this.parts.back.disabled = this.#history.length === 0;
			}
		});

		this.on(this.parts.search, 'input', () => {
			this.#renderResults();
		});

		this.on(this.parts.category, 'change', () => {
			this.#renderResults();
		});

		this.on(this.parts.search, 'keydown', event => {
			const first = this.parts.results.querySelector('button');

			if (event.key === 'Enter' && first) {
				event.preventDefault();
				first.click();
			} else if (event.key === 'ArrowDown' && first) {
				event.preventDefault();
				first.focus();
			}
		});

		this.on(this.parts.results, 'click', event => {
			const button = event.target.closest('button');

			if (button) {
				this.#sounds.page();
				this.#go(`article:${button.dataset.article}`);
			}
		});

		this.on(this.parts.results, 'keydown', event => {
			const buttons = [...this.parts.results.querySelectorAll('button')];
			const index = buttons.indexOf(event.target);
			const step = {ArrowUp: -1, ArrowDown: 1}[event.key];

			if (!step || index === -1) {
				return;
			}

			event.preventDefault();

			if (index + step < 0) {
				this.parts.search.focus();
			} else {
				buttons[Math.min(index + step, buttons.length - 1)].focus();
			}
		});

		this.on(this.parts.random, 'click', () => {
			const others = this.#articleIds.filter(id => `article:${id}` !== this.#currentPlace);
			this.#sounds.page();
			this.#go(`article:${randomItem(others)}`);
		});

		this.on(this.parts.homeFactNext, 'click', () => {
			this.#sounds.click();
			this.#showHomeFact();
		});

		this.on(this.parts.homeFactRead, 'click', () => {
			this.#sounds.page();
			this.#go(`article:${this.#homeFactArticle}`);
		});

		this.on(this.parts.say, 'click', () => {
			const article = this.#articles[this.#media.id];

			if (speak(article.speech.text, {lang: article.speech.lang, rate: 0.8})) {
				this.say(`🗣️ ${article.pronunciation}`);
			} else {
				this.say(`This computer has no speech. Say it yourself: ${article.pronunciation}.`);
			}
		});

		this.on(this.parts.articleFactNext, 'click', () => {
			const article = this.#articles[this.#media.id];
			this.#factIndex = (this.#factIndex + 1) % article.facts.length;
			this.parts.articleFact.textContent = article.facts[this.#factIndex];
			this.#sounds.click();
		});

		this.#eventElements = events.map(([date, icon, text, links = []], index) => {
			const item = fromTemplate(this.parts.eventTemplate);
			const [iconElement, dateElement, textElement] = item.children;
			iconElement.textContent = icon;
			dateElement.textContent = date;
			textElement.textContent = text;

			for (const id of links) {
				item.append(this.#linkButton(`📖 ${this.#articles[id].title}`, event => {
					event.stopPropagation();
					this.#sounds.page();
					this.#go(`article:${id}`);
				}));
			}

			item.addEventListener('click', () => {
				this.#stopTravel();
				this.#showEvent(index);
			});

			return item;
		});

		this.parts.timelineStrip.replaceChildren(...this.#eventElements);

		this.on(this.parts.timelineEarlier, 'click', () => {
			this.#step(-1);
		});

		this.on(this.parts.timelineLater, 'click', () => {
			this.#step(1);
		});

		this.on(this.parts.timelineStrip, 'keydown', event => {
			const offset = {ArrowLeft: -1, ArrowRight: 1}[event.key];

			if (offset) {
				event.preventDefault();
				this.#step(offset);
			} else if (event.key === 'Home' || event.key === 'End') {
				event.preventDefault();
				this.#stopTravel();
				this.#showEvent(event.key === 'Home' ? 0 : events.length - 1);
			}
		});

		for (const button of this.#eraButtons) {
			this.on(button, 'click', () => {
				this.#stopTravel();
				this.#sounds.click();
				this.#showEvent(Number(button.dataset.encartaEra));
			});
		}

		// Travel goes through the events to 1999 by itself, one by one, and jumps there for the visitors who prefer less motion.
		this.on(this.parts.timelinePlay, 'click', async () => {
			if (this.parts.timelinePlay.getAttribute('aria-pressed') === 'true') {
				this.#stopTravel();
				this.say('The time machine stops.');
				return;
			}

			const last = events.length - 2;

			if (this.reducedMotion) {
				this.#showEvent(last);
				return;
			}

			const run = ++this.#travelRun;
			this.parts.timelinePlay.setAttribute('aria-pressed', 'true');
			this.parts.timelinePlay.textContent = '⏹ Stop';

			if (this.#timelineIndex >= last) {
				this.#showEvent(0);
			}

			while (this.#timelineIndex < last) {
				await this.#wait(1100);

				if (run !== this.#travelRun) {
					return;
				}

				this.#showEvent(this.#timelineIndex + 1);
				this.#tone(440 + (this.#timelineIndex * 25), 0, 0.1, {type: 'sine', volume: 0.05});
			}

			this.#stopTravel();
			this.say('You have arrived in 1999. Welcome home.');
		});

		const record = this.stored('knights', {});
		this.#record = {knighted: storedCount(record.knighted), best: storedCount(record.best)};

		this.on(this.parts.mazeHint, 'click', () => {
			this.#useHint();
		});

		this.on(this.parts.mazeLookup, 'click', () => {
			const current = this.#game?.question;

			if (!current?.question.article) {
				return;
			}

			if (!current.isLookedUp) {
				current.isLookedUp = true;
				this.#addPoints(-10);
			}

			this.#sounds.page();
			this.#go(`article:${current.question.article}`).then(isOpen => {
				if (isOpen) {
					this.say(`${this.#articles[current.question.article].title}. The answer is somewhere here. Press MindMaze to go back to your question. (−10 points for looking it up.)`);
				}
			});
		});

		this.on(this.parts.mazeStepBack, 'click', () => {
			if (this.#game.question && !this.#game.question.isAnswered) {
				this.#closeQuestion();
				this.say('You step back from the door. It waits.');
				this.#drawMaze();
			}
		});

		for (const [index, button] of this.#answerButtons.entries()) {
			this.on(button, 'click', () => {
				this.#answer(index);
			});
		}

		for (const button of this.#doorButtons) {
			this.on(button, 'click', () => {
				this.#useSide(button.dataset.encartaDoor);
			});
		}

		this.on(this.parts.mazeTalk, 'click', () => {
			this.#talk();
		});

		this.on(this.parts.mazeMapToggle, 'click', () => {
			const isShown = this.parts.mazeMap.hidden;
			this.parts.mazeMap.hidden = !isShown;
			this.parts.mazeMapToggle.setAttribute('aria-pressed', String(isShown));
		});

		this.on(this.parts.mazeNew, 'click', async () => {
			if (this.#game && this.#game.score > 0 && !this.#game.isKnighted) {
				const reply = await this.ask({title: 'MindMaze', icon: '🏰', text: 'Do you want to leave this castle and start in a new one? Your points stay behind.', buttons: ['Yes', 'No'], opener: this.parts.mazeNew});

				if (reply !== 'Yes') {
					return;
				}
			}

			this.#newGame();
			this.say(`A new castle. ${this.#describeRoom()} Find the throne room!`);
			this.parts.mazeScreen.focus({preventScroll: true});
		});

		// A click or a tap on a door uses it, and a click on a character talks to them.
		this.on(this.parts.mazeScreen, 'click', event => {
			if (!this.#game) {
				return;
			}

			// The balloon goes away once the visitor acts, as it can cover a door on a phone.
			this.parts.mazeBalloon.hidden = true;

			const box = this.parts.mazeScreen.getBoundingClientRect();
			const x = (event.clientX - box.left) * 480 / box.width;
			const y = (event.clientY - box.top) * 300 / box.height;

			if (this.#game.people.has(this.#game.cell) && x > 130 && x < 206 && y > 160) {
				this.#talk();
			} else if (x >= backDoor.left - 6 && x <= backDoor.right + 6 && y >= backDoor.top - 24 && y <= backDoor.bottom) {
				this.#useSide('front');
			} else if (x >= 30 && x <= 118 && y >= 90 && y <= 285) {
				this.#useSide('left');
			} else if (x >= 362 && x <= 450 && y >= 90 && y <= 285) {
				this.#useSide('right');
			} else if (y > 250) {
				this.#useSide('back');
			}
		});

		this.on(this.parts.maze, 'keydown', event => {
			if (event.ctrlKey || event.altKey || event.metaKey) {
				return;
			}

			if (this.#game?.question && /^[1-4]$/.test(event.key)) {
				event.preventDefault();
				this.#answer(Number(event.key) - 1);
				return;
			}

			const key = event.key.toLowerCase();

			if (key === 'escape' && this.#game?.question) {
				// Escape steps back from the question instead of closing the window.
				event.preventDefault();
				event.stopPropagation();
				this.parts.mazeStepBack.click();
			} else if (key === 'h' && this.#game?.question) {
				event.preventDefault();
				this.#useHint();
			} else if (key === 't') {
				event.preventDefault();
				this.#talk();
			} else if (key === 'm') {
				event.preventDefault();
				this.parts.mazeMapToggle.click();
			} else if (event.target === this.parts.mazeScreen) {
				const side = {arrowleft: 'left', arrowup: 'front', arrowright: 'right', arrowdown: 'back'}[key];

				if (side) {
					event.preventDefault();
					this.#useSide(side);
				}
			}
		});
	}

	// Encarta starts the first time its window opens. Everything stops while the window is closed, and the clips stop while the tab is hidden.
	visibilityChanged(isVisible) {
		if (isVisible && !this.#hasStarted) {
			this.#start();
		} else if (document.hidden) {
			this.#stopClip();
		}

		this.#resumeWaits();
		this.#updateMotion();
	}

	// A closed window stops the clip, the travel of the timeline, and the speech, also when Encarta was off the screen already.
	windowChanged(isOpen) {
		if (isOpen) {
			return;
		}

		this.#stopClip();
		this.#stopTravel();

		if (canSpeak) {
			speechSynthesis.cancel();
		}
	}

	reducedMotionChanged() {
		this.#updateMotion();
	}

	// Another toy of the page starts a tune.
	musicStopped() {
		this.#stopClip();
	}

	// A control of MindMaze that goes away while it has the focus, like an answer once it is answered or a door that the next room does not have, gives the focus to the room, where the end of a question puts it too. The buttons of the timeline give it to each other at its ends.
	focusReplacement(control) {
		const {maze, mazeScreen, timelineEarlier, timelineLater} = this.parts;

		if (!maze.hidden && maze.contains(control)) {
			return mazeScreen;
		}

		if (control === timelineEarlier) {
			return timelineLater;
		}

		if (control === timelineLater) {
			return timelineEarlier;
		}

		return super.focusReplacement(control);
	}

	#resumeWaiters = [];

	// The waits of Encarta, like the disc that loads and the doors that open, stop while its window is closed or off the screen, or the tab is hidden.
	async #wait(milliseconds) {
		await new Promise(resolve => {
			setTimeout(resolve, milliseconds);
		});

		while (!this.isVisible) {
			await new Promise(resolve => {
				this.#resumeWaiters.push(resolve);
			});
		}
	}

	#resumeWaits() {
		if (this.isVisible) {
			for (const resolve of this.#resumeWaiters.splice(0)) {
				resolve();
			}
		}
	}

	// The things that move only move while the window is on the screen, the tab is visible, and the visitor does not prefer less motion.
	#canMove() {
		return this.isVisible && !this.reducedMotion;
	}

	#isSoundOn() {
		return this.parts.sound.getAttribute('aria-pressed') === 'true';
	}

	// A sound effect plays only while the sound is on. The sounds go through the volume of the tray, which the desktop gives in the handler of the click on the sound button.
	#tone(frequency, start, duration, options) {
		const sound = this.#isSoundOn() && this.isVisible && this.sound();

		if (sound) {
			playTone(sound.output, frequency, start, duration, options);
		}
	}

	#noise(start, duration, options) {
		const sound = this.#isSoundOn() && this.isVisible && this.sound();

		if (sound) {
			playNoise(sound.output, start, duration, options);
		}
	}

	#sounds = {
		click: () => {
			this.#tone(1400, 0, 0.03, {type: 'square', volume: 0.03});
		},
		whirr: () => {
			this.#tone(70, 0, 1.1, {type: 'sawtooth', volume: 0.03, slide: 260});
			this.#noise(0, 1.1, {frequency: 900, quality: 0.6, volume: 0.025});

			for (let index = 0; index < 4; index++) {
				this.#tone(2200, 0.15 + (index * 0.22), 0.02, {type: 'square', volume: 0.025});
			}
		},
		creak: () => {
			this.#tone(110, 0, 0.6, {type: 'sawtooth', volume: 0.05, slide: 190, vibrato: 12});
			this.#noise(0, 0.25, {frequency: 400, volume: 0.04});
		},
		steps: () => {
			for (let index = 0; index < 3; index++) {
				this.#tone(95, index * 0.18, 0.08, {type: 'sine', volume: 0.18, slide: 60});
			}
		},
		bump: () => {
			this.#tone(80, 0, 0.15, {type: 'sine', volume: 0.2, slide: 40});
			this.#noise(0, 0.1, {frequency: 300, volume: 0.06});
		},
		right: () => {
			this.#tone(660, 0, 0.12);
			this.#tone(880, 0.12, 0.25);
		},
		wrong: () => {
			this.#tone(160, 0, 0.45, {type: 'sawtooth', volume: 0.06, slide: 80});
		},
		rank: () => {
			for (const [index, frequency] of [523.25, 659.25, 783.99].entries()) {
				this.#tone(frequency, index * 0.1, 0.2, {type: 'square', volume: 0.05});
			}
		},
		fanfare: () => {
			const notes = [[392, 0, 0.15], [523.25, 0.15, 0.15], [659.25, 0.3, 0.15], [783.99, 0.45, 0.4], [659.25, 0.85, 0.15], [783.99, 1, 0.9]];

			for (const [frequency, start, duration] of notes) {
				this.#tone(frequency, start, duration, {type: 'square', volume: 0.06});
				this.#tone(frequency / 2, start, duration, {type: 'triangle', volume: 0.06});
			}
		},
		ghost: () => {
			this.#tone(420, 0, 1.2, {type: 'sine', volume: 0.08, slide: 180, vibrato: 25});
		},
		jester: () => {
			for (let index = 0; index < 6; index++) {
				this.#tone(index % 2 === 0 ? 1568 : 1760, index * 0.07, 0.12, {volume: 0.04});
			}
		},
		page: () => {
			this.#noise(0, 0.12, {frequency: 3000, quality: 0.5, volume: 0.03});
		},
		sizzle: () => {
			this.#noise(0, 0.9, {frequency: 5000, quality: 0.4, volume: 0.04});
		},
	};

	// A clip is a longer sound, like an anthem or the modem, which plays on its own volume, so it can stop in the middle. Only one tune of the page plays at a time.
	#clip;

	#stopClip() {
		if (!this.#clip) {
			return;
		}

		const {gain, timers, onEnd} = this.#clip;
		this.#clip = undefined;
		gain.disconnect();

		for (const timer of timers) {
			clearTimeout(timer);
		}

		this.music(false);
		onEnd?.();
	}

	#startClip({name, duration, build, cues = [], onEnd}) {
		this.#stopClip();

		const sound = this.sound();

		if (!sound) {
			return;
		}

		const gain = sound.context.createGain();
		gain.connect(sound.output);
		const output = {
			tone: (...parameters) => playTone(gain, ...parameters),
			noise: (...parameters) => playNoise(gain, ...parameters),
		};
		build(output);
		const timers = cues.map(([time, action]) => setTimeout(action, time * 1000));
		this.#clip = {name, gain, timers, onEnd};
		timers.push(setTimeout(() => {
			this.#stopClip();
		}, (duration * 1000) + 100));
		this.music(true);
	}

	// The message box of the desktop. It closes with the window of Encarta.
	ask(options) {
		return super.ask({title: 'Microsoft Encarta', icon: '💿', opener: this.desktopWindow, ...options});
	}

	// The articles of Encarta. Each has a media picture that it draws on the canvas from its state, and buttons that change the state.
	#articles = {
		norway: {
			title: 'Norway',
			icon: '🇳🇴',
			category: 'Geography',
			disc: 1,
			pronunciation: 'Norwegian: Norge (NOR-geh)',
			speech: {text: 'Norge', lang: 'nb-NO'},
			keywords: 'norge noreg oslo fjord kingdom scandinavia harald krone oil lillehammer flag anthem',
			paragraphs: [
				'Norway (Norwegian Norge or Noreg), kingdom in northern Europe, on the western part of the Scandinavian Peninsula. Norway has about 4.4 million people, and its capital and largest city is Oslo. The long coast is cut by deep, narrow bays called fjords, and about half of the country lies north of the Arctic Circle.',
				'Norway is a constitutional monarchy. King Harald V has reigned since 1991. The constitution was signed at Eidsvoll on May 17, 1814, and Norway left its union with Sweden in 1905. In 1994 the Norwegians voted no to joining the European Union, for the second time.',
				'Since oil was found in the North Sea in 1969, Norway has become one of the richest countries in the world. Fishing, shipping, and forestry are also important. The currency is the Norwegian krone. In 1994 the town of Lillehammer hosted the Winter Olympic Games.',
			],
			facts: [
				'Norwegians say that their flag is the “mother of all flags”, as the flags of France, the Netherlands, and Finland are hidden in it.',
				'The cheese slicer was invented by the Norwegian carpenter Thor Bjørklund in 1925.',
				'The Norwegian Johan Vaaler patented a paper clip in 1899. Nobody has patented the Office Assistant yet.',
				'On May 17, children walk in parades with flags, and eat as much ice cream and as many hot dogs as they want.',
			],
			seeAlso: ['bergen', 'waffle', 'internet'],
			media: {
				caption: 'The flag of Norway, with a blue cross outlined in white on red.',
				label: 'The flag of Norway',
				start: () => ({playing: false, line: -1}),
				actions: [
					{label: state => (state.playing ? '⏹ Stop' : '▶ Play the national anthem'), run: state => (state.playing ? this.#stopClip() : this.#playAnthem(state))},
				],
				isMoving: state => state.playing,
				draw(context, state, time) {
					const {width, height} = context.canvas;
					context.fillStyle = '#87b4e0';
					context.fillRect(0, 0, width, height);
					const flagWidth = 176;
					const flagHeight = 128;
					const left = (width - flagWidth) / 2;
					const top = 8;
					const unit = flagWidth / 22;
					const stripWidth = 4;

					// The flag waves in strips while the anthem plays.
					for (let x = 0; x < flagWidth; x += stripWidth) {
						const wave = state.playing ? Math.sin((x / 22) + (time / 220)) * 3 * (x / flagWidth) : 0;
						context.save();
						context.beginPath();
						context.rect(left + x, top + wave, stripWidth + 0.5, flagHeight);
						context.clip();
						context.translate(0, wave);
						context.fillStyle = '#ba0c2f';
						context.fillRect(left, top, flagWidth, flagHeight);
						context.fillStyle = '#ffffff';
						context.fillRect(left + (6 * unit), top, 4 * unit, flagHeight);
						context.fillRect(left, top + (6 * unit), flagWidth, 4 * unit);
						context.fillStyle = '#00205b';
						context.fillRect(left + (7 * unit), top, 2 * unit, flagHeight);
						context.fillRect(left, top + (7 * unit), flagWidth, 2 * unit);
						context.restore();
					}

					context.fillStyle = '#5a4030';
					context.fillRect(left - 4, top - 4, 4, height);

					if (state.line >= 0) {
						textBox(context, `🎵 ${anthem.lyrics[state.line]}`, width / 2, height - 6, {font: 'italic bold 12px "Times New Roman", serif'});
					}
				},
			},
		},
		bergen: {
			title: 'Bergen',
			icon: '☔',
			category: 'Geography',
			disc: 1,
			pronunciation: 'BAIR-gen',
			speech: {text: 'Bergen', lang: 'nb-NO'},
			keywords: 'city rain bryggen hanseatic grieg fløyen fish market seven mountains umbrella',
			paragraphs: [
				'Bergen, the second largest city of Norway, on the west coast, with about 225,000 people. The city lies between seven mountains, and it was founded about 1070 by King Olav Kyrre. In the 13th century Bergen was the capital of Norway.',
				'From the 14th century, German merchants of the Hanseatic League traded dried fish from the old wharf, Bryggen, whose wooden houses are on the World Heritage List of UNESCO. The funicular Fløibanen goes up the mountain Fløyen, and the fish market by the harbor is famous.',
				'Bergen is known as one of the wettest cities of Europe, with about 2,250 millimeters of rain a year. The composer Edvard Grieg was born here in 1843.',
			],
			facts: [
				'People in Bergen say: “There is no bad weather, only bad clothes.”',
				'It rains in Bergen on more than 200 days of the year. Sindre has checked, from his window.',
				'A child of Bergen is said to be born with an umbrella in the hand.',
				'The Black Death came to Norway in 1349 on a ship to Bergen.',
			],
			seeAlso: ['norway', 'waffle'],
			media: {
				caption: 'Bryggen, the old wharf of Bergen, in a typical weather.',
				label: 'Bryggen in Bergen in the rain',
				start: () => ({rain: 2, playing: false, drops: Array.from({length: 120}, () => ({x: Math.random() * 240, y: Math.random() * 150, speed: 0.6 + Math.random()}))}),
				actions: [
					{label: state => (state.rain === 4 ? '☀️ Stop the rain' : '🌧️ More rain'), run: state => this.#changeRain(state)},
					{label: state => (state.playing ? '⏹ Stop' : '▶ Play Grieg'), run: state => (state.playing ? this.#stopClip() : this.#playGrieg(state))},
				],
				isMoving: state => state.rain > 0,
				draw(context, state, time) {
					const {width, height} = context.canvas;
					const sky = context.createLinearGradient(0, 0, 0, 90);
					sky.addColorStop(0, state.rain === 0 ? '#5aa0e8' : '#6a7480');
					sky.addColorStop(1, state.rain === 0 ? '#bfe0ff' : '#a8b0b8');
					context.fillStyle = sky;
					context.fillRect(0, 0, width, height);

					if (state.rain === 0) {
						context.fillStyle = '#ffe14a';
						context.beginPath();
						context.arc(200, 26, 14, 0, Math.PI * 2);
						context.fill();
					}

					// The mountains behind the city.
					context.fillStyle = '#3c5a3a';
					context.beginPath();
					context.moveTo(0, 80);
					context.lineTo(40, 40);
					context.lineTo(80, 62);
					context.lineTo(130, 30);
					context.lineTo(175, 58);
					context.lineTo(215, 38);
					context.lineTo(240, 55);
					context.lineTo(240, 100);
					context.lineTo(0, 100);
					context.fill();

					// The gables of Bryggen.
					const colors = ['#b8322a', '#f0e6c8', '#d8a020', '#8a3a20', '#f0e6c8', '#c84a2a', '#e8c040', '#7a2a1a', '#f0e6c8', '#b8322a'];

					for (const [index, color] of colors.entries()) {
						const x = 4 + (index * 23.5);
						context.fillStyle = color;
						context.beginPath();
						context.moveTo(x, 118);
						context.lineTo(x, 84);
						context.lineTo(x + 11, 68);
						context.lineTo(x + 22, 84);
						context.lineTo(x + 22, 118);
						context.fill();
						context.strokeStyle = 'rgba(0, 0, 0, 0.4)';
						context.stroke();
						context.fillStyle = '#ffffcc';
						context.fillRect(x + 4, 90, 5, 6);
						context.fillRect(x + 13, 90, 5, 6);
						context.fillRect(x + 8, 102, 6, 9);
					}

					context.fillStyle = state.rain === 0 ? '#2a6aa8' : '#3a5068';
					context.fillRect(0, 118, width, height - 118);

					// The rain falls while it can move, and stands still for the visitors who prefer less motion.
					context.strokeStyle = 'rgba(220, 230, 255, 0.7)';
					context.lineWidth = 1;
					const count = state.rain * 30;

					for (const drop of state.drops.slice(0, count)) {
						const y = (drop.y + (time * 0.25 * drop.speed)) % height;
						const x = (drop.x - ((time * 0.05 * drop.speed) % width) + width) % width;
						context.beginPath();
						context.moveTo(x, y);
						context.lineTo(x - 2, y + 7);
						context.stroke();
					}

					const words = ['Sun! Everybody runs outside.', 'Drizzle (“yr”)', 'Normal Bergen rain', 'Heavy rain', 'Pouring down (“øsregn”)'];
					textBox(context, words[state.rain], 6, 14, {align: 'left'});
				},
			},
		},
		waffle: {
			title: 'Waffle',
			icon: '🧇',
			category: 'Food & Hobbies',
			disc: 1,
			pronunciation: 'Norwegian: vaffel (VAFF-el)',
			speech: {text: 'vaffel', lang: 'nb-NO'},
			keywords: 'vaffel brunost brown cheese iron heart batter jam sour cream baking food',
			paragraphs: [
				'Waffle, flat cake of batter baked between the two hot plates of a waffle iron, which press a pattern of squares into it. Waffles have been baked in Europe since the Middle Ages.',
				'In Norway, a waffle has the shape of five hearts in a circle. It is eaten warm or cold, folded, with brown cheese (brunost), with jam, or with sour cream. Norwegian waffles are served at birthdays, at school bazaars, and on the ferries along the coast.',
				'In the United States, Cornelius Swartwout of New York patented a waffle iron in 1869, and the thick Belgian waffle became famous at the World’s Fair in New York in 1964.',
			],
			facts: [
				'Brown cheese was first made by Anne Hov, a dairymaid in Gudbrandsdalen, in 1863.',
				'In Sweden, March 25 is Waffle Day (Våffeldagen).',
				'Mormor says that the first waffle always goes wrong. That is why she eats it herself.',
			],
			seeAlso: ['norway', 'bergen'],
			media: {
				caption: 'A Norwegian waffle, five hearts in a circle.',
				label: 'A heart waffle on a plate',
				start: () => ({baked: 1, cheese: false, eaten: 0}),
				actions: [
					{label: state => (state.baked === 3 || state.eaten === 5 ? '🥣 New batter' : '🔥 Bake longer'), run: state => this.#bakeWaffle(state)},
					{label: state => (state.cheese ? '🧀 Take off the brunost' : '🧀 Add brunost'), run: state => {
						state.cheese = !state.cheese;
						this.say(state.cheese ? 'Brunost on top. Now it is a real Norwegian waffle.' : 'The brunost is off. Mormor looks worried.');
					}},
					{label: () => '😋 Eat a heart', run: state => this.#eatWaffle(state)},
				],
				isMoving: () => false,
				draw(context, state) {
					const {width, height} = context.canvas;

					// A red and white checkered tablecloth.
					for (let y = 0; y < height; y += 15) {
						for (let x = 0; x < width; x += 15) {
							context.fillStyle = ((x + y) / 15) % 2 === 0 ? '#d83a3a' : '#fff0f0';
							context.fillRect(x, y, 15, 15);
						}
					}

					context.fillStyle = '#ffffff';
					context.beginPath();
					context.ellipse(120, 75, 70, 66, 0, 0, Math.PI * 2);
					context.fill();
					context.strokeStyle = '#c0c0c0';
					context.stroke();
					const colors = ['#f3e2a0', '#e0a640', '#b8742a', '#3a2410'];
					const grid = ['#d8c480', '#b87a20', '#8a5018', '#1a1008'];

					for (let heart = state.eaten; heart < 5; heart++) {
						const angle = (heart * Math.PI * 2 / 5) - (Math.PI / 2);
						context.save();
						context.translate(120 + (Math.cos(angle) * 27), 75 + (Math.sin(angle) * 27));
						context.rotate(angle + (Math.PI / 2));
						heartPath(context, 54);
						context.fillStyle = colors[state.baked];
						context.fill();
						context.strokeStyle = grid[state.baked];
						context.lineWidth = 1.5;
						context.stroke();
						context.save();
						context.clip();
						context.strokeStyle = grid[state.baked];
						context.lineWidth = 2;

						for (let line = -30; line <= 30; line += 7) {
							context.beginPath();
							context.moveTo(line, -30);
							context.lineTo(line, 30);
							context.moveTo(-30, line);
							context.lineTo(30, line);
							context.stroke();
						}

						if (state.cheese) {
							context.fillStyle = '#c87a3a';
							context.fillRect(-14, -12, 28, 6);
							context.fillRect(-10, -2, 22, 6);
						}

						context.restore();
						context.restore();
					}

					if (state.baked === 3) {
						context.fillStyle = 'rgba(80, 80, 80, 0.5)';

						for (const [x, y, radius] of [[100, 30, 14], [125, 18, 18], [150, 32, 12]]) {
							context.beginPath();
							context.arc(x, y, radius, 0, Math.PI * 2);
							context.fill();
						}
					}

					const words = ['Raw batter', 'Golden', 'Brown and crispy', 'Burnt!'];
					textBox(context, state.eaten === 5 ? 'All gone' : words[state.baked], 6, 14, {align: 'left'});
				},
			},
		},
		unicorn: {
			title: 'Unicorn',
			icon: '🦄',
			category: 'Myths & Legends',
			disc: 1,
			pronunciation: 'YOO-nih-korn',
			speech: {text: 'unicorn', lang: 'en-US'},
			keywords: 'myth legend horn narwhal alicorn scotland glitter horse magic',
			paragraphs: [
				'Unicorn, a legendary animal like a white horse, with a single long, spiraled horn in the middle of its forehead. The Greek doctor Ctesias described it about 400 BC, after stories of a wild ass of India.',
				'In the Middle Ages, people believed that the horn of the unicorn could make poison harmless, and that only a maiden could tame the animal. Kings and popes paid fortunes for unicorn horns. Most of them were the tusks of the narwhal, a whale of the Arctic seas.',
				'The unicorn is the national animal of Scotland, and it holds the royal coat of arms of the United Kingdom together with the lion.',
			],
			facts: [
				'The throne of the kings of Denmark and Norway, finished in 1671, is made of “unicorn horns”, which are narwhal tusks.',
				'Sindre has a virtual unicorn called Glitter on his home page. She is real, as far as this encyclopedia knows.',
				'The tusk of a narwhal is a tooth that can grow to 3 meters.',
			],
			seeAlso: ['furby', 'norway'],
			media: {
				caption: 'A unicorn, as the artists of the Middle Ages imagined it.',
				label: 'A white unicorn with a rainbow mane',
				start: () => ({narwhal: false, sparkles: []}),
				actions: [
					{label: state => (state.narwhal ? '🦄 Show the unicorn' : '🐋 Show the real “unicorn”'), run: state => {
						state.narwhal = !state.narwhal;
						this.parts.mediaCaption.textContent = state.narwhal ? 'A narwhal, whose tusk was sold as the horn of a unicorn.' : 'A unicorn, as the artists of the Middle Ages imagined it.';
						this.say(state.narwhal ? 'The secret of the unicorn horns: a whale of the Arctic seas.' : 'The unicorn is back. Glitter approves.');
					}},
					{label: () => '✨ Sparkle', run: state => {
						for (let index = 0; index < 6; index++) {
							state.sparkles.push({x: Math.random() * 240, y: Math.random() * 150, size: 3 + (Math.random() * 5)});
						}

						state.sparkles = state.sparkles.slice(-48);
						this.#tone(1760, 0, 0.15, {volume: 0.04});
						this.#tone(2349, 0.08, 0.2, {volume: 0.04});
					}},
				],
				isMoving: () => false,
				draw(context, state) {
					const {width, height} = context.canvas;

					if (state.narwhal) {
						const sea = context.createLinearGradient(0, 0, 0, height);
						sea.addColorStop(0, '#2a6aa8');
						sea.addColorStop(1, '#0a2050');
						context.fillStyle = sea;
						context.fillRect(0, 0, width, height);
						context.fillStyle = '#8a9aa8';
						context.beginPath();
						context.ellipse(130, 85, 70, 24, -0.1, 0, Math.PI * 2);
						context.fill();
						context.beginPath();
						context.moveTo(195, 75);
						context.lineTo(232, 60);
						context.lineTo(222, 85);
						context.fill();
						context.fillStyle = '#5a6a78';

						for (const [x, y] of [[100, 80], [130, 90], [150, 76], [115, 95]]) {
							context.beginPath();
							context.arc(x, y, 3, 0, Math.PI * 2);
							context.fill();
						}

						context.strokeStyle = '#f0ead0';
						context.lineWidth = 3;
						context.beginPath();
						context.moveTo(64, 82);
						context.lineTo(8, 60);
						context.stroke();
						context.fillStyle = '#000000';
						context.beginPath();
						context.arc(76, 82, 2.5, 0, Math.PI * 2);
						context.fill();
					} else {
						const sky = context.createLinearGradient(0, 0, 0, height);
						sky.addColorStop(0, '#ffd8f0');
						sky.addColorStop(1, '#c8f0ff');
						context.fillStyle = sky;
						context.fillRect(0, 0, width, height);

						for (const [index, color] of ['#ff4040', '#ffa040', '#ffff40', '#40d040', '#4080ff', '#a040ff'].entries()) {
							context.strokeStyle = color;
							context.lineWidth = 4;
							context.beginPath();
							context.arc(120, 170, 130 - (index * 4), Math.PI, Math.PI * 2);
							context.stroke();
						}

						context.fillStyle = '#7ac860';
						context.fillRect(0, 128, width, 22);
						context.fillStyle = '#ffffff';
						context.strokeStyle = '#9090c0';
						context.lineWidth = 1.5;

						for (const x of [92, 104, 146, 158]) {
							context.fillRect(x, 96, 8, 36);
							context.strokeRect(x, 96, 8, 36);
						}

						context.beginPath();
						context.ellipse(125, 92, 44, 20, 0, 0, Math.PI * 2);
						context.fill();
						context.stroke();
						context.beginPath();
						context.moveTo(150, 82);
						context.lineTo(168, 52);
						context.lineTo(186, 60);
						context.lineTo(166, 92);
						context.fill();
						context.stroke();
						context.beginPath();
						context.ellipse(182, 58, 16, 10, 0.4, 0, Math.PI * 2);
						context.fill();
						context.stroke();
						context.fillStyle = '#ffd700';
						context.beginPath();
						context.moveTo(184, 47);
						context.lineTo(204, 22);
						context.lineTo(190, 50);
						context.fill();
						context.fillStyle = '#000000';
						context.beginPath();
						context.arc(186, 56, 2, 0, Math.PI * 2);
						context.fill();

						for (const [index, color] of ['#ff4fa0', '#ffa040', '#ffe040', '#40c0ff', '#a060ff'].entries()) {
							context.strokeStyle = color;
							context.lineWidth = 4;
							context.beginPath();
							context.moveTo(170 - (index * 3), 48 + (index * 5));
							context.quadraticCurveTo(155 - (index * 6), 60 + (index * 6), 160 - (index * 4), 78 + (index * 4));
							context.stroke();
							context.beginPath();
							context.moveTo(82, 86 + (index * 2));
							context.quadraticCurveTo(66, 96 + (index * 4), 72, 118 + (index * 2));
							context.stroke();
						}
					}

					context.fillStyle = '#fff8a0';

					for (const sparkle of state.sparkles) {
						context.save();
						context.translate(sparkle.x, sparkle.y);
						context.beginPath();

						for (let point = 0; point < 8; point++) {
							const radius = point % 2 === 0 ? sparkle.size : sparkle.size / 3;
							const angle = point * Math.PI / 4;
							context.lineTo(Math.cos(angle) * radius, Math.sin(angle) * radius);
						}

						context.fill();
						context.restore();
					}
				},
			},
		},
		y2k: {
			title: 'Year 2000 Problem',
			icon: '📅',
			category: 'Science & Technology',
			disc: 2,
			pronunciation: 'Also called Y2K (why-too-KAY) or the millennium bug',
			speech: {text: 'Y 2 K', lang: 'en-US'},
			keywords: 'y2k millennium bug 2000 1900 computer date clock leap year',
			paragraphs: [
				'Year 2000 problem, also called Y2K or the millennium bug, a flaw in computer programs and chips that store the year with only two digits, like 99 for 1999. When the year 2000 comes, such a computer can read 00 as the year 1900.',
				'Programmers of the 1960s and 1970s saved expensive memory by leaving out the 19. A computer with the problem could compute a negative age, charge a hundred years of interest, or stop. Banks, airlines, power companies, and governments spend hundreds of billions of dollars to test and fix their systems before January 1, 2000.',
				'Some people store water, canned food, and candles in case the computers fail. Others plan to celebrate the new millennium in a plane, to see what happens.',
			],
			facts: [
				'The year 2000 is a leap year, as it can be divided by 400. Some programs get that wrong too.',
				'Strictly, the new millennium begins on January 1, 2001. Nobody wants to wait.',
				'Pappa has already printed the bank statement, just in case.',
			],
			seeAlso: ['internet', 'modem'],
			media: {
				caption: 'The clock of a computer with the year 2000 problem.',
				label: 'A computer clock showing 31.12.99',
				start: () => ({seconds: 55, rolled: false, running: false, age: false}),
				actions: [
					{label: state => (state.rolled ? '↩ Back to 1999' : '⏩ Roll over to 2000'), run: state => this.#rollOver(state)},
					{label: () => '👵 Mormor’s age', run: state => {
						state.age = !state.age;
						this.say(state.age ? (state.rolled ? 'Mormor was born in 22. 00 minus 22 is minus 22. Mormor is not born yet!' : 'Mormor was born in 22. 99 minus 22 is 77. That is right, for now.') : 'The age is hidden. Mormor prefers that anyway.');
					}},
				],
				isMoving: () => false,
				draw(context, state) {
					const {width, height} = context.canvas;
					context.fillStyle = '#101010';
					context.fillRect(0, 0, width, height);
					context.fillStyle = '#002a00';
					context.fillRect(14, 14, width - 28, 70);
					context.strokeStyle = '#3a3a3a';
					context.lineWidth = 4;
					context.strokeRect(14, 14, width - 28, 70);
					const date = state.rolled ? '01.01.00' : '31.12.99';
					const time = state.rolled ? '00:00:00' : `23:59:${String(state.seconds).padStart(2, '0')}`;
					context.font = 'bold 26px "Courier New", monospace';
					context.textAlign = 'center';
					context.textBaseline = 'middle';
					context.fillStyle = '#33ff66';
					context.fillText(date, width / 2, 36);
					context.fillText(time, width / 2, 64);
					context.font = 'bold 14px "Courier New", monospace';
					context.fillStyle = state.rolled ? '#ff4040' : '#33ff66';
					context.fillText(state.rolled ? 'YEAR: 1900  (!!!)' : 'YEAR: 1999', width / 2, 102);

					if (state.age) {
						context.fillStyle = state.rolled ? '#ff4040' : '#c0c0c0';
						context.fillText(state.rolled ? 'MORMOR: 00 - 22 = -22 YEARS' : 'MORMOR: 99 - 22 = 77 YEARS', width / 2, 124);
					} else if (state.rolled) {
						context.fillStyle = '#ffff60';
						context.fillText('HAPPY NEW YEAR 1900?', width / 2, 124);
					}

					context.textAlign = 'left';
				},
			},
		},
		internet: {
			title: 'Internet',
			icon: '🌐',
			category: 'Science & Technology',
			disc: 2,
			pronunciation: 'IN-ter-net',
			speech: {text: 'Internet', lang: 'en-US'},
			keywords: 'arpanet world wide web www browser email hosts network berners-lee mosaic krøllalfa',
			paragraphs: [
				'Internet, the worldwide network of computer networks. It began in 1969 as the ARPANET of the United States Department of Defense, which connected four universities. The first message, from Los Angeles to Stanford, was meant to be “LOGIN”, but the computer crashed after “LO”.',
				'In 1973 Norway was one of the first countries outside the United States to connect to the ARPANET. In 1989 and 1990, the British scientist Tim Berners-Lee invented the World Wide Web at CERN in Switzerland, and the Mosaic browser of 1993 made it easy to use.',
				'In 1999, about 200 million people use the Internet, for electronic mail, chat, news, and home pages. Most of them connect from home with a modem and a telephone line.',
			],
			facts: [
				'In Norwegian, the @ sign is called “krøllalfa”, the curly alpha.',
				'The first webcam watched a coffee pot at the University of Cambridge.',
				'In 1999 the number of computers on the Internet doubles about every year.',
			],
			seeAlso: ['modem', 'y2k', 'furby'],
			media: {
				caption: 'The number of computers (hosts) on the Internet, by year.',
				label: 'A chart of the computers on the Internet',
				start: () => ({index: hostCounts.length - 1}),
				actions: [
					{label: () => '◀ Earlier', run: state => {
						state.index = (state.index + hostCounts.length - 1) % hostCounts.length;
						this.#sounds.click();
					}},
					{label: () => 'Later ▶', run: state => {
						state.index = (state.index + 1) % hostCounts.length;
						this.#sounds.click();
					}},
				],
				isMoving: () => false,
				draw(context, state) {
					const {width, height} = context.canvas;
					const [year, hosts] = hostCounts[state.index];
					context.fillStyle = '#06103a';
					context.fillRect(0, 0, width, height);

					// The globe with a dot for the computers, more dots for more of them.
					context.strokeStyle = '#2a4aa0';
					context.lineWidth = 1;
					context.beginPath();
					context.arc(52, 56, 44, 0, Math.PI * 2);
					context.stroke();

					for (const radius of [15, 30]) {
						context.beginPath();
						context.ellipse(52, 56, radius, 44, 0, 0, Math.PI * 2);
						context.stroke();
					}

					context.beginPath();
					context.moveTo(8, 56);
					context.lineTo(96, 56);
					context.stroke();
					const dots = Math.round(Math.log10(hosts + 1) * 22);
					let seed = 7;
					const random = () => {
						seed = (seed * 16_807) % 2_147_483_647;
						return seed / 2_147_483_647;
					};

					const points = [];

					for (let index = 0; index < dots; index++) {
						const angle = random() * Math.PI * 2;
						const radius = Math.sqrt(random()) * 42;
						points.push([52 + (Math.cos(angle) * radius), 56 + (Math.sin(angle) * radius)]);
					}

					context.strokeStyle = 'rgba(80, 200, 255, 0.35)';

					for (let index = 1; index < points.length; index += 3) {
						context.beginPath();
						context.moveTo(...points[index - 1]);
						context.lineTo(...points[index]);
						context.stroke();
					}

					context.fillStyle = '#7fe0ff';

					for (const [x, y] of points) {
						context.fillRect(x - 1, y - 1, 2, 2);
					}

					context.fillStyle = '#ffd700';
					context.font = 'bold 26px "Times New Roman", serif';
					context.textAlign = 'left';
					context.textBaseline = 'alphabetic';
					context.fillText(String(year), 112, 40);
					context.fillStyle = '#ffffff';
					context.font = 'bold 14px Arial, sans-serif';
					context.fillText(hosts.toLocaleString('en-US'), 112, 62);
					context.font = '11px Arial, sans-serif';
					context.fillText(hosts === 1 ? 'computer' : 'computers', 112, 76);

					// A bar for each year, on a scale where each line is ten times more.
					const barWidth = (width - 16) / hostCounts.length;

					for (const [index, [, count]] of hostCounts.entries()) {
						const barHeight = Math.log10(count + 1) * 6.5;
						context.fillStyle = index === state.index ? '#ffd700' : '#3a6ad0';
						context.fillRect(8 + (index * barWidth), 144 - barHeight, barWidth - 2, barHeight);
					}
				},
			},
		},
		modem: {
			title: 'Modem',
			icon: '📞',
			category: 'Science & Technology',
			disc: 2,
			pronunciation: 'MOH-dem, from modulator-demodulator',
			speech: {text: 'modem', lang: 'en-US'},
			keywords: 'dial-up 56k v.90 baud telephone line handshake hayes isp connect phone mamma',
			paragraphs: [
				'Modem (short for modulator-demodulator), device that turns the data of a computer into sounds that can travel over a telephone line, and turns the sounds of another modem back into data. Its speed is measured in bits per second (bps).',
				'When a modem calls, the two modems first whistle and screech at each other. This handshake tests the line and agrees on the fastest speed that both can use. In 1998 the V.90 standard made 56,000 bps (56k) modems work together.',
				'While a modem is online, the telephone line is busy. Nobody can call the house, and if somebody picks up the phone, the connection is lost.',
			],
			facts: [
				'Modems are told what to do with the AT commands of Hayes. ATDT dials a number, and ATH0 hangs up.',
				'A 56k modem rarely gets 56k. The telephone lines are not good enough, and the law of the United States keeps it at 53k.',
				'Pappa says that the phone bill is bigger than the electricity bill now.',
			],
			seeAlso: ['internet', 'y2k'],
			media: {
				caption: 'A 56k external modem, with its lights.',
				label: 'An external modem',
				start: () => ({phase: 'idle', line: 'READY', speed: -1}),
				actions: [
					{label: state => (state.phase === 'idle' || state.phase === 'dropped' ? '📞 Connect' : '📴 Hang up'), run: state => (state.phase === 'idle' || state.phase === 'dropped' ? this.#connectModem(state) : this.#hangUp(state))},
					{label: () => '☎️ Mamma picks up', run: state => this.#mammaPicksUp(state)},
					{label: () => '⏱️ Download time', run: state => {
						state.speed = (state.speed + 1) % modemSpeeds.length;
						const [name, bitsPerSecond] = modemSpeeds[state.speed];
						const seconds = Math.round(3.6 * 1024 * 1024 * 8 / bitsPerSecond);
						state.line = `${name}: ${Math.floor(seconds / 60)} MIN ${seconds % 60} S`;
						this.say(`At ${name}, “A-ha, Take On Me.mp3” (3.6 MB) takes ${Math.floor(seconds / 60)} minutes and ${seconds % 60} seconds, if Mamma does not pick up the phone.`);
					}},
				],
				isMoving: state => state.phase === 'dialing' || state.phase === 'handshake' || state.phase === 'online',
				draw: (context, state, time) => {
					const {width, height} = context.canvas;
					context.fillStyle = '#4a5a6a';
					context.fillRect(0, 0, width, height);
					context.fillStyle = '#002a00';
					context.fillRect(16, 12, width - 32, 30);
					context.fillStyle = '#33ff66';
					context.font = 'bold 13px "Courier New", monospace';
					context.textAlign = 'center';
					context.textBaseline = 'middle';
					context.fillText(state.line, width / 2, 28);

					// The beige box of the modem, seen from the front.
					context.fillStyle = '#d8d0b8';
					context.beginPath();
					context.moveTo(20, 70);
					context.lineTo(220, 70);
					context.lineTo(230, 120);
					context.lineTo(10, 120);
					context.fill();
					context.fillStyle = '#b8b098';
					context.fillRect(10, 120, 220, 14);
					context.fillStyle = '#404040';
					context.font = 'bold 9px Arial, sans-serif';
					context.fillText('SPORTSTER 56K', 60, 84);
					const lights = ['HS', 'AA', 'CD', 'OH', 'RD', 'SD', 'TR', 'MR'];
					const isConnecting = state.phase === 'dialing' || state.phase === 'handshake';
					const isOnline = state.phase === 'online';
					const blink = this.#canMove() ? Math.floor(time / 90) : 0;

					for (const [index, name] of lights.entries()) {
						const x = 46 + (index * 22);
						const isOn = {
							HS: isOnline,
							AA: false,
							CD: isOnline,
							OH: isConnecting || isOnline,
							RD: (isConnecting || isOnline) && (blink + index) % 3 !== 0,
							SD: (isConnecting || isOnline) && (blink + index) % 2 === 0,
							TR: state.phase !== 'idle',
							MR: true,
						}[name];
						context.fillStyle = isOn ? '#ff3030' : '#602020';
						context.beginPath();
						context.arc(x, 106, 4, 0, Math.PI * 2);
						context.fill();
						context.fillStyle = '#404040';
						context.fillText(name, x, 126);
					}

					context.textAlign = 'left';
				},
			},
		},
		furby: {
			title: 'Furby',
			icon: '🦉',
			category: 'Food & Hobbies',
			disc: 2,
			pronunciation: 'FUR-bee',
			speech: {text: 'Furby', lang: 'en-US'},
			keywords: 'toy tiger electronics furbish robot pet electronic nsa 1998 christmas',
			paragraphs: [
				'Furby, electronic toy pet made by Tiger Electronics, sold from October 1998. A Furby looks like a furry owl with big ears, and it has motors, sensors, and a small computer inside. It blinks, wiggles its ears, sleeps, and talks.',
				'A new Furby speaks only its own language, Furbish, and seems to learn English over time, although the words are already in it. Furby was the toy of the Christmas of 1998, when parents fought over the last ones in the shops. About 14 million are sold in 1999.',
				'In January 1999, the National Security Agency of the United States banned Furbies from its offices, in case they could record secrets. They cannot.',
			],
			facts: [
				'A Furby has no off switch. To make it quiet, take out the batteries.',
				'Two Furbies near each other talk together, with infrared light.',
				'Lillesøster wants one for her birthday. Sindre wants a modem that is faster.',
			],
			seeAlso: ['unicorn', 'internet'],
			media: {
				caption: 'A Furby, ready to talk.',
				label: 'A Furby',
				start: () => ({word: -1, blinkUntil: 0, giggles: 0}),
				actions: [
					{label: () => '🗣️ Speak Furbish', run: state => {
						state.word = (state.word + 1) % furbish.length;
						const [word, meaning] = furbish[state.word];
						state.blinkUntil = performance.now() + 250;
						state.giggles = 0;
						speak(word.replaceAll('-', ''), {lang: 'en-US', pitch: 2, rate: 1.1});
						this.say(`Furby says “${word}”, which means “${meaning}”`);
						setTimeout(() => {
							this.#drawMedia();
						}, 300);
					}},
					{label: () => '🪶 Tickle', run: state => {
						state.giggles++;
						state.blinkUntil = performance.now() + 250;
						// A tickle only giggles out loud while the sound is on, as the button does not say that it plays sound.
						if (this.#isSoundOn()) {
							speak(state.giggles > 2 ? 'Hee hee hee! Boo! Boo!' : 'Hee hee hee!', {lang: 'en-US', pitch: 2, rate: 1.2});
						}

						this.say(state.giggles > 2 ? 'Furby has had enough tickles. “Boo” means no.' : 'Furby giggles.');
						setTimeout(() => {
							this.#drawMedia();
						}, 300);
					}},
				],
				isMoving: () => false,
				draw(context, state) {
					const {width, height} = context.canvas;
					context.fillStyle = '#f0e8ff';
					context.fillRect(0, 0, width, height);
					context.fillStyle = '#c8a0e0';
					context.fillRect(0, 128, width, 22);

					// The ears, the body, the face, the eyes, and the beak, to the left of the speech balloon.
					context.save();
					context.translate(-30, 0);
					context.fillStyle = '#7a4aa0';
					context.beginPath();
					context.moveTo(66, 60);
					context.lineTo(40, 6);
					context.lineTo(88, 44);
					context.moveTo(124, 44);
					context.lineTo(172, 6);
					context.lineTo(146, 60);
					context.fill();
					context.beginPath();
					context.ellipse(106, 88, 52, 52, 0, 0, Math.PI * 2);
					context.fill();
					context.fillStyle = '#f4e0f8';
					context.beginPath();
					context.ellipse(106, 82, 34, 30, 0, 0, Math.PI * 2);
					context.fill();
					const isBlinking = performance.now() < state.blinkUntil;

					for (const x of [92, 120]) {
						context.fillStyle = '#ffffff';
						context.beginPath();
						context.arc(x, 74, 11, 0, Math.PI * 2);
						context.fill();

						if (isBlinking) {
							context.fillStyle = '#7a4aa0';
							context.fill();
						} else {
							context.fillStyle = '#2a60c0';
							context.beginPath();
							context.arc(x, 76, 6, 0, Math.PI * 2);
							context.fill();
							context.fillStyle = '#000000';
							context.beginPath();
							context.arc(x, 76, 3, 0, Math.PI * 2);
							context.fill();
						}
					}

					context.fillStyle = '#ffa020';
					context.beginPath();
					context.moveTo(98, 90);
					context.lineTo(114, 90);
					context.lineTo(106, 104);
					context.fill();
					context.fillStyle = '#ffa020';
					context.fillRect(76, 136, 18, 6);
					context.fillRect(118, 136, 18, 6);
					context.restore();

					if (state.word >= 0) {
						const [word, meaning] = furbish[state.word];
						context.fillStyle = '#ffffff';
						context.strokeStyle = '#000000';
						context.lineWidth = 1.5;
						context.beginPath();
						context.roundRect(130, 36, 106, 50, 8);
						context.fill();
						context.stroke();
						context.fillStyle = '#000000';
						context.textAlign = 'center';
						context.font = 'bold 11px "Comic Sans MS", cursive';
						context.fillText(word, 183, 55, 98);
						context.font = '10px "Comic Sans MS", cursive';
						context.fillText(`(${meaning})`, 183, 73, 98);
						context.textAlign = 'left';
					}
				},
			},
		},
	};

	#articleIds = Object.keys(this.#articles);

	// The media of the article that is open.
	#media;
	#mediaLoop;

	#drawMedia(time = performance.now()) {
		if (!this.#media) {
			return;
		}

		const article = this.#articles[this.#media.id];
		article.media.draw(this.#mediaContext, this.#media.state, time);
	}

	#isMediaMoving() {
		return this.#media && !this.parts.article.hidden && this.#canMove() && this.#articles[this.#media.id].media.isMoving(this.#media.state);
	}

	#runMediaLoop() {
		if (this.#isMediaMoving()) {
			this.#mediaLoop.start();
		} else {
			this.#drawMedia();
		}
	}

	// The state of the media changes, so the picture, the buttons, and the motion follow it.
	#updateMedia() {
		if (!this.#media) {
			return;
		}

		for (const [index, action] of this.#articles[this.#media.id].media.actions.entries()) {
			this.parts.mediaActions.children[index].textContent = action.label(this.#media.state);
		}

		this.#runMediaLoop();
	}

	#playAnthem(state) {
		const {beat, notes, lyrics} = anthem;
		let time = 0.1;
		const cues = [];
		const lineStarts = [0, 8, 16, 24];

		this.#startClip({
			name: 'anthem',
			duration: notesLength(notes, beat) + 0.3,
			build: output => {
				let beats = 0;

				for (const [note, length] of notes) {
					if (note) {
						const frequency = noteFrequency(note);
						output.tone(frequency, time, (length * beat) - 0.03, {type: 'triangle', volume: 0.14});
						output.tone(frequency * 2, time, (length * beat) - 0.03, {type: 'sine', volume: 0.03});
						output.tone(frequency / 2, time, (length * beat) - 0.03, {type: 'square', volume: 0.02});
					}

					const lineIndex = lineStarts.indexOf(beats);

					if (lineIndex !== -1) {
						cues.push([time, () => {
							state.line = lineIndex;
							this.#drawMedia();
						}]);
					}

					beats += length;
					time += length * beat;
				}
			},
			cues,
			onEnd: () => {
				state.playing = false;
				state.line = -1;
				this.#updateMedia();
			},
		});

		if (this.#clip?.name === 'anthem') {
			state.playing = true;
			this.say(`🎵 “Ja, vi elsker dette landet”, the national anthem of Norway, by Rikard Nordraak. ${lyrics.join(' ')}`);
		}
	}

	#playGrieg(state) {
		let time = 0.1;

		this.#startClip({
			name: 'grieg',
			duration: 22,
			build: output => {
				// The tune gets faster and louder each time, like in Peer Gynt, and goes up an octave at the end.
				for (let round = 0; round < 4; round++) {
					const eighth = 0.24 - (round * 0.04);
					const octave = round >= 2 ? 2 : 1;

					for (const [note, length] of mountainKingPhrase) {
						const frequency = noteFrequency(note) * octave;
						output.tone(frequency, time, Math.min(length * eighth, 0.3), {type: round === 0 ? 'triangle' : 'square', volume: 0.04 + (round * 0.025)});

						if (round > 0) {
							output.tone(frequency / 2, time, 0.08, {type: 'triangle', volume: 0.05});
						}

						time += length * eighth;
					}
				}

				output.tone(noteFrequency('B2'), time, 0.6, {type: 'sawtooth', volume: 0.1});
				output.noise(time, 0.5, {frequency: 200, volume: 0.15});
			},
			onEnd: () => {
				state.playing = false;
				this.#updateMedia();
			},
		});

		if (this.#clip?.name === 'grieg') {
			state.playing = true;
			this.say('🎵 “In the Hall of the Mountain King”, by Edvard Grieg of Bergen. It gets faster. Hold on to your umbrella.');
		}
	}

	#changeRain(state) {
		state.rain = state.rain === 4 ? 0 : state.rain + 1;
		this.#noise(0, 0.6, {frequency: 6000, quality: 0.3, volume: 0.01 + (state.rain * 0.01)});
		this.say(state.rain === 0 ? 'The sun comes out! All of Bergen runs outside. (This happens twice a year.)' : (state.rain === 4 ? 'Øsregn: it pours down. A normal Tuesday in Bergen.' : 'More rain. The people of Bergen do not notice.'));
	}

	#bakeWaffle(state) {
		if (state.baked === 3 || state.eaten === 5) {
			Object.assign(state, {baked: 0, eaten: 0, cheese: false});
			this.say('Mormor pours new batter into the waffle iron.');
			return;
		}

		state.baked++;
		this.#sounds.sizzle();
		this.say(['', 'Golden. Mormor says it needs a little more.', 'Brown and crispy. Perfect! Add brunost.', 'Burnt! The smoke alarm beeps, and Mamma opens all the windows.'][state.baked]);

		if (state.baked === 3) {
			for (let index = 0; index < 3; index++) {
				this.#tone(3200, index * 0.3, 0.15, {type: 'square', volume: 0.03});
			}
		}
	}

	#eatWaffle(state) {
		if (state.eaten === 5) {
			this.say('There is nothing left. Lillesøster ate the last heart.');
			return;
		}

		if (state.baked === 0) {
			this.say('Raw batter! Mormor takes the waffle away. Bake it first.');
			return;
		}

		state.eaten++;
		this.#tone(220, 0, 0.08, {type: 'square', volume: 0.04});
		this.say(state.baked === 3 ? 'Crunch. It tastes like charcoal.' : (state.eaten === 5 ? 'All five hearts are gone. Nam!' : `Nam nam! ${5 - state.eaten} hearts are left${state.cheese ? '' : ', and they need brunost'}.`));
	}

	async #rollOver(state) {
		if (state.running) {
			return;
		}

		if (state.rolled) {
			Object.assign(state, {rolled: false, seconds: 55});
			this.say('Back to December 31, 1999. Phew.');
			return;
		}

		state.running = true;

		// The last seconds tick one by one, unless the visitor prefers less motion. Leaving the article stops the clock.
		if (!this.reducedMotion) {
			while (state.seconds < 59) {
				await this.#wait(700);

				if (this.#media?.state !== state) {
					return;
				}

				state.seconds++;
				this.#tone(1000, 0, 0.05, {type: 'square', volume: 0.03});
				this.#drawMedia();
			}

			await this.#wait(700);
		}

		if (this.#media?.state !== state) {
			return;
		}

		state.running = false;
		state.rolled = true;
		this.#tone(220, 0, 0.6, {type: 'sawtooth', volume: 0.06, slide: 110});
		this.say('Midnight! The computer thinks it is January 1, 1900. Better bring a horse.');
		this.#updateMedia();
	}

	#connectModem(state) {
		const setPhase = (phase, line) => () => {
			state.phase = phase;
			state.line = line;
			this.#updateMedia();
		};

		this.#startClip({
			name: 'modem',
			duration: 9.4,
			build: output => {
				output.tone(350, 0, 0.9, {type: 'sine', volume: 0.06});
				output.tone(440, 0, 0.9, {type: 'sine', volume: 0.06});

				for (const [index, digit] of [...dialNumber].entries()) {
					const start = 1 + (index * 0.16);

					for (const frequency of dtmf[digit]) {
						output.tone(frequency, start, 0.1, {type: 'sine', volume: 0.06});
					}
				}

				// The other modem answers, and they screech until they agree.
				output.tone(2100, 3, 1.4, {type: 'sine', volume: 0.05});

				for (let index = 0; index < 6; index++) {
					output.tone(index % 2 === 0 ? 980 : 1180, 4.5 + (index * 0.1), 0.1, {type: 'square', volume: 0.03});
				}

				output.tone(1200, 5.2, 0.4, {type: 'sine', volume: 0.05});
				output.tone(2400, 5.2, 0.4, {type: 'sine', volume: 0.04});
				output.noise(5.6, 2.2, {frequency: 1800, quality: 0.7, volume: 0.07});
				output.tone(1800, 6.2, 0.3, {type: 'square', volume: 0.02, slide: 600});
				output.tone(600, 6.7, 0.3, {type: 'square', volume: 0.02, slide: 1900});
				output.noise(7.9, 1.2, {frequency: 3000, quality: 0.5, volume: 0.04});
			},
			cues: [
				[0, setPhase('dialing', 'ATDT 55 31 40 00')],
				[3, setPhase('handshake', 'EEEE-KRRR-SHHHH...')],
				[9.2, setPhase('online', 'CONNECT 49333/ARQ/V90')],
			],
			onEnd: () => {
				if (state.phase !== 'online' && state.phase !== 'dropped') {
					state.phase = 'idle';
					state.line = 'READY';
					this.#updateMedia();
				}
			},
		});

		if (this.#clip?.name === 'modem') {
			this.say('ATDT… The modem dials the Internet. Nobody pick up the phone!');
		}
	}

	#hangUp(state) {
		this.#stopClip();
		state.phase = 'idle';
		state.line = 'ATH0 OK';
		this.say('The modem hangs up. The phone line is free again.');
	}

	#mammaPicksUp(state) {
		if (state.phase === 'idle' || state.phase === 'dropped') {
			this.say('Mamma picks up the phone, hears the dial tone, and calls Mormor. Nothing happens to the Internet, as you are not on it.');
			return;
		}

		// The modem only leaves idle after a press of Connect, which plays its sound, so Mamma may speak.
		this.#stopClip();
		state.phase = 'dropped';
		state.line = 'NO CARRIER';
		this.#tone(900, 0, 0.05, {type: 'square', volume: 0.05});
		speak('Sindre! Jeg må ringe Mormor!', {lang: 'nb-NO', pitch: 1.2, rate: 1});
		this.say('Mamma picks up the phone: “Sindre! Jeg må ringe Mormor!” (I need to call Mormor!) NO CARRIER.');
	}

	// The navigation of Encarta: the places, the disc in the drive, and Back.
	#views;
	#currentPlace;
	#history = [];
	#disc = 1;
	#discSwaps = 0;
	#isBusy = false;

	#discOf(place) {
		if (place.startsWith('article:')) {
			return this.#articles[place.slice('article:'.length)].disc;
		}

		return {timeline: 2, maze: 1}[place];
	}

	#showView(name) {
		for (const [viewName, element] of Object.entries(this.#views)) {
			element.hidden = viewName !== name;
		}

		for (const button of this.#goButtons) {
			if (button.dataset.encartaGo === name) {
				button.dataset.state = 'current';
			} else {
				delete button.dataset.state;
			}
		}

		this.parts.back.disabled = this.#history.length === 0;
	}

	async #runSplash(lines, totalTime) {
		this.#showView('splash');
		this.parts.progress.style.width = '0';

		if (this.reducedMotion) {
			this.parts.splashText.textContent = lines.at(-1);
			this.parts.progress.style.width = '100%';
			return;
		}

		this.parts.disc.dataset.state = 'spinning';
		this.#sounds.whirr();

		for (const [index, line] of lines.entries()) {
			this.parts.splashText.textContent = line;
			this.parts.progress.style.width = `${Math.round(((index + 1) / lines.length) * 100)}%`;
			await this.#wait(totalTime / lines.length);
		}

		delete this.parts.disc.dataset.state;
	}

	// Encarta 99 Deluxe came on two discs, so going to something on the other disc asks for it, like the real one.
	async #swapDisc(wanted) {
		const texts = [
			`Please insert Encarta Encyclopedia Deluxe 99 Disc ${wanted} into drive D:.`,
			`Please insert Disc ${wanted} into drive D:. Again.`,
			`Please insert Disc ${wanted}. Tip: If Lillesøster used it as a coaster, wipe off the juice first.`,
			`Please insert Disc ${wanted}. You have now changed discs ${this.#discSwaps} times. Encarta needs 580 MB to copy both discs to the hard disk, and you have 212 MB free.`,
		];

		const answer = await this.ask({
			text: texts[Math.min(this.#discSwaps, texts.length - 1)],
			buttons: ['OK', 'Cancel'],
			details: 'Disc 1 has the Pinpointer, the articles about Norway, Bergen, the waffle, and the unicorn, and MindMaze. Disc 2 has the timeline and the newest articles, about the year 2000 problem, the Internet, the modem, and Furby.',
		});

		if (answer !== 'OK') {
			this.say(`Encarta stays with Disc ${this.#disc}.`);
			return false;
		}

		this.#discSwaps++;
		this.#disc = wanted;
		await this.#runSplash([`Reading Disc ${wanted}…`, 'Checking drive D:…', `Disc ${wanted} is ready.`], 1000);
		return true;
	}

	async #go(place, {isBack = false} = {}) {
		if (this.#isBusy || place === this.#currentPlace) {
			return false;
		}

		this.#isBusy = true;
		// A result, a link, or a button of the old place is hidden after the move, so its focus moves to the new place.
		const hadFocus = Object.values(this.#views).some(element => element.contains(document.activeElement));

		try {
			const wantedDisc = this.#discOf(place);

			if (wantedDisc && wantedDisc !== this.#disc) {
				if (!await this.#swapDisc(wantedDisc)) {
					return false;
				}
			}

			if (!isBack && this.#currentPlace && this.#currentPlace !== 'splash') {
				this.#history.push(this.#currentPlace);
				this.#history = this.#history.slice(-30);
			}

			this.#leavePlace();
			this.#currentPlace = place;
			this.#showPlace(place);

			if (hadFocus) {
				const target = place.startsWith('article:') ? this.parts.article : {home: this.parts.search, timeline: this.parts.timelineStrip, maze: this.parts.mazeScreen}[place];
				target.focus({preventScroll: true});
			}

			return true;
		} finally {
			this.#isBusy = false;
		}
	}

	// Leaving an article stops its media, so a clock that ticks or a tune does not go on behind another place.
	#leavePlace() {
		if (this.#currentPlace?.startsWith('article:')) {
			this.#stopClip();
			this.#media = undefined;

			if (canSpeak) {
				speechSynthesis.cancel();
			}
		}

		this.#stopTravel();
	}

	#showPlace(place) {
		if (place.startsWith('article:')) {
			this.#showView('article');
			this.#renderArticle(place.slice('article:'.length));
			return;
		}

		this.#showView(place);

		if (place === 'home') {
			this.say(`Welcome to Encarta 99. Disc ${this.#disc} is in drive D:. Type in the Pinpointer to find an article.`);
		} else if (place === 'timeline') {
			this.#showEvent(this.#timelineIndex, {isQuiet: true});
			this.say('The timeline, from the big bang to 1999. Step through it, or jump to an era.');
		} else if (place === 'maze') {
			this.#enterMaze();
		}
	}

	// The Pinpointer finds the articles that have the words, in the title first.
	#renderResults() {
		const words = this.parts.search.value.trim().toLocaleLowerCase('en-US');
		const category = this.parts.category.value;
		const matches = this.#articleIds
			.filter(id => category === 'All categories' || this.#articles[id].category === category)
			.map(id => {
				const article = this.#articles[id];
				const text = [article.title, article.keywords, ...article.paragraphs].join(' ').toLocaleLowerCase('en-US');
				const isInTitle = article.title.toLocaleLowerCase('en-US').includes(words);
				return {id, isInTitle, isMatch: words === '' || text.includes(words)};
			})
			.filter(result => result.isMatch);

		const sorted = [...matches.filter(result => result.isInTitle), ...matches.filter(result => !result.isInTitle)];
		this.parts.results.replaceChildren();

		for (const {id} of sorted) {
			const item = fromTemplate(this.parts.resultTemplate);
			const button = item.querySelector('button');
			const [icon, title, categoryName] = button.children;
			icon.textContent = this.#articles[id].icon;
			title.textContent = this.#articles[id].title;
			categoryName.textContent = `Disc ${this.#articles[id].disc} ★ ${this.#articles[id].category}`;
			button.dataset.article = id;
			this.parts.results.append(item);
		}

		if (sorted.length > 0) {
			this.parts.resultsCount.textContent = words ? `${sorted.length} of ${this.#articleIds.length} articles ${sorted.length === 1 ? 'has' : 'have'} “${this.parts.search.value.trim()}”.` : `${this.#articleIds.length} articles. Lillesøster borrowed the disc with the other 36,992.`;
			return;
		}

		const funny = [
			[/sindre/u, 'Encarta has no article about Sindre yet. Maybe in Encarta 2000, when he is famous.'],
			[/titanic/u, 'The Titanic sank. So did this search.'],
			[/kiss|love/u, 'Mamma is standing behind you.'],
		].find(([pattern]) => pattern.test(words));

		this.parts.resultsCount.textContent = funny?.[1] ?? `Encarta has no article with “${this.parts.search.value.trim()}”. Try “rain” or “1999”.`;
	}

	// The fact of the home screen comes from any article.
	#homeFactArticle;

	#showHomeFact() {
		const id = randomItem(this.#articleIds.filter(id => id !== this.#homeFactArticle));
		this.#homeFactArticle = id;
		this.parts.homeFact.textContent = randomItem(this.#articles[id].facts);
		this.parts.homeFactRead.textContent = `Read “${this.#articles[id].title}”`;
	}

	// An article: its text, its media, its fact, and its links.
	#factIndex = 0;

	#linkButton(title, action) {
		const button = fromTemplate(this.parts.linkTemplate);
		button.textContent = title;
		button.addEventListener('click', action);
		return button;
	}

	#renderArticle(id) {
		const article = this.#articles[id];
		this.parts.articleCategory.textContent = `${article.category} ★ Disc ${article.disc}`;
		this.parts.articleTitle.textContent = article.title;
		this.parts.pronunciation.textContent = `Pronunciation: ${article.pronunciation}`;
		this.parts.articleBody.replaceChildren(...article.paragraphs.map(text => {
			const paragraph = document.createElement('p');
			paragraph.textContent = text;
			return paragraph;
		}));
		this.#factIndex = 0;
		this.parts.articleFact.textContent = article.facts[0];
		this.parts.seeAlso.replaceChildren(...article.seeAlso.map(other => this.#linkButton(`${this.#articles[other].icon} ${this.#articles[other].title}`, () => {
			this.#sounds.page();
			this.#go(`article:${other}`);
		})));
		this.#media = {id, state: article.media.start()};
		this.parts.mediaCaption.textContent = article.media.caption;
		this.parts.media.setAttribute('aria-label', article.media.label);
		this.parts.mediaActions.replaceChildren(...article.media.actions.map(action => {
			const button = fromTemplate(this.parts.actionTemplate);

			button.addEventListener('click', () => {
				const state = this.#media.state;
				this.#sounds.click();
				action.run(state);
				this.#updateMedia();
			});

			return button;
		}));
		this.#updateMedia();
		this.parts.article.scrollTop = 0;
		this.say(`${article.title}. ${article.paragraphs[0].split('. ')[0]}.`);
	}

	#timelineIndex = 0;
	#eventElements;

	#showEvent(index, {isQuiet = false} = {}) {
		this.#timelineIndex = clamp(index, 0, events.length - 1);

		for (const [eventIndex, element] of this.#eventElements.entries()) {
			if (eventIndex === this.#timelineIndex) {
				element.dataset.state = 'current';
			} else {
				delete element.dataset.state;
			}
		}

		const element = this.#eventElements[this.#timelineIndex];
		const stripBox = this.parts.timelineStrip.getBoundingClientRect();
		const box = element.getBoundingClientRect();
		const left = this.parts.timelineStrip.scrollLeft + (box.left - stripBox.left) - ((this.parts.timelineStrip.clientWidth - box.width) / 2);
		this.parts.timelineStrip.scrollTo({left, behavior: this.reducedMotion || isQuiet ? 'auto' : 'smooth'});
		const [date, , text] = events[this.#timelineIndex];
		this.parts.timelineYear.textContent = date;
		this.parts.timelineEarlier.disabled = this.#timelineIndex === 0;
		this.parts.timelineLater.disabled = this.#timelineIndex === events.length - 1;

		if (!isQuiet) {
			this.say(`${date}: ${text}`);
		}
	}

	#travelRun = 0;

	#stopTravel() {
		this.#travelRun++;
		this.parts.timelinePlay.setAttribute('aria-pressed', 'false');
		this.parts.timelinePlay.textContent = '🚀 Travel to 1999';
	}

	#step(offset) {
		this.#stopTravel();
		this.#showEvent(this.#timelineIndex + offset);
		this.#tone(offset > 0 ? 880 : 660, 0, 0.06, {volume: 0.05});
	}

	#game;
	#maze = {animation: undefined, popStart: 0};
	#mazeLoop;
	#balloonTimer;
	#record;

	#passageOf(cell, direction) {
		const other = neighbor(cell, direction);
		return other === undefined ? undefined : this.#game.passages.get(passageKey(cell, other));
	}

	#newGame() {
		// The castle is a random maze, with a few extra doors, so there is more than one way.
		const passages = new Map();
		const visited = new Set([startCell]);
		const stack = [startCell];

		while (stack.length > 0) {
			const cell = stack.at(-1);
			const options = [0, 1, 2, 3].map(direction => neighbor(cell, direction)).filter(other => other !== undefined && !visited.has(other));

			if (options.length === 0) {
				stack.pop();
				continue;
			}

			const next = randomItem(options);
			passages.set(passageKey(cell, next), {state: 'closed'});
			visited.add(next);
			stack.push(next);
		}

		let extras = 0;

		while (extras < 4) {
			const cell = Math.floor(Math.random() * size * size);
			const other = neighbor(cell, Math.floor(Math.random() * 4));

			if (other !== undefined && !passages.has(passageKey(cell, other))) {
				passages.set(passageKey(cell, other), {state: 'closed'});
				extras++;
			}
		}

		const middleCells = shuffled(Array.from({length: size * size}, (_, cell) => cell).filter(cell => cell !== startCell && cell !== throneCell));
		const themes = new Map([[startCell, gateTheme], [throneCell, throneTheme]]);
		const otherThemes = shuffled(roomThemes);

		for (const [index, cell] of middleCells.entries()) {
			themes.set(cell, index === 0 ? kitchenTheme : otherThemes[index - 1]);
		}

		const people = new Map([[middleCells[0], 'mormor'], [middleCells[1], 'jester'], [middleCells[2], 'knight'], [middleCells[3], 'ghost'], [throneCell, 'king']]);

		this.#game = {
			passages,
			themes,
			people,
			met: new Set(),
			cell: startCell,
			facing: [0, 1, 2, 3].find(direction => passages.has(passageKey(startCell, neighbor(startCell, direction) ?? -1))),
			visited: new Set([startCell]),
			isMapRevealed: false,
			score: 0,
			cards: 0,
			questionPool: shuffled(questions),
			riddlePool: shuffled(riddles),
			kingPool: shuffled(kingQuestions),
			question: undefined,
			isKnighted: false,
			isRiddleSolved: false,
			isBusy: false,
			jokeIndex: 0,
		};

		this.#closeQuestion();
		this.parts.mazeBalloon.hidden = true;
		this.#maze.animation = undefined;
		this.#updateHud();
		this.#drawMaze();
	}

	#rankOf(score) {
		return this.#game?.isKnighted ? 'Knight' : ranks.findLast(([minimum]) => score >= minimum)[1];
	}

	#updateHud() {
		this.parts.mazeScore.textContent = `${this.#game.score.toLocaleString('en-US')} points ★ ${this.#rankOf(this.#game.score)} ★ Rooms ${this.#game.visited.size}/${size * size}${this.#game.cards > 0 ? ` ★ 🃏×${this.#game.cards}` : ''}`;

		for (const button of this.#doorButtons) {
			const side = button.dataset.encartaDoor;

			if (side === 'back') {
				continue;
			}

			const direction = (this.#game.facing + sides[side] + 4) % 4;
			const passage = this.#passageOf(this.#game.cell, direction);
			const where = {left: 'on the left', front: 'ahead', right: 'on the right'}[side];
			button.disabled = !passage;
			button.setAttribute('aria-label', passage ? `Door ${where} (${passage.state})` : `No door ${where}`);
		}

		const person = this.#game.people.get(this.#game.cell);
		this.parts.mazeTalk.hidden = !person;
		this.parts.mazeTalk.setAttribute('aria-label', person ? `Talk to ${characters[person].name.replace('The ', 'the ')}` : 'Talk');
	}

	#addPoints(points) {
		const before = this.#rankOf(this.#game.score);
		this.#game.score = Math.max(0, this.#game.score + points);
		const after = this.#rankOf(this.#game.score);
		this.#updateHud();

		if (before !== after && points > 0) {
			this.#sounds.rank();
			this.toast(`🏰 MindMaze: you are now a ${after}!`);
		}
	}

	#speech(who, text) {
		const character = characters[who];
		this.parts.mazeBalloon.textContent = `${character.icon} ${character.name}: ${text}`;
		this.parts.mazeBalloon.hidden = false;
		clearTimeout(this.#balloonTimer);
		this.#balloonTimer = setTimeout(() => {
			this.parts.mazeBalloon.hidden = true;
		}, 6500);
	}

	#drawCharacter(context, who, time) {
		const rise = this.#maze.popStart && !this.reducedMotion ? clamp((time - this.#maze.popStart) / 400, 0, 1) : 1;
		const bob = who === 'ghost' && this.#canMove() ? Math.sin(time / 300) * 4 : 0;
		const x = 168;
		const feet = 296 + ((1 - rise) * 110) + bob;
		context.save();
		context.beginPath();
		context.rect(0, 0, 480, 300);
		context.clip();
		context.translate(x, feet);

		// A shadow on the floor.
		context.fillStyle = 'rgba(0, 0, 0, 0.35)';
		context.beginPath();
		context.ellipse(0, -2 - bob, 30, 6, 0, 0, Math.PI * 2);
		context.fill();

		if (who === 'ghost') {
			context.globalAlpha = 0.85;
			context.fillStyle = '#f4f4ff';
			context.beginPath();
			context.moveTo(-28, -10);
			context.lineTo(-28, -70);
			context.arc(0, -70, 28, Math.PI, 0);
			context.lineTo(28, -10);

			for (let wave = 0; wave < 4; wave++) {
				context.quadraticCurveTo(21 - (wave * 14), wave % 2 === 0 ? 2 : -18, 14 - (wave * 14), -10);
			}

			context.fill();
			context.fillStyle = '#000000';

			for (const eye of [-10, 10]) {
				context.beginPath();
				context.ellipse(eye, -72, 5, 8, 0, 0, Math.PI * 2);
				context.fill();
			}

			context.beginPath();
			context.ellipse(0, -50, 7, 9, 0, 0, Math.PI * 2);
			context.fill();
			context.restore();
			return;
		}

		const outfits = {
			jester: {body: '#c02020', other: '#f0c020', skin: '#f0c8a0'},
			knight: {body: '#a0a8b0', other: '#707880', skin: '#a0a8b0'},
			mormor: {body: '#5a6aa0', other: '#ffffff', skin: '#f0c8a0'},
			king: {body: '#a01030', other: '#ffffff', skin: '#f0c8a0'},
		}[who];

		// The legs, the body, the arms, and the head.
		context.fillStyle = who === 'jester' ? outfits.other : '#3a3a3a';
		context.fillRect(-14, -34, 10, 34);
		context.fillStyle = who === 'jester' ? outfits.body : '#3a3a3a';
		context.fillRect(4, -34, 10, 34);
		context.fillStyle = outfits.body;
		context.beginPath();
		context.moveTo(-22, -34);
		context.lineTo(-18, -84);
		context.lineTo(18, -84);
		context.lineTo(22, -34);
		context.closePath();
		context.fill();

		if (who === 'jester') {
			context.fillStyle = outfits.other;
			context.beginPath();
			context.moveTo(0, -84);
			context.lineTo(18, -59);
			context.lineTo(0, -34);
			context.lineTo(-18, -59);
			context.closePath();
			context.fill();
		} else if (who === 'mormor') {
			context.fillStyle = outfits.other;
			context.fillRect(-12, -70, 24, 36);
		} else if (who === 'king') {
			context.fillStyle = outfits.other;
			context.fillRect(-4, -84, 8, 50);
			context.fillRect(-22, -40, 44, 6);
		}

		context.fillStyle = outfits.body;
		context.fillRect(-28, -82, 8, 32);
		context.fillRect(20, -82, 8, 32);
		context.fillStyle = outfits.skin;
		context.beginPath();
		context.arc(0, -98, 15, 0, Math.PI * 2);
		context.fill();

		if (who === 'knight') {
			context.fillStyle = '#202020';
			context.fillRect(-11, -101, 22, 4);
			context.fillStyle = '#d02020';
			context.beginPath();
			context.ellipse(0, -118, 5, 10, 0, 0, Math.PI * 2);
			context.fill();
			context.strokeStyle = '#d8dce0';
			context.lineWidth = 4;
			context.beginPath();
			context.moveTo(30, -50);
			context.lineTo(30, -120);
			context.stroke();
			context.strokeStyle = '#806020';
			context.beginPath();
			context.moveTo(22, -56);
			context.lineTo(38, -56);
			context.stroke();
		} else {
			context.fillStyle = '#000000';

			for (const eye of [-5, 5]) {
				context.beginPath();
				context.arc(eye, -100, 2, 0, Math.PI * 2);
				context.fill();
			}

			context.strokeStyle = '#802020';
			context.lineWidth = 1.5;
			context.beginPath();
			context.arc(0, -95, 6, 0.2, Math.PI - 0.2);
			context.stroke();
		}

		if (who === 'jester') {
			for (const [tipX, tipY, color] of [[-24, -122, '#c02020'], [0, -132, '#f0c020'], [24, -122, '#2040c0']]) {
				context.fillStyle = color;
				context.beginPath();
				context.moveTo(-12, -108);
				context.lineTo(tipX, tipY);
				context.lineTo(12, -108);
				context.fill();
				context.fillStyle = '#ffd700';
				context.beginPath();
				context.arc(tipX, tipY, 3.5, 0, Math.PI * 2);
				context.fill();
			}
		} else if (who === 'mormor') {
			context.fillStyle = '#d0d0d0';
			context.beginPath();
			context.arc(0, -108, 14, Math.PI, 0);
			context.arc(0, -118, 7, 0, Math.PI * 2);
			context.fill();
			context.strokeStyle = '#303030';
			context.lineWidth = 1;

			for (const eye of [-5, 5]) {
				context.beginPath();
				context.arc(eye, -100, 4, 0, Math.PI * 2);
				context.stroke();
			}

			// A plate with a waffle.
			context.fillStyle = '#ffffff';
			context.beginPath();
			context.ellipse(-30, -56, 16, 5, 0, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#d89a40';
			context.save();
			context.translate(-30, -62);
			heartPath(context, 16);
			context.fill();
			context.restore();
		} else if (who === 'king') {
			context.fillStyle = '#ffd700';
			context.beginPath();
			context.moveTo(-14, -110);
			context.lineTo(-14, -126);
			context.lineTo(-7, -118);
			context.lineTo(0, -130);
			context.lineTo(7, -118);
			context.lineTo(14, -126);
			context.lineTo(14, -110);
			context.closePath();
			context.fill();
			context.fillStyle = '#e8e8e8';
			context.beginPath();
			context.moveTo(-10, -92);
			context.quadraticCurveTo(0, -70, 10, -92);
			context.fill();
		}

		context.restore();
	}

	#drawTorch(context, x, y, time) {
		context.fillStyle = '#4a3020';
		context.fillRect(x - 3, y, 6, 18);
		const flicker = this.#canMove() ? Math.sin(time / 70) + Math.sin(time / 43) : 0;
		const glow = context.createRadialGradient(x, y - 6, 2, x, y - 6, 40 + (flicker * 3));
		glow.addColorStop(0, 'rgba(255, 200, 80, 0.35)');
		glow.addColorStop(1, 'rgba(255, 200, 80, 0)');
		context.fillStyle = glow;
		context.fillRect(x - 45, y - 50, 90, 90);
		context.fillStyle = '#ff9a20';
		context.beginPath();
		context.ellipse(x, y - 6, 5 + (flicker * 0.6), 10 + flicker, 0, 0, Math.PI * 2);
		context.fill();
		context.fillStyle = '#fff060';
		context.beginPath();
		context.ellipse(x, y - 3, 2.5, 5, 0, 0, Math.PI * 2);
		context.fill();
	}

	#drawRoom(context, time) {
		const theme = this.#game.themes.get(this.#game.cell);
		const stone = theme.stone;

		// The ceiling, the floor, the side walls, and the back wall, each in its own light.
		const faces = [
			[[0, 0], [480, 0], [back.right, back.top], [back.left, back.top], 0.35],
			[[0, 300], [480, 300], [back.right, back.bottom], [back.left, back.bottom], 0.55],
			[[0, 0], [back.left, back.top], [back.left, back.bottom], [0, 300], 0.7],
			[[480, 0], [back.right, back.top], [back.right, back.bottom], [480, 300], 0.7],
		];

		for (const [first, second, third, fourth, light] of faces) {
			context.fillStyle = shade(stone, light);
			context.beginPath();
			context.moveTo(...first);
			context.lineTo(...second);
			context.lineTo(...third);
			context.lineTo(...fourth);
			context.closePath();
			context.fill();
		}

		context.fillStyle = shade(stone, 0.9);
		context.fillRect(back.left, back.top, back.right - back.left, back.bottom - back.top);

		// The mortar of the stones.
		context.strokeStyle = 'rgba(0, 0, 0, 0.22)';
		context.lineWidth = 1;

		for (let row = 0; row <= 10; row++) {
			const y = back.top + (row * 14.5);
			context.beginPath();
			context.moveTo(back.left, y);
			context.lineTo(back.right, y);
			context.stroke();

			for (let column = 0; column < 7; column++) {
				const x = back.left + ((column + (row % 2 === 0 ? 0.5 : 0)) * 30);

				if (x > back.left && x < back.right && row < 10) {
					context.beginPath();
					context.moveTo(x, y);
					context.lineTo(x, y + 14.5);
					context.stroke();
				}
			}

			const fraction = row / 10;
			context.beginPath();
			context.moveTo(0, fraction * 300);
			context.lineTo(back.left, back.top + (fraction * (back.bottom - back.top)));
			context.moveTo(480, fraction * 300);
			context.lineTo(back.right, back.top + (fraction * (back.bottom - back.top)));
			context.stroke();
		}

		// The flagstones of the floor.
		for (let line = 0; line <= 8; line++) {
			context.beginPath();
			context.moveTo(line * 60, 300);
			context.lineTo(back.left + (line * 22.5), back.bottom);
			context.stroke();
		}

		for (const y of [222, 234, 252, 278]) {
			const fraction = (y - back.bottom) / (300 - back.bottom);
			context.beginPath();
			context.moveTo(back.left * (1 - fraction), y);
			context.lineTo(480 - (back.left * (1 - fraction)), y);
			context.stroke();
		}

		if (this.#game.cell === throneCell) {
			// A red carpet to the throne.
			context.fillStyle = '#a01020';
			context.beginPath();
			context.moveTo(200, 300);
			context.lineTo(280, 300);
			context.lineTo(258, back.bottom);
			context.lineTo(222, back.bottom);
			context.fill();
		}

		// The pictures on the back wall, beside the door.
		context.font = '22px sans-serif';
		context.textAlign = 'center';
		context.textBaseline = 'middle';

		for (const [index, x] of [178, 302].entries()) {
			context.fillStyle = '#5a3a1a';
			context.fillRect(x - 17, 92, 34, 34);
			context.fillStyle = '#e8dcc0';
			context.fillRect(x - 14, 95, 28, 28);
			context.fillText(theme.decoration[index], x, 110);
		}

		// The name of the room on a banner.
		context.fillStyle = '#e8d8a0';
		context.fillRect(170, 8, 140, 22);
		context.strokeStyle = '#6a4a20';
		context.lineWidth = 2;
		context.strokeRect(170, 8, 140, 22);
		context.fillStyle = '#3a2010';
		context.font = 'bold 13px "Times New Roman", serif';
		context.fillText(theme.name, 240, 20);

		this.#drawTorch(context, 75, 70, time);
		this.#drawTorch(context, 405, 70, time + 500);

		// The doors on the three walls that the visitor sees.
		for (const side of ['front', 'left', 'right']) {
			const direction = (this.#game.facing + sides[side] + 4) % 4;
			const passage = this.#passageOf(this.#game.cell, direction);

			if (!passage) {
				continue;
			}

			const animation = this.#maze.animation?.side === side && this.#maze.animation.type === 'door' ? this.#maze.animation : undefined;
			const openness = passage.state === 'open' ? 1 : (animation ? clamp((time - animation.start) / animation.duration, 0, 1) : 0);

			if (side === 'front') {
				drawDoor(context, [[backDoor.left, backDoor.top], [backDoor.right, backDoor.top], [backDoor.right, backDoor.bottom], [backDoor.left, backDoor.bottom]], passage, openness, 22);
			} else {
				const door = sideDoor(side === 'right');
				drawDoor(context, [door.outerTop, door.innerTop, door.innerBottom, door.outerBottom], passage, openness, 12);
			}
		}

		const person = this.#game.people.get(this.#game.cell);

		if (person) {
			this.#drawCharacter(context, person, time);
		}

		// The compass in the corner says where the visitor looks.
		context.fillStyle = 'rgba(0, 0, 0, 0.55)';
		context.fillRect(6, 6, 64, 22);
		context.fillStyle = '#ffd700';
		context.font = 'bold 12px Arial, sans-serif';
		context.textAlign = 'left';
		context.fillText(`🧭 ${directionNames[this.#game.facing].toUpperCase()}`, 10, 18);
	}

	#drawMaze(time = performance.now()) {
		if (!this.#game) {
			return;
		}

		// The room is drawn 300 high, and squeezed into the canvas, which is a little lower so the window fits on the desktop.
		const context = this.#mazeContext;
		const squeeze = this.parts.mazeScreen.height / 300;
		const animation = this.#maze.animation;
		context.setTransform(1, 0, 0, squeeze, 0, 0);
		context.save();
		context.fillStyle = '#000000';
		context.fillRect(0, 0, 480, 300);

		if (animation?.type === 'walk') {
			// Walking zooms into the doorway, and the next room fades in.
			const progress = clamp((time - animation.start) / animation.duration, 0, 1);
			const zoom = 1 + (progress * 1.6);
			context.translate(animation.x, animation.y);
			context.scale(zoom, zoom);
			context.translate(-animation.x, -animation.y);
			this.#drawRoom(context, time);
			context.setTransform(1, 0, 0, squeeze, 0, 0);
			context.fillStyle = `rgba(0, 0, 0, ${progress})`;
			context.fillRect(0, 0, 480, 300);
		} else {
			this.#drawRoom(context, time);

			if (animation?.type === 'arrive' || animation?.type === 'turn') {
				const progress = clamp((time - animation.start) / animation.duration, 0, 1);
				context.fillStyle = `rgba(0, 0, 0, ${1 - progress})`;
				context.fillRect(0, 0, 480, 300);
			}
		}

		context.restore();

		if (this.#game.isKnighted) {
			textBox(context, '⚔️ You are a Knight of MindMaze! ⚔️', 240, 288, {font: 'bold 15px "Times New Roman", serif', color: '#ffd700', background: 'rgba(60, 0, 20, 0.85)'});
		}

		this.#drawMap();
	}

	#drawMap() {
		const context = this.#mazeMapContext;
		const cellSize = 26;
		const margin = 8;
		context.fillStyle = 'rgba(20, 14, 6, 0.85)';
		context.fillRect(0, 0, 120, 120);

		for (let cell = 0; cell < size * size; cell++) {
			const x = margin + ((cell % size) * cellSize);
			const y = margin + (Math.floor(cell / size) * cellSize);
			const isKnown = this.#game.visited.has(cell) || this.#game.isMapRevealed;

			if (!isKnown) {
				continue;
			}

			context.fillStyle = this.#game.visited.has(cell) ? '#c8b080' : '#6a5a40';
			context.fillRect(x + 1, y + 1, cellSize - 2, cellSize - 2);

			// The walls, with a gap for an open door and a mark for a closed one.
			for (const direction of [0, 1, 2, 3]) {
				const passage = this.#passageOf(cell, direction);
				const [fromX, fromY, toX, toY] = [[x, y, x + cellSize, y], [x + cellSize, y, x + cellSize, y + cellSize], [x, y + cellSize, x + cellSize, y + cellSize], [x, y, x, y + cellSize]][direction];
				context.strokeStyle = passage ? (passage.state === 'open' ? 'rgba(0, 0, 0, 0)' : (passage.state === 'locked' ? '#ff4040' : '#ffd700')) : '#1a1008';
				context.lineWidth = passage ? 2 : 3;

				if (passage && passage.state !== 'open') {
					context.setLineDash([3, 3]);
				}

				context.beginPath();
				context.moveTo(fromX, fromY);
				context.lineTo(toX, toY);
				context.stroke();
				context.setLineDash([]);
			}

			const person = this.#game.people.get(cell);
			const mark = cell === throneCell ? '👑' : (person && this.#game.met.has(person) ? characters[person].icon : '');

			if (mark) {
				context.font = '12px sans-serif';
				context.textAlign = 'center';
				context.textBaseline = 'middle';
				context.fillText(mark, x + (cellSize / 2), y + (cellSize / 2));
			}
		}

		// The visitor is a red arrow that points where they look.
		const x = margin + ((this.#game.cell % size) * cellSize) + (cellSize / 2);
		const y = margin + (Math.floor(this.#game.cell / size) * cellSize) + (cellSize / 2);
		context.save();
		context.translate(x, y);
		context.rotate(this.#game.facing * Math.PI / 2);
		context.fillStyle = '#ff2020';
		context.beginPath();
		context.moveTo(0, -9);
		context.lineTo(7, 7);
		context.lineTo(0, 3);
		context.lineTo(-7, 7);
		context.closePath();
		context.fill();
		context.restore();
		this.parts.mazeMap.setAttribute('aria-label', `Map of the castle: you have visited ${this.#game.visited.size} of ${size * size} rooms, and you look ${directionNames[this.#game.facing]}.${this.#game.isMapRevealed ? ' The throne room is in the top right corner.' : ''}`);
	}

	#isMazeMoving() {
		return !this.parts.maze.hidden && this.#canMove();
	}

	#runMazeLoop() {
		if (this.#isMazeMoving()) {
			this.#mazeLoop.start();
		} else {
			this.#drawMaze();
		}
	}

	// An animation of the maze runs for its time, which the visitors who prefer less motion skip.
	async #animate(animation, duration) {
		if (this.reducedMotion) {
			return;
		}

		this.#maze.animation = {...animation, start: performance.now(), duration};

		if (!this.#mazeLoop.isRunning) {
			this.#drawMaze();
		}

		await this.#wait(duration);
		this.#maze.animation = undefined;
	}

	#describeRoom() {
		const theme = this.#game.themes.get(this.#game.cell);
		const doors = ['left', 'front', 'right'].flatMap(side => {
			const passage = this.#passageOf(this.#game.cell, (this.#game.facing + sides[side] + 4) % 4);
			return passage ? [`${{left: 'on the left', front: 'ahead', right: 'on the right'}[side]} (${passage.state})`] : [];
		});
		const behind = this.#passageOf(this.#game.cell, (this.#game.facing + 2) % 4);
		return `The ${theme.name}. You look ${directionNames[this.#game.facing]}. ${doors.length > 0 ? `Doors: ${doors.join(', ')}.` : 'No doors on these walls.'}${behind ? ' There is a door behind you.' : ''}`;
	}

	#meet(person) {
		const character = characters[person];
		this.#game.met.add(person);
		this.#maze.popStart = performance.now();

		if (person === 'jester') {
			this.#game.cards += 2;
			this.#sounds.jester();
			this.#speech(person, `${randomItem(character.lines)} Here, take two jester cards. Each one takes away two wrong answers.`);
		} else if (person === 'ghost') {
			this.#game.isMapRevealed = true;
			this.#sounds.ghost();
			this.#speech(person, character.lines[0]);
			this.parts.mazeMapToggle.setAttribute('aria-pressed', 'true');
			this.parts.mazeMap.hidden = false;
		} else if (person === 'mormor') {
			this.#addPoints(50);
			this.#sounds.sizzle();
			this.#speech(person, `${randomItem(character.lines)} (+50 points)`);
		} else if (person === 'knight') {
			this.#speech(person, character.lines[0]);
			setTimeout(() => {
				if (this.#game.people.get(this.#game.cell) === 'knight' && !this.#game.question && !this.#game.isRiddleSolved) {
					this.#askQuestion('riddle');
				}
			}, this.reducedMotion ? 0 : 900);
		} else if (person === 'king') {
			this.#sounds.fanfare();
			this.#speech(person, character.lines[0]);
			setTimeout(() => {
				if (this.#game.people.get(this.#game.cell) === 'king' && !this.#game.isKnighted && !this.#game.question) {
					this.#askQuestion('king');
				}
			}, this.reducedMotion ? 0 : 900);
		}

		this.#updateHud();
		this.#runMazeLoop();
	}

	#enterRoom() {
		this.#game.visited.add(this.#game.cell);
		this.#updateHud();
		const person = this.#game.people.get(this.#game.cell);
		this.say(this.#describeRoom() + (person ? ` ${characters[person].name} is here.` : ''));

		if (person && !this.#game.met.has(person)) {
			this.#meet(person);
		}
	}

	async #turnAround() {
		this.#game.isBusy = true;
		this.#game.facing = (this.#game.facing + 2) % 4;
		this.#sounds.steps();
		await this.#animate({type: 'turn'}, 250);
		this.#game.isBusy = false;
		this.#updateHud();
		this.#drawMaze();
		this.say(this.#describeRoom());
	}

	async #walk(side, direction) {
		this.#game.isBusy = true;
		const door = side === 'front' ? [(backDoor.left + backDoor.right) / 2, 170] : (side === 'left' ? [74, 200] : [406, 200]);
		this.#sounds.steps();
		await this.#animate({type: 'walk', x: door[0], y: door[1]}, 450);
		this.#game.cell = neighbor(this.#game.cell, direction);
		this.#game.facing = direction;
		this.#maze.popStart = 0;
		this.parts.mazeBalloon.hidden = true;
		await this.#animate({type: 'arrive'}, 300);
		this.#game.isBusy = false;
		this.#drawMaze();
		this.#enterRoom();
	}

	async #openDoor(side, direction) {
		this.#game.isBusy = true;
		this.#sounds.creak();
		await this.#animate({type: 'door', side}, 500);
		this.#passageOf(this.#game.cell, direction).state = 'open';
		this.#game.isBusy = false;
		await this.#walk(side, direction);
	}

	#useSide(side) {
		if (!this.#game || this.#game.isBusy || this.#game.question) {
			return;
		}

		if (side === 'back') {
			this.#turnAround();
			return;
		}

		const direction = (this.#game.facing + sides[side] + 4) % 4;
		const passage = this.#passageOf(this.#game.cell, direction);

		if (!passage) {
			this.#sounds.bump();
			this.say(randomItem(['That is a wall. Only the ghost can walk through walls.', 'Bonk. Solid stone.', 'There is no door there. The castle was built before doors were cheap.']));
			return;
		}

		if (passage.state === 'open') {
			this.#walk(side, direction);
		} else if (passage.state === 'locked') {
			this.#sounds.bump();
			this.say('This door is locked, as you answered it wrong. Answer a question at another door, and the lock rusts away.');
		} else {
			this.#askQuestion('door', {side, direction});
		}
	}

	// A question: of a door, a riddle of the knight, or the question of the King.
	#takeQuestion(pool) {
		const question = this.#game[pool].shift();
		this.#game[pool].push(question);
		return question;
	}

	#askQuestion(kind, door) {
		const question = this.#takeQuestion({door: 'questionPool', riddle: 'riddlePool', king: 'kingPool'}[kind]);
		const order = shuffled([0, 1, 2, 3]);
		this.#game.question = {kind, door, question, order, isHintUsed: false, isLookedUp: false, isAnswered: false};
		this.parts.mazeAsker.textContent = {door: '🚪 The door asks:', riddle: '🛡️ The Knight’s riddle (+150 points):', king: '👑 The King asks (to become a knight):'}[kind];
		this.parts.mazeQuestionText.textContent = question.text;

		for (const [index, button] of this.#answerButtons.entries()) {
			button.textContent = `${index + 1}. ${question.answers[order[index]]}`;
			button.disabled = false;
			delete button.dataset.state;
		}

		this.parts.mazeHint.disabled = false;
		this.parts.mazeHint.textContent = this.#game.cards > 0 ? `🃏 Ask the jester (${this.#game.cards} card${this.#game.cards === 1 ? '' : 's'})` : '🃏 Ask the jester (−25)';
		this.parts.mazeLookup.hidden = !question.article;
		this.parts.mazeLookup.disabled = false;
		this.parts.mazeQuestion.hidden = false;
		this.#sounds.page();
		this.say(`${this.parts.mazeAsker.textContent} ${question.text} ${order.map((answer, index) => `${index + 1}: ${question.answers[answer]}.`).join(' ')}`);
		this.#answerButtons[0].focus({preventScroll: true});
		this.parts.mazeQuestion.scrollIntoView({block: 'nearest'});
	}

	#closeQuestion() {
		const hadFocus = this.parts.mazeQuestion.contains(document.activeElement);
		this.#game.question = undefined;
		this.parts.mazeQuestion.hidden = true;

		if (hadFocus) {
			this.parts.mazeScreen.focus({preventScroll: true});
		}
	}

	// When no door can be answered from where the visitor can walk, the ghost unlocks the locked ones, so the castle never traps anybody.
	#isTrapped() {
		const reachable = new Set([this.#game.cell]);
		const queue = [this.#game.cell];

		while (queue.length > 0) {
			const cell = queue.shift();

			for (const direction of [0, 1, 2, 3]) {
				const passage = this.#passageOf(cell, direction);

				if (passage?.state === 'closed') {
					return false;
				}

				const other = neighbor(cell, direction);

				if (passage?.state === 'open' && !reachable.has(other)) {
					reachable.add(other);
					queue.push(other);
				}
			}
		}

		return true;
	}

	#unlockAll() {
		for (const passage of this.#game.passages.values()) {
			if (passage.state === 'locked') {
				passage.state = 'closed';
			}
		}
	}

	async #answer(index) {
		const current = this.#game?.question;

		if (!current || current.isAnswered || this.#answerButtons[index].disabled) {
			return;
		}

		current.isAnswered = true;
		const isRight = current.order[index] === 0;
		const rightIndex = current.order.indexOf(0);
		this.#answerButtons[index].dataset.state = isRight ? 'right' : 'wrong';

		if (!isRight) {
			this.#answerButtons[rightIndex].dataset.state = 'right';
		}

		for (const button of this.#answerButtons) {
			button.disabled = true;
		}

		this.parts.mazeHint.disabled = true;
		this.parts.mazeLookup.disabled = true;

		if (isRight) {
			this.#sounds.right();
		} else {
			this.#sounds.wrong();
		}

		const rightText = current.question.answers[0];

		if (current.kind === 'door') {
			if (isRight) {
				const points = current.isHintUsed ? 50 : 100;
				this.#unlockAll();
				this.#addPoints(points);
				this.say(`Right! ${rightText}. The door opens. +${points} points.`);
			} else {
				this.#passageOf(this.#game.cell, current.door.direction).state = 'locked';
				this.#addPoints(-25);
				this.#speech('jester', randomItem(characters.jester.wrong));
				this.say(`Wrong. The answer is: ${rightText}. The door locks itself. −25 points.`);
			}
		} else if (current.kind === 'riddle') {
			if (isRight) {
				this.#game.isRiddleSolved = true;
				this.#addPoints(150);
				this.#speech('knight', 'Well answered! You may pass. And take 150 points for your wisdom.');
			} else {
				this.#speech('knight', `Ha! It is “${rightText}”. Come back when you are wiser.`);
			}

			this.say(isRight ? `Right! ${rightText}. +150 points.` : `Wrong. The answer is: ${rightText}.`);
		} else if (isRight) {
			this.#addPoints(200);
		} else {
			this.#speech('king', `No! It is “${rightText}”. But a king is merciful. Talk to me, and you get another question.`);
			this.say(`Wrong. The answer is: ${rightText}. Press Talk to try another question.`);
		}

		await this.#wait(1400);

		if (this.#game?.question !== current) {
			return;
		}

		this.#closeQuestion();

		if (current.kind === 'door') {
			if (isRight) {
				await this.#openDoor(current.door.side, current.door.direction);
			} else {
				if (this.#isTrapped()) {
					this.#unlockAll();
					this.#sounds.ghost();
					this.#speech('ghost', 'Boooo! You look stuck. I unlocked the doors for you. Do not tell the King.');
				}

				this.#drawMaze();
				this.#updateHud();
			}
		} else if (current.kind === 'king' && isRight) {
			this.#knight();
		}
	}

	#knight() {
		this.#game.isKnighted = true;
		this.#record = {knighted: this.#record.knighted + 1, best: Math.max(this.#record.best, this.#game.score)};
		this.store('knights', this.#record);
		this.#updateHud();
		this.#drawMaze();
		this.#sounds.fanfare();
		this.#speech('king', 'Kneel! I dub thee Knight of MindMaze, Defender of the Waffle, Protector of Bergen. Arise, Sir or Dame!');
		this.say(`You are a Knight of MindMaze, with ${this.#game.score.toLocaleString('en-US')} points, after visiting ${this.#game.visited.size} rooms. You have been knighted ${this.#record.knighted} time${this.#record.knighted === 1 ? '' : 's'}, and your best score is ${this.#record.best.toLocaleString('en-US')}. Press New Game to play again.`);
		this.celebrate();
		this.toast('⚔️ You are a Knight of MindMaze!');
	}

	#useHint() {
		const current = this.#game?.question;

		if (!current || current.isHintUsed || current.isAnswered) {
			return;
		}

		current.isHintUsed = true;

		if (this.#game.cards > 0) {
			this.#game.cards--;
		} else {
			this.#addPoints(-25);
		}

		const wrong = shuffled([1, 2, 3]).slice(0, 2);

		for (const answerIndex of wrong) {
			const button = this.#answerButtons[current.order.indexOf(answerIndex)];
			button.dataset.state = 'cut';
			button.disabled = true;
		}

		this.parts.mazeHint.disabled = true;
		this.#sounds.jester();
		this.#speech('jester', randomItem(['Psst! It is not those two. Probably.', 'I took away two wrong ones. The rest is up to you, peasant.', 'Fifty-fifty! I saw that on a TV show in England.']));
		this.#updateHud();
		this.#answerButtons.find(button => !button.disabled)?.focus({preventScroll: true});
	}

	#talk() {
		const person = this.#game?.people.get(this.#game.cell);

		if (!person || this.#game.question || this.#game.isBusy) {
			return;
		}

		this.#maze.popStart = 0;

		if (person === 'king' && !this.#game.isKnighted) {
			this.#askQuestion('king');
			return;
		}

		if (person === 'king') {
			this.#speech('king', 'Rise, my knight! Now go and do something about all that rain.');
			return;
		}

		if (person === 'knight' && !this.#game.isRiddleSolved) {
			this.#askQuestion('riddle');
			return;
		}

		if (person === 'jester') {
			this.#sounds.jester();
		} else if (person === 'ghost') {
			this.#sounds.ghost();
		}

		const {lines} = characters[person];
		this.#game.jokeIndex = (this.#game.jokeIndex + 1) % lines.length;
		this.#speech(person, lines[this.#game.jokeIndex]);
	}

	#hasEnteredMaze = false;

	#enterMaze() {
		if (!this.#game) {
			this.#newGame();
		}

		this.#updateHud();
		this.#runMazeLoop();

		if (!this.#hasEnteredMaze) {
			this.#hasEnteredMaze = true;
			this.#speech('jester', 'Welcome to MindMaze, peasant! Find the throne room, and the King will make you a knight. Click a door to answer its question.');
			this.say(`${this.#describeRoom()} ${this.#record.knighted > 0 ? `You have been knighted ${this.#record.knighted} time${this.#record.knighted === 1 ? '' : 's'}.` : 'Find the throne room!'}`);
		} else if (this.#game.question) {
			this.say(`Back at the question: ${this.#game.question.question.text}`);
		} else {
			this.say(this.#describeRoom());
		}
	}

	// Encarta starts the first time its window opens.
	#hasStarted = false;

	async #start() {
		this.#hasStarted = true;
		this.#currentPlace = 'splash';
		this.#isBusy = true;
		await this.#runSplash(['Checking drive D:…', 'Loading Encarta Encyclopedia Deluxe 99…', 'Reading the index of 37,000 articles…', 'Starting the Pinpointer…'], 1800);
		this.#isBusy = false;
		this.#currentPlace = undefined;
		this.#renderResults();
		this.#showHomeFact();
		await this.#go('home');
	}

	#updateMotion() {
		if (!this.parts.article.hidden) {
			this.#runMediaLoop();
		}

		if (!this.parts.maze.hidden) {
			this.#runMazeLoop();
		}
	}
}
