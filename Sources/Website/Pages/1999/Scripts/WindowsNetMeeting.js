// Microsoft NetMeeting 2.1 on the desktop of the 1999 page, for a video call with Mormor in Ålesund, who just got a computer. The directory server is busy, she ignores the first call, her video is 160 × 120 at 2 frames per second, her sound comes seconds late, she types with caps lock and one finger, draws a cat that looks like a potato, sends a photo that takes forever, clicks everything on the shared desktop, cannot find Hang Up, and Mamma picks up the phone. Everything waits while the window is closed, off the screen, or the tab is hidden. Nothing makes a sound until the visitor presses Sound.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));
const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);

// Each call has a number, and a wait of a call that ended throws this, so the rest of what Mormor was doing stops.
class Cancelled extends Error {}

// A sequence that runs on its own. A call that ends stops it quietly, and real errors still show.
const inBackground = promise => {
	promise.catch(error => {
		if (!(error instanceof Cancelled)) {
			throw error;
		}
	});
};

// Mormor speaks with an old voice, and Mamma with a quick one. The Grandma voice of macOS is the best Mormor.
const voiceFor = who => {
	const voices = globalThis.speechSynthesis?.getVoices() ?? [];
	const english = voices.filter(voice => voice.lang.startsWith('en'));

	if (who === 'mormor') {
		return voices.find(voice => /grandma/i.test(voice.name)) ?? english.find(voice => /moira|fiona|karen|tessa|samantha|female/i.test(voice.name)) ?? english[0];
	}

	return english.find(voice => /samantha|karen|female/i.test(voice.name)) ?? english[0];
};

const formatDuration = seconds => {
	const minutes = Math.floor(seconds / 60);
	const rest = seconds % 60;
	return minutes > 0 ? `${minutes} min ${rest} s` : `${rest} s`;
};

const clock = seconds => `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;

// The directory of the ILS server: the strangers of 1999 who were logged on, and Mormor.
const people = [
	{id: 'mormor', media: '🔊📹', name: 'MORMOR', email: 'mormor.alesund@online.no', city: 'Ålesund, Norway', comment: 'HELLO IS THIS ON'},
	{id: 'dan', media: '🔊📹', name: 'Dan', email: 'trucker_dan@aol.com', city: 'Ohio, USA', comment: 'Anyone with a camera want to talk trucks?'},
	{id: 'raven', media: '🔊', name: 'Raven', email: 'xXRavenXx@hotmail.com', city: 'Leeds, UK', comment: 'no ppl without webcam!!!'},
	{id: 'boris', media: '', name: 'Boris', email: 'boris.chess@mail.ru', city: 'Minsk', comment: 'Chess? I have no camera, only chess.'},
	{id: 'gary', media: '🔊📹', name: 'Gary', email: 'quickcam_gary@compuserve.com', city: 'Florida, USA', comment: 'testing my new webcam!!! wave if u see me'},
	{id: 'zorg', media: '🔊', name: 'Zorg', email: 'zorg@area51.net', city: 'Roswell, USA', comment: 'We come in peace. 14.4 only.'},
	{id: 'test', media: '', name: 'test', email: 'test@test.com', city: 'test', comment: 'test'},
	{id: 'olga', media: '🔊', name: 'Olga', email: 'olga.s@telia.se', city: 'Göteborg, Sweden', comment: 'Söker någon som talar svenska'},
	{id: 'me', media: '🔊📹', name: 'Sindre', email: 'sindre@online.no', city: 'Bergen, Norway', comment: 'Making a home page!!'},
];

// What happens when the visitor calls a stranger instead of Mormor.
const strangerAnswers = {
	dan: 'Dan accepted the call, looked at you for three seconds, said “You’re not a trucker,” and hung up.',
	raven: 'Raven did not accept your call.',
	boris: 'Boris accepted the call and moved his pawn. Then nothing happened for a long time. Boris hung up.',
	gary: 'Gary accepted the call! He waved. You waved. He hung up. What a time to be alive.',
	zorg: 'Zorg is in another call. With the mothership.',
	test: 'test did not accept your call. test.',
	olga: 'Olga accepted the call and asked something in Swedish. You said “Hej!” She hung up, happy.',
	me: 'You cannot call yourself. You tried, though.',
};

// Faster video has more frames in bigger blocks, and better quality fewer frames in smaller blocks, like the slider of NetMeeting.
const qualities = {
	1: {fps: 4, block: 8, name: 'Faster video: 4 frames a second, in big blocks.'},
	2: {fps: 2, block: 4, name: 'In between: 2 frames a second.'},
	3: {fps: 1, block: 2, name: 'Better quality: 1 frame a second, in small blocks.'},
};

const ellipse = (context, x, y, radiusX, radiusY, color, rotation = 0) => {
	context.fillStyle = color;
	context.beginPath();
	context.ellipse(x, y, radiusX, radiusY, rotation, 0, Math.PI * 2);
	context.fill();
};

// The living room of Mormor: flowered wallpaper, a painting of a fjord, and a window with rain, as it always rains in Ålesund.
const drawLivingRoom = (context, frame) => {
	context.fillStyle = '#d9c9a3';
	context.fillRect(0, 0, 160, 120);
	context.fillStyle = '#c2a675';

	for (let y = 5; y < 120; y += 14) {
		for (let x = ((y / 14) % 2 < 1 ? 4 : 12); x < 160; x += 16) {
			context.fillRect(x, y, 3, 3);
		}
	}

	context.fillStyle = '#6b4a2a';
	context.fillRect(12, 12, 36, 28);
	context.fillStyle = '#9cc8e8';
	context.fillRect(15, 15, 30, 22);
	context.fillStyle = '#3a6a4a';
	context.beginPath();
	context.moveTo(15, 32);
	context.lineTo(24, 20);
	context.lineTo(31, 28);
	context.lineTo(37, 22);
	context.lineTo(45, 32);
	context.fill();
	context.fillStyle = '#2a5a8a';
	context.fillRect(15, 32, 30, 5);
	context.fillStyle = '#7f95a6';
	context.fillRect(122, 8, 32, 46);
	context.strokeStyle = '#ffffff';
	context.lineWidth = 2;
	context.strokeRect(122, 8, 32, 46);
	context.beginPath();
	context.moveTo(138, 8);
	context.lineTo(138, 54);
	context.moveTo(122, 31);
	context.lineTo(154, 31);
	context.stroke();
	context.strokeStyle = 'rgba(255, 255, 255, 0.55)';
	context.lineWidth = 1;
	context.beginPath();

	for (let x = 125; x < 154; x += 5) {
		const offset = (frame * 6 + x) % 12;
		context.moveTo(x, 10 + offset);
		context.lineTo(x - 2, 16 + offset);
		context.moveTo(x + 2, 32 + offset);
		context.lineTo(x, 38 + offset);
	}

	context.stroke();
};

// Mormor, around her nose: gray curls, round glasses, rosy cheeks, and the red cardigan that she knitted.
const drawMormor = (context, {x, y, scale, eyes = 'open', mouth = 'smile', tilt = 0, glow = false}) => {
	context.save();
	context.translate(x, y);
	context.rotate(tilt);
	context.scale(scale, scale);
	ellipse(context, 0, 78, 62, 42, '#b02a2a');
	context.fillStyle = '#f4e6d0';

	for (let row = 0; row < 3; row++) {
		for (let column = -6; column <= 6; column++) {
			context.fillRect((column * 9) + (row % 2 === 0 ? 0 : 4.5) - 1, 46 + (row * 7), 2, 2);
		}
	}

	context.fillStyle = '#e8b896';
	context.fillRect(-9, 24, 18, 16);
	ellipse(context, 0, 40, 14, 5, '#f8f8f8');

	for (const [curlX, curlY, radius] of [[-26, -8, 15], [26, -8, 15], [0, -34, 24], [-18, -28, 16], [18, -28, 16], [0, -54, 12], [-29, 8, 9], [29, 8, 9]]) {
		ellipse(context, curlX, curlY, radius, radius, '#cbcbcb');
	}

	ellipse(context, 0, 0, 25, 31, '#f2c9a6');

	for (const curlX of [-16, -6, 5, 15]) {
		ellipse(context, curlX, -27, 8, 6, '#dadada');
	}

	ellipse(context, -14, 9, 6, 4, 'rgba(230, 110, 110, 0.5)');
	ellipse(context, 14, 9, 6, 4, 'rgba(230, 110, 110, 0.5)');
	context.strokeStyle = '#3a2a1a';
	context.fillStyle = '#3a2a1a';
	context.lineWidth = 1.5;

	for (const eyeX of [-11, 11]) {
		if (eyes === 'closed') {
			context.beginPath();
			context.moveTo(eyeX - 4, -3);
			context.lineTo(eyeX + 4, -3);
			context.stroke();
		} else if (eyes === 'half') {
			context.fillRect(eyeX - 4, -3, 8, 2);
		} else {
			ellipse(context, eyeX, eyes === 'down' ? -1 : -3, 2.4, 2.4, '#2a3a5a');
		}
	}

	context.strokeStyle = '#5a3a1a';
	context.lineWidth = 2.2;

	for (const eyeX of [-11, 11]) {
		context.beginPath();
		context.arc(eyeX, -3, 8, 0, Math.PI * 2);

		if (glow) {
			context.fillStyle = 'rgba(120, 170, 255, 0.55)';
			context.fill();
		}

		context.stroke();
	}

	context.beginPath();
	context.moveTo(-3, -4);
	context.lineTo(3, -4);
	context.stroke();
	context.strokeStyle = '#c08a6a';
	context.lineWidth = 1.5;
	context.beginPath();
	context.moveTo(0, -1);
	context.lineTo(-3, 8);
	context.lineTo(2, 9);
	context.stroke();
	context.strokeStyle = '#8a3a3a';
	context.fillStyle = '#5a1a1a';
	context.lineWidth = 1.8;

	if (mouth === 'open' || mouth === 'wide') {
		ellipse(context, 0, 17, mouth === 'wide' ? 8 : 6, mouth === 'wide' ? 7 : 4, '#5a1a1a');
	} else if (mouth === 'o') {
		ellipse(context, 0, 17, 3, 3.5, '#5a1a1a');
	} else {
		context.beginPath();
		context.arc(0, 12, 8, 0.2 * Math.PI, 0.8 * Math.PI);
		context.stroke();
	}

	context.fillStyle = '#f8f8f0';

	for (let bead = -5; bead <= 5; bead++) {
		ellipse(context, bead * 4, 44 + (Math.abs(bead) * 0.6), 1.6, 1.6, '#f8f8f0');
	}

	context.restore();
};

// Pusen, the cat of Mormor: a fat orange tabby.
const drawCat = (context, x, y, scale) => {
	context.save();
	context.translate(x, y);
	context.scale(scale, scale);
	context.fillStyle = '#e08a2a';

	for (const side of [-1, 1]) {
		context.beginPath();
		context.moveTo(side * 34, -20);
		context.lineTo(side * 40, -58);
		context.lineTo(side * 10, -36);
		context.fill();
	}

	ellipse(context, 0, 0, 45, 38, '#e08a2a');
	context.fillStyle = '#b8601a';

	for (const stripeX of [-12, 0, 12]) {
		context.fillRect(stripeX - 2, -38, 4, 14);
	}

	for (const side of [-1, 1]) {
		ellipse(context, side * 16, -6, 9, 7, '#9acd32');
		ellipse(context, side * 16, -6, 2, 6, '#000000');
	}

	context.fillStyle = '#ff9aa8';
	context.beginPath();
	context.moveTo(-5, 6);
	context.lineTo(5, 6);
	context.lineTo(0, 12);
	context.fill();
	context.strokeStyle = '#ffffff';
	context.lineWidth = 1;
	context.beginPath();

	for (const side of [-1, 1]) {
		for (const lift of [-4, 0, 4]) {
			context.moveTo(side * 12, 12);
			context.lineTo(side * 44, 10 + (lift * 2));
		}
	}

	context.stroke();
	context.restore();
};

// The heart waffle of Mormor, with brunost on it.
const drawWaffle = (context, x, y) => {
	for (let index = 0; index < 5; index++) {
		const angle = (index / 5) * Math.PI * 2 - (Math.PI / 2);
		ellipse(context, x + (Math.cos(angle) * 18), y + (Math.sin(angle) * 18), 16, 14, '#d9a441', angle);
	}

	ellipse(context, x, y, 16, 16, '#d9a441');
	context.strokeStyle = '#a8742a';
	context.lineWidth = 1;
	context.beginPath();

	for (let offset = -36; offset <= 36; offset += 6) {
		context.moveTo(x + offset, y - 36);
		context.lineTo(x + offset, y + 36);
		context.moveTo(x - 36, y + offset);
		context.lineTo(x + 36, y + offset);
	}

	context.stroke();
	context.fillStyle = '#b8732e';
	context.fillRect(x - 10, y - 6, 20, 10);
};

// The ceiling of the living room with its lamp, and the chin and nostrils of Mormor from below, as the camera points up.
const drawCeiling = context => {
	context.fillStyle = '#ece6d6';
	context.fillRect(0, 0, 160, 120);
	context.fillStyle = '#d4cbb4';
	context.beginPath();
	context.moveTo(0, 70);
	context.lineTo(40, 58);
	context.lineTo(160, 76);
	context.lineTo(160, 120);
	context.lineTo(0, 120);
	context.fill();
	context.strokeStyle = '#6a6a6a';
	context.lineWidth = 1;
	context.beginPath();
	context.moveTo(96, 0);
	context.lineTo(96, 22);
	context.stroke();
	ellipse(context, 96, 30, 22, 10, '#f6efb8');
	ellipse(context, 96, 34, 14, 4, '#fffbe0');
	ellipse(context, 74, 134, 50, 30, '#f2c9a6');
	ellipse(context, 66, 112, 4, 2.5, '#6a3a2a');
	ellipse(context, 82, 112, 4, 2.5, '#6a3a2a');
	context.strokeStyle = '#5a3a1a';
	context.lineWidth = 3;
	context.beginPath();
	context.arc(52, 96, 14, 0.15 * Math.PI, 0.85 * Math.PI);
	context.arc(96, 96, 14, 0.15 * Math.PI, 0.85 * Math.PI);
	context.stroke();
};

// What Mormor’s camera shows, by the scene, and what a screen reader hears about it.
const scenes = {
	normal: {
		label: 'Mormor, smiling in her living room',
		draw(context, look, frame) {
			drawLivingRoom(context, frame);
			drawMormor(context, {x: 80 + look.bobX, y: 64 + look.bobY, scale: 1, ...look});
		},
	},
	close: {
		label: 'Mormor’s nose and glasses, much too close to the camera',
		draw(context, look, frame) {
			drawLivingRoom(context, frame);
			drawMormor(context, {x: 82 + look.bobX, y: 58 + look.bobY, scale: 3.3, ...look});
		},
	},
	forehead: {
		label: 'only Mormor’s forehead and her gray curls',
		draw(context, look, frame) {
			drawLivingRoom(context, frame);
			drawMormor(context, {x: 80 + look.bobX, y: 130 + look.bobY, scale: 1.5, ...look});
		},
	},
	ceiling: {
		label: 'the ceiling and the lamp, and Mormor’s nostrils at the bottom',
		draw(context) {
			drawCeiling(context);
		},
	},
	finger: {
		label: 'a big pink finger over the camera',
		draw(context, look, frame) {
			scenes.normal.draw(context, look, frame);
			ellipse(context, 30, 72, 46, 74, 'rgba(232, 160, 150, 0.95)', 0.3);
			ellipse(context, 46, 18, 14, 18, 'rgba(250, 210, 205, 0.95)', 0.3);
		},
	},
	upside: {
		label: 'Mormor, upside down',
		draw(context, look, frame) {
			context.save();
			context.translate(160, 120);
			context.rotate(Math.PI);
			scenes.normal.draw(context, look, frame);
			context.restore();
		},
	},
	cat: {
		label: 'Pusen, the cat, very close',
		draw(context, look, frame) {
			drawLivingRoom(context, frame);
			drawCat(context, 80 + look.bobX, 70 + look.bobY, 1.25);
		},
	},
	waffle: {
		label: 'Mormor holds up a heart waffle with brunost',
		draw(context, look, frame) {
			scenes.normal.draw(context, look, frame);
			drawWaffle(context, 80, 92);
		},
	},
	empty: {
		label: 'an empty chair. Mormor went to get coffee',
		draw(context, look, frame) {
			drawLivingRoom(context, frame);
			context.fillStyle = '#7a4a2a';
			context.fillRect(48, 50, 64, 70);
			context.fillStyle = '#9a6a3a';
			context.fillRect(54, 56, 52, 64);
			context.fillStyle = '#7a4a2a';

			for (const slatX of [64, 78, 92]) {
				context.fillRect(slatX, 56, 4, 64);
			}
		},
	},
	search: {
		label: 'Mormor, very close, looking down at her screen, blue light in her glasses',
		draw(context, look, frame) {
			drawLivingRoom(context, frame);
			drawMormor(context, {x: 80 + look.bobX, y: 70 + look.bobY, scale: 2.1, ...look, eyes: 'down', glow: true});
		},
	},
	static: {
		label: 'snow, as the line breaks',
		draw(context) {
			for (let y = 0; y < 120; y += 4) {
				for (let x = 0; x < 160; x += 4) {
					const gray = randomInteger(20, 230);
					context.fillStyle = `rgb(${gray}, ${gray}, ${gray})`;
					context.fillRect(x, y, 4, 4);
				}
			}
		},
	},
	dark: {
		label: 'nothing, it is black',
		draw(context) {
			context.fillStyle = '#000000';
			context.fillRect(0, 0, 160, 120);
		},
	},
	calling: {
		label: 'Calling Mormor',
	},
};

// My video: a drawing of me with my headset, in my room with the unicorn poster.
const drawSindre = (context, isTalking) => {
	context.fillStyle = '#6d8fd0';
	context.fillRect(0, 0, 160, 120);
	context.fillStyle = '#ffb6e6';
	context.fillRect(104, 10, 44, 36);
	context.font = '24px sans-serif';
	context.textAlign = 'center';
	context.fillText('🦄', 126, 38);
	ellipse(context, 72, 132, 52, 36, '#cc1f1f');
	context.fillStyle = '#ffffff';
	context.font = 'bold 12px sans-serif';
	context.fillText('B', 72, 116);
	context.fillStyle = '#f0c8a8';
	context.fillRect(64, 84, 16, 14);
	ellipse(context, 72, 62, 24, 28, '#f6d2b4');
	context.fillStyle = '#f2d24a';
	context.beginPath();
	context.moveTo(46, 54);

	for (let spike = 0; spike <= 8; spike++) {
		context.lineTo(46 + (spike * 6.5), spike % 2 === 0 ? 24 : 36);
	}

	context.lineTo(98, 54);
	context.quadraticCurveTo(72, 40, 46, 54);
	context.fill();
	ellipse(context, 63, 60, 2.5, 2.5, '#2a5ab0');
	ellipse(context, 81, 60, 2.5, 2.5, '#2a5ab0');
	context.fillStyle = '#c87a5a';

	for (const [freckleX, freckleY] of [[60, 68], [64, 70], [80, 68], [84, 70]]) {
		context.fillRect(freckleX, freckleY, 1.5, 1.5);
	}

	if (isTalking && Math.random() < 0.7) {
		ellipse(context, 72, 78, 5, 4, '#6a1a1a');
	} else {
		context.strokeStyle = '#6a1a1a';
		context.lineWidth = 1.5;
		context.beginPath();
		context.arc(72, 72, 7, 0.2 * Math.PI, 0.8 * Math.PI);
		context.stroke();
	}

	// The headset of a NetMeeting call, with the microphone at the mouth.
	context.strokeStyle = '#303030';
	context.lineWidth = 3;
	context.beginPath();
	context.arc(72, 58, 28, Math.PI, 0);
	context.stroke();
	ellipse(context, 44, 62, 5, 8, '#303030');
	context.lineWidth = 2;
	context.beginPath();
	context.moveTo(44, 68);
	context.quadraticCurveTo(48, 82, 62, 80);
	context.stroke();
	ellipse(context, 63, 80, 3, 3, '#303030');
};

// The photo of Pusen that Mormor sends: asleep on the sofa, with her thumb over a corner.
const drawPhoto = canvas => {
	const context = canvas.getContext('2d');
	context.fillStyle = '#2f5a3a';
	context.fillRect(0, 0, 80, 60);
	context.fillStyle = '#3f6a4a';
	context.fillRect(0, 34, 80, 26);
	ellipse(context, 38, 38, 24, 13, '#e08a2a');
	ellipse(context, 18, 30, 10, 9, '#e08a2a');
	context.fillStyle = '#e08a2a';
	context.beginPath();
	context.moveTo(11, 24);
	context.lineTo(12, 15);
	context.lineTo(18, 22);
	context.moveTo(20, 22);
	context.lineTo(25, 15);
	context.lineTo(26, 25);
	context.fill();
	context.fillStyle = '#b8601a';

	for (const stripeX of [30, 38, 46]) {
		context.fillRect(stripeX, 27, 3, 10);
	}

	context.strokeStyle = '#3a2a1a';
	context.beginPath();
	context.moveTo(14, 30);
	context.lineTo(17, 30);
	context.moveTo(20, 30);
	context.lineTo(23, 30);
	context.stroke();
	ellipse(context, 74, 6, 18, 16, 'rgba(240, 170, 160, 0.9)');
	context.fillStyle = '#ff9a2a';
	context.font = 'bold 6px monospace';
	context.textAlign = 'right';
	context.fillText('\'99 10 09', 78, 57);
};

const stopTracks = stream => {
	for (const track of stream?.getTracks() ?? []) {
		track.stop();
	}
};

// What I can say, and what Mormor answers when it arrives.
const yourLines = {
	hello: 'Hei, Mormor!',
	hear: 'Can you hear me?',
	camera: 'Move the camera down!',
	cat: 'Where is Pusen?',
	draw: 'Draw something!',
	love: 'Jeg er glad i deg, Mormor.',
	bye: 'Ha det, Mormor!',
};

const collisionLines = [
	'Oh! Sorry. You go first, dear.',
	'No, no, you go.',
	'You go! … No, you!',
	'HELLO? Are you still there? The sound comes so late!',
];

// The camera of Mormor goes everywhere but down, until it is right.
const cameraSteps = [
	{scene: 'forehead', text: 'Down? Like this?'},
	{scene: 'ceiling', text: 'Now? I pushed it down.'},
	{scene: 'finger', text: 'Oops. That is my finger.'},
	{scene: 'close', text: 'Better? I can see myself in the little window!'},
	{scene: 'upside', text: 'Oh no, I turned it the wrong way!'},
	{scene: 'normal', text: 'THERE! Can you see me now? Good. I am not touching it again.'},
];

// What Mormor does by herself, now and then, when nothing else goes on. With reduced motion, she only talks, and the picture does not change by itself.
const spontaneous = [
	{text: 'Is it raining in Bergen? Here it is raining. It always rains.'},
	{text: 'Have you eaten? You look thin. Maybe it is the picture.'},
	{text: 'Your mamma says you are on the computer ALL day.'},
	{text: 'I made waffles. With brunost. Look! Can you smell it?', scene: 'waffle', after: 'normal'},
	{text: 'Wait, I hear the kettle. Do not go anywhere!', scene: 'empty', pause: 9000, back: 'I am back! Where were we?'},
	{text: 'Ingrid at the library says the Internet is full of strangers. Are YOU a stranger?'},
	{text: 'This is like Star Trek! Your grandfather would have loved this.'},
	{text: 'Oops. I bumped the little camera.', scene: 'forehead'},
	{text: 'PUSEN! Get down from the keyboard!', scene: 'cat', after: 'normal', meow: true},
];

const incomingTexts = [
	'Mormor (mormor.alesund@online.no) is calling you. Do you want to accept the call?',
	'Mormor is calling you again. Do you want to accept the call?',
	'Mormor is calling you. For the third time. Do you want to accept the call?',
];

const openingLines = {
	outgoing: 'HELLO? SINDRE? Is it on? I pressed the green telephone.',
	ignored: 'Sorry, dear! I pressed Ignore. Ingrid at the library said to always press No when the computer asks something.',
	hungup: 'Hello again! I think we got cut off. Or did you hang up on your old Mormor?',
	mamma: 'We got cut off! Your mamma called me on the telephone to tell me. The Internet is so funny.',
};

const endTexts = {
	you: {history: 'You hung up', text: 'You hung up.'},
	plug: {history: 'Mormor pulled the plug', text: 'Mormor left the call. She pulled out the plug.'},
	mamma: {history: 'The line dropped: Mamma picked up the phone', text: 'The line dropped. Mamma picked up the phone in the kitchen.'},
};

// The keys around each key, for her typos.
const keyRows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];

const neighborOf = character => {
	for (const [rowIndex, row] of keyRows.entries()) {
		const index = row.indexOf(character);

		if (index !== -1) {
			const choices = [row[index - 1], row[index + 1], keyRows[rowIndex + 1]?.[index], keyRows[rowIndex - 1]?.[index]].filter(Boolean);
			return randomItem(choices);
		}
	}

	return character;
};

const chatAnswer = text => {
	const lower = text.toLowerCase();

	if (/pusen|cat|katt/.test(lower)) {
		return 'PUSEN IS SLEEPING ON THE TV. IT IS WARM THERE';
	}

	if (/waffle|vaffel|brunost/.test(lower)) {
		return 'I HAVE WAFFLES. COME TO ÅLESUND';
	}

	if (/caps|shout|big letters|small letters/.test(lower)) {
		return 'I AM NOT SHOUTING. THE COMPUTER WRITES BIG';
	}

	if (/love|glad i deg/.test(lower)) {
		return 'I LOVE YOU TOO. MORE THAN THE CAT. LOVE MORMOR';
	}

	if (/\b(hei|hi|hello|hallo)\b/.test(lower)) {
		return 'HELLO!!!! IT WORKS!!!!';
	}

	if (lower.endsWith('?')) {
		return 'I DO NOT KNOW. ASK YOUR MAMMA';
	}

	return randomItem(['WHAT', 'YES', 'I TYPE WITH ONE FINGER IT TAKES TIME', 'OK. LOVE MORMOR', 'HOW DO YOU MAKE SMALL LETTERS']);
};

// Mormor’s cat: a potato with ears, little potato eyes that are really his spots, whiskers, legs, and a tail.
const potatoCatStrokes = () => {
	const centerX = 228;
	const centerY = 112;
	const body = [];

	for (let angle = 0; angle <= Math.PI * 2 + 0.01; angle += 0.16) {
		const radius = 1 + (0.12 * Math.sin(angle * 3)) + (0.07 * Math.sin((angle * 5) + 1)) + (0.04 * Math.sin((angle * 7) + 2));
		body.push([centerX + (62 * radius * Math.cos(angle)), centerY + (40 * radius * Math.sin(angle))]);
	}

	const dot = (x, y) => [[x, y], [x + 1, y + 1], [x, y + 1]];
	const tail = [];

	for (let step = 0; step <= 10; step++) {
		tail.push([centerX + 54 + (step * 3), centerY - (step * 4) + (Math.sin(step * 0.8) * 4)]);
	}

	return [
		body,
		[[centerX - 30, centerY - 34], [centerX - 27, centerY - 46], [centerX - 20, centerY - 37]],
		[[centerX - 6, centerY - 39], [centerX, centerY - 50], [centerX + 6, centerY - 39]],
		dot(centerX - 24, centerY - 12),
		dot(centerX - 4, centerY - 14),
		[[centerX - 18, centerY - 2], [centerX - 14, centerY + 2], [centerX - 10, centerY - 2]],
		[[centerX - 30, centerY - 4], [centerX - 52, centerY - 10]],
		[[centerX - 30, centerY], [centerX - 54, centerY]],
		[[centerX - 30, centerY + 4], [centerX - 50, centerY + 10]],
		[[centerX + 6, centerY - 4], [centerX + 24, centerY - 10]],
		[[centerX + 6, centerY], [centerX + 26, centerY + 2]],
		dot(centerX + 18, centerY + 14),
		dot(centerX - 2, centerY + 20),
		dot(centerX + 30, centerY - 4),
		...[-30, -12, 10, 28].map(legX => [[centerX + legX, centerY + 32], [centerX + legX, centerY + 44]]),
		tail,
	];
};

const guesses = [
	'Oh, is that a horse?',
	'A boat! Or is it me?',
	'Is it Glitter, your unicorn?',
	'Very nice! What is it?',
	'Is it the fjord? It is the fjord.',
	'That is a good potato. Oh, it is not a potato?',
];

const penColors = {black: '#000000', red: '#ff0000', blue: '#0000ff', green: '#008000', orange: '#ff8000'};

// The icons of my shared desktop.
const shareIcons = {
	computer: {label: 'My Computer', icon: '🖥️', x: 8, y: 8},
	bin: {label: 'Recycle Bin', icon: '🗑️', x: 8, y: 60},
	homework: {label: 'HOMEWORK.DOC', icon: '📄', x: 8, y: 112},
	games: {label: 'MY GAMES', icon: '📁', x: 64, y: 8},
	glitter: {label: 'GLITTER.EXE', icon: '🦄', x: 64, y: 60},
};

const drawShareWindow = (context, {title, x, y, width, height, lines}) => {
	context.fillStyle = '#c0c0c0';
	context.fillRect(x, y, width, height);
	context.strokeStyle = '#ffffff';
	context.strokeRect(x + 0.5, y + 0.5, width - 1, height - 1);
	context.fillStyle = '#000080';
	context.fillRect(x + 2, y + 2, width - 4, 11);
	context.fillStyle = '#ffffff';
	context.font = 'bold 8px sans-serif';
	context.textAlign = 'left';
	context.fillText(title, x + 4, y + 10);
	context.fillStyle = '#ffffff';
	context.fillRect(x + 3, y + 15, width - 6, height - 18);
	context.fillStyle = '#000000';
	context.font = '8px sans-serif';

	for (const [index, line] of lines.entries()) {
		context.fillText(line, x + 6, y + 25 + (index * 10));
	}
};

const files = {
	in: {name: 'PUSEN.BMP', size: 150},
	out: {name: 'ROCKY.BMP', size: 58},
};

const timeLeft = seconds => {
	const minutes = Math.round(seconds / 60);
	return seconds < 60 ? 'Less than a minute left.' : (minutes === 1 ? 'About a minute left.' : `About ${minutes} minutes left.`);
};


export default class extends GeoCitiesElement {
	#viewButtons;
	#panels;
	#toolPanels;
	#toolButtons;
	#colorButtons;
	#remoteContext;
	#localContext;
	#boardContext;
	#shareContext;
	#photoContext;
	#videoTimer;
	#meterTimer;
	#clockTimer;

	// The things of a call wait while NetMeeting is out of sight, so Mormor does not talk, type, and draw to nobody.
	#resumeWaiters = [];

	#call = {
		token: 0,
		state: 'idle',
		seconds: 0,
		delay: 0,
		scene: 'dark',
		frame: 0,
		isFrozen: false,
		isAwkward: false,
		isVideoPaused: false,
		isSayingGoodbye: false,
		mouthUntil: 0,
		speakingUntil: 0,
		heardUntil: 0,
		yourMouthUntil: 0,
		collisions: 0,
		cameraStep: 0,
		loveCount: 0,
		events: 0,
		hasOpenedChat: false,
		lastGuess: 0,
		lastMuted: 0,
	};

	#sounds = {
		ring: () => {
			for (let index = 0; index < 3; index++) {
				this.#tone(1046.5, index * 0.32, 0.14, {type: 'square', volume: 0.035});
				this.#tone(784, (index * 0.32) + 0.14, 0.14, {type: 'square', volume: 0.035});
			}
		},
		connect: () => {
			this.#tone(523.25, 0, 0.12, {type: 'triangle'});
			this.#tone(783.99, 0.12, 0.25, {type: 'triangle'});
		},
		hangUp: () => {
			this.#tone(783.99, 0, 0.12, {type: 'triangle'});
			this.#tone(392, 0.12, 0.3, {type: 'triangle'});
		},
		meow: () => {
			this.#tone(620, 0, 0.2, {type: 'triangle', volume: 0.07, slide: 950});
			this.#tone(950, 0.2, 0.45, {type: 'triangle', volume: 0.07, slide: 480});
		},
		blip: () => {
			this.#tone(1318.5, 0, 0.06, {type: 'square', volume: 0.025});
		},
		modemScream: () => {
			this.#noise(0, 1.8, {frequency: 2200, q: 0.4, volume: 0.1});
			this.#tone(2100, 0, 1.4, {type: 'square', volume: 0.025});
			this.#tone(1200, 0.4, 1.2, {type: 'sawtooth', volume: 0.025, slide: 2400});
			this.#noise(2, 0.05, {frequency: 500, volume: 0.2});
		},
		// The dial tone of Norway is 425 Hz.
		dial: () => {
			this.#tone(425, 0, 1.6, {volume: 0.07});
		},
	};

	// The voice stops only while it says something of NetMeeting, so it does not cut off the voice of another toy of the page.
	#utterances = new Set();

	// The history of the calls, kept in the browser.
	#callHistory = [];

	// Mormor is picked from the start, so Call calls her at once.
	#directory = {
		isLoggedOn: false,
		attempts: 0,
		selected: 'mormor',
		isDialingStranger: false,
	};

	// The directory server of Microsoft was always busy in the evening. ils.microsoft.com lets the visitor in on the second try, and the others never do.
	#logOnRun = 0;

	// The videos. Mormor’s is drawn at full size, then made small and blown up again, in blocks as big as the quality allows.
	#sceneCanvas = new OffscreenCanvas(160, 120);

	#scene = this.#sceneCanvas.getContext('2d');

	#smallCanvas = new OffscreenCanvas(40, 30);

	#small = this.#smallCanvas.getContext('2d');

	// My video: a drawing of me with my headset, in my room with the unicorn poster, or the real webcam of the visitor, made small and blocky.
	#webcam = {stream: undefined, video: undefined, isAsking: false};

	#webcamCanvas = new OffscreenCanvas(160, 120);

	#webcamContext = this.#webcamCanvas.getContext('2d');

	// The subtitles of the call: what Mormor says, when her sound arrives, and what I say.
	#subtitleTimers = new Map();

	// What Mormor does, one thing at a time, in turn.
	#mormorChain = Promise.resolve();

	#mormorPending = 0;

	#answers = {
		hello: async token => {
			await this.#speakLine(token, 'HEI, SINDRE! Oh, I can see you! You are so small! Are you in the little box?');
		},
		hear: async token => {
			await this.#speakLine(token, randomItem(['WHAT? Yes! I can hear you! Can YOU hear ME?', 'I CAN HEAR YOU! I talk loud, as it is far to Bergen!']));
		},
		camera: async token => {
			if (this.#call.scene === 'normal') {
				await this.#speakLine(token, 'It is perfect now! Your Mormor is a computer expert.');
				return;
			}

			const step = cameraSteps[this.#call.cameraStep % cameraSteps.length];
			this.#call.cameraStep++;
			await this.#speakLine(token, step.text, {scene: step.scene});

			if (step.scene === 'normal') {
				this.#call.cameraStep = 0;
			}
		},
		cat: async token => {
			await this.#speakLine(token, 'PUSEN! Kom hit, pus pus pus!', {scene: 'normal'});
			await this.#during(token, 1200);
			this.#setScene('cat');
			this.#sounds.meow();
			await this.#speakLine(token, 'Here he is! Say hei to Sindre, Pusen! … I will send you a photo of him. Ingrid at the library scanned it for me.');
			this.#setScene('normal');
			inBackground(this.#startTransfer(token, 'in'));
		},
		draw: async token => {
			this.#setTool('whiteboard', true);

			if (this.#hasCatOnBoard) {
				await this.#speakLine(token, 'I drew Pusen already! Look at the board. My hand is tired, dear.');
				return;
			}

			await this.#drawPotatoCat(token);
		},
		love: async token => {
			this.#call.loveCount++;

			if (this.#call.loveCount === 1) {
				await this.#speakLine(token, 'What, dear? The sound went away. Say it one more time.');
				return;
			}

			this.#call.loveCount = 0;
			await this.#speakLine(token, 'Oh… Jeg er glad i deg også, vennen min. Very, very much. More than the cat. Do not tell Pusen.', {scene: 'normal'});
		},
		bye: async token => {
			await this.#sayGoodbye(token);
		},
	};

	// The call: ringing, the first call that Mormor ignores, the calls she makes back, and the end.
	#hasMormorAnswered = false;

	#hasMammaPickedUp = false;

	// The Chat: Mormor types with caps lock on and one finger, letter by letter, and fixes her typos.
	#chatChain = Promise.resolve();

	#hasCatWalkedOnKeyboard = false;

	// The Whiteboard: both of us draw. What is drawn is kept on its own canvas, and the pointers of the pens go on top.
	#ink = new OffscreenCanvas(320, 200);

	#inkContext = this.#ink.getContext('2d');

	#pen = {x: 160, y: 100, isDown: false, isDrawing: false, color: '#000000', last: undefined, hasFocus: false};

	#mormorPen = {x: 0, y: 0, isShown: false};

	#hasCatOnBoard = false;

	#guessTimer;

	// Sharing: Mormor sees my desktop, and with Collaborate, she clicks everything. Mormor drags the homework around, so the icons are a copy.
	#shareIcons = structuredClone(shareIcons);

	#share = {
		isOn: false,
		hasControl: false,
		run: 0,
		cursor: {x: 200, y: 120},
		windows: [],
		wallpaper: 'teal',
		isHomeworkInBin: false,
		hasUnicorn: false,
		hasShutDownDialog: false,
		dragging: undefined,
	};

	// File Transfer: the photo of Pusen over a modem, which shares the line with the video, so it goes faster with the video paused. A BMP is stored from the bottom up, so it appears from the bottom.
	#photoSource = new OffscreenCanvas(80, 60);

	#transfer = {run: 0, isActive: false, direction: 'in'};

	// The window: the directory logs on when NetMeeting opens the first time, and everything waits while it is closed, off the screen, or the tab is hidden.
	#hasOpened = false;

	connected() {
		const {sound: soundButton, remoteVideo, localVideo, board, shareScreen, photo} = this.parts;
		this.#viewButtons = [...this.querySelectorAll('[data-netmeeting-view]')];
		this.#panels = new Map([...this.querySelectorAll('[data-netmeeting-panel]')].map(panel => [panel.dataset.netmeetingPanel, panel]));
		this.#toolPanels = new Map([...this.querySelectorAll('[data-netmeeting-tool]')].map(panel => [panel.dataset.netmeetingTool, panel]));
		this.#toolButtons = new Map([['chat', this.parts.chat], ['whiteboard', this.parts.whiteboard], ['share', this.parts.share], ['transfer', this.parts.sendFile]]);
		this.#colorButtons = [...this.querySelectorAll('[data-netmeeting-color]')];
		this.#remoteContext = remoteVideo.getContext('2d');
		this.#localContext = localVideo.getContext('2d');
		this.#boardContext = board.getContext('2d');
		this.#shareContext = shareScreen.getContext('2d');
		this.#photoContext = photo.getContext('2d');
		this.#inkContext.lineCap = 'round';
		this.#inkContext.lineJoin = 'round';
		this.#callHistory = this.stored('history', []).filter(entry => ['time', 'who', 'result'].every(key => typeof entry?.[key] === 'string'));

		this.on(soundButton, 'click', () => {
			const isOn = soundButton.getAttribute('aria-pressed') !== 'true';
			soundButton.setAttribute('aria-pressed', String(isOn));
			soundButton.firstElementChild.textContent = isOn ? '🔊' : '🔈';

			if (isOn) {
				soundButton.dataset.state = 'on';

				// The desktop starts its audio in the handler of this click, as browsers only allow sound after one.
				this.sound();
				this.#sounds.blip();
				this.say('Sound is on: the ringing, the modem, and Mormor’s voice.');
			} else {
				delete soundButton.dataset.state;
				this.#stopSpeaking();
				this.say('Sound is off. The subtitles still show what Mormor says.');
			}
		});

		for (const button of this.#viewButtons) {
			this.on(button, 'click', () => {
				this.#showView(button.dataset.netmeetingView);
			});
		}

		this.#showView('directory');

		this.#renderHistory();

		this.on(this.parts.refresh, 'click', () => {
			this.#logOn();
		});

		this.on(this.parts.server, 'change', () => {
			this.#logOn();
		});

		// SpeedDial calls without the directory, like in NetMeeting.
		for (const button of this.querySelectorAll('[data-netmeeting-dial]')) {
			this.on(button, 'click', async () => {
				const who = button.dataset.netmeetingDial;

				if (who === 'mormor') {
					this.#placeCall();
				} else if (who === 'trond') {
					await this.ask({icon: '📞', text: 'Trond is not logged on. His mamma is on the phone, with your mamma.', opener: button});
				} else {
					await this.ask({icon: '🏢', text: 'The computer at Pappa’s office does not answer. The IT department said no to NetMeeting.', opener: button});
				}
			});
		}

		this.on(this.parts.webcam, 'click', async () => {
			if (this.#webcam.stream) {
				this.#stopWebcam();
				this.say('Your webcam is off. Mormor sees the drawing of Sindre again.');
				return;
			}

			if (this.#webcam.isAsking) {
				return;
			}

			if (this.#call.state !== 'connected') {
				this.say('Wait until Mormor answers, then turn on your webcam.');
				return;
			}

			if (!navigator.mediaDevices?.getUserMedia) {
				this.say('This computer has no webcam drivers. Mormor sees the drawing of Sindre.');
				return;
			}

			this.say('Asking for your webcam. Nothing leaves your computer: the picture is only drawn here, small and blocky.');
			const token = this.#call.token;
			const video = document.createElement('video');
			video.muted = true;
			video.playsInline = true;
			this.#webcam.isAsking = true;
			let stream;

			try {
				stream = await navigator.mediaDevices.getUserMedia({video: {width: {ideal: 160}, height: {ideal: 120}}, audio: false});
				video.srcObject = stream;
				await video.play();
			} catch {
				stopTracks(stream);
				this.say('No webcam, or the browser said no. Mormor sees the drawing of Sindre.');
				return;
			} finally {
				this.#webcam.isAsking = false;
			}

			// The call could have ended, or NetMeeting gone out of sight, while the browser asked.
			if (token !== this.#call.token || !this.isVisible) {
				stopTracks(stream);
				this.say('The webcam stays off: the call ended, or NetMeeting went out of sight.');
				return;
			}

			this.#webcam.stream = stream;
			this.#webcam.video = video;
			this.parts.webcam.setAttribute('aria-pressed', 'true');
			this.parts.webcam.setAttribute('aria-label', 'Stop my real webcam');
			this.parts.localVideo.setAttribute('aria-label', 'My video: your real webcam, 160 × 120, in blocks');
			this.#drawLocal();			this.say('Your real webcam is on, at 160 × 120, like a QuickCam of 1999.');
			this.#queueLine(token, 'OH! Now I see the real you! You need a haircut. And some sleep.');
		});

		this.on(this.parts.quality, 'input', () => {
			this.#updateCallTimers();
			this.#videoFrame();
			this.say(this.#quality().name);
		});

		this.on(this.parts.remotePause, 'click', () => {
			this.#setVideoPaused(!this.#call.isVideoPaused);
			this.#call.isFrozen = false;
			this.#drawRemote();
			this.say(this.#call.isVideoPaused ? 'Mormor’s video is paused, so the modem has more room for files.' : 'Mormor’s video plays again.');
		});

		for (const button of this.querySelectorAll('[data-netmeeting-say]')) {
			this.on(button, 'click', () => {
				this.#sayToMormor(button.dataset.netmeetingSay);
			});
		}

		// Without the directory, only Mormor can be called, like with SpeedDial.
		this.on(this.parts.call, 'click', () => {
			this.#callPerson(this.#directory.isLoggedOn ? this.#directory.selected : 'mormor');
		});

		this.on(this.parts.hangUp, 'click', async () => {
			if (this.#call.state === 'ringing') {
				this.#call.token++;
				this.#call.state = 'idle';
				this.#showCallArea(false);
				this.parts.notInCall.textContent = 'You hung up before Mormor answered.';
				this.parts.callInfo.textContent = 'Not in a call';
				this.say('You hung up before Mormor answered.');
				return;
			}

			if (this.#call.state !== 'connected') {
				this.say('You are not in a call.');
				return;
			}

			if (this.#call.isSayingGoodbye) {
				this.#endCall('you');
				this.say('You hung up. In Ålesund, Mormor is still looking for the button.');
				return;
			}

			const answer = await this.ask({icon: '❓', text: 'Mormor did not say ha det yet. Do you want to hang up on your grandmother?', buttons: ['Yes', 'No'], opener: this.parts.hangUp});

			if (answer !== 'Yes' || this.#call.state !== 'connected') {
				return;
			}

			this.#endCall('you');
			this.say('You hung up on Mormor.');
			await this.#wait(6000);
			this.#incoming('hungup');
		});

		this.on(this.parts.chat, 'click', () => {
			if (this.#needsCall()) {
				return;
			}

			const isOpen = this.#toolPanels.get('chat').hidden;
			this.#setTool('chat', isOpen);

			if (isOpen && !this.#call.hasOpenedChat) {
				this.#call.hasOpenedChat = true;
				this.#mormorTypes(this.#call.token, 'HELLO SINDRE THIS IS MORMOR. LOVE MORMOR');
			}
		});

		this.on(this.parts.whiteboard, 'click', () => {
			if (this.#needsCall()) {
				return;
			}

			const isOpen = this.#toolPanels.get('whiteboard').hidden;
			this.#setTool('whiteboard', isOpen);

			if (isOpen && !this.#hasCatOnBoard && !this.#call.isSayingGoodbye) {
				const token = this.#call.token;
				this.#mormorDoes(token, async () => {
					// She could have drawn him in the meantime, after “Draw something!”.
					if (this.#hasCatOnBoard) {
						return;
					}

					await this.#speakLine(token, 'Oh, a drawing board! Wait, I will draw Pusen for you.');
					await this.#drawPotatoCat(token);
				});
			}
		});

		this.on(this.parts.chatForm, 'submit', event => {
			event.preventDefault();
			const text = this.parts.chatInput.value.trim();

			if (!text) {
				return;
			}

			if (this.#call.state !== 'connected') {
				this.say('Nobody is in the chat. Call Mormor first.');
				return;
			}

			this.parts.chatInput.value = '';
			this.#addChatLine('Sindre', text);
			const token = this.#call.token;

			// Once, the cat walks on her keyboard before she answers.
			if (!this.#hasCatWalkedOnKeyboard && !this.reducedMotion && Math.random() < 0.5) {
				this.#hasCatWalkedOnKeyboard = true;
				this.#mormorTypes(token, 'JJJJJJJJJJJJJJJJJJKKKKKKKK;;;;;;;;');
				this.#mormorTypes(token, 'SORRY THAT WAS PUSEN');
			}

			this.#mormorTypes(token, chatAnswer(text));
		});

		this.on(board, 'pointerdown', event => {
			board.setPointerCapture(event.pointerId);
			this.#pen.isDrawing = true;
			this.#pen.last = this.#boardPoint(event);
			this.#strokeOnBoard([this.#pen.last, [this.#pen.last[0] + 0.5, this.#pen.last[1] + 0.5]], this.#pen.color);
		});

		this.on(board, 'pointermove', event => {
			if (!this.#pen.isDrawing) {
				return;
			}

			const point = this.#boardPoint(event);
			this.#strokeOnBoard([this.#pen.last, point], this.#pen.color);
			this.#pen.last = point;
		});

		for (const type of ['pointerup', 'pointercancel']) {
			this.on(board, type, () => {
				if (this.#pen.isDrawing) {
					this.#pen.isDrawing = false;
					this.#scheduleGuess();
				}
			});
		}

		this.on(board, 'keydown', event => {
			const step = event.shiftKey ? 12 : 4;
			const moves = {ArrowLeft: [-step, 0], ArrowRight: [step, 0], ArrowUp: [0, -step], ArrowDown: [0, step]};

			if (event.key === ' ') {
				event.preventDefault();
				this.#pen.isDown = !this.#pen.isDown;
				this.#renderBoard();
				this.say(this.#pen.isDown ? 'The pen is down. The arrow keys draw.' : 'The pen is up. The arrow keys move it.');
				return;
			}

			const move = moves[event.key];

			if (!move) {
				return;
			}

			event.preventDefault();
			const from = [this.#pen.x, this.#pen.y];
			this.#pen.x = clamp(this.#pen.x + move[0], 0, 320);
			this.#pen.y = clamp(this.#pen.y + move[1], 0, 200);

			if (this.#pen.isDown) {
				this.#strokeOnBoard([from, [this.#pen.x, this.#pen.y]], this.#pen.color);
				this.#scheduleGuess();
			} else {
				this.#renderBoard();
			}
		});

		this.on(board, 'focus', () => {
			this.#pen.hasFocus = true;
			this.#renderBoard();
		});

		this.on(board, 'blur', () => {
			this.#pen.hasFocus = false;
			this.#renderBoard();
		});

		for (const button of this.#colorButtons) {
			if (button.getAttribute('aria-pressed') === 'true') {
				button.dataset.state = 'on';
			}

			this.on(button, 'click', () => {
				this.#pen.color = penColors[button.dataset.netmeetingColor];

				for (const other of this.#colorButtons) {
					other.setAttribute('aria-pressed', String(other === button));

					if (other === button) {
						other.dataset.state = 'on';
					} else {
						delete other.dataset.state;
					}
				}

				this.#renderBoard();
			});
		}

		this.on(this.parts.clearBoard, 'click', async () => {
			const answer = await this.ask({title: 'Whiteboard', icon: '❓', text: 'Are you sure you want to clear the contents of this page?', buttons: ['Yes', 'No'], opener: this.parts.clearBoard});

			if (answer !== 'Yes') {
				return;
			}

			this.#inkContext.clearRect(0, 0, 320, 200);
			this.#renderBoard();
			board.setAttribute('aria-label', 'Whiteboard. Draw with the mouse or a finger, or move the pen with the arrow keys. Space lifts the pen and puts it down.');

			if (this.#hasCatOnBoard) {
				this.#hasCatOnBoard = false;
				this.#queueLine(this.#call.token, 'Oh! Where did Pusen go? I worked so hard on his ears!');
			}
		});

		this.#renderBoard();

		this.on(this.parts.share, 'click', () => {
			if (this.#needsCall()) {
				return;
			}

			this.#setSharing(!this.#share.isOn);

			if (this.#share.isOn) {
				this.say('You share your desktop. Mormor can see it. Press Collaborate to let her click.');
				this.#queueLine(this.#call.token, 'Oh! I can see your computer! What is GLITTER.EXE?');
			} else {
				this.say('You stopped sharing.');
			}
		});

		this.on(this.parts.collaborate, 'click', () => {
			if (this.#needsCall()) {
				return;
			}

			if (!this.#share.isOn) {
				this.say('Share your desktop first, then Collaborate.');
				return;
			}

			if (this.#share.hasControl) {
				this.#takeControlBack();
			} else {
				inBackground(this.#mormorTakesControl(this.#call.token));
			}
		});

		this.on(shareScreen, 'pointerdown', event => {
			if (this.#share.hasControl) {
				this.#takeControlBack();
				return;
			}

			// The visitor can get the homework back out of the Recycle Bin.
			const rect = shareScreen.getBoundingClientRect();
			const x = (event.clientX - rect.left) / rect.width * 320;
			const y = (event.clientY - rect.top) / rect.height * 200;
			const bin = this.#shareIcons.bin;

			if (x >= bin.x && x <= bin.x + 44 && y >= bin.y && y <= bin.y + 40) {
				this.#restoreHomework();
			}
		});

		this.on(shareScreen, 'keydown', event => {
			if (this.#share.hasControl && ['Escape', 'Enter', ' '].includes(event.key)) {
				// Escape takes the control back, like in NetMeeting, instead of closing the window.
				event.preventDefault();
				event.stopPropagation();
				this.#takeControlBack();
			} else if (!this.#share.hasControl && ['Enter', ' '].includes(event.key)) {
				event.preventDefault();
				this.#restoreHomework();
			}
		});

		this.#renderShare();

		drawPhoto(this.#photoSource);

		this.on(this.parts.transferCancel, 'click', () => {
			this.#failTransfer('You cancelled it.');
			this.say('You cancelled the transfer.');
			this.#queueLine(this.#call.token, this.#transfer.direction === 'in' ? 'Oh, it stopped. Ask about Pusen again, and I will send him again.' : 'Oh, it stopped. Was it something nice? Send it again, dear.');
		});

		this.on(this.parts.sendFile, 'click', async () => {
			if (this.#needsCall()) {
				return;
			}

			const isOpen = this.#toolPanels.get('transfer').hidden;
			this.#setTool('transfer', isOpen);

			if (!isOpen || this.#transfer.isActive) {
				return;
			}

			const answer = await this.ask({title: 'Send File', icon: '📁', text: 'Send ROCKY.BMP to Mormor? It is a photo of Rocky, my pet rock. 58 KB.', buttons: ['Send', 'Cancel'], opener: this.parts.sendFile});

			if (answer === 'Send') {
				inBackground(this.#startTransfer(this.#call.token, 'out'));
			}
		});

		// The microphone and the speaker of the audio bar.
		this.on(this.parts.microphone, 'change', () => {
			this.say(this.parts.microphone.checked ? 'Your microphone is on.' : 'Your microphone is off. Mormor cannot hear you.');
		});

		this.on(this.parts.speaker, 'change', () => {
			if (!this.parts.speaker.checked) {
				this.#stopSpeaking();
			}

			this.say(this.parts.speaker.checked ? 'Your speaker is on.' : 'Your speaker is off. You only see Mormor’s lips move.');
		});

		this.#setScene('dark');

		this.#drawLocal();
	}

	// The directory logs on when NetMeeting opens the first time, and everything waits while it is closed, off the screen, or the tab is hidden.
	visibilityChanged(isVisible) {
		this.#updateCallTimers();

		// The real webcam turns off as soon as NetMeeting is out of sight, so its light does not stay on for nothing.
		if (!isVisible) {
			this.#stopSpeaking();

			if (this.#webcam.stream) {
				this.#stopWebcam();
				this.say('Your webcam turned off, as NetMeeting was out of sight. Press the camera button to turn it on again.');
			}

			return;
		}

		if (!this.#hasOpened) {
			this.#hasOpened = true;
			this.#logOn();
		}

		for (const resolve of this.#resumeWaiters.splice(0)) {
			resolve();
		}
	}

	reducedMotionChanged() {
		this.#updateCallTimers();
	}

	// The video runs at the frames of the quality, and the meters and the clock of the call run, only while the call is on the screen. With reduced motion, a new still frame comes only when something changes.
	#updateCallTimers() {
		const isRunning = this.#call.state === 'connected' && this.isVisible;
		this.#videoTimer?.cancel();

		this.#videoTimer = isRunning && !this.reducedMotion ? this.interval(1000 / this.#quality().fps, () => {
			this.#videoFrame();
		}) : undefined;

		if (isRunning && !this.#meterTimer) {
			this.#meterTimer = this.interval(120, () => {
				this.#updateMeters();
			});

			this.#clockTimer = this.interval(1000, () => {
				this.#tickClock();
			});
		} else if (!isRunning && this.#meterTimer) {
			this.#meterTimer.cancel();
			this.#clockTimer.cancel();
			this.#meterTimer = undefined;
			this.#clockTimer = undefined;
		}
	}

	// A view, a tool, or the call that hides gives the focus to the control that takes its place: the button of the view that shows, the button of the tool in the toolbar, or Call.
	focusReplacement(control) {
		if (control.closest('[data-netmeeting-panel]')?.hidden) {
			return this.#viewButtons.find(button => button.getAttribute('aria-pressed') === 'true');
		}

		const tool = control.closest('[data-netmeeting-tool]');

		if (tool && (tool.hidden || control.disabled)) {
			return this.#toolButtons.get(tool.dataset.netmeetingTool);
		}

		if (this.parts.callArea.hidden && this.parts.callArea.contains(control)) {
			return this.parts.call;
		}

		return super.focusReplacement(control);
	}

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

	async #during(token, milliseconds) {
		await this.#wait(milliseconds);

		if (token !== this.#call.token) {
			throw new Cancelled();
		}
	}

	// The message box of the desktop, which answers with the button that the visitor clicks.
	ask(options) {
		return super.ask({title: 'NetMeeting', icon: '📹', opener: this.desktopWindow.contains(document.activeElement) ? document.activeElement : this.parts.call, ...options});
	}

	// The sounds go through the volume of the tray, once the visitor turns them on.
	#isSoundOn() {
		return this.parts.sound.getAttribute('aria-pressed') === 'true' && this.isVisible && this.sound() !== undefined;
	}

	#tone(frequency, start, duration, {type = 'sine', volume = 0.08, slide} = {}) {
		if (!this.#isSoundOn()) {
			return;
		}

		const {context, output} = this.sound();
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
	}

	// A burst of noise, for the scream of the modem.
	#noise(start, duration, {volume = 0.1, frequency = 1000, q = 0.7} = {}) {
		if (!this.#isSoundOn()) {
			return;
		}

		const {context, output} = this.sound();
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
	}

	#stopSpeaking() {
		if (this.#utterances.size > 0) {
			this.#utterances.clear();
			speechSynthesis.cancel();
		}
	}

	#speak(text, who) {
		if (!this.#isSoundOn() || !this.parts.speaker.checked || !globalThis.speechSynthesis) {
			return;
		}

		const utterance = new SpeechSynthesisUtterance(text.replaceAll('…', ', '));
		const voice = voiceFor(who);

		if (voice) {
			utterance.voice = voice;
		}

		utterance.rate = who === 'mormor' ? 0.8 : 1.15;
		utterance.pitch = who === 'mormor' ? 0.8 : 1.2;

		for (const type of ['end', 'error']) {
			utterance.addEventListener(type, () => {
				this.#utterances.delete(utterance);
			});
		}

		this.#utterances.add(utterance);
		speechSynthesis.speak(utterance);
	}

	// The views of the bar on the left.
	#showView(name) {
		for (const [panelName, panel] of this.#panels) {
			panel.hidden = panelName !== name;
		}

		for (const button of this.#viewButtons) {
			const isOn = button.dataset.netmeetingView === name;
			button.setAttribute('aria-pressed', String(isOn));

			if (isOn) {
				button.dataset.state = 'on';
			} else {
				delete button.dataset.state;
			}
		}
	}

	#renderHistory() {
		this.parts.history.replaceChildren();

		if (this.#callHistory.length === 0) {
			const item = document.createElement('li');
			item.textContent = 'No calls yet. Mormor is waiting.';
			this.parts.history.append(item);
			return;
		}

		for (const entry of this.#callHistory) {
			const item = document.createElement('li');
			item.textContent = `${entry.time}  ${entry.who}: ${entry.result}`;
			this.parts.history.append(item);
		}
	}

	#addHistory(who, result) {
		this.#callHistory.unshift({time: new Date().toLocaleTimeString('en-GB', {hour: '2-digit', minute: '2-digit'}), who, result});
		this.#callHistory = this.#callHistory.slice(0, 12);
		this.store('history', this.#callHistory);
		this.#renderHistory();
	}

	#selectPerson(id) {
		this.#directory.selected = id;

		for (const row of this.parts.directoryRows.children) {
			if (row.dataset.person === id) {
				row.dataset.state = 'selected';
			} else {
				delete row.dataset.state;
			}
		}
	}

	#renderDirectory() {
		this.parts.directoryRows.replaceChildren();

		if (!this.#directory.isLoggedOn) {
			return;
		}

		for (const person of people) {
			const row = this.parts.rowTemplate.content.firstElementChild.cloneNode(true);
			const cells = row.children;
			row.dataset.person = person.id;
			cells[0].textContent = person.media;
			cells[1].firstElementChild.textContent = person.name;
			cells[2].textContent = person.email;
			cells[3].textContent = person.city;
			cells[4].textContent = person.comment;

			cells[1].firstElementChild.addEventListener('click', () => {
				this.#selectPerson(person.id);
				this.say(`${person.name} is picked. Press 📞 Call to call.`);
			});

			row.addEventListener('dblclick', () => {
				this.#selectPerson(person.id);
				this.#callPerson(person.id);
			});

			this.parts.directoryRows.append(row);
		}

		this.#selectPerson(this.#directory.selected);
	}

	async #logOn() {
		const run = ++this.#logOnRun;
		const server = this.parts.server.value;
		this.#directory.isLoggedOn = false;
		this.#renderDirectory();
		this.say(`Logging on to ${server}…`);
		await this.#wait(1000);

		if (run !== this.#logOnRun) {
			return;
		}

		if (server === 'ils.microsoft.com' && this.#directory.attempts > 0) {
			this.#directory.isLoggedOn = true;
			this.#renderDirectory();
			this.say(`Logged on to ${server}. ${people.length} people are listed. Press 📞 Call to call Mormor!`);
			return;
		}

		this.#directory.attempts++;
		const text = server === 'ils.microsoft.com' ? `Could not log on to ${server}. The server is busy. Everybody with Windows 98 is trying to log on tonight.` : `Could not log on to ${server}. The server is busy, or it does not answer. Try ils.microsoft.com.`;
		const answer = await this.ask({icon: '⚠️', text, buttons: ['Retry', 'Cancel'], opener: this.parts.refresh});

		if (run !== this.#logOnRun) {
			return;
		}

		if (answer === 'Retry') {
			this.#logOn();
		} else {
			this.say('Not logged on to the directory. Press 📞 Call to call Mormor anyway, or Refresh to try again.');
		}
	}

	async #callStranger(id) {
		if (this.#directory.isDialingStranger) {
			return;
		}

		if (this.#call.state !== 'idle') {
			this.say('You are already in a call. NetMeeting sends video to one person at a time, and that is Mormor.');
			return;
		}

		this.#directory.isDialingStranger = true;
		const person = people.find(candidate => candidate.id === id);
		this.#sounds.ring();
		this.say(`Calling ${person.name}…`);
		await this.#wait(id === 'me' ? 300 : 2500);
		await this.ask({icon: id === 'me' ? '🤔' : '📞', text: strangerAnswers[id], opener: this.parts.call});
		this.#directory.isDialingStranger = false;

		if (id !== 'me') {
			this.#addHistory(person.name, id === 'raven' || id === 'test' ? 'Did not accept the call' : (id === 'zorg' ? 'In another call' : 'Hung up on you'));
		}

		this.say('Mormor is the one in Ålesund, at the top of the list.');
	}

	// Faster video has more frames in bigger blocks, and better quality fewer frames in smaller blocks, like the slider of NetMeeting.
	#quality() {
		return qualities[this.parts.quality.value] ?? qualities[2];
	}

	#pixelate(source, target) {
		const {block} = this.#quality();
		this.#smallCanvas.width = 160 / block;
		this.#smallCanvas.height = 120 / block;
		this.#small.imageSmoothingEnabled = true;
		this.#small.drawImage(source, 0, 0, this.#smallCanvas.width, this.#smallCanvas.height);
		target.imageSmoothingEnabled = false;
		target.drawImage(this.#smallCanvas, 0, 0, this.#smallCanvas.width, this.#smallCanvas.height, 0, 0, 160, 120);
	}

	#lookOf() {
		const isMoving = !this.reducedMotion;
		const isTalking = isMoving && performance.now() < this.#call.mouthUntil;

		if (this.#call.isAwkward) {
			return {eyes: 'half', mouth: 'wide', tilt: 0.14, bobX: 3, bobY: 2};
		}

		return {
			eyes: isMoving && Math.random() < 0.08 ? 'closed' : 'open',
			mouth: isTalking ? randomItem(['open', 'o', 'smile', 'wide']) : 'smile',
			tilt: isMoving ? (Math.random() - 0.5) * 0.06 : 0,
			bobX: isMoving ? randomInteger(-2, 2) : 0,
			bobY: isMoving ? randomInteger(-1, 1) : 0,
		};
	}

	// The words of NetMeeting itself on the video window are sharp, not in blocks like the video.
	#drawNotice(text, background, color) {
		this.#remoteContext.fillStyle = background;
		this.#remoteContext.fillRect(0, 0, 160, 120);
		this.#remoteContext.fillStyle = color;
		this.#remoteContext.font = 'bold 13px sans-serif';
		this.#remoteContext.textAlign = 'center';
		this.#remoteContext.fillText(text, 80, 64);
	}

	#drawRemote() {
		if (this.#call.isFrozen) {
			return;
		}

		this.#call.frame++;

		if (this.#call.scene === 'calling') {
			this.#drawNotice('📞 Calling…', '#000040', '#ffffff');
			return;
		}

		if (this.#call.isVideoPaused && this.#call.state === 'connected') {
			this.#drawNotice('❚❚ Video paused', '#000000', '#c0c0c0');
			return;
		}

		const current = scenes[this.#call.scene] ?? scenes.dark;
		current.draw(this.#scene, this.#lookOf(), this.#call.frame);
		this.#pixelate(this.#sceneCanvas, this.#remoteContext);

		// A block or two slides, like the video of a modem when a frame comes late.
		if (!this.reducedMotion && this.#call.scene !== 'dark' && Math.random() < 0.35) {
			const {block} = this.#quality();
			const blockX = randomInteger(0, (160 / block) - 3) * block;
			const blockY = randomInteger(0, (120 / block) - 3) * block;
			this.#remoteContext.drawImage(this.parts.remoteVideo, blockX, blockY, block * 3, block * 2, blockX + block, blockY, block * 3, block * 2);
		}
	}

	#setScene(name) {
		this.#call.scene = name;
		this.parts.remoteVideo.setAttribute('aria-label', `Mormor’s video: ${scenes[name].label}.`);
		this.#drawRemote();
	}

	#drawLocal() {
		if (this.#webcam.video && this.#webcam.video.readyState >= 2) {
			this.#webcamContext.drawImage(this.#webcam.video, 0, 0, 160, 120);
			this.#pixelate(this.#webcamCanvas, this.#localContext);
			return;
		}

		drawSindre(this.#scene, !this.reducedMotion && performance.now() < this.#call.yourMouthUntil);
		this.#pixelate(this.#sceneCanvas, this.#localContext);
	}

	#stopWebcam() {
		stopTracks(this.#webcam.stream);
		this.#webcam.stream = undefined;
		this.#webcam.video = undefined;
		this.parts.webcam.setAttribute('aria-pressed', 'false');
		this.parts.webcam.setAttribute('aria-label', 'Use my real webcam');
		this.parts.localVideo.setAttribute('aria-label', 'My video: a drawing of Sindre');
		this.#drawLocal();
	}

	#videoFrame() {
		this.#drawRemote();
		this.#drawLocal();
	}

	#setVideoPaused(isVideoPaused) {
		this.#call.isVideoPaused = isVideoPaused;
		this.parts.remotePause.setAttribute('aria-pressed', String(isVideoPaused));
		this.parts.remotePause.textContent = isVideoPaused ? '▶' : '❚❚';
		this.parts.remotePause.setAttribute('aria-label', isVideoPaused ? 'Play Mormor’s video' : 'Pause Mormor’s video');
	}

	// The level meters of the microphone and the speaker jump while somebody talks.
	#updateMeters() {
		const now = performance.now();
		const isMicrophoneOn = this.#call.state === 'connected' && this.parts.microphone.checked && now < this.#call.yourMouthUntil;
		const isSpeakerOn = this.#call.state === 'connected' && this.parts.speaker.checked && now < this.#call.heardUntil;
		const level = isOn => (isOn ? (this.reducedMotion ? 70 : randomInteger(30, 100)) : 0);
		this.parts.microphoneLevel.style.width = `${level(isMicrophoneOn)}%`;
		this.parts.speakerLevel.style.width = `${level(isSpeakerOn)}%`;
	}

	#showSubtitle(element, text, duration) {
		element.textContent = text;
		clearTimeout(this.#subtitleTimers.get(element));
		this.#subtitleTimers.set(element, setTimeout(() => {
			element.textContent = '';
		}, duration + 2500));
	}

	// Mormor says a line. Her lips move at once, and her sound comes over the modem after the delay.
	async #speakLine(token, text, {scene: sceneName, who = 'mormor'} = {}) {
		const duration = clamp(text.length * 65, 1500, 7000);

		if (sceneName) {
			this.#setScene(sceneName);
		}

		this.#call.mouthUntil = performance.now() + duration;
		this.#call.speakingUntil = this.#call.mouthUntil;
		await this.#during(token, this.#call.delay);
		const name = who === 'mormor' ? 'Mormor' : 'Mamma';
		this.#showSubtitle(this.parts.subtitleMormor, this.parts.speaker.checked ? `${name}: ${text}` : `${name}: 🔇 (your speaker is off)`, duration);
		this.#speak(text, who);
		this.#call.heardUntil = performance.now() + duration;
		await this.#during(token, duration);
	}

	#mormorDoes(token, sequence) {
		this.#mormorPending++;
		const run = this.#mormorChain.then(async () => {
			if (token === this.#call.token) {
				await sequence();
			}
		}).finally(() => {
			this.#mormorPending--;
		});
		this.#mormorChain = run.catch(() => {});
		inBackground(run);
		return run;
	}

	// A remark that is only funny right away, like about what she clicks, is left out while she is still busy with something else, so her words do not fall behind.
	#queueLine(token, text, {scene: sceneName, isRemark = false} = {}) {
		if (this.#call.state !== 'connected' || (isRemark && this.#mormorPending > 0)) {
			return;
		}

		this.#mormorDoes(token, () => this.#speakLine(token, text, {scene: sceneName}));
	}

	#sayToMormor(lineId) {
		if (this.#call.state !== 'connected') {
			this.say('You are not in a call. Press 📞 Call to call Mormor first.');
			return;
		}

		const text = yourLines[lineId];
		const now = performance.now();
		const duration = clamp(text.length * 60, 1200, 4000);
		const isOverHer = now < this.#call.heardUntil;
		this.#call.yourMouthUntil = now + duration;
		this.#showSubtitle(this.parts.subtitleYou, `You: ${text}`, duration);
		this.#drawLocal();

		if (!this.parts.microphone.checked) {
			this.say('Your microphone is off, so Mormor only sees your mouth move.');

			if (now - this.#call.lastMuted > 15_000) {
				this.#call.lastMuted = now;
				this.#queueLine(this.#call.token, 'Sindre? Your mouth moves, but there is no sound! Did Pusen chew the wire?');
			}

			return;
		}

		if (isOverHer) {
			this.say(`You talk over Mormor. Her sound comes ${(this.#call.delay / 1000).toFixed(1)} seconds late, so this happens a lot.`);
		}

		// While Mormor looks for Hang Up, she does not listen anymore.
		if (this.#call.isSayingGoodbye) {
			return;
		}

		const token = this.#call.token;

		inBackground((async () => {
			// My sound arrives at Mormor after the same delay. If she talks then, we talk over each other, and nobody hears anything.
			await this.#during(token, this.#call.delay);

			if (isOverHer || performance.now() < this.#call.speakingUntil) {
				const line = collisionLines[Math.min(this.#call.collisions, collisionLines.length - 1)];
				this.#call.collisions++;
				this.say('You both talked at the same time. Wait until her sound stops.');
				this.#queueLine(token, line, {isRemark: true});
				return;
			}

			this.#call.collisions = 0;
			this.#mormorDoes(token, () => this.#answers[lineId](token));
		})());
	}

	// The picture freezes at the worst moment, while her sound goes on.
	async #freezeVideo(token) {
		this.#call.isAwkward = true;
		this.#drawRemote();
		this.#call.isAwkward = false;
		this.#call.isFrozen = true;
		this.parts.remoteLabel.textContent = 'Mormor (frozen)';
		this.say('Mormor’s picture froze. The modem has too much to do.');
		await this.#speakLine(token, 'And then I said to the man in the shop… Sindre? Are you there? I am waving! Can you see me waving?');
		await this.#during(token, 2500);
		this.#call.isFrozen = false;
		this.parts.remoteLabel.textContent = 'Mormor';
		this.#drawRemote();
	}

	async #runSpontaneous(token) {
		this.#call.events++;

		if (this.#call.events === 1) {
			await this.#freezeVideo(token);
			return;
		}

		if (this.#toolPanels.get('chat').hidden === false && Math.random() < 0.35) {
			await this.#mormorTypes(token, randomItem(['CAN YOU READ THIS', 'I AM TYPING!!!!', 'WHERE IS THE SMALL LETTERS']));
			return;
		}

		const event = randomItem(this.reducedMotion ? spontaneous.filter(item => !item.scene) : spontaneous);

		if (event.meow) {
			this.#sounds.meow();
		}

		await this.#speakLine(token, event.text, {scene: event.scene});

		if (event.pause) {
			await this.#during(token, event.pause);
			await this.#speakLine(token, event.back, {scene: 'normal'});
		} else if (event.after) {
			await this.#during(token, 1500);
			this.#setScene(event.after);
		}
	}

	async #director(token) {
		await this.#during(token, 14_000);

		while (this.#call.state === 'connected') {
			if (this.#mormorPending === 0 && !this.#call.isSayingGoodbye && !this.#share.hasControl) {
				await this.#mormorDoes(token, () => this.#runSpontaneous(token));
			}

			await this.#during(token, randomInteger(14_000, 22_000));
		}
	}

	#showCallArea(isShown) {
		this.parts.callArea.hidden = !isShown;
		this.parts.notInCall.hidden = isShown;
	}

	#placeCall() {
		if (this.#call.state !== 'idle') {
			this.say(this.#call.state === 'connected' ? 'You are already in a call with Mormor.' : 'Wait, the phone is already ringing.');
			return;
		}

		const token = ++this.#call.token;
		this.#call.state = 'ringing';
		this.#showView('call');
		this.#showCallArea(true);
		this.#setScene('calling');
		this.#drawLocal();
		this.parts.callInfo.textContent = 'Calling Mormor…';
		this.say('Calling Mormor at mormor.alesund@online.no…');

		inBackground((async () => {
			for (let ring = 0; ring < 2; ring++) {
				this.#sounds.ring();
				await this.#during(token, 2200);
			}

			if (this.#hasMormorAnswered) {
				this.#connect('outgoing');
				return;
			}

			// The first call of a visit, Mormor presses Ignore, as she thinks that it is a virus. Then she calls back.
			this.#hasMormorAnswered = true;
			this.#call.token++;
			this.#call.state = 'idle';
			this.#showCallArea(false);
			this.parts.notInCall.textContent = 'Mormor did not accept your call.';
			this.parts.callInfo.textContent = 'Not in a call';
			this.#addHistory('Mormor', 'Did not accept the call');
			await this.ask({icon: '📞', text: 'Mormor did not accept your call.', opener: this.parts.call});
			await this.#wait(1500);
			this.#incoming('ignored');
		})());
	}

	#callPerson(id) {
		if (id === 'mormor') {
			this.#placeCall();
		} else {
			this.#callStranger(id);
		}
	}

	async #incoming(reason, attempt = 1) {
		if (this.#call.state !== 'idle') {
			return;
		}

		const token = ++this.#call.token;
		this.#call.state = 'incoming';
		this.#sounds.ring();
		this.parts.callInfo.textContent = 'Mormor is calling…';

		// It rings until the visitor answers, and waits like everything else while NetMeeting is out of sight.
		inBackground((async () => {
			while (true) {
				await this.#during(token, 2500);

				if (this.#call.state !== 'incoming') {
					return;
				}

				this.#sounds.ring();
			}
		})());

		const answer = await this.ask({icon: '📞', text: incomingTexts[attempt - 1], buttons: ['Accept', 'Ignore']});

		if (token !== this.#call.token) {
			return;
		}

		if (answer === 'Accept') {
			this.#connect(reason);
			return;
		}

		this.#call.state = 'idle';
		this.parts.callInfo.textContent = 'Not in a call';
		this.#addHistory('Mormor', 'You ignored her call');

		if (attempt < 3) {
			this.say('You ignored Mormor. She will try again.');
			await this.#wait(7000);
			this.#incoming(reason, attempt + 1);
		} else {
			this.say('Mormor gave up, and called Mamma on the real telephone instead.');
			this.toast('Mormor called Mamma on the real telephone. Mamma says: be nice to Mormor.');
		}
	}

	#connect(reason) {
		const token = ++this.#call.token;
		Object.assign(this.#call, {
			state: 'connected',
			seconds: 0,
			delay: randomInteger(1800, 3000),
			isFrozen: false,
			isAwkward: false,
			isSayingGoodbye: false,
			mouthUntil: 0,
			speakingUntil: 0,
			heardUntil: 0,
			collisions: 0,
			cameraStep: 0,
			loveCount: 0,
			events: 0,
			hasOpenedChat: false,
		});
		this.#setVideoPaused(false);
		this.parts.remoteLabel.textContent = 'Mormor';
		this.parts.delay.textContent = `Delay ${(this.#call.delay / 1000).toFixed(1)} s`;
		this.#sounds.connect();
		this.#showView('call');
		this.#showCallArea(true);
		this.parts.callInfo.textContent = `In a call with Mormor ${clock(0)}`;
		this.say('Mormor accepted the call! Her sound comes late over the modem, so wait for it.');
		this.#setScene(reason === 'mamma' || reason === 'hungup' ? 'normal' : 'close');
		this.#drawLocal();
		this.#updateCallTimers();

		this.#mormorDoes(token, async () => {
			await this.#speakLine(token, openingLines[reason]);

			if (this.#call.scene === 'close') {
				await this.#speakLine(token, 'Can you see me? I will sit back a little.', {scene: 'forehead'});
				await this.#speakLine(token, 'And I will move the little camera. There.', {scene: 'ceiling'});
				this.say('Mormor’s camera points at the ceiling. Press “Move the camera down”.');
			}
		});

		inBackground(this.#director(token));
	}

	#endCall(reason) {
		if (this.#call.state !== 'connected') {
			return;
		}

		this.#call.token++;
		this.#call.state = 'idle';
		this.#updateCallTimers();
		this.#addHistory('Mormor', `${endTexts[reason].history}, after ${formatDuration(this.#call.seconds)}`);
		this.#sounds.hangUp();
		this.#stopSpeaking();
		this.#stopWebcam();
		this.#failTransfer('The call ended.');
		this.#setSharing(false);

		for (const name of this.#toolPanels.keys()) {
			this.#setTool(name, false);
		}

		this.#call.isFrozen = false;
		this.#setScene('dark');
		this.parts.subtitleMormor.textContent = '';
		this.parts.subtitleYou.textContent = '';
		this.#showCallArea(false);
		this.parts.notInCall.textContent = `${endTexts[reason].text} Press 📞 Call to call her again.`;
		this.parts.callInfo.textContent = 'Not in a call';
		this.parts.delay.textContent = 'Delay –';
		this.#updateMeters();
	}

	// Ha det: Mormor cannot find Hang Up. She tries everything, and then pulls the plug.
	async #sayGoodbye(token) {
		if (this.#call.isSayingGoodbye) {
			return;
		}

		this.#call.isSayingGoodbye = true;
		await this.#speakLine(token, 'Ha det, vennen min! Bye bye! … Now. How do I turn this off?', {scene: 'search'});
		await this.#speakLine(token, 'Is it this button?');
		this.#setTool('whiteboard', true);
		this.#strokeOnBoard([[40, 160], [70, 150], [90, 170], [60, 180]], '#8b5a2b');
		this.say('Mormor opened the Whiteboard. That is not Hang Up.');
		await this.#speakLine(token, 'No. That is a drawing board. This one, then?');
		this.#setScene('dark');
		this.say('Mormor turned off her camera. That is not Hang Up either.');
		await this.#speakLine(token, 'Oh! Now you are gone! No, wait.');
		this.#setScene('search');
		this.#setTool('chat', true);
		await this.#mormorTypes(token, 'HOW DO I HANG UP');
		await this.#speakLine(token, 'There is no red button. Your grandfather would have known.', {scene: 'close'});
		await this.#speakLine(token, 'I will pull the plug. Ha det, Sindre! Kos deg!');
		await this.#during(token, 1200);
		this.#setScene('static');
		await this.#during(token, 800);
		this.#endCall('plug');
		this.say('Mormor left the call. She pulled out the plug. That is one way to hang up.');
	}

	// Mamma picks up the phone in the kitchen, so the modem screams and the line drops.
	async #mammaPicksUp() {
		if (this.#call.state !== 'connected' || this.#hasMammaPickedUp) {
			return;
		}

		this.#hasMammaPickedUp = true;
		const token = this.#call.token;
		this.#sounds.modemScream();
		this.#call.isFrozen = false;
		this.#setScene('static');
		this.#call.isFrozen = true;
		const text = 'Hallo? HALLO? Sindre, are you on the Internet again? I need the phone. I am calling Mormor!';
		this.#showSubtitle(this.parts.subtitleMormor, `Mamma: ${text}`, 5000);
		this.#speak(text, 'mamma');
		this.say('Mamma picked up the phone in the kitchen. The modem screams.');

		await this.#during(token, 4500);
		this.#endCall('mamma');
		const answer = await this.ask({title: 'Dial-Up Networking', icon: '📞', text: 'The connection to the Internet was lost. Somebody picked up the phone.', buttons: ['Reconnect', 'Cancel'], opener: this.parts.call});

		if (answer !== 'Reconnect') {
			this.say('You are offline. Mamma is on the phone with Mormor, about you.');
			return;
		}

		this.#sounds.dial();
		this.say('Mamma: “OK, ten more minutes. Then I need the phone.” Dialing again…');
		await this.#wait(4000);
		this.#incoming('mamma');
	}

	// The clock of the call. Mamma picks up the phone after some minutes, if a file did not make her do it first.
	#tickClock() {
		this.#call.seconds++;
		this.parts.callInfo.textContent = `In a call with Mormor ${clock(this.#call.seconds)}`;

		if (this.#call.seconds >= 160 && !this.#hasMammaPickedUp && !this.#call.isSayingGoodbye && !this.#transfer.isActive) {
			inBackground(this.#mammaPicksUp());
		}
	}

	// The windows of the tools of the call, which the toolbar opens and closes.
	#setTool(name, isOpen) {
		const panel = this.#toolPanels.get(name);
		const wasHidden = panel.hidden;
		const button = this.#toolButtons.get(name);

		panel.hidden = !isOpen;

		// The tools open below the call, so the window scrolls to show a tool that opens. Only the window scrolls, as scrolling the desktop around it would hide the window.
		if (isOpen && wasHidden) {
			const appWindow = this.desktopWindow;
			const panelBottom = panel.getBoundingClientRect().bottom - appWindow.getBoundingClientRect().top + appWindow.scrollTop;

			if (panelBottom > appWindow.scrollTop + appWindow.clientHeight) {
				appWindow.scrollTo({top: panelBottom - appWindow.clientHeight + 8, behavior: this.reducedMotion ? 'auto' : 'smooth'});
			}
		}

		button.setAttribute('aria-pressed', String(isOpen));

		if (isOpen) {
			button.dataset.state = 'on';
		} else {
			delete button.dataset.state;
		}

		if (name === 'whiteboard' && isOpen) {
			this.#renderBoard();
		}
	}

	#needsCall() {
		if (this.#call.state === 'connected') {
			return false;
		}

		this.say('You are not in a call. Press 📞 Call to call Mormor first.');
		return true;
	}

	#addChatLine(name, text) {
		const line = document.createElement('p');
		const author = document.createElement('strong');
		author.textContent = `${name}: `;
		const words = document.createElement('span');
		words.textContent = text;
		line.append(author, words);
		this.parts.chatLog.append(line);
		this.parts.chatLog.scrollTop = this.parts.chatLog.scrollHeight;
		return line;
	}

	// Her one finger, letter by letter, with a typo now and then that she sees and fixes.
	async #typeLetters(token, text, words) {
		let typed = '';

		if (this.reducedMotion) {
			words.textContent = '✍️ …';
			await this.#during(token, text.length * 250);
		} else {
			for (const character of text) {
				if (/[A-Z]/.test(character) && Math.random() < 0.08) {
					typed += neighborOf(character);
					words.textContent = `${typed}▌`;
					await this.#during(token, randomInteger(500, 900));
					typed = typed.slice(0, -1);
					words.textContent = `${typed}▌`;
					await this.#during(token, 400);
				}

				typed += character;
				words.textContent = `${typed}▌`;
				this.parts.chatLog.scrollTop = this.parts.chatLog.scrollHeight;
				await this.#during(token, character === ' ' ? randomInteger(500, 1000) : randomInteger(160, 480));
			}
		}
	}

	async #typeMessage(token, text) {
		await this.#during(token, 1500);

		// While she types, the line is hidden from screen readers, so they read the whole message once, not every letter. A call that ends takes away what she did not finish.
		const typing = this.#addChatLine('Mormor', '');
		typing.setAttribute('aria-hidden', 'true');
		const words = typing.lastElementChild;

		try {
			await this.#typeLetters(token, text, words);
		} finally {
			typing.remove();
		}

		this.#addChatLine('Mormor', text);
		this.#sounds.blip();
	}

	#mormorTypes(token, text) {
		const run = this.#chatChain.then(() => this.#typeMessage(token, text));
		this.#chatChain = run.catch(() => {});
		inBackground(run);
		return run;
	}

	#renderBoard() {
		this.#boardContext.fillStyle = '#ffffff';
		this.#boardContext.fillRect(0, 0, 320, 200);
		this.#boardContext.drawImage(this.#ink, 0, 0);

		// The remote pointer of NetMeeting shows where the other person draws.
		if (this.#mormorPen.isShown) {
			this.#boardContext.font = '16px sans-serif';
			this.#boardContext.textAlign = 'left';
			this.#boardContext.fillText('✏️', this.#mormorPen.x - 2, this.#mormorPen.y - 2);
			this.#boardContext.fillStyle = '#ffff99';
			this.#boardContext.fillRect(this.#mormorPen.x + 14, this.#mormorPen.y - 22, 38, 12);
			this.#boardContext.strokeStyle = '#000000';
			this.#boardContext.lineWidth = 1;
			this.#boardContext.strokeRect(this.#mormorPen.x + 14, this.#mormorPen.y - 22, 38, 12);
			this.#boardContext.fillStyle = '#000000';
			this.#boardContext.font = 'bold 9px sans-serif';
			this.#boardContext.fillText('Mormor', this.#mormorPen.x + 16, this.#mormorPen.y - 13);
		}

		if (this.#pen.hasFocus) {
			this.#boardContext.strokeStyle = this.#pen.isDown ? this.#pen.color : '#808080';
			this.#boardContext.lineWidth = 1;
			this.#boardContext.beginPath();
			this.#boardContext.moveTo(this.#pen.x - 6, this.#pen.y);
			this.#boardContext.lineTo(this.#pen.x + 6, this.#pen.y);
			this.#boardContext.moveTo(this.#pen.x, this.#pen.y - 6);
			this.#boardContext.lineTo(this.#pen.x, this.#pen.y + 6);
			this.#boardContext.stroke();
		}
	}

	#strokeOnBoard(points, color) {
		this.#inkContext.strokeStyle = color;
		this.#inkContext.lineWidth = 3;
		this.#inkContext.beginPath();
		this.#inkContext.moveTo(...points[0]);

		for (const point of points.slice(1)) {
			this.#inkContext.lineTo(...point);
		}

		this.#inkContext.stroke();
		this.#renderBoard();
	}

	async #drawPotatoCat(token) {
		const color = '#8b5a2b';
		this.#mormorPen.isShown = true;

		try {
			for (const stroke of potatoCatStrokes()) {
				if (this.reducedMotion) {
					this.#strokeOnBoard(stroke, color);
					continue;
				}

				for (let index = 1; index < stroke.length; index++) {
					[this.#mormorPen.x, this.#mormorPen.y] = stroke[index];
					this.#strokeOnBoard([stroke[index - 1], stroke[index]], color);
					await this.#during(token, 45);
				}

				await this.#during(token, 250);
			}

			this.#inkContext.fillStyle = color;
			this.#inkContext.font = 'bold 18px "Comic Sans MS", "Comic Sans", cursive';
			this.#inkContext.textAlign = 'left';
			this.#inkContext.fillText('PUSEN', 196, 186);
			[this.#mormorPen.x, this.#mormorPen.y] = [250, 180];
			this.#renderBoard();
		} finally {
			this.#mormorPen.isShown = false;
			this.#renderBoard();
		}

		this.#hasCatOnBoard = true;
		this.parts.board.setAttribute('aria-label', 'Whiteboard, with Mormor’s drawing of Pusen, which looks like a potato with ears. Draw with the mouse or a finger, or move the pen with the arrow keys. Space lifts the pen and puts it down.');
		this.say('Mormor drew Pusen. It looks a lot like a potato.');
		await this.#speakLine(token, 'Do you see? It is Pusen! He is a little round. It is the winter.');
	}

	// After the visitor draws, Mormor guesses what it is, and is wrong.
	#scheduleGuess() {
		clearTimeout(this.#guessTimer);
		this.#guessTimer = setTimeout(() => {
			const now = performance.now();

			if (this.#call.state !== 'connected' || this.#mormorPending > 0 || now - this.#call.lastGuess < 12_000) {
				return;
			}

			this.#call.lastGuess = now;
			this.#queueLine(this.#call.token, randomItem(guesses), {isRemark: true});
		}, 2500);
	}

	#boardPoint(event) {
		const rect = this.parts.board.getBoundingClientRect();
		return [
			clamp((event.clientX - rect.left - this.parts.board.clientLeft) / this.parts.board.clientWidth * 320, 0, 320),
			clamp((event.clientY - rect.top - this.parts.board.clientTop) / this.parts.board.clientHeight * 200, 0, 200),
		];
	}

	#resetShare() {
		Object.assign(this.#share, {windows: [], wallpaper: 'teal', isHomeworkInBin: false, hasUnicorn: false, hasShutDownDialog: false, dragging: undefined, cursor: {x: 200, y: 120}});
		this.#shareIcons.homework.x = 8;
		this.#shareIcons.homework.y = 112;
	}

	#renderShare() {
		const context = this.#shareContext;

		if (this.#share.wallpaper === 'bricks') {
			context.fillStyle = '#9a3a2a';
			context.fillRect(0, 0, 320, 200);
			context.strokeStyle = '#d8c8b0';
			context.lineWidth = 1;
			context.beginPath();

			for (let y = 0; y < 200; y += 10) {
				context.moveTo(0, y + 0.5);
				context.lineTo(320, y + 0.5);

				for (let x = (y / 10) % 2 === 0 ? 0 : 10; x < 320; x += 20) {
					context.moveTo(x + 0.5, y);
					context.lineTo(x + 0.5, y + 10);
				}
			}

			context.stroke();
		} else {
			context.fillStyle = '#008080';
			context.fillRect(0, 0, 320, 200);
		}

		context.textAlign = 'center';

		for (const [id, icon] of Object.entries(this.#shareIcons)) {
			if (id === 'homework' && this.#share.isHomeworkInBin && this.#share.dragging !== 'homework') {
				continue;
			}

			context.font = '20px sans-serif';
			context.fillText(id === 'bin' && this.#share.isHomeworkInBin ? '🗑️' : icon.icon, icon.x + 22, icon.y + 24);
			context.font = '8px sans-serif';
			context.fillStyle = '#000000';
			context.fillText(icon.label, icon.x + 23, icon.y + 37);
			context.fillStyle = '#ffffff';
			context.fillText(icon.label, icon.x + 22, icon.y + 36);
		}

		if (this.#share.isHomeworkInBin) {
			context.font = '9px sans-serif';
			context.fillText('📄', this.#shareIcons.bin.x + 34, this.#shareIcons.bin.y + 12);
		}

		if (this.#share.hasUnicorn) {
			context.font = '44px sans-serif';
			context.fillText('🦄', 250, 150);
		}

		for (const shareWindow of this.#share.windows) {
			drawShareWindow(context, shareWindow);
		}

		if (this.#share.hasShutDownDialog) {
			drawShareWindow(context, {title: 'Shut Down Windows', x: 90, y: 60, width: 150, height: 64, lines: ['Are you sure you want to', 'shut down the computer?', '        [ Yes ]    [ No ]']});
		}

		// The taskbar, with Start.
		context.fillStyle = '#c0c0c0';
		context.fillRect(0, 184, 320, 16);
		context.fillStyle = '#ffffff';
		context.fillRect(0, 184, 320, 1);
		context.strokeStyle = '#000000';
		context.strokeRect(2.5, 186.5, 36, 11);
		context.fillStyle = '#000000';
		context.font = 'bold 8px sans-serif';
		context.textAlign = 'left';
		context.fillText('🪟 Start', 5, 195);

		if (this.#share.hasControl) {
			const {x, y} = this.#share.cursor;
			context.fillStyle = '#ffffff';
			context.strokeStyle = '#000000';
			context.lineWidth = 1;
			context.beginPath();
			context.moveTo(x, y);
			context.lineTo(x, y + 14);
			context.lineTo(x + 4, y + 10);
			context.lineTo(x + 7, y + 16);
			context.lineTo(x + 9, y + 15);
			context.lineTo(x + 6, y + 9);
			context.lineTo(x + 11, y + 9);
			context.closePath();
			context.fill();
			context.stroke();
			context.fillStyle = '#ffff99';
			context.fillRect(x + 10, y + 14, 38, 12);
			context.strokeRect(x + 10.5, y + 14.5, 38, 12);
			context.fillStyle = '#000000';
			context.font = 'bold 9px sans-serif';
			context.fillText('Mormor', x + 13, y + 23);
		}
	}

	#setSharing(isOn) {
		if (!isOn && this.#share.hasControl) {
			this.#takeControlBack(false);
		}

		this.#share.isOn = isOn;
		this.#resetShare();
		this.#setTool('share', isOn);
		this.#renderShare();
	}

	// A wait of Mormor’s turn with the mouse, which stops when the visitor takes the control back.
	async #controlWait(token, run, milliseconds) {
		await this.#during(token, milliseconds);

		if (run !== this.#share.run || !this.#share.hasControl) {
			throw new Cancelled();
		}
	}

	async #glide(token, run, x, y) {
		const steps = this.reducedMotion ? 1 : 16;
		const from = {...this.#share.cursor};

		for (let step = 1; step <= steps; step++) {
			this.#share.cursor = {x: from.x + ((x - from.x) * step / steps), y: from.y + ((y - from.y) * step / steps)};

			if (this.#share.dragging) {
				this.#shareIcons[this.#share.dragging].x = this.#share.cursor.x - 22;
				this.#shareIcons[this.#share.dragging].y = this.#share.cursor.y - 20;
			}

			this.#renderShare();
			await this.#controlWait(token, run, 40);
		}
	}

	// Collaborate is pressed in while Mormor has the control of the mouse.
	#setControl(hasControl) {
		this.#share.hasControl = hasControl;
		this.parts.collaborate.setAttribute('aria-pressed', String(hasControl));

		if (hasControl) {
			this.parts.collaborate.dataset.state = 'on';
		} else {
			delete this.parts.collaborate.dataset.state;
		}

		this.#renderShare();
	}

	async #mormorTakesControl(token) {
		const run = ++this.#share.run;
		this.#setControl(true);
		this.parts.shareScreen.focus({preventScroll: true});
		this.say('Mormor has the control of your desktop! Press Escape or click it to take it back.');
		this.#queueLine(token, 'Ooh! I can move your little arrow!');
		const tell = (status, line) => {
			this.say(status);
			this.#queueLine(token, line, {isRemark: true});
		};

		try {
			await this.#controlWait(token, run, 1500);
			await this.#glide(token, run, this.#shareIcons.computer.x + 22, this.#shareIcons.computer.y + 18);
			await this.#controlWait(token, run, 500);
			this.#share.windows.push({title: 'My Computer', x: 120, y: 12, width: 140, height: 62, lines: ['💾 3½ Floppy (A:)', '💽 (C:)', '📀 (D:)']});
			this.#renderShare();
			tell('Mormor opened My Computer.', 'Oh, My Computer! Is that where you keep me?');
			await this.#controlWait(token, run, 3500);
			await this.#glide(token, run, this.#shareIcons.homework.x + 22, this.#shareIcons.homework.y + 18);
			this.#share.dragging = 'homework';
			await this.#glide(token, run, this.#shareIcons.bin.x + 22, this.#shareIcons.bin.y + 18);
			this.#share.dragging = undefined;
			this.#share.isHomeworkInBin = true;
			this.#shareIcons.homework.x = 8;
			this.#shareIcons.homework.y = 112;
			this.#renderShare();
			tell('Mormor dragged HOMEWORK.DOC into the Recycle Bin! Click the Recycle Bin later to get it back.', 'This one said HOMEWORK. I tidied it away for you.');
			await this.#controlWait(token, run, 3500);
			await this.#glide(token, run, this.#shareIcons.glitter.x + 22, this.#shareIcons.glitter.y + 18);
			await this.#controlWait(token, run, 500);
			this.#share.hasUnicorn = true;
			this.#renderShare();
			tell('Mormor started GLITTER.EXE. There is a unicorn on your desktop now.', 'A horse with a horn! Is that Glitter?');
			await this.#controlWait(token, run, 3500);
			await this.#glide(token, run, 250, 100);
			this.#share.wallpaper = 'bricks';
			this.#renderShare();
			tell('Mormor changed your wallpaper to Bricks.', 'There. Now it looks like my kitchen.');
			await this.#controlWait(token, run, 3500);
			const notepad = {title: 'Untitled - Notepad', x: 100, y: 90, width: 190, height: 50, lines: ['', '']};
			this.#share.windows.push(notepad);

			for (const [index, line] of ['HELLO SINDRE', 'THIS IS MORMOR IN YOUR COMPUTER'].entries()) {
				for (const character of line) {
					notepad.lines[index] += character;
					this.#renderShare();
					await this.#controlWait(token, run, this.reducedMotion ? 20 : 140);
				}
			}

			// The shared desktop is small on a phone, so the status also says what she typed.
			this.say('Mormor typed a letter to you in Notepad: “HELLO SINDRE, THIS IS MORMOR IN YOUR COMPUTER”.');
			await this.#controlWait(token, run, 2000);
			await this.#glide(token, run, 18, 192);
			this.#share.hasShutDownDialog = true;
			this.#renderShare();
			tell('Mormor clicked Start, then Shut Down! Press Escape or click to take the control back, quick!', 'Is this how you hang up?');
			await this.#controlWait(token, run, 7000);
			this.#share.hasShutDownDialog = false;
			this.#setControl(false);
			tell('Mormor clicked No. Your computer stays on. She gave the control back.', 'No. I did not dare. It said SHUT DOWN. You can have your arrow back, my arm is tired.');
		} catch (error) {
			if (!(error instanceof Cancelled)) {
				throw error;
			}
		}
	}

	#takeControlBack(shouldSay = true) {
		this.#share.run++;
		this.#share.dragging = undefined;
		const hadDialog = this.#share.hasShutDownDialog;
		this.#share.hasShutDownDialog = false;
		this.#setControl(false);

		if (shouldSay) {
			this.say(hadDialog ? 'You took the control back, and clicked No. Your computer stays on.' : 'You took the control back.');
			this.#queueLine(this.#call.token, 'Oh! The arrow moves by itself!', {isRemark: true});
		}
	}

	#restoreHomework() {
		if (!this.#share.isHomeworkInBin) {
			return;
		}

		this.#share.isHomeworkInBin = false;
		this.#renderShare();
		this.say('You got HOMEWORK.DOC back out of the Recycle Bin. Phew.');
	}

	#revealPhoto(fraction) {
		this.#photoContext.fillStyle = '#000000';
		this.#photoContext.fillRect(0, 0, 80, 60);
		const rows = Math.floor(fraction * 60);

		if (rows > 0) {
			this.#photoContext.drawImage(this.#photoSource, 0, 60 - rows, 80, rows, 0, 60 - rows, 80, rows);
		}
	}

	#failTransfer(reason) {
		if (!this.#transfer.isActive) {
			return;
		}

		this.#transfer.run++;
		this.#transfer.isActive = false;
		this.parts.transferCancel.disabled = true;
		this.parts.transferInfo.textContent = `The transfer of ${files[this.#transfer.direction].name} failed. ${reason}`;
	}

	async #startTransfer(token, direction) {
		if (this.#transfer.isActive || this.#call.state !== 'connected') {
			return;
		}

		const run = ++this.#transfer.run;
		const file = files[direction];
		Object.assign(this.#transfer, {isActive: true, direction});
		this.#setTool('transfer', true);
		this.parts.transferName.textContent = direction === 'in' ? `Receiving ${file.name} from Mormor` : `Sending ${file.name} to Mormor`;
		this.parts.transferCancel.disabled = false;
		this.parts.transferProgress.style.width = '0';
		this.#revealPhoto(0);
		this.parts.photo.setAttribute('aria-label', direction === 'in' ? 'The photo, coming in from the bottom' : 'The photo of Rocky, my pet rock');

		if (direction === 'out') {
			this.#photoContext.fillStyle = '#87ceeb';
			this.#photoContext.fillRect(0, 0, 80, 60);
			ellipse(this.#photoContext, 40, 38, 22, 14, '#8a8a8a');
			ellipse(this.#photoContext, 34, 34, 2, 2, '#000000');
			ellipse(this.#photoContext, 46, 34, 2, 2, '#000000');
		}

		this.say(`${this.parts.transferName.textContent}, ${file.size} KB over the modem.`);
		let received = 0;
		let tick = 0;

		while (received < file.size) {
			await this.#during(token, 250);

			if (run !== this.#transfer.run) {
				return;
			}

			tick++;

			// The modem shares its 28,800 bps with the video and the sound, and the speed jumps around, and so does the time left.
			const rate = (this.#call.isVideoPaused ? 3.2 : 1.1) * (0.4 + (Math.random() * 1.2));
			received = Math.min(file.size, received + rate);
			const fraction = received / file.size;
			this.parts.transferProgress.style.width = `${fraction * 100}%`;
			this.parts.transferInfo.textContent = `${Math.floor(received)} KB of ${file.size} KB at ${rate.toFixed(1)} KB/s. ${timeLeft((file.size - received) / rate)}${this.#call.isVideoPaused ? '' : ' Pause the video to go faster.'}`;

			if (direction === 'in') {
				this.#revealPhoto(fraction);
			}

			if (fraction >= 0.97 && !this.#hasMammaPickedUp && !this.#call.isSayingGoodbye) {
				inBackground(this.#mammaPicksUp());
				return;
			}

			if (tick % 60 === 0 && direction === 'in') {
				this.#queueLine(token, randomItem(['Did it come yet?', 'Is it there? Ingrid said it goes like lightning.', 'I can wait. I am old, I am good at waiting.']), {isRemark: true});
			}
		}

		this.#transfer.isActive = false;
		this.parts.transferCancel.disabled = true;
		this.parts.transferProgress.style.width = '100%';

		if (direction === 'in') {
			this.#revealPhoto(1);
			this.parts.photo.setAttribute('aria-label', 'The photo of Pusen, Mormor’s cat, asleep on the sofa, with her thumb over a corner');
			this.parts.transferInfo.textContent = 'Done! Saved in C:\\Program Files\\NetMeeting\\Received Files\\PUSEN.BMP';
			this.say('PUSEN.BMP arrived! It only took forever.');
			this.#queueLine(token, 'Did you get it? Is he not handsome? The pink thing is my thumb.');
		} else {
			this.parts.transferInfo.textContent = 'Done! Mormor received ROCKY.BMP.';
			this.say('ROCKY.BMP arrived at Mormor’s computer.');
			this.#queueLine(token, 'It says it is in Received Files. Where is Received Files? I only have a drawer. … Oh, it is a rock. Lovely rock, dear.');
		}
	}
}
