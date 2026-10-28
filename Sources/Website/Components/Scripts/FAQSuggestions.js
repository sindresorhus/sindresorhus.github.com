import {cloneTemplate} from '/scripts/dom.js';

/*
FAQ suggestions: while the visitor types, the message is split into words (three or more letters, without stopwords), and each question is scored by the words it shares with the message. Rare words count more (TF-IDF). The site generator prepares the words of each question, with synonyms. Pinned questions come first when they match as many words as the best other question, then questions with more matching words, then app questions, then higher scores. A question needs two matching words, or one for messages with only one known word.
*/

/*
The lines of a log that the visitor pasted, like the diagnostic report that the form asks for: a field, like `Command:   Actions` (a colon and two or more spaces), a field of the JSON of a crash report, like `"procName" : "Dato",`, a line of a stack with its count of samples, like `  127  <e-core>`, and a line with a memory address, like a stack frame (`[0x10939e154]`). Their words are not the words of the visitor, so they would push the right answer down.
*/
const logLinePattern = /^(?:[\w \t./()-]+:\s{2,}|[\s{[]*"[^"]+"\s*:|\s*\d+\s{2,})|\b0x[\da-f]{4,}/i;

const withoutLogLines = text => text.split('\n').filter(line => !logLinePattern.test(line)).join('\n');

// A line that only a crash report has, in the text format, like `Exception Type:  EXC_CRASH`, or in the JSON format of an `.ips` file, like `"bug_type":"309"`.
const crashReportPattern = /^(?:Incident Identifier|Crashed Thread|Exception Type):|"bug_type"/m;

// The endings of the forms of a word, and no ending, for the same word.
const wordEndings = new Set(['', 's', 'es', 'ed', 'ing', 'er', 'ly']);

// The endings that a word without its last “e” takes, like “freezing” for “freeze”.
const vowelEndings = new Set(['es', 'ed', 'ing', 'er']);

// The function that finds the questions a message is about, among the general questions and the questions of the app with the title.
function questionMatcher(data, appTitle) {
	const stopwords = new Set(data.stopwords);
	const app = data.apps.find(app => app.title === appTitle);

	let questions = data.generalQuestions;

	if (app) {
		// Questions about platforms the app is not on are left out.
		questions = questions.filter(question => !question.platforms || question.platforms.some(platform => app.platforms.includes(platform)));
		questions = [...app.questions.map(question => ({...question, isAppSpecific: true})), ...questions];
	}

	// The words a message can match: the words of the question, and its keywords and synonyms.
	questions = questions.map(question => ({...question, words: [...question.questionWords, ...question.extraWords]}));

	const allWords = new Set(questions.flatMap(question => question.words));

	// Apostrophes are removed first, as in the site generator, so “doesn't” becomes “doesnt”.
	const wordsIn = text => (text.toLowerCase().replaceAll(/['’]/g, '').match(/[a-z\d_]{3,}/g) ?? []).filter(word => !stopwords.has(word));

	// Another form of the same word matches: the word with an ending, like “syncs”, “synced”, and “syncing” for “sync”, also with a doubled last letter, like “quitting” for “quit”, or without a last “e”, like “freezing” for “freeze”. Not a longer word with the same start, like “freezing” for “free”.
	const wordsMatch = (first, second) => {
		const [shorter, longer] = first.length <= second.length ? [first, second] : [second, first];
		// Without its last “e”, a word only takes an ending that starts with a vowel, so “one” does not match “only”.
		const stems = [[shorter, wordEndings], [shorter + shorter.at(-1), wordEndings], ...(shorter.endsWith('e') ? [[shorter.slice(0, -1), vowelEndings]] : [])];
		return stems.some(([stem, endings]) => longer.startsWith(stem) && endings.has(longer.slice(stem.length)));
	};

	// Jaccard similarity of all the words of two questions, to leave out a general question that repeats an app question.
	const similarity = (first, second) => {
		const firstWords = new Set(first.toLowerCase().match(/\w+/g));
		const secondWords = new Set(second.toLowerCase().match(/\w+/g));
		return firstWords.intersection(secondWords).size / firstWords.union(secondWords).size;
	};

	const matchingQuestions = message => {
		const messageWords = [...new Set(wordsIn(withoutLogLines(message)))];

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
	// The function that finds the questions a message is about. It is made on the first input, after the page script has set the `app` attribute.
	#matchingQuestions;

	#isDismissed = false;
	#timer;

	// The URLs of the questions in the list, so the list is only rebuilt, and its count announced, when they change.
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
		const count = this.querySelector('[data-part="count"]');

		clearTimeout(this.#timer);

		this.#timer = setTimeout(() => {
			// A word that starts with “crash”, or the text of the crash dialog of macOS, like “Dato quit unexpectedly.”, which visitors often copy. Not when the message already has a crash report, which has “Crashed” in it.
			crashWarning.hidden = !/\bcrash|\bquits? unexpectedly/i.test(textarea.value) || crashReportPattern.test(textarea.value);

			// After a dismiss, only the crash warning still follows the text.
			if (this.#isDismissed) {
				return;
			}

			this.#matchingQuestions ??= questionMatcher(JSON.parse(document.getElementById(this.getAttribute('questions')).textContent), this.getAttribute('app'));

			const matches = this.#matchingQuestions(textarea.value);
			if (matches.length === 0) {
				panel.hidden = true;
				count.textContent = '';
				// The list is built again when the panel comes back, so screen readers hear its number again.
				this.#renderedURLs = undefined;
				return;
			}

			const urls = matches.map(({url}) => url).join(' ');
			if (urls !== this.#renderedURLs) {
				this.#renderedURLs = urls;
				list.replaceChildren(...matches.map(({question, url}) => {
					const item = cloneTemplate(this.querySelector('[data-part="template"]'));
					item.querySelector('[data-part="link"]').href = url;
					item.querySelector('[data-part="question"]').textContent = question;
					return item;
				}));

				// Screen readers hear the number in the live region, not all the questions again for each change.
				count.textContent = `${matches.length} related help ${matches.length === 1 ? 'answer' : 'answers'}`;
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

customElements.define('faq-suggestions', FAQSuggestions);
