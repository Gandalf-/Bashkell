#!/bin/bash

# usage: 
#  source functional.sh
#  echo "done!"

tmp_fifo='/tmp/funcfifo'
rm -f ${tmp_fifo}
mkfifo ${tmp_fifo}
exec 5<>${tmp_fifo}

# core
add() { 
  if int "$1" && int "$2"; then echo $(( $1 + $2 ))
  else bc <<< "scale=4; $1 + $2"; fi
}
sub() { 
  if int "$1" && int "$2"; then echo $(( $1 - $2 ))
  else bc <<< "scale=4; $1 - $2"; fi
}
mul() { 
  if int "$1" && int "$2"; then echo $(( $1 * $2 ))
  else bc <<< "scale=4; $1 * $2"; fi
}
div() {
  if int "$1" && int "$2"; then echo $(( $1 / $2 ))
  else bc <<< "scale=4; $1 / $2"; fi
}
mod() { 
  if int "$1" && int "$2"; then echo $(( $2 % $1 ))
  else bc <<< "scale=4; $2 % $1"; fi
}

odd() { [[ $(( $1 % 2 )) == 1 ]]; }
even(){ [[ $(( $1 % 2 )) == 0 ]]; }
not() { eval "$@"; if ! (($?)); then false; fi; }
empty(){ [[ -z "$@" ]]; }
int() { [[ "$1" -eq "$1" ]] 2>/dev/null; }

cons(){ echo "$@"; }
cdr() { shift; echo "$@"; }
car() { echo "$1"; }

cadr() { .. car . cdr "$@"; }
cddr() { .. cdr . cdr "$@"; }

length() { echo "${#@}"; }
append() { echo "${*:2} ${1}"; }
reverse(){ for ((i=$#; i >= 1; i--)); do echo "${!i}"; done | xargs ; }

drop(){ echo "${*:2:$(($# - $1 - 1))}"; }
take(){ echo "${*:2:$1}"; }
last() { .. car . reverse "$@"; }

list_tail(){ n=$1; shift; echo "${*:(-$n)}"; }
list_ref() { echo "${*:$(( $1 + 2)):1 }"; }

where() {
  : ' variable = expression
  this method of variable assignment is 6 times faster than subshells

  where foo = car {1..10}
  where foo = car {1..10} , bar = cdr {5..15}
  '
  local var="$1"; shift ; shift
  "$@" >&5
  read -r "${var}" <&5
}

assign() {
  local var="$1"; shift
  "$@" >&5
  read -r "${var}" <&5
}

..() {
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

  echo "$previous"
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
      where arg1 = car "$list1"
      where arg2 = car "$list2"
      eval "$func $arg1 $arg2"
      where list1 = cdr "$list1"
      where list2 = cdr "$list2"
    done | xargs
  fi
}

foldl() {
  : ' function, init, list -> list
  applies the provided function to each element of the list, instead of
  returning a list, the input is applied to init in a way defined by the
  provided function
  foldl add , 100 , {1..5}
  '
  local func init list args

  IFS=',' read -ra args <<< "$@"
  func="${args[0]}"
  init="${args[1]}"
  list="${args[2]}"

  for elem in $list; do
    where init = eval "$func $init $elem"
  done

  echo "$init"
}

filter() {
  : ' function, list -> list
  applies the function to every element in the list, if the return value is
  true then that element is added to the output list
  filter even , {1..100}
  '
  IFS=',' read -ra args <<< "$@"
  where func = car "${args[@]}"
  where list = cdr "${args[@]}"

  for elem in $list; do
    if eval "$func" "$elem"; then
      echo "$elem"
    fi
  done | xargs
}

lambda() {
  eval "function _lambda() { eval $* ; }"
  export -f _lambda
  echo _lambda
}

flip() {
  : ' function x y -> function y x
  flip sub , 10 , 5
  '
  IFS=',' read -ra args <<< "$@"
  func="${args[0]}"
  arg1="${args[1]}"
  arg2="${args[2]}"

  eval "$func $arg2 $arg1" | xargs
}

sum() { foldl add, 0, "$@"; }
avg() { .. div "$(sum "$@")" . length "$@"; }
srt() { printf '%s\n' "$@" | sort -n; }
rand() { for ((i=0; i < $1; i++)); do echo $RANDOM; done | xargs; }

examples() {
  .. reverse . cdr . reverse {a..f}
  .. car . cdr . cdr {a..e}
  map 'echo -n', {a..e}
  .. echo . cdr . map echo, {a..f}
  .. cons foo . map mul 5 , . cdr {1..5}
  map 'rot13 <<<', Hello there foo
  .. mul 5 . add 1 . add 2 3
  .. echo a. echo b. echo c
  foldl add , 10 , {1..10}
  .. map echo , . reverse {a..f}
  drop 3 {1..10}
  .. reverse . list_tail 5 . take 50 {1..100}
  .. filter not even , . map mod 5 , {1..100}
}
