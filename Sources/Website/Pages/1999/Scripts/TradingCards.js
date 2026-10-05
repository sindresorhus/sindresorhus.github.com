// Unimon trading cards on the 1999 page: a pack has three common cards, an uncommon card, and a rare holo card in two packs of five, or else another uncommon card. The binder keeps how many of each card the visitor has, in the browser, and Kevin offers trades for the extra cards.
const randomItem = items => items[Math.floor(Math.random() * items.length)];
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));

// A copy of the first element of a template.
const cloneTemplate = template => template.content.firstElementChild.cloneNode(true);

// Like “1 pack” or “2 packs”.
const plural = (count, word) => `${count.toLocaleString('en-US')} ${word}${count === 1 ? '' : 's'}`;

// The foil of a holo card shines where the pointer is. The cards of a pack are made again for each pack, so their listeners go away with them.
const addShine = element => {
	if (element.dataset.unimonRarity !== 'rare') {
		return;
	}

	element.addEventListener('pointermove', event => {
		const bounds = element.getBoundingClientRect();
		const x = (event.clientX - bounds.left) / bounds.width;
		element.style.setProperty('--unimon-shine', `${(0.5 - x) * 60}%`);
	});
};

export default class extends GeoCitiesElement {
	connected() {
		const {pack: packButton, pull, status, trade, tradeText, tradeAccept: acceptButton, tradeDecline: declineButton, binderTitle, binder} = this.parts;
		const cards = [...this.querySelectorAll('template[data-unimon-card]')].map(template => ({
			id: template.dataset.unimonCard,
			template,
			name: template.content.querySelector('strong').textContent,
			rarity: template.content.firstElementChild.dataset.unimonRarity,
		}));
		const collection = this.stored('collection', {counts: {}, packs: 0});
		// The stored counts could be anything, so each is a whole number of cards.
		if (typeof collection.counts !== 'object' || collection.counts === null || Array.isArray(collection.counts)) {
			collection.counts = {};
		}

		if (!Number.isInteger(collection.packs) || collection.packs < 0) {
			collection.packs = 0;
		}

		let isOpening = false;
		let offer;

		const count = card => {
			const value = collection.counts[card.id];
			return Number.isInteger(value) && value > 0 ? value : 0;
		};

		const add = (card, amount = 1) => {
			collection.counts[card.id] = count(card) + amount;
		};

		const pick = rarity => randomItem(cards.filter(card => card.rarity === rarity));

		const renderBinder = () => {
			const collected = cards.filter(card => count(card) > 0).length;
			binderTitle.textContent = `My Binder: ${collected} of ${cards.length} cards · ${plural(collection.packs, 'pack')} opened`;
			for (const [index, card] of cards.entries()) {
				const slot = binder.querySelector(`[data-unimon-slot="${card.id}"]`);
				if (count(card) === 0) {
					delete slot.dataset.state;
					delete slot.dataset.unimonRarity;
					slot.textContent = '?';
					slot.setAttribute('aria-label', `Card ${index + 1}: not collected yet`);
					continue;
				}

				slot.dataset.state = 'filled';
				slot.dataset.unimonRarity = card.rarity;
				const name = document.createElement('span');
				name.textContent = card.name;
				const amount = document.createElement('span');
				amount.textContent = `×${count(card)}`;
				slot.replaceChildren(card.template.content.querySelector('picture').cloneNode(true), name, amount);
				slot.setAttribute('aria-label', `${card.name}${card.rarity === 'rare' ? ' (holo)' : ''}, ${count(card)}`);
			}
		};

		const hideOffer = () => {
			offer = undefined;
			const hadFocus = trade.contains(document.activeElement);
			trade.hidden = true;
			if (hadFocus) {
				packButton.focus();
			}
		};

		// Kevin mostly wants the best card of the visitor for a pile of common ones, and only sometimes offers a fair trade, for a card that the visitor does not have yet.
		const makeOffer = () => {
			const extras = cards.filter(card => count(card) >= 2);
			const missing = cards.filter(card => count(card) === 0);
			// He wants any of the holo cards of the visitor, not always the same one, or an uncommon card when the visitor has no holo cards.
			const owned = rarity => cards.filter(card => card.rarity === rarity && count(card) > 0);
			const best = randomItem(owned('rare').length > 0 ? owned('rare') : owned('uncommon'));
			if (extras.length > 0 && missing.length > 0 && Math.random() < 0.35) {
				const wanted = randomItem(extras);
				const offered = randomItem(missing);
				offer = {give: [[wanted, 2]], get: [[offered, 1]], isFair: true};
				tradeText.textContent = `Kevin: ok fine. i give u ${offered.name} for 2× ${wanted.name}. my mom says i have to be nice`;
			} else if (best) {
				const junk = pick('common');
				const amount = randomInteger(2, 4);
				offer = {give: [[best, 1]], get: [[junk, amount]], isFair: false};
				tradeText.textContent = `Kevin: hey wanna trade? i give u ${amount}× ${junk.name} for ur ${best.name}. its a good deal. trust me`;
			} else {
				return;
			}

			trade.hidden = false;
			// The offer comes after what the pack gave, which `say()` says in the same frame.
			this.say(tradeText.textContent, status, {join: true});
		};

		const openPack = async () => {
			isOpening = true;
			hideOffer();
			packButton.dataset.state = 'opening';
			await this.wait(this.reducedMotion ? 0 : 700);
			delete packButton.dataset.state;
			pull.replaceChildren();

			const packCards = [pick('common'), pick('common'), pick('common'), pick('uncommon'), Math.random() < 0.4 ? pick('rare') : pick('uncommon')];
			const names = [];
			for (const card of packCards) {
				const isNew = count(card) === 0;
				add(card);
				const element = cloneTemplate(card.template);
				element.dataset.state = 'new';
				addShine(element);
				pull.append(element);
				names.push(`${card.name}${card.rarity === 'rare' ? ' (HOLO!)' : ''}${isNew ? ' (new)' : ''}`);
				if (!this.reducedMotion) {
					await this.wait(250);
				}
			}

			collection.packs++;
			this.store('collection', collection);
			renderBinder();
			const hasRare = packCards.some(card => card.rarity === 'rare');
			this.say(`You got: ${names.join(', ')}.${hasRare ? ' A rare holo card!' : ''}`);
			if (hasRare) {
				this.cheer();
			}

			if (cards.every(card => count(card) > 0) && !collection.isComplete) {
				collection.isComplete = true;
				this.store('collection', collection);
				this.toast('You collected all the Unimon cards! Kevin is so jealous.');
				this.celebrate();
			} else if (Math.random() < 0.5) {
				makeOffer();
			}

			isOpening = false;
		};

		this.on(packButton, 'click', () => {
			if (!isOpening) {
				openPack();
			}
		});

		this.on(acceptButton, 'click', () => {
			if (!offer) {
				return;
			}

			for (const [card, amount] of offer.give) {
				add(card, -amount);
			}

			for (const [card, amount] of offer.get) {
				add(card, amount);
			}

			this.store('collection', collection);
			renderBinder();
			this.say(offer.isFair ? 'A fair trade! Kevin must be sick today.' : 'Kevin ripped you off. Again. He is already showing your card to everyone.');
			hideOffer();
		});

		this.on(declineButton, 'click', () => {
			this.say('Kevin: ur loss');
			hideOffer();
		});

		renderBinder();
	}
}
