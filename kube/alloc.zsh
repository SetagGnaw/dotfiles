# view-allocations - show CPU/memory requests & limits across nodes/namespaces
# install: kubectl krew install view-allocations
#
# examples:
#   kva                        # all namespaces, all resources
#   kva -r cpu                 # CPU only
#   kva -r memory              # memory only
#   kva -n default             # specific namespace
#   kva -g node                # group by node
#   kva -g namespace           # group by namespace
function kva() { kubectl view-allocations "$@"; }
