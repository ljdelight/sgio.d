
module sgio.SCSIDevice;

import sgio.exceptions;
import std.conv;
import std.bitmanip;
import std.stdio                 : write, writef, writeln, writefln, File;

version (Posix)
{
   import sgio.sg_io;
   import core.sys.posix.sys.ioctl  : ioctl;
   alias int Handle;
}

version (Windows)
{
   import core.sys.windows.windows;
   ubyte SG_INFO_OK = 0;
   alias HANDLE Handle;

   struct SCSI_PASS_THROUGH_DIRECT
   {
      USHORT Length;
      UCHAR ScsiStatus;
      UCHAR PathId;
      UCHAR TargetId;
      UCHAR Lun;
      UCHAR CdbLength;
      UCHAR SenseInfoLength;
      UCHAR DataIn;
      ULONG DataTransferLength;
      ULONG TimeOutValue;
      PVOID DataBuffer;
      ULONG SenseInfoOffset;
      UCHAR[16] Cdb;
   }

   extern (Windows) BOOL DeviceIoControl(
      HANDLE hDevice,              // handle to device
      DWORD dwIoControlCode,       // operation control code
      LPVOID lpInBuffer,           // input data buffer
      DWORD nInBufferSize,         // size of input data buffer
      LPVOID lpOutBuffer,          // output data buffer
      DWORD nOutBufferSize,        // size of output data buffer
      LPDWORD lpBytesReturned,     // byte count
      LPOVERLAPPED lpOverlapped    // overlapped information
   );

   extern (Windows) DWORD GetLastError();

   const uint IOCTL_SCSI_PASS_THROUGH        = 0x4D004;
   const uint IOCTL_SCSI_PASS_THROUGH_DIRECT = 0x4D014;
   const uint SCSI_IOCTL_DATA_OUT          = 0;
   const uint SCSI_IOCTL_DATA_IN           = 1;
   const int  SCSI_IOCTL_DATA_UNSPECIFIED  = 2;
}


class SCSIDevice
{
private:
   Handle m_device;

public:
   /**
    * SCSIDevice ctor to save the device handle of an open device.
    * Params:
    *    device = Handle of opened device to send ioctls.
    */
   this(uint device)
   {
      m_device = cast(Handle)(device);
   }

   /**
    * Execute the native SGIO call on the device.
    *
    * Throws:
    *    IoctlFailException when the ioctl fails.
    *    SCSICheckConditionException when we have sense information.
    */
   void sgio_execute(ubyte[] cdb_buf, ubyte[] dataout_buf, ubyte[] datain_buf, ubyte[] sense_buf)
   {
      version (Windows)
      {
         // TODO(ljdelight): clean up after fixing failed attempts
         const uint SENSE_LENGTH = 196;
         ubyte[512] iobuffer = 0;
         DWORD amountTransferred = -1;
         SCSI_PASS_THROUGH_DIRECT scsiPassThrough = {0};

         // scsiPassThrough.Cdb is always 16 bytes and we only want to copy the first
         // cdb_buf.length bytes from the cdb_buf.
         uint size = cast(uint)(cdb_buf.length);
         scsiPassThrough.Cdb[] = 0;

         writeln("CDB length: ", size);
         scsiPassThrough.Cdb[0..size] = cdb_buf[0..size];
         scsiPassThrough.Length             = SCSI_PASS_THROUGH_DIRECT.sizeof;
         scsiPassThrough.ScsiStatus         = 0x00;
         scsiPassThrough.TimeOutValue       = 0x40;
         scsiPassThrough.CdbLength          = cast(ubyte)(size);
         scsiPassThrough.SenseInfoOffset    = SCSI_PASS_THROUGH_DIRECT.sizeof;
         scsiPassThrough.SenseInfoLength    = SENSE_LENGTH;
         scsiPassThrough.DataIn             = SCSI_IOCTL_DATA_IN;
         scsiPassThrough.DataBuffer         = datain_buf.ptr;

         // This MUST be a multiple of the device's block size!
         scsiPassThrough.DataTransferLength = 512;

         // TODO(ljdelight): dataout needs setup

         writeln("CDB buffer contents:");
         for (int k = 0; k < cdb_buf.length; ++k)
         {
            if ((k > 0) && (0 == (k % 16)))
            {
               writeln();
            }
            else if ((k > 0) && (0 == (k % 8)))
            {
               write(" ");
            }
            {
               writef("%02x ", cdb_buf[k]);
            }
         }

         int status = DeviceIoControl( m_device,
                                       IOCTL_SCSI_PASS_THROUGH_DIRECT,
                                       &scsiPassThrough,
                                       iobuffer.length, //scsiPassThrough.sizeof,
                                       &iobuffer,
                                       iobuffer.length,
                                       &amountTransferred,
                                       null);
         if (status == 0)
         {
            int errorCode = GetLastError();
            LPSTR lastErrorAsString = null;

            FormatMessageA(
               FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_IGNORE_INSERTS,
               null,
               errorCode,
               MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
               cast(LPSTR) &lastErrorAsString,
               0,
               null);

            string exceptionMessage = "ioctl error code is " ~ to!string(errorCode);
            if (lastErrorAsString != null)
            {
               exceptionMessage ~= ". " ~ to!string(lastErrorAsString);
               LocalFree(lastErrorAsString);
               lastErrorAsString = null;
            }
            throw new IoctlFailException(exceptionMessage);
         }
         writeln("\nIOBUFFER contents:");
         for (int k = 0; k < iobuffer.length; ++k)
         {
            if ((k > 0) && (0 == (k % 16)))
            {
               writeln();
            }
            else if ((k > 0) && (0 == (k % 8)))
            {
               write(" ");
            }
            {
               writef("%02x ", iobuffer[k]);
            }
         }
         writeln();

         // TODO sense_buf needs to be filled with data from scsiPassThrough... i think...
         if (scsiPassThrough.ScsiStatus != SG_INFO_OK)
         {
            throw new SCSICheckConditionException(sense_buf);
         }

         writeln("ioctl return ", status);
         // TODO throw exception if scsi status is bad
         writeln("scsi status ", scsiPassThrough.ScsiStatus);
         writeln("amount transferred ", amountTransferred);
      }

      version (Posix)
      {
         _sg_io_hdr io_hdr;

         io_hdr.interface_id = 'S';
         io_hdr.dxfer_direction = 0;
         io_hdr.cmdp = cdb_buf.ptr;
         io_hdr.cmd_len = cast(ubyte)(cdb_buf.length);
         io_hdr.sbp = sense_buf.ptr;
         io_hdr.mx_sb_len = cast(ubyte)(sense_buf.length);

         if (dataout_buf !is null)
         {
            io_hdr.dxfer_direction = SG_DXFER_TO_DEV;
            io_hdr.dxferp = dataout_buf.ptr;
            io_hdr.dxfer_len = cast(uint)(dataout_buf.length);
         }
         if (datain_buf !is null)
         {
            io_hdr.dxfer_direction = SG_DXFER_FROM_DEV;
            io_hdr.dxferp = datain_buf.ptr;
            io_hdr.dxfer_len = cast(uint)(datain_buf.length);
         }
         // TODO(ljdelight): setup for SG_TO_FROM_DEV and test


         int res = ioctl(m_device, SG_IO, &io_hdr);

         if (res < 0)
         {
            throw new IoctlFailException("ioctl failed, failure code is " ~ to!string(res));
         }
         if ((io_hdr.info & SG_INFO_OK_MASK) != SG_INFO_OK)
         {
            throw new SCSICheckConditionException(sense_buf);
         }
      }
   }
}

/**
 * Class to hold the device handle, block size, and total blocks in a single place. This sends
 * a ReadCapacity(10) command to the device to collect the values; to avoid sending the command,
 * override the defaults in the constructor.
 */
class SCSIDeviceBS : SCSIDevice
{
public:
   /**
    * Params:
    *    device = Handle of opened device to send ioctls.
    *    blocksize = Read totalLBAs argument.
    *    totalLBAs = Set both blocksize and totalLBAs args to non-default values to avoid sending a ReadCapacity
    *                to the device. Usually you'll only want to override these if you are VERY SURE
    *                of the values for the device (say, it was already queried).
    */
   this(uint device, int blocksize=-1, ulong totalLBAs=-1)
   {
      super(device);
      if (blocksize == -1 || totalLBAs == -1)
      {
         import sgio.read;
         auto rc10 = new ReadCapacity10(this);
         m_blocksize = rc10.blocksize;
         m_total_lba = rc10.total_lba;
      }
      else
      {
         m_blocksize = blocksize;
         m_total_lba = totalLBAs;
      }
   }

   @property
   {
      int blocksize() { return m_blocksize; }
      ulong total_lba() { return m_total_lba; }
   }

private:
   int m_blocksize;
   ulong m_total_lba;
}


version (unittest)
{
   /**
    * This is a simple class used to simulate the communication with a device by using
    * known buffers. Pass this device to a SCSICommand, and during the sgio_execute()
    * it sets the response buffers with the data instead of executing a real ioctl.
    *
    * Note:
    *    To test a scsi command test cases will pass the constructor applicable buffers (dataout,
    *    datain, sense) and then pass the device to a SCSICommand. The unmarshall will work on
    *    those buffers.
    */
   class FakeSCSIDevice : SCSIDeviceBS
   {
   public:
      /**
       * Construct a FakeSCSIDevice where the ioctl will return the arg buffers.
       *
       * Params:
       *    dataout_buf = Pseudo-dataout buffer
       *    datain_buf = Pseudo-datain buffer
       *    sense_buf = Pseudo-sense buffer
       */
      this(ubyte[] dataout_buf = null, ubyte[] datain_buf = null, ubyte[] sense_buf = null)
      {
         super(-1, 512, 10000);
         m_dataout_buf = dataout_buf.dup;
         m_datain_buf = datain_buf.dup;
         m_sense_buf = sense_buf.dup;
      }

      /**
       * Overloaded sgio_execute to set the argument buffers to their expected values.
       */
      override void sgio_execute(ubyte[] cdb_buf, ubyte[] dataout_buf,
                                    ubyte[] datain_buf, ubyte[] sense_buf)
      {
         if (m_dataout_buf)
            dataout_buf[] = m_dataout_buf;
         if (m_datain_buf)
            datain_buf[] = m_datain_buf;
         if (m_sense_buf)
            sense_buf[] = m_sense_buf;
      }

   private:
      ubyte[] m_dataout_buf;
      ubyte[] m_datain_buf;
      ubyte[] m_sense_buf;
   }
}
