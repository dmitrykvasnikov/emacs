;; -*- lexical-binding: t; -*-

;;; Version control

(use-package magit
  :bind (("C-x g" . magit-status)          ; the main git interface for the repo
         ;; Commands scoped to the file being edited: blame, log, stage this
         ;; hunk, checkout this file.
         ("C-c g" . magit-file-dispatch))
  ;; Word-level highlighting inside every diff hunk, not just the one point is
  ;; on -- makes a one-character change in a long line visible at a glance.
  :custom (magit-diff-refine-hunk 'all))

;; Fringe git indicators.  `set-fringe-mode' (dk-ui.el) leaves room for them;
;; on a terminal frame there is no fringe, but `diff-hl-fallback-to-margin'
;; defaults to t and diff-hl moves the indicators to the margin on its own.
;;
;; `:defer 0' rather than a mode hook: `global-diff-hl-mode' has to be called
;; once, and calling it from `:init' would pull diff-hl in on the startup path
;; for the sake of a mode that only matters once a file is open.  At idle 0 it
;; loads just after init and still catches buffers restored during startup,
;; since enabling a globalized minor mode sweeps the existing buffer list.
(use-package diff-hl
  :defer 0
  :hook ((dired-mode         . diff-hl-dired-mode)
         ;; Magit's own revert hooks are wired up by `diff-hl-mode' itself, but
         ;; they only fire for buffers Magit actually reverts -- after a commit
         ;; the rest keep drawing the pre-commit diff until this runs.
         ;; (`diff-hl-magit-pre-refresh', which older snippets pair with this,
         ;; has been an alias for `ignore' since diff-hl 1.11.0.)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  ;; Not just `prog-mode': org, markdown and config files are version
  ;; controlled too.  Non-file buffers and, per `diff-hl-disable-on-remote',
  ;; TRAMP files are skipped -- see `turn-on-diff-hl-mode'.
  (global-diff-hl-mode 1)
  ;; Update the indicators from the buffer text on an idle timer instead of
  ;; only on save.  This is the one part here with a running cost; drop it to
  ;; go back to save-time updates.
  (diff-hl-flydiff-mode 1))

(provide 'dk-vcs)
;;; dk-vcs.el ends here
