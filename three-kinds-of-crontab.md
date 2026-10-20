# Three Kinds of Crontab

**Scope:** user crontabs, `/etc/crontab`, and
`/etc/cron.d/` — same daemon, same fields, one crucial
extra column, and the two mistakes that follow from it.

## The three tables

| Table | Where it lives | Edited with | User field? |
|-------|----------------|-------------|-------------|
| User crontab | spool: `/var/spool/cron/crontabs/<you>` | the `crontab` command only | no — it's already yours |
| System crontab | `/etc/crontab` | any editor (you're root) | **yes** |
| Drop-ins | `/etc/cron.d/<name>` | any editor (you're root) | **yes** |

The user crontab knows whose it is from where it sits,
so its lines are just five fields and a command. The
system tables are shared files, so each line must say
*who runs this*: five fields, **then a username**, then
the command. From the lab machine's own `/etc/crontab`:

```
17 *    * * *   root    cd / && run-parts --report /etc/cron.hourly
25 6    * * *   root    test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.daily; }
```

Those lines run the `/etc/cron.hourly`, `cron.daily`,
`cron.weekly`, and `cron.monthly` directories — folders
of scripts the system runs at those rough times. (On a
machine with anacron installed, the daily-and-later
lines mostly defer to it; see
[Machines That Sleep](machines-that-sleep.md).)

## Mistake 1: a user line in a system table

Copy a working user-crontab line into `/etc/cron.d/`
and it stops being a job and becomes an error. The lab
planted exactly that — no user field:

```
* * * * * echo "broken tick ..." >> /some/file
```

Cron read the first word of the command, `echo`, as the
username, and the daemon logged it in plain words:

```
cron[7485]: Error: bad username; while reading /etc/cron.d/mere-broken
cron[7485]: (*system*mere-broken) ERROR (Syntax error, this crontab file will be ignored)
```

No tick file ever appeared. Note the failure mode: the
*whole file* is ignored, silently apart from that log
line, and other files are unaffected — the neighbouring
`/etc/cron.d/mere-lab` never missed a minute while its
broken sibling sat beside it.

## Mistake 2: the missing final newline

A system crontab file must end with a newline. Leave it
off and the same treatment follows — the lab's second
planted file was a perfectly valid line whose only
defect was ending without one (`od` showed the file
ending in `g`, no `\n`):

```
cron[7485]: (*system*mere-nonewline) ERROR (Missing newline before EOF, this crontab file will be ignored)
```

Your editor probably adds the final newline for you,
which is why this bites people who generate these files
with scripts and `printf`. Check:
`tail -c 1 file | od -c` — you want to see `\n`.

## Which table should a job live in?

- **It's yours, about your files** → your user crontab.
  No root required, no user field, managed with
  `crontab -e`.
- **It's the machine's** — backups, log rotation,
  package housekeeping → `/etc/cron.d/<package-or-job>`
  as root, one file per concern, with the user field
  set to the *least*-privileged account that can do the
  work ([Who May Cron](who-may-cron.md)).
- `/etc/crontab` itself: mostly leave it to the system.
  It's the same format as `cron.d`; the drop-in
  directory exists so you don't have to share one file.

One more `cron.d` house rule: filenames there may use
letters, digits, underscores, and dashes only. A file
named `backup.sh` or `backup.old` is ignored by the
run-parts-style housekeeping lines and, on Debian,
rejected as a crontab for the same naming reason.
