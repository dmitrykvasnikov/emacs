;; -*- lexical-binding: t; -*-

;;; My variables
;;
;; Values that are referenced from more than one module live here, so that a
;; single edit changes every place that uses them.

(defvar dk/auto-save-directory (expand-file-name "autosave/" user-emacs-directory)
  "Directory where auto-save files are kept, out of the way of the project.
The trailing slash is load-bearing.  With the UNIQUIFY flag set in
`auto-save-file-name-transforms', `files--transform-file-name' runs the
replacement through `file-name-directory' before appending the mangled
name -- without the slash the last component is read as a file name and
dropped, and every auto-save lands in `user-emacs-directory' instead.")

(defvar dk/backup-directory (expand-file-name "backups/" user-emacs-directory)
  "Directory where numbered backup versions of local files are kept.")

(defvar dk/lock-directory (expand-file-name "locks/" user-emacs-directory)
  "Directory where file locks (.#foo symlinks) are kept, out of the project.
The trailing slash is load-bearing for the same reason as in
`dk/auto-save-directory': `lock-file-name-transforms' uses the UNIQUIFY
flag, which runs the replacement through `file-name-directory'.")

(defvar dk/recentf-save-timer nil
  "Idle timer that saves the recent-file list periodically.
Set in dk-navigation.el.  Kept in a variable so that reloading the module
cancels the previous timer instead of stacking a second one.")

(defvar dk/font-families
  '("Aporetic Sans Mono"
    "Iosevka"
    "0xProto Nerd Font Mono"
    "IBM Plex Mono"
    "VictorMono Nerd Font Mono")
  "Font families offered by `dk/change-font'.
Each string must be the exact family name that Emacs reports in
`font-family-list'.")

(defvar dk/font-family "Iosevka"
  "Font family used by the global `default' face.
`dk/change-font' updates this value when the font is changed for the
current Emacs session.  Fonts without programming ligatures still work,
but the `ligature' setup in dk-ui.el cannot invent glyphs absent from the
font.  In particular, Aporetic Sans Mono omits those OpenType features.")

(defvar dk/font-height 115
  "Height (1/10 pt) of the `default' face.")

(defvar dk/minibuffer-font-height 100
  "Height (1/10 pt) of the whole minibuffer, prompt and candidates.
Applied by `dk/minibuffer-small-font' as a buffer-local remapping of the
`default' face.")

(defvar dk/theme 'gruber-darker
  "Theme loaded at start-up by src/dk-theme.el.")

(defvar dk/org-directory "~/org"
  "Root directory of the org files, used for `org-agenda-files'.")

(defvar dk/project-ignored-directories
  '(;; Haskell -- cabal v2, stack, and the .hie files HLS writes
    "dist-newstyle" ".stack-work" ".hie"
    ;; Rust
    "target"
    ;; C/C++ -- CLion's out-of-source cmake builds, clangd's index
    "cmake-build-*" ".cache"
    ;; Not a language here, but they turn up beside one often enough
    "node_modules" ".direnv")
  "Generated directories to keep out of project file lists and searches.
Referenced from `project-vc-ignores' and `grep-find-ignored-directories'
\(dk-navigation.el) and from `consult-ripgrep-args' (dk-completion.el).

This is a safety net, not the primary mechanism: for a git-backed project
`project-files' shells out to `git ls-files --exclude-standard', and rg
reads .gitignore on its own, so a project that ignores its own build
directory is already handled.  The net matters for the projects that do
not -- there the whole of dist-newstyle lands in C-x p f -- and for roots
found by `project-vc-extra-root-markers' outside any repository.

The net applies at any depth and overrides what git tracks, so it holds
only names that are always generated.  Generic names such as \"build\",
\"dist\" and \"vendor\" are left out on purpose: plenty of projects keep
hand-written sources or vendored code under them, and those files would
silently vanish from C-x p f and every search.  A project that needs
more can set `project-vc-ignores' in its own .dir-locals.el (the variable
is `safe-local-variable' for lists).

Entries are bare directory names, which is the form
`grep-find-ignored-directories' wants.  Globs are allowed, hence
\"cmake-build-*\".  dk-completion.el turns each into an rg
`--glob=!NAME/' -- the trailing slash restricts it to directories, so a
plain file of the same name is still searched.

`project-vc-ignores' needs each name with a trailing slash too, and
dk-navigation.el appends one there.  That is not cosmetic: a bare name
becomes the pathspec `**/NAME', which matches the directory entry but
none of the files under it, so the setting silently does nothing --
there is a FIXME about it in `project--vc-list-files'.  With the slash it
takes the `NAME/ -> NAME/**' branch instead and actually prunes.")

(defvar dk/eglot-connect-wait 15
  "Seconds an xref jump waits for a starting LSP server before giving up.
Used by `dk/xref-wait-for-eglot' (dk-functions.el).  Generous on purpose:
the wait only happens on a jump made before the server has answered
`initialize', and C-g interrupts it.")

(defvar-local dk/eglot-connecting-server nil
  "Server initialized from this buffer, used to bound xref's startup wait.")

(provide 'dk-vars)
;;; dk-vars.el ends here
