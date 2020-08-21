{ stdenv
, fetchgit
, rustPlatform
, Security
, openssl
, pkgconfig
, sqlite
, callPackage }:

# , lib
# , packr

rustPlatform.buildRustPackage rec {
  pname = "sciota-server";
  version = "1.0";

  src = fetchgit {
    url = "https://github.com/InterstitialTech/sciota-server.git";
    rev = "18c4181f0228afcd152f1ae3754e8825ac8b3567";
    sha256 = "14lncsrnvfcarlrh9dwkv33nwcf0xxsc8ysalvxrrv7d6sd90kgb";
    fetchSubmodules = true;
  };
  # src = fetchFromGitHub {
  #   owner = "InterstitialTech";
  #   repo = "sciota-server";
  #   rev = "18c4181f0228afcd152f1ae3754e8825ac8b3567";
  #   sha256 = "14lncsrnvfcarlrh9dwkv33nwcf0xxsc8ysalvxrrv7d6sd90kgb";
  #   fetchSubmodules = true;
  # };
  # 3be7e31c95d0bc945a73ec27af608cea216da69c
  # 3be7e31c95d0bc945a73ec27af608cea216da69c
  # ui = callPackage ./ui.nix { };
  the_elm = callPackage "${src}/elm" {  };

  # preBuild = ''
  #   cp -r ${ui}/libexec/gotify-ui/deps/gotify-ui/build ui/build && packr
  # '';

  postInstall = ''
    echo "postInstall"
    ls -l $out
    mkdir $out/static
    cp -r ${src}/server/static $out/static
    cp -r ${the_elm}/Main.js $out/static/main.js
  '';

  # cargo-culting this from the gotify package.
  subPackages = [ "." ];


#  sourceRoot = "source/server";
  cargoSha256 = "1jdbjx3xa7f4yhq4l7xsgy6jpdr2lkgqrzarqb5vj2s3jg13kyl4";
  # dontMakeSourcesWritable=1;

  buildInputs = [(stdenv.lib.optional stdenv.isDarwin Security) openssl sqlite];

  nativeBuildInputs = [ pkgconfig ];

  meta = with stdenv.lib; {
    description = "A measurement repository for IOT devices.";
    homepage = https://github.com/InterstitialTech/sciota-server;
    license = with licenses; [ bsd3 ];
    maintainers = [ bburdette chronopoulos ];
    platforms = platforms.all;
  };
}

