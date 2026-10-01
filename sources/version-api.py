"""Public version reporting only; retain status and private driver ABI version."""
import struct
def nvapi_patches(original):
 # GetDisplayDriverVersion validated buffer/version/handle before its backend
 # call. At this epilogue ESI is the unmodified result, EDI the validated buffer.
 # Relabel only a successful 36881 result. Errors and other drivers pass through.
 hook=0x870b9;cave=0x294e40;bias=0xc00
 body=bytes.fromhex('9c 85f6 7510 817f0411900000 7507 c747047d950000 9d 8bc6 8b4df4')
 assert len(body)==27
 stub=body+b'\xe9'+struct.pack('<i',(hook+5)-(cave+len(body)+5))
 pe=struct.unpack_from('<I',original,60)[0];sec=pe+24+struct.unpack_from('<H',original,pe+20)[0]
 vs=struct.unpack_from('<I',original,sec+8)[0];va=struct.unpack_from('<I',original,sec+12)[0];raw=struct.unpack_from('<I',original,sec+20)[0]
 assert (vs,va,raw)==(2705966,4096,1024)
 assert cave>=raw+vs and cave+len(stub)<=0x295000
 assert original[cave:cave+len(stub)]==bytes(len(stub))
 return [(0x183fde,struct.pack('<I',36881),struct.pack('<I',38269),'SYS_GetDriverAndBranchVersion public output'),
 (hook,bytes.fromhex('8bc68b4df4'),b'\xe9'+struct.pack('<i',cave-(hook+5)),'GetDisplayDriverVersion validated epilogue to reporting stub'),
 (cave,bytes(len(stub)),stub,'Relabel only success+36881; preserve status/flags/non-version data'),
 (sec+8,struct.pack('<I',vs),struct.pack('<I',cave+len(stub)-raw),'Extend executable virtual size into existing zero raw alignment padding')]
