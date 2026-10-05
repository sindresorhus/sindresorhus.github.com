// The visualizer of the Music Room on the 1999 page, a Winamp plugin that draws the sound of the whole room on a screen of 320 × 200 pixels, from the analyser of the sound card after the volume. It runs only while the screen is on the screen and the tab is visible, and shows a still picture for visitors who prefer reduced motion.
import {analyser} from '/scripts/geocities-sound-card.js';

const randomItem = items => items[Math.floor(Math.random() * items.length)];

export default class extends GeoCitiesElement {
	#update;

	connected() {
		const {canvas, status, random, fullScreen: fullScreenButton} = this.parts;
		const drawing = canvas.getContext('2d');
		const presetButtons = [...this.querySelectorAll('[data-visualizer-preset]')];
		const effectBoxes = [...this.querySelectorAll('[data-visualizer-effect]')];
		const width = 320;
		const height = 200;
		const frequencies = new Uint8Array(512);
		const wave = new Uint8Array(1024);
		const stars = Array.from({length: 140}, () => ({x: (Math.random() * 2) - 1, y: (Math.random() * 2) - 1, z: Math.random()}));
		let preset = 'scope';
		let time = 0;
		let energyAverage = 0;
		let lastBeat = 0;

		const effect = id => effectBoxes.find(box => box.dataset.visualizerEffect === id).checked;

		// Reads the sound, or makes up a calm wave for the still picture and while nothing has played yet.
		const listen = isStill => {
			if (analyser && !isStill) {
				analyser.getByteFrequencyData(frequencies);
				analyser.getByteTimeDomainData(wave);
				return;
			}

			for (const index of frequencies.keys()) {
				frequencies[index] = isStill ? Math.max(0, 200 - (index * 1.2) + (40 * Math.sin(index / 6))) : 0;
			}

			for (const index of wave.keys()) {
				wave[index] = 128 + (isStill ? 60 * Math.sin(index / 40) * Math.cos(index / 170) : 0);
			}
		};

		// A beat is a moment when the bass is much louder than it was on average.
		const detectBeat = now => {
			let energy = 0;

			for (let index = 0; index < 8; index++) {
				energy += frequencies[index];
			}

			energy /= 8;
			energyAverage = (energyAverage * 0.95) + (energy * 0.05);
			// At most three beats a second, so the flash on the beat does not flash faster than that.
			const isBeat = energy > 90 && energy > energyAverage * 1.25 && now - lastBeat > 340;

			if (isBeat) {
				lastBeat = now;
			}

			return {energy, isBeat};
		};

		const color = (offset, lightness = 55) => `hsl(${effect('rainbow') ? (time * 60) + offset : 120 + (offset / 8)} 100% ${lightness}%)`;

		const presets = {
			scope({energy}) {
				// The wave, wound into a spiral that turns.
				drawing.lineWidth = 2;
				drawing.strokeStyle = color(0);
				drawing.beginPath();

				for (let index = 0; index < wave.length; index += 4) {
					const progress = index / wave.length;
					const angle = (progress * Math.PI * 6) + (time * 1.5);
					const radius = 10 + (progress * 70) + (((wave[index] - 128) / 128) * (30 + (energy / 6)));
					const x = (width / 2) + (Math.cos(angle) * radius * 1.3);
					const y = (height / 2) + (Math.sin(angle) * radius);

					if (index === 0) {
						drawing.moveTo(x, y);
					} else {
						drawing.lineTo(x, y);
					}
				}

				drawing.stroke();
			},
			fire() {
				// Bars of the spectrum from the middle, yellow at the bottom and red at the top, like flames.
				const bars = 32;
				const barWidth = width / bars / 2;

				for (let bar = 0; bar < bars; bar++) {
					const value = frequencies[Math.floor((bar ** 1.5) * 1.6)] / 255;
					const barHeight = value * height * 0.95;
					const gradient = drawing.createLinearGradient(0, height, 0, height - barHeight);
					gradient.addColorStop(0, '#ffff00');
					gradient.addColorStop(0.5, effect('rainbow') ? color(bar * 10) : '#ff6600');
					gradient.addColorStop(1, '#cc0000');
					drawing.fillStyle = gradient;
					drawing.fillRect((width / 2) + (bar * barWidth), height - barHeight, barWidth - 1, barHeight);
					drawing.fillRect((width / 2) - ((bar + 1) * barWidth), height - barHeight, barWidth - 1, barHeight);
				}
			},
			tunnel({energy, isBeat}) {
				// Rings that fly out of the middle, faster with the beat, and a unicorn that grows with the bass.
				for (let ring = 0; ring < 9; ring++) {
					const radius = ((time * 60) + (ring * 25)) % 225;
					drawing.lineWidth = 1 + (energy / 40);
					drawing.strokeStyle = color(ring * 40, isBeat ? 75 : 55);
					drawing.beginPath();
					drawing.ellipse(width / 2, height / 2, radius * 1.3, radius, time / 2, 0, Math.PI * 2);
					drawing.stroke();
				}

				drawing.font = `${24 + (energy / 5)}px sans-serif`;
				drawing.textAlign = 'center';
				drawing.textBaseline = 'middle';
				drawing.fillText('🦄', width / 2, height / 2);
			},
			stars({energy, isBeat}) {
				// Stars that fly at the screen, faster when the music is louder.
				const speed = 0.004 + (energy / 9000) + (isBeat ? 0.03 : 0);
				drawing.fillStyle = color(0, 80);

				for (const star of stars) {
					star.z -= speed;

					if (star.z <= 0.01) {
						star.x = (Math.random() * 2) - 1;
						star.y = (Math.random() * 2) - 1;
						star.z = 1;
					}

					const x = (width / 2) + ((star.x / star.z) * 80);
					const y = (height / 2) + ((star.y / star.z) * 60);
					const size = 0.6 + ((1 - star.z) * 3.5);
					drawing.fillRect(x, y, size, size);
				}
			},
			waves() {
				// The plain oscilloscope of Winamp, and a mirror of it in pink.
				for (const [index, offset] of [[0, -30], [1, 30]]) {
					drawing.lineWidth = 2;
					drawing.strokeStyle = index === 0 ? color(0) : color(180);
					drawing.beginPath();

					for (let x = 0; x < width; x++) {
						const sample = wave[Math.floor((x / width) * wave.length)];
						const y = (height / 2) + offset + (((sample - 128) / 128) * 80 * (index === 0 ? 1 : -1));

						if (x === 0) {
							drawing.moveTo(x, y);
						} else {
							drawing.lineTo(x, y);
						}
					}

					drawing.stroke();
				}
			},
		};

		const draw = (now, isStill = false) => {
			listen(isStill);
			const beat = detectBeat(now);

			// Trails zoom the last picture a little and fade it, like the “dynamic movement” of the plugins of the time.
			if (effect('trails') && !isStill) {
				drawing.globalAlpha = 0.88;
				drawing.drawImage(canvas, -6, -4, width + 12, height + 8);
				drawing.globalAlpha = 1;
				drawing.fillStyle = 'rgb(0 0 0 / 0.18)';
				drawing.fillRect(0, 0, width, height);
			} else {
				drawing.fillStyle = '#000';
				drawing.fillRect(0, 0, width, height);
			}

			presets[preset](beat);

			if (effect('mirror')) {
				drawing.save();
				drawing.scale(-1, 1);
				drawing.drawImage(canvas, 0, 0, width / 2, height, -width, 0, width / 2, height);
				drawing.restore();
			}

			if (effect('flash') && beat.isBeat && !isStill) {
				drawing.globalCompositeOperation = 'difference';
				drawing.fillStyle = '#fff';
				drawing.fillRect(0, 0, width, height);
				drawing.globalCompositeOperation = 'source-over';
			}

			if (!analyser && !isStill) {
				drawing.font = 'bold 11px "Courier New", monospace';
				drawing.textAlign = 'center';
				drawing.fillStyle = '#00e000';
				drawing.fillText('NO SIGNAL. PLAY SOMETHING IN THE MUSIC ROOM ♪', width / 2, height - 12);
			}
		};

		// Until the room makes a sound, the screen shows “NO SIGNAL” once, and the loop only waits for the sound. The loop runs while the canvas is on the screen and the tab is visible.
		let hasDrawnIdle = false;

		this.loop((seconds, now) => {
			time = now / 1000;

			if (analyser || !hasDrawnIdle) {
				draw(now);
				hasDrawnIdle = true;
			}
		}, {while: () => !this.reducedMotion});

		this.#update = () => {
			if (this.reducedMotion) {
				// A still picture at a moment with nice colors.
				time = 2.5;
				draw(performance.now(), true);
				status.textContent = 'This is a still picture, as your device asks for less motion.';
				return;
			}

			status.textContent = '';
		};

		const choosePreset = id => {
			preset = id;

			for (const button of presetButtons) {
				const isOn = button.dataset.visualizerPreset === id;
				button.setAttribute('aria-pressed', String(isOn));

				if (isOn) {
					button.dataset.state = 'on';
				} else {
					delete button.dataset.state;
				}
			}

			canvas.setAttribute('aria-label', `The visualizer, showing ${presetButtons.find(button => button.dataset.visualizerPreset === id).textContent.trim()}`);

			if (this.reducedMotion) {
				draw(performance.now(), true);
			}
		};

		for (const button of presetButtons) {
			this.on(button, 'click', () => {
				choosePreset(button.dataset.visualizerPreset);
			});
		}

		for (const box of effectBoxes) {
			this.on(box, 'change', () => {
				if (this.reducedMotion) {
					draw(performance.now(), true);
				}
			});
		}

		this.on(random, 'click', () => {
			// Random leaves the flash as it is, as the visitor did not ask for flashes.
			for (const box of effectBoxes) {
				if (box.dataset.visualizerEffect !== 'flash') {
					box.checked = Math.random() < 0.5;
				}
			}

			choosePreset(randomItem(presetButtons.filter(button => button.dataset.visualizerPreset !== preset)).dataset.visualizerPreset);
		});

		// Full screen, like Alt+Enter in Winamp. Safari on the iPhone cannot show a canvas in full screen, so the button is hidden there. Escape leaves it, as always.
		if (document.fullscreenEnabled) {
			this.on(fullScreenButton, 'click', () => {
				canvas.requestFullscreen?.().catch(() => {});
			});
		} else {
			fullScreenButton.hidden = true;
		}

		choosePreset(preset);
		this.#update();
	}

	get visibilityTarget() {
		return this.parts.canvas;
	}

	reducedMotionChanged() {
		this.#update();
	}
}
