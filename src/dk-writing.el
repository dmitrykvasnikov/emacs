;; -*- lexical-binding: t; -*-

;;; Prose: Markdown and Org

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Markdown
(use-package markdown-mode
  ;; GFM everywhere: tables, strikethrough, checkboxes, ``` fences
  :mode (("\\.md\\'"       . gfm-mode)
         ("\\.markdown\\'" . gfm-mode)
         ("README\\.md\\'" . gfm-mode))
  :hook (markdown-mode . dk/prose-display)
  :custom
  (markdown-command '("pandoc" "--from=gfm" "--to=html5" "--standalone"))
  (markdown-header-scaling t)
  (markdown-hide-markup t)                  ;; set it, never toggle it in a hook
  (markdown-hide-urls t)                    ;; [text](url) -> text ⚓
  (markdown-fontify-code-blocks-natively t)
  (markdown-fontify-whole-heading-line t)
  (markdown-enable-math t)
  (markdown-enable-highlighting-syntax t)
  (markdown-asymmetric-header t)
  (markdown-list-item-bullets '("•" "◦" "▪" "▫"))
  :bind (:map markdown-mode-map
              ("C-c C-e"  . markdown-do)
              ("C-c C-v"  . gfm-view-mode)  ;; read-only fully-rendered view
              ("M-<up>"   . markdown-move-up)
              ("M-<down>" . markdown-move-down)))

;; Table alignment for both markdown and org
(use-package valign
  :hook ((markdown-mode org-mode) . valign-mode)
  :custom (valign-fancy-bar t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org
(use-package org
  :ensure nil                           ; built-in
  :hook (org-mode . dk/prose-display)
  :custom
  (org-agenda-files (list dk/org-directory))
  (org-log-done 'time)
  (org-log-into-drawer t)
  ;; Rendering
  (org-startup-indented t)                       ;; virtual indent, no leading stars
  (org-hide-emphasis-markers t)                  ;; /italic/ -> italic
  (org-pretty-entities t)                        ;; \alpha -> α
  (org-pretty-entities-include-sub-superscripts t)
  (org-ellipsis " ▾")
  (org-fontify-quote-and-verse-blocks t)
  (org-fontify-whole-heading-line t)
  (org-startup-with-inline-images t)
  (org-image-actual-width '(600))
  ;; Source blocks
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 0)
  (org-src-preserve-indentation t)
  ;; Editing behaviour
  (org-catch-invisible-edits 'show-and-error)    ;; never silently edit folded text
  (org-return-follows-link t)
  (org-insert-heading-respect-content t)
  (org-auto-align-tags nil)                      ;; let org-modern place tags
  (org-tags-column 0)
  (org-imenu-depth 4))

(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :custom
  (org-modern-table nil)          ;; valign owns tables — don't run both
  (org-modern-star 'replace)      ;; ◉ ○ ◈ instead of ***; 'fold for folding indicators
  (org-modern-hide-stars 'leading)
  ;; Fringes are on (dk-ui.el sets `set-fringe-mode' to 10), so this can be
  ;; flipped to t for a fringe bar down the side of src/quote blocks.
  (org-modern-block-fringe nil)
  (org-modern-list '((?- . "–") (?+ . "•") (?* . "‣"))))

(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autoemphasis t)
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t)
  (org-appear-autoentities t)
  (org-appear-delay 0.0))

(provide 'dk-writing)
;;; dk-writing.el ends here
