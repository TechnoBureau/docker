# docker Image Build

## Generate Cron Configuration
Add below line in postunpack.sh while building the docker file or while start before cron daemon start
```
generate_cron_conf date ' "/opt/technobureau/common/bin/cron.sh" > /proc/1/fd/1 2>&1' --run-as technobureau
```
