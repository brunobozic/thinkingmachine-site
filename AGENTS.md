# AGENTS.md — Operating rules for AI agents working on this repo

This file is **mandatory reading before any non-trivial change**. Most of it is
hard-won knowledge — every gotcha here cost real time the first time we hit it.

## 1. The Windows long-path gotcha (single biggest source of pain)

**Symptom:** `git status` or `git checkout` fails with `Filename too long` or
`unable to open loose object <hash>: Filename too long`, even though no single
file in the working tree is unusually long.

**Cause:** The repo lives under
`C:\Users\BrunoBozic\AppData\Roaming\Claude\local-agent-mode-sessions\<uuid>\<uuid>\<uuid>\outputs\thinkingmachine-site`
— roughly 214 characters of path before the working tree begins. Git internally
constructs paths like `.git/objects/84/3004d704...` and when the full physical
path crosses Windows' MAX_PATH (260 chars), the syscall fails.

**Fix (one-time, machine-wide):**
```
git config --global core.longpaths true
```
This makes git use Windows' `\\?\` extended-length path prefix internally.

**What does NOT help:** Creating a directory junction (`mklink /J C:\tm
<long-path>`). Git resolves the junction back to the real path before opening
files, so the long-path problem returns. Use `core.longpaths true` instead.

**Best practice for new agents:** When cloning fresh, clone to a short path
like `C:\tm-fresh` or `C:\repos\<name>`. Avoid placing repos under AppData.

## 2. The Astro/cowork sandbox `.git/` write deny

**Symptom:** Inside the sandboxed bash tool (`mcp__workspace__bash`), commands
like `git stash`, `git reset`, `git commit`, even `rm -f .git/index.lock` fail
with `Operation not permitted` — despite the file being owned by the sandbox
user.

**Cause:** The cowork session's outputs mount blocks `unlink`/write syscalls on
the `.git/` subtree, regardless of POSIX permissions. This is a sandbox security
policy, not a permissions issue.

**Fix:** Don't run git operations from the sandbox bash. Use **Desktop Commander**
(`mcp__Desktop_Commander__start_process` with `cmd.exe`) which runs on Bruno's
real Windows shell and has full filesystem access.

**What CAN be done from the sandbox:** Read git objects via `git show
origin/main:<path>` (this reads pack objects only, not the index, so works
fine). All file edits via the `Edit`/`Write` tools also work — they go to the
Windows-side filesystem directly.

## 3. Stale local repo state across sessions

**Symptom:** Local working tree has a different state than origin/main. Files
appear unmodified locally but the live site reflects more recent commits.

**Cause:** Multiple Claude sessions have written files via Edit/Write without
committing. Origin/main has been advanced by previous Claude sessions that
DID commit (via the user's Windows shell). The local working tree drifts.

**Fix:** Don't try to fix the existing working tree. Clone fresh to a short
path (`C:\tm-fresh`), copy your edited files over, commit + push from there.
The original (long-path) repo is fine to use for reading current local state;
just don't try to commit from it.

## 4. SSH keys not authenticating to GitHub from cmd-spawned processes

**Symptom:** `git push` / `git clone git@github.com:…` fails with
`Permission denied (publickey)` — even though the user can normally push
from their regular terminal.

**Cause:** The user's normal terminal session has ssh-agent context or
Windows Credential Manager set up. A cmd.exe spawned via `Start-Process` with
`-NoNewWindow` inherits a stripped environment without those.

**Fix:** Switch the remote to **HTTPS** and rely on Git Credential Manager
(`manager-core`). Git for Windows bundles GCM and Bruno's GitHub OAuth token
is cached in Windows Credential Manager. HTTPS clone and push work without
any extra configuration once you use the `https://` URL.

```
# Use this URL form for clone/push, not the git@ form
https://github.com/brunobozic/thinkingmachine-site.git
```

**Side note:** The `~/.ssh/` directory does contain four keys (`id_ed25519`,
`id_rsa`, `id_multipass`, `id_theknowlogy`) but **none of them are registered
as a GitHub authentication key** on this machine. Don't waste time iterating
through them.

## 5. PowerShell `& 'C:\Path With Spaces\bin\foo.exe'` silently no-ops

**Symptom:** Running `& 'C:\Program Files\Git\cmd\git.exe' status` from
PowerShell `-File` script produces empty output and `$LASTEXITCODE` is `$null`.
The script keeps running but git was never invoked.

**Cause:** When PowerShell is launched non-interactively via Desktop Commander's
`start_process`, the call operator `&` against a quoted path containing spaces
does not spawn the child process correctly. The exact reason isn't clear; might
be a STA/MTA boundary, might be a sub-shell PATH issue.

**Fix:** Use the 8.3 short path for `Program Files` (`C:\PROGRA~1\Git\cmd\git.exe`)
**and** invoke through `Start-Process -FilePath cmd.exe -ArgumentList '/c …'`
with output redirected to a file via `> outfile 2>&1`. Don't try to capture
stdout via PowerShell variable assignment — write to a file and read it back.

Even simpler: skip PowerShell entirely and use `.bat` files. cmd.exe handles
spawning external processes correctly. The pattern that works:

```bat
@echo off
set PATH=%SystemRoot%\System32;%SystemRoot%;%PATH%
set GIT=C:\PROGRA~1\Git\cmd\git.exe
%GIT% status > C:\path\to\out.log 2>&1
```

## 6. Desktop Commander spawned cmd.exe has empty PATH

**Symptom:** Inside a `.bat` file invoked via Desktop Commander, even
`where`, `findstr`, and `cmdkey` fail with "not recognized as an internal or
external command".

**Cause:** The spawned cmd.exe inherits an empty/minimal PATH. System32 isn't
on it.

**Fix:** Set PATH explicitly at the top of every `.bat`:
```bat
set PATH=%SystemRoot%\System32;%SystemRoot%;%PATH%
```

## 7. Astro content collections schema must match frontmatter exactly

**Symptom:** A frontmatter field set in `*.md` files isn't visible at
`study.data.<field>` in the renderer — silently `undefined`.

**Cause:** Zod's default `.object()` strips unknown fields. If a field isn't
declared in `src/content/config.ts`, Astro discards it on load.

**Fix:** Every frontmatter field used in renderers must be declared. The
current schema covers `title`, `sector`, `engagementType`, `year`, `region`,
`summary`, `quickRead` (optional), `publishedAt` (optional), `featured`,
`draft`. Adding a new field means updating `config.ts` first, then the
renderer.

## 8. Astro Markdown rendering inside JSX expressions

**Symptom:** In an Astro component, when you render `study.data.quickRead`
content inside a `<div class="prose" set:html={...}>` expression, `**bold**`
and `*italic*` Markdown render as literal asterisks.

**Cause:** `study.data.quickRead` is a raw string from the frontmatter. It
doesn't go through Astro's Markdown processor (which only handles the body
of `.md` files). When you `set:html` the raw string, you're injecting raw
text into HTML.

**Fix:** The renderer wraps each paragraph with an inline regex Markdown
processor:
```ts
study.data.quickRead.split('\n\n').map((para) => {
  const html = para.trim()
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/\*\*([^\n]+?)\*\*/g, '<strong>$1</strong>')
    .replace(/(^|[^*])\*([^*\n]+)\*/g, '$1<em>$2</em>');
  return `<p>${html}</p>`;
}).join('')
```

**Gotcha within the gotcha:** The bold regex must be **non-greedy** (`+?`)
and accept `*` inside (`[^\n]+?` not `[^*]+?`). Otherwise nested italic
`**bold *italic* bold**` breaks because `[^*]+` excludes `*` from the
bold content. We hit this exact bug and fixed it in commit `ba2d1d9`.

## 9. `build.format: 'file'` requires matching nginx config

**Symptom:** Trailing-slash URLs (`/services/`) 404 or redirect to plain HTTP
under TLS.

**Cause:** `build.format: 'file'` writes `/services.html` not `/services/index.html`.
A request for `/services/` doesn't match `/services.html`. Stock nginx's
default-redirect-to-add-trailing-slash logic then fires, but because nginx
sits behind Traefik (which terminates TLS), nginx sees plain HTTP and the
redirect goes to `http://thinkingmachine.uk/services/` — TLS downgraded.

**Fix:** `nginx.conf` has two specific directives:
- `absolute_redirect off; port_in_redirect off;` — protocol-relative redirects
- `location ~ ^(?<noslash>.+)/$ { return 301 $noslash; }` — strip trailing slash
- `location / { try_files $uri $uri.html $uri/index.html =404; }` — try .html

Combined with `trailingSlash: 'never'` and `build.format: 'file'` in Astro
and the sitemap, canonical/served URLs all agree. Don't change one without
checking all three.

## 10. hreflang must only point to URLs that exist

**Symptom:** Google Search Console flags hreflang errors. AI search downgrades
the result.

**Cause:** Astro doesn't validate that translated paths exist. If `/about` is
in EN but `/de/about` is missing, emitting `<link rel="alternate" hreflang="de"
href="…/de/about">` is harmful.

**Fix:** `src/i18n/paths.ts` exports a `TRANSLATED_PATHS` registry. `BaseLayout`
only emits hreflang alternates when the current path is in the registry.
When adding a translation, add the path to the registry.

## 11. JSON-LD `inLanguage` was hardcoded `'en'` (now fixed)

**Symptom:** Google quality flag on DE/HR pages — Schema.org `inLanguage`
disagrees with HTML `lang`.

**Cause:** Original `BaseLayout.astro` had `inLanguage: 'en'` hardcoded in
both the `WebSite` and `WebPage` JSON-LD nodes, regardless of the served
locale.

**Fix (already shipped):** Both nodes now use `inLanguage: localeMeta.lang`.
If you write new JSON-LD blocks, always reference `localeMeta.lang`, never
hardcode `'en'`.

## 12. Astro is NOT a JS runtime for ContentScripts

When you see `<script>…</script>` in an Astro component, that's a build-time
declaration that ships to the browser. For dynamic JSON-LD that depends on
page data, emit `<script type="application/ld+json" set:html={JSON.stringify(obj)} />`.
Don't try to construct it at runtime with browser DOM APIs.

## 13. The mailto: contact CTA is a temporary stopgap

`src/pages/contact.astro` contains a Cal.com embed scaffold that activates
when `CAL_BOOKING_PATH` is set to a non-empty string. When activating, also
update the Traefik CSP in `infra/traefik/dynamic.yml` to allow `app.cal.com`
in `script-src`, `frame-src`, `connect-src`, and `img-src`. Instructions are
inline in the file.

## 14. Brand voice — "we" is a stylistic choice, not deception

The site is one-principal but writes as "we". This is the boutique-advisory
tradition (think Bain's early days, McKinsey's writing style guide). The
About page is the resolution point — it makes clear that the practice is one
principal plus a small set of named partners under sub-NDA when scope warrants.
If an agent rewrites this to "I", check with Bruno first.

## 15. Self-hosted fonts — don't accidentally re-add Google Fonts

`global.css` imports `@fontsource/inter/{400,500,600}.css` and
`@fontsource-variable/source-serif-4`. The Traefik CSP no longer allows
`fonts.googleapis.com` or `fonts.gstatic.com`. If a future agent re-adds a
Google Fonts CDN link in `BaseLayout`, the fonts will fail to load under
the strict CSP. Either way, doing so breaks the "No trackers" footer claim.

## 16. astro-og-canvas build dependency

Per-page OG images use `astro-og-canvas` + `canvaskit-wasm`. First `npm install`
on a fresh checkout downloads the canvaskit WASM blob (~7 MB) into the
node_modules cache. If CI build fails specifically at the canvaskit stage,
the fix is to pin `canvaskit-wasm` to a stable major version or, in the
extreme case, remove the `ogImage={…}` props from the four renderers and
let pages fall back to the default `/og-image.png`.

## 17. Don't commit files generated by the build

The `dist/` folder is gitignored. Sometimes agents forget and `git add .`
sweeps it in. Check the index before commit:
```
git status --short | findstr dist/
```

## 18. Word counts on Quick reads

The five case studies' `quickRead` fields target **200–280 words**. Anything
over 300 words feels long in the rendered card; anything under 180 doesn't
hook. The current set is 196–267 words across EN/DE/HR. If you rewrite a
Quick read, sanity-check word count before committing.

## 19. Anonymisation regex audit before any commit touching content

Before committing a content change, search the local working tree for the
forbidden terms list:
```
git -c core.longpaths=true grep -i -E "(Opennovations|Therapeer|MedCall|Alem|Vrdoljak|DACH|LiveKit|DeepFilterNet|Aker BP|Zeek|BMWK|STRABAG|SimonsVoss|ParkEfficient|Valhall|Yggdrasil|DROPS|psychotherapy)"
```
A clean run = `0` matches. If anything fires, fix it before push.

## 20. CI/CD pipeline summary (full detail in `infra/CI-CD.md`)

- Push to `main` triggers `.github/workflows/deploy.yml`
- GitHub Actions builds the Astro static site
- Wraps it in nginx-alpine via `Dockerfile`
- Pushes the image to GitHub Container Registry (GHCR)
- SSHs to the Hetzner VPS using a deploy key
- VPS pulls the new image and restarts the `thinkingmachine-site` container
- Traefik (always running) picks up the restarted container and routes
  traffic through it without dropping connections

Total elapsed: usually 90–120 seconds from `git push` to live.
