# Machines That Sleep

**Scope:** cron's hard rule — a job due while the
machine was off or asleep is *skipped, forever* — and
anacron, the companion built for exactly that.

## The gap in cron

Cron is a clock, not a checklist. It wakes each
minute, asks "what's due *now*?", and runs it. A
laptop closed at 02:55 misses the 03:00 backup; when
it opens at 09:00, cron doesn't remember the backup
was ever owed. For always-on servers the rule rarely
bites. For laptops and desktops — machines that sleep
nights and weekends — it quietly deletes exactly the
jobs those machines most need: backups, updates,
housekeeping.

## anacron: cron with a memory

**anacron** answers a different question: "what's
*due*, given when it last ran?" It keeps, per job, a
timestamp file recording the last run date, and when
anacron itself runs (at boot, on a timer, when you call
it), it runs any job whose period has elapsed since
its timestamp — then updates the timestamp.

Its table, `/etc/anacrontab`, has different fields:
**period in days, delay in minutes, a job name, the
command**. The lab machine's stock table:

```
1   5   cron.daily    run-parts --report /etc/cron.daily
7   10  cron.weekly   run-parts --report /etc/cron.weekly
@monthly 15 cron.monthly run-parts --report /etc/cron.monthly
```

That's the machinery behind `/etc/cron.daily` and
friends on desktops: cron's own `/etc/crontab` lines
for those directories defer to anacron when it's
installed, so a daily job on a laptop means "once a
day, whenever the machine is awake", not "at 06:25 or
never". The delay column (5, 10, 15 minutes) spreads
the catch-up work out after a boot instead of firing
everything in the first minute.

There's no anacron daemon in the cron sense: something
has to *invoke* anacron — a systemd timer, a boot
script, or you. It also works at day granularity:
nothing in anacron says "at 09:00"; the finest promise
is "once per period, when the machine is on."

## The lab run: forced, then honest

A one-line lab table (`1 0 mere-daily <script>`) and a
private spool directory of timestamps. First, anacron
forced to ignore timestamps (`-f`) and delays (`-n`),
in debug mode (`-d`) so it talks:

```
$ anacron -d -f -n -t lab-anacrontab -S spool
Anacron 2.3 started on 2026-10-20
Will run job `mere-daily'
Jobs will be executed sequentially
Job `mere-daily' started
Job `mere-daily' terminated
Normal exit (1 job run)

$ cat spool/mere-daily
20261020
```

Then the same invocation *without* forcing — the
normal case, later that day:

```
$ anacron -d -t lab-anacrontab -S spool
Anacron 2.3 started on 2026-10-20
Normal exit (0 jobs run)
```

The job's output file was unchanged: one run, total.
The timestamp file said "ran today"; the period said
"every 1 day"; so there was nothing owed, and anacron
correctly did nothing. That boring second run **is**
the feature — it's what "daily" means on a machine
that might have been asleep at the appointed hour.

Check (`anacron -T -t your-anacrontab` test mode)
validates a table without running anything — the lab's
table passed with exit 0 before its first real run.

## Choosing between them

- The machine is always on and the minute matters →
  cron.
- The machine sleeps and the *day* matters → anacron
  (or a systemd timer with catch-up — next chapter).
- Both live happily on one machine; the stock tables
  above show the usual split, daily-and-slower to
  anacron, finer schedules to cron.
