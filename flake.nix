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
	    wget
          ];

          shellHook = ''
	    alias yz=yazi
	    alias lg=lazygit

	    [ $(id -u) -ne 0 ] && { echo "must run as root: \`sudo nix develop\`" ; exit 1; }

	    export LFS=/mnt/lfs
	    export GIT_SSH_COMMAND="ssh -F /home/guilh/.ssh/config"

	    umask 022

	    mountpoint -q $LFS || mount /dev/sda3 $LFS
	    mountpoint -q $LFS/boot || mount /dev/sda1 $LFS/boot
	    swapon --show=NAME | grep -q "^/dev/sda2$" || swapon /dev/sda2

	    chown root:root $LFS
	    chmod 755 $LFS

            echo "Welcome to the LFS-compatible development shell!"
          '';
        };
      });
}

