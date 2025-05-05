;
; TrafficLightSystem.asm
;
; Created: 4/16/2025 3:13:13 PM
; Author : Lillianmay Lancour
;
;Design and implement a traffic light control system for a single-lane 
;roadway using AVR assembly language. 
;The system must include realistic light sequencing 
;(Red ? Green ? Yellow), 
;respond to a crosswalk button, and manage LED indicators for vehicle 
;and pedestrian traffic. 

;Smart Yellow Timing: When a crosswalk
;------------------------------------------------------------
;led pin assignments
;north to south
.equ NS_RED = 4               ;PB4 (12)
.equ NS_YELLOW = 3            ;PB3 (11)
.equ NS_GREEN = 2             ;PB2 (10)
;east to west
.equ EW_RED = 7               ;PD7 (7)
.equ EW_YELLOW = 0            ;PB0 (8)
.equ EW_GREEN = 1             ;PB1 (9)

;button pin assignments
.equ BTN_NS = 4               ;PD4 - pull up   
.equ BTN_EW = 2               ;PD2 - high impedence button       
;crosswalk led assignments
.equ WALK_LED_NS = 5          ;PB5 (D13)
.equ WALK_LED_EW = 6          ;PD6 (D6)


;delay constants (in sec)
.equ GREEN_TIME = 5
.equ YELLOW_TIME = 2
.equ WALK_TIME = 6            ;on for 4 seconds, blink for last 2 sec

;timer values for 1s delay in timer 1
;1sec = 1000000 microseconds  
;prescalar = 256 (1024 would work too)
;CTC mode           OCR1A: 62499 , OCR1AH = 0xF4 , OCR1AL = 0x23
;Normal mode        TCNT1: 3036 , TCNT1H = 0x0B , TCNT1L = 0xDC
.equ COMPARE_MATCH = 62499

;state of lights
.equ NS_GREEN_PHASE = 0
.equ NS_YELLOW_PHASE = 1
.equ ALL_RED_PHASE_1 = 2
.equ EW_GREEN_PHASE = 3
.equ EW_YELLOW_PHASE = 4
.equ ALL_RED_PHASE_2 = 5

;definitions to give our registers meaning
.def state = r16              ;traffic light state
.def delay_counter = r17      ;general timing
.def temp = r18               ;temporary register
.def walk_flag_ns = r19       ;flag for main crosswalk
.def walk_flag_ew = r20       ;flag for second crosswalk


.def blink_counter = r21      ;countdown for blinking walk led

;Vector Table
;------------------------------------------------------------
.org 0x0000                   ; Reset Vector
          jmp       main

.org OC1Aaddr                 ;timer/Counter1 Compare Match A
          jmp      tmr1_isr
           
                    
.org INT_VECTORS_SIZE         ; End Vector Table

main:
;one time configuration 
;------------------------------------------------------------

;set LED pins to output

          sbi       DDRB, NS_RED
          sbi       DDRB, NS_GREEN
          sbi       DDRB, NS_YELLOW

          sbi       DDRD, EW_RED
          sbi       DDRB, EW_GREEN
          sbi       DDRB, EW_YELLOW

;cross walk lights
          sbi       DDRB, WALK_LED_NS
          sbi       DDRD, WALK_LED_EW

;set button pins as input
          cbi       DDRD, BTN_NS        ;pull - up
          sbi       PORTD, BTN_NS       ;enable pull up resistor 

          cbi       DDRD, BTN_EW        ;no pull up for EW button its floating
    
;clear flags
          clr       walk_flag_ns
          clr       walk_flag_ew
          clr       state

          ldi       delay_counter, GREEN_TIME     ;start with NS green



;timer 1 in ctc mode with 1 second delay

          clr       temp
          sts       TCNT1H,temp
          sts       TCNT1L,temp


          ;set compare match value
          ldi       temp,HIGH(COMPARE_MATCH)
          sts       OCR1AH,temp
          ldi       temp,LOW(COMPARE_MATCH)
          sts       OCR1AL,temp
          clr       temp
          sts       TCCR1A, temp
;enable compare match interupt for timer 1
          ldi       temp,(1<<WGM12)|(1<<CS12)     ;ctc mode with prescalar 256
          sts       TCCR1B, temp

          ldi       temp,(1<<OCIE1A)
          sts       TIMSK1,temp
          
          
          sei       ;global interupts enabled
           

main_loop:
;scanning not interupting 
          ;check NS walk button
          sbis      PIND, BTN_NS
          ldi       walk_flag_ns, 1
          ;check EW walk button
          sbic      PIND, BTN_EW
          ldi       walk_flag_ew,1


          rjmp      main_loop

  
tmr1_isr:
          dec       delay_counter       ;decrement every second
          brne      end_timer1_isr      ;still counting down dont switch yet
          ;advance the light state
          rcall     update_traffic_lights         

end_timer1_isr:
          clr       temp
          sts       TCNT1H,temp
          sts       TCNT1L,temp
          reti



;function to update trafic lights  
;------------------------------------------------------------
update_traffic_lights:
          rcall     clear_lights        ;clear all lights

          ;select based on state
          ;ns green phase
          cpi       state, NS_GREEN_PHASE
          breq      ns_green_
          ;ns yellow phase
          cpi       state, NS_YELLOW_PHASE
          breq      ns_yellow_
          ;ns red phase
          cpi       state, ALL_RED_PHASE_1
          breq      all_red_1

          ;ew green phase
          cpi       state, EW_GREEN_PHASE
          breq      ew_green_
          ;ew yellow phase
          cpi       state, EW_YELLOW_PHASE
          breq      ew_yellow_
          ;ew red phase
          cpi       state, ALL_RED_PHASE_2
          breq      all_red_2

          ;fallback
          clr       state
          rjmp      ns_green_




;different cases for the lights
;------------------------------------------------------------
ns_green_:
          sbi       PORTB, NS_GREEN ;  2 = b10
          sbi       PORTD, EW_RED ; d7
          ldi       delay_counter, GREEN_TIME
          ldi       state, NS_YELLOW_PHASE
          ret
ns_yellow_:
          sbi       PORTB, NS_YELLOW ;11 = b3
          sbi       PORTD, EW_RED ; d7

          ;shorten if cross
          tst       walk_flag_ns
          breq      ns_normal_yellow   
          ldi       delay_counter, 1    ;1 sec for short time
          rjmp      ns_set_next
ns_normal_yellow:
          ldi       delay_counter, YELLOW_TIME
ns_set_next:
          ldi       state, ALL_RED_PHASE_1
          ret
all_red_1:
          sbi       PORTB, NS_RED
          sbi       PORTD, EW_RED
          ;NS walk light
          tst       walk_flag_ns
          breq      skip_ns_walk
          sbi       PORTB, WALK_LED_NS
          clr       walk_flag_ns
skip_ns_walk:
          ldi       delay_counter, WALK_TIME
          ldi       state, EW_GREEN_PHASE
          ret
ew_green_:
          sbi       PORTB, EW_GREEN ; 9 = b1
          sbi       PORTB, NS_RED ; 12 = b4
          ldi       delay_counter, GREEN_TIME
          ldi       state, EW_YELLOW_PHASE
          ret
ew_yellow_:
          sbi       PORTB, EW_YELLOW ; 8 = b0
          sbi       PORTB, NS_RED ; 12 = b4
          ;shorten if cross
          tst       walk_flag_ew
          breq      ew_normal_yellow   
          ldi       delay_counter, 1    ;1 sec for short time
          rjmp      ew_set_next
ew_normal_yellow:
          ldi       delay_counter, YELLOW_TIME
ew_set_next:
          ldi       state, ALL_RED_PHASE_2
          ret
all_red_2:
          sbi       PORTB, NS_RED
          sbi       PORTD, EW_RED
          ;EW walk light
          tst       walk_flag_ew
          breq      skip_ew_walk
          sbi       PORTD, WALK_LED_EW
          clr       walk_flag_ew
skip_ew_walk:
          ldi       delay_counter, WALK_TIME
          ldi       state, NS_GREEN_PHASE
          ret

clear_lights:
          ; clear NS lights (PB4, PB3, PB2)
          cbi       PORTB, NS_RED
          cbi       PORTB, NS_YELLOW
          cbi       PORTB, NS_GREEN
          ; clear EW lights (PB0, PB1, PD7)
          cbi       PORTB, EW_GREEN
          cbi       PORTB, EW_YELLOW
          cbi       PORTD, EW_RED

          cbi       PORTB, WALK_LED_NS
          cbi       PORTD, WALK_LED_EW
          ret




















