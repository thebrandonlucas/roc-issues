Main := [].{}

Model := { files : List({ url : Str, size : U64 }) }

empty : Model
empty = { files: [] }

model : Model
model = { ..empty, files: [{ url: "u" }] }
