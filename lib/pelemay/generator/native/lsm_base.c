#include <lsm_base.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <pelemay_base.h>

static uint64_t sum(uint64_t *a, size_t n) {
  uint64_t sum = 0;
#pragma clang loop vectorize_width(LOOP_VECTORIZE_WIDTH)
  for(size_t i = 0; i < n; i++) {
    sum += a[i];
  }
  return sum;
}

static double avr(uint64_t sum, size_t n) {
  return (double)sum / n;
}

static double *diff(uint64_t *a, size_t n, double avr) {
  double *ret = (double *)malloc(sizeof(double) * n);
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

double *pelemay_lsm(uint64_t *x, uint64_t *y, size_t n) {
  uint64_t sum_x = sum(x, n);
  uint64_t sum_y = sum(y, n);
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
  free(diff_x);
  free(diff_y);
  double *_lsm = (double *)malloc(sizeof(double) * 3);
  _lsm[0] = r;
  _lsm[1] = a;
  _lsm[2] = b;
  return _lsm;
}

double *pelemay_lsm_drive(pelemay_driver driver) {
  uint64_t *x = (uint64_t *)malloc(sizeof(uint64_t) * DRIVE_NUM * MAX_SHIFT_SIZE);
  uint64_t *y = (uint64_t *)malloc(sizeof(uint64_t) * DRIVE_NUM * MAX_SHIFT_SIZE);
  uint64_t *t = (uint64_t *)malloc(sizeof(uint64_t) * DRIVE_NUM);
  double *lsm;
  do {
    size_t size = LOOP_VECTORIZE_WIDTH;
    size_t count = 0;
    for(unsigned i = 0; i < MAX_SHIFT_SIZE; i++, size <<= SHIFT) {
      for(unsigned j = 0; j < DRIVE_NUM; j++) {
        t[j] = (* driver)((uint64_t)size);
      }
      uint64_t sum_t = sum(t, DRIVE_NUM);
      double avr_t = avr(sum_t, DRIVE_NUM);
      double *diff_t = diff(t, DRIVE_NUM, avr_t);
      double variance_t = variance(diff_t, DRIVE_NUM);
      free(diff_t);
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
  free(x);
  free(y);
  free(t);
  return lsm;
}
