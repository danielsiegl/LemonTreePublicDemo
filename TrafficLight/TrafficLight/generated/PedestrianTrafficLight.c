/* Model File: PedestrianTrafficLight
 * Model Path: C:\LemonTreeTestData\LemonTreePublicDemo\TrafficLight\TrafficLight.eap
 * 
 * Author: rdeininger 
 * Date: 2021-10-12 07:53:42
 * 
 * Notes: 
 *  */
#include "PedestrianTrafficLight.h"

/* Implements REQ:Pedestrian Traffic Light Transitions:{B237CF0F-6975-48a8-97D8-81A8A739E7FD} */

/* Statically allocated instance. Automatically added and generated. */
PedestrianTrafficLight PedestrianTrafficLight_me;

/* Returns a pointer to the statically allocated structure for PedestrianTrafficLight.
 * Automatically added and generated.
 * @return Pointer to the statically allocated structure for PedestrianTrafficLight. */
PedestrianTrafficLight* PedestrianTrafficLight_new(void)
{
    return &PedestrianTrafficLight_me;
}

/* Name:		PedestrianSM
 * Returns: 	bool
 * Parameters:	const PedestrianTrafficLight* me, const PedestrianTrafficLight_PedestrianSM_STM* stm,  Signals msg
 *  */
bool PedestrianTrafficLight_PedestrianSM(PedestrianTrafficLight* const me, PedestrianTrafficLight_PedestrianSM_STM* const stm, /*  Pointer to the current state machine instance */
                                         Signals msg /*  Signal for the state machine */
                                         )
{
    bool evConsumed = !1; /* Indicates if the event has already been consumed */
    switch (stm->mainState.activeSubState)
    {
    case PedestrianTrafficLight_PedestrianSM_Green:

        if (msg == CarTrafficGo)
        {
            evConsumed = !0;
            /* From 'Green' to 'Red' */
            stm->mainState.activeSubState = PedestrianTrafficLight_PedestrianSM_Red;
            printf("Pedestrian: Red\r\n");
            /* end of entry actions for state Red */
        }
        break;
    case PedestrianTrafficLight_PedestrianSM_Red:

        if (msg == CarTrafficStop)
        {
            evConsumed = !0;
            /* From 'Red' to 'Green' */
            stm->mainState.activeSubState = PedestrianTrafficLight_PedestrianSM_Green;
            printf("Pedestrian: Green\r\n");
            /* end of entry actions for state Green */
        }
        break;
    default:
        break;
    }
    return evConsumed;
}

/* Name:		PedestrianSM_init
 * Returns: 	void
 * Parameters:	const PedestrianTrafficLight* me, const PedestrianTrafficLight_PedestrianSM_STM* stm
 *  */
void PedestrianTrafficLight_PedestrianSM_init(PedestrianTrafficLight* const me, PedestrianTrafficLight_PedestrianSM_STM* const stm /*  Pointer to the current state machine instance */
                                              )
{
    /* State: Green */
    stm->Green.activeSubState = PedestrianTrafficLight_PedestrianSM_NOSTATE;
    /* State: Red */
    stm->Red.activeSubState = PedestrianTrafficLight_PedestrianSM_NOSTATE;

    /* From 'Initial' to 'Red' */
    stm->mainState.activeSubState = PedestrianTrafficLight_PedestrianSM_Red;
    printf("Pedestrian: Red\r\n");
    /* end of entry actions for state Red */
}

/* Name:		PedestrianTrafficLight
 * Returns: 	
 * Parameters:	const PedestrianTrafficLight* me,  void (*i_sigHandler)(Signals)
 *  */
void PedestrianTrafficLight_PedestrianTrafficLight(PedestrianTrafficLight* const me, void (*i_sigHandler)(Signals) /*  pointer to send signal handler */
                                                   )
{
    /* SyncableUserCode{BA2D3C11-E901-47af-A638-3AD544794D71}:E0Lpugjlll */
    me->sigHandler = i_sigHandler;
    /* SyncableUserCode{BA2D3C11-E901-47af-A638-3AD544794D71} */
    /* Call init function of stm PedestrianSM for instance PedestrianSM */
    PedestrianTrafficLight_PedestrianSM_init(me, &(me->PedestrianSM));
}

