package main

import "core:fmt"
import "core:math/rand"
import m "core:math"

import "core:encoding/json"
import "core:os"
import "core:os/os2"

when ODIN_DEBUG {print :: fmt.println
		printf :: fmt.printf
} else when ODIN_TEST {
	print :: log.info
	printf:: log.infof
} else {printf :: proc(fmt: string, args: ..any, flush := true) {}
	print :: proc(args: ..any, sep := " ", flush := true) {} }

MAX_EL :: 4096*2
N_TESTS::  100

@(thread_local)
array:[MAX_EL]u64

//@(thread_local)
//array_backup:[MAX_EL]u64

main :: proc(){

	test_data :[4][N_TESTS]u64

	for i in 0..<N_TESTS{
		test_quick(nil); test_data[0][i] = quick_time
		test_merge(nil); test_data[1][i] = merge_time
		test_heap(nil);  test_data[2][i] =  heap_time
		test_radix(nil); test_data[3][i] = radix_time
	}
	fmt.print(test_data)

	json_data,_ := json.marshal(test_data)
	os.write_entire_file("results.json",json_data)
	
	process, err := os2.process_start(os2.Process_Desc{command = {"python", "plot.py"}})

	if err != nil {print(err); panic("python didnt start")}

	_,_ = os2.process_wait(process)
}

quick :: proc(arr:^[MAX_EL]u64, low,high:u64){
	if low < high{
		pi := partition(arr,low,high)

		switch pi+low{ 
		// skip sorting left sub-array if both pi and low are 0
		case  :  quick(arr,low,pi-1); fallthrough
		case 0:  quick(arr,pi+1,high)
		}
	}
}

partition :: proc(arr:^[MAX_EL]u64, low:u64 ,high:u64)->u64{
	pivot := arr[high]
	i     := low - 1

	for j:=low; j< high ; j+=1{
		if arr[j] <= pivot{
			i+=1
			arr[i],arr[j] = arr[j],arr[i]
		}
	}

	arr[i+1],arr[high] = arr[high], arr[i+1]

	return i + 1
}

merge :: proc(arr:^[MAX_EL]u64, l,m,r:u64){
	i,j,k:u64

	n1:=m-l+1
	n2:=r-m

	L:=make([]u64,n1)
	R:=make([]u64,n2)
	defer{
		delete(L)
		delete(R)
	}

	for n,i in arr[l:n1+l] {
		L[i] = n}

	for n,i in arr[m+1:n2+m+1] {R[i] = n}

	k = l

	for i < n1 && j < n2 {
		if L[i] <= R[j]{
			arr[k] = L[i]
			i+=1
			k+=1
			continue
		}

		arr[k] = R[j]
		j+=1
		k+=1
	}

	for i < n1 {
		arr[k] = L[i]
		i+=1
		k+=1
	}

	for j<n2{
		arr[k] = R[j]
		j+=1
		k+=1
	}
}

merge_sort :: proc(arr:^[MAX_EL]u64, l,r:u64){
	if l < r {
		m := l + (r-l)/2

		merge_sort(arr,l,m)
		merge_sort(arr,m+1,r)

		merge(arr,l,m,r)
	}
}


heap :: proc(arr:^[MAX_EL]u64){
	n :: MAX_EL

	for i:u64= (MAX_EL/2) -1; i64(i) >= 0 ; i-=1{
		heapify(arr,n,i)
	}

	for i:u64=n-1; i>0; i-=1 {
		temp := arr[0]; 
		arr[0] = arr[i];
		arr[i] = temp;

		heapify(arr,i,0)
	}
}


heapify :: proc(arr:^[MAX_EL]u64, n,i:u64){

	largest :u64= i

	l := 2*i + 1

	r := 2*i +2

	if l<n && arr[l] > arr[largest]{
		largest = l
	}

	if r<n && arr[r] > arr[largest]{
		largest = r
	}


	if largest != i {
		temp := arr[i]
		arr[i] = arr[largest]
		arr[largest] = temp

		heapify(arr,n,largest)
	}
}

BASE  :: 256
DIGITS:u64:   8
BITS  :u64:   8

radix :: proc(arr:^[MAX_EL]u64){
	for digit in 0..<DIGITS{
		counting(arr,digit)
	}
}

count_array :[BASE+1]u64
out_array   :[MAX_EL]u64
counting :: proc(arr:^[MAX_EL]u64, digit:u64)->(done:bool){
	count_array = 0
	out_array = 0

	shift := digit*BITS
	done = true
	for n in arr{ 
		i :=  (n >> shift) & 0xff
		done &&= (i == 0)

		count_array[i]+=1 
	}
	// if there were no digits other than 0, there's no point in sorting
	if done {return}

	for i:=1; i<=BASE; i+=1{
		count_array[i] += count_array[i-1]
	}
	for i:=MAX_EL -1; i64(i)>=0 ; i-=1{
		n := (arr[i] >> shift) & 0xff
		count_i := count_array[ n ] - 1
		arr_i := arr[i]
		out_array[ count_i] = arr_i

		count_array[ n ] -=1
	}

	for n,i in out_array{
		arr[i] = n
	}


	return
	
}

import "core:testing"
import "core:log"
import "core:time"
import "base:intrinsics"

quick_time :u64
@(test)
test_quick :: proc(t:^testing.T){
	if t != nil {rand.reset(t.seed)}

	for &n in &array{
		//n = auto_cast rand.uint64() % (MAX_EL*MAX_EL)
		n = rand.uint64()
	}

	stop_w :time.Stopwatch

	time.stopwatch_start(&stop_w)
	quick(&array,0,MAX_EL-1)
	//log.info("\n sorted quick array:",array,"\n")

	time.stopwatch_stop(&stop_w)
	quick_time = auto_cast time.duration_microseconds(stop_w._accumulation)
	log.info("quick time :",quick_time)
}

merge_time :u64
@(test)
test_merge :: proc(t:^testing.T){
	if t != nil {rand.reset(t.seed)}

	for &n in &array{
		//n = auto_cast rand.uint64() % (MAX_EL*MAX_EL)
		n = rand.uint64()
	}

	//log.info("\nmerge:\n",array)
	stop_w :time.Stopwatch

	time.stopwatch_start(&stop_w)
	merge_sort(&array,0,MAX_EL-1)

	//log.info("\n sorted merge array:",array,"\n")

	time.stopwatch_stop(&stop_w)
	merge_time = auto_cast time.duration_microseconds(stop_w._accumulation)
	log.info("merge time :",merge_time)
}
heap_time :u64

@(test)
test_heap :: proc(t:^testing.T){
	if t != nil {rand.reset(t.seed)}

	for &n in &array{
		//n = auto_cast rand.uint64() % (MAX_EL*MAX_EL)
		n = rand.uint64()
	}

	//log.info("\nheap:\n",array)
	stop_w :time.Stopwatch

	time.stopwatch_start(&stop_w)
	heap(&array)
	//log.info("\n sorted heap array:",array,"\n")

	time.stopwatch_stop(&stop_w)
	heap_time = auto_cast time.duration_microseconds(stop_w._accumulation)
	log.info("heap time :",heap_time)
}

radix_time :u64
@(test)
test_radix :: proc(t:^testing.T){
	if t != nil {rand.reset(t.seed)}

	for &n in &array{
		//n = auto_cast rand.uint64() % (MAX_EL*MAX_EL)
		n = rand.uint64()
	}

	//log.info("\nradix:\n",array)
	stop_w :time.Stopwatch

	time.stopwatch_start(&stop_w)
	radix(&array)

	//log.info("\n sorted radix array:",array,"\n")

	time.stopwatch_stop(&stop_w)
	radix_time = auto_cast time.duration_microseconds(stop_w._accumulation)
	log.info("radix time :",radix_time)
}

@(test)
print_results :: proc(t:^testing.T){
	time.sleep(500_000_000)

	print("All of them are done\n")
	printf("Quick sort time: %v\n",quick_time)
	printf("Merge sort time: %v\n",merge_time)
	printf("Heap  sort time: %v\n",heap_time)
	printf("Radix sort time: %v\n",radix_time)
	
	return
}

