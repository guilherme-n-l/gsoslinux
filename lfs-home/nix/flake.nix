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

	link = tgt: src:
	let
	  pkg = pkgs.${src};
	in
	pkgs.stdenv.mkDerivation {
          name = "${tgt}-wrapper";
          src = null;
          phases = [ "installPhase" ];
          buildInputs = [ pkg ];
          installPhase = ''
            mkdir -p $out/bin
            ln -s ${pkg}/bin/${src} $out/bin/${tgt}
          '';
	};

        myAwk = link "awk" "gawk";
        myYacc = link "yacc" "bison";
        mySh = link "sh" "bash";
	LFS = "/mnt/lfs";
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

	    myAwk
	    myYacc
	    mySh
          ];

          shellHook = ''
	  set +h
	  umask 022

	  export LFS=${LFS}
	  export LANG=POSIX
	  export LC_ALL=POSIX
	  export LFS_TGT=$(uname -m)-lfs-linux-gnu
	  export CONFIG_SITE=$LFS/usr/share/config.site
	  export MAKEFLAGS=-j$(nproc)

	  # if [ ! -L /bin ]; then
	  #   export PATH=/bin:$PATH
	  # fi

	  export PATH=$LFS/tools/bin:$PATH

	  echo "Welcome to the LFS-compatible development shell!"
	  cd $LFS
          '';
        };
      });
}

