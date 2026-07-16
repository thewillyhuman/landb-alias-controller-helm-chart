The **LANDB Alias Controller Helm Chart** deploys the
[LANDB Alias Controller](https://gitlab.cern.ch/kubernetes/networking/landb-controller/landb-alias-controller)
on Kubernetes. This controller watches Ingress resources and automatically
synchronizes DNS aliases to OpenStack server metadata, enabling CERN's LANDB
system to create corresponding DNS records without manual configuration.

[[_TOC_]]

## Quick Start

### Using the cluster's cloud-config (default)

On Magnum-created clusters, a `cloud-config` secret with OpenStack credentials
already exists in `kube-system`. The controller uses it by default — no
credential configuration needed:

```bash
helm install landb-alias-controller oci://registry.cern.ch/kubernetes/charts/landb-alias-controller \
  --version 0.0.8 \
  --namespace kube-system
```

### Using explicit credentials

To use explicit credentials instead of cloud-config, disable `cloudConfig` and
provide credentials via `secretEnv`:

```bash
helm install landb-alias-controller oci://registry.cern.ch/kubernetes/charts/landb-alias-controller \
  --version 0.0.8 \
  --namespace kube-system \
  --set cloudConfig.enabled=false \
  --set secretEnv.OS_AUTH_URL="$OS_AUTH_URL" \
  --set secretEnv.OS_USERNAME="$OS_USERNAME" \
  --set secretEnv.OS_PASSWORD="$OS_PASSWORD" \
  --set secretEnv.OS_PROJECT_NAME="$OS_PROJECT_NAME" \
  --set secretEnv.OS_USER_DOMAIN_NAME="$OS_USER_DOMAIN_NAME"
```

## Configuration

### Authentication

The controller requires OpenStack credentials to synchronize aliases. Three
options are available:

#### Option 1: Cloud-Config Secret (default)

By default, the controller reads credentials from the `cloud-config` secret
that Magnum creates in `kube-system`. This uses trust-based authentication and
requires no manual credential setup.

The chart automatically creates a Role and RoleBinding in `kube-system`
granting the controller's service account permission to read the secret. The
namespace and secret name are configurable:

```yaml
cloudConfig:
  enabled: true             # default
  namespace: kube-system    # default
  name: cloud-config        # default
```

To disable cloud-config authentication and use environment variables instead,
set `cloudConfig.enabled: false`.

#### Option 2: Inline Secret

Provide credentials directly via `secretEnv` (the chart creates a Secret for you):

```yaml
secretEnv:
  OS_AUTH_URL: "https://keystone.cern.ch/v3"
  OS_USERNAME: "svc-landb-ctrl"
  OS_PASSWORD: "changeme"
  OS_PROJECT_NAME: "my-project"
  OS_USER_DOMAIN_NAME: "Default"
```

#### Option 3: External Secret Reference

Reference a pre-existing Secret with `envFromSecret`:

```yaml
envFromSecret: "my-openstack-credentials"
```

Options 2 and 3 can be used together — all secrets are mounted via `envFrom`.

### Controller Flags

The controller binary accepts command-line flags configured via `args` in `values.yaml`:

| Flag | Default | Description |
|------|---------|-------------|
| `--provider` | `openstack` | DNS provider to use |
| `--ingress-node-labels` | `node-role.kubernetes.io/ingress,role=ingress` | Comma-separated label selectors identifying ingress nodes (OR). Use `key` for presence or `key=value` for exact match |
| `--cloud-config-secret` | | Read credentials from a K8s secret (`namespace/name`) |
| `--zap-log-level` | `info` | Log level: `debug`, `info`, `error` |
| `--zap-devel` | `false` | Enable development-mode logging |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod scheduling |
| args | list | `["--provider=openstack","--ingress-node-labels=node-role.kubernetes.io/ingress,role=ingress","--zap-log-level=info"]` | Container arguments passed to the controller binary. The controller accepts the following flags:   --provider              - DNS provider to use (default "openstack")   --ingress-node-labels   - Comma-separated labels identifying ingress nodes (OR logic)                             (default "node-role.kubernetes.io/ingress,role")   --cloud-config-secret   - Read OpenStack credentials from a K8s secret (format: namespace/name)   --zap-log-level         - Log level: debug, info, error (default "info")   --zap-devel             - Enable development-mode logging (default false) |
| cloudConfig.enabled | bool | `true` | Read OpenStack credentials from the cloud-config secret in kube-system. When enabled, secretEnv/envFromSecret for OS_* variables are not required. |
| cloudConfig.name | string | `"cloud-config"` | Name of the cloud-config secret |
| cloudConfig.namespace | string | `"kube-system"` | Namespace of the cloud-config secret |
| env | object | `{}` | Environment variables passed to the container. Use this for non-sensitive configuration. OpenStack credentials should go in secretEnv or envFromSecret. |
| envFromSecret | string | `""` | Reference to an existing Secret for sensitive environment variables. Can be used alongside secretEnv — both will be mounted via envFrom. |
| extraVolumeMounts | list | `[]` | Additional volume mounts to add to the container |
| extraVolumes | list | `[]` | Additional volumes to add to the pod |
| fullnameOverride | string | `""` | Override the full resource name prefix |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"registry.cern.ch/kubernetes/landb-alias-controller"` | Container image repository |
| image.tag | string | `"v0.0.7"` | Overrides the image tag whose default is the chart appVersion |
| imagePullSecrets | list | `[]` | Secrets for pulling images from private registries |
| nameOverride | string | `""` | Override the default chart name used in resource names |
| nodeSelector | object | `{"kubernetes.io/os":"linux"}` | Node selector for pod scheduling |
| podAnnotations | object | `{}` | Annotations to add to the controller pod |
| podMonitor.enabled | bool | `false` | Enable Prometheus PodMonitor for scraping /metrics |
| podMonitor.interval | string | `""` | Scrape interval (e.g. "30s"). Uses Prometheus default if empty |
| podMonitor.labels | object | `{}` | Additional labels for the PodMonitor (e.g. for Prometheus selector matching) |
| podMonitor.scrapeTimeout | string | `""` | Scrape timeout (e.g. "10s"). Uses Prometheus default if empty |
| podSecurityContext | object | `{}` | Pod-level security context |
| rbac.create | bool | `true` | Whether to create ClusterRole and ClusterRoleBinding for the controller |
| replicaCount | int | `1` | Number of pod replicas |
| resources.limits.memory | string | `"64Mi"` | Memory limit |
| resources.requests.cpu | string | `"10m"` | CPU request |
| resources.requests.memory | string | `"64Mi"` | Memory request |
| secretEnv | object | `{}` | Sensitive environment variables. The chart creates a Secret automatically and mounts it via envFrom. Use this for OpenStack credentials: |
| securityContext | object | `{"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"runAsUser":65534}` | Container-level security context |
| serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount |
| serviceAccount.create | bool | `true` | Whether to create a ServiceAccount |
| serviceAccount.name | string | `""` | Name of the ServiceAccount. If not set, a name is generated from the fullname template |
| tolerations | list | `[]` | Tolerations for pod scheduling |

## Contributing

We welcome contributions! If you're interested in helping improve this project, please review our [contribution guidelines](CONTRIBUTING.md). In brief:

1. **Fork** the repository.
2. Create a **feature branch**.
3. Implement, provide tests and validate your changes.
4. Submit a **Merge Request (MR)** to the `master` branch.

For a full contribution workflow, visit the [contribution guide](CONTRIBUTING.md).

## Release Procedure

This chart honours [semantic versioning](https://semver.org/). Follow this manual procedure to create a new release:

### Bump the chart version

- Open the `Chart.yaml` file in the root of the repository.
- Update the `version`: field to the new release version (this must match the tag you will create — without any `v` prefix).

  Example:

  ```yaml
  apiVersion: v2
  name: landb-alias-controller
  version: 1.2.3  # <--- Bump this version
  ```

- Commit the change:

  ```bash
  git add Chart.yaml
  git commit -m "Bump chart version to 1.2.3"

  # Push to master, or create a merge request from your release branch:
  git push origin master
  ```

### Create and push the tag

- Create an **annotated tag** matching the chart version (do not prefix with `v`):

  ```bash
  git tag -a 1.2.3 -m "1.2.3

  - Change description.
  - Change description."
  git push origin 1.2.3
  ```

## License

This repository is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0). See the [LICENSE](LICENSE) file for more information.
