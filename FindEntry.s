
# ENTRY NAME MATCHING
# ===================
# exclusively used by FindEntry.

.macro MatchLen LenReg, EntryReg, DoneLabel

    movq \LenReg, %rcx
    cmpq (\EntryReg), %rcx
    jne \DoneLabel

.endm

.macro MatchChar BuffReg, EntryReg, DoneLabel
    ForEachCharacter:		
        movb  -1(\BuffReg, %rcx), %al
        cmpb  7(\EntryReg, %rcx), %al
        jne \DoneLabel
    loop ForEachCharacter
.endm

.macro MatchExactName EntryReg

    MatchLen %r9, \EntryReg, MatchExactNameDone
    MatchChar %r8, \EntryReg, MatchExactNameDone
    MatchExactNameDone:

.endm

# ENTRY TRAVERSING ROUTINES
# =========================
# also execlusively used by FindEntry

.macro GoToFirstEntry EntryReg
    leaq DictStart(%rip), \EntryReg
    GoToNextEntry \EntryReg
.endm

.macro GoToNextEntry EntryReg

    movq -8(\EntryReg), \EntryReg
    GoToEntry \EntryReg
    
.endm

.macro GoToEntry EntryReg
    leaq DictEnd(%rip), %r10
    leaq (%r10, \EntryReg), \EntryReg
.endm

# Let EntryReg stores the address of definition.
# The offset depends on the content between the
# header label and content label.

.macro GoToDefinition EntryReg
    addq (\EntryReg), \EntryReg
    leaq 8(\EntryReg), \EntryReg
.endm

.macro FindEntry EntryReg

    GoToFirstEntry \EntryReg   
 
    ForEachEntry:
        
        cmpq $(0x0), (\EntryReg)
        je LookUpDone

        MatchExactName \EntryReg       
 
            jne NotMatching

        OtherwiseMatching:
           
            push \EntryReg 

                GoToDefinition \EntryReg

                movq \EntryReg, %r13
                jmp  EnterFirstWord

                ExecutionDone:

            pop  \EntryReg
            jmp LookUpDone
        
        NotMatching:
            GoToNextEntry \EntryReg

        jmp ForEachEntry
    LookUpDone:
    
.endm

Find:
    FindEntry %r14
    ret
