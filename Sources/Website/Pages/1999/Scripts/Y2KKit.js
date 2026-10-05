// The Y2K survival kit on the 1999 page: the points of what the visitor has, as a grade on a report card, with a comment for the worst choices.
const grades = [
	{points: 80, grade: 'A+', comment: 'Excellent! You will survive the year 2000. Glitter is proud of you.'},
	{points: 65, grade: 'A', comment: 'Very good! Maybe one more can of beans.'},
	{points: 50, grade: 'B', comment: 'Good. You will survive, but you will be hungry.'},
	{points: 35, grade: 'C', comment: 'OK. At least pack a flashlight.'},
	{points: 20, grade: 'D', comment: 'Hmm. Your VCR will be fine. You, I am not so sure.'},
	{points: Number.NEGATIVE_INFINITY, grade: 'F', comment: 'The Y2K bug will get you first. See me after class.'},
];

// The comments for the worst choices, by their points.
const notes = {
	'-10': 'PS: Your VCR has blinked 12:00 since 1987 anyway.',
	'-15': 'PS: You sold your computer?! How will you read my page in the year 2000?',
	'-25': 'PS: NEVER be in an elevator at midnight!!!',
};

const sum = numbers => {
	let total = 0;
	for (const number of numbers) {
		total += number;
	}

	return total;
};

export default class extends GeoCitiesElement {
	connected() {
		const {form, card, grade, comment} = this.parts;

		this.on(form, 'submit', event => {
			event.preventDefault();
			const checked = [...form.querySelectorAll('[data-y2k-points]:checked')];
			const points = sum(checked.map(input => Number(input.dataset.y2kPoints)));
			const result = grades.find(grade => points >= grade.points);
			const warnings = checked
				.filter(input => Number(input.dataset.y2kPoints) < 0)
				.map(input => notes[input.dataset.y2kPoints]);
			card.hidden = false;
			grade.textContent = '';
			this.say([`${points} points.`, result.comment, ...warnings].join(' '), comment);

			// The grade comes with the comment, which `say()` writes in the next frame, so the report card is read out as one.
			requestAnimationFrame(() => {
				grade.textContent = result.grade;
				if (result.grade === 'A+') {
					this.cheer();
					this.celebrate();
				}
			});
		});
	}
}
