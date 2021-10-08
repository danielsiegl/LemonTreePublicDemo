/* Model File: FSM
 * Model Path: C:\LemonTreeTestData\LemonTreePublicDemo\TrafficLight\TrafficLight.eap
 * 
 * Author: wnesensohn 
 * Date: 2021-10-07 15:14:56
 * 
 * Notes: 
 *  */
#include "FSM.h"

/* Name:		checkTimeEvent
 * Returns: 	bool
 * Parameters:	 FSM_STATE* state,  long value,  time_units unit
 *  */
bool FSM_checkTimeEvent(FSM_STATE* state, long value, time_units unit)
{
    /* SyncableUserCode{2DD7EDAF-8F29-40e9-A161-84BCA0951049}:As2S68iI9d */
    unsigned long difference;
    unsigned long valueToCheck;

    difference = (FSM_getTime() - state->startTime);

    switch (unit)
    {
    case TIME_NANOSECONDS:
        valueToCheck = (unsigned long)(value / 10e8);
        break;
    case TIME_MICROSECONDS:
        valueToCheck = (unsigned long)(value / 10e5);
        break;
    case TIME_TICKS:
    case TIME_MILLISECONDS:
        valueToCheck = value / 10e2;
        break;
    case TIME_SECONDS:
        valueToCheck = (unsigned long)(value);
        break;
    case TIME_MINUTES:
        valueToCheck = (unsigned long)(value * 60);
        break;
    case TIME_HOURS:
        valueToCheck = (unsigned long)(value * 60 * 60);
        break;
    default:
        return 0;
    }

    if (difference >= valueToCheck)
    {
        return 1;
    }

    return 0;
    /* SyncableUserCode{2DD7EDAF-8F29-40e9-A161-84BCA0951049} */
}

/* Name:		getTime
 * Returns: 	long
 * Parameters:	
 *  */
long FSM_getTime(void)
{
    /* SyncableUserCode{534E0831-6ED6-478d-8801-2A92EBB740E6}:MTQY45OhU2 */
    time_t now = time(NULL);

    return now;
    /* SyncableUserCode{534E0831-6ED6-478d-8801-2A92EBB740E6} */
}

