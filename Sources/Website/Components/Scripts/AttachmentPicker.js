import {cloneTemplate} from '/scripts/dom.js';

// Like “217 kB” or “1.5 MB”, in the language of the visitor. In decimal units, like Finder, so a file has the size that Finder shows, and the size limit means what the visitor expects. Files under 1 kB show as 1 kB, not 0 kB.
const kilobytes = new Intl.NumberFormat(undefined, {style: 'unit', unit: 'kilobyte', maximumFractionDigits: 0});
const megabytes = new Intl.NumberFormat(undefined, {style: 'unit', unit: 'megabyte', maximumFractionDigits: 1});
const formatSize = bytes => bytes < 1_000_000
	? kilobytes.format(Math.max(bytes / 1000, 1))
	: megabytes.format(bytes / 1_000_000);

class AttachmentPicker extends HTMLElement {
	// The files of the input are rebuilt from this list, so files can be added in several picks and removed one by one.
	#files = [];

	// The file input, which the label of the picker opens.
	get #input() {
		return this.querySelector('[data-part="input"]');
	}

	connectedCallback() {
		// The same functions, so connecting the element again does not add second listeners.
		this.#input.addEventListener('change', this.#add);
		this.#input.form?.addEventListener('reset', this.#clear);
		window.addEventListener('pageshow', this.#addRestoredFiles);
	}

	// A reset of the form empties the input, so the chips and the list go too.
	#clear = () => {
		this.#files = [];
		this.querySelector('[data-part="fileList"]').replaceChildren();
		this.#updateInput();
	};

	#add = event => {
		this.#addFiles(event.currentTarget.files);
	};

	// When the page comes back without the back/forward cache, like after Back, the browser puts the files back in the input before the page shows, but not the chips, so the visitor would send files that they cannot see or remove, also one that is too large. The files that already have a chip are skipped.
	#addRestoredFiles = () => {
		if (this.#input.files.length > 0) {
			this.#addFiles(this.#input.files);
		}
	};

	#addFiles(files) {
		const fileList = this.querySelector('[data-part="fileList"]');

		// Files that are already attached, by name, size, and date, are skipped, so two different screenshots with the same name and size are both kept. Only the new files get a chip, so the thumbnails of the others are not loaded again.
		for (const file of files) {
			if (!this.#files.some(existingFile => existingFile.name === file.name && existingFile.size === file.size && existingFile.lastModified === file.lastModified)) {
				this.#files.push(file);
				fileList.append(this.#chip(file));
			}
		}

		this.#updateInput();
	}

	// The largest file that the form can send, in bytes.
	get #maximumFileSize() {
		return Number(this.getAttribute('maximum-file-size'));
	}

	// The input gets all the files, as a pick replaces its files. While a file is too large, the form cannot be sent.
	#updateInput() {
		const dataTransfer = new DataTransfer();
		let totalSize = 0;
		for (const file of this.#files) {
			dataTransfer.items.add(file);
			totalSize += file.size;
		}

		this.#input.files = dataTransfer.files;

		// The message of the browser has the notice of the chip, with the name of the file.
		const tooLargeFile = this.#files.find(file => file.size > this.#maximumFileSize);
		this.#input.setCustomValidity(tooLargeFile ? `“${tooLargeFile.name}”: ${this.#tooLargeNotice}` : '');

		// Like “33 files, 15.1 MB”. One file shows its size in its chip.
		this.querySelector('[data-part="summary"]').textContent = this.#files.length > 1 ? `${this.#files.length} files, ${formatSize(totalSize)}` : '';
	}

	// The text of the notice for a file that is too large, which Swift writes with the size limit of the build.
	get #tooLargeNotice() {
		return cloneTemplate(this.querySelector('[data-part="template"]')).querySelector('[data-part="tooLargeNotice"]').textContent;
	}

	#chip(file) {
		const chip = cloneTemplate(this.querySelector('[data-part="template"]'));
		const thumbnail = chip.querySelector('[data-part="thumbnail"]');

		// The type that the browser gives the file from its extension, like `image/png`.
		if (file.type.startsWith('image/')) {
			const icon = chip.querySelector('[data-part="fileIcon"]');
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

		// The end of the name is the extension and the 4 characters before it, or the last 4 characters of a name without an extension. It is at most 12 characters, as it does not shrink, so a long extension would overflow the chip. By the characters that people see, so an emoji or a letter with an accent is not cut in two.
		const characters = [...new Intl.Segmenter().segment(file.name)].map(({segment}) => segment);
		const extensionIndex = characters.lastIndexOf('.');
		const endIndex = Math.max(0, (extensionIndex > 0 ? extensionIndex : characters.length) - 4, characters.length - 12);
		chip.querySelector('[data-part="nameStart"]').textContent = characters.slice(0, endIndex).join('');
		chip.querySelector('[data-part="nameEnd"]').textContent = characters.slice(endIndex).join('');
		chip.querySelector('[data-part="size"]').textContent = formatSize(file.size);

		if (file.size > this.#maximumFileSize) {
			chip.dataset.state = 'too-large';
		}

		const removeButton = chip.querySelector('[data-part="removeButton"]');
		removeButton.ariaLabel = `Remove ${file.name}`;
		removeButton.addEventListener('click', () => {
			const fileList = chip.parentElement;
			const index = [...fileList.children].indexOf(chip);
			this.#files.splice(this.#files.indexOf(file), 1);
			chip.remove();
			this.#updateInput();

			// The removed chip had the focus, so it moves to the next remove button, the previous one for the last chip, or the file input.
			const removeButtons = fileList.querySelectorAll('[data-part="removeButton"]');
			(removeButtons[Math.min(index, removeButtons.length - 1)] ?? this.#input).focus();
		});

		return chip;
	}
}

customElements.define('attachment-picker', AttachmentPicker);
