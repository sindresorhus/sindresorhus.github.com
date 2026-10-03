const feedbackData = JSON.parse(document.querySelector('#feedback-data')?.textContent ?? '{}');
const apps = feedbackData.apps ?? [];
const generalQuestions = feedbackData.generalQuestions ?? [];
const stopwords = new Set(feedbackData.stopwords ?? []);
const parameters = new URL(location.href).searchParams;
const product = parameters.get('product');
const app = apps.find(app => app.title === product);

// Clones the content of a `<template>` in the page.
function cloneTemplate(id) {
	return document.querySelector(`#${id}`).content.firstElementChild.cloneNode(true);
}

// --- Success page ---

function showSuccess() {
	document.querySelector('#main').replaceChildren(cloneTemplate('success-template'));

	setTimeout(() => {
		location.href = '/apps';
	}, 10_000);
}

// --- The selected app (icon, title, extra help) ---

function showProduct() {
	document.title = `Feedback & Support for ${product} — Sindre Sorhus`;
	document.querySelector('#product-name').textContent = product;

	if (!app) {
		return;
	}

	document.querySelector('#app-icon').src = app.iconUrl;
	// The browser tab shows the icon of the app.
	document.querySelector('link[rel="icon"]')?.setAttribute('href', app.iconUrl);

	const additionalInfo = document.querySelector('#additional-info');

	if (app.repoUrl) {
		const searchParameters = new URLSearchParams({
			body: `<!--\nProvide your feedback below. Include as many details as possible.\n-->\n\n\n\n---\n${parameters.get('metadata') ?? ''}`.trim(),
		});

		const paragraph = cloneTemplate('repository-template');
		paragraph.querySelector('[data-repository-link]').href = `${app.repoUrl}/issues/new?${searchParameters}`;
		additionalInfo.append(paragraph);
	}

	if (app.hasFaqSection) {
		const paragraph = cloneTemplate('app-faq-template');
		paragraph.querySelector('[data-app-faq-link]').href = `${app.url}#faq`;
		additionalInfo.append(paragraph);
	}

	// HTML that the site generator rendered from the Markdown of the app, not visitor input.
	if (app.feedbackNote) {
		additionalInfo.insertAdjacentHTML('beforeend', `<div>${app.feedbackNote}</div>`);
	}
}

// --- Hidden fields: the URL parameters and the environment of the visitor ---

// Safari and Firefox do not have `userAgentData`, so the platform comes from `navigator.platform`.
function detectPlatform() {
	const platform = navigator.platform ?? '';

	if (/iPhone|iPad|iPod/.test(platform) || /iPhone|iPad/.test(navigator.userAgent)) {
		return 'iOS';
	}

	if (/Mac/.test(platform)) {
		return 'macOS';
	}

	if (/Win/.test(platform)) {
		return 'Windows';
	}

	if (/Android/.test(navigator.userAgent)) {
		return 'Android';
	}

	if (/Linux/.test(platform)) {
		return 'Linux';
	}

	return 'Unknown';
}

// The referrer path for pages of this site, and the full URL for other sites.
function referrerText() {
	try {
		const url = new URL(document.referrer);
		if (url.hostname === 'sindresorhus.com' || url.hostname === 'www.sindresorhus.com') {
			return url.pathname + url.search + url.hash;
		}
	} catch {}

	return document.referrer;
}

// The browser and OS details that help diagnose a report.
async function environmentInfo() {
	// Chromium only. Safari and Firefox fall back to the user agent string.
	const highEntropy = await navigator.userAgentData?.getHighEntropyValues(['platformVersion']).catch(() => undefined);

	// The OS name in the user agent string is frozen in modern browsers, so `userAgentData.platform` comes first.
	const platform = navigator.userAgentData?.platform ?? detectPlatform();

	// Safari 26 and later uses the OS version as its version on all Apple platforms. WebKitGTK fakes a high version to pass browser checks, so other platforms are left out.
	const isApplePlatform = ['macOS', 'iOS'].includes(platform);
	const safari = navigator.userAgent.match(/Version\/([\d.]+).*Safari/);
	const safariOSVersion = isApplePlatform && safari && Number.parseInt(safari[1], 10) >= 26 ? safari[1] : undefined;

	// Windows reports the version of `Windows.Foundation.UniversalApiContract` instead of the OS version, and Linux reports nothing.
	const platformVersion = ['macOS', 'iOS', 'Android', 'Chrome OS'].includes(platform) ? highEntropy?.platformVersion : undefined;

	const brand = navigator.userAgentData?.brands?.find(item => item.brand !== 'Chromium' && !item.brand.startsWith('Not'));
	const firefox = navigator.userAgent.match(/Firefox\/([\d.]+)/);

	let browser = 'Unknown';
	if (brand) {
		browser = `${brand.brand} ${brand.version}`;
	} else if (safariOSVersion) {
		browser = 'Safari';
	} else if (safari) {
		browser = `Safari ${safari[1]}`;
	} else if (firefox) {
		browser = `Firefox ${firefox[1]}`;
	}

	return [
		`OS: ${[platform, platformVersion ?? safariOSVersion].filter(Boolean).join(' ')}`,
		`Browser: ${browser}`,
		`Screen: ${screen.width}×${screen.height} @${window.devicePixelRatio}x`,
		`Timezone: ${Intl.DateTimeFormat().resolvedOptions().timeZone}`,
		`Locale: ${navigator.language}`,
		`Languages: ${navigator.languages.join(', ')}`,
		navigator.deviceMemory && `Device memory: ${navigator.deviceMemory} GB`,
		document.referrer && `Referrer: ${referrerText()}`,
	].filter(Boolean).join('\n');
}

function addHiddenField(form, name, value) {
	const input = document.createElement('input');
	input.type = 'hidden';
	input.name = name;
	input.value = value;
	form.append(input);
}

async function addHiddenFields(form) {
	addHiddenField(form, 'timestamp', Date.now());

	// Every URL parameter is sent along, and some fill in the form.
	for (const [key, value] of parameters) {
		if (key === 'emailField') {
			form.elements.email.value = value;
		} else if (key === 'messageField') {
			form.elements.message.value = value;
			form.elements.message.setSelectionRange(0, 0);
		} else if (key === 'extraInfo') {
			// A text area, as the text can have several lines.
			const textarea = document.createElement('textarea');
			textarea.name = key;
			textarea.hidden = true;
			textarea.readOnly = true;
			textarea.value = value;
			form.append(textarea);
		} else {
			addHiddenField(form, key, value);
		}
	}

	// The metadata is in the form now, so it is removed from the visible URL.
	if (parameters.get('metadata')) {
		const url = new URL(location.href);
		url.searchParams.delete('metadata');
		history.replaceState({}, '', url);
	}

	// Apps send their own metadata. Otherwise, the environment of the browser is sent. It is added last, as it waits for the browser, so the fields above are filled before the visitor starts typing.
	if (!parameters.has('metadata')) {
		addHiddenField(form, 'metadata', await environmentInfo());
	}
}

// --- Attachments ---

function setUpAttachments() {
	const input = document.querySelector('#attachments-input');
	const fileList = document.querySelector('#file-list');
	const imageExtensions = new Set(['png', 'jpg', 'jpeg', 'jxl', 'gif', 'webp', 'heic', 'heif', 'avif', 'svg']);

	// The files of the input are rebuilt from this list, so files can be added in several picks and removed one by one.
	const files = [];

	const formatSize = bytes => bytes < 1024 * 1024
		? `${(bytes / 1024).toFixed(0)} KB`
		: `${(bytes / (1024 * 1024)).toFixed(1)} MB`;

	const update = () => {
		const dataTransfer = new DataTransfer();
		for (const file of files) {
			dataTransfer.items.add(file);
		}

		input.files = dataTransfer.files;

		fileList.replaceChildren(...files.map((file, index) => {
			const chip = cloneTemplate('attachment-template');
			const thumbnail = chip.querySelector('img');

			if (imageExtensions.has(file.name.split('.').pop().toLowerCase())) {
				thumbnail.src = URL.createObjectURL(file);
				thumbnail.addEventListener('load', () => {
					URL.revokeObjectURL(thumbnail.src);
				}, {once: true});
				chip.querySelector('svg').remove();
			} else {
				thumbnail.remove();
			}

			chip.querySelector('[data-name]').textContent = file.name;
			chip.querySelector('[data-size]').textContent = formatSize(file.size);

			const removeButton = chip.querySelector('button');
			removeButton.ariaLabel = `Remove ${file.name}`;
			removeButton.addEventListener('click', () => {
				files.splice(index, 1);
				update();
			});

			return chip;
		}));
	};

	input.addEventListener('change', () => {
		// Files that are already attached, by name and size, are skipped.
		for (const file of input.files) {
			if (!files.some(existingFile => existingFile.name === file.name && existingFile.size === file.size)) {
				files.push(file);
			}
		}

		update();
	});
}

// --- Email typos ---

function setUpEmailTypoDetection(emailInput) {
	const domainTypos = {
		'gmial.com': 'gmail.com',
		'gmal.com': 'gmail.com',
		'gmil.com': 'gmail.com',
		'gnail.com': 'gmail.com',
		'gamil.com': 'gmail.com',
		'gmai.com': 'gmail.com',
		'gmail.co': 'gmail.com',
		'gmail.con': 'gmail.com',
		'gmail.cm': 'gmail.com',
		'gmaill.com': 'gmail.com',
		'gmaul.com': 'gmail.com',
		'gmeil.com': 'gmail.com',
		'yaho.com': 'yahoo.com',
		'yahooo.com': 'yahoo.com',
		'yhaoo.com': 'yahoo.com',
		'yahoo.con': 'yahoo.com',
		'yaoo.com': 'yahoo.com',
		'yahol.com': 'yahoo.com',
		'hotmial.com': 'hotmail.com',
		'hotmai.com': 'hotmail.com',
		'hotmil.com': 'hotmail.com',
		'homail.com': 'hotmail.com',
		'hotmail.con': 'hotmail.com',
		'hotmali.com': 'hotmail.com',
		'outlok.com': 'outlook.com',
		'outloook.com': 'outlook.com',
		'outlook.con': 'outlook.com',
		'iclould.com': 'icloud.com',
		'icoud.com': 'icloud.com',
		'iclod.com': 'icloud.com',
	};

	const topLevelDomainTypos = {
		'.con': '.com',
		'.cmo': '.com',
		'.ocm': '.com',
		'.ney': '.net',
	};

	const warningFor = email => {
		const atIndex = email.lastIndexOf('@');
		if (atIndex === -1) {
			return;
		}

		const localPart = email.slice(0, atIndex);
		if (localPart.endsWith('-') || localPart.startsWith('.') || localPart.endsWith('.') || localPart.includes('..')) {
			return 'Your email address looks incorrect.';
		}

		const domain = email.slice(atIndex + 1).toLowerCase();
		if (domainTypos[domain]) {
			return `Did you mean ${email.slice(0, atIndex + 1)}${domainTypos[domain]}?`;
		}

		for (const [typo, correction] of Object.entries(topLevelDomainTypos)) {
			if (domain.endsWith(typo)) {
				return `Did you mean ${email.slice(0, atIndex + 1)}${domain.slice(0, -typo.length)}${correction}?`;
			}
		}
	};

	const emailWarning = document.querySelector('#email-warning');
	let timer;

	emailInput.addEventListener('input', () => {
		emailWarning.hidden = true;
		clearTimeout(timer);

		timer = setTimeout(() => {
			const warning = warningFor(emailInput.value.trim());
			if (warning) {
				emailWarning.textContent = warning;
				emailWarning.hidden = false;
			}
		}, 600);
	});
}

/*
FAQ suggestions: while the visitor types, the message is split into words (three or more letters, without stopwords), and each question is scored by the words it shares with the message. Rare words count more (TF-IDF). The site generator prepares the words of each question, with synonyms. Pinned questions come first, then questions with more matching words, then app questions, then higher scores. A question needs two matching words, or one for pinned questions and for messages with only one known word.
*/

function setUpSuggestions(textarea) {
	let questions = generalQuestions;

	if (app) {
		// Questions about platforms the app is not on are left out.
		questions = questions.filter(question => !question.platforms || question.platforms.some(platform => app.platforms.includes(platform)));
		questions = [...(app.questions ?? []).map(question => ({...question, isAppSpecific: true})), ...questions];
	}

	// The words a message can match: the words of the question, and its keywords and synonyms.
	questions = questions.map(question => ({...question, words: [...question.questionWords, ...question.extraWords]}));

	// How many questions each word is in. Rare words count more.
	const questionCounts = new Map();
	for (const question of questions) {
		for (const word of new Set(question.questionWords)) {
			questionCounts.set(word, (questionCounts.get(word) ?? 0) + 1);
		}
	}

	const allWords = new Set(questions.flatMap(question => question.words));

	// Apostrophes are removed first, as in the site generator, so “doesn't” becomes “doesnt”.
	const wordsIn = text => (text.toLowerCase().replaceAll('\'', '').match(/[a-z\d_]{3,}/g) ?? []).filter(word => !stopwords.has(word));

	// Words with the same start match, like “sync” and “syncing”.
	const wordsMatch = (first, second) => first.startsWith(second) || second.startsWith(first);

	// Jaccard similarity of all the words of two questions, to leave out a general question that repeats an app question.
	const similarity = (first, second) => {
		const firstWords = new Set(first.toLowerCase().match(/\w+/g) ?? []);
		const secondWords = new Set(second.toLowerCase().match(/\w+/g) ?? []);
		const sharedCount = [...firstWords].filter(word => secondWords.has(word)).length;
		return sharedCount / (firstWords.size + secondWords.size - sharedCount);
	};

	const pinnedRank = question => question.pinnedRank ?? Number.POSITIVE_INFINITY;

	const matchingQuestions = message => {
		const messageWords = [...new Set(wordsIn(message))];

		// Words that no question has, like “didnt”, do not raise the number of words a question needs.
		const knownWords = messageWords.filter(messageWord => [...allWords].some(word => wordsMatch(messageWord, word)));
		const minimumMatchCount = knownWords.length <= 1 ? 1 : 2;

		const results = questions
			.map(question => {
				let score = 0;
				let matchCount = 0;

				for (const messageWord of messageWords) {
					if (question.words.some(word => wordsMatch(messageWord, word))) {
						score += Math.log((questions.length + 1) / ((questionCounts.get(messageWord) ?? 0) + 1));
						matchCount++;
					}
				}

				return {question, score, matchCount};
			})
			.filter(({question, score, matchCount}) => score > 0 && matchCount >= (question.pinnedRank === undefined ? minimumMatchCount : 1))
			.sort((first, second) => {
				if (first.question.pinnedRank !== undefined || second.question.pinnedRank !== undefined) {
					return pinnedRank(first.question) - pinnedRank(second.question);
				}

				if (first.question.isAppSpecific !== second.question.isAppSpecific) {
					if (first.matchCount !== second.matchCount) {
						return second.matchCount - first.matchCount;
					}

					return first.question.isAppSpecific ? -1 : 1;
				}

				return second.score - first.score;
			})
			.map(({question}) => question);

		const appResults = results.filter(question => question.isAppSpecific);

		return results
			.filter(question => question.isAppSpecific || !appResults.some(appQuestion => similarity(question.question, appQuestion.question) >= 0.6))
			.slice(0, 4);
	};

	const panel = document.querySelector('#faq-suggestions');
	const list = document.querySelector('#faq-list');
	const crashWarning = document.querySelector('#crash-warning');
	let isDismissed = false;
	let timer;

	textarea.addEventListener('input', () => {
		clearTimeout(timer);

		timer = setTimeout(() => {
			crashWarning.hidden = !/\bcrash/i.test(textarea.value);

			// After a dismiss, only the crash warning still follows the text.
			if (isDismissed) {
				return;
			}

			const matches = matchingQuestions(textarea.value);
			if (matches.length === 0) {
				panel.hidden = true;
				return;
			}

			list.replaceChildren(...matches.map(({question, url}) => {
				const item = cloneTemplate('suggestion-template');
				item.querySelector('a').href = url;
				item.querySelector('[data-question]').textContent = question;
				return item;
			}));

			panel.hidden = false;
		}, 350);
	});

	document.querySelector('#faq-dismiss').addEventListener('click', () => {
		isDismissed = true;
		panel.hidden = true;
	});
}

if (location.search === '?success') {
	showSuccess();
} else {
	const form = document.querySelector('#feedback-form');

	if (product) {
		showProduct();
	}

	addHiddenFields(form).catch(error => {
		console.error('Could not add the hidden fields:', error);
	});
	setUpAttachments();
	setUpEmailTypoDetection(form.elements.email);
	setUpSuggestions(form.elements.message);

	// The disabled button shows “Sending…”.
	form.addEventListener('submit', () => {
		document.querySelector('#submit-button').disabled = true;
	});
}
