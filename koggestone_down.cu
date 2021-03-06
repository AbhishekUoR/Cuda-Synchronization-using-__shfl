/* -*- mode: c++ -*- */
#include <stdio.h>
#include <cuda.h>
#include <stdlib.h>
#include <assert.h>

void checkCuda(const cudaError_t s, const char* file, const int line) {
  if(s != cudaSuccess) {
    fprintf(stderr, 
	    "%s:%d: CUDA error: %s\n", file, line, cudaGetErrorString(s));
    exit(1);
  }
}

#define check_cuda(x) checkCuda((x), __FILE__, __LINE__)


__global__
void sum_warp(int *n, int N, int *out) {
  int tid = threadIdx.x;
  int temp1 = n[tid];
  int temp2;

  assert(N <= 32);
    for(int d = 0; d < 5; d++) {        
   	temp2 = __shfl_down(temp1,((1<<d))); 
   if((tid % (1<<(d+1))) == 0) {
	temp1+=temp2;
    }
  } 

  if(tid == 0) {
    *out = temp1;
  }  

}

int main(int argc, char *argv[])
{
  if(argc == 1) {
    fprintf(stderr, "Usage: %s number1 number2...\n", argv[0]);
    exit(1);
  }

  if(argc > 33) {
    fprintf(stderr, "Usage: %s number1 number2...\n", argv[0]);
    fprintf(stderr, "Can only add up to 32 numbers\n");
    exit(1);
  }

  int n[32], N = 0;

  for(int i = 0; i < argc-1; i++) {
    n[i] = atoi(argv[i+1]);
    N++;
  }

  printf("Read %d numbers.\n", N);

  int *n_d, *out_d;
  int out;
  
  check_cuda(cudaMalloc(&n_d, sizeof(int) * N));
  check_cuda(cudaMalloc(&out_d, sizeof(int) * 1));
  
  check_cuda(cudaMemcpy(n_d, n, sizeof(int) * N, cudaMemcpyHostToDevice));
  
  sum_warp<<<1, 32>>>(n_d, N, out_d);

  check_cuda(cudaMemcpy(&out, out_d, sizeof(int) * 1, cudaMemcpyDeviceToHost));

  printf("Sum of %d numbers: %d\n", N, out);

  check_cuda(cudaFree(n_d));
  check_cuda(cudaFree(out_d));

  return 0;
}
