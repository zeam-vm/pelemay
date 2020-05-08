#ifndef LSM_H
#define LSM_H

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#include <stdlib.h>
#include <erl_nif.h>

#define DRIVE_NUM 10
#define MAX_SHIFT_SIZE 5

typedef ErlNifUInt64 (*pelemay_driver)(size_t vec_l);

double *pelemay_lsm(ErlNifUInt64 *x, ErlNifUInt64 *y, size_t n);

double *pelemay_lsm_drive(pelemay_driver driver);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // LSM_H
