# Lustre HSM
- Explain how to check the state of a file
lfs hsm_state <file>

- How to release a file
lfs hsm_release <file>

- How to restore a file
lfs hsm_restore <file>

- How to restore all files below a directory
find . -type f -exec sudo lfs hsm_restore {} \;

- How to archibe all files below a directory
find . -type f -exec sudo lfs hsm_archive {} \;

- How to add files into blobs and then in lustre
