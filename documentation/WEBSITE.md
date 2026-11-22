# SLYS website

The landing page of SLYS lives in `docs/` and is served by GitHub Pages at
https://gugeldot.github.io/slys/. Plain HTML, CSS and JavaScript: no build step, no dependencies,
no workflow (the `docs/` folder is the one GitHub Pages can serve straight from a branch).

> The technical documents (format, security, releasing...) are in `documentation/`, not in `docs/`,
> so they are not published as part of the website.

```
docs/index.html            page (content, metadata, JSON-LD)
docs/404.html              not-found page
docs/assets/css/style.css  styles
docs/assets/js/main.js     mobile menu, OS detection, lightbox, click-to-load videos
docs/assets/fonts/         Roboto (latin, variable, self-hosted)
docs/assets/img/           WebP images
docs/assets/og/            Open Graph image: template (src/) + render.js (needs Playwright)
docs/assets/icons/         favicon set
docs/tools/fill-checksums.py   copies the SHA-256 values from a release's SHA256SUMS into index.html
```

## One-time setup (repository owner)

*Settings -> Pages -> Build and deployment -> Source: Deploy from a branch -> Branch: `main`,
folder `/docs`*.

## Preview locally

`cd docs && python3 -m http.server 8000`

## After a release

1. Download `SHA256SUMS` from the GitHub release.
2. `python3 docs/tools/fill-checksums.py SHA256SUMS`
3. Update the version number in `docs/index.html` (download section and the JSON-LD `softwareVersion`)
   and the roadmap if needed, then commit. Pushing to `main` publishes the site.

Screenshots and the two videos still show SLYS 1.5; replace them with 1.6 ones when convenient.
