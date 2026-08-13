# Tockmox site repo

Your deployment. Private. Contains **no copy of Tockmox** ... only what is
yours: values, secrets, and your own apps.

1. Edit `site/values/global.yaml`.
2. Pin the Tockmox revision in `bootstrap/root-applications.yaml`.
3. Apply it.

Upgrading Tockmox is changing `targetRevision` and syncing. Nothing here is
touched by an upgrade.
