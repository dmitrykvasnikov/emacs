;; -*- lexical-binding: t; -*-

;;; Themes
;;
;; Loaded last: `dk/sync-orderless' recolours orderless faces from the theme,
;; so both orderless and the theme must already be there.

;; Load any theme without the "this theme may run arbitrary code, mark it safe?"
;; prompt.  Themes here come from ELPA and themes/, all of them known.
(setq custom-safe-themes t)

;; `:defer t' throughout.  A theme package does not need to be *loaded* for
;; `load-theme' or `consult-theme' to find its themes: `custom-theme-load-path'
;; defaults to (custom-theme-directory t), where t stands for `load-path', and
;; package activation already puts every package directory there.  Each theme
;; file `require's its own package at the top, so whichever theme is actually
;; enabled pulls in what it needs.  Loading all four up front cost ~65ms of
;; startup while the theme in use (gruber-darker) is a vendored one in themes/.
(use-package doom-themes    :defer t)
(use-package ef-themes      :defer t)
(use-package gruvbox-theme  :defer t)
(use-package spacemacs-theme :defer t)

;; Named function, so re-loading this file replaces the hook instead of
;; stacking another anonymous copy of it.
(defun dk/theme-enabled (theme)
  "Re-apply face tweaks that depend on the colours of THEME."
  (message "Theme enabled: %s" theme)
  (dk/sync-orderless))

(add-hook 'enable-theme-functions #'dk/theme-enabled)

;; Extra themes live in themes/, added to `custom-theme-load-path' by init.el
(load-theme dk/theme t)

(provide 'dk-theme)
;;; dk-theme.el ends here
