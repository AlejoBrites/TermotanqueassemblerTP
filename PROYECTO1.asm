;********************************************************************
;Alumnno: Alejo Brites               DNI:44182530                   * 
; Fecha de entrega:11/11/2022                                       *
;Profesor: Roberto Garcia          PIC16F628A                       *
;El programa simulara la temperatura del agua de un termotanque     *
;donde la minima es de 35°C y la maxima de 70°C, este termotanque   *
;tendre 4 ldes que indicaran que: La resistencia esta apagada,LA 2da*
;que indicara que el agua se esta calentando, la 3ra que el agua    *
;llego a la maxima y la 4ta que el agua desencio a la minima        *
;********************************************************************

;********************************************************************
;                         DATOS                                     *
;********************************************************************

	__CONFIG 3F10
	LIST p=16F628A
    INCLUDE <p16F628A.INC>
	ERRORLEVEL -302

;********************************************************************
;                          DEFINICIONES                             *
;********************************************************************

TEMPMAX EQU 0x20    ;Reservamos memoria para temperatura maxima
TEMPMIN EQU 0x21    ;Reservamos memoria para temperatura minima
TEMPACT EQU 0x22    ;Reservamos memoria para temperatura ambiente
CANILLA EQU 0x23    ;Reservamos memoria para  la canilla
ACUMULADOR1 EQU 0x24  ;Reservamos memoria para  contador1
ACUMULADOR2 EQU 0x25  ;Reservamos memoria para  contador2
ACUMULADOR3 EQU 0x26  ;...
ACUMULADOR4 EQU 0x27  ;...
;********************************************************************

		ORG 0x00

;********************************************************************
;              INICIO DEL PROGRAMA                                  *
;********************************************************************

INICIO

		call CONFIGURAR_PUERTOS   ;configuramos los puertos con sus valores iniciales

		movlw d'30'
		movwf TEMPMIN  ;le damos el valor a la temperatura minima con los mov
		movlw d'70'
		movwf TEMPMAX  ;le damos el valor a la temperatura maxima con los mov
		movlw d'20'
		movwf TEMPACT  ;le damos el valor a la temperatura actual con los mov
        COMF CANILLA,F   ;podemos con CLRF dejamos la canilla en 0, es decir "cerrada"
        ;podemos cambiar el "CLRF" POR "COMF" para abrir la canilla Y QUE VAYA VARIANDO
		clrw    ;Dejo en 0 el registro w ( por las dudas ) 

		CALL CALIENTOELAGUA  ;LLAMO a la subrutina para empezar el procedimiento de calentar agua 
		
		CALL RETARDO_DE1S     ;llamo a 4 retardos de 1seg, para generar
		CALL RETARDO_DE1S     ;un retanro de 4 segundo entre los calls
		CALL RETARDO_DE1S
		CALL RETARDO_DE1S
		CALL RETARDO_DE1S
		
		;¡¡¡COMENTARIOIMPORTANTE !!!
        ;SI LA TEMPERATURA ACTUAL>TEMPERATURA MAXIMA la luz roja se prendera sin hacer la subrutina
		;de CALIENTOELAGUA y pasara a disminuirse
		
		CALL DISMINUIR_TEMP   ; Empezamos el proceso de decrecimiento hasta la temperatura minima

		goto INICIO

;********************************************************************
CONFIGURAR_PUERTOS         ;Aca configuraremos con el trisb el portb

		bsf STATUS,RP0    ;Entramos al banco 1
		movlw b'11110000'  ;cargamos el literal como numero binario
		movwf TRISB        ;y lo movemos al trisb configurando el bit 0,1,2,3 como salida
		bcf STATUS,RP0     ;volvemos al banco 0 
		movlw b'00000000'
		movwf PORTB         ;cargamos el portb
	
		RETURN
;********************************************************************
CALIENTOELAGUA             ;Aca trabajaremos con el calentamiento del agua

        CALL LED_AZUL      ;LLamamos a la luz led de resistencia apagada
		movf TEMPACT,W
		subwf TEMPMAX,W
		btfsc STATUS,C    ;verfico si la tempact>tempmax 
		CALL INCREMENTAR_TEMP ;en caso de ser tempact<tempmax llamo a la subrutina
		
		CALL LED_ROJO		

		RETURN

INCREMENTAR_TEMP

        CALL LED_AMARILLO

		incf TEMPACT,F     ;Incrementa en 1 la temperatura actual

		movf TEMPACT,W      ; movemos el valos de temperatura actual al registro w
		subwf TEMPMAX,W   ; para luego restarlo "tempmax - w(tempact)"

		btfss STATUS,Z        ;verifico si la temperatura actual llego a la maxima 
		goto INCREMENTAR_TEMP	;sino volvemos a hacer el procedimiento para seguir incrementando

		RETURN

;********************************************************************

DISMINUIR_TEMP          ;Aca trabajaremos con el enfriamiento del agua

	   movf TEMPMIN,W   ; nos fijamos que tempact>tempmin 
	   subwf TEMPACT,W ;con la resta TEMPACT-TEMPMIN
	   btfsc STATUS,C  ;verificamos que tempact>tempmin
	   CALL DISMINUIR_TEMP1	;sino llamamos a esta subrutina	

	   CALL LED_VERDE	

	   RETURN


DISMINUIR_TEMP1

       decf TEMPACT,F     

	   btfsc CANILLA,0     ;Si la canilla esta abierta llamara a
	   CALL DISMINUIR_POR_CARNILLA  ; esta funcion, sino la saltara

	   movf TEMPACT,W     ;movemos al w, la tempact
	   subwf TEMPMIN,W    ; restamos la tempact con la tempmin
	   btfss STATUS,Z
	   goto DISMINUIR_TEMP1	 ;Sino llego a la temperatura minima, que siga		

	   RETURN

DISMINUIR_POR_CARNILLA

	   movlw d'4'
	   subwf TEMPACT,F

	   RETURN

;********************************************************************
;                              LEDS                                 *
;********************************************************************

LED_AZUL                 ;Luz de resistencia apaada

		bcf STATUS,RP0
		bsf PORTB,0              ;seteamos en 1 el bit, prendiendo el mismo
        call RETARDO_DE250MS
		call RETARDO_DE250MS
		call RETARDO_DE250MS
		bcf PORTB,0

		RETURN

LED_AMARILLO            ;Luz led del proceso del calentamiento del agua

		bcf STATUS,RP0
		bsf PORTB,1              ;seteamos en 1 el bit, prendiendo el mismo
        call RETARDO_DE250MS
		call RETARDO_DE250MS
		
		bcf PORTB,1

		RETURN

LED_ROJO            ;Luz led que indica que el agua llego a la maxima

		bcf STATUS,RP0
		bsf PORTB,2               ;seteamos en 1 el bit, prendiendo el mismo
        CALL RETARDO_DE1S       ;retardo
		bcf PORTB,2

		RETURN

LED_VERDE

		bcf STATUS,RP0
		bsf PORTB,3               ;seteamos en 1 el bit, prendiendo el mismo
        call RETARDO_DE250MS       ;retardo
		call RETARDO_DE250MS 
		call RETARDO_DE250MS 
		bcf PORTB,3

		RETURN

;********************************************************************
;                           RETARDOS                                *
;********************************************************************

RETARDO_DE1MS                  ;RETARDO PARA 1 MILISEGUNDO YA QUE 256 ES EL MAXIMO DEL PIC

		movlw d'250'            ;cargamos el registro de trabajo
		movwf ACUMULADOR1       ; para luego moverlo al ACUMULADOR1
RETARDOAUX1 
        nop
        decfsz ACUMULADOR1,F    ;con esta instruccion decremento el ACUMULADOR1 hacemos esto hasta que 
        goto RETARDOAUX1        ;se haya decrementado a 0, lo que significa 1ms de retardo
        RETURN


RETARDO_DE250MS                 ;con esta subrutina generaremos 250 ms
         movlw D'250'            ;Cantidad de veces que voy a llamar a la subrutina "RETARDOS_DE1MS"
         movwf ACUMULADOR2

RETARDOAUX2   
         call   RETARDO_DE1MS        ;llamamos al retardo de 1ms para por cada vuelta a RETARDOAUX2
         decfsz    ACUMULADOR2,F     ;vayamos decrementando en uno los 250 del ACUMULADOR1
         goto RETARDOAUX2            ;Lo repito hasta ACUMULADOR2 que quede en 0. Lo cual seria,250ms de retardo
         RETURN


RETARDO_DE1S                    ;con esta subrutina generaremos 1000 ms osea 1 seg
         movlw     D'4'         ;Cantidad de veces que voy a llamar a la subrutina "RETARDO_DE250MS"
         movwf     ACUMULADOR3

RETARDOAUX3      
	     call  RETARDO_DE250MS     ;Al llamarlo 4 veces vamos a generar 1seg
         decfsz     ACUMULADOR3,F  ;decrementamos hasta que
         goto   RETARDOAUX3        ;ACUMULADOR3 quede en 0
         RETURN



;********************************************************************
		END