;
;    NOTES:
;         1) The 'View' represents the scrollers logical view window into the world.
;              i) It represents its pixel position into a larger world defined by the tile-map
;              ii) The world 'units' are pixels to keep things easy and hopefully fast.
;              iii) The view co-ordinates represent the top-left position of the 'View' into the tile-map world
;              iv) The view position is changed by updating the x,y speed/velocity values.
;              v) If the view speed exceeds the tile x or y size then this will result in the scroll buffer being updated more thsn once.
;
;         2) The 'Tile-Map' is a 2d array of values that are used to identify the 'tile' graphics used to build up the scrolling display.
;              i) The maximum tile map size is 4096 tiles wide by 4096 tiles high (max view scroll area of 65536 x 65536)
;              ii) In this verion of the scroller, each Tile is 16x16 pixels in size.
;
;         2) The 'Buffer' represents the memory and data required to display the scrolling 'View'
;              i) It repesents the memory used to build the view using various hardware techniques to provide the illusion on a large scrolling world'
;              ii) The buffer display is built up using a grid of 'Tiles' which are defined in by the 'tile-map'
;
;
;
               rsreset
INIT_TILEMAP_PTR    rs.l      1    ; address ptr to the tile-map
INIT_TILEGFX_PTR    rs.l      1    ; address ptr to the tile-gfx
INIT_TILEMAP_WIDTH  rs.w      1    ; tile-map width (number of tiles wide)
INIT_TILEMAP_HEIGHT rs.w      1    ; tile_map height (number of tiles high)

scr2_init_struct
                    dc.l      0    ; INIT_TILEMAP_PTR 
                    dc.l      0    ; INIT_TILEGFX_PTR
                    dc.w      0    ; INIT_TILEMAP_WIDTH
                    dc.w      0    ; INIT_TILEMAP_HEIGHT



               rsreset
SCR2_VIEW_STRUCT    rs.l      1         ; address pointer to view structure
SCR2_BUFFER_STRUCT  rs.l      1         ; address pointer to buffer structure
SCR2_TILEMAP_STRUCT rs.l      1         ; address pointer to tile-map structure

scr2_struct
                    dc.l      scr2_view_struct
                    dc.l      scr2_buffer_struct
                    dc.l      scr_tilemap_struct


               rsreset
SCR2_VIEW_X_PX      rs.w      1         ; max view xpos = 65535 = 204.8 lo-res screens wide (320px wide)
SCR2_VIEW_Y_PX      rs.w      1         ; max view ypos = 65535 = 256 lo-res screens high (256px high)
SCR2_VIEW_X_VEL     rs.w      1         ; view x velocity in pixels per update
SCR2_VIEW_Y_VEL     rs.w      1         ; view y velocity in pixels per update

scr2_view_struct
                    dc.w      0         ; SCR2_VIEW_X_PX - scroll view window x position 0-65535
                    dc.w      0         ; SCR2_VIEW_Y_PX - scroll view window y position 0-65536
                    dc.w      0         ; SCR2_VIEW_X_VEL - view x velocity in pixels per update
                    dc.w      0         ; SCR2_VIEW_y_VEL - view y velocity in pixels per update

               rsreset
SCR2_BUFFER_PTR          rs.l      1         ; address ptr to the buffer display memory
SCR2_BUFFER_X_PX         rs.w      1         ; buffer x soft scroll position in pixels
SCR2_BUFFER_Y_PX         rs.w      1         ; buffer y soft scroll position in pixels
SCR2_BUFFER_WIDTH_PX     rs.w      1         ; pixel width of the scroll buffer
SCR2_BUFFER_HEIGHT_PX    rs.w      1         ; pixel height of the scroll buffer
SCR2_BUFFER_WIDTH_BYTE   rs.w      1         ; width of buffer in bytes              // TODO: Calculate Value on Initialisation
SCR2_BUFFER_WIDTH_TILES  rs.w      1         ; width of buffer in tiles              // TODO: Calculate Value on Scroller Initialisation


scr2_buffer_struct
                    dc.l      buffer_bitplane     ; SCR2_BUFFER_PTR - address ptr to buffer memory
                    dc.w      0                   ; SCR2_BUFFER_X_PX - buffer x scroll position in pixels 
                    dc.w      0                   ; SCR2_BUFFER_Y_PX - buffer y scroll position in pixels
                    dc.w      320                 ; SCR2_BUFFER_WIDTH in pixels
                    dc.w      288                 ; SCR2_BUFFER_HEIGHT in pixels
                    dc.w      40                  ; SCR2_BUFFER_WIDTH_BYTE
                    dc.w      20                  ; SCR2_BUFFER_WIDTH_TILES

               rsreset
SCR2_TILEMAP_PTR     rs.l      1         ; tile-map address ptr
SCR2_TILEGFX_PTR     rs.l      1         ; tile-map gfx address ptr
SCR2_TILEMAP_WIDTH   rs.w      1         ; tile-map width in tiles
SCR2_TILEMAP_HEIGHT  rs.w      1         ; tile-map height in tiles

scr_tilemap_struct
                    dc.l      0         ; SCR_TILEMAP_PTR
                    dc.l      0         ; SCR_TILEGFX_PTR
                    dc.w      0         ; SCR_TILEMAP_WIDTH
                    dc.w      0         ; SCR_TILEMAP_HEIGHT



               ; IN:
               ;    a0.l - scroll initialisatoin structure
scr2_initialise
               lea       scr2_struct,a1

               ; init scroll structure values from init values
               move.l    SCR2_TILEMAP_STRUCT(a1),a2
               move.l    INIT_TILEMAP_PTR(a0),SCR2_TILEMAP_PTR(a2)
               move.l    INIT_TILEGFX_PTR(a0),SCR2_TILEGFX_PTR(a2)
               move.w    INIT_TILEMAP_WIDTH(a0),SCR2_TILEMAP_WIDTH(a2)
               move.w    INIT_TILEMAP_HEIGHT(a0),SCR2_TILEMAP_HEIGHT(a2)

               ;bsr       scr2_init_copper_wait_table
               bsr       scr2_scr_blit_tile_buffer

               rts



               ; This function schould be called regularly to update the scroll
               ; screen display.
               ;
scr2_scroll_update
            ;jsr     scrv2_vertical_joystick_scroll                ; set vertical scroll speed by joystick input
            ;jsr     scr2_vertical_soft_buffer_scroll             ; update vertical soft scroll values of 'scroll buffer'
            ;jsr     scr2_vertical_soft_view_scroll               ; update vertical soft scoll values of 'view window'
            ;jsr     scr2_vertical_calc_wrap_wait                 ; set vertical scroll copper list buffer wrap values
            ;jsr     scr2_vertical_set_copper_scroll              ; set copper list bitplane ptrs
            ;jsr     scr2_vertical_blit_new_line                  ; check if new vertical data needs to be added to the screen buffer.
            rts

        ; ----------- blit new gfx into display buffer -------------
        ;   IN:
        ;     a0.l = scroll_data
;scr2_vertical_blit_new_line
;          ; check if hard scroll line has changes
;            lea     scroll_data,a0
;            moveq   #0,d0
;            move.w  SCR_VIEW_Y_PX(a0),d0
;            ext.l   d0
;            beq     .cont
;            divs.w  #16,d0
;.cont
;            cmp.w   SCR_VIEW_Y_IDX(a0),d0
;            bgt.s   .add_bottom_row             ; scroll up (new top row required)
;            blt.s   .add_top_row                ; scroll down (new bottom row required)
;            rts                                 ; no new data required
;
;.add_top_row
;            ;tst.w   d0
;            ;bge.s   .no_tilemap_wrap
;.is_tilemap_wrap
;            ;move.w  SCR_TILEDATA_HEIGHT(a0),d0
;.no_tilemap_wrap
;            ;move.w  d0,SCR_VIEW_Y_IDX(a0)      ; store new tile index
;            ;move.w  d0,d1
;
;             ; get left of screen x tile index  (d0)
;            ;move.w  SCR_VIEW_X_IDX(a0),d0
;            ; get destination left x tile index (d2)
;            ;move.w  d0,d2
;
;            ; get desination y tile index (d3)
;            ;moveq   #0,d3
;            ;move.w  SCR_BUFFER_Y_IDX(a0),d3
;
;                    ;   - d0.w = source tile x index (scroll data co-ords)
;                    ;   - d1.w = source tile y index (scroll data co-ords)
;                    ;   - d2.w = destination tile x-index (display buffer co-ords)
;                    ;   - d3.w = destination tile y-index (display buffer co-ords)
;                    ;   - a0.l = scroll data structure
;            ;jsr     scr_blit_tile_row
;            move.w  #$0f0,$DFF180
;            rts
;
;.add_bottom_row
;            ;move.w  d0,d4
;            ;add.w   SCR_DISPLAY_HEIGHT_TILES(a0),d4            
;            ;cmp.w   SCR_TILEDATA_HEIGHT(a0),d4
;            ;blt.s   .no_wrap_bottom
;.is_wrap_bottom
;            ;moveq   #0,d0
;.no_wrap_bottom
;            ; get top of screen y tile index (d1)
;            ;move.w  d0,SCR_VIEW_Y_IDX(a0)             ; store new tile index (top of screen)
;            ;add.w   SCR_DISPLAY_HEIGHT_TILES(a0),d0   ; get y row index for bottom of the screen
;            ;sub.w   #1,d0
;            ;move.w  d0,d1
;
;            ; get left of screen x tile index  (d0)
;            ;move.w  SCR_VIEW_X_IDX(a0),d0
;            ; get destination left x tile index (d2)
;            ;move.w  d0,d2
;
;            ; get desination y tile index (d3)
;            ;moveq   #0,d3
;            ;move.w  SCR_BUFFER_Y_IDX(a0),d3
;
;
;
;                    ;   - d0.w = source tile x index (scroll data co-ords)
;                    ;   - d1.w = source tile y index (scroll data co-ords)
;                    ;   - d2.w = destination tile x-index (display buffer co-ords)
;                    ;   - d3.w = destination tile y-index (display buffer co-ords)
;                    ;   - a0.l = scroll data structure
;            ;jsr     scr_blit_tile_row
;            move.w  #$f00,$DFF180
;            rts



;scr2_vertical_soft_view_scroll
;            lea         scroll_data,a0
;            move.w      SCR_VIEW_Y_PX(a0),d0
;            move.w      SCR_VERT_SCROLL_SPEED(a0),d7
;            add.w       d7,d0                           ; update view y scroll
;
;            move.w      SCR_BUFFER_HEIGHT(a0),d7        ; tile height of scroll
;            muls        SCR_TILEGFX_HEIGHT_PX(a0),d7    ; pixel height of scroll
;
;        ; check scroll down wrap
;.chk_down_wrap
;            cmp.w       d7,d0
;            blt         .chk_up_wrap
;.is_down_wrap
;            sub.w       d7,d0
;            bra         .cont
;
;        ; check scroll up wrap
;.chk_up_wrap
;            cmp.w       #$0000,d0
;            bge         .cont
;.is_up_wrap
;            add.w       d7,d0
;
;        ; store soft scroll value
;.cont
;            move.w      d0,SCR_VIEW_Y_PX(a0)
;
;            rts


;        ; --------------- Do Vertical Soft Scroll based on Scroll Speed ------------
;scr2_vertical_soft_buffer_scroll
;            lea         scroll_data,a0
;            move.w      SCR_BUFFER_Y_PX(a0),d0
;            move.w      SCR_VERT_SCROLL_SPEED(a0),d7
;            add.w       d7,d0                           ; update buffer y scroll
;            ;add.w       d7,SCR_VIEW_Y_PX(a0)            ; update world view y scroll
;
;        ; check scroll down wrap
;.chk_down_wrap
;            cmp.w       SCR_BUFFER_HEIGHT(a0),d0
;            blt         .chk_up_wrap
;.is_down_wrap
;            sub.w       SCR_BUFFER_HEIGHT(a0),d0
;            bra         .cont
;
;        ; check scroll up wrap
;.chk_up_wrap
;            cmp.w       #$0000,d0
;            bge         .cont
;.is_up_wrap
;            add.w       SCR_BUFFER_HEIGHT(a0),d0
;
;        ; store soft scroll value
;.cont
;            move.w      d0,SCR_BUFFER_Y_PX(a0)
;
;        ; update new data tile index (ready for hard-scroll)
;        ; probably move this so it's only executed when hard-scrolling is occurring.
;            tst.w     d0
;            beq.s     .is_zero
;.not_zero
;            ext.l     d0
;            divs      #16,d0
;.is_zero
;            sub.w     #1,d0
;            bpl.s     .is_plus
;.is_neg
;            add.w     SCR_DISPLAY_HEIGHT_TILES(a0),d0
;.is_plus
;            move.w    d0,SCR_BUFFER_Y_IDX(a0)
;
;            rts
;


;        ; ----------------- Set scroll buffer wrap vertical copper wait ------------------
;scr2_vertical_calc_wrap_wait 
;            lea         scroll_data,a0
;            move.w      SCR_BUFFER_Y_PX(a0),d0
;            asl.w       #1,d0
;
;            lea         copper_wait_table,a0
;            moveq       #0,d1
;            moveq       #0,d2
;            move.b      (a0,d0.w),d1            ; bpl wait
;            move.b      1(a0,d0.w),d2           ; copper wait
;
;            lea.l       copper_wrap_wait,a0
;            move.b      d1,(a0)
;            lea.l       copper_wrap_bpl_wait,a0
;            move.b      d2,(a0)
;
;            rts
;


;        ; ------------------ Set scroll buffer top bitplane ptrs in copper ----------------
;scr2_vertical_set_copper_scroll
;            lea         scroll_data,a0
;        ; update bitplane ptrs
;            moveq       #0,d0
;            moveq       #0,d1
;            move.l      #bitplane,d0
;            move.w      SCR_BUFFER_Y_PX(a0),d1
;            mulu        #40,d1
;            add.l       d1,d0
;
;            lea     copper_bpl,a0
;              
;            move.w  d0,2(a0)
;            swap.w  d0
;            move.w  d0,6(a0)
;
;            rts
;





     macro px_to_tile_idx 
px_to_tile_idx_\@
     tst.w     \1
     beq.s     .avoid_div_0
     divs      #16,\1
.avoid_div_0
 
     endm


                    ; ---------------- blit buffer full of tile data to buffer --------------
                    ; Initialise the display 'view' / 'buffer' with a screen of tile-map
                    ; graphics.
                    ; Uses values stored from the initialised 'scr_struct' to construct
                    ; the display.
                    ;
                    ; IN: (No Parameters Required)
                    ;
scr2_scr_blit_tile_buffer
                    lea       scr2_struct,a0
                    move.l    SCR2_VIEW_STRUCT(a0),a1
                    moveq     #0,d0
                    moveq     #0,d1
                    moveq     #0,d2
                    moveq     #0,d3
                    moveq     #0,d4

                  ; calc tile-map Y co-oord (top line's left-most tile index)
.calc_tilemap_x_idx
                    move.w    SCR2_VIEW_X_PX(a1),d0
                    px_to_tile_idx d0

                  ; calc source tile Y co-oord (top line's top-most tile index)
.calc_top_row_idx
                    move.w    SCR2_VIEW_Y_PX(a1),d1 
                    px_to_tile_idx d1

.get_row_count
                    move.l    SCR2_BUFFER_STRUCT(a0),a1
                    move.w    SCR2_BUFFER_HEIGHT_PX(a1),d4 
                    px_to_tile_idx d4
                    subq    #1,d4
.row_loop
                    jsr     scr2_scr_blit_tile_row
                    add.w   #1,d1                           ; increment tile-map y index
                    add.w   #1,d3                           ; increment buffer tile y index
                    dbf     d4,.row_loop

                    rts



                    ; ---------------- blit row of tile data to buffer --------------
                    ; IN:
                    ;   - d0.w = tile-map tile x index (scroll data co-ords)
                    ;   - d1.w = tile-map tile y index (scroll data co-ords)
                    ;   - d2.w = buffer tile x-index (display buffer co-ords)
                    ;   - d3.w = buffer tile y-index (display buffer co-ords)
                    ;   - a0.l = scroll data structure
                    ;
scr2_scr_blit_tile_row   
                    movem.l   d0-d7/a0,-(sp) 
                    move.l    SCR2_BUFFER_STRUCT(a0),a1
                    move.w    SCR2_BUFFER_WIDTH_TILES(a1),d7          ; get number of tiles per row
                    sub.w     #1,d7
.tile_loop
                    bsr       scr2_scr_blit_tile
                    add.w     #1,d0                      ; increment x index
                    add.w     #1,d2
                    dbf       d7,.tile_loop

                    movem.l (sp)+,d0-d7/a0
                    rts



                    ; IN:
                    ;   - d0.w = tile-map tile x index (scroll data co-ords)
                    ;   - d1.w = tile-map tile y index (scroll data co-ords)
                    ;   - d2.w = buffer tile x-index (display buffer co-ords)
                    ;   - d3.w = buffer tile y-index (display buffer co-ords)
                    ;   - a0.l = scroll data structure
scr2_scr_blit_tile   
                    movem.l d0-d7/a0,-(sp)
                    move.l    SCR2_TILEMAP_STRUCT(a0),a1
                    move.l    SCR2_BUFFER_STRUCT(a0),a3
                  ; get tile type value
                    mulu      SCR2_TILEMAP_WIDTH(a1),d1          ; get y index into scroll_tile_data
                    add.w     d1,d0                              ; get x,y index into scroll_tile_data 
                    move.l    SCR2_TILEMAP_PTR(a1),a2            ; get tile data address 
                    moveq     #0,d5  
                    move.b    (a2,d0.w),d5                       ; get tile type value

                  ; calc source gfx ptr
                    move.l    SCR2_TILEGFX_PTR(a1),a2
                    mulu      #32,d5                             ; Tile size in bytes                    
                    lea       (a2,d5.w),a2                       ; source tile gfx ptr

                  ; calc destination gfx ptr
                    move.l  SCR2_BUFFER_PTR(a3),a4               ; destination bitplane ptr
                    mulu    #16,d3                               ; get raster y from tile y (multiply by tile height)
                    mulu    SCR2_BUFFER_WIDTH_BYTE(a3),d3        ; get y byte offset into bitplane
                    mulu    #2,d2                                ; get x word offset
                    add.w   d2,d3                                ; get x,y byte offset into bitplane
                    lea     (a4,d3.w),a4                         ; desination buffer ptr

                  ; blit tile
                    lea     CUSTOM,a6
                    btst.b  #14-8,DMACONR(a6)
.blit_wait          btst.b  #14-8,DMACONR(a6)
                    bne.s   .blit_wait

                    move.l  #$ffffffff,BLTAFWM(a6)    ; masks
                    move.l  #$09F00000,BLTCON0(a6)    ; D=A, Transfer mode
                    move.l  a2,BLTAPT(a6)             ; src ptr
                    move.w  #0,BLTAMOD(a6)
                    move.l  a4,BLTDPT(a6)             ; dest ptr
                    move.w  #38,BLTDMOD(a6)
                    move.w  #(16<<6)+1,BLTSIZE(a6)           ; 16x16 blit - start   
                    movem.l (sp)+,d0-d7/a0  
                    rts



;                    ; ---------------- scroll tile data ---------------
;                    ; scroll is currently 16x16 tiles
;                    ; horizontal view is 20 tiles (40 bytes = 320 pixels wide)
;                    ; visible vertical view is 16 tiles high (16 tiles = 256 pixels high)
;                    ; offscreen vertical view is 2 tiles high (2 tiles = 32 pixels high)
;                    ; one buffer of tile data = 20 x 18 tiles = 360 bytes
;                    ;
;                    rsreset
;SCR_TILEDATA_PTR            rs.l    1               ; ptr to tile map data
;SCR_TILEGFX_PTR             rs.l    1               ; ptr to tile gfx
;SCR_TILEGFX_SIZE            rs.w    1               ; Size of each tile in bytes
;SCR_TILEGFX_WIDTH_PX        rs.w    1               ; Width of each tile in pixels
;SCR_TILEGFX_HEIGHT_PX       rs.w    1               ; Height of each tile in pixels
;SCR_TILEDATA_WIDTH          rs.w    1               ; tile map data - number of tiles wide
;SCR_TILEDATA_HEIGHT         rs.w    1               ; tile map data - number of tiles high;
;
;SCR_VIEW_X_PX               rs.w    1               ; Left co-ord of view window (pixel value)
;SCR_VIEW_X_IDX              rs.w    1               ; Left co-ord of view window (tile x index)
;SCR_VIEW_Y_PX               rs.w    1               ; Top co-ord of view window (pixel value)
;SCR_VIEW_Y_IDX              rs.w    1               ; Top co-ord of view window (tile y index);
;
;SCR_BUFFER_PTR              rs.l    1               ; Display buffer ptr
;SCR_BUFFER_WIDTH            rs.w    1               ; Display buffer width (bytes)
;SCR_BUFFER_HEIGHT           rs.w    1               ; Display buffer height (rasters)
;SCR_DISPLAY_WIDTH_TILES     rs.w    1               ; Display Tiles Wide
;SCR_DISPLAY_HEIGHT_TILES    rs.w    1               ; Display Tiles High
;SCR_BUFFER_Y_PX             rs.w    1               ; Vertical Scroll Pixel Value (buffer soft scroll)
;SCR_BUFFER_X_PX             rs.w    1               ; Horizontal Scroll Pixel Value (buffer soft scroll)
;SCR_BUFFER_Y_IDX            rs.w    1               ; Scroll buffer new data y tile index
;SCR_BUFFER_X_IDX            rs.w    1               ; Scroll buffer new data x tile index
;
;SCR_VERT_SCROLL_SPEED       rs.w    1               ; Vertical Scroll Speed +/-
;


;                      even
;scroll_data
;.tiledata_ptr           dc.l    scroll_tile_data
;.tilegfx_ptr            dc.l    tile_gfx
;.tilegfx_size           dc.w    32              ; each tile is 32 bytes in size
;.tilegfx_width_px       dc.w    16              ; tile gfx = 16 pixels wide
;.tilegfx_height_px      dc.w    16              ; tile gfx = 16 pixles high
;.tiledata_width         dc.w    20              ; tiles wide (columns)
;.tiledata_height        dc.w    40              ; tiles high (lines)
;.view_x                 dc.w    0               ; world pixel scroll pos (from top left)
;.view_x_idx             dc.w    0               ; tile map x index
;.view_y                 dc.w    0               ; world pixel scroll pos (from top left)
;.view_y_idx             dc.w    0               ; tile map y index
;.buffer_ptr             dc.l    bitplane        ; display buffer address
;.buffer_width           dc.w    40              ; display buffer width (bytes)
;.buffer_height          dc.w    256+32          ; display buffer height (rasters)
;.display_tiles_width    dc.w    20              ; the display is 20 tiles wide (visible scroll area)
;.display_tiles_high     dc.w    18              ; the display is 18 tiles high (visible scroll area)
;.vert_scroll_px         dc.w    0
;.horz_scroll_px         dc.w    0
;.vert_scroll_speed      dc.w    1               ; vertical scroll speed
;




;          ; ------------- initialise copper wait table -----------------
;scr2_init_copper_wait_table
;            lea     copper_wait_table,a0
;            lea     scroll_data,a1
;            move.w  SCR_BUFFER_HEIGHT(a1),d0
;            sub.w   #$100,d0
;            bcs     .set_pal_wrap
;          ; set copper offscreen are wrap values
;.set_offscreen_wrap
;            sub.w   #$1,d0
;            bcs     .set_pal_wrap
;.offscreen_loop
;            move.b  #$ff,(a0)+
;            move.b  #$2c,(a0)+
;            tst.w   d0                        ; set z=1 if d0.w == 0
;            dbeq    d0,.offscreen_loop        ; exit loop when d0.w == 0
;          ; set copper pal area wrap values
;.set_pal_wrap
;            move.w  #$2c,d0
;.pal_loop   move.b  #$ff,(a0)+
;            move.b  d0,(a0)+
;            tst.w   d0
;            dbeq    d0,.pal_loop
;
;          ; set copper $ff-$2c
;.set_ntsc_wrap
;            move.w  #$fe,d0
;.ntsc_loop  move.b  d0,(a0)+
;            move.b  d0,(a0)
;            add.b   #$01,(a0)+
;            cmp.b   #$2b,d0
;            dbeq    d0,.ntsc_loop
;
;            lea   copper_wait_table_end,a1
;            cmp.l a0,a1
;            bne.s copper_table_error
;            
;            rts
;
;copper_table_error
;            lea   $dff000,a6
;            move.w  VHPOSR(a6),COLOR00(a6)
;            jmp   copper_table_error
;


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



buffer_bitplane  ; 320 x 288    
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


