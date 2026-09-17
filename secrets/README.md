# Your secrets

**`bootstrap/applications/site-secrets.yaml` syncs this directory**, at
sync-wave 1, ahead of every layer that consumes a secret. Commit a sealed
secret here and ArgoCD applies and reconciles it like anything else in the
repository.

> **Fixed in v0.6.1.** Through v0.6.0 this template carried no such
> Application, so a site cloned from here committed its sealed secrets and
> never applied them, with `CreateContainerConfigError` on Authentik, Grafana,
> LiteLLM and ntfy as the only symptom. If you built a site from the v0.6.0
> template, copy `bootstrap/applications/site-secrets.yaml` into it, replace
> `PLACEHOLDER_SITE_REPO_URL` with your repository URL to match the other
> Applications, and commit.

SealedSecrets only. They are encrypted to **your** cluster's key, which is what
makes them safe to commit ... nobody else can decrypt them, including the
Tockmox project.

```bash
kubeseal --format yaml < my-secret.plain.yaml > my-secret.yaml
```

`secrets/*.plain.yaml` is gitignored so the unsealed input does not follow the
output into a commit.

Back up the sealed-secrets controller's private key somewhere that is not the
cluster it came from. Losing it makes every sealed secret in this repository
permanently unreadable.

Which secrets each layer expects, and how they are consumed:
`docs/administration/secrets.md` in the Tockmox repository.
