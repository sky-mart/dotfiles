(require 'org)
(require 'org-crypt)

(defvar mart/notes-dir "~/notes")
(defvar mart/inbox-note "inbox")
(defvar mart/work-note "tfh")

(add-to-list 'org-modules 'org-habit t)
(setq org-habit-show-all-today t
      org-startup-indented t         ;; Visually indent sections. This looks better for smaller files.
      org-src-tab-acts-natively t    ;; Tab in source blocks should act like in major mode
      org-src-preserve-indentation t
      org-log-into-drawer t          ;; State changes for todos and also notes should go into a Logbook drawer
      org-src-fontify-natively t     ;; Code highlighting in code blocks
      org-support-shift-select t     ;; Allow shift selection with arrows
      org-startup-folded t           ;; Collapse all headlines
      org-directory mart/notes-dir
      org-agenda-files (list mart/notes-dir) ;; And all of those files should be in included agenda.
      org-crypt-key nil              ;; Use symmetric encryption unless CRYPTKEY is set.
      org-crypt-disable-auto-save 'encrypt
      org-todo-keywords '((sequence "TODO(1)" "IN-PROGRESS(2)" "WAITING(4)" "SOMEDAY(5)" "|" "DONE(3)" "CANCELED(6)"))
      )
(org-crypt-use-before-save-magic)
(add-to-list 'org-tags-exclude-from-inheritance "crypt")

(defun mart/notes-file-p (file-name)
  (when file-name
    (file-in-directory-p (expand-file-name file-name)
                         (file-name-as-directory
                          (expand-file-name org-directory)))))

(defun mart/notes-save-guard ()
  (when (mart/notes-file-p buffer-file-name)
    (unless (eq 0 (call-process "mountpoint" nil nil nil "-q"
                                (expand-file-name org-directory)))
      (user-error "Refusing to save notes: %s is not mounted" org-directory))
    (when (and (file-exists-p buffer-file-name)
               (not (verify-visited-file-modtime (current-buffer))))
      (user-error
       "Refusing to save stale notes buffer; revert the buffer first"))))

(add-hook 'before-save-hook #'mart/notes-save-guard)

(defun mart/note-path (note-name)
  (expand-file-name (concat note-name ".org") org-directory))

(defun mart/open-note (note-name)
  (find-file (mart/note-path note-name)))

(defun mart/new-inbox-entry ()
  (interactive)
  (mart/open-note mart/inbox-note)
  (goto-char (point-max))
  (org-meta-return))

(with-eval-after-load 'hydra
  (mart/defhydra-bilingual notes-launcher (:color blue) "Open notes"
    ("d" "в" (mart/open-note "journal") "Diary")
    ("i" "ш" (mart/open-note mart/inbox-note) "Inbox")
    ("t" "е" (mart/open-note "texts") "Texts")
    ("w" "ц" (mart/open-note mart/work-note) "TFH")
    ("k" "л" (dired "~/notes/kb") "KB")
    ("j" "о" (dired "~/notes/projects") "Projects")
    ("s" "ы" (mart/open-note "kb/stats") "Stats")
    ("r" "к" (mart/open-note "projects/archive/archive") "Archive")
    ("a" "ф" (org-agenda-list) "Agenda")
    ("g" "п" (mart/org-gcal-push-buffer) "Push buffer to Google Calendar")
    ("G" "П" (mart/org-gcal-post-at-point) "Post entry to Google Calendar")
    ("n" "т" (mart/new-inbox-entry) "New inbox"))
  (global-set-key (kbd "C-`") #'notes-launcher/body))

(defun mart/previous-workday-date ()
  "Return yesterday's date, or Friday's date on Monday."
  (let* ((now (current-time))
         (days-back (if (= (decoded-time-weekday (decode-time now)) 1)
                        3
                      1)))
    (format-time-string "%d.%m.%Y"
                        (time-subtract now (days-to-time days-back)))))

(defun mart/log-work-journal (&optional date)
  (mart/open-note 'mart/work-note)
  (widen)
  (goto-char (org-find-olp '("Journal") t))
  (org-end-of-subtree t t)
  (unless (bolp) (insert "\n"))
  (insert (format "** %s\n"
                  (or date (mart/previous-workday-date))))
  (org-paste-subtree
   3
   (with-temp-buffer
     (insert-file-contents (mart/note-path 'mart/inbox-note))
     (buffer-string)))
  (save-buffer)
  (mart/open-note 'mart/inbox-note)
  (erase-buffer))


;; Google Calendar stuff

(defvar mart/org-gcal-email "primary"
  "Google Calendar id synced by org-gcal.")

(use-package org-gcal
  :after org
  :commands (org-gcal-delete-at-point
             org-gcal-fetch
             org-gcal-post-at-point
             org-gcal-sync)
  :config
  ;; If shell env vars get annoying, auth-source with ~/.authinfo.gpg is a good next step.
  (setq mart/org-gcal-email (or (getenv "ORG_GCAL_EMAIL")
                                      mart/org-gcal-email)
        org-gcal-client-id (or (getenv "ORG_GCAL_CLIENT_ID")
                               org-gcal-client-id)
        org-gcal-client-secret (or (getenv "ORG_GCAL_CLIENT_SECRET")
                                   org-gcal-client-secret)
        org-gcal-file-alist `((,mart/org-gcal-email
                               . ,(file-name-concat org-directory "Projects.org"))))
  (org-gcal-reload-client-id-secret)
  )

(defun mart/org-gcal-post-at-point ()
  "Post the Org entry at point without importing data from Google Calendar."
  (interactive)
  (org-gcal-post-at-point t nil 'always-push))

(defun mart/org-gcal-push-buffer ()
  "Push all Org-managed Calendar entries in the current buffer to Google."
  (interactive)
  (let ((count 0))
    (org-map-entries
     (lambda ()
       (when (equal (org-entry-get nil org-gcal-managed-property) "org")
         (cl-incf count)
         (org-gcal-post-at-point t nil 'always-push)))
     nil 'file)
    (message "Pushing %d Org event%s to Google Calendar"
             count (if (= count 1) "" "s"))))
