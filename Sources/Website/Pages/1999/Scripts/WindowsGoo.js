// Kai’s Power Goo on the desktop of the 1999 page: a face that the brush warps like liquid, with the tools of Power Goo, the Goo Movie, Undo, and Save as PNG. The faces are drawn here, on a canvas of 256 × 256.
const size = 256;

// The goo is a field of moves on a grid of 65 × 65 points, 4 pixels apart: each pixel of the face shows the pixel of the picture that the field moves it to. The tools change the field, never the picture, so Ungoo and Undo can always go back.
const spacing = 4;
const grid = (size / spacing) + 1;

// The field between the points of the grid.
const sampleField = (fieldXValues, fieldYValues, x, y) => {
	const gridX = Math.min(Math.max(x / spacing, 0), grid - 1.001);
	const gridY = Math.min(Math.max(y / spacing, 0), grid - 1.001);
	const left = Math.floor(gridX);
	const top = Math.floor(gridY);
	const fractionX = gridX - left;
	const fractionY = gridY - top;
	const index = (top * grid) + left;
	const mix = values => {
		const upper = values[index] + ((values[index + 1] - values[index]) * fractionX);
		const lower = values[index + grid] + ((values[index + grid + 1] - values[index + grid]) * fractionX);
		return upper + ((lower - upper) * fractionY);
	};

	return [mix(fieldXValues), mix(fieldYValues)];
};

const toolMessages = {
	smear: 'Smear: drag to push the face around, like clay.',
	grow: 'Grow: hold the brush down to blow up a nose, or the eyes.',
	shrink: 'Shrink: hold it down to make things tiny. Try the ears.',
	twirl: 'Twirl: hold it down to spin the face like a whirlpool.',
	noodle: 'Noodle: hold it down for ripples, like a face in a puddle.',
	smudge: 'Smudge: hold it down, and the face melts like ice cream in the sun.',
	ungoo: 'Ungoo: brush over the goo to put the face back.',
};

// The keyboard: the arrow keys move the brush, and Space holds it down while it moves, so the keyboard goos too.
const arrowMoves = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]};

// The faces, drawn with gradients and shapes on a canvas, so no photo is needed.
const ellipse = (drawing, x, y, radiusX, radiusY, fill, rotation = 0) => {
	drawing.beginPath();
	drawing.ellipse(x, y, radiusX, radiusY, rotation, 0, Math.PI * 2);
	drawing.fillStyle = fill;
	drawing.fill();
};

const radial = (drawing, x, y, radius, stops) => {
	const gradient = drawing.createRadialGradient(x - (radius * 0.3), y - (radius * 0.35), radius * 0.1, x, y, radius);

	for (const [offset, color] of stops) {
		gradient.addColorStop(offset, color);
	}

	return gradient;
};

const linear = (drawing, x1, y1, x2, y2, stops) => {
	const gradient = drawing.createLinearGradient(x1, y1, x2, y2);

	for (const [offset, color] of stops) {
		gradient.addColorStop(offset, color);
	}

	return gradient;
};

const faces = {
	// My school photo of 1999, with the laser background that every school photo had.
	sindre(drawing) {
		drawing.fillStyle = linear(drawing, 0, 0, size, size, [[0, '#1b0b4a'], [0.5, '#3a1d8a'], [1, '#0b3d7a']]);
		drawing.fillRect(0, 0, size, size);
		drawing.save();
		drawing.globalCompositeOperation = 'lighter';
		drawing.lineCap = 'round';

		for (const [index, color] of ['#ff3fb4', '#3fd8ff', '#b06bff', '#ff3fb4', '#3fd8ff', '#ffe14f'].entries()) {
			drawing.strokeStyle = color;
			drawing.globalAlpha = 0.55;
			drawing.lineWidth = 3;
			drawing.shadowColor = color;
			drawing.shadowBlur = 8;
			drawing.beginPath();
			drawing.moveTo(index % 2 === 0 ? 0 : size, size);
			drawing.lineTo((index * 50) - 20, index % 2 === 0 ? -10 : 40);
			drawing.stroke();
		}

		drawing.restore();
		// The sweater, with the band of a Norwegian pattern.
		ellipse(drawing, 128, 280, 120, 90, '#b8232a');
		drawing.fillStyle = '#f5f1e6';
		drawing.fillRect(20, 206, 216, 14);

		for (let x = 24; x < 236; x += 14) {
			drawing.fillStyle = '#1d3f8f';
			drawing.beginPath();
			drawing.moveTo(x, 213);
			drawing.lineTo(x + 7, 207);
			drawing.lineTo(x + 14, 213);
			drawing.lineTo(x + 7, 219);
			drawing.fill();
		}

		drawing.fillStyle = '#e8b48c';
		drawing.fillRect(108, 168, 40, 40);
		// The ears and the head.
		ellipse(drawing, 66, 120, 12, 18, '#e9b38a');
		ellipse(drawing, 190, 120, 12, 18, '#e9b38a');
		ellipse(drawing, 128, 116, 62, 74, radial(drawing, 128, 116, 80, [[0, '#ffdcbc'], [1, '#e2a47c']]));
		// The bowl cut, straight across the forehead.
		drawing.fillStyle = linear(drawing, 0, 30, 0, 100, [[0, '#f7d46b'], [1, '#d9a93c']]);
		drawing.beginPath();
		drawing.ellipse(128, 100, 70, 66, 0, Math.PI, Math.PI * 2);
		drawing.lineTo(198, 112);
		drawing.lineTo(186, 112);
		drawing.lineTo(186, 88);
		drawing.lineTo(70, 88);
		drawing.lineTo(70, 112);
		drawing.lineTo(58, 112);
		drawing.closePath();
		drawing.fill();
		drawing.strokeStyle = '#b8862a';
		drawing.lineWidth = 1;

		for (let x = 74; x < 186; x += 7) {
			drawing.beginPath();
			drawing.moveTo(x, 60);
			drawing.lineTo(x + 2, 88);
			drawing.stroke();
		}

		// The cheeks and the freckles.
		ellipse(drawing, 88, 146, 14, 9, 'rgba(255, 120, 120, 0.35)');
		ellipse(drawing, 168, 146, 14, 9, 'rgba(255, 120, 120, 0.35)');

		for (const [x, y] of [[84, 140], [92, 144], [80, 147], [164, 140], [172, 145], [160, 147], [124, 132], [134, 134]]) {
			ellipse(drawing, x, y, 1.5, 1.5, '#b8744c');
		}

		// The eyes behind big glasses.
		for (const x of [100, 156]) {
			ellipse(drawing, x, 118, 11, 8, '#ffffff');
			ellipse(drawing, x + 1, 119, 6, 6, '#3c7fd0');
			ellipse(drawing, x + 1, 119, 3, 3, '#101010');
			ellipse(drawing, x - 1, 117, 1.5, 1.5, '#ffffff');
			drawing.fillStyle = '#8a5a2a';
			drawing.fillRect(x - 14, 96, 28, 4);
		}

		drawing.lineWidth = 6;
		drawing.strokeStyle = '#3a2418';

		for (const x of [100, 156]) {
			drawing.beginPath();
			drawing.arc(x, 118, 25, 0, Math.PI * 2);
			drawing.fillStyle = 'rgba(180, 220, 255, 0.18)';
			drawing.fill();
			drawing.stroke();
		}

		drawing.beginPath();
		drawing.moveTo(124, 114);
		drawing.quadraticCurveTo(128, 108, 132, 114);
		drawing.stroke();
		drawing.lineWidth = 2;
		drawing.strokeStyle = 'rgba(255, 255, 255, 0.7)';

		for (const x of [92, 148]) {
			drawing.beginPath();
			drawing.arc(x, 110, 10, Math.PI * 1.1, Math.PI * 1.5);
			drawing.stroke();
		}

		// The nose, and the big smile with braces.
		drawing.strokeStyle = '#c0805a';
		drawing.lineWidth = 3;
		drawing.beginPath();
		drawing.moveTo(128, 124);
		drawing.quadraticCurveTo(122, 144, 132, 146);
		drawing.stroke();
		drawing.fillStyle = '#7a1e22';
		drawing.beginPath();
		drawing.moveTo(98, 158);
		drawing.quadraticCurveTo(128, 196, 158, 158);
		drawing.closePath();
		drawing.fill();
		drawing.fillStyle = '#ffffff';
		drawing.beginPath();
		drawing.moveTo(102, 160);
		drawing.lineTo(154, 160);
		drawing.quadraticCurveTo(150, 172, 128, 173);
		drawing.quadraticCurveTo(106, 172, 102, 160);
		drawing.fill();
		drawing.fillStyle = '#9aa0a8';

		for (let x = 106; x < 152; x += 8) {
			drawing.fillRect(x, 163, 5, 5);
		}

		drawing.strokeStyle = '#6a7078';
		drawing.lineWidth = 1.5;
		drawing.beginPath();
		drawing.moveTo(104, 165.5);
		drawing.lineTo(152, 165.5);
		drawing.stroke();
	},
	// Pappa, with the mustache, the glasses of a pilot, and the hair that has moved to the back.
	pappa(drawing) {
		drawing.fillStyle = '#d8c39a';
		drawing.fillRect(0, 0, size, size);

		for (let x = 0; x < size; x += 32) {
			drawing.fillStyle = '#b89a6a';
			drawing.fillRect(x, 0, 12, size);
			drawing.fillStyle = '#e6d3ae';
			drawing.fillRect(x + 14, 0, 4, size);
		}

		ellipse(drawing, 128, 290, 130, 100, '#4a6fa8');
		drawing.fillStyle = '#ffffff';
		drawing.beginPath();
		drawing.moveTo(96, 196);
		drawing.lineTo(128, 236);
		drawing.lineTo(160, 196);
		drawing.fill();
		drawing.fillStyle = '#7a3a1a';
		drawing.beginPath();
		drawing.moveTo(122, 210);
		drawing.lineTo(134, 210);
		drawing.lineTo(140, 256);
		drawing.lineTo(116, 256);
		drawing.fill();
		drawing.fillStyle = '#e0a47c';
		drawing.fillRect(106, 168, 44, 34);
		// The hair at the back, long, like a mullet.
		ellipse(drawing, 128, 130, 76, 70, '#6a4424');
		ellipse(drawing, 66, 122, 12, 18, '#e0a47c');
		ellipse(drawing, 190, 122, 12, 18, '#e0a47c');
		ellipse(drawing, 128, 116, 60, 74, radial(drawing, 128, 116, 80, [[0, '#f8cfa8'], [1, '#d4946a']]));
		// The shiny top of the head, and the hair that is left on the sides.
		ellipse(drawing, 112, 64, 18, 8, 'rgba(255, 255, 255, 0.45)', -0.3);
		ellipse(drawing, 72, 96, 10, 24, '#6a4424');
		ellipse(drawing, 184, 96, 10, 24, '#6a4424');
		drawing.fillStyle = '#5a3a1c';
		drawing.fillRect(84, 92, 30, 6);
		drawing.fillRect(142, 92, 30, 6);
		// The glasses of a pilot, gold, with brown glass.
		for (const x of [100, 156]) {
			ellipse(drawing, x, 116, 6, 5, '#2a1a10');
			drawing.beginPath();
			drawing.moveTo(x - 24, 104);
			drawing.quadraticCurveTo(x, 98, x + 24, 104);
			drawing.quadraticCurveTo(x + 24, 136, x, 138);
			drawing.quadraticCurveTo(x - 24, 136, x - 24, 104);
			drawing.fillStyle = 'rgba(120, 70, 20, 0.55)';
			drawing.fill();
			drawing.strokeStyle = '#d4a017';
			drawing.lineWidth = 3;
			drawing.stroke();
		}

		drawing.beginPath();
		drawing.moveTo(124, 106);
		drawing.lineTo(132, 106);
		drawing.stroke();
		// The nose, and the big mustache.
		drawing.fillStyle = '#d08a60';
		drawing.beginPath();
		drawing.moveTo(128, 118);
		drawing.lineTo(118, 150);
		drawing.quadraticCurveTo(128, 156, 138, 150);
		drawing.closePath();
		drawing.fill();
		drawing.fillStyle = '#4a2c14';
		drawing.beginPath();
		drawing.moveTo(96, 170);
		drawing.quadraticCurveTo(100, 150, 128, 154);
		drawing.quadraticCurveTo(156, 150, 160, 170);
		drawing.quadraticCurveTo(144, 162, 128, 164);
		drawing.quadraticCurveTo(112, 162, 96, 170);
		drawing.fill();
		drawing.strokeStyle = '#8a3a2a';
		drawing.lineWidth = 3;
		drawing.beginPath();
		drawing.moveTo(112, 176);
		drawing.quadraticCurveTo(128, 182, 144, 176);
		drawing.stroke();
	},
	// Pus, the cat of the neighbors, who sits for nobody.
	cat(drawing) {
		drawing.fillStyle = linear(drawing, 0, 0, 0, size, [[0, '#bfe3ff'], [1, '#7fb8e8']]);
		drawing.fillRect(0, 0, size, size);
		ellipse(drawing, 128, 270, 110, 80, '#e8892c');

		for (const side of [-1, 1]) {
			drawing.fillStyle = '#e8892c';
			drawing.beginPath();
			drawing.moveTo(128 + (side * 30), 70);
			drawing.lineTo(128 + (side * 78), 18);
			drawing.lineTo(128 + (side * 86), 100);
			drawing.fill();
			drawing.fillStyle = '#f7a8b8';
			drawing.beginPath();
			drawing.moveTo(128 + (side * 42), 72);
			drawing.lineTo(128 + (side * 74), 36);
			drawing.lineTo(128 + (side * 78), 92);
			drawing.fill();
		}

		ellipse(drawing, 128, 130, 92, 80, radial(drawing, 128, 130, 100, [[0, '#ffb45c'], [1, '#d8741c']]));

		for (const [x, y, angle] of [[128, 62, 0], [110, 66, -0.2], [146, 66, 0.2], [52, 130, 1.4], [204, 130, -1.4]]) {
			ellipse(drawing, x, y, 4, 16, '#b85a14', angle);
		}

		ellipse(drawing, 108, 170, 26, 20, '#fff4e6');
		ellipse(drawing, 148, 170, 26, 20, '#fff4e6');

		for (const x of [92, 164]) {
			ellipse(drawing, x, 124, 20, 17, '#9fd84a');
			ellipse(drawing, x, 124, 4, 15, '#101010');
			ellipse(drawing, x - 6, 118, 3.5, 3.5, '#ffffff');
		}

		drawing.fillStyle = '#f07a96';
		drawing.beginPath();
		drawing.moveTo(118, 152);
		drawing.lineTo(138, 152);
		drawing.lineTo(128, 164);
		drawing.fill();
		drawing.strokeStyle = '#5a2a10';
		drawing.lineWidth = 2.5;
		drawing.beginPath();
		drawing.moveTo(128, 164);
		drawing.quadraticCurveTo(122, 176, 112, 172);
		drawing.moveTo(128, 164);
		drawing.quadraticCurveTo(134, 176, 144, 172);
		drawing.stroke();
		drawing.strokeStyle = '#ffffff';
		drawing.lineWidth = 1.5;

		for (const side of [-1, 1]) {
			for (const offset of [-8, 0, 8]) {
				drawing.beginPath();
				drawing.moveTo(128 + (side * 30), 168 + (offset / 2));
				drawing.lineTo(128 + (side * 100), 160 + (offset * 2));
				drawing.stroke();
			}
		}
	},
	// The Mona Lisa, as I copied it in Paint from a book: the smile, the folded hands, and the hills behind her.
	mona(drawing) {
		drawing.fillStyle = linear(drawing, 0, 0, 0, size, [[0, '#c9c48a'], [0.4, '#8fa078'], [1, '#3a4a30']]);
		drawing.fillRect(0, 0, size, size);
		drawing.fillStyle = '#5a5a38';
		drawing.beginPath();
		drawing.moveTo(0, 120);
		drawing.quadraticCurveTo(40, 90, 70, 130);
		drawing.lineTo(70, 256);
		drawing.lineTo(0, 256);
		drawing.fill();
		drawing.beginPath();
		drawing.moveTo(256, 110);
		drawing.quadraticCurveTo(210, 80, 186, 120);
		drawing.lineTo(186, 256);
		drawing.lineTo(256, 256);
		drawing.fill();
		drawing.strokeStyle = '#b89a5a';
		drawing.lineWidth = 3;
		drawing.beginPath();
		drawing.moveTo(10, 170);
		drawing.quadraticCurveTo(40, 150, 30, 130);
		drawing.moveTo(246, 160);
		drawing.quadraticCurveTo(220, 140, 236, 118);
		drawing.stroke();
		// The dress and the hands.
		ellipse(drawing, 128, 270, 112, 96, '#2e2a18');
		ellipse(drawing, 128, 214, 40, 22, radial(drawing, 128, 214, 44, [[0, '#e8c890'], [1, '#b88a50']]));
		ellipse(drawing, 110, 250, 30, 14, '#d8b070', -0.2);
		ellipse(drawing, 148, 246, 30, 13, '#e2bc7c', 0.15);
		// The long dark hair, and the face.
		ellipse(drawing, 128, 112, 64, 84, '#2a1c10');
		ellipse(drawing, 128, 108, 46, 60, radial(drawing, 128, 108, 64, [[0, '#f2d49a'], [1, '#c09050']]));
		drawing.fillStyle = 'rgba(30, 20, 10, 0.35)';
		drawing.beginPath();
		drawing.ellipse(128, 56, 50, 16, 0, Math.PI, Math.PI * 2);
		drawing.fill();

		for (const x of [110, 146]) {
			ellipse(drawing, x, 104, 9, 4, '#f6e8c8');
			ellipse(drawing, x + 1, 104, 4, 4, '#3a2410');
			drawing.strokeStyle = 'rgba(80, 50, 20, 0.6)';
			drawing.lineWidth = 2;
			drawing.beginPath();
			drawing.arc(x, 106, 11, Math.PI * 1.15, Math.PI * 1.85);
			drawing.stroke();
		}

		drawing.strokeStyle = 'rgba(120, 70, 30, 0.7)';
		drawing.lineWidth = 2;
		drawing.beginPath();
		drawing.moveTo(128, 108);
		drawing.quadraticCurveTo(124, 126, 132, 128);
		drawing.stroke();
		// The famous smile: barely there, and a little bit to one side.
		drawing.strokeStyle = '#8a4a2a';
		drawing.lineWidth = 2.5;
		drawing.beginPath();
		drawing.moveTo(114, 142);
		drawing.quadraticCurveTo(128, 148, 144, 140);
		drawing.stroke();
		// Old, yellow varnish over everything.
		drawing.fillStyle = 'rgba(160, 120, 20, 0.15)';
		drawing.fillRect(0, 0, size, size);
	},
};

const faceMessages = {
	sindre: 'My school photo of 1999. The laser background was free. The braces were not.',
	pappa: 'Pappa. The goo stays on, so Pappa gets the same goo as the face before.',
	cat: 'Pus, the cat of the neighbors. She does not like this.',
	mona: 'The Mona Lisa, as I copied it in Paint. Leonardo took 4 years. I took 20 minutes.',
};

export default class extends GeoCitiesElement {
	#context;
	#output;
	#fieldX = new Float32Array(grid * grid);
	#fieldY = new Float32Array(grid * grid);
	#picture;
	#isDirty = false;
	#frame;
	#tool = 'smear';

	// The brush, which shows where it goos while the pointer is over the face, or while the keyboard moves it.
	#brush = {x: size / 2, y: size / 2, isVisible: false};

	// Undo keeps the field of before each stroke, up to 20 strokes.
	#undoSteps = [];

	#isPressed = false;
	#pressLoop;
	#movie;
	#movieLoop;

	connected() {
		const {canvas, face, size: sizePicker, undo, reset, movie, save} = this.parts;
		this.#context = canvas.getContext('2d');
		this.#output = this.#context.createImageData(size, size);

		// While the brush is down, the tools that do not need a drag, like Grow, keep going, one step each frame.
		this.#pressLoop = this.loop(() => {
			this.#applyTool(this.#brush.x, this.#brush.y);
		}, {while: () => this.#isPressed && this.#tool !== 'smear'});

		this.#movieLoop = this.loop((seconds, time) => {
			this.#playMovie(time);
		}, {while: () => this.#movie !== undefined});

		this.on(canvas, 'pointerdown', event => {
			if (event.button !== 0) {
				return;
			}

			event.preventDefault();
			canvas.focus();
			canvas.setPointerCapture(event.pointerId);
			const [x, y] = this.#canvasPoint(event);
			this.#brush.x = x;
			this.#brush.y = y;
			this.#brush.isVisible = true;
			this.#pressBrush();
			this.#requestDraw();
		});

		this.on(canvas, 'pointermove', event => {
			const [x, y] = this.#canvasPoint(event);
			this.#brush.isVisible = true;
			this.#moveBrush(x, y);
		});

		for (const type of ['pointerup', 'pointercancel']) {
			this.on(canvas, type, () => {
				this.#releaseBrush();
			});
		}

		this.on(canvas, 'pointerleave', event => {
			if (!this.#isPressed && event.pointerType === 'mouse') {
				this.#brush.isVisible = false;
				this.#requestDraw();
			}
		});

		this.on(canvas, 'keydown', event => {
			const arrow = arrowMoves[event.key];

			if (arrow) {
				event.preventDefault();
				const step = event.shiftKey ? 20 : 6;
				this.#brush.isVisible = true;
				this.#moveBrush(Math.min(Math.max(this.#brush.x + (arrow[0] * step), 0), size), Math.min(Math.max(this.#brush.y + (arrow[1] * step), 0), size));
			} else if (event.key === ' ') {
				event.preventDefault();

				if (!event.repeat && !this.#isPressed) {
					this.#brush.isVisible = true;
					this.#pressBrush();
					this.#requestDraw();
				}
			}
		});

		this.on(canvas, 'keyup', event => {
			if (event.key === ' ') {
				this.#releaseBrush();
			}
		});

		this.on(canvas, 'focus', () => {
			this.#brush.isVisible = true;
			this.#requestDraw();
		});

		this.on(canvas, 'blur', () => {
			this.#releaseBrush();
			this.#brush.isVisible = false;
			this.#requestDraw();
		});

		for (const button of this.querySelectorAll('[data-goo-tool]')) {
			this.on(button, 'click', () => {
				this.#pickTool(button.dataset.gooTool);
				this.say(toolMessages[button.dataset.gooTool]);
			});
		}

		this.on(sizePicker, 'change', () => {
			this.#requestDraw();
		});

		this.on(undo, 'click', () => {
			this.#stopMovie();
			const step = this.#undoSteps.pop();

			if (!step) {
				this.say('Nothing to undo. The face is as you found it.');
				return;
			}

			[this.#fieldX, this.#fieldY] = step;
			this.#requestDraw(true);
			this.say('Undone. Goo is forgiving.');
		});

		this.on(reset, 'click', () => {
			this.#stopMovie();
			this.#rememberField();
			this.#fieldX = new Float32Array(grid * grid);
			this.#fieldY = new Float32Array(grid * grid);
			this.#requestDraw(true);
			this.say('The face is back to normal. Undo brings the goo back.');
		});

		this.on(face, 'change', () => {
			this.#stopMovie();
			this.#drawFace(face.value);
			this.say(faceMessages[face.value]);
		});

		this.on(movie, 'click', () => {
			if (this.reducedMotion) {
				const isBefore = movie.getAttribute('aria-pressed') !== 'true';
				movie.setAttribute('aria-pressed', String(isBefore));
				this.#renderFace(isBefore ? 0 : 1);
				this.#isDirty = !isBefore;
				this.#show();
				this.say(isBefore ? 'Before: the face as it was. The movie does not move, as you prefer less motion. Press again for after.' : 'After: with all your goo.');
				return;
			}

			if (this.#movie) {
				this.#stopMovie();
				return;
			}

			this.#movie = {};
			movie.setAttribute('aria-pressed', 'true');
			this.say('Goo Movie! Starring the face, and your goo.');
			this.#movieLoop.start();
		});

		this.on(save, 'click', () => {
			this.#stopMovie();
			this.#renderFace();
			this.#isDirty = false;
			this.#context.putImageData(this.#output, 0, 0);
			canvas.toBlob(blob => {
				const link = document.createElement('a');
				link.href = URL.createObjectURL(blob);
				link.download = 'GOO.PNG';
				link.click();
				setTimeout(() => {
					URL.revokeObjectURL(link.href);
				}, 1000);
				this.#show();
				this.say('Saved as GOO.PNG. Print it and hang it on the fridge.');
			});
		});

		this.#pickTool('smear');
	}

	// The movie and the brush only run while the face is on screen, in an open window, in a visible tab.
	get visibilityTarget() {
		return this.parts.canvas;
	}

	visibilityChanged(isVisible) {
		if (!isVisible) {
			this.#stopMovie();
			this.#releaseBrush();
		}
	}

	// The face is drawn when the window opens for the first time, so the page does not draw it for nothing. A window that is open already, like after a restore of the page, needs its face too.
	windowChanged(isOpen) {
		if (isOpen && !this.#picture) {
			this.#drawFace(this.parts.face.value);
		}
	}

	reducedMotionChanged() {
		this.#stopMovie();
		this.parts.movie.setAttribute('aria-pressed', 'false');
		this.#requestDraw(true);
	}

	// Draws the face through the field, with the moves times `amount`, which the Goo Movie changes.
	#renderFace(amount = 1) {
		const pixels = this.#output.data;
		const source = this.#picture.data;

		for (let y = 0; y < size; y++) {
			for (let x = 0; x < size; x++) {
				const [moveX, moveY] = sampleField(this.#fieldX, this.#fieldY, x, y);
				const sourceX = Math.min(Math.max(x + (moveX * amount), 0), size - 1);
				const sourceY = Math.min(Math.max(y + (moveY * amount), 0), size - 1);
				const left = Math.floor(sourceX);
				const top = Math.floor(sourceY);
				const right = Math.min(left + 1, size - 1);
				const bottom = Math.min(top + 1, size - 1);
				const fractionX = sourceX - left;
				const fractionY = sourceY - top;
				const topLeft = ((top * size) + left) * 4;
				const topRight = ((top * size) + right) * 4;
				const bottomLeft = ((bottom * size) + left) * 4;
				const bottomRight = ((bottom * size) + right) * 4;
				const target = ((y * size) + x) * 4;

				for (let channel = 0; channel < 3; channel++) {
					const upper = source[topLeft + channel] + ((source[topRight + channel] - source[topLeft + channel]) * fractionX);
					const lower = source[bottomLeft + channel] + ((source[bottomRight + channel] - source[bottomLeft + channel]) * fractionX);
					pixels[target + channel] = upper + ((lower - upper) * fractionY);
				}

				pixels[target + 3] = 255;
			}
		}
	}

	get #brushRadius() {
		return Number(this.parts.size.value);
	}

	#show() {
		const context = this.#context;
		context.putImageData(this.#output, 0, 0);

		if (this.#brush.isVisible) {
			context.save();
			context.setLineDash([4, 4]);
			context.lineWidth = 2;
			context.strokeStyle = '#ffd27a';
			context.beginPath();
			context.arc(this.#brush.x, this.#brush.y, this.#brushRadius, 0, Math.PI * 2);
			context.stroke();
			context.restore();
		}
	}

	#draw() {
		this.#frame = undefined;

		if (!this.#picture) {
			return;
		}

		if (this.#isDirty) {
			this.#renderFace();
			this.#isDirty = false;
		}

		this.#show();
	}

	#requestDraw(changed = false) {
		this.#isDirty ||= changed;
		this.#frame ??= requestAnimationFrame(() => {
			this.#draw();
		});
	}

	// The tools. Each one moves the points of the grid inside the brush, the most in the middle. A point shows what an old point showed, so the goo of before moves along, like liquid.
	#applyTool(centerX, centerY, {moveX = 0, moveY = 0} = {}) {
		const radius = this.#brushRadius;
		const tool = this.#tool;
		const fieldX = this.#fieldX;
		const fieldY = this.#fieldY;
		const oldX = fieldX.slice();
		const oldY = fieldY.slice();
		const first = Math.max(Math.floor((centerY - radius) / spacing), 0);
		const last = Math.min(Math.ceil((centerY + radius) / spacing), grid - 1);
		const firstColumn = Math.max(Math.floor((centerX - radius) / spacing), 0);
		const lastColumn = Math.min(Math.ceil((centerX + radius) / spacing), grid - 1);

		for (let row = first; row <= last; row++) {
			for (let column = firstColumn; column <= lastColumn; column++) {
				const pointX = column * spacing;
				const pointY = row * spacing;
				const offsetX = pointX - centerX;
				const offsetY = pointY - centerY;
				const distance = Math.hypot(offsetX, offsetY);

				if (distance >= radius) {
					continue;
				}

				const falloff = (1 - ((distance / radius) ** 2)) ** 2;
				const index = (row * grid) + column;
				let sourceX = pointX;
				let sourceY = pointY;

				if (tool === 'ungoo') {
					fieldX[index] = oldX[index] * (1 - (0.12 * falloff));
					fieldY[index] = oldY[index] * (1 - (0.12 * falloff));
					continue;
				}

				if (tool === 'smear') {
					sourceX -= moveX * falloff;
					sourceY -= moveY * falloff;
				} else if (tool === 'smudge') {
					// The face melts down, like ice cream in the sun.
					sourceY -= 1.6 * falloff;
					sourceX -= Math.sin(pointY / 9) * 0.4 * falloff;
				} else if (tool === 'twirl') {
					const angle = 0.07 * falloff;
					sourceX = centerX + (offsetX * Math.cos(angle)) - (offsetY * Math.sin(angle));
					sourceY = centerY + (offsetX * Math.sin(angle)) + (offsetY * Math.cos(angle));
				} else {
					const scales = {
						grow: 1 - (0.035 * falloff),
						shrink: 1 + (0.035 * falloff),
						noodle: 1 + (0.05 * falloff * Math.sin((distance / radius) * Math.PI * 3)),
					};

					sourceX = centerX + (offsetX * scales[tool]);
					sourceY = centerY + (offsetY * scales[tool]);
				}

				const [oldMoveX, oldMoveY] = sampleField(oldX, oldY, sourceX, sourceY);
				fieldX[index] = sourceX + oldMoveX - pointX;
				fieldY[index] = sourceY + oldMoveY - pointY;
			}
		}

		this.#requestDraw(true);
	}

	#rememberField() {
		this.#undoSteps.push([this.#fieldX.slice(), this.#fieldY.slice()]);

		if (this.#undoSteps.length > 20) {
			this.#undoSteps.shift();
		}
	}

	#pressBrush() {
		this.#stopMovie();
		this.#rememberField();
		this.#isPressed = true;
		this.#pressLoop.start();
	}

	#releaseBrush() {
		this.#isPressed = false;
		this.#pressLoop.stop();
	}

	// A long drag is cut into short steps, so a fast smear stays smooth.
	#smearTo(x, y) {
		const moveX = x - this.#brush.x;
		const moveY = y - this.#brush.y;
		const steps = Math.max(Math.ceil(Math.hypot(moveX, moveY) / 3), 1);

		for (let step = 1; step <= steps; step++) {
			const fromX = this.#brush.x + ((moveX * (step - 1)) / steps);
			const fromY = this.#brush.y + ((moveY * (step - 1)) / steps);
			this.#applyTool(fromX, fromY, {moveX: moveX / steps, moveY: moveY / steps});
		}
	}

	#moveBrush(x, y) {
		if (this.#isPressed && this.#tool === 'smear') {
			this.#smearTo(x, y);
		}

		this.#brush.x = x;
		this.#brush.y = y;
		this.#requestDraw();
	}

	#canvasPoint(event) {
		const box = this.parts.canvas.getBoundingClientRect();
		return [((event.clientX - box.left) / box.width) * size, ((event.clientY - box.top) / box.height) * size];
	}

	#pickTool(name) {
		this.#tool = name;

		for (const button of this.querySelectorAll('[data-goo-tool]')) {
			const isPicked = button.dataset.gooTool === name;
			button.setAttribute('aria-pressed', String(isPicked));

			if (isPicked) {
				button.dataset.state = 'on';
			} else {
				delete button.dataset.state;
			}
		}
	}

	#drawFace(name) {
		const pictureCanvas = document.createElement('canvas');
		pictureCanvas.width = size;
		pictureCanvas.height = size;
		const drawing = pictureCanvas.getContext('2d');
		faces[name](drawing);
		this.#picture = drawing.getImageData(0, 0, size, size);
		this.#requestDraw(true);
	}

	// The Goo Movie plays the goo from the face as it was to the goo and back, three times, like the movies of Power Goo. Visitors who prefer less motion see the face as it was while the button is pressed in, and the goo again when it is not.
	#stopMovie() {
		const {movie} = this.parts;

		// The Before and After button of reduced motion has no movie, but is pressed for After.
		movie.setAttribute('aria-pressed', 'false');

		if (!this.#movie) {
			return;
		}

		this.#movie = undefined;
		this.#movieLoop.stop();
		movie.setAttribute('aria-pressed', 'false');
		this.#requestDraw(true);
	}

	#playMovie(time) {
		this.#movie.start ??= time;
		const elapsed = (time - this.#movie.start) / 1000;

		if (elapsed > 7.5) {
			this.#stopMovie();
			this.say('The end. Goo Movie by Sindre, 1999.');
			return;
		}

		// Each trip from the face to the goo and back takes 2.5 seconds, smooth at both ends.
		const amount = (1 - Math.cos((elapsed / 2.5) * Math.PI * 2)) / 2;
		this.#renderFace(amount);
		this.#isDirty = true;
		this.#show();
	}
}
