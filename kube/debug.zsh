# Example using netshoot to debug a running pod
# kubectl debug -it <pod-name> \
#   --image=nicolaka/netshoot \
#   --target=<container-name-inside-pod>

# debug - ephemeral container into a pod; picks image interactively if not given
# usage: kdebug <pod> [image]
function kdebug() {
  local pod=${1:?usage: kdebug <pod> [image]}
  local image=$2

  if [[ -z "$image" ]]; then
    local -a options=(
      "busybox               basic shell + coreutils"
      "nicolaka/netshoot     network: dig/curl/tcpdump/ip/ss/iperf3"
      "alpine                lightweight, apk package manager"
      "ubuntu                familiar env, apt package manager"
      "curlimages/curl       just curl, minimal footprint"
      "postgres              psql client for DB access"
      "bitnami/kubectl       kubectl inside the cluster"
    )
    print "Select debug image:"
    local i
    for i in {1..${#options[@]}}; do
      printf "%2d) %s\n" $i "${options[$i]}"
    done
    local ncustom=$(( ${#options[@]} + 1 ))
    printf "%2d) custom\n" $ncustom
    print -n "Enter number [1-$ncustom]: "
    local choice
    read choice
    if [[ "$choice" == "$ncustom" ]]; then
      print -n "Enter image: "
      read image
    elif [[ "$choice" -ge 1 && "$choice" -le "${#options[@]}" ]]; then
      image=${options[$choice]%%  *}
    else
      print "Invalid selection"
      return 1
    fi
  fi

  kubectl debug -it "$pod" --image="$image" --profile=general -- sh
}
