# sciota-server

## TL;DR build it:

### For apt-based Linux:

```
sudo apt-get install libsqlite3-dev openssl
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cd server
cargo build
./target/debug/server
```

### For nixos, or if you have nix installed on mac/debian/etc:

Automatic build/run for elm:
```
cd elm/
nix-shell
./watch-build.sh
```

Automatic build/run for the server:
```
cd server/
nix-shell
./watchrun.sh
```

## Build Details

How to build:

For the server, there are two parts: the elm frontend and the rust backend.  

**build tools**

For elm, you'll need elm 0.19.1, which is most likely the version that is installed via apt if you're on debian.  

For rust, standard rustc+cargo will do.  rustc being the rust compiler, and cargo being the build tool that pulls in dependencies. Some projects depend on the nightly version of rust for new features, but this one does not.  Install rust/cargo with [rustup.sh](https://rustup.rs/), or maybe with apt if you prefer.

**basic build**

To build the elm frontend, CD to elm/ and run `build.sh`.  

To build the rust part, CD to server/ and `cargo build`.  

Configure the server with server/config.toml.

When you first start the server (with `./target/debug/server`), you'll need to register a user.  This would normally happen by the server sending an email to you, but typically ISPs will block email sending.  For now the server will write each registration email out to last-email.txt.  Check that to get your registration 'magic link'.

**dev build**

If you're hacking on the elm code, the watch-build.sh will rebuild the elm code any time you save your changes.  This requires [elm-live](https://www.elm-live.com/).

For rust you can get the same thing with the watchrun.sh script; this will recompile and restart the server any time you make a change to the rust source code.  The watch feature requires installing [cargo-watch](https://github.com/passcod/cargo-watch).

