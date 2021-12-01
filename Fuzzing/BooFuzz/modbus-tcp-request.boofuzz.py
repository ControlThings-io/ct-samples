from boofuzz import Target, Session, TCPSocketConnection, Request, Word, Size, Block, Byte, RandomData

IP = '127.0.0.1'
PORT = 10502
UNIT_ID = 1

target = Target(connection = TCPSocketConnection(IP, PORT))
session = Session(target = target)

request = Request('Modbus_Request', children=(
    Word(name='Trans_ID', default_value=1, endian='>', fuzzable=False),
    Word(name='Version', default_value=0, endian='>', fuzzable=False),
    Size(name='Size', block_name='Modbus_PDU', length=2, endian='>', fuzzable=False),
    Block(name='Modbus_PDU', children=(
        Byte(name='Unit_ID', default_value=UNIT_ID, endian='>', fuzzable=False),
        Byte(name='Function', default_value=3, full_range=True, endian='>'),
        RandomData(name='Func_Data', default_value='\x00\x00\x00\x01', max_length=256, step=4),
        ))
    ))

session.connect(request)
session.fuzz()