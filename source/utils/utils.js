// Fisher-Yates shuffle.
export const shufflingArray = array => {
	const result = [...array];

	for (let index = result.length - 1; index > 0; index--) {
		const randomIndex = Math.floor(Math.random() * (index + 1));
		[result[index], result[randomIndex]] = [result[randomIndex], result[index]];
	}

	return result;
};

export const getFormattedDate = date =>
	date
		? new Date(date).toLocaleDateString('en-us', {
			year: 'numeric',
			month: 'long',
			day: 'numeric',
		})
		: '';
