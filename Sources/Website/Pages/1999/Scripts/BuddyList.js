// The buddy list on the 1999 page: buddies sign on and off, go away, and send instant messages while the list is on screen, and answer the visitor in their own way. Warnings raise the warning level of a buddy, and a buddy at 100% is kicked off, like on the real network. The sounds are made with Web Audio, and only play after the visitor turns them on.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));

// A copy of the first element of a template.
const cloneTemplate = template => template.content.firstElementChild.cloneNode(true);

// Sets up the buddy list, with the element for its helpers, like `say()`, `on()`, and `timeout()`, and its parts.
const setUpBuddyList = (buddyList, {myWarning: myWarningText, sound: soundCheckbox, list, groupTemplate, buddyTemplate, away: awayButton, awayForm, awayText, chatTitle, buddyWarning, log, lineTemplate, form, input, send: sendButton, warn: warnButton}) => {
	const myName = 'SindreTheUnicorn';

	// Each buddy has things to say first, answers, answers to some words, and what they say when warned.
	const buddies = [
		{
			name: 'WaffleKing85',
			group: 'Buddies',
			isOnline: true,
			openers: ['hey!!! do u like waffles', 'i just ate 6 waffles. AMA', 'brown cheese or jam? choose wisely'],
			answers: ['lol', 'brb, waffles', 'u should try them with brown cheese', 'my waffle iron is heart shaped. 5 hearts per waffle'],
			keywords: [[/waffle|vaffel|brunost|cheese/i, 'WAFFLES!!! finally someone gets it'], [/\?/, 'idk. waffles?']],
			warned: 'y did u warn me!!! i was only talking about waffles',
		},
		{
			name: 'xXGlitterXx',
			group: 'Buddies',
			isOnline: true,
			openers: ['neigh!!!', '*sparkles at u*', 'r u my friend? neigh'],
			answers: ['neigh neigh', '*swishes tail*', 'i am a unicorn. i cannot read. neigh', '~*~*~ sparkle ~*~*~'],
			keywords: [[/feed|food|hungry|eat|waffle/i, 'omg yes pls scroll up and feed me'], [/love|♥|<3/i, '♥♥♥ neigh ♥♥♥']],
			warned: 'neigh?? :( *sad sparkle*',
		},
		{
			name: 'BondiBlue98',
			group: 'Buddies',
			isOnline: false,
			openers: ['did u see the new iMac colors? TANGERINE', 'think different!!!', 'my iMac has no floppy drive and i am FINE'],
			answers: ['think different', 'it is see-through. u can see the computer inside', 'macs dont get viruses lol'],
			keywords: [[/pc|windows|bill|gates/i, 'windows?? eww'], [/mac|imac|apple/i, 'yesss a fellow mac user']],
			warned: 'warning me will not make ur PC a mac',
		},
		{
			name: 'Kevin from school',
			group: 'Buddies',
			isOnline: false,
			openers: ['wanna trade unimon cards? i have a holo floppy', 'did u do the homework', 'i got 3 holo cards today. no big deal'],
			answers: ['ok but i get ur glitter card', 'my cousin works at a video game company', 'lol no'],
			keywords: [[/trade|card|unimon|holo/i, 'deal. 3 floppies for ur holo glitter. fair trade'], [/homework/i, 'can i copy urs']],
			warned: 'ok fine no trades for u',
		},
		{
			name: 'CoolDude2000',
			group: 'Buddies',
			isOnline: true,
			openers: ['a/s/l?', 'sup', 'wanna see my page? its under construction'],
			answers: ['cool', 'cool cool', 'k', 'lol same'],
			keywords: [[/\d/, 'cool. 12/m/cyberspace'], [/page|site/i, 'my page has a hit counter. 4 hits. 3 are me']],
			warned: 'whoa. not cool',
		},
		{
			name: 'Mamma',
			group: 'Family',
			isOnline: true,
			openers: ['SINDRE ARE YOU THERE', 'DINNER IS READY', 'HOW DO I MAKE THE LETTERS SMALL'],
			answers: ['OK. COME DOWN NOW.', 'I NEED THE PHONE IN 5 MINUTES', 'LOVE MAMMA'],
			keywords: [[/\bno\b|nei/i, 'DO NOT SAY NO TO YOUR MOTHER'], [/love|♥/i, 'LOVE YOU TOO. NOW GET OFF THE INTERNET']],
			warned: 'DID YOU JUST WARN YOUR MOTHER',
		},
		{
			name: 'Bestemor',
			group: 'Family',
			isOnline: false,
			openers: ['HELLO IS THIS THE INTERNET', 'SINDRE I CLICKED THE START BUTTON AND NOTHING STARTED', 'IS THIS THE E-MAIL'],
			answers: ['HOW DO I CLOSE THIS', 'I WILL CALL YOU ON THE PHONE INSTEAD', 'YOU ARE SO GOOD WITH COMPUTERS'],
			keywords: [[/hi|hei|hello/i, 'HELLO DEAR. IT IS BESTEMOR. I AM TYPING']],
			warned: 'WHAT IS A WARNING. IS IT A VIRUS',
		},
	];

	for (const buddy of buddies) {
		buddy.lines = [];
		buddy.warning = 0;
		buddy.isAway = false;
		buddy.hasNewMessage = false;
		// When a buddy that was kicked off can sign on again.
		buddy.bannedUntil = 0;
		buddy.row = cloneTemplate(buddyTemplate);
		buddy.button = buddy.row.querySelector('button');
		[buddy.icon, buddy.label, buddy.note] = buddy.button.querySelectorAll('span');
		buddy.label.textContent = buddy.name;
		buddyList.on(buddy.button, 'click', () => {
			openChat(buddy);
		});
	}

	// The groups of the list, with a heading that counts the buddies online, like “Buddies (3/5)”. The co-workers group is empty, as I am 10.
	const groups = ['Buddies', 'Family', 'Co-Workers'].map(name => {
		const item = cloneTemplate(groupTemplate);
		const [heading, members] = item.children;
		members.append(...buddies.filter(buddy => buddy.group === name).map(buddy => buddy.row));
		list.append(item);
		return {name, heading, members};
	});

	let chatBuddy;
	let myWarning = 0;
	let isAway = false;
	let awayMessage = '';
	let isDisconnected = false;
	let eventTimer;
	// The visitor gets only a few messages that they did not start, so the chat does not nag.
	let unaskedMessages = 0;

	// The sounds of the buddy list: a door that creaks open when a buddy signs on, one that slams when a buddy signs off, and a bloop for a message. The audio of the element is made when the visitor turns them on.
	const playSound = kind => {
		const audio = buddyList.sound();
		if (!soundCheckbox.checked || !audio) {
			return;
		}

		const {context: audioContext} = audio;
		const time = audioContext.currentTime + 0.02;
		const output = new GainNode(audioContext, {gain: 0});
		output.connect(audio.output);
		if (kind === 'message') {
			const oscillator = new OscillatorNode(audioContext, {type: 'sine', frequency: 520});
			oscillator.frequency.setValueAtTime(520, time);
			oscillator.frequency.setValueAtTime(780, time + 0.09);
			output.gain.setValueAtTime(0.12, time);
			output.gain.exponentialRampToValueAtTime(0.001, time + 0.25);
			oscillator.connect(output);
			oscillator.start(time);
			oscillator.stop(time + 0.26);
			return;
		}

		if (kind === 'open') {
			// The creak: a buzzy tone that rises, with a wobble.
			const oscillator = new OscillatorNode(audioContext, {type: 'sawtooth', frequency: 90});
			oscillator.frequency.exponentialRampToValueAtTime(240, time + 0.6);
			const wobble = new OscillatorNode(audioContext, {frequency: 23});
			const wobbleDepth = new GainNode(audioContext, {gain: 30});
			wobble.connect(wobbleDepth).connect(oscillator.frequency);
			const filter = new BiquadFilterNode(audioContext, {type: 'bandpass', frequency: 900, Q: 4});
			output.gain.setValueAtTime(0.0001, time);
			output.gain.exponentialRampToValueAtTime(0.08, time + 0.1);
			output.gain.exponentialRampToValueAtTime(0.0001, time + 0.65);
			oscillator.connect(filter).connect(output);
			oscillator.start(time);
			wobble.start(time);
			oscillator.stop(time + 0.7);
			wobble.stop(time + 0.7);
			return;
		}

		// The slam: a short burst of noise and a low thump.
		const noise = new AudioBuffer({length: Math.floor(audioContext.sampleRate * 0.3), sampleRate: audioContext.sampleRate});
		const samples = noise.getChannelData(0);
		for (let index = 0; index < samples.length; index++) {
			samples[index] = (Math.random() * 2) - 1;
		}

		const source = new AudioBufferSourceNode(audioContext, {buffer: noise});
		const filter = new BiquadFilterNode(audioContext, {type: 'lowpass', frequency: 700});
		const thump = new OscillatorNode(audioContext, {type: 'sine', frequency: 70});
		output.gain.setValueAtTime(0.25, time);
		output.gain.exponentialRampToValueAtTime(0.001, time + 0.3);
		source.connect(filter).connect(output);
		thump.connect(output);
		source.start(time);
		thump.start(time);
		thump.stop(time + 0.3);
	};

	buddyList.on(soundCheckbox, 'change', () => {
		if (soundCheckbox.checked) {
			buddyList.sound()?.context.resume();
			playSound('open');
		}
	});

	// The row of a buddy: hidden while offline, and highlighted with a door for a moment while signing on or off.
	const renderBuddy = buddy => {
		const isShown = buddy.isOnline || buddy.isLeaving;
		buddy.row.hidden = !isShown;
		buddy.button.disabled = !buddy.isOnline;
		let state;
		let icon = '';
		let note = '';
		if (buddy.isLeaving) {
			state = 'signing-off';
			icon = '🚪';
			note = 'signed off';
		} else if (buddy.isArriving) {
			state = 'signing-on';
			icon = '🚪';
			note = 'signed on';
		} else if (buddy.hasNewMessage) {
			state = 'message';
			icon = '✉️';
			note = 'new IM!';
		} else if (buddy.isAway) {
			state = 'away';
			icon = '📝';
			note = 'away';
		}

		if (buddy.warning > 0 && !buddy.isLeaving) {
			note = `${note} ${buddy.warning}%`.trim();
		}

		if (state) {
			buddy.button.dataset.state = state;
		} else {
			delete buddy.button.dataset.state;
		}

		buddy.icon.textContent = icon;
		buddy.note.textContent = note;
		buddy.button.setAttribute('aria-label', `${buddy.name}${note ? `, ${note}` : ''}`);

		for (const group of groups) {
			const members = buddies.filter(other => other.group === group.name);
			group.heading.textContent = `${group.name} (${members.filter(other => other.isOnline).length}/${members.length})`;
		}
	};

	const renderAll = () => {
		for (const buddy of buddies) {
			renderBuddy(buddy);
		}
	};

	const addLine = (buddy, kind, text) => {
		buddy.lines.push({kind, text});
		if (buddy === chatBuddy) {
			log.append(renderLine(buddy, {kind, text}));
			log.scrollTop = log.scrollHeight;
		}
	};

	const renderLine = (buddy, {kind, text}) => {
		const line = cloneTemplate(lineTemplate);
		const [name, message] = line.children;
		message.textContent = text;
		if (kind === 'system') {
			line.dataset.state = 'system';
			name.remove();
		} else if (kind === 'auto') {
			line.dataset.state = 'auto';
			name.dataset.state = 'mine';
			name.textContent = `Auto response from ${myName}:`;
		} else if (kind === 'mine') {
			name.dataset.state = 'mine';
			name.textContent = `${myName}:`;
		} else {
			name.textContent = `${buddy.name}:`;
		}

		return line;
	};

	const renderChat = () => {
		if (!chatBuddy) {
			return;
		}

		chatTitle.textContent = `Instant Message: ${chatBuddy.name}`;
		buddyWarning.textContent = `${chatBuddy.name}’s warning level: ${chatBuddy.warning}%`;
		const canChat = chatBuddy.isOnline && !isDisconnected;
		input.disabled = !canChat;
		sendButton.disabled = !canChat;
		warnButton.disabled = !canChat;
	};

	const openChat = buddy => {
		chatBuddy = buddy;
		buddy.hasNewMessage = false;
		// The old messages are not read out again when the chat opens.
		log.setAttribute('aria-live', 'off');
		log.replaceChildren(...buddy.lines.map(line => renderLine(buddy, line)));
		log.scrollTop = log.scrollHeight;
		requestAnimationFrame(() => {
			log.removeAttribute('aria-live');
		});
		renderBuddy(buddy);
		renderChat();
		input.focus();
	};

	// A buddy answers after a moment, as they have to type it, with the answer to a word in the message, or one of their answers.
	const answer = (buddy, message) => {
		const keyword = buddy.keywords.find(([pattern]) => pattern.test(message));
		const text = keyword?.[1] ?? randomItem(buddy.answers);
		buddyList.timeout(randomInteger(1200, 2800), () => {
			if (buddy.isOnline && !isDisconnected) {
				receive(buddy, text);
			}
		});
	};

	const receive = (buddy, text) => {
		addLine(buddy, 'them', text);
		playSound('message');
		if (buddy !== chatBuddy) {
			buddy.hasNewMessage = true;
			renderBuddy(buddy);
			buddyList.say(`New instant message from ${buddy.name}: ${text}`);
		}

		// The away message answers by itself, and the buddy has something to say about it.
		if (isAway && !buddy.hasSeenAway) {
			buddy.hasSeenAway = true;
			buddyList.timeout(300, () => {
				addLine(buddy, 'auto', awayMessage);
				buddyList.timeout(2000, () => {
					if (buddy.isOnline && !isDisconnected) {
						addLine(buddy, 'them', randomItem(['lol nice away msg', 'ok ttyl', 'ur always away!!!', 'is that a song lyric?', 'k. brb too']));
						playSound('message');
					}
				});
			});
		}
	};

	const signOn = async buddy => {
		// A buddy who was kicked off comes back with a clean warning level.
		if (buddy.warning >= 100) {
			buddy.warning = 0;
		}

		buddy.isOnline = true;
		buddy.isArriving = true;
		renderBuddy(buddy);
		playSound('open');
		buddyList.say(`${buddy.name} signed on.`);
		await buddyList.wait(3000);
		buddy.isArriving = false;
		renderBuddy(buddy);
	};

	const signOff = async buddy => {
		buddy.isOnline = false;
		buddy.isLeaving = true;
		buddy.isAway = false;
		renderBuddy(buddy);
		renderChat();
		playSound('slam');
		buddyList.say(`${buddy.name} signed off.`);
		await buddyList.wait(3000);
		buddy.isLeaving = false;
		renderBuddy(buddy);
	};

	// Something happens on the list every now and then: a buddy signs on or off, goes away or comes back, or sends a message.
	const randomEvent = () => {
		if (isDisconnected) {
			return;
		}

		const online = buddies.filter(buddy => buddy.isOnline && !buddy.isArriving);
		const offline = buddies.filter(buddy => !buddy.isOnline && !buddy.isLeaving && buddy.bannedUntil < Date.now());
		// The first thing that happens is always a message, so the visitor sees what the list is for, and not a buddy who leaves.
		const roll = unaskedMessages === 0 ? 0 : Math.random();
		if (roll < 0.35 && unaskedMessages < 6 && online.length > 0) {
			const buddy = randomItem(online.filter(buddy => !buddy.isAway).length > 0 ? online.filter(buddy => !buddy.isAway) : online);
			unaskedMessages++;
			receive(buddy, randomItem(buddy.openers));
		} else if (roll < 0.6 && offline.length > 0) {
			signOn(randomItem(offline));
		} else if (roll < 0.8 && online.length > 2) {
			signOff(randomItem(online.filter(buddy => buddy !== chatBuddy)));
		} else if (online.length > 0) {
			const buddy = randomItem(online);
			buddy.isAway = !buddy.isAway;
			renderBuddy(buddy);
		}
	};

	const scheduleEvent = (delay = randomInteger(12_000, 25_000)) => {
		eventTimer?.cancel();
		eventTimer = buddyList.timeout(delay, () => {
			randomEvent();
			scheduleEvent();
		});
	};

	buddyList.on(form, 'submit', event => {
		event.preventDefault();
		const text = input.value.trim();
		if (!text || !chatBuddy?.isOnline || isDisconnected) {
			return;
		}

		input.value = '';
		addLine(chatBuddy, 'mine', text);
		answer(chatBuddy, text);
	});

	const updateMyWarning = () => {
		myWarningText.textContent = `My warning level: ${myWarning}%`;
	};

	// At 100%, the visitor is kicked off too, and everyone signs off, until the modem dials in again.
	const disconnect = async () => {
		isDisconnected = true;
		renderChat();
		buddyList.say('Your warning level is 100%. You have been disconnected for being too evil.');
		buddyList.toast('Your warning level is 100%. You have been disconnected!');
		for (const buddy of buddies.filter(buddy => buddy.isOnline)) {
			buddy.isOnline = false;
			buddy.wasOnline = true;
			renderBuddy(buddy);
		}

		await buddyList.wait(8000);
		myWarning = 0;
		updateMyWarning();
		isDisconnected = false;
		buddyList.say('Reconnected. Be nice this time.');
		for (const buddy of buddies.filter(buddy => buddy.wasOnline)) {
			buddy.wasOnline = false;
			buddy.isOnline = true;
		}

		renderAll();
		renderChat();
	};

	buddyList.on(warnButton, 'click', () => {
		const buddy = chatBuddy;
		if (!buddy?.isOnline || isDisconnected) {
			return;
		}

		buddy.warning = Math.min(buddy.warning + randomInteger(10, 25), 100);
		addLine(buddy, 'system', `You warned ${buddy.name}. Their warning level is now ${buddy.warning}%.`);
		renderBuddy(buddy);
		renderChat();
		if (buddy.warning >= 100) {
			addLine(buddy, 'system', `${buddy.name} was kicked off for a while, as their warning level is 100%.`);
			buddy.bannedUntil = Date.now() + 60_000;
			signOff(buddy);
			return;
		}

		buddyList.timeout(1200, () => {
			if (!buddy.isOnline || isDisconnected) {
				return;
			}

			receive(buddy, buddy.warned);
			// Buddies warn back half of the time.
			if (Math.random() < 0.5) {
				myWarning = Math.min(myWarning + randomInteger(10, 30), 100);
				updateMyWarning();
				addLine(buddy, 'system', `${buddy.name} warned you back! Your warning level is now ${myWarning}%.`);
				if (myWarning >= 100) {
					disconnect();
				}
			}
		});
	});

	buddyList.on(awayButton, 'click', () => {
		if (isAway) {
			isAway = false;
			awayButton.textContent = 'I’m Away';
			buddyList.say('You are back.');
			return;
		}

		const isOpening = awayForm.hidden;
		awayForm.hidden = !isOpening;
		awayButton.setAttribute('aria-expanded', String(isOpening));
		if (isOpening) {
			awayText.value ||= 'brb, my mom needs the phone';
			awayText.focus();
			awayText.select();
		}
	});

	buddyList.on(awayForm, 'submit', event => {
		event.preventDefault();
		awayMessage = awayText.value.trim() || 'brb';
		isAway = true;
		for (const buddy of buddies) {
			buddy.hasSeenAway = false;
		}

		awayForm.hidden = true;
		awayButton.setAttribute('aria-expanded', 'false');
		awayButton.textContent = 'I’m Back';
		awayButton.focus();
		buddyList.say(`You are away: “${awayMessage}”. Your away message answers your buddies.`);
	});

	renderAll();

	return {
		// The focus is never lost when the row of a buddy hides, or its button is disabled as the buddy signs off, or the chat can no longer be used: it goes to the buddy list.
		focusReplacement() {
			return buddies.find(buddy => buddy.isOnline)?.button ?? awayButton;
		},
		visibilityChanged(isVisible) {
			if (isVisible) {
				// The first message comes soon, so the visitor sees what the list does.
				scheduleEvent(unaskedMessages === 0 ? 3000 : undefined);
			} else {
				eventTimer?.cancel();
			}
		},
	};
};

export default class extends GeoCitiesElement {
	#buddyList;

	connected() {
		this.#buddyList = setUpBuddyList(this, this.parts);
	}

	visibilityChanged(isVisible) {
		this.#buddyList.visibilityChanged(isVisible);
	}

	focusReplacement() {
		return this.#buddyList.focusReplacement();
	}
}
