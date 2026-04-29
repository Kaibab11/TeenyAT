.const PORT_A_DIR 0x8000
.const PORT_B_DIR 0x8001
.const PORT_A 0x8002
.const PORT_B 0x8003
.const RAND 0x8010
.const RAND_BITS 0x8011

.const LCD_CURSOR 0xA000 
.const LCD_CLEAR_SCREEN 0xA001
.const LCD_MOVE_LEFT 0xA002  
.const LCD_MOVE_RIGHT 0xA003
.const LCD_MOVE_UP 0xA004
.const LCD_MOVE_DOWN 0xA005
.const LCD_MOVE_LEFT_WRAP 0xA006  
.const LCD_MOVE_RIGHT_WRAP 0xA007
.const LCD_MOVE_UP_WRAP 0xA008
.const LCD_MOVE_DOWN_WRAP 0xA009
.const LCD_CURSOR_X 0xA00A
.const LCD_CURSOR_Y 0xA00B
.const LCD_CURSOR_XY 0xA00C
.const BUZZER_LEFT 0xA010
.const BUZZER_RIGHT 0xA011
.const FADER_LEFT 0xA020
.const FADER_RIGHT 0xA021

.const LEROY_1 0xD1
.const LEROY_2 0xD3
.const DELAY_AMT 375

.const WALL 0x84
.const COIN 0xBA

    jmp !init_demo

.var flipped_flag 0
.var score 0  

!init_demo

    cal !maze_init
    cal !coin_spawn
; Set port A to input mode
    set rE, 0xFFFF 
    str [PORT_A_DIR], rE

    set rA, 0
    set rB, 0
    str [LCD_CURSOR_XY], rZ

!main

    cal !draw_leroy
    cal !delay
    cal !move_check
    jmp !main

!draw_leroy
    lod rE, [LCD_CURSOR_XY]

    set rC, LEROY_1
    str [LCD_CURSOR], rC

    str [LCD_CURSOR_XY], rE
    ret

!move_check

    set rA, 1
    set rB, 4

    lod rC, [PORT_A]
    and rC, 0xF
    cmp rC, rZ
    je !check_loop_done

!check_loop

    set rD, rC
    and rD, rA

    cmp rD, rA
    je !move_detected 

    shr rC, 1
    lup rB, !check_loop

!check_loop_done
    ret

!move_detected

    lod rE, [LCD_CURSOR_XY]

    lod rD, [rB + !MOVES]
    lod rC, [rD]
    ;lod rC, [LCD_MOVE_RIGHT_WRAP] ;Don't know if this is my code or a bug, but this does not "peek" as its supposed to so i have to reset the cursor after
    cmp rC, WALL

    str [LCD_CURSOR_XY], rE
    je !check_loop_done

    lod rE, [LCD_CURSOR_XY]
    str [LCD_CURSOR], rZ
    str [LCD_CURSOR_XY], rE
    
    set rA, 1
    lod rD, [rB + !MOVES]
    str [rD], rA

    cmp rC, COIN
    jne !check_loop_done

!coin_collected
    lod rA, [score]
    inc rA

    str [PORT_B], rA
    str [score], rA

    cal !coin_spawn
    jmp !check_loop_done

;-------------Delay ---------------------

!delay
    set rE, 0
    set rD, DELAY_AMT                       
!inner_delay_loop
    inc rE
    dly rE
    cmp rE, rD          
    jl !inner_delay_loop
    ret

;-------------COIN SPAWNING---------------------
!coin_spawn
    ;psh rE
    lod rE, [LCD_CURSOR_XY]

!spawn_loop

    lod rA, [RAND]
    lod rB, [RAND]

    mod rA, 20
    mod rB, 4

    str [LCD_CURSOR_X], rA      ; x-coordinate
    str [LCD_CURSOR_Y], rB      ; y-coordinate

    lod rA, [LCD_CURSOR]     
    cmp rA, WALL
    je !spawn_loop

    set rA, COIN
    str [LCD_CURSOR], rA

    str [LCD_CURSOR_XY], rE

    ;pop rE
    ret

;------------- MAZE DRAWING ---------------------

!maze_init

    set rC, WALL
    set rB, 0
    set rE, 0
    cal !draw_walls
    ret
    
!draw_walls

    lod rA, [rE + !WAll_ROWS]

    cmp rA, 100
    je !draw_walls_inc_Y

    str [LCD_CURSOR_X], rA
    str [LCD_CURSOR_Y], rB
    str [LCD_CURSOR], rC

    inc rE
    jmp !draw_walls

!draw_walls_inc_Y
    inc rE
    inc rB
    cmp rB, 4
    jne !draw_walls

!draw_walls_end
    ret

;------------- DATA SECTION ---------------------

!WAll_ROWS
.raw 4 5 14 15 100 1 8 9 10 11 18 100 1 8 9 10 11 18 100 4 5 14 15 100

!MOVES
.raw 0xBEEF LCD_MOVE_DOWN_WRAP LCD_MOVE_RIGHT_WRAP LCD_MOVE_UP_WRAP LCD_MOVE_LEFT_WRAP

