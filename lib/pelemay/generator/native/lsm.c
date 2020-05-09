#include <lsm.h>
#include <math.h>
#include <erl_nif.h>
#include <basic.h>

static ErlNifUInt64 sum(ErlNifUInt64 *a, size_t n) {
  ErlNifUInt64 sum = 0;
#pragma clang loop vectorize_width(LOOP_VECTORIZE_WIDTH)
  for(size_t i = 0; i < n; i++) {
    sum += a[i];
  }
  return sum;
}

static double avr(ErlNifUInt64 sum, size_t n) {
  return (double)sum / n;
}

static double *diff(ErlNifUInt64 *a, size_t n, double avr) {
  double *ret = (double *)enif_alloc(sizeof(double) * n);
#pragma clang loop vectorize_width(LOOP_VECTORIZE_WIDTH)
  for(size_t i = 0; i < n; i++) {
    ret[i] = (a[i] - avr);
  }
  return ret;
}

static double variance(double* diff, size_t n) {
  double ret = 0.0;
#pragma clang loop vectorize_width(LOOP_VECTORIZE_WIDTH)
  for(size_t i = 0; i < n; i++) {
    ret += diff[i] * diff[i];
  }
  return ret / n;
}

static double covariance(double *diff_a, double *diff_b, size_t n) {
  double ret = 0.0;
#pragma clang loop vectorize_width(LOOP_VECTORIZE_WIDTH)
  for(int i = 0; i < n; i++) {
    ret += diff_a[i] * diff_b[i];
  }
  return ret / n;
}

static double lsm_a(double variance_x, double covariance) {
   return covariance / variance_x;
}

static double lsm_b(double lsm_a, double avr_x, double avr_y) {
  return avr_y - lsm_a * avr_x;
}

static double lsm_r(double variance_x, double variance_y, double covariance) {
  return covariance / sqrt(variance_x) / sqrt(variance_y);
}

double *pelemay_lsm(ErlNifUInt64 *x, ErlNifUInt64 *y, size_t n) {
  ErlNifUInt64 sum_x = sum(x, n);
  ErlNifUInt64 sum_y = sum(y, n);
  double avr_x = avr(sum_x, n);
  double avr_y = avr(sum_y, n);
  double *diff_x = diff(x, n, avr_x);
  double *diff_y = diff(y, n, avr_y);
  double variance_x = variance(diff_x, n);
  double variance_y = variance(diff_y, n);
  double _covariance = covariance(diff_x, diff_y, n);
  double a = lsm_a(variance_x, _covariance);
  double b = lsm_b(a, avr_x, avr_y);
  double r = lsm_r(variance_x, variance_y, _covariance);
  enif_free(diff_x);
  enif_free(diff_y);
  double *_lsm = (double *)enif_alloc(sizeof(double) * 3);
  _lsm[0] = r;
  _lsm[1] = a;
  _lsm[2] = b;
  return _lsm;
}

double *pelemay_lsm_drive(pelemay_driver driver) {
  ErlNifUInt64 *x = (ErlNifUInt64 *)enif_alloc(sizeof(ErlNifUInt64) * DRIVE_NUM * MAX_SHIFT_SIZE);
  ErlNifUInt64 *y = (ErlNifUInt64 *)enif_alloc(sizeof(ErlNifUInt64) * DRIVE_NUM * MAX_SHIFT_SIZE);
  ErlNifUInt64 *t = (ErlNifUInt64 *)enif_alloc(sizeof(ErlNifUInt64) * DRIVE_NUM);
  double *lsm;
  do {
    size_t size = LOOP_VECTORIZE_WIDTH;
    size_t count = 0;
    for(unsigned i = 0; i < MAX_SHIFT_SIZE; i++, size <<= SHIFT) {
      for(unsigned j = 0; j < DRIVE_NUM; j++) {
        t[j] = (* driver)((ErlNifUInt64)size);
      }
      ErlNifUInt64 sum_t = sum(t, DRIVE_NUM);
      double avr_t = avr(sum_t, DRIVE_NUM);
      double *diff_t = diff(t, DRIVE_NUM, avr_t);
      double variance_t = variance(diff_t, DRIVE_NUM);
      enif_free(diff_t);
      for(unsigned j = 0; j < DRIVE_NUM; j++) {
        if(fabs(t[j] - avr_t) / sqrt(variance_t) < OUTLIER_FACTOR) {
          x[count] = size;
          y[count] = t[j];
          count++;
        }
      }
    }
    lsm = pelemay_lsm(x, y, count);
  } while(lsm[0] < 0.9 || lsm[1] <= 0 || lsm[2] < 0.0);
  enif_free(x);
  enif_free(y);
  enif_free(t);
  return lsm;
}
