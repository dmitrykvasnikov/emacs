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
(use-package projectile
  :init
  (setq projectile-auto-discover t)
  (setq projectile-track-known-projects-automatically t)   ; auto-add projects
  (setq projectile-cache-file (expand-file-name "projectile.cache" user-emacs-directory))
  (setq projectile-completion-system 'default)
  (setq projectile-indexing-method 'alien)                 ; faster on Unix
  (projectile-mode +1)
  :bind (:map projectile-mode-map
              ("C-c p" . projectile-command-map))
  :config
  (add-to-list 'projectile-globally-ignored-buffers "*projectile-files-errors*")
  (add-to-list 'projectile-globally-ignored-buffers "EGLOT*"))

;; These have to go into `projectile-command-map', not the global map: the
;; `C-c p' prefix is claimed by `projectile-mode-map', a minor-mode map, which
;; shadows any global binding that starts with `C-c p'.
(use-package consult-projectile
  :after projectile
  :bind (:map projectile-command-map
              ("f" . consult-projectile-find-file)
              ("p" . consult-projectile-switch-project)
              ("b" . consult-projectile-switch-to-buffer)
              ("d" . consult-projectile-find-dir)))

(provide 'dk-navigation)
;;; dk-navigation.el ends here
