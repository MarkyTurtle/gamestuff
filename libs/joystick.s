
JOYSTICK_LEFT       EQU     $0
JOYSTICK_RIGHT      EQU     $1
JOYSTICK_UP         EQU     $2
JOYSTICK_DOWN       EQU     $3
JOYSTICK_BUTTON1    EQU     $4
JOYSTICK_BUTTON2    EQU     $5
JOYSTICK_BUTTON3    EQU     $6

                rsreset
controller_struct
stick_state     rs.w    1                   ; joysick state bits.

controller_port1
                dc.w    $0                  ; stick state.

controller_port2
                dc.w    $0                  ; stick state.



            ; IN:
            ;   d0.w - JOY0DAT, or JOY1DAT value
            ;   a0.l - controller_struct
decode_joystick_directions   ; IN: d0.w - JOY0DAT/JOY1DAT, a0.l - controller_struct
                movem.l d1-d2,-(a7)
                moveq.l #0,d1
.chk_left       
                btst.l  #9,d0
                bne.s   .is_left
.chk_right      
                btst.l  #1,d0
                beq.s   .chk_up
                bset.l  #JOYSTICK_RIGHT,d1
                bra.s   .chk_up
.is_left
                bset.l  #JOYSTICK_LEFT,d1
.chk_up
                move.w  d0,d2
                rol.w   #1,d2
                eor.w   d2,d0
                btst.l  #9,d0
                bne.s   .is_up
.chk_down
                btst.l  #1,d0
                beq.s   .store_result
                bset.l  #JOYSTICK_DOWN,d1
                bra.s   .store_result
.is_up
                bset.l  #JOYSTICK_UP,d1
.store_result
                move.w  d1,stick_state(a0)
                movem.l (a7)+,d1-d2
                rts



            ; -------------------- decode joystick port 1 buttons -------------------
            ; IN:
            ;   a6.l - custom base
decode_joystick_port1_buttons
                lea     controller_port1,a0
                moveq.l #0,d1

.chk_button1    btst.b  #6,$bfe001
                bne.s   .chk_button2
.is_button1     bset.l  #JOYSTICK_BUTTON1,d1

.chk_button2    move.w  POTGOR(a6),d0
                btst.l  #10,d0
                bne.s  .chk_button3
.is_button2     bset.l  #JOYSTICK_BUTTON2,d1

.chk_button3    btst.l  #8,d0
                bne.s   .set_state
.is_button3     bset.l  #JOYSTICK_BUTTON3,d1

.set_state      or.w    d1,stick_state(a0)
                rts



            ; -------------------- decode joystick port 2 buttons -------------------
            ; IN:
            ;   a6.l - custom base
decode_joystick_port2_buttons
                lea     controller_port2,a0
                moveq.l #0,d1

.chk_button1    btst.b  #7,$bfe001
                bne.s   .chk_button2
.is_button1     bset.l  #JOYSTICK_BUTTON1,d1

.chk_button2    move.w  POTGOR(a6),d0
                btst.l  #14,d0
                bne.s  .chk_button3
.is_button2     bset.l  #JOYSTICK_BUTTON2,d1

.chk_button3    btst.l  #12,d0
                bne.s   .set_state
.is_button3     bset.l  #JOYSTICK_BUTTON3,d1

.set_state      or.w    d1,stick_state(a0)
                rts



                ; ----------------- debug test controller --------------
                ; flash the screen colours for controller port inputs
                ;
                ; IN:
                ;   a0 - controller port structure ptr
                ;   a1 - debug flags string ptr
                ;
_debug_test_controller
                movem.l d0/a0/a1,-(a7)
                move.w  #$000,_debug_stick_colour(a1)
                move.w  stick_state(a0),d0
.chk_left
                move.b  #'.',_debug_stick_left(a1)
                btst    #JOYSTICK_LEFT,d0
                beq.s   .chk_right
                move.w  #$f00,_debug_stick_colour(a1)
                move.b  #'X',_debug_stick_left(a1)
.chk_right
                move.b  #'.',_debug_stick_right(a1)
                btst    #JOYSTICK_RIGHT,d0
                beq.s   .chk_up
                move.w  #$0f0,_debug_stick_colour(a1)
                move.b  #'X',_debug_stick_right(a1)
.chk_up
                move.b  #'.',_debug_stick_up(a1)
                btst    #JOYSTICK_UP,d0
                beq.s   .chk_down
                move.w  #$00f,_debug_stick_colour(a1)
                move.b  #'X',_debug_stick_up(a1)
.chk_down
                move.b  #'.',_debug_stick_down(a1)
                btst    #JOYSTICK_DOWN,d0
                beq.s   .chk_button_1
                move.w  #$ff0,_debug_stick_colour(a1)
                move.b  #'X',_debug_stick_down(a1)
.chk_button_1
                move.b  #'.',_debug_stick_but1(a1)
                btst    #JOYSTICK_BUTTON1,d0
                beq.s   .chk_button_2
                move.w  #$fff,_debug_stick_colour(a1)
                move.b  #'X',_debug_stick_but1(a1)
.chk_button_2
                move.b  #'.',_debug_stick_but2(a1)
                btst    #JOYSTICK_BUTTON2,d0
                beq.s   .chk_button_3
                move.w  #$0ff,_debug_stick_colour(a1)
                move.b  #'.',_debug_stick_but2(a1)
.chk_button_3
                move.b  #'.',_debug_stick_but3(a1)
                btst    #JOYSTICK_BUTTON3,d0
                beq.s   .continue
                move.w  #$f0f,_debug_stick_colour(a1)
                move.b  #'.',_debug_stick_but3(a1)
.continue
                movem.l (a7)+,d0/a0/a1
                rts

                    rsreset
_debug_stick_colour rs.w    1
_debug_stick_up     rs.b    1
_debug_stick_down   rs.b    1
_debug_stick_left   rs.b    1
_debug_stick_right  rs.b    1
_debug_stick_but1   rs.b    1
_debug_stick_but2   rs.b    1
_debug_stick_but3   rs.b    1

                even
_debug_joystick_input_1
                dc.w    $0000               ; debug colour
                dc.b    ".......",0         ; directional debug flags (up,down,left,right,button1,button2,button3)   
                even
_debug_joystick_input_2
                dc.w    $0000               ; debug colour
                dc.b    ".......",0         ; directional debug flags (up,down,left,right,button1,button2,button3)   
                even

