--
-- Lua dissector for DLMS/COSEM
-- Version 1.0
-- Last update: 28th March 2018
--
-- Developed as a part of IRONSTONE research project
-- 
-- (c) Petr Matousek, FIT BUT, Czech Republic, 2018
-- Contact:  matousp@fit.vutbr.cz
--
-- This is not a full DLMS dissector: it parses only selected DLMS/COSEM messages
-- LN referencing support only
--

-- declare the protocol
dlms_proto = Proto("DLMS","DLMS/COSEM")

-- declare the value strings
local COSEMpdu = {
   [0x60] = "AARQ Association Request",
   [0x61] = "AARE Association Response",
   [0x62] = "AARL Release Request",
   [0x63] = "AARE Release Response",
   [0x64] = "ABRT Abort",
   [0xc0] = "GetRequest",
   [0xc1] = "SetRequest",
   [0xc2] = "EventNotificationRequest",
   [0xc3] = "ActionRequest",
   [0xc4] = "GetResponse",
   [0xc5] = "SetResponse",
   [0xc7] = "ActionResponse"
}

local GetRequestVALS = {
   [1] = "GetRequestNormal",
   [2] = "GetRequestNext",
   [3] = "GetRequestWithList"
} 

local GetResponseVALS = {
   [1] = "GetResponseNormal",
   [2] = "GetResponseWithDatablock",
   [3] = "GetResponseWithList"
}

local SetRequestVALS = {
   [1] = "SetRequestNormal",
   [2] = "SetRequestWithFirstDatablock",
   [3] = "SetRequestWithDatablock",
   [4] = "SetRequestWithList",
   [5] = "SetRequestWithListAndFirstDatablock"
}

local SetResponseVALS = {
   [1] = "SetResponseNormal",
   [2] = "SetResponseWithFirstDatablock",
   [3] = "SetResponseWithDatablock",
   [4] = "SetResponseWithList",
   [5] = "SetResponseWithListAndFirstDatablock"
}

local GetDataTypeVALS = { 
   [0] = "null-data",
   [1] = "array",
   [2] = "structure",
   [3] = "boolean",
   [4] = "bit-string",
   [5] = "double-long",
   [6] = "double-long-unsigned",
   [9] = "octet-string",
   [10] = "visible-string",
   [13] = "bcd",
   [15] = "integer",
   [16] = "long",
   [17] = "unsigned",
   [18] = "long-unsigned",
   [19] = "compact-array",
   [20] = "long64",
   [21] = "long64-unsigned",
   [22] = "enum",
   [23] = "float32",
   [24] = "float64",
   [25] = "date_time",
   [26] = "data",
   [27] = "time",
   [255] = "do-not-care"
}

local GetDataResultVALS = {
   [0] = "data",
   [1] = "data-access-result"
}

local DataBlockResultVALS = {
   [0] = "raw-data",
   [1] = "data-access-result"
}

local BooleanVALS = {
   [0] = "False",
   [1] = "True"
}

local DataAccessResultVALS = {
   [0] = "Success",
   [1] = "HardwareFault",
   [2] = "TemporaryFailure",
   [3] = "ReadWriteDenied",
   [4] = "ObjectUndefined",
   [9] = "ObjectClassInconsistent",
   [11] = "ObjectUnavailable",
   [12] = "TypeUnmatched",
   [13] = "ScopeOfAccessViolated",
   [14] = "DataBlockUnavailable",
   [15] = "LongGetAborted",
   [16] = "NoLongGetInProgress",
   [17] = "LongSetAborted",
   [18] = "NoLongSetInProgress",
   [250] = "OtherReason"
}

local ContextVALS = {   -- AARQ: last two bytes of the application context name (OID)
   [0x0101] = "LN Referencing, Without Ciphering",
   [0x0102] = "SN Referencing, Without Ciphering",
   [0x0103] = "LN Referencing, With Ciphering",
   [0x0104] = "SN Referencing, With Ciphering",
   [0x0200] = "Lowest Level Security",
   [0x0201] = "Low Level Security",
   [0x0202] = "High Level Security", 
   [0x0203] = "High Level Security - MD5", 
   [0x0204] = "High Level Security - SHA1", 
   [0x0205] = "High Level Security - GMAC"
}

local ACSErequirementsVALS = {
   [0] = "authentication",
   [1] = "application-context-negotiation",
   [2] = "higher-level-assocation",
   [3] = "nested-assocation"
}

local AssociationResultVALS = {
   [0] = "accepted",
   [1] = "rejected-permanent",
   [2] = "rejected-transient",
}

local ASCEserviceUserVALS = {
   [0] = "null",
   [1] = "no-reason-given",
   [2] = "application-context-name-not-support",
   [11] = "authentication-mechanism-name-not-recognized",
   [12] = "authentication-mechanism-name-required",
   [13] = "authentication-failure",
   [14] = "authentication-required"
}

local ASCEserviceUserVALS = {
   [0] = "null",
   [1] = "no-reason-given",
   [2] = "application-context-name-not-support",
   [11] = "authentication-mechanism-name-not-recognized",
   [12] = "authentication-mechanism-name-required",
   [13] = "authentication-failure",
   [14] = "authentication-required"
}

local ASCEserviceProviderVALS = {
   [0] = "null",
   [1] = "no-reason-given",
   [2] = "no-common-acse-version",
}

-- Declare the Wireshark fields

-- DLMS header
local APDU_type = ProtoField.uint8("dlms.apdu_type","Type",base.HEX,COSEMpdu)
-- DLMS GetRequest and SetRequest fields
local GetRequest = ProtoField.uint8("dlms.GetRequest","GetRequest",base.HEX,GetRequestVALS)
local SetRequest = ProtoField.uint8("dlms.SetRequest","SetRequest",base.HEX,SetRequestVALS)
local Request_invoke_id = ProtoField.uint8("dlms.request_invoke_id","Invoke ID and Priority",base.HEX)
local Class_id = ProtoField.uint16("dlms.class_id","class-id")
local Instance_id = ProtoField.string("dlms.instance_id","OBIS code")
local Attribute_id = ProtoField.uint8("dlms.attribute_id","attribute-id")
local Access_selection = ProtoField.uint8("dlms.access_selection","access-selection")
local Block_number = ProtoField.uint32("dlms.block_number","Block number",base.HEX)
-- DLMS GetResponseNormal
local GetResponse = ProtoField.uint8("dlms.GetResponse","GetResponse",base.HEX,GetResponseVALS)
local SetResponse = ProtoField.uint8("dlms.SetResponse","SetResponse",base.HEX,SetResponseVALS)
local Response_invoke_id = ProtoField.uint8("dlms.response_invoke_id","Invoke ID and Priority",base.HEX)
local Response_result = ProtoField.bytes("dlms.response_result","Data",base.DOT)
local Response_getData = ProtoField.uint8("dlms.response_getData","GetDataResult",base.DEC,GetDataResultVALS)
local DataType = ProtoField.uint8("dlms.dataType","Data type",base.DEC,GetDataTypeVALS)
local DataStringLen = ProtoField.uint8("dlms.dataStringLen","Length",base.DEC)
-- GetResponse Value Types
local StringValue = ProtoField.bytes("dlms.StringValue","Value",base.DOT)
local LongValue = ProtoField.uint16("dlms.LongValue","Value",base.DEC)
local BooleanValue = ProtoField.uint8("dlms.BooleanValue","Value",base.DEC, BooleanVALS)
local IntegerValue = ProtoField.uint8("dlms.IntegerValue","Value",base.DEC)
local DoubleLongValue = ProtoField.uint32("dlms.IntegerValue","Value",base.DEC)
local Long64Value = ProtoField.uint64("dlms.long64","Value",base.DEC)
-- GetResponseWithDataBlock
local LastBlock = ProtoField.uint8("dlms.lastBlock","Last block",base.DEC, BooleanVALS)
local BlockNumber = ProtoField.uint32("dlms.blockNumber", "Block number",base.DEC)
local DataBlockResult = ProtoField.uint8("dlms.dataBlockResult","Result",base.DEC, DataBlockResultVALS)
local DataAccessResult = ProtoField.uint8("dlms.dataAccessResult","DataAccessResult",base.DEC, DataAccessResultVALS)

dlms_proto.fields = {DLMS, APDU_type, GetRequest, SetRequest, Request_invoke_id, Class_id, Instance_id, Attribute_id, Access_selection, Block_number, GetResponse, SetResponse, Response_invoke_id, Response_result, Response_getData, DataType, DataStringLen, StringValue, LongValue, BooleanValue, IntegerValue, DoubleLongValue, Long64Value, LastBlock, BlockNumber, DataBlockResult, DataAccessResult}

-- create the dissection function
function dlms_proto.dissector(buffer, pinfo, tree)

    -- Set the protocol column
   local t_dlms = tree:add(dlms_proto, buffer())
   local offset = 0
   local frame_len = 0
   local dlms_type = buffer(offset,1):uint()

    -- create the DLMS protocol tree item
    t_dlms:add(APDU_type, buffer(offset,1))
    frame_len = buffer:len()
    pinfo.cols['info'] = "DLMS "..COSEMpdu[dlms_type]

    -- processing DLMS.GetRequest
    if dlms_type == 0xc0 then
       local getRequestType = buffer(offset+1,1):uint()
       t_dlms:add(GetRequest, buffer(offset+1,1))
       
       if getRequestType == 1 then -- getRequestNormal
	  t_dlms:add(Request_invoke_id, buffer(offset+2,1))
	  local t_Descriptor = t_dlms:add(buffer(offset+3),"Cosem-Attribute-Descriptor")
	  local class = buffer(offset+3,2):uint()
	  local instance = buffer(offset+5,6)
	  local obis = string.format("%d.%d.%d.%d.%d.%d",instance(0,1):uint(),instance(1,1):uint(),instance(2,1):uint(),instance(3,1):uint(),instance(4,1):uint(),instance(5,1):uint())
	  local attribute = buffer(offset+11,1):uint()
	  
	  t_Descriptor:add(Class_id, buffer(offset+3,2))
	  t_Descriptor:add(Instance_id, buffer(offset+5,6),obis)
	  t_Descriptor:add(Attribute_id, buffer(offset+11,1))
	  
	  t_dlms:add(Access_selection, buffer(offset+12,1))
	  pinfo.cols['info'] = GetRequestVALS[getRequestType]..", class="..class..", OBIS="..obis..", attr="..attribute
       elseif getRequestType == 2 then -- getRequestNext
	  t_dlms:add(Request_invoke_id, buffer(offset+2,1))
	  t_dlms:add(Block_number, buffer(offset+3,4))
	  local block_number = buffer(offset+3,4):uint()
	  
	  pinfo.cols['info'] = GetRequestVALS[getRequestType]..", block no: "..block_number
       else
	  pinfo.cols['info'] = GetRequestVALS[getRequestType]
       end
    end

    -- processing DLMS.SetRequest
    if dlms_type == 0xc1 then
       local setRequestType = buffer(offset+1,1):uint()
       t_dlms:add(SetRequest,buffer(offset+1,1))
       
       if setRequestType == 1 then -- setRequestNormal
	  t_dlms:add(Request_invoke_id,buffer(offset+2,1))
	  local t_Descriptor = t_dlms:add(buffer(offset+3),"Cosem-Attribute-Descriptor")
	  local class = buffer(offset+3,2):uint()
	  local instance = buffer(offset+5,6)
	  local obis = string.format("%d.%d.%d.%d.%d.%d",instance(0,1):uint(),instance(1,1):uint(),instance(2,1):uint(),instance(3,1):uint(),instance(4,1):uint(),instance(5,1):uint())
	  local attribute = buffer(offset+11,1):uint()
	  
	  t_Descriptor:add(Class_id, buffer(offset+3,2))
	  t_Descriptor:add(Instance_id, buffer(offset+5,6),obis)
	  t_Descriptor:add(Attribute_id, buffer(offset+11,1))
	  t_dlms:add(Access_selection, buffer(offset+12,1))
	  offset = offset + 13
	  local dataLen = frame_len - 13
	  local t_data = t_dlms:add(buffer(offset,dataLen),"Data")
	  local dataTypeIndex = buffer(offset,1):uint()
	  local value
	  t_data:add(DataType,buffer(offset,1))

	  -- processing long integer or long unsigned (16 bits)
	  if dataTypeIndex == 16 or dataTypeIndex == 18 then 
	     t_data:add(LongValue,buffer(offset+1,dataLen-1))
	     value = buffer(offset+1,dataLen-1):uint()
	  end

	  -- processing Boolean (8 bits)
	  if dataTypeIndex == 3 then
	     t_data:add(BooleanValue, buffer(offset+1,dataLen-1))
	     value = buffer(offset+1,dataLen-1):uint()
	  end
	  
	  -- processing double long and double long unsigned (32 bits)
	  if dataTypeIndex == 5 or dataTypeIndex == 6 then
	     t_data:add(DoubleLongValue, buffer(offset+1,dataLen-1))
	     value = buffer(offset+1,dataLen-1):uint()
	  end

	  -- processing structure and array (sequence of data)
	  if dataTypeIndex == 1 or dataTypeIndex == 2 then
	     t_data:add(StringValue,buffer(offset+1,dataLen-1))
	     value = buffer(offset+1,dataLen-1):uint()
	  end

	  -- processing unsigned integer, integer or enum (8 bits)
	  if dataTypeIndex == 17 or dataTypeIndex == 15  or dataTypeIndex == 22 then
	     t_data:add(IntegerValue, buffer(offset+1,dataLen-1))
	     value = buffer(offset+1,dataLen-1):uint()
	  end

	  -- processing octet string or visible string
	  if dataTypeIndex == 9 or dataTypeIndex == 10 then
	     t_data:add(DataStringLen,buffer(offset+1,1))
	     -- get dataLen from the OCTET STRING format
	     dataLen = buffer(offset+2,1):uint()
	     t_data:add(StringValue,buffer(offset+3,dataLen))
	     value = buffer(offset+3,dataLen)
	  end
	  pinfo.cols['info'] = SetRequestVALS[setRequestType]..", OBIS="..obis..", attr="..attribute..", value="..value
       end 
    end
    
    -- processing DLMS.GetResponse
    if dlms_type == 0xc4 then
       t_dlms:add(GetResponse,buffer(offset+1,1))

       local responseType = buffer(offset+1,1):uint()
       local dataLen = frame_len-5
       local dataTypeIndex = 0
       t_dlms:add(Response_invoke_id,buffer(offset+2,1))

       if responseType == 1 then -- GetNormalResponse
	  local t_data = t_dlms:add(buffer(offset+3,frame_len-3),"Data")
	  offset = offset+3
	  t_data:add(Response_getData,buffer(offset,1))

	  if buffer(offset,1):uint() == 0 then -- CHOICE Data
	     t_data:add(DataType,buffer(offset+1,1))
	     dataTypeIndex = buffer(offset+1,1):uint()
	     
	     -- processing octet string
	     if dataTypeIndex == 9  then
		t_data:add(DataStringLen,buffer(offset+2,1))
		-- get dataLen from the OCTET STRING format
		dataLen = buffer(offset+2,1):uint()
		t_data:add(StringValue,buffer(offset+3,dataLen))
	     end

	     -- processing visible string
	     if dataTypeIndex == 10 then
		t_data:add(DataStringLen,buffer(offset+2,1))
		-- get dataLen from the OCTET STRING format
		dataLen = buffer(offset+2,1):uint()
		t_data:add(buffer(offset+3,dataLen),"Value:",PrintString(dataLen,buffer(offset+3)))
	     end

	     -- processing long integer or long unsigned (16 bits)
	     if dataTypeIndex == 16 or dataTypeIndex == 18 then 
		t_data:add(LongValue,buffer(offset+2,dataLen))
	     end
	     
	     -- processing Boolean (8 bits)
	     if dataTypeIndex == 3 then
		t_data:add(BooleanValue, buffer(offset+2,dataLen))
	     end
	     
	     -- processing unsigned integer, integer or enum (8 bits)
	     if dataTypeIndex == 17 or dataTypeIndex == 15  or dataTypeIndex == 22 then
		t_data:add(IntegerValue, buffer(offset+2,dataLen))
	     end
	     
	     -- processing double long and double long unsigned (32 bits)
	     if dataTypeIndex == 5 or dataTypeIndex == 6 then
		t_data:add(DoubleLongValue, buffer(offset+2,dataLen))
	     end
	     
	     -- processing long64 and long64 unsigned (64 bits)
	     if dataTypeIndex == 20 or dataTypeIndex == 21 then
		t_data:add(Long64Value, buffer(offset+2,dataLen))
	     end

	     -- processing structure and array (sequence of data)
	     if dataTypeIndex == 1 or dataTypeIndex == 2 then
		t_data:add(StringValue,buffer(offset+2,dataLen))
	     end
	     pinfo.cols['info'] = GetResponseVALS[responseType]..", "..GetDataTypeVALS[dataTypeIndex].." ("..dataLen.." bytes)"
	  else                                  -- CHOICE data-access-result
	     local result = buffer(offset+2,1):uint()
	     t_data:add(buffer(offset+2,1),"DataAccessResult:",DataAccessResultVALS[result].." ("..result..")")
	     pinfo.cols['info'] = GetResponseVALS[responseType]..", "..DataAccessResultVALS[result].." ("..dataLen.." bytes)"
	  end
       end
       
       if responseType == 2 then -- GetResponseWithDatablock
	  local t_dataBlock = t_dlms:add(buffer(offset+3, frame_len-3),"DataBlock-G")
	  offset = offset+3
	  t_dataBlock:add(LastBlock, buffer(offset,1))
	  local blockNumber = buffer(offset+1,4):uint()
	  t_dataBlock:add(BlockNumber, buffer(offset+1,4))
	  t_dataBlock:add(DataBlockResult, buffer(offset+5,1))
	  local result = buffer(offset+5,1):uint()

	  if result == 0 then -- raw data, i.e., OCTET STRING
	     dataLen = dataLen - 5    -- length of raw data in this frame
	     dataTypeIndex = 9
	     local dataBlockLen = buffer(offset+6,1):uint()
	     offset = offset + 6
	     
	     -- processing ASN.1 variable-length integers
	     if dataBlockLen <= 127 then -- the length is one byte only
		t_dataBlock:add(DataStringLen, buffer(offset,1))
	     else -- the length is more than one byte
		local LenBytes = dataBlockLen - 128  -- get the length of the length field
		local LenValue = buffer(offset+1,LenBytes):uint()
		t_dataBlock:add(DataStringLen, buffer(offset,LenBytes+1), LenValue)
		offset = offset + LenBytes
	     end
		
	     t_dataBlock:add(StringValue,buffer(offset,dataLen-1)) 
	  end
	  pinfo.cols['info'] = GetResponseVALS[responseType].." no. "..blockNumber..", "..GetDataTypeVALS[dataTypeIndex].." ("..dataLen.." bytes)"
       else
	  pinfo.cols['info'] = GetResponseVALS[responseType]..", "..GetDataTypeVALS[dataTypeIndex].." ("..dataLen.." bytes)"
       end
    end

    -- processing DLMS.SetResponse
    if dlms_type == 0xc5 then
       t_dlms:add(SetResponse,buffer(offset+1,1))

       local responseType = buffer(offset+1,1):uint()
       t_dlms:add(Response_invoke_id,buffer(offset+2,1))

       if responseType == 1 then -- SetNormalResponse
	  t_dlms:add(DataAccessResult, buffer(offset+3,1))
	  local response = buffer(offset+3,1):uint()
	  pinfo.cols['info'] = SetResponseVALS[responseType]..", result="..response.." ("..DataAccessResultVALS[response]..")"
       end
    end
    
    -- processing DLMS.AARQ (encoded by BER using TLV structures)
    if dlms_type == 0x60 then                       -- type (application tag AARQ)
       local bufferLen = buffer(offset+1,1):uint()  -- the length of the TLV value
       t_dlms:add(buffer(offset+1,1),"Length:",bufferLen)
       local type = GetTagNumber(buffer:range(2,1)) -- type (AARQ field)
       local len = buffer(offset+3,1):uint()        -- the length of the embedded TLV
       bufferLen = bufferLen - len -2
       offset = offset + 4
       if type == 1 then -- type Application Context
	  if buffer(offset,1):uint() == 0x06 then   -- type OID
	     len = buffer(offset+1,1):uint()        -- the length of the embedded TLV
	     local oid = PrintOID(buffer(offset+2,7))
	     t_dlms:add(buffer(offset+2,len),"ApplicationContextName:", oid.." ("..ContextVALS[buffer(offset+7,2):uint()]..")")
	     offset = offset + 9
	  end
       end
       if bufferLen > 0 then
	  type = GetTagNumber(buffer:range(offset,1))
	  if type == 10 then                      -- sender ACSE requirements
	     len = buffer(offset+1,1):uint()
	     local acse = GetBitStringValue(buffer(offset+2,len))
	     t_dlms:add(buffer(offset+2,len),"SenderACSErequirements:",ACSErequirementsVALS[acse].." ("..acse..")")
	     offset = offset + 2 + len
	     bufferLen = bufferLen - 2 - len
	  end
       end
       if bufferLen > 0 then
	  type = GetTagNumber(buffer:range(offset,1))
	  if type == 11 then                      -- mechanism name
	     len = buffer(offset+1,1):uint()
	     local oid = PrintOID(buffer(offset+2,len))
	     t_dlms:add(buffer(offset+2,len),"MechanismName:",oid.." ("..ContextVALS[buffer(offset+7,2):uint()]..")")
	     offset = offset + 2 + len
	     bufferLen = bufferLen - 2 - len
	  end
       end
       if bufferLen > 0 then
	  type = GetTagNumber(buffer:range(offset,1))
	  if type == 12 then                      -- calling authentication value
	     len = buffer(offset+1,1):uint()
	     type = GetTagNumber(buffer:range(offset+2,1)) -- get CHOICE tag
	     if type == 0 then -- charstring
		offset = offset + 2               -- move to the charstring
		len = buffer(offset+1,1):uint()   -- the length of the string
	     end
	     t_dlms:add(buffer(offset+2,len),"CallingAuthenticationValue:",PrintString(len,buffer(offset+2,len)))
	     offset = offset + 2 + len
	     bufferLen = bufferLen - 2 - len
	  end
       end
       if bufferLen > 0 then
	  type = GetTagNumber(buffer:range(offset,1))
	  if type == 30 then                       -- type user information 
	     len = buffer(offset+1,1):uint()       -- the length of the embedded TLV
	     if buffer(offset+2,1):uint() == 0x04 then -- type OCTET STRING
		len = buffer(offset+3,1):uint()        -- the length of the string
		if buffer(offset+4,1):uint() == 0x01 then -- initiateRequest tag
		   offset = offset+4
		   local t_request = t_dlms:add(buffer(offset,len),"UserInformation:","xDLMS-Initiate.request")
		   local item = buffer(offset+1,1):uint() -- OPTIONAL dedicated-key
		   if item == 0 then -- key not present: boolean value
		      t_request:add(buffer(offset+1,1),"DedicatedKey:",BooleanVALS[item].."("..item..")")
		      offset=offset+2
		   else              -- key present: OCTET STRING
		      offset = offset + 1
		      len = buffer(offset,1)
		      local str = tostring(buffer(offset+1,len))
		      t_request:add(buffer(offset+1,len),"DedicatedKey:",str)
		      offset = offset+1+len
		   end
		   item = buffer(offset,1):uint()
		   t_request:add(buffer(offset,1),"ResponseAllowed:",BooleanVALS[item].."("..item..")")
		   offset = offset+1
		   item = buffer(offset,1):uint()
		   t_request:add(buffer(offset,1),"ProposedQualityOfService:",BooleanVALS[item].."("..item..")")
		   offset = offset+1
		   item = buffer(offset,1):uint()
		   t_request:add(buffer(offset,1),"ProposedDLMSversionNumber:",item)
		   offset = offset+1
		   t_request:add(buffer(offset,7),"ProposedConformance:",tostring(buffer(offset,7)))
		   offset = offset+7
		   t_request:add(buffer(offset,2),"ClientMaxReceivedPDUsize:", buffer(offset,2):uint())
		end
	     end
	  end
       end
    end

    -- processing DLMS.AARE (encoded by BER using TLV structures)
    if dlms_type == 0x61 then                       -- type (application tag AARE)
       local bufferLen = buffer(offset+1,1):uint()  -- the length of the TLV value
       t_dlms:add(buffer(offset+1,1),"Length:",bufferLen)
       local type = GetTagNumber(buffer:range(2,1)) -- type (AARQ field)
       local len = buffer(offset+3,1):uint()        -- the length of the embedded TLV
       bufferLen = bufferLen - len -2
       offset = offset + 4
       if type == 1 then -- type Application Context
	  if buffer(offset,1):uint() == 0x06 then   -- type OID
	     len = buffer(offset+1,1):uint()        -- the length of the embedded TLV
	     local oid = PrintOID(buffer(offset+2,7))
	     t_dlms:add(buffer(offset+2,len),"ApplicationContextName:", oid.." ("..ContextVALS[buffer(offset+7,2):uint()]..")")
	     offset = offset + 9
	  end
       end
       if bufferLen > 0 then
	  type = GetTagNumber(buffer:range(offset,1))
	  if type == 2 then                      -- association result
	     len = buffer(offset+1,1):uint()
	     local result = buffer(offset+4,1):uint() -- INTEGER type
	     t_dlms:add(buffer(offset+4,1),"AssociationResult:",AssociationResultVALS[result].." ("..result..")")
	     offset = offset + 2 + len
	     bufferLen = bufferLen - 2 - len
	     pinfo.cols['info'] = "DLMS "..COSEMpdu[dlms_type]..": "..AssociationResultVALS[result]
	  end
       end
       if bufferLen > 0 then
	  type = GetTagNumber(buffer:range(offset,1))
	  if type == 3 then                      -- result source diagnostic
	     len = buffer(offset+1,1):uint()
	     type = GetTagNumber(buffer:range(offset+2,1)) 
	     if type == 1 then                   -- acse-service user
		local result = buffer(offset+6,1):uint()
		t_dlms:add(buffer(offset+6,1),"ResultSourceDiagnostic:",ASCEserviceUserVALS[result].." ("..result..")")
	     else
		t_dlms:add(buffer(offset+6,1),"ResultSourceDiagnostic:",ASCEserviceProvideVALS[result].." ("..result..")")
	     end
	     offset = offset + 2 + len
	     bufferLen = bufferLen - 2 - len
	  end
       end
       if bufferLen > 0 then
	  type = GetTagNumber(buffer:range(offset,1))
	  if type == 8 then                      -- responder ACSE requirements
	     len = buffer(offset+1,1):uint()
	     local acse = GetBitStringValue(buffer(offset+2,len))
	     t_dlms:add(buffer(offset+2,len),"SenderACSErequirements:",ACSErequirementsVALS[acse].." ("..acse..")")
	     offset = offset + 2 + len
	     bufferLen = bufferLen - 2 - len
	  end
       end
       if bufferLen > 0 then
	  type = GetTagNumber(buffer:range(offset,1))
	  if type == 9 then                      -- mechanism name
	     len = buffer(offset+1,1):uint()
	     local oid = PrintOID(buffer(offset+2,len))
	     t_dlms:add(buffer(offset+2,len),"MechanismName:",oid.." ("..ContextVALS[buffer(offset+7,2):uint()]..")")
	     offset = offset + 2 + len
	     bufferLen = bufferLen - 2 - len
	  end
       end
       if bufferLen > 0 then
	  type = GetTagNumber(buffer:range(offset,1))
	  if type == 10 then                      -- responding authentication value
	     len = buffer(offset+1,1):uint()
	     type = GetTagNumber(buffer:range(offset+2,1)) -- get CHOICE tag
	     if type == 0 then -- charstring
		offset = offset + 2               -- move to the charstring
		len = buffer(offset+1,1):uint()   -- the length of the string
	     end
	     t_dlms:add(buffer(offset+2,len),"CallingAuthenticationValue:",PrintString(len,buffer(offset+2,len)))
	     offset = offset + 2 + len
	     bufferLen = bufferLen - 2 - len
	  end
       end
       if bufferLen > 0 then
	  type = GetTagNumber(buffer:range(offset,1))
	  if type == 30 then                       -- type user information 
	     len = buffer(offset+1,1):uint()       -- the length of the embedded TLV
	     if buffer(offset+2,1):uint() == 0x04 then -- type OCTET STRING
		len = buffer(offset+3,1):uint()        -- the length of the string
		if buffer(offset+4,1):uint() == 0x08 then -- initiateResponse tag
		   offset = offset+4
		   local t_request = t_dlms:add(buffer(offset,len),"UserInformation:","xDLMS-Initiate.response")
		   local item = buffer(offset+1,1):uint() -- OPTIONAL negotiated-quality-of-service
		   t_request:add(buffer(offset+1,1),"NegotiatedQualityOfService:",item)
		   offset=offset+2

		   item = buffer(offset,1):uint()
		   t_request:add(buffer(offset,1),"NegotiatedDLMSversion:",item)
		   offset = offset+1
		   t_request:add(buffer(offset,7),"ProposedConformance:",tostring(buffer(offset,7)))
		   offset = offset+7
		   t_request:add(buffer(offset,2),"ClientMaxReceivedPDUsize:", buffer(offset,2):uint())
		   offset = offset+2
		   t_request:add(buffer(offset,2),"VAAname:", buffer(offset,2):uint())
		end
	     end
	  end
       end
    end
end

-- returns tag number (last 5 bits of the identifier byte) of the TLV
function GetTagNumber (tag)
   return tag:bitfield(3,5)
end

-- returns OID value as a formatted string of 7 bytes
-- expects DLMS prefix 2.16.756.5.8.x.x which has a compact BER encoding
function PrintOID (oid)
   if oid(0,3):uint() == 0x608574 then -- BER encoded OID value 2+16 and 756
      return string.format("2.16.756.%d.%d.%d.%d",oid(3,1):uint(),oid(4,1):uint(),oid(5,1):uint(),oid(6,1):uint())
   else
      return string.format("%d.%d.%d.%d.%d.%d.%d",oid(0,1):uint(),oid(1,1):uint(),oid(2,1):uint(),oid(3,1):uint(),oid(4,1):uint(),oid(5,1):uint(),oid(6,1):uint())
   end
end

-- returns a bit string value from BER encoded BITSTRING
function GetBitStringValue (str)
   local len = str:len()-1            -- no. of bytes with BITSTRING without the unused bits number
   local unused = str(0,1):uint()     -- no. of unused bits (the first byte of the BITSTRING)
   local bitstring = str:range(1,len) -- the value of the BITSTRING
   return bitstring:bitfield(0,len*8-unused)
end

-- returns an ASCII string from a HEX bytes, e
function PrintString (len, str)
   local printable = ""
   for i = 0,len-1,1 do
      printable = printable..string.char(str(i,1):uint())
   end
   return printable
end


-- load the tcp port table
-- tcp_table = DissectorTable.get("tcp.port")
-- register the protocol to port 4061
-- tcp_table:add(4061, dlms_proto)
