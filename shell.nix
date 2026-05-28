{ pkgs ? import <nixpkgs> { 
    config = { 
      android_sdk.accept_license = true;
      allowUnfree = true;
    }; 
  }
}:

let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "9.0";
    toolsVersion = "26.1.1";
    platformToolsVersion = "35.0.1";
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

    # Ensure sysprof-capture-4.pc is found
    export PKG_CONFIG_PATH=${pkgs.sysprof.dev}/lib/pkgconfig:$PKG_CONFIG_PATH
  '';
}
