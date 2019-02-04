from boofuzz import *

session = Session(
    target=Target(
        connection=SocketConnection('127.0.0.1', 10502, proto='tcp')))

s_initialize('modbus-req')
s_static('\x00\x01', name='trans_id')
s_static('\x00\x00', name='version')
s_static('\x00\x06', name='bytes')
s_static('\x01', name='unit_id')
s_string('\x03', name='func')
s_string('\x00\x00', name='address')
s_string('\x00\x01', name='count')

session.connect(s_get('modbus-req'))
session.fuzz()
