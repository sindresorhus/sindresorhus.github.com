// Sindre’s RollerCoaster Tycoon: Fløyen Park, a game like RollerCoaster Tycoon (Chris Sawyer, 1999) on the 1999 page: the visitor builds a steel roller coaster piece by piece in a side view, tests it with real physics, gets the Excitement, Intensity, and Nausea ratings of the ride, and opens it to little pixel guests, who queue, pay, ride, scream, think, and sometimes throw up. The park is kept in the browser. The canvas runs only while it is on screen and the tab is visible. Nothing makes a sound until the visitor turns on the sound. For visitors who prefer reduced motion, the park moves one second for each press of the Step button.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomBetween = (minimum, maximum) => minimum + (Math.random() * (maximum - minimum));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Shows a toggle button as pressed, for screen readers and for the style.
const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));
	button.dataset.state = isPressed ? 'on' : '';
};

// The position of a pointer on a canvas, in the pixels of the canvas.
const canvasPoint = (canvas, event) => {
	const rectangle = canvas.getBoundingClientRect();
	return {
		x: (event.clientX - rectangle.left) * canvas.width / rectangle.width,
		y: (event.clientY - rectangle.top) * canvas.height / rectangle.height,
	};
};

// The track: a list of samples a quarter of a meter apart, made by a turtle that walks along the pieces and turns its pitch, heading, and roll. The world is in meters, with x to the right, y up, and z toward the visitor.
const sampleSpacing = 0.25;
const gravity = 9.81;
const stationStart = 8;
const stationLength = 18;
const stationHeight = 3;
const stationStop = 16.5;
const backDepth = -12;
const maximumHeight = 70;
const degrees = Math.PI / 180;

// The slopes of the game, from steep down to steep up. A piece can only change the slope by one step, like in the game.
const levelAngle = level => [-60, -25, 0, 25, 60][level + 2] * degrees;
const gentleRadius = 18;
const steepRadius = 15;
const bendRadius = (from, to) => (Math.abs(from) + Math.abs(to) === 1 ? gentleRadius : steepRadius);
const straightLength = level => (Math.abs(level) === 2 ? 4 : 5);

const pieceTypes = {
	steepDown: {level: -2, name: 'Steep slope down', cost: 500},
	down: {level: -1, name: 'Slope down', cost: 350},
	level: {level: 0, name: 'Level track', cost: 250},
	up: {level: 1, name: 'Slope up', cost: 350},
	steepUp: {level: 2, name: 'Steep slope up', cost: 500},
	loop: {name: 'Vertical loop', cost: 2500},
	corkscrew: {name: 'Corkscrew', cost: 3000},
	helix: {name: 'Helix', cost: 2200},
	turn: {name: 'Turn around', cost: 1200},
	brakes: {name: 'Brakes', cost: 600},
};

const chainCost = 150;

const add = (first, second) => ({x: first.x + second.x, y: first.y + second.y, z: first.z + second.z});
const subtract = (first, second) => ({x: first.x - second.x, y: first.y - second.y, z: first.z - second.z});
const scale = (vector, factor) => ({x: vector.x * factor, y: vector.y * factor, z: vector.z * factor});
const dot = (first, second) => (first.x * second.x) + (first.y * second.y) + (first.z * second.z);
const cross = (first, second) => ({
	x: (first.y * second.z) - (first.z * second.y),
	y: (first.z * second.x) - (first.x * second.z),
	z: (first.x * second.y) - (first.y * second.x),
});

const normalize = vector => {
	const length = Math.hypot(vector.x, vector.y, vector.z) || 1;
	return scale(vector, 1 / length);
};

// The forward and up directions of a car with a pitch, a heading, and a roll. Without roll, up is square to the track in its upright plane, so it turns over in a loop.
const frameOf = (pitch, heading, roll = 0) => {
	const forward = {x: Math.cos(pitch) * Math.cos(heading), y: Math.sin(pitch), z: Math.cos(pitch) * Math.sin(heading)};
	const flatUp = {x: -Math.sin(pitch) * Math.cos(heading), y: Math.cos(pitch), z: -Math.sin(pitch) * Math.sin(heading)};
	const side = cross(forward, flatUp);
	return {forward, up: add(scale(flatUp, Math.cos(roll)), scale(side, Math.sin(roll))), side};
};

const move = (turtle, samples, distance, next, flags, offset) => {
	const direction = frameOf((turtle.pitch + next.pitch) / 2, (turtle.heading + next.heading) / 2).forward;
	turtle.x += direction.x * distance;
	turtle.y += direction.y * distance;
	turtle.z += direction.z * distance;
	turtle.pitch = next.pitch;
	turtle.heading = next.heading;
	turtle.roll = next.roll ?? 0;
	samples.push({
		x: turtle.x + (offset?.x ?? 0),
		y: turtle.y + (offset?.y ?? 0),
		z: turtle.z + (offset?.z ?? 0),
		pitch: turtle.pitch,
		heading: turtle.heading,
		roll: turtle.roll,
		...flags,
	});
};

const straight = (turtle, samples, length, flags) => {
	const count = Math.max(1, Math.ceil(length / sampleSpacing));
	for (let index = 0; index < count; index++) {
		move(turtle, samples, length / count, {pitch: turtle.pitch, heading: turtle.heading}, flags);
	}
};

// A curve up or down to a new pitch, with a radius big enough that a fast train does not squash its riders.
const bend = (turtle, samples, pitch, radius, flags) => {
	const start = turtle.pitch;
	const length = Math.abs(pitch - start) * radius;
	const count = Math.max(1, Math.ceil(length / sampleSpacing));
	for (let index = 1; index <= count; index++) {
		move(turtle, samples, length / count, {pitch: start + ((pitch - start) * index / count), heading: turtle.heading}, flags);
	}
};

// A flat turn, banked toward its middle, for the slow way back to the station.
const turn = (turtle, samples, angle, radius, flags) => {
	const start = turtle.heading;
	const length = Math.abs(angle) * radius;
	const count = Math.max(1, Math.ceil(length / sampleSpacing));
	for (let index = 1; index <= count; index++) {
		const progress = index / count;
		const roll = Math.sign(angle) * 45 * degrees * Math.min(1, progress * 4, (1 - progress) * 4);
		move(turtle, samples, length / count, {pitch: turtle.pitch, heading: start + (angle * progress), roll}, {...flags, banked: true});
	}
};

const buildSlope = (turtle, samples, from, to, flags) => {
	if (from !== to) {
		bend(turtle, samples, levelAngle(to), bendRadius(from, to), flags);
	}

	straight(turtle, samples, straightLength(to), flags);
};

// A loop like the ones of the time, tighter at the top than at the bottom, so the riders are not squashed at the bottom or dropped at the top. It moves a little toward the visitor, so the track comes out next to where it went in.
const buildLoop = (turtle, samples, flags) => {
	const bottomRadius = 14;
	const topRadius = 6;
	const start = turtle.pitch;
	let angle = 0;
	while (angle < (Math.PI * 2) - 0.0001) {
		const radius = bottomRadius - ((bottomRadius - topRadius) * (1 - Math.cos(angle)) / 2);
		const step = Math.min(sampleSpacing / radius, (Math.PI * 2) - angle);
		angle += step;
		turtle.z += 2.5 * step / (Math.PI * 2);
		move(turtle, samples, radius * step, {pitch: start + angle, heading: turtle.heading}, {...flags, inverted: Math.cos(angle) < 0});
	}

	turtle.pitch = start;
	samples.at(-1).pitch = start;
};

// A corkscrew turns the train once around a line along the track, so the track winds around that line, and the riders are upside down at the top. The roll starts and ends slowly, so the track has no kink where the corkscrew starts and ends.
const buildCorkscrew = (turtle, samples, flags) => {
	const length = 40;
	const radius = 2.6;
	const count = Math.ceil(length / sampleSpacing);
	const {up, side} = frameOf(turtle.pitch, turtle.heading);
	for (let index = 1; index <= count; index++) {
		const progress = index / count;
		const roll = (Math.PI * 2 * progress) - Math.sin(Math.PI * 2 * progress);
		const rolledUp = add(scale(up, Math.cos(roll)), scale(side, Math.sin(roll)));
		move(turtle, samples, length / count, {pitch: turtle.pitch, heading: turtle.heading, roll}, {...flags, inverted: Math.cos(roll) < 0}, scale(subtract(up, rolledUp), radius));
	}

	turtle.roll = 0;
	samples.at(-1).roll = 0;
};

// A turn whose curve and banking grow together at its start and shrink together at its end, like real track, so the riders are not thrown sideways where it begins.
const curve = (turtle, samples, {angle, length, bank, ramp, dip = 0}, flags) => {
	const count = Math.ceil(length / sampleSpacing);
	const weight = progress => Math.min(1, progress / ramp, (1 - progress) / ramp);
	let total = 0;
	for (let index = 0; index < count; index++) {
		total += weight((index + 0.5) / count);
	}

	const start = turtle.heading;
	let heading = start;
	for (let index = 1; index <= count; index++) {
		const progress = index / count;
		heading += angle * weight((index - 0.5) / count) / total;
		move(turtle, samples, length / count, {pitch: -dip * Math.sin(Math.PI * progress), heading, roll: Math.sign(angle) * bank * weight(progress)}, {...flags, isTurn: true, banked: bank > 0});
	}

	turtle.heading = (start + angle) % (Math.PI * 2);
	turtle.pitch = 0;
	turtle.roll = 0;
	Object.assign(samples.at(-1), {heading: turtle.heading, pitch: 0, roll: 0});
};

// A helix turns once around while it goes down a bit. Without banking, a fast train flies off it.
const buildHelix = (turtle, samples, flags, isBanked) => {
	curve(turtle, samples, {angle: Math.PI * 2, length: Math.PI * 2 * 7 / 0.9, bank: isBanked ? 55 * degrees : 0, ramp: 0.1, dip: 8 * degrees}, flags);
};

// A banked turn around, so the track comes back along the front of the park, or goes back to the middle.
const buildTurnAround = (turtle, samples, flags) => {
	curve(turtle, samples, {angle: Math.PI, length: Math.PI * 8 / 0.8, bank: 60 * degrees, ramp: 0.2}, flags);
};

// The way up or down to the height of the station, along the back of the park: a gentle slope if there is room, or a steep one. It returns the horizontal room it needs, or undefined when it does not fit.
const planHeightChange = (change, room) => {
	const height = Math.abs(change);
	if (height < 0.05) {
		return {kind: 'none', room: 0};
	}

	const gentle = 25 * degrees;
	const gentleBends = 2 * gentleRadius * (1 - Math.cos(gentle));
	if (height <= gentleBends) {
		const angle = Math.acos(1 - (height / (2 * gentleRadius)));
		return {kind: 'gentle', angle, length: 0, room: 2 * gentleRadius * Math.sin(angle)};
	}

	const gentleLength = (height - gentleBends) / Math.sin(gentle);
	const gentlePlan = {kind: 'gentle', angle: gentle, length: gentleLength, room: (2 * gentleRadius * Math.sin(gentle)) + (gentleLength * Math.cos(gentle))};
	if (gentlePlan.room <= room) {
		return gentlePlan;
	}

	const steep = 60 * degrees;
	const steepBends = 2 * ((gentleRadius * (1 - Math.cos(gentle))) + (steepRadius * (Math.cos(gentle) - Math.cos(steep))));
	if (height >= steepBends) {
		const steepLength = (height - steepBends) / Math.sin(steep);
		const steepPlan = {kind: 'steep', length: steepLength, room: (2 * ((gentleRadius * Math.sin(gentle)) + (steepRadius * (Math.sin(steep) - Math.sin(gentle))))) + (steepLength * Math.cos(steep))};
		if (steepPlan.room <= room) {
			return steepPlan;
		}
	}

	return undefined;
};

// The way back to the station, which the park builds by itself: it levels out, brakes, turns around to the back of the park if the track runs to the right, goes up or down to the height of the station, and turns around again into the station. Drive tires keep the train moving on it.
const buildReturn = (turtle, samples, level) => {
	const flags = {piece: -2};
	for (let current = level; current !== 0; current -= Math.sign(current)) {
		bend(turtle, samples, levelAngle(current - Math.sign(current)), bendRadius(current, current - Math.sign(current)), flags);
	}

	turtle.pitch = 0;
	straight(turtle, samples, 14, {...flags, brake: true});
	const isRunningRight = Math.cos(turtle.heading) > 0;
	if (isRunningRight) {
		const radius = (turtle.z - backDepth) / 2;
		if (radius < 3) {
			return 'The track is too far back to turn around.';
		}

		turn(turtle, samples, -Math.PI, radius, flags);
	} else if (turtle.z < 6) {
		return 'The track is too close to the station to turn into it.';
	}

	const change = stationHeight - turtle.y;
	const room = turtle.x - stationStart - 2;
	const plan = planHeightChange(change, room);
	if (!plan || room < 0) {
		return change < 0 ? 'The end of the track is too high to get back down to the station. Come down first!' : 'The track is too short to get back to the station. Build further!';
	}

	const direction = Math.sign(change);
	const slopeFlags = {...flags, chain: direction > 0, tires: direction < 0};
	if (plan.kind === 'gentle') {
		bend(turtle, samples, direction * plan.angle, gentleRadius, slopeFlags);
		straight(turtle, samples, plan.length, slopeFlags);
		bend(turtle, samples, 0, gentleRadius, slopeFlags);
	} else if (plan.kind === 'steep') {
		bend(turtle, samples, direction * 25 * degrees, gentleRadius, slopeFlags);
		bend(turtle, samples, direction * 60 * degrees, steepRadius, slopeFlags);
		straight(turtle, samples, plan.length, slopeFlags);
		bend(turtle, samples, direction * 25 * degrees, steepRadius, slopeFlags);
		bend(turtle, samples, 0, gentleRadius, slopeFlags);
	}

	turtle.pitch = 0;
	const length = turtle.x - stationStart;
	straight(turtle, samples, Math.max(0, length - 10), {...flags, tires: true});
	straight(turtle, samples, Math.min(10, length), {...flags, tires: true, brake: true});
	turn(turtle, samples, isRunningRight ? -Math.PI : Math.PI, Math.abs(turtle.z) / 2, {...flags, tires: true});
	return undefined;
};

const addPiece = (turtle, samples, piece, index, level) => {
	const type = pieceTypes[piece.type];
	const flags = {piece: index, chain: Boolean(piece.chain)};
	if (type.level !== undefined) {
		buildSlope(turtle, samples, level, type.level, flags);
		return type.level;
	}

	if (piece.type === 'loop') {
		buildLoop(turtle, samples, flags);
	} else if (piece.type === 'corkscrew') {
		buildCorkscrew(turtle, samples, flags);
	} else if (piece.type === 'helix') {
		buildHelix(turtle, samples, flags, piece.banked !== false);
	} else if (piece.type === 'turn') {
		buildTurnAround(turtle, samples, flags);
	} else {
		straight(turtle, samples, 8, {...flags, brake: true});
	}

	return 0;
};

// The pieces that can go at the end of the track. A special piece needs level track, and a slope can only change by one step, like in the game.
const allowedPieces = level => Object.fromEntries(Object.entries(pieceTypes).map(([id, type]) => [id, type.level === undefined ? level === 0 : Math.abs(type.level - level) <= 1]));

// The chain lift goes on level track and slopes up.
const takesChain = id => (pieceTypes[id].level ?? -1) >= 0;

// Makes the samples into a track that a train can ride: the distance along it, and at each sample the forward, up, and side directions and how fast the forward direction turns, which gives the G-forces.
const finishTrack = (samples, isClosed) => {
	const count = samples.length;
	const at = index => samples[isClosed ? ((index % count) + count) % count : clamp(index, 0, count - 1)];
	let distance = 0;
	for (const [index, sample] of samples.entries()) {
		if (index > 0) {
			distance += Math.hypot(sample.x - samples[index - 1].x, sample.y - samples[index - 1].y, sample.z - samples[index - 1].z);
		}

		sample.s = distance;
	}

	const last = samples.at(-1);
	const length = isClosed ? distance + Math.hypot(samples[0].x - last.x, samples[0].y - last.y, samples[0].z - last.z) : distance;
	for (const [index, sample] of samples.entries()) {
		sample.forward = normalize(subtract(at(index + 2), at(index - 2)));
	}

	for (const [index, sample] of samples.entries()) {
		const span = 4 * sampleSpacing;
		sample.bend = scale(subtract(at(index + 2).forward, at(index - 2).forward), 1 / span);
		const up = frameOf(sample.pitch, sample.heading, sample.roll).up;
		sample.up = normalize(subtract(up, scale(sample.forward, dot(up, sample.forward))));
		sample.side = cross(sample.forward, sample.up);
	}

	return length;
};

// Whether a sample is so close to the samples from one index to another that the two tracks would go through each other.
const isTrackNear = (samples, sample, from, to) => {
	for (let index = from; index < to; index += 2) {
		const other = samples[index];
		if (Math.abs(other.x - sample.x) < 2.2 && Math.abs(other.y - sample.y) < 2.2 && Math.abs(other.z - sample.z) < 2.2) {
			return true;
		}
	}

	return false;
};

// Builds the whole circuit: the station, the pieces of the visitor, and the way back. It also says what is wrong with a piece, with the errors of the game.
const compileTrack = pieces => {
	const turtle = {x: stationStart, y: stationHeight, z: 0, pitch: 0, heading: 0, roll: 0};
	const samples = [{x: turtle.x, y: turtle.y, z: 0, pitch: 0, heading: 0, roll: 0, piece: -1, station: true}];
	straight(turtle, samples, stationLength, {piece: -1, station: true});
	const pieceStarts = [];
	let level = 0;
	for (const [index, piece] of pieces.entries()) {
		pieceStarts.push(samples.length);
		level = addPiece(turtle, samples, piece, index, level);
	}

	const end = {...turtle};
	const outEnd = samples.length;
	let returnError = buildReturn(turtle, samples, level);
	for (let index = outEnd; index < samples.length && !returnError; index++) {
		const sample = samples[index];
		if (sample.x - (sample.z * 0.35) > 155) {
			returnError = 'The way back to the station does not fit in the park. Turn around sooner!';
		} else if (sample.y < 0.5) {
			returnError = 'The way back to the station would go into the ground. Level out higher!';
		} else if (index % 2 === 0 && isTrackNear(samples, sample, pieceStarts[0] ?? outEnd, Math.min(outEnd, index - 40))) {
			returnError = 'The way back to the station would go through the track. Build on, or turn around!';
		}
	}

	const isClosed = !returnError;
	const length = finishTrack(samples, isClosed);
	return {samples, length, pieceStarts, outEnd, level, end, returnError, isClosed};
};

// What is wrong with the last piece of a track, like the errors of the game, or undefined.
const pieceError = track => {
	const start = track.pieceStarts.at(-1) ?? track.outEnd;
	for (let index = start; index < track.outEnd; index++) {
		const sample = track.samples[index];
		if (sample.y < 1) {
			return 'Can’t build this here… Ground in the way!';
		}

		if (sample.y > maximumHeight) {
			return 'Can’t build this here… Too high!';
		}

		const screenX = sample.x - (sample.z * 0.35);
		if (screenX > 150 || screenX < 1) {
			return 'Can’t build this here… Off edge of map!';
		}

		if (sample.x < stationStart + stationLength - 0.5 && sample.z < 4 && sample.y < 9) {
			return 'Can’t build this here… Station in the way!';
		}

		// The track cannot go through itself, but it can touch the piece before it.
		if (isTrackNear(track.samples, sample, 0, start - 40)) {
			return 'Can’t build this here… Track in the way!';
		}
	}

	return undefined;
};

// The index of the sample at a distance along the track.
const sampleIndexAt = (track, distance) => {
	const {samples, length} = track;
	const wrapped = track.isClosed ? ((distance % length) + length) % length : clamp(distance, 0, samples.at(-1).s);
	let low = 0;
	let high = samples.length - 1;
	while (low < high) {
		const middle = Math.ceil((low + high) / 2);
		if (samples[middle].s <= wrapped) {
			low = middle;
		} else {
			high = middle - 1;
		}
	}

	return low;
};

const sampleAt = (track, distance) => track.samples[sampleIndexAt(track, distance)];

// The point at a distance along the track, between two samples, so the train moves smoothly.
const pointAt = (track, distance) => {
	const index = sampleIndexAt(track, distance);
	const sample = track.samples[index];
	const next = track.samples[(index + 1) % track.samples.length];
	const {length} = track;
	const wrapped = track.isClosed ? ((distance % length) + length) % length : distance;
	const gap = (index + 1 === track.samples.length ? length : next.s) - sample.s;
	const fraction = gap > 0 ? clamp((wrapped - sample.s) / gap, 0, 1) : 0;
	return {
		x: sample.x + ((next.x - sample.x) * fraction),
		y: sample.y + ((next.y - sample.y) * fraction),
		z: sample.z + ((next.z - sample.z) * fraction),
		sample,
	};
};

// The train: four cars, two seats each. It is pulled by the chain, pushed by the drive tires, slowed by the brakes, by rolling, and by the air, and gravity does the rest.
const carCount = 4;
const carSpacing = 3.2;
const chainSpeed = 4.5;
const tireSpeed = 3.5;
const brakeSpeed = 7;

const newTrain = () => ({
	s: stationStop,
	speed: 0,
	phase: 'stopped',
	odometer: 0,
	reversals: 0,
	vertical: 1,
	lateral: 0,
	wasForward: false,
	time: 0,
	chainDistance: 0,
	stalled: 0,
});

// The G-forces at a sample for a speed: what the riders feel, along their up and to their side.
const forcesAt = (sample, speed) => {
	const felt = add(scale(sample.bend, speed * speed), {x: 0, y: gravity, z: 0});
	return {vertical: dot(felt, sample.up) / gravity, lateral: dot(felt, sample.side) / gravity};
};

// One small step of the train. It returns what happened: `arrived`, `rollback`, `stuck`, `derail`, `chain`, or undefined.
const stepTrain = (train, track, seconds) => {
	if (train.phase !== 'running') {
		return undefined;
	}

	let slope = 0;
	let isChain = false;
	let isTires = false;
	let isBrake = false;
	for (let car = 0; car < carCount; car++) {
		const sample = sampleAt(track, train.s - (car * carSpacing));
		slope += sample.forward.y;
		isChain ||= Boolean(sample.chain);
		isTires ||= Boolean(sample.tires) || (Boolean(sample.station) && train.odometer < stationLength);
		isBrake ||= Boolean(sample.brake);
	}

	slope /= carCount;
	const {speed} = train;
	const resistance = (0.02 * gravity) + (0.0005 * speed * speed);
	let next = speed - (gravity * slope * seconds) - (Math.sign(speed) * resistance * seconds);
	if (isChain && next < chainSpeed) {
		next = chainSpeed;
	}

	if (isTires && next < tireSpeed) {
		next = Math.min(tireSpeed, next + (6 * seconds));
	}

	if (isBrake && next > brakeSpeed) {
		next = Math.max(brakeSpeed, next - (14 * seconds));
	}

	// The station brakes stop the train at the platform after a lap.
	const front = ((train.s % track.length) + track.length) % track.length;
	const isHome = train.odometer > track.length / 2 && front < stationStop + 0.5;
	if (isHome) {
		const left = stationStop - front;
		next = Math.max(0.5, Math.min(next, Math.sqrt(2 * 2.5 * Math.max(left, 0)) + 0.4));
	}

	train.speed = next;
	train.s += next * seconds;
	train.odometer += next * seconds;
	train.time += seconds;
	if (isChain) {
		train.chainDistance += Math.abs(next * seconds);
	}

	// The G-forces are smoothed a little, like the ones the game shows.
	const forces = forcesAt(sampleAt(track, train.s - (carSpacing * 1.5)), next);
	const smoothing = Math.min(1, seconds / 0.08);
	train.vertical += (forces.vertical - train.vertical) * smoothing;
	train.lateral += (forces.lateral - train.lateral) * smoothing;

	if (isHome && train.odometer >= track.length - 0.02) {
		train.s = stationStop;
		train.speed = 0;
		train.phase = 'stopped';
		return 'arrived';
	}

	// Once the train went over the track end where a piece was demolished, it flies off.
	if (train.cut !== undefined && (((train.s % track.length) + track.length) % track.length) >= train.cut && train.odometer > 0) {
		return 'derail';
	}

	for (let car = 0; car < carCount; car++) {
		const sample = sampleAt(track, train.s - (car * carSpacing));
		if (sample.isTurn && !sample.banked && Math.abs(forcesAt(sample, next).lateral) > 2.2) {
			return 'derail';
		}
	}

	// A train that rolls to a halt on level track is stuck too.
	train.stalled = !isChain && !isTires && !isHome && Math.abs(next) < 0.05 ? train.stalled + seconds : 0;
	if (train.stalled > 2) {
		return 'stuck';
	}

	if (next > 0.05) {
		train.wasForward = true;
	} else if (next < -0.05 && train.wasForward) {
		train.wasForward = false;
		train.reversals++;
		return train.reversals >= 2 ? 'stuck' : 'rollback';
	}

	if (isChain && train.chainDistance > 0.75) {
		train.chainDistance = 0;
		return 'chain';
	}

	return undefined;
};

const physicsStep = 1 / 120;

// The words of the ratings of the game.
const ratingWord = value => {
	if (value < 2.5) {
		return 'Low';
	}

	if (value < 5.5) {
		return 'Medium';
	}

	if (value < 6.5) {
		return 'High';
	}

	if (value < 7.5) {
		return 'Very High';
	}

	if (value < 9.5) {
		return 'Extreme';
	}

	return 'Ultra-Extreme';
};

// The drops of the track: each run down of more than 3 meters, with its height.
const dropsOf = track => {
	const drops = [];
	let top = track.samples[0].y;
	let bottom = top;
	for (const sample of track.samples) {
		if (sample.y > bottom + 1.5) {
			if (top - bottom > 3) {
				drops.push(top - bottom);
			}

			top = sample.y;
			bottom = sample.y;
		}

		top = Math.max(top, sample.y);
		bottom = Math.min(bottom, sample.y);
		if (sample.y > top - 0.01) {
			bottom = sample.y;
		}
	}

	if (top - bottom > 3) {
		drops.push(top - bottom);
	}

	return drops;
};

// A test run without riders, all at once: it says how the ride went and what the game would rate it.
const testRun = (track, pieces) => {
	const train = newTrain();
	train.phase = 'running';
	const series = [];
	const speeds = new Float32Array(Math.ceil(track.samples.length / 16));
	let nextRecord = 0;
	let result;
	let airtime = 0;
	let maximumSpeed = 0;
	let maximumVertical = 0;
	let minimumVertical = 1;
	let maximumLateral = 0;
	let rollbackAt;
	while (train.time < 400 && !result) {
		const event = stepTrain(train, track, physicsStep);
		const index = sampleIndexAt(track, train.s);
		speeds[Math.floor(index / 16)] = Math.max(speeds[Math.floor(index / 16)], Math.abs(train.speed));
		maximumSpeed = Math.max(maximumSpeed, Math.abs(train.speed));
		maximumVertical = Math.max(maximumVertical, train.vertical);
		minimumVertical = Math.min(minimumVertical, train.vertical);
		maximumLateral = Math.max(maximumLateral, Math.abs(train.lateral));
		if (train.vertical < 0) {
			airtime += physicsStep;
		}

		if (train.time >= nextRecord) {
			nextRecord += 0.2;
			series.push([Math.round(train.time * 10) / 10, Math.round(Math.abs(train.speed) * 36) / 10, Math.round(pointAt(track, train.s).y * 10) / 10, Math.round(train.vertical * 100) / 100, Math.round(train.lateral * 100) / 100]);
		}

		if (event === 'rollback') {
			rollbackAt ??= track.samples[index];
		} else if (event === 'arrived' || event === 'stuck' || event === 'derail') {
			result = event;
		}
	}

	result ??= 'stuck';
	const drops = dropsOf(track);
	const inversions = pieces.filter(piece => piece.type === 'loop' || piece.type === 'corkscrew').length;
	const helices = pieces.filter(piece => piece.type === 'helix').length;
	const stats = {
		result,
		maximumSpeed,
		averageSpeed: train.odometer / Math.max(train.time, 1),
		time: train.time,
		length: track.length,
		maximumVertical,
		minimumVertical,
		maximumLateral,
		drops: drops.length,
		highestDrop: Math.max(0, ...drops),
		inversions,
		airtime,
		rollback: Boolean(rollbackAt),
		where: rollbackAt ? Math.round(rollbackAt.x) : Math.round(pointAt(track, train.s).x),
	};

	// The ratings are made like the ones of the game: speed, drops, inversions, and airtime make a ride exciting, and strong G-forces make it intense. Turning and going upside down make the riders sick. A ride that is far too intense is not much fun.
	const intensity = 0.3 + (Math.max(0, maximumVertical - 1) * 0.7) + (Math.max(0, -minimumVertical) * 1.2) + (maximumLateral * 0.9) + (maximumSpeed * 0.04) + (inversions * 0.4) + (Math.min(drops.length, 8) * 0.1);
	let excitement = 0.3 + (Math.min(drops.length, 8) * 0.3) + (Math.min(stats.highestDrop, 60) * 0.045) + (maximumSpeed * 0.06) + (inversions * 0.65) + (Math.min(airtime, 4) * 0.35) + (Math.min(track.length, 900) / 450) + (helices * 0.45) + (Math.min(maximumLateral, 1.5) * 0.3);
	if (intensity > 10) {
		excitement *= 0.55;
	} else if (intensity > 8.5) {
		excitement *= 0.85;
	}

	const nausea = 0.2 + (maximumLateral * 0.9) + (inversions * 0.75) + (Math.max(0, -minimumVertical) * 0.9) + (helices * 0.9) + (Math.max(0, maximumVertical - 3) * 0.6);
	const isGood = result === 'arrived';
	return {
		stats,
		ratings: isGood ? {excitement: Math.round(excitement * 100) / 100, intensity: Math.round(intensity * 100) / 100, nausea: Math.round(nausea * 100) / 100} : undefined,
		series,
		speeds: [...speeds].map(speed => Math.round(speed * 3.6)),
	};
};

// Pappa built this one, so the park has a ride from the start: a chain lift, a big drop, a loop, a turn around to the front, an airtime hill, a helix, and a corkscrew.
const pappasDesign = [
	{type: 'up', chain: true},
	{type: 'steepUp', chain: true},
	{type: 'up', chain: true},
	{type: 'level', chain: true},
	{type: 'down'},
	{type: 'steepDown'},
	{type: 'down'},
	{type: 'level'},
	{type: 'loop'},
	{type: 'turn'},
	{type: 'up'},
	{type: 'level'},
	{type: 'helix', banked: true},
	{type: 'level'},
	{type: 'corkscrew'},
	{type: 'brakes'},
];

const startMoney = 20_000;
const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

const colorSchemes = {
	red: {track: '#d42020', rail: '#ff6060', supports: '#e8e8e8', train: '#2050d0', trim: '#ffd800'},
	blue: {track: '#2040c0', rail: '#6080ff', supports: '#f0d020', train: '#d02020', trim: '#ffffff'},
	green: {track: '#209030', rail: '#60d060', supports: '#a0a0a0', train: '#f08000', trim: '#ffffff'},
	glitter: {track: '#e040a0', rail: '#ff90d0', supports: '#a060e0', train: '#ffffff', trim: '#ff60c0'},
	black: {track: '#202020', rail: '#606060', supports: '#ff8000', train: '#ff8000', trim: '#202020'},
};

const storedNumber = (value, fallback, minimum, maximum) => (Number.isFinite(value) ? clamp(Math.round(value), minimum, maximum) : fallback);

const kroner = amount => `${Math.round(amount).toLocaleString('nb-NO')} kr`;

// The screen: a side view of the park, 4 pixels to the meter. Things further back are drawn a little higher and to the right, like the side views of the time.
const pixelsPerMeter = 4;
const groundLine = 318;
const queueLane = 340;
const walkLane = 349;
const queueStart = 126;
const queueSpacing = 7;
const queueLength = 16;
const decisionPoint = queueStart + (queueSpacing * queueLength) + 14;
const exitStairs = 40;
const gate = 632;

const project = (x, y, z) => ({x: 12 + ((x - (z * 0.35)) * pixelsPerMeter), y: groundLine - (y * pixelsPerMeter) + (z * 0.8)});
const projectVector = vector => project(vector.x, vector.y, vector.z);

// The guests: little pixel people of Bergen, each with how intense a ride they like, how strong their stomach is, and how much they will pay.
const guestNames = ['Kari', 'Ola', 'Ingrid', 'Lars', 'Silje', 'Anders', 'Marit', 'Per', 'Hanne', 'Knut', 'Siri', 'Bjørn', 'Liv', 'Even', 'Tone', 'Geir', 'Mona', 'Jon', 'Randi', 'Espen', 'Nina', 'Øyvind', 'Åse', 'Kjetil'];
const surnameLetters = 'ABDEFGHJKLMNOPRSTV';
const shirts = ['#e02020', '#2060e0', '#20a040', '#f0c000', '#a030c0', '#ff8000', '#00a0b0', '#ffffff', '#ff60b0'];

// A few guests are people I know, with their own taste in rides.
const specialGuests = [
	{name: 'Mormor', shirt: '#8040a0', minimumIntensity: 0, maximumIntensity: 2.5, tolerance: 2, thrift: 2, isMormor: true},
	{name: 'Trond', shirt: '#20a040', minimumIntensity: 3, maximumIntensity: 12, tolerance: 9, thrift: 1.5, isTrond: true},
	{name: 'Lillesøster', shirt: '#ff60b0', minimumIntensity: 0, maximumIntensity: 5, tolerance: 4, thrift: 1},
	{name: 'Mamma', shirt: '#c02060', minimumIntensity: 1, maximumIntensity: 6.5, tolerance: 4.5, thrift: 0.9},
	{name: 'Pappa', shirt: '#2050a0', minimumIntensity: 2, maximumIntensity: 9, tolerance: 6, thrift: 0.7},
];

// The drawing. The sky, Fløyen, and the path are drawn once, and the track whenever it changes, so each frame only draws what moves.
const makeLayer = canvas => {
	const layer = document.createElement('canvas');
	layer.width = canvas.width;
	layer.height = canvas.height;
	return layer;
};

const drawLine = (paint, from, to) => {
	paint.beginPath();
	paint.moveTo(from.x, from.y);
	paint.lineTo(to.x, to.y);
	paint.stroke();
};

// The windows of the game: construction, ride, and park.
const fallbackPieces = ['level', 'up', 'down', 'steepUp', 'steepDown'];

const addRow = (list, term, value) => {
	const termElement = document.createElement('dt');
	termElement.textContent = term;
	const valueElement = document.createElement('dd');
	valueElement.textContent = value;
	list.append(termElement, valueElement);
};

// Only what the visitor paid for gives money back, so Pappa’s free design is not a money machine.
const refundOf = piece => (piece.isPaid ? Math.round((pieceTypes[piece.type].cost + (piece.chain ? chainCost : 0)) * 0.75) : 0);

const pappaSays = [
	'Pappa says: “Ok, but you pay me back in waffles with brunost.”',
	'Pappa sighs: “Penger vokser ikke på trær!” That means money does not grow on trees.',
	'Pappa says: “This is the last time. Next time, ask Mormor.”',
];

export default class extends GeoCitiesElement {
	#park;
	#track;
	#trainTrack;
	// The last test run of the track: its stats, ratings, graphs, and speeds.
	#lastRun;
	#train = newTrain();
	#rideStatus = 'closed';
	#pendingRun;
	#isTesting = false;
	#openAfterTest = false;
	#wreck;
	#selectedPiece = 'up';
	#isChain = true;
	#isBanked = true;
	#isCamera = false;
	#isShowingSpeeds = false;
	#isPaused = false;
	#isRaining = false;
	#rainTimer = 40;
	#clock = 0;
	#monthTimer = 0;
	#monthIncome = 0;
	#spawnTimer = 1;
	#loadTimer = 0;
	#dispatchTimer = 0;
	#screamCooldown = 0;
	#selectedGuest;
	#nextGuestNumber = 1;
	#clearArmed = false;
	#clearTimer;
	// The next piece, as a flashing ghost, like in the construction mode of the game. It is red where it cannot go.
	#ghost;
	#context;
	#graphContext;
	#sceneryLayer;
	#trackLayer;
	#statusButtons;
	#pieceButtons;
	#loop;
	#guests = [];
	#puddles = [];
	#handymen = [];
	#particles = [];

	// The sounds, made with tones and noise once the visitor turns them on: the chain lift, the wheels, the screams, the cash register, the bulldozer, and the crash.
	#audio = {
		context: undefined,
		output: undefined,
		noise: undefined,
		rumble: undefined,
		isOn: false,
		// The audio of the element, which it only has in the handler of a click.
		start(sound) {
			if (!sound) {
				return false;
			}

			this.context = sound.context;
			this.output = sound.output;
			this.context.resume();
			if (!this.noise) {
				this.noise = new AudioBuffer({length: this.context.sampleRate, sampleRate: this.context.sampleRate});
				const data = this.noise.getChannelData(0);
				for (let index = 0; index < data.length; index++) {
					data[index] = (Math.random() * 2) - 1;
				}

				const source = new AudioBufferSourceNode(this.context, {buffer: this.noise, loop: true});
				const filter = new BiquadFilterNode(this.context, {type: 'lowpass', frequency: 260});
				this.rumble = new GainNode(this.context, {gain: 0});
				source.connect(filter).connect(this.rumble).connect(this.output);
				source.start();
			}

			return true;
		},
		get isReady() {
			return this.isOn && this.context?.state === 'running';
		},
		tone(frequency, duration, {type = 'square', volume = 0.05, when = 0, slideTo} = {}) {
			if (!this.isReady) {
				return;
			}

			const start = this.context.currentTime + when;
			const oscillator = new OscillatorNode(this.context, {type, frequency});
			if (slideTo) {
				oscillator.frequency.exponentialRampToValueAtTime(slideTo, start + duration);
			}

			const gain = new GainNode(this.context, {gain: 0});
			gain.gain.setValueAtTime(0, start);
			gain.gain.linearRampToValueAtTime(volume, start + 0.01);
			gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
			oscillator.connect(gain).connect(this.output);
			oscillator.start(start);
			oscillator.stop(start + duration + 0.05);
		},
		hiss(duration, {volume = 0.1, frequency = 1500, type = 'bandpass', when = 0, slideTo} = {}) {
			if (!this.isReady) {
				return;
			}

			const start = this.context.currentTime + when;
			const source = new AudioBufferSourceNode(this.context, {buffer: this.noise});
			const filter = new BiquadFilterNode(this.context, {type, frequency, Q: 1.2});
			if (slideTo) {
				filter.frequency.exponentialRampToValueAtTime(slideTo, start + duration);
			}

			const gain = new GainNode(this.context, {gain: 0});
			gain.gain.setValueAtTime(0, start);
			gain.gain.linearRampToValueAtTime(volume, start + 0.01);
			gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
			source.connect(filter).connect(gain).connect(this.output);
			source.start(start, Math.random() * 0.5);
			source.stop(start + duration + 0.05);
		},
		clack() {
			this.hiss(0.025, {volume: 0.25, frequency: 2200});
			this.tone(160, 0.03, {volume: 0.04});
		},
		// A scream: a few voices that slide down, with a wobble, through the shape of an open mouth.
		scream() {
			if (!this.isReady) {
				return;
			}

			const start = this.context.currentTime;
			for (let voice = 0; voice < 3; voice++) {
				const pitch = randomBetween(520, 980);
				const oscillator = new OscillatorNode(this.context, {type: 'sawtooth', frequency: pitch});
				oscillator.frequency.linearRampToValueAtTime(pitch * 0.72, start + 1);
				const wobble = new OscillatorNode(this.context, {frequency: randomBetween(5, 8)});
				const wobbleDepth = new GainNode(this.context, {gain: pitch * 0.04});
				wobble.connect(wobbleDepth).connect(oscillator.frequency);
				const mouth = new BiquadFilterNode(this.context, {type: 'bandpass', frequency: 1100, Q: 2});
				const gain = new GainNode(this.context, {gain: 0});
				const delay = voice * 0.06;
				gain.gain.setValueAtTime(0, start + delay);
				gain.gain.linearRampToValueAtTime(0.05, start + delay + 0.08);
				gain.gain.linearRampToValueAtTime(0.035, start + delay + 0.7);
				gain.gain.exponentialRampToValueAtTime(0.0001, start + delay + 1.05);
				oscillator.connect(mouth).connect(gain).connect(this.output);
				oscillator.start(start + delay);
				wobble.start(start + delay);
				oscillator.stop(start + delay + 1.1);
				wobble.stop(start + delay + 1.1);
			}
		},
		cash() {
			this.tone(1568, 0.07, {volume: 0.05});
			this.tone(2093, 0.3, {type: 'triangle', volume: 0.07, when: 0.07});
			this.hiss(0.05, {volume: 0.12, frequency: 4000, when: 0.07});
		},
		build() {
			this.tone(150, 0.12, {type: 'triangle', volume: 0.12, slideTo: 70});
			this.hiss(0.06, {volume: 0.15, frequency: 800});
		},
		bulldozer() {
			this.hiss(0.5, {volume: 0.2, frequency: 300, type: 'lowpass'});
			this.tone(55, 0.5, {volume: 0.06});
		},
		crash() {
			this.hiss(1.4, {volume: 0.4, frequency: 3000, type: 'lowpass', slideTo: 150});
			this.tone(80, 0.9, {type: 'sine', volume: 0.3, slideTo: 30});
			this.tone(300, 0.2, {type: 'square', volume: 0.05, when: 0.05, slideTo: 90});
		},
		vomit() {
			this.tone(210, 0.5, {type: 'sawtooth', volume: 0.04, slideTo: 70});
			this.hiss(0.4, {volume: 0.08, frequency: 500, when: 0.1});
		},
		whistle() {
			this.tone(1800, 0.15, {type: 'sine', volume: 0.05});
			this.tone(1800, 0.3, {type: 'sine', volume: 0.05, when: 0.2});
		},
		setRumble(speed) {
			if (!this.rumble || !this.context) {
				return;
			}

			const volume = this.isReady ? Math.min(0.12, Math.abs(speed) / 160) : 0;
			this.rumble.gain.setTargetAtTime(volume, this.context.currentTime, 0.1);
		},
	};

	connected() {
		const {canvas, graph} = this.parts;
		this.#context = canvas.getContext('2d');
		this.#graphContext = graph.getContext('2d');
		this.#sceneryLayer = makeLayer(canvas);
		this.#trackLayer = makeLayer(canvas);
		this.#statusButtons = new Map([...this.querySelectorAll('[data-coaster-status]')].map(button => [button.dataset.coasterStatus, button]));
		this.#pieceButtons = new Map([...this.querySelectorAll('[data-coaster-piece]')].map(button => [button.dataset.coasterPiece, button]));

		// The saved park is checked field by field, as it can be broken. The results of the test run are not saved, as the run gives the same results again.
		const stored = this.stored('park', {});
		const hasStoredPieces = Array.isArray(stored.pieces) && stored.pieces.every(piece => Object.hasOwn(pieceTypes, piece?.type));
		this.#park = {
			pieces: hasStoredPieces ? stored.pieces : structuredClone(pappasDesign),
			name: typeof stored.name === 'string' ? stored.name.slice(0, 24) : 'Roller Coaster 1',
			price: storedNumber(stored.price, 30, 0, 200),
			money: storedNumber(stored.money, startMoney, -Infinity, Infinity),
			colors: Object.hasOwn(colorSchemes, stored.colors) ? stored.colors : 'red',
			handymen: storedNumber(stored.handymen, 0, 0, 4),
			loans: storedNumber(stored.loans, 0, 0, 3),
			month: storedNumber(stored.month, 2, 0, Infinity),
			riders: storedNumber(stored.riders, 0, 0, Infinity),
			// Pappa tested his design before the visitor came, so a new park can open at once.
			isTested: !hasStoredPieces || stored.isTested === true,
		};

		this.#track = compileTrack(this.#park.pieces);
		this.#trainTrack = this.#track;
		this.#lastRun = this.#park.isTested && this.#track.isClosed ? testRun(this.#track, this.#park.pieces) : undefined;
		this.#isShowingSpeeds = this.reducedMotion;

		for (const [id, button] of this.#pieceButtons) {
			this.on(button, 'click', () => {
				this.#selectedPiece = id;
				this.#refresh();
			});
		}

		this.on(this.parts.chain, 'click', () => {
			this.#isChain = !this.#isChain;
			this.#refresh();
		});

		this.on(this.parts.banked, 'click', () => {
			this.#isBanked = !this.#isBanked;
			this.#refresh();
		});

		this.on(this.parts.build, 'click', () => {
			this.#build();
		});

		this.on(this.parts.demolish, 'click', () => {
			this.#demolish();
		});

		this.on(this.parts.clear, 'click', () => {
			if (this.#isTrainBusy()) {
				this.say('Wait until the train is back in the station!');
				return;
			}

			// The second click has to come soon, so a forgotten first click cannot demolish the track later.
			if (!this.#clearArmed) {
				this.#clearArmed = true;
				this.#clearTimer = setTimeout(() => {
					this.#clearArmed = false;
					this.#refresh();
				}, 4000);
				this.#refresh();
				return;
			}

			this.#clearArmed = false;
			clearTimeout(this.#clearTimer);
			this.#closeForConstruction();
			let refund = 0;
			for (const piece of this.#park.pieces) {
				refund += refundOf(piece);
			}

			this.#park.pieces = [];
			this.#park.money += refund;
			this.#audio.bulldozer();
			this.#rebuild();
			this.say(`The whole track is gone${refund > 0 ? `, and you got ${kroner(refund)} back` : ''}. Only the station is left. Start with a chain lift up!`);
		});

		this.on(this.parts.preset, 'click', () => {
			if (this.#isTrainBusy()) {
				this.say('Wait until the train is back in the station!');
				return;
			}

			this.#closeForConstruction();
			this.#park.pieces = structuredClone(pappasDesign);
			this.#rebuild();
			this.say('Pappa built his design again, for free. He says it is the best one, and that you should test it.');
		});

		for (const [id, button] of this.#statusButtons) {
			this.on(button, 'click', () => {
				if (id === 'closed') {
					this.#closeRide();
				} else if (id === 'test') {
					this.#openAfterTest = false;
					this.#startTest();
				} else {
					this.#openRide();
				}

				this.#refresh();
			});
		}

		this.on(this.parts.camera, 'click', () => {
			this.#isCamera = !this.#isCamera;
			setPressed(this.parts.camera, this.#isCamera);
			this.say(this.#isCamera ? 'The ride camera is on. It sits in the front car.' : 'The ride camera is off.');
			this.#refresh();
		});

		this.on(this.parts.speeds, 'click', () => {
			this.#isShowingSpeeds = !this.#isShowingSpeeds;
			setPressed(this.parts.speeds, this.#isShowingSpeeds);
			if (this.#isShowingSpeeds && !this.#lastRun) {
				this.say('Test the ride first, to know its speeds.');
			}

			this.#refresh();
		});

		this.on(this.parts.pause, 'click', () => {
			this.#isPaused = !this.#isPaused;
			setPressed(this.parts.pause, this.#isPaused);
			if (this.#isPaused) {
				this.#audio.setRumble(0);
			}

			this.say(this.#isPaused ? 'Paused. The Step button moves the park on by one second.' : 'Going on.');
			this.#loop.start();
		});

		this.on(this.parts.step, 'click', () => {
			this.#stepOnce();
		});

		this.on(this.parts.sound, 'click', () => {
			this.#audio.isOn = !this.#audio.isOn && this.#audio.start(this.sound());
			if (!this.#audio.isOn) {
				this.#audio.setRumble(0);
			}

			setPressed(this.parts.sound, this.#audio.isOn);
			this.parts.sound.textContent = this.#audio.isOn ? '🔊 Sound' : '🔈 Sound';
			this.#audio.whistle();
		});

		this.on(this.parts.name, 'input', () => {
			this.#park.name = this.parts.name.value;
			this.#drawTrackLayer();
			this.#keep();
			this.#refresh();
		});

		for (const [button, change] of [[this.parts.priceDown, -5], [this.parts.priceUp, 5]]) {
			this.on(button, 'click', () => {
				this.#park.price = clamp(this.#park.price + change, 0, 200);
				this.#keep();
				this.#showPark();
				this.say(`The ticket for ${this.#rideName()} costs ${kroner(this.#park.price)}.${this.#park.price === 0 ? ' Free rides for everyone!' : ''}`);
			});
		}

		this.on(this.parts.graphKind, 'change', () => {
			this.#drawGraph();
		});

		this.on(this.parts.colors, 'change', () => {
			this.#park.colors = this.parts.colors.value;
			this.#drawTrackLayer();
			this.#keep();
			this.#refresh();
		});

		this.on(this.parts.handyman, 'click', () => {
			if (this.#park.handymen >= 4) {
				this.say('Four handymen are enough for one path!');
				return;
			}

			if (this.#park.money < 500) {
				this.say('Not enough cash: requires 500 kr.');
				return;
			}

			this.#park.money -= 500;
			this.#park.handymen++;
			this.#keep();
			this.say(`You hired a handyman. He walks in through the gate with his broom, and gets ${kroner(200)} a month.`);
			this.#refresh();
		});

		this.on(this.parts.loan, 'click', () => {
			if (this.#park.loans >= 3) {
				return;
			}

			this.#park.money += 5000;
			this.say(pappaSays[this.#park.loans]);
			this.#park.loans++;
			this.#audio.cash();
			this.#keep();
			this.#refresh();
		});

		this.on(canvas, 'click', event => {
			if (this.#isCamera) {
				return;
			}

			const point = canvasPoint(canvas, event);
			const candidates = this.#guests.filter(guest => guest.state !== 'riding' && guest.state !== 'floating');
			let best;
			// The guests are tiny on a phone, so a finger may land a bit beside them: the reach is at least 22 CSS pixels at any size of the canvas.
			let bestDistance = 22 * Math.max(1, canvas.width / canvas.clientWidth);
			for (const guest of candidates) {
				const distance = Math.hypot(guest.x - point.x, guest.lane - 5 - point.y);
				if (distance < bestDistance) {
					best = guest;
					bestDistance = distance;
				}
			}

			if (best) {
				this.#pickGuest(best);
			}
		});

		this.on(canvas, 'keydown', event => {
			if (event.ctrlKey || event.altKey || event.metaKey) {
				return;
			}

			const key = event.key.toLowerCase();
			const actions = {
				b: () => this.#build(),
				backspace: () => this.#demolish(),
				delete: () => this.#demolish(),
				t: () => this.#statusButtons.get('test').click(),
				o: () => this.#statusButtons.get('open').click(),
				x: () => this.#statusButtons.get('closed').click(),
				c: () => this.parts.camera.click(),
				g: () => {
					const candidates = this.#guests.filter(guest => guest.state !== 'riding' && guest.state !== 'floating');
					this.#pickGuest(candidates[(candidates.indexOf(this.#selectedGuest) + 1) % candidates.length]);
				},
				' ': () => (this.#isPaused || this.reducedMotion ? this.#stepOnce() : this.parts.pause.click()),
			};
			if (actions[key] && !event.repeat) {
				event.preventDefault();
				actions[key]();
			}
		});

		this.#loop = this.loop(seconds => {
			if (!this.#isPaused) {
				this.#update(seconds);
			}

			this.#draw();
			if (Math.floor(this.#clock * 2) !== Math.floor((this.#clock - seconds) * 2)) {
				this.#showPark();
			}
		}, {
			while: () => !this.reducedMotion,
			// The rumble of the wheels stops when the park is scrolled away or the tab is hidden.
			stopped: () => {
				this.#audio.setRumble(0);
			},
		});

		// A few guests are in the park already when the visitor comes.
		for (let index = 0; index < 7; index++) {
			const guest = this.#makeGuest();
			guest.x = randomBetween(decisionPoint + 20, gate - 20);
			guest.step = Math.random() * 4;
			this.#guests.push(guest);
		}

		this.parts.name.value = this.#park.name;
		this.parts.colors.value = this.#park.colors;
		this.#showStatus();
		this.#drawScenery();
		this.#drawTrackLayer();
		this.#showRide();
		this.#drawGraph();
		this.#refresh();
		this.#applyMotion();
	}

	// The game runs only while the park is on screen, and not while only the windows below it are.
	get visibilityTarget() {
		return this.parts.canvas;
	}

	reducedMotionChanged() {
		this.#applyMotion();
	}

	// The control that takes the place of the one that got disabled while it had the focus: Build for the bulldozer when the last piece is gone, the handyman for the loan when Pappa says no more, and Step for Pause when the visitor prefers reduced motion.
	focusReplacement(control) {
		const {demolish, build, loan, handyman, pause, step} = this.parts;
		if (control === demolish) {
			return build;
		}

		if (control === loan) {
			return handyman;
		}

		if (control === pause) {
			return step;
		}

		return super.focusReplacement(control);
	}

	#keep() {
		this.store('park', this.#park);
	}

	#scheme() {
		return colorSchemes[this.#park.colors];
	}

	// The thoughts of the guests, newest first, like the thoughts tab of the park window of the game.
	#think(guest, text, seconds = 4) {
		guest.thought = text;
		guest.thoughtUntil = this.#clock + seconds;
		const item = document.createElement('li');
		item.textContent = `${guest.name}: “${text}”`;
		this.parts.thoughts.prepend(item);
		while (this.parts.thoughts.children.length > 8) {
			this.parts.thoughts.lastElementChild.remove();
		}
	}

	#rideName() {
		return this.#park.name.trim() || 'Roller Coaster 1';
	}

	#makeGuest() {
		const number = this.#nextGuestNumber++;
		const special = number % 9 === 4 ? specialGuests.find(guest => !this.#guests.some(other => other.name === guest.name)) : undefined;
		return {
			name: `${randomItem(guestNames)} ${surnameLetters[Math.floor(Math.random() * surnameLetters.length)]}.`,
			shirt: randomItem(shirts),
			minimumIntensity: randomBetween(0, 4.5),
			maximumIntensity: randomBetween(5, 11),
			tolerance: randomBetween(3, 8),
			thrift: randomBetween(0.8, 1.6),
			...special,
			x: gate + 6,
			lane: walkLane,
			direction: -1,
			speed: randomBetween(14, 22),
			state: 'arriving',
			thought: undefined,
			thoughtUntil: 0,
			step: Math.random(),
			waited: 0,
			rides: 0,
		};
	}

	// What a guest would pay for a ride, from its ratings, like the value of a ride in the game.
	#rideValue() {
		const ratings = this.#lastRun?.ratings;
		return ratings ? Math.max(0, Math.round(8 + (ratings.excitement * 9) - (Math.max(0, ratings.intensity - 8) * 5))) : 0;
	}

	#queue() {
		return this.#guests.filter(guest => guest.state === 'queue' || guest.state === 'toQueue');
	}

	// A guest who walks past the queue line decides whether to ride, like in the game.
	#decide(guest) {
		const name = this.#rideName();
		if (guest.isMormor) {
			this.#think(guest, this.#rideStatus === 'open' ? `Uff da! ${name} looks far too wild for me. I’ll have a waffle instead.` : 'What a nice day for a walk, even in the rain.');
			return false;
		}

		if (this.#rideStatus !== 'open' || !this.#lastRun?.ratings) {
			if (Math.random() < 0.5) {
				this.#think(guest, 'I want to go on something more thrilling than the merry-go-round');
			}

			return false;
		}

		const {excitement, intensity, nausea} = this.#lastRun.ratings;
		if (this.#queue().length >= queueLength) {
			this.#think(guest, `The queue for ${name} is too long`);
			return false;
		}

		if (intensity > guest.maximumIntensity) {
			this.#think(guest, randomItem([`${name} looks too intense for me!`, 'This ride is too intense for me!']));
			return false;
		}

		if (intensity < guest.minimumIntensity) {
			this.#think(guest, `I want to go on something more thrilling than ${name}`);
			return false;
		}

		if (nausea > guest.tolerance + 3) {
			this.#think(guest, `Just looking at ${name} makes me feel sick!`);
			return false;
		}

		if (this.#park.price > this.#rideValue() * guest.thrift) {
			this.#think(guest, `I’m not paying that much to go on ${name}`);
			return false;
		}

		guest.ticket = this.#park.price;
		if (this.#park.price <= this.#rideValue() * 0.4) {
			this.#think(guest, `${name} is really good value!`);
		} else if (guest.isTrond) {
			this.#think(guest, `Kult! ${name}! Sindre, I’m first in the queue!`);
		} else if (excitement > 6 && Math.random() < 0.4) {
			this.#think(guest, `I want to go on ${name}!`);
		}

		return true;
	}

	// The thought of a rider who comes off, from the ride they had.
	#comeOff(guest, slot, wasStuck) {
		const name = this.#rideName();
		guest.state = 'exiting';
		guest.lane = walkLane;
		guest.x = exitStairs + (slot * 6);
		guest.direction = 1;
		guest.rides++;
		if (wasStuck) {
			this.#think(guest, `I want my money back! I was stuck on ${name} for ages!`);
			this.#park.money -= guest.ticket ?? this.#park.price;
			guest.state = 'leaving';
			return;
		}

		const {excitement, intensity, nausea} = this.#lastRun?.ratings ?? {excitement: 0, intensity: 0, nausea: 0};
		const sickness = clamp((nausea - guest.tolerance) * 0.3, 0, 0.85);
		if (Math.random() < sickness) {
			this.#think(guest, nausea - guest.tolerance > 2.5 ? 'I feel very sick' : 'I feel sick', 6);
			guest.isSick = true;
			guest.sickTimer = randomBetween(1.5, 3.5);
			return;
		}

		if (Math.random() < 0.07) {
			this.#think(guest, randomItem(['I’m lost!', 'I can’t find the park exit!', 'Where did I park my bike?']), 6);
			guest.state = 'lost';
			guest.lostTimer = 25;
			return;
		}

		if (intensity > guest.maximumIntensity) {
			this.#think(guest, `${name} was too intense for me!`);
		} else if (excitement >= 6) {
			this.#think(guest, guest.isTrond ? 'Again! Again! Again!' : randomItem(['Wow! What a great ride!', `Wow! ${name} was great!`, `${name} was more fun than a waffle with brunost!`]));
			if (guest.isTrond || Math.random() < 0.35) {
				guest.wantsAgain = true;
			}
		} else if (excitement >= 4) {
			this.#think(guest, `${name} was fun`);
		} else {
			this.#think(guest, `${name} was more boring than the merry-go-round`);
		}

		if (this.#park.price <= this.#rideValue() * 0.5 && Math.random() < 0.4) {
			this.#think(guest, `${name} is really good value!`);
		}
	}

	#updateGuests(seconds) {
		if (this.#rideStatus === 'open' || this.#guests.length < 6) {
			this.#spawnTimer -= seconds * (this.#isRaining ? 0.5 : 1);
		}

		if (this.#spawnTimer <= 0 && this.#guests.length < 28) {
			this.#spawnTimer = this.#rideStatus === 'open' ? randomBetween(1.5, 3.5) : randomBetween(3, 6);
			this.#guests.push(this.#makeGuest());
		}

		const slots = this.#queue();
		for (const guest of [...this.#guests]) {
			guest.step += seconds * guest.speed / 6;
			if (guest.isSick && guest.state !== 'riding') {
				guest.sickTimer -= seconds;
				if (guest.sickTimer <= 0) {
					guest.isSick = false;
					// The path only holds so much vomit, so a park without handymen does not fill up forever.
					if (this.#puddles.length < 40) {
						this.#puddles.push({x: guest.x, lane: guest.lane, age: 0});
					}

					this.#audio.vomit();
					this.#think(guest, 'Bleurgh!', 2);
				}
			}

			if (guest.state === 'riding') {
				continue;
			}

			if (guest.state === 'queue' || guest.state === 'toQueue') {
				const target = queueStart + (slots.indexOf(guest) * queueSpacing);
				guest.waited += seconds;
				if (Math.abs(guest.x - target) > 0.5) {
					guest.direction = Math.sign(target - guest.x);
					guest.x += guest.direction * Math.min(Math.abs(target - guest.x), guest.speed * seconds);
				} else {
					guest.state = 'queue';
					guest.step = 0;
				}

				if (guest.waited > 60 && !guest.hasComplained) {
					guest.hasComplained = true;
					this.#think(guest, `I’ve been queuing for ${this.#rideName()} for ages`);
				}

				if (this.#rideStatus !== 'open') {
					this.#think(guest, `I wanted to go on ${this.#rideName()}, but it’s closed`);
					guest.state = 'leaving';
					guest.lane = walkLane;
					guest.direction = 1;
				}

				continue;
			}

			if (guest.state === 'boarding') {
				guest.x -= guest.speed * 1.5 * seconds;
				if (guest.x <= queueStart - 10) {
					guest.state = 'riding';
				}

				continue;
			}

			if (guest.state === 'lost') {
				guest.lostTimer -= seconds;
				if (Math.random() < seconds * 0.4) {
					guest.direction *= -1;
				}

				if (guest.lostTimer <= 0) {
					this.#think(guest, 'I want to go home');
					guest.state = 'leaving';
					guest.direction = 1;
				}
			}

			guest.x += guest.direction * guest.speed * seconds * (guest.state === 'lost' ? 0.6 : 1);
			if (guest.state === 'lost') {
				guest.x = clamp(guest.x, 20, 600);
			}

			// A guest who steps near the vomit on the path thinks about it, once.
			if (!guest.sawVomit && this.#puddles.some(puddle => Math.abs(puddle.x - guest.x) < 5 && puddle.lane === guest.lane && puddle.age > 1)) {
				guest.sawVomit = true;
				this.#think(guest, 'The vomit here is really disgusting!');
			}

			if (guest.state === 'arriving' && guest.direction < 0 && guest.x <= decisionPoint && !guest.hasDecided) {
				guest.hasDecided = true;
				if (this.#decide(guest)) {
					guest.state = 'toQueue';
					guest.lane = queueLane;
					guest.waited = 0;
				}
			}

			if (guest.state === 'exiting' && guest.x > decisionPoint + 20) {
				if (guest.wantsAgain && this.#rideStatus === 'open' && this.#queue().length < queueLength) {
					guest.wantsAgain = false;
					this.#think(guest, `I want to go on ${this.#rideName()} again!`);
					guest.ticket = this.#park.price;
					guest.state = 'toQueue';
					guest.lane = queueLane;
					guest.waited = 0;
				} else {
					guest.state = 'leaving';
				}
			}

			if ((guest.state === 'arriving' || guest.state === 'exiting') && guest.x < 30) {
				guest.direction = 1;
				guest.state = 'leaving';
			}

			if (guest.state === 'leaving' && guest.x > gate + 10) {
				this.#guests.splice(this.#guests.indexOf(guest), 1);
				if (this.#selectedGuest === guest) {
					this.#selectedGuest = undefined;
				}
			}
		}

		// Rain in Bergen comes and goes. The guests put up their umbrellas.
		this.#rainTimer -= seconds;
		if (this.#rainTimer <= 0) {
			this.#isRaining = !this.#isRaining;
			this.#rainTimer = this.#isRaining ? randomBetween(15, 30) : randomBetween(35, 70);
			if (this.#isRaining) {
				const guest = randomItem(this.#guests.filter(other => other.state !== 'riding'));
				if (guest) {
					this.#think(guest, randomItem(['It’s raining. Typisk Bergen!', 'Good thing I always bring my umbrella', 'It’s raining again']));
				}
			}
		}
	}

	// The handymen sweep up the vomit, nearest first, and walk around with their brooms when the path is clean.
	#updateHandymen(seconds) {
		while (this.#handymen.length < this.#park.handymen) {
			this.#handymen.push({x: gate, target: undefined, sweeping: 0, direction: -1, step: 0});
		}

		for (const handyman of this.#handymen) {
			handyman.step += seconds * 3;
			if (handyman.sweeping > 0) {
				handyman.sweeping -= seconds;
				if (handyman.sweeping <= 0 && handyman.target) {
					this.#puddles.splice(this.#puddles.indexOf(handyman.target), 1);
					handyman.target = undefined;
				}

				continue;
			}

			if (!handyman.target || !this.#puddles.includes(handyman.target)) {
				const free = this.#puddles.filter(puddle => !this.#handymen.some(other => other.target === puddle));
				handyman.target = free.sort((first, second) => Math.abs(first.x - handyman.x) - Math.abs(second.x - handyman.x))[0];
			}

			const goal = handyman.target?.x ?? (handyman.direction < 0 ? 60 : 590);
			const distance = goal - handyman.x;
			if (Math.abs(distance) < 2) {
				if (handyman.target) {
					handyman.sweeping = 2;
				} else {
					handyman.direction *= -1;
				}
			} else {
				handyman.direction = Math.sign(distance);
				handyman.x += handyman.direction * 16 * seconds;
			}
		}

		for (const puddle of this.#puddles) {
			puddle.age += seconds;
		}
	}

	// The ride: the status lights, the test run, the loading of the train, and what happens when it comes back.
	#isTrainHome() {
		return this.#train.phase === 'stopped';
	}

	#dispatch() {
		Object.assign(this.#train, {phase: 'running', s: stationStop, speed: 0, odometer: 0, reversals: 0, wasForward: false, time: 0, chainDistance: 0, stalled: 0, cut: undefined});
		this.#train.hasRocky = this.#isTesting;
		this.#audio.whistle();
	}

	#showStatus() {
		for (const [id, button] of this.#statusButtons) {
			const isOn = id === this.#rideStatus;
			button.setAttribute('aria-pressed', String(isOn));
			button.querySelector('span').dataset.state = isOn ? 'on' : '';
		}
	}

	#setStatus(value) {
		this.#rideStatus = value;
		this.#showStatus();
	}

	// A train that crashed has to be replaced before the ride can run again.
	#replaceTrain() {
		if (!this.#wreck) {
			return true;
		}

		if (this.#wreck.isFlying) {
			this.say('Wait until the train has landed!');
			return false;
		}

		this.#park.money -= 1500;
		this.#wreck = undefined;
		this.#train = newTrain();
		this.#trainTrack = this.#track;
		this.#keep();
		this.say(`A new train for ${this.#rideName()} cost ${kroner(1500)}.`);
		return true;
	}

	#startTest() {
		if (!this.#track.isClosed) {
			this.say(`Can’t test ${this.#rideName()}… ${this.#track.returnError}`);
			this.#setStatus('closed');
			return;
		}

		if (!this.#replaceTrain()) {
			return;
		}

		this.#pendingRun = testRun(this.#track, this.#park.pieces);
		this.#isTesting = true;
		this.#setStatus('test');
		this.say(`Testing ${this.#rideName()}. Rocky the pet rock rides in the front car as the test dummy.`);
		if (this.#isTrainHome()) {
			this.#dispatchTimer = 1;
		}
	}

	#openRide() {
		if (!this.#lastRun?.ratings) {
			this.#openAfterTest = true;
			this.#startTest();
			if (this.#rideStatus === 'test') {
				this.say(`${this.#rideName()} has to be tested before it can open. Testing now…`);
			}

			return;
		}

		if (!this.#replaceTrain()) {
			return;
		}

		this.#isTesting = false;
		this.#setStatus('open');
		this.say(`${this.#rideName()} is open! The ticket costs ${kroner(this.#park.price)}.`);
		this.celebrate();
		// The guests on the path hear that the ride is open, and come back to look at it.
		for (const guest of this.#guests) {
			if (guest.state === 'arriving' || guest.state === 'leaving') {
				Object.assign(guest, {state: 'arriving', direction: -1, hasDecided: false});
			}
		}
	}

	#closeRide() {
		this.#openAfterTest = false;
		this.#isTesting = false;
		this.#setStatus('closed');
		this.say(this.#isTrainHome() ? `${this.#rideName()} is closed.` : `${this.#rideName()} is closing. The train finishes its lap first.`);
	}

	// The ratings of a test run go into the ride window, and the test result into the ticker.
	#reveal(run) {
		this.#lastRun = run;
		this.#park.isTested = true;
		this.#keep();
		this.#showRide();
		this.#drawGraph();
		if (!run.ratings) {
			return;
		}

		const {excitement, intensity, nausea} = run.ratings;
		this.say(`Test results for ${this.#rideName()}: Excitement ${excitement.toFixed(2)} (${ratingWord(excitement)}), Intensity ${intensity.toFixed(2)} (${ratingWord(intensity)}), Nausea ${nausea.toFixed(2)} (${ratingWord(nausea)}).`);
		if (excitement >= 7) {
			this.toast(`${this.#rideName()} got an excitement rating of ${excitement.toFixed(2)} (${ratingWord(excitement)})! The guests will love it.`);
			this.celebrate();
		}
	}

	#arrive(wasStuck) {
		const riders = this.#guests.filter(guest => guest.state === 'riding');
		for (const [slot, rider] of riders.entries()) {
			this.#comeOff(rider, slot, wasStuck);
		}

		if (this.#isTesting && this.#pendingRun) {
			const run = this.#pendingRun;
			this.#pendingRun = undefined;
			this.#reveal(run);
			if (run.ratings && this.#openAfterTest) {
				this.#openAfterTest = false;
				this.#openRide();
			} else if (!run.ratings) {
				this.#openAfterTest = false;
			}
		}

		this.#loadTimer = 0;
		this.#dispatchTimer = this.#rideStatus === 'test' ? 1.5 : 0;
		this.#train.hasRocky = false;
		this.#trainTrack = this.#track;
		if (this.#train.cut !== undefined) {
			this.#train.cut = undefined;
			this.#drawTrackLayer();
		}
	}

	// The train leaves the track: the cars fly on, the riders float down under their umbrellas, and the balloons get away.
	#crash() {
		const cars = [];
		for (let car = 0; car < carCount; car++) {
			const point = pointAt(this.#trainTrack, this.#train.s - (car * carSpacing));
			const velocity = scale(point.sample.forward, this.#train.speed);
			cars.push({x: point.x, y: point.y, z: point.z, velocityX: velocity.x, velocityY: velocity.y + 2, velocityZ: velocity.z, angle: Math.atan2(-velocity.y, velocity.x), spin: randomBetween(-6, 6), isLanded: false});
		}

		const riders = this.#guests.filter(guest => guest.state === 'riding');
		for (const [index, rider] of riders.entries()) {
			const car = cars[Math.floor(index / 2)];
			const point = project(car.x, car.y, car.z);
			this.#particles.push({kind: 'floater', x: point.x, y: point.y, velocityX: randomBetween(-30, 30), velocityY: -randomBetween(30, 60), life: 30, guest: rider});
			rider.state = 'floating';
		}

		this.#wreck = {cars, isFlying: true, riders: riders.length, hadRocky: this.#train.hasRocky};
		this.#train.phase = 'crashed';
		this.#audio.setRumble(0);
		this.say(`Oh no! ${this.#rideName()} flew off the track!`);
	}

	#updateWreck(seconds) {
		if (!this.#wreck?.isFlying) {
			return;
		}

		for (const car of this.#wreck.cars) {
			if (car.isLanded) {
				continue;
			}

			car.velocityY -= gravity * seconds;
			car.x += car.velocityX * seconds;
			car.y += car.velocityY * seconds;
			car.z += car.velocityZ * seconds;
			car.angle += car.spin * seconds;
			car.x = clamp(car.x, -2, 158);
			if (car.y <= 0.6) {
				car.y = 0.6;
				car.isLanded = true;
				const point = project(car.x, car.y, car.z);
				for (let index = 0; index < 6; index++) {
					this.#particles.push({kind: 'smoke', x: point.x + randomBetween(-6, 6), y: point.y, velocityX: randomBetween(-8, 8), velocityY: -randomBetween(8, 20), life: randomBetween(2, 4), size: randomBetween(3, 7)});
				}

				this.#particles.push({kind: 'text', text: 'BOOM!', x: point.x, y: point.y - 12, velocityX: 0, velocityY: -12, life: 1.5});
				if (!this.#wreck.hasBoomed) {
					this.#wreck.hasBoomed = true;
					this.#audio.crash();
					for (let index = 0; index < 6; index++) {
						this.#particles.push({kind: 'balloon', x: point.x + randomBetween(-10, 10), y: point.y - 10, velocityX: randomBetween(-6, 6), velocityY: -randomBetween(14, 24), life: 20, color: randomItem(shirts), wobble: Math.random() * 6});
					}
				}
			}
		}

		if (this.#wreck.cars.every(car => car.isLanded)) {
			this.#wreck.isFlying = false;
			this.#openAfterTest = false;
			this.#isTesting = false;
			this.#pendingRun = undefined;
			this.#setStatus('closed');
			const riders = this.#wreck.riders;
			const text = riders > 0
				? `Oh no, they crashed! ${riders} ${riders === 1 ? 'rider floated' : 'riders floated'} down under their umbrellas, as everyone in Bergen carries one, and nobody got hurt. The balloon seller is not happy. A new train costs ${kroner(1500)}.`
				: `Oh no, the test train crashed! Only Rocky the pet rock was on it, and he is fine, as he is a rock. A new train costs ${kroner(1500)}.`;
			this.say(text);
			this.toast(`Oh no! ${this.#rideName()} has crashed!`);
			this.#trainTrack = this.#track;
			this.#train.cut = undefined;
			this.#drawTrackLayer();
		}
	}

	// One frame of the train, in small fixed steps so the physics is the same as in the test run.
	#updateTrain(seconds) {
		if (this.#train.phase === 'stopped') {
			this.#audio.setRumble(0);
			if (this.#rideStatus === 'test') {
				this.#dispatchTimer -= seconds;
				if (this.#dispatchTimer <= 0 && !this.#guests.some(guest => guest.state === 'boarding')) {
					this.#dispatch();
				}
			} else if (this.#rideStatus === 'open') {
				this.#loadTimer += seconds;
				const riding = this.#guests.filter(guest => guest.state === 'riding' || guest.state === 'boarding').length;
				const waiting = this.#queue().filter(guest => guest.state === 'queue');
				if (riding < carCount * 2 && waiting.length > 0 && this.#loadTimer > 0.4) {
					this.#loadTimer = 0.01;
					const guest = waiting[0];
					guest.state = 'boarding';
					guest.direction = -1;
					// A guest pays the price of when they joined the queue.
					const ticket = guest.ticket ?? this.#park.price;
					guest.ticket = ticket;
					this.#park.money += ticket;
					this.#monthIncome += ticket;
					this.#park.riders++;
					this.#particles.push({kind: 'text', text: `+${ticket} kr`, x: queueStart - 4, y: queueLane - 14, velocityX: 0, velocityY: -14, life: 1.2, color: '#ffff60'});
					if (ticket > 0) {
						this.#audio.cash();
					}
				}

				this.#dispatchTimer += seconds;
				const isFull = this.#guests.filter(guest => guest.state === 'riding').length >= carCount * 2;
				const isBoarding = this.#guests.some(guest => guest.state === 'boarding');
				if (!isBoarding && ((isFull && this.#dispatchTimer > 1) || (riding > 0 && this.#dispatchTimer > 8) || this.#dispatchTimer > 14)) {
					this.#dispatchTimer = 0;
					this.#dispatch();
				}
			} else if (this.#guests.some(guest => guest.state === 'riding') && !this.#guests.some(guest => guest.state === 'boarding')) {
				if (this.#trainTrack.isClosed) {
					// Riders who sat down before the ride closed get their lap first.
					this.#dispatch();
				} else {
					// The track was changed under them, and no longer goes back to the station, so they get off with their money back.
					for (const rider of this.#guests.filter(guest => guest.state === 'riding')) {
						Object.assign(rider, {state: 'leaving', x: exitStairs, lane: walkLane, direction: 1});
						this.#park.money -= rider.ticket ?? this.#park.price;
						this.#think(rider, `I wanted to go on ${this.#rideName()}, but it’s closed`);
					}
				}
			}

			return;
		}

		if (this.#train.phase === 'stuck') {
			this.#train.stuckTimer -= seconds;
			if (this.#train.stuckTimer <= 0) {
				this.#train.phase = 'towing';
				this.say(`A mechanic pulls the train of ${this.#rideName()} back to the station with Pappa’s Volvo.`);
			}

			return;
		}

		if (this.#train.phase === 'towing') {
			const distance = Math.min(3 * seconds, this.#train.odometer);
			this.#train.s -= distance;
			this.#train.odometer -= distance;
			this.#train.speed = -3;
			this.#audio.setRumble(3);
			if (this.#train.odometer <= 0) {
				this.#train.phase = 'stopped';
				this.#train.s = stationStop;
				this.#train.speed = 0;
				this.#arrive(true);
			}

			return;
		}

		if (this.#train.phase !== 'running') {
			return;
		}

		let left = seconds;
		while (left > 0) {
			const event = stepTrain(this.#train, this.#trainTrack, Math.min(physicsStep, left));
			left -= physicsStep;
			if (event === 'chain') {
				this.#audio.clack();
			} else if (event === 'rollback') {
				this.say(`The train of ${this.#rideName()} did not make it over the hill, and rolls back! Build a higher lift hill, or a lower hill.`);
			} else if (event === 'stuck') {
				this.#train.phase = 'stuck';
				this.#train.stuckTimer = 3;
				this.#train.speed = 0;
				if (this.#isTesting && this.#pendingRun) {
					this.#reveal(this.#pendingRun);
					this.#pendingRun = undefined;
				}

				this.#setStatus('closed');
				this.#isTesting = false;
				this.#openAfterTest = false;
				this.say(`The train of ${this.#rideName()} is stuck in a valley! The ride is closed until a mechanic gets it back.`);
				return;
			} else if (event === 'derail') {
				if (this.#isTesting && this.#pendingRun) {
					this.#reveal(this.#pendingRun);
					this.#pendingRun = undefined;
				}

				this.#crash();
				return;
			} else if (event === 'arrived') {
				this.#arrive(false);
				return;
			}
		}

		this.#audio.setRumble(this.#train.speed);
		this.#screamCooldown -= seconds;
		const riders = this.#guests.filter(guest => guest.state === 'riding');
		const sample = sampleAt(this.#trainTrack, this.#train.s - carSpacing);
		const isThrilling = this.#train.vertical > 3 || this.#train.vertical < 0.15 || sample.inverted || (this.#train.speed > 15 && sample.forward.y < -0.4);
		if (isThrilling && this.#screamCooldown <= 0 && riders.length > 0) {
			this.#screamCooldown = 2.5;
			this.#train.screamUntil = this.#clock + 1.2;
			this.#audio.scream();
			const point = project(pointAt(this.#trainTrack, this.#train.s).x, pointAt(this.#trainTrack, this.#train.s).y, pointAt(this.#trainTrack, this.#train.s).z);
			this.#particles.push({kind: 'text', text: randomItem(['Aaaaah!', 'Wheee!', 'AAAAAAH!', 'Mammaaa!', 'Yaaay!']), x: point.x, y: point.y - 14, velocityX: 0, velocityY: -10, life: 1.4, color: '#ffffff'});
		}
	}

	// Each month of the park, the handymen get their pay, and the ticker says how it went. Pappa is impressed when the park makes money.
	#updateMonth(seconds) {
		this.#monthTimer += seconds;
		if (this.#monthTimer < 45) {
			return;
		}

		this.#monthTimer = 0;
		this.#park.month++;
		const wages = this.#park.handymen * 200;
		this.#park.money -= wages;
		const year = 1999 + Math.floor(this.#park.month / 12);
		const month = months[this.#park.month % 12];
		let text = `It is ${month} ${year}. Tickets made ${kroner(this.#monthIncome)} last month${wages > 0 ? `, and the handymen got ${kroner(wages)}` : ''}.`;
		if (this.#park.month === 12) {
			text = `Happy new year 2000! The year 2000 problem did not crash the park. ${text}`;
			this.celebrate();
		}

		this.#monthIncome = 0;
		this.say(text);
		this.#keep();
	}

	#update(seconds) {
		this.#clock += seconds;
		this.#updateTrain(seconds);
		this.#updateWreck(seconds);
		this.#updateGuests(seconds);
		this.#updateHandymen(seconds);
		this.#updateMonth(seconds);
		for (const particle of [...this.#particles]) {
			particle.life -= seconds;
			if (particle.kind === 'floater') {
				// A rider on an umbrella falls slowly to the path, and walks off angry, but dry.
				particle.velocityY = Math.min(particle.velocityY + (60 * seconds), 18);
				particle.x += particle.velocityX * seconds;
				particle.velocityX *= 0.98;
				particle.y += particle.velocityY * seconds;
				if (particle.y >= walkLane) {
					this.#particles.splice(this.#particles.indexOf(particle), 1);
					const {guest} = particle;
					Object.assign(guest, {state: 'leaving', x: clamp(particle.x, 10, 620), lane: walkLane, direction: 1});
					this.#park.money -= guest.ticket ?? this.#park.price;
					this.#think(guest, randomItem(['I want my money back!', 'That was not in the brochure!', 'Good thing I brought my umbrella!', 'Can we do that again?']));
				}

				continue;
			}

			if (particle.kind === 'balloon') {
				particle.x += (particle.velocityX + (Math.sin((this.#clock * 2) + particle.wobble) * 8)) * seconds;
			} else {
				particle.x += particle.velocityX * seconds;
			}

			particle.y += particle.velocityY * seconds;
			if (particle.life <= 0 || particle.y < -20) {
				this.#particles.splice(this.#particles.indexOf(particle), 1);
			}
		}

	}

	#drawScenery() {
		const {canvas} = this.parts;
		const paint = this.#sceneryLayer.getContext('2d');
		const sky = paint.createLinearGradient(0, 0, 0, groundLine);
		sky.addColorStop(0, '#6f93b8');
		sky.addColorStop(1, '#c4d6e4');
		paint.fillStyle = sky;
		paint.fillRect(0, 0, canvas.width, groundLine);

		// Clouds over Bergen, as always.
		paint.fillStyle = '#eef2f6';
		for (const [x, y, size] of [[70, 40, 26], [250, 26, 34], [430, 52, 22], [560, 30, 30]]) {
			for (let index = 0; index < 4; index++) {
				paint.beginPath();
				paint.ellipse(x + (index * size * 0.6), y + ((index % 2) * 5), size * 0.6, size * 0.35, 0, 0, Math.PI * 2);
				paint.fill();
			}
		}

		// Fløyen behind the park, with fir trees and the funicular going up.
		paint.fillStyle = '#3d6b45';
		paint.beginPath();
		paint.moveTo(0, groundLine - 30);
		for (let x = 0; x <= canvas.width; x += 8) {
			const height = 150 + (Math.sin(x / 90) * 30) + (Math.sin(x / 31) * 8) - (Math.max(0, x - 380) * 0.18);
			paint.lineTo(x, groundLine - height);
		}

		paint.lineTo(canvas.width, groundLine);
		paint.lineTo(0, groundLine);
		paint.fill();
		paint.fillStyle = '#2c5534';
		for (let index = 0; index < 70; index++) {
			const x = (index * 97) % canvas.width;
			const y = groundLine - 20 - ((index * 53) % 120);
			paint.beginPath();
			paint.moveTo(x, y - 9);
			paint.lineTo(x - 4, y);
			paint.lineTo(x + 4, y);
			paint.fill();
		}

		paint.strokeStyle = 'rgba(90, 64, 48, 0.45)';
		paint.lineWidth = 1;
		paint.beginPath();
		paint.moveTo(300, groundLine - 20);
		paint.lineTo(420, groundLine - 150);
		paint.stroke();
		paint.fillStyle = 'rgba(192, 48, 48, 0.6)';
		paint.fillRect(386, groundLine - 117, 6, 4);
		paint.fillStyle = '#ffffff';
		paint.font = 'bold 8px sans-serif';
		paint.fillText('FLØYEN 320 moh.', 430, groundLine - 156);

		// The grass of the park and the path along the front, where the guests walk.
		paint.fillStyle = '#5fa04a';
		paint.fillRect(0, groundLine - 4, canvas.width, canvas.height - groundLine + 4);
		paint.fillStyle = '#c8b48a';
		paint.fillRect(0, queueLane - 7, canvas.width, walkLane - queueLane + 11);
		paint.fillStyle = '#b09a70';
		paint.fillRect(0, queueLane - 7, canvas.width, 1);
		paint.fillRect(0, walkLane + 3, canvas.width, 1);
		paint.fillStyle = '#e8d8b0';
		for (let x = 0; x < canvas.width; x += 14) {
			paint.fillRect(x, walkLane - 4, 6, 1);
		}

		// The queue line has railings, like in the game.
		paint.fillStyle = '#707070';
		paint.fillRect(queueStart - 6, queueLane + 2, (queueSpacing * queueLength) + 10, 1);
		for (let x = queueStart - 6; x <= queueStart + (queueSpacing * queueLength) + 4; x += 10) {
			paint.fillRect(x, queueLane - 4, 1, 6);
		}

		paint.fillStyle = '#e080a0';
		for (let x = 4; x < canvas.width; x += 23) {
			paint.fillRect(x, 356, 2, 2);
			paint.fillRect(x + 11, 358, 2, 2);
		}

		// The park gate, by the entrance on the right.
		paint.fillStyle = '#804020';
		paint.fillRect(gate - 4, walkLane - 34, 3, 36);
		paint.fillRect(gate + 8, walkLane - 34, 3, 36);
		paint.fillStyle = '#ffd800';
		paint.fillRect(gate - 14, walkLane - 44, 32, 11);
		paint.fillStyle = '#802000';
		paint.font = 'bold 7px sans-serif';
		paint.fillText('FLØYEN', gate - 12, walkLane - 37);
		paint.fillText('PARK', gate - 7, walkLane - 34 + 1);
	}

	// The steel supports go down to the ground from the track where it is upright, with a cross brace on the tall ones.
	#drawSupports(paint, samples, end) {
		const colors = this.#scheme();
		paint.strokeStyle = colors.supports;
		paint.lineWidth = 2;
		for (let index = 0; index < end; index += 16) {
			const sample = samples[index];
			if (sample.up.y < 0.6 || sample.y < 1.2 || sample.station) {
				continue;
			}

			const top = project(sample.x, sample.y - 0.5, sample.z);
			const bottom = project(sample.x, 0, sample.z);
			drawLine(paint, top, bottom);
			if (sample.y > 12) {
				paint.lineWidth = 1;
				const middle = project(sample.x, sample.y / 2, sample.z);
				drawLine(paint, {x: bottom.x - 4, y: bottom.y}, middle);
				drawLine(paint, {x: bottom.x + 4, y: bottom.y}, middle);
				paint.lineWidth = 2;
			}
		}
	}

	// The track is a spine below two rails, with ties across, drawn from the back to the front.
	#drawTrackSamples(paint, samples, end, {color, rail, alpha = 1} = {}) {
		const colors = this.#scheme();
		const segments = [];
		for (let index = 0; index + 2 < end; index += 2) {
			segments.push(index);
		}

		segments.sort((first, second) => samples[first].z - samples[second].z);
		paint.globalAlpha = alpha;
		paint.lineCap = 'round';
		for (const index of segments) {
			const sample = samples[index];
			const next = samples[index + 2];
			const below = sample => add(sample, scale(sample.up, -0.5));
			const railOffset = sample => scale(sample.side, 0.7);
			paint.strokeStyle = color ?? colors.track;
			paint.lineWidth = 3;
			drawLine(paint, projectVector(below(sample)), projectVector(below(next)));
			paint.strokeStyle = rail ?? colors.rail;
			paint.lineWidth = 1.2;
			drawLine(paint, projectVector(add(sample, railOffset(sample))), projectVector(add(next, railOffset(next))));
			drawLine(paint, projectVector(subtract(sample, railOffset(sample))), projectVector(subtract(next, railOffset(next))));
			if (index % 6 === 0) {
				paint.strokeStyle = '#303030';
				paint.lineWidth = 1;
				drawLine(paint, projectVector(add(sample, railOffset(sample))), projectVector(subtract(sample, railOffset(sample))));
			}

			if (!color && sample.chain) {
				paint.strokeStyle = '#202020';
				paint.lineWidth = 1;
				const chain = projectVector(add(sample, scale(sample.up, -0.2)));
				paint.strokeRect(chain.x - 0.5, chain.y - 0.5, 1, 1);
			}

			if (!color && sample.brake && index % 4 === 0) {
				paint.fillStyle = '#ff9000';
				const fin = projectVector(add(sample, scale(sample.up, -0.3)));
				paint.fillRect(fin.x - 1, fin.y - 1, 2, 2);
			}
		}

		paint.globalAlpha = 1;
	}

	// The station: a platform with a striped roof and the name of the ride, stairs down to the queue, and the exit.
	#drawStation(paint) {
		const colors = this.#scheme();
		const platformBack = project(stationStart, stationHeight - 0.6, -1.5);
		const platformFront = project(stationStart + stationLength, stationHeight - 0.6, 3);
		paint.fillStyle = '#909090';
		paint.fillRect(platformBack.x - 6, platformBack.y, platformFront.x - platformBack.x + 6, 5);
		paint.fillStyle = '#707070';
		for (let x = stationStart; x <= stationStart + stationLength; x += 4.5) {
			const top = project(x, stationHeight - 0.6, 3);
			paint.fillRect(top.x - 1, top.y, 2, groundLine - top.y + 4);
		}

		const roofLeft = project(stationStart - 1, stationHeight + 4.2, 0);
		const roofRight = project(stationStart + stationLength + 1, stationHeight + 4.2, 0);
		for (let x = roofLeft.x; x < roofRight.x; x += 8) {
			paint.fillStyle = Math.round((x - roofLeft.x) / 8) % 2 === 0 ? colors.track : '#ffffff';
			paint.fillRect(x, roofLeft.y - 6, Math.min(8, roofRight.x - x), 6);
		}

		paint.fillStyle = '#606060';
		paint.fillRect(roofLeft.x + 2, roofLeft.y, 2, 16);
		paint.fillRect(roofRight.x - 4, roofLeft.y, 2, 16);
		paint.fillStyle = '#000080';
		paint.fillRect(roofLeft.x + 8, roofLeft.y - 16, roofRight.x - roofLeft.x - 16, 10);
		paint.fillStyle = '#ffff60';
		paint.font = 'bold 8px sans-serif';
		paint.textAlign = 'center';
		paint.fillText(this.#rideName().slice(0, 18), (roofLeft.x + roofRight.x) / 2, roofLeft.y - 8);
		paint.textAlign = 'start';

		// The stairs to the queue line and from the exit.
		paint.fillStyle = '#a07040';
		for (let step = 0; step < 6; step++) {
			paint.fillRect(platformFront.x - 6 + (step * 1.5), platformFront.y + 5 + (step * 5.5), 6, 2);
			paint.fillRect(platformBack.x + 4 - (step * 1.5), platformFront.y + 5 + (step * 5.5), 6, 2);
		}

		for (const [x, text, color] of [[queueStart - 10, 'IN', '#20a020'], [exitStairs - 2, 'EXIT', '#c02020']]) {
			paint.fillStyle = color;
			paint.fillRect(x - 8, queueLane - 22, 20, 8);
			paint.fillStyle = '#ffffff';
			paint.font = 'bold 7px sans-serif';
			paint.fillText(text, x - 6, queueLane - 16);
		}
	}

	#drawTrackLayer() {
		const paint = this.#trackLayer.getContext('2d');
		paint.clearRect(0, 0, this.parts.canvas.width, this.parts.canvas.height);
		// While a train runs toward a demolished piece, the way back is not drawn, so the gap shows.
		const end = this.#track.isClosed && this.#train.cut === undefined ? this.#track.samples.length : this.#track.outEnd;
		this.#drawSupports(paint, this.#track.samples, end);
		this.#drawStation(paint);
		this.#drawTrackSamples(paint, this.#track.samples, end);
		if (end === this.#track.outEnd) {
			// The end of a track that does not reach the station yet ends in a buffer, like the end of track in the game.
			const last = this.#track.samples[this.#track.outEnd - 1];
			const point = project(last.x, last.y, last.z);
			paint.fillStyle = '#ffd800';
			paint.fillRect(point.x - 2, point.y - 4, 4, 6);
		}
	}

	#makeGhost() {
		const piece = {type: this.#selectedPiece, chain: this.#isChain && takesChain(this.#selectedPiece), banked: this.#isBanked};
		const candidate = compileTrack([...this.#park.pieces, piece]);
		const start = candidate.pieceStarts.at(-1);
		this.#ghost = {piece, samples: candidate.samples.slice(Math.max(0, start - 2), candidate.outEnd), error: pieceError(candidate), cost: pieceTypes[this.#selectedPiece].cost + (piece.chain ? chainCost : 0)};
	}

	#drawGhost() {
		if (!this.#ghost || !allowedPieces(this.#track.level)[this.#selectedPiece] || this.#rideStatus !== 'closed' || this.#isCamera) {
			return;
		}

		if (!this.reducedMotion && Math.floor(this.#clock * 2.5) % 3 === 0) {
			return;
		}

		this.#drawTrackSamples(this.#context, this.#ghost.samples, this.#ghost.samples.length, this.#ghost.error ? {color: '#ff2020', rail: '#ff8080', alpha: 0.7} : {color: '#ffffff', rail: '#ffffa0', alpha: 0.75});
	}

	// The speeds of the last test run, written along the track, in kilometers per hour.
	#drawSpeeds() {
		const context = this.#context;
		const speeds = this.#lastRun?.speeds;
		if (!this.#isShowingSpeeds || !speeds || this.#isCamera) {
			return;
		}

		context.font = 'bold 8px sans-serif';
		context.textAlign = 'center';
		for (let bucket = 2; bucket < speeds.length; bucket += 3) {
			if (!speeds[bucket]) {
				continue;
			}

			const sample = this.#track.samples[bucket * 16];
			const point = projectVector(add(sample, scale(sample.up, 2.4)));
			const text = String(speeds[bucket]);
			context.fillStyle = '#000080';
			context.fillRect(point.x - 7, point.y - 7, 14, 9);
			context.fillStyle = '#ffffff';
			context.fillText(text, point.x, point.y);
		}

		context.textAlign = 'start';
	}

	// The merry-go-round by the gate, the dullest ride of the park.
	#drawMerryGoRound() {
		const context = this.#context;
		const x = 590;
		const y = queueLane - 9;
		context.fillStyle = '#e04040';
		context.beginPath();
		context.moveTo(x - 14, y - 14);
		context.lineTo(x, y - 24);
		context.lineTo(x + 14, y - 14);
		context.fill();
		context.fillStyle = '#ffd800';
		context.fillRect(x - 14, y - 14, 28, 3);
		context.fillStyle = '#8a6a40';
		context.fillRect(x - 1, y - 11, 2, 11);
		context.fillStyle = '#ffffff';
		for (let horse = 0; horse < 3; horse++) {
			const angle = (this.#clock * (this.reducedMotion ? 0 : 1.5)) + (horse * Math.PI * 2 / 3);
			const horseX = x + (Math.sin(angle) * 11);
			context.globalAlpha = Math.cos(angle) > 0 ? 1 : 0.5;
			context.fillRect(horseX - 2, y - 6 + (Math.sin(angle * 2) * 1.5), 5, 3);
		}

		context.globalAlpha = 1;
		context.fillStyle = '#a0a0a0';
		context.fillRect(x - 15, y, 30, 2);
	}

	#drawPerson(x, feet, {shirt, isSick, isWalking, step, hasUmbrella, isSelected, isHandyman}) {
		const context = this.#context;
		const left = Math.round(x) - 2;
		const top = Math.round(feet) - 12;
		if (hasUmbrella) {
			context.fillStyle = shirt;
			context.beginPath();
			context.arc(left + 2, top - 1, 5.5, Math.PI, 0);
			context.fill();
			context.fillStyle = '#303030';
			context.fillRect(left + 2, top - 1, 1, 4);
		}

		context.fillStyle = isSick ? '#90d050' : '#f0c8a0';
		context.fillRect(left, top, 4, 4);
		context.fillStyle = isHandyman ? '#3050c0' : shirt;
		context.fillRect(left - 0.5, top + 4, 5, 4);
		context.fillStyle = isHandyman ? '#3050c0' : '#304060';
		const stride = isWalking ? Math.round(Math.sin(step * Math.PI)) : 0;
		context.fillRect(left + (stride > 0 ? -1 : 0), top + 8, 1.5, 4);
		context.fillRect(left + 2.5 + (stride < 0 ? 1 : 0), top + 8, 1.5, 4);
		if (isHandyman) {
			context.fillStyle = '#ffd800';
			context.fillRect(left - 0.5, top - 1, 5, 1.5);
		}

		if (isSelected) {
			context.fillStyle = '#ffff00';
			context.strokeStyle = '#000000';
			context.lineWidth = 0.8;
			context.beginPath();
			context.moveTo(left + 2, top - 3);
			context.lineTo(left - 2, top - 9);
			context.lineTo(left + 6, top - 9);
			context.closePath();
			context.fill();
			context.stroke();
		}
	}

	#drawGuests() {
		const context = this.#context;
		for (const puddle of this.#puddles) {
			context.fillStyle = '#b0c040';
			context.beginPath();
			context.ellipse(puddle.x, puddle.lane + 1, 4, 1.5, 0, 0, Math.PI * 2);
			context.fill();
			context.fillStyle = '#d0d060';
			context.fillRect(puddle.x - 1, puddle.lane, 2, 1);
		}

		const walking = this.#guests.filter(guest => guest.state !== 'riding' && guest.state !== 'floating');
		walking.sort((first, second) => first.lane - second.lane);
		for (const guest of walking) {
			const isWalking = guest.state !== 'queue';
			this.#drawPerson(guest.x, guest.lane, {shirt: guest.shirt, isSick: guest.isSick, isWalking, step: guest.step, hasUmbrella: this.#isRaining, isSelected: guest === this.#selectedGuest});
		}

		for (const handyman of this.#handymen) {
			this.#drawPerson(handyman.x, walkLane, {shirt: '#3050c0', isHandyman: true, isWalking: handyman.sweeping <= 0, step: handyman.step, hasUmbrella: false});
			// The broom, which sweeps back and forth while he works.
			context.strokeStyle = '#a07030';
			context.lineWidth = 1;
			const sweep = handyman.sweeping > 0 ? Math.sin(this.#clock * 12) * 3 : 0;
			drawLine(context, {x: handyman.x + 2, y: walkLane - 6}, {x: handyman.x + 5 + sweep, y: walkLane});
			context.fillStyle = '#e0c060';
			context.fillRect(handyman.x + 3 + sweep, walkLane - 1, 4, 2);
		}
	}

	// A car of the train, turned along the track, with its riders above it, or below it when they are upside down. The train is drawn a bit bigger than the track, so it is easy to follow.
	#drawCar(x, y, z, angle, upness, riders, {isFront, hasRocky, isScreaming}) {
		const context = this.#context;
		const colors = this.#scheme();
		const point = project(x, y, z);
		context.save();
		context.translate(point.x, point.y);
		context.rotate(angle);
		const lift = clamp(upness, -1, 1);
		for (const [seat, rider] of riders.entries()) {
			if (!rider) {
				continue;
			}

			const seatX = -4 + (seat * 7);
			const headY = -lift * 6.5;
			context.fillStyle = rider.isSick ? '#90d050' : '#f0c8a0';
			context.fillRect(seatX - 1.5, headY - 2, 4, 4);
			context.fillStyle = rider.shirt;
			context.fillRect(seatX - 1.5, headY + (lift > 0 ? 2 : -3), 4, 1.5);
			if (isScreaming) {
				context.fillStyle = '#f0c8a0';
				context.fillRect(seatX - 3, headY - (lift * 5) - 1.5, 1.5, 3);
				context.fillRect(seatX + 3, headY - (lift * 5) - 1.5, 1.5, 3);
			}
		}

		if (hasRocky) {
			context.fillStyle = '#8c8c8c';
			context.strokeStyle = '#404040';
			context.lineWidth = 0.8;
			context.beginPath();
			context.ellipse(4, -lift * 5.5, 3, 2.4, 0, 0, Math.PI * 2);
			context.fill();
			context.stroke();
		}

		context.fillStyle = '#000000';
		context.fillRect(-8, -3.5, 16, 7);
		context.fillStyle = colors.train;
		context.fillRect(-7, -2.5, 14, 5);
		context.fillStyle = colors.trim;
		context.fillRect(-7, -0.5, 14, 1.2);
		if (isFront) {
			context.fillStyle = colors.train;
			context.beginPath();
			context.moveTo(7, -2.5);
			context.lineTo(10, 0);
			context.lineTo(7, 2.5);
			context.fill();
		}

		context.restore();
	}

	#drawTrain() {
		const context = this.#context;
		if (this.#wreck) {
			for (const [index, car] of this.#wreck.cars.entries()) {
				this.#drawCar(car.x, car.y, car.z, car.angle, 1, [], {isFront: index === 0});
			}

			if (!this.#wreck.isFlying) {
				const first = project(this.#wreck.cars[0].x, 0.6, this.#wreck.cars[0].z);
				context.fillStyle = 'rgba(80, 80, 80, 0.5)';
				context.beginPath();
				context.arc(first.x, first.y - 8 - (Math.sin(this.#clock * 2) * 2), 6, 0, Math.PI * 2);
				context.fill();
			}

			return;
		}

		const riders = this.#guests.filter(guest => guest.state === 'riding');
		const isScreaming = this.#clock < (this.#train.screamUntil ?? 0);
		for (let car = carCount - 1; car >= 0; car--) {
			const point = pointAt(this.#trainTrack, this.#train.s - (car * carSpacing));
			const {sample} = point;
			const base = project(point.x, point.y, point.z);
			const ahead = project(point.x + sample.forward.x, point.y + sample.forward.y, point.z + sample.forward.z);
			const angle = Math.atan2(ahead.y - base.y, ahead.x - base.x);
			const upPoint = project(point.x + sample.up.x, point.y + sample.up.y, point.z + sample.up.z);
			const upness = (((upPoint.x - base.x) * Math.sin(angle)) - ((upPoint.y - base.y) * Math.cos(angle))) / pixelsPerMeter;
			const center = add(point, scale(sample.up, 0.55));
			this.#drawCar(center.x, center.y, center.z, angle, upness, [riders[car * 2], riders[(car * 2) + 1]], {isFront: car === 0, hasRocky: car === 0 && this.#train.hasRocky, isScreaming});
		}
	}

	#drawParticles() {
		const context = this.#context;
		for (const particle of this.#particles) {
			if (particle.kind === 'smoke') {
				context.fillStyle = `rgba(90, 90, 90, ${clamp(particle.life / 3, 0, 0.7)})`;
				context.beginPath();
				context.arc(particle.x, particle.y, particle.size + (3 - particle.life), 0, Math.PI * 2);
				context.fill();
			} else if (particle.kind === 'balloon') {
				context.strokeStyle = '#404040';
				context.lineWidth = 0.5;
				drawLine(context, {x: particle.x, y: particle.y + 4}, {x: particle.x + 1, y: particle.y + 12});
				context.fillStyle = particle.color;
				context.beginPath();
				context.ellipse(particle.x, particle.y, 3.5, 4.5, 0, 0, Math.PI * 2);
				context.fill();
			} else if (particle.kind === 'floater') {
				this.#drawPerson(particle.x, particle.y + 9, {shirt: particle.guest.shirt, hasUmbrella: true, isWalking: false});
			} else if (particle.kind === 'text') {
				context.font = 'bold 10px "Comic Sans MS", sans-serif';
				context.textAlign = 'center';
				context.lineWidth = 3;
				context.strokeStyle = '#000000';
				context.strokeText(particle.text, particle.x, particle.y);
				context.fillStyle = particle.color ?? '#ffdd00';
				context.fillText(particle.text, particle.x, particle.y);
				context.textAlign = 'start';
			}
		}
	}

	// The thought bubbles of the guests, a few at a time, and always the one of the guest the visitor picked.
	#drawBubbles() {
		const context = this.#context;
		const thinking = this.#guests.filter(guest => guest.thought && guest.thoughtUntil > this.#clock && guest.state !== 'riding' && guest.state !== 'floating');
		const shown = thinking.slice(-2);
		if (this.#selectedGuest && thinking.includes(this.#selectedGuest) && !shown.includes(this.#selectedGuest)) {
			shown.push(this.#selectedGuest);
		}

		context.font = '9px sans-serif';
		let stack = 0;
		for (const guest of shown) {
			// Long thoughts wrap onto a second line, so the bubble fits on the screen.
			const words = guest.thought.split(' ');
			const lines = [''];
			for (const word of words) {
				const line = lines.at(-1);
				if (line && context.measureText(`${line} ${word}`).width > 220) {
					lines.push(word);
				} else {
					lines[lines.length - 1] = line ? `${line} ${word}` : word;
				}
			}

			const width = Math.max(...lines.map(line => context.measureText(line).width)) + 8;
			const height = (lines.length * 11) + 3;
			const x = clamp(guest.x - (width / 2), 2, this.parts.canvas.width - width - 2);
			const bottom = guest.lane - 20 - stack;
			stack += height + 4;
			context.fillStyle = '#ffffff';
			context.strokeStyle = '#000000';
			context.lineWidth = 1;
			context.beginPath();
			context.roundRect(x, bottom - height, width, height, 5);
			context.fill();
			context.stroke();
			context.beginPath();
			context.moveTo(guest.x - 2, bottom);
			context.lineTo(guest.x, bottom + 5);
			context.lineTo(guest.x + 2, bottom);
			context.fill();
			context.fillStyle = '#000000';
			for (const [index, line] of lines.entries()) {
				context.fillText(line, x + 4, bottom - height + 10 + (index * 11));
			}
		}
	}

	#drawRain() {
		const context = this.#context;
		if (!this.#isRaining) {
			return;
		}

		context.strokeStyle = 'rgba(220, 230, 255, 0.5)';
		context.lineWidth = 1;
		for (let index = 0; index < 90; index++) {
			const x = ((index * 73) + (this.#clock * (this.reducedMotion ? 0 : 40))) % this.parts.canvas.width;
			const y = ((index * 131) + (this.#clock * (this.reducedMotion ? 0 : 260))) % this.parts.canvas.height;
			drawLine(context, {x, y}, {x: x - 2, y: y + 6});
		}
	}

	// The speed and the G-forces, in the corner, like the ride window of the game shows them during a test.
	#drawGauges() {
		const context = this.#context;
		const lines = [];
		if (this.#train.phase === 'running' || this.#train.phase === 'towing') {
			lines.push(`${Math.round(Math.abs(this.#train.speed) * 3.6)} km/h`, `${this.#train.vertical.toFixed(1)} G`, `${Math.abs(this.#train.lateral).toFixed(1)} G sideways`);
		}

		lines.push(`${this.#rideName()}: ${{closed: 'Closed', test: 'Testing', open: 'Open'}[this.#rideStatus]}`);
		context.font = 'bold 9px "Courier New", monospace';
		context.fillStyle = 'rgba(0, 0, 40, 0.65)';
		context.fillRect(4, 4, 128, (lines.length * 11) + 5);
		context.fillStyle = '#80ff80';
		for (const [index, line] of lines.entries()) {
			context.fillText(line, 8, 14 + (index * 11));
		}
	}

	// The ride camera: the view from the front seat, with the track ahead drawn in perspective, and the horizon tilting as the train turns over.
	#drawCamera() {
		const context = this.#context;
		const width = this.parts.canvas.width;
		const height = this.parts.canvas.height;
		const centerX = width / 2;
		const centerY = height * 0.45;
		const focal = 300;
		const point = this.#wreck ? undefined : pointAt(this.#trainTrack, this.#train.s);
		if (!point) {
			context.fillStyle = '#000000';
			context.fillRect(0, 0, width, height);
			context.fillStyle = '#ffffff';
			context.font = 'bold 14px "Courier New", monospace';
			context.textAlign = 'center';
			context.fillText('NO SIGNAL. The camera crashed with the train.', centerX, centerY);
			context.textAlign = 'start';
			return;
		}

		// The side of the track points to the left of the riders, so the screen goes the other way.
		const {forward, up, side} = point.sample;
		const eye = add(add(point, scale(up, 1.6)), scale(forward, 0.5));
		const toScreen = world => {
			const relative = subtract(world, eye);
			const depth = dot(relative, forward);
			if (depth < 0.4) {
				return undefined;
			}

			return {x: centerX - (dot(relative, side) / depth * focal), y: centerY - (dot(relative, up) / depth * focal)};
		};

		// The ground is everything below the horizon, so it is the part of the screen where the view looks down.
		const worldUp = {x: 0, y: 1, z: 0};
		const lookingUp = corner => dot(forward, worldUp) - (((corner.x - centerX) / focal) * dot(side, worldUp)) + (((centerY - corner.y) / focal) * dot(up, worldUp));
		context.fillStyle = '#8fb8d8';
		context.fillRect(0, 0, width, height);
		const corners = [{x: 0, y: 0}, {x: width, y: 0}, {x: width, y: height}, {x: 0, y: height}];
		const ground = [];
		for (const [index, corner] of corners.entries()) {
			const next = corners[(index + 1) % corners.length];
			const value = lookingUp(corner);
			const nextValue = lookingUp(next);
			if (value < 0) {
				ground.push(corner);
			}

			if ((value < 0) !== (nextValue < 0)) {
				const fraction = value / (value - nextValue);
				ground.push({x: corner.x + ((next.x - corner.x) * fraction), y: corner.y + ((next.y - corner.y) * fraction)});
			}
		}

		if (ground.length > 2) {
			context.fillStyle = '#5fa04a';
			context.beginPath();
			context.moveTo(ground[0].x, ground[0].y);
			for (const corner of ground.slice(1)) {
				context.lineTo(corner.x, corner.y);
			}

			context.fill();
		}

		// Fir trees around the park, for a sense of speed.
		context.fillStyle = '#2c5534';
		for (let index = 0; index < 40; index++) {
			const tree = {x: ((index * 37) % 190) - 20, y: 0, z: index % 2 === 0 ? 34 + ((index * 7) % 20) : -24 - ((index * 11) % 20)};
			const bottom = toScreen(tree);
			const top = toScreen({...tree, y: 7});
			if (bottom && top && Math.abs(bottom.x) < 2000) {
				const size = Math.abs(bottom.y - top.y) / 3;
				context.beginPath();
				context.moveTo(top.x, top.y);
				context.lineTo(bottom.x - size, bottom.y);
				context.lineTo(bottom.x + size, bottom.y);
				context.fill();
			}
		}

		// The track ahead, from far to near.
		const colors = this.#scheme();
		const start = sampleIndexAt(this.#trainTrack, this.#train.s);
		const count = this.#trainTrack.samples.length;
		const end = this.#trainTrack.isClosed ? count : this.#trainTrack.outEnd;
		for (let step = 400; step >= 2; step -= 2) {
			const index = this.#trainTrack.isClosed ? (start + step) % count : start + step;
			const nextIndex = this.#trainTrack.isClosed ? (index + 2) % count : index + 2;
			if (nextIndex >= end || index >= end) {
				continue;
			}

			const sample = this.#trainTrack.samples[index];
			const next = this.#trainTrack.samples[nextIndex];
			for (const offset of [0.7, -0.7]) {
				const from = toScreen(add(sample, scale(sample.side, offset)));
				const to = toScreen(add(next, scale(next.side, offset)));
				if (from && to) {
					context.strokeStyle = colors.rail;
					context.lineWidth = clamp(12 / Math.max(1, Math.hypot(...Object.values(subtract(sample, eye))) / 3), 1, 6);
					drawLine(context, from, to);
				}
			}

			if (step % 6 === 0) {
				const left = toScreen(add(sample, scale(sample.side, 0.9)));
				const right = toScreen(subtract(sample, scale(sample.side, 0.9)));
				if (left && right) {
					context.strokeStyle = sample.chain ? '#202020' : colors.track;
					context.lineWidth = 2;
					drawLine(context, left, right);
				}
			}
		}

		// The front of the car, and the hands of the riders when they scream.
		context.fillStyle = colors.train;
		context.fillRect(0, height - 34, width, 34);
		context.fillStyle = colors.trim;
		context.fillRect(0, height - 34, width, 4);
		if (this.#clock < (this.#train.screamUntil ?? 0)) {
			context.fillStyle = '#f0c8a0';
			for (const x of [180, 230, 410, 460]) {
				context.fillRect(x, height - 90, 14, 60);
			}
		}

		context.fillStyle = 'rgba(0, 0, 40, 0.65)';
		context.fillRect(width - 140, 6, 134, 38);
		context.fillStyle = '#80ff80';
		context.font = 'bold 11px "Courier New", monospace';
		context.fillText(`${Math.round(Math.abs(this.#train.speed) * 3.6)} km/h`, width - 132, 22);
		context.fillText(`${this.#train.vertical.toFixed(1)} G`, width - 132, 37);
		context.fillStyle = '#ff4040';
		context.fillText('● REC', 10, 20);
	}

	#draw() {
		if (this.#isCamera) {
			this.#drawCamera();
			return;
		}

		this.#context.drawImage(this.#sceneryLayer, 0, 0);
		this.#context.drawImage(this.#trackLayer, 0, 0);
		this.#drawGhost();
		this.#drawSpeeds();
		this.#drawTrain();
		this.#drawMerryGoRound();
		this.#drawGuests();
		this.#drawParticles();
		this.#drawBubbles();
		this.#drawRain();
		this.#drawGauges();
	}

	// The graphs of the ride window, of the last test run.
	#drawGraph() {
		const graphContext = this.#graphContext;
		const width = this.parts.graph.width;
		const height = this.parts.graph.height;
		graphContext.fillStyle = '#000000';
		graphContext.fillRect(0, 0, width, height);
		graphContext.font = '9px sans-serif';
		const series = this.#lastRun?.series;
		if (!series?.length) {
			graphContext.fillStyle = '#80ff80';
			graphContext.fillText('Test the ride to see its graphs.', 8, 18);
			return;
		}

		const column = {speed: 1, height: 2, vertical: 3, lateral: 4}[this.parts.graphKind.value] ?? 1;
		const unit = {1: 'km/h', 2: 'm', 3: 'G', 4: 'G'}[column];
		const values = series.map(row => row[column]);
		const minimum = Math.min(0, ...values);
		const maximum = Math.max(1, ...values);
		const time = series.at(-1)[0] || 1;
		const toY = value => height - 12 - ((value - minimum) / (maximum - minimum) * (height - 24));
		graphContext.strokeStyle = '#204020';
		graphContext.lineWidth = 1;
		for (let second = 0; second <= time; second += 10) {
			const x = 4 + (second / time * (width - 8));
			drawLine(graphContext, {x, y: 0}, {x, y: height});
		}

		drawLine(graphContext, {x: 0, y: toY(0)}, {x: width, y: toY(0)});
		graphContext.strokeStyle = {1: '#ffff40', 2: '#40c0ff', 3: '#ff6060', 4: '#60ff60'}[column];
		graphContext.lineWidth = 1.5;
		graphContext.beginPath();
		for (const [index, row] of series.entries()) {
			const x = 4 + (row[0] / time * (width - 8));
			if (index === 0) {
				graphContext.moveTo(x, toY(row[column]));
			} else {
				graphContext.lineTo(x, toY(row[column]));
			}
		}

		graphContext.stroke();
		graphContext.fillStyle = '#ffffff';
		graphContext.fillText(`${maximum.toFixed(column > 2 ? 1 : 0)} ${unit}`, 6, 10);
		graphContext.fillText(`${minimum.toFixed(column > 2 ? 1 : 0)} ${unit}`, 6, height - 2);
		graphContext.fillText(`${Math.round(time)} s`, width - 26, height - 2);
	}

	#showConstruction() {
		const allowed = allowedPieces(this.#track.level);
		if (!allowed[this.#selectedPiece]) {
			this.#selectedPiece = fallbackPieces.find(id => allowed[id]);
		}

		for (const [id, button] of this.#pieceButtons) {
			button.disabled = !allowed[id];
			setPressed(button, id === this.#selectedPiece);
		}

		this.parts.chain.disabled = !takesChain(this.#selectedPiece);
		setPressed(this.parts.chain, this.#isChain && takesChain(this.#selectedPiece));
		this.parts.banked.disabled = this.#selectedPiece !== 'helix';
		setPressed(this.parts.banked, this.#isBanked);
		this.#makeGhost();
		this.parts.build.textContent = `Build this (${kroner(this.#ghost.cost)})`;
		const name = `${pieceTypes[this.#selectedPiece].name}${this.#ghost.piece.chain ? ' with chain lift' : ''}${this.#selectedPiece === 'helix' ? (this.#isBanked ? ', banked' : ', not banked') : ''}`;
		if (this.#ghost.error) {
			this.parts.message.textContent = this.#ghost.error;
		} else if (this.#track.returnError) {
			this.parts.message.textContent = `Next: ${name}. Not a complete circuit yet: ${this.#track.returnError}`;
		} else {
			this.parts.message.textContent = `Next: ${name}. The track joins the station by itself along the back.`;
		}

		this.parts.demolish.disabled = this.#park.pieces.length === 0;
		this.parts.clear.textContent = this.#clearArmed ? 'Sure? Click again!' : 'Demolish all';
	}

	#showRide() {
		this.parts.ratings.replaceChildren();
		const {ratings, stats} = this.#lastRun ?? {};
		if (ratings) {
			addRow(this.parts.ratings, 'Excitement:', `${ratings.excitement.toFixed(2)} (${ratingWord(ratings.excitement)})`);
			addRow(this.parts.ratings, 'Intensity:', `${ratings.intensity.toFixed(2)} (${ratingWord(ratings.intensity)})`);
			addRow(this.parts.ratings, 'Nausea:', `${ratings.nausea.toFixed(2)} (${ratingWord(ratings.nausea)})`);
		} else if (stats && stats.result !== 'arrived') {
			addRow(this.parts.ratings, 'Ratings:', stats.result === 'derail' ? 'Test failed: the train flew off!' : 'Test failed: the train got stuck!');
		} else {
			addRow(this.parts.ratings, 'Ratings:', 'Not yet known. Test the ride!');
		}

		this.parts.stats.replaceChildren();
		if (!stats) {
			return;
		}

		addRow(this.parts.stats, 'Max speed:', `${Math.round(stats.maximumSpeed * 3.6)} km/h`);
		addRow(this.parts.stats, 'Average speed:', `${Math.round(stats.averageSpeed * 3.6)} km/h`);
		addRow(this.parts.stats, 'Ride time:', `${Math.round(stats.time)} seconds`);
		addRow(this.parts.stats, 'Ride length:', `${Math.round(stats.length)} m`);
		addRow(this.parts.stats, 'Max positive vertical G:', stats.maximumVertical.toFixed(2));
		addRow(this.parts.stats, 'Max negative vertical G:', stats.minimumVertical.toFixed(2));
		addRow(this.parts.stats, 'Max lateral G:', stats.maximumLateral.toFixed(2));
		addRow(this.parts.stats, 'Drops:', String(stats.drops));
		addRow(this.parts.stats, 'Highest drop:', `${Math.round(stats.highestDrop)} m`);
		addRow(this.parts.stats, 'Inversions:', String(stats.inversions));
		addRow(this.parts.stats, 'Airtime:', `${stats.airtime.toFixed(1)} seconds`);
		if (ratings) {
			addRow(this.parts.stats, 'Guests would pay:', `about ${kroner(this.#rideValue())}`);
		}
	}

	#showPark() {
		const month = months[this.#park.month % 12];
		const year = 1999 + Math.floor(this.#park.month / 12);
		const text = `MONEY  ${kroner(this.#park.money)}\nGUESTS ${this.#guests.length} in the park\nRIDERS ${this.#park.riders} so far\nDATE   ${month} ${year}${this.#isRaining ? ', raining' : ''}`;
		if (this.parts.money.textContent !== text) {
			this.parts.money.textContent = text;
		}

		this.parts.price.textContent = kroner(this.#park.price);
		this.parts.handyman.textContent = this.#park.handymen > 0 ? `🧹 Hire a handyman (500 kr), ${this.#park.handymen} hired` : '🧹 Hire a handyman (500 kr)';
		this.parts.loan.disabled = this.#park.loans >= 3;
	}

	#refresh() {
		this.#showConstruction();
		this.#showPark();
		if (this.reducedMotion || this.#isPaused || !this.isVisible) {
			this.#draw();
		}
	}

	#rebuild() {
		this.#track = compileTrack(this.#park.pieces);
		if (this.#train.phase === 'stopped' || this.#wreck) {
			this.#trainTrack = this.#track;
		}

		this.#lastRun = undefined;
		this.#park.isTested = false;
		this.#drawTrackLayer();
		this.#keep();
		this.#showRide();
		this.#refresh();
	}

	// Building and demolishing need a closed ride with the train at the station. Only demolishing works while it runs, like the famous trick of the game.
	#isTrainBusy() {
		return !this.#wreck && this.#train.phase !== 'stopped';
	}

	#closeForConstruction() {
		if (this.#rideStatus !== 'closed' && !this.#isTrainBusy()) {
			this.#closeRide();
			this.say(`${this.#rideName()} is closed for construction.`);
		}
	}

	#build() {
		if (this.#isTrainBusy()) {
			this.parts.message.textContent = 'Can’t build while the train is running! Close the ride, and wait for the train.';
			this.say(this.parts.message.textContent);
			return;
		}

		this.#makeGhost();
		if (this.#ghost.error) {
			this.say(this.#ghost.error);
			return;
		}

		if (this.#park.money < this.#ghost.cost) {
			this.say(`Not enough cash: requires ${kroner(this.#ghost.cost)}. Ask Pappa for a loan!`);
			return;
		}

		this.#closeForConstruction();
		this.#park.money -= this.#ghost.cost;
		this.#park.pieces.push({...this.#ghost.piece, isPaid: true});
		this.#audio.build();
		this.#rebuild();
		this.say(`Built: ${pieceTypes[this.#ghost.piece.type].name} for ${kroner(this.#ghost.cost)}.${this.#track.isClosed ? '' : ` ${this.#track.returnError}`}`);
	}

	#demolish() {
		if (this.#park.pieces.length === 0) {
			this.say('There is nothing left to demolish, except the station.');
			return;
		}

		if (this.#wreck?.isFlying) {
			return;
		}

		const index = this.#park.pieces.length - 1;
		const refund = refundOf(this.#park.pieces[index]);
		if (this.#train.phase === 'running' && !this.#wreck) {
			// The test run was for the longer track, so its ratings must not come back.
			this.#pendingRun = undefined;
			// The famous trick: the track in front of the train is gone, so it flies off when it gets there.
			const cut = this.#trainTrack.samples[this.#trainTrack.pieceStarts[index]].s;
			const front = ((this.#train.s % this.#trainTrack.length) + this.#trainTrack.length) % this.#trainTrack.length;
			this.#park.pieces.pop();
			this.#park.money += refund;
			this.#audio.bulldozer();
			if (front >= cut - 1) {
				this.#train.cut = 0;
				this.#rebuild();
				this.#crash();
			} else {
				this.#train.cut = cut;
				this.#rebuild();
				this.say(`Uh oh. You demolished the track in front of the running train of ${this.#rideName()}…`);
			}

			return;
		}

		this.#closeForConstruction();
		this.#park.pieces.pop();
		this.#park.money += refund;
		this.#audio.bulldozer();
		this.#rebuild();
		this.say(refund > 0 ? `Demolished the last piece, and got ${kroner(refund)} back.` : 'Demolished the last piece. Pappa built it for free, so there is no money back.');
	}

	// One second of the park, in small steps, for the Step button and for visitors who prefer reduced motion.
	#stepOnce() {
		for (let index = 0; index < 30; index++) {
			this.#update(1 / 30);
		}

		// The rumble of the wheels stops with the park, as the park does not go on by itself.
		this.#audio.setRumble(0);
		this.#draw();
		this.#showPark();
	}

	// What a guest thinks right now, for the visitor who clicks them.
	#currentThought(guest) {
		if (guest.thought && guest.thoughtUntil > this.#clock - 4) {
			return guest.thought;
		}

		if (guest.state === 'queue') {
			return `I’m queuing for ${this.#rideName()}`;
		}

		if (guest.state === 'lost') {
			return 'I’m lost!';
		}

		if (guest.isSick) {
			return 'I feel sick';
		}

		return randomItem(['I’m hungry. Is there a waffle stand?', 'I want a balloon', 'This park is really nice', 'My feet hurt', 'I’m thirsty', 'Where is the toilet?']);
	}

	#pickGuest(guest) {
		this.#selectedGuest = guest;
		if (!guest) {
			return;
		}

		const text = this.#currentThought(guest);
		guest.thought = text;
		guest.thoughtUntil = this.#clock + 4;
		this.say(`${guest.name}${guest.rides > 0 ? `, who rode ${guest.rides} ${guest.rides === 1 ? 'time' : 'times'},` : ''} thinks: “${text}”`);
		this.#refresh();
	}

	// For visitors who prefer reduced motion, the park holds still, and the Step button moves it on.
	#applyMotion() {
		this.parts.pause.disabled = this.reducedMotion;
		if (this.reducedMotion) {
			this.#isShowingSpeeds = true;
			setPressed(this.parts.speeds, true);
			setPressed(this.parts.pause, true);
			this.parts.pause.textContent = 'Paused (less motion)';
			this.#draw();
		} else {
			setPressed(this.parts.pause, this.#isPaused);
			this.parts.pause.textContent = 'Pause';
		}
	}
}
