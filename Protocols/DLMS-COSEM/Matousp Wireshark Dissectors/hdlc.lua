-- 
-- Lua dissector for HDLC encapsulated over TCP (used for SCADA systems over TCP/IP)
-- The payload is interpreted as a DLMS/COSEM message (requires dlms.lua dissector)
--
-- Version 1.0
-- Last update: 28th March 2018
--
-- Developed as a part of IRONSTONE research project
-- 
-- (c) Petr Matousek, FIT BUT, Czech Republic, 2018
-- Contact:  matousp@fit.vutbr.cz
--
-- declare the protocol
hdlc_proto = Proto("HDLC", "HDLC over TCP")

-- declare the value strings
local FrameFormatTypeVALS = {
   [0xA] = "Number 3"
}

local SegVALS = {
   [0] = "Not Set",
   [1] = "Set"
}

local FrameTypeVALS = {
   [0] = "I-Frame",
   [1] = "S-Frame"
}

local sFrameTypeVALS = {
   [0] = "Receive Ready (RR)",
   [1] = "Receive Not Read (RNR)",
   [2] = "Reject (REJ)",
   [3] = "Selective Reject (SREJ)"
}

local LLCsrcSAPVALS = {
   [0xe6] = "Command",
   [0xe7] = "Response"
}

-- Declare the fields

-- HDLC header
local flag = ProtoField.uint8("hdlc.flag","Flag",base.HEX)
local frameFormat = ProtoField.uint16("hdlc.frameFormat","Frame Format",base.HEX)
local frameType = ProtoField.uint16("hdlc.frameType","HDLC Frame Format Type",base.DEC,FrameFormatTypeVALS,0xf000)
local segmentationFlag = ProtoField.uint16("hdlc.segmentationFlag","Segmentation Flag", base.DEC,SegVALS,0x0800)
local frameLen = ProtoField.uint16("hdlc.frameLen","HDLC Frame Length",base.DEC, nil,0x07FF)
local dstAddress = ProtoField.uint8("hdlc.dstAddress", "Destination Address",base.DEC)
local srcAddress = ProtoField.uint8("hdlc.srcAddress", "Source Address",base.DEC)
local ctrlField = ProtoField.uint8("hdlc.ctrlField","Control Field", base.HEX)

-- HDLC frame types
-- I-Frames
local RecvNumber = ProtoField.uint8("hdlc.recvNumber","N(R)",base.DEC,nil,0xe0)
local Polling = ProtoField.uint8("hdlc.polling","P/F flag",base.DEC,nil,0x10)
local SentNumber = ProtoField.uint8("hdlc.sentNumber","N(S)",base.DEC,nil,0x0e)
local iFrameType = ProtoField.uint8("hdlc.iFrameType","Frame type",base.HEX,FrameTypeVALS,0x01)

-- S-Frames
local sFrame = ProtoField.uint8("hdlc.sFrame","S-Frame",base.DEC,nil,0x3)
local sFrameType = ProtoField.uint8("hdlc.sFrameType","type",base.DEC,sFrameTypeVALS,0xc)

-- HDLC data and trailer
local HCS = ProtoField.uint16("hdlc.HCS","Header Checksum", base.HEX)
local FCS = ProtoField.uint16("hdlc.FCS","Frame Checksum", base.HEX)

-- LLC layer header
-- local LLC_type = ProtoField.uint16("hdlc.llc_type","LLC command/response", base.HEX, LLCTypeVALS)
local LLC_dstSAP = ProtoField.uint8("hdlc.llc_dstSAP", "Destination LSAP",base.HEX)
local LLC_srcSAP = ProtoField.uint8("hdlc.llc_srcSAP", "Source LSAP",base.HEX, LLCsrcSAPVALS)
local LLC_control = ProtoField.uint8("hdlc.llc_control","LLC Quality")
local LLC_data = ProtoField.bytes("hdlc.llc_data","Data")

hdlc_proto.fields = {flag, frameFormat, frameType, segmentationFlag, frameLen, dstAddress, srcAddress, ctrlField, RecvNumber, Polling, SentNumber, iFrameType, sFrame, sFrameType, HCS, LLC_dstSAP, LLC_srcSAP, LLC_control, LLC_data, FCS}

-- create the dissection function
function hdlc_proto.dissector(buffer, pinfo, tree)

    -- Set the protocol column

    -- create the HDLC protocol tree item
    local t_hdlc = tree:add(hdlc_proto, buffer())
    local offset = 0
    local frame_len = 0
    local information_len = 0
    local hdlc_flag = buffer(offset,1):uint()

    if hdlc_flag == 0x7e then  -- it is a HDLC frame
       t_hdlc:add(flag, buffer(offset,1))
       
       local t_frameFormat = t_hdlc:add(frameFormat,buffer(offset + 1, 2))
       t_frameFormat:add(frameType,buffer(offset+1,2))
       t_frameFormat:add(segmentationFlag,buffer(offset+1,2))
       t_frameFormat:add(frameLen,buffer(offset+1,2))
       
       t_hdlc:add(dstAddress, buffer(offset + 3, 1))
       t_hdlc:add(srcAddress, buffer(offset + 4, 1))
       
       local srcAdd = buffer(offset+3,1):uint()
       local dstAdd = buffer(offset+4,1):uint()
       
       -- moving offset to the control field
       local t_ctrlField = t_hdlc:add(ctrlField, buffer(offset+5, 1))
       
       local frameCode = buffer:range(5,1)
       local FrameBits = frameCode:bitfield(6,2)
       
       -- iFrames structure
       if FrameBits == 0 or FrameBits == 2 then
	  t_ctrlField:add(RecvNumber, buffer(offset+5,1))
	  t_ctrlField:add(Polling, buffer(offset+5,1))
	  t_ctrlField:add(SentNumber, buffer(offset+5,1))
	  t_ctrlField:add(iFrameType, buffer(offset+5,1))
	  local recv = frameCode:bitfield(0,3)
	  local sent = frameCode:bitfield(4,3)

	  -- the length of the frame including opening and closing flags
	  frame_len = buffer:len()
	  -- the length of the information field
	  information_len = frame_len-9 

	  offset = offset + 6  -- move to the HCS or FCS field

	  if information_len > 0 then  -- there is a non-empty information field
	     -- HCS field
	     t_hdlc:add(HCS, buffer(offset, 2))
	     information_len = information_len - 2   -- length without HCS field
	     local destSAP = buffer(offset+2,1):uint()
	     offset = offset + 2
	     if destSAP == 0xe6 then -- testing header LLC presence
		
		local t_LLC_frame = t_hdlc:add(buffer(offset,information_len),"Information")
		t_LLC_frame:add(LLC_dstSAP,buffer(offset,1))
		t_LLC_frame:add(LLC_srcSAP,buffer(offset+1,1))
		
		t_LLC_frame:add(LLC_control,buffer(offset+2,1))
		t_LLC_frame:add(LLC_data, buffer(offset+3, information_len-3))
		
		local new_buffer = buffer(offset+3,information_len-3)
		
		local dissector = Dissector.get("dlms")
		dissector:call(new_buffer:tvb(),pinfo,tree)
		
		offset = offset + information_len
		
		pinfo.cols['protocol'] = "DLMS"
	     else -- no LLC header present but non-empty data field
		information_len = information_len 
		local dataLen = "Data ("..information_len.." bytes)"
		t_hdlc:add(buffer(offset,information_len),dataLen)
		pinfo.cols['protocol'] = "HDLC over TCP"
		pinfo.cols['info'] = "HDLC segmented data ("..information_len.." bytes)"
		offset = offset + information_len
	     end
	  else -- I-frame has an empty information field
		pinfo.cols['protocol'] = "HDLC over TCP"
		pinfo.cols['info'] = FrameTypeVALS[0]..", From "..srcAdd.." -> "..dstAdd..", no data"
	  end
       end

       -- sFrames struture
       if FrameBits == 1 then
	  t_ctrlField:add(RecvNumber, buffer(offset+5,1))
	  t_ctrlField:add(Polling, buffer(offset+5,1))
	  t_ctrlField:add(sFrameType, buffer(offset+5,1))
	  t_ctrlField:add(sFrame, buffer(offset+5,1))
	  local recv = frameCode:bitfield(0,3)
	  local sType = frameCode:bitfield(5,2)
	  
	  pinfo.cols['protocol'] = "HDLC over TCP"
	  pinfo.cols['info'] = FrameTypeVALS[1]..", From "..srcAdd.." -> "..dstAdd..", "..sFrameTypeVALS[sType]..": N(R)="..recv
	  offset = offset + 6
       end

       t_hdlc:add(FCS, buffer(offset,2))
       t_hdlc:add(flag, buffer(offset+2,1))
    end
end

-- load the tcp port table
tcp_table = DissectorTable.get("tcp.port")
-- register the protocol to port 4061 and 4060
tcp_table:add(4061, hdlc_proto)
tcp_table:add(4060, hdlc_proto)
