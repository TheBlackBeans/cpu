#!/usr/bin/env bash

# To add a new test, go to the line containing "# <--- INSERT HERE" (near the end of the file)
# Between this line and the previous line, insert a new line containing "run_test "<directory_name>""
# This directory contains a file "description.txt" with the following format:
# 
# description.txt:
# <first line, copied directly into the compiler command line for every test>
# <reference>@<name>`<dependency 1>`<dependency 2>...@<copied into the command line for this test>
#
# The entire folder can be skipped by adding a '#' at its very top (eg, the first line starts with a '#')
# or a specific test can be skipped by prepending a '#' at the beginning of the line.

compiler="${1:-iverilog}"

if [[ "$1" = "--help" ]] || [[ "$1" = "-h" ]]
then
	echo "Usage: $0 [compiler]"
	exit 0
fi

successes=0
total=0
major_skips=0
minor_skips=0

failure_txt=""

declare -A passed_tests=()

function test_failed()
{
	# $1 = name; $2 = bold + red; $3 = cmdline; $4 = content
	failure_txt="$failure_txt"$'\n\e[31;1m'"$2"$'\e[0;31m'"; '$3' outputted:"$'\e[m\n'"$4"$'\e[m\n'
	echo -n $'\e[91m\xE2\x80\xA2\e[m'
	passed_tests["$1"]=false
}
function test_succeeded()
{
	# $1 = name
	(( successes++ ))
	echo -n $'\e[92m\xE2\x80\xA2\e[m'
	passed_tests["$1"]=true
}
SKIP_COLOR=33
function test_skipped()
{
	# $1 = name
	(( minor_skips++ ))
	echo -n $'\e['"$SKIP_COLOR"$'m\xE2\x80\xA2\e[m'
	passed_tests["$1"]=false
}

SEPARATOR='@'
DEPENDENCIES='`'

function run_test()
{
	first_line='#'
	echo -n "- Compiling then running tests for '$1' "
	while read -r l
	do
		if [[ "$first_line" = '#' ]]
		then
			first_line="$l"
			# a =~ r
			# true iff a matches the regexp r
			# So '#' is not a comment start
			if [[ "$first_line" =~ ^# ]]
			then
				echo $'\e['"$SKIP_COLOR"$'m- SKIPPING (test disabled)\e[m'
				(( major_skips++ ))
				return
			fi
			continue
		fi
		output_file="$(echo "$l" | cut -d"$SEPARATOR" -f1)"
		desc="$(echo "$l" | cut -d"$SEPARATOR" -f2)"
		compile_files="$(echo "$l" | cut -d"$SEPARATOR" -f3-)"
		
		name="$(echo "$desc" | cut -d"$DEPENDENCIES" -f1)"
		
		if [[ -z "$output_file" ]] || [[ -z "$name" ]] || [[ "$l" =~ ^# ]]
		then
			test_skipped "$name"
			continue
		fi
		if [[ -n "${passed_tests["$name"]+_}" ]]
		then
			test_failed "$name" "Duplicate test '$name'" "" "Other run was a success: ${passed_tests["$name"]}"
			continue
		fi
		i=2
		while [[ -n "$(echo "$desc" | cut -s -d"$DEPENDENCIES" -f$i)" ]]
		do
			dep="$(echo "$desc" | cut -s -d"$DEPENDENCIES" -f$i)"
			if ! [[ -n "${passed_tests["$dep"]+_}" ]]
			then
				test_skipped "$name"
				failure_txt="$failure_txt"$'\n\e['"${SKIP_COLOR}mWarning: test '$name' depends on '$dep', which has not (yet?) been evaluated"$'\e[m\n'
				break
			elif ! ${passed_tests["$dep"]}
			then
				test_skipped "$name"
				break
			fi
			(( i++ ))
		done
		[[ -n "$(echo "$desc" | cut -s -d"$DEPENDENCIES" -f$i)" ]] && continue
		
		(( total++ ))
		# shellcheck disable=SC2086
		output_txt=$($compiler $first_line $compile_files -ocur_test 2>&1)
		ecode=$?
		if [[ $ecode -ne 0 ]]
		then
			test_failed "$name" "Failure compiling the subtest '$name'" "$compiler $first_line $compile_files -ocur_tes" "$output_txt"
			continue
		fi
		
		diff_txt=$(diff <(./cur_test) "$output_file" 2>&1)
		ecode=$?
		if [[ $ecode -ne 0 ]]
		then
			test_failed "$name" "Failure executing the subtest '$name'" "$compiler $first_line $compile_files -ocur_test; diff ..." "$diff_txt"
			continue
		fi
		
		test_succeeded "$name"
	done <"$1"/description.txt
	echo
	[[ -f cur_test ]] && rm cur_test
}

cd "$(dirname "$0")" || exit 2
echo "Testing using '"$'\e[1m'"$compiler"$'\e[m'"' in $(pwd)"

run_test "reg"
# <--- INSERT HERE

echo "$failure_txt"
if [[ $total -eq 0 ]]
then
	echo 'Error: no test executed!'
else
	echo "Summary: $successes/$total tests succeeded ($((100 * successes / total))%)"
fi
if [[ $minor_skips -ne 0 ]]
then
	echo "$minor_skips test$([[ $minor_skips -ne 1 ]] && echo 's have' || echo ' has') been skipped"
fi
if [[ $major_skips -ne 0 ]]
then
	echo "$major_skips test block$([[ $major_skips -ne 1 ]] && echo 's have' || echo ' has') been skipped"
fi
