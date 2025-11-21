
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

                    ; IN:
                    ;   d0.w - x pixel pos to start
                    ;   d1.w - y raster offset in bytes
                    ;   d2.l - value to display
                    ;   a0.l - text string to display (null terminated)
debug_write
                    movem.l d0-d7/a0-a6,-(a7)
                    lea     debug_string,a0

                    move.w  #8-1,d7             ; 8 nibbles
.conv_loop          move.l  d2,d3
                    and.l   #$0000000f,d3
                    cmp.b   #$0a,d3
                    bge     .hex
.dig
                    add.b   #$30,d3
                    bra.s   .set_char_value
.hex
                    add.b   #55,d3

.set_char_value
                    move.b  d3,(a0,d7.w)
                    ror.l   #4,d2
                    dbf     d7,.conv_loop

.clear
                    lea   bitplane,a1
                    move.w  #8-1,d7
                    moveq   #0,d6
.clearloop
                    move.w  d7,d6
                    mulu    #40,d6
                    add.w   d1,d6
                    move.b  #0,(a1,d6.w)
                    move.b  #0,1(a1,d6.w)
                    move.b  #0,2(a1,d6.w)
                    move.b  #0,3(a1,d6.w)
                    move.b  #0,4(a1,d6.w)
                    move.b  #0,5(a1,d6.w)
                    move.b  #0,6(a1,d6.w)
                    move.b  #0,7(a1,d6.w)
                    dbf     d7,.clearloop

                    lea     bitplane,a1
                    jsr     write_string
                    movem.l (a7)+,d0-d7/a0-a6
                    rts

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
                dc.w    $2a01,$fffe
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
copper_wrap_wait
                dc.w    $ffdf,$fffe                     ; wait required if wrapping inside the PAL screen area
                dc.w    COLOR00,$00f
copper_wrap_bpl_wait
                dc.w    $0001,$fffe                     ; for scanline and wrap bitplane ptrs
copper_wrap_bpl
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

              include "texttyper.s"


bitplane      
                ; 0-15 rasters
                dcb.l   (40*8)/4,$0f0f0f0f
                dcb.l   (40*8)/4,$f0f0f0f0
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
            lea     copper_wrap_bpl,a1
            move.l  #bitplane,d0
              
            move.w  d0,2(a0)
            move.w  d0,2(a1)                ; copper wrap bpl
            swap.w  d0
            move.w  d0,6(a0)
            move.w  d0,6(a1)                ; copper wrap bpl

            lea     copper_colors,a0
            move.w  #$fff,6(a0)             ; colour 01

            lea     copper_bplcon,a0
            move.w  #$1200,2(a0)            ; single bitplane

            rts


vertical_buffer_height  dc.w    256+32      ; max buffer height 
vertical_scroll_value   dc.w    16           ; the current scroll offset
vertical_display_height dc.w    256         ; the viewable display height
vertical_wait_value     dc.w    256+32
vertical_scroll_speed   dc.w    1           ; number of pixels per scroll interval
   


calc_wrap_wait 
            move.w      vertical_scroll_value,d0
            asl.w       #1,d0

            lea         copper_wait_table,a0
            moveq       #0,d1
            moveq       #0,d2
            move.b      (a0,d0.w),d1            ; bpl wait
            move.b      1(a0,d0.w),d2           ; copper wait

            lea.l       copper_wrap_wait,a0
            move.b      d1,(a0)
            lea.l       copper_wrap_bpl_wait,a0
            move.b      d2,(a0)

            rts




vertical_scroll
            jsr     joystick_scroll  
            jsr     calc_wrap_wait
            jsr     set_copper_scroll
            rts


joystick_scroll
            move.w      controller_port2,d0
            btst.l      #JOYSTICK_DOWN,d0
            beq.s       .check_up
.is_down
            move.w      vertical_scroll_value,d0
            add.w       vertical_scroll_speed,d0
            cmp.w       vertical_buffer_height,d0
            blt         .not_wrap
            move.w      #0,d0
            ble         .not_wrap
.is_down_wrap
            sub.w       vertical_buffer_height,d0
.not_wrap
            move.w      d0,vertical_scroll_value
            bra         .cont

.check_up
            btst.l      #JOYSTICK_UP,d0
            beq.s       .cont
.is_up 
            move.w      vertical_scroll_value,d0
            sub.w       vertical_scroll_speed,d0
            cmp.w       #$0000,d0
            bge         .not_up_wrap
.is_up_wrap
            add.w       vertical_buffer_height,d0
.not_up_wrap
            move.w      d0,vertical_scroll_value         
.cont
            rts




            ; IN:
            ;   d0.w - x pixel pos to start
            ;   d1.w - y raster offset in bytes
            ;   d2.l - value to display
            ;   a0.l - text string to display (null terminated)
            moveq   #0,d0
            move.l  #(40*200),d1
            moveq   #0,d2
            move.w  vertical_scroll_value,d2
            lea     bitplane,a0
            jsr     debug_write

set_copper_scroll
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


            ; ---------------------------------------------------------------
            ; Copper Wait Table
            ; Used as a precalculated set of copper waits for wrapping the 
            ; display buffer for the vertical scroll.
            ; The table below is suitable for use with a scroll buffer of
            ; 256 + 32 = 288 rasters high.
            ; so the first 32 rasters are set to 'no wrap values' $ff,$2c
            ; as they are outised of the viewable screen area.
            ;
copper_wait_table       
                    ; outside pal (32 rasters) (off screen buffer scroll area)
                    ; i.e. there is no screen wrap until the buffer has scrolled enough to 
                    ; reach the end of the offscreen buffer
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 

                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 
                        dc.b    $ff,$2c 

                    ; start scrolling and wrapping the buffer inside the PAL screen area
                    ; the copper wait is always line $ff for the first copper PAL area wait.
                    ; the second value is the wrap to start raster line,
                    ; assuming a standard PAL height of 256 rasters - lo-res
                        dc.b    $ff,$2c     ; 000
                        dc.b    $ff,$2b
                        dc.b    $ff,$2a
                        dc.b    $ff,$29
                        dc.b    $ff,$28
                        dc.b    $ff,$27
                        dc.b    $ff,$26
                        dc.b    $ff,$25
                        dc.b    $ff,$24
                        dc.b    $ff,$23
                        dc.b    $ff,$22    
                        dc.b    $ff,$21     
                        dc.b    $ff,$20     
                        dc.b    $ff,$1f     
                        dc.b    $ff,$1e     
                        dc.b    $ff,$1d     ; 015  

                        dc.b    $ff,$1c     ; 016
                        dc.b    $ff,$1b
                        dc.b    $ff,$1a
                        dc.b    $ff,$19
                        dc.b    $ff,$18
                        dc.b    $ff,$17
                        dc.b    $ff,$16
                        dc.b    $ff,$15
                        dc.b    $ff,$14
                        dc.b    $ff,$13
                        dc.b    $ff,$12     
                        dc.b    $ff,$11     
                        dc.b    $ff,$10     
                        dc.b    $ff,$0f     
                        dc.b    $ff,$0e     
                        dc.b    $ff,$0d     ; 032  

                        dc.b    $ff,$0c     ; 033
                        dc.b    $ff,$0b
                        dc.b    $ff,$0a
                        dc.b    $ff,$09
                        dc.b    $ff,$08
                        dc.b    $ff,$07
                        dc.b    $ff,$06
                        dc.b    $ff,$05
                        dc.b    $ff,$04
                        dc.b    $ff,$03
                        dc.b    $ff,$02     
                        dc.b    $ff,$01     
                        dc.b    $ff,$00  

                        ; scroll wrap is now above the PAL screen area (ie. in the top range $2c-$ff)
                        ; The first copper wait is now set to the raster line before the bitplane wrap
                        ; Thie allows the copper to keep the initial 'PAL' wait without haveing to
                        ; modify the copper list instructions (only the veritcal raster wait)   
                        dc.b    $fe,$ff     
                        dc.b    $fd,$fe     
                        dc.b    $fc,$fd     ; 047  

                        dc.b    $fb,$fc     ; 048
                        dc.b    $fa,$fb
                        dc.b    $f9,$fa
                        dc.b    $f8,$f9
                        dc.b    $f7,$f8
                        dc.b    $f6,$f7
                        dc.b    $f5,$f6
                        dc.b    $f4,$f5
                        dc.b    $f3,$f4
                        dc.b    $f2,$f3
                        dc.b    $f1,$f2     
                        dc.b    $f0,$f1     
                        dc.b    $ef,$f0     
                        dc.b    $ee,$ef     
                        dc.b    $ed,$ee     
                        dc.b    $ec,$ed     ; 063 

                        dc.b    $eb,$ec     ; 064
                        dc.b    $ea,$eb
                        dc.b    $e9,$ea
                        dc.b    $e8,$e9
                        dc.b    $e7,$e8
                        dc.b    $e6,$e7
                        dc.b    $e5,$e6
                        dc.b    $e4,$e5
                        dc.b    $e3,$e4
                        dc.b    $e2,$e3
                        dc.b    $e1,$e2     
                        dc.b    $e0,$e1     
                        dc.b    $df,$e0     
                        dc.b    $de,$df     
                        dc.b    $dd,$de     
                        dc.b    $dc,$dd     ; 079

                        dc.b    $db,$dc     ; 080
                        dc.b    $da,$db
                        dc.b    $d9,$da
                        dc.b    $d8,$d9
                        dc.b    $d7,$d8
                        dc.b    $d6,$d7
                        dc.b    $d5,$d6
                        dc.b    $d4,$d5
                        dc.b    $d3,$d4
                        dc.b    $d2,$d3
                        dc.b    $d1,$d2     
                        dc.b    $d0,$d1     
                        dc.b    $cf,$d0     
                        dc.b    $ce,$cf     
                        dc.b    $cd,$ce     
                        dc.b    $cc,$cd     ; 095 

                        dc.b    $cb,$cc     ; 096
                        dc.b    $ca,$cb
                        dc.b    $c9,$ca
                        dc.b    $c8,$c9
                        dc.b    $c7,$c8
                        dc.b    $c6,$c7
                        dc.b    $c5,$c6
                        dc.b    $c4,$c5
                        dc.b    $c3,$c4
                        dc.b    $c2,$c3
                        dc.b    $c1,$c2     
                        dc.b    $c0,$c1     
                        dc.b    $bf,$c0     
                        dc.b    $be,$bf     
                        dc.b    $bd,$be     
                        dc.b    $bc,$bd     ; 111 

                        dc.b    $bb,$bc     ; 112
                        dc.b    $ba,$bb
                        dc.b    $b9,$ba
                        dc.b    $b8,$b9
                        dc.b    $b7,$b8
                        dc.b    $b6,$b7
                        dc.b    $b5,$b6
                        dc.b    $b4,$b5
                        dc.b    $b3,$b4
                        dc.b    $b2,$b3
                        dc.b    $b1,$b2     
                        dc.b    $b0,$b1     
                        dc.b    $af,$b0     
                        dc.b    $ae,$af     
                        dc.b    $ad,$ae     
                        dc.b    $ac,$ad     ; 127 

                        dc.b    $ab,$ac     ; 128
                        dc.b    $aa,$ab
                        dc.b    $a9,$aa
                        dc.b    $a8,$a9
                        dc.b    $a7,$a8
                        dc.b    $a6,$a7
                        dc.b    $a5,$a6
                        dc.b    $a4,$a5
                        dc.b    $a3,$a4
                        dc.b    $a2,$a3
                        dc.b    $a1,$a2     
                        dc.b    $a0,$a1     
                        dc.b    $9f,$a0     
                        dc.b    $9e,$9f     
                        dc.b    $9d,$9e     
                        dc.b    $9c,$9d     ; 143 

                        dc.b    $9b,$9c     ; 144
                        dc.b    $9a,$9b
                        dc.b    $99,$9a
                        dc.b    $98,$99
                        dc.b    $97,$98
                        dc.b    $96,$97
                        dc.b    $95,$96
                        dc.b    $94,$95
                        dc.b    $93,$94
                        dc.b    $92,$93
                        dc.b    $91,$92     
                        dc.b    $90,$91     
                        dc.b    $8f,$90     
                        dc.b    $8e,$8f     
                        dc.b    $8d,$8e     
                        dc.b    $8c,$8d     ; 159

                        dc.b    $8b,$8c     ; 160
                        dc.b    $8a,$8b
                        dc.b    $89,$8a
                        dc.b    $88,$89
                        dc.b    $87,$88
                        dc.b    $86,$87
                        dc.b    $85,$86
                        dc.b    $84,$85
                        dc.b    $83,$84
                        dc.b    $82,$83
                        dc.b    $81,$82     
                        dc.b    $80,$81     
                        dc.b    $7f,$80     
                        dc.b    $7e,$7f     
                        dc.b    $7d,$7e     
                        dc.b    $7c,$7d     ; 175

                        dc.b    $7b,$7c     ; 176
                        dc.b    $7a,$7b
                        dc.b    $79,$7a
                        dc.b    $78,$79
                        dc.b    $77,$78
                        dc.b    $76,$77
                        dc.b    $75,$76
                        dc.b    $74,$75
                        dc.b    $73,$74
                        dc.b    $72,$73
                        dc.b    $71,$72     
                        dc.b    $70,$71     
                        dc.b    $6f,$70     
                        dc.b    $6e,$6f     
                        dc.b    $6d,$6e     
                        dc.b    $6c,$6d     ; 191

                        dc.b    $6b,$6c     ; 192
                        dc.b    $6a,$6b
                        dc.b    $69,$6a
                        dc.b    $68,$69
                        dc.b    $67,$68
                        dc.b    $66,$67
                        dc.b    $65,$66
                        dc.b    $64,$65
                        dc.b    $63,$64
                        dc.b    $62,$63
                        dc.b    $61,$62     
                        dc.b    $60,$61     
                        dc.b    $5f,$60     
                        dc.b    $5e,$5f     
                        dc.b    $5d,$5e     
                        dc.b    $5c,$5d     ; 207

                        dc.b    $5b,$5c     ; 208
                        dc.b    $5a,$5b
                        dc.b    $59,$5a
                        dc.b    $58,$59
                        dc.b    $57,$58
                        dc.b    $56,$57
                        dc.b    $55,$56
                        dc.b    $54,$55
                        dc.b    $53,$54
                        dc.b    $52,$53
                        dc.b    $51,$52     
                        dc.b    $50,$51     
                        dc.b    $4f,$50     
                        dc.b    $4e,$4f     
                        dc.b    $4d,$4e     
                        dc.b    $4c,$4d     ; 223

                        dc.b    $4b,$4c     ; 224
                        dc.b    $4a,$4b
                        dc.b    $49,$4a
                        dc.b    $48,$49
                        dc.b    $47,$48
                        dc.b    $46,$47
                        dc.b    $45,$46
                        dc.b    $44,$45
                        dc.b    $43,$44
                        dc.b    $42,$43
                        dc.b    $41,$42     
                        dc.b    $40,$41     
                        dc.b    $3f,$40     
                        dc.b    $3e,$3f     
                        dc.b    $3d,$3e     
                        dc.b    $3c,$3d     ; 239

                        dc.b    $3b,$3c     ; 240
                        dc.b    $3a,$3b
                        dc.b    $39,$3a
                        dc.b    $38,$39
                        dc.b    $37,$38
                        dc.b    $36,$37
                        dc.b    $35,$36
                        dc.b    $34,$35
                        dc.b    $33,$34
                        dc.b    $32,$33
                        dc.b    $31,$32     
                        dc.b    $30,$31     
                        dc.b    $2f,$30     
                        dc.b    $2e,$2f     
                        dc.b    $2d,$2e     
                        dc.b    $2c,$2d     ; 255
                        
                        dc.b    $2b,$2c     ; 255

debug_string  dc.b  "01234567",$0
            even



menu_font_gfx
          incdir  "gfx/"
          include "typerfont.s"

