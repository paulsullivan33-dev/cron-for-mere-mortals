# Managing Your Crontab

**Scope:** the `crontab` command — the only supported
way to touch your own table — including the removal
flag that deserves respect.

## The four verbs

```
crontab -l     # list: print your current crontab
crontab -e     # edit: open it in an editor, install on save
crontab file   # install: replace your crontab with this file
crontab -r     # remove: delete your crontab entirely
```

A fresh user has no crontab at all, and `-l` says so:

```
$ crontab -l
no crontab for root
```

(exit status 1 — scripts that call `crontab -l` should
expect that on any account that has never installed
one.)

## Installing from a file, and checking as you go

Keeping your crontab as a file you control — ideally in
version control — beats editing in place, because you
can diff it, review it, and put it back. The round trip:

```
$ cat small-crontab.txt
# my first crontab
17 3 * * * /home/hatch/workspace/cron-lab/out/backup.sh

$ crontab small-crontab.txt
$ crontab -l
# my first crontab
17 3 * * * /home/hatch/workspace/cron-lab/out/backup.sh
```

The installed copy lands in the spool, owned by you,
mode 600:

```
$ ls -la /var/spool/cron/crontabs/
-rw------- 1 root root 266 ... root
```

Never edit that spool file directly. The `crontab`
command validates before it installs; a text editor
doesn't. Watch the validator earn its keep — two
deliberately broken files:

```
$ crontab broken-minute.txt
"broken-minute.txt":0: bad minute
errors in crontab file, can't install.

$ crontab broken-fields.txt
"broken-fields.txt":0: bad day-of-week
errors in crontab file, can't install.
```

Both exit 1, and in both cases **the previous good
crontab stayed installed** — a failed install changes
nothing. (The second error is a nice tell: with only
four fields, cron read the command's first word as the
day-of-week field and objected to *it*. Field counting
is the first thing to check on any rejection.)

## Editing in place: -e

`crontab -e` opens your crontab in `$EDITOR` (or
`$VISUAL`), and installs what you save. Save without
changing anything and it notices:

```
$ EDITOR=/bin/true crontab -e
No modification made
```

`-e` runs the same validation as installing from a
file: a syntax error at save time gets you the error
and a chance to re-edit, not a broken table.

## Removing: -r, the dangerous neighbour

`-r` sits one key from `-e` on the keyboard, and on
this cron it is *not* padded: **plain `crontab -r`
deletes your crontab immediately — no prompt, on a
terminal or in a pipe.** The lab removed a real
crontab both ways; there was nothing to capture but
the aftermath:

```
$ printf 'no\n' | crontab -r   # there is no prompt to answer
$ crontab -l
no crontab for root
```

If you want the prompt, ask for it — `-i` is the
interactive form:

```
$ crontab -r -i
crontab: really delete root's crontab? (y/n)
```

Answering `no` there preserves the crontab; `yes`
removes it. Two habits follow:

- **Back up before you touch anything:**
  `crontab -l > crontab-backup-$(date +%F).txt` first,
  *then* edit or remove. Recovery is then one
  `crontab crontab-backup-….txt` away instead of an
  archaeology project.
- Treat a removed crontab as gone. There is no trash
  can and no undo.

## The audit trail

Every `crontab` command writes to the system log, so
"who changed the table, and when" is answerable on a
shared machine:

```
crontab[6801]: (root) REPLACE (root)
crontab[6815]: (root) DELETE (root)
crontab[6843]: (root) REPLACE (root)
```

(`journalctl -t crontab` on a systemd machine;
`/var/log/syslog` where rsyslog collects it.) REPLACE
means an install, DELETE a removal, LIST a listing.
The daemon logs job executions separately, under the
`CRON` tag — [When It Didn't Run](when-it-didnt-run.md)
walks through both.
