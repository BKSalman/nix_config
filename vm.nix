# taken from https://github.com/TechsupportOnHold/Nixos-VM
{
  config,
  pkgs,
  ...
}: {
  # Add user to libvirtd group
  users.users.salman.extraGroups = ["libvirtd"];

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
    gnome.adwaita-icon-theme
  ];

  # Manage the virtualisation services
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [pkgs.OVMFFull.fd];
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;
  services.spice-webdavd.enable = true;
}
