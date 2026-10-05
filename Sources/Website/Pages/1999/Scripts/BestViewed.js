// The “Best viewed with…” buttons on the 1999 page: each sets its view on the panel of the page, which the styles of the panel show. Lynx shows the text of each image in brackets instead of the image, like Lynx did, and [INLINE] for an image without text.
const viewMessages = {
	eyes: 'Back to normal. Best viewed with eyes, and yours work fine.',
	lynx: 'Welcome, Lynx user! No images, no colors, no problem.',
	monitor: 'Now in glorious green, like the monitor in the computer room at school.',
	'16-bit': '16-bit color! That is 65,536 colors, and my page uses all of them.',
	'3d': 'Put on your 3D glasses! The red and blue ones from the cereal box.',
	shades: 'Dark mode, 20 years early. Cool shades not included.',
	australia: 'G’day, mate! The page is now the right way up for visitors in Australia.',
};

export default class extends GeoCitiesElement {
	connected() {
		const {lynxTemplate} = this.parts;
		const panel = document.querySelector('#geocities-panel');
		const viewButtons = [...this.querySelectorAll('[data-best-viewed]')];
		let lynxLabels = [];

		const showLynxLabels = isShown => {
			for (const label of lynxLabels) {
				label.remove();
			}

			lynxLabels = [];

			if (!isShown) {
				return;
			}

			for (const image of panel.querySelectorAll('img[src^="/1999/"]')) {
				const label = lynxTemplate.content.firstElementChild.cloneNode(true);
				label.textContent = `[${image.alt || 'INLINE'}]`;
				(image.closest('picture') ?? image).after(label);
				lynxLabels.push(label);
			}
		};

		const showView = async (view, button) => {
			if (button.ariaPressed === 'true') {
				return;
			}

			const isTurning = view === 'australia' || panel.dataset.bestViewedView === 'australia';
			showLynxLabels(view === 'lynx');

			if (view === 'eyes') {
				delete panel.dataset.bestViewedView;
			} else {
				panel.dataset.bestViewedView = view;
			}

			for (const item of viewButtons) {
				const isPressed = item === button;
				item.ariaPressed = String(isPressed);

				if (isPressed) {
					item.dataset.state = 'on';
				} else {
					delete item.dataset.state;
				}
			}

			this.toast(viewMessages[view]);

			// The page turns around its middle, so all of it stays where the page can scroll, and then the buttons come back into view, so the visitor can turn it back.
			if (isTurning) {
				// Reading the style starts the turn, so its transition is there to wait for.
				getComputedStyle(panel).rotate;
				await Promise.allSettled(panel.getAnimations().filter(animation => animation instanceof CSSTransition).map(animation => animation.finished));
				button.scrollIntoView({behavior: 'instant', block: 'center'});
				button.focus({preventScroll: true});
			}
		};

		for (const button of viewButtons) {
			if (button.ariaPressed === 'true') {
				button.dataset.state = 'on';
			}

			this.on(button, 'click', () => {
				showView(button.dataset.bestViewed, button);
			});
		}
	}
}
