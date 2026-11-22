# SLYS landing page

Static landing page for SLYS (the application repository is private), published with GitHub Pages at https://gugeldot.github.io/slys-web/.
Plain HTML, CSS and JavaScript: no build step, no dependencies.

```
index.html            page (content, metadata, JSON-LD)
404.html              not-found page
assets/css/style.css  styles
assets/js/main.js     mobile menu, OS detection, lightbox, click-to-load videos
assets/fonts/         Roboto (latin, variable, self-hosted)
assets/img/           WebP images
assets/og/            Open Graph image: template (src/) + render.js (needs Playwright)
assets/icons/         favicon set
tools/fill-checksums.py   writes the SHA-256 of the release files into index.html
```

## Publishing a release

1. Upload the installer and the ZIP to GitHub Releases of `gugeldot/slys`.
2. `python3 tools/fill-checksums.py Slys_Installer.exe Slys_Linux.zip`
3. Check the `TODO:` comments in `index.html`.
