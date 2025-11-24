
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

                    ; IN:
                    ;   - d0.w = source tile x index (scroll data co-ords)
                    ;   - d1.w = source tile y index (scroll data co-ords)
                    ;   - d2.w = destination tile x-index (display buffer co-ords)
                    ;   - d3.w = destination tile y-index (display buffer co-ords)
                    ;   - a0.l = scroll data structure
               moveq     #0,d0
               moveq     #0,d1
               moveq     #0,d2
               moveq     #0,d3
               lea       scroll_data,a0
               jsr       scr_blit_tile_buffer
               jsr       init_scroll

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

          ; vertical scroll
               jsr       vertical_scroll



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






vertical_scroll
            jsr     vertical_joystick_scroll                ; set vertical scroll speed by joystick input
            jsr     vertical_soft_scroll                    ; update vertical soft scroll values
            jsr     vertical_calc_wrap_wait                 ; set vertical scroll copper list buffer wrap values
            jsr     vertical_set_copper_scroll              ; set copper list bitplane ptrs
            jsr     vertical_blit_new_line                  ; check if new vertical data needs to be added to the screen buffer.
            rts


        ; ----------- blit new gfx into display buffer -------------
        ;   IN:
        ;     a0.l = scroll_data
vertical_blit_new_line
          ; check if hard scroll line has changes
            lea     scroll_data,a0
            move.w  SCR_VIEW_Y(a0),d0
            beq     .cont
            divs.w  #16,d0
.cont
            ;move.w  SCR_VIEW_Y_IDX(a0),d1
            cmp.w   SCR_VIEW_Y_IDX(a0),d0
            bgt.s   .add_bottom_row             ; scroll up (new top row required)
            blt.s   .add_top_row                ; scroll down (new bottom row required)
            rts                                 ; no new data required

.add_top_row
            move.w  d0,SCR_VIEW_Y_IDX(a0)      ; store new tile index

                    ;   - d0.w = source tile x index (scroll data co-ords)
                    ;   - d1.w = source tile y index (scroll data co-ords)
                    ;   - d2.w = destination tile x-index (display buffer co-ords)
                    ;   - d3.w = destination tile y-index (display buffer co-ords)
                    ;   - a0.l = scroll data structure
            ;jsr     scr_blit_tile_row
            move.w  #$0f0,$DFF180
            rts

.add_bottom_row
            move.w  d0,SCR_VIEW_Y_IDX(a0)             ; store new tile index
            add.w   SCR_DISPLAY_HEIGHT_TILES(a0),d0   ; get y index for bottom of the screen
            move.w  d0,d1
            move.w   SCR_VIEW_X_IDX(a0),d0
            move.w   d0,d2
            move.w  SCR_DISPLAY_HEIGHT_TILES(a0),d3
            sub.w   #1,d3

                    ;   - d0.w = source tile x index (scroll data co-ords)
                    ;   - d1.w = source tile y index (scroll data co-ords)
                    ;   - d2.w = destination tile x-index (display buffer co-ords)
                    ;   - d3.w = destination tile y-index (display buffer co-ords)
                    ;   - a0.l = scroll data structure
            ;jsr     scr_blit_tile_row
            move.w  #$f00,$DFF180
            rts

        ; ----------- set vertical scroll speed from joystick input ------------
vertical_joystick_scroll
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



        ; --------------- Do Vertical Soft Scroll based on Scroll Speed ------------
vertical_soft_scroll
            lea         scroll_data,a0
            move.w      SCR_VERT_SCROLL_PX(a0),d0
            move.w      SCR_VERT_SCROLL_SPEED(a0),d7
            add.w       d7,d0                           ; update buffer y scroll
            add.w       d7,SCR_VIEW_Y(a0)               ; update world view y scroll

        ; check scroll down wrap
.chk_down_wrap
            cmp.w       SCR_BUFFER_HEIGHT(a0),d0
            blt         .chk_up_wrap
.is_down_wrap
            sub.w       SCR_BUFFER_HEIGHT(a0),d0
            bra         .cont

        ; check scroll up wrap
.chk_up_wrap
            cmp.w       #$0000,d0
            bge         .cont
.is_up_wrap
            add.w       SCR_BUFFER_HEIGHT(a0),d0

        ; store soft scroll value
.cont
            move.w      d0,SCR_VERT_SCROLL_PX(a0)
            rts



        ; ----------------- Set scroll buffer wrap vertical copper wait ------------------
vertical_calc_wrap_wait 
            lea         scroll_data,a0
            move.w      SCR_VERT_SCROLL_PX(a0),d0
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



        ; ------------------ Set scroll buffer top bitplane ptrs in copper ----------------
vertical_set_copper_scroll
            lea         scroll_data,a0
        ; update bitplane ptrs
            moveq       #0,d0
            moveq       #0,d1
            move.l      #bitplane,d0
            move.w      SCR_VERT_SCROLL_PX(a0),d1
            mulu        #40,d1
            add.l       d1,d0

            lea     copper_bpl,a0
              
            move.w  d0,2(a0)
            swap.w  d0
            move.w  d0,6(a0)

            rts





init_scroll
            bsr     init_copper_wait_table
            rts

          ; ------------- initialise copper wait table -----------------
init_copper_wait_table
            lea     copper_wait_table,a0
            lea     scroll_data,a1
            move.w  SCR_BUFFER_HEIGHT(a1),d0
            sub.w   #$100,d0
            bcs     .set_pal_wrap
          ; set copper offscreen are wrap values
.set_offscreen_wrap
            sub.w   #$1,d0
            bcs     .set_pal_wrap
.offscreen_loop
            move.b  #$ff,(a0)+
            move.b  #$2c,(a0)+
            tst.w   d0                        ; set z=1 if d0.w == 0
            dbeq    d0,.offscreen_loop        ; exit loop when d0.w == 0
          ; set copper pal area wrap values
.set_pal_wrap
            move.w  #$2c,d0
.pal_loop   move.b  #$ff,(a0)+
            move.b  d0,(a0)+
            tst.w   d0
            dbeq    d0,.pal_loop

          ; set copper $ff-$2c
.set_ntsc_wrap
            move.w  #$fe,d0
.ntsc_loop  move.b  d0,(a0)+
            move.b  d0,(a0)
            add.b   #$01,(a0)+
            cmp.b   #$2b,d0
            dbeq    d0,.ntsc_loop

            lea   copper_wait_table_end,a1
            cmp.l a0,a1
            bne.s copper_table_error
            
            rts

copper_table_error
            lea   $dff000,a6
            move.w  VHPOSR(a6),COLOR00(a6)
            jmp   copper_table_error


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
copper_wait_table_end




                    ; ---------------- blit buffer full of tile data to buffer --------------
                    ; IN:
                    ;   - d0.w = source tile x index (scroll data co-ords)
                    ;   - d1.w = source tile y index (scroll data co-ords)
                    ;   - d2.w = destination tile x-index (display buffer co-ords)
                    ;   - d3.w = destination tile y-index (display buffer co-ords)
                    ;   - a0.l = scroll data structure
                    ;
scr_blit_tile_buffer

                    lea     scroll_data,a0
                    moveq   #0,d0
                    moveq   #0,d2
                    moveq   #0,d3

                  ; calc source tile Y co-oord (top line's initial tile index)
.calc_top_row_idx
                    moveq   #0,d1
                    move.w  SCR_VIEW_Y(a0),d1                        ; Get the View Windows's Y scroll co-oord
                    beq     .store_top_row_idx
                    divs.w  #16,d1
.store_top_row_idx
                    move.w  d1,SCR_VIEW_Y_IDX(a0)                 ; store initial tile y index

.get_row_count
                    move.w  SCR_DISPLAY_HEIGHT_TILES(a0),d4       ; display height in tiles
                    subq    #1,d4
.row_loop
                    jsr     scr_blit_tile_row
                    add.w   #1,d1
                    add.w   #1,d3
                    dbf     d4,.row_loop

                    rts

                    ; ---------------- blit row of tile data to buffer --------------
                    ; IN:
                    ;   - d0.w = source tile x index (scroll data co-ords)
                    ;   - d1.w = source tile y index (scroll data co-ords)
                    ;   - d2.w = destination tile x-index (display buffer co-ords)
                    ;   - d3.w = destination tile y-index (display buffer co-ords)
                    ;   - a0.l = scroll data structure
                    ;
scr_blit_tile_row   
                    movem.l d0-d7/a0,-(sp) 
                    move.w  #20-1,d7                    ; 20 tiles wide display
.tile_loop
                    bsr     scr_blit_tile
                    add.w   #1,d0                   ; increment x index
                    add.w   #1,d2
                    dbf     d7,.tile_loop

                    movem.l (sp)+,d0-d7/a0
                    rts



                    ; IN:
                    ;   - d0.w = source tile x index (scroll data co-ords)
                    ;   - d1.w = source tile y index (scroll data co-ords)
                    ;   - d2.w = destination tile x-index (display buffer co-ords)
                    ;   - d3.w = destination tile y-index (display buffer co-ords)
                    ;   - a0.l = scroll data structure
scr_blit_tile   
                    movem.l d0-d7/a0,-(sp)
                  ; get tile type value
                    mulu    SCR_TILEDATA_WIDTH(a0),d1       ; get y index into scroll_tile_data
                    add.w   d1,d0                           ; get x,y index into scroll_tile_data 
                    move.l  SCR_TILEDATA_PTR(a0),a2         ; get tile data address 
                    moveq   #0,d5  
                    move.b  (a2,d0.w),d5                    ; get tile type value

                  ; calc source gfx ptr
                    move.l  SCR_TILEGFX_PTR(a0),a2
                    mulu    SCR_TILEGFX_SIZE(a0),d5                    
                    lea     (a2,d5.w),a2                ; source tile gfx ptr

                  ; calc destination gfx ptr
                    move.l  SCR_BUFFER_PTR(a0),a3           ; destination bitplane ptr
                    mulu    SCR_TILEGFX_HEIGHT_PX(a0),d3    ; get raster y from tile y
                    mulu    SCR_BUFFER_WIDTH(a0),d3         ; get y byte offset into bitplane
                    mulu    #2,d2                           ; get x word offset
                    add.w   d2,d3                           ; get x,y byte offset into bitplane
                    lea     (a3,d3.w),a3                    ; desination buffer ptr

                  ; blit tile
                    lea     CUSTOM,a6
                    btst.b  #14-8,DMACONR(a6)
.blit_wait          btst.b  #14-8,DMACONR(a6)
                    bne.s   .blit_wait

                    move.l  #$ffffffff,BLTAFWM(a6)    ; masks
                    move.l  #$09F00000,BLTCON0(a6)    ; D=A, Transfer mode
                    move.l  a2,BLTAPT(a6)             ; src ptr
                    move.w  #0,BLTAMOD(a6)
                    move.l  a3,BLTDPT(a6)             ; dest ptr
                    move.w  #38,BLTDMOD(a6)
                    move.w  #(16<<6)+1,BLTSIZE(a6)           ; 16x16 blit - start   
                    movem.l (sp)+,d0-d7/a0  
                    rts



                    ; ---------------- scroll tile data ---------------
                    ; scroll is currently 16x16 tiles
                    ; horizontal view is 20 tiles (40 bytes = 320 pixels wide)
                    ; visible vertical view is 16 tiles high (16 tiles = 256 pixels high)
                    ; offscreen vertical view is 2 tiles high (2 tiles = 32 pixels high)
                    ; one buffer of tile data = 20 x 18 tiles = 360 bytes
                    ;
                    rsreset
SCR_TILEDATA_PTR            rs.l    1               ; ptr to tile map data
SCR_TILEGFX_PTR             rs.l    1               ; ptr to tile gfx
SCR_TILEGFX_SIZE            rs.w    1               ; Size of each tile in bytes
SCR_TILEGFX_WIDTH_PX        rs.w    1               ; Width of each tile in pixels
SCR_TILEGFX_HEIGHT_PX       rs.w    1               ; Height of each tile in pixels
SCR_TILEDATA_WIDTH          rs.w    1               ; tile map data - number of tiles wide
SCR_TILEDATA_HEIGHT         rs.w    1               ; tile map data - number of tiles high
SCR_VIEW_X                  rs.w    1               ; Left co-ord of view window (pixel value)
SCR_VIEW_X_IDX              rs.w    1               ; Left co-ord of view window (tile x index)
SCR_VIEW_Y                  rs.w    1               ; Top co-ord of view window (pixel value)
SCR_VIEW_Y_IDX              rs.w    1               ; Top co-ord of view window (tile y index)
SCR_BUFFER_PTR              rs.l    1               ; Display buffer ptr
SCR_BUFFER_WIDTH            rs.w    1               ; Display buffer width (bytes)
SCR_BUFFER_HEIGHT           rs.w    1               ; Display buffer height (rasters)
SCR_DISPLAY_WIDTH_TILES     rs.w    1               ; Display Tiles Wide
SCR_DISPLAY_HEIGHT_TILES    rs.w    1               ; Display Tiles High
; soft scroll vales
SCR_VERT_SCROLL_PX          rs.w    1               ; Vertical Scroll Pixel Value (buffer soft scroll)
SCR_HORZ_SCROLL_PX          rs.w    1               ; Horizontal Scroll Pixel Value (buffer soft scroll)
SCR_VERT_SCROLL_SPEED       rs.w    1               ; Vertical Scroll Speed +/-

                      even
scroll_data
.tiledata_ptr           dc.l    scroll_tile_data
.tilegfx_ptr            dc.l    tile_gfx
.tilegfx_size           dc.w    32              ; each tile is 32 bytes in size
.tilegfx_width_px       dc.w    16              ; tile gfx = 16 pixels wide
.tilegfx_height_px      dc.w    16              ; tile gfx = 16 pixles high
.tiledata_width         dc.w    20              ; tiles wide
.tiledata_height        dc.w    18              ; tiles high
.view_x                 dc.w    0               ; world pixel scroll pos (from top left)
.view_x_idx             dc.w    0               ; tile map x index
.view_y                 dc.w    0               ; world pixel scroll pos (from top left)
.view_y_idx             dc.w    0               ; tile map y index
.buffer_ptr             dc.l    bitplane        ; display buffer address
.buffer_width           dc.w    40              ; display buffer width (bytes)
.buffer_height          dc.w    256+32          ; display buffer height (rasters)
.display_tiles_width    dc.w    20              ; the display is 20 tiles wide (visible scroll area)
.display_tiles_high     dc.w    18              ; the display is 18 tiles high (visible scroll area)
.vert_scroll_px         dc.w    0
.horz_scroll_px         dc.w    0
.vert_scroll_speed      dc.w    1               ; vertical scroll speed

scroll_tile_data
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$01,$01,$01,$00,$01,$01,$01,$00,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$01,$00,$00,$01,$00,$01,$00,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$01,$00,$00,$01,$00,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$01,$00,$00,$01,$01,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                        dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


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



