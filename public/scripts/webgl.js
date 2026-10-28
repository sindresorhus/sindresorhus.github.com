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
