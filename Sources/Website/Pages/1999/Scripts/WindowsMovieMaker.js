// 3D Movie Maker on the desktop of the 1999 page, like the movie studio of Microsoft Kids (1995): a set in fake 3D, with a floor in perspective and actors that get smaller further back, three or four camera angles for each set, and a clock that runs while the visitor drags an actor, which records its path frame by frame. A movie is a list of scenes, and a scene has a set, a camera, actors with their paths and actions, and events at frames: speech balloons, sound effects, titles, and camera cuts. McZee, the guide of the studio, and his talking hand speak in the status balloon. Nothing makes a sound until the visitor presses the Sound button.

const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const pad = number => String(number).padStart(3, '0');

// A number from 0 to 1 that is always the same for the same seed, for the stones, the stars, and the rain, so they do not jump around between frames.
const noiseAt = seed => {
	const value = Math.sin(seed * 12.9898) * 43_758.5453;
	return value - Math.floor(value);
};

// The stage is 480 × 300, like the studio of the real one, drawn at twice the pixels, so the text is sharp.
const stageWidth = 480;
const stageHeight = 300;
const pixelRatio = 2;

// The movie runs at 10 frames a second, about as fast as the real one ran on a Pentium.
const frameTime = 100;
const sayFrames = 25;
const titleFrames = 30;
const effectFrames = 10;
const endFrames = 25;
const shortestScene = 20;
const longestScene = 600;
const maximumActors = 6;
const maximumScenes = 12;

// The floor of a set: x goes from left to right, and z from the front (0) to the back (1). The actors stay on this part of it.
const floorLimits = {left: -1.2, right: 1.2, front: -0.1, back: 1.1};
const roomWidth = 1.3;
const roomBack = 1.2;
const roomFront = -1;

// A point of the set on the stage: the floor turns around its middle by the yaw of the camera, and a point further away is closer to the horizon and smaller. `scale` is how many pixels one unit of the set is at that point.
const project = (camera, x, y, z) => {
	const cosine = Math.cos(camera.yaw);
	const sine = Math.sin(camera.yaw);
	const middleZ = z - 0.5;
	const turnedX = (x * cosine) - (middleZ * sine);
	const turnedZ = (x * sine) + (middleZ * cosine);
	const depth = Math.max(camera.distance + turnedZ, 0.2);
	const scale = camera.focal / depth;
	return {x: (stageWidth / 2) + (turnedX * scale), y: camera.horizon + ((camera.height - y) * scale), scale, depth};
};

// The other way around: the spot on the floor under a point of the stage, for a drag.
const floorAt = (camera, stageX, stageY) => {
	const cosine = Math.cos(camera.yaw);
	const sine = Math.sin(camera.yaw);
	const depth = (camera.height * camera.focal) / Math.max(stageY - camera.horizon, 4);
	const turnedX = ((stageX - (stageWidth / 2)) * depth) / camera.focal;
	const turnedZ = depth - camera.distance;
	return {
		x: clamp((turnedX * cosine) + (turnedZ * sine), floorLimits.left, floorLimits.right),
		z: clamp((-turnedX * sine) + (turnedZ * cosine) + 0.5, floorLimits.front, floorLimits.back),
	};
};

// The drawing tools.
const tracePolygon = (context, points) => {
	context.beginPath();
	context.moveTo(points[0].x, points[0].y);

	for (const point of points.slice(1)) {
		context.lineTo(point.x, point.y);
	}

	context.closePath();
};

const fillPolygon = (context, points, fill) => {
	tracePolygon(context, points);
	context.fillStyle = fill;
	context.fill();
};

// A face of a box or a wall that turns its back to the camera goes the other way around on the stage, so it is not drawn.
const isFacing = points => {
	let area = 0;

	for (const [index, point] of points.entries()) {
		const next = points[(index + 1) % points.length];
		area += (point.x * next.y) - (next.x * point.y);
	}

	return area < 0;
};

const floorQuad = (camera, x0, z0, x1, z1) => [project(camera, x0, 0, z0), project(camera, x1, 0, z0), project(camera, x1, 0, z1), project(camera, x0, 0, z1)];
const backQuad = (camera, x0, x1, y0, y1, z = roomBack) => [project(camera, x0, y0, z), project(camera, x1, y0, z), project(camera, x1, y1, z), project(camera, x0, y1, z)];

const floorEllipse = (camera, centerX, centerZ, radiusX, radiusZ) => Array.from({length: 16}, (_, index) => {
	const angle = (index / 16) * Math.PI * 2;
	return project(camera, centerX + (Math.cos(angle) * radiusX), 0, centerZ + (Math.sin(angle) * radiusZ));
});

const line = (context, from, to, color, lineWidth = 1) => {
	context.beginPath();
	context.moveTo(from.x, from.y);
	context.lineTo(to.x, to.y);
	context.strokeStyle = color;
	context.lineWidth = lineWidth;
	context.stroke();
};

const circle = (context, x, y, radius, fill) => {
	context.beginPath();
	context.arc(x, y, radius, 0, Math.PI * 2);
	context.fillStyle = fill;
	context.fill();
};

const ellipse = (context, x, y, radiusX, radiusY, fill, rotation = 0) => {
	context.beginPath();
	context.ellipse(x, y, radiusX, radiusY, rotation, 0, Math.PI * 2);
	context.fillStyle = fill;
	context.fill();
};

const shape = (context, points, fill) => {
	context.beginPath();
	context.moveTo(points[0][0], points[0][1]);

	for (const [x, y] of points.slice(1)) {
		context.lineTo(x, y);
	}

	context.closePath();
	context.fillStyle = fill;
	context.fill();
};

// An arm or a leg from a joint, where the angle 0 points down and a positive angle points forward.
const limb = (context, x, y, angle, length, lineWidth, color) => {
	context.beginPath();
	context.moveTo(x, y);
	context.lineTo(x + (Math.sin(angle) * length), y + (Math.cos(angle) * length));
	context.strokeStyle = color;
	context.lineWidth = lineWidth;
	context.lineCap = 'round';
	context.stroke();
	return {x: x + (Math.sin(angle) * length), y: y + (Math.cos(angle) * length)};
};

// A box on the floor, like a counter or a coffin, with the faces that the camera sees.
const box = (context, camera, {x0, x1, z0, z1, y0 = 0, y1, top, front, side}) => {
	const corner = (x, y, z) => project(camera, x, y, z);
	const faces = [
		[[corner(x0, y0, z0), corner(x1, y0, z0), corner(x1, y1, z0), corner(x0, y1, z0)], front],
		[[corner(x1, y0, z1), corner(x0, y0, z1), corner(x0, y1, z1), corner(x1, y1, z1)], front],
		[[corner(x0, y0, z1), corner(x0, y0, z0), corner(x0, y1, z0), corner(x0, y1, z1)], side],
		[[corner(x1, y0, z0), corner(x1, y0, z1), corner(x1, y1, z1), corner(x1, y1, z0)], side],
		[[corner(x0, y1, z0), corner(x1, y1, z0), corner(x1, y1, z1), corner(x0, y1, z1)], top],
	];

	for (const [points, color] of faces) {
		if (isFacing(points)) {
			fillPolygon(context, points, color);
		}
	}
};

// A room with a back wall, the side walls that the camera sees from inside, and a floor. A side wall seen from outside is left out, like the open side of a set in a studio.
const room = (context, camera, {ceiling, wall, side, floor, wallHeight}) => {
	context.fillStyle = ceiling;
	context.fillRect(0, 0, stageWidth, stageHeight);
	const left = [project(camera, -roomWidth, 0, roomFront), project(camera, -roomWidth, 0, roomBack), project(camera, -roomWidth, wallHeight, roomBack), project(camera, -roomWidth, wallHeight, roomFront)];
	const right = [project(camera, roomWidth, 0, roomBack), project(camera, roomWidth, 0, roomFront), project(camera, roomWidth, wallHeight, roomFront), project(camera, roomWidth, wallHeight, roomBack)];

	for (const points of [left, right]) {
		if (isFacing(points)) {
			fillPolygon(context, points, side);
		}
	}

	fillPolygon(context, backQuad(camera, -roomWidth, roomWidth, 0, wallHeight), wall);
	fillPolygon(context, floorQuad(camera, -roomWidth, roomFront, roomWidth, roomBack), floor);
};

// Text on a wall, as big as the wall is near.
const wallText = (context, camera, text, x, y, size, color, font = 'bold %px Arial, sans-serif') => {
	const point = project(camera, x, y, roomBack);
	context.font = font.replace('%', String(Math.max(size * point.scale, 4).toFixed(1)));
	context.textAlign = 'center';
	context.textBaseline = 'middle';
	context.fillStyle = color;
	context.fillText(text, point.x, point.y);
};

const rainbow = ['#ff3b3b', '#ff9f1c', '#ffe03b', '#3bd16f', '#3b8bff', '#a35bff'];

// The actors, drawn facing right with their feet at 0 and their heads at about -100, and turned around when they walk left. A pose has the angles of the legs and the arms, and how high the actor is lifted, tilted, squashed, or fallen over.
const drawSindre = (context, pose) => {
	const backFoot = limb(context, -3, -44, pose.backLeg, 40, 9, '#1c3d7a');
	ellipse(context, backFoot.x + 3, backFoot.y + 1, 7, 3.5, '#3b2a1c');
	limb(context, -2, -76, pose.backArm, 27, 7, '#8e1b1b');
	const frontFoot = limb(context, 3, -44, pose.frontLeg, 40, 9, '#2652a8');
	ellipse(context, frontFoot.x + 3, frontFoot.y + 1, 7, 3.5, '#4a3523');

	// A red Norwegian knitted sweater with a white band, like every kid in Bergen had.
	context.beginPath();
	context.roundRect(-13, -82, 26, 42, 6);
	context.fillStyle = '#c62828';
	context.fill();
	context.fillStyle = '#ffffff';

	for (let x = -11; x <= 8; x += 6) {
		context.fillRect(x, -78, 3, 3);
		context.fillRect(x + 3, -74, 3, 3);
	}

	circle(context, 2, -91, 12, '#f6cfa8');
	context.beginPath();
	context.arc(1, -93, 12.5, Math.PI, Math.PI * 2);
	context.lineTo(14, -90);
	context.lineTo(7, -96);
	context.lineTo(-1, -91);
	context.lineTo(-11, -88);
	context.closePath();
	context.fillStyle = '#f4d24a';
	context.fill();
	circle(context, 8, -91, 1.8, '#1a1a1a');
	circle(context, 10, -86, 2.5, 'rgba(255, 120, 120, 0.5)');
	context.beginPath();
	context.arc(6, -87, 4, 0.3, Math.PI - 0.9);
	context.strokeStyle = '#7a3a2a';
	context.lineWidth = 1.5;
	context.stroke();
	const hand = limb(context, 3, -76, pose.frontArm, 27, 7, '#e53935');
	circle(context, hand.x, hand.y, 4, '#f6cfa8');
};

const drawGlitter = (context, pose, frame) => {
	limb(context, -18, -50, pose.frontLeg, 44, 7, '#e1d2ee');
	limb(context, 18, -50, pose.backLeg, 44, 7, '#e1d2ee');

	for (const [index, color] of rainbow.entries()) {
		context.beginPath();
		context.moveTo(-28, -62 + (index * 1.5));
		context.quadraticCurveTo(-50, -60 + (index * 2) + (Math.sin(frame * 0.8) * 4), -42, -28 + (index * 2));
		context.strokeStyle = color;
		context.lineWidth = 2.5;
		context.lineCap = 'round';
		context.stroke();
	}

	ellipse(context, 0, -58, 31, 15, '#ffffff');
	context.strokeStyle = '#c9a0dc';
	context.lineWidth = 1.5;
	context.stroke();

	for (const [x, angle] of [[-13, pose.backLeg], [23, pose.frontLeg]]) {
		const hoof = limb(context, x, -50, angle, 44, 7, '#ffffff');
		circle(context, hoof.x, hoof.y, 4, '#ff8fc8');
	}

	shape(context, [[15, -66], [27, -86], [39, -82], [30, -55]], '#ffffff');
	ellipse(context, 38, -84, 13, 8, '#ffffff', 0.5);
	ellipse(context, 46, -78, 6, 5, '#ffe4f2');
	shape(context, [[32, -92], [38, -94], [42, -110]], '#ffd700');
	context.beginPath();
	context.moveTo(34, -97);
	context.lineTo(39, -98);
	context.moveTo(36, -102);
	context.lineTo(40, -103);
	context.strokeStyle = '#d4a017';
	context.lineWidth = 1;
	context.stroke();

	for (const [index, color] of rainbow.entries()) {
		circle(context, 22 + (index * 2.2), -64 - (index * 4.5), 5, color);
	}

	circle(context, 38, -86, 2.2, '#222222');
	circle(context, 48, -79, 1, '#c06090');

	// Glitter glitters.
	if (frame % 4 < 2) {
		context.fillStyle = '#fff6a0';
		context.font = 'bold 12px Arial, sans-serif';
		context.textAlign = 'center';
		context.fillText('✦', 50, -104);
	}
};

const drawRocky = (context, pose, frame) => {
	context.beginPath();
	context.moveTo(-30, 0);
	context.quadraticCurveTo(-50, -4, -44, -40);
	context.quadraticCurveTo(-36, -78, 0, -82);
	context.quadraticCurveTo(40, -86, 46, -48);
	context.quadraticCurveTo(52, -6, 30, 0);
	context.closePath();
	context.fillStyle = '#8d8d8d';
	context.fill();
	context.strokeStyle = '#4d4d4d';
	context.lineWidth = 3;
	context.stroke();

	for (const [x, y, radius] of [[-24, -30, 6], [-10, -16, 4], [30, -24, 5], [-28, -56, 3]]) {
		circle(context, x, y, radius, '#767676');
	}

	// Googly eyes, which wobble when he moves.
	const wobbleX = Math.sin(frame * 1.7) * 3;
	const wobbleY = Math.cos(frame * 1.3) * 3;
	circle(context, 10, -56, 13, '#ffffff');
	circle(context, 10 + wobbleX, -54 + wobbleY, 6, '#111111');
	circle(context, 34, -52, 11, '#ffffff');
	circle(context, 34 + (wobbleX * 0.8), -50 + wobbleY, 5, '#111111');
	context.beginPath();
	context.arc(22, -34, 10, 0.3, Math.PI - 0.3);
	context.strokeStyle = '#222222';
	context.lineWidth = 3;
	context.stroke();

	if (pose.lift > 2 || pose.tilt !== 0) {
		context.beginPath();
		context.arc(22, -30, 5, 0, Math.PI);
		context.fillStyle = '#5a0f0f';
		context.fill();
	}
};

const drawSeagull = (context, pose, frame) => {
	limb(context, -2, -30, pose.backLeg, 30, 3, '#d9821b');
	limb(context, 6, -30, pose.frontLeg, 30, 3, '#f5a623');
	shape(context, [[-26, -48], [-48, -58], [-46, -40]], '#9aa3ad');
	ellipse(context, 0, -46, 30, 17, '#ffffff');
	context.strokeStyle = '#c5ccd3';
	context.lineWidth = 1.5;
	context.stroke();

	if (pose.flap > 0) {
		const angle = Math.sin(frame * 2.2) * 0.9 * pose.flap;
		context.save();
		context.translate(-2, -56);
		context.rotate(-angle - 0.2);
		shape(context, [[0, 0], [-42, -26], [-30, 4]], '#8f99a4');
		shape(context, [[-42, -26], [-34, -20], [-36, -12]], '#222222');
		context.restore();
	} else {
		ellipse(context, -6, -48, 22, 9, '#a7b0ba', -0.15);
		ellipse(context, -24, -46, 6, 4, '#222222', -0.15);
	}

	circle(context, 24, -66, 12, '#ffffff');
	circle(context, 28, -69, 2.2, '#111111');
	line(context, {x: 23, y: -74}, {x: 32, y: -72}, '#555555', 1.5);
	shape(context, [[33, -68], [56, -63], [33, -59]], '#f7c11e');
	circle(context, 46, -62, 2, '#d0021b');
};

const drawRobot = (context, pose, frame) => {
	const backFoot = limb(context, -7, -40, pose.backLeg, 36, 9, '#6c7a7d');
	context.fillStyle = '#4f5b5d';
	context.fillRect(backFoot.x - 6, backFoot.y - 3, 14, 6);
	limb(context, -6, -74, pose.backArm, 28, 6, '#6c7a7d');
	const frontFoot = limb(context, 7, -40, pose.frontLeg, 36, 9, '#8a9a9d');
	context.fillStyle = '#5f6b6d';
	context.fillRect(frontFoot.x - 6, frontFoot.y - 3, 14, 6);
	context.fillStyle = '#a9b7ba';
	context.fillRect(-18, -80, 36, 42);
	context.strokeStyle = '#4f5b5d';
	context.lineWidth = 2;
	context.strokeRect(-18, -80, 36, 42);
	context.fillStyle = '#2c3e50';
	context.fillRect(-11, -72, 22, 14);
	const lights = ['#ff4040', '#40ff40', '#ffd040'];

	for (const [index, color] of lights.entries()) {
		circle(context, -6 + (index * 6), -65, 2.2, (frame + index) % 3 === 0 ? color : '#34495e');
	}

	context.fillStyle = '#c3cfd1';
	context.fillRect(-13, -99, 26, 18);
	context.strokeRect(-13, -99, 26, 18);
	context.fillStyle = '#111111';
	context.fillRect(-9, -94, 22, 7);
	circle(context, 4 + (Math.sin(frame * 0.5) * 5), -90.5, 2.5, '#ff2a2a');
	line(context, {x: 0, y: -99}, {x: 0, y: -105}, '#4f5b5d', 2);
	circle(context, 0, -106, 3, frame % 4 < 2 ? '#ffee44' : '#ff8800');
	const hand = limb(context, 7, -74, pose.frontArm, 28, 6, '#8a9a9d');
	context.beginPath();
	context.arc(hand.x, hand.y, 5, 0.5, Math.PI * 1.6);
	context.strokeStyle = '#4f5b5d';
	context.lineWidth = 3;
	context.stroke();
};

// The cast, with the height in units of the set, the width of a sprite next to its height, and the voice when the sound is on.
const cast = {
	sindre: {name: 'Sindre', height: 0.56, width: 0.4, draw: drawSindre, voice: {pitch: 1.4, rate: 1.1}},
	glitter: {name: 'Glitter', height: 0.56, width: 0.95, draw: drawGlitter, voice: {pitch: 2, rate: 1.15}},
	rocky: {name: 'Rocky', height: 0.26, width: 1, draw: drawRocky, voice: {pitch: 0.1, rate: 0.6}},
	seagull: {name: 'The seagull', height: 0.34, width: 1, draw: drawSeagull, voice: {pitch: 1.8, rate: 1.4}},
	robot: {name: 'The robot', height: 0.6, width: 0.45, draw: drawRobot, voice: {pitch: 0.3, rate: 0.8}},
};

const actionNames = ['stand', 'walk', 'run', 'jump', 'dance', 'wave', 'fall'];

// The pose of an actor at a frame, by its action and how many frames ago the action started. Rocky has no legs, so he hops, and the seagull flies when it jumps.
const poseOf = (kind, action, local, frame) => {
	const pose = {frontLeg: 0.05, backLeg: -0.05, frontArm: 0.15, backArm: -0.15, lift: 0, tilt: 0, squash: 1, flap: 0, fallen: 0};
	const swing = Math.sin(frame * 0.9);

	if (action === 'walk') {
		pose.frontLeg = swing * 0.45;
		pose.backLeg = -swing * 0.45;
		pose.frontArm = -swing * 0.4;
		pose.backArm = swing * 0.4;
		pose.lift = Math.abs(Math.cos(frame * 0.9)) * (kind === 'rocky' ? 14 : 2);
	} else if (action === 'run') {
		const fast = Math.sin(frame * 1.5);
		pose.frontLeg = fast * 0.85;
		pose.backLeg = -fast * 0.85;
		pose.frontArm = -fast * 1;
		pose.backArm = fast * 1;
		pose.tilt = 0.18;
		pose.lift = Math.abs(Math.cos(frame * 1.5)) * (kind === 'rocky' ? 20 : 5);
	} else if (action === 'jump') {
		const phase = (local % 8) / 8;
		pose.lift = Math.sin(phase * Math.PI) * (kind === 'seagull' ? 80 : 45);
		pose.frontLeg = 0.6;
		pose.backLeg = -0.4;
		pose.frontArm = 2.7;
		pose.backArm = 2.5;
		pose.flap = 1;
		pose.squash = phase < 0.1 ? 0.85 : 1;
	} else if (action === 'dance') {
		const beat = Math.sin(frame * 0.8);
		pose.tilt = beat * 0.2;
		pose.frontArm = 2.5 + (beat * 0.5);
		pose.backArm = 2.5 - (beat * 0.5);
		pose.frontLeg = beat * 0.35;
		pose.backLeg = -0.1;
		pose.lift = Math.abs(beat) * 6;
		pose.flap = Math.abs(beat);
	} else if (action === 'wave') {
		pose.frontArm = 2.6 + (Math.sin(frame * 1.4) * 0.45);
		pose.flap = kind === 'seagull' ? 0.5 : 0;
		pose.tilt = kind === 'rocky' ? Math.sin(frame * 1.4) * 0.25 : 0;
	} else if (action === 'fall') {
		pose.fallen = Math.min(local / 4, 1);
		pose.frontArm = 1.4;
		pose.backArm = 1.2;
	}

	return pose;
};

// The props of the sets, drawn like the actors, with their feet at 0 and their tops at -100.
const drawCandelabra = (context, time) => {
	ellipse(context, 0, -2, 16, 4, '#8b6508');
	context.fillStyle = '#b8860b';
	context.fillRect(-3, -80, 6, 78);
	context.beginPath();
	context.moveTo(-20, -84);
	context.quadraticCurveTo(-20, -66, 0, -66);
	context.quadraticCurveTo(20, -66, 20, -84);
	context.strokeStyle = '#b8860b';
	context.lineWidth = 4;
	context.stroke();

	for (const [index, x] of [-20, 0, 20].entries()) {
		const top = x === 0 ? -96 : -88;
		context.fillStyle = '#f5f0dc';
		context.fillRect(x - 3, top, 6, x === 0 ? 16 : 6);
		const flicker = Math.sin((time / 90) + (index * 2)) * 1.5;
		const glow = context.createRadialGradient(x, top - 6, 1, x, top - 6, 16);
		glow.addColorStop(0, 'rgba(255, 210, 90, 0.5)');
		glow.addColorStop(1, 'rgba(255, 210, 90, 0)');
		circle(context, x, top - 6, 16, glow);
		ellipse(context, x, top - 6 + (flicker / 2), 3.5, 6 + flicker, '#ffcc33');
	}
};

const drawGhost = (context, time) => {
	context.globalAlpha = 0.75;
	context.beginPath();
	context.moveTo(-30, -10);
	context.lineTo(-30, -70);
	context.arc(0, -70, 30, Math.PI, 0);
	context.lineTo(30, -10);

	for (let x = 30; x > -30; x -= 15) {
		context.quadraticCurveTo(x - 7.5, -10 + (Math.sin((time / 200) + x) * 8), x - 15, -10);
	}

	context.closePath();
	context.fillStyle = '#f4f4ff';
	context.fill();
	context.globalAlpha = 1;
	ellipse(context, -10, -72, 5, 8, '#111122');
	ellipse(context, 10, -72, 5, 8, '#111122');
	ellipse(context, 0, -50, 6, 8, '#111122');
};

const drawStool = context => {
	ellipse(context, 0, -2, 12, 3, '#777777');
	context.fillStyle = '#c0c0c0';
	context.fillRect(-2, -88, 4, 86);
	ellipse(context, 0, -92, 16, 6, '#d0021b');
	ellipse(context, 0, -95, 16, 5, '#ff2e3d');
};

const drawJukebox = (context, time) => {
	context.beginPath();
	context.moveTo(-34, 0);
	context.lineTo(-34, -66);
	context.arc(0, -66, 34, Math.PI, 0);
	context.lineTo(34, 0);
	context.closePath();
	context.fillStyle = '#7a3b12';
	context.fill();

	const shift = Math.floor(time / 250);

	for (const index of rainbow.keys()) {
		context.beginPath();
		context.arc(0, -66, 30 - (index * 3), Math.PI, 0);
		context.strokeStyle = rainbow[(index + shift) % rainbow.length];
		context.lineWidth = 2.5;
		context.stroke();
	}

	context.fillStyle = '#f5deb3';
	context.fillRect(-20, -66, 40, 20);
	context.fillStyle = '#333333';

	for (let y = -40; y < -6; y += 5) {
		context.fillRect(-24, y, 48, 2);
	}
};

const drawWaffles = context => {
	ellipse(context, 0, -10, 50, 12, '#f8f8f8');

	// Five hearts, like a Norwegian waffle, with a slice of brown cheese on top.
	for (const [index, x] of [-28, -14, 0, 14, 28].entries()) {
		context.save();
		context.translate(x, -30 - (index % 2) * 4);
		context.rotate((index - 2) * 0.35);
		context.beginPath();
		context.moveTo(0, 14);
		context.bezierCurveTo(-16, 2, -10, -14, 0, -6);
		context.bezierCurveTo(10, -14, 16, 2, 0, 14);
		context.fillStyle = '#e0a84a';
		context.fill();
		context.restore();
	}

	context.fillStyle = '#b5651d';
	context.fillRect(-10, -46, 20, 8);
};

const drawConsoleLights = (context, time) => {
	context.fillStyle = '#0a2a0a';
	context.fillRect(-40, -96, 80, 50);
	context.beginPath();

	for (let x = -36; x <= 36; x += 2) {
		const y = -71 + (Math.sin((x / 6) + (time / 200)) * 14);

		if (x === -36) {
			context.moveTo(x, y);
		} else {
			context.lineTo(x, y);
		}
	}

	context.strokeStyle = '#33ff66';
	context.lineWidth = 2;
	context.stroke();

	for (let index = 0; index < 6; index++) {
		const isOn = Math.floor((time / 300) + (index * 1.7)) % 3 === 0;
		circle(context, -35 + (index * 14), -30, 5, isOn ? ['#ff3b3b', '#ffe03b', '#3bd16f'][index % 3] : '#333b48');
	}
};

const drawPlant = (context, time) => {
	context.fillStyle = '#b06030';
	context.beginPath();
	context.moveTo(-20, -30);
	context.lineTo(20, -30);
	context.lineTo(14, 0);
	context.lineTo(-14, 0);
	context.closePath();
	context.fill();

	for (let index = 0; index < 5; index++) {
		const sway = Math.sin((time / 500) + index) * 0.25;
		context.save();
		context.translate(0, -30);
		context.rotate(((index - 2) * 0.4) + sway);
		context.beginPath();
		context.moveTo(0, 0);
		context.quadraticCurveTo(12, -40, 0, -66);
		context.strokeStyle = '#b44dff';
		context.lineWidth = 6;
		context.lineCap = 'round';
		context.stroke();
		circle(context, 0, -66, 6, '#ff7bf0');
		context.restore();
	}
};

const drawLamp = context => {
	context.fillStyle = '#20302a';
	context.fillRect(-3, -86, 6, 86);
	ellipse(context, 0, -2, 10, 3, '#20302a');
	const glow = context.createRadialGradient(0, -92, 2, 0, -92, 30);
	glow.addColorStop(0, 'rgba(255, 220, 120, 0.7)');
	glow.addColorStop(1, 'rgba(255, 220, 120, 0)');
	circle(context, 0, -92, 30, glow);
	shape(context, [[-9, -86], [9, -86], [7, -100], [-7, -100]], '#ffe9a0');
	shape(context, [[-11, -100], [11, -100], [0, -108]], '#20302a');
};

const drawTrashCan = context => {
	shape(context, [[-30, -90], [30, -90], [24, 0], [-24, 0]], '#2e7d32');

	for (let x = -18; x <= 18; x += 12) {
		line(context, {x, y: -84}, {x: x * 0.85, y: -6}, '#1b5e20', 3);
	}

	ellipse(context, 0, -92, 33, 8, '#388e3c');
};

// The sets, each with its cameras, a painter for the walls and the floor, props that the actors walk in front of and behind, and things in front of all, like rain. `yaw` turns the floor, `distance` is how far back the camera is, `height` is how high it is, `focal` is the zoom, and `horizon` is where the floor ends far away.
const sets = {
	haunted: {
		name: 'Haunted House',
		emoji: '🏚️',
		cameras: [
			{name: 'Front Hall', yaw: 0, distance: 2.4, height: 0.9, focal: 300, horizon: 70},
			{name: 'Low and Spooky', yaw: 0.3, distance: 2.3, height: 0.3, focal: 320, horizon: 170},
			{name: 'From the Stairs', yaw: -0.5, distance: 2.6, height: 1.8, focal: 280, horizon: 10},
			{name: 'Behind the Coffin', yaw: 0.65, distance: 2.6, height: 1, focal: 300, horizon: 70},
		],
		paint(context, camera, time, isReducedMotion) {
			room(context, camera, {ceiling: '#120a1c', wall: '#3b2650', side: '#2c1c3d', floor: '#4a2f1d', wallHeight: 1.7});

			for (let x = -roomWidth; x < roomWidth; x += 0.2) {
				fillPolygon(context, backQuad(camera, x, x + 0.1, 0, 1.7), 'rgba(0, 0, 0, 0.15)');
			}

			for (let x = -roomWidth; x <= roomWidth; x += 0.16) {
				line(context, project(camera, x, 0, roomFront), project(camera, x, 0, roomBack), '#2e1c10', 1);
			}

			// The window, where lightning flashes now and then, but not for visitors who prefer less motion.
			const isLightning = !isReducedMotion && (time % 5200) < 120;
			fillPolygon(context, backQuad(camera, -0.45, 0.25, 0.7, 1.45), isLightning ? '#e8ecff' : '#141b38');
			const moon = project(camera, -0.25, 1.25, roomBack);
			circle(context, moon.x, moon.y, 6 * moon.scale / 100, '#f4f1c9');
			line(context, project(camera, -0.1, 0.7, roomBack), project(camera, -0.1, 1.45, roomBack), '#1a0f0a', 3);
			line(context, project(camera, -0.45, 1.07, roomBack), project(camera, 0.25, 1.07, roomBack), '#1a0f0a', 3);

			// A portrait of an old man, whose eyes follow the visitor.
			fillPolygon(context, backQuad(camera, 0.55, 1, 0.65, 1.3), '#c9a227');
			fillPolygon(context, backQuad(camera, 0.6, 0.95, 0.7, 1.25), '#2a1f14');
			const face = project(camera, 0.775, 1.02, roomBack);
			const faceSize = face.scale / 100;
			ellipse(context, face.x, face.y, 9 * faceSize, 12 * faceSize, '#b9a68a');
			const look = Math.sin(time / 1300) * 1.5 * faceSize;
			circle(context, face.x - (3.5 * faceSize) + look, face.y - (2 * faceSize), 1.4 * faceSize, '#000000');
			circle(context, face.x + (3.5 * faceSize) + look, face.y - (2 * faceSize), 1.4 * faceSize, '#000000');

			// Cobwebs in the corners.
			for (const side of [-1, 1]) {
				const corner = project(camera, side * roomWidth, 1.7, roomBack);
				const size = 18 * corner.scale / 100;

				for (let index = 0; index <= 4; index++) {
					const angle = (Math.PI / 2) * (index / 4);
					line(context, corner, {x: corner.x - (side * Math.cos(angle) * size * 3), y: corner.y + (Math.sin(angle) * size * 3)}, 'rgba(220, 220, 220, 0.5)', 0.8);
				}

				for (let ring = 1; ring <= 3; ring++) {
					context.beginPath();
					context.arc(corner.x, corner.y, ring * size, side > 0 ? Math.PI / 2 : 0, side > 0 ? Math.PI : Math.PI / 2);
					context.strokeStyle = 'rgba(220, 220, 220, 0.4)';
					context.lineWidth = 0.8;
					context.stroke();
				}
			}
		},
		props: [
			{x: -0.95, z: 0.95, height: 0.55, draw: drawCandelabra},
			{x: 0.75, z: 1.01, box: {x0: 0.45, x1: 1.05, z0: 0.92, z1: 1.1, y1: 0.16, top: '#5a3a22', front: '#3e2716', side: '#4a2f1b'}},
			{x: 0, z: 0.85, y: 0.25, height: 0.35, draw: drawGhost, place: time => ({x: Math.sin(time / 2300) * 0.8, y: 0.25 + (Math.sin(time / 400) * 0.04)})},
		],
	},
	diner: {
		name: 'Diner',
		emoji: '🍔',
		cameras: [
			{name: 'Booth', yaw: 0, distance: 2.3, height: 0.8, focal: 300, horizon: 80},
			{name: 'At the Counter', yaw: -0.45, distance: 2.4, height: 0.5, focal: 310, horizon: 120},
			{name: 'Bird’s Eye', yaw: 0.25, distance: 2.6, height: 2, focal: 270, horizon: -10},
		],
		paint(context, camera, time, isReducedMotion) {
			room(context, camera, {ceiling: '#2b1b12', wall: '#7fd1c7', side: '#6bbcb2', floor: '#f4f4f4', wallHeight: 1.5});

			// The checkered floor of a diner.
			for (let column = 0; column < 13; column++) {
				for (let row = 0; row < 11; row++) {
					if ((column + row) % 2 === 0) {
						const x = -roomWidth + (column * 0.2);
						const z = roomFront + (row * 0.2);
						fillPolygon(context, floorQuad(camera, x, z, x + 0.2, z + 0.2), '#1d1d1d');
					}
				}
			}

			fillPolygon(context, backQuad(camera, -roomWidth, roomWidth, 0, 0.4), '#c0392b');
			line(context, project(camera, -roomWidth, 0.4, roomBack), project(camera, roomWidth, 0.4, roomBack), '#e0e0e0', 2);

			// A window to the street, where it rains, of course.
			fillPolygon(context, backQuad(camera, -1.2, -0.6, 0.6, 1.15), '#8fa3b5');

			for (let index = 0; index < 8; index++) {
				const x = -1.15 + (noiseAt(index) * 0.5);
				const y = 0.62 + ((((time / 1500) + noiseAt(index + 9)) % 1) * 0.5);
				line(context, project(camera, x, y + 0.04, roomBack), project(camera, x - 0.01, y, roomBack), '#dbe8f5', 1);
			}

			// The neon sign blinks off now and then.
			fillPolygon(context, backQuad(camera, -0.35, 0.45, 1.05, 1.38), '#1a1a1a');
			const isNeonOn = isReducedMotion || (time % 4100) > 300;
			wallText(context, camera, 'DINER', 0.05, 1.215, 0.17, isNeonOn ? '#ff4fd8' : '#552244', 'bold %px "Arial Black", Arial, sans-serif');

			fillPolygon(context, backQuad(camera, 0.65, 1.2, 0.6, 1.15), '#222222');
			wallText(context, camera, 'MENY', 0.925, 1.06, 0.07, '#ffffff', 'bold %px "Comic Sans MS", cursive');
			wallText(context, camera, 'Vafler 10 kr', 0.925, 0.92, 0.055, '#ffe08a', '%px "Comic Sans MS", cursive');
			wallText(context, camera, 'Kaffe 8 kr', 0.925, 0.8, 0.055, '#ffe08a', '%px "Comic Sans MS", cursive');
			wallText(context, camera, 'Pølse 15 kr', 0.925, 0.68, 0.055, '#ffe08a', '%px "Comic Sans MS", cursive');
		},
		props: [
			{x: -0.35, z: 1.05, box: {x0: -1.1, x1: 0.4, z0: 0.95, z1: 1.15, y1: 0.32, top: '#e8e8e8', front: '#d35400', side: '#a04000'}},
			{x: -0.4, z: 1.05, y: 0.32, height: 0.1, draw: drawWaffles},
			{x: -0.85, z: 0.85, height: 0.26, draw: drawStool},
			{x: -0.45, z: 0.85, height: 0.26, draw: drawStool},
			{x: -0.05, z: 0.85, height: 0.26, draw: drawStool},
			{x: 1.02, z: 1.02, height: 0.5, draw: drawJukebox},
		],
	},
	space: {
		name: 'Space Station',
		emoji: '🚀',
		cameras: [
			{name: 'Bridge', yaw: 0, distance: 2.4, height: 0.9, focal: 300, horizon: 75},
			{name: 'Low Orbit', yaw: 0.4, distance: 2.4, height: 0.35, focal: 320, horizon: 160},
			{name: 'Wide', yaw: -0.3, distance: 3.1, height: 1.1, focal: 300, horizon: 80},
			{name: 'Security Camera', yaw: 0.6, distance: 2.6, height: 2.1, focal: 270, horizon: -5},
		],
		paint(context, camera, time, isReducedMotion) {
			room(context, camera, {ceiling: '#1b1f2a', wall: '#3d4655', side: '#333b48', floor: '#59606b', wallHeight: 1.6});

			for (let x = -roomWidth; x <= roomWidth; x += 0.26) {
				line(context, project(camera, x, 0, roomFront), project(camera, x, 0, roomBack), '#3a4048', 1.5);
				line(context, project(camera, x, 0, roomBack), project(camera, x, 1.6, roomBack), '#2f3642', 1.5);
			}

			for (let z = roomFront; z <= roomBack; z += 0.26) {
				line(context, project(camera, -roomWidth, 0, z), project(camera, roomWidth, 0, z), '#3a4048', 1.5);
			}

			fillPolygon(context, floorQuad(camera, -roomWidth, -0.25, roomWidth, -0.2), '#e0b000');

			// The big window, with stars that drift by, and the Earth, where Norway is.
			const glass = backQuad(camera, -0.85, 0.85, 0.5, 1.4);
			context.save();
			fillPolygon(context, glass, '#04050d');
			context.clip();
			const drift = (camera.yaw * 200) + (time / 80);

			for (let index = 0; index < 60; index++) {
				const x = ((noiseAt(index) * 700) + drift) % 700 - 110;
				const y = noiseAt(index + 100) * 200;
				circle(context, x, y, noiseAt(index + 200) * 1.2 + 0.3, '#ffffff');
			}

			const earth = project(camera, 0.35, 0.8, roomBack + 2);
			const earthRadius = 0.45 * earth.scale;
			circle(context, earth.x, earth.y, earthRadius, '#2a6fdb');
			ellipse(context, earth.x - (earthRadius * 0.2), earth.y - (earthRadius * 0.5), earthRadius * 0.25, earthRadius * 0.4, '#3bb25a', -0.4);
			ellipse(context, earth.x + (earthRadius * 0.4), earth.y + (earthRadius * 0.1), earthRadius * 0.3, earthRadius * 0.2, '#3bb25a');
			context.restore();
			tracePolygon(context, glass);
			context.strokeStyle = '#a0a8b8';
			context.lineWidth = 3;
			context.stroke();
			fillPolygon(context, backQuad(camera, 0.95, 1.25, 0.95, 1.15), '#e0b000');
			wallText(context, camera, 'DECK 7', 1.1, 1.05, 0.06, '#111111');
		},
		props: [
			{x: -0.875, z: 0.99, box: {x0: -1.15, x1: -0.6, z0: 0.88, z1: 1.1, y1: 0.28, top: '#2b3440', front: '#4b5868', side: '#3a4553'}},
			{x: -0.875, z: 0.87, y: 0.06, height: 0.2, draw: drawConsoleLights},
			{x: 1, z: 0.9, height: 0.38, draw: drawPlant},
		],
	},
	bergen: {
		name: 'Rainy Bergen Street',
		emoji: '☔',
		cameras: [
			{name: 'Bryggen', yaw: 0, distance: 2.4, height: 0.8, focal: 300, horizon: 90},
			{name: 'Down by the Puddle', yaw: -0.35, distance: 2.3, height: 0.25, focal: 320, horizon: 175},
			{name: 'From Mormor’s Window', yaw: 0.45, distance: 2.7, height: 1.9, focal: 280, horizon: 0},
		],
		paint(context, camera, time, isReducedMotion) {
			const sky = context.createLinearGradient(0, 0, 0, stageHeight);
			sky.addColorStop(0, '#6c7884');
			sky.addColorStop(1, '#b9c2c9');
			context.fillStyle = sky;
			context.fillRect(0, 0, stageWidth, stageHeight);

			// The mountain Fløyen behind the town, which moves less than the street when the camera turns.
			const mountain = [];

			for (let index = 0; index <= 12; index++) {
				const x = -3 + (index * 0.5);
				mountain.push(project(camera, x, 1.3 + (Math.sin(index * 1.3) * 0.25) + (index === 6 ? 0.4 : 0), roomBack + 3));
			}

			mountain.push(project(camera, 3, 0, roomBack + 3), project(camera, -3, 0, roomBack + 3));
			fillPolygon(context, mountain, '#4d5e55');

			// The cobblestones of the street, and the sidewalk in front of the houses.
			fillPolygon(context, floorQuad(camera, -2.4, roomFront, 2.4, roomBack), '#686c70');

			for (let column = 0; column < 30; column++) {
				for (let row = 0; row < 15; row++) {
					const x = -2.4 + (column * 0.16) + (row % 2 === 0 ? 0 : 0.08);
					const z = roomFront + (row * 0.135);

					if (z < 1) {
						const shade = Math.floor(noiseAt((column * 31) + row) * 3);
						fillPolygon(context, floorQuad(camera, x + 0.01, z + 0.01, x + 0.15, z + 0.125), ['#5c6064', '#73777c', '#7f8388'][shade]);
					}
				}
			}

			fillPolygon(context, floorQuad(camera, -2.4, 1, 2.4, roomBack), '#8a8f94');

			// The wooden houses of Bryggen, with pointed roofs, in their colors.
			const colors = ['#b03a2e', '#e5b33d', '#f2efe6', '#c0562f', '#d9c27a', '#b03a2e', '#f2efe6', '#e5b33d'];

			for (const [index, color] of colors.entries()) {
				const x0 = -2.08 + (index * 0.52);
				const x1 = x0 + 0.5;
				const top = 0.95 + (noiseAt(index + 40) * 0.2);
				fillPolygon(context, backQuad(camera, x0, x1, 0, top), color);
				fillPolygon(context, [project(camera, x0 - 0.02, top, roomBack), project(camera, x1 + 0.02, top, roomBack), project(camera, (x0 + x1) / 2, top + 0.3, roomBack)], '#3b2f2a');

				for (const windowY of [0.45, 0.72]) {
					for (const windowX of [x0 + 0.08, x1 - 0.18]) {
						fillPolygon(context, backQuad(camera, windowX, windowX + 0.1, windowY, windowY + 0.14), '#ffffff');
						fillPolygon(context, backQuad(camera, windowX + 0.015, windowX + 0.085, windowY + 0.015, windowY + 0.125), index % 3 === 0 ? '#ffe9a0' : '#3d4a5c');
					}
				}

				fillPolygon(context, backQuad(camera, ((x0 + x1) / 2) - 0.06, ((x0 + x1) / 2) + 0.06, 0, 0.26), '#4a2f1d');
			}

			fillPolygon(context, backQuad(camera, -0.5, -0.04, 0.3, 0.4), '#2b1d14');
			wallText(context, camera, 'BRYGGEN', -0.27, 0.35, 0.065, '#f2d34f', 'bold %px Georgia, serif');

			// Puddles, with rings where the rain falls in.
			for (const [x, z, radius] of [[-0.6, 0.25, 0.18], [0.55, 0.6, 0.14], [0.1, -0.05, 0.12]]) {
				fillPolygon(context, floorEllipse(camera, x, z, radius, radius * 0.6), '#8ea2b4');
				const ring = ((time / 900) + x) % 1;
				tracePolygon(context, floorEllipse(camera, x, z, radius * ring, radius * 0.6 * ring));
				context.strokeStyle = `rgba(230, 240, 255, ${(1 - ring).toFixed(2)})`;
				context.lineWidth = 1;
				context.stroke();
			}
		},
		props: [
			{x: 0.95, z: 0.85, height: 0.95, draw: drawLamp},
			{x: -1.05, z: 0.9, height: 0.22, draw: drawTrashCan},
		],
		// It always rains in Bergen.
		overlay(context, time) {
			context.strokeStyle = 'rgba(220, 232, 255, 0.55)';
			context.lineWidth = 1;
			context.beginPath();

			for (let index = 0; index < 90; index++) {
				const x = noiseAt(index) * (stageWidth + 60);
				const y = ((noiseAt(index + 300) * stageHeight) + (time * 0.45)) % (stageHeight + 20) - 20;
				context.moveTo(x, y);
				context.lineTo(x - 4, y + 12);
			}

			context.stroke();
		},
	},
};

// The words of the sound effects, drawn like in a comic, so the sound is also seen with the sound off.
const effects = {
	boing: {word: 'BOING!', color: '#ffe600'},
	crash: {word: 'CRASH!', color: '#ff3b1f'},
	laugh: {word: 'HA HA HA!', color: '#7dff7d'},
	applause: {word: 'CLAP CLAP!', color: '#7fd4ff'},
};

const newScene = (set = 'bergen') => ({set, camera: 0, length: 1, actors: [], events: []});
// A new movie starts with me on the set, so the first drag already films something.
const newMovie = () => ({scenes: [{...newScene(), actors: [{id: 1, kind: 'sindre', facing: 1, path: [[0, -0.6, 0.3]], actions: [[0, 'stand']]}]}]});

const pathPointAt = (actor, frame) => {
	let found = actor.path[0];

	for (const point of actor.path) {
		if (point[0] > frame) {
			break;
		}

		found = point;
	}

	return found;
};

const actionAt = (actor, frame) => {
	let found = [0, 'stand'];

	for (const entry of actor.actions) {
		if (entry[0] > frame) {
			break;
		}

		found = entry;
	}

	return found;
};

// An actor is on the stage from the first frame of its path.
const isOnStage = (actor, frame) => actor.path.length > 0 && actor.path[0][0] <= frame;

const cameraAt = (scene, frame) => {
	let camera = scene.camera;

	for (const event of scene.events) {
		if (event.type === 'camera' && event.frame <= frame) {
			camera = event.camera;
		}
	}

	return Math.min(camera, sets[scene.set].cameras.length - 1);
};

// An actor faces the way it last walked on the stage.
const facingAt = (camera, actor, frame) => {
	let facing = actor.facing;
	let previousX;

	for (const [pointFrame, x, z] of actor.path) {
		if (pointFrame > frame) {
			break;
		}

		const stageX = project(camera, x, 0, z).x;

		if (previousX !== undefined && Math.abs(stageX - previousX) > 0.3) {
			facing = stageX > previousX ? 1 : -1;
		}

		previousX = stageX;
	}

	return facing;
};

const extendScene = (scene, lastFrame) => {
	scene.length = clamp(Math.max(scene.length, lastFrame + 1), 1, longestScene);
};

const sortByFrame = items => items.sort((first, second) => (first[0] ?? first.frame) - (second[0] ?? second.frame));

// Wraps the text of a speech balloon in lines that fit.
const wrapText = (context, text, maximumWidth) => {
	const lines = [];
	let current = '';
	const fits = candidate => context.measureText(candidate).width <= maximumWidth;

	for (const word of text.split(' ')) {
		const candidate = current ? `${current} ${word}` : word;

		if (fits(candidate)) {
			current = candidate;
			continue;
		}

		if (current) {
			lines.push(current);
		}

		// The word starts a new line, and a word that is too long for a line, like “AAAAAAAAAAAAAAAAAAAH!”, is cut, so the balloon stays on the stage.
		current = '';

		for (const character of word) {
			if (current && !fits(current + character)) {
				lines.push(current);
				current = '';
			}

			current += character;
		}
	}

	if (current) {
		lines.push(current);
	}

	return lines;
};

// The stage shrinks on a phone, so the text that the visitor must read grows with it, to at least 10 CSS pixels. At the full size it stays as it is. `zoom` is how many pixels of the stage one CSS pixel is.
const readableScale = (baseSize, zoom) => Math.max(1, (10 / baseSize) * zoom);

const drawBalloon = (context, text, headX, headY, zoom) => {
	const scale = readableScale(12, zoom);
	context.font = `${12 * scale}px "Comic Sans MS", "Comic Sans", cursive`;
	context.textAlign = 'left';
	context.textBaseline = 'top';
	const lines = wrapText(context, text, 140 * scale);
	const lineHeight = 14 * scale;
	let widest = 0;

	for (const textLine of lines) {
		widest = Math.max(widest, context.measureText(textLine).width);
	}

	const boxWidth = widest + 16;
	const boxHeight = (lines.length * lineHeight) + 10;
	const x = clamp(headX - (boxWidth / 2), 4, stageWidth - boxWidth - 4);
	const y = clamp(headY - boxHeight - 16, 4, stageHeight - boxHeight - 30);
	const tailX = clamp(headX, x + 12, x + boxWidth - 12);
	context.beginPath();
	context.roundRect(x, y, boxWidth, boxHeight, 10);
	context.moveTo(tailX - 6, y + boxHeight);
	context.lineTo(clamp(headX, 4, stageWidth - 4), Math.max(headY - 4, y + boxHeight + 4));
	context.lineTo(tailX + 6, y + boxHeight);
	context.fillStyle = '#ffffff';
	context.fill();
	context.strokeStyle = '#000000';
	context.lineWidth = 1.5;
	context.stroke();
	context.fillStyle = '#ffffff';
	context.fillRect(tailX - 5, y + boxHeight - 2, 10, 3);
	context.fillStyle = '#000000';

	for (const [index, textLine] of lines.entries()) {
		context.fillText(textLine, x + 8, y + 5 + (index * lineHeight));
	}
};

// 3D letters that spin in one after the other, with a deep golden side, like the 3D words of the real one.
const drawTitle = (context, text, local, centerY, size = 34) => {
	context.font = `${size}px Impact, "Arial Black", sans-serif`;
	context.textAlign = 'center';
	context.textBaseline = 'middle';
	const letters = [...text];
	const widths = letters.map(letter => context.measureText(letter).width + 2);
	let total = 0;

	for (const letterWidth of widths) {
		total += letterWidth;
	}

	// A long title gets smaller, so it fits on the stage.
	const fit = Math.min(1, (stageWidth - 30) / total);
	let x = (stageWidth / 2) - (total * fit / 2);
	const fade = local > titleFrames - 5 && local < titleFrames ? (titleFrames - local) / 5 : 1;
	context.globalAlpha = fade;

	for (const [index, letter] of letters.entries()) {
		const letterWidth = widths[index] * fit;
		const time = local - (index * 1.2);

		if (time >= 0) {
			const spin = clamp(time / 7, 0, 1);
			const angle = (1 - spin) * Math.PI * 3;
			const grow = 1 + ((1 - spin) * 1.5);
			context.save();
			context.translate(x + (letterWidth / 2), centerY);
			context.scale(Math.cos(angle) * grow * fit, grow * fit);

			for (let depth = 6; depth >= 1; depth--) {
				context.fillStyle = depth > 3 ? '#5a2600' : '#8a4300';
				context.fillText(letter, depth * 0.9, depth * 0.9);
			}

			const gradient = context.createLinearGradient(0, -size / 2, 0, size / 2);
			gradient.addColorStop(0, '#fff7a8');
			gradient.addColorStop(0.5, '#ffc21a');
			gradient.addColorStop(1, '#ff7b00');
			context.fillStyle = Math.cos(angle) < 0 ? '#b36b00' : gradient;
			context.fillText(letter, 0, 0);
			context.strokeStyle = '#3a1800';
			context.lineWidth = 1;
			context.strokeText(letter, 0, 0);
			context.restore();
		}

		x += letterWidth;
	}

	context.globalAlpha = 1;
};

const drawEffectWord = (context, effect, local, index) => {
	const {word, color} = effects[effect];
	const grow = 1 + (Math.max(0, 1 - (local / 3)) * 0.7);
	const x = 380 - (index * 30);
	const y = 52 + (index * 40);
	context.save();
	context.translate(x, y);
	context.rotate(-0.15);
	context.scale(grow, grow);
	context.beginPath();

	for (let point = 0; point < 24; point++) {
		const angle = (point / 24) * Math.PI * 2;
		const radius = point % 2 === 0 ? 62 : 44;
		context.lineTo(Math.cos(angle) * radius, Math.sin(angle) * radius * 0.55);
	}

	context.closePath();
	context.fillStyle = color;
	context.fill();
	context.strokeStyle = '#000000';
	context.lineWidth = 2;
	context.stroke();
	context.font = '18px Impact, "Arial Black", sans-serif';
	context.textAlign = 'center';
	context.textBaseline = 'middle';
	context.fillStyle = '#000000';
	context.fillText(word, 0, 1);
	context.restore();
};

const drawActor = (context, camera, actor, frame, point) => {
	const kind = cast[actor.kind];
	const [actionFrame, action] = actionAt(actor, frame);
	const pose = poseOf(actor.kind, action, frame - actionFrame, frame);
	const scale = (kind.height * point.scale) / 100;
	const facing = facingAt(camera, actor, frame);
	context.save();
	context.translate(point.x, point.y);
	context.scale(scale * facing, scale * pose.squash);
	context.translate(0, -pose.lift);
	context.rotate(pose.tilt + (pose.fallen * Math.PI / 2));
	kind.draw(context, pose, frame);
	context.restore();
	const spriteHeight = 100 * scale;
	const spriteWidth = kind.width * 100 * scale;
	const top = point.y - (pose.lift * scale) - (spriteHeight * (pose.fallen > 0.5 ? 0.45 : 1));
	return {id: actor.id, left: point.x - (spriteWidth / 2) - 6, right: point.x + (spriteWidth / 2) + 6, top: top - 6, bottom: point.y + 6, footX: point.x, footY: point.y, headX: point.x, headY: top};
};

// Draws a frame of a scene: the set, the shadows, the props and the actors from the back to the front, and then the balloons, the sound effects, and the titles. While editing, the picked actor has a ring and its path. It gives the boxes of the actors on the stage, where a click picks one.
const drawFrame = (context, scene, frame, time, {isEditing = false, isRecording = false, pickedId, zoom = 1, isReducedMotion = false} = {}) => {
	const set = sets[scene.set];
	const cameraNumber = cameraAt(scene, frame);
	const camera = set.cameras[cameraNumber];
	context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
	context.globalAlpha = 1;
	set.paint(context, camera, time, isReducedMotion);
	const actors = scene.actors.filter(actor => isOnStage(actor, frame));
	const drawables = [];
	const layout = [];

	for (const actor of actors) {
		const [, x, z] = pathPointAt(actor, frame);
		const point = project(camera, x, 0, z);
		const radius = cast[actor.kind].width * cast[actor.kind].height * 0.45;
		fillPolygon(context, floorEllipse(camera, x, z, Math.max(radius, 0.06), 0.05), 'rgba(0, 0, 0, 0.3)');

		if (isEditing && actor.id === pickedId) {
			tracePolygon(context, floorEllipse(camera, x, z, Math.max(radius, 0.06) + 0.04, 0.08));
			context.setLineDash([4, 3]);
			context.strokeStyle = '#ffff00';
			context.lineWidth = 2;
			context.stroke();
			context.setLineDash([]);

			for (const [index, [, pathX, pathZ]] of actor.path.entries()) {
				if (index % 2 === 0) {
					const dot = project(camera, pathX, 0, pathZ);
					circle(context, dot.x, dot.y, 1.5, 'rgba(255, 255, 0, 0.8)');
				}
			}
		}

		drawables.push({depth: point.depth, draw: () => layout.push(drawActor(context, camera, actor, frame, point))});
	}

	for (const prop of set.props) {
		const place = prop.place?.(time) ?? {};
		const point = project(camera, place.x ?? prop.x, place.y ?? prop.y ?? 0, prop.z);
		drawables.push({
			depth: point.depth,
			draw() {
				if (prop.box) {
					box(context, camera, prop.box);
					return;
				}

				const scale = (prop.height * point.scale) / 100;
				context.save();
				context.translate(point.x, point.y);
				context.scale(scale, scale);
				prop.draw(context, time);
				context.restore();
			},
		});
	}

	drawables.sort((first, second) => second.depth - first.depth);

	for (const drawable of drawables) {
		drawable.draw();
	}

	set.overlay?.(context, time);

	for (const event of scene.events) {
		const local = frame - event.frame;

		if (event.type === 'say' && local >= 0 && local < sayFrames) {
			const speaker = layout.find(entry => entry.id === event.actor);

			if (speaker) {
				drawBalloon(context, event.text, speaker.headX, speaker.headY, zoom);
			}
		}
	}

	let effectIndex = 0;

	for (const event of scene.events) {
		const local = frame - event.frame;

		if (event.type === 'sound' && local >= 0 && local < effectFrames) {
			drawEffectWord(context, event.sound, local, effectIndex);
			effectIndex++;
		}
	}

	let titleIndex = 0;

	for (const event of scene.events) {
		const local = frame - event.frame;

		if (event.type === 'title' && local >= 0 && local < titleFrames) {
			drawTitle(context, event.text, local, 70 + (titleIndex * 50));
			titleIndex++;
		}
	}

	if (isEditing) {
		context.font = 'bold 11px Arial, sans-serif';
		context.textAlign = 'left';
		context.textBaseline = 'top';
		context.fillStyle = 'rgba(0, 0, 0, 0.55)';
		const label = `📷 ${cameraNumber + 1}: ${camera.name}`;
		context.fillRect(4, 4, context.measureText(label).width + 10, 17);
		context.fillStyle = '#ffffff';
		context.fillText(label, 9, 7);

		if (isRecording) {
			circle(context, stageWidth - 52, 13, 5, '#ff2020');
			context.fillStyle = '#ffffff';
			context.fillText('REC', stageWidth - 43, 7);
		}

		// The first step, on the stage itself, until the scene has something in it.
		const hint = actors.length === 0 ? 'Add an actor in the 🎭 Actors drawer!' : (scene.length === 1 ? 'Drag an actor across the floor!' : undefined);

		if (hint && scene.events.length === 0) {
			const scale = readableScale(14, zoom);
			context.font = `bold ${14 * scale}px "Comic Sans MS", cursive`;
			context.textAlign = 'center';
			context.fillStyle = 'rgba(0, 0, 0, 0.6)';
			const hintWidth = Math.min(Math.max(stageWidth - 140, context.measureText(hint).width + 20), stageWidth - 8);
			context.fillRect((stageWidth - hintWidth) / 2, stageHeight - 18 - (26 * scale), hintWidth, 26 * scale);
			context.fillStyle = '#ffff99';
			context.fillText(hint, stageWidth / 2, stageHeight - 18 - (20 * scale));
		}
	}

	return layout;
};

// The end of the movie: red curtains, and “The End” in spinning 3D letters.
const drawEnd = (context, local, director) => {
	context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
	context.fillStyle = '#000000';
	context.fillRect(0, 0, stageWidth, stageHeight);
	const open = Math.min(local / 6, 1) * 0.3;

	for (const side of [0, 1]) {
		const curtainWidth = stageWidth * (0.5 - open);
		const x = side === 0 ? 0 : stageWidth - curtainWidth;
		context.fillStyle = '#9b0d14';
		context.fillRect(x, 0, curtainWidth, stageHeight);

		for (let fold = x + 10; fold < x + curtainWidth; fold += 20) {
			context.fillStyle = 'rgba(0, 0, 0, 0.25)';
			context.fillRect(fold, 0, 6, stageHeight);
		}
	}

	drawTitle(context, 'The End', local, 120, 48);

	if (local > 10) {
		context.font = '14px "Comic Sans MS", cursive';
		context.textAlign = 'center';
		context.fillStyle = '#ffffff';
		context.fillText(`Directed by ${director}`, stageWidth / 2, 190);
		context.font = '11px Arial, sans-serif';
		context.fillStyle = '#c0c0c0';
		context.fillText('Made with Microsoft 3D Movie Maker', stageWidth / 2, 212);
	}
};

// McZee, the lanky alien guide of the studio, and his hand, which has a mouth and opinions. Each line says who says it (`guide.who`), and the one who talks moves his mouth for a moment, until `guide.until`.
const drawGuide = (context, time, guide, isReducedMotion) => {
	context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
	context.clearRect(0, 0, 64, 96);
	const isTalking = time < guide.until;
	const isMouthOpen = isTalking && !isReducedMotion && Math.floor(time / 130) % 2 === 0;
	const bob = isReducedMotion ? 0 : Math.sin(time / 600) * 1;
	const paint = (fill, draw) => {
		context.beginPath();
		draw();
		context.fillStyle = fill;
		context.fill();
	};

	// Long purple legs and a yellow vest.
	context.strokeStyle = '#6a3fa0';
	context.lineWidth = 5;
	context.lineCap = 'round';
	context.beginPath();
	context.moveTo(26, 64);
	context.lineTo(22, 93);
	context.moveTo(34, 64);
	context.lineTo(38, 93);
	context.stroke();
	paint('#ffcc00', () => {
		context.roundRect(21, 40 + bob, 18, 26, 4);
	});
	context.strokeStyle = '#4caf9a';
	context.lineWidth = 3;
	context.beginPath();
	context.moveTo(22, 44 + bob);
	context.quadraticCurveTo(12, 56, 16, 68);
	context.moveTo(38, 44 + bob);
	context.quadraticCurveTo(48, 40, 50, 30);
	context.stroke();
	context.fillStyle = '#4caf9a';
	context.fillRect(28, 32 + bob, 4, 10);

	// The head, long and green, with big eyes.
	paint('#5cc9b0', () => {
		context.ellipse(30, 20 + bob, 11, 15, 0, 0, Math.PI * 2);
	});
	paint('#ff5fa2', () => {
		context.ellipse(30, 5 + bob, 8, 4, 0, 0, Math.PI * 2);
	});
	paint('#ffffff', () => {
		context.ellipse(25, 17 + bob, 4, 5, 0, 0, Math.PI * 2);
		context.ellipse(35, 17 + bob, 4, 5, 0, 0, Math.PI * 2);
	});
	paint('#111111', () => {
		context.arc(26, 18 + bob, 2, 0, Math.PI * 2);
		context.arc(36, 18 + bob, 2, 0, Math.PI * 2);
	});

	if (guide.who === 'McZee' && isMouthOpen) {
		paint('#3a0a1a', () => {
			context.ellipse(30, 28 + bob, 4, 3, 0, 0, Math.PI * 2);
		});
	} else {
		context.strokeStyle = '#1d5c4f';
		context.lineWidth = 1.5;
		context.beginPath();
		context.arc(30, 25 + bob, 4, 0.3, Math.PI - 0.3);
		context.stroke();
	}

	// The hand, up beside his head, with eyes, and a mouth between the thumb and the fingers.
	const handOpen = guide.who === 'The Hand' && isMouthOpen ? 4 : 1;
	paint('#5cc9b0', () => {
		context.ellipse(52, 24 - handOpen, 9, 5, -0.2, 0, Math.PI * 2);
	});
	paint('#4caf9a', () => {
		context.ellipse(52, 32 + handOpen, 8, 4, 0.1, 0, Math.PI * 2);
	});
	paint('#ffffff', () => {
		context.arc(50, 20 - handOpen, 2.5, 0, Math.PI * 2);
		context.arc(56, 20 - handOpen, 2.5, 0, Math.PI * 2);
	});
	paint('#111111', () => {
		context.arc(50.5, 20.5 - handOpen, 1.2, 0, Math.PI * 2);
		context.arc(56.5, 20.5 - handOpen, 1.2, 0, Math.PI * 2);
	});
};

// What McZee and the hand say.
const lines = {
	welcome: ['McZee', 'Welcome to the 3D Movie Maker studio! Sindre is on the set. Drag him across the floor, and the clock runs while you drag. Then press ▶ Play.'],
	welcomeBack: ['McZee', 'Welcome back! Your movie waited for you in the vault. Press ▶ Play to see it again.'],
	tips: [
		['McZee', 'Drag an actor while the clock runs to record its path. Let go to stop the clock.'],
		['McZee', 'Try another camera! A new camera in the middle of a scene is a cut, like in a real movie.'],
		['McZee', 'Pick an action in the 🎭 Actors drawer, like Dance. It starts at the frame you are on.'],
		['McZee', 'Titles spin in with 3D letters. Every great movie needs a title. Or at least a “THE END”.'],
		['McZee', 'Put a laugh track after a joke. Then everybody knows that it was a joke.'],
		['McZee', 'Make a new scene in the 🎬 Scenes drawer. The movie plays all the scenes, one after the other.'],
		['The Hand', 'Psst. Save your movie in the 📁 Portfolio, or Mamma turns off the computer and it is gone.'],
		['The Hand', 'I am not a sock. I am a hand with eyes. There is a difference.'],
		['McZee', 'Rocky has no legs. He is a rock. But with the magic of the movies, he can walk!'],
		['The Hand', 'The balloons talk out loud when the sound is on. The robot has the best voice. Do not tell the others.'],
		['McZee', 'Toy Story was made on 117 computers. You have one. That is plenty.'],
		['The Hand', 'The seagulls of Bergen steal waffles. That is not a movie. That is a documentary.'],
		['McZee', 'No mouse? The arrow keys move the picked actor one frame at a time, and N picks the next one.'],
		['McZee', 'Want to see how the pros do it? Watch “The Waffle Heist” in the 📁 Portfolio.'],
	],
	actors: {
		sindre: ['McZee', 'Sindre is on the set! He is the star, the director, and the boy who has to be in bed by nine.'],
		glitter: ['McZee', 'Glitter the unicorn! Feed her a waffle, and she does her own stunts.'],
		rocky: ['The Hand', 'Rocky the pet rock joined the cast. Great actor. Very calm. He never forgets a line.'],
		seagull: ['McZee', 'A seagull from the fish market. Watch your waffles.'],
		robot: ['McZee', 'The robot runs Windows 98. Please do not let it crash. Or do. Crashes are funny.'],
	},
	actions: {
		stand: ['McZee', 'Standing still. A bold choice.'],
		walk: ['McZee', 'Walking. A classic.'],
		run: ['McZee', 'Run! Something must be after them.'],
		jump: ['McZee', 'Up they go! Add the Boing sound for extra boing.'],
		dance: ['The Hand', 'Look at those moves! I would dance too, but I am a hand.'],
		wave: ['McZee', 'Hi, Mormor!'],
		fall: ['The Hand', 'Ouch. Quick, add the laugh track!'],
	},
	effects: {
		boing: ['McZee', 'BOING! The finest sound of 1995.'],
		crash: ['The Hand', 'CRASH! I hope that was not the good china.'],
		laugh: ['McZee', 'The laugh track! Now it is funny. Officially.'],
		applause: ['The Hand', 'Applause! Thank you, thank you, I am here all week.'],
	},
	reviews: [
		['McZee', 'Bravo! Two thumbs up! The hand gives it two more.'],
		['The Hand', 'I laughed, I cried, I ate all the popcorn.'],
		['McZee', 'A masterpiece! I am calling Hollywood. Long distance, so do not tell Pappa.'],
		['McZee', 'Wonderful! Even Rocky moved. Well, you moved him. Still!'],
	],
};

// A saved movie comes from the storage of the browser, where it could be broken or old, so only the parts that make sense are kept.
const cleanMovie = value => {
	if (!Array.isArray(value?.scenes) || value.scenes.length === 0) {
		return undefined;
	}

	const scenes = value.scenes.slice(0, maximumScenes).map(scene => {
		const actors = (Array.isArray(scene?.actors) ? scene.actors : [])
			.filter(actor => Object.hasOwn(cast, actor?.kind) && Array.isArray(actor.path))
			.slice(0, maximumActors)
			.map((actor, index) => ({
				id: Number.isInteger(actor.id) ? actor.id : index + 1,
				kind: actor.kind,
				facing: actor.facing === -1 ? -1 : 1,
				path: sortByFrame(actor.path
					.filter(point => Array.isArray(point) && point.length === 3 && point.every(number => Number.isFinite(number)))
					.slice(0, longestScene + 1)
					.map(([frame, x, z]) => [clamp(Math.round(frame), 0, longestScene), clamp(x, -2, 2), clamp(z, -0.5, 1.5)])),
				actions: sortByFrame((Array.isArray(actor.actions) ? actor.actions : [])
					.filter(entry => Array.isArray(entry) && Number.isFinite(entry[0]) && actionNames.includes(entry[1]))
					.slice(0, 200)
					.map(([frame, action]) => [clamp(Math.round(frame), 0, longestScene), action])),
			}))
			.filter(actor => actor.path.length > 0);

		const events = (Array.isArray(scene?.events) ? scene.events : [])
			.filter(event => Number.isFinite(event?.frame))
			.slice(0, 300)
			.map(event => {
				const frame = clamp(Math.round(event.frame), 0, longestScene);

				if (event.type === 'say' && typeof event.text === 'string' && Number.isInteger(event.actor)) {
					return {frame, type: 'say', actor: event.actor, text: event.text.slice(0, 50)};
				}

				if (event.type === 'title' && typeof event.text === 'string') {
					return {frame, type: 'title', text: event.text.slice(0, 24)};
				}

				if (event.type === 'sound' && Object.hasOwn(effects, event.sound)) {
					return {frame, type: 'sound', sound: event.sound};
				}

				if (event.type === 'camera' && Number.isInteger(event.camera)) {
					return {frame, type: 'camera', camera: clamp(event.camera, 0, 3)};
				}

				return undefined;
			})
			.filter(Boolean);

		return {
			set: Object.hasOwn(sets, scene?.set) ? scene.set : 'bergen',
			camera: Number.isInteger(scene?.camera) ? clamp(scene.camera, 0, 3) : 0,
			length: Number.isFinite(scene?.length) ? clamp(Math.round(scene.length), 1, longestScene) : 1,
			actors,
			events: sortByFrame(events),
		};
	});

	return {scenes};
};

// “The Waffle Heist”, the premade movie: a seagull steals my waffle on Bryggen and flees to space, where Rocky waits.
const walk = (from, to, startFrame, endFrame) => Array.from({length: endFrame - startFrame + 1}, (_, index) => {
	const progress = index / Math.max(endFrame - startFrame, 1);
	return [startFrame + index, from[0] + ((to[0] - from[0]) * progress), from[1] + ((to[1] - from[1]) * progress)];
});

const waffleHeist = {
	scenes: [
		{
			set: 'bergen',
			camera: 0,
			length: 95,
			actors: [
				{id: 1, kind: 'sindre', facing: 1, path: walk([-1.1, 0.35], [-0.2, 0.35], 0, 28), actions: [[0, 'walk'], [29, 'stand'], [60, 'fall']]},
				{id: 2, kind: 'seagull', facing: -1, path: [...walk([1.2, 0.9], [0.05, 0.4], 38, 52), ...walk([0.05, 0.4], [1.3, 0.1], 58, 80)], actions: [[38, 'jump'], [53, 'stand'], [58, 'run']]},
			],
			events: [
				{frame: 0, type: 'title', text: 'THE WAFFLE HEIST'},
				{frame: 32, type: 'say', actor: 1, text: 'Mmm! A waffle with brunost!'},
				{frame: 44, type: 'camera', camera: 1},
				{frame: 57, type: 'say', actor: 2, text: 'SKRÆÆ! Mine now!'},
				{frame: 58, type: 'sound', sound: 'crash'},
				{frame: 64, type: 'say', actor: 1, text: 'MIN VAFFEL!!!'},
				{frame: 70, type: 'sound', sound: 'laugh'},
			],
		},
		{
			set: 'diner',
			camera: 0,
			length: 85,
			actors: [
				{id: 1, kind: 'robot', facing: -1, path: [[0, 0.5, 0.75]], actions: [[0, 'stand'], [62, 'wave']]},
				{id: 2, kind: 'glitter', facing: 1, path: [[0, -0.75, 0.45]], actions: [[0, 'dance']]},
				{id: 3, kind: 'seagull', facing: 1, path: walk([-1.3, 0.2], [0.05, 0.35], 8, 30), actions: [[8, 'walk'], [31, 'stand'], [56, 'jump']]},
				{id: 4, kind: 'sindre', facing: -1, path: walk([1.3, 0.15], [0.45, 0.3], 44, 56), actions: [[44, 'run'], [57, 'stand']]},
			],
			events: [
				{frame: 2, type: 'say', actor: 1, text: 'WAFFLE DETECTED. BEEP.'},
				{frame: 33, type: 'say', actor: 3, text: 'One coffee. Black. Like my soul.'},
				{frame: 44, type: 'camera', camera: 1},
				{frame: 56, type: 'sound', sound: 'boing'},
				{frame: 58, type: 'say', actor: 4, text: 'Where did it go?!'},
				{frame: 66, type: 'say', actor: 1, text: 'IT WENT TO SPACE. BEEP.'},
				{frame: 72, type: 'sound', sound: 'laugh'},
			],
		},
		{
			set: 'space',
			camera: 0,
			length: 85,
			actors: [
				{id: 1, kind: 'seagull', facing: 1, path: [[0, -0.2, 0.5]], actions: [[0, 'jump'], [24, 'dance'], [62, 'fall']]},
				{id: 2, kind: 'rocky', facing: -1, path: [[0, 0.9, 0.85], ...walk([0.9, 0.85], [0.1, 0.5], 40, 60)], actions: [[0, 'stand'], [40, 'walk'], [61, 'stand']]},
			],
			events: [
				{frame: 0, type: 'title', text: 'MEANWHILE, IN SPACE'},
				{frame: 30, type: 'say', actor: 1, text: 'Nobody finds me in SPACE.'},
				{frame: 40, type: 'camera', camera: 2},
				{frame: 62, type: 'sound', sound: 'crash'},
				{frame: 64, type: 'say', actor: 2, text: '…'},
				{frame: 72, type: 'say', actor: 1, text: 'How did a ROCK get to space?!'},
				{frame: 78, type: 'sound', sound: 'laugh'},
			],
		},
		{
			set: 'haunted',
			camera: 0,
			length: 60,
			actors: [
				{id: 1, kind: 'sindre', facing: 1, path: [[0, -0.45, 0.3]], actions: [[0, 'dance']]},
				{id: 2, kind: 'glitter', facing: -1, path: [[0, 0.5, 0.45]], actions: [[0, 'dance']]},
				{id: 3, kind: 'rocky', facing: 1, path: [[0, 0, 0.15]], actions: [[0, 'wave']]},
			],
			events: [
				{frame: 4, type: 'say', actor: 1, text: 'Rocky got my waffle back!'},
				{frame: 18, type: 'say', actor: 2, text: 'Party at the haunted house!'},
				{frame: 30, type: 'title', text: 'THE END?'},
				{frame: 30, type: 'sound', sound: 'applause'},
			],
		},
	],
};

const setPressed = (button, isPressed) => {
	button.setAttribute('aria-pressed', String(isPressed));

	if (isPressed) {
		button.dataset.state = 'on';
	} else {
		delete button.dataset.state;
	}
};

const setPathPoint = (actor, frame, spot) => {
	actor.path = actor.path.filter(point => point[0] !== frame);
	actor.path.push([frame, spot.x, spot.z]);
	sortByFrame(actor.path);
};

export default class extends GeoCitiesElement {
	#context;
	#guideContext;
	#cameraButtons;

	// The movie, the scene and the frame on the stage, the picked actor, and the movie that plays, which can also be the premade movie.
	#movie;
	#sceneIndex = 0;
	#currentFrame = 0;
	#pickedId;
	#playback;
	#undoStack = [];
	#layout = [];

	// A drag on an actor records its path: the clock runs while the pointer is down, and each frame keeps the spot under the pointer.
	#drag;

	#guide = {who: 'McZee', until: 0};
	#tipIndex = Math.floor(Math.random() * lines.tips.length);
	#welcome;
	#carry = 0;
	#lastDraw = 0;

	// The sounds, made with tones and noise through the volume of the tray, once the visitor turns them on. The lines of the speech balloons are said with the voice of the computer.
	#audio;

	connected() {
		const {screen, guide, frame, play, stop, step, undo, sound, set, scenes, addScene, deleteScene, cast: castPicker, addActor, action, nextActor, removeActor, sayForm, sayText, titleForm, titleText, effect, addEffect, save, open, newMovie: newMovieButton, premiere, ask} = this.parts;
		this.#context = screen.getContext('2d');
		this.#guideContext = guide.getContext('2d');
		this.#cameraButtons = [...this.querySelectorAll('[data-moviemaker-camera]')];
		const toolButtons = [...this.querySelectorAll('[data-moviemaker-tool]')];
		const panels = [...this.querySelectorAll('[data-moviemaker-panel]')];

		// The stage is 480 × 300, like the studio of the real one, drawn at twice the pixels, so the text is sharp.
		screen.width = stageWidth * pixelRatio;
		screen.height = stageHeight * pixelRatio;
		guide.width = 64 * pixelRatio;
		guide.height = 96 * pixelRatio;

		// The studio opens with the saved movie, or a new one, and McZee welcomes the visitor the first time the window opens.
		const saved = cleanMovie(this.stored('movie'));
		this.#movie = saved ?? newMovie();
		this.#welcome = saved ? lines.welcomeBack : lines.welcome;
		this.#refresh();

		// The loop draws the stage while it is on the screen, in its open window, and the tab is visible: the movie at 10 frames a second, and the rain and the candles in between. With reduced motion, it does not run, and the stage is drawn after each input.
		this.loop((seconds, time) => {
			if (this.#playback && !this.#playback.isStepping) {
				this.#carry += seconds * 1000;

				while (this.#playback && this.#carry >= frameTime) {
					this.#carry -= frameTime;
					this.#advancePlayback();
				}
			}

			// The set is drawn at about 20 frames a second, which is plenty for rain.
			if (time - this.#lastDraw > 45) {
				this.#lastDraw = time;
				this.#render();
				this.#drawGuide(time);
			}
		}, {
			while: () => !this.reducedMotion,
			maximumStep: 0.25,
			stopped: () => {
				this.#carry = 0;
			},
		});

		this.on(screen, 'pointerdown', event => {
			// One finger drags at a time.
			if (event.button !== 0 || !event.isPrimary || this.#drag) {
				return;
			}

			if (this.#playback) {
				this.#stopPlayback();
				return;
			}

			const point = this.#stagePoint(event);
			// A finger is wider than a mouse pointer, and the actors are small on a phone, so a touch reaches 8 CSS pixels beyond an actor.
			const reach = event.pointerType === 'mouse' ? 0 : 8 * (stageWidth / screen.clientWidth);
			const hit = this.#layout.findLast(entry => point.x >= entry.left - reach && point.x <= entry.right + reach && point.y >= entry.top - reach && point.y <= entry.bottom + reach);

			if (!hit) {
				this.#pickedId = undefined;
				this.#updateControls();
				this.#render();
				return;
			}

			this.#pickedId = hit.id;
			screen.setPointerCapture(event.pointerId);
			this.#drag = {id: hit.id, startX: point.x, startY: point.y, offsetX: hit.footX - point.x, offsetY: hit.footY - point.y, isRecording: false};
			this.#updateControls();
			this.#render();
		});

		this.on(screen, 'pointermove', event => {
			if (!this.#drag) {
				return;
			}

			const point = this.#stagePoint(event);

			if (!this.#drag.isRecording && Math.hypot(point.x - this.#drag.startX, point.y - this.#drag.startY) < 5) {
				return;
			}

			// The actor can be gone in the middle of a drag, like with the Delete key.
			const actor = this.#draggedActor();

			if (!actor) {
				this.#stopRecording();
				return;
			}

			const scene = this.#currentScene();
			const camera = sets[scene.set].cameras[cameraAt(scene, this.#currentFrame)];
			this.#drag.spot = floorAt(camera, point.x + this.#drag.offsetX, point.y + this.#drag.offsetY);

			if (!this.#drag.isRecording) {
				this.#startRecording(actor);
			}

			setPathPoint(actor, this.#currentFrame, this.#drag.spot);
			this.#render();
		});

		for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
			this.on(screen, type, () => {
				this.#stopRecording();
			});
		}

		this.on(screen, 'keydown', event => {
			this.#keyDown(event);
		});

		// The tools open their drawers, one at a time.
		for (const button of toolButtons) {
			this.on(button, 'click', () => {
				for (const other of toolButtons) {
					setPressed(other, other === button);
				}

				for (const panel of panels) {
					panel.hidden = panel.dataset.moviemakerPanel !== button.dataset.moviemakerTool;

					// The drawer opens under the toolbar, which can be at the bottom edge of the window, so the window scrolls to show it.
					if (!panel.hidden) {
						panel.scrollIntoView({block: 'nearest'});
					}
				}
			});
		}

		this.on(set, 'change', () => {
			const picked = sets[set.value];

			if (!picked) {
				return;
			}

			this.#edit(() => {
				const scene = this.#currentScene();
				scene.set = set.value;
				scene.camera = 0;
				scene.events = scene.events.filter(event => event.type !== 'camera');
			});
			this.#talk('McZee', `${picked.emoji} The ${picked.name}! It has ${picked.cameras.length} cameras. Try them all.`);
		});

		for (const [index, button] of this.#cameraButtons.entries()) {
			this.on(button, 'click', () => {
				const scene = this.#currentScene();
				const camera = sets[scene.set].cameras[index];

				if (!camera) {
					return;
				}

				this.#edit(() => {
					scene.events = scene.events.filter(event => event.type !== 'camera' || event.frame !== this.#currentFrame);

					if (this.#currentFrame === 0) {
						scene.camera = index;
					} else {
						scene.events.push({frame: this.#currentFrame, type: 'camera', camera: index});
						sortByFrame(scene.events);
					}
				});

				if (this.#currentFrame === 0) {
					this.#talk('McZee', `Camera ${index + 1}: ${camera.name}. The scene starts with this one.`);
				} else {
					this.#talk('McZee', `Cut to camera ${index + 1}, ${camera.name}, at frame ${this.#currentFrame}. Very Spielberg.`);
				}
			});
		}

		// The buttons of the scenes are made again with each change, so the strip listens for their clicks.
		this.on(scenes, 'click', event => {
			const buttons = [...scenes.querySelectorAll('button')];
			const index = buttons.indexOf(event.target.closest('button'));

			if (index === -1) {
				return;
			}

			this.#stopPlayback();
			this.#sceneIndex = index;
			this.#currentFrame = 0;
			this.#pickedId = undefined;
			this.#refresh();
			scenes.querySelectorAll('button')[index]?.focus();
		});

		this.on(addScene, 'click', () => {
			if (this.#movie.scenes.length >= maximumScenes) {
				this.#talk('McZee', `${maximumScenes} scenes is a long movie! Mamma says the computer is not a cinema.`);
				return;
			}

			this.#edit(() => {
				this.#movie.scenes.splice(this.#sceneIndex + 1, 0, newScene(this.#currentScene().set));
				this.#sceneIndex++;
				this.#currentFrame = 0;
				this.#pickedId = undefined;
			});
			this.#talk('McZee', `Scene ${this.#sceneIndex + 1}! A new scene starts empty, so bring your actors back on the set.`);
		});

		this.on(deleteScene, 'click', async () => {
			if (this.#movie.scenes.length < 2) {
				return;
			}

			const index = this.#sceneIndex;
			const answer = await this.ask({text: `Cut scene ${index + 1} from the movie? You can get it back with Undo.`, buttons: ['Yes', 'No'], opener: deleteScene});

			if (answer !== 'Yes' || this.#movie.scenes.length < 2 || !this.#movie.scenes[index]) {
				return;
			}

			this.#edit(() => {
				this.#movie.scenes.splice(index, 1);
				this.#sceneIndex = Math.min(index, this.#movie.scenes.length - 1);
				this.#currentFrame = 0;
				this.#pickedId = undefined;
			});
			this.#talk('The Hand', 'Scene cut. It was too long anyway.');
		});

		this.on(addActor, 'click', () => {
			const kind = castPicker.value;

			if (!cast[kind]) {
				return;
			}

			const scene = this.#currentScene();

			if (scene.actors.length >= maximumActors) {
				this.#talk('McZee', `The set is full! ${maximumActors} actors is the most. The union says so.`);
				return;
			}

			let id = 1;

			for (const actor of scene.actors) {
				id = Math.max(id, actor.id + 1);
			}

			const x = (Math.random() * 1.6) - 0.8;

			this.#edit(() => {
				scene.actors.push({id, kind, facing: x > 0 ? -1 : 1, path: [[this.#currentFrame, x, 0.15 + (Math.random() * 0.6)]], actions: [[this.#currentFrame, 'stand']]});
				this.#pickedId = id;
			});
			this.#talkLine(lines.actors[kind]);
		});

		this.on(action, 'change', () => {
			const picked = action.value;
			const actor = this.#needsActor();

			if (!actor || !actionNames.includes(picked)) {
				return;
			}

			this.#edit(() => {
				actor.actions = actor.actions.filter(entry => entry[0] !== this.#currentFrame);
				actor.actions.push([this.#currentFrame, picked]);
				sortByFrame(actor.actions);
			});
			this.#talkLine(lines.actions[picked]);
		});

		this.on(nextActor, 'click', () => {
			this.#pickNext();
		});

		this.on(removeActor, 'click', () => {
			this.#removeActor();
		});

		this.on(sayForm, 'submit', event => {
			event.preventDefault();
			const text = sayText.value.trim();

			if (!text) {
				this.#talk('McZee', 'Write what the actor says first, like “Uff da!”');
				sayText.focus();
				return;
			}

			const actor = this.#needsActor();

			if (!actor) {
				return;
			}

			this.#edit(() => {
				const scene = this.#currentScene();
				scene.events.push({frame: this.#currentFrame, type: 'say', actor: actor.id, text});
				sortByFrame(scene.events);
				extendScene(scene, this.#currentFrame + sayFrames - 1);
			});
			sayText.value = '';
			this.#speakLine(text, actor.kind);
			this.#talk('McZee', `${cast[actor.kind].name} says it at frame ${this.#currentFrame}. ${this.#isSoundOn() ? 'What a voice!' : 'Turn on the sound to hear it.'}`);
		});

		this.on(titleForm, 'submit', event => {
			event.preventDefault();
			const text = titleText.value.trim().toUpperCase();

			if (!text) {
				this.#talk('McZee', 'Write a title first. “THE REVENGE OF ROCKY” is free to use.');
				titleText.focus();
				return;
			}

			this.#edit(() => {
				const scene = this.#currentScene();
				scene.events.push({frame: this.#currentFrame, type: 'title', text});
				sortByFrame(scene.events);
				extendScene(scene, this.#currentFrame + titleFrames - 1);
			});
			titleText.value = '';
			this.#talk('McZee', 'Ooh, 3D letters! Very 1995. Step forward a few frames to see them spin in.');
		});

		this.on(addEffect, 'click', () => {
			const picked = effect.value;

			if (!effects[picked]) {
				return;
			}

			this.#edit(() => {
				const scene = this.#currentScene();
				scene.events.push({frame: this.#currentFrame, type: 'sound', sound: picked});
				sortByFrame(scene.events);
				extendScene(scene, this.#currentFrame + effectFrames - 1);
			});
			this.#sounds[picked]();
			this.#talkLine(lines.effects[picked]);
		});

		this.on(frame, 'input', () => {
			this.#goToFrame(Number(frame.value));
		});

		this.on(play, 'click', () => {
			this.#play();
		});

		this.on(stop, 'click', () => {
			this.#stopPlayback();
		});

		this.on(step, 'click', () => {
			this.#step();
		});

		this.on(undo, 'click', () => {
			const last = this.#undoStack.pop();

			if (!last) {
				return;
			}

			this.#stopPlayback();
			this.#movie = JSON.parse(last.movie);
			this.#sceneIndex = Math.min(last.sceneIndex, this.#movie.scenes.length - 1);
			this.#currentFrame = Math.min(this.#currentFrame, this.#currentScene().length);
			this.#pickedId = this.#currentScene().actors.some(actor => actor.id === this.#pickedId) ? this.#pickedId : undefined;
			this.#refresh();
			this.#talk('The Hand', 'Undone. Like it never happened.');
		});

		this.on(sound, 'click', () => {
			const isOn = sound.getAttribute('aria-pressed') !== 'true';
			sound.setAttribute('aria-pressed', String(isOn));
			sound.textContent = isOn ? '🔊 Sound' : '🔈 Sound';

			// The desktop gives the audio in the handler of the click, so the browser lets it play.
			if (isOn && !this.#audio) {
				const audio = this.sound();

				if (audio) {
					this.#audio = {context: audio.context, destination: audio.output};
					this.#connectOutput();
				}
			}

			if (isOn) {
				this.#sounds.boing();
			} else {
				this.#silence();
			}
		});

		this.on(ask, 'click', () => {
			this.#tipIndex = (this.#tipIndex + 1) % lines.tips.length;
			this.#talkLine(lines.tips[this.#tipIndex]);
		});

		this.on(save, 'click', () => {
			this.#stopRecording();

			// The storage can be missing or full, and then it keeps what it had, so the visitor is told whether the movie was saved.
			if (this.store('movie', this.#movie)) {
				this.#talk('McZee', 'Saved as C:\\3DMOVIE\\MYMOVIE.3MM. It is safe in this browser now, even if Mamma needs the phone line.');
				this.toast('🎬 MYMOVIE.3MM saved!');
			} else {
				this.#talk('The Hand', 'The disk is full! Or the browser said no. Either way, the movie is only in memory.');
			}
		});

		this.on(open, 'click', () => {
			const savedMovie = cleanMovie(this.stored('movie'));

			if (!savedMovie) {
				this.#talk('McZee', 'There is no saved movie yet. Make one, and press 💾 Save!');
				return;
			}

			this.#edit(() => {
				this.#movie = savedMovie;
				this.#sceneIndex = 0;
				this.#currentFrame = 0;
				this.#pickedId = undefined;
			});
			this.#talk('McZee', 'Here is MYMOVIE.3MM, back from the vault. Undo brings back the one before.');
		});

		this.on(newMovieButton, 'click', async () => {
			const answer = await this.ask({text: 'Start a new movie? What you did not save goes to the floor of the cutting room. Undo can still bring it back.', buttons: ['Yes', 'No'], opener: newMovieButton});

			if (answer !== 'Yes') {
				return;
			}

			this.#edit(() => {
				this.#movie = newMovie();
				this.#sceneIndex = 0;
				this.#currentFrame = 0;
				this.#pickedId = undefined;
			});
			this.#talk('McZee', 'A new movie! A blank film, full of possibilities. And rain, as it is Bergen.');
		});

		this.on(premiere, 'click', () => {
			this.#startPlayback(waffleHeist, 'Sindre, age 9¾');
			this.#talk('McZee', this.reducedMotion ? 'Tonight’s premiere: “The Waffle Heist”, a true story from Bryggen. Mostly true. Press ⏭ Step to go through it.' : 'Tonight’s premiere: “The Waffle Heist”, a true story from Bryggen. Mostly true.');
		});
	}

	disconnected() {
		this.#drag = undefined;
		this.#silence();
	}

	// The studio runs only while its stage is on the screen, not while only its tools are.
	get visibilityTarget() {
		return this.parts.screen;
	}

	visibilityChanged(isVisible) {
		if (!isVisible && document.hidden) {
			this.#stopRecording();
		}
	}

	// A closed window stops the movie, the drag, and the voices, also when the stage was off the screen already, so it is watched by itself.
	windowChanged(isOpen) {
		if (!isOpen) {
			this.#stopRecording();
			this.#stopPlayback();
			this.#silence();
			return;
		}

		if (this.#welcome) {
			this.#talkLine(this.#welcome);
			this.#welcome = undefined;
		}

		this.#render();
		this.#drawGuide(performance.now());
	}

	reducedMotionChanged(isReduced) {
		if (this.#playback) {
			this.#playback.isStepping = isReduced;
		}

		this.#render();
	}

	// Stop gets disabled when the movie stops, so the focus goes to Play, which starts it again.
	focusReplacement(control) {
		return control === this.parts.stop ? this.parts.play : super.focusReplacement(control);
	}

	#currentScene() {
		return this.#movie.scenes[this.#sceneIndex];
	}

	#pickedActor() {
		return this.#currentScene().actors.find(actor => actor.id === this.#pickedId);
	}

	#draggedActor() {
		return this.#currentScene().actors.find(candidate => candidate.id === this.#drag?.id);
	}

	// The ambient things, like the rain, move with the clock, and with reduced motion only with the frames, so nothing moves by itself.
	#ambientTime() {
		return this.reducedMotion ? (this.#playback?.frame ?? this.#currentFrame) * frameTime : performance.now();
	}

	#render() {
		const time = this.#ambientTime();
		const options = {zoom: stageWidth / (this.parts.screen.clientWidth || stageWidth), isReducedMotion: this.reducedMotion};

		if (this.#playback) {
			if (this.#playback.ending >= 0) {
				drawEnd(this.#context, this.#playback.ending, this.#playback.director);
			} else {
				this.#layout = drawFrame(this.#context, this.#playback.movie.scenes[this.#playback.sceneIndex], this.#playback.frame, time, options);
			}

			return;
		}

		this.#layout = drawFrame(this.#context, this.#currentScene(), this.#currentFrame, time, {...options, isEditing: true, isRecording: this.#drag?.isRecording, pickedId: this.#pickedId});
	}

	#drawGuide(time) {
		drawGuide(this.#guideContext, time, this.#guide, this.reducedMotion);
	}

	// McZee or the hand says a line in the balloon, which is the status of the studio.
	#talk(who, text) {
		this.#guide.who = who;
		this.#guide.until = performance.now() + 2500;
		this.say(`${who}: ${text}`);
		this.#drawGuide(performance.now());
	}

	#talkLine([who, text]) {
		this.#talk(who, text);
	}

	#isSoundOn() {
		return this.#audio !== undefined && this.parts.sound.getAttribute('aria-pressed') === 'true';
	}

	#tone(frequency, start, duration, {type = 'sine', volume = 0.12, slide, vibrato} = {}) {
		if (!this.#isSoundOn()) {
			return;
		}

		const {context: audioContext, output} = this.#audio;
		const oscillator = audioContext.createOscillator();
		const gain = audioContext.createGain();
		const time = audioContext.currentTime + start;
		oscillator.type = type;
		oscillator.frequency.setValueAtTime(frequency, time);

		if (slide) {
			oscillator.frequency.exponentialRampToValueAtTime(slide, time + duration);
		}

		if (vibrato) {
			const wobble = audioContext.createOscillator();
			const depth = audioContext.createGain();
			wobble.frequency.value = vibrato.rate;
			depth.gain.value = vibrato.depth;
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
	}

	#noise(start, duration, {volume = 0.1, frequency = 1000, q = 0.7} = {}) {
		if (!this.#isSoundOn()) {
			return;
		}

		const {context: audioContext, output} = this.#audio;
		const buffer = audioContext.createBuffer(1, Math.ceil(audioContext.sampleRate * duration), audioContext.sampleRate);
		const samples = buffer.getChannelData(0);

		for (let index = 0; index < samples.length; index++) {
			samples[index] = (Math.random() * 2) - 1;
		}

		const source = audioContext.createBufferSource();
		const filter = audioContext.createBiquadFilter();
		const gain = audioContext.createGain();
		const time = audioContext.currentTime + start;
		source.buffer = buffer;
		filter.type = 'bandpass';
		filter.frequency.value = frequency;
		filter.Q.value = q;
		gain.gain.setValueAtTime(volume, time);
		gain.gain.exponentialRampToValueAtTime(0.0001, time + duration);
		source.connect(filter).connect(gain).connect(output);
		source.start(time);
	}

	#sounds = {
		boing: () => {
			this.#tone(160, 0, 0.12, {slide: 480, volume: 0.2});
			this.#tone(480, 0.12, 0.55, {slide: 200, volume: 0.2, vibrato: {rate: 18, depth: 60}});
		},
		crash: () => {
			this.#tone(90, 0, 0.35, {slide: 40, volume: 0.3});
			this.#noise(0, 0.9, {volume: 0.4, frequency: 3000, q: 0.4});
			this.#noise(0, 0.35, {volume: 0.35, frequency: 400, q: 0.8});

			for (const [index, frequency] of [2349, 1661, 3136, 1975].entries()) {
				this.#tone(frequency, 0.04 + (index * 0.07), 0.4, {type: 'square', volume: 0.03});
			}
		},
		laugh: () => {
			for (let voice = 0; voice < 5; voice++) {
				for (let laugh = 0; laugh < 6; laugh++) {
					const start = (voice * 0.07) + (laugh * 0.19) + (Math.random() * 0.04);
					this.#noise(start, 0.11, {volume: 0.14, frequency: 700 + (voice * 160), q: 4});
					this.#tone(170 + (voice * 45), start, 0.1, {type: 'sawtooth', volume: 0.025, slide: 140 + (voice * 35)});
				}
			}
		},
		applause: () => {
			for (let clap = 0; clap < 140; clap++) {
				const start = Math.random() * 2.2;
				this.#noise(start, 0.03 + (Math.random() * 0.03), {volume: 0.16 * (1 - (start / 2.6)), frequency: 1500 + (Math.random() * 2500), q: 1.2});
			}
		},
		clapper: () => {
			this.#noise(0, 0.06, {volume: 0.4, frequency: 2200, q: 1});
			this.#tone(1200, 0, 0.05, {type: 'square', volume: 0.05});
		},
	};

	#speakLine(text, kind) {
		if (!this.#isSoundOn() || !('speechSynthesis' in globalThis)) {
			return;
		}

		const utterance = new SpeechSynthesisUtterance(text);
		utterance.pitch = cast[kind].voice.pitch;
		utterance.rate = cast[kind].voice.rate;
		speechSynthesis.speak(utterance);
	}

	// The sounds go through a volume of their own, which is swapped for a new one to cut the sounds that are still on their way, like the applause, when the movie stops or the sound is turned off.
	#connectOutput() {
		this.#audio.output = this.#audio.context.createGain();
		this.#audio.output.connect(this.#audio.destination);
	}

	#silence() {
		if ('speechSynthesis' in globalThis) {
			speechSynthesis.cancel();
		}

		if (this.#audio) {
			this.#audio.output.disconnect();
			this.#connectOutput();
		}
	}

	// The sounds and the voices of the events that start at a frame.
	#playEvents(scene, frame) {
		for (const event of scene.events) {
			if (event.frame !== frame) {
				continue;
			}

			if (event.type === 'sound') {
				this.#sounds[event.sound]();
			} else if (event.type === 'say') {
				const actor = scene.actors.find(candidate => candidate.id === event.actor);

				if (actor) {
					this.#speakLine(event.text, actor.kind);
				}
			}
		}
	}

	// A question with the message box of the desktop.
	ask(options) {
		return super.ask({title: '3D Movie Maker', icon: '🎬', ...options});
	}

	// The undo of the studio keeps the last 40 versions of the movie.
	#remember() {
		this.#undoStack.push({movie: JSON.stringify(this.#movie), sceneIndex: this.#sceneIndex});
		this.#undoStack = this.#undoStack.slice(-40);
	}

	#updateCounter() {
		const {counter, frame} = this.parts;

		if (this.#playback) {
			const scenes = this.#playback.movie.scenes;
			counter.textContent = this.#playback.ending >= 0 ? 'The End ★ Credits' : `Scene ${this.#playback.sceneIndex + 1}/${scenes.length} ★ Frame ${pad(this.#playback.frame)}`;
			const scene = scenes[Math.min(this.#playback.sceneIndex, scenes.length - 1)];
			frame.max = String(Math.max(scene.length, shortestScene) - 1);
			frame.value = String(this.#playback.ending >= 0 ? frame.max : this.#playback.frame);
			return;
		}

		const scene = this.#currentScene();
		counter.textContent = `Scene ${this.#sceneIndex + 1}/${this.#movie.scenes.length} ★ Frame ${pad(this.#currentFrame)}/${pad(scene.length)}`;
		frame.max = String(scene.length);
		frame.value = String(this.#currentFrame);
	}

	#renderScenes() {
		const {scenes, sceneTemplate} = this.parts;

		const buttons = this.#movie.scenes.map((scene, index) => {
			const button = sceneTemplate.content.firstElementChild.cloneNode(true);
			const set = sets[scene.set];
			button.textContent = `${index + 1} ${set.emoji}`;
			button.setAttribute('aria-label', `Scene ${index + 1}: ${set.name}`);
			setPressed(button, index === this.#sceneIndex);
			return button;
		});

		scenes.replaceChildren(...buttons);
	}

	#updateControls() {
		const {set: setPicker, action, stop, undo, removeActor, deleteScene, frame} = this.parts;
		const scene = this.#currentScene();
		const set = sets[scene.set];
		const actor = this.#pickedActor();
		const camera = cameraAt(scene, this.#currentFrame);
		setPicker.value = scene.set;

		for (const [index, button] of this.#cameraButtons.entries()) {
			button.hidden = index >= set.cameras.length;
			button.title = set.cameras[index]?.name ?? '';
			setPressed(button, index === camera);
		}

		if (actor) {
			action.value = actionAt(actor, this.#currentFrame)[1];
		}

		stop.disabled = this.#playback === undefined;
		undo.disabled = this.#undoStack.length === 0;
		removeActor.disabled = actor === undefined;
		deleteScene.disabled = this.#movie.scenes.length < 2;
		frame.disabled = this.#playback !== undefined;
		this.#updateCounter();
	}

	#refresh() {
		this.#renderScenes();
		this.#updateControls();
		this.#render();
	}

	// An edit stops the movie first, and can be undone.
	#edit(change) {
		this.#stopPlayback();
		this.#remember();
		change();
		this.#refresh();
	}

	#needsActor() {
		// With only one actor on the stage there is nothing to choose, so the arrow keys, the actions, and the balloons work without a click first.
		const onStage = this.#currentScene().actors.filter(actor => isOnStage(actor, this.#currentFrame));

		if (onStage.length === 1) {
			this.#pickedId = onStage[0].id;
		}

		const actor = this.#pickedActor();

		if (!actor || !isOnStage(actor, this.#currentFrame)) {
			this.#talk('McZee', 'First pick an actor on the stage. Click one, or press N on the stage. Or add one in the 🎭 Actors drawer.');
			return undefined;
		}

		return actor;
	}

	// The movie plays from the start, scene after scene, and ends with “The End”. With reduced motion, it only goes on with the Step button.
	#startPlayback(movieToPlay, director) {
		this.#stopRecording();
		this.#silence();
		this.#playback = {movie: movieToPlay, sceneIndex: 0, frame: 0, ending: -1, director, isStepping: this.reducedMotion};
		this.#sounds.clapper();
		this.#playEvents(movieToPlay.scenes[0], 0);
		this.#updateControls();
		this.#render();
	}

	#finishPlayback() {
		this.#playback = undefined;
		this.#updateControls();
		this.#render();
		this.#talkLine(randomItem(lines.reviews));
	}

	#advancePlayback() {
		const playback = this.#playback;

		if (playback.ending >= 0) {
			playback.ending++;

			if (playback.ending >= endFrames) {
				this.#finishPlayback();
				return;
			}
		} else {
			const scenes = playback.movie.scenes;
			playback.frame++;

			if (playback.frame >= Math.max(scenes[playback.sceneIndex].length, shortestScene)) {
				playback.frame = 0;
				playback.sceneIndex++;

				if (playback.sceneIndex >= scenes.length) {
					playback.sceneIndex = scenes.length - 1;
					playback.ending = 0;
					this.#sounds.applause();
				}
			}

			if (playback.ending < 0) {
				this.#playEvents(scenes[playback.sceneIndex], playback.frame);
			}
		}

		this.#updateCounter();
	}

	#stopPlayback() {
		if (!this.#playback) {
			return;
		}

		this.#playback = undefined;
		this.#silence();
		this.#updateControls();
		this.#render();
	}

	#play() {
		const hasAnything = this.#movie.scenes.some(scene => scene.actors.length > 0 || scene.events.length > 0);

		if (!hasAnything) {
			this.#talk('McZee', 'The movie is empty! Add an actor first. Even Rocky would do.');
			return;
		}

		this.#startPlayback(this.#movie, 'You');
		this.#talk('McZee', this.reducedMotion ? 'Lights down! Press ⏭ Step to go through the movie, one frame at a time.' : 'Lights down! Popcorn up!');
	}

	#togglePlay() {
		if (this.#playback) {
			this.#stopPlayback();
		} else {
			this.#play();
		}
	}

	#stagePoint(event) {
		const {screen} = this.parts;
		const rectangle = screen.getBoundingClientRect();

		return {
			x: ((event.clientX - rectangle.left - screen.clientLeft) / screen.clientWidth) * stageWidth,
			y: ((event.clientY - rectangle.top - screen.clientTop) / screen.clientHeight) * stageHeight,
		};
	}

	#recordTick() {
		const scene = this.#currentScene();
		const actor = this.#draggedActor();

		if (!actor || this.#currentFrame + 1 >= longestScene) {
			this.#stopRecording();
			return;
		}

		this.#currentFrame++;
		setPathPoint(actor, this.#currentFrame, this.#drag.spot);
		extendScene(scene, this.#currentFrame);
		this.#playEvents(scene, this.#currentFrame);
		this.#updateCounter();
		this.#render();
	}

	#startRecording(actor) {
		this.#remember();
		actor.path = actor.path.filter(point => point[0] <= this.#currentFrame);
		this.#drag.isRecording = true;
		this.#drag.startFrame = this.#currentFrame;

		this.#drag.timer = this.interval(frameTime, () => {
			this.#recordTick();
		});

		this.parts.undo.disabled = false;
	}

	#stopRecording() {
		if (!this.#drag) {
			return;
		}

		this.#drag.timer?.cancel();
		const recorded = this.#drag.isRecording ? this.#currentFrame - this.#drag.startFrame : 0;
		this.#drag = undefined;

		if (recorded > 0) {
			this.#talk('McZee', `Cut! ${recorded} ${recorded === 1 ? 'frame' : 'frames'} of pure movie magic. Press ▶ Play to watch, or drag again from here.`);
		}

		this.#refresh();
	}

	#pickNext() {
		const onStage = this.#currentScene().actors.filter(actor => isOnStage(actor, this.#currentFrame));

		if (onStage.length === 0) {
			this.#talk('McZee', 'Nobody is on the stage at this frame. Add an actor in the 🎭 Actors drawer.');
			return;
		}

		const index = onStage.findIndex(actor => actor.id === this.#pickedId);
		this.#pickedId = onStage[(index + 1) % onStage.length].id;
		this.#updateControls();
		this.#render();
		this.say(`${cast[this.#pickedActor().kind].name} is picked.`);
	}

	#goToFrame(frame) {
		this.#stopPlayback();
		this.#currentFrame = clamp(frame, 0, this.#currentScene().length);
		this.#updateControls();
		this.#render();
	}

	#step() {
		if (this.#playback) {
			this.#playback.isStepping = true;
			this.#advancePlayback();
			this.#render();
			return;
		}

		const scene = this.#currentScene();

		if (this.#currentFrame < scene.length) {
			this.#currentFrame++;
			this.#playEvents(scene, this.#currentFrame);
		}

		this.#updateControls();
		this.#render();
	}

	#removeActor() {
		const actor = this.#pickedActor();

		if (!actor) {
			return;
		}

		this.#edit(() => {
			const scene = this.#currentScene();
			scene.actors = scene.actors.filter(candidate => candidate !== actor);
			scene.events = scene.events.filter(event => event.type !== 'say' || event.actor !== actor.id);
			this.#pickedId = undefined;
		});
		this.#talk('McZee', `${cast[actor.kind].name} went back to the dressing room.`);
	}

	#keyDown(event) {
		if (event.ctrlKey || event.altKey || event.metaKey) {
			return;
		}

		const move = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, 1], ArrowDown: [0, -1]}[event.key];

		if (move) {
			event.preventDefault();
			this.#stopPlayback();
			const actor = this.#needsActor();

			if (!actor || this.#currentFrame + 1 >= longestScene) {
				return;
			}

			this.#remember();
			const [, x, z] = pathPointAt(actor, this.#currentFrame);
			const next = this.#currentFrame + 1;
			actor.path = actor.path.filter(point => point[0] < next);
			actor.path.push([next, clamp(x + (move[0] * 0.06), floorLimits.left, floorLimits.right), clamp(z + (move[1] * 0.06), floorLimits.front, floorLimits.back)]);
			this.#currentFrame = next;
			extendScene(this.#currentScene(), this.#currentFrame);
			this.#updateControls();
			this.#render();
		} else if (event.key === ' ') {
			event.preventDefault();

			if (!event.repeat) {
				this.#togglePlay();
			}
		} else if (event.key === 'n' || event.key === 'N') {
			event.preventDefault();
			this.#pickNext();
		} else if (event.key === ',') {
			event.preventDefault();
			this.#goToFrame(this.#currentFrame - 1);
		} else if (event.key === '.') {
			event.preventDefault();
			this.#step();
		} else if (event.key === 'Delete' || event.key === 'Backspace') {
			event.preventDefault();
			this.#removeActor();
		}
	}
}
