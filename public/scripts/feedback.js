const feedbackData = JSON.parse(document.querySelector('#feedback-data')?.textContent ?? '{}');
const apps = feedbackData.apps ?? [];
const parameters = new URLSearchParams(location.search);
const productParameter = parameters.get('product');

// The app is found by its title or its slug (the URL path), in any case, like `supercharge` for “Supercharge”.
const productName = productParameter?.toLowerCase();
const app = apps.find(app => app.title.toLowerCase() === productName || app.url.slice(1) === productName);
const product = app?.title ?? productParameter;

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
	const productNameElement = document.querySelector('#product-name');
	productNameElement.textContent = product;
	productNameElement.hidden = false;
	document.querySelector('#app-picker').hidden = true;
	document.querySelector('#feedback-form').hidden = false;
	document.querySelector('#before-you-write').hidden = false;

	if (!app) {
		return;
	}

	// The suggestions include the questions of the app.
	document.querySelector('#faq-suggestions').setAttribute('app', app.title);

	const icon = document.querySelector('#app-icon');
	icon.src = app.iconURL;
	icon.hidden = false;
	// The browser tab shows the icon of the app.
	document.querySelector('link[rel="icon"]')?.setAttribute('href', app.iconURL);

	const additionalInformation = document.querySelector('#additional-information');

	if (app.repositoryURL) {
		const searchParameters = new URLSearchParams({
			body: `<!--\nProvide your feedback below. Include as many details as possible.\n-->\n\n\n\n---\n${parameters.get('metadata') ?? ''}`.trim(),
		});

		const paragraph = cloneTemplate('repository-template');
		paragraph.querySelector('[data-repository-link]').href = `${app.repositoryURL}/issues/new?${searchParameters}`;
		additionalInformation.append(paragraph);
	}

	if (app.faqURL) {
		const paragraph = cloneTemplate('app-faq-template');
		paragraph.querySelector('[data-app-faq-link]').href = app.faqURL;
		additionalInformation.append(paragraph);
	}

	// HTML that the site generator rendered from the Markdown of the app, not visitor input.
	if (app.feedbackNote) {
		additionalInformation.insertAdjacentHTML('beforeend', `<div>${app.feedbackNote}</div>`);
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

	// Safari 26 and later uses the OS version as its version on all Apple platforms. WebKitGTK fakes a high version to pass browser checks, so other platforms are left out.
	const isApplePlatform = ['macOS', 'iOS'].includes(platform);
	const safari = navigator.userAgent.match(/Version\/([\d.]+).*Safari/);
	const safariOSVersion = isApplePlatform && safari && Number.parseInt(safari[1], 10) >= 26 ? safari[1] : undefined;

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
	addHiddenField(form, 'timestamp', Date.now());

	// Every URL parameter is sent along, and some fill in the form.
	for (const [key, value] of parameters) {
		if (key === 'emailField') {
			form.elements.email.value = value;
		} else if (key === 'messageField') {
			form.elements.message.value = value;
			form.elements.message.setSelectionRange(0, 0);
		} else if (key === 'product') {
			// The real title of the app, also when the link has its slug or another case.
			addHiddenField(form, key, product);
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
		// Only its own keys, as `constructor` is an inherited property of every object.
		if (Object.hasOwn(domainTypos, domain)) {
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
	setUpEmailTypoDetection(form.elements.email);

	// The disabled button shows “Sending…”.
	const submitButton = document.querySelector('#submit-button');
	form.addEventListener('submit', () => {
		submitButton.disabled = true;
	});

	// The page can come back with the button disabled, with the form state that Firefox restores (before this script runs) or from the back/forward cache. The first `pageshow` is left out, as it can come after a submit when the page loads slowly.
	submitButton.disabled = false;
	window.addEventListener('pageshow', event => {
		if (event.persisted) {
			submitButton.disabled = false;
		}
	});
}
