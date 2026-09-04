# Tockmox site repository

Your deployment, and only your deployment. This repository contains **no copy
of Tockmox** ... only what is yours: values, secrets, and your own
applications. Upgrading Tockmox means changing `targetRevision` and syncing.
Nothing here is touched by an upgrade.

Pinned to **v0.6.0-rc1**.

## Prerequisites

A conformant Kubernetes cluster with a CNI and a default StorageClass, ArgoCD
2.6 or newer, and sealed-secrets with your own key. Nothing else: cert-manager,
MetalLB, Longhorn and Traefik are installed by Tockmox as wave-2 charts.

Full detail: `docs/deployment/prerequisites.md` in the Tockmox repository.

## Quick start

**1.** Click **Use this template**, choose *Create a new repository*, then clone
your copy. Forking also works, but a fork keeps this repository's history and
stays linked to it as a fork; a template gives a clean first commit that is
yours.

**2.** Set the two required values in `site/values/global.yaml`:
`global.internalDomain` and `global.lanCIDR`. Neither has a default, because a
wrong guess at either fails in a way that does not name the setting.

**3.** Set `addressPool.range` in `site/values/platform.yaml` to a range inside
your `lanCIDR` that DHCP does not hand out. The platform layer refuses to
render without it.

**4.** Replace the two placeholders everywhere they appear. `perl -pi` rather
than `sed -i` because the two disagree about in-place editing across macOS and
Linux:

```bash
grep -rl PLACEHOLDER_SITE_REPO_URL . \
  | xargs perl -pi -e 's|PLACEHOLDER_SITE_REPO_URL|https://github.com/you/your-site|g'

grep -rl int.example.com . \
  | xargs perl -pi -e 's|int\.example\.com|int.yourdomain|g'
```

**5.** Commit and push. ArgoCD reads your values over git, so this repository
must be reachable from the cluster.

**6.** Apply the parent, and only the parent:

```bash
kubectl apply -f bootstrap/root.yaml
kubectl -n argocd get applications -w
```

Applying `bootstrap/applications/*.yaml` directly with `kubectl` also works,
and their `sync-wave` annotations then do nothing at all: ArgoCD orders
resources **within** an Application. The parent is not decoration.

## Layout

```
site/values/global.yaml     settings every layer reads
site/values/<layer>.yaml    per-layer overrides
apps/                       your own workloads
secrets/                    your SealedSecrets
bootstrap/root.yaml         the only thing you apply by hand
bootstrap/applications/     one Application per layer, sync-wave ordered
```

## Sync waves

| Wave | Layer |
|---|---|
| 0 | `tockmox-crds` |
| 1 | `tockmox-policy` |
| 2 | `tockmox-platform` |
| 3 | `tockmox-observability`, `tockmox-exporters` |
| 4 | `tockmox-identity` |
| 5 | `tockmox-devops`, `tockmox-ai`, `tockmox-selfcheck` |
| 6 | `site-apps` (everything in `apps/`) |

## Rules worth knowing

- The `tockmox-` namespace prefix is reserved. Do not use it for your own
  workloads.
- Editing resources with `kubectl` will not stick while `selfHeal` is on.
  Change this repository instead.
- A layer Application's destination namespace must match what the policy
  layer's NetworkPolicies guard. Override both together or neither.
- Real secrets never live here as plaintext. SealedSecrets are encrypted to
  your cluster's key and are safe to commit; nothing else is.

## Generating this instead

`install/tockmox-install.sh` in the Tockmox repository produces this same
layout from a config file, with your answers already filled in and validated
against a live cluster:

```bash
./install/tockmox-install.sh --config tockmox.yaml --dry-run
```

Use whichever you prefer. The output is the same shape, down to the
`repoURL` string: both write `https://github.com/tockmox/tockmox.git`, with
the suffix. ArgoCD would not have cared either way (`util/git.NormalizeGitURL`
strips `.git`, lowercases and trims before every repository, credential
template and project `sourceRepos` match, at 2.6 and still at 3.5), but two
generators emitting two strings for one repository is a diff an evaluator has
to explain, so the template carries the installer's form.

## Moving to a newer Tockmox

Change `targetRevision` in `bootstrap/applications/*.yaml` and sync. Read the
release notes first: a values key that moved is called out there by name.

## Why this repository has no tags of its own

Each Tockmox release re-pins this template by hand (nine `targetRevision`
lines and the "Pinned to" line above), and that pin is the whole record of
which release a template state matches. No tag is cut here until the Tockmox
repository is public (ADR-0045, at LLC formation), for three reasons:

- A tag is a second thing to remember at release time, and a forgotten one
  is a new way for this repository and the release to disagree ... the exact
  failure the re-pin step exists to prevent.
- Until publication nobody but the maintainer needs an older scaffold, so a
  tag has no reader yet.
- Publication of the Tockmox repository is a one-time history cut (an orphan
  commit at first public release). Every pin this template has carried so
  far names a pre-cut Tockmox tag, so a template tag made now would freeze
  a `targetRevision` that no public checkout can resolve.

At publication the question is reopened once, with the release skill deciding
whether a template tag becomes a release step.

---

<sub>Apache-2.0. Tockmox is a trademark.</sub>
