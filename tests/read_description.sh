#!/usr/bin/env bash

cd "$(dirname "$0")" || exit 2

verbose=true
lint=false
if [[ "$1" == "-q" ]] || [[ "$1" == "--quiet" ]]
then
	verbose=false
	shift 1
elif [[ "$1" == "--lint" ]]
then
	verbose=false
	lint=true
	shift 1
fi

if [[ ! -f "$1/description.txt" ]]
then
	$verbose && echo "Usage: $0 [-q|--quiet|--lint] <directory>" || true
	exit 2
fi

eval "$(grep "SEPARATOR=" run_tests.sh)"
eval "$(grep "DEPENDENCIES=" run_tests.sh)"

enbls=()
names=()
depss=()
refs=()
cmds=()
max_nlen=9 # Test name
max_dlen=12 # Dependencies
any_has_deps=false
max_rlen=14 # Reference file
max_clen=12 # Command line

first_line="#"
while read -r l
do
	if [[ "$first_line" == "#" ]]
	then
		if [[ "$l" =~ ^# ]]
		then
			$verbose && echo "Test is disabled" || true
			exit 2
		fi
		first_line="$l"
		continue
	fi
	
	if [[ "$l" =~ ^# ]]
	then
		enbl="33"
		l="${l:1}"
	else
		enbl="32"
	fi
	ref="$(echo "$l" | cut -d"$SEPARATOR" -f1)"
	desc="$(echo "$l" | cut -d"$SEPARATOR" -f2)"
	cmd2="$(echo "$l" | cut -d"$SEPARATOR" -f3-)"
	
	name="$(echo "$desc" | cut -d"$DEPENDENCIES" -f1)"
	deps="$(echo "$desc" | cut -d"$DEPENDENCIES" -s -f2-)"
	if [[ -n "$deps" ]]
	then
		any_has_deps=true
		if [[ -z "$(echo "$deps" | cut -d"$DEPENDENCIES" -s -f1-)" ]]
		then
			(( max_dlen = max_dlen < ${#deps} ? ${#deps} : max_dlen ))
		else
			i=1
			while [[ -n "$(echo "$deps" | cut -d"$DEPENDENCIES" -s -f$i-)" ]]
			do
				dep="$(echo "$deps" | cut -d"$DEPENDENCIES" -f$i)"
				(( max_dlen = max_dlen < ${#dep} ? ${#dep} : max_dlen ))
				(( i++ ))
			done
		fi
	fi
	cmd="iverilog $first_line $cmd2 -ocur_test 2>&1"
	
	enbls+=("$enbl")
	names+=("$name")
	depss+=("$deps")
	refs+=("$ref")
	cmds+=("$cmd")
	(( max_nlen = max_nlen < ${#name} ? ${#name} : max_nlen ))
	(( max_rlen = max_rlen < ${#ref} ? ${#ref} : max_rlen ))
	(( max_clen = max_clen < ${#cmd} ? ${#cmd} : max_clen ))
done < "$1/description.txt"

if $verbose
then
	echo -n "Test name"; i=9; while (( i < max_nlen )); do echo -n " "; (( i++ )); done
	if $any_has_deps; then echo -n " | Dependencies"; i=12; while (( i < max_dlen )); do echo -n " "; (( i++ )); done; fi
	echo -n " | Reference file"; i=14; while (( i < max_rlen )); do echo -n " "; (( i++ )); done
	echo " | Command line"
	
	i=0; while (( i < max_nlen )); do echo -n "-"; (( i++ )); done
	if $any_has_deps; then echo -n "-+-"; i=0; while (( i < max_dlen )); do echo -n "-"; (( i++ )); done; fi
	echo -n "-+-"; i=0; while (( i < max_rlen )); do echo -n "-"; (( i++ )); done
	echo -n "-+-"; i=0; while (( i < max_clen )); do echo -n "-"; (( i++ )); done
	echo
fi

idx=0
imax=${#names[@]}

declnames=()

while (( idx < imax ))
do
	fst_dep="$(echo "${depss[idx]}" | cut -d"$DEPENDENCIES" -f1)"
	fst_found=false; for n in "${declnames[@]}"; do if [[ "$n" == "$fst_dep" ]]; then fst_found=true; break; fi done
	
	if $lint
	then
		if [[ -n "$fst_dep" ]]
		then
			failed_deps=""
			if ! $fst_found
			then
				failed_deps="$fst_dep"
			fi
			j=2
			while [[ -n "$(echo "${depss[idx]}" | cut -d"$DEPENDENCIES" -s -f$j-)" ]]
			do
				dep="$(echo "${depss[idx]}" | cut -d"$DEPENDENCIES" -f$j)"
				found=false; for n in "${declnames[@]}"; do if [[ "$n" == "$dep" ]]; then found=true; break; fi done
				$found || failed_deps="$dep"
				(( j++ ))
			done
			if [[ -n "$failed_deps" ]]
			then
				echo "$1: test ${names[idx]} has an external or mistyped dependency $failed_deps"
			fi
		fi
	fi
	if $verbose
	then
		echo -n $'\e['"${enbls[idx]}m${names[idx]}"$'\e[m' || echo -n $'\e[32m'"${names[idx]}"$'\e[m'; i=${#names[idx]}; while (( i < max_nlen )); do echo -n " "; (( i++ )); done
		if $any_has_deps; then echo -n " | $($fst_found && echo $'\e[32m' || echo $'\e[31m')$fst_dep"$'\e[m'; i=${#fst_dep}; while (( i < max_dlen )); do echo -n " "; (( i++ )); done; fi
		echo -n " | ${refs[idx]}"; i=${#refs[idx]}; while (( i < max_rlen )); do echo -n " "; (( i++ )); done
		echo " | ${cmds[idx]}"
		j=2
		while [[ -n "$(echo "${depss[idx]}" | cut -d"$DEPENDENCIES" -s -f$j-)" ]]
		do
			i=0; while (( i < max_nlen )); do echo -n " "; (( i++ )); done
			dep="$(echo "${depss[idx]}" | cut -d"$DEPENDENCIES" -f$j)"
			found=false; for n in "${declnames[@]}"; do if [[ "$n" == "$dep" ]]; then found=true; break; fi done
			echo -n " | $($found && echo $'\e[32m' || echo $'\e[31m')$dep"$'\e[m'; i=${#dep}; while (( i < max_dlen )); do echo -n " "; (( i++ )); done
			echo -n " | "; i=0; while (( i < max_rlen )); do echo -n " "; (( i++ )); done
			echo " |"
			(( j++ ))
		done
	fi
	declnames+=("${names[idx]}")
	(( idx++ ))
done
