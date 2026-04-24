/**
 * Mindiff — Site Vitrine
 * main.js — Interactions & animations
 */

(function () {
  'use strict';

  // =========================================================
  // 1. NAVBAR — sticky + hamburger
  // =========================================================
  function initNavbar() {
    const navbar    = document.getElementById('navbar');
    const hamburger = document.getElementById('hamburger');
    const mobileMenu = document.getElementById('mobile-menu');

    if (!navbar) return;

    // Sticky style
    function handleScroll() {
      if (window.scrollY > 80) {
        navbar.classList.add('is-scrolled');
      } else {
        navbar.classList.remove('is-scrolled');
      }
    }
    window.addEventListener('scroll', handleScroll, { passive: true });
    handleScroll(); // run on load

    // Hamburger toggle
    if (hamburger && mobileMenu) {
      hamburger.addEventListener('click', function () {
        const isOpen = hamburger.classList.toggle('is-open');
        mobileMenu.classList.toggle('is-open', isOpen);
        hamburger.setAttribute('aria-expanded', isOpen.toString());
        mobileMenu.setAttribute('aria-hidden', (!isOpen).toString());
      });

      // Close on link click
      mobileMenu.querySelectorAll('a').forEach(function (link) {
        link.addEventListener('click', function () {
          hamburger.classList.remove('is-open');
          mobileMenu.classList.remove('is-open');
          hamburger.setAttribute('aria-expanded', 'false');
          mobileMenu.setAttribute('aria-hidden', 'true');
        });
      });
    }
  }

  // =========================================================
  // 2. SMOOTH SCROLL — offset-aware
  // =========================================================
  function initSmoothScroll() {
    const NAVBAR_H = parseInt(
      getComputedStyle(document.documentElement).getPropertyValue('--navbar-h') || '72',
      10
    );

    document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {
      anchor.addEventListener('click', function (e) {
        const href = this.getAttribute('href');
        if (href === '#') return;
        const target = document.querySelector(href);
        if (!target) return;
        e.preventDefault();
        const top = target.getBoundingClientRect().top + window.scrollY - NAVBAR_H;
        window.scrollTo({ top: top, behavior: 'smooth' });
      });
    });
  }

  // =========================================================
  // 3. SCROLL ANIMATIONS — IntersectionObserver
  // =========================================================
  function initScrollAnimations() {
    if (!('IntersectionObserver' in window)) {
      // Fallback: make everything visible
      document.querySelectorAll('.animate-on-scroll').forEach(function (el) {
        el.classList.add('is-visible');
      });
      return;
    }

    const observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: '0px 0px -40px 0px' }
    );

    document.querySelectorAll('.animate-on-scroll').forEach(function (el) {
      observer.observe(el);
    });
  }

  // =========================================================
  // 4. COUNTERS — hero stat count-up
  // =========================================================
  function initCounters() {
    const nums = document.querySelectorAll('.stat-num[data-target]');
    if (!nums.length) return;

    function easeOut(t) {
      return 1 - Math.pow(1 - t, 3);
    }

    function animateCounter(el) {
      const target  = parseInt(el.dataset.target, 10);
      const suffix  = el.dataset.suffix || '';
      const duration = 1400; // ms
      let start = null;

      function step(timestamp) {
        if (!start) start = timestamp;
        const elapsed  = timestamp - start;
        const progress = Math.min(elapsed / duration, 1);
        const value    = Math.round(easeOut(progress) * target);
        el.textContent = value + suffix;
        if (progress < 1) requestAnimationFrame(step);
      }
      requestAnimationFrame(step);
    }

    if (!('IntersectionObserver' in window)) {
      nums.forEach(animateCounter);
      return;
    }

    const observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            animateCounter(entry.target);
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.5 }
    );

    nums.forEach(function (el) { observer.observe(el); });
  }

  // =========================================================
  // 5. PARALLAX — hero background + phone mockup
  // =========================================================
  function initParallax() {
    // Skip on mobile / reduced motion
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    if (window.innerWidth < 768) return;

    const hero    = document.getElementById('hero');
    const mockup  = document.querySelector('.hero__mockup');
    if (!hero) return;

    let ticking = false;

    function onScroll() {
      if (!ticking) {
        requestAnimationFrame(function () {
          const scrollY = window.scrollY;
          // Subtle background shift
          hero.style.backgroundPositionY = scrollY * 0.3 + 'px';
          // Phone mockup rises slightly
          if (mockup) {
            mockup.style.transform = 'translateY(' + scrollY * -0.08 + 'px)';
          }
          ticking = false;
        });
        ticking = true;
      }
    }

    window.addEventListener('scroll', onScroll, { passive: true });
  }

  // =========================================================
  // 6. ACTIVE NAV LINK — highlight current section
  // =========================================================
  function initActiveNav() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.navbar__links a[href^="#"]');
    if (!sections.length || !navLinks.length) return;

    const NAVBAR_H = 80;

    function updateActive() {
      let currentId = '';
      sections.forEach(function (section) {
        const top = section.getBoundingClientRect().top;
        if (top <= NAVBAR_H + 40) {
          currentId = section.id;
        }
      });
      navLinks.forEach(function (link) {
        const href = link.getAttribute('href').slice(1);
        link.classList.toggle('active', href === currentId);
      });
    }

    window.addEventListener('scroll', updateActive, { passive: true });
    updateActive();
  }

  // =========================================================
  // 7. QR CODES — APK Android
  // =========================================================
  function initQRCodes() {
    var apks = [
      {
        id: 'qr-prod',
        url: 'https://github.com/Ni-coco/ESP-Mindiff/releases/download/main-latest/app-release.apk'
      },
      {
        id: 'qr-dev',
        url: 'https://github.com/Ni-coco/ESP-Mindiff/releases/download/dev-latest/app-release.apk'
      }
    ];

    function renderFallbackImage(el, url) {
      var img = document.createElement('img');
      img.width = 140;
      img.height = 140;
      img.loading = 'lazy';
      img.alt = 'QR code de telechargement APK';
      img.src = 'https://api.qrserver.com/v1/create-qr-code/?size=140x140&data=' + encodeURIComponent(url);
      el.innerHTML = '';
      el.appendChild(img);
    }

    apks.forEach(function (apk) {
      var el = document.getElementById(apk.id);
      if (!el) return;
      if (typeof QRCode === 'undefined') {
        renderFallbackImage(el, apk.url);
        return;
      }
      try {
        new QRCode(el, {
          text: apk.url,
          width: 140,
          height: 140,
          colorDark: '#121212',
          colorLight: '#ffffff',
          correctLevel: QRCode.CorrectLevel.M
        });
      } catch (e) {
        renderFallbackImage(el, apk.url);
      }
    });
  }

  // =========================================================
  // INIT
  // =========================================================
  function init() {
    initNavbar();
    initSmoothScroll();
    initScrollAnimations();
    initCounters();
    initParallax();
    initActiveNav();
    initQRCodes();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
