# Hugging Face helpers (uses the new `hf` CLI; the old `huggingface-cli` is deprecated).
#
# Get a token at https://huggingface.co/settings/tokens, then store it in
# ~/.huggingface_token (NOT in this repo). Example:
#   echo 'hf_xxxxxxxxxxxxxxxxxxxx' > ~/.huggingface_token
#   chmod 600 ~/.huggingface_token
#
# Both HF_TOKEN (new) and HUGGING_FACE_HUB_TOKEN (legacy) are exported so the
# huggingface_hub / transformers / datasets libraries pick it up automatically.
if [[ -r "$HOME/.huggingface_token" ]]; then
  export HF_TOKEN="$(<$HOME/.huggingface_token)"
  export HUGGING_FACE_HUB_TOKEN="$HF_TOKEN"
fi

# Interactive login — writes the token to ~/.cache/huggingface/token.
hflogin() { hf auth login "$@"; }

# Show the currently authenticated HF user.
hfwhoami() { hf auth whoami "$@"; }

# Log out and remove the cached token.
hflogout() { hf auth logout "$@"; }

# Download a repo (model or dataset) into the local HF cache.
# Usage: hfdownload <repo_id> [filename ...]
hfdownload() { hf download "$@"; }

# Upload files to a repo.
# Usage: hfupload <repo_id> <local_path> [path_in_repo]
hfupload() { hf upload "$@"; }

# Search models, e.g. hfsearch "gemma"
hfsearch() { hf models ls --search "$@"; }

# Open the HF tokens page to create or rotate a token.
hftoken() { open "https://huggingface.co/settings/tokens"; }
