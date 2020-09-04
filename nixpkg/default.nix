{ stdenv
, fetchFromGitHub
, rustPlatform
, openssl
, pkgconfig
, sqlite
, callPackage }:

rustPlatform.buildRustPackage rec {
  pname = "sciota-server";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "InterstitialTech";
    repo = "sciota-server";
    rev = "dcc0821b145a62592afe1a8c9db88d33c4d987be";
    sha256 = "1fg4vv1wybwk0rz9dnxyg49wmh5kpma8il6rjxmh5dv8c0wpah30";
    fetchSubmodules = true;
  };

  subPackages = [ "." ];


  sourceRoot = "source/server";
  cargoSha256 = "1dah7ybr7qqfj3gdri26zn5b2cj6rvdcsdsxgn3sw6aa24cnykvs";

  buildInputs = [openssl sqlite];

  nativeBuildInputs = [ pkgconfig ];

  meta = with stdenv.lib; {
    description = "A measurement repository for IOT devices.";
    homepage = https://github.com/InterstitialTech/sciota-server;
    license = with licenses; [ gpl3 ];
    maintainers = [ bburdette chronopoulos ];
    platforms = platforms.all;
  };
}

