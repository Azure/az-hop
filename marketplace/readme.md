# icon sizes

- large: 216x216
- medium: 90x90
- small: 48x48
- wide: 255x115

# copy from managed disk to vhd

https://github.com/Azure-Samples/azure-cli-samples/blob/master/virtual-machine/copy-managed-disks-vhd-to-storage-account/copy-managed-disks-vhd-to-storage-account.sh

# Add to packer files
"keep_os_disk": true,
"temp_os_disk_name":  "{{user `var_image`}}"


Steps to create:
- Create icons if new offer
  - `icongen.sh`
  - `iconupload.sh`
- Build image
- Copy OS Disk
  - e.g. `./copyosdisk.sh azhop-$OFFER-centos-7.9 azhop-marketplace azhop-$OFFER-centos-7.9-v1.0.0.vhd`
- Create `$OFFER-offer.json`
- Insert SAS URLs with `insert_offer_urls.sh $OFFER` to create `$OFFER-offer-final.json` (limitation of single offer and hard-coded OS)
- put offer
  - `. auth.sh`
  - `authenticate_legacy`
  - `put_offer azhpc azhop-$OFFER $OFFER-offer-final.json`