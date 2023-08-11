DLMS dissector for Wireshark
(c) Petr Matousek, Brno University of Technology, Brno, Czech Republic
Contact: matousp@fit.vutbr.cz

Version: 1.0
Date: 28th March 2018

This folder contains three LUA files forming a DLMS dissector for Wireshark. 
DLMS/COSEM is a transmission protocol for energy metering. It supports remote meter reading,
remote control and any other services related to energy distribution. 

DLMS specification is developed and maintained by the DLMS User Association. It defined 
application layer protocols, COSEM objects and classes, HDLC or TCP/IP transport. 

DLMS dissector was implemented as a part of the research project IRONSTONE (2016-2019) by 
Brno University of Technology, Czech Republic. It implements a limited set of features of 
DLMS communication that was a part of the project. 

DLMS dissector includes:
  - dlms.lua - a dissector of DLMS layer including AARQ and AARE PDUs
  - hdlc.lua - a dissector of HDLC format 3. HDLC transports DLMS messages. Here we expect 
               HDLC frames encapsulated over TCP/IP. For DLMS, mostly I-frames are important. 
             - hdlc.lua dissector calls DLMS dissector for non-empty I-frames. 
  - dlms-wrapper.lua - a dissector that extracts DLMS messages wrapped into a user-specific
               wrapper over TCP/IP. In this case, it skipps the first N bytes. The remaining
               bytes are interpreted as a DLMS communication, thus, DLMS dissector is called
               upon them. 

Supported DLMS message and parsing:
  - only LN referencing
  - AARQ (with xDLMS-Initiate.response) and AARE (with xDLMS-Initiate.response) 
  - DLMS LN referencing messages: GetRequest, GetResponse, SetRequest, SetResponse 
  - detailed parsing of Get/SetRequestNormal, Get/SetResponseNormal, GetResponseWithDatablock 
  - GetRequestNormal: extraction of OBIS code, interface class and attribute 
  - GetResponseNormal: extraction of data type, length and value 
  - SetRequestNormal: OBIS code, interface class, attribute and value extracted
  - SetResponseNormal: data-access-result extracted
  - DataBlock-G value is not interpreted
  - No ciphered APDU messages supported

TODO list:
  - reassembling of segmented HDLC messages
  - AARL, AARE, Abort parsing