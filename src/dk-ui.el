;; -*- lexical-binding: t; -*-

;;; Look and feel
;;
;; `inhibit-startup-message' and the menu/tool-bar removal live in
;; early-init.el, so the frame is never created with them in the first place.

(setq initial-scratch-message
      ";; He who walks alone  ... Always walks uphill but ... Beneath his feet are the ... Broken bones of flawed men ...\n\n")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Frame chrome
(tooltip-mode -1)
(set-fringe-mode 10)
(blink-cursor-mode -1)
(column-number-mode 1)
(global-hl-line-mode 1)
(add-hook 'tty-setup-hook #'dk/enable-tty-mouse) ; mouse in the terminal

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Point, scrolling and line wrapping
(setq make-cursor-line-fully-visible nil)
(setq scroll-preserve-screen-position t)
(setq word-wrap t)
(setq recenter-positions '(middle top))
(setq scroll-conservatively 1000)
(setq scroll-margin 3)
(setq next-screen-context-lines 3)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fonts
(set-face-attribute 'default nil
                    :family dk/font-family :height dk/font-height)
(set-face-attribute 'minibuffer-prompt nil
                    :family dk/font-family :height dk/minibuffer-font-height)

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
  :custom ((doom-modeline-height 15)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Help buffers
(use-package which-key
  :ensure nil                           ; built-in since Emacs 30
  :defer 0
  :custom (which-key-idle-delay 1)
  :config (which-key-mode))

(use-package helpful
  :custom
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
