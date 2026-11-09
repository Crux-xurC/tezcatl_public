{ pkgs, beamPackages }:

rec {
  cowlib = beamPackages.buildRebar3 rec {
    pname = "cowlib";
    version = "2.13.0";
    name = pname;
    src = pkgs.fetchHex {
      pkg = pname;
      version = version;
      sha256 = "sha256-4eEoTcP8Awpksa0Ng4KufpnaRsMka4FTGKS4SIc4AKQ=";
    };
  };

  ranch = beamPackages.buildRebar3 rec {
    pname = "ranch";
    version = "2.1.0";
    name = pname;
    src = pkgs.fetchHex {
      pkg = pname;
      version = version;
      sha256 = "sha256-JE7j+iphdScNjh/FkCT9nbx2KUoyEFfej4A7FHnnaRY=";
    };
  };

  cowboy = beamPackages.buildRebar3 rec {
    pname = "cowboy";
    version = "2.12.0";
    name = pname;
    src = pkgs.fetchHex {
      pkg = pname;
      version = version;
      sha256 = "sha256-inq+bRgzcs6yHKonCb7JKKsrcuGKORGqF3Fjm++CZR4=";
    };
    beamDeps = [ cowlib ranch ];
  };

  gun = beamPackages.buildRebar3 rec {
    pname = "gun";
    version = "2.1.0";
    name = pname;
    src = pkgs.fetchHex {
      pkg = pname;
      version = version;
      sha256 = "sha256-Uvx/wka/w7AOAa6hwoVMcKNmNIV0q1DFff55bSSgEB0=";
    };
    beamDeps = [ cowlib ];
  };

  erlexec = beamPackages.buildRebar3 rec {
    pname = "erlexec";
    version = "2.3.4";
    name = pname;
    src = pkgs.fetchHex {
      pkg = pname;
      version = version;
      sha256 = "sha256-qwxsNWmp+ZH7/mYklhqIaIYQc4WJ/5260k25uyeuIzs=";
    };
    nativeBuildInputs = [ pkgs.gnumake ];
  };

  # MariaDB as a backend (the relay's /sql): MyXQL and what it needs. Mix packages
  # (buildMix), telemetry a rebar3 one.
  telemetry = beamPackages.buildRebar3 rec {
    pname = "telemetry";
    version = "1.4.2";
    name = pname;
    src = pkgs.fetchHex {
      pkg = pname;
      version = version;
      sha256 = "sha256-ko9klQZlBgd4YsDRZGYJ7tiRpDJr7jEmulS2CvYf67E=";
    };
  };

  decimal = beamPackages.buildMix rec {
    name = "decimal";
    version = "3.1.1";
    src = pkgs.fetchHex {
      pkg = name;
      version = version;
      sha256 = "sha256-xfJfLO10oFh9A+YCP1lduOkkydOSLIyP/Z7fxEmM8fY=";
    };
  };

  db_connection = beamPackages.buildMix rec {
    name = "db_connection";
    version = "2.10.2";
    src = pkgs.fetchHex {
      pkg = name;
      version = version;
      sha256 = "sha256-UQsUSCMw8a9kkKL6Dv2NTxQ10VKbFlZH3yKsDy3w+pM=";
    };
    beamDeps = [ telemetry ];
  };

  myxql = beamPackages.buildMix rec {
    name = "myxql";
    version = "0.9.0";
    src = pkgs.fetchHex {
      pkg = name;
      version = version;
      sha256 = "sha256-OhezhWKnqZXCkVcIdf2WwGt7A2nW6wWSpSqdzL5dFEs=";
    };
    beamDeps = [ db_connection decimal telemetry ];
  };
}
