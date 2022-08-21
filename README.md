# polybar-liu-schedule
This is a simple module which shows the next event and course scheduled at LIU. It supports the merging of several schedules to allow for high customizability.
If the next event is scheduled more than a week in advance, the date will be shown instead of the weekday. 

![Polybar](https://i.imgur.com/wuFgfuD.png)

### Dependencies
- Curl
- Date

### Settings
#### Polybar
```ini 
[module/polybar-liu-schedule]
type = custom/script
exec = path/to/script/polybar-liu-schedule.sh
interval = 900
```

#### Script
To add schedules, modify the SCHEDULES-variable in the script.
```bash
SCHEDULES=(
    "https://cloud.timeedit.net/liu/web/schema/ri667QQQY63Zn3Q5861309Z7y6Z06.ics"
    "https://cloud.timeedit.net/liu/web/schema/ria675QQY63Zn3Q5861309Z7y6Z06.ics"
)
```
To change the format, simply modify the string echoed at the end of the script.

```bash
echo "$time | $begin-$end | $course | $teaching_type | $location"
```

### Known Bugs
- ~~Unwanted characters are shown if more than one location is scheduled.~~
- If more than one location is scheduled, only the first will be shown.

### Work in Progress
- Giving the module a minimal-mode which can be expanded by clicking on it.
