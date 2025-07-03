{
  description = "Dev shell with required packages for Linux From Scratch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bash
            binutils
            bison
            coreutils
            diffutils
            findutils
            gawk
            gcc
            gnumake
            gnugrep
            gzip
            linuxHeaders
            m4
            patch
            perl
            python3
            gnused
            gnutar
            texinfo
            xz
	    git
	    neovim
	    yazi
	    lazygit
          ];

          shellHook = ''
	    alias yz=yazi
	    alias lg=lazygit
            echo "Welcome to the LFS-compatible development shell!"
          '';
        };
      });
}

