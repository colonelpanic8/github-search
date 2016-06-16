;;; github-search.el --- Clone repositories by searching github

;; Copyright (C) 2016 Ivan Malison

;; Author: Ivan Malison <IvanMalison@gmail.com>
;; Keywords: github search clone api gh magit
;; URL: https://github.com/IvanMalison/github-search
;; Version: 0.0.0
;; Package-Requires: ((magit "2.1.0") (gh "0.10.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package aims to provide an easy interface to creating per
;; project org-mode TODO headings.

;;; Code:
(require 'gh-search)
(require 'magit-remote)
(require 'cl-lib)

(defvar github-search-repo-format-function 'github-search-string-for-repo)
(defvar github-search-get-clone-url-function 'github-search-get-clone-url)
(defvar github-search-get-target-directory-for-repo-function
  'github-search-prompt-for-target-directory)
(defvar github-search-page-limit 1)

(defun github-search-for-completion (search-string &optional page-limit)
  (let* ((search-api (make-instance gh-search-api))
         (search-response (gh-search-repos search-api search-string page-limit))
         (repositories (oref search-response :data)))
    (cl-loop for repo in repositories
             collect
             (cons (funcall github-search-repo-format-function repo) repo))))

(defun github-search-string-for-repo (repository)
  (format "%s/%s"
          (oref (oref repository :owner) :login)
          (oref repository :name)))

(defun github-search-get-clone-url (repository)
  (oref repo :clone-url))

(defun github-search-select-repository-from-search-string (search-string)
  (let* ((candidates (github-search-for-completion search-string
                                                   github-search-page-limit))
         (selection (completing-read "Select a repository: " candidates)))
    (cdr (assoc selection candidates))))

(defun github-search-prompt-for-target-directory (repo)
  (let ((input-target (read-directory-name
                       "Clone to: " nil nil nil
                       (and (string-match "\\([^./]+\\)\\(\\.git\\)?$" remote-url)
                            (match-string 1 remote-url)))))
    (if (file-exists-p input-target) (concat input-target (oref repo :name))
      input-target)))

(defun github-search-get-target-directory-for-repo (repo)
  (funcall github-search-get-target-directory-for-repo-function repo))

;;;###autoload
(defun github-search-clone-repo (search-string)
  "Query github using SEARCH-STRING and clone the selected repository."
  (interactive
   (list (read-from-minibuffer "Enter a github search string: ")))
  (let* ((repo (github-search-select-repository-from-search-string search-string))
         (remote-url (funcall github-search-get-clone-url-function repo))
         (target-directory (github-search-get-target-directory-for-repo repo)))
    (magit-clone remote-url target-directory)))

(provide 'github-search)
;;; github-search.el ends here
