counter() { tclsh ~/dotfiles/modules/tcl/counter.tcl ~/db/.counter "$@"; }
memo() { tclsh ~/dotfiles/modules/tcl/memo.tcl ~/inbox/memo "$@"; }
db() { tclsh ~/dotfiles/modules/tcl/db.tcl ~/db/db.db "$@"; }

c() { counter "$@"; }
m() { memo "$@"; }
d() { db "$@"; }
