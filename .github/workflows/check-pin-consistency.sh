#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Fails when this template's release pin is internally inconsistent: the
# targetRevision lines under bootstrap/applications/ disagree with each
# other, or the README's "Pinned to" line disagrees with them.
#
# This is the LOCAL half of the re-pin DoD tockmox-release (the private
# skill) and RELEASING.md's "tockmox-site-template re-pin" gate already
# state by hand: "9 lines on vX.Y.Z, 10 on main" (or however many layers
# exist at the time), README's "Pinned to" line matching. TM-0675 found the
# drift this script watches for by running that check for the first time,
# three hours before the 0.6.0 tag. It should not take a human noticing.
#
# NOT IMPLEMENTED HERE: comparing this pin against tockmox/tockmox's latest
# release tag on GitHub, to catch a pin that lags by more than one release.
# tockmox/tockmox is currently a PRIVATE repository (RELEASING.md notes the
# release badge itself cannot render while it is private), so an
# unauthenticated call to the releases API returns 404 rather than a real
# "latest" answer, and there is no way to ask "how far behind is this pin"
# without a token. A token embedded in a PUBLIC template's workflow is a
# credential this repository has nowhere safe to hold, so that check is
# left out rather than built on a token. Revisit once tockmox/tockmox goes
# public (ADR-0045): `gh release view --repo tockmox/tockmox --json tagName`
# needs no auth at that point.
#
# PORTABILITY: written to run identically on macOS's /bin/bash (3.2.57) and
# the Linux Actions runner, per the same reasoning tockmox/tockmox's
# check-docs-style.sh states for itself: no arrays, no mapfile, no bare
# "$@" under `set -u`.
#
# Usage:
#   check-pin-consistency.sh              check this repository
#   check-pin-consistency.sh --selftest   prove the checks actually refuse

set -eu

APPS_DIR="bootstrap/applications"

# check_pins DIR -> prints findings; returns 0 clean, 1 refused
check_pins() {
  cp_dir="$1"
  cp_apps="$cp_dir/$APPS_DIR"
  [ -d "$cp_apps" ] || { echo "no $cp_apps directory"; return 1; }

  # -o extracts just "targetRevision: <value>" regardless of what precedes it
  # on the line (a YAML list dash, indentation, or both), so this does not
  # depend on how the surrounding file happens to be indented.
  cp_pins=$(grep -ohE 'targetRevision:[[:space:]]*[^[:space:]]+' "$cp_apps"/*.yaml 2>/dev/null \
              | sed 's/targetRevision:[[:space:]]*/targetRevision: /' \
              | grep -v '^targetRevision: main$' \
              | sort -u)
  cp_n=$(printf '%s\n' "$cp_pins" | grep -c '^targetRevision:' || true)

  if [ "$cp_n" -eq 0 ]; then
    echo "no non-main targetRevision found under $cp_apps"
    return 1
  fi
  if [ "$cp_n" -gt 1 ]; then
    echo "targetRevision values disagree across $cp_apps:"
    printf '%s\n' "$cp_pins" | sed 's/^/    /'
    return 1
  fi

  cp_pin=$(printf '%s\n' "$cp_pins" | sed 's/^targetRevision:[[:space:]]*//')
  echo "all layer pins agree: $cp_pin"

  cp_readme="$cp_dir/README.md"
  [ -f "$cp_readme" ] || { echo "no README.md"; return 1; }
  if ! grep -q "Pinned to \*\*${cp_pin}\*\*" "$cp_readme"; then
    echo "README.md does not say 'Pinned to **${cp_pin}**':"
    grep -n 'Pinned to' "$cp_readme" | sed 's/^/    /' \
      || echo "    (no 'Pinned to' line at all)"
    return 1
  fi
  echo "README.md agrees: Pinned to **${cp_pin}**"
  return 0
}

# ==========================================================================
# selftest: fixtures only, never this repository's own tree
# ==========================================================================
selftest() {
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  fails=0

  mk() { # mk DIR PIN_A PIN_B README_PIN
    mk_d="$1"; mkdir -p "$mk_d/bootstrap/applications"
    printf 'spec:\n  sources:\n  - targetRevision: %s\n  - targetRevision: main\n' "$2" \
      > "$mk_d/bootstrap/applications/layer-a.yaml"
    printf 'spec:\n  sources:\n  - targetRevision: %s\n  - targetRevision: main\n' "$3" \
      > "$mk_d/bootstrap/applications/layer-b.yaml"
    printf 'source:\n  targetRevision: main\n' > "$mk_d/bootstrap/applications/site-apps.yaml"
    printf '# Site\n\nPinned to **%s**.\n' "$4" > "$mk_d/README.md"
  }

  probe() { # probe LABEL want-pass|want-fail DIR
    p_label="$1"; p_want="$2"; p_dir="$3"
    if check_pins "$p_dir" >/tmp/pin-selftest-out 2>&1; then p_got=want-pass; else p_got=want-fail; fi
    if [ "$p_got" = "$p_want" ]; then
      echo "  ok  $p_label: $p_got as expected"
    else
      echo "  SELFTEST FAIL: '$p_label' wanted $p_want, got $p_got:"
      sed 's/^/            /' /tmp/pin-selftest-out
      fails=1
    fi
  }

  echo "selftest: pin-consistency"

  d="$tmp/good"; mk "$d" "v1.2.3" "v1.2.3" "v1.2.3"
  probe "a consistent tree" want-pass "$d"

  d="$tmp/split"; mk "$d" "v1.2.3" "v1.2.2" "v1.2.3"
  probe "a split targetRevision across layer files" want-fail "$d"

  d="$tmp/readme"; mk "$d" "v1.2.3" "v1.2.3" "v1.2.2"
  probe "a README pin disagreeing with the layers" want-fail "$d"

  d="$tmp/noreadme"; mk "$d" "v1.2.3" "v1.2.3" "v1.2.3"; rm "$d/README.md"
  probe "no README.md at all" want-fail "$d"

  d="$tmp/none"; mkdir -p "$d/bootstrap/applications"
  printf 'source:\n  targetRevision: main\n' > "$d/bootstrap/applications/site-apps.yaml"
  printf '# Site\n' > "$d/README.md"
  probe "no non-main pin anywhere (nothing to check)" want-fail "$d"

  if [ "$fails" -eq 0 ]; then
    echo "check-pin-consistency --selftest: PASSED"
    exit 0
  fi
  echo "check-pin-consistency --selftest: FAILED"
  exit 1
}

case "${1:-}" in
  --selftest) selftest ;;
esac

check_pins "."
