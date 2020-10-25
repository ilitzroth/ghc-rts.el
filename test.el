;;; SPDX-License-Identifier: GPL-3.0-or-later
(require 'ghc-rts)

;; Since ghc rts can only be started once we have to choose what to test
;; This is achieved by (skip-unless (eq (ghc-rts::get-rts-status) :not-initialized))
;; at the beginning of each test.
;; See how testing all tests is achieved in the makefile.

(ert-deftest test-internal-funs ()
  "Test the state transitions of the ghc runtime."
  (skip-unless (eq (ghc-rts-status)
                   :not-initialized))
  (should (eq (ghc-rts::exit-rts)
              :not-initialized))
  (should (eq (ghc-rts::init-rts)
              :initialized))
  (should (eq (ghc-rts::get-rts-status)
              :initialized))
  (should (eq (ghc-rts::init-rts)
              :initialized))
  (should (eq (ghc-rts::get-rts-status)
              :initialized))

  (should (integerp (ghc-rts::num-allocations)))
  (should (ghc-rts::dynamicp))

  (should-not (ghc-rts::profiledp))
  (should-not (ghc-rts::stats-enabled-p))
  (should (eq (ghc-rts::exit-rts)
              :exited))
  (should (eq (ghc-rts::get-rts-status)
              :exited))
  (should (eq (ghc-rts::exit-rts)
              :exited))
  (should (eq (ghc-rts::init-rts)
              :exited))
  (should (eq (ghc-rts::get-rts-status)
              :exited)))

(ert-deftest test-internal-funs-no-init()
  "Test calling the internal functions without starting the RTS."
  (skip-unless (eq (ghc-rts-status)
                   :not-initialized))
  (should (integerp (ghc-rts::num-allocations)))
  (should (ghc-rts::dynamicp))

  (should-not (ghc-rts::profiledp))
  (should-not (ghc-rts::stats-enabled-p)))

(ert-deftest test-internal-funs-after-exit ()
  "Test calling internal functions after ghc RTS has exited."
  (skip-unless (eq (ghc-rts-status)
                   :not-initialized))
  (should (eq (ghc-rts::init-rts)
              :initialized))
  (should (eq (ghc-rts::exit-rts)
              :exited))
  (should (eq (ghc-rts::get-rts-status)
              :exited))
  (should (integerp (ghc-rts::num-allocations)))
  (should (ghc-rts::dynamicp))

  (should-not (ghc-rts::profiledp))
  (should-not (ghc-rts::stats-enabled-p)))

(ert-deftest test-exposed-funs ()
  "Test the state transitions of the ghc runtime."
  (skip-unless (eq (ghc-rts-status)
                   :not-initialized))
  (should (eq (ghc-rts-exit)
              :not-initialized))
  (should (eq (ghc-rts-init)
              :initialized))
  (should (eq (ghc-rts-status)
              :initialized))
  (should (eq (ghc-rts-init)
              :initialized))
  (should (eq (ghc-rts-status)
              :initialized))


  (should (integerp (ghc-rts-num-allocations)))
  (should (ghc-rts-dynamic-p))

  (should-not (ghc-rts-profiled-p))
  (should-not (ghc-rts-stats-enabled-p))
  (should (eq (ghc-rts-exit)
              :exited))
  (should (eq (ghc-rts-status)
              :exited))
  (should (eq (ghc-rts-exit)
              :exited))
  (should (eq (ghc-rts-init)
              :exited))
  (should (eq (ghc-rts-status)
              :exited)))

(ert-deftest test-exposed-funs-no-init ()
  (skip-unless (eq (ghc-rts-status)
                   :not-initialized))
  (should-error (ghc-rts-num-allocations))
  (should-error (ghc-rts-dynamic-p))
  (should-error (ghc-rts-profiled-p))
  (should-error (ghc-rts-stats-enabled-p)))

(ert-deftest test-exposed-funs-after-exit ()
  (skip-unless (eq (ghc-rts-status)
                   :not-initialized))
  (should (eq (ghc-rts::init-rts)
              :initialized))
  (should (eq (ghc-rts::exit-rts)
              :exited))
  (should (eq (ghc-rts::get-rts-status)
              :exited))
  (should-error (ghc-rts-num-allocations))
  (should-error (ghc-rts-dynamic-p))
  (should-error (ghc-rts-profiled-p))
  (should-error (ghc-rts-stats-enabled-p)))

(ert-deftest test-rts-options-command-line ()
  (skip-unless (eq (ghc-rts-status)
              :not-initialized))
  (should (eq (ghc-rts-init "-T")
              :initialized))
  (should (ghc-rts-stats-enabled-p)))

(ert-deftest test-rts-options-default-args ()
  (skip-unless (eq (ghc-rts-status)
              :not-initialized))
  (setq *ghc-rts-default-args* "-T")
  (should (eq (ghc-rts-init "-T")
              :initialized))
  (should (ghc-rts-stats-enabled-p)))
