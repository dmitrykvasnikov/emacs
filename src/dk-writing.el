;; -*- lexical-binding: t; -*-

;;; Prose: Markdown and Org

(require 'dk-vars)                      ; `dk/org-directory'
(require 'dk-functions)                 ; `dk/prose-display'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Markdown
(use-package markdown-mode
  ;; GFM everywhere: tables, strikethrough, checkboxes, ``` fences
  :mode (("\\.md\\'"       . gfm-mode)
         ("\\.markdown\\'" . gfm-mode)
         ("README\\.md\\'" . gfm-mode))
  ;; Soft wrapping and looser line spacing; see dk-functions.el.
  :hook (markdown-mode . dk/prose-display)
  :custom
  ;; External renderer used by `markdown-preview' and `markdown-export'.
  ;; A list, not a string, so no shell quoting is involved.
  (markdown-command '("pandoc" "--from=gfm" "--to=html5" "--standalone"))
  (markdown-header-scaling t)               ;; # bigger than ##, bigger than ###
  (markdown-hide-markup t)                  ;; set it, never toggle it in a hook
  (markdown-hide-urls t)                    ;; [text](url) -> text ⚓
  (markdown-fontify-code-blocks-natively t) ;; ```rust blocks get rust highlighting
  (markdown-fontify-whole-heading-line t)   ;; heading face runs to the window edge
  (markdown-enable-math t)                  ;; $...$ / $$...$$ treated as LaTeX
  (markdown-enable-highlighting-syntax t)   ;; ==marked text== recognised
  ;; Headings inserted by `markdown-insert-header' and friends get their hashes
  ;; only at the start of the line -- "## Title", not "## Title ##".
  (markdown-asymmetric-header t)
  ;; Bullet drawn per nesting level (display only -- the file keeps its - and *).
  (markdown-list-item-bullets '("•" "◦" "▪" "▫"))
  :bind (:map markdown-mode-map
              ;; Context-sensitive: completes/toggles whatever is at point --
              ;; ticks a checkbox, follows a link, renumbers a list item.
              ("C-c C-e"  . markdown-do)
              ("C-c C-v"  . gfm-view-mode)  ;; read-only fully-rendered view
              ("M-<up>"   . markdown-move-up)    ;; move list item or subtree up
              ("M-<down>" . markdown-move-down)))

;; Pixel-accurate table alignment for both markdown and org: columns line up
;; even with CJK characters, emoji or a variable-pitch font, which the built-in
;; character-count alignment cannot do.
(use-package valign
  :hook ((markdown-mode org-mode) . valign-mode)
  :custom (valign-fancy-bar t))         ;; draw the separator rows as solid rules

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org
(use-package org
  :ensure nil                           ; built-in
  :hook (org-mode . dk/prose-display)
  :custom
  ;; Files scanned to build the agenda -- everything under ~/org (dk-vars.el).
  (org-agenda-files (list dk/org-directory))
  (org-log-done 'time)                           ;; stamp CLOSED: when a TODO is done
  (org-log-into-drawer t)                        ;; ...and hide notes in a :LOGBOOK:
  ;; Rendering
  (org-startup-indented t)                       ;; virtual indent, no leading stars
  (org-hide-emphasis-markers t)                  ;; /italic/ -> italic
  (org-pretty-entities t)                        ;; \alpha -> α
  (org-pretty-entities-include-sub-superscripts t) ;; a_1 and x^2 rendered too
  (org-ellipsis " ▾")                            ;; marker at the end of a folded heading
  (org-fontify-quote-and-verse-blocks t)         ;; distinct face for #+begin_quote
  (org-fontify-whole-heading-line t)             ;; heading face runs to the window edge
  (org-startup-with-inline-images t)             ;; show images without pressing C-c C-x C-v
  ;; Display width for inline images.  A number *in a list* means "honour a
  ;; #+ATTR_*: :width when the image has one, otherwise fall back to 600px" --
  ;; a bare 600 would force that width on every image instead.
  (org-image-actual-width '(600))
  ;; Source blocks
  (org-src-fontify-natively t)                   ;; highlight a block in its own language
  (org-src-tab-acts-natively t)                  ;; TAB indents by that language's rules
  ;; Between them: no indentation is added when leaving the C-c ' editor, and
  ;; whatever indentation the block already has is written back untouched --
  ;; which matters for Python and YAML blocks.
  (org-edit-src-content-indentation 0)
  (org-src-preserve-indentation t)
  ;; Editing behaviour
  (org-catch-invisible-edits 'show-and-error)    ;; never silently edit folded text
  (org-return-follows-link t)                    ;; RET on a link opens it
  ;; M-RET on a heading with a body puts the new heading after that body,
  ;; instead of splitting the text at point.
  (org-insert-heading-respect-content t)
  (org-auto-align-tags nil)                      ;; let org-modern place tags
  (org-tags-column 0)                            ;; ...right after the title, not at col 77
  (org-imenu-depth 4)                            ;; imenu/consult see 4 heading levels
  :bind (:map org-mode-map
              ;; S-RET means "open an indented line below" everywhere else, and
              ;; `org-mode-map' shadows the global binding -- so without this
              ;; entry the key keeps org's meaning throughout an org buffer.
              ;; `dk/newline-below' hands back to `org-table-copy-down' when
              ;; point is actually in a table, which is the only place org's
              ;; binding is worth anything.
              ("S-<return>" . dk/newline-below)))

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

;; The counterweight to all the hiding above: reveal the raw markup of whatever
;; element point is inside, so it can be edited, and hide it again on leaving.
;; Each toggle below corresponds to one thing org is hiding.
(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autoemphasis t)           ;; *bold* /italic/ (org-hide-emphasis-markers)
  (org-appear-autolinks t)              ;; the [[target][...]] half of a link
  (org-appear-autosubmarkers t)         ;; a_1 / x^2 (org-pretty-entities-include-...)
  (org-appear-autoentities t)           ;; \alpha (org-pretty-entities)
  (org-appear-delay 0.0))               ;; reveal at once, no idle wait

(provide 'dk-writing)
;;; dk-writing.el ends here
