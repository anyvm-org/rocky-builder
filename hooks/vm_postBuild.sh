# in-guest postBuild hook (piped to the guest's sh over SSH by build.py).
#
# Keep everything tolerant: build.py runs this over the remote shell with the
# remote shell exiting non-zero on any unhandled error, and one dnf hiccup
# should not abort the whole build.
#
# IMPORTANT: do NOT run a full `dnf makecache` or `dnf upgrade` here. On a
# TCG aarch64 / ppc64le / s390x guest that is tens of minutes of CPU on a
# 2-core GHA runner, which blocks the SSH session and looks like the build
# has hung. hooks/vm_installpkgs.sh does the one cache expiry that is needed.

echo "=================== postBuild ===="

# Make sure sshd survives the reboot that build.py does right after this
# hook. The RHEL family names the unit sshd.service (not ssh.service as on
# Debian/Ubuntu).
echo "--- enabling sshd ---"
systemctl enable sshd.service 2>/dev/null || systemctl enable sshd 2>/dev/null || true

# --- kill the background metadata-refresh machinery ---------------------
# dnf-makecache.timer fires within minutes of every boot and holds the dnf
# lock while it downloads repodata. A short-lived VM is handed to the user
# the moment sshd answers, so the user's very first `dnf install` races it
# and dies on the lock. Nothing in a disposable CI VM benefits from a
# background metadata refresh, so switch it off permanently.
#
# Order matters: stop anything already running (a mask does not stop a live
# unit), then disable, then mask so a later package upgrade cannot quietly
# re-enable it. This block must stay AHEAD of any dnf call in this hook, and
# it protects the VM_PRE_INSTALL_PKGS install build.py runs after the reboot
# as well.
echo "--- disabling dnf background metadata refresh ---"
_dnf_auto_units="dnf-makecache.timer dnf-makecache.service
dnf-automatic.timer dnf-automatic-install.timer"
systemctl stop $_dnf_auto_units 2>/dev/null || true
systemctl disable dnf-makecache.timer dnf-automatic.timer \
    dnf-automatic-install.timer 2>/dev/null || true
systemctl mask $_dnf_auto_units 2>/dev/null || true

# Belt and braces, and the part that survives a unit reshuffle: with
# metadata_timer_sync off, the periodic work is a no-op even if a timer
# comes back.
if [ -f /etc/dnf/dnf.conf ] && ! grep -q '^metadata_timer_sync' /etc/dnf/dnf.conf; then
    echo 'metadata_timer_sync=0' >> /etc/dnf/dnf.conf
fi

# NOTE: do NOT run "cloud-init clean" here. build.py reboots right after
# this hook, and a clean makes cloud-init treat the next boot as a new
# instance, which (via ssh_deletekeys) regenerates the SSH host keys. The
# host key for the VM's IP then changes mid-build and the next "ssh"
# fails with "REMOTE HOST IDENTIFICATION HAS CHANGED".

passwd -d root

echo "postBuild done."

exit 0
