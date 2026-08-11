;; -*- lexical-binding: t; -*-

;;; Tree-sitter: grammars, first-use installation, major-mode remapping
;;
;; Loaded ahead of dk-programming and dk-languages: `major-mode-remap-alist'
;; has to be in place before any file is visited, and `rust-mode-treesitter-derive'
;; has to be set before rust-mode is loaded.

(require 'treesit)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Grammars
;;
;; Built into <user-emacs-directory>/tree-sitter/ rather than taken from the
;; distro: Arch only packages c, rust, markdown and bash -- no cpp, go, toml,
;; yaml or json -- and its grammars track tree-sitter 0.26, while this Emacs
;; loads ABI 13-15 only (see `treesit-library-abi-version').
;;
;; Every revision is pinned.  An unpinned master can raise the ABI past 15, or
;; rename nodes out from under the queries in Emacs' own ts modes; the second
;; failure mode shows up as quietly missing fontification rather than an error.
(setq treesit-language-source-alist
      '((bash       "https://github.com/tree-sitter/tree-sitter-bash"          "v0.23.3")
        (c          "https://github.com/tree-sitter/tree-sitter-c"             "v0.23.4")
        (cmake      "https://github.com/uyha/tree-sitter-cmake"                "v0.7.1")
        (cpp        "https://github.com/tree-sitter/tree-sitter-cpp"           "v0.23.4")
        (dockerfile "https://github.com/camdencheek/tree-sitter-dockerfile"    "v0.2.0")
        (go         "https://github.com/tree-sitter/tree-sitter-go"            "v0.23.4")
        (gomod      "https://github.com/camdencheek/tree-sitter-go-mod"        "v1.1.0")
        (haskell    "https://github.com/tree-sitter/tree-sitter-haskell"       "v0.23.1")
        (json       "https://github.com/tree-sitter/tree-sitter-json"          "v0.24.8")
        (rust       "https://github.com/tree-sitter/tree-sitter-rust"          "v0.23.2")
        (toml       "https://github.com/tree-sitter-grammars/tree-sitter-toml" "v0.7.0")
        (yaml       "https://github.com/tree-sitter-grammars/tree-sitter-yaml" "v0.7.1")))

(setq treesit-font-lock-level 4)        ; every feature the grammars define

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Installing them
(defvar dk/treesit--attempted nil
  "Languages already auto-built this session, successfully or not.
Stops a grammar that fails to compile from being retried in every
buffer that asks for it.")

(defun dk/treesit-ensure (lang)
  "Make the tree-sitter grammar for LANG usable, building it if missing.
Returns non-nil when LANG can be used.  Each language is attempted at
most once per session."
  (cond
   ((treesit-language-available-p lang) t)
   ((memq lang dk/treesit--attempted) nil)
   ((not (assq lang treesit-language-source-alist)) nil)
   (t
    (push lang dk/treesit--attempted)
    (message "treesit: building %s grammar, this takes a few seconds..." lang)
    (ignore-errors (treesit-install-language-grammar lang))
    (if (treesit-language-available-p lang)
        (progn (message "treesit: %s grammar ready" lang) t)
      (message "treesit: could not build the %s grammar" lang)
      nil))))

;; Every ts mode gates itself on `treesit-ready-p', which makes that the one
;; place to hang first-use installation on -- third-party modes included.
;; Batch sessions are left alone, so byte-compiling never shells out to git.
(define-advice treesit-ready-p (:before (lang &rest _) dk/auto-install)
  "Build a missing grammar for LANG the first time it is asked for."
  (unless noninteractive
    (dk/treesit-ensure lang)))

(defun dk/treesit-install-all (&optional force)
  "Install every grammar in `treesit-language-source-alist'.
Grammars already present are skipped unless FORCE (the prefix argument)
is non-nil."
  (interactive "P")
  (dolist (src treesit-language-source-alist)
    (let ((lang (car src)))
      (if (and (not force) (treesit-language-available-p lang))
          (message "treesit: %s already installed" lang)
        (message "treesit: installing %s..." lang)
        (treesit-install-language-grammar lang))))
  (message "treesit: done"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Use the ts mode wherever a classic mode would have been chosen.
;; Emacs 30 fills `major-mode-remap-defaults' for TeX only -- nothing below
;; happens on its own.
(dolist (remap '((c-mode         . c-ts-mode)
                 (c++-mode       . c++-ts-mode)
                 (c-or-c++-mode  . c-or-c++-ts-mode)
                 (go-mode        . go-ts-mode)
                 (js-json-mode   . json-ts-mode)
                 (conf-toml-mode . toml-ts-mode)
                 (sh-mode        . bash-ts-mode)))
  (add-to-list 'major-mode-remap-alist remap))

;; Haskell deliberately gets no entry: haskell-mode stays the default and
;; `dk/haskell-toggle-ts' (dk-languages.el) adds one on demand.  Rust needs
;; none either -- rustic reaches rust-ts-mode by derivation, see below.

;; Extensions stock Emacs has no ts mapping for.  `add-to-list' prepends, so
;; these beat what is already there -- which is the point for go.mod (mapped
;; to `m2-mode', i.e. Modula-2) and CMakeLists.txt (mapped to `text-mode').
(dolist (entry '(("/go\\.mod\\'"         . go-mod-ts-mode)
                 ("\\.ya?ml\\'"          . yaml-ts-mode)
                 ("CMakeLists\\.txt\\'"  . cmake-ts-mode)
                 ("\\.cmake\\'"          . cmake-ts-mode)
                 ("/\\(?:Containerfile\\|Dockerfile\\)\\(?:\\.[^/]*\\)?\\'"
                  . dockerfile-ts-mode)))
  (add-to-list 'auto-mode-alist entry))

;; rust-mode derives from `rust-ts-mode' when this is set, and rustic-mode
;; derives from rust-mode -- so this single variable puts rustic buffers on
;; tree-sitter.  It is a defcustom, so it must be set before rust-mode loads;
;; that is the whole reason this module sorts ahead of dk-languages.
(setq rust-mode-treesitter-derive t)

(provide 'dk-treesit)
;;; dk-treesit.el ends here
