
module sgio.read;

import std.bitmanip;

import sgio.SCSICommand;
import sgio.SCSIDevice;
import sgio.exceptions;

/**
 * ReadCapacity10 class to send a read with a 10 byte CDB
 */
class ReadCapacity10 : SCSICommand
{
   /**
    * Params:
    *    dev = Device to execute the ioctl.
    *    alloclen = Datain buffer length
    */
   this(SCSIDevice dev, int alloclen = 8)
   {
      super(dev, 0, alloclen);
      super.init_cdb(OPCODE.READ_CAPACITY_10);
      execute();
   }

   /**
    * Method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {
      m_returned_lba = bigEndianToNative!uint(datain[0..4]);
      m_block_length = bigEndianToNative!uint(datain[4..8]);
   }

   @property
   {
      uint returned_lba() { return m_returned_lba; }
      uint block_length() { return m_block_length; }
   }

   unittest
   {
      ubyte[8] datain_buf;
      datain_buf[0..4] = nativeToBigEndian(cast(uint) 104392);
      datain_buf[4..8] = nativeToBigEndian(cast(uint) 512);

      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto read10 = new ReadCapacity10(pseudoDev);

      assert(read10.returned_lba == 104392);
      assert(read10.block_length == 512);
   }

private:
   uint m_returned_lba;
   uint m_block_length;
}


