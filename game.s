
                section main,code_c


            ;--------------------- includes and constants ---------------------------
                INCDIR      "include"
                INCLUDE     "hw.i"


TEST_BUILD           EQU    1             ; comment out for release build

              IFD    TEST_BUILD
STACK_SIZE      equ     1024              ; 1kb stack
STACK_PTR       equ     stack+STACK_SIZE
              ELSE
STACK_SIZE      equ     0                 ; 1kb stack
STACK_PTR       equ     stack+STACK_SIZE
              ENDC


            ; --------------------- code entry point --------------------
start
              jmp     startup


            ; ----------------------- stack memory ----------------------
            ; todo: put this in fast-memory if available
            ;
              even
stack         dcb.b   STACK_SIZE,0


            ;-------------------------- start up ------------------------
            ; initialise the system, set up intterupts etc
            ;
startup:
            ; todo: detect processor type, memory layout, chip versions 
            ; todo: wait for vertical blank before disabling sprite DMA
              lea     $dff000,a6
              move.w  #$7fff,INTENA(a6)
              move.w  #$7fff,DMACON(a6)
              move.w  #$7fff,INTREQ(a6)
              move.w  #$7fff,INTREQ(a6)

            ; enter supervisor mode
              lea     STACK_PTR,a7
              lea     supervisor,a0
              move.l  a0,$80.w
              trap    #0
supervisor
            ; initialise the stack ptr
              lea     STACK_PTR,a7

            ; set default exception handlers $08.w - $60.w
              lea     default_exception_handler,a0
              lea     $08.w,a1
              move.w  #22,d7                  ; 23 entries
.set_loop      move.l  a0,(a1)+
              dbra    d7,.set_loop


            ; set interrupt handlers
              lea     level1_interrupt_handler,a0
              move.l  a0,$64.w
              lea     level2_interrupt_handler,a0
              move.l  a0,$68.w
              lea     level3_interrupt_handler,a0
              move.l  a0,$6c.w
              lea     level4_interrupt_handler,a0
              move.l  a0,$70.w
              lea     level5_interrupt_handler,a0
              move.l  a0,$74.w
              lea     level6_interrupt_handler,a0
              move.l  a0,$78.w
              lea     level7_interrupt_handler,a0
              move.l  a0,$7c.w


            ; set trap vectors
              lea     default_trap_handler,a0
              move.l  a0,$80.w
              move.l  a0,$84.w
              move.l  a0,$88.w
              move.l  a0,$8c.w
              move.l  a0,$90.w
              move.l  a0,$94.w
              move.l  a0,$98.w
              move.l  a0,$9c.w
              move.l  a0,$a0.w
              move.l  a0,$a4.w
              move.l  a0,$a8.w
              move.l  a0,$ac.w
              move.l  a0,$b0.w
              move.l  a0,$b4.w
              move.l  a0,$b8.w
              move.l  a0,$bc.w

            ; enable interrupts
              move.w  #$C020,INTENA(a6)       ; enable vertb  

            ; enable joystick buttons
              move.w  #$ff00,POTGO(a6)

            ; intialise copper display
              jsr     init_copper_display

            ; set up copper list
              lea     copper_list_1,a0
              move.l  a0,COP1LC(a6)
              move.w  #$8280,DMACON(a6)


              move.w  #$8300,DMACON(a6)   ; enable bitplane dma
              ;move.w  #$8240,DMACON(a6)   ; enable blitter dma

loop
              jmp     loop


                ; default processor exception handler
default_exception_handler
              move.w  #$0000,d0
.loop         move.w  d0,$dff180
              add.w   #$0001,d0
              jmp     .loop


                ; default trap instruction handler
default_trap_handler
              rte


                ; serial transmit buffer empty (intreq bit 00)
                ; disk block finished (intreq bit 01)
                ; software interrupt (intreq bit 02)
level1_interrupt_handler
              movem.l d0-d7/a0-a6,-(a7)
              lea     $dff000,a6

                ; clear the interrupt (level 1 only)
              move.w  INTREQ(a6),d0
              and.w   #%0000000000000111,d0
              move.w  d0,INTREQR(a6)

              movem.l (a7)+,d0-d7/a0-a6
              rte



                ; io ports and timers (intreq bit 03) 
level2_interrupt_handler
              movem.l d0-d7/a0-a6,-(a7)
              lea     $dff000,a6

                ; clear the interrupt (level 1 only)
              move.w  INTREQ(a6),d0
              and.w   #%0000000000001000,d0
              move.w  d0,INTREQR(a6)

              movem.l (a7)+,d0-d7/a0-a6
              rte


test_color      dc.w    $0
frame_count     dc.w    $0
                ; copper (intreq bit 04)
                ; vertical blank (intreq bit 05)
                ; blitter (intreq bit 06)
level3_interrupt_handler
                movem.l d0-d7/a0-a6,-(a7)
                lea     $dff000,a6

                move.w  #$0f0,COLOR00(a6)

                add.w   #$1,frame_count
                move.w  frame_count,d0
                btst.l  #0,d0
                beq.s   .even_frame
.odd_frame
                move.l  #copper_list_1,copper_ptr
                move.l  #copper_bpl_1,copper_bpl_ptr                        ;dc.l    copper_bpl_1
                move.l  #copper_wrap_wait_1,copper_wrap_wait_ptr            ; dc.l    copper_wrap_wait_1
                move.l  #copper_wrap_bpl_wait_1,copper_wrap_bpl_wait_ptr    ;dc.l    copper_wrap_bpl_wait_1
                move.l  #copper_list_1,COP1LC(a6)
                bra     .end_frame_stuff
.even_frame
                move.l  #copper_list_1,copper_ptr
                move.l  #copper_bpl_1,copper_bpl_ptr                        ;dc.l    copper_bpl_1
                move.l  #copper_wrap_wait_1,copper_wrap_wait_ptr            ; dc.l    copper_wrap_wait_1
                move.l  #copper_wrap_bpl_wait_1,copper_wrap_bpl_wait_ptr    ;dc.l    copper_wrap_bpl_wait_1
                move.l  #copper_list_1,COP1LC(a6)
.end_frame_stuff

              ;add.w   #$1,test_color
              ;move.w  test_color,d0
              ;move.w  d0,$dff180

                ; get joystick port 1
                move.w  JOY0DAT(a6),d0
                lea     controller_port1,a0
                jsr     decode_joystick_directions
                jsr     decode_joystick_port1_buttons

                ; get joystick port 2
                move.w  JOY1DAT(a6),d0
                lea     controller_port2,a0
                jsr     decode_joystick_directions
                jsr     decode_joystick_port2_buttons

                ; vertical scroll
                jsr     vertical_scroll


            move.w  #$000,COLOR00(a6)

                ; clear the interrupt (level 3 only)
              move.w  INTREQR(a6),d0
              and.w   #%0000000001110000,d0
              move.w  d0,INTREQ(a6)

              movem.l (a7)+,d0-d7/a0-a6
              rte


                ; audio 0-3 (intreq bits 07-10)
level4_interrupt_handler
              movem.l d0-d7/a0-a6,-(a7)
              lea     $dff000,a6

              ; clear the interrupt (level 4 only)
              move.w  INTREQ(a6),d0
              and.w   #%0000011110000000,d0
              move.w  d0,INTREQR(a6)

              movem.l (a7)+,d0-d7/a0-a6
              rte



                ; serial receive buffer (intreq bit 11)
                ; disk sync (intreq bit 12)
level5_interrupt_handler
              movem.l d0-d7/a0-a6,-(a7)
              lea     $dff000,a6

              ; clear the interrupt (level 5 only)
              move.w  INTREQ(a6),d0
              and.w   #%0001100000000000,d0
              move.w  d0,INTREQR(a6)

              movem.l (a7)+,d0-d7/a0-a6
              rte



                ; external ciab B flag (disk index) (intreq bit 13)
level6_interrupt_handler
              movem.l d0-d7/a0-a6,-(a7)
              lea     $dff000,a6

              ; clear the interrupt (level 6 only)
              move.w  INTREQ(a6),d0
              and.w   #%0010000000000000,d0
              move.w  d0,INTREQR(a6)

              movem.l (a7)+,d0-d7/a0-a6
              rte


                ; external ciab B flag (disk index) (intreq bit 13)
level7_interrupt_handler
              movem.l d0-d7/a0-a6,-(a7)
              lea     $dff000,a6

              ; clear the interrupt (level 6 only)
              move.w  INTREQ(a6),d0
              and.w   #%0010000000000000,d0
              move.w  d0,INTREQR(a6)

              movem.l (a7)+,d0-d7/a0-a6
              rte


copper_ptr                  dc.l    copper_list_1
copper_bpl_ptr              dc.l    copper_bpl_1
copper_wrap_wait_ptr        dc.l    copper_wrap_wait_1
copper_wrap_bpl_wait_ptr    dc.l    copper_wrap_bpl_wait_1


            ; -------------------------- copper list ------------------------
            ; program copper list for managine the screen display.
copper_list_1
                dc.w    DIWSTRT,$2c81            ; default PAL window start
                dc.w    DIWSTOP,$2cc1            ; default PAL window stop
                dc.w    DDFSTRT,$0038            ; default lowres data fetch
                dc.w    DDFSTOP,$00d0            ; default lowres data stop
copper_bplcon_1 dc.w    BPLCON0,$0000            ; reset/switch off all display controll settings
                dc.w    BPLCON1,$0000
                dc.w    BPLCON2,$0000
                dc.w    BPLCON3,$0000
                dc.w    BPLCON4,$0000
                dc.w    FMODE,$0000              ; reset aga fetch mode (if available)
copper_bpl_1    dc.w    BPL1PTL,$0000
                dc.w    BPL1PTH,$0000
                dc.w    BPL2PTL,$0000
                dc.w    BPL2PTH,$0000
                dc.w    BPL3PTL,$0000
                dc.w    BPL3PTH,$0000
                dc.w    BPL4PTL,$0000
                dc.w    BPL4PTH,$0000
                dc.w    BPL5PTL,$0000
                dc.w    BPL5PTH,$0000
                dc.w    BPL1MOD,$0000 
                dc.w    BPL2MOD,00000
copper_colors_1 dc.w    COLOR00,$000
                dc.w    COLOR01,$000
                dc.w    COLOR02,$000
                dc.w    COLOR03,$000
                dc.w    COLOR04,$000
                dc.w    COLOR05,$000
                dc.w    COLOR06,$000
                dc.w    COLOR07,$000
                dc.w    COLOR08,$000
                dc.w    COLOR09,$000
                dc.w    COLOR10,$000
                dc.w    COLOR11,$000
                dc.w    COLOR12,$000
                dc.w    COLOR13,$000
                dc.w    COLOR14,$000
                dc.w    COLOR15,$000
                dc.w    COLOR16,$000
                dc.w    COLOR17,$000
                dc.w    COLOR18,$000
                dc.w    COLOR19,$000
                dc.w    COLOR20,$000
                dc.w    COLOR21,$000
                dc.w    COLOR22,$000
                dc.w    COLOR23,$000
                dc.w    COLOR24,$000
                dc.w    COLOR25,$000
                dc.w    COLOR26,$000
                dc.w    COLOR27,$000
                dc.w    COLOR28,$000
                dc.w    COLOR29,$000
                dc.w    COLOR30,$000
                dc.w    COLOR31,$000
copper_wrap_wait_1
                dc.w    $ffdf,$fffe                     ; wait required if wrapping inside the PAL screen area
                dc.w    COLOR00,$00f
copper_wrap_bpl_wait_1
                dc.w    $0001,$fffe                     ; for scanline and wrap bitplane ptrs
copper_wrap_bpl_1
                dc.w    BPL1PTL,$0000                   ; scroll wrap bitplane ptrs (always the start of the bitplane)
                dc.w    BPL1PTH,$0000
                dc.w    BPL2PTL,$0000
                dc.w    BPL2PTH,$0000
                dc.w    BPL3PTL,$0000
                dc.w    BPL3PTH,$0000
                dc.w    BPL4PTL,$0000
                dc.w    BPL4PTH,$0000
                dc.w    BPL5PTL,$0000
                dc.w    BPL5PTH,$0000

                dc.w    COLOR00,$000                ; debug colour line (shows where the buffer wrap is on screen)

                dc.w    $ffff,$fffe
                dc.w    $ffff,$fffe


copper_list_2
                dc.w    DIWSTRT,$2c81            ; default PAL window start
                dc.w    DIWSTOP,$2cc1            ; default PAL window stop
                dc.w    DDFSTRT,$0038            ; default lowres data fetch
                dc.w    DDFSTOP,$00d0            ; default lowres data stop
copper_bplcon_2 dc.w    BPLCON0,$0000            ; reset/switch off all display controll settings
                dc.w    BPLCON1,$0000
                dc.w    BPLCON2,$0000
                dc.w    BPLCON3,$0000
                dc.w    BPLCON4,$0000
                dc.w    FMODE,$0000              ; reset aga fetch mode (if available)
copper_bpl_2    dc.w    BPL1PTL,$0000
                dc.w    BPL1PTH,$0000
                dc.w    BPL2PTL,$0000
                dc.w    BPL2PTH,$0000
                dc.w    BPL3PTL,$0000
                dc.w    BPL3PTH,$0000
                dc.w    BPL4PTL,$0000
                dc.w    BPL4PTH,$0000
                dc.w    BPL5PTL,$0000
                dc.w    BPL5PTH,$0000
                dc.w    BPL1MOD,$0000 
                dc.w    BPL2MOD,00000
copper_colors_2 dc.w    COLOR00,$000
                dc.w    COLOR01,$000
                dc.w    COLOR02,$000
                dc.w    COLOR03,$000
                dc.w    COLOR04,$000
                dc.w    COLOR05,$000
                dc.w    COLOR06,$000
                dc.w    COLOR07,$000
                dc.w    COLOR08,$000
                dc.w    COLOR09,$000
                dc.w    COLOR10,$000
                dc.w    COLOR11,$000
                dc.w    COLOR12,$000
                dc.w    COLOR13,$000
                dc.w    COLOR14,$000
                dc.w    COLOR15,$000
                dc.w    COLOR16,$000
                dc.w    COLOR17,$000
                dc.w    COLOR18,$000
                dc.w    COLOR19,$000
                dc.w    COLOR20,$000
                dc.w    COLOR21,$000
                dc.w    COLOR22,$000
                dc.w    COLOR23,$000
                dc.w    COLOR24,$000
                dc.w    COLOR25,$000
                dc.w    COLOR26,$000
                dc.w    COLOR27,$000
                dc.w    COLOR28,$000
                dc.w    COLOR29,$000
                dc.w    COLOR30,$000
                dc.w    COLOR31,$000
copper_wrap_wait_2
                dc.w    $ffdf,$fffe                     ; wait required if wrapping inside the PAL screen area
                dc.w    $180,$00f
copper_wrap_bpl_wait_2
                dc.w    $0001,$fffe                     ; for scanline and wrap bitplane ptrs
copper_wrap_bpl_2
                dc.w    BPL1PTL,$0000                   ; scroll wrap bitplane ptrs (always the start of the bitplane)
                dc.w    BPL1PTH,$0000
                dc.w    BPL2PTL,$0000
                dc.w    BPL2PTH,$0000
                dc.w    BPL3PTL,$0000
                dc.w    BPL3PTH,$0000
                dc.w    BPL4PTL,$0000
                dc.w    BPL4PTH,$0000
                dc.w    BPL5PTL,$0000
                dc.w    BPL5PTH,$0000

                dc.w    COLOR00,$000                ; debug colour line (shows where the buffer wrap is on screen)

                dc.w    $ffff,$fffe
                dc.w    $ffff,$fffe


              incdir  "libs/"
              include "joystick.s"


bitplane      
                ; 0-15 rasters
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                ; 16-31 rasters
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                ; 32-47 rasters
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                ; 48-63 rasters
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                ; 64-79 rasters
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                ; 80-95 rasters
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                ; 96-111 rasters
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                ; 112-127 rasters
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                ; 128-255 rasters
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                dcb.l   (40*8)/4,$ff00ff00
                dcb.l   (40*8)/4,$00ff00ff
                ; additional 32 rasters (offscreen scroll)
                ; 0-15 rasters
                dcb.l   (40*8)/4,$ffff0000
                dcb.l   (40*8)/4,$0000ffff
                ; 16-31 rasters
                dcb.l   (40*8)/4,$ffff0000
                dcb.l   (40*8)/4,$0000ffff            

init_copper_display
            lea     copper_bpl_1,a0
            lea     copper_wrap_bpl_1,a1
            lea     copper_bpl_2,a2
            lea     copper_wrap_bpl_2,a3
            move.l  #bitplane,d0
              
            move.w  d0,2(a0)
            move.w  d0,2(a1)                ; copper wrap bpl
            move.w  d0,2(a2)
            move.w  d0,2(a3)
            swap.w  d0
            move.w  d0,6(a0)
            move.w  d0,6(a1)                ; copper wrap bpl
            move.w  d0,6(a2)
            move.w  d0,6(a3)

            lea     copper_colors_1,a0
            lea     copper_colors_2,a1
            move.w  #$fff,6(a0)             ; colour 01
            move.w  #$fff,6(a1)

            lea     copper_bplcon_1,a0
            lea     copper_bplcon_2,a1
            move.w  #$1200,2(a0)            ; single bitplane
            move.w  #$1200,2(a1)

            rts


vertical_buffer_height  dc.w    256+32      ; max buffer height 
vertical_scroll_value   dc.w    0           ; the current scroll offset
vertical_display_height dc.w    256         ; the viewable display height
vertical_wait_value     dc.w    256+32

calc_wrap_wait 
            move.w      vertical_buffer_height,d0
            sub.w       vertical_scroll_value,d0          ; bottom wait value (might be off screen if buffer higher than the screen)
            ; clamp max wait to 255
            cmp.w       #$00ff,d0
            ble         .no_clamp
.clamp
            move.w      #$00ff,d0
.no_clamp
            ; add window vertical start
            add.w       #$2c,d0
            move.w      d0,d1

;            cmp.w       #$00100,d0         ; check for pal wait
;            blt         .no_pal_wait
;.is_pal_wait
;            move.w      #$00ff,d0
;            sub.w       #$0101,d1
;            bra         .set_cop_wait

.no_pal_wait
            sub.w       #$1,d0

.set_cop_wait
            move.l      copper_wrap_wait_ptr,a0
            move.b      d0,(a0) 
            move.l      copper_wrap_bpl_wait_ptr,a1
            move.b      d1,(a1)

            rts      
            





            rts


vertical_scroll
            move.w      controller_port2,d0
            btst.l      #JOYSTICK_DOWN,d0
            beq.s       .check_up
.is_down
            move.w      vertical_scroll_value,d0
            add.w       #1,d0
            cmp.w       vertical_buffer_height,d0
            bcs         .not_wrap
            move.w      #0,d0
.not_wrap
            move.w      d0,vertical_scroll_value
            bra         .cont

.check_up
            btst.l      #JOYSTICK_UP,d0
            beq.s       .cont
.is_up 
            move.w      vertical_scroll_value,d0
            sub.w       #1,d0
            cmp.w       #$0000,d0
            bge         .not_up_wrap
.is_up_wrap
            move.w      vertical_buffer_height,d0
.not_up_wrap
            move.w      d0,vertical_scroll_value
            
.cont

            jsr     calc_wrap_wait

        ; update bitplane ptrs
            moveq       #0,d0
            moveq       #0,d1
            move.l      #bitplane,d0
            move.w      vertical_scroll_value,d1
            mulu        #40,d1
            add.l       d1,d0

            lea     copper_bpl_1,a0
            lea     copper_bpl_2,a1
              
            move.w  d0,2(a0)
            move.w  d0,2(a1)
            swap.w  d0
            move.w  d0,6(a0)
            move.w  d0,6(a1)



            rts


