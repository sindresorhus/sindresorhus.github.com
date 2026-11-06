const day = 86_400_000;

// The ISO 8601 week of the day of the visitor, like “ISO week 46”, and its Monday and Sunday.
const weekNumber = now => {
	// The local day of the visitor as a UTC date, so the days are all 24 hours, also when the clock changes.
	const today = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate());
	// A week starts on Monday.
	const monday = today - (((new Date(today).getUTCDay() + 6) % 7) * day);
	// A week is in the year of its Thursday, so week 1 is the week with the first Thursday of the year.
	const thursday = new Date(monday + (3 * day));
	const week = Math.floor((thursday - Date.UTC(thursday.getUTCFullYear(), 0, 1)) / (7 * day)) + 1;
	const format = date => new Date(date).toLocaleDateString('en-US', {timeZone: 'UTC', month: 'long', day: 'numeric'});

	return [`ISO week ${week}`, `${format(monday)} to ${format(monday + (6 * day))}`];
};

// The time in UTC, like “14:32 UTC”, and the time of the visitor with the offset, like “20:02 for you (UTC+5:30)”.
const utcTime = now => {
	// In the 24-hour format.
	const time = timeZone => now.toLocaleTimeString('en-US', {timeZone, hour: '2-digit', minute: '2-digit', hourCycle: 'h23'});
	// Like “GMT+5:30”, or “GMT” without an offset.
	const offset = new Intl.DateTimeFormat('en-US', {timeZoneName: 'shortOffset'}).formatToParts(now).find(part => part.type === 'timeZoneName').value;

	// A visitor whose time is UTC, like in London in the winter, has the same time, so the line does not show the time twice.
	return [`${time('UTC')} UTC`, now.getTimezoneOffset() === 0 ? 'the same as your time' : `${time()} for you (${offset.replace('GMT', 'UTC')})`];
};

class LiveFact extends HTMLElement {
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
		const [value, detail] = this.getAttribute('kind') === 'week-number' ? weekNumber(now) : utcTime(now);

		this.querySelector('[data-part="value"]').textContent = value;
		this.querySelector('[data-part="detail"]').textContent = detail;
		this.dataset.state = 'shown';

		// At the start of the next minute, so the time is the same as on a clock, and the week changes at midnight.
		this.#timer = setTimeout(this.#update, 60_000 - (now.getSeconds() * 1000) - now.getMilliseconds());
	};
}

customElements.define('live-fact', LiveFact);
