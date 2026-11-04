# Quarto academic site + technical blog

A complete, ready-to-render Quarto website: about-style homepage, publications
(driven off `references.bib`), CV, and a math+code technical blog with an RSS
feed. Posts are `.qmd` — markdown with real LaTeX math (`$...$`, `$$...$$`) and
executable Python/R/Julia code cells.

## What's here

```
_quarto.yml        site config: navbar, theme, MathJax macros, bibliography
index.qmd          about-style homepage
publications.qmd   publications (rendered from references.bib)
cv.qmd             CV page (+ link to a PDF you drop in assets/)
blog.qmd           blog listing page (generates blog.xml RSS feed)
posts/             one folder per post; sample post included
styles.scss        custom theme (quiet academic palette)
references.bib     your bibliography
requirements.txt   Python deps — only needed because the sample post runs code
.github/workflows/publish.yml   auto-build + deploy to GitHub Pages
```

## Run it locally

1. Install Quarto (single binary): <https://quarto.org/docs/get-started/>.
2. The sample post executes Python, so once: `pip install -r requirements.txt`.
   (If you delete the sample post's code cells you can skip this and remove the
   Python step from the workflow.)
3. Live preview with reload:

   ```bash
   quarto preview
   ```

4. One-off build into `_site/`:

   ```bash
   quarto render
   ```

## Writing a post

Create `posts/my-post/index.qmd` with front matter:

```yaml
---
title: "My title"
date: 2026-02-01
categories: [genetics, methods]
---
```

Then write prose with `$\hsq$`-style inline math and `$$ ... $$` display math.
Custom macros (e.g. `\rg`, `\hsq`, `\cov{·}{·}`) are defined once in
`_quarto.yml` under `MathJax.tex.macros` and work in every post — edit that list
to match your notation. Code cells run at render time and embed their figures:

````
```{python}
import numpy as np
...
plt.show()
```
````

## Deploy to GitHub Pages (free)

1. Push this folder to a GitHub repo (e.g. `yourname.github.io` for a root site,
   or any repo name for a project site).
2. Repo **Settings → Pages → Build and deployment → Source: GitHub Actions**.
3. Push to `main`. The included workflow renders and deploys automatically.
4. Update `site-url` in `_quarto.yml` to your final URL.

### Custom domain (optional, ~$10–15/yr)

Add a `CNAME` file containing your domain, set the DNS records your registrar
documents for GitHub Pages, and enable "Enforce HTTPS" in Settings → Pages.

## Things marked to change

Search for `<-- change` and `XXXX` / `your-handle` placeholders in
`_quarto.yml`, `index.qmd`, `cv.qmd`, and `publications.qmd`. Drop a headshot at
`assets/profile.jpg` and (optionally) a `assets/cv.pdf`.
