{ lib, buildLinux, fetchFromGitHub, fetchzip, runCommand
, ... } @ args:

let
  patchRepo = fetchFromGitHub {
    owner = "t2linux";
    repo = "linux-t2-patches";
    rev = "6.1";
    hash = "sha256-KaMd7MTH8rVoZjSyshX3gXSTuDQULpnNJU3kzHMXC00=";
  };

  version = "6.1.75";
  majorVersion = with lib; (elemAt (take 1 (splitVersion version)) 0);
in
buildLinux (args // {
  inherit version;

  pname = "linux-t2";
  # Snippet from nixpkgs
  modDirVersion = with lib; "${concatStringsSep "." (take 3 (splitVersion "${version}.0"))}";

  src = runCommand "patched-source" {} ''
    cp -r ${fetchzip {
      url = "mirror://kernel/linux/kernel/v${majorVersion}.x/linux-${version}.tar.xz";
      hash = "sha256-FvICGRPEnBaQGujy9le7cj6lVWHlSoqwifyA0gYKW6M=";
    }} $out
    chmod -R u+w $out
    cd $out
    while read -r patch; do
      echo "Applying patch $patch";
      patch -p1 < $patch;
    done < <(find ${patchRepo} -type f -name "*.patch" | sort)
  '';

  structuredExtraConfig = with lib.kernel; {
    APPLE_BCE = module;
    APPLE_GMUX = module;
    BRCMFMAC = module;
    BT_BCM = module;
    BT_HCIBCM4377 = module;
    BT_HCIUART_BCM = yes;
    BT_HCIUART = module;
    HID_APPLE_IBRIDGE = module;
    HID_APPLE = module;
    HID_APPLE_MAGIC_BACKLIGHT = module;
    HID_APPLE_TOUCHBAR = module;
    HID_SENSOR_ALS = module;
    SND_PCM = module;
    STAGING = yes;
  };

  ignoreConfigErrors = true;

  kernelPatches = [];
} // (args.argsOverride or {}))
