// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Coin {

    //关键字“public”让这些变量可以从外部读取
    //@deprecated:该类型是一个 160 位值，不允许任何算术运算。它适用于存储合约地址，或属于外部帐户的密钥对的公共部分的哈希值。
    address public minter;

    //@deprecated:该映射类型映射地址无符号整数
    mapping (address => unit) public balances;

    //客户端可以通过事件针对变化作出高效的反应
    //@deprecated:该事件在函数的最后一行中发出 。以太坊客户端（例如 Web 应用程序）可以侦听区块链上发出的这些事件，而无需花费太多成本。
    //            一旦发出，侦听器就会收到参数,和，这使得跟踪交易成为可能。
    //
    //  *************  javascript 调用示例 ************* 
    // 要侦听此事件，您可以使用以下 JavaScript 代码，该代码使用web3.js创建Coin合约对象，并且任何用户界面都会balances从上面调用自动生成的函数：
    // Coin.Sent().watch({}, '', function(error, result) {
    // if (!error) {
    //     console.log("Coin transfer: " + result.args.amount +
    //         " coins were sent from " + result.args.from +
    //         " to " + result.args.to + ".");
    //     console.log("Balances now:\n" +
    //         "Sender: " + Coin.balances.call(result.args.from) +
    //         "Receiver: " + Coin.balances.call(result.args.to));
    //     }
    // })
    
    event Sent(address from ,address to ,uint amount);

    //这是构造函数，只有当合约创建时运行
    constructor(){
        minter = msg.sender;
    }

    //发送一定数量的新创建的硬币到一个地址
    //只能被合约创建者调用
    //@deprecated: 该mint函数将一定数量的新创建的硬币发送到另一个地址。该要求是恢复所有的变化，如果没有遇到函数调用定义的条件。
    //              在这个例子中，确保只有合约的创建者可以调用，并确保最大数量的代币。这可确保将来不会出现溢出错误。
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        require(amount < 1e60);
        balances[receiver] += amount;
    }

    //Errors允许您提供有关操作失败原因的信息。它们被返回给函数的调用者。
    //@deprecated: 错误允许您向调用者提供有关条件或操作失败原因的更多信息。错误与revert 语句一起使用 。
    //             revert 语句无条件地中止和恢复与require函数类似的所有更改，但它还允许您提供错误的名称和将提供给调用者（并最终提供给前端应用程序或块浏览器）的附加数据，以便故障可以更容易地调试或反应。
    error InsufficientBalance(uint requested,uint availble);

    //从当前持有地址发送一定量的现有硬币到一个新地址
    // @deprecated: send任何人（已经拥有其中一些硬币的人）都可以使用该功能将硬币发送给其他任何人。如果发送方没有足够的硬币发送，则require调用失败并向发送方提供适当的错误消息字符串。
    function send(address receiver, uint amount) public{
        // 发送数量超出当前持有就返回异常
        if( amount > balances[msg.sender]){
            revert InsufficientBalance({
                requested: amount,
                availble: balances[receiver]
            });
        }
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender,address receiver, uint amount);
    }

    // @note: 如果您使用此合约将硬币发送到某个地址，则在区块链浏览器上查看该地址时将看不到任何内容，因为您发送硬币的记录和更改的余额仅存储在该特定硬币的数据存储中合同。
    //      通过使用事件，您可以创建一个“区块链浏览器”来跟踪新币的交易和余额，但您必须检查币合约地址而不是币所有者的地址。

}
