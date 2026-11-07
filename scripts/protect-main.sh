#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Configure the required status checks on main. Requires GitHub Pro (or a public
# repository): GitHub returns 403 for branch protection on a private repository
# on the free plan.
set -euo pipefail
repo="${1:-xenoglossy-asyncio/hoa-core}"
json="$(mktemp)"
cat > "$json" <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "docs-check",
      "i18n-check",
      "content-check",
      "addon-lua",
      "launcher-build",
      "client-check",
      "server-build"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
trap 'rm -f "$json"' EXIT
gh api -X PUT "repos/$repo/branches/main/protection" --input "$json"
