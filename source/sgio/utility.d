
module sgio.utility;

import std.string : format, strip;
import std.conv : to;
import std.ascii : isPrintable, toLower;

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
 * Simple helper function to create the second byte of the CDB for read(10), read(12), and read(16).
 * For a description of the arguments, see the Read(XX) commands.
 */
protected ubyte readXXHelperCreateByte(ubyte rdprotect, ubyte dpo, ubyte fua, ubyte rarc)
{
   ubyte res = 0;
   res |= (rdprotect << 5) & 0xe0;
   res |= dpo  ? 0x10 : 0;
   res |= fua  ? 0x80 : 0;
   res |= rarc ? 0x04 : 0;

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


string bufferToHexDump(const(ubyte)[] buff, ulong length)
{
   string prettyBuffer = "";

   string lhs = format("%06x", 0) ~ ":";
   string rhs = "|";

   // Loop over the buffer using a 1-based count
   for (int idx = 1; idx <= length; idx++)
   {
      // From the buffer create the hex and char version.
      string byteAsHex = format("%02x", buff[idx-1]);
      char byteAsChar = to!char(isPrintable(buff[idx-1]) ? buff[idx-1] : '.');

      lhs ~= " " ~ byteAsHex;
      rhs ~= byteAsChar;

      if (idx > 0 && idx % 16 == 0)
      {
         prettyBuffer ~= lhs ~ "  " ~ rhs ~ "|\n";
         lhs = format("%06x", idx) ~ ":";
         rhs = "|";
      } else if (idx > 0 && idx % 8 == 0)
      {
         lhs ~= " ";
      }
   }

   // make an output if the buffer is less than 16 bytes
   if (prettyBuffer == "")
   {
      prettyBuffer = lhs ~ "  " ~ rhs ~ "|\n";
   }

   return prettyBuffer;
}


unittest
{
   import std.stdio;
   ubyte[] bufferHello = [0x10, 0xFE, 'h', 'e', 'L', 'L', 'o', '.'];
   assert("000000: 10 fe 68 65 4c 4c 6f 2e   |..heLLo.|\n"
      == bufferToHexDump(bufferHello, bufferHello.length));

   ubyte[] bufferTwoLines = [
      0x00, 0x19, 'T', 'h', 'i', 's', ' ', 'i',
      0x10, 0xFE, 's', ' ', 'T', 'W', 'O', ' ',
      0x10, 0xFE, 'L', 'i', 'n', 'e', 's', '.',
      0x10, 0xFE, ' ', 'P', 'a', 's', 's', '!'];
   assert(
      "000000: 00 19 54 68 69 73 20 69  10 fe 73 20 54 57 4f 20  |..This i..s TWO |\n" ~
      "000010: 10 fe 4c 69 6e 65 73 2e  10 fe 20 50 61 73 73 21  |..Lines... Pass!|\n"
      == bufferToHexDump(bufferTwoLines, bufferTwoLines.length));
}

