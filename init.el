;;; init.el --- Initialization file for Emacs -*- lexical-binding: t -*-
;; Author: Dmitry Kvasnikov

;;; Commentary:
;;Emacs Startup File --- initialization for Emacs

;;; Code:

;; UI Settings
(tool-bar-mode 0)                    ;; no tool bar
(menu-bar-mode 0)                    ;; no menu bar
;;(toggle-frame-fullscreen)            ;; start with fullscreen
(scroll-bar-mode 0)                  ;; no scrollbar
(show-paren-mode 1)                  ;; highlight matchin parenthesis
(column-number-mode 1)               ;; show column number in minibuffer
(display-line-numbers-mode 1)	     ;; display line numbers ...
(setq display-line-numbers-type 'relative)
                                     ;; ... and make it relative
(global-display-line-numbers-mode 1) ;; display line numbers
(setq inhibit-startup-message t)     ;; no splashscreen
(fset `yes-or-no-p `y-or-n-p)        ;; answer questions with y/n (instead of
				     ;; yes/no)

(setq-default initial-scratch-message ";; He who walks alone  ... Always walks uphill but ... Beneath his feet are the ... Broken bones of flawed men ...\n\n")

;; Fonts
(set-face-attribute 'default nil
		    :font "Aporetic Sans Mono"
		    :height 120)
;; Set minibuffer font
(set-face-attribute 'minibuffer-prompt nil
                    :family "Aporetic Sans Mono"
                    :height 120)

;; Auto-refresh buffers when files on disk change.
(global-auto-revert-mode t)

;; Initialize package management
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Ensure 'use-package' is installed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(require 'use-package-ensure)

;; when installing package, it will be always downloaded automatically from
;; repository if is not available
(setq use-package-always-ensure t)
(setq use-package-always-defer nil)
(setq use-package-verbose t)
(setq use-package-compute-statistics t)

;; Packages installation
(use-package recentf
  :init
  (recentf-mode))

(use-package doom-modeline
  :init (doom-modeline-mode 1))

(use-package vertico
  :hook (after-init . vertico-mode)
  :init (vertico-mode)
  :custom
  (vertico-count 8)
  (vertico-cycle t)
  (vertico-resize nil)
  (vertico-scroll-margin 0))

(use-package orderless
  :after vertico
  :custom
  (completion-category-defaults nil)
  (completion-styles '(orderless partial-completion))
  (completion-category-overrides '((file (styles . (partial-completion))))))

(use-package marginalia
  :after vertico
  :init
  (marginalia-mode))

(use-package savehist
  :init
  (savehist-mode))

(use-package which-key
  :init
  (which-key-mode))

;; Windows navigation
(windmove-default-keybindings)

;; Icons
;;(use-package treemacs-all-the-icons)
(use-package all-the-icons)
(add-hook 'dired-mode-hook 'all-the-icons-dired-mode)

;;Keyboard mappings
(global-set-key (kbd "C-x C-r") 'recentf-open)
(global-set-key (kbd "C-x C-b") 'ibuffer)
(global-set-key (kbd "M-/") 'comment-or-uncomment-region)
(global-set-key (kbd "C-M-s") 'window-toggle-side-windows)
(global-set-key (kbd "C-; t") 'ef-themes-select)

;; Auto-save on change
(defun save-buffer-if-visiting-file (&optional args)
   "Save the current buffer only if it is visiting a file"
   (interactive)
   (if (and (buffer-file-name) (buffer-modified-p))
       (save-buffer args)))
(add-hook 'auto-save-hook 'save-buffer-if-visiting-file)
(setq auto-save-interval 1)

;; Install and configure themes
(use-package dracula-theme)
(use-package ef-themes)
(load-theme 'dracula t)

;; Switch between Emacs windows
(use-package ace-window
  :config
  (global-set-key (kbd "M-o") 'ace-window))

;; Delete selection
(delete-selection-mode t)

;; Files navigation
(setq vc-follow-symlinks t)		;; Follow symlinks without confirmation

;; Switch to treemacs
(defvar previous-window nil
  "Variable to store the previous window.")

(defun switch-to-treemacs ()
  "Switch to the Treemacs window."
  (interactive)
  (if (eq (selected-window) (treemacs-get-local-window))
      (when previous-window
        (select-window previous-window)
        (setq previous-window nil))
    (progn
      (setq previous-window (selected-window))
      (let ((treemacs-win (treemacs-get-local-window)))
        (when treemacs-win
          (select-window treemacs-win))))))

(global-set-key (kbd "M-t") 'switch-to-treemacs)


;; Haskell Mode configuration

(use-package ormolu)

(use-package haskell-mode
  :config
  (define-key haskell-mode-map (kbd "C-c C-c") 'haskell-compile)
  (define-key haskell-cabal-mode-map (kbd "C-c C-c") 'haskell-compile)
  )

(with-eval-after-load 'haskell-mode
  (define-key haskell-mode-map (kbd "C-f") 'ormolu-format-buffer)
  (define-key haskell-mode-map (kbd "C-M-x") 'haskell-interactive-bring))

;; Hook to bind formatting to C-f in haskell-mode
(add-hook 'haskell-mode-hook
          (lambda ()
            (local-set-key (kbd "C-f") 'ormolu-format-buffer)))


(use-package lsp-mode
  :hook ((css-mode
	  js2-mode
	  html-mode
	  json-mode
	  java-mode
	  typescript-mode
	  haskell-mode) . lsp-deferred)
  :commands lsp lsp-deferred
  :config
  (setq lsp-haskell-process-path-hie "haskell-language-server-wrapper")
  (setq lsp-haskell-process-args-hie '("-d" "-l" "/tmp/hls.log"))
  (setq lsp-enable-snippet nil) ;; Disable snippet support
  (setq lsp-auto-configure t)
  (setq lsp-lens-place-position 'above-line)
  :custom
  ;; (lsp-log-io nil)
  ;; (lsp-keep-workspace-alive nil)
  ;; (lsp-semantic-tokens-enable nil)
  ;; (lsp-session-file "~/.emacs.d/.lsp-session-v1")
  
  ;; (lsp-enable-xref t)
  ;; (lsp-enable-links t)
  ;; (lsp-enable-imenu nil)
  ;; (lsp-enable-indentation nil)
  ;; (lsp-eldoc-enable-hover nil)
  ;; (lsp-enable-file-watchers nil)
  ;; (lsp-enable-symbol-highlighting t)
  ;; (lsp-enable-on-type-formatting nil)
  ;; (lsp-enable-text-document-color nil)
  ;; (lsp-enable-suggest-server-download t)

  ;; (lsp-ui-doc-enable nil)
  ;; (lsp-ui-sideline-delay 0)
  ;; (lsp-ui-sideline-show-hover nil)
  ;; (lsp-ui-sideline-update-mode 'line)
  ;; (lsp-ui-sideline-diagnostic-max-lines 20)
  
  ;; (lsp-signature-auto-activate nil)
  ;; (lsp-signature-render-documentation nil)

  ;; (lsp-modeline-diagnostics-enable nil)
  ;; (lsp-modeline-code-actions-enable nil)
  ;; (lsp-modeline-workspace-status-enable nil)
  
  ;; (lsp-headerline-breadcrumb-enable nil)
  ;; (lsp-headerline-breadcrumb-icons-enable nil)
  ;; (lsp-headerline-breadcrumb-enable-diagnostics nil)
  ;; (lsp-headerline-breadcrumb-enable-symbol-numbers nil)
  
  (lsp-completion-show-kind t)
  (lsp-completion-provider :none)
  (lsp-diagnostics-provider :flycheck))

;; Install and configure lsp-haskell
(use-package lsp-haskell
  :config
  (setq lsp-haskell-server-path "haskell-language-server-wrapper")
  )

(use-package lsp-ui
  :after lsp-mode
  :hook (lsp-mode . lsp-ui-mode)
  :config
  (setq lsp-ui-peek-enable t)
  (setq lsp-ui-doc-position 'at-point)
  (define-key lsp-ui-mode-map (kbd "M-.") #'lsp-ui-peek-find-definitions)
  (define-key lsp-ui-mode-map (kbd "M-?") #'lsp-ui-peek-find-references))

(use-package flycheck
  :hook (after-init . global-flycheck-mode)
  :custom
  (flycheck-help-echo-function nil)
  (flycheck-display-errors-delay 0.0)
  (flycheck-auto-display-errors-after-checking t))

(use-package popup)

(use-package flycheck-popup-tip)
(use-package flycheck-pos-tip)

(eval-after-load 'flycheck
 (if (display-graphic-p)
     (flycheck-pos-tip-mode)
     (flycheck-popup-tip-mode)))

;;(setq flycheck-pos-tip-display-errors-tty-function #'flycheck-popup-tip-show-popup)
;;(flycheck-pos-tip-mode)
;; Install and configure company-mode
(use-package company
  :hook (prog-mode . company-mode)
  :init
  (setq company-minimum-prefix-length 2
        company-tooltip-limit 14
        company-tooltip-align-annotations t
        company-require-match 'never
        company-idle-delay 0.26
	company-frontends)
  :config
  (define-key company-active-map (kbd "<escape>") #'hide-company-tooltip)
  (define-key company-active-map (kbd "<return>") #'company-complete-selection)
  (define-key company-active-map (kbd "RET") #'company-complete-selection)
  (define-key company-active-map (kbd "<tab>") #'company-complete-selection)
  (define-key company-active-map (kbd "TAB") #'company-complete-selection))

(use-package company-box
  :hook (company-mode . company-box-mode)
  :config
  (setq company-box-show-single-candidate t
        company-box-backends-colors nil
        company-box-tooltip-limit 50
        company-box-icons-alist 'company-box-icons-nerd-icons
        ;; Move company-box-icons--elisp to the end, because it has a catch-all
        ;; clause that ruins icons from other backends in elisp buffers.
        company-box-icons-functions
        (cons #'+company-box-icons--elisp-fn
              (delq 'company-box-icons--elisp
                    company-box-icons-functions))
        company-box-icons-nerd-icons
        `((Unknown        . ,(nerd-icons-codicon  "nf-cod-code"                :face  'font-lock-warning-face))
          (Text           . ,(nerd-icons-codicon  "nf-cod-text_size"           :face  'font-lock-doc-face))
          (Method         . ,(nerd-icons-codicon  "nf-cod-symbol_method"       :face  'font-lock-function-name-face))
          (Function       . ,(nerd-icons-codicon  "nf-cod-symbol_method"       :face  'font-lock-function-name-face))
          (Constructor    . ,(nerd-icons-codicon  "nf-cod-triangle_right"      :face  'font-lock-function-name-face))
          (Field          . ,(nerd-icons-codicon  "nf-cod-symbol_field"        :face  'font-lock-variable-name-face))
          (Variable       . ,(nerd-icons-codicon  "nf-cod-symbol_variable"     :face  'font-lock-variable-name-face))
          (Class          . ,(nerd-icons-codicon  "nf-cod-symbol_class"        :face  'font-lock-type-face))
          (Interface      . ,(nerd-icons-codicon  "nf-cod-symbol_interface"    :face  'font-lock-type-face))
          (Module         . ,(nerd-icons-codicon  "nf-cod-file_submodule"      :face  'font-lock-preprocessor-face))
          (Property       . ,(nerd-icons-codicon  "nf-cod-symbol_property"     :face  'font-lock-variable-name-face))
          (Unit           . ,(nerd-icons-codicon  "nf-cod-symbol_ruler"        :face  'font-lock-constant-face))
          (Value          . ,(nerd-icons-codicon  "nf-cod-symbol_field"        :face  'font-lock-builtin-face))
          (Enum           . ,(nerd-icons-codicon  "nf-cod-symbol_enum"         :face  'font-lock-builtin-face))
          (Keyword        . ,(nerd-icons-codicon  "nf-cod-symbol_keyword"      :face  'font-lock-keyword-face))
          (Snippet        . ,(nerd-icons-codicon  "nf-cod-symbol_snippet"      :face  'font-lock-string-face))
          (Color          . ,(nerd-icons-codicon  "nf-cod-symbol_color"        :face  'success))
          (File           . ,(nerd-icons-codicon  "nf-cod-symbol_file"         :face  'font-lock-string-face))
          (Reference      . ,(nerd-icons-codicon  "nf-cod-references"          :face  'font-lock-variable-name-face))
          (Folder         . ,(nerd-icons-codicon  "nf-cod-folder"              :face  'font-lock-variable-name-face))
          (EnumMember     . ,(nerd-icons-codicon  "nf-cod-symbol_enum_member"  :face  'font-lock-builtin-face))
          (Constant       . ,(nerd-icons-codicon  "nf-cod-symbol_constant"     :face  'font-lock-constant-face))
          (Struct         . ,(nerd-icons-codicon  "nf-cod-symbol_structure"    :face  'font-lock-variable-name-face))
          (Event          . ,(nerd-icons-codicon  "nf-cod-symbol_event"        :face  'font-lock-warning-face))
          (Operator       . ,(nerd-icons-codicon  "nf-cod-symbol_operator"     :face  'font-lock-comment-delimiter-face))
          (TypeParameter  . ,(nerd-icons-codicon  "nf-cod-list_unordered"      :face  'font-lock-type-face))
          (Template       . ,(nerd-icons-codicon  "nf-cod-symbol_snippet"      :face  'font-lock-string-face))
          (ElispFunction  . ,(nerd-icons-codicon  "nf-cod-symbol_method"       :face  'font-lock-function-name-face))
          (ElispVariable  . ,(nerd-icons-codicon  "nf-cod-symbol_variable"     :face  'font-lock-variable-name-face))
          (ElispFeature   . ,(nerd-icons-codicon  "nf-cod-globe"               :face  'font-lock-builtin-face))
          (ElispFace      . ,(nerd-icons-codicon  "nf-cod-symbol_color"        :face  'success))))

  (setq x-gtk-resize-child-frames 'resize-mode)

  ;; Disable tab-bar in company-box child frames
  ;; TODO PR me upstream!
  (add-to-list 'company-box-frame-parameters '(tab-bar-lines . 0))

  ;; Don't show documentation in echo area, because company-box displays its own
  ;; in a child frame.
  (cl-callf2 delq 'company-echo-metadata-frontend company-frontends)

  (defun +company-box-icons--elisp-fn (candidate)
    (when (derived-mode-p 'emacs-lisp-mode)
      (let ((sym (intern candidate)))
        (cond ((fboundp sym)  'ElispFunction)
              ((boundp sym)   'ElispVariable)
              ((featurep sym) 'ElispFeature)
              ((facep sym)    'ElispFace))))))


;; Function to hide company tooltip
(defun hide-company-tooltip ()
  (interactive)
  (when (company-tooltip-visible-p)
    (company-cancel))
  )


;; Disable pop-up errors in Haskell mode
;; (setq haskell-interactive-popup-errors nil)

(use-package treemacs
  :after all-the-icons
  :config
  (require 'all-the-icons)
  (treemacs-load-theme "all-the-icons")

  ;; Customize the sizes for Treemacs faces
  (custom-set-faces
   '(treemacs-directory-face ((t (:height 0.80))))
   '(treemacs-file-face ((t (:height 0.80))))
   '(treemacs-root-face ((t (:height 0.80)))))
  (treemacs-resize-icons 14)
  )

(use-package treemacs-evil
   :after treemacs evil)
;; Use the 'use-package' macro to configure the 'treemacs-evil' package
;; The ':ensure t' ensures that the package is installed if not already present
;; The ':after treemacs evil' specifies that the package should be loaded after 'treemacs' and 'evil'

(use-package treemacs-projectile
  :after treemacs projectile)
;; Use the 'use-package' macro to configure the 'treemacs-projectile' package
;; The ':ensure t' ensures that the package is installed if not already present
;; The ':after treemacs projectile' specifies that the package should be loaded after 'treemacs' and 'projectile'

;; Display Treemacs as a side window on startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (delete-other-windows)
            (treemacs)
            (treemacs-follow-mode t)))

;; Set C-M-s keybinding to toggle side window
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(treemacs-directory-face ((t (:height 0.8))))
 '(treemacs-file-face ((t (:height 0.8))))
 '(treemacs-root-face ((t (:height 0.8)))))

;; Git integration
(use-package magit)

;;; init.el ends here
