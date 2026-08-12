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

(defvar dk/font-family "Aporetic Sans Mono"
  "Font family used for the default and minibuffer faces.")

(defvar dk/font-height 115
  "Height (1/10 pt) of the `default' face.")

(defvar dk/minibuffer-font-height 100
  "Height (1/10 pt) of the `minibuffer-prompt' face.")

(defvar dk/theme 'gruber-darker
  "Theme loaded at start-up by src/dk-theme.el.")

(defvar dk/org-directory "~/org"
  "Root directory of the org files, used for `org-agenda-files'.")

(defvar dk/project-ignored-directories
  '(;; Haskell -- cabal v2, cabal v1, stack, and the .hie files HLS writes
    "dist-newstyle" "dist" ".stack-work" ".hie"
    ;; Rust
    "target"
    ;; C/C++ -- out-of-source cmake builds, CLion's variants, clangd's index
    "build" "cmake-build-*" ".cache"
    ;; Go -- vendored dependencies
    "vendor"
    ;; Not a language here, but they turn up beside one often enough
    "node_modules" ".direnv")
  "Build and cache directories to keep out of project file lists and searches.
Referenced from `project-vc-ignores' and `grep-find-ignored-directories'
\(dk-navigation.el) and from `consult-ripgrep-args' (dk-completion.el).

This is a safety net, not the primary mechanism: for a git-backed project
`project-files' shells out to `git ls-files --exclude-standard', and rg
reads .gitignore on its own, so a project that ignores its own build
directory is already handled.  The net matters for the projects that do
not -- there the whole of dist-newstyle lands in C-x p f -- and for roots
found by `project-vc-extra-root-markers' outside any repository.

Entries are bare directory names, which is the form
`grep-find-ignored-directories' and rg's --glob both want.  Globs are
allowed, hence \"cmake-build-*\".

`project-vc-ignores' needs each name with a trailing slash instead, and
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

(provide 'dk-vars)
;;; dk-vars.el ends here
