// @ts-check
import {parts} from '/scripts/dom.js';

/**
@import {ProjectOfTheDayParts} from '/scripts/element-contracts.js'
*/

/**
The configuration encoded by ProjectOfTheDay.Config in Swift. ScriptTypeTests checks the encoded values against this type.
@typedef {Readonly<{listPath: string, randomTitle: string}>} ProjectOfTheDayConfig
*/

/**
A project in the file of the projects, encoded by ProjectOfTheDay.Project in Swift.
@typedef {Readonly<{name: string, description: string, detail: string, url: string}>} Project
*/

class ProjectOfTheDay extends HTMLElement {
	// The request for the projects, so more clicks while it loads wait for it, instead of loading the file again.
	/** @type {Promise<Project[]> | undefined} */
	#projects;

	connectedCallback() {
		// The same function, so connecting the element again does not add a second listener.
		/** @type {ProjectOfTheDayParts} */ (parts(this)).next.addEventListener('click', this.#showAnother);
	}

	#showAnother = async () => {
		// Swift supplies the required configuration attribute.
		const {listPath, randomTitle} = /** @type {ProjectOfTheDayConfig} */ (JSON.parse(/** @type {string} */ (this.dataset.config)));
		this.#projects ??= fetch(listPath).then(response => response.json());
		let projects;

		try {
			projects = await this.#projects;
		} catch (error) {
			// The project of the day stays, and the next click tries again.
			this.#projects = undefined;
			console.error('Could not load the projects:', error);
			return;
		}

		const {title, name, description, detail} = /** @type {ProjectOfTheDayParts} */ (parts(this));
		const others = projects.filter(project => project.name !== name.textContent);
		const pick = others[Math.floor(Math.random() * others.length)];

		// A list with only the shown project has no other one.
		if (!pick) {
			return;
		}

		title.textContent = randomTitle;
		name.textContent = pick.name;
		name.href = pick.url;
		description.textContent = pick.description;
		detail.textContent = pick.detail;
	};
}

customElements.define('project-of-the-day', ProjectOfTheDay);
