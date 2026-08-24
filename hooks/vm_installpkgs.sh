# In-guest install script for the RHEL-family builders (piped into the guest
# sh by build.py with ANYVM_PKGS prepended; runs under set -e).
#
# The cloud image's pre-baked dnf metadata is a point-in-time snapshot of the
# compose it was built from. Once a point release rolls, the cached repodata
# still advertises package versions that have been rotated out of the mirror,
# and `dnf install` fails with a 404 on the .rpm rather than with a clear
# "your metadata is stale" error. Expiring the cache first is cheap insurance.
#
# --setopt=install_weak_deps=False keeps the image from pulling in the
# recommends chain (documentation, extra fonts) that a base VM never uses;
# on the TCG-emulated arches every avoided package is real wall-clock.
dnf clean expire-cache
dnf install -y --setopt=install_weak_deps=False $ANYVM_PKGS
