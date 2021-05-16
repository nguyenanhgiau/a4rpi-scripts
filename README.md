# Android4Rpi - scripts

For the main project, see [main project](https://github.com/nguyenanhgiau/local_manifests/tree/rpi4-a11-telephony)

# Flash image to sdcard
If the flashing machine and the building machine is the same, just run command:
```bash
$ cd $ANDROID_BUILD_TOP
$ ./scripts/android_flash_rpi4.sh sdb #suppose your sdcard is sdb
```
In the case, your flashing machine is difference from the building machine.<br>
You have to package image and download it to your flashing machine.<br>
Then, you can flash image to sdcard.
## Package image for downloading
After building, you can package your image by command:
```bash
$ ./scripts/package_image.sh
```
After packing, you will get a folder that contains all files output, includes script flash image.<br>
Now, you can download this folder to your flashing machine and flash it to sdcard.<br>
This takes several minutes (about 1-3 minutes).
```bash
$ cd android_image #cd to folder that contains your image
$ ./android_flash_rpi4.sh sdb #suppose your sdcard is sdb
```

After all, you can unplug sdcard and plug on it to your rpi4.

