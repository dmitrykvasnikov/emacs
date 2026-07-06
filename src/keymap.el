;; -*- lexical-binding: t; -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Keyboard mappings

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
(global-set-key (kbd "C-x C-b") #'ibuffer)
(global-set-key (kbd "M-o") #'other-window)
(global-set-key (kbd "M-/") #'comment-or-uncomment-region)
(global-set-key (kbd "C-c t") #'consult-theme)
(global-set-key (kbd "S-<return>") (kbd "C-e C-m"))
(global-set-key (kbd "C-=") #'er/expand-region)
(global-set-key (kbd "M-u") #'upcase-dwim)
(global-set-key (kbd "M-l") #'downcase-dwim)
(global-set-key (kbd "M-c") #'capitalize-dwim)
(global-set-key (kbd "C-c r") #'cua-mode)
(global-set-key (kbd "M-x") #'dk/M-x-dwim)
(global-set-key (kbd "C-c k") (lambda() (interactive) (kill-buffer (current-buffer))))
(global-set-key (kbd "C-c e") #'eval-buffer)

(provide 'keymap)
;;; keymap.el ends here
