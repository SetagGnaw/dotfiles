# File-transfer helpers: scp for single files, rsync for directories or
# resumable transfers. A "pinned" destination is persisted in
# ~/.transfer_host so individual commands stay short.
#
#   pin-host gates@100.65.69.44   # remember this destination
#   pin-host                       # show current pinned host
#   unpin-host                     # forget pinned host
#
#   send file.txt                  # scp to pinned host, ~/shared/file.txt
#   send file.txt user@host:/tmp/  # explicit destination overrides pin
#   send a.txt b.txt :/tmp/        # multiple files; ':' = pinned host
#   sendr ./build                  # rsync -avzP to pinned host:~/shared/
#   sendr ./build :srv/app/        # rsync to pinned host:srv/app/
#
#   get remote.log                 # scp pinned:remote.log -> ./
#   get :/var/log/x.log /tmp/      # ':' prefix forces pinned host
#   getr remote-dir                # rsync -avzP pinned:remote-dir ./
#
# Override the pinned host inline by passing user@host or host: as the
# last arg to send/sendr, or as the source prefix for get/getr.

_transfer_host_file="$HOME/.transfer_host"

_transfer_host() {
  [[ -r $_transfer_host_file ]] && command cat "$_transfer_host_file"
}

_transfer_require_host() {
  local host
  host=$(_transfer_host)
  if [[ -z $host ]]; then
    echo "transfer: no pinned host. Run: pin-host user@host" >&2
    return 1
  fi
  printf '%s' "$host"
}

# Resolve a path arg into a scp/rsync spec.
# - "user@host:path"  -> returned as-is
# - "host:path"       -> returned as-is
# - ":path"           -> rewritten to "<pinned>:path"
# - "path"            -> returned as-is (local)
_transfer_resolve() {
  local arg=$1 host
  if [[ $arg == :* ]]; then
    host=$(_transfer_require_host) || return 1
    printf '%s:%s' "$host" "${arg#:}"
  else
    printf '%s' "$arg"
  fi
}

pin-host() {
  if [[ -z $1 ]]; then
    local current
    current=$(_transfer_host)
    if [[ -n $current ]]; then
      echo "pinned: $current"
    else
      echo "no pinned host. Usage: pin-host user@host"
    fi
    return 0
  fi
  print -r -- "$1" > "$_transfer_host_file"
  echo "pinned: $1"
}

unpin-host() {
  command rm -f "$_transfer_host_file"
  echo "pinned host cleared"
}

# scp send. Last arg may be a destination (user@host[:path], host:path, or
# :path). Otherwise files go to "<pinned>:~/shared/" (basename preserved).
send() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: send <file>... [user@host[:path] | :path]" >&2
    return 1
  fi

  local last=${@[-1]} dest sources host
  if [[ $last == *:* ]]; then
    dest=$(_transfer_resolve "$last") || return 1
    sources=("${@[1,-2]}")
  elif [[ $last == *@* && $last != */* && ! -e $last ]]; then
    # Bare user@host override (no :path); only when it is not an existing
    # local path, so files like icon@2x.png still count as sources.
    host=$last
    dest="${host}:shared/"
    sources=("${@[1,-2]}")
  else
    host=$(_transfer_require_host) || return 1
    dest="${host}:shared/"
    sources=("$@")
  fi

  if [[ ${#sources[@]} -eq 0 ]]; then
    echo "send: no source files" >&2
    return 1
  fi

  # Only the ~/shared destinations set $host; contact the remote after the
  # local checks passed.
  [[ -n $host ]] && { ssh "$host" 'mkdir -p ~/shared' || return 1; }

  scp "${sources[@]}" "$dest"
}

# rsync send (recursive, compressed, with progress + partial resume).
sendr() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: sendr <path>... [user@host[:path] | :path]" >&2
    return 1
  fi

  local last=${@[-1]} dest sources host
  if [[ $last == *:* ]]; then
    dest=$(_transfer_resolve "$last") || return 1
    sources=("${@[1,-2]}")
  elif [[ $last == *@* && $last != */* && ! -e $last ]]; then
    # Bare user@host override (no :path); only when it is not an existing
    # local path, so files like icon@2x.png still count as sources.
    host=$last
    dest="${host}:shared/"
    sources=("${@[1,-2]}")
  else
    host=$(_transfer_require_host) || return 1
    dest="${host}:shared/"
    sources=("$@")
  fi

  if [[ ${#sources[@]} -eq 0 ]]; then
    echo "sendr: no source paths" >&2
    return 1
  fi

  [[ -n $host ]] && { ssh "$host" 'mkdir -p ~/shared' || return 1; }

  rsync -avzP "${sources[@]}" "$dest"
}

# scp pull. First arg is remote (pinned by default), optional second is local dest.
get() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: get <remote-path> [local-dest]" >&2
    return 1
  fi

  local src dst
  src=$1
  dst=${2:-.}

  if [[ $src != *:* ]]; then
    local host
    host=$(_transfer_require_host) || return 1
    src="${host}:${src}"
  else
    src=$(_transfer_resolve "$src") || return 1
  fi

  scp "$src" "$dst"
}

# rsync pull (recursive, compressed, with progress + partial resume).
getr() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: getr <remote-path> [local-dest]" >&2
    return 1
  fi

  local src dst
  src=$1
  dst=${2:-.}

  if [[ $src != *:* ]]; then
    local host
    host=$(_transfer_require_host) || return 1
    src="${host}:${src}"
  else
    src=$(_transfer_resolve "$src") || return 1
  fi

  rsync -avzP "$src" "$dst"
}
