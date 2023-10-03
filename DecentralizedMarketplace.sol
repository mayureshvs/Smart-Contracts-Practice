// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//enable users to list items for sale(details,price,availibility)
//place orders(veridfy availibility)
//handle transactions
//structure for item: name description price sellersAddress availabilityStatus
//confirmationFunction
//  retrive info of listed items with details
//ablity to withdraw funds by sellers
//refunds for cancelled orders
//other required handling of funds
contract DecentralizedMarketplace{

    struct item{
        uint itemID;
        string name;
        string desc;
        uint AmtInWei;
        address sellerAddr;
        address buyerAddr;
        OrderStatus orderStatus;
    }


    enum OrderStatus{
        available,orderPlaced,orderConfirmed,sold
    }

    mapping (uint => item) public itemDetails;
    mapping (address => uint[]) itemsOnSale;
    mapping (address => uint[]) orders;

    uint nextItemID;

    modifier onlySeller(uint _itemID){
        require(msg.sender == itemDetails[_itemID].sellerAddr,"You are not seller of this Product");
        _;
    }

    modifier onlyBuyer(uint _itemID){
        require(msg.sender == itemDetails[_itemID].buyerAddr,"Either You are not buyer of this Product, or your order has been declined.");
        _;
    }

    function addItemForSale(string calldata _name,string calldata _desc, uint _priceInWei) external {
        itemDetails[nextItemID] = item(nextItemID,_name,_desc,_priceInWei,msg.sender,address(0),OrderStatus.available);
        itemsOnSale[msg.sender].push(nextItemID);
        nextItemID++;
        
    }

    function placeOrder(uint _itemID) external payable{
        require(itemDetails[_itemID].orderStatus == OrderStatus.available,"Requested item is not available");
        require(msg.value >= itemDetails[_itemID].AmtInWei,"Amount Entered is lesser than price of item");
        itemDetails[_itemID].orderStatus = OrderStatus(uint(itemDetails[_itemID].orderStatus) + 1);
        itemDetails[_itemID].buyerAddr = msg.sender;
        orders[msg.sender].push(_itemID);
        
    }

    function getOrderStatus(uint _itemID) external view onlyBuyer(_itemID) returns(string memory){
        if(itemDetails[_itemID].orderStatus == OrderStatus.orderConfirmed){
            return "Order is confirmed, Please wait for delivery.";
        }else if(itemDetails[_itemID].orderStatus == OrderStatus.sold){
            return "Order is already delivered to you. if not please reach out to customer care.";
        }else{
            return "Order is yet to be confirmed by seller. Please wait.";
        }
    }

    function yourOrders() external view returns(item[] memory){
         uint NumOfItems = orders[msg.sender].length;
        item[] memory items = new item[](NumOfItems);
        for(uint i = 0;i<NumOfItems;i++){
            items[i] = itemDetails[orders[msg.sender][i]];
        }
        return items;
    }

    function YourItemsOnSale() external view returns(item[] memory){
        uint NumOfItems = itemsOnSale[msg.sender].length;
        item[] memory items = new item[](NumOfItems);
        for(uint i = 0;i<NumOfItems;i++){
            items[i] = itemDetails[itemsOnSale[msg.sender][i]];
        }
        return items;

    }

    function ItemsOnSale() external view returns(item[] memory){
        
        item[] memory items = new item[](nextItemID);
        for(uint i = 0;i<nextItemID;i++){
            items[i] = itemDetails[i];
        }
        return items;

    }

    function comfirmOrder(uint _itemID) external onlySeller(_itemID){
        require(itemDetails[_itemID].orderStatus == OrderStatus.orderPlaced,"No one has yet placed order for given Item");
        itemDetails[_itemID].orderStatus = OrderStatus(uint(itemDetails[_itemID].orderStatus) + 1);
    }

    function declineOrder(uint _itemID) external payable onlySeller(_itemID){
        require(itemDetails[_itemID].orderStatus == OrderStatus.orderPlaced,"No one has yet placed order for given Item");
        itemDetails[_itemID].orderStatus = OrderStatus(uint(itemDetails[_itemID].orderStatus) - 1);
        payable(itemDetails[_itemID].buyerAddr).transfer(itemDetails[_itemID].AmtInWei);
        itemDetails[_itemID].buyerAddr = address(0);
    }

    function comfirmSale(uint _itemID) external onlyBuyer(_itemID){
        require(itemDetails[_itemID].orderStatus == OrderStatus.orderConfirmed,"No one has yet placed order for given Item");
        itemDetails[_itemID].orderStatus = OrderStatus(uint(itemDetails[_itemID].orderStatus) + 1);
    }

    function claimAmountOfSale(uint _itemID) external payable onlySeller(_itemID){
        require(itemDetails[_itemID].orderStatus == OrderStatus.sold,"No one has yet placed order for given Item");
        payable(msg.sender).transfer(itemDetails[_itemID].AmtInWei);
    }



}