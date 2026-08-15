# ─────────────────────────────────────────────────────────────────────────────
# Fuzzy kubectl — fzf-powered interactive resource selection
# Requires: fzf, kubectl, jq (for kfsec), _kf_* helpers from .zsh_kube_common.sh
# ─────────────────────────────────────────────────────────────────────────────
#
#  COMMAND     ARGS                        DESCRIPTION
#  ─────────────────────────────────────────────────────────────────────────
#  kfl         [ns|-A]           fuzzy pick pod → stream logs (multi-container aware)
#  kfe         [ns|-A]           fuzzy pick pod → exec shell (bash → sh fallback)
#  kfd         [ns|-A] [type]    fuzzy pick resource → describe
#  kfg         [ns|-A]           fuzzy pick from all resources → get yaml

#  kfcr        [-dr] [ns]        fuzzy kubectl create (resource type)
#  kfrun       [ns]              fuzzy imperative: kubectl run / kubectl expose
#  kfrm        [ns|-A]           fuzzy pick any resource → delete (with confirm)
#  kfla        [ns|-A]           fuzzy pick any resource → add/remove label

#  kfsec       [ns|-A]           fuzzy pick secret → base64-decode all keys
#  kfcm        [ns|-A]           fuzzy pick configmap → view yaml
#  kfcan       [ns|-A]           fuzzy kubectl auth can-i (verb + resource picker)
# ─────────────────────────────────────────────────────────────────────────────

# ── Commands ─────────────────────────────────────────────────────────────────

# kfl — fuzzy pod logs (multi-container aware)
# Usage: kfl [namespace|-A] [extra kubectl logs flags]
kfl() {
  local ns=$(_kf_ns "$1"); shift 2>/dev/null
  local sel
  sel=$(kubectl get pods ${=ns} --no-headers --show-labels 2>/dev/null \
    | _kf_fzf --header="Logs: select pod  [$ns]") || return
  local KF_NAME KF_NS
  _kf_parse_selection "$sel" "$ns"

  local containers
  containers=$(kubectl get pod "$KF_NAME" ${=KF_NS} \
    -o jsonpath='{.spec.containers[*].name}' 2>/dev/null | tr ' ' '\n')

  local container_flag=""
  if [[ $(echo "$containers" | wc -l | tr -d ' ') -gt 1 ]]; then
    local c
    c=$(echo "$containers" | _kf_fzf --header="Select container") || return
    container_flag="-c $c"
  fi

  kubectl logs -f "$KF_NAME" ${=KF_NS} ${=container_flag} "$@"
}

# kfe — fuzzy exec into pod (bash → sh fallback)
# Usage: kfe [namespace|-A]
kfe() {
  local ns=$(_kf_ns "$1")
  local sel
  sel=$(kubectl get pods ${=ns} --no-headers --show-labels 2>/dev/null \
    | _kf_fzf --header="Exec: select pod  [$ns]") || return
  local KF_NAME KF_NS
  _kf_parse_selection "$sel" "$ns"

  local shell
  shell=$(kubectl exec "$KF_NAME" ${=KF_NS} -- sh -c 'command -v bash 2>/dev/null || echo /bin/sh' 2>/dev/null)
  kubectl exec -it "$KF_NAME" ${=KF_NS} -- "${shell:-/bin/sh}"
}

# kfd — fuzzy describe any resource (pick type interactively if omitted)
# Usage: kfd [namespace|-A] [resource-type]
kfd() {
  local ns_arg="" resource_type=""

  # Route args: detect if first arg is a namespace/flag or resource type
  case "$1" in
    -A) ns_arg="-A"; resource_type="$2" ;;
    po|pod|pods|deploy|deployment|deployments|svc|service|services| \
    cm|configmap|configmaps|secret|secrets|ing|ingress|ingresses| \
    pvc|pvcs|persistentvolumeclaim|persistentvolumeclaims|pv|no|node|nodes| \
    ds|daemonset|daemonsets|rs|replicaset|replicasets| \
    statefulset|statefulsets|sts|job|jobs|cj|cronjob|cronjobs| \
    sa|serviceaccount|serviceaccounts|hpa|crd|crds|ep|endpoints|ns|namespace|namespaces)
      resource_type="$1" ;;
    *) ns_arg="$1"; resource_type="$2" ;;
  esac

  local ns=$(_kf_ns "$ns_arg")

  if [[ -z "$resource_type" ]]; then
    resource_type=$(kubectl api-resources --no-headers --verbs=get 2>/dev/null \
      | awk '{print $1}' \
      | _kf_fzf --header="Describe: select resource type") || return
  fi

  # Fetch with headers: cluster-scoped kinds (nodes, namespaces, pv, ...) have
  # no NAMESPACE column even with -A, so drop -A for them or the wrong column
  # would be taken as the name.
  local out
  out=$(kubectl get "$resource_type" ${=ns} --show-labels 2>/dev/null) || return
  [[ "$ns" == "-A" && "${out%%[[:space:]]*}" != "NAMESPACE" ]] && ns=""
  local sel
  sel=$(printf '%s\n' "$out" | tail -n +2 \
    | _kf_fzf --header="Describe: select $resource_type  [${ns:-cluster}]") || return
  local KF_NAME KF_NS
  _kf_parse_selection "$sel" "$ns"

  kubectl describe "$resource_type" "$KF_NAME" ${=KF_NS}
}

# kfg — fuzzy get across ALL resources (single picker, type/name in first column)
# Usage: kfg [namespace|-A]
kfg() {
  local ns=$(_kf_ns "$1")
  local sel
  sel=$(kubectl get all ${=ns} --no-headers --show-labels 2>/dev/null \
    | _kf_fzf --header="Get: select resource  [$ns]") || return

  # name column is "type/name" e.g. pod/my-pod-xxx or deployment.apps/my-deploy
  # (with -A it is the second column; _kf_parse_selection handles both)
  local KF_NAME KF_NS
  _kf_parse_selection "$sel" "$ns"
  local resource_type="${KF_NAME%%/*}"
  KF_NAME="${KF_NAME##*/}"

  # dont pipe into neat, if you want clean yaml
  # use kn - knp, knd, knsvc
  kubectl get "$resource_type" "$KF_NAME" ${=KF_NS} -o yaml | _kf_save
}

# kfcr — fuzzy kubectl create: pick resource type (kubectl create)
# Usage: kfcr [-dr] [namespace]
kfcr() {
  local dry_run=0
  local -a passargs=()
  for arg in "$@"; do [[ "$arg" == "-dr" ]] && dry_run=1 || passargs+=("$arg"); done
  local ns=$(_kf_ns "${passargs[1]}")
  local -a dry_flags=(); (( dry_run )) && dry_flags=(--dry-run=client -o yaml)

  local resource_type
  resource_type=$(printf '%s\n' \
    namespace serviceaccount \
    configmap \
    "secret/generic" "secret/docker-registry" "secret/tls" \
    deployment \
    "service/clusterip" "service/nodeport" "service/loadbalancer" \
    job cronjob \
    quota \
    | _kf_fzf --header="Create: select resource type") || return

  local name
  echo -n "Name: "; read name
  [[ -z "$name" ]] && { echo "Aborted: name required."; return 1; }

  case "$resource_type" in

    namespace)
      echo "\n$ kubectl create namespace $name ${dry_flags[*]}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      kubectl create namespace "$name" "${dry_flags[@]}"
      ;;

    serviceaccount)
      echo "\n$ kubectl create serviceaccount $name ${dry_flags[*]} ${ns}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      kubectl create serviceaccount "$name" "${dry_flags[@]}" ${=ns}
      ;;

    configmap|secret/generic)
      local ktype="${resource_type/\/generic/}"
      local -a literals=()
      echo "Enter key=value pairs (empty line to finish):"
      while true; do
        local kv; echo -n "  key=value: "; read kv
        [[ -z "$kv" ]] && break
        literals+=(--from-literal="$kv")
      done
      if [[ "$ktype" == "configmap" ]]; then
        echo "\n$ kubectl create configmap $name ${literals[*]} ${dry_flags[*]} ${ns}"
        _kf_confirm "Run?" || { echo "Aborted."; return 1; }
        kubectl create configmap "$name" "${literals[@]}" "${dry_flags[@]}" ${=ns}
      else
        echo "\n$ kubectl create secret generic $name ${literals[*]} ${dry_flags[*]} ${ns}"
        _kf_confirm "Run?" || { echo "Aborted."; return 1; }
        kubectl create secret generic "$name" "${literals[@]}" "${dry_flags[@]}" ${=ns}
      fi
      ;;

    secret/docker-registry)
      local server user pass email
      echo -n "Docker server: ";    read server
      echo -n "Username: ";         read user
      echo -n "Password: ";         read -s pass; echo
      echo -n "Email (optional): "; read email
      local -a extra=(); [[ -n "$email" ]] && extra=(--docker-email="$email")
      echo "\n$ kubectl create secret docker-registry $name --docker-server=... ${dry_flags[*]} ${ns}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      kubectl create secret docker-registry "$name" \
        --docker-server="$server" --docker-username="$user" \
        --docker-password="$pass" "${extra[@]}" "${dry_flags[@]}" ${=ns}
      ;;

    secret/tls)
      local cert key
      echo -n "Cert file: "; read cert
      echo -n "Key file:  "; read key
      echo "\n$ kubectl create secret tls $name --cert=$cert --key=$key ${dry_flags[*]} ${ns}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      kubectl create secret tls "$name" --cert="$cert" --key="$key" "${dry_flags[@]}" ${=ns}
      ;;

    deployment)
      local image replicas
      image=$(_kf_pick_image) || return
      [[ -z "$image" ]] && { echo "Aborted: image required."; return 1; }
      echo -n "Replicas [1]: "; read replicas
      local -a rep_flag=(); [[ -n "$replicas" ]] && rep_flag=(--replicas="$replicas")
      echo "\n$ kubectl create deployment $name --image=$image ${rep_flag[*]} ${dry_flags[*]} ${ns}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      kubectl create deployment "$name" --image="$image" "${rep_flag[@]}" "${dry_flags[@]}" ${=ns}
      ;;

    service/clusterip|service/nodeport|service/loadbalancer)
      local svc_subtype="${resource_type##*/}"
      local port target_port
      echo -n "Port (exposed): ";       read port;        [[ -z "$port" ]] && { echo "Aborted."; return 1; }
      echo -n "Target port [=$port]: "; read target_port; target_port="${target_port:-$port}"
      echo "Selectors (key=value, empty line to finish; default app=$name):"
      local -a sel_pairs=()
      while true; do
        local kv; echo -n "  key=value: "; read kv
        [[ -z "$kv" ]] && break
        sel_pairs+=("$kv")
      done
      local selector="${(j:,:)sel_pairs}"
      if [[ -z "$selector" ]]; then
        echo "\n$ kubectl create service $svc_subtype $name --tcp=$port:$target_port ${dry_flags[*]} ${ns}"
        _kf_confirm "Run?" || { echo "Aborted."; return 1; }
        kubectl create service "$svc_subtype" "$name" --tcp="$port:$target_port" "${dry_flags[@]}" ${=ns}
      else
        # `kubectl create service` has no --selector flag; set it on the
        # dry-run manifest with `kubectl set selector --local` (documented
        # pattern), then create unless -dr.
        echo "\n$ kubectl create service $svc_subtype $name --tcp=$port:$target_port --dry-run=client -o yaml ${ns} \\"
        echo "    | kubectl set selector --local -f - '$selector' -o yaml$( (( dry_run )) || echo " | kubectl create -f - ${ns}" )"
        _kf_confirm "Run?" || { echo "Aborted."; return 1; }
        kubectl create service "$svc_subtype" "$name" --tcp="$port:$target_port" --dry-run=client -o yaml ${=ns} \
          | kubectl set selector --local -f - "$selector" -o yaml \
          | { (( dry_run )) && cat || kubectl create -f - ${=ns}; }
      fi
      ;;

    job)
      local image
      image=$(_kf_pick_image) || return
      [[ -z "$image" ]] && { echo "Aborted: image required."; return 1; }
      echo "\n$ kubectl create job $name --image=$image ${dry_flags[*]} ${ns}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      kubectl create job "$name" --image="$image" "${dry_flags[@]}" ${=ns}
      ;;

    cronjob)
      local image schedule
      image=$(_kf_pick_image) || return
      [[ -z "$image" ]] && { echo "Aborted: image required."; return 1; }
      echo -n "Schedule (e.g. '*/5 * * * *'): "; read schedule
      [[ -z "$schedule" ]] && { echo "Aborted: schedule required."; return 1; }
      echo "\n$ kubectl create cronjob $name --image=$image --schedule='$schedule' ${dry_flags[*]} ${ns}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      kubectl create cronjob "$name" --image="$image" --schedule="$schedule" "${dry_flags[@]}" ${=ns}
      ;;

    quota)
      # Multi-select resource keys, then prompt value for each
      local -a selected_keys
      selected_keys=(${(f)"$(printf '%s\n' \
        'pods' \
        'cpu' 'requests.cpu' 'limits.cpu' \
        'memory' 'requests.memory' 'limits.memory' \
        'services' 'services.loadbalancers' 'services.nodeports' \
        'persistentvolumeclaims' \
        'secrets' 'configmaps' \
        | _kf_fzf --multi --header="Quota: select resources to limit  (TAB to multi-select)")"}) || return
      [[ ${#selected_keys[@]} -eq 0 ]] && { echo "Aborted: select at least one resource."; return 1; }

      local -a hard=()
      local hints=('pods=10' 'cpu=2' 'requests.cpu=1' 'limits.cpu=4' 'memory=4Gi' 'requests.memory=2Gi' 'limits.memory=8Gi' 'services=5' 'services.loadbalancers=2' 'services.nodeports=3' 'persistentvolumeclaims=5' 'secrets=20' 'configmaps=20')
      for key in "${selected_keys[@]}"; do
        local hint=""
        for h in "${hints[@]}"; do [[ "${h%%=*}" == "$key" ]] && hint=" (e.g. ${h##*=})" && break; done
        local val
        echo -n "  $key$hint: "; read val
        [[ -z "$val" ]] && { echo "Aborted: value required for $key."; return 1; }
        hard+=("$key=$val")
      done

      local hard_str="${(j:,:)hard}"
      echo "\n$ kubectl create quota $name --hard=$hard_str ${dry_flags[*]} ${ns}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      kubectl create quota "$name" --hard="$hard_str" "${dry_flags[@]}" ${=ns}
      ;;

  esac
}

# kfrun — fuzzy imperative: kubectl run (pod) or kubectl expose (service)
# Usage: kfrun [-dr] [-it] [namespace]
kfrun() {
  local dry_run=0 it=0
  local -a passargs=()
  for arg in "$@"; do
    case "$arg" in
      -dr) dry_run=1 ;;
      -it) it=1 ;;
      *)   passargs+=("$arg") ;;
    esac
  done
  local ns=$(_kf_ns "${passargs[1]}")
  local -a dry_flags=(); (( dry_run )) && dry_flags=(--dry-run=client -o yaml)

  local resource_type
  resource_type=$(printf 'pod\nservice' \
    | _kf_fzf --header="Imperative: pod (kubectl run) or service (kubectl expose)?") || return

  case "$resource_type" in

    pod)
      local name image port restart labels cmd
      echo -n "Name: ";                      read name;    [[ -z "$name"  ]] && { echo "Aborted."; return 1; }
      image=$(_kf_pick_image) || return
      [[ -z "$image" ]] && { echo "Aborted: image required."; return 1; }
      echo -n "Port (optional): ";           read port
      echo -n "Restart [Always/OnFailure/Never, default Always]: "; read restart; restart="${restart:-Always}"
      echo -n "Labels (k=v,k=v, optional): "; read labels
      echo "Env vars (KEY=val, empty line to finish):"
      local -a env_flags=()
      while true; do
        local ev; echo -n "  KEY=val: "; read ev
        [[ -z "$ev" ]] && break
        env_flags+=(--env="$ev")
      done
      echo -n "Command override (optional, e.g. '/bin/sh -c sleep 3600'): "; read cmd

      local -a extra_flags=()
      [[ -n "$port"    ]] && extra_flags+=(--port="$port")
      [[ -n "$labels"  ]] && extra_flags+=(--labels="$labels")
      [[ "$restart" != "Always" ]] && extra_flags+=(--restart="$restart")

      echo "\n$ kubectl run $name --image=$image ${extra_flags[*]} ${env_flags[*]} ${dry_flags[*]} ${ns}${cmd:+ -- $cmd}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      if [[ -n "$cmd" ]]; then
        kubectl run "$name" --image="$image" "${extra_flags[@]}" "${env_flags[@]}" "${dry_flags[@]}" ${=ns} -- ${=cmd} \
          | { (( dry_run )) && _kf_save || cat; }
      else
        kubectl run "$name" --image="$image" "${extra_flags[@]}" "${env_flags[@]}" "${dry_flags[@]}" ${=ns} \
          | { (( dry_run )) && _kf_save || cat; }
      fi
      if (( it && !dry_run )); then
        echo "Waiting for pod/$name to be ready..."
        kubectl wait pod "$name" ${=ns} --for=condition=Ready --timeout=60s || return
        kubectl exec -it "$name" ${=ns} -- /bin/sh
      fi
      ;;

    service)
      local expose_type expose_name
      expose_type=$(printf 'pod\ndeployment\nreplicaset\nstatefulset\ndaemonset\njob' \
        | _kf_fzf --header="Expose: select resource type") || return
      local expose_sel
      expose_sel=$(kubectl get "$expose_type" ${=ns} --no-headers --show-labels 2>/dev/null \
        | _kf_fzf --header="Expose: select $expose_type  [$ns]") || return
      expose_name=$(echo "$expose_sel" | awk '{print $1}')

      local selector
      if [[ "$expose_type" == "pod" ]]; then
        selector=$(kubectl get pod "$expose_name" ${=ns} -o jsonpath='{.metadata.labels}' 2>/dev/null \
          | jq -r 'to_entries | map("\(.key)=\(.value)") | join(",")' 2>/dev/null)
      else
        selector=$(kubectl get "$expose_type" "$expose_name" ${=ns} -o jsonpath='{.spec.selector.matchLabels}' 2>/dev/null \
          | jq -r 'to_entries | map("\(.key)=\(.value)") | join(",")' 2>/dev/null)
      fi

      local svc_name port target_port svc_type protocol
      echo -n "Service name [$expose_name]: ";            read svc_name;    svc_name="${svc_name:-$expose_name}"
      echo -n "Port (exposed): ";                         read port;        [[ -z "$port" ]] && { echo "Aborted."; return 1; }
      echo -n "Target port [=$port]: ";                   read target_port; target_port="${target_port:-$port}"
      echo -n "Type [ClusterIP/NodePort/LoadBalancer]: ";  read svc_type;   svc_type="${svc_type:-ClusterIP}"
      echo -n "Protocol [TCP]: ";                         read protocol;    protocol="${protocol:-TCP}"
      local -a tp_flag=();       [[ "$target_port" != "$port" ]] && tp_flag=(--target-port="$target_port")
      local -a selector_flag=(); [[ -n "$selector" ]] && selector_flag=(--selector="$selector")
      echo "\n$ kubectl expose $expose_type $expose_name --name=$svc_name --port=$port ${tp_flag[*]} --type=$svc_type --protocol=$protocol ${selector_flag[*]} ${dry_flags[*]} ${ns}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      kubectl expose "$expose_type" "$expose_name" \
        --name="$svc_name" --port="$port" "${tp_flag[@]}" \
        --type="$svc_type" --protocol="$protocol" "${selector_flag[@]}" "${dry_flags[@]}" ${=ns} \
        | { (( dry_run )) && _kf_save || cat; }
      ;;

  esac
}

# kfrm — fuzzy delete any resource with confirmation (multi-select)
# Usage: kfrm [namespace|-A]
kfrm() {
  local ns=$(_kf_ns "$1")
  local sel
  sel=$(kubectl get all ${=ns} --no-headers --show-labels 2>/dev/null \
    | _kf_fzf --multi --header="DELETE: select resource(s)  [tab=multi, $ns]") || return

  local count
  count=$(echo "$sel" | wc -l | tr -d ' ')
  echo "About to delete $count resource(s):"
  # With -A the first column is the namespace; _kf_parse_selection handles both
  local KF_NAME KF_NS line
  echo "$sel" | while IFS= read -r line; do
    _kf_parse_selection "$line" "$ns"
    echo "  $KF_NAME  [${KF_NS#-n }]"
  done
  _kf_confirm "Confirm delete?" || { echo "Aborted."; return 1; }

  echo "$sel" | while IFS= read -r line; do
    _kf_parse_selection "$line" "$ns"
    kubectl delete "${KF_NAME%%/*}" "${KF_NAME##*/}" ${=KF_NS} --wait=false
  done
}

# kfsec — fuzzy pick secret and decode all keys
# Usage: kfsec [namespace|-A]
kfsec() {
  local ns=$(_kf_ns "$1")
  local sel
  sel=$(kubectl get secrets ${=ns} --no-headers --show-labels 2>/dev/null \
    | _kf_fzf --header="Secret: select  [$ns]") || return
  local KF_NAME KF_NS
  _kf_parse_selection "$sel" "$ns"

  echo "\n=== $KF_NAME ======================================"
  kubectl get secret "$KF_NAME" ${=KF_NS} -o json 2>/dev/null \
    | jq -r '.data | to_entries[] | "\(.key): \(.value | @base64d)"' 2>/dev/null \
    || kubectl get secret "$KF_NAME" ${=KF_NS} -o yaml
}

# kfla — fuzzy pick any resource → add or remove a label
# Usage: kfla [namespace|-A]
kfla() {
  local ns=$(_kf_ns "$1")
  local sel
  sel=$(kubectl get all ${=ns} --no-headers --show-labels 2>/dev/null \
    | _kf_fzf --header="Label: select resource  [$ns]") || return

  # name column is "type/name" (second column with -A)
  local KF_NAME KF_NS
  _kf_parse_selection "$sel" "$ns"
  local resource_type="${KF_NAME%%/*}"
  KF_NAME="${KF_NAME##*/}"

  local existing_labels
  existing_labels=$(kubectl get "$resource_type" "$KF_NAME" ${=KF_NS} \
    -o jsonpath='{.metadata.labels}' 2>/dev/null \
    | jq -r 'to_entries[] | "\(.key)=\(.value)"' 2>/dev/null)

  echo "Current labels:"
  echo "${existing_labels:-  (none)}"
  echo

  local action
  action=$(printf 'add/update\nremove' \
    | _kf_fzf --header="Label action") || return

  case "$action" in
    add/update)
      local key value
      echo -n "key: "; read key
      [[ -z "$key" ]] && { echo "Aborted."; return 1; }
      echo -n "value: "; read value
      [[ -z "$value" ]] && { echo "Aborted."; return 1; }
      echo "\n$ kubectl label $resource_type $KF_NAME $key=$value --overwrite ${KF_NS}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      kubectl label "$resource_type" "$KF_NAME" ${=KF_NS} "$key=$value" --overwrite
      ;;
    remove)
      local key
      key=$(echo "$existing_labels" | awk -F= '{print $1}' \
        | _kf_fzf --header="Remove label: select key") || return
      echo "\n$ kubectl label $resource_type $KF_NAME ${key}- ${KF_NS}"
      _kf_confirm "Run?" || { echo "Aborted."; return 1; }
      kubectl label "$resource_type" "$KF_NAME" ${=KF_NS} "${key}-"
      ;;
  esac
}

# kfcm — fuzzy pick configmap and view
# Usage: kfcm [namespace|-A]
kfcm() {
  local ns=$(_kf_ns "$1")
  local sel
  sel=$(kubectl get configmaps ${=ns} --no-headers --show-labels 2>/dev/null \
    | _kf_fzf --header="ConfigMap: select  [$ns]") || return
  local KF_NAME KF_NS
  _kf_parse_selection "$sel" "$ns"

  kubectl get configmap "$KF_NAME" ${=KF_NS} -o yaml
}

# kfcan — fuzzy kubectl auth can-i: pick verb then resource
# Usage: kfcan [namespace|-A]
# Optionally impersonate a user/serviceaccount with --as
kfcan() {
  local ns=$(_kf_ns "$1")

  local verb
  verb=$(printf '%s\n' \
    get list watch \
    create update patch delete deletecollection \
    exec attach port-forward \
    impersonate bind escalate \
    '*' \
    | _kf_fzf --header="can-i: select verb") || return

  # Discovery only advertises the standard verbs, so filtering api-resources
  # by an RBAC-only verb (impersonate, bind, escalate, *) yields nothing;
  # exec/attach/port-forward are not verbs at all but `create` on a pod
  # subresource, which `auth can-i` takes via --subresource.
  local resource
  local -a res_args=() extra=() sub_flag=()
  case "$verb" in
    exec|attach|port-forward)
      sub_flag=(--subresource="${verb//-/}")
      verb=create
      resource=pods
      ;;
    get|list|watch|create|update|patch|delete|deletecollection)
      res_args=(--verbs="$verb")
      ;;
    impersonate) extra=(users groups serviceaccounts uids userextras) ;;
    bind|escalate) extra=(roles clusterroles) ;;
    '*') extra=('*') ;;
  esac
  if [[ -z "$resource" ]]; then
    resource=$( { (( ${#extra[@]} )) && printf '%s\n' "${extra[@]}"; \
        kubectl api-resources --no-headers "${res_args[@]}" 2>/dev/null \
        | awk '{print $1}'; } \
      | _kf_fzf --header="can-i: select resource  [verb=$verb]") || return
  fi

  local as_flag=""
  local as_who
  echo -n "Impersonate (--as) [empty to use current user]: "; read as_who
  [[ -n "$as_who" ]] && as_flag="--as=$as_who"

  echo "\n$ kubectl auth can-i $verb $resource ${sub_flag[*]} ${as_flag} ${ns}"
  kubectl auth can-i "$verb" "$resource" "${sub_flag[@]}" ${=as_flag} ${=ns}
}
