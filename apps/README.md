# Your applications

Everything in this directory syncs to the cluster via the `site-apps`
Application in `../bootstrap/applications/site-apps.yaml`, ordered after every
Tockmox layer. Plain manifests and Argo Application CRs both work; manifests
should carry their own `namespace:`.

The `tockmox-` namespace prefix is reserved. Do not use it here.

The full wiring guide for a new app ... namespace, NetworkPolicy, database,
backups, ingress, SSO, metrics ... is
`docs/administration/adding-an-application.md` in the Tockmox repository.
