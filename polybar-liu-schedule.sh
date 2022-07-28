#!/bin/bash

SCHEDULE="https://cloud.timeedit.net/liu/web/schema/ri667XQ6637Z52Qm8Z0306Z6y7YQ600n6Y95Y6gQ60.ics"
SCHEDULE_TIMEZONE="UTC"

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


last_key=""

for line in $(curl -s $SCHEDULE)
do
		line=${line%$'\r'} # Remove DOS newlines
		
		key=$(get_key $line)
		value=$(get_value $line)
		
		# Filter out the wanted fields
		[[ $key == "DTSTART" || $key == "DTEND" ]] && event+=($value)
		[[ $key == "SUMMARY" ]] && event+=(${value::6})
		[[ $last_key == "SUMMARY" ]] && event+=(${line::2})
		[[ $last_key == "LOCATION" ]] && event+=($line)

		# Break when the end of the first event is reached
		[[ $line == "END:VEVENT" ]] && break

		last_key=$key
done

# If the event is empty, exit and indicate an error
(( ${#event[@]} == 0 )) && exit 1

start_time=$(parse_time ${event[0]})
end_time=$(parse_time ${event[1]})

begin=$(get_hour_min "$start_time")
end=$(get_hour_min "$end_time")
date=$(get_date "$start_time")

echo "$date | $begin-$end | ${event[2]} ${event[3]} ${event[4]}"

