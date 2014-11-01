sgio.d
======

sgio.d is a simple sgio library written in D. It can send a few different inquiries, read, and write commands.

To Build
======

To build only the shared object:

    make final

sgio_example.d is a little sample program that sends inquiries and reads to the device. To build the sample program call `make sgio_example` and
execute `LD_LIBRARY_PATH=. ./sgio_example <device>+` as root. Call `make run` to have it execute the inquiries on /dev/sda and /dev/sdb.
