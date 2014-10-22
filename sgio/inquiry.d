
module sgio.inquiry;

import std.string : strip, format;
import std.conv;
import std.bitmanip;

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
      if (evpd && m_pagecode != datain[1])
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
public:
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
      m_rmb      = decodeByte(datain, 1, 0x80);
      m_version  = decodeByte(datain, 2);
      m_normaca  = decodeByte(datain, 3, 0x20);
      m_hisup    = decodeByte(datain, 3, 0x10);

      m_response_data_format = decodeByte(datain, 3, 0x0f);
      m_additional_length    = decodeByte(datain, 4);

      m_sccs     = decodeByte(datain, 5, 0x80);
      m_acc      = decodeByte(datain, 5, 0x40);
      m_tpgs     = decodeByte(datain, 5, 0x30);
      m_threepc  = decodeByte(datain, 5, 0x08);
      m_protect  = decodeByte(datain, 5, 0x01);

      m_bque     = decodeByte(datain, 6, 0x80);
      m_encserv  = decodeByte(datain, 6, 0x40);
      m_multip   = decodeByte(datain, 6, 0x10);
      m_mchngr   = decodeByte(datain, 6, 0x08);
      m_addr16   = decodeByte(datain, 6, 0x01);

      m_wbus16   = decodeByte(datain, 7, 0x20);
      m_sync     = decodeByte(datain, 7, 0x10);
      m_cmdque   = decodeByte(datain, 7, 0x02);

      m_t10_vendor_identification = bufferGetString(datain[ 8..16]);
      m_product_identification    = bufferGetString(datain[16..32]);
      m_product_revision_level    = bufferGetString(datain[32..36]);

      m_clocking = decodeByte(datain, 56, 0x0c);
      m_qas      = decodeByte(datain, 56, 0x02);
      m_ius      = decodeByte(datain, 56, 0x01);
   }

   @property
   {
      ubyte rmb() { return m_rmb; }
      ubyte versionField() { return m_version; }
      ubyte normaca() { return m_normaca; }
      ubyte hisup() { return m_hisup; }

      ubyte response_data_format() { return m_response_data_format; }
      ubyte additional_length() { return m_additional_length; }

      ubyte sccs() { return m_sccs; }
      ubyte acc() { return m_acc; }
      ubyte tpgs() { return m_tpgs; }
      ubyte threepc() { return m_threepc; }
      ubyte protect() { return m_protect; }

      ubyte bque() { return m_bque; }
      ubyte encserv() { return m_encserv; }
      ubyte multip() { return m_multip; }
      ubyte mchngr() { return m_mchngr; }
      ubyte addr16() { return m_addr16; }
      ubyte wbus16() { return m_wbus16; }

      ubyte sync() { return m_sync; }
      ubyte cmdque() { return m_cmdque; }
      string t10_vendor_identification() { return m_t10_vendor_identification; }
      string product_identification() { return m_product_identification; }
      string product_revision_level() { return m_product_revision_level; }

      ubyte clocking() { return m_clocking; }
      ubyte qas() { return m_qas; }
      ubyte ius() { return m_ius; }
   }

   unittest
   {
      const string T10_VENDOR = " ATA! ";
      const string PRODUCT_IDENT = "  product-ASDFE ";
      const string REVISION_LEVEL = " 0.2";

      ubyte[96] datain_buf;
      datain_buf[1] = 0x80; // rmb = 1
      datain_buf[2] = 0x05; // version spc-3
      datain_buf[3] = 0x39; // normaca=1, hisup=1, rdf=1001b
      datain_buf[4] = 0x10; // additional length = 16
      datain_buf[5] = 0xe9; // sccs=1, acc=1, tpgs=2, 3pc=1, protect=1
      datain_buf[6] = 0xe9; // bque=1, encServ=1, vs=1, multip=0, mchngr=1, addr16=1
      datain_buf[7] = 0x32; // wbus16=1, sync=1, cmdque=1
      datain_buf[8..8+T10_VENDOR.length] = cast(ubyte[])(T10_VENDOR);
      datain_buf[16..16+PRODUCT_IDENT.length] = cast(ubyte[])(PRODUCT_IDENT);
      datain_buf[32..32+REVISION_LEVEL.length] = cast(ubyte[]) REVISION_LEVEL;
      datain_buf[56] = 0x0b; // clocking=2, qas=1, ius=1
      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto inquiry = new StandardInquiry(pseudoDev);

      assert(inquiry.rmb == 1);
      assert(inquiry.versionField == 5);
      assert(inquiry.normaca == 1);
      assert(inquiry.hisup == 1);
      assert(inquiry.response_data_format == 9);
      assert(inquiry.additional_length == 16);
      assert(inquiry.sccs == 1);
      assert(inquiry.acc == 1);
      assert(inquiry.tpgs == 2);
      assert(inquiry.threepc == 1);
      assert(inquiry.protect == 1);

      assert(inquiry.bque == 1);
      assert(inquiry.encserv == 1);
      assert(inquiry.multip == 0);
      assert(inquiry.mchngr == 1);

      assert(inquiry.addr16 == 1);
      assert(inquiry.wbus16 == 1);
      assert(inquiry.sync == 1);
      assert(inquiry.cmdque == 1);
      assert(inquiry.t10_vendor_identification == strip(T10_VENDOR));
      assert(inquiry.product_identification == strip(PRODUCT_IDENT));
      assert(inquiry.product_revision_level == strip(REVISION_LEVEL));

      assert(inquiry.clocking == 2);
      assert(inquiry.qas == 1);
      assert(inquiry.ius == 1);
   }

private:

   ubyte m_rmb;
   ubyte m_version;
   ubyte m_normaca;
   ubyte m_hisup;

   ubyte m_response_data_format;
   ubyte m_additional_length;

   ubyte m_sccs;
   ubyte m_acc;
   ubyte m_tpgs;
   ubyte m_threepc;
   ubyte m_protect;

   ubyte m_bque;
   ubyte m_encserv;
   ubyte m_multip;
   ubyte m_mchngr;
   ubyte m_addr16;

   ubyte m_wbus16;
   ubyte m_sync;
   ubyte m_cmdque;

   string m_t10_vendor_identification;
   string m_product_identification;
   string m_product_revision_level;

   ubyte m_clocking;
   ubyte m_qas;
   ubyte m_ius;

}


/**
 * DeviceIdentificationInquiry class to encapsulate the unmarshall'ing of the datain buffer.
 */
class DeviceIdentificationInquiry : Inquiry_Base
{
   import std.container : make, Array;

   /**
    * Params:
    *    dev = Device to execute the ioctl.
    */
   this(SCSIDevice dev)
   {
      super(dev, VPD.DEVICE_IDENTIFICATION, true, 0xff);
   }

   /**
    * Method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {
      m_id_descriptors_length = bigEndianToNative!ushort(datain[2..4]);
      m_identification_list = make!(Array!IdentificationDescriptor)();
      size_t offset = 4;
      while (offset < m_id_descriptors_length)
      {
         // TODO: we can get a truncated buffer. probably throw an exception here.
         assert(offset + 4 + datain[offset+3] <= datain.length);
         auto id_descriptor = new IdentificationDescriptor(datain[offset..$]);
         m_identification_list ~= id_descriptor;

         offset += id_descriptor.identifier_length + 4;
      }
   }

   @property
   {
      auto identification_list() { return m_identification_list; }
      size_t id_descriptors_length() { return m_id_descriptors_length; }
   }

   class IdentificationDescriptor
   {
      this(const(ubyte)[] buffer)
      {
         m_protocol_identifier = decodeByte(buffer, 0, 0xf0);
         m_code_set            = decodeByte(buffer, 0, 0x0f);
         m_piv                 = decodeByte(buffer, 1, 0x80);
         m_association         = decodeByte(buffer, 1, 0x30);
         m_identifier_type     = decodeByte(buffer, 1, 0x0f);
         m_identifier_length = buffer[3];
         m_identifier = buffer[4..4+m_identifier_length].dup;
      }

      @property
      {
         ubyte protocol_identifier() { return m_protocol_identifier; }
         ubyte code_set() { return m_code_set; }
         ubyte piv() { return m_piv; }
         ubyte association() { return m_association; }
         ubyte identifier_type() { return m_identifier_type; }
         ubyte identifier_length() { return m_identifier_length; }
         ubyte[] identifier() { return m_identifier; }
      }

   private:
      ubyte m_protocol_identifier;
      ubyte m_code_set;
      ubyte m_piv;
      ubyte m_association;
      ubyte m_identifier_type;
      ubyte m_identifier_length;
      ubyte[] m_identifier;
   }

   unittest
   {
      string scsiName = "さいごutf8";
      // add one to the string here for null termination
      size_t scsiNameLength_multiple4 = (scsiName.length+1) + (4 - (scsiName.length+1) % 4) % 4;
      assert(scsiNameLength_multiple4 >= scsiName.length);
      assert(scsiNameLength_multiple4 <= 256);
      assert(scsiNameLength_multiple4 % 4 == 0);

      size_t id_descriptor_length = 4 + scsiNameLength_multiple4; // 4B of header plus string
      ubyte[] id_descriptor = new ubyte[id_descriptor_length];
      id_descriptor[0] = 0xe9; // protocolid=14, codeset=9
      id_descriptor[1] = 0xa8; // piv=1, association=2, idtype=8 (scsi name string)
      id_descriptor[3] = cast(ubyte) scsiNameLength_multiple4;
      id_descriptor[4..4+scsiName.length] = cast(ubyte[]) scsiName;

      size_t totalDescriptorsLength = 2*(id_descriptor.length);
      ubyte[0xff] datain_buf;
      datain_buf[1] = 0x83; // pagecode=0x83
      datain_buf[2] = cast(ubyte)(totalDescriptorsLength >> 8);
      datain_buf[3] = (totalDescriptorsLength) & 0xff;

      // first write of identification descriptor
      size_t offset = 4;
      datain_buf[offset..offset+id_descriptor.length] = id_descriptor[];

      // second write of identification descriptor
      offset = offset + id_descriptor.length;
      datain_buf[offset..offset+id_descriptor.length] = id_descriptor[];

      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto inquiry = new DeviceIdentificationInquiry(pseudoDev);

      assert(inquiry.id_descriptors_length == totalDescriptorsLength);
      assert(inquiry.identification_list.length == 2);
      foreach (descriptor; inquiry.identification_list())
      {
         assert(descriptor.protocol_identifier == 14);
         assert(descriptor.code_set == 9);
         assert(descriptor.piv == 1);
         assert(descriptor.association == 2);
         assert(descriptor.identifier_type == 8);
         assert(descriptor.identifier_length == scsiNameLength_multiple4);
         assert(bufferGetString(descriptor.identifier) == scsiName);
      }

   }
private:
   Array!(IdentificationDescriptor) m_identification_list;
   size_t m_id_descriptors_length;
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
      m_unit_serial_number = bufferGetString(datain[4..m_serial_length+4]);
   }

   @property
   {
      /** Get the length of the serial number. This will match the serial number string length. */
      ubyte serial_length() { return m_serial_length; }

      /** Get the unit serial number string. */
      string unit_serial_number() { return m_unit_serial_number; }
   }

   unittest
   {
      const string sn = "   theSerialNumber123.;  ";

      ubyte[96] datain_buf;
      datain_buf[1] = VPD.UNIT_SERIAL_NUMBER;
      datain_buf[3] = sn.length;
      datain_buf[4..4+sn.length] = cast(ubyte[])(sn);

      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto inquiry = new UnitSerialNumberInquiry(pseudoDev);

      assert(inquiry.serial_length == sn.length);
      assert(inquiry.unit_serial_number == strip(sn));
   }

private:
   ubyte m_serial_length;
   string m_unit_serial_number;
}


/**
 * ManagementNetworkAddressInquiry class to encapsulate the unmarshall'ing of the datain buffer.
 */
class ManagementNetworkAddressInquiry : Inquiry_Base
{
   import std.container : make, Array;

   /**
    * Params:
    *    dev = Device to execute the ioctl.
    */
   this(SCSIDevice dev)
   {
      super(dev, VPD.MANAGEMENT_NETWORK_ADDRESS, true, 0x1000);
   }

   /**
    * Method used to unmarshall the datain buffer.
    */
   override protected void unmarshall()
   {
      m_network_descriptors_length = bigEndianToNative!ushort(datain[2..4]);
      m_network_descriptors = make!(Array!NetworkServicesDescriptor)();

      size_t offset = 4;
      while (offset < m_network_descriptors_length)
      {
         // TODO: we can get a truncated buffer. probably throw an exception here.
         assert(offset + 4 + bigEndianToNative!ushort(cast(ubyte[2]) datain[offset+2..offset+4])
                     <= datain.length);
         auto ns_descriptor = new NetworkServicesDescriptor(datain[offset..$]);
         m_network_descriptors ~= ns_descriptor;

         offset += ns_descriptor.network_address_length + 4;
      }
   }

   @property
   {
      auto network_descriptors() { return m_network_descriptors; }
      size_t network_descriptors_length() { return m_network_descriptors_length; }
   }

   class NetworkServicesDescriptor
   {
      this(const(ubyte)[] buffer)
      {
         m_association  = decodeByte(buffer, 0, 0x60);
         m_service_type = decodeByte(buffer, 0, 0x1f);
         m_network_address_length = bigEndianToNative!ushort( cast(ubyte[2]) buffer[2..4]);
         m_network_address   = buffer[4..4+m_network_address_length].dup;
      }

      @property
      {
         ubyte association() { return m_association; }
         ubyte service_type() { return m_service_type; }
         size_t network_address_length() { return m_network_address_length; }
         ubyte[] network_address() { return m_network_address; }
      }

   private:
      ubyte m_association;
      ubyte m_service_type;
      size_t m_network_address_length;
      ubyte[] m_network_address;
   }

   unittest
   {
      string url = "somereallylongprefix://[FE80:0000:0000:0000:0202:B3FF:FE1E:8329]:43255";
      // add one to the string here for null termination
      size_t urlLength_multiple4 = (url.length+1) + (4 - (url.length+1) % 4) % 4;
      size_t ns_descriptor_length = 4 + urlLength_multiple4; // 4B of header plus string

      ubyte[] ns_descriptor = new ubyte[ns_descriptor_length];
      ns_descriptor[0] = 0xcf; // association=2, servicetype=15
      ns_descriptor[2] = cast(ubyte) urlLength_multiple4 >> 8;
      ns_descriptor[3] = urlLength_multiple4 & 0xff;
      ns_descriptor[4..4+url.length] = cast(ubyte[]) url;

      int num_test_descriptors = 3;
      size_t totalDescriptorsLength = num_test_descriptors*(ns_descriptor.length);

      ubyte[0x1000] datain_buf;
      datain_buf[1] = VPD.MANAGEMENT_NETWORK_ADDRESS;
      datain_buf[2] = cast(ubyte)(totalDescriptorsLength >> 8);
      datain_buf[3] = (totalDescriptorsLength) & 0xff;

      // first write of identification descriptor
      size_t offset = 4;
      for (int count = 0; count < num_test_descriptors; count++)
      {
         datain_buf[offset..offset+ns_descriptor.length] = ns_descriptor[];
         offset = offset + ns_descriptor.length;
      }

      auto pseudoDev = new FakeSCSIDevice(null, datain_buf, null);
      auto inquiry = new ManagementNetworkAddressInquiry(pseudoDev);

      assert(inquiry.network_descriptors_length == totalDescriptorsLength);
      assert(inquiry.network_descriptors.length == num_test_descriptors);
      foreach (descriptor; inquiry.network_descriptors())
      {
         assert(descriptor.association == 2);
         assert(descriptor.service_type == 15);
         assert(descriptor.network_address_length == urlLength_multiple4);
         assert(bufferGetString(descriptor.network_address) == url);
      }

   }
private:
   Array!(NetworkServicesDescriptor) m_network_descriptors;
   size_t m_network_descriptors_length;
}
