# Build a Local K8s Cluster with Multipass

This directory contains scripts that leverage [Multipass](https://canonical.com/multipass) and Ansible to bootstrap an Ubuntu Jammy VM cluster on a laptop or workstation, making it easy to try MicroK8s or any other Kubernetes-based workloads locally.

## Components

- `build_cluster.sh`: launches the desired number of `kvmXX` Multipass instances, injects your SSH public key, and triggers `install_vm.yaml`.
- `install_vm.yaml`: upgrades packages, optionally swaps APT mirrors, patches `/etc/hosts`, and distributes SSH keys across all VMs.
- `sources.list.*`: architecture-specific APT source templates that can speed up package downloads in restricted networks.

## Prerequisites

1. Multipass 1.12+ with access to the `jammy` image.
2. An SSH key at `~/.ssh/id_rsa.pub` (generate with `ssh-keygen -t rsa -b 4096` if missing).
3. Ansible 2.13+ and permission to write files in this repository.

> Note: The scripts target macOS and Linux. Windows is not supported.

## Quick Start

1. **Prepare an SSH key**
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
   ```
2. **Run the cluster script**
   ```bash
   cd <repo-root>
   ./multipass/build_cluster.sh <node-count> <replace-apt-source>
   ```
   - `node-count`: number of VMs. For example, `3` creates `kvm00`, `kvm01`, `kvm02`.
   - `replace-apt-source`: `true/false`. When `true`, the script copies the matching `sources.list.*` file into each VM.
3. **Wait for automation to finish**
   - The script creates the `inventory` file for Ansible and writes IP details to `multipass/hosts`.
   - After the playbook completes, each VM restarts so the updated hosts file takes effect.
4. **Access a VM**
   ```bash
   multipass shell kvm00
   ```
   SSH trust is in place between VMs, so you can hop from one VM to another with `ssh ubuntu@kvm01`.

## Customize APT Sources

- ARM64/aarch64 uses `sources.list.aarch64`; x86_64 uses `sources.list.amd64`.
- Update the template file with your preferred mirror, then rerun `build_cluster.sh ... true`.
- To keep existing VMs without replacing the mirror, pass `false` as the second argument so `sources.list` is skipped.

## Cleanup and Reuse

- Remove a single instance: `multipass delete kvm00 && multipass purge`
- Remove all instances: `multipass delete --all && multipass purge`
- The script overwrites `inventory`, `multipass/hosts`, and other temp files, so ensure you no longer need them before re-running.

## Troubleshooting

- **Multipass command not found**: verify `multipass version` works; on macOS you may need `brew reinstall multipass`.
- **Playbook SSH errors**: ensure `~/.ssh/id_rsa.pub` exists and no agent restrictions block passwordless SSH; delete and recreate VMs if necessary.
- **Slow APT downloads**: pass `true` as the second argument and point the templates to a closer mirror.
