import {cloneTemplate, parts} from '/scripts/dom.js';

// Like “217 kB” or “1.5 MB”, in the language of the visitor. In decimal units, like Finder, so a file has the size that Finder shows, and the size limit means what the visitor expects. Files under 1 kB show as 1 kB, not 0 kB, but an empty file shows as “Empty”, like a log that failed to save, so the visitor does not think it has content.
const kilobytes = new Intl.NumberFormat(undefined, {style: 'unit', unit: 'kilobyte', maximumFractionDigits: 0});
const megabytes = new Intl.NumberFormat(undefined, {style: 'unit', unit: 'megabyte', maximumFractionDigits: 1});
const formatSize = bytes => {
	if (bytes === 0) {
		return 'Empty';
	}

	return bytes < 1_000_000
		? kilobytes.format(Math.max(bytes / 1000, 1))
		: megabytes.format(bytes / 1_000_000);
};

// The app, its version, and the OS of a crash report, like “Dato 5.8.1 · macOS 27.2”. The first line of an `.ips` file is JSON with them, like `{"app_name":"Dato","app_version":"5.8.1","os_version":"macOS 27.2 (26B118)",…}`. Nothing for another file, or a report without the name of the app.
async function readCrashReport(file) {
	if (!file.name.toLowerCase().endsWith('.ips')) {
		return;
	}

	try {
		// The first line is short, so only the start of the file is read.
		const [firstLine] = (await file.slice(0, 4096).text()).split('\n');
		const {app_name: name, app_version: version, os_version: osVersion} = JSON.parse(firstLine);

		if (typeof name !== 'string' || !name) {
			return;
		}

		// The OS without its build, like “macOS 27.2” for “macOS 27.2 (26B118)”.
		return [[name, version].filter(Boolean).join(' '), osVersion?.replace(/\s*\(.*$/, '')].filter(Boolean).join(' · ');
	} catch {
		// Not a crash report in the JSON format, or a file that cannot be read.
	}
}

class AttachmentPicker extends HTMLElement {
	// The files of the input are rebuilt from this list, so files can be added in several picks and removed one by one.
	#files = [];

	// The file input, which the label of the picker opens.
	get #input() {
		return parts(this).input;
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
		parts(this).fileList.replaceChildren();
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
		const {fileList} = parts(this);

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
		parts(this).summary.textContent = this.#files.length > 1 ? `${this.#files.length} files, ${formatSize(totalSize)}` : '';
	}

	// The text of the notice for a file that is too large, which Swift writes with the size limit of the build.
	get #tooLargeNotice() {
		return parts(cloneTemplate(parts(this).template)).tooLargeNotice.textContent;
	}

	#chip(file) {
		const chip = cloneTemplate(parts(this).template);
		const {
			thumbnail,
			fileIcon: icon,
			nameStart,
			nameEnd,
			size,
			removeButton,
			crashReportDetails,
		} = parts(chip);

		// The type that the browser gives the file from its extension, like `image/png`.
		if (file.type.startsWith('image/')) {
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
		let endIndex = Math.max(0, (extensionIndex > 0 ? extensionIndex : characters.length) - 4, characters.length - 12);

		// A space at the start of the end goes to the end of the start, where the ellipsis replaces it when the name is cut, so there is no gap after the ellipsis, like “Screen Recordin…bug.mov”, as in Finder.
		if (/^\s$/.test(characters[endIndex] ?? '')) {
			endIndex++;
		}

		nameStart.textContent = characters.slice(0, endIndex).join('');
		nameEnd.textContent = characters.slice(endIndex).join('');
		size.textContent = formatSize(file.size);

		if (file.size > this.#maximumFileSize) {
			chip.dataset.state = 'too-large';
		} else {
			// The file is read after the chip shows, so the chip does not wait for it.
			readCrashReport(file).then(details => {
				if (details) {
					crashReportDetails.textContent = details;
					chip.dataset.state = 'crash-report';
				}
			});
		}

		removeButton.ariaLabel = `Remove ${file.name}`;
		removeButton.addEventListener('click', () => {
			const fileList = chip.parentElement;
			const index = [...fileList.children].indexOf(chip);
			this.#files.splice(this.#files.indexOf(file), 1);
			chip.remove();
			this.#updateInput();

			// Setting the files of the input sends no event, so the form hears of the removal with a change event, like for a pick, for the help that follows the attachments.
			this.dispatchEvent(new Event('change', {bubbles: true}));

			// The removed chip had the focus, so it moves to the next remove button, the previous one for the last chip, or the file input.
			const removeButtons = fileList.querySelectorAll('[data-part="removeButton"]');
			(removeButtons[Math.min(index, removeButtons.length - 1)] ?? this.#input).focus();
		});

		return chip;
	}
}

customElements.define('attachment-picker', AttachmentPicker);
