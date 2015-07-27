

import std.stdio                 : write, writef, writeln, writefln, File;
import core.sys.windows.windows;

import sgio.inquiry.inquiry;
import sgio.read.read;
import sgio.read.readcapacity;
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

void executeIoctls(string deviceName)
{
   writeln("Attempting open on device ", deviceName);
   version (Windows)
   {
      wchar* thefile = std.utf.toUTFz!(wchar*)(deviceName);
      auto file = CreateFileW(thefile,
                       GENERIC_WRITE|GENERIC_READ,
                       FILE_SHARE_WRITE|FILE_SHARE_READ,
                       null, OPEN_EXISTING,
                       FILE_ATTRIBUTE_NORMAL, null);

      if (file == INVALID_HANDLE_VALUE)
      {
         writeln("failed to open device");
         return;
      }
      auto dev = new SCSIDeviceBS(cast(uint)(file));
   }
   version (Posix)
   {
      auto file = File(deviceName, "rb");
      auto dev = new SCSIDeviceBS(file.fileno());
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

      // create a quick map of the supported VPD pages
      ubyte[ubyte] supportedVPDPages;
      for (int idx = 0; idx < inquiry2.supported_pages.length; idx++)
      {
         ubyte vpdPage = inquiry2.supported_pages[idx];
         supportedVPDPages[vpdPage] = vpdPage;
      }

      writeln("\n\n******** UNIT_SERIAL_NUMBER");
      if (VPD.UNIT_SERIAL_NUMBER in supportedVPDPages)
      {
         auto inquiry3 = new UnitSerialNumberInquiry(dev);
         printSCSICommand(inquiry3);
         writeln("Serial: ", inquiry3.unit_serial_number);
      }
      else
      {
         writeln("USN is not supported");
      }

      writeln("\n\n******** Device Identification Inquiry");
      if (VPD.DEVICE_IDENTIFICATION in supportedVPDPages)
      {
         auto inquiry4 = new DeviceIdentificationInquiry(dev);
         printSCSICommand(inquiry4);
      }
      else
      {
         writeln("Device identification is not supported");
      }

      writeln("\n\n******** Management Network Address");
      if (VPD.MANAGEMENT_NETWORK_ADDRESS in supportedVPDPages)
      {
         auto inquiry5 = new ManagementNetworkAddressInquiry(dev);
         printSCSICommand(inquiry5);
      }
      else
      {
         writeln("MNA is not supported");
      }

      writeln("\n\n******** Read16 1 block at LBA 0");
      auto read16 = new Read16(dev, 0, 1);

      writeln("\n\n******** Read Capacity 10");
      auto readCapacity10 = new ReadCapacity10(dev);
      printSCSICommand(readCapacity10);
      writeln("total_lba: ", readCapacity10.total_lba);
      writeln("blocksize: ", readCapacity10.blocksize);

      writeln("\n\n******** Read Capacity 16");
      auto readCapacity16 = new ReadCapacity16(dev);
      printSCSICommand(readCapacity16);
      writeln("total_lba: ", readCapacity16.total_lba);
      writeln("blocksize: ", readCapacity16.blocksize);
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

}

int main(string[] args)
{
   if (args.length <= 1)
   {
      writeln("sgio_example <device>+");
      return 1;
   }

   for (int idx = 1; idx < args.length; idx++)
   {
      executeIoctls(args[idx]);
   }

   return 0;
}
