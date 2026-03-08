/* NothingHere — Landing Page Scripts */

(function () {
  'use strict';

  /* --- Star Field Generator --- */
  var starField = document.getElementById('star-field');
  if (starField) {
    var starCount = 60;
    var frag = document.createDocumentFragment();
    for (var i = 0; i < starCount; i++) {
      var star = document.createElement('div');
      star.className = 'star';
      star.style.left = Math.random() * 100 + '%';
      star.style.top = Math.random() * 100 + '%';
      star.style.setProperty('--duration', (2 + Math.random() * 4) + 's');
      star.style.setProperty('--delay', (Math.random() * 4) + 's');
      star.style.width = star.style.height = (1 + Math.random() * 2) + 'px';
      frag.appendChild(star);
    }
    starField.appendChild(frag);
  }

  /* --- Mouse Glow Follow (hero only) --- */
  var hero = document.querySelector('.hero');
  if (hero && window.matchMedia('(pointer: fine)').matches) {
    var glow = document.createElement('div');
    glow.style.cssText =
      'position:absolute;width:400px;height:400px;border-radius:50%;' +
      'background:radial-gradient(circle,rgba(79,143,255,0.08) 0%,transparent 70%);' +
      'pointer-events:none;transform:translate(-50%,-50%);transition:opacity 0.3s;opacity:0;z-index:0;';
    hero.appendChild(glow);
    hero.addEventListener('mousemove', function (e) {
      var rect = hero.getBoundingClientRect();
      glow.style.left = (e.clientX - rect.left) + 'px';
      glow.style.top = (e.clientY - rect.top) + 'px';
      glow.style.opacity = '1';
    });
    hero.addEventListener('mouseleave', function () {
      glow.style.opacity = '0';
    });
  }

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
