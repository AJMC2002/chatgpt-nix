{
  autoPatchelfHook,
  fetchurl,
  lib,
  makeWrapper,
  stdenvNoCC,
  xz,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libusb1,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  pango,
  qt5,
  qt6,
  systemd,
  xdg-utils,
}: let
  arch =
    {
      x86_64-linux = "amd64";
      aarch64-linux = "arm64";
    }.${
      stdenvNoCC.hostPlatform.system
    };
  hashes = {
    amd64 = "sha256-PKWef5pmQbni+5rWgGg3hLWrgCb/dBj7ISoOvl3zodc=";
    arm64 = "sha256-mrLLuvM86+qh4G61yreBKJNvknoNl78A5AaU5fMcYps=";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "chatgpt";
    version = "26.1013.40934";

    src = fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_26.1013.40934_${arch}.deb";
      hash = hashes.${arch};
    };

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
      xz
    ];

    buildInputs = [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      gdk-pixbuf
      glib
      gtk3
      libdrm
      libgbm
      libglvnd
      libnotify
      libusb1
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      nspr
      nss
      pango
      qt6.qtbase
      systemd
    ];

    dontWrapQtApps = true;
    preFixup = ''
      addAutoPatchelfSearchPath ${qt5.qtbase.out}/lib
    '';

    # Bundled musl prebuilds aren't used by the glibc Linux app.
    autoPatchelfIgnoreMissingDeps = ["libc.musl-x86_64.so.1" "libc.musl-aarch64.so.1"];

    unpackPhase = ''
      runHook preUnpack
      ar x "$src"
      runHook postUnpack
    '';

    installPhase = ''
      mkdir -p "$out"
      tar -xJf data.tar.xz -C "$out" \
        ./usr/lib/chatgpt ./usr/share/applications/chatgpt.desktop ./usr/share/pixmaps/chatgpt.png
      mv "$out/usr/lib" "$out/lib"
      mv "$out/usr/share" "$out/share"
      rmdir "$out/usr"
      substituteInPlace "$out/share/applications/chatgpt.desktop" \
        --replace-fail 'Exec=chatgpt %U' "Exec=$out/bin/chatgpt %U"
      makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
        --chdir "$out/lib/chatgpt" \
        --prefix PATH : ${lib.makeBinPath [xdg-utils]}
    '';

    meta = {
      description = "ChatGPT desktop application by OpenAI";
      homepage = "https://chatgpt.com/";
      license = lib.licenses.unfree;
      mainProgram = "chatgpt";
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  }
