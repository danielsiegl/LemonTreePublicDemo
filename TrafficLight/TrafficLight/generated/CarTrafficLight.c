/* Model File: CarTrafficLight
 * Model Path: C:\LemonTreeTestData\LemonTreePublicDemo\TrafficLight\TrafficLight.eap
 * 
 * Author: rdeininger 
 * Date: 2021-10-07 15:14:55
 * 
 * Notes: 
 *  */
#include "CarTrafficLight.h"

/* Implements REQ:Car traffic light states:{81695243-BAA4-443e-915D-68C88569D2FB} */

/* Statically allocated instance. Automatically added and generated. */
CarTrafficLight CarTrafficLight_me;

/* Returns a pointer to the statically allocated structure for CarTrafficLight.
 * Automatically added and generated.
 * @return Pointer to the statically allocated structure for CarTrafficLight. */
CarTrafficLight* CarTrafficLight_new(void)
{
    return &CarTrafficLight_me;
}

/* Name:		CarTrafficSM
 * Returns: 	bool
 * Parameters:	const CarTrafficLight* me, const CarTrafficLight_CarTrafficSM_STM* stm,  Signals msg
 *  */
bool CarTrafficLight_CarTrafficSM(CarTrafficLight* const me, CarTrafficLight_CarTrafficSM_STM* const stm, /*  Pointer to the current state machine instance */
                                  Signals msg /*  Signal for the state machine */
                                  )
{
    bool evConsumed = !1; /* Indicates if the event has already been consumed */
    switch (stm->mainState.activeSubState)
    {
    case CarTrafficLight_CarTrafficSM_Green:

        if (FSM_checkTimeEvent(&(stm->Green), 6, TIME_SECONDS) != !1)
        {
            evConsumed = !0;
            /* From 'Green' to 'Yellow' */
            stm->mainState.activeSubState = CarTrafficLight_CarTrafficSM_Yellow;
            /* State: Yellow */
            stm->Yellow.startTime = FSM_getTime();
            printf("Cars: Yellow\r\n");
            /* end of entry actions for state Yellow */
        }
        break;
    case CarTrafficLight_CarTrafficSM_Red:

        if (FSM_checkTimeEvent(&(stm->Red), 7, TIME_SECONDS) != !1)
        {
            evConsumed = !0;
            /* From 'Red' to 'RedYellow' */
            stm->mainState.activeSubState = CarTrafficLight_CarTrafficSM_RedYellow;
            /* State: RedYellow */
            stm->RedYellow.startTime = FSM_getTime();
            printf("Cars: Red-Yellow\r\n");
            me->sigHandler(CarTrafficGo);
            /* end of entry actions for state RedYellow */
        }
        break;
    case CarTrafficLight_CarTrafficSM_RedYellow:

        if (FSM_checkTimeEvent(&(stm->RedYellow), 1, TIME_SECONDS) != !1)
        {
            evConsumed = !0;
            /* From 'RedYellow' to 'Green' */
            stm->mainState.activeSubState = CarTrafficLight_CarTrafficSM_Green;
            /* State: Green */
            stm->Green.startTime = FSM_getTime();
            printf("Cars: Green\r\n");
            /* end of entry actions for state Green */
        }
        break;
    case CarTrafficLight_CarTrafficSM_Yellow:

        if (FSM_checkTimeEvent(&(stm->Yellow), 2, TIME_SECONDS) != !1)
        {
            evConsumed = !0;
            /* From 'Yellow' to 'Red' */
            stm->mainState.activeSubState = CarTrafficLight_CarTrafficSM_Red;
            /* State: Red */
            stm->Red.startTime = FSM_getTime();
            printf("Cars: Red\r\n");
            me->sigHandler(CarTrafficStop);
            /* end of entry actions for state Red */
        }
        break;
    default:
        break;
    }
    return evConsumed;
}

/* Name:		CarTrafficSM_init
 * Returns: 	void
 * Parameters:	const CarTrafficLight* me, const CarTrafficLight_CarTrafficSM_STM* stm
 *  */
void CarTrafficLight_CarTrafficSM_init(CarTrafficLight* const me, CarTrafficLight_CarTrafficSM_STM* const stm /*  Pointer to the current state machine instance */
                                       )
{
    /* State: Green */
    stm->Green.activeSubState = CarTrafficLight_CarTrafficSM_NOSTATE;
    /* State: Red */
    stm->Red.activeSubState = CarTrafficLight_CarTrafficSM_NOSTATE;
    /* State: RedYellow */
    stm->RedYellow.activeSubState = CarTrafficLight_CarTrafficSM_NOSTATE;
    /* State: Yellow */
    stm->Yellow.activeSubState = CarTrafficLight_CarTrafficSM_NOSTATE;

    /* From 'Initial' to 'Red' */
    stm->mainState.activeSubState = CarTrafficLight_CarTrafficSM_Red;
    /* State: Red */
    stm->Red.startTime = FSM_getTime();
    printf("Cars: Red\r\n");
    me->sigHandler(CarTrafficStop);
    /* end of entry actions for state Red */
}

/* Name:		CarTrafficLight
 * Returns: 	
 * Parameters:	const CarTrafficLight* me,  void (*i_sigHandler)(Signals)
 *  */
void CarTrafficLight_CarTrafficLight(CarTrafficLight* const me, void (*i_sigHandler)(Signals) /*  pointer to send signal handler */
                                     )
{
    /* SyncableUserCode{569DDFFF-E41C-4619-ACDD-8ECD2B85DAEE}:E0Lpugjlll */
    me->sigHandler = i_sigHandler;
    /* SyncableUserCode{569DDFFF-E41C-4619-ACDD-8ECD2B85DAEE} */
    /* Call init function of stm CarTrafficSM for instance CarTrafficSM */
    CarTrafficLight_CarTrafficSM_init(me, &(me->CarTrafficSM));
}

