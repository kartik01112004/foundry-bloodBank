// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Blood Unit Production Smart Contract
contract BloodUnitProduction {
    // Addresses for different roles
    mapping(address => bool) public phlebotomists;
    mapping(address => bool) public bloodbanktechnicians;
    mapping(address => bool) public transporters;

    uint256 public donor_ID;
    uint256 public startTime;
    uint256 public amount;
    uint256 public expiryDate;

    // Status and Types
    enum WholeBloodUnitStatus {
        NotReady,
        ReadyforDelivery,
        StartDelivery,
        onTrack,
        EndDelivery,
        WholeBloodUnitReceived
    }

    WholeBloodUnitStatus public bloodunitstate;

    enum BloodComponentType {
        RedCellsType,
        PlasmaType,
        PlateletsType
    }

    BloodComponentType public bloodComponentType;

    // Events
    event BloodUnitProductionProcessStarted(address phlebotomist);
    event WholeBloodUnitReadyForDelivery(address phlebotomist, uint256 donor_ID);
    event DeliveryStart(address transporter);
    event DeliveryEnd(address transporter);
    event WholeBloodUnitReceived(address bloodbanktechnician);
    event RedCellUnitProductionEnd(
        address indexed bloodbanktechnician,
        uint256 bloodComponentType,
        uint256 redCellsAmount,
        uint256 redCellsExpiryDate
    );
    event PlasmaUnitProductionEnd(
        address indexed bloodbanktechnician, uint256 bloodComponentType, uint256 plasmaAmount, uint256 plasmaExpiryDate
    );
    event PlateletsUnitProductionEnd(
        address indexed bloodbanktechnician,
        uint256 bloodComponentType,
        uint256 plateletsAmount,
        uint256 plateletsExpiryDate
    );

    constructor() {
        startTime = block.timestamp;
        bloodunitstate = WholeBloodUnitStatus.NotReady;
    }

    // Role Assignment Functions
    function assignPhlebotomist(address _phlebotomist) public {
        phlebotomists[_phlebotomist] = true;
    }

    function assignBloodBankTechnician(address _technician) public {
        bloodbanktechnicians[_technician] = true;
    }

    function assignTransporter(address _transporter) public {
        transporters[_transporter] = true;
    }

    // Modifiers for role-based access control
    modifier onlyPhlebotomist() {
        require(phlebotomists[msg.sender], "Sender is not a phlebotomist");
        _;
    }

    modifier onlyTransporter() {
        require(transporters[msg.sender], "Sender is not a transporter");
        _;
    }

    modifier onlyBloodBankTechnician() {
        require(bloodbanktechnicians[msg.sender], "Sender is not a bloodbank technician");
        _;
    }

    // Blood Unit Production Functions
    function collectWholeBloodUnit(uint256 _donorID) public onlyPhlebotomist {
        donor_ID = _donorID;
        require(bloodunitstate == WholeBloodUnitStatus.NotReady, "Blood unit is already collected");
        bloodunitstate = WholeBloodUnitStatus.ReadyforDelivery;
        emit WholeBloodUnitReadyForDelivery(msg.sender, donor_ID);
    }

    function startDelivery() public onlyTransporter {
        require(
            bloodunitstate == WholeBloodUnitStatus.ReadyforDelivery, "Delivery cannot start before blood unit is ready"
        );
        bloodunitstate = WholeBloodUnitStatus.onTrack;
        emit DeliveryStart(msg.sender);
    }

    function endDelivery() public onlyTransporter {
        require(bloodunitstate == WholeBloodUnitStatus.onTrack, "Cannot end delivery before it starts");
        bloodunitstate = WholeBloodUnitStatus.EndDelivery;
        emit DeliveryEnd(msg.sender);
    }

    function receiveCollectedBloodUnit() public onlyBloodBankTechnician {
        require(bloodunitstate == WholeBloodUnitStatus.EndDelivery, "Cannot receive blood unit before delivery ends");
        bloodunitstate = WholeBloodUnitStatus.WholeBloodUnitReceived;
        emit WholeBloodUnitReceived(msg.sender);
    }

    function createBloodUnit(BloodComponentType _componentType, uint256 _amount, uint256 _expiryDate)
        public
        onlyBloodBankTechnician
    {
        amount = _amount;
        expiryDate = _expiryDate;

        if (_componentType == BloodComponentType.RedCellsType) {
            emit RedCellUnitProductionEnd(msg.sender, 0, amount, expiryDate);
        } else if (_componentType == BloodComponentType.PlasmaType) {
            emit PlasmaUnitProductionEnd(msg.sender, 1, amount, expiryDate);
        } else if (_componentType == BloodComponentType.PlateletsType) {
            emit PlateletsUnitProductionEnd(msg.sender, 2, amount, expiryDate);
        }
    }
}

// Blood Unit Consumption Smart Contract
contract BloodUnitConsumption {
    // Addresses for different roles
    mapping(address => bool) public bloodbankadministrations;
    mapping(address => bool) public hospitaladministrations;
    mapping(address => bool) public transporters;
    mapping(address => bool) public doctors;
    mapping(address => bool) public nurses;

    uint256 public patientID;
    uint256 public amount;
    uint256 public transfusionDate;
    uint256 public transfusionTime;
    uint256 public requestDate;
    uint256 public approvalDate;

    enum OrderStatus {
        NotReady,
        ReadyforDelivery,
        StartDelivery,
        onTrack,
        EndDelivery,
        OrderReceived
    }

    OrderStatus public orderState;

    enum BloodComponentType {
        RedCellsType,
        PlasmaType,
        PlateletsType
    }

    BloodComponentType public bloodComponentType;

    constructor() {
        orderState = OrderStatus.NotReady;
    }

    // Events
    event BloodUnitRequest(
        address indexed doctor, uint256 bloodComponentType, uint256 amount, uint256 indexed requestDate
    );
    event OrderApproval(
        address bloodbankAdmin, uint256 bloodComponentType, uint256 amount, uint256 indexed approvalDate
    );
    event DeliveryStart(address transporter);
    event DeliveryEnd(address transporter);
    event BloodUnitOrderReceived(address indexed doctor);
    event BloodUnitPrescription(address indexed doctor, uint256 bloodComponentType, uint256 patientID, uint256 amount);
    event BloodUnitTransfusionComplete(address indexed nurse, uint256 patientID, uint256 date, uint256 time);

    // Role Assignment Functions
    function assignBloodBankAdmin(address _admin) public {
        bloodbankadministrations[_admin] = true;
    }

    function assignHospitalAdmin(address _admin) public {
        hospitaladministrations[_admin] = true;
    }

    function assignTransporter(address _transporter) public {
        transporters[_transporter] = true;
    }

    function assignDoctor(address _doctor) public {
        doctors[_doctor] = true;
    }

    function assignNurse(address _nurse) public {
        nurses[_nurse] = true;
    }

    // Modifiers for role-based access control
    modifier onlyBloodBankAdmin() {
        require(bloodbankadministrations[msg.sender], "Sender is not a bloodbank admin");
        _;
    }

    modifier onlyHospitalAdmin() {
        require(hospitaladministrations[msg.sender], "Sender is not a hospital admin");
        _;
    }

    modifier onlyTransporter() {
        require(transporters[msg.sender], "Sender is not a transporter");
        _;
    }

    modifier onlyDoctor() {
        require(doctors[msg.sender], "Sender is not a doctor");
        _;
    }

    modifier onlyNurse() {
        require(nurses[msg.sender], "Sender is not a nurse");
        _;
    }

    // Blood Unit Consumption Functions
    function requestBloodUnit(BloodComponentType _componentType, uint256 _amount, uint256 _requestDate)
        public
        onlyDoctor
    {
        amount = _amount;
        requestDate = _requestDate;

        emit BloodUnitRequest(msg.sender, uint256(_componentType), amount, requestDate);
    }

    function approveOrder(BloodComponentType _componentType, uint256 _amount, uint256 _approvalDate)
        public
        onlyBloodBankAdmin
    {
        amount = _amount;
        approvalDate = _approvalDate;

        emit OrderApproval(msg.sender, uint256(_componentType), amount, approvalDate);
    }

    function startDelivery() public onlyTransporter {
        require(orderState == OrderStatus.ReadyforDelivery, "Order must be ready for delivery to start");
        orderState = OrderStatus.onTrack;
        emit DeliveryStart(msg.sender);
    }

    function endDelivery() public onlyTransporter {
        require(orderState == OrderStatus.onTrack, "Delivery must be in progress to end it");
        orderState = OrderStatus.EndDelivery;
        emit DeliveryEnd(msg.sender);
    }

    function orderReceived() public onlyDoctor {
        require(orderState == OrderStatus.EndDelivery, "Delivery must end before receiving order");
        orderState = OrderStatus.OrderReceived;
        emit BloodUnitOrderReceived(msg.sender);
    }

    function prescribeBloodUnit(BloodComponentType _componentType, uint256 _patientID, uint256 _amount)
        public
        onlyDoctor
    {
        patientID = _patientID;
        amount = _amount;

        emit BloodUnitPrescription(msg.sender, uint256(_componentType), patientID, amount);
    }

    function completeBloodTransfusion(uint256 _patientID, uint256 _date, uint256 _time) public onlyNurse {
        transfusionDate = _date;
        transfusionTime = _time;

        emit BloodUnitTransfusionComplete(msg.sender, _patientID, _date, _time);
    }
}
