{ pkgs ? import <nixpkgs> { }, ... }:
let
  static-site = import ./. { };
  content = ./content;
in pkgs.runCommand "site" { inherit content; } ''
  mkdir -p content
  cp -r $content/* content
  ${static-site}/bin/static-site --input-dir content --output-dir $out
''
