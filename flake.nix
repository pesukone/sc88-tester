{
  description = "asdasd";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        hPkgs = pkgs.haskell.packages."ghc910";

        devTools = [
          hPkgs.ghc
          hPkgs.haskell-language-server
          hPkgs.implicit-hie
          stack-wrapped

          pkgs.portmidi
          pkgs.pkg-config
          pkgs.libadwaita
          pkgs.libsysprof-capture
          pkgs.pcre2
          pkgs.gobject-introspection
          pkgs.libxdmcp
          pkgs.util-linux
          pkgs.libselinux
          pkgs.libsepol
          pkgs.fribidi
          pkgs.libthai
          pkgs.libdatrie
          pkgs.appstream
        ];

        stack-wrapped = pkgs.symlinkJoin {
          name = "stack";
          paths = [ pkgs.stack ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/stack \
              --add-flags "\
                --no-nix \
                --system-ghc \
                --no-install-ghc \
              "
          '';
        };
      in
      {

        devShells.default = pkgs.mkShell {
          buildInputs = devTools;

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath devTools;
        };
      }
    );
}
