; IMPL macros are required to execute for init
; CALL macros for calling the function

; return Byte eax: status code
%macro STRCMP_CALL 2; (DoubleWord: p_str1, DoubleWord: p_str2)
    push esi
    push edi
    mov esi, %1
    mov edi, %2
    call strcmp
    pop edi
    pop esi
%endmacro

%macro STRCMP_IMPL 0
    jmp init_SPRINT
strcmp:
    push edx
    mov edx, esi
%%loop:; char by char
    cmp byte[esi], 0; Null terminator check
    je %%check_end
    mov al, byte[esi]
    cmp al, byte[edi]
    jne %%not_equal
    inc esi; Next byte
    inc edi
    jmp %%loop
%%check_end:
    cmp edx, esi; Either str1 == null or str1 == str2
    jne %%not_equal
    mov eax, 0; Status COde 
    jmp %%quit
%%not_equal:
    mov eax, 1; Status code 
%%quit:
    pop edx
    ret
%endmacro

; return no changes
%macro EMPTY_BUFFER_CALL 2; (DoubleWord: size, DoubleWord: p_buffer)

    push ecx
    push edi
    mov ecx, %1
    mov edi, %2
    call empty_buffer
    pop edi
    pop ecx
%endmacro

%macro EMPTY_BUFFER_IMPL 0
    jmp init_STRCPY
empty_buffer:
    push eax
    mov al, 0
    cld
    rep stosb
    pop eax

    ret
%endmacro

; return Byte eax: status code
%macro STRCPY_CALL 3; (DoubleWord: p_source_str, DoubleWord: p_dest_str, DoubleWord dest_size)
    push esi
    push edi
    push edx
    mov esi, %1
    mov edi, %2
    mov edx, %3
    call strcpy
    pop edx
    pop edi
    pop esi
%endmacro

%macro STRCPY_IMPL 0
    jmp init_ITOA
strcpy:
    push ecx
    xor ecx, ecx; init coutner
.next:
    cmp ecx, edx; cmp with max dest len
    jae .maxlen_reached
    mov al, [esi + ecx]
    mov [edi + ecx], al
    inc ecx
    cmp al, 0
    jnz .next
    jmp .success
.maxlen_reached:
    mov byte [edi + edx - 1], 0; Overwrite with Null
.success:
    mov eax, 0; Status Code
    pop ecx
    ret
%endmacro

; return DoubleWord buffer: str
%macro ITOA_CALL 1; (DoubleWord: i)
    push eax
    mov eax, %1; devidend
    call itoa
    pop eax
%endmacro

%macro ITOA_IMPL 0
    jmp init_ATOI
itoa:
    ; (eax: Lower 32bits, ebx: divisor, ecx: temp2, edx: Upper 32bits)
    push ebx
    push ecx
    push edx

    ; Divide by 10
    mov ebx, 10; divisor
    mov ecx, 0; init counter
    mov edx, 0; Upper 32bits are 0

    EMPTY_BUFFER_CALL 64, itoa_buffer
%%loop:
    div ebx; EAX / EBX = EAX...EDX
    push edx; LILO
    inc ecx; num of times to pop off the stack
    cmp eax, 0; eax=0 means the end
    jz %%done
    jmp %%loop
%%done:
    mov eax, 0
    mov ebx, 0; Use as second counter
%%write:
    ; Write in the buffer
    cmp ebx, ecx
    je %%finished
    pop edx
    add edx, 48
    mov [itoa_buffer + ebx], edx
    inc ebx
    jmp %%write
%%finished:
    ; mov [itoa_buffer + ebx], 0; null terminator
    pop edx
    pop ecx
    pop ebx
    ret
%endmacro

; return DoubleWord eax
%macro ATOI_CALL 1; (p_str)
    push ebx
    mov ebx, 0
    mov ebx, %1
    call atoi
    pop ebx
%endmacro

%macro ATOI_IMPL 0
    jmp init_VALIDATE_PASSWORD
atoi:
    push ecx
    push edx
    mov eax, 0; init current digit
    mov ecx, 0; init loop counter
    mov edx, 0; init second counder
%%loop:
    cmp byte[ebx + ecx], 0; null check
    jz %%finished
    mov eax, [ebx + ecx]
    push eax
    inc ecx
    jmp %%ready
%%ready:
    mov eax, 0; init to sum up digits
%%finished:
    cmp ecx, edx
    jz %%quit
    pop ebx
    ; add eax, ebx * 10 * edx
    push ebx
    mov ecx, ebx
    imul ecx, 10
    imul ecx, edx
    add eax, ecx
    pop ebx
    inc edx
    jmp %%finished
%%quit:
    pop edx
    pop ecx
    ret
%endmacro

;return DoubleWord eax: status code
%macro VALIDATE_PASSWORD_CALL 1; (p_password)
    mov eax, %1
    call validate_password
%endmacro

%macro VALIDATE_PASSWORD_IMPL 0
    jmp init_AUTHENTICATE
validate_password:
    ; (ebx: capital flg, ecx: len)
    push ebx
    push ecx
    
    mov ebx, 0; hasCapital
    mov ecx, 0

%%capital_check:
    cmp byte[eax + ecx], 0; Null Check
    je %%finished_word_check
    
    cmp byte[eax + ecx], 'A'; Capital flg checker
    jb %%is_not_capital
    cmp byte[eax + ecx], 'Z'
    ja %%is_not_capital
    mov ebx, 1; flg on
    jmp %%is_capital
%%is_not_capital:
    inc ecx
    jmp %%capital_check
%%is_capital:
    inc ecx
    mov ebx, 1
    jmp %%capital_check
%%finished_word_check:
    cmp ebx, 1
    je %%has_capital
    jmp %%no_capital
%%has_capital:
    SPRINT_CALL has_capital
    cmp ecx, 8
    jge %%has_8words
    jmp %%has_no_8words
%%has_8words:
    SPRINT_CALL has_8words
    jmp %%success
%%has_no_8words:
    SPRINT_CALL has_no_8words
    mov eax, 1
    jmp %%finished
%%no_capital:
    SPRINT_CALL has_no_capical
    mov eax, 1
    jmp %%finished
%%success:
    mov eax, 0
    jmp %%finished
%%finished:
    pop ecx
    pop ebx
    ret
%endmacro

;return DoubleWord eax: status code
%macro AUTHENTICATE_CALL 2; (DoubleWord p_username, DoubleWord p_password)
    push ebx
    mov eax, %1; Username
    mov ebx, %2; Password
    call authenticate
    pop ebx
%endmacro

%macro AUTHENTICATE_IMPL 1; (DoubleWord p_users)
    jmp init_slen
authenticate:
    push esi
    mov esi, %1; current pointer

    push ecx; user index
    mov ecx, 0; init
%%username_loop:
    cmp ecx, 16; above capacity
    jge %%invalid

    push esi
    push ecx
    
    imul ecx, USER_SIZE
    add esi, ecx
    
    pop ecx
    pop esi

    push ebx
    lea ebx, [esi+1]
    STRCMP_CALL eax, ebx
    pop ebx
    cmp eax, 0
    je %%check_password
    inc ecx; next user
%%check_password:
    mov eax, ebx; copy input password
    add esi, 16; offset
    STRCMP_CALL eax, esi
    cmp eax, 0
    je %%valid
    jmp %%invalid
%%valid:
    mov eax, 0
    jmp %%finished
%%invalid:
    mov eax, 1
    jmp %%finished
%%finished:
    pop ecx
    pop esi
    ret
    
%endmacro

;return no change
%macro SPRINT_CALL 1; (p_message)
    EMPTY_BUFFER_CALL 64, sprint_buffer
    STRCPY_CALL %1, sprint_buffer, 64
    call sprint
%endmacro

%macro SPRINT_IMPL 0
    jmp init_SYS_WRITE
sprint:
    push eax
    push ebx
    push ecx
    push edx

    SLEN_CALL sprint_buffer
    push eax; save slen

    mov eax, 4
    mov ebx, 1
    mov ecx, sprint_buffer
    pop edx; get slen
    int 0x80

    pop edx; pop in the opposite order
    pop ecx
    pop ebx
    pop eax
    ret
%endmacro

;return sys_write buffer
%macro SYS_WRITE_CALL 0
    call sys_write
%endmacro

%macro SYS_WRITE_IMPL 0
    jmp init_IS_NUMERIC
sys_write:
    push eax
    push ebx
    push ecx
    push edx
    push esi

    EMPTY_BUFFER_CALL 64, sys_write_buffer
    mov eax, 3
    mov ebx, 0
    mov ecx, sys_write_buffer
    mov edx, 64
    int 0x80

    ;Remove LF
    SLEN_CALL sys_write_buffer
    mov esi, sys_write_buffer
    mov byte[esi + eax - 1], 0; replace LF with 0

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
%endmacro

;return (DoubleWord eax: status code)
%macro IS_NUMERIC_CALL 1; (p_str)
    push esi
    mov esi, %1
    call is_numeric
    pop esi
%endmacro

%macro IS_NUMERIC_IMPL 0;
    jmp init_REGISTER_USER
is_numeric:
    push ecx; counter
    mov eax, 0
    mov ecx, 0
%%loop:
    cmp byte[esi + ecx], 0
    je %%check
    cmp byte[esi + ecx], 48
    jb %%invalid
    cmp byte[esi + ecx], 57
    ja %%invalid
    inc ecx
    jmp %%loop
%%check:
    cmp ecx, 0; p_str* = 0 check
    je %%invalid
    jmp %%valid
%%invalid:
    SPRINT_CALL is_not_numeric_msg
    mov eax, 1; status code
    jmp %%done
%%valid:
    SPRINT_CALL is_numeric_msg
    jmp %%done
%%done:
    pop ecx
    ret
%endmacro
; return DoubleWord eax: status code
%macro REGISTER_USER_CALL 0
    call register_user
%endmacro

%macro REGISTER_USER_IMPL 2; (DoubleWord p_users, DoubleWord p_user_num)
    jmp init_REGISTER_BOOK
register_user:
    push esi; p_users
    push ecx; p_user_num
    push edx; temp1
    push ebx; temp2
    mov esi, %1
    movzx ecx, byte[%2]
    mov edx, ecx
    imul edx, USER_SIZE
    add esi, edx

    ;ID
    inc ecx; new id
    mov [%2], cl; Update user_count
    mov byte[esi], cl; Save ID in the record

    ;name
    SPRINT_CALL user_name_prompt
    SYS_WRITE_CALL
    SLEN_CALL sys_write_buffer
    cmp eax, 15
    ja %%invalid_user_name
    lea ebx, [esi+1]
    STRCPY_CALL sys_write_buffer, ebx, 16

    ;pass
    SPRINT_CALL user_pass_prompt
    SYS_WRITE_CALL
    VALIDATE_PASSWORD_CALL sys_write_buffer
    cmp eax, 0
    jne %%invalid_user_password
    SLEN_CALL sys_write_buffer
    cmp eax, 15
    ja %%invalid_user_password
    lea ebx, [esi+17]
    STRCPY_CALL sys_write_buffer, ebx, 16

    ;address
    SPRINT_CALL user_address_prompt
    SYS_WRITE_CALL
    SLEN_CALL sys_write_buffer; length check
    cmp eax, 31
    ja %%invalid_user_address
    lea ebx, [esi+33]
    STRCPY_CALL sys_write_buffer, ebx, 32

    ;user_type
    SPRINT_CALL user_type_prompt
    SYS_WRITE_CALL
    SLEN_CALL sys_write_buffer
    cmp eax, 2
    jae %%invalid_user_type
    cmp byte[sys_write_buffer], '0'
    je %%correct_user_type
    cmp byte[sys_write_buffer], '1'
    je %%correct_user_type
    jmp %%invalid_user_type
%%correct_user_type:
    lea ebx, [esi+65]
    ;DEBUG4
    mov eax, sys_write_buffer
    cmp byte[sys_write_buffer], '0'
    mov byte[ebx], 0x00
    cmp byte[sys_write_buffer], '1'
    mov byte[ebx], 0x01

    jmp %%success
%%invalid_user_name:
    SPRINT_CALL invalid_user_name
    jmp %%failed
%%invalid_user_password:
    SPRINT_CALL invalid_user_password
    jmp %%failed
%%invalid_user_type:
    SPRINT_CALL invalid_user_type
    jmp %%finished
%%invalid_user_address:
    SPRINT_CALL invalid_user_address
    jmp %%failed
%%failed:
    SPRINT_CALL authtication_failed
    mov eax,  1
    jmp %%finished
%%success:
    SPRINT_CALL registered_user
    mov eax, 0
    jmp %%finished
%%finished:
    pop ebx
    pop edx
    pop ecx
    pop esi
    ret
%endmacro

; return DoubleWord eax: status code
%macro REGISTER_BOOK_CALL 0
    call register_book
%endmacro

%macro REGISTER_BOOK_IMPL 2; (DoubleWord p_books, DoubleWord p_book_num)
    jmp init_SEARCH_BOOK
register_book:
    push esi; p_books
    push ecx; p_book_num
    push edx; temp1
    push ebx; temp2
    mov esi, %1
    movzx ecx, byte[%2]
    mov edx, ecx
    imul edx, BOOK_SIZE
    add esi, edx

    ;ID
    inc ecx; new id
    mov [%2], cl
    mov byte[esi], cl

    ;title
    SPRINT_CALL book_title_prompt
    SYS_WRITE_CALL
    SLEN_CALL sys_write_buffer
    cmp eax, 31
    ja %%invalid_book_title
    lea ebx, [esi+1]
    STRCPY_CALL sys_write_buffer, ebx, 32

    ;author
    SPRINT_CALL book_author_prompt
    SYS_WRITE_CALL
    SLEN_CALL sys_write_buffer
    cmp eax, 19
    ja %%invalid_book_author
    lea ebx, [esi+33]
    STRCPY_CALL sys_write_buffer, ebx, 20

    ;stock
    SPRINT_CALL book_stock_prompt
    SYS_WRITE_CALL
    SLEN_CALL sys_write_buffer; length check
    cmp eax, 1
    ja %%invalid_book_stock
    ; Numeric char check
    IS_NUMERIC_CALL sys_write_buffer
    cmp eax, 0
    jne %%invalid_book_stock
    lea ebx, [esi+53]
    STRCPY_CALL sys_write_buffer, ebx, 2

    jmp %%success
%%invalid_book_title:
    SPRINT_CALL invalid_book_title
    jmp %%failed
%%invalid_book_author:
    SPRINT_CALL invalid_book_author
    jmp %%failed
%%invalid_book_stock:
    SPRINT_CALL invalid_book_stock
    jmp %%failed
%%failed:
    SPRINT_CALL book_registration_failed
    mov eax,  1
    jmp %%finished
%%success:
    SPRINT_CALL book_registration_success
    mov eax, 0
    jmp %%finished
%%finished:
    pop ebx
    pop edx
    pop ecx
    pop esi
    ret
%endmacro

;return (DoubleWord eax: len)
%macro SLEN_CALL 1; (p_str)
    EMPTY_BUFFER_CALL 64, slen_buffer
    STRCPY_CALL %1, slen_buffer, 64
    call strlen
%endmacro

%macro SLEN_IMPL 0
    jmp init_strcmp
strlen:
    push ecx
    mov ecx, 0; init counter
%%nextChar:
    mov eax, slen_buffer
    cmp byte[slen_buffer + ecx], 0
    jz %%finished
    inc ecx
    jmp %%nextChar
%%finished:
    mov eax, ecx
    pop ecx
    ret
%endmacro


; DoubleWord eax: status code
%macro SEARCH_BOOK_CALL 0
    EMPTY_BUFFER_CALL 64, search_book_buffer
    SPRINT_CALL book_title_prompt
    SYS_WRITE_CALL
    call search_book
%endmacro

%macro SEARCH_BOOK_IMPL 2; (p_books, p_book_num)
    jmp init_LEND_BOOK
search_book:
    push esi; p_books
    push ebx; counter
    push ecx; p_book_num
    push edx; temp
    mov esi, %1
    mov ebx, 0; init counter
    mov ecx, [%2]; book num
%%loop:
    cmp ebx, ecx
    jg %%not_found
    STRCMP_CALL [ecx+1], search_book_buffer
    cmp eax, 0
    je %%found
    add ecx, BOOK_SIZE
    inc ebx
    jmp %%loop
%%not_found:
    mov eax, 1
    SPRINT_CALL book_not_found
    jmp %%finished
%%found:
    mov eax, 0
    SPRINT_CALL book_found
    jmp %%finished
%%finished:
    pop edx
    pop ecx
    pop ebx
    pop esi
    ret
%endmacro

%macro LEND_BOOK_CALL 0
    EMPTY_BUFFER_CALL 64, search_book_buffer
    SPRINT_CALL book_title_prompt
    SYS_WRITE_CALL
    call lend_book
%endmacro

%macro LEND_BOOK_IMPL 2; (p_books, p_book_num)
    jmp init_system
lend_book:
    push esi; p_books
    push ebx; counter
    push ecx; p_book_num
    push edx; temp
    mov esi, %1
    mov ebx, 0; init counter
    mov ecx, [%2]; book num
%%loop:
    cmp ebx, ecx
    jg %%not_found
    STRCMP_CALL [ecx+1], search_book_buffer
    cmp eax, 0
    je %%found
    add ecx, BOOK_SIZE
    inc ebx
    jmp %%loop
%%not_found:
    mov eax, 1
    SPRINT_CALL book_not_found
    jmp %%finished
%%found:
    mov eax, 0
    SPRINT_CALL book_found
    dec byte[ecx+53]
    jmp %%finished
%%finished:
    pop edx
    pop ecx
    pop ebx
    pop esi
    ret
%endmacro

struc User
    .id         resb 1; byte
    .name       resb 16; str
    .pass       resb 16; str
    .address    resb 32; str
    .user_type  resb 1; byte
endstruc

struc Book
    .id         resb 1; byte
    .title      resb 32; str
    .author     resb 20; str
    .stock      resb 1; byte
endstruc

section .data
    ; System Info
    user_count db 0; init with 0x00 1byte 0-256
    book_count db 0; init with 0x00
    BUFFER_SIZE equ 64
    ; Struct Size
    USER_SIZE equ 66
    BOOK_SIZE equ 54

    staff_menu db 0x0A, "Staff Menu", 0x0A, "1. Register Book", 0x0A, "2. Register User", 0x0A, "3. Search Book", 0x0A, "4. Lend Book", 0x0A, "5. Exit", 0x0A, "Option: ", 0x00
               
    customer_menu db 0x0A, "Customer Menu", 0x0A, "1. Search Book", 0x0A, "2. Exit", 0x0A, "Option: ", 0x00
    
    ; Lend Book Msgs
    book_lent db "Book lent successfully", 0x00
    no_stock db "No stock available", 0x00
    
    ; Book Search Msgs
    search_prompt db "Search term: ", 0x00
    results_header db "Search Results:", 0x00
    newline db 0x00
    separator db ": ", 0x00
    by_text db " by ", 0x00
    stock_text db " (Stock: ", 0x00
    closing_paren db ")", 0x00
    book_not_found db "Book not found...", 0
    book_found db "Book found...", 0

;---------------------------------------------------------------------------
    ;utils msg
    ; IS_NUMERIC
    is_numeric_msg db "The string is numeric chars!", 0x0A, 0
    is_not_numeric_msg db "The string is not numeric!", 0x0A, 0

;---------------------------------------------------------------------------
    ;init_system
    welcome_msg db "Library Management System", 0x0A, 0
    reg_master db "Register Master Account", 0Ah, 0
    reg_customer db "Register Customer Account", 0Ah, 0
    reg_sample_book db "Create 2 sample book records", 0Ah, 0
    
;---------------------------------------------------------------------------
    ;Validate Pass
    has_no_capical db "No Capital Letters!", 0x0A, 0
    has_capital db "Password has capital letter!", 0x0A, 0
    has_8words db "Password is more than 8 chars!", 0x0A, 0
    has_no_8words db "Password is no more than 8 chars...", 0x0A, 0

;---------------------------------------------------------------------------
    ;Register User
    user_name_prompt db "Name: ", 0x00
    user_pass_prompt db "Password (min 8 chars, 1+ uppercase): ", 0x00
    user_address_prompt db "Address: ", 0x00
    user_type_prompt db "User type (0:Customer, 1:Staff): ", 0x00

    registered_user db "User has been registered successfully!", 0x0A, 0
    authtication_failed db "Authentication failed...", 0x0A, 0
    invalid_user_type db "Enter valid user type... (0 or 1)", 0x0A, 0
    invalid_user_name db "Enter valid username... (less than 16 letters)", 0x0A, 0
    invalid_user_password db "Enter valid password... (less than 16 letters)", 0x0A, 0
    invalid_user_address db "Enter valid address... (less than 32 letters)", 0x0A, 0

;---------------------------------------------------------------------------
    ;Register Book
    book_title_prompt db "Title: ", 0x00
    book_author_prompt db "Author: ", 0x00
    book_stock_prompt db "Stock: ", 0x00

    registered_book db "Book has been registered successfully!", 0x0A, 0
    invalid_book_title db "Enter valid book title... (less than 32 letters)", 0x0A, 0
    invalid_book_author db "Enter valid book author... (less than 20 letters)", 0x0A, 0
    invalid_book_stock db "Enter valid book stock... (numberic chars & less than 10)", 0x0A, 0
    book_registration_failed db "Book registration failed...", 0x0A, 0
    book_registration_success db "Book registration Success!", 0x0A, 0

;---------------------------------------------------------------------------
    ;Login
    login_prompt db "Login first!", 0x0A, 0
    match_msg db "Username and Password matched!", 0x0A, 0
    not_match_msg db "Username and Password did't match!", 0x0A, 0
    invalid_username_password_msg db "Invalid input! (Username, Password must be less than 20 letters!)", 0x0A, 0
    try_again_msg db "Try again...", 0x0A, 0
section .bss
    ; Define Database
    users resb USER_SIZE * 16; Reserve sizeof(array of User of size 16)
    books resb BOOK_SIZE * 16

    username resb 20
    password resb 20

    reg_user_buffer resb 64
    strcpy_buffer resb 64
    sprint_buffer resb 64
    itoa_buffer resb 64
    slen_buffer resb 64
    sys_write_buffer resb 64
    search_book_buffer resb 64
    lend_book_buffer resb 64
    general_purpose_buffer resb 64
section .text
    global _start

_start:
    ; jmp init
init_EMPTY_BUFFER:
    EMPTY_BUFFER_IMPL
init_STRCPY:
    STRCPY_IMPL
init_ITOA:
    ITOA_IMPL
init_ATOI:
    ATOI_IMPL
init_VALIDATE_PASSWORD:
    VALIDATE_PASSWORD_IMPL
init_AUTHENTICATE:
    AUTHENTICATE_IMPL users
init_slen:
    SLEN_IMPL
init_strcmp:
    STRCMP_IMPL
init_SPRINT:
    SPRINT_IMPL
init_SYS_WRITE:
    SYS_WRITE_IMPL
init_IS_NUMERIC:
    IS_NUMERIC_IMPL
init_REGISTER_USER:
    REGISTER_USER_IMPL users, user_count
init_REGISTER_BOOK:
    REGISTER_BOOK_IMPL books, book_count
init_SEARCH_BOOK:
    SEARCH_BOOK_IMPL books, book_count
init_LEND_BOOK:
    LEND_BOOK_IMPL books, book_count
init_system:
    ; system init
    SPRINT_CALL welcome_msg
register_master:
    SPRINT_CALL reg_master
    REGISTER_USER_CALL
    cmp eax, 0
    jne register_master
    ; jmp DEBUG
; DEBUG:
;     mov esi, users
;     mov eax, 0
; register_customer:
;     SPRINT_CALL reg_customer
;     REGISTER_USER_CALL
;     cmp eax, 0
;     jne register_customer
; register_sample_book:
;     mov ecx, 0
;     mov edx, 2; Repeat twice
; .loop:
;     SPRINT_CALL reg_sample_book
;     REGISTER_BOOK_CALL
;     cmp eax, 0
;     jne .loop
;     inc ecx
;     cmp ecx, edx
;     jne .loop



login:
    SPRINT_CALL login_prompt
    SPRINT_CALL user_name_prompt
    SYS_WRITE_CALL
    SLEN_CALL sys_write_buffer
    cmp eax, 19
    ja .invalid
    STRCPY_CALL sys_write_buffer, username, 20
    SPRINT_CALL user_pass_prompt
    SYS_WRITE_CALL
    SLEN_CALL sys_write_buffer
    cmp eax, 20
    ja .invalid
    STRCPY_CALL sys_write_buffer, password, 20
    AUTHENTICATE_CALL username, password
    cmp eax, 0
    jne .not_match
    jmp .valid
.invalid:
    SPRINT_CALL invalid_username_password_msg
    SPRINT_CALL try_again_msg
    ;DEBUG
    mov esi, users
    mov ebx, [esi+2]
    SPRINT_CALL ebx
    mov ebx, [esi+18]
    SPRINT_CALL ebx
    mov ebx, [esi+34]
    SPRINT_CALL ebx
    mov ebx, [esi+66]
    SPRINT_CALL ebx

    jmp login
.not_match:
    SPRINT_CALL not_match_msg
    SPRINT_CALL try_again_msg
    jmp login
.valid
    SPRINT_CALL match_msg







; .staff_menu:
;     SPRINT_CALL staff_menu
;     SYS_WRITE_CALL
;     STRCMP_CALL sys_write_buffer, '0'
;     je quit
;     STRCMP_CALL sys_write_buffer, '1'
;     je .register_user
;     STRCMP_CALL sys_write_buffer, '2'
;     je .register_book
;     STRCMP_CALL sys_write_buffer, '3'
;     je .search_book
;     STRCMP_CALL sys_write_buffer, '4'
;     je .lend_book

; .register_user:
;     REGISTER_USER_CALL
;     jmp .staff_menu
; .register_book:
;     REGISTER_BOOK_CALL
;     jmp .staff_menu
; .search_book:
;     SEARCH_BOOK_CALL
;     jmp .staff_menu
; .lend_book:
;     LEND_BOOK_CALL
;     jmp .staff_menu
quit:
    mov eax, 1
    xor ebx, ebx
    int 0x80