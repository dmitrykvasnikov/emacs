;; -*- lexical-binding: t; -*-

;;; Global keyboard mappings
;;
;; Loaded last, so a binding here wins over anything a package set globally.
;; Package-local bindings (:map ...) stay next to their `use-package'.

(require 'dk-functions)                 ; `dk/M-x-dwim', `dk/newline-below', ...

;; ESC quits one level (prompt, popup, extra windows) the way C-g does, instead
;; of acting as the Meta prefix.
(global-set-key (kbd "<escape>") #'keyboard-escape-quit)

(global-set-key (kbd "C-x C-b") #'ibuffer)   ; ibuffer, not the plain buffer list
(global-set-key (kbd "M-o") #'other-window)  ; shorter than C-x o
;; Comment the region, or just the current line when there is none.  Replaces
;; `dabbrev-expand'.  Not `comment-or-uncomment-region': its interactive spec is
;; "*r", so it demands a region every time -- with no mark set it simply errored
;; ("The mark is not set now, so there is no region"), and with a stale mark left
;; over from some earlier command it silently commented out everything back to
;; wherever that was.  `comment-line' takes a count instead and handles both.
(global-set-key (kbd "M-/") #'comment-line)
(global-set-key (kbd "C-c t") #'consult-theme) ; pick a theme, with live preview

;; Shift-RET: open an indented new line below without breaking the current one,
;; wherever point happens to be.  See dk-functions.el for why this is a command
;; and no longer the `C-e C-m' keyboard macro.
(global-set-key (kbd "S-<return>") #'dk/newline-below)

;; C-= (er/expand-region) is bound from its own `use-package' in dk-defaults.el.

;; Case changes.  The -dwim commands act on the region when one is active and on
;; the word after point otherwise -- unlike `upcase-word' and friends, which
;; always take the word.  M-l and M-c replace the stock bindings for those.
(global-set-key (kbd "M-u") #'upcase-dwim)
(global-set-key (kbd "M-l") #'downcase-dwim)
(global-set-key (kbd "M-c") #'capitalize-dwim)

;; Toggle CUA mode, for the occasional C-c/C-x/C-v copy-paste session.
(global-set-key (kbd "C-c r") #'cua-mode)

;; M-x, except that it moves to an already-open minibuffer instead of trying to
;; start a second one; see dk-functions.el.
(global-set-key (kbd "M-x") #'dk/M-x-dwim)

(global-set-key (kbd "C-c k") #'dk/kill-current-buffer) ; kill without confirming which
(global-set-key (kbd "C-c e") #'eval-buffer)            ; re-evaluate an elisp buffer

;; Minibuffer editing: Shift-Backspace kills the previous word.
;; `minibuffer-local-map' is the parent of every other minibuffer keymap
;; (completion, must-match, vertico-map, ...), so one binding covers all prompts.
(define-key minibuffer-local-map (kbd "S-<backspace>") #'backward-kill-word)

(provide 'dk-keymap)
;;; dk-keymap.el ends here
