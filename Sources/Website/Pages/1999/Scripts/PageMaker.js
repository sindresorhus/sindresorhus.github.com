// The home page maker on the 1999 page: it writes the page of the visitor as the HTML of 1999, with `<marquee>`, `<bgsound>`, and a WordArt title, and shows it in a sandboxed frame, so nothing in it can run. The GIFs have full addresses, so the saved file shows them too.
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));

// Sets up the page maker, with the element for its helpers, like `say()`, `on()`, and `timeout()`, and its parts.
const setUpPageMaker = (pageMaker, {form, title: titleInput, wordArt: wordArtSelect, background: backgroundSelect, about: aboutInput, marquee: marqueeInput, tune: tuneSelect, counter: counterCheckbox, construction: constructionCheckbox, gifs: gifChoices, preview, viewSource: viewSourceButton, save: saveButton, publish: publishButton, source, log}) => {
	// The backgrounds, each with the neighborhood of GeoCities that fits it.
	const backgrounds = {
		'Starry Night': {css: 'background: #000033 radial-gradient(1px 1px at 10px 10px, #fff, transparent) 0 0 / 40px 40px; color: #ffff00;', link: '#00ffff', neighborhood: 'Area51/Nebula'},
		Clouds: {css: 'background: linear-gradient(#5aa9ff, #ffffff); color: #000080;', link: '#cc0000', neighborhood: 'EnchantedForest/Glade'},
		'Hot Pink': {css: 'background: #ff66cc; color: #000000;', link: '#0000ff', neighborhood: 'Hollywood/Hills'},
		Flames: {css: 'background: linear-gradient(to top, #ff3300, #000000 70%); color: #ffcc00;', link: '#ffffff', neighborhood: 'SunsetStrip/Stage'},
		Matrix: {css: 'background: #000000; color: #00ff00; font-family: "Courier New", monospace;', link: '#99ff99', neighborhood: 'SiliconValley/Lab'},
		Bricks: {css: 'background: #993322 repeating-linear-gradient(0deg, #ccbbaa 0 2px, transparent 2px 20px); color: #ffffff;', link: '#ffff00', neighborhood: 'SoHo/Lofts'},
	};

	const wordArts = {
		Rainbow: 'background: linear-gradient(90deg, #f33, #f90, #fe0, #3c3, #39f, #c6f); -webkit-background-clip: text; background-clip: text; color: transparent; filter: drop-shadow(3px 3px 0 #666);',
		Fire: 'background: linear-gradient(#ff0, #f60, #c00); -webkit-background-clip: text; background-clip: text; color: transparent; filter: drop-shadow(2px 2px 0 #300);',
		Chrome: 'background: linear-gradient(#fff, #888 50%, #333 51%, #ccc); -webkit-background-clip: text; background-clip: text; color: transparent; filter: drop-shadow(2px 2px 0 #000);',
		Slime: 'color: #7cfc00; text-shadow: 0 3px 0 #2e8b00, 0 6px 0 #1a5200;',
	};

	// The hit counter of the new page, the same in the preview and the saved file.
	const visitor = String(randomInteger(1, 9999)).padStart(6, '0');

	const escapeHTML = text => text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
	const absolute = path => new URL(path, location.href).href;

	// The page as HTML. The preview leaves out the motion for visitors who prefer reduced motion, with still GIFs and a marquee that stands still, but the saved page has it all.
	const makePage = ({isPreview = false} = {}) => {
		const isStill = isPreview && pageMaker.reducedMotion;
		const background = backgrounds[backgroundSelect.value];
		const title = escapeHTML(titleInput.value.trim() || 'My Home Page');
		const marquee = escapeHTML(marqueeInput.value.trim());
		const about = escapeHTML(aboutInput.value.trim()).replaceAll('\n', '<br>');
		const tune = tuneSelect.value;
		const gifPath = input => absolute(isStill ? input.dataset.pageMakerStill : input.dataset.pageMakerGif);
		const gifs = [...gifChoices.querySelectorAll('[data-page-maker-gif]:checked')]
			.map(input => `<img src="${gifPath(input)}" alt="${escapeHTML(input.value)}">`)
			.join('\n');

		return `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta name="GENERATOR" content="Microsoft FrontPage Express 2.0">
<title>${title}</title>
<style>
body { ${background.css} font-family: "Comic Sans MS", "Comic Sans", cursive; text-align: center; margin: 16px; }
a { color: ${background.link}; }
h1 { font-family: Impact, "Arial Black", sans-serif; font-size: 40px; margin: 8px 0; transform: rotate(-3deg); ${wordArts[wordArtSelect.value]} }
img { vertical-align: middle; margin: 4px; max-width: 120px; }
marquee, .marquee { font-weight: bold; border: 3px ridge #808080; background: #000080; color: #ffffff; padding: 2px; }
.counter { font-family: "Courier New", monospace; background: #000; color: #0f0; padding: 1px 4px; letter-spacing: 2px; }
.blink { color: #ff0000; font-weight: bold;${isStill ? '' : ' animation: blink 1s steps(1, end) infinite;'} }
@keyframes blink { 50% { visibility: hidden; } }
</style>
</head>
<body>
${tune === 'None' ? '' : `<bgsound src="${tune}" loop="infinite">\n`}<h1>${title}</h1>
${marquee ? (isStill ? `<p class="marquee">${marquee}</p>` : `<marquee scrollamount="4">${marquee}</marquee>`) : ''}
<p>${gifs}</p>
<p>${about}</p>
${constructionCheckbox.checked ? `<p><img src="${gifPath(constructionCheckbox)}" alt="Under construction"> <span class="blink">This page is under construction!</span></p>\n` : ''}${counterCheckbox.checked ? `<p>You are visitor number <span class="counter">${visitor}</span></p>\n` : ''}${tune === 'None' ? '' : `<p><small>&#9835; Now playing: ${tune} &#9835;</small></p>\n`}<hr>
<p><small>Made with FrontPage Express &middot; Best viewed with Netscape Navigator 4 at 800&times;600 &middot; Sign my guestbook!</small></p>
</body>
</html>
`;
	};

	let previewTimer;
	const updatePreview = () => {
		previewTimer?.cancel();
		previewTimer = pageMaker.timeout(150, () => {
			preview.srcdoc = makePage({isPreview: true});
			if (!source.hidden) {
				source.value = makePage();
			}
		});
	};

	pageMaker.on(form, 'input', updatePreview);
	pageMaker.on(form, 'submit', event => {
		event.preventDefault();
	});

	pageMaker.on(viewSourceButton, 'click', () => {
		const isOpening = source.hidden;
		source.hidden = !isOpening;
		viewSourceButton.setAttribute('aria-expanded', String(isOpening));
		viewSourceButton.textContent = isOpening ? 'Hide Source' : 'View Source';
		if (isOpening) {
			source.value = makePage();
		}
	});

	pageMaker.on(saveButton, 'click', () => {
		const url = URL.createObjectURL(new Blob([makePage()], {type: 'text/html'}));
		const link = document.createElement('a');
		link.href = url;
		link.download = 'index.html';
		link.click();
		// A plain timer, so the address of the file is freed also when the element is removed first.
		setTimeout(() => {
			URL.revokeObjectURL(url);
		}, 1000);
		pageMaker.say('Saved as index.html. Open it in your browser, or put it on a floppy!');
	});

	let isPublishing = false;
	pageMaker.on(publishButton, 'click', async () => {
		if (isPublishing) {
			return;
		}

		isPublishing = true;
		const html = makePage();
		const bytes = new Blob([html]).size;
		const address = `http://www.geocities.com/${backgrounds[backgroundSelect.value].neighborhood}/${randomInteger(1000, 9999)}/`;
		log.hidden = false;
		log.textContent = '';
		pageMaker.say('Publishing to GeoCities…');
		const lines = [
			[400, 'Connecting to ftp.geocities.com…'],
			[900, '220 GeoCities FTP server ready.'],
			[300, 'USER sindre'],
			[400, '331 Password required for sindre.'],
			[300, 'PASS ********'],
			[700, '230 User sindre logged in. Welcome home, homesteader!'],
			[400, 'TYPE A'],
			[300, `STOR index.html (${bytes.toLocaleString('en-US')} bytes)`],
			[1600, `Sending at 2.1 KB/s… ${'#'.repeat(20)}`],
			[400, '226 Transfer complete.'],
			[300, 'QUIT'],
			[300, '221 Goodbye. Come back soon!'],
		];
		for (const [delay, line] of lines) {
			await pageMaker.wait(delay);
			log.textContent += `${line}\n`;
		}

		pageMaker.say(`Your page is on the World Wide Web! Its address: ${address} Tell all your friends! (GeoCities closed in 2009, so it lives in your heart now.)`);
		pageMaker.cheer();
		isPublishing = false;
	});

	updatePreview();

	return {
		updatePreview,
	};
};

export default class extends GeoCitiesElement {
	#pageMaker;

	connected() {
		this.#pageMaker = setUpPageMaker(this, this.parts);
	}

	// The preview leaves out the motion for visitors who prefer reduced motion.
	reducedMotionChanged() {
		this.#pageMaker.updatePreview();
	}
}
