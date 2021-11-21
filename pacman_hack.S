.db "NES", $1A, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0


.org $8000

variables:
	.define player_x $0000
	.define player_y $0001
	.define mushroom_x $0002

colors:
	.define DARK_GRAY $00
	.define MEDIUM_GRAY $10
	.define LIGHT_GRAY $20
	.define LIGHTEST_GRAY $30
	
	.define DARK_BLUE $01
	.define MEDIUM_BLUE $11
	.define LIGHT_BLUE $21
	.define LIGHTEST_BLUE $31
	
	.define DARK_INDIGO $02
	.define MEDIUM_INDIGO $12
	.define LIGHT_INDIGO $22
	.define LIGHTEST_INDIGO $32
	
	.define DARK_VIOLET $03
	.define MEDIUM_VIOLET $13
	.define LIGHT_VIOLET $23
	.define LIGHTEST_VIOLET $33
	
	.define DARK_PURPLE $04
	.define MEDIUM_PURPLE $14
	.define LIGHT_PURPLE $24
	.define LIGHTEST_PURPLE $34
	
	.define DARK_REDVIOLET $05
	.define MEDIUM_REDVIOLET $15
	.define LIGHT_REDVIOLET $25
	.define LIGHTEST_REDVIOLET $35
	
	.define DARK_RED $06
	.define MEDIUM_RED $16
	.define LIGHT_RED $26
	.define LIGHTEST_RED $36
	
	.define DARK_ORANGE $07
	.define MEDIUM_ORANGE $17
	.define LIGHT_ORANGE $27
	.define LIGHTEST_ORANGE $37
	
	.define DARK_YELLOW $08
	.define MEDIUM_YELLOW $18
	.define LIGHT_YELLOW $28
	.define LIGHTEST_YELLOW $38
	
	.define DARK_CHARTREUSE $09
	.define MEDIUM_CHARTREUSE $19
	.define LIGHT_CHARTREUSE $29
	.define LIGHTEST_CHARTREUSE $39
	
	.define DARK_GREEN $0A
	.define MEDIUM_GREEN $1A
	.define LIGHT_GREEN $2A
	.define LIGHTEST_GREEN $3A
	
	.define DARK_CYAN $0B
	.define MEDIUM_CYAN $1B
	.define LIGHT_CYAN $2B
	.define LIGHTEST_CYAN $3B
	
	.define DARK_TURQUOISE $0C
	.define MEDIUM_TURQUOISE $1C
	.define LIGHT_TURQUOISE $2C
	.define LIGHTEST_TURQUOISE $3C
	
	.define BLACK $0F
	.define DARKEST_GRAY $2D
	.define MEDIUM_GRAY2 $3D

interfaces:
	.define PPUCTRL $2000
	.define PPUMASK $2001
	.define PPUSTATUS $2002
	.define OAMADDR $2003
	.define OAMDATA $2004
	.define PPUADDR $2006
	.define PPUDATA $2007
	.define OAMDMA	$4014
	.define JOYPAD1 $4016
	.define JOYPAD2 $4017

reset:
	SEI					; disable IRQs
	CLD					; disable decimal mode
	LDX #$40
	STX JOYPAD2			; disable APU frame IRQ
	LDX #$FF
	TXS					; set up stack
	INX
	STX PPUCTRL			; disable nmi
	STX PPUMASK			; disable rendering
	STX $4010			; disable DMC IRQs

vblankwait1:			; First wait for vblank to make sure PPU is ready
	BIT PPUSTATUS
	BPL vblankwait1

clrmem:
	LDA #$00
	STA $00, x
	STA $100, x
	STA $200, x
	STA $300, x
	STA $400, x
	STA $500, x
	STA $600, x
	STA $700, x
	INX
	BNE clrmem
   
vblankwait2:			; Second wait for vblank, PPU is ready after this
	BIT PPUSTATUS
	BPL vblankwait2

LoadPalettes:
	LDA PPUSTATUS		; read PPU status to reset the high/low latch
	LDA #$3F
	STA PPUADDR			; write the high byte of $3F00 address
	LDA #$00
	STA PPUADDR			; write the low byte of $3F00 address
	
	LDX #$00 
	LoadBackgroundPaletteLoop:
		LDA background_palette, x
		STA PPUDATA			; write to PPU
		INX
		CPX #$10			
		BNE LoadBackgroundPaletteLoop

	LDX #$00
	LoadSpritesPaletteLoop:
		LDA sprite_palette, x
		STA PPUDATA
		INX
		CPX #$10
		BNE LoadSpritesPaletteLoop

		LDA #%10000000		; enable NMI
		STA PPUCTRL
  
		LDA #%00010000		; enable sprites
		STA PPUMASK

		LDX #$00
		LDY #$F1

LoadSpritesLoop:
	LDA sprites, x      
	STA $200, x			
	INX                   
	CPX #$20            
	BNE LoadSpritesLoop 

InitializeVariables:
	; set starting value for vars
	LDA $203
	STA player_x
	LDA $200
	STA player_y
	LDA $213
	STA mushroom_x

Foreverloop:
	JMP Foreverloop     

nmi:
	LDA #$00 
	STA OAMADDR
	LDA #$02 
	STA OAMDMA

NPCControl:
	CPY #$08
	BEQ NPC_MoveRight

	NPC_MoveLeft:
		LDX #$00
		LoadGhostLeftSpritesLoop:
			INX                   
			LDA ghost_left, x      
			STA $210, x		     
			INX                 	
			LDA ghost_left, x  
			STA $210, x		
			INX                 	
			INX                 	
			CPX #$10            
			BNE LoadGhostLeftSpritesLoop 
		LDA mushroom_x
		STA $213
		STA $21B
		TAX
		CLC
		ADC #$08
		STA $217
		STA $21F
		DEX
		STX mushroom_x
		CPX #$10
		BCC SetNextMoveRight
		JMP JoypadControl

	NPC_MoveRight:
		LDX #$00
		LoadGhostRightSpritesLoop:
			INX                   
			LDA ghost_right, x      
			STA $210, x		     
			INX                 	
			LDA ghost_right, x  
			STA $210, x		
			INX                 	
			INX                 	
			CPX #$10            
			BNE LoadGhostRightSpritesLoop 
		LDA mushroom_x
		STA $213
		STA $21B
		TAX
		CLC
		ADC #$08
		STA $217
		STA $21F
		INX
		STX mushroom_x 
		CPX #$F1
		BCS SetNextMoveLeft
		JMP JoypadControl

	SetNextMoveRight:
		LDY #$08
		JMP JoypadControl
	SetNextMoveLeft:
		LDY #$F1
		JMP JoypadControl

JoypadControl:
	LatchController:
		LDA #$01
		STA JOYPAD1
		LDA #$00
		STA JOYPAD1      ; tell both the controllers to latch buttons

	ReadA: 
		LDA JOYPAD1     
		AND #%00000001  
		BEQ ReadADone 
	ReadADone:        
  
	ReadB: 
		LDA JOYPAD1     
		AND #%00000001  
		BEQ ReadBDone   

	ReadBDone:        

	ReadSelect: 
		LDA JOYPAD1       
		AND #%00000001   
		BEQ ReadSelectDone

	ReadSelectDone:

	ReadStart: 
		LDA JOYPAD1      
		AND #%00000001  
		BEQ ReadStartDone

	ReadStartDone:

	ReadUp: 
		LDA JOYPAD1
		AND #%00000001
		BNE MoveUp
		BEQ ReadUpDone
	
	;Move Mario to the up
	MoveUp:
		LDA player_y
		STA $200
		STA $204
		TAX
		CLC
		ADC #08
		STA $208
		STA $20C
		DEX
		STX player_y 
		
		LDX #$00
		LoadPacmanUpSpritesLoop:
			INX                   
			LDA pacman_up, x      
			STA $200, x		     
			INX                 	
			LDA pacman_up, x  
			STA $200, x		
			INX                 	
			INX                 	
			CPX #$10            
			BNE LoadPacmanUpSpritesLoop 

	ReadUpDone:

	ReadDown: 
		LDA JOYPAD1       
		AND #%00000001  
		BNE MoveDown
		BEQ ReadDownDone

	;Move Mario to the down
	MoveDown:
		LDA player_y
		STA $200
		STA $204
		TAX
		CLC
		ADC #08
		STA $208
		STA $20C
		INX
		STX player_y 
		
		LDX #$00
		LoadPacmanDownSpritesLoop:
			INX                   
			LDA pacman_down, x      
			STA $200, x		     
			INX                 	
			LDA pacman_down, x  
			STA $200, x		
			INX                 	
			INX                 	
			CPX #$10            
			BNE LoadPacmanDownSpritesLoop 

	ReadDownDone:

	ReadLeft: 
		LDA JOYPAD1
		AND #%00000001  
		BNE MoveLeft
		JMP ReadLeftDone

	;Move Mario to the left
	MoveLeft:
		LDA player_x
		STA $203
		STA $20B
		TAX
		CLC
		ADC #$08
		STA $207
		STA $20F
		DEX
		STX player_x 
		
		LDX #$00
		LoadPacmanLeftSpritesLoop:
			INX                   
			LDA pacman_left, x      
			STA $200, x		     
			INX                 	
			LDA pacman_left, x  
			STA $200, x		
			INX                 	
			INX                 	
			CPX #$10            
			BNE LoadPacmanLeftSpritesLoop 

	ReadLeftDone:

	ReadRight: 
		LDA JOYPAD1
		AND #%00000001  
		BNE MoveRight
		JMP ReadRightDone

	;Move Mario to the right  
	MoveRight:
		LDA player_x
		STA $203
		STA $20B
		TAX
		CLC
		ADC #$08
		STA $207
		STA $20F
		INX
		STX player_x
		
		LDX #$00
		LoadPacmanRightSpritesLoop:
			INX                   
			LDA pacman_right, x      
			STA $200, x		     
			INX                 	
			LDA pacman_right, x  
			STA $200, x		
			INX                 	
			INX                 	
			CPX #$10            
			BNE LoadPacmanRightSpritesLoop 

	ReadRightDone:

		RTI

irq:
    RTI

background_palette:
  .db BLACK, LIGHT_CHARTREUSE,	MEDIUM_GREEN,	BLACK	;background palette 1
  .db BLACK, LIGHTEST_RED,		MEDIUM_ORANGE,	BLACK	;background palette 2
  .db BLACK, LIGHTEST_GRAY,		LIGHT_BLUE,		BLACK	;background palette 3
  .db BLACK, LIGHT_ORANGE,		MEDIUM_ORANGE,	BLACK	;background palette 4
  
sprite_palette:
  .db BLACK, LIGHT_YELLOW,			LIGHTEST_GRAY,	LIGHT_ORANGE	;sprite palette 1
  .db BLACK, MEDIUM_GREEN,		LIGHTEST_GRAY,	LIGHT_ORANGE	;sprite palette 2
  .db BLACK, MEDIUM_RED,			LIGHTEST_GRAY,	LIGHT_ORANGE	;sprite palette 3
  .db BLACK, BLACK,				LIGHTEST_RED,	MEDIUM_ORANGE   ;sprite palette 4

sprites:
	pacman_left:
		.db $78, $02, %00000000, $78   ;sprite 0
		.db $78, $03, %01000000, $80   ;sprite 1
		.db $80, $02, %10000000, $78   ;sprite 2
		.db $80, $03, %11000000, $80   ;sprite 3
	ghost_left:
		.db $D7, $1B, %00000000, $F1   ;sprite 0
		.db $D7, $1C, %00000000, $F8   ;sprite 1
		.db $DF, $1E, %00000000, $F1   ;sprite 2
		.db $DF, $1F, %00000000, $F8   ;sprite 3
	ghost_right:
		.db $D7, $1C, %01000000, $F1   ;sprite 0
		.db $D7, $1B, %01000000, $F8   ;sprite 1
		.db $DF, $1F, %01000000, $F1   ;sprite 2
		.db $DF, $1E, %01000000, $F8   ;sprite 3
	pacman_right:
		.db $78, $03, %00000000, $78   ;sprite 0
		.db $78, $02, %01000000, $80   ;sprite 1
		.db $80, $03, %10000000, $78   ;sprite 2
		.db $80, $02, %11000000, $80   ;sprite 3
	pacman_down:
		.db $78, $00, %00000000, $78   ;sprite 2
		.db $78, $01, %00000000, $80   ;sprite 2
		.db $80, $04, %00000000, $78   ;sprite 2
		.db $80, $04, %01000000, $80   ;sprite 2
	pacman_up:
		.db $78, $04, %10000000, $78   ;sprite 2
		.db $78, $04, %11000000, $80   ;sprite 2
		.db $80, $00, %10000000, $78   ;sprite 2
		.db $80, $01, %10000000, $80   ;sprite 2

.goto $FFFA
.dw nmi
.dw reset
.dw irq

.incbin "pacman.chr"   ;includes 8KB graphics file from SMB1