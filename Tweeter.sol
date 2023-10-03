// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract TweeterComtract {
    struct Tweet {
        uint256 id;
        address author;
        string content;
        uint256 createdAt;
    }

    struct Message {
        uint256 id;
        string content;
        address from;
        address to;
        uint256 createdAt;
    }

    mapping(uint256 => Tweet) public tweets;
    mapping(address => uint256[]) public tweetsOf;
    mapping(uint256 => Message[]) public conversations;
    mapping(address => mapping(address => bool)) public operators;
    mapping(address => address[]) public following;

    uint256 nextTweetId;
    uint256 nextMsgId;

    function _tweet(address _from, string calldata _content) internal {
        tweets[nextTweetId] = Tweet(
            nextTweetId,
            _from,
            _content,
            block.timestamp
        );
        tweetsOf[_from].push(nextTweetId);
        nextTweetId++;
    }

    function _sendMessage(
        address _from,
        address _to,
        string calldata _content
    ) internal {
        conversations[nextMsgId].push(
            Message(nextMsgId, _content, _from, _to, block.timestamp)
        );
        nextMsgId++;
    }

    function tweet(string calldata _content) public {
        
        _tweet(msg.sender, _content);
    }

    function tweet(address _from, string calldata _content) public {
        require(operators[msg.sender][_from] == true, "User is not authorized to tweet for account. ");
        _tweet(_from, _content);
    }

    function sendMessage(address _to, string calldata _content) public {
        _sendMessage(msg.sender, _to, _content);
    }

    function sendMessage(
        address _from,
        address _to,
        string calldata _content
    ) public {
        require(operators[msg.sender][_from] == true, "User is not authorized to msg for account. ");
        _sendMessage(_from, _to, _content);
    }

    function follow(address _followed) public {
        following[msg.sender].push(_followed);
    }

    function allow(address _operator) public {
        operators[msg.sender][_operator] = true;
    }

    function disallow(address _operator) public {
        operators[msg.sender][_operator] = false;
    }

    function getLatestTweets(uint256 count)
        public
        view
        returns (Tweet[] memory)
    {
        require(count > 0 && count < nextTweetId, "Count is not proper");

        Tweet[] memory _tweets = new Tweet[](count);

        uint256 j;

        for (uint256 i = nextTweetId - count; i < nextTweetId; i++) {
            Tweet storage _structure = tweets[i]; //why storage why not memory?
            _tweets[j] = (
                Tweet(
                    _structure.id,
                    _structure.author,
                    _structure.content,
                    _structure.createdAt
                )
            );
            j++;
        }

        return _tweets;
    }

    function getLatestTweetsOfUser_1(address _user, uint256 count)
        public
        view
        returns (Tweet[] memory)
    {
        require(count > 0 && count < nextTweetId, "Count is not proper");

        Tweet[] memory _tweets = new Tweet[](count);
        uint256 j;
        uint256 latestTweetID = nextTweetId - 1;    //SLOAD
        while (j < count) {
            if (tweets[latestTweetID].author == _user) {    //SLOAD
                _tweets[j] = tweets[latestTweetID];
                j++;
            }
            latestTweetID--;
        }

        return _tweets;
    }

    

    function getLatestTweetsOfUser_2(address _user, uint256 count)
        public
        view
        returns (Tweet[] memory)
    {
        require(count > 0 && count < nextTweetId, "Count is not proper");

        Tweet[] memory _tweets = new Tweet[](count);
        uint256[] memory tweetIDsOfUser = tweetsOf[_user];  //MSTORE
        uint256 j;
        for (
            uint256 i = tweetIDsOfUser.length - count;
            i < tweetIDsOfUser.length;
            i++
        ) {
            Tweet storage _structure = tweets[tweetIDsOfUser[i]];   //STACK
            _tweets[j] = (
                Tweet(
                    _structure.id,                      
                    _structure.author,
                    _structure.content,
                    _structure.createdAt
                )
            );
            j++;
        }
        return _tweets;
    }

    function getLatestTweetsOfUser_3(address _user, uint256 count)
        public
        view
        returns (Tweet[] memory)
    {
        require(count > 0 && count < nextTweetId, "Count is not proper");

        Tweet[] memory _tweets = new Tweet[](count);
        uint256[] memory tweetIDsOfUser = tweetsOf[_user];
        uint256 j;
        for (
            uint256 i = tweetIDsOfUser.length - count;
            i < tweetIDsOfUser.length;
            i++
        ) {
            Tweet memory _structure = tweets[tweetIDsOfUser[i]];
            _tweets[j] = (
                Tweet(
                    _structure.id,
                    _structure.author,
                    _structure.content,
                    _structure.createdAt
                )
            );
            j++;
        }
        return _tweets;
    }

      function getLatestTweetsOfUser_4(address _user, uint256 count)
        public
        view
        returns (Tweet[] memory)
    {
        require(count > 0 && count < nextTweetId, "Count is not proper");

        Tweet[] memory _tweets = new Tweet[](count);
        uint256[] memory tweetIDsOfUser = tweetsOf[_user];  //MSTORE
        uint256 j;
        for (
            uint256 i = tweetIDsOfUser.length - count;
            i < tweetIDsOfUser.length;
            i++
        ) {
            _tweets[j] = tweets[tweetIDsOfUser[i]];     //SLOAD and MLOAD
            j++;
        }
        return _tweets;
    }

    function getLatestTweetsOfUser_5(address _user, uint256 count)
        public
        view
        returns (Tweet[] memory)
    {
        require(count > 0 && count < nextTweetId, "Count is not proper");

        Tweet[] memory _tweets = new Tweet[](count);
        uint256 j;
        uint[] memory IDs = tweetsOf[_user];
        uint256 latestTweetByUser_index = IDs.length - 1;
        while (j < count) {
            _tweets[j] = tweets[IDs[latestTweetByUser_index]];
            j++;
            latestTweetByUser_index--;
        }

        return _tweets;
    }

    function getLatestTweetsOfUser_6(address _user, uint256 count)
        public
        view
        returns (Tweet[] memory)
    {
        require(count > 0 && count < nextTweetId, "Count is not proper");

        Tweet[] memory _tweets = new Tweet[](count);
        uint256 j;
        uint[] storage IDs = tweetsOf[_user];
        uint256 latestTweetByUser_index = IDs.length - 1;
        while (j < count) {
            _tweets[j] = tweets[IDs[latestTweetByUser_index]];
            j++;
            latestTweetByUser_index--;
        }

        return _tweets;
    }
}
