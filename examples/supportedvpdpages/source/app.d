import std.stdio : writeln;

import sgio.inquiry.inquiry;
import sgio.SCSIDevice;
import sgio.utility;
import sgio.exceptions;

int main(string[] args)
{
   if (args.length <= 1)
   {
      writeln("app <device>");
      return 1;
   }

   auto deviceName = args[1];
   auto dev = new SCSIDeviceBS(deviceName);

   try
   {
      auto vpdpages = new SupportedVPDPagesInquiry(dev);
      writeln("Here are the suppored VPD pages for " ~ deviceName);
      writeln(bufferToHexDump(vpdpages.supported_pages, vpdpages.supported_pages.length));
   }
   catch (SCSIException err)
   {
      writeln("SCSIException... Message: ", err.msg);
      return 1;
   }
   return 0;
}
