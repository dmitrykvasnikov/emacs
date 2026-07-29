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

(defun dk/clang-fos ()
  (when (locate-dominating-file default-directory ".clang-format")
    (add-hook 'before-save-hook #'clang-format-buffer nil t)))

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
  "Stop `haskell-doc-mode' from fighting Eldoc/Eglot."
  (haskell-doc-mode -1))

(defun dk/apheleia-inhibit-unconfigured-c ()
  "Inhibit apheleia in C/C++ buffers with no .clang-format in scope."
  (and (derived-mode-p 'c-mode 'c-ts-mode 'c++-mode 'c++-ts-mode)
       (not (locate-dominating-file default-directory ".clang-format"))))

(defun dk/treesit-install-missing ()
  "Compile and install any tree-sitter grammar that is missing.
Needs git and a C compiler.  Run once per machine."
  (interactive)
  (dolist (lang (mapcar #'car treesit-language-source-alist))
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
