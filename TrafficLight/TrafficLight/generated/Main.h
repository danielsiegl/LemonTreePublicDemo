/* Model File: Main
 * Model Path: C:\LemonTreeTestData\LemonTreePublicDemo\TrafficLight\TrafficLight.eap
 * 
 * Author: markus.hammer 
 * Date: 2021-10-07 15:14:55
 * 
 * Notes: 
 *  */
#ifndef H_MAIN
#define H_MAIN

#include "CarTrafficLight.h" /* Include for 'relation to classifier' 'CarTrafficLight' */
#include "PedestrianTrafficLight.h" /* Include for 'relation to classifier' 'PedestrianTrafficLight' */
/* Implements REQ:Statemachine interaction:{E6D9702B-F457-43a3-939A-F7DA459E573C} */

#define SIGNAL_QUEUE_SIZE 10

typedef int Main;

/* Returns a pointer to the statically allocated structure for Main.
 * Automatically added and generated.
 * @return Pointer to the statically allocated structure for Main. */
Main* Main_new(void);

/* Name:		main
 * Returns: 	int
 * Parameters:	
 *  */
int main(void);

/* Name:		signalHandler
 * Returns: 	void
 * Parameters:	 Signals* queue,  int length,  int* idx,  Signals sentSignal
 *  */
/* Implements REQ:Statemachine interaction:{E6D9702B-F457-43a3-939A-F7DA459E573C} */
void Main_signalHandler(Signals* queue, /*  pointer to signal queue filled by router methods */
                        int length, /*  queue max length */
                        int* idx, /*  pointer to current queue element */
                        Signals sentSignal /*  signal sent  */
                        );

/* Name:		pedestrianSigRouter
 * Returns: 	void
 * Parameters:	 Signals sentSignal
 *  */
void Main_pedestrianSigRouter(Signals sentSignal);

/* Name:		carTraficSigRouter
 * Returns: 	void
 * Parameters:	 Signals sentSignal
 *  */
void Main_carTraficSigRouter(Signals sentSignal);

#endif /* #ifndef H_MAIN */

