open Bigarray ;;
open Tcsset;;

let sparseness_generator n sparseness dupdegree =
	let intarr = Array1.create int c_layout n in
	let m = int_of_float (sparseness *. (float n)) in
	let i = ref 0 in
	while !i < m do
		let r = Random.int n in
		if (intarr.{r} = 0) then (
			intarr.{r} <- 1;
			incr i
		)
	done;
	let numbers = ref 0 in
	let counting = ref false in
	for i = 0 to n - 1 do
		if intarr.{i} = 1 then counting := not !counting;
		if !counting then incr numbers
	done;
	let k = int_of_float ((float !numbers) *. dupdegree) in
	let values = Array1.create int c_layout k in
	let c = ref 0 in
	let counting = ref false in
	for i = 0 to m - 1 do
		if intarr.{i} = 1 then counting := not !counting;
		if !counting then (
			values.{!c} <- i;
			incr c
		)
	done;
	while !c < k do
		values.{!c} <- values.{Random.int !c};
		incr c
	done;
	for i = 0 to k - 1 do
		let a = Random.int k in
		let b = Random.int k in
		let tmp = values.{a} in
		values.{a} <- values.{b};
		values.{b} <- tmp
	done;
	values



let sign = IntervalSetFuncs.int_intervalset

module S = IntSet ;;
module T = Tcsset.IntervalSet;;

let time_it id a =
  print_string (id ^ ": ");
  flush stdout;
  let f = Sys.time () in
  let x = a () in
  let f' = Sys.time () in
  print_string (" ==>> " ^ Printf.sprintf "%.2f" (f' -. f) ^ " sec\n");
  flush stdout;
  x

let check s t =
	if S.elements s = T.elements t then () else failwith "Unsound computation!"

let output = false

let to_string s = "{" ^ String.concat "," (List.map string_of_int (S.elements s)) ^ "}"

let to_string' s = "{" ^ String.concat "," (List.map string_of_int (T.elements s)) ^ "}"

let _ = Random.self_init ()

let _ =
  let s1 = ref S.empty in
  let s2 = ref S.empty in
  let t1 = ref (T.empty sign) in
  let t2 = ref (T.empty sign) in

  let limit = int_of_string Sys.argv.(1) in
  let sparseness = float_of_string Sys.argv.(2) in
  let dupdegree = float_of_string Sys.argv.(3) in

  let a = sparseness_generator limit sparseness dupdegree in
  let b = sparseness_generator limit sparseness dupdegree in
  let c = sparseness_generator limit sparseness dupdegree in

  let an = Array1.dim a in
  let bn = Array1.dim b in
  let cn = Array1.dim c in

  time_it "Filling ordinary tree set 1" (fun _ ->
  for i=0 to an-1 do
    s1 := S.add a.{i} !s1;
  done;
  print_string (if output then to_string !s1 else "");
  );

  time_it "Filling interval tree set 1" (fun _ ->
  for i=0 to an-1 do
    t1 := T.add a.{i} !t1;
  done;
  print_string (if output then to_string' !t1 else "");
  );

  check !s1 !t1;


  time_it "Filling ordinary tree set 2" (fun _ ->
  for i=0 to bn-1 do
    s2 := S.add b.{i} !s2;
  done;
  print_string (if output then to_string !s2 else "")
  );

  time_it "Filling interval tree set 2" (fun _ ->
  for i=0 to bn-1 do
    t2 := T.add b.{i} !t2;
  done;
  print_string (if output then to_string' !t2 else "")
  );

  check !s2 !t2;

  time_it "Computing size of ordinary tree set 1" (fun _ ->
    let i = S.cardinal !s1 in
    print_string (if output then string_of_int i else "")
  );
  time_it "Computing size of interval tree set 1" (fun _ ->
    let i = T.cardinal !t1 in
    print_string (if output then string_of_int i else "")
  );
  time_it "Computing size of ordinary tree set 2" (fun _ ->
    let i = S.cardinal !s2 in
    print_string (if output then string_of_int i else "")
  );
  time_it "Computing size of interval tree set 2" (fun _ ->
    let i = T.cardinal !t2 in
    print_string (if output then string_of_int i else "")
  );

  let us = ref S.empty in
  let ut = ref (T.empty sign) in

  time_it "Forming union of ordinary tree sets 1 and 2" (fun _ ->
    us := S.union !s1 !s2;
    print_string (if output then to_string !us else "")
  );
  time_it "Forming union of interval tree sets 1 and 2" (fun _ ->
    ut := T.union !t1 !t2;
    print_string (if output then to_string' !ut else "")
  );

  check !us !ut;

  time_it "Forming intersection of ordinary tree sets 1 and 2" (fun _ ->
    us := S.inter !s1 !s2;
    print_string (if output then to_string !us else "")
  );
  time_it "Forming intersection of interval tree sets 1 and 2" (fun _ ->
    ut := T.inter !t1 !t2;
    print_string (if output then to_string' !ut else "")
  );

  check !us !ut;


  time_it "Forming difference between ordinary tree sets 1 and 2" (fun _ ->
    us := S.diff !s1 !s2;
    print_string (if output then to_string !us else "")
  );
  time_it "Forming difference between interval tree sets 1 and 2" (fun _ ->
    ut := T.diff !t1 !t2;
    print_string (if output then to_string' !ut else "")
  );

  check !us !ut;

  time_it ("Checking for subset inclusion between ordinary tree sets 1 and 2") (fun _ ->
    let u = S.subset !s1 !s2 in
    print_string (if output then string_of_bool u else "")
  );
  time_it ("Checking for subset inclusion between interval tree sets 1 and 2") (fun _ ->
    let u = T.subset !t1 !t2 in
    print_string (if output then string_of_bool u else "")
  );
  time_it ("Checking for subset inclusion between ordinary tree sets 2 and 1") (fun _ ->
    let u = S.subset !s2 !s1 in
    print_string (if output then string_of_bool u else "")
  );
  time_it ("Checking for subset inclusion between interval tree sets 2 and 1") (fun _ ->
    let u = T.subset !t2 !t1 in
    print_string (if output then string_of_bool u else "")
  );


  let b = Random.bool () in
  let x = Random.int limit in
  let u = S.remove x !s1 in
  time_it ("Checking for equality between ordinary tree set 1 and variant ") (fun _ ->
    let u = if b then S.equal !s1 u else S.equal u !s1 in
    let output = true in
    print_string (if output then string_of_bool u else "")
  );
  let u = T.remove x !t1 in
  time_it ("Checking for equality between interval tree set 1 and variant") (fun _ ->
    let u = if b then T.equal !t1 u else T.equal u !t1 in
    let output = true in
    print_string (if output then string_of_bool u else "")
  );




  time_it ("Deleting " ^ string_of_int cn ^ " elements from ordinary tree set 1") (fun _ ->
    us := !s1;
    for i=0 to cn-1 do
       us := S.remove c.{i} !us
    done;
    print_string (if output then to_string !us else "")
  );
  time_it ("Deleting " ^ string_of_int cn ^ " elements from interval tree set 1") (fun _ ->
    ut := !t1;
    for i=0 to cn-1 do
       ut := T.remove c.{i} !ut
    done;
    print_string (if output then to_string' !ut else "")
  );

  check !us !ut;

  time_it ("Computing the sum over all elements in the ordinary tree set 1 through folding") (fun _ ->
    let i = S.fold (fun x -> fun y -> x + y) !s1 0 in
    print_string (if output then string_of_int i else "")
  );
  time_it ("Computing the sum over all elements in the interval tree set 1 through folding") (fun _ ->
    let i = T.fold (fun x -> fun y -> x + y) !t1 0 in
    print_string (if output then string_of_int i else "")
  );

  time_it ("Counting the number of elements in the ordinary tree set 1 by iterating through it") (fun _ ->
    let n = ref 0 in
    let _ = S.iter (fun _ -> incr n) !s1 in
    print_string (if output then string_of_int !n else "")
  );
  time_it ("Counting the number of elements in the interval tree set 1 by iterating through it") (fun _ ->
    let n = ref 0 in
    let _ = T.iter (fun _ -> incr n) !t1 in
    print_string (if output then string_of_int !n else "")
  );

  time_it ("Filtering all even elements from the ordinary tree set 1") (fun _ ->
    us := S.filter (fun x -> x mod 2 = 0) !s1;
    print_string (if output then to_string !us else "")
  );
  time_it ("Filtering all even elements from the interval tree set 1 using method 1") (fun _ ->
    ut := T.filter (fun x -> x mod 2 = 0) !t1;
    print_string (if output then to_string' !ut else "")
  );

  check !us !ut;

  time_it ("Filtering all big elements from the ordinary tree set 1") (fun _ ->
    us := S.filter (fun x -> x > limit/2) !s1;
    print_string (if output then to_string !us else "")
  );
  time_it ("Filtering all big elements from the interval tree set 1 using method 1") (fun _ ->
    ut := T.filter (fun x -> x > limit/2) !t1;
    print_string (if output then to_string' !ut else "")
  );

  check !us !ut;

  let us2 = ref S.empty in
  let ut2 = ref (T.empty sign) in

  time_it ("Splitting ordinary tree set 1 into two halves") (fun _ ->
    let (s,b,s') = S.split (limit/2) !s1 in
    us := s;
    us2 := s';
    print_string (if output then to_string s ^ " " ^ string_of_bool b ^ " " ^ to_string s' else "")
  );
  time_it ("Splitting interval tree set 1 into two halves") (fun _ ->
    let (t,b,t') = T.split (limit/2) !t1 in
    ut := t;
    ut2 := t';
    print_string (if output then to_string' t ^ " " ^ string_of_bool b ^ " " ^ to_string' t' else "")
  );

  check !us !ut;
  check !us2 !ut2;

  time_it ("Partitioning ordinary tree set 1 into evens/odds") (fun _ ->
    let (s,s') = S.partition (fun x -> x mod 2 = 0) !s1 in
    us := s;
    us2 := s';
    print_string (if output then to_string s ^ " " ^ to_string s' else "")
  );
  time_it ("Partitioning interval tree set 1 into evens/odds") (fun _ ->
    let (t,t') = T.partition (fun x -> x mod 2 = 0) !t1 in
    ut := t;
    ut2 := t';
    print_string (if output then to_string' t ^ " " ^ to_string' t' else "")
  );

  check !us !ut;
  check !us2 !ut2;

  time_it ("Partitioning ordinary tree set 1 into little/big ones") (fun _ ->
    let (s,s') = S.partition (fun x -> x <= limit/2) !s1 in
    us := s;
    us2 := s';
    print_string (if output then to_string s ^ " " ^ to_string s' else "")
  );
  time_it ("Partitioning interval tree set 1 into little/big ones") (fun _ ->
    let (t,t') = T.partition (fun x -> x <= limit/2) !t1 in
    ut := t;
    ut2 := t';
    print_string (if output then to_string' t ^ " " ^ to_string' t' else "")
  );

  check !us !ut;
  check !us2 !ut2;



  ()
