
No `sshfs` cell is listed for any release: `fuse-sshfs` is not packaged in
Rocky's BaseOS or AppStream for 9 or 10 (it lives in EPEL), and a base image
should not carry a third-party repository. `rsync`, `nfs-utils` and `tree`
are all in BaseOS, so every other sync method listed above is real.
