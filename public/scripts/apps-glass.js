// The liquid glass behind the title of the apps page, drawn with WebGL: soft fields in the colors of the featured apps, seen through slowly moving frosted glass. It draws one still frame for visitors who prefer reduced motion, and pauses while it is off screen or the tab is hidden. Without WebGL, the canvas keeps its still gradient (`AppsPage`).
const canvas = document.querySelector('#apps-glass');
const gl = canvas.getContext('webgl', {antialias: false, depth: false, powerPreference: 'low-power'});

const vertexShader = `
	attribute vec2 position;

	void main() {
		gl_Position = vec4(position, 0.0, 1.0);
	}
`;

const fragmentShader = `
	precision highp float;

	uniform vec2 resolution;
	uniform float time;
	uniform vec2 pointer;
	uniform float pointerStrength;
	uniform float isDark;
	uniform vec3 colors[5];

	float hash(vec2 point) {
		return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
	}

	float noise(vec2 point) {
		vec2 cell = floor(point);
		vec2 fraction = fract(point);
		vec2 curve = fraction * fraction * (3.0 - 2.0 * fraction);

		return mix(
			mix(hash(cell), hash(cell + vec2(1.0, 0.0)), curve.x),
			mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), curve.x),
			curve.y
		);
	}

	// The height of the glass: broad, slow swells.
	float surface(vec2 point) {
		return noise(point * 1.3 + vec2(time * 0.045, -time * 0.03)) * 0.65
			+ noise(point * 2.6 - vec2(time * 0.035, time * 0.05)) * 0.35;
	}

	void main() {
		vec2 uv = gl_FragCoord.xy / resolution;
		float aspect = resolution.x / resolution.y;
		vec2 point = vec2(uv.x * aspect, uv.y);

		// The slope of the glass bends the light that comes through it.
		float delta = 0.02;
		float height = surface(point);
		vec2 slope = vec2(surface(point + vec2(delta, 0.0)) - height, surface(point + vec2(0.0, delta)) - height) / delta;

		// The glass swells a little under the pointer, like a lens.
		vec2 toPointer = point - vec2(pointer.x * aspect, pointer.y);
		float lens = exp(-dot(toPointer, toPointer) * 6.0) * pointerStrength;
		slope += toPointer * lens * 2.5;

		vec2 refracted = point + slope * 0.14;

		// Soft fields of color that drift slowly. Where they overlap, their colors mix, and between them the page shows through.
		vec3 color = vec3(0.0);
		float weight = 0.0;
		float clear = 1.0;

		for (int index = 0; index < 5; index++) {
			float offset = float(index);
			vec2 center = vec2(
				(0.1 + offset * 0.2 + sin(time * (0.05 + offset * 0.011) + offset * 1.9) * 0.05) * aspect,
				0.5 + cos(time * (0.04 + offset * 0.009) + offset * 2.4) * 0.14
			);
			vec2 offsetFromCenter = (refracted - center) / vec2(min(aspect * 0.19, 0.9), 0.48);
			float field = exp(-dot(offsetFromCenter, offsetFromCenter));
			color += colors[index] * field;
			weight += field;
			clear *= 1.0 - field * 0.85;
		}

		// The glass fades out toward the sides and the bottom of the canvas. At the top, it continues behind the site header to the top of the page, but fainter, so the links of the header stay readable.
		float edge = (1.0 - smoothstep(0.55, 1.0, abs(uv.x * 2.0 - 1.0))) * smoothstep(0.0, 0.35, uv.y) * mix(1.0, 0.4, smoothstep(0.7, 1.0, uv.y));

		color /= max(weight, 0.0001);
		float alpha = (1.0 - clear) * edge;

		// A soft highlight where the glass faces the light, which comes from above, or from the pointer.
		vec2 light = normalize(mix(vec2(-0.4, 1.0), -toPointer + vec2(0.0001), pointerStrength * 0.6));
		float highlight = pow(max(dot(normalize(slope + vec2(0.0001)), light), 0.0), 4.0) * smoothstep(0.4, 1.6, length(slope)) * alpha;

		if (isDark > 0.5) {
			color = mix(color * 1.15, vec3(1.0), highlight * 0.5);
			alpha = alpha * 0.55 + highlight * 0.1;
		} else {
			// Lighter and more see-through, like frosted glass in daylight.
			color = mix(color, vec3(1.0), 0.2 + highlight * 0.5);
			alpha = alpha * 0.45 + highlight * 0.08;
		}

		// A faint grain, like frosted glass, which also hides banding.
		alpha *= 1.0 + (hash(gl_FragCoord.xy + fract(time)) - 0.5) * 0.06;

		alpha = clamp(alpha, 0.0, 1.0);
		gl_FragColor = vec4(min(color, 1.0) * alpha, alpha);
	}
`;

// The shader program, or `undefined` when the shaders do not compile on the device, like one without high precision. Then the canvas keeps its still gradient.
const createProgram = () => {
	const program = gl.createProgram();

	for (const [type, source] of [[gl.VERTEX_SHADER, vertexShader], [gl.FRAGMENT_SHADER, fragmentShader]]) {
		const shader = gl.createShader(type);
		gl.shaderSource(shader, source);
		gl.compileShader(shader);
		gl.attachShader(program, shader);
	}

	gl.linkProgram(program);

	return gl.getProgramParameter(program, gl.LINK_STATUS) ? program : undefined;
};

const program = gl ? createProgram() : undefined;

if (program) {
	gl.useProgram(program);

	// Two triangles that cover the canvas.
	gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
	const position = gl.getAttribLocation(program, 'position');
	gl.enableVertexAttribArray(position);
	gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);

	const uniforms = Object.fromEntries(['resolution', 'time', 'pointer', 'pointerStrength', 'isDark', 'colors'].map(name => [name, gl.getUniformLocation(program, name)]));

	// The colors are custom properties of the canvas, like `--glass-color-1: #527cea`. A 2D canvas turns each into red, green, and blue, whatever the CSS color is.
	const style = getComputedStyle(canvas);
	const colorContext = new OffscreenCanvas(1, 1).getContext('2d', {willReadFrequently: true});
	const colors = [1, 2, 3, 4, 5].flatMap(index => {
		colorContext.clearRect(0, 0, 1, 1);
		colorContext.fillStyle = style.getPropertyValue(`--glass-color-${index}`).trim() || 'transparent';
		colorContext.fillRect(0, 0, 1, 1);
		return [...colorContext.getImageData(0, 0, 1, 1).data.slice(0, 3)].map(value => value / 255);
	});
	gl.uniform3fv(uniforms.colors, colors);

	// The glass replaces the still gradient. The first frame is drawn when the size of the canvas is known, before the page shows.
	canvas.dataset.state = 'drawing';

	const darkQuery = matchMedia('(prefers-color-scheme: dark)');
	const reducedMotionQuery = matchMedia('(prefers-reduced-motion: reduce)');
	const finePointerQuery = matchMedia('(hover: hover) and (pointer: fine)');

	// The glass is soft, so half the CSS pixels in each direction is enough, and it saves battery. The browser scales it up smoothly.
	const scale = 0.5;

	const resize = () => {
		canvas.width = Math.max(1, Math.round(canvas.clientWidth * scale));
		canvas.height = Math.max(1, Math.round(canvas.clientHeight * scale));
		gl.viewport(0, 0, canvas.width, canvas.height);
	};

	// The pointer, in the coordinates of the canvas, from 0 to 1 with the origin at the bottom left. It eases toward where the pointer is.
	const pointer = {x: 0.5, y: 0.5, strength: 0};
	const targetPointer = {x: 0.5, y: 0.5, strength: 0};

	const header = canvas.parentElement;

	header.addEventListener('pointermove', event => {
		if (!finePointerQuery.matches) {
			return;
		}

		const rect = canvas.getBoundingClientRect();
		targetPointer.x = (event.clientX - rect.left) / rect.width;
		targetPointer.y = 1 - ((event.clientY - rect.top) / rect.height);
		targetPointer.strength = 1;
	});

	header.addEventListener('pointerleave', () => {
		targetPointer.strength = 0;
	});

	// A moment in the drift that looks good as a still frame.
	const stillTime = 40;

	// The time does not move while the glass is paused, so it continues where it stopped.
	let time = stillTime;
	let lastFrameTime = 0;

	const draw = () => {
		gl.uniform2f(uniforms.resolution, canvas.width, canvas.height);
		gl.uniform1f(uniforms.time, time);
		gl.uniform2f(uniforms.pointer, pointer.x, pointer.y);
		gl.uniform1f(uniforms.pointerStrength, pointer.strength);
		gl.uniform1f(uniforms.isDark, darkQuery.matches ? 1 : 0);
		gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
	};

	let frame = 0;
	let isRunning = false;
	let isOnScreen = false;

	// At most 30 frames a second, as the glass moves slowly.
	const animate = now => {
		frame = requestAnimationFrame(animate);

		if (now - lastFrameTime < 1000 / 31) {
			return;
		}

		// A long gap, like after a pause, does not jump ahead.
		time += Math.min(now - lastFrameTime, 100) / 1000;
		lastFrameTime = now;

		for (const key of ['x', 'y', 'strength']) {
			pointer[key] += (targetPointer[key] - pointer[key]) * 0.06;
		}

		draw();
	};

	const update = () => {
		const shouldRun = isOnScreen && !document.hidden && !reducedMotionQuery.matches;

		if (shouldRun === isRunning) {
			return;
		}

		isRunning = shouldRun;

		if (shouldRun) {
			lastFrameTime = performance.now();
			frame = requestAnimationFrame(animate);
		} else {
			cancelAnimationFrame(frame);
		}
	};

	new IntersectionObserver(([entry]) => {
		isOnScreen = entry.isIntersecting;
		update();
	}).observe(canvas);

	new ResizeObserver(() => {
		resize();
		draw();
	}).observe(canvas);

	document.addEventListener('visibilitychange', update);

	// A still frame in the new colors, or with the time where it is now.
	darkQuery.addEventListener('change', draw);

	// With reduced motion, the glass shows the same still frame as when the page loads with it, without the light of the pointer.
	reducedMotionQuery.addEventListener('change', () => {
		if (reducedMotionQuery.matches) {
			time = stillTime;
			pointer.strength = 0;
			targetPointer.strength = 0;
		}

		update();
		draw();
	});
}
