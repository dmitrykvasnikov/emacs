# External software required by this config

Everything **outside Emacs** that this configuration expects to find on the
system. Emacs packages are not listed: `use-package` has
`use-package-always-ensure t` (`src/dk-packages.el:38`), so the ~35 ELPA/MELPA
packages install themselves on first launch.

Every entry names the file and line that needs it, so anything belonging to a
language you don't use can be dropped.

Package names are for **Arch Linux**; other distros are noted where the name
differs. Verified against Emacs 30.2.

`.gitignore` excludes `elpa/`, `tree-sitter/`, `eln-cache/` and `custom.el` —
a fresh clone rebuilds all four, see [§9](#9-post-install-inside-emacs).

---

## 0. TL;DR — clean Arch install

```bash
# Emacs + core tooling
sudo pacman -S --needed emacs git base-devel gnupg ripgrep fd pandoc-cli

# LSP servers, compilers, formatters
sudo pacman -S --needed clang go gopls rustup

# Rust toolchain
rustup default stable
rustup component add rustfmt clippy rust-analyzer

# Haskell — ghcup, not pacman (keeps GHC/HLS/fourmolu in sync)
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
ghcup install ghc      --set latest
ghcup install cabal    --set latest
ghcup install hls      --set latest
cabal install fourmolu
# add ~/.ghcup/bin and ~/.cabal/bin to PATH

# Optional formatters for the non-code file types (see §6)
sudo pacman -S --needed taplo-cli prettier shfmt

# Fonts
sudo pacman -S --needed ttf-nerd-fonts-symbols
yay -S ttf-iosevka             # AUR only (or paru -S ttf-iosevka)

# Org directory referenced by org-agenda-files
mkdir -p ~/org
```

Then launch Emacs and run the steps in [§9](#9-post-install-inside-emacs)
(tree-sitter grammars — those are compiled locally, not packaged).

---

## 1. Emacs itself

**Emacs 30.1 or newer is required.** The config uses `setopt` (29+), built-in
`use-package` (29+), `treesit` (29+), built-in `which-key`
(`src/dk-ui.el:67`, 30+), `major-mode-remap-alist` (`src/dk-treesit.el:87`,
30+), `eglot-events-buffer-config` (`src/dk-programming.el:49`, 30+) and
`completion-pcm-leading-wildcard` (`src/dk-completion.el:64`, 30+).

| Build feature | Configure flag | Needed by |
|---|---|---|
| tree-sitter | `--with-tree-sitter` | the whole of `src/dk-treesit.el`; every `*-ts-mode` |
| dynamic modules | `--with-modules` | loading the compiled grammar `.so` files |
| native compilation | `--with-native-compilation` | `eln-cache/`, startup speed (`early-init.el:43`) |
| GUI build (X11/pgtk) | default | fonts (`src/dk-ui.el:43`), fringe bitmaps (`src/dk-programming.el:93`), corfu's child-frame popup |
| HarfBuzz | `--with-harfbuzz` | the shaping that turns the composition rules in `src/dk-ui.el:71` into ligature glyphs |

Arch's `extra/emacs` ships all five. A terminal-only build still mostly works
— `diff-hl` falls back to the margin — but corfu's popup needs a child frame,
and the font settings and fringe indicators are inert there. Ligatures are
inert there too, for a different reason: in `emacs -nw` the glyphs are the
terminal emulator's to draw, whatever this config asks for.

To confirm the build has what the ligatures need:

```elisp
(and (display-graphic-p) (string-match-p "HARFBUZZ" system-configuration-features))
```

`emacsclient` ships with Emacs and is required by `with-editor`, which magit
uses for commit messages.

Non-Arch: Debian/Ubuntu ship Emacs 29 or older on LTS releases — check
`emacs --version` before assuming the distro package is enough.

---

## 2. Core tooling

Needed no matter which languages you use.

| Binary | Arch package | Needed by |
|---|---|---|
| `git` | `git` | magit (`src/dk-vcs.el:5`), diff-hl (`src/dk-vcs.el:23`), `project-try-vc` root detection (`src/dk-navigation.el:51`), `vc-follow-symlinks` (`src/dk-defaults.el:24`), and cloning every tree-sitter grammar repo (`src/dk-treesit.el:22`) |
| `gcc`, `g++`, `make` | `base-devel` | compiling tree-sitter grammars (§8) — the C++ compiler is needed for grammars whose external scanner is C++. Also libgccjit for native-comp. |
| `rg` | `ripgrep` | `consult-ripgrep`, bound to `C-x p g` / `C-c p g` and offered in `project-switch-commands` (`src/dk-navigation.el:68,74`) |
| `find`, `grep` | `findutils`, `grep` | `consult-find` on `C-c C-f` (`src/dk-completion.el:80`); `consult-grep` via `M-x`. Both in Arch `core`. |
| `pandoc` | `pandoc-cli` | `markdown-command` (`src/dk-writing.el:17`) — `markdown-preview` / `markdown-export`. Arch's package is `pandoc-cli`, **not** `pandoc` (that is the Haskell library). |
| `gpg` | `gnupg` | verifying signed ELPA packages on first install. Optional but recommended. |
| GNU `ls` | `coreutils` | `dired-listing-switches` uses `--group-directories-first` (`src/dk-navigation.el:24`), a GNU extension. Present on any Linux; only an issue on BSD/macOS. |

**Optional:** `fd` — nothing in the config binds `consult-fd`, but it is much
faster than `find` if you reach for it via `M-x`.

---

## 3. LSP servers

`eglot-ensure` runs in these modes (`src/dk-programming.el:37-42`,
`src/dk-languages.el:105`). A missing server means no completion or
diagnostics for that language; nothing else breaks.

| Binary | Arch package | Trigger | Configured with |
|---|---|---|---|
| `clangd` | `clang` | `c-ts-mode`, `c++-ts-mode` | `--clang-tidy`, `-std=c23` (`src/dk-languages.el:26`) |
| `rust-analyzer` | `rust-analyzer`, or `rustup component add rust-analyzer` | `rustic-mode` | `:check (:command "clippy")` — needs `cargo-clippy`, see §7 (`src/dk-languages.el:21`) |
| `gopls` | `gopls` | `go-ts-mode` | stock (`src/dk-programming.el:42`) |
| `haskell-language-server-wrapper` | **ghcup**, see §7 | `haskell-mode` and `haskell-ts-mode` | `--lsp` (`src/dk-languages.el:18`) |

The Haskell entry must be the `-wrapper` binary — it dispatches to the HLS
build matching each project's GHC. Do not install a bare
`haskell-language-server`.

Non-Arch: clangd is `clangd` on Debian/Ubuntu and `clang-tools-extra` on
Fedora. If `gopls` isn't packaged, `go install golang.org/x/tools/gopls@latest`.

---

## 4. Formatters — required

`apheleia-global-mode` is on (`src/dk-programming.el:107`) and is the **only**
formatter in the config: the per-language `before-save-hook` formatters and
`rustic-format-on-save` were all removed. apheleia picks the tool from its own
`apheleia-mode-alist`, so these are the ones the languages here resolve to.

| Binary | Arch package | Formats | Note |
|---|---|---|---|
| `rustfmt` | `rustup component add rustfmt` | `rustic-mode`, `rust-mode`, `rust-ts-mode` | |
| `gofmt` | `go` | `go-ts-mode` | ships inside the `go` package |
| `clang-format` | `clang` | `c-ts-mode`, `c++-ts-mode` | only runs in trees that contain a `.clang-format` file — `dk/no-clang-format-p` (`src/dk-functions.el:102`) inhibits it everywhere else |
| `fourmolu` | `cabal install fourmolu` (or `ghcup`, or AUR `fourmolu-bin`) | `haskell-mode`, `haskell-ts-mode` | apheleia's Haskell default is fourmolu, **not** ormolu |

The `clang-format` package also provides the `clang-format` Emacs commands
(`src/dk-languages.el:142`), which call the same binary.

---

## 5. Language toolchains

Install only what you use.

### Rust
| Binary | Source | Needed by |
|---|---|---|
| `cargo` | `rustup` | rustic drives every build/test/run through cargo (`src/dk-languages.el:103`) |
| `rustfmt` | `rustup component add rustfmt` | apheleia, §4 |
| `cargo-clippy` | `rustup component add clippy` | the `:check (:command "clippy")` option handed to rust-analyzer |

`rustup` and the distro `rust` package conflict — pick one. `rustup` keeps
rustfmt/clippy/rust-analyzer versions matched to the toolchain.

### Go
| Binary | Arch package | Needed by |
|---|---|---|
| `go`, `gofmt` | `go` | building; `gofmt` is apheleia's Go formatter |
| `gopls` | `gopls` | eglot, §3 |

### C / C++
| Binary | Arch package | Needed by |
|---|---|---|
| `clangd`, `clang-format` | `clang` | §3, §4 |
| `gcc`, `g++` | `base-devel` | compiling; also grammar builds |

### Haskell
| Binary | Source | Needed by |
|---|---|---|
| `ghc` | ghcup | compiler; HLS must match its version |
| `cabal` | ghcup | `haskell-process-type` is `'cabal-repl` (`src/dk-languages.el:48`) — `C-c C-z` and `C-c C-l` both go through `cabal repl` |
| `haskell-language-server-wrapper` | `ghcup install hls` | eglot, §3 |
| `fourmolu` | `cabal install fourmolu` | apheleia, §4 |

Use **ghcup**, not pacman: HLS is built against an exact GHC version and Arch's
`ghc` regularly drifts ahead of what HLS supports. Put `~/.ghcup/bin` and
`~/.cabal/bin` on `PATH`.

Note `haskell-ts-mode` (`src/dk-languages.el:50`) drives a bare `ghci` via
`run-haskell`, while `haskell-mode` uses `cabal repl` — both come from ghcup.

---

## 6. Formatters — optional

`src/dk-treesit.el:103` maps a set of extra file types onto built-in ts modes,
and apheleia has a default formatter for most of them. Without the binary,
saving such a file logs an apheleia error and leaves the buffer untouched —
harmless, but noisy. Install the ones you care about, or drop the entry from
`apheleia-mode-alist`.

| File type | Mode | Formatter | Arch package |
|---|---|---|---|
| TOML (`Cargo.toml`, …) | `toml-ts-mode` | `taplo` | `taplo-cli` |
| YAML | `yaml-ts-mode` | `prettier` | `prettier` (needs `nodejs`) |
| JSON | `json-ts-mode` | `prettier` | `prettier` |
| shell scripts | `bash-ts-mode` | `shfmt` | `shfmt` |
| `CMakeLists.txt`, `*.cmake` | `cmake-ts-mode` | `cmake-format` | AUR `cmake-format`, or `pipx install cmakelang` |
| `Dockerfile`, `Containerfile` | `dockerfile-ts-mode` | `dprint` | AUR `dprint`, or `cargo install dprint` |

Emacs Lisp is formatted by apheleia's built-in `lisp-indent` — no external
binary.

Markdown is deliberately absent from `apheleia-mode-alist` upstream, so `.md`
files are never reformatted on save.

---

## 7. Fonts

| Font | Arch package | Needed by |
|---|---|---|
| **Iosevka** | `ttf-iosevka` — **AUR only** (`yay`/`paru`) | hard-coded as the `default` and `minibuffer-prompt` family (`src/dk-vars.el:16`, applied in `src/dk-ui.el:43`), and it is the family whose `calt`/`liga` features the ligature setup below composes. Missing → silent fallback to some other monospace font, no warning, and no ligatures. |
| **Symbols Nerd Font Mono** | `ttf-nerd-fonts-symbols` | `nerd-icons`, the single icon backend here: doom-modeline (`src/dk-ui.el:96`), `nerd-icons-dired` (`src/dk-navigation.el:40`), `nerd-icons-corfu` (`src/dk-completion.el:182`). Missing → tofu boxes everywhere. |

Not on Arch: upstream Iosevka releases are at `github.com/be5invis/Iosevka` —
unzip into `~/.local/share/fonts/` and run `fc-cache -f`. For the Nerd Font,
`M-x nerd-icons-install-fonts` downloads and installs it from inside Emacs.

To use a different font instead, edit `dk/font-family` in `src/dk-vars.el` —
it is referenced from one place only. One constraint on the replacement: the
`ligature` package (`src/dk-ui.el:71`) installs composition rules, but the
glyphs come from the font's own OpenType features, so a family built without
`calt`/`liga` silently gets no ligatures. That is exactly why **Aporetic Sans
Mono**, the previous value here, was dropped: its monospaced cuts ship
`cv01`–`cv99` and `ss01`–`ss20` but no ligature features at all. To check a
candidate before switching:

```bash
python3 - <<'EOF'
import struct
p = '/usr/share/fonts/TTF/Iosevka-Regular.ttf'   # path to the font file
d = open(p, 'rb').read()
tabs = {d[12+16*i:16+16*i].decode('latin1'): struct.unpack('>II', d[20+16*i:28+16*i])
        for i in range(struct.unpack('>H', d[4:6])[0])}
o = tabs['GSUB'][0]
flo = o + struct.unpack('>H', d[o+6:o+8])[0]
n = struct.unpack('>H', d[flo:flo+2])[0]
feats = {d[flo+2+6*i:flo+6+6*i].decode('latin1') for i in range(n)}
print(sorted(feats & {'liga', 'calt', 'clig', 'dlig'}) or 'no ligature features')
EOF
```

---

## 8. Tree-sitter grammars

`tree-sitter/` is git-ignored, so **a fresh clone has no grammars**. They are
cloned and compiled locally at pinned revisions
(`src/dk-treesit.el:22`) — Arch's packaged grammars are deliberately not used
(it only ships a few, and they track an ABI this Emacs cannot load).

Twelve grammars: `bash` `c` `cmake` `cpp` `dockerfile` `go` `gomod` `haskell`
`json` `rust` `toml` `yaml`.

Build requirements: `git`, `gcc`, `g++`, `make` — all from `base-devel`.
Network access to github.com.

You do **not** need to do this by hand: `dk/treesit-ensure`
(`src/dk-treesit.el:45`) is advised onto `treesit-ready-p`, so the first buffer
that wants a grammar builds it, once per session. `M-x dk/treesit-install-all`
does the whole set up front.

---

## 9. Post-install inside Emacs

1. **First launch downloads ~35 ELPA/MELPA packages** (plus dependencies).
   Needs working network and TLS. Expect a slow first start; after that
   `package-quickstart` (`early-init.el:49`) keeps startup around half a second.

2. **Tree-sitter grammars** — `M-x dk/treesit-install-all`
   (`C-u` prefix rebuilds ones already present).

3. **Nerd Font**, if the distro package wasn't used —
   `M-x nerd-icons-install-fonts`.

4. **Create the org directory** — `org-agenda-files` is `(list "~/org")`
   (`src/dk-vars.el:28`); `org-agenda` errors if it does not exist:
   ```bash
   mkdir -p ~/org
   ```

5. **Optional:** `M-x dk/recompile-config` byte-compiles `src/`
   (`src/dk-functions.el:76`). Not required — `load-prefer-newer` is `t`, so a
   stale `.elc` is ignored rather than loaded.

---

## 10. What you do *not* need

Listed so as not to over-install.

| Tool | Why not |
|---|---|
| `stack` | `haskell-process-type` is `'cabal-repl` (`src/dk-languages.el:48`) |
| `ormolu` | apheleia's Haskell formatter is **fourmolu** |
| `goimports` | apheleia uses plain `gofmt` for Go |
| `multimarkdown` | `markdown-command` is pandoc (`src/dk-writing.el:17`) |
| `tree-sitter` CLI | `treesit` loads compiled `.so` files directly; the Rust CLI is for grammar authors |
| `trash-cli` | `delete-by-moving-to-trash` (`src/dk-defaults.el:29`) uses Emacs' own freedesktop trash implementation |
| `libvterm` | no terminal emulator package in this config |
| `git-delta`, `difftastic` | magit needs nothing beyond `git` |
| `sqlite`, `graphviz`, LaTeX | no org-roam, no org-babel graphing, no LaTeX export configured |
| `aspell` / `hunspell` | no spellchecker configured. Worth adding for the prose modes, but nothing currently calls one. |
| `python` | no Python mode or grammar configured |
| `exec-path-from-shell` | only needed if Emacs is launched from a desktop launcher with a different `PATH` — see the note in §11 |

---

## 11. Verification

From a shell:

```bash
for c in emacs emacsclient git gcc g++ make find grep rg pandoc \
         clangd clang-format gopls go gofmt \
         rust-analyzer cargo rustfmt cargo-clippy \
         ghc cabal haskell-language-server-wrapper fourmolu \
         taplo prettier shfmt; do
  printf '%-36s %s\n' "$c" "$(command -v "$c" 2>/dev/null || echo MISSING)"
done

fc-list : family | grep -cw 'Iosevka'             # expect >= 1
fc-list : family | grep -ci 'symbols nerd font'   # expect >= 1
```

From inside Emacs — this is the authoritative check, since `exec-path` can
differ from the shell `PATH` when Emacs starts from a desktop launcher:

```elisp
(dolist (b '("git" "rg" "pandoc" "clangd" "clang-format" "gopls" "gofmt"
             "rust-analyzer" "cargo" "rustfmt"
             "haskell-language-server-wrapper" "cabal" "fourmolu"))
  (message "%-36s %s" b (or (executable-find b) "MISSING")))
```

And the grammars:

```elisp
(dolist (src treesit-language-source-alist)
  (message "%-12s %s" (car src)
           (if (treesit-language-available-p (car src)) "ok" "MISSING")))
```
