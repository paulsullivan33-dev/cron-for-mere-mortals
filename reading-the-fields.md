# Reading the Five Fields

**Scope:** the schedule field of a crontab line — what the
five columns mean, and how to read real lines without
guessing.

## The shape of a line

```
17 3 * * * /home/you/bin/backup.sh
```

Five time fields, then the command. In order:

| Field        | Allowed values | Names you can use        |
|--------------|----------------|--------------------------|
| Minute       | 0–59           | —                        |
| Hour         | 0–23           | —                        |
| Day of month | 1–31           | —                        |
| Month        | 1–12           | `jan`–`dec`              |
| Day of week  | 0–7            | `sun`–`sat` (0 and 7 are both Sunday) |

The system's own `/etc/crontab` carries the same diagram,
captured from the lab machine:

```
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed
```

(The `user-name` shown there belongs to system crontabs
only — [Three Kinds of Crontab](three-kinds-of-crontab.md).)

## The four ways to fill a field

Every field is built from four ingredients:

- `*` — every value. "Any."
- A number or name — `3`, `jan`, `fri`. Just that one.
- A **list** — commas: `1,15` = the 1st and the 15th.
- A **range** — a dash: `9-17` = 9 through 17.
- A **step** — a slash after a range or `*`: `*/10` =
  every 10th value in the field, `9-17/2` = every second
  hour from 9 to 17.

That's the whole grammar. Every schedule you will ever
write is those pieces in the five slots.

## Worked readings

Read each line out loud as a sentence — "at minute __,
past hour __, on …". It feels slow for a week and then
it's instant.

```
*/10 * * * *
```
"Every 10 minutes." The step in the minute field does
all the work: minutes 0, 10, 20, 30, 40, 50 of every
hour. This is the shape of the classic 10-minute sync
job.

```
0 9 * * 1
```
"At 09:00 on Mondays." Minute 0, hour 9, any day of the
month, any month, day-of-week 1.

```
30 2 * * *
```
"At 02:30 every day." Day-of-week is `*`, so the day of
the month doesn't matter either — both day fields are
"any".

```
15,45 9-17 * * mon-fri
```
"At :15 and :45, from 09:00 to 17:45, Monday to
Friday." A list, a range, and a name range in one line.

```
0 0 1 jan *
```
"At midnight on 1 January." A single month, named.

```
0 4 * * 0
```
"At 04:00 on Sundays." Day-of-week 0.

## The day-of-month / day-of-week trap

One rule surprises everyone once. When **both** the
day-of-month and day-of-week fields are restricted
(neither is `*`), cron runs the job when **either**
matches — it's an OR, not an AND.

```
0 9 1 * mon
```

This does **not** mean "09:00 on the first Monday of the
month." It means 09:00 on the 1st of every month **and**
09:00 every Monday — five or six runs a month instead
of one. There is no field combination that says "first
Monday"; if you need it, schedule the job for the first
seven days and let the command check the date itself.

Check: read that line again in a month's time and the OR
will still be there. This behaviour is defined in the
`crontab(5)` manual page, not by your cron daemon's mood.

## When a schedule outgrows the fields

Below one minute there is nothing: cron's smallest unit
is a minute, and a job that must run every 20 seconds
wants a different tool (a systemd timer can do it; the
companion guide's lab fired every 15 seconds). Chaining
two lines a minute apart is fine; simulating seconds by
sprinkling `sleep 20` through three copies of a job is a
smell.
