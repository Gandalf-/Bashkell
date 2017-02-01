#!/bin/bash

add() { echo $(( $1 + $2 )); }
sub() { echo $(( $1 - $2 )); }
mul() { echo $(( $1 * $2 )); }
div() { echo $(( $1 / $2 )); }

cons(){ echo "$@"; }
cdr() { shift; echo "$@"; }
car() { echo "$1"; }

length() { echo "${#@}"; }
append() { echo "${@:2} ${1}"; }
reverse(){ for ((i=$#; i >= 1; i--)); do echo "${!i}"; done | xargs ; }

list_tail(){ echo ${@:$(( $1 + 2)) }; }
list_ref() { echo ${@:$(( $1 + 2)):1 }; }

curry() {
  : ' function, ... -> any
  evaluates an arbitrary number of curried functions from right to left
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
  : ' function, list -> list
  applies the provided function to every element of the list
  '
  IFS=',' read -ra args <<< "$@"
  for arg in ${args[@]:1}; do
    eval "${args[0]} $arg"
  done | xargs
}

map_lambda() {
  : ' anonymous function, list -> list
  more powerful version of map that allows arbitrary functions to be defined
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
  '
  IFS=',' read -ra args <<< "$@"
  func="${args[0]}"
  init="${args[@]:1:1}"

  for arg in ${args[@]:2}; do
    init=$(eval "$func $init $arg")
  done 

  echo $init
}

curry reverse . cdr . reverse {a..f}
echo

curry car . cdr . cdr {a..e}
echo

map 'echo -n', {a..e}
echo

curry echo . cdr . map echo, {a..f}
echo

curry cons foo . map mul 5 , . cdr {1..5}
echo

map 'rot13 <<<', Hello there foo
echo

map_lambda 'echo $(($1 + 5))', {1..6}
echo

map_lambda 'rot13 <<< $1 | rot13', Hello there
echo

curry mul 5 . add 1 . add 2 3
echo

curry echo a. echo b. echo c
echo

foldl add , 10 , {1..10}
