# The Cron Environment

**Scope:** the small, bare world a cron job runs in —
the cause of most "but it works when I run it"
mysteries — measured, not described from folklore.

## The measurement

Folklore says "cron jobs get almost no environment."
Here is what that meant on the lab machine, from a job
whose entire purpose was to dump its world, every
minute:

```
* * * * * { echo "PWD=$PWD"; echo "SHELL=$SHELL"; echo "PATH=$PATH"; echo "HOME=$HOME"; echo "LOGNAME=$LOGNAME"; /usr/bin/env | sort; } > .../env-dump.txt 2>&1
```

The five lines the job itself vouches for:

```
PWD=/root
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOME=/root
LOGNAME=root
```

Read them as five separate surprises:

- **`PWD=/root`** — the working directory is your home
  directory, *not* wherever you happened to be when
  you wrote the crontab. A relative path in a job
  resolves against `$HOME`.
- **`SHELL=/bin/sh`** — jobs run under `/bin/sh`,
  whatever your login shell is. Bash syntax (arrays,
  `[[ … ]]`, `source`) is not available unless you ask
  for it (below).
- **`PATH=…`** — that PATH is cron's own built-in
  default. Sensible system directories; no `~/bin`, no
  `/usr/local` extras beyond what's shown, nothing your
  shell profile adds — because **your profile is never
  read**.
- **`HOME` and `LOGNAME`** come from the account
  database (`/etc/passwd`), not from any session.

Beyond those, the full dump held only what the daemon
itself had inherited from the service manager that
started it — which is to say: nothing you should rely
on. The rule that survives every machine: **a cron job
gets the five things above and whatever you set
yourself. Anything else you find there is weather, not
climate.**

## Why "it works in my shell" fails

Your interactive shell is a rich place: your profile
has run, exports are set, `PATH` includes your tool
directories, aliases exist, you're sitting in some
directory. A cron job has *none* of that, so the same
command fails in one of a few standard ways. The lab
staged the classic — a script that calls a helper by
bare name, trusting `PATH`:

```
$ ./nightly-report.sh                     # interactive, lab bin/ on PATH
nightly report for 2026-10-20 19:42

$ env -i HOME=/root LOGNAME=root SHELL=/bin/sh \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    /bin/sh -c "cd /root && ./nightly-report.sh"
nightly-report.sh: 4: fancy-date: not found
nightly report for
```

Note the exit status of that second run: **0**. The
script soldiered on with an empty value where the
helper's output belonged. Cron jobs failing *quietly
and successfully* is normal, and it's why the debugging
chapter ([When It Didn't Run](when-it-didnt-run.md))
starts with reproduction, not log-reading. (The
`env -i` command above is that reproduction technique:
empty the environment, put back only what cron
provides, run the job's exact command.)

## Setting the environment yourself

A crontab can set variables — its own tiny header
language. Lines of the form `NAME=value` at the top
apply to every job below them:

```
SHELL=/bin/bash
PATH=/home/you/bin:/usr/local/bin:/usr/bin:/bin
HOME=/home/you

0 3 * * * nightly-report.sh
```

Rules that matter:

- Use **absolute paths** in jobs anyway. A PATH you set
  helps; a command that doesn't need PATH helps more.
- `SHELL=` changes the shell jobs run under — the
  honest fix if a job genuinely needs bash.
- A script that needs *your* environment should say so
  itself (set and export inside the script), not hope
  the crontab provides it. The crontab belongs to the
  schedule; the script belongs to the work.
- Nothing sources `~/.profile` or `~/.bashrc`. If a job
  needs a value from one of those files, copy the value
  into the crontab or the script and let the profile
  stay interactive-only.
