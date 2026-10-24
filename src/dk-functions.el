;; -*- lexical-binding: t; -*-

;;; My functions
;;
;; Named helpers used from :hook / :custom clauses elsewhere.  Keeping them
;; named (instead of inline lambdas) means a hook can be removed again and a
;; module can be re-loaded without stacking duplicates.

(require 'cl-lib)                       ; `cl-letf' in `dk/escape-quit-keep-windows'
(require 'dk-vars)                      ; shared command and hook settings

;; Called only under a `derived-mode-p' guard, so org is loaded by then; this
;; just keeps the byte-compiler quiet about it.
(declare-function org-at-table-p "org" (&optional table-type))
(declare-function org-table-copy-down "org-table" (n))
(declare-function cape-dabbrev "cape" (&optional interactive))
(declare-function dk/add-to-confdir "../early-init" (relative-path))
(declare-function eglot-managed-p "eglot" ())
(declare-function recentf-save-list "recentf" ())
(declare-function face-remap-remove-relative "face-remap" (cookie))
(declare-function gfm-mode "markdown-mode" ())
(declare-function gfm-view-mode "markdown-mode" ())
(declare-function markdown-mode "markdown-mode" ())
(declare-function markdown-view-mode "markdown-mode" ())

(defvar corfu-auto)
(defvar recentf-mode)
(defvar go-ts-mode-indent-offset)

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

(defun dk/dired-remote-safety ()
  "Ask before recursive deletes in a remote Dired buffer.
Locally `delete-by-moving-to-trash' makes `dired-recursive-deletes'
\\='always safe: a deleted tree can be restored from the trash.  Over
TRAMP there is no trash and the delete is permanent, so make Dired ask
\"Recursively delete?\" for each top-level directory there."
  (when (file-remote-p default-directory)
    (setq-local dired-recursive-deletes 'top)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Persisted histories
(defun dk/savehist-strip-kill-ring ()
  "Remove text properties from the string entries of `kill-ring'.
Run from `savehist-save-hook', so the history file holds plain strings
instead of each entry's font-lock faces.  The entries are replaced in
place, which keeps `kill-ring-yank-pointer' (a tail of the same list)
valid.  Trade-off: the live entries lose their properties too, such as a
`yank-handler', at each save -- yanking them later inserts plain text."
  (let ((tail kill-ring))
    (while tail
      (when (stringp (car tail))
        (setcar tail (substring-no-properties (car tail))))
      (setq tail (cdr tail)))))

(defun dk/recentf-directory-regexp (directory)
  "Return a regexp matching file names under DIRECTORY, for `recentf-exclude'.
recentf abbreviates names before checking them (~/... rather than
/home/...), so both the expanded and the abbreviated spelling match."
  (let ((dir (file-name-as-directory (expand-file-name directory))))
    (concat "\\`"
            (regexp-opt (delete-dups (list dir (abbreviate-file-name dir)))))))

(defun dk/recentf-save-quietly ()
  "Save the recent-file list without a message in the echo area.
Run from the idle timer in `dk/recentf-save-timer', so a crash of a
long-running daemon loses at most a few minutes of recent files."
  (when recentf-mode
    (let ((inhibit-message t))
      (recentf-save-list))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helpful helpers
(defun dk/helpful-open (buf)
  "Display helpful buffer BUF, reusing a helpful window when there is one.
From inside a helpful buffer -- following a link -- BUF replaces it in the
same window.  Elsewhere, a visible helpful window is reused; failing that
the frame is split, to the right when the current window has full frame
width and below otherwise; and if the frame is too small to split, the
current window is used.  Point stays where it was, so the docs can be read
and dismissed without moving into them.  Going through `display-buffer'
records quit-restore parameters, so q in the helpful window steps back
through the helpful buffers it has shown and, once at the first, deletes
the window it was split into.
`helpful-switch-buffer-function' is called after `helpful-update' has
already run inside BUF, and its return value is discarded, so declining
to select the window is safe."
  (if (derived-mode-p 'helpful-mode)
      (pop-to-buffer-same-window buf)
    (display-buffer
     buf `((display-buffer-reuse-mode-window
            display-buffer-in-direction
            display-buffer-same-window)
           (mode . helpful-mode)
           (direction . ,(if (window-full-width-p) 'right 'below))))))

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

(defun dk/escape-quit-keep-windows (orig-fun &rest args)
  "Run ORIG-FUN (`keyboard-escape-quit') without deleting windows.
Around advice.  When there is nothing else to cancel,
`keyboard-escape-quit' falls through to `delete-other-windows'; claiming
the frame already has a single window skips that branch and leaves the
layout alone.  Every earlier branch -- region, minibuffer, prefix
argument, recursive edit -- still runs."
  (cl-letf (((symbol-function 'one-window-p) #'always))
    (apply orig-fun args)))

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
(defun dk/apheleia-inhibit-p ()
  "Non-nil when apheleia should not format the current buffer on save.
Used from `apheleia-inhibit-functions', so formatting is opt-in per tree
for the languages whose formatter would otherwise impose one style on
every project:

- C/C++ without a .clang-format or _clang-format file in a dominating
  directory.  Otherwise every C buffer would be reformatted to
  clang-format's built-in LLVM style.  Both names are recognised,
  matching the clang-format binary, and the ts and classic modes are both
  listed because `c-ts-mode' does not derive from `c-mode'.
- Haskell (`haskell-mode', and `haskell-ts-mode', which registers it as a
  parent) without a fourmolu.yaml in a dominating directory.  A project
  formatted with ormolu, stylish-haskell or by hand would otherwise be
  rewritten in fourmolu's default style on its first save.
- Every `lisp-data-mode' buffer, which covers `emacs-lisp-mode' and
  `lisp-interaction-mode'.  apheleia's lisp-indent re-indents the whole
  file, turning each save into a diff over lines that were never touched.

apheleia consults this when it turns `apheleia-mode' on for a buffer, so
a configuration file added later takes effect after \\[revert-buffer]."
  (cond
   ((derived-mode-p '(c-ts-mode c++-ts-mode c-mode c++-mode))
    (not (or (locate-dominating-file default-directory ".clang-format")
             (locate-dominating-file default-directory "_clang-format"))))
   ((derived-mode-p '(haskell-mode haskell-ts-mode))
    (not (locate-dominating-file default-directory "fourmolu.yaml")))
   ((derived-mode-p 'lisp-data-mode))))

(defun dk/go-ts-tab-width ()
  "Display a tab as wide as one `go-ts-mode' indentation step.
Go indents with tabs (gofmt rewrites leading whitespace to one tab per
level), while `go-ts-mode-indent-offset' is the step Emacs indents by as
you type.  With the default `tab-width' of 8 and a step of 4, a typed
first level came out as four spaces, gofmt turned it into a tab drawn 8
wide, and indentation jumped on every save.  Matching the two makes one
level one tab, displayed at the configured width; the file is unchanged."
  (setq-local tab-width go-ts-mode-indent-offset))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Wait only for a server that has actually started initializing.  A mode hook
;; alone says nothing about connection state (the user may have shut it down).
(defun dk/eglot-server-initialized (server)
  "Remember SERVER while it initializes for the current buffer."
  (setq dk/eglot-connecting-server server))

(defun dk/eglot-forget-connecting-server ()
  "Forget the startup wait when Eglot starts or stops managing this buffer."
  (setq dk/eglot-connecting-server nil))

(defun dk/eglot-managed-p ()
  "Non-nil when Eglot manages the current buffer."
  (and (fboundp 'eglot-managed-p) (eglot-managed-p)))

(defun dk/eglot-connecting-p ()
  "Non-nil while this buffer's initializing server is still running."
  (and dk/eglot-connecting-server
       (not (dk/eglot-managed-p))
       (fboundp 'jsonrpc-running-p)
       (jsonrpc-running-p dk/eglot-connecting-server)))

(defun dk/xref-wait-for-eglot (&rest _)
  "Wait briefly for an initializing server, then allow normal xref lookup.
Disconnected, failed and deliberately stopped servers do not block other
backends.  C-g can interrupt the wait."
  (when (dk/eglot-connecting-p)
    (with-delayed-message (1 "Waiting for the language server...")
      (let ((deadline (+ (float-time) dk/eglot-connect-wait)))
        (while (and (dk/eglot-connecting-p) (< (float-time) deadline))
          (accept-process-output nil 0.05))))))

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
  "Prose-friendly display: soft wrapping, a bit of extra line spacing,
and no automatic completion popup.  In prose nearly every word has
dabbrev candidates, so `corfu-auto' would pop up after each one; TAB and
M-TAB still complete on demand.  Setting it buffer-locally from the
major-mode hook is enough: `global-corfu-mode' turns `corfu-mode' on only
after the mode hooks have run, and corfu reads `corfu-auto' at that point."
  (visual-line-mode 1)
  (setq-local line-spacing 0.15)
  (setq-local corfu-auto nil))

(defun dk/markdown-toggle-view ()
  "Switch between editing Markdown and its read-only rendered view.
From `gfm-mode' (or plain `markdown-mode') enter `gfm-view-mode' (or
`markdown-view-mode'); from either view mode return to the matching
editing mode.  `gfm-view-mode' derives from `gfm-mode', not from
`markdown-view-mode', so both view modes are tested for, and before
`gfm-mode'.  The view modes turn on `read-only-mode', which a major-mode
switch does not undo, so on the way back `buffer-read-only' is restored
from the file's own permissions.  That happens before the switch, not
after: `global-corfu-mode' skips read-only buffers when the new mode
starts, and would otherwise leave corfu off in the editing buffer."
  (interactive)
  (cond
   ((derived-mode-p '(gfm-view-mode markdown-view-mode))
    (setq buffer-read-only
          (and buffer-file-name (not (file-writable-p buffer-file-name))))
    (if (derived-mode-p 'gfm-view-mode) (gfm-mode) (markdown-mode)))
   ((derived-mode-p 'gfm-mode) (gfm-view-mode))
   (t (markdown-view-mode))))

(provide 'dk-functions)
;;; dk-functions.el ends here
