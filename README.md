sgio.d
======

sgio.d is a simple sgio library written in D. It can only send a few different
scsi inquiries for now.

To Build
======

To build only the shared object just call

    make final

To build the library and sgio_example.d, build with `make sgio_example` and
execute `LD_LIBRARY_PATH=. ./sgio_example <device>` as root.
