#!/usr/bin/env bash
# Fail if a URL that SKILL.md or README.md depends on stops resolving.
# The skill reads these sources at run time, so a moved page breaks it silently.
set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
files=(
  "$root/plugins/terragrunt-upgrade-impact/skills/terragrunt-upgrade-impact/SKILL.md"
  "$root/README.md"
)

urls=$(grep -ohE 'https://[A-Za-z0-9./_#?=&%~+-]+' "${files[@]}" | sed -E 's/[.,)]+$//' | sort -u)
fail=0
for u in $urls; do
  code=$(curl -s -o /dev/null -L -w '%{http_code}' --max-time 30 --retry 2 "$u")
  if [ "$code" = "200" ]; then
    echo "ok    $u"
  else
    echo "FAIL  $code  $u"
    fail=1
  fi
done
exit $fail
