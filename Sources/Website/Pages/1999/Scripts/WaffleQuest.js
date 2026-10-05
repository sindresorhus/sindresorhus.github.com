// WAFFLE QUEST: The Great Underground Kitchen on the 1999 page, a text adventure like Zork (1980) by Infocom. A parser reads what the visitor types: a verb, a thing, and maybe a second thing after a word like IN or WITH. The world is a list of rooms and things, and everything that changes is in one state, so SAVE, RESTORE, and UNDO only copy it, and SAVE keeps it in the browser. It beeps when the sound button of Sindre’s Quest is on, which tells it with the `geocities-adventure-sound` event.
const randomItem = items => items[Math.floor(Math.random() * items.length)];

// A short sound effect, made in the browser.
const beep = (audio, frequency, duration = 0.1, {type = 'square', volume = 0.05, when = 0} = {}) => {
	if (audio?.context.state !== 'running') {
		return;
	}

	const start = audio.context.currentTime + when;
	const oscillator = new OscillatorNode(audio.context, {type, frequency});
	const gain = new GainNode(audio.context, {gain: 0});
	gain.gain.setValueAtTime(0, start);
	gain.gain.linearRampToValueAtTime(volume, start + 0.005);
	gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
	oscillator.connect(gain).connect(audio.output);
	oscillator.start(start);
	oscillator.stop(start + duration + 0.02);
};

export default class extends GeoCitiesElement {
	#isSoundOn = false;

	connected() {
		// The sound button of Sindre’s Quest turns the sound on and off for all the adventure games of the page.
		this.on(document, 'geocities-adventure-sound', event => {
			this.#isSoundOn = event.detail.isOn;
		});

		const {screen, form, input, typed, after, room: roomLabel, score: scoreLabel} = this.parts;

		const rooms = {
			westOfHouse: {
				name: 'West of Mormor’s House',
				description: 'You are standing in the rain west of a red wooden house in Bergen, with a boarded front door.',
				exits: {
					n: 'northOfHouse',
					s: 'southOfHouse',
					e: 'The door is boarded. Mormor nailed it shut in 1974, to keep the seagulls out.',
					w: 'That way is the road to the city. You have a quest. Mormor would be disappointed.',
				},
			},
			northOfHouse: {
				name: 'North of House',
				description: 'You are facing the north side of the red house. There is no door here, and all the windows are boarded up. A narrow path winds north toward Fløyen.',
				exits: {
					w: 'westOfHouse',
					e: 'behindHouse',
					n: 'The path to Fløyen is closed due to weather. It is always closed due to weather.',
				},
			},
			southOfHouse: {
				name: 'South of House',
				description: 'You are facing the south side of the red house. There is no door here, and all the windows are boarded up. A seagull watches you from the roof.',
				exits: {
					w: 'westOfHouse',
					e: 'behindHouse',
					s: 'You would get lost in the rain. Everybody does.',
				},
			},
			behindHouse: {
				name: 'Behind House',
				description: state => `You are behind the red house. A path leads into the rain to the north and the south. In one corner of the house there is a small window which is ${state.flags.windowOpen ? 'open' : 'slightly ajar'}.`,
				exits: {
					n: 'northOfHouse',
					s: 'southOfHouse',
					w: state => state.flags.windowOpen ? 'kitchen' : 'The window is closed.',
					in: state => state.flags.windowOpen ? 'kitchen' : 'The window is closed.',
				},
			},
			kitchen: {
				name: 'Kitchen',
				description: 'You are in the kitchen of Mormor’s house. A table seems to have been used recently for the preparation of waffles. A passage leads to the west, and a dark staircase leads upward. To the east is a small window which is open.',
				exits: {
					e: 'behindHouse',
					out: 'behindHouse',
					w: 'livingRoom',
					u: 'attic',
				},
			},
			attic: {
				name: 'Attic',
				isDark: true,
				description: 'This is the attic, full of Christmas decorations and boxes marked “1970s”. The only exit is a stairway leading down.',
				exits: {
					d: 'kitchen',
				},
			},
			livingRoom: {
				name: 'Living Room',
				description(state) {
					let text = 'You are in the living room. There is a doorway to the east, a fireplace with a brass plaque on it, and a glass trophy case for waffle trophies.';
					if (state.flags.rugMoved) {
						text += ` The rug is moved to one side, and there is ${state.flags.trapOpen ? 'an open trap door' : 'a closed trap door'} in the floor.`;
					} else {
						text += ' A large oriental rug lies in the middle of the room.';
					}

					return text;
				},
				exits: {
					e: 'kitchen',
					d: state => state.flags.trapOpen ? 'cellar' : (state.flags.rugMoved ? 'The trap door is closed.' : 'You can’t go that way.'),
					u: 'The chimney is too narrow for a kid. Santa manages, but he is magic.',
				},
			},
			cellar: {
				name: 'Cellar',
				isDark: true,
				description: 'You are in a dark and damp cellar, full of jars of Mormor’s jam. A narrow passageway leads north. Above you is the trap door.',
				exits: {
					n: 'trollRoom',
					u: 'livingRoom',
					s: 'The crawlway to the south is full of empty jam jars.',
				},
			},
			trollRoom: {
				name: 'The Troll Room',
				isDark: true,
				description: 'This is a small room with passages to the east, the west, the north, and the south. Brown cheese stains and deep scratches, perhaps made by a cheese slicer, mar the walls.',
				exits: {
					s: 'cellar',
					e: state => state.flags.trollFed ? 'maze1' : 'The troll fends you off with a menacing gesture.',
					w: state => state.flags.trollFed ? 'mill' : 'The troll fends you off with a menacing gesture.',
					n: state => state.flags.trollFed ? 'coldCave' : 'The troll fends you off with a menacing gesture.',
				},
			},
			maze1: {name: 'Maze', isDark: true, isMaze: true, exits: {w: 'trollRoom', n: 'maze2', e: 'maze3', s: 'maze1', u: 'maze4'}},
			maze2: {name: 'Maze', isDark: true, isMaze: true, exits: {s: 'maze1', e: 'maze4', w: 'maze3', n: 'maze5'}},
			maze3: {name: 'Maze', isDark: true, isMaze: true, exits: {e: 'maze1', n: 'maze2', d: 'maze5', w: 'maze3'}},
			maze4: {name: 'Maze', isDark: true, isMaze: true, exits: {d: 'maze1', w: 'maze2', n: 'maze4', e: 'maze5'}},
			maze5: {name: 'Maze', isDark: true, isMaze: true, exits: {s: 'deadEnd', n: 'maze3', w: 'maze4', e: 'maze2', u: 'maze1'}},
			deadEnd: {
				name: 'Dead End',
				isDark: true,
				description: 'This is a dead end. Somebody has written on the wall: “KEVIN WAS HERE 1997”.',
				exits: {
					n: 'maze5',
				},
			},
			mill: {
				name: 'Old Mill',
				isDark: true,
				description: 'You are in an old underground mill. A great millstone sits over a pile of grain, with a wooden lever next to it. A chute hangs over a bin. The only exit is east.',
				exits: {
					e: 'trollRoom',
				},
			},
			coldCave: {
				name: 'Cold Cave',
				isDark: true,
				description: state => `You are in a freezing cave. Icicles hang from the ceiling like teeth. ${state.flags.iceChipped ? 'A block of ice in the corner is chipped open.' : 'A bottle of milk is frozen solid in a block of ice in the corner.'} Passages lead north and south. A warm, golden glow comes from the north.`,
				exits: {
					s: 'trollRoom',
					n: 'temple',
				},
			},
			temple: {
				name: 'Temple of the Golden Waffle',
				description: 'You are in a domed temple, lit by a golden glow. On an altar of polished brown cheese stands an enormous golden waffle iron. Words are carved above it. A narrow, sooty chimney leads up, and a passage leads south.',
				exits: {
					s: 'coldCave',
					u: 'livingRoom',
				},
			},
		};

		// The things of the world: their names, the words that the parser knows them by, where they are at the start, and what is special about them. Fixed things cannot be taken.
		const things = {
			mailbox: {name: 'small mailbox', words: ['small', 'mailbox', 'box'], location: 'westOfHouse', isFixed: true, isContainer: true, initial: 'There is a small mailbox here.', description: 'A small red mailbox. It says MORMOR on it, in her best handwriting.'},
			leaflet: {name: 'leaflet', words: ['leaflet', 'paper', 'flyer', 'advertisement', 'mail'], location: 'mailbox', text: '“WELCOME TO WAFFLE QUEST!\n\nWAFFLE QUEST is a game of adventure, danger, and low cunning. In it you will explore some of the most amazing kitchens ever seen by mortals. No computer should be without one!\n\nFind the three things of the Golden Waffle, bake it in the Temple, and put it in Mormor’s trophy case.”'},
			window: {name: 'window', words: ['small', 'window'], location: 'behindHouse', isFixed: true, isScenery: true, description: state => state.flags.windowOpen ? 'The window is open, wide enough for a kid.' : 'The window is slightly ajar, but not enough to allow entry.'},
			table: {name: 'kitchen table', words: ['kitchen', 'table'], location: 'kitchen', isFixed: true, isScenery: true, description: 'A wooden table with waffle crumbs on it. Mormor was here.'},
			bag: {name: 'brown paper bag', words: ['brown', 'paper', 'bag', 'sack'], location: 'kitchen', isContainer: true, initial: 'On the table is a brown paper bag. It smells of brown cheese.', description: 'A brown paper bag, like the ones for a matpakke.'},
			sandwich: {name: 'brown cheese sandwich', words: ['brown', 'cheese', 'sandwich', 'matpakke', 'lunch', 'food', 'brunost'], location: 'bag', isFood: true, description: 'A matpakke: two slices of bread with thick brown cheese, wrapped in paper. Lunch for a kid, or a snack for a troll.'},
			slicer: {name: 'cheese slicer', words: ['cheese', 'slicer', 'ostehovel'], location: 'attic', initial: 'A large cheese slicer lies on a box, sharp and shiny.', description: 'A cheese slicer, invented in Norway in 1925. This one is big and sharp, like a tiny shovel for cutting ice.'},
			plaque: {name: 'brass plaque', words: ['brass', 'plaque', 'fireplace'], location: 'livingRoom', isFixed: true, isScenery: true, text: 'MORMOR’S RULE: WHEN THE WAFFLE IRON CLOSES, SAY “KOS”.', description: 'A brass plaque on the fireplace, with words on it.'},
			lamp: {name: 'brass lantern', words: ['brass', 'lantern', 'lamp', 'light', 'flashlight'], location: 'livingRoom', initial: 'A battery-powered brass lantern is on the trophy case.', description: state => `A battery-powered brass lantern. It is ${state.things.lamp.isOn ? 'on' : 'off'}.`},
			spatula: {name: 'elvish spatula', words: ['elvish', 'spatula', 'sword'], location: 'livingRoom', initial: 'Above the fireplace hangs an elvish spatula of great antiquity.', description: 'An elvish spatula of great antiquity. It glows blue when danger is near, or when it is near a waffle.'},
			case: {name: 'trophy case', words: ['trophy', 'glass', 'case'], location: 'livingRoom', isFixed: true, isContainer: true, isTransparent: true, isScenery: true, description: 'A glass trophy case. There is a space in the middle with a small sign: “RESERVED FOR THE GOLDEN WAFFLE”.'},
			rug: {name: 'oriental rug', words: ['oriental', 'rug', 'carpet'], location: 'livingRoom', isFixed: true, isScenery: true, description: state => state.flags.rugMoved ? 'The rug is moved to one side.' : 'A large oriental rug. There is a suspicious bump in the middle.'},
			trapDoor: {name: 'trap door', words: ['trap', 'door', 'trapdoor', 'hatch'], location: 'nowhere', isFixed: true, isScenery: true, description: state => `A trap door in the floor. It is ${state.flags.trapOpen ? 'open, and stairs lead down into the darkness' : 'closed'}.`},
			jam: {name: 'jars of jam', words: ['jars', 'jar', 'jam'], location: 'cellar', isFixed: true, isScenery: true, description: 'Hundreds of jars of Mormor’s cloudberry jam, from 1962 to 1998.'},
			troll: {name: 'troll', words: ['troll', 'nasty', 'monster'], location: 'trollRoom', isFixed: true, isScenery: true, isPerson: true, description: state => state.flags.trollFed ? 'The troll is asleep, with brown cheese on his chin. He snores like a boat engine.' : 'A nasty-looking troll, brandishing a bloody cheese slicer. Well, it is brown cheese, not blood. He has one tooth and looks very, very hungry.'},
			egg: {name: 'golden egg', words: ['golden', 'egg'], location: 'deadEnd', initial: 'In a nest of old AOL CDs lies a golden egg.', description: 'A hen’s egg, painted gold, the way Mormor likes them. It is one of the three things of the Golden Waffle.'},
			lever: {name: 'wooden lever', words: ['wooden', 'lever', 'handle'], location: 'mill', isFixed: true, isScenery: true, description: 'A wooden lever, next to the millstone.'},
			millstone: {name: 'millstone', words: ['mill', 'millstone', 'stone', 'grain'], location: 'mill', isFixed: true, isScenery: true, description: 'A great round millstone over a pile of grain.'},
			flour: {name: 'sack of flour', words: ['sack', 'flour', 'bag'], location: 'nowhere', initial: 'A sack of flour is in the bin under the chute.', description: 'A sack of fresh flour. It is one of the three things of the Golden Waffle.'},
			ice: {name: 'block of ice', words: ['block', 'ice', 'icicle', 'icicles'], location: 'coldCave', isFixed: true, isScenery: true, description: state => state.flags.iceChipped ? 'The block of ice is chipped open.' : 'A block of ice, with a bottle of milk frozen inside it. You need something sharp to chip it out.'},
			milk: {name: 'bottle of milk', words: ['bottle', 'milk'], location: 'coldCave', initial: '', description: 'A cold bottle of milk. It is one of the three things of the Golden Waffle.'},
			iron: {name: 'golden waffle iron', words: ['golden', 'iron', 'altar'], location: 'temple', isFixed: true, isContainer: true, isScenery: true, description: state => `An enormous golden waffle iron, on an altar of brown cheese. It is ${state.things.iron.isOpen ? 'open' : 'closed'}.`},
			words: {name: 'carved words', words: ['carved', 'words', 'inscription', 'writing'], location: 'temple', isFixed: true, isScenery: true, text: 'FLOUR, EGG, AND MILK. CLOSE THE IRON, AND SAY THE WORD THAT MORMOR SAYS.', description: 'Words, carved above the waffle iron. Read them.'},
			waffle: {name: 'Golden Waffle', words: ['golden', 'waffle'], location: 'nowhere', description: 'The Golden Waffle! It shines like the sun that Bergen never sees, and it smells of 300 years of Sundays.'},
			seagull: {name: 'seagull', words: ['seagull', 'gull', 'bird'], location: 'southOfHouse', isFixed: true, isScenery: true, description: 'A Bergen seagull. It looks at you like you are a waffle.'},
		};

		const directions = {
			downstairs: 'd', upstairs: 'u', through: 'in', n: 'n', north: 'n', s: 's', south: 's', e: 'e', east: 'e', w: 'w', west: 'w', u: 'u', up: 'u', d: 'd', down: 'd', ne: 'ne', northeast: 'ne', nw: 'nw', northwest: 'nw', se: 'se', southeast: 'se', sw: 'sw', southwest: 'sw', in: 'in', inside: 'in', enter: 'in', out: 'out', outside: 'out', exit: 'out', leave: 'out',
		};

		// The verbs, by the words the visitor may type for each, longest first, so PICK UP is found before PICK.
		const verbWords = [
			['pick up', 'take'], ['look under', 'examine'], ['use', 'use'], ['enter', 'go'], ['put down', 'drop'], ['turn on', 'light'], ['switch on', 'light'], ['turn off', 'extinguish'], ['switch off', 'extinguish'], ['look at', 'examine'], ['look in', 'examine'], ['talk to', 'talk'], ['climb up', 'climb'], ['climb down', 'climb'], ['go', 'go'], ['walk', 'go'], ['run', 'go'], ['take', 'take'], ['get', 'take'], ['grab', 'take'], ['carry', 'take'], ['drop', 'drop'], ['open', 'open'], ['close', 'close'], ['shut', 'close'], ['read', 'read'], ['examine', 'examine'], ['x', 'examine'], ['inspect', 'examine'], ['describe', 'examine'], ['check', 'examine'], ['search', 'examine'], ['look', 'look'], ['l', 'look'], ['inventory', 'inventory'], ['i', 'inventory'], ['inv', 'inventory'], ['light', 'light'], ['extinguish', 'extinguish'], ['put', 'put'], ['place', 'put'], ['insert', 'put'], ['give', 'give'], ['offer', 'give'], ['feed', 'give'], ['throw', 'give'], ['eat', 'eat'], ['drink', 'drink'], ['move', 'move'], ['push', 'move'], ['pull', 'move'], ['lift', 'move'], ['slide', 'move'], ['shove', 'move'], ['chip', 'break'], ['break', 'break'], ['cut', 'break'], ['smash', 'break'], ['hit', 'attack'], ['attack', 'attack'], ['kill', 'attack'], ['fight', 'attack'], ['stab', 'attack'], ['say', 'say'], ['yell', 'say'], ['shout', 'say'], ['climb', 'climb'], ['wait', 'wait'], ['z', 'wait'], ['score', 'score'], ['save', 'save'], ['restore', 'restore'], ['load', 'restore'], ['restart', 'restart'], ['undo', 'undo'], ['again', 'again'], ['g', 'again'], ['help', 'help'], ['hint', 'help'], ['hints', 'help'], ['about', 'help'], ['verbose', 'verbose'], ['brief', 'brief'], ['diagnose', 'diagnose'], ['xyzzy', 'xyzzy'], ['plugh', 'xyzzy'], ['hello', 'hello'], ['hi', 'hello'], ['hei', 'hello'], ['jump', 'jump'], ['sing', 'sing'], ['dance', 'dance'], ['pray', 'pray'], ['sleep', 'sleep'], ['listen', 'listen'], ['smell', 'smell'], ['sniff', 'smell'], ['quit', 'quit'], ['q', 'quit'], ['damn', 'swear'], ['fuck', 'swear'], ['shit', 'swear'], ['crap', 'swear'], ['darn', 'swear'], ['heck', 'swear'], ['curse', 'swear'], ['swear', 'swear'], ['kos', 'kos'], ['version', 'version'], ['wake', 'wake'], ['kiss', 'kiss'], ['knock', 'knock'],
		];

		const prepositions = new Set(['in', 'into', 'inside', 'on', 'onto', 'to', 'with', 'at', 'from', 'using']);
		const fillerWords = new Set(['the', 'a', 'an', 'some', 'please', 'my']);

		const ranks = [[100, 'Golden Waffle Wizard'], [80, 'Master Waffle Maker'], [60, 'Waffle Maker'], [40, 'Junior Waffle Maker'], [20, 'Batter Stirrer'], [0, 'Waffle Beginner']];

		const newState = () => ({
			room: 'westOfHouse',
			moves: 0,
			points: {},
			flags: {},
			darkTurns: 0,
			visited: {},
			things: Object.fromEntries(Object.entries(things).map(([id, thing]) => [id, {location: thing.location, isOpen: false, isOn: false, isMoved: false}])),
		});

		let state = newState();
		let undoState;
		let lastCommand = '';
		let lastThing;
		let history = [];
		let historyIndex = 0;
		let isVerbose = false;

		const score = () => {
			let total = 0;
			for (const points of Object.values(state.points)) {
				total += points;
			}

			return total;
		};

		const rank = () => ranks.find(([minimum]) => score() >= minimum)[1];

		const award = (key, points) => {
			if (state.points[key] === undefined) {
				state.points[key] = points;
				this.#beep(1046, 0.06);
				this.#beep(1568, 0.1, {when: 0.06});
			}
		};

		// Prints text to the screen of the game, and keeps the screen to the last few hundred lines, like the scrollback of DOS.
		const print = (text = '', isTitle = false) => {
			if (isTitle) {
				const title = document.createElement('strong');
				title.textContent = text;
				screen.append(title, '\n');
			} else {
				screen.append(`${text}\n`);
			}

			while (screen.childNodes.length > 600) {
				screen.firstChild.remove();
			}

			screen.scrollTop = screen.scrollHeight;
		};

		const updateStatus = () => {
			roomLabel.textContent = isLit() ? rooms[state.room].name : 'Darkness';
			scoreLabel.textContent = `Score: ${score()}/100   Moves: ${state.moves}`;
		};

		const location = id => state.things[id].location;
		const isCarried = id => location(id) === 'player';
		// A thing is held when it is carried, or in an open container that is carried, like the sandwich in the bag.
		const isHeld = id => isCarried(id) || (things[location(id)]?.isContainer === true && state.things[location(id)].isOpen && isHeld(location(id)));
		const withArticle = name => `${/^[aeiou]/i.test(name) ? 'an' : 'a'} ${name}`;

		// A thing is in reach when it is in the room or carried, or in an open or see-through container that is.
		const isInReach = id => {
			const where = location(id);
			if (where === 'player' || where === state.room) {
				return true;
			}

			if (things[where]?.isContainer) {
				return (state.things[where].isOpen || things[where].isTransparent) && isInReach(where);
			}

			return false;
		};

		const isLit = () => {
			if (!rooms[state.room].isDark) {
				return true;
			}

			return state.things.lamp.isOn && isInReach('lamp');
		};

		const describe = value => typeof value === 'function' ? value(state) : value;

		const contentsOf = id => Object.keys(things).filter(other => location(other) === id);

		const listContents = (id, indent = '') => {
			const contents = contentsOf(id);
			if (contents.length > 0 && (state.things[id].isOpen || things[id].isTransparent)) {
				print(`${indent}The ${things[id].name} contains:`);
				for (const other of contents) {
					print(`${indent}  ${withArticle(things[other].name)}`);
				}
			}
		};

		const look = (isForced = true) => {
			const room = rooms[state.room];
			if (!isLit()) {
				print('It is pitch black. You are likely to be eaten by a grue.');
				if (isCarried('spatula')) {
					print('Your spatula is glowing with a faint blue glow.');
				}

				return;
			}

			print(room.name, true);
			if (isForced || isVerbose || !state.visited[state.room]) {
				print(room.isMaze ? 'This is part of a maze of twisty little passages, all alike.' : describe(room.description));
			}

			state.visited[state.room] = true;
			for (const id of contentsOf(state.room)) {
				const thing = things[id];
				if (thing.isScenery) {
					continue;
				}

				if (id === 'milk' && !state.flags.iceChipped) {
					continue;
				}

				const hasMoved = state.things[id].isMoved;
				print(!hasMoved && thing.initial ? thing.initial : `There is a ${thing.name} here.`);
				listContents(id);
			}

			if (state.room === 'trollRoom' && !state.flags.trollFed) {
				print('A nasty-looking troll, brandishing a bloody cheese slicer, blocks all passages out of the room.');
			} else if (state.room === 'trollRoom') {
				print('A troll is asleep here, snoring happily, with brown cheese on his chin.');
			}

			if (state.room === 'temple') {
				listContents('iron');
			}
		};

		const die = text => {
			print(text);
			print();
			print('    ****  You have died  ****');
			print();
			print('Would you like to RESTART, RESTORE a saved game, or UNDO your last move?');
			state.isDead = true;
			this.#beep(196, 0.3, {type: 'sawtooth'});
			this.#beep(147, 0.5, {type: 'sawtooth', when: 0.3});
		};

		const goTo = room => {
			if (room === 'livingRoom' && state.room === 'cellar') {
				state.flags.rugMoved = true;
				print('You push the trap door open and climb up into the living room.');
				print();
			}

			state.room = room;
			if (room === 'kitchen') {
				award('kitchen', 10);
			}

			if (room === 'cellar' && state.flags.trapOpen) {
				state.flags.trapOpen = false;
				award('cellar', 10);
				look(false);
				print('The trap door crashes shut above you. From upstairs, Mormor’s voice: “Close the door, you are letting the cold in!”');
				return;
			}

			look(false);
		};

		const move = direction => {
			const exit = rooms[state.room].exits[direction];
			const target = describe(exit);
			if (target === undefined) {
				print(isLit() ? 'You can’t go that way.' : 'You stumble around in the dark and find nothing. Not even the way.');
				return;
			}

			if (!rooms[target]) {
				print(target);
				return;
			}

			if (state.room === 'temple' && direction === 'u') {
				print('You climb up the narrow chimney, and tumble out of the fireplace in the living room, covered in soot.');
				print();
			}

			goTo(target);
		};

		// Finds the thing that the words of the visitor name, among the things in reach, or among all things in the room for EXAMINE. It prefers the thing whose words match the most.
		const findThing = words => {
			if (words.length === 0) {
				return undefined;
			}

			if (words.length === 1 && (words[0] === 'it' || words[0] === 'them')) {
				return lastThing && isInReach(lastThing) ? lastThing : undefined;
			}

			let best;
			let bestCount = 0;
			for (const id of Object.keys(things)) {
				if (!isInReach(id) || (id === 'trapDoor' && !state.flags.rugMoved) || (id === 'milk' && !state.flags.iceChipped && !isCarried('milk'))) {
					continue;
				}

				const count = words.filter(word => things[id].words.includes(word)).length;
				const hasNoun = things[id].words.includes(words.at(-1));
				if (hasNoun && count > bestCount) {
					best = id;
					bestCount = count;
				}
			}

			return best;
		};

		// Splits a command into its verb and the words of its one or two things, like PUT EGG IN IRON.
		const parse = text => {
			const words = text.toLowerCase().replaceAll(/[^a-zæøå\d\s]/g, ' ').split(/\s+/).filter(word => word && !fillerWords.has(word));
			if (words.length === 0) {
				return {verb: 'none'};
			}

			if (Object.hasOwn(directions, words[0]) && words.length === 1) {
				return {verb: 'go', direction: directions[words[0]]};
			}

			let verb;
			let rest = words;
			for (const [phrase, canonical] of verbWords) {
				const phraseWords = phrase.split(' ');
				if (phraseWords.every((word, index) => words[index] === word)) {
					verb = canonical;
					rest = words.slice(phraseWords.length);
					break;
				}
			}

			if (!verb) {
				return {verb: 'unknown', word: words[0]};
			}

			// GO, ENTER, and CLIMB take a direction, or a window or a chimney to go through.
			const direction = directions[rest.find(word => Object.hasOwn(directions, word))];
			const throughWindow = rest.includes('window') || rest.includes('house') ? 'in' : undefined;
			if (verb === 'go') {
				return {verb: 'go', direction: direction ?? throughWindow ?? (words[0] === 'enter' ? 'in' : undefined)};
			}

			if (verb === 'climb' && (rest.length === 0 || direction || throughWindow || rest.includes('chimney') || rest.includes('stairs') || rest.includes('staircase'))) {
				return {verb: 'go', direction: direction ?? throughWindow ?? (words[1] === 'down' ? 'd' : 'u')};
			}

			const split = rest.findIndex(word => prepositions.has(word));
			const direct = split === -1 ? rest : rest.slice(0, split);
			const indirect = split === -1 ? [] : rest.slice(split + 1);
			return {verb, direct, indirect, preposition: split === -1 ? undefined : rest[split], all: direct.includes('all') || direct.includes('everything')};
		};

		const take = id => {
			const thing = things[id];
			if (isCarried(id)) {
				return 'You already have that.';
			}

			if (thing.isPerson) {
				return 'The troll is too heavy. Also, he would not like it.';
			}

			if (thing.isFixed) {
				return randomItem(['It is securely fastened.', 'A valiant attempt.', 'You can’t be serious.']);
			}

			if (id === 'milk' && !state.flags.iceChipped) {
				return 'The milk is frozen solid into the ice. You need something sharp to chip it out.';
			}

			state.things[id].location = 'player';
			state.things[id].isMoved = true;
			if (id === 'lamp') {
				award('lamp', 5);
			}

			if (id === 'egg') {
				award('egg', 10);
			}

			if (id === 'milk') {
				award('milk', 10);
			}

			if (id === 'flour') {
				award('flour', 10);
			}

			return 'Taken.';
		};

		const bake = () => {
			const contents = contentsOf('iron');
			const hasAll = ['flour', 'egg', 'milk'].every(id => contents.includes(id));
			if (state.room !== 'temple') {
				print('“Kos!” you say. Nothing happens. It works better near a waffle iron.');
				return;
			}

			if (state.things.iron.isOpen) {
				print('The temple echoes: “KOS... kos... kos...” Nothing happens. Perhaps the iron should be closed first.');
				return;
			}

			if (!hasAll) {
				print('The temple echoes: “KOS... kos... kos...” The waffle iron hums, then stops. Something is missing inside it.');
				return;
			}

			for (const id of ['flour', 'egg', 'milk']) {
				state.things[id].location = 'nowhere';
			}

			state.things.waffle.location = 'iron';
			state.flags.waffleBaked = true;
			award('bake', 15);
			print('The temple echoes: “KOS... kos... kos...”');
			print('The golden waffle iron glows, hisses, and smells of every Sunday morning that ever was. Then it clicks. Something is ready inside.');
		};

		const win = () => {
			award('case', 15);
			print('As you place the Golden Waffle in the trophy case, Mormor walks in, with brown cheese and a cheese slicer.');
			print('“My Golden Waffle! You found it! Now we can have waffles for the next 300 years.”');
			print();
			print('    ****  You have won  ****');
			print();
			print(`Your score is ${score()} of a possible 100, in ${state.moves + 1} moves. This gives you the rank of ${rank()}.`);
			print();
			print('Would you like to RESTART, or RESTORE a saved game?');
			state.isOver = true;
			this.celebrate();
			this.cheer();
			this.toast(`🧇 You won WAFFLE QUEST with ${score()} of 100 points!`);
		};

		const handlers = {
			none() {
				print('I beg your pardon?');
			},
			unknown({word}) {
				print(`I don’t know the word “${word}”.`);
			},
			go({direction}) {
				if (!direction) {
					print('Where do you want to go?');
					return;
				}

				move(direction);
			},
			look() {
				look(true);
			},
			inventory() {
				const carried = contentsOf('player');
				if (carried.length === 0) {
					print('You are empty-handed.');
					return;
				}

				print('You are carrying:');
				for (const id of carried) {
					print(`  ${withArticle(things[id].name)}${id === 'lamp' && state.things.lamp.isOn ? ' (providing light)' : ''}`);
					listContents(id, '  ');
				}
			},
			examine({thing}) {
				if (!isLit()) {
					print('It’s too dark to see.');
					return;
				}

				print(describe(things[thing].description) ?? `There’s nothing special about the ${things[thing].name}.`);
				if (things[thing].isContainer) {
					if (!state.things[thing].isOpen && !things[thing].isTransparent) {
						print(`The ${things[thing].name} is closed.`);
					} else if (contentsOf(thing).length === 0) {
						print(`The ${things[thing].name} is empty.`);
					} else {
						listContents(thing);
					}
				}
			},
			read({thing}) {
				if (!isLit()) {
					print('It’s too dark to read.');
					return;
				}

				print(things[thing].text ?? `There is nothing written on the ${things[thing].name}.`);
			},
			take({thing, all}) {
				if (all) {
					const takeable = contentsOf(state.room).filter(id => !things[id].isFixed && (id !== 'milk' || state.flags.iceChipped));
					if (takeable.length === 0 || !isLit()) {
						print('There is nothing here to take.');
						return;
					}

					for (const id of takeable) {
						print(`${things[id].name}: ${take(id)}`);
					}

					return;
				}

				if (!isLit() && !isCarried(thing)) {
					print('It’s too dark to see.');
					return;
				}

				print(take(thing));
			},
			drop({thing, all}) {
				const list = all ? contentsOf('player') : [thing];
				if (list.length === 0) {
					print('You are empty-handed.');
					return;
				}

				for (const id of list) {
					if (!isHeld(id)) {
						print('You don’t have that.');
						continue;
					}

					state.things[id].location = state.room;
					print(all ? `${things[id].name}: Dropped.` : 'Dropped.');
				}
			},
			open({thing}) {
				if (thing === 'window') {
					state.flags.windowOpen = true;
					print('With great effort, you open the window far enough for a kid to get in.');
					return;
				}

				if (thing === 'trapDoor') {
					state.flags.trapOpen = true;
					print('The door reluctantly opens to reveal a rickety staircase descending into darkness.');
					return;
				}

				if (!things[thing].isContainer) {
					print(`You can’t open the ${things[thing].name}.`);
					return;
				}

				if (state.things[thing].isOpen) {
					print('It is already open.');
					return;
				}

				state.things[thing].isOpen = true;
				const contents = contentsOf(thing);
				if (contents.length === 0) {
					print('Opened.');
				} else {
					print(`Opening the ${things[thing].name} reveals ${contents.map(id => withArticle(things[id].name)).join(' and ')}.`);
				}
			},
			close({thing}) {
				if (thing === 'window') {
					state.flags.windowOpen = false;
					print('The window closes.');
					return;
				}

				if (thing === 'trapDoor') {
					state.flags.trapOpen = false;
					print('The door swings shut and closes.');
					return;
				}

				if (!things[thing].isContainer || !state.things[thing].isOpen) {
					print(things[thing].isContainer ? 'It is already closed.' : `You can’t close the ${things[thing].name}.`);
					return;
				}

				state.things[thing].isOpen = false;
				print('Closed.');
			},
			light({thing}) {
				if (thing !== 'lamp') {
					print(`You can’t turn that on.`);
					return;
				}

				const wasLit = isLit();
				state.things.lamp.isOn = true;
				print('The brass lantern is now on.');
				if (!wasLit && isLit()) {
					state.darkTurns = 0;
					print();
					look(true);
				}
			},
			extinguish({thing}) {
				if (thing !== 'lamp') {
					print('You can’t turn that off.');
					return;
				}

				state.things.lamp.isOn = false;
				print('The brass lantern is now off.');
				if (!isLit()) {
					print('It is now pitch black.');
				}
			},
			move({thing}) {
				if (thing === 'rug') {
					if (state.flags.rugMoved) {
						print('Having moved the rug once, you find it impossible to move it again.');
						return;
					}

					state.flags.rugMoved = true;
					state.things.trapDoor.location = 'livingRoom';
					print('With a great effort, the rug is moved to one side of the room, revealing the dusty cover of a closed trap door.');
					return;
				}

				if (thing === 'lever') {
					if (state.flags.milled) {
						print('The millstone grinds and rumbles, but there is no more grain to grind.');
						return;
					}

					state.flags.milled = true;
					state.things.flour.location = 'mill';
					print('The millstone grinds and rumbles. A cloud of white dust comes out of the chute, and a sack of flour drops into the bin.');
					return;
				}

				print(things[thing].isFixed ? 'Moving it would not help.' : 'Moving it reveals nothing.');
			},
			put({thing, target}) {
				if (!target) {
					print(`What do you want to put the ${things[thing].name} in?`);
					return;
				}

				if (!isHeld(thing)) {
					print('You don’t have that.');
					return;
				}

				if (!things[target].isContainer) {
					print(`You can’t put things in the ${things[target].name}.`);
					return;
				}

				if (thing === target || location(target) === thing) {
					print('You can’t put something inside itself. Not even in Bergen.');
					return;
				}

				if (!state.things[target].isOpen) {
					print(`The ${things[target].name} is closed.`);
					return;
				}

				if (target === 'case' && thing !== 'waffle') {
					print('The sign in the case says it is reserved for the Golden Waffle.');
					return;
				}

				if (target === 'iron' && !['flour', 'egg', 'milk'].includes(thing)) {
					print('That does not belong in a waffle iron. Mormor would faint.');
					return;
				}

				state.things[thing].location = target;
				print('Done.');
				if (target === 'case') {
					win();
				}
			},
			give({thing, target}) {
				// FEED TROLL gives the troll the sandwich, if there is one.
				if (thing === 'troll' && !target) {
					if (!isHeld('sandwich')) {
						print('You have nothing that the troll would eat. Except you.');
						return;
					}

					handlers.give({thing: 'sandwich', target: 'troll'});
					return;
				}

				if (!target) {
					print(`Who do you want to give the ${things[thing].name} to?`);
					return;
				}

				if (target !== 'troll') {
					print(`The ${things[target].name} doesn’t want it.`);
					return;
				}

				if (state.flags.trollFed) {
					print('The troll is asleep. Let sleeping trolls lie.');
					return;
				}

				if (!isHeld(thing)) {
					print('You don’t have that.');
					return;
				}

				if (thing !== 'sandwich') {
					print(`The troll sniffs the ${things[thing].name}, growls, and throws it back at you. It is not food.`);
					return;
				}

				state.things.sandwich.location = 'nowhere';
				state.flags.trollFed = true;
				award('troll', 15);
				print('The troll, who is remarkably coordinated for someone with one tooth, catches the sandwich and eats it in one bite. He smiles, lies down, and falls asleep at once. The passages are free.');
			},
			use({thing, target}) {
				if (thing === 'slicer' && target) {
					handlers.break({thing: target, target: 'slicer'});
				} else if (thing === 'lamp') {
					handlers.light({thing});
				} else if (thing === 'lever' || thing === 'rug') {
					handlers.move({thing});
				} else if (target) {
					handlers.put({thing, target});
				} else {
					print('You’ll have to be more specific. What do you want to do with it?');
				}
			},
			eat({thing}) {
				if (thing === 'sandwich') {
					print('You could, but something tells you that somebody down below needs it more.');
					return;
				}

				print(thing === 'waffle' ? 'Eat the Golden Waffle? It belongs in Mormor’s trophy case!' : 'That does not sound very tasty.');
			},
			drink({thing}) {
				print(thing === 'milk' ? 'It is for the waffle. You can have a glass afterward.' : 'You can’t drink that.');
			},
			break({thing, target}) {
				if (thing === 'ice') {
					if (state.flags.iceChipped) {
						print('It is already chipped open.');
						return;
					}

					if (target !== 'slicer' || !isHeld('slicer')) {
						print(target ? `The ${things[target].name} is not sharp enough.` : 'With what? Your teeth?');
						return;
					}

					state.flags.iceChipped = true;
					print('Chip, chip, chip. The cheese slicer was not made for ice, but it works. A bottle of milk slides out of the ice block.');
					return;
				}

				handlers.attack({thing, target});
			},
			attack({thing, target}) {
				if (thing !== 'troll') {
					print(`Violence isn’t the answer to this one.`);
					return;
				}

				if (state.flags.trollFed) {
					print('Attacking a sleeping troll? That is not very sporting.');
					return;
				}

				if (!target) {
					print('With what? Your bare hands?');
					return;
				}

				die(`The troll laughs, catches your ${things[target].name}, and slices you thinly with his own cheese slicer. Trolls know their slicers.`);
			},
			say({direct}) {
				if (direct.includes('kos')) {
					bake();
				} else if (direct.length === 0) {
					print('Say what?');
				} else {
					print(`“${direct.join(' ')}!” you say. The walls do not care.`);
				}
			},
			kos() {
				bake();
			},
			talk({thing}) {
				print(thing === 'troll' ? (state.flags.trollFed ? 'The troll snores.' : 'The troll grunts: “HUNGRY.” He looks at your hands, then at you. Mostly at you.') : 'There is no answer.');
			},
			hello() {
				print(state.room === 'trollRoom' && !state.flags.trollFed ? 'The troll grunts: “HUNGRY.”' : 'Hei! Nice weather we are having. Just kidding, it is raining.');
			},
			wait() {
				print('Time passes. It rains.');
			},
			climb({thing}) {
				print(thing === 'iron' ? 'You climb onto the altar. Nothing happens, except that you feel silly.' : 'You can’t climb that.');
			},
			score() {
				print(`Your score is ${score()} (total of 100 points), in ${state.moves} move${state.moves === 1 ? '' : 's'}. This gives you the rank of ${rank()}.`);
			},
			help() {
				print('WAFFLE QUEST understands sentences like TAKE LAMP, OPEN THE MAILBOX, GO NORTH (or just N), PUT EGG IN IRON, and GIVE SANDWICH TO TROLL. Useful words: LOOK (L), INVENTORY (I), EXAMINE (X), READ, TAKE ALL, SCORE, SAVE, RESTORE, UNDO, and AGAIN (G). The up arrow brings back what you typed before. Stuck? The WaffleClues hint book on this page has the answers, in invisible ink.');
			},
			verbose() {
				isVerbose = true;
				print('Maximum verbosity.');
			},
			brief() {
				isVerbose = false;
				print('Brief descriptions.');
			},
			diagnose() {
				print('You are in perfect health. A little wet. It’s Bergen.');
			},
			xyzzy() {
				print('A hollow voice says “Wrong game.”');
			},
			jump() {
				print('Wheeeeeeeeee!!!!!');
			},
			sing() {
				print('You sing “Hurra for deg som fyller ditt år”. Somewhere, a grue covers its ears.');
			},
			dance() {
				print('You do the Macarena. Nobody sees it. Good.');
			},
			pray() {
				print('If you pray enough, your prayers may be answered. Mostly by Mormor.');
			},
			sleep() {
				print('There is no time for that. Mormor needs her waffle!');
			},
			listen() {
				print(state.room === 'trollRoom' ? 'You hear a troll breathing. Loudly.' : 'You hear the rain. Always the rain.');
			},
			smell() {
				print(state.room === 'temple' ? 'It smells of waffles. Every Sunday ever.' : 'It smells of rain and brown cheese, like all of Bergen.');
			},
			swear() {
				print('Such language from a kid! Mormor would wash your mouth with brown cheese.');
			},
			quit() {
				print('You can’t quit now! Mormor needs her waffle. (Type RESTART to begin again.)');
			},
			version() {
				print('WAFFLE QUEST: The Great Underground Kitchen\nRelease 1 / Serial number 991009 / Interpreter SindreDOS 6.22');
			},
			wake({thing}) {
				print(thing === 'troll' ? 'You do not want to wake a troll. Trust me.' : 'It is not asleep.');
			},
			kiss() {
				print('I’d sooner kiss a grue.');
			},
			knock() {
				print('Nobody answers. Mormor is busy.');
			},
		};

		// The commands that need a thing, with what to ask when it is missing.
		const needsThing = new Set(['use', 'examine', 'read', 'take', 'drop', 'open', 'close', 'light', 'extinguish', 'move', 'put', 'give', 'eat', 'drink', 'break', 'attack', 'talk', 'climb', 'wake', 'kiss']);

		const run = text => {
			const command = parse(text);
			if (command.verb === 'again') {
				if (!lastCommand) {
					print('There is nothing to repeat.');
					return;
				}

				run(lastCommand);
				return;
			}

			if (command.verb === 'restart') {
				state = newState();
				undoState = undefined;
				screen.textContent = '';
				intro();
				return;
			}

			if (command.verb === 'undo') {
				if (!undoState) {
					print('There is nothing to undo.');
					return;
				}

				state = undoState;
				undoState = undefined;
				print('[Previous turn undone.]');
				print();
				look(true);
				return;
			}

			if (command.verb === 'save') {
				this.store('save', state);
				print('Please insert your save disk in drive A:\nSaving to A:\\WAFFLE.SAV... Ok.');
				return;
			}

			if (command.verb === 'restore') {
				const saved = this.stored('save', undefined);
				if (!saved) {
					print('There is no saved game on the disk in drive A:.');
					return;
				}

				state = saved;
				undoState = undefined;
				print('Restored from A:\\WAFFLE.SAV.');
				print();
				look(true);
				return;
			}

			if (state.isDead || state.isOver) {
				print(state.isDead ? 'You are dead. Type RESTART, RESTORE, or UNDO.' : 'You won! Type RESTART to play again, or RESTORE.');
				return;
			}

			lastCommand = text;
			if (['score', 'help', 'version', 'verbose', 'brief', 'none', 'unknown'].includes(command.verb)) {
				handlers[command.verb](command);
				return;
			}

			if (command.all && command.verb !== 'take' && command.verb !== 'drop') {
				print('You can’t use multiple objects with that verb.');
				return;
			}

			if (needsThing.has(command.verb) && !command.all) {
				command.thing = findThing(command.direct);
				command.target = findThing(command.indirect);
				if (command.direct.length === 0) {
					print(`What do you want to ${text.trim().toLowerCase()}?`);
					return;
				}

				if (!command.thing) {
					print(isLit() ? `You can’t see any ${command.direct.join(' ')} here!` : 'It’s too dark to see.');
					return;
				}

				if (command.indirect.length > 0 && !command.target) {
					print(`You can’t see any ${command.indirect.join(' ')} here!`);
					return;
				}

				lastThing = command.thing;
			}

			const before = structuredClone(state);
			handlers[command.verb](command);
			undoState = before;
			state.moves++;
			// Each turn that ends in the dark brings the grue closer: a warning, then a noise, then the grue. Walking around in the dark after the warning is the fastest way to meet it.
			if (state.isDead) {
				return;
			}

			if (isLit()) {
				state.darkTurns = 0;
			} else {
				state.darkTurns++;
				if (state.darkTurns === 2) {
					print('You hear something slithering in the darkness nearby.');
				} else if (state.darkTurns >= 3) {
					die(randomItem(['Oh, no! You have walked into the slavering fangs of a lurking grue!', 'Oh, no! A lurking grue slithered into the room and devoured you!']));
				}
			}
		};

		const intro = () => {
			print('WAFFLE QUEST: The Great Underground Kitchen', true);
			print('An Interactive Fantasy, by Sindre');
			print('Copyright (c) 1999 Sindresoft. All rights reserved.');
			print('Release 1 / Serial number 991009');
			print();
			look(true);
			updateStatus();
		};

		// Shows what is typed with a blinking DOS cursor where the caret is, as the field itself is see-through on top of it.
		const updateMirror = () => {
			const caret = input.selectionStart ?? input.value.length;
			typed.textContent = input.value.slice(0, caret);
			after.textContent = input.value.slice(caret);
		};

		for (const event of ['input', 'keyup', 'click', 'focus', 'select']) {
			this.on(input, event, updateMirror);
		}

		const submit = text => {
			print(`>${text}`);
			// A command that the parser cannot handle must not freeze the screen.
			try {
				run(text);
			} catch {
				print('I don’t understand that sentence.');
			}

			print();
			updateStatus();
		};

		this.on(form, 'submit', event => {
			event.preventDefault();
			const text = input.value;
			input.value = '';
			updateMirror();
			if (text.trim()) {
				history.push(text);
				history = history.slice(-30);
			}

			historyIndex = history.length;
			submit(text);
		});

		// The up and down arrows bring back what was typed before, like DOSKEY.
		this.on(input, 'keydown', event => {
			if (event.key === 'ArrowUp' && historyIndex > 0) {
				event.preventDefault();
				historyIndex--;
				input.value = history[historyIndex];
			} else if (event.key === 'ArrowDown' && historyIndex < history.length) {
				event.preventDefault();
				historyIndex++;
				input.value = history[historyIndex] ?? '';
			} else {
				return;
			}

			requestAnimationFrame(() => {
				input.setSelectionRange(input.value.length, input.value.length);
				updateMirror();
			});
		});

		// A click on the screen types, like on a real terminal, unless the visitor selects text to copy.
		this.on(screen, 'click', () => {
			if (String(getSelection()).length === 0) {
				input.focus({preventScroll: true});
			}
		});

		for (const button of this.querySelectorAll('[data-waffle-quest-command]')) {
			this.on(button, 'click', () => {
				submit(button.dataset.waffleQuestCommand);
			});
		}

		intro();
	}

	// The audio is made at the first sound, in the click or the key press that makes it, as browsers only let audio start then.
	#beep(...options) {
		if (this.#isSoundOn) {
			beep(this.sound(), ...options);
		}
	}
}
