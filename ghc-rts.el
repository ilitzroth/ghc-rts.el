;;; ghc-rts.el --- GHC runtime system initialization -*- lexical-binding: t -*-

;; Copyright (C) 2020-2025 Immanuel Litzroth -*- lexical-binding: t -*-

;; Author: Immanuel Litzroth <immanuel.litzroth@gmail.com>
;; Created: Symbol’s function definition is void: time-stamp-string
;; Keywords: languages, processes, tools, haskell, ghc
;; Homepage: https://github.com/ilitzroth/ghc-rts.el
;; Version : 0.0.1
;; Package-Requires: ((emacs "24.4"))
;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;; This package loads a module that initializes the ghc runtime system.
;;; Change Log:

;;; Code:

(eval-when-compile (require 'cl-lib))
(eval-when-compile (require 'subr-x))

(declare-function ghc-rts::get-rts-status "ext:emacs-ghc-rts")
(declare-function ghc-rts::init-rts "ext:emacs-ghc-rts")
(declare-function ghc-rts::exit-rts "ext:emacs-ghc-rts")
(declare-function ghc-rts::num-allocations "ext:emacs-ghc-rts")
(declare-function ghc-rts::dynamicp "ext:emacs-ghc-rts")
(declare-function ghc-rts::profiledp "ext:emacs-ghc-rts")
(declare-function ghc-rts::stats-enabled-p "ext:emacs-ghc-rts")

(defconst ghc-rts-so
  "emacs-ghc-rts.so"
  "Name of the binary module to load.")

(defconst ghc-rts-directory
  (or (and load-file-name
           (file-name-directory load-file-name))
      default-directory)
  "The directory this library was loaded from.")

(defun ghc-rts-maybe-compile-and-load ()
  "Load an possibly compile the binary module."
  (unless (require 'ghc-rts-internal nil :no-error)
    (let ((default-directory ghc-rts-directory)
          (help-buffer-name "*GHC RTS Compilation*")
          (shell-command-dont-erase-buffer t))
      (unless (file-exists-p ghc-rts-so)
        (with-help-window help-buffer-name
          (prin1-to-string (format
                  "The binary module to intialize the ghc rts doesn't seem to be
built on your system yet. I will try to build it but if that doesn't
work you might able to get it running by checking the Makefile in
directory %s and fixing it for your system.
You will need to have recent g++ and ghc installed." ghc-rts-directory)))
        (when (yes-or-no-p "Build the binary module?")
          (shell-command "make" help-buffer-name))
        (unless (file-exists-p ghc-rts-so)
          (error "Could not build the binary module in dir %s" ghc-rts-directory)))
      (unless (load "emacs-ghc-rts.so"
                    :no-error
                    :no-message
                    :no-suffix
                    :must-suffix)
        (error "Could not load the binary module %s" ghc-rts-so))
      (provide 'ghc-rts-internal))))

(defgroup ghc-rts nil
  "Start GHC RTS in emacs."
  :version "0.0.1"
  :group 'haskell)

(defcustom ghc-rts-default-args nil
  "List of strings that are the arguments to be passed on init to the rts.
This should not start with \"+RTS\""
  :group 'ghc-rts
  :type '(set string))

(defun ghc-rts-ensure-initialized ()
  "Ensure that the runtime system is initialized."
  (ghc-rts-maybe-compile-and-load)
  (cl-case (ghc-rts-status)
    (:initialized nil)
    (:not-initialized
     (error "GHC RTS has status :not-initialized, call ghc-rts-init to initialize"))
    (:exited
     (error "GHC RTS has status :exited and cannot be reinitialized"))))

(defun ghc-rts-status (&optional with-message)
  "Return the status of the ghc RTS.
value returned will be one of :not-initialized :initialized
  :empty.  Print a message when WITH-MESSAGE is not nil"
  (interactive "p")
  (ghc-rts-maybe-compile-and-load)
  (let ((status (ghc-rts::get-rts-status)))
    (when with-message
      (message "GHC RTS status: %s" status))
    status))

(defun ghc-rts-init (&rest args)
  "Initialize the ghc RTS.
The remaining argument are the ARGS that will be passed to the runtime
system.  If no string is passed the value of `ghc-rts-default-args' is used.
Return the status of the ghc RTS after this call.  Due to limitations
in ghc it not possible to stop and restart the ghc RTS.  This can be
safely called many times but will only initialize once."
  (ghc-rts-maybe-compile-and-load)
  (apply #'ghc-rts::init-rts
         "emacs-module"
         "+RTS"
         "--install-signal-handlers=no"
         (if args args ghc-rts-default-args)))

(defun ghc-rts-exit ()
  "Exit the ghc RTS.
After this action the RTS cannot be reinitialized Emacs needs
restarting if you want to use it again.  Returns the status of the RTS
after exit.  This can be safely called many times but will only exit
once."
  (interactive)
  (ghc-rts-maybe-compile-and-load)
  (ghc-rts::exit-rts))

(defun ghc-rts-num-allocations (&optional with-message)
  "Return the number of allocations performed by the RTS.
Print a message when WITH-MESSAGE is not nil."
  (interactive "p")
  (ghc-rts-ensure-initialized)
  (let ((num-allocations (ghc-rts::num-allocations)))
    (when with-message
      (message "GHC RTS number of allocations: %d"
               num-allocations))
    num-allocations))

(defun ghc-rts-dynamic-p(&optional with-message)
   "Return whether the ghc RTS was dynamically linked.
In Emacs this will always return true.  Print a message when
WITH-MESSAGE is not nil"
  (interactive "p")
  (ghc-rts-ensure-initialized)
  (let ((dynamicp (ghc-rts::dynamicp)))
    (when with-message
      (message "GHC RTS linked dynamically: %s"
               (if dynamicp "yes" "no")))
    dynamicp))


(defun ghc-rts-profiled-p (&optional with-message)
  "Return whether the ghc RTS is build for profiling.
Print a message when WITH-MESSAGE is not nil."
  (interactive "p")
  (ghc-rts-ensure-initialized)
  (let ((profiledp (ghc-rts::profiledp)))
    (when with-message
      (message "GHC RTS profiled: %s"
               (if profiledp "yes" "no")))
    profiledp))


(defun ghc-rts-stats-enabled-p (&optional with-message)
  "Return whether ghc RTS has stats enabled.
Print a message when WITH-MESSAGE is not nil."
  (interactive "p")
  (ghc-rts-ensure-initialized)
  (let ((res (ghc-rts::stats-enabled-p)))
    (when with-message
      (message "GHC rts stats enabled: %s"
	       (if res "yes" "no")))
    res))

(provide 'ghc-rts)

;;; ghc-rts.el ends here
