# AGENTS.md — Operating rules for AI agents working on this repo

This file is **mandatory reading before any non-trivial change**. Most of it is
hard-won knowledge — every gotcha here cost real time the first time we hit it.

## TL;DR for "I just want to deploy a fix" — the fast path

**The auto-deploy loop is wired and working as of 2026-05-15.** Just push to
`main` and the site updates ~90s later. No manual SSH needed.

The site runs on Hetzner VPS **tm-prod-fsn1** at **178.105.104.173** (CX23,
Falkenstein, project 12580250). Deploy flow:

1. **Edit files locally**, work in `C:\tm-fresh` (a fresh clone — DO NOT work
   in the cowork session path; see §1).
2. **Commit + push** via the `.bat` scripts pattern (see §5). HTTPS clone +
   Git Credential Manager handle GitHub auth.
3. **CI builds** the image and pushes to `ghcr.io/brunobozic/thinkingmachine-site`
   (~60s).
4. **CI's `notify-vps` job** POSTs to
   `https://thinkingmachine.uk/_webhook/hooks/redeploy` with `Authorization: Bearer $WEBHOOK_TOKEN`.
5. **Webhook receiver** on the VPS (systemd unit `tm-webhook`) validates the
   bearer token, runs `/usr/local/bin/tm-redeploy.sh` which does
   `docker compose pull && up -d`.
6. **Traefik** swaps the container with zero downtime (~5s).
7. Total: **~90 seconds from `git push` to live**.

If you ever need to deploy manually, the SSH alias is `tm-prod`:
```
ssh tm-prod 'cd /srv/thinkingmachine-site && docker compose pull && docker compose up -d'
```
The key is at `~/.ssh/hetzner_tm` with the alias in `~/.ssh/config`. Both are
installed and verified working.

## TL;DR for "verify the site is alive"

Run `bash infra/verify-all-pages.sh` (committed to the repo) — it checks every
URL in the sitemap and every locale, asserts HTTP 200, and verifies content
markers. Last full pass: 2026-05-15, **41 pages all green**.

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
- GitHub Actions builds the Astro static site inside the Dockerfile multi-stage
  build (npm install + astro build + nginx-alpine wrap)
- Pushes the image to GitHub Container Registry (GHCR) tagged both `:latest`
  and `:<short-sha>`
- `notify-vps` job POSTs to `https://hooks.thinkingmachine.uk/hooks/redeploy`
  with a bearer token — the webhook receiver pulls the new image and rolls
  the site container
- Traefik (always running) picks up the restarted container with zero downtime

If the webhook isn't wired (§22), the workflow degrades gracefully — CI still
builds and pushes the image, but the site doesn't update until someone SSHes
in and runs `docker compose pull && up -d`.

## 21. **CI builds; CI does NOT deploy by default** ← single biggest historical confusion

**Symptom:** You push a change, the workflow shows green, but
`https://thinkingmachine.uk/` still serves the previous build.

**Cause:** The original workflow only had a `build-and-push` job — no SSH step,
no webhook, no auto-pull. The `notify-vps` job sat commented out from day one
with the note *"Comment out until WEBHOOK_URL is configured in repo Secrets."*
So "CI green" meant only "image is on GHCR," not "site is live."

**Fix shipped (commit `1a1cb0b` and on):** `infra/webhook/` plus the now-active
`notify-vps` job in the workflow. After one-time VPS setup (§22), every push
to `main` auto-deploys. Until the one-time setup is done on the VPS, the
workflow tolerates the missing secret and exits 0 with a warning — but the
site still doesn't update without a manual pull.

**Past Bruno spent multiple hours assuming the workflow was deploying.** Save
yourself the time: when you push, also check the live site for the change.
The fast check is `curl -sI https://thinkingmachine.uk/ | grep -i security-policy`
— compare the CSP against your local infra/traefik/dynamic.yml. If they
diverge, the deploy didn't happen.

## 22. The webhook one-time VPS setup (mandatory for true auto-deploy)

Full instructions: `infra/webhook/README.md`. Five steps, ~5 minutes:

1. Generate token: `openssl rand -hex 32`
2. Store on VPS: `echo WEBHOOK_TOKEN=<token> | sudo tee /etc/thinkingmachine/webhook.env`
3. GitHub repo → Settings → Secrets → Actions:
   - `WEBHOOK_URL = https://hooks.thinkingmachine.uk/hooks/redeploy`
   - `WEBHOOK_TOKEN = <same token>`
4. Cloudflare DNS: add `hooks.thinkingmachine.uk` A record → VPS public IP
5. `cd infra/webhook && docker compose up -d` on the VPS

Verify with `curl -i -X POST -H "Authorization: Bearer <token>" https://hooks.thinkingmachine.uk/hooks/redeploy`
— expect 200 + "redeploy triggered" + the site container rolls.

## 23. The VPS — coordinates an agent always needs

| Field | Value |
|---|---|
| Provider | Hetzner Cloud |
| Server name | `tm-prod-fsn1` |
| Server ID | `130167718` |
| Public IPv4 | `178.105.104.173` |
| IPv6 | `2a01:4f8:c014:1fad::/64` |
| Type | CX23 (2 vCPU, 4 GB RAM, 40 GB SSD) |
| Location | Falkenstein (eu-central) |
| Hetzner Project ID | `12580250` |
| Project console URL | `https://console.hetzner.com/projects/12580250/servers/130167718/overview` |

To find this again: <https://console.hetzner.com/projects/12580250/servers/130167718/overview>.

**The public IPv4 is the actual origin.** It's NOT Cloudflare-proxied — earlier
confusion was because `curl --resolve thinkingmachine.uk:443:1.1.1.1` was used
during diagnostics, which forces the request to Cloudflare's resolver, not the
site. A plain `curl thinkingmachine.uk` hits the Hetzner box directly.

## 24. SSH key for the VPS — NOT in `~/.ssh/`

The four keys in `C:\Users\BrunoBozic\.ssh\` (`id_ed25519`, `id_rsa`,
`id_multipass`, `id_theknowlogy`) **do not auth to the VPS**. Don't waste time
iterating through them again — the probe is recorded in `vps.log` from
2026-05-15 and all four returned `Permission denied (publickey)`.

The Hetzner SSH key store lists a key called `claude-cowork-deploy`. The
matching private key lives wherever you keep your real deploy keys (likely in
a project folder, WSL, or a password manager — not in `~/.ssh/`). When you
find it, **drop a symlink at `~/.ssh/id_tm_prod` and add this to
`~/.ssh/config`:**
```
Host tm-prod-fsn1
  HostName 178.105.104.173
  User root
  IdentityFile ~/.ssh/id_tm_prod
  IdentitiesOnly yes
```
Then `ssh tm-prod-fsn1 'cd /opt/thinkingmachine-site && docker compose pull && docker compose up -d'`
is the deploy one-liner.

## 25. SSH-from-cmd-spawned-process loses your ssh-agent context

**Symptom:** You can SSH to GitHub fine from your normal terminal, but
`Start-Process cmd /c 'ssh github.com'` from a non-interactive parent fails
with `Permission denied (publickey)`.

**Cause:** Non-interactive child shells inherit a stripped environment.
ssh-agent socket isn't reachable. Git for Windows' bundled `ssh.exe` only
sees the keys you pass via `-i` and uses `IdentitiesOnly=yes` semantics
under `BatchMode`.

**Fix:** For Git operations, use **HTTPS remotes + Git Credential Manager**
(see §4). The user's GitHub PAT is cached in Windows Credential Manager and
GCM presents it on demand — no SSH agent needed.
For VPS SSH, use the explicit `IdentityFile` in `~/.ssh/config` (see §24).

## 26. PowerShell `& 'C:\Program Files\...'` silently swallows output

**Symptom:** Your script runs, exits 0, but produces no output. Variables
that should hold stdout from a child process are empty.

**Cause:** When PowerShell is launched non-interactively (via Desktop Commander
`start_process`), the call operator `&` against a quoted path containing
spaces fails to spawn the child process correctly — but doesn't error. The
parent script continues with empty/null variables.

**Fix:** Use the 8.3 short-name (`C:\PROGRA~1\Git\cmd\git.exe`) **and** invoke
via `Start-Process -FilePath cmd.exe -ArgumentList '/c …'` with output
redirected to a file (`> outfile 2>&1`). Capture via PowerShell variables is
unreliable in this context.

**Even better:** skip PowerShell, write `.bat` files. cmd.exe spawns processes
correctly. Template:
```bat
@echo off
set PATH=%SystemRoot%\System32;%SystemRoot%;%PATH%
set GIT=C:\PROGRA~1\Git\cmd\git.exe
%GIT% status > C:\path\to\out.log 2>&1
```

## 27. Desktop Commander spawned cmd.exe has empty PATH

**Symptom:** `where`, `findstr`, `cmdkey`, even `curl` fail with "not
recognized as an internal or external command".

**Cause:** The spawned shell inherits a minimal environment. System32 isn't
on PATH.

**Fix:** Set PATH at the top of every `.bat`:
```
set PATH=%SystemRoot%\System32;%SystemRoot%;%PATH%
```
Also keep absolute paths to common tools (`C:\Windows\System32\curl.exe`,
`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`) handy.

## 28. The Cloudflare-doesn't-actually-proxy nuance

The site DNS resolves to `178.105.104.173` directly. There's no Cloudflare
proxy in front despite Cloudflare being the DNS host (the orange-cloud is
disabled or absent for the apex `A` record). That means:

- HTTPS / TLS termination happens at Traefik on the VPS (not at Cloudflare's
  edge)
- `Let's Encrypt` issues the cert directly to the VPS via TLS-ALPN-01
- Direct IP `curl https://thinkingmachine.uk/` hits the VPS, not a Cloudflare
  PoP

If you ever flip the orange-cloud on (for DDoS / WAF), be aware:
- Origin IP gets hidden — clients can't reach the VPS directly, so the webhook
  receiver path changes
- The CAA records still pin to letsencrypt.org so cert issuance still works
- Origin certs must come from Cloudflare (not Let's Encrypt) for end-to-end
  HTTPS — or accept that Cloudflare→origin is unencrypted (don't)

## 29. astro-og-canvas's `logo` key trap

**Symptom:** Astro build fails at the OG image endpoint:
```
The "path" argument must be of type string or an instance of Buffer or URL. Received undefined
  at open (node:internal/fs/promises:634:10)
  at file:///app/dist/pages/og/_---route_.png.astro.mjs:247:33
```

**Cause:** Passing `logo: { /* commented-out path */ }` to `getImageOptions`.
The library treats `logo` as present-and-malformed and calls `fs.open(undefined)`.

**Fix:** Omit the entire `logo` key. To add a logo later: add a 200×200 PNG
at `public/og-logo.png` and add:
```ts
logo: { path: './public/og-logo.png', size: [120, 120] }
```
(don't comment-in keys — the empty-object form is the trap).

## 30. The repo-state-across-sessions chaos

**Symptom:** Local working tree in the cowork outputs path drifts wildly from
origin/main. Files appear modified locally that you never touched.
`git status` shows 30+ stale "M" entries.

**Cause:** Previous Claude sessions wrote files to disk via Edit/Write but
never committed. Origin/main moved forward via OTHER Claude sessions (or
your direct pushes). The local working tree never reconciles.

**Fix:** Don't work in the cowork outputs path for any non-trivial change.
Clone fresh to a short path:
```
cd C:\
git clone https://github.com/brunobozic/thinkingmachine-site.git tm-fresh
```
Work, commit, push from `C:\tm-fresh`. The cowork outputs path is fine for
reading + scratch; treat it as ephemeral.

## 31. Hetzner web console (noVNC) opens in a popup outside the MCP tab group

**Symptom:** You click Console → ">_" in Hetzner Cloud UI, a popup opens with
the noVNC terminal, but the Claude-in-Chrome MCP doesn't see it
(`tabs_context_mcp` shows only the original tab).

**Cause:** Hetzner opens the console as a `window.open` in a new browser
window, which doesn't get included in the MCP's session tab group.

**Workaround:** For commands you want me to run, prefer:
1. SSH from Desktop Commander (need the key — see §24), or
2. Wire the webhook (§22) and never need the console again, or
3. Ask the user to type into the noVNC popup themselves

The noVNC popup IS interactive — Bruno can paste commands into it directly.
But I can't drive it through the Chrome MCP.

## 32. Cowork session ".git" is on a permission-denied mount

**Symptom:** From the `mcp__workspace__bash` sandbox shell, even
`rm .git/index.lock` returns `Operation not permitted`. Git commands fail
because the lock can't be removed.

**Cause:** The sandbox mount that exposes the outputs path blocks `unlink`
syscalls on the `.git/` subtree as a security policy. The bash shell's user
owns the files but the kernel still refuses the syscall.

**Fix:** Don't run git from inside the sandbox. Use Desktop Commander
(`mcp__Desktop_Commander__start_process`) which runs natively on the Windows
host and has full filesystem access. The sandbox is fine for reading file
content via `git show origin/main:path` (uses pack objects, not the index).

## 33. The Cowork outputs working-copy filesystem differs from the Windows view

**Symptom:** You read a file via the `Read` tool successfully, then try to
read the same path via `mcp__workspace__bash` and get "no such file."

**Cause:** Two distinct mount points:
- Windows path `C:\Users\BrunoBozic\AppData\Roaming\Claude\local-agent-mode-sessions\<uuid>\<uuid>\<uuid>\outputs\` is what `Read`/`Write`/`Edit` see
- Linux path `/sessions/<name>/mnt/outputs/` is what `mcp__workspace__bash` sees
- They map to the same files but the Linux mount blocks writes to `.git/`

In practice: file content tools (Read/Write/Edit) work on the Windows path
and are reliable. Use them for all content edits. The bash shell is fine
for read-only inspection and curl/grep tasks against external sources.

Total elapsed: usually 90–120 seconds from `git push` to live.
