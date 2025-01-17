{ lib
, stdenv
, buildGoModule
, fetchFromGitHub
, makeDesktopItem
, copyDesktopItems
, pkg-config
, desktopToDarwinBundle
, xorg
, wayland
, wayland-protocols
, libxkbcommon
, libglvnd
, mpv
, darwin
, waylandSupport ? false
}:

assert waylandSupport -> stdenv.isLinux;

buildGoModule rec {
  pname = "supersonic" + lib.optionalString waylandSupport "-wayland";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "dweymouth";
    repo = "supersonic";
    rev = "v${version}";
    hash = "sha256-4SLAUqLMoUxTSi4I/QeHqudO62Gmhpm1XbCGf+3rPlc=";
  };

  vendorHash = "sha256-6Yp5OoybFpoBuIKodbwnyX3crLCl8hJ2r4plzo0plsY=";

  nativeBuildInputs = [
    copyDesktopItems
    pkg-config
  ] ++ lib.optionals stdenv.isDarwin [
    desktopToDarwinBundle
  ];

  # go-glfw doesn't support both X11 and Wayland in single build
  tags = lib.optionals waylandSupport [ "wayland" ];

  buildInputs = [
    libglvnd
    mpv
  ] ++ lib.optionals stdenv.isLinux [
    xorg.libXxf86vm
    xorg.libX11
  ] ++ lib.optionals (stdenv.isLinux && !waylandSupport) [
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXcursor
    xorg.libXi
    xorg.libXext
  ] ++ lib.optionals (stdenv.isLinux && waylandSupport) [
    wayland
    wayland-protocols
    libxkbcommon
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk_11_0.frameworks.Cocoa
    darwin.apple_sdk_11_0.frameworks.Kernel
    darwin.apple_sdk_11_0.frameworks.OpenGL
    darwin.apple_sdk_11_0.frameworks.UserNotifications
  ];

  postInstall = ''
    for dimension in 128 256 512;do
        dimensions=''${dimension}x''${dimension}
        mkdir -p $out/share/icons/hicolor/$dimensions/apps
        cp res/appicon-$dimension.png $out/share/icons/hicolor/$dimensions/apps/${meta.mainProgram}.png
    done
  '' + lib.optionalString waylandSupport ''
    mv $out/bin/supersonic $out/bin/${meta.mainProgram}
  '';

  desktopItems = [
    (makeDesktopItem {
      name = meta.mainProgram;
      exec = meta.mainProgram;
      icon = meta.mainProgram;
      desktopName = "Supersonic" + lib.optionalString waylandSupport " (Wayland)";
      genericName = "Subsonic Client";
      comment = meta.description;
      type = "Application";
      categories = [ "Audio" "AudioVideo" ];
    })
  ];

  meta = with lib; {
    mainProgram = "supersonic" + lib.optionalString waylandSupport "-wayland";
    description = "A lightweight cross-platform desktop client for Subsonic music servers";
    homepage = "https://github.com/dweymouth/supersonic";
    platforms = platforms.linux ++ platforms.darwin;
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ zane sochotnicky ];
  };
}
