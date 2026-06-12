{ pkgs ? import <nixpkgs> {
    config = {
      android_sdk.accept_license = true;
      allowUnfree = true;
    };
  }
}:

let
  # Use Flutter 3.24.0 for compatibility with Kotlin 1.9.20
  flutter = pkgs.flutter.overrideAttrs (oldAttrs: rec {
    version = "3.24.0";
    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz";
      hash = "sha256-1SpdEvF9i8+GjRzMAf4Pf/sFtT2WKKohsHoY+dM2IfI=";
    };
  });

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "9.0";
    toolsVersion = "26.1.1";
    platformToolsVersion = "35.0.2";
    buildToolsVersions = [ "30.0.3" "33.0.0" ];
    includeEmulator = false;
    emulatorVersion = "32.1.15";
    platformVersions = [ "28" "29" "30" "33" ];
    includeSources = false;
    includeSystemImages = false;
    systemImageTypes = [ "google_apis_playstore" ];
    abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
    cmakeVersions = [ "3.22.1" ];
    includeNDK = true;
    ndkVersions = ["25.2.9519653"];
    useGoogleAPIs = false;
    useGoogleTVAddOns = false;
    includeExtras = [
      "extras;google;gcm"
    ];
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Flutter
    flutter

    # Android dependencies
    androidComposition.androidsdk
    jdk17

    # Linux desktop dependencies
    at-spi2-core
    gcc
    cmake
    dbus
    gdk-pixbuf
    glib
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav
    gtk3
    libdatrie
    libepoxy
    libselinux
    libsepol
    libthai
    libxkbcommon
    ninja
    pcre
    pkg-config
    pango
    cairo
    harfbuzz
    sysprof
    xorg.libX11
    xorg.libXcursor
    xorg.libXext
    xorg.libXinerama
    xorg.libXi
    xorg.libXrender
    xorg.libXtst

    # Chrome
    google-chrome

    # Additional tools
    git
    which
    unzip
  ];

  # Set up environment variables
  shellHook = ''
    export ANDROID_HOME=${androidComposition.androidsdk}/libexec/android-sdk
    export CHROME_EXECUTABLE=${pkgs.google-chrome}/bin/google-chrome-stable
    export PATH=$PATH:$ANDROID_HOME/platform-tools
    
    # Required for Flutter Linux desktop build
    export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath (with pkgs; [
      stdenv.cc.cc.lib
      gtk3
      glib
      libepoxy
      at-spi2-core
      dbus
      gdk-pixbuf
      pango
      cairo
      harfbuzz
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
    ])}:$LD_LIBRARY_PATH
    
    # Explicitly set compiler paths to avoid system leakage
    export CC=${pkgs.gcc}/bin/gcc
    export CXX=${pkgs.gcc}/bin/g++
    
    # Add libstdc++ and other libraries to search path
    export LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.lib.makeLibraryPath (with pkgs; [
      stdenv.cc.cc.lib
      gtk3
      glib
    ])}:$LIBRARY_PATH

    # Ensure sysprof-capture-4.pc and other pkg-config files are found
    export PKG_CONFIG_PATH=${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" (with pkgs; [
      sysprof
      glib
      gtk3
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
    ])}:$PKG_CONFIG_PATH
  '';
}
