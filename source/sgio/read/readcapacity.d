
module sgio.read.readcapacity;

import std.bitmanip;

import sgio.SCSICommand;
import sgio.SCSIDevice;
import sgio.utility;

/**
 * ReadCapacity16 class to send a read capacity
 */
class ReadCapacity16 : SCSICommand
{
   /**
    * Params:
    *    dev = Device to execute the ioctl.
    *    datain_len = Datain buffer length
    */
   this(SCSIDevice dev, uint datain_len = 32)
   {
      super(dev, OPCODE.READ_CAPACITY_16, 0, datain_len);
      m_cdb[1] = 0x10;
      m_cdb[10..14] = nativeToBigEndian(datain_len);
      execute();
   }

   /**
    * Method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {
      m_total_lba = bigEndianToNative!ulong(datain[0..8]);
      m_blocksize = bigEndianToNative!uint(datain[8..12]);
      m_referenceTagOwnEnabled = decodeByte(datain, 12, 0x02);
      m_protectionEnabled = decodeByte(datain, 12, 0x01);
   }

   @property
   {
      ulong total_lba() { return m_total_lba; }
      uint blocksize() { return m_blocksize; }
      ubyte referenceTagOwnEnabled() { return m_referenceTagOwnEnabled; }
      ubyte protectionEnabled() { return m_protectionEnabled; }
   }

   unittest
   {
      ubyte[32] datain_buf;
      datain_buf[0..8] = nativeToBigEndian(cast(ulong) 104392);
      datain_buf[8..12] = nativeToBigEndian(cast(uint) 512);
      datain_buf[12] = 0x02;

      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto readCapacity16 = new ReadCapacity16(pseudoDev);

      assert(readCapacity16.total_lba == 104392);
      assert(readCapacity16.blocksize == 512);
      assert(readCapacity16.referenceTagOwnEnabled == 0x01);
      assert(readCapacity16.protectionEnabled == 0x00);
   }

private:
   ulong m_total_lba;
   uint m_blocksize;
   ubyte m_referenceTagOwnEnabled;
   ubyte m_protectionEnabled;
}


/**
 * ReadCapacity10 class to send a read capacity with a 10 byte CDB
 */
class ReadCapacity10 : SCSICommand
{
   /**
    * Params:
    *    dev = Device to execute the ioctl.
    *    datain_len = Datain buffer length
    */
   this(SCSIDevice dev, int datain_len = 8)
   {
      super(dev, OPCODE.READ_CAPACITY_10, 0, datain_len);
      execute();
   }

   /**
    * Method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {
      m_total_lba = bigEndianToNative!uint(datain[0..4]);
      m_blocksize = bigEndianToNative!uint(datain[4..8]);
   }

   @property
   {
      uint total_lba() { return m_total_lba; }
      uint blocksize() { return m_blocksize; }
   }

   unittest
   {
      ubyte[8] datain_buf;
      datain_buf[0..4] = nativeToBigEndian(cast(uint) 104392);
      datain_buf[4..8] = nativeToBigEndian(cast(uint) 512);

      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto readCapacity10 = new ReadCapacity10(pseudoDev);

      assert(readCapacity10.total_lba == 104392);
      assert(readCapacity10.blocksize == 512);
   }

private:
   uint m_total_lba;
   uint m_blocksize;
}
