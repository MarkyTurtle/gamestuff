
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
              lea     copper_list,a0
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


test_color:   dc.w  $0

                ; copper (intreq bit 04)
                ; vertical blank (intreq bit 05)
                ; blitter (intreq bit 06)
level3_interrupt_handler
              movem.l d0-d7/a0-a6,-(a7)
              lea     $dff000,a6


              add.w   #$1,test_color
              move.w  test_color,d0
              move.w  d0,$dff180

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



            ; -------------------------- copper list ------------------------
            ; program copper list for managine the screen display.
copper_list
                dc.w    DIWSTRT,$2c81            ; default PAL window start
                dc.w    DIWSTOP,$2cc1            ; default PAL window stop
                dc.w    DDFSTRT,$0038            ; default lowres data fetch
                dc.w    DDFSTOP,$00d0            ; default lowres data stop
copper_bplcon   dc.w    BPLCON0,$0000            ; reset/switch off all display controll settings
                dc.w    BPLCON1,$0000
                dc.w    BPLCON2,$0000
                dc.w    BPLCON3,$0000
                dc.w    BPLCON4,$0000
                dc.w    FMODE,$0000              ; reset aga fetch mode (if available)
copper_bpl      dc.w    BPL1PTL,$0000
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
copper_colors   dc.w    COLOR00,$000
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
                dc.w    $ffdf,$fffe                     ; wait for pal area
                dc.w    $0001,$fffe
                dc.w    COLOR00,$00f
                dc.w    $2801,$fffe
                dc.w    COLOR00,$0f00
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
            lea     copper_bpl,a0
            move.l  #bitplane,d0
              
            move.w  d0,2(a0)
            swap.w  d0
            move.w  d0,6(a0)

            lea     copper_colors,a0
            move.w  #$fff,6(a0)             ; colour 01

            lea     copper_bplcon,a0
            move.w  #$1200,2(a0)            ; single bitplane

            rts


vertical_scroll_height  dc.w    256+32      ; max buffer height 
vertical_scroll_value   dc.w    $0000

vertical_scroll
            move.w      controller_port2,d0
            btst.l      #JOYSTICK_DOWN,d0
            beq.s       .not_down
            move.w      vertical_scroll_value,d0
            add.w       #1,d0
            cmp.w       vertical_scroll_height,d0
            bcs         .not_wrap
            move.w      #0,d0
.not_wrap
            move.w  d0,vertical_scroll_value

.not_down
            
        ; update bitplane ptrs
            moveq       #0,d0
            moveq       #0,d1
            move.l      #bitplane,d0
            move.w      vertical_scroll_value,d1
            mulu        #40,d1
            add.l       d1,d0

            lea     copper_bpl,a0
              
            move.w  d0,2(a0)
            swap.w  d0
            move.w  d0,6(a0)

            rts


