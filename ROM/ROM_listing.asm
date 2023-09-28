ca65 V2.19 - Git 4944c92
Main file   : SmartyKit1_ROM.asm
Current file: SmartyKit1_ROM.asm

000000r 1                         .feature c_comments
000000r 1               /*  SmartyKit 1 - ROM source
000000r 1                *  http://www.smartykit.io/
000000r 1                *  Copyright (C) 2020, Sergey Panarin <sergey@smartykit.io>
000000r 1                *
000000r 1                   This program is free software: you can redistribute it and/or modify
000000r 1                   it under the terms of the GNU General Public License as published by
000000r 1                   the Free Software Foundation, either version 3 of the License, or
000000r 1                   (at your option) any later version.
000000r 1                   This program is distributed in the hope that it will be useful,
000000r 1                   but WITHOUT ANY WARRANTY; without even the implied warranty of
000000r 1                   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
000000r 1                   GNU General Public License for more details.
000000r 1                   You should have received a copy of the GNU General Public License
000000r 1                   along with this program.  If not, see <https://www.gnu.org/licenses/>.
000000r 1               */
000000r 1               
000000r 1                         .setcpu "6502"
000000r 1                         .segment "PICTURE"
000000r 1  88 A8 50 07  Woz:      .byte $88, $a8, $50, $07, $61, $92, $94, $67
000004r 1  61 92 94 67  
000008r 1                       ;  .byte "8*8 Pixel Art picture end", $0d, $00
000008r 1               
000008r 1                         .code
000000r 1  EA                     nop
000001r 1                         .segment "C000"
000000r 1  EA                     nop
000001r 1               
000001r 1                         .segment "E000"
000000r 1                         .include "a1basic.asm"
000000r 2               ; Apple 1 BASIC
000000r 2               ;
000000r 2               ; Modifications to build with CC65 by Jeff Tranter <tranter@pobox.com>
000000r 2               ;
000000r 2               ; Apple 1 BASIC was written by Steve Wozniak
000000r 2               ; Uses disassembly copyright 2003 Eric Smith <eric@brouhaha.com>
000000r 2               ; http://www.brouhaha.com/~eric/retrocomputing/apple/apple1/basic/
000000r 2               
000000r 2               Z1d     =       $1D
000000r 2               ch      =       $24     ; horizontal cursor location
000000r 2               var     =       $48
000000r 2               lomem   =       $4A     ; lower limit of memory used by BASIC (2 bytes)
000000r 2               himem   =       $4C     ; upper limit of memory used by BASIC (2 bytes)
000000r 2               rnd     =       $4E     ; random number (2 bytes)
000000r 2               
000000r 2               ; The noun stack and syntax stack appear to overlap, which is OK since
000000r 2               ; they apparently are not used simultaneously.
000000r 2               
000000r 2               ; The noun stack size appears to be 32 entries, based on LDX #$20
000000r 2               ; instruction at e67f.  However, there seems to be enough room for
000000r 2               ; another 8 entries.  The noun stack builds down from noun_stk_<part>+$1f
000000r 2               ; to noun_stk_<part>+$00, indexed by the X register.
000000r 2               
000000r 2               ; Noun stack usage appears to be:
000000r 2               ;   integer:
000000r 2               ;       (noun_stk_h_int,noun_stk_l) = value
000000r 2               ;       noun_stk_h_str = 0
000000r 2               ;   string:
000000r 2               ;       (noun_stk_h_str,noun_stk_l) = pointer to string
000000r 2               ;       noun_stk_h_int = any
000000r 2               ; Since noun_stk_h_str determines whether stack entry is integer or string,
000000r 2               ; strings can't start in zero page.
000000r 2               
000000r 2               noun_stk_l =    $50
000000r 2               syn_stk_h =     $58     ; through $77
000000r 2               noun_stk_h_str = $78
000000r 2               syn_stk_l  =    $80     ; through $9F
000000r 2               noun_stk_h_int = $A0
000000r 2               txtndxstk  =    $A8     ; through $C7
000000r 2               text_index =    $C8     ; index into text being tokenized (in buffer at $0200)
000000r 2               leadbl  =       $C9     ; leading blanks
000000r 2               pp      =       $CA     ; pointer to end of program (2 bytes)
000000r 2               pv      =       $CC     ; pointer to end of variable storage (2 bytes)
000000r 2               acc     =       $CE     ; (2 bytes)
000000r 2               srch    =       $D0
000000r 2               tokndxstk =     $D1
000000r 2               srch2   =       $D2
000000r 2               if_flag =       $D4
000000r 2               cr_flag =       $D5
000000r 2               current_verb =  $D6
000000r 2               precedence =    $D7
000000r 2               x_save  =       $D8
000000r 2               run_flag =      $D9
000000r 2               aux     =       $DA
000000r 2               pline   =       $DC     ; pointer to current program line (2 bytes)
000000r 2               pverb   =       $E0     ; pointer to current verb (2 bytes)
000000r 2               p1      =       $E2
000000r 2               p2      =       $E4
000000r 2               p3      =       $E6
000000r 2               token_index =   $F1    ; pointer used to write tokens into buffer  2 bytes)
000000r 2               pcon    =       $F2    ; temp used in decimal output (2 bytes)
000000r 2               auto_inc =      $F4
000000r 2               auto_ln =       $F6
000000r 2               auto_flag =     $F8
000000r 2               char    =       $F9
000000r 2               leadzr  =       $FA
000000r 2               for_nest_count = $FB    ; count of active (nested) FOR loops
000000r 2               gosub_nest_count = $FC  ; count of active (nested) subroutines calls (GOSUB)
000000r 2               synstkdx =      $FD
000000r 2               synpag  =       $FE
000000r 2               
000000r 2               ; GOSUB stack, max eight entries
000000r 2               ; note that the Apple II version has sixteen entries
000000r 2               gstk_pverbl     =       $0100    ; saved pverb
000000r 2               gstk_pverbh     =       $0108
000000r 2               gstk_plinel     =       $0110    ; saved pline
000000r 2               gstk_plineh     =       $0118
000000r 2               
000000r 2               ; FOR stack, max eight entries
000000r 2               ; note that the Apple II version has sixteen entries
000000r 2               fstk_varl       =       $0120   ; pointer to index variable
000000r 2               fstk_varh       =       $0128
000000r 2               fstk_stepl      =       $0130   ; step value
000000r 2               fstk_steph      =       $0138
000000r 2               fstk_plinel     =       $0140   ; saved pline
000000r 2               fstk_plineh     =       $0148
000000r 2               fstk_pverbl     =       $0150   ; saved pverb
000000r 2               fstk_pverbh     =       $0158
000000r 2               fstk_tol        =       $0160   ; "to" (limit) value
000000r 2               fstk_toh        =       $0168
000000r 2               buffer  =       $0200
000000r 2               ;KBD     =       $D010
000000r 2               ;KBDCR   =       $D011
000000r 2               ;DSP     =       $D012
000000r 2               
000000r 2               ; The program can be relocated to a different address but should be a
000000r 2               ; multiple of $2000.
000000r 2               
000000r 2                       .org    $E000
00E000  2                       .export START
00E000  2  4C B0 E2     START:  JMP     cold            ; BASIC cold start entry point
00E003  2               
00E003  2               ; Get character for keyboard, return in A.
00E003  2  AD 11 D0     rdkey:  LDA     KBDCR           ; Read control register
00E006  2  10 FB                BPL     rdkey           ; Loop if no key pressed
00E008  2  AD 10 D0             LDA     KBD             ; Read key data
00E00B  2  60                   RTS                     ; and return
00E00C  2               
00E00C  2  8A           Se00c:  TXA
00E00D  2  29 20                AND     #$20
00E00F  2  F0 23                BEQ     Le034
00E011  2               
00E011  2  A9 A0        Se011:  LDA     #$A0
00E013  2  85 E4                STA     p2
00E015  2  4C C9 E3             JMP     cout
00E018  2               
00E018  2  A9 20        Se018:  LDA     #$20
00E01A  2               
00E01A  2  C5 24        Se01a:  CMP     ch
00E01C  2  B0 0C                BCS     nextbyte
00E01E  2  A9 8D                LDA     #$8D
00E020  2  A0 07                LDY     #$07
00E022  2  20 C9 E3     Le022:  JSR     cout
00E025  2  A9 A0                LDA     #$A0
00E027  2  88                   DEY
00E028  2  D0 F8                BNE     Le022
00E02A  2               
00E02A  2  A0 00        nextbyte:       LDY     #$00
00E02C  2  B1 E2                LDA     (p1),Y
00E02E  2  E6 E2                INC     p1
00E030  2  D0 02                BNE     Le034
00E032  2  E6 E3                INC     p1+1
00E034  2  60           Le034:  RTS
00E035  2               
00E035  2               ; token $75 - "," in LIST command
00E035  2  20 15 E7     list_comman:    JSR     get16bit
00E038  2  20 76 E5             JSR     find_line2
00E03B  2  A5 E2        Le03b:  LDA     p1
00E03D  2  C5 E6                CMP     p3
00E03F  2  A5 E3                LDA     p1+1
00E041  2  E5 E7                SBC     p3+1
00E043  2  B0 EF                BCS     Le034
00E045  2  20 6D E0             JSR     list_line
00E048  2  4C 3B E0             JMP     Le03b
00E04B  2               
00E04B  2               ; token $76 - LIST command w/ no args
00E04B  2  A5 CA        list_all:       LDA     pp
00E04D  2  85 E2                STA     p1
00E04F  2  A5 CB                LDA     pp+1
00E051  2  85 E3                STA     p1+1
00E053  2  A5 4C                LDA     himem
00E055  2  85 E6                STA     p3
00E057  2  A5 4D                LDA     himem+1
00E059  2  85 E7                STA     p3+1
00E05B  2  D0 DE                BNE     Le03b
00E05D  2               
00E05D  2               ; token $74 - LIST command w/ line number(s)
00E05D  2  20 15 E7     list_cmd:       JSR     get16bit
00E060  2  20 6D E5             JSR     find_line
00E063  2  A5 E4                LDA     p2
00E065  2  85 E2                STA     p1
00E067  2  A5 E5                LDA     p2+1
00E069  2  85 E3                STA     p1+1
00E06B  2  B0 C7                BCS     Le034
00E06D  2               
00E06D  2               ; list one program line
00E06D  2  86 D8        list_line:      STX     x_save
00E06F  2  A9 A0                LDA     #$A0
00E071  2  85 FA                STA     leadzr
00E073  2  20 2A E0             JSR     nextbyte
00E076  2  98                   TYA
00E077  2               
00E077  2               ; list an integer (line number or literal)
00E077  2  85 E4        list_int:       STA     p2
00E079  2  20 2A E0             JSR     nextbyte
00E07C  2  AA                   TAX
00E07D  2  20 2A E0             JSR     nextbyte
00E080  2  20 1B E5             JSR     prdec
00E083  2  20 18 E0     Le083:  JSR     Se018
00E086  2  84 FA                STY     leadzr
00E088  2  AA                   TAX
00E089  2  10 18                BPL     list_token
00E08B  2  0A                   ASL
00E08C  2  10 E9                BPL     list_int
00E08E  2  A5 E4                LDA     p2
00E090  2  D0 03                BNE     Le095
00E092  2  20 11 E0             JSR     Se011
00E095  2  8A           Le095:  TXA
00E096  2  20 C9 E3     Le096:  JSR     cout
00E099  2  A9 25        Le099:  LDA     #$25
00E09B  2  20 1A E0             JSR     Se01a
00E09E  2  AA                   TAX
00E09F  2  30 F5                BMI     Le096
00E0A1  2  85 E4                STA     p2
00E0A3  2               
00E0A3  2               ; list a single token
00E0A3  2  C9 01        list_token:     CMP     #$01
00E0A5  2  D0 05                BNE     Le0ac
00E0A7  2  A6 D8                LDX     x_save
00E0A9  2  4C CD E3             JMP     crout
00E0AC  2  48           Le0ac:  PHA
00E0AD  2  84 CE                STY     acc
00E0AF  2  A2 ED                LDX     #>syntabl2
00E0B1  2  86 CF                STX     acc+1
00E0B3  2  C9 51                CMP     #$51
00E0B5  2  90 04                BCC     Le0bb
00E0B7  2  C6 CF                DEC     acc+1
00E0B9  2  E9 50                SBC     #$50
00E0BB  2  48           Le0bb:  PHA
00E0BC  2  B1 CE                LDA     (acc),Y
00E0BE  2  AA           Le0be:  TAX
00E0BF  2  88                   DEY
00E0C0  2  B1 CE                LDA     (acc),Y
00E0C2  2  10 FA                BPL     Le0be
00E0C4  2  E0 C0                CPX     #$C0
00E0C6  2  B0 04                BCS     Le0cc
00E0C8  2  E0 00                CPX     #$00
00E0CA  2  30 F2                BMI     Le0be
00E0CC  2  AA           Le0cc:  TAX
00E0CD  2  68                   PLA
00E0CE  2  E9 01                SBC     #$01
00E0D0  2  D0 E9                BNE     Le0bb
00E0D2  2  24 E4                BIT     p2
00E0D4  2  30 03                BMI     Le0d9
00E0D6  2  20 F8 EF             JSR     Seff8
00E0D9  2  B1 CE        Le0d9:  LDA     (acc),Y
00E0DB  2  10 10                BPL     Le0ed
00E0DD  2  AA                   TAX
00E0DE  2  29 3F                AND     #$3F
00E0E0  2  85 E4                STA     p2
00E0E2  2  18                   CLC
00E0E3  2  69 A0                ADC     #$A0
00E0E5  2  20 C9 E3             JSR     cout
00E0E8  2  88                   DEY
00E0E9  2  E0 C0                CPX     #$C0
00E0EB  2  90 EC                BCC     Le0d9
00E0ED  2  20 0C E0     Le0ed:  JSR     Se00c
00E0F0  2  68                   PLA
00E0F1  2  C9 5D                CMP     #$5D
00E0F3  2  F0 A4                BEQ     Le099
00E0F5  2  C9 28                CMP     #$28
00E0F7  2  D0 8A                BNE     Le083
00E0F9  2  F0 9E                BEQ     Le099
00E0FB  2               
00E0FB  2               ; token $2A - left paren for substring like A$(3,5)
00E0FB  2  20 18 E1     paren_substr:   JSR     Se118
00E0FE  2  95 50                STA     noun_stk_l,X
00E100  2  D5 78                CMP     noun_stk_h_str,X
00E102  2  90 11        Le102:  BCC     Le115
00E104  2  A0 2B        string_err:     LDY     #$2B
00E106  2  4C E0 E3     go_errmess_1:   JMP     print_err_msg
00E109  2               
00E109  2               ; token $2B - comma for substring like A$(3,5)
00E109  2  20 34 EE     comma_substr:   JSR     getbyte
00E10C  2  D5 50                CMP     noun_stk_l,X
00E10E  2  90 F4                BCC     string_err
00E110  2  20 E4 EF             JSR     Sefe4
00E113  2  95 78                STA     noun_stk_h_str,X
00E115  2  4C 23 E8     Le115:  JMP     left_paren
00E118  2               
00E118  2  20 34 EE     Se118:  JSR     getbyte
00E11B  2  F0 E7                BEQ     string_err
00E11D  2  38                   SEC
00E11E  2  E9 01                SBC     #$01
00E120  2  60                   RTS
00E121  2               
00E121  2               ; token $42 - left paren for string array as dest
00E121  2               ; A$(1)="FOO"
00E121  2  20 18 E1     str_arr_dest:   JSR     Se118
00E124  2  95 50                STA     noun_stk_l,X
00E126  2  18                   CLC
00E127  2  F5 78                SBC     noun_stk_h_str,X
00E129  2  4C 02 E1             JMP     Le102
00E12C  2  A0 14        Le12c:  LDY     #$14
00E12E  2  D0 D6                BNE     go_errmess_1
00E130  2               
00E130  2               ; token $43 - comma, next var in DIM statement is string
00E130  2               ; token $4E - "DIM", next var in DIM is string
00E130  2  20 18 E1     dim_str:        JSR     Se118
00E133  2  E8                   INX
00E134  2  B5 50        Le134:  LDA     noun_stk_l,X
00E136  2  85 DA                STA     aux
00E138  2  65 CE                ADC     acc
00E13A  2  48                   PHA
00E13B  2  A8                   TAY
00E13C  2  B5 78                LDA     noun_stk_h_str,X
00E13E  2  85 DB                STA     aux+1
00E140  2  65 CF                ADC     acc+1
00E142  2  48                   PHA
00E143  2  C4 CA                CPY     pp
00E145  2  E5 CB                SBC     pp+1
00E147  2  B0 E3                BCS     Le12c
00E149  2  A5 DA                LDA     aux
00E14B  2  69 FE                ADC     #$FE
00E14D  2  85 DA                STA     aux
00E14F  2  A9 FF                LDA     #$FF
00E151  2  A8                   TAY
00E152  2  65 DB                ADC     aux+1
00E154  2  85 DB                STA     aux+1
00E156  2  C8           Le156:  INY
00E157  2  B1 DA                LDA     (aux),Y
00E159  2  D9 CC 00             CMP     pv,Y
00E15C  2  D0 0F                BNE     Le16d
00E15E  2  98                   TYA
00E15F  2  F0 F5                BEQ     Le156
00E161  2  68           Le161:  PLA
00E162  2  91 DA                STA     (aux),Y
00E164  2  99 CC 00             STA     pv,Y
00E167  2  88                   DEY
00E168  2  10 F7                BPL     Le161
00E16A  2  E8                   INX
00E16B  2  60                   RTS
00E16C  2  EA                   NOP
00E16D  2  A0 80        Le16d:  LDY     #$80
00E16F  2  D0 95        Le16f:  BNE     go_errmess_1
00E171  2               
00E171  2               ; token ???
00E171  2  A9 00        input_str:      LDA     #$00
00E173  2  20 0A E7             JSR     push_a_noun_stk
00E176  2  A0 02                LDY     #$02
00E178  2  94 78                STY     noun_stk_h_str,X
00E17A  2  20 0A E7             JSR     push_a_noun_stk
00E17D  2  A9 BF                LDA     #$BF                    ; '?'
00E17F  2  20 C9 E3             JSR     cout
00E182  2  A0 00                LDY     #$00
00E184  2  20 9E E2             JSR     read_line
00E187  2  94 78                STY     noun_stk_h_str,X
00E189  2  EA                   NOP
00E18A  2  EA                   NOP
00E18B  2  EA                   NOP
00E18C  2               
00E18C  2               ; token $70 - string literal
00E18C  2  B5 51        string_lit:     LDA     noun_stk_l+1,X
00E18E  2  85 CE                STA     acc
00E190  2  B5 79                LDA     noun_stk_h_str+1,X
00E192  2  85 CF                STA     acc+1
00E194  2  E8                   INX
00E195  2  E8                   INX
00E196  2  20 BC E1             JSR     Se1bc
00E199  2  B5 4E        Le199:  LDA     rnd,X
00E19B  2  D5 76                CMP     syn_stk_h+30,X
00E19D  2  B0 15                BCS     Le1b4
00E19F  2  F6 4E                INC     rnd,X
00E1A1  2  A8                   TAY
00E1A2  2  B1 CE                LDA     (acc),Y
00E1A4  2  B4 50                LDY     noun_stk_l,X
00E1A6  2  C4 E4                CPY     p2
00E1A8  2  90 04                BCC     Le1ae
00E1AA  2  A0 83                LDY     #$83
00E1AC  2  D0 C1                BNE     Le16f
00E1AE  2  91 DA        Le1ae:  STA     (aux),Y
00E1B0  2  F6 50                INC     noun_stk_l,X
00E1B2  2  90 E5                BCC     Le199
00E1B4  2  B4 50        Le1b4:  LDY     noun_stk_l,X
00E1B6  2  8A                   TXA
00E1B7  2  91 DA                STA     (aux),Y
00E1B9  2  E8                   INX
00E1BA  2  E8                   INX
00E1BB  2  60                   RTS
00E1BC  2               
00E1BC  2  B5 51        Se1bc:  LDA     noun_stk_l+1,X
00E1BE  2  85 DA                STA     aux
00E1C0  2  38                   SEC
00E1C1  2  E9 02                SBC     #$02
00E1C3  2  85 E4                STA     p2
00E1C5  2  B5 79                LDA     noun_stk_h_str+1,X
00E1C7  2  85 DB                STA     aux+1
00E1C9  2  E9 00                SBC     #$00
00E1CB  2  85 E5                STA     p2+1
00E1CD  2  A0 00                LDY     #$00
00E1CF  2  B1 E4                LDA     (p2),Y
00E1D1  2  18                   CLC
00E1D2  2  E5 DA                SBC     aux
00E1D4  2  85 E4                STA     p2
00E1D6  2  60                   RTS
00E1D7  2               
00E1D7  2               ; token $39 - "=" for string equality operator
00E1D7  2  B5 53        string_eq:      LDA     noun_stk_l+3,X
00E1D9  2  85 CE                STA     acc
00E1DB  2  B5 7B                LDA     noun_stk_h_str+3,X
00E1DD  2  85 CF                STA     acc+1
00E1DF  2  B5 51                LDA     noun_stk_l+1,X
00E1E1  2  85 DA                STA     aux
00E1E3  2  B5 79                LDA     noun_stk_h_str+1,X
00E1E5  2  85 DB                STA     aux+1
00E1E7  2  E8                   INX
00E1E8  2  E8                   INX
00E1E9  2  E8                   INX
00E1EA  2  A0 00                LDY     #$00
00E1EC  2  94 78                STY     noun_stk_h_str,X
00E1EE  2  94 A0                STY     noun_stk_h_int,X
00E1F0  2  C8                   INY
00E1F1  2  94 50                STY     noun_stk_l,X
00E1F3  2  B5 4D        Le1f3:  LDA     himem+1,X
00E1F5  2  D5 75                CMP     syn_stk_h+29,X
00E1F7  2  08                   PHP
00E1F8  2  48                   PHA
00E1F9  2  B5 4F                LDA     rnd+1,X
00E1FB  2  D5 77                CMP     syn_stk_h+31,X
00E1FD  2  90 07                BCC     Le206
00E1FF  2  68                   PLA
00E200  2  28                   PLP
00E201  2  B0 02                BCS     Le205
00E203  2  56 50        Le203:  LSR     noun_stk_l,X
00E205  2  60           Le205:  RTS
00E206  2  A8           Le206:  TAY
00E207  2  B1 CE                LDA     (acc),Y
00E209  2  85 E4                STA     p2
00E20B  2  68                   PLA
00E20C  2  A8                   TAY
00E20D  2  28                   PLP
00E20E  2  B0 F3                BCS     Le203
00E210  2  B1 DA                LDA     (aux),Y
00E212  2  C5 E4                CMP     p2
00E214  2  D0 ED                BNE     Le203
00E216  2  F6 4F                INC     rnd+1,X
00E218  2  F6 4D                INC     himem+1,X
00E21A  2  B0 D7                BCS     Le1f3
00E21C  2               
00E21C  2               ; token $3A - "#" for string inequality operator
00E21C  2  20 D7 E1     string_neq:     JSR     string_eq
00E21F  2  4C 36 E7             JMP     not_op
00E222  2               
00E222  2               ; token $14 - "*" for numeric multiplication
00E222  2  20 54 E2     mult_op:        JSR     Se254
00E225  2  06 CE        Le225:  ASL     acc
00E227  2  26 CF                ROL     acc+1
00E229  2  90 0D                BCC     Le238
00E22B  2  18                   CLC
00E22C  2  A5 E6                LDA     p3
00E22E  2  65 DA                ADC     aux
00E230  2  85 E6                STA     p3
00E232  2  A5 E7                LDA     p3+1
00E234  2  65 DB                ADC     aux+1
00E236  2  85 E7                STA     p3+1
00E238  2  88           Le238:  DEY
00E239  2  F0 09                BEQ     Le244
00E23B  2  06 E6                ASL     p3
00E23D  2  26 E7                ROL     p3+1
00E23F  2  10 E4                BPL     Le225
00E241  2  4C 7E E7             JMP     Le77e
00E244  2  A5 E6        Le244:  LDA     p3
00E246  2  20 08 E7             JSR     push_ya_noun_stk
00E249  2  A5 E7                LDA     p3+1
00E24B  2  95 A0                STA     noun_stk_h_int,X
00E24D  2  06 E5                ASL     p2+1
00E24F  2  90 28                BCC     Le279
00E251  2  4C 6F E7             JMP     negate
00E254  2               
00E254  2  A9 55        Se254:  LDA     #$55
00E256  2  85 E5                STA     p2+1
00E258  2  20 5B E2             JSR     Se25b
00E25B  2               
00E25B  2  A5 CE        Se25b:  LDA     acc
00E25D  2  85 DA                STA     aux
00E25F  2  A5 CF                LDA     acc+1
00E261  2  85 DB                STA     aux+1
00E263  2  20 15 E7             JSR     get16bit
00E266  2  84 E6                STY     p3
00E268  2  84 E7                STY     p3+1
00E26A  2  A5 CF                LDA     acc+1
00E26C  2  10 09                BPL     Le277
00E26E  2  CA                   DEX
00E26F  2  06 E5                ASL     p2+1
00E271  2  20 6F E7             JSR     negate
00E274  2  20 15 E7             JSR     get16bit
00E277  2  A0 10        Le277:  LDY     #$10
00E279  2  60           Le279:  RTS
00E27A  2               
00E27A  2               ; token $1f - "MOD"
00E27A  2  20 6C EE     mod_op: JSR     See6c
00E27D  2  F0 C5                BEQ     Le244
00E27F  2  FF                   .byte   $FF
00E280  2  C9 84        Le280:  CMP     #$84
00E282  2  D0 02                BNE     Le286
00E284  2  46 F8                LSR     auto_flag
00E286  2  C9 DF        Le286:  CMP     #$DF
00E288  2  F0 11                BEQ     Le29b
00E28A  2  C9 9B                CMP     #$9B
00E28C  2  F0 06                BEQ     Le294
00E28E  2  99 00 02             STA     buffer,Y
00E291  2  C8                   INY
00E292  2  10 0A                BPL     read_line
00E294  2  A0 8B        Le294:  LDY     #$8B
00E296  2  20 C4 E3             JSR     Se3c4
00E299  2               
00E299  2  A0 01        Se299:  LDY     #$01
00E29B  2  88           Le29b:  DEY
00E29C  2  30 F6                BMI     Le294
00E29E  2               
00E29E  2               ; read a line from keyboard (using rdkey) into buffer
00E29E  2  20 03 E0     read_line:      JSR     rdkey
00E2A1  2  EA                   NOP
00E2A2  2  EA                   NOP
00E2A3  2  20 C9 E3             JSR     cout
00E2A6  2  C9 8D                CMP     #$8D
00E2A8  2  D0 D6                BNE     Le280
00E2AA  2  A9 DF                LDA     #$DF
00E2AC  2  99 00 02             STA     buffer,Y
00E2AF  2  60                   RTS
00E2B0  2  20 D3 EF     cold:   JSR     mem_init_4k
00E2B3  2                       .export warm
00E2B3  2  20 CD E3     warm:   JSR     crout           ; BASIC warm start entry point
00E2B6  2  46 D9        Le2b6:  LSR     run_flag
00E2B8  2  A9 BE                LDA     #'>'+$80        ; Prompt character (high bit set)
00E2BA  2  20 C9 E3             JSR     cout
00E2BD  2  A0 00                LDY     #$00
00E2BF  2  84 FA                STY     leadzr
00E2C1  2  24 F8                BIT     auto_flag
00E2C3  2  10 0C                BPL     Le2d1
00E2C5  2  A6 F6                LDX     auto_ln
00E2C7  2  A5 F7                LDA     auto_ln+1
00E2C9  2  20 1B E5             JSR     prdec
00E2CC  2  A9 A0                LDA     #$A0
00E2CE  2  20 C9 E3             JSR     cout
00E2D1  2  A2 FF        Le2d1:  LDX     #$FF
00E2D3  2  9A                   TXS
00E2D4  2  20 9E E2             JSR     read_line
00E2D7  2  84 F1                STY     token_index
00E2D9  2  8A                   TXA
00E2DA  2  85 C8                STA     text_index
00E2DC  2  A2 20                LDX     #$20
00E2DE  2  20 91 E4             JSR     Se491
00E2E1  2  A5 C8                LDA     text_index
00E2E3  2  69 00                ADC     #$00
00E2E5  2  85 E0                STA     pverb
00E2E7  2  A9 00                LDA     #$00
00E2E9  2  AA                   TAX
00E2EA  2  69 02                ADC     #$02
00E2EC  2  85 E1                STA     pverb+1
00E2EE  2  A1 E0                LDA     (pverb,X)
00E2F0  2  29 F0                AND     #$F0
00E2F2  2  C9 B0                CMP     #$B0
00E2F4  2  F0 03                BEQ     Le2f9
00E2F6  2  4C 83 E8             JMP     Le883
00E2F9  2  A0 02        Le2f9:  LDY     #$02
00E2FB  2  B1 E0        Le2fb:  LDA     (pverb),Y
00E2FD  2  99 CD 00             STA     pv+1,Y
00E300  2  88                   DEY
00E301  2  D0 F8                BNE     Le2fb
00E303  2  20 8A E3             JSR     Se38a
00E306  2  A5 F1                LDA     token_index
00E308  2  E5 C8                SBC     text_index
00E30A  2  C9 04                CMP     #$04
00E30C  2  F0 A8                BEQ     Le2b6
00E30E  2  91 E0                STA     (pverb),Y
00E310  2  A5 CA                LDA     pp
00E312  2  F1 E0                SBC     (pverb),Y
00E314  2  85 E4                STA     p2
00E316  2  A5 CB                LDA     pp+1
00E318  2  E9 00                SBC     #$00
00E31A  2  85 E5                STA     p2+1
00E31C  2  A5 E4                LDA     p2
00E31E  2  C5 CC                CMP     pv
00E320  2  A5 E5                LDA     p2+1
00E322  2  E5 CD                SBC     pv+1
00E324  2  90 45                BCC     Le36b
00E326  2  A5 CA        Le326:  LDA     pp
00E328  2  F1 E0                SBC     (pverb),Y
00E32A  2  85 E6                STA     p3
00E32C  2  A5 CB                LDA     pp+1
00E32E  2  E9 00                SBC     #$00
00E330  2  85 E7                STA     p3+1
00E332  2  B1 CA                LDA     (pp),Y
00E334  2  91 E6                STA     (p3),Y
00E336  2  E6 CA                INC     pp
00E338  2  D0 02                BNE     Le33c
00E33A  2  E6 CB                INC     pp+1
00E33C  2  A5 E2        Le33c:  LDA     p1
00E33E  2  C5 CA                CMP     pp
00E340  2  A5 E3                LDA     p1+1
00E342  2  E5 CB                SBC     pp+1
00E344  2  B0 E0                BCS     Le326
00E346  2  B5 E4        Le346:  LDA     p2,X
00E348  2  95 CA                STA     pp,X
00E34A  2  CA                   DEX
00E34B  2  10 F9                BPL     Le346
00E34D  2  B1 E0                LDA     (pverb),Y
00E34F  2  A8                   TAY
00E350  2  88           Le350:  DEY
00E351  2  B1 E0                LDA     (pverb),Y
00E353  2  91 E6                STA     (p3),Y
00E355  2  98                   TYA
00E356  2  D0 F8                BNE     Le350
00E358  2  24 F8                BIT     auto_flag
00E35A  2  10 09                BPL     Le365
00E35C  2  B5 F7        Le35c:  LDA     auto_ln+1,X
00E35E  2  75 F5                ADC     auto_inc+1,X
00E360  2  95 F7                STA     auto_ln+1,X
00E362  2  E8                   INX
00E363  2  F0 F7                BEQ     Le35c
00E365  2  10 7E        Le365:  BPL     Le3e5
00E367  2  00 00 00 00          .byte   $00,$00,$00,$00
00E36B  2  A0 14        Le36b:  LDY     #$14
00E36D  2  D0 71                BNE     print_err_msg
00E36F  2               
00E36F  2               ; token $0a - "," in DEL command
00E36F  2  20 15 E7     del_comma:      JSR     get16bit
00E372  2  A5 E2                LDA     p1
00E374  2  85 E6                STA     p3
00E376  2  A5 E3                LDA     p1+1
00E378  2  85 E7                STA     p3+1
00E37A  2  20 75 E5             JSR     find_line1
00E37D  2  A5 E2                LDA     p1
00E37F  2  85 E4                STA     p2
00E381  2  A5 E3                LDA     p1+1
00E383  2  85 E5                STA     p2+1
00E385  2  D0 0E                BNE     Le395
00E387  2               
00E387  2               ; token $09 - "DEL"
00E387  2  20 15 E7     del_cmd:        JSR     get16bit
00E38A  2               
00E38A  2  20 6D E5     Se38a:  JSR     find_line
00E38D  2  A5 E6                LDA     p3
00E38F  2  85 E2                STA     p1
00E391  2  A5 E7                LDA     p3+1
00E393  2  85 E3                STA     p1+1
00E395  2  A0 00        Le395:  LDY     #$00
00E397  2  A5 CA        Le397:  LDA     pp
00E399  2  C5 E4                CMP     p2
00E39B  2  A5 CB                LDA     pp+1
00E39D  2  E5 E5                SBC     p2+1
00E39F  2  B0 16                BCS     Le3b7
00E3A1  2  A5 E4                LDA     p2
00E3A3  2  D0 02                BNE     Le3a7
00E3A5  2  C6 E5                DEC     p2+1
00E3A7  2  C6 E4        Le3a7:  DEC     p2
00E3A9  2  A5 E6                LDA     p3
00E3AB  2  D0 02                BNE     Le3af
00E3AD  2  C6 E7                DEC     p3+1
00E3AF  2  C6 E6        Le3af:  DEC     p3
00E3B1  2  B1 E4                LDA     (p2),Y
00E3B3  2  91 E6                STA     (p3),Y
00E3B5  2  90 E0                BCC     Le397
00E3B7  2  A5 E6        Le3b7:  LDA     p3
00E3B9  2  85 CA                STA     pp
00E3BB  2  A5 E7                LDA     p3+1
00E3BD  2  85 CB                STA     pp+1
00E3BF  2  60                   RTS
00E3C0  2  20 C9 E3     Le3c0:  JSR     cout
00E3C3  2  C8                   INY
00E3C4  2               
00E3C4  2  B9 00 EB     Se3c4:  LDA     error_msg_tbl,Y
00E3C7  2  30 F7                BMI     Le3c0
00E3C9  2               
00E3C9  2  C9 8D        cout:   CMP     #$8D
00E3CB  2  D0 06                BNE     Le3d3
00E3CD  2               
00E3CD  2  A9 00        crout:  LDA     #$00            ; character output
00E3CF  2  85 24                STA     ch
00E3D1  2  A9 8D                LDA     #$8D
00E3D3  2  E6 24        Le3d3:  INC     ch
00E3D5  2               
00E3D5  2               ; Send character to display. Char is in A.
00E3D5  2  2C 12 D0     Le3d5:  BIT     DSP          ; See if display ready
00E3D8  2  30 FB                BMI     Le3d5        ; Loop if not
00E3DA  2  8D 12 D0             STA     DSP          ; Write display data
00E3DD  2  60                   RTS                  ; and return
00E3DE  2               
00E3DE  2  A0 06        too_long_err:   LDY     #$06
00E3E0  2               
00E3E0  2  20 D3 EE     print_err_msg:  JSR     print_err_msg1  ; print error message specified in Y
00E3E3  2  24 D9                BIT     run_flag
00E3E5  2  30 03        Le3e5:  BMI     Le3ea
00E3E7  2  4C B6 E2             JMP     Le2b6
00E3EA  2  4C 9A EB     Le3ea:  JMP     Leb9a
00E3ED  2  2A           Le3ed:  ROL
00E3EE  2  69 A0                ADC     #$A0
00E3F0  2  DD 00 02             CMP     buffer,X
00E3F3  2  D0 53                BNE     Le448
00E3F5  2  B1 FE                LDA     (synpag),Y
00E3F7  2  0A                   ASL
00E3F8  2  30 06                BMI     Le400
00E3FA  2  88                   DEY
00E3FB  2  B1 FE                LDA     (synpag),Y
00E3FD  2  30 29                BMI     Le428
00E3FF  2  C8                   INY
00E400  2  86 C8        Le400:  STX     text_index
00E402  2  98                   TYA
00E403  2  48                   PHA
00E404  2  A2 00                LDX     #$00
00E406  2  A1 FE                LDA     (synpag,X)
00E408  2  AA                   TAX
00E409  2  4A           Le409:  LSR
00E40A  2  49 48                EOR     #$48
00E40C  2  11 FE                ORA     (synpag),Y
00E40E  2  C9 C0                CMP     #$C0
00E410  2  90 01                BCC     Le413
00E412  2  E8                   INX
00E413  2  C8           Le413:  INY
00E414  2  D0 F3                BNE     Le409
00E416  2  68                   PLA
00E417  2  A8                   TAY
00E418  2  8A                   TXA
00E419  2  4C C0 E4             JMP     Le4c0
00E41C  2               
00E41C  2               ; write a token to the buffer
00E41C  2               ; buffer [++tokndx] = A
00E41C  2  E6 F1        put_token:      INC     token_index
00E41E  2  A6 F1                LDX     token_index
00E420  2  F0 BC                BEQ     too_long_err
00E422  2  9D 00 02             STA     buffer,X
00E425  2  60           Le425:  RTS
00E426  2  A6 C8        Le426:  LDX     text_index
00E428  2  A9 A0        Le428:  LDA     #$A0
00E42A  2  E8           Le42a:  INX
00E42B  2  DD 00 02             CMP     buffer,X
00E42E  2  B0 FA                BCS     Le42a
00E430  2  B1 FE                LDA     (synpag),Y
00E432  2  29 3F                AND     #$3F
00E434  2  4A                   LSR
00E435  2  D0 B6                BNE     Le3ed
00E437  2  BD 00 02             LDA     buffer,X
00E43A  2  B0 06                BCS     Le442
00E43C  2  69 3F                ADC     #$3F
00E43E  2  C9 1A                CMP     #$1A
00E440  2  90 6F                BCC     Le4b1
00E442  2  69 4F        Le442:  ADC     #$4F
00E444  2  C9 0A                CMP     #$0A
00E446  2  90 69                BCC     Le4b1
00E448  2  A6 FD        Le448:  LDX     synstkdx
00E44A  2  C8           Le44a:  INY
00E44B  2  B1 FE                LDA     (synpag),Y
00E44D  2  29 E0                AND     #$E0
00E44F  2  C9 20                CMP     #$20
00E451  2  F0 7A                BEQ     Le4cd
00E453  2  B5 A8                LDA     txtndxstk,X
00E455  2  85 C8                STA     text_index
00E457  2  B5 D1                LDA     tokndxstk,X
00E459  2  85 F1                STA     token_index
00E45B  2  88           Le45b:  DEY
00E45C  2  B1 FE                LDA     (synpag),Y
00E45E  2  0A                   ASL
00E45F  2  10 FA                BPL     Le45b
00E461  2  88                   DEY
00E462  2  B0 38                BCS     Le49c
00E464  2  0A                   ASL
00E465  2  30 35                BMI     Le49c
00E467  2  B4 58                LDY     syn_stk_h,X
00E469  2  84 FF                STY     synpag+1
00E46B  2  B4 80                LDY     syn_stk_l,X
00E46D  2  E8                   INX
00E46E  2  10 DA                BPL     Le44a
00E470  2  F0 B3        Le470:  BEQ     Le425
00E472  2  C9 7E                CMP     #$7E
00E474  2  B0 22                BCS     Le498
00E476  2  CA                   DEX
00E477  2  10 04                BPL     Le47d
00E479  2  A0 06                LDY     #$06
00E47B  2  10 29                BPL     go_errmess_2
00E47D  2  94 80        Le47d:  STY     syn_stk_l,X
00E47F  2  A4 FF                LDY     synpag+1
00E481  2  94 58                STY     syn_stk_h,X
00E483  2  A4 C8                LDY     text_index
00E485  2  94 A8                STY     txtndxstk,X
00E487  2  A4 F1                LDY     token_index
00E489  2  94 D1                STY     tokndxstk,X
00E48B  2  29 1F                AND     #$1F
00E48D  2  A8                   TAY
00E48E  2  B9 20 EC             LDA     syntabl_index,Y
00E491  2               
00E491  2  0A           Se491:  ASL
00E492  2  A8                   TAY
00E493  2  A9 76                LDA     #(>syntabl_index)>>1
00E495  2  2A                   ROL
00E496  2  85 FF                STA     synpag+1
00E498  2  D0 01        Le498:  BNE     Le49b
00E49A  2  C8                   INY
00E49B  2  C8           Le49b:  INY
00E49C  2  86 FD        Le49c:  STX     synstkdx
00E49E  2  B1 FE                LDA     (synpag),Y
00E4A0  2  30 84                BMI     Le426
00E4A2  2  D0 05                BNE     Le4a9
00E4A4  2  A0 0E                LDY     #$0E
00E4A6  2  4C E0 E3     go_errmess_2:   JMP     print_err_msg
00E4A9  2  C9 03        Le4a9:  CMP     #$03
00E4AB  2  B0 C3                BCS     Le470
00E4AD  2  4A                   LSR
00E4AE  2  A6 C8                LDX     text_index
00E4B0  2  E8                   INX
00E4B1  2  BD 00 02     Le4b1:  LDA     buffer,X
00E4B4  2  90 04                BCC     Le4ba
00E4B6  2  C9 A2                CMP     #$A2
00E4B8  2  F0 0A                BEQ     Le4c4
00E4BA  2  C9 DF        Le4ba:  CMP     #$DF
00E4BC  2  F0 06                BEQ     Le4c4
00E4BE  2  86 C8                STX     text_index
00E4C0  2  20 1C E4     Le4c0:  JSR     put_token
00E4C3  2  C8                   INY
00E4C4  2  88           Le4c4:  DEY
00E4C5  2  A6 FD                LDX     synstkdx
00E4C7  2  B1 FE        Le4c7:  LDA     (synpag),Y
00E4C9  2  88                   DEY
00E4CA  2  0A                   ASL
00E4CB  2  10 CF                BPL     Le49c
00E4CD  2  B4 58        Le4cd:  LDY     syn_stk_h,X
00E4CF  2  84 FF                STY     synpag+1
00E4D1  2  B4 80                LDY     syn_stk_l,X
00E4D3  2  E8                   INX
00E4D4  2  B1 FE                LDA     (synpag),Y
00E4D6  2  29 9F                AND     #$9F
00E4D8  2  D0 ED                BNE     Le4c7
00E4DA  2  85 F2                STA     pcon
00E4DC  2  85 F3                STA     pcon+1
00E4DE  2  98                   TYA
00E4DF  2  48                   PHA
00E4E0  2  86 FD                STX     synstkdx
00E4E2  2  B4 D0                LDY     srch,X
00E4E4  2  84 C9                STY     leadbl
00E4E6  2  18                   CLC
00E4E7  2  A9 0A        Le4e7:  LDA     #$0A
00E4E9  2  85 F9                STA     char
00E4EB  2  A2 00                LDX     #$00
00E4ED  2  C8                   INY
00E4EE  2  B9 00 02             LDA     buffer,Y
00E4F1  2  29 0F                AND     #$0F
00E4F3  2  65 F2        Le4f3:  ADC     pcon
00E4F5  2  48                   PHA
00E4F6  2  8A                   TXA
00E4F7  2  65 F3                ADC     pcon+1
00E4F9  2  30 1C                BMI     Le517
00E4FB  2  AA                   TAX
00E4FC  2  68                   PLA
00E4FD  2  C6 F9                DEC     char
00E4FF  2  D0 F2                BNE     Le4f3
00E501  2  85 F2                STA     pcon
00E503  2  86 F3                STX     pcon+1
00E505  2  C4 F1                CPY     token_index
00E507  2  D0 DE                BNE     Le4e7
00E509  2  A4 C9                LDY     leadbl
00E50B  2  C8                   INY
00E50C  2  84 F1                STY     token_index
00E50E  2  20 1C E4             JSR     put_token
00E511  2  68                   PLA
00E512  2  A8                   TAY
00E513  2  A5 F3                LDA     pcon+1
00E515  2  B0 A9                BCS     Le4c0
00E517  2  A0 00        Le517:  LDY     #$00
00E519  2  10 8B                BPL     go_errmess_2
00E51B  2               
00E51B  2  85 F3        prdec:  STA     pcon+1  ; output A:X in decimal
00E51D  2  86 F2                STX     pcon
00E51F  2  A2 04                LDX     #$04
00E521  2  86 C9                STX     leadbl
00E523  2  A9 B0        Le523:  LDA     #$B0
00E525  2  85 F9                STA     char
00E527  2  A5 F2        Le527:  LDA     pcon
00E529  2  DD 63 E5             CMP     dectabl,X
00E52C  2  A5 F3                LDA     pcon+1
00E52E  2  FD 68 E5             SBC     dectabh,X
00E531  2  90 0D                BCC     Le540
00E533  2  85 F3                STA     pcon+1
00E535  2  A5 F2                LDA     pcon
00E537  2  FD 63 E5             SBC     dectabl,X
00E53A  2  85 F2                STA     pcon
00E53C  2  E6 F9                INC     char
00E53E  2  D0 E7                BNE     Le527
00E540  2  A5 F9        Le540:  LDA     char
00E542  2  E8                   INX
00E543  2  CA                   DEX
00E544  2  F0 0E                BEQ     Le554
00E546  2  C9 B0                CMP     #$B0
00E548  2  F0 02                BEQ     Le54c
00E54A  2  85 C9                STA     leadbl
00E54C  2  24 C9        Le54c:  BIT     leadbl
00E54E  2  30 04                BMI     Le554
00E550  2  A5 FA                LDA     leadzr
00E552  2  F0 0B                BEQ     Le55f
00E554  2  20 C9 E3     Le554:  JSR     cout
00E557  2  24 F8                BIT     auto_flag
00E559  2  10 04                BPL     Le55f
00E55B  2  99 00 02             STA     buffer,Y
00E55E  2  C8                   INY
00E55F  2  CA           Le55f:  DEX
00E560  2  10 C1                BPL     Le523
00E562  2  60                   RTS
00E563  2               ; powers of 10 table, low byte
00E563  2  01 0A 64 E8  dectabl:        .byte   $01,$0A,$64,$E8,$10
00E567  2  10           
00E568  2               
00E568  2               ; powers of 10 table, high byte
00E568  2  00 00 00 03  dectabh:        .byte   $00,$00,$00,$03,$27
00E56C  2  27           
00E56D  2               
00E56D  2  A5 CA        find_line:      LDA     pp
00E56F  2  85 E6                STA     p3
00E571  2  A5 CB                LDA     pp+1
00E573  2  85 E7                STA     p3+1
00E575  2               
00E575  2  E8           find_line1:     INX
00E576  2               
00E576  2  A5 E7        find_line2:     LDA     p3+1
00E578  2  85 E5                STA     p2+1
00E57A  2  A5 E6                LDA     p3
00E57C  2  85 E4                STA     p2
00E57E  2  C5 4C                CMP     himem
00E580  2  A5 E5                LDA     p2+1
00E582  2  E5 4D                SBC     himem+1
00E584  2  B0 26                BCS     Le5ac
00E586  2  A0 01                LDY     #$01
00E588  2  B1 E4                LDA     (p2),Y
00E58A  2  E5 CE                SBC     acc
00E58C  2  C8                   INY
00E58D  2  B1 E4                LDA     (p2),Y
00E58F  2  E5 CF                SBC     acc+1
00E591  2  B0 19                BCS     Le5ac
00E593  2  A0 00                LDY     #$00
00E595  2  A5 E6                LDA     p3
00E597  2  71 E4                ADC     (p2),Y
00E599  2  85 E6                STA     p3
00E59B  2  90 03                BCC     Le5a0
00E59D  2  E6 E7                INC     p3+1
00E59F  2  18                   CLC
00E5A0  2  C8           Le5a0:  INY
00E5A1  2  A5 CE                LDA     acc
00E5A3  2  F1 E4                SBC     (p2),Y
00E5A5  2  C8                   INY
00E5A6  2  A5 CF                LDA     acc+1
00E5A8  2  F1 E4                SBC     (p2),Y
00E5AA  2  B0 CA                BCS     find_line2
00E5AC  2  60           Le5ac:  RTS
00E5AD  2               
00E5AD  2               ; token $0B - "NEW"
00E5AD  2  46 F8        new_cmd:        LSR     auto_flag
00E5AF  2  A5 4C                LDA     himem
00E5B1  2  85 CA                STA     pp
00E5B3  2  A5 4D                LDA     himem+1
00E5B5  2  85 CB                STA     pp+1
00E5B7  2               
00E5B7  2               ; token $0C - "CLR"
00E5B7  2  A5 4A        clr:    LDA     lomem
00E5B9  2  85 CC                STA     pv
00E5BB  2  A5 4B                LDA     lomem+1
00E5BD  2  85 CD                STA     pv+1
00E5BF  2  A9 00                LDA     #$00
00E5C1  2  85 FB                STA     for_nest_count
00E5C3  2  85 FC                STA     gosub_nest_count
00E5C5  2  85 FE                STA     synpag
00E5C7  2  A9 00                LDA     #$00
00E5C9  2  85 1D                STA     Z1d
00E5CB  2  60                   RTS
00E5CC  2  A5 D0        Le5cc:  LDA     srch
00E5CE  2  69 05                ADC     #$05
00E5D0  2  85 D2                STA     srch2
00E5D2  2  A5 D1                LDA     tokndxstk
00E5D4  2  69 00                ADC     #$00
00E5D6  2  85 D3                STA     srch2+1
00E5D8  2  A5 D2                LDA     srch2
00E5DA  2  C5 CA                CMP     pp
00E5DC  2  A5 D3                LDA     srch2+1
00E5DE  2  E5 CB                SBC     pp+1
00E5E0  2  90 03                BCC     Le5e5
00E5E2  2  4C 6B E3             JMP     Le36b
00E5E5  2  A5 CE        Le5e5:  LDA     acc
00E5E7  2  91 D0                STA     (srch),Y
00E5E9  2  A5 CF                LDA     acc+1
00E5EB  2  C8                   INY
00E5EC  2  91 D0                STA     (srch),Y
00E5EE  2  A5 D2                LDA     srch2
00E5F0  2  C8                   INY
00E5F1  2  91 D0                STA     (srch),Y
00E5F3  2  A5 D3                LDA     srch2+1
00E5F5  2  C8                   INY
00E5F6  2  91 D0                STA     (srch),Y
00E5F8  2  A9 00                LDA     #$00
00E5FA  2  C8                   INY
00E5FB  2  91 D0                STA     (srch),Y
00E5FD  2  C8                   INY
00E5FE  2  91 D0                STA     (srch),Y
00E600  2  A5 D2                LDA     srch2
00E602  2  85 CC                STA     pv
00E604  2  A5 D3                LDA     srch2+1
00E606  2  85 CD                STA     pv+1
00E608  2  A5 D0                LDA     srch
00E60A  2  90 43                BCC     Le64f
00E60C  2  85 CE        execute_var:    STA     acc
00E60E  2  84 CF                STY     acc+1
00E610  2  20 FF E6             JSR     get_next_prog_byte
00E613  2  30 0E                BMI     Le623
00E615  2  C9 40                CMP     #$40
00E617  2  F0 0A                BEQ     Le623
00E619  2  4C 28 E6             JMP     Le628
00E61C  2  06 C9 49 D0          .byte   $06,$C9,$49,$D0,$07,$A9,$49
00E620  2  07 A9 49     
00E623  2  85 CF        Le623:  STA     acc+1
00E625  2  20 FF E6             JSR     get_next_prog_byte
00E628  2  A5 4B        Le628:  LDA     lomem+1
00E62A  2  85 D1                STA     tokndxstk
00E62C  2  A5 4A                LDA     lomem
00E62E  2  85 D0        Le62e:  STA     srch
00E630  2  C5 CC                CMP     pv
00E632  2  A5 D1                LDA     tokndxstk
00E634  2  E5 CD                SBC     pv+1
00E636  2  B0 94                BCS     Le5cc
00E638  2  B1 D0                LDA     (srch),Y
00E63A  2  C8                   INY
00E63B  2  C5 CE                CMP     acc
00E63D  2  D0 06                BNE     Le645
00E63F  2  B1 D0                LDA     (srch),Y
00E641  2  C5 CF                CMP     acc+1
00E643  2  F0 0E                BEQ     Le653
00E645  2  C8           Le645:  INY
00E646  2  B1 D0                LDA     (srch),Y
00E648  2  48                   PHA
00E649  2  C8                   INY
00E64A  2  B1 D0                LDA     (srch),Y
00E64C  2  85 D1                STA     tokndxstk
00E64E  2  68                   PLA
00E64F  2  A0 00        Le64f:  LDY     #$00
00E651  2  F0 DB                BEQ     Le62e
00E653  2  A5 D0        Le653:  LDA     srch
00E655  2  69 03                ADC     #$03
00E657  2  20 0A E7             JSR     push_a_noun_stk
00E65A  2  A5 D1                LDA     tokndxstk
00E65C  2  69 00                ADC     #$00
00E65E  2  95 78                STA     noun_stk_h_str,X
00E660  2  A5 CF                LDA     acc+1
00E662  2  C9 40                CMP     #$40
00E664  2  D0 1C                BNE     fetch_prog_byte
00E666  2  88                   DEY
00E667  2  98                   TYA
00E668  2  20 0A E7             JSR     push_a_noun_stk
00E66B  2  88                   DEY
00E66C  2  94 78                STY     noun_stk_h_str,X
00E66E  2  A0 03                LDY     #$03
00E670  2  F6 78        Le670:  INC     noun_stk_h_str,X
00E672  2  C8                   INY
00E673  2  B1 D0                LDA     (srch),Y
00E675  2  30 F9                BMI     Le670
00E677  2  10 09                BPL     fetch_prog_byte
00E679  2               
00E679  2  A9 00        execute_stmt:   LDA     #$00
00E67B  2  85 D4                STA     if_flag
00E67D  2  85 D5                STA     cr_flag
00E67F  2  A2 20                LDX     #$20
00E681  2               
00E681  2               ; push old verb on stack for later use in precedence test
00E681  2  48           push_old_verb:  PHA
00E682  2  A0 00        fetch_prog_byte:        LDY     #$00
00E684  2  B1 E0                LDA     (pverb),Y
00E686  2  10 18        Le686:  BPL     execute_token
00E688  2  0A                   ASL
00E689  2  30 81                BMI     execute_var
00E68B  2  20 FF E6             JSR     get_next_prog_byte
00E68E  2  20 08 E7             JSR     push_ya_noun_stk
00E691  2  20 FF E6             JSR     get_next_prog_byte
00E694  2  95 A0                STA     noun_stk_h_int,X
00E696  2  24 D4        Le696:  BIT     if_flag
00E698  2  10 01                BPL     Le69b
00E69A  2  CA                   DEX
00E69B  2  20 FF E6     Le69b:  JSR     get_next_prog_byte
00E69E  2  B0 E6                BCS     Le686
00E6A0  2               
00E6A0  2  C9 28        execute_token:  CMP     #$28
00E6A2  2  D0 1F                BNE     execute_verb
00E6A4  2  A5 E0                LDA     pverb
00E6A6  2  20 0A E7             JSR     push_a_noun_stk
00E6A9  2  A5 E1                LDA     pverb+1
00E6AB  2  95 78                STA     noun_stk_h_str,X
00E6AD  2  24 D4                BIT     if_flag
00E6AF  2  30 0B                BMI     Le6bc
00E6B1  2  A9 01                LDA     #$01
00E6B3  2  20 0A E7             JSR     push_a_noun_stk
00E6B6  2  A9 00                LDA     #$00
00E6B8  2  95 78                STA     noun_stk_h_str,X
00E6BA  2  F6 78        Le6ba:  INC     noun_stk_h_str,X
00E6BC  2  20 FF E6     Le6bc:  JSR     get_next_prog_byte
00E6BF  2  30 F9                BMI     Le6ba
00E6C1  2  B0 D3                BCS     Le696
00E6C3  2  24 D4        execute_verb:   BIT     if_flag
00E6C5  2  10 06                BPL     Le6cd
00E6C7  2  C9 04                CMP     #$04
00E6C9  2  B0 D0                BCS     Le69b
00E6CB  2  46 D4                LSR     if_flag
00E6CD  2  A8           Le6cd:  TAY
00E6CE  2  85 D6                STA     current_verb
00E6D0  2  B9 98 E9             LDA     verb_prec_tbl,Y
00E6D3  2  29 55                AND     #$55
00E6D5  2  0A                   ASL
00E6D6  2  85 D7                STA     precedence
00E6D8  2  68           Le6d8:  PLA
00E6D9  2  A8                   TAY
00E6DA  2  B9 98 E9             LDA     verb_prec_tbl,Y
00E6DD  2  29 AA                AND     #$AA
00E6DF  2  C5 D7                CMP     precedence
00E6E1  2  B0 09                BCS     do_verb
00E6E3  2  98                   TYA
00E6E4  2  48                   PHA
00E6E5  2  20 FF E6             JSR     get_next_prog_byte
00E6E8  2  A5 D6                LDA     current_verb
00E6EA  2  90 95                BCC     push_old_verb
00E6EC  2  B9 10 EA     do_verb:        LDA     verb_adr_l,Y
00E6EF  2  85 CE                STA     acc
00E6F1  2  B9 88 EA             LDA     verb_adr_h,Y
00E6F4  2  85 CF                STA     acc+1
00E6F6  2  20 FC E6             JSR     Se6fc
00E6F9  2  4C D8 E6             JMP     Le6d8
00E6FC  2               
00E6FC  2  6C CE 00     Se6fc:  JMP     (acc)
00E6FF  2               
00E6FF  2  E6 E0        get_next_prog_byte:     INC     pverb
00E701  2  D0 02                BNE     Le705
00E703  2  E6 E1                INC     pverb+1
00E705  2  B1 E0        Le705:  LDA     (pverb),Y
00E707  2  60                   RTS
00E708  2               
00E708  2  94 77        push_ya_noun_stk:       STY     syn_stk_h+31,X
00E70A  2               
00E70A  2  CA           push_a_noun_stk:        DEX
00E70B  2  30 03                BMI     Le710
00E70D  2  95 50                STA     noun_stk_l,X
00E70F  2  60                   RTS
00E710  2  A0 66        Le710:  LDY     #$66
00E712  2  4C E0 E3     go_errmess_3:   JMP     print_err_msg
00E715  2               
00E715  2  A0 00        get16bit:       LDY     #$00
00E717  2  B5 50                LDA     noun_stk_l,X
00E719  2  85 CE                STA     acc
00E71B  2  B5 A0                LDA     noun_stk_h_int,X
00E71D  2  85 CF                STA     acc+1
00E71F  2  B5 78                LDA     noun_stk_h_str,X
00E721  2  F0 0E                BEQ     Le731
00E723  2  85 CF                STA     acc+1
00E725  2  B1 CE                LDA     (acc),Y
00E727  2  48                   PHA
00E728  2  C8                   INY
00E729  2  B1 CE                LDA     (acc),Y
00E72B  2  85 CF                STA     acc+1
00E72D  2  68                   PLA
00E72E  2  85 CE                STA     acc
00E730  2  88                   DEY
00E731  2  E8           Le731:  INX
00E732  2  60                   RTS
00E733  2               
00E733  2               ; token $16 - "=" for numeric equality operator
00E733  2  20 4A E7     eq_op:  JSR     neq_op
00E736  2               
00E736  2               ; token $37 - "NOT"
00E736  2  20 15 E7     not_op: JSR     get16bit
00E739  2  98                   TYA
00E73A  2  20 08 E7             JSR     push_ya_noun_stk
00E73D  2  95 A0                STA     noun_stk_h_int,X
00E73F  2  C5 CE                CMP     acc
00E741  2  D0 06                BNE     Le749
00E743  2  C5 CF                CMP     acc+1
00E745  2  D0 02                BNE     Le749
00E747  2  F6 50                INC     noun_stk_l,X
00E749  2  60           Le749:  RTS
00E74A  2               
00E74A  2               ; token $17 - "#" for numeric inequality operator
00E74A  2               ; token $1B - "<>" for numeric inequality operator
00E74A  2  20 82 E7     neq_op: JSR     subtract
00E74D  2  20 59 E7             JSR     sgn_fn
00E750  2               
00E750  2               ; token $31 - "ABS"
00E750  2  20 15 E7     abs_fn: JSR     get16bit
00E753  2  24 CF                BIT     acc+1
00E755  2  30 1B                BMI     Se772
00E757  2  CA           Le757:  DEX
00E758  2  60           Le758:  RTS
00E759  2               
00E759  2               ; token $30 - "SGN"
00E759  2  20 15 E7     sgn_fn: JSR     get16bit
00E75C  2  A5 CF                LDA     acc+1
00E75E  2  D0 04                BNE     Le764
00E760  2  A5 CE                LDA     acc
00E762  2  F0 F3                BEQ     Le757
00E764  2  A9 FF        Le764:  LDA     #$FF
00E766  2  20 08 E7             JSR     push_ya_noun_stk
00E769  2  95 A0                STA     noun_stk_h_int,X
00E76B  2  24 CF                BIT     acc+1
00E76D  2  30 E9                BMI     Le758
00E76F  2               
00E76F  2               ; token $36 - "-" for unary negation
00E76F  2  20 15 E7     negate: JSR     get16bit
00E772  2               
00E772  2  98           Se772:  TYA
00E773  2  38                   SEC
00E774  2  E5 CE                SBC     acc
00E776  2  20 08 E7             JSR     push_ya_noun_stk
00E779  2  98                   TYA
00E77A  2  E5 CF                SBC     acc+1
00E77C  2  50 23                BVC     Le7a1
00E77E  2  A0 00        Le77e:  LDY     #$00
00E780  2  10 90                BPL     go_errmess_3
00E782  2               
00E782  2               ; token $13 - "-" for numeric subtraction
00E782  2  20 6F E7     subtract:       JSR     negate
00E785  2               
00E785  2               ; token $12 - "+" for numeric addition
00E785  2  20 15 E7     add:    JSR     get16bit
00E788  2  A5 CE                LDA     acc
00E78A  2  85 DA                STA     aux
00E78C  2  A5 CF                LDA     acc+1
00E78E  2  85 DB                STA     aux+1
00E790  2  20 15 E7             JSR     get16bit
00E793  2               
00E793  2  18           Se793:  CLC
00E794  2  A5 CE                LDA     acc
00E796  2  65 DA                ADC     aux
00E798  2  20 08 E7             JSR     push_ya_noun_stk
00E79B  2  A5 CF                LDA     acc+1
00E79D  2  65 DB                ADC     aux+1
00E79F  2  70 DD                BVS     Le77e
00E7A1  2  95 A0        Le7a1:  STA     noun_stk_h_int,X
00E7A3  2               
00E7A3  2               ; token $35 - "+" for unary positive
00E7A3  2  60           unary_pos:      RTS
00E7A4  2               
00E7A4  2               ; token $50 - "TAB" function
00E7A4  2  20 15 E7     tab_fn: JSR     get16bit
00E7A7  2  A4 CE                LDY     acc
00E7A9  2  F0 05                BEQ     Le7b0
00E7AB  2  88                   DEY
00E7AC  2  A5 CF                LDA     acc+1
00E7AE  2  F0 0C                BEQ     Le7bc
00E7B0  2  60           Le7b0:  RTS
00E7B1  2               
00E7B1  2               ; horizontal tab
00E7B1  2  A5 24        tabout: LDA     ch
00E7B3  2  09 07                ORA     #$07
00E7B5  2  A8                   TAY
00E7B6  2  C8                   INY
00E7B7  2  A9 A0        Le7b7:  LDA     #$A0
00E7B9  2  20 C9 E3             JSR     cout
00E7BC  2  C4 24        Le7bc:  CPY     ch
00E7BE  2  B0 F7                BCS     Le7b7
00E7C0  2  60                   RTS
00E7C1  2               
00E7C1  2               ; token $49 - "," in print, numeric follows
00E7C1  2  20 B1 E7     print_com_num:  JSR     tabout
00E7C4  2               
00E7C4  2               ; token $62 - "PRINT" numeric
00E7C4  2  20 15 E7     print_num:      JSR     get16bit
00E7C7  2  A5 CF                LDA     acc+1
00E7C9  2  10 0A                BPL     Le7d5
00E7CB  2  A9 AD                LDA     #$AD
00E7CD  2  20 C9 E3             JSR     cout
00E7D0  2  20 72 E7             JSR     Se772
00E7D3  2  50 EF                BVC     print_num
00E7D5  2  88           Le7d5:  DEY
00E7D6  2  84 D5                STY     cr_flag
00E7D8  2  86 CF                STX     acc+1
00E7DA  2  A6 CE                LDX     acc
00E7DC  2  20 1B E5             JSR     prdec
00E7DF  2  A6 CF                LDX     acc+1
00E7E1  2  60                   RTS
00E7E2  2               
00E7E2  2               ; token $0D - "AUTO" command
00E7E2  2  20 15 E7     auto_cmd:       JSR     get16bit
00E7E5  2  A5 CE                LDA     acc
00E7E7  2  85 F6                STA     auto_ln
00E7E9  2  A5 CF                LDA     acc+1
00E7EB  2  85 F7                STA     auto_ln+1
00E7ED  2  88                   DEY
00E7EE  2  84 F8                STY     auto_flag
00E7F0  2  C8                   INY
00E7F1  2  A9 0A                LDA     #$0A
00E7F3  2  85 F4        Le7f3:  STA     auto_inc
00E7F5  2  84 F5                STY     auto_inc+1
00E7F7  2  60                   RTS
00E7F8  2               
00E7F8  2               ; token $0E - "," in AUTO command
00E7F8  2  20 15 E7     auto_com:       JSR     get16bit
00E7FB  2  A5 CE                LDA     acc
00E7FD  2  A4 CF                LDY     acc+1
00E7FF  2  10 F2                BPL     Le7f3
00E801  2               
00E801  2               ; token $56 - "=" in FOR statement
00E801  2               ; token $71 - "=" in LET (or implied LET) statement
00E801  2  20 15 E7     var_assign:     JSR     get16bit
00E804  2  B5 50                LDA     noun_stk_l,X
00E806  2  85 DA                STA     aux
00E808  2  B5 78                LDA     noun_stk_h_str,X
00E80A  2  85 DB                STA     aux+1
00E80C  2  A5 CE                LDA     acc
00E80E  2  91 DA                STA     (aux),Y
00E810  2  C8                   INY
00E811  2  A5 CF                LDA     acc+1
00E813  2  91 DA                STA     (aux),Y
00E815  2  E8                   INX
00E816  2               
00E816  2  60           Te816:  RTS
00E817  2               
00E817  2               ; token $00 - begining of line
00E817  2               begin_line:
00E817  2  68                   PLA
00E818  2  68                   PLA
00E819  2               
00E819  2               ; token $03 - ":" statement separator
00E819  2  24 D5        colon:  BIT     cr_flag
00E81B  2  10 05                BPL     Le822
00E81D  2               
00E81D  2               ; token $63 - "PRINT" with no arg
00E81D  2  20 CD E3     print_cr:       JSR     crout
00E820  2               
00E820  2               ; token $47 - ";" at end of print statement
00E820  2  46 D5        print_semi:     LSR     cr_flag
00E822  2  60           Le822:  RTS
00E823  2               
00E823  2               
00E823  2               ; token $22 - "(" in string DIM
00E823  2               ; token $34 - "(" in numeric DIM
00E823  2               ; token $38 - "(" in numeric expression
00E823  2               ; token $3F - "(" in some PEEK, RND, SGN, ABS (PDL)
00E823  2  A0 FF        left_paren:     LDY     #$FF
00E825  2  84 D7                STY     precedence
00E827  2               
00E827  2               ; token $72 - ")" everywhere
00E827  2  60           right_paren:    RTS
00E828  2               
00E828  2               ; token $60 - "IF" statement
00E828  2  20 CD EF     if_stmt:        JSR     Sefcd
00E82B  2  F0 07                BEQ     Le834
00E82D  2  A9 25                LDA     #$25
00E82F  2  85 D6                STA     current_verb
00E831  2  88                   DEY
00E832  2  84 D4                STY     if_flag
00E834  2  E8           Le834:  INX
00E835  2  60                   RTS
00E836  2               ; RUN without CLR, used by Apple DOS
00E836  2  A5 CA        run_warm:       LDA     pp
00E838  2  A4 CB                LDY     pp+1
00E83A  2  D0 5A                BNE     Le896
00E83C  2               
00E83C  2               ; token $5C - "GOSUB" statement
00E83C  2  A0 41        gosub_stmt:     LDY     #$41
00E83E  2  A5 FC                LDA     gosub_nest_count
00E840  2  C9 08                CMP     #$08
00E842  2  B0 5E                BCS     go_errmess_4
00E844  2  A8                   TAY
00E845  2  E6 FC                INC     gosub_nest_count
00E847  2  A5 E0                LDA     pverb
00E849  2  99 00 01             STA     gstk_pverbl,Y
00E84C  2  A5 E1                LDA     pverb+1
00E84E  2  99 08 01             STA     gstk_pverbh,Y
00E851  2  A5 DC                LDA     pline
00E853  2  99 10 01             STA     gstk_plinel,Y
00E856  2  A5 DD                LDA     pline+1
00E858  2  99 18 01             STA     gstk_plineh,Y
00E85B  2               
00E85B  2               ; token $24 - "THEN"
00E85B  2               ; token $5F - "GOTO" statement
00E85B  2  20 15 E7     goto_stmt:      JSR     get16bit
00E85E  2  20 6D E5             JSR     find_line
00E861  2  90 04                BCC     Le867
00E863  2  A0 37                LDY     #$37
00E865  2  D0 3B                BNE     go_errmess_4
00E867  2  A5 E4        Le867:  LDA     p2
00E869  2  A4 E5                LDY     p2+1
00E86B  2               
00E86B  2               ; loop to run a program
00E86B  2  85 DC        run_loop:       STA     pline
00E86D  2  84 DD                STY     pline+1
00E86F  2  2C 11 D0             BIT     KBDCR
00E872  2  30 4F                BMI     Le8c3
00E874  2  18                   CLC
00E875  2  69 03                ADC     #$03
00E877  2  90 01                BCC     Le87a
00E879  2  C8                   INY
00E87A  2  A2 FF        Le87a:  LDX     #$FF
00E87C  2  86 D9                STX     run_flag
00E87E  2  9A                   TXS
00E87F  2  85 E0                STA     pverb
00E881  2  84 E1                STY     pverb+1
00E883  2  20 79 E6     Le883:  JSR     execute_stmt
00E886  2  24 D9                BIT     run_flag
00E888  2  10 49                BPL     end_stmt
00E88A  2  18                   CLC
00E88B  2  A0 00                LDY     #$00
00E88D  2  A5 DC                LDA     pline
00E88F  2  71 DC                ADC     (pline),Y
00E891  2  A4 DD                LDY     pline+1
00E893  2  90 01                BCC     Le896
00E895  2  C8                   INY
00E896  2  C5 4C        Le896:  CMP     himem
00E898  2  D0 D1                BNE     run_loop
00E89A  2  C4 4D                CPY     himem+1
00E89C  2  D0 CD                BNE     run_loop
00E89E  2  A0 34                LDY     #$34
00E8A0  2  46 D9                LSR     run_flag
00E8A2  2  4C E0 E3     go_errmess_4:   JMP     print_err_msg
00E8A5  2               
00E8A5  2               ; token $5B - "RETURN" statement
00E8A5  2  A0 4A        return_stmt:    LDY     #$4A
00E8A7  2  A5 FC                LDA     gosub_nest_count
00E8A9  2  F0 F7                BEQ     go_errmess_4
00E8AB  2  C6 FC                DEC     gosub_nest_count
00E8AD  2  A8                   TAY
00E8AE  2  B9 0F 01             LDA     gstk_plinel-1,Y
00E8B1  2  85 DC                STA     pline
00E8B3  2  B9 17 01             LDA     gstk_plineh-1,Y
00E8B6  2  85 DD                STA     pline+1
00E8B8  2  BE FF 00             LDX     a:synpag+1,Y            ; force absolute addressing mode
00E8BB  2  B9 07 01             LDA     gstk_pverbh-1,Y
00E8BE  2  A8           Le8be:  TAY
00E8BF  2  8A                   TXA
00E8C0  2  4C 7A E8             JMP     Le87a
00E8C3  2  A0 63        Le8c3:  LDY     #$63
00E8C5  2  20 C4 E3             JSR     Se3c4
00E8C8  2  A0 01                LDY     #$01
00E8CA  2  B1 DC                LDA     (pline),Y
00E8CC  2  AA                   TAX
00E8CD  2  C8                   INY
00E8CE  2  B1 DC                LDA     (pline),Y
00E8D0  2  20 1B E5             JSR     prdec
00E8D3  2               
00E8D3  2               ; token $51 - "END" statement
00E8D3  2  4C B3 E2     end_stmt:       JMP     warm
00E8D6  2  C6 FB        Le8d6:  DEC     for_nest_count
00E8D8  2               
00E8D8  2               ; token $59 - "NEXT" statement
00E8D8  2               ; token $5A - "," in NEXT statement
00E8D8  2  A0 5B        next_stmt:      LDY     #$5B
00E8DA  2  A5 FB                LDA     for_nest_count
00E8DC  2  F0 C4        Le8dc:  BEQ     go_errmess_4
00E8DE  2  A8                   TAY
00E8DF  2  B5 50                LDA     noun_stk_l,X
00E8E1  2  D9 1F 01             CMP     fstk_varl-1,Y
00E8E4  2  D0 F0                BNE     Le8d6
00E8E6  2  B5 78                LDA     noun_stk_h_str,X
00E8E8  2  D9 27 01             CMP     fstk_varh-1,Y
00E8EB  2  D0 E9                BNE     Le8d6
00E8ED  2  B9 2F 01             LDA     fstk_stepl-1,Y
00E8F0  2  85 DA                STA     aux
00E8F2  2  B9 37 01             LDA     fstk_steph-1,Y
00E8F5  2  85 DB                STA     aux+1
00E8F7  2  20 15 E7             JSR     get16bit
00E8FA  2  CA                   DEX
00E8FB  2  20 93 E7             JSR     Se793
00E8FE  2  20 01 E8             JSR     var_assign
00E901  2  CA                   DEX
00E902  2  A4 FB                LDY     for_nest_count
00E904  2  B9 67 01             LDA     fstk_toh-1,Y
00E907  2  95 9F                STA     syn_stk_l+31,X
00E909  2  B9 5F 01             LDA     fstk_tol-1,Y
00E90C  2  A0 00                LDY     #$00
00E90E  2  20 08 E7             JSR     push_ya_noun_stk
00E911  2  20 82 E7             JSR     subtract
00E914  2  20 59 E7             JSR     sgn_fn
00E917  2  20 15 E7             JSR     get16bit
00E91A  2  A4 FB                LDY     for_nest_count
00E91C  2  A5 CE                LDA     acc
00E91E  2  F0 05                BEQ     Le925
00E920  2  59 37 01             EOR     fstk_steph-1,Y
00E923  2  10 12                BPL     Le937
00E925  2  B9 3F 01     Le925:  LDA     fstk_plinel-1,Y
00E928  2  85 DC                STA     pline
00E92A  2  B9 47 01             LDA     fstk_plineh-1,Y
00E92D  2  85 DD                STA     pline+1
00E92F  2  BE 4F 01             LDX     fstk_pverbl-1,Y
00E932  2  B9 57 01             LDA     fstk_pverbh-1,Y
00E935  2  D0 87                BNE     Le8be
00E937  2  C6 FB        Le937:  DEC     for_nest_count
00E939  2  60                   RTS
00E93A  2               
00E93A  2               ; token $55 - "FOR" statement
00E93A  2  A0 54        for_stmt:       LDY     #$54
00E93C  2  A5 FB                LDA     for_nest_count
00E93E  2  C9 08                CMP     #$08
00E940  2  F0 9A                BEQ     Le8dc
00E942  2  E6 FB                INC     for_nest_count
00E944  2  A8                   TAY
00E945  2  B5 50                LDA     noun_stk_l,X
00E947  2  99 20 01             STA     fstk_varl,Y
00E94A  2  B5 78                LDA     noun_stk_h_str,X
00E94C  2  99 28 01             STA     fstk_varh,Y
00E94F  2  60                   RTS
00E950  2               
00E950  2               ; token $57 - "TO"
00E950  2  20 15 E7     to_clause:      JSR     get16bit
00E953  2  A4 FB                LDY     for_nest_count
00E955  2  A5 CE                LDA     acc
00E957  2  99 5F 01             STA     fstk_tol-1,Y
00E95A  2  A5 CF                LDA     acc+1
00E95C  2  99 67 01             STA     fstk_toh-1,Y
00E95F  2  A9 01                LDA     #$01
00E961  2  99 2F 01             STA     fstk_stepl-1,Y
00E964  2  A9 00                LDA     #$00
00E966  2  99 37 01     Le966:  STA     fstk_steph-1,Y
00E969  2  A5 DC                LDA     pline
00E96B  2  99 3F 01             STA     fstk_plinel-1,Y
00E96E  2  A5 DD                LDA     pline+1
00E970  2  99 47 01             STA     fstk_plineh-1,Y
00E973  2  A5 E0                LDA     pverb
00E975  2  99 4F 01             STA     fstk_pverbl-1,Y
00E978  2  A5 E1                LDA     pverb+1
00E97A  2  99 57 01             STA     fstk_pverbh-1,Y
00E97D  2  60                   RTS
00E97E  2               
00E97E  2  20 15 E7     Te97e:  JSR     get16bit
00E981  2  A4 FB                LDY     for_nest_count
00E983  2  A5 CE                LDA     acc
00E985  2  99 2F 01             STA     fstk_stepl-1,Y
00E988  2  A5 CF                LDA     acc+1
00E98A  2  4C 66 E9             JMP     Le966
00E98D  2  00 00 00 00          .byte   $00,$00,$00,$00,$00,$00,$00,$00
00E991  2  00 00 00 00  
00E995  2  00 00 00             .byte   $00,$00,$00
00E998  2               
00E998  2               ; verb precedence
00E998  2               ; (verb_prec[token]&0xAA)>>1 for left (?)
00E998  2               ; verb_prec[token]&0x55 for right (?)
00E998  2               verb_prec_tbl:
00E998  2  00 00 00 AB          .byte   $00,$00,$00,$AB,$03,$03,$03,$03
00E99C  2  03 03 03 03  
00E9A0  2  03 03 03 03          .byte   $03,$03,$03,$03,$03,$03,$03,$03
00E9A4  2  03 03 03 03  
00E9A8  2  03 03 3F 3F          .byte   $03,$03,$3F,$3F,$C0,$C0,$3C,$3C
00E9AC  2  C0 C0 3C 3C  
00E9B0  2  3C 3C 3C 3C          .byte   $3C,$3C,$3C,$3C,$3C,$30,$0F,$C0
00E9B4  2  3C 30 0F C0  
00E9B8  2  CC FF 55 00          .byte   $CC,$FF,$55,$00,$AB,$AB,$03,$03
00E9BC  2  AB AB 03 03  
00E9C0  2  FF FF 55 FF          .byte   $FF,$FF,$55,$FF,$FF,$55,$CF,$CF
00E9C4  2  FF 55 CF CF  
00E9C8  2  CF CF CF FF          .byte   $CF,$CF,$CF,$FF,$55,$C3,$C3,$C3
00E9CC  2  55 C3 C3 C3  
00E9D0  2  55 F0 F0 CF          .byte   $55,$F0,$F0,$CF,$56,$56,$56,$55
00E9D4  2  56 56 56 55  
00E9D8  2  FF FF 55 03          .byte   $FF,$FF,$55,$03,$03,$03,$03,$03
00E9DC  2  03 03 03 03  
00E9E0  2  03 03 FF FF          .byte   $03,$03,$FF,$FF,$FF,$03,$03,$03
00E9E4  2  FF 03 03 03  
00E9E8  2  03 03 03 03          .byte   $03,$03,$03,$03,$03,$03,$03,$03
00E9EC  2  03 03 03 03  
00E9F0  2  03 03 03 03          .byte   $03,$03,$03,$03,$03,$00,$AB,$03
00E9F4  2  03 00 AB 03  
00E9F8  2  57 03 03 03          .byte   $57,$03,$03,$03,$03,$07,$03,$03
00E9FC  2  03 07 03 03  
00EA00  2  03 03 03 03          .byte   $03,$03,$03,$03,$03,$03,$03,$03
00EA04  2  03 03 03 03  
00EA08  2  03 03 AA FF          .byte   $03,$03,$AA,$FF,$FF,$FF,$FF,$FF
00EA0C  2  FF FF FF FF  
00EA10  2               verb_adr_l:
00EA10  2  17 FF FF 19          .byte   <begin_line,$FF,$FF,<colon,<list_cmd,<list_comman,<list_all,<Teff2
00EA14  2  5D 35 4B F2  
00EA18  2  EC 87 6F AD          .byte   <Tefec,<del_cmd,<del_comma,<new_cmd,<clr,<auto_cmd,<auto_com,<(Tee5e+1)
00EA1C  2  B7 E2 F8 54  
00EA20  2  80 96 85 82          .byte   <Tef80,<Tef96,<add,<subtract,<mult_op,<divide,<eq_op,<neq_op
00EA24  2  22 10 33 4A  
00EA28  2  13 06 0B 4A          .byte   <Tec13,<Tec06,<Tec0b,<neq_op,<Tec01,<Tec40,<Tec47,<mod_op
00EA2C  2  01 40 47 7A  
00EA30  2  00 FF 23 09          .byte   $00,$FF,<left_paren,<comma_substr,<goto_stmt,<Te816,<string_input,<input_num_comma
00EA34  2  5B 16 B6 CB  
00EA38  2  FF FF FB FF          .byte   $FF,$FF,<paren_substr,$FF,$FF,<num_array_subs,<peek_fn,<rnd_fn
00EA3C  2  FF 24 F6 4E  
00EA40  2  59 50 00 FF          .byte   <sgn_fn,<abs_fn,$00,$FF,<left_paren,<unary_pos,<negate,<not_op
00EA44  2  23 A3 6F 36  
00EA48  2  23 D7 1C 22          .byte   <left_paren,<string_eq,<string_neq,<len_fn,<leec2,<(l1235+2),<(l1237+4),<left_paren
00EA4C  2  C2 AE BA 23  
00EA50  2  FF FF 21 30          .byte   $FF,$FF,<str_arr_dest,<dim_str,<dim_num,<print_str,<print_num,<print_semi
00EA54  2  1E 03 C4 20  
00EA58  2  00 C1 FF FF          .byte   <print_str_comma,<print_com_num,$FF,$FF,$FF,<call_stmt,<dim_str,<dim_num
00EA5C  2  FF A0 30 1E  
00EA60  2  A4 D3 B6 BC          .byte   <tab_fn,<end_stmt,<string_input,<input_prompt,<input_num_stmt,<for_stmt,<var_assign,<to_clause
00EA64  2  AA 3A 01 50  
00EA68  2  7E D8 D8 A5          .byte   <Te97e,<next_stmt,<next_stmt,<return_stmt,<gosub_stmt,$FF,<Te816,<goto_stmt
00EA6C  2  3C FF 16 5B  
00EA70  2  28 03 C4 1D          .byte   <if_stmt,<print_str,<print_num,<print_cr,<poke_stmt,<Tef0c,<Tee4e,<poke_stmt
00EA74  2  00 0C 4E 00  
00EA78  2  3E 00 A6 B0          .byte   <plot_comma,<poke_stmt,<l1233,<(l1235+4),<poke_stmt,<(l1237+6),<(leec2+4),<(l123+1)
00EA7C  2  00 BC C6 57  
00EA80  2  8C 01 27 FF          .byte   <string_lit,<var_assign,<right_paren,$FF,$FF,$FF,$FF,$FF
00EA84  2  FF FF FF FF  
00EA88  2               verb_adr_h:
00EA88  2  E8 FF FF E8          .byte   >begin_line,$FF,$FF,>colon,>list_cmd,>list_comman,>list_all,>Teff2
00EA8C  2  E0 E0 E0 EF  
00EA90  2  EF E3 E3 E5          .byte   >Tefec,>del_cmd,>del_comma,>new_cmd,>clr,>auto_cmd,>auto_com,>(Tee5e+1)
00EA94  2  E5 E7 E7 EE  
00EA98  2  EF EF E7 E7          .byte   >Tef80,>Tef96,>add,>subtract,>mult_op,>divide,>eq_op,>neq_op
00EA9C  2  E2 EF E7 E7  
00EAA0  2  EC EC EC E7          .byte   >Tec13,>Tec06,>Tec0b,>neq_op,>Tec01,>Tec40,>Tec47,>mod_op
00EAA4  2  EC EC EC E2  
00EAA8  2  00 FF E8 E1          .byte   $00,$FF,>left_paren,>comma_substr,>goto_stmt,>Te816,>string_input,>input_num_comma
00EAAC  2  E8 E8 EF EB  
00EAB0  2  FF FF E0 FF          .byte   $FF,$FF,>paren_substr,$FF,$FF,>num_array_subs,>peek_fn,>rnd_fn
00EAB4  2  FF EF EE EF  
00EAB8  2  E7 E7 00 FF          .byte   >sgn_fn,>abs_fn,$00,$FF,>left_paren,>unary_pos,>negate,>not_op
00EABC  2  E8 E7 E7 E7  
00EAC0  2  E8 E1 E2 EE          .byte   >left_paren,>string_eq,>string_neq,>len_fn,>leec2,>(l1235+2),>(l1237+4),>left_paren
00EAC4  2  EE EE EE E8  
00EAC8  2  FF FF E1 E1          .byte   $FF,$FF,>str_arr_dest,>dim_str,>dim_num,>print_str,>print_num,>print_semi
00EACC  2  EF EE E7 E8  
00EAD0  2  EE E7 FF FF          .byte   >print_str_comma,>print_com_num,$FF,$FF,$FF,>call_stmt,>dim_str,>dim_num
00EAD4  2  FF EE E1 EF  
00EAD8  2  E7 E8 EF EF          .byte   >tab_fn,>end_stmt,>string_input,>input_prompt,>input_num_stmt,>for_stmt,>var_assign,>to_clause
00EADC  2  EB E9 E8 E9  
00EAE0  2  E9 E8 E8 E8          .byte   >Te97e,>next_stmt,>next_stmt,>return_stmt,>gosub_stmt,$FF,>Te816,>goto_stmt
00EAE4  2  E8 FF E8 E8  
00EAE8  2  E8 EE E7 E8          .byte   >if_stmt,>print_str,>print_num,>print_cr,>poke_stmt,>Tef0c,>Tee4e,>poke_stmt
00EAEC  2  EF EF EE EF  
00EAF0  2  EE EF EE EE          .byte   >plot_comma,>poke_stmt,>l1233,>(l1235+4),>poke_stmt,>(l1237+6),>(leec2+4),>(l123+1)
00EAF4  2  EF EE EE EE  
00EAF8  2  E1 E8 E8 FF          .byte   >string_lit,>var_assign,>right_paren,$FF,$FF,$FF,$FF,$FF
00EAFC  2  FF FF FF FF  
00EB00  2               
00EB00  2               ; Error message strings. Last character has high bit unset.
00EB00  2               error_msg_tbl:
00EB00  2  BE B3 B2 B7          .byte   $BE,$B3,$B2,$B7,$B6,$37         ; ">32767"
00EB04  2  B6 37        
00EB06  2  D4 CF CF A0          .byte   $D4,$CF,$CF,$A0,$CC,$CF,$CE,$47 ; "TOO LONG"
00EB0A  2  CC CF CE 47  
00EB0E  2  D3 D9 CE D4          .byte   $D3,$D9,$CE,$D4,$C1,$58         ; "SYNTAX"
00EB12  2  C1 58        
00EB14  2  CD C5 CD A0          .byte   $CD,$C5,$CD,$A0,$C6,$D5,$CC,$4C ; "MEM FULL"
00EB18  2  C6 D5 CC 4C  
00EB1C  2  D4 CF CF A0          .byte   $D4,$CF,$CF,$A0,$CD,$C1,$CE,$D9,$A0,$D0,$C1,$D2,$C5,$CE,$53 ; "TOO MANY PARENS"
00EB20  2  CD C1 CE D9  
00EB24  2  A0 D0 C1 D2  
00EB2B  2  D3 D4 D2 C9          .byte   $D3,$D4,$D2,$C9,$CE,$47         ; "STRING"
00EB2F  2  CE 47        
00EB31  2  CE CF A0 C5          .byte   $CE,$CF,$A0,$C5,$CE,$44         ; "NO END"
00EB35  2  CE 44        
00EB37  2  C2 C1 C4 A0          .byte   $C2,$C1,$C4,$A0,$C2,$D2,$C1,$CE,$C3,$48 ; "BAD BRANCH"
00EB3B  2  C2 D2 C1 CE  
00EB3F  2  C3 48        
00EB41  2  BE B8 A0 C7          .byte   $BE,$B8,$A0,$C7,$CF,$D3,$D5,$C2,$53     ; ">8 GOSUBS"
00EB45  2  CF D3 D5 C2  
00EB49  2  53           
00EB4A  2  C2 C1 C4 A0          .byte   $C2,$C1,$C4,$A0,$D2,$C5,$D4,$D5,$D2,$4E ; "BAD RETURN"
00EB4E  2  D2 C5 D4 D5  
00EB52  2  D2 4E        
00EB54  2  BE B8 A0 C6          .byte   $BE,$B8,$A0,$C6,$CF,$D2,$53     ; ">8 FORS"
00EB58  2  CF D2 53     
00EB5B  2  C2 C1 C4 A0          .byte   $C2,$C1,$C4,$A0,$CE,$C5,$D8,$54 ; "BAD NEXT"
00EB5F  2  CE C5 D8 54  
00EB63  2  D3 D4 CF D0          .byte   $D3,$D4,$CF,$D0,$D0,$C5,$C4,$A0,$C1,$D4,$20 ; "STOPPED AT "
00EB67  2  D0 C5 C4 A0  
00EB6B  2  C1 D4 20     
00EB6E  2  AA AA AA 20          .byte   $AA,$AA,$AA,$20                 ; "*** "
00EB72  2  A0 C5 D2 D2          .byte   $A0,$C5,$D2,$D2,$0D             ; " ERR.\n"
00EB76  2  0D           
00EB77  2  BE B2 B5 35          .byte   $BE,$B2,$B5,$35                 ; ">255"
00EB7B  2  D2 C1 CE C7          .byte   $D2,$C1,$CE,$C7,$45             ; RANGE"
00EB7F  2  45           
00EB80  2  C4 C9 4D             .byte   $C4,$C9,$4D                     ; "DIM"
00EB83  2  D3 D4 D2 A0          .byte   $D3,$D4,$D2,$A0,$CF,$D6,$C6,$4C ; "STR OVFL"
00EB87  2  CF D6 C6 4C  
00EB8B  2  DC 0D                .byte   $DC,$0D                         ; "\\\n"
00EB8D  2  D2 C5 D4 D9          .byte   $D2,$C5,$D4,$D9,$D0,$C5,$A0,$CC,$C9,$CE,$C5,$8D ; "RETYPE LINE\n"
00EB91  2  D0 C5 A0 CC  
00EB95  2  C9 CE C5 8D  
00EB99  2  3F                   .byte   $3F                             ; "?"
00EB9A  2  46 D9        Leb9a:  LSR     run_flag
00EB9C  2  90 03                BCC     Leba1
00EB9E  2  4C C3 E8             JMP     Le8c3
00EBA1  2  A6 CF        Leba1:  LDX     acc+1
00EBA3  2  9A                   TXS
00EBA4  2  A6 CE                LDX     acc
00EBA6  2  A0 8D                LDY     #$8D
00EBA8  2  D0 02                BNE     Lebac
00EBAA  2               
00EBAA  2               ; token $54 - "INPUT" statement, numeric, no prompt
00EBAA  2  A0 99        input_num_stmt: LDY     #$99
00EBAC  2  20 C4 E3     Lebac:  JSR     Se3c4
00EBAF  2  86 CE                STX     acc
00EBB1  2  BA                   TSX
00EBB2  2  86 CF                STX     acc+1
00EBB4  2  A0 FE                LDY     #$FE
00EBB6  2  84 D9                STY     run_flag
00EBB8  2  C8                   INY
00EBB9  2  84 C8                STY     text_index
00EBBB  2  20 99 E2             JSR     Se299
00EBBE  2  84 F1                STY     token_index
00EBC0  2  A2 20                LDX     #$20
00EBC2  2  A9 30                LDA     #$30
00EBC4  2  20 91 E4             JSR     Se491
00EBC7  2  E6 D9                INC     run_flag
00EBC9  2  A6 CE                LDX     acc
00EBCB  2               
00EBCB  2               ; token $27 - "," numeric input
00EBCB  2  A4 C8        input_num_comma:        LDY     text_index
00EBCD  2  0A                   ASL
00EBCE  2  85 CE        Lebce:  STA     acc
00EBD0  2  C8                   INY
00EBD1  2  B9 00 02             LDA     buffer,Y
00EBD4  2  C9 74                CMP     #$74
00EBD6  2  F0 D2                BEQ     input_num_stmt
00EBD8  2  49 B0                EOR     #$B0
00EBDA  2  C9 0A                CMP     #$0A
00EBDC  2  B0 F0                BCS     Lebce
00EBDE  2  C8                   INY
00EBDF  2  C8                   INY
00EBE0  2  84 C8                STY     text_index
00EBE2  2  B9 00 02             LDA     buffer,Y
00EBE5  2  48                   PHA
00EBE6  2  B9 FF 01             LDA     buffer-1,Y
00EBE9  2  A0 00                LDY     #$00
00EBEB  2  20 08 E7             JSR     push_ya_noun_stk
00EBEE  2  68                   PLA
00EBEF  2  95 A0                STA     noun_stk_h_int,X
00EBF1  2  A5 CE                LDA     acc
00EBF3  2  C9 C7                CMP     #$C7
00EBF5  2  D0 03                BNE     Lebfa
00EBF7  2  20 6F E7             JSR     negate
00EBFA  2  4C 01 E8     Lebfa:  JMP     var_assign
00EBFD  2               
00EBFD  2  FF FF FF 50          .byte   $FF,$FF,$FF,$50
00EC01  2               
00EC01  2  20 13 EC     Tec01:  JSR     Tec13
00EC04  2  D0 15                BNE     Lec1b
00EC06  2               
00EC06  2  20 0B EC     Tec06:  JSR     Tec0b
00EC09  2  D0 10                BNE     Lec1b
00EC0B  2               
00EC0B  2  20 82 E7     Tec0b:  JSR     subtract
00EC0E  2  20 6F E7             JSR     negate
00EC11  2  50 03                BVC     Lec16
00EC13  2               
00EC13  2  20 82 E7     Tec13:  JSR     subtract
00EC16  2  20 59 E7     Lec16:  JSR     sgn_fn
00EC19  2  56 50                LSR     noun_stk_l,X
00EC1B  2  4C 36 E7     Lec1b:  JMP     not_op
00EC1E  2               
00EC1E  2  FF FF                .byte   $FF,$FF
00EC20  2               
00EC20  2               ; indexes into syntabl
00EC20  2               syntabl_index:
00EC20  2  C1 FF 7F D1          .byte   $C1,$FF,$7F,$D1,$CC,$C7,$CF,$CE
00EC24  2  CC C7 CF CE  
00EC28  2  C5 9A 98 8B          .byte   $C5,$9A,$98,$8B,$96,$95,$93,$BF
00EC2C  2  96 95 93 BF  
00EC30  2  B2 32 2D 2B          .byte   $B2,$32,$2D,$2B,$BC,$B0,$AC,$BE
00EC34  2  BC B0 AC BE  
00EC38  2  35 8E 61 FF          .byte   $35,$8E,$61,$FF,$FF,$FF,$DD,$FB
00EC3C  2  FF FF DD FB  
00EC40  2               
00EC40  2  20 C9 EF     Tec40:  JSR     Sefc9
00EC43  2  15 4F                ORA     rnd+1,X
00EC45  2  10 05                BPL     Lec4c
00EC47  2               
00EC47  2  20 C9 EF     Tec47:  JSR     Sefc9
00EC4A  2  35 4F                AND     rnd+1,X
00EC4C  2  95 50        Lec4c:  STA     noun_stk_l,X
00EC4E  2  10 CB                BPL     Lec1b
00EC50  2  4C C9 EF             JMP     Sefc9
00EC53  2  40 60 8D 60          .byte   $40,$60,$8D,$60,$8B,$00,$7E,$8C
00EC57  2  8B 00 7E 8C  
00EC5B  2  33 00 00 60          .byte   $33,$00,$00,$60,$03,$BF,$12,$00
00EC5F  2  03 BF 12 00  
00EC63  2  40 89 C9 47          .byte   $40,$89,$C9,$47,$9D,$17,$68,$9D
00EC67  2  9D 17 68 9D  
00EC6B  2  0A 00 40 60          .byte   $0A,$00,$40,$60,$8D,$60,$8B,$00
00EC6F  2  8D 60 8B 00  
00EC73  2  7E 8C 3C 00          .byte   $7E,$8C,$3C,$00,$00,$60,$03,$BF
00EC77  2  00 60 03 BF  
00EC7B  2  1B 4B 67 B4          .byte   $1B,$4B,$67,$B4,$A1,$07,$8C,$07
00EC7F  2  A1 07 8C 07  
00EC83  2  AE A9 AC A8          .byte   $AE,$A9,$AC,$A8,$67,$8C,$07,$B4
00EC87  2  67 8C 07 B4  
00EC8B  2  AF AC B0 67          .byte   $AF,$AC,$B0,$67,$9D,$B2,$AF,$AC
00EC8F  2  9D B2 AF AC  
00EC93  2  AF A3 67 8C          .byte   $AF,$A3,$67,$8C,$07,$A5,$AB,$AF
00EC97  2  07 A5 AB AF  
00EC9B  2  B0 F4 AE A9          .byte   $B0,$F4,$AE,$A9,$B2,$B0,$7F,$0E
00EC9F  2  B2 B0 7F 0E  
00ECA3  2  27 B4 AE A9          .byte   $27,$B4,$AE,$A9,$B2,$B0,$7F,$0E
00ECA7  2  B2 B0 7F 0E  
00ECAB  2  28 B4 AE A9          .byte   $28,$B4,$AE,$A9,$B2,$B0,$64,$07
00ECAF  2  B2 B0 64 07  
00ECB3  2  A6 A9 67 AF          .byte   $A6,$A9,$67,$AF,$B4,$AF,$A7,$78
00ECB7  2  B4 AF A7 78  
00ECBB  2  B4 A5 AC 78          .byte   $B4,$A5,$AC,$78,$7F,$02,$AD,$A5
00ECBF  2  7F 02 AD A5  
00ECC3  2  B2 67 A2 B5          .byte   $B2,$67,$A2,$B5,$B3,$AF,$A7,$EE
00ECC7  2  B3 AF A7 EE  
00ECCB  2  B2 B5 B4 A5          .byte   $B2,$B5,$B4,$A5,$B2,$7E,$8C,$39
00ECCF  2  B2 7E 8C 39  
00ECD3  2  B4 B8 A5 AE          .byte   $B4,$B8,$A5,$AE,$67,$B0,$A5,$B4
00ECD7  2  67 B0 A5 B4  
00ECDB  2  B3 27 AF B4          .byte   $B3,$27,$AF,$B4,$07,$9D,$19,$B2
00ECDF  2  07 9D 19 B2  
00ECE3  2  AF A6 7F 05          .byte   $AF,$A6,$7F,$05,$37,$B4,$B5,$B0
00ECE7  2  37 B4 B5 B0  
00ECEB  2  AE A9 7F 05          .byte   $AE,$A9,$7F,$05,$28,$B4,$B5,$B0
00ECEF  2  28 B4 B5 B0  
00ECF3  2  AE A9 7F 05          .byte   $AE,$A9,$7F,$05,$2A,$B4,$B5,$B0
00ECF7  2  2A B4 B5 B0  
00ECFB  2  AE A9 E4 AE          .byte   $AE,$A9,$E4,$AE,$A5,$00,$FF,$FF
00ECFF  2  A5 00 FF FF  
00ED03  2               syntabl2:
00ED03  2  47 A2 A1 B4          .byte   $47,$A2,$A1,$B4,$7F,$0D,$30,$AD
00ED07  2  7F 0D 30 AD  
00ED0B  2  A9 A4 7F 0D          .byte   $A9,$A4,$7F,$0D,$23,$AD,$A9,$A4
00ED0F  2  23 AD A9 A4  
00ED13  2  67 AC AC A1          .byte   $67,$AC,$AC,$A1,$A3,$00,$40,$80
00ED17  2  A3 00 40 80  
00ED1B  2  C0 C1 80 00          .byte   $C0,$C1,$80,$00,$47,$8C,$68,$8C
00ED1F  2  47 8C 68 8C  
00ED23  2  DB 67 9B 68          .byte   $DB,$67,$9B,$68,$9B,$50,$8C,$63
00ED27  2  9B 50 8C 63  
00ED2B  2  8C 7F 01 51          .byte   $8C,$7F,$01,$51,$07,$88,$29,$84
00ED2F  2  07 88 29 84  
00ED33  2  80 C4 80 57          .byte   $80,$C4,$80,$57,$71,$07,$88,$14
00ED37  2  71 07 88 14  
00ED3B  2  ED A5 AD AF          .byte   $ED,$A5,$AD,$AF,$AC,$ED,$A5,$AD
00ED3F  2  AC ED A5 AD  
00ED43  2  A9 A8 F2 AF          .byte   $A9,$A8,$F2,$AF,$AC,$AF,$A3,$71
00ED47  2  AC AF A3 71  
00ED4B  2  08 88 AE A5          .byte   $08,$88,$AE,$A5,$AC,$68,$83,$08
00ED4F  2  AC 68 83 08  
00ED53  2  68 9D 08 71          .byte   $68,$9D,$08,$71,$07,$88,$60,$76
00ED57  2  07 88 60 76  
00ED5B  2  B4 AF AE 76          .byte   $B4,$AF,$AE,$76,$8D,$76,$8B,$51
00ED5F  2  8D 76 8B 51  
00ED63  2  07 88 19 B8          .byte   $07,$88,$19,$B8,$A4,$AE,$B2,$F2
00ED67  2  A4 AE B2 F2  
00ED6B  2  B3 B5 F3 A2          .byte   $B3,$B5,$F3,$A2,$A1,$EE,$A7,$B3
00ED6F  2  A1 EE A7 B3  
00ED73  2  E4 AE B2 EB          .byte   $E4,$AE,$B2,$EB,$A5,$A5,$B0,$51
00ED77  2  A5 A5 B0 51  
00ED7B  2  07 88 39 81          .byte   $07,$88,$39,$81,$C1,$4F,$7F,$0F
00ED7F  2  C1 4F 7F 0F  
00ED83  2  2F 00 51 06          .byte   $2F,$00,$51,$06,$88,$29,$C2,$0C
00ED87  2  88 29 C2 0C  
00ED8B  2  82 57 8C 6A          .byte   $82,$57,$8C,$6A,$8C,$42,$AE,$A5
00ED8F  2  8C 42 AE A5  
00ED93  2  A8 B4 60 AE          .byte   $A8,$B4,$60,$AE,$A5,$A8,$B4,$4F
00ED97  2  A5 A8 B4 4F  
00ED9B  2  7E 1E 35 8C          .byte   $7E,$1E,$35,$8C,$27,$51,$07,$88
00ED9F  2  27 51 07 88  
00EDA3  2  09 8B FE E4          .byte   $09,$8B,$FE,$E4,$AF,$AD,$F2,$AF
00EDA7  2  AF AD F2 AF  
00EDAB  2  E4 AE A1 DC          .byte   $E4,$AE,$A1,$DC,$DE,$9C,$DD,$9C
00EDAF  2  DE 9C DD 9C  
00EDB3  2  DE DD 9E C3          .byte   $DE,$DD,$9E,$C3,$DD,$CF,$CA,$CD
00EDB7  2  DD CF CA CD  
00EDBB  2  CB 00 47 9D          .byte   $CB,$00,$47,$9D,$AD,$A5,$AD,$AF
00EDBF  2  AD A5 AD AF  
00EDC3  2  AC 76 9D AD          .byte   $AC,$76,$9D,$AD,$A5,$AD,$A9,$A8
00EDC7  2  A5 AD A9 A8  
00EDCB  2  E6 A6 AF 60          .byte   $E6,$A6,$AF,$60,$8C,$20,$AF,$B4
00EDCF  2  8C 20 AF B4  
00EDD3  2  B5 A1 F2 AC          .byte   $B5,$A1,$F2,$AC,$A3,$F2,$A3,$B3
00EDD7  2  A3 F2 A3 B3  
00EDDB  2  60 8C 20 AC          .byte   $60,$8C,$20,$AC,$A5,$A4,$EE,$B5
00EDDF  2  A5 A4 EE B5  
00EDE3  2  B2 60 AE B5          .byte   $B2,$60,$AE,$B5,$B2,$F4,$B3,$A9
00EDE7  2  B2 F4 B3 A9  
00EDEB  2  AC 60 8C 20          .byte   $AC,$60,$8C,$20,$B4,$B3,$A9,$AC
00EDEF  2  B4 B3 A9 AC  
00EDF3  2  7A 7E 9A 22          .byte   $7A,$7E,$9A,$22,$20,$00,$60,$03
00EDF7  2  20 00 60 03  
00EDFB  2  BF 60 03 BF          .byte   $BF,$60,$03,$BF,$1F
00EDFF  2  1F           
00EE00  2               
00EE00  2               ; token $48 - "," string output
00EE00  2  20 B1 E7     print_str_comma:        JSR     tabout
00EE03  2               
00EE03  2               ; token $45 - ";" string output
00EE03  2               ; token $61 - "PRINT" string
00EE03  2  E8           print_str:      INX
00EE04  2  E8                   INX
00EE05  2  B5 4F                LDA     rnd+1,X
00EE07  2  85 DA                STA     aux
00EE09  2  B5 77                LDA     syn_stk_h+31,X
00EE0B  2  85 DB                STA     aux+1
00EE0D  2  B4 4E                LDY     rnd,X
00EE0F  2  98           Lee0f:  TYA
00EE10  2  D5 76                CMP     syn_stk_h+30,X
00EE12  2  B0 09                BCS     Lee1d
00EE14  2  B1 DA                LDA     (aux),Y
00EE16  2  20 C9 E3             JSR     cout
00EE19  2  C8                   INY
00EE1A  2  4C 0F EE             JMP     Lee0f
00EE1D  2  A9 FF        Lee1d:  LDA     #$FF
00EE1F  2  85 D5                STA     cr_flag
00EE21  2  60                   RTS
00EE22  2               
00EE22  2               ; token $3B - "LEN(" function
00EE22  2  E8           len_fn: INX
00EE23  2  A9 00                LDA     #$00
00EE25  2  95 78                STA     noun_stk_h_str,X
00EE27  2  95 A0                STA     noun_stk_h_int,X
00EE29  2  B5 77                LDA     syn_stk_h+31,X
00EE2B  2  38                   SEC
00EE2C  2  F5 4F                SBC     rnd+1,X
00EE2E  2  95 50                STA     noun_stk_l,X
00EE30  2  4C 23 E8             JMP     left_paren
00EE33  2               
00EE33  2  FF                   .byte   $FF
00EE34  2               
00EE34  2  20 15 E7     getbyte:        JSR     get16bit
00EE37  2  A5 CF                LDA     acc+1
00EE39  2  D0 28                BNE     gr_255_err
00EE3B  2  A5 CE                LDA     acc
00EE3D  2  60                   RTS
00EE3E  2               
00EE3E  2               ; token $68 - "," for PLOT statement (???)
00EE3E  2  20 34 EE     plot_comma:     JSR     getbyte
00EE41  2  A4 C8                LDY     text_index
00EE43  2  C9 30                CMP     #$30
00EE45  2  B0 21                BCS     range_err
00EE47  2  C0 28                CPY     #$28
00EE49  2  B0 1D                BCS     range_err
00EE4B  2  60                   RTS
00EE4C  2  EA                   NOP
00EE4D  2  EA                   NOP
00EE4E  2               
00EE4E  2  20 34 EE     Tee4e:  JSR     getbyte
00EE51  2  60                   RTS
00EE52  2  EA                   NOP
00EE53  2  8A           Tee5e:  TXA
00EE54  2  A2 01                LDX     #$01
00EE56  2  B4 CE        l123:   LDY     acc,X
00EE58  2  94 4C                STY     himem,X
00EE5A  2  B4 48                LDY     var,X
00EE5C  2  94 CA                STY     pp,X
00EE5E  2  CA                   DEX
00EE5F  2  F0 F5                BEQ     l123
00EE61  2  AA                   TAX
00EE62  2  60                   RTS
00EE63  2  A0 77        gr_255_err:     LDY     #$77            ; > 255 error
00EE65  2  4C E0 E3     go_errmess_5:   JMP     print_err_msg
00EE68  2  A0 7B        range_err:      LDY     #$7B            ; range error
00EE6A  2  D0 F9                BNE     go_errmess_5
00EE6C  2               
00EE6C  2  20 54 E2     See6c:  JSR     Se254
00EE6F  2  A5 DA                LDA     aux
00EE71  2  D0 07                BNE     Lee7a
00EE73  2  A5 DB                LDA     aux+1
00EE75  2  D0 03                BNE     Lee7a
00EE77  2  4C 7E E7             JMP     Le77e
00EE7A  2  06 CE        Lee7a:  ASL     acc
00EE7C  2  26 CF                ROL     acc+1
00EE7E  2  26 E6                ROL     p3
00EE80  2  26 E7                ROL     p3+1
00EE82  2  A5 E6                LDA     p3
00EE84  2  C5 DA                CMP     aux
00EE86  2  A5 E7                LDA     p3+1
00EE88  2  E5 DB                SBC     aux+1
00EE8A  2  90 0A                BCC     Lee96
00EE8C  2  85 E7                STA     p3+1
00EE8E  2  A5 E6                LDA     p3
00EE90  2  E5 DA                SBC     aux
00EE92  2  85 E6                STA     p3
00EE94  2  E6 CE                INC     acc
00EE96  2  88           Lee96:  DEY
00EE97  2  D0 E1                BNE     Lee7a
00EE99  2  60                   RTS
00EE9A  2               
00EE9A  2  FF FF FF FF          .byte   $FF,$FF,$FF,$FF,$FF,$FF
00EE9E  2  FF FF        
00EEA0  2               
00EEA0  2               ; token $4D - "CALL" statement
00EEA0  2  20 15 E7     call_stmt:      JSR     get16bit
00EEA3  2  6C CE 00             JMP     (acc)
00EEA6  2  A5 4C        l1233:  LDA     himem
00EEA8  2  D0 02                BNE     l1235
00EEAA  2  C6 4D                DEC     himem+1
00EEAC  2  C6 4C        l1235:  DEC     himem
00EEAE  2  A5 48                LDA     var
00EEB0  2  D0 02                BNE     l1236
00EEB2  2  C6 49                DEC     var+1
00EEB4  2  C6 48        l1236:  DEC     var
00EEB6  2  A0 00        l1237:  LDY     #$00
00EEB8  2  B1 4C                LDA     (himem),Y
00EEBA  2  91 48                STA     (var),Y
00EEBC  2  A5 CA                LDA     pp
00EEBE  2  C5 4C                CMP     himem
00EEC0  2  A5 CB                LDA     pp+1
00EEC2  2  E5 4D        leec2:  SBC     himem+1
00EEC4  2  90 E0                BCC     l1233
00EEC6  2  4C 53 EE             JMP     Tee5e
00EEC9  2  C9 28                CMP     #$28
00EECB  2  B0 9B        Leecb:  BCS     range_err
00EECD  2  A8                   TAY
00EECE  2  A5 C8                LDA     text_index
00EED0  2  60                   RTS
00EED1  2  EA                   NOP
00EED2  2  EA                   NOP
00EED3  2               
00EED3  2               print_err_msg1:
00EED3  2  98                   TYA
00EED4  2  AA                   TAX
00EED5  2  A0 6E                LDY     #$6E
00EED7  2  20 C4 E3             JSR     Se3c4
00EEDA  2  8A                   TXA
00EEDB  2  A8                   TAY
00EEDC  2  20 C4 E3             JSR     Se3c4
00EEDF  2  A0 72                LDY     #$72
00EEE1  2  4C C4 E3             JMP     Se3c4
00EEE4  2               
00EEE4  2  20 15 E7     Seee4:  JSR     get16bit
00EEE7  2  06 CE        Leee7:  ASL     acc
00EEE9  2  26 CF                ROL     acc+1
00EEEB  2  30 FA                BMI     Leee7
00EEED  2  B0 DC                BCS     Leecb
00EEEF  2  D0 04                BNE     Leef5
00EEF1  2  C5 CE                CMP     acc
00EEF3  2  B0 D6                BCS     Leecb
00EEF5  2  60           Leef5:  RTS
00EEF6  2               
00EEF6  2               ; token $2E - "PEEK" fn (uses $3F left paren)
00EEF6  2  20 15 E7     peek_fn:        JSR     get16bit
00EEF9  2  B1 CE                LDA     (acc),Y
00EEFB  2  94 9F                STY     syn_stk_l+31,X
00EEFD  2  4C 08 E7             JMP     push_ya_noun_stk
00EF00  2               
00EF00  2               ; token $65 - "," for POKE statement
00EF00  2  20 34 EE     poke_stmt:      JSR     getbyte
00EF03  2  A5 CE                LDA     acc
00EF05  2  48                   PHA
00EF06  2  20 15 E7             JSR     get16bit
00EF09  2  68                   PLA
00EF0A  2  91 CE                STA     (acc),Y
00EF0C  2               
00EF0C  2  60           Tef0c:  RTS
00EF0D  2               
00EF0D  2  FF FF FF             .byte   $FF,$FF,$FF
00EF10  2               
00EF10  2               ; token $15 - "/" for numeric division
00EF10  2  20 6C EE     divide: JSR     See6c
00EF13  2  A5 CE                LDA     acc
00EF15  2  85 E6                STA     p3
00EF17  2  A5 CF                LDA     acc+1
00EF19  2  85 E7                STA     p3+1
00EF1B  2  4C 44 E2             JMP     Le244
00EF1E  2               
00EF1E  2               ; token $44 - "," next var in DIM statement is numeric
00EF1E  2               ; token $4F - "DIM", next var is numeric
00EF1E  2  20 E4 EE     dim_num:        JSR     Seee4
00EF21  2  4C 34 E1             JMP     Le134
00EF24  2               
00EF24  2               ; token $2D - "(" for numeric array subscript
00EF24  2  20 E4 EE     num_array_subs: JSR     Seee4
00EF27  2  B4 78                LDY     noun_stk_h_str,X
00EF29  2  B5 50                LDA     noun_stk_l,X
00EF2B  2  69 FE                ADC     #$FE
00EF2D  2  B0 01                BCS     Lef30
00EF2F  2  88                   DEY
00EF30  2  85 DA        Lef30:  STA     aux
00EF32  2  84 DB                STY     aux+1
00EF34  2  18                   CLC
00EF35  2  65 CE                ADC     acc
00EF37  2  95 50                STA     noun_stk_l,X
00EF39  2  98                   TYA
00EF3A  2  65 CF                ADC     acc+1
00EF3C  2  95 78                STA     noun_stk_h_str,X
00EF3E  2  A0 00                LDY     #$00
00EF40  2  B5 50                LDA     noun_stk_l,X
00EF42  2  D1 DA                CMP     (aux),Y
00EF44  2  C8                   INY
00EF45  2  B5 78                LDA     noun_stk_h_str,X
00EF47  2  F1 DA                SBC     (aux),Y
00EF49  2  B0 80                BCS     Leecb
00EF4B  2  4C 23 E8             JMP     left_paren
00EF4E  2               
00EF4E  2               ; token $2F - "RND" fn (uses $3F left paren)
00EF4E  2  20 15 E7     rnd_fn: JSR     get16bit
00EF51  2  A5 4E                LDA     rnd
00EF53  2  20 08 E7             JSR     push_ya_noun_stk
00EF56  2  A5 4F                LDA     rnd+1
00EF58  2  D0 04                BNE     Lef5e
00EF5A  2  C5 4E                CMP     rnd
00EF5C  2  69 00                ADC     #$00
00EF5E  2  29 7F        Lef5e:  AND     #$7F
00EF60  2  85 4F                STA     rnd+1
00EF62  2  95 A0                STA     noun_stk_h_int,X
00EF64  2  A0 11                LDY     #$11
00EF66  2  A5 4F        Lef66:  LDA     rnd+1
00EF68  2  0A                   ASL
00EF69  2  18                   CLC
00EF6A  2  69 40                ADC     #$40
00EF6C  2  0A                   ASL
00EF6D  2  26 4E                ROL     rnd
00EF6F  2  26 4F                ROL     rnd+1
00EF71  2  88                   DEY
00EF72  2  D0 F2                BNE     Lef66
00EF74  2  A5 CE                LDA     acc
00EF76  2  20 08 E7             JSR     push_ya_noun_stk
00EF79  2  A5 CF                LDA     acc+1
00EF7B  2  95 A0                STA     noun_stk_h_int,X
00EF7D  2  4C 7A E2             JMP     mod_op
00EF80  2               
00EF80  2  20 15 E7     Tef80:  JSR     get16bit
00EF83  2  A4 CE                LDY     acc
00EF85  2  C4 4C                CPY     himem
00EF87  2  A5 CF                LDA     acc+1
00EF89  2  E5 4D                SBC     himem+1
00EF8B  2  90 1F                BCC     Lefab
00EF8D  2  84 48                STY     var
00EF8F  2  A5 CF                LDA     acc+1
00EF91  2  85 49                STA     var+1
00EF93  2  4C B6 EE     Lef93:  JMP     l1237
00EF96  2               
00EF96  2  20 15 E7     Tef96:  JSR     get16bit
00EF99  2  A4 CE                LDY     acc
00EF9B  2  C4 CA                CPY     pp
00EF9D  2  A5 CF                LDA     acc+1
00EF9F  2  E5 CB                SBC     pp+1
00EFA1  2  B0 09                BCS     Lefab
00EFA3  2  84 4A                STY     lomem
00EFA5  2  A5 CF                LDA     acc+1
00EFA7  2  85 4B                STA     lomem+1
00EFA9  2  4C B7 E5             JMP     clr
00EFAC  2  4C CB EE     Lefab:  JMP     Leecb
00EFAF  2  EA                   NOP
00EFB0  2  EA                   NOP
00EFB1  2  EA                   NOP
00EFB2  2  EA                   NOP
00EFB3  2  20 C9 EF     Lefb3:  JSR     Sefc9
00EFB6  2               
00EFB6  2               ; token $26 - "," for string input
00EFB6  2               ; token $52 - "INPUT" statement for string
00EFB6  2  20 71 E1     string_input:   JSR     input_str
00EFB9  2  4C BF EF             JMP     Lefbf
00EFBC  2               
00EFBC  2               ; token $53 - "INPUT" with literal string prompt
00EFBC  2  20 03 EE     input_prompt:   JSR     print_str
00EFBF  2  A9 FF        Lefbf:  LDA     #$FF
00EFC1  2  85 C8                STA     text_index
00EFC3  2  A9 74                LDA     #$74
00EFC5  2  8D 00 02             STA     buffer
00EFC8  2  60                   RTS
00EFC9  2               
00EFC9  2  20 36 E7     Sefc9:  JSR     not_op
00EFCC  2  E8                   INX
00EFCD  2               
00EFCD  2  20 36 E7     Sefcd:  JSR     not_op
00EFD0  2  B5 50                LDA     noun_stk_l,X
00EFD2  2  60                   RTS
00EFD3  2               
00EFD3  2               ; memory initialization for 4K RAM
00EFD3  2  A9 00        mem_init_4k:    LDA     #$00
00EFD5  2  85 4A                STA     lomem
00EFD7  2  85 4C                STA     himem
00EFD9  2  A9 08                LDA     #$08
00EFDB  2  85 4B                STA     lomem+1         ; LOMEM defaults to $0800
00EFDD  2  A9 10                LDA     #$10
00EFDF  2  85 4D                STA     himem+1         ; HIMEM defaults to $1000
00EFE1  2  4C AD E5             JMP     new_cmd
00EFE4  2               
00EFE4  2  D5 78        Sefe4:  CMP     noun_stk_h_str,X
00EFE6  2  D0 01                BNE     Lefe9
00EFE8  2  18                   CLC
00EFE9  2  4C 02 E1     Lefe9:  JMP     Le102
00EFEC  2               
00EFEC  2  20 B7 E5     Tefec:  JSR     clr
00EFEF  2  4C 36 E8             JMP     run_warm
00EFF2  2               
00EFF2  2  20 B7 E5     Teff2:  JSR     clr
00EFF5  2  4C 5B E8             JMP     goto_stmt
00EFF8  2               
00EFF8  2  E0 80        Seff8:  CPX     #$80
00EFFA  2  D0 01                BNE     Leffd
00EFFC  2  88                   DEY
00EFFD  2  4C 0C E0     Leffd:  JMP     Se00c
00F000  2               
00F000  1               
00F000  1                         .segment "F000"
00F000  1  EA                     nop
00F001  1                         ;Woz face
00F001  1                        ; .include "Apple30th_Woz.asm"
00F001  1               
00F001  1                         .segment "F800"
00F001  1  EA                     nop
00F002  1                         ;Test from Apple-1 Operation Manual â€“ printing all ASCII symbols in a loop
00F002  1                        ; .include "TestFromManual.asm"
00F002  1               
00F002  1                         .segment "FA00"
00F002  1  EA                     nop
00F003  1                         ;Power-On Self Test (POST)
00F003  1                        ; .include "POST.asm"
00F003  1               
00F003  1                          .segment "FC00"
00F003  1  EA                      nop
00F004  1                         ;;printing 8x8 picture in the center with '*'
00F004  1                        ; .include "8x8art.asm"
00F004  1               
00F004  1                         .segment "FD00"
00F004  1                         ;.include "POST.asm"
00F004  1  EA                     nop
00F005  1                         ;Printing 'Hello, World!'
00F005  1                         ;.include "HelloWorld.asm"
00F005  1               
00F005  1                         .segment "FF00"
00F005  1                         .include "Woz_Monitor.asm"
00F005  2               ;  The WOZ Monitor for the Apple 1
00F005  2               ;  Written by Steve Wozniak in 1976
00F005  2               
00F005  2               
00F005  2               ; Page 0 Variables
00F005  2               
00F005  2               XAML            = $24           ;  Last "opened" location Low
00F005  2               XAMH            = $25           ;  Last "opened" location High
00F005  2               STL             = $26           ;  Store address Low
00F005  2               STH             = $27           ;  Store address High
00F005  2               L               = $28           ;  Hex value parsing Low
00F005  2               H               = $29           ;  Hex value parsing High
00F005  2               YSAV            = $2A           ;  Used to see if hex value is given
00F005  2               MODE            = $2B           ;  $00=XAM, $7F=STOR, $AE=BLOCK XAM
00F005  2               
00F005  2               
00F005  2               ; Other Variables
00F005  2               
00F005  2               IN              = $0200         ;  Input buffer to $027F
00F005  2               KBD             = $D010         ;  PIA.A keyboard input
00F005  2               KBDCR           = $D011         ;  PIA.A keyboard control register
00F005  2               DSP             = $D012         ;  PIA.B display output register
00F005  2               DSPCR           = $D013         ;  PIA.B display control register
00F005  2               
00F005  2                              .org $FF00
00FF00  2                              .export RESET
00FF00  2               
00FF00  2  D8           RESET:          CLD             ; Clear decimal arithmetic mode.
00FF01  2  58                           CLI
00FF02  2  A0 7F                        LDY #$7F        ; Mask for DSP data direction register.
00FF04  2  8C 12 D0                     STY DSP         ; Set it up.
00FF07  2  A9 A7                        LDA #$A7        ; KBD and DSP control register mask.
00FF09  2  8D 11 D0                     STA KBDCR       ; Enable interrupts, set CA1, CB1, for
00FF0C  2  8D 13 D0                     STA DSPCR       ; positive edge sense/output mode.
00FF0F  2  C9 DF        NOTCR:          CMP #'_'+$80    ; "_"?
00FF11  2  F0 13                        BEQ BACKSPACE   ; Yes.
00FF13  2  C9 9B                        CMP #$9B        ; ESC?
00FF15  2  F0 03                        BEQ ESCAPE      ; Yes.
00FF17  2  C8                           INY             ; Advance text index.
00FF18  2  10 0F                        BPL NEXTCHAR    ; Auto ESC if > 127.
00FF1A  2  A9 DC        ESCAPE:         LDA #'\'+$80    ; "\".
00FF1C  2  20 EF FF                     JSR ECHO        ; Output it.
00FF1F  2  A9 8D        GETLINE:        LDA #$8D        ; CR.
00FF21  2  20 EF FF                     JSR ECHO        ; Output it.
00FF24  2  A0 01                        LDY #$01        ; Initialize text index.
00FF26  2  88           BACKSPACE:      DEY             ; Back up text index.
00FF27  2  30 F6                        BMI GETLINE     ; Beyond start of line, reinitialize.
00FF29  2  AD 11 D0     NEXTCHAR:       LDA KBDCR       ; Key ready?
00FF2C  2  10 FB                        BPL NEXTCHAR    ; Loop until ready.
00FF2E  2  AD 10 D0                     LDA KBD         ; Load character. B7 should be ‘1’.
00FF31  2  99 00 02                     STA IN,Y        ; Add to text buffer.
00FF34  2  20 EF FF                     JSR ECHO        ; Display character.
00FF37  2  C9 8D                        CMP #$8D        ; CR?
00FF39  2  D0 D4                        BNE NOTCR       ; No.
00FF3B  2  A0 FF                        LDY #$FF        ; Reset text index.
00FF3D  2  A9 00                        LDA #$00        ; For XAM mode.
00FF3F  2  AA                           TAX             ; 0->X.
00FF40  2  0A           SETSTOR:        ASL             ; Leaves $7B if setting STOR mode.
00FF41  2  85 2B        SETMODE:        STA MODE        ; $00=XAM $7B=STOR $AE=BLOK XAM
00FF43  2  C8           BLSKIP:         INY             ; Advance text index.
00FF44  2  B9 00 02     NEXTITEM:       LDA IN,Y        ; Get character.
00FF47  2  C9 8D                        CMP #$8D        ; CR?
00FF49  2  F0 D4                        BEQ GETLINE     ; Yes, done this line.
00FF4B  2  C9 AE                        CMP #'.'+$80    ; "."?
00FF4D  2  90 F4                        BCC BLSKIP      ; Skip delimiter.
00FF4F  2  F0 F0                        BEQ SETMODE     ; Yes. Set STOR mode.
00FF51  2  C9 BA                        CMP #':'+$80    ; ":"?
00FF53  2  F0 EB                        BEQ SETSTOR     ; Yes. Set STOR mode.
00FF55  2  C9 D2                        CMP #'R'+$80    ; "R"?
00FF57  2  F0 3B                        BEQ RUN         ; Yes. Run user program.
00FF59  2  86 28                        STX L           ; $00-> L.
00FF5B  2  86 29                        STX H           ; and H.
00FF5D  2  84 2A                        STY YSAV        ; Save Y for comparison.
00FF5F  2  B9 00 02     NEXTHEX:        LDA IN,Y        ; Get character for hex test.
00FF62  2  49 B0                        EOR #$B0        ; Map digits to $0-9.
00FF64  2  C9 0A                        CMP #$0A        ; Digit?
00FF66  2  90 06                        BCC DIG         ; Yes.
00FF68  2  69 88                        ADC #$88        ; Map letter "A"-"F" to $FA-FF.
00FF6A  2  C9 FA                        CMP #$FA        ; Hex letter?
00FF6C  2  90 11                        BCC NOTHEX      ; No, character not hex.
00FF6E  2  0A           DIG:            ASL
00FF6F  2  0A                           ASL             ; Hex digit to MSD of A.
00FF70  2  0A                           ASL
00FF71  2  0A                           ASL
00FF72  2  A2 04                        LDX #$04        ; Shift count.
00FF74  2  0A           HEXSHIFT:       ASL             ; Hex digit left, MSB to carry.
00FF75  2  26 28                        ROL L           ; Rotate into LSD.
00FF77  2  26 29                        ROL H           ;  Rotate into MSD’s.
00FF79  2  CA                           DEX             ; Done 4 shifts?
00FF7A  2  D0 F8                        BNE HEXSHIFT    ; No, loop.
00FF7C  2  C8                           INY             ; Advance text index.
00FF7D  2  D0 E0                        BNE NEXTHEX     ; Always taken. Check next char for hex.
00FF7F  2  C4 2A        NOTHEX:         CPY YSAV        ; Check if L, H empty (no hex digits).
00FF81  2  F0 97                        BEQ ESCAPE      ; Yes, generate ESC sequence.
00FF83  2  24 2B                        BIT MODE        ; Test MODE byte.
00FF85  2  50 10                        BVC NOTSTOR     ;  B6=0 STOR 1 for XAM & BLOCK XAM
00FF87  2  A5 28                        LDA L           ; LSD’s of hex data.
00FF89  2  81 26                        STA (STL,X)     ; Store at current ‘store index’.
00FF8B  2  E6 26                        INC STL         ; Increment store index.
00FF8D  2  D0 B5                        BNE NEXTITEM    ; Get next item. (no carry).
00FF8F  2  E6 27                        INC STH         ; Add carry to ‘store index’ high order.
00FF91  2  4C 44 FF     TONEXTITEM:     JMP NEXTITEM    ; Get next command item.
00FF94  2  6C 24 00     RUN:            JMP (XAML)      ; Run at current XAM index.
00FF97  2  30 2B        NOTSTOR:        BMI XAMNEXT     ; B7=0 for XAM, 1 for BLOCK XAM.
00FF99  2  A2 02                        LDX #$02        ; Byte count.
00FF9B  2  B5 27        SETADR:         LDA L-1,X       ; Copy hex data to
00FF9D  2  95 25                        STA STL-1,X     ; ‘store index’.
00FF9F  2  95 23                        STA XAML-1,X    ; And to ‘XAM index’.
00FFA1  2  CA                           DEX             ; Next of 2 bytes.
00FFA2  2  D0 F7                        BNE SETADR      ; Loop unless X=0.
00FFA4  2  D0 14        NXTPRNT:        BNE PRDATA      ; NE means no address to print.
00FFA6  2  A9 8D                        LDA #$8D        ; CR.
00FFA8  2  20 EF FF                     JSR ECHO        ; Output it.
00FFAB  2  A5 25                        LDA XAMH        ; ‘Examine index’ high-order byte.
00FFAD  2  20 DC FF                     JSR PRBYTE      ; Output it in hex format.
00FFB0  2  A5 24                        LDA XAML        ; Low-order ‘examine index’ byte.
00FFB2  2  20 DC FF                     JSR PRBYTE      ; Output it in hex format.
00FFB5  2  A9 BA                        LDA #':'+$80    ; ":".
00FFB7  2  20 EF FF                     JSR ECHO        ; Output it.
00FFBA  2  A9 A0        PRDATA:         LDA #$A0        ; Blank.
00FFBC  2  20 EF FF                     JSR ECHO        ; Output it.
00FFBF  2  A1 24                        LDA (XAML,X)    ; Get data byte at ‘examine index’.
00FFC1  2  20 DC FF                     JSR PRBYTE      ; Output it in hex format.
00FFC4  2  86 2B        XAMNEXT:        STX MODE        ; 0->MODE (XAM mode).
00FFC6  2  A5 24                        LDA XAML
00FFC8  2  C5 28                        CMP L           ; Compare ‘examine index’ to hex data.
00FFCA  2  A5 25                        LDA XAMH
00FFCC  2  E5 29                        SBC H
00FFCE  2  B0 C1                        BCS TONEXTITEM  ; Not less, so no more data to output.
00FFD0  2  E6 24                        INC XAML
00FFD2  2  D0 02                        BNE MOD8CHK     ; Increment ‘examine index’.
00FFD4  2  E6 25                        INC XAMH
00FFD6  2  A5 24        MOD8CHK:        LDA XAML        ; Check low-order ‘examine index’ byte
00FFD8  2  29 07                        AND #$07        ; For MOD 8=0
00FFDA  2  10 C8                        BPL NXTPRNT     ; Always taken.
00FFDC  2  48           PRBYTE:         PHA             ; Save A for LSD.
00FFDD  2  4A                           LSR
00FFDE  2  4A                           LSR
00FFDF  2  4A                           LSR             ; MSD to LSD position.
00FFE0  2  4A                           LSR
00FFE1  2  20 E5 FF                     JSR PRHEX       ; Output hex digit.
00FFE4  2  68                           PLA             ; Restore A.
00FFE5  2  29 0F        PRHEX:          AND #$0F        ; Mask LSD for hex print.
00FFE7  2  09 B0                        ORA #'0'+$80    ; Add "0".
00FFE9  2  C9 BA                        CMP #$BA        ; Digit?
00FFEB  2  90 02                        BCC ECHO        ; Yes, output it.
00FFED  2  69 06                        ADC #$06        ; Add offset for letter.
00FFEF  2  2C 12 D0     ECHO:           BIT DSP         ; bit (B7) cleared yet?
00FFF2  2  30 FB                        BMI ECHO        ; No, wait for display.
00FFF4  2  8D 12 D0                     STA DSP         ; Output character. Sets DA.
00FFF7  2  60                           RTS             ; Return.
00FFF8  2               
00FFF8  2  40            NMI:           RTI             ; simple Interrupt Service Routine(ISR)
00FFF9  2  40            IRQ:           RTI             ; simple Interrupt Service Routine(ISR)
00FFFA  2               
00FFFA  1               
00FFFA  1                         .segment "VECTORS"
00FFFA  1                         ; Interrupt Vectors
00FFFA  1  F8 FF                  .WORD NMI            ; NMI
00FFFC  1  00 FF                  .WORD RESET     ; RESET (starting point in Woz Monitor) or POST (test)
00FFFE  1  F9 FF                  .WORD IRQ            ; BRK/IRQ
010000  1               
010000  1               
010000  1               
