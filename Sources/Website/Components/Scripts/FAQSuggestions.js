/*
FAQ suggestions: while the visitor types, the message is split into words (three or more letters, without stopwords), and each question is scored by the words it shares with the message. Rare words count more (TF-IDF). The site generator prepares the words of each question, with synonyms. Pinned questions come first, then questions with more matching words, then app questions, then higher scores. A question needs two matching words, or one for messages with only one known word.
*/

// The function that finds the questions a message is about, among the general questions and the questions of the app with the title.
function questionMatcher(data, appTitle) {
	const generalQuestions = data.generalQuestions ?? [];
	const stopwords = new Set(data.stopwords ?? []);
	const app = (data.apps ?? []).find(app => app.title === appTitle);

	let questions = generalQuestions;

	if (app) {
		// Questions about platforms the app is not on are left out.
		questions = questions.filter(question => !question.platforms || question.platforms.some(platform => app.platforms.includes(platform)));
		questions = [...(app.questions ?? []).map(question => ({...question, isAppSpecific: true})), ...questions];
	}

	// The words a message can match: the words of the question, and its keywords and synonyms.
	questions = questions.map(question => ({...question, words: [...question.questionWords, ...question.extraWords]}));

	const allWords = new Set(questions.flatMap(question => question.words));

	// Apostrophes are removed first, as in the site generator, so “doesn't” becomes “doesnt”.
	const wordsIn = text => (text.toLowerCase().replaceAll(/['’]/g, '').match(/[a-z\d_]{3,}/g) ?? []).filter(word => !stopwords.has(word));

	// Words with the same start match, like “sync” and “syncing”.
	const wordsMatch = (first, second) => first.startsWith(second) || second.startsWith(first);

	// Jaccard similarity of all the words of two questions, to leave out a general question that repeats an app question.
	const similarity = (first, second) => {
		const firstWords = new Set(first.toLowerCase().match(/\w+/g));
		const secondWords = new Set(second.toLowerCase().match(/\w+/g));
		return firstWords.intersection(secondWords).size / firstWords.union(secondWords).size;
	};

	const pinnedRank = question => question.pinnedRank ?? Number.POSITIVE_INFINITY;

	const matchingQuestions = message => {
		const messageWords = [...new Set(wordsIn(message))];

		// Words that no question has, like “didnt”, do not raise the number of words a question needs.
		const knownWords = messageWords.filter(messageWord => allWords.values().some(word => wordsMatch(messageWord, word)));
		const minimumMatchCount = knownWords.length <= 1 ? 1 : 2;

		// How many questions each word is in, with the same matching as below, so “browsers” is as common as “browser”. Rare words count more.
		const weights = new Map(messageWords.map(messageWord => {
			const questionCount = questions.filter(question => question.questionWords.some(word => wordsMatch(messageWord, word))).length;
			return [messageWord, Math.log((questions.length + 1) / (questionCount + 1))];
		}));

		const results = questions
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
			.filter(({score, matchCount}) => score > 0 && matchCount >= minimumMatchCount)
			.sort((first, second) => {
				if (first.question.pinnedRank !== undefined || second.question.pinnedRank !== undefined) {
					return pinnedRank(first.question) - pinnedRank(second.question);
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

export default class extends HTMLElement {
	// The function that finds the questions a message is about. It is made on the first input, after the page script has set the `app` attribute.
	#matchingQuestions;

	#isDismissed = false;
	#timer;

	// The URLs of the questions in the list, so the list is only rebuilt when they change, as the live region reads all of it again.
	#renderedURLs;

	connectedCallback() {
		// The same functions, so connecting the element again does not add second listeners.
		this.#message.addEventListener('input', this.#suggest);
		this.querySelector('[data-part="dismiss"]').addEventListener('click', this.#dismiss);
	}

	// The message field, which the `for` attribute names, like the `for` of a label.
	get #message() {
		return document.getElementById(this.getAttribute('for'));
	}

	#suggest = () => {
		const textarea = this.#message;
		const panel = this.querySelector('[data-part="panel"]');
		const list = this.querySelector('[data-part="list"]');
		const crashWarning = this.querySelector('[data-part="crashWarning"]');

		clearTimeout(this.#timer);

		this.#timer = setTimeout(() => {
			crashWarning.hidden = !/\bcrash/i.test(textarea.value);

			// After a dismiss, only the crash warning still follows the text.
			if (this.#isDismissed) {
				return;
			}

			this.#matchingQuestions ??= questionMatcher(JSON.parse(this.querySelector('[data-part="questions"]').textContent), this.getAttribute('app'));

			const matches = this.#matchingQuestions(textarea.value);
			if (matches.length === 0) {
				panel.hidden = true;
				// The list is built again when the panel comes back, so screen readers read it again.
				this.#renderedURLs = undefined;
				return;
			}

			const urls = matches.map(({url}) => url).join(' ');
			if (urls !== this.#renderedURLs) {
				this.#renderedURLs = urls;
				list.replaceChildren(...matches.map(({question, url}) => {
					const item = this.querySelector('[data-part="template"]').content.firstElementChild.cloneNode(true);
					item.querySelector('a').href = url;
					item.querySelector('[data-part="question"]').textContent = question;
					return item;
				}));
			}

			panel.hidden = false;
		}, 350);
	};

	#dismiss = () => {
		this.#isDismissed = true;
		this.querySelector('[data-part="panel"]').hidden = true;

		// The button had the focus, so it goes back to the message, which the suggestions are about.
		this.#message.focus();
	};
}
