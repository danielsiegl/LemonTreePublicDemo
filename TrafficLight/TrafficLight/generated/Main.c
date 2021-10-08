/* Model File: Main
 * Model Path: C:\LemonTreeTestData\LemonTreePublicDemo\TrafficLight\TrafficLight.eap
 * 
 * Author: markus.hammer 
 * Date: 2021-10-07 15:14:55
 * 
 * Notes: 
 *  */
#include "Main.h"

/* Implements REQ:Statemachine interaction:{E6D9702B-F457-43a3-939A-F7DA459E573C} */

static Signals sigQueueCarTraffic[SIGNAL_QUEUE_SIZE];

static int signalsCarsIdx = -1;

static Signals sigQueuePedestrian[SIGNAL_QUEUE_SIZE];

static int signalsPedsIdx = -1;

/* Statically allocated instance. Automatically added and generated. */
Main Main_me;

/* Returns a pointer to the statically allocated structure for Main.
 * Automatically added and generated.
 * @return Pointer to the statically allocated structure for Main. */
Main* Main_new(void)
{
    return &Main_me;
}

/* Name:		main
 * Returns: 	int
 * Parameters:	
 *  */
int main(void)
{
    /* SyncableUserCode{A9340277-2A65-4b04-9BF6-2B1B7268BC09}:b13QQY1W7l */
    Main* me = Main_new();

    for (int i = 0; i < SIGNAL_QUEUE_SIZE; i++)
    {
        sigQueueCarTraffic[i] = 0;
        sigQueuePedestrian[i] = 0;
    }

    CarTrafficLight* cars = CarTrafficLight_new();
    PedestrianTrafficLight* peds = PedestrianTrafficLight_new();

    //constructors to call SM_Init provide signal handler function
    CarTrafficLight_CarTrafficLight(cars, &Main_carTraficSigRouter);
    PedestrianTrafficLight_PedestrianTrafficLight(peds, &Main_pedestrianSigRouter);

    //start game -> master send ping first
    /*PingMaster_MasterSM(pingM, &pingM->MasterSM, NOSIG);*/

    while (1)
    {
        //run 1st SM on events in queue
        Signals currentSig = NOSIG;
        bool evConsumed = false;
        if (signalsCarsIdx >= 0)
        {
            currentSig = sigQueueCarTraffic[signalsCarsIdx];
        }
        evConsumed = CarTrafficLight_CarTrafficSM(cars, &cars->CarTrafficSM, currentSig);
        if (evConsumed)
        {
            sigQueueCarTraffic[signalsCarsIdx] = NOSIG;
            signalsCarsIdx--;
        }
        //run 2st SM on events in queue
        if (signalsPedsIdx >= 0)
        {
            int evConsumed = 0;
            evConsumed = PedestrianTrafficLight_PedestrianSM(peds, &peds->PedestrianSM, sigQueuePedestrian[signalsPedsIdx]);
            if (evConsumed)
            {
                sigQueuePedestrian[signalsPedsIdx] = NOSIG;
                signalsPedsIdx--;
            }
        }
        Sleep(100);
    }
    /* SyncableUserCode{A9340277-2A65-4b04-9BF6-2B1B7268BC09} */
}

/* Name:		signalHandler
 * Returns: 	void
 * Parameters:	 Signals* queue,  int length,  int* idx,  Signals sentSignal
 *  */
void Main_signalHandler(Signals* queue, /*  pointer to signal queue filled by router methods */
                        int length, /*  queue max length */
                        int* idx, /*  pointer to current queue element */
                        Signals sentSignal /*  signal sent  */
                        )
{ /* Start of implementation REQ:Statemachine interaction:{E6D9702B-F457-43a3-939A-F7DA459E573C} */

    /* insert current sendSignal to provided signal queue */
    /* SyncableUserCode{169CB3EA-E8DC-42cc-8ABE-4BF08515DD3D}:JM5XHwrtAU */
    int newIdx = ++(*idx);

    if ((newIdx >= 0) && (newIdx < length))
    {
        queue[newIdx] = sentSignal;
        *idx = newIdx;
    }
    /* SyncableUserCode{169CB3EA-E8DC-42cc-8ABE-4BF08515DD3D} */
    /* End of implementation REQ:Statemachine interaction:{E6D9702B-F457-43a3-939A-F7DA459E573C} */
}

/* Name:		pedestrianSigRouter
 * Returns: 	void
 * Parameters:	 Signals sentSignal
 *  */
void Main_pedestrianSigRouter(Signals sentSignal)
{
    /* place documentation here */
    /* SyncableUserCode{F03C001E-7111-40d8-8CD7-A0BAF94CF0AC}:FPJWRf1L74 */
    Main_signalHandler(&sigQueueCarTraffic, SIGNAL_QUEUE_SIZE, &signalsCarsIdx, sentSignal);

    /* SyncableUserCode{F03C001E-7111-40d8-8CD7-A0BAF94CF0AC} */
}

/* Name:		carTraficSigRouter
 * Returns: 	void
 * Parameters:	 Signals sentSignal
 *  */
void Main_carTraficSigRouter(Signals sentSignal)
{
    /* SyncableUserCode{94A9152F-8A32-4dd7-B4E3-F9F509D06ECB}:ifY62Zur6A */
    Main_signalHandler(&sigQueuePedestrian, SIGNAL_QUEUE_SIZE, &signalsPedsIdx, sentSignal);

    /* SyncableUserCode{94A9152F-8A32-4dd7-B4E3-F9F509D06ECB} */
}

