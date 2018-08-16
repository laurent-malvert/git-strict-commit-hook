#!/bin/sh
#
# Copyright (c) 2018 Laurent Malvert <laurent.malvert@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the
# following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# git-better-commit(1) - Git hook to help you write strict commit messages.
#
# Released under the MIT License.
#
# Version 0.7.0
#
# https://gitlab.com/laurent.malvert/git-strict-commit-hook
# (originally from: https://github.com/tommarshall/git-good-commit)
#


###########################################################################
# Environment Setup

HOOK_EDITOR=

RED=
YELLOW=
BLUE=
WHITE=
NC=

is_rule_enabled() {
  get_config "rule${1}" "true"
}

get_config() {
  key="$1"
  default_value="$2"

  git config --get "hooks.strictcommit.${key}" || echo "$default_value"
}

# Set colour variables if the output should be coloured.
set_colors() {
  default_color=$(git config --get hooks.strictcommit.color || git config --get color.ui || echo 'auto')
  if [ -n "$default_color" ] ||
       [ "$default_color" = "always" ] ||
       [ "$default_color" = "auto" ]; then
    RED='\033[1;31m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    WHITE='\033[1;37m'
    NC='\033[0m' # No Color
  fi
}

# Set the hook editor, using the same approach as git.
set_editor() {
  # $GIT_EDITOR appears to always be set to `:` when the hook is executed by Git?
  # ref: http://stackoverflow.com/q/41468839/885540
  # ref: https://github.com/tommarshall/git-good-commit/issues/11
  # HOOK_EDITOR=$GIT_EDITOR
  [ -z "${HOOK_EDITOR}" ] && HOOK_EDITOR="$(git config --get core.editor)"
  [ -z "${HOOK_EDITOR}" ] && HOOK_EDITOR="$VISUAL"
  [ -z "${HOOK_EDITOR}" ] && HOOK_EDITOR="$EDITOR"
  [ -z "${HOOK_EDITOR}" ] && HOOK_EDITOR="vi"
}

set_tty() {
  if tty >/dev/null 2>&1; then
    TTY=$(tty)
  else
    TTY=/dev/tty
  fi
}

set_environment() {
  set_colors
  set_editor
  set_tty

  # something ugly and equivalent to:
  #  ('[A-Z]+-[0-9]+(,([A-Z]+-[0-9]+))*)
  TICKET_PATTERN="$(get_config "ticketformat")"

  RULE_4_LIMIT="$(get_config "rule4" "72")"
  RULE_9_LIMIT=$(get_config "rule6" "72")
}


###########################################################################
# Outputs

# turn on DEBUG=1 to see ugly verbose debug outputs everywhere
debug() {
  if [ "$DEBUG" = "1" ]; then
    echo "$@"
  fi
}

help() {
  echo "${RED}$(cat <<-EOF
a - abort - Abort and exit without committing.
c - continue - Commit anyway, with a potentially invalid message.
e - edit - Edit commit message and re-validate.
? - Print help.
EOF
)${NC}"
}

warning() {
  line_number="$1"
  line="$2"
  warning="$3"

  WARNINGS=$((WARNINGS+1))
  echo "${YELLOW}[x] ${warning}${NC}"
  echo " -> ${WHITE}line ${line_number}: ${line}${NC}"
}


###########################################################################
# Utils

str_trim() {
  echo "$1" | sed -e 's/^[ \t]*//'
}

str_count_words() {
  echo "$(IFS=' '; set -f; set -- $1; echo $#)"
}

str_starts_with() {
  case $2 in
    "$1"*) true;;
    *) false;;
  esac;
}

str_first_word() {
  echo "${1%% *}"
}

str_first_chars() {
  nchars="${2:-1}"
  echo "${1:0:${nchars}}"
}

str_last_chars() {
  nchars="${2:-1}"
  echo "${1:$((${#1}-${nchars})):${nchars}}"
}

str_ids_list() {
  expr "$1" : ${TICKET_PATTERN:-'\([A-Z]\{1,\}-[0-9]\{1,\}\(,\([A-Z]\{1,\}-[0-9]\{1,\}\)\)\{0,\}\).*'}
}

str_after() {
  echo "$(str_trim "${1##${2}}")"
}

###########################################################################
# Good / Better / Stricter Commit Rules

# 1. Prefix the subject line with ticket IDs (format: (([A-Z]+-\d+)[,]?)+ ),
#     followed by a single space.
#     e.g.:
#       - OK: "AB-123 Fix a broken thing"
#       - OK: "AB-123,CD-234 Fix a broken thing"
check_rule_1() {
  tickets="$(str_ids_list "$1")"

  [ -z "$tickets" ] &&
    warning 1 "$1" "#1: Prefix the subject line with ticket ID(s). (here: ${first_word})"
}

# all following rules relating to the subject line will NOT consider the prefix
# checked by rule 1.

# 2. Start the subject line with a word.
check_rule_2() {
  first_word="$(str_first_word "$1")"
  first_char="$(str_first_chars "$first_word")"

  case "$first_char" in
    [A-Z]* | [a-z]*) ;; # we're OK here.
    *) warning 1 "$1" "#2: Start the subject line with a word. (here: ${first_word})";;
  esac
}

# 3. Do no write single worded commits
check_rule_3() {
  [ $(str_count_words "$1") -lt 2 ] &&
    warning $2 "$1" "#3: Do no write single worded commits."
}

# 4. Limit the subject line to RULE_4_LIMIT characters.
#    (recommended default: 72)
check_rule_4() {
  [ "${#1}" -gt $RULE_4_LIMIT ] &&
    warning 1 "${1}" "#4: Limit the subject line to ${RULE_4_LIMIT} characters. (here: ${#1} chars)"
}

# 5. Capitalize the subject line.
check_rule_5() {
  first_word="$(str_first_word "$1")"
  first_char="$(str_first_chars "$first_word")"

  case "$first_char" in
    [A-Z]*) ;; # we're OK here.
    *) warning 1 "$1" "#5: Capitalize the subject line. (here: ${first_word})";;
  esac
}

# 6. Do not end the subject line with a period.
check_rule_6() {
  last_char="$(str_last_chars "$1")"

  [ "$last_char" = "." ] &&
    warning 1 "$1" "#6: Do not end the subject line with a period."
}

# 7. Use the imperative mood in the subject line.
check_rule_7() {
  first_word="$(str_first_word "$1")"
  ending_3_chars="$(str_last_chars "$first_word" 3)"
  ending_2_chars="$(str_last_chars "$first_word" 2)"
  blacklisted_endings="ed ing es un an"
  shopt -s nocasematch
  for ending in ${blacklisted_endings}; do
    case "$ending" in
      $ending_3_chars | $ending_2_chars )
        warning 1 "$1" "#7: Use the imperative mood in the subject line. (potential blacklisted ending: -${ending})"; break;;
    esac
  done
  shopt -u nocasematch
}

# 8. Separate subject from body with a blank line.
check_rule_8() {
  [ -n "${1}" ] &&
    warning 2 "${1}" "#8: Separate subject from body with a blank line."
}

# 9. Wrap the body at RULE_9_LIMIT characters.
#    (recommended: 72)
check_rule_9() {
  URL_REGEX='^[[:blank:]]*(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

  [ "${#1}" -gt 75 ] &&
    warning $2 "$1" "#9: Wrap the body at ${RULE_9_LIMIT} characters. (here: ${#1} chars)"
}

# 10. Document the "why?" and the "how?"
check_rule_10() {
  :
  # No idea how to enforce without being too formal or annoying.
  # Could parse entire message, and fail the words why/how/to/in order/because not found.
  # This forces users to type long-ish messages, and makes dangerous assumptions
  # (but we already do in #5, after all...)
}


###########################################################################
# Commit Message Verifier

check_rule() {
  rule_id="$1"
  line_text="$2"
  line_num="$3"
  if [ "$(is_rule_enabled "${rule_id}")" = "true" ]; then
    check_rule_call="check_rule_${rule_id}"
    $check_rule_call "${line_text}" "${line_num}"
  else
    debug "Rule ${rule_id} is disabled. Skipping check for line ${line_num}."
  fi
}

validate_commit_message() {
  commit_msg_file="$1"
  linum=1      # *active* line number

  WARNINGS=0
  while IFS='' read -r curr_line; do
    debug "-----------------------------------------"
    # trim trailing spaces from commit lines
    clean_curr_line="$(str_trim "${curr_line}")"

    # ignore all lines after cut line
    if [ "$clean_curr_line" = "# ------------------------ >8 ------------------------" ]; then
      return ;
    fi

    # ignore comments (jumpt to next line if starting with #)
    # ignore all first empty lines (like git commit does)
    if ! str_starts_with "#" "${clean_curr_line}"; then
      debug "[+] curr  : ${curr_line}"
      debug "[+] clean : ${clean_curr_line}"
      debug "[+] lineno: ${linum}"

      # all heading lines are skipped
      # checks really start on the 1st active line
      if [ $linum -eq 1 ] && [ -z "$curr_line" ]; then
        debug "[-] Empty heading line. Skipping."
      else
        if [ $linum -eq 1 ]; then
          # capture the subject, and remove the 'squash! ' prefix if present
          full_subject_line="${clean_curr_line/#squash! /}"
          text_subject_line="$(str_after "${full_subject_line}" "$(str_ids_list "${full_subject_line}")")"

          debug "[+] subject: ${full_subject_line}"
          debug "[+] subject: ${text_subject_line}"

          # if the commit subject starts with 'fixup! '
          # there's nothing to validate, we can return here
          [ "${full_subject_line}" != "${full_subject_line#fixup! }" ] &&
            return

          check_rule 1 "${full_subject_line}" "${linum}"
          check_rule 2 "${text_subject_line}" "${linum}"
          check_rule 3 "${text_subject_line}" "${linum}"
          check_rule 4 "${text_subject_line}" "${linum}"
          check_rule 5 "${text_subject_line}" "${linum}"
          check_rule 6 "${text_subject_line}" "${linum}"
          check_rule 7 "${text_subject_line}" "${linum}"
        else
          if [ $linum -eq 2 ]; then
            if [ -n "${clean_curr_line}" ]; then
              check_rule 8 "${curr_line}"
            fi
          elif [ "${clean_curr_line}" != "" ]; then
            check_rule 9 "${curr_line}" "${linum}"
            check_rule 10 "${curr_line}" "${linum}"
          fi
        fi
        linum=$((linum+1))
      fi
    else
      debug "[-] Comment line. Skipping."
    fi
  done < "$commit_msg_file"
  return $WARNINGS
}

menu() {
  response="?"

  # if non-interactive don't prompt and exit with an error
  if [ ! -t 1 ] && [ -z ${FAKE_TTY+x} ]; then
    return 1
  fi
  while [ "$response" = "?" ]; do
    echo "${BLUE}Proceed with commit? [a/c/e/?] ${NC}"
    read response < "$TTY"
    case "$response" in
      [Aa]) return 1 ;;
      [Cc]) return 0 ;;
      [Ee]) $HOOK_EDITOR "$1"; return 2 ;;
      *)    response="?"; help ;;
    esac
  done
  return 0
}

# Validate the contents of the commmit msg against the Strict Commit rules.
# Query for user action on any detected error.
check_commit_message_file() {
  while ! validate_commit_message "${1}"; do
    menu "${1}"
    RET=$?
    ( [ $RET -eq 0 ] || [ $RET -eq 1 ] ) && return $RET
  done
}

main() {
  set_environment
  check_commit_message_file "${1}"
}

main "$@"
exit $?
