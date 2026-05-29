- [ ] GET THE FUCKING CRON BRO

```sh
…/dot-config/sketchybar/plugins on  main $ 0s ❯ crontab -l
0 * * * * brew outdated 2>/dev/null | wc -l | tr -d ' ' > /tmp/brew_outdated_count.tmp && mv /tmp/brew_outdated_count.tmp /tmp/brew_outdated_count
```
