{ stdenv, fetchurl, fetchzip, meson, ninja, pkgconfig, elixir, glib, src }:

with stdenv.lib;

let
  gzseek = stdenv.mkDerivation {
    name = "gzseek";

    src = fetchzip {
      url = "https://github.com/serokell/gzseek/archive/1e75f98b8cdd3be32088f76a6eb0ab288dfb5e2b.tar.gz";
      sha256 = "132s82cx9n4rgcqv6ylm4qz0czjlv1wd5zlchi808jcrjvl42w9c";
    };

    nativeBuildInputs = [ meson ninja pkgconfig ];
    buildInputs = [ glib ];
  };

  hex = fetchurl {
    url = "https://repo.hex.pm/installs/1.6.0/hex-0.18.1.ez";
    sha512 = "9c806664a3341930df4528be38b0da216a31994830c4437246555fe3027c047e073415bcb1b6557a28549e12b0c986142f5e3485825a66033f67302e87520119";
  };

  fetchHex = { pname, version, sha256 }: stdenv.mkDerivation {
    name = "hex-${pname}-${version}";

    src = fetchurl {
      url = "https://repo.hex.pm/tarballs/${pname}-${version}.tar";
      inherit sha256;

      postFetch = ''
        tar -xf $downloadedFile
        cat VERSION metadata.config contents.tar.gz > $out
      '';
    };

    buildCommand = ''
      mkdir $out && cd $out
      ${gzseek}/bin/gzseek $src | tar -zxf -
      echo ${pname},${version},${sha256},hexpm > .hex
    '';
  };

  closure = {
    dialyxir = fetchHex {
      pname = "dialyxir";
      version = "0.5.1";
      sha256 = "b331b091720fd93e878137add264bac4f644e1ddae07a70bf7062c7862c4b952";
    };

  };

  linkDependency = name: src: "ln -s ${src} deps/${name}";
in

stdenv.mkDerivation {
  name = "mix-project";
  inherit src;

  buildInputs = [ elixir ];

  configurePhase = ''
    runHook preConfigure

    mkdir deps
    ${concatStrings (mapAttrsToList linkDependency closure)}

    runHook postConfigure
  '';

  HOME = ".";
  MIX_ENV = "prod";

  buildPhase = ''
    runHook preBuild

    mix archive.install --force ${hex}
    mix compile

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    mv * $out

    runHook postInstall
  '';
}

