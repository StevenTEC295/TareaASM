.MODEL SMALL
.STACK 100h

.DATA    

    ;Definir estructuras
    max_cuentas     equ 10
    max_numero      equ 8
    max_nombre      equ 20
    size_estado     equ 1
    registro_size   equ max_numero+max_nombre+2+size_estado
                         
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
    
    buffer_saldo  DB 7
                  DB ?
                  DB 7 DUP(?)
                  
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
    je opcion_depositar
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
    
opcion_depositar:
    ; Aquí irá la función para depositar
    lea dx, mensaje_crear_cuenta
    mov ah, 09h
    int 21h
    call esperar_tecla
    ret
    
opcion_retirar:
    ; Aquí irá la función para retirar
    lea dx, mensaje_crear_cuenta
    mov ah, 09h
    int 21h
    call esperar_tecla
    ret
    
opcion_consultar:
    ; Aquí irá la función para consultar
    lea dx, mensaje_crear_cuenta
    mov ah, 09h
    int 21h
    call esperar_tecla
    ret
    
opcion_reporte:
    ; Aquí irá la función para reporte
    lea dx, mensaje_crear_cuenta
    mov ah, 09h
    int 21h
    call esperar_tecla
    ret
    
opcion_desactivar:
    ; Aquí irá la función para desactivar
    lea dx, mensaje_crear_cuenta
    mov ah, 09h
    int 21h
    call esperar_tecla
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
    LEA DI, buffer_numero+2    ; DI apunta al número ingresado
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
    
    ; Mostrar mensaje de error
    PUSH DX
    MOV AH, 09h
    LEA DX, msg_cuenta_existe
    INT 21h
    POP DX
    
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


; Funcion: Crear cuenta con validacion

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
    
    ; Si llegamos aqui, el número es válido (no existe)
    JMP continuar_creacion
    
cuenta_duplicada:
    ; La cuenta ya existe - mostrar error y salir
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

END Main