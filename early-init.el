;; -*- lexical-binding: t; -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; functions i need to have for list operations in the beginning of init.el

;; Expand path with emacs config dir
(defun dk/add-to-confdir (relative-path)
  (expand-file-name relative-path user-emacs-directory))

;; Add list of items to a list
;; it expand-p is TRUE each path from the list expanded to emacs config dir
(defun dk/add-paths-to-list (list-var paths &optional expand-p)
  (let ((expander (if expand-p #'dk/add-to-confdir #'identity)))
    (dolist (path paths)
      (add-to-list list-var (funcall expander path)))))

;; Defer GC through startup, restore a sane threshold afterwards.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

(setq load-prefer-newer t)              ; never load a stale .elc
(setq site-run-file nil)
(setq frame-inhibit-implied-resize t)   ; no resize per font/UI change
(setq inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name)
(setq native-comp-async-report-warnings-errors 'silent)
(setq package-quickstart t)             ; big win with ~60 packages

;; No flicker: never create these, rather than creating and removing them.
(push '(menu-bar-lines . 0)   default-frame-alist)
(push '(tool-bar-lines . 0)   default-frame-alist)

