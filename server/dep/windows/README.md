# Windows build dependencies

These are the Windows x64 dependencies used by the MaNGOS server build. They replace the
old GPL-2.0-only MySQL client and OpenSSL 1.0.2 bundles so the server can be distributed
under GPL-3.0.

| Component | Version | License | Source |
| --- | --- | --- | --- |
| MariaDB Connector/C | 3.4.10 | LGPL-2.1-or-later | MariaDB Server 11.4.13 winx64 package (libmariadb.dll, client headers) |
| OpenSSL | 3.5.9 LTS | Apache-2.0 | https://slproweb.com/products/Win32OpenSSL.html |

The MariaDB connector uses Windows Schannel for TLS and does not link OpenSSL. The server
uses libcrypto for its own crypto and loads the OpenSSL legacy provider from `legacy.dll` in
the server directory (RC4 is needed for the 1.12 auth stream).

The Debug configuration links the same import libraries and runs the same DLLs; only the Release
copies are kept to avoid duplicating the binaries.

SHA-256 of the shipped binaries:

- `lib/x64_release/legacy.dll`: `cb94828d5828bdc035207b348bb9159e80488e6623107bc69312c9eb3941b081`
- `lib/x64_release/libcrypto-3-x64.dll`: `81bc67d537fcd320d8ede1c5a49506629f0fd04e42ec7e9b0bab70a822d4fba5`
- `lib/x64_release/libcrypto.lib`: `f81322c5ac0b748a839af6827d079c4bdd28248702efd7a90042ea714dbc2a92`
- `lib/x64_release/libmariadb.dll`: `48196755ea9c3db151fc22f450cc35167d9142046925a85557670129c0a41742`
- `lib/x64_release/libmariadb.lib`: `2ee0c3d6813103f23f8395d9996529c63fb0770e3c70dd5a20e1554c21c1f4d4`
