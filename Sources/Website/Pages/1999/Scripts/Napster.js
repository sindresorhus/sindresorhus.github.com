// Napster and the CD burner on the 1999 page. The search finds the hits of 1999 on the computers of other kids, often with the wrong name. The downloads share the modem of the visitor, and each goes no faster than the modem at the other end, by a clock of the night where a second is a minute. Then the burner writes the songs to a CD, as long as nobody touches the computer. The coasters are kept in the browser.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));

// A copy of the first element of a template.
const cloneTemplate = template => template.content.firstElementChild.cloneNode(true);

const sum = numbers => {
	let total = 0;
	for (const number of numbers) {
		total += number;
	}

	return total;
};

// Like “1 minute” or “2 minutes”.
const plural = (count, word) => `${count.toLocaleString('en-US')} ${word}${count === 1 ? '' : 's'}`;

const songs = [
	{artist: 'Eiffel 65', title: 'Blue (Da Ba Dee)', seconds: 219},
	{artist: 'Aqua', title: 'Barbie Girl', seconds: 197},
	{artist: 'Lou Bega', title: 'Mambo No. 5', seconds: 219},
	{artist: 'Ricky Martin', title: 'Livin’ la Vida Loca', seconds: 243},
	{artist: 'Britney Spears', title: '…Baby One More Time', seconds: 211},
	{artist: 'Smash Mouth', title: 'All Star', seconds: 200},
	{artist: 'Backstreet Boys', title: 'I Want It That Way', seconds: 213},
	{artist: 'TLC', title: 'No Scrubs', seconds: 214},
	{artist: 'Santana', title: 'Smooth', seconds: 296},
	{artist: 'Cher', title: 'Believe', seconds: 239},
	{artist: 'a-ha', title: 'Take On Me', seconds: 228},
	{artist: 'Darude', title: 'Sandstorm', seconds: 225},
	{artist: 'Lene Marlin', title: 'Sitting Down Here', seconds: 237},
	{artist: 'Bomfunk MC’s', title: 'Freestyler', seconds: 186},
	{artist: 'Vengaboys', title: 'We’re Going to Ibiza!', seconds: 195},
];

// The other kids, with the line of each, and how many KB a second it sends.
const lines = [
	{name: '14.4K', speed: 1.4},
	{name: '28.8K', speed: 2.8},
	{name: '33.6K', speed: 3.2},
	{name: '56K', speed: 4.6},
	{name: 'Cable', speed: 40},
	{name: 'T1', speed: 150},
];
const users = ['xXdjXx', 'metalhead77', 'bondi_babe', 'ripper2000', 'mp3king', 'dial_up_dan', 'lars_fan_club', 'dorm_room_t1', 'sk8rboi', 'grunge4ever'];

// The modem of the visitor gets about 4.8 KB a second, at best, which all downloads share.
const modemSpeed = 4.8;
const maximumTransfers = 4;

const songName = song => `${song.artist} – ${song.title}`;
const fileName = (song, style) => {
	const base = `${song.artist} - ${song.title.replace('…', '')}`;
	return {
		plain: `${base}.mp3`,
		lower: `${base.toLowerCase().replaceAll(' ', '_')}.mp3`,
		real: `${song.title.replace('…', '')} (REAL) (not a fake) [128].mp3`,
		live: `${song.artist.toLowerCase()} - ${song.title.toLowerCase().replace('…', '')} (live in my room).mp3`,
		wrong: `${randomItem(['weird al', 'eminem', 'metallica', 'the offspring'])} - ${song.title.toLowerCase().replace('…', '')}.mp3`,
	}[style];
};

const formatSize = kilobytes => `${(kilobytes / 1024).toFixed(1)} MB`;
const formatLength = seconds => `${Math.floor(seconds / 60)}:${String(Math.round(seconds % 60)).padStart(2, '0')}`;

// Sets up Napster and the CD burner, with the element for its helpers, like `say()`, `on()`, and `interval()`, and its parts.
const setUpNapster = (napster, {search: searchForm, query, results, resultTemplate, clock, transfers: transferList, transferTemplate, library, songTemplate, capacity, capacityFill, label: labelInput, burn: burnButton, burner, buffer: bufferFill, written: writtenFill, burnStatus, disc, discLabel, coasters: coastersText}) => {
	// The songs that the visitor has, which starts with two that I ripped from my own CDs.
	const owned = [
		{song: songs.find(song => song.title === 'Take On Me'), note: 'ripped from my CD'},
		{song: songs.find(song => song.title === 'Sitting Down Here'), note: 'ripped from my CD'},
	];

	// The night: from 23:00, a minute for each second that a download runs.
	let nightMinutes = 0;
	let night = 1;
	let hasMomCalled = false;
	const transfers = [];
	let tickTimer;

	const renderClock = () => {
		const minutes = (23 * 60) + nightMinutes;
		const time = `${String(Math.floor(minutes / 60) % 24).padStart(2, '0')}:${String(minutes % 60).padStart(2, '0')}`;
		const active = transfers.filter(transfer => transfer.state === 'downloading');
		const speed = sum(active.map(transfer => transfer.speed));
		clock.textContent = `☾ Night ${night}, ${time} · Modem: 56K · ${speed.toFixed(1)} KB/s`;
	};

	const search = text => {
		const words = text.toLowerCase().split(/\s+/).filter(Boolean);
		const matches = songs.filter(song => words.every(word => songName(song).toLowerCase().includes(word)));
		const found = [];
		for (const song of matches.slice(0, 3)) {
			for (const style of ['plain', randomItem(['lower', 'real', 'live']), 'wrong']) {
				// A file with the wrong artist is often a different song, too.
				const isWrong = style === 'wrong' && Math.random() < 0.6;
				found.push({name: fileName(song, style), song: isWrong ? randomItem(songs) : song});
			}
		}

		// Nobody has it, but somebody has a file with that name. It is always Barbie Girl.
		if (found.length === 0) {
			const barbie = songs.find(song => song.artist === 'Aqua');
			found.push({name: `${text.toLowerCase()}.mp3`, song: barbie}, {name: `${text.toLowerCase()} (rare remix).mp3`, song: barbie});
		}

		return found.slice(0, 7).map(file => {
			const line = randomItem(lines);
			const bitrate = randomItem([64, 128, 128, 128, 160, 192]);
			return {
				...file,
				user: randomItem(users),
				line,
				bitrate,
				size: (file.song.seconds * bitrate) / 8,
			};
		});
	};

	const showResults = text => {
		const files = search(text);
		results.replaceChildren(...files.map(file => {
			const item = cloneTemplate(resultTemplate);
			const name = item.querySelector('strong');
			const details = item.querySelector('span');
			const button = item.querySelector('button');
			name.textContent = file.name;
			details.textContent = `${formatSize(file.size)} · ${file.bitrate} kbps · ${file.line.name} · ${file.user}`;
			button.setAttribute('aria-label', `Get ${file.name}`);
			// The results are made again for each search, so their listeners go away with them.
			button.addEventListener('click', () => {
				startTransfer(file);
			});
			return item;
		}));
		napster.say(`Found ${plural(files.length, 'file')} for “${text}”.`);
	};

	const renderTransfer = transfer => {
		const percent = Math.min(transfer.received / transfer.file.size, 1) * 100;
		transfer.fill.style.width = `${percent}%`;
		const remaining = transfer.speed > 0 ? Math.ceil((transfer.file.size - transfer.received) / transfer.speed / 60) : 0;
		transfer.text.textContent = {
			queued: `Remotely queued (#${transfer.queuePosition}) · ${transfer.file.user}`,
			waiting: 'Locally queued. Your modem is busy.',
			downloading: `${Math.floor(percent)}% · ${transfer.speed.toFixed(1)} KB/s · ${plural(remaining, 'minute')} left · ${transfer.file.user} (${transfer.file.line.name})`,
			done: transfer.doneText,
			failed: transfer.failText,
		}[transfer.state];
		if (transfer.state === 'done' || transfer.state === 'failed') {
			transfer.item.dataset.state = transfer.state;
		}

		transfer.retryButton.hidden = transfer.state !== 'failed';
	};

	const startTransfer = file => {
		if (transfers.length === 0) {
			transferList.replaceChildren();
		}

		const item = cloneTemplate(transferTemplate);
		item.querySelector('strong').textContent = file.name;
		const retryButton = item.querySelector('button');
		retryButton.setAttribute('aria-label', `Try again: ${file.name}`);
		// A new try replaces the failed one, and the focus goes to the new one, as the button is gone. The listener goes away with the button.
		retryButton.addEventListener('click', () => {
			transfers.splice(transfers.indexOf(transfer), 1);
			item.remove();
			startTransfer(file).item.focus();
		});
		item.tabIndex = -1;
		const transfer = {
			file,
			item,
			fill: item.querySelector('div > div'),
			text: item.querySelector('span'),
			retryButton,
			received: 0,
			speed: 0,
			state: Math.random() < 0.3 ? 'queued' : 'waiting',
			queuePosition: randomInteger(3, 47),
		};
		transfers.push(transfer);
		transferList.prepend(item);
		renderTransfer(transfer);
		napster.say(`Getting ${file.name}…`);
		tick(true);
		return transfer;
	};

	const fail = (transfer, text) => {
		transfer.state = 'failed';
		transfer.failText = text;
		transfer.speed = 0;
		renderTransfer(transfer);
	};

	// A minute of the night: the queues move, the downloads get their part of the modem, and sometimes the night happens, like mom picking up the phone.
	const tick = (isOnlyUpdate = false) => {
		const running = transfers.filter(transfer => transfer.state === 'waiting' || transfer.state === 'downloading');
		for (const transfer of running.slice(0, maximumTransfers)) {
			transfer.state = 'downloading';
		}

		const active = transfers.filter(transfer => transfer.state === 'downloading');
		for (const transfer of active) {
			transfer.speed = Math.min(transfer.file.line.speed, modemSpeed / active.length);
		}

		const isQueued = transfers.some(transfer => transfer.state === 'queued');
		if (!isOnlyUpdate && (active.length > 0 || isQueued)) {
			nightMinutes++;
			for (const transfer of transfers.filter(transfer => transfer.state === 'queued')) {
				transfer.queuePosition -= randomInteger(1, 6);
				if (transfer.queuePosition <= 0) {
					transfer.state = 'waiting';
				}
			}

			for (const transfer of active) {
				transfer.received += transfer.speed * 60;
				if (transfer.received >= transfer.file.size) {
					transfer.state = 'done';
					transfer.speed = 0;
					const isSurprise = !transfer.file.name.toLowerCase().includes(transfer.file.song.title.toLowerCase().replace('…', ''));
					transfer.doneText = isSurprise ? `Done! It is actually ${songName(transfer.file.song)}.` : 'Done! Added to My MP3s.';
					renderTransfer(transfer);
					owned.push({song: transfer.file.song, note: 'from Napster'});
					renderLibrary();
					napster.say(`${transfer.file.name} is done.${isSurprise ? ` It is actually ${songName(transfer.file.song)}. Classic.` : ''}`);
				} else if (Math.random() < 0.003) {
					fail(transfer, `${transfer.file.user} went offline. Their mom picked up the phone.`);
				}
			}

			// Mom picks up the phone, and every download dies, at most once a night, so most songs make it.
			if (!hasMomCalled && active.length > 0 && Math.random() < 0.005) {
				hasMomCalled = true;
				for (const transfer of active.filter(transfer => transfer.state === 'downloading')) {
					fail(transfer, 'Connection lost at the worst time.');
				}

				napster.say('Mom picked up the phone! The modem lost the connection. Press Try Again when she is done.');
				napster.toast('MAMMA: I NEED THE PHONE!!!');
			}

			// In the morning, it is time for school.
			if (nightMinutes >= 8 * 60) {
				for (const transfer of transfers.filter(transfer => transfer.state === 'downloading' || transfer.state === 'waiting' || transfer.state === 'queued')) {
					fail(transfer, 'Stopped. It is 07:00 and time for school.');
				}

				nightMinutes = 0;
				night++;
				hasMomCalled = false;
				napster.say('It is 07:00! MAMMA: GET OFF THE INTERNET, YOU HAVE SCHOOL. A new night starts.');
			}
		}

		for (const transfer of transfers) {
			if (transfer.state !== 'done' && transfer.state !== 'failed') {
				renderTransfer(transfer);
			}
		}

		renderClock();
		updateTimer();
	};

	// The night only goes on while downloads run, and the window is on screen.
	const updateTimer = () => {
		const isBusy = transfers.some(transfer => ['queued', 'waiting', 'downloading'].includes(transfer.state));
		if (napster.isVisible && isBusy) {
			tickTimer ??= napster.interval(1000, () => {
				tick();
			});
		} else {
			tickTimer?.cancel();
			tickTimer = undefined;
		}
	};

	napster.on(searchForm, 'submit', event => {
		event.preventDefault();
		const text = query.value.trim();
		if (text) {
			showResults(text);
		}
	});

	napster.on(searchForm, 'click', event => {
		const suggestion = event.target.closest('[data-napster-suggestion]')?.dataset.napsterSuggestion;
		if (suggestion) {
			query.value = suggestion;
			showResults(suggestion);
		}
	});

	// The CD burner.
	const cdSeconds = 74 * 60;
	let isBurning = false;
	let coasters = Math.max(Math.trunc(napster.stored('coasters', 0)), 0);

	const selectedSongs = () => [...library.querySelectorAll('input:checked')].map(input => owned[Number(input.value)].song);

	const updateCapacity = () => {
		const seconds = sum(selectedSongs().map(song => song.seconds));
		capacityFill.style.width = `${Math.min(seconds / cdSeconds, 1) * 100}%`;
		capacity.textContent = `${formatLength(seconds)} of 74:00${seconds > cdSeconds ? '. Too much music! Take some songs off.' : ''}`;
		burnButton.disabled = isBurning || seconds === 0 || seconds > cdSeconds;
	};

	const renderLibrary = () => {
		const checked = new Set([...library.querySelectorAll('input:checked')].map(input => input.value));
		// The songs are made again, so the focus goes back to the same song.
		const focusedValue = library.contains(document.activeElement) ? document.activeElement.value : undefined;
		library.replaceChildren(...owned.map(({song, note}, index) => {
			const item = cloneTemplate(songTemplate);
			const checkbox = item.querySelector('input');
			checkbox.value = String(index);
			checkbox.checked = checked.has(String(index));
			checkbox.disabled = isBurning;
			item.querySelector('span').textContent = `${songName(song)} (${formatLength(song.seconds)}, ${note})`;
			return item;
		}));
		if (focusedValue !== undefined) {
			library.querySelector(`input[value="${focusedValue}"]`)?.focus();
		}

		updateCapacity();
	};

	napster.on(library, 'change', updateCapacity);

	const renderCoasters = () => {
		coastersText.textContent = coasters > 0 ? `Coasters made so far: ${coasters}. They are great under a glass of juice.` : '';
	};

	const burn = async () => {
		const chosen = selectedSongs();
		const minutes = sum(chosen.map(song => song.seconds)) / 60;
		const label = labelInput.value.trim() || 'My Mix';
		isBurning = true;
		renderLibrary();
		labelInput.disabled = true;
		disc.hidden = true;
		burner.hidden = false;
		// The burn button is disabled while it burns, so the focus goes to the burner, which tells what to do.
		burner.focus();
		napster.say('Burning! Do not touch anything!', burnStatus);

		let buffer = 100;
		let written = 0;
		const duration = (6 + (minutes * 0.25)) * 1000;
		const start = performance.now();
		let lastTime = start;
		let lastPointer;

		// The first moment after the click is not counted, as the hand is still on the mouse.
		const isCounting = () => performance.now() - start > 700;

		const shake = amount => {
			if (isCounting()) {
				buffer -= amount;
			}
		};

		const listeners = new AbortController();
		const {signal} = listeners;
		napster.on(document, 'pointermove', event => {
			if (lastPointer) {
				shake(Math.hypot(event.clientX - lastPointer.x, event.clientY - lastPointer.y) * 0.2);
			}

			lastPointer = {x: event.clientX, y: event.clientY};
		}, {signal});
		napster.on(document, 'wheel', () => {
			shake(12);
		}, {signal, passive: true});
		napster.on(document, 'scroll', () => {
			shake(4);
		}, {signal, passive: true});
		napster.on(document, 'keydown', () => {
			shake(15);
		}, {signal});

		const isDone = await new Promise(resolve => {
			const frame = time => {
				// The computer fills the buffer again, but not as fast as a restless hand empties it.
				buffer = Math.min(buffer + ((time - lastTime) / 1000 * 18), 100);
				lastTime = time;
				written = Math.min((time - start) / duration, 1);
				bufferFill.style.width = `${Math.max(buffer, 0)}%`;
				if (buffer < 30) {
					bufferFill.dataset.state = 'low';
				} else {
					delete bufferFill.dataset.state;
				}

				writtenFill.style.width = `${written * 100}%`;
				if (buffer <= 0) {
					resolve(false);
				} else if (written >= 1) {
					resolve(true);
				} else {
					requestAnimationFrame(frame);
				}
			};

			requestAnimationFrame(frame);
		});

		listeners.abort();
		isBurning = false;
		labelInput.disabled = false;
		burner.hidden = true;
		disc.hidden = false;
		if (isDone) {
			delete disc.dataset.state;
			discLabel.textContent = label;
			disc.setAttribute('aria-label', `A CD-R with “${label}” written on it in marker, with ${plural(chosen.length, 'song')}`);
			napster.say(`Done! “${label}” has ${plural(chosen.length, 'song')}. Give it to your crush.`, burnStatus);
			napster.toast('Your mix CD is done!');
			napster.cheer();
		} else {
			coasters++;
			napster.store('coasters', coasters);
			disc.dataset.state = 'coaster';
			discLabel.textContent = 'COASTER';
			disc.setAttribute('aria-label', 'A ruined CD-R, now a coaster');
			napster.say('Buffer underrun! You touched the computer, and the CD is now a coaster. Try again, and sit still.', burnStatus);
		}

		renderCoasters();
		renderLibrary();
		burnButton.focus();
	};

	napster.on(burnButton, 'click', () => {
		if (!isBurning) {
			burn();
		}
	});

	renderClock();
	renderLibrary();
	renderCoasters();

	return {
		visibilityChanged() {
			updateTimer();
		},
	};
};

export default class extends GeoCitiesElement {
	#napster;

	connected() {
		this.#napster = setUpNapster(this, this.parts);
	}

	visibilityChanged() {
		this.#napster.visibilityChanged();
	}
}
