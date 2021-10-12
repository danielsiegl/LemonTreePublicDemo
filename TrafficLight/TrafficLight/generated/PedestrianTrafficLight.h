/* Model File: PedestrianTrafficLight
 * Model Path: C:\LemonTreeTestData\LemonTreePublicDemo\TrafficLight\TrafficLight.eap
 * 
 * Author: rdeininger 
 * Date: 2021-10-12 07:53:42
 * 
 * Notes: 
 *  */
#ifndef H_PEDESTRIANTRAFFICLIGHT
#define H_PEDESTRIANTRAFFICLIGHT

#include "FSM.h" /* Include for 'relation to classifier' 'FSM' */
#include "time.h" /* Include for 'relation to classifier' 'time' */
#include "stdio.h" /* Include for 'relation to classifier' 'stdio' */
#include "stdbool.h" /* Include for 'relation to classifier' 'stdbool' */
#include "windows.h" /* Include for 'relation to classifier' 'windows' */
#include "Signals.h" /* Include for signals */
/* Implements REQ:Pedestrian Traffic Light Transitions:{B237CF0F-6975-48a8-97D8-81A8A739E7FD} */

/* Enumeration defining all states of state machine PedestrianSM */
typedef enum {
    PedestrianTrafficLight_PedestrianSM_NOSTATE = 0, /* Explicit value specification added by code generator */

    PedestrianTrafficLight_PedestrianSM_Green,

    PedestrianTrafficLight_PedestrianSM_Red
} PedestrianTrafficLight_PedestrianSM_States;

typedef struct PedestrianTrafficLight_PedestrianSM_STMStruct
{

    FSM_STATE mainState;

    FSM_STATE Green;

    FSM_STATE Red;
} PedestrianTrafficLight_PedestrianSM_STM;

/* Name:		sigHandlerTarget_t
 * Returns: 	void
 * Parameters:	 Signals sig
 *  */
typedef void (*sigHandlerTarget_t)(Signals);

typedef struct PedestrianTrafficLightStruct
{

    sigHandlerTarget_t sigHandler;

    PedestrianTrafficLight_PedestrianSM_STM PedestrianSM;
} PedestrianTrafficLight;

/* Returns a pointer to the statically allocated structure for PedestrianTrafficLight.
 * Automatically added and generated.
 * @return Pointer to the statically allocated structure for PedestrianTrafficLight. */
PedestrianTrafficLight* PedestrianTrafficLight_new(void);

/* Name:		PedestrianSM
 * Returns: 	bool
 * Parameters:	const PedestrianTrafficLight* me, const PedestrianTrafficLight_PedestrianSM_STM* stm,  Signals msg
 *  */
bool PedestrianTrafficLight_PedestrianSM(PedestrianTrafficLight* const me, PedestrianTrafficLight_PedestrianSM_STM* const stm, /*  Pointer to the current state machine instance */
                                         Signals msg /*  Signal for the state machine */
                                         );

/* Name:		PedestrianSM_init
 * Returns: 	void
 * Parameters:	const PedestrianTrafficLight* me, const PedestrianTrafficLight_PedestrianSM_STM* stm
 *  */
void PedestrianTrafficLight_PedestrianSM_init(PedestrianTrafficLight* const me, PedestrianTrafficLight_PedestrianSM_STM* const stm /*  Pointer to the current state machine instance */
                                              );

/* Name:		PedestrianTrafficLight
 * Returns: 	
 * Parameters:	const PedestrianTrafficLight* me,  void (*i_sigHandler)(Signals)
 *  */
void PedestrianTrafficLight_PedestrianTrafficLight(PedestrianTrafficLight* const me, void (*i_sigHandler)(Signals) /*  pointer to send signal handler */
                                                   );

#endif /* #ifndef H_PEDESTRIANTRAFFICLIGHT */

