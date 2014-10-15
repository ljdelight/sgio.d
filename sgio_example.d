

import std.stdio                 : write, writef, writeln, writefln, File;
import core.sys.windows.windows;

import sgio.inquiry;
import sgio.SCSIDevice;
import sgio.utility;
import sgio.exceptions;
import sgio.SCSICommand;

enum SENSE_CODES: int
{
   // http://www.t10.org/lists/2sensekey.htm
   NO_SENSE        = 0x00,
   RECOVERED_ERROR = 0x01,
   NOT_READY       = 0x02,
   MEDIUM_ERROR    = 0x03,
   HARDWARE_ERROR  = 0x04,
   ILLEGAL_REQUEST = 0x05,
   UNIT_ATTENTION  = 0x06,
   DATA_PROTECT    = 0x07,
   BLANK_CHECK     = 0x09,
   VENDOR_SPECIFIC = 0x09,
   COPY_ABORTED    = 0x0a,
   ABORTED_COMMAND = 0x0b,
   VOLUME_OVERFLOW = 0x0d,
   MISCOMPARE      = 0x0e,
   COMPLETED       = 0x0f
}

void printSCSICommand(SCSICommand command)
{
   writeln("CDB:");
   write(writeBuffer(command.cdb, command.cdb.length));
   writeln("DATAIN:");
   write(writeBuffer(command.datain, command.datain.length));
}

int main()
{
   version (Windows)
   {
      auto file = CreateFileW("\\\\.\\PHYSICALDRIVE1",
                       GENERIC_WRITE|GENERIC_READ,
                       FILE_SHARE_WRITE|FILE_SHARE_READ,
                       null, OPEN_EXISTING,
                       FILE_ATTRIBUTE_NORMAL, null);

      if (file == INVALID_HANDLE_VALUE)
      {
         writeln("failed to open device");
      }
      auto dev = new SCSIDevice(cast(uint)(file));
   }
   version (Posix)
   {
      auto file = File("/dev/sda", "rb");
      auto dev = new SCSIDevice(file.fileno());
   }

   try
   {
      writeln("******* SCSI STANDARD INQUIRY");
      auto inquiry = new StandardInquiry(dev);
      printSCSICommand(inquiry);
      writeBuffer(inquiry.datain, inquiry.datain.length);
      writeln("t10_vendor_identification: ", inquiry.t10_vendor_identification);
      writeln("product_identification: ", inquiry.product_identification);
      writeln("additional_length: ", inquiry.additional_length);
      writeln("product_revision_level: ", inquiry.product_revision_level);


      writeln("\n\n******** SUPPORTED_VPD_PAGES");
      auto inquiry2 = new SupportedVPDPagesInquiry(dev);
      printSCSICommand(inquiry2);
      writeln("\nNum supportedPages:", inquiry2.page_length);
      writeln(writeBuffer(inquiry2.supported_pages, inquiry2.supported_pages.length));

      writeln("\n\n******** UNIT_SERIAL_NUMBER");
      auto inquiry3 = new UnitSerialNumberInquiry(dev);
      printSCSICommand(inquiry3);
      writeln("Serial: ", cast(string)(inquiry3.unit_serial_number));

   }
   catch (SCSIException err)
   {
      writeln("Something went wrong... Error: ", err.msg);
   }

   version (Posix)
   {
      file.close();
   }
   version (Windows)
   {
      CloseHandle(file);
   }

   return 0;
}
