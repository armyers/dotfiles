# To use custom commands instead of find, override _fzf_compgen_{path,dir}
_fzf_compgen_path() {
  echo "$1"
  # command find -L "$1" \
  #   -name .git -prune -o -name .hg -prune -o -name .svn -prune -o \( -type d -o -type f -o -type l \) \
  #   -a -not -path "$1" -print 2> /dev/null | sed 's@^\./@@'
  command fd -t d -t f -t l -L --strip-cwd-prefix . "$1" 2> /dev/null'
}

_fzf_compgen_dir() {
  # command find -L "$1" \
  #   -name .git -prune -o -name .hg -prune -o -name .svn -prune -o -type d \
  #   -a -not -path "$1" -print 2> /dev/null | sed 's@^\./@@'
  command fd -t d -L --strip-cwd-prefix . "$1" 2> /dev/null'
}
