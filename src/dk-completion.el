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
;; Vertical candidate list in the minibuffer, in place of the stock
;; *Completions* window.
(use-package vertico
  :init (vertico-mode)
  :custom
  (vertico-count 15)                    ; at most 15 candidates on screen
  (vertico-cycle t)                     ; past the last candidate, back to the first
  (vertico-resize nil)                  ; keep the list a fixed height, no jumping
  (vertico-scroll-margin 7))            ; start scrolling 7 candidates from the edge

;; Path editing in file prompts: RET on a directory descends into it instead of
;; ending the prompt.  Ships with vertico, hence `:ensure nil'.
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

;; Per-category vertico settings.  Also ships with vertico.
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

;; Space-separated matching: "fi buf" finds `find-file-other-buffer' in any
;; order, no need to remember where the words sit in the name.
(use-package orderless
  :custom
  ;; orderless first, `basic' behind it as the fallback that still does exact
  ;; prefix matching -- which is what TRAMP and a few other back-ends rely on.
  (completion-styles '(orderless basic))
  ;; File names are the exception: `partial-completion' is what expands
  ;; /u/s/l into /usr/share/lib, and orderless would ignore the separators.
  (completion-category-overrides '((file (styles partial-completion))))
  ;; Let `partial-completion' match in the middle of a component too, so "log"
  ;; finds "catalog.txt" and not just files starting with "log".
  (completion-pcm-leading-wildcard t))

;; Annotations in the right margin of the candidate list: a command's key
;; binding, a variable's value, a file's size and mode.
(use-package marginalia
  :after vertico
  :init (marginalia-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Consult commands
;;
;; Live-previewing replacements for the built-in commands: each one feeds a
;; completing-read, so vertico/orderless/marginalia apply to all of them.
(use-package consult
  :bind (("C-x b"   . consult-buffer)          ;; buffers + recent files + bookmarks
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-c C-f" . consult-find)            ;; find(1) under a directory
         ("C-s"     . consult-line)            ;; search lines in this buffer
         ;; Repeat that search with its previous string, the way C-s C-s does in
         ;; isearch.  GUI only: a terminal cannot tell C-S-s from C-s, so there
         ;; this key just arrives as C-s and starts a fresh `consult-line'.
         ("C-S-s"   . dk/consult-line-repeat)
         ("C-x C-r" . consult-recent-file)
         ("C-c ?"   . consult-flymake)         ;; jump through the diagnostics
         ("C-c m"   . consult-mode-command)    ;; only the current mode's commands
         ("M-y"     . consult-yank-pop)        ;; pick from the kill ring by preview
         ;; `consult-history' is only meaningful where there *is* a history.
         ;; Bound globally it shadowed `isearch-backward' everywhere and, in an
         ;; ordinary buffer, `consult--current-history' has no branch to take
         ;; and signals an error.  `minibuffer-local-map' is the parent of every
         ;; other minibuffer keymap, so this one entry covers all prompts.
         :map minibuffer-local-map
         ("C-r"     . consult-history))
  :custom
  ;; Preview on any key that moves the selection, rather than only on an
  ;; explicit M-. -- so walking the candidate list shows each buffer/line/file.
  (consult-preview-key 'any)
  ;; Report line numbers counted from the start of the file even in a narrowed
  ;; buffer, so they match what the compiler or git says.
  (consult-line-numbers-widen t)
  :config
  ;; Keep eglot's own buffers out of the buffer list.  This lived in
  ;; `projectile-globally-ignored-buffers' before; project.el has no
  ;; equivalent, and consult is what actually lists buffers here.
  (add-to-list 'consult-buffer-filter "\\`EGLOT")
  ;; Build directories kept out of C-x p g as well, matching what project.el
  ;; hides from C-x p f (see `dk/project-ignored-directories').  rg already
  ;; reads .gitignore, so this only bites in the projects that do not ignore
  ;; their own build output -- exactly the case that prompted the setting.
  ;; Appended in `:config' rather than set in `:custom': consult is deferred,
  ;; so the variable does not exist yet when the `:custom' forms run, and the
  ;; upstream default is worth inheriting rather than restating here.
  ;; `ensure-list' because the variable is documented as a string *or* a list;
  ;; it is a string today, and `consult--build-args' accepts either, so going
  ;; through a list keeps this working if that default is ever changed.
  (setq consult-ripgrep-args
        (append (ensure-list consult-ripgrep-args)
                (mapcar (lambda (dir) (format "--glob=!%s" dir))
                        dk/project-ignored-directories))))

;; The other half of the C-r story: shells and REPLs keep a real history too.
;; Kept outside the `use-package' above because that block only runs once consult
;; loads, which may well be after the first comint buffer already exists.
(with-eval-after-load 'comint
  (keymap-set comint-mode-map "C-r" #'consult-history))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Act on the thing at point / on candidates
;; A right-click menu for the keyboard: `embark-act' offers the actions that fit
;; whatever is at point or is the current completion candidate (a file -> open,
;; rename, delete; a symbol -> describe, find definition; a URL -> browse).
(use-package embark
  :bind (("C-." . embark-act)         ;; menu of actions for the thing at point
         ("C-;" . embark-dwim)        ;; run the most likely action without asking
         ("C-h B" . embark-bindings)) ;; every binding available here, searchable
  :init
  ;; With 3 or fewer candidates, TAB just cycles them instead of popping up a
  ;; completion list.  Set here because embark's docs recommend it alongside
  ;; `tab-always-indent' = complete, set at the top of this file.
  (setq completion-cycle-threshold 3))

;; Glue: makes `embark-export' from a consult search produce a live grep/occur
;; buffer, and adds consult's preview to embark's collect buffers.
(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Completion at point
;; In-buffer completion popup, driven by whatever `completion-at-point-functions'
;; offers -- eglot in a code buffer, cape elsewhere.
(use-package corfu
  :custom
  (corfu-cycle t)                   ;; TAB past the last candidate wraps to the first
  (corfu-auto t)                    ;; pop up while typing, no need to hit TAB
  (corfu-auto-delay 0.2)            ;; seconds of idle before it appears
  (corfu-auto-prefix 2)             ;; ...and only after 2 characters
  (corfu-popupinfo-delay 0.5)       ;; idle before the docs pane opens beside it
  (corfu-preview-current t)         ;; show the selected candidate inline in the buffer
  (corfu-on-exact-match nil)        ;; a single exact match still waits for confirmation
  ;; Quit when point moves past a word boundary -- unless the boundary was typed
  ;; as the separator below, which is how a multi-word orderless filter is
  ;; entered without the popup closing on the space.
  (corfu-quit-at-boundary 'separator)
  (corfu-quit-no-match t)           ;; nothing matches -> get out of the way
  (corfu-separator ?\s)             ;; space separates orderless components
  (corfu-scroll-margin 5)           ;; context rows kept visible while scrolling
  (corfu-preselect :first)          ;; first candidate selected, so RET takes it
  :bind
  (:map corfu-map
        ("TAB"     . corfu-insert)
        ("RET"     . corfu-insert)
        ("M-d"     . corfu-popupinfo-toggle) ;; toggle doc popup
        ("C-g"     . corfu-quit)
        ("M-l"     . corfu-show-location))   ;; jump to candidate source
  :init
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1))           ;; docs/signature in a pane next to the popup

;; Extra completion-at-point back-ends.  These are what corfu falls back on in
;; buffers with no LSP: file names and words already in the buffer.
(use-package cape
  :init
  ;; Depths, not plain `add-hook' calls: `add-hook' prepends, so listing
  ;; cape-file first and cape-dabbrev second produced (cape-dabbrev cape-file)
  ;; -- and cape-dabbrev matches the trailing word of a path and answers first,
  ;; which meant file completion almost never fired.
  (add-hook 'completion-at-point-functions #'cape-file -10)
  (add-hook 'completion-at-point-functions #'cape-dabbrev -5)
  ;; Don't offer buffer words until 3 characters are typed -- below that the
  ;; candidate list is noise.
  :custom (cape-dabbrev-min-length 3))

;; Kind of each candidate (function, variable, class, ...) in the corfu margin,
;; taken from the CAPF's `:company-kind'.  Only one margin formatter may be
;; installed -- do not add a second one alongside this.
(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(provide 'dk-completion)
;;; dk-completion.el ends here
