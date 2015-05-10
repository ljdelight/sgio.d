sgio.d [![Build Status](https://travis-ci.org/ljdelight/sgio.d.svg?branch=master)](https://travis-ci.org/ljdelight/sgio.d)
======
sgio.d is an sgio library written in D to assist with writing low-level scsi device drivers and quick prototyping.

Features
=====
* Supports sending ioctls on both Windows and Linux (D syntax made this very easy)
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
    * Write10, Write12, Write16
    * Write commands are obviously low-level and are NOT used in the sgio_example demo code


To Build
======
There are OS-specific makefiles for Windows and Linux, and it is assumed you know how to build on those platforms (linux does need LD_LIBRARY_PATH so it can find the .so).


sgio_example.d is a sample program that sends a few inquiries (std inquiry, supported VPD, USN, and MNA) and reads the first 512-byte block of a device. I would like to extend this to do something more interesting.
