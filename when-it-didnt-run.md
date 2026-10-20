# When It Didn't Run

**Scope:** a debugging order for the classic report —
"my cron job didn't run" — from most to least common
cause, each with the check that settles it. Everything
here was exercised in this guide's lab.

## 1. Is the daemon alive?

Jobs don't run on a machine whose cron isn't running,
and the failure is total silence — nothing was ever
going to happen.

```
$ pgrep -a cron
6663 /usr/sbin/cron -f -P

$ systemctl status cron      # on a systemd machine
● cron.service - Regular background program processing daemon
     Active: active (running)
```

No process, no jobs. (Before the lab started its
daemon, `pgrep -a cron` returned nothing, exit 1 —
that *was* the diagnosis.)

## 2. Did cron try? Read its log

Cron logs every job it starts. On a systemd machine:

```
$ journalctl -t CRON | grep backup
... CRON[7107]: (root) CMD (echo "noisy job: ...")
```

(`/var/log/syslog`, same `CRON` tag, where rsyslog
collects logs.) Three readings:

- **No CMD line at all** → cron never attempted it.
  The problem is upstream: the schedule, the table, or
  which table you edited (step 3).
- **A CMD line, but truncated-looking** → compare it
  with the crontab line. Cron logs the command it
  *ran*; a line that ends early is the percent trap
  ([The Percent Trap](the-percent-trap.md)).
- **A CMD line and no result** → cron did its half.
  The job ran and failed in its own world (step 4).

Crontab edits are logged too, under the `crontab` tag
(REPLACE/DELETE/LIST) — proof of what got installed,
and when ([Managing Your Crontab](managing-your-crontab.md)).

## 3. Was it the table, the schedule, or the clock?

- **Right table?** A line in `/etc/cron.d/` missing its
  user field doesn't run and the daemon says so:
  `Error: bad username` with the file **ignored**
  ([Three Kinds of Crontab](three-kinds-of-crontab.md)).
  A line in a user crontab that you installed as
  someone else (`sudo crontab -e` edits *root's*
  crontab) is the same species of mistake.
- **Right fields?** Read the line aloud the way
  [Reading the Five Fields](reading-the-fields.md)
  teaches. `0 9 * * 1` and `0 9 * * *` differ by a
  weekday. And remember the OR: restricted
  day-of-month *and* day-of-week fires on either, not
  both.
- **Was the machine on?** A job due during sleep or
  downtime is skipped, not deferred. If the evidence
  says "should have run at 03:00" and the journal says
  the machine woke at 09:00, that's the answer, and
  the fix is [Machines That Sleep](machines-that-sleep.md),
  not a schedule edit.
- **Which clock?** Cron follows the system clock and
  local time. Around daylight-saving transitions, jobs
  in the repeated or vanished hour can run twice or
  not at all — if a job is safety-critical on those two
  nights a year, check your distribution's notes rather
  than discovering it.

## 4. Reproduce its world

If cron ran the job and the job failed, run it
*yourself* — but in cron's environment, not yours.
This single technique settles most cases:

```
env -i HOME=/root LOGNAME=root SHELL=/bin/sh \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  /bin/sh -c "cd /root && /path/to/the/job.sh"
```

(Use the values from *your* job owner's environment
dump if you made one — [The Cron Environment](the-cron-environment.md).)
Whatever breaks here is what broke at 03:00: a helper
not on PATH, a relative path resolving against `$HOME`,
a bashism in a `/bin/sh` world. And watch exit
statuses with suspicion — the lab's failing script
exited 0. A job can lie; its output can't.

## 5. The checklist of small things

- Script not executable, or edited by something that
  stripped the bit: `ls -l` it. Cron runs the *command*;
  a non-executable script is a failed command.
- The script works but writes where cron's user can't:
  output files under another user's home, a lock in a
  root-owned directory.
- A lock doing its job: `flock -n` skips look exactly
  like "didn't run" unless you log the skips
  ([Overlap and flock](overlap-and-flock.md)).
- The job ran fine and *mailed* its output somewhere
  nobody reads ([Output and Mail](output-and-mail.md)).

Work the steps in order. Most "cron is broken" reports
end at step 1, 3, or 4 — and cron, it turns out, wasn't.
