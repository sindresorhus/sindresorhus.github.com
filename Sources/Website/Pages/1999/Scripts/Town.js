// SimSindreville 2000 on the 1999 page: a strip of land of 480 × 160 pixels, drawn twice as large, with eight lots between the mountains and the road. The buildings are drawn with rectangles, so their windows can light up at night. The taxes come in each month, which is six seconds while the town is on the screen, and for the time the visitor was away.

const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Makes a canvas with a sprite of big pixels, from rows of letters where each letter is a color of the palette, and any other letter, like a dot, is clear. Short rows are clear at the end.
const makeSprite = (rows, palette, scale = 1) => {
	const width = Math.max(...rows.map(row => row.length));
	const canvas = document.createElement('canvas');
	canvas.width = width * scale;
	canvas.height = rows.length * scale;
	const context = canvas.getContext('2d');

	for (const [y, row] of rows.entries()) {
		for (const [x, letter] of [...row].entries()) {
			if (palette[letter]) {
				context.fillStyle = palette[letter];
				context.fillRect(x * scale, y * scale, scale, scale);
			}
		}
	}

	return canvas;
};

export default class extends GeoCitiesElement {
	// The town only lives while the picture is on the screen, not while only the newspaper below it is.
	get visibilityTarget() {
		return this.parts.city;
	}

	connected() {
		const {city: townCanvas, news, funds: fundsText, population: populationText, date: dateText} = this.parts;
		const lotButtons = [...this.querySelectorAll('[data-town-lot]')];
		const toolInputs = [...this.querySelectorAll('input[name="geocities-town-tool"]')];
		const width = 480;
		const height = 160;
		const ground = 128;
		const scene = document.createElement('canvas');
		scene.width = width;
		scene.height = height;
		const sceneContext = scene.getContext('2d');
		const context = townCanvas.getContext('2d');
		const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

		const buildings = {
			house: {name: 'house', price: 100, residents: 4, jobs: 0},
			waffle: {name: 'waffle café', price: 250, residents: 0, jobs: 5},
			cafe: {name: 'Internet café', price: 300, residents: 0, jobs: 4},
			church: {name: 'stave church', price: 400, residents: 0, jobs: 1},
			park: {name: 'park', price: 50, residents: 0, jobs: 0},
			tower: {name: 'GeoCities tower', price: 500, residents: 2, jobs: 5},
			trollrock: {name: 'troll rock', price: 0, residents: 0, jobs: 0},
			rubble: {name: 'pile of rubble', price: 0, residents: 0, jobs: 0},
		};

		const floorPrice = 150;
		const maximumFloors = 9;
		const houseColors = ['#b22222', '#e8c547', '#f4f4f4', '#d2691e', '#4a7ab0'];
		const saved = this.stored('city', {});
		const isValidLot = lot => lot?.type === 'empty' || Object.hasOwn(buildings, lot?.type ?? '');
		const lots = Array.isArray(saved.lots) && saved.lots.length === 8 && saved.lots.every(lot => isValidLot(lot)) ? saved.lots : [{type: 'house', color: houseColors[0], floors: 0}, ...Array.from({length: 7}, () => ({type: 'empty'}))];
		for (const lot of lots) {
			if (lot.type === 'tower') {
				lot.floors = clamp(Math.floor(Number(lot.floors) || 1), 1, maximumFloors);
			}
		}

		let funds = Number.isFinite(saved.funds) ? saved.funds : 1000;
		let month = Number.isInteger(saved.month) ? saved.month : 0;
		let rainStops = Number.isInteger(saved.rainStops) ? saved.rainStops : 0;
		let isRaining = Math.random() < 0.65;
		let sunnyUntil = 0;
		let time = 0;
		let troll;
		let honk;

		const saveTown = () => {
			this.store('city', {lots, funds, month, rainStops, lastSeen: Date.now()});
		};

		const residents = () => lots.reduce((total, lot) => total + (buildings[lot.type]?.residents ?? 0) * (lot.type === 'tower' ? lot.floors : 1), 0);
		const jobs = () => lots.reduce((total, lot) => total + (buildings[lot.type]?.jobs ?? 0) * (lot.type === 'tower' ? lot.floors : 1), 0);
		const monthlyTaxes = () => (residents() * 5) + (Math.min(jobs(), residents()) * 3) + (lots.filter(lot => lot.type === 'trollrock').length * 20) + 10;

		const showStats = () => {
			fundsText.textContent = `Funds: kr ${funds.toLocaleString('en-US')}`;
			populationText.textContent = `Pop. ${residents()}`;
			dateText.textContent = `${months[month % 12]} ${1999 + Math.floor(month / 12)}`;

			for (const [index, button] of lotButtons.entries()) {
				const lot = lots[index];
				const name = lot.type === 'empty' ? 'empty' : buildings[lot.type].name;
				button.textContent = lot.type === 'tower' ? `Lot ${index + 1}: ${name}, ${lot.floors} ${lot.floors === 1 ? 'floor' : 'floors'}` : `Lot ${index + 1}: ${name}`;
			}
		};

		const headline = message => {
			this.say(message, news);
		};

		// MARK: Drawing

		const hourNow = () => {
			const date = new Date();
			return date.getHours() + (date.getMinutes() / 60);
		};

		const isNightAt = hour => hour < 6.5 || hour >= 19.5;
		const isDayAt = hour => hour >= 6 && hour < 20;

		const skyColors = hour => {
			if (isRaining) {
				return isNightAt(hour) ? ['#151525', '#2a2a40'] : ['#6f7a86', '#aab3bc'];
			}

			if (hour < 5 || hour >= 21.5) {
				return ['#070726', '#1a1a50'];
			}

			if (hour < 7.5) {
				return ['#5a4a8a', '#ffaa77'];
			}

			if (hour < 18) {
				return ['#3d8fe0', '#bfe4ff'];
			}

			return ['#4a3a7a', '#ff8855'];
		};

		// The stars do not move, so they are made once.
		const stars = Array.from({length: 40}, () => ({x: Math.random() * width, y: Math.random() * 70}));
		const raindrops = Array.from({length: 140}, () => ({x: Math.random() * width, y: Math.random() * height}));
		const people = Array.from({length: 10}, (_, index) => ({x: Math.random() * width, direction: index % 2 === 0 ? 1 : -1, speed: randomBetween(8, 14), shirt: randomItem(['#cc3333', '#3366cc', '#33aa55', '#ffcc00', '#aa55cc']), umbrella: randomItem(['#ff3366', '#3399ff', '#ffcc00', '#222222'])}));
		const cars = Array.from({length: 5}, (_, index) => ({x: Math.random() * width, lane: index % 2, speed: randomBetween(35, 60), color: randomItem(['#c0392b', '#2c3e50', '#f1c40f', '#ecf0f1', '#27ae60', '#8e44ad'])}));
		const elevator = {floor: 0, target: 1, position: 0};

		const fill = (color, x, y, rectWidth, rectHeight) => {
			sceneContext.fillStyle = color;
			sceneContext.fillRect(Math.round(x), Math.round(y), rectWidth, rectHeight);
		};

		const drawWindow = (x, y, isNight, isLit, dayColor = '#9fd3ff') => {
			fill(isNight ? (isLit ? '#ffe066' : '#202838') : dayColor, x, y, 5, 5);
		};

		const drawMountains = isNight => {
			sceneContext.fillStyle = isNight ? '#1c2438' : (isRaining ? '#5d6878' : '#6c7fa0');
			sceneContext.beginPath();
			sceneContext.moveTo(0, 100);

			for (const [x, y] of [[0, 62], [60, 40], [110, 58], [170, 30], [230, 54], [300, 36], [360, 60], [420, 34], [480, 56], [480, 100]]) {
				sceneContext.lineTo(x, y);
			}

			sceneContext.fill();

			// Ulriken, with its TV tower.
			fill(isNight ? '#ff3333' : '#dddddd', 299, 22, 2, 14);

			sceneContext.fillStyle = isNight ? '#12241a' : (isRaining ? '#3d5a45' : '#3f7a4a');
			sceneContext.beginPath();
			sceneContext.moveTo(0, 104);

			for (const [x, y] of [[0, 80], [50, 70], [100, 84], [160, 66], [220, 82], [280, 72], [340, 86], [400, 70], [480, 82], [480, 104]]) {
				sceneContext.lineTo(x, y);
			}

			sceneContext.fill();
		};

		const drawBuilding = (lot, index, isNight) => {
			const x = index * 60;
			const seed = index * 7;

			switch (lot.type) {
				case 'house': {
					fill('#000000', x + 11, 103, 38, 26);
					fill(lot.color ?? houseColors[0], x + 12, 104, 36, 24);
					sceneContext.fillStyle = '#3a2a2a';
					sceneContext.beginPath();
					sceneContext.moveTo(x + 7, 105);
					sceneContext.lineTo(x + 30, 88);
					sceneContext.lineTo(x + 53, 105);
					sceneContext.fill();
					fill('#5a3a2a', x + 40, 88, 4, 10);
					fill('#6b4423', x + 27, 116, 6, 12);
					drawWindow(x + 16, 109, isNight, (seed % 3) !== 0);
					drawWindow(x + 39, 109, isNight, (seed % 2) === 0);
					break;
				}

				case 'waffle': {
					fill('#000000', x + 7, 97, 46, 32);
					fill('#ffd1dc', x + 8, 98, 44, 30);

					for (let stripe = 0; stripe < 11; stripe++) {
						fill(stripe % 2 === 0 ? '#cc0000' : '#ffffff', x + 8 + (stripe * 4), 96, 4, 5);
					}

					fill('#6b4423', x + 26, 114, 8, 14);
					drawWindow(x + 12, 106, isNight, true, '#bfe8ff');
					drawWindow(x + 18, 106, isNight, true, '#bfe8ff');
					drawWindow(x + 38, 106, isNight, true, '#bfe8ff');
					drawWindow(x + 44, 106, isNight, true, '#bfe8ff');

					// A waffle heart on the roof, with its grid.
					sceneContext.fillStyle = '#e8a840';
					sceneContext.beginPath();
					sceneContext.arc(x + 26, 86, 5, 0, Math.PI * 2);
					sceneContext.arc(x + 34, 86, 5, 0, Math.PI * 2);
					sceneContext.fill();
					sceneContext.beginPath();
					sceneContext.moveTo(x + 21, 87);
					sceneContext.lineTo(x + 30, 96);
					sceneContext.lineTo(x + 39, 87);
					sceneContext.fill();
					fill('#b07020', x + 24, 84, 12, 1);
					fill('#b07020', x + 24, 88, 12, 1);
					fill('#b07020', x + 28, 82, 1, 10);
					fill('#b07020', x + 32, 82, 1, 10);
					break;
				}

				case 'cafe': {
					fill('#000000', x + 7, 93, 46, 36);
					fill('#7080a0', x + 8, 94, 44, 34);
					fill('#202838', x + 12, 100, 36, 12);

					// Monitors glow behind the big window.
					for (let screen = 0; screen < 4; screen++) {
						fill(isNight || Math.floor(time * 2 + screen) % 3 !== 0 ? '#33ffcc' : '#1a8870', x + 14 + (screen * 9), 104, 5, 4);
					}

					fill('#404858', x + 26, 116, 8, 12);
					fill(Math.floor(time * 2) % 2 === 0 ? '#ff33cc' : '#ffff33', x + 22, 84, 16, 9);
					fill('#000000', x + 25, 86, 10, 5);
					break;
				}

				case 'church': {
					fill('#2a160a', x + 13, 105, 34, 23);
					fill('#4a2a1a', x + 14, 106, 32, 22);
					sceneContext.fillStyle = '#2a160a';

					for (const [left, top, right] of [[10, 106, 50], [18, 92, 42], [24, 80, 36]]) {
						sceneContext.beginPath();
						sceneContext.moveTo(x + left, top);
						sceneContext.lineTo(x + 30, top - 10);
						sceneContext.lineTo(x + right, top);
						sceneContext.fill();
					}

					fill('#4a2a1a', x + 22, 92, 16, 14);
					fill('#2a160a', x + 29, 60, 2, 12);

					// The dragon heads on the roofs.
					fill('#2a160a', x + 8, 102, 3, 3);
					fill('#2a160a', x + 49, 102, 3, 3);
					fill('#2a160a', x + 16, 88, 3, 3);
					fill('#2a160a', x + 41, 88, 3, 3);
					fill(isNight ? '#ffcc55' : '#1a0a00', x + 27, 116, 6, 12);
					break;
				}

				case 'park': {
					fill('#4caf50', x + 2, 122, 56, 6);
					fill('#6b4423', x + 18, 104, 4, 20);
					sceneContext.fillStyle = '#2e8b3a';
					sceneContext.beginPath();
					sceneContext.arc(x + 20, 100, 11, 0, Math.PI * 2);
					sceneContext.fill();
					fill('#8b5a2b', x + 34, 118, 14, 2);
					fill('#8b5a2b', x + 35, 120, 2, 4);
					fill('#8b5a2b', x + 45, 120, 2, 4);
					fill('#ff3366', x + 8, 120, 2, 2);
					fill('#ffcc00', x + 52, 120, 2, 2);
					break;
				}

				case 'tower': {
					const floors = lot.floors;
					const top = ground - (floors * 12);
					fill('#000000', x + 7, top - 1, 46, (floors * 12) + 1);
					fill('#b8b0d8', x + 8, top, 44, floors * 12);

					for (let floor = 0; floor < floors; floor++) {
						const y = ground - ((floor + 1) * 12) + 3;

						for (let column = 0; column < 4; column++) {
							drawWindow(x + 11 + (column * 8), y, isNight, ((floor * 5) + (column * 3) + index) % 4 !== 0, '#9fd3ff');
						}
					}

					// The elevator in its shaft, which rides between the floors.
					fill('#5a5080', x + 44, top, 6, floors * 12);
					fill('#ffcc00', x + 45, ground - 10 - Math.round(elevator.position * 12), 4, 8);

					// The sign of GeoCities on the roof, with a light that blinks.
					fill('#660099', x + 10, top - 9, 40, 8);
					fill(Math.floor(time * 2) % 2 === 0 ? '#ff0000' : '#550000', x + 29, top - 13, 2, 3);
					break;
				}

				case 'trollrock': {
					sceneContext.fillStyle = '#8a8a8a';
					sceneContext.beginPath();
					sceneContext.ellipse(x + 30, 116, 16, 12, 0, 0, Math.PI * 2);
					sceneContext.fill();
					sceneContext.beginPath();
					sceneContext.ellipse(x + 30, 100, 10, 9, 0, 0, Math.PI * 2);
					sceneContext.fill();
					fill('#6a6a6a', x + 33, 100, 8, 5);
					fill('#4c8a3c', x + 22, 92, 10, 3);
					fill('#000000', x + 27, 97, 2, 2);
					fill('#000000', x + 33, 97, 2, 2);
					break;
				}

				case 'rubble': {
					for (let piece = 0; piece < 12; piece++) {
						fill(piece % 3 === 0 ? '#6b4423' : '#777777', x + 10 + ((piece * 7) % 38), 120 - ((piece * 3) % 8), 6, 8);
					}

					break;
				}

				default: {
					// An empty lot, with a sign for sale.
					fill('#5a8a3a', x + 2, 124, 56, 4);
					fill('#6b4423', x + 29, 112, 2, 12);
					fill('#ffffff', x + 22, 106, 16, 8);
					fill('#cc0000', x + 24, 109, 12, 2);
					break;
				}
			}
		};

		const drawPerson = (person, isNight) => {
			const x = Math.round(person.x);
			fill('#222222', x, 131, 1, 3);
			fill('#222222', x + 2, 131, 1, 3);
			fill(person.shirt, x, 127, 3, 4);
			fill('#ffd8b0', x, 124, 3, 3);

			if (isRaining) {
				fill(person.umbrella, x - 2, 120, 7, 2);
				fill(person.umbrella, x - 1, 119, 5, 1);
				fill('#000000', x + 1, 121, 1, 3);
			}

			if (isNight) {
				fill('rgba(0, 0, 0, 0.3)', x - 2, 119, 7, 15);
			}
		};

		const drawCar = (car, isNight) => {
			const x = Math.round(car.x);
			const y = car.lane === 0 ? 141 : 147;
			fill('#000000', x - 1, y - 1, 22, 7);
			fill(car.color, x, y, 20, 5);
			fill(car.color, x + 4, y - 4, 11, 4);
			fill('#9fd3ff', x + 5, y - 3, 4, 3);
			fill('#9fd3ff', x + 10, y - 3, 4, 3);
			fill('#111111', x + 3, y + 4, 4, 3);
			fill('#111111', x + 13, y + 4, 4, 3);

			if (isNight) {
				fill('#ffff99', car.lane === 0 ? x + 20 : x - 3, y + 1, 3, 2);
			}
		};

		const trollRows = [
			'....hhhhh.....',
			'...hhhhhhh....',
			'..ttttttttt...',
			'..tkttttkt....',
			'..ttttttttt...',
			'.tttttNNNttt..',
			'..ttttNNNNtt..',
			'...tttNNNNt...',
			'....tttttt....',
			'..bbbbbbbbbb..',
			'.bbbbbbbbbbbb.',
			'tbbbbbbbbbbbbt',
			't.bbbbbbbbbb.t',
			'..bbbbbbbbbb..',
			'..bb......bb..',
			'..tt......tt..',
			'.ttt......ttt.',
		];

		const trollSprite = makeSprite(trollRows, {h: '#3a2a1a', t: '#6a8a4a', k: '#000000', N: '#8aa86a', b: '#6b4423'}, 2);
		const stoneSprite = makeSprite(trollRows, {h: '#6a6a6a', t: '#8a8a8a', k: '#444444', N: '#9a9a9a', b: '#7a7a7a'}, 2);

		const draw = () => {
			const hour = hourNow();
			const isNight = isNightAt(hour);
			const [skyTop, skyBottom] = skyColors(hour);
			const sky = sceneContext.createLinearGradient(0, 0, 0, 100);
			sky.addColorStop(0, skyTop);
			sky.addColorStop(1, skyBottom);
			sceneContext.fillStyle = sky;
			sceneContext.fillRect(0, 0, width, 104);

			if (isNight && !isRaining) {
				for (const star of stars) {
					fill('#ffffff', star.x, star.y, 1, 1);
				}

				sceneContext.fillStyle = '#fffbe0';
				sceneContext.beginPath();
				sceneContext.arc(420, 22, 9, 0, Math.PI * 2);
				sceneContext.fill();
				sceneContext.fillStyle = skyTop;
				sceneContext.beginPath();
				sceneContext.arc(425, 19, 8, 0, Math.PI * 2);
				sceneContext.fill();
			} else if (!isRaining) {
				// The sun follows the clock of the visitor across the sky.
				const progress = clamp((hour - 6) / 14, 0, 1);
				sceneContext.fillStyle = '#ffdd33';
				sceneContext.beginPath();
				sceneContext.arc(20 + (progress * 440), 80 - (Math.sin(progress * Math.PI) * 62), 10, 0, Math.PI * 2);
				sceneContext.fill();
			}

			drawMountains(isNight);

			// The clouds: a few white ones, or a gray lid over Bergen.
			sceneContext.fillStyle = isRaining ? (isNight ? '#2a2a38' : '#8a929c') : 'rgba(255, 255, 255, 0.85)';

			for (let cloud = 0; cloud < (isRaining ? 9 : 3); cloud++) {
				const x = ((cloud * 97) + (time * 4)) % (width + 80) - 40;
				const y = isRaining ? 6 + ((cloud % 3) * 6) : 18 + ((cloud % 2) * 14);
				sceneContext.beginPath();
				sceneContext.ellipse(x, y, isRaining ? 46 : 20, isRaining ? 12 : 6, 0, 0, Math.PI * 2);
				sceneContext.fill();
			}

			fill(isNight ? '#2a4a2a' : '#5a8a3a', 0, 104, width, 24);
			fill('#b8b8b8', 0, ground, width, 6);
			fill('#404040', 0, 134, width, 18);

			for (let x = 0; x < width; x += 20) {
				fill('#ffffff', x, 143, 10, 1);
			}

			fill(isNight ? '#0a1a3a' : '#2a5a9a', 0, 152, width, 8);

			for (let x = 0; x < width; x += 16) {
				fill('rgba(255, 255, 255, 0.4)', x + ((time * 6) % 16), 154 + ((x / 16) % 2), 5, 1);
			}

			for (const [index, lot] of lots.entries()) {
				drawBuilding(lot, index, isNight);
			}

			const population = residents();
			const walkers = Math.min(people.length, Math.floor(population / 6));

			for (const person of people.slice(0, walkers)) {
				drawPerson(person, isNight);
			}

			const driving = Math.min(cars.length, 1 + Math.floor(population / 15));

			for (const car of cars.slice(0, driving)) {
				drawCar(car, isNight);
			}

			if (troll) {
				sceneContext.drawImage(troll.state === 'stone' ? stoneSprite : trollSprite, Math.round(troll.x - 14), ground - stoneSprite.height + 2 + (troll.state === 'smash' ? Math.round(Math.sin(time * 40)) : 0));
			}

			if (isRaining) {
				sceneContext.fillStyle = 'rgba(180, 200, 255, 0.6)';

				for (const drop of raindrops) {
					sceneContext.fillRect(Math.round(drop.x), Math.round(drop.y), 1, 3);
				}
			}

			context.imageSmoothingEnabled = false;
			context.drawImage(scene, 0, 0, townCanvas.width, townCanvas.height);

			// The words, in sharp letters on the large canvas: the signs of the tower and the honk of a car.
			context.font = 'bold 11px Verdana, sans-serif';
			context.textAlign = 'center';

			for (const [index, lot] of lots.entries()) {
				if (lot.type === 'tower') {
					context.fillStyle = '#ffff66';
					context.fillText('GeoCities', ((index * 60) + 30) * 2, (ground - (lot.floors * 12) - 3) * 2);
				}
			}

			if (honk) {
				const x = clamp(honk.car.x + 10, 20, width - 20) * 2;
				const y = (honk.car.lane === 0 ? 132 : 138) * 2;
				context.fillStyle = '#ffffff';
				context.fillRect(x - 26, y - 22, 52, 20);
				context.strokeStyle = '#000000';
				context.lineWidth = 2;
				context.strokeRect(x - 26, y - 22, 52, 20);
				context.fillStyle = '#cc0000';
				context.font = 'bold 14px Impact, "Arial Black", sans-serif';
				context.fillText('TUT!', x, y - 7);
			}
		};

		// MARK: Simulation

		const simulate = seconds => {
			time += seconds;

			if (sunnyUntil && time > sunnyUntil) {
				sunnyUntil = 0;
				isRaining = true;
				headline('It is raining again. This is Bergen.');
			}

			for (const drop of raindrops) {
				drop.y += 220 * seconds;
				drop.x -= 40 * seconds;

				if (drop.y > height) {
					drop.y -= height;
					drop.x = Math.random() * width;
				}
			}

			for (const person of people) {
				person.x = (person.x + (person.direction * person.speed * seconds) + width + 10) % (width + 10);
			}

			for (const car of cars) {
				const speed = car.speed * (honk?.car === car ? 2.5 : 1);
				car.x = car.lane === 0 ? ((car.x + (speed * seconds) + 30) % (width + 30)) - 30 : ((car.x - (speed * seconds) + width + 30) % (width + 30)) - 30;
			}

			if (honk) {
				honk.time -= seconds;

				if (honk.time <= 0) {
					honk = undefined;
				}
			}

			// The elevator rides to a floor, waits, and picks another.
			const tower = lots.find(lot => lot.type === 'tower');

			if (tower) {
				const distance = elevator.target - elevator.position;

				if (Math.abs(distance) < 0.05) {
					elevator.position = elevator.target;
					elevator.target = Math.floor(Math.random() * tower.floors);
				} else if (elevator.position > tower.floors - 1) {
					elevator.position = tower.floors - 1;
				} else {
					elevator.position += Math.sign(distance) * Math.min(Math.abs(distance), seconds * 1.5);
				}
			}

			if (troll) {
				updateTroll(seconds);
			}
		};

		// The troll walks in from the right, and smashes a building in the dark or the rain. In the sun it turns to stone, like in the old stories.
		const updateTroll = seconds => {
			troll.timer -= seconds;
			const isSunny = isDayAt(hourNow()) && !isRaining;

			switch (troll.state) {
				case 'walk': {
					troll.x -= 16 * seconds;

					if (isSunny && troll.x < 400) {
						troll.state = 'stone';
						troll.timer = 2.5;
						headline('The sun came out, and the troll turned to stone! Just like in the old stories.');
						break;
					}

					if (troll.target !== undefined && troll.x <= (troll.target * 60) + 40) {
						troll.state = 'smash';
						troll.timer = 1.5;
					} else if (troll.x < -30) {
						if (!troll.hasSmashed) {
							headline('The troll found nothing to smash and went back to the mountains.');
						}

						troll = undefined;
					}

					break;
				}

				case 'smash': {
					if (troll.timer <= 0) {
						const lot = lots[troll.target];

						// The visitor bulldozed it while the troll was on its way.
						if (['empty', 'rubble', 'trollrock'].includes(lot.type)) {
							troll.target = undefined;
							troll.state = 'walk';
							break;
						}

						const name = buildings[lot.type].name;
						lots[troll.target] = {type: 'rubble'};
						headline(`The troll smashed the ${name}! Trolls are safe in the ${isRaining ? 'rain' : 'dark'}. Use the bulldozer to clean up.`);
						troll.target = undefined;
						troll.hasSmashed = true;
						troll.state = 'walk';
						showStats();
						saveTown();
					}

					break;
				}

				case 'stone': {
					if (troll.timer <= 0) {
						const lotIndex = Math.round(clamp((troll.x - 30) / 60, 0, 7));
						const emptyLots = lots.map((lot, index) => ({lot, index})).filter(({lot}) => lot.type === 'empty');
						const nearestEmpty = emptyLots.sort((first, second) => Math.abs(first.index - lotIndex) - Math.abs(second.index - lotIndex))[0];

						if (nearestEmpty) {
							lots[nearestEmpty.index] = {type: 'trollrock'};
							headline('The troll rock is a tourist attraction now: kr 20 more in taxes each month!');
						} else {
							headline('The stone troll rolled into the fjord. SPLASH!');
						}

						troll = undefined;
						showStats();
						saveTown();
					}

					break;
				}

				default: {
					break;
				}
			}
		};

		const step = seconds => {
			simulate(seconds);
			draw();
		};

		this.loop(step, {while: () => !this.reducedMotion});

		// Without motion, things that take time happen at once, and the picture is drawn again.
		const settle = () => {
			if (!this.reducedMotion) {
				return;
			}

			for (let index = 0; index < 1000 && troll; index++) {
				if (troll.state === 'walk') {
					troll.x = troll.target === undefined ? Math.min(troll.x, -29) : (troll.target * 60) + 40;
				}

				simulate(0.25);
			}

			draw();
		};

		// MARK: The mayor

		const randomNews = () => {
			const choices = [isRaining ? 'Rain again in Sindreville. Citizens are not surprised.' : 'Sun in Sindreville! Schools close so the kids can see it.', 'Stock market: AOL is up. Bondi Blue iMacs are sold out.', 'The mayor is doing a great job, says the mayor.', 'Local kid builds a home page. Mom is proud.'];

			if (lots.some(lot => lot.type === 'waffle')) {
				choices.push('The waffle café sold out of brown cheese again!');
			}

			if (lots.some(lot => lot.type === 'cafe')) {
				choices.push('Internet café: “The 56K modem is so fast!”');
			}

			if (lots.some(lot => lot.type === 'trollrock')) {
				choices.push('Tourists take photos of the troll rock. Some of them touch its nose.');
			}

			if (month % 12 === 11) {
				choices.push('Y2K: the mayor says the computers of the town are ready. Probably.');
			}

			return randomItem(choices);
		};

		const nextMonth = () => {
			const before = residents();
			funds += monthlyTaxes();
			month++;

			if (month % 12 === 0) {
				headline(`Happy new year ${1999 + Math.floor(month / 12)}! ${month === 12 ? 'Y2K came, and nothing broke. The mayor is relieved.' : 'Fireworks over the fjord!'}`);
			} else if (Math.random() < 0.25) {
				headline(randomNews());
			}

			if (Math.floor(residents() / 25) > Math.floor(before / 25)) {
				headline(`Sindreville has ${residents()} people now!`);
			}

			showStats();
			saveTown();
		};

		this.interval(6000, () => {
			if (this.isVisible) {
				nextMonth();
			}
		});

		const pickedTool = () => toolInputs.find(item => item.checked)?.value ?? 'house';

		const showTool = () => {
			for (const item of toolInputs) {
				const label = item.closest('label');

				if (item.checked) {
					label.dataset.state = 'on';
				} else {
					delete label.dataset.state;
				}
			}
		};

		for (const item of toolInputs) {
			this.on(item, 'change', showTool);
		}

		const useLot = index => {
			const tool = pickedTool();
			const lot = lots[index];

			if (tool === 'bulldozer') {
				if (lot.type === 'empty') {
					headline('The bulldozer flattened an empty lot. It is very flat now.');
					return;
				}

				const refund = lot.type === 'tower' ? Math.floor((buildings.tower.price + ((lot.floors - 1) * floorPrice)) / 2) : Math.floor(buildings[lot.type].price / 2);
				headline(lot.type === 'rubble' ? 'The rubble is gone. The lot is for sale again.' : `Bulldozed the ${buildings[lot.type].name}. You got kr ${refund} back.`);
				funds += refund;
				lots[index] = {type: 'empty'};
			} else if (lot.type === 'tower' && tool === 'tower') {
				if (lot.floors >= maximumFloors) {
					headline('The tower has as many floors as the city allows. The planes need room too.');
					return;
				}

				if (funds < floorPrice) {
					headline(`A new floor costs kr ${floorPrice}. Wait for the taxes!`);
					return;
				}

				funds -= floorPrice;
				lot.floors++;
				headline(`The GeoCities tower has ${lot.floors} floors now. Free home pages on every floor!`);
			} else if (lot.type === 'tower') {
				headline('Pick the GeoCities tower to build one more floor on it, or the bulldozer to clear the lot.');
				return;
			} else if (lot.type !== 'empty') {
				headline(`That lot has a ${buildings[lot.type].name} on it. Use the bulldozer first.`);
				return;
			} else {
				const building = buildings[tool];

				if (funds < building.price) {
					headline(`A ${building.name} costs kr ${building.price}, and you have kr ${funds}. Wait for the taxes!`);
					return;
				}

				funds -= building.price;
				lots[index] = {type: tool, color: randomItem(houseColors), floors: tool === 'tower' ? 1 : 0};
				headline({
					house: 'A new family moved to Sindreville!',
					waffle: 'The waffle café is open! The whole town smells of waffles.',
					cafe: 'The Internet café is open. Surf the Web for kr 30 an hour!',
					church: 'A stave church! The dragons on the roof keep the trolls away. Maybe.',
					park: 'A new park. The sheep from my page would love it.',
					tower: 'The GeoCities tower is open! Click it again with the tower tool for more floors.',
				}[tool]);
			}

			showStats();
			saveTown();
			draw();
		};

		for (const [index, button] of lotButtons.entries()) {
			this.on(button, 'click', () => {
				useLot(index);
			});
		}

		let honkTimer;

		const honkAt = x => {
			const population = residents();
			const driving = cars.slice(0, Math.min(cars.length, 1 + Math.floor(population / 15)));
			const car = driving.sort((first, second) => Math.abs(first.x - x) - Math.abs(second.x - x))[0];
			honk = {car, time: 1.2};
			draw();

			if (this.reducedMotion) {
				honkTimer?.cancel();
				honkTimer = this.timeout(1200, () => {
					honk = undefined;
					draw();
				});
			}
		};

		this.on(townCanvas, 'click', event => {
			const rect = townCanvas.getBoundingClientRect();
			honkAt(((event.clientX - rect.left) / rect.width) * width);
		});

		this.on(this.parts.honk, 'click', () => {
			honkAt(randomBetween(0, width));
			headline(randomItem(['TUT! A Volvo honks back.', 'TUT TUT! The bus driver waves.', 'TUT! Somebody honks back. It is a small town.']));
		});

		this.on(this.parts.sun, 'click', () => {
			if (!isRaining) {
				headline('It is not even raining. Enjoy it while it lasts.');
				return;
			}

			isRaining = false;
			rainStops++;
			saveTown();
			headline(rainStops === 1 ? 'The rain stopped! The people of Sindreville do not know what to do.' : `The rain stopped for the ${rainStops}th time. It will not last.`);
			draw();

			if (this.reducedMotion) {
				this.timeout(20_000, () => {
					isRaining = true;
					headline('It is raining again. This is Bergen.');
					draw();
				});
			} else {
				sunnyUntil = time + 20;
			}
		});

		this.on(this.parts.troll, 'click', () => {
			if (troll) {
				headline('One troll at a time, please.');
				return;
			}

			const built = lots.map((lot, index) => ({lot, index})).filter(({lot}) => !['empty', 'rubble', 'trollrock'].includes(lot.type));
			const isSunny = isDayAt(hourNow()) && !isRaining;
			troll = {x: width + 20, state: 'walk', timer: 0, target: built.length > 0 ? randomItem(built).index : undefined};
			headline(isSunny ? 'A TROLL is coming down from the mountains! Luckily, the sun is out.' : `A TROLL is coming down from the mountains! It is ${isRaining ? 'raining' : 'dark'}, so nothing can stop it.`);
			settle();
			draw();
		});

		// The taxes of the time the visitor was away: a month for every five minutes, at most a year.
		if (saved.lastSeen) {
			const awayMonths = Math.min(12, Math.floor((Date.now() - saved.lastSeen) / 300_000));

			if (awayMonths > 0) {
				const taxes = awayMonths * monthlyTaxes();
				funds += taxes;
				month += awayMonths;
				headline(`While you were away, ${awayMonths} ${awayMonths === 1 ? 'month' : 'months'} went by in Sindreville, and the taxes brought in kr ${taxes}.`);
			}
		}

		if (!news.textContent) {
			news.textContent = isRaining ? 'Welcome, mayor! It is raining. Of course it is.' : 'Welcome, mayor! The sun is out. Nobody knows how long it will last.';
		}

		showTool();
		showStats();
		saveTown();
		draw();
	}
}
