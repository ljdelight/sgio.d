
module sgio.read.read;

import std.bitmanip;

import sgio.utility;
import sgio.SCSICommand;
import sgio.SCSIDevice;

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
    *    lba = Starting LBA of the read
    *    transfer_length = Number of blocks to read
    *    group_num =
    *    rdprotect = Read protection information
    *    dpo = Disable page out bit
    *    fua = Force unit access
    *    rarc = Rebuild assist recovery control
    */
   this(SCSIDeviceBS dev, uint lba, ushort transfer_length,
         ubyte group_num=0, ubyte rdprotect=0, ubyte dpo=0, ubyte fua=0, ubyte rarc=0)
   {
      super(dev, OPCODE.READ_10, 0, dev.blocksize*transfer_length);

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
      auto read10 = new Read10(pseudoDev, 0, 1);

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
    *    lba = Starting LBA of the read
    *    transfer_length = Number of blocks to read
    *    group_num =
    *    rdprotect = Read protection information
    *    dpo = Disable page out bit
    *    fua = Force unit access
    *    rarc = Rebuild assist recovery control
    */
   this(SCSIDeviceBS dev, uint lba, uint transfer_length,
         ubyte group_num=0, ubyte rdprotect=0, ubyte dpo=0, ubyte fua=0, ubyte rarc=0)
   {
      super(dev, OPCODE.READ_12, 0, dev.blocksize*transfer_length);

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
      auto read12 = new Read12(pseudoDev, 0, 1);

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
    *    lba = Starting LBA of the read
    *    transfer_length = Number of blocks to read
    *    group_num =
    *    rdprotect = Read protection information
    *    dpo = Disable page out bit
    *    fua = Force unit access
    *    rarc = Rebuild assist recovery control
    */
   this(SCSIDeviceBS dev, ulong lba, uint transfer_length,
         ubyte group_num=0, ubyte rdprotect=0, ubyte dpo=0, ubyte fua=0, ubyte rarc=0)
   {
      super(dev, OPCODE.READ_16, 0, dev.blocksize*transfer_length);

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
      auto read16 = new Read16(pseudoDev, 0, 1);

      assert(read16.datain[0x1fe..0x200] == [0x55, 0xaa]);
   }
private:

}

