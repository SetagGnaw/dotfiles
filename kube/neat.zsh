# neat - strip managed-fields / noise from output
# install: kubectl krew install neat
#
# examples:
#   kneat get pod mypod -o yaml          # get + clean in one command
#   kneat get deploy myapp -o yaml       # works with any resource
#   kubectl get pod mypod -o yaml | kneat  # pipe mode
#   kgpo mypod -o yaml | kneat           # combine with kubectl-aliases (kgpo, kgd, kgsvc...)
#   koy pod mypod | kneat                # combine with koy alias
function kneat()  { kubectl neat "$@"; }

# ── Fuzzy neat ────────────────────────────────────────────────────────────────
# Requires: fzf, kubectl, kubectl-neat, _kf_* helpers from .zsh_kube_common.sh
#
#  COMMAND     ARGS        DESCRIPTION
#  ──────────────────────────────────────────────────────────────────────────
#  knp        [ns|-A]     fuzzy pick pod(s)        → get yaml | neat  (TAB multi-select)
#  knd        [ns|-A]     fuzzy pick deployment(s) → get yaml | neat  (TAB multi-select)
#  knsvc      [ns|-A]     fuzzy pick service(s)    → get yaml | neat  (TAB multi-select)
#  kn         [ns|-A]     fuzzy pick any resource type → get yaml | neat  (TAB multi-select)
# ─────────────────────────────────────────────────────────────────────────────

# knp — fuzzy pick pod(s), view clean yaml
knp() {
  local ns=$(_kf_ns "$1")
  local -a sels
  sels=("${(@f)$(kubectl get pods ${=ns} --no-headers 2>/dev/null \
    | _kf_fzf --multi --header="Neat: select pod(s)  [$ns]  (TAB multi-select)")}" ) || return
  {
    local first=1
    for sel in "${sels[@]}"; do
      local KF_NAME KF_NS
      _kf_parse_selection "$sel" "$ns"
      (( first )) || echo "---"
      first=0
      kubectl get pod "$KF_NAME" ${=KF_NS} -o yaml | kubectl neat
    done
  } | _kf_save
}

# knd — fuzzy pick deployment(s), view clean yaml
knd() {
  local ns=$(_kf_ns "$1")
  local -a sels
  sels=("${(@f)$(kubectl get deployments ${=ns} --no-headers 2>/dev/null \
    | _kf_fzf --multi --header="Neat: select deployment(s)  [$ns]  (TAB multi-select)")}" ) || return
  {
    local first=1
    for sel in "${sels[@]}"; do
      local KF_NAME KF_NS
      _kf_parse_selection "$sel" "$ns"
      (( first )) || echo "---"
      first=0
      kubectl get deployment "$KF_NAME" ${=KF_NS} -o yaml | kubectl neat
    done
  } | _kf_save
}

# knsvc — fuzzy pick service(s), view clean yaml
knsvc() {
  local ns=$(_kf_ns "$1")
  local -a sels
  sels=("${(@f)$(kubectl get services ${=ns} --no-headers 2>/dev/null \
    | _kf_fzf --multi --header="Neat: select service(s)  [$ns]  (TAB multi-select)")}" ) || return
  {
    local first=1
    for sel in "${sels[@]}"; do
      local KF_NAME KF_NS
      _kf_parse_selection "$sel" "$ns"
      (( first )) || echo "---"
      first=0
      kubectl get service "$KF_NAME" ${=KF_NS} -o yaml | kubectl neat
    done
  } | _kf_save
}

# kn — fuzzy pick any resource type, then pick instance(s), view clean yaml
kn() {
  local ns=$(_kf_ns "$1")
  local resource_type
  resource_type=$(kubectl api-resources --no-headers --verbs=get 2>/dev/null \
    | awk '{print $1}' \
    | _kf_fzf --header="Neat: select resource type") || return
  # Fetch with headers: cluster-scoped kinds have no NAMESPACE column even
  # with -A, so drop -A for them or the wrong column would be taken as the name.
  local out
  out=$(kubectl get "$resource_type" ${=ns} 2>/dev/null) || return
  [[ "$ns" == "-A" && "${out%%[[:space:]]*}" != "NAMESPACE" ]] && ns=""
  local -a sels
  sels=("${(@f)$(printf '%s\n' "$out" | tail -n +2 \
    | _kf_fzf --multi --header="Neat: select $resource_type  [${ns:-cluster}]  (TAB multi-select)")}" ) || return
  {
    local first=1
    for sel in "${sels[@]}"; do
      local KF_NAME KF_NS
      _kf_parse_selection "$sel" "$ns"
      (( first )) || echo "---"
      first=0
      kubectl get "$resource_type" "$KF_NAME" ${=KF_NS} -o yaml | kubectl neat
    done
  } | _kf_save
}
