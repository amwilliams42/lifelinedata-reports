import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Merges and concatenates CSS class names.
 * @param {...any[]} inputs - The class values to merge.
 * @returns {string} The merged class names.
 */
export function cn(...inputs) {
	return twMerge(clsx(inputs));
}

/**
 * Converts a value to boolean
 * @param {any} value - The value to convert
 * @returns {boolean|undefined} The boolean value
 */
export const toBoolean = (value) => {
	if (typeof value === 'undefined') return undefined;
	if (typeof value === 'string') {
		if (value.toLowerCase() === 'true') return true;
		if (value.toLowerCase() === 'false') return false;
	}
	return Boolean(value);
};
