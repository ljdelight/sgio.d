import std.stdio : writeln;
import core.sys.windows.windows;

import sgio.inquiry.inquiry;
import sgio.SCSIDevice;
import sgio.utility;
import sgio.exceptions;
import sgio.SCSICommand;

int main(string[] args)
{
   if (args.length <= 1)
   {
      writeln("app <device>");
      return 1;
   }

   auto deviceName = args[1];

   // TODO: this should be generalized somehow. nasty os-specific.
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
         return 1;
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
      auto vpdpages = new SupportedVPDPagesInquiry(dev);
      writeln("Here are the suppored VPD pages for " ~ deviceName);
      writeln(writeBuffer(vpdpages.supported_pages, vpdpages.supported_pages.length));
   }
   catch (SCSIException err)
   {
      writeln("SCSIException... Message: ", err.msg);
      return 1;
   }
   finally
   {
       version (Posix)
       {
          file.close();
       }
       version (Windows)
       {
          CloseHandle(file);
       }
    }
   return 0;
}
