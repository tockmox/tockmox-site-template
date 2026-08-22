# Your secrets

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
