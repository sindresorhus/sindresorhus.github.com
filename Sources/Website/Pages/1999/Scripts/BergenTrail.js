// The Bergen Trail on the 1999 page: a game like The Oregon Trail on the Apple II, about the summer car trip of the family in Pappa’s old Volvo 240, from Bergen to Nordkapp. The text of each screen is built in the page, with numbered choices, and the pictures are drawn on a canvas in the six colors of the Apple II. The trip, the gravestones, and the Top Ten are kept in the browser. The canvas runs only while it is on the screen and the tab is visible, and with reduced motion, nothing moves by itself: the car drives one day for each press.
const randomItem = items => items[Math.floor(Math.random() * items.length)];

const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * ((maximum - minimum) + 1));

const clamp = (value, minimum, maximum) => Math.min(maximum, Math.max(minimum, value));

// Picks one of the items by their `weight`.
const weightedItem = items => {
	let total = 0;
	for (const item of items) {
		total += item.weight;
	}

	let roll = Math.random() * total;
	for (const item of items) {
		roll -= item.weight;
		if (roll < 0) {
			return item;
		}
	}

	return items.at(-1);
};

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// MARK: The trip

const occupations = {
	banker: {title: 'a banker from Bergen', short: 'banker', money: 15_000, multiplier: 1, perk: 'A banker has the most money, but gets the fewest points.'},
	fisherman: {title: 'a fisherman from Askøy', short: 'fisherman', money: 8000, multiplier: 2, perk: 'A fisherman has less money, but catches more and bigger fish, and is quicker on the line. He gets double points.'},
	teacher: {title: 'a teacher from Fana', short: 'teacher', money: 5000, multiplier: 3, perk: 'A teacher has the least money, but plays I Spy and 20 Questions, so the kids get bored half as often. He gets triple points.'},
};

const defaultNames = ['Pappa', 'Mamma', 'Sindre', 'Lillesøster', 'Mormor'];

const nameRoles = ['The driver', 'Next to the driver', 'In the back, me', 'In the back, the little sister', 'In the back, in the middle'];

const months = [
	{month: 4, name: 'May', advice: 'May: the mountain roads can still have snow, and it is cold, but there are no mosquitoes and no queues. On 17 May, the national day, everybody waves flags.'},
	{month: 5, name: 'June', advice: 'June: the midnight sun shines all night north of the Arctic Circle, so nobody sleeps. The new tunnel to Nordkapp opens on 15 June.'},
	{month: 6, name: 'July', advice: 'July: the common holiday (fellesferie), when all of Norway is on the road and in the ferry queue. Warm, and the mosquitoes are hungry.'},
	{month: 7, name: 'August', advice: 'August: cloudberries on the mountains and mosquitoes in Finnmark. School starts in the middle of the month, but we will not be there.'},
	{month: 8, name: 'September', advice: 'September: rain. Then more rain. No queues and no mosquitoes, and maybe the northern lights.'},
];

const paces = {
	sunday: {name: 'a Sunday drive', km: 130, health: 1, description: '130 km a day, with stops for ice cream. Good for the health.'},
	steady: {name: 'steady', km: 200, health: 0, description: '200 km a day, the normal speed of a Volvo 240.'},
	hurry: {name: 'Pappa is in a hurry', km: 290, health: -3, description: '290 km a day with no stops. Bad for the health, and the police are out.'},
};

const rations = {
	filling: {name: 'filling', kilograms: 0.6, health: 1, description: 'Mormor’s portions, with brown cheese on every slice.'},
	meager: {name: 'meager', kilograms: 0.4, health: -1, description: 'One slice each, and thin cheese.'},
	bare: {name: 'bare bones', kilograms: 0.2, health: -3, description: 'Crispbread and tap water.'},
};

// The real route, the long way: the landmarks, the ferries, and the places with a shop. `lonLat` places it on the map.
const route = [
	{
		km: 0,
		kind: 'start',
		name: 'Bergen',
		picture: 'bergen',
		lonLat: [5.32, 60.39],
		text: 'Bergen, the city of seven mountains and about 240 days of rain a year. Mamma waves goodbye to the house, Mormor waves goodbye to the fish market, and Pappa pats the Volvo and says it has never been better. It is 2400 km to Nordkapp.',
	},
	{
		km: 105,
		kind: 'landmark',
		name: 'Voss',
		picture: 'voss',
		lonLat: [6.42, 60.63],
		shop: 1.15,
		text: 'Voss, with the Tvindefossen waterfall, a ski jump, and smalahove, the smoked sheep’s head, which Pappa wants to try and Lillesøster does not want to look at.',
		talk: [
			'A man in a ski jacket says: “Bergen? It rains there. Here, it only rains on most days.”',
			'A woman at the kiosk says: “Try the smalahove. Some eat the eye first, some last. Never in the middle.”',
			'A boy says: “I jumped from the big ski jump once. Well, the small one. Well, I looked at it.”',
		],
	},
	{
		km: 185,
		kind: 'ferry',
		name: 'the Sognefjord',
		ferry: 'Vangsnes–Hella',
		lonLat: [6.6, 61.17],
		water: 'fjord',
		ticket: 190,
		text: 'The ferry Vangsnes–Hella crosses the Sognefjord, the longest and deepest fjord in Norway: 204 km long and 1308 m deep.',
		around: 'Pappa drives around the Sognefjord, which is 204 km long. Every time the road comes back to the fjord, Lillesøster asks if that is the other side.',
		aroundDays: 3,
		advice: [
			'The ferry man says: “The waffles on board are the best in Norway. Do not tell my wife.”',
			'The ferry man says: “The queue is shorter at 6 in the morning. And in October.”',
			'The ferry man says: “Drive up the ramp while it lifts? Some do. Some swim.”',
		],
	},
	{
		km: 390,
		kind: 'landmark',
		name: 'Geiranger',
		picture: 'geiranger',
		lonLat: [7.2, 62.1],
		text: 'Geiranger, at the end of the Geirangerfjord, where the Seven Sisters waterfalls fall across from the Suitor. The Eagle Road climbs out of the fjord in eleven hairpin bends, and Lillesøster gets carsick in all of them.',
		talk: [
			'A farmer says: “The farms up on the cliffs had a rope on the kids, so they did not fall into the fjord.”',
			'A tourist from a cruise ship asks Pappa for the toilet, in German. Pappa points at the fjord.',
			'Mormor says: “I came here on my honeymoon in 1952. The road was worse, and so was your grandfather.”',
		],
	},
	{
		km: 410,
		kind: 'ferry',
		name: 'the Norddalsfjord',
		ferry: 'Eidsdal–Linge',
		lonLat: [7.0, 62.35],
		water: 'fjord',
		ticket: 120,
		text: 'The ferry Eidsdal–Linge crosses the Norddalsfjord in 10 minutes. The queue takes longer. After it come the strawberries of Valldal and the eleven bends of Trollstigen.',
		around: 'Pappa drives around the Norddalsfjord on roads that are as narrow as the Volvo. Twice, he backs up for a bus for a kilometer.',
		aroundDays: 2,
		advice: [
			'The ferry man says: “Ten minutes over, ten minutes back. I have done it 40,000 times. I still get seasick.”',
			'The ferry man says: “Buy strawberries in Valldal. They are the best in the world, says Valldal.”',
		],
	},
	{
		km: 690,
		kind: 'landmark',
		name: 'Trondheim',
		picture: 'trondheim',
		lonLat: [10.4, 63.43],
		shop: 1.25,
		text: 'Trondheim, the old capital of the Vikings, with the Nidaros Cathedral, where the kings are blessed, and the only bicycle lift in the world, up the hill of Brubakken. Mormor wants to see the cathedral, Sindre wants to see the bicycle lift, and Lillesøster wants to see a toilet.',
		talk: [
			'A student says: “Trondheim is the best city in Norway. Bergen is the wettest. Oslo is the most Oslo.”',
			'A man at the cathedral says: “It took almost 300 years to build. Your trip will feel longer.”',
			'A girl at the bicycle lift says: “Put your right foot on the plate and stand up. Everybody falls over the first time.”',
		],
	},
	{
		km: 1160,
		kind: 'landmark',
		name: 'the Arctic Circle Centre',
		picture: 'arctic',
		lonLat: [15.5, 66.55],
		text: 'The Arctic Circle Centre on Saltfjellet, at 66° 33′ North. North of this line, the sun does not set in the summer. Travelers have built thousands of small stone towers (varder) on the bare mountain, and Sindre builds one for Rocky the pet rock.',
		talk: [
			'A Swedish man in shorts says: “It is warmer in Sweden.” It is.',
			'The woman at the counter sells a certificate that says you crossed the Arctic Circle. Mamma buys five.',
			'A reindeer looks at the Volvo for a long time. It says nothing, but it is not impressed.',
		],
	},
	{
		km: 1340,
		kind: 'ferry',
		name: 'the Vestfjord',
		ferry: 'Bodø–Moskenes',
		lonLat: [14.4, 67.28],
		water: 'sea',
		ticket: 420,
		text: 'The ferry from Bodø to Moskenes in Lofoten crosses the open Vestfjord in more than three hours, with big waves. Mormor brought seasickness pills from 1974.',
		around: 'There is no road around the sea. Pappa drives two days north through Narvik anyway, and then takes the small ferry from Skutvik to Lofoten, which he says does not count.',
		aroundDays: 2,
		advice: [
			'The ferry man says: “Sit in the middle of the boat and look at the horizon. Or at the waffles.”',
			'The ferry man says: “In the winter, the waves are as tall as the ferry. Now they are only half.”',
		],
	},
	{
		km: 1360,
		kind: 'landmark',
		name: 'Lofoten',
		picture: 'lofoten',
		lonLat: [13.1, 67.93],
		text: 'Lofoten: sharp mountains straight out of the sea, red fishing cabins (rorbuer) on poles, and racks of cod drying in the wind, the stockfish that has gone to Italy for a thousand years. The village at the end of the road is called Å.',
		talk: [
			'A fisherman says: “The cod comes here from the Barents Sea every winter. Then it hangs on the rack until it is as hard as a plank.”',
			'An Italian man says: “Stoccafisso! My nonna loves it.” He buys 20 kg.',
			'A boy on the pier says: “People steal the sign of Å all the time. It is the shortest name, so it fits in a suitcase.”',
		],
	},
	{
		km: 1760,
		kind: 'landmark',
		name: 'Tromsø',
		picture: 'tromso',
		lonLat: [18.95, 69.65],
		shop: 1.4,
		text: 'Tromsø, the Paris of the North, they say (nobody in Paris says it). The Arctic Cathedral looks like a stack of white ice, and Mack is the northernmost brewery in the world. In the summer, the sun does not set for two months.',
		talk: [
			'A man in a Tromsø IL shirt says: “We beat Brann at football. Not this year, but some year.”',
			'A student says: “In the dark time, we have parties. In the light time, we have parties without sleep.”',
			'Mormor says the Arctic Cathedral looks like the iceberg that sank the Titanic. She means it nicely.',
		],
	},
	{
		km: 1830,
		kind: 'ferry',
		name: 'the Lyngenfjord',
		ferry: 'Lyngseidet–Olderdalen',
		lonLat: [20.2, 69.6],
		water: 'fjord',
		ticket: 160,
		text: 'The ferry Lyngseidet–Olderdalen crosses the Lyngenfjord, under the Lyngen Alps, which have glaciers in July.',
		around: 'Pappa drives around the Lyngenfjord, past Skibotn and back up the other side, with a long view of the glaciers and a long “Er vi fremme snart?”',
		aroundDays: 2,
		advice: [
			'The ferry man says: “The Lyngen Alps? Up close, they are just mountains. Nice ones.”',
			'The ferry man says: “I saw a whale here once. Or a big wave. It was a big wave.”',
		],
	},
	{
		km: 2090,
		kind: 'landmark',
		name: 'Alta',
		picture: 'alta',
		lonLat: [23.27, 69.97],
		shop: 1.5,
		text: 'Alta, with thousands of rock carvings of reindeer, boats, and hunters, made from 7000 to 2000 years ago, and on the World Heritage List of UNESCO since 1985. Sindre draws the Volvo in his notebook, so it is ready to be famous in 7000 years.',
		talk: [
			'A girl says: “Our river has the biggest salmon in the world. The salmon agree.”',
			'A man at the petrol station says: “Nordkapp? 240 km. Three hours if you drive like a local, five if you drive like a Volvo.”',
			'An old woman says: “The carvings were found in 1972. My cow found them first, but nobody asked her.”',
		],
	},
	{
		km: 2330,
		kind: 'ferry',
		name: 'Magerøysundet',
		ferry: 'Kåfjord–Honningsvåg',
		lonLat: [25.6, 70.85],
		water: 'sea',
		ticket: 150,
		isNorthCape: true,
		text: 'Nordkapp is on the island of Magerøya. Until the new tunnel opens on 15 June 1999, the ferry Kåfjord–Honningsvåg is the only way over Magerøysundet with a car.',
		around: 'There is no road around the sea to an island. Pappa waits for two days in Kåfjord and reads the timetable of the new tunnel.',
		aroundDays: 2,
		advice: [
			'The ferry man says: “In a few weeks, they open a tunnel under the sea here, and I will be out of a job. Buy a waffle.”',
			'The ferry man says: “Honningsvåg is a city, they say. It has 3000 people and a lot of wind.”',
		],
	},
	{
		km: 2400,
		kind: 'end',
		name: 'Nordkapp',
		picture: 'nordkapp',
		lonLat: [25.78, 71.17],
	},
];

const totalKilometers = route.at(-1).km;

// The days of Pappa’s holiday. After them, the trip is over, wherever the Volvo is.
const holidayDays = 28;

// The North Cape Tunnel opened on 15 June 1999, so after that the last crossing has no ferry.
const tunnelOpening = new Date(1999, 5, 15);

// `advice` is what Kjell at Rimi in Bergen puts in the basket for a new trip, so a visitor can pay and go at once.
const storeItems = [
	{id: 'cheese', name: 'Brown cheese', unit: 'kg', step: 1, price: 69, maximum: 40, advice: 10},
	{id: 'bread', name: 'Matpakke bread', unit: 'loaves of 1 kg', step: 5, price: 18, maximum: 150, advice: 50},
	{id: 'kvikkLunsj', name: 'Kvikk Lunsj', unit: 'bars', step: 5, price: 8, maximum: 100, advice: 10},
	{id: 'petrolMoney', name: 'Petrol money', unit: 'kr', step: 250, price: 1, maximum: 10_000, isMoney: true, advice: 2500},
	{id: 'tires', name: 'Spare tires', unit: 'tires', step: 1, price: 550, maximum: 4, advice: 2},
	{id: 'map', name: 'Road map of Norway', unit: 'map', step: 1, price: 149, maximum: 1, advice: 1},
	{id: 'spray', name: 'Mosquito spray', unit: 'bottles', step: 1, price: 59, maximum: 10, advice: 2},
];

// The conditions that people get on the trip. Nobody dies of them, but they drain the health until they pass.
const conditions = [
	'carsickness',
	'a sunburn',
	'a cold from the rain',
	'mosquito bites',
	'a sore bottom from sitting',
	'a stomach ache from too much Kvikk Lunsj',
	'hiccups that will not stop',
	'a stiff neck from sleeping in the car',
];

const newTrip = () => ({
	version: 1,
	occupation: 'banker',
	names: [...defaultNames],
	month: 5,
	day: 0,
	money: 0,
	petrolMoney: 0,
	cheese: 0,
	bread: 0,
	kvikkLunsj: 0,
	fish: 0,
	extraFood: 0,
	tires: 0,
	map: 0,
	spray: 0,
	km: 0,
	next: 1,
	at: undefined,
	pace: 'steady',
	rations: 'filling',
	weather: 'rain',
	health: [100, 100, 100, 100, 100],
	conditions: ['', '', '', '', ''],
	asked: 0,
	askedMilestone: 0,
	churches: 0,
	boredomDeaths: 0,
	seen: [],
	talkIndex: 0,
	isStarted: false,
});

const isFamilyList = (list, type) => Array.isArray(list) && list.length === 5 && list.every(item => typeof item === type);

// A saved trip that was changed or broken would throw on the road, so only a trip with the right kinds of values goes on.
const isValidTrip = trip => {
	const isNumbersValid = Object.entries(newTrip()).every(([key, value]) => typeof value !== 'number' || Number.isFinite(trip[key]));
	return isNumbersValid
		&& trip.isStarted === true
		&& Object.hasOwn(occupations, trip.occupation)
		&& Object.hasOwn(paces, trip.pace)
		&& Object.hasOwn(rations, trip.rations)
		&& months.some(({month}) => month === trip.month)
		&& typeof trip.weather === 'string'
		&& isFamilyList(trip.names, 'string')
		&& isFamilyList(trip.health, 'number')
		&& isFamilyList(trip.conditions, 'string')
		&& Array.isArray(trip.seen)
		&& Number.isInteger(trip.next) && trip.next >= 1 && trip.next < route.length
		&& (trip.at === undefined || (Number.isInteger(trip.at) && trip.at >= 0 && trip.at < route.length));
};

const formatDate = date => date.toLocaleDateString('en-GB', {weekday: 'long', day: 'numeric', month: 'long', year: 'numeric'});

const formatNumber = number => Math.round(number).toLocaleString('en-US');

const kroner = amount => `${formatNumber(amount)} kr`;

const healthWord = value => {
	if (value >= 70) {
		return 'good';
	}

	if (value >= 45) {
		return 'fair';
	}

	if (value >= 22) {
		return 'poor';
	}

	return 'very poor';
};

// The kind of land the road goes through, for the pictures and the events.
const regionOf = km => {
	if (km < 690) {
		return 'fjords';
	}

	if (km < 1160) {
		return 'forest';
	}

	if (km < 2090) {
		return 'north';
	}

	return 'finnmark';
};

const element = (tag, text) => {
	const node = document.createElement(tag);
	if (text !== undefined) {
		node.textContent = text;
	}

	return node;
};

// MARK: Drawing

const width = 280;

const height = 160;

const color = {
	black: '#000000',
	white: '#ffffff',
	green: '#14f53c',
	violet: '#ff44fd',
	orange: '#ff6a3c',
	blue: '#14cfff',
};

const spriteColors = {
	k: color.black,
	w: color.white,
	g: color.green,
	v: color.violet,
	o: color.orange,
	b: color.blue,
};

// A number from 0 to 1 that is always the same for the same seed, for scenery that looks random but stays put.
const hash = seed => {
	const value = Math.sin((seed * 127.1) + 311.7) * 43_758.5453;
	return value - Math.floor(value);
};

// A tiny pixel font of 3 × 5, like the letters of the Apple II but smaller. Each letter is five rows of three bits.
const pixelFont = {
	A: [2, 5, 7, 5, 5], B: [6, 5, 6, 5, 6], C: [3, 4, 4, 4, 3], D: [6, 5, 5, 5, 6], E: [7, 4, 6, 4, 7], F: [7, 4, 6, 4, 4], G: [3, 4, 5, 5, 3], H: [5, 5, 7, 5, 5], I: [7, 2, 2, 2, 7], J: [1, 1, 1, 5, 2], K: [5, 5, 6, 5, 5], L: [4, 4, 4, 4, 7], M: [5, 7, 7, 5, 5], N: [6, 5, 5, 5, 5], O: [2, 5, 5, 5, 2], P: [6, 5, 6, 4, 4], Q: [2, 5, 5, 6, 3], R: [6, 5, 6, 5, 5], S: [3, 4, 2, 1, 6], T: [7, 2, 2, 2, 2], U: [5, 5, 5, 5, 7], V: [5, 5, 5, 5, 2], W: [5, 5, 7, 7, 5], X: [5, 5, 2, 5, 5], Y: [5, 5, 2, 2, 2], Z: [7, 1, 2, 4, 7],
	0: [7, 5, 5, 5, 7], 1: [2, 6, 2, 2, 7], 2: [6, 1, 2, 4, 7], 3: [6, 1, 2, 1, 6], 4: [5, 5, 7, 1, 1], 5: [7, 4, 6, 1, 6], 6: [3, 4, 7, 5, 7], 7: [7, 1, 2, 2, 2], 8: [7, 5, 7, 5, 7], 9: [7, 5, 7, 1, 6],
	' ': [0, 0, 0, 0, 0], '.': [0, 0, 0, 0, 2], ',': [0, 0, 0, 2, 4], '!': [2, 2, 2, 0, 2], '?': [6, 1, 2, 0, 2], ':': [0, 2, 0, 2, 0], '-': [0, 0, 7, 0, 0], '+': [0, 2, 7, 2, 0], '’': [2, 2, 0, 0, 0], '\'': [2, 2, 0, 0, 0], '“': [5, 5, 0, 0, 0], '”': [5, 5, 0, 0, 0], '"': [5, 5, 0, 0, 0], '(': [1, 2, 2, 2, 1], ')': [4, 2, 2, 2, 4], '/': [1, 1, 2, 4, 4], '°': [7, 5, 7, 0, 0], '′': [2, 2, 0, 0, 0], '♥': [0, 5, 7, 7, 2],
	Æ: [3, 6, 7, 6, 7], Ø: [3, 5, 7, 5, 6], Å: [2, 0, 2, 5, 7], Ä: [5, 0, 2, 5, 7], Ö: [5, 0, 2, 5, 2], É: [1, 2, 7, 6, 7],
};

const textWidth = (text, scale = 1) => (([...text].length * 4) - 1) * scale;

// Breaks text into lines of at most `length` letters, at the spaces.
const wrapText = (text, length) => {
	const lines = [];
	let line = '';
	for (const word of text.split(/\s+/)) {
		if (word === '') {
			continue;
		}

		if (line === '') {
			line = word.slice(0, length);
		} else if (line.length + 1 + word.length <= length) {
			line += ` ${word}`;
		} else {
			lines.push(line);
			line = word.slice(0, length);
		}
	}

	if (line !== '') {
		lines.push(line);
	}

	return lines;
};

// Pappa’s Volvo 240, the estate with the roof box, facing right. The wheels turn with the frame.
const volvoRows = [
	'.....wwwwwwwwwwwwwwwww............',
	'....wwwwwwwwwwwwwwwwwww...........',
	'..oooooooooooooooooooooooo........',
	'..obbbbbbobbbbbbbobbbbbbbbo.......',
	'..obbbbbbobbbbbbbobbbbbbbbbo......',
	'..obbbbbbobbbbbbbobbbbbbbbbbo.....',
	'.oooooooooooooooooooooooooooooooo.',
	'.ooooooooooooooooooooooooooooooooww',
	'woooooooooooooooooooooooooooooooow',
	'.oooooooooooooooooooooooooooooooo.',
	'.wwwwkkkkkwwwwwwwwwwwwwwkkkkkwwww.',
];

const wheelRows = [
	['.wwwww.', 'wkkwkkw', 'wwkkkww', 'wkkwkkw', '.wwwww.'],
	['.wwwww.', 'wkwkwkw', 'wkkkkkw', 'wkwkwkw', '.wwwww.'],
];

const policeColors = {...spriteColors, o: color.white, b: color.blue};

const sheepRows = [
	'..wwwww...',
	'.wwwwwwwkk',
	'wwwwwwwwkk',
	'wwwwwwww..',
	'.w.w..w.w.',
];

const mooseRows = [
	'w.w.w.w.........',
	'wwwwwww.........',
	'...ooo..........',
	'..ooooo.........',
	'.oooooooooooooo.',
	'oo.oooooooooooooo',
	'...ooooooooooooo.',
	'...oooooooooooo..',
	'...o.o......o.o..',
	'...o.o......o.o..',
	'...o.o......o.o..',
];

const reindeerRows = [
	'w.w.......',
	'.ww.......',
	'.vvv......',
	'..vvvvvvv.',
	'..vvvvvvvv',
	'..v.v..v.v',
	'..v.v..v.v',
];

const caravanRows = [
	'.wwwwwwwwwwwwwwwwwwwwwwww...',
	'wwwwwwwwwwwwwwwwwwwwwwwwww..',
	'wwbbbbwwwwwwwwwwwwwwbbbbww..',
	'wwbbbbwwwwwwwwwwwwwwbbbbww..',
	'oooooooooooooooooooooooooo..',
	'wwwwwwwwwwwwwwwwwwwwwwwwwwww',
	'wwwwwwwwwwwwwwwwwwwwwwwwww..',
	'.........kwwwwk.............',
	'.........kwkkwk.............',
	'..........kwwk..............',
];

const shipRows = [
	'....................oooo..........',
	'....................kkkk..........',
	'..........wwwwwwwwwwwwwwwwww......',
	'........wwwbwbwbwbwbwbwbwbwwww....',
	'......wwwwwwwwwwwwwwwwwwwwwwwwwww.',
	'kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
	'.kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk.',
	'..kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk..',
];

const ferryRows = [
	'.............wwww..............',
	'.............wbbw..............',
	'....wwwwwwwwwwwwwwwwwwwwwwww...',
	'..wwvvvoovvvwwwwoovvvwwwwwwwww.',
	'wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww',
	'oooooooooooooooooooooooooooooooo',
	'.wwwwwwwwwwwwwwwwwwwwwwwwwwwwww.',
	'..wwwwwwwwwwwwwwwwwwwwwwwwwwww..',
];

const tombstoneRows = [
	'..wwww..',
	'.wwwwww.',
	'wwwkkwww',
	'wwkkkkww',
	'wwwkkwww',
	'wwwkkwww',
	'wwwwwwww',
	'wwwwwwww',
];

const codRows = [
	'....wwwww.......',
	'..wwvvvvvww...w.',
	'.wkvvvvvvvvw.ww.',
	'wwvvvvvvvvvvwww.',
	'.wvvvvvvvvvw.ww.',
	'..wwvvvvvww...w.',
	'....wwwww.......',
];

const personRows = [
	'.o.',
	'www',
	'.w.',
	'w.w',
];

// The map of Norway, with the route and the Volvo on it.
const coast = [
	[11.4, 58.95], [10.7, 59.85], [10.3, 59.2], [9.6, 59.0], [8.6, 58.4], [7.9, 58.05], [7.0, 57.98], [6.2, 58.3], [5.6, 58.8], [5.6, 59.3], [5.2, 59.6], [5.0, 60.3], [4.9, 61.0], [5.0, 61.6], [5.1, 62.2], [6.0, 62.5], [7.0, 62.9], [8.0, 63.2], [9.0, 63.6], [10.0, 64.1], [11.0, 64.8], [12.2, 65.5], [12.8, 66.2], [13.5, 66.9], [14.4, 67.3], [15.4, 68.0], [16.5, 68.3], [17.2, 68.9], [17.8, 69.3], [18.5, 69.75], [19.5, 70.0], [21.0, 70.2], [22.0, 70.5], [23.5, 70.8], [24.5, 71.0], [25.8, 71.15], [26.8, 71.0], [28.0, 71.05], [29.0, 70.8], [30.5, 70.5], [31.1, 70.3], [30.0, 70.0], [30.2, 69.8], [30.9, 69.5], [29.2, 69.0], [28.4, 69.9], [27.9, 70.08], [26.5, 69.9], [25.6, 69.2], [24.8, 68.6], [23.5, 68.8], [22.0, 68.7], [20.55, 69.06], [19.9, 68.35], [18.1, 68.4], [17.0, 67.6], [16.1, 67.0], [15.4, 66.2], [14.5, 65.6], [14.0, 64.5], [13.2, 64.0], [12.2, 63.5], [12.2, 62.6], [12.3, 61.6], [12.8, 61.2], [12.4, 60.4], [11.8, 59.8], [11.4, 58.95],
];

const lofotenIslands = [[12.9, 67.85], [13.6, 68.1], [14.6, 68.3], [15.6, 68.6], [16.0, 68.9], [15.4, 68.95], [14.2, 68.55], [13.2, 68.15], [12.9, 67.85]];

const project = ([longitude, latitude]) => [8 + ((longitude - 4.5) * 0.42 * 11), 6 + ((71.4 - latitude) * 11)];

// One day of driving takes this many seconds on the screen.
const secondsPerDay = 1.6;

const weatherSpeed = {
	'heavy rain': 0.7,
	rain: 0.85,
	fog: 0.8,
	snow: 0.6,
};

// MARK: The gravestones

// Two old trips are always on the road, like the gravestones of other players in the real game.
const oldTombstones = [
	{km: 300, name: 'Onkel Bjarne', epitaph: 'He knew a shortcut.'},
	{km: 1500, name: 'Trond’s family', epitaph: 'They forgot the brown cheese.'},
];

const tombstoneId = stone => `stone:${stone.km}:${stone.name}:${stone.epitaph}`;

const tombstoneLines = (name, epitaph) => ['HERE LIES', 'THE TRIP OF', name.slice(0, 30), '', ...wrapText(epitaph, 32).slice(0, 4)];

// MARK: Score

const ranks = [
	{minimum: 7000, name: 'Trail Guide'},
	{minimum: 3000, name: 'Adventurer'},
	{minimum: 0, name: 'Greenhorn'},
];

const rankOf = points => ranks.find(rank => points >= rank.minimum).name;

const seedTopTen = [
	{name: 'Roald Amundsen', points: 7650},
	{name: 'Fridtjof Nansen', points: 5694},
	{name: 'Thor Heyerdahl', points: 4138},
	{name: 'Onkel Bjarne', points: 2945},
	{name: 'Trond’s pappa', points: 2052},
	{name: 'Mormor in 1967', points: 1401},
	{name: 'Glitter the unicorn', points: 1036},
	{name: 'The Hurtigruten', points: 568},
	{name: 'Rocky the pet rock', points: 234},
	{name: 'A sheep from Voss', points: 210},
];

const healthPoints = {good: 500, fair: 400, poor: 300, 'very poor': 200};

const nextBiteIn = () => 1.2 + (Math.random() * 3);

const learnPages = [
	'Try taking a journey by car across Norway in the summer of 1999! Your family of five will drive 2400 km from Bergen to Nordkapp, the north end of Europe, in Pappa’s old Volvo 240 with a roof box. If you make it, you get a certificate, a sunburn, and a very tired Pappa.',
	'You need food, petrol money, and spare tires. Rimi in Bergen has the lowest prices, and the shops get dearer the farther north you go. The fjords are in the way, so you take ferries and wait for them. You can fish for cod on the way, but only 10 kg fits in the car.',
	'Nobody dies on the Bergen Trail. People get carsickness, sunburns, and mosquito bites, and if they get bored enough, they die of boredom, for a little while. Pappa has 4 weeks of holiday. If the trip fails, you write its gravestone, and the next trip will drive past it.',
	'Your score is the health of the family, the supplies, and the money that are left at Nordkapp, times the points of Pappa’s job. Trail Guides get 7000 points or more.',
];

export default class extends GeoCitiesElement {
	#context;
	#loop;

	// The one-bit speaker of the Apple II: square waves that click and beep. Nothing sounds until the visitor turns the sound on, which makes the audio of the element (`sound()`) in the handler of the click.
	#audio = {
		isOn: false,
		sound: undefined,
		beep(frequency, duration, delay = 0, volume = 0.04) {
			if (!this.isOn) {
				return;
			}

			const {context, output} = this.sound;
			const start = context.currentTime + delay;
			const oscillator = context.createOscillator();
			const gain = context.createGain();
			oscillator.type = 'square';
			oscillator.frequency.value = frequency;
			gain.gain.setValueAtTime(volume, start);
			gain.gain.setValueAtTime(0, start + duration);
			oscillator.connect(gain).connect(output);
			oscillator.start(start);
			oscillator.stop(start + duration + 0.02);
		},
		tune(notes, length = 0.12) {
			for (const [index, frequency] of notes.entries()) {
				if (frequency > 0) {
					this.beep(frequency, length * 0.9, index * length);
				}
			}
		},
		click() {
			this.beep(1000, 0.03);
		},
		alert() {
			this.tune([440, 330], 0.1);
		},
		arrive() {
			this.tune([523, 659, 784, 1047], 0.1);
		},
		bite() {
			this.tune([1400, 0, 1400], 0.05);
		},
		caught() {
			this.tune([523, 659, 784, 1047, 1319], 0.06);
		},
		sad() {
			this.tune([392, 370, 349, 330, 0, 262], 0.22);
		},
		fanfare() {
			this.tune([392, 392, 523, 0, 659, 0, 784, 784, 659, 784, 1047], 0.13);
		},
	};

	#state = newTrip();
	#menuButtons = [];
	#primaryAction;
	#focusAfterRender = false;
	#currentScreen = '';
	#travelFields;
	#scene = {kind: 'title'};
	#travelScroll = 0;
	#animationTime = 0;
	#isDriving = false;
	#dayClock = 0;
	#ferryQueue = 0;
	#fishing;
	#fishingText;

	// Remembers where the focus was, as a click on a button that the new screen removes moves the focus to the page.
	#lastFocused;

	// The picture of the road draws the gravestones in every frame, so they are read from the storage only when they change.
	#tombstones;

	#pictureDrawers = {
		bergen: time => this.#drawBergen(time),
		voss: () => this.#drawVoss(),
		geiranger: () => this.#drawGeiranger(),
		trondheim: () => this.#drawTrondheim(),
		arctic: time => this.#drawArctic(time),
		lofoten: () => this.#drawLofoten(),
		tromso: () => this.#drawTromso(),
		alta: () => this.#drawAlta(),
		nordkapp: time => this.#drawNordkapp(time),
		store: time => this.#drawStore(time),
		tunnel: time => this.#drawTunnel(time),
		church: () => this.#drawChurch(),
		cassette: time => this.#drawCassette(time),
		map: time => this.#drawMap(time),
		title: time => this.#drawTitle(time),
		fishing: time => this.#drawFishing(time),
	};

	#dateEvents = [
		{month: 4, day: 17, id: 'national-day', overlay: 'flags', text: () => `Hurra! It is the 17th of May, the national day. You stop in a town to see the children’s parade with flags and brass bands, and eat hot dogs and ice cream until ${this.#names()[3]} feels sick.`, effect: () => this.#healAll(6)},
		{month: 5, day: 15, id: 'tunnel', text: () => `Today, the new North Cape Tunnel opens, under the sea to Nordkapp. ${this.#names()[0]} says it is in our honor.`, when: () => this.#state.km < 2330},
		{month: 5, day: 23, id: 'midsummer', overlay: 'bonfire', text: () => `It is Sankthansaften, midsummer eve! There are bonfires on every beach, and ${this.#names()[0]} sings, which nobody asked for.`, effect: () => this.#healAll(5)},
		{month: 7, day: 16, id: 'school', text: () => `School starts today in Bergen. ${this.#names()[2]} and ${this.#names()[3]} are not there. ${this.#names()[1]} wrote a note to the teacher: “They are on a study trip.”`},
	];

	#events = [
		{
			weight: 3,
			when: () => this.#state.km < 1300,
			run: () => ({overlay: 'sheep', lines: [`Sheep on the road! ${this.#names()[0]} honks. The sheep do not care. They are on holiday too. You lose an hour.`]}),
		},
		{
			weight: 2,
			when: () => this.#state.km < 2100,
			run: () => ({
				overlay: 'moose',
				lines: ['A moose on the road! It is as tall as the Volvo, and it does not move.'],
				choices: [
					{
						label: 'Brake hard',
						outcome: () => {
							const lost = Math.min(2, this.#state.cheese);
							this.#state.cheese -= lost;
							return `${this.#names()[0]} brakes hard. The Volvo stops one meter from the moose, and the brown cheese flies into the windshield. You lost ${lost} kg of brown cheese.`;
						},
					},
					{
						label: 'Honk the horn',
						outcome: () => 'The moose looks at the Volvo for ten minutes. Then it walks away, very slowly, to show who decides. You lose an hour.',
					},
					{
						label: `Let ${this.#names()[3]} talk to it`,
						outcome: () => {
							this.#state.health[3] = clamp(this.#state.health[3] + 15, 0, 100);
							return `${this.#names()[3]} rolls down the window and says “Hei, elg!” The moose leaves. ${this.#names()[3]} is very proud, and talks about it for 300 km.`;
						},
					},
				],
			}),
		},
		{
			weight: 3,
			when: () => this.#state.km > 1700,
			run: () => ({overlay: 'reindeer', lines: [`A herd of reindeer walks down the middle of the road for an hour. ${this.#names()[4]} counts 314 of them, and ${this.#names()[3]} gives them all names.`]}),
		},
		{
			weight: 3,
			when: () => this.#passengers().length > 0,
			run: () => {
				const index = this.#state.km > 300 && this.#state.km < 460 ? 3 : randomItem(this.#passengers());
				this.#state.conditions[index] = 'carsickness';
				return {lines: [`${this.#names()[index]} has carsickness. ${this.#names()[0]} stops in a lay-by. Twice.`]};
			},
		},
		{
			weight: 2,
			when: () => (this.#state.weather === 'sunny' || this.#state.weather === 'warm') && !this.#state.conditions[0],
			run: () => {
				this.#state.conditions[0] = 'a sunburn';
				return {lines: [`${this.#names()[0]} has a sunburn, but only on the left arm, the one in the open window.`]};
			},
		},
		{
			weight: 3,
			run: () => {
				if (this.#state.tires > 0) {
					this.#state.tires -= 1;
					return {overlay: 'flat', lines: [`Flat tire! ${this.#names()[0]} changes it in the rain while everybody watches from the car. You have ${this.#state.tires} spare ${this.#state.tires === 1 ? 'tire' : 'tires'} left.`]};
				}

				if (this.#state.money >= 600) {
					this.#state.money -= 600;
					const news = this.#loseDays(2);
					return {overlay: 'flat', lines: ['Flat tire, and no spare tire! A tow truck takes the Volvo to a garage. It costs 600 kr and two days.', ...news]};
				}

				const news = this.#loseDays(3);
				return {overlay: 'flat', lines: [`Flat tire, no spare tire, and no money. ${this.#names()[0]} fixes it with a bicycle pump, tape, and chewing gum. It takes three days.`, ...news]};
			},
		},
		{
			weight: 2,
			run: () => {
				this.#state.health[4] = clamp(this.#state.health[4] - 5, 0, 100);
				return {picture: 'tunnel', lines: [`A tunnel with no lights, 4 km long, blasted by hand in the 1950s. Water drips from the roof. ${this.#names()[4]} says a prayer, and ${this.#names()[2]} counts 87 drops on the windshield.`]};
			},
		},
		{
			weight: 2,
			run: () => {
				const news = this.#loseDays(1);
				return {lines: [`${this.#names()[3]} left a shoe at the last rest stop. ${this.#names()[0]} drives back 60 km to get it. It was under the seat. You lose a day.`, ...news]};
			},
		},
		{
			weight: 3,
			run: () => ({
				picture: 'church',
				lines: [`${this.#names()[4]} wants to stop at ${this.#churchHere()}.`],
				choices: [
					{
						label: 'Stop at the church',
						outcome: () => {
							this.#state.churches += 1;
							this.#state.health[4] = clamp(this.#state.health[4] + 20, 0, 100);
							return `${this.#names()[4]} lights a candle, reads every gravestone, and buys a postcard. ${this.#names()[3]} looks for bats. Churches so far: ${this.#state.churches}.`;
						},
					},
					{
						label: 'Drive on',
						outcome: () => {
							this.#state.health[4] = clamp(this.#state.health[4] - 15, 0, 100);
							return `${this.#names()[4]} sighs once every kilometer for the next 50 km.`;
						},
					},
				],
			}),
		},
		{
			weight: 2,
			run: () => {
				const tape = randomItem(this.#tapes());
				const index = randomItem([1, 2, 3, 4]);
				this.#state.conditions[index] = 'boredom';
				this.#state.asked += 20;
				return {picture: 'cassette', label: tape.label, lines: [`The cassette player eats the tape: ${tape.name}! ${this.#names()[2]} winds it back with a pencil for 50 km, and in the meantime, there is nothing to listen to but ${this.#names()[0]}’s humming. ${this.#names()[index]} is bored.`]};
			},
		},
		{
			weight: 4,
			when: () => this.#isNorthOfArcticCircle() && this.#state.month >= 5 && this.#state.month <= 7,
			run: () => {
				const where = regionOf(this.#state.km) === 'finnmark' ? 'of Finnmark' : 'of the north';
				if (this.#state.spray > 0) {
					this.#state.spray -= 1;
					return {overlay: 'mosquitoes', lines: [`The mosquitoes ${where} attack! You use a bottle of mosquito spray, and they go away, offended. You have ${this.#state.spray} ${this.#state.spray === 1 ? 'bottle' : 'bottles'} left.`]};
				}

				const bitten = [1, 2, 3, 4].filter(() => Math.random() < 0.6);
				for (const index of bitten) {
					this.#state.conditions[index] = 'mosquito bites';
				}

				const who = bitten.length === 0 ? 'Only the Volvo has' : `${bitten.map(index => this.#names()[index]).join(' and ')} ${bitten.length === 1 ? 'has' : 'have'}`;
				return {overlay: 'mosquitoes', lines: [`The mosquitoes ${where} attack, and you have no mosquito spray! ${who} mosquito bites. ${this.#names()[0]} says the mosquitoes here are as big as sparrows.`]};
			},
		},
		{
			weight: 3,
			when: () => this.#isMidnightSun(),
			run: () => {
				this.#healAll(-5);
				const bonus = Math.min(50, this.#nextStop().km - this.#state.km - 1);
				if (bonus > 0) {
					this.#state.km += bonus;
					this.#payPetrol(bonus);
				}

				return {lines: [`The midnight sun! It is 2 at night and as light as noon. Nobody sleeps, and ${this.#names()[0]} drives on, because it feels like the afternoon.${bonus > 0 ? ` You drive ${bonus} km extra.` : ''}`]};
			},
		},
		{
			weight: 2,
			run: () => {
				this.#state.asked += 12;
				return {lines: [`Road work! You wait 40 minutes behind a red light for the escort car (følgebil). ${this.#names()[3]} asks “Er vi fremme snart?” 12 times.`]};
			},
		},
		{
			weight: 1,
			run: () => {
				const fine = Math.min(this.#state.money, 1500);
				this.#state.money -= fine;
				return {overlay: 'police', lines: [`The police stop the Volvo. ${this.#names()[0]} drove 95 in an 80 zone. The fine is 1500 kr${fine < 1500 ? `, and ${this.#names()[0]} can only pay ${kroner(fine)}` : ''}. ${this.#names()[1]} says nothing, very loudly.`]};
			},
			hurryWeight: 6,
		},
		{
			weight: 2,
			when: () => this.#state.km > 1000 && (this.#state.month === 6 || this.#state.month === 7),
			run: () => {
				this.#state.extraFood += 2;
				return {overlay: 'berries', lines: [`${this.#names()[4]} finds cloudberries (multer), the gold of the mountains! You pick 2 kg. ${this.#names()[4]} will never tell anyone where.`]};
			},
		},
		{
			weight: 1,
			mapWeight: 0.2,
			noMapWeight: 4,
			run: () => {
				const news = this.#loseDays(1);
				this.#state.extraFood += 2;
				return {lines: [`${this.#names()[0]} took a wrong turn and drove to Sweden. He says it was on purpose, as the candy is cheaper there. You lose a day, but get 2 kg of Swedish candy.${this.#state.map ? '' : ' (A road map would help.)'}`, ...news]};
			},
		},
		{
			weight: 2,
			when: () => (this.#state.km > 250 && this.#state.km < 460) || (this.#state.km > 1050 && this.#state.km < 1200),
			run: () => ({overlay: 'boiling', lines: [`The Volvo boils on the steep road. ${this.#names()[0]} says it is Swedish, so it can take it. You wait two hours for it to cool, and ${this.#names()[2]} tries to fry an egg on the hood.`]}),
		},
		{
			weight: 2,
			when: () => regionOf(this.#state.km) === 'north' || this.#state.km < 690,
			run: () => {
				this.#healAll(5);
				return {overlay: 'hurtigruten', lines: ['The Hurtigruten ship sails by on the fjord. Everybody waves, and the ship blows its horn back. Everybody feels better.']};
			},
		},
		{
			weight: 2,
			when: () => this.#state.money >= 75,
			run: () => {
				this.#state.money -= 75;
				this.#healAll(3);
				return {lines: [`${this.#names()[0]} buys soft ice for everybody at a petrol station. ${this.#names()[2]} gets a brain freeze, and ${this.#names()[4]} gets the sprinkles.`]};
			},
		},
		{
			weight: 3,
			when: () => this.#state.month === 8 && this.#isNorthOfArcticCircle(),
			run: () => {
				this.#healAll(10);
				return {overlay: 'lights', lines: [`The northern lights! Green curtains dance over the sky all night. Even ${this.#names()[0]} stops the car to look. Everybody feels better.`]};
			},
		},
		{
			weight: 2,
			run: () => {
				this.#state.asked += 15;
				return {overlay: 'caravan', lines: [`A Swedish caravan drives at 60 km/h in front of you for 100 km, and there is no place to pass. ${this.#names()[0]} says words that ${this.#names()[3]} repeats for the rest of the summer.`]};
			},
		},
		{
			weight: 2,
			run: () => ({lines: [`${this.#names()[2]} and ${this.#names()[3]} fight about the middle of the back seat. ${this.#names()[1]} puts a line of tape down the middle. Then ${this.#names()[4]} sits on the line.`]}),
		},
		{
			weight: 2,
			when: () => this.#state.km < 700 && (this.#state.month === 5 || this.#state.month === 6) && this.#state.money >= 40,
			run: () => {
				this.#state.money -= 40;
				this.#state.extraFood += 2;
				return {overlay: 'strawberries', lines: [`A farmer sells strawberries by the road. ${this.#names()[1]} buys a basket for 40 kr, and 2 kg of food is gone before the next bend. Well, it is in the family.`]};
			},
		},
	];

	#askedMilestones = [
		[100, () => `${this.#names()[3]} has asked “Er vi fremme snart?” (“Are we there yet?”) 100 times. ${this.#names()[0]} says “Snart.” (“Soon.”)`],
		[200, () => `200 times “Er vi fremme snart?” ${this.#names()[0]} says “NEI!” and turns up the radio. It is the shipping forecast.`],
		[300, () => `300 times. ${this.#names()[1]} starts a game of I Spy instead. ${this.#names()[3]} spies something that starts with F. It is “fremme”.`],
		[400, () => `400 times “Er vi fremme snart?” Now ${this.#names()[4]} asks too.`],
		[500, () => `500 times. ${this.#names()[0]} answers with a sigh so long that it lasts to the next petrol station.`],
	];

	#tripOverReasons = {
		holiday: () => `${this.#names()[0]}’s holiday is over. He has to be back at work on Monday, so the family turns the Volvo around at km ${formatNumber(this.#state.km)}, near ${this.#lastPlace().name}.`,
		tired: () => `Everybody is too tired of the trip. ${this.#names()[1]} books the Hurtigruten home, and ${this.#names()[0]} sells the roof box.`,
		petrol: () => `The Volvo ran out of petrol at km ${formatNumber(this.#state.km)}, and there is no money left for more. Onkel Bjarne comes all the way from Bergen with a tow rope.`,
	};

	connected() {
		const {monitor, canvas, sound, restart} = this.parts;
		this.#context = canvas.getContext('2d');
		this.#tombstones = [...oldTombstones, ...this.#savedTombstones()];

		this.#loop = this.loop(seconds => {
			this.#animationTime += seconds;
			if (this.#isDriving && this.#currentScreen === 'travel' && !this.reducedMotion) {
				this.#travelScroll += seconds * paces[this.#state.pace].km * 0.25;
				this.#dayClock += seconds;
				if (this.#dayClock >= secondsPerDay) {
					this.#dayClock = 0;
					this.#driveDay();
				}
			}

			if (this.#isFishing()) {
				this.#updateFishing(seconds);
			}

			this.#draw();
		}, {while: () => this.#isAnimated()});

		this.on(sound, 'click', () => {
			const audio = this.#audio;
			audio.sound ??= this.sound();
			audio.isOn = !audio.isOn && audio.sound !== undefined;
			setPressed(sound, audio.isOn);
			sound.textContent = audio.isOn ? '🔊 Sound On' : '🔇 Sound Off';
			audio.click();
		});

		this.on(this, 'focusin', event => {
			this.#lastFocused = event.target;
		});

		this.on(document, 'focusin', event => {
			if (!this.contains(event.target)) {
				this.#lastFocused = undefined;
			}
		});

		// Escape answers the question of “Start a New Trip” with no, like a dialog, also from the buttons below the monitor.
		this.on(this, 'keydown', event => {
			if (event.key === 'Escape' && this.#currentScreen === 'restart') {
				event.preventDefault();
				this.#menuButtons.at(-1).click();
			}
		});

		this.on(monitor, 'keydown', event => {
			// A held key would otherwise race through the screens and skip the news.
			if (event.repeat || event.target.matches('input') || event.altKey || event.ctrlKey || event.metaKey) {
				return;
			}

			// In the store, the only choice is to pay, which a stray key should not do.
			const number = Number.parseInt(event.key, 10);
			if (this.#currentScreen !== 'store' && number >= 1 && number <= this.#menuButtons.length) {
				event.preventDefault();
				this.#menuButtons[number - 1].click();
				return;
			}

			if (event.target === canvas && (event.key === ' ' || event.key === 'Enter') && this.#primaryAction) {
				event.preventDefault();
				this.#audio.click();
				this.#primaryAction();
			}
		});

		this.on(canvas, 'click', () => {
			if (this.#primaryAction) {
				this.#audio.click();
				this.#primaryAction();
			}
		});

		this.on(restart, 'click', () => {
			this.#audio.click();
			if (!this.#state.isStarted && !this.#savedTrip()) {
				this.#showOccupation();
				this.#menuButtons[0]?.focus({preventScroll: true});
				return;
			}

			this.#showScreen('restart', () => {
				this.#addLine('Do you want to give up this trip and start a new one?');
				this.#addMenu([
					{
						label: 'Yes, start a new trip',
						action: () => {
							this.store('trip', undefined);
							this.#showOccupation();
						},
					},
					{label: 'No, keep the trip', action: this.#state.isStarted ? () => this.#showSizeUp() : () => this.#showTitle()},
				]);
			});
			this.#menuButtons[0]?.focus({preventScroll: true});
		});

		this.#showTitle();
	}

	// The pictures move only while the canvas is on screen, not while only the text of the screen below it is.
	get visibilityTarget() {
		return this.parts.canvas;
	}

	reducedMotionChanged() {
		if (this.#currentScreen === 'travel') {
			this.#showTravel();
		}

		this.#draw();
	}

	// MARK: The trip

	#saveTrip() {
		if (this.#state.isStarted) {
			this.store('trip', this.#state);
		}
	}

	#savedTrip() {
		const saved = this.stored('trip', {});
		return saved.version === 1 && isValidTrip(saved) ? saved : undefined;
	}

	#names() {
		return this.#state.names;
	}

	// The texts of the places name the family as they are by default, so they use the names that the visitor typed instead.
	#withNames(text) {
		return text.replaceAll(/Pappa|Mamma|Sindre|Lillesøster|Mormor/g, name => this.#names()[defaultNames.indexOf(name)]);
	}

	#occupation() {
		return occupations[this.#state.occupation] ?? occupations.banker;
	}

	#dateOf(day) {
		return new Date(1999, this.#state.month, 1 + day);
	}

	#today() {
		return this.#dateOf(this.#state.day);
	}

	#food() {
		return this.#state.fish + this.#state.extraFood + this.#state.bread + this.#state.cheese;
	}

	#averageHealth() {
		let total = 0;
		for (const value of this.#state.health) {
			total += value;
		}

		return total / this.#state.health.length;
	}

	#isNorthOfArcticCircle() {
		return this.#state.km >= 1160;
	}

	#isMidnightSun() {
		return this.#isNorthOfArcticCircle() && (this.#state.month === 5 || this.#state.month === 6);
	}

	#lastPlace() {
		return route[Math.max(0, this.#state.next - 1)];
	}

	#nextStop() {
		return route[this.#state.next];
	}

	// MARK: The screen

	#setPrompt(text) {
		this.parts.prompt.textContent = text;
	}

	// Builds a new screen of text. When the focus was on the old screen, it moves to the first control of the new one, so the keyboard and screen readers follow along.
	#showScreen(name, build) {
		this.#focusAfterRender = this.parts.screen.contains(document.activeElement) || document.activeElement === document.body;
		this.#focusAfterRender &&= this.contains(this.#lastFocused);
		this.#currentScreen = name;
		this.#isDriving = false;
		this.parts.screen.replaceChildren();
		this.#menuButtons = [];
		this.#primaryAction = undefined;
		this.#setPrompt('');
		build();
		if (this.#focusAfterRender) {
			this.parts.screen.querySelector('button, input')?.focus({preventScroll: true});
		}
	}

	#addHeading(text) {
		this.parts.screen.append(element('h3', text));
	}

	// A paragraph from parts: plain text, `{bold}` in green, or `{inverse}` in black on white, like the inverse letters of the Apple II.
	#addLine(...parts) {
		const paragraph = element('p');
		for (const part of parts) {
			if (typeof part === 'string') {
				paragraph.append(part);
			} else if (part.bold !== undefined) {
				paragraph.append(element('b', part.bold));
			} else if (part.inverse !== undefined) {
				paragraph.append(element('strong', part.inverse));
			}
		}

		this.parts.screen.append(paragraph);
		return paragraph;
	}

	// A line with a green label and a value that can change in place.
	#addField(label, value) {
		const paragraph = this.#addLine({bold: `${label}: `});
		const span = element('span', value);
		paragraph.append(span);
		return span;
	}

	#addMenu(items, prompt = 'What is your choice?') {
		const list = element('ol');
		for (const item of items) {
			const button = element('button', `${this.#menuButtons.length + 1}. ${item.label}`);
			button.type = 'button';
			button.addEventListener('click', () => {
				this.#audio.click();
				item.action();
			});
			const listItem = element('li');
			listItem.append(button);
			list.append(listItem);
			this.#menuButtons.push(button);
		}

		this.parts.screen.append(list);
		this.#setPrompt(prompt);
		return list;
	}

	#addContinue(action) {
		this.#addMenu([{label: 'Continue', action}], 'Press SPACE BAR to continue');
		this.#primaryAction = action;
	}

	// A screen with a picture, some lines of text, and Continue.
	#showMessage({title, lines, picture, then, statusText}) {
		if (picture) {
			this.#setScene(picture.kind, picture);
		}

		this.#showScreen('message', () => {
			if (title) {
				this.#addHeading(title);
			}

			for (const line of lines) {
				this.#addLine(line);
			}

			this.#addContinue(then);
		});

		if (statusText ?? lines[0]) {
			this.say(statusText ?? lines[0]);
		}
	}

	// MARK: Drawing

	#fill(x, y, rectangleWidth, rectangleHeight, fillColor) {
		this.#context.fillStyle = fillColor;
		this.#context.fillRect(Math.round(x), Math.round(y), Math.round(rectangleWidth), Math.round(rectangleHeight));
	}

	// Draws text in the pixel font. `x` is the center, unless `align` is `left`.
	#drawText(text, x, y, textColor, scale = 1, align = 'center') {
		const characters = [...String(text).toUpperCase()];
		let left = align === 'left' ? Math.round(x) : Math.round(x - (textWidth(characters.join(''), scale) / 2));
		this.#context.fillStyle = textColor;

		for (const character of characters) {
			const rows = pixelFont[character] ?? pixelFont['?'];
			for (const [row, bits] of rows.entries()) {
				for (let column = 0; column < 3; column++) {
					if (bits & (4 >> column)) {
						this.#context.fillRect(left + (column * scale), Math.round(y) + (row * scale), scale, scale);
					}
				}
			}

			left += 4 * scale;
		}
	}

	// Draws a picture from rows of letters, where each letter is a color of `spriteColors`, and a dot is see-through.
	#drawSprite(rows, x, y, scale = 1, colors = spriteColors) {
		for (const [row, line] of rows.entries()) {
			for (let column = 0; column < line.length; column++) {
				const spriteColor = colors[line[column]];
				if (spriteColor) {
					this.#fill(x + (column * scale), y + (row * scale), scale, scale, spriteColor);
				}
			}
		}
	}

	// A mountain of steps, two pixels high each, like the chunky mountains of the Apple II, with snow on the top part.
	#drawMountain(x, baseY, mountainHeight, halfWidth, body, snow = 0) {
		for (let row = 0; row < mountainHeight; row += 2) {
			const half = Math.max(1, Math.round(((row + 2) / mountainHeight) * halfWidth));
			this.#fill(x - half, baseY - mountainHeight + row, half * 2, 2, row < mountainHeight * snow ? color.white : body);
		}
	}

	// A row of mountains that scrolls with the offset, always the same for the same seed.
	#drawRange({offset, baseY, spacing, minimum, maximum, body, snow, seed}) {
		const first = Math.floor(offset / spacing) - 2;
		for (let index = first; index < first + Math.ceil(width / spacing) + 5; index++) {
			const x = ((index * spacing) - offset) + (hash(index + seed) * spacing * 0.5);
			const mountainHeight = minimum + (hash((index * 3) + seed) * (maximum - minimum));
			this.#drawMountain(x, baseY, mountainHeight, mountainHeight * (0.8 + (hash((index * 7) + seed) * 0.7)), body, snow);
		}
	}

	#drawTree(x, baseY, treeHeight = 10) {
		for (let row = 0; row < treeHeight; row += 2) {
			const half = Math.max(1, Math.round(((row + 2) / treeHeight) * treeHeight * 0.3));
			this.#fill(x - half, baseY - treeHeight + row, half * 2, 2, color.green);
		}

		this.#fill(x - 1, baseY, 2, 2, color.orange);
	}

	#drawRain(time, amount = 60, heavy = false) {
		for (let index = 0; index < amount; index++) {
			const x = ((hash(index) * width) + (time * 30)) % width;
			const y = ((hash(index + 99) * height) + (time * (heavy ? 160 : 110))) % height;
			this.#fill(x, y, 1, heavy ? 4 : 3, color.blue);
		}
	}

	#drawSnow(time) {
		for (let index = 0; index < 50; index++) {
			const x = ((hash(index) * width) + (Math.sin(time + index) * 4)) % width;
			const y = ((hash(index + 7) * height) + (time * 20)) % height;
			this.#fill(x, y, 1, 1, color.white);
		}
	}

	// Fog as a checkerboard of white pixels over the picture, the only way the Apple II could do gray.
	#drawFog(top = 0, bottom = height) {
		this.#context.fillStyle = color.white;
		for (let y = top; y < bottom; y += 2) {
			for (let x = (y / 2) % 2 === 0 ? 0 : 2; x < width; x += 4) {
				this.#context.fillRect(x, y, 1, 1);
			}
		}
	}

	#drawSun(x, y, sunColor = color.orange) {
		this.#fill(x - 4, y - 6, 8, 12, sunColor);
		this.#fill(x - 6, y - 4, 12, 8, sunColor);
	}

	#drawClouds(time, seed = 1) {
		for (let index = 0; index < 4; index++) {
			const x = (((hash(index + seed) * width) + (time * 4)) % (width + 60)) - 30;
			const y = 8 + (hash(index + seed + 5) * 22);
			this.#fill(x, y, 30, 4, color.white);
			this.#fill(x + 6, y - 3, 16, 3, color.white);
		}
	}

	#drawVolvo(x, y, frame = 0, colors = spriteColors) {
		this.#drawSprite(volvoRows, x, y, 1, colors);
		const wheel = wheelRows[frame % 2];
		this.#drawSprite(wheel, x + 4, y + 10, 1, colors);
		this.#drawSprite(wheel, x + 23, y + 10, 1, colors);
	}

	// The scenery while driving: mountains, the fjord or the sea, trees, the road, and the weather, all scrolling with the offset.
	#drawLandscape(offset, time, {weather = this.#state.weather, km = this.#state.km} = {}) {
		const region = regionOf(km);
		this.#fill(0, 0, width, height, color.black);

		if (weather === 'sunny' || weather === 'warm' || this.#isMidnightSun()) {
			this.#drawSun(this.#isMidnightSun() ? 236 : 232, this.#isMidnightSun() ? 70 : 22);
		}

		if (region === 'finnmark') {
			this.#drawRange({offset: offset * 0.15, baseY: 100, spacing: 70, minimum: 10, maximum: 22, body: color.violet, snow: 0.2, seed: 40});
		} else if (region === 'forest') {
			this.#drawRange({offset: offset * 0.15, baseY: 100, spacing: 60, minimum: 20, maximum: 40, body: color.violet, snow: 0.2, seed: 20});
			this.#drawRange({offset: offset * 0.3, baseY: 104, spacing: 46, minimum: 12, maximum: 24, body: color.green, snow: 0, seed: 25});
		} else {
			this.#drawRange({offset: offset * 0.15, baseY: 98, spacing: 48, minimum: 40, maximum: 70, body: color.violet, snow: region === 'north' ? 0.45 : 0.3, seed: region === 'north' ? 30 : 10});
		}

		// The fjord or the sea between the mountains and the road.
		if (region === 'fjords' || region === 'north') {
			this.#fill(0, 98, width, 10, color.blue);
			for (let index = 0; index < 12; index++) {
				const x = (((hash(index + 3) * width) - (offset * 0.4)) % width + width) % width;
				this.#fill(x, 100 + ((index % 3) * 3), 6, 1, color.white);
			}
		} else {
			this.#fill(0, 98, width, 10, color.green);
		}

		this.#fill(0, 108, width, 52, color.green);

		// Tundra has no trees, only stones and lichen.
		const treeSpacing = region === 'finnmark' ? 0 : (region === 'north' ? 70 : 26);
		if (treeSpacing > 0) {
			const treeOffset = offset * 0.7;
			const first = Math.floor(treeOffset / treeSpacing) - 1;
			for (let index = first; index < first + Math.ceil(width / treeSpacing) + 3; index++) {
				const x = (index * treeSpacing) - treeOffset + (hash(index + 50) * treeSpacing * 0.6);
				this.#drawTree(x, 118 + (hash(index + 60) * 4), 10 + Math.round(hash(index + 70) * 6));
			}
		} else {
			const stoneOffset = offset * 0.7;
			for (let index = 0; index < 18; index++) {
				const x = (((hash(index + 80) * 300) - stoneOffset) % 300 + 300) % 300 - 10;
				this.#fill(x, 112 + (hash(index + 90) * 12), 3, 2, index % 2 === 0 ? color.white : color.orange);
			}
		}

		// The road, with the dashes in the middle moving past.
		this.#fill(0, 126, width, 18, color.black);
		const dashOffset = offset % 20;
		for (let x = -dashOffset; x < width; x += 20) {
			this.#fill(x, 134, 10, 2, color.white);
		}

		for (let index = 0; index < 9; index++) {
			const x = (((hash(index + 120) * 300) - offset) % 300 + 300) % 300 - 10;
			this.#fill(x, 148 + (hash(index + 130) * 8), 2, 2, color.orange);
		}

		if (weather === 'rain') {
			this.#drawClouds(time);
			this.#drawRain(time, 50);
		} else if (weather === 'heavy rain') {
			this.#drawClouds(time, 4);
			this.#drawRain(time, 110, true);
		} else if (weather === 'snow') {
			this.#drawClouds(time, 2);
			this.#drawSnow(time);
		} else if (weather === 'fog') {
			this.#drawFog(40, 126);
		}
	}

	#stillOrMoving(value) {
		return this.reducedMotion ? 0 : value;
	}

	#drawTravel(overlay) {
		const offset = this.reducedMotion ? this.#state.km * 3 : this.#travelScroll;
		const time = this.#stillOrMoving(this.#animationTime);
		this.#drawLandscape(offset, time);

		const isMoving = this.#isDriving && !this.reducedMotion;
		const bounce = isMoving && Math.floor(time * 8) % 2 === 0 ? 1 : 0;
		const frame = isMoving ? Math.floor(time * 10) : 0;
		const carY = 119 - bounce;

		for (const tombstone of this.#tombstones) {
			const distance = tombstone.km - this.#state.km;
			if (distance >= 0 && distance < 30 && overlay !== 'tombstone') {
				this.#drawSprite(tombstoneRows, 180 + (distance * 3), 112);
			}
		}

		// A Swedish caravan, pulled by a Swedish car, in front of the Volvo.
		if (overlay === 'caravan') {
			this.#drawSprite(caravanRows, 156, 118, 1);
			this.#fill(184, 128, 14, 1, color.white);
			this.#drawVolvo(196, 119, 0, {...spriteColors, o: color.blue, b: color.white});
		}

		if (overlay === 'flat') {
			this.#drawVolvo(110, 120, 0);
			this.#fill(141, 129, 9, 3, color.white);
			this.#drawSprite(wheelRows[0], 150, 138);
			this.#drawPeople(160, 134, [0]);
		} else {
			this.#drawVolvo(110, carY, frame);
		}

		if (overlay === 'boiling') {
			for (let index = 0; index < 14; index++) {
				const y = 110 - ((index * 3) + ((time * 20) % 6));
				this.#fill(137 + (Math.sin(index + time * 4) * 3), y, 2, 2, color.white);
			}
		}

		if (overlay === 'police') {
			this.#drawVolvo(40, 119, 0, policeColors);
			this.#fill(52, 116, 6, 3, Math.floor(time * 4) % 2 === 0 || this.reducedMotion ? color.blue : color.white);
		}

		if (overlay === 'sheep') {
			this.#drawSprite(sheepRows, 170, 126, 2);
			this.#drawSprite(sheepRows, 200, 130, 2);
			this.#drawSprite(sheepRows, 226, 125, 2);
		}

		if (overlay === 'moose') {
			this.#drawSprite(mooseRows, 170, 108, 2);
		}

		if (overlay === 'reindeer') {
			for (let index = 0; index < 6; index++) {
				this.#drawSprite(reindeerRows, 158 + (index * 18), 124 + ((index % 2) * 6) + (index === 3 ? -4 : 0));
			}
		}

		if (overlay === 'hurtigruten') {
			const x = this.reducedMotion ? 150 : (260 - ((time * 8) % 340));
			this.#drawSprite(shipRows, x, 91);
		}

		if (overlay === 'mosquitoes') {
			for (let index = 0; index < 70; index++) {
				const angle = (index * 2.4) + (time * (2 + (index % 3)));
				const radius = 6 + (hash(index) * 40);
				this.#fill(127 + (Math.cos(angle) * radius), 118 + (Math.sin(angle) * radius * 0.5), 1, 1, color.white);
			}
		}

		if (overlay === 'lights') {
			for (let band = 0; band < 3; band++) {
				for (let x = 0; x < width; x += 2) {
					const y = 14 + (band * 9) + (Math.sin((x / 23) + time + band) * 6);
					this.#fill(x, y, 2, 6 - band, band === 1 ? color.blue : color.green);
				}
			}
		}

		if (overlay === 'berries') {
			for (let index = 0; index < 24; index++) {
				const x = 150 + (hash(index + 5) * 120);
				const y = 110 + (hash(index + 9) * 14);
				this.#fill(x, y, 3, 3, color.orange);
				this.#fill(x - 2, y + 3, 7, 1, color.green);
			}

			this.#drawPeople(200, 124, [4]);
			this.#fill(206, 118, 8, 6, color.white);
		}

		if (overlay === 'flags') {
			for (let index = 0; index < 6; index++) {
				const x = 20 + (index * 40);
				this.#fill(x, 104, 1, 16, color.white);
				this.#fill(x + 1, 104, 9, 6, color.orange);
				this.#fill(x + 1, 106, 9, 2, color.white);
				this.#fill(x + 4, 104, 2, 6, color.white);
				this.#fill(x + 1, 106.5, 9, 1, color.blue);
				this.#fill(x + 4.5, 104, 1, 6, color.blue);
			}
		}

		if (overlay === 'bonfire') {
			for (const [index, x] of [190, 250, 40].entries()) {
				const flicker = (Math.floor(time * 8) + index) % 2;
				this.#fill(x - 10, 116, 20, 3, color.white);
				this.#drawMountain(x, 116, 22 + (flicker * 3), 9, color.orange, 0.25 + (flicker * 0.1));
				for (let spark = 0; spark < 4; spark++) {
					this.#fill(x - 4 + (hash(spark + index + Math.floor(time * 4)) * 8), 84 + (hash(spark + 3 + index) * 6), 1, 1, color.orange);
				}
			}

			this.#drawPeople(208, 120, [0]);
		}

		if (overlay === 'tombstone') {
			this.#drawSprite(tombstoneRows, 170, 110, 2);
		}

		if (overlay === 'strawberries') {
			this.#fill(176, 116, 30, 10, color.white);
			this.#fill(178, 112, 26, 4, color.orange);
			for (let index = 0; index < 6; index++) {
				this.#fill(180 + (index * 4), 120, 2, 2, color.orange);
			}
		}
	}

	// Small people of three pixels, by the index of the family.
	#drawPeople(x, y, indexes = [0, 1, 2, 3, 4]) {
		for (const [position, index] of indexes.entries()) {
			const isSmall = index === 3;
			this.#drawSprite(isSmall ? personRows.slice(1) : personRows, x + (position * 5), y - (isSmall ? 3 : 4));
		}
	}

	#drawBergen(time) {
		this.#fill(0, 0, width, height, color.black);
		this.#drawMountain(70, 92, 60, 90, color.green, 0);
		this.#drawMountain(210, 92, 70, 100, color.green, 0);
		// The funicular up Fløyen.
		for (let index = 0; index < 30; index++) {
			this.#fill(100 + (index * 2), 88 - (index * 1.6), 2, 1, color.white);
		}

		const houseColors = [color.orange, color.white, color.orange, color.violet, color.white, color.orange, color.white];
		for (const [index, houseColor] of houseColors.entries()) {
			const x = 30 + (index * 32);
			this.#fill(x, 82, 28, 34, houseColor);
			this.#drawMountain(x + 14, 82, 14, 14, houseColor);

			for (let window = 0; window < 3; window++) {
				this.#fill(x + 4 + (window * 8), 88, 4, 5, color.black);
				this.#fill(x + 4 + (window * 8), 100, 4, 5, color.black);
			}
		}

		this.#fill(0, 116, width, 44, color.blue);
		for (let index = 0; index < 20; index++) {
			this.#fill(hash(index + 1) * width, 120 + (hash(index + 2) * 36), 8, 1, color.white);
		}

		this.#drawRain(time, 70);
	}

	#drawVoss() {
		this.#fill(0, 0, width, height, color.black);
		this.#drawMountain(60, 100, 70, 80, color.violet, 0.35);
		this.#drawMountain(170, 100, 84, 90, color.violet, 0.35);
		this.#drawMountain(250, 100, 60, 60, color.violet, 0.3);
		// Tvindefossen, falling in steps down the cliff.
		this.#fill(18, 40, 30, 70, color.violet);
		for (let step = 0; step < 6; step++) {
			this.#fill(24 + (step % 2) * 4, 40 + (step * 12), 10, 12, color.white);
			this.#fill(26 + (step % 2) * 4, 44 + (step * 12), 2, 8, color.blue);
		}

		this.#fill(0, 100, width, 60, color.green);
		// The ski jump on the hill.
		for (let index = 0; index < 40; index++) {
			this.#fill(190 + (index * 2), 60 + (index * (index < 30 ? 1.4 : 0.4)), 3, 2, color.white);
		}

		this.#fill(186, 54, 8, 8, color.white);
		this.#fill(60, 126, 150, 20, color.blue);
		this.#fill(80, 132, 40, 1, color.white);
		this.#drawVolvo(220, 130);
	}

	#drawFerryScene(time, crossing) {
		this.#fill(0, 0, width, height, color.black);
		const isSea = crossing.water === 'sea';
		if (isSea) {
			this.#drawMountain(220, 82, 30, 20, color.violet, 0.4);
			this.#drawMountain(250, 82, 40, 18, color.violet, 0.4);
			this.#drawMountain(270, 82, 26, 16, color.violet, 0.4);
		} else {
			this.#drawMountain(20, 90, 80, 70, color.violet, 0.3);
			this.#drawMountain(110, 84, 60, 50, color.violet, 0.35);
			this.#drawMountain(270, 90, 86, 80, color.violet, 0.3);
		}

		this.#fill(0, 82, width, 78, color.blue);
		for (let index = 0; index < 24; index++) {
			const x = ((hash(index + 2) * width) + this.#stillOrMoving(time * (isSea ? 12 : 4))) % width;
			this.#fill(x, 88 + (hash(index + 4) * 50), isSea ? 8 : 5, 1, color.white);
		}

		if (isSea) {
			this.#drawSun(60, 30);
		}

		// The quay with the queue of cars.
		this.#fill(0, 130, 120, 30, color.green);
		this.#fill(0, 128, 120, 2, color.white);
		const queueColors = [color.white, color.orange, color.violet, color.white, color.blue, color.orange];
		for (const [index, carColor] of queueColors.entries()) {
			this.#fill(4 + (index * 14), 132, 11, 5, carColor);
			this.#fill(6 + (index * 14), 129, 7, 3, carColor);
		}

		this.#drawVolvo(86, 136);
		const ferryX = 130 + (this.reducedMotion ? 20 : (Math.sin(time * 0.3) * 40) + 30);
		this.#drawSprite(ferryRows, ferryX, 104, 2);
	}

	#drawGeiranger() {
		this.#fill(0, 0, width, height, color.black);
		// The steep walls of the fjord.
		for (let y = 20; y < 130; y += 2) {
			this.#fill(0, y, 70 + ((y - 20) * 0.5), 2, color.violet);
			this.#fill(210 - ((y - 20) * 0.5), y, 200, 2, color.violet);
		}

		this.#fill(0, 20, 60, 6, color.white);
		this.#fill(220, 20, 60, 6, color.white);
		this.#fill(70, 120, 140, 40, color.blue);
		this.#fill(0, 130, 70, 30, color.violet);
		this.#fill(210, 130, 70, 30, color.violet);
		// The Seven Sisters.
		for (let index = 0; index < 7; index++) {
			this.#fill(16 + (index * 6), 40 + (index % 2) * 4, 2, 70, color.white);
		}

		// The Eagle Road, in hairpin bends up the other side.
		for (let bend = 0; bend < 6; bend++) {
			const y = 120 - (bend * 14);
			const left = 220;
			this.#fill(left, y, 40, 2, color.white);
			this.#fill(bend % 2 === 0 ? left + 38 : left, y - 14, 2, 14, color.white);
		}

		this.#drawSprite(shipRows, 110, 112);
		this.#fill(80, 140, 120, 1, color.white);
	}

	#drawTrondheim() {
		this.#fill(0, 0, width, height, color.black);
		// The Nidaros Cathedral.
		this.#fill(150, 60, 110, 60, color.white);
		this.#fill(160, 30, 18, 90, color.white);
		this.#fill(232, 30, 18, 90, color.white);
		this.#drawMountain(169, 30, 18, 9, color.white);
		this.#drawMountain(241, 30, 18, 9, color.white);
		this.#drawMountain(205, 44, 30, 6, color.violet);
		this.#fill(196, 70, 18, 18, color.orange);
		this.#fill(204, 70, 2, 18, color.black);
		this.#fill(196, 78, 18, 2, color.black);
		for (let index = 0; index < 8; index++) {
			this.#fill(155 + (index * 13), 96, 6, 12, color.black);
		}

		this.#fill(198, 104, 14, 16, color.black);
		// The old wharf houses on the river.
		const houseColors = [color.orange, color.green, color.white, color.orange, color.violet];
		for (const [index, houseColor] of houseColors.entries()) {
			const x = 4 + (index * 26);
			this.#fill(x, 84, 22, 32, houseColor);
			this.#drawMountain(x + 11, 84, 10, 11, houseColor);

			this.#fill(x + 6, 92, 4, 6, color.black);
			this.#fill(x + 13, 92, 4, 6, color.black);
			this.#fill(x + 3, 116, 2, 8, color.white);
			this.#fill(x + 17, 116, 2, 8, color.white);
		}

		this.#fill(0, 120, width, 40, color.blue);
		// The Old Town Bridge.
		for (let x = 0; x < 120; x += 2) {
			this.#fill(80 + x, 118 + (Math.abs(Math.sin(x / 38)) * 8), 2, 3, color.orange);
		}

		this.#fill(80, 116, 120, 2, color.orange);
	}

	#drawArctic(time) {
		this.#fill(0, 0, width, height, color.black);
		if (this.#isMidnightSun()) {
			this.#drawSun(230, 52);
		}

		this.#drawMountain(40, 92, 24, 60, color.violet, 0.5);
		this.#drawMountain(160, 92, 30, 70, color.violet, 0.5);
		this.#drawMountain(260, 92, 20, 50, color.violet, 0.5);
		this.#fill(0, 92, width, 68, color.green);
		for (let index = 0; index < 16; index++) {
			this.#fill(hash(index) * width, 96 + (hash(index + 3) * 60), 10, 2, color.white);
		}

		// The line of the Arctic Circle.
		for (let x = 0; x < width; x += 8) {
			this.#fill(x, 126, 5, 2, color.white);
		}

		this.#drawText('66° 33′ N', 50, 116, color.white);
		// Stone towers.
		for (let index = 0; index < 8; index++) {
			this.#drawMountain(30 + (index * 30) + (hash(index + 9) * 10), 112 + ((index % 3) * 14), 8, 3, color.white);
		}

		// The globe on its stone.
		const centerX = 196;
		const centerY = 100;
		for (let angle = 0; angle < Math.PI * 2; angle += 0.15) {
			this.#fill(centerX + (Math.cos(angle) * 10), centerY + (Math.sin(angle) * 10), 1, 1, color.white);
			this.#fill(centerX + (Math.cos(angle) * 5), centerY + (Math.sin(angle) * 10), 1, 1, color.white);
		}

		this.#fill(centerX - 10, centerY, 21, 1, color.white);
		this.#fill(centerX - 4, centerY + 11, 8, 10, color.violet);
		this.#drawVolvo(80, 134);
		this.#drawPeople(130, 146);
		this.#drawSnow(this.#stillOrMoving(time) * 0.5);
	}

	#drawLofoten() {
		this.#fill(0, 0, width, height, color.black);
		if (this.#isMidnightSun()) {
			this.#drawSun(140, 60);
		}

		const peaks = [[20, 50], [55, 80], [90, 60], [190, 90], [230, 64], [262, 76]];
		for (const [x, peakHeight] of peaks) {
			this.#drawMountain(x, 104, peakHeight, peakHeight * 0.45, color.violet, 0.25);
		}

		this.#fill(0, 104, width, 56, color.blue);
		for (let index = 0; index < 16; index++) {
			this.#fill(hash(index + 7) * width, 112 + (hash(index + 8) * 44), 6, 1, color.white);
		}

		// Red fishing cabins on poles.
		for (let index = 0; index < 4; index++) {
			const x = 120 + (index * 24);
			this.#fill(x, 90, 20, 14, color.orange);
			this.#drawMountain(x + 10, 90, 8, 10, color.orange);

			this.#fill(x + 3, 94, 4, 4, color.white);
			this.#fill(x + 13, 94, 4, 4, color.white);
			this.#fill(x + 2, 104, 2, 8, color.white);
			this.#fill(x + 16, 104, 2, 8, color.white);
		}

		// A rack of drying cod.
		this.#fill(20, 84, 2, 24, color.white);
		this.#fill(80, 84, 2, 24, color.white);
		this.#fill(20, 84, 62, 2, color.white);
		for (let index = 0; index < 12; index++) {
			this.#fill(24 + (index * 5), 86, 2, 8, color.white);
			this.#fill(23 + (index * 5), 94, 4, 2, color.white);
		}
	}

	#drawTromso() {
		this.#fill(0, 0, width, height, color.black);
		if (this.#isMidnightSun()) {
			this.#drawSun(60, 30);
		}

		this.#drawMountain(60, 90, 50, 70, color.violet, 0.5);
		this.#drawMountain(230, 90, 60, 80, color.violet, 0.5);
		this.#fill(0, 90, width, 70, color.blue);
		// The bridge over the sound.
		for (let x = 0; x < width; x += 2) {
			this.#fill(x, 92 - (Math.sin((x / width) * Math.PI) * 14), 2, 2, color.white);
		}

		for (let x = 20; x < width; x += 24) {
			this.#fill(x, 92 - (Math.sin((x / width) * Math.PI) * 14), 1, 10, color.white);
		}

		// The Arctic Cathedral: white triangles one behind the other, smaller toward the back, with strips of glass between them.
		this.#fill(0, 140, width, 20, color.green);
		for (let layer = 6; layer >= 0; layer--) {
			const x = 100 + (layer * 12);
			const layerHeight = 62 - (layer * 7);
			this.#drawMountain(x, 140, layerHeight + 2, (layerHeight * 0.5) + 1, color.black);
			this.#drawMountain(x, 140, layerHeight, layerHeight * 0.5, color.white);
		}

		// The glass front with the cross.
		this.#drawMountain(100, 140, 40, 20, color.blue);
		this.#fill(99, 110, 2, 12, color.white);
		this.#fill(95, 114, 10, 2, color.white);
	}

	#drawAlta() {
		this.#fill(0, 0, width, height, color.black);
		this.#fill(0, 20, width, 110, color.violet);
		for (let index = 0; index < 40; index++) {
			this.#fill(hash(index) * width, 22 + (hash(index + 1) * 104), 6, 1, color.black);
		}

		// Rock carvings: reindeer, a boat, and hunters.
		const carving = [
			'o.o.........',
			'.o..........',
			'.oooooooo...',
			'..oooooooo..',
			'..o.o..o.o..',
			'..o.o..o.o..',
		];
		for (let index = 0; index < 5; index++) {
			this.#drawSprite(carving, 20 + (index * 50), 34 + ((index % 2) * 30), 2);
		}

		const boat = [
			'o.o.o.o.o.o.o',
			'ooooooooooooo',
			'.ooooooooooo.',
			'o...........o',
		];
		this.#drawSprite(boat, 120, 100, 2);
		for (let index = 0; index < 3; index++) {
			this.#drawSprite(['.o.', 'ooo', '.o.', 'o.o'], 210 + (index * 10), 104, 2);
		}

		this.#fill(0, 130, width, 30, color.green);
		this.#fill(0, 138, width, 3, color.white);
		this.#drawPeople(120, 152);
	}

	#drawNordkapp(time) {
		this.#fill(0, 0, width, height, color.black);
		if (this.#state.weather !== 'fog') {
			this.#drawSun(220, this.#isMidnightSun() ? 64 : 30);
		}

		this.#fill(0, 76, width, 84, color.blue);
		for (let index = 0; index < 20; index++) {
			this.#fill(((hash(index) * width) + this.#stillOrMoving(time * 3)) % width, 80 + (hash(index + 4) * 76), 6, 1, color.white);
		}

		// The cliff, 307 m straight down into the Arctic Ocean.
		for (let y = 60; y < height; y += 2) {
			const edge = 150 + ((y - 60) * 0.12) + (hash(y) * 6);
			this.#fill(0, y, edge, 2, color.violet);
		}

		this.#fill(0, 56, 156, 6, color.green);
		// The globe on its stand.
		const centerX = 110;
		const centerY = 30;
		for (let angle = 0; angle < Math.PI * 2; angle += 0.08) {
			this.#fill(centerX + (Math.cos(angle) * 16), centerY + (Math.sin(angle) * 16), 1, 1, color.white);
			this.#fill(centerX + (Math.cos(angle) * 8), centerY + (Math.sin(angle) * 16), 1, 1, color.white);
		}

		this.#fill(centerX - 16, centerY, 33, 1, color.white);
		this.#fill(centerX - 14, centerY - 8, 29, 1, color.white);
		this.#fill(centerX - 14, centerY + 8, 29, 1, color.white);
		this.#fill(centerX - 6, centerY + 17, 12, 40, color.white);
		this.#fill(centerX - 4, centerY + 19, 8, 36, color.black);
		this.#drawPeople(40, 56);
		this.#drawVolvo(2, 46);
		if (this.#state.weather === 'fog') {
			this.#drawFog();
		}
	}

	#drawStore(time) {
		this.#fill(0, 0, width, height, color.black);
		this.#drawMountain(50, 70, 40, 70, color.green);
		this.#drawMountain(230, 70, 50, 80, color.green);
		this.#fill(40, 46, 200, 74, color.white);
		this.#fill(40, 46, 200, 8, color.orange);
		this.#drawText('RIMI', 140, 60, color.blue, 4);
		this.#fill(126, 90, 28, 30, color.black);
		this.#fill(139, 90, 2, 30, color.white);
		for (let index = 0; index < 2; index++) {
			this.#fill(56 + (index * 30), 92, 22, 16, color.blue);
			this.#fill(174 + (index * 30), 92, 22, 16, color.blue);
		}

		this.#fill(0, 120, width, 40, color.black);
		for (let x = 0; x < width; x += 20) {
			this.#fill(x, 140, 10, 2, color.white);
		}

		this.#drawVolvo(20, 126);
		this.#drawRain(time, 50);
	}

	#drawTunnel(time) {
		this.#fill(0, 0, width, height, color.black);
		// The rough rock, blasted out of the mountain, in rings that get smaller into the dark.
		for (let ring = 0; ring < 8; ring++) {
			const scale = 1 - (ring * 0.12);
			const centerY = 96 + (44 * scale);
			for (let angle = Math.PI; angle <= Math.PI * 2; angle += 0.06 / scale) {
				const jag = hash(Math.round(angle * 50) + (ring * 7)) * 5 * scale;
				this.#fill(140 + (Math.cos(angle) * ((136 * scale) + jag)), centerY + (Math.sin(angle) * ((100 * scale) + jag)), 2, 2, ring % 2 === 0 ? color.violet : color.blue);
			}
		}

		for (let index = 0; index < 60; index++) {
			const angle = Math.PI + (hash(index) * Math.PI);
			const scale = 0.3 + (hash(index + 1) * 0.7);
			this.#fill(140 + (Math.cos(angle) * 136 * scale), 96 + (44 * scale) + (Math.sin(angle) * 100 * scale), 2, 2, color.violet);
		}

		// The road into the dark, with the beams of the headlights in a checkerboard, so they look faint.
		for (let y = 98; y < height; y += 2) {
			const spread = (y - 96) * 3;
			this.#fill(140 - spread, y, 2, 2, color.white);
			this.#fill(140 + spread, y, 2, 2, color.white);
		}

		const dashOffset = this.#stillOrMoving(time * 20) % 8;
		for (let y = 98 + dashOffset; y < height; y += 8) {
			this.#fill(139, y, 2, Math.max(1, (y - 96) / 8), color.white);
		}

		this.#context.fillStyle = color.white;
		for (let y = 110; y < height; y += 2) {
			const spread = (y - 100) * 1.4;
			for (let x = Math.round(140 - spread); x < 140 + spread; x += 4) {
				this.#context.fillRect(x + ((y / 2) % 2 === 0 ? 0 : 2), y, 1, 1);
			}
		}

		// Drops from the roof.
		for (let index = 0; index < 14; index++) {
			const y = (20 + (hash(index) * 80) + this.#stillOrMoving(time * 60)) % 110;
			this.#fill(50 + (hash(index + 5) * 180), y, 1, 3, color.blue);
		}

		// The tail lights of a truck far ahead.
		this.#fill(134, 100, 2, 2, color.orange);
		this.#fill(144, 100, 2, 2, color.orange);
	}

	#drawChurch() {
		this.#fill(0, 0, width, height, color.black);
		this.#drawMountain(60, 110, 60, 80, color.violet, 0.3);
		this.#drawMountain(240, 110, 70, 80, color.violet, 0.3);
		this.#fill(0, 110, width, 50, color.green);
		// A stave church: walls of tarred wood under roofs on roofs, with dragon heads on the gables.
		const centerX = 140;
		const tiers = [{halfWidth: 40, top: 104, wall: 26}, {halfWidth: 27, top: 76, wall: 14}, {halfWidth: 16, top: 52, wall: 10}];
		for (const {halfWidth, top, wall} of tiers) {
			this.#fill(centerX - halfWidth + 6, top, (halfWidth - 6) * 2, wall, color.orange);
			this.#drawMountain(centerX, top, 14, halfWidth, color.violet);
			this.#fill(centerX - halfWidth - 3, top - 3, 4, 2, color.orange);
			this.#fill(centerX + halfWidth - 1, top - 3, 4, 2, color.orange);
		}

		this.#drawMountain(centerX, 38, 24, 6, color.violet);
		this.#fill(centerX - 1, 6, 2, 8, color.white);
		this.#fill(centerX - 3, 8, 6, 2, color.white);
		for (let x = centerX - 30; x < centerX + 30; x += 6) {
			this.#fill(x, 104, 1, 26, color.black);
		}

		this.#fill(centerX - 5, 116, 10, 14, color.black);
		this.#drawPeople(centerX + 40, 146, [4]);
		this.#drawVolvo(20, 140);
	}

	#drawCassette(time) {
		this.#fill(0, 0, width, height, color.black);
		this.#fill(70, 30, 140, 86, color.white);
		this.#fill(80, 38, 120, 30, color.orange);
		this.#drawText(this.#scene.label ?? 'A-HA', 140, 48, color.black, 2);
		this.#fill(100, 78, 80, 26, color.black);
		for (const x of [116, 164]) {
			for (let angle = 0; angle < Math.PI * 2; angle += 0.3) {
				this.#fill(x + (Math.cos(angle + this.#stillOrMoving(time)) * 8), 91 + (Math.sin(angle + this.#stillOrMoving(time)) * 8), 2, 2, color.white);
			}
		}

		// The tape that came out, in loops all over the car.
		for (let index = 0; index < 200; index++) {
			const progress = index / 200;
			const x = 140 + (Math.sin(progress * 19) * 60 * progress) + (progress * 40);
			const y = 116 + (progress * 40) + (Math.cos(progress * 23) * 10);
			this.#fill(x, y, 2, 1, color.orange);
		}
	}

	#fillPolygon(points, fillColor) {
		this.#context.fillStyle = fillColor;
		this.#context.beginPath();
		for (const [index, point] of points.entries()) {
			const [x, y] = project(point);
			if (index === 0) {
				this.#context.moveTo(x, y);
			} else {
				this.#context.lineTo(x, y);
			}
		}

		this.#context.closePath();
		this.#context.fill();
	}

	#drawLine([fromX, fromY], [toX, toY], lineColor, dash = 0) {
		const steps = Math.max(1, Math.ceil(Math.hypot(toX - fromX, toY - fromY)));
		for (let step = 0; step <= steps; step++) {
			if (dash > 0 && Math.floor(step / dash) % 2 === 1) {
				continue;
			}

			this.#fill(fromX + (((toX - fromX) * step) / steps), fromY + (((toY - fromY) * step) / steps), 1, 1, lineColor);
		}
	}

	#carPosition() {
		const from = route[Math.max(0, this.#state.next - 1)];
		const to = route[Math.min(route.length - 1, this.#state.next)];
		const progress = to.km === from.km ? 0 : (this.#state.km - from.km) / (to.km - from.km);
		const [fromX, fromY] = project(from.lonLat);
		const [toX, toY] = project(to.lonLat);
		return [fromX + ((toX - fromX) * progress), fromY + ((toY - fromY) * progress)];
	}

	#drawMap(time) {
		this.#fill(0, 0, width, height, color.black);
		this.#fillPolygon(coast, color.green);
		this.#fillPolygon(lofotenIslands, color.green);
		for (let index = 1; index < route.length; index++) {
			this.#drawLine(project(route[index - 1].lonLat), project(route[index].lonLat), index < this.#state.next || (index === this.#state.next && this.#state.km >= route[index].km) ? color.white : color.violet, index >= this.#state.next ? 2 : 0);
		}

		for (const stop of route) {
			const [x, y] = project(stop.lonLat);
			this.#fill(x - 1, y - 1, 3, 3, stop.kind === 'ferry' ? color.blue : color.white);
		}

		const [carX, carY] = this.#carPosition();
		const isBlinkOn = this.reducedMotion || Math.floor(time * 3) % 2 === 0;
		this.#fill(carX - 2, carY - 2, 5, 5, isBlinkOn ? color.orange : color.white);

		this.#drawText('NORGE 1999', 210, 10, color.white, 2);
		this.#drawText(`${formatNumber(this.#state.km)} OF ${formatNumber(totalKilometers)} KM`, 210, 30, color.green);
		const next = this.#nextStop();
		if (next) {
			this.#drawText('NEXT:', 210, 44, color.violet);
			for (const [index, line] of wrapText(next.name.replace(/^the /, ''), 16).entries()) {
				this.#drawText(line, 210, 52 + (index * 7), color.white);
			}
		}

		this.#fill(166, 128, 5, 5, color.orange);
		this.#drawText('THE VOLVO', 174, 128, color.white, 1, 'left');
		this.#fill(167, 140, 3, 3, color.blue);
		this.#drawText('FERRY', 174, 139, color.white, 1, 'left');
		this.#fill(167, 150, 3, 3, color.white);
		this.#drawText('LANDMARK', 174, 149, color.white, 1, 'left');
	}

	#drawTitle(time) {
		this.#fill(0, 0, width, height, color.black);
		this.#drawText('THE BERGEN TRAIL', 140, 12, color.white, 3);
		this.#fill(44, 32, 192, 2, color.green);
		this.#drawText('BERGEN TO NORDKAPP, SUMMER 1999', 140, 40, color.green);
		this.#drawMountain(40, 112, 54, 60, color.violet, 0.3);
		this.#drawMountain(120, 112, 64, 70, color.violet, 0.3);
		this.#drawMountain(220, 112, 50, 66, color.violet, 0.3);
		this.#fill(0, 104, width, 8, color.blue);
		this.#fill(0, 112, width, 48, color.green);
		this.#fill(0, 128, width, 16, color.black);
		for (let x = 0; x < width; x += 20) {
			this.#fill(x, 135, 10, 2, color.white);
		}

		const x = this.reducedMotion ? 120 : ((time * 30) % (width + 80)) - 40;
		this.#drawVolvo(x, 121, this.reducedMotion ? 0 : Math.floor(time * 10));
		this.#drawSun(240, 60);
	}

	#drawGravestone({lines, small}) {
		this.#fill(0, 0, width, height, color.black);
		for (let index = 0; index < 30; index++) {
			this.#fill(hash(index) * width, hash(index + 1) * 60, 1, 1, color.white);
		}

		this.#fill(0, 130, width, 30, color.green);
		for (let row = 0; row < 20; row += 2) {
			this.#fill(width / 2 - 100 - row, 130 - row + 20, 200 + (row * 2), 2, color.green);
		}

		const stoneWidth = small ? 100 : 150;
		const stoneHeight = small ? 80 : 110;
		const left = (width - stoneWidth) / 2;
		const top = 132 - stoneHeight;
		this.#fill(left, top + 10, stoneWidth, stoneHeight - 10, color.white);
		this.#fill(left + 10, top, stoneWidth - 20, 10, color.white);
		this.#fill(left + 4, top + 4, stoneWidth - 8, 8, color.white);
		for (const [index, line] of lines.entries()) {
			this.#drawText(line, width / 2, top + 12 + (index * 9), color.black);
		}

		this.#drawPeople(left - 30, 146);
	}

	#drawFishing(time) {
		const still = this.reducedMotion;
		this.#fill(0, 0, width, height, color.black);
		this.#drawMountain(220, 70, 40, 60, color.violet, 0.3);
		this.#drawMountain(270, 70, 30, 40, color.violet, 0.3);
		if (this.#isMidnightSun()) {
			this.#drawSun(180, 52);
		}

		this.#fill(0, 70, width, 90, color.blue);
		for (let index = 0; index < 20; index++) {
			this.#fill(((hash(index) * width) + (still ? 0 : time * 6)) % width, 74 + (hash(index + 1) * 80), 5, 1, color.white);
		}

		// The quay, the Volvo, and Sindre with the rod.
		this.#fill(0, 60, 70, 12, color.orange);
		for (let x = 4; x < 70; x += 12) {
			this.#fill(x, 72, 3, 40, color.orange);
		}

		this.#drawVolvo(2, 49);
		this.#drawPeople(52, 60, [2]);
		const isBite = this.#fishing.phase === 'bite';
		const bob = still || isBite ? 0 : Math.round(Math.sin(time * 3));
		const floatX = 180;
		const floatY = isBite ? 76 : 70 + bob;
		this.#drawLine([56, 50], [62, 40], color.white);
		this.#drawLine([62, 40], [floatX, floatY - 2], color.white);
		this.#fill(floatX - 2, floatY - 4, 4, 3, color.orange);
		this.#fill(floatX - 2, floatY - 1, 4, 3, color.white);
		if (isBite) {
			this.#drawText('!', floatX, 56, color.orange, 3);
			for (let ring = 0; ring < 3; ring++) {
				this.#fill(floatX - 8 - (ring * 4), 72 + ring, 16 + (ring * 8), 1, color.white);
			}
		}

		// Cod under the water.
		if (!still) {
			for (let index = 0; index < 3; index++) {
				const x = ((index * 110) + (time * (10 + (index * 4)))) % (width + 40) - 20;
				this.#drawSprite(codRows, x, 100 + (index * 18));
			}
		} else {
			this.#drawSprite(codRows, 120, 110);
		}

		if (this.#fishing.flash && this.#fishing.time < this.#fishing.flashUntil) {
			this.#fill(60, 10, 160, 40, color.black);
			this.#drawText(this.#fishing.flash, 140, 16, color.white, 2);
			if (this.#fishing.flashKilograms > 0) {
				this.#drawSprite(codRows, 118, 28, 3);
			}
		}

		// Twice the size of the other small letters, so a phone shows the catch and the time big enough to read.
		this.#fill(212, 126, 68, 32, color.black);
		this.#drawText(`${formatNumber(this.#fishing.total)} KG`, 246, 130, color.green, 2);
		this.#drawText(`TIME ${Math.max(0, Math.ceil(this.#fishing.timeLeft))}`, 246, 144, color.white, 2);
	}

	#draw() {
		const time = this.#animationTime;
		if (this.#scene.kind === 'travel') {
			this.#drawTravel(this.#scene.overlay);
		} else if (this.#scene.kind === 'ferry') {
			this.#drawFerryScene(time, this.#scene.crossing);
		} else if (this.#scene.kind === 'gravestone') {
			this.#drawGravestone(this.#scene);
		} else {
			(this.#pictureDrawers[this.#scene.kind] ?? this.#pictureDrawers.title)(time);
		}
	}

	// The pictures that move, which only run when the visitor allows motion. Fishing also runs with reduced motion, as the float must go under in time, but nothing else moves then. Fishing waits while another screen, like the question of “Start a New Trip”, covers it.
	#isFishing() {
		return this.#currentScreen === 'fishing' && !this.#fishing.isOver;
	}

	#isAnimated() {
		if (this.#isFishing()) {
			return true;
		}

		return !this.reducedMotion && ['travel', 'title', 'ferry', 'bergen', 'store', 'map', 'tunnel', 'cassette', 'arctic', 'nordkapp'].includes(this.#scene.kind);
	}

	#setScene(kind, options = {}) {
		this.#scene = {...options, kind};
		this.#draw();
		this.#loop.start();
	}

	// MARK: The days

	#payPetrol(kilometers) {
		let cost = Math.round(kilometers * 0.9);
		const fromEnvelope = Math.min(cost, this.#state.petrolMoney);
		this.#state.petrolMoney -= fromEnvelope;
		cost -= fromEnvelope;
		if (cost > this.#state.money) {
			this.#state.money = 0;
			return false;
		}

		this.#state.money -= cost;
		return true;
	}

	// Eats the food of one day, the fish first, as it does not keep, then the extra food, the bread, and the brown cheese.
	#eat(need) {
		let left = need;
		for (const key of ['fish', 'extraFood', 'bread', 'cheese']) {
			const amount = Math.min(left, this.#state[key]);
			this.#state[key] = Math.round((this.#state[key] - amount) * 10) / 10;
			left -= amount;
		}

		return need - left;
	}

	// One day passes for the family: they eat, their health changes, people get sick or better, and Lillesøster asks. It returns the news of the day for the screen.
	#passDay({isResting = false, isDriving: driving = false} = {}) {
		const news = [];
		const need = rations[this.#state.rations].kilograms * 5;
		const eaten = this.#eat(need);
		const isFed = eaten >= need - 0.01;
		// The news comes on the day the food runs out, not on every hungry day after it, which would stop the Volvo every 2 seconds.
		if (!isFed && eaten > 0) {
			news.push(`There is no food left. ${this.#names()[3]} eats the air freshener of the Volvo.`);
		}

		for (let index = 0; index < 5; index++) {
			let change = isResting ? 6 : (driving ? paces[this.#state.pace].health : 1);
			change += rations[this.#state.rations].health;
			if (!isFed) {
				change -= 8;
			}

			if (this.#state.cheese <= 0) {
				change -= 1;
			}

			if (driving && (this.#state.weather === 'rain' || this.#state.weather === 'heavy rain')) {
				change -= 1;
			}

			const condition = this.#state.conditions[index];
			if (condition === 'boredom') {
				change -= 5;
				if (this.#state.kvikkLunsj > 0) {
					this.#state.kvikkLunsj -= 1;
					this.#state.conditions[index] = '';
					news.push(`${this.#names()[index]} ate a Kvikk Lunsj and is not bored anymore. The mountain rules on the wrapper were read out loud. Again.`);
				}
			} else if (condition) {
				change -= 4;
				if (Math.random() < (isResting ? 0.45 : 0.15)) {
					this.#state.conditions[index] = '';
				}
			}

			this.#state.health[index] = clamp(this.#state.health[index] + change, 0, 100);

			const sickChance = 0.012 + (this.#state.health[index] < 50 ? 0.03 : 0) + (this.#state.pace === 'hurry' ? 0.02 : 0) + (this.#state.rations === 'bare' ? 0.02 : 0);
			if (!this.#state.conditions[index] && driving && Math.random() < sickChance) {
				let options = conditions;
				if (index === 0) {
					options = conditions.filter(name => name !== 'carsickness');
				}

				const newCondition = randomItem(options);
				this.#state.conditions[index] = newCondition;
				news.push(`${this.#names()[index]} has ${newCondition}.`);
			}

			const boredChance = (this.#occupation() === occupations.teacher ? 0.012 : 0.025) * (driving ? 1 : 0.3);
			if (!this.#state.conditions[index] && index !== 0 && Math.random() < boredChance) {
				this.#state.conditions[index] = 'boredom';
				news.push(`${this.#names()[index]} is bored.`);
			}
		}

		if (driving) {
			const asked = randomInteger(3, 11);
			this.#state.asked += this.#occupation() === occupations.teacher ? Math.ceil(asked / 2) : asked;
		}

		// Fish does not keep in a warm car.
		this.#state.fish = Math.floor(this.#state.fish * 0.6);
		this.#state.day += 1;
		if (news.length > 3) {
			news.length = 3;
		}

		return news;
	}

	#loseDays(count) {
		const news = [];
		for (let day = 0; day < count; day++) {
			news.push(...this.#passDay());
		}

		return news;
	}

	#rollWeather() {
		let rain = [0.4, 0.35, 0.4, 0.5, 0.7][this.#state.month - 4];
		if (this.#state.km < 200) {
			rain += 0.25;
		}

		const roll = Math.random();
		if ((this.#state.month === 4 || this.#state.month === 8) && (regionOf(this.#state.km) === 'north' || (this.#state.km > 250 && this.#state.km < 450)) && roll < 0.15) {
			return 'snow';
		}

		if (roll < rain * 0.3) {
			return 'heavy rain';
		}

		if (roll < rain) {
			return 'rain';
		}

		if (roll < rain + 0.12) {
			return 'fog';
		}

		if (this.#state.month === 6 || this.#state.month === 7) {
			return roll < 0.85 ? 'sunny' : 'warm';
		}

		return roll < 0.8 ? 'cool' : 'sunny';
	}

	// Why a trip ends before Nordkapp, if it does.
	#tripOverCause() {
		if (this.#state.day >= holidayDays) {
			return 'holiday';
		}

		if (this.#averageHealth() < 8) {
			return 'tired';
		}

		return undefined;
	}

	#firstBoredToDeath() {
		return this.#state.health.findIndex(value => value <= 0);
	}

	#driveDay() {
		const stop = this.#nextStop();
		// A trip that was saved on the day of an arrival arrives at once.
		if (stop.km <= this.#state.km) {
			this.#arrive();
			return;
		}

		this.#state.weather = this.#rollWeather();
		let distance = paces[this.#state.pace].km * (weatherSpeed[this.#state.weather] ?? 1);
		if (this.#averageHealth() < 30) {
			distance *= 0.75;
		}

		distance = Math.max(10, Math.round(distance));
		const remaining = stop.km - this.#state.km;
		const isArriving = distance >= remaining;
		if (isArriving) {
			distance = remaining;
		}

		if (!this.#payPetrol(distance)) {
			this.#showTripOver('petrol');
			return;
		}

		this.#state.km += distance;
		const news = this.#passDay({isDriving: true});
		this.#saveTrip();

		// Reaching Nordkapp counts, also on the last day of the holiday.
		if (isArriving && stop.kind === 'end') {
			this.#arrive();
			return;
		}

		if (this.#continueAfter(news, isArriving ? () => this.#arrive() : () => this.#showTravel())) {
			return;
		}

		if (isArriving) {
			this.#arrive();
			return;
		}

		// One gravestone a day, the first on the road first, so two close together, or one at a landmark or a ferry, where the day ends with the arrival, are still passed on the next day.
		const [tombstone] = this.#tombstones.filter(stone => stone.km <= this.#state.km && !this.#state.seen.includes(tombstoneId(stone))).toSorted((first, second) => first.km - second.km);
		if (tombstone) {
			this.#state.seen.push(tombstoneId(tombstone));
			this.#saveTrip();
			this.#showPassedTombstone(tombstone);
			return;
		}

		const event = this.#pickEvent();
		if (event) {
			this.#saveTrip();
			this.#showEvent(event);
			return;
		}

		this.#updateTravel();
	}

	// Shows what must be shown after days have passed: the end of the trip, someone who died of boredom, or the news. It returns whether it showed something.
	#continueAfter(news, then = () => this.#showTravel()) {
		const cause = this.#tripOverCause();
		if (cause) {
			this.#showTripOver(cause);
			return true;
		}

		const bored = this.#firstBoredToDeath();
		if (bored >= 0) {
			this.#showBoredToDeath(bored, then);
			return true;
		}

		if (news.length > 0) {
			this.#audio.alert();
			this.#showMessage({lines: news, picture: {kind: 'travel'}, then});
			return true;
		}

		return false;
	}

	// MARK: The events

	#passengers() {
		return [1, 2, 3, 4].filter(index => !this.#state.conditions[index]);
	}

	#churchHere() {
		if (this.#state.km < 185) {
			return 'Hopperstad Stave Church in Vik, from about 1130';
		}

		if (this.#state.km < 690) {
			return 'Lom Stave Church, from about 1160';
		}

		if (this.#state.km < 1360) {
			return 'a small white wooden church on a hill, like all the others';
		}

		if (this.#state.km < 1760) {
			return 'Flakstad Church in Lofoten, red and from 1780';
		}

		if (this.#state.km < 2330) {
			return 'Kåfjord Church in Alta, built by English copper miners in 1837';
		}

		return 'Honningsvåg Church, the only building in town that was left standing after the war';
	}

	#tapes() {
		return [
			{label: 'A-HA', name: 'a-ha’s “Hunting High and Low”'},
			{label: 'SPICE', name: `${this.#names()[3]}’s Spice Girls tape`},
			{label: 'VAZELINA', name: 'Vazelina Bilopphøggers'},
			{label: 'SALMER', name: `${this.#names()[4]}’s hymns`},
			{label: 'DIRE', name: `${this.#names()[0]}’s “Best of Dire Straits”`},
		];
	}

	#healAll(amount) {
		for (let index = 0; index < 5; index++) {
			this.#state.health[index] = clamp(this.#state.health[index] + amount, 0, 100);
		}
	}

	#pickEvent() {
		const milestone = this.#askedMilestones.find(([count]) => this.#state.asked >= count && this.#state.askedMilestone < count);
		if (milestone) {
			this.#state.askedMilestone = milestone[0];
			return {lines: [milestone[1]()]};
		}

		const date = this.#today();
		const dateEvent = this.#dateEvents.find(event => event.month === date.getMonth() && event.day === date.getDate() && !this.#state.seen.includes(event.id) && (event.when?.() ?? true));
		if (dateEvent) {
			this.#state.seen.push(dateEvent.id);
			dateEvent.effect?.();
			return {overlay: dateEvent.overlay, lines: [dateEvent.text()]};
		}

		if (Math.random() > 0.42) {
			return undefined;
		}

		const possible = this.#events.filter(event => event.when?.() ?? true).map(event => {
			let weight = event.weight;
			if (event.hurryWeight && this.#state.pace === 'hurry') {
				weight = event.hurryWeight;
			}

			if (event.noMapWeight) {
				weight = this.#state.map ? event.mapWeight : event.noMapWeight;
			}

			return {event, weight};
		});

		return weightedItem(possible).event.run();
	}

	#showEvent(event) {
		this.#audio.alert();
		const picture = event.picture ? {kind: event.picture, label: event.label} : {kind: 'travel', overlay: event.overlay};
		if (!event.choices) {
			this.#showMessage({lines: event.lines, picture, then: () => this.#afterEvent()});
			return;
		}

		this.#setScene(picture.kind, picture);
		this.#showScreen('event', () => {
			for (const line of event.lines) {
				this.#addLine(line);
			}

			this.#addMenu(event.choices.map(choice => ({
				label: choice.label,
				action: () => {
					this.#showMessage({lines: [choice.outcome()], picture, then: () => this.#afterEvent()});
				},
			})));
		});
		this.say(event.lines[0]);
	}

	#afterEvent() {
		this.#saveTrip();
		if (!this.#continueAfter([])) {
			this.#showTravel();
		}
	}

	// MARK: The gravestones

	#savedTombstones() {
		return this.stored('tombstones', []).filter(stone => typeof stone?.km === 'number' && typeof stone.epitaph === 'string' && typeof stone.name === 'string');
	}

	#showPassedTombstone(stone) {
		this.#audio.sad();
		this.#showMessage({
			title: 'A gravestone by the road',
			lines: [`You pass the gravestone of an old trip. It says: “Here lies the trip of ${stone.name}. ${stone.epitaph}”`, `${this.#names()[4]} wants to stop and read it twice.`],
			picture: {kind: 'gravestone', lines: tombstoneLines(stone.name, stone.epitaph)},
			then: () => this.#showTravel(),
		});
	}

	#showBoredToDeath(index, then) {
		const name = this.#names()[index];
		const date = this.#today();
		this.#state.boredomDeaths += 1;
		this.#state.health[index] = 35;
		this.#state.conditions[index] = '';
		this.#saveTrip();
		this.#audio.sad();
		const comebacks = [
			`${this.#names()[0]} turns on the radio. ${name} sits up and says: “Is that the news?” ${name} is alive again.`,
			`${this.#names()[1]} opens a new pack of Kvikk Lunsj. ${name} rises from the dead at once.`,
			`${this.#names()[2]} says there is a moose outside. There is not, but ${name} came back to life to see it.`,
		];
		this.#showMessage({
			title: `${name} has died of boredom.`,
			lines: [`Here lies ${name}, who died of boredom on ${formatDate(date)}, at km ${formatNumber(this.#state.km)}.`, randomItem(comebacks)],
			picture: {kind: 'gravestone', small: true, lines: ['HERE LIES', name.toUpperCase().slice(0, 22), 'DIED OF', 'BOREDOM', `${date.getDate()}.${date.getMonth() + 1}.1999`]},
			then,
			statusText: `${name} has died of boredom.`,
		});
	}

	#showTripOver(cause) {
		this.store('trip', undefined);
		this.#state.isStarted = false;
		this.#audio.sad();
		const name = this.#names()[0];
		let epitaph = '';
		this.#setScene('gravestone', {lines: tombstoneLines(name, epitaph)});
		this.#showScreen('tombstone', () => {
			this.#addHeading('The trip is over');
			this.#addLine(this.#tripOverReasons[cause]());
			this.#addLine('Like the trips of the real Oregon Trail, this one gets a gravestone by the road, where the next trip will pass it.');
			const form = element('form');
			const label = element('label', 'Write the epitaph: ');
			const input = element('input');
			input.type = 'text';
			input.maxLength = 60;
			input.autocomplete = 'off';
			input.placeholder = 'Er vi fremme snart?';
			label.append(input);
			form.append(label);
			this.parts.screen.append(form);
			this.#addMenu([
				{
					label: 'Carve it in stone',
					action: () => {
						epitaph = input.value.trim() || 'Er vi fremme snart?';
						const stones = this.#savedTombstones();
						stones.push({km: this.#state.km, name, epitaph});
						this.store('tombstones', stones.slice(-10));
						this.#tombstones = [...oldTombstones, ...stones.slice(-10)];
						this.#scene.lines = tombstoneLines(name, epitaph);
						this.#draw();
						this.#showMessage({
							lines: [`The gravestone stands at km ${formatNumber(this.#state.km)}: “Here lies the trip of ${name}. ${epitaph}” The next trip will drive past it.`],
							then: () => this.#showTitle(),
						});
					},
				},
				{label: 'Go back to the start', action: () => this.#showTitle()},
			]);
			input.addEventListener('input', () => {
				this.#scene.lines = tombstoneLines(name, input.value.trim());
				this.#draw();
			});
			form.addEventListener('submit', event => {
				event.preventDefault();
				this.#menuButtons[0].click();
			});
			if (this.#focusAfterRender) {
				input.focus({preventScroll: true});
			}
		});
		this.say('The trip is over. Write the epitaph of its gravestone.');
	}

	// MARK: Arriving

	#arrive() {
		const stop = this.#nextStop();
		this.#audio.arrive();
		if (stop.kind === 'ferry') {
			this.#state.at = this.#state.next;
			this.#saveTrip();
			if (stop.isNorthCape && this.#today() >= tunnelOpening) {
				this.#showNorthCapeTunnel();
			} else {
				this.#showFerry();
			}

			return;
		}

		if (stop.kind === 'end') {
			this.#showNordkapp();
			return;
		}

		this.#state.at = this.#state.next;
		this.#state.next += 1;
		this.#saveTrip();
		this.#showLandmark(stop);
	}

	#showLandmark(stop) {
		this.#setScene(stop.picture);
		this.#showScreen('landmark', () => {
			this.#addHeading(stop.name.replace(/^the /, 'The '));
			this.#addLine(formatDate(this.#today()));
			this.#addLine(this.#withNames(stop.text));
			this.#addMenu([{label: 'Look around', action: () => this.#showSizeUp()}], 'Press SPACE BAR to continue');
			this.#primaryAction = () => this.#showSizeUp();
		});
		this.say(`You are now at ${stop.name}.`);
	}

	#queueFor() {
		const base = {4: 6, 5: 20, 6: 60, 7: 30, 8: 4}[this.#state.month] ?? 20;
		return randomInteger(Math.round(base * 0.5), Math.round(base * 1.5));
	}

	#showFerry(isReturning = false) {
		const crossing = route[this.#state.at];
		if (!isReturning || this.#ferryQueue === 0) {
			this.#ferryQueue = this.#queueFor();
		}

		const ticket = crossing.ticket;
		const capacity = 30;
		this.#setScene('ferry', {crossing});
		this.#showScreen('ferry', () => {
			this.#addHeading(`The ferry ${crossing.ferry}`);
			this.#addLine(this.#withNames(crossing.text));
			this.#addField('Weather', this.#state.weather);
			this.#addField('The queue', `${this.#ferryQueue} cars, and the ferry takes ${capacity}${this.#state.month === 6 ? ' (it is the common holiday)' : ''}`);
			this.#addField('The ticket', `${kroner(ticket)} for the car and five people`);
			this.#addField('Money', kroner(this.#state.money));
			const items = [];
			if (this.#state.money >= ticket) {
				items.push(
					{label: 'Wait in the ferry queue', action: () => this.#crossByFerry({isSneaking: false})},
					{label: 'Drive up the ramp as it lifts', action: () => this.#crossByFerry({isSneaking: true})},
				);
			} else {
				this.#addLine({bold: 'You do not have the money for the ticket.'});
			}

			items.push(
				{label: `Drive around (${crossing.aroundDays} days)`, action: () => this.#driveAround()},
				{label: 'Ask the ferry man', action: () => this.#askFerryMan()},
			);
			this.#addMenu(items);
		});
		this.say(`You must cross ${crossing.name}.`);
	}

	#askFerryMan() {
		const crossing = route[this.#state.at];
		this.#showMessage({lines: [this.#withNames(randomItem(crossing.advice))], then: () => this.#showFerry(true)});
	}

	#finishCrossing(lines, news = []) {
		this.#state.at = undefined;
		this.#state.next += 1;
		this.#saveTrip();
		this.#showMessage({lines: [...lines, ...news], then: () => {
			if (!this.#continueAfter([])) {
				this.#showTravel();
			}
		}});
	}

	#crossByFerry({isSneaking}) {
		const crossing = route[this.#state.at];
		const [pappa, , sindre, sister, mormor] = this.#names();
		const lines = [];
		let hours = Math.ceil(this.#ferryQueue / 30) * (crossing.water === 'sea' ? 4 : 1);
		if (isSneaking) {
			const roll = Math.random();
			if (roll < 0.45) {
				hours = 0;
				lines.push(`${pappa} drives up the ramp as it lifts, and the Volvo makes it with a bump! The ferry man shakes his head, but takes the money.`);
			} else if (roll < 0.8) {
				hours += 3;
				lines.push(`The ferry man in the orange vest waves ${pappa} back to the end of the queue. Everybody in the queue claps. You wait ${hours} hours.`);
			} else {
				hours = 0;
				const bread = Math.min(this.#state.bread, randomInteger(3, 8));
				const cheese = Math.min(this.#state.cheese, randomInteger(1, 3));
				this.#state.bread -= bread;
				this.#state.cheese -= cheese;
				lines.push(`The Volvo jumps the gap to the ferry! The roof box flies open: you lost ${bread} loaves of bread and ${cheese} kg of brown cheese, and ${mormor}’s hat floats away on the fjord.`);
			}
		} else {
			lines.push(`You wait in the queue for ${hours} ${hours === 1 ? 'hour' : 'hours'}${hours > 8 ? ', and sleep in the car' : ''}. ${mormor} buys ferry waffles for everybody.`);
			this.#healAll(3);
		}

		this.#state.money -= crossing.ticket;
		const seasick = [1, 3, 4].filter(index => !this.#state.conditions[index]);
		if (crossing.water === 'sea' && seasick.length > 0 && Math.random() < 0.6) {
			const index = randomItem(seasick);
			this.#state.conditions[index] = 'seasickness';
			lines.push(`The waves are big. ${this.#names()[index]} has seasickness, but ${sindre} eats two more waffles.`);
		} else {
			lines.push(`The crossing is calm. ${sister} sees a porpoise, or a plastic bag.`);
		}

		const news = hours > 8 ? this.#passDay() : [];
		this.#finishCrossing(lines, news);
	}

	#driveAround() {
		const crossing = route[this.#state.at];
		const extraKilometers = crossing.aroundDays * 150;
		if (!this.#payPetrol(extraKilometers)) {
			this.#showTripOver('petrol');
			return;
		}

		this.#state.asked += crossing.aroundDays * 25;
		const news = this.#loseDays(crossing.aroundDays);
		this.#finishCrossing([this.#withNames(crossing.around), `It takes ${crossing.aroundDays} days and ${extraKilometers} km of petrol.`], news);
	}

	#showNorthCapeTunnel() {
		const toll = 145;
		this.#state.money = Math.max(0, this.#state.money - toll);
		this.#state.at = undefined;
		this.#state.next += 1;
		this.#saveTrip();
		this.#showMessage({
			title: 'The North Cape Tunnel',
			lines: [`The new North Cape Tunnel opened on 15 June 1999! It is 6.8 km long and goes 212 m under the sea to Magerøya. ${this.#names()[0]} pays the toll of ${kroner(toll)}, and ${this.#names()[4]} holds her breath the whole way.`],
			picture: {kind: 'tunnel'},
			then: () => this.#showTravel(),
		});
	}

	#showNordkapp() {
		this.#state.isStarted = false;
		this.store('trip', undefined);
		this.#state.weather = Math.random() < 0.4 ? 'fog' : 'sunny';
		const fee = 175 * 5;
		const lines = ['Nordkapp! 71° 10′ 21″ North, the north end of Europe. Well, almost: Knivskjellodden is 1.5 km farther north, but you have to walk 18 km for it, so it does not count. A cliff of 307 m drops straight into the Arctic Ocean, and the steel globe stands on the edge.'];
		if (this.#state.money >= fee) {
			this.#state.money -= fee;
			lines.push(`You pay 175 kr each to get into the North Cape Hall. ${this.#names()[0]} says the view costs extra. It is a joke. Nobody laughs.`);
		} else {
			lines.push(`You do not have the ${kroner(fee)} to get into the North Cape Hall, so you look at the globe through the fence. It is the same globe.`);
		}

		lines.push(this.#state.weather === 'fog' ? 'It is foggy. You drove 2400 km to see a wall of white. Everybody agrees that it is a very northern wall.' : this.#isMidnightSun() ? `The midnight sun hangs over the sea at midnight, and everybody is quiet for once. Even ${this.#names()[3]}.` : 'The sun is out, and you can see all the way to the North Pole. Almost.');
		lines.push(`${this.#names()[3]} asks “Er vi fremme nå?” (“Are we there now?”) Yes. YES!`);
		this.#audio.fanfare();
		this.celebrate();
		this.toast('The Volvo made it to Nordkapp!');
		this.#showMessage({
			title: 'You made it to Nordkapp!',
			lines,
			picture: {kind: 'nordkapp'},
			then: () => this.#showScore(),
		});
	}

	// MARK: Score

	#topTen() {
		const list = this.stored('top-ten', []).filter(entry => typeof entry?.name === 'string' && typeof entry.points === 'number');
		return list.length > 0 ? list : seedTopTen;
	}

	#scoreRows() {
		const rows = [];
		const counts = {};
		for (const value of this.#state.health) {
			const word = healthWord(value);
			counts[word] = (counts[word] ?? 0) + 1;
		}

		for (const [word, count] of Object.entries(counts)) {
			rows.push([`${count} ${count === 1 ? 'person' : 'people'} in ${word} health`, count * healthPoints[word]]);
		}

		rows.push(
			['The Volvo 240', 50],
			[`${this.#state.tires} spare ${this.#state.tires === 1 ? 'tire' : 'tires'}`, this.#state.tires * 2],
			[`${this.#state.kvikkLunsj} Kvikk Lunsj`, Math.floor(this.#state.kvikkLunsj / 2)],
			[`${formatNumber(this.#food())} kg of food`, Math.floor(this.#food() / 4)],
			[kroner(this.#state.money + this.#state.petrolMoney), Math.floor((this.#state.money + this.#state.petrolMoney) / 50)],
			[`${this.#state.asked} times “Er vi fremme snart?”`, 0],
		);
		return rows;
	}

	#showScore() {
		const rows = this.#scoreRows();
		let subtotal = 0;
		for (const [, points] of rows) {
			subtotal += points;
		}

		const total = subtotal * this.#occupation().multiplier;
		const rank = rankOf(total);
		this.#setScene('nordkapp');
		this.#showScreen('score', () => {
			this.#addHeading('Points for arriving at Nordkapp');
			const table = element('table');
			for (const [label, points] of rows) {
				const row = element('tr');
				row.append(element('td', label), element('td', formatNumber(points)));
				table.append(row);
			}

			this.parts.screen.append(table);
			this.#addLine({bold: 'Total: '}, `${formatNumber(subtotal)} × ${this.#occupation().multiplier} for a ${this.#occupation().short} = `, {inverse: `${formatNumber(total)} points`});
			this.#addLine({bold: 'Your rank: '}, {inverse: rank});
			if (this.#state.boredomDeaths > 0) {
				this.#addLine(`Died of boredom along the way: ${this.#state.boredomDeaths} ${this.#state.boredomDeaths === 1 ? 'time' : 'times'}. They got better.`);
			}

			const list = this.#topTen();
			const qualifies = list.length < 10 || total > list.at(-1).points;
			if (qualifies) {
				this.#addLine('You made the Bergen Top Ten!');
				const form = element('form');
				const label = element('label', 'Your name for the Top Ten: ');
				const input = element('input');
				input.type = 'text';
				input.maxLength = 20;
				input.autocomplete = 'off';
				input.value = this.#names()[0];
				label.append(input);
				form.append(label);
				this.parts.screen.append(form);
				const addToTopTen = () => {
					const entry = {name: input.value.trim() || this.#names()[0], points: total};
					const updated = [...list, entry].sort((first, second) => second.points - first.points).slice(0, 10);
					this.store('top-ten', updated);
					this.#showTopTen();
				};

				form.addEventListener('submit', event => {
					event.preventDefault();
					addToTopTen();
				});
				this.#addMenu([
					{label: 'Write my name in the Top Ten', action: addToTopTen},
					{label: 'Travel the trail again', action: () => this.#showOccupation()},
				]);
			} else {
				this.#addMenu([
					{label: 'See the Bergen Top Ten', action: () => this.#showTopTen()},
					{label: 'Travel the trail again', action: () => this.#showOccupation()},
				]);
			}
		});
		this.say(`${formatNumber(total)} points: ${rank}.`);
	}

	#showTopTen() {
		this.#setScene('title');
		this.#showScreen('topTen', () => {
			this.#addHeading('The Bergen Top Ten');
			const table = element('table');
			const header = element('tr');
			header.append(element('th', 'Name'), element('th', 'Points'), element('th', 'Rating'));
			table.append(header);
			for (const entry of this.#topTen()) {
				const row = element('tr');
				row.append(element('td', entry.name), element('td', formatNumber(entry.points)), element('td', rankOf(entry.points)));
				table.append(row);
			}

			this.parts.screen.append(table);
			this.#addLine('Trail Guide: 7000 points or more. Adventurer: 3000 or more. Greenhorn: less.');
			this.#addMenu([
				{label: 'Go back to the start', action: () => this.#showTitle()},
				{
					label: 'Erase the Top Ten',
					action: () => {
						this.store('top-ten', undefined);
						this.#showTopTen();
					},
				},
			]);
		});
	}

	// MARK: The menus of the trail

	#showTravel() {
		this.#setScene('travel');
		this.#showScreen('travel', () => {
			const stop = this.#nextStop();
			this.#travelFields = {
				date: this.#addField('Date', formatDate(this.#today())),
				weather: this.#addField('Weather', ''),
				health: this.#addField('Health', ''),
				food: this.#addField('Food', ''),
				next: this.#addField('Next landmark', ''),
				driven: this.#addField('Driven', ''),
				asked: this.#addField('“Er vi fremme snart?”', ''),
				holiday: this.#addField('Holiday left', ''),
			};
			if (this.reducedMotion) {
				this.#addMenu([
					{label: 'Drive on (one day)', action: () => this.#driveDay()},
					{label: 'Size up the situation', action: () => this.#showSizeUp()},
				]);
				this.#primaryAction = () => this.#driveDay();
			} else {
				this.#addMenu([{label: 'Size up the situation', action: () => this.#showSizeUp()}], 'Press ENTER to size up the situation');
				this.#primaryAction = () => this.#showSizeUp();
				this.#isDriving = true;
				this.#dayClock = 0;
			}

			this.#updateTravel();
			if (stop) {
				this.say(`On the road to ${stop.name}.`);
			}
		});
	}

	#updateTravel() {
		if (this.#currentScreen !== 'travel' || !this.#travelFields) {
			return;
		}

		const stop = this.#nextStop();
		this.#travelFields.date.textContent = formatDate(this.#today());
		this.#travelFields.weather.textContent = `${this.#state.weather}${this.#isMidnightSun() ? ' (midnight sun)' : ''}`;
		this.#travelFields.health.textContent = healthWord(this.#averageHealth());
		this.#travelFields.food.textContent = `${formatNumber(this.#food())} kg`;
		this.#travelFields.next.textContent = `${stop.name.replace(/^the /, 'The ')}, ${formatNumber(stop.km - this.#state.km)} km`;
		this.#travelFields.driven.textContent = `${formatNumber(this.#state.km)} of ${formatNumber(totalKilometers)} km`;
		this.#travelFields.asked.textContent = `${formatNumber(this.#state.asked)} times`;
		this.#travelFields.holiday.textContent = `${holidayDays - this.#state.day} days`;
		this.#draw();
	}

	#showSizeUp() {
		const here = this.#state.at === undefined ? undefined : route[this.#state.at];
		if (here?.kind === 'ferry') {
			this.#showFerry(true);
			return;
		}

		this.#setScene(here?.picture ?? 'travel');
		this.#showScreen('sizeUp', () => {
			this.#addHeading(here ? here.name.replace(/^the /, 'The ') : 'On the road');
			this.#addLine(formatDate(this.#today()));
			this.#addField('Weather', this.#state.weather);
			this.#addField('Health', healthWord(this.#averageHealth()));
			this.#addField('Pace', paces[this.#state.pace].name);
			this.#addField('Rations', rations[this.#state.rations].name);
			const items = [
				{label: 'Continue on the trail', action: () => this.#continueOnTrail()},
				{label: 'Check the supplies', action: () => this.#showSupplies()},
				{label: 'Look at the map', action: () => this.#showMap()},
				{label: 'Change the pace', action: () => this.#showPace()},
				{label: 'Change the food rations', action: () => this.#showRations()},
				{label: 'Stop to rest', action: () => this.#showRest()},
				{label: 'Go fishing', action: () => this.#startFishing()},
			];
			if (here?.talk) {
				items.push({label: 'Talk to people', action: () => this.#talk(here)});
			}

			if (here?.shop) {
				items.push({label: 'Buy supplies', action: () => this.#showStore({factor: here.shop, place: here.name, then: () => this.#showSizeUp()})});
			}

			this.#addMenu(items);
		});
	}

	#continueOnTrail() {
		this.#state.at = undefined;
		this.#saveTrip();
		this.#showTravel();
	}

	#showSupplies() {
		this.#setScene('travel');
		this.#showScreen('supplies', () => {
			this.#addHeading('Your supplies');
			const table = element('table');
			const rows = [
				['Money', kroner(this.#state.money)],
				['Petrol money', kroner(this.#state.petrolMoney)],
				['Brown cheese', `${formatNumber(this.#state.cheese)} kg`],
				['Matpakke bread', `${formatNumber(this.#state.bread)} loaves`],
				['Fresh fish', `${formatNumber(this.#state.fish)} kg`],
				['Other food', `${formatNumber(this.#state.extraFood)} kg`],
				['Kvikk Lunsj', `${this.#state.kvikkLunsj} bars`],
				['Spare tires', String(this.#state.tires)],
				['Road map', this.#state.map ? 'yes' : 'no (Pappa says he does not need one)'],
				['Mosquito spray', `${this.#state.spray} bottles`],
			];
			for (const [label, value] of rows) {
				const row = element('tr');
				row.append(element('td', label), element('td', value));
				table.append(row);
			}

			this.parts.screen.append(table);
			this.#addHeading('The family');
			for (const [index, name] of this.#names().entries()) {
				const condition = this.#state.conditions[index];
				const sickness = condition === 'boredom' ? ', is bored' : `, has ${condition}`;
				this.#addLine({bold: `${name}: `}, `${healthWord(this.#state.health[index])} health${condition ? sickness : ''}`);
			}

			this.#addContinue(() => this.#showSizeUp());
		});
	}

	#showMap() {
		this.#setScene('map');
		this.#showScreen('map', () => {
			const stop = this.#nextStop();
			this.#addHeading('The map');
			this.#addLine(`You have driven ${formatNumber(this.#state.km)} km of ${formatNumber(totalKilometers)} km. It is ${formatNumber(stop.km - this.#state.km)} km to ${stop.name}, and ${formatNumber(totalKilometers - this.#state.km)} km to Nordkapp.`);
			this.#addLine('On the map, the orange dot is the Volvo, the blue dots are ferries, and the white dots are landmarks.');
			if (!this.#state.map) {
				this.#addLine(`You have no road map, so this is the map that ${this.#names()[2]} drew on the back of a Rimi receipt.`);
			}

			this.#addContinue(() => this.#showSizeUp());
		});
	}

	#showPace() {
		this.#showScreen('pace', () => {
			this.#addHeading('Change the pace');
			this.#addLine({bold: 'The pace now: '}, paces[this.#state.pace].name);
			this.#addMenu(Object.entries(paces).map(([id, pace]) => ({
				label: `${pace.name.replace(/^a /, 'A ').replace(/^steady/, 'Steady')}: ${pace.description}`,
				action: () => {
					this.#state.pace = id;
					this.#saveTrip();
					this.#showSizeUp();
				},
			})));
		});
	}

	#showRations() {
		this.#showScreen('rations', () => {
			this.#addHeading('Change the food rations');
			this.#addLine({bold: 'The rations now: '}, rations[this.#state.rations].name);
			this.#addMenu(Object.entries(rations).map(([id, ration]) => ({
				label: `${ration.name[0].toUpperCase()}${ration.name.slice(1)}: ${ration.description} (${ration.kilograms} kg each a day)`,
				action: () => {
					this.#state.rations = id;
					this.#saveTrip();
					this.#showSizeUp();
				},
			})));
		});
	}

	#showRest() {
		this.#showScreen('rest', () => {
			this.#addHeading('Stop to rest');
			this.#addLine('How many days do you want to rest?');
			const rest = days => {
				const news = [];
				for (let day = 0; day < days; day++) {
					news.push(...this.#passDay({isResting: true}));
				}

				this.#saveTrip();
				if (!this.#continueAfter([], () => this.#showSizeUp())) {
					this.#showMessage({lines: [`You rest for ${days} ${days === 1 ? 'day' : 'days'}. Everybody feels better, and ${this.#names()[0]} washes the Volvo.`, ...news], then: () => this.#showSizeUp()});
				}
			};

			this.#addMenu([
				{label: 'One day', action: () => rest(1)},
				{label: 'Two days', action: () => rest(2)},
				{label: 'Three days', action: () => rest(3)},
				{label: 'Never mind', action: () => this.#showSizeUp()},
			]);
		});
	}

	#talk(place) {
		const line = place.talk[this.#state.talkIndex % place.talk.length];
		this.#state.talkIndex += 1;
		this.#showMessage({lines: [this.#withNames(line)], then: () => this.#showSizeUp()});
	}

	// MARK: Fishing

	#catchTable() {
		return [
			{weight: 50, name: 'a cod', minimum: 4, maximum: 40},
			{weight: 20, name: 'a saithe', minimum: 2, maximum: 12},
			{weight: 12, name: 'a mackerel', minimum: 1, maximum: 2},
			{weight: 5, name: 'a halibut as big as a door', minimum: 60, maximum: 140},
			{weight: 5, name: 'a whole school of herring', minimum: 150, maximum: 300},
			{weight: 4, name: 'an old boot', minimum: 0, maximum: 0},
			{weight: 2, name: `${this.#names()[4]}’s hat`, minimum: 0, maximum: 0},
			{weight: 2, name: 'a cassette of Vazelina Bilopphøggers, still playable', minimum: 0, maximum: 0},
		];
	}

	#isFisherman() {
		return this.#state.occupation === 'fisherman';
	}

	#biteWindow() {
		return (this.#isFisherman() ? 1.1 : 0.75) + (this.reducedMotion ? 0.6 : 0);
	}

	#setFishingText(text) {
		this.#fishingText.textContent = text;
		this.say(text);
	}

	#startFishing() {
		this.#fishing = {time: 0, timeLeft: 20, phase: 'waiting', nextBite: nextBiteIn(), biteEnd: 0, total: 0, catches: 0, isOver: false};
		this.#setScene('fishing');
		this.#showScreen('fishing', () => {
			this.#addHeading('Fishing');
			this.#addLine(`${this.#names()[2]} stands on the quay with ${this.#names()[4]}’s old rod. Watch the float. When it goes under, pull!`);
			this.#fishingText = this.#addLine('The float bobs on the water.');
			this.#addMenu([
				{label: 'Pull the line!', action: () => this.#pullLine()},
				{label: 'Stop fishing', action: () => this.#endFishing()},
			], 'Press SPACE BAR to pull');
			this.#primaryAction = () => this.#pullLine();
		});
		this.#loop.start();
	}

	#pullLine() {
		if (this.#fishing.isOver) {
			return;
		}

		if (this.#fishing.phase !== 'bite') {
			this.#fishing.nextBite = this.#fishing.time + nextBiteIn();
			this.#setFishingText('Too early! The fish swims away from the splash.');
			return;
		}

		const caught = weightedItem(this.#catchTable());
		let kilograms = randomInteger(caught.minimum, caught.maximum);
		if (this.#isFisherman()) {
			kilograms = Math.round(kilograms * 1.3);
		}

		this.#fishing.total += kilograms;
		this.#fishing.catches += 1;
		this.#fishing.phase = 'waiting';
		this.#fishing.nextBite = this.#fishing.time + nextBiteIn();
		this.#fishing.flash = kilograms > 0 ? `${kilograms} KG!` : 'JUNK!';
		this.#fishing.flashKilograms = kilograms;
		this.#fishing.flashUntil = this.#fishing.time + 1.4;
		this.#audio.caught();
		this.#setFishingText(kilograms > 0 ? `You caught ${caught.name} of ${kilograms} kg!` : `You caught ${caught.name}.`);
		this.#draw();
		if (this.#fishing.catches >= 6) {
			this.#endFishing();
		}
	}

	#updateFishing(seconds) {
		this.#fishing.time += seconds;
		this.#fishing.timeLeft -= seconds;
		if (this.#fishing.phase === 'waiting' && this.#fishing.time >= this.#fishing.nextBite) {
			this.#fishing.phase = 'bite';
			this.#fishing.biteEnd = this.#fishing.time + this.#biteWindow();
			this.#audio.bite();
			this.#setFishingText('The float goes under! Pull!');
		} else if (this.#fishing.phase === 'bite' && this.#fishing.time > this.#fishing.biteEnd) {
			this.#fishing.phase = 'waiting';
			this.#fishing.nextBite = this.#fishing.time + nextBiteIn();
			this.#setFishingText('Too slow. The fish took the bait and left.');
		}

		if (this.#fishing.timeLeft <= 0) {
			this.#endFishing();
		}
	}

	#endFishing() {
		if (this.#fishing.isOver) {
			return;
		}

		this.#fishing.isOver = true;
		const {total} = this.#fishing;
		const carried = Math.min(total, 10);
		const news = this.#passDay();
		this.#state.fish += carried;
		this.#saveTrip();
		let line;
		if (total === 0) {
			line = 'You caught nothing but a cold.';
		} else if (total > carried) {
			line = `You caught ${formatNumber(total)} kg of fish. However, you were only able to carry ${carried} kg back to the Volvo, as the roof box is full of brown cheese.`;
		} else {
			line = `You caught ${formatNumber(total)} kg of fish and carry it all to the Volvo. ${this.#names()[1]} opens all the windows.`;
		}

		this.#showMessage({lines: [line, 'Fishing took the whole day.'], picture: {kind: 'fishing'}, then: () => {
			if (!this.#continueAfter(news, () => this.#showSizeUp())) {
				this.#showSizeUp();
			}
		}});
	}

	// MARK: The store

	#showStore({factor, place, isStart = false, then}) {
		this.#setScene('store');
		const cart = {};
		for (const item of storeItems) {
			cart[item.id] = 0;
		}

		const priceOf = item => item.isMoney ? 1 : Math.round(item.price * factor);
		const bill = () => {
			let total = 0;
			for (const item of storeItems) {
				total += cart[item.id] * priceOf(item);
			}

			return total;
		};

		// Kjell keeps 1000 kr out of the basket, about what the five ferry tickets cost, so a poor teacher does not have to drive around the first fjord.
		if (isStart) {
			for (const item of storeItems) {
				while (cart[item.id] < item.advice && bill() + (item.step * priceOf(item)) <= this.#state.money - 1000) {
					cart[item.id] += item.step;
				}
			}
		}

		const amountCells = {};
		const priceCells = {};
		let billField;
		let leftField;
		let clerk;

		const update = () => {
			for (const item of storeItems) {
				amountCells[item.id].textContent = String(cart[item.id]);
				priceCells[item.id].textContent = kroner(cart[item.id] * priceOf(item));
			}

			billField.textContent = kroner(bill());
			leftField.textContent = kroner(this.#state.money - bill());
		};

		const change = (item, direction) => {
			const amount = cart[item.id] + (direction * item.step);
			const owned = item.id === 'petrolMoney' ? 0 : this.#state[item.id];
			if (amount < 0) {
				return;
			}

			if (amount + owned > item.maximum) {
				clerk.textContent = item.id === 'map' ? 'Kjell says: “One map is enough. Pappa will not read it anyway.”' : `Kjell says: “That is all of the ${item.name.toLowerCase()} that fits in a Volvo.”`;
				return;
			}

			if (direction > 0 && bill() + (item.step * priceOf(item)) > this.#state.money) {
				clerk.textContent = 'Kjell says: “You cannot afford that. Put something back.”';
				this.say('You cannot afford that.');
				return;
			}

			cart[item.id] = amount;
			clerk.textContent = '';
			update();
			this.say(`${item.name}: ${cart[item.id]} ${item.unit}. The bill is ${kroner(bill())}.`);
		};

		this.#showScreen('store', () => {
			this.#addHeading(isStart ? 'Rimi in Bergen' : `The shop in ${place}`);
			this.#addLine(formatDate(this.#today()));
			if (!isStart) {
				this.#addLine(`The prices here are ${Math.round((factor - 1) * 100)}% higher than in Bergen. That is the north.`);
			}

			const table = element('table');
			const header = element('tr');
			header.append(element('th', 'Item'), element('th', 'Buy'), element('th', 'Cost'));
			table.append(header);
			for (const item of storeItems) {
				const row = element('tr');
				const nameCell = element('td');
				const owned = this.#state[item.id];
				const detail = item.isMoney ? `(have ${kroner(owned)})` : `${kroner(priceOf(item))}, have ${owned}`;
				nameCell.append(item.name, element('br'), detail);
				const buyCell = element('td');
				const stepper = element('div');
				const less = element('button', '−');
				less.type = 'button';
				less.setAttribute('aria-label', `Less ${item.name.toLowerCase()}`);
				less.addEventListener('click', () => {
					this.#audio.click();
					change(item, -1);
				});
				const more = element('button', '+');
				more.type = 'button';
				more.setAttribute('aria-label', `More ${item.name.toLowerCase()}`);
				more.addEventListener('click', () => {
					this.#audio.click();
					change(item, 1);
				});
				amountCells[item.id] = element('span', '0');
				stepper.append(less, amountCells[item.id], more);
				buyCell.append(stepper);
				priceCells[item.id] = element('td', '0 kr');
				row.append(nameCell, buyCell, priceCells[item.id]);
				table.append(row);
			}

			this.parts.screen.append(table);
			billField = this.#addField('Total bill', '');
			leftField = this.#addField('Money left after', '');
			clerk = this.#addLine(isStart ? 'Kjell says: “Hei! I put in the basket what I would take for five people to Nordkapp, and left 1000 kr for the ferries. Change it with − and +, or just pay.”' : `The man at the counter says: “Going to Nordkapp? Everybody is going to Nordkapp.”`);
			update();
			this.#addMenu([
				{
					label: 'Pay and leave the store',
					action: () => {
						this.#state.money -= bill();
						for (const item of storeItems) {
							this.#state[item.id] += cart[item.id];
						}

						this.#saveTrip();
						then();
					},
				},
			]);
		});
	}

	// MARK: Setting up the trip

	#showTitle() {
		this.#setScene('title');
		const saved = this.#savedTrip();
		this.#showScreen('title', () => {
			this.#addLine({inverse: 'THE BERGEN TRAIL'}, ' by Sindre, 1999');
			this.#addLine('You may:');
			const items = [];
			if (saved) {
				items.push({
					label: `Continue the trip (km ${formatNumber(saved.km)}, ${formatDate(new Date(1999, saved.month, 1 + saved.day))})`,
					action: () => {
						this.#state = {...newTrip(), ...saved};
						this.#showSizeUp();
					},
				});
			}

			items.push(
				{label: saved ? 'Start a new trip' : 'Travel the trail', action: () => this.#showOccupation()},
				{label: 'Learn about the trail', action: () => this.#showLearn(0)},
				{label: 'See the Bergen Top Ten', action: () => this.#showTopTen()},
			);
			this.#addMenu(items);
		});
	}

	#showLearn(page) {
		this.#setScene(page % 2 === 0 ? 'title' : 'map');
		this.#showScreen('learn', () => {
			this.#addHeading('Learn about the trail');
			this.#addLine(learnPages[page]);
			this.#addLine(`Page ${page + 1} of ${learnPages.length}`);
			this.#addContinue(page + 1 < learnPages.length ? () => this.#showLearn(page + 1) : () => this.#showTitle());
		});
	}

	#showOccupation() {
		this.#state = newTrip();
		this.#setScene('bergen');
		this.#showScreen('occupation', () => {
			this.#addLine('Many kinds of people drive to Nordkapp. You may:');
			const items = Object.entries(occupations).map(([id, job]) => ({
				label: `Let Pappa be ${job.title} (${kroner(job.money)})`,
				action: () => {
					this.#state.occupation = id;
					this.#state.money = job.money;
					this.#showNames();
				},
			}));
			items.push({label: 'Find out the differences between these choices', action: () => this.#showOccupationHelp()});
			this.#addMenu(items);
		});
	}

	#showOccupationHelp() {
		this.#showScreen('occupationHelp', () => {
			this.#addHeading('The jobs of Pappa');
			for (const job of Object.values(occupations)) {
				this.#addLine({bold: `${job.title[0].toUpperCase()}${job.title.slice(1)}: `}, job.perk);
			}

			this.#addContinue(() => this.#showOccupation());
		});
	}

	#showNames() {
		this.#setScene('title');
		this.#showScreen('names', () => {
			this.#addLine('What are the names of the five in the Volvo?');
			const form = element('form');
			const inputs = [];
			for (const [index, role] of nameRoles.entries()) {
				const label = element('label', `${role}: `);
				const input = element('input');
				input.type = 'text';
				input.maxLength = 12;
				input.autocomplete = 'off';
				input.value = this.#state.names[index];
				label.append(input);
				form.append(label);
				inputs.push(input);
			}

			this.parts.screen.append(form);
			const confirm = () => {
				this.#state.names = inputs.map((input, index) => input.value.trim().slice(0, 12) || defaultNames[index]);
				this.#showMonth();
			};

			// A form with five fields and no submit button does not submit on Enter, so Enter in a field confirms the names here.
			form.addEventListener('keydown', event => {
				if (event.key === 'Enter' && !event.isComposing) {
					event.preventDefault();
					this.#audio.click();
					confirm();
				}
			});
			this.#addMenu([{label: 'These names are correct', action: confirm}]);
			if (this.#focusAfterRender) {
				inputs[0].focus({preventScroll: true});
			}
		});
	}

	#showMonth() {
		this.#showScreen('month', () => {
			this.#addLine('It is 1999. When do you want to leave Bergen?');
			const items = months.map(month => ({
				label: month.name,
				action: () => {
					this.#state.month = month.month;
					this.#state.weather = month.month === 8 ? 'heavy rain' : 'rain';
					this.#showStoreIntro();
				},
			}));
			items.push({label: 'Ask for advice', action: () => this.#showMonthAdvice()});
			this.#addMenu(items);
		});
	}

	#showMonthAdvice() {
		this.#showScreen('monthAdvice', () => {
			this.#addHeading('Advice from Mormor');
			for (const month of months) {
				this.#addLine(month.advice);
			}

			this.#addContinue(() => this.#showMonth());
		});
	}

	#showStoreIntro() {
		this.#setScene('store');
		this.#showScreen('storeIntro', () => {
			this.#addLine(`Before leaving Bergen, you should buy supplies at Rimi. You have ${kroner(this.#state.money)} in cash.`);
			this.#addLine('You will need brown cheese and matpakke bread for the packed lunches, Kvikk Lunsj (with the mountain rules on the wrapper), petrol money (the Volvo drinks like a horse), spare tires (the roads up north are bad), a road map (Pappa says he does not need one), and mosquito spray (Finnmark).');
			this.#addLine('You can buy more on the way, in Voss, Trondheim, Tromsø, and Alta, but it gets dearer.');
			this.#addContinue(() => this.#showStore({factor: 1, place: 'Bergen', isStart: true, then: () => this.#showDeparture()}));
		});
	}

	#showDeparture() {
		this.#state.isStarted = true;
		this.#saveTrip();
		this.#setScene('bergen');
		this.#showScreen('departure', () => {
			this.#addHeading('Bergen');
			this.#addLine(formatDate(this.#today()));
			this.#addLine(this.#withNames(route[0].text));
			if (this.#food() === 0) {
				this.#addLine({bold: 'You have no food at all. Kjell runs after the Volvo, waving a loaf.'});
			}

			this.#addContinue(() => this.#showTravel());
		});
		this.say('The trip begins in Bergen.');
	}
}
