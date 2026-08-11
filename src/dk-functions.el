;; -*- lexical-binding: t; -*-

;;; My functions
;;
;; Named helpers used from :hook / :custom clauses elsewhere.  Keeping them
;; named (instead of inline lambdas) means a hook can be removed again and a
;; module can be re-loaded without stacking duplicates.

;; Display statistics @startup
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
  "Underline orderless matches in the theme's string colour, no background."
  (let ((fg (face-attribute 'font-lock-string-face :foreground)))
    (dolist (face '(orderless-match-face-0
                    orderless-match-face-1
                    orderless-match-face-2
                    orderless-match-face-3))
      (set-face-attribute face nil :foreground fg :background 'unspecified :underline t))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helpful helpers
(defun dk/helpful-open (buf)
  "Display helpful buffer BUF in a split, without leaving the current window.
If the current window has full frame width, split right; otherwise split
below.  Point stays where it was, so the docs can be read and dismissed
without ever moving into them -- see `dk/helpful-dismiss'.
`helpful-switch-buffer-function' is called after `helpful-update' has
already run inside BUF, and its return value is discarded, so declining
to select the new window is safe."
  (set-window-buffer
   (if (window-full-width-p) (split-window-right) (split-window-below))
   buf))

(defun dk/helpful-window ()
  "Return a live window showing a `helpful-mode' buffer, or nil."
  (seq-find (lambda (win)
              (provided-mode-derived-p
               (buffer-local-value 'major-mode (window-buffer win))
               'helpful-mode))
            (window-list nil 'no-minibuf)))

(defun dk/helpful-dismiss ()
  "Close the visible helpful window, if there is one, and kill its buffer.
Returns non-nil when a window was actually closed, which is what lets
this be used as `:before-until' advice on the quit commands: a plain
C-g or ESC keeps its usual meaning whenever no helpful window is up."
  (interactive)
  (when-let* ((win (dk/helpful-window))
              (buf (window-buffer win)))
    ;; Only delete the window if it isn't the last one in the frame.
    (unless (one-window-p 'no-minibuf)
      (delete-window win))
    (kill-buffer buf)
    t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Commands
(defun dk/M-x-dwim ()
  "Run M-x as normal, unless the minibuffer is active, but not selected"
  (interactive)
  (if (and (active-minibuffer-window)
           (not (minibufferp)))
      (switch-to-minibuffer)
    (call-interactively #'execute-extended-command)))

(defun dk/kill-current-buffer ()
  "Kill the current buffer without asking which one."
  (interactive)
  (kill-buffer (current-buffer)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Language hooks
(defun dk/no-clang-format-p ()
  "Non-nil in a C/C++ buffer whose tree carries no .clang-format.
Used from `apheleia-inhibit-functions'.  Without it apheleia would
reformat every C buffer to clang-format's built-in LLVM style; the
per-buffer `before-save-hook' this replaced was conditional in the same
way.  Both the ts and the classic modes are listed because `c-ts-mode'
does not derive from `c-mode'."
  (and (derived-mode-p '(c-ts-mode c++-ts-mode c-mode c++-mode))
       (not (locate-dominating-file default-directory ".clang-format"))))

(defun dk/haskell-disable-doc-mode ()
  "Turn off `haskell-doc-mode', it fights with eglot/eldoc over the echo area."
  (haskell-doc-mode -1))

(defun dk/eglot-clean-haskell-markdown (args)
  "Safely strip Haskell code fences from Eglot markup data in ARGS."
  (let* ((markup (car args))
         ;; If markup is a plist (list), look for the :value key, otherwise use the string
         (str (if (listp markup) (plist-get markup :value) markup)))
    (when (and (stringp str) (string-match-p "```haskell" str))
      (let ((clean-str (replace-regexp-in-string "```haskell\n\\|```" "" str)))
        (if (listp markup)
            (plist-put markup :value clean-str)
          (setcar args clean-str)))))
  args)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Prose display
(defun dk/prose-display ()
  "Prose-friendly display: soft wrapping and a bit of extra line spacing."
  (visual-line-mode 1)
  (setq-local line-spacing 0.15))

(defalias 'dk/markdown-prose #'dk/prose-display)
(defalias 'dk/org-prose #'dk/prose-display)

(provide 'dk-functions)
;;; dk-functions.el ends here
