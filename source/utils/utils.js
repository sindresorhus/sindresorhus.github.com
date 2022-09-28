export const getFormattedDate = date =>
	date
		? new Date(date).toLocaleDateString('en-us', {
			year: 'numeric',
			month: 'long',
			day: 'numeric',
		})
		: '';
