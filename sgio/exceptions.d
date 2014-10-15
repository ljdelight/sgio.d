
module sgio.exceptions;

import std.string : format;

class SCSIException : Exception
{
   this(string message)
   {
      super(message);
   }
}

class IoctlFailException : SCSIException
{
   this(string message)
   {
      super(message);
   }
}

class SCSICheckConditionException : SCSIException
{
   static int SENSE_FORMAT_CURRENT_FIXED = 0x70;

   ubyte valid;
   ubyte response_code;
   ubyte filemark;
   ubyte eom;
   ubyte ili;
   ubyte sdat_ovfl;
   ubyte sense_key;
   ubyte[4] information;
   ubyte additional_sense_length;
   ubyte[4] command_specific_information;
   ubyte additional_sense_code;
   ubyte additional_sense_code_qualifier;
   ubyte field_replaceable_unit_code;
   int ascq;

   this(ubyte[] sense)
   {
      valid = sense[0] & 0x80;
      response_code = sense[0] & 0x7f;

      if (response_code == SENSE_FORMAT_CURRENT_FIXED)
      {
         filemark = sense[2] & 0x80;
         eom = sense[2] & 0x40;
         ili = sense[2] & 0x20;
         sdat_ovfl = sense[2] & 0x10;
         sense_key = sense[2] & 0x0f;
         information = sense[3..7];
         additional_sense_length = sense[7];
         command_specific_information = sense[8..12];
         additional_sense_code = sense[12];
         additional_sense_code_qualifier = sense[13];
         field_replaceable_unit_code = sense[14];
      }
      ascq = additional_sense_code << 8 + additional_sense_code_qualifier;

      super(format("Check condition raised. ASC+Q=0x%04x", ascq));
   }
}

class BadOpCodeException : SCSIException
{
   this(string message)
   {
      super(message);
   }
}
