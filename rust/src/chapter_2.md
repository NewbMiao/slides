# Cell and RefCell

内部可变性（`interior mutability`）是`Rust`用来表示在一个值的外部看起来是不可变的，但是在内部是可变的。这种模式通常用于在拥有不可变引用的同时修改目标数据。

`Cell`和`RefCell`是`Rust`提供的两种内部可变性的实现。`Cell`是用于`Copy`类型的，而`RefCell`是用于非`Copy`类型的。

不知道你有没有好奇过具体内部可变性应用在什么场景，为啥要分两种实现。

今天我们针对一些场景来聊聊这两个类型的应用。

## Why interior mutability?

如下代码所示，当需要多个可变引用时，会违反`Rust`的所有权要求：同一时间只能有一个可变引用。

```rust
let mut x = 1;
let y = &mut x;
let z = &mut x;
x = 2;
*y = 3;
*z = 4;
println!("{}", x);
# will get error:
# error[E0499]: cannot borrow `x` as mutable more than once at a time
#  --> src/main.rs:5:9
#   |
# 4 | let y = &mut x;
#   |         ------ first mutable borrow occurs here
# 5 | let z = &mut x;
#   |         ^^^^^^ second mutable borrow occurs here
# 6 | x = 2;
# 7 | *y = 3;
#   | ------ first borrow later used here

# error[E0506]: cannot assign to `x` because it is borrowed
#  --> src/main.rs:6:1
#   |
# 4 | let y = &mut x;
#   |         ------ `x` is borrowed here
# 5 | let z = &mut x;
# 6 | x = 2;
#   | ^^^^^ `x` is assigned to here but it was already borrowed
# 7 | *y = 3;
#   | ------ borrow later used here
```

这个时候就是内部可变性发挥作用的时候了。拿`Cell`来举例

```rust
let x = Cell::new(1);
let y = &x;
let z = &x;
x.set(2);
y.set(3);
z.set(4);
println!("{}", x.get());
```

通过`Cell`，其封装了`get`和`set`,可以在不需要显示声明为可变的情况下修改值。

### 修改结构体的字段

一般我们要修改一个结构体的值，需要将其声明为`mut`, 而对应的方法也需要接收`&mut self` 举例如下：

```rust
#[derive(Debug, Default)]
struct Person {
    age: u32,
    name: String,
}

impl Person {
    fn celebrate_birthday(&mut self) {
        let current_age = self.age;
        self.age = current_age + 1;
    }
}
let mut Person = Person::default();
Person.celebrate_birthday();
println!("Age after birthday: {}", Person.age);
```

但是有时候我们并不想这么做，因为我们只是想**修改其中的某个字段**，而不是整个结构体，亦或者**接口并不想暴露一个`&mut self`的方法**。

```rust
#[derive(Debug, Default)]
struct Person {
    age: Cell<u32>,
    name: String,
}

impl Person {
    // 方法receiver无需声明为`mut`
    fn celebrate_birthday(&self) {
        let current_age = self.age.get();
        self.age.set(current_age + 1);
    }
}
person.celebrate_birthday();
println!("Age after birthday: {}", person.age.get());
```

## Cell 只适合 Copy 类型

对于非`Copy`类型，`Cell`并不适用, 因为其约束了`get`方法的返回值必须是`Copy`类型。

```rust
impl<T: Copy> Cell<T> {
    pub fn get(&self) -> T {
```

那是不是不能往`Cell`里面放非`Copy`类型的值呢？当然不是，只是失去了意义，代码如下

```rust
let mut s = Cell::new(String::from("value"));
// 没有 `s.get()`，因为 `String` 不是 `Copy` 类型
// 而`get_mut()`返回的是 要求自身是可变的，就失去了用`Cell`的意义
*s.get_mut() = String::from("value2");
println!("{}", s.into_inner());
```

## RefCell 提供引用

`RefCell`主要的不同是支持非`Copy`类型，且返回的是引用，而不是值。

```rust
use std::cell::RefCell;

let c = RefCell::new("hello".to_owned());
*c.borrow_mut() = "bonjour".to_owned();
let val = c.borrow();

assert_eq!(&*val, "bonjour");
```

## 运行时检查

如果把上边代码换成如下先借用，编译能通过，但是运行时会报错。

`RefCell` 依旧要遵守借用规则，只是推迟检查从编译期到运行时，如果违反了借用规则，会 `panic`。

````rust

```rust
use std::cell::RefCell;

let c = RefCell::new("hello".to_owned());
let val = c.borrow(); // 先借用再修改，最后读取借用的值
*c.borrow_mut() = "bonjour".to_owned();

assert_eq!(&*val, "bonjour");

# will panic:
# thread 'main' panicked at 'already borrowed: BorrowMutError', src/main.rs:7:8
````

综上可以看出，`Cell`和`RefCell`是不同粒度的内部可变性实现，简单的`Copy`类型可以考虑开销小的`Cell`来获取有内部可变性的**值**， 需要更灵活的内部可变**借用**就要用`RefCell`。
