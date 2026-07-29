;;; src/vars.el --- user variables -*- lexical-binding: t; -*-

(defvar dk/font-family "Aporetic Sans Mono"
  "Default monospace family; ignored gracefully when not installed.")
(defvar dk/font-height 115
  "Default face height, in 1/10 pt.")
(defvar dk/minibuffer-font-height 100
  "Face height for the minibuffer prompt.")

(defvar dk/auto-save-dir (expand-file-name "autosave/" user-emacs-directory)
  "Directory for auto-save files.  Trailing slash is required.")

(defvar dk/prose-line-spacing 0.15
  "Extra line spacing in prose buffers (Markdown, Org).")

(defvar dk/packages
  '(;; Completion / minibuffer
    vertico orderless marginalia consult consult-dir consult-eglot embark
    embark-consult corfu cape
    ;; Editing / navigation
    expand-region wgrep vundo breadcrumb treesit-fold
    ;; Coding
    apheleia magit diff-hl
    ;; Languages
    haskell-mode haskell-ts-mode go-mode markdown-mode valign
    ;; UI
    nerd-icons nerd-icons-dired nerd-icons-corfu doom-modeline helpful
    rainbow-delimiters diredfl org-modern org-appear
    ;; Themes
    doom-themes ef-themes gruvbox-theme spacemacs-theme)
  "Packages this configuration installs from an archive.
Deliberately excludes which-key, recentf and display-line-numbers: Emacs 30
registers those as built-in packages, so they need no installing.  Setting
`package-selected-packages' from this makes `package-autoremove' safe and
lets a fresh machine be provisioned with
`package-install-selected-packages'.")

(defvar dk/trusted-dirs
  (list (expand-file-name user-emacs-directory)
        (expand-file-name "~/code/"))
  "Directories whose Elisp is trusted.
Emacs 30 gates `elisp-flymake-byte-compile' behind `trusted-content';
without this, editing this config gets no error checking.  Trailing
slashes are required — they mark a directory rather than a single file.")

(defvar dk/treesit-languages
  '((bash    "https://github.com/tree-sitter/tree-sitter-bash")
    (c       "https://github.com/tree-sitter/tree-sitter-c")
    (cpp     "https://github.com/tree-sitter/tree-sitter-cpp")
    (cmake   "https://github.com/uyha/tree-sitter-cmake")
    (go      "https://github.com/tree-sitter/tree-sitter-go")
    (gomod   "https://github.com/camdencheek/tree-sitter-go-mod")
    (haskell "https://github.com/tree-sitter/tree-sitter-haskell")
    (json    "https://github.com/tree-sitter/tree-sitter-json")
    (python  "https://github.com/tree-sitter/tree-sitter-python")
    (rust    "https://github.com/tree-sitter/tree-sitter-rust")
    (toml    "https://github.com/tree-sitter/tree-sitter-toml")
    (yaml    "https://github.com/ikatyang/tree-sitter-yaml"))
  "Grammars installed by `dk/treesit-install-missing'.")

(defvar dk/treesit-remaps
  '((c-mode         c-ts-mode         c)
    (c++-mode       c++-ts-mode       cpp)
    (c-or-c++-mode  c-or-c++-ts-mode  c)
    (python-mode    python-ts-mode    python)
    (sh-mode        bash-ts-mode      bash)
    (js-json-mode   json-ts-mode      json)
    (conf-toml-mode toml-ts-mode      toml)
    (rust-mode      rust-ts-mode      rust)
    (go-mode        go-ts-mode        go))
  "(CLASSIC-MODE TS-MODE LANGUAGE) triples for `dk/treesit-apply-remaps'.
The remap is installed only when LANGUAGE's grammar is present, so a
missing grammar falls back to the classic mode instead of leaving a
parser-less tree-sitter mode with no font-lock, indent or imenu.")

(provide 'vars)
;;; vars.el ends here
