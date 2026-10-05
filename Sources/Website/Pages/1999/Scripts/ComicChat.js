// Comic Chat ’99 on the 1999 page: each line becomes a balloon in a panel of a comic strip, and the characters act it out with the rules of Microsoft Comic Chat (Kurlander, Skelly, and Salesin, SIGGRAPH 1996): greetings wave, “I” points to yourself, “you” points to the other, LOL laughs, capitals and “!!!” shout, and smileys set the face. The emotion wheel overrides the face. A panel holds two balloons, and a new panel starts when it is full or the speaker already spoke in it.

const randomItem = items => items[Math.floor(Math.random() * items.length)];

const people = {
	kid: {name: 'Propeller Kid', skin: '#ffd8b0', shirt: '#ff3333', pants: '#3344aa', look: 'propeller'},
	dude: {name: 'Cool Dude', skin: '#d99a66', shirt: '#22aa44', pants: '#222222', look: 'shades'},
	mormor: {name: 'Mormor', skin: '#ffe2cc', shirt: '#9966cc', pants: '#663399', look: 'bun'},
	alien: {name: 'The alien from Area 51', skin: '#88ee66', shirt: '#9999aa', pants: '#555566', look: 'antennae'},
	sindre: {name: 'Sindre', skin: '#ffe0c0', shirt: '#0099bb', pants: '#334455', look: 'blond'},
	mom: {name: 'Mom', skin: '#ffd8c0', shirt: '#cc3366', pants: '#552233', look: 'curls'},
	rocky: {name: 'Rocky the pet rock', look: 'rock'},
};

// The arms of each gesture, from the shoulder through the elbow to the hand, for a character that faces right.
const arms = {
	neutral: [[34, 70, 28, 94, 30, 112], [66, 70, 72, 94, 70, 112]],
	hips: [[34, 70, 18, 88, 32, 100], [66, 70, 82, 88, 68, 100]],
	wave: [[34, 70, 28, 94, 30, 112], [66, 70, 84, 56, 86, 30]],
	pointSelf: [[34, 70, 28, 94, 30, 112], [66, 70, 72, 92, 54, 84]],
	pointOther: [[34, 70, 28, 94, 30, 112], [66, 70, 86, 70, 99, 64]],
	shout: [[34, 70, 20, 52, 16, 30], [66, 70, 80, 52, 84, 30]],
	laugh: [[34, 70, 30, 98, 46, 102], [66, 70, 72, 98, 56, 102]],
	shrug: [[34, 70, 18, 84, 10, 70], [66, 70, 82, 84, 90, 70]],
	scared: [[34, 70, 20, 60, 24, 44], [66, 70, 80, 60, 78, 44]],
	think: [[34, 70, 28, 94, 30, 112], [66, 70, 80, 86, 64, 58]],
};

const tilts = {laugh: -10, shout: -4, shrug: 6, think: 8};

// The face of each expression, with eyes, brows, and mouth, for a character that faces right.
const faces = {
	neutral: '<circle cx="51" cy="36" r="2.6"/><circle cx="63" cy="36" r="2.6"/><path d="M54 49 L64 48" fill="none" stroke="#000" stroke-width="2.5" stroke-linecap="round"/>',
	happy: '<circle cx="51" cy="36" r="2.6"/><circle cx="63" cy="36" r="2.6"/><path d="M51 46 Q57 54 65 46" fill="none" stroke="#000" stroke-width="2.5" stroke-linecap="round"/>',
	laughing: '<path d="M47 37 Q51 32 55 37 M59 37 Q63 32 67 37" fill="none" stroke="#000" stroke-width="2.5" stroke-linecap="round"/><path d="M50 45 Q58 60 66 45 Z" fill="#992222" stroke="#000" stroke-width="2"/>',
	coy: '<path d="M47 36 L55 36" stroke="#000" stroke-width="2.5" stroke-linecap="round"/><circle cx="63" cy="36" r="2.6"/><path d="M55 47 Q59 51 64 47" fill="none" stroke="#000" stroke-width="2.5" stroke-linecap="round"/><circle cx="66" cy="43" r="3.5" fill="#ff8899" opacity="0.7"/>',
	bored: '<path d="M47 37 L55 37 M59 37 L67 37" stroke="#000" stroke-width="2.5" stroke-linecap="round"/><path d="M47 34 L55 35 M59 35 L67 34" stroke="#000" stroke-width="1.5"/><path d="M54 50 L63 50" stroke="#000" stroke-width="2.5" stroke-linecap="round"/>',
	scared: '<circle cx="51" cy="36" r="4.5" fill="#fff" stroke="#000" stroke-width="1.5"/><circle cx="63" cy="36" r="4.5" fill="#fff" stroke="#000" stroke-width="1.5"/><circle cx="52" cy="36" r="1.6"/><circle cx="64" cy="36" r="1.6"/><path d="M46 28 Q51 25 55 28 M59 28 Q63 25 68 28" fill="none" stroke="#000" stroke-width="2"/><ellipse cx="58" cy="50" rx="3" ry="4" fill="#441111"/><path d="M72 30 Q75 36 72 38 Q69 36 72 30" fill="#66ccff" stroke="#000" stroke-width="1"/>',
	sad: '<circle cx="51" cy="37" r="2.6"/><circle cx="63" cy="37" r="2.6"/><path d="M46 31 L54 29 M60 29 L68 31" stroke="#000" stroke-width="2" stroke-linecap="round"/><path d="M51 52 Q57 45 65 52" fill="none" stroke="#000" stroke-width="2.5" stroke-linecap="round"/>',
	angry: '<circle cx="51" cy="37" r="2.6"/><circle cx="63" cy="37" r="2.6"/><path d="M45 28 L55 33 M59 33 L69 28" stroke="#000" stroke-width="2.5" stroke-linecap="round"/><path d="M51 51 Q57 46 65 51" fill="none" stroke="#000" stroke-width="2.5" stroke-linecap="round"/>',
	shouting: '<circle cx="51" cy="35" r="2.6"/><circle cx="63" cy="35" r="2.6"/><path d="M46 27 Q51 24 55 27 M59 27 Q63 24 68 27" fill="none" stroke="#000" stroke-width="2"/><ellipse cx="58" cy="49" rx="6" ry="7" fill="#992222" stroke="#000" stroke-width="2"/>',
};

// The hair, the hats, and the glasses of each character, drawn over the head.
const looks = {
	propeller: '<path d="M30 32 Q52 2 74 32 Z" fill="#3366ff" stroke="#000" stroke-width="2"/><path d="M52 4 L52 16 M52 32 L52 6" stroke="#ffcc00" stroke-width="4"/><path d="M38 5 L66 5" stroke="#ff3333" stroke-width="4" stroke-linecap="round"/><circle cx="52" cy="5" r="2.5" fill="#000"/>',
	shades: '<path d="M30 30 L34 14 L40 24 L46 10 L52 22 L58 9 L64 22 L70 13 L74 30 Q52 20 30 30 Z" fill="#332211" stroke="#000" stroke-width="2"/><path d="M45 32 H56 V39 Q50 42 45 39 Z M59 32 H70 V39 Q64 42 59 39 Z M56 34 H59" fill="#111" stroke="#000" stroke-width="1.5"/>',
	bun: '<circle cx="36" cy="18" r="9" fill="#cccccc" stroke="#000" stroke-width="2"/><path d="M30 34 Q34 12 54 14 Q74 14 74 30 Q60 22 30 34 Z" fill="#dddddd" stroke="#000" stroke-width="2"/><circle cx="51" cy="36" r="5.5" fill="none" stroke="#000" stroke-width="1.5"/><circle cx="63" cy="36" r="5.5" fill="none" stroke="#000" stroke-width="1.5"/>',
	antennae: '<path d="M44 18 L36 4 M60 18 L68 4" stroke="#000" stroke-width="2.5"/><circle cx="36" cy="4" r="3.5" fill="#ff66ff" stroke="#000" stroke-width="1.5"/><circle cx="68" cy="4" r="3.5" fill="#ff66ff" stroke="#000" stroke-width="1.5"/>',
	blond: '<path d="M29 34 Q32 10 54 12 Q76 13 75 32 Q66 20 56 25 Q46 19 29 34 Z" fill="#f2d35a" stroke="#000" stroke-width="2"/>',
	curls: '<g fill="#8b4a22" stroke="#000" stroke-width="1.5"><circle cx="34" cy="26" r="7"/><circle cx="42" cy="17" r="7"/><circle cx="53" cy="13" r="7"/><circle cx="64" cy="16" r="7"/><circle cx="72" cy="25" r="6"/><circle cx="31" cy="37" r="6"/></g>',
};

// Draws a character as a picture of a comic: an outlined body, the arms of the gesture, and the head with the face of the expression. Rocky is a rock with googly eyes, whatever he feels.
const drawCharacter = (key, gesture, expression, isFacingLeft) => {
	const person = people[key];
	let body;

	if (person.look === 'rock') {
		body = '<ellipse cx="50" cy="156" rx="36" ry="4" fill="rgba(0,0,0,0.15)"/><path d="M14 154 Q8 124 34 116 Q58 104 82 124 Q96 150 82 156 Z" fill="#9a9a9a" stroke="#000" stroke-width="2.5"/><path d="M30 140 Q36 136 40 142 M64 132 Q70 130 72 136" fill="none" stroke="#666" stroke-width="2"/><circle cx="44" cy="128" r="7" fill="#fff" stroke="#000" stroke-width="1.5"/><circle cx="60" cy="126" r="7" fill="#fff" stroke="#000" stroke-width="1.5"/><circle cx="46" cy="130" r="3"/><circle cx="62" cy="124" r="3"/>';
	} else {
		const skin = expression === 'angry' ? '#ff9a8a' : person.skin;
		const arm = points => {
			const path = `M${points[0]} ${points[1]} Q${points[2]} ${points[3]} ${points[4]} ${points[5]}`;
			return `<path d="${path}" fill="none" stroke="#000" stroke-width="11" stroke-linecap="round"/><path d="${path}" fill="none" stroke="${person.shirt}" stroke-width="7" stroke-linecap="round"/><circle cx="${points[4]}" cy="${points[5]}" r="5" fill="${skin}" stroke="#000" stroke-width="2"/>`;
		};

		const [backArm, frontArm] = arms[gesture] ?? arms.neutral;
		body = `<ellipse cx="50" cy="156" rx="26" ry="4" fill="rgba(0,0,0,0.15)"/>
			<path d="M44 112 L42 150 M56 112 L58 150" stroke="#000" stroke-width="13" stroke-linecap="round"/>
			<path d="M44 112 L42 150 M56 112 L58 150" stroke="${person.pants}" stroke-width="9" stroke-linecap="round"/>
			<ellipse cx="40" cy="153" rx="8" ry="4"/><ellipse cx="62" cy="153" rx="8" ry="4"/>
			${arm(backArm)}
			<path d="M32 66 Q50 58 68 66 L70 114 Q50 120 30 114 Z" fill="${person.shirt}" stroke="#000" stroke-width="2.5"/>
			${arm(frontArm)}
			<g transform="rotate(${tilts[gesture] ?? 0} 50 50)">
				<circle cx="52" cy="38" r="22" fill="${skin}" stroke="#000" stroke-width="2.5"/>
				${faces[expression] ?? faces.neutral}
				${looks[person.look] ?? ''}
			</g>`;
	}

	const mirror = isFacingLeft ? ' transform="translate(100 0) scale(-1 1)"' : '';
	return `<svg viewBox="0 0 100 160" preserveAspectRatio="xMidYMax meet"><g${mirror}>${body}</g></svg>`;
};

const gestureWords = {wave: 'waves', pointSelf: 'points at themselves', pointOther: 'points at the other', shout: 'shouts', laugh: 'laughs', shrug: 'shrugs', think: 'thinks', scared: 'looks scared', hips: 'says', neutral: 'says'};

// What Sindre answers, by what the visitor said. The first match wins, and the last one matches anything.
const replies = [
	[/^[^a-zæøå]*[A-ZÆØÅ][^a-zæøå]{3,}$/, ['WHY ARE WE SHOUTING???', 'OK OK!!! I HEAR YOU!!!', 'MY MOM SAYS NO SHOUTING ON THE INTERNET!!!']],
	[/\b(hi|hello|hey|heya|hei|hallo|yo)\b/i, ['Hi! Welcome to my room! :-)', 'Hello! I made this whole page myself!', 'Hei hei! That is Norwegian for hi.']],
	[/\b(bye|goodbye|ha det|cya|later)\b/i, ['Bye! Sign my guestbook!', 'Bye bye! Come back soon! :-)']],
	[/\b(waffles?|brown cheese|brunost|food)\b/i, ['I LOVE WAFFLES!!!', 'I built a shrine to waffles. I am serious. Scroll down!']],
	[/\b(unicorns?|glitter)\b/i, ['Glitter is my virtual unicorn. Did you feed her?', 'Unicorns are the best animal. Do not tell Rocky.']],
	[/\b(mac|imac|apple|bondi)\b/i, ['My iMac is Bondi Blue. It is the best computer ever made. :-)', 'Think different!']],
	[/\b(windows|pc|microsoft|bill gates|crash)/i, ['Did it crash again? LOL', 'I have a Mac. I do not know what that is. ;-)']],
	[/\b(rain|bergen|weather|umbrella)\b/i, ['It rains in Bergen. It ALWAYS rains in Bergen.', 'I was born with an umbrella. True story.']],
	[/\b(norway|norwegian|norge|norsk)\b/i, ['Hilsen fra Norge! We have the Internet here too!', 'Yes! We have fjords and waffles. :-)']],
	[/\b(y2k|2000|millennium)\b/i, ['I stocked up on waffles for Y2K. Just in case.', 'My dad says the computers will be fine. My dad says a lot of things.']],
	[/\b(rocky|rock)\b/i, ['Rocky does not talk much. He is a rock.', 'Rocky says hi. I think.']],
	[/\b(cat|neko|sheep|dolly|pets?)\b/i, ['Did you see the pets on my page? Neko chases your mouse!', 'You can clone Dolly. Science!']],
	[/\b(lol|rofl|rotfl|lmao|haha)\b|:-?D/i, ['LOL!!!', 'ROTFL :-D', 'Hehe. You are funny.']],
	[/\b(stupid|lame|boring|sucks|ugly)\b/i, ['That is not nice. :-(', 'MOM!!! SOMEBODY IS MEAN ON THE INTERNET!!!']],
	[/\b(cool|awesome|nice|great|love|best)\b/i, ['Thanks!!! You are cool too!', 'I worked SO hard on it. :-)', 'I know! :-D']],
	[/\b(you)\b/i, ['Me? I am 12 and I make web pages.', 'I am just a kid with an iMac. :-)']],
	[/\?\s*$/, ['I do not know. Ask Jeeves?', 'Good question! I will put it in my FAQ.', 'Ask the butler further down my page. He knows everything.']],
	[/./, ['Cool.', 'I will put that on my page!', 'You are my 3rd visitor today! :-)', 'Did you sign my guestbook yet?', 'I am not allowed on the Internet after 8. Mom says.', 'Brb, getting a waffle. Ok I am back.']],
];

export default class extends GeoCitiesElement {
	connected() {
		const {strip, form, input, character: characterSelect, clear: clearButton, reconnect: reconnectButton, panelTemplate, balloonTemplate, characterTemplate: castTemplate} = this.parts;
		const emotionInputs = [...this.querySelectorAll('input[name="geocities-comic-emotion"]')];
		let neutralTurn = 0;

		// The gesture and the face that a line asks for, with the rules of Comic Chat, and the emotion of the wheel, when one is picked.
		const readLine = (text, mode, emotion) => {
			const letters = text.replaceAll(/[^\p{L}]/gu, '');
			const isShout = mode !== 'think' && ((letters.length >= 3 && letters === letters.toUpperCase() && letters !== letters.toLowerCase()) || text.includes('!!!'));
			const start = text.trim().toLowerCase();
			let expression = 'neutral';

			if (/>:-?\(/.test(text)) {
				expression = 'angry';
			} else if (/:-?\(|:'\(/.test(text)) {
				expression = 'sad';
			} else if (/;-?\)/.test(text)) {
				expression = 'coy';
			} else if (/:-?D|\b(lol|rofl|rotfl|lmao|ha(ha)+|he(he)+)\b/i.test(text)) {
				expression = 'laughing';
			} else if (/:-?[oO0S]\b/.test(text)) {
				expression = 'scared';
			} else if (/:-?\)|:-?\]|=\)|<g>|<grin>/i.test(text)) {
				expression = 'happy';
			} else if (/:-?\|/.test(text)) {
				expression = 'bored';
			} else if (isShout) {
				expression = 'shouting';
			}

			let gesture;

			if (mode === 'think') {
				gesture = 'think';
			} else if (isShout) {
				gesture = 'shout';
			} else if (expression === 'laughing') {
				gesture = 'laugh';
			} else if (/^(hi|hello|hey|heya|bye|goodbye|welcome|hei|hallo|yo|cya|ha det)\b/.test(start) || /\bbrb\b/.test(start)) {
				gesture = 'wave';
			} else if (/^you\b|\b(are|will|did|do|can|would|have) you\b|\bdon['’]t you\b/.test(start)) {
				gesture = 'pointOther';
			} else if (/^(i|i['’]m|i['’]ll|i['’]d|i['’]ve|me|my)\b/.test(start) || /\bimho\b/.test(start)) {
				gesture = 'pointSelf';
			} else if (start.endsWith('?')) {
				gesture = 'shrug';
			} else if (expression === 'scared') {
				gesture = 'scared';
			} else {
				// Like Comic Chat, it takes turns with the neutral poses, so the comic does not look the same in every panel.
				gesture = ['neutral', 'hips'][neutralTurn++ % 2];
			}

			let kind = mode === 'think' ? 'think' : (isShout ? 'shout' : 'say');

			if (emotion && emotion !== 'auto') {
				expression = emotion;

				if (gesture === 'neutral' || gesture === 'hips') {
					gesture = {laughing: 'laugh', shouting: 'shout', scared: 'scared', angry: 'hips'}[emotion] ?? gesture;
				}

				if (emotion === 'shouting' && kind === 'say') {
					kind = 'shout';
				}
			}

			return {gesture, expression, kind};
		};

		let lastReply;
		let current;
		let lineCount = 0;
		let isOnline = true;
		let hasMomCalled = false;

		// A new panel with its cast, from left to right. The first faces right, and the others face left, so they talk to each other.
		const newPanel = (cast, state) => {
			const element = panelTemplate.content.firstElementChild.cloneNode(true);
			const castElement = element.children[1];
			const figures = {};

			if (state) {
				element.dataset.state = state;
			}

			for (const [index, key] of cast.entries()) {
				const figure = castTemplate.content.firstElementChild.cloneNode(true);
				figure.innerHTML = drawCharacter(key, ['neutral', 'hips'][(neutralTurn + index) % 2], 'neutral', index > 0);
				castElement.append(figure);
				figures[key] = {element: figure, isFacingLeft: index > 0};
			}

			strip.append(element);

			// A page of the comic has at most nine panels.
			while (strip.children.length > 9) {
				strip.firstElementChild.remove();
			}

			current = {element, balloons: element.children[0], caption: element.children[2], count: 0, speakers: new Set(), figures};
			return current;
		};

		const act = (key, reading) => {
			const figure = current.figures[key];
			figure.element.innerHTML = drawCharacter(key, reading.gesture, reading.expression, figure.isFacingLeft);
		};

		const speak = (key, text, reading, cast) => {
			if (!current || current.count >= 2 || current.speakers.has(key) || !current.figures[key]) {
				newPanel(cast);
			}

			act(key, reading);
			const balloon = balloonTemplate.content.firstElementChild.cloneNode(true);
			balloon.textContent = text;

			if (reading.kind !== 'say') {
				balloon.dataset.state = reading.kind;
			}

			if (current.figures[key].isFacingLeft) {
				balloon.dataset.comicSide = 'right';
			}

			current.balloons.append(balloon);
			current.caption.textContent = `${current.caption.textContent} ${people[key].name} ${gestureWords[reading.gesture] ?? 'says'}.`.trim();
			current.count++;
			current.speakers.add(key);
		};

		// The others react with their faces to a shout or a laugh.
		const react = (key, reading) => {
			const figure = current.figures[key];

			if (!figure || current.speakers.has(key)) {
				return;
			}

			const expression = {shout: 'scared', laugh: 'happy', wave: 'happy'}[reading.gesture];

			if (expression) {
				figure.element.innerHTML = drawCharacter(key, expression === 'scared' ? 'scared' : 'neutral', expression, figure.isFacingLeft);
			}
		};

		const visitorCast = () => {
			const cast = [characterSelect.value];

			// Rocky sits in the room now and then. He never says anything.
			if (Math.random() < 0.3) {
				cast.push('rocky');
			}

			if (isOnline) {
				cast.push('sindre');
			}

			return cast;
		};

		const sindreSays = (text, emotion) => {
			speak('sindre', text, readLine(text, 'say', emotion), [characterSelect.value, 'sindre']);
		};

		const answer = text => {
			const [, choices] = replies.find(([pattern]) => pattern.test(text));
			const options = choices.filter(choice => choice !== lastReply);
			lastReply = randomItem(options.length > 0 ? options : choices);
			sindreSays(lastReply);
		};

		// After a while, Mom needs the phone line, like every evening in 1999.
		const momNeedsThePhone = () => {
			hasMomCalled = true;
			isOnline = false;
			newPanel(['sindre', 'mom'], 'mom');
			speak('mom', 'SINDRE!!! I NEED THE PHONE! GET OFF THE INTERNET!', readLine('SINDRE!!!', 'say'), ['sindre', 'mom']);
			speak('sindre', 'NOOO! Bye everybody!', {gesture: 'wave', expression: 'scared', kind: 'shout'}, ['sindre', 'mom']);
			current.caption.textContent += ' *** Sindre has quit (Mom needs the phone).';
			reconnectButton.hidden = false;
		};

		this.on(form, 'submit', event => {
			event.preventDefault();
			const text = input.value.trim().slice(0, 80);

			if (!text) {
				input.focus();
				return;
			}

			const mode = event.submitter?.dataset.comicMode ?? 'say';
			const emotion = emotionInputs.find(item => item.checked)?.value;
			const reading = readLine(text, mode, emotion);
			const visitor = characterSelect.value;
			speak(visitor, text, reading, visitorCast());
			react('sindre', reading);
			input.value = '';
			lineCount++;

			if (current.figures.rocky && /\b(rocky|rock)\b/i.test(text) && current.count < 2) {
				speak('rocky', '…', {gesture: 'neutral', expression: 'neutral', kind: 'think'}, visitorCast());
			}

			if (!isOnline) {
				return;
			}

			this.timeout(900, () => {
				if (!isOnline) {
					return;
				}

				answer(text);

				if (!hasMomCalled && lineCount >= 8) {
					hasMomCalled = true;
					this.timeout(1200, momNeedsThePhone);
				}
			});
		});

		this.on(reconnectButton, 'click', () => {
			isOnline = true;
			reconnectButton.hidden = true;
			newPanel([characterSelect.value, 'sindre']);
			current.caption.textContent = '*** Sindre has joined #sindres-room.';
			sindreSays('Hi! I am back! Mom is on the phone with Mormor now. We have 10 minutes.');
			input.focus();
		});

		const showEmotion = () => {
			for (const item of emotionInputs) {
				const label = item.closest('label');

				if (item.checked) {
					label.dataset.state = 'picked';
				} else {
					delete label.dataset.state;
				}
			}
		};

		for (const item of emotionInputs) {
			this.on(item, 'change', showEmotion);
		}

		// A new page of the comic. While Mom has the phone, Sindre is not there to say hi.
		const welcome = () => {
			current = undefined;
			strip.replaceChildren();

			if (!isOnline) {
				newPanel([characterSelect.value]);
				current.caption.textContent = '*** Sindre is offline (Mom needs the phone). Press Reconnect.';
				return;
			}

			newPanel([characterSelect.value, 'sindre']);
			sindreSays('Hi! Welcome to my chat room! Type something below and we act it out.', 'happy');
		};

		this.on(clearButton, 'click', welcome);

		showEmotion();
		welcome();
	}
}
