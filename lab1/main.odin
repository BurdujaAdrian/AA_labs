#+feature dynamic-literals

package main

import "core:fmt"
import la "core:math/linalg"
import m "core:math"

import "core:thread"
import "core:time"
import "base:intrinsics"

import "core:encoding/json"
import "core:os"
import "core:os/os2"

print :: fmt.println

print_mutex :=b64(false)

PHI :: 0.5 + m.SQRT_FIVE/2
PHI2:: 0.5 - m.SQRT_FIVE/2

thread_run :: thread.create_and_start_with_poly_data

MAG :: 1000

Result :: struct{
	name : string,
	data: struct{x:[10]u64, y:[10]u64},
}

test_naive :: proc(res:^Result){
	for n:u64=1; n<=10; n+=1{
		res.name = "naive_rec"

		stop_w :time.Stopwatch

		time.stopwatch_start(&stop_w)
		_ = naive_rec_fib(n*4)
		time.stopwatch_stop(&stop_w)		
		print("naive", stop_w._accumulation)
		res.data.y[ n -1] = auto_cast time.duration_microseconds(stop_w._accumulation)
		res.data.x[ n -1] = n*4
	}
}

test_dyn :: proc(res:^Result){
	for n:u64=1; n<=10; n+=1{
		res.name = "dyn"

		stop_w :time.Stopwatch

		time.stopwatch_start(&stop_w)
		_ = dyn_fib(n*MAG)
		time.stopwatch_stop(&stop_w)

		print("dyn",stop_w._accumulation)

		res.data.y[ n -1] = auto_cast time.duration_microseconds(stop_w._accumulation)
		res.data.x[ n -1] = n*MAG
	}
}

test_form :: proc(res:^Result){
	for n:u64=1; n<=10; n+=1{
		res.name = "form"

		stop_w :time.Stopwatch

		time.stopwatch_start(&stop_w)
		_ = form_fib(n*MAG)
		time.stopwatch_stop(&stop_w)

		print("form",stop_w._accumulation)

		res.data.y[ n -1] = auto_cast time.duration_microseconds(stop_w._accumulation)
		res.data.x[ n -1] = n*MAG
	}
}


test_mat :: proc(res:^Result){
	for n:u64=1; n<=10; n+=1{
		res.name = "mat"

		stop_w :time.Stopwatch

		time.stopwatch_start(&stop_w)
		_ = mat_fib(n*MAG)
		time.stopwatch_stop(&stop_w)

		print("mat",stop_w._accumulation)

		res.data.y[ n -1] = auto_cast time.duration_microseconds(stop_w._accumulation)
		res.data.x[ n -1] = n*MAG
	}
}

test_rec :: proc(res:^Result){
	for n:u64=1; n<=10; n+=1{
		res.name = "rec"

		stop_w :time.Stopwatch

		time.stopwatch_start(&stop_w)
		_ = rec_fib(n*MAG)
		time.stopwatch_stop(&stop_w)

		print("rec",stop_w._accumulation)

		res.data.y[ n -1] = auto_cast time.duration_microseconds(stop_w._accumulation)
		res.data.x[ n -1] = n*MAG
	}
}


test_iter :: proc(res:^Result){
	for n:u64=1; n<=10; n+=1{
		res.name = "iter"

		stop_w :time.Stopwatch

		time.stopwatch_start(&stop_w)
		_ = iter_fib(n*MAG)
		time.stopwatch_stop(&stop_w)

		print("iter",stop_w._accumulation)

		res.data.y[ n -1] = auto_cast time.duration_microseconds(stop_w._accumulation)
		res.data.x[ n -1] = n*MAG
	}
}

test_doubling :: proc(res:^Result){
	for n:u64=1; n<=10; n+=1{
		res.name = "doubling"

		stop_w :time.Stopwatch

		time.stopwatch_start(&stop_w)
		_ = doubling_fib(n*MAG)
		time.stopwatch_stop(&stop_w)

		print("doubling",stop_w._accumulation)

		res.data.y[ n -1] = auto_cast time.duration_microseconds(stop_w._accumulation)
		res.data.x[ n -1] = n*MAG
	}
}



main :: proc(){
	
	results:[7]Result


	//naive_thread := thread_run(&results[0],test_naive)
	dyn_thread := thread_run(&results[1],test_dyn)
	mat_thread := thread_run(&results[2],test_mat)
	form_thread:= thread_run(&results[3],test_form)
	rec_thread := thread_run(&results[4],test_rec)
	iter_thread:= thread_run(&results[5],test_iter)
	doubling_thread:=thread_run(&results[6],test_doubling)
	time.sleep(1 * time.Millisecond)
	thread.join(dyn_thread)
	thread.join(rec_thread)
	thread.join(mat_thread)
	thread.join(form_thread)
	thread.join(iter_thread)
	thread.join(doubling_thread)
	//thread.join(naive_thread)

	print("end of threads")

	json_data,_ := json.marshal(results)
	os.write_entire_file("results.json",json_data)
	
	process, err := os2.process_start(os2.Process_Desc{command = {"python", "plot.py"}})

	if err != nil {print(err); panic("python didnt start")}

	_,_ = os2.process_wait(process)
}


naive_rec_fib :: proc(n:u64)-> u64{
	if n == 0 {return 0}
	if n <= 2 {return 1}

	return naive_rec_fib(n-1) + naive_rec_fib(n-2)
}




dyn_fib :: proc(n:u64, a:u64 = 0, b:u64 = 1)->u64{
	list := [dynamic]u64{0,1}
	
	for i in 2..<n+1 {
		append(&list, list[i-1]+list[i-2])
	}
	return list[n]
}

mat_fib :: proc(n:u64)->u64{
	if n == 0 {return 0}

	mat:= matrix[2,2]u64{1,1,1,0}
	mat = matrix_pow(mat,n)
	//print(mat)
	return mat[0][0]
}

matrix_pow :: proc(mat:matrix[2,2]u64 , pow:u64)->(res :matrix[2,2]u64){
	res = mat; for _ in 2..<pow{res *=mat }; return 
}

form_fib :: proc(n:u64)->u64{
	if n == 0 {return 0}

	return u64( (m.pow_f64(PHI,f64(n)) -
		     m.pow_f64(PHI2,f64(n))
		    )/m.SQRT_FIVE)
}

//@new
rec_fib :: proc(n:u64, a:u64 = 0, b:u64 = 1)->u64{
	if n == 0 {return a}
	if n == 1 {return b}

	return rec_fib(n-1, b, a+b)
}

iter_fib :: proc(n:u64)->u64{
	a:u64=0
	b:u64=1

	for _ in 0..<n{ a,b = b,a+b}

	return a
}

MOD :: 1000000007
doubling_fib :: proc(n:u64,res:^[]u64 = nil, call:int=0)->u64{
	res:=res
	if res == nil {
		res = new_clone([]u64{0,0})
	}

	if n == 0 {
		res[0] = 0
		res[1] = 1
		return 0
	}
	
	_ = doubling_fib(n/2 , res,call+1)
	
	a:= res[0]
	b:= res[1]
	c:= 2*b - a

	if c < 0 {c+=MOD}

	c = (a * c) % MOD

	d:= (a * a + b * b) % MOD

	if n % 2 == 0{
		res[0] = c
		res[1] = d
		return res[0]
	}

	res[0] = d
	res[1] = c + d

	if call == 0 {free(res)}
	return res[0]
}

