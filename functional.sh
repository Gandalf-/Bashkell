#!/bin/bash

add() { echo $(( $1 + $2 )); }
sub() { echo $(( $1 - $2 )); }
mul() { echo $(( $1 * $2 )); }
div() { echo $(( $1 / $2 )); }

odd() { [[ $(( $1 % 2 )) == 1 ]]; }
even(){ [[ $(( $1 % 2 )) == 0 ]]; }
not() { eval "$@"; if ! (($?)); then false; fi; }
empty(){ [[ -z "$@" ]]; }

cons(){ echo "$@"; }
cdr() { shift; echo "$@"; }
car() { echo "$1"; }

cadr() { . car . cdr "$@"; }
cddr() { . cdr . cdr "$@"; }

length() { echo "${#@}"; }
append() { echo "${@:2} ${1}"; }
reverse(){ for ((i=$#; i >= 1; i--)); do echo "${!i}"; done | xargs ; }

list_tail(){ echo ${@:$(( $1 + 2)) }; }
list_ref() { echo ${@:$(( $1 + 2)):1 }; }

.() {
  : ' function, ... -> any
  evaluates an arbitrary number of curried functions from right to left
  . mul 5 . add 5 . sub 10 5 -> 50
  '
  IFS='.' read -ra args <<< "$@"

  length=$(( ${#args[@]} - 1))
  previous=""

  for i in $(seq $length -1 0); do
    previous="$(eval "${args[i]}""$previous" )"
  done

  echo $previous
}

map() {
  : ' function, list [, list] -> list
  applies the provided function to every element of the list
  map add 5 , {1..5} -> 6 7 8 9 10
  map add , {1..5} , {6..10} -> 7 9 11 13 15
  '
  local func list1 list2 args

  IFS=',' read -ra args <<< "$@"
  func="${args[0]}"
  list1="${args[1]}"
  list2="${args[2]}"

  # single list
  if [[ -z "$list2" ]]; then

    for elem in $list1; do
      eval "$func $elem"
    done | xargs

  # two lists
  else

    while not empty "$list1" && not empty "$list2"; do
      eval "$func $(car $list1) $(car $list2)"
      list1="$(cdr $list1)"
      list2="$(cdr $list2)"
    done | xargs
  fi
}

map_lambda() {
  : ' anonymous function, list -> list
  more powerful version of map that allows arbitrary functions to be defined
  possibly depreciated
  '
  IFS=',' read -ra args <<< "$@"
  eval "function _lambda() { "${args[0]}" ;}"
  map _lambda, "${args[@]:1}" | xargs
}

foldl() {
  : ' function, init, list -> list
  applies the provided function to each element of the list, instead of
  returning a list, the input is applied to init in a way defined by the
  provided function
  foldl add , 100 , {1..5}
  '
  IFS=',' read -ra args <<< "$@"
  func="$(car "${args[@]}")"
  init="$(cadr "${args[@]}")"
  list="$(cddr "${args[@]}")"

  for elem in $list; do
    init="$(eval "$func $init $elem ")"
  done

  echo $init
}

filter() {
  : ' function, list -> list
  applies the function to every element in the list, if the return value is
  true then that element is added to the output list
  '
  IFS=',' read -ra args <<< "$@"
  func="$(car "${args[@]}")"
  list="$(cdr "${args[@]}")"

  for elem in $list; do
    if $(eval "$func" "$elem"); then
      echo "$elem"
    fi
  done | xargs
}

examples() {
  . reverse . cdr . reverse {a..f}

  . car . cdr . cdr {a..e}

  map 'echo -n', {a..e}

  . echo . cdr . map echo, {a..f}

  . cons foo . map mul 5 , . cdr {1..5}

  map 'rot13 <<<', Hello there foo

  map_lambda 'echo $(($1 + 5))', {1..6}

  map_lambda 'rot13 <<< $1 | rot13', Hello there

  . mul 5 . add 1 . add 2 3

  . echo a. echo b. echo c

  foldl add , 10 , {1..10}

  . map echo , . reverse {a..f}
}

while true; do
  echo -n "> "; read -r line

  if [[ "$line" == "quit" ]]; then
    exit
  fi

  eval "$line"
done
