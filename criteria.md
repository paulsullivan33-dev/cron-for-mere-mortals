# Writing Criteria

Every guide in this repo is written to the same standard. If you're
adding or editing a guide — human or AI — hold it to these.

1. **Plain words, real ideas.** Simple language, never dumbed-down
   concepts. Explain jargon on first use; collect terms in the
   glossary.
2. **No hype.** No marketing adjectives, no "revolutionary," no
   promises about what something will do for the reader.
3. **Honest about limits.** Say what the thing *can't* do. State
   uncertainty instead of smoothing it over. Validation notes include
   what remains unverified.
4. **No invented numbers.** Benchmarks, defaults, and specs are either
   measured or qualified with "depends on your setup." If it wasn't
   tested, say so.
5. **Checkable.** Commands are meant to be run, with "Check:" blocks
   showing what success looks like. Sources are linked, not asserted.
6. **Respect the reader's setup.** Call out Windows/Mac/Linux
   differences. Don't assume a GPU, a budget, or prior experience.
7. **Safety isn't skipped.** Real risks get stated plainly, not buried.
8. **Scoped.** Each guide says what it covers and points elsewhere for
   the rest. No guide pretends to be the whole subject.
9. **Structure over prose.** Tables, before/after examples,
   symptom → fix. Scannable beats essay.

---

## Verification notes for this guide

Everything hands-on was run on the build machine:
cron 3.0pl1-184ubuntu2 and anacron 2.3-39ubuntu2
(Ubuntu 24.04 packages) under a real systemd, with a
lab of every-minute jobs whose outputs are files with
timestamps. The receipts (full transcripts) are kept
with the lab, and the chapters quote them.

**Run for real, captured:**

- The daemon started via `systemctl start cron`;
  `pgrep`/`systemctl status` before (nothing) and
  after (running).
- `crontab -l` with no crontab ("no crontab for
  root", exit 1); install-from-file and list round
  trips; the spool file's ownership and mode 600.
- Syntax rejection, twice: "bad minute" and "bad
  day-of-week", each "errors in crontab file, can't
  install.", exit 1, previous crontab untouched.
- `crontab -e` with a no-op editor: "No modification
  made".
- `crontab -r`: removes instantly with **no prompt**,
  piped or on a terminal. `crontab -r -i` prompts
  ("really delete root's crontab? (y/n)"); "no"
  preserves, "yes" removes. Both branches captured.
- Firings, one per minute over several minutes:
  heartbeat and `/etc/cron.d` tick files with matching
  timestamps — user and system tables both live.
- The environment dump job: PWD, SHELL, PATH, HOME,
  LOGNAME as a job receives them.
- The percent trap both ways: escaped → real dates in
  the file; unescaped → blank lines, with the daemon's
  CMD log line showing the command truncated at the
  `%`.
- Output with no MTA: "(CRON) info (No MTA installed,
  discarding output)", once per firing. With
  `MAILTO=""` installed, the same job still ran (CMD
  line present) and the discard notices stopped.
- `flock -n` end to end: a 75-second job every minute
  produced started / skipped / finished / started,
  and a manual contention demo (`-n` → exit 1,
  silent; `-w 10` waited and ran).
- `/etc/cron.d` failure modes, both with the daemon's
  own words: a line missing the user field → "Error:
  bad username … this crontab file will be ignored";
  a file without a final newline → "Missing newline
  before EOF, this crontab file will be ignored".
  Neither job ever fired; the healthy neighbouring
  file never missed a minute.
- `@reboot`: daemon restart and full stop/start both
  produced the log line "(CRON) INFO (Skipping
  @reboot jobs -- not system startup)" and no run.
- anacron with a lab table and spool: test mode exit
  0; a forced run executed the job and wrote its
  timestamp file (20261020); an unforced run the same
  day executed 0 jobs, correctly.
- cron.allow and cron.deny refusals, verbatim, both
  ways, exit 1.
- The `env -i` reproduction: a PATH-dependent script
  succeeds interactively and fails ("fancy-date: not
  found") in cron's measured environment — exiting 0
  anyway, which is kept in the guide because it
  happened.

**Documented, not run:**

- A genuine boot-time `@reboot` firing. The sandbox
  cannot reboot; what could be captured — the skip
  behaviour — was, and the chapter says which is
  which.
- Delivery of job output as real mail to a mailbox.
  No MTA exists on the build box; the discard notice
  is the captured evidence for the mechanism, and the
  chapter doesn't pretend otherwise.
- An unprivileged user's *successful* crontab use.
  This sandbox silently ignores `setgid` (proven with
  a setgid copy of `id`: it ran with the caller's
  gid), so the stock spool permissions locked the
  test user out even when allowed. The refusals were
  captured; the allowed case is stock behaviour,
  described and labelled as not captured here.
- syslog-file grepping as the primary log path. The
  lab logs through journald; the `/var/log/syslog`
  route is named for rsyslog systems without any
  captured output claimed for it.
- macOS and other-Unix cron differences: named where
  relevant, not exercised; no such machine was
  available to the build.
