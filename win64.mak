#
# I borrowed most of this makefile from the DMD runtime win64.mak. The
#    compiler flags are the most difficult part...
#    https://github.com/D-Programming-Language/druntime/blob/master/win64.mak
#
MODEL=64

VCDIR=\Program Files (x86)\Microsoft Visual Studio 12.0\VC
SDKDIR=\Program Files (x86)\Microsoft SDKs\Windows\v7.1A

DMD=dmd

CC="$(VCDIR)\bin\amd64\cl"
LD="$(VCDIR)\bin\amd64\link"
AR="$(VCDIR)\bin\amd64\lib"

DOCDIR=doc
IMPDIR=import

DEBUG=-g -debug -unittest
DFLAGS=-m$(MODEL) $(DEBUG) -w
UDFLAGS=-m$(MODEL) -O -release -dip25 -w -Isource -Iimport
DDOCFLAGS=-c -w -o-

#CFLAGS=/O2 /I"$(VCDIR)"\INCLUDE /I"$(SDKDIR)"\Include
CFLAGS=/Z7 /I"$(VCDIR)"\INCLUDE /I"$(SDKDIR)"\Include

DRUNTIME_BASE=druntime$(MODEL)
DRUNTIME=lib\$(DRUNTIME_BASE).lib
SGIODRUNTIME=lib\sgiod64.lib

IMPORTS= \
	$(IMPDIR)\sgio\exceptions.di \
	$(IMPDIR)\sgio\inquiry.di \
	$(IMPDIR)\sgio\read.di \
	$(IMPDIR)\sgio\SCSICommand.di \
	$(IMPDIR)\sgio\SCSIDevice.di \
	$(IMPDIR)\sgio\utility.di \
	$(IMPDIR)\sgio\write.di


DOCS= \
	$(DOCDIR)\exceptions.html \
	$(DOCDIR)\inquiry.html \
	$(DOCDIR)\read.html \
	$(DOCDIR)\SCSICommand.html \
	$(DOCDIR)\SCSIDevice.html \
	$(DOCDIR)\utility.html \
	$(DOCDIR)\write.html

SRCS= \
	source\sgio\exceptions.d \
	source\sgio\inquiry.d \
	source\sgio\read.d \
	source\sgio\SCSICommand.d \
	source\sgio\SCSIDevice.d \
	source\sgio\utility.d \
	source\sgio\write.d

sgio_example.exe: sgio_example.obj $(SGIODRUNTIME)
	$(DMD) sgio_example.obj -m$(MODEL) -g -L/map -L$(SGIODRUNTIME)

sgio_example.obj: sgio_example.d
	$(DMD) -c -m$(MODEL) sgio_example -Isource -g -unittest

$(SGIODRUNTIME): $(DOCS) $(IMPORTS)
	$(DMD) -lib -of$(SGIODRUNTIME) -Xfsgiod.json $(DFLAGS) $(SRCS)


# ######################## Doc .html file generation ##############################

$(DOCDIR)\exceptions.html: source\sgio\exceptions.d
	$(DMD) $(DDOCFLAGS) -Isource -Df$@ $(DOCFMT) $**

$(DOCDIR)\inquiry.html: source\sgio\inquiry.d
	$(DMD) $(DDOCFLAGS) -Isource -Df$@ $(DOCFMT) $**

$(DOCDIR)\read.html: source\sgio\read.d
	$(DMD) $(DDOCFLAGS) -Isource -Df$@ $(DOCFMT) $**

$(DOCDIR)\SCSICommand.html: source\sgio\SCSICommand.d
	$(DMD) $(DDOCFLAGS) -Isource -Df$@ $(DOCFMT) $**

$(DOCDIR)\SCSIDevice.html: source\sgio\SCSIDevice.d
	$(DMD) $(DDOCFLAGS) -Isource -Df$@ $(DOCFMT) $**

$(DOCDIR)\utility.html: source\sgio\utility.d
	$(DMD) $(DDOCFLAGS) -Isource -Df$@ $(DOCFMT) $**

$(DOCDIR)\write.html: source\sgio\write.d
	$(DMD) $(DDOCFLAGS) -Isource -Df$@ $(DOCFMT) $**


# ######################## Header .di file generation ##############################

$(IMPDIR)\sgio\exceptions.di: source\sgio\exceptions.d
	$(DMD) -c -o- -Isource -Iimport -Hf$@ $**

$(IMPDIR)\sgio\inquiry.di: source\sgio\inquiry.d
	$(DMD) -c -o- -Isource -Iimport -Hf$@ $**

$(IMPDIR)\sgio\read.di: source\sgio\read.d
	$(DMD) -c -o- -Isource -Iimport -Hf$@ $**

$(IMPDIR)\sgio\SCSICommand.di: source\sgio\SCSICommand.d
	$(DMD) -c -o- -Isource -Iimport -Hf$@ $**

$(IMPDIR)\sgio\SCSIDevice.di: source\sgio\SCSIDevice.d
	$(DMD) -c -o- -Isource -Iimport -Hf$@ $**

$(IMPDIR)\sgio\utility.di: source\sgio\utility.d
	$(DMD) -c -o- -Isource -Iimport -Hf$@ $**

$(IMPDIR)\sgio\write.di: source\sgio\write.d
	$(DMD) -c -o- -Isource -Iimport -Hf$@ $**


clean:
	-rm -rf $(DOCDIR) $(IMPDIR) lib sgiod.json sgio_example.exe sgio_example.obj
