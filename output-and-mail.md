# Output and Mail

**Scope:** where a job's output goes — cron's answer
being "the mail", what that means on a modern machine,
and the habit that replaces it.

## Cron's one reporting channel

A cron job's standard output and standard error are
not thrown away, and they are not logged. Cron collects
them and **mails them to the job's owner**. That design
made sense when every machine ran a mail server and
every user read local mail. It surprises people now,
mostly by producing silence.

The lab ran a deliberately noisy job — one line of
output a minute, no redirect — on a machine with no
mail system installed:

```
* * * * * echo "noisy job: this output has nowhere to go"
```

The job ran (its CMD lines are in the log), and once a
minute the daemon noted the output's fate, verbatim:

```
CRON[7096]: (CRON) info (No MTA installed, discarding output)
```

No mail arrived, no file grew, nothing failed. On a
machine *with* a mail transfer agent, the same setup
delivers those lines to the owner's local mailbox
(`/var/mail/<you>`) — a place almost nobody reads,
which is its own kind of silence. This guide did not
capture a delivery: the lab box has no MTA, by design,
and the discard notice above is the honest receipt.

## MAILTO: choosing the destination

The crontab header variable `MAILTO` names who gets
job output:

```
MAILTO=you@example.com
```

- Set it to an address your mail system can actually
  deliver, and output becomes email — reasonable on a
  machine with working mail, a deliverability question
  everywhere else.
- Set it **empty** and you declare "no mail, ever":

  ```
  MAILTO=""
  ```

  The lab added exactly that line to the noisy
  crontab: at the next minute the job still ran (its
  CMD line is in the log) and the *discarding output*
  notice was simply gone — zero in the window that
  followed. The output now vanishes by your decision
  rather than by default.

`MAILTO` applies to every job in the crontab below the
line. Per-job control comes from redirects, which is
the better tool anyway.

## The habit that replaces mail: a log of your own

For any job you care about, send output to a file you
chose, both streams, append mode:

```
0 3 * * * /home/you/bin/backup.sh >> /home/you/logs/backup.log 2>&1
```

- `>>` **appends** — the log becomes a history. (`>`
  would keep only the most recent run, which is
  occasionally what you want and usually a surprise.)
- `2>&1` folds errors into the same file, in order.
  Without it, errors still go to the mail channel —
  the channel you just learned not to trust.
- A job that produces **no output at all** on success
  is the polite ideal: then the file grows only when
  there's something to read, and any mail that does
  arrive means trouble. Design scripts that way:
  quiet on success, explicit on failure.
- Remember the log grows forever unless something
  rotates it. On a system machine that's logrotate's
  job; for a personal log, a line count you check
  occasionally is fine.

Check: two runs of the backup, one forced to fail, and
`backup.log` should show the first run's line and the
second run's error, in order, nothing mailed anywhere.
