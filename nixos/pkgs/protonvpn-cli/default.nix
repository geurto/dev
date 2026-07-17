{
  lib,
  pkgs,
  python3Packages,
  fetchFromGitHub,
  rustPlatform,
  maturin,
}:

let
  py = python3Packages;

  proton-core = py.buildPythonPackage rec {
    pname = "proton-core";
    version = "unstable-2024";
    pyproject = true;
    build-system = [ py.setuptools ];
    src = fetchFromGitHub {
      owner = "ProtonVPN";
      repo = "python-proton-core";
      rev = "f7a178a99c3adc0e88c7f91d4db5371a052c4985"; # pin to a specific commit hash!
      hash = "sha256-ZT/LkppzeEDGs9aOCx561fA1EgAShPCnMs8c05mgF0k=";
    };
    propagatedBuildInputs = with py; [
      requests
      cryptography
      bcrypt
      keyring
      python-gnupg
      pyopenssl
      aiohttp
    ];
    doCheck = false;
  };

  proton-vpn-local-agent =
    let
      localAgentSo = rustPlatform.buildRustPackage {
        pname = "proton-vpn-local-agent";
        version = "1.6.1";

        src = fetchFromGitHub {
          owner = "ProtonVPN";
          repo = "local-agent-rs";
          rev = "ee7a8e2fa94e41c3e3d7fe11f77341c87c5ed936";
          hash = "sha256-VmZ8nsKqP8jyNe7Rl+PHsXhsjgchq3rKmTtAqFEe7yM=";
        };

        sourceRoot = "source/python-proton-vpn-local-agent";

        cargoHash = "sha256-MOCLMQ8mqv8Q3I3bIS0ynfpPmrULMA+80RHZBeu7r5s=";

        postInstall = ''
          # rename the cdylib to what Python expects
          mv $out/lib/libpython_proton_vpn_local_agent.so $out/lib/local_agent.so
        '';
      };
    in
    py.buildPythonPackage {
      pname = "proton-vpn-local-agent";
      version = "1.6.1";
      format = "other";

      dontUnpack = true;

      installPhase = ''
        mkdir -p $out/${py.python.sitePackages}/proton/vpn
        cp ${localAgentSo}/lib/local_agent.so $out/${py.python.sitePackages}/proton/vpn/
      '';
    };

  proton-keyring-linux = py.buildPythonPackage rec {
    pname = "proton-keyring-linux";
    version = "unstable-2024";
    pyproject = true;
    build-system = [ py.setuptools ];
    src = fetchFromGitHub {
      owner = "ProtonVPN";
      repo = "python-proton-keyring-linux";
      rev = "1534c2f09d73ad18a073c09dd314e11c9da895e0";
      hash = "sha256-deld1MjuTjgjXBCUuDzYABRjN4gT1mz+duV0Qj4IWCg=";
    };
    propagatedBuildInputs = [ proton-core ];
    doCheck = false;
  };

  proton-vpn-api-core = py.buildPythonPackage rec {
    pname = "proton-vpn-api-core";
    version = "unstable-2024";
    pyproject = true;
    build-system = [ py.setuptools ];
    src = fetchFromGitHub {
      owner = "ProtonVPN";
      repo = "python-proton-vpn-api-core";
      rev = "c167ab87cae2d0184d2a0378b810776d91182533";
      hash = "sha256-jSlkHH5NGv/3rO+IcMAnxPLtoWmfBkPR7wMG2CkPVpQ=";
    };
    pythonRemoveDeps = [ "proton-vpn-local-agent" ];
    propagatedBuildInputs = with py; [
      proton-core
      proton-vpn-local-agent
      distro
      sentry-sdk
      pynacl
      fido2
      pygobject3
      pycairo
      jinja2
    ];
    doCheck = false;
  };

in
py.buildPythonPackage rec {
  pname = "proton-vpn-cli";
  version = "unstable-2024";
  pyproject = true;
  build-system = [ py.setuptools ];
  makeWrapperArgs = [ "--prefix GI_TYPELIB_PATH : ${pkgs.networkmanager}/lib/girepository-1.0" ];

  src = fetchFromGitHub {
    owner = "ProtonVPN";
    repo = "proton-vpn-cli";
    rev = "7b7725eba22231287bb7adce8b817eeadc61a2c6";
    hash = "sha256-CkkytFC3Zr/l2EV5W70kssN1v11F23oZpDvf7JWqmvQ=";
  };

  pythonRemoveDeps = [ "proton-vpn-local-agent" ];
  propagatedBuildInputs =
    with py;
    [
      proton-core
      proton-vpn-api-core
      proton-keyring-linux
      proton-vpn-local-agent
      click
      packaging
      dbus-fast
      tabulate
    ]
    ++ (with pkgs; [
      networkmanager # provides the NM GObject introspection namespace
    ]);

  doCheck = false;

  meta = {
    description = "Official ProtonVPN CLI Linux app";
    homepage = "https://github.com/ProtonVPN/proton-vpn-cli";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
  };
}
