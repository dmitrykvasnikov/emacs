;;; src/functions.el --- user functions -*- lexical-binding: t; -*-

;; Display statistics at startup
(defun dk/display-startup-time ()
  "Display statistics on start-up"
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))
(add-hook 'emacs-startup-hook #'dk/display-startup-time)

;; Setup orderless match faces
(defun dk/sync-orderless ()
  "Set orderless match faces to use the same background as visual selection."
  (let ((bg (face-attribute 'region :background))
	(fg (face-attribute 'font-lock-string-face :foreground)))
    (dolist (face '(orderless-match-face-0
                    orderless-match-face-1
                    orderless-match-face-2
                    orderless-match-face-3))
      (set-face-attribute face nil :foreground fg :background 'unspecified :underline t))))

;; Helpful helpers
(defun dk/helpful-open (buf)
  "Open helpful buffer BUF in a split window.
If current window has full frame width, split right; otherwise split below."
  (select-window
   (if (window-full-width-p)
       (split-window-right)
     (split-window-below)))
  ;; or to split window on bigger size
  ;; (if (> (window-pixel-width) (window-pixel-height))
  ;;     (split-window-right)
  ;;   (split-window-below))
  (switch-to-buffer buf))

(defun dk/helpful-close ()
  "Close the helpful window and kill its buffer."
  (interactive)
  (let ((buf (current-buffer)))
    ;; Delete the window, but only if it's not the only one in the frame
    (unless (one-window-p)
      (delete-window))
    ;; Kill the helpful buffer
    (kill-buffer buf)))

(defun dk/M-x-dwim ()
  "Run M-x as normal, unless the minibuffer is active, but not selected"
  (interactive)
  (if (and (active-minibuffer-window)
	   (not (minibufferp)))
      (switch-to-minibuffer)
    (call-interactively #'execute-extended-command)))

(defun dk/eglot-clean-haskell-markdown (args)
  "Safely strip Haskell code fences from Eglot markup data."
  (let* ((markup (car args))
         ;; If markup is a plist (list), look for the :value key, otherwise use the string
         (str (if (listp markup) (plist-get markup :value) markup)))
    (when (and (stringp str) (string-match-p "```haskell" str))
      (let ((clean-str (replace-regexp-in-string "```haskell\n\\|```" "" str)))
        (if (listp markup)
            (plist-put markup :value clean-str)
          (setcar args clean-str)))))
  args)

;; Org/Markdown files display
(defun dk/prose-setup ()
  "Prose-friendly display for Markdown buffers."
  (visual-line-mode 1)
  (setq-local line-spacing dk/prose-line-spacing))

(defun dk/consult-line-repeat ()
  "Run `consult-line' seeded with the previous search string.
The equivalent of isearch's `C-s C-s': `consult-line' is not incremental,
so there is no match to advance from — this re-runs the last search
instead.  Falls back to a plain `consult-line' when the history is empty
or consult has not been loaded yet."
  (interactive)
  (consult-line (car (bound-and-true-p consult--line-history))))

(defun dk/newline-below ()
  "Open a new line below point, regardless of column."
  (interactive)
  (end-of-line)
  (newline-and-indent))

(defun dk/theme-hook (theme)
  "Re-sync derived faces after THEME is enabled."
  (message "Theme enabled: %s" theme)
  (dk/sync-orderless))

(defun dk/haskell-setup ()
  "Stop `haskell-doc-mode' from fighting Eldoc/Eglot.
Guarded: `haskell-ts-mode' buffers never enable it, and calling the
autoloaded command there would pull in haskell-doc for nothing."
  (when (bound-and-true-p haskell-doc-mode)
    (haskell-doc-mode -1)))

(defun dk/treesit-apply-remaps ()
  "Remap classic major modes to tree-sitter ones where the grammar exists.
Guarding on the grammar means a missing one degrades to the classic mode
instead of a tree-sitter mode with no parser behind it."
  (pcase-dolist (`(,classic ,ts ,lang) dk/treesit-remaps)
    (when (treesit-language-available-p lang)
      (add-to-list 'major-mode-remap-alist (cons classic ts)))))

(defun dk/eglot-expected-p ()
  "Non-nil when this buffer's major mode is set up to start Eglot.
Walks the mode's parents, so `python-ts-mode' is covered by the hook on
`python-base-mode'."
  (and buffer-file-name
       (seq-some (lambda (mode)
                   (let ((hook (intern-soft (format "%s-hook" mode))))
                     (and hook (boundp hook)
                          (memq 'eglot-ensure (symbol-value hook)))))
                 (derived-mode-all-parents major-mode))))

(defun dk/xref-wait-for-eglot (&rest _)
  "Wait for a starting Eglot server before xref settles on a backend.
`eglot-ensure' connects in the background, so right after a file is
opened the buffer is not managed yet and `xref-backend-functions' still
answers `etags': M-. then prompts for a TAGS file that does not exist
instead of jumping, which reads as \"navigation is broken\".  The window
is milliseconds for a warm server but seconds for gopls on a cold cache
in a cgo-heavy project — precisely when the first jump is made.

Waiting here rather than raising `eglot-sync-connect' keeps visiting a
file instant and pays the cost only on the jump that needs it.  Erroring
out afterwards is deliberate: in a mode that has an LSP server the etags
fallback has nothing useful to offer."
  ;; `eglot--managed-mode' first: one buffer-local variable read short-circuits
  ;; every jump in a connected buffer, which is all of them after the first.
  (when (and (not (bound-and-true-p eglot--managed-mode))
             (dk/eglot-expected-p))
    (with-delayed-message (1 "Waiting for the language server...")
      (let ((deadline (+ (float-time) dk/eglot-connect-wait)))
        (while (and (not (bound-and-true-p eglot--managed-mode))
                    (< (float-time) deadline))
          (accept-process-output nil 0.05))))
    (unless (bound-and-true-p eglot--managed-mode)
      (user-error "No language server in this buffer yet; try M-x eglot"))))

(defun dk/apheleia-inhibit-unconfigured-c ()
  "Inhibit apheleia in C/C++ buffers with no .clang-format in scope."
  (and (derived-mode-p 'c-mode 'c-ts-mode 'c++-mode 'c++-ts-mode)
       (not (locate-dominating-file default-directory ".clang-format"))))

(defun dk/treesit-install-missing ()
  "Compile and install any tree-sitter grammar that is missing.
Needs git and a C compiler.  Run once per machine, then restart Emacs.
Iterates `dk/treesit-languages' directly rather than
`treesit-language-source-alist', so a broken wiring of the latter cannot
turn this into a silent no-op."
  (interactive)
  (dolist (lang (mapcar #'car dk/treesit-languages))
    (if (treesit-language-available-p lang)
        (message "tree-sitter grammar present: %s" lang)
      (message "Installing tree-sitter grammar: %s" lang)
      (treesit-install-language-grammar lang))))

(defun dk/escape-dwim ()
  "Quit the minibuffer if active, otherwise plain `keyboard-quit'.
Never deletes windows, unlike `keyboard-escape-quit'."
  (interactive)
  (if (active-minibuffer-window)
      (abort-recursive-edit)
    (keyboard-quit)))

(provide 'functions)
;;; functions.el ends here
