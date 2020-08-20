# sciota-server

How to build:

For the server, there are two parts: the elm frontend and the rust backend.  

**build tools**

For elm, you'll need elm 0.19.1, which is most likely the version that is install via apt if you're on debian.  

For rust, standard rust+cargo will do.  rustc being the rust compiler, and cargo being the build tool that pulls in dependencies. Some projects depend on the nightly version of rust for new features, but this one does not.  Install rust/cargo with [rustup.sh](https://rustup.rs/), or maybe with apt if you prefer.

**basic build**

To build the elm frontend, CD to elm/ and run `build.sh`.  

To build the rust part, CD to server/ and `cargo build`.  

When you first start the server (with `./target/debug/server`), you'll need to register a user.  This would normally happen by the server sending an email to you, but typically ISPs will block email sending.  For now the server will write each registration email out to last-email.txt.  Check that to get your registration 'magic link'.

**dev build**

If you're hacking on the elm code, the watch-build.sh will rebuild the elm code any time you save your changes.  This requires [elm-live](https://www.elm-live.com/).

For rust you can get the same thing with the watchrun.sh script; this will recompile and restart the server any time you make a change to the rust source code.  The watch feature requires installing [cargo-watch](https://github.com/passcod/cargo-watch).  Configure the server with config.toml.

