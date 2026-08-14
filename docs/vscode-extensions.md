# VSCode Extensions — Bloat Audit

Currently ~60 extensions installed. Many spawn their own language server or
extension host (100–600 MB each). Disable per-workspace with:

- Extensions view → filter `@enabled` → right-click → **Disable (Workspace)**
- Inspect live process cost: `Cmd+Shift+P` → **Developer: Open Process Explorer**

## Heavy language servers (200–600 MB each)

| Extension | When to keep | Notes |
|---|---|---|
| `ms-vscode.cpptools` (+ extension-pack, devtools, themes) | C/C++ workspaces only | IntelliSense is huge |
| `ms-python.vscode-pylance` | Python workspaces | Very heavy; disable elsewhere |
| `golang.go` | Go repos | Spawns `gopls` |
| `dart-code.dart-code` + `dart-code.flutter` | Flutter/Dart work | Dart analysis server |
| `juanblanco.solidity`, `tintinweb.vscode-vyper` | Smart-contract work | LSPs |
| `hashicorp.terraform` + `hashicorp.hcl` | IaC repos | Terraform LSP |
| `redhat.vscode-yaml`, `redhat.vscode-xml` | YAML/XML-heavy work | Java-backed (XML esp.) |

## Duplicate / overlapping AI

- `anthropic.claude-code` **and** `google.geminicodeassist` — pick one.

## Heavy DB / cloud tools

| Extension | When to keep |
|---|---|
| `cweijan.dbclient-jdbc` | Active DB querying (JVM-based, big) |
| `mongodb.mongodb-vscode` | MongoDB work |
| `cweijan.vscode-redis-client` | Redis work |
| `googlecloudtools.cloudcode` | GCP work |
| `docker.docker` | Container work |
| `ms-kubernetes-tools.vscode-kubernetes-tools` | K8s work |

## Jupyter stack (disable if using ipython in terminal, not notebooks)

- `ms-toolsai.jupyter`
- `ms-toolsai.jupyter-renderers`
- `ms-toolsai.vscode-jupyter-cell-tags`
- `ms-toolsai.vscode-jupyter-slideshow`
- `ms-toolsai.jupyter-keymap`

## Biggest wins

1. Disable the **cpptools family** outside C++ projects.
2. Keep only one AI assistant (Claude **or** Gemini).
3. Disable **dart/flutter** unless actively using them.
4. Disable the **JDBC DB client** when not querying DBs.
5. Close extra VSCode windows — each renderer is 300–500 MB.

## Consolidating extension hosts

Some extensions can share an extension host via `settings.json`:

```json
"extensions.experimental.affinity": {
  "ms-python.python": 1,
  "ms-python.vscode-pylance": 1
}
```

Reduces per-extension-host overhead when several extensions are always used together.
