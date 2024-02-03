;	------------------------------------------------
;	|											   |
;	|			Práctica 5 - AOC 1				   |
;	|			Nerea Salamero Labara			   |
;	|			Inés Román Gracia				   |
;	|									   05/2022 |
;	------------------------------------------------
		AREA datos,DATA

VICIntEnable 	EQU 0xFFFFF010 			;activar IRQs (solo bits 1) 
VICIntEnClr 	EQU 0xFFFFF014 			;desactivar IRQs (solo bits 1) 
VICVectAddr0 	EQU 0xFFFFF100 			;vector interrupciones (VI) 
VICVectAddr 	EQU 0xFFFFF030 			;registro para EOI 

T0_IR 			EQU 0xE0004000 			;reg. para bajar peticiones IRQ4 
MAX_TICS 		EQU 10 					;cent. seg. para decr. contador 
timer_so 		DCD 0 					;var. para @RSI_timer_SO 
contador 		DCD 100 				;decimas de seg. que faltan 
	
RDAT			EQU	0xE0010000			;reg. datos teclado UART1
IOSET			EQU	0xE0028004			;reg. datos GPIO (activar bits)
IOCLR			EQU	0xE002800C			;reg. datos GPIO (desactivar bits)
tecl_so			DCD	0
	
dirInicio		EQU 0x40007E20
dirFin			EQU	0x40007FFF
dirRotulo		EQU	0x40007EE3			;dir. rótulo ganar || dir. rótulo gameover
dirVidas		DCD	0x40007E08
dirPuntos		DCD	0x40007E1C

dir_coche		DCD	0x40007FEC			;dirección de inicio del coche
velo			DCD	8					;var. que controla el movimiento del coche, un movimiento cada 0.08 segundos
vidas			DCD 3					;var. que cuenta las vidas que le quedan al coche
puntosDec		DCD 0					;var. que cuenta el numero de decenas de monedas que ha cogido el coche
puntosUni		DCD	0					;var. que cuenta el numero de unidades de monedas que ha cogido el coche
tmoneda			DCD 0					;var. que indica el tiempo que tiene que pasar hasta crear la proxima moneda
reloj			DCD 0 					;contador de centesimas de segundo 
max 			DCD 8					;velocidad de movimiento (en centesimas s.) 
cont 			DCD 0 					;instante siguiente movimiento 
dirx 			DCD 0 					;direccion mov. caracter ‘H’ (-1 izda.,0 stop,1 der.) 
diry 			DCD 0 					;direccion mov. caracter ‘H’ (-1 arriba,0 stop,1 abajo) 
fin 			DCB 0 					;indicador fin de programa (si vale 1) 
pulsado			DCB 0					;indicador si se ha pulsado la tecla de inicio

vecRoad			SPACE	15				;reservo espacio para colocar las posiciones de los # de la carretera
vecCoin			SPACE	15				;reservo espacio para colocar las posiciones de las monedas

finGanar		DCB 0					;indicador fin por ganar (si vale 1)
marcador		DCB " Vidas:             Puntos:"
fraseini		DCB	"Press (S) to start the game."
frasefin		DCB	"        GAME OVER        "
fraseganar		DCB "¡ENHORABUENA! HAS GANADO "


				AREA codigo,CODE
				EXPORT inicio			; forma de enlazar con el startup.s
				IMPORT srand			; para poder invocar SBR srand
				IMPORT rand				; para poder invocar SBR rand
inicio	
		;programar RSI_IRQ4 -> RSI_reloj 
				LDR		r0,=VICVectAddr0		;r0=@VI
				LDR		r1,=timer_so			;r1=timer_so
				mov 	r2,#4					;r2=4
				ldr		r3,[r0,r2,LSL #2]		;r3=VI[r2]=@RSI_timer_SO
				str 	r3,[r1]					;reloj_so=@RSI_timer_SO
				
				LDR 	r1,=RSI_reloj			;r1=@RSI_reloj (la RSI)
				str 	r1,[r0,r2,LSL #2]		;VI[r2]=@RSI_reloj (la RSI)
		
		;programar RSI_IRQ7 -> RSI_teclado 
				LDR		r0,=VICVectAddr0		;r0=@VI
				LDR		r1,=tecl_so				;r1=@tecl_so
				mov		r2,#7					;r2=7
				ldr		r3,[r0,r2,LSL #2]		;r3=VI[7]=@RSI_tecl_SO
				str 	r3,[r1]					;tecl_so=@RSI_tecl_SO

				LDR 	r1,=RSI_teclado			;r1=@RSI_teclado mia
				str 	r1,[r0,r2,LSL #2]		;VI[7]=@RSI_teclado mia
		
		;activar IRQ4,IRQ7 
				LDR		r0,=VICIntEnable		;r0=@VICIntEnable
				mov		r1,#2_10010000			;r1=#2_10010000
				str		r1,[r0]					;VICIntEnable[4,7]=1	(habilit. IRQ4 e IRQ7)

;-----------------------------------------------------------------------------------------------------------
;					PANTALLA CON RÓTULO INICIAL
;-----------------------------------------------------------------------------------------------------------
				LDR		r0,=0x40007E00			;guardo en r0 @primer elemento
				LDR		r1,=0x40007FFF			;guardo en r1 @último elemento
				LDR		r2,=0x40007EE1			;guardo en r0 @frase de la pantalla inicial
				LDR		r3,=fraseini			;r1=@fraseinicial
				eor		r5,r5,r5				;limpiamos registro r5 (contador)
				
compruebo		cmp		r0,r2					;comparo r0 con r3
				bne		blanquito

cartelito		ldrb	r4,[r3]					;r4=dato de @fraseinicial
				strb	r4,[r0]					;cargamos r2 en r0 (mostramos por pantalla las letras)
				add		r0,r0,#1				;r0=r0+1	->	muevo una posición
				cmp		r5,#27					;comparo r6 (contador) con 27				
				beq		blanquito				;si son iguales salto a blanquito
				add		r3,r3,#1				;si no r3=r3+1
				add		r5,r5,#1				;r5=r5+1
				b		cartelito				;salto incondicional a cartelito para imprimir el resto del msj

blanquito		mov		r4,#' '					;r2=' ' (espacio)
				strb	r4,[r0]					;imprimo el espacio en la pantalla
				add		r0,r0,#1				;r0=r0+1
				
fin_pantinicio	cmp		r0,r1
				bls		compruebo
				
		;Comprobar si se ha pulsado la tecla para iniciar el juego.
tecla			LDR		r2,=pulsado				;r2=@pulsado
				ldrb	r2,[r2]					;r2=dato de @pulsado
				cmp		r2,#0					;comparo r2 con 0
				beq		tecla					;si son iguales sigue comprobando si hemos pulsado 
												;la tecla necesaria para iniciar el juego.

;-----------------------------------------------------------------------------------------------------------
;					CABECERA Y PANTALLA INICIAL DEL PROGRAMA
;-----------------------------------------------------------------------------------------------------------
pantallainicial	LDR		r0,=0x40007E00			;guardo en r0 @primerelemento
				LDR		r1,=marcador			;r1=@marcador
				ldrb	r2,[r1]					;r2=dato de @marcador
				eor		r3,r3,r3				;limpio registro r3 (contador)

			;Mostrar cabecera 'Vidas:       Puntos:'
bucMarcador		ldrb	r2,[r1],#1				;r2=dato de @marcador
				strb	r2,[r0],#1				;mostro el vector marcador desde la @ inicial de la pantalla
				add		r3,r3,#1				;r3=r3+1 (contador++)
				cmp		r3,#27					;comparo r3 (cont) con 27
				bne		bucMarcador				;si r3!=27, salto a bucMarcador
				
			;Mostrar número de vidas restantes.
nVidas			LDR		r3,=dirVidas			;r3=@dirVidas
				ldr		r3,[r3]					;r3=dato de @dirVidas
				LDR		r2,=vidas				;r2=@vidas
				ldr		r2,[r2]					;r2=dato de @vidas
				add		r2,r2,#48				;paso las vidas a ascii
				strb	r2,[r3]					;escribo en dirVidas las vidas que le quedan al jugador

			;Pongo la pantalla en blanco.
				LDR		r0,=dirInicio			;guardo en r0 @primer elemento
				LDR		r1,=dirFin				;guardo en r1 @último elemento
				mov		r2,#' '					;r2=' ' (espacio)
blanco			cmp		r0,r1					;comparo r0 con r1
				bhi		carretera				;si r0=r1 (@actual=@final), salto a carretera
				strb	r2,[r0]					;imprimo el espacio en la pantalla
				add		r0,r0,#1				;r0=r0+1
				b		blanco					;salto incondicional a blanco

			;Dibujo la carretera en la pantalla.
carretera		LDR		r0,=dirInicio			;r0=@dirInicio
				mov		r2,#'#'					;r2=#
bucRoad			strb	r2,[r0,#8]				;muestro en @dirInicio+8 '#'
				strb	r2,[r0,#16]				;muestro en @dirInicio+16 '#'
				add		r0,r0,#32				;avanzo una fila
				cmp		r0,r1					;comparo r2(@dirInicio) y r3(@dirFin)
				blt		bucRoad					;si r2<r3, salto a bucRoad
				
			;Inicio vector de la carretera.
				LDR		r0,=vecRoad				;r0=@vecRoad
				mov		r1,#0					;r1=0
				mov		r2,#8					;r2=8
bucVec			strb	r2,[r0,r1]				;guardo en @vecRoad+r1 el valor de r2
				add		r1,r1,#1				;r1=r1+1
				cmp		r1,#15					;comparo r1 con 15
				bne		bucVec					;si no son iguales, salto a bucVec
				
			;Escribir el coche en su posición inicial.
coche			mov		r1,#'H'					;r1=H
				LDR		r2,=dir_coche			;r2=@dir_coche
				ldr		r2,[r2]					;r2=dato de @dir_coche
				LDR		r0,=dirInicio			;guardo en r0 @primer elemento
				LDR		r3,=dirFin				;guardo en r3 @último elemento
				
bucCoche		cmp		r0,r2					;comparo r0(@elementoactual) con r2(dir_coche)
				bne		seguimos				;si r0!=r2, salto a seguimos
				strb	r1,[r0]					;muestro el coche por pantalla

seguimos		add		r0,r0,#1				;r0=r0+1
				cmp		r0,r3					;comparo la dirección actual con la final
				blt		bucCoche				;si r0<=r3, salto a pantallainicial


;-----------------------------------------------------------------------------------------------------------
;					INICIALIZAR NÚMEROS ALEATORIOS
;-----------------------------------------------------------------------------------------------------------
		;Inicializar semilla srand
				LDR		r0,=velo				;r0=@velo
				ldr		r0,[r0]					;r0=dato de @velo
				PUSH	{r0}					;apilar parámetro
				bl		srand
				add		sp,sp,#4				;quitar parámetro
				
		;Número aleatorio entre 1 y 16 filas para crear primera moneda
				sub 	sp,sp,#4				;espacio para el resultado
				bl 		rand
				POP 	{r0}					;r0 = numRand1
				mov		r1,#15					;r1=15
				and		r0,r0,r1				;r0=0..15
				add		r0,r0,#1				;r0=1..16
				LDR		r1,=tmoneda				;r1=@tmoneda
				str		r0,[r1]					;guardo en r1 lo que hay en r0

;-----------------------------------------------------------------------------------------------------------
;						EMPIEZA EL BUCLE
;-----------------------------------------------------------------------------------------------------------
bucle		;Comprobar fin
				LDR		r0,=fin					;r0=@fin
				ldrb	r1,[r0]					;r1=dato de @fin
				cmp		r1,#1					;comparo r1 con 1
				beq		rotuloFin				;si fin=1, salto a pant_final
				
			;Comprobar ganar
				LDR		r0,=finGanar			;r0=@finGanar
				ldrb	r1,[r0]					;r1=dato de @finGanar
				cmp		r1,#1					;comparo r1 con 1
				beq		rotuloGanar				;si fin=1, salto a rotuloGanar
				
			;Actualizar posición coche
			;¿Es necesario mover el coche?
				LDR		r0,=velo				;r0=@velo
				ldr		r1,[r0]					;r1=dato de @velo
				cmp		r1,#8					;comparo r1 con 8
				blo		moveRoad				;si r1<8, salto a moveRoad
				mov		r1,#0					;r1=0
				str		r1,[r0]					;guardo en r0 el valor de r1 (pongo @velo a 0)
			
			;Compruebo si tengo que mover en el eje X.
comprDirX		LDR		r0,=dirx				;r0=@dirx
				ldr		r0,[r0]					;r0=dato de @dirx
				cmp		r0,#0					;comparo r0 con 0
				beq		comprDirY				;si son iguales, salto a comprDirY
				bl		moveCar					;llamo a SBR moveCar
				
			;Compruebo si tengo que mover en el eje Y.
comprDirY		LDR		r0,=diry				;r0=@diry
				ldr		r0,[r0]					;r0=dato de @diry
				cmp		r0,#0					;comparo r0 con 0
				beq		moveRoad				;si son iguales, salto a moveRoad
				bl		moveCar					;llamo a SBR moveCar
				
			;mover cada <max> tiempo la carretera.
moveRoad		LDR		r0,=reloj				;r0=@reloj
				ldr		r1,[r0]					;r1=dato de @reloj
				LDR		r2,=max					;r2=@max
				ldr		r2,[r2]					;r2=dato de @max
				cmp		r1,r2					;comparo reloj y max			
				blo		bucle					;salta si reloj!=max
				mov		r1,#0					;ponemos reloj a 0
				str		r1,[r0]					;actualizo el valor de reloj
				bl		moverCarretera			;llamo a SBR moverCarretera
				b 		bucle					;salto incondicional a bucle


;-----------------------------------------------------------------------------------------------------------
;					PANTALLA CON DIFERENTES RÓTULOS FINALES
;-----------------------------------------------------------------------------------------------------------
			;Escribo la frase "GAME OVER"
rotuloFin		LDR		r3,=frasefin			;r3=@frasefin
				b		escribirFinal
				
			;Escribo la frase "¡ENHORABUENA! HAS GANADO"
rotuloGanar		LDR		r3,=fraseganar			;r3=@fraseganar

			;Escribir la frase correspondiente
escribirFinal	LDR		r0,=0x40007E00			;guardo en r0 @primer elemento
				LDR		r1,=0x40007FFF			;guardo en r1 @último elemento
				LDR		r2,=dirRotulo			;guardo en r2 @frase de la pantalla final
				eor		r5,r5,r5				;limpiamos registro r5 (contador)
				
comprobarF		cmp		r0,r2					;comparo r0 con r2
				bne		blancoF					;si r0!=r2,salto a blancoF

cartelfin		ldrb	r4,[r3]					;r4=dato de @frasefin
				strb	r4,[r0]					;cargamos r2 en r0 (mostramos por pantalla las letras)
				add		r0,r0,#1				;r0=r0+1	->	muevo una posición
				cmp		r5,#24					;comparo r5(contador) con 9				
				beq		blancoF					;si son iguales salto a blancoF
				add		r3,r3,#1				;si no r3=r3+1
				add		r5,r5,#1				;r5=r5+1
				b		cartelfin				;salto incondicional a cartelfin para imprimir el resto del msj

blancoF			mov		r4,#' '					;r2=' ' (espacio)
				strb	r4,[r0]					;imprimo el espacio en la pantalla
				add		r0,r0,#1				;r0=r0+1
				
fin_pantfin		cmp		r0,r1
				bls		comprobarF
		

;=======================DESACTIVAMOS IRQ4, IRQ7, RSI_reloj Y RSI_teclado====================================
finBucle	;desactivar IRQ4,IRQ7
				LDR 	r0,=VICIntEnClr			;r0=@VICIntEnClr
				mov 	r1,#2_10010000			;r1=#2_10010000
				str 	r1,[r0]					;VICIntEnClr[4,7]=1 -> VICIntEnable[4]=0
												
			;desactivar RSI_reloj
				LDR 	r0,=VICVectAddr0		;r0=@VI
				LDR 	r1,=timer_so			;r1=@timer_so
				ldr 	r1,[r1]					;r1=timer_so=@RSI_timer_SO
				mov 	r2,#4					;r2=4
				str 	r1,[r0,r2,LSL #2]		;VI[4]=@RSI_reloj_SO
				
			;desactivar RSI_teclado
				LDR		r0,=VICVectAddr0		;r0=@VI
				LDR		r1,=tecl_so				;r1=tecl_so
				ldr 	r1,[r1]					;r1=tec_so=@tecl_SO
				mov		r2,#7					;r2=7
				str		r1,[r0,r2,LSL #2]		;VI[4]=@RSI_tecl_SO

bfin 			b 	bfin 



;-----------------------------------------------------------------------------------------------------------
;						SBR SUMAR MONEDAS.
;-----------------------------------------------------------------------------------------------------------
sumaMoneda		PUSH	{lr,r11}
				mov		fp,sp
				PUSH	{r0-r4}
				
				LDR 	r0,=dirPuntos			;r0=@dirPuntos
				ldr		r0,[r0]					;r0=direccion de los puntos en la pantalla
				LDR		r1,=puntosUni			;r1=@puntosUni
				LDR		r3,=puntosDec			;r3=@puntosDec
				ldr		r2,[r1]					;r2=unidades de puntos
				ldr		r4,[r3]					;r4=decenas de puntos
				add		r4,r4,r2				;r4=r4+r2
				cmp		r4,#18					;comparo r4 con 18
				blt		seguira					;si no son iguales, significa que no ha llegado a 99
				
				LDR		r0,=finGanar			;r0=@finGanar
				mov		r1,#1					;r1=1
				strb	r1,[r0]					;Guardo r1(1) en r0(@finGanar) [pongo finGanar a 1]
				b		finSuma
				
			;Si no ha llegado a 99 puntos, sigo sumando unidades/decenas.
seguira			cmp		r2,#9					;si ya hay 9 unidades no podemos sumar mas
				moveq	r2,#0					;si r2=9 -> r2=0
				addne	r2,r2,#1				;si r2!=9 -> r2=r2+1
				str		r2,[r1]					;guardo las nuevas unidades				
				add		r2,r2,#48				;paso las unidades a ascii
				strb	r2,[r0,#1]
				bne		finSuma					;si había menos de 9 unidades ya he acabado
				ldr		r2,[r3]					;r2=decenas de puntos
				cmp		r2,#9					;si ya hay 9 decenas no podemos sumar mas
				beq		finSuma
				add		r2,r2,#1				;si r2!=9 -> r2=r2+1
				str		r2,[r3]
				add		r2,r2,#48				;pasamos las decenas a ascii
				strb	r2,[r0]	

finSuma			POP		{r0-r4,fp,pc}


;-----------------------------------------------------------------------------------------------------------
;						SBR PARA MOVER EL COCHE.
;-----------------------------------------------------------------------------------------------------------
moveCar			PUSH	{lr,r11}
				mov		fp,sp
				PUSH	{r0-r3}
				LDR		r0,=dir_coche			;r0=@dir_coche
				ldr		r1,[r0]					;r1=dato de @dir_coche
				
			;Evaluamos el movimiento en el eje X.
moverX			LDR		r2,=dirx				;r2=@dirx
				ldr		r3,[r2]					;r3=dato de @dirx
				cmp		r3,#0					;compruebo si r3=0
				beq		moverY					;salto a moverY para comprobar si tengo q mover en ese eje
				cmp		r3,#-1					;compruebo si r3=-1
				subeq	r1,r1,#1				;si r3==-1, muevo hacia la izda
				cmp		r3,#1					;compruebo si r3=1
				addeq	r1,r1,#1				;si r3==1, muevo hacia la dcha
				mov		r3,#0					;r3=dirx=0
				str		r3,[r2]					;actualizo valor dirx
				b		muevo

			;Evaluamos el movimiento en el eje Y.
moverY			LDR		r2,=diry				;r2=@dirx
				ldr		r3,[r2]					;r3=dato de @dirx
				cmp		r3,#0					;compruebo si r3=0
				beq		finMoneda				;salto a moverY para comprobar si tengo q mover en ese eje
				cmp		r3,#-1					;compruebo si r3=-1
				subeq	r1,r1,#32				;si r3==-1, muevo hacia arriba
				cmp		r3,#1					;compruebo si r3=1
				addeq	r1,r1,#32				;si r3==1, muevo hacia abajo
				mov		r3,#0					;r3=diry=0
				str		r3,[r2]					;actualizo valor diry
				
			;realizo el movimiento del coche
muevo			mov		r2,#' '					;r2=' '
				ldr		r3,[r0]					;r3 guarda la @anterior del coche
				strb	r2,[r3]					;limpio la antigua posición del coche
				
			;compruebo derecha y abajo.
				LDR		r2,=0x40007FFF
				cmp		r1,r2
				bhi		quitarVida
			;compruebo izquierda y arriba
				LDR		r2,=0x40007E20
				cmp		r1,r2
				blo		quitarVida
				
			;compruebo que la siguiente posición está en blanco
				mov		r2,#'#'					;r2=#
				ldrb	r3,[r1]					;guardo en r3 				
				cmp		r3,r2					;comparo r3 con r2
				beq		quitarVida				;si son iguales, salto a quitarVida
				
escribo			str		r1,[r0]					;guardo la nueva posición del coche en la pantalla
				mov		r2,#'H'					;r2=H
				strb	r2,[r1]					;escribo 'H' en la nueva posición del coche
				b		finMoneda

			;PIERDO UNA VIDA
quitarVida		LDR		r0,=vidas				;r0=@vidas
				ldr		r1,[r0]					;r1=dato de @vidas
				sub		r1,r1,#1				;r1=r1-1
				str		r1,[r0]					;guardamos el nuevo valor de vidas
				LDR		r2,=dirVidas			;r2=@dirVidas
				ldr		r2,[r2]					;r2=dato de @dirVidas
				add		r3,r1,#48				;r3=vidas+48		[paso a ascii]
				strb	r3,[r2]					;muestro en pantalla el n de vidas
				cmp		r1,#0					;comparo vidas con 0
				bne		nomesalgo				;si no es cero, salto a nomesalgo	

			;No me quedan mas vidas acaba el juego
				LDR		r0,=fin					;r0=@fin
				mov		r1,#1					;r1=1
				strb	r1,[r0]					;guardo el 1 en fin (acaba el programa)
				b		finMover		

			;Pierdo una vida y vuelvo a la posicion inicial, en el centro de la ultima fila
nomesalgo		LDR		r3,=dir_coche			;r3=@dir_coche
				LDR		r0,=vecRoad				;r0=@vecRoad
				ldrb	r0,[r0,#14]				;r0=@vecRoad+14
				add		r0,r0,#4				;r0=r0+4
				LDR		r1,=0x40007FE0			
				add		r1,r1,r0
				str		r1,[r3]
				mov		r2,#'H'					;r2=H
				strb	r2,[r1]					;guardo H en r1

finMoneda	;Compruebo si el coche ha cogido una moneda
				LDR		r0,=dir_coche
				ldr		r0,[r0]
				LDR		r1,=0x1FF				;bits no comunes a todas las direcciones de la pantalla
				and		r2,r0,r1				;r2=bits que definen la posicion en pantalla
				mov		r1,r2,LSR#5				;r1=numero de fila del coche
				sub		r1,r1,#1				;r1=ind. fila en vecCoin
				LDR		r2,=0x1F				;bits no comunes entre las columnas de una fila
				and		r0,r0,r2				;r0=numero de columna del coche
				LDR		r2,=vecCoin
				ldrb	r3,[r2,r1]				;r3=num. de vecCoin de la fila donde esta el coche
				cmp		r3,r0					;compruebo si el coche y la moneda estan en la misma columna
				bne		finMover				
				bl		sumaMoneda
				mov		r3,#0
				strb	r3,[r2,r1]				;actualizo a 0 la posicion de la moneda

finMover		POP		{r0-r3,fp,pc}
				

;-----------------------------------------------------------------------------------------------------------
;						MOVER LA CARRETERA.
;-----------------------------------------------------------------------------------------------------------
moverCarretera	PUSH	{lr,r11}
				mov		fp,sp
				PUSH	{r0-r8}
				
			;Mover toda la pantalla excepto una fila hacia abajo
				LDR 	r0,=0x40007FE0
				LDR 	r1,=vecRoad
				LDR		r7,=vecCoin
				mov		r4,#' '					;r4=' '
				mov		r5,#'#'					;r5=#
				mov		r6,#'o'					;r6=o
				mov 	r2,#14					;r2 = última fila
			
			;MOVEMOS TODAS LAS FILAS DE LA PANTALLA UNA POSICION
			;Quitamos los caracteres de la fila
bucCar			ldrb	r3,[r1,r2]				;r3 = posicion lado izquierdo de la carretera
				strb	r4,[r0,r3]				;ponemos un espacio en blanco donde antes estaba la carretera
				add		r3,r3,#8				;r3 = r3 + 8 (posicion lado izquierdo de la carretera)
				strb	r4,[r0,r3]				;ponemos un espacio en blanco donde antes estaba la carretera
				ldrb	r3,[r7,r2]				;r3=posicion de la moneda
				cmp		r3,#0
				beq		noQuitarCoin			;r3=0 -> no hay moneda en esa fila
				strb	r4,[r0,r3]				;ponemos un espacio donde estaba la moneda
			
			;Ponemos los nuevos valores, los de la fila superior
noQuitarCoin	mov		r8,r2					;r8=indice de la fila actual
				sub		r2,r2,#1				;r2=indice de la fila superior
				ldrb	r3,[r1,r2]				;r3 = pos. fila superior # izq.
				strb	r3,[r1,r8]				;guardamos en vecRoad la posicion del # superior
				strb	r5,[r0,r3]				;ponemos # donde esta el margen derecho en la fila superior
				add		r3,r3,#8
				strb	r5,[r0,r3]				;ponemos # donde esta el margen izquierdo en la fila superior
				ldrb	r3,[r7,r2]				;r3=posicion de la moneda de la fila superior
				strb	r3,[r7,r8]				;guardamos en vecCoin la pos. de la moneda de la fila superior
				cmp		r3,#0
				beq		noMoney					;r3=0 -> no hay moneda
				strb	r6,[r0,r3]				;colocamos la moneda en la pantalla
				
			;Comprobamos si el coche ha cogido una moneda
				add		r8,r0,r3				;r8=(pos. 0 de la fila + pos.moneda en la fila = pos.moneda en la pantalla)
				LDR		r3,=dir_coche
				ldr		r3,[r3]					;r3=direccion del coche
				cmp		r8,r3					;la moneda coincide con el coche
				bne		noMoney
				mov		r3,#'H'
				strb	r3,[r8]					;volvemos a colocar el coche
				mov		r3,#0
				add		r8,r2,#1
				strb	r3,[r7,r8]				;colocamos un 0 en vecCoin
				bl		sumaMoneda				;añadimos un punto
				
noMoney			sub		r0,r0,#32				;r0=0x40007FE0, 0x40007FC0, 0x40007FA0, ..., 0x40007E20
				cmp		r2,#0
				bne		bucCar					

			; Valor aleatorio 1 (Si numRand=0 -> se mueve a la izquierda, 
			;						numRand=1 -> se queda quieta, 
			;						numRand=2 -> se mueve a la drch, 
			;						numRand=3 -> coge el bit0 de posCoche, si bit0=0 -> mueve a la izq, bit0=1 -> mueve  a la drch)
			
			;NÚMEROS ALEATORIOS PARA CREAR LA SIGUIENTE FILA
				sub 	sp,sp,#4				;espacio para el resultado
				bl 		rand
				POP 	{r0}					;r0=numRand1		
				mov 	r1,#3					;r1=máscara 0..011
				and 	r0,r0,r1				;r0=numRand = 000...[1,0]bit de numRand
				
				cmp		r0,#0					;si r0=0
				beq		movIzq					;se mueve a la izquierda
				cmp		r0,#1					;si r0=2
				beq		movDer					;se mueve a la derecha
				LDR 	r0, =dir_coche
				ldr		r0, [r0]				;r0=reloj
				and 	r0, r0, #1				;r0=bit0
				cmp		r0,#0					;si r0=0
				beq		movIzq					;se mueve a la izquierda
				cmp		r0,#1					;si r0=1
				beq		movDer					;se mueve a la derecha
				
movIzq			LDR 	r0,=0x40007E20
				LDR		r1,=vecRoad
				ldrb	r3,[r1]					;r3=vecRoad[0]
				cmp		r3,#0					;si vecRoad[0]=0, no se puede mover a la izquierda
				beq		ponerMoney
				strb	r4,[r0,r3]				;ponemos un espacio en el margen izquierdo
				add		r7,r3,#8
				strb	r4,[r0,r7]				;ponemos un espacio en el margen derecho
				sub		r3,r3,#1				;r3 = vecRoad[0]-1
				strb	r3,[r1]					;vecRoad[0] = vecRoad[0]-1
				strb	r5,[r0,r3]				;ponemos # en el nuevo margen izquierdo
				add		r7,r3,#8
				strb	r5,[r0,r7]				;ponemos # en el nuevo margen derecho
				LDR		r1,=vecCoin
				ldrb	r2,[r1]					
				cmp		r2,#0					;r2=0 no hay moneda
				beq     ponerMoney
				strb	r4,[r0,r2]				;si hay moneda la quitamos
				mov		r2,#0
				strb	r2,[r1]					;actualizamos valor de vecCoin a 0
				b		ponerMoney
				
movDer			LDR 	r0,=0x40007E20
				LDR		r1,=vecRoad
				ldrb	r3,[r1]					;r3=vecRoad[0]
				add		r7,r3,#8
				cmp		r7,#30					;si vecRoad[0]=0, no se puede mover a la derecha
				bhi		ponerMoney
				strb	r4,[r0,r3]				;ponemos un espacio en el margen izquierdo
				add		r7,r3,#8
				strb	r4,[r0,r7]				;ponemos un espacio en el margen derecho
				add		r3,r3,#1				;r3=vecRoad[0]-1
				strb	r3,[r1]					;vecRoad[0]=vecRoad[0]-1
				strb	r5,[r0,r3]				;ponemos # en el nuevo margen izquierdo
				add		r7,r3,#8
				strb	r5,[r0,r7]				;ponemos # en el nuevo margen derecho
				LDR		r1,=vecCoin
				ldrb	r2,[r1]
				cmp		r2,#0					;r2=0 no hay moneda
				beq     ponerMoney				
				strb	r4,[r0,r2]				;si hay moneda la quitamos
				mov		r2,#0
				strb	r2,[r1]					;actualizamos valor de vecCoin a 0
				
			;Comprobamos si colocamos moneda
ponerMoney		LDR		r0,=tmoneda
				ldr		r1,[r0]					;r1=tmoneda, numero de filas hasta la siguiente moneda
				cmp		r1,#0
				sub		r1,r1,#1				;tmoneda--
				str		r1,[r0]
				bhi		finError				;tmoneda!=0 -> no ponemos moneda
			;Llamamos a la subrutina rand para determinar el siguiente valor de tmoneda
				sub		sp,sp,#4
				bl		rand
				POP		{r1}					;r1=num.aleatorio
				mov		r2,#15					;r2=15
				and		r1,r1,r2				;r1=num aletaorio entre 0 y 15
				add		r1,r1,#1				;r1=num aletaorio entre 1 y 16
				str		r1,[r0]					;tmoneda = [1,...,16]				
			;Colocamos moneda
				LDR 	r0,=0x40007E20
				LDR 	r1,=vecRoad
				LDR		r2,=vecCoin
			;Llamamos a la subrutina rand para determinar el valor de la columna de la moneda
				sub		sp,sp,#4
				bl		rand					
				POP		{r3}					;r3=num.aleatorio
				mov		r4,#7					;r4=7
				and		r3,r3,r4				;r3=[0,..,7]
				cmp		r3,#0					;si r3=0 no ponemos moneda
				beq		noCoin
				ldrb	r4,[r1]					;r4=indice # izq
				add		r3,r3,r4				;r3=ind.#izq + num.aleatorio entre 1 y 7, es la pos.moneda en la fila
				mov		r4,#'o'
				strb	r4,[r0,r3]				;colocamos la moneda
			;Comprobamos si la moneda coincide con el coche
				add		r0,r0,r3				;r0=pos.moneda en la pantalla
				LDR		r1,=dir_coche
				ldr		r1,[r1]					;r1=pos.coche
				cmp		r0,r1					;la moneda coincide con el coche
				bne		noCoin
				mov		r1,#'H'					;la moneda coincide con el coche
				bl		sumaMoneda				;añadimos un punto
				strb	r1,[r0]					;colocamos el coche
				mov		r3,#0					
noCoin			strb	r3,[r2]					;actualizamos el valor de vecCoin

			;Comprobamos si el coche se ha salido de los limites de la carretera
finError		LDR		r4,=dir_coche
				ldr		r1,[r4]					;r1=pos.coche
				ldrb	r1,[r1]					;r1=caracter de la posicion del coche
				cmp		r1,r5					;r1=# -> el coche ha chocado
				bne		finRoad
				LDR		r0,=vidas				;r0=@vidas
				ldr		r1,[r0]					;r1=dato de @vidas
				sub		r1,r1,#1				;r1=r1-1
				str		r1,[r0]					;guardamos el nuevo valor de vidas
				LDR		r2,=dirVidas			;r2=@dirVidas
				ldr		r2,[r2]					;r2=dato de @dirVidas
				add		r3,r1,#48				;r3=vidas+48		[paso a ascii]
				strb	r3,[r2]					;muestro en pantalla el n de vidas
				cmp		r1,#0
				bhi		continuo
			;No me quedan mas vidas y acaba el juego	
				LDR		r0,=fin
				mov		r1,#1
				strb	r1,[r0]
				b		finRoad
			;Me quedan mas vidas y coloco el coche en la pos. inicial	
continuo		LDR		r0,=vecRoad
				ldrb	r0,[r0,#14]				;r0=pos.# izq. en la ultima fila
				add		r0,r0,#4				;r0=pos.centro en ultima fila 
				LDR		r1,=0x40007FE0			;r1=valor ultima fila
				add		r1,r1,r0				;r1=pos. centro de ultima fila en la pantalla
				str		r1,[r4]					;actualizo la posicion del coche
				mov		r2,#'H'
				strb	r2,[r1]					;coloco el coche

finRoad			POP {r0-r8, r11, pc}


;-----------------------------------------------------------------------------------------------------------
;						RUTINA DE SERVICIO DEL TIMER
;-----------------------------------------------------------------------------------------------------------
RSI_reloj 										;Rutina de servicio a la interrupcion IRQ4 (timer 0) 
												;Cada 0,01 s. llega una peticion de interrupcion 
		;Prólogo	---	  I=0	---	   Activar IRQS
				sub		lr,lr,#4				;correccion @ret. (segmentado)
				PUSH	{lr}					;apilar @retorno (pila modo IRQ)
				mrs		r14,spsr				;r14_irq = cpsr prog. interrumpido
				PUSH	{r14}					;apilar estado prog. interr.
				msr		cpsr_c,#2_01010010		;I=0 -> activar IRQs (modo IRQ)
				
				PUSH	{r0-r2}					;apilar regs a utilizar
		;control (bajar pet. IRQ4)
				LDR		r0,=T0_IR				;r0=@T0_IR
				mov		r1,#1					;r1=1
				str		r1,[r0]					;escribir 1 en T0_IR para bajar petición HW IRQ[4]	

		;aumentar reloj
				LDR		r0,=reloj				;r0=@reloj
				ldr		r1,[r0]					;r1=reloj
				add		r1,r1,#1				;r1=reloj++
				str		r1,[r0]					;@reloj=reloj++
				LDR		r0,=velo				;r0=@velo
				ldr		r1,[r0]					;r1=velo
				add		r1,r1,#1				;r1=velo++
				str		r1,[r0]					;@velo=velo++
				
fintimer		POP		{r0-r2}					;desapilar registros utilizados
		;Epílogo --- preparar ret. + EOI + retorno.
				msr		cpsr_c,#2_11010010		;I=1 -> desactivar interr. IRQ
				POP		{r14}					;r14=cpsr prog. interrumpido
				msr		spsr_fsxc,r14			;spsr = cpsr prog. interrumpido
				LDR		r14,=VICVectAddr		;EOI r14=@VICVectAddr
				str		r14,[r14]				;EOI escritura en VICVectAddr
				POP		{pc}^					;ret. a prog inter. + rec. estado


;-----------------------------------------------------------------------------------------------------------
;						RUTINA DE SERVICIO DEL TECLADO 
;-----------------------------------------------------------------------------------------------------------
RSI_teclado 									;Rutina de servicio a la interrupcion IRQ7 (teclado) 
												;al pulsar cada tecla llega peticion de interrupcion IRQ7
				sub		lr,lr,#4				;correccion @ret. (segmentado)
				PUSH	{lr}					;apilar @retorno (en pila IRQ) 
				mrs 	r14,spsr 				;r14_irq=cpsr prog. interrumpido
				PUSH 	{r14} 					;apilar estado prog. interr. 
				msr		cpsr_c,#2_01010010		;I=0 -> activar IRQs (modo IRQ) 
				
				PUSH	{r0-r2}					;apilar registros a utilizar
				
				LDR		r1,=RDAT 				;r1=@RDAT teclado
				ldrb	r0,[r1] 				;r0=codigo ASCII tecla 

			;Aumentar velocidad carretera
mas				cmp		r0,#'+'					;comparo la tecla pulsada con '+'
				bne		menos					;si r0 no es +, salto a menos
				LDR		r1,=max					;r1=@max	[velocidad de carretera]
				ldr		r0,[r1]					;r2=dato de max
				cmp		r0,#1					;comparo r0 con 1
				bls		fintec					;si r0<8, salto a fintec
				sub		r0,r0,#1				;bajo la tasa de movimiento -> mas rapido
				str		r0,[r1]					;guardo el nuevo valor de max
				b		fintec					;salto incondicional a fintec

			;Disminuir velocidad carretera
menos			cmp		r0,#'-'					;comparo la tecla pulsada con '-'
				bne		mayus					;si r0 no es -,salto a mayus
				LDR		r1,=max					;r1=@max	[velocidad de carretera]
				ldr		r0,[r1]					;r2=dato de max
				cmp		r0,#128					;comparo r0 con 128
				bge		fintec					;si r0>128, salto a fintec
				add		r0,r0,#1				;aumento la tasa de velocidad -> mas lento
				str		r0,[r1]					;guardo el nuevo valor de max
				b		fintec					;salto incondicional a fintec
				
mayus			bic		r0,r0,#2_100000			;paso a MAYUSCULAS
			
			;Iniciar partida
S_inicio		cmp		r0,#'S'					;comparo la tecla pulsada con 'S'
				bne		J_izq					;
				mov		r0,#1					;
				LDR		r1,=pulsado				;r1=@pulsado
				strb	r0,[r1]					;actualizo el valor de pulsado
				b		fintec					;salto incondicional a fintec

			;Mover hacia izquierda
J_izq			cmp		r0,#'J'					;comparo la tecla pulsada con 'J'
				bne		L_dcha					;
				mov		r0,#-1					;
				LDR		r1,=dirx				;
				str		r0,[r1]					;
				b		fintec					;salto incondicional a fintec

			;Mover hacia derecha
L_dcha			cmp		r0,#'L'					;comparo la tecla pulsada con 'L'
				bne		I_arriba				;
				mov		r0,#1					;
				LDR		r1,=dirx				;
				str		r0,[r1]					;
				b		fintec					;salto incondicional a fintec

			;Mover hacia arriba
I_arriba		cmp		r0,#'I'					;comparo la tecla pulsada con 'I'
				bne		K_abajo					;
				mov		r0,#-1					;
				LDR		r1,=diry				;
				str		r0,[r1]					;
				b		fintec					;salto incondicional a fintec

			;Mover hacia abajo
K_abajo			cmp		r0,#'K'					;comparo la tecla pulsada con 'K'
				bne		Q_fin					;
				mov		r0,#1					;
				LDR		r1,=diry				;
				str		r0,[r1]					;
				b		fintec					;salto incondicional a fintec

			;Finalizar partida
Q_fin			cmp		r0,#'Q'					;miro si la tecla pulsada corresponde a la letra 'Q'
				bne		fintec					;si no se ha pulsado ninguna tecla relevante (not S,J,L,I,K,+,-) salta a fintec
				mov 	r0,#1					;r0=1
				ldr 	r1,=fin					;si la tecla apretada es Q, entonces guarda @fin en r0
				strb 	r0,[r1]					;Guardo r1(1) en r0(@fin) [pongo fin a 1]
				
fintec			POP		{r0-r2}
				msr 	cpsr_c,#2_11010010 
				POP 	{r14} 
				msr 	spsr_fsxc,r14 
				LDR 	r14,=VICVectAddr 
				str 	r14,[r14] 
				POP		{pc}^
				
		END
