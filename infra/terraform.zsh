export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p "$HOME/.terraform.d/plugin-cache"

function tfaa(){
    terraform apply -auto-approve $*
}

function tfout(){
    terraform output $*
}

function tfshow(){
    terraform show $*
}

# for share images project
function remake(){
    tfd -auto-approve && tfa -auto-approve
}
