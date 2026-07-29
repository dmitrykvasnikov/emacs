;;; src/bootstrap.el --- functions needed before init.el  -*- lexical-binding: t; -*-

(defun dk/add-to-confdir (relative-path)
  "Expand RELATIVE-PATH against `user-emacs-directory'."
  (expand-file-name relative-path user-emacs-directory))

(defun dk/add-paths-to-list (list-var paths &optional expand-p)
  "Add each of PATHS to LIST-VAR, expanding against the config dir when EXPAND-P."
  (let ((expander (if expand-p #'dk/add-to-confdir #'identity)))
    (dolist (path paths)
      (add-to-list list-var (funcall expander path)))))

(provide 'bootstrap)
;;; bootstrap.el ends here
