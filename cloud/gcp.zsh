# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/gateswang/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/gateswang/google-cloud-sdk/path.zsh.inc'; fi
# The next line enables shell command completion for gcloud.
if [ -f '/Users/gateswang/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/gateswang/google-cloud-sdk/completion.zsh.inc'; fi

# export PROJECT_ID=$(gcloud config list --format='value(core.project)')
# export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
# gcloud config set project $PROJECT_ID

# export TF_VAR_project=$PROJECT_ID
