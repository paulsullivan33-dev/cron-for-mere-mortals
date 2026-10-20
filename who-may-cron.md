# Who May Cron

**Scope:** the access rules around cron — who is
allowed a crontab at all, whose jobs should run as
whom, and the one configuration that turns a crontab
into a privilege-escalation machine.

## The gate: cron.allow and cron.deny

By default, every user may have a crontab. Two files
in `/etc` narrow that:

- **`/etc/cron.allow`** — if it exists, *only* users
  listed in it (one per line) may use `crontab`.
- **`/etc/cron.deny`** — if there's no allow file,
  users listed in the deny file are refused.

The lab created a user `mere` and ran the experiment
both ways. With an allow file naming only root:

```
$ su - mere -c "crontab -l"
You (mere) are not allowed to use this program (crontab)
See crontab(1) for more information
```

With `mere` in a deny file instead, the identical
refusal. Exit status 1 both times, and the refusal is
the `crontab` command's — the files gate the *tool*,
so a refused user can't install, list, or remove a
crontab at all.

(Leaving both files absent restores the default. One
lab note: on the sandbox, mere's *allowed* runs then
failed at the spool directory — the sandbox silently
ignores the `setgid` bit the real `crontab` binary
uses to reach it, verified with a test binary. That's
this box's quirk, not cron's behaviour; on a stock
system an allowed user's `crontab -l` answers "no
crontab for mere".)

Root is never gated by these files. And note what the
gate doesn't do: it says nothing about the *system*
tables — those are root's files, protected by ordinary
file permissions.

## Run jobs as the smallest user that works

Every job runs as *somebody*, and that choice is a
security decision:

- A **user crontab** job runs as that user, with that
  user's powers. Default to this.
- A **system table** job runs as the user its user
  field names. `root` is the common entry and the
  lazy one: a backup that only reads your documents
  doesn't need to be root; name your own account and
  the job's worst day gets smaller.
- Root jobs earn their keep only for genuinely
  system-level work — and they make the next section
  load-bearing.

## The cardinal sin: a root job running a writable script

If root's crontab runs `/home/you/bin/backup.sh`, then
anyone who can edit that script *is root*, on a timer.
The rule, worth stating flatly:

> **Never schedule, as root (or any other user), a
> script that a less-privileged user can modify.**

Check the whole chain, not just the file: the script,
the directory it sits in, any file it reads commands
or configuration from. Root-owned scripts live in
root-owned directories (`/usr/local/sbin` is the
customary place). The `crontab` command protects the
tables themselves — spool files are mode 600 and
system tables are root's — but it cannot protect what
the tables *point at*.

Two smaller corollaries:

- A user crontab on a shared machine is still that
  user's whole authority, on a schedule, unattended.
  Treat a surprising crontab the way you'd treat a
  surprising shell profile: as something to explain.
  (`journalctl -t crontab` shows who installed what,
  when.)
- Don't widen the gate casually: adding a service
  account to `cron.allow` is giving that account a
  timed, unattended execution path. That's sometimes
  the point. Do it on purpose.
