;;; init.el --- Emacs initialization -*- lexical-binding: t; -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Basic UI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; User Interface
(setq inhibit-startup-message t) ; Disable the splash screen

(scroll-bar-mode -1) ; Disable visible scrollbar
(tool-bar-mode -1)   ; Disable the toolbar
;; (tooltip-mode -1)    ; Disable tooltips
(set-fringe-mode 10) ; Give some breathing room
(menu-bar-mode -1)   ; Disable the menubar

(set-face-attribute 'default nil :font "Fira Code")
(set-face-attribute 'default nil :height 110)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Behavior
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Store custom-file separately, don't freak out when it's not found
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file 'noerror)

;; create the autosave dir if necessary, since emacs won't.
(make-directory "~/.emacs.d/autosaves/" t)

;; Backup behavior
;; Put autosave files (ie #foo#) and backup files (ie foo~) in ~/.emacs.d/.
(custom-set-variables
 '(auto-save-file-name-transforms '((".*" "~/.emacs.d/autosaves/\\1" t)))
 '(backup-directory-alist '((".*" . "~/.emacs.d/backups/"))))

;; start week from Monday
(setq calendar-week-start-day 1)

;; set timestamps to English
(setq system-time-locale "C")

;; Map Cmd to be Meta
(setq mac-command-modifier 'meta)

(setq-default word-wrap t) ; Enable word wrap

(setq
 global-display-line-numbers-mode -1
 display-line-numbers-type 'relative
 display-line-numbers-current-absolute t)

(defun linum () (display-line-numbers-mode 1))
(add-hook 'prog-mode-hook 'linum)

;;(column-number-mode)
(delete-selection-mode 1)
(global-superword-mode 1)

;; Always wrap lines
(global-visual-line-mode 1)

;; Highlight the current line
(global-hl-line-mode 1)

;; auto revert
(global-auto-revert-mode 1)

;; Never use tabs, use spaces instead.
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq tab-width 4)

;; Delete trailing spaces and add new line in the end of a file on save.
(add-hook 'before-save-hook 'delete-trailing-whitespace)
(setq require-final-newline t)

;; C-x, C-c, C-v for cut, copy, paste
(cua-mode t)

(setq apropos-sort-by-scores t) ; Sort apropos results by relevancy

(fset 'yes-or-no-p 'y-or-n-p)      ; y and n instead of yes and no everywhere else

(global-set-key (kbd "<f4>") (lambda () (interactive) (revert-buffer nil t)))

;; Comment line or region.
(global-set-key (kbd "C-/") 'comment-line)

(global-set-key (kbd "C-x C-h") 'previous-buffer)
(global-set-key (kbd "C-x C-l") 'next-buffer)

(global-set-key (kbd "C-{") 'shrink-window-horizontally)
(global-set-key (kbd "C-}") 'enlarge-window-horizontally)

(global-unset-key (kbd "C-<down-mouse-1>"))
(global-unset-key (kbd "<down-mouse-8>"))
(global-unset-key (kbd "<down-mouse-9>"))

;; Disable secondary selection completely
(global-unset-key (kbd "M-<down-mouse-1>"))
(global-unset-key (kbd "M-<drag-mouse-1>"))
(global-unset-key (kbd "M-<mouse-1>"))

(global-set-key (kbd "C-x 2") (lambda ()
                                (interactive)
                                (split-window-below)
                                (other-window 1)))

(global-set-key (kbd "C-x 3") (lambda ()
                                (interactive)
                                (split-window-right)
                                (other-window 1)))

(global-set-key (kbd "<f2>") 'window-configuration-to-register)
(global-set-key (kbd "M-<f2>") 'jump-to-register)

(global-set-key
 (kbd "M-\\")
 (lambda () (interactive) (find-file (file-truename "~/.emacs.d/init.el"))))

(global-set-key (kbd "C-r") 'replace-string)
(setq replace-start-from-point nil) ; Start replacements from the start of the file

(defun display-ansi-colors ()
  (interactive)
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region (point-min) (point-max))))

(global-set-key (kbd "C-'") 'kill-whole-line)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Package setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Initialize package sources
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

;;(unless package-archive-contents
;;(package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;; Try package without installation
(use-package try)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General purpose packages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Emacs bindings with the russian keyboard
(use-package reverse-im
  :config
  (reverse-im-activate "russian-computer"))

;; enable Mac OS X path
(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

;; We need Emacs kill ring and system clipboard to be independent. Simpleclip is the solution to that.
;; (use-package simpleclip
;;   :config
;;   (simpleclip-mode 1))

;; Linear undo and redo.
(use-package undo-fu
  :bind
  (("C-z" . undo-fu-only-undo)
   ("C-S-z" . undo-fu-only-redo)))

(use-package smex)  ;; show recent commands when invoking Alt-x (or Cmd+Shift+p)

;; Multiple cursors. Similar to Sublime or VS Code.
(use-package multiple-cursors
  :bind
  (("M-3" . mc/mark-next-like-this)
   ("M-4" . mc/edit-beginnings-of-lines))
  :config
  (setq mc/always-run-for-all 1)
  (define-key mc/keymap (kbd "<return>") nil))

(use-package move-text
  :config
  (move-text-default-bindings))

(use-package hydra)

(global-set-key
 (kbd "M-u")
 (defhydra case-launcher (:color blue)
   "Change case"
   ("u" upcase-dwim "Upper case")
   ("г" upcase-dwim "Upper case") ;; cyrillic
   ("l" downcase-dwim "Lower case")
   ("д" downcase-dwim "Lower case") ;; cyrillic
   ("c" capitalize-dwim "Capitalize")
   ("с" capitalize-dwim "Capitalize") ;; cyrillic
   ))

(global-set-key (kbd "M-l") 'duplicate-line)
(setq duplicate-line-final-position -1) ; move cursor to the last new line

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Help
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Interactive help with key bindings
(use-package which-key
  :diminish which-key-mode
  :config
  (which-key-mode)
  (setq which-key-idle-delay 0.5))

;; Better help
(use-package helpful
  :commands (helpful-callable helpful-variable helpful-command helpful-key)
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UI packages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; UI theme
(use-package doom-themes
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  ;; (load-theme 'doom-outrun-electric t)
  (load-theme 'doom-nord t)
  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

;; NOTE: The first time you load your configuration on a new machine, you'll
;; need to run the following command interactively so that mode line icons
;; display correctly:
;;
;; M-x all-the-icons-install-fonts
;; M-x nerd-icons-install-fonts

(use-package all-the-icons)

;; Beautiful bottom line
(use-package doom-modeline
  :init (doom-modeline-mode 1))

;; Colorful brackets
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; replace switch-window mechanism
(use-package ace-window
  :bind
  (("C-x O" . other-frame)
   ([remap other-window] . 'ace-window))
  :init
  (progn
    (setq aw-scope 'global) ;; was frame
    (custom-set-faces
     '(aw-leading-char-face
       ((t (:inherit ace-jump-face-foreground :height 3.0)))))
    ))

(winner-mode 1) ;; Window configurations

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Completion and search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Completion mechanism
(use-package ivy
  :diminish ivy-mode
  :bind (("C-s" . swiper)
         ("C-x b" . ivy-switch-buffer))
  :config
  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t)
  (setq ivy-display-style 'fancy)
  (setq ivy-magic-slash-non-match-action nil))

;; Additional help
(use-package ivy-rich
  :after ivy
  :config
  (ivy-rich-mode 1)
  (setq ivy-rich-path-style 'abbrev))

;; Part of ivy?
(use-package counsel
  :bind (("M-x" . counsel-M-x))
  :config
  (counsel-mode 1))

(use-package flx)   ;; enable fuzzy matching

;; enable avy for quick navigation
(use-package avy
  :bind (("C-o" . avy-goto-char)))

;; better grep
(use-package ripgrep
  :config
  (setq grep-command "rg --no-heading --line-number --smart-case "))

(use-package fzf
  :bind
  ;; Don't forget to set keybinds!
  :config
  (setq
   fzf/args "-x --color bw --print-query --margin=1,0 --no-hscroll"
   fzf/executable "fzf"
   fzf/git-grep-args "-i --line-number %s"
   ;; command used for `fzf-grep-*` functions
   ;; example usage for ripgrep:
   ;; fzf/grep-command "rg --no-heading -nH"
   fzf/grep-command "grep -nrH"
   ;; If nil, the fzf buffer will appear at the top of the window
   fzf/position-bottom t
   fzf/window-height 15))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Project management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package projectile
  :diminish projectile-mode
  :custom
  (projectile-completion-system 'ivy)
  (projectile-compile-use-comint-mode t)
  (projectile-ignored-project-function
   (lambda (project-root)
     (or (string-search ".cache/bazel" project-root)
         (string-search ".rustup" project-root))))
  (projectile-switch-project-action #'magit-status)

  :bind-keymap
  ("C-c p" . projectile-command-map)
  :bind
  ("M-r" . projectile-ripgrep)

  :config
  (add-to-list 'projectile-globally-ignored-directories ".cache")
  (when (file-directory-p "~/projects/code")
    (setq projectile-project-search-path '("~/projects/code"))))

(use-package counsel-projectile
  :after projectile
  :after counsel
  :bind
  (("M-o" . counsel-projectile-find-file))
  :config (counsel-projectile-mode))

(use-package dashboard
  :config
  (setq dashboard-items '((projects . 5)
                          (recents  . 5)))
  (dashboard-setup-startup-hook))

(use-package tramp
  :custom
  ;; (tramp-auto-save-directory "~/.emacs.d/tramp-autosave")
  (tramp-use-scp-direct-remote-copying t)
  (tramp-histfile-override t)           ; sets both HISTFILESIZE
                                        ; and HISTSIZE to 0
  (tramp-verbose 1)                     ; errors only (no warnings)
  (remote-file-name-inhibit-locks t)    ; different emacs sessions are not
                                        ; modifying the same remote file
  (remote-file-name-inhibit-cache nil)  ; remote files are not modified
                                        ; outside of emacs
)

;; Speed up TRAMP
(setq vc-ignore-dir-regexp
      (format "%s\\|%s"
                    vc-ignore-dir-regexp
                    tramp-file-name-regexp))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Git
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package transient)

(transient-define-suffix magit-push-to-gerrit ()
  "Push to Gerrit"
  :description "to gerrit"
  (interactive)
  (magit-push-refspecs "origin" (format "HEAD:refs/for/%s" (magit-main-branch)) nil))

(transient-define-suffix magit-pull-from-main ()
  "Pull from master"
  :description "main"
  (interactive)
  (magit-pull-branch (format "origin/%s" (magit-main-branch)) (magit-pull-arguments)))

(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  :config
  (transient-append-suffix 'magit-push "t"
    '("g" magit-push-to-gerrit))
  (transient-append-suffix 'magit-pull "e"
    '("M" magit-pull-from-main)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Development
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package tree-sitter
  :config
  (setq major-mode-remap-alist
        '((python-mode . python-ts-mode)
          (c-mode . c-ts-mode)
          (c++-mode . c++-ts-mode)
          (rust-mode . rust-ts-mode)
          (sh-mode . bash-ts-mode))
        treesit-font-lock-level 4))

(use-package nix-ts-mode
  :mode "\\.nix\\'")

(use-package eglot
  :config
  (add-to-list 'eglot-server-programs
               '(c++-ts-mode . ("clangd")))
  (add-to-list 'eglot-server-programs
               '(python-ts-mode . ("ty" "server")))
  (add-to-list 'eglot-server-programs
               '(bash-ts-mode . ("bash-language-server" "start")))
  :hook
  ;; eglot in rust is managed by rustic-mode
  (c-ts-mode . eglot-ensure)
  (c++-ts-mode . eglot-ensure)
  (python-ts-mode . eglot-ensure)
  (bash-ts-mode . eglot-ensure))

(use-package dape
  :hook
  (kill-emacs . dape-breakpoint-save) ;; Save breakpoints on quit
  (after-init . dape-breakpoint-load) ;; Load breakpoints on startup

  :custom
  ;; Turn on global bindings for setting breakpoints with mouse
  ;; (dape-breakpoint-global-mode +1)
  (dape-buffer-window-arrangement 'right)
  (dape-cwd-function #'projectile-project-root)

  ;; The approach with the start- and stopped- hooks doesn't work
  ;; The stopped hook is called righ away
  :bind
  (("<f5>" . dape)
   ("S-<f5>" . dape-quit)
   ("<f8>" . dape-pause)
   ("<f9>" . dape-breakpoint-toggle)
   ("<f10>" . dape-next)
   ("<f11>" . dape-step-in)
   ("S-<f11>" . dape-step-out))

  :config
  (add-to-list
   'dape-configs
   ;; openocd needs to be launched first
   '(cortex
     modes (c-ts-mode c++-ts-mode)
     command "gdb"
     ;; -ex "monitor reset halt" can be used to stop the target
     command-args ("-q" "--interpreter=dap" "-ex" "target remote :3333")
     :type "gdb"
     :request "launch"
     ;; still have to run file <program> manually in the repl
     :program (lambda ()
                (read-file-name "ELF file: " (dape-cwd)))
     :cwd dape-cwd-function
     :target "localhost:3333"
     :stopAtBeginningOfMainSubprogram nil
     :stopOnEntry nil)))

(defun mart/dape-mode ()
   "My dape-mode handling"
   (interactive)
   (if dape-active-mode
       (progn
         (global-set-key (kbd "<f5>") 'dape-continue)
         (message "Dape is active"))
     (global-set-key (kbd "<f5>") 'dape)
     (message "Dape is inactive")))

(add-hook 'dape-active-mode-hook 'mart/dape-mode)

(defvar openocd-process nil
  "OpenOCD process identificator")

(defun openocd-start (config)
  "Start OpenOCD with a CONFIG"
  (interactive "sConfig: ")
  (setq openocd-process (start-process "OpenOCD" "*openocd*" "openocd" "-f" (format "%s.cfg" config))))

(defun openocd-kill ()
  (interactive)
  (when openocd-process
    (delete-process openocd-process)
    (kill-buffer "*openocd*")
    (setq openocd-process nil)))

(defun openocd-debug (config)
  (interactive "sConfig: ")
  (add-hook 'dape-active-mode-hook
            (lambda () (unless dape-active-mode
                         (openocd-kill))))
  (openocd-start config)
  (call-interactively #'dape))

(use-package company
  :config
  (setq company-idle-delay 0)
  (setq company-minimum-prefix-length 1)
  (global-company-mode t))

(use-package company-box
  :hook (company-mode . company-box-mode))

(use-package yasnippet
  :config
  (yas-global-mode 1)
  (add-to-list 'company-backends 'company-yasnippet))

(use-package bazel
  :mode ("\\.bazel\\'" . bazel-mode))

(defun bazel-target-output (target)
  "Get the output of a bazel target. 1 output is expected so far."
  (interactive "sTarget: ")
  (shell-command (format "bazel cquery %s --output=files 2>/dev/null" target)))

(use-package rustic
  :custom
  (rustic-lsp-client 'eglot)
  (rust-mode-treesitter-derive t))

(use-package systemd)

(use-package ansible)

(add-hook 'compilation-filter-hook 'ansi-color-compilation-filter)

(setq
 compilation-scroll-output 'first-error
 ansi-color-for-compilation-mode t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Python
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; install
;; uv tool install ty@latest
;; uv tool install debugpy
;; uv add ruff
(use-package uv-mode
  ;; set the python shell interpreter to the venv one
  :hook (python-ts-mode . uv-mode-set))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; C++
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; formatting
(use-package clang-format+
  :bind (("M-n" . clang-format-region)))

;; for pure C projects remove in .dir_locals
(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))
(c-set-offset 'innamespace '0)
(c-set-offset 'substatement-open '0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Debugging
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; TODO: rewrite using dape
(defun bazel-debug-at-point ()
  "Run the test case at point."
  (interactive)
  (let* ((source-file (or buffer-file-name
                          (user-error "Buffer doesn’t visit a file")))
         (root (or (bazel--workspace-root source-file)
                   (user-error "File is not in a Bazel workspace")))
         (directory (or (bazel--package-directory source-file root)
                        (user-error "File is not in a Bazel package")))
         (package (or (bazel--package-name directory root)
                      (user-error "File is not in a Bazel package")))
         (build-file (or (bazel--locate-build-file directory)
                         (user-error "No BUILD file found")))
         (relative-file (file-relative-name source-file directory))
         (case-fold-file (file-name-case-insensitive-p source-file))
         (rule (or (bazel--consuming-rule build-file relative-file
                                          case-fold-file :only-tests)
                   (user-error "No rule for file %s found" relative-file)))
         (test-executable (file-name-concat root "bazel-bin" package rule))
         (name
          (or (run-hook-with-args-until-success 'bazel-test-at-point-functions)
              (user-error "Point is not on a test case"))))
    (gdb (format "gdb -i=mi --cd=%s %s" root test-executable))))
;;  nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Some basic Org defaults

(add-to-list 'org-modules 'org-habit t)
(setq org-habit-show-all-today t
      org-startup-indented t         ;; Visually indent sections. This looks better for smaller files.
      org-src-tab-acts-natively t    ;; Tab in source blocks should act like in major mode
      org-src-preserve-indentation t
      org-log-into-drawer t          ;; State changes for todos and also notes should go into a Logbook drawer
      org-src-fontify-natively t     ;; Code highlighting in code blocks
      org-support-shift-select t     ;; Allow shift selection with arrows
      org-startup-folded t           ;; Collapse all headlines
      org-directory "~/notes"
      org-agenda-files '("~/notes") ;; And all of those files should be in included agenda.
      org-todo-keywords '((sequence "TODO(1)" "IN-PROGRESS(2)" "WAITING(4)" "SOMEDAY(5)" "|" "DONE(3)" "CANCELED(6)"))
      )

(defun open-note (exact-file)
  (find-file (file-name-concat org-directory exact-file)))

(defun mart/new-inbox-entry ()
  (interactive)
  (open-note "Inbox.org")
  (end-of-buffer)
  (org-meta-return))

(global-set-key
 (kbd "C-`")
 (defhydra notes-launcher (:color blue)
   "Open notes"
   ("d" (open-note "Diary.org") "Diary")
   ("в" (open-note "Diary.org") "Diary") ;; cyrillic
   ("i" (open-note "Inbox.org") "Inbox")
   ("ш" (open-note "Inbox.org") "Inbox") ;; cyrillic
   ("t" (open-note "Texts.org") "Texts")
   ("е" (open-note "Texts.org") "Texts") ;; cyrillic
   ("k" (open-note "KB.org") "KB")
   ("л" (open-note "KB.org") "KB") ;; cyrillic
   ("j" (open-note "Projects.org") "Projects")
   ("о" (open-note "Projects.org") "Projects") ;; cyrillic
   ("p" (open-note "Plans.org") "Plans")
   ("з" (open-note "Plans.org") "Plans") ;; cyrillic
   ("s" (open-note "Stats.org") "Stats")
   ("ы" (open-note "Stats.org") "Stats") ;; cyrillic
   ("r" (open-note "Archive.org") "Archive")
   ("к" (open-note "Archive.org") "Archive") ;; cyrillic
   ("a" (org-agenda-list) "Agenda")
   ("ф" (org-agenda-list) "Agenda") ;; cyrillic
   ("n" (mart/new-inbox-entry) "New inbox")
   ("т" (mart/new-inbox-entry) "New inbox") ;; cyrillic
))

;; requires pandoc
(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "pandoc"))

(use-package yaml-mode)

(use-package plantuml-mode
  :config
  (setq plantuml-jar-path "/home/vlad/.local/bin/plantuml-1.2023.5.jar")
  (setq plantuml-default-exec-mode 'jar))

;; TFH specific
(if (file-exists-p "~/.tfh/emacs.el")
    (load "~/.tfh/emacs.el"))
