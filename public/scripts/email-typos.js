// The likely typos of the domain of an email address, like `gmial.com` for `gmail.com`, for the email field of the feedback form (`feedback.js`).
import {editDistance} from '/scripts/edit-distance.js';

// The domains of the email providers of most visitors.
const commonDomains = ['gmail.com', 'icloud.com', 'outlook.com', 'hotmail.com', 'yahoo.com', 'proton.me', 'protonmail.com'];

// Real email domains that are one edit from a common domain, like `mail.com` from `gmail.com`.
const realDomains = new Set(['mail.com', 'email.com', 'ymail.com', 'cloud.com']);

// Likely typos of the endings of the common domains.
const endingTypos = {
	'.con': '.com',
	'.cmo': '.com',
	'.ocm': '.com',
	'.ney': '.net',
};

// The name and the ending of a domain, like `gmail` and `.com`.
function splitDomain(domain) {
	const dotIndex = domain.indexOf('.');
	return dotIndex === -1 ? {name: domain, ending: ''} : {name: domain.slice(0, dotIndex), ending: domain.slice(dotIndex)};
}

/*
The domain that the visitor likely meant: the domain with the typo of its ending fixed, like `.com` for `.con`, and then the common domain whose name is close, like `icloud.com` for `icluod.com` (the way Mailcheck works). The domain itself when it looks right. A domain without a dot is the common domain whose name it is, like `gmail`, or that it is without its dot, like `gmailcom`, or else `undefined`, as the browser accepts a domain without a dot, but no reply reaches it.

The name and the ending are compared on their own, so a common name with another real ending, like `hotmail.ca` and `protonmail.ch`, which are two edits from `.com`, is not taken for `.com`. A long name, like `protonmail`, can have two typos. Short domains, like `me.com` and `live.com`, are not in the list, as their names are close to many real names, like `ge.com` and `love.com`.
*/
export function intendedDomain(domain) {
	const endingTypo = Object.keys(endingTypos).find(typo => domain.endsWith(typo));
	const fixedDomain = endingTypo ? domain.slice(0, -endingTypo.length) + endingTypos[endingTypo] : domain;

	if (realDomains.has(fixedDomain)) {
		return fixedDomain;
	}

	if (!fixedDomain.includes('.')) {
		return commonDomains.find(commonDomain => [splitDomain(commonDomain).name, commonDomain.replace('.', '')].includes(fixedDomain));
	}

	const {name, ending} = splitDomain(fixedDomain);
	let bestMatch = {domain: fixedDomain, distance: Number.POSITIVE_INFINITY};

	for (const commonDomain of commonDomains) {
		const {name: commonName, ending: commonEnding} = splitDomain(commonDomain);
		const hasCommonEnding = ending === commonEnding;

		// A typo in the name, like `gmial.com`, or in the ending of a common name, like `gmail.co`.
		let distance = Number.POSITIVE_INFINITY;

		if (hasCommonEnding) {
			distance = editDistance(name, commonName);
		} else if (name === commonName) {
			// An ending that stops early, like `gmail.c`, is one edit.
			distance = commonEnding.startsWith(ending) ? 1 : editDistance(ending, commonEnding);
		}

		const maximumDistance = hasCommonEnding && commonName.length >= 8 ? 2 : 1;

		if (distance <= maximumDistance && distance < bestMatch.distance) {
			bestMatch = {domain: commonDomain, distance};
		}
	}

	return bestMatch.domain;
}
