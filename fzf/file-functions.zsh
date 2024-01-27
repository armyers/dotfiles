# To use custom commands instead of find, override _fzf_compgen_{path,dir}
_fzf_compgen_path() {
  echo "$1"
  command fd -t d -t f -t l -L . "$1" | sed 's%^./%%'
}

_fzf_compgen_dir() {
  command fd -t d -L . "$1" | sed 's%^./%%'
}
