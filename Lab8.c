// Lab8.c
// Runs on LM4F120 or TM4C123
// Raiyan Chowdhury, Timberlon Gray
// Last modification date: change this to the last modification date or look very silly
// Last Modified: 4/5/2016 

// Analog Input connected to PE2=ADC1
// displays on Sitronox ST7735
// PF3, PF2, PF1 are heartbeats

#include <stdint.h>

#include "ST7735.h"
#include "TExaS.h"
#include "ADC.h"
#include "print.h"
#include "tm4c123gh6pm.h"

//*****the first three main programs are for debugging *****
// main1 tests just the ADC and slide pot, use debugger to see data
// main2 adds the LCD to the ADC and slide pot, ADC data is on Nokia
// main3 adds your convert function, position data is no Nokia

void DisableInterrupts(void); // Disable interrupts
void EnableInterrupts(void);  // Enable interrupts

#define PF1       (*((volatile uint32_t *)0x40025008))
#define PF2       (*((volatile uint32_t *)0x40025010))
#define PF3       (*((volatile uint32_t *)0x40025020))
#define	fresh	1
#define	stale	0

// Initialize Port F so PF1, PF2 and PF3 are heartbeats
void PortF_Init(void){ uint32_t volatile delay;
	SYSCTL_RCGCGPIO_R |= 0x20;
	delay = SYSCTL_RCGCGPIO_R;
	GPIO_PORTF_DIR_R |= 0x0E;
	GPIO_PORTF_AFSEL_R &= ~0x0E;
	GPIO_PORTF_DEN_R |= 0x0E;
}
uint32_t Data;        // 12-bit ADC
uint32_t Position;    // 32-bit fixed-point 0.001 cm
uint32_t ADCMail;
uint8_t ADCStatus;
int main1(void){      // single step this program and look at Data
  TExaS_Init();       // Bus clock is 80 MHz 
  ADC_Init();         // turn on ADC, set channel to 1
  while(1){                
    Data = ADC_In();  // sample 12-bit channel 1
  }
}

int main2(void){
  TExaS_Init();       // Bus clock is 80 MHz 
  ADC_Init();         // turn on ADC, set channel to 1
  ST7735_InitR(INITR_REDTAB); 
  PortF_Init();
  while(1){           // use scope to measure execution time for ADC_In and LCD_OutDec           
    PF2 = 0x04;       // Profile ADC
    Data = ADC_In();  // sample 12-bit channel 1
    PF2 = 0x00;       // end of ADC Profile
    ST7735_SetCursor(0,0);
    PF1 = 0x02;       // Profile LCD
    LCD_OutDec(Data); 
    ST7735_OutString("    ");  // these spaces are used to coverup characters from last output
    PF1 = 0;          // end of LCD Profile
  }
}

uint32_t Convert(uint32_t input){
  return (222*input)/500 + 74;	//0.4437*input + 74.02
  // more accurate in the middle, less accurate at ends: 0.3828*input + 207 --> (98*input)/256 + 207
}
int main3(void){ 
  TExaS_Init();         // Bus clock is 80 MHz 
  ST7735_InitR(INITR_REDTAB); 
  PortF_Init();
  ADC_Init();         // turn on ADC, set channel to 1
  while(1){  
    PF2 ^= 0x04;      // Heartbeat
    Data = ADC_In();  // sample 12-bit channel 1
    PF3 = 0x08;       // Profile Convert
    Position = Convert(Data); 
    PF3 = 0;          // end of Convert Profile
    PF1 = 0x02;       // Profile LCD
    ST7735_SetCursor(0,0);
    LCD_OutDec(Data); ST7735_OutString("    "); 
    ST7735_SetCursor(6,0);
    LCD_OutFix(Position);
    PF1 = 0;          // end of LCD Profile
  }
}   

void SysTick_Handler(void){
	PF1 ^= 0x02;
	PF1 ^= 0x02;
	ADCMail = ADC_In();
	ADCStatus = fresh;
	PF1 ^= 0x02;
}

void SysTick_Init(uint32_t period){
	NVIC_ST_CTRL_R = 0;
	NVIC_ST_RELOAD_R = period - 1;
	NVIC_ST_CURRENT_R = 0;
	NVIC_SYS_PRI3_R = (NVIC_SYS_PRI3_R&0x00FFFFFF)|0x40000000;
	NVIC_ST_CTRL_R = 0x00000007;
	EnableInterrupts();
}

int main(void){
	TExaS_Init();
	ST7735_InitR(INITR_REDTAB);
	PortF_Init();
	ADC_Init();
  SysTick_Init(2000000);	// (25ms)*80,000 = 2,000,000
  
  while(1){
		while(ADCStatus == stale){}
		ADCStatus = stale;
    ST7735_SetCursor(6,0);
    LCD_OutFix(Convert(ADCMail));	ST7735_OutString(" cm");
  }
}

