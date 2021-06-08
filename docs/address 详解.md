### address 详解

地址类型有两种形式，他们大致相同：

<font color="red">address</font>：保存一个20字节的值（以太坊地址的大小）。

<font color="red">address payable</font> ：可支付地址，与 address 相同，不过有成员函数 transfer 和 send 。

这种区别背后的思想是 address payable 可以接受以太币的地址，而一个普通的 address 则不能。

####类型转换：

允许从 address payable 到 address 的隐式转换，而从 address 到 address payable 必须显示的转换, 通过 payable(address) 进行转换。

```
	在0.5版本,执行这种转换的唯一方法是使用中间类型，先转换为 ``uint160`` 如,  
	address payable ap = address(uint160(addr));

```

address 允许和 uint160、 整型字面常量、bytes20 及合约类型相互转换。

只能通过 payable(...) 表达式把 address 类型和合约类型转换为 address payable。 只有能接收以太币的合约类型，才能够进行此转换。例如合约要么有 receive 或可支付的回退函数。 注意 payable(0) 是有效的，这是此规则的例外。

```
	如果你需要 address 类型的变量，并计划发送以太币给这个地址，那么声明类型为 address payable 可以明确表达出你的需求。 
	同样，尽量更早对他们进行区分或转换。

```
注意：

```
	 如果将使用较大字节数组类型转换为 address ，例如 bytes32 ，那么 address 将被截断。
	 为了减少转换歧义，0.4.24及更高编译器版本要求我们在转换中显式截断处理。 
	 以32bytes值 0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC 为例， 
	 如果使用 address(uint160(bytes20(b))) 结果是 0x111122223333444455556666777788889999aAaa， 
	 而使用 address(uint160(uint256(b))) 结果是 0x777788889999AaAAbBbbCcccddDdeeeEfFFfCcCc 。

```

####地址类型成员变量

```
	<address>.balance (uint256)
	以 Wei 为单位的 地址类型 Address 的余额。

	<address>.code (bytes memory)
	在 地址类型 Address 上的代码(可以为空)

	<address>.codehash (bytes32)
	:ref:`address`的codehash

	<address payable>.transfer(uint256 amount)
	向 地址类型 Address 发送数量为 amount 的 Wei，失败时抛出异常，使用固定（不可调节）的 2300 gas 的矿工费。

	<address payable>.send(uint256 amount) returns (bool)
	向 地址类型 Address 发送数量为 amount 的 Wei，失败时返回 false，发送 2300 gas 的矿工费用，不可调节。

	<address>.call(bytes memory) returns (bool, bytes memory)
	用给定的有效载荷（payload）发出低级 CALL 调用，返回成功状态及返回数据，发送所有可用 gas，也可以调节 gas。

	<address>.delegatecall(bytes memory) returns (bool, bytes memory)
	用给定的有效载荷 发出低级 DELEGATECALL 调用 ，返回成功状态并返回数据，发送所有可用 gas，也可以调节 gas。 发出低级函数 DELEGATECALL，失败时返回 false，发送所有可用 gas，可调节。

	<address>.staticcall(bytes memory) returns (bool, bytes memory)
	用给定的有效载荷 发出低级 STATICCALL 调用 ，返回成功状态并返回数据，发送所有可用 gas，也可以调节 gas。

```


#####balance & transfer

可以使用 balance 属性来查询一个地址的余额， 也可以使用 transfer 函数向一个可支付地址（payable address）发送 以太币Ether （以 wei 为单位）：
```
	address x = 0x123;
	address myAddress = this;
	if (x.balance < 10 && myAddress.balance >= 10) x.transfer(10);

```

如果当前合约的余额不够多，则 transfer 函数会执行失败，或者如果以太转移被接收帐户拒绝， transfer 函数同样会失败而进行回退。

```
	如果 x 是一个合约地址，它的代码（更具体来说是, 如果有receive函数, 执行 receive 接收以太函数, 或者存在fallback函数,执行 Fallback 回退函数 函数）会跟 transfer 函数调用一起执行（这是 EVM 的一个特性，无法阻止）。 
	如果在执行过程中用光了 gas 或者因为任何原因执行失败，以太币Ether 交易会被打回，当前的合约也会在终止的同时抛出异常。

```

####send

send 是 transfer 的低级版本。如果执行失败，当前的合约不会因为异常而终止，但 send 会返回 false。
```
	在使用 send 的时候会有些风险：如果调用栈深度是 1024 会导致发送失败（这总是可以被调用者强制），如果接收者用光了 gas 也会导致发送失败。 
	所以为了保证 以太币Ether 发送的安全，一定要检查 send 的返回值，使用 transfer 或者更好的办法： 使用接收者自己取回资金的模式。

```

####call & delegatecall & staticcall 

为了与不符合 应用二进制接口(Application Binary Interface(ABI))的合约交互，或者要更直接地控制编码，提供了函数 call，delegatecall 和 staticcall 。 它们都带有一个 bytes memory 参数和返回执行成功状态（bool）和数据（bytes memory）。

函数 abi.encode，abi.encodePacked，abi.encodeWithSelector 和 abi.encodeWithSignature 可用于编码结构化数据。
例如:

```
	bytes memory payload = abi.encodeWithSignature("register(string)", "MyName");
	(bool success, bytes memory returnData) = address(nameReg).call(payload);
	require(success);

```
此外，为了与不符合 应用二进制接口Application Binary Interface(ABI) 的合约交互，于是就有了可以接受任意类型任意数量参数的 call 函数。 这些参数会被打包到以 32 字节为单位的连续区域中存放。 其中一个例外是当第一个参数被编码成正好 4 个字节的情况。 在这种情况下，这个参数后边不会填充后续参数编码，以允许使用函数签名。

```solidity
	address nameReg = 0x72ba7d8e73fe8eb666ea66babc8116a41bfb10e2;
	nameReg.call("register", "MyName");
	nameReg.call(bytes4(keccak256("fun(uint256)")), a);

```
注意：
```
	所有这些函数都是低级函数，应谨慎使用。 具体来说，任何未知的合约都可能是恶意的，我们在调用一个合约的同时就将控制权交给了它，而合约又可以回调合约，所以要准备好在调用返回时改变相应的状态变量（可参考 可重入 )， 与其他合约交互的常规方法是在合约对象上调用函数（x.f()）。

```

```
	可以使用 gas 修改器modifier 调整提供的 gas 数量

	address(nameReg).call{gas: 1000000}(abi.encodeWithSignature("register(string)", "MyName"));
	类似地，也能控制提供的 以太币Ether 的值

	address(nameReg).call{value: 1 ether}(abi.encodeWithSignature("register(string)", "MyName"));
	最后一点，这些 修改器modifier 可以联合使用。每个修改器出现的顺序不重要

	address(nameReg).call{gas: 1000000, value: 1 ether}(abi.encodeWithSignature("register(string)", "MyName"));
	以类似的方式，可以使用函数 delegatecall ：区别在于只调用给定地址的代码（函数），其他状态属性如（存储，余额 …）都来自当前合约。 delegatecall 的目的是使用另一个合约中的库代码。 用户必须确保两个合约中的存储结构都适合委托调用 （delegatecall）。

```

从以太坊拜占庭（byzantium）版本开始 提供了 staticcall ，它与 call 基本相同，但如果被调用的函数以任何方式修改状态变量，都将回退。

所有三个函数 call ，delegatecall 和 staticcall 都是非常低级的函数，应该只把它们当作 最后一招 来使用，因为它们破坏了 Solidity 的类型安全性。

所有三种方法都提供 gas 选项，而 delegatecall 不支持 value 选项。

```
	不管是读取状态还是写入状态，最好避免在合约代码中硬编码使用的 gas 值。这可能会引入”陷阱“，而且 gas 的消耗也是可能会改变的。

	所有合约都可以转换为 address 类型，因此可以使用 address(this).balance 查询当前合约的余额。

```















