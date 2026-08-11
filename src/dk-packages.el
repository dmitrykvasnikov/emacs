;; -*- lexical-binding: t; -*-

;;; Package system bootstrap
;;
;; Must be loaded before any other module, they all use `use-package'.

(require 'package)

(setq package-archives '(("melpa"  . "https://melpa.org/packages/")
                         ("org"    . "https://orgmode.org/elpa/")
                         ("elpa"   . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)

;; Install missing packages automatically.  Built-in packages (eglot, dired,
;; org, flymake, recentf, which-key, ...) must therefore pass `:ensure nil',
;; otherwise package.el tries to fetch them from an archive that has no such
;; package.
(setq use-package-always-ensure t)

(provide 'dk-packages)
;;; dk-packages.el ends here
