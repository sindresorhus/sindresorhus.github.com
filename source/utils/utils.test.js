import assert from 'node:assert/strict';
import {test} from 'node:test';
import {cleanPathname, fetchAppStoreInfo, fetchFilteredReleases} from './utils.js';

test('cleanPathname removes the leading slash and the extension', () => {
	assert.equal(cleanPathname('/apps/dato.html'), 'apps/dato');
});

test('cleanPathname turns index pages into their folder', () => {
	assert.equal(cleanPathname('/'), '');
	assert.equal(cleanPathname('/index.html'), '');
	assert.equal(cleanPathname('/apps/index.html'), 'apps');
});

test('cleanPathname keeps names that only end with index', () => {
	assert.equal(cleanPathname('/reindex.html'), 'reindex');
	assert.equal(cleanPathname('/apps/my-index.html'), 'apps/my-index');
});

test('fetchFilteredReleases removes drafts and prereleases', async t => {
	const fetchMock = t.mock.method(globalThis, 'fetch', async () => Response.json([
		{name: 'Beta', draft: false, prerelease: true},
		{name: 'Draft', draft: true, prerelease: false},
		{name: 'Release', draft: false, prerelease: false},
	]));

	const releases = await fetchFilteredReleases('filtering-app');

	t.assert.deepStrictEqual(releases.map(release => release.name), ['Release']);
	t.assert.strictEqual(fetchMock.mock.calls[0].arguments[0], 'https://api.github.com/repos/sindresorhus/filtering-app/releases?per_page=100');
});

test('fetchFilteredReleases fetches the releases of a repo only once', async t => {
	const fetchMock = t.mock.method(globalThis, 'fetch', async () => Response.json([]));

	await Promise.all([
		fetchFilteredReleases('caching-app'),
		fetchFilteredReleases('caching-app'),
	]);
	await fetchFilteredReleases('caching-app');

	t.assert.strictEqual(fetchMock.mock.callCount(), 1);
});

test('fetchAppStoreInfo returns no metadata when the App Store responds with an error', async t => {
	t.mock.method(globalThis, 'fetch', async () => new Response(undefined, {status: 429}));

	t.assert.deepStrictEqual(await fetchAppStoreInfo([123]), new Map());
});

test('fetchAppStoreInfo returns no metadata when the request fails', async t => {
	t.mock.method(globalThis, 'fetch', async () => {
		throw new TypeError('Network error');
	});

	t.assert.deepStrictEqual(await fetchAppStoreInfo([123]), new Map());
});
