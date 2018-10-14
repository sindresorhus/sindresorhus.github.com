// Adapted from http://www.cornify.com/js/cornify.js
(() => {
	'use strict';

	let cornify_count = 0;

	var cornify_add = function () {
		cornify_count += 1;
		const cornify_url = 'https://www.cornify.com/';
		const div = document.createElement('div');
		div.style.position = 'fixed';

		document.title = '✨🦄✨';

		let numType = 'px';
		const heightRandom = Math.random() * 0.75;
		let windowHeight = 768;
		let windowWidth = 1024;
		let height = 0;
		const width = 0;
		const de = document.documentElement;
		if (typeof (window.innerHeight) === 'number') {
			windowHeight = window.innerHeight;
			windowWidth = window.innerWidth;
		} else if (de && de.clientHeight) {
			windowHeight = de.clientHeight;
			windowWidth = de.clientWidth;
		} else {
			numType = '%';
			height = Math.round(height * 100) + '%';
		}

		div.addEventListener('click', cornify_add);
		div.style.zIndex = 10;
		div.style.outline = 0;

		if (cornify_count === 15) {
			div.style.top = Math.max(0, Math.round((windowHeight - 530) / 2)) + 'px';
			div.style.left = Math.round((windowWidth - 530) / 2) + 'px';
			div.style.zIndex = 1000;
		} else {
			if (numType === 'px') {
				div.style.top = Math.round(windowHeight * heightRandom) + numType;
			} else {
				div.style.top = height;
			}
			div.style.left = Math.round(Math.random() * 90) + '%';
		}

		const img = document.createElement('img');
		const currentTime = new Date();
		let submitTime = currentTime.getTime();
		if (cornify_count === 15) {
			submitTime = 0;
		}
		img.setAttribute('src', `${cornify_url}getacorn.php?r=${submitTime}&url=${document.location.href}`);
		const ease = 'all .1s linear';
		div.style.WebkitTransition = ease;
		div.style.WebkitTransform = 'rotate(1deg) scale(1.01,1.01)';
		div.style.transition = 'all .1s linear';
		div.addEventListener('mouseover', function () {
			const size = 1 + Math.round(Math.random() * 10) / 100;
			const angle = Math.round(Math.random() * 20 - 10);
			const result = 'rotate(' + angle + 'deg) scale(' + size + ',' + size + ')';
			this.style.transform = result;
			this.style.WebkitTransform = result;
		});
		div.addEventListener('mouseout', function () {
			const size = 0.9 + Math.round(Math.random() * 10) / 100;
			const angle = Math.round(Math.random() * 6 - 3);
			const result = 'rotate(' + angle + 'deg) scale(' + size + ',' + size + ')';
			this.style.transform = result;
			this.style.WebkitTransform = result;
		});
		const body = document.getElementsByTagName('body')[0];
		body.appendChild(div);
		div.appendChild(img);

		// Add stylesheet
		if (cornify_count === 5) {
			const cssExisting = document.getElementById('__cornify_css');
			if (!cssExisting) {
				const head = document.getElementsByTagName('head')[0];
				const css = document.createElement('link');
				css.id = '__cornify_css';
				css.type = 'text/css';
				css.rel = 'stylesheet';
				css.href = 'https://www.cornify.com/css/cornify.css';
				css.media = 'screen';
				head.appendChild(css);
			}
			cornify_replace();
		}

		cornify_updatecount();
	};

	var cornify_updatecount = function () {
		var p = document.getElementById('cornifycount');
		if (p == null) {
			var p = document.createElement('p');
			p.id = 'cornifycount';
			p.style.position = 'fixed';
			p.style.bottom = '5px';
			p.style.left = '0px';
			p.style.right = '0px';
			p.style.zIndex = '1000000000';
			p.style.color = '#ff00ff';
			p.style.textAlign = 'center';
			p.style.fontSize = '24px';
			p.style.fontFamily = '\'Comic Sans MS\', \'Comic Sans\', \'Marker Felt\', serif';
			const body = document.getElementsByTagName('body')[0];
			body.appendChild(p);
		}
		if (cornify_count === 1) {
			p.innerHTML = `${cornify_count} UNICORN OR RAINBOW CREATED`;
		} else {
			p.innerHTML = `${cornify_count} UNICORNS &AMP; RAINBOWS CREATED`;
		}
		cornify_setcookie('cornify', String(cornify_count), 1000);
	};

	var cornify_setcookie = (name, value, days) => {
		const d = new Date();
		d.setTime(d.getTime() + (days * 24 * 60 * 60 * 1000));
		const expires = `expires=${d.toGMTString()}`;
		document.cookie = `${name}=${value}; ${expires}`;
	};

	const cornify_getcookie = function (cname) {
		const name = `${cname}=`;
		const ca = document.cookie.split(';');
		for (let i = 0; i < ca.length; i++) {
			const c = ca[i].trim();
			if (c.indexOf(name) === 0) {
				return c.substring(name.length, c.length);
			}
		}
		return '';
	};

	cornify_count = parseInt(cornify_getcookie('cornify'));
	if (isNaN(cornify_count)) {
		cornify_count = 0;
	}

	var cornify_replace = function () {
		let hc = 6;
		let hs;
		let h;
		let k;
		const words = ['Happy', 'Sparkly', 'Glittery', 'Fun', 'Magical', 'Lovely', 'Cute', 'Charming', 'Amazing', 'Wonderful'];
		while (hc >= 1) {
			hs = document.getElementsByTagName('h' + hc);
			for (k = 0; k < hs.length; k++) {
				h = hs[k];
				h.innerHTML = words[Math.floor(Math.random() * words.length)] + ' ' + h.innerHTML;
			}
			hc -= 1;
		}
	};

	window.cornify = cornify_add;
})();
