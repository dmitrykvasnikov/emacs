;; -*- lexical-binding: t; -*-

;;; Core editing behaviour
;;
;; Everything here is about *how editing behaves*; how it looks is in ui.el.

(require 'dk-vars)                      ; `dk/auto-save-directory'

(setq use-short-answers t)              ; y/n instead of typing out yes/no

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Files, backups and auto-save
(setq make-backup-files nil)            ; no foo~ next to the file
(setq create-lockfiles nil)             ; no .#foo (they confuse file watchers)

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
;; These reach isearch through C-r and through the commands that start one
;; themselves (isearch-forward-symbol-at-point, the C-M-s regexp searches,
;; dired's C-s).  C-s itself is `consult-line' -- see dk-completion.el -- so
;; the forward search does not go through here.
(setq isearch-allow-scroll t)           ; scroll commands don't exit the search
(setq isearch-lazy-count t)             ; "3/17" in the prompt while typing
(setq isearch-wrap-pause 'no-ding)      ; wrap past the end silently, no extra C-s
(setq isearch-repeat-on-direction-change t) ; C-r after C-s moves off the current match

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Editing helpers.  The binding lives here rather than in dk-keymap.el so that
;; `:bind' can autoload the package instead of loading it at startup.
(use-package expand-region
  :bind ("C-=" . er/expand-region))

(provide 'dk-defaults)
;;; dk-defaults.el ends here
