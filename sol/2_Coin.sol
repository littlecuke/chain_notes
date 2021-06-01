// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Coin {

    //关键字“public”让这些变量可以从外部读取
    //@deprecated  该类型是一个 160 位值，不允许任何算术运算。它适用于存储合约地址，或属于外部帐户的密钥对的公共部分的哈希值。
    address public minter;
    mapping (address => unit) public balances;

    //客户端可以通过事件针对变化作出高效的反应
    event Sent(address from ,address to ,uint amount);

    //这是构造函数，只有当合约创建时运行
    constructor(){
        minter = msg.sender;
    }

    //发送一定数量的新创建的硬币到一个地址
    //只能被合约创建者调用
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        require(amount < 1e60);
        balances[receiver] += amount;
    }

    //Errors允许您提供有关操作失败原因的信息。它们被返回给函数的调用者。
    error InsufficientBalance(uint requested,uint availble);

    //从当前持有地址发送一定量的现有硬币到一个新地址
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


}
