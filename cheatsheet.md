# Emacs keybinding cheat sheet

This sheet reflects this repository's Emacs 30 configuration. It starts with
general editing and moves toward the configured completion, project, language,
and package workflows. Major-mode maps can override global keys; use `C-h k`
or the searchable `C-h B` whenever the current buffer behaves differently.

## Key notation

- `C-` means hold Control; `M-` means hold Meta/Alt; `S-` means hold Shift.
- A space separates consecutive keys. For example, `C-x C-f` means press
  `C-x`, release it, then press `C-f`.
- `RET`, `TAB`, `DEL`, and `SPC` mean Return, Tab, Backspace, and Space.
- A numeric prefix changes or repeats many commands: `M-5 C-n` moves down five
  lines, and `C-u` supplies the common universal prefix.
- Repeat mode is enabled. After a repeatable command, the final key often works
  by itself; for example, `C-x o o o` cycles through several windows.

## Help, commands, and getting unstuck

| Key | Action |
| --- | --- |
| `C-g` | Cancel the current command or prompt |
| `Esc` | Cancel the current interaction (configured like `C-g`) |
| `M-x` | Run a command by name; if a minibuffer is already open elsewhere, move to it |
| `C-h k` | Describe the command on a key, using Helpful |
| `C-h f` | Describe a function or callable |
| `C-h v` | Describe a variable |
| `C-h x` | Describe a command |
| `C-h C-h` | Describe the symbol at point |
| `C-h B` | Search all bindings available in the current context with Embark |
| `C-h m` | Describe the current major and minor modes |
| `C-h b` | Show all active bindings |
| `C-h w` | Show which key runs a named command |

Which-key is enabled, so pausing after a prefix such as `C-x`, `C-c`, or
`C-x p` displays the available continuations.

## Moving around

| Key | Action |
| --- | --- |
| `C-f` / `C-b` | Forward / backward one character |
| `M-f` / `M-b` | Forward / backward one word |
| `C-n` / `C-p` | Next / previous logical line |
| `C-a` / `C-e` | Beginning / end of line |
| `M-a` / `M-e` | Beginning / end of sentence |
| `M-{` / `M-}` | Previous / next paragraph |
| `C-M-f` / `C-M-b` | Forward / backward over a balanced expression |
| `C-M-u` / `C-M-d` | Move out of / down into a balanced expression |
| `M-<` / `M->` | Beginning / end of buffer |
| `C-v` / `M-v` | Page down / up, preserving screen position |
| `C-l` | Recenter point: middle, then top |
| `M-g g` | Go to a line number |
| `M-g c` | Avy: type visible text, then jump using the displayed hint |
| `C-x C-x` | Exchange point and mark |

## Selecting and editing text

| Key | Action |
| --- | --- |
| `C-SPC` | Set the mark and begin a region |
| `C-x h` | Select the whole buffer |
| `C-x SPC` | Begin a rectangular selection |
| `C-w` | Kill the region |
| `M-w` | Copy the region |
| `C-y` | Yank the latest killed or copied text |
| `M-y` | Select an item from the kill ring with preview (Consult) |
| `C-k` | Kill from point to end of line |
| `M-d` / `M-DEL` | Kill the next / previous word |
| `C-/` or `C-_` | Undo the latest change |
| `C-x u` | Open the Vundo tree |
| `C-=` | Expand the active region semantically |
| `M-/` | Comment the active region, or the current line when no region is active |
| `M-u` / `M-l` / `M-c` | Uppercase / lowercase / capitalize region or word at point |
| `S-RET` | Open and indent a new line below without splitting the current line |
| `M-q` | Fill the paragraph or mode-specific block |
| `M-\` | Delete surrounding horizontal whitespace |

Typing replaces an active region, matching common GUI editors. Matching closing
parentheses, brackets, and quotes are inserted automatically.

### Multiple cursors

| Key | Action |
| --- | --- |
| `C->` | Add the next occurrence of the active region or symbol |
| `C-<` | Add the previous occurrence |
| `C-c ;` | Mark all matching occurrences |
| `C-c l` | Put a cursor on every selected line |
| `C-g` or `RET` | Leave multiple-cursors mode |

### Vundo

After `C-x u`, navigate the undo tree without changing the buffer permanently
until confirming:

| Key | Action |
| --- | --- |
| `f` / `b` or `right` / `left` | Move forward / backward along a branch |
| `n` / `p` or `down` / `up` | Move to the next / previous branch |
| `a` / `e` | Move to the current branch's root / end |
| `l` | Go to the last saved state |
| `RET` | Confirm the selected state |
| `q` or `C-g` | Quit without selecting it |

## Files and buffers

| Key | Action |
| --- | --- |
| `C-x C-f` | Find or create a file |
| `C-x C-s` | Save the current file |
| `C-x s` | Save some or all modified buffers |
| `C-x C-w` | Save as another file |
| `C-x i` | Insert another file's contents |
| `C-x b` | Switch among buffers, recent files, and bookmarks (Consult) |
| `C-x 4 b` | Switch to a buffer in another window (Consult) |
| `C-x C-r` | Open a recent file (Consult) |
| `C-x C-b` | Open Ibuffer instead of the basic buffer list |
| `C-c k` | Kill the current buffer without asking which buffer |
| `C-x k` | Choose a buffer to kill |
| `C-x C-j` | Open Dired in the current file's directory |

Files changed externally are reloaded automatically when safe. Point positions,
minibuffer history, search history, and up to 200 kill-ring entries persist
between sessions.

### Ibuffer essentials

| Key | Action |
| --- | --- |
| `RET` | Visit the buffer at point |
| `o` | Visit it in another window |
| `m` / `u` | Mark / unmark a buffer |
| `d` | Mark a buffer for deletion |
| `x` | Execute marked operations |
| `g` | Refresh the list |
| `q` | Quit Ibuffer |

## Windows

| Key | Action |
| --- | --- |
| `C-x 0` | Delete the selected window |
| `C-x 1` | Keep only the selected window |
| `C-x 2` | Split below |
| `C-x 3` | Split right |
| `C-x o` or `M-o` | Select the next window |
| `C-M-v` | Scroll the other window |
| `C-x 4 f` | Find a file in another window |
| `C-c <left>` | Undo the last window-layout change |
| `C-c <right>` | Redo a window-layout change |

## Search, minibuffer, and completion

### Search and replace

| Key | Context | Action |
| --- | --- | --- |
| `C-s` | Ordinary buffer | Consult line search with live preview |
| `C-S-s` | GUI frame | Repeat the previous Consult line search |
| `C-r` | Ordinary buffer | Incremental backward search |
| `C-r` | Minibuffer, shell, or REPL | Search that prompt's history with Consult |
| `C-c f` | Anywhere | Find a file below a chosen directory |
| `M-s o` | Ordinary buffer | List matching lines with Occur |
| `M-%` | Ordinary buffer | Query-replace literal text |
| `C-M-%` | Ordinary buffer | Query-replace a regular expression |

`C-S-s` cannot be distinguished from `C-s` by most terminals, so it starts a
fresh search there.

### Vertico prompts

Completion is space-separated and orderless: typing `fi buf` can match
`find-file-other-buffer`. File prompts retain partial path completion, so
abbreviations such as `/u/s/l` can expand through directory components.

| Key | Action |
| --- | --- |
| `C-n` / `C-p` | Next / previous candidate |
| `M-n` / `M-p` | Next / previous history item |
| `RET` | Accept a candidate; in a file prompt, enter a selected directory |
| `TAB` | Insert the selected candidate into the prompt |
| `M-RET` | Submit exactly what was typed instead of the selected candidate |
| `DEL` | Delete one character |
| `S-Backspace` | Kill the previous word |
| `M-DEL` | Move up one component in a file path; otherwise kill the previous word |
| `C-g` | Leave the current minibuffer level |

Recursive minibuffers are enabled. The prompt displays the nesting depth, and
the configured `M-x` returns to an already-open minibuffer instead of opening
another one.

### Embark actions

| Key | Action |
| --- | --- |
| `C-.` | Show actions for the candidate or thing at point |
| `C-;` | Run the most likely action immediately |
| `C-h B` | Search all actions and bindings available here |

For a reusable grep result buffer, run a Consult grep, press `C-. E` to export
it, then use `M-x wgrep-change-to-wgrep-mode` to edit matches. Finish with
`C-c C-c` or `C-x C-s`; abort edits with `C-c C-k`.

### Corfu completion popup

Corfu appears automatically after two characters. It uses Eglot completions in
managed code buffers and file/word completion elsewhere.

| Key | Action while the popup is visible |
| --- | --- |
| `C-n` / `C-p` or `M-n` / `M-p` | Next / previous candidate |
| `RET` or `TAB` | Insert the selected candidate |
| `M-d` | Toggle the documentation popup |
| `M-l` | Show the selected candidate's source location |
| `C-g` | Close the popup |

The popup's local `M-l` temporarily takes precedence over global lowercase.

## Projects

`C-x p` is the built-in project prefix; `C-c p` is an identical alias for
Projectile muscle memory. Project roots include Git roots and directories
marked by a Cabal file, `stack.yaml`, `Cargo.toml`, `go.mod`, or
`compile_commands.json`.

Use either prefix in this table:

| Key after prefix | Full example | Action |
| --- | --- | --- |
| `p` | `C-x p p` | Switch project, then choose find file, buffer, directory, ripgrep, or Magit |
| `f` | `C-x p f` | Find a project file |
| `F` | `C-x p F` | Find a file, allowing files outside the project |
| `b` | `C-x p b` | Switch project buffer with Consult |
| `d` | `C-x p d` | Find a project directory |
| `D` | `C-x p D` | Open the project root in Dired |
| `g` | `C-x p g` | Ripgrep the project with Consult |
| `G` | `C-x p G` | Search regexp, also allowing external files |
| `r` | `C-x p r` | Query-replace a regexp across project files |
| `c` | `C-x p c` | Compile the project |
| `s` | `C-x p s` | Open a project shell |
| `e` | `C-x p e` | Open project Eshell |
| `!` | `C-x p !` | Run a synchronous shell command in the project |
| `&` | `C-x p &` | Run an asynchronous shell command in the project |
| `v` | `C-x p v` | Open the project in VC Dir |
| `k` | `C-x p k` | Kill the project's buffers |
| `x` | `C-x p x` | Run `M-x` scoped to project-aware commands |
| `C-x s` | `C-x p C-x s` | Save project buffers |

Build and cache directories such as `dist-newstyle`, `target`, `build`,
`vendor`, and `node_modules` are excluded from project file lists and searches.

## Dired file manager

`C-x C-j` opens Dired at the current file. Entering a directory reuses the
window's Dired buffer. With two Dired windows open, copy and rename default to
the other window's directory. Recursive copies and deletions do not ask an
extra recursion question; deletions go to the desktop trash in interactive
sessions.

| Key | Action |
| --- | --- |
| `RET`, `f`, or `e` | Open the file or directory at point |
| `^` | Go to the parent directory |
| `n` / `p` | Next / previous entry |
| `m` / `u` | Mark / unmark an entry |
| `t` | Toggle all marks |
| `% m` | Mark names matching a regular expression |
| `C` | Copy marked files |
| `R` | Rename or move marked files |
| `D` | Delete marked files immediately after confirmation |
| `d` | Flag entries for later deletion |
| `x` | Execute flagged deletions |
| `+` | Create a directory |
| `w` | Copy the selected file name |
| `=` | Diff the file at point against another file |
| `g` | Refresh the listing |
| `q` | Quit Dired |

## Programming and diagnostics

### Navigation and diagnostics

| Key | Action |
| --- | --- |
| `M-.` | Find definition; waits briefly for a starting Eglot server |
| `M-?` | Find references |
| `M-,` | Return from an xref jump |
| `C-M-.` | Find definitions matching a pattern |
| `M-n` / `M-p` | Next / previous Flymake diagnostic in programming buffers |
| `C-c ?` | List and jump to Flymake diagnostics with Consult |
| `C-c m` | Search commands relevant to the current major mode |
| `C-M-\` | Indent the active region |

Eglot starts automatically for Haskell, Rust, C, C++, and Go buffers. Apheleia
formats on save; C and C++ formatting is enabled only when the project contains
`.clang-format` or `_clang-format`.

Useful unbound commands are available through `M-x`:

| Command | Action |
| --- | --- |
| `eglot-rename` | Semantic rename through the language server |
| `eglot-code-actions` | Choose an LSP code action |
| `eglot-reconnect` | Restart or reconnect the language server |
| `flymake-show-buffer-diagnostics` | List diagnostics for this buffer |
| `apheleia-format-buffer` | Format now instead of waiting for save |
| `clang-format-region` / `clang-format-buffer` | Run clang-format explicitly |

### Haskell

The same keys are provided by both Haskell modes, with the closest available
command in each mode:

| Key | `haskell-mode` | `haskell-ts-mode` |
| --- | --- | --- |
| `C-c C-l` | Load the file into the Cabal REPL | Compile the region and go to GHCi |
| `C-c C-z` | Switch to the interactive buffer | Run or switch to Haskell |
| `C-c C-t` | Show the type at point | Open the Eldoc documentation buffer |

Run `M-x dk/haskell-toggle-ts` to switch all open Haskell buffers and the
session default between `haskell-mode` and `haskell-ts-mode`.

## Git and Magit

| Key | Action |
| --- | --- |
| `C-x g` | Open Magit status for the current repository |
| `C-c g` | Open Magit's dispatch menu for the current file |

Inside a Magit status buffer:

| Key | Action |
| --- | --- |
| `?` or `h` | Show Magit's command dispatch menu |
| `TAB` | Expand or collapse the section at point |
| `RET` | Visit the item at point |
| `n` / `p` | Next / previous section |
| `g` | Refresh status |
| `s` / `u` | Stage / unstage the file or hunk at point |
| `S` / `U` | Stage modified files / unstage everything |
| `c` | Open the commit menu; `c c` starts a normal commit |
| `P` | Open the push menu |
| `F` | Open the pull menu |
| `f` | Open the fetch menu |
| `b` | Open the branch menu |
| `l` | Open the log menu |
| `d` | Open the diff menu |
| `r` | Open the rebase menu |
| `z` | Open the stash menu |
| `x` | Quickly reset the item at point |
| `k` | Delete the item at point when that section permits it |
| `q` | Bury the Magit buffer |

Magit transients show the exact follow-up keys and arguments, so the single
prefix letters are the useful part to memorize first.

## Markdown

Markdown files open in GFM mode. Markup and URLs are visually hidden until
needed, prose wraps softly, and Pandoc backs preview/export commands.

| Key | Action |
| --- | --- |
| `TAB` / `S-TAB` | Cycle visibility forward / backward |
| `RET` | Context-aware newline and list continuation |
| `M-RET` | Insert a list item |
| `C-c C-e` | Act on the item at point: toggle checkbox, follow link, renumber list, and so on |
| `C-c C-v` | Toggle the read-only rendered GFM view |
| `M-<up>` / `M-<down>` | Move the current list item or subtree |
| `C-c C-l` | Insert a link |
| `C-c C-o` | Follow the item at point |
| `C-c '` | Edit the fenced code block at point in its language mode |
| `C-c C-n` / `C-c C-p` | Next / previous heading |
| `C-c C-f` / `C-c C-b` | Next / previous heading at the same level |
| `C-c C-u` | Move to the parent heading |
| `C-c C-s b` / `i` / `c` | Insert bold / italic / inline code markup |
| `C-c C-s C` | Insert a fenced GFM code block |
| `C-c C-s l` | Insert a link through the style menu |
| `C-c C-s t` | Insert a table |
| `C-c C-c p` | Preview using Pandoc |
| `C-c C-c e` | Export using Pandoc |
| `C-c C-c v` | Export and preview |

## Org mode

| Key | Action |
| --- | --- |
| `TAB` / `S-TAB` | Cycle the current subtree / the whole document |
| `RET` | Follow a link at point; otherwise insert a context-aware newline |
| `S-RET` | Open an indented line below; in a table, copy the cell downward |
| `M-RET` | Insert a heading or list item after the current content |
| `M-<left>` / `M-<right>` | Promote / demote a heading or list item |
| `M-<up>` / `M-<down>` | Move a subtree or list item |
| `C-c C-t` | Cycle TODO state |
| `C-c C-s` | Schedule the item |
| `C-c C-d` | Set a deadline |
| `C-c C-z` | Add a note |
| `C-c C-c` | Act on the item at point or update its state |
| `C-c C-l` | Insert or edit a link |
| `C-c C-o` | Open the link at point |
| `C-c C-e` | Open the export dispatcher |
| `C-c '` | Edit the source block at point in its language mode |
| `C-c C-c` | Execute the source block when point is on its header |
| `C-c C-v t` | Tangle source blocks |
| `C-c C-x C-v` | Toggle inline images |
| `C-c [` / `C-c ]` | Add / remove this file from the agenda set |

The agenda scans Org files in `~/org`; run `M-x org-agenda` to open it.

## Configuration and appearance

| Key or command | Action |
| --- | --- |
| `C-c t` | Choose a theme with live preview |
| `M-x dk/change-font` | Choose a configured font globally or for the current buffer |
| `M-x dk/recompile-config` | Byte-compile `src/`; use `C-u` to force recompilation |
| `M-x dk/treesit-install-all` | Install missing pinned tree-sitter grammars |
| `C-c e` | Re-evaluate the current Emacs Lisp buffer |
| `C-c r` | Toggle CUA mode for a temporary `C-c`/`C-x`/`C-v` workflow |
