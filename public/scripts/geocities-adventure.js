// The helpers of the adventure games of the 1999 page, which Sindre’s Quest (`Adventure.js`), Insult Seagull Fighting (`InsultFight.js`), WAFFLE QUEST (`WaffleQuest.js`), and the linking book (`LinkingBook.js`) share: the short sound effects, and the palette and the sprites of the pixel art.

// A short sound effect, made in the browser.
export const beep = (audio, frequency, duration = 0.1, {type = 'square', volume = 0.05, when = 0} = {}) => {
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

// The colors of the pixel art, by the letter that the sprites use for them, a palette like the 256 colors of VGA.
export const palette = {
	k: '#000000',
	w: '#ffffff',
	s: '#f4c49c',
	S: '#d8956a',
	h: '#f2d16b',
	H: '#c99a36',
	b: '#2a5bd7',
	B: '#1b3a8a',
	j: '#ffd400',
	J: '#c9a400',
	r: '#d42a2a',
	R: '#8a1414',
	g: '#3fa34d',
	G: '#1f5c2a',
	n: '#8b5a2b',
	N: '#5a3519',
	e: '#8a8a8a',
	E: '#4a4a4a',
	l: '#c8c8c8',
	o: '#ff8c1a',
	p: '#ff8fc8',
	P: '#7a3fb0',
	y: '#ffd700',
	Y: '#b8860b',
	c: '#7fd4ff',
	t: '#8fa86a',
	T: '#5d7a45',
	m: '#b07a3a',
	u: '#9a9aa8',
	U: '#5c5c6a',
};

// Draws a sprite of letters, one letter a pixel and a dot for nothing, at a scale, with its feet at `y`, facing right, or left when it is flipped. The colors can be swapped, like the shirt of Sindre for his rain jacket.
export const drawSprite = (context, rows, x, y, {scale = 2, isFlipped = false, colors = {}} = {}) => {
	const width = rows[0].length;
	const top = Math.round(y - (rows.length * scale));
	const left = Math.round(x - (width * scale / 2));
	for (const [row, line] of rows.entries()) {
		for (let column = 0; column < width; column++) {
			const letter = line[isFlipped ? width - 1 - column : column];
			if (letter === '.') {
				continue;
			}

			context.fillStyle = colors[letter] ?? palette[letter];
			context.fillRect(left + (column * scale), top + (row * scale), scale, scale);
		}
	}
};
