(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
	typeof define === 'function' && define.amd ? define(factory) :
	(global.AnchorScroller = factory());
}(this, (function () { 'use strict';

class Scroller {
    constructor(options) {
        this.options = options;
        this.documentLength = Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight);
    }
    scrollTo(position) {
        this.time = 0;
        this.position = position;
        this.positionRelativeToBottom = this.documentLength - this.position;
        this.start = window.scrollY;
        this.change = this.calculateChange();
        this.animation = requestAnimationFrame(this.scroll.bind(this));
    }
    userHasCanceledScroll() {
        if (window.scrollY !== Math.floor(this.options.animation(this.time, this.start, this.change, this.options.time.duration)) &&
            window.scrollY !== Math.ceil(this.options.animation(this.time, this.start, this.change, this.options.time.duration))) {
            return true;
        }
        else if (window.scrollY !== Math.floor(this.options.animation(this.time, this.start, this.change, this.options.time.duration)) &&
            window.scrollY === Math.ceil(this.options.animation(this.time, this.start, this.change, this.options.time.duration))) {
            return false;
        }
        else {
            return false;
        }
    }
    calculateChange() {
        return this.positionRelativeToBottom < window.innerHeight
            ? this.documentLength - window.innerHeight - this.start
            : this.position - this.start;
    }
    scroll() {
        if (this.userHasCanceledScroll()) {
            cancelAnimationFrame(this.animation);
            return;
        }
        this.time += this.options.time.increment;
        window.scroll(window.scrollX, this.options.animation(this.time, this.start, this.change, this.options.time.duration));
        if (this.time < this.options.time.duration) {
            this.animation = requestAnimationFrame(this.scroll.bind(this));
        }
    }
}

class AnchorScroller {
    constructor(optionalOptions) {
        this.optionalOptions = optionalOptions;
        this.options = Object.assign({ checkParent: false, class: undefined, animation: (time, start, change, duration) => {
                return ((time /= duration / 2) < 1)
                    ? change / 2 * time * time * time + start
                    : change / 2 * ((time -= 2) * time * time + 2) + start;
            }, time: {
                increment: 25,
                duration: 1500
            } }, optionalOptions);
        this.scroller = new Scroller({
            animation: this.options.animation,
            time: this.options.time
        });
        this.check = this.check.bind(this);
        document.addEventListener('click', this.check);
    }
    scroll(position) {
        this.scroller.scrollTo(position);
    }
    destroy() {
        document.removeEventListener('click', this.check);
    }
    check(event) {
        if (event.target.nodeName === 'A') {
            this.checkElement(event.target, event);
        }
        else if (this.options.checkParent && event.target.parentNode && event.target.parentNode.nodeName === 'A') {
            this.checkElement(event.target.parentNode, event);
        }
    }
    checkElement(element, event) {
        if (this.options.class && !element.classList.contains(this.options.class))
            return;
        const hash = element.hash;
        if (!hash)
            return;
        const anchor = document.getElementById(hash.slice(1));
        if (!anchor)
            return;
        event.preventDefault();
        if (window.scrollY !== anchor.offsetTop) {
            this.scroll(anchor.offsetTop);
        }
    }
}

return AnchorScroller;

})));
