{
  description = "Tezcatl — dev server + browser UI + Elixir vent relay for emacs-vent";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6201e203d09599479a3b3450ed24fa81537ebc4e";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      beamPackages = pkgs.beam.packages.erlang_27;

      relayPkgs = import ./nix/relay-packages.nix { inherit pkgs beamPackages; };
      relayDeps = [
        relayPkgs.cowlib
        relayPkgs.ranch
        relayPkgs.cowboy
        relayPkgs.gun
        relayPkgs.erlexec
        relayPkgs.telemetry
        relayPkgs.decimal
        relayPkgs.db_connection
        relayPkgs.myxql
      ];

      fonts =
        if builtins.pathExists ./nix/fonts.nix
        then import ./nix/fonts.nix { inherit pkgs; }
        else { packages = [ ]; xdgDataDirs = ""; };

      fontsHook = pkgs.lib.optionalString (fonts.xdgDataDirs != "")
        ''export XDG_DATA_DIRS="$XDG_DATA_DIRS:${fonts.xdgDataDirs}"'';
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.python3
          pkgs.nodejs
          pkgs.xdg-utils
          # GET /fs/grep
          pkgs.ripgrep
          beamPackages.elixir
          beamPackages.erlang
        ]
        ++ (import ./nix/dev-tools.nix {
          inherit pkgs beamPackages;
        })
        ++ fonts.packages ++ relayDeps;

        shellHook = ''
          export TEZCATL_DIR="$PWD"
          export ELIXIR_ERL_OPTIONS="+fnu"

          # this machine's own settings (git-ignored), e.g. TEZCATL_FS_ROOT
          if [ -f "$TEZCATL_DIR/local.env" ]; then . "$TEZCATL_DIR/local.env"; fi
          ${fontsHook}

          # Run just the relay in the foreground (Ctrl-C to stop). Without
          # POCA_SECRET it needs --no-auth (D-poca-secret).
          relay() {
            if [ "''${1:-}" = --no-auth ]; then
              ( cd "$TEZCATL_DIR" && TEZCATL_AUTH=off elixir main.exs )
            else
              ( cd "$TEZCATL_DIR" && elixir main.exs )
            fi
          }

          # Bring tezcatl up: the pages and the relay, in the foreground (Ctrl+C
          # stops both; refuses when a port is in use). It opens no browser and
          # starts no backend -- emacs-vent and Xipe Totec are started on their
          # own (Poca's box). The work is nix/t, so an outside launcher can run it.
          t() {
            "$TEZCATL_DIR/nix/t" "$@"
          }

          echo "--------------------------------------------------"
          echo "🚀  Tezcatl dev shell  (pages :4001, relay :4100; backends: emacs-vent :4000, xipe :4200)"
          echo "--------------------------------------------------"
          echo "  t       : start pages + relay in the foreground, Ctrl+C stops both (refuses if a port is in use); opens no browser"
          echo "            needs Poca's POCA_SECRET (start it from Poca's box), or t --no-auth to run without authentication"
          echo "  relay   : run the vent relay in the foreground (relay --no-auth without POCA_SECRET)"
          echo "  pages   : main.html (launcher: image + page list + form) / launcher.html (minimal fallback) / panels/{input,output,code,xterm}.html"
          echo "  tests   : node --test test/*.test.js   (nothing needs to be running)"
          echo "  logs    : /tmp/tezcatl-{http,relay}.log"
          echo "  nvim    : the PTY box uses your own nvim on PATH (login shell); Tezcatl ships none"
        '';
      };
    };
}
