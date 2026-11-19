Fold := {}

show : List(U32) -> Str
show = |list| list.fold(0, |sum, x| sum + x).to_str()

expect show([2, 3]) == "5"
