;; -*- lexical-binding: t; -*-
;;; init.el --- Entry point: load paths, custom file, module list

(declare-function dk/add-to-confdir "early-init" (relative-path))
(declare-function dk/add-paths-to-list "early-init"
                  (list-var paths &optional expand-p))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User identity.  Read by anything that has to sign work as coming from a
;; person: magit/VC commit authorship, message-mode, org export, gnus.
;; `setq', not `setq-default': neither of these is ever buffer-local.
(setq user-full-name "Dmitry Kvasnikov"
      user-mail-address "dmitry.kvasnikov@gmail.com")

;; Must be exactly this: a literal string, in a setq of its own, in this file.
;; `display-startup-echo-area-message' regexp-scans `user-init-file' for that
;; shape -- see the note in early-init.el.
(setq inhibit-startup-echo-area-message "dmitry")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Load paths -- `dk/add-paths-to-list' and `dk/add-to-confdir' come from
;; early-init.el, which is the only place they can live: they run before this
;; file adds src/ to `load-path'.
(dk/add-paths-to-list 'load-path '("src") t)
(dk/add-paths-to-list 'custom-theme-load-path '("themes/") t)

;; Keep the customize interface out of this file: anything set through `M-x
;; customize' is written to custom.el instead of being appended here.  That file
;; is git-ignored.  It is loaded before the modules chiefly so that values for
;; the `dk/*' variables, which are defined with `defvar', win over their defaults.
;; Options set explicitly by a module -- in a `use-package :custom' clause, for
;; example -- remain source-controlled and intentionally take precedence over
;; custom.el.
(setopt custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file nil t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Modules
;;
;; Every module lives in src/ and is prefixed dk- so that none of them shadows
;; a file of the same name in Emacs' own lisp/ directory (completion.el and
;; keymap.el both exist there, and src/ comes first on `load-path').
;;
;;   dk-vars         values shared by several modules
;;   dk-functions    named helpers used from hooks
;;   dk-packages     package.el + use-package bootstrap  (must precede the rest)
;;   dk-defaults     core editing behaviour
;;   dk-ui           look and feel, modeline, help buffers
;;   dk-completion   vertico/consult/corfu/embark
;;   dk-navigation   recentf, dired, project
;;   dk-vcs          magit, diff-hl
;;   dk-treesit      grammars and major-mode remapping (before the two below:
;;                   sets `major-mode-remap-alist' and the rust-mode knob)
;;   dk-programming  eglot, flymake, apheleia, prog-mode display
;;   dk-languages    per-language modes and LSP servers
;;   dk-writing      markdown and org
;;   dk-theme        themes (last: needs orderless loaded)
;;   dk-keymap       global keys (last: wins over package globals)
(defconst dk/modules
  '("dk-vars"
    "dk-functions"
    "dk-packages"
    "dk-defaults"
    "dk-ui"
    "dk-completion"
    "dk-navigation"
    "dk-vcs"
    "dk-treesit"
    "dk-programming"
    "dk-languages"
    "dk-writing"
    "dk-theme"
    "dk-keymap")
  "Configuration modules in src/, loaded in this order.")

;; Fail fast.  Continuing after a module errors leaves any side effects from the
;; first half of that module in place and makes failures in later modules much
;; harder to diagnose.
(dolist (module dk/modules)
  (load (dk/add-to-confdir (concat "src/" module)) nil t))

(provide 'init)
;;; init.el ends here
