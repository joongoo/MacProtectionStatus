# Archive

Old approaches kept for reference, not part of the active build.

## build_pkg.sh

Built a `.pkg` installer via `pkgbuild` (`--install-location "/Applications"`).
Dropped because, unsigned, `installd` would register a successful install
receipt (`pkgutil --pkg-info` showed it) without actually copying the app to
`/Applications` — the payload silently never landed, with no error surfaced
to the user. Replaced by `build_dmg.sh`, which only relies on a plain Finder
drag-and-drop copy (no `installd` involved).
