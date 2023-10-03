// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//participate
//place bids (itemID,bidAmount)
//determine highest bidder and bid
//structure to hold info about each item - name description current highest bid
//getItemlist
contract AuctionSystem {
    address auctionCommission;
    address public highestBidder;
    uint256 public highestBid;

    struct Item {
        uint256 itemID;
        string name;
        string description;
        uint256 currentHighestBid;
        address latestBidderAddress;
        bool isSold;
    }

    struct Bidder {
        address bidderAddress;
        uint256 wealth;
        bool isRegistered;
    }

    enum status {
        YetToStart,
        in_Progress,
        Done
    }

    mapping(uint256 => Item) itemDetails;
    mapping(address => Bidder) bidderDetails;

    uint256 nextItemID;
    uint256 firstItemID;

    status auctionState;

    constructor() {
        auctionCommission = msg.sender;
        auctionState = status.YetToStart;
    }

    modifier onlyAuctionCommission() {
        require(
            msg.sender == auctionCommission,
            "You are not from Auction Commission"
        );
        _;
    }

    function participate(uint256 _wealth) external {
        require(
            msg.sender != auctionCommission,
            "You are from Auction Commission"
        );
        require(
            auctionState == status.YetToStart,
            "Auction Commision is not accepting participation right now."
        );
        bidderDetails[msg.sender] = Bidder(msg.sender, _wealth, true);
    }

    function addItemToAuction(string calldata _name, string calldata _desc)
        external
    {
        require(
            auctionState == status.YetToStart,
            "Auction Commision is not accepting any items now."
        );
        itemDetails[nextItemID] = Item(
            nextItemID,
            _name,
            _desc,
            0,
            address(0),
            false
        );
        nextItemID++;
    }

    function getItemList() external view returns (Item[] memory) {
        require(
            auctionState == status.in_Progress,
            "Youc cannot fetch itemList now."
        );
        Item[] memory items = new Item[](nextItemID);
        for (uint256 i = firstItemID; i < nextItemID; i++) {
            items[i] = itemDetails[i];
        }
        return items;
    }

    function nextAuctionStage() external onlyAuctionCommission {
        auctionState = status(uint8(auctionState) + 1);

        if (auctionState == status.Done) {
            for (uint256 i = firstItemID; i < nextItemID; i++) {
                if (itemDetails[i].currentHighestBid > 0) {
                    itemDetails[i].isSold = true;
                }
            }
            firstItemID = nextItemID;
        }
    }

    function getAuctionState() external view returns (string memory) {
        if (auctionState == status.Done) {
            return "Auction is completed";
        } else if (auctionState == status.in_Progress) {
            return "Auction is going on";
        } else {
            return "Auction is yet to start";
        }
    }

    function placeBid(uint256 _itemID, uint256 _bidAmount) external {
        require(
            auctionState == status.in_Progress,
            "You cannot place bid now."
        );
        require(
            bidderDetails[msg.sender].isRegistered,
            "You are not registered as Bidder"
        );
        require(
            itemDetails[_itemID].currentHighestBid < _bidAmount,
            "You need to bid higher"
        );
        require(
            _bidAmount < bidderDetails[msg.sender].wealth,
            "You don't have enough wealth to bid"
        );

        itemDetails[_itemID].currentHighestBid = _bidAmount;
        itemDetails[_itemID].latestBidderAddress = msg.sender;

        if (highestBid < _bidAmount) {
            highestBid = _bidAmount;
            highestBidder = msg.sender;
        }
    }
}
