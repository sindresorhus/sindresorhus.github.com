/* eslint-env browser */
(function () {
	'use strict';

	function injectScript(src, cb) {
		const script = document.createElement('script');
		script.async = true;
		script.src = src;
		script.addEventListener('load', cb);
		document.head.appendChild(script);
	}

	window.handleRssPost = function (data) {
		var item = data.query.results.rss.channel.item;
		var link = document.createElement('a');
		link.href = item.link.replace(/\?source=rss.*$/, '');
		link.textContent = item.title;
		var container = document.querySelector('#latest-blog-post');
		container.appendChild(link);
		container.classList.add('visible');
	};

	// Burger menu toggle
	var burger = document.querySelector('.nav-toggle');
	var menu = document.querySelector('.nav-menu');
	burger.addEventListener('click', function () {
		burger.classList.toggle('is-active');
		menu.classList.toggle('is-active');
	});

	// Unicorn easteregg
	document.querySelector('#unicorn-btn').addEventListener('click', function (event) {
		event.preventDefault();
		injectScript('cornify.js', function () {
			cornify();
			cornify();
			setInterval(cornify, 1000);
		});
	});

	// Smooth anchor scroll
	new AnchorScroller();
})();

(function () {
	'use strict';

	function hideScrollHint() {
		if (window.scrollY > 100) {
			document.removeEventListener('scroll', hideScrollHint);
			document.querySelector('#scroll-hint').classList.add('hidden');
		}
	}

	document.addEventListener('scroll', hideScrollHint, {passive: true});
})();
