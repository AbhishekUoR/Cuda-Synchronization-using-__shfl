all: koggestone koggestone_shfl koggestone_down

%: %.cu
	nvcc -arch sm_35 $< -o $@
.phony: clean
clean:
	rm -rf koggestone koggestone_shfl koggestone_down
