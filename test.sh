create_tmp_dir () {
    tmpdir="$(mktemp -d)"
}

create_tmp_dir

echo $tmpdir

echo $1