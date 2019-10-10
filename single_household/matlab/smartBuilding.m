%% Problem parameters

timeStep = 0.25; % hours
horizonLength = 24 * 7; % hours

% Number of time steps
numTimeSteps = floor(horizonLength / timeStep);
timeStepsInDay = round(24 / timeStep);
daysInHorizon = floor(horizonLength / 24);

% AC-to-DC conversion efficiency
etaAD = 0.9;
% DC-to-AC conversion efficiency
etaDA = 0.7;
% Minimum status of charge (SOC)
statusOfChargeMin = 0.3;
% Maximum SOC
statusOfChargeMax = 0.9;
% Discharging current limit [Ah]
dischargingCurrentMax = 20;
% Charging current limit [Ah]
chargingCurrentCMax = 20;
% Charge/discharge efficiency
etaC = 0.9;
% Battery capacity [kWh]
batteryCapacity = 4;
% Initial energy in the battery [kWh]
batteryInitialEnergy = 2;

% Cost [£/kWh]
cost = readmatrix("../cost.dat", "CommentStyle", "#");
% DC load [kW]
powerDCLoad = readmatrix("../dc_load.dat", "CommentStyle", "#");
% AC load [kW]
powerACLoad = readmatrix("../ac_load.dat", "CommentStyle", "#");
% PV output [kW]
powerPhoto = readmatrix("../pv_output.dat", "CommentStyle", "#");

% Secondary parameters

% Minimum energy that can be stored in the battery
batteryEnergyMin = statusOfChargeMin * batteryCapacity;
% Maximum energy that can be stored in the battery
batteryEnergyMax = statusOfChargeMax * batteryCapacity;
% Maximum discharging rate [kW]
dischargingPowerMax = -etaC * dischargingCurrentMax;
% Maximum charging rate [kW]
chargingPowerMax = etaC * chargingCurrentCMax;

%% Variables

% Power required from the main grid [kW]
inputPower = optimvar("inputPower", numTimeSteps);
% AC to DC power flow [kW]
powerACDC = optimvar("powerACDC", numTimeSteps);
% Power flow on the DC bus [kW]
powerDCBus = optimvar("powerDCBus", numTimeSteps);
% Battery power flow [kW]
batteryPower = optimvar("batteryPower", numTimeSteps, ...
    "LowerBound", dischargingPowerMax, ...
    "UpperBound", chargingPowerMax);
% Energy stored in the battery at time step t [kWh]
batteryEnergy = optimvar("batteryEnergy", numTimeSteps, ...
    "LowerBound", batteryEnergyMin, ...
    "UpperBound", batteryEnergyMax);
% 1 when converting AC to DC, 0 when DC to AC
switchACDC = optimvar("switchACDC", numTimeSteps, ...
    "Type", "integer", "LowerBound", 0, "UpperBound", 1);

%% Objective

% Minimize the toal cost
problem = optimproblem("Objective", sum(cost .* inputPower * timeStep));

%% Constraints

% Conservation of total power
problem.Constraints.ConservationTotalPower = ...
    inputPower == powerACLoad + powerACDC;

% Switch governs DC flow
problem.Constraints.BindPositiveDCFlow = ...
    switchACDC .* powerDCBus >= 0;
problem.Constraints.BindNegativeDCFlow = ...
    (switchACDC - 1) .* powerDCBus >= 0;

% Conservation of power in AC/DC conversion
problem.Constraints.ConservationPowerACDC = ...
    powerACDC == (etaAD * switchACDC + etaDA * (1 - switchACDC)) .* powerDCBus;

% Conservation of power on the DC bus
problem.Constraints.ConservationPowerDCBus = ...
    powerDCBus + powerPhoto == powerDCLoad + batteryPower;

% Total energy stored in the battery
problem.Constraints.InitialBatteryEnergy = ...
    batteryEnergy(1) == batteryInitialEnergy;

for k = 2:numTimeSteps
    problem.Constraints.("BatteryEnergyTimeStep"+ k) = ...
        batteryEnergy(k) == batteryEnergy(k - 1) + batteryPower(k - 1) * timeStep;
end

%% Initial point for solve

initValue = zeros(numTimeSteps, 1);
initialPoint.inputPower = initValue;
initialPoint.powerACDC = initValue;
initialPoint.powerDCBus = initValue;
initialPoint.batteryPower = initValue;
initialPoint.batteryEnergy = batteryEnergyMin * ones(numTimeSteps, 1);
initialPoint.switchACDC = initValue;
