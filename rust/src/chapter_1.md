# Why Rust?

看看官网怎么说

- performance
- reliability
- productivity

---

## 内存安全

- 人工管理内存
- 智能指针
- GC
- 所有权

---

<!-- ## 并发安全

- 单线程
- GIL 全局锁
- Actor 模型
- CSP 模型
- 所有权+类型系统

--- -->

## 举个 🌰

拷贝？移动？

```rust
println!("start");
# // copy
let a = 1;
let _b = a;
let _c = a;

# // move (string is allocated on heap, copy by default is not very efficient)
let d = String::from("hello");
let _e = d;
let _f = d;
```

---

## drop

```rust
#[derive(Debug)]
struct MyString(String);
impl MyString {
    fn from(name: &str) -> Self {
        MyString(String::from(name))
    }
}
struct MyData {
    data: MyString,
}

# impl Drop for MyString {
#    fn drop(&mut self) {
#        println!("Dropping MyString with value: {:?}", self.0);
#    }
# }
# impl Drop for MyData {
#     fn drop(&mut self) {
#         println!("Dropping MyData with value: {:?}", self.data);
#     }
# }


fn main() {
    {
        let _ = MyData {
            data: MyString::from("not used"),
        };
        let wrapper = MyData {
            data: MyString::from("used as variable"),
        };
        println!("End of the scope inside main.");
    }

    println!("End of the scope.");
}
```

---

## Borrow

```rust
println!("start");
let a = String::from("hello");
let d = &a;
// let ref d = a;
let _e = d;
let _f = d;
```

---

## 举个 🌰

为什么要 borrow

```rust
# #[derive(Debug)]
# struct MyString(String);
# impl MyString {
#     fn from(name: &str) -> Self {
#         MyString(String::from(name))
#     }
# }
# struct MyData {
#     data: MyString,
# }

# impl Drop for MyString {
#    fn drop(&mut self) {
#        println!("Dropping MyString with value: {:?}", self.0);
#    }
# }
# impl Drop for MyData {
#     fn drop(&mut self) {
#         println!("Dropping MyData with value: {:?}", self.data);
#     }
# }

struct MyDataRef<'a> {
    reference: &'a MyData,
}

# impl<'a> Drop for MyDataRef<'a> {
#     fn drop(&mut self) {
#         println!("Dropping MyDataRef");
#     }
# }

fn main() {
    {
        let wrapper = MyData {
            data: MyString::from("used as variable"),
        };
        let b = MyDataRef { reference: &wrapper };
        println!("End of the scope inside main.");
    }

    println!("End of the scope.");
}
```

---

## 举个 🌰

修改呢

```rust
let d = String::from("hello");
d = String::from("world");
```

## mutable

```rust
let mut d = String::from("hello");
d = String::from("world");
```

---

## 举个 🌰

回头看看修改的 drop

```rust
# #[derive(Debug)]
# struct MyString(String);
# impl MyString {
#     fn from(name: &str) -> Self {
#         MyString(String::from(name))
#     }
# }
# struct MyData {
#     data: MyString,
# }

# impl Drop for MyString {
#    fn drop(&mut self) {
#        println!("Dropping MyString with value: {:?}", self.0);
#    }
# }
# impl Drop for MyData {
#     fn drop(&mut self) {
#         println!("Dropping MyData with value: {:?}", self.data);
#     }
# }

fn main() {
    {

        let mut wrapper = MyData {
            data: MyString::from("used as mut variable1"),
        };
        wrapper.data = MyString::from("used as mut variable2");
        println!("[Mutable] End of the scope inside main.");
    }

    println!("End of the scope.");
}
```

---

## immutable + mutable

```rust,editable
#![allow(unused)]
fn main(){
    let mut d = String::from("hello");
    let e = &d;
    let f = &d;
    let g = &mut d;
    *g = "world".to_string();
    println!("{f}");
}
```

---

## interior mutation

Cell (copy) Refcell(non-copy)

```rust
use std::cell::RefCell;
let value = RefCell::new(5);
// Mutate the value using an immutable reference
let borrowed = value.borrow();
println!("Before mutation: {}", *borrowed);
drop(borrowed);
// Interior mutation
{
    let mut borrowed_mut = value.borrow_mut();
    *borrowed_mut += 1;
}
let borrowed = value.borrow();
println!("After mutation: {}", *borrowed);
```

---

## 所有权

- 值有且只有一个所有者, 且所有者离开作用域时, 值将被丢弃
- 所有权可转移
- 借用
  - 不可变借用可以有多个
  - 可变借用同一时间只能有一个

---

## 好处

- prevent errors at compile time
- race condition
- used after free
- deallocation

---

## lifetimes

return local reference？

```rust,editable
#![allow(unused)]
fn ret_local_ref() -> &str {
    let my_string = String::from("local string");
    &my_string
}
```

```rust,editable
#![allow(unused)]

fn longest(str1:  &str, str2: &str) -> &str {
    if str1.len() > str2.len() {
        str1
    } else {
        str2
    }
}

fn main() {
    let str1 = "hello";
    let str2 = "world！";

    let result = longest(str1, str2);
    println!("The longest string is: {}", result);
}
```

---

## 再举个 🌰

```rust,editable
#![allow(unused)]
fn get_longest<'a>(str1: &'a str, str2: &'a str) -> &'a str {
    if str1.len() > str2.len() {
        str1
    } else {
        str2
    }
}

fn main() {
    let result;
    {
        let str1 = String::from("hello");
        let str2 = "world!";
        result = get_longest(str1.as_str(), str2);
    }

    println!("The longest string is: {}", result);
}
```

---

## So

- 所有权关注的是值的拥有和管理
- 借用检查器在编译时保证引用的有效性和安全性
- 生命周期关注的是引用的有效范围和引用的合法性

---

## Rust is future

还有啥？

- 零成本抽象（异步，泛型等）
- RAII
- 类型系统 (option, result, enum, trait, trait object)
- 模式匹配
- 并发安全(send, sync trait)

> [Rust Language Cheat Sheet](https://cheats.rs/)
