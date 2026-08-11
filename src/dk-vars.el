;; -*- lexical-binding: t; -*-

;;; My variables
;;
;; Values that are referenced from more than one module live here, so that a
;; single edit changes every place that uses them.

(defvar dk/auto-save-directory (expand-file-name "autosave/" user-emacs-directory)
  "Directory where auto-save files are kept, out of the way of the project.
The trailing slash is load-bearing.  With the UNIQUIFY flag set in
`auto-save-file-name-transforms', `files--transform-file-name' runs the
replacement through `file-name-directory' before appending the mangled
name -- without the slash the last component is read as a file name and
dropped, and every auto-save lands in `user-emacs-directory' instead.")

(defvar dk/font-family "Aporetic Sans Mono"
  "Font family used for the default and minibuffer faces.")

(defvar dk/font-height 115
  "Height (1/10 pt) of the `default' face.")

(defvar dk/minibuffer-font-height 100
  "Height (1/10 pt) of the `minibuffer-prompt' face.")

(defvar dk/theme 'gruber-darker
  "Theme loaded at start-up by src/theme.el.")

(defvar dk/org-directory "~/org"
  "Root directory of the org files, used for `org-agenda-files'.")

(provide 'dk-vars)
;;; dk-vars.el ends here
