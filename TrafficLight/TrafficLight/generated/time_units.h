/* Model File: time_units
 * Model Path: C:\LemonTreeTestData\LemonTreePublicDemo\TrafficLight\TrafficLight.eap
 * 
 * Author: wnesensohn 
 * Date: 2021-10-12 07:53:43
 * 
 * Notes: 
 *  */
#ifndef H_TIME_UNITS
#define H_TIME_UNITS

typedef enum {
    TIME_TICKS = 0, /* Explicit value specification added by code generator */
    TIME_NANOSECONDS,
    TIME_MICROSECONDS,
    TIME_MILLISECONDS,
    TIME_SECONDS,
    TIME_MINUTES,
    TIME_HOURS
} time_units;

#endif /* #ifndef H_TIME_UNITS */

