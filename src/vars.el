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

(defvar dk/treesit-languages
  '((bash   "https://github.com/tree-sitter/tree-sitter-bash")
    (c      "https://github.com/tree-sitter/tree-sitter-c")
    (cpp    "https://github.com/tree-sitter/tree-sitter-cpp")
    (cmake  "https://github.com/uyha/tree-sitter-cmake")
    (go     "https://github.com/tree-sitter/tree-sitter-go")
    (gomod  "https://github.com/camdencheek/tree-sitter-go-mod")
    (json   "https://github.com/tree-sitter/tree-sitter-json")
    (python "https://github.com/tree-sitter/tree-sitter-python")
    (rust   "https://github.com/tree-sitter/tree-sitter-rust")
    (toml   "https://github.com/tree-sitter/tree-sitter-toml")
    (yaml   "https://github.com/ikatyang/tree-sitter-yaml"))
  "Grammars installed by `dk/treesit-install-missing'.")

(provide 'vars)
;;; vars.el ends here
