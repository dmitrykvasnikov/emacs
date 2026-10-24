;; -*- lexical-binding: t; -*-

;;; Core editing behaviour
;;
;; Everything here is about *how editing behaves*; how it looks is in ui.el.

(require 'dk-vars)                      ; auto-save, backup and lock directories
(require 'dk-functions)                 ; `dk/savehist-strip-kill-ring'

(setq use-short-answers t)              ; y/n instead of typing out yes/no

;; Indent with spaces.  The default t mixed tabs into any line indented 8
;; columns or more.  Modes whose formats need tabs (go-ts-mode, the makefile
;; modes) set it back buffer-locally; a project with a tab convention sets it
;; in its own .dir-locals.el.
(setq-default indent-tabs-mode nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Files, backups and auto-save
;; File locks (.#foo symlinks) warn when another Emacs edits the same file.
;; They are collected in locks/ instead of beside the file, where they showed
;; up in `git status' and set off file watchers.  Every local session applies
;; the same transform, so locking between them still works; for TRAMP files
;; the lock is now local too, so a session on the remote host no longer sees
;; it -- an acceptable loss.
(setq create-lockfiles t)
(make-directory dk/lock-directory t)
(setq lock-file-name-transforms `((".*" ,dk/lock-directory t)))

;; Keep three numbered backups per local file in one git-ignored directory.
;; The regexp matches ordinary absolute paths but not TRAMP names such as
;; /ssh:host:/path, so remote files retain Emacs' normal backup behaviour.
;; `vc-make-backup-files' extends this to version-controlled files -- most of
;; what is edited -- which Emacs otherwise never backs up.  A backup is made
;; at the first save of each visit, so it holds the state before this
;; session's edits, including any not yet committed.
(make-directory dk/backup-directory t)
(setq make-backup-files t
      vc-make-backup-files t
      backup-directory-alist `(("\\`/[^/:]+/" . ,dk/backup-directory))
      version-control t
      kept-new-versions 3
      kept-old-versions 0
      delete-old-versions t)

;; Auto-save recovery files (#foo#) still exist -- they are what `M-x
;; recover-this-file' reads after a crash -- but they are all collected in
;; autosave/ instead of being littered next to the file being edited.  The
;; directory has to exist before the first auto-save; `make-directory' with a
;; non-nil second argument is a no-op when it already does.  The trailing t in
;; the transform is the UNIQUIFY flag: the full path is mangled into the file
;; name, so src/foo.el and test/foo.el cannot collide in one flat directory.
(make-directory dk/auto-save-directory t)
(setq auto-save-file-name-transforms `((".*" ,dk/auto-save-directory t)))

(setq vc-follow-symlinks t)             ; visit the target, don't ask every time

;; Deletions go to the freedesktop trash instead of being unlinked, so a
;; mis-typed dired `D' is recoverable.  Disabled in batch runs, where there is
;; nobody to empty the trash and no desktop session to own it.
(setq delete-by-moving-to-trash (not noninteractive))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Global minor modes
(delete-selection-mode 1)               ; typing replaces the active region
;; 100 entries (the default) is little for a history that now survives restarts
;; and is read back by consult-history, M-y and the C-r prompts.
(setq history-length 1000)
(savehist-mode 1)                       ; persist minibuffer history across sessions
;; Save histories that are not minibuffer histories themselves.  In
;; particular, `M-y' reads `kill-ring', which Savehist does not persist by
;; default.  The ring sizes below are the only limits: the rings trim
;; themselves, so savehist gets no separate cap that could disagree.
;;
;; Persisting the kill ring is a deliberate choice: anything copied --
;; passwords included -- is written in plain text to the history file.
;; `dk/savehist-strip-kill-ring' drops text properties first, so the file holds
;; plain strings rather than every entry's font-lock faces.
(setq kill-ring-max 200
      search-ring-max 100
      regexp-search-ring-max 100)
(dolist (variable '(kill-ring search-ring regexp-search-ring))
  (add-to-list 'savehist-additional-variables variable))
(add-hook 'savehist-save-hook #'dk/savehist-strip-kill-ring)
(save-place-mode 1)                     ; reopen files at the point last left there
(global-auto-revert-mode 1)             ; reload files changed on disk (e.g. by git)
(repeat-mode 1)                         ; repeat a chord's last key alone: C-x o o o
(winner-mode 1)                         ; C-c <left>/<right> undo window changes
(electric-pair-mode 1)                  ; insert the closing ) " ] automatically

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bells and undo
;;
;; No bell at all: nil `visible-bell' alone would fall back to the audible one,
;; so the ring function is replaced by `ignore' as well.
(setq visible-bell nil)
(setq ring-bell-function #'ignore)

;; Undo history limits, 13x the stock values -- generous enough that a long
;; editing session is not truncated mid-way.  Emacs discards the oldest undo
;; entries past `undo-limit', tries harder past `undo-strong-limit', and drops
;; the history of a single huge change outright past `undo-outer-limit'.
(setq undo-limit (* 13 160000)          ; ~2MB: start discarding old entries
      undo-strong-limit (* 13 240000)   ; ~3MB: discard even a change in progress
      undo-outer-limit (* 13 24000000)) ; ~300MB: refuse one absurd change

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Search
;;
;; The search keys are split on purpose: C-s is `consult-line' (a minibuffer
;; list of matching lines -- see dk-completion.el) and C-r stays the stock
;; `isearch-backward'.  They are different interfaces, so C-r after C-s does
;; not reverse a search, and only isearch feeds the persisted `search-ring';
;; consult-line keeps its own history.  These settings therefore reach
;; isearch through C-r and through the commands that start one themselves
;; (isearch-forward-symbol-at-point, the C-M-s regexp searches, dired's C-s).
(setq isearch-allow-scroll t)           ; scroll commands don't exit the search
(setq isearch-lazy-count t)             ; "3/17" in the prompt while typing
(setq isearch-wrap-pause 'no-ding)      ; wrap past the end silently, no extra C-s
(setq isearch-repeat-on-direction-change t) ; C-r after C-s moves off the current match

;; Keep files pleasant to consume outside Emacs and make accidental missing
;; final newlines visible to version-control tools.
(setq require-final-newline t)
(add-hook 'prog-mode-hook
          (lambda ()
            (setq-local show-trailing-whitespace t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Editing helpers.  The binding lives here rather than in dk-keymap.el so that
;; `:bind' can autoload the package instead of loading it at startup.
(use-package expand-region
  :bind (("C-=" . er/expand-region)
         ("C-c v" . er/expand-region))) ; terminal-safe alternate: no C-= there

;; Edit several occurrences or lines at once.  Use Eglot's semantic rename for
;; program symbols; these commands are for deliberately textual transformations.
;; Mark-all sits on a `C-c <letter>' key, which Emacs reserves for the user:
;; `C-c ;' (its old key) belongs to major modes, and org takes it for
;; `org-toggle-comment'.
(use-package multiple-cursors
  :bind (("C->"   . mc/mark-next-like-this)
         ("C-<"   . mc/mark-previous-like-this)
         ("C-c A" . mc/mark-all-like-this)
         ("C-c l" . mc/edit-lines)
         ;; Terminal-safe alternates: a terminal cannot send C-> or C-<.
         ("C-c n" . mc/mark-next-like-this)
         ("C-c N" . mc/mark-previous-like-this)))

;; Inspect and move through the buffer's ordinary undo history as a tree.  This
;; does not replace the undo implementation or need a permanent minor mode;
;; C-/ and C-_ remain the quick linear undo keys.
(use-package vundo
  :bind ("C-x u" . vundo)
  :custom (vundo-glyph-alist vundo-unicode-symbols))

(provide 'dk-defaults)
;;; dk-defaults.el ends here
