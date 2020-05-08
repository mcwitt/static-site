{
  network.description = "Web server";

  webserver = _: {
    networking.firewall.allowedTCPPorts = [ 80 ];
    nixpkgs.localSystem.system = "x86_64-linux";

    services.nginx = {
      enable = true;
      virtualHosts.localhost = { root = import ../site.nix { }; };
    };
  };
}
