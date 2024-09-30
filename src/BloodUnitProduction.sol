// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Blood Unit Production Smart contract

contract bloodunitproduction {
    address public phlebotomist;
    address public bloodbanktechnician;
    uint256 donor_ID;

    uint256 startTime;
    uint256 amount;
    uint256 expiryDate;

    mapping(address => bool) transporter; // only authorized transporters are allowed

    enum wholebloodunitStatus {
        NotReady,
        ReadyforDelivery,
        StartDelivery,
        onTrack,
        EndDelivery,
        wholebloodunitReceived
    }

    wholebloodunitStatus public bloodunitstate;

    enum BloodComponentType {
        redcellstype,
        plasmatype,
        plateletstype
    }

    BloodComponentType public BloodcomponentType;

    // Events
    event BloodUnitProductionprocessStarted(address phlebotomist);
    event wholebloodunitReadyForDelivery(address phlebotomist, uint256 donor_ID);
    event DeliveryStart(address transporter);
    event DeliveryEnd(address transporter);
    event wholebloodunitReceived(address bloodbanktechnician);
    event redcellunitproductionend(
        address indexed bloodbanktechnician,
        uint256 BloodcomponentType,
        uint256 redcellsamount,
        uint256 redcellsexpiryDate
    );
    event plasmaunitproductionend(
        address indexed bloodbanktechnician, uint256 BloodcomponentType, uint256 plasmaamount, uint256 plasmaexpiryDate
    );
    event plateletsunitproductionend(
        address indexed bloodbanktechnician,
        uint256 BloodcomponentType,
        uint256 plateletsamount,
        uint256 plateletsexpiryDate
    );

    constructor() {
        phlebotomist = msg.sender;
        bloodbanktechnician = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        startTime = block.timestamp;
        bloodunitstate = wholebloodunitStatus.NotReady;
        emit BloodUnitProductionprocessStarted(phlebotomist);
    }

    // Transporter Authorization Function

    function Assigningtransporter(address user) public {
        transporter[user] = true;
    }

    //Defining Modifiers

    modifier onlyphlebotomist() {
        require(phlebotomist == msg.sender, "The sender is not eligible to run this function");
        _;
    }

    modifier onlytransporter() {
        require(transporter[msg.sender], "The sender is not eligible to run this function");
        _;
    }

    modifier onlybloodbanktechnician() {
        require(bloodbanktechnician == msg.sender, "The sender is not eligible to run this function");
        _;
    }

    // Blood Unit Production Tracing

    function Collectwholebloodunit(uint256 donorID) public onlyphlebotomist {
        donor_ID = donorID;
        require(bloodunitstate == wholebloodunitStatus.NotReady, "Blood unit is already collected");
        bloodunitstate = wholebloodunitStatus.ReadyforDelivery;

        emit wholebloodunitReadyForDelivery(msg.sender, donor_ID);
    }

    function StartDelivery() public onlytransporter {
        require(
            bloodunitstate == wholebloodunitStatus.ReadyforDelivery,
            "Can't start delivery before collecting the blood unit"
        );
        bloodunitstate = wholebloodunitStatus.onTrack;
        emit DeliveryStart(msg.sender);
    }

    function EndDelivery() public onlytransporter {
        require(bloodunitstate == wholebloodunitStatus.onTrack, "Can't end delivery before announcing the start of it");
        bloodunitstate = wholebloodunitStatus.EndDelivery;
        emit DeliveryEnd(msg.sender);
    }

    function ReceiveCollectedBloodunit() public onlybloodbanktechnician {
        require(
            bloodunitstate == wholebloodunitStatus.EndDelivery,
            "Can't receive the whole blood unit before announcing the end of the delivery"
        );
        bloodunitstate = wholebloodunitStatus.wholebloodunitReceived;
        emit wholebloodunitReceived(msg.sender);
    }

    function Createbloodunit(BloodComponentType _BloodcomponentType, uint256 _A, uint256 _Expd)
        public
        onlybloodbanktechnician
        returns (uint256)
    {
        amount = _A;
        expiryDate = _Expd;

        if (_BloodcomponentType == BloodComponentType.redcellstype) {
            emit redcellunitproductionend(msg.sender, 0, amount, expiryDate);
        }
        if (_BloodcomponentType == BloodComponentType.plasmatype) {
            emit plasmaunitproductionend(msg.sender, 1, amount, expiryDate);
        } else if (_BloodcomponentType == BloodComponentType.plateletstype) {
            emit plateletsunitproductionend(msg.sender, 2, amount, expiryDate);
        }
    }
}
