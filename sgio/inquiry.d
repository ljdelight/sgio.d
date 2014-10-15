
module sgio.inquiry;

import std.string : format;

import sgio.SCSICommand;
import sgio.SCSIDevice;
import sgio.utility;
import sgio.exceptions;


enum VPD: int
{
   // SPC3r23 D.7 Page Codes, p445
   SUPPORTED_VPD_PAGES                      = 0x00,
   UNIT_SERIAL_NUMBER                       = 0x80,
   ASCII_IMPLEMENTED_OPERATING_DEFINITION   = 0x82,
   DEVICE_IDENTIFICATION                    = 0x83,
   SOFTWARE_INTERFACE_IDENTIFICATION        = 0x84,
   MANAGEMENT_NETWORK_ADDRESS               = 0x85,
   EXTENDED_INQUIRY_DATA                    = 0x86,
   MODE_PAGE_POLICT                         = 0x87,
   SCSI_PORTS                               = 0x88,
}


class Inquiry_Base : SCSICommand
{
   static const int INQUIRY_COMMAND = 0x12;

public:
   /**
    * Inquiry_Base constructor will initialize the CDB, then execute the Inquiry on the device.
    * Child classes override unmarshall() to extract information from the datain buffer.
    *
    * Params:
    *    dev = The device to send the SCSI command.
    *    pagecode = Pagecode of the SCSI Inquiry (defaults to 0, a std inquiry).
    *    evpn = Enable Vital Product Data is used to send SCSI VPD inquries (defaults to true).
    *    alloclen = Byte length to allocate for the datain buffer.
    */
   this(SCSIDevice dev, ubyte pagecode = 0, bool evpd = true, int alloclen = 96)
   {
      // call super to allocate 0 for dataout buffer, and alloclen for datain buffer
      super(dev, 0, alloclen);
      this.m_pagecode = pagecode;
      this.m_evpd = evpd;

      init_cdb(m_pagecode, alloclen);
      execute();

      // ensure we have a good datain buffer
      if (m_pagecode != datain[1])
      {
         throw new SCSIException(format("Expecting page 0x%02x but datain page is 0x%02x",
                        m_pagecode, datain[1]));
      }

      // read these two fields since all inquiries have it
      m_peripheral_qualifier   = decodeByte(datain, 0, 0xe0);
      m_peripheral_device_type = decodeByte(datain, 0, 0x1f);
   }

   /**
    * Initialize the CDB given the allocation length.
    * Note: The pagecode field isn't needed, but I get strange compiler errors that I didn't
    *       take the time to resolve ("use alias to introduce base class overload set").
    */
   protected void init_cdb(ubyte pagecode, int alloclen)
   {
      // initialize the cdb buffer
      super.init_cdb(INQUIRY_COMMAND);
      if (m_evpd)
      {
         super.cdb[1] |= 0x01;
         super.cdb[2] = m_pagecode;
      }
      super.cdb[3..5] = [(alloclen>>8) & 0xff, alloclen & 0xff];
   }

   /**
    * Abstract method used to unmarshall the datain buffer.
    */
   override abstract protected void unmarshall();

   @property
   {
      bool evpd() { return m_evpd; }
      ubyte pagecode() { return m_pagecode; }
      ubyte peripheral_qualifier() { return m_peripheral_qualifier; }
      ubyte peripheral_device_type() { return m_peripheral_device_type; }
   }

private:
   bool m_evpd;
   ubyte m_pagecode;
   ubyte m_peripheral_qualifier;
   ubyte m_peripheral_device_type;

}

/**
 * Standard Inquiry class to encapsulate the unmarshall'ing of the datain buffer.
 */
class StandardInquiry : Inquiry_Base
{

   /**
    * Constructor for the StandardInquiry; sets opcode to 0x00 and evpd to false.
    * Params:
    *    dev = Device to execute the Standard Inquiry ioctl.
    */
   this(SCSIDevice dev)
   {
      // Standard inquiry is the only inquiry we need to disable the "enable vpd page" field.
      //    The superclass defaults to evpd, so we need to turn it off for std inquiry.
      super(dev, 0x0, false);
   }

   /**
    * Method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {


      rmb      = decodeByte(datain, 1, 0x80);
      version_ = decodeByte(datain, 2);
      normaca  = decodeByte(datain, 3, 0x20);
      hisup    = decodeByte(datain, 3, 0x10);

      response_data_format = decodeByte(datain, 3, 0x0f);
      additional_length = decodeByte(datain, 4);

      sccs     = decodeByte(datain, 5, 0x80);
      acc      = decodeByte(datain, 5, 0x40);
      tpgs     = decodeByte(datain, 5, 0x30);
      threepc  = decodeByte(datain, 5, 0x08);
      protect  = decodeByte(datain, 5, 0x01);

      encserv  = decodeByte(datain, 6, 0x40);
      multip   = decodeByte(datain, 6, 0x10);
      addr16   = decodeByte(datain, 6, 0x01);

      wbus16   = decodeByte(datain, 7, 0x20);
      sync     = decodeByte(datain, 7, 0x10);
      cmdque   = decodeByte(datain, 7, 0x02);

      t10_vendor_identification = cast(string)(datain[8..16]);
      product_identification    = cast(string)(datain[16..32]);
      product_revision_level    = cast(string)(datain[32..36]);

      clocking = decodeByte(datain, 56, 0x0c);
      qas      = decodeByte(datain, 56, 0x02);
      ius      = decodeByte(datain, 56, 0x01);
   }

   ubyte rmb;
   ubyte version_;
   ubyte normaca;
   ubyte hisup;

   ubyte response_data_format;
   ubyte additional_length;

   ubyte sccs;
   ubyte acc;
   ubyte tpgs;
   ubyte threepc;
   ubyte protect;

   ubyte encserv;
   ubyte multip;
   ubyte addr16;

   ubyte wbus16;
   ubyte sync;
   ubyte cmdque;

   public string t10_vendor_identification;
   public string product_identification;
   public string product_revision_level;

   ubyte clocking;
   ubyte qas;
   ubyte ius;

}


/**
 * DeviceIdentificationInquiry class to encapsulate the unmarshall'ing of the datain buffer.
 */
class DeviceIdentificationInquiry : Inquiry_Base
{
   /**
    * Params:
    *    dev = Device to execute the ioctl.
    */
   this(SCSIDevice dev)
   {
      super(dev, VPD.DEVICE_IDENTIFICATION);
   }

   /**
    * Method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {

   }
}


/**
 * SupportedVPDPagesInquiry class to encapsulate the unmarshall'ing of the datain buffer.
 */
class SupportedVPDPagesInquiry : Inquiry_Base
{
public:
   /**
    * Params:
    *    dev = Device to execute the ioctl.
    */
   this(SCSIDevice dev)
   {
      super(dev, VPD.SUPPORTED_VPD_PAGES);
   }

   /**
    * Abstract method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {
      m_page_length = decodeByte(datain, 3);
      m_supported_pages = datain[4..page_length+4];
   }

   @property
   {
      /** Get the page length of the VPD pages buffer. */
      ubyte page_length() { return m_page_length; }

      /** Get the array of supported VPD pages. */
      ubyte[] supported_pages() { return m_supported_pages; }
   }

   unittest
   {
      ubyte[96] datain_buf;
      datain_buf[0] = 0xb5; // peripheral_qualifier 101b (0x5), peripheral_device_type 10101b (0x15)
      datain_buf[1] = VPD.SUPPORTED_VPD_PAGES;
      datain_buf[3] = 0x03; // page_length is 3
      datain_buf[4..8] = cast(ubyte[])([1, 2, 3, -1]); // vpd pages 1,2,3 followed by -1 as invalid

      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto inquiry = new SupportedVPDPagesInquiry(pseudoDev);

      assert(inquiry.pagecode == VPD.SUPPORTED_VPD_PAGES);
      assert(inquiry.peripheral_qualifier == 0x05);
      assert(inquiry.peripheral_device_type == 0x15);
      assert(inquiry.page_length == 3);
      assert(inquiry.supported_pages == [1, 2, 3]);
   }

private:
   ubyte m_page_length;
   ubyte[] m_supported_pages;
}

/**
 * UnitSerialNumberInquiry class to encapsulate the unmarshall'ing of the datain buffer.
 */
class UnitSerialNumberInquiry : Inquiry_Base
{
   /**
    * Params:
    *    dev = Device to execute the ioctl.
    */
   this(SCSIDevice dev)
   {
      super(dev, VPD.UNIT_SERIAL_NUMBER);
   }

   /**
    * Abstract method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {
      m_serial_length = decodeByte(datain, 3);
      m_unit_serial_number = cast(string)(datain[4..m_serial_length+4]);
   }

   @property
   {
      /** Get the lenght of the serial number. This will match the serial number string length. */
      ubyte serial_length() { return m_serial_length; }

      /** Get the unit serial number string. */
      string unit_serial_number() { return m_unit_serial_number; }
   }

   unittest
   {
      const string sn = "theSerialNumber123.;";

      ubyte[96] datain_buf;
      datain_buf[1] = VPD.UNIT_SERIAL_NUMBER;
      datain_buf[3] = sn.length;
      datain_buf[4..4+sn.length] = cast(ubyte[])(sn);

      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto inquiry = new UnitSerialNumberInquiry(pseudoDev);

      assert(inquiry.serial_length == sn.length);
      assert(inquiry.unit_serial_number == sn);
      assert(inquiry.unit_serial_number.length == inquiry.serial_length);
   }

private:
   ubyte m_serial_length;
   string m_unit_serial_number;
}


