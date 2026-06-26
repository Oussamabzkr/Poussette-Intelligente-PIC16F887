; ================================================================== 
; PROJET : POUSSETTE INTELLIGENTE 
; ================================================================== 
LIST p=16f887 
INCLUDE "p16f887.inc" 
 
; ---- CONFIGURATION DES FUSIBLES ---- 
__CONFIG _CONFIG1, _LVP_OFF & _FCMEN_OFF & _IESO_OFF & _BOR_OFF & 
_CPD_OFF & _CP_OFF & _MCLRE_ON & _PWRTE_ON & _WDT_OFF & _HS_OSC 
__CONFIG _CONFIG2, _WRT_OFF & _BOR21V 
 
; ---- VARIABLES ---- 
CBLOCK 0x20 
    COMPTEUR_5S          ; Compteur pour les 5 secondes (50 boucles de 100ms) 
    VAR1, VAR2, VAR3     ; Variables pour les boucles de délai 
    REG_ADC              ; Valeur de la LDR (0-255) 
    FLAG_ETAT            ; Bit 0: 1=Poussette en marche, 0=Arrêtée 
ENDC 
 
ORG 0x0000 
    GOTO INITIALISATION 
 
; ================================================================== 
; SOUS-ROUTINE : DELAI DE 100 MILLISECONDES  
; ================================================================== 
DELAI_100MS: 
    MOVLW .2 
    MOVWF VAR3 
BOUCLE_EXT: 
    MOVLW .130 
    MOVWF VAR2 
BOUCLE_MID: 
    MOVLW .255 
    MOVWF VAR1 
BOUCLE_INT: 
    DECFSZ VAR1, F 
    GOTO BOUCLE_INT 
    DECFSZ VAR2, F 
    GOTO BOUCLE_MID 
    DECFSZ VAR3, F 
    GOTO BOUCLE_EXT 
    RETURN 
 
; ================================================================== 
; SOUS-ROUTINE : LECTURE DU CAPTEUR LDR 
; ================================================================== 
LECTURE_LDR: 
    BANKSEL ADCON0 
    BSF ADCON0, GO       ; Lancer la conversion Analogique/Numérique 
ATTENTE_ADC: 
    BTFSC ADCON0, GO 
    GOTO ATTENTE_ADC 
    MOVF ADRESH, W 
    MOVWF REG_ADC        ; Stocker le résultat (0 à 255) 
    RETURN 
 
 
 
; ================================================================== 
; SOUS-ROUTINE : ARRÊT TOTAL DES MOTEURS 
; ================================================================== 
ROUTINE_ARRET: 
    CLRF CCPR1L          ; PWM Gauche à 0% 
    CLRF CCPR2L          ; PWM Droite à 0% 
    MOVLW B'00000000' 
    MOVWF PORTD          ; Couper complètement les directions (L293D) 
    BCF PORTB, 7         ; Eteindre LED Vitesse Verte 
    BCF PORTB, 6         ; Eteindre LED Vitesse Rouge 
    RETURN 
 
; ================================================================== 
; INITIALISATION DU MICROCONTRÔLEUR 
; ================================================================== 
INITIALISATION: 
    BANKSEL TRISA 
    MOVLW B'00000001'    ; RA0 (AN0) en entrée (LDR) 
    MOVWF TRISA 
    CLRF TRISB           ; PORTB en sortie (LEDs et Buzzer) 
    CLRF TRISC           ; PORTC en sortie (PWM sur RC1, RC2) 
    MOVLW B'00000001'    ; RD0 entrée (Btn Droit), RD1-RD4 sorties (Moteurs) 
    MOVWF TRISD 
    MOVLW B'00000111'    ; RE0 (Btn Gauche), RE1 (ECHO), RE2 (IR) en entrées 
    MOVWF TRISE 
 
    BANKSEL ANSEL 
    MOVLW B'00000001'    ; AN0 Analogique 
    MOVWF ANSEL 
    CLRF ANSELH 
 
    BANKSEL ADCON1 
    CLRF ADCON1 
    BANKSEL ADCON0 
    MOVLW B'10000001' 
    MOVWF ADCON0 
 
    ; Configuration PWM Matériel 
    BANKSEL PR2 
    MOVLW .124 
    MOVWF PR2 
    BANKSEL T2CON 
    MOVLW B'00000110' 
    MOVWF T2CON 
    BANKSEL CCP1CON 
    MOVLW B'00001100' 
    MOVWF CCP1CON 
    MOVLW B'00001100' 
    MOVWF CCP2CON 
 
    BANKSEL PORTA 
    CLRF PORTC 
    CLRF PORTD 
    CLRF PORTB 
    CLRF FLAG_ETAT       ; Initialiser l'état de la poussette à l'arrêt 
 
 
 
 
 
; ================================================================== 
; BOUCLE PRINCIPALE 
; ================================================================== 
BOUCLE_PRINCIPALE: 
    ; 1. Sécurité Obstacle (Ultrason sur RE1) 
    BTFSC PORTE, 1 
    GOTO MODE_OBSTACLE 
 
    ; 2. Vérification Présence Parent (IR sur RE2) 
    BTFSC PORTE, 2 
    GOTO MARCHE_NORMALE 
 
    ; 3. Parent Absent ! 
    ; On vérifie si la poussette était en marche juste avant 
    BTFSC FLAG_ETAT, 0 
    GOTO DEBUT_COMPTE_5S     ; Elle était en marche, lancer le compte à rebours 
 
    ; Sinon, elle était déjà à l'arrêt, on maintient l'état 
    GOTO ETAT_ARRET 
 
MARCHE_NORMALE: 
    BSF FLAG_ETAT, 0     ; Mémoriser que la poussette est en mouvement 
    BCF PORTB, 3         ; Eteindre LED Rouge Parent 
    BSF PORTB, 4         ; Allumer LED Verte Parent 
    CALL GESTION_MOTEURS    ; Avancer normalement 
    GOTO BOUCLE_PRINCIPALE 
 
 
 
 
DEBUT_COMPTE_5S: 
    ; Le parent vient de disparaître : on maintient la LED Verte allumée 
    ; pendant les 5 secondes car la poussette roule encore. 
    BCF PORTB, 3         ; Assurer que la LED Rouge est éteinte 
    BSF PORTB, 4         ; Garder la LED Verte allumée 
    MOVLW .50            ; 50 x 100ms = 5 secondes 
    MOVWF COMPTEUR_5S 
 
BOUCLE_5S: 
    CALL GESTION_MOTEURS ; Continuer à faire rouler la poussette 
    CALL DELAI_100MS     ; Attendre 100ms 
     
    ; Vérifier si le parent est revenu 
    BTFSC PORTE, 2 
    GOTO MARCHE_NORMALE  ; Il est revenu ! Annuler le compte et continuer 
     
    ; Vérifier s'il y a un obstacle pendant le compte à rebours 
    BTFSC PORTE, 1 
    GOTO MODE_OBSTACLE 
     
    DECFSZ COMPTEUR_5S, F 
    GOTO BOUCLE_5S 
     
    ; Fin des 5 secondes sans retour du parent -> Arrêt effectif 
    GOTO ETAT_ARRET 
 
ETAT_ARRET: 
    BCF FLAG_ETAT, 0     ; Mémoriser que la poussette est arrêtée 
    BSF PORTB, 3         ; Allumer LED Rouge (Moteurs arrêtés, parent absent) 
    BCF PORTB, 4         ; Eteindre LED Verte 
    CALL ROUTINE_ARRET   ; Couper l'alimentation des moteurs 
    GOTO BOUCLE_PRINCIPALE 
 
MODE_OBSTACLE: 
    CALL ROUTINE_ARRET   ; Couper les moteurs immédiatement 
    BSF PORTB, 5         ; Allumer Buzzer 
     
    ; Délai 1 seconde (10 x 100ms) pour le buzzer 
    MOVLW .10 
    MOVWF COMPTEUR_5S 
BOUCLE_BUZZER: 
    CALL DELAI_100MS 
    DECFSZ COMPTEUR_5S, F 
    GOTO BOUCLE_BUZZER 
     
    BCF PORTB, 5         ; Eteindre Buzzer 
    GOTO BOUCLE_PRINCIPALE 
 
; ================================================================== 
; GESTION MOTEURS ET PWM 
; ================================================================== 
GESTION_MOTEURS: 
    ; --- A. CONTRÔLE DE LA DIRECTION --- 
    BTFSC PORTE, 0       ; Le bouton Gauche (RE0) est-il pressé (1) ? 
    GOTO BTN_GAUCHE_PRESSE 
    BTFSC PORTD, 0       ; Le bouton Droite (RD0) est-il pressé (1) ? 
    GOTO BTN_DROITE_SEUL 
     
    ; MARCHE AVANT LIGNE DROITE (Aucun bouton pressé) 
    MOVLW B'00001010'    ; RD1=1, RD2=0 (Gauche Avant) | RD3=1, RD4=0 (Droite 
Avant) 
    MOVWF PORTD 
    GOTO ADAPTE_VITESSE 
 
BTN_GAUCHE_PRESSE: 
    BTFSC PORTD, 0       ; Le bouton droit est-il AUSSI pressé ? 
    GOTO ARRET_CONFLIT   ; Oui -> Conflit -> Arrêt de sécurité 
     
    ; TOURNER À GAUCHE (Moteur Gauche à l'arrêt, Moteur Droit avance) 
    MOVLW B'00001000'    ; RD1=0, RD2=0 (Gauche STOP) | RD3=1, RD4=0 (Droite 
Avant) 
    MOVWF PORTD 
    GOTO ADAPTE_VITESSE 
 
BTN_DROITE_SEUL: 
    ; TOURNER À DROITE (Moteur Gauche avance, Moteur Droit à l'arrêt) 
    MOVLW B'00000010'    ; RD1=1, RD2=0 (Gauche Avant) | RD3=0, RD4=0 (Droite 
STOP) 
    MOVWF PORTD 
    GOTO ADAPTE_VITESSE 
 
ARRET_CONFLIT: 
    CALL ROUTINE_ARRET 
    RETURN 
 
ADAPTE_VITESSE: 
    ; --- B. LECTURE LDR ET SÉLECTION PWM --- 
    CALL LECTURE_LDR 
     
    MOVLW .240 
    SUBWF REG_ADC, W 
    BTFSC STATUS, C 
    GOTO VIT_7 
 
    MOVLW .200 
    SUBWF REG_ADC, W 
    BTFSC STATUS, C 
    GOTO VIT_6 
 
    MOVLW .160 
    SUBWF REG_ADC, W 
    BTFSC STATUS, C 
    GOTO VIT_5 
 
    MOVLW .130 
    SUBWF REG_ADC, W 
    BTFSC STATUS, C 
    GOTO VIT_4           ; Zone médiane 
 
    MOVLW .90 
    SUBWF REG_ADC, W 
    BTFSC STATUS, C 
    GOTO VIT_3 
 
    MOVLW .50 
    SUBWF REG_ADC, W 
    BTFSC STATUS, C 
    GOTO VIT_2 
 
    GOTO VIT_1           ; Si inférieur à 50 
 
VIT_7: 
    MOVLW .124 
    GOTO APPLIQUE_PWM 
VIT_6: 
    MOVLW .110 
    GOTO APPLIQUE_PWM 
VIT_5: 
    MOVLW .90 
    GOTO APPLIQUE_PWM 
VIT_4: 
    MOVLW .75            ; Vitesse Médiane (Croisière) 
    GOTO APPLIQUE_PWM 
VIT_3: 
    MOVLW .60 
    GOTO APPLIQUE_PWM 
VIT_2: 
    MOVLW .40 
    GOTO APPLIQUE_PWM 
VIT_1: 
    MOVLW .20            ; Vitesse très lente 
    GOTO APPLIQUE_PWM 
 
APPLIQUE_PWM: 
    MOVWF CCPR1L         ; Envoi au moteur Gauche (RC2) 
    MOVWF CCPR2L         ; Envoi au moteur Droit (RC1) 
 
    ; --- C. GESTION DES LEDS DE VITESSE --- 
    MOVLW .110 
    SUBWF REG_ADC, W 
    BTFSS STATUS, C      ; Si ADC < 110 
    GOTO LDR_BASSE 
 
    MOVLW .146 
    SUBWF REG_ADC, W 
    BTFSS STATUS, C      ; Si ADC entre 110 et 145 (Point mort) 
    GOTO LDR_MEDIANE 
 
    ; Si ADC >= 146 
    GOTO LDR_HAUTE 
 
LDR_BASSE: 
    BSF PORTB, 6         ; Allumer LED Rouge Vitesse (Ralentissement) 
    BCF PORTB, 7         ; Eteindre LED Verte 
    RETURN 
 
LDR_MEDIANE: 
    BCF PORTB, 6         ; Eteindre LED Rouge 
    BCF PORTB, 7         ; Eteindre LED Verte 
    RETURN 
 
LDR_HAUTE: 
    BCF PORTB, 6         ; Eteindre LED Rouge 
    BSF PORTB, 7         ; Allumer LED Verte Vitesse (Accélération) 
    RETURN 
 
END.