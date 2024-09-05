{
  description = "Rust";

  inputs = {
    git-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      git-hooks,
      nixpkgs,
    }:
    let
      inherit (nixpkgs) lib;

      mapPackages = f: lib.mapAttrs f nixpkgs.legacyPackages;

      toFormatter = _: pkgs: pkgs.nixfmt-rfc-style;

      toChecks = system: pkgs: {
        git-hooks = git-hooks.lib.${system}.run {
          src = self;
          hooks = {
            end-of-file-fixer.enable = true;
            fix-byte-order-marker.enable = true;
            mixed-line-endings.enable = true;
            nixfmt = {
              enable = true;
              package = toFormatter system pkgs;
            };
            trim-trailing-whitespace.enable = true;
          };
        };
      };

      toShells =
        system: pkgs:
        let
          inherit (self.checks.${system}) git-hooks;

          extraPackages = with pkgs; [
            clang
            gdb
            nil
            rust-analyzer
            rustfilt
            (toFormatter system pkgs)
          ];
        in
        {
          default = pkgs.mkShell {
            inherit (git-hooks) shellHook;
            packages = extraPackages ++ git-hooks.enabledPackages;
          };
        };
    in
    {
      checks = mapPackages toChecks;
      formatter = mapPackages toFormatter;
      devShells = mapPackages toShells;
    };
}
