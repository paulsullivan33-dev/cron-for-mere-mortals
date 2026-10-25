# cron for Mere Mortals

**cron** is the clockwork that runs Unix machines when
nobody is watching: a small daemon that wakes every
minute, reads tables of jobs, and starts whatever is
due — backups at 03:00, a sync every ten minutes,
housekeeping on Sundays. It has almost no features,
and that is the point. This guide explains the parts a
mortal actually touches: reading and writing the
schedules, surviving the environment jobs run in,
keeping output and overlaps under control, and
debugging the job that didn't run.

This guide assumes you use a terminal on a Linux
machine and can edit a text file. Everything
cron-specific — fields, spool, system tables — is
explained from zero.

## What this guide covers

- [**What cron is**](what-cron-is.md) — a daemon plus
  tables, and what it deliberately is not
- [**Reading the five fields**](reading-the-fields.md) —
  minutes to months, lists, ranges, steps, and the
  day-fields OR trap
- [**Special strings**](special-strings.md) — `@daily`
  and friends, and what `@reboot` really promises
- [**Three kinds of crontab**](three-kinds-of-crontab.md) —
  yours, `/etc/crontab`, and `/etc/cron.d`, plus the
  extra field that breaks copies
- [**Managing your crontab**](managing-your-crontab.md) —
  list, edit, install, and the removal flag one letter
  from edit
- [**The cron environment**](the-cron-environment.md) —
  the bare world jobs run in, measured
- [**The percent trap**](the-percent-trap.md) — the `%`
  that eats your command
- [**Output and mail**](output-and-mail.md) — where job
  output goes, `MAILTO`, and the log-file habit
- [**Overlap and flock**](overlap-and-flock.md) — when
  a job outlives its schedule
- [**Machines that sleep**](machines-that-sleep.md) —
  cron's skipped-job rule and anacron's memory
- [**Cron or systemd timers**](cron-or-timers.md) — an
  honest comparison
- [**When it didn't run**](when-it-didnt-run.md) — the
  debugging order
- [**Who may cron**](who-may-cron.md) — allow/deny,
  least-privilege users, and the writable-script sin
- [**Glossary**](glossary.md) — the terms, collected in
  one place

## What it doesn't cover

Mail server setup (cron hands output to one; running
one is its own subject), the internals of other
schedulers (at, batch, launchd, Windows Task
Scheduler), and hosted "cron as a service" products.
systemd timers get a comparison chapter here and
their depth in the companion guide, *systemd for Mere
Mortals*.

## How to use this guide

Every command, firing, and failure in this guide was
run for real on cron 3.0pl1 (Ubuntu 24.04): a daemon
was started and read its tables aloud in the log,
every-minute jobs fired and left timestamped files,
broken tables were rejected by name, a 75-second job
on a 60-second schedule skipped exactly as `flock`
intended, and anacron ran a job once and then —
correctly — not again. The example files in
[`examples/`](examples/) are the lab's own files with
the lab's path prefix swapped for `/home/you`.

Two things the lab could not do are labelled where
they belong: a `@reboot` job firing at a genuine
system boot (the sandbox cannot reboot — but the
daemon's refusal to fire one on a mere restart *is*
captured, and it's the more useful fact), and delivery
of job-output mail to a real mailbox (the lab machine
has no mail system; cron's "discarding output" notice
is captured instead). One more sandbox quirk, noted in
the security chapter: unprivileged users' spool access
was blocked by the sandbox ignoring the `setgid` bit,
so the allow/deny chapter shows the refusals — the
point of the test — verbatim, and describes the
allowed case from stock-system behaviour.

---

## Part of the series

This guide is one of the [For Mere Mortals](https://paulsullivan33-dev.github.io/mere-mortals/) guides: plain-language guides to the tools programmers and makers use.

Related guides:

- [systemd for Mere Mortals](https://paulsullivan33-dev.github.io/systemd-for-mere-mortals/)
- [Bash for Mere Mortals](https://paulsullivan33-dev.github.io/bash-for-mere-mortals/)
- [Backups for Mere Mortals](https://paulsullivan33-dev.github.io/backups-for-mere-mortals/)

## License

The writing in this guide is licensed under [CC BY 4.0](https://github.com/paulsullivan33-dev/cron-for-mere-mortals/blob/main/LICENSE). Code examples and lab scripts are licensed under the [MIT License](https://github.com/paulsullivan33-dev/cron-for-mere-mortals/blob/main/LICENSE-CODE).
