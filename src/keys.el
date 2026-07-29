;;; src/keys.el --- user key bindings -*- lexical-binding: t; -*-

;; NB: this file must NOT be called keymap.el.  Emacs preloads its own
;; lisp/keymap.el, so `(require 'keymap)' sees the feature already in
;; `features' and returns without ever loading this file — every binding
;; below silently does nothing.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Keyboard mappings

;;(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
(global-set-key (kbd "<escape>") #'dk/escape-dwim)
(global-set-key (kbd "C-x C-b") #'ibuffer)
(global-set-key (kbd "M-o") #'other-window)
(global-set-key (kbd "M-/") #'comment-or-uncomment-region)
(global-set-key (kbd "C-c t") #'consult-theme)
(global-set-key (kbd "S-<return>") #'dk/newline-below)
(global-set-key (kbd "C-=") #'er/expand-region)
(global-set-key (kbd "M-u") #'upcase-dwim)
(global-set-key (kbd "M-l") #'downcase-dwim)
(global-set-key (kbd "M-c") #'capitalize-dwim)
(global-set-key (kbd "C-c r") #'cua-mode)
(global-set-key (kbd "M-x") #'dk/M-x-dwim)
(global-set-key (kbd "C-c k") #'kill-current-buffer)
;;(global-set-key (kbd "C-c k") (lambda() (interactive) (kill-buffer (current-buffer))))
(global-set-key (kbd "C-c e") #'eval-buffer)
;; Repeat the last consult-line search.  GUI only: a terminal cannot tell
;; C-S-s from C-s, so there it just runs consult-line normally.
(global-set-key (kbd "C-S-s") #'dk/consult-line-repeat)
;; Compilation: `recompile' is the 90% case, `project-compile' sets the command.
(global-set-key (kbd "C-c c") #'recompile)
(global-set-key (kbd "C-c C") #'project-compile)

;; Minibuffer editing: Shift-Backspace kills the previous word.
;; `minibuffer-local-map' is the parent of every other minibuffer keymap
;; (completion, must-match, vertico-map, ...), so one binding covers all prompts.
(define-key minibuffer-local-map (kbd "S-<backspace>") #'backward-kill-word)

(provide 'keys)
;;; keys.el ends here
