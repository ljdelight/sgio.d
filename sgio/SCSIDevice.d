
module sgio.SCSIDevice;

import sgio.exceptions;
import std.conv;

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
      UCHAR Cdb[16];
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
    * Args:
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
         // TODO(ljdelight): this doesn't f*cking work on windoze. i always get 44 byte response.
         //       Probably more to think about for windows anyway. Like use SPTDWithBuffer?
         // TODO(ljdelight): clean up after fixing failed attempts
         const uint SENSE_LENGTH = 196;
         ubyte[512] iobuffer = 0;
         DWORD amountTransferred = -1;
         SCSI_PASS_THROUGH_DIRECT scsiPassThrough = {0};

         scsiPassThrough.Cdb[] = 0;
         uint size = cast(uint)((cdb_buf.length <= scsiPassThrough.Cdb.length ?
                           cdb_buf.length : scsiPassThrough.Cdb.length));
         writeln("CDB SIZE", size);
         scsiPassThrough.Cdb[0..size] = cdb_buf[0..size];
         scsiPassThrough.Length             = SCSI_PASS_THROUGH_DIRECT.sizeof;
         scsiPassThrough.ScsiStatus         = 0x00;
         scsiPassThrough.TimeOutValue       = 0x40;
         scsiPassThrough.CdbLength          = cast(ubyte)(size);
         scsiPassThrough.SenseInfoOffset    = SCSI_PASS_THROUGH_DIRECT.sizeof;
         scsiPassThrough.SenseInfoLength    = SENSE_LENGTH;
         scsiPassThrough.DataIn             = SCSI_IOCTL_DATA_IN;
         scsiPassThrough.DataBuffer         = datain_buf.ptr;
         scsiPassThrough.DataTransferLength = (cdb_buf[3] << 8) | cdb_buf[4];
         // TODO(ljdelight): dataout needs setup

         writeln("THE CDB:");
         for (int k = 0; k < cdb_buf.length; ++k)
         {
            if ((k > 0) && (0 == (k % 8)))
            {
               writeln();
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
         writeln("THE IOBUFFER:");
         for (int k = 0; k < iobuffer.length; ++k)
         {
            if ((k > 0) && (0 == (k % 16)))
            {
               writeln();
            }
            {
               writef("%02x ", iobuffer[k]);
            }
         }

         if (status == 0)
         {
            writeln("ERROR from DeviceIoControl");
            writeln("last error ", GetLastError());
         }
         writeln("ioctl return ", status);
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
   class FakeSCSIDevice : SCSIDevice
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
         super(-1);
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
