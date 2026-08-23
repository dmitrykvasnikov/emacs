;; -*- lexical-binding: t; -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; functions i need to have for list operations in the beginning of init.el

;; Resolve RELATIVE-PATH against the config directory (~/.config/emacs).
(defun dk/add-to-confdir (relative-path)
  (expand-file-name relative-path user-emacs-directory))

;; Add every element of PATHS to the list held in LIST-VAR.
;; With EXPAND-P non-nil each path is first resolved against the config
;; directory, so callers can write "src" instead of the absolute name.
(defun dk/add-paths-to-list (list-var paths &optional expand-p)
  (let ((expander (if expand-p #'dk/add-to-confdir #'identity)))
    (dolist (path paths)
      (add-to-list list-var (funcall expander path)))))

;; Defer GC through startup, restore a sane threshold afterwards.  Collecting
;; while ~60 packages are being loaded costs more than the memory it saves, so
;; the threshold is raised to "never" for the duration and lowered again from
;; `emacs-startup-hook'.  64MB (not the 800KB default) keeps GC pauses rare
;; during editing without letting the heap grow unbounded.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

(setq load-prefer-newer t)              ; never load a stale .elc
(setq site-run-file nil)                ; skip the distro's site-start.el
(setq frame-inhibit-implied-resize t)   ; no resize per font/UI change
(setq inhibit-startup-message t)        ; no splash screen, straight to *scratch*
;; `inhibit-startup-echo-area-message' is deliberately NOT set here.  It only
;; takes effect if it was set through Custom, or if `startup.el' can find a
;; literal `(setq inhibit-startup-echo-area-message "<login>")' by scanning
;; `user-init-file' as text -- see `display-startup-echo-area-message'.  A
;; variable reference, and any setting made from early-init.el, fails both
;; tests.  It lives in init.el instead.
;; Native compilation happens in the background for every package that has not
;; been compiled yet.  'silent still logs warnings to *Warnings*, it just stops
;; the buffer from popping up over whatever is being edited.
(defvar native-comp-async-report-warnings-errors) ; defined lazily by comp-run.el
(setq native-comp-async-report-warnings-errors 'silent)

;; Collapse every installed package's autoloads into one preloaded file
;; (package-quickstart.el) instead of reading each package's -autoloads.el at
;; startup.  Big win with ~60 packages.  Refreshed by package.el on
;; install/delete; `M-x package-quickstart-refresh' rebuilds it by hand.
(setq package-quickstart t)

;; No flicker: never create these, rather than creating and removing them.
(push '(menu-bar-lines . 0)   default-frame-alist)
(push '(tool-bar-lines . 0)   default-frame-alist)
