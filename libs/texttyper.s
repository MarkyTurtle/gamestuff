



                    ; IN:
                    ;   d0.w - x pixel pos to start
                    ;   d1.w - y raster offset in bytes
                    ;   a0.l - text string to display (null terminated)
                    ;   a1.l - bitplane to write to
                    ;
write_string
                                ; display loading string
                                movem.l d0-d7/a0-a6,-(a7)
                                move.l  a0,a3                           ; text string ptr
                                move.w  d0,character_x_pos
                                move.w  d1,character_y_offset
                                move.l  a1,a0                           ; bitplane ptr
                                lea.l   menu_font_gfx,a2
                                jsr     display_text
                                movem.l (a7)+,d0-d7/a0-a6
                                rts




                        ; ------------------------- display text -------------------------
                        ; IN:   a0 - typer bitplane
                        ;       a2 - font_gfx
                        ;       a3 - display text
                        ;       d7 - type (x) characters wide
                        ;       d6 - type (x) characters tall 
display_text                    ;move.w  #$0000,character_x_pos                          ; reset x position
                                ;move.w  #$0000,character_y_offset                       ; reset y offset (line position)

.print_char_loop                moveq.l  #$00000000,d0
                                moveq.l  #$00000000,d1
                                moveq.l  #$00000000,d2
                                moveq.l  #$00000000,d3
                                moveq.l  #$00000000,d4

.process_ascii_char             ; process ascii character
                                move.b  (a3)+,d0                        ; get ascii char value
                                cmp.b   #$00,d0                         ; text display NULL terminator
                                beq     .exit_display_text
                                cmp.b   #$0a,d0                         ; line feed
                                beq     .line_feed
                                cmp.b   #$0d,d0                         ; carriage return
                                beq     .carriage_return
                                cmp.b   #$20,d0                         ; space character
                                beq     .space_character
                                bra.s   .print_char

.line_feed                      add.w   #$0140,character_y_offset       ; increase y offset by 1 whole text line (8x40 bytes)
                                bra.s   .process_ascii_char

.carriage_return                move.w  #$0000,character_x_pos          ; reset x position (left hand side)
                                bra.s   .process_ascii_char

.space_character                add.w   #7,character_x_pos
                                bra.s   .process_ascii_char

.print_char                     SUB.B   #$20,D0                         ; font starts at 'space' char (32 ascii)

                                LSL.B   #$00000001,D0                   ; d0 = index to start of char gfx
                                LEA.L   (A2,D0.W),A4                    ; a4 = char gfx ptr
                                MOVE.W  character_x_pos,d1              
                                MOVE.W  D1,D3
                                LSR.W   #$00000003,D1                   ; d1 = byte offset
                                MOVE.W  D1,D4
                                LSL.W   #$00000003,D4                   ; d4 = rounded pixel offset
                                SUB.W   D4,D3                           ; d3 = shift vale
                                BTST.L  #$0000,D1                       ; check of odd bytes offset
                                BEQ.W   .is_even_byte_offset 
                                BCLR.L  #$0000,D1
                                MOVE.W  #$0008,D2
                                BRA.W   .shift_and_print_char
.is_even_byte_offset
                                MOVE.W  #$0000,D2

.shift_and_print_char           LEA.L   (A0,D1.W),A1                    ; a1 = dest ptr + x offset
                                MOVE.W  character_y_offset,D1
                                LEA.L   (A1,D1.W),A1                    ; a1 = dest ptr + y offset
                                MOVE.L  $0000(A4),D0                    ; char line 1
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0000(A1)
                                MOVE.L  $0076(A4),D0                                    ; char line 2
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0028(A1)
                                MOVE.L  $00ec(A4),D0                                    ; char line 3
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0050(A1)
                                MOVE.L  $0162(A4),D0                                    ; char line 4
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0078(A1)
                                MOVE.L  $01d8(A4),D0                                    ; char line 5
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$00a0(A1)
                                MOVE.L  $024e(A4),D0                                    ; char line 6
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$00c8(A1)
                                MOVE.L  $02c4(A4),D0                                    ; char line 7
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$00f0(A1)

                                ADD.W   #$0007,character_x_pos                          ; add character width to x position
                                bra.w   .print_char_loop

                                MOVE.W  #$0000,character_x_pos                          ; reset x position (left hand side)
                                ADD.W   #$0140,character_y_offset                       ; increment line offset (8 rasters = 320 bytes)
                                ;MOVE.W  #$002c,D7                                       ; reset line loop counter (next 45 chars)
                                bra.w   .print_char_loop                             ; do next line loop

.exit_display_text
                                MOVE.W  #$0000,character_x_pos                          ; reset x position
                                MOVE.W  #$0000,character_y_offset                       ; reset y offset (line position)
                                RTS 

character_x_pos                 dc.w    $0000                                           ; typer x - pixel position
character_y_offset              dc.w    $0000                                           ; typer - y - offset (multiple of bytes per raster)


