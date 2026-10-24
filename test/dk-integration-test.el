;;; dk-integration-test.el --- Tests after loading init.el -*- lexical-binding: t; -*-
(require 'ert)

(defun dk/test-haskell-ts-repl-defined ()
  "Assert that `dk/haskell-ts-run-repl' is a real function, not an autoload."
  (let ((def (symbol-function 'dk/haskell-ts-run-repl)))
    (should (functionp def))
    (should-not (autoloadp def))))

(ert-deftest dk/haskell-repl-survives-classic-load-and-config-reload ()
  (require 'haskell-ts-mode)
  (dk/test-haskell-ts-repl-defined)
  (let ((ts-repl (symbol-function 'dk/haskell-ts-run-repl)))
    (require 'inf-haskell)
    (should-not (eq ts-repl (symbol-function 'run-haskell)))
    (dk/test-haskell-ts-repl-defined)
    (load "dk-languages" nil t)
    (dk/test-haskell-ts-repl-defined)
    (should (eq ts-repl (symbol-function 'dk/haskell-ts-run-repl)))
    (should (eq (keymap-lookup haskell-ts-mode-map "C-c C-z")
                'dk/haskell-ts-run-repl))
    (should (eq (keymap-lookup haskell-ts-mode-map "C-c C-r")
                'dk/haskell-ts-run-repl))))

(ert-deftest dk/eglot-preserves-mixed-markdown-input ()
  (require 'eglot)
  (let* ((source "```haskell\nf x = x\n```\nOther:\n```python\nprint(1)\n```")
         (markup (list :kind "markdown" :value (copy-sequence source)))
         (markdown-fontify-code-blocks-natively nil))
    (let ((rendered (eglot--format-markup markup)))
      (should (string-match-p "f x = x" rendered))
      (should (string-match-p "print(1)" rendered)))
    (should (equal (plist-get markup :value) source))))

(ert-deftest dk/installed-grammars-select-working-modes ()
  ;; Without the grammars dk-treesit.el falls back to classic/text modes on
  ;; purpose; that is an environment gap, not a failure of this config.
  (skip-unless (seq-every-p #'treesit-language-available-p
                            '(c cpp go gomod yaml json toml bash cmake
                              dockerfile rust)))
  (dolist (case '(("sample.c" c-ts-mode "int main(void) { return 0; }")
                  ("sample.cpp" c++-ts-mode "int main() { return 0; }")
                  ("sample.go" go-ts-mode "package main\nfunc main() {}")
                  ("go.mod" go-mod-ts-mode "module example.com/test\ngo 1.24")
                  ("sample.yaml" yaml-ts-mode "key: value")
                  ("sample.json" json-ts-mode "{\"key\": 1}")
                  ("sample.toml" toml-ts-mode "key = 1")
                  ("sample.sh" bash-ts-mode "#!/bin/bash\necho hello")
                  ("CMakeLists.txt" cmake-ts-mode "project(test)")
                  ("Dockerfile" dockerfile-ts-mode "FROM alpine")
                  ("sample.rs" rustic-mode "fn main() {}")))
    (with-temp-buffer
      (setq buffer-file-name (expand-file-name (car case) temporary-file-directory))
      (insert (nth 2 case))
      (set-auto-mode)
      (should (eq major-mode (cadr case)))
      (font-lock-ensure))))
