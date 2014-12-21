
(** Test F *)

open OUnit

module F = Future.Std
module MVar = Future.MVar

let test_mvar () =
  let box = MVar.empty () in
  let f = F.spawn (fun () -> MVar.take box + 1) in
  Thread.delay 0.1;
  OUnit.assert_bool "still waiting" (not (F.is_done f));
  MVar.put box 1;
  Thread.delay 1.;
  OUnit.assert_equal (F.Success 2) (F.state f);
  ()

let test_parallel () =
  let open Gen.Infix in
  let l = 1 -- 300
    |> Gen.map (fun _ -> F.spawn (fun () -> Thread.delay 0.1; 1))
    |> Gen.to_list in
  let l' = F.map (List.fold_left (+) 0) (F.sequence l) in
  Thread.delay 0.5;
  OUnit.assert_equal (F.Success 300) (F.state l');
  ()

let test_time () =
  let f1 = F.spawn (fun () -> Thread.delay 0.5) in
  let f2 = F.spawn (fun () -> Thread.delay 0.5) in
  Thread.delay 0.75;
  match F.state f1, F.state f2 with
  | F.Success _, F.Success _ -> ()
  | _ -> OUnit.assert_failure "parallelism"

let test_timer () =
  let mvar = MVar.full 1 in
  F.Timer.after 0.5
    (fun () -> ignore (MVar.update mvar (fun x -> x + 2)));
  F.Timer.after 0.2
    (fun () -> ignore (MVar.update mvar (fun x -> x * 4)));
  Thread.delay 0.7;
  OUnit.assert_equal 6 (MVar.peek mvar);
  ()

let suite =
  "test_future" >:::
    [ "test_mvar" >:: test_mvar;
      "test_parallel" >:: test_parallel;
      "test_time" >:: test_time;
      "test_timer" >:: test_timer;
    ]