.MODEL SMALL
.STACK 100h

.DATA    

    ; =============================================
    ; Constantes de estructura
    ; =============================================
    max_cuentas   equ 10
    max_numero    equ 8
    max_nombre    equ 20
    size_estado   equ 1
    registro_size equ 31        ; max_numero + max_nombre + 2 (saldo) + size_estado

    estado_activa   equ 1
    estado_inactiva equ 0       

    ; =============================================
    ; Almacenamiento de cuentas
    ; =============================================
    cuentas_array   db max_cuentas * registro_size dup(0)
    num_cuentas     dw 0
    offset_registro dw 0        ; Variable auxiliar para calcular posicion del registro

    ; =============================================
    ; Buffers de entrada
    ; =============================================
    buffer_numero DB max_numero
                  DB ?
                  DB max_numero DUP(?)

    buffer_nombre DB max_nombre
                  DB ?
                  DB max_nombre DUP(?)

    buffer_saldo  DB 5
                  DB ?
                  DB 5 DUP(?)

    buffer        DB 3, ?, 3 dup('$')

    ; =============================================
    ; Menu principal
    ; =============================================
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

    opcion db 0
    letras db 0

    ; =============================================
    ; Mensajes generales
    ; =============================================
    salto_linea          db 13,10,'$'
    mensaje_error        db 13,10,'Error: Debe ingresar un numero del 1 al 7$'
    msg_pedir_numero     db 13,10,'Ingrese numero de cuenta: $'
    msg_pedir_nombre     db 'Ingrese nombre del titular: $'
    msg_cuenta_creada    db 13,10,'*** CUENTA CREADA EXITOSAMENTE ***',13,10,'$'
    msg_error_limite     db 13,10,'ERROR: Limite de cuentas alcanzado!',13,10,'$'
    msg_no_cuentas       db 13,10,'No hay cuentas registradas.',13,10,'$'
    msg_cuenta_existe    db 13,10,'ERROR: El numero de cuenta ya existe!',13,10,'$'
    msg_cuenta_no_existe db 13,10,'ERROR: La cuenta no existe.',13,10,'$'
    msg_cuenta_inactiva  db 13,10,'ERROR: La cuenta esta INACTIVA.',13,10,'$'
    msg_no_numero db 13,10,'ERROR: Numero de cuenta no permite letras!',13,10,'$'
    msg_monto_invalido   db 13,10,'ERROR: Monto invalido. Debe ser mayor a 0.',13,10,'$'
    msg_pedir_monto      db 13,10,'Ingrese monto: $'
    msg_deposito_exitoso db 13,10,'*** DEPOSITO EXITOSO ***',13,10,'$'
    msg_retiro_exitoso   db 13,10,'*** RETIRO EXITOSO ***',13,10,'$'
    msg_fondos_insuf     db 13,10,'ERROR: Fondos insuficientes.',13,10,'$'
    msg_saldo_actual     db 'Saldo actual: $'
    msg_submenu_estado   db 13,10,'1. Activar',13,10,'2. Desactivar',13,10,'Seleccione opcion: $'
    msg_activada_ok      db 13,10,'*** CUENTA ACTIVADA EXITOSAMENTE ***',13,10,'$'
    msg_desactivada_ok   db 13,10,'*** CUENTA DESACTIVADA EXITOSAMENTE ***',13,10,'$'
    msg_ya_activa        db 13,10,'ERROR: La cuenta ya se encuentra activa.',13,10,'$'
    msg_ya_inactiva      db 13,10,'ERROR: La cuenta ya se encuentra inactiva.',13,10,'$'

    ; =============================================
    ; Mensajes de reporte
    ; =============================================
    msg_rep_titulo   db 13,10,'======= REPORTE GENERAL =======',13,10,'$'
    msg_rep_activas  db 'Cuentas Activas: $'
    msg_rep_inactivas db 13,10,'Cuentas Inactivas: $'
    msg_rep_saldo_tot db 13,10,'Saldo Total del Banco: $'
    msg_rep_saldo_max db 13,10,'Mayor Saldo Registrado: $'
    msg_rep_saldo_min db 13,10,'Menor Saldo Registrado: $'
    msg_rep_pie       db 13,10,'===============================',13,10,'$'

    ; =============================================
    ; Variables para reporte
    ; =============================================
    rep_activas    dw 0
    rep_inactivas  dw 0
    rep_saldo_total dw 0
    rep_saldo_max  dw 0
    rep_saldo_min  dw 0FFFFh


.CODE                                                                             


; =============================================
; Programa principal
; =============================================
Main proc
    mov ax, @DATA
    mov ds, ax
    
principal_loop:
    call mostrar_menu  
    call obtener_opcion
    jc mostrar_error_menu
    call switch
    jmp principal_loop
    
mostrar_error_menu:
    lea dx, mensaje_error
    mov ah, 09h
    int 21h
    lea dx, salto_linea
    mov ah, 09h
    int 21h
    mov ah, 08h
    int 21h
    jmp principal_loop
    
main endp


; =============================================
; Mostrar menu y leer opcion
; =============================================
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


; =============================================
; Validar y guardar opcion del menu
; Salida: CF=0 exito, CF=1 error
; =============================================
obtener_opcion proc       
    push ax
    push bx
    push cx
    push dx
    
    mov cl, buffer[1]
    cmp cl, 0
    je error_opcion
    
    mov al, buffer[2]
    cmp al, '0'
    jb error_opcion
    cmp al, '9'
    ja error_opcion
    
    sub al, '0'
    cmp al, 1
    jb error_opcion
    cmp al, 7
    ja error_opcion
    
    mov opcion, al
    clc
    jmp fin_opcion
    
error_opcion:
    stc
    
fin_opcion:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
obtener_opcion endp       


; =============================================
; Despachar segun opcion seleccionada
; =============================================
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


; =============================================
; Esperar una tecla antes de continuar
; =============================================
esperar_tecla proc
    push ax
    mov ah, 08h
    int 21h
    pop ax
    ret
esperar_tecla endp


; =============================================
; Copiar buffer_numero en [DI]
; Entrada: DI = destino en cuentas_array
; =============================================
copiar_numero PROC
    PUSH AX
    PUSH CX
    PUSH SI
    
    LEA SI, buffer_numero+2
    MOV CL, buffer_numero+1
    XOR CH, CH
    
    CMP CX, 0
    JE copiar_num_fin
    
copiar_num:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP copiar_num
    
copiar_num_fin:
    MOV BYTE PTR [DI], 0
    
    POP SI
    POP CX
    POP AX
    RET
copiar_numero ENDP


; =============================================
; Copiar buffer_nombre en [DI]
; Entrada: DI = destino en cuentas_array
; =============================================
copiar_nombre PROC
    PUSH AX
    PUSH CX
    PUSH SI
    
    LEA SI, buffer_nombre+2
    MOV CL, buffer_nombre+1
    XOR CH, CH
    
    CMP CX, 0
    JE copiar_nom_fin
    
copiar_nom:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP copiar_nom
    
copiar_nom_fin:
    MOV BYTE PTR [DI], 0
    
    POP SI
    POP CX
    POP AX
    RET
copiar_nombre ENDP


; =============================================
; Validar si numero de cuenta ya existe
; Salida: ZF=1 existe, ZF=0 no existe
; =============================================
validar_cuenta_existe PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    CMP num_cuentas, 0
    JE no_existe
    
    LEA SI, cuentas_array
    MOV CX, num_cuentas
    
buscar_cuenta:
    PUSH CX
    PUSH SI
    LEA DI, buffer_numero+2
    
comparar_numeros:
    MOV AL, [SI]
    MOV BL, [DI]
    CMP BL, 0Dh
    JE  buffer_terminado
    CMP AL, BL
    JNE siguiente_cuenta
    CMP AL, 0
    JE numeros_iguales
    INC SI
    INC DI
    JMP comparar_numeros
    
buffer_terminado:
    CMP AL, 0
    JNE siguiente_cuenta
    JE numeros_iguales
    
numeros_iguales:
    POP SI
    POP CX
    CMP AX, AX          ; ZF = 1 (existe)
    JMP fin_validacion
    
siguiente_cuenta:
    POP SI
    POP CX
    ADD SI, REGISTRO_SIZE
    LOOP buscar_cuenta
    
no_existe:
    XOR AX, AX
    CMP AX, 1           ; ZF = 0 (no existe)
    
fin_validacion:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET                     
validar_cuenta_existe ENDP


; =============================================
; Validar si numero de cuenta tiene letras
; Salida: CF=1 Posee letras, CF=0 No posee letras
; =============================================
validar_numero_cuenta proc       
    push ax
    push bx
    push cx
    push dx
    

buscar_letras:
        
    mov cl, buffer_numero[1]
    cmp cl, 0
    je error_string
    
    
    mov al, buffer_numero[bx+2]
    cmp al, '0'
    jb error_string
    cmp al, '9'
    ja error_string
     
    sub al, '0'
    cmp al, 0
    jb error_string
    cmp al, 9
    ja error_string
    
    inc bx
    
    cmp al, 0
    mov letras, al
    clc 
    
    cmp bl,cl     
    jl buscar_letras
    
    clc
    
    jmp fin_verificacion

    
error_string:
    stc 
    
fin_verificacion:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
    
validar_numero_cuenta endp    


; =============================================
; Localizar cuenta por numero
; Entrada: buffer_numero con numero buscado
; Salida:  SI = direccion de la cuenta
; =============================================
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
    LEA DI, buffer_numero+2
    
comparar_localizar:
    MOV AL, [SI]
    MOV BL, [DI]
    CMP BL, 0Dh
    JE buffer_terminado_localizar
    CMP AL, BL
    JNE siguiente_localizar
    CMP AL, 0
    JE encontrado_localizar
    INC SI
    INC DI
    JMP comparar_localizar
    
buffer_terminado_localizar:
    CMP AL, 0
    JNE siguiente_localizar
    JE encontrado_localizar
    
encontrado_localizar:
    POP SI
    POP CX
    JMP fin_localizar
    
siguiente_localizar:
    POP SI
    POP CX
    ADD SI, REGISTRO_SIZE
    LOOP buscar_localizar
    XOR SI, SI
    
fin_localizar:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    RET
localizar_cuenta_por_numero ENDP


; =============================================
; Convertir buffer_saldo a numero
; Salida: AX = numero convertido
; =============================================
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


; =============================================
; Mostrar numero en AX por pantalla
; =============================================
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


; =============================================
; Opcion 1: Crear cuenta
; =============================================
crear_cuenta proc   
    MOV AX, num_cuentas
    CMP AX, MAX_CUENTAS
    JL verificar_duplicado
    
    MOV AH, 09h
    LEA DX, msg_error_limite
    INT 21h
    call esperar_tecla
    RET
    
verificar_duplicado:
    MOV AH, 09h
    LEA DX, msg_pedir_numero
    INT 21h
    lea dx, buffer_numero
    mov ah, 0Ah
    int 21h
    lea dx, salto_linea
    mov ah, 09h
    int 21h
    
    CALL validar_cuenta_existe
    JZ cuenta_duplicada
    
    CALL validar_numero_cuenta
    JC no_es_numero
    
    JMP continuar_creacion
    
cuenta_duplicada:
    mov ah, 09h
    lea dx, msg_cuenta_existe
    int 21h
    call esperar_tecla
    RET 
    

no_es_numero:
    mov ah, 09h
    lea dx, msg_no_numero
    int 21h
    call esperar_tecla
    RET
        
continuar_creacion:
    ; Calcular offset del nuevo registro UNA sola vez
    MOV BX, num_cuentas
    MOV AX, registro_size
    MUL BX
    MOV offset_registro, AX

    ; Copiar numero
    LEA DI, cuentas_array
    ADD DI, offset_registro
    CALL copiar_numero

    ; Pedir y copiar nombre
    MOV AH, 09h
    LEA DX, msg_pedir_nombre
    INT 21h
    lea dx, buffer_nombre
    mov ah, 0Ah
    int 21h
    lea dx, salto_linea
    mov ah, 09h
    int 21h

    LEA DI, cuentas_array
    ADD DI, offset_registro
    ADD DI, MAX_NUMERO
    CALL copiar_nombre

    ; Guardar saldo = 0 y estado = activa
    LEA DI, cuentas_array
    ADD DI, offset_registro
    ADD DI, MAX_NUMERO + MAX_NOMBRE
    MOV WORD PTR [DI], 0
    ADD DI, 2
    MOV BYTE PTR [DI], ESTADO_ACTIVA

    INC num_cuentas

    MOV AH, 09h
    LEA DX, msg_cuenta_creada
    INT 21h
    call esperar_tecla
    RET
crear_cuenta endp


; =============================================
; Opcion 2: Depositar dinero
; =============================================
depositar proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    MOV AH, 09h
    LEA DX, msg_pedir_numero
    INT 21h
    lea dx, buffer_numero
    mov ah, 0Ah
    int 21h
    lea dx, salto_linea
    mov ah, 09h
    int 21h
              
    CALL validar_cuenta_existe
    JZ cuenta_encontrada_dep
    
    MOV AH, 09h
    LEA DX, msg_cuenta_no_existe
    INT 21h
    call esperar_tecla
    JMP fin_depositar
    
cuenta_encontrada_dep:
    CALL localizar_cuenta_por_numero
    
    PUSH SI
    ADD SI, MAX_NUMERO + MAX_NOMBRE + 2
    MOV AL, [SI]
    POP SI
    CMP AL, ESTADO_ACTIVA
    JE dep_cuenta_activa
    
    MOV AH, 09h
    LEA DX, msg_cuenta_inactiva
    INT 21h
    call esperar_tecla
    JMP fin_depositar
    
dep_cuenta_activa:
    MOV AH, 09h
    LEA DX, msg_pedir_monto
    INT 21h
    lea dx, buffer_saldo
    mov ah, 0Ah
    int 21h
    lea dx, salto_linea
    mov ah, 09h
    int 21h
    
    CALL convertir_monto
    CMP AX, 0
    JLE dep_monto_invalido
    
    PUSH SI
    ADD SI, MAX_NUMERO + MAX_NOMBRE
    MOV BX, [SI]
    ADD BX, AX
    MOV [SI], BX
    POP SI
    
    MOV AH, 09h
    LEA DX, msg_deposito_exitoso
    INT 21h
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
    
dep_monto_invalido:
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


; =============================================
; Opcion 3: Retirar dinero
; =============================================
opcion_retirar proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    MOV AH, 09h
    LEA DX, msg_pedir_numero
    INT 21h
    lea dx, buffer_numero
    mov ah, 0Ah
    int 21h
    lea dx, salto_linea
    mov ah, 09h
    int 21h

    CALL validar_cuenta_existe
    JZ ret_cuenta_encontrada

    MOV AH, 09h
    LEA DX, msg_cuenta_no_existe
    INT 21h
    call esperar_tecla
    JMP fin_retirar

ret_cuenta_encontrada:
    CALL localizar_cuenta_por_numero

    PUSH SI
    ADD SI, MAX_NUMERO + MAX_NOMBRE + 2
    MOV AL, [SI]
    POP SI
    CMP AL, ESTADO_ACTIVA
    JE ret_cuenta_activa

    MOV AH, 09h
    LEA DX, msg_cuenta_inactiva
    INT 21h
    call esperar_tecla
    JMP fin_retirar

ret_cuenta_activa:
    MOV AH, 09h
    LEA DX, msg_pedir_monto
    INT 21h
    lea dx, buffer_saldo
    mov ah, 0Ah
    int 21h
    lea dx, salto_linea
    mov ah, 09h
    int 21h

    CALL convertir_monto
    CMP AX, 0
    JLE ret_monto_invalido

    PUSH SI
    ADD SI, MAX_NUMERO + MAX_NOMBRE
    MOV BX, [SI]        ; BX = saldo actual
    CMP BX, AX
    JGE ret_hay_fondos

    POP SI
    MOV AH, 09h
    LEA DX, msg_fondos_insuf
    INT 21h
    call esperar_tecla
    JMP fin_retirar

ret_hay_fondos:
    SUB BX, AX
    MOV [SI], BX
    POP SI

    MOV AH, 09h
    LEA DX, msg_retiro_exitoso
    INT 21h
    MOV AH, 09h
    LEA DX, msg_saldo_actual
    INT 21h
    MOV AX, BX
    CALL mostrar_numero
    lea dx, salto_linea
    mov ah, 09h
    int 21h
    call esperar_tecla
    JMP fin_retirar

ret_monto_invalido:
    MOV AH, 09h
    LEA DX, msg_monto_invalido
    INT 21h
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


; =============================================
; Opcion 4: Consultar saldo
; =============================================
opcion_consultar proc
    mov ah, 09h
    lea dx, msg_pedir_numero
    int 21h
    lea dx, buffer_numero
    mov ah, 0Ah
    int 21h
    lea dx, salto_linea
    mov ah, 09h
    int 21h

    call validar_cuenta_existe
    jz realizar_consulta
    
    mov ah, 09h
    lea dx, msg_cuenta_no_existe
    int 21h
    call esperar_tecla
    ret

realizar_consulta:
    call localizar_cuenta_por_numero

    mov ah, 09h
    lea dx, msg_saldo_actual
    int 21h

    push si
    add si, MAX_NUMERO + MAX_NOMBRE
    mov ax, [si]
    pop si
    
    call mostrar_numero
    lea dx, salto_linea
    mov ah, 09h
    int 21h
    call esperar_tecla
    ret
opcion_consultar endp


; =============================================
; Opcion 6: Activar / Desactivar cuenta
; =============================================
opcion_desactivar proc
    mov ah, 09h
    lea dx, msg_pedir_numero
    int 21h
    lea dx, buffer_numero
    mov ah, 0Ah
    int 21h
    lea dx, salto_linea
    mov ah, 09h
    int 21h

    call validar_cuenta_existe
    jz mostrar_submenu_estado
    
    mov ah, 09h
    lea dx, msg_cuenta_no_existe
    int 21h
    call esperar_tecla
    ret

mostrar_submenu_estado:
    call localizar_cuenta_por_numero
    push si

    mov ah, 09h
    lea dx, msg_submenu_estado
    int 21h

    mov ah, 01h
    int 21h
    mov bl, al

    mov ah, 09h
    lea dx, salto_linea
    int 21h

    pop si
    add si, MAX_NUMERO + MAX_NOMBRE + 2
    mov al, [si]

    cmp bl, '1'
    je hacer_activacion
    cmp bl, '2'
    je hacer_desactivacion
    
    lea dx, mensaje_error
    mov ah, 09h
    int 21h
    call esperar_tecla
    ret

hacer_activacion:
    cmp al, 1
    je error_ya_activa
    mov byte ptr [si], 1
    mov ah, 09h
    lea dx, msg_activada_ok
    int 21h
    call esperar_tecla
    ret

hacer_desactivacion:
    cmp al, 0
    je error_ya_inactiva
    mov byte ptr [si], 0
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


; =============================================
; Opcion 5: Reporte general
; =============================================
opcion_reporte proc
    cmp num_cuentas, 0
    ja iniciar_reporte
    
    mov ah, 09h
    lea dx, msg_no_cuentas
    int 21h
    call esperar_tecla
    ret

iniciar_reporte:
    mov rep_activas, 0
    mov rep_inactivas, 0
    mov rep_saldo_total, 0
    mov rep_saldo_max, 0
    mov rep_saldo_min, 0FFFFh

    lea si, cuentas_array
    mov cx, num_cuentas

ciclo_reporte:
    push si

    ; Revisar estado
    add si, MAX_NUMERO + MAX_NOMBRE + 2
    mov al, [si]
    pop si

    cmp al, 1
    je es_activa
    inc rep_inactivas
    jmp revisar_saldo
es_activa:
    inc rep_activas

revisar_saldo:
    push si
    add si, MAX_NUMERO + MAX_NOMBRE
    mov ax, [si]
    pop si

    add rep_saldo_total, ax

    cmp ax, rep_saldo_max
    jbe evaluar_minimo
    mov rep_saldo_max, ax

evaluar_minimo:
    cmp ax, rep_saldo_min
    jae siguiente_cuenta_rep
    mov rep_saldo_min, ax

siguiente_cuenta_rep:
    add si, REGISTRO_SIZE
    loop ciclo_reporte

    ; Imprimir reporte
    mov ah, 09h
    lea dx, msg_rep_titulo
    int 21h

    lea dx, msg_rep_activas
    int 21h
    mov ax, rep_activas
    call mostrar_numero

    mov ah, 09h
    lea dx, msg_rep_inactivas
    int 21h
    mov ax, rep_inactivas
    call mostrar_numero

    mov ah, 09h
    lea dx, msg_rep_saldo_tot
    int 21h
    mov ax, rep_saldo_total
    call mostrar_numero

    mov ah, 09h
    lea dx, msg_rep_saldo_max
    int 21h
    mov ax, rep_saldo_max
    call mostrar_numero

    mov ah, 09h
    lea dx, msg_rep_saldo_min
    int 21h
    mov ax, rep_saldo_min
    call mostrar_numero

    mov ah, 09h
    lea dx, msg_rep_pie
    int 21h

    call esperar_tecla
    ret
opcion_reporte endp

END Main