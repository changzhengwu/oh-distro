/** THIS IS AN AUTOMATICALLY GENERATED FILE.  DO NOT MODIFY
 * BY HAND!!
 *
 * Generated by lcm-gen
 **/

#include <stdint.h>
#include <stdlib.h>
#include <lcm/lcm_coretypes.h>
#include <lcm/lcm.h>

#ifndef _mav_indexed_measurement_t_h
#define _mav_indexed_measurement_t_h

#ifdef __cplusplus
extern "C" {
#endif

typedef struct _mav_indexed_measurement_t mav_indexed_measurement_t;
struct _mav_indexed_measurement_t
{
    int64_t    utime;
    int64_t    state_utime;
    int32_t    measured_dim;
    double     *z_effective;
    int32_t    *z_indices;
    int32_t    measured_cov_dim;
    double     *R_effective;
};

mav_indexed_measurement_t   *mav_indexed_measurement_t_copy(const mav_indexed_measurement_t *p);
void mav_indexed_measurement_t_destroy(mav_indexed_measurement_t *p);

typedef struct _mav_indexed_measurement_t_subscription_t mav_indexed_measurement_t_subscription_t;
typedef void(*mav_indexed_measurement_t_handler_t)(const lcm_recv_buf_t *rbuf,
             const char *channel, const mav_indexed_measurement_t *msg, void *user);

int mav_indexed_measurement_t_publish(lcm_t *lcm, const char *channel, const mav_indexed_measurement_t *p);
mav_indexed_measurement_t_subscription_t* mav_indexed_measurement_t_subscribe(lcm_t *lcm, const char *channel, mav_indexed_measurement_t_handler_t f, void *userdata);
int mav_indexed_measurement_t_unsubscribe(lcm_t *lcm, mav_indexed_measurement_t_subscription_t* hid);
int mav_indexed_measurement_t_subscription_set_queue_capacity(mav_indexed_measurement_t_subscription_t* subs,
                              int num_messages);


int  mav_indexed_measurement_t_encode(void *buf, int offset, int maxlen, const mav_indexed_measurement_t *p);
int  mav_indexed_measurement_t_decode(const void *buf, int offset, int maxlen, mav_indexed_measurement_t *p);
int  mav_indexed_measurement_t_decode_cleanup(mav_indexed_measurement_t *p);
int  mav_indexed_measurement_t_encoded_size(const mav_indexed_measurement_t *p);

// LCM support functions. Users should not call these
int64_t __mav_indexed_measurement_t_get_hash(void);
int64_t __mav_indexed_measurement_t_hash_recursive(const __lcm_hash_ptr *p);
int     __mav_indexed_measurement_t_encode_array(void *buf, int offset, int maxlen, const mav_indexed_measurement_t *p, int elements);
int     __mav_indexed_measurement_t_decode_array(const void *buf, int offset, int maxlen, mav_indexed_measurement_t *p, int elements);
int     __mav_indexed_measurement_t_decode_array_cleanup(mav_indexed_measurement_t *p, int elements);
int     __mav_indexed_measurement_t_encoded_array_size(const mav_indexed_measurement_t *p, int elements);
int     __mav_indexed_measurement_t_clone_array(const mav_indexed_measurement_t *p, mav_indexed_measurement_t *q, int elements);

#ifdef __cplusplus
}
#endif

#endif
