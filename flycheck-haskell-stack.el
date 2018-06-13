;;; flycheck-haskell-stack.el --- Flycheck: Haskell using the stack build tool -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2015 Christopher Reichert <creichert07@gmail.com>
;;
;; Author: Christopher Reichert <creichert07@gmail.com>
;; URL: https://github.com/creichert/flycheck-haskell-stack
;; Keywords: tools, convenience
;; Version: 0.1
;; Package-Requires: ((emacs "24.1") (flycheck "0.22"))
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Work from which this checker is derived:
;;     - http://ioctl.it/posts/2015-07-03-stack-flycheck.html
;;     - https://github.com/flycheck/flycheck/blob/master/flycheck.el
;;
;;; Setup:
;;
;; (defun haskell-mode-setup-hook ()
;;   (interactive)
;;   (progn
;;     ;; ...
;;     (flycheck-select-checker 'haskell-stack)))
;;
;; (add-hook 'haskell-mode-hook 'haskell-mode-setup-hook)
;; (add-to-list 'flycheck-disabled-checkers 'haskell-ghc)
;; (add-to-list 'flycheck-disabled-checkers 'haskell-hlint)

(require 'flycheck)

(flycheck-define-checker haskell-stack
  "A Haskell syntax and type checker using stack.

See URL `https://github.com/commercialhaskell/stack/'.
GHC User Manual: https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/
"
  :command ("stack" "ghc" "--cwd" (eval (shell-command-to-string "echo -n `stack path --project-root`"))
                          "--"
                          "-Wall" "-O0" "-fno-code"
                          "-XCPP" "-XTemplateHaskell"
            (option-flag "-no-user-package-db"
                         flycheck-ghc-no-user-package-database)
            (option-list "-package-db" flycheck-ghc-package-databases)
            (option-list "-i" flycheck-ghc-search-path concat)
            ;; Include the parent directory of the current module tree, to
            ;; properly resolve local imports
            (eval (concat
                   "-i"
                   (flycheck-module-root-directory
                    (flycheck-find-in-buffer flycheck-haskell-module-re))))
            (option-list "-X" flycheck-ghc-language-extensions concat)
            (eval flycheck-ghc-args)
            "-x" (eval
                  (pcase major-mode
                    (`haskell-mode "hs")
                    (`literate-haskell-mode "lhs")))
            source)
  :error-patterns
  ((warning line-start (file-name) ":" line ":" column ":"
            (or " " "\n    ") "Warning:" (optional "\n")
            (message
             (one-or-more " ") (one-or-more not-newline)
             (zero-or-more "\n"
                           (one-or-more " ")
                           (one-or-more not-newline)))
            line-end)
   (error line-start (file-name) ":" line ":" column ": error:"
          (or (message (one-or-more not-newline))
              (and "\n"
                   (message
                    (one-or-more " ") (one-or-more not-newline)
                    (zero-or-more "\n"
                                  (one-or-more " ")
                                  (one-or-more not-newline)))))
          line-end))
  :error-filter
  (lambda (errors)
    (flycheck-sanitize-errors (flycheck-dedent-error-messages errors)))
  :modes (haskell-mode literate-haskell-mode)
  :next-checkers ((warning . haskell-hlint)))

(provide 'flycheck-haskell-stack)
