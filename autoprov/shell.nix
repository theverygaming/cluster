with import (fetchTarball https://github.com/NixOS/nixpkgs/archive/e8057b67ebf307f01bdcc8fba94d94f75039d1f6.tar.gz) { };
let
  sillyORMPackage = pkgs.python311Packages.buildPythonPackage rec {
    pname = "sillyorm";
    version = "0.2.0";
    pyproject = true;

    nativeBuildInputs = [
      python311Packages.setuptools
    ];

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-7ItyPeLalI6clXfw4dTsJYUNYgwg4rWobfK9N56DA7g=";
    };
  };
in
stdenv.mkDerivation {
  name = "autoprov";
  buildInputs = [
    # server
    sillyORMPackage
    python311Packages.flask
    python311Packages.waitress

    # client
    python311Packages.requests
  ];
}
