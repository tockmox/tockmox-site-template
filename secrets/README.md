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
kubeseal --format yaml \
    --controller-name sealed-secrets \
    --controller-namespace kube-system \
  < my-secret.plain.yaml > my-secret.yaml
```

**Do not drop the two `--controller-*` flags.** They name the sealed-secrets
Service a Tockmox install actually creates. `kubeseal`'s own default
(`sealed-secrets-controller`) does not match it, and **without them the `>`
redirect leaves a zero-byte file that looks minted** ... no error, a file on
disk, and nothing in it. Commit that and ArgoCD applies it happily, no Secret
appears, and the symptom is `CreateContainerConfigError` on Authentik, Grafana,
LiteLLM and ntfy, which reads as a broken chart rather than an unsealed secret.

Check the output before committing it. A sealed secret is only sealed if it has
an `encryptedData` block:

```bash
grep -q 'encryptedData' my-secret.yaml && echo sealed || echo "NOT SEALED"
```

`secrets/*.plain.yaml` is gitignored so the unsealed input does not follow the
output into a commit.

Back up the sealed-secrets controller's private key somewhere that is not the
cluster it came from. Losing it makes every sealed secret in this repository
permanently unreadable.

Which secrets each layer expects, and how they are consumed:
`docs/administration/secrets.md` in the Tockmox repository.
