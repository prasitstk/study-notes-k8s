### Set up

Convert your kubeconfig to base64: `cat kubeconfig | base64`

Copy Kubeconfig (base64 format) to Gitpod variable `K8S_CTX` in `*/*` scope.

DigitalOcean console > API > Tokens/Keys > Generate new token
- Token name: <Token-name>
- Expiry: 90 days
- Select scopes: Read & Write
- Token: <Generated-token>

Copy the  <Generated-token> to Gitpod variable `DO_TOKEN` in `*/*` scope.

---

### References
- [Gitpod : How to use kubectl and manage Kubernetes clusters ?](https://dev.to/stack-labs/gitpod-how-to-use-kubectl-and-manage-kubernetes-clusters--4edp)
- [Kubectl packaged by Bitnami](https://hub.docker.com/r/bitnami/kubectl)
- [How to Install and Configure doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/)
- [quadeare/gitpod-kubectl](https://github.com/quadeare/gitpod-kubectl)

---
