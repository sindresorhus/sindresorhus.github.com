const imageExtensions = new Set(['png', 'jpg', 'jpeg', 'jxl', 'gif', 'webp', 'heic', 'heif', 'avif', 'svg']);

// Like “217 kB” or “1.5 MB”, in the language of the visitor. Files under 1 kB show as 1 kB, not 0 kB.
const kilobytes = new Intl.NumberFormat(undefined, {style: 'unit', unit: 'kilobyte', maximumFractionDigits: 0});
const megabytes = new Intl.NumberFormat(undefined, {style: 'unit', unit: 'megabyte', maximumFractionDigits: 1});
const formatSize = bytes => bytes < 1024 * 1024
	? kilobytes.format(Math.max(bytes / 1024, 1))
	: megabytes.format(bytes / (1024 * 1024));

export default class extends HTMLElement {
	// The files of the input are rebuilt from this list, so files can be added in several picks and removed one by one.
	#files = [];

	connectedCallback() {
		// The same function, so connecting the element again does not add a second listener.
		this.querySelector('[data-part="input"]').addEventListener('change', this.#add);
	}

	#add = event => {
		// Files that are already attached, by name and size, are skipped.
		for (const file of event.currentTarget.files) {
			if (!this.#files.some(existingFile => existingFile.name === file.name && existingFile.size === file.size)) {
				this.#files.push(file);
			}
		}

		this.#update();
	};

	#update() {
		const files = this.#files;
		const input = this.querySelector('[data-part="input"]');
		const fileList = this.querySelector('[data-part="fileList"]');
		const template = this.querySelector('[data-part="template"]');

		const dataTransfer = new DataTransfer();
		for (const file of files) {
			dataTransfer.items.add(file);
		}

		input.files = dataTransfer.files;

		fileList.replaceChildren(...files.map((file, index) => {
			const chip = template.content.firstElementChild.cloneNode(true);
			const thumbnail = chip.querySelector('img');

			if (imageExtensions.has(file.name.split('.').pop().toLowerCase())) {
				const icon = chip.querySelector('svg');
				thumbnail.src = URL.createObjectURL(file);
				thumbnail.addEventListener('load', () => {
					URL.revokeObjectURL(thumbnail.src);
				}, {once: true});

				// Some browsers cannot show some image formats, like HEIC in Chrome, so these get the file icon.
				thumbnail.addEventListener('error', () => {
					URL.revokeObjectURL(thumbnail.src);
					thumbnail.replaceWith(icon);
				}, {once: true});

				icon.remove();
			} else {
				thumbnail.remove();
			}

			chip.querySelector('[data-part="name"]').textContent = file.name;
			chip.querySelector('[data-part="size"]').textContent = formatSize(file.size);

			const removeButton = chip.querySelector('button');
			removeButton.ariaLabel = `Remove ${file.name}`;
			removeButton.addEventListener('click', () => {
				files.splice(index, 1);
				this.#update();

				// The removed chip had the focus, so it moves to the next remove button, the previous one for the last chip, or the file input.
				const removeButtons = fileList.querySelectorAll('button');
				(removeButtons[Math.min(index, removeButtons.length - 1)] ?? input).focus();
			});

			return chip;
		}));
	}
}
