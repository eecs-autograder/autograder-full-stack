version=$1
release_branch=release-$(echo "$version" | sed -E "s/([0-9]+\.[0-9]+).*/\1.X/")
echo $release_branch
