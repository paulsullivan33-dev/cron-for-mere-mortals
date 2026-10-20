# What Cron Is

**Scope:** the moving parts — a daemon, some tables of
jobs, and a spool directory — and what cron deliberately
is not.

## Two halves

Cron sounds like one thing and is two:

1. **The daemon** (the `cron` program, run by the
   system). It wakes up once a minute, reads the job
   tables, starts whatever is due, and goes back to
   sleep. It does nothing else — no monitoring, no
   reporting, no memory of what happened last time.
2. **The tables** (crontabs). Plain text files, one per
   user plus some system ones, in a fixed format:
   *when*, then *what to run*. The daemon is useless
   without tables and the tables are inert without the
   daemon.

That's the whole machine. Almost everything confusing
about cron is one of those two halves being mistaken for
the other — a perfectly good table with no daemon
reading it, or a healthy daemon faithfully running a
line that doesn't say what you think it says.

Check: the daemon, alive, on the lab machine (started
with systemd; on a machine without systemd it starts
however that system starts services):

```
$ systemctl start cron
$ pgrep -a cron
6663 /usr/sbin/cron -f -P
```

And before it was started, the same checks told the
truth in the other direction: `crontab -l` said "no
crontab for root" and `pgrep -a cron` found nothing
(exit status 1). Jobs don't fail mysteriously when the
daemon is down; they simply never happen — see
[When It Didn't Run](when-it-didnt-run.md).

## Where the tables live

- **Your crontab** lives in a spool directory —
  `/var/spool/cron/crontabs/<username>` on Debian and
  Ubuntu. You never edit that file directly; the
  `crontab` command is the only door
  ([Managing Your Crontab](managing-your-crontab.md)).

  ```
  $ ls -la /var/spool/cron/crontabs/
  drwx-wx--T 1 root crontab    0 ... .
  -rw------- 1 root root    266 ... root
  ```

  Note the permissions: the directory is guarded and
  your table is mode 600, readable only by you and root.

- **The system's tables** live in the open:
  `/etc/crontab` and the drop-in directory
  `/etc/cron.d/`. Those are ordinary files, edited with
  an ordinary editor — but their format has one extra
  field ([Three Kinds of Crontab](three-kinds-of-crontab.md)).

## What cron is not

- **Not precise.** One minute is the smallest step, and
  a busy machine may start a job a little late. Cron
  makes no promises finer than that.
- **Not persistent.** If the machine is off or asleep
  when a job falls due, the job is skipped — not
  delayed, skipped. (Machines that sleep have a
  companion tool; see
  [Machines That Sleep](machines-that-sleep.md).)
- **Not a supervisor.** If a job crashes, cron notes
  nothing and retries nothing. It will happily start
  the same broken job again next time it's due.
- **Not a shell you recognise.** The world a job runs
  in is much smaller than your login shell — the
  single biggest source of "it works when I run it"
  mysteries ([The Cron Environment](the-cron-environment.md)).

Cron has survived since the 1970s not by growing
features but by refusing to. Everything in this guide
follows from that stubborn smallness.
