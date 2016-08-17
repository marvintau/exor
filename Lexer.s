# LOCATE WORD BOUND
# =====================================================
# A register holds the address of last char decrease every
# time and checks two consecutive chars (a bigram) at that
# position. If a bigram wit "C_" pattern is found, then
# assign the address to EndReg, and if a bigram with "_C"
# found, then leave the subroutine, and the current char
# position (StartReg) along with the end position (EndReg)
# will be used in the next stage.

.macro LocateWordBound StartReg, EndReg

    leaq InputBuffer(%rip), %rax 

    NextBigram:
        cmpq \StartReg, %rax 
        je   WordLocated

        cmpb $(0x20), (\StartReg)
        je   StartWithSpace
        jne  StartWithChar

        StartWithSpace:
            cmpb $(0x20), -1(\StartReg)
            je  MoveCurr 

            CharNext:
                movq \StartReg, \EndReg
                jmp MoveCurr 

        StartWithChar:
            cmpb $(0x20), -1(\StartReg) 
            jne MoveCurr 

            SpaceNext:

                jmp WordLocated

        MoveCurr:

            decq \StartReg
        
        jmp NextBigram 

    WordLocated:
        subq \StartReg, \EndReg
.endm



# Initialize 
# =====================
# r8 always stores the starting of Input buffer, yet
# r9 always stores the length of the buffer.

Code InitLocateWord
    movq BufferAddressRegister(%rip), %r8
    addq InputBufferLength(%rip), %r8
CodeEnd InitLocateWord

Code ScanInputBuffer
    movq    $SyscallRead, %rax
    movq    $(0), %rdi
    movq    BufferAddressRegister(%rip), %rsi
    movq    $(InputBufferEnd - InputBuffer), %rdx
    syscall

    decq    %rax
    movq    $(0x20), (%rsi, %rax)

    movq    %rax, InputBufferLength(%rip)
CodeEnd ScanInputBuffer

Code LocateWordBound
    LocateWordBound %r8, %r9 
CodeEnd LocateWordBound

Code BufferEndNotReached
    leaq InputBuffer(%rip), %r9 
    cmpq %r8, %r9
    je Reached
        decq %r8
        movq $(0x1), %rax
        jmp ReachedDone
    Reached:    
        movq $(0x0), %rax
    ReachedDone:
        PushDataStack %rax
CodeEnd BufferEndNotReached 

Word ExecuteSession
    # %r8 as Buffer Start Register, which holds the starting position
    # where lexer starts (which actually is the end of buffer). While
    # %r9 the Buffer End register, which sometimes holds the position
    # where the word starts, sometimes holds the length of the word
    
    .quad LocateWordBound
    .quad ParseWord
    .quad BufferEndNotReached 
    .quad LoopWhile

WordEnd ExecuteSession

Word InitScan
    .quad InitLocateWord
    .quad ExecuteSession
WordEnd InitScan
