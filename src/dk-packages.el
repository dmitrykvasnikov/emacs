;; -*- lexical-binding: t; -*-

;;; Package system bootstrap
;;
;; Must be loaded before any other module, they all use `use-package'.
;;
;; There is deliberately no `package-initialize' call here.  `package-quickstart'
;; (early-init.el) means Emacs has already run `package-activate-all' off the
;; quickstart file by the time this loads.  Calling `package-initialize' on top
;; of that re-scans every directory under elpa/, re-reads every archive-contents,
;; and then activates the whole set a second time -- `package-activate-all'
;; refuses the quickstart file once `package-activated-list' is non-nil, so that
;; second pass takes the slow path.  It cost ~0.10s of a 0.52s init.
;;
;; Nothing is lost: `package-installed-p' has a branch for exactly this state
;; (quickstart used, `package--initialized' still nil), and `package-install'
;; runs `package--archives-initialize' itself, which initialises and refreshes
;; on demand the first time something actually needs installing.

(require 'package)

(setq package-archives '(("melpa"  . "https://melpa.org/packages/")
                         ("elpa"   . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

;; Prefer stable official archives when the same package exists in more than
;; one place.  Packages available only from MELPA are unaffected.
(setq package-archive-priorities '(("elpa"   . 30)
                                   ("nongnu" . 20)
                                   ("melpa"  . 10)))

;; No eager `package-refresh-contents' either: it is a blocking network call on
;; the startup path, and `use-package-ensure-elpa' already refreshes and retries
;; when a package is missing from `package-archive-contents'.
;;
;; use-package itself is built in since Emacs 29, so there is nothing to install.
(require 'use-package)

;; Install missing packages automatically.  Built-in packages (eglot, dired,
;; org, flymake, recentf, which-key, ...) must therefore pass `:ensure nil',
;; otherwise package.el tries to fetch them from an archive that has no such
;; package.
(setq use-package-always-ensure t)

(provide 'dk-packages)
;;; dk-packages.el ends here
