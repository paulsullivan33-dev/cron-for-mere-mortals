# Overlap and flock

**Scope:** what happens when a job outlives its
schedule, and the one-flag tool that decides whether
the next copy waits, skips, or piles up.

## The problem

Cron starts what's due. It does not check whether the
previous copy finished. A sync job on a 10-minute
schedule that takes 25 minutes today — a big file, a
slow network — will be started two more times before
the first one ends. Three copies then write to the
same destination at once, and the error you get is
corruption-flavoured and hard to connect back to
scheduling.

Nothing in cron prevents this. The prevention lives in
the job line, and it's a separate small tool: `flock`,
which takes a lock on a file and runs a command only
while it holds that lock.

## The pattern

```
*/10 * * * * flock -n /home/you/.cache/log-sync.lock /home/you/bin/sync-logs.sh
```

- `flock -n <lockfile> <command>` — try for the lock;
  if this copy gets it, run the command; if a previous
  copy still holds it, **fail immediately**.
- The lock file is just a file; its contents don't
  matter. It lives somewhere writable and unremarkable.
- When the command exits — normally or by crashing —
  the lock is released automatically. A dead run cannot
  wedge the schedule with a stale lock.

This is the pattern behind real housekeeping: a
log-sync job that runs every ten minutes and must
**never run twice at once** wraps itself exactly like
this.

## Measured: a 75-second job on a 60-second schedule

The lab made the overlap certain — a job that sleeps
75 seconds, due every minute, wrapped in `flock -n`,
logging its starts, finishes, and the skips (the
`|| echo` catches `flock`'s failure and writes the
skip down):

```
* * * * * /usr/bin/flock -n .../slow.lock .../slow-job.sh || echo "skipped at $(date -Is) - previous run still going" >> .../flock.log
```

```
started  2026-10-20T19:32:01+00:00
skipped at 2026-10-20T19:33:01+00:00 - previous run still going
finished 2026-10-20T19:33:16+00:00
started  2026-10-20T19:34:01+00:00
```

Read it as a rhythm: start, one skip while it runs,
finish, start again. Without the lock there would have
been two `started` lines before the first `finished`,
and two copies writing at once. With it, overlap is
impossible and the skips are visible in the log
instead of silent.

The same moment, by hand, shows what the failure looks
like up close — a lock held by a sleeper, a second
attempt refused:

```
$ flock -n out/demo.lock sleep 8 &
$ flock -n out/demo.lock echo "second copy ran"
exit=1
```

Nothing printed, no error message: with `-n`, a busy
lock is a silent exit status 1. (That's why the lab's
crontab line adds `|| echo …` — a skip you don't log
is a gap you'll debug later.)

## Skip, wait, or pile up — choose on purpose

`flock` gives the job line three possible policies; the
right one depends on what the job *is*:

- **Skip (`-n`)** — for work whose next scheduled run
  makes a missed run moot: syncs, polls, cleanups.
  Missing one is harmless; doubling one is not.
- **Wait (`-w seconds`)** — for work that must all
  happen, in order, but never simultaneously: a queue
  drainer, an uploader. The lab's manual run:
  `flock -w 10` waited out an 8-second lock holder and
  then ran (exit 0). Beware: waiters can themselves
  queue up into a convoy if the work keeps overrunning.
- **Pile up (no lock)** — almost never right. It's what
  you get by default, which is the only reason it
  happens.

And the opposite question — a job that must **never
be skipped**, where a missed run is lost work — is not
a locking problem at all. It's cron's persistence
limit: a run missed while the machine slept simply
doesn't exist. That job wants anacron or a timer with
catch-up ([Machines That Sleep](machines-that-sleep.md),
[Cron or systemd Timers](cron-or-timers.md)).
