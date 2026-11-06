import {cloneTemplate, scriptData} from '/scripts/dom.js';
import {searchKey, closest} from '/scripts/edit-distance.js';
import {intendedDomain} from '/scripts/email-typos.js';

const {apps} = scriptData('feedback-data');
const parameters = new URLSearchParams(location.search);
const productParameter = parameters.get('product');

// The app is found by one of its names, in any case, like `supercharge` for “Supercharge”, or the name that the app sends, like “Color Picker” for “System Color Picker”.
const productName = productParameter?.toLowerCase();
const app = apps.find(candidate => candidate.names.some(name => name.toLowerCase() === productName));
const product = app?.title ?? productParameter;

// The details that the app sent, like its version. After the first load, they are only in the state of the history entry (`addHiddenFields`).
const appMetadata = parameters.get('metadata') ?? history.state?.metadata;

// The parameters that stay when the visitor picks another app, like `referrer`, but not the app and the `metadata` of the app that sent it. Limitation: the text that the visitor typed is not kept, so “Change App” loses it.
const keptParameters = new URLSearchParams(parameters);
keptParameters.delete('product');
keptParameters.delete('metadata');

// --- The selected app (icon, title, extra help) ---

function showProduct() {
	document.title = `Feedback & Support for ${product} — Sindre Sorhus`;
	const productNameElement = document.querySelector('#product-name');
	productNameElement.textContent = product;
	productNameElement.hidden = false;

	const changeAppLink = document.querySelector('#change-app-link');
	changeAppLink.search = keptParameters;
	changeAppLink.hidden = false;
	document.querySelector('#app-picker').hidden = true;
	const form = document.querySelector('#feedback-form');

	// The notes and the form show now, together with the app and its notes, which this script adds above the form, so the message field does not move after it shows. The browser does not draw before this function ends.
	document.documentElement.setAttribute('data-product-shown', '');

	// The form is hidden until the script in the head marks the page, so `autofocus` is not reliable. Like `autofocus`, it leaves the focus where the visitor already put it. The page does not scroll to the message, so the app and the notes above it stay in view.
	if (document.activeElement === document.body) {
		form.elements.message.focus({preventScroll: true});
	}

	if (!app) {
		return;
	}

	// The suggestions include the questions of the app.
	document.querySelector('#faq-suggestions').setAttribute('app', app.title);

	const iconTemplate = document.querySelector('#app-icon-template');
	const icon = cloneTemplate(iconTemplate);
	icon.src = app.iconURL;
	iconTemplate.replaceWith(icon);
	// The browser tab shows the icon of the app.
	document.querySelector('link[rel="icon"]')?.setAttribute('href', app.iconURL);

	const additionalInformation = document.querySelector('#additional-information');

	// A visitor on a macOS version that the current version of the app does not run on cannot update, so the last version for that macOS version comes first. The app sends its macOS version, like `OS: macOS 15.6 (24G84)`. An older version is for a major version, or for a minor version of macOS 10, like 10.15.
	const macOSVersion = appMetadata?.match(/^OS: macOS (10\.\d+|\d+)/m)?.[1];
	const olderVersion = app.olderVersions.find(({macOS}) => macOS === macOSVersion);
	// Not for a visitor who already has that version or a newer one, like the current version on a newer minor version of that macOS. The app sends its version and build, like `App: Dato 5.7.2 (1234)`.
	const appVersion = appMetadata?.match(/^App: .* (\S+) \(/m)?.[1];
	if (olderVersion && (!appVersion || appVersion.localeCompare(olderVersion.version, undefined, {numeric: true}) < 0)) {
		const paragraph = cloneTemplate(document.querySelector('#older-version-template'));
		paragraph.querySelector('[data-older-version-text]').textContent = `You are on macOS ${macOSVersion}. ${app.title} ${olderVersion.version} is the last version for it.`;
		const link = paragraph.querySelector('[data-older-version-link]');
		link.textContent = `Download ${olderVersion.version}`;
		link.href = olderVersion.url;
		additionalInformation.append(paragraph);
	}

	if (app.repositoryURL) {
		const searchParameters = new URLSearchParams({
			body: `<!--\nProvide your feedback below. Include as many details as possible.\n-->\n\n\n\n---\n${appMetadata ?? ''}`.trim(),
		});

		const paragraph = cloneTemplate(document.querySelector('#repository-template'));
		paragraph.querySelector('[data-repository-link]').href = `${app.repositoryURL}/issues/new?${searchParameters}`;
		additionalInformation.append(paragraph);
	}

	if (app.faqURL) {
		const paragraph = cloneTemplate(document.querySelector('#app-faq-template'));
		paragraph.querySelector('[data-app-faq-link]').href = app.faqURL;
		additionalInformation.append(paragraph);
	}

	// The note of the app, from its `feedbackNote`.
	const noteTemplate = [...document.querySelectorAll('[data-feedback-note]')].find(template => template.dataset.feedbackNote === app.title);
	if (noteTemplate) {
		additionalInformation.append(cloneTemplate(noteTemplate));
	}
}

// --- The app picker ---

// The links to the form of each app keep the parameters of the page, like the ones that the “Change App” link keeps, so a `referrer` of the page wins over the one of the picker.
function keepParametersInAppPicker() {
	for (const link of document.querySelectorAll('#app-picker a[href^="/feedback?"]')) {
		const url = new URL(link.href);

		for (const [key, value] of keptParameters) {
			url.searchParams.set(key, value);
		}

		link.href = url;
	}
}

// --- Hidden fields: the URL parameters and the environment of the visitor ---

// Safari and Firefox do not have `userAgentData`, so the platform comes from `navigator.platform`.
function detectPlatform() {
	const platform = navigator.platform ?? '';

	// An iPad asks for desktop sites by default, so it says it is a Mac. Its main input is touch, even with a trackpad, while a Mac, also one with a touch screen, has the trackpad or mouse as its main input.
	if (/iPhone|iPad|iPod/.test(platform) || /iPhone|iPad/.test(navigator.userAgent) || (/Mac/.test(platform) && navigator.maxTouchPoints > 1 && matchMedia('(pointer: coarse)').matches)) {
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
	const url = URL.parse(document.referrer);
	if (url?.hostname === 'sindresorhus.com' || url?.hostname === 'www.sindresorhus.com') {
		return url.pathname + url.search + url.hash;
	}

	return document.referrer;
}

// The browser and OS details that help diagnose a report.
async function environmentInfo() {
	// Chromium only. Safari and Firefox fall back to the user agent string.
	const highEntropy = await navigator.userAgentData?.getHighEntropyValues(['platformVersion']).catch(() => undefined);

	// The OS name in the user agent string is frozen in modern browsers, so `userAgentData.platform` comes first.
	const platform = navigator.userAgentData?.platform ?? detectPlatform();

	// On iOS, Safari 26 and later has the version of the OS. Not on macOS, as Safari 26 also comes for macOS 14 and 15. WebKitGTK fakes a high version to pass browser checks, so other platforms are left out.
	const safari = navigator.userAgent.match(/Version\/([\d.]+).*Safari/);
	const safariOSVersion = platform === 'iOS' && safari && Number.parseInt(safari[1], 10) >= 26 ? safari[1] : undefined;

	// Windows reports the version of `Windows.Foundation.UniversalApiContract` instead of the OS version, and Linux reports nothing.
	const platformVersion = ['macOS', 'iOS', 'Android', 'Chrome OS'].includes(platform) ? highEntropy?.platformVersion : undefined;

	// Browsers based on Chromium list their own brand next to Chromium, but some, like Chromium itself, only list Chromium.
	const brands = navigator.userAgentData?.brands?.filter(item => !item.brand.startsWith('Not')) ?? [];
	const brand = brands.find(item => item.brand !== 'Chromium') ?? brands[0];
	const firefox = navigator.userAgent.match(/Firefox\/([\d.]+)/);

	// Browsers on iOS use WebKit and look like Safari, but name themselves with their own token.
	const iOSBrowser = navigator.userAgent.match(/(CriOS|FxiOS|EdgiOS)\/([\d.]+)/);
	const iOSBrowserNames = {CriOS: 'Chrome', FxiOS: 'Firefox', EdgiOS: 'Edge'};

	let browser = 'Unknown';
	if (brand) {
		browser = `${brand.brand} ${brand.version}`;
	} else if (iOSBrowser) {
		browser = `${iOSBrowserNames[iOSBrowser[1]]} ${iOSBrowser[2]}`;
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
	// The time is set when the form is sent.
	addHiddenField(form, 'timestamp', '');

	// Every URL parameter is sent along, and some fill in the form.
	for (const [key, value] of parameters) {
		if (key === 'emailField') {
			// The default value, so the address of the link comes back when the form empties itself after Back from the sent message.
			form.elements.email.defaultValue = value;
		} else if (key === 'messageField') {
			form.elements.message.value = value;
			form.elements.message.setSelectionRange(0, 0);
			// Setting the value fires no `input` event, so the related help and the crash warning would wait for the visitor to type.
			form.elements.message.dispatchEvent(new Event('input'));
		} else if (key === 'product') {
			// The real title of the app, also when the link has its slug or another case.
			addHiddenField(form, key, product);
		} else if (key !== 'metadata' && !form.elements.namedItem(key)) {
			// Not a parameter with the name of a field of the form, like `email` or `timestamp`, as a second field with the name would replace the value of the visitor, and `form.elements.email` would be a list.
			addHiddenField(form, key, value);
		}
	}

	if (appMetadata) {
		addHiddenField(form, 'metadata', appMetadata);

		// The metadata is in the form now, so it is removed from the visible URL. It stays in the state of the history entry, so a reload, or a tab that the browser loads again, still sends it.
		if (parameters.has('metadata')) {
			const url = new URL(location.href);
			url.searchParams.delete('metadata');
			history.replaceState({...history.state, metadata: appMetadata}, '', url);
		}
	} else {
		// Apps send their own metadata. Otherwise, the environment of the browser is sent. It is added last, as it waits for the browser, so the fields above are filled before the visitor starts typing. If a detail fails, the user agent is still sent, as it has most of the details.
		const metadata = await environmentInfo().catch(error => {
			console.error('Could not get the environment details:', error);
			return `User agent: ${navigator.userAgent}`;
		});

		addHiddenField(form, 'metadata', metadata);
	}
}

// --- Email typos ---

function setUpEmailTypoDetection(emailInput) {
	// While the visitor types, an address can look incorrect only because it is not complete yet, like `anna@fastm`, so it is judged incorrect only when the field is done (`isDone`). A likely typo, like `gmial.com`, shows at once.
	const warningFor = (email, {isDone}) => {
		const atIndex = email.lastIndexOf('@');
		if (atIndex === -1) {
			return;
		}

		const incorrectWarning = isDone ? 'Your email address looks incorrect.' : undefined;
		const localPart = email.slice(0, atIndex);
		if (localPart.endsWith('-') || localPart.startsWith('.') || localPart.endsWith('.') || localPart.includes('..')) {
			return incorrectWarning;
		}

		const domain = email.slice(atIndex + 1).toLowerCase();
		const intended = intendedDomain(domain);

		if (!intended) {
			return incorrectWarning;
		}

		if (intended !== domain) {
			return suggestion(`${email.slice(0, atIndex + 1)}${intended}`);
		}
	};

	const emailWarning = document.querySelector('#email-warning');
	let timer;

	// “Did you mean …?” with the corrected address as a button, which puts it in the field.
	const suggestion = address => {
		const element = cloneTemplate(document.querySelector('#email-suggestion-template'));
		const button = element.querySelector('[data-suggested-email]');
		button.textContent = address;
		button.addEventListener('click', () => {
			clearTimeout(timer);
			emailInput.value = address;
			emailWarning.replaceChildren();
			// The button is gone, so the focus goes back to the field.
			emailInput.focus();
		});

		return element;
	};

	const showWarning = ({isDone}) => {
		clearTimeout(timer);
		emailWarning.replaceChildren(warningFor(emailInput.value.trim(), {isDone}) ?? '');
	};

	emailInput.addEventListener('input', () => {
		emailWarning.replaceChildren();
		clearTimeout(timer);

		timer = setTimeout(() => {
			showWarning({isDone: false});
		}, 600);
	});

	// When the visitor leaves the field. A suggestion that already shows stays, as the focus can leave the field for its button, which would be gone before the click.
	emailInput.addEventListener('change', () => {
		if (!emailWarning.textContent) {
			showWarning({isDone: true});
		}
	});
}

// --- The filter of the app picker ---

function setUpAppFilter() {
	const filter = document.querySelector('#app-filter');
	const status = document.querySelector('#app-filter-status');
	const list = document.querySelector('[data-app-filter-text]').parentElement;

	// The text is the name and the subtitle of the app. The item only shows the name. In the alphabetical order of the page.
	const items = [...document.querySelectorAll('[data-app-filter-text]')].map(item => ({item, textKey: searchKey(item.dataset.appFilterText), titleKey: searchKey(item.textContent)}));
	let shownItems = items;

	/*
	An app matches when its name or its subtitle has each word, like “menu cal” for “Menu Bar Calendar”, also without spaces, like “menubar” (`searchKey`). The apps whose name has the words come first, as visitors mostly type the name, so “menu bar” shows Menu Bar Calendar before the apps that are about the menu bar.

	When no app matches, the app whose name is closest shows instead, like “Gifski” for “gifksi” (`closest`).
	*/
	const update = () => {
		const words = filter.value.split(/\s+/).map(word => searchKey(word)).filter(Boolean);
		const matches = items.filter(({textKey}) => words.every(word => textKey.includes(word)));
		const nameMatches = matches.filter(({titleKey}) => words.every(word => titleKey.includes(word)));
		const closestItem = matches.length === 0 ? closest(words.join(''), items, {key: ({titleKey}) => titleKey}) : undefined;
		shownItems = matches.length > 0 ? [...nameMatches, ...matches.filter(match => !nameMatches.includes(match))] : [closestItem].filter(Boolean);

		const hiddenItems = items.filter(entry => !shownItems.includes(entry));

		for (const entry of hiddenItems) {
			entry.item.hidden = true;
		}

		for (const entry of shownItems) {
			entry.item.hidden = false;
		}

		// The shown apps in their order, and the hidden ones after them, so screen readers and the keyboard follow the order too.
		list.append(...shownItems.map(({item}) => item), ...hiddenItems.map(({item}) => item));

		status.textContent = shownItems.length > 0 ? '' : 'No app matches. Check the spelling, or try another word.';
	};

	filter.addEventListener('input', update);

	// Enter opens the first app that shows, like a search. Not while an input method composes a word, or without a filter.
	filter.addEventListener('keydown', event => {
		if (event.key === 'Enter' && !event.isComposing && filter.value.trim()) {
			shownItems[0]?.item.querySelector('a').click();
		}
	});

	// Firefox restores the text of the field when the visitor comes back to the page.
	update();
}

// The script in the head marks the page after a send, and the page shows the message from the HTML.
if (!document.documentElement.hasAttribute('data-sent')) {
	const form = document.querySelector('#feedback-form');

	if (product) {
		showProduct();
	} else {
		keepParametersInAppPicker();
		setUpAppFilter();
	}

	// It fills the fields from the link at once, like the email address, which the check below needs, and adds the environment of the browser when the browser has it.
	const hiddenFieldsAdded = addHiddenFields(form).catch(error => {
		console.error('Could not add the hidden fields:', error);
	});
	setUpEmailTypoDetection(form.elements.email);

	// An address from the link, like from an app, is checked too, as setting the value fires no `change` event.
	if (parameters.has('emailField')) {
		form.elements.email.dispatchEvent(new Event('change'));
	}

	// The button shows “Sending…” while the form sends.
	const submitButton = document.querySelector('#submit-button');
	const enableSubmitButton = () => {
		submitButton.disabled = false;
		delete submitButton.dataset.state;
	};

	// Limitation: when the visitor stops the send, like with the Stop button of the browser, the button stays disabled with “Sending…” until the page loads again, as no event says that the navigation stopped.
	form.addEventListener('submit', () => {
		// The time of the send, not of the page load, as the visitor can write for a long time, and the page can come back from the back/forward cache hours later. In seconds, like the feedback form of the apps, which sends to the same form.
		form.elements.timestamp.value = Math.floor(Date.now() / 1000);
		submitButton.disabled = true;
		submitButton.dataset.state = 'sending';
	});

	// The button is disabled in the HTML until this script has added the hidden fields, like the app and the environment of the browser, which waits for the browser. The page can also come back with it disabled from the back/forward cache. The first `pageshow` is left out, as it can come after a submit when the page loads slowly.
	hiddenFieldsAdded.then(enableSubmitButton);

	// The script in the head sets it when the message was sent. A page that the browser loads again, like after Back without the back/forward cache, starts without it. Limitation: a browser that puts the text of the fields back in a page that it loads again keeps the sent text there.
	const sentKey = 'feedback-sent';
	try {
		sessionStorage.removeItem(sentKey);
	} catch {
		// Without storage, like with blocked site data, the form keeps its text after Back.
	}

	window.addEventListener('pageshow', event => {
		if (!event.persisted) {
			return;
		}

		enableSubmitButton();

		// After Back from the sent message, the form is emptied, so the visitor does not send the same message again. A send that failed, like when the browser is offline, keeps the text.
		let isSent = false;
		try {
			isSent = sessionStorage.getItem(sentKey) !== null;
			sessionStorage.removeItem(sentKey);
		} catch {
			// Without storage, the form keeps its text.
		}

		if (isSent) {
			form.reset();
			// Like a change of the visitor, so the related help and the email warning go away.
			form.elements.message.dispatchEvent(new Event('input'));
			form.elements.email.dispatchEvent(new Event('input'));
		}
	});
}
