#nix/dev-tools.nix
{ pkgs, beamPackages }:


with pkgs; [
  # --- Language servers (lsp.json's command is looked up on PATH) ---
  # Elixir: /lsp's elixir. xipe_totec's Scanner.Lsp uses it through /lsp too.
  # Taken from beamPackages, so it is built with the same Elixir/OTP as the relay
  beamPackages.elixir-ls

  # JavaScript / TypeScript (tezcatl's own browser side)
  typescript-language-server
  # JSON (config.json, lsp.json ...; the css / html servers are in the same package)
  vscode-langservers-extracted
  # Nix (flake.nix, nix/*.nix)
  nil
  # OCaml (a xipe_totec target). Its version may differ from a project's OCaml;
  # the LSP only assists editing, so they are not kept strictly the same
  ocamlPackages.ocaml-lsp

  # Haskell: HLS is too large (7.2 GiB unpacked), so it is left out. Instead
  # efm-langserver (a generic bridge, a few MiB) runs `ghc -fno-code` on every save
  # and returns its errors and warnings as diagnostics -- about what loading the file
  # in GHCi shows. No completion, no hover. ghc is the one on PATH (not necessarily
  # the project environment's). -dynamic is there because Arch's ghc has only dynamic
  # libraries (it works with nixpkgs' ghc too). When an imported module is broken,
  # nothing shows for the open file (ghc stops in the import)
  (writeShellScriptBin "tezcatl-haskell-lsp" ''
    exec ${efm-langserver}/bin/efm-langserver -c ${writeText "efm-haskell.yaml" ''
      version: 2
      lint-debounce: 500ms
      languages:
        haskell:
          - lint-command: 'ghc -dynamic -fno-code -fdiagnostics-color=never -fno-diagnostics-show-caret -Wall -outputdir "''${TMPDIR:-/tmp}/tezcatl-ghc" -i"$(dirname ''${INPUT})" -isrc ''${INPUT}'
            lint-stdin: false
            lint-ignore-exit-code: true
            lint-after-open: true
            lint-on-save: true
            lint-source: ghc
            lint-formats:
              - '%E%f:%l:%c: error: %m'
              - '%W%f:%l:%c: warning: %m'
              - '%C    %m'
              - '%-G%.%#'
    ''}
  '')

  # Elixir for the editor (the "editor" of lsp.json's elixir). Where there is no mix.exs,
  # elixir-ls returns no diagnostics at all (not even syntax errors), so there
  # efm-langserver checks the syntax only, with `Code.string_to_quoted` -- the file is
  # neither run nor compiled, so top-level code does not run, and undefined functions
  # and warnings are not reported. It sees the text being edited (before a save). Where
  # there is a mix.exs (the root the relay picks by rootMarkers = the working directory)
  # elixir-ls is used as it is. Xipe Totec's scan keeps using lsp.json's elixir itself
  # (elixir-ls)
  (writeShellScriptBin "tezcatl-elixir-lsp" ''
    if [ -f mix.exs ]; then exec ${beamPackages.elixir-ls}/bin/elixir-ls; fi
    exec ${efm-langserver}/bin/efm-langserver -c ${writeText "efm-elixir.yaml" ''
      version: 2
      lint-debounce: 300ms
      languages:
        elixir:
          - lint-command: '${beamPackages.elixir}/bin/elixir ${writeText "tezcatl-elixir-syntax.exs" ''
              # stdin: the buffer; argv: its path (for the messages only)
              [file] = System.argv()
              src = IO.read(:stdio, :eof)
              case Code.string_to_quoted(src, file: file, columns: true, emit_warnings: false) do
                {:ok, _} ->
                  :ok

                {:error, {meta, msg, token}} ->
                  {line, col} = if is_list(meta), do: {meta[:line] || 1, meta[:column] || 1}, else: {meta, 1}
                  msg = case msg do
                    {a, b} -> a <> b
                    m -> m
                  end
                  IO.puts("#{file}:#{line}:#{col}: error: #{String.replace(msg <> token, "\n", " ")}")
              end
            ''} ''${INPUT}'
            lint-stdin: true
            lint-ignore-exit-code: true
            lint-after-open: true
            lint-source: elixir
            lint-formats:
              - '%f:%l:%c: %trror: %m'
    ''}
  '')

  # shell (lsp.json's shell): efm-langserver runs shellcheck. Syntax errors are
  # reported by shellcheck's own parser too. It sees the text being edited. SC2148
  # (unknown shell) of a file with no shebang is not reported
  (writeShellScriptBin "tezcatl-shell-lsp" ''
    exec ${efm-langserver}/bin/efm-langserver -c ${writeText "efm-shell.yaml" ''
      version: 2
      lint-debounce: 300ms
      languages:
        shell:
          - lint-command: '${shellcheck}/bin/shellcheck -f gcc -x -e SC2148 -'
            lint-stdin: true
            lint-ignore-exit-code: true
            lint-after-open: true
            lint-source: shellcheck
            lint-formats:
              - '-:%l:%c: %trror: %m'
              - '-:%l:%c: %tarning: %m'
              - '-:%l:%c: %tote: %m'
    ''}
  '')
]
