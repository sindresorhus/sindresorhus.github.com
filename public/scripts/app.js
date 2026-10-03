const prefersReducedMotion = matchMedia('(prefers-reduced-motion: reduce)');

// The share button shares the App Store page, or the app page for apps that are not on the App Store. Some browsers, like Firefox on desktop, cannot share.
{
	const shareButton = document.querySelector('#share-button');
	const shareData = {
		title: shareButton?.dataset.shareTitle,
		url: shareButton?.dataset.shareUrl,
	};

	if (shareButton && navigator.canShare?.(shareData)) {
		shareButton.hidden = false;

		shareButton.addEventListener('click', async () => {
			try {
				await navigator.share(shareData);
			} catch (error) {
				if (error.name !== 'AbortError') {
					console.error('Share failed:', error.message);
				}
			}
		});
	}
}

// A 3D tilt of the app icon that follows the pointer. It eases toward the pointer every frame, and only starts after a short dwell, so moving across the icon does not trigger it. A grace area around the icon keeps it going near the edges.
{
	const icon = document.querySelector('#app-icon');

	if (icon && !prefersReducedMotion.matches) {
		const maxTilt = 36;
		const easing = 0.1;
		const dwellTime = 300;
		const gracePadding = 40;
		const clamp = (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum);
		const rest = {x: 0, y: 0, scale: 1, shadowX: 0, shadowY: 0, shadowBlur: 0, shadowOpacity: 0};
		const state = {...rest};
		const target = {...rest};
		// Read when the tilt first starts, after scripts that group the icon have run, and before the tilt sets its own filter.
		let baseFilter;
		let isActive = false;
		let isHovering = false;
		let isAnimating = false;
		let dwellTimer;
		let cursorX = 0;
		let cursorY = 0;

		// A script can group the icon with things drawn on it, like the pupils of Googly Eyes, so they tilt together.
		const tilted = () => icon.closest('[data-app-icon-group]') ?? icon;

		// The position is measured when the pointer enters and when the layout changes, not on every pointer move.
		let rect = icon.getBoundingClientRect();
		const measure = () => {
			rect = icon.getBoundingClientRect();
		};

		const animate = () => {
			Object.assign(target, isActive
				? {x: cursorX, y: cursorY, scale: 1.1, shadowX: -cursorX * 20, shadowY: -cursorY * 20, shadowBlur: 30, shadowOpacity: 0.25}
				: rest);

			for (const key of Object.keys(state)) {
				state[key] += (target[key] - state[key]) * easing;
			}

			tilted().style.transform = `rotateY(${state.x * maxTilt}deg) rotateX(${-state.y * maxTilt}deg) scale3d(${state.scale}, ${state.scale}, ${state.scale})`;

			// The shadow moves opposite to the tilt, as if the light comes from above.
			const tiltShadow = `drop-shadow(${state.shadowX}px ${state.shadowY + 10}px ${state.shadowBlur}px rgb(0 0 0 / ${state.shadowOpacity}))`;
			tilted().style.filter = baseFilter === 'none' ? tiltShadow : `${baseFilter} ${tiltShadow}`;

			if (Object.keys(state).every(key => Math.abs(state[key] - target[key]) < 0.005)) {
				isAnimating = false;

				if (!isActive) {
					tilted().style.transform = '';
					tilted().style.filter = '';
					Object.assign(state, rest);
				}
			} else {
				requestAnimationFrame(animate);
			}
		};

		const startAnimating = () => {
			baseFilter ??= getComputedStyle(tilted()).filter;

			if (!isAnimating) {
				isAnimating = true;
				requestAnimationFrame(animate);
			}
		};

		icon.addEventListener('mouseenter', () => {
			measure();
			isHovering = true;
			dwellTimer = setTimeout(() => {
				if (isHovering) {
					isActive = true;
					startAnimating();
				}
			}, dwellTime);
		});

		icon.addEventListener('mouseleave', () => {
			isHovering = false;
			clearTimeout(dwellTimer);
		});

		// The tilt ends when the pointer leaves the window, even from the grace area.
		document.addEventListener('mouseleave', () => {
			isHovering = false;
			isActive = false;
			clearTimeout(dwellTimer);
			startAnimating();
		});

		window.addEventListener('resize', measure, {passive: true});
		window.addEventListener('scroll', measure, {passive: true});

		// The document gets the pointer moves, so the tilt continues in the grace area outside the icon.
		document.addEventListener('mousemove', event => {
			if (!isActive) {
				return;
			}

			cursorX = clamp((event.clientX - rect.left) / rect.width - 0.5, -0.5, 0.5);
			cursorY = clamp((event.clientY - rect.top) / rect.height - 0.5, -0.5, 0.5);

			const isInGraceArea = event.clientX >= rect.left - gracePadding
				&& event.clientX <= rect.right + gracePadding
				&& event.clientY >= rect.top - gracePadding
				&& event.clientY <= rect.bottom + gracePadding;

			if (!isInGraceArea) {
				isHovering = false;
				isActive = false;
				clearTimeout(dwellTimer);
			}

			startAnimating();
		}, {passive: true});
	}
}

// Scroll spy: marks the link of the section that was last scrolled past the header, so the app navigation underlines it.
// TODO: Replace this with CSS scroll spy (`scroll-target-group` and `:target-current`) when Safari and Firefox support it.
{
	const links = document.querySelectorAll('#app-navigation a[href^="#"]');
	const headings = [...document.querySelectorAll('article h2[id]')];

	if (links.length > 0 && headings.length > 0) {
		const passedHeadings = new Set();
		let isAtEnd = false;

		const update = () => {
			// At the end of the page, the last section may be too short to scroll past the header.
			const activeHeading = isAtEnd ? headings.at(-1) : headings.findLast(heading => passedHeadings.has(heading));

			for (const link of links) {
				if (activeHeading && link.getAttribute('href') === `#${activeHeading.id}`) {
					link.setAttribute('aria-current', 'location');
				} else {
					link.removeAttribute('aria-current');
				}
			}
		};

		// The top 100px are behind the header. A heading above that line has been scrolled past.
		const headingObserver = new IntersectionObserver(entries => {
			for (const entry of entries) {
				if (entry.boundingClientRect.top < 100) {
					passedHeadings.add(entry.target);
				} else {
					passedHeadings.delete(entry.target);
				}
			}

			update();
		}, {rootMargin: '-100px 0px 0px 0px'});

		for (const heading of headings) {
			headingObserver.observe(heading);
		}

		const footer = document.querySelector('body > footer');

		if (footer) {
			new IntersectionObserver(([entry]) => {
				isAtEnd = entry.isIntersecting;
				update();
			}).observe(footer);
		}
	}
}

// Demo videos play while they are visible, unless the visitor prefers reduced motion. A click, or Enter or Space, pauses and plays a video, so it can always be stopped (WCAG 2.2.2).
{
	const videos = document.querySelectorAll('#app-media video');

	const toggle = video => {
		if (video.paused) {
			delete video.dataset.pausedByVisitor;
			video.play().catch(() => {});
		} else {
			video.dataset.pausedByVisitor = '';
			video.pause();
		}
	};

	const observer = new IntersectionObserver(entries => {
		for (const {target: video, isIntersecting} of entries) {
			if (isIntersecting && !prefersReducedMotion.matches && !('pausedByVisitor' in video.dataset)) {
				video.play().catch(() => {});
			} else if (!isIntersecting) {
				video.pause();
			}
		}
	}, {threshold: 0.5});

	for (const video of videos) {
		observer.observe(video);
		video.addEventListener('click', () => toggle(video));
		video.addEventListener('keydown', event => {
			if (event.key === 'Enter' || event.key === ' ') {
				event.preventDefault();
				toggle(video);
			}
		});
	}
}

// The buttons of the media carousel. A button is disabled at the end it points to, and the styles hide it.
// TODO: Replace this with CSS carousels (`::scroll-button` and `::scroll-marker`) when Safari and Firefox support them.
{
	const carousel = document.querySelector('#app-media');
	const previousButton = document.querySelector('#media-previous');
	const nextButton = document.querySelector('#media-next');
	const items = carousel ? [...carousel.children] : [];

	if (items.length > 0 && previousButton && nextButton) {
		// Shows the first item, instead of the scroll position that the browser restores.
		carousel.scrollLeft = 0;

		let currentIndex = 0;

		const visibleIndex = () => {
			const center = carousel.getBoundingClientRect().left + (carousel.offsetWidth / 2);
			let closestIndex = 0;
			let closestDistance = Number.POSITIVE_INFINITY;

			for (const [index, item] of items.entries()) {
				const {left, width} = item.getBoundingClientRect();
				const distance = Math.abs(left + (width / 2) - center);

				if (distance < closestDistance) {
					closestDistance = distance;
					closestIndex = index;
				}
			}

			return closestIndex;
		};

		const updateButtons = () => {
			previousButton.disabled = currentIndex === 0;
			nextButton.disabled = currentIndex === items.length - 1;
		};

		const scrollTo = index => {
			currentIndex = Math.max(0, Math.min(items.length - 1, index));
			items[currentIndex].scrollIntoView({behavior: prefersReducedMotion.matches ? 'instant' : 'smooth', block: 'nearest', inline: 'center'});
			updateButtons();
		};

		previousButton.addEventListener('click', () => {
			scrollTo(currentIndex - 1);
		});

		nextButton.addEventListener('click', () => {
			scrollTo(currentIndex + 1);
		});

		// Keeps the buttons right after the visitor swipes.
		carousel.addEventListener('scrollend', () => {
			currentIndex = visibleIndex();
			updateButtons();
		}, {passive: true});

		updateButtons();
	}
}
