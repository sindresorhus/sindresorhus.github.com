// @ts-check
import {clockTime, parts, untilNextMinute} from '/scripts/dom.js';

/**
@import {AwakeStatusState, AwakeStatusParts, SiteIcon} from '/scripts/element-contracts.js'
*/

/**
One display outcome encoded by AwakeStatus.Status in Swift.
@typedef {Readonly<{state: AwakeStatusState, icon: SiteIcon, text: string, beforeHour: number}>} AwakeStatusEntry
*/

/**
The configuration encoded by AwakeStatus.Config in Swift. ScriptTypeTests checks the actual encoded values against this type.
@typedef {Readonly<{statuses: readonly AwakeStatusEntry[], utcOffsetMinutes: number}>} AwakeStatusConfig
*/

class AwakeStatus extends HTMLElement {
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
		// Swift supplies the required configuration attribute.
		const {statuses, utcOffsetMinutes} = /** @type {AwakeStatusConfig} */ (JSON.parse(/** @type {string} */ (this.dataset.config)));
		const now = new Date();
		// The time where I am is the time in UTC with my offset added, in the 24-hour format, like “04:12”.
		const time = clockTime(new Date(now.getTime() + (utcOffsetMinutes * 60_000)), 'UTC');
		const hour = Number.parseInt(time, 10);

		// The state, the icon in the sprite, and the text.
		// Swift's status table covers every hour, with a final beforeHour of 24.
		const {state, icon, text} = /** @type {AwakeStatusEntry} */ (statuses.find(status => hour < status.beforeHour));

		this.dataset.state = state;
		// The icon is rendered by Swift.
		const use = /** @type {SVGUseElement} */ (this.querySelector('use'));
		use.href.baseVal = use.href.baseVal.replace(/#.*/, `#${icon}`);
		const {text: textPart, time: timePart} = /** @type {AwakeStatusParts} */ (parts(this));
		textPart.textContent = text;
		timePart.textContent = `${time} my time`;

		// At the start of the next minute, so the time is the same as on a clock.
		this.#timer = setTimeout(this.#update, untilNextMinute(now));
	};
}

customElements.define('awake-status', AwakeStatus);
