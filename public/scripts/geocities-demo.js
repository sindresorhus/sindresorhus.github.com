// The helpers of the demo effects of the 1999 page, which the intro (`Cracktro.js`) and the Effect Toy Box (`EffectToys.js`) share: the colors and palettes of the pixels, a canvas that is drawn pixel by pixel, a fast sine, and the loop of an effect.
import {clamp} from '/scripts/geocities-element.js';

export const wrap = (value, size) => ((value % size) + size) % size;

// MARK: Pixels and colors

// A color as the four bytes of a pixel in an `ImageData`, which is red first on the little-endian computers that run browsers.
export const rgb = (red, green, blue) => ((255 << 24) | (clamp(Math.round(blue), 0, 255) << 16) | (clamp(Math.round(green), 0, 255) << 8) | clamp(Math.round(red), 0, 255)) >>> 0;

/**
A palette of 256 colors that goes smoothly through the colors, like the palettes of VGA mode 13h.
*/
const makePalette = stops => {
	const palette = new Uint32Array(256);

	for (let index = 0; index < 256; index++) {
		const position = (index / 256) * (stops.length - 1);
		const from = stops[Math.floor(position)];
		const to = stops[Math.min(Math.floor(position) + 1, stops.length - 1)];
		const amount = position - Math.floor(position);
		palette[index] = rgb(...from.map((value, channel) => value + ((to[channel] - value) * amount)));
	}

	return palette;
};

// The palettes of the effects. Each starts and ends with the same color, so the colors can go around and around.
export const palettes = [
	{name: 'AMIGA', palette: makePalette([[0, 0, 60], [60, 0, 160], [220, 0, 170], [255, 140, 210], [255, 255, 255], [120, 210, 255], [0, 70, 180], [0, 0, 60]])},
	{name: 'ACID', palette: makePalette([[0, 30, 0], [0, 200, 40], [230, 255, 0], [255, 0, 200], [80, 0, 120], [0, 30, 0]])},
	{name: 'FIRE', palette: makePalette([[20, 0, 0], [170, 0, 0], [255, 120, 0], [255, 230, 60], [255, 255, 220], [255, 140, 0], [20, 0, 0]])},
	{name: 'C64', palette: makePalette([[53, 40, 121], [108, 94, 181], [112, 164, 178], [154, 210, 132], [184, 199, 111], [111, 79, 37], [53, 40, 121]])},
	{name: 'RAINBOW', palette: makePalette([[255, 0, 0], [255, 200, 0], [0, 255, 0], [0, 200, 255], [120, 0, 255], [255, 0, 160], [255, 0, 0]])},
];

export const firePalette = makePalette([[0, 0, 0], [80, 0, 0], [200, 30, 0], [255, 120, 0], [255, 210, 40], [255, 255, 180], [255, 255, 255]]);

/**
A canvas that is drawn pixel by pixel, with the pixels as one number each.
*/
export const pixelSurface = canvas => {
	const context = canvas.getContext('2d');
	const image = context.createImageData(canvas.width, canvas.height);

	return {
		context,
		width: canvas.width,
		height: canvas.height,
		pixels: new Uint32Array(image.data.buffer),
		show() {
			context.putImageData(image, 0, 0);
		},
	};
};

// The pixels of a canvas that is drawn with the drawing functions of the browser, like text, as numbers.
export const canvasPixels = canvas => new Uint32Array(canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height).data.buffer);

// A sine from a table, which is much faster for the effects that need one for every pixel. The angle is in steps of 1/1024 of a turn.
const sineTable = Float32Array.from({length: 1024}, (_, index) => Math.sin((index / 1024) * Math.PI * 2));
export const fastSine = steps => sineTable[steps & 1023];

export const loadImage = source => new Promise(resolve => {
	const image = new Image();
	image.addEventListener('load', () => {
		resolve(image);
	});
	image.addEventListener('error', () => {
		resolve(undefined);
	});
	image.src = source;
});

// MARK: The animation

/**
Runs `step(delta)` on each frame while the canvas is on the screen, the tab is visible, and motion is allowed, with a loop of the element. The first picture is drawn with `step(0)` when the canvas first shows, also when nothing moves. The returned controls tell whether it runs and pause it, `poke(delta)` draws one more frame when nothing runs by itself, like when the visitor prefers reduced motion and does something, and `drawStill()` draws a still picture when the motion changes.
*/
export const animate = (element, canvas, step) => {
	let isPaused = false;
	let hasDrawn = false;

	// A step of 0 seconds draws a still picture, like Fractint, which then draws its whole picture at once, or the vector balls that jump to their shape, so the first step of a run moves like a frame.
	const loop = element.loop(seconds => {
		step(seconds || (1 / 60));
	}, {target: canvas, maximumStep: 0.05, while: () => !isPaused && !element.reducedMotion});

	const visibility = element.watchVisibility(canvas, isVisible => {
		if (isVisible && !hasDrawn) {
			hasDrawn = true;
			step(0);
		}
	});

	const isRunning = () => visibility.isVisible && !isPaused && !element.reducedMotion;

	return {
		get isRunning() {
			return isRunning();
		},
		setPaused(value) {
			isPaused = value;
			loop.start();
		},
		poke(delta = 0) {
			if (!isRunning()) {
				step(delta);
			}
		},
		drawStill() {
			if (visibility.isVisible) {
				step(0);
			}
		},
	};
};
