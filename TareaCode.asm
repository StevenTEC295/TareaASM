.MODEL SMALL
.STACK 100h

.DATA    

    ;Definir estructuras
    max_cuentas     equ 10
    max_numero      equ 8
    max_nombre      equ 20
    size_estado     equ 1
    registro_size equ (max_numero+max_nombre+2+size_estado)
                         
    ;Constantes de estado_cuenta                        
    estado_activa   equ 1
    estado_inactiva equ 0       
    
    ;array donde se almacenaran cuentas
    cuentas_array db max_cuentas*registro_size dup(0)
    
    ;variable para contador de cuentas
    num_cuentas dw 0
    
    ;buffers para cuentas 
    buffer_numero DB 10
                  DB ?
                  DB 10 DUP(?)
    
    buffer_nombre DB 30
                  DB ?
                  DB 30 DUP(?)
    
    buffer_saldo  DB 5
                  DB ?
                  DB 5 DUP(?)
                  
    ; Mensajes para crear cuenta
    msg_pedir_numero DB 13,10,'Ingrese numero de cuenta: $'
    msg_pedir_nombre DB 'Ingrese nombre del titular: $'              
    
    msg_cuenta_creada DB 13,10,'*** CUENTA CREADA EXITOSAMENTE ***',13,10,'$'
    msg_error_limite  DB 13,10,'ERROR: Limite de cuentas alcanzado!',13,10,'$'
    msg_no_cuentas    DB 13,10,'No hay cuentas registradas.',13,10,'$'
    
    buffer db 3, ?, 3 dup('$')      ; Buffer pequeno para 1 caracter + Enter
    menu DB '=====================================', 13, 10
         DB '           MENU PRINCIPAL', 13, 10
         DB '=====================================', 13, 10
         DB '1. Crear cuenta', 13, 10
         DB '2. Depositar dinero', 13, 10
         DB '3. Retirar dinero', 13, 10
         DB '4. Consultar saldo', 13, 10
         DB '5. Mostrar reporte general', 13, 10
         DB '6. Desactivar cuenta', 13, 10
         DB '7. Salir', 13, 10
         DB '=====================================', 13, 10
         DB 'Seleccione una opcion: $'   
    opcion db 0                         ; Solo un byte (0-255)
    mensaje_error db 13,10,'Error: Debe ingresar un numero del 1 al 7$' 
    mensaje_crear_cuenta db 13, 10, 'Crear cuenta, en desarrollo...'
    msg_cuenta_existe DB 13,10,'ERROR: El numero de cuenta ya existe!',13,10,'$'               
    salto_linea db 13,10,'$' 
    
        
    msg_pedir_monto      DB 13,10,'Ingrese monto a depositar: $'
    msg_cuenta_inactiva  DB 13,10,'ERROR: La cuenta esta INACTIVA. No se puede depositar.',13,10,'$'
    msg_cuenta_no_existe DB 13,10,'ERROR: La cuenta no existe.',13,10,'$'
    msg_monto_invalido   DB 13,10,'ERROR: Monto invalido. Debe ser mayor a 0.',13,10,'$'
    msg_deposito_exitoso DB 13,10,'*** DEPOSITO EXITOSO ***',13,10,'$'
    msg_saldo_actual     DB 'Nuevo saldo: $'
    msg_submenu_estado  db 13,10,'1. Activar',13,10,'2. Desactivar',13,10,'Seleccione opcion: $'
    msg_activada_ok     db 13,10,'*** CUENTA ACTIVADA EXITOSAMENTE ***',13,10,'$'
    msg_ya_activa       db 13,10,'ERROR: La cuenta ya se encuentra activa.',13,10,'$'
    ; Mensajes para consultar saldo, retirar dinero, reporte general y desactivar cuenta.
    msg_retirar_monto   db 13,10,'Ingrese monto a retirar: $'  
    msg_retiro_exitoso  db 13,10,'*** RETIRO EXITOSO ***',13,10,'$'
    msg_monto_insuficiente  db 13,10,'NO VALIDO: Los fondos que desea retirar no son suficientes',13,10,'$'
    msg_desactivada_ok  db 13,10,'*** CUENTA DESACTIVADA EXITOSAMENTE ***',13,10,'$'
    msg_ya_inactiva     db 13,10,'ERROR: La cuenta ya se encuentra inactiva.',13,10,'$'
    msg_nombre_titular  db 13,10,'Titular: $'
    ; Textos msg para el reporte
    msg_rep_titulo      db 13,10,'======= REPORTE GENERAL =======',13,10,'$'
    msg_rep_activas     db 'Cuentas Activas: $'
    msg_rep_inactivas   db 13,10,'Cuentas Inactivas: $'
    msg_rep_saldo_tot   db 13,10,'Saldo Total del Banco: $'
    msg_rep_saldo_max   db 13,10,'Mayor Saldo Registrado: $'
    msg_rep_saldo_min   db 13,10,'Menor Saldo Registrado: $'
    msg_rep_pie         db 13,10,'===============================',13,10,'$'

    ; Variables matematicas para el reporte genral
    rep_activas         dw 0
    rep_inactivas       dw 0
    rep_saldo_total     dw 0
    rep_saldo_max       dw 0
    rep_saldo_min       dw 0FFFFh  ; Inicia en el maximo posible para poder encontrar el menor




.CODE                                                                             


Main proc
    mov ax, @DATA
    mov ds, ax
    
principal_loop:
    call mostrar_menu  
    call obtener_opcion
    jc mostrar_error_menu
    call switch ;Escoger opcion
    
    ; Despues de cada operacion, volver al menu
    jmp principal_loop
    
mostrar_error_menu:
    lea dx, mensaje_error
    mov ah, 09h
    int 21h
    
    lea dx, salto_linea
    mov ah, 09h
    int 21h
    
    ; Esperar una tecla antes de continuar
    mov ah, 08h
    int 21h
    
    jmp principal_loop
    
main endp

mostrar_menu proc
    lea dx, menu
    mov ah, 09h
    int 21h
    
    lea dx, buffer
    mov ah, 0Ah
    int 21h
    
    lea dx, salto_linea
    mov ah, 09h
    int 21h  
    
    ret
mostrar_menu endp

obtener_opcion proc       
    push ax
    push bx
    push cx
    push dx
    
    ; Verificar que no esta vacio
    mov cl, buffer[1]        ; Longitud de la entrada
    cmp cl, 0
    je error_opcion
    
    ; Obtener el primer caracter
    mov al, buffer[2]        ; Primer caracter ingresado
    
    ; Validar que sea digito
    cmp al, '0'
    jb error_opcion
    cmp al, '9'
    ja error_opcion
    
    ; Convertir de ASCII a numero
    sub al, '0'
    
    ; Validar que esta entre 1 y 7
    cmp al, 1
    jb error_opcion          ; Menor que 1
    cmp al, 7
    ja error_opcion          ; Mayor que 7
    
    ; Guardar la opcion
    mov opcion, al
    
    clc                      ; exito
    jmp fin_opcion
    
error_opcion:
    stc                      ; Error
    
fin_opcion:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
obtener_opcion endp       

switch proc 
    cmp opcion, 1
    je crear_cuenta
    cmp opcion, 2
    je depositar
    cmp opcion, 3
    je opcion_retirar
    cmp opcion, 4
    je opcion_consultar
    cmp opcion, 5
    je opcion_reporte
    cmp opcion, 6
    je opcion_desactivar
    cmp opcion, 7
    je salir_programa
    
    ret
    
salir_programa:
    mov ah, 4Ch
    int 21h
    
switch endp


; Funcion para esperar una tecla

esperar_tecla proc
    push ax
    
    mov ah, 08h
    int 21h
    
    pop ax
    ret
esperar_tecla endp

copiar_numero PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI
    
    LEA SI, buffer_numero+2
    MOV CL, buffer_numero+1
    XOR CH, CH
    
copiar_num:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP copiar_num
    
    MOV BYTE PTR [DI], 0
    
    POP DI
    POP SI
    POP CX
    POP AX
    RET
copiar_numero ENDP


; Funcion: Validar si el numero de cuenta ya existe

validar_cuenta_existe PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    ; Si no hay cuentas, no puede existir
    CMP num_cuentas, 0
    JE no_existe
    
    ; Preparar busqueda
    LEA SI, cuentas_array     ; SI apunta al inicio del array
    MOV CX, num_cuentas       ; CX = numero de cuentas a revisar
    XOR BX, BX                ; BX = contador/offset
    
buscar_cuenta:
    PUSH CX
    PUSH SI
    
    ; Comparar numero actual con el buscado
    LEA DI, buffer_numero+2    ; DI apunta al n�mero ingresado
    MOV CX, MAX_NUMERO-1       ; Longitud maxima sin terminador
    
comparar_numeros:
    MOV AL, [SI]               ; Caracter del array
    MOV BL, [DI]               ; Caracter del buffer
    CMP BL, 0Dh
    JE  buffer_terminado
    CMP AL, BL
    JNE siguiente_cuenta        ; Si son diferentes, siguiente cuenta
    
    CMP AL, 0                   ; Llegamos al terminador?
    JE numeros_iguales          ; Si ambos son 0, son iguales
    
    INC SI
    INC DI
    LOOP comparar_numeros
    
    ; Si llegamos aqui, revisar el ultimo caracter
    MOV AL, [SI]
    MOV BL, [DI]
    CMP AL, BL
    JNE siguiente_cuenta
    
numeros_iguales:
    ; Los numeros son iguales - la cuenta ya existe
    POP SI
    POP CX
    
    ; Configurar ZF = 1 (existe)
    CMP AX, AX                   ; Esto pone ZF = 1
    JMP fin_validacion
    
siguiente_cuenta:
    POP SI
    POP CX
    ADD SI, REGISTRO_SIZE        ; Avanzar a la siguiente cuenta
    LOOP buscar_cuenta
    
no_existe:
    ; La cuenta no existe
    ; Configurar ZF = 0 (no existe)
    XOR AX, AX
    CMP AX, 1                    ; Esto pone ZF = 0
    
fin_validacion:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET                     
validar_cuenta_existe ENDP  

buffer_terminado:
    ; El usuario presiono Enter - considerar como fin de cadena
    MOV BYTE PTR [DI], 0        ; Poner terminador explicitamente
    ; Continuar comparacion con el nuevo terminador
    JMP comparar_numeros
 
 
;================================================
;Funcion: Depositar dinero
;================================================

depositar proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
verificar_existe:
    ; Pedir numero primero para validar
    MOV AH, 09h
    LEA DX, msg_pedir_numero
    INT 21h
    
    lea dx, buffer_numero
    mov ah, 0Ah
    int 21h
    
    lea dx, salto_linea
    mov ah, 09h
    int 21h
              
    ; Validar si el numero ya existe
    CALL validar_cuenta_existe
    JZ cuenta_encontrada
    JMP cuenta_no_existe
    
cuenta_encontrada:
    ; La cuenta existe - ahora hay que localizarla en el array
    CALL localizar_cuenta_por_numero   ; Devuelve SI = direccion de la cuenta
    
    ; Verificar que la cuenta esta ACTIVA
    PUSH SI
    ADD SI, MAX_NUMERO + MAX_NOMBRE + 2   ; SI apunta al campo estado
    MOV AL, [SI]
    POP SI
    CMP AL, ESTADO_ACTIVA
    JE cuenta_activa
    
    ; Si la cuenta est� INACTIVA
    MOV AH, 09h
    LEA DX, msg_cuenta_inactiva
    INT 21h
    call esperar_tecla
    JMP fin_depositar
    
cuenta_activa:
    ; Pedir cantidad a depositar
    MOV AH, 09h
    LEA DX, msg_pedir_monto
    INT 21h
    
    lea dx, buffer_saldo
    mov ah, 0Ah
    int 21h
    
    lea dx, salto_linea
    mov ah, 09h
    int 21h
    
    ; Convertir el monto ingresado a numero (AX)
    CALL convertir_monto
    
    ; Verificar que el monto sea positivo
    CMP AX, 0
    JLE monto_invalido
    
    ; Localizar el campo saldo de la cuenta
    PUSH SI
    ADD SI, MAX_NUMERO + MAX_NOMBRE   ; SI apunta al campo saldo
    MOV BX, [SI]                      ; BX = saldo actual
    
    ; Sumar el monto al saldo actual
    ADD BX, AX
    MOV [SI], BX                       ; Guardar nuevo saldo
    POP SI
    
    ; Mostrar mensaje de Exito
    MOV AH, 09h
    LEA DX, msg_deposito_exitoso
    INT 21h
    
    ; Mostrar el nuevo saldo
    MOV AH, 09h
    LEA DX, msg_saldo_actual
    INT 21h
    
    MOV AX, BX
    CALL mostrar_numero 
    
    lea dx, salto_linea
    mov ah, 09h
    int 21h

    call esperar_tecla
    JMP fin_depositar
    
cuenta_no_existe:
    MOV AH, 09h
    LEA DX, msg_cuenta_no_existe
    INT 21h
    call esperar_tecla
    JMP fin_depositar
    
monto_invalido:
    MOV AH, 09h
    LEA DX, msg_monto_invalido
    INT 21h
    call esperar_tecla
    
fin_depositar:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
depositar endp


; Funcion: Localizar cuenta por numero
; ENTRADA: buffer_numero con el numero buscado
; SALIDA:  SI = direccion de la cuenta en cuentas_array

localizar_cuenta_por_numero PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    LEA SI, cuentas_array
    MOV CX, num_cuentas
    
buscar_localizar:
    PUSH CX
    PUSH SI
    
    ; Comparar numeros
    LEA DI, buffer_numero+2
    MOV CX, MAX_NUMERO-1
    
comparar_localizar:
    MOV AL, [SI]
    MOV BL, [DI]
    CMP AL, BL
    JNE siguiente_localizar
    
    CMP AL, 0
    JE encontrado_localizar
    
    INC SI
    INC DI
    LOOP comparar_localizar
    
    ; Verificar ultimo caracter
    MOV AL, [SI]
    MOV BL, [DI]
    CMP AL, BL
    JNE siguiente_localizar
    CMP AL, 0
    JNE siguiente_localizar
    
encontrado_localizar:
    POP SI           ; Recuperamos SI original (direccion de la cuenta)
    POP CX
    JMP fin_localizar
    
siguiente_localizar:
    POP SI
    POP CX
    ADD SI, REGISTRO_SIZE
    LOOP buscar_localizar
    
    ; Si no encuentra (no deberia pasar porque ya validamos)
    XOR SI, SI
    
fin_localizar:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    RET
localizar_cuenta_por_numero ENDP


; Funcion: Convertir monto ingresado a numero
; ENTRADA: buffer_saldo con el monto
; SALIDA:  AX = numero convertido

convertir_monto PROC
    push bx
    push cx
    push dx
    push si
    
    LEA SI, buffer_saldo+2
    XOR AX, AX
    XOR BX, BX
    MOV CL, buffer_saldo+1
    XOR CH, CH
    
    CMP CX, 0
    JE fin_conversion
    
convertir_monto_loop:
    MOV BL, [SI]
    CMP BL, '0'
    JB fin_conversion
    CMP BL, '9'
    JA fin_conversion
    
    SUB BL, '0'
    MOV DX, 10
    MUL DX
    ADD AX, BX
    INC SI
    LOOP convertir_monto_loop
    
fin_conversion:
    pop si
    pop dx
    pop cx
    pop bx
    RET
convertir_monto ENDP


; Funcion: Mostrar numero en AX

mostrar_numero PROC
    push ax
    push bx
    push cx
    push dx
    
    MOV BX, 10
    XOR CX, CX
    
convertir_mostrar:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    OR AX, AX
    JNZ convertir_mostrar
    
mostrar_digitos_loop:
    POP DX
    ADD DL, '0'
    MOV AH, 02h
    INT 21h
    LOOP mostrar_digitos_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    RET
mostrar_numero ENDP
     
   

;================================================
; Funcion: Crear cuenta con validacion
;================================================


crear_cuenta proc   
    ; Verificar espacio
    MOV AX, num_cuentas
    CMP AX, MAX_CUENTAS
    JL verificar_duplicado
    
    MOV AH, 09h
    LEA DX, msg_error_limite
    INT 21h
    call esperar_tecla
    RET
    
verificar_duplicado:
    ; Pedir numero primero para validar
    MOV AH, 09h
    LEA DX, msg_pedir_numero
    INT 21h
    
    lea dx, buffer_numero
    mov ah, 0Ah
    int 21h
    
    lea dx, salto_linea
    mov ah, 09h
    int 21h
    
    ; Validar si el numero ya existe
    CALL validar_cuenta_existe
    JZ cuenta_duplicada          ; Si ZF = 1, la cuenta ya existe
    
    ; Si llegamos aqui, el n�mero es v�lido (no existe)
    JMP continuar_creacion
    
cuenta_duplicada:
    ; La cuenta ya existe - mostrar error y salir
    mov ah, 09h
    lea dx, msg_cuenta_existe
    int 21h
    call esperar_tecla
    RET
    
continuar_creacion:
    ; Calcular posicion
    MOV AX, REGISTRO_SIZE
    MUL num_cuentas
    LEA DI, cuentas_array
    ADD DI, AX
    
    ; Copiar numero (ya validado)
    CALL copiar_numero      ; Copia a DI
    
    ; Avanzar al nombre
    ADD DI, MAX_NUMERO
    
    ; Pedir nombre
    MOV AH, 09h
    LEA DX, msg_pedir_nombre
    INT 21h
    
    lea dx, buffer_nombre
    mov ah, 0Ah
    int 21h
    
    lea dx, salto_linea
    mov ah, 09h
    int 21h  
    
    CALL copiar_nombre      ; Copia a DI
    
    ; Avanzar al saldo
    ADD DI, MAX_NOMBRE
    
    ; 3. GUARDAR SALDO = 0 (SIEMPRE)
    MOV WORD PTR [DI], 0     ; Saldo inicial en 0
    
    ; Avanzar al campo estado
    ADD DI, 2                ; +2 por el saldo word
    
    ; 4. GUARDAR ESTADO = ACTIVA (SIEMPRE)
    MOV BYTE PTR [DI], ESTADO_ACTIVA
    
    ; Incrementar contador de cuentas
    INC num_cuentas
    
    ; Mostrar mensaje de exito
    MOV AH, 09h
    LEA DX, msg_cuenta_creada
    INT 21h
    
    call esperar_tecla
    RET
crear_cuenta endp 

copiar_nombre PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI
    
    LEA SI, buffer_nombre+2
    MOV CL, buffer_nombre+1
    XOR CH, CH
    
copiar_nom:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP copiar_nom
    
    MOV BYTE PTR [DI], 0
    
    POP DI
    POP SI
    POP CX
    POP AX
    RET
copiar_nombre ENDP


;================================================
;Funcion: Retirar saldo
;================================================

opcion_retirar proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ;Pedir numero de cuenta 
    mov ah, 09h
    lea dx, msg_pedir_numero
    int 21h

    lea dx, buffer_numero
    mov ah, 0Ah
    int 21h

    lea dx, salto_linea
    mov ah, 09h
    int 21h

    ;Validar si existe 
    call validar_cuenta_existe
    jz retiro      ; Si ZF=1, la cuenta existe, saltamos a consultar
    
    ; Si no existe, imprimimos error y salimos
    mov ah, 09h
    lea dx, msg_cuenta_no_existe
    int 21h
    call esperar_tecla 
    ;ret
    jmp fin_retirar
    
retiro: 

    ;Obtener el puntero a la cuenta (SI)    
    call localizar_cuenta_por_numero
    
    ; Verificar que la cuenta esta ACTIVA
    push si
    add si, MAX_NUMERO + MAX_NOMBRE + 2   ; SI apunta al campo estado
    mov al, [si]
    pop si
    cmp al, ESTADO_ACTIVA
    je cuenta_activa_retirar
    
    ; Si la cuenta esta INACTIVA
    mov ah, 09h
    lea dx, msg_cuenta_inactiva
    int 21h
    call esperar_tecla
    jmp fin_retirar
    
cuenta_activa_retirar:
    
    ;Imprimir etiqueta de saldo a retirar
    mov ah, 09h
    lea dx, msg_retirar_monto
    int 21h 
    
    lea dx, buffer_saldo
    mov ah, 0Ah
    int 21h
    
    lea dx, salto_linea
    mov ah, 09h
    int 21h
    
    ; Convertir monto ingresado en numero (ax)
    call convertir_monto
    
     
    ;Tomar saldo actual y convertirlo en numero (cx)
    push si
    add si, 28              ; Brincamos 28 bytes hacia adelante
    mov cx, [si]            ; Traemos el saldo a CX
    pop si
    
    ;verificar que el monto sea positivo
    cmp ax, 0
    jle monto_no_valido
    
    ;verificar que el monto sea menor al saldo actual
    cmp ax,cx
    jg monto_insuficiente
    
    ;Localizar el campo saldo de la cuenta
    push si
    add si, MAX_NUMERO + MAX_NOMBRE   ; SI apunta al campo saldo
    mov cx, [si]                      ; BX = saldo actual
    
    
    ; Restar el monto del saldo actual
    sub cx, ax
    mov [si], cx                       ; Guardar nuevo saldo
    pop si
    
    ; Mostrar mensaje de Exito
    mov ah, 09h
    lea dx, msg_retiro_exitoso
    int 21h
    
    ; Mostrar el nuevo saldo
    mov ah, 09h
    lea dx, msg_saldo_actual
    int 21h
    
    mov ax, cx
    call mostrar_numero  
    
    lea dx, salto_linea
    mov ah, 09h
    int 21h

    call esperar_tecla
    jmp fin_retirar

    
monto_no_valido:
    mov ah, 09h
    lea dx, msg_monto_invalido
    int 21h
    call esperar_tecla 
    ;ret
    jmp fin_retirar
           
monto_insuficiente:
    mov ah, 09h
    lea dx, msg_monto_insuficiente
    int 21h
    call esperar_tecla
    
    
fin_retirar:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
    

opcion_retirar endp


;================================================
;Funcion: Consultar saldo
;================================================

opcion_consultar proc
     ; 1. Pedir numero de cuenta 
    mov ah, 09h
    lea dx, msg_pedir_numero
    int 21h

    lea dx, buffer_numero
    mov ah, 0Ah
    int 21h

    lea dx, salto_linea
    mov ah, 09h
    int 21h

    ; 2. Validar si existe 
    call validar_cuenta_existe
    jz realizar_consulta      ; Si ZF=1, la cuenta existe, saltamos a consultar
    
    ; Si no existe, imprimimos error y salimos
    mov ah, 09h
    lea dx, msg_cuenta_no_existe
    int 21h
    call esperar_tecla
    ret
realizar_consulta:
    ; 3. Obtener el puntero a la cuenta (SI)    
    call localizar_cuenta_por_numero

    ; 4. Imprimir Titulo de Saldo
    mov ah, 09h
    lea dx, msg_saldo_actual
    int 21h

    ; 5. Leer el Saldo (Esta en el byte 28)
    push si
    add si, 28              ; Brincamos 28 bytes hacia adelante
    mov ax, [si]            ; Traemos el saldo a AX
    pop si
    
    call mostrar_numero     ;imprimir 

    lea dx, salto_linea
    mov ah, 09h
    int 21h

    call esperar_tecla
    ret
opcion_consultar endp
                      
                      

;================================================
;Funcion: Desactivar cuenta
;================================================                      
                      
opcion_desactivar proc
    ; 1. Pedir numero de cuenta
    mov ah, 09h
    lea dx, msg_pedir_numero
    int 21h

    lea dx, buffer_numero
    mov ah, 0Ah
    int 21h

    lea dx, salto_linea
    mov ah, 09h
    int 21h

    ; 2. Validar existencia
    call validar_cuenta_existe
    jz mostrar_submenu_estado
    
    ; Si no existe
    mov ah, 09h
    lea dx, msg_cuenta_no_existe
    int 21h
    call esperar_tecla
    ret

mostrar_submenu_estado:
    ; 3. Obtener el puntero a la cuenta (SI)
    call localizar_cuenta_por_numero
    
    ; GUARDAMOS "SI" porque leer el teclado va a ensuciar los registros
    push si 

    ; 4. Mostrar submenu
    mov ah, 09h
    lea dx, msg_submenu_estado
    int 21h

    ; 5. Leer UNA sola tecla (opcion 1 o 2)
    mov ah, 01h
    int 21h
    mov bl, al          ; Guardamos lo que el usuario digitó en BL

    ; Imprimir salto de linea para que se vea ordenado
    mov ah, 09h
    lea dx, salto_linea
    int 21h

    ; RECUPERAMOS "SI" y leemos el estado actual de la cuenta
    pop si 
    add si, 30          ; Brincamos al byte del Estado
    mov al, [si]        ; AL tiene el estado actual (1 = Activa, 0 = Inactiva)

    ; 6. Redirigir según lo que eligió el usuario
    cmp bl, '1'
    je hacer_activacion
    cmp bl, '2'
    je hacer_desactivacion
    
    ; Si digitó otra cosa (ej. un 5 o una letra)
    lea dx, mensaje_error
    mov ah, 09h
    int 21h
    call esperar_tecla
    ret

hacer_activacion:
    cmp al, 1           ; Verificamos si YA está activa
    je error_ya_activa
    mov byte ptr [si], 1 ; Le ponemos un 1 (Activa)
    
    mov ah, 09h
    lea dx, msg_activada_ok
    int 21h
    call esperar_tecla
    ret

hacer_desactivacion:
    cmp al, 0           ; Verificamos si YA está inactiva
    je error_ya_inactiva
    mov byte ptr [si], 0 ; Le ponemos un 0 (Inactiva)
    
    mov ah, 09h
    lea dx, msg_desactivada_ok
    int 21h
    call esperar_tecla
    ret

error_ya_activa:
    mov ah, 09h
    lea dx, msg_ya_activa
    int 21h
    call esperar_tecla
    ret

error_ya_inactiva:
    mov ah, 09h
    lea dx, msg_ya_inactiva
    int 21h
    call esperar_tecla
    ret
opcion_desactivar endp  



;================================================
;Funcion: Reporte
;================================================


opcion_reporte proc
    ; 1. Revisar si hay cuentas creadas
    cmp num_cuentas, 0
    ja iniciar_reporte      ; Si hay más de 0, iniciamos
    
    mov ah, 09h
    lea dx, msg_no_cuentas
    int 21h
    call esperar_tecla
    ret

iniciar_reporte:
    ; Limpiamos contadores a 0 (por si se pide el reporte 2 veces seguidas)
    mov rep_activas, 0
    mov rep_inactivas, 0
    mov rep_saldo_total, 0
    mov rep_saldo_max, 0
    mov rep_saldo_min, 0FFFFh ; Maximo posible

    lea si, cuentas_array   ; SI apunta al inicio de toda la base de datos
    mov cx, num_cuentas     ; CX es nuestro contador para el LOOP

ciclo_reporte:
    ; A. REVISAR ESTADO (Byte 30)
    push si
    add si, 30
    mov al, [si]
    pop si

    cmp al, 1
    je es_activa
    inc rep_inactivas       ; Si no es 1, sumamos inactiva
    jmp revisar_saldo
es_activa:
    inc rep_activas

revisar_saldo:
    ; B. REVISAR SALDOS (Byte 28)
    push si
    add si, 28
    mov ax, [si]            ; AX tiene el saldo de esta cuenta
    pop si

    add rep_saldo_total, ax ; Acumulamos el saldo total

    ; Evaluar Maximo
    cmp ax, rep_saldo_max
    jbe evaluar_minimo      ; Si es menor o igual, ignoramos
    mov rep_saldo_max, ax   ; ¡Nuevo campeon maximo!

evaluar_minimo:
    cmp ax, rep_saldo_min
    jae siguiente_cuenta_rep; Si es mayor o igual, ignoramos
    mov rep_saldo_min, ax   ; ¡Nuevo campeon minimo!

siguiente_cuenta_rep:
    add si, 31              ; Brincamos a la siguiente cuenta (31 bytes)
    loop ciclo_reporte

imprimir_reporte:
    ; Imprimimos Titulo
    mov ah, 09h
    lea dx, msg_rep_titulo
    int 21h

    ; Imprimir Activas
    lea dx, msg_rep_activas
    int 21h
    mov ax, rep_activas
    call mostrar_numero

    ; Imprimir Inactivas
    mov ah, 09h
    lea dx, msg_rep_inactivas
    int 21h
    mov ax, rep_inactivas
    call mostrar_numero

    ; Imprimir Saldo Total
    mov ah, 09h
    lea dx, msg_rep_saldo_tot
    int 21h
    mov ax, rep_saldo_total
    call mostrar_numero

    ; Imprimir Maximo
    mov ah, 09h
    lea dx, msg_rep_saldo_max
    int 21h
    mov ax, rep_saldo_max
    call mostrar_numero

    ; Imprimir Minimo
    mov ah, 09h
    lea dx, msg_rep_saldo_min
    int 21h
    mov ax, rep_saldo_min
    call mostrar_numero

    ; Pie de Reporte
    mov ah, 09h
    lea dx, msg_rep_pie
    int 21h

    call esperar_tecla
    ret
opcion_reporte endp


END Main