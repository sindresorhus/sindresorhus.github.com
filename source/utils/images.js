const load = async function () {
	let images = [];
	try {
		images = import.meta.glob('~/assets/images/**');
	} catch {}

	return images;
};

let cachedImages;

export const fetchLocalImages = async () => {
	cachedImages = cachedImages ?? load();
	return cachedImages;
};

export const findImage = async imagePath => {
	if (typeof imagePath !== 'string') {
		return null;
	}

	if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
		return imagePath;
	}

	if (!imagePath.startsWith('~/assets')) {
		return null;
	} // For now only consume images using ~/assets alias (or absolute)

	const images = await fetchLocalImages();
	const key = imagePath.replace('~/', '/source/');

	// eslint-disable-next-line unicorn/no-await-expression-member
	return typeof images[key] === 'function' ? (await images[key]()).default : null;
};
