/* ============================================================
   TecDive — main.js
   Handles: header/footer injection, nav, scroll effects,
            back-to-top, gallery filter+lightbox, contact form
   ============================================================ */

'use strict';

// ── 1. HEADER & FOOTER TEMPLATES ─────────────────────────────

const NAV_LINKS = [
  { href: '/index.html',     label: 'Početna'   },
  { href: '/o-nama.html',    label: 'O nama'    },
  { href: '/obuke.html',     label: 'Obuke'     },
  { href: '/galerija.html',  label: 'Galerija'  },
  { href: '/dokumenti.html', label: 'Dokumenti' },
  { href: '/kontakt.html',   label: 'Kontakt'   },
];

function buildNavLinks() {
  const path = window.location.pathname;
  return NAV_LINKS.map(link => {
    const isActive = path === link.href ||
                     (link.href !== '/index.html' && path.startsWith(link.href.replace('.html', '')));
    const activeClass = isActive ? ' nav-link--active' : '';
    if (link.href === '/kontakt.html') {
      return `<a href="${link.href}" class="nav-link nav-cta${activeClass}">${link.label}</a>`;
    }
    return `<a href="${link.href}" class="nav-link${activeClass}">${link.label}</a>`;
  }).join('');
}

const headerHTML = `
<header class="site-header" id="main-header">
  <div class="container">
    <div class="header-inner">
      <a href="/index.html" class="site-logo" aria-label="Tec Dive Subotica - početna">
        <img src="/img/logo.jpg" alt="Tec Dive Subotica" style="height:80px; width:auto; display:block;" />
        <div class="logo-text">
          <span class="logo-name">TecDive</span>
          <span class="logo-subtitle">Subotica · Tehničko ronjenje</span>
        </div>
      </a>
      <nav class="site-nav" id="main-nav" role="navigation" aria-label="Glavna navigacija">
        ${buildNavLinks()}
      </nav>
      <button class="nav-toggle" id="nav-toggle" aria-expanded="false" aria-controls="main-nav" aria-label="Otvori meni">
        <span></span>
        <span></span>
        <span></span>
      </button>
    </div>
  </div>
</header>
`;

const footerHTML = `
<footer class="site-footer">
  <div class="container">
    <div class="footer-main">
      <div class="footer-brand">
        <span class="footer-logo-name">TecDive</span>
        <span class="footer-logo-sub">Subotica · Tehničko ronjenje</span>
        <p>Klub tehničkih ronilaca iz Subotice posvećen sigurnom, odgovornom i uzbudljivom tehničkom ronjenju.</p>
        <div class="social-links">
          <a href="#" class="social-link" aria-label="Facebook" title="Facebook">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
          </a>
          <a href="#" class="social-link" aria-label="Instagram" title="Instagram">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/></svg>
          </a>
        </div>
      </div>

      <div class="footer-col">
        <h4>Navigacija</h4>
        <nav class="footer-nav" aria-label="Footer navigacija">
          <a href="/index.html">Početna</a>
          <a href="/o-nama.html">O nama</a>
          <a href="/obuke.html">Obuke</a>
          <a href="/galerija.html">Galerija</a>
          <a href="/dokumenti.html">Dokumenti</a>
          <a href="/kontakt.html">Kontakt</a>
        </nav>
      </div>

      <div class="footer-col">
        <h4>Kontakt</h4>
        <ul class="footer-contact-list">
          <li class="footer-contact-item">
            <span class="icon" aria-hidden="true">📧</span>
            <a href="mailto:info@tecdive.rs">info@tecdive.rs</a>
          </li>
          <li class="footer-contact-item">
            <span class="icon" aria-hidden="true">📞</span>
            <a href="tel:+381XXXXXXXXX">+381 XX XXX XXXX</a>
          </li>
          <li class="footer-contact-item">
            <span class="icon" aria-hidden="true">📍</span>
            <span>Subotica, Srbija</span>
          </li>
        </ul>
      </div>
    </div>

    <div class="footer-bottom">
      <p class="footer-bottom-text">© ${new Date().getFullYear()} Tec Dive Subotica. Sva prava zadržana.</p>
      <div class="footer-bottom-links">
        <a href="/kontakt.html">Kontakt</a>
      </div>
    </div>
  </div>
</footer>
`;

// ── 2. INJECT HEADER & FOOTER ─────────────────────────────────

document.addEventListener('DOMContentLoaded', function () {
  const headerSlot = document.getElementById('site-header');
  const footerSlot = document.getElementById('site-footer');

  if (headerSlot) headerSlot.outerHTML = headerHTML;
  if (footerSlot) footerSlot.outerHTML = footerHTML;

  // After injection, initialize all behaviors
  initNav();
  initScrollEffects();
  initBackToTop();
  initSmoothScroll();
  initGallery();
  initContactForm();
});

// ── 3. MOBILE NAV TOGGLE ─────────────────────────────────────

function initNav() {
  const toggle = document.getElementById('nav-toggle');
  const nav    = document.getElementById('main-nav');
  if (!toggle || !nav) return;

  toggle.addEventListener('click', function () {
    const isOpen = nav.classList.toggle('nav-open');
    toggle.classList.toggle('is-active', isOpen);
    toggle.setAttribute('aria-expanded', String(isOpen));
    document.body.style.overflow = isOpen ? 'hidden' : '';
  });

  // Close on outside click
  document.addEventListener('click', function (e) {
    if (!nav.contains(e.target) && !toggle.contains(e.target)) {
      closeNav();
    }
  });

  // Close on Escape
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closeNav();
  });

  // Close on nav link click (mobile)
  nav.querySelectorAll('.nav-link').forEach(function (link) {
    link.addEventListener('click', function () {
      closeNav();
    });
  });

  function closeNav() {
    nav.classList.remove('nav-open');
    toggle.classList.remove('is-active');
    toggle.setAttribute('aria-expanded', 'false');
    document.body.style.overflow = '';
  }
}

// ── 4. HEADER SCROLL EFFECT ──────────────────────────────────

function initScrollEffects() {
  const header = document.getElementById('main-header');
  if (!header) return;

  function onScroll() {
    header.classList.toggle('header-scrolled', window.scrollY > 10);
  }

  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
}

// ── 5. BACK-TO-TOP BUTTON ────────────────────────────────────

function initBackToTop() {
  const btn = document.getElementById('back-to-top');
  if (!btn) return;

  window.addEventListener('scroll', function () {
    btn.classList.toggle('visible', window.scrollY > 400);
  }, { passive: true });

  btn.addEventListener('click', function () {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
}

// ── 6. SMOOTH SCROLL FOR ANCHOR LINKS ────────────────────────

function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {
    anchor.addEventListener('click', function (e) {
      const target = document.querySelector(this.getAttribute('href'));
      if (!target) return;
      e.preventDefault();
      const navHeight = parseInt(getComputedStyle(document.documentElement)
                          .getPropertyValue('--nav-height'), 10) || 72;
      const top = target.getBoundingClientRect().top + window.scrollY - navHeight - 16;
      window.scrollTo({ top: top, behavior: 'smooth' });
    });
  });
}

// ── 7. GALLERY FILTER + LIGHTBOX ────────────────────────────

function initGallery() {
  initGalleryFilter();
  initGalleryLightbox();
}

function initGalleryFilter() {
  const filterBtns = document.querySelectorAll('.gallery-filter-btn');
  const items      = document.querySelectorAll('.gallery-item');
  if (!filterBtns.length) return;

  filterBtns.forEach(function (btn) {
    btn.addEventListener('click', function () {
      const filter = this.dataset.filter;

      filterBtns.forEach(function (b) { b.classList.remove('active'); });
      this.classList.add('active');

      items.forEach(function (item) {
        if (filter === 'all' || item.dataset.category === filter) {
          item.classList.remove('hidden');
        } else {
          item.classList.add('hidden');
        }
      });
    });
  });
}

function initGalleryLightbox() {
  const items   = document.querySelectorAll('.gallery-item');
  const lb      = document.getElementById('lightbox');
  if (!items.length || !lb) return;

  const lbImg     = lb.querySelector('.lightbox-img');
  const lbCaption = lb.querySelector('.lightbox-caption');
  const lbClose   = lb.querySelector('.lightbox-close');
  const lbPrev    = lb.querySelector('.lightbox-prev');
  const lbNext    = lb.querySelector('.lightbox-next');

  let currentIdx  = 0;
  let visibleItems = [];

  function getVisible() {
    return Array.from(items).filter(function (i) {
      return !i.classList.contains('hidden');
    });
  }

  function openLightbox(idx) {
    visibleItems = getVisible();
    currentIdx = idx;
    showImage(currentIdx);
    lb.classList.add('is-open');
    document.body.style.overflow = 'hidden';
  }

  function closeLightbox() {
    lb.classList.remove('is-open');
    document.body.style.overflow = '';
  }

  function showImage(idx) {
    const item = visibleItems[idx];
    if (!item) return;
    const img     = item.querySelector('img');
    const caption = item.querySelector('.gallery-item-caption');
    lbImg.src         = img ? img.src : '';
    lbImg.alt         = img ? img.alt : '';
    lbCaption.textContent = caption ? caption.textContent : '';
  }

  function navigate(dir) {
    currentIdx = (currentIdx + dir + visibleItems.length) % visibleItems.length;
    showImage(currentIdx);
  }

  items.forEach(function (item, idx) {
    if (item.hasAttribute('data-no-lightbox')) return;
    item.addEventListener('click', function () {
      const visible = getVisible();
      const vIdx = visible.indexOf(item);
      openLightbox(vIdx);
    });
  });

  if (lbClose) lbClose.addEventListener('click', closeLightbox);
  if (lbPrev)  lbPrev.addEventListener('click', function () { navigate(-1); });
  if (lbNext)  lbNext.addEventListener('click', function () { navigate(1); });

  lb.addEventListener('click', function (e) {
    if (e.target === lb) closeLightbox();
  });

  document.addEventListener('keydown', function (e) {
    if (!lb.classList.contains('is-open')) return;
    if (e.key === 'Escape')      closeLightbox();
    if (e.key === 'ArrowLeft')   navigate(-1);
    if (e.key === 'ArrowRight')  navigate(1);
  });
}

// ── 8. CONTACT FORM UX ───────────────────────────────────────

function initContactForm() {
  const form = document.getElementById('contact-form');
  if (!form) return;

  // Show success message if redirected back by Formspree
  const params = new URLSearchParams(window.location.search);
  if (params.get('submission') === 'success') {
    const success = document.getElementById('form-success');
    if (success) {
      success.classList.add('visible');
      form.style.display = 'none';
    }
  }

  form.addEventListener('submit', function (e) {
    let valid = true;

    // Clear previous errors
    form.querySelectorAll('.form-error').forEach(function (el) {
      el.classList.remove('visible');
    });

    // Validate required fields
    form.querySelectorAll('[required]').forEach(function (field) {
      const err = field.parentNode.querySelector('.form-error');
      if (!field.value.trim()) {
        valid = false;
        if (err) err.classList.add('visible');
        field.focus();
      }
    });

    // Validate email format
    const emailField = form.querySelector('[type="email"]');
    if (emailField && emailField.value) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(emailField.value)) {
        valid = false;
        const err = emailField.parentNode.querySelector('.form-error');
        if (err) {
          err.textContent = 'Unesite ispravnu email adresu.';
          err.classList.add('visible');
        }
      }
    }

    if (!valid) e.preventDefault();
  });
}
