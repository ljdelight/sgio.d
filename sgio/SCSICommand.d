
module sgio.SCSICommand;

import std.string : format;
import sgio.SCSIDevice;
import sgio.exceptions;

abstract class SCSICommand
{
private:
   ubyte[] m_sense;
   ubyte[] m_dataout;
   ubyte[] m_datain;
   ubyte[] m_cdb;
   SCSIDevice m_device;

public:
   @property
   {
      /** Get a reference to the sense buffer */
      ubyte[] sense() { return m_sense; }

      /** Get a reference to the dataout buffer (possibly null) */
      ubyte[] dataout() { return m_dataout; }

      /** Get a reference to the datain buffer (possibly null) */
      ubyte[] datain() { return m_datain; }

      /** Get a reference ot the CDB */
      ubyte[] cdb() { return m_cdb; }

      /** Get the SCSIDevice */
      SCSIDevice device() { return m_device; }
   }

   /**
    * The constructor will allocate sense, dataout, and datain buffers as necessary
    * Params:
    *    dev = The device to send the SCSI command.
    *    dataout_alloclen = Byte length used for allocation of the dataout buffer.
    *    datain_alloclen  = Byte length used for allocation of the datain buffer.
    */
   this(SCSIDevice dev, int dataout_alloclen, int datain_alloclen)
   in
   {
      assert(dev !is null);
      assert(dataout_alloclen >= 0);
      assert(datain_alloclen >= 0);
   }
   body
   {
      m_device = dev;
      m_sense = new ubyte[32];
      m_dataout = ((dataout_alloclen > 0) ? new ubyte[dataout_alloclen] : null);
      m_datain = ((datain_alloclen > 0) ? new ubyte[datain_alloclen] : null);
      m_cdb = null;
   }

   ~this()
   {
      // TODO(blucas): memory allocations are strange in D. The docs were confusing and it seems
      //     new/delete are soon deprecated? Need to read more or ask a question.
      destroy(m_sense);
      if (m_dataout != null)
      {
         destroy(m_dataout);
      }
      if (m_datain != null)
      {
         destroy(m_datain);
      }
   }

   /**
    * Allocate the CDB and set the opcode field. Opcode is used to determine cdb length.
    *
    * Params:
    *    opcode = SCSI opcode that we send to the device.
    * Throws:
    *    BadOpCodeException when the opcode is out of the valid range.
    */
   void init_cdb(ubyte opcode)
   {
      if (m_cdb != null)
      {
         // TODO(ljdelight): I'm not sure we need this if. Depends on the design, maybe remove it.
         destroy(m_cdb);
         m_cdb = null;
      }

      if (opcode < 0x20)
      {
         m_cdb = new ubyte[6];
      }
      else if (opcode < 0x60)
      {
         m_cdb = new ubyte[10];
      }
      else if (opcode < 0x80)
      {
         throw new BadOpCodeException(format("Opcode cannot be in range [0x60,0x80) but is 0x%02x",
                        opcode));
      }
      else if (opcode < 0xa0)
      {
         m_cdb = new ubyte[16];
      }
      else if (opcode < 0xc0)
      {
         m_cdb = new ubyte[12];
      }
      else
      {
         throw new BadOpCodeException("Opcode cannot exceed 0xc0");
      }

      m_cdb[0] = opcode;
   }

   /**
    * Execute the SCSI command on the device (using device.sgio_execute), then
    * unmarshalls the datain buffer with a call to unmarshall().
    *
    * Note: The init_cdb method must be called to allocate the CDB before calling execute().
    *       Since inquiry, write, etc CDBs have different required arguments, this base class
    *       cannot easily encapsulate the initialization of the CDB. That work is left to the
    *       derived class.
    */
   void execute()
   {
      m_device.sgio_execute(m_cdb, m_dataout, m_datain, m_sense);
      unmarshall();
   }

   /**
    * Abstract method used to unmarshall the datain buffer.
    */
   abstract protected void unmarshall();

}
