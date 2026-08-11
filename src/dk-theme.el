;; -*- lexical-binding: t; -*-

;;; Themes
;;
;; Loaded last: `dk/sync-orderless' recolours orderless faces from the theme,
;; so both orderless and the theme must already be there.

(setq custom-safe-themes t)

(use-package doom-themes)
(use-package ef-themes)
(use-package gruvbox-theme)
(use-package spacemacs-theme)

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
