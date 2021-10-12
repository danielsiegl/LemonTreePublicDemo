/* Model File: FSM
 * Model Path: C:\LemonTreeTestData\LemonTreePublicDemo\TrafficLight\TrafficLight.eap
 * 
 * Author: wnesensohn 
 * Date: 2021-10-12 07:53:42
 * 
 * Notes: 
 *  */
#ifndef H_FSM
#define H_FSM

#include "FSM_STATE.h" /* Include for 'relation to classifier' 'FSM_STATE' */
#include <time.h>/* Include for 'relation to classifier' 'time' */
#include "stdbool.h" /* Include for 'relation to classifier' 'stdbool' */
#include "time_units.h" /* Include for 'relation to classifier' 'time_units' */

/* Name:		checkTimeEvent
 * Returns: 	bool
 * Parameters:	 FSM_STATE* state,  long value,  time_units unit
 *  */
bool FSM_checkTimeEvent(FSM_STATE* state, long value, time_units unit);

/* Name:		getTime
 * Returns: 	long
 * Parameters:	
 *  */
long FSM_getTime(void);

#endif /* #ifndef H_FSM */

