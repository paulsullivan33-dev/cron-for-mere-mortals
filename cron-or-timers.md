# Cron or systemd Timers

**Scope:** an honest comparison, because on a modern
Linux both exist and the choice is real. The depth on
the timer side belongs to the companion guide *systemd
for Mere Mortals* — this chapter is the map, not the
territory.

## The same job, two shapes

Cron expresses a schedule as a line in a table. A
systemd timer expresses it as a *pair of unit files* —
a `.timer` that says when, a `.service` that says
what — managed by the same systemd that runs
everything else. Neither is a wrapper around the
other; they're independent systems that happen to
overlap.

## What differs

| Question | cron | systemd timer |
|----------|------|---------------|
| Where's the schedule? | one line in a crontab | a `.timer` unit file |
| What ran, and did it work? | nothing records it; your log file is the record | the journal: starts, exits, failures, all kept |
| Job's output | mailed, or your redirect | the journal, automatically |
| Missed while off/asleep | skipped forever | `Persistent=true` runs it once at next boot |
| Environment | minimal, fixed (ch. 6) | set explicitly per unit; still no login shell |
| Ordering ("after the network") | nothing | real dependency machinery |
| Finer than a minute | no | yes (`OnUnitActiveSec=` and friends) |
| Runs without systemd | yes — anywhere Unix-like | no |
| Randomised delay | hand-rolled (`sleep $RANDOM`-style) | built in (`RandomizedDelaySec=`) |

Three of these deserve emphasis:

**State and evidence.** A timer's last run, result,
and output are inspectable (`systemctl list-timers`,
`journalctl -u …`). Cron's evidence is the CMD line it
logs at start and whatever the job wrote itself. Most
of this guide's debugging chapter exists because cron
keeps so little — timers simply have less to debug.

**Catch-up is a setting, not a second tool.** The
sleeping-machine problem that needs anacron on the
cron side is one keyword on the timer side.

**The systemd guide's lab fired a timer every 15
seconds** and watched it tick — sub-minute schedules
are ordinary there, impossible here.

## What doesn't differ

Timers do not fix a bad command. The job still runs
without your login shell, still needs absolute paths
and a thought-through environment, and a timer will
start an overlapping copy situation just as cron will
if the service allows it (systemd has its own answers
there — again, the other guide's subject).

## A sane default

- The machine runs systemd (most current Linux) and
  the job is *the machine's* → a timer is usually the
  better citizen.
- The job is *yours*, small, and portable — or the
  machine isn't a systemd one (a container, a BSD, an
  old box, a shared host where crontab is what you
  get) → cron, with this guide's habits: a log file of
  your own, `flock -n` on anything that can overrun.
- Knowing cron remains worthwhile even where timers
  win: crontabs are everywhere, decades deep, and they
  will outlive several more replacements.
