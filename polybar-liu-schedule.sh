#!/bin/bash

SCHEDULES=(
		"https://cloud.timeedit.net/liu/web/schema/ri697QQQY62Zn4Q5536354Z1y6Z06.ics" #TDAB01
		"https://cloud.timeedit.net/liu/web/schema/ri697QQQY62Zn4Q5546354Z1y6Z06.ics" #TDDD92
) 

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
						[[ $last_key == "SUMMARY" ]] && last_event+=(${line::2})
						[[ $last_key == "LOCATION" ]] && last_event+=($line)

						# Break when the end of the first event is reached
						[[ $line == "END:VEVENT" ]] && break

						last_key=$key
				done

				# Set the event if it is currently empty, or the new one starts earlier
				if [[ (("${#event[@]}" == 0)) || (("${last_event[0]}" < "${event[0]}")) ]] 
				then
						event=(${last_event[@]})
				fi
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

echo "$date | $begin-$end | ${event[2]} ${event[3]} ${event[4]}"

