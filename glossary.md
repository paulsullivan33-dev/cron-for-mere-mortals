# Glossary

**anacron** — cron's companion for machines that
sleep. Instead of clock times it tracks *when each job
last ran* (timestamp files) and runs whatever is due
by period — "daily" means once a day, whenever the
machine is awake.

**CMD line** — the log entry cron writes when it starts
a job: `CRON[pid]: (user) CMD (the command)`. The
primary evidence that a job ran — and a record of the
command as cron understood it, percent-split and all.

**cron.allow / cron.deny** — files in `/etc` gating who
may use the `crontab` command at all. If the allow file
exists, only its users may; otherwise the deny file's
users may not. Root is never gated.

**crontab** — two things sharing a name: a *table* of
jobs (five time fields plus a command per line), and
the *command* that installs, lists, edits, and removes
your personal table.

**cron.d** — `/etc/cron.d/`: a directory of system
crontab files, one per concern. Same format as
`/etc/crontab`, including the extra user field and the
final-newline rule.

**daemon** — a background program that runs whether or
not anyone is logged in. Cron's daemon wakes each
minute, reads the tables, and starts what's due.

**day fields trap** — with both day-of-month and
day-of-week restricted, a job runs when *either*
matches (OR), not when both do (AND).

**fields** — the five time columns of a crontab line:
minute, hour, day of month, month, day of week.

**flock** — a small tool that runs a command while
holding a lock on a file. `flock -n lockfile command`
runs the command only if no other copy holds the lock,
which is how cron jobs keep from overlapping themselves.

**job** — one line of a crontab: a schedule plus a
command, run as the table's owner (or the user field's
account, in system tables).

**MAILTO** — a crontab header variable naming where
job output is mailed. Set it empty (`MAILTO=""`) to
send output nowhere, on purpose.

**MTA** — mail transfer agent (Postfix, Exim, …): the
mail system cron hands job output to. Without one, cron
logs "No MTA installed, discarding output" and the
output is simply gone.

**percent trap** — in a crontab command, the first
unescaped `%` ends the command; the rest becomes the
command's standard input. Escape literal percents as
`\%`.

**@reboot** — the special string meaning "run once at
system startup". A daemon restart later in the day does
*not* re-trigger it; cron checks whether this is really
system startup and logs the skip when it isn't.

**spool** — `/var/spool/cron/crontabs/`: where user
crontabs actually live, one file per user, managed
only through the `crontab` command.

**step** — the `/` in a field: `*/10` means every
10th value; `9-17/2` means every second value in the
range.

**system crontab** — `/etc/crontab` and the files in
`/etc/cron.d/`. Their lines carry a sixth field, the
user the job runs as.

**timestamp file** — anacron's memory: one small file
per job recording the date it last ran, compared
against the job's period to decide what's owed.
