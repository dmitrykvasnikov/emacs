;; -*- lexical-binding: t; -*-

;;; Core editing behaviour
;;
;; Everything here is about *how editing behaves*; how it looks is in ui.el.

(setq use-short-answers t)              ; y/n instead of yes/no

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Files, backups and auto-save
(setq make-backup-files nil)            ; no foo~ next to the file
(setq create-lockfiles nil)             ; no .#foo
(make-directory dk/auto-save-directory t)
(setq auto-save-file-name-transforms `((".*" ,dk/auto-save-directory t)))
(setq vc-follow-symlinks t)             ; follow symlinks without confirmation
(setq delete-by-moving-to-trash (not noninteractive))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Global minor modes
(delete-selection-mode 1)               ; typing replaces the active region
(savehist-mode 1)                       ; persist minibuffer history
(save-place-mode 1)                     ; reopen files where they were left
(global-auto-revert-mode 1)             ; reload files changed on disk
(repeat-mode 1)
(winner-mode 1)                         ; C-c <left>/<right> undo window changes
(electric-pair-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bells and undo
(setq visible-bell nil)
(setq ring-bell-function #'ignore)
(setq undo-limit (* 13 160000)
      undo-strong-limit (* 13 240000)
      undo-outer-limit (* 13 24000000))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Search
(setq isearch-allow-scroll t)
(setq isearch-lazy-count t)
(setq isearch-wrap-pause 'no-ding)
(setq isearch-repeat-on-direction-change t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Editing helpers
(use-package expand-region)             ; C-= in keymap.el

(provide 'dk-defaults)
;;; dk-defaults.el ends here
