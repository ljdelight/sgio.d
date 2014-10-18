
module sgio.utility;

import std.string : format, strip;
import std.xml : isChar;
import std.conv;

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

/**
 * Get a string from buffer where the string spans [offset_start, offset_end).
 * Params:
 *    buffer = Buffer with an ASCII string to obtain.
 *    offset_start = Beginning byte offset within the buffer where the string starts.
 *    offset_end = Ending byte offset which is not included in the string.
 */
string bufferGetString(ubyte[] buffer, ulong offset_start, ulong offset_end)
in
{
   assert(buffer != null);
   assert(offset_start < offset_end);
   assert(offset_end <= buffer.length);
}
body
{
   ulong bufflen = offset_end - offset_start;

   // add one to the lenth for null-termination
   ubyte[] temp = new ubyte[bufflen+1];
   temp[0..bufflen] = buffer[offset_start..offset_end];
   temp[bufflen] = '\0';

   return strip(to!string(cast(const char*) temp.ptr));
}

unittest
{
   ubyte[] no_null = [' ', 'A', 'B', 'C', ' '];
   assert("ABC" == bufferGetString(no_null, 0, no_null.length));
   assert("ABC" == bufferGetString(no_null, 1, no_null.length-1));
   assert("A" == bufferGetString(no_null, 1, 2));
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