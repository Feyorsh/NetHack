{
  stdenv,
  lib,
  fetchurl,
  coreutils,
  groff,
  ncurses,
  gzip,
  gnugrep,
  less,
  x11Mode ? false,
  qtMode ? false,
  libXaw,
  libXext,
  libXpm,
  bdftopcf,
  mkfontdir,
  pkg-config,
  qt5,
  copyDesktopItems,
  makeDesktopItem,
}:

let
  platform =
    if stdenv.hostPlatform.isUnix then
      "unix"
    else
      throw "Unknown platform for NetHack: ${stdenv.hostPlatform.system}";
  unixHint = "lisp";
  # unixHint =
  #   if stdenv.hostPlatform.isLinux then
  #     "linux.370"
  #   else if stdenv.hostPlatform.isDarwin then
  #     "macos.370"
  #   else
  #     "unix";
  userDir = "~/.config/nethack";
  binPath = lib.makeBinPath [
    coreutils
    less
  ];

in
stdenv.mkDerivation rec {
  version = "3.7.0-pre";
  pname =
    if x11Mode then
      "nethack-x11"
    else if qtMode then
      "nethack-qt"
    else
      "nethack";

  src = ./.;
  # src = fetchurl {
  #   url = "https://nethack.org/download/${version}/nethack-${
  #     lib.replaceStrings [ "." ] [ "" ] version
  #   }-src.tgz";
  #   sha256 = "sha256-mM9n323r+WaKYXRaqEwJvKs2Ll0z9blE7FFV1E0qrLI=";
  # };

  buildInputs = [
    ncurses
  ]
  ++ lib.optionals x11Mode [
    libXaw
    libXext
    libXpm
  ]
  ++ lib.optionals qtMode [
    gzip
    qt5.qtbase.bin
    qt5.qtmultimedia.bin
  ];

  nativeBuildInputs = [
    copyDesktopItems
    groff
    pkg-config
  ]
  ++ lib.optionals x11Mode [
    mkfontdir
    bdftopcf
  ]
  ++ lib.optionals qtMode [
    mkfontdir
    qt5.qtbase.dev
    qt5.qtmultimedia.dev
    qt5.wrapQtAppsHook
    bdftopcf
  ];

  makeFlags = [
    "PREFIX=$(out)" "WANT_WIN_TTY=1" "WANT_WIN_CURSES=1"
  ] ++ lib.optionals (x11Mode) [
    "WANT_WIN_X11=1"
  ] ++ lib.optionals (qtMode) [
    "WANT_WIN_QT=1"
  ];

  postPatch = ''
    sed -e '/^ *cd /d' -i sys/unix/nethack.sh
    sed \
      -e 's,^WINQT4LIB =.*,WINQT4LIB = `pkg-config Qt5Gui --libs` \\\
            `pkg-config Qt5Widgets --libs` \\\
            `pkg-config Qt5Multimedia --libs`,' \
      -i sys/unix/Makefile.src
    sed \
      -e 's,^CFLAGS=-g,CFLAGS=,' \
      -e 's,/bin/gzip,${gzip}/bin/gzip,g' \
      -e 's,^WINTTYLIB=.*,WINTTYLIB=-lncurses,' \
      -i sys/unix/hints/linux.370
    sed \
      -e 's,/usr/bin/grep,${gnugrep}/bin/grep,g' \
      -i sys/unix/sysconf
    sed \
      -e 's,^CFLAGS=-g,CFLAGS=,' \
      -e 's,/bin/gzip,${gzip}/bin/gzip,g' \
      -e 's,/usr/bin/grep,${gnugrep}/bin/grep,g' \
      -i sys/unix/hints/lisp
    sed \
      -e 's,^#WANT_WIN_CURSES=1$,WANT_WIN_CURSES=1,' \
      -e 's,^CC=.*$,CC=${stdenv.cc.targetPrefix}cc,' \
      -e 's,^HACKDIR=.*$,HACKDIR=\$(PREFIX)/games/lib/\$(GAME)dir,' \
      -e 's,^SHELLDIR=.*$,SHELLDIR=\$(PREFIX)/games,' \
      -e 's,^CFLAGS+=-DCRASHREPORT,#CFLAGS+=-DCRASHREPORT,' \
      -e 's,/usr/bin/true,${coreutils}/bin/true,g' \
      -e 's,/usr/bin/grep,${gnugrep}/bin/grep,g' \
      -e 's,^CFLAGS=-g,CFLAGS=,' \
      -i sys/unix/hints/macos.370
    sed -e '/define CHDIR/d' -i include/config.h
    sed -i -e 's,^GREPPATH,#GREPPATH,' sys/unix/sysconf
    sed -i -e '/rm -f $(MAKEDEFS)/d' sys/unix/Makefile.src
    # Fix building on darwin where otherwise __has_attribute fails with an empty parameter
    sed -e 's/define __warn_unused_result__ .*/define __warn_unused_result__ __unused__/' -i include/tradstdc.h
    sed -e 's/define warn_unused_result .*/define warn_unused_result __unused__/' -i include/tradstdc.h
  '';

  configurePhase = ''
    pushd sys/${platform}
    ${lib.optionalString (platform == "unix") ''
      sh setup.sh hints/${unixHint}
    ''}
    popd
  '';

  preBuild = let
    lua546 = fetchurl {
      url = "https://www.lua.org/ftp/lua-5.4.6.tar.gz";
      hash = "sha256-fV6huctqoLWco93hxq3LV++DobqOVDLA7NBr9DmzrYg=";
    };
  in ''
    mkdir -p lib
    tar zxf ${lua546} -C lib
  '';

  enableParallelBuilding = true;

  preFixup = lib.optionalString qtMode ''
    wrapQtApp "$out/games/nethack"
  '';

  postInstall = ''
    mkdir -p $out/games/lib/nethackuserdir
    for i in xlogfile logfile perm record save; do
      mv $out/games/lib/nethackdir/$i $out/games/lib/nethackuserdir
    done

    mkdir -p $out/bin
    cat <<EOF >$out/bin/nethack
    #! ${stdenv.shell} -e
    PATH=${binPath}:\$PATH

    if [ ! -d ${userDir} ]; then
      mkdir -p ${userDir}
      cp -r $out/games/lib/nethackuserdir/* ${userDir}
      chmod -R +w ${userDir}
    fi

    RUNDIR=\$(mktemp -d)

    cleanup() {
      rm -rf \$RUNDIR
    }
    trap cleanup EXIT

    cd \$RUNDIR
    for i in ${userDir}/*; do
      ln -s \$i \$(basename \$i)
    done
    for i in $out/games/lib/nethackdir/*; do
      ln -s \$i \$(basename \$i)
    done
    set +e
    $out/games/nethack "\$@"
    if [[ \$? -gt 128 ]]; then
      echo "nethack exited abnormally, attempting to recover save file..."
      ./recover -d . ?lock.0
    fi
    EOF
    chmod +x $out/bin/nethack
    ${lib.optionalString x11Mode "mv $out/bin/nethack $out/bin/nethack-x11"}
    ${lib.optionalString qtMode "mv $out/bin/nethack $out/bin/nethack-qt"}
    install -Dm 555 util/makedefs -t $out/libexec/nethack/
    ${lib.optionalString (!(x11Mode || qtMode)) "install -Dm 555 util/dlb -t $out/libexec/nethack/"}
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "NetHack";
      exec =
        if x11Mode then
          "nethack-x11"
        else if qtMode then
          "nethack-qt"
        else
          "nethack";
      icon = "nethack";
      desktopName = "NetHack";
      comment = "NetHack is a single player dungeon exploration game";
      categories = [
        "Game"
        "ActionGame"
      ];
    })
  ];

  meta = with lib; {
    description = "Rogue-like game";
    homepage = "http://nethack.org/";
    license = "nethack";
    platforms = if x11Mode then platforms.linux else platforms.unix;
    maintainers = with maintainers; [ abbradar ];
    mainProgram = "nethack";
  };
}
