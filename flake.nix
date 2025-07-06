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
	LFS = "/mnt/lfs";
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [];

          shellHook = ''
	    [ $(id -u) -ne 0 ] && { echo "must run as root: \`sudo nix develop\`" ; exit 1; }

	    export LFS=${LFS}
	    export GIT_SSH_COMMAND="ssh -F /home/guilh/.ssh/config"

	    umask 022

	    mountpoint -q $LFS || mount /dev/sda3 $LFS
	    mountpoint -q $LFS/boot || mount /dev/sda1 $LFS/boot
	    swapon --show=NAME | grep -q "^/dev/sda2$" || swapon /dev/sda2

	    chown root:root $LFS
	    chmod 755 $LFS

	    exec sudo -u lfs nix develop /home/lfs/nix
          '';
        };
      });
}

