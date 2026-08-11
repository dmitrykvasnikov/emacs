;; -*- lexical-binding: t; -*-

;;; Minibuffer and in-buffer completion
;;
;; vertico + orderless + marginalia + consult in the minibuffer,
;; corfu + cape at point, embark to act on candidates.

;; TAB completes when the line is already indented; this is the single place
;; `tab-always-indent' is set (corfu/embark both want the `complete' value).
(setq tab-always-indent 'complete)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Minibuffer UI
(use-package vertico
  :init (vertico-mode)
  :custom
  (vertico-count 15)
  (vertico-cycle t)
  (vertico-resize nil)
  (vertico-scroll-margin 7))

(use-package vertico-directory
  :ensure nil
  :after vertico
  :bind (:map vertico-map
              ("RET"   . vertico-directory-enter)
              ;; Plain commands, not the vertico-directory-* variants: those delete a
              ;; whole path component when point is right after "/", which makes
              ;; Backspace and Shift-Backspace identical at a directory boundary.
              ("DEL"   . delete-backward-char)
              ("S-<backspace>" . backward-kill-word)
              ;; Up one directory in file prompts; plain word kill everywhere else
              ("M-DEL" . vertico-directory-delete-word)))

(use-package vertico-multiform
  :ensure nil
  :after vertico
  :custom
  ;; Sort file prompts (find-file, dired, ...) by name.  Other prompts keep the
  ;; default history/length ordering.  Consult sources that declare their own
  ;; display-sort-function, e.g. consult-recent-file, are unaffected.
  (vertico-multiform-categories
   '((file (vertico-sort-function . vertico-sort-alpha))))
  :config
  (vertico-multiform-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t))

(use-package marginalia
  :after vertico
  :init (marginalia-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Consult commands
(use-package consult
  :bind (("C-x b"   . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-c C-f" . consult-find)
         ("C-s"     . consult-line)          ;; search line in buffer
         ("C-x C-r" . consult-recent-file)
         ("C-c ?"   . consult-flymake)
         ("C-c m"   . consult-mode-command)
         ("M-y"     . consult-yank-pop)
         ;; `consult-history' is only meaningful where there *is* a history.
         ;; Bound globally it shadowed `isearch-backward' everywhere and, in an
         ;; ordinary buffer, `consult--current-history' has no branch to take
         ;; and signals an error.  `minibuffer-local-map' is the parent of every
         ;; other minibuffer keymap, so this one entry covers all prompts.
         :map minibuffer-local-map
         ("C-r"     . consult-history))
  :custom
  (consult-preview-key 'any)              ;; preview while moving
  (consult-line-numbers-widen t)
  :config
  ;; Keep eglot's own buffers out of the buffer list.  This lived in
  ;; `projectile-globally-ignored-buffers' before; project.el has no
  ;; equivalent, and consult is what actually lists buffers here.
  (add-to-list 'consult-buffer-filter "\\`EGLOT"))

;; The other half of the C-r story: shells and REPLs keep a real history too.
;; Kept outside the `use-package' above because that block only runs once consult
;; loads, which may well be after the first comint buffer already exists.
(with-eval-after-load 'comint
  (keymap-set comint-mode-map "C-r" #'consult-history))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Act on the thing at point / on candidates
(use-package embark
  :bind (("C-." . embark-act)         ;; act on thing at point
         ("C-;" . embark-dwim)        ;; do what I mean
         ("C-h B" . embark-bindings)) ;; show bindings
  :init
  (setq completion-cycle-threshold 3))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Completion at point
(use-package corfu
  :custom
  (corfu-cycle t)                   ;; TAB cycles candidates
  (corfu-auto t)                    ;; auto-popup completion
  (corfu-auto-delay 0.2)            ;; delay before auto popup
  (corfu-auto-prefix 2)             ;; minimum prefix length for auto
  (corfu-popupinfo-delay 0.5)       ;; delay for doc popup
  (corfu-preview-current t)         ;; preview current candidate
  (corfu-on-exact-match nil)        ;; don't auto-insert on exact match
  (corfu-quit-at-boundary 'separator)
  (corfu-quit-no-match t)
  (corfu-separator ?\s)             ;; space is separator (for LSP)
  (corfu-scroll-margin 5)
  (corfu-preselect :first)
  :bind
  (:map corfu-map
        ("TAB"     . corfu-insert)
        ("RET"     . corfu-insert)
        ("M-d"     . corfu-popupinfo-toggle) ;; toggle doc popup
        ("C-g"     . corfu-quit)
        ("M-l"     . corfu-show-location))   ;; jump to candidate source
  :init
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1))

(use-package cape
  :init
  ;; Depths, not plain `add-hook' calls: `add-hook' prepends, so listing
  ;; cape-file first and cape-dabbrev second produced (cape-dabbrev cape-file)
  ;; -- and cape-dabbrev matches the trailing word of a path and answers first,
  ;; which meant file completion almost never fired.
  (add-hook 'completion-at-point-functions #'cape-file -10)
  (add-hook 'completion-at-point-functions #'cape-dabbrev -5)
  :custom (cape-dabbrev-min-length 3))

;; corfu draws its popup with child frames, which a terminal frame does not have
;; -- without this, completion in `emacsclient -nw' is invisible.  The mode is
;; safe to enable unconditionally: `corfu-terminal-disable-on-gui' defaults to t
;; and every entry point re-checks `display-graphic-p', so a mixed session of GUI
;; and terminal frames gets the right popup in each.
(use-package corfu-terminal
  :after corfu
  :config (corfu-terminal-mode 1))

;; Kind of each candidate (function, variable, class, ...) in the corfu margin,
;; taken from the CAPF's `:company-kind'.  Only one margin formatter may be
;; installed -- do not add a second one alongside this.
(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(provide 'dk-completion)
;;; dk-completion.el ends here
