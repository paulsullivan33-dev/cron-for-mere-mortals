#!/bin/sh
# Stands in for every real script that works interactively and fails under cron:
# it calls a helper by bare name, trusting PATH to know where it lives.
echo "nightly report for $(fancy-date)"
