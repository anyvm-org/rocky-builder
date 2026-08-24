# Image-slimming finalize. Runs as the LAST in-guest hook, after postBuild
# and the VM_PRE_INSTALL_PKGS installs.
#
# Unlike the Debian-family builders, dropping the package metadata here is
# safe: dnf refetches repodata on demand and does not need a separate
# "update" step first, so a user's `dnf install` still works out of the box
# on a shipped image. That makes `dnf clean all` a pure win -- the cached
# repodata is tens of megabytes.

echo "=== finalize: image cleanup ==="

dnf clean all || true
rm -rf /var/cache/dnf/* 2>/dev/null || true

# TRIM every mounted filesystem: the build disk runs with discard=unmap, so
# freed blocks (package churn, kernel leftovers) become holes in the qcow2
# and the export-time sparsify reclaims them. The RHEL-family cloud images
# root on xfs, which supports fstrim the same way ext4 does.
fstrim -av || true

df -h || true
echo "=== finalize: image cleanup done ==="
