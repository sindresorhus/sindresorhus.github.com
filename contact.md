---
layout: simple
title: Contact
---

<style>
.hero-body .column {
	margin-bottom: 180px;
}

#email {
	text-align: center;
	font-size: 25px;
}
</style>

<script type="module">
// Forwards `subject` and `body` search params to the email link

const originalSearchParams = new URLSearchParams(location.search);
const element = document.querySelector('#email a');

const searchParams = new URLSearchParams();
if (originalSearchParams.has('subject')) {
	searchParams.set('subject', originalSearchParams.get('subject'));
}
if (originalSearchParams.has('body')) {
	searchParams.set('body', originalSearchParams.get('body'));
}

element.search = searchParams.toString();
</script>

# Contact

I value my time, so make it worth it, and [keep it succinct.](https://www.google.com/search?q=succinct+emails)

---

<p id="email">
	<a href="mailto:sindresorhus@gmail.com">sindresorhus@gmail.com</a>
</p>

---

Please no support questions, job offers, questionnaires, etc.
