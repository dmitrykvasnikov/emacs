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
  "Open helpful buffer BUF in a split window.
If current window has full frame width, split right; otherwise split below."
  (select-window
   (if (window-full-width-p)
       (split-window-right)
     (split-window-below)))
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
(defun dk/clang-format-on-save ()
  "Format the buffer with clang-format on save, if the tree has a .clang-format."
  (when (locate-dominating-file default-directory ".clang-format")
    (add-hook 'before-save-hook #'clang-format-buffer nil t)))

(defun dk/go-format-on-save ()
  "Run `gofmt' on save in this buffer."
  (add-hook 'before-save-hook #'gofmt-before-save nil t))

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
