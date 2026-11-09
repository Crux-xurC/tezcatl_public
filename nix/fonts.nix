{ pkgs }:

# Native side only (Emacs, terminals): fonts from nixpkgs. The browser's own
# faces -- Senobi Gothic (the UI face) and heterodox_chess (fairy chess
# pieces) -- are not packaged here: their files under fonts/ are local only
# (git-ignored, not redistributed) and reach the pages over HTTP through
# lib/core/fonts.css.
let
  plemolJP = pkgs.plemoljp;
in
{
  packages = [ plemolJP ];

  xdgDataDirs = "${plemolJP}/share";
}
