// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract bloodunitconsumption {
    address public bloodbankadministration;
    address public hospitaladministration;
    uint startTime;
    uint PatientID;
    uint Amount;
    uint TransfusionDate;
    uint TransfusionTime;
    uint requestDate;
    uint ApprovalDate;
    mapping(address => bool) transporter; // only authorized transporters are allowed
    mapping(address => bool) doctor; // only authorized doctors are allowed
    mapping(address => bool) nurse; // only authorized nurses are allowed
    enum OrderStatus {
        NotReady,
        ReadyforDelivery,
        StartDelivery,
        onTrack,
        EndDelivery,
        OrderReceived
    }
    OrderStatus public Orderstate;
    enum BloodComponentType {
        redcellstype,
        plasmatype,
        plateletstype
    }
    BloodComponentType public BloodcomponentType;

    constructor() {
        bloodbankadministration = msg.sender;
        hospitaladministration = 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678;
        startTime = block.timestamp;
        Orderstate = OrderStatus.NotReady;
        emit consumptionSCdeployer(msg.sender);
    }

    // Events
    event RedcellsRequest(
        address indexed doctor,
        uint BloodcomponentType,
        uint Amount,
        uint indexed requestDate
    );
    event PlasmaRequest(
        address indexed doctor,
        uint BloodcomponentType,
        uint Amount,
        uint indexed requestDate
    );
    event PlateletsRequest(
        address indexed doctor,
        uint BloodcomponentType,
        uint Amount,
        uint indexed requestDate
    );
    event RedcellsOrderApproval(
        address bloodbanckadministration,
        uint BloodcomponentType,
        uint Amount,
        uint indexed ApprovalDate
    );
    event PlasmaOrderApproval(
        address bloodbanckadministration,
        uint BloodcomponentType,
        uint Amount,
        uint indexed ApprovalDate
    );
    event PlateletsOrderApproval(
        address bloodbanckadministration,
        uint BloodcomponentType,
        uint Amount,
        uint indexed ApprovalDate
    );
    event DeliveryStart(address transporter);
    event DeliveryEnd(address transporter);
    event BloodComponentUnitsOrderReceived(address indexed doctor);
    event DoctorRedcellsPrescription(
        address indexed doctor,
        uint BloodcomponentType,
        uint PatientID,
        uint Amount
    );
    event DoctorplasmaPrescription(
        address indexed doctor,
        uint BloodcomponentType,
        uint PatientID,
        uint Amount
    );
    event DoctorplateletsPrescription(
        address indexed doctor,
        uint BloodcomponentType,
        uint PatientID,
        uint Amount
    );
    event consumptionend(
        address indexed nures,
        uint PatientID,
        uint Date,
        uint Time
    );
    event consumptionSCdeployer(address deployer);

    // Transporter Authorization Function

    function assigningtransporter(
        address user
    ) public onlybloodbankadministration {
        transporter[user] = true;
    }

    // Doctor Authorization Function
    function assigningdoctors(address user) public onlyhospitaladministration {
        doctor[user] = true;
    }

    // Nurse Authorization Function
    function assigningnurses(address user) public onlyhospitaladministration {
        nurse[user] = true;
    }

    //Defining Modifiers

    modifier onlybloodbankadministration() {
        require(
            bloodbankadministration == msg.sender,
            "The sender is not eligible to run this function"
        );
        _;
    }

    modifier onlyhospitaladministration() {
        require(
            hospitaladministration == msg.sender,
            "The sender is not eligible to run this function"
        );
        _;
    }

    modifier onlytransporter() {
        require(
            transporter[msg.sender],
            "The sender is not eligible to run this function"
        );
        _;
    }

    modifier onlydoctor() {
        require(
            doctor[msg.sender],
            "The sender is not eligible to run this function"
        );
        _;
    }
    modifier onlynurse() {
        require(
            nurse[msg.sender],
            "The sender is not eligible to run this function"
        );
        _;
    }

    // Blood Unit Consumption Tracing
    function BloodunitRequested(
        BloodComponentType _BloodcomponentType,
        uint A,
        uint ReqDate
    ) public onlydoctor {
        Amount = A;
        requestDate = ReqDate;
        if (_BloodcomponentType == BloodComponentType.redcellstype) {
            emit RedcellsRequest(msg.sender, 0, Amount, requestDate);
        }
        if (_BloodcomponentType == BloodComponentType.plasmatype) {
            emit PlasmaRequest(msg.sender, 1, Amount, requestDate);
        } else if (_BloodcomponentType == BloodComponentType.plateletstype) {
            emit PlateletsRequest(msg.sender, 2, Amount, requestDate);
        }
    }

    function OrderApproval(
        BloodComponentType _BloodcomponentType,
        uint _A,
        uint _AproDate
    ) public onlybloodbankadministration {
        Amount = _A;
        ApprovalDate = _AproDate;
        if (_BloodcomponentType == BloodComponentType.redcellstype) {
            emit RedcellsOrderApproval(msg.sender, 0, Amount, ApprovalDate);
        }
        if (_BloodcomponentType == BloodComponentType.plasmatype) {
            emit PlasmaOrderApproval(msg.sender, 1, Amount, ApprovalDate);
        } else if (_BloodcomponentType == BloodComponentType.plateletstype) {
            emit PlateletsOrderApproval(msg.sender, 2, Amount, ApprovalDate);
        }
    }

    function StartDelivery() public onlytransporter {
        require(
            Orderstate == OrderStatus.ReadyforDelivery,
            "Can't start delivery before approving the doctor's request"
        );
        Orderstate = OrderStatus.onTrack;
        emit DeliveryStart(msg.sender);
    }

    function EndDelivery() public onlytransporter {
        require(
            Orderstate == OrderStatus.onTrack,
            "Can't end delivery before announcing the start of it"
        );
        Orderstate = OrderStatus.EndDelivery;
        emit DeliveryEnd(msg.sender);
    }

    function OrderReceived() public onlydoctor {
        require(
            Orderstate == OrderStatus.EndDelivery,
            "Can't receive the order before announcing the end of the delivery"
        );
        Orderstate = OrderStatus.OrderReceived;
        emit BloodComponentUnitsOrderReceived(msg.sender);
    }

    function BloodUnitPrescription(
        BloodComponentType _BloodcomponentType,
        uint _ID,
        uint _A
    ) public onlydoctor {
        PatientID = _ID;
        Amount = _A;
        if (_BloodcomponentType == BloodComponentType.redcellstype) {
            emit DoctorRedcellsPrescription(msg.sender, 0, PatientID, Amount);
        }
        if (_BloodcomponentType == BloodComponentType.plasmatype) {
            emit DoctorplasmaPrescription(msg.sender, 1, PatientID, Amount);
        } else if (_BloodcomponentType == BloodComponentType.plateletstype) {
            emit DoctorplateletsPrescription(msg.sender, 2, PatientID, Amount);
        }
    }

    function BloodUnitTransfusion(
        uint ID,
        uint Date,
        uint Time
    ) public onlynurse {
        PatientID = ID;
        TransfusionDate = Date;
        TransfusionTime = Time;
        emit consumptionend(msg.sender, ID, Date, Time);
    }
}
