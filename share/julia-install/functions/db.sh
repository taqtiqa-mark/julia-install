#!/usr/bin/env bash

# Query the Julia-install key-value database for a specific key
# allow system specific overrides + warnings / errors
__ji_db_system()
{
  \typeset __key __message
  for __key in "${_system_name}_${_system_version}_$1" "${_system_name}_$1" "$1"
  do
    if __ji_db "${__key}_error" __message
    then ji_error "${__message}"
    fi
    if __ji_db "${__key}_warn" __message
    then ji_warn "${__message}"
    fi
    if __ji_db "${__key}" "$2"
    then return 0
    fi
  done
  true # for OSX
}

# Query the ji key-value database for a specific key
# Allow overrides from user specifications in $ji_user_path/db
__ji_db()
{
  \typeset value key variable
  key="${1:-}"
  variable="${2:-}"
  value=""

  if [[ -f "$ji_user_path/db" ]]
  then value="$( __ji_db_ "$ji_user_path/db"   "$key" )"
  fi
  if [[ -z "$value" && -f "$ji_path/config/db" ]]
  then value="$( __ji_db_ "$ji_path/config/db" "$key" )"
  fi
  [[ -n "$value" ]] || return 1
  if [[ -n "$variable" ]]
  then eval "$variable='$value'"
  else echo "$value"
  fi
  true # for OSX
}

__ji_db_remove()
{
  if
    [[ -f "$1" ]]
  then
    __ji_sed -e "\#^$2=# d"  -e '/^$/d' "$1" > "$1.new"
    \command \mv -f "$1.new" "$1"
  fi
}

__ji_db_add()
{
  \typeset __dir="${1%/*}"
  if   [[ -f "${1}" ]]
  then __ji_db_remove "${1}" "${2}"
  elif [[ ! -d "${__dir}" ]]
  then mkdir -p "${__dir}"
  fi
  printf "%b=%b\n" "$2" "$3" >> "$1"
}

__ji_db_get()
{
  if [[ -f "$1" ]]
  then __ji_sed -n -e "\#^$2=# { s#^$2=##;; p; }" -e '/^$/d' < "$1"
  else echo -n ""
  fi
}

__ji_db_()
{
  \typeset __db __key __value
  __db="$1"
  __key="${2%%\?*}" # remove ?x=y from urls
  shift 2
  __value="$*"
  case "${__value}" in
    (unset|delete)
      __ji_db_remove "${__db}" "${__key}"
      ;;
    ("")
      __ji_db_get    "${__db}" "${__key}"
      ;;
    (*)
      __ji_db_add    "${__db}" "${__key}" "${__value}"
      ;;
  esac
}