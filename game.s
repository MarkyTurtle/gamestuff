
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
               lea.l     STACK_PTR,a0
               lea.l     vector_handler_table,a1
               jsr       kill_system

            ; enable joystick buttons
               move.w    #$ff00,POTGO(a6)

            ; intialise copper display
               jsr       init_copper_display

            ; set up copper list
               lea       copper_list,a0

               lea       CUSTOM,a6
               move.l    a0,COP1LC(a6)
               move.w    #$8280,DMACON(a6)     ; enable copper dma
               move.w    #$8300,DMACON(a6)     ; enable bitplane dma
               move.w    #$8240,DMACON(a6)     ; enable blitter dma


            ; initialise game routines
               jsr       scr2_initialise


          ; enable interrupts
               move.w    #$C020,INTENA(a6)       ; enable vertb  


loop
               jmp       loop

 
 
 
test_color      dc.w    $0
frame_count     dc.w    $0

                ; copper (intreq bit 04)
                ; vertical blank (intreq bit 05)
                ; blitter (intreq bit 06)
level3_interrupt_handler
               movem.l   d0-d7/a0-a6,-(a7)
               lea       CUSTOM,a6

          ; test for vbl interrupt
               move.w    INTREQR(a6),d0
               and.w     #$0020,d0
               beq       .exit_handler

          ; get joystick port 1
               move.w    JOY0DAT(a6),d0
               lea       controller_port1,a0
               jsr       decode_joystick_directions
               jsr       decode_joystick_port1_buttons

          ; get joystick port 2
               move.w    JOY1DAT(a6),d0
               lea       controller_port2,a0
               jsr       decode_joystick_directions
               jsr       decode_joystick_port2_buttons

          ; scroll
               jsr       set_scroll_speed
               jsr       scr2_scroll_update




          ; clear the interrupt (level 3 only)
               move.w    INTREQR(a6),d0
               and.w     #$0070,d0                     ; keep level 3 interrupt flags
.exit_handler  move.w    d0,INTREQ(a6)                 ; clear level 3 interrupt flags

               movem.l   (a7)+,d0-d7/a0-a6
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





        ; ----------- set vertical scroll speed from joystick input ------------
set_scroll_speed
            lea         scroll_data,a0
            move.w      controller_port2,d0

        ; check joystick down
.chk_joy_down
            btst.l      #JOYSTICK_DOWN,d0
            beq.s       .check_up
.is_down
            move.w      #$0001,SCR_VERT_SCROLL_SPEED(a0)
            rts

        ; check joystick up
.check_up
            btst.l      #JOYSTICK_UP,d0
            beq.s       .not_up_or_down
.is_up 
            move.w      #$ffff,SCR_VERT_SCROLL_SPEED(a0)
            rts

.not_up_or_down
            move.w      #$0000,SCR_VERT_SCROLL_SPEED(a0)
            rts





scroll_tile_data
                        dc.b    $01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$00,$01,$01   ; 000
                        dc.b    $00,$00,$01,$01,$01,$00,$01,$01,$01,$00,$01,$01,$01,$00,$00,$00,$00,$00,$01,$00   ; 001
                        dc.b    $00,$00,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$00,$00,$01,$00,$00   ; 002
                        dc.b    $00,$00,$00,$01,$00,$00,$01,$00,$01,$00,$01,$01,$01,$00,$00,$00,$01,$00,$00,$00   ; 003
                        dc.b    $00,$00,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$00,$00,$00,$01,$00,$00,$00,$00   ; 004
                        dc.b    $00,$00,$00,$01,$00,$00,$01,$01,$01,$00,$01,$00,$00,$00,$01,$00,$00,$00,$00,$00   ; 005
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00   ; 006
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00   ; 007
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00   ; 008
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00   ; 009
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00   ; 010
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00   ; 011
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00   ; 012
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00   ; 013
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00   ; 014
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00   ; 015
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00   ; 016
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00   ; 017
                        dc.b    $00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01   ; 018
                        dc.b    $00,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01   ; 019
                        dc.b    $00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01   ; 020
                        dc.b    $00,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00   ; 021
                        dc.b    $00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00   ; 022
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00   ; 023
                        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00,$00   ; 024
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00   ; 025
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00   ; 026
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00   ; 027
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00   ; 028
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00   ; 029

                        dc.b    $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00   ; 030
                        dc.b    $00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00   ; 031
                        dc.b    $00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00   ; 032
                        dc.b    $00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00   ; 033
                        dc.b    $00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00   ; 034

                        ; bug - skipping this line?
                        dc.b    $00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00   ; 035

                        dc.b    $00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00   ; 036
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00   ; 037
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01   ; 038
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01   ; 039

                        ; SOLID BAR - END OF DATA (visual reference incase code over-shoots)
                        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01   ; xx
                        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01   ; xx
                        dc.b    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01   ; xx



                        even
tile_gfx
                        dcb.w   16,$5555
                        dcb.w   16,$ffff


debug_string  dc.b  "01234567",$0
            even



menu_font_gfx
          incdir  "gfx/"
          include "typerfont.s"



          ; ----------------------------- Kill System ---------------------------
          ; Kills the Amiga OS and initialised Vectors.
          ; This needs work for processors other than 68000 which use the VBR
          ; as a base address for Vectors etc.
          ;
          ; Could do with adding checks for Processor, Chipset, VBR, Memory etc.
          ; 
          ; IN:
          ;   a0.l - new stack ptr address
          ;   a1.l - vector table
          ;
kill_system
               lea       CUSTOM,a6
               move.w    #$7fff,INTENA(a6)        ; interrupts off
               move.w    #$7fff,INTREQ(a6)        ; clear interrupt request flags
               move.w    #$7fff,INTREQ(a6)        ; clear interrupt request flags

.blit_wait     btst.b    #14-8,DMACONR(a6)        ; wait for any existing blit operation to finish
               bne.s     .blit_wait

               move.w  #$7fff,DMACON(a6)


          ; enter supervisor mode (trash/forget old stack ptr)
               move.l    (a7),a2                  ; save return address PC from existing stack
               move.l    a0,a7                    ; set new user mode stack (for the moment)
               move.l    #.supervisor,$80.w       ; set trap #0 vector
               trap      #0                       ; execute trap to enter supervisor mode

.supervisor    move.l    a0,a7                    ; set supervisor stack pointer SSP
               move.l    a2,-(a7)                 ; store return address PC on stack


          ; set exception vectors
               lea       $0,a0                    
.loop          move.l    (a1)+,d0
               cmp.l     #$ffffffff,d0
               beq.s     .cont
               move.l    d0,(a0)+
               bra.s     .loop
.cont          
               rts





vector_handler_table                              ; Vector  | Addr      | Description
              dc.l  $0                            ; 000     | $00.w     | Reset, Initial SSP
              dc.l  $0                            ; 001     | $04.w     | Reset, Initial PC
              dc.l  default_exception_handler     ; 002     | $08.w
              dc.l  default_exception_handler     ; 003     | $0C.w
              dc.l  default_exception_handler     ; 004     | $10.w
              dc.l  default_exception_handler     ; 005     | $14.w
              dc.l  default_exception_handler     ; 006     | $18.w
              dc.l  default_exception_handler     ; 007     | $1C.w
              dc.l  default_exception_handler     ; 008     | $20.w
              dc.l  default_exception_handler     ; 009     | $24.w
              dc.l  default_exception_handler     ; 010     | $28.w
              dc.l  default_exception_handler     ; 011     | $2C.w
              dc.l  default_exception_handler     ; 012     | $30.w
              dc.l  default_exception_handler     ; 013     | $34.w
              dc.l  default_exception_handler     ; 014     | $38.w
              dc.l  default_exception_handler     ; 015     | $3C.w
              dc.l  default_exception_handler     ; 016     | $40.w
              dc.l  default_exception_handler     ; 017     | $44.w
              dc.l  default_exception_handler     ; 018     | $48.w
              dc.l  default_exception_handler     ; 019     | $4C.w
              dc.l  default_exception_handler     ; 020     | $50.w
              dc.l  default_exception_handler     ; 021     | $54.w
              dc.l  default_exception_handler     ; 022     | $58.w
              dc.l  default_exception_handler     ; 023     | $5C.w
              dc.l  default_exception_handler     ; 024     | $60.w
              dc.l  level1_interrupt_handler      ; 025     | $64.w
              dc.l  level2_interrupt_handler      ; 026     | $68.w
              dc.l  level3_interrupt_handler      ; 027     | $6C.w
              dc.l  level4_interrupt_handler      ; 028     | $70.w
              dc.l  level5_interrupt_handler      ; 029     | $74.w
              dc.l  level6_interrupt_handler      ; 030     | $78.w
              dc.l  level7_interrupt_handler      ; 031     | $7C.w
              dc.l  default_trap_handler          ; 032     | $80.w - Trap 00
              dc.l  default_trap_handler          ; 033     | $84.w
              dc.l  default_trap_handler          ; 034     | $88.w
              dc.l  default_trap_handler          ; 035     | $8C.w
              dc.l  default_trap_handler          ; 036     | $90.w
              dc.l  default_trap_handler          ; 037     | $94.w
              dc.l  default_trap_handler          ; 038     | $98.w
              dc.l  default_trap_handler          ; 039     | $9C.w
              dc.l  default_trap_handler          ; 040     | $A0.w
              dc.l  default_trap_handler          ; 041     | $A4.w
              dc.l  default_trap_handler          ; 042     | $A8.w
              dc.l  default_trap_handler          ; 043     | $AC.w
              dc.l  default_trap_handler          ; 044     | $B0.w
              dc.l  default_trap_handler          ; 045     | $B4.w
              dc.l  default_trap_handler          ; 046     | $B8.w
              dc.l  default_trap_handler          ; 047     | $BC.w - Trap 15
              dc.l  $FFFFFFFF

                            


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



               incdir    "libs/"
               include   "scroller.s"


