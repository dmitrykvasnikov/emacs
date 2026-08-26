;; -*- lexical-binding: t; -*-

;;; My functions
;;
;; Named helpers used from :hook / :custom clauses elsewhere.  Keeping them
;; named (instead of inline lambdas) means a hook can be removed again and a
;; module can be re-loaded without stacking duplicates.

(require 'dk-vars)                      ; shared command and hook settings

;; Called only under a `derived-mode-p' guard, so org is loaded by then; this
;; just keeps the byte-compiler quiet about it.
(declare-function org-at-table-p "org" (&optional table-type))
(declare-function org-table-copy-down "org-table" (n))
(declare-function cape-dabbrev "cape" (&optional interactive))
(declare-function dk/add-to-confdir "../early-init" (relative-path))
(declare-function eglot-managed-p "eglot" ())
(declare-function face-remap-remove-relative "face-remap" (cookie))

(defvar-local dk/font-remap-cookie nil
  "Cookie for the font remapping installed by `dk/change-font'.")

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
      (when (facep face)
        (set-face-attribute face nil :foreground fg
                            :background 'unspecified :underline t)))))

;; Mouse support on a terminal frame.  Called from `tty-setup-hook' rather than
;; unconditionally at startup: `xterm-mouse-mode' does nothing under a GUI, and
;; the hook also catches `emacsclient -nw' frames opened later.  It must be a
;; named wrapper -- `xterm-mouse-mode' is a global minor mode, so putting the
;; mode function itself on the hook would *toggle* it once per terminal frame.
(defun dk/enable-tty-mouse ()
  "Turn on `xterm-mouse-mode' for a terminal frame."
  (xterm-mouse-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helpful helpers
(defun dk/helpful-open (buf)
  "Display helpful buffer BUF in a split when the frame has room.
If the current window has full frame width, split right; otherwise split
below.  Point stays where it was when a split succeeds, so the docs can be
read and dismissed without moving into them.  If the frame is too small to
split, use the current window instead of raising an error.
`helpful-switch-buffer-function' is called after `helpful-update' has
already run inside BUF, and its return value is discarded, so declining
to select the new window is safe."
  (let ((win (condition-case nil
                 (if (window-full-width-p)
                     (split-window-right)
                   (split-window-below))
               (error nil))))
    (if win
        (set-window-buffer win buf)
      (switch-to-buffer buf))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Config maintenance
(defun dk/recompile-config (&optional force)
  "Byte-compile the config modules in src/.
Not run automatically: `load-prefer-newer' is t, so a .elc that has gone
stale is ignored in favour of the .el rather than silently loaded, which
makes leaving this un-run harmless.  With FORCE (the prefix argument),
recompile even the files whose .elc is already current."
  (interactive "P")
  (byte-recompile-directory (dk/add-to-confdir "src") 0 force))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Commands
(defun dk/change-font ()
  "Choose a configured font for this session or the current buffer.
Candidates come from `dk/font-families'.  Before changing anything,
verify that the selected family is available to the current graphical
frame.  A session-wide change affects every existing frame and frames
created later; a buffer-local change follows the buffer between windows."
  (interactive)
  (unless (display-graphic-p)
    (user-error "Fonts can only be changed from a graphical frame"))
  (let* ((buffer (current-buffer))
         (family (completing-read "Font: " dk/font-families nil t
                                  nil nil dk/font-family)))
    (unless (find-font (font-spec :family family))
      (user-error "Font family `%s' is not installed" family))
    (pcase (car (read-multiple-choice
                 (format "Use %s for: " family)
                 '((?g "global" "all frames for this Emacs session")
                   (?b "buffer" "the current buffer only"))))
      (?g
       (set-face-attribute 'default nil :family family)
       (setq dk/font-family family)
       ;; Otherwise a previous buffer-only choice would hide the new global
       ;; font in the buffer from which this command was invoked.
       (with-current-buffer buffer
         (when dk/font-remap-cookie
           (face-remap-remove-relative dk/font-remap-cookie)
           (setq dk/font-remap-cookie nil)))
       (message "Using %s globally for this Emacs session" family))
      (?b
       (with-current-buffer buffer
         (when dk/font-remap-cookie
           (face-remap-remove-relative dk/font-remap-cookie))
         (setq dk/font-remap-cookie
               (face-remap-add-relative 'default `(:family ,family))))
       (message "Using %s in buffer %s" family (buffer-name buffer))))))

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

(defun dk/newline-below ()
  "Open a new line below point and indent it, regardless of column.
Bound to S-RET.  This replaced the `C-e C-m' keyboard macro that used to
sit on that key: a macro re-runs whatever RET is bound to *now*, so in
org and markdown it ran `org-return' / `markdown-enter-key' instead, and
it indented only as far as `electric-indent-mode' happened to be on.
Calling `newline-and-indent' directly makes the key mean the same thing
in every mode.

Inside an org table it defers to `org-table-copy-down' instead.  Org
binds that to S-RET and to nothing else -- the menu entry aside, taking
the key outright would remove the command from the keyboard altogether --
and \"open a line below\" has no meaning in a table row anyway."
  (interactive)
  (if (and (derived-mode-p 'org-mode) (org-at-table-p))
      (call-interactively #'org-table-copy-down)
    (end-of-line)
    (newline-and-indent)))

(defun dk/consult-line-repeat ()
  "Run `consult-line' seeded with the previous search string.
The equivalent of isearch's `C-s C-s': `consult-line' is not incremental,
so there is no match to advance from -- this re-runs the last search
instead.  Falls back to a plain `consult-line' when the history is empty
or consult has not been loaded yet."
  (interactive)
  (consult-line (car (bound-and-true-p consult--line-history))))

(defun dk/cape-dabbrev ()
  "Complete words from buffers after at least three characters.
This is the named, reload-safe equivalent of wrapping `cape-dabbrev'
with `cape-capf-prefix-length'."
  (pcase (cape-dabbrev)
    (`(,beg ,end ,table . ,plist)
     (when (>= (- end beg) 3)
       `(,beg ,end ,table :company-prefix-length t ,@plist)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Language hooks
(defun dk/no-clang-format-p ()
  "Non-nil in a C/C++ buffer whose tree carries no clang-format file.
Used from `apheleia-inhibit-functions'.  Without it apheleia would
reformat every C buffer to clang-format's built-in LLVM style; the
per-buffer `before-save-hook' this replaced was conditional in the same
way.  Both .clang-format and _clang-format are recognised, matching the
clang-format binary.  The ts and classic modes are both listed because
`c-ts-mode' does not derive from `c-mode'."
  (and (derived-mode-p '(c-ts-mode c++-ts-mode c-mode c++-mode))
       (not (or (locate-dominating-file default-directory ".clang-format")
                (locate-dominating-file default-directory "_clang-format")))))

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
;; Waiting for eglot before an xref jump
(defun dk/eglot-managed-p ()
  "Non-nil when Eglot is loaded and manages the current buffer."
  (and (fboundp 'eglot-managed-p)
       (eglot-managed-p)))

(defun dk/eglot-expected-p ()
  "Non-nil when this buffer's major mode is set up to start Eglot.
Walks the mode's parents, so a mode whose `eglot-ensure' hook sits on a
base mode is still recognised.  Checking the hooks rather than a fixed
list of modes means this cannot drift out of step with the `:hook' clause
in dk-programming.el."
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
in a cgo-heavy project -- precisely when the first jump is made.

Waiting here rather than raising `eglot-sync-connect' keeps visiting a
file instant and pays the cost only on the jump that needs it.  Erroring
out afterwards is deliberate: in a mode that has an LSP server the etags
fallback has nothing useful to offer."
  ;; The managed check short-circuits every jump in a connected buffer, which
  ;; is all of them after the first.
  (when (and (not (dk/eglot-managed-p))
             (dk/eglot-expected-p))
    (with-delayed-message (1 "Waiting for the language server...")
      (let ((deadline (+ (float-time) dk/eglot-connect-wait)))
        (while (and (not (dk/eglot-managed-p))
                    (< (float-time) deadline))
          (accept-process-output nil 0.05))))
    (unless (dk/eglot-managed-p)
      (user-error "No language server in this buffer yet; try M-x eglot"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Minibuffer display
(defun dk/minibuffer-small-font ()
  "Shrink the whole minibuffer to `dk/minibuffer-font-height'.
The candidate list included.  A face attribute on `minibuffer-prompt'
does not do this: per
`minibuffer-prompt-properties' that face is put on the prompt string and
nothing else, so vertico's candidates -- which are ordinary buffer text --
kept the full-size `default' face and only the prompt shrank.  Remapping
`default' buffer-locally covers the whole minibuffer window."
  (setq-local face-remapping-alist
              `((default :height ,dk/minibuffer-font-height))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Prose display
(defun dk/prose-display ()
  "Prose-friendly display: soft wrapping and a bit of extra line spacing."
  (visual-line-mode 1)
  (setq-local line-spacing 0.15))

(provide 'dk-functions)
;;; dk-functions.el ends here
