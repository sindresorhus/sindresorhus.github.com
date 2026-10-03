const feedbackData = JSON.parse(document.querySelector('#feedback-data')?.textContent ?? '{"apps":[],"generalFaqs":[]}');
const apps = feedbackData.apps ?? [];
const generalFaqs = feedbackData.generalFaqs ?? [];

// --- Success page ---

	function initSuccess() {
		if (window.location.search !== '?success') {
			return false;
		}

		$('#main').html(`
			<div class="feedback-success">
				<div class="feedback-success-icon">
					<svg class="feedback-success-check" xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
				</div>
				<div>
					<h1 class="feedback-success-title">Message sent!</h1>
					<p class="feedback-success-message">Thanks for reaching out. I read every message and will get back to you soon. When you get my reply, please respond in that email thread instead of sending a new message.</p>
				</div>
				<p class="feedback-success-redirect">Taking you to the apps page…</p>
			</div>
		`);

		setTimeout(() => {
			window.location.href = 'https://sindresorhus.com/apps';
		}, 10000);

		return true;
	}

	// --- Product UI (icon, title, additional info links) ---

	function initProductUI() {
		const params = new URL(location.href).searchParams;
		if (!params.has('product')) {
			return;
		}

		const product = params.get('product');
		const app = apps.find(app => app.title === product);

		$('title').text(`Feedback & Support for ${product} — Sindre Sorhus`);
		$('#product-name').text(product);

		if (app) {
			$('#app-icon').css('visibility', 'visible').attr('src', app.iconUrl);
			// Update the browser tab favicon to match the selected app
			document.querySelector('link[rel="icon"]')?.setAttribute('href', app.iconUrl);
		}

		const additionalInfo = $('#additional-info');

		if (app?.repoUrl) {
			const searchParams = new URLSearchParams();
			searchParams.append('body', `<\!--\nProvide your feedback below. Include as many details as possible.\n-->\n\n\n\n---\n${params.get('metadata') ?? ''}`.trim());
			const url = `${app.repoUrl}/issues/new?${searchParams}`;
			additionalInfo.append(`
				If you have a GitHub account, <a href="${url}" target="_blank" rel="noopener noreferrer">open an issue on the repo</a> instead.
			`);
		}

		if (app?.hasFaqSection) {
			additionalInfo.append(`
				See the <a href="${app.url}#faq">app's frequently asked questions (FAQs)</a> and the <a href="/apps/faq">general FAQs</a> in case your question has already been answered.\nMake sure you are on the latest version and try to restart your device.\nIf the app crashed, it would be very helpful if you could send a <a href="/apps/faq#crash-report">crash report</a>.
			`);
		}

		if (app?.feedbackNote) {
			additionalInfo.append(`<div>${app.feedbackNote}</div>`);
		}

		if (additionalInfo.children().length > 0) {
			additionalInfo.show();
		}
	}

	// --- URL params: inject hidden fields + pre-fill email/message ---

	// Safari / Firefox fallback via `navigator.platform`
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

	// Collects the browser and OS details that help diagnose a report
	async function environmentInfo() {
		// Chromium-only. Safari and Firefox do not expose `userAgentData` yet, so they fall back to the UA string.
		const highEntropy = await navigator.userAgentData?.getHighEntropyValues(['platformVersion']).catch(() => undefined);

		// The OS name in the UA string is frozen in modern browsers, so prefer `userAgentData.platform`
		const platform = navigator.userAgentData?.platform ?? detectPlatform();

		// Safari 26+ uses the OS version as its version number on all Apple platforms. WebKitGTK fakes a high version to pass browser checks, so non-Apple platforms are excluded.
		const isApplePlatform = ['macOS', 'iOS'].includes(platform);
		const safari = navigator.userAgent.match(/Version\/([\d.]+).*Safari/);
		const safariOSVersion = isApplePlatform && safari && Number.parseInt(safari[1], 10) >= 26 ? safari[1] : undefined;

		// Windows reports the `Windows.Foundation.UniversalApiContract` version, not the OS version, and Linux reports nothing
		const platformVersion = ['macOS', 'iOS', 'Android', 'Chrome OS'].includes(platform) ? highEntropy?.platformVersion : undefined;

		// `userAgentData` is available in Chromium-based browsers
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
			document.referrer && `Referrer: ${(() => {
				try {
					const url = new URL(document.referrer);
					if (url.hostname === 'sindresorhus.com' || url.hostname === 'www.sindresorhus.com') {
						return url.pathname + url.search + url.hash;
					}
				} catch {}
				return document.referrer;
			})()}`,
		].filter(Boolean).join('\n');
	}

	async function applyUrlParams() {
		const params = new URL(location.href).searchParams;
		const form = $('#feedback-form');

		form.append(
			$('<input type="hidden" name="timestamp">').val(Date.now())
		);

		// Auto-collect environment info when no app-provided metadata is present
		if (!params.has('metadata')) {
			form.append($('<input type="hidden" name="metadata">').val(await environmentInfo()));
		}

		// Include all the existing search params as hidden inputs
		for (const [key, value] of params) {
			if (key === 'emailField') {
				form.find('[name="email"]').val(value);
				continue;
			}

			if (key === 'messageField') {
				form.find('[name="message"]').val(value).get(0).setSelectionRange(0, 0);
				continue;
			}

			if (key === 'extraInfo') {
				form.append(
					$('<textarea style="display:none" readonly></textarea>').attr('name', key).text(value)
				);
				continue;
			}

			form.append(
				$('<input type="hidden">').attr('name', key).val(value)
			);
		}

		// Clean up metadata param from the visible URL after it's been injected
		if (params.get('metadata')) {
			const url = new URL(window.location);
			url.searchParams.delete('metadata');
			window.history.replaceState({}, '', url);
		}
	}

	// --- Attachments ---

	function initAttachments() {
		const attachmentsInput = document.querySelector('#attachments-input');
		const fileList = document.querySelector('#file-list');
		if (!attachmentsInput) {
			return;
		}

		const IMAGE_EXTENSIONS = new Set(['png', 'jpg', 'jpeg', 'jxl', 'gif', 'webp', 'heic', 'heif', 'avif', 'svg']);
		const FILE_ICON = `<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0"><path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><polyline points="13 2 13 9 20 9"/></svg>`;
		const CLOSE_ICON = `<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 10 10" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="1" y1="1" x2="9" y2="9"/><line x1="9" y1="1" x2="1" y2="9"/></svg>`;

		// Source-of-truth array; the file input's FileList is rebuilt from this on every change
		let attachedFiles = [];

		function formatSize(bytes) {
			return bytes < 1024 * 1024
				? `${(bytes / 1024).toFixed(0)} KB`
				: `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
		}

		// Rebuild the file input's FileList from our source-of-truth array
		function syncFilesToInput() {
			const dataTransfer = new DataTransfer();
			for (const file of attachedFiles) {
				dataTransfer.items.add(file);
			}
			attachmentsInput.files = dataTransfer.files;
		}

		function renderFileList() {
			fileList.innerHTML = '';
			for (const [index, file] of attachedFiles.entries()) {
				const extension = file.name.split('.').pop().toLowerCase();

				const chip = document.createElement('span');
				chip.className = 'attachment-chip';

				if (IMAGE_EXTENSIONS.has(extension)) {
					const thumbnail = document.createElement('img');
					thumbnail.style.cssText = 'width:20px;height:20px;object-fit:cover;border-radius:3px;flex-shrink:0';
					thumbnail.src = URL.createObjectURL(file);
					chip.append(thumbnail);
				} else {
					const iconWrapper = document.createElement('span');
					iconWrapper.innerHTML = FILE_ICON;
					chip.append(iconWrapper);
				}

				const nameWrapper = document.createElement('span');
				nameWrapper.className = 'attachment-name-wrap';
				const nameText = document.createElement('span');
				nameText.className = 'attachment-name';
				nameText.textContent = file.name;
				const sizeText = document.createElement('span');
				sizeText.className = 'attachment-size';
				sizeText.textContent = formatSize(file.size);
				nameWrapper.append(nameText, sizeText);
				chip.append(nameWrapper);

				const removeButton = document.createElement('button');
				removeButton.type = 'button';
				removeButton.className = 'attachment-remove';
				removeButton.setAttribute('aria-label', `Remove ${file.name}`);
				removeButton.dataset.index = index;
				removeButton.innerHTML = CLOSE_ICON;
				chip.append(removeButton);

				fileList.append(chip);
			}
		}

		attachmentsInput.addEventListener('change', () => {
			// Merge newly selected files into the accumulated list (skip duplicates by name+size)
			for (const file of attachmentsInput.files) {
				const isDuplicate = attachedFiles.some(existingFile => existingFile.name === file.name && existingFile.size === file.size);
				if (!isDuplicate) {
					attachedFiles.push(file);
				}
			}

			syncFilesToInput();
			renderFileList();
		});

		fileList.addEventListener('click', event => {
			const button = event.target.closest('button[data-index]');
			if (!button) {
				return;
			}
			attachedFiles.splice(Number(button.dataset.index), 1);
			syncFilesToInput();
			renderFileList();
		});
	}

	// --- Auto-growing textarea ---

	// Makes the textarea grow with its content instead of scrolling
	function initAutoGrowTextarea(textarea) {
		textarea.style.overflowY = 'hidden';
		const minHeight = textarea.offsetHeight;

		function resizeTextarea() {
			textarea.style.height = `${minHeight}px`;
			textarea.style.height = `${Math.max(textarea.scrollHeight, minHeight)}px`;
		}

		textarea.addEventListener('input', resizeTextarea);
		return resizeTextarea;
	}

	// --- Email domain typo detection ---

	function initEmailTypoDetection(emailInput) {
		const EMAIL_TYPOS = {
			'gmial.com': 'gmail.com', 'gmal.com': 'gmail.com', 'gmil.com': 'gmail.com',
			'gnail.com': 'gmail.com', 'gamil.com': 'gmail.com', 'gmai.com': 'gmail.com',
			'gmail.co': 'gmail.com', 'gmail.con': 'gmail.com', 'gmail.cm': 'gmail.com',
			'gmaill.com': 'gmail.com', 'gmaul.com': 'gmail.com', 'gmeil.com': 'gmail.com',
			'yaho.com': 'yahoo.com', 'yahooo.com': 'yahoo.com', 'yhaoo.com': 'yahoo.com',
			'yahoo.con': 'yahoo.com', 'yaoo.com': 'yahoo.com', 'yahol.com': 'yahoo.com',
			'hotmial.com': 'hotmail.com', 'hotmai.com': 'hotmail.com', 'hotmil.com': 'hotmail.com',
			'homail.com': 'hotmail.com', 'hotmail.con': 'hotmail.com', 'hotmali.com': 'hotmail.com',
			'outlok.com': 'outlook.com', 'outloook.com': 'outlook.com', 'outlook.con': 'outlook.com',
			'iclould.com': 'icloud.com', 'icoud.com': 'icloud.com', 'iclod.com': 'icloud.com',
		};

		const TLD_TYPOS = {'.con': '.com', '.cmo': '.com', '.ocm': '.com', '.ney': '.net'};

		function suggestEmailFix(email) {
			const atIndex = email.lastIndexOf('@');
			if (atIndex === -1) {
				return;
			}
			const localPart = email.slice(0, atIndex);
			if (
				localPart.endsWith('-') ||
				localPart.startsWith('.') ||
				localPart.endsWith('.') ||
				localPart.includes('..')
			) {
				return 'Your email address looks incorrect.';
			}
			const domain = email.slice(atIndex + 1).toLowerCase();
			if (EMAIL_TYPOS[domain]) {
				return `Did you mean ${email.slice(0, atIndex + 1)}${EMAIL_TYPOS[domain]}?`;
			}
			for (const [badTld, goodTld] of Object.entries(TLD_TYPOS)) {
				if (domain.endsWith(badTld)) {
					return `Did you mean ${email.slice(0, atIndex + 1)}${domain.slice(0, -badTld.length)}${goodTld}?`;
				}
			}
		}

		const emailWarning = document.createElement('p');
		emailWarning.className = 'email-warning hidden';
		emailWarning.role = 'alert';
		emailInput.insertAdjacentElement('afterend', emailWarning);

		let emailDebounceTimer;

		emailInput.addEventListener('input', () => {
			emailWarning.classList.add('hidden');
			clearTimeout(emailDebounceTimer);
			emailDebounceTimer = setTimeout(() => {
				const warning = suggestEmailFix(emailInput.value.trim());
				if (warning) {
					emailWarning.textContent = warning;
					emailWarning.classList.remove('hidden');
				}
			}, 600);
		});
	}

	// --- Submit: loading state + clear draft ---

	function initSubmit() {
		$('#feedback-form').on('submit', () => {
			const button = document.querySelector('#submit-button');
			// Lock the width before changing text so it doesn't resize
			button.style.width = `${button.offsetWidth}px`;
			$(button).prop('disabled', true).text('Sending…');
		});
	}

	if (!initSuccess()) {
		initProductUI();
		applyUrlParams();
		initAttachments();

		const textarea = document.querySelector('[name="message"]');
		if (textarea) {
			initAutoGrowTextarea(textarea);
			const emailInput = document.querySelector('[name="email"]');
			initEmailTypoDetection(emailInput);
			initSubmit();
		}
	}

/*
	FAQ suggestion engine: as the user types, we tokenize their message (3+ char words, minus stopwords), expand with synonyms, and score each FAQ using TF-IDF weighting (rare word matches score higher). Results are sorted by pinned status, match count, and score, then deduplicated. Minimum 2 matching words required (1 for pinned FAQs or single-word queries).
	*/

	const params = new URL(location.href).searchParams;
	let allFaqs = generalFaqs;

	if (params.has('product')) {
		const product = params.get('product');
		const app = apps.find(app => app.title === product);
		if (app) {
			// Drop FAQs that are restricted to platforms this app doesn't support
			allFaqs = allFaqs.filter(faq => !faq.platforms || faq.platforms.some(platform => app.platforms.includes(platform)));

			if (app.faqHeadings?.length > 0) {
				const appFaqs = app.faqHeadings.map(heading => ({...heading, question: heading.text, url: `${app.url}#${heading.slug}`, isAppSpecific: true}));
				allFaqs = [...appFaqs, ...allFaqs];
			}
		}
	}

	const pinnedUrls = [
		'/apps/faq#refund',
		'/apps/faq#app-problem',
		'/apps/faq#app-not-showing-in-menu-bar',
		'/velja#fn-key-not-detected',
		'/velja#builtin-apps-requests',
	];

	// Common English words that carry no search signal in a tech support context
	const STOPWORDS = new Set([
		'ago', 'all', 'also', 'and', 'any', 'are', 'about', 'after', 'again', 'back',
		'been', 'being', 'both', 'but', 'can',
		'come', 'could', 'day', 'did', 'does', 'done', 'each', 'even', 'ever', 'every',
		'far', 'feel', 'few', 'find', 'first', 'for', 'from', 'get', 'give', 'got',
		'had', 'has', 'have', 'her', 'here', 'his', 'how', 'into', 'its',
		'just', 'keep', 'know', 'last', 'let', 'like', 'look', 'made', 'make',
		'many', 'may', 'more', 'most', 'much', 'need', 'never', 'new', 'not', 'now',
		'off', 'often', 'old', 'onto', 'other', 'our', 'over', 'own',
		'please', 'said', 'same', 'say', 'see', 'seem', 'should', 'since',
		'some', 'still', 'such', 'take', 'tell', 'than', 'that', 'the',
		'their', 'them', 'then', 'there', 'these', 'they', 'thing', 'think', 'this', 'those',
		'too', 'try', 'turn', 'upon', 'use', 'used', 'using', 'very',
		'want', 'was', 'way', 'were', 'what', 'when', 'where', 'which',
		'while', 'who', 'why', 'will', 'with', 'would', 'yet', 'you', 'your',
	]);

	// Term groups where all terms are interchangeable during FAQ matching
	const SYNONYM_GROUPS = [
		['icloud', 'sync', 'syncing'],
		['screen', 'display', 'monitor'],
		['crash', 'freeze', 'hang'],
		['delete', 'remove'],
		['settings', 'preferences'],
		['notification', 'alert', 'banner'],
		['shortcut', 'hotkey'],
		['update', 'upgrade'],
		['storage', 'space'],
		['account', 'profile'],
		['theme', 'appearance'],
		['location', 'gps'],
		['picture', 'image', 'photo'],
	];

	// One-directional synonyms: key expands to values, but not the reverse
	const SYNONYMS = new Map([
		['broken', ['bug', 'error', 'crash']],
		['slow', ['performance', 'battery']],
		['buy', ['purchase', 'subscription']],
		['stuck', ['freeze']],
		['wifi', ['network', 'connection']],
		['password', ['authentication']],
	]);

	for (const group of SYNONYM_GROUPS) {
		for (const term of group) {
			SYNONYMS.set(term, group.filter(t => t !== term));
		}
	}

	// Strip apostrophes before tokenizing so "doesn't" → "doesnt" (harmless non-match)
	// rather than "doesn" which could trigger false partial matches
	function tokenize(text) {
		return (text.toLowerCase().replace(/'/g, '').match(/\b\w{3,}\b/g) ?? []).filter(word => !STOPWORDS.has(word));
	}

	// Returns true if the words share a common prefix (handles sync/syncing, crash/crashed, etc.)
	function wordMatches(queryWord, faqWord) {
		return faqWord === queryWord || faqWord.startsWith(queryWord) || queryWord.startsWith(faqWord);
	}

	// Expands a word list with synonyms so cross-term matches are possible
	function expandWithSynonyms(words) {
		const expanded = new Set(words);
		for (const word of words) {
			const synonyms = SYNONYMS.get(word);
			if (synonyms) {
				for (const synonym of synonyms) {
					expanded.add(synonym);
				}
			}
		}

		return [...expanded];
	}

	// All searchable words for a FAQ entry (question + keywords + synonyms)
	function faqTokens(faq) {
		return expandWithSynonyms([...tokenize(faq.question), ...tokenize(faq.keywords?.join(' ') ?? '')]);
	}

	function buildDocumentFrequency(faqs) {
		const documentFrequency = new Map();
		for (const faq of faqs) {
			for (const word of new Set(tokenize(faq.question))) {
				documentFrequency.set(word, (documentFrequency.get(word) ?? 0) + 1);
			}
		}
		return documentFrequency;
	}

	// All meaningful words across all FAQs (questions + keywords + synonyms) — used to detect
	// "unknown" query words like "didnt"/"doesnt" that shouldn't count toward minMatches
	function buildCorpus(faqs) {
		const corpus = new Set();
		for (const faq of faqs) {
			for (const word of faqTokens(faq)) corpus.add(word);
		}

		return corpus;
	}

	// Score each FAQ against the query words; returns [{faq, score, matchCount}]
	function scoreFaqs(faqs, queryWords, documentFrequencyIndex) {
		const faqCount = faqs.length;
		return faqs.map(faq => {
			const words = faqTokens(faq);
			let score = 0;
			let matchCount = 0;
			for (const queryWord of queryWords) {
				if (words.some(faqWord => wordMatches(queryWord, faqWord))) {
					// Rare words (low document frequency) score higher than common words
					score += Math.log((faqCount + 1) / ((documentFrequencyIndex.get(queryWord) ?? 0) + 1));
					matchCount++;
				}
			}
			return {faq, score, matchCount};
		});
	}

	// Sort by pinned > higher matchCount > app-specific > score; filter to minMatches threshold
	// Pinned FAQs only need 1 match — they are high-priority by design
	function sortAndFilter(scored, minMatches) {
		return scored
			.filter(({score, matchCount, faq}) => score > 0 && matchCount >= (pinnedUrls.includes(faq.url) ? 1 : minMatches))
			.sort((itemA, itemB) => {
				const pinnedIndexA = pinnedUrls.indexOf(itemA.faq.url);
				const pinnedIndexB = pinnedUrls.indexOf(itemB.faq.url);
				if (pinnedIndexA !== -1 || pinnedIndexB !== -1) {
					if (pinnedIndexA === -1) {
						return 1;
					}
					if (pinnedIndexB === -1) {
						return -1;
					}
					return pinnedIndexA - pinnedIndexB;
				}

				if (itemA.faq.isAppSpecific !== itemB.faq.isAppSpecific) {
					if (itemA.matchCount !== itemB.matchCount) {
						return itemB.matchCount - itemA.matchCount;
					}

					return itemA.faq.isAppSpecific ? -1 : 1;
				}

				return itemB.score - itemA.score;
			})
			.map(({faq}) => faq);
	}

	// Jaccard similarity on raw (unfiltered) question words — used for deduplication only
	function questionSimilarity(textA, textB) {
		const wordsA = new Set(textA.toLowerCase().match(/\w+/g) ?? []);
		const wordsB = new Set(textB.toLowerCase().match(/\w+/g) ?? []);
		const intersection = [...wordsA].filter(word => wordsB.has(word)).length;
		return intersection / (wordsA.size + wordsB.size - intersection);
	}

	// Remove general FAQs that are near-duplicates of an app-specific result
	function deduplicateResults(results) {
		const appSpecificResults = results.filter(faq => faq.isAppSpecific);
		if (appSpecificResults.length === 0) {
			return results;
		}

		return results.filter(faq =>
			faq.isAppSpecific || !appSpecificResults.some(appSpecificFaq =>
				questionSimilarity(faq.question, appSpecificFaq.question) >= 0.6
			)
		);
	}

	let documentFrequencyIndex;
	let corpusIndex;

	function findMatchingFaqs(query, faqs) {
		documentFrequencyIndex ??= buildDocumentFrequency(faqs);
		corpusIndex ??= buildCorpus(faqs);
		const queryWords = [...new Set(tokenize(query))];
		if (queryWords.length === 0) return [];

		// Only count query words that exist in the FAQ corpus toward the minMatches threshold.
		// Negation words like "didnt", "doesnt", "wont" carry no FAQ signal on their own
		// and should not inflate the requirement (e.g. "didn't launch" → only "launch" is known).
		const knownQueryWords = queryWords.filter(queryWord => {
			for (const corpusWord of corpusIndex) {
				if (wordMatches(queryWord, corpusWord)) {
					return true;
				}
			}

			return false;
		});

		const minMatches = knownQueryWords.length <= 1 ? 1 : 2;
		const scored = scoreFaqs(faqs, queryWords, documentFrequencyIndex);
		const sorted = sortAndFilter(scored, minMatches);
		return deduplicateResults(sorted).slice(0, 4);
	}

	let debounceTimer;
	let dismissed = false;

	const messageTextarea = $('[name="message"]');
	const faqSuggestionsPanel = $('#faq-suggestions');
	const faqList = $('#faq-list');
	const crashWarning = $('#crash-warning');

	function showSuggestions() {
		faqSuggestionsPanel.prop('hidden', false);
		messageTextarea.attr('aria-expanded', 'true');
	}

	function hideSuggestions() {
		faqSuggestionsPanel.prop('hidden', true);
		messageTextarea.attr('aria-expanded', 'false');
	}

	function dismissSuggestions() {
		dismissed = true;
		hideSuggestions();
	}

	messageTextarea.on('input', function () {
		if (dismissed) {
			return;
		}

		clearTimeout(debounceTimer);

		debounceTimer = setTimeout(() => {
			crashWarning.prop('hidden', !/\bcrash/i.test(this.value));
			const query = this.value;
			const matches = findMatchingFaqs(query, allFaqs);
			if (matches.length === 0) {
				hideSuggestions();
				return;
			}

			faqList.empty();
			for (const {question, url} of matches) {
				faqList.append(`<li><a href="${url}" target="_blank" rel="noopener noreferrer" class="faq-suggestion-link">→ ${question}</a></li>`);
			}

			showSuggestions();
		}, 350);
	});

	// ArrowDown from textarea moves focus into the suggestion list
	messageTextarea.on('keydown', function (event) {
		if (faqSuggestionsPanel.prop('hidden')) {
			return;
		}
		if (event.key === 'ArrowDown') {
			event.preventDefault();
			faqList.find('a').first().focus();
		} else if (event.key === 'Escape') {
			dismissSuggestions();
		}
	});

	// Arrow keys navigate between suggestion links; Escape dismisses
	faqList.on('keydown', 'a', function (event) {
		if (event.key === 'ArrowDown') {
			event.preventDefault();
			const nextLink = $(this).closest('li').next().find('a');
			if (nextLink.length) {
				nextLink.focus();
			}
		} else if (event.key === 'ArrowUp') {
			event.preventDefault();
			const previousLink = $(this).closest('li').prev().find('a');
			if (previousLink.length) {
				previousLink.focus();
			} else {
				// At the top — return focus to the textarea
				messageTextarea.focus();
			}
		} else if (event.key === 'Escape') {
			dismissSuggestions();
			messageTextarea.focus();
		}
	});

	$('#faq-dismiss').on('click', dismissSuggestions);
