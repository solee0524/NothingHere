/* NothingHere — Landing Page Scripts */

(function () {
  'use strict';

  /* --- Scroll Reveal (IntersectionObserver) --- */
  var revealEls = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window) {
    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add('revealed');
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15, rootMargin: '0px 0px -40px 0px' }
    );
    revealEls.forEach(function (el) { observer.observe(el); });
  } else {
    revealEls.forEach(function (el) { el.classList.add('revealed'); });
  }

  /* --- Navigation scroll background --- */
  var nav = document.querySelector('.nav');
  if (nav) {
    window.addEventListener('scroll', function () {
      nav.classList.toggle('scrolled', window.scrollY > 20);
    }, { passive: true });
  }

  /* --- Guard Mode state toggle --- */
  var demo = document.querySelector('.guard-demo');
  if (demo) {
    var menuBar = demo.querySelector('.menu-bar-mock');
    var armedState = demo.querySelector('.guard-armed');
    var disarmedState = demo.querySelector('.guard-disarmed');
    var pill = demo.querySelector('.pill-armed');
    var armedIcon = demo.querySelector('.armed-icon');
    var disarmedIcon = demo.querySelector('.disarmed-icon');
    var isArmed = true;

    setInterval(function () {
      isArmed = !isArmed;
      if (menuBar) {
        menuBar.classList.toggle('armed', isArmed);
        menuBar.classList.toggle('disarmed', !isArmed);
      }
      if (armedIcon && disarmedIcon) {
        armedIcon.style.display = isArmed ? '' : 'none';
        disarmedIcon.style.display = isArmed ? 'none' : '';
      }
      if (pill) {
        pill.className = 'guard-pill pill-armed ' + (isArmed ? 'armed' : 'disarmed');
        pill.textContent = isArmed ? 'Armed' : 'Disarmed';
      }
      if (armedState && disarmedState) {
        armedState.classList.toggle('hidden', !isArmed);
        disarmedState.classList.toggle('hidden', isArmed);
      }
    }, 4000);
  }

  /* --- Mobile menu toggle --- */
  var toggle = document.querySelector('.nav-toggle');
  var links = document.querySelector('.nav-links');
  if (toggle && links) {
    toggle.addEventListener('click', function () {
      toggle.classList.toggle('open');
      links.classList.toggle('open');
    });
    links.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () {
        toggle.classList.remove('open');
        links.classList.remove('open');
      });
    });
  }
})();
