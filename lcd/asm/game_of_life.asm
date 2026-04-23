; TeenyAT Constants
.const PORT_A_DIR   0x8000
.const PORT_B_DIR   0x8001
.const PORT_A       0x8002
.const PORT_B       0x8003
.const RAND         0x8010
.const RAND_BITS    0x8011

; LCD Peripherals
.const LIVESCREEN 0x9000
.const UPDATESCREEN 0xA000
.const X1 0xD000
.const Y1 0xD001
.const X2 0xD002
.const Y2 0xD003
.const STROKE 0xD010
.const FILL 0xD011
.const DRAWFILL 0xD012
.const DRAWSTROKE 0xD013
.const UPDATE 0xE000
.const RECT 0xE010
.const LINE 0xE011
.const POINT 0xE012
.const MOUSEX 0xFFFC
.const MOUSEY 0xFFFD
.const MOUSEB 0xFFFB
.const TERM 0xFFFF
.const KEY 0xFFFE

.const MOUSE_LEFT 1

.const WHITE 2561

.const DEAD_COLOR 2561
.const ALIVE_COLOR 0

!draw_white_to_screen
    str [X1], rZ            ; store zero into X1 address
    str [Y1], rZ            ; store zero into Y1 address

    set rA, 63      
    str [X2], rA            ; store rA into X2 address
    str [Y2], rA            ; store rA into Y2 address

    str [DRAWSTROKE], rZ    ; storing zero in to DRAWSTROKE means no stroke 

    set rC, DEAD_COLOR
    str [FILL], rC          ; store rC to the FILL address
    str [RECT], rZ          ; blit rectangle to update buffer
    str [UPDATE], rZ        ; swap the display buffers

!initial_setup
; load into registers the state of the mouse
    lod rA, [MOUSEX]        
    lod rB, [MOUSEY]
    lod rC, [MOUSEB]

    cmp rC, MOUSE_LEFT      ; left mouse button is down
    je !set_starting        ; color that pixel to the ALIVE_COLOR

; if key is 'S' jump to the main loop
    lod rD, [KEY]
    cmp rD, 'S'            
    je !main

    jmp !initial_setup


!set_starting
    set rC, ALIVE_COLOR
    str [X1], rA
    str [Y1], rB
    str [STROKE], rC
    str [POINT], rZ
    str [UPDATE], rZ

    jmp !initial_setup

; ---------------------------------------------------------------

!main

    cal !update_cells       ; Calls the update loop for the program 
    str [UPDATE], rZ        ; Swiches buffer with current 

; if key i s 'R' reset the program to the beginning
    lod rD, [KEY]
    cmp rD, 'R'
    je !draw_white_to_screen

    jmp !main

!update_cells
    set rE, 0x1000          ; have rE start at the bottom of the screen

!update_loop

    set rD, rE + LIVESCREEN ; Get pixel index

    lod rA, [rD]            ; Load color of current pixel
    cmp rA, ALIVE_COLOR

    je !its_alive           ; jump if its the alive color

    jmp !its_dead           ; jump if its not the alive color


!update_loop_bottom
    lup rE, !update_loop    ; loop till rE is 0
    ret

!its_alive

; calls the function to get the number of neighbors of the current cell 
; returns count in rA
; expects rD to have current pixel index of LIVESCREEN
    cal !check_neighbors

; if there are two or three neighbors it stays alive
    cmp rA, 2
    je !stays_alive
    cmp rA, 3
    je !stays_alive

; otherwise it either dies due to underpopulation or overpopulation
!dies

; cell dies by changing color to DEAD_COLOR 

    set rC, rE + UPDATESCREEN   ; get relative pixel coords for UPDATESCREEN

    set rA, DEAD_COLOR
    str [STROKE], rA
    str [rC], rA

    jmp !update_loop_bottom

!stays_alive

; cell stays alive by coloring the ALIVE_COLOR

    set rC, rE + UPDATESCREEN   ; get relative pixel coords for UPDATESCREEN

    set rA, ALIVE_COLOR
    str [STROKE], rA
    str [rC], rA

    jmp !update_loop_bottom

!its_dead

; calls the function to get the number of neighbors of the current cell 
; returns count in rA
; expects rD to have current pixel index of LIVESCREEN
    cal !check_neighbors

; if there are exactly 3 neigbors the cell becomes alive
    cmp rA, 3
    jne !update_loop_bottom

!comes_alive

; cell comes alive by coloring the ALIVE_COLOR

    set rC, rE + UPDATESCREEN ; get relative pixel coords for UPDATESCREEN

    set rA, ALIVE_COLOR
    str [STROKE], rA
    str [rC], rA

    jmp !update_loop_bottom


;-----------------------------------------------
!check_neighbors ; Expects rD to have current pixel index, Stores count into rA

    ;index - 65  index - 64  index - 63
    ;index -  1  [cell]      index +  1
    ;index + 63  index + 64  index + 65

    set rA, rZ          ; Reset rA to 0

!check_1

    set rC, rD - 65 ; [-1, -1]

    cmp rC, LIVESCREEN
    jl !check_2

    lod rB, [rC]
    cmp rB, ALIVE_COLOR

    jne !check_2

    cal !increment_count

!check_2

    set rC, rD - 64 ; [0, -1]

    cmp rC, LIVESCREEN
    jl !check_3

    lod rB, [rC]
    cmp rB, ALIVE_COLOR

    jne !check_3    

    cal !increment_count

!check_3

    set rC, rD - 63 ; [+1, -1]
    cmp rC, LIVESCREEN
    jl !check_4

    lod rB, [rC]
    cmp rB, ALIVE_COLOR

    jne !check_4

    cal !increment_count

!check_4

    set rC, rD - 1 ; [-1, 0]

    lod rB, [rC]
    cmp rB, ALIVE_COLOR

    jne !check_5

    cal !increment_count


!check_5

    set rC, rD + 1 ; [+1, 0]

    lod rB, [rC]
    cmp rB, ALIVE_COLOR

    jne !check_6

    cal !increment_count

!check_6

    set rC, rD + 63 ; [-1, +1]

    cmp rC, UPDATESCREEN
    jge !check_7

    lod rB, [rC]
    cmp rB, ALIVE_COLOR

    jne !check_7

    cal !increment_count

!check_7

    set rC, rD + 64 ; [0, +1]

    cmp rC, UPDATESCREEN
    jge !check_8

    lod rB, [rC]
    cmp rB, ALIVE_COLOR

    jne !check_8

    cal !increment_count

!check_8

    set rC, rD + 65 ; [+1, +1]

    cmp rC, UPDATESCREEN
    jge !end_check

    lod rB, [rC]
    cmp rB, ALIVE_COLOR

    jne !end_check

    cal !increment_count

!end_check
    ret

!increment_count
    inc rA
    ret

;-----------------------------------------------


    







    


