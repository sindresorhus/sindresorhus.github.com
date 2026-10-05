// NRK Tekst-TV on the 1999 page: pages of 40 letters by 22 lines, in the eight colors of teletext. A line is text with codes: `^` and a lowercase letter sets the color of the text, and an uppercase letter sets the background, like the control codes of real teletext. A line that starts with `#` is double height. A page has subpages, which turn by themselves, like the news, and a text for each language.
const randomInteger = (minimum, maximum) => minimum + Math.floor(Math.random() * (maximum - minimum + 1));

const width = 40;
const colors = {
	k: '#000000',
	r: '#ff0000',
	g: '#00ff00',
	y: '#ffff00',
	b: '#0000ff',
	m: '#ff00ff',
	c: '#00ffff',
	w: '#ffffff',
};

// Wraps a paragraph into lines of the screen, each with a space at the start, like the margin of teletext.
const paragraph = (color, text) => {
	const lines = [];
	let line = '';
	for (const word of text.split(' ')) {
		if (line && `${line} ${word}`.length > width - 2) {
			lines.push(line);
			line = word;
		} else {
			line = line ? `${line} ${word}` : word;
		}
	}

	lines.push(line);
	return lines.map(line => `^${color} ${line}`);
};

// A line of the index, with dots to the page number.
const indexLine = (title, page) => `^c ${title} ${'.'.repeat(width - title.length - 7)}^w${page}`;

// A band in a color across the screen, with the title and the page number, at the top of a page.
const band = (background, title, page) => `^${background}^k ${title}${' '.repeat(width - title.length - 5)}${page}`;

// A line of the map of Norway: the land is green, with a label on the left or the right of it.
const mapLine = (start, length, label = '', side = 'right') => side === 'left'
	? `^w${label.padEnd(start)}^G${' '.repeat(length)}^K`
	: `${' '.repeat(start)}^G${' '.repeat(length)}^K^w ${label}`;

// The logo, in double height letters on bands of color.
const logo = ['#^B^w  NRK  ^K ^Y^k TEKST-TV ^K ^c 31.12.1999'];

const map = [
	mapLine(24, 7, 'Kirkenes -21 ', 'left'),
	mapLine(19, 11, 'Tromsø -14 ', 'left'),
	mapLine(16, 8),
	mapLine(13, 7, 'Bodø -6 ', 'left'),
	mapLine(11, 6),
	mapLine(9, 6, 'Mo i Rana -11'),
	mapLine(7, 7, 'Trondheim -9'),
	mapLine(5, 10),
	mapLine(3, 13, 'Hamar -15'),
	mapLine(2, 15, 'Oslo -12'),
	mapLine(1, 14, '<- Bergen +4'),
	mapLine(2, 12, 'Stavanger +2'),
	mapLine(5, 8, 'Kristiansand -3'),
];

// The picture of the TV under the subtitles: the dining room of Dinner for One, in blocks.
const dinnerRoom = [
	'^B',
	'^B          ^w▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄',
	'^B          ^w█  ^y▄█▄ ^w      ^y▄█▄ ^w  █',
	'^B          ^w█   ^y█  ^w ^m▀▄▀^w  ^y█  ^w  █',
	'^B          ^w▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀',
	'^B    ^y▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄',
	'^B    ^y█ ^w▄ ▄   ▄ ▄   ▄ ▄   ▄ ▄^y      █',
	'^B    ^y█                            █',
	'^B    ^y▀▀█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█▀▀',
	'^B      ^y█                        █',
	'^B   ^y▄▀▀▄^r▀▀▀▄',
	'^B   ^y▀▄▄▀^r▄▄▄▀',
	'^B',
];

const subtitle = (norwegian, english) => ({
	no: [' (Grevinnen og hovmesteren, NRK1)', '', ...dinnerRoom, '', ...paragraph('w', norwegian).map(line => `^K${line}`)],
	en: [' (Dinner for One, NRK1)', '', ...dinnerRoom, '', ...paragraph('w', english).map(line => `^K${line}`)],
});

const pages = {
	100: {
		title: ['Forside', 'Front page'],
		subpages: [{
			no: [
				...logo,
				'',
				'#^y Velkommen til NRK Tekst-TV!',
				'',
				indexLine('NYHETER', 101),
				indexLine('UTENRIKS', 102),
				indexLine('VÆRET', 150),
				indexLine('Y2K: ER DU KLAR?', 199),
				indexLine('SPORT', 200),
				indexLine('TV I KVELD', 300),
				indexLine('VAFFELOPPSKRIFT', 456),
				indexLine('TEKSTING', 777),
				'',
				'^m Det finnes en hemmelig side.',
				'^m Finn den selv! Glitter liker 5.',
				'',
				'^r Nyheter ^g Sport ^y Været ^c TV',
			],
			en: [
				...logo,
				'',
				'#^y Welcome to NRK Tekst-TV!',
				'',
				indexLine('NEWS', 101),
				indexLine('WORLD', 102),
				indexLine('WEATHER', 150),
				indexLine('Y2K: ARE YOU READY?', 199),
				indexLine('SPORT', 200),
				indexLine('TV TONIGHT', 300),
				indexLine('WAFFLE RECIPE', 456),
				indexLine('SUBTITLES', 777),
				'',
				'^m There is a secret page.',
				'^m Find it yourself! Glitter likes 5.',
				'',
				'^r News ^g Sport ^y Weather ^c TV',
			],
		}],
	},
	101: {
		title: ['Nyheter', 'News'],
		subpages: [
			{
				no: [band('Y', 'NYHETER', '1/3'), '', '#^w Gutt (10) lager hjemmeside', '', ...paragraph('c', 'En gutt fra Norge har laget en hjemmeside med 400 animerte GIF-er, en gjestebok og en enhjørning.'), '', ...paragraph('c', '– Den er ikke ferdig. Den er under konstruksjon, sier gutten.'), '', ...paragraph('c', 'Moren hans er stolt, men vil gjerne bruke telefonen snart.')],
				en: [band('Y', 'NEWS', '1/3'), '', '#^w Boy (10) makes home page', '', ...paragraph('c', 'A boy from Norway has made a home page with 400 animated GIFs, a guestbook, and a unicorn.'), '', ...paragraph('c', '“It is not done. It is under construction,” the boy says.'), '', ...paragraph('c', 'His mother is proud, but would like to use the phone soon.')],
			},
			{
				no: [band('Y', 'NYHETER', '2/3'), '', '#^w Rekordsalg av vaffeljern', '', ...paragraph('c', 'Butikkene har aldri solgt så mange vaffeljern som i desember.'), '', ...paragraph('c', '– Folk vil ha vafler hvis verden går under ved midnatt, sier en selger i Bergen.'), '', ...paragraph('c', 'Brunost er utsolgt flere steder.')],
				en: [band('Y', 'NEWS', '2/3'), '', '#^w Record sales of waffle irons', '', ...paragraph('c', 'Shops have never sold as many waffle irons as this December.'), '', ...paragraph('c', '“People want waffles if the world ends at midnight,” a salesman in Bergen says.'), '', ...paragraph('c', 'Brown cheese is sold out in many places.')],
			},
			{
				no: [band('Y', 'NYHETER', '3/3'), '', '#^w Mødre tar telefonen', '', ...paragraph('c', 'Tusenvis av nedlastinger blir avbrutt hver kveld når noen i familien tar telefonen.'), '', ...paragraph('c', 'Telenor ber alle vente til nedlastingen er ferdig. Det kan ta hele natten.')],
				en: [band('Y', 'NEWS', '3/3'), '', '#^w Mothers pick up the phone', '', ...paragraph('c', 'Thousands of downloads are cut off every evening when someone in the family picks up the phone.'), '', ...paragraph('c', 'Telenor asks everyone to wait until the download is done. It can take all night.')],
			},
		],
	},
	102: {
		title: ['Utenriks', 'World'],
		subpages: [{
			no: [band('Y', 'UTENRIKS', '102'), '', '^y EURO:', ...paragraph('c', 'Elleve land i EU fikk en ny valuta 1. januar. Foreløpig bare på papiret.'), '', '^y NAPSTER:', ...paragraph('c', 'Platebransjen saksøker et nytt program der ungdom deler musikk gratis.'), '', '^y MICROSOFT:', ...paragraph('c', 'Windows 2000 kommer i februar. Navnet er allerede klart for år 2000.'), '', '^y Y2K:', ...paragraph('c', 'Amerikanere kjøper hermetikk, vann og generatorer.')],
			en: [band('Y', 'WORLD', '102'), '', '^y EURO:', ...paragraph('c', 'Eleven countries of the EU got a new currency on January 1. Only on paper, for now.'), '', '^y NAPSTER:', ...paragraph('c', 'The record industry sues a new program where kids share music for free.'), '', '^y MICROSOFT:', ...paragraph('c', 'Windows 2000 comes out in February. The name is ready for the year 2000.'), '', '^y Y2K:', ...paragraph('c', 'Americans buy canned food, water, and generators.')],
		}],
	},
	150: {
		title: ['Været', 'Weather'],
		subpages: [{
			no: [band('C', 'VÆRET NYTTÅRSAFTEN', '150'), '', ...map, '', ...paragraph('w', 'Kaldt og klart, med stjerner. Fint vær for fyrverkeri. Regn i Bergen (som vanlig).')],
			en: [band('C', 'WEATHER NEW YEAR’S EVE', '150'), '', ...map, '', ...paragraph('w', 'Cold and clear, with stars. Good weather for fireworks. Rain in Bergen (as always).')],
		}],
	},
	199: {
		title: ['Y2K', 'Y2K'],
		subpages: [{
			no: [band('R', 'Y2K: ER DU KLAR?', '199'), '', ...paragraph('c', 'Klokka 00.00 blir det år 2000. Noen datamaskiner tror at det blir år 1900.'), '', '^w Myndighetene anbefaler:', '^y  * ^w Fyll badekaret med vann', '^y  * ^w Ta ut litt kontanter', '^y  * ^w Skriv ut viktige e-poster', '^y  * ^w Ikke sitt i heisen ved midnatt', '', ...paragraph('g', 'Pakk Y2K-sjekklisten lenger ned på denne hjemmesiden!')],
			en: [band('R', 'Y2K: ARE YOU READY?', '199'), '', ...paragraph('c', 'At 00:00 it will be the year 2000. Some computers think it will be the year 1900.'), '', '^w The government recommends:', '^y  * ^w Fill the bathtub with water', '^y  * ^w Take out some cash', '^y  * ^w Print your important e-mails', '^y  * ^w Do not be in an elevator at midnight', '', ...paragraph('g', 'Pack the Y2K checklist further down this home page!')],
		}],
	},
	200: {
		title: ['Sport', 'Sport'],
		subpages: [{
			no: [band('G', 'SPORT', '200'), '', '^y HÅNDBALL-VM FOR KVINNER:', '#^w Norge er verdensmestere!', '', ...paragraph('c', 'Norge slo Frankrike 25-24 etter ekstraomganger i finalen i Lillehammer.'), '', '^y FOTBALL:', ...paragraph('c', 'Rosenborg er seriemester for åttende år på rad.'), '', '^y VAFFEL-NM:', ...paragraph('c', 'Sindre (10) spiste 14 vafler med brunost. Ny norsk rekord!')],
			en: [band('G', 'SPORT', '200'), '', '^y WOMEN’S HANDBALL WORLD CUP:', '#^w Norway are world champions!', '', ...paragraph('c', 'Norway beat France 25-24 after extra time in the final in Lillehammer.'), '', '^y FOOTBALL:', ...paragraph('c', 'Rosenborg win the league for the eighth year in a row.'), '', '^y WAFFLE CHAMPIONSHIP:', ...paragraph('c', 'Sindre (10) ate 14 waffles with brown cheese. A new Norwegian record!')],
		}],
	},
	300: {
		title: ['TV i kveld', 'TV tonight'],
		subpages: [{
			no: [band('C', 'TV I KVELD   NRK1', '300'), '', '^y 18.00 ^w Barne-TV', '^y 18.30 ^w Jul i Blåfjell (R)', '^y 19.00 ^w Dagsrevyen', '^y 19.45 ^w Kongens nyttårstale', '^y 20.05 ^w Grevinnen og hovmesteren', '^c       Teksting på side 777', '^y 21.00 ^w Nyttårsshow', '^y 23.45 ^w Tusenårsskiftet direkte', '^y 00.00 ^m ÅR 2000!!!', '^y 00.01 ^w Y2K? Skjermen kan bli svart', '', ...paragraph('g', 'Programmet kan bli endret hvis datamaskinene tror det er 1900.')],
			en: [band('C', 'TV TONIGHT   NRK1', '300'), '', '^y 18.00 ^w Children’s TV', '^y 18.30 ^w Christmas in Blue Mountain', '^y 19.00 ^w The Evening News', '^y 19.45 ^w The King’s New Year Speech', '^y 20.05 ^w Dinner for One', '^c       Subtitles on page 777', '^y 21.00 ^w New Year’s Show', '^y 23.45 ^w The new millennium, live', '^y 00.00 ^m YEAR 2000!!!', '^y 00.01 ^w Y2K? The screen may go black', '', ...paragraph('g', 'The schedule may change if the computers think it is 1900.')],
		}],
	},
	456: {
		title: ['Vaffeloppskrift', 'Waffle recipe'],
		subpages: [{
			no: [band('Y', 'VAFFELOPPSKRIFT', '456'), '', '^w Vafler (ca. 10 hjerter):', '', '^c  4 egg', '^c  1 dl sukker', '^c  5 dl hvetemel', '^c  5 dl melk', '^c  1 ts kardemomme', '^c  100 g smeltet smør', '', ...paragraph('w', 'Visp egg og sukker. Rør inn mel og melk. Rør inn smøret. La røren svelle i en halvtime.'), '', '#^y Server med brunost!'],
			en: [band('Y', 'WAFFLE RECIPE', '456'), '', '^w Waffles (about 10 hearts):', '', '^c  4 eggs', '^c  1 dl sugar', '^c  5 dl flour', '^c  5 dl milk', '^c  1 tsp cardamom', '^c  100 g melted butter', '', ...paragraph('w', 'Whisk the eggs and the sugar. Stir in the flour and the milk. Stir in the butter. Let the batter rest for half an hour.'), '', '#^y Serve with brown cheese!'],
		}],
	},
	555: {
		title: ['Sindres hemmelige side', 'Sindre’s secret page'],
		subpages: [{
			no: [band('M', 'HEMMELIG!!!', '555'), '', '^m            ▄▀', '^m      ▄▄▄▄▄█▀█▄', '^m    ▄███████▄▀▀', '^m    ▀█▀█▀▀█▀█', '^m     █ █  █ █', '', '#^y Du fant den hemmelige siden!', '', ...paragraph('c', 'Hei! Det er meg, Sindre. Jeg hacket Tekst-TV. Ikke si det til NRK.'), '', ...paragraph('w', 'Hilsen Sindre og Glitter')],
			en: [band('M', 'SECRET!!!', '555'), '', '^m            ▄▀', '^m      ▄▄▄▄▄█▀█▄', '^m    ▄███████▄▀▀', '^m    ▀█▀█▀▀█▀█', '^m     █ █  █ █', '', '#^y You found the secret page!', '', ...paragraph('c', 'Hi! It is me, Sindre. I hacked Tekst-TV. Do not tell NRK.'), '', ...paragraph('w', 'Greetings from Sindre and Glitter')],
		}],
	},
	777: {
		title: ['Teksting', 'Subtitles'],
		// The subtitles change faster than the news.
		interval: 3500,
		subpages: [
			subtitle('– Samme prosedyre som i fjor, Miss Sophie?', '– The same procedure as last year, Miss Sophie?'),
			subtitle('– Samme prosedyre som hvert år, James.', '– The same procedure as every year, James.'),
			subtitle('[James snubler i tigerskinnet]', '[James trips over the tiger skin]'),
			subtitle('– Skål!', '– Skål!'),
			subtitle('– Jeg skal gjøre mitt aller beste!', '– Well, I’ll do my very best!'),
		],
	},
};

const pageNumbers = Object.keys(pages).map(Number);

const renderLine = (text, line) => {
	let isDoubleHeight = false;
	if (text.startsWith('#')) {
		isDoubleHeight = true;
		text = text.slice(1);
	}

	let color = colors.w;
	let background = colors.k;
	let length = 0;
	for (const part of text.split(/(\^[a-zA-Z])/)) {
		if (/^\^[a-zA-Z]$/.test(part)) {
			const code = part[1];
			if (code === code.toUpperCase()) {
				background = colors[code.toLowerCase()];
			} else {
				color = colors[code];
			}

			continue;
		}

		if (!part) {
			continue;
		}

		// The spaces are no-break spaces, as the screen keeps line breaks but collapses spaces, and teletext graphics are made of them.
		const visible = part.slice(0, width - length);
		const span = document.createElement('span');
		span.textContent = visible.replaceAll(' ', '\u00A0');
		span.style.color = color;
		span.style.backgroundColor = background;
		length += visible.length;
		line.append(span);
	}

	// The last background goes to the end of the line, like a band of teletext.
	if (length < width) {
		const rest = document.createElement('span');
		rest.textContent = '\u00A0'.repeat(width - length);
		rest.style.backgroundColor = background;
		line.append(rest);
	}

	if (isDoubleHeight) {
		line.style.transform = 'scaleY(2)';
		line.style.transformOrigin = 'top';
		line.style.marginBottom = '1lh';
	}
};

export default class extends GeoCitiesElement {
	#current = 100;
	#shown = 100;
	#subpage = 0;
	#typed = '';
	#isEnglish = false;
	#hasFoundSecret = false;
	#searchTimer;
	#subpageTimer;
	#clockTimer;

	connected() {
		const {translate: translateButton} = this.parts;

		this.on(this, 'click', event => {
			const digit = event.target.closest('[data-tekst-tv-digit]')?.dataset.tekstTvDigit;
			if (digit) {
				this.#typeDigit(digit);
				return;
			}

			const step = event.target.closest('[data-tekst-tv-step]')?.dataset.tekstTvStep;
			if (step) {
				this.#searchTimer?.cancel();
				this.#typed = '';
				// The page buttons go through the subpages of a page first, like the news.
				const nextSubpage = this.#subpage + Number(step);
				if (nextSubpage >= 0 && nextSubpage < pages[this.#current].subpages.length) {
					this.#subpage = nextSubpage;
					this.#render();
					this.#renderHeader();
					this.#startSubpages();
					this.say(`Page ${this.#current}, subpage ${this.#subpage + 1} of ${pages[this.#current].subpages.length}`);
					return;
				}

				const index = pageNumbers.indexOf(this.#current);
				this.#show(pageNumbers.at((index + Number(step)) % pageNumbers.length));
				return;
			}

			const jump = event.target.closest('[data-tekst-tv-jump]')?.dataset.tekstTvJump;
			if (jump) {
				this.#searchTimer?.cancel();
				this.#typed = '';
				this.#search(Number(jump));
			}
		});

		// The number keys of the keyboard work like the remote, while the focus is on the TV part.
		this.on(this, 'keydown', event => {
			if (
				event.altKey
				|| event.ctrlKey
				|| event.metaKey
				|| !/^\d$/.test(event.key)
				|| event.target.closest('input, textarea, select')
			) {
				return;
			}

			// The page number is not also a key of the games of the page, like the holes of Zap the Aliens.
			event.preventDefault();
			event.stopPropagation();
			this.#typeDigit(event.key);
		});

		this.on(translateButton, 'click', () => {
			this.#isEnglish = !this.#isEnglish;
			translateButton.setAttribute('aria-pressed', String(this.#isEnglish));
			if (this.#isEnglish) {
				translateButton.dataset.state = 'on';
			} else {
				delete translateButton.dataset.state;
			}

			this.#render();
			this.#renderHeader();
		});

		this.#render();
		this.#renderHeader();
	}

	// The clock in the header ticks, and the subpages turn, only while the TV is on screen.
	visibilityChanged(isVisible) {
		this.#clockTimer?.cancel();
		if (isVisible) {
			this.#renderHeader();
			this.#clockTimer = this.interval(1000, () => {
				this.#renderHeader();
			});
			this.#startSubpages();
		} else {
			this.#stopSubpages();
		}
	}

	reducedMotionChanged() {
		this.#startSubpages();
	}

	#render() {
		const page = pages[this.#current];
		const lines = page.subpages[this.#subpage][this.#isEnglish ? 'en' : 'no'];
		this.parts.page.replaceChildren(...lines.map(text => {
			const line = document.createElement('div');
			renderLine(text, line);
			return line;
		}));
	}

	#renderHeader() {
		const {header} = this.parts;
		const now = new Date();
		const time = now.toLocaleTimeString('nb-NO', {hour: '2-digit', minute: '2-digit', second: '2-digit'}).replaceAll('.', ':');
		const date = this.#isEnglish ? 'Fri 31 Dec' : 'Fre 31 des';
		const requested = this.#typed ? this.#typed.padEnd(3, '-') : String(this.#current);
		header.replaceChildren();
		renderLine(`^w P${requested} ^y NRK ^w${this.#shown} ^c${date} ^y${time}`, header);
	}

	#stopSubpages() {
		this.#subpageTimer?.cancel();
		this.#subpageTimer = undefined;
	}

	#startSubpages() {
		this.#stopSubpages();
		const page = pages[this.#current];
		// The subpages only turn by themselves for visitors who do not prefer reduced motion. The others turn them with the page buttons.
		if (!this.isVisible || page.subpages.length < 2 || this.reducedMotion) {
			return;
		}

		this.#subpageTimer = this.interval(page.interval ?? 8000, () => {
			this.#subpage = (this.#subpage + 1) % page.subpages.length;
			this.#render();
		});
	}

	#show(number) {
		this.#current = number;
		this.#shown = number;
		this.#subpage = 0;
		this.#typed = '';
		this.#render();
		this.#renderHeader();
		this.#startSubpages();
		const page = pages[number];
		this.say(`Page ${number}: ${page.title[this.#isEnglish ? 1 : 0]}${this.#isEnglish ? '' : ` (${page.title[1]})`}`);

		if (number === 555 && !this.#hasFoundSecret) {
			this.#hasFoundSecret = true;
			this.cheer();
			this.toast('You found the secret Tekst-TV page! Do not tell NRK.');
		}
	}

	// A real decoder waits for the page while the pages go by on the air, one after the other, so the number in the header counts up until the right one comes. A page that does not exist never comes, so it gives up after a while.
	#search(target) {
		this.#searchTimer?.cancel();
		const exists = pageNumbers.includes(target);
		let steps = exists ? randomInteger(6, 14) : 40;
		// The count starts some pages before the target, so it arrives at the target with the last step.
		this.#shown = exists ? ((target - steps - 100 + 800) % 800) + 100 : this.#current;
		this.#searchTimer = this.interval(70, () => {
			steps--;
			this.#shown = this.#shown >= 899 ? 100 : this.#shown + 1;
			if (steps <= 0) {
				this.#searchTimer.cancel();
				if (exists) {
					this.#show(target);
				} else {
					this.#typed = '';
					this.#shown = this.#current;
					this.#renderHeader();
					this.say(`Page ${target} is not on the air. A real TV would keep looking forever, so I stopped it.`);
				}

				return;
			}

			this.#renderHeader();
		});
	}

	#typeDigit(digit) {
		// The decoder is busy with the last page number until it finds the page.
		if (this.#typed.length >= 3) {
			return;
		}

		// Pages are from 100 to 899, so the first digit is from 1 to 8.
		if (!this.#typed && (digit === '0' || digit === '9')) {
			this.say('Teletext pages are from 100 to 899.');
			return;
		}

		this.#typed += digit;
		this.#renderHeader();
		if (this.#typed.length === 3) {
			this.#search(Number(this.#typed));
		}
	}
}
