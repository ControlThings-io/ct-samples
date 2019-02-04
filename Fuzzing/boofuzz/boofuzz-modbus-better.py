from boofuzz import *

session = Session(
    target=Target(connection=SocketConnection('127.0.0.1', 10502, proto='tcp')))

s_initialize('modbus-req')
s_word(1, name='trans_id', endian='>')
s_word(0, name='version', endian='>')
s_size('modbus-pdu', length=2, name='size', endian='>')
if s_block_start('modbus-pdu'):
    s_byte(1, name='unit_id', endian='>', fuzzable=False)
    s_byte(3, name='func', endian='>')
    s_random('\x00\x00\x00\x01', min_length=4, max_length=252, name='func_data')
s_block_end()

session.connect(s_get('modbus-req'))
session.fuzz()
