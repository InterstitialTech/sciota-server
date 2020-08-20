{ stdenv
, fetchFromGitHub
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

  src = fetchFromGitHub {
    owner = "InterstitialTech"
    repo = "sciota-server";
    rev = "25e29e4f432eca12f84a8c71a295e3d185bc5a90";
    sha256 = "1k0x8z6m2326prsmz3mrs9yjn6kq92jaqw74if77di6pwz26qcig";
  };

  # ui = callPackage ./ui.nix { };
  the_elm = callPackage "${src}/elm" {  };

  # preBuild = ''
  #   cp -r ${ui}/libexec/gotify-ui/deps/gotify-ui/build ui/build && packr
  # '';

  postInstall = ''
    echo "postInstall"
    ls -l $out
    mkdir ${out}/static
    cp -r ${src}/server/static ${out}/static
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
    maintainers = [ bburdette, chronopoulos ];
    platforms = platforms.all;
  };
}

