# Special Strings

**Scope:** the `@word` shortcuts that replace the five
fields — what each one means, and the fine print on
`@reboot`, which is not what most people assume.

## The shortcuts

A crontab line can replace all five fields with a
single word:

| String      | Means                            | Equivalent fields |
|-------------|----------------------------------|-------------------|
| `@hourly`   | once an hour, on the hour        | `0 * * * *`       |
| `@daily`    | once a day, at midnight          | `0 0 * * *`       |
| `@midnight` | same as `@daily`                 | `0 0 * * *`       |
| `@weekly`   | midnight on Sunday               | `0 0 * * 0`       |
| `@monthly`  | midnight on the 1st              | `0 0 1 * *`       |
| `@yearly`   | midnight on 1 January            | `0 0 1 1 *`       |
| `@annually` | same as `@yearly`                | `0 0 1 1 *`       |
| `@reboot`   | once, when the system starts     | *(no equivalent)* |

The time-based strings are pure shorthand — the daemon
expands them to the fields shown, and they behave
exactly like the numeric form. `@reboot` is the odd one
out: it's not a schedule at all.

## What @reboot really promises

`@reboot` does not mean "when the cron daemon
(re)starts." It means **when the system starts** — and
cron can tell the difference.

The lab's crontab carried this line:

```
@reboot echo "reboot job fired at $(date -Is)" >> /home/hatch/workspace/cron-lab/out/reboot.log
```

Restarting the daemon — both a `systemctl restart cron`
and a full stop/start — produced **no run and no file**.
The daemon's own log says why, verbatim, once per
start:

```
cron[7205]: (CRON) INFO (Skipping @reboot jobs -- not system startup)
```

Debian and Ubuntu's cron checks how long the machine
has been up; a daemon started long after boot concludes
"this is not system startup" and leaves `@reboot` jobs
alone. That's a feature wearing a disguise: restarting
a service for maintenance shouldn't re-fire every
user's boot jobs on a shared machine.

Two practical consequences:

- **You cannot test an `@reboot` job by restarting
  cron.** On a real machine you'd reboot, or wait for
  the next real boot and check afterwards:
  `journalctl -t CRON | grep -i reboot` plus whatever
  the job itself was supposed to produce.
- **The lab could not capture a genuine boot-time
  firing** — a sandbox you cannot reboot gives you the
  skip, not the run. The firing itself is documented
  behaviour, labelled as such here: the job runs once,
  shortly after boot, as the crontab's owner, in the
  usual minimal environment
  ([The Cron Environment](the-cron-environment.md)).

One more limit, true however it fires: an `@reboot` job
is not a service. Nothing restarts it if it dies,
nothing orders it after the network or the disks it
might need, and a long-running one is just a process
cron has forgotten about. If the thing must stay up,
that's a service's job — the systemd guide's territory.
