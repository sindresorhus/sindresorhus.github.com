const appPageData = JSON.parse(document.querySelector('#app-page-data')?.textContent ?? '{}');
const appTitle = appPageData.title;
const appStoreUrl = appPageData.appStoreURL;

const shareData = {
		title: appTitle,
		url: appStoreUrl
	};

	// The share button only exists for App Store apps, and some browsers, like Firefox on desktop, do not support sharing.
	const shareButton = document.querySelector('#share-button');
	if (shareButton && navigator.canShare?.(shareData)) {
		shareButton.style.display = 'block';

		shareButton.addEventListener('click', async () => {
			try {
				await navigator.share(shareData);
			} catch (error) {
				console.error('Share failed:', error.message);
			}
		});
	}

if (document.referrer.endsWith('/apps/random')) {
		document.querySelector('#another-random-app').style.display = 'flex';
	}

{
	// 3D tilt effect on the app icon.
	// Uses lerp for buttery smooth interpolation. Requires a short dwell time
	// before activating so quick mouse fly-overs are ignored.
	// A grace area around the icon keeps the effect alive when slightly outside bounds.
	const icon = document.querySelector('#app-icon');

	if (icon && !matchMedia('(prefers-reduced-motion: reduce)').matches) {
		const maxTilt = 36;
		const lerpFactor = 0.1;
		const dwellTime = 300;
		const gracePadding = 40;
		const clamp = (value, min, max) => Math.min(Math.max(value, min), max);
		const lerp = (current, target, factor) => current + (target - current) * factor;

		// Animated properties: [current, target]
		const state = { x: 0, y: 0, scale: 1, shadowX: 0, shadowY: 0, shadowBlur: 0, shadowOpacity: 0 };
		const target = { ...state };
		let activated = false;
		let hovering = false;
		let animating = false;
		let dwellTimer;

		icon.style.willChange = 'transform, filter';
		icon.parentElement.style.perspective = '800px';

		// Capture the existing Tailwind drop-shadow so we can preserve it.
		const baseFilter = getComputedStyle(icon).filter;
		const hasBaseFilter = baseFilter && baseFilter !== 'none';

		const animate = () => {
			// Compute targets fresh each frame.
			if (activated) {
				target.x = cursorX;
				target.y = cursorY;
				target.scale = 1.1;
				target.shadowX = -cursorX * 20;
				target.shadowY = -cursorY * 20;
				target.shadowBlur = 30;
				target.shadowOpacity = 0.25;
			} else {
				Object.assign(target, { x: 0, y: 0, scale: 1, shadowX: 0, shadowY: 0, shadowBlur: 0, shadowOpacity: 0 });
			}

			for (const key of Object.keys(state)) {
				state[key] = lerp(state[key], target[key], lerpFactor);
			}

			icon.style.transform = `rotateY(${state.x * maxTilt}deg) rotateX(${-state.y * maxTilt}deg) scale3d(${state.scale}, ${state.scale}, ${state.scale})`;

			// Shadow shifts opposite to tilt, as if light comes from above.
			const tiltShadow = `drop-shadow(${state.shadowX}px ${state.shadowY + 10}px ${state.shadowBlur}px rgba(0,0,0,${state.shadowOpacity}))`;
			icon.style.filter = hasBaseFilter ? `${baseFilter} ${tiltShadow}` : tiltShadow;

			const settled = Object.keys(state).every(key => Math.abs(state[key] - target[key]) < 0.005);

			if (settled) {
				animating = false;
				if (!activated) {
					icon.style.transform = '';
					icon.style.filter = '';
					Object.assign(state, { x: 0, y: 0, scale: 1, shadowX: 0, shadowY: 0, shadowBlur: 0, shadowOpacity: 0 });
				}
			} else {
				requestAnimationFrame(animate);
			}
		};

		const startAnimating = () => {
			if (!animating) {
				animating = true;
				requestAnimationFrame(animate);
			}
		};

		// Cursor position relative to icon center, updated on every mousemove.
		let cursorX = 0;
		let cursorY = 0;

		icon.addEventListener('mouseenter', () => {
			hovering = true;
			dwellTimer = setTimeout(() => {
				if (hovering) {
					activated = true;
					startAnimating();
				}
			}, dwellTime);
		});

		// Listen on document to track cursor in the grace area outside the icon.
		document.addEventListener('mousemove', (event) => {
			const rect = icon.getBoundingClientRect();
			cursorX = clamp((event.clientX - rect.left) / rect.width - 0.5, -0.5, 0.5);
			cursorY = clamp((event.clientY - rect.top) / rect.height - 0.5, -0.5, 0.5);

			if (activated) {
				// Deactivate if cursor leaves the grace area.
				const inGrace = event.clientX >= rect.left - gracePadding
					&& event.clientX <= rect.right + gracePadding
					&& event.clientY >= rect.top - gracePadding
					&& event.clientY <= rect.bottom + gracePadding;

				if (!inGrace) {
					hovering = false;
					activated = false;
					clearTimeout(dwellTimer);
				}

				startAnimating();
			}
		}, {passive: true});

		icon.addEventListener('mouseleave', () => {
			hovering = false;
			clearTimeout(dwellTimer);
		});
	}
}

{
	const siteHeader = document.querySelector('#site-header');
	const siteNav = document.querySelector('#site-nav-content');
	const appNav = document.querySelector('#app-nav-content');
	const hero = document.querySelector('#app-hero');

	if (siteHeader && siteNav && appNav && hero) {
		siteHeader.appendChild(appNav);

		// Uses `filter: opacity()` instead of `opacity` property because the header's
		// `backdrop-filter` creates a backdrop root that blocks opacity animations.
		const setOpacity = (element, value) => {
			element.style.filter = value < 1 ? `opacity(${value})` : '';
			element.style.pointerEvents = value < 1 ? 'none' : '';
			// A hidden nav must not get keyboard focus or be read by screen readers.
			element.inert = value < 1;
		};

		const fadeTo = (element, target) => {
			element.animate(
				[
					{filter: `opacity(${target < 1 ? 1 : 0})`},
					{filter: `opacity(${target})`},
				],
				{duration: 400, easing: 'ease-in-out'},
			).onfinish = () => setOpacity(element, target);
		};

		const mobileQuery = window.matchMedia('(max-width: 767px)');
		let showing = false;

		new IntersectionObserver(([entry]) => {
			const shouldShow = !entry.isIntersecting && !mobileQuery.matches;

			if (shouldShow === showing) {
				return;
			}

			showing = shouldShow;

			if (shouldShow) {
				fadeTo(siteNav, 0);
				fadeTo(appNav, 1);
			} else {
				fadeTo(appNav, 0);
				fadeTo(siteNav, 1);
			}
		}).observe(hero);

		// Scroll-spy: highlight the active section link in the app nav.
		const navLinks = appNav.querySelectorAll('a[href^="#"]');
		const headings = [...document.querySelectorAll('article h2[id]')];
		const activeColor = getComputedStyle(document.documentElement).getPropertyValue('--color-secondary-500').trim();

		if (navLinks.length > 0 && headings.length > 0) {
			document.addEventListener('scroll', () => {
				let activeId;

				// At the bottom of the page, activate the last section since it may not scroll far enough to trigger normally.
				const isAtBottom = (window.innerHeight + window.scrollY) >= (document.documentElement.scrollHeight - 2);
				if (isAtBottom) {
					activeId = headings.at(-1).id;
				} else {
					// Find the last heading that has scrolled past the top of the viewport.
					for (const heading of headings) {
						if (heading.getBoundingClientRect().top < 100) {
							activeId = heading.id;
						}
					}
				}

				// Underline the active nav link, clear the rest.
				for (const link of navLinks) {
					const isActive = link.getAttribute('href') === `#${activeId}`;
					link.style.textDecorationColor = isActive ? activeColor : 'transparent';
				}
			}, {passive: true});
		}
	}
}

(() => {
	const carousel = document.querySelector('#app-media');
	if (!carousel) {
		return;
	}

	const previousButton = document.querySelector('.media-prev');
	const nextButton = document.querySelector('.media-next');
	const items = [...carousel.querySelectorAll(':scope > *')];

	if (items.length === 0) {
		return;
	}

	// Ensure the first item is visible on load (prevents browser scroll restoration).
	carousel.scrollLeft = 0;

	let currentIndex = 0;

	const getVisualIndex = () => {
		const containerCenter = carousel.getBoundingClientRect().left + carousel.offsetWidth / 2;
		let closestIndex = 0;
		let minimumDistance = Infinity;
		for (const [index, item] of items.entries()) {
			const {left, width} = item.getBoundingClientRect();
			const distance = Math.abs(left + width / 2 - containerCenter);
			if (distance < minimumDistance) {
				minimumDistance = distance;
				closestIndex = index;
			}
		}
		return closestIndex;
	};

	const setButtonHidden = (button, isHidden) => {
		button.style.opacity = isHidden ? '0' : '';
		button.style.pointerEvents = isHidden ? 'none' : '';
	};

	const updateBoundaries = () => {
		setButtonHidden(previousButton, currentIndex === 0);
		setButtonHidden(nextButton, currentIndex === items.length - 1);
	};

	const scrollToIndex = (index) => {
		currentIndex = Math.max(0, Math.min(items.length - 1, index));
		items[currentIndex].scrollIntoView({behavior: 'smooth', block: 'nearest', inline: 'center'});
		updateBoundaries();
	};

	previousButton.addEventListener('click', () => {
		scrollToIndex(currentIndex - 1);
	});
	nextButton.addEventListener('click', () => {
		scrollToIndex(currentIndex + 1);
	});

	// Sync index after user manually swipes so button state stays correct.
	carousel.addEventListener('scrollend', () => {
		currentIndex = getVisualIndex();
		updateBoundaries();
	}, {passive: true});

	updateBoundaries();
})();
