
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

 
    ForEachEntry:
        
        cmpq $(0x0), (\EntryReg)
        je LookUpDone

        MatchExactName \EntryReg       
 
            jne NotMatching

           
            push \EntryReg 

                GoToDefinition \EntryReg

                jmp ExecuteLexedWord 

                ExecutionDone:
                    # since we pushed the r13 onto stack
                    # when entering ExecuteLexedWord
                    PopStack %r13

            pop  \EntryReg
            jmp LookUpDone
        
        NotMatching:
            GoToNextEntry \EntryReg

        jmp ForEachEntry
    LookUpDone:
    
.endm

Code CheckEnd
    xorq %rax, %rax
    cmpq $(0x0), (%r11)
    sete %al
    shlq %rax
    PushDataStack %rax
CodeEnd CheckEnd

Code EvaluateEntry

    push %r11 
    GoToDefinition %r11 
    
    jmp ExecuteLexedWord 
    EvaluateDone:
        PopStack %r13
    pop %r11 

CodeEnd EvaluateEntry

Code ReturnLexer 
    .quad RealReturnLexer
RealReturnLexer:
    jmp EvaluateDone 
CodeEnd ReturnLexer

Code MatchName
    xorq %rax, %rax
    MatchExactName %r11
    setne %al
    PushDataStack %rax
CodeEnd MatchName

Code NextEntry
    GoToNextEntry %r11
CodeEnd NextEntry

Word ParseWord
    .quad EnterDict
    .quad Find
WordEnd ParseWord

Word Find
    .quad CheckEnd
    .quad Cond
    .quad MatchAndEval
    .quad LoopLikeForever
WordEnd Find

Word MatchAndEval
    .quad MatchName
    .quad Cond
    .quad EvaluateEntry
    .quad NextEntry
WordEnd MatchAndEval

Code EnterDict
    GoToFirstEntry %r11   
CodeEnd EnterDict
