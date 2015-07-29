sgio.d [![Build Status](https://travis-ci.org/ljdelight/sgio.d.svg?branch=master)](https://travis-ci.org/ljdelight/sgio.d)
======
sgio.d is an sgio library to assist with writing low-level scsi device drivers and quick prototyping.

Features
=====
* Supports sending ioctls on both Windows and Linux
* Inquiries:
    * Standard Inquiry (0x00)
    * Supported VPD Pages VPD (0x00)
    * Unit Serial Number VPD (0x80)
    * Device Identification VPD (0x83)
    * Management Network Address VPD (0x85)
* Read Commands:
    * ReadCapacity10
    * Read10, Read12, Read16
* Write Commands:
    * Write10, Write12, Write16 (these are dangerous)

To Build
======
Use dub to build the library. See the examples directory for sample code.
