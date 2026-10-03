// ── Centering: account for exact header height ───────────────────────────────
const header = document.querySelector('#site-header');

function applyHeaderHeight() {
	document.documentElement.style.setProperty('--header-h', `${header.offsetHeight}px`);
}

applyHeaderHeight();
window.addEventListener('resize', applyHeaderHeight);

// ── Proximity lift animation ─────────────────────────────────────────────────
const emailEl = document.querySelector('#contact-email');
const letters = [...emailEl.querySelectorAll('.letter')];
const n = letters.length;
const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

// Per-letter color: blue → violet → pink across the full email
function indexColor(i) {
	const t = i / (n - 1);
	if (t < 0.5) {
		const u = t * 2;
		return [
			Math.round(0x3b + (0xa8 - 0x3b) * u),
			Math.round(0x82 + (0x55 - 0x82) * u),
			Math.round(0xf6 + (0xf7 - 0xf6) * u),
		];
	}

	const u = (t - 0.5) * 2;
	return [
		Math.round(0xa8 + (0xec - 0xa8) * u),
		Math.round(0x55 + (0x48 - 0x55) * u),
		Math.round(0xf7 + (0x99 - 0xf7) * u),
	];
}

const colors = letters.map((_, i) => indexColor(i));

// Cache rest-position centers once (after entrance animation settles)
let centers = [];

function cachePositions() {
	centers = letters.map(el => {
		const r = el.getBoundingClientRect();
		return {cx: r.left + r.width / 2, cy: r.top + r.height / 2};
	});
}

// Cache after entrance animation (800ms + 200ms delay = ~1s)
setTimeout(cachePositions, 1000);
window.addEventListener('resize', cachePositions);

const RADIUS = 155;
const MAX_LIFT = 22;
const MAX_SCALE = 0.8;

let raf = 0;

// ── Rainbow mode ──────────────────────────────────────────────────────────────
let rainbowActive = false;
let rainbowRaf = 0;

function rainbowTick(timestamp) {
	const t = timestamp / 1000;
	for (let i = 0; i < n; i++) {
		const hue = (t * 60 + i * (360 / n)) % 360;
		const el = letters[i];
		el.style.color = `hsl(${hue}deg 100% 65%)`;
		el.style.textShadow = `0 0 20px hsl(${hue}deg 100% 65% / 0.65), 0 0 44px hsl(${hue}deg 100% 65% / 0.3)`;
	}

	rainbowRaf = requestAnimationFrame(rainbowTick);
}

function startRainbow() {
	if (rainbowActive) return;
	rainbowActive = true;
	rainbowRaf = requestAnimationFrame(rainbowTick);
}

function stopRainbow() {
	rainbowActive = false;
	cancelAnimationFrame(rainbowRaf);
	for (const el of letters) {
		el.style.color = '';
		el.style.textShadow = '';
	}
}

// ── 3D tilt ──────────────────────────────────────────────────────────────────
let tiltX = 0, tiltY = 0;
let tiltTX = 0, tiltTY = 0;
let tiltRaf = 0;

function tiltTick() {
	tiltX += (tiltTX - tiltX) * 0.09;
	tiltY += (tiltTY - tiltY) * 0.09;
	emailEl.style.transform = `rotateX(${tiltX}deg) rotateY(${tiltY}deg)`;
	const settling = Math.abs(tiltTX - tiltX) < 0.02 && Math.abs(tiltTY - tiltY) < 0.02;
	if (!settling) tiltRaf = requestAnimationFrame(tiltTick);
	else emailEl.style.transform = tiltTX === 0 ? '' : emailEl.style.transform;
}

function startTilt() {
	cancelAnimationFrame(tiltRaf);
	tiltRaf = requestAnimationFrame(tiltTick);
}

function updateTilt(mx, my) {
	const rect = emailEl.getBoundingClientRect();
	const cx = rect.left + rect.width / 2;
	const cy = rect.top + rect.height / 2;
	const dx = (mx - cx) / (rect.width * 0.6);
	const dy = (my - cy) / (rect.height * 3);
	tiltTY = Math.max(-10, Math.min(10, dx * 14));
	tiltTX = Math.max(-6, Math.min(6, dy * -10));
	startTilt();
}

function resetTilt() {
	tiltTX = 0;
	tiltTY = 0;
	startTilt();
}

// ─────────────────────────────────────────────────────────────────────────────

function update(mx, my) {
	// Raw proximity per letter
	const raw = new Float32Array(n);
	for (let i = 0; i < n; i++) {
		const {cx, cy} = centers[i];
		const d = Math.hypot(mx - cx, my - cy);
		const r = Math.max(0, 1 - d / RADIUS);
		raw[i] = r * r; // quadratic: smoother falloff at edges
	}

	// Propagate to neighbors (creates wave/ripple through text)
	const strengths = new Float32Array(raw);
	for (let i = 0; i < n; i++) {
		if (raw[i] < 0.01) continue;
		const s = raw[i];
		if (i > 0) strengths[i - 1] = Math.max(strengths[i - 1], s * 0.55);
		if (i < n - 1) strengths[i + 1] = Math.max(strengths[i + 1], s * 0.55);
		if (i > 1) strengths[i - 2] = Math.max(strengths[i - 2], s * 0.28);
		if (i < n - 2) strengths[i + 2] = Math.max(strengths[i + 2], s * 0.28);
		if (i > 2) strengths[i - 3] = Math.max(strengths[i - 3], s * 0.1);
		if (i < n - 3) strengths[i + 3] = Math.max(strengths[i + 3], s * 0.1);
	}

	for (let i = 0; i < n; i++) {
		const s = strengths[i];
		const el = letters[i];
		if (s > 0.005) {
			const lift = s * MAX_LIFT;
			const scale = 1 + s * MAX_SCALE;
			const z = s * 55;
			el.classList.remove('leaving');
			el.style.transform = `translateY(${-lift}px) scale(${scale}) translateZ(${z}px)`;
			if (!rainbowActive) {
				const [r, g, b] = colors[i];
				const glow = s * 26;
				el.style.color = `rgb(${r},${g},${b})`;
				el.style.textShadow = `0 0 ${glow}px rgba(${r},${g},${b},0.65), 0 0 ${glow * 2.2}px rgba(${r},${g},${b},0.3)`;
			}
		} else {
			el.classList.add('leaving');
			el.style.transform = '';
			if (!rainbowActive) {
				el.style.color = '';
				el.style.textShadow = '';
			}
		}
	}
}

if (!reducedMotion) {
	document.addEventListener('mousemove', (e) => {
		startRainbow();
		cancelAnimationFrame(raf);
		raf = requestAnimationFrame(() => update(e.clientX, e.clientY));
		updateTilt(e.clientX, e.clientY);
	});

	document.addEventListener('mouseleave', () => {
		stopRainbow();
		cancelAnimationFrame(raf);
		raf = requestAnimationFrame(() => update(-9999, -9999));
		resetTilt();
	});

	if (window.matchMedia('(hover: none)').matches) {
		startRainbow();
	}
}

// ── Sparkle burst on click ───────────────────────────────────────────────────
emailEl.addEventListener('click', (e) => {
	for (let i = 0; i < 26; i++) {
		const dot = document.createElement('div');
		const angle = (i / 26) * Math.PI * 2 + Math.random() * 0.35;
		const dist = 55 + Math.random() * 110;
		const size = 4 + Math.random() * 8;
		const [r, g, b] = colors[Math.floor(Math.random() * n)];
		const color = `rgb(${r},${g},${b})`;

		dot.style.cssText = `
			position:fixed;left:${e.clientX}px;top:${e.clientY}px;
			width:${size}px;height:${size}px;border-radius:50%;
			background:${color};box-shadow:0 0 ${size * 2}px ${color};
			pointer-events:none;z-index:9999;
			transform:translate(-50%,-50%);
			transition:transform 0.75s cubic-bezier(0.22,1,0.36,1),opacity 0.75s ease;
		`;
		document.body.appendChild(dot);
		dot.getBoundingClientRect();
		dot.style.transform = `translate(calc(-50% + ${Math.cos(angle) * dist}px),calc(-50% + ${Math.sin(angle) * dist}px))`;
		dot.style.opacity = '0';
		setTimeout(() => dot.remove(), 800);
	}
});

// ── Forward search params ────────────────────────────────────────────────────
const params = new URLSearchParams(location.search);
const url = new URL(emailEl.href);
if (params.has('subject')) url.searchParams.set('subject', params.get('subject'));
if (params.has('body')) url.searchParams.set('body', params.get('body'));
emailEl.href = url.toString();

const cleanUrl = new URL(window.location.href);
cleanUrl.searchParams.delete('subject');
cleanUrl.searchParams.delete('body');
window.history.replaceState({}, '', cleanUrl);
