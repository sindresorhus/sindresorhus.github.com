import {cloneTemplate, isMac, parts, scriptData} from '/scripts/dom.js';
import {wordMatcher} from '/scripts/words.js';

/*
FAQ suggestions: while the visitor types, the message is split into words (three or more letters, without stopwords), and each question is scored by the words it shares with the message. Rare words count more (TF-IDF). The site generator prepares the words of each question, with synonyms. Pinned questions come first when they match as many words as the best other question, then questions with more matching words, then app questions, then higher scores. A question needs two matching words, or one for messages with only one known word. The tips of the app and the guides about it are questions of the app with a label, like “Guide”, so the same rules are for them.
*/

/*
The lines of a log that the visitor pasted, like the diagnostic report that the form asks for: a field, like `Command:   Actions` (a colon and two or more spaces), a field of the JSON of a crash report, like `"procName" : "Dato",`, a line of a stack with its count of samples, like `  127  <e-core>`, a line that starts with a date and a time with seconds, like `2026-11-01 10:15:30` of `log show` and `/var/log/install.log` (with seconds, so a sentence that starts with a date and a time, like `2026-11-01 10:15 the icon went away`, still counts), and a line with a memory address, like a stack frame (`[0x10939e154]`). Their words are not the words of the visitor, so they would push the right answer down.
*/
const logLinePattern = /^(?:[\w \t./()-]+:\s{2,}|[\s{[]*"[^"]+"\s*:|\s*\d+\s{2,}|\s*\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2})|\b0x[\da-f]{4,}/i;

const withoutLogLines = text => text.split('\n').filter(line => !logLinePattern.test(line)).join('\n');

// A line that only a crash report has, in the text format, like `Exception Type:  EXC_CRASH`, or in the JSON format of an `.ips` file, like `"bug_type":"309"`.
const crashReportPattern = /^(?:Incident Identifier|Crashed Thread|Exception Type):|"bug_type"/m;

// The name of a crash report file, like `Dato-2026-11-01-101530.ips`, or `.crash` of older macOS versions.
const crashReportFilePattern = /\.(?:ips|crash)$/i;

// The function that finds the questions a message is about, among the general questions and the questions of the app, when the page has one.
function questionMatcher(data, app) {
	// The word rules of the site generator, so the message is split and matched like the questions.
	const {wordsIn, wordsMatch} = wordMatcher(data);
	let questions = data.generalQuestions;

	if (app) {
		// Questions about platforms the app is not on are left out.
		questions = questions.filter(question => !question.platforms || question.platforms.some(platform => app.platforms.includes(platform)));
		questions = [...app.questions.map(question => ({...question, isAppSpecific: true})), ...questions];
	}

	// The words a message can match: the words of the question, and its keywords and synonyms.
	questions = questions.map(question => ({...question, words: [...question.questionWords, ...question.extraWords]}));

	const allWords = new Set(questions.flatMap(question => question.words));

	// The name of the app, which visitors often write, like “Velja is great”, is left out of the message, as many questions of the app have it, so it would match them all. Only the whole name, so “calendar” still counts for Menu Bar Calendar. A limitation: for an app whose name is a common word, like Actions, the word is left out too, so the other words of the message must match.
	const appTitlePattern = app ? new RegExp(`\\b${RegExp.escape(app.title)}\\b`, 'gi') : undefined;
	const withoutAppTitle = text => appTitlePattern ? text.replaceAll(appTitlePattern, ' ') : text;

	// Jaccard similarity of all the words of two questions, to leave out a general question that repeats an app question.
	const similarity = (first, second) => {
		const firstWords = new Set(first.toLowerCase().match(/\w+/g));
		const secondWords = new Set(second.toLowerCase().match(/\w+/g));
		return firstWords.intersection(secondWords).size / firstWords.union(secondWords).size;
	};

	const matchingQuestions = message => {
		const messageWords = [...new Set(wordsIn(withoutAppTitle(withoutLogLines(message))))];

		// Words that no question has, like “didnt”, do not raise the number of words a question needs.
		const knownWords = messageWords.filter(messageWord => allWords.values().some(word => wordsMatch(messageWord, word)));
		const minimumMatchCount = knownWords.length <= 1 ? 1 : 2;

		// How many questions each word is in, with the same matching as below, so “browsers” is as common as “browser”. Rare words count more.
		const weights = new Map(messageWords.map(messageWord => {
			const questionCount = questions.filter(question => question.questionWords.some(word => wordsMatch(messageWord, word))).length;
			return [messageWord, Math.log((questions.length + 1) / (questionCount + 1))];
		}));

		const scoredQuestions = questions
			.map(question => {
				let score = 0;
				let matchCount = 0;

				for (const messageWord of messageWords) {
					if (question.words.some(word => wordsMatch(messageWord, word))) {
						score += weights.get(messageWord);
						matchCount++;
					}
				}

				return {question, score, matchCount};
			})
			.filter(({score, matchCount}) => score > 0 && matchCount >= minimumMatchCount);

		// A pinned question only goes first when it matches as many words as the best other question, so it does not push down an exact match.
		const bestUnpinnedMatchCount = Math.max(0, ...scoredQuestions.filter(({question}) => question.pinnedRank === undefined).map(({matchCount}) => matchCount));
		const pinnedRank = ({question, matchCount}) => matchCount >= bestUnpinnedMatchCount ? question.pinnedRank ?? Number.POSITIVE_INFINITY : Number.POSITIVE_INFINITY;

		const results = scoredQuestions
			.sort((first, second) => {
				if (pinnedRank(first) !== pinnedRank(second)) {
					return pinnedRank(first) - pinnedRank(second);
				}

				if (first.matchCount !== second.matchCount) {
					return second.matchCount - first.matchCount;
				}

				if (first.question.isAppSpecific !== second.question.isAppSpecific) {
					return first.question.isAppSpecific ? -1 : 1;
				}

				return second.score - first.score;
			})
			.map(({question}) => question);

		const appResults = results.filter(question => question.isAppSpecific);

		return results
			.filter(question => question.isAppSpecific || !appResults.some(appQuestion => similarity(question.question, appQuestion.question) >= 0.6))
			.slice(0, 4);
	};

	return matchingQuestions;
}

class FAQSuggestions extends HTMLElement {
	// The questions, which are read on the first input, as they are large, and the app of the page among them, which the page script has set before. Limitation: an app that the visitor picks after the first input does not change the suggestions or the crash report steps, as most visitors pick the app first.
	#data;
	#app;

	// The function that finds the questions a message is about. It is made on the first input, after the page script has set the `app` attribute.
	#matchingQuestions;

	#isDismissed = false;
	#timer;

	// The URLs of the questions in the list, so the list is only rebuilt, and its count announced, when they change.
	#renderedURLs;

	connectedCallback() {
		// The same functions, so connecting the element again does not add second listeners.
		this.#message.addEventListener('input', this.#suggest);
		// The attachments of the form, for the crash warning.
		this.#message.form?.addEventListener('change', this.#suggest);
		parts(this).dismiss.addEventListener('click', this.#dismiss);
		parts(this).attachFiles.addEventListener('click', this.#attachFiles);
		window.addEventListener('pageshow', this.#suggestForRestoredMessage);
	}

	// When the page comes back without the back/forward cache, like after Back from an answer, the browser puts the text back in the message before the page shows, but sends no `input` event, so the related help and the crash warning would stay away until the visitor types again. Not for an empty message, so the page does not read the questions before the visitor writes.
	#suggestForRestoredMessage = () => {
		if (this.#message.value) {
			this.#suggest();
		}
	};

	// The message field, which the `for` attribute names, like the `for` of a label.
	get #message() {
		return document.getElementById(this.getAttribute('for'));
	}

	#suggest = () => {
		const textarea = this.#message;
		const {
			panel,
			list,
			crashWarning,
			macCrashReportSteps,
			appName,
			count,
			template,
		} = parts(this);

		clearTimeout(this.#timer);

		this.#timer = setTimeout(() => {
			// A word that starts with “crash”, or the text of the crash dialog of macOS, like “Dato quit unexpectedly.”, which visitors often copy. Not when the message already has a crash report, which has “Crashed” in it, or a crash report is attached.
			const hasCrashReportFile = [...this.#fileInput?.files ?? []].some(file => crashReportFilePattern.test(file.name));
			crashWarning.hidden = !/\bcrash|\bquits? unexpectedly/i.test(textarea.value) || crashReportPattern.test(textarea.value) || hasCrashReportFile;

			if (!this.#data) {
				this.#data = scriptData(this.getAttribute('questions'));
				this.#app = this.#data.apps.find(candidate => candidate.title === this.getAttribute('app'));

				// The steps to attach the crash reports from the file dialog, which is the open panel of macOS, only for an app on macOS in a browser on a Mac. Only once, as the app does not change, and screen readers would read the live region again for each change.
				macCrashReportSteps.hidden = !(isMac && this.#app?.platforms.includes('macOS'));
				appName.textContent = this.#app?.title ?? '';
			}

			// After a dismiss, only the crash warning still follows the text.
			if (this.#isDismissed) {
				return;
			}

			this.#matchingQuestions ??= questionMatcher(this.#data, this.#app);

			const matches = this.#matchingQuestions(textarea.value);
			if (matches.length === 0) {
				// A new word can leave no question for a moment, like a second word that needs a question with both words, so the panel keeps the last questions while the visitor writes, and the fields below do not jump. It hides when the message is empty.
				if (!panel.hidden && textarea.value.trim()) {
					return;
				}

				panel.hidden = true;
				count.textContent = '';
				// The list is built again when the panel comes back, so screen readers hear its number again.
				this.#renderedURLs = undefined;
				return;
			}

			const urls = matches.map(({url}) => url).join(' ');
			if (urls !== this.#renderedURLs) {
				this.#renderedURLs = urls;
				list.replaceChildren(...matches.map(({question, url, label}) => {
					const item = cloneTemplate(template);
					const {link, label: labelText, question: questionText} = parts(item);
					link.href = url;
					questionText.textContent = question;

					// A guide or a tip says what it is, like “Guide: ”, as its link opens a how-to and not an answer.
					if (label) {
						labelText.textContent = `${label}: `;
					} else {
						labelText.remove();
					}

					return item;
				}));

				// Screen readers hear the number in the live region, not all the questions again for each change.
				count.textContent = `${matches.length} related help ${matches.length === 1 ? 'answer' : 'answers'}`;
			}

			panel.hidden = false;
		}, 350);
	};

	// The file input of the form (`AttachmentPicker`).
	get #fileInput() {
		return [...this.#message.form?.elements ?? []].find(element => element.type === 'file');
	}

	// The button in the steps for a Mac opens the file dialog of the form, where the next steps are.
	#attachFiles = () => {
		this.#fileInput?.click();
	};

	#dismiss = () => {
		this.#isDismissed = true;
		parts(this).panel.hidden = true;

		// The button had the focus, so it goes back to the message, which the suggestions are about.
		this.#message.focus();
	};
}

customElements.define('faq-suggestions', FAQSuggestions);
