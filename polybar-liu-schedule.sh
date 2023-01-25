#!/bin/bash

# The schedules which will be used by the script.
SCHEDULES=(
	"https://cloud.timeedit.net/liu/web/schema/ri667XQ7577Z55Qm6Z0756Z6y2YQ700n6Y43Y0gQ50.ics",
    "https://cloud.timeedit.net/liu/web/schema/ri607QQQY76Zn7Q5238554Z2y6Z06.ics"
) 

SCHEDULE_TIMEZONE="UTC"
WEEK_IN_SECONDS=604800

event=()

# Return the index of the ':' character, which separates the key from the value
get_separator_index () {
    search=":"
    rest=${1#*$search}

    echo $((${#1} - ${#rest}))
}

get_key () {
    index=$(get_separator_index $1)

    (( $index > 0 )) && echo ${1::$(($index - 1))}
}

get_value () {
    index=$(get_separator_index $1)

    (( $index > 0 )) && echo ${1:$(($index))}
}

# Parse a time into a format which is convertable by date
# There is probably a better way to do this, but it works
parse_time () {
    echo "${1::4}-${1:4:2}-${1:6:2} ${1:9:2}:${1:11:2} $SCHEDULE_TIMEZONE"
}

# Return the hour and minute from a parsed time
get_hour_min () {
    echo $(date -d "$1" "+%H:%M")
}

# Return the date from a parsed time
get_date () {
    echo $(date -d "$1" "+%Y-%m-%d")
}

# Return the weekday from a parsed time
get_weekday () {
    day=$(date -d "$1" "+%a")
    echo ${day^}
}

strip_backslash () {
    echo ${1//\\/}
}

get_current_unix () {
    echo $(date "+%s")
}

get_unix_from_time () {
    echo $(date -d "$1" "+%s")
}


# Loop through the different schedules and save the earliest event
get_earliest_event () {
    for schedule in "${SCHEDULES[@]}"
    do
        last_key=""
        last_event=()

        for line in $(curl -s $schedule)
        do
            line=${line%$'\r'} # Remove DOS newlines

            key=$(get_key $line)
            value=$(get_value $line)

            # Filter out the wanted fields
            [[ $key == "DTSTART" || $key == "DTEND" ]] && last_event+=($value)
            [[ $key == "SUMMARY" ]] && last_event+=(${value::6})
			# Strip the last comma to allow for greater variability
            [[ $last_key == "SUMMARY" || $last_key == "LOCATION" ]] && last_event+=(${line%","})

            # Do checks when the end of the event has been reached
            if [[ $line == "END:VEVENT" ]]
            then
                event_time=$(parse_time ${last_event[1]})
                event_unix=$(get_unix_from_time "$event_time")
                current_unix=$(get_current_unix)

                # If the event has not passed, break
                (( $event_unix > $current_unix )) && break

                # Otherwise, reset the event and check the next one
                last_event=()
            fi

            last_key=$key
        done

        # Set the event if it is currently empty or if the new one starts earlier
        [[ (("${#event[@]}" == 0)) || 
            (("${last_event[0]}" < "${event[0]}")) 
        ]] && event=(${last_event[@]})
    done
}

get_earliest_event

# If the event is empty, exit and indicate an error
(( ${#event[@]} == 0 )) && exit 1

start_time=$(parse_time ${event[0]})
end_time=$(parse_time ${event[1]})

begin=$(get_hour_min "$start_time")
end=$(get_hour_min "$end_time")
date=$(get_date "$start_time")
day=$(get_weekday "$start_time")
course=${event[2]}
teaching_type=$(strip_backslash ${event[3]})
location=$(strip_backslash ${event[4]})

# Check if there should be no location and reset it if its the case
[[ "${location::11}" == "DESCRIPTION" ]] && location="- "

# Echo the day if time remaining is less than a week, otherwise the date
if  (( $(date -d "$start_time" "+%s") - $(date "+%s") < $WEEK_IN_SECONDS ))
then
    time=$day
else
    time=$date
fi

# Echo the information that will be caught by Polybar. Modify this string to customize the bar output
echo "$time | $begin-$end | $course | $teaching_type | $location"

