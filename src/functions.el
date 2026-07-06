;; -*- lexical-binding: t; -*-

;; My functions

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

(provide 'functions.el)
;;; functions.el ends here
