
module sgio.exceptions;
import sgio.utility;
import std.string : format;

/**
 * SCSIException is the base class for all scsi exceptions.
 */
class SCSIException : Exception
{
   this(string message)
   {
      super(message);
   }
}

/**
 * IoctlFailException is used when the ioctl to the device fails
 */
class IoctlFailException : SCSIException
{
   this(string message)
   {
      super(message);
   }
}

/**
 * SCSICheckConditionException is used on a check condition
 */
class SCSICheckConditionException : SCSIException
{
   /**
    * Params:
    *    sense = Sense buffer that is unmarshalled
    */
   this(ubyte[] sense)
   {
      // SPC 4.5.3 Fixed format sense data
      m_valid         = decodeByte(sense, 0, 0x80);
      m_response_code = decodeByte(sense, 0, 0x7f);

      if (m_response_code != SenseFormat.CURRENT_INFO_FIXED &&
          m_response_code != SenseFormat.DEFERRED_ERR_FIXED)
      {
         throw new SCSIException(format("SCSICheckConditionException was thrown but"
            ~ " response_code (0x%02x) doesn't imply fixed-format sense."
            ~ " Raising SCSIException instead", m_response_code));
      }

      m_filemark  = decodeByte(sense, 2, 0x80);
      m_eom       = decodeByte(sense, 2, 0x40);
      m_ili       = decodeByte(sense, 2, 0x20);
      m_sdat_ovfl = decodeByte(sense, 2, 0x10);
      m_sense_key = decodeByte(sense, 2, 0x0f);
      m_information                  = sense[3..7];
      m_additional_sense_length      = sense[7];
      m_command_specific_information = sense[8..12];
      m_additional_sense_code        = sense[12];
      m_additional_sense_code_qualifier = sense[13];
      m_field_replaceable_unit_code  = sense[14];
      m_ascq = m_additional_sense_code << 8 + m_additional_sense_code_qualifier;

      string sensekey_description = ((m_sense_key < SenseKeyString.length) ?
                                       SenseKeyString[m_sense_key] : "");
      super(format("Check condition! SenseKey=0x%02x (%s) ASC+Q=0x%04x",
         m_sense_key, sensekey_description, m_ascq));
   }

   enum SenseFormat: int
   {
      CURRENT_INFO_FIXED = 0x70,
      DEFERRED_ERR_FIXED = 0x71,
      CURRENT_INFO_DESCR = 0x72,
      DEFERRED_ERR_DESCR = 0x73
   }

   static const string[] SenseKeyString = [
      "no sense", "recovered error", "not ready", "medium error", "hardware error",
      "illegal request", "unit attention", "data protect", "blank check", "vendor specific",
      "copy aborted", "aborted command", "", "volume overflow", "miscompare", "completed"];

   @property
   {
      ubyte valid() { return m_valid; }
      ubyte response_code() { return m_response_code; }
      ubyte filemark() { return m_filemark; }
      ubyte eom() { return m_eom; }
      ubyte ili() { return m_ili; }
      ubyte sdat_ovfl() { return m_sdat_ovfl; }
      ubyte sense_key() { return m_sense_key; }
      ubyte[4] information() { return m_information; }
      ubyte additional_sense_length() { return m_additional_sense_length; }
      ubyte[4] command_specific_information() { return m_command_specific_information; }
      ubyte additional_sense_code() { return m_additional_sense_code; }
      ubyte additional_sense_code_qualifier() { return m_additional_sense_code_qualifier; }
      ubyte field_replaceable_unit_code() { return m_field_replaceable_unit_code; }
      int ascq() { return m_ascq; }
   }

private:
   ubyte m_valid;
   ubyte m_response_code;
   ubyte m_filemark;
   ubyte m_eom;
   ubyte m_ili;
   ubyte m_sdat_ovfl;
   ubyte m_sense_key;
   ubyte[4] m_information;
   ubyte m_additional_sense_length;
   ubyte[4] m_command_specific_information;
   ubyte m_additional_sense_code;
   ubyte m_additional_sense_code_qualifier;
   ubyte m_field_replaceable_unit_code;
   int m_ascq;
}

/**
 * BadOpCodeException is used when the OPCODE is invalid
 */
class BadOpCodeException : SCSIException
{
   this(string message)
   {
      super(message);
   }
}
