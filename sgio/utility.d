
module sgio.utility;

import std.string : format, strip;
import std.xml : isChar;

/**
 * Decode the byte in the buffer given the offset and bitmask.
 *    We find the byte, '&' with the mask, then right-shift to get the final result.
 * Params:
 *    buffer = The buffer with the byte to decode.
 *    offset = Byte offset in the the buffer.
 *    mask   = Bitmask used to decode the byte.
 */
ubyte decodeByte(const(ubyte)[] buffer, int offset, ubyte mask = 0xff)
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
 * Get a string from buffer where the string spans the length of the buffer. The span
 * does not need to be null-terminated.
 * Params:
 *    buffer       = Buffer with an ASCII string to obtain.
 */
string bufferGetString(const(ubyte)[] buffer)
{
   import std.conv : to;

   if (buffer.length == 0)
   {
      return null;
   }
   if (buffer[$-1] == '\0')
   {
      return strip(to!string(cast(char*)buffer.ptr));
   }

   // add one to the lenth for null-termination
   auto temp = new ubyte[buffer.length+1];
   temp[0..$-1] = buffer[];

   return strip(to!string(cast(char*) temp.ptr));
}

unittest
{
   ubyte[] no_null = [' ', 'A', 'B', 'C', ' '];
   assert("ABC" == bufferGetString(no_null[0..no_null.length]));
   assert("B" == bufferGetString(no_null[2..3]));

   immutable ubyte[] no_nullImmut = [' ', 'A', 'B', 'C', ' '];
   assert("ABC" == bufferGetString(no_nullImmut[1..no_nullImmut.length-1]));

   ubyte[] null_term = [' ', 'L', 'o', 'L', '\0'];
   assert("LoL" == bufferGetString(null_term[0..null_term.length]));
}

string writeBuffer(const(ubyte)[] buff, ulong length)
{
   string strBuf = "";

   for (int idx = 0; idx < length; ++idx)
   {
      if ((idx > 0) && (0 == (idx % 16)))
      {
         strBuf ~= "\n";
      }
      else if ((idx > 0) && (0 == (idx % 8)))
      {
         strBuf ~= " ";
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
