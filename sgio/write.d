
module sgio.write;

import std.bitmanip;

import sgio.SCSICommand;
import sgio.SCSIDevice;
import sgio.exceptions;

/**
 * Simple helper function to create the second byte of the CDB.
 * For a description of the arguments, see the Write(XX) commands.
 */
private ubyte writeXXHelperCreateByte(ubyte wrprotect, ubyte dpo, ubyte fua)
{
   ubyte res = 0;
   res |= (wrprotect << 5) & 0xe0;
   res |= dpo ? 0x10 : 0;
   res |= fua ? 0x80 : 0;

   return res;
}

/**
 * Class to send a Write(10) command to a scsi device.
 * NOTE: SBC3r36 has this note: Migration from the WRITE (10) command to the WRITE (16) command
 *    is recommended for all implementations.
 */
class Write10 : SCSICommand
{
public:
   /**
    * Params:
    *    dev = Device to send the scsi command
    *    dataout = Data to write to the device
    *    lba = Starting LBA of the write
    *    transfer_length = Number of blocks to write
    *    group_num =
    *    wrprotect = Write protection information
    *    dpo = Disable page out bit
    *    fua = Force unit access
    */
   this(SCSIDeviceBS dev, ubyte[] dataout, uint lba, ushort transfer_length,
         ubyte group_num=0, ubyte wrprotect=0, ubyte dpo=0, ubyte fua=0)
   {
      assert(transfer_length*dev.blocksize <= dataout.length);
      super(dev, OPCODE.WRITE_10, 0, 0);
      m_dataout = dataout;

      m_cdb[1] = writeXXHelperCreateByte(wrprotect, dpo, fua);
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
}


/**
 * Class to send a Write(12) command to a scsi device.
 * NOTE: SBC3r36 has this note: Migration from the WRITE (12) command to the WRITE (16) command
 *    is recommended for all implementations.
 */
class Write12 : SCSICommand
{
public:
   /**
    * Params:
    *    dev = Device to send the scsi command
    *    dataout = Data to write to the device
    *    lba = Starting LBA of the write
    *    transfer_length = Number of blocks to write
    *    group_num =
    *    wrprotect = Write protection information
    *    dpo = Disable page out bit
    *    fua = Force unit access
    */
   this(SCSIDeviceBS dev, ubyte[] dataout, uint lba, uint transfer_length,
         ubyte group_num=0, ubyte wrprotect=0, ubyte dpo=0, ubyte fua=0)
   {
      assert(transfer_length*dev.blocksize <= dataout.length);
      super(dev, OPCODE.WRITE_12, 0, 0);
      m_dataout = dataout;

      m_cdb[1] = writeXXHelperCreateByte(wrprotect, dpo, fua);
      m_cdb[2..6] = nativeToBigEndian!uint(lba);
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
}


/**
 * Class to send a Write(16) command to a scsi device.
 */
class Write16 : SCSICommand
{
public:
   /**
    * Params:
    *    dev = Device to send the scsi command
    *    dataout = Data to write to the device
    *    lba = Starting LBA of the write
    *    transfer_length = Number of blocks to write
    *    group_num =
    *    wrprotect = Write protection information
    *    dpo = Disable page out bit
    *    fua = Force unit access
    */
   this(SCSIDeviceBS dev, ubyte[] dataout, ulong lba, uint transfer_length,
         ubyte group_num=0, ubyte wrprotect=0, ubyte dpo=0, ubyte fua=0)
   {
      assert(transfer_length*dev.blocksize <= dataout.length);
      assert(dataout.length % dev.blocksize == 0);
      super(dev, OPCODE.WRITE_16, 0, 0);
      m_dataout = dataout;

      m_cdb[1] = writeXXHelperCreateByte(wrprotect, dpo, fua);
      m_cdb[2..10] = nativeToBigEndian!ulong(lba);
      m_cdb[10..14] = nativeToBigEndian!uint(transfer_length);
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
}
