
module sgio.utility;

import std.string : format;
import std.xml : isChar;

/**
 * Decode the byte in the buffer given the offset and bitmask.
 *    We find the byte, '&' with the mask, then right-shift to get the final result.
 * Params:
 *    buffer = The buffer with the byte to decode.
 *    offset = Byte offset in the the buffer.
 *    mask   = Bitmask used to decode the byte.
 */
ubyte decodeByte(ubyte[] buffer, int offset, ubyte mask = 0xff)
in
{
   assert(buffer != null);
   assert(offset >= 0 && offset < buffer.length);
}
body
{
   ubyte res = buffer[offset] & mask;
   while (! (mask & 0x01))
   {
      res >>= 1;
      mask >>= 1;
   }
   return res;
}


string writeBuffer(ubyte[] buff, ulong length)
{
   string strBuf = "";

   for (int idx = 0; idx < length; ++idx)
   {
      if ((idx > 0) && (0 == (idx % 8)))
      {
         strBuf ~= "\n";
      }
      // breaks output of non-chars in char range, but who cares in this code
      //if (isChar(buff[idx]))
      //{
      //   strBuf ~= " " ~ cast(char)(buff[idx]) ~ " ";
      //}
      //else
      {
         strBuf ~= format("%02x ", buff[idx]);
      }
   }
   strBuf ~= "\n";

   return strBuf;
}