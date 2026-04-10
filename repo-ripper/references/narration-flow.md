# Narration Flow Reference

Maintain coherent narration through prose plus code.
Introduce each code block, explain intent, and explain outcome.
Do not dump isolated snippets.

## Header Placement Example

```markdown
---
finished: false
---
#spenso/src/tensors/data/dense/DenseTensor
#spenso/src/tensors/math/add/DenseTensor
#physics/quantum-mechanics

# DenseTensor
```

## Bad Flow Example

````markdown
Here is how to create a tensor.
```rust
let tensor = DenseTensor::new(struct, data);
```
Tensors are useful.
````

## Good Flow Example

````markdown
To instantiate our data structure, combine the pre-defined skeleton with raw numerical values.
Call the constructor with the sorted structure
```rust
// and the raw data,
let tensor = DenseTensor::new(perm_struct.structure, raw_data)
// to produce the final tensor, where we crash if the data size does not match
    .expect("Data size must match structure volume");
```
This ensures raw data matches internal ordering.
Because `expect` is used, execution stops explicitly to prevent silent data corruption.
````
