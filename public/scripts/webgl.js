// The WebGL setup of the canvases that draw one shader over their whole area, like the glass of the apps page and the galaxy of the home page.

// Two triangles that cover the canvas, from the corners in `position`.
const vertexShader = `
	attribute vec2 position;

	void main() {
		gl_Position = vec4(position, 0.0, 1.0);
	}
`;

/**
Draws the fragment shader over the whole canvas of the WebGL context, with `gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)`. It compiles and links the shaders, gives them the corners of the canvas, and calls `setUp(program)`, where the caller gets the locations of its uniforms and sets its other state, like blending. Returns `false` when the shaders do not compile on the device, like one without high precision.

The GPU can lose the canvas, like after the device sleeps, which removes the program and all the state. Then it tells the browser that the page sets up the canvas again, so the browser gives it back when it can, and then it sets up everything again and calls `setUp(program)` again. The caller stops drawing on `webglcontextlost`, and starts again on `webglcontextrestored`, as its listener runs after the setup. If the shaders do not compile again, `setUp` is not called, so the caller can tell that the canvas is not set up, and stays as it is.
*/
export function startShader(gl, {fragment, setUp}) {
	const start = () => {
		const program = gl.createProgram();

		for (const [type, source] of [[gl.VERTEX_SHADER, vertexShader], [gl.FRAGMENT_SHADER, fragment]]) {
			const shader = gl.createShader(type);
			gl.shaderSource(shader, source);
			gl.compileShader(shader);
			gl.attachShader(program, shader);
		}

		gl.linkProgram(program);

		if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
			return false;
		}

		gl.useProgram(program);
		gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
		const position = gl.getAttribLocation(program, 'position');
		gl.enableVertexAttribArray(position);
		gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);

		setUp(program);
		return true;
	};

	if (!start()) {
		return false;
	}

	gl.canvas.addEventListener('webglcontextlost', event => {
		event.preventDefault();
	});

	gl.canvas.addEventListener('webglcontextrestored', start);

	return true;
}

/**
Calls `frame(time)` at most 30 times a second while the canvas is on screen, the tab is visible, and `canRun()` is true, like when the shaders are set up. The time is in seconds from `startTime`, and it does not move while the loop is paused, so the drawing continues where it stopped. A long gap, like after a stall, counts as 100 ms. Call `update()` after a change that `canRun()` reads, like a lost canvas. Returns `update`, the `time`, and whether it `isRunning`.
*/
export function shaderLoop(canvas, {frame, canRun, startTime = 0}) {
	let time = startTime;
	let lastFrameTime = 0;
	let animationFrame;
	let isOnScreen = false;

	const animate = now => {
		animationFrame = requestAnimationFrame(animate);

		if (now - lastFrameTime < 1000 / 31) {
			return;
		}

		time += Math.min(now - lastFrameTime, 100) / 1000;
		lastFrameTime = now;
		frame(time);
	};

	const update = () => {
		const shouldRun = isOnScreen && !document.hidden && canRun();

		if (shouldRun === (animationFrame !== undefined)) {
			return;
		}

		if (shouldRun) {
			lastFrameTime = performance.now();
			animationFrame = requestAnimationFrame(animate);
		} else {
			cancelAnimationFrame(animationFrame);
			animationFrame = undefined;
		}
	};

	new IntersectionObserver(([entry]) => {
		isOnScreen = entry.isIntersecting;
		update();
	}).observe(canvas);

	document.addEventListener('visibilitychange', update);

	return {
		update,
		get time() {
			return time;
		},
		get isRunning() {
			return animationFrame !== undefined;
		},
	};
}
