;; -*- lexical-binding: t; -*-

;;; Moving around: files, directories, projects

(use-package recentf
  :ensure nil                           ; built-in
  :custom
  (recentf-max-menu-items 15)
  (recentf-max-saved-items 300)
  :init (recentf-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Dired
(use-package dired
  :ensure nil                           ; built-in
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :config
  (setq dired-listing-switches "-agho --group-directories-first"
        dired-recursive-copies 'always
        dired-recursive-deletes 'always
        dired-dwim-target t
        dired-kill-when-opening-new-dired-buffer t))

(use-package diredfl
  :hook (dired-mode . diredfl-mode))

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
  ;; `project-try-vc' only recognises VC roots.  These markers make a plain
  ;; directory a root too -- and make a subdirectory of a git repo its own
  ;; root, which is what you want in a cabal or cargo workspace.
  (project-vc-extra-root-markers '("*.cabal" "stack.yaml" "Cargo.toml"
                                   "go.mod" "compile_commands.json"))
  (project-list-file (expand-file-name "projects" user-emacs-directory))
  ;; Menu offered right after `project-switch-project'.
  (project-switch-commands '((project-find-file      "Find file")
                             (consult-project-buffer "Buffer")
                             (project-find-dir       "Find dir")
                             (consult-ripgrep        "Ripgrep")
                             (magit-project-status   "Magit")))
  :bind (:map project-prefix-map
              ("b" . consult-project-buffer)
              ("g" . consult-ripgrep))
  :config
  ;; `C-x p' keeps working; `C-c p' is here for the projectile muscle memory.
  ;; Unlike projectile's this is a global binding rather than a minor-mode map,
  ;; so nothing shadows it and project keys can be defined anywhere.
  (keymap-global-set "C-c p" project-prefix-map))

(provide 'dk-navigation)
;;; dk-navigation.el ends here
