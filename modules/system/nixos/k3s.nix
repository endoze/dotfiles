# k3s (lightweight Kubernetes) module for NixOS
# Provides k3s server configuration with management tools
{ config, pkgs, lib, ... }:

{
  services.k3s = {
    enable = true;
    role = "server";

    extraFlags = toString [
      # Disable built-in traefik - we'll deploy our own
      "--disable=traefik"
      # Disable servicelb - use NodePort/HostPort instead
      "--disable=servicelb"
      # Store k3s data on ZFS for persistence and snapshots
      "--data-dir=/mnt/hermes/docker/k3s"
      # Write kubeconfig with proper permissions
      "--write-kubeconfig-mode=0644"
      # Extend NodePort range for soju (6697) and enshrouded (15636/15637)
      "--service-node-port-range=53-32767"
    ];

    containerdConfigTemplate = ''
      {{ template "base" . }}

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
      privileged_without_host_devices = false
      runtime_engine = ""
      runtime_root = ""
      runtime_type = "io.containerd.runc.v2"
    '';

  };

  # k3s should start after ZFS pools are imported and CDI specs are generated
  systemd.services.k3s = {
    after = [ "zfs.target" "network-online.target" "nvidia-container-toolkit-cdi-generator.service" ];
    wants = [ "zfs.target" "network-online.target" "nvidia-container-toolkit-cdi-generator.service" ];
  };

  # Trust k3s network interfaces for firewall
  networking.firewall = {
    trustedInterfaces = [
      "cni0"       # Container network interface
      "flannel.1"  # Flannel overlay network
    ];

    # k3s API server port
    allowedTCPPorts = [ 6443 ];
  };

  # Kubernetes management tools
  environment.systemPackages = with pkgs; [
    kubectl      # Kubernetes CLI
    kubernetes-helm  # Helm package manager
    k9s          # Terminal UI for Kubernetes
    stern        # Multi-pod log tailing
    kubectx      # Switch between clusters/namespaces
  ];

  # Set KUBECONFIG environment variable system-wide
  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

}
