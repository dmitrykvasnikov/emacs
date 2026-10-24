;;; dk-packages-test.el --- dk/package-list matches the config -*- lexical-binding: t; -*-
(require 'ert)
(require 'dk-packages)

(defconst dk/test-src-directory
  (expand-file-name "../src/" (file-name-directory
                               (or load-file-name buffer-file-name)))
  "The config's src/ directory, located relative to this test file.")

(defun dk/test-ensured-packages (form)
  "Return the names of ensured `use-package' declarations inside FORM.
Walks FORM recursively, so declarations nested in `let', `when' and the
like are found too.  A declaration counts unless it says `:ensure nil'."
  (when (consp form)
    (let ((found (and (eq (car form) 'use-package)
                      (symbolp (cadr form))
                      (let ((ensure (memq :ensure (cddr form))))
                        (not (and ensure (null (cadr ensure)))))
                      (list (cadr form)))))
      ;; Walk the cdr chain by hand: forms can be dotted lists.
      (while (consp form)
        (setq found (append found (dk/test-ensured-packages (car form)))
              form (cdr form)))
      found)))

(defun dk/test-file-ensured-packages (file)
  "Return the ensured `use-package' names declared in FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (let (found form)
      (while (setq form (condition-case nil
                            (read (current-buffer))
                          (end-of-file nil)))
        (setq found (append found (dk/test-ensured-packages form))))
      found)))

(ert-deftest dk/package-list-matches-use-package-forms ()
  (let ((declared (delete-dups
                   (mapcan #'dk/test-file-ensured-packages
                           (directory-files dk/test-src-directory t
                                            "\\`dk-.*\\.el\\'")))))
    (should (equal (sort (copy-sequence declared) #'string<)
                   (sort (copy-sequence dk/package-list) #'string<)))))

;;; dk-packages-test.el ends here
