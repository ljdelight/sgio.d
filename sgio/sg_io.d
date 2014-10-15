
module sgio.sg_io;

const int SG_IO = 0x2285;
const int SG_DXFER_TO_DEV = -2;
const int SG_DXFER_FROM_DEV = -3;
const int SG_DXFER_TO_FROM_DEV = -4;

const uint SG_INFO_OK_MASK = 1;
const uint SG_INFO_OK = 0;

struct _sg_io_hdr
{
   int interface_id; /* [i] 'S' for SCSI generic (required) */
   int dxfer_direction; /* [i] data transfer direction  */
   ubyte cmd_len; /* [i] SCSI command length ( <= 16 bytes) */
   ubyte mx_sb_len; /* [i] max length to write to sbp */
   ushort iovec_count; /* [i] 0 implies no scatter gather */
   uint dxfer_len; /* [i] byte count of data transfer */
   void * dxferp; /* [i], [*io] points to data transfer memory
                  or scatter gather list */
   ubyte * cmdp; /* [i], [*i] points to command to perform */
   ubyte * sbp; /* [i], [*o] points to sense_buffer memory */
   uint timeout; /* [i] MAX_UINT->no timeout (unit: millisec) */
   uint flags; /* [i] 0 -> default, see SG_FLAG... */
   int pack_id; /* [i->o] unused internally (normally) */
   void * usr_ptr; /* [i->o] unused internally */
   ubyte status; /* [o] scsi status */
   ubyte masked_status;/* [o] shifted, masked scsi status */
   ubyte msg_status; /* [o] messaging level data (optional) */
   ubyte sb_len_wr; /* [o] byte count actually written to sbp */
   ushort host_status; /* [o] errors from host adapter */
   ushort driver_status;/* [o] errors from software driver */
   int resid; /* [o] dxfer_len - actual_transferred */
   uint duration; /* [o] time taken by cmd (unit: millisec) */
   uint info; /* [o] auxiliary information */
} /* 64 bytes long (on i386) */
