exec env -i LANG=POSIX LC_ALL=POSIX HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' $(which bash)
export LANG
export LC_ALL
