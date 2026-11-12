// @ts-check
import {clockTime, parts, untilNextMinute} from '/scripts/dom.js';

/**
@import {LiveFactKind, LiveFactParts, LiveFactState} from '/scripts/element-contracts.js'
*/

const day = 86_400_000;

// The ISO 8601 week of the day of the visitor, like “ISO week 46”, and its Monday and Sunday.
/**
@param {Date} now
@returns {[string, string]}
*/
const weekNumber = now => {
	// The local day of the visitor as a UTC date, so the days are all 24 hours, also when the clock changes.
	const today = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate());
	// A week starts on Monday.
	const monday = today - (((new Date(today).getUTCDay() + 6) % 7) * day);
	// A week is in the year of its Thursday, so week 1 is the week with the first Thursday of the year.
	const thursday = new Date(monday + (3 * day));
	const week = Math.floor((thursday.getTime() - Date.UTC(thursday.getUTCFullYear(), 0, 1)) / (7 * day)) + 1;
	/** @param {number} date */
	const format = date => new Date(date).toLocaleDateString('en-US', {timeZone: 'UTC', month: 'long', day: 'numeric'});

	return [`ISO week ${week}`, `${format(monday)} to ${format(monday + (6 * day))}`];
};

// The time in UTC, like “14:32 UTC”, and the date in UTC with the time of the visitor and the offset, like “Nov 13 in UTC · 20:02 for you (UTC+5:30)”, or “Nov 13 · your time is UTC” for a visitor whose time is UTC. The date says “in UTC”, as it is not the date of the visitor when it is already another day in UTC, like the menu of the UTC Time app shows. With the short month and without the weekday, so the line fits on one line at 390 px on all days, and the card does not change its height when the script runs.
/**
@param {Date} now
@returns {[string, string]}
*/
const utcTime = now => {
	// Like “GMT+5:30”, or “GMT” without an offset.
	// Requesting `timeZoneName` guarantees this part, which the general Intl type cannot express.
	const offset = /** @type {Intl.DateTimeFormatPart} */ (new Intl.DateTimeFormat('en-US', {timeZoneName: 'shortOffset'}).formatToParts(now).find(part => part.type === 'timeZoneName')).value;
	const date = now.toLocaleDateString('en-US', {timeZone: 'UTC', month: 'short', day: 'numeric'});
	const time = `${clockTime(now, 'UTC')} UTC`;

	// A visitor whose time is UTC, like in London in the winter, has the same time and date, so the line does not show the time twice, and the date needs no “in UTC”.
	if (now.getTimezoneOffset() === 0) {
		return [time, `${date} · your time is UTC`];
	}

	// The offset has a minus sign, not a hyphen, like the other text of the site.
	return [time, `${date} in UTC · ${clockTime(now)} for you (${offset.replace('GMT', 'UTC').replace('-', '−')})`];
};

// The facts by the raw values of `LiveFact.Kind` in Swift. An unknown kind throws, so the card stays hidden and never shows the fact of another kind.
/** @type {Record<LiveFactKind, (now: Date) => [string, string]>} */
const facts = {
	'week-number': weekNumber,
	'utc-time': utcTime,
};

class LiveFact extends HTMLElement {
	/** @type {number | undefined} */
	#timer;

	connectedCallback() {
		clearTimeout(this.#timer);
		this.#update();
	}

	disconnectedCallback() {
		clearTimeout(this.#timer);
	}

	#update = () => {
		const now = new Date();
		// Swift renders the kind and the named parts; their types are generated from that markup.
		const [value, detail] = facts[/** @type {LiveFactKind} */ (this.getAttribute('kind'))](now);

		const {value: valuePart, detail: detailPart} = /** @type {LiveFactParts} */ (parts(this));
		valuePart.textContent = value;
		detailPart.textContent = detail;
		this.dataset.state = /** @satisfies {LiveFactState} */ ('shown');

		// At the start of the next minute, so the time is the same as on a clock, and the week changes at midnight.
		this.#timer = setTimeout(this.#update, untilNextMinute(now));
	};
}

customElements.define('live-fact', LiveFact);
