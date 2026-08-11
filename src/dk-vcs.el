;; -*- lexical-binding: t; -*-

;;; Version control

(use-package magit
  :bind (("C-x g" . magit-status)
         ("C-c g" . magit-file-dispatch))
  :custom (magit-diff-refine-hunk 'all))

(use-package diff-hl                       ; fringe git indicators
  :hook ((prog-mode  . diff-hl-mode)
         (dired-mode . diff-hl-dired-mode)))

(provide 'dk-vcs)
;;; dk-vcs.el ends here
