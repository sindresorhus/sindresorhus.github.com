// WaffleMail on the 1999 page: an inbox of 1999, with a list of messages and the open one below it. Some messages have buttons that play out the hoax or the spam, and new messages arrive when the visitor breaks a chain, writes one, or waits for Bill Gates to pay. How far the e-mail of Bill Gates went is kept in the browser.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));

// A copy of the first element of a template.
const cloneTemplate = template => template.content.firstElementChild.cloneNode(true);

// The hoax promised $245 for each person the visitor sent it to, $243 for each person they sent it to, and $241 for everyone after that. Each day, everyone sends it to 10 more people.
const gatesMoney = days => {
	let money = 0;
	let people = 0;
	for (let day = 1; day <= days; day++) {
		const reached = 10 ** day;
		people += reached;
		money += reached * (day === 1 ? 245 : (day === 2 ? 243 : 241));
	}

	return {money, people};
};

// About the number of people on the Internet in 1999.
const internetPopulation = 250_000_000;

export default class extends GeoCitiesElement {
	connected() {
		const {title, list, rowTemplate, reader, readerFrom, readerSubject, readerBody, actions, actionTemplate, compose: composeButton, composer, who: whoSelect, luck: luckSelect, curse: curseSelect, count: countSelect} = this.parts;

		// How far the e-mail of Bill Gates went, by the days since the visitor forwarded it, kept between visits.
		const gates = this.stored('gates', {days: 0});
		// The stored days could be anything, so they are a small whole number, as the money is counted day by day.
		gates.days = Math.min(Math.max(Math.trunc(Number(gates.days)) || 0, 0), 12);

		const gatesText = () => {
			if (gates.days === 0) {
				return '';
			}

			const {money, people} = gatesMoney(gates.days);
			if (people > internetPopulation) {
				return `\n\n— Day ${gates.days}: Your e-mail has reached ${people.toLocaleString('en-US')} people. That is more people than there are on the Internet. Bill Gates owes you $${money.toLocaleString('en-US')}. The check is in the mail. (It is not.)`;
			}

			return `\n\n— Day ${gates.days}: Your e-mail has reached ${people.toLocaleString('en-US')} people. Bill Gates owes you $${money.toLocaleString('en-US')}!`;
		};

		let palmStep = 0;
		let goodTimesForwards = 0;
		let hasSentDollars = false;
		let chainResult = '';
		let nextId = 0;
		let openMessage;

		const messages = [
			{
				from: 'Mamma',
				subject: 'WHO IS USING THE PHONE LINE???',
				date: 'Dec 31',
				body: () => 'SINDRE,\n\nI HAVE TRIED TO CALL GRANDMA FOR 3 HOURS. THE LINE IS BUSY. ARE YOU ON THE INTERNET AGAIN?\n\nDINNER IS AT 6.\n\nLOVE, MAMMA\n\nPS: HOW DO I TURN OFF THE BIG LETTERS',
			},
			{
				from: 'xXGlitterXx',
				subject: 'hi!!! i lernd 2 type',
				date: 'Dec 31',
				body: () => 'hi sindre\n\nneigh. it is me glitter. i typed this with my horn.\n\ni am hungry. pls scroll up and feed me a waffle.\n\nluv glitter\n~*~*~*~*~*~',
			},
			{
				from: 'Bill Gates',
				subject: 'FW: FW: FW: Microsoft e-mail tracking beta!!!',
				date: 'Dec 30',
				body: () => `>>>> Hello everybody, my name is Bill Gates. I have just written an e-mail tracing program that traces everyone to whom this message is forwarded. I am experimenting with this and I need your help.\n>>>>\n>>>> Forward this to everyone you know. For every person you send it to, Microsoft will pay you $245. For every person they send it to, you get $243, and for every person after that, $241.\n>>>>\n>>>> This is not a joke. My lawyer checked it.${gatesText()}`,
				actions: () => [
					gates.days === 0
						? {
							label: 'Forward to 10 Friends',
							run: () => {
								gates.days = 1;
								this.store('gates', gates);
								this.say('Forwarded to 10 friends! Now wait for them to forward it too.');
							},
						}
						: {
							label: 'Wait a Day',
							run: () => {
								if (gatesMoney(gates.days).people > internetPopulation) {
									this.say('Everyone on the Internet has it now. Bill Gates is out of money.');
									return;
								}

								gates.days++;
								this.store('gates', gates);
								this.say(`A day passed. Bill Gates owes you $${gatesMoney(gates.days).money.toLocaleString('en-US')}.`);
								if (gates.days === 3) {
									addMessage({
										from: 'Bill Gates',
										subject: 'RE: FW: FW: FW: Microsoft e-mail tracking beta!!!',
										date: 'Dec 31',
										body: () => 'Who is this? How did you get this address?\n\nPlease stop forwarding this. There is no e-mail tracing program. There is no money.\n\nBill\n\nSent from Windows 98 Second Edition',
									});
								}
							},
						},
				],
			},
			{
				from: 'Prize Center',
				subject: 'CONGRATULATIONS!!! You have WON a FREE Palm Pilot!!!',
				date: 'Dec 29',
				body: () => [
					'CONGRATULATIONS!!!\n\nYou are our 1,000,000th visitor! You have been selected to get a FREE Palm Pilot!!!\n\nThis is NOT spam. You signed up for this when you visited the Internet.\n\nClick CLAIM NOW to get your prize!!!',
					'STEP 2 OF 3\n\nTo make sure that you are a real person, answer this question:\n\nDo you like free things?',
					'STEP 3 OF 3\n\nAlmost there! To confirm, forward this e-mail to 10 friends. They can win a Palm Pilot too!*\n\n*Only one Palm Pilot will be given away.',
					'CONGRATULATIONS!!!\n\nYour FREE Palm Pilot is on its way!*\n\n .--------------.\n | .----------. |\n | |  3:14 PM | |\n | | Graffiti | |\n | \'----------\' |\n |  o  [==]  o  |\n \'--------------\'\n\n*This is a picture of a Palm Pilot. Shipping and handling: $199.99. Stylus, batteries, and Palm Pilot not included.',
				][palmStep],
				actions: () => [
					[{
						label: 'CLAIM NOW!!!',
						run: () => {
							palmStep = 1;
						},
					}],
					[
						{
							label: 'Yes',
							run: () => {
								palmStep = 2;
							},
						},
						{
							label: 'YES!!!',
							run: () => {
								palmStep = 2;
							},
						},
					],
					[{
						label: 'Forward to 10 Friends',
						run: () => {
							palmStep = 3;
							this.toast('You won a Palm Pilot! (A picture of one.)');
						},
					}],
					[],
				][palmStep],
			},
			{
				from: 'Tante Ingrid',
				subject: 'FW: fw: FW: FW: Send this to 10 people in 10 minutes!!!',
				date: 'Dec 28',
				body: () => `This letter has been sent around the world nine times. It started in Norway in 1953.\n\nSend it to 10 people within 10 minutes, and something good will happen to you.\n\nDO NOT BREAK THE CHAIN!!! A boy in Bergen broke the chain, and his modem only connected at 2400 baud for a whole year.${chainResult}`,
				actions: () => chainResult ? [] : [
					{
						label: 'Forward to 10 People',
						run: () => {
							const luck = randomItem(['You will find a waffle within 4 days.', 'Your crush will sign your guestbook.', 'Your modem will connect on the first try tonight.', 'You will win at Solitaire.']);
							chainResult = `\n\n— You forwarded it. Good luck is on its way: ${luck}`;
							this.toast(`Good luck: ${luck}`);
						},
					},
					{
						label: 'Break the Chain',
						run: () => {
							chainResult = '\n\n— You broke the chain. Nothing happened. Yet.';
							this.timeout(6000, () => {
								this.toast('Bad luck: you broke the chain, and your mom found out.');
								addMessage({
									from: 'Mamma',
									subject: 'FW: why did you break the chain???',
									date: 'Dec 31',
									body: () => 'SINDRE,\n\nTANTE INGRID SAYS YOU BROKE THE CHAIN. NOW SHE IS WORRIED ABOUT HER MODEM.\n\nPLEASE SEND IT TO 10 PEOPLE. YOU CAN SEND IT TO ME 10 TIMES.\n\nLOVE, MAMMA',
								});
							});
						},
					},
				],
			},
			{
				from: 'IT Department',
				subject: 'WARNING!!! Good Times virus!!! Read this NOW',
				date: 'Dec 27',
				body: () => `If you get an e-mail called “Good Times”, DO NOT read it! It will erase your hard drive. It will even put your CPU in an nth-complexity infinite binary loop, which can severely damage it.\n\nAOL says it is a very dangerous virus. Forward this warning to everyone you know!!!${goodTimesForwards > 0 ? `\n\n— You warned ${(goodTimesForwards * 52).toLocaleString('en-US')} people, and they warned ${(goodTimesForwards * 52 * 52).toLocaleString('en-US')} more. Congratulations: you are now the Good Times virus. It was never real, but the warning about it spread like one.` : ''}`,
				actions: () => [{
					label: 'Warn Everyone I Know!',
					run: () => {
						goodTimesForwards++;
					},
				}],
			},
			{
				from: 'Dave Rhodes',
				subject: 'MAKE MONEY FAST!!!',
				date: 'Dec 24',
				body: () => `My name is Dave Rhodes. In 1987 my car was taken away and my bills were piling up. Then I found this letter, and now I am rich!\n\nIt is easy! Send $1 to each of the 5 names on the list below. Then take the first name off the list, put your name at the bottom, and send it to 200 people. You will get $50,000 in 60 days!!!\n\nThis is 100% LEGAL.${hasSentDollars ? '\n\n— You sent $5 and put your name on the list. Expected profit: $50,000. Real profit: −$5, and a lot of e-mail.' : ''}`,
				actions: () => hasSentDollars ? [] : [{
					label: 'Send $1 to Everyone',
					run: () => {
						hasSentDollars = true;
					},
				}],
			},
			{
				from: 'Mamma',
				subject: 'FW: Neiman Marcus cookie recipe (they charged $250!!!)',
				date: 'Dec 20',
				body: () => 'My friend had a cookie at Neiman Marcus and asked for the recipe. They said it costs “two-fifty”, and she said yes. Then she got a bill of $250!!!\n\nTo get back at them, send this recipe to everyone you know:\n\n2 cups butter, 4 cups flour, 2 cups sugar, 2 cups brown sugar, 5 cups oatmeal, 4 eggs, 24 oz chocolate chips, 1 grated Hershey bar…\n\nLove, Mamma\n\nPS: I made them with brown cheese. Not as good.',
			},
			{
				from: 'CoolDude2000',
				subject: 'u HAVE to see this!!!!!!!!',
				date: 'Dec 18',
				body: () => 'omg go to the hamster dance page. there are like 100 hamsters dancing. dee doo dee doo.\n\nbest page on the internet.\n\nur page is ok too i guess.\n\na/s/l?',
			},
		];

		for (const message of messages) {
			message.id = nextId++;
			message.isUnread = true;
		}

		const updateTitle = () => {
			const unread = messages.filter(message => message.isUnread).length;
			title.textContent = unread > 0 ? `WaffleMail: Inbox (${unread} new)` : 'WaffleMail: Inbox';
		};

		const renderList = () => {
			list.replaceChildren(...messages.map(message => {
				const row = cloneTemplate(rowTemplate);
				const button = row.querySelector('button');
				const [from, subject] = button.querySelectorAll('span');
				from.textContent = `${message.from} · ${message.date}`;
				subject.textContent = message.subject;
				if (message === openMessage) {
					button.dataset.state = 'open';
					button.setAttribute('aria-current', 'true');
				} else if (message.isUnread) {
					button.dataset.state = 'unread';
					button.setAttribute('aria-label', `Unread: ${message.from}, ${message.subject}`);
				}

				// The rows are made again each time the list changes, so their listeners go away with them.
				button.addEventListener('click', () => {
					open(message);
				});
				return row;
			}));
			updateTitle();
		};

		const renderReader = () => {
			const message = openMessage;
			if (!message) {
				readerFrom.textContent = '';
				readerSubject.textContent = '';
				readerBody.textContent = messages.length > 0 ? 'Pick a message to read it.' : 'Your inbox is empty. Nobody loves you. (Just kidding. Sign my guestbook!)';
				actions.replaceChildren();
				return;
			}

			readerFrom.textContent = `From: ${message.from} · ${message.date}, 1999`;
			readerSubject.textContent = `Subject: ${message.subject}`;
			// The spaces at the start of a line and in a row are kept, for the ASCII art, as the text keeps its line breaks but collapses spaces.
			readerBody.textContent = message.body().replaceAll(/^ +| {2,}/gm, spaces => '\u00A0'.repeat(spaces.length));
			const buttons = (message.actions?.() ?? []).map(action => {
				const button = cloneTemplate(actionTemplate);
				button.textContent = action.label;
				button.addEventListener('click', () => {
					action.run();
					renderReader();
					// The buttons are made again, so the focus goes to the message, which now tells what happened, instead of being lost.
					reader.focus();
				});
				return button;
			});

			const deleteButton = cloneTemplate(actionTemplate);
			deleteButton.textContent = 'Delete';
			deleteButton.addEventListener('click', () => {
				const index = messages.indexOf(message);
				messages.splice(index, 1);
				openMessage = undefined;
				renderList();
				renderReader();
				this.say(`Deleted “${message.subject}”.`);
				// The focus goes to the next message, or the one before it, as the deleted one is gone.
				const next = list.querySelectorAll('button')[Math.min(index, messages.length - 1)];
				(next ?? reader).focus();
			});
			actions.replaceChildren(...buttons, deleteButton);
		};

		const open = message => {
			openMessage = message;
			message.isUnread = false;
			renderList();
			renderReader();
			reader.focus();
		};

		const addMessage = message => {
			message.id = nextId++;
			message.isUnread = true;
			messages.unshift(message);
			// The list is made again, so the focus goes back to the same message.
			const focusedIndex = [...list.querySelectorAll('button')].indexOf(document.activeElement);
			renderList();
			if (focusedIndex !== -1) {
				list.querySelectorAll('button')[focusedIndex + 1]?.focus();
			}

			if (!openMessage) {
				renderReader();
			}

			this.say(`New message from ${message.from}: ${message.subject}`);
		};

		this.on(composeButton, 'click', () => {
			const isOpening = composer.hidden;
			composer.hidden = !isOpening;
			composeButton.setAttribute('aria-expanded', String(isOpening));
			if (isOpening) {
				whoSelect.focus();
			}
		});

		this.on(composer, 'submit', event => {
			event.preventDefault();
			const who = whoSelect.value;
			const luck = luckSelect.value;
			const curse = curseSelect.value;
			const count = countSelect.value;
			const subject = `THIS IS NOT A JOKE!!! (${who} says it is true)`;
			const body = `THIS IS NOT A JOKE!!! ${who.toUpperCase()} SAYS IT IS TRUE!!!\n\nSend this to ${count.toLowerCase()} within 10 minutes. If you do: ${luck.toLowerCase()}!!!\n\nIf you do not: ${curse.toLowerCase()}. This happened to a girl in Bergen.\n\nDO NOT BREAK THE CHAIN!!!`;
			composer.hidden = true;
			composeButton.setAttribute('aria-expanded', 'false');
			composeButton.focus();
			this.say('Your chain letter was sent to 10 friends. Chain letters always come back…');

			// Chain letters always came back to the one who started them, after they went around.
			this.timeout(8000, () => {
				const forwards = randomInteger(4, 9);
				const quote = '> '.repeat(forwards);
				addMessage({
					from: randomItem(['Kevin from school', 'Tante Ingrid', 'CoolDude2000', 'Mamma']),
					subject: `${'FW: '.repeat(forwards)}${subject}`,
					date: 'Dec 31',
					body: () => `omg u HAVE to read this!!! it is TRUE!!!\n\n${quote}${body.replaceAll('\n', `\n${quote}`)}`,
				});
				this.toast('You have new mail! A chain letter. It looks familiar…');
			});
		});

		renderList();
		renderReader();
	}
}
