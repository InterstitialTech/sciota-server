# sciota-server

How to build:

For the server, there are two parts: the elm frontend and the rust backend.  

For elm, you'll need elm 0.19.1, which is most likely the version that is install via apt if you're on debian.  
For rust, standard rust+cargo will do - some projects depend on the nightly version of rust of new features, but this one does not.  Install that with [rustup.sh](https://rustup.rs/), or maybe with apt.

To build the elm frontend, CD to elm/ and run `watch-build.sh`.  This will rebuild the elm code any time you change the source.  The object code (main.js) goes into server/static.

To build the rust part, CD to server/ and `cargo build`.  You can also run the watchrun.sh script; this will recompile and restart the server any time you make a change to the rust source code.  Configure the server with config.toml.

When you first start the server, you'll need to register a user.  This would normally happen by the server sending an email to you, but typically ISPs will block email sending.  For now the server will write each registration email out to last-email.txt.  Check that to get your registration `magic link`.
