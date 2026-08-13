;; -*- lexical-binding: t; -*-

;;; Look and feel
;;
;; `inhibit-startup-message' and the menu/tool-bar removal live in
;; early-init.el, so the frame is never created with them in the first place.

(require 'dk-vars)                      ; `dk/font-family', `dk/font-height'
(require 'dk-functions)                 ; `dk/enable-tty-mouse', `dk/helpful-*'

;; Text put in *scratch* on start-up.  Must be comment syntax for the buffer's
;; mode (lisp-interaction-mode), hence the leading `;;'.
(setq initial-scratch-message
      ";; He who walks alone  ... Always walks uphill but ... Beneath his feet are the ... Broken bones of flawed men ...\n\n")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Frame chrome
(tooltip-mode -1)                       ; help text in the echo area, not a popup
(set-fringe-mode 10)                    ; 10px side margins: room for diff-hl/flymake
(blink-cursor-mode -1)                  ; a still cursor, nothing flashing
(column-number-mode 1)                  ; column next to the line number in the modeline
(global-hl-line-mode 1)                 ; faint highlight on the line point is on
(add-hook 'tty-setup-hook #'dk/enable-tty-mouse) ; mouse in the terminal

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Point, scrolling and line wrapping
;;
;; `scroll-conservatively' and `scroll-margin' are the pair that makes scrolling
;; behave like an ordinary editor's: without them Emacs jumps half a screen as
;; soon as point leaves the window.
(setq make-cursor-line-fully-visible nil) ; let the last line be half-visible, don't scroll
(setq scroll-preserve-screen-position t)  ; C-v/M-v put point back on the same screen row
;; `setq-default', not `setq': `word-wrap' is automatically buffer-local, so a
;; plain `setq' here would only affect the buffer that happened to be current
;; while this file loaded, and every other buffer would keep breaking mid-word.
(setq-default word-wrap t)                ; when a line does wrap, break at word boundaries
(setq recenter-positions '(middle top))   ; C-l cycles middle -> top only, no bottom stop
(setq scroll-conservatively 1000)         ; scroll line by line, never recenter
(setq scroll-margin 3)                    ; keep 3 lines of context above/below point
(setq next-screen-context-lines 3)        ; lines kept in view across a C-v page

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fonts
;;
;; Set as a face attribute rather than through `default-frame-alist', so it
;; applies to frames made later by `emacsclient' too.  The family and both sizes
;; come from dk-vars.el.
(set-face-attribute 'default nil
                    :family dk/font-family :height dk/font-height)

;; The minibuffer is deliberately a size smaller than the body text, so
;; vertico's candidate list takes up less of the frame.  This has to be a
;; buffer-local remap of `default' installed per prompt -- see
;; `dk/minibuffer-small-font' for why setting the `minibuffer-prompt' face
;; instead only ever shrank the prompt string.
(add-hook 'minibuffer-setup-hook #'dk/minibuffer-small-font)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Icons and modeline
;;
;; nerd-icons is the single icon backend for the whole config (modeline, dired,
;; corfu).  doom-modeline requires it outright, so it is loaded either way.
;; It draws from the "Symbols Nerd Font Mono" font -- if icons ever show up as
;; boxes, run `M-x nerd-icons-install-fonts'.
(use-package nerd-icons)

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  ;; A floor, not a fixed size: the modeline never gets shorter than the font
  ;; needs, so 15 effectively means "no extra padding".
  :custom ((doom-modeline-height 15)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Help buffers

;; Popup listing what can follow a half-typed prefix (C-x, C-c, ...).
(use-package which-key
  :ensure nil                           ; built-in since Emacs 30
  :defer 0                              ; load at idle, not on the startup path
  :custom (which-key-idle-delay 1)      ; 1s of hesitation before the popup appears
  :config (which-key-mode))

;; Richer C-h: source, callers, current value, key bindings -- all in one buffer.
(use-package helpful
  :custom
  ;; How the buffer gets on screen; see dk-functions.el.
  (helpful-switch-buffer-function #'dk/helpful-open)
  :bind
  (("C-h f" . helpful-callable)
   ("C-h v" . helpful-variable)
   ("C-h k" . helpful-key)
   ("C-h x" . helpful-command)
   ("C-h C-h" . helpful-at-point))
  :config
  ;; Dismiss the helpful window with C-g or ESC from wherever point happens to
  ;; be.  A binding in `helpful-mode-map' only fires once the helpful buffer is
  ;; selected, and `dk/helpful-open' deliberately does not select it, so the
  ;; quit commands themselves have to know about the window.
  ;;
  ;; `:before-until' means the quit is swallowed only when a helpful window was
  ;; actually closed; with none up, C-g and ESC behave exactly as before.  C-g
  ;; at a prompt runs `minibuffer-keyboard-quit' rather than `keyboard-quit',
  ;; so aborting a minibuffer is untouched.  These live in `:config' because
  ;; helpful is autoloaded -- there can be no helpful window before it loads.
  (define-advice keyboard-quit (:before-until () dk/dismiss-helpful)
    "Close a visible helpful window instead of quitting."
    (dk/helpful-dismiss))
  (define-advice keyboard-escape-quit (:before-until () dk/dismiss-helpful)
    "Close a visible helpful window instead of quitting.
Also keeps `keyboard-escape-quit' from reaching its `delete-other-windows'
branch, which would otherwise tear down unrelated splits."
    (dk/helpful-dismiss)))

(provide 'dk-ui)
;;; dk-ui.el ends here
