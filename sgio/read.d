
module sgio.read;

import std.bitmanip;

import sgio.SCSICommand;
import sgio.SCSIDevice;
import sgio.exceptions;

/**
 * ReadCapacity10 class to send a read capacity with a 10 byte CDB
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
      auto readCapacity10 = new ReadCapacity10(pseudoDev);

      assert(readCapacity10.returned_lba == 104392);
      assert(readCapacity10.block_length == 512);
   }

private:
   uint m_returned_lba;
   uint m_block_length;
}

/**
 * Simple helper function to create the second byte of the CDB for read(10), read(12), and read(16).
 * For a description of the arguments, see the Read(XX) commands.
 */
private ubyte readXXHelperCreateByte(ubyte rdprotect, ubyte dpo, ubyte fua, ubyte rarc)
{
   ubyte res = 0;
   res |= (rdprotect << 5) & 0xe0;
   res |= dpo  ? 0x10 : 0;
   res |= fua  ? 0x80 : 0;
   res |= rarc ? 0x04 : 0;

   return res;
}

/**
 * Class to send a Read(10) command to a scsi device.
 * NOTE: SBC3r36 has this note: Migration from the READ (10) command to the READ (16) command
 *    is recommended for all implementations.
 */
class Read10 : SCSICommand
{
public:
   /**
    *
    * Params:
    *    dev = Device to send the scsi command
    *    blocksize = Blocksize of the device
    *    lba = Starting LBA of the read
    *    transfer_length = Number of blocks to read
    *    group_num =
    *    rdprotect = Read protection information
    *    dpo = Disable page out bit
    *    fua = Force unit access
    *    rarc = Rebuild assist recovery control
    */
   this(SCSIDevice dev, int blocksize, uint lba, ushort transfer_length,
         ubyte group_num=0, ubyte rdprotect=0, ubyte dpo=0, ubyte fua=0, ubyte rarc=0)
   {
      super(dev, 0, blocksize*transfer_length);
      super.init_cdb(OPCODE.READ_10);

      m_cdb[1] = readXXHelperCreateByte(rdprotect, dpo, fua, rarc);
      m_cdb[2..6] = nativeToBigEndian!uint(lba);
      m_cdb[6] = group_num & 0x1f;
      m_cdb[7..9] = nativeToBigEndian!ushort(transfer_length);
      execute();
   }

   /**
    * Method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {
      // empty
   }

   unittest
   {
      ubyte[512] datain_buf;
      datain_buf[0x1fe..0x200] = [0x55, 0xaa];

      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto read10 = new Read10(pseudoDev, 512, 0, 1);

      assert(read10.datain[0x1fe..0x200] == [0x55, 0xaa]);
   }
private:

}



/**
 * Class to send a Read(12) command to a scsi device.
 */
class Read12 : SCSICommand
{
public:
   /**
    *
    * Params:
    *    dev = Device to send the scsi command
    *    blocksize = Blocksize of the device
    *    lba = Starting LBA of the read
    *    transfer_length = Number of blocks to read
    *    group_num =
    *    rdprotect = Read protection information
    *    dpo = Disable page out bit
    *    fua = Force unit access
    *    rarc = Rebuild assist recovery control
    */
   this(SCSIDevice dev, int blocksize, uint lba, uint transfer_length,
         ubyte group_num=0, ubyte rdprotect=0, ubyte dpo=0, ubyte fua=0, ubyte rarc=0)
   {
      super(dev, 0, blocksize*transfer_length);
      super.init_cdb(OPCODE.READ_12);

      m_cdb[1] = readXXHelperCreateByte(rdprotect, dpo, fua, rarc);
      m_cdb[2..6]  = nativeToBigEndian!uint(lba);
      m_cdb[6..10] = nativeToBigEndian!uint(transfer_length);
      m_cdb[10] = group_num & 0x1f;
      execute();
   }

   /**
    * Method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {
      // empty
   }

   unittest
   {
      ubyte[512] datain_buf;
      datain_buf[0x1fe..0x200] = [0x55, 0xaa];

      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto read12 = new Read12(pseudoDev, 512, 0, 1);

      assert(read12.datain[0x1fe..0x200] == [0x55, 0xaa]);
   }
private:

}



/**
 * Class to send a Read(16) command to a scsi device.
 */
class Read16 : SCSICommand
{
public:
   /**
    *
    * Params:
    *    dev = Device to send the scsi command
    *    blocksize = Blocksize of the device
    *    lba = Starting LBA of the read
    *    transfer_length = Number of blocks to read
    *    group_num =
    *    rdprotect = Read protection information
    *    dpo = Disable page out bit
    *    fua = Force unit access
    *    rarc = Rebuild assist recovery control
    */
   this(SCSIDevice dev, int blocksize, ulong lba, uint transfer_length,
         ubyte group_num=0, ubyte rdprotect=0, ubyte dpo=0, ubyte fua=0, ubyte rarc=0)
   {
      super(dev, 0, blocksize*transfer_length);
      super.init_cdb(OPCODE.READ_16);

      m_cdb[1] = readXXHelperCreateByte(rdprotect, dpo, fua, rarc);
      m_cdb[2..10]  = nativeToBigEndian!ulong(lba);
      m_cdb[10..14] = nativeToBigEndian!uint(cast(uint) transfer_length);
      m_cdb[14] = group_num & 0x1f;
      execute();
   }

   /**
    * Method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {
      // empty
   }

   unittest
   {
      ubyte[512] datain_buf;
      datain_buf[0x1fe..0x200] = [0x55, 0xaa];

      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto read16 = new Read16(pseudoDev, 512, 0, 1);

      assert(read16.datain[0x1fe..0x200] == [0x55, 0xaa]);
   }
private:

}

