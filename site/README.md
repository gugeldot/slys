# SLYS website

The landing page of SLYS, published with GitHub Pages at https://gugeldot.github.io/slys/ from this
folder (workflow `.github/workflows/pages.yml`). Plain HTML, CSS and JavaScript: no build step, no
dependencies.

```
index.html            page (content, metadata, JSON-LD)
404.html              not-found page
assets/css/style.css  styles
assets/js/main.js     mobile menu, OS detection, lightbox, click-to-load videos
assets/fonts/         Roboto (latin, variable, self-hosted)
assets/img/           WebP images
assets/og/            Open Graph image: template (src/) + render.js (needs Playwright)
assets/icons/         favicon set
tools/fill-checksums.py   copies the SHA-256 values from a release's SHA256SUMS into index.html
```

Preview it locally: `cd site && python3 -m http.server 8000`.

## After a release

1. Download `SHA256SUMS` from the GitHub release.
2. `python3 site/tools/fill-checksums.py SHA256SUMS`
3. Update the version number in `index.html` (download section and the JSON-LD `softwareVersion`)
   and the roadmap if needed, then commit. Pushing to `main` publishes the site.

Screenshots and the two videos still show SLYS 1.5; replace them with 1.6 ones when convenient.
