---
layout: ~/layouts/MarkdownLayout.astro
title: Contact
---

<script type="module">
// Forwards `subject` and `body` search params to the email link.

const originalSearchParams = new URLSearchParams(location.search);
const element = document.querySelector('#contact-email');

const url = new URL(element.href);
if (originalSearchParams.has('subject')) {
	url.searchParams.set('subject', originalSearchParams.get('subject'));
}
if (originalSearchParams.has('body')) {
	url.searchParams.set('body', originalSearchParams.get('body'));
}

element.href = url.toString();

// Clear URL parameters.
const url = new URL(window.location);
url.searchParams.delete('subject');
url.searchParams.delete('body');
window.history.replaceState({}, '', url);
</script>

# Contact

<div class="sm:-mt-2 not-prose text-3xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-primary-500 to-secondary-500 sm:whitespace-nowrap hover:underline hover:underline-offset-8 hover:decoration-4 decoration-black dark:decoration-white">
	<a id="contact-email" href="mailto:sindresorhus@gmail.com">sindresorhus@gmail.com</a>
</div>

I value my time, so make it worth it, and [keep it succinct](https://www.google.com/search?q=succinct+emails).

For app-related queries, use the in-app feedback button or the support link on the app's page.
