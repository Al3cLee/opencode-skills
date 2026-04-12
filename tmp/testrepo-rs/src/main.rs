mod foo;

use foo::dense_tensor::{process_tensor, DenseTensor};

fn main() {
    let t = DenseTensor {
        data: vec![1, 2, 3],
    };
    process_tensor(t);
    let _fb = FooBar {};
}

#[derive(Debug, Clone, PartialEq)]
struct FooBar {}

fn use_foobar(fb: &FooBar) -> bool {
    fb == fb
}
