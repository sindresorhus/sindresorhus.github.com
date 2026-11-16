import {parts} from '/scripts/dom.js';

class ProjectOfTheDay extends HTMLElement {
	// The request for the projects, so more clicks while it loads wait for it, instead of loading the file again.
	#projects;

	connectedCallback() {
		// The same function, so connecting the element again does not add a second listener.
		parts(this).next.addEventListener('click', this.#showAnother);
	}

	#showAnother = async () => {
		const {listPath, randomTitle} = JSON.parse(this.dataset.config);
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

		const {title, name, description, detail} = parts(this);
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
