Number:
	.ascii "%08X\n"

InputBufferLength:
	.quad   3	
InputBuffer:
        .ascii "All"
	.fill 	64, 1, 0x20 
InputBufferEnd:

.set EntryType.Code,  0x00
.set EntryType.WordSeq, 0x01

StackPointer:
	.quad	0
Stack:
	.rept 	64
	.quad	0
	.endr
StackEnd:
