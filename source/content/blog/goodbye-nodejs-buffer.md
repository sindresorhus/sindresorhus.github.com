---
title: Goodbye, Node.js Buffer
description: It's time to move from Buffer to Uint8Array.
pubDate: 2023-10-24
tags:
  - nodejs
  - javascript
  - open-source
---

The [`Buffer`](https://nodejs.org/api/buffer.html) type has been the cornerstone for binary data handling in Node.js since the beginning. However, these days we have [`Uint8Array`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Uint8Array), which is a native JavaScript type and works cross-platform. While `Buffer` is an instance of `Uint8Array`, it introduces numerous methods that are not available in other JavaScript environments. Consequently, code leveraging Buffer-specific methods needs polyfilling, preventing many valuable packages from being browser-compatible.

`Buffer` also comes with additional caveats. While [`Uint8Array#slice()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypedArray/slice) creates an immutable copy, [`Buffer#slice()`](https://nodejs.org/api/buffer.html#bufslicestart-end) creates a mutable segment linked to the original Buffer, resulting in possible unpredictable behavior. The problem is not the behavior of the `Buffer#slice()` method, but the fact that `Buffer` is a subclass of `Uint8Array` and completely changes the behavior of an inherited method. Instead of `Buffer#slice()`, use `Uint8Array#subarray()` or `Buffer#subarray()`. Furthermore, [buffers expose private information](https://github.com/nodejs/node/issues/41588#issuecomment-1016269584) through global variables, a potential security risk.

It is time to move on.

## The Plan

I intend to move [all my packages](https://github.com/search?q=owner%3Asindresorhus+%22node%3Abuffer%22&type=code) from using `Buffer` to `Uint8Array`. If you are a maintainer of a JavaScript package, I encourage you to do the same.

`Buffer` will never be removed, and probably never even deprecated, but at least the community can slowly move away from it. My hope is that the Node.js team will at least start discouraging the use of `Buffer`.

## How

First, familiarize yourself with the [subtle incompatibilities](https://nodejs.org/api/buffer.html#buffers-and-typedarrays) between `Uint8Array` and `Buffer`.

I have made the [`uint8array-extras` package](https://github.com/sindresorhus/uint8array-extras) to make the transition easier. Pull requests are welcome for additional utilities.

If your code accepts a `Buffer` and doesn't use any `Buffer`-specific methods, you can simply update your docs and types to `Uint8Array`. Changing the input type from `Buffer` to `Uint8Array` is a non-breaking change since `Buffer` is an instance of `Uint8Array`.

Changing the return type from `Buffer` to `Uint8Array` is a breaking change, because consumers may use `Buffer`-specific methods.

If you absolutely need to convert a `Uint8Array` to a `Buffer`, you can use `Buffer.from(uint8Array)` (copies the data) or `Buffer.from(uint8Array.buffer, uint8Array.byteOffset, uint8Array.byteLength)` (does not copy). However, there is usually a better way.

The primary transition steps are:

- Remove all `import {Buffer} from 'node:buffer'` imports.
- Remove all occurrences of the `Buffer` global.
- Stop using `Buffer`-specific methods.
- Replace `Buffer` reading/writing methods, like [`Buffer#readInt32BE()`](https://nodejs.org/api/buffer.html#bufreadint32beoffset), with [`DataView`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DataView).

### Questions

#### Why did `Buffer` exist in the first place?

`Buffer` was created long before `Uint8Array` existed.

#### How can I convert to and from Base64 with `Uint8Array`?

You can use my [`uint8array-extras` package](https://github.com/sindresorhus/uint8array-extras) for now. It will most likely eventually be [supported natively](https://github.com/tc39/proposal-arraybuffer-base64/issues) in JavaScript.

#### How do I handle Node.js APIs that return a `Buffer`, like the `fs` methods?

Since `Buffer` is a subclass of `Uint8Array`, you can just treat it like a `Uint8Array`. Just make sure you don't use `.slice()` (which differs in behavior) or any Buffer-specific methods.

### Examples

#### JavaScript

```diff
+import {stringToBase64} from 'uint8array-extras';

-Buffer.from(string).toString('base64');
+stringToBase64(string);
```

```diff
+import {uint8ArrayToHex} from 'uint8array-extras';

-buffer.toString('hex');
+uint8ArrayToHex(uint8Array);
```

```diff
 const bytes = getBytes();

+const view = new DataView(bytes.buffer);

-const value = bytes.readInt32BE(1);
+const value = view.getInt32(1);
```

```diff
 import crypto from 'node:crypto';
-import {Buffer} from 'node:buffer';
+import {isUint8Array} from 'uint8array-extras';

 export default function hash(data) {
-	if (!(typeof data === 'string' || Buffer.isBuffer(data))) {
+	if (!(typeof data === 'string' || isUint8Array(data))) {
 		throw new TypeError('Incorrect type.');
 	}

 	return crypto.createHash('md5').update(data).digest('hex');
 }
```

Most Node.js APIs accept `Uint8Array` too, so no extra work was required. Ideally, this code should also transition to [Web Crypto](https://nodejs.org/api/webcrypto.html), but that's not relevant to this example.

##### TypeScript

```diff
-import {Buffer} from 'node:buffer';

-export function getSize(input: string | Buffer): number { … }
+export function getSize(input: string | Uint8Array): number { … }
```

## Enforcement

I recommend enforcing `Uint8Array` over `Buffer` with linting.

Add this to your ESLint config:

```js
{
	'no-restricted-globals': [
		'error',
		{
			name: 'Buffer',
			message: 'Use Uint8Array instead.'
		}
	],
	'no-restricted-imports': [
		'error',
		{
			name: 'buffer',
			message: 'Use Uint8Array instead.'
		},
		{
			name: 'node:buffer',
			message: 'Use Uint8Array instead.'
		}
	]
}
```

And if you use TypeScript, add this:

```js
{
	'@typescript-eslint/ban-types': [
		'error',
		{
			types: {
				Buffer: {
					message: 'Use Uint8Array instead.',
					suggest: [
						'Uint8Array'
					]
				}
			}
		}
	]
}
```

If you use [XO](https://github.com/xojs/xo), it will soon come with this config by default.

## How Can I Help?

[Voice your support](https://github.com/nodejs/node/issues/41588) for Node.js using `Uint8Array` for new APIs.

Help me move [my packages](https://github.com/search?q=owner%3Asindresorhus+%22node%3Abuffer%22&type=code) to `Uint8Array`. Pick one and give it a go.

Help us make a [lint rule](https://github.com/sindresorhus/eslint-plugin-unicorn/issues/1808) to prevent the use of `Buffer` methods.

## Future

`Uint8Array` (or rather `TypedArray`) need more utility methods!

For example, there is currently no good built-in way to convert a `Uint8Array` to Base64 or Hex. Although, it looks like this is [most likely coming](https://github.com/tc39/proposal-arraybuffer-base64).

Consider proposing missing bits to [TC39](https://github.com/tc39/proposals).

## The End

Let's make the JavaScript package ecosystem more cross-platform. Thanks for reading.

[Discuss](https://github.com/sindresorhus/meta/discussions/22)
