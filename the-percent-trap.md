# The Percent Trap

**Scope:** the single most surprising rule in the
crontab format — in the command field, `%` does not
mean what you think.

## The rule

In a crontab line, the **first unescaped `%` in the
command field ends the command**. Everything after it
is fed to the command as standard input, and any
further `%` characters become newlines in that input.

Nothing else in Unix works like this, which is why it
ambushes everyone exactly once — usually inside a
`date +format`, the place `%` is most natural.

## The ambush, staged

Two lab jobs, identical except for escaping, both
appending to files so the difference can't hide:

```
* * * * * /bin/date >> .../percent-ok.log   2>&1 +\%Y-\%m-\%d
* * * * * /bin/date >> .../percent-trap.log 2>&1 +%Y-%m-%d
```

After three minutes:

```
$ cat percent-ok.log
2026-10-20
2026-10-20
2026-10-20

$ cat percent-trap.log



```

Three blank lines. The unescaped job *ran* — the file
grew on schedule — but cron split its command at the
first `%`, so what actually executed was just
`/bin/date +` (a format string of "+" and nothing else
prints an empty line), while `Y-%m-%d` was delivered to
`date`'s standard input, which it politely ignored.
The daemon's log even shows the amputation — it
records the command it ran, not the one you wrote:

```
CRON[7251]: (root) CMD (/bin/date >> .../percent-trap.log 2>&1 +)
```

Everything past the `%` is simply not in the log line,
because as far as cron is concerned it was never part
of the command.

## The fix

Escape every literal percent as `\%`:

```
0 4 * * * tar czf /backups/app-$(date +\%Y\%m\%d).tar.gz /srv/app
```

The backslash is consumed by cron, and the command
sees a plain `%`. This applies everywhere in the
command field — `date` formats, `printf` formats,
`strftime`-style strings in other tools.

Check: after any crontab edit that touches `%`, find
the job's CMD line in the log after its next run and
read what's actually there. If the line ends earlier
than your command does, an unescaped `%` is why.
