;; -*- lexical-binding: t; -*-

;;; Moving around: files, directories, projects

(require 'dk-vars)                      ; ignored and excluded directories
(require 'dk-functions)                 ; `dk/dired-remote-safety', recentf helpers

;; Jump straight to visible text using short on-screen hint keys.  M-g c is the
;; natural replacement for the rarely-used numeric `goto-char'; that command
;; remains available through M-x.
(use-package avy
  :bind ("M-g c" . avy-goto-char-timer))

;; The list of recently visited files, persisted across sessions.  It is what
;; backs `consult-recent-file' (C-x C-r) and the recent-file section of
;; `consult-buffer'.
;;
;; Files nobody reopens by name are kept out: package sources visited through
;; M-., backups and auto-saves, scratch files in /tmp and commit messages.
;; The list is otherwise written only when Emacs exits cleanly, which the
;; daemon rarely does, so an idle timer also saves it every five minutes; the
;; old timer is cancelled first so that reloading this module keeps one.
(use-package recentf
  :ensure nil                           ; built-in
  :custom
  (recentf-max-menu-items 15)           ; entries shown in the File menu
  (recentf-max-saved-items 300)         ; entries kept in the file on disk
  (recentf-exclude
   `(,(dk/recentf-directory-regexp package-user-dir)
     ,(dk/recentf-directory-regexp dk/backup-directory)
     ,(dk/recentf-directory-regexp dk/auto-save-directory)
     ,(dk/recentf-directory-regexp temporary-file-directory)
     "/COMMIT_EDITMSG\\'"))
  :init (recentf-mode)
  :config
  (when (timerp dk/recentf-save-timer)
    (cancel-timer dk/recentf-save-timer))
  (setq dk/recentf-save-timer
        (run-with-idle-timer 300 t #'dk/recentf-save-quietly)))

;; C-x C-b opens ibuffer (dk-keymap.el), usually in another window -- right
;; where M-o is pressed to get back.  ibuffer's own M-o is
;; `ibuffer-visit-buffer-1-window', which visits the buffer at point and
;; deletes every other window; restore the global `other-window' instead.
;; The shadowed command stays on M-x and ibuffer's menu.
(use-package ibuffer
  :ensure nil                           ; built-in
  :bind (:map ibuffer-mode-map
              ("M-o" . other-window)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Dired
(use-package dired
  :ensure nil                           ; built-in
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))      ; open dired on the current file's directory
  ;; Remote buffers ask before a recursive delete; see `dk/dired-remote-safety'.
  :hook (dired-mode . dk/dired-remote-safety)
  :config
  ;; Flags handed to ls(1): -a all files, -g like -l but without the owner
  ;; column, -h human-readable sizes, -o without the group column.
  ;; --group-directories-first is GNU ls only: a BSD/macOS host reached over
  ;; TRAMP needs it dropped (or GNU coreutils installed there).
  (setq dired-listing-switches "-agho --group-directories-first"
        ;; Recurse into directories on C/D without asking "recursive?" each
        ;; time.  Deletes are safe to recurse because they go to the trash
        ;; (dk-defaults.el); remote buffers, which have no trash, override
        ;; this with 'top from `dk/dired-remote-safety'.
        dired-recursive-copies 'always
        dired-recursive-deletes 'always
        ;; With two dired windows open, the other one's directory is the default
        ;; target for copy and rename -- a two-pane file manager.
        dired-dwim-target t
        ;; Entering a subdirectory reuses the window's buffer instead of
        ;; leaving one dired buffer behind per directory visited.
        dired-kill-when-opening-new-dired-buffer t))

;; Colour dired listings by file type, permissions, size and date.
(use-package diredfl
  :hook (dired-mode . diredfl-mode))

;; File-type icons in the listing, from the same nerd-icons set as the modeline.
(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Projects
;;
;; project.el rather than projectile: eglot already roots itself with
;; `project-current', so projectile was a second, independently-configured
;; notion of "the project" that could disagree with it.  Everything the old
;; setup used has a direct equivalent, and consult's project commands are
;; project.el-aware already.
(use-package project
  :ensure nil                           ; built-in
  :demand t
  :custom
  ;; `project-try-vc' only recognises VC roots.  These markers exist to give a
  ;; directory outside any repository a root.  The nearest marker wins, so
  ;; they are workspace-level files only: a per-package marker (Cargo.toml,
  ;; *.cabal, go.mod) would make every workspace member its own project, and
  ;; eglot -- which uses the project root as the server root -- would start
  ;; one LSP server per member.  Inside git the repository root, or a
  ;; workspace file below it, stays the root.  The cost: a lone crate outside
  ;; git becomes a project only once its first build writes Cargo.lock, and a
  ;; lone cabal package outside git needs a cabal.project.
  (project-vc-extra-root-markers '("cabal.project" "stack.yaml" "Cargo.lock"
                                   "go.work" "compile_commands.json"))
  ;; Build output kept out of C-x p f and C-x p d.  `project-files' reaches the
  ;; file list two different ways and this is the one setting both of them
  ;; honour: at the VC root it becomes a `:(exclude,glob,top)' pathspec on
  ;; `git ls-files', and anywhere else -- a root found by a marker above rather
  ;; than by git, say a cabal workspace outside any repository -- it comes back
  ;; through `project-ignores' into the find(1) call.  See dk-vars.el for why a
  ;; net is needed at all when .gitignore already exists.
  ;;
  ;; The trailing slash is load-bearing -- without it git gets `**/dist-newstyle',
  ;; which matches the directory but not the files inside it, and the whole
  ;; setting quietly does nothing.  find(1) prunes either way.
  (project-vc-ignores (mapcar (lambda (dir) (concat dir "/"))
                              dk/project-ignored-directories))
  ;; Menu offered right after `project-switch-project'.
  (project-switch-commands '((project-find-file      "Find file")
                             (consult-project-buffer "Buffer")
                             (project-find-dir       "Find dir")
                             (consult-ripgrep        "Ripgrep")
                             (magit-project-status   "Magit")))
  ;; Replace two project.el commands under C-x p with their consult versions,
  ;; which get preview and orderless filtering: C-x p b and C-x p g.
  :bind (:map project-prefix-map
              ("b" . consult-project-buffer)
              ("g" . consult-ripgrep))
  :config
  ;; `C-x p' keeps working; `C-c p' is here for the projectile muscle memory.
  ;; Unlike projectile's this is a global binding rather than a minor-mode map,
  ;; so nothing shadows it and project keys can be defined anywhere.
  (keymap-global-set "C-c p" project-prefix-map))

;; The same directories kept out of the grep-based searches: `project-find-regexp'
;; (C-x p r) and `rgrep' build their find(1) command from this list.  Appended
;; rather than assigned -- the stock value is the VCS metadata directories, which
;; still need skipping.
(use-package grep
  :ensure nil                           ; built-in
  :defer t
  :config
  (dolist (dir dk/project-ignored-directories)
    (add-to-list 'grep-find-ignored-directories dir)))

(provide 'dk-navigation)
;;; dk-navigation.el ends here
