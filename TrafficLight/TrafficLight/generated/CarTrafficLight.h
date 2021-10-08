/* Model File: CarTrafficLight
 * Model Path: C:\LemonTreeTestData\LemonTreePublicDemo\TrafficLight\TrafficLight.eap
 * 
 * Author: rdeininger 
 * Date: 2021-10-07 15:14:55
 * 
 * Notes: 
 *  */
#ifndef H_CARTRAFFICLIGHT
#define H_CARTRAFFICLIGHT

#include "FSM.h" /* Include for 'relation to classifier' 'FSM' */
#include "time.h" /* Include for 'relation to classifier' 'time' */
#include "stdio.h" /* Include for 'relation to classifier' 'stdio' */
#include "stdbool.h" /* Include for 'relation to classifier' 'stdbool' */
#include "windows.h" /* Include for 'relation to classifier' 'windows' */
/* Implements REQ:Car traffic light states:{81695243-BAA4-443e-915D-68C88569D2FB} */

/* Enumeration defining all states of state machine CarTrafficSM */
typedef enum {
    CarTrafficLight_CarTrafficSM_NOSTATE = 0, /* Explicit value specification added by code generator */

    CarTrafficLight_CarTrafficSM_Green,

    CarTrafficLight_CarTrafficSM_Red,

    CarTrafficLight_CarTrafficSM_RedYellow,

    CarTrafficLight_CarTrafficSM_Yellow
} CarTrafficLight_CarTrafficSM_States;

typedef struct CarTrafficLight_CarTrafficSM_STMStruct
{

    FSM_STATE mainState;

    FSM_STATE Green;

    FSM_STATE Red;

    FSM_STATE RedYellow;

    FSM_STATE Yellow;
} CarTrafficLight_CarTrafficSM_STM;

/* Name:		sigHandler_t
 * Returns: 	int
 * Parameters:	 Signals sig
 *  */
typedef int (*sigHandler_t)(Signals);

typedef struct CarTrafficLightStruct
{

    sigHandler_t sigHandler;

    CarTrafficLight_CarTrafficSM_STM CarTrafficSM;
} CarTrafficLight;

/* Returns a pointer to the statically allocated structure for CarTrafficLight.
 * Automatically added and generated.
 * @return Pointer to the statically allocated structure for CarTrafficLight. */
CarTrafficLight* CarTrafficLight_new(void);

/* Name:		CarTrafficSM
 * Returns: 	bool
 * Parameters:	const CarTrafficLight* me, const CarTrafficLight_CarTrafficSM_STM* stm,  Signals msg
 *  */
bool CarTrafficLight_CarTrafficSM(CarTrafficLight* const me, CarTrafficLight_CarTrafficSM_STM* const stm, /*  Pointer to the current state machine instance */
                                  Signals msg /*  Signal for the state machine */
                                  );

/* Name:		CarTrafficSM_init
 * Returns: 	void
 * Parameters:	const CarTrafficLight* me, const CarTrafficLight_CarTrafficSM_STM* stm
 *  */
void CarTrafficLight_CarTrafficSM_init(CarTrafficLight* const me, CarTrafficLight_CarTrafficSM_STM* const stm /*  Pointer to the current state machine instance */
                                       );

/* Name:		CarTrafficLight
 * Returns: 	
 * Parameters:	const CarTrafficLight* me,  void (*i_sigHandler)(Signals)
 *  */
void CarTrafficLight_CarTrafficLight(CarTrafficLight* const me, void (*i_sigHandler)(Signals) /*  pointer to send signal handler */
                                     );

#endif /* #ifndef H_CARTRAFFICLIGHT */

