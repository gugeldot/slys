/* SLYS landing: menu, scroll progress, reveal, spotlight, tabs, encryption modes,
   screenshot stage + lightbox, click-to-load videos, OS detection. No dependencies. */
(function () {
  'use strict';
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  /* Always start at the top (the intro animation is built for the first screen) */
  var toTop = function () {
    if (location.hash) { try { history.replaceState(null, '', location.pathname + location.search); } catch (e) {} }
    window.scrollTo(0, 0);
  };
  toTop();
  addEventListener('load', toTop);
  addEventListener('pageshow', function (e) { if (e.persisted) toTop(); });
  var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* Mobile menu */
  var toggle = $('.nav-toggle');
  var nav = $('#site-nav');
  if (toggle && nav) {
    var closeNav = function () { nav.classList.remove('open'); toggle.setAttribute('aria-expanded', 'false'); };
    toggle.addEventListener('click', function () {
      toggle.setAttribute('aria-expanded', String(nav.classList.toggle('open')));
    });
    nav.addEventListener('click', function (e) { if (e.target.closest('a')) closeNav(); });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && nav.classList.contains('open')) { closeNav(); toggle.focus(); }
    });
  }

  /* Sliding indicator behind the nav pills (follows hover, rests on the active section) */
  var ind = $('.ind');
  var rest = null;
  var moveInd = function (el) {
    if (!ind) return;
    if (!el || getComputedStyle(ind).display === 'none') { ind.style.opacity = 0; return; }
    ind.style.width = el.offsetWidth + 'px';
    ind.style.transform = 'translateX(' + el.offsetLeft + 'px)';
    ind.style.opacity = 1;
  };
  if (ind && nav) {
    $$('.pill', nav).forEach(function (p) {
      p.addEventListener('pointerenter', function () { moveInd(p); });
      p.addEventListener('focus', function () { moveInd(p); });
    });
    nav.addEventListener('pointerleave', function () { moveInd(rest); });
    addEventListener('resize', function () { moveInd(rest); });
  }

  /* Scroll progress bar */
  var bar = $('.progress');
  if (bar) {
    var tick = false;
    var upd = function () {
      var h = document.documentElement;
      var max = h.scrollHeight - h.clientHeight;
      bar.style.transform = 'scaleX(' + (max > 0 ? Math.min(1, h.scrollTop / max) : 0) + ')';
      tick = false;
    };
    addEventListener('scroll', function () { if (!tick) { tick = true; requestAnimationFrame(upd); } }, { passive: true });
    upd();
  }

  /* Highlight the nav pill of the section in view */
  if ('IntersectionObserver' in window) {
    var pills = {};
    $$('.nav .pill').forEach(function (a) { pills[a.getAttribute('href').slice(1)] = a; });
    var spy = new IntersectionObserver(function (es) {
      es.forEach(function (en) {
        var p = pills[en.target.id];
        if (!p) return;
        if (en.isIntersecting) { $$('.nav .pill.on').forEach(function (x) { x.classList.remove('on'); }); p.classList.add('on'); rest = p; moveInd(p); }
      });
    }, { rootMargin: '-45% 0px -50% 0px' });
    Object.keys(pills).forEach(function (id) { var s = document.getElementById(id); if (s) spy.observe(s); });
  }

  /* Scroll reveal (+ count-up for the numbers inside) */
  var countUp = function (root) {
    $$('[data-count]', root).forEach(function (el) {
      var to = parseInt(el.getAttribute('data-count'), 10);
      if (reduce || !to) return;
      var t0 = null;
      var step = function (t) {
        if (t0 === null) t0 = t;
        var k = Math.min(1, (t - t0) / 1100);
        var v = Math.round(to * (1 - Math.pow(1 - k, 3)));
        el.textContent = v.toLocaleString('en-US');
        if (k < 1) requestAnimationFrame(step);
      };
      el.textContent = '0';
      requestAnimationFrame(step);
    });
  };
  var items = $$('.reveal');
  if ('IntersectionObserver' in window && !reduce) {
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (en) {
        if (!en.isIntersecting) return;
        en.target.classList.add('in');
        countUp(en.target);
        io.unobserve(en.target);
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -6% 0px' });
    items.forEach(function (el) { io.observe(el); });
  } else {
    items.forEach(function (el) { el.classList.add('in'); });
  }

  /* Cursor spotlight on cards */
  if (!reduce) {
    document.addEventListener('pointermove', function (e) {
      var c = e.target.closest && e.target.closest('.card');
      if (!c) return;
      var r = c.getBoundingClientRect();
      c.style.setProperty('--mx', (e.clientX - r.left) + 'px');
      c.style.setProperty('--my', (e.clientY - r.top) + 'px');
    }, { passive: true });
  }

  /* Fragment / Recompose tabs */
  var tabs = $('.tabs');
  if (tabs) {
    tabs.hidden = false;
    var tbs = $$('[role="tab"]', tabs);
    var select = function (tb, focus) {
      tbs.forEach(function (t) {
        var on = t === tb;
        t.setAttribute('aria-selected', String(on));
        t.tabIndex = on ? 0 : -1;
        var p = document.getElementById(t.getAttribute('aria-controls'));
        if (p) {
          p.hidden = !on;
          if (on) { var l = $('.steps', p); if (l) { l.classList.remove('in'); void l.offsetWidth; l.classList.add('in'); } }
        }
      });
      if (focus) tb.focus();
    };
    tbs.forEach(function (t, i) {
      t.addEventListener('click', function () { select(t); });
      t.addEventListener('keydown', function (e) {
        if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
          e.preventDefault();
          select(tbs[(i + (e.key === 'ArrowRight' ? 1 : tbs.length - 1)) % tbs.length], true);
        }
      });
    });
    select(tbs[0]);
    /* hide the panel headings, the tabs already name them */
    $$('.panel > h3').forEach(function (h) { h.classList.add('sr-only'); });
  }

  /* Encryption mode picker: padlocks snap shut when the mode scrolls into view or changes */
  var frags = $$('[data-frags] .frag');
  if (frags.length) {
    var lockFrags = function (m) {
      frags.forEach(function (f, i) {
        f.classList.toggle('enc', m === 'high' || (m === 'mid' && (i === 0 || i === frags.length - 1)));
      });
    };
    var curMode = function () { var c = $('input[name="mode"]:checked'); return c ? c.value : 'mid'; };
    $$('input[name="mode"]').forEach(function (r) {
      r.addEventListener('change', function () {
        $$('.mode-desc').forEach(function (d) { d.classList.toggle('on', d.getAttribute('data-mode') === r.value); });
        lockFrags('none');
        void $('[data-frags]').offsetWidth;
        requestAnimationFrame(function () { lockFrags(r.value); });
      });
    });
    var mc = $('.modes');
    if (mc && 'IntersectionObserver' in window && !reduce) {
      lockFrags('none');
      new IntersectionObserver(function (es, o) {
        if (es[0].isIntersecting) { lockFrags(curMode()); o.disconnect(); }
      }, { threshold: 0.5 }).observe(mc);
    }
  }

  /* OS detection: highlight the matching download card */
  var uaData = navigator.userAgentData && navigator.userAgentData.platform;
  var raw = (uaData || navigator.platform || '') + ' ' + (navigator.userAgent || '');
  var os = null;
  if (/android/i.test(raw)) os = null;
  else if (/win/i.test(raw)) os = 'windows';
  else if (/linux|x11|cros/i.test(raw)) os = 'linux';
  if (os) {
    var card = $('.os[data-os="' + os + '"]');
    if (card) {
      card.classList.add('is-current');
      var rec = $('.rec', card);
      if (rec) rec.hidden = false;
    }
  }

  /* Screenshot carousel: scroll-snap track, auto-advance, arrows, dots; lightbox on <dialog> */
  var vp = $('.viewport');
  var slides = $$('.slide', vp || document);
  var dots = $$('.dot');
  var cur = 0;
  var width = function () { return vp.clientWidth; };
  var goTo = function (i, smooth) {
    cur = (i + slides.length) % slides.length;
    vp.scrollTo({ left: cur * width(), behavior: smooth === false || reduce ? 'auto' : 'smooth' });
    mark();
  };
  var mark = function () {
    dots.forEach(function (d, k) { d.classList.toggle('on', k === cur); if (k === cur) d.setAttribute('aria-current', 'true'); else d.removeAttribute('aria-current'); });
  };
  var timer = null, inView = false, hovering = false;
  var play = function () {
    clearInterval(timer);
    if (reduce || !inView || hovering || document.hidden) return;
    timer = setInterval(function () { goTo(cur + 1); }, 5000);
  };
  if (vp && slides.length) {
    var settle;
    vp.addEventListener('scroll', function () {
      clearTimeout(settle);
      settle = setTimeout(function () {
        var i = Math.round(vp.scrollLeft / width());
        if (i !== cur) { cur = i; mark(); play(); }
      }, 80);
    }, { passive: true });
    $('.car-btn.prev').addEventListener('click', function () { goTo(cur - 1); play(); });
    $('.car-btn.next').addEventListener('click', function () { goTo(cur + 1); play(); });
    dots.forEach(function (d, k) { d.addEventListener('click', function () { goTo(k); play(); }); });
    vp.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowRight') { e.preventDefault(); goTo(cur + 1); play(); }
      if (e.key === 'ArrowLeft') { e.preventDefault(); goTo(cur - 1); play(); }
    });
    addEventListener('resize', function () { goTo(cur, false); });
    var box = $('.carousel');
    box.addEventListener('pointerenter', function () { hovering = true; play(); });
    box.addEventListener('pointerleave', function () { hovering = false; play(); });
    box.addEventListener('focusin', function () { hovering = true; play(); });
    box.addEventListener('focusout', function () { hovering = false; play(); });
    document.addEventListener('visibilitychange', play);
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (es) { inView = es[0].isIntersecting; play(); }, { threshold: 0.35 }).observe(box);
    } else { inView = true; play(); }
  }

  var dlg = $('.lightbox');
  if (dlg && typeof dlg.showModal === 'function' && slides.length) {
    var limg = $('img', dlg);
    var lcap = $('figcaption', dlg);
    var lshow = function (i) {
      goTo(i, false);
      var im = $('img', slides[cur]);
      limg.src = im.getAttribute('src');
      limg.alt = im.alt;
      lcap.textContent = $('figcaption', slides[cur]).textContent;
    };
    slides.forEach(function (s, i) {
      $('a', s).addEventListener('click', function (e) { e.preventDefault(); lshow(i); dlg.showModal(); });
    });
    dlg.addEventListener('click', function (e) {
      var b = e.target.closest('[data-lb]');
      if (b) {
        var act = b.getAttribute('data-lb');
        if (act === 'close') dlg.close();
        else lshow(cur + (act === 'next' ? 1 : -1));
      } else if (e.target === dlg) {
        dlg.close();
      }
    });
    dlg.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowRight') lshow(cur + 1);
      if (e.key === 'ArrowLeft') lshow(cur - 1);
    });
    dlg.addEventListener('close', function () { var a = $('a', slides[cur]); if (a) a.focus(); });
  }

  /* Accordions: smooth height + fade on open and close (native <details> underneath) */
  $$('details.acc').forEach(function (d) {
    var s = $('summary', d), body = $('.body', d), run = null;
    s.addEventListener('click', function (e) {
      if (reduce || !d.animate) return;
      e.preventDefault();
      if (run) { run.forEach(function (a) { a.cancel(); }); run = null; }
      var from = d.offsetHeight, opening = !d.open, to;
      d.style.overflow = 'hidden';
      if (opening) { d.open = true; to = d.offsetHeight; }
      else { d.classList.add('closing'); to = s.offsetHeight + 2; }
      var opt = { duration: 420, easing: 'cubic-bezier(.2,.8,.2,1)' };
      var h = d.animate({ height: [from + 'px', to + 'px'] }, opt);
      var f = body.animate({ opacity: opening ? [0, 1] : [1, 0], transform: opening ? ['translateY(-8px)', 'none'] : ['none', 'translateY(-8px)'] }, opt);
      run = [h, f];
      h.onfinish = function () {
        if (!opening) d.open = false;
        d.classList.remove('closing');
        d.style.overflow = '';
        run = null;
      };
    });
  });

  /* Videos: load the YouTube player only after the visitor asks for it.
     The referrer policy and origin are required by YouTube (otherwise: player error 153). */
  $$('a.video[data-yt]').forEach(function (a) {
    a.addEventListener('click', function (e) {
      e.preventDefault();
      var f = document.createElement('iframe');
      var q = '?autoplay=1&rel=0&playsinline=1';
      if (/^https?:$/.test(location.protocol)) q += '&origin=' + encodeURIComponent(location.origin);
      f.src = 'https://www.youtube-nocookie.com/embed/' + encodeURIComponent(a.getAttribute('data-yt')) + q;
      f.title = a.getAttribute('data-title') || 'Video';
      f.allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen';
      f.referrerPolicy = 'strict-origin-when-cross-origin';
      f.allowFullscreen = true;
      var box = document.createElement('div');
      box.className = 'video';
      box.appendChild(f);
      a.replaceWith(box);
      f.focus();
    });
  });

  /* Intro: the page starts empty, the pieces of logo, headline and buttons drop in as little tiles,
     rest scattered for a moment, then snap together. Each piece is a clipped clone of the real element
     (the real one takes over at the end). Uses the Web Animations API; skipped for reduced motion. */
  (function () {
    var hero = $('.hero');
    var els = hero ? $$('.intro', hero) : [];
    var finish = function () {
      els.forEach(function (e) { e.classList.remove('intro'); });
      document.documentElement.classList.add('intro-done');
    };
    if (!els.length || reduce || !document.fonts || !document.documentElement.animate) { finish(); return; }
    var EMPTY = 2500, FALL = 1000, MOVE = 2100;
    var plan = function (e) {
      if (e.tagName === 'IMG') return { c: 8, r: 4, d: 0 };
      if (e.classList.contains('lead')) return { c: 10, r: 2, d: .35 };
      return { c: 4, r: 2, d: .7 };
    };
    var run = function () {
      var hr = hero.getBoundingClientRect();
      var layer = document.createElement('div');
      layer.className = 'frag-layer';
      layer.setAttribute('aria-hidden', 'true');
      var W = innerWidth, H = innerHeight, pieces = [], T = 0;
      els.forEach(function (e) {
        var r = e.getBoundingClientRect(), p = plan(e);
        var pw = r.width / p.c, ph = r.height / p.r;
        for (var y = 0; y < p.r; y++) {
          for (var x = 0; x < p.c; x++) {
            var tile = document.createElement('div');
            tile.className = 'pc';
            tile.style.left = (r.left - hr.left + x * pw) + 'px';
            tile.style.top = (r.top - hr.top + y * ph) + 'px';
            tile.style.width = (pw + .6) + 'px';
            tile.style.height = (ph + .6) + 'px';
            var bg = document.createElement('i');
            var c = e.cloneNode(true);
            c.classList.remove('intro');
            c.removeAttribute('id'); c.removeAttribute('href'); c.removeAttribute('fetchpriority'); c.tabIndex = -1;
            var s = c.style;
            s.position = 'absolute'; s.maxWidth = 'none'; s.margin = '0'; s.animation = 'none'; s.opacity = '1'; s.transition = 'none';
            s.left = (-x * pw) + 'px'; s.top = (-y * ph) + 'px';
            s.width = r.width + 'px'; s.height = r.height + 'px';
            tile.appendChild(bg); tile.appendChild(c); layer.appendChild(tile);
            var fd = EMPTY + Math.random() * 500;
            var ad = EMPTY + FALL + 650 + p.d * 1000 + Math.random() * 600 + 500;
            T = Math.max(T, ad + MOVE);
            var homeX = r.left + x * pw + pw / 2, homeY = r.top + y * ph + ph / 2;
            var dx = (.04 + Math.random() * .92) * W - homeX, dy = (70 + Math.random() * (H - 150)) - homeY;
            var rot = (Math.random() - .5) * 70, sc = (.85 + Math.random() * .3).toFixed(2);
            pieces.push({ tile: tile, bg: bg, fd: fd, ad: ad,
              from: 'translate(' + dx.toFixed(0) + 'px,' + (-H - 300) + 'px) rotate(' + (rot * 2).toFixed(0) + 'deg)',
              rest: 'translate(' + dx.toFixed(0) + 'px,' + dy.toFixed(0) + 'px) rotate(' + rot.toFixed(0) + 'deg) scale(' + sc + ')' });
          }
        }
      });
      hero.appendChild(layer);
      pieces.forEach(function (q) {
        var o = function (ms) { return Math.min(1, ms / T); };
        q.tile.animate([
          { transform: q.from, borderRadius: '9px', offset: 0 },
          { transform: q.from, borderRadius: '9px', offset: o(q.fd), easing: 'cubic-bezier(.3,1.35,.5,1)' },
          { transform: q.rest, borderRadius: '9px', offset: o(q.fd + FALL) },
          { transform: q.rest, borderRadius: '9px', offset: o(q.ad), easing: 'cubic-bezier(.2,.8,.2,1)' },
          { transform: 'none', borderRadius: '0px', offset: o(q.ad + MOVE) },
          { transform: 'none', borderRadius: '0px', offset: 1 }
        ], { duration: T, fill: 'both' });
        q.bg.animate([
          { opacity: 1, offset: 0 }, { opacity: 1, offset: o(q.ad + MOVE * .35) },
          { opacity: 0, offset: o(q.ad + MOVE * .9) }, { opacity: 0, offset: 1 }
        ], { duration: T, fill: 'both' });
      });
      setTimeout(function () { finish(); layer.remove(); }, T + 200);
    };
    var imgs = els.filter(function (e) { return e.tagName === 'IMG'; });
    var ready = imgs.map(function (i) { return i.decode ? i.decode().catch(function () {}) : Promise.resolve(); });
    Promise.all(ready.concat([document.fonts.ready])).then(run);
  })();
})();
