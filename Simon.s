.data
subtractedSpeed:     .word 0 #Enhancement B-2: Stores a negative number which is added to the time delayed for lights.
count:     .word 4

.globl main
.text

main:
    # For this Simon version, the sequence increasing enhancement and the decreasing the time
    # between flashes are the enhancements implemented.  Programming for each enhancement 
    # is documentation near where it occurs with either "Enhancement A-1" or 
    # "Enhancement B-2".
    
    # Before we deal with the LEDs, we need to generate a random
    # sequence of numbers that we will use to indicate the button/LED
    # to light up. For example, we can have 0 for UP, 1 for DOWN, 2 for
    # LEFT, and 3 for RIGHT. Store the sequence in memory. We provided 
    # a declaration above that you can use if you want.
    # HINT: Use the rand function provided to generate each number
    sequenceLOOP:
        li s0, 0
        li s2, 4 # Possible light values for sequence and max values we can store in sequence
        
        # Enhancemnet A-1: Loads the memory address into s3 to use as the heap so that the
        # Sequence can be indefinately long. Also loads count into s1, this count is for the
        # number of lights to be randomized (Used in the sequenceWHILE loop exit flag).
        lw s1, count
        li s3, 0x10000008
        
        sequenceWHILE:
            beq s0, s1 repeatLOOP
            mv a0, s2
            jal rand
            sb a0, 0(s3)
            addi s3, s3, 1
            addi s0, s0, 1
            j sequenceWHILE
   
    # TODO: Now read the sequence and replay it on the LEDs. You will
    # need to use the delay function to ensure that the LEDs light up 
    # slowly. In general, for each number in the sequence you should:
    # 1. Figure out the corresponding LED location and colour
    # 2. Light up the appropriate LED (with the colour)
    # 2. Wait for a short delay (e.g. 500 ms)
    # 3. Turn off the LED (i.e. set it to black)
    # 4. Wait for a short delay (e.g. 1000 ms) before repeating
    
    repeatLOOP:
    li s3 0x10000008
    lw s1, count
    li s0, 0
    li s4, 0 #UP
    li s5, 1 #DOWN
    li s6, 2 #LEFT
    li s7, 3 #RIGHT
    lw s8, subtractedSpeed # Enhancement B-2: Loads subtractedSpeed to s8 register
    
    repeatWHILE:
        beq s0, s1, repeatEND
        lb s2, (0)s3
        ifUP: #Red
            bne s2, s4, ifLEFT
            li a0, 0xff0000 # Load colour red into a0
            li t4, 0
            li t5, 0
            mv a1, t4
            mv a2, t5
            jal setLED
            j FINAL
        ifLEFT: #Yellow
            bne s2, s6, ifDOWN
            li a0, 0xffff00 # Load colour yellow into a0 
            li t4, 0
            li t5, 1
            mv a1, t4 
            mv a2, t5
            jal setLED
            j FINAL  
        ifDOWN: #Green
            bne s2, s5, elseRIGHT
            li a0, 0x00ff00 # Load colour green into a0 
            li t4, 1
            li t5, 1
            mv a1, t4
            mv a2, t5
            jal setLED
            j FINAL
            
        elseRIGHT: #Blue
            li a0, 0x0000ff # Load colour blue into a0 
            li t4, 1
            li t5, 0
            mv a1, t4 
            mv a2, t5
            jal setLED
        FINAL:
            # Delay for 500ms
            li a0 500
            add a0, a0, s8 # Enhancement B-2: adds the value of subtractedSpeed to decrease delay.
            jal delay
            # Switch colour to black (0, 0, 0) for LED at t4,t5
            li a0, 0x000000 
            mv a1, t4
            mv a2, t5
            jal setLED
            # Delay for 1000ms # Enhancement B-2: adds the value of subtractedSpeed to decrease delay.
            li a0 1000
            add a0, a0, s8 
            jal delay
            
            addi s3, s3, 1
            addi s0, s0, 1
            j repeatWHILE
    
    repeatEND:
        li a0 3000 # wait for another 3 seconds (with earlier 1 second is approximately 4 seconds)
        
        #Flash all lights white

        li a0, 0xffffff
        jal flashAll
        
        li a0, 250
        jal delay
        
        li a0, 0x000000
        jal flashAll
        
    
    # Read through the sequence again and check for user input
    # using pollDpad. For each number in the sequence, check the d-pad
    # input and compare it against the sequence. If the input does not
    # match, display some indication of error on the LEDs and exit. 
    # Otherwise, keep checking the rest of the sequence and display 
    # some indication of success once you reach the end.
    
    inputLOOPINIT:
        li s0, 0
        lw s1, count
        li s3, 0x10000008
        li s11, 1 # Will continue to be 1 as long as the values are correct
        
    inputLOOP:
        beq s0, s1, inputEND
        lb s10, 0(s3)
            
        jal pollDpad
        mv s2, a0 
            
        ifPressedUP: #Red
            bne s2, s4, ifPressedLEFT
            li a0, 0xff0000 # Load colour red into a0
            li t4, 0
            li t5, 0
            mv a1, t4
            mv a2, t5
            jal setLED
            j inputFINAL
        ifPressedLEFT: #Yellow
            bne s2, s6, ifPressedDOWN
            li a0, 0xffff00 # Load colour yellow into a0 
            li t4, 0
            li t5, 1
            mv a1, t4
            mv a2, t5
            jal setLED
            j inputFINAL  
        ifPressedDOWN: #Green
            bne s2, s5, elsePressedRIGHT
            li a0, 0x00ff00 # Load colour green into a0 
            li t4, 1
            li t5, 1
            mv a1, t4
            mv a2, t5
            jal setLED
            j inputFINAL
            
        elsePressedRIGHT: #Blue
            li a0, 0x0000ff # Load colour blue into a0 
            li t4, 1
            li t5, 0
            mv a1, t4 
            mv a2, t5
            jal setLED
                
            inputFINAL:
            
            IFbadSequence:
                beq s2, s10, inputContinue
                li s11, 0
                
            inputContinue:
                # Delay for 500ms
                li a0 300
                jal delay
                
                # Switch colour to black (0, 0, 0) for LED at t4,t5
                li a0, 0x000000 
                mv a1, t4
                mv a2, t5
                jal setLED
                addi s3, s3, 1
                addi s0, s0, 1
                j inputLOOP
                          
        inputEND:
            li a0, 250
            jal delay
            li s0, 1
            IFIncorrectSequence:
                beq s11, s0, ELSECorrectSequence
                li a0 0xff0000
                jal flashAll
                li a0 100
                jal delay
                li a0 0x000000
                jal flashAll
                li a0 100
                jal delay
                li a0 0xff0000
                jal flashAll
                li a0 200
                jal delay
                li a0 0x000000
                jal flashAll
                j playAgain
                
            ELSECorrectSequence:
                li a0, 0x00ff00
                li a1, 0
                li a2, 0
                jal setLED
                li a0, 200
                jal delay
                li a0, 0x000000
                li a1, 0
                li a2, 0
                jal setLED
                li a0, 0x00ff00
                li a1, 0
                li a2, 1
                jal setLED
                li a0, 200
                jal delay
                li a0, 0x000000
                li a1, 0
                li a2, 1
                jal setLED
                li a0, 0x00ff00
                li a1, 1
                li a2, 1
                jal setLED
                li a0, 200
                jal delay
                li a0, 0x000000
                li a1, 1
                li a2, 1
                jal setLED
                li a0, 0x00ff00
                li a1, 1
                li a2, 0
                jal setLED
                li a0, 400
                jal delay
                li a0, 0x000000
                li a1, 1
                li a2, 0
                jal setLED
                li a0, 0x00ff00
                li a1, 1
                li a2, 1
                jal setLED
                li a0, 200
                jal delay
                li a0, 0x000000
                li a1, 1
                li a2, 1
                jal setLED
                li a0, 0x00ff00
                li a1, 1
                li a2, 0
                jal setLED
                li a0, 600
                jal delay
                li a0, 0x000000
                li a1, 1
                li a2, 0
                jal setLED

    # Ask if the user wishes to play again and either loop back to
    # start a new round or terminate, based on their input.
    
    playAgain:
        li a0, 250
        jal delay
        
        li a0, 0x00ff00
        li a1, 0
        li a2, 0
        jal setLED
        
        li a0, 400
        jal delay
        
        li a0, 0xff0000
        li a1, 1
        li a2, 1
        jal setLED
        
        li a0, 200
        jal delay
        
        li s4, 0 #UP
        li s5, 1 #DOWN
        
        SELECTION:
            jal pollDpad
            mv s0, a0
            
            IFPlayAgain:
                bne s4, s0, IFExit
                li a0, 0x000000
                jal flashAll
                
                li s0, 0
                IFCorrect:
                    # Enhancements A-1 and B-2: If the user was correct on the last run, then the count
                    # is incremented to increase sequence size. Also, if the speed can be reduced (subtractedSpeed != -450)
                    # then the value of subtractedSpeed is subtracted by 50 and stored in memory in the same spot.
                    beq s11, s0, noIncrease
                    # Increment count at its memory address, this 
                    li s0, 0x10000004
                    lw s1, count 
                    addi s1, s1, 1
                    sw s1, 0(s0)
                
                    #Check to see if s8 can have its speed reduced (Won't happen if s8 = -450 as then delay is 0)
                    li s0, 0x10000000
                    li s1, -450
                    IFSpeedNotTooLow:
                        beq s8, s1, noIncrease
                        addi s8, s8, -50
                        sw s8, 0(s0)
                noIncrease:
                    
                j main
            IFExit:
                bne s5, s0, SELECTION
                li a0, 0x000000
                jal flashAll
                j exit
exit:
    li a7, 10
    ecall
    
# ---- My Helpers ----

# a0 contains colour to flash
flashAll: 
    li a4, 0
    li a6, 2
    addi sp, sp, -4
    sw ra, 0(sp)
    outerLoop:
        beq a4, a6, outerEnd
        li a5, 0
        innerLoop:
            beq a5, a6, innerEnd
            mv a1, a4
            mv a2, a5
            jal setLED
            addi a5, a5, 1
            j innerLoop
        innerEnd:
            addi a4, a4, 1
            j outerLoop
    outerEnd:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra
    
# --- HELPER FUNCTIONS ---
# Feel free to use (or modify) them however you see fit
     
# Takes in the number of milliseconds to wait (in a0) before returning
delay:
    mv t0, a0
    li a7, 30
    ecall
    mv t1, a0
delayLoop:
    ecall
    sub t2, a0, t1
    bgez t2, delayIfEnd
    addi t2, t2, -1
delayIfEnd:
    bltu t2, t0, delayLoop
    jr ra

# Takes in a number in a0, and returns a (sort of) random number from 0 to
# this number (exclusive)
rand:
    mv t0, a0
    li a7, 30
    ecall
    remu a0, a0, t0
    jr ra
    
# Takes in an RGB color in a0, an x-coordinate in a1, and a y-coordinate
# in a2. Then it sets the led at (x, y) to the given color.
setLED:
    li t1, LED_MATRIX_0_WIDTH
    mul t0, a2, t1
    add t0, t0, a1
    li t1, 4
    mul t0, t0, t1
    li t1, LED_MATRIX_0_BASE
    add t0, t1, t0
    sw a0, (0)t0
    jr ra
    
# Polls the d-pad input until a button is pressed, then returns a number
# representing the button that was pressed in a0.
# The possible return values are:
# 0: UP
# 1: DOWN
# 2: LEFT
# 3: RIGHT
pollDpad:
    mv a0, zero
    li t1, 4
pollLoop:
    bge a0, t1, pollLoopEnd
    li t2, D_PAD_0_BASE
    slli t3, a0, 2
    add t2, t2, t3
    lw t3, (0)t2
    bnez t3, pollRelease
    addi a0, a0, 1
    j pollLoop
pollLoopEnd:
    j pollDpad
pollRelease:
    lw t3, (0)t2
    bnez t3, pollRelease
pollExit:
    jr ra
