import path from 'node:path';
import {fileURLToPath} from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export const getProjectRootDir = () => {
	const mode = import.meta.env.MODE;
	return mode === 'production' ? path.join(__dirname, '../') : path.join(__dirname, '../../');
};

const __srcFolder = path.join(getProjectRootDir(), '/src');

export const getRelativeUrlByFilePath = filePath => {
	if (filePath) {
		return filePath.replace(__srcFolder, '');
	}

	return null;
};
